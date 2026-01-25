# Factorio Narrator

Accessibility mod that logs what the player hovers over (and related UI events) to Factorio's `script-output` so an external screen reader or TTS can speak it.

## What it does

- Logs the currently selected/hovered entity (or "terrain" when nothing is selected).
- Logs when a GUI is opened.
- Provides a custom input to read the hovered item on demand.

## Installation

1. Clone this repo into your Factorio mods folder:
   - `%APPDATA%\Factorio\mods\factorio-narrator`
2. Start Factorio and enable the mod.

## How to use

1. Install the mod and start the game.
2. Point your cursor at entities to get automatic hover logs.
3. To narrate inventory items, hover the item and press the custom input (default: `CONTROL`).
   - You can change this in Factorio's controls menu under the mod's input name.
4. Read the log file from:
   - `%APPDATA%\Factorio\script-output\factorio-narrator\factorio-narrator-output.txt`

## Narration (Windows)

This repo includes `narrator.py`, a Windows-only SAPI speaker that tails the output file.
You must run this script to hear narrations.

Requirements:
- Python 3
- `comtypes` package (see `requirements.txt`)

Run:

```powershell
pip install -r requirements.txt
```

Then:

```powershell
python narrator.py
```

This will read new lines from the output file and speak them aloud.
