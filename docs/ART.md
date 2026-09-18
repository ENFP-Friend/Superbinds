# Console art

Endcaps, chrome, and (optional) ready-meters. Not shaman totem poles — those stay in Shaman Binds. Druid packs ship `sculptures={}`; the engine still has a generic sculpture renderer if a later pack wants crowns.

Product: [`../README.md`](../README.md). Pack theme fields: [`PROFILE-SCHEMA.md`](PROFILE-SCHEMA.md). Live Haranir bar (cat / travel / Horde default): [`SHOTS.md`](SHOTS.md).

Live textures: `Media\*.tga` (what WoW loads). Packed PNG sources: `assets\`. Workshop drafts: ShamanBinds `assets\` (this Cursor workspace) — **not** TOC-loaded.

---

## What an endcap is

A carved bust that books the brass plate. Two copies: left faces right, right is `SetTexCoord` mirrored. Art follows the **animal** (`P.FormEndcap` / shapeshift name), not the bar page. Ground travel shares caster slots (`use="caster"`) and still uses the sable. Skyriding is the same Travel Form (bonus 5) and still uses the sable.

They are **UI ornaments**: walnut + bronze + gold inlay. They are **not**:

- living fur / photoreal animals
- shaman wolves, runes, or totem shafts
- a coloured 3D model pasted on the bar
- a different animal’s sculpture reused as a reference (the head morphs)

Anatomy still has to match the **in-game form**. Haranir bear is a grey-lavender quill-bear (yellow eye, pink inner ear, tusks, quills). Haranir cat is a massive wolverine with quills, not a second bear. Haranir travel is a sable (huge bat/fennec ears, tusks). Horde default is a wind rider (lion + bat wings + scorpion tail + backswept horns).

Always `P.SmoothUITexture` (`SetSnapToPixelGrid(false)`, `SetTexelSnappingStyle("Unsnapped")`). WoW TGA is not mipmapped — draw at on-screen size.

---

## Shipped (this pass)

| Use | Live TGA | On-screen | `leftIn` | Source pick | Status |
|---|---|---|---|---|---|
| Bear | `Media/DruidEndcap_bear.tga` | 80×120 | 26 | Haranir quill-bear, relic wood-bronze, workshop `DruidEndcap_bear_ui_v5_batC.png` | **Live** |
| Cat | `Media/DruidEndcap_cat.tga` | 80×120 | 26 | Haranir wolverine, huge ears, yellow eyes, v6 **B** (`DruidEndcap_cat_ui_v6_B.png`) | **Live** |
| Travel | `Media/DruidEndcap_travel.tga` | 80×120 | 26 | Haranir sable, huge ears, workshop `DruidEndcap_travel_ui_v1_C.png` | **Live** |
| Horde (unshifted) | `Media/DruidEndcap_horde.tga` | 90×120 | 36 | Wind rider, horns, gold-collar bust, `HordeEndcap_wyvern_v4_B.png` | **Live** |
| Alliance (unshifted) | `Media/ShamanEndcap.tga` | 70×120 | 36 | Leftover owl | Live, not replaced |
| Moonkin | — | — | — | Haranir batbear | **Not started** |

Packed copies of the live picks also sit in SuperBinds `assets/DruidEndcap_{bear,cat,travel,horde}.png`.

Form art overrides faction art while shifted. Caster / moonkin / unknown form show owl or wyvern.

`leftIn` 26 was walked in: 36 sat too far into the bar, 10 too far left, 22 then 26.

Theme in each Druid pack:

```lua
endcaps = {
  bear   = { path="Interface\\AddOns\\SuperBinds\\Media\\DruidEndcap_bear.tga",   width=80, height=120, leftIn=26 },
  cat    = { path="Interface\\AddOns\\SuperBinds\\Media\\DruidEndcap_cat.tga",    width=80, height=120, leftIn=26 },
  travel = { path="Interface\\AddOns\\SuperBinds\\Media\\DruidEndcap_travel.tga", width=80, height=120, leftIn=26 },
}
endcap      = "...\\ShamanEndcap.tga"        -- Alliance fallback
endcapHorde = "...\\DruidEndcap_horde.tga"   -- Horde fallback
```

---

## Cat redo (shipped)

Shipped orange v2-B was too lion/bear. v6 from in-game Haranir cat shots; user picked **B**. Live TGA/PNG updated. Workshop `DruidEndcap_cat_ui_v6_{A,C,D}.png` unused. Do not generate from the bear sculpture as a reference.

---

## How to add or replace one

1. Gather in-game / wiki shots of **that form only**. Do not attach a sibling animal.
2. Generate 4 busts. Prompt: ornate Druid **UI endcap**, carved walnut and gold leaf, three-quarter or bust, facing right, transparent or magenta ground. Not shaman, not living fur, not a full body on a landscape.
3. User picks. Crop to the on-screen box (form 80×120, Horde 90×120).
4. Write TGA (below) into `SuperBinds\Media\`. Keep the PNG in `assets\`.
5. Point `theme.endcaps[form]` or `endcapHorde` at the new path. Bump addon version. `/reload`.

Leftover shaman files in `Media\` (`ShamanEndcap_wolf.tga`, `Totem*.tga`, `EarthElemental.tga`) are unused by Druid packs. Do not delete unless asked — they are the engine’s default chrome and the sculpture renderer’s old kit.

---

## TGA export

Uncompressed 32-bit BGRA, origin **bottom-left**, header descriptor **8**. WoW will not `SetTexture` a PNG on these paths.

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

Texture-only change: `/reload`. New files or new `theme` keys: bump `SuperBinds.toc` + load print.

---

## Optional sculpture rack

Same renderer as Shaman totem crowns: grey base + masked colour fill, `profile.sculptures` rows (`names`, `file`, `size`, `tuck`, `behind`, `uv`, `fillTop`). Empty table = no rack. If you add crowns later, they are **class ornaments**, not a hardcoded totem list. Ground / `@cursor` macros still need a real action slot (`NeedsBlizzardSlot`).
