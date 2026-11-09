"""Udacity Socket.IO controller adapted from the course's drive.py."""
import argparse
import base64
import csv
from datetime import datetime
from io import BytesIO
import json
from pathlib import Path
import time

import eventlet
import eventlet.wsgi
from flask import Flask
import numpy as np
from PIL import Image
import socketio
import torch

from model import NetworkNvidia
from utils import preprocess


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('model', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--speed', type=float, default=10)
    parser.add_argument('--port', type=int, default=4567)
    parser.add_argument('--record-every', type=int, default=10)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    (args.output / 'frames').mkdir()
    torch.set_num_threads(2)
    model = NetworkNvidia()
    checkpoint = torch.load(args.model, map_location='cpu', weights_only=False)
    model.load_state_dict(checkpoint['state_dict'])
    model.eval()
    (args.output / 'config.json').write_text(json.dumps({'checkpoint': str(args.model.resolve()),
        'epoch': checkpoint['epoch'], 'target_speed': args.speed, 'controller': '1.2-steering^2-(speed/target)^2'}, indent=2))
    sio = socketio.Server(async_mode='eventlet', cors_allowed_origins='*')
    app = socketio.Middleware(sio, Flask(__name__))
    handle = (args.output / 'telemetry.csv').open('w', newline='', buffering=1)
    writer = csv.writer(handle)
    writer.writerow(['time', 'frame', 'speed', 'steering', 'throttle', 'inference_ms'])
    frames = 0

    def control(sid, steering, throttle):
        sio.emit('steer', data={'steering_angle': str(steering), 'throttle': str(throttle)}, room=sid)

    @sio.on('connect')
    def connect(sid, environ):
        print('SIMULATOR_CONNECTED', sid, flush=True)
        control(sid, 0, 0)

    @sio.on('disconnect')
    def disconnect(sid):
        print('SIMULATOR_DISCONNECTED', sid, flush=True)

    @sio.on('telemetry')
    def telemetry(sid, data):
        nonlocal frames
        if not data:
            sio.emit('manual', data={}, room=sid)
            return
        begin = time.perf_counter()
        speed = float(data['speed'])
        image = Image.open(BytesIO(base64.b64decode(data['image']))).convert('RGB')
        tensor = torch.from_numpy(preprocess(np.asarray(image)[:, :, ::-1])).unsqueeze(0)
        with torch.inference_mode():
            steering = float(model(tensor).item())
        steering = float(np.clip(steering, -1, 1))
        throttle = float(np.clip(1.2 - steering**2 - (speed / args.speed)**2, -1, 1))
        control(sid, steering, throttle)
        frames += 1
        writer.writerow([datetime.now().isoformat(timespec='milliseconds'), frames, speed, steering, throttle,
                         (time.perf_counter() - begin) * 1000])
        if frames % args.record_every == 0:
            image.save(args.output / 'frames' / f'{frames:07d}.jpg')
        if frames % 30 == 0:
            print(f'frame={frames} steering={steering:.4f} throttle={throttle:.4f} speed={speed:.2f}', flush=True)

    print(f'LISTENING 0.0.0.0:{args.port}; model epoch={checkpoint["epoch"]}', flush=True)
    try:
        eventlet.wsgi.server(eventlet.listen(('0.0.0.0', args.port)), app, log_output=False)
    finally:
        handle.close()


if __name__ == '__main__':
    main()
