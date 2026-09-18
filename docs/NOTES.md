# SuperBinds notes

Snapshot: **0.5.83** (18 Sep 2026). `/superbinds probe` copy window is spellbook plus live keys/slots. **Elune Prime** is the default Guardian + Elune tree 24 pack (Thorn/Rootwalking on Attack, SBA on bear E, World click-only). Elune's Chosen remains the previous Elune strip. Skyriding flight form keeps the console (E / Q / 1 / 2 / C plus Forms wheel). Shipping addon is this folder, junctioned to `_retail_\Interface\AddOns\SuperBinds`. Live **Shaman Binds** stays a separate addon — do not edit its GUI or junction. **DruidAssistant** is an unused sidecar; BIND, bars, and endcaps do not live there.

Product overview: [`../README.md`](../README.md). **Probe → pack:** [`PROFILE-GUIDE.md`](PROFILE-GUIDE.md). Schema: [`PROFILE-SCHEMA.md`](PROFILE-SCHEMA.md). Art: [`ART.md`](ART.md). Shots: [`SHOTS.md`](SHOTS.md). **Known errors + owed rework:** [`ISSUES.md`](ISSUES.md).

## Product split

| Piece | Where | Role |
| --- | --- | --- |
| Engine | `SuperBinds.lua` | Console, BIND, **multi-form native slots**, per-form hotkeys, SBA paint, pulse, endcap swap |
| Druid packs | `Profiles/Druid/*.lua` | Spells, keys, `actionBars`, `bars` per form, `hero`, `theme.endcaps` |
| Shipped art | `Media/*.tga` | What the game loads |
| Packed PNG sources | `assets/DruidEndcap_{bear,cat,travel,horde}.png` | Cropped 80×120 / 90×120 sources |
| Workshop drafts | ShamanBinds `assets/` (open Cursor workspace) | Rejected gens; not loaded by TOC |

Engine has no class spells. If you need a shapeshift name or TGA path, it belongs in a pack.

## Form bars (the addon)

Same labeled key on every stance; **different native bar** under it.

- Caster: page 1, slots 1–12
- Cat: bonus 1, ~73–84
- Bear: bonus 3, ~97–108
- Moonkin: bonus 4, ~109–120
- Travel (ground / swim): shares caster (`use="caster"`)
- Skyriding / flight form: still Travel Form, bonus **5**, absolute ~121–132. Not caster. Console stays; default bar hides.

Relative slot 1 is always E / `ACTIONBUTTON1`. In bear that is absolute **97**. In skyriding that is Surge Forward on ~121. The tab, the key, and that slot are one object for combat faces. Overlay (`formPrimary[form]`) is a restock log written **after** the slot changes.

Live writes (BIND, spellbook drop, drawer→parent) must `PlaceAction` the **live bonus-bar slot**, not page 1. `P.BonusBarForm` / `P.LiveActionSlot` exist because Haranir shapeshift ids can miss.

Keyboard combat faces follow the stance page. Forms wheel casts the shapeshift spell on every page (including empty skyriding columns). Claimed mouse keys skip Dash/M5 hardware stamps. Owed work: [`ISSUES.md`](ISSUES.md).

## Packs in the TOC

`SuperBinds.toc` loads Guardian, Elune's Chosen, Elune Prime, Feral, then Balance.

