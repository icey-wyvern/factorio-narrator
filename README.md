# Factorio Narrator

Accessibility mod that logs what the player hovers over (and related UI events) to Factorio's `script-output` so an external screen reader or TTS can speak it.

## What it does

- Logs the currently selected/hovered entity (or "terrain" when nothing is selected).
- Logs when a GUI is opened.
- Provides a custom input to read the hovered prototype on demand.

## How to use

1. Install the mod and start the game.
2. Point your cursor at entities to get automatic hover logs.
3. Press the custom input (default: `CONTROL`) to read the hovered prototype.
   - You can change this in Factorio's controls menu under the mod's input name.
4. Read the log file from:
   - `%APPDATA%\Factorio\script-output\factorio-narrator\factorio-narrator-output.txt`

## Optional narrator script (Windows)

This repo includes `narrator.py`, a simple Windows SAPI speaker that tails the output file.

Requirements:
- Python 3
- `comtypes` package

Run:

```powershell
python narrator.py
```

This will read new lines from the output file and speak them aloud.