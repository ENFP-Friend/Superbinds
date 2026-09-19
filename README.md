# Super Binds

Class-agnostic Midnight action console, ported from Shaman Binds. **0.5.116**.

Repo: [github.com/ENFP-Friend/Superbinds](https://github.com/ENFP-Friend/Superbinds)

Layouts are **profile data** — the engine has no class spells. The product is one compact bar whose **hotkey, label, and native slot stay one object**, with a **separate action bar per form** and the **same keys on every stance**.

Current TOC packs: **Elune Prime** (Guardian + hero tree 24, default), **Elune's Chosen** (previous Elune strip), **Guardian** (fallback), **Feral**, **Balance**.

## Demo

**SuperBinds 0.5.116** — Druid so far: every form bar, the hotkey helper, the GCD attack helper, and the cat attack helper. Blizzard’s assisted rotation omits bleeds, so they do not stack from that helper.

<video src="docs/shots/superbinds-05116-druid-helpers.mp4" controls muted playsinline width="720"></video>

**Shaman Binds origin (WIP)** — Haranir Druid with totem-pole timers, the ultimate, menus and drawers. SuperBinds is the port; those totem timers are **not** in SuperBinds yet.

<video src="docs/shots/shamanbinds-wip-haranir-totems.mp4" controls muted playsinline width="720"></video>

## Horde vs Alliance default bar

Unshifted endcaps follow faction. **Horde** uses the wind rider; **Alliance** uses the owl (the same sculpture as [Shaman Binds](https://github.com/ENFP-Friend/ShamanBinds)). Shapeshift still swaps to the animal busts.

**Horde** — Elune Prime, wind-rider endcaps.

![Horde default bar — wind-rider endcaps](docs/shots/04-horde-default-bar.png)

**Alliance** — owl endcaps, Shaman Binds default console.

![Alliance default bar — owl endcaps](docs/shots/05-alliance-default-bar.png)

## Form bars

![Haranir cat form — wolverine endcaps, same keys as every stance](docs/shots/01-haranir-cat.png)

![Haranir travel form — sable endcaps, caster page under the same keys](docs/shots/02-haranir-travel.png)

![Haranir unshifted Horde — wind-rider endcaps, caster page](docs/shots/03-haranir-horde-default.png)

- Session / shipping notes: [`docs/NOTES.md`](docs/NOTES.md)
- **Profile from a live probe (philosophy + agent):** [`docs/PROFILE-GUIDE.md`](docs/PROFILE-GUIDE.md)
- Profile schema (form bars, overlays, BIND): [`docs/PROFILE-SCHEMA.md`](docs/PROFILE-SCHEMA.md)
- Console art (endcaps, TGA): [`docs/ART.md`](docs/ART.md)
- In-game Haranir form bar: [`docs/SHOTS.md`](docs/SHOTS.md)
- Known errors + owed rework: [`docs/ISSUES.md`](docs/ISSUES.md)
- Druid experimental (next-best readout): [`docs/EXPERIMENTAL.md`](docs/EXPERIMENTAL.md)
- Install: [`docs/INSTALL.md`](docs/INSTALL.md)
- Reference (not TOC-loaded): [`_reference/ShamanBinds.lua`](_reference/ShamanBinds.lua)

## What it does

Blizzard gives each shapeshift its own action page (caster 1–12, cat bonus bar, bear, moonkin). SuperBinds keeps **one console** and **one set of keys**. Pressing **Q** is always Action Button 2. In cat that slot is Prowl; in bear it is Growl; unshifted it is Entangling Roots. The tab icon and cooldown follow the form you are in.

That is the stay-in-form design: you do not learn a second keymap, and Blizzard Single-Button Assistant is not asked to play other forms for you.

## Form bars and hotkeys

Each pack declares `actionBars` and per-family `bars`. Apply (`/superbinds`, out of combat) **PlaceID**s the right spell onto each form’s **absolute** slots. In combat the secure `[bonusbar:N]` driver follows the stance page. Keyboard faces bind `ACTIONBUTTON` 1–12 so WoW remaps the key to the bar you are on.

| Key | Slot | Caster | Cat | Bear | Moonkin |
|---|---|---|---|---|---|
| **E** | 1 | Moonfire | Feral: Assisted Rotation · Guardian: Mangle | Mangle (Elune: drop SBA here) | Moonfire |
| **Q** | 2 | Entangling Roots | Prowl | Growl | Entangling Roots |
| **C** | 7 | Barkskin | Barkskin | Ironfur | Barkskin |
| **R** | 9 | Wrath | Feral: Tiger’s Fury · Guardian: Maul | Elune: Lunar Beam (Raze is click) | Wrath |
| **M5** | 8 | Regrowth | Regrowth | Frenzied Regeneration | Regrowth |
| **M4** | 10 | Dash on **every** form bar (`allBars`) | | | |
| Wheel | 3–6 | Elune Prime: Bear / Cat / Travel. Thorn Bloom is **Shift-E**. Elune's Chosen: Shift-WheelUp Thorn Bloom. Other packs: Moonkin on Shift-WheelUp | | | |

Ground travel **shares the caster bar** (`use="caster"`) and still gets its own endcap **and its own drawers**. **Skyriding / flight form** is still Travel Form (same extras list as ground travel), but it uses bonus bar 5 (absolute slots ~121–132), not caster. Shapeshifts are **manual** keys, never next-cast. The Forms wheel (Bear / Cat / Travel) stays those spells in every stance, including skyriding — Aerial Halt is not a form.

While skyriding the console stays up and the default WoW bar is hidden. Live columns: **E** Surge Forward, **Q** Second Wind, **C** Whirling Surge. **1** Aerial Halt and **2** Skyward Ascent sit on the console (they are not Forms or Thorn). Elune's Chosen Shift-wheel-up stays Thorn Bloom; Elune Prime Thorn is Shift-E.

A drop onto a family parent writes **only the form you are in**. The **slot is the truth**: the live relative column (`ACTIONBUTTON1` in bear is 97) must receive `PlaceAction`. `formPrimary` is a restock log written *after* that, not a parallel inventory. Reloads rebuild the console without Pickup/Place. A drop must not PlaceID every bar (that shuffled slots onto the cursor).

Hotkey labels are live WoW (`GetBindingKey`). Rebinding Action Button 2 in Blizzard’s UI updates the Q face. BIND on a keyboard column places the painted ability on this form’s slot and keeps `ACTIONBUTTON`. Claimed wheel keys bind `ACTIONBUTTON` on ground forms; shapeshift chords stay the form spell so skyriding cannot steal them. Known errors: [`docs/ISSUES.md`](docs/ISSUES.md).

Spellbook drops do **not** need Shift. Shift-drag a **drawer extra** onto the parent swaps (old parent moves into the drawer). Shift-drag a **bar face** (or extra) off the console empties that form’s slot — the drop rail is not a drop target. If the WoW cursor is holding a spell, Shift on E must not pick up Mangle.

## Console

- Compact brass strip: family tabs, hover drawers, BIND, `::` grip, drop rail `+`
- Families: Attack E · Disrupt Q · Heal M5 · Forms wheel · Move M4 · Protect C · Empower R · Travel X · Buffs · Recover
- Hover a tab to open that family. BIND opens every drawer as a **narrow column above its own tab** (odd/even rows so neighbors do not pile up)
- BIND a **strip face** to a key only on **this form** (cat E→2 does not steal bear E). BIND a **drawer extra** to a key binds that extra (it does not promote onto the strip). Chat prints `Shred cat → 2`.
- Shift-drag a **drawer extra** onto the parent **swaps** (old parent moves into the drawer). Shift-drag a face **off the bar** empties this form’s slot (`formPrimary.empty`); `/superbinds restore E` restocks. Drop on `+` adds a click-only extra. Spellbook / rune-book drop on the parent is `PlaceAction` on that form’s slot
- Cooldown swipe + countdown on tabs and drawer rows
- Assisted-combat **blue shimmer** is paint-only (`GetNextCastSpell(false)`). Do not `SetActionUIButton`. Midnight combat IDs stay secret — texture/cooldown APIs get the raw id. Shapeshifts are never suggested
- Endcaps follow the **animal** (bear / cat / travel). Unshifted: Alliance owl or Horde wyvern. Moonkin not started
- Hide Blizzard bar 1 (optional). Extra Action stays. Skyriding / flight form hides the default bar and keeps this console. Enter / `/` stay chat. Ctrl-wheel zooms unless a pack claimed it
- Combat GCD pulse: dark swipe runs to the gold slice (9 o'clock–12) during the GCD; press while the edge travels through that slice (default 0.75s). Combat-only unless settings preview

## Packs

| Pack | Spec | Hero | Native form | Default |
|---|---|---|---|---|
| Elune Prime | 104 | 24 | bear | yes (Guardian + Elune tree) |
| Elune's Chosen | 104 | 24 | bear | previous Elune strip (`/superbinds load Elune's Chosen`) |
| Guardian | 104 | — | bear | fallback (`/superbinds load Guardian`) |
| Feral | 103 | — | cat (E is SBA in cat) | spec-follow |
| Balance | 102 | — | moonkin | starter, not an endgame APL |

`/superbinds load Elune Prime` / `Elune's Chosen` / `Guardian` / `Feral` / `Balance`. Spec follow prefers a **default** pack with `pack.hero == GetActiveHeroTalentSpec()`, then a spec pack with no `hero` field.

## Install

Junction this folder to `_retail_\Interface\AddOns\SuperBinds`. Do **not** replace the ShamanBinds junction. Disable **Shaman Binds** on the Druid so both addons do not own keys and slots. `/reload`, then out of combat.

Full steps: [`docs/INSTALL.md`](docs/INSTALL.md).

## Commands

`/superbinds` apply; `load Elune Prime|Elune's Chosen|Guardian|Feral|Balance`; `save`; `list`; `delete`; `default`; `bind`; `map`; `options`; `keys`; `hide`; `show`. `/keymap` field guide. Alias `/sbinds`.

Custom saves store an overlay plus the base pack name. Shipped tables are not overwritten.

## Constraints

Lua 200 locals per file. Lua 5.1 **60 upvalues** per function (`BuildEverything` helpers go on `P._L` — see [`docs/NOTES.md`](docs/NOTES.md#agent-traps)). No comparing secret numbers. `P.Number` is a boolean type-check. No `SetActionUIButton`. No WTF / `bindings-cache.wtf` writes while WoW is running. `@cursor` needs a real action slot. Unmodified wheel is camera unless BIND or the pack claimed it.
