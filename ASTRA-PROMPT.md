Paste this into Astra, then attach the files listed at the bottom.

---

You are continuing **SuperBinds**, a WoW Midnight addon. Attached `_reference/ShamanBinds.lua` (8.34) is the **working engine**. You do not have my disk beyond the attachments.

**Previous SuperBinds.lua is a failed rewrite. Do not extend it.** Copy `_reference/ShamanBinds.lua` → `SuperBinds.lua` and port. Current SuperBinds.lua is a negative example of what went wrong.

Do not edit live Shaman Binds. Do not TOC-load `_reference`. Do not commit or push.

## Naming

- Addon: SuperBinds. DB: SuperBindsDB. Slash: `/superbinds` `/sbinds` `/keymap`.
- **Class** = `DRUID` (folder `Profiles/Druid/`).
- **Packs** (data only): `Balance` and `Guardian`. Live character is **Guardian**. Default Druid pack: `Guardian` (`default=true`). Balance stays a loadable pack. `/superbinds load Guardian` and `/superbinds load Balance`.
- Engine grep must have **no** Wrath, Moonfire, Cat Form, Mangle, Wind Shear, Ghost Wolf, Farseer, Hex.

## Method (mandatory)

1. Copy `_reference/ShamanBinds.lua` to `SuperBinds.lua`. Rename ShamanBinds → SuperBinds, DB, slashes, prints. Keep subsystems verbatim (de-shamanize data only).
2. Move class content into profile files. Do **not** invent a second placement kernel.
3. Then add generic form-bar / rotation / save-reset features from the brief. No `if druid`.

Keep from Shaman Binds: console, tabs, drawers, BIND + gold lip, `::` grip, drop rail `+`, PlaceID/PickupID, EnsureMacro only when needed, NeedsBlizzardSlot genericized (`@cursor` / `target=="cursor"` / profile flag — **not** totem names), AllocHiddenSlot 8–12, KEEP, ArmModifiedCast, BindKeyTo / mouse ≠ CLICK, cooldown swipe + numbers on tabs **and** drawer rows, paint-only `ActionBarButtonAssistedCombatHighlightTemplate` (**no SetActionUIButton**, Play-then-Stop once, combat-only loop), hide bar 1 without eating Character/Progression clicks, mount/vehicle yield, Extra Action stays, Enter/`/` chat, Numpad 8/9 unbound, profile save/load + `Before <name>` snapshot, sculpture **renderer** if `profile.sculptures` nonempty, theme **application**, 200 locals on `P`/nested `do`, Midnight secrets (never compare secrets; SetCooldown without comparing).

## Unified action bar (the original already does this — copy it)

This is the product. A bar face is **one native WoW slot**. Spell, hotkey, and label are the same object. They stay together when the face is dragged, when the ability on that slot changes, and when the player rebinds in **WoW** (Key Bindings / Quick Keybind), not only inside SuperBinds.

Copy `_reference` behaviour. Do not invent a second identity for “console tab” vs “action slot” vs “form page”.

- **Identity is the slot**, not the spell and not a per-form overlay key. bindId = `bar:N`. Keyboard SetBinding goes to `ACTIONBUTTONN` (so mount/vehicle can reuse those keys when our overrides drop). Console tab is `type="action"` `action=N` — click and hotkey both `UseAction` that slot. Comment in 8.34: “Bar faces: click and hotkey both UseAction on that slot.” Drag comment: “Keys stay on their slots; only the abilities move.”
- **Hotkey label is live WoW.** `RefreshBindLabels` / `GetBindingKey(commandName)` / `GetBindingKey("ACTIONBUTTON"..slot)`. Overlay `binds["bar:N"]` / `barBinds["ACTIONBUTTONN"]` is a cache of that, not a private keymap the UI paints from while WoW disagrees.
- **`UPDATE_BINDINGS` observes WoW.** If the player rebinds Action Button 1 in Blizzard’s UI, our E face label, overlay, and click target stay that slot. Do not fight it by immediately `SetBinding` the pack default back. Do not paint labels from `overlay.binds[identity]` while ignoring `GetBindingKey`. Mouse/wheel are the exception (CLICK never fires; those stay MACRO/ACTIONBUTTON 8–12).
- **Quick Keybind** on our console writes the same command the face already owns (`ACTIONBUTTONN` for bar faces). Hover-bind and WoW Quick Keybind are one system (`WireQuickKeybind`, `AssignHoveredBind`, `RebindAll`).
- **Form pages do not split the face.** Relative slot 1 is ACTIONBUTTON1 / E in caster, cat, bear, moonkin. PlaceID different spells onto each form’s **absolute** slots. Same key, same label, same tab. Never `identity..":"..form` macros, never a second PlaceAction for the display primary.
- **Drawer extras** (no bar slot): keyboard may CLICK a named helper; mouse still cannot CLICK — AllocHiddenSlot 8–12. That is the only split, and 8.34 already has it.

