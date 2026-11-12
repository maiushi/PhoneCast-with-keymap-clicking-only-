# PhoneCast

Mirror and control your Android phone on a Windows PC. Plug the phone in with a USB cable and it casts automatically.

## Download

**[Click here to download PhoneCast-Setup.zip](https://github.com/maiushi/PhoneCast-with-keymap-clicking-only-/raw/main/PhoneCast-Setup.zip)**

Extract the zip, then double-click `PhoneCast-Setup.bat`.

If Windows shows "Windows protected your PC", click **More info**, then **Run anyway**.

## What it sets up

- **Auto-cast:** the phone screen opens on your PC whenever you plug it in, using [scrcpy](https://github.com/Genymobile/scrcpy). Control it with your mouse and keyboard.
- **Info box:** shows the phone's temperature and the cast's fps, with Screen off / Screen on buttons. It hides when the phone is unplugged.
- **Keymap (clicking only):** press a key to tap a spot on the phone, using [AutoHotkey](https://www.autohotkey.com/).
- Everything starts with Windows, and restarts itself within 5 minutes if it ever stops.

## Phone setup (one time)

1. Settings → About phone → tap **Build number** 7 times (on Xiaomi/POCO/Redmi: **OS version**).
2. Developer options → turn on **USB debugging**.
3. Xiaomi/POCO/Redmi only: also turn on **USB debugging (Security settings)**, or the mouse and keyboard won't work.
4. Plug in with a data cable and tap **Allow** when the phone asks. Only allow PCs you trust.

## Keymap

Works only while the cast window is active.

| Action | Keys |
| --- | --- |
| Set a key (hover the mouse over the spot first) | `Ctrl + Alt + key` |
| Remove a key | `Ctrl + Alt + Shift + key` |
| Keymap on/off (turn off to type) | `F8` |

Letters A–Z and numbers 0–9. Taps only, no dragging or holding.

## Shortcuts in the cast window

| Action | Keys |
| --- | --- |
| Phone screen off (keeps casting) | `Alt + O` |
| Phone screen on | `Alt + Shift + O` |
| Home / Back / Recent apps | `Alt + H` / `Alt + B` / `Alt + S` |
| Fullscreen | `Alt + F` |

## Remove

Press `Win + R`, type `shell:startup`, and delete the three `PhoneCast` shortcuts. Then run this in PowerShell to remove the auto-restart tasks:

```powershell
Unregister-ScheduledTask -TaskName PhoneCast-watch, PhoneCast-temp -Confirm:$false
```

Finally, delete the `PhoneCast` folder in your user folder.

## Notes

- Works with most Android phones (Android 5+). Not iPhones.
- Some apps (like GCash and banking apps) won't open while Developer options is on. Turn it off when you need them.
