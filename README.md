# Super Binds

Class-agnostic Midnight action console, ported from Shaman Binds. **0.5.82**.

Repo: [github.com/ENFP-Friend/Superbinds](https://github.com/ENFP-Friend/Superbinds)

Layouts are **profile data** — the engine has no class spells. The product is one compact bar whose **hotkey, label, and native slot stay one object**, with a **separate action bar per form** and the **same keys on every stance**.

Current TOC packs: **Elune's Chosen** (Guardian + hero tree 24, default), **Guardian** (fallback), **Feral**, **Balance**.

## Horde vs Alliance default bar

Unshifted endcaps follow faction. **Horde** uses the wind rider; **Alliance** uses the owl (the same sculpture as [Shaman Binds](https://github.com/ENFP-Friend/ShamanBinds)). Shapeshift still swaps to the animal busts.

**Horde** — wind-rider endcaps.

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
| Wheel | 3–6 | Elune probe: Bear / Cat / Travel; Shift-WheelUp is **Thorn Bloom**. Other packs: Moonkin on Shift-WheelUp | | | |

Ground travel **shares the caster bar** (`use="caster"`) and still gets its own endcap. **Skyriding / flight form** is still Travel Form, but it uses bonus bar 5 (absolute slots ~121–132), not caster. Shapeshifts are **manual** keys, never next-cast. The Forms wheel (Bear / Cat / Travel) stays those spells in every stance, including skyriding — Aerial Halt is not a form.

While skyriding the console stays up and the default WoW bar is hidden. Live columns: **E** Surge Forward, **Q** Second Wind, **C** Whirling Surge. **1** Aerial Halt and **2** Skyward Ascent sit on the console (they are not Forms or Thorn). Shift-wheel-up stays Thorn Bloom.

A drop onto a family parent writes **only the form you are in**. The **slot is the truth**: the live relative column (`ACTIONBUTTON1` in bear is 97) must receive `PlaceAction`. `formPrimary` is a restock log written *after* that, not a parallel inventory. Reloads rebuild the console without Pickup/Place. A drop must not PlaceID every bar (that shuffled slots onto the cursor).

Hotkey labels are live WoW (`GetBindingKey`). Rebinding Action Button 2 in Blizzard’s UI updates the Q face. BIND on a keyboard column places the painted ability on this form’s slot and keeps `ACTIONBUTTON`. Claimed wheel keys bind `ACTIONBUTTON` on ground forms; shapeshift chords stay the form spell so skyriding cannot steal them. Known errors: [`docs/ISSUES.md`](docs/ISSUES.md).

Spellbook drops do **not** need Shift. Shift-drag a **drawer extra** onto the parent swaps (old parent moves into the drawer). Shift-drag a **bar face** (or extra) off the console empties that form’s slot — the drop rail is not a drop target. If the WoW cursor is holding a spell, Shift on E must not pick up Mangle.

## Console

- Compact brass strip: family tabs, hover drawers, BIND, `::` grip, drop rail `+`
- Families: Attack E · Disrupt Q · Heal M5 · Forms wheel · Move M4 · Protect C · Empower R · Travel X · Buffs · Recover
- Hover a tab to open that family. BIND opens every drawer in a wrapping grid
- Shift-drag a **drawer extra** onto the parent **swaps** (old parent moves into the drawer). Shift-drag a face **off the bar** empties this form’s slot (`formPrimary.empty`); `/superbinds restore E` restocks. Drop on `+` adds a click-only extra. Spellbook / rune-book drop on the parent is `PlaceAction` on that form’s slot
- Cooldown swipe + countdown on tabs and drawer rows
- Assisted-combat **blue shimmer** is paint-only (`GetNextCastSpell(false)`). Do not `SetActionUIButton`. Midnight combat IDs stay secret — texture/cooldown APIs get the raw id. Shapeshifts are never suggested
- Endcaps follow the **animal** (bear / cat / travel). Unshifted: Alliance owl or Horde wyvern. Moonkin not started
- Hide Blizzard bar 1 (optional). Extra Action stays. Skyriding / flight form hides the default bar and keeps this console. Enter / `/` stay chat. Ctrl-wheel zooms unless a pack claimed it
- Combat GCD pulse is a thin gold bezel on the console (native cooldown swipe, soft ring glow; combat-only unless settings preview)

## Packs

| Pack | Spec | Hero | Native form | Default |
|---|---|---|---|---|
| Elune's Chosen | 104 | 24 | bear | yes (Guardian + Elune tree) |
| Guardian | 104 | — | bear | fallback (`/superbinds load Guardian`) |
| Feral | 103 | — | cat (E is SBA in cat) | spec-follow |
| Balance | 102 | — | moonkin | starter, not an endgame APL |

`/superbinds load Elune's Chosen` / `Guardian` / `Feral` / `Balance`. Spec follow prefers `pack.hero == GetActiveHeroTalentSpec()`, then a spec pack with no `hero` field.

## Install

Junction this folder to `_retail_\Interface\AddOns\SuperBinds`. Do **not** replace the ShamanBinds junction. Disable **Shaman Binds** on the Druid so both addons do not own keys and slots. `/reload`, then out of combat.

Full steps: [`docs/INSTALL.md`](docs/INSTALL.md).

## Commands

`/superbinds` apply; `load Elune's Chosen|Guardian|Feral|Balance`; `save`; `list`; `delete`; `default`; `bind`; `map`; `options`; `keys`; `hide`; `show`. `/keymap` field guide. Alias `/sbinds`.

Custom saves store an overlay plus the base pack name. Shipped tables are not overwritten.

## Constraints

Lua 200 locals per file. No comparing secret numbers. No `SetActionUIButton`. No WTF / `bindings-cache.wtf` writes while WoW is running. `@cursor` needs a real action slot. Unmodified wheel is camera unless BIND or the pack claimed it.
