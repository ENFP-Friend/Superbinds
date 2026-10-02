<p align="center">
  <img src="docs/logo.png" alt="Super Binds" width="360">
</p>

# Super Binds

This addon is for people who want a simpler action bar. It replaces Blizzard's main action bar.

Each button is a spell you press all the time, such as an attack, an interrupt, a heal, or a defensive. Hover the button and the other spells in that group open. You can look through your abilities, set a hotkey quickly, and keep those keys under a label for what they are.

Changing form does not move those keys. The spell on the button changes with the form.

An attack helper times the next attack, so you can press as it comes ready. It is off until you turn it on.

https://github.com/user-attachments/assets/0554ebdd-a97d-4d26-8e2b-bad28d7c3c1f

The caps on the ends of the bar are drawn for your faction, and for Haranir Druid forms. You can save a layout and load it again later.

It has really only been tested on a Druid, so expect bugs. I made it with AI, and a lot of the Lua is AI slop. I built it for myself. I am quitting WoW, and I figured someone else might want it. Fork it, improve it, do whatever you want with it.

## First login

Install the zip, then restart WoW once so it sees the new addon folders. A setup card shows the bar and asks you to apply on that character. Two callouts follow: the buttons, then BIND. MAP under BIND opens the field guide. Click a row to start Quick Keybind, hover that row, and press a key.

`/superbinds tutorial` shows the card again.

![Setup card — preview of the bar, Apply on this character](docs/shots/tutorial-setup.jpg)

After Apply, two callouts sit on the real bar. The first is the buttons. The second is BIND, and MAP under it.

![Coach mark on the bar — drag a spell onto a slot](docs/shots/tutorial-bar.jpg)

MAP opens the field guide. Click a row and Quick Keybind Mode starts, so you can hover that row and press a key. The Blizzard window sits on the left.

![Field guide with Quick Keybind Mode](docs/shots/field-guide-bind.jpg)

## Install

1. Download the zip. It already contains SuperBinds plus one folder per class. Unzip them into `World of Warcraft/_retail_/Interface/AddOns` so those folders sit directly in AddOns, not inside another folder.
2. Restart the client once.
3. Log in. If you also use a separate addon named Shaman Binds, disable it on this character. Both want the same keys.
4. Apply from the setup card, or type `/superbinds` out of combat.

To start over, close WoW and delete `WTF/Account/<account>/SavedVariables/SuperBinds.lua`. Then `/superbinds clean`. Do not delete SavedVariables while the game is running.

On a Druid you can also use ESC → Options → AddOns → **Super Binds** → **Start clean** → **Import Druid layout**. That loads the shipped Druid layout, Elune Prime.

If you are working from this repo, junction the folder to `_retail_/Interface/AddOns/SuperBinds` and put each `SuperBinds_<Class>` folder beside it. Full steps: [`docs/INSTALL.md`](docs/INSTALL.md).

## Commands

- `/superbinds` applies the layout.
- `/superbinds clean` wipes overlays and reloads this class's shipped layout.
- `/superbinds reset` restores the layout's keys. The bar stays.
- `/superbinds load Elune Prime`
- `/superbinds save`, `list`, `bind`, `tutorial`, `map`, `keys`, `options`, `hide`, `show`
- `/keymap` opens the field guide.
- `/sbinds` is the same as `/superbinds`.

## Limits

Retail only. Interface 120007 and 120100. Not Classic.

Druid is the layout that has been played. Other classes get the same bar and keep the spells already on it. That bar is usable. It is not a finished layout.

The attack helper is in the options and off by default.

## More of it

https://github.com/user-attachments/assets/3cdeb784-c3e7-41b7-9bd4-6409eec09026

**Adding and moving spells.** Drop a spell on a button, or set its key with BIND. Each form keeps its own spells on those keys (unshifted, cat, bear, travel, and so on).

https://github.com/user-attachments/assets/ca82af59-d3d5-4644-9b2f-74fd024eb204

**Haranir bat form.** Same keys. The bat-form spells and the end cap change.

https://github.com/user-attachments/assets/d4cb291b-2684-4674-81a6-2b39eefb3a0f

**Druid forms.** The bar in each form, setting keys, and the attack helper. Blizzard's assisted rotation leaves bleeds out, so that helper does not keep bleeds stacked.

https://github.com/user-attachments/assets/1eb62c11-db0c-4e98-ae85-c976e423f44c

**Not this addon.** The totem timers in this clip are from an older private shaman addon. They are not in Super Binds.

![Field guide — every ability and its key](docs/shots/06-field-guide.png)

**Field guide** (`/keymap`). Bindings on the bar, or every spell you know. **Not used** hides spells already placed. **This form** is the default, so a cat-only spell does not show as unused while you are in bear.

![Hotkey menu — BIND drawers per family](docs/shots/07-hotkey-menu.jpg)

**BIND.** Hover an icon and press a key, a mouse button, or the wheel. Each form keeps its own keys.

## The bar

The labels stay in every form. The spell on the button is what changes: caster, cat, bear, bat form, skyriding.

![Horde default bar — wind-rider endcaps](docs/shots/04-horde-default-bar.png)

More stills (cat, travel, Alliance owl): [`docs/SHOTS.md`](docs/SHOTS.md).

## Docs

| | |
|---|---|
| Install | [`docs/INSTALL.md`](docs/INSTALL.md) |
| Screenshots | [`docs/SHOTS.md`](docs/SHOTS.md) |
| Attack helper | [`docs/EXPERIMENTAL.md`](docs/EXPERIMENTAL.md) |
| Making a layout | [`docs/PROFILE-GUIDE.md`](docs/PROFILE-GUIDE.md) |
| Layout schema | [`docs/PROFILE-SCHEMA.md`](docs/PROFILE-SCHEMA.md) |
| Endcap art | [`docs/ART.md`](docs/ART.md) |
| Notes | [`docs/NOTES.md`](docs/NOTES.md) |
| Known errors | [`docs/ISSUES.md`](docs/ISSUES.md) |
