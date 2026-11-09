param(
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [int]$Seconds = 0,
    [double]$Interval = 0.2,
    [switch]$MinimizeAfter
)

Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class SimulatorWindow {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int command);
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
'@

[void][SimulatorWindow]::SetProcessDPIAware()
$simulator = Get-Process beta_simulator -ErrorAction Stop | Select-Object -First 1
[void][SimulatorWindow]::ShowWindow($simulator.MainWindowHandle, 9)
[void][SimulatorWindow]::SetForegroundWindow($simulator.MainWindowHandle)
Start-Sleep -Milliseconds 300
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$frame = 0
do {
    $rect = New-Object SimulatorWindow+RECT
    [void][SimulatorWindow]::GetWindowRect($simulator.MainWindowHandle, [ref]$rect)
    $bitmap = New-Object System.Drawing.Bitmap(($rect.Right-$rect.Left), ($rect.Bottom-$rect.Top))
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
    $file = Join-Path $OutputDirectory ('{0:D6}.png' -f $frame)
    $bitmap.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
    $frame++
    if ($Seconds -gt 0) { Start-Sleep -Milliseconds ([int]($Interval * 1000)) }
} while ($timer.Elapsed.TotalSeconds -lt $Seconds)
Write-Output "Captured $frame frames to $OutputDirectory"
if ($MinimizeAfter) {
    [void][SimulatorWindow]::ShowWindow($simulator.MainWindowHandle, 6)
}
