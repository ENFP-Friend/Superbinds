# Publish Super Binds 0.5.145

Everything you upload is in `dist\`. The paste text is below. You still have to make the accounts and click submit.

Zip to upload everywhere: `dist\SuperBinds-0.5.145.zip`

Screenshots, in this order: `dist\screenshots\`

Do not upload the git repo, `docs\`, `assets\`, or `SuperBinds_bak.lua`. The zip is already the right set of folders.

The GitHub repo is still private, and `main` does not contain this 0.5.145 code. Leave it private until you want the source public. The zip is the release.

License on every site: **All Rights Reserved**. That matches `LICENSE` in the zip. The GitHub README still says anyone may fork it. That sentence is looser than the license. Delete it before you make the repo public, or tell me and the license can be switched to MIT.

---

## Order

1. CurseForge. This is the one people actually install from.
2. Wago. Same zip. If it offers "import from CurseForge", use that, then paste the description only where the import left a hole.
3. WoWInterface. Same zip. Approval is slower.
4. Optional posts. Reddit and Discord, after the CurseForge page exists, so the link is real.

---

## 1. CurseForge

Open https://authors.curseforge.com/ and log in. Create an author account if it asks. Then **Create Project**.

| Field | Paste / pick |
|---|---|
| Game | World of Warcraft |
| Class | Addons |
| Name | Super Binds |
| Summary | see below |
| Categories | Action Bars, Class, Combat |
| License | All Rights Reserved |
| Logo | `dist\screenshots\00-logo.png` |

**Summary** (the one-line box):

```
One bar, one set of keys. The spell on each key changes with your form. Druid includes a finished layout. Every other class keeps the spells already on action bar 1.
```

**Description** (the big box). If the editor has a Markdown mode, use that. Otherwise paste it as-is.

```
One bar. The same keys in every form. The native action slot under each key is what changes: caster, cat, bear, travel, stance.

