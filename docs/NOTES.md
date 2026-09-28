# SuperBinds notes

Snapshot: **0.5.121** (23 Sep 2026). Parked. One public Druid import (**Elune Prime**). `/superbinds clean` wipes overlays. A `/superbinds load` stays until you change spec (`profilePinned`). Engine is class-agnostic; Shaman is a separate private addon, not imported here. `/superbinds probe` copy window is spellbook plus live keys/slots. Skyriding flight form keeps the console (E / Q / 1 / 2 / C plus Forms wheel). Shipping addon is this folder, junctioned to `_retail_\Interface\AddOns\SuperBinds`. Live **Shaman Binds** stays a separate addon — do not edit its GUI or junction. **DruidAssistant** is an unused sidecar; BIND, bars, and endcaps do not live there.

Public patch notes: [`../README.md`](../README.md#since-05117).

- **0.5.118** — SBA glow only with a real next cast. Explicit pack rows are not dropped as rotation leftovers. Import Druid does not load a saved profile of the same name. `match("^bar:")` for bar ids (already required; both checks).
- **0.5.119** — Manual load / Import / Start clean set `profilePinned`. Spec change clears it. Elune Prime: Rake `1`, Rip `4`, bear Regrowth `SHIFT-BUTTON5`, bear Barkskin `CTRL-C`, Remove Corruption `ALT-BUTTON5` on Heal (not Recover). Mouse chords are in `pack.hardware`. Do not bind Rip to `2` (trinket, and Skyward Ascent while mounted).
- **0.5.120** — `/keymap` filter: bindings, all spells, not used. Form option defaults to the form you are in.
- **0.5.121** — Spell groups: `IsSpellCrowdControl`, `IsExternalDefensive`, `IsSelfBuff`, else the spellbook skill line. Do not vendor a class/race spell database.
- **0.5.122–0.5.129** — Flight faces follow what the key casts. Field guide sits above the bar. Druid packs moved to the sibling addon `SuperBinds_Druid` (`Dependencies: SuperBinds`, no `LoadWith`). BIND is a brass seal with a clasp.
- **0.5.130** — `SuperBindsDB.appliedChars`: the layout is per character. A character that never applied gets the prompt (right-click skips it for the session); spec follow does not apply silently. Start clean in settings asks first. `RefreshMoveChrome` read a nil global `keymapFrame`; it now reads `SuperBindsKeymap`.

Cursor’s open workspace is often **ShamanBinds**. Edit the sibling **SuperBinds** folder. Do not commit or push unless asked.

Product overview: [`../README.md`](../README.md). **Probe → pack:** [`PROFILE-GUIDE.md`](PROFILE-GUIDE.md). Schema: [`PROFILE-SCHEMA.md`](PROFILE-SCHEMA.md). Art: [`ART.md`](ART.md). Shots: [`SHOTS.md`](SHOTS.md). **Known errors + owed rework:** [`ISSUES.md`](ISSUES.md). NBA readout: [`EXPERIMENTAL.md`](EXPERIMENTAL.md). **Read [Agent traps](#agent-traps) before growing `SuperBinds.lua`.**

## Product split

| Piece | Where | Role |
| --- | --- | --- |
| Engine | `SuperBinds.lua` | Console, BIND, **multi-form native slots**, per-form hotkeys, SBA paint, pulse, endcap swap |
| Druid packs | `SuperBinds_Druid/` (sibling addon) | Spells, keys, `actionBars`, `bars` per form, `hero`, `theme.endcaps`. Loads with the core. |
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

- **Elune Prime** (`spec=104`, `hero=24`, `nativeForm=bear`, default) — probe binding map: Thorn/Rootwalking on Attack, SBA on bear E, World click-only. Cat Rake **1**, Rip **4**. Bear Regrowth **Shift-M5**, Barkskin **Ctrl-C**. Remove Corruption **Alt-M5** (Heal). Loads when the Elune hero tree is active, and a manual load stays until spec change.
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

## Agent traps

These are the bugs a cold read of the file will recreate. Schema fields: [`PROFILE-SCHEMA.md`](PROFILE-SCHEMA.md).

### Lua 5.1 (load-time, not runtime)

- **200 locals per file.** Helpers live on `P` (or nested `do`). The file is already near the cap.
- **60 upvalues per function prototype.** `BuildEverything` hit this in 0.5.97 (`function at line N has more than 60 upvalues` — the reported line is often near the *end* of the function). Helpers it calls are stashed on `P._L` and invoked as `L.Name` after `local L = P._L`. Do not add a new file-level `local function` and close over it from `BuildEverything`. Nested closures inside it share that budget for what they capture. Tables already upvalued there (`KEEP`, `PLACED_SPELLS`, `BOOK`, `BAR_BINDS`, `console`, …) can stay; new *functions* must not.
- `P.Number(x)` is a **type check** (returns boolean). Numeric pack fields (`comboMax`) use `P.PublicNumber`. Using `P.Number` in `cp >= need` crashed NBA (`compare boolean with number`).

### Three “forms” (they are not the same)

| Helper | Meaning |
| --- | --- |
| `PackFormNow` / `BarOwner` | Which **action page** to PlaceID. Ground travel `use="caster"` → **caster slots**. |
| `DrawerForm` | Which **extras list**. Ground travel and skyriding/flight are **`travel`**, not caster. |
| `CurrentForm` / `FormEndcap` | Animal art. |

Layout rebuilds when the **bar form or the drawer form** changes. A skip that only compares `PackFormNow` misses caster → ground travel (same slots, different drawers). Do not `PlaceID` bear onto skyriding Surge.

### Drawers are per stance (0.5.94+)

Player overlay is `custom.addedForms[form]`, `custom.hiddenForms[form]`, `custom.orderForms[form]`. **Never paint or write** the legacy global `custom.added` / `custom.hidden` — that leaked cat add/remove onto bear and caster.

- Pack stock rows may still set `form="cat"` or `form={"cat","bear"}`. Untagged stock stays in every stance. `P.ItemFormOk` treats travel / flight / skyriding as one extras identity.
- Shift-drag a pack extra off the bar → `HideExtra` **this** `DrawerForm` (`hiddenForms`). Drop on `+` → `AddExtra` this form only. Displace / swap hides here, never writes the old global `custom.hidden[key]`.
- `MigrateAddedPerForm` may copy leftover globals onto the current drawer form, then clear them.

### Column keys are per stance (0.5.96+)

`SuperBindsDB.formBinds[form]["bar:N"]` applies as SecureHandler override binds on that bonus bar. Pack `barBinds` stays the character `ACTIONBUTTON` default. Cat Attack **2** must not steal bear **E**.

- BIND a **strip** `bar:N`: write `formBinds[PackFormNow]`, restore pack-default `ACTIONBUTTON`. Chat: `Shred cat → 2`.
- BIND a **drawer extra**: bind that extra’s CLICK/SPELL. Do **not** promote it onto a strip key (pressing 2 then fires the column, not the drawer).
- Labels: `EffectiveKey` / `RefreshBindLabels` / `FormBindFor`. Test `bindId` with `match("^bar:")`. `find("^bar:", 1, true)` is a **plain** search for the literal characters `^bar:` and never applies `formBinds` (0.5.97: keys fired, labels stayed E).
- `RebindAll` and `UPDATE_BINDINGS` must **not** copy live `GetBindingKey(ACTIONBUTTON)` into global `barBinds`.

### SBA / NBA / BIND maze

Do not grow `CommitCursorToTab` / `PickupAssisted` / `PickupSpell(1229376)`. Shimmer is paint-only. NBA is a **flash loop**, not every off-form button — see [`EXPERIMENTAL.md`](EXPERIMENTAL.md). Recover and World are the click-only exceptions; every other non-SBA active needs a `bindKey`. Shapeshifts are never next-cast.

**Off-role vs native form (spec role, not a class string):** `pack.nativeForm` is the primary talent-tree stance (Guardian / Elune Prime = `bear`, Feral = `cat`, Balance = `moonkin`). `P.PackNativeForm` reads that field; familyMode is only a fallback. NEXT BEST and the **pulse next-press key** show only when `P.NbaFormList()` is set — current `DrawerForm` has a pack `nba` list **and** is not `nativeForm`. Do **not** `if form == "bear"` and do **not** paint the pulse key from SBA / `GetNextCastSpell` on the native form (that is why the hotkey leaked onto the GCD ring in bear). Live character is Guardian, so cat is the off-role cheat-sheet; caster and travel have no `nba` list yet, so they stay blank too.

**Later (Feral / converse):** when the primary role is cat, the same gate already hides the title in cat. A bear cheat-sheet is `pack.nba.bear` (and any other off-role lists), not a Guardian special case. Do not invert with a hardcoded “always cat.” Caster / travel NBA is still optional.

## BIND / bars (engine)

Unified bar: hotkey label, ability, and native slot stay one object. Keyboard faces are `ACTIONBUTTON` 1–12.

BIND (0.5.83–0.5.97):

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

Combat-only GCD bezel matching the walnut/gold trim. Visible spinner is a `PulseEdge` pip via `SetRotation` at a constant °/s — **not** the hoop’s `CooldownFrameTemplate` (that widget `SetCooldown`s from 12 and teleports on a hit). Hidden 1px cooldown still watches the real GCD. Soft ADD ring glow (not a filled disc). 20% opacity slider = shipped look.

**Hit window:** the pip spins at a **constant** clockwise rate (`76° / PulseWindow()`, so crossing the gold slice is the press window). Do not `SetCooldown` on the visible hoop — that teleports the pip back to 12 on a hit. Hidden watcher still times the real GCD. On a hit, **rotate `PulseHitZone`** to where the pip will be when this GCD ends; tween the slice, do not reset `_sbSpinAng`. Window phase is the same spin, now through the slice. **Miss:** do not `PulseSettle("idle")`. Unlock the slice (`_sbZoneLock=false`) and let it **chase** one guessed GCD ahead of the pip; the next real press locks it again with the same tween. Never hide the pip during the window. Do not add a second HUD.

ESC → Options → AddOns → Super Binds → **GCD pulse** (or `/superbinds options`) previews it out of combat.

**Pulse next-press key** (experimental, default on): the hotkey for the NBA flash (E, 1, R…) sits above the ring. Same off-role gate as NEXT BEST (`NbaFormList` / `nativeForm`). Hidden in the spec’s native form. See [Agent traps](#agent-traps).

## Hard constraints

- Lua 200 locals per file (`P` table, nested `do`).
- Lua 5.1 **60 upvalues** per function (`BuildEverything` → `P._L`; see [Agent traps](#agent-traps)).
- Midnight secrets: no comparing secret numbers. `P.Number` is a boolean type-check; use `P.PublicNumber` for actual numbers.
- No `SetActionUIButton`.
- Do not write WTF / `bindings-cache.wtf` while WoW is running.
- Unmodified wheel is camera unless BIND or the pack claimed it.
- `@cursor` abilities need a real action slot.

## Next

Art only here. Engine owed work: [`ISSUES.md`](ISSUES.md).

1. Moonkin (Haranir batbear) endcap.
2. Alliance owl replacement (same relic process as Horde wyvern).
3. Feral converse NBA: `nativeForm=cat` already hides the pulse key / NEXT BEST in cat. A bear (or caster) cheat-sheet is `pack.nba.bear`, not a hardcoded invert.

## Commands

`/superbinds` apply; `load Elune Prime|Elune's Chosen|Guardian|Feral|Balance`; `save`; `list`; `bind`; `options`; `keys`. `/keymap` field guide.

Disable **Shaman Binds** on this character so both addons do not own keys and slots.
