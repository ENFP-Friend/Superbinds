# Independent profile packs

The TOC loads `SuperBinds.lua`, then `Profiles/Druid/Balance.lua`. There is no `Profiles/Balance.lua` duplicate. Add a second profile file to the TOC after the engine and call `SuperBinds.RegisterProfile(table)` from it. No engine edit is needed.

Profile data follows `SUPERBINDS-BRIEF.md`: `name`, `class`, `familyMode`, `default`, `families`, `hardware`, `reserved`, `camera`, `exclude`, `neverBind`, `sculptures`, `theme`, `macros`, `barBinds`. The explicit Balance-first request overrides the brief's earlier shipping-pack examples.

Each family has a stable `tag`, `title`, `caption`, optional `bar`, and `items`. Abilities accept `spell={IDs or names in preference order}`, `target`, `label`, `bindKey`/`key`, `slot`, `itemID`, `equipmentSlot`, `macrotext`, `macro={short,icon,body}`, `requires`, `iconFile`, or optional `sba`. Stable tags and row positions identify saved overlays. Reordering stock rows can move existing row customisations, so migrate them deliberately when revising a pack.

A spell with `target="cursor"` or a macro containing `@cursor` requires an explicit action slot on that form's bar (relative 1–12). Mouse bindings to non-slot entries use named macros, SPELL or ITEM commands, not CLICK. Named macros use collision-free `SuB` names and normal game macro storage. Macro text longer than 255 bytes is rejected. Hardware entries supply `slot` and optional `macro` referencing `profile.macros[name]={body=...,icon=...}`. `barBinds` can map default keys to ACTIONBUTTON slots.

## Stance / form action bars

Packs that shapeshift or stance-dance declare `actionBars`. The engine does not hardcode Druid, Warrior, or Rogue. Each named form (from `forms` / `form`) maps to a native bar:

```lua
actionBars = {
  caster = { page = 1 },           -- unshifted / default page
  cat    = { bonus = 1 },          -- GetBonusBarOffset() while in that form
  bear   = { bonus = 3 },
  travel = { page = 1, use = "caster" }, -- share another form's bar
}
```

`bonus` uses WoW's bonus-bar index (cat/stealth 1, bear 3, moonkin 4, warrior stances 1–3). Relative `slot=1` on that form is ACTIONBUTTON1; WoW swaps the underlying slots. Keys stay 1–12.

Family faces per form: `bars={ caster={slot=1,spell=...}, cat={slot=1,spell=...} }`. Shapeshifts that must work on every bar: `allBars=true` on the same relative slot. Drawer rows may set `form="cat"` so they only appear in that layout.

The secure page driver is `[bonusbar:N]`; it updates in combat. Apply still places each form's macros on that form's absolute slots while you are out of combat.

## Rotation extensions

- `useBlizzardSBA=false`: never consult the Blizzard next-cast API. Optional true enables the generic assistant path for another pack.
- `form="caster"`: identifier used when the current shapeshift API index is zero.
- `forms={identifier={spells={formSpellIDs or names}}}`: maps the active form spell reported by `GetShapeshiftFormInfo` to a profile identifier. Never infer a form from a hardcoded numeric form index.
- `rotation={identifier={ordered rules}}`.
- Rule fields: `spell={...}`, `auraMissing=true` (own harmful target aura), `powerType=<WoW resource enum>`, `minPower=<number>`, `fallback=true` (author-designated no-cooldown filler). Unknown conditions are skipped. Use fallback sparingly.
- `neverSuggest={IDs and/or names}`: hard exclusion before recommendations. Manual forms belong here and in the console, never the priority lists.

Themes accept `brass={r,g,b}`, `endcap` / `endcapHorde`, sizes, and `endcaps={ bear={path,width,height,leftIn}, cat=..., travel=... }`. Form art follows the shapeshift name, not `BarOwner` (travel can share caster slots and still use the sable). The engine mirrors the right endcap.

Sculptures are optional data: `names`, `file`, `size` or `width`/`height`, `tuck`, `behind`, `uv`, `fillTop`. They render on separate UIParent frames with grey bases and masked colour fill. Public cooldowns or an observed cast's base cooldown drive their fill. Secret values are not inspected. Balance ships `sculptures={}` and no sculpture art.
