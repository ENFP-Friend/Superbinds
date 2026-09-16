# SuperBinds — Astra brief

Copy this file to Astra with the current `ShamanBinds.lua` / `.toc` / `Media\` / `docs\`. Source of truth for behaviour is the live Shaman Binds addon, not a rewrite from memory.

## What we are doing

Ship a **new addon folder `SuperBinds`**. Same player-facing console as Shaman Binds: brass bar, family tabs, hover drawers, BIND, drag/drop, cooldown swipe + countdown numbers, assisted-combat **blue shimmer**, hide Blizzard bar 1, mount bar swap, profiles.

**Hard rule: the engine has no class-specific content.** No shaman spells, no Druid spells, no Wind Shear, no totem names, no Farseer, no Hex, no `P.SPELL_ID` tables of class spells, no `STATIC_EXCLUDE` of rotation buttons, no `BuildPrimeFamilies` / `BuildFarseerFamilies` in the engine. All of that lives in **profile data**.

Shaman Binds today is the reference implementation and the first profile pack. SuperBinds must load a Shaman profile and look/behave like Shaman Binds. A later Druid profile is only data.

Do **not** edit ShamanBinds in place to “become” SuperBinds. New addon. Optional: import `ShamanBindsDB` once if present.

---

## Product (must all survive)

These are engine features, not shaman features:

- Compact console: tabs, `::` grip, BIND key + gold lip, faction-agnostic endcaps driven by **profile theme**
- Hover one family drawer; BIND opens all drawers in a wrapping grid
- Secure clicks in combat; modifier chords; Alt self-cast where the profile asks
- Shift-drag pickup, Ctrl-drag / lip / `::` move console, BIND lip moves BIND only
- Drop rail `+` adds; drop on a face/row displaces the old ability into the family
- Cooldown swipe + countdown on **tabs and drawer helpers** (not on sculpture meters)
- Assisted-combat blue shimmer (`ActionBarButtonAssistedCombatHighlightTemplate`), paint-only, **do not** `SetActionUIButton`. `GetNextCastSpell(false)`. Glow matching visible icons; SBA / Attack tab glows when next-cast is hidden via `hideAutoManaged`. Loop flipbook in combat only; Play-then-Stop once on create to crop the atlas
- Profiles: save / load / list / delete. Loading a stock layout snapshots `Before …` first
- Settings: `/superbinds options` (hide bar 1, hide auto-managed, mount bar, warn binds, apply, keymap, BIND)
- Field guide `/keymap`
- Hide extra Blizzard bars except flying/mount and Extra Action
- Enter / `/` stay chat. Numpad 8/9 left for ReShade
- Lua 200-local file limit: helpers on `P` / nested `do` blocks, not 200 file-chunk locals
- Midnight secrets: never compare secret values; pass cooldown start/duration into `SetCooldown` without comparing; `GetCursorInfo` may secret a spell id while type is still `"spell"`

---

## The rule, in one sentence

**Engine = how buttons, binds, and chrome work. Profile = which abilities, keys, sculptures, and labels a class uses.**

If you need a class name, a spell name, a totem TGA, or “Enhancement vs Farseer” to compile the engine, it is in the wrong place.

---

## Profile data (this is the class pack)

A profile is a named table (shipped defaults + player `SuperBindsDB.profiles`). Minimum fields:

```lua
{
  name = "Prime",                 -- UI name
  class = "SHAMAN",               -- optional filter; engine still must not hardcode spells
  familyMode = "prime",           -- id only; meaning comes from this table
  families = {                    -- console strip, left to right
    {
      tag = "E",                  -- short id
      title = "Attack · E",       -- drawer header
      caption = "ATTACK",         -- tab label under the icon
      bar = {                     -- primary face (optional)
        slot = 3,                 -- Blizzard action slot 1-12, or nil
        key = "E", bindKey = "E",
        sba = true,               -- Assisted Rotation face
        label = "Assisted Rotation",
        -- xor: spell={ "Name" }, macro={ short, icon, body }, covers={...}
      },
      items = {                   -- drawer rows
        -- bindKey / key optional (nil = click-only)
        -- spell / macrotext / itemID / sba
        -- target = "harm"|"help"|"cursor"|"plain"  (engine builds [@cursor] etc.)
        -- covers, requires, note, iconFile, savedMacroName
      },
    },
    -- ...
  },
  hardware = {                    -- mouse / wheel chords this profile owns
    -- ["SHIFT-MOUSEWHEELUP"] = { slot = 5, macro = "RushTotem" },
    -- omit keys the engine must leave as camera (see reserved)
  },
  reserved = {                    -- BIND must not steal these
    ["CTRL-MOUSEWHEELUP"] = "camera zoom in",
    ["CTRL-MOUSEWHEELDOWN"] = "camera zoom out",
    ["CTRL-BUTTON4"] = "camera zoom in",
    ["CTRL-BUTTON5"] = "camera zoom out",
    NUMPADPLUS = "camera zoom in",
    NUMPADMINUS = "camera zoom out",
  },
  camera = {                      -- RestoreCameraWheel
    MOUSEWHEELUP = "CAMERAZOOMIN",
    MOUSEWHEELDOWN = "CAMERAZOOMOUT",
    ["CTRL-MOUSEWHEELUP"] = "CAMERAZOOMIN",
    ["CTRL-MOUSEWHEELDOWN"] = "CAMERAZOOMOUT",
    NUMPADPLUS = "CAMERAZOOMIN",
    NUMPADMINUS = "CAMERAZOOMOUT",
  },
  exclude = {                     -- hideAutoManaged leftovers (rotation buttons)
    -- ["Stormstrike"] = true,
  },
  neverBind = { "Hex" },          -- names the applier must not bind
  sculptures = {                  -- optional; empty = no crowns (Druid later)
    -- { names={...}, file=..., behind=, size=, tuck=, uv=, fillTop=, glow=, extra= }
  },
  theme = {                       -- endcaps, chrome; paths under SuperBinds/Media
    -- copy P.ClassThemes.SHAMAN shape; Horde variants optional
  },
  macros = {                      -- named helper macros the hardware table refers to
    -- RushTotem = { icon=, body= },
  },
  barBinds = {                    -- default keyboard → ACTIONBUTTONN
    -- ["Q"] = "ACTIONBUTTON1",
  },
}
```

Shipped later: Shaman packs can be transcribed from `BuildPrimeFamilies` etc. **First pack to build is Druid.** Use the shaman builders only as the shape of a profile table.

Player edits (custom rows, binds, tab positions, totem positions) stay in `SuperBindsDB` **on top of** the loaded profile, same as today.

`/superbinds load <name>` loads a profile. `/superbinds save <name>` writes the current overlay. `/superbinds default` loads the class’s default profile if the profile table says so (Shaman → Prime), not a hardcoded string in apply logic beyond “profile.default == true”.

---

## Engine may know (generic)

- Family **shape**: tag, bar slot, items, bindKey, covers, click-only
- `sba = true` means Blizzard assisted-rotation face (any class)
- `@cursor` / help / harm macro wrappers from `target`
- Totem-**style sculptures** as a generic “ready meter above the bar” driven by `profile.sculptures` (names + TGA + uv). If sculptures is empty, skip the rack. Do not special-case “Totem” in the engine except `NeedsBlizzardSlot` for `@cursor` / ground macros (string match on macro body / `target=="cursor"`, not a totem name list)
- Mouse keys cannot bind `CLICK` commands — park extras on MACRO / ACTIONBUTTON (see 8.33)
- Reserved camera keys from **profile.reserved**, not a shaman comment
- Trinkets 2/3 as on-use slots 13/14 if the profile includes those faces
- Book scan, Known(), hide unknown spells
- Lua secrets, 200 locals, combat lockdown

## Engine must not know

- Wind Shear, Ghost Wolf, Wind Rush, Capacitor, Earthgrab, Thorn Bloom, Astral Shift, Healing Surge, Farseer, Prime, Pocket, Hex, Rootwalking, Haranir, Enhancement, Elemental
- `P.SPELL_ID` as a shaman dictionary (a profile may include a small id hint table if the book is secret; that table is profile data)
- `P.TALENT80_NAMES` / `/superbinds talents` spending shaman talents — if talents stay, the wanted-name list is profile data; default is **do not port talent spending** unless the profile opts in
- Hardcoded `familyMode == "farseer"` branches (Ctrl-Q Earthquake, Shift-E Thunderstorm). Those are just different profiles
- `P.MACRO_SHORT_BY_LABEL` shaman map — generate from profile.macros / covers
- Addon folder assumptions `Interface\\AddOns\\ShamanBinds\\Media\\...` — use `SuperBinds`

---

## File layout (suggested)

```
SuperBinds/
  SuperBinds.toc          -- SavedVariables: SuperBindsDB
  SuperBinds.lua          -- engine only
  Profiles/
    Shaman_Prime.lua
    Shaman_Farseer.lua
    Shaman_Pocket.lua
  Media/                  -- copy needed TGA from ShamanBinds (endcaps, totems, fill tip)
