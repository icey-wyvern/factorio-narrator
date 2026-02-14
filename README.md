# Factorio Narrator

Accessibility mod that logs what you hover over (and related UI events) to Factorio's `script-output` for a screen reader or TTS.

## What it does

- Logs the currently selected/hovered entity (or "terrain" when nothing is selected).
- Logs when a GUI is opened.
- Provides a keybind to read the hovered item/prototype.
- Trims the output log automatically if it grows beyond 10 KB (checked every ~5 minutes).

## Installation

1. Clone this repo into your Factorio mods folder:
   - `%APPDATA%\Factorio\mods\factorio-narrator`
2. Start Factorio and enable the mod.

## How to use

1. Install the narrator requirements, then run the narrator script:
   - `pip install -r requirements.txt`
   - `python narrator.py`
2. Run Factorio and enable the mod.
3. Point your cursor at entities to get automatic hover logs.
4. Press `1` to read the currently hovered item/prototype (inventory, recipe icons, filter selectors, etc.).
   - You can change this in Factorio's controls menu under the mod's input name.
5. Output file (also what the narrator speaks):
   - `%APPDATA%\Factorio\script-output\factorio-narrator\factorio-narrator-output.txt`
