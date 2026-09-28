# Independent profile packs

The core TOC loads `SuperBinds.lua` only. Class packs are sibling addons. Druid is `SuperBinds_Druid` (`## Dependencies: SuperBinds`, no `LoadOnDemand`). It calls `SuperBinds.RegisterProfile(table)` from each pack file. Do not add pack files to `SuperBinds.toc`. Do not use `LoadWith` — that marks the class addon on-demand and the console can build before the packs exist. Optional `hero=` (Druid Elune’s Chosen = 24) so two packs with the same `spec` do not race.

**Engine = how buttons, binds, form pages, and chrome work. Profile = which abilities, keys, and labels a class uses.**

How to author a pack from `/superbinds probe` (vital verbs, role-named families, agent workflow): [`PROFILE-GUIDE.md`](PROFILE-GUIDE.md). Known errors + owed engine rework: [`ISSUES.md`](ISSUES.md).

Minimum fields: `name`, `class`, `familyMode`, `default`, `families`, plus optional `spec`, `nativeForm`, `forms`, `actionBars`, `hardware`, `reserved`, `camera`, `exclude`, `neverBind`, `neverSuggest`, `sculptures`, `theme`, `macros`, `barBinds`, `rotation`, `useBlizzardSBA`.

Each family has a stable `tag`, `title`, `caption`, optional `bar` or `bars`, and `items`. Abilities accept `spell={IDs or names in preference order}`, `target`, `label`, `bindKey`/`key`, `slot`, `itemID`, `equipmentSlot`, `macrotext`, `macro={short,icon,body}`, `requires`, `iconFile`, `sba`, `allBars`, `form`. Stable tags identify saved overlays. Reordering stock rows can move existing row customisations — migrate them deliberately.

A spell with `target="cursor"` or a macro containing `@cursor` requires an explicit action slot on that form’s bar (relative 1–12). Mouse bindings to non-slot entries use named macros, SPELL or ITEM commands, not CLICK. Named macros use collision-free `SB_` names. Macro text longer than 255 bytes is rejected. Hardware entries supply `slot` and optional `macro` / `spell`. `barBinds` maps default keys to `ACTIONBUTTON` slots.

## Stance / form action bars

This is the product. Packs that shapeshift declare `actionBars`. The engine does not hardcode Druid. Each named form maps to a native bar:

```lua
actionBars = {
  caster  = { page = 1 },                 -- unshifted
  cat     = { bonus = 1 },                -- GetBonusBarOffset() while in that form
  bear    = { bonus = 3 },
  moonkin = { bonus = 4 },
  travel  = { page = 1, use = "caster" }, -- ground travel shares caster slots; endcap can still be travel
}
```

`bonus` is WoW’s bonus-bar index (cat/stealth 1, bear 3, moonkin 4, warrior stances 1–3). Relative `slot=1` is `ACTIONBUTTON1`. WoW swaps the underlying absolute slots (caster 1–12, cat ~73–84, bear ~97–108, moonkin ~109–120, **skyriding ~121–132**). **Keys stay 1–12.** Unmatched bonus 5 is not caster. Ground travel may `use="caster"`; skyriding is still Travel Form and keeps Forms-family keys. Combat faces on E/Q/C follow the live skyriding columns (Surge Forward / Second Wind / Whirling Surge). Aerial Halt and Skyward Ascent bind **1** and **2** — they must not paint onto Forms or Thorn.

Which bar to write is the **live stance page** (`GetBonusBarOffset` / `P.BonusBarForm`), not `pack.form` when shapeshift IDs miss (Haranir). Shapeshift **art** uses the animal name (`P.CurrentForm`); travel can share caster slots and still show the sable.

`forms={ cat={spells={768}}, ... }` maps `GetShapeshiftFormInfo` ids and localized names onto those identifiers. `nativeForm` is the spec’s expected animal (Guardian bear, Feral cat, Balance moonkin). `spec=` is the WoW spec id for auto-load.

### Family faces per form

```lua
bars = {
  caster  = { slot=2, key="Q", spell={339},  label="Entangling Roots" },
  cat     = { slot=2, key="Q", spell={5215}, label="Prowl" },
  bear    = { slot=2, key="Q", spell={6795}, label="Growl" },
  moonkin = { slot=2, key="Q", spell={339},  label="Entangling Roots" },
}
```

Same hotkey, same relative slot, different spell on each form’s absolute slot. Apply PlaceIDs every form while out of combat. The secure page driver is `[bonusbar:N]`; it updates in combat.

Shapeshifts and Dash that must exist on **every** page: `bar={ slot=3, bindKey="MOUSEWHEELUP", spell={5487}, allBars=true }` (or `allBars` on a drawer item with its own `slot`). Drawer rows may set `form="cat"` or `form={"cat","bear"}` so they only appear in those stances. Untagged rows stay in every drawer. Combat defers the rebuild until you leave combat.

