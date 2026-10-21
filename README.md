# Mythling Realms

Mythling Realms is a Roblox collection-and-progression game project built with Luau and mapped for Rojo.

## Implemented in this branch

- Starter Mythlings and a persistent collection with individual level, XP, and evolution state.
- Basic Egg collection, server-selected rewards, validated rarity weights, and a reveal animation.
- Multi-stage progression quests covering crystal collection, Emberfall, the Forgotten Ruins vault, creature battles, egg openings, and levels.
- Starfall Haven and Emberfall, with server-validated portals and collection access.
- Basic server-authoritative creature combat, visible creature health, XP and Starshard rewards, co-op contribution sharing, and respawns.
- A third Forgotten Ruins island with a three-rune vault puzzle and one-time persisted reward.
- Daily login reward streaks, a daily Starshard wheel, and rotating hourly global events.
- Optional Game Pass support for 2x Starshards and the VIP Aurora Stag companion. Both pass IDs are intentionally set to zero until real passes are created.
- Data normalization, transient save retries, and protections for disconnects during player data loading.

## Project layout

- MythlingRealms/default.project.json — Rojo project mapping.
- MythlingRealms/src/ServerScriptService/MythlingServer.server.lua — authoritative game state, progression, DataStore, map, combat, events, and purchases.
- MythlingRealms/src/StarterPlayer/StarterPlayerScripts/MythlingClient.client.lua — menus, inventory, egg reveal, daily wheel, event banner, and HUD.
- MythlingRealms/CHECKLIST_AND_RELEASE.md — implementation/release checklist, including work that needs Roblox Studio.
- MythlingRealms/MONETIZATION_SETUP.md — how to configure the real Game Pass IDs.

## Opening the project

1. Clone or download this repository.
2. Open the MythlingRealms directory as a Rojo project using default.project.json.
3. Sync the project to a Roblox Studio place using the Rojo plugin.
4. Publish a private test place and enable Studio access to API services before testing DataStore behavior.
5. Open Output and check for runtime errors. Follow the outstanding items in MythlingRealms/CHECKLIST_AND_RELEASE.md.

## Important configuration

- DataStore uses MythlingRealms_PlayerData_v1; existing saves are normalized when loaded.
- Game Pass IDs are in GAMEPASS_IDS near the top of MythlingServer.server.lua; zero means disabled.
- No developer-product consumables are configured.
- The scripts have been statically reviewed in this branch, but they have **not** been compiled or executed in Roblox Studio in this environment. This repository branch is a consolidated implementation candidate, not a verified production release.

## Current work branch

release/checklist-complete-build

Review this branch and its pull request before merging it into main.
