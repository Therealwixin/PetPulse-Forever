# Changelog

## 1.6.6 — 2026-11-23

- Back to settings button in Training Guide, retaining the previously selected settings tab.
- Draggable minimap paw: left click opens settings, right click opens Training Guide. Position saved per character; hide in General or toggle with /petpulse minimap.
- EN/SK/CZ labels, 118 simulated behavioral tests and minimap asset validation.

## 1.6.5 — 2026-11-23

- Beast mouseover tooltips show a 28px native spell icon beside each recorded teachable ability, with readable spacing and existing rank/status text.
- Missing spell textures retain the ability name with a question-mark fallback.
- 114 simulated behavioral tests.

## 1.6.4 — 2026-11-22

- Persistent central ammo warning for arrows and bullets, independent of HUD expansion and other alerts. Clears after replenishment, disabling ammo alerts or unavailable counts.
- Audible low/critical/empty transitions with cooldown, respecting the sound preference; no sound on every shot. Initial low inventory is displayed after UI creation.
- Large central main-pet level-up announcement for seven seconds, including levels without newly unlocked ranks. Combat deferral and level-alert preference retained. Separate positions allow both notices at once.
- 112 simulated behavioral tests.

## 1.6.3 — 2026-11-22

- Consistent 200 × 50 logo size in both windows.
- Settings logo centered in the header; Training Guide logo and title centered as one group, aligned vertically with matching top padding.

## 1.6.2 — 2026-11-22

- Logo paw changed from gold to brick red.
- FOREVER increased from 17 to 32 source pixels, semibold, in light neutral lettering for legibility at header size.
- Existing paw and PetPulse wordmark retained; no gameplay changes.

## 1.6.1 — 2026-11-22

- Main pet uses the live game portrait, cached portrait when stabled, and native family fallback.
- Summon GUID snapshots grouped by name/family in Choose; returning main pet rebinds without losing level-up tracking. Historical snapshots retained.
- Up-to-date pets now see the next rank per ability, ordered by required pet level, with future requirements in the detail.
- EN/SK/CZ strings and 106 simulated behavioral tests.

## 1.6.0 — 2026-11-22

- Rebuilt Training Guide around My Pet, Bestiary and Top Picks, with a permanent main-pet selector and clear training status.
- One relevant rank per ability; ready upgrades take priority. Unknown data never becomes an all-clear.
- Bestiary: 14 rows, family portraits, direct family selection, level/zone filters and search.
- Eight role-based pet picks with level colors, reasons and dated source attribution. Rare appearances are distinguished from performance recommendations.
- Contextual detail buttons; alert settings moved into a compact panel; automatic window fit on smaller screens.
- Resolve exact live zone names when the client returns a continent map.
- EN/SK/CZ strings and 101 simulated behavioral tests.

## 1.5.1 — 2026-11-22

- Settings and Training Guide now close each other instead of interleaving at the same frame strata. Combat guards preserve the currently open settings window.
- Both windows use an opaque background with the native Blizzard dialog texture and border, without teal/gold tint.
- Result pages immediately select their first entry and show details.
- Four regression tests added: 92 total simulated behavioral tests.

## 1.5.0 — 2026-11-22

- Training guide: 813 beasts, 155 ranks, 32 abilities, 18 pet trainers; zone/family/level/knowledge filters, search and map actions.
- World-unit tooltip additions and deduplicated nearby learning opportunities.
- Separate hunter knowledge, main-pet snapshots, temporary-pet observations and tracked learning progress.
- Main-pet level-up advice, deferred in combat, with training/stabling/taming next steps and a separate toggle.
- 24 reference stable locations plus personal stable interaction records; faction filtering and measurable nearest recorded locations.
- EN/SK/CZ training UI, native spell tooltips, source provenance and MIT attribution.
- 88 simulated behavioral tests; live secure execution and rendering still need in-game testing.

## 1.4.2 — 2026-11-22

- Credits tab: Wixin, special thanks to Ewelyn & Lucy, dedication, version, revision, release date and interface target.
- Addon author metadata set to Wixin.
- Feed Once now uses the native red button template, matching Cancel while retaining secure feeding and confirmation checks.


## 1.4.1 — 2026-11-21

- Pet XP shown as a clockwise violet arc within the portrait ornament, visible both collapsed and expanded.
- Portrait tooltip shows exact XP, percentage and XP remaining.
- UNIT_PET_EXPERIENCE refreshes the ring without bag scans.
- Missing/invalid XP and dead/absent pets hide the ring instead of inventing a cap or progress.
- 67 simulated behavioral tests.


## 1.4.0 — 2026-11-21

