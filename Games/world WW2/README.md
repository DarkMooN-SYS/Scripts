# Conquer The World WW2 — Quick Readme

## What this game is

**Conquer The World WW2 [🎃]** is a fast global strategy game inspired by Hearts of Iron. You choose a country, develop its economy and military, manage diplomacy, and capture enough territory to win.

Live place inspected: place `14422394494`, version `12949`, creator `Marian_Dev`.

## Basic game loop

1. Select a country from the country-selection menu.
2. Build your economy and choose what your factories produce.
3. Research technologies and unlock military, industrial, air, naval, and missile upgrades.
4. Train and expand your army; deploy troops to map tiles and move or attack neighboring territory.
5. Use diplomacy to form alliances, declare war, request peace, create or manage puppets, and call allies into wars.
6. Capture territory, defend important cities, and improve your win score.
7. Reach the map's territory-based win condition or survive until the match ends.

## Main systems

### Country selection

The selection screen supports searching and sorting countries by name, power, or recommendation. Country power is associated with division strength. Changing countries can be restricted by a cooldown during a match.

The live place contains multiple map scenarios and country data for Europe, Eurasia, and world-scale maps, including WW1, WW2, Cold War, and modern settings.

### Economy and production

The Production menu tracks civilian factories, military factories, consumer-goods income, military expenses, navy expenses, profit, factory productivity, stockpiles, and production lines.

Use production lines to turn factory capacity into military and economic outputs. Keep an eye on profit: army, navy, and other projects create continuing costs.

### Army

The Army menu manages at least these troop classes:

- Infantry
- Tanks
- Anti-Tank

You set training targets, pay the cost to increase them, and wait for training to complete. Manpower and daily military expenses limit how quickly an army can grow. Troops can be selected on map tiles, moved, halted, deployed, and used in combat.

### Research

Research is organized as a technology tree with research slots. Technologies improve areas such as production, army performance, fortifications, aircraft, ships, and missiles. Start research from the Research menu and monitor active slots from the HUD.

### Diplomacy and government

The Diplomacy menu shows relations, ideology, allies, enemies, puppets, factories, manpower, divisions, ships, research, aircraft, and nuclear capability. Available actions include declaring war, requesting alliances or peace, calling allies to war, sending aid, demanding territory, justifying war goals, and managing puppet relationships.

The Government menu handles ideology changes and government focus systems. Ideology changes have political-power and money costs.

### Air force and navy

Airfields and airports support aircraft deployment, movement, range, priority, and upgrades. Naval systems include ship purchases and shipyard upgrades. Air and naval control can support invasions and protect your territory.

### Missiles and nuclear weapons

Tile projects include forts and missile silos. Missile silos can launch missiles or nukes and can automatically intercept incoming silo weapons. Research and silo levels affect range, damage, penetration, city-project damage, and interception.

The inspected scripts describe missile levels with increasing range and damage; exact availability and costs depend on the current scenario and technology state.

## How victory works

Victory is based on a territory score calculated from controlled map tiles plus diplomatic relationships. The game weights territory differently for countries with opposite, different, or matching ideologies, and gives a reduced contribution to puppets.

In practical terms: expand your own territory, build reliable allies, and use puppets strategically, but do not rely on diplomacy alone. The win progress bar on the top HUD shows progress toward the current map's territory threshold.

## Recommended first match

Choose a medium or strong country so you have room to learn. Open Production early, keep a positive economy, start research immediately, and train infantry before investing heavily in advanced units. Secure nearby borders with diplomacy, then expand toward weak or isolated neighbors. Build airfields and forts around important cities before starting a large war.

## Important UI locations

- `CountrySelection`: choose and search for a nation.
- `GameGui > Menus > ProductionMenu`: factories and economy.
- `GameGui > Menus > ArmyMenu`: manpower and troop training.
- `GameGui > Menus > ResearchMenu`: technology tree and research slots.
- `GameGui > Menus > DiplomacyMenu`: foreign relations and war actions.
- `GameGui > Menus > GovernmentMenu`: ideology and focuses.
- `GameGui > Menus > AirforceMenu`: aircraft and missile actions.
- `GameGui > TileInfo`: selected tile, city, project, and troop information.

## Notes and limitations

This guide is based on the live client and decompiled client-visible structures at the time of inspection. UI names, balance, costs, map availability, and rules can change after an update. The game currently reported 1,123 indexed scripts and place version `12949`.
