Paste this entire prompt into a new high-capability GPT coding agent. Attach the files listed at the bottom. Work only in `C:\Users\Nick\Documents\Websites\SuperBinds`.

---

# SuperBinds — clean port (not a rewrite)

You are finishing my WoW **Midnight** addon **SuperBinds**.

The previous agents **failed**. They wrote a new ~1,800-line engine from the brief instead of porting the working Shaman Binds machine. That rewrite:

- minted a unique saved macro (`SuB1`…`SuB120`) for almost every console face, then hit the 120-macro cap
- invented identity / overlay / `skipPlace` apply logic that aborted with “invalid or duplicate action slots”
- hid the SuperBinds console on `/reset` and showed Blizzard’s default bar
- never copied `PlaceID`, `ArmModifiedCast`, hidden slots 8–12, `KEEP`, or Quick Keybind

**You will not continue that rewrite.** You will **port the engine** from attached `_reference/ShamanBinds.lua` (live 8.34) and **move class content into profile files**. Current `SuperBinds.lua` is a negative example. Keep `Profiles/Druid/Balance.lua` as pack data to adapt, not as proof the engine is fine.

Shaman Binds on disk at `C:\Users\Nick\Documents\Websites\ShamanBinds` is the **live GUI I still play**. Do not edit it. Do not TOC-load `_reference/ShamanBinds.lua`. Do not commit or push unless I ask.

## What SuperBinds is

New addon folder. Same player-facing console as Shaman Binds. Class-agnostic engine. First playable pack is **Balance Druid**, not Shaman.

- **Class** = `DRUID` (folder `Profiles/Druid/`, field `class = "DRUID"`).
- **Profile** = `Balance` (file `Profiles/Druid/Balance.lua`, field `name = "Balance"`).
- Load: `/superbinds load Balance` (also `/sbinds`). Out of combat, dismounted.
- Later packs (`Profiles/Druid/Feral.lua`, `Profiles/Shaman/Prime.lua`) must not require engine edits.

**Engine = how buttons, binds, and chrome work. Profile = which abilities, keys, sculptures, labels, forms, and rotation a class uses.**

If the engine needs a spell name, form name, “Balance”, “Druid”, “Farseer”, or a totem TGA path to compile, it is in the wrong file.

## Method (mandatory)

1. **Copy** `_reference/ShamanBinds.lua` to `SuperBinds.lua` as the starting file. Do not start from the current SuperBinds.lua kernel.
2. Rename the addon surface: `ShamanBinds` → `SuperBinds`, `ShamanBindsDB` → `SuperBindsDB`, `/shamanbinds` → `/superbinds` (keep `/sbinds` and `/keymap`). User-facing print strings say Super Binds.
3. **Keep these subsystems almost verbatim** (de-shamanize names/data only):
   - Console, tabs, hover drawers, BIND, BIND gold lip, `::` grip, drop rail `+`, displace-on-drop
   - `PlaceID` / `PickupID` (spells go on native slots; this is the default)
   - `EnsureMacro` / `PlaceMacro` / `PruneOrphan*Macros` (named macros only when needed)
   - `NeedsBlizzardSlot` **genericized**: `@cursor` in body, `target=="cursor"`, or profile flag — **not** a totem/Thorn Bloom name list
   - `AllocHiddenSlot` / helper ACTIONBUTTON 8–12 for mouse extras that cannot use `CLICK`
   - `KEEP`, `ClearSlot`, bar-1 placement pass in apply
   - `SetMenuButton`, `SetupClickButton`, `ArmModifiedCast` (Shift/Ctrl/Alt on the same face)
   - `BindKeyTo` / `ApplyClickBind` / mouse keys → `MACRO` or `ACTIONBUTTON`, never `CLICK` for mouse buttons (8.33)
   - Cooldown swipe + countdown on **tabs and drawer rows**
   - Assisted highlight: `ActionBarButtonAssistedCombatHighlightTemplate`, paint-only, **no `SetActionUIButton`**, Play-then-Stop once to crop atlas, loop in combat only
   - Hide bar 1 without eating Character / Progression Menu clicks (comments 7.80–8.00)
   - Mount / vehicle yields to MainActionBar; Extra Action stays
   - Enter / `/` stay chat; Numpad 8/9 unbound for ReShade
   - Profile save/load **mechanism**; `Before <name>` snapshot on load
   - Sculpture **renderer** (fill, mask, drag, uv) if `profile.sculptures` is non-empty; skip rack if `{}`
   - Theme **application**; values and Media paths come from the profile
   - Lua 200 file-chunk locals: helpers on `P` / nested `do`, not 200 locals at file scope
   - Midnight secrets: never compare secret values; `SetCooldown` without comparing; `GetCursorInfo` may secret an id while type is still `"spell"`
