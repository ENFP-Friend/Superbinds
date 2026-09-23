# SuperBinds profile guide (agent + probe)

Use this when an agent sits between a **live `/superbinds probe` dump** and a **new or rewritten pack**. Schema fields: [`PROFILE-SCHEMA.md`](PROFILE-SCHEMA.md). Engine owed work: [`ISSUES.md`](ISSUES.md). Lua / form / BIND traps before editing the engine: [`NOTES.md` Agent traps](NOTES.md#agent-traps). Do not invent a kit from wiki memory or from the previous class’s family names.

Cursor’s open workspace is often **ShamanBinds**. The shipping engine and packs are the sibling **SuperBinds** folder. Do not edit live Shaman Binds GUI.

**Engine = chrome, slots, BIND, form pages. Profile = this character’s verbs, keys, and labels.**

---

## Why this exists

Shaman Binds already had a compact-console philosophy. SuperBinds is class-agnostic: the next pack is whatever the probe says this character can press. The agent’s job is to turn that dump into a profile that feels as close to “perfect” as the engine allows — not to clone the shaman Prime table onto a Haranir Guardian, a Feral cat, or a healer.

Source of truth, in order:

1. **`/superbinds probe`** (spellbook lines, racials, shapeshifts, `GetRotationSpells`)
2. **This guide** (how to group and key those spells)
3. **`PROFILE-SCHEMA.md`** (how to write the lua table)
4. Pack files already in `Profiles/` — examples only, not a template of family *names*

If a spell is not in the probe, it does not go on the bar. `Known()` will hide it anyway.

---

## Philosophy (from Shaman Binds, still the product)

These are why the console is shaped this way. Do not “simplify” them away.

- **Main strip = vital verbs.** A short set of jobs you must reach without opening a drawer: interrupt / control, heal, attack, protect, move, travel, trinkets. Visible cooldown on the face.
- **Modifiers = variants of that job.** Shift/Ctrl on the same family. Keep the console compact.
- **Every ability the SBA does not handle needs a binding.** If it is not on the probe’s **SBA presses** list, it gets a `bindKey` (strip face, Shift/Ctrl, wheel, or another chord). **Recover and World are the click-only exceptions:** rez / hearth / Moonglade stay Recover; non-combat General / system actives stay World — no bind. Shapeshifts still get the Forms-family keys even if SBA lists Bear Form.
- **One family per hover.** Not a second action bar.
- **Stay in form.** Same labeled keys every stance; the **native slot under the key** changes. Do not teach a second keymap. Do not ask Single-Button Assistant to play other forms for you.
- **Slot is the truth.** The tab, the hotkey, and that form’s absolute slot are one object. Overlay (`formPrimary`) is a restock log after the slot changes.
- **SBA is optional on a face**, not the whole UI. Probe lists what Blizzard’s assistant actually presses. Defensives, interrupts, racials, and travel stay manual unless the probe says otherwise.
- **Shapeshifts are manual.** Wheel / form family. Never next-cast (`neverSuggest`). SBA may still list Bear Form — that does not put Bear Form on E. Druid **skyriding is still Travel Form**: Forms keys stay Bear / Cat / Travel. Aerial Halt and Skyward Ascent are skyriding verbs (**1** / **2**), not Forms.
- **Accessibility default (Prime import), unless role fights it:** heal on **M5**, protect on **C**, mount on **X**. Interrupt-class control on **Q**. Attack on **E**. Move on **M4**. Spend / hero CD on **R**. Trinkets on **2** and **3** on the ground. While skyriding, **1** is Aerial Halt and **2** is Skyward Ascent.
- **Hex-class hard stops from shaman still apply where relevant:** extra bars 2–8 off on apply (Extra Action stays; skyriding uses this console, not the default bar); Enter and `/` stay chat; unmodified wheel is camera unless BIND or the pack claimed it; `@cursor` / ground spells need a real action slot; mouse keys cannot use `CLICK Frame:LeftButton` (SPELL / ITEM / named macro); no `SetActionUIButton`; no secret-id compares; do not write `WTF` / `bindings-cache.wtf` from the repo while WoW is running.

---

## Families are not a fixed vocabulary

Do **not** copy shaman or Guardian captions onto every pack. `ATTACK` / `DISRUPT` / `HEAL` / `TOTEMS` / `MOVE` / `PROTECT` / `EMPOWER` / `TRAVEL` / `BUFFS` / `RECOVER` are **one** tank-druid strip. The next character may need different jobs and different names even when the *jobs* are close.

A family is a **job**, not a spell. The title stays the same in every form. The **face** is that form’s verb for the job (Protect shows Barkskin in caster and Ironfur in bear). Do not name the family Mangle, Ironfur, Lunar Beam, or a shaman Ward.

Name jobs from **role + character**, then map spells onto those jobs:

| Job | This tank-druid strip | Not the family name |
|---|---|---|
| Damage / threat | Attack | Mangle, Moonfire, Moon |
| Kick / CC / taunt | Disrupt | Growl, Roots |
| Throughput heal | Heal | Frenzied Regeneration |
| Mitigation | Protect | Ironfur, Barkskin, Ward |
| Hero / spend | Empower | Lunar Beam, Raze |
| Mobility | Move | Dash |
| Stance | Forms | Bear Form |
| Travel / mount | Travel | Favorite mount |
| Race / world | Thorn (Haranir) | a totem wheel they do not have |
| Raid buff / rez | Buffs, Recover | Mark of the Wild |

**Tags** (`E`, `Q`, `C`, …) are overlay IDs and usually match the hardware key. **Captions** are the job the player reads. A healer pack might put Heal on `E` and not have Attack at all. Elune’s Chosen is still a Guardian tank — same jobs as Guardian; Lunar Beam and Thorn Bloom are **spells inside** Empower / Thorn, not new family titles.

Group drawer rows by that job. A Haranir tank puts **Thorn Bloom** and **Rootwalking** with racial / recover / a dedicated family — not on a shaman totem wheel they do not have. Stance-only extras use `form="cat"` or `form={"cat","bear"}` inside the family that owns that verb; they do not invent a fake “Feral” tab on a Guardian. Untagged extras (Thorn, Dash, rez) stay in every stance.

If the probe has no Moonkin Form, do not ship a moonkin `bars.moonkin` face as if they did.

---

## `/superbinds probe`

Live dump of **this** character. Chat is a bad copy target.

1. Out of combat: `/superbinds probe` (aliases: `dump` / `layout` / `log` / `spells` / `book`)
2. A window opens. **Ctrl+A, Ctrl+C**, paste to the agent  
   **or** `/reload` after the dump — tables are `SuperBindsDB.probe` and `SuperBindsDB.dump` in  
   `WTF\Account\<account>\SavedVariables\SuperBinds.lua` (agent may read that file after reload; do not edit WTF while the client is running)

The dump includes:

- `race`, `class`, `spec`, `specName`, `hero`, `pack`
- **SBA button** name and **SBA presses** (`C_AssistedCombat.GetRotationSpells`)
- Each **spellbook skill line**, **active** vs **passive** (Racials sit under General for Haranir)
- **Shapeshifts** on the stance bar
- **Keys:** pack stock faces per form, live `ACTIONBUTTON` 1–12 (this form’s absolute slot + what is on it), painted console, `GetBindingAction` chords, `formPrimary` overlays
- Secret combat ids: leave combat and probe again

Treat **SBA presses** as what one Assisted Combat button will fire. Treat **active** rows as what may be keyed or clicked. Passives are not faces. Flyouts stay flyouts unless the pack has a reason to pick a child spell. Treat the **Keys** block as what is actually bound and sitting on the bar right now — overlays can disagree with pack stock (example: SBA dropped on bear E).

---

## Agent workflow (probe → pack)

1. Read the probe. List actives by line (class, spec, General/racials). List SBA. List forms.
2. Decide **role** (tank / healer / melee / ranged) from spec + native form, not from an old pack name.
3. Decide **vital verbs** for *this* kit. Assign keys using the accessibility default unless the role needs a different home (example: a healer’s E may be the heal, not a builder).
4. **Name families** for this character. Do not reuse another spec’s captions because they are “close.”
5. Per form that the probe actually has: fill `bars` (or `bar` + `allBars` for Dash / forms). Same relative slot, different spell.
6. Drawer: modifiers first (`bindKey`). **Do not leave a non-SBA active as click-only** except Recover. Hide SBA-covered clicks only when `useBlizzardSBA` is on; Elune/Guardian packs are `useBlizzardSBA=false` so the builder stays on E unless the player dropped SBA there.
7. Racial actives get a **binding** (not click-only). Do not leave Thorn Bloom only in the Blizzard book.
8. `neverSuggest` = shapeshifts (and anything else that must never be next-cast). `rotation` only uses probe spells. Unknown form → no suggestion.
9. New file under `Profiles/<Class>/`, `RegisterProfile`, add to `SuperBinds.toc` after the engine. Set `spec`, optional `hero`, `default` so auto-load does not race.
10. Do not put class spells in `SuperBinds.lua`. Do not edit live Shaman Binds GUI.

Worked example (Haranir Guardian Elune, probe 2026-09-18): SBA = Lunar Beam, Mangle, Moonfire, Raze, Swipe, Thrash, plus Bear Form / Mark of the Wild / Convoke. Manual: Ironfur, Frenzied Regeneration, Skull Bash, Survival Instincts, Incarnation, Heart of the Wild, Thorn Bloom, Rootwalking, Typhoon, Ursol’s Vortex, Wild Charge. No Moonkin, no Maul (Raze instead). Captions can stay tank-like but **Raze** not Maul, **Lunar Beam** on empower, racials not totems.

---

## BIND (player, after the pack exists)

`/superbinds bind` or the BIND key: drawers in a grid, hover, press a key or scroll. Esc / BIND again to finish. Gold lip moves BIND only. `/superbinds keys` reserved chords. `/keymap` field guide: Bindings, All spells, Not used; this form or every form. Crowd control, defensives, and self buffs use Blizzard’s flags (`0.5.121`). Everything else stays on its spellbook tab.

Spellbook drop on a parent is `PlaceAction` on **this form’s** slot (no Shift). Shift-drag extras; Shift-drag a face off the bar empties that form’s slot. Add / hide / reorder extras are **this stance only** (`addedForms` / `hiddenForms` / `orderForms` on `DrawerForm` — travel extras are not caster’s). BIND a strip column writes `formBinds` for this form (`Shred cat → 2`); BIND a drawer extra does not steal that column’s `ACTIONBUTTON`.

---

## Checks before calling the pack done

- Every keyed spell is in the probe actives (or is SBA on an explicit `sba=true` face).
- Every probe active **not** on the SBA presses list has a `bindKey`, except Recover and World rows (click-only).
- Every probe racial active has a binding.
- Family **captions** match this role/character, not a leftover shaman/druid strip.
- Forms in `actionBars` / `forms` match probe shapeshifts. Ground travel may share caster slots; skyriding travel is bonus 5 and still uses the Forms-family keys.
- Same keys every stance; bear E is slot **97**, not page 1.
- Ctrl-wheel still camera unless this pack claimed it.
- `/reload`, then `/superbinds` out of combat. Load print matches toc.
