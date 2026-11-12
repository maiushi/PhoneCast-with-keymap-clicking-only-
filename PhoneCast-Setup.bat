@echo off
title PhoneCast Setup
echo Setting up PhoneCast. This can take a minute...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = (Get-Content -Raw '%~f0') -split '(?m)^#PSSTART\r?\n', 2; Invoke-Expression $s[1]"
echo.
echo Done. Plug in your phone to start casting.
pause
exit /b
#PSSTART
# ===== PhoneCast full setup (cast + temp/fps box + keymap) =====
# 1. Install scrcpy (includes adb) and AutoHotkey
winget install --id Genymobile.scrcpy -e --accept-source-agreements --accept-package-agreements
winget install --id AutoHotkey.AutoHotkey -e --accept-source-agreements --accept-package-agreements
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')

$dir = "$env:USERPROFILE\PhoneCast"
New-Item -ItemType Directory -Force $dir | Out-Null

# 2. Auto-cast script
@'
$casting = $false
while ($true) {
  $connected = (adb devices) -match "`tdevice$"
  if ($connected -and -not $casting) {
    Start-Process scrcpy -ArgumentList "--keyboard=uhid --stay-awake --turn-screen-off --max-size=1600 --max-fps=60 --video-bit-rate=8M --print-fps" -NoNewWindow -RedirectStandardOutput "$PSScriptRoot\scrcpy-out.log" -RedirectStandardError "$PSScriptRoot\scrcpy-err.log"
    $casting = $true
  }
  if (-not $connected) { $casting = $false }
  Start-Sleep 2
}
'@ | Set-Content "$dir\watch.ps1"

# 3. Box: temperature, fps, screen buttons, keymap instructions
@'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$shell = New-Object -ComObject WScript.Shell
$f = New-Object Windows.Forms.Form
$f.FormBorderStyle = 'None'; $f.TopMost = $true; $f.ShowInTaskbar = $false
$f.BackColor = 'Black'; $f.Opacity = 0.85
$f.StartPosition = 'Manual'
$f.Size = New-Object Drawing.Size(200, 158)
$wa = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$f.Location = New-Object Drawing.Point(($wa.Right - 210), ($wa.Top + 10))

$l = New-Object Windows.Forms.Label
$l.Location = New-Object Drawing.Point(0, 2); $l.Size = New-Object Drawing.Size(200, 34)
$l.TextAlign = 'MiddleCenter'; $l.ForeColor = 'White'; $l.Text = '...'
$l.Font = New-Object Drawing.Font('Segoe UI', 14, [Drawing.FontStyle]::Bold)

$l2 = New-Object Windows.Forms.Label
$l2.Location = New-Object Drawing.Point(0, 36); $l2.Size = New-Object Drawing.Size(200, 24)
$l2.TextAlign = 'MiddleCenter'; $l2.ForeColor = 'White'; $l2.Text = '-- fps'
$l2.Font = New-Object Drawing.Font('Segoe UI', 11)

function New-Btn($text, $x) {
  $b = New-Object Windows.Forms.Button
  $b.Text = $text; $b.FlatStyle = 'Flat'; $b.ForeColor = 'White'
  $b.BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
  $b.Font = New-Object Drawing.Font('Segoe UI', 8)
  $b.Location = New-Object Drawing.Point($x, 64); $b.Size = New-Object Drawing.Size(88, 26)
  $b
}
$bOff = New-Btn 'Screen off' 8
$bOn  = New-Btn 'Screen on' 104

$send = {
  param($keys)
  $p = Get-Process scrcpy -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($p) {
    $null = $shell.AppActivate($p.Id)
    Start-Sleep -Milliseconds 250
    [Windows.Forms.SendKeys]::SendWait($keys)
  }
}
$bOff.Add_Click({ & $send '%o' })
$bOn.Add_Click({ & $send '%+o' })

$l3 = New-Object Windows.Forms.Label
$l3.Location = New-Object Drawing.Point(6, 96); $l3.Size = New-Object Drawing.Size(190, 58)
$l3.ForeColor = 'Silver'
$l3.Font = New-Object Drawing.Font('Segoe UI', 7.5)
$l3.Text = "Keymap (hover mouse on spot):`nCtrl+Alt+key = set`nCtrl+Alt+Shift+key = remove`nF8 = keymap on/off"
$f.Controls.AddRange(@($l, $l2, $bOff, $bOn, $l3))

