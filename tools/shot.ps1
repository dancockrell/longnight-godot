# Capture a Godot window's own pixels, by the PID we launched.
#
#   powershell -ExecutionPolicy Bypass -File tools\shot.ps1 -Scene res://scenes/Camp.tscn -Out shot.png
#
# WHY THIS EXISTS. Three earlier attempts photographed the wrong thing:
#
#   1. CopyFromScreen over a fixed screen region caught whatever happened to
#      be at those coordinates - twice that was another Claude session's
#      window, and one of those was read as evidence of a bug in this game
#      that did not exist.
#   2. CopyFromScreen over THIS window's GetWindowRect is still wrong: the
#      rect is correct but the window may be behind others, and the screen
#      shows the occluding window's pixels.
#   3. Trusting PrintWindow's return value alone - it returns true for a
#      window that renders as a black rectangle.
#
# So: address the window by the handle of the process we started, capture its
# backing store with PrintWindow (PW_RENDERFULLCONTENT), and then SAMPLE THE
# PIXELS to prove the result is not blank before saving it. The bool is not
# the check; the image is.
#
# CLAUDE.md rule 8b - the instruments do not label the actor - and rule 16 -
# looking at the artefact only works if the thing you are looking at is the
# artefact.

param(
  [string]$Scene = "",
  [string]$Out = "shot.png",
  [int]$Seconds = 8,
  [string]$Resolution = "1280x800",
  [string]$Godot = "C:\Users\Admin\AppData\Local\Programs\Godot\Standard\Godot_v4.7.2-stable_win64.exe",
  [string]$ProjectPath = "C:\Users\Admin\dev\longnight-godot"
)

Add-Type @"
using System;using System.Runtime.InteropServices;using System.Drawing;
public struct RECT{public int L,T,R,B;}
public class Win{
  [DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out RECT r);
  [DllImport("user32.dll")]public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint f);
  [DllImport("user32.dll")]public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
}
"@ -ReferencedAssemblies System.Drawing

# PowerShell is not DPI-aware by default. GetWindowRect for a DPI-aware
# window (Godot is one) then returns coordinates scaled DOWN by the monitor's
# scale factor - a 1024x640 Godot window came back as 834x550, a ratio with
# no relation to the actual content, and a screenshot built from that rect
# silently cropped off whatever fell outside the shrunk box. It looked
# exactly like a layout bug in the game and was actually this tool being
# DPI-blind. -4 is DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2.
[void][Win]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))

$argv = @('--path', $ProjectPath, '--resolution', $Resolution)
if ($Scene -ne "") { $argv += $Scene }

$p = Start-Process -FilePath $Godot -ArgumentList $argv -PassThru
Start-Sleep -Seconds $Seconds
$p.Refresh()
$h = $p.MainWindowHandle

if ($h -eq [IntPtr]::Zero) {
  Write-Output "FAIL: process $($p.Id) has no window. Refusing to capture the screen instead - that is how you end up photographing another session."
  Stop-Process -Id $p.Id -Force
  exit 1
}
Write-Output "window title=[$($p.MainWindowTitle)] pid=$($p.Id)"

# Poll until the window's rect stops changing rather than trusting a fixed
# sleep. An earlier version captured immediately and got a 834x550 rect for a
# window that was still resizing toward its final ~1024x640+chrome size - the
# capture silently cropped off the bottom of the layout, which was read as a
# missing button in the game when it was a race in this tool.
$prev = New-Object RECT
[void][Win]::GetWindowRect($h, [ref]$prev)
$stableCount = 0
for ($i = 0; $i -lt 20; $i++) {
  Start-Sleep -Milliseconds 250
  $cur = New-Object RECT
  [void][Win]::GetWindowRect($h, [ref]$cur)
  if ($cur.L -eq $prev.L -and $cur.T -eq $prev.T -and $cur.R -eq $prev.R -and $cur.B -eq $prev.B) {
    $stableCount++
    if ($stableCount -ge 3) { break }
  } else {
    $stableCount = 0
  }
  $prev = $cur
}
$r = $prev
$w = $r.R - $r.L; $ht = $r.B - $r.T
Write-Output "window rect stabilised after polling: ${w}x${ht}"
if ($w -le 0 -or $ht -le 0) {
  Write-Output "FAIL: window rect is ${w}x${ht}"
  Stop-Process -Id $p.Id -Force
  exit 1
}

Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$dc = $g.GetHdc()
$ok = [Win]::PrintWindow($h, $dc, 2)
$g.ReleaseHdc($dc)

# Do not trust $ok. Sample the pixels: a window that failed to render comes
# back as one flat colour, and PrintWindow reports success for it.
$seen = @{}
for ($x = 10; $x -lt $w - 10; $x += 29) {
  for ($y = 10; $y -lt $ht - 10; $y += 29) { $seen[$bmp.GetPixel($x,$y).ToArgb()] = 1 }
}
Write-Output "PrintWindow=$ok size=${w}x${ht} distinct_sampled_colours=$($seen.Count)"

Stop-Process -Id $p.Id -Force

if ($seen.Count -lt 3) {
  Write-Output "FAIL: captured image has $($seen.Count) distinct colours - it is blank. Not saving."
  exit 1
}

$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output "SAVED $Out"