The rewrite broke this on purpose by accident: per-face `SuB*` macros, `overlay.binds[identity]`, `skipPlace` when two identities wanted one slot, labels from `P.Key(entry)`, `ApplyBindings` fighting live keys. Delete all of that.

## Why the last port was fundamentally wrong

These are not polish bugs. They mean the engine is not Shaman Binds.

1. **Rewrite, not port.** ~1800-line new kernel. Lost PlaceID, ArmModifiedCast, hidden 8–12, KEEP, Quick Keybind.
2. **Macro flood.** CreateMacro / `SuB*` per console face / per form identity → 120-macro cap. Ordinary spells must **PlaceID** (`C_Spell.PickupSpell` + native slot). Named macros only for `@cursor`, profile-supplied macro bodies, or mouse binds that cannot CLICK. Small stable names, prune orphans, character then account, `pcall(CreateMacro)`.
3. **Duplicate / invalid slots.** Display primary and per-form bar row packed onto the same slot → apply aborted. Faces that share a native slot are `type="action"` on that slot, not a second PlaceAction.
4. **`/reset` destroyed the product.** Hid SuperBinds console, `LoadBindings(DEFAULT_BINDINGS)`, Blizzard bar came back. Reset must **keep our console**, empty owned slots, restore **pack default keys**, PlaceID again, hide bar 1. Snapshot `Before reset`. Never LoadBindings(defaults) as reset.
5. **Form kit empty.** `formAbilities` / FormAbilities.lua never TOC-loaded (or never fed BIND “See All”). Kit is profile data: `profile.formAbilities[form] = { ids/names }`. TOC loads engine then profile lua files. Unknown IDs hide via Known().
6. **BIND face missing / broken** because the rewrite dropped BIND workshop, lip, and gold key.
7. **Blizzard bar vs our bar.** hideBar1 must work like 8.34. Reset/apply must not “fix” by showing Blizzard bar 1.
8. **Identity overlay / skipPlace** invented to paper over duplicate slots. Delete that approach. Use Shaman Binds placement.
9. **Split action bar.** Console tab, hotkey label, and native slot were three different objects. Moving a face or rebinding in WoW desynced them. Original: one `bar:N` face; keys stay on slots; abilities move; labels follow `GetBindingKey`.

## Stay-in-form (the Druid problem the rewrite never solved)

Blizzard Single-Button Assistant / `C_AssistedCombat` is **spec-native form only**. Guardian in bear is correct. Guardian in cat/caster/travel: SBA shapeshifts or plays bear/Balance buttons and never returns. JustAC / IncredibleAssist / HekiLight only skin SBA — they cannot fix this.

**What actually works (this is the engine+profile design):**

- Same keys (ACTIONBUTTON 1–12). **Different PlaceID spells on each form’s absolute slots** (caster 1–12, cat bonus1 ~73–84, bear bonus3 ~97–108, moonkin bonus4; use the API, do not hardcode class). Relative `slot=1` stays E / ACTIONBUTTON1 in every form.
- Shapeshifts are **manual** keys (`allBars=true`), never next-cast.
- `neverSuggest` includes every shapeshift ID/name. Also exclude Fluid Form **destinations that leave the current form** (Shred/Rake/Skull Bash → cat, Mangle → bear, Wrath/Starfire → moonkin if known, Dash → cat, Stampeding Roar → bear). Pressing those **is** a form change.
- `useBlizzardSBA=false` on Druid packs unless a pack explicitly wants Blizzard **only while already in the spec’s native form**. Never use GetNextCastSpell as the brain that tells you to shift.
- Off-form shimmer = `profile.rotation[currentForm]` for the form you **already are in**. Unknown form → no suggestion (do not fall back to caster). Unshifted = `profile.form` (usually `"caster"`). Map via `profile.forms` + `GetShapeshiftFormInfo`. **Do not** hardcode form index 1 = cat in the engine.
- **Midnight secrets:** do **not** require `UnitCanAttack == true` (or other combat booleans) to advance next-cast. Those come back nil. If you do, the icon freezes on the form opener until a form change. Skip rules you cannot prove; `fallback=true` is the no-cooldown filler. `auraMissing`: if the aura value is secret, do not freeze on that spell forever — remember own casts or skip the rule.
- Rotation lists with a **single** spell (bear = Mangle only) never step. Packs must list the real in-form priority (Guardian bear: Thrash → Mangle → Lunar Beam/Red Moon → Maul/Raze → Moonfire maintain → Swipe filler; **not** Moonfire-first). Look up current Icy Veins / SimC `guardian_apl.inc`. Do not invent an endgame Balance APL for a level-11 Balance pack; `Known()` hides unlearned.
- Assisted highlight on **our console**: paint-only, no SetActionUIButton. On **Blizzard ACTIONBUTTON keys**: in spec native form, WoW already highlights those keys — do not fight it. Off-form, do not let SBA light Bear Form / shapeshift keys; glow the stay-in-form spell that is actually on that form’s bar.

