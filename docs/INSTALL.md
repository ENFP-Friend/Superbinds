# SuperBinds 0.5.117

Repo folder: `C:\Users\Nick\Documents\Websites\SuperBinds`

Parked, AI-assisted, Druid import only — see [`../README.md`](../README.md).

**Shaman Binds stays** at `AddOns\ShamanBinds` → `Documents\Websites\ShamanBinds`. Do not rename or overwrite that junction. SuperBinds is **not** a Shaman layout.

## Junction

This folder should already be linked to WoW. If `dir` in AddOns is missing SuperBinds, close WoW and run (Developer Mode or admin):

```bat
mklink /J "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\SuperBinds" "C:\Users\Nick\Documents\Websites\SuperBinds"
```

`dir` in AddOns should show both:

- `<JUNCTION> ShamanBinds [...]`
- `<JUNCTION> SuperBinds [...]`

Do not nest another `SuperBinds` folder inside this project. No extra Media download is required. Existing `Media\` TGAs (endcaps) load from this folder.

## Start clean

Close WoW. Delete `WTF\Account\<account>\SavedVariables\SuperBinds.lua` (and `.bak`). Log in on a Druid with **Shaman Binds disabled**. `/reload`. Then **Start clean** + **Import Druid layout** in settings, or `/superbinds clean`.

Never delete SavedVariables while WoW is running.

## In game

Chat should print `Super Binds: 0.5.117 loaded.` Out of combat:

```
/superbinds clean
```

That is the one Druid import (**Elune Prime**). `/superbinds list` still shows extra spec packs if you want them.

Apply **PlaceID**s learned spells onto **each form’s bar**. Unknown spells do not get buttons.

Current feature notes: [`NOTES.md`](NOTES.md) · product: [`../README.md`](../README.md) · pack schema: [`PROFILE-SCHEMA.md`](PROFILE-SCHEMA.md).

## Play

Same keys every form. E / Q / C / R / M4 / M5 / wheel stay on their columns; the **ability on that column** is the form bar. Ground travel shares caster slots. Skyriding flight form is still Travel Form (bonus 5): the console stays, the default bar hides, **E / Q / C** are Surge Forward / Second Wind / Whirling Surge, **1 / 2** are Aerial Halt / Skyward Ascent, and the Forms wheel still changes forms.

Elune Prime wheel: up Bear, down Cat, shift-down Travel. Thorn Bloom is Shift-E. Ctrl-wheel zooms. Forms are always manual; they are never next-cast.

BIND opens the grid. Hover a spell and press a key, wheel, or a mouse button. Keyboard BIND places the painted ability on **this form’s** slot.

Ctrl-drag a face, right-drag, or drag `::` to move the console.

## Commands

`/superbinds` apply; `clean`; `load Elune Prime`; `save`; `list`; `bind`; `map`; `options`; `keys`; `hide`; `show`. `/keymap` field guide. Alias `/sbinds`.

## Do not

- Write `WTF` or `bindings-cache.wtf` while WoW is running.
- Load `_reference\ShamanBinds.lua` from the TOC.
- Enable Shaman Binds and SuperBinds on the same character.
- Expect a Shaman import. That addon is separate and not class-agnostic.