$update = {
  $line = adb shell dumpsys battery 2>$null | Select-String 'temperature' | Select-Object -First 1
  if ($line) {
    if (-not $f.Visible) { $f.Show() }
    $t = [int](("$line" -split ':')[1].Trim()) / 10
    $l.Text = ('{0:N1}' -f $t) + [char]176 + 'C'
    if ($t -ge 45) { $l.ForeColor = 'Red' }
    elseif ($t -ge 40) { $l.ForeColor = 'Orange' }
    else { $l.ForeColor = 'LightGreen' }
  } else { $f.Hide() }

  $fps = $null
  if (Get-Process scrcpy -ErrorAction SilentlyContinue) {
    $fps = Get-Content "$PSScriptRoot\scrcpy-out.log", "$PSScriptRoot\scrcpy-err.log" -Tail 3 -ErrorAction SilentlyContinue |
      Select-String '(\d+) fps' | Select-Object -Last 1
  }
  if ($fps) { $l2.Text = $fps.Matches[0].Groups[1].Value + ' fps' } else { $l2.Text = '-- fps' }
}

$timer = New-Object Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick($update)
$timer.Start()
$f.Add_Shown($update)

$down = { if ($_.Button -eq 'Right') { $f.Close() } else { $script:drag = $_.Location } }
$move = { if ($_.Button -eq 'Left') { $f.Left += $_.X - $script:drag.X; $f.Top += $_.Y - $script:drag.Y } }
foreach ($c in $l, $l2, $l3) { $c.Add_MouseDown($down); $c.Add_MouseMove($move) }

[Windows.Forms.Application]::Run($f)
'@ | Set-Content "$dir\temp.ps1"

# 4. Keymap (AutoHotkey)
@'
#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode "Mouse", "Client"
ini := A_ScriptDir "\keymap.ini"
keys := StrSplit("abcdefghijklmnopqrstuvwxyz1234567890")

HotIfWinActive "ahk_exe scrcpy.exe"
for k in keys {
    Hotkey "^!" k, SavePos
    Hotkey "^!+" k, DelPos
    if IniRead(ini, "map", k, "") != ""
        Hotkey k, DoClick
}

#SuspendExempt
F8:: {
    Suspend -1
    Note(A_IsSuspended ? "Keymap OFF" : "Keymap ON")
}
#SuspendExempt False

Note(msg) {
    ToolTip msg
    SetTimer () => ToolTip(), -1200
}

SavePos(hk) {
    k := SubStr(hk, 3)
    WinGetClientPos , , &w, &h, "A"
    MouseGetPos &x, &y
    IniWrite Round(x / w, 4) "," Round(y / h, 4), ini, "map", k
    Hotkey k, DoClick, "On"
    Note("Saved key: " k)
}

DelPos(hk) {
    k := SubStr(hk, 4)
    try IniDelete ini, "map", k
    try Hotkey k, "Off"
    Note("Removed key: " k)
}

DoClick(hk) {
    p := StrSplit(IniRead(ini, "map", hk, ""), ",")
    if p.Length < 2
        return
    WinGetClientPos , , &w, &h, "A"
    MouseGetPos &ox, &oy
    MouseMove Round(p[1] * w), Round(p[2] * h), 0
    Click "Down"
    Sleep 30
    Click "Up"
    MouseMove ox, oy, 0
}
'@ | Set-Content "$dir\keymap.ahk"

# 5. Start all three with Windows
$startup = [Environment]::GetFolderPath('Startup')
$ws = New-Object -ComObject WScript.Shell
foreach ($n in 'watch', 'temp') {
  $s = $ws.CreateShortcut("$startup\PhoneCast-$n.lnk")
  $s.TargetPath = "powershell.exe"
  $s.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dir\$n.ps1`""
  $s.Save()
}
$s = $ws.CreateShortcut("$startup\PhoneCast-keymap.lnk")
$s.TargetPath = "$dir\keymap.ahk"
$s.Save()
Remove-Item "$startup\PhoneCast.lnk" -ErrorAction SilentlyContinue

# 6. Start (or restart) everything now
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object CommandLine -match 'watch\.ps1|temp\.ps1' | ForEach-Object { Stop-Process -Id $_.ProcessId }
Stop-Process -Name scrcpy -ErrorAction SilentlyContinue
Start-Process "$startup\PhoneCast-watch.lnk"
Start-Process "$startup\PhoneCast-temp.lnk"
Start-Process "$dir\keymap.ahk"
