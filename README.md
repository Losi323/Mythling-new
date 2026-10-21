# Mythling Realms

Mythling Realms is a Roblox collection-and-progression game project built with Luau and mapped for Rojo.

## Implemented in this branch

- Starter Mythlings and a persistent collection with individual level, XP, and evolution state.
- Basic Egg collection, server-selected rewards, validated rarity weights, and a reveal animation.
- Multi-stage progression quests covering crystal collection, Emberfall, the Forgotten Ruins vault, creature battles, egg openings, and levels.
- Starfall Haven and Emberfall, with server-validated portals and collection access.
- Server-authoritative creature pursuit and combat, visible health, XP and Starshard rewards, co-op contribution sharing, and respawns.
- A third Forgotten Ruins island with a lit, signed bridge, a three-rune vault puzzle, and a one-time persisted reward.
- World-specific visual decoration, glowing portals, floating crystals, light crystal glows, and combat damage feedback.
- Daily login reward streaks, a daily Starshard wheel, and rotating hourly global events.
- Server-authoritative four-player parties with timed invitations, accept/decline, leave/disband handling, and cleanup on disconnect.
- Optional Game Pass support for 2x Starshards and the VIP Aurora Stag companion, plus three Developer Product Starshard packs with idempotent receipt handling. All purchase IDs are intentionally zero until real products are created.
- Data normalization, transient save retries, disconnect protections, urgent-save scheduling, and persistent receipt tracking.
- Improved starter selection cards and daily wheel markers aligned to the server-selected reward.

## Project layout

- MythlingRealms/default.project.json — Rojo project mapping.
- MythlingRealms/src/ServerScriptService/MythlingServer.server.lua — authoritative game state, progression, DataStore, map, combat, events, and purchases.
- MythlingRealms/src/StarterPlayer/StarterPlayerScripts/MythlingClient.client.lua — menus, inventory, egg reveal, daily wheel, event banner, and HUD.
- MythlingRealms/src/Workspace/MythlingMap/ForgottenRuins/VaultPuzzle/VaultPuzzleScript.server.lua — rune puzzle, island geometry, and server-only reward handoff.
- MythlingRealms/CHECKLIST_AND_RELEASE.md — implementation/release checklist, including work that needs Roblox Studio.
- MythlingRealms/MONETIZATION_SETUP.md — how to configure real Game Pass and Developer Product IDs, prices, and receipt handling.

## Opening the project — no script-by-script setup

1. Download the ZIP for branch release/checklist-complete-build and extract it.
2. Install the Rojo CLI and Studio plugin using the official guide: https://create.roblox.com/docs/projects/external-tools
3. Open the MythlingRealms folder.
4. Double-click BUILD_MYTHLING.bat. It runs Rojo to build MythlingRealms.rbxlx from default.project.json.
5. Open MythlingRealms.rbxlx in Roblox Studio. The project mapping places the server, client, and Workspace files into their intended services.
6. Alternatively, run START_ROJO_SYNC.bat, then connect the Rojo plugin in Studio to sync the project live.
7. Check View > Output and follow MythlingRealms/CHECKLIST_AND_RELEASE.md before publishing.

The .bat files must be run from Windows/File Explorer, not typed into Studio. They assemble/sync the project automatically; they do not publish the experience or replace the required runtime checks..

## Important configuration

- DataStore uses MythlingRealms_PlayerData_v1; existing saves are normalized when loaded.
- Game Pass IDs are in GAMEPASS_IDS and consumable product IDs in DEVELOPER_PRODUCTS near the top of MythlingServer.server.lua; zero means disabled.
- Developer Product receipt handling is implemented, but no consumables are active until real product IDs are configured.
- Direct pet trading and gifting are intentionally omitted until a transactional inventory-transfer flow can prevent duplication or item loss.
- The scripts have been statically reviewed in this branch, but they have **not** been compiled or executed in Roblox Studio in this environment. This repository branch is a consolidated implementation candidate, not a verified production release.

## Current work branch

release/checklist-complete-build

Review this branch and its pull request before merging it into main.
