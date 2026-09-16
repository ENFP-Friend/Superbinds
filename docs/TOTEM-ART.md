# Shaman Binds — Totem crown art

Product overview (what the addon does, profiles, console, commands): [`README.md`](README.md).

Read this before recreating, recoloring, resizing, or adding a totem crown. This is the art bible for the four ready-state images that sit above the console.

Live addon (after install):

`World of Warcraft\_retail_\Interface\AddOns\ShamanBinds\`

Source art in this repo: [`assets/`](assets/).

This file is the art bible. Keep it in sync with `assets/TOTEM-ART.md` if you edit either.

---

## What these are

These are **WoW shaman totem poles** used as UI ornaments. Only the distinctive **crown** (the head) shows above the brass console; the shaft is tucked under the plate.

They are **not**:

- cups, goblets, chalices, or bowls
- demonic face stacks
- random new sculptures when an original already exists
- full-length poles standing on a ground plane
- spell icons in a square with a border
- Blizzard stock lightning-blue runes on every totem

If an original pole exists, **recolor / refit that original**. Do not generate a new body.

---

## Current set (order on the bar)

| Slot | Spell | Live TGA | Primary colour | Runes | Notes |
|---|---|---|---|---|---|
| 1 | Wind Rush Totem | `Media\TotemWindRush.tga` | **White air** (hint of cool teal OK, not grey) | White / ivory | Soft wispy magic. Never a hard disc. |
| 2 | Capacitor Totem | `Media\TotemCapacitor.tga` | **Cyan-blue lightning** | Cyan-blue | Match the official spell icon (gold spear-cap, lightning orb). |
| 3 | Earthgrab / Earthbind | `Media\TotemEarthgrab.tga` | **Green** | Green | **Size reference.** Keep the T-wings. `behind = true`. |
| 4 | Thorn Bloom | `Media\TotemThornBloom.tga` | **Gold core, green claws** | Gold | Spell-icon V-burst on a short pole. `behind = true`. |

Lua table: `P.TOTEM_READY` in `ShamanBinds.lua`. Paths are `Interface\AddOns\ShamanBinds\Media\<Name>` with **no extension**.

---

## Colour language (user-set, do not invent)

Each totem has **one primary colour**. **Runes always use that colour**, never stock lightning-blue.

- **Wind Rush** = white air. Subtle cool teal/blue in the mist is OK. Not greyscale, not electric blue.
- **Thorn Bloom** = gold core / runes, olive-green thorn claws (official spell icon). Not a purple lotus.
- **Earthgrab** = green. Moss / nature green on the runes. Stone stays stone.
- **Capacitor** = cyan-blue lightning, gold metal cap. This one *is* allowed to look like the spell icon.

Recolor by **luminance tint + a soft mask**. Do **not** posterize with hard HSV hue snaps — that made Thorn Bloom look dithered/speckled.

---

## Size (Earthgrab is perfect — match it)

On-screen frame: `P.TOTEM_SIZE = 192`, `P.TOTEM_TUCK = 96` (bottom half sits under the plate).

Texture canvas: **256×256 PNG/TGA**, transparent background.

Earthgrab’s painted box is the scale all others must match:

- Max painted size **228×179** inside 256
- **14px** side/bottom pad
- Bottom-aligned: paste at `((256 - nw) // 2, 256 - 14 - nh)`
- Earthgrab crown bbox is about `(14, 63, 242, 242)` — painted height ~179/256 of the frame

**Do not shrink Earthgrab** to match a larger sibling. Shrink the sibling.

Wind Rush and Thorn Bloom used to fill the whole 256 square, so they looked huge next to Earthgrab. They were refit to the same 179px painted height. Capacitor is closer to full-height; do not change it unless asked.

WoW TGA is **not mipmapped**. Drawing a 512 (or 1024) texture scaled down on a 192 frame looks crunchy. Feed art that is already near on-screen size. After fitting, always `P.SmoothUITexture` (`SetSnapToPixelGrid(false)`, `SetTexelSnappingStyle("Unsnapped")`).

---

## Source-of-truth files (do not overwrite)

Keep these originals. Process into `_crown.png` + live TGA.

| Totem | Keep forever | Why |
|---|---|---|
| Wind Rush | `TotemWindRush_ui.png` | Original carved stone head, feathers, leather, teal swirl. The sculpture to preserve. |
| Thorn Bloom | `TotemThornBloom_ui.png` | Original lotus (retired). Live sculpture is `TotemThornBloom_riseC_furnace.png`. |
| Earthgrab | `TotemEarthgrab.png` | 1024, white background, **complete T-wings**. Early UI crops clipped the wings — never do that again. |
| Capacitor | `TotemCapacitor_icon_src.png` | Official-icon look. Magenta-keyed export. |

Throwaway / rejected (do **not** revive as the live crown):

- `TotemWindRush_cup.png` — cup/goblet
- `TotemWindRush_pole.png`, `TotemWindRush_pole_src.png`, `TotemWindRush_white_src.png` — wrong sculpture (full column / new pole)
- Hue-snapped posterized intermediates

Useful working copies (OK to replace when redoing that totem):

- `TotemWindRush_soft.png` — last generated wispy-white Wind Rush (magenta bg)
- `*_crown.png` — 256 preview of what is in the live TGA
- `TotemCrownsMock-v3.png` — bar mock with four crowns (Wind Rush still teal in the mock)

---

## Per-totem notes

### Wind Rush

- Body: C-shaped dark basalt head, bronze fittings, leather wrap, hanging feathers. Same pose as `_ui.png`.
- Magic: rushing **white** air, volumetric, **soft feathered edges**. Inner core can be denser/brighter. Outer tendrils dissolve. **Not** a solid filled disc, **not** a cookie-cutter circle, **not** a hole in the swirl (an earlier fix filled the core opaque and made the edge harsh).
- Rune on the wrap: white/ivory, not lightning-blue.
- Last good generation: `TotemWindRush_soft.png` then keyed + fitted.

### Capacitor

- Gold spear-cap, cyan-blue cracked orb, lightning, blue runes.
- Match the **official spell icon**, not a generic stone pole.

### Earthgrab

- Mossy stone, vines, **wide T-wings**. User said this size is **perfect**.
- First UI crop cut the wings. Refit: key white, keep top ~62% (wings + head), fit 228×179 into 256 with 14px pad, green rune tint.
- `behind = true` (frame level 6 so Wind Rush / Capacitor sit in front).

### Thorn Bloom

- Official-icon bloom: olive succulent claws bursting **up and out** in a V, gold-orange core, short stone stump with a gold rune.
- Live source: `TotemThornBloom_riseC_furnace.png`. Keep `_ui.png` as the old lotus.
- Fitted to the Earthgrab painted box (same 179px height).

---

## How to redo or add one

1. **Read the original** listed above. Look at `TotemEarthgrab_crown.png` for scale.
2. If the pole already exists, **do not GenerateImage a new body**. Recolor/refit, or generate **only** the magic/glow while forcing the same sculpture in the prompt and using the original as `reference_image_paths`.
3. If you must generate: transparent or **magenta** background (generated magenta is often `~(214, 0, 134)`, not pure `#FF00FF`). Three-quarter view, no ground, no text, no UI chrome. Prompt must say: shaman totem pole, not a cup, not demonic faces, keep this exact sculpture.
4. Key the background (flood from edges; despill magenta/white halos). Do not eat interior glow holes that are part of the art, except Wind Rush’s swirl core which must not be a transparent hole.
5. Recolor with luma tint + soft mask. Runes = that totem’s colour.
6. Trim alpha, scale to fit **228×179**, paste into 256 with 14px bottom pad, centered X.
7. Save `assets\<Name>_crown.png` (and the working PNG). **Write TGA** to `ShamanBinds\Media\<Name>.tga`.
8. If it is a **new** totem, add a `P.TOTEM_READY` row, bump `placeVer` if frames change, bump addon version in `.toc` + load print, then tell the user to `/reload`.
9. Do not commit or write WTF/`bindings-cache.wtf` unless asked. Do not `/load mine`.

### GenerateImage prompt skeleton

```
Isolated World of Warcraft shaman <Spell> Totem crown. Keep the EXACT carved
stone sculpture from the reference: <describe the original>. Not a cup, not a
goblet, not a full-length column on a ground plane, not demonic faces.

Primary colour: <colour>. Runes in that same colour, never stock lightning-blue.

<Magic / bloom / lightning notes, including edge quality.>

Solid magenta #FF00FF background. No ground, no text, no UI frame.
```

Always pass the original `_ui.png` / source PNG as the reference image.

---

## TGA export (required)

Uncompressed 32-bit BGRA, origin **bottom-left**. WoW will not show PNG from `SetTexture` on these paths.

```python
def write_tga(path, im):
    im = im.convert("RGBA")
    w, h = im.size
    pixels = im.tobytes()
    header = bytearray(18)
    header[2] = 2
    header[12] = w & 0xFF
    header[13] = (w >> 8) & 0xFF
    header[14] = h & 0xFF
    header[15] = (h >> 8) & 0xFF
    header[16] = 32
    header[17] = 8
    out = bytearray()
    for y in range(h - 1, -1, -1):
        row = y * w * 4
        for x in range(w):
            i = row + x * 4
            out.extend((pixels[i + 2], pixels[i + 1], pixels[i], pixels[i + 3]))
    with open(path, "wb") as f:
        f.write(header)
        f.write(out)
```

Live files are 256×256 → 262162 bytes. After a texture-only change, `/reload` is enough. If you add textures or change frame construction, bump `placeVer` (currently **6**) so `EnsureTotemReady` rebuilds.

---

## Fit-to-Earthgrab snippet

```python
SIZE, MAX_W, MAX_H, PAD = 256, 228, 179, 14

def fit(im):
    a = im.split()[3].point(lambda v: 255 if v > 16 else 0)
    im = im.crop(a.getbbox())
    scale = min(MAX_W / im.width, MAX_H / im.height)
    nw, nh = max(1, int(im.width * scale)), max(1, int(im.height * scale))
    im = im.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(im, ((SIZE - nw) // 2, SIZE - PAD - nh), im)
    return canvas
```

---

## How they behave in the addon (so art and code stay aligned)

- Parent: **UIParent**, strata HIGH. Earthgrab / Thorn Bloom frame level **6**, Wind Rush / Capacitor **12**, still under the console (HIGH **50**).
- Drag is manual (`P.BeginTotemDrag` / `P.TotemDragOnUpdate`). **Do not** `StartMoving` or `CopyToClipboard`. Drop saves `ShamanBindsDB.totemPos[i] = {x=, y=}` silently. Included in profile snapshot/load.
- Hide all crowns when the console is hidden (mount). Combat: `EnableMouse` off.
- **Cooldown fill (7.48+):** crowns stay visible on CD. Grey desaturated stone underneath; full-colour art **fills upward from the brass lip** like a meter. Do not hide the totem for the whole CD anymore. In combat, Midnight secrets CD numbers — fill is armed from the cast (`MarkTotemUsed`) using public duration or `GetSpellBaseCooldown`. GCD (~1.5s) is **not** a totem CD; ignore it when a real totem timer is running.
- Do **not** wrap `Cooldown:SetCooldown` on the metatable. Do not parent movable totem frames to the secure console. Mixed templates omit `:SetFrameRef` — use `SecureHandlerSetFrameRef` if you touch secure frames.

Wheel binds (context only; do not reshuffle unless asked): Shift-Up Wind Rush, Shift-Down Capacitor, Ctrl-Up Earthgrab/Earthbind, Ctrl-Down Thorn Bloom.

---

## Version / reload

After lua or art changes: tell the user to `/reload`. If binds changed, `/shamanbinds` or `/shamanbinds load Farseer`. Load chat should show the new version (`## Version` in the `.toc` and the load `print`).

Do not `/load mine`. Do not commit or push unless asked. Do not write `WTF` or `bindings-cache.wtf` while WoW is running.
