# Training guide — 1.6.7

## How it works

Select your main pet with Choose → Use my current pet. The guide keeps that selection when you bring out a temporary pet. If the client assigns a new GUID after stabling, the selected main pet is rebound by exact name and family. Duplicate snapshots are grouped in Choose without deleting history. Different pets of the same family should have different names; name/family matching cannot distinguish identically named pets. The saved snapshot is explicitly labelled. No pet is automatically abandoned, stabled or tamed.

Hunter knowledge is read using the teaching spell's learn_id, or positively confirmed by the game's learning message / Beast Training services. A temporary pet knowing an ability does not mean the hunter has learned it. Use the ability until the game confirms learning, then retrieve and train your main pet. Final training eligibility is always checked by the game's own Beast Training interface. The guide checks family, pet level, current rank, incremental training-point cost and the four-active-ability limit.

Level-up notices compare the selected pet's observed levels within the session. Login, reload, unchanged level and temporary pets do not generate notices. A level increase queues until the spellbook is available and combat ends. One combined HUD notice and chat details show newly level-eligible ranks; training points or other requirements may still be missing. The toggle is independent of nearby alerts. Skipped levels are handled together.

## Database provenance

Ability/rank/NPC/trainer facts adapted from the MIT-licensed TrueshotLodge data repository:
https://github.com/chazlander/TrueshotLodge
Snapshot: 8ca00b18cde7d8f7fab9b40bfc25b6ec7f1640b8 (2026-11-22).
Full MIT notice is in THIRD-PARTY-NOTICES.txt. Runtime and interface code are PetPulse code. Contributor identities were not imported.

32 abilities / 155 ranks / 813 beasts / 18 pet trainers. Not every rank has a documented source. The additional Lava Breath client spells (444678/444681, teaching spells 444680/444682) come from Forever build 71037; their source NPCs remain unknown. Core Hound compatibility and level requirements follow https://www.wow-petopia.com/forever/abilities.php . Training mechanics: https://www.wow-petopia.com/forever/training.php .

24 independently formatted reference stable location facts (names, map coordinates and faction) checked against:
https://forevermastery.com/en/npcs/category/stable-masters
These are Classic reference positions, not confirmed Forever sightings. Personal PET_STABLE_SHOW interactions record your position near the NPC and override same-name reference records. No remote data is downloaded by the addon. The stable catalog is intentionally labelled incomplete rather than guessing missing NPCs or positions.

## Location and client limits

- Nearby alerts only inspect exposed target/mouseover/nameplate units, never scan the hidden world. Each NPC type has a ten-minute alert cooldown. Combat, dead/player-controlled units, level restrictions and unknown hunter knowledge suppress misleading opportunities.
- Map pins represent recorded habitats, not an individual currently alive beast. Some ranks lack a source; some beasts lack recorded abilities. Beast Lore and tame observations can improve your personal database.
- Nearest source recommendations require the entire recorded NPC level range to fit your hunter level. Other catalog entries remain inspectable manually.
- Distance ranking uses comparable world positions on the same continent where the client exposes them. Without that API it compares positions only inside your current zone. Other zones remain alternatives, never claimed to be globally nearest. Distances are straight-line estimates, not pathfinding through mountains, dungeons, boats or flight routes.
- The nearest stable is the closest measurable friendly record in the included/personal data, not a claim to cover every stable in Forever. Unknown faction cannot select an enemy faction's record; neutral records remain eligible.
- Native waypoint support varies by client. Show on map always attempts to open the known map; pin creation requires the client's waypoint API.
- Guide windows close in combat and secure training still requires your click. Changes to stable slots, taming and training remain manual.
- Pet snapshots and learned ranks are saved per character. Resetting presentation settings preserves this progress.
- English fallback names in the external NPC catalog may remain English on a non-English game client. PetPulse's interface and advice support EN/SK/CZ.

## Validation

Tests/validate.py compiles every Lua file with Lua 5.1, loads the TOC under a deterministic API mock, runs 67 existing and 60 guide tests, and verifies image assets. Guide tests cover every catalog source ID and compressed coordinate, separate hunter knowledge, family/level/points/slots, personal overrides, trainer offers, learning messages, tooltip deduplication, zone filtering, nearest-point logic, factions, level-up baseline/combat/temporary pets and the guide window.

These checks do not emulate Blizzard secure execution or prove in-game appearance. Test the first real level-up, learning message, stable interaction, tooltip and map action in the Forever client after a full restart.

Version 1.6 replaces the old four-view UI with a main-pet overview, filtered Bestiary and role-based Top Picks. The full ability catalog still drives tips, level-up notices and bestiary details. The overview selects one upgrade per ability, prioritizing a known, affordable, teachable rank over a higher rank that first needs acquisition. The header count refers to these distinct abilities, not every historical rank.
