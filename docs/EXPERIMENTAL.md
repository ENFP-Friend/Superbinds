# Druid experimental — next-best readout

Druid-only experiment. Off by default. This file is the spec: **the theory** (why), **how it is programmed** (engine + pack), and **how it works** (what you press). Update it when the build changes.

Blizzard Assisted Combat / SBA is **one spec list**. On Guardian that is bear. Cat, travel, and moonkin do not get their own Blizzard brain. Midnight secrets also block a real Hekili: addons may **paint** combat (cooldown duration objects, `GetNextCastSpell(false)` without unwrapping ids) but must not **decide** from secret buffs, rage, combo points, or CDs. This experiment is the legal leftover: a per-form cheat-sheet plus one best-effort flash.

Engine stays class-agnostic. No `if class == "DRUID"` in `SuperBinds.lua`. The feature exists when the **setting is on** and the **loaded pack has `nba`**. Druid packs ship the lists. Other classes omit them.

Shipped in **0.5.103**. ESC → Options → AddOns → Super Binds → **Druid only (experimental)** → **Druid only: off-form next-best readout**. Shift to cat. Drag the **NEXT BEST** title to move. **Up arrow** above the title hides the box (down arrow restores). Bear hides it. **Pulse next-press key** is on by default: the hotkey (E, 1, R…) sits **above the GCD pulse**. Same off-role gate as NEXT BEST (`pack.nativeForm`) — Guardian cat, not bear.

---

## The theory

SBA cannot play off-form. A talent **matrix** of every hero × node × form is unmaintainable and not how rotation helpers worked even before Midnight.

What works:

1. **Priority list per off-form** (Guardian cat, maybe caster later). Native form (`nativeForm`, Guardian = bear) already has Blizzard SBA. Do **not** author a second bear rotation. The NBA strip is the **flash loop** for that off-form (opener + builders + finishers), not every button on the console. AoE and CDs stay on Attack / Empower drawers.
2. **`Known()` subtracts** what this character does not have. Different players get different strips from the same list. A spell we never listed never appears until we add a row.
3. **Not lookahead.** We cannot read “is Rip on the target?” or real combo points. The strip is the ordered kit. At most **one** icon flashes “now.”
4. **Native form:** no `nba` list. E is SBA; flash is Blizzard `GetNextCastSpell(false)` on the console. Hide the experimental readout there.
5. **Off-form flash is a cast stepper**, not SBA and not `SpellReady` on the CP loop. Combat secrets made “is Rip up?” illegal. The old pack fallback stuck on **Shred (E)** after Rake. Finishers **need combo points** (Rip and Bite both fail at 0). We cannot read the five dots, so the stepper **counts its own successful builders** up to `comboMax`.
6. **Readout, not a second action bar.** The console stays jobs + keys + native slots (`ACTIONBUTTON` 1–12). The experiment is a movable strip. You still press Q / 1 / E / 2 / R. Do not `PlaceAction` extra slots. Do not `SetActionUIButton`. Click-to-cast on the readout is optional and must not get its own binds.

Travel/skyriding may not need a readout; those verbs are already on the main bar.

This will not be perfect. It is the best we can ship without breaking Midnight or SuperBinds rules.

---

## How it is programmed

### Gate

| Piece | Where |
|---|---|
| Toggle | `SuperBindsDB.experimentalNBA` (default **false**) |
| Next-press name | `SuperBindsDB.experimentalNbaName` (default **true**) — title **above the GCD pulse** |
| Settings | Section **Druid only (experimental)**. Checkboxes: **Druid only: off-form next-best readout**, **Pulse next-press key** |
| Pack list | `pack.nba[form]` (Elune Prime ships `nba.cat` only) |
| Hide native | `P.NbaFormList` returns nil when `form == pack.nativeForm`. NEXT BEST **and** the pulse key stay off there. |
| Show | `P.NbaEnabled()` **and** a resolved list with at least one `Known()` spell |

### Pack row

```lua
nba={
  cat={
    comboMax=5,  -- must be a real number (not P.Number, which is a boolean check)
    {spell={5215},label="Prowl",loop=true,combo="stealth"},
    {spell={1822},label="Rake",loop=true,combo="open"},
    {spell={5221},label="Shred",loop=true,combo="build"},
    {spell={1079},label="Rip",loop=true,combo="spend"},
    {spell={22568},label="Ferocious Bite",loop=true,combo="spend"},
  },
}
```

- `spell={...}`: `Known()` picks the first ID this character has. `neverSuggest` (shapeshifts) is skipped.
- `loop=true`: eligible for the flash stepper. The cat strip is **loop rows only** (Prowl, Rake, Shred, Rip, Bite). AoE/CDs are not listed here.
- `combo=`:
  - `"stealth"` — first, if usable
  - `"open"` — once per combat (Rake / stun)
  - `"build"` — filler until estimated CP hits `comboMax`
  - `"spend"` — finisher; only at `comboMax`; several spenders **rotate** (Rip then Bite then Rip…)
- If `combo` is omitted, labels **Rake / Shred / Rip / Ferocious Bite** still infer open/fill/spend. **Prowl does not** — stealth must be tagged.

### Engine (class-agnostic)

All in `SuperBinds.lua`. No class string.

