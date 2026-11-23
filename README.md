# PetPulse

A companion HUD for Hunters and their pets in **World of Warcraft: Forever**.

PetPulse keeps feeding, happiness, pet XP, training and ammunition close at hand. Hover over your pet portrait to open the controls, or use the minimap paw to open the settings.

![PetPulse HUD](docs/screenshots/01-hud.png)

## Features

- **Smart Feed:** chooses food your current pet can eat. Safe food takes one click; potentially valuable, buff or quest-related food asks for confirmation. Right-click to choose a specific item with its game tooltip.
- **Pet care:** happiness, feeding duration, pet death and low-health warnings. The portrait changes to Call Pet or Revive Pet when needed.
- **Pet XP:** a progress ring around the portrait and a central level-up announcement.
- **Training Guide:** choose a main pet, see what can be taught now and what unlocks next, and find source beasts, trainers and recorded stable locations.
- **Beast tooltips:** recorded abilities with readable spell icons and their relevance to your main pet. Nearby tips use units actually exposed by the client.
- **Bestiary and Top Picks:** family, level and zone filters, map locations and role-based recommendations.
- **Ammunition:** compatible arrow/bullet counts, adjustable thresholds and central low/critical/empty warnings. Font, color and collapsed visibility are configurable.
- **Companion styles:** 19 pet-family sets with happy, neutral and unhappy artwork, plus the Classic set.
- **EN / SK / CZ**, movable HUD, minimap launcher and per-character preferences.

![Training Guide](docs/screenshots/05-training-guide.png)
![Companion styles](docs/screenshots/04-mood-families.png)

## Install

Download **PetPulseForever-1.6.6.zip** from [Releases](../../releases/latest), then extract the `PetPulseForever` folder into:

`World of Warcraft/_forever_/Interface/AddOns/`

Restart WoW, enable PetPulse Forever and log in on a Hunter. This build targets **Forever Interface 16001**, not Retail or Classic Era.

## Quick start

- `/petpulse` — settings.
- `/petpulse training` — Training Guide; **Choose** selects your main pet.
- Minimap paw: left-click for settings, right-click for training; drag to reposition.
- `/petpulse minimap` — show/hide the minimap icon.
- `/petpulse unlock` and `/petpulse lock` — move and lock the HUD.
- Right-click Smart Feed — choose food manually.

## Screenshots

[Smart Feed](docs/screenshots/02-smart-feed.png) · [Companion Care](docs/screenshots/03-companion-care.png) · [Ammo settings](docs/screenshots/06-ammo-settings.png)

## What to expect

Version 1.6.6 is the first public release. Core flows have been tested in game; 118 deterministic mock tests cover behavior, but cannot emulate all Blizzard secure UI behavior.

Training and location catalogs may be incomplete or differ after updates. Map locations are recorded habitats, not live-spawn tracking. Learning an ability requires taming and using the source pet; killing a beast does not teach it. Training remains a manual action in the game's Beast Training interface. Same-name pets of the same family share a selector identity, so give distinct companions distinct names.

Food safety uses the client's current pet diet plus catalog and quest information. Unknown or protected candidates require review; the addon cannot know the personal value of every item.

## Feedback

Please use [Issues](../../issues) and include your addon version, Forever client build, steps to reproduce and a screenshot or Lua error when relevant. Do not post account credentials or SavedVariables containing information you do not want public.

## Development

Source is in `PetPulseForever/`. Run the checks with Python 3:

```sh
python -m pip install lupa Pillow
python PetPulseForever/Tests/validate.py
```

## Credits

**Addon Creator:** Wixin  
**Special Thanks:** Ewelyn & Lucy  
Created for all Hunters and their beloved pets.

Training data adapted from [TrueshotLodge](https://github.com/chazlander/TrueshotLodge) under MIT; the full notice is bundled. Other data notes are in the training documentation. Companion illustrations use AI-assisted artwork; the paw logo is a geometric mark.

See [LICENSE.txt](LICENSE.txt) and [third-party notices](PetPulseForever/THIRD-PARTY-NOTICES.txt).