4. **Move into profile data** (do not leave in the engine):
   - `BuildPrimeFamilies` / Farseer / Pocket / purpose families
   - `MOUSE_HARDWARE`, `HARDWARE_LABEL`, `BAR_BINDS`
   - `P.SPELL_ID`, talent spend lists, `STATIC_EXCLUDE`, Hex never-bind
   - Sculpture list + TGA paths
   - Theme colours and endcap paths
   - Any `familyMode == "farseer"` branches — those are just different profiles
5. **Then** add only the extra engine features listed below (form bars, Balance shimmer source, save/reset). Do not add a second placement system.

TOC: `SuperBinds.lua` then `Profiles/Druid/Balance.lua` only for v1. Do not load `_reference`. SavedVariables: `SuperBindsDB`. Interface: match `_reference/ShamanBinds.toc` (Midnight).

Media already in `SuperBinds/Media/` (endcap TGAs). Balance theme may point at those. Balance ships `sculptures = {}` — no Druid totem crowns.

## Forbidden (this is how the last port died)

- Do **not** CreateMacro per console face / per form identity.
- Do **not** `PickupMacro`+`PlaceAction` for ordinary spells. Use `PlaceID` / `C_Spell.PickupSpell`.
- Do **not** invent `SuB1` infinite names. Reuse a small registry of named macros (`SB_` / `SuB_` + stable short key), prune orphans, try character then account macros, `pcall(CreateMacro)`.
- Do **not** abort apply on “duplicate action slots” by packing display primaries and per-form bar rows onto the same slot. Display faces that share a native slot are `type="action"` on that slot, not a second placement.
- Do **not** hide the SuperBinds console and fade-in Blizzard bar 1 on reset.
- Do **not** write `WTF` / `bindings-cache.wtf`. Use `SetBinding` + `SaveBindings(GetCurrentBindingSet())`.
- Do **not** `SetActionUIButton`.
- Do **not** wrap `Cooldown:SetCooldown` or use `CooldownFrame_Set`.
- Do **not** fight Bartender/Dominos.
- Do **not** simplify away BIND, drop-rail, shimmer, or drawers.
- Do **not** put Wrath / Moonfire / Cat Form / Wind Shear in the engine.
- Do **not** ship playable Prime/Farseer/Pocket in v1. Empty stubs are optional; Balance is the pack.

## Placement rules (copy these, do not reinterpret)

Default for a family `bar` / `bars` face with `spell={...}`: resolve `Known()`, **PlaceID onto the slot**, console tab `SetAttribute("type","action")` + `action=slot` (or `type="spell"` for click-only faces with no slot).

Use a **saved named macro** only when:

- body contains `@cursor` / `target=="cursor"` (Midnight: addon SecureActionButtons cannot fire these; they must sit on ACTIONBUTTON 1–12)
- the profile supplies `macro={short,icon,body}` or `macrotext` that must live on a slot
- a **mouse** bind cannot use `CLICK` and needs MACRO/ACTIONBUTTON (8.33)

Help/harm mouseover for **clicking the console** may use `macrotext` on the secure button. Do not fill the account macro book for that.

Drawer rows without slots: `type="spell"` / `type="item"` / inline `macrotext`. Keys on those rows are CLICK (keyboard) or SPELL/ITEM/MACRO (mouse).

## Extra engine features (after the kernel exists)

These are generic. No `if druid`.

### Stance / form bars

Packs that shapeshift declare `actionBars`:

```lua
actionBars = {
  caster = { page = 1 },
  cat    = { bonus = 1 },  -- GetBonusBarOffset while in that form
  bear   = { bonus = 3 },
  travel = { page = 1, use = "caster" }, -- share another form's slots
}
```

Relative `slot=1` is ACTIONBUTTON1; WoW swaps the underlying absolute slots. Keys stay 1–12. Secure page driver: `[bonusbar:N]`. Out of combat, apply **PlaceID** onto each form’s absolute slots (caster 1–12, cat ~73–84, bear ~97–108 — use the API, do not hardcode class).

Family faces per form: `bars = { caster={slot=1,spell=...}, cat={...} }`. Shapeshifts that must exist on every bar: `allBars=true` on the same relative slot.

### Form kit (BIND “See All” / form abilities)

`profile.formAbilities[form] = { ids and names }`. That list is “kit of this form”, not “anything the client will let you press.” Shapeshifts and off-form dumps (Starfire in bear) stay out. Unknown IDs hide via `Known()`.

### Next-cast shimmer

If `profile.useBlizzardSBA == true`, generic Blizzard assistant path is allowed (`sba=true` faces, `GetNextCastSpell(false)`).

**Balance sets `useBlizzardSBA=false`.** Shimmer comes from `profile.rotation[currentForm]`, filtered by the form you are **already in**. Never recommend a shapeshift as next-cast. `neverSuggest` is a hard exclude. `form="caster"` when shapeshift index is 0. Map forms via `profile.forms = { cat={spells={768}}, ... }` and `GetShapeshiftFormInfo` — **do not hardcode form index 1 = cat in the engine**. Unknown form → no suggestion (do not fall back to caster). Secret combat data: skip rules you cannot prove; optional `fallback=true` filler from the pack.

