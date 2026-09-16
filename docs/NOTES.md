# SuperBinds notes

Snapshot: **0.5.18** (16 Sep 2026). Shipping addon is this folder, junctioned to `_retail_\Interface\AddOns\SuperBinds`. Live **Shaman Binds** stays a separate addon — do not edit its GUI or junction. **DruidAssistant** is an unused sidecar; BIND, bars, and endcaps do not live there.

## Product split

| Piece | Where | Role |
| --- | --- | --- |
| Engine | `SuperBinds.lua` | Console, BIND, native slots, form bars, SBA paint, endcap swap |
| Druid packs | `Profiles/Druid/*.lua` | Spells, keys, families, `theme.endcaps` |
| Shipped art | `Media/*.tga` | What the game loads |
| Packed PNG sources | `assets/DruidEndcap_{bear,cat,travel,horde}.png` | Cropped 80×120 / 90×120 sources |
| Workshop drafts | ShamanBinds `assets/` (open Cursor workspace) | Rejected gens; not loaded by TOC |

Engine has no class spells. If you need a shapeshift name or TGA path, it belongs in a pack.

## Packs in the TOC

`SuperBinds.toc` loads Guardian, Feral, then Balance.

- **Guardian** (`spec=104`, `nativeForm=bear`, default) — wheel: up Bear, down Cat, shift-up Moonkin, shift-down Travel. Ctrl-wheel stays camera.
- **Feral** (`spec=103`, `nativeForm=cat`) — auto-follows Feral spec. E is SBA in cat.
- **Balance** (`spec=102`, `nativeForm=moonkin`) — starter, not an endgame APL.

`/superbinds load Guardian` / `Feral` / `Balance`. Spec follow should pick the matching pack on login.

Live character for this work: Haranir Druid, switched Guardian → Feral.

## Endcaps (form GUI)

`P.FormEndcap()` uses the **shapeshift name** (`cat` / `bear` / `travel` / `moonkin`), not `BarOwner`. Travel shares the caster action bar (`use="caster"`); looking up `endcaps.caster` was why travel kept the Horde wyvern until 0.5.16.

Shipped:

| Form / faction | File | Size | `leftIn` | Pick |
| --- | --- | --- | --- | --- |
| Bear | `Media/DruidEndcap_bear.tga` | 80×120 | 26 | Haranir quill-bear, relic wood-bronze (`batC`) |
| Cat | `Media/DruidEndcap_cat.tga` | 80×120 | 26 | **Rejected.** Live file is still v2-B orange wolverine. v5 A–D generated, not packed. |
| Travel | `Media/DruidEndcap_travel.tga` | 80×120 | 26 | Haranir sable, huge ears, pick **C** |
| Horde default | `Media/DruidEndcap_horde.tga` | 90×120 | (faction 36) | Wind rider, horns, gold-collar bust, pick **B** (v4) |
| Alliance default | `Media/ShamanEndcap.tga` | 70×120 | 36 | Leftover owl. Not replaced. |
| Moonkin | — | — | — | Not started. |

Caster / moonkin / unknown form show Alliance owl or Horde wyvern. Bear, cat, and travel override while shifted.

Art rules that stuck: carved walnut + gold leaf inlay (Druid relic, not shaman runes, not living fur). Anatomy from in-game screenshots + wiki. Do not attach a different animal’s sculpture as a reference or the head morphs.

TGA: uncompressed 32-bit, origin bottom-left, header descriptor `8`.

## BIND / bars (engine)

Unified bar: hotkey label, ability, and native slot stay one object. Keyboard faces are `ACTIONBUTTON` 1–12. Mouse/wheel cannot reliably fire `ACTIONBUTTON` on retail — those use `SPELL` / hardware click attrs.

Fixes already in the engine (not Druid-hardcoded):

- Extra that exists on another form’s bar: place on this form’s column + `ACTIONBUTTON`, do not save the caster spell.
- Mouse BIND uses the **painted** spell, not `GetActionInfo` of the relative caster slot (that was Roots while the cat face showed Prowl).
- Claimed mouse keys skip `ArmHardwareClicks` type4/5 stamps (Dash on M4 was firing with Prowl).

Remaining gap: mouse `SPELL` is form-static; keyboard columns follow the form bar. `FireableMouseCommand` can still prefer a pack-default mouse key.

## SBA

`C_AssistedCombat.GetNextCastSpell(false)` is paint-only. Midnight combat IDs are secret — pass the raw id into texture/cooldown APIs, do not unwrap/compare. Native ActionButton hosts must still get `PaintAssistedFace`. Do not `SetActionUIButton`. Shapeshifts are never next-cast.

Custom primary / SBA drop is per-form (`formPrimary`), not one spell on every face.

## Hard constraints

- Lua 200 locals per file (`P` table, nested `do`).
- Midnight secrets: no comparing secret numbers.
- No `SetActionUIButton`.
- Do not write WTF / `bindings-cache.wtf` while WoW is running.
- Unmodified wheel is camera unless BIND or the pack claimed it.
- `@cursor` abilities need a real action slot.

## Next (paused here)

1. **Cat redo** — user disliked the shipped wolverine. Four new busts: workshop `DruidEndcap_cat_ui_v5_{A,B,C,D}.png` (ShamanBinds `assets/` and Cursor project `assets/`). Pick one, pack to `Media/DruidEndcap_cat.tga` like bear.
2. Moonkin (Haranir batbear) endcap.
3. Alliance owl replacement (same relic process as Horde wyvern).
4. Optional: mouse BIND column-follow; leftover shaman comments / default owl theme; disable DruidAssistant when SuperBinds owns bars.

## Commands

`/superbinds` apply; `load Guardian|Feral|Balance`; `save`; `list`; `bind`; `options`; `keys`. `/keymap` field guide.

Disable **Shaman Binds** on this character so both addons do not own keys and slots.