- **Elune Prime** (`spec=104`, `hero=24`, `nativeForm=bear`, default) — probe binding map: Thorn/Rootwalking on Attack, SBA on bear E, World click-only. Loads when the Elune hero tree is active.
- **Elune's Chosen** (`spec=104`, `hero=24`, `nativeForm=bear`) — previous Elune strip (Thorn on Shift-wheel-up). `/superbinds load Elune's Chosen`.
- **Guardian** (`spec=104`, no `hero`, `nativeForm=bear`) — previous bear kit. Fallback when Elune is not the hero tree. `/superbinds load Guardian`.
- **Feral** (`spec=103`, `nativeForm=cat`) — auto-follows Feral spec. E is SBA in cat.
- **Balance** (`spec=102`, `nativeForm=moonkin`) — starter, not an endgame APL.

Strip: E attack · Q disrupt · M5 heal · T forms/wheel · M4 move · C protect · R empower · X travel · BUF · +.

Elune / Guardian / Feral wheel: up Bear, down Cat, shift-down Travel. **Elune Prime** Thorn Bloom is **Shift-E** (Attack). Elune's Chosen still uses shift-up Thorn Bloom. Balance still uses Moonkin on a pack key. Ctrl-wheel stays camera.

Skyriding (bonus 5): **E** Surge Forward, **Q** Second Wind, **C** Whirling Surge, **1** Aerial Halt, **2** Skyward Ascent. Forms wheel does not change. Aerial Halt is never a Forms face.

Live character: Horde Haranir Guardian, Elune Prime.

## Endcaps (form GUI)

Bible: [`ART.md`](ART.md). `P.FormEndcap()` uses the shapeshift name, not `BarOwner`.

Live: bear `batC`, cat v6 **B**, travel C, Horde wyvern v4 B. Alliance owl leftover. Moonkin not started. `leftIn` 26 for form busts.

## BIND / bars (engine)

Unified bar: hotkey label, ability, and native slot stay one object. Keyboard faces are `ACTIONBUTTON` 1–12.

BIND (0.5.83):

- Rebinding a strip face does **not** PlaceAction the same spell onto its slot (WoW toggles it off → empty Q).
- BIND a drawer extra to a key that belongs to a strip face **swaps**: extra → face, face → that drawer (old extra chord follows the displaced face).
- BIND drawers are **narrow** (width follows the name) and sit **above their own tab**, odd/even rows so neighbors do not pile into one grid.
- `Known()` must not call `C_Spell.GetSpellInfo` with flyout / junk names — that aborted Elune Prime on reload (`Layout update failed`).

Fixes already in the engine (not Druid-hardcoded):

- Extra that exists on another form’s bar: place on this form’s column + `ACTIONBUTTON`, do not save the caster spell.
- Mouse BIND uses the **painted** spell, not `GetActionInfo` of the relative caster slot (that was Roots while the cat face showed Prowl).
- Claimed mouse keys skip `ArmHardwareClicks` type4/5 stamps (Dash on M4 was firing with Prowl).
- Drawer → parent uses the live bonus bar, not `pack.form = caster`.

## SBA

`C_AssistedCombat.GetNextCastSpell(false)` is **paint-only**. Midnight combat IDs are secret — pass the raw id into texture/cooldown APIs, do not unwrap/compare. Do not `SetActionUIButton`. Shapeshifts are never next-cast.

Assisted Combat on a bar is type `spell` / subtype `assistedcombat` (or `C_ActionBar.IsAssistedCombatAction`). `PickupSpell(1229376)` is not how you place it. A rune-book drop must `PlaceAction` the **existing cursor** onto the live absolute slot. Overlay records that after the fact, per form.

`useBlizzardSBA=false` on Druid packs except an explicit `sba=true` **face** (Feral cat E).

## Pulse

Combat-only GCD bezel matching the walnut/gold trim. Native `CooldownFrameTemplate`, circular edge, traveling pip inside a thin ring (`SetEdgeScale` 0.72 — do not raise above ~1 or the pip leaves the 64px widget). Soft ADD ring glow (not a filled disc). 20% opacity slider = shipped look; large ring reads ~34% opaque (15% more transparent than 0.5.64). ESC → Options → AddOns → Super Binds (or `/superbinds options`) previews it out of combat; the slider writes glow + bezel live.

## Hard constraints

- Lua 200 locals per file (`P` table, nested `do`).
- Midnight secrets: no comparing secret numbers.
- No `SetActionUIButton`.
- Do not write WTF / `bindings-cache.wtf` while WoW is running.
- Unmodified wheel is camera unless BIND or the pack claimed it.
- `@cursor` abilities need a real action slot.

## Next

Art only here. Engine owed work: [`ISSUES.md`](ISSUES.md).

1. Moonkin (Haranir batbear) endcap.
2. Alliance owl replacement (same relic process as Horde wyvern).

## Commands

`/superbinds` apply; `load Elune Prime|Elune's Chosen|Guardian|Feral|Balance`; `save`; `list`; `bind`; `options`; `keys`. `/keymap` field guide.

Disable **Shaman Binds** on this character so both addons do not own keys and slots.