### Commands

`/superbinds` apply + keymap  
`load <name>`  
`save [name]` — overlay (binds, custom faces, positions) + base pack. No name → `Current`. Do not overwrite shipped profile tables.  
`load <saved name>` restores that overlay onto its base pack.  
`reset` — **keep the SuperBinds console**. Empty native slots this addon owns (and leftover junk on those bars), restore **pack default keys** (clear overlay binds/custom), PlaceID the pack again, hide Blizzard bar 1 as usual. Snapshot `Before reset` first. **Do not** `LoadBindings(DEFAULT_BINDINGS)` in a way that dumps our console and shows the default bar. Game `/reset` is instance reset; ours is `/superbinds reset` only.  
`list` / `delete <name>` / `default` (profile with `default=true` for this class)  
`bind` / `map` / `options` / `hide` / `show`

Autosave overlay positions/settings when options checkbox `autosave` is on (default on).

Console, keymap, and BIND workshop panels are movable; persist positions in the overlay.

## Balance pack (level 11) — first profile to ship

I am a **level 11 Balance Druid**. Attached `Profiles/Druid/Balance.lua` is the pack I will keep editing. Use it. Do not invent an endgame APL. `Known()` hides unlearned spells. Forms are **manual** keys, never shimmer candidates.

Intended keys (if learned):

- E Wrath / Shred / Mangle by form (native slot 1)
- Q Roots / Prowl / Growl by form (slot 2)
- C Bear Form, X Travel Form, M4 Cat Form (`allBars`)
- M5 Regrowth / Dash / Frenzied Regeneration (slot 8); Shift-M5 Rejuvenation (slot 9)
- Shift-E Moonfire, Ctrl-E Starsurge (caster drawer); F/Rake/Maul/FB by form
- Buffs / Recover click-only
- Plain wheel + Ctrl-wheel = camera unless BIND claimed plain wheel. Ctrl-wheel reserved.

`useBlizzardSBA=false`. `sculptures={}`. Theme may use existing SuperBinds Media endcaps.

## Constraints (do not abandon)

- Lua 5.1, 200 locals per chunk
- Combat lockdown: no protected calls in combat; pending apply after regen
- `@cursor` only on real ACTIONBUTTON 1–12
- Unmodified wheel is camera unless BIND claimed it
- No second visible damage bar; no OPie
- Do not `/load mine`
- Junction: `AddOns\SuperBinds` → this folder. **Do not replace** the ShamanBinds junction
- Disable Shaman Binds on the Balance character so `/sbinds` and slots are not double-owned

## Done when

1. Engine grep has **no** class/spec spell names (no Wrath, Moonfire, Cat Form, Wind Shear, Ghost Wolf, …). Form **identifiers** in generic code are keys from the loaded profile (`caster`, or whatever the pack named), not hardcoded Druid.
2. `Profiles/Druid/Balance.lua` grep **does** contain the layout and rotation.
3. You return **complete files** for the SuperBinds folder (not a sketch, not “apply this diff only” unless a file is truly unchanged).
4. `/reload` prints a SuperBinds version. `/superbinds load Balance` out of combat, dismounted, builds the brass console, places **spells** on native slots, drawers/BIND/shimmer work, Blizzard bar 1 stays hidden.
5. `/superbinds save` and `/superbinds reset` work as specified (console stays ours on reset).
6. A second profile file in the TOC would not need engine edits.
7. Macro book is not flooded; only the few named macros the kernel actually needs.
8. Follow table shape in `docs/SUPERBINDS-BRIEF.md` and stance-bar notes in `docs/PROFILE-SCHEMA.md`. Ignore shipping shaman packs. **Balance is the first pack.**

Voice: small comments that say why, not essays. Match Shaman Binds lua density.

Out of scope: git push, renaming ShamanBinds, Bartender wars, workshop PNGs, making Druid “done”, talent-auto-spend.

---

## Attach these (paperclip)

From `C:\Users\Nick\Documents\Websites\SuperBinds\`:

1. `docs/SUPERBINDS-BRIEF.md`
2. `docs/PROFILE-SCHEMA.md`
3. `_reference/ShamanBinds.lua`
4. `_reference/ShamanBinds.toc`
5. `SuperBinds.lua` ← failed rewrite; do not extend its apply/macro kernel
6. `SuperBinds.toc`
7. `Profiles/Druid/Balance.lua` ← keep as pack data
8. `docs/TOTEM-ART.md` ← renderer only; Balance uses `sculptures={}`
9. This prompt file if you saved it (`GPT-PROMPT.md`)

Do **not** attach Media `.tga`, `Profiles/Shaman_*.lua`, the ShamanBinds repo, `assets/`, or screenshots.

Return complete `SuperBinds.lua`, `SuperBinds.toc`, and `Profiles/Druid/Balance.lua`.
