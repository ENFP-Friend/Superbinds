# Files for Astra

Work **in this folder**: `C:\Users\Nick\Documents\Websites\SuperBinds`

Nick keeps playing and editing GUI in **Shaman Binds** (`Documents\Websites\ShamanBinds`). Do not modify that tree unless asked.

## Read

1. `docs/SUPERBINDS-BRIEF.md` — spec (engine vs profile, acceptance grep)
2. `_reference/ShamanBinds.lua` — working 8.34 reference (do not TOC-load it)
3. `_reference/ShamanBinds.toc`
4. `docs/TOTEM-ART.md` — sculpture renderer rules (list itself is profile data)
5. `Media\` — TGAs to keep using from profile theme/sculptures paths

## Write

- `SuperBinds.lua` — engine (no class spell names)
- `Profiles\Shaman_Prime.lua` / `Shaman_Farseer.lua` / `Shaman_Pocket.lua` — fill from reference `Build*Families`
- `SuperBinds.toc` — already lists those files

## Do not

- Touch `C:\Users\Nick\Documents\Websites\ShamanBinds` (live GUI)
- Load `_reference` from the TOC
- Commit or push unless asked
- Invent Druid as a finished class; a stub profile is enough to prove the split
