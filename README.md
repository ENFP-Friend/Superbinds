# Super Binds

Class-agnostic Midnight action console. **One bar, one set of keys, a different native action page per form.** Ported from [Shaman Binds](https://github.com/ENFP-Friend/ShamanBinds). **0.5.116** — Druid packs ship now.

<video src="https://github.com/user-attachments/assets/c9f4c4cc-6c1d-4e72-859e-208a43a627ba" controls muted playsinline></video>

**Adding and moving spells** — BIND, drawers, and dropping abilities onto faces. Each form keeps its own slot memory (unshifted vs cat, bear, travel, and so on).

<video src="https://github.com/user-attachments/assets/094719ad-63a4-406e-a269-537c0861d8ae" controls muted playsinline></video>

**Haranir bat form** — same keys, bat-form page and endcap.

<video src="https://github.com/user-attachments/assets/b01152df-cb3e-40d1-8ae5-09792e1d6304" controls muted playsinline></video>

**0.5.116** — Haranir Druid: every form bar, hotkey helper, GCD attack helper, and the cat attack helper. Blizzard’s assisted rotation omits bleeds, so they do not stack from that helper.

<video src="https://github.com/user-attachments/assets/64c0e38c-e97c-4613-a837-e4ed698446d7" controls muted playsinline></video>

**Shaman Binds origin (WIP)** — totem-pole timers, ultimate, menus and drawers. SuperBinds is the port; those timers are **not** in SuperBinds yet.

![Field guide — every ability and its key](docs/shots/06-field-guide.png)

**Field guide** (`/keymap`) — a quick look at every spell and binding.

![Hotkey menu — BIND drawers per family](docs/shots/07-hotkey-menu.jpg)

**Hotkey menu** — BIND mode. Hover an icon, press a key or scroll. Each form keeps its own slot memory.

## The bar

Same labeled keys in every stance. The **native slot under the key** is what changes (caster, cat, bear, bat form, skyriding).

![Horde default bar — wind-rider endcaps](docs/shots/04-horde-default-bar.png)

More stills (cat, travel, Alliance owl): [`docs/SHOTS.md`](docs/SHOTS.md).

## Install

Junction this folder to `_retail_\Interface\AddOns\SuperBinds`. Do **not** replace the ShamanBinds junction. Disable **Shaman Binds** on the Druid so both addons do not own keys and slots. `/reload`, then apply out of combat.

Full steps: [`docs/INSTALL.md`](docs/INSTALL.md).

## Packs

| Pack | Spec | Native form | Notes |
|---|---|---|---|
| **Elune Prime** | Guardian | bear | default (hero tree 24) |
| Elune's Chosen | Guardian | bear | previous Elune strip |
| Guardian | Guardian | bear | fallback |
| Feral | Feral | cat | E is SBA in cat |
| Balance | Balance | moonkin | starter, not an endgame APL |

`/superbinds load Elune Prime` (or `Elune's Chosen` / `Guardian` / `Feral` / `Balance`).

## Commands

`/superbinds` apply · `load …` · `save` · `list` · `bind` · `options` · `keys` · `hide` / `show`. Alias `/sbinds`. Field guide: `/keymap`.

## Docs

| | |
|---|---|
| Install | [`docs/INSTALL.md`](docs/INSTALL.md) |
| Screenshots | [`docs/SHOTS.md`](docs/SHOTS.md) |
| Next-best / pulse (experimental) | [`docs/EXPERIMENTAL.md`](docs/EXPERIMENTAL.md) |
| Profile from a live probe | [`docs/PROFILE-GUIDE.md`](docs/PROFILE-GUIDE.md) |
| Schema | [`docs/PROFILE-SCHEMA.md`](docs/PROFILE-SCHEMA.md) |
| Endcap art | [`docs/ART.md`](docs/ART.md) |
| Session notes / agent traps | [`docs/NOTES.md`](docs/NOTES.md) |
| Known errors | [`docs/ISSUES.md`](docs/ISSUES.md) |