Druid ships with a layout, Elune Prime (Guardian and Elune's Chosen). Feral, Balance, and Guardian packs are in the download for spec follow. There is no Shaman layout in this addon.

Every other class gets a blank bar. Spells already on action bar 1 stay. Drag a spell onto a button, or bind a key, to change them. Those class modules only load for the class you are logged in as.

Apply is per character. It hides Blizzard bars 2 through 8. Other characters are left alone until they Apply too.

## First login

Install the zip, then restart WoW once so it sees the new addon folders. A setup card previews the bar. Apply on that character. Two callouts follow: the buttons, then BIND. MAP under BIND opens the field guide. Click a row to start Quick Keybind, then hover that row and press a key.

/superbinds tutorial shows the card again.

## What you do with it

Drag a spell from the field guide onto a button, or onto + to add a click row in that column's drawer.

BIND opens Quick Keybind. Hover an icon and press a key, the wheel, or a mouse button. Each form keeps its own slot memory.

Ctrl-drag a button to move the console.

The field guide (/keymap) can show bindings, every spell in your spellbook, or spells you have not placed. This form is the default, so a cat-only spell does not show as unused while you are in bear.

## Install

1. Download the zip. It already contains SuperBinds plus one folder per class. Unzip them into World of Warcraft/_retail_/Interface/AddOns so those folders sit directly in AddOns, not inside another folder.
2. Restart the client once.
3. Log in. If you also use a separate addon named Shaman Binds, disable it on this character. Both want the same keys.
4. Apply from the setup card, or type /superbinds out of combat.

To start over, close WoW and delete WTF/Account/<account>/SavedVariables/SuperBinds.lua. Then /superbinds clean. Do not delete SavedVariables while the game is running.

## Commands

/superbinds applies the pack.
/superbinds clean wipes overlays and reloads this class's shipped pack.
/superbinds reset restores pack keys. The console stays.
/superbinds load Elune Prime
/superbinds save, list, bind, tutorial, map, keys, options, hide, show
/keymap opens the field guide.
/sbinds is the same as /superbinds.

## Limits

Retail only. The TOC is interface 120007 and 120100. Not Classic.

Druid is the layout that has been played. Other classes are a usable empty bar, not a finished rotation.

The experimental next-best readout exists in options and is off by default.
```

Create the project, then **Files → Add File**.

| Field | Value |
|---|---|
| File | `dist\SuperBinds-0.5.145.zip` |
| Display name | Super Binds 0.5.145 |
| Release type | Beta |
| Game versions | Retail only. Check the boxes for interface 120007 and 120100 (12.0.7 and 12.1.0 if that is how the list is labeled). Do not check Classic, Era, or Mists. |

**Changelog** for that file:

```
Initial public release, 0.5.145.

One console, same keys in every form. The native slot under each key changes with shapeshift and stance.

Druid includes Elune Prime, plus Feral, Balance, and Guardian for spec follow.

Every other class keeps the spells already on action bar 1. Drag or BIND to change them. Only the class you are playing is loaded.

First login walks through Apply, the bar, and BIND. MAP opens the field guide.

Apply is per character and hides Blizzard bars 2-8.
```

Then upload the screenshots from `dist\screenshots\` in filename order. Captions:

```
01-setup.jpg — Setup card. Apply is this character only.
02-bar.jpg — After Apply. The bar, BIND, and MAP.
03-field-guide.jpg — Field guide with Quick Keybind on the left.
04-bar-horde.png — Horde bar. Same keys, wind-rider endcaps.
05-field-guide-list.png — Field guide list.
06-bind.jpg — BIND mode. One drawer per column.
07-cat.png — Cat form. Same keys, cat page.
08-travel.png — Travel form. Same keys, travel page.
```

Submit. CurseForge reviews the first file. That can take a day. You do not need to wait for it before filling in Wago.

---

## 2. Wago

Open https://addons.wago.io/ and sign in. Create the addon project. If **Import from CurseForge** is offered and your CurseForge project already exists, use it, then check the description.

| Field | Value |
|---|---|
| Name | Super Binds |
| Summary | same summary as CurseForge |
| Description | same description as CurseForge |
| Categories | Action Bars, Class, Combat |
| Flavor | Retail / Midnight. Not Classic. |
| File | `dist\SuperBinds-0.5.145.zip` |
| Version | 0.5.145 |
| Stability | Beta |
| Changelog | same changelog as CurseForge |

Wago's project id is a short code under the addon name on your dashboard. You do not need it for this hand upload. Save it if you later want automatic releases.

---

## 3. WoWInterface

Open https://www.wowinterface.com/ and log in. My Addons → add a new addon (wording varies: "Submit an addon" or "Add file").

| Field | Value |
|---|---|
| Name | Super Binds |
| Category | Action Bar Mods. Also Class & Role Specific if a second category is allowed. |
| Version | 0.5.145 |
| WoW version | Retail. Compatible with interface 120007 and 120100. Not Classic. |
| File | `dist\SuperBinds-0.5.145.zip` |
| License | All Rights Reserved |

**Short description:**

```
One bar, one set of keys. The spell on each key changes with your form. Druid includes a finished layout (Elune Prime). Every other class keeps the spells already on action bar 1.
```

**Long description** (WoWInterface still wants BBCode):

```
[b]One bar. The same keys in every form.[/b] The native action slot under each key is what changes: caster, cat, bear, travel, stance.

Druid ships with Elune Prime (Guardian and Elune's Chosen). Feral, Balance, and Guardian are included for spec follow. There is no Shaman layout in this addon.

Every other class gets a blank bar. Spells already on action bar 1 stay. Drag a spell onto a button, or bind a key, to change them. Only the class you are logged in as is loaded.

Apply is per character. It hides Blizzard bars 2 through 8.

[b]First login[/b]
Restart WoW once after install. A setup card asks you to Apply. Then two callouts: the buttons, then BIND. MAP under BIND opens the field guide.

[b]Install[/b]
[list]
[*]Unzip into World of Warcraft\_retail_\Interface\AddOns. The zip already contains SuperBinds and one folder per class. Those folders must sit directly in AddOns.
[*]Restart the client once.
[*]If you also use a separate addon named Shaman Binds, disable it on this character.
[*]Apply from the card, or type /superbinds out of combat.
[/list]

[b]Commands[/b]
[code]/superbinds[/code] apply
[code]/superbinds clean[/code] wipe overlays and reload this class's shipped pack
[code]/superbinds tutorial[/code] show the setup card again
[code]/keymap[/code] field guide
Alias: [code]/sbinds[/code]

Retail only (interface 120007 and 120100). Druid is the layout that has been played. Other classes are a usable empty bar, not a finished rotation.
```

**Changelog:**

```
0.5.145
Initial public release.
One console, same keys in every form.
Druid includes Elune Prime, plus Feral, Balance, and Guardian.
Other classes keep action bar 1 and load only for the class you are playing.
```

Upload the same screenshots if the form allows them.

---

## 4. After a page exists

**Reddit** — r/wow or r/WowUI. Title:

```
Super Binds: one bar, same keys, the spell changes with your form
```

Body:

```
Retail addon. One console. The keys stay put and the native slot under each key changes with form or stance.

Druid includes a layout (Elune Prime, plus the other spec packs). Every other class keeps whatever is already on action bar 1, and you drag or bind from there. Only your class's module loads.

Apply is per character and hides Blizzard bars 2-8. BIND is on the console. MAP under it opens a field guide.

First public build, 0.5.145, marked beta. Druid is the one I've actually played.

CurseForge: PASTE THE URL
```

**Discord**, wherever you already talk about addons. Not a new server.

```
Super Binds 0.5.145 is up. One bar, same keys, the spell changes with your form. Druid has a layout. Other classes start from action bar 1. Beta. PASTE THE URL
```

---

## What is in the zip

Top level, which is what WoW and CurseForge expect:

- `SuperBinds` — the engine, Media, license
- `SuperBinds_Druid` — Elune Prime, Guardian, Elune's Chosen, Feral, Balance
- `SuperBinds_Warrior`, `SuperBinds_Paladin`, `SuperBinds_Hunter`, `SuperBinds_Rogue`, `SuperBinds_Priest`, `SuperBinds_DeathKnight`, `SuperBinds_Shaman`, `SuperBinds_Mage`, `SuperBinds_Warlock`, `SuperBinds_Monk`, `SuperBinds_DemonHunter`, `SuperBinds_Evoker` — blank bars, one loaded per character

Not in the zip: docs, the art workshop, SavedVariables, the old Shaman profile experiments, `SuperBinds_bak.lua`.