| Function | Job |
|---|---|
| `NbaResolve` | `Known()` the list; `comboMax` via `P.PublicNumber` (never `P.Number`, which returned `true` and crashed `cp >= need`) |
| `EnsureNbaStrip` / `LayoutNbaStrip` | Movable `NEXT BEST` frame, saved `SuperBindsDB.pos.nba`. Secure buttons `type=spell`, no extra `ACTIONBUTTON` |
| `NbaLiveKey` | Paints the **live console key** for that spell, or `Click` |
| `NbaNextId` | Picks the one flashed id (and row) from state (below) |
| `NbaNoteCast` | Advances state on `UNIT_SPELLCAST_SUCCEEDED`, or OnClick of a readout icon (`fromClick=true`) |
| `DriveNbaStrip` | `ApplyAssistedHighlight` on that id. Cooldown swipes use duration objects |
| `ReadNextCastSpell` | Returns **nil** while the NBA strip is active so E does not also glow Shred/SBA |

Combat: do not rebuild the strip (secure). If the attributed form still matches, keep showing. Layout out of combat resets the stepper.

### Stepper state (estimated, not secret CP)

| State | Meaning |
|---|---|
| `_nbaCp` | Count of successful **open/build** casts this cycle, capped at `comboMax` |
| `_nbaOpened` | Rake (or any builder) has landed; stop offering Prowl / re-Rake |
| `_nbaProwled` | Prowl used or already stealthed; skip Prowl |
| `_nbaSpendI` | Which spender is next (1 = first `combo="spend"` in pack order = Rip) |

Advance:

- **Builder** (`open` or `build`): `_nbaCp = min(comboMax, cp+1)`, `_nbaOpened = true`
- **Spender**: only if estimated CP is full (strip click at 0 CP is ignored). Then `_nbaCp = 0`, stay opened, rotate `_nbaSpendI` to the **other** finisher. Never flash two spenders back-to-back.
- **Stealth**: sets `_nbaProwled`; does not add a combo point
- Match by public spell id (`SpellIDsMatch` both override directions) or by **name** if the cast id is secret
- Combat end (`PLAYER_REGEN_ENABLED`) and strip layout: `cp=0`, `opened=false`, `prowled=false`, spender index back to Rip

### Prowl / ready

`SpellReady` is used **only** for the stealth row (not for Rip/Bite). If usable is false, skip. If start/duration are secret (`SpellReady` nil), offer Prowl **out of combat only**. `IsStealthed()` when it is a public boolean: already stealthed → skip Prowl, go to Rake.

---

## How it works

You still press the **console** keys. The readout flashes which of those to press. With **Pulse next-press key** on (default), that hotkey sits centered **above the GCD pulse** in **off-role** only (`NbaFormList`: current form has `pack.nba` and is not `nativeForm`). Native form (Guardian bear) has no title.

**Pull (Guardian cat, 5 combo slots):**

1. **Q Prowl** — if known, not on cooldown, not already stealthed, and usable. Combat or CD → skip.
2. **1 Rake** — bleed + 1 estimated CP. From Prowl this is the **stun**.
3. **E Shred** — mash until the estimate hits 5 (Rake was 1, then four Shreds).
4. **2 Rip** — long bleed; **spends** the five points. Will not flash at 0 CP.
5. **E Shred** — build five again.
6. **R Ferocious Bite** — dump; **spends** the five points. Will not flash at 0 CP.
7. Repeat **E → 2 Rip → E → R Bite**. After a spend the flash goes back to Shred, not the other finisher and not Rake.

Leave combat: next pull can Prowl again; first dump is Rip again.

**Why it is wrong sometimes (allowed):** we cannot see real combo points or whether Rip is still on the target. A proc, an extra Shred, or pressing Rip early desyncs the estimate. Thrash / Swipe / Moonfire / Convoke stay on the **console drawers**, not on NEXT BEST.

---

## What we are doing

- [x] Settings toggle, **default off**, labeled Druid-only.
- [x] Readout only when that toggle is on **and** the pack has `nba` for this **off-form**.
- [x] Elune Prime `nba.cat` from probes 2026-09-18 / 2026-09-19. **No `nba.bear`.**
- [x] Movable strip, saved position, duration-object cooldown swipe, live key labels.
- [x] Cast stepper: stealth → open → fill to 5 → rotate spenders, never at 0 CP.
- [x] Console next-cast paint suppressed while the strip is up.
- [x] `form=` on BIND drawers so extras follow stance (string or `{cat,bear}`). Combat still defers the rebuild.
- [x] Next-press **hotkey** above the GCD pulse, **off-role only** (`NbaFormList` / `nativeForm`; not a hardcoded bear).
- [x] Up arrow above NEXT BEST hides the box; down arrow restores (`nbaCollapsed`). Pulse key still follows the stepper.
- [ ] Feral converse: `nba.bear` (and any other off-role lists) when native form is cat. Pulse key already follows `nativeForm`.
- [ ] Travel `nba` only if the skyriding strip is not enough.

### Elune Prime `nba.cat`

Probe kit used to author the **loop**: Prowl, Rake, Shred, Rip, Ferocious Bite. Thrash, Swipe, Moonfire, and Convoke are cat-usable but they are **not** the ST stepper — they live on Attack / Empower drawers. **Not in the book:** Tiger's Fury, Berserk, Feral Frenzy, Primal Wrath. Shapeshifts, Growl, heals, racials stay off this list. Prowl is the stealth opener (Rake stun), not a shapeshift.

| # | Spell | Key | Flash | Combo |
|---|---|---|---|---|
| 1 | Prowl | Q | first, if usable | stealth |
| 2 | Rake | 1 | open (stun from stealth) | open |
| 3 | Shred | E | fill until 5 CP | build |
| 4 | Rip | 2 | first 5-CP spend, then alternates with Bite | spend |
| 5 | Ferocious Bite | R | after Rip, at 5 CP | spend |

---

Not in this experiment: core/class addon split, a second bound action bar, off-form SBA, a talent truth table, reading real combo points or bleed remaining.
