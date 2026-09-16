# Super Binds

Class-agnostic Midnight action console, ported from Shaman Binds. **0.5.18**. Layouts are **profile data** — the engine has no class spells.

Current TOC packs: **Guardian** (default), **Feral**, **Balance**. Live notes: [`docs/NOTES.md`](docs/NOTES.md).

- Astra / port brief: [`docs/SUPERBINDS-BRIEF.md`](docs/SUPERBINDS-BRIEF.md)
- Profile schema: [`docs/PROFILE-SCHEMA.md`](docs/PROFILE-SCHEMA.md)
- Install: [`docs/INSTALL.md`](docs/INSTALL.md)
- Reference (not loaded by the TOC): [`_reference/ShamanBinds.lua`](_reference/ShamanBinds.lua)

## Install

Junction this folder to `_retail_\Interface\AddOns\SuperBinds`. Do **not** replace the ShamanBinds junction.

Disable **Shaman Binds** on the Druid, `/reload`, then out of combat:

```
/superbinds load Feral
```

Guardian and Balance: `/superbinds load Guardian` or `Balance`. Spec follow should pick Feral (103), Guardian (104), or Balance (102) on login.

## Play

- Same keys every form: native `ACTIONBUTTON` 1–12, form bars placed with `PlaceID`.
- Wheel (Guardian / Feral packs): up Bear, down Cat, shift-up Moonkin, shift-down Travel. Ctrl-wheel zooms.
- BIND: hover a face, press a key. Mouse binds the painted spell, not the caster-bar leftover.
- Endcaps swap with shapeshift (bear / cat / travel). Horde default is the wyvern bust; Alliance is still the owl.
- Assisted Rotation is paint-only (`GetNextCastSpell`). Shapeshifts are never next-cast.
