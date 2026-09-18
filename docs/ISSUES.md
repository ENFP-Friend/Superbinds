# SuperBinds — known errors and owed rework

This is the **only** list. Other docs must link here, not copy it.

Engine: `SuperBinds.lua`. Do not edit live Shaman Binds GUI. Do not grow the hacks below. Tab paint is not proof — prove with `/superbinds probe` (keys + slots) and `GetActionInfo` on the **absolute** slot (bear E = **97**).

## What the app is supposed to be

One **column** = relative slot **1–12** = `ACTIONBUTTONN` = console tab = that form’s **absolute** slot.

| Form | Bar | E (slot 1) |
|---|---|---|
| caster | page 1 | 1 |
| cat | bonus 1 | ~73 |
| bear | bonus 3 | **97** |
| moonkin | bonus 4 | ~109 |
| travel | shares caster (ground) | 1 |
| skyriding | bonus 5 | **121** (still Travel Form) |

Same keys every stance. Click the tab and press the labeled key must be the **same** ability **in this form**. Overlay (`formPrimary`) is a restock log **after** the slot changes. SBA shimmer is paint-only. Shapeshifts are never next-cast. No `SetActionUIButton`. No WTF writes while WoW is running. Lua 200 locals. No `if class == "DRUID"` in the engine.

---

## Closed by probe 2026-09-18 17:35 (0.5.79)

Caster `bonus=0`, bear `bonus=3`. Same chords in both forms.

| Check | Result |
|---|---|
| `R = ACTIONBUTTON9` | Yes. Caster 9 Wrath, bear **105** Lunar Beam. |
| Wheel = `ACTIONBUTTON` 3/4/5/6 | Yes (`MOUSEWHEEL*` and Shift-wheel). 17:16 `SPELL` was leftover binds, not a client limit. |
| Unused 11–12 / 107–108 | Empty. |
| Bear E abs **97** | Assisted Rotation overlay (player drop). Caster 1 Moonfire. |

`/superbinds restore E` in bear restocks pack Mangle.

---

## Closed by user confirm 2026-09-18 18:42 (0.5.82)

Skyriding / druid flight form is still Travel Form (`bonus=5`, abs ~121–132). Console stays; default bar hides.

| Check | Result |
|---|---|
| Forms wheel | Bear / Cat / Travel in every stance, including skyriding. Not Aerial Halt. |
| E / Q / C | Surge Forward / Second Wind / Whirling Surge |
| 1 / 2 | Aerial Halt / Skyward Ascent |
| Thorn Shift-wheel-up | Thorn Bloom (not Skyward Ascent) |

---

## Closed 2026-09-18 (0.5.83)

| Check | Result |
|---|---|
| Elune Prime load | World flyout names no longer pass into `GetSpellInfo` (layout no longer aborts). |
| BIND on Q | Rebinding the strip face does not PlaceAction the same spell (slot stays filled). |
| BIND drawer → Q | Extra and face **swap**. Old face moves into that drawer. |
| BIND board | Narrow columns above each family tab (odd/even rows). |

---

## Known errors (live)

| Status | What | Evidence / notes |
|---|---|---|
| Open (pack) | Rebirth missing from painted Recover | Book and pack stock list it; 17:35 paint still skips it (`Known` / drawer filter). |
| Confirm | Drop SBA on bear E with no Shift → stays on **97**, caster 1 unchanged | Overlay already there from an earlier drop. Not a fresh drop this dump. |
| Expected | Bear E = Assisted Rotation overlay | Player dropped SBA. Pack stock is Mangle. |
| Constraint | Pulse `SetEdgeScale` | Stay **&lt; 1** (shipped 0.72). |
| Constraint | Host vs paint | Tab is not a Blizzard `ActionButton` (no `SetActionUIButton`). Click still `type=action` on the live abs slot. |

---

## Do not

- Treat a correct icon as a correct slot or a correct key.
- Write class spells into `SuperBinds.lua`.
- Grow `CommitCursorToTab` / `PickupAssisted` / `PickupSpell(1229376)` / `if slot == 9`.
- SPELL-bind combat mouse keys by default. Wheel combat columns bind `ACTIONBUTTON` when apply succeeds. Shapeshift chords are the form spell on purpose (skyriding).
- Call `/superbinds reset` the first fix (last resort).
- Park helpers on 8–12.

`/superbinds restore [E]` wipes overlay for that tag and restocks every form bar. `/superbinds probe` (aliases `dump` / `layout`) is the copyable log of book + keys + live slots.