```

TOC loads engine then profile files. Profile files register with `SuperBinds.RegisterProfile(tbl)`. Engine never `if class == "SHAMAN"`.

Slash: `/superbinds` and `/sbinds`. Keep `/keymap`.

---

## Constraints (do not abandon)

From Shaman Binds — still true:

- No second visible damage bar; no OPie
- Ground / `@cursor` abilities on real Blizzard slots (page 1, ACTIONBUTTON 1–12)
- No `Cooldown:SetCooldown` metatable wrap; no `CooldownFrame_Set`
- No `SetActionUIButton` for assisted highlight
- Helpers on `P` do not count toward 200 file-chunk locals
- Do not write `WTF` / `bindings-cache.wtf`
- Do not `/load mine`
- Ctrl-M4 / Ctrl-M5 and (for the Shaman profile) Ctrl-Wheel stay camera unless **that profile** puts a spell there
- Unmodified wheel stays camera unless BIND claimed it
- Hide bar 1 without eating Character / Progression Menu clicks (see 7.80–8.00 comments in `ShamanBinds.lua`)

Live version of the reference addon is **8.34** (helper drawer cooldown + shimmer; Ctrl-Wheel zoom; BIND mouse keys on click-only extras via named macros).

---

## Port map (where to look in ShamanBinds.lua)

| Engine (keep, de-shamanize) | Profile (move) |
|---|---|
| Console, tabs, menus, BIND, QKB | `BuildPrimeFamilies` / Farseer / Pocket / purpose |
| `SetMenuButton`, cooldown, assisted glow | `MOUSE_HARDWARE`, `HARDWARE_LABEL` |
| Drag/drop, plus rail, displace | `STATIC_EXCLUDE`, Hex never-bind |
| `AssignHoveredBind`, `FireableMouseCommand`, `AbilityMacroCommand` | `P.SPELL_ID`, talent name list |
| Hide bar 1, mount bar, chat keys | `P.TOTEM_READY` entries |
| Profile save/load **mechanism** | Prime/Farseer/Pocket **contents** |
| Sculpture **renderer** (fill, drag, uv) | Sculpture **list** + TGA paths |
| `P.ClassThemes` **application** | Theme **values** + Media paths |
| `FamilySpell` as a generic helper | Calls with shaman names |

---

## Acceptance

On a **druid**, SuperBinds enabled (Shaman Binds can stay disabled on that character):

1. `/reload` prints SuperBinds version. `/superbinds load Druid` (or the profile name) out of combat, dismounted.
2. Console has tabs, drawers, BIND, cooldown swipe on faces **and** drawer rows, blue shimmer on next-cast / SBA tab.
3. Engine grep has **no** class spell names.
4. Adding a second profile file does not require engine edits.

Shaman Prime/Farseer/Pocket are **not** required for v1. The attached `ShamanBinds.lua` is the engine reference only.

Do not invent Druid totem crowns. Do not drop BIND, drop-rail, or shimmer to “simplify.”

---

## Out of scope

- Pushing to GitHub
- Renaming the existing ShamanBinds repo
- Bartender/Dominos wars
- Writing WTF
- Porting workshop `assets/` alt PNGs
- Making Druid “done”

---

## Voice

Match the existing lua: small comments that say why, not essays. Keep user-facing strings on `/superbinds`, not `/shamanbinds`. If a comment needs a shaman example, put it in the profile file.
