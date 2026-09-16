# SuperBinds 0.5.18

Repo folder: `C:\Users\Nick\Documents\Websites\SuperBinds`

**Shaman Binds stays** at `AddOns\ShamanBinds` → `Documents\Websites\ShamanBinds`. Do not rename or overwrite that junction.

## Junction

This folder should already be linked to WoW. If `dir` in AddOns is missing SuperBinds, close WoW and run (Developer Mode or admin):

```bat
mklink /J "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\SuperBinds" "C:\Users\Nick\Documents\Websites\SuperBinds"
```

`dir` in AddOns should show both:

- `<JUNCTION> ShamanBinds [...]`
- `<JUNCTION> SuperBinds [...]`

Do not nest another `SuperBinds` folder inside this project. No Media download is required: Balance uses built-in UI textures. Existing Media files may remain.

## In game (this character)

Disable **Shaman Binds** on this character so both addons do not own `/sbinds`, `/keymap`, keys, and native action slots. Leave Shaman Binds installed for other characters.

Then `/reload`. Out of combat and dismounted:

```
/superbinds load Feral
```

Guardian / Balance: `load Guardian` or `load Balance`. Spec follow should pick the pack on login. Applying places learned native-slot actions on that pack's form bars. Unknown spells do not get buttons. Reloads rebuild the console without Pickup/Place.

Current state (endcaps, BIND, open work): [`NOTES.md`](NOTES.md).

## Play

Wheel on Guardian / Feral: up Bear, down Cat, shift-up Moonkin, shift-down Travel. Ctrl-wheel zooms. BIND opens the grid — hover a spell and press a key. Backspace clears; Escape finishes. Ctrl-drag a face or drag `::` to move the console. The gold lip above BIND moves BIND independently. Forms are always manual; they are never next-cast.

BIND opens the grid. Hover a spell and press a key, wheel, or a mouse button. Backspace clears its binding; Escape finishes. Ctrl-drag a face, right-drag, or drag `::` to move the console. The gold lip above BIND moves BIND independently.

Shift-drag an ability onto another slot to swap within a family. Across families the destination receives a copy and retains the displaced ability in its drawer. Drop onto `+` to add a click-only copy. A drop outside the console cancels. External spellbook, item, macro and mount cursors can be dropped on faces, rows or `+`.

## Recommendations

Level-11 starter priority, not a max-level rotation. `useBlizzardSBA=false`: recommendations do not call Blizzard's next-cast assistant. Caster, cat and bear lists are independent. Unknown forms and travel forms produce no suggestion. `neverSuggest` excludes shapeshifts.

When combat data is secret, the engine skips conditions it cannot establish and can show a pack-designated no-cooldown filler. Unknown forms never fall back to caster. Shimmer is paint-only and animates in combat only.

## Commands

`/superbinds` apply and keymap; `load Balance`; `save My setup`; `load My setup`; `list`; `delete My setup`; `default`; `bind`; `map`; `options`; `hide`; `show`. `/keymap` opens the field guide.

Custom saves store an overlay plus their base pack name. Shipped tables are not overwritten.

## Do not

- Write `WTF` or `bindings-cache.wtf` while WoW is running.
- Load `_reference\ShamanBinds.lua` from the TOC.