## Extra engine features (after the kernel exists)

Generic. No `if druid`.

**Stance / form bars** — `profile.actionBars` as in `docs/PROFILE-SCHEMA.md`. Secure `[bonusbar:N]`. Out of combat PlaceID onto each form’s absolute slots. `allBars=true` shapeshifts on the same relative slot every page.

**Form kit** — `profile.formAbilities[form]`. BIND See All uses this, not “whatever IsSpellUsable”.

**Commands** — `/superbinds` apply+keymap; `load <name>`; `save [name]` overlay (not overwrite shipped tables); `reset` as above; `list` / `delete` / `default`; `bind` / `map` / `options` / `hide` / `show`. Autosave positions when settings.autosave (default on).

## Constraints

Lua 5.1, 200 locals per chunk. No protected calls in combat; pending apply after regen. `@cursor` only on real ACTIONBUTTON 1–12. Unmodified wheel is camera unless BIND claimed it. No WTF writes. No SetActionUIButton. No Cooldown metatable wrap; no CooldownFrame_Set. No second visible damage bar. Junction AddOns\SuperBinds → this folder; do not touch the ShamanBinds junction. Disable Shaman Binds on the Druid character so slots are not double-owned.

**Druid Assistant** in AddOns is a temporary sidecar. SuperBinds must **not** skip apply because it exists. SuperBinds is the product. Do not depend on Druid Assistant.

## Fill these

`SuperBinds.lua`, `SuperBinds.toc`, `Profiles/Druid/Guardian.lua` (default), `Profiles/Druid/Balance.lua` (keep editing). TOC: engine then those profiles. Theme may use existing SuperBinds/Media endcaps. `sculptures={}` on both Druid packs.

Balance = level-11 starter, tiny Known() list, manual forms, `useBlizzardSBA=false`.
Guardian = live tank pack, form bars + stay-in-form rotation as above, `useBlizzardSBA=false` (bear uses in-form list that matches SimC/Icy Veins; Blizzard highlight on native ACTIONBUTTONS is enough in bear if those spells are PlaceID’d there).

## Done when

1. Engine grep has no class/spec spell names. Form identifiers are keys from the loaded profile.
2. Profile files grep **do** contain layout + rotation.
3. You return **complete files**, not diffs, for `C:\Users\Nick\Documents\Websites\SuperBinds\`.
4. `/reload` prints SuperBinds version. `/superbinds load Guardian` out of combat, dismounted: brass console, **spells** on native form slots, drawers/BIND/shimmer, Blizzard bar 1 hidden, macro book not flooded.
5. `/superbinds save` and `/superbinds reset` work (console stays ours).
6. A third profile file in the TOC would not need engine edits.
7. Shimmer never prefers a shapeshift. Off-form never follows SBA into another form.
8. Follow `docs/SUPERBINDS-BRIEF.md` + `docs/PROFILE-SCHEMA.md`. Ignore shipping shaman packs for v1.
9. Move an ability between two bar faces: keys/labels stay on those slots, spells swap. Rebind Action Button N in WoW: our matching face label and press both follow that key. Form swap does not invent a new hotkey for slot 1.

Voice: small comments that say why. Match Shaman Binds lua density.

---

## Attach these (paperclip)

From `C:\Users\Nick\Documents\Websites\SuperBinds\`:

1. `docs\SUPERBINDS-BRIEF.md`
2. `docs\PROFILE-SCHEMA.md`
3. `_reference\ShamanBinds.lua`
4. `_reference\ShamanBinds.toc`
5. `SuperBinds.lua`  ← failed rewrite; do not extend its apply/macro kernel
6. `SuperBinds.toc`
7. `Profiles\Druid\Balance.lua`
8. `docs\TOTEM-ART.md`  ← renderer only; Druid packs use sculptures = {}
9. This file (`ASTRA-PROMPT.md`)

Do **not** attach Media `.tga`, `Profiles\Shaman_*.lua`, the ShamanBinds repo, `assets\`, `restore\`, screenshots, or DruidAssistant.
