# SuperBinds 0.5.83

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

Do not nest another `SuperBinds` folder inside this project. No extra Media download is required. Existing `Media\` TGAs (endcaps) load from this folder.

## In game (this character)

Disable **Shaman Binds** on this character so both addons do not own `/sbinds`, `/keymap`, keys, and native action slots. Leave Shaman Binds installed for other characters.

Then `/reload`. Chat should print `Super Binds: 0.5.83 loaded.` Out of combat and dismounted, spec follow should pick **Elune Prime** on a Guardian with hero tree 24, or **Guardian** / **Feral** / **Balance** by spec. Force with:

```
/superbinds load Elune Prime
```

Also `load Elune's Chosen` (previous Elune strip), `load Guardian` (previous bear kit), `load Feral`, `load Balance`.

Apply **PlaceID**s learned spells onto **each form’s bar** (caster page 1, cat bonus 1, bear bonus 3, moonkin bonus 4). The same hotkeys (`ACTIONBUTTON` 1–12, plus pack mouse/wheel) fire whichever page is showing. Unknown spells do not get buttons. Reloads rebuild the console without Pickup/Place.

Current feature notes: [`NOTES.md`](NOTES.md) · product: [`../README.md`](../README.md) · pack schema: [`PROFILE-SCHEMA.md`](PROFILE-SCHEMA.md).

## Play

Same keys every form. E / Q / C / R / M4 / M5 / wheel stay on their columns; the **ability on that column** is the form bar. Ground travel shares caster slots. Skyriding flight form is still Travel Form (bonus 5): the console stays, the default bar hides, **E / Q / C** are Surge Forward / Second Wind / Whirling Surge, **1 / 2** are Aerial Halt / Skyward Ascent, and the Forms wheel still changes forms.

Elune / Guardian / Feral wheel: up Bear, down Cat, shift-up Thorn Bloom, shift-down Travel. Ctrl-wheel zooms. Forms are always manual; they are never next-cast.

BIND opens the grid. Hover a spell and press a key, wheel, or a mouse button. Keyboard BIND places the painted ability on **this form’s** slot. Mouse BIND uses the painted spell, not page-1 leftover. Backspace clears; Escape finishes.

Ctrl-drag a face, right-drag, or drag `::` to move the console. The gold lip above BIND moves BIND independently.

Spellbook / rune-book: pick the spell up and drop it on the parent face (**no Shift**). That must `PlaceAction` the live bonus-bar slot (bear E = 97). Shift-drag a **drawer extra** onto the parent (old parent moves into the drawer). Shift-drag a **face off the bar** (including onto the empty drop rail) `PickupAction`+`ClearCursor` that form’s slot and writes `formPrimary.empty` so apply will not restock it. Drop onto `+` to add a click-only copy. A drop writes only the stance you are in — it must not PlaceID every form or shuffle the cursor. `/superbinds restore E` puts the pack parent back.

Identity / known errors: [`ISSUES.md`](ISSUES.md).

## Recommendations

Level-21 kit, not a max-level rotation. `useBlizzardSBA=false`: pack lists do not call Blizzard’s next-cast assistant. Caster, cat, bear and moonkin lists are independent. Unknown forms and travel produce no suggestion. `neverSuggest` excludes shapeshifts.

When combat data is secret, the engine skips conditions it cannot establish and can show a pack-designated no-cooldown filler. Unknown forms never fall back to caster. Shimmer is paint-only and animates in combat only. Native-form SBA (Feral E in cat) still paints live via `GetNextCastSpell` without unwrapping secret ids.

## Commands

`/superbinds` apply and keymap; `load Elune Prime|Elune's Chosen|Guardian|Feral|Balance`; `save My setup`; `load My setup`; `list`; `delete My setup`; `default`; `bind`; `map`; `options`; `keys`; `hide`; `show`. `/keymap` opens the field guide. Alias `/sbinds`.

Custom saves store an overlay plus their base pack name. Shipped tables are not overwritten. Custom parents are per-form (`formPrimary`).

## Do not

- Write `WTF` or `bindings-cache.wtf` while WoW is running.
- Load `_reference\ShamanBinds.lua` from the TOC.
- Enable Shaman Binds and SuperBinds on the same character.