- Circular, restrained hover glow with transparent corners; round menu medallion.
- Native paw-and-pulse logo in settings; General / Ammunition / Mood icons tabs.
- All 19 hunter families (57 mood textures), three-state previews and Classic fallback.
- Ammo moves 13 px closer to the collapsed portrait; optional collapsed visibility, RGB color and Blizzard UI font.
- Right-click food picker: native bag tooltips, pagination, protected entries, explicit selection and automatic mode.
- Manual selection revalidates diet, inventory and protection on every feed; missing selections never silently substitute food.
- 64 simulated behavioral tests.


## 1.3.0 — 2026-11-21

- Strong gold hover border and icon illumination.
- Expanded HUD hamburger opens settings.
- EN / SK / CZ language selector for addon menus, tooltips and meal captions; native item/spell text remains client-provided.
- Selectable Wolf, Fox, Cat, Crocolisk and Classic mood icons. New sets retain green joy rays, yellow sparkles and red lightning.
- Larger unmasked mood artwork and transparent game-ready textures.
- Feeding selection and action rules unchanged.


## 1.2.3 - 2026-11-21

- Ten cute meal captions, stable throughout each meal, without consecutive repeats.
- Visible gold hover highlight, including secure action buttons.
- Private tooltips with text enlarged by 2 px; default game tooltips unaffected.
- Feeding policy unchanged; 55 simulated behavioral tests passed.

## 1.2.2 — 2026-11-20

- Teplé kovové ozdoby bez zeleného tintu a výraznejšie úchyty.
- Friz Quadrata pre Ammo namiesto Arial Narrow.
- Trvalo viditeľné Ammo pod zbaleným petom; plynulý oblúkový presun do pravej pozície.
- Feeding pravidlá nezmenené; 52 simulovaných testov.


## 1.2.1 — 2026-11-20

- Jemnejšie kovové objímky bez navrstvených kruhov; zachované ozdoby a prepojenie shardu.
- Smart Feed: výrazný typ potraviny, skutočné natívne item efekty a konkrétne questové stavy.
- Feeding pravidlá bez zmeny, overené porovnaním súborov s 1.2.0.
- 49 behaviorálnych testov a aktualizovaný náhľad textúr.


## 1.2.0 — 2026-11-20

- Cute puppy mood ikonky, zdobený trvalý portrét a čitateľnejší sans-serif ammo font.
- Companion Care tooltip a presúvajúci sa bonding feeding badge s reálnym aura odpočtom.
- Smrť peta: warning a centrálny secure Revive/Call macro, vrátane manuálneho Shift-Revive fallbacku.
- Jemný pod-20-percentný health warning s natívnou secret-safe display krivkou.
- Audit 5 982 questov, 49 food väzieb, kontrola dokončenia všetkých súvisiacich questov, ochrana repeatables.
- Questové jedlo je s potvrdením; buffové/drahé/neoverené až ako posledná možnosť. Nižší item level má prioritu v rámci skupiny.
- 45 automatických behaviorálnych testov; in-game testovanie zostáva potrebné.


## 1.1.0 — 2026-11-20

- Kompletný 411-položkový katalóg pet food z Blizzard DB2 buildu 71037, audit všetkých spell efektov a triggerov.
- Opravené vylučovanie bežných cooking reagentov. Chunk of Boar Meat má prednosť pred chráneným Goretusk Liver Pie.
- Buffy sa chránia podľa spell dát aj bez anglického tooltipu; odstránený nespoľahlivý vendor allowlist.
- Veľká plocha na voľné ťahanie v Unlock režime, priame Lock HUD, deaktivované akcie počas presúvania.
- Súvislý kovovo-kryštálový shard a tri vlastné farebné happiness emblémy. Feed naďalej zobrazuje jedlo.
- Skrátený Feed tooltip; explicitný dôvod ochrany.
- 33 automatických behaviorálnych testov; grafické a Lua kontroly.


## 1.0.0 — 2026-11-20

- Prvé vydanie pre Forever Interface 16001.
- Kruhový 44 px portrét, vlastné happiness ikony a rozbalenie do štyroch smerov.
- Zdieľaná mouseover geometria s toleranciou 280 ms bez blokovania kliknutí v medzerách.
- Jednoklikový Smart Feed s klientskou diet kontrolou, opätovnou validáciou a explicitným potvrdením hodnotného jedla.
- Aktuálny feeding efekt bez vymysleného hunger timeru.
- Tooltip so štatistikami, rezistenciami, diétou, loyalty a TP.
- Overovanie tréningu podľa aktuálnej pet trainer session; žiadne upozornenie iba podľa TP.
- Ammo count podľa zbrane a required level; 300/200 hranice, nulový stav, cooldown a refill reset.
- Anglické nastavenia, per-character SavedVariables, oddelené secure vrstvy a slovenská dokumentácia.
- Statická a simulovaná validácia. In-game akceptačný test zostáva potrebný.
