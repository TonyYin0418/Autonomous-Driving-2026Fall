# nuScenes to YOLO converter

`convert.py` projects nuScenes 3D annotations into YOLO 2D labels. It creates
one independent dataset for each location and splits each location by scene
into train/val/test using ratios 7:1:2 and random seed 42.

Locations: `boston-seaport`, `singapore-hollandvillage`,
`singapore-onenorth`, and `singapore-queenstown`.

## Run (Linux)

Run from the project root. External paths are explicit absolute paths; the
output path is internal to this project and can remain relative.

```bash
conda activate yolo
python nuscenes_yolo_converter/convert.py \
  --dataroot /data/nuscenes \
  --output nuscenes_yolo_converter/output/nuscenes_yolo_vis34 \
  --exclude-night \
  --visibilities 3 4 \
  --overwrite
```

The converter requires the pip-installed `nuscenes-devkit` package.

Useful options:

```text
--train-ratio 0.7          Train ratio (default 0.7).
--val-ratio 0.1            Validation ratio (test is 1-train-val).
--seed 42                  Deterministic location/scene split.
--min-distance 1.0        Retain frames at least 1 metre apart in ego XY.
--dry-run                 Print filtering counts without writing output.
--no-exclude-night         Keep night scenes.
--visibilities 3 4         Keep only visibility levels 3 and 4.
--class-mode detection10   Official nuScenes detection classes.
--class-mode all23         Preserve all raw annotation categories.
--image-mode hardlink      Avoid copying image bytes on the same filesystem.
--image-mode copy           Create independent image copies.
--overwrite                Replace an existing output directory.
```

Empty-label frames are removed before distance sampling. Preview the retained
sample count without creating or replacing a dataset:

```bash
python nuscenes_yolo_converter/convert.py \
  --dataroot /data/nuscenes \
  --exclude-night --visibilities 3 4 \
  --min-distance 1.0 --dry-run
```

## Output

```text
output/nuscenes_yolo_vis34/
├── conversion_summary.json
├── boston-seaport/
│   ├── data.yaml
│   ├── classes.txt
│   ├── manifest.csv
│   ├── manifests/{train,val,test}.txt
│   ├── images/{train,val,test}/
│   └── labels/{train,val,test}/
├── singapore-hollandvillage/
├── singapore-onenorth/
└── singapore-queenstown/
```

Each location directory is a standalone Ultralytics dataset. Its `data.yaml`
uses `path: .` and all manifests contain relative paths, so the generated
location directory can be moved without rewriting labels. The `source_image`
column in `manifest.csv` intentionally records the external nuScenes source
as an absolute provenance path; `output_image` is relative to the location
dataset.

Validate one location dataset:

```bash
python nuscenes_yolo_converter/validate.py \
  nuscenes_yolo_converter/output/nuscenes_yolo_vis34/boston-seaport
```

Training, evaluation and visualization are implemented separately in the
sibling `yolo_workflow` directory.
