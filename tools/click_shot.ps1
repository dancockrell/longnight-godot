# UNVERIFIED - clicks did not register in the one run this was tried on
# (screenshot after 3 clicks still showed beat 1). Likely SetForegroundWindow
# silently failing for a background PowerShell process, which Windows
# restricts. Left in the repo as a starting point, not as a working tool -
# do not trust its output without confirming a beat actually advanced.
#
# Like shot.ps1, but clicks the first button N times before capturing, so a
# later beat in the graph can be looked at rather than only the first one.
param(
  [string]$Scene = "res://scenes/Camp.tscn",
  [string]$Out = "shot.png",
  [int]$Clicks = 0,
  [string]$Resolution = "1024x640",
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
  [DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);
}
"@ -ReferencedAssemblies System.Drawing
[void][Win]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
Add-Type -AssemblyName System.Windows.Forms

$p = Start-Process -FilePath $Godot -ArgumentList @('--path',$ProjectPath,'--resolution',$Resolution,$Scene) -PassThru
Start-Sleep -Seconds 8
$p.Refresh()
$h = $p.MainWindowHandle
if ($h -eq [IntPtr]::Zero) { Write-Output "FAIL: no window"; Stop-Process -Id $p.Id -Force; exit 1 }
[void][Win]::SetForegroundWindow($h)
Start-Sleep -Milliseconds 500

function Get-Rect($h) {
  $r = New-Object RECT
  [void][Win]::GetWindowRect($h, [ref]$r)
  return $r
}

for ($i = 0; $i -lt $Clicks; $i++) {
  $r = Get-Rect $h
  # The Continue/choice button sits near the bottom of the footer band.
  # Click near the bottom-centre of the window, well above the true edge.
  $cx = [int](($r.L + $r.R) / 2)
  $cy = [int]($r.B - 45)
  [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($cx, $cy)
  Start-Sleep -Milliseconds 150
  Add-Type @"
using System.Runtime.InteropServices;
public class Mouse {
  [DllImport("user32.dll")] public static extern void mouse_event(uint f,int dx,int dy,uint data,int extra);
}
"@
  [Mouse]::mouse_event(0x0002,0,0,0,0)  # left down
  Start-Sleep -Milliseconds 50
  [Mouse]::mouse_event(0x0004,0,0,0,0)  # left up
  Start-Sleep -Milliseconds 400
}

$prev = Get-Rect $h
$stable = 0
for ($i = 0; $i -lt 20; $i++) {
  Start-Sleep -Milliseconds 200
  $cur = Get-Rect $h
  if ($cur.L -eq $prev.L -and $cur.T -eq $prev.T -and $cur.R -eq $prev.R -and $cur.B -eq $prev.B) {
    $stable++
    if ($stable -ge 3) { break }
  } else { $stable = 0 }
  $prev = $cur
}
$r = $prev
$w = $r.R - $r.L; $ht = $r.B - $r.T
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$dc = $g.GetHdc()
[void][Win]::PrintWindow($h, $dc, 2)
$g.ReleaseHdc($dc)
$seen = @{}
for ($x = 10; $x -lt $w - 10; $x += 23) { for ($y = 10; $y -lt $ht - 10; $y += 23) { $seen[$bmp.GetPixel($x,$y).ToArgb()] = 1 } }
Write-Output "size=${w}x${ht} distinct=$($seen.Count) clicks=$Clicks"
Stop-Process -Id $p.Id -Force
if ($seen.Count -lt 3) { Write-Output "FAIL: blank capture"; exit 1 }
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output "SAVED $Out"