Single-bar classes can still use `bar={ slot=1, key="E", ... }` with no `bars` table.

### Overlay: custom parent per form

`SuperBindsDB.custom[tag].formPrimary[form] = ability` — dropping a drawer extra onto the parent while in cat replaces **cat** Q only. `custom.primary` is the old single-bar overlay; `MigrateFormPrimary` moves it into `formPrimary` for the form you are on.

A drop onto a form-bar parent (slot is the truth; overlay is the log):

1. `PlaceAction` the **live cursor** onto this stance’s absolute slot (`LiveActionSlot` / bonus bar). Bear E is 97, not page 1. Do not `ClearCursor` then `PickupSpell(1229376)` — Assisted Combat is not a normal pickup.
2. Read the slot. Write `formPrimary` for **this** stance from what is actually there.
3. Rebuild the console only — it must **not** PlaceID every family/form (leftover cursor cycles slots and used to paint caster page 1 while you were in cat).

Spellbook drops do not use Shift. Shift-drag a drawer extra onto the parent swaps. Shift-drag a face off the console empties this form’s slot (`formPrimary[form] = { empty = true }`); apply must `ClearSlot` that overlay, not restock pack. Shift-drag a pack extra off hides it this stance (`custom.hiddenForms[form]`). Drop onto `+` adds it this stance only (`custom.addedForms[form]`). Drawer `form` is the shapeshift name (`cat` / `bear` / `caster` / `travel`), not the bar owner. Ground travel and skyriding/flight share **travel** extras even though ground travel uses caster slots. Layout rebuilds when the drawer form changes, not only when the bonus page changes. Drop/bind identity owed: [`ISSUES.md`](ISSUES.md).

Old parent moves into `custom.addedForms[form]`. Stock extras stay click-only unless they have `bindKey`. Layout never paints the legacy global `custom.added` list.

## Unified bar / BIND

Identity is the **slot**, not a per-form overlay key. `bindId = bar:N`. Keyboard `SetBinding` goes to pack-default `ACTIONBUTTONN` (same keys as a fallback). Per-form column keys live in `SuperBindsDB.formBinds[form]["bar:N"]` and apply as override binds on that bonus bar (`cat` 2 on Attack does not steal bear E). Drawer extras bind their own CLICK/SPELL command. The tab is `type="action"` with the **absolute** slot for this form. Click and hotkey both `UseAction` that slot. Labels follow `formBinds` then the live ACTIONBUTTON bind.

BIND (hover + key):

- Keyboard column: rebind **this form only**. Chat: `Shred cat → 2`.
- Drawer extra: bind that extra. Do not promote onto a strip key.
- Mouse: claimed hardware uses `ACTIONBUTTON` on that column. Shapeshift wheel chords cast the form spell so skyriding cannot replace them with Aerial Halt. Owed leftover: [`ISSUES.md`](ISSUES.md).

## Rotation / SBA

- `useBlizzardSBA=false`: pack next-cast does not drive Blizzard’s assistant. A face may still be `sba=true` (Feral E in cat); paint uses `GetNextCastSpell(false)` without unwrapping secret combat ids.
- `rotation={ caster={...}, cat={...}, bear={...}, moonkin={...}, travel={} }`.
- Experimental next-best readout: `nba={ cat={...}, bear={...} }` — ordered union per form; engine `Known()` subtracts. Form lists may set `comboMax=5`. Loop rows may set `combo="stealth"` (first if known, usable, not on cooldown, not already stealthed), `combo="open"` (once per combat), `combo="build"` (fill to `comboMax`), or `combo="spend"` (flash only at `comboMax`; multiple spenders rotate and never fire back-to-back). Spec and theory: [`EXPERIMENTAL.md`](EXPERIMENTAL.md).
- Rule fields: `spell={...}`, `auraMissing=true`, `dot=`, `ranged=`, `powerType=`, `minPower=`, `fallback=true`. Unknown conditions are skipped. Unknown forms never fall back to caster.
- `neverSuggest={IDs and/or names}`: shapeshifts belong here. Manual forms stay on the wheel, never in next-cast.

## Theme / sculptures

Themes accept `brass={r,g,b}`, `endcap` / `endcapHorde`, sizes, and `endcaps={ bear={path,width,height,leftIn}, cat=..., travel=... }`. Form art follows the shapeshift name, not `BarOwner`. The engine mirrors the right endcap. Art bible: [`ART.md`](ART.md).

Sculptures are optional: `names`, `file`, `size`, `tuck`, `behind`, `uv`, `fillTop`. Empty `sculptures={}` skips the rack (Druid packs). Do not special-case “Totem” in the engine except `NeedsBlizzardSlot` for `@cursor` / ground macros.
