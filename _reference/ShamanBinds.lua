-- Robustness patch: clear modified casts; safe profile preflight; native-slot drops; drag refresh guards.
ShamanBindsDB = type(ShamanBindsDB) == "table" and ShamanBindsDB or {}

local SBA_ID = 1229376

-- v6 "Console" layout.
--   * Main bar (slots 1-7): the vital verbs with visible cooldown state:
--     Interrupt / Heal / Attack / Overflow / Stun / Flee / Defence.
--   * Above it: a thin tab strip. Hovering a tab unfolds a compact drop-down
--     of that family's abilities (modifier keys labelled, the rest click-only).
--     De-hover and it collapses. Secure handlers = works in combat too.
--   * Modifier keys fire invisible secure buttons -- no bars, no slot art.
--
-- Automatic equipment: on-use trinkets follow slots 13/14 as visible main-console buttons.
-- Drag/drop polish: fixed add rail, explicit previews, cancellation and reliable custom rows.
-- 7.45: Earthgrab wings fit inside the square instead of clipping.
-- 7.46: Wind Rush and Thorn Bloom scaled down to Earthgrab's painted size.
-- 7.47: Wind Rush magic has soft wispy edges instead of a hard disc.
-- 7.48: Totem crowns stay visible on cooldown; element colour fills back like a meter.
-- 7.49: Totem cooldown fill clips a locked texture so it does not jitter.
-- 7.50: Fill uses a mask and integer heights so the art cannot crawl or flicker.
-- 7.51: Element glow rides the fill tip as colour climbs.
-- 7.52: Fill-tip glow opacity halved.
-- 7.53: Earth Elemental ready tracker, half size, same fill and drag.
-- 7.54: Wolf endcaps and Earth Elemental TGAs match on-screen size (no downscale).
-- 7.55: Earth Elemental uses the volcanic model; wolves keep native proportions.
-- 7.56: Wolf endcaps restored to 82x116 so they are not pushed into the bar.
-- 7.57: Wolf endcaps use native proportions; they were ~70% too wide.
-- 7.58: Wolf endcaps redrawn for 82x116 so in-game size is 100% with no stretch.
-- 7.59: Wolf endcaps regenerated without the original sculpture's skew.
-- 7.60: Right wolf overlap matches the left so the gap is gone.
-- 7.61: Right wolf draws above the bar.
-- 7.62: Right end of the bar has the same brass gap as the :: grip.
-- 7.63: Farseer owl endcaps. Wolves kept at Media\ShamanEndcap_wolf.tga.
-- 7.64: Horde uses a crimson wyvern endcap; Alliance keeps the owl.
-- 7.65: TOC Interface matches current Midnight so it is not marked out of date.
-- 7.66: Horde endcap is a real wind rider (lion, bat wings, scorpion tail).
-- 7.67: Horde wind rider uses the owl's carved-stone style, crimson runes.
-- 7.68: Horde endcap keeps that style but uses the real wind-rider silhouette.
-- 7.69: Wind rider sits like the owl — only the front two paws show.
-- 7.70: Horde console chrome uses crimson / warm brass; Alliance stays teal.
-- 7.71: Alliance owl eyes glow while Ascendance is ready.
-- 7.72: Eye glow overlay sublevel 7 (CreateTexture only allows -8..7).
-- 7.73: Hover drawers take clicks again (totem grabbers were eating Menu_*).
-- 7.74: Stop fading MainMenuBar so Character / Progression Menu clicks work.
-- 7.75: Faded ActionButton mouse only; keep raising the Midnight Menu after HUD restack.
-- 7.76: Stop touching MicroMenu (that overlay blocked Character Info). Silence faded bar clicks only.
-- 7.78: Revert FX ModelScene click-through; that was a false lead.
-- 7.80: Do not fight Bartender/Dominos for the HUD. That is what made Menu clicks die.
-- 7.81: Stop post-login page/bar pulses; they turned Menu clicks off over time.
-- 7.82: Dead Blizzard Menu plate ate clicks out of combat; combat hid it. Click-through the plate.
-- 7.83: hideBar1 was fading the whole MainActionBar. That plate ate Menu clicks out of combat.
-- 7.84: Never EnableMouse/HookScript the Blizzard Menu. Town pokes taint it; combat is the only clean path.
-- 7.85: Keep GlobalFX/widget ModelScenes click-through; they sit on the Menu and re-arm in town.
-- 7.86: Restore hide-bar-1 as one fade (7.84 stripped the skin). Drop the FX click-through.
-- 7.87: Console BIND key starts Quick Keybind; click again or Esc to finish.
-- 7.88: Drag BIND to move the console; click still starts or finishes Quick Keybind.
-- 7.89: BIND has its own gold lip; drag that to place BIND, not the whole console.
-- 7.90: BIND mode lays drawers in a wrapping grid so they do not stack.
-- 7.96: Restore hide-bar-1, extra-bar hide, and Lua mount overrides. 7.91–7.95
-- delayed or rerouted that chrome to chase Menu clicks and left both bars up.
-- 8.00: Mount bar is MainActionBar. hideBar1 must un-fade it when mounted.
-- 8.01 binding-loop fix: stop UPDATE_BINDINGS feeding itself through Shift-E.
-- 8.01: Talent name list was in the file chunk and blew Lua's register cap.
-- 8.02: BIND / Quick Keybind sees Shift/Ctrl+wheel without stealing camera or totems.
-- 8.03: Wheel is a real BIND key; console labels follow the saved bind.
-- 8.04: Stolen Shift-WheelUp keeps the hovered spell (Thorn Bloom), not Wind Rush.
-- 8.05: Ctrl-M4 / Ctrl-M5 stay camera zoom; Spirit Walk is click on Move.
-- 8.06: BIND and apply warn when a totem chord or camera key is displaced.
-- 8.07: Thorn Bloom is half size; fill window uses that totem's tuck, not the 192 default.
-- 8.08: Thorn Bloom fill uses the painted art box, not empty TGA pad.
-- 8.09: Wind Rush sits on the bar; bottom of the art is inset so it does not clip.
-- 8.10: Wind Rush is quarter size; fill uses the painted art box.
-- 8.11: Wind Rush is 75% scale (down by a quarter), fill still on the painted box.
-- 8.12: Wind Rush downscaled in the TGA; frame matches painted pixels (no square stretch).
-- 8.13: Wind Rush pixels downscaled 25% from the restored unstretched art.
-- 8.14: Wind Rush drag hit covers the small frame (39px inset left no grab).
-- 8.15: Thorn Bloom art is Haranir vines, face-on; fill uses the new painted box.
-- 8.16: Earthgrab timer ends at the T-wings, not the empty pad above them.
-- 8.17: TotemFillCap reads fillTop as a number (P.Number is a predicate).
-- 8.18: Capacitor timer light is inset to the painted pole, not the square frame.
-- 8.19: Thorn Bloom is a carved pole with Earthgrab vines, sized with the others.
-- 8.20: Thorn Bloom height restored; greener succulent claws and vines.
-- 8.21: Thorn Bloom base matches Wind Rush wraps; plump succulent, short cup.
-- 8.22: Thorn Bloom cup shortened; plant and base share the same face-on camera.
-- 8.23: Console icons use Blizzard's cooldown swipe (not the totem sculptures).
-- 8.24: Console icons use Blizzard's assisted-highlight glow (not the totem sculptures).
-- 8.25: Assisted glow crops the flipbook and sits around the brass square.
-- 8.26: Assisted glow loops whenever it is shown, not only in combat.
-- 8.27: Assisted glow loops in combat only (8.26 reverted).
-- 8.28: Spellbook drops add to a family instead of replacing the tab.
-- 8.29: Drop on a slot replaces it and parks the old spell in the family; + adds.
-- 8.30: Stay under Lua's 200-local file limit.
-- 8.31: Boot frame stays in the same scope as its event hooks.
-- 8.32: Ctrl-Wheel is camera zoom; Earthgrab and Thorn Bloom are click on Totems.
-- 8.33: BIND can put a mouse key on click-only totems (macro, not CLICK).
-- 8.34: Drawer helpers get the same cooldown swipe and assisted glow as the tabs.
-- 7.21: Ready wheel-totems pop a small image just above the console.
-- Class skin: generated Shaman wolf endcaps; class-selected palette and neutral fallback.
-- 7.20: Pull wolf endcaps flush with the bar; crop empty TGA padding.
-- 7.19: Console endcaps were drawn upside down and mirrored; rotate them and swap sides.
-- 7.18: On-use trinkets default to 2 and 3 on every profile.
-- 7.17: Settings toggle hides SBA-managed clicks on Attack. On by default.
-- 7.16: Stamp Thunderstorm onto Shift-E as a SPELL bind so apply cannot miss it.
-- 7.15: Farseer Shift-E is Thunderstorm; Earthquake moves to Ctrl-Q.
-- 7.14: Keep quest Extra Action and the flying / mount action bar visible.
-- 7.13: Shift-WheelDown is Capacitor; Ctrl-WheelUp is Earthgrab.
-- 7.12: Farseer keys Thunderstorm (Ctrl-Q) when the talent is known.
-- 7.11: Farseer profile — Elemental layout on Prime faces. Load with /shamanbinds load Farseer.
-- 7.06: Prime is the default layout. Pocket and purpose families stay opt-in.
-- 7.02: Prime profile — accessibility import (M5 heal, C protect, X mount).
-- 7.00: Cleanse/C and Astral Shift/M5 keep icons and hotkeys; Rootwalking
-- sits on a Blizzard slot so Return can fire; Enter applies the prompt.
-- 6.99 added purpose-based families, activated on explicit /shamanbinds.

local KEEP = {}
local PLACED_SPELLS = {}
local drag = { ability = nil, fromTag = nil, bindKey = nil, fromPrimary = false, active = false }
local console, consoleTabs, menus, allMenuButtons, HoldMenus
local busy, finishing = false, false
consoleTabs, menus, allMenuButtons = {}, {}, {}
-- Helpers on P do not count toward Lua's 200-local file limit.
local P = {}
local RefreshLayout, NormalizeAbility
P.pendingRefresh = false
P.regenCombat = false
P.regenCombatKnown = false
P.ctrlHeld, P.shiftHeld, P.altHeld = false, false, false

-- Midnight: InCombatLockdown can stay true or go secret after combat.
-- PLAYER_REGEN_* is the source of truth. Secret/unknown does not lock the UI.
do
  local w = CreateFrame("Frame")
  w:RegisterEvent("PLAYER_REGEN_DISABLED")
  w:RegisterEvent("PLAYER_REGEN_ENABLED")
  w:SetScript("OnEvent", function(_, event)
    P.regenCombat = (event == "PLAYER_REGEN_DISABLED")
    P.regenCombatKnown = true
  end)
end

local function Locked()
  if P.regenCombatKnown then return P.regenCombat end
  if P.regenCombat then return true end
  if type(InCombatLockdown) ~= "function" then return false end
  local ok, value = pcall(InCombatLockdown)
  if not ok or (issecretvalue and issecretvalue(value)) then return false end
  return value and true or false
end

function P.Number(value)
  if issecretvalue and issecretvalue(value) then return false end
  return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function P.PublicNumber(value)
  if issecretvalue and issecretvalue(value) then return nil end
  return P.Number(value) and value or nil
end

function P.SmoothUITexture(tex)
  if not tex then return end
  -- WoW UI snaps texels to the pixel grid. Scaled TGA without mips then
  -- looks crunchy. Unsnap and feed art at the on-screen size instead.
  if tex.SetSnapToPixelGrid then pcall(tex.SetSnapToPixelGrid, tex, false) end
  if tex.SetTexelSnappingStyle then pcall(tex.SetTexelSnappingStyle, tex, "Unsnapped") end
end

function P.Text(value)
  if issecretvalue and issecretvalue(value) then return nil end
  return type(value) == "string" and value ~= "" and value or nil
end

function P.ID(value)
  return P.Number(value) and value > 0 and value % 1 == 0 and value or nil
end

function P.Report(err)
  print("|cff0070ddShaman Binds:|r " .. tostring(err))
end

function P.ClearAction(frame)
  if not frame or Locked() then return end
  frame.equipmentSlot, frame._sbEquipmentSlot = nil, nil
  for _, key in ipairs({"type", "typerelease", "spell", "item", "macro", "macrotext", "action"}) do
    frame:SetAttribute(key, nil)
    -- Reused helpers must also forget their previous modified left-clicks.
    for _, prefix in ipairs({"shift-", "ctrl-", "alt-"}) do
      frame:SetAttribute(prefix .. key .. "1", nil)
    end
  end
  frame._sbTypeSaved, frame._sbRelSaved = nil, nil
  frame:SetScript("PostClick", nil)
  frame:SetScript("PreClick", nil)
  if P.ArmHardwareClicks then P.ArmHardwareClicks(frame) end
end

-- Left click is this face's ability. MMB/M4/M5 always fire the hardware
-- extras, even when the cursor is over a different icon. A mouse-enabled
-- frame otherwise swallows those buttons and the keybind never runs.
function P.RegisterFaceClicks(frame)
  if not frame or not frame.RegisterForClicks then return end
  frame:RegisterForClicks(
    "LeftButtonDown", "LeftButtonUp",
    "MiddleButtonDown", "MiddleButtonUp",
    "Button4Down", "Button4Up",
    "Button5Down", "Button5Up"
  )
  if P.ArmHardwareClicks then P.ArmHardwareClicks(frame) end
end

function P.RegisterMouseCatchClicks(frame)
  if not frame or not frame.RegisterForClicks then return end
  frame:RegisterForClicks(
    "MiddleButtonDown", "MiddleButtonUp",
    "Button4Down", "Button4Up",
    "Button5Down", "Button5Up"
  )
  if P.ArmHardwareClicks then P.ArmHardwareClicks(frame) end
end

-- Presentation only. No action, binding, cursor or SavedVariables writes.
P.Visual = {
  ink = {0.035, 0.047, 0.060, 0.98},
  panel = {0.055, 0.071, 0.086, 0.98},
  row = {0.075, 0.094, 0.110, 1},
  edge = {0.27, 0.29, 0.29, 1},
  brass = {0.68, 0.55, 0.35, 1},
  text = {0.94, 0.91, 0.83, 1},
  muted = {0.52, 0.61, 0.64, 1},
  teal = {0.27, 0.78, 0.76, 1},
  font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
  rowWidth = 214, rowHeight = 46, menuPad = 10, menuHeader = 34,
  families = {E="HIT", Q="INTERRUPT", ["2"]="SUSTAIN", T="GROUND", M4="MOVE",
    M5="SUMMON", C="OVERFLOW", BUF="EMPOWER", TP="EXPLORE", ["+"]="UTILITY"},
}

-- Class-selected presentation only. Ability engines remain Shaman-specific.
P.ClassThemes = {
  SHAMAN={accent={0.20,0.66,1.0,1}, metal={0.63,0.49,0.30,1},
    endcap="Interface\\AddOns\\ShamanBinds\\Media\\ShamanEndcap.tga",
    endcapW=70, endcapH=120,
    endcapHorde="Interface\\AddOns\\ShamanBinds\\Media\\ShamanEndcap_horde.tga",
    endcapHordeW=90, endcapHordeH=120,
    -- Wyvern: crimson runes, warm brass, umber stone.
    accentHorde={0.78,0.16,0.14,1}, metalHorde={0.70,0.50,0.28,1},
    inkHorde={0.040,0.024,0.022,0.98}, panelHorde={0.070,0.040,0.036,0.98},
    rowHorde={0.090,0.050,0.044,1}, edgeHorde={0.36,0.22,0.16,1},
    mutedHorde={0.72,0.56,0.52,1},
    stoneHorde={0.46,0.34,0.30,0.90}, shineHorde={0.82,0.58,0.32,0.70}},
  DEFAULT={accent={0.65,0.73,0.82,1}, metal={0.51,0.52,0.55,1}},
}

function P.PlayerIsHorde()
  if type(UnitFactionGroup)~="function" then return false end
  local ok, group=pcall(UnitFactionGroup, "player")
  return ok and group=="Horde"
end

function P.ApplyEndcapArt()
  P.ApplyFactionChrome()
end

function P.TintTex(tex, color, alpha)
  if not tex or not color then return end
  tex:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
end

function P.ApplyFactionChrome()
  local path, w, h = P.Visual.endcap, P.Visual.endcapW, P.Visual.endcapH
  if path and console then
    for _, art in ipairs(console._sbEndcaps or {}) do
      art:SetTexture(path)
      if w and h then art:SetSize(w, h) end
      P.SmoothUITexture(art)
    end
    P.TintTex(console._sbVisualPlate, P.Visual.ink)
    if console._sbStone then console._sbStone:SetVertexColor(unpack(P.Visual.stone)) end
    for _, rim in ipairs(console._sbRims or {}) do P.TintTex(rim, P.Visual.brass) end
    for _, shine in ipairs(console._sbShines or {}) do P.TintTex(shine, P.Visual.shine) end
    P.TintTex(console._sbRuneline, P.Visual.teal)
    if console._sbRuneline then console._sbRuneline:SetAlpha(0.45) end
    if console._sbRailTex then
      local t=P.Visual.teal
      console._sbRailTex:SetColorTexture(t[1], t[2], t[3], 0.10)
    end
    for _, tab in ipairs(consoleTabs or {}) do
      P.TintTex(tab._sbOpenMarker, P.Visual.teal)
    end
    for _, menu in pairs(menus or {}) do
      if menu._sbTealLine then P.TintTex(menu._sbTealLine, P.Visual.teal) end
      if menu._sbFamilyCaption then menu._sbFamilyCaption:SetTextColor(unpack(P.Visual.muted)) end
      for _, button in ipairs(menu.buttons or {}) do
        P.TintTex(button._sbRowAccent, P.Visual.teal)
        if button.keyText then button.keyText:SetTextColor(unpack(P.Visual.teal)) end
      end
    end
    P.EnsureEndcapEyes()
    if P.UpdateEndcapEyes then P.UpdateEndcapEyes() end
  end
end

function P.EnsureEndcapEyes()
  if not console then return end
  console._sbEyeGlows = console._sbEyeGlows or {}
  for i, art in ipairs(console._sbEndcaps or {}) do
    local glow = console._sbEyeGlows[i]
    if not glow then
      glow = console:CreateTexture(nil, "OVERLAY", nil, 7)
      glow:SetTexture("Interface\\AddOns\\ShamanBinds\\Media\\ShamanEndcap_owl_eyes")
      glow:SetBlendMode("ADD")
      P.SmoothUITexture(glow)
      glow:SetAlpha(0)
      console._sbEyeGlows[i] = glow
    end
    glow:ClearAllPoints()
    glow:SetAllPoints(art)
    if i == 1 then glow:SetTexCoord(0, 1, 0, 1) else glow:SetTexCoord(1, 0, 0, 1) end
  end
end

function P.PulseEndcapEyes()
  local glows = console and console._sbEyeGlows
  if not glows then return false end
  local on = P._sbEyesReady and console:IsShown() and not P.PlayerIsHorde()
  local a = 0
  if on then
    a = 0.55 + 0.40 * (0.5 + 0.5 * math.sin((GetTime() or 0) * 3.4))
  end
  for _, glow in ipairs(glows) do
    if glow then glow:SetAlpha(a) end
  end
  return on
end

function P.SelectClassTheme(classToken)
  if not classToken and type(UnitClass)=="function" then
    local ok, _, token=pcall(UnitClass,"player")
    if ok then classToken=token end
  end
  local theme=P.ClassThemes[classToken] or P.ClassThemes.DEFAULT
  local accent=theme.accent
  if theme==P.ClassThemes.DEFAULT and RAID_CLASS_COLORS then
    local color=RAID_CLASS_COLORS[classToken or ""]
    if type(color)=="table" and P.Number(color.r) and P.Number(color.g) and P.Number(color.b) then
      accent={color.r,color.g,color.b,1}
    end
  end
  P.Visual.font="Fonts\\FRIZQT__.TTF"
  P.Visual.classToken=classToken or "UNKNOWN"
  if theme.endcapHorde and P.PlayerIsHorde() then
    P.Visual.endcap=theme.endcapHorde
    P.Visual.endcapW=theme.endcapHordeW or 90
    P.Visual.endcapH=theme.endcapHordeH or 120
    P.Visual.faction="Horde"
    P.Visual.teal={unpack(theme.accentHorde or {0.78,0.16,0.14,1})}
    P.Visual.brass={unpack(theme.metalHorde or theme.metal)}
    P.Visual.ink=theme.inkHorde or {0.040,0.024,0.022,0.98}
    P.Visual.panel=theme.panelHorde or {0.070,0.040,0.036,0.98}
    P.Visual.row=theme.rowHorde or {0.090,0.050,0.044,1}
    P.Visual.edge=theme.edgeHorde or {0.36,0.22,0.16,1}
    P.Visual.muted=theme.mutedHorde or {0.72,0.56,0.52,1}
    P.Visual.stone=theme.stoneHorde or {0.46,0.34,0.30,0.90}
    P.Visual.shine=theme.shineHorde or {0.82,0.58,0.32,0.70}
  else
    P.Visual.endcap=theme.endcap
    P.Visual.endcapW=theme.endcapW or 70
    P.Visual.endcapH=theme.endcapH or 120
    P.Visual.faction="Alliance"
    P.Visual.teal={unpack(accent)}
    P.Visual.brass={unpack(theme.metal)}
    P.Visual.ink={0.025,0.029,0.036,0.98}
    P.Visual.panel={0.047,0.049,0.055,0.98}
    P.Visual.row={0.060,0.068,0.080,1}
    P.Visual.edge={0.29,0.27,0.23,1}
    P.Visual.muted={0.66,0.69,0.70,1}
    P.Visual.stone={0.52,0.58,0.65,0.85}
    P.Visual.shine={0.86,0.73,0.49,0.65}
  end
  P.ApplyFactionChrome()
  return theme
end
P.SelectClassTheme()

function P.VisualFont(text, size, color, flags)
  text:SetFont(P.Visual.font, size, flags or "")
  text:SetTextColor(unpack(color or P.Visual.text))
  text:SetShadowColor(0, 0, 0, 0.85)
  text:SetShadowOffset(1, -1)
end

function P.VisualTexture(frame, layer, color, sublevel)
  local texture = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
  texture:SetColorTexture(unpack(color))
  return texture
end

function P.VisualPanel(frame, color, border)
  frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",
    edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
  frame:SetBackdropColor(unpack(color or P.Visual.panel))
  frame:SetBackdropBorderColor(unpack(border or P.Visual.edge))
end

function P.VisualLine(frame, color, inset, y)
  local line = P.VisualTexture(frame, "BORDER", color)
  line:SetPoint("TOPLEFT", inset or 1, y or -1)
  line:SetPoint("TOPRIGHT", -(inset or 1), y or -1)
  line:SetHeight(1)
  return line
end

-- GameTooltip default anchors sit on top of the strip and the upward
-- drawer. Park it beside the whole cluster so our chrome stays readable.
function P.ConsoleClusterRect()
  local c = console
  if not c or not c.GetLeft or not c:GetLeft() then return nil end
  local l, r, t, b = c:GetLeft(), c:GetRight(), c:GetTop(), c:GetBottom()
  local plate = c._sbVisualPlate
  if plate and plate.GetLeft and plate:GetLeft() then
    l = math.min(l, plate:GetLeft())
    r = math.max(r, plate:GetRight())
    t = math.max(t, plate:GetTop())
    b = math.min(b, plate:GetBottom())
  end
  for _, art in ipairs(c._sbEndcaps or {}) do
    if art.GetLeft and art:GetLeft() then
      l,r=math.min(l,art:GetLeft()),math.max(r,art:GetRight())
      t,b=math.max(t,art:GetTop()),math.min(b,art:GetBottom())
    end
  end
  for _, m in pairs(menus) do
    if m:IsShown() and m.GetLeft and m:GetLeft() and (m:GetWidth() or 0) > 8 then
      l = math.min(l, m:GetLeft())
      r = math.max(r, m:GetRight())
      t = math.max(t, m:GetTop())
      b = math.min(b, m:GetBottom())
    end
  end
  -- Family captions sit under the tabs.
  return l, r, t, b - 20
end

function P.PlaceTooltipAway()
  if not GameTooltip or not GameTooltip:IsShown() then return end
  GameTooltip:ClearAllPoints()
  local parent = UIParent
  local pad = 16
  local tipW = GameTooltip:GetWidth() or 280
  local tipH = GameTooltip:GetHeight() or 180
  local screenL = parent:GetLeft() or 0
  local screenR = parent:GetRight() or 1024
  local screenT = parent:GetTop() or 768
  local screenB = parent:GetBottom() or 0
  local l, r, _, b = P.ConsoleClusterRect()
  local point, x, y
  if r and (screenR - r) >= (tipW + pad) then
    point, x, y = "BOTTOMLEFT", r + pad, b or 80
  elseif l and (l - screenL) >= (tipW + pad) then
    point, x, y = "BOTTOMRIGHT", l - pad, b or 80
  elseif console then
    GameTooltip:SetPoint("RIGHT", console, "LEFT", -16, 20)
    return
  else
    point, x, y = "CENTER", (screenL + screenR) / 2, (screenB + screenT) / 2
  end
  if y + tipH > screenT - 8 then y = screenT - tipH - 8 end
  if y < screenB + 8 then y = screenB + 8 end
  GameTooltip:SetPoint(point, parent, "BOTTOMLEFT", x, y)
end

function P.ShowConsoleTooltip(owner, source, extra)
  if not owner or not source or drag.active then return end
  GameTooltip:SetOwner(owner, "ANCHOR_NONE")
  if source.equipmentSlot and GameTooltip.SetInventoryItem then
    GameTooltip:SetInventoryItem("player", source.equipmentSlot)
  elseif source.spellID then
    GameTooltip:SetSpellByID(source.spellID)
  elseif source.itemID then
    GameTooltip:SetItemByID(source.itemID)
  elseif source.tipText then
    GameTooltip:SetText(source.tipText)
  elseif extra and extra.title then
    GameTooltip:SetText(extra.title)
  else
    GameTooltip:Hide()
    return
  end
  if source.tipKey then GameTooltip:AddLine(source.tipKey, unpack(P.Visual.teal)) end
  if extra and extra.line then GameTooltip:AddLine(extra.line, 0.7, 0.7, 0.7, true) end
  GameTooltip:Show()
  P.PlaceTooltipAway()
  if C_Timer and C_Timer.After then C_Timer.After(0, P.PlaceTooltipAway) end
end

function P.SkinConsole(frame)
  if frame._sbVisualPlate then return end
  -- Only texture regions: no additional mouse targets or protected buttons.
  local plate=P.VisualTexture(frame,"BACKGROUND",P.Visual.ink,-5)
  plate:SetPoint("TOPLEFT",-24,8)
  plate:SetPoint("BOTTOMRIGHT",7,-23)
  frame._sbVisualPlate=plate
  local stone=frame:CreateTexture(nil,"BACKGROUND",nil,-4)
  stone:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
  stone:SetAllPoints(plate)
  stone:SetVertexColor(unpack(P.Visual.stone or {0.52,0.58,0.65,0.85}))
  frame._sbStone=stone
  frame._sbRims, frame._sbShines = {}, {}
  for _,side in ipairs({"TOP","BOTTOM"}) do
    local rim=P.VisualTexture(frame,"BORDER",P.Visual.brass,-2)
    rim:SetPoint(side.."LEFT",plate,side.."LEFT",0,0)
    rim:SetPoint(side.."RIGHT",plate,side.."RIGHT",0,0)
    rim:SetHeight(3)
    frame._sbRims[#frame._sbRims+1]=rim
    local shine=P.VisualTexture(frame,"BORDER",P.Visual.shine or {0.86,0.73,0.49,0.65},-1)
    shine:SetPoint(side.."LEFT",rim,side.."LEFT",1,0)
    shine:SetPoint(side.."RIGHT",rim,side.."RIGHT",-1,0)
    shine:SetHeight(1)
    frame._sbShines[#frame._sbShines+1]=shine
  end
  local inset=P.VisualTexture(frame,"BORDER",{0,0,0,0.8},0)
  inset:SetPoint("TOPLEFT",plate,"TOPLEFT",2,-3)
  inset:SetPoint("TOPRIGHT",plate,"TOPRIGHT",-2,-3)
  inset:SetHeight(2)
  local runeline=P.VisualTexture(frame,"BORDER",P.Visual.teal,1)
  runeline:SetPoint("BOTTOMLEFT",plate,"BOTTOMLEFT",8,5)
  runeline:SetPoint("BOTTOMRIGHT",plate,"BOTTOMRIGHT",-8,5)
  runeline:SetHeight(1)
  runeline:SetAlpha(0.45)
  frame._sbRuneline=runeline
  frame._sbEndcaps={}
  for _,side in ipairs({"LEFT","RIGHT"}) do
    local art=frame:CreateTexture(nil,"ARTWORK",nil,0)
    if P.Visual.endcap then
      art:SetTexture(P.Visual.endcap)
      -- Alliance owl 70x120, Horde wind rider 90x120. Wolves: ShamanEndcap_wolf.tga.
      art:SetSize(P.Visual.endcapW or 70, P.Visual.endcapH or 120)
      P.SmoothUITexture(art)
      if side=="LEFT" then
        art:SetDrawLayer("ARTWORK", 0)
        art:SetPoint("RIGHT",plate,"LEFT",36,14)
        art:SetTexCoord(0, 1, 0, 1)
      else
        art:SetDrawLayer("OVERLAY", 7)
        art:SetPoint("LEFT",plate,"RIGHT",-36,14)
        art:SetTexCoord(1, 0, 0, 1)
      end
    else
      -- Neutral metal wings for unimplemented class artwork, class-coloured inlays.
      art:SetColorTexture(unpack(P.Visual.brass))
      art:SetSize(8,74)
      art:SetPoint(side=="LEFT" and "RIGHT" or "LEFT",plate,side,0,0)
      local gem=P.VisualTexture(frame,"ARTWORK",P.Visual.teal,1)
      gem:SetSize(4,24);gem:SetPoint("CENTER",art,"CENTER")
    end
    frame._sbEndcaps[#frame._sbEndcaps+1]=art
  end
  P.EnsureEndcapEyes()
  -- Negative insets extend the clamp boundary to include the decorative ends.
  if frame.SetClampRectInsets then frame:SetClampRectInsets(-106,88,52,-26) end
end

function P.SkinParent(tab, fam)
  if not tab._sbFamilyCaption then
    local caption = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    caption:SetPoint("TOP", tab, "BOTTOM", 0, -3)
    caption:SetWidth(52)
    caption:SetWordWrap(false)
    P.VisualFont(caption, 8, P.Visual.muted)
    tab._sbFamilyCaption = caption
    local marker = P.VisualTexture(tab, "OVERLAY", P.Visual.teal, 6)
    marker:SetPoint("TOPLEFT", 4, -1)
    marker:SetPoint("TOPRIGHT", -4, -1)
    marker:SetHeight(2)
    marker:SetAlpha(0)
    tab._sbOpenMarker = marker
    local badge = P.VisualTexture(tab, "OVERLAY", {0.015, 0.022, 0.030, 0.93}, 5)
    badge:SetPoint("BOTTOMLEFT", 3, 3)
    badge:SetPoint("BOTTOMRIGHT", -3, 3)
    badge:SetHeight(15)
    tab._sbKeyBadge = badge
  end
  tab._sbFamilyCaption:SetText(P.Visual.families[fam.tag] or fam.tag or "")
  if tab.keyText then
    tab.keyText:ClearAllPoints()
    tab.keyText:SetPoint("BOTTOM", 0, 4)
    tab.keyText:SetWidth(44)
    P.VisualFont(tab.keyText, 11, P.Visual.text, "OUTLINE")
  end
end

function P.SkinMenu(menu, tab)
  if menu._sbVisualTitle then return end
  P.VisualPanel(menu, P.Visual.ink, P.Visual.brass)
  menu._sbTealLine = P.VisualLine(menu, P.Visual.teal, 1, -1)
  local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  title:SetPoint("TOPLEFT", 12, -11)
  P.VisualFont(title, 10, P.Visual.text)
  menu._sbVisualTitle = title
  local count = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  count:SetPoint("TOPRIGHT", -12, -11)
  P.VisualFont(count, 9, P.Visual.muted)
  menu._sbVisualCount = count
  menu._sbVisualRule = P.VisualLine(menu, P.Visual.edge, 10, -28)
  menu:HookScript("OnShow", function()
    if tab._sbOpenMarker then tab._sbOpenMarker:SetAlpha(1) end
    if tab._sbFamilyCaption then tab._sbFamilyCaption:SetTextColor(unpack(P.Visual.teal)) end
    if P.ArmMenuMouse then P.ArmMenuMouse(menu) end
    if P.RefreshTotemHits then P.RefreshTotemHits() end
  end)
  menu:HookScript("OnHide", function()
    if tab._sbOpenMarker then tab._sbOpenMarker:SetAlpha(0) end
    if tab._sbFamilyCaption then tab._sbFamilyCaption:SetTextColor(unpack(P.Visual.muted)) end
    if P.RefreshTotemHits then P.RefreshTotemHits() end
  end)
end

-- Drawers sit in the same screen rect as the totem crowns. They must take
-- clicks; otherwise the grabber underneath eats every Menu_* row.
function P.MenusBlockingTotems()
  for _, menu in pairs(menus or {}) do
    if menu:IsShown() then return true end
  end
  return false
end

function P.ArmMenuMouse(menu)
  if not menu then return end
  menu:EnableMouse(true)
  if menu.SetMouseClickEnabled then menu:SetMouseClickEnabled(true) end
  if menu.SetMouseMotionEnabled then menu:SetMouseMotionEnabled(true) end
  menu:SetFrameStrata("HIGH")
  local level = (console and (console:GetFrameLevel() or 50) or 50) + 40
  pcall(function() menu:SetFrameLevel(level) end)
  for _, b in ipairs(menu.buttons or {}) do
    b:EnableMouse(true)
    if b.SetMouseClickEnabled then b:SetMouseClickEnabled(true) end
    if b.SetMouseMotionEnabled then b:SetMouseMotionEnabled(true) end
    pcall(function()
      b:SetFrameStrata("HIGH")
      b:SetFrameLevel(level + 2)
    end)
  end
end

function P.RefreshTotemHits()
  for _, f in ipairs((P.totemReadyRack and P.totemReadyRack.icons) or {}) do
    P.ApplyTotemChrome(f)
  end
end

function P.SkinDrawer(button)
  if button._sbVisualLabel then return end
  P.VisualPanel(button, P.Visual.row, P.Visual.edge)
  button.icon:ClearAllPoints()
  button.icon:SetPoint("LEFT", 5, 0)
  button.icon:SetSize(36, 36)
  if button._sbVignette then button._sbVignette:Hide() end
  if button._sbTopShine then button._sbTopShine:Hide() end
  -- One quiet row border; the brass belongs to the console, not every row.
  for _, shadow in ipairs(button._sbShadow or {}) do shadow:Hide() end
  local well = P.VisualTexture(button, "BACKGROUND", {0.015, 0.022, 0.028, 1})
  well:SetPoint("LEFT", 4, 0)
  well:SetSize(38, 38)
  local accent = P.VisualTexture(button, "OVERLAY", P.Visual.teal, 6)
  accent:SetPoint("TOPLEFT", 0, -1)
  accent:SetPoint("BOTTOMLEFT", 0, 1)
  accent:SetWidth(2)
  accent:SetAlpha(0)
  button._sbRowAccent = accent
  button:HookScript("OnEnter", function(self)
    self:SetBackdropColor(P.Visual.row[1] + 0.03, P.Visual.row[2] + 0.04, P.Visual.row[3] + 0.05, 1)
    self._sbRowAccent:SetAlpha(1)
  end)
  button:HookScript("OnLeave", function(self)
    self:SetBackdropColor(unpack(P.Visual.row))
    self._sbRowAccent:SetAlpha(0)
  end)
  local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("TOPLEFT", 50, -8)
  label:SetWidth(P.Visual.rowWidth - 60)
  label:SetHeight(15)
  label:SetWordWrap(false)
  label:SetJustifyH("LEFT")
  P.VisualFont(label, 11, P.Visual.text)
  button._sbVisualLabel = label
  button.keyText:ClearAllPoints()
  button.keyText:SetPoint("BOTTOMLEFT", 50, 7)
  button.keyText:SetWidth(150)
  button.keyText:SetJustifyH("LEFT")
  P.VisualFont(button.keyText, 10, P.Visual.teal)
  local click = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  click:SetPoint("BOTTOMLEFT", 50, 7)
  P.VisualFont(click, 9, P.Visual.muted)
  click:SetText("Click to use")
  button._sbClickHint = click
end

function P.UpdateDrawerVisual(button, ability)
  if not button._sbVisualLabel then return end
  button._sbVisualLabel:SetText(ability.label or ability.name or "Ability")
  local text = button.keyText and button.keyText:GetText()
  button._sbClickHint:SetShown(not text or text == "")
end

-- Shared key-label typography.
local function StyleKeyText(fs)
  if not fs then return end
  P.VisualFont(fs, 11, P.Visual.text, "OUTLINE")
end


local function PrettyKey(key)
  if type(key) ~= "string" or key == "" then return nil end
  return (key
    :gsub("MOUSEWHEELUP", "WheelUp")
    :gsub("MOUSEWHEELDOWN", "WheelDown")
    :gsub("MWHEELUP", "WheelUp")
    :gsub("MWHEELDOWN", "WheelDown")
    :gsub("BUTTON3", "MMB")
    :gsub("BUTTON4", "M4")
    :gsub("BUTTON5", "M5")
    :gsub("BUTTON2", "RMB")
    :gsub("BUTTON1", "LMB")
    :gsub("SHIFT%-", "Shift-")
    :gsub("CTRL%-", "Ctrl-")
    :gsub("ALT%-", "Alt-"))
end

local function ShortKey(key)
  if not PrettyKey(key) then return nil end
  return (PrettyKey(key)
    :gsub("[Mm]ouse", "M")
    :gsub("WheelUp", "WUp")
    :gsub("WheelDown", "WDn")
    :gsub("Shift%-", "S-")
    :gsub("Ctrl%-", "C-")
    :gsub("Alt%-", "A-"))
end

local function InQuickKeybind()
  if KeybindFrames_InQuickKeybindMode then
    local ok, on = pcall(KeybindFrames_InQuickKeybindMode)
    if ok and on then return true end
  end
  return QuickKeybindFrame and QuickKeybindFrame:IsShown()
end

-- ============================== SPELLBOOK ==============================

local function SpellName(id)
  return (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or tostring(id)
end

-- name -> spellID for every active, known, non-passive spell in the book.
-- This is the source of truth (avoids wrong-race/wrong-rank name lookups).
local BOOK = {}

function P.BookInfo(slot, bank)
  local api = C_SpellBook and C_SpellBook.GetSpellBookItemInfo
  if type(api) ~= "function" then return nil end
  local ok, info = pcall(api, slot, bank)
  if ok and type(info) == "table" then return info end
  ok, info = pcall(api, {slotIndex=slot, spellBank=bank})
  return ok and type(info) == "table" and info or nil
end

local function ScanBook()
  local previous = {}
  for name, id in pairs(BOOK) do previous[name] = id end
  wipe(BOOK)
  local ok, err = pcall(function()
    for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
      local li = C_SpellBook.GetSpellBookSkillLineInfo(line)
      if li and not li.offSpecID then
        for j = li.itemIndexOffset + 1, li.itemIndexOffset + li.numSpellBookItems do
          local it = P.BookInfo(j, Enum.SpellBookSpellBank.Player)
          if it and it.spellID and not it.isPassive and not it.isOffSpec then
            local spellType = Enum.SpellBookItemType
            if spellType and it.itemType and it.itemType ~= spellType.Spell then
              -- Flyouts, pets, and unlearned nodes are not family faces.
            else
              local nm = it.name or SpellName(it.spellID)
              if nm and nm ~= "" and nm ~= tostring(it.spellID) and not BOOK[nm] then
                BOOK[nm] = it.spellID
              end
            end
          end
        end
      end
    end
  end)
  if not ok then
    wipe(BOOK)
    for name, id in pairs(previous) do BOOK[name] = id end
  end
end

-- Talent / racial IDs used when the book scan hides the name (Midnight secrets).
P.SPELL_ID = {
  ["Cleanse Spirit"] = 51886,
  ["Purify Spirit"] = 77130,
  ["Astral Shift"] = 108271,
  ["Sundering"] = 197214,
  ["Spiritwalker's Grace"] = 79206,
  ["Stormkeeper"] = 191634,
  ["Earthquake"] = 61882,
  ["Elemental Blast"] = 117014,
  ["Gust of Wind"] = 192063,
  ["Thunderstorm"] = 51490,
  ["Lava Burst"] = 51505,
  ["Rootwalking"] = 1238686,
  ["Rootwalking: Return"] = 1238695,
  ["Primal Elementalist"] = 117013,
  ["Earth Elemental"] = 198103,
  ["Fire Elemental"] = 198067,
  ["Storm Elemental"] = 192249,
  ["Ascendance"] = 114050,
}
P.SPELL_ICON = {
  ["Cleanse Spirit"] = 136087,
  ["Purify Spirit"] = 236288,
  ["Astral Shift"] = 538565,
  ["Sundering"] = 1020304,
  ["Spiritwalker's Grace"] = 451170,
  ["Stormkeeper"] = 839974,
  ["Earthquake"] = 451165,
  ["Gust of Wind"] = 1029585,
  ["Thunderstorm"] = 136111,
  ["Rootwalking"] = 135726,
  ["Rootwalking: Return"] = 135726,
}

function P.PlayerKnows(id)
  if not P.ID(id) then return false end
  if IsPlayerSpell and IsPlayerSpell(id) then return true end
  if IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(id) then return true end
  if IsSpellKnown and IsSpellKnown(id) then return true end
  if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
    local ok, known = pcall(C_SpellBook.IsSpellInSpellBook, id)
    if ok and known then return true end
  end
  return false
end

function P.UsesActionOverride(name)
  return type(name) == "string" and name:find("Rootwalking", 1, true) ~= nil
end

-- First name from the list that exists in the spellbook. Returns name, id.
local function Known(...)
  for i = 1, select("#", ...) do
    local name = select(i, ...)
    if name and BOOK[name] then return name, BOOK[name] end
  end
  for i = 1, select("#", ...) do
    local name = select(i, ...)
    local id = name and P.SPELL_ID[name]
    if id and P.PlayerKnows(id) then return name, id end
    if name and C_Spell and C_Spell.GetSpellInfo then
      local info = C_Spell.GetSpellInfo(name)
      local id2 = type(info) == "table" and info.spellID or nil
      if id2 and P.PlayerKnows(id2) then return (info.name or name), id2 end
    end
  end
  for i = 1, select("#", ...) do
    local want = select(i, ...)
    if type(want) == "string" and want ~= "" then
      for bookName, id in pairs(BOOK) do
        if type(bookName) == "string" and bookName:find(want, 1, true) then
          return bookName, id
        end
      end
    end
  end
end

local function SpellIcon(id, name)
  if id and C_Spell and C_Spell.GetSpellTexture then
    local tex = C_Spell.GetSpellTexture(id)
    if tex and tex ~= 0 and tex ~= 134400 then return tex end
  end
  if name and P.SPELL_ICON[name] then return P.SPELL_ICON[name] end
  return 134400
end

local RACIALS = {
  "Thorn Bloom", "Lash Out",
  "Blood Fury", "Berserking", "War Stomp", "Stoneform", "Gift of the Naaru",
  "Quaking Palm", "Arcane Torrent", "Fireblood", "Ancestral Call", "Bull Rush",
  "Spatial Rift", "Light's Judgment", "Rocket Barrage", "Bag of Tricks",
  "Regeneratin'", "Shadowmeld", "Escape Artist", "Every Man for Himself",
  "Will to Survive", "Darkflight", "Haymaker",
}

-- SBA / passives / replaced buttons. Never dump these into +.
local STATIC_EXCLUDE = {
  ["Flametongue Weapon"] = true,
  ["Windfury Weapon"] = true,
  ["Stormstrike"] = true,
  ["Lava Lash"] = true,
  ["Crash Lightning"] = true,
  ["Voltaic Blaze"] = true,
  ["Lightning Bolt"] = true,
  ["Ice Strike"] = true,
  ["Flame Shock"] = true,
  ["Tempest"] = true,
  ["Fire Nova"] = true,
  ["Feral Spirit"] = true,
  ["Doom Winds"] = true,
  ["Lava Burst"] = true,
  ["Elemental Blast"] = true,
  ["Earth Shock"] = true,
  ["Windstrike"] = true,
  ["Chain Lightning"] = true,
}

-- ============================== BAR 1 PLACEMENT ==============================

local function PickupID(id)
  if C_Spell and C_Spell.PickupSpell then C_Spell.PickupSpell(id) else PickupSpell(id) end
end

local function ClearSlot(slot)
  PickupAction(slot)
  ClearCursor()
end

-- Midnight can return a secret from GetCursorInfo even when the cursor is empty.
-- Treat secrets as empty so PlaceMacro/PlaceID are not fail-closed on apply.
function P.CursorKind()
  local ok, kind = pcall(GetCursorInfo)
  if not ok then return nil end
  if issecretvalue and issecretvalue(kind) then return "secret" end
  if kind == nil then return nil end
  return kind
end

local function PlaceID(slot, id)
  if Locked() or not P.ID(slot) or not P.ID(id) then return false end
  local kind = P.CursorKind()
  if kind and kind ~= "secret" then return false end
  PickupID(id)
  kind = P.CursorKind()
  if kind ~= "spell" and kind ~= "secret" then ClearCursor(); return false end
  PlaceAction(slot)
  ClearCursor()
  KEEP[slot] = true
  return true
end

local function MacroIndex(name)
  if not name then return 0 end
  local index = GetMacroIndexByName(name)
  return (index and index > 0) and index or 0
end

-- Walk account macros (1..N) then character macros.
local function EachSBMacro(fn)
  local acc = MAX_ACCOUNT_MACROS or 120
  local g, c = GetNumMacros()
  g, c = g or 0, c or 0
  for i = 1, g do
    local n = GetMacroInfo(i)
    if type(n) == "string" and n:sub(1, 3) == "SB_" then
      if fn(i, n) then return i, n end
    end
  end
  for i = acc + 1, acc + c do
    local n = GetMacroInfo(i)
    if type(n) == "string" and n:sub(1, 3) == "SB_" then
      if fn(i, n) then return i, n end
    end
  end
end

-- Old builds created SB_HealSurge1, SB_HealSurge2, … until the 120 cap.
-- Delete suffix clones that are not in the current registry.
function P.PruneOrphanSBMacros()
  if Locked() then return end
  local keep = {}
  for _, name in pairs(ShamanBindsDB.macroNames or {}) do keep[name] = true end
  local victims = {}
  EachSBMacro(function(i, n)
    if not keep[n] and n:match("^SB_.+%d+$") then
      victims[#victims + 1] = i
    end
  end)
  table.sort(victims, function(a, b) return a > b end)
  for _, i in ipairs(victims) do pcall(DeleteMacro, i) end
end

local function EnsureMacro(name, icon, body)
  if Locked() or not P.Text(name) or not P.Text(body) then return nil end
  if #body > (MAX_MACRO_LENGTH or 255) then return nil end
  local registry = ShamanBindsDB.macroNames
  local actual = registry[name] or ("SB_" .. name)
  local index = MacroIndex(actual)
  if index == 0 then index = MacroIndex("SB_" .. name) if index > 0 then actual = "SB_" .. name end end
  if index == 0 then
    EachSBMacro(function(i, n)
      if n == "SB_" .. name or n:match("^SB_" .. name:gsub("(%W)", "%%%1") .. "%d+$") then
        index, actual = i, n
        return true
      end
    end)
  end
  if index > 0 then
    pcall(EditMacro, index, actual, icon or 134400, body)
    registry[name] = actual
    return index
  end
  actual = "SB_" .. name
  for _, perChar in ipairs({true, false}) do
    local ok, idx = pcall(CreateMacro, actual, icon or 134400, body, perChar)
    if ok and idx and idx > 0 then
      registry[name] = actual
      return idx
    end
  end
  if not P.macroCapacityWarning then
    P.macroCapacityWarning=true
    P.Report("Macro storage full. Free a macro slot, then /shamanbinds. Existing macros were preserved.")
  end
  return nil
end

local function PlaceMacro(slot, name, icon, body, pulseName, frameName)
  if Locked() then return false end
  local kind = P.CursorKind()
  if kind and kind ~= "secret" then return false end
  local index = EnsureMacro(name, icon, body)
  if not index or index == 0 then return false end
  PickupMacro(index)
  kind = P.CursorKind()
  if kind ~= "macro" and kind ~= "secret" then ClearCursor(); return false end
  PlaceAction(slot)
  ClearCursor()
  KEEP[slot] = true
  if slot >= 8 then ShamanBindsDB.hiddenSlots[slot] = GetMacroInfo(index) end
  return true
end

-- Midnight blocks @cursor (and some totem) casts from addon SecureActionButtons.
-- Those macros must sit on a real Blizzard action slot; the key clicks that slot.
-- Mouse extras use page-1 slots 8-12 (ACTIONBUTTON8-12). Never 61-72 as a
-- visible bar, and never MULTIACTIONBAR* — a hidden extra bar does not fire.
local hiddenByBindId = {}
local hiddenSlotN = 0
-- bindKey → first /cast or /use line (no modifier). Filled while extras resolve.
local chordLine = {}

local function ResetHiddenSlots()
  wipe(hiddenByBindId)
  wipe(chordLine)
  hiddenSlotN = 0
end

local function SpellListHasTotem(list)
  if type(list) == "string" then return list:find("Totem", 1, true) end
  if type(list) ~= "table" then return false end
  for _, n in ipairs(list) do
    if type(n) == "string" and n:find("Totem", 1, true) then return true end
  end
end

-- Totems and @cursor need a real Blizzard slot.
-- Mousewheel totems match via @cursor / Totem in the body — not the key name.
-- Other mouse keys (M4/M5/MMB) park on reserved 8-12 or a named MACRO bind.
local function NeedsBlizzardSlot(item)
  if type(item) ~= "table" then return false end
  if item.equipmentSlot then return false end -- /use equipment, even if its name contains Totem
  local t = item.macrotext
  if t and (t:find("@cursor", 1, true) or t:find("Totem", 1, true)) then return true end
  if SpellListHasTotem(item.spell) or SpellListHasTotem(item.name) or SpellListHasTotem(item.label) then return true end
  local nm = item.name or item.label
  if nm == "Thorn Bloom" then return true end
  if nm and P.UsesActionOverride(nm) then return true end
  if item.covers then
    for _, cover in ipairs(item.covers) do
      if P.UsesActionOverride(cover) then return true end
    end
  end
  return false
end

-- One mouse key = one action. Shift extras are their own binds.
-- Ground totems use Shift+wheel. Plain wheel and Ctrl-wheel stay on the camera.
-- WoW's bind token is MOUSEWHEELUP, not MWHEELUP (SetBinding rejects the short name).
local MOUSE_HARDWARE = {
  ["SHIFT-MOUSEWHEELUP"] = { slot = 5, macro = "RushTotem" },
  ["BUTTON3"] = { slot = 10, spell = "Earth Elemental", macro = "EarthEle" },
  ["BUTTON4"] = { slot = 6 },
  ["BUTTON5"] = { slot = 8, macro = "FavMount" },
  ["SHIFT-BUTTON4"] = { slot = 9, macro = "FleeKit" },
  ["SHIFT-MOUSEWHEELDOWN"] = { slot = 11, macro = "CapTotem" },
  ["SHIFT-BUTTON3"] = { spell = "Spiritwalker's Grace" },
}

function P.IsMouseKey(key)
  if type(key) ~= "string" then return false end
  return key:find("BUTTON", 1, true) ~= nil
    or key:find("MOUSEWHEEL", 1, true) ~= nil
    or key:find("MWHEEL", 1, true) ~= nil
end

function P.IsCameraBinding(key)
  local act = GetBindingAction(key)
  return act == "CAMERAZOOMIN" or act == "CAMERAZOOMOUT"
end

function P.IsAddonCameraKey(key)
  return key == "CTRL-BUTTON4" or key == "CTRL-BUTTON5"
    or key == "CTRL-MOUSEWHEELUP" or key == "CTRL-MOUSEWHEELDOWN"
end

local HARDWARE_LABEL = {
  ["SHIFT-MOUSEWHEELUP"] = "Wind Rush Totem",
  ["SHIFT-MOUSEWHEELDOWN"] = "Capacitor Totem",
  ["CTRL-MOUSEWHEELUP"] = "camera zoom in",
  ["CTRL-MOUSEWHEELDOWN"] = "camera zoom out",
  ["BUTTON3"] = "Earth Elemental",
  ["BUTTON4"] = "Ghost Wolf (Move)",
  ["BUTTON5"] = "the M5 face",
  ["SHIFT-BUTTON3"] = "Spiritwalker's Grace",
  ["SHIFT-BUTTON4"] = "the Shift-M4 extra",
  ["SHIFT-BUTTON5"] = "the Shift-M5 extra",
  MOUSEWHEELUP = "camera zoom in",
  MOUSEWHEELDOWN = "camera zoom out",
}

function P.HardwareLabel(key)
  return HARDWARE_LABEL[key]
end

function P.WarnBindsOn()
  return ShamanBindsDB.warnBinds ~= false
end

function P.ReservedBindReason(key)
  if key == "CTRL-MOUSEWHEELUP" or key == "CTRL-MOUSEWHEELDOWN" then
    return "Ctrl-Wheel stays on camera zoom."
  end
  if key == "CTRL-BUTTON4" or key == "CTRL-BUTTON5" then
    return "Ctrl-M4 / Ctrl-M5 stay on camera zoom. Set them in ESC → Keybindings."
  end
  if key == "NUMPADPLUS" or key == "NUMPADMINUS" then
    return "Numpad + / − stay on camera zoom."
  end
  if P.IsChatKey(key) then
    return "Enter and / stay on chat."
  end
end

function P.ExplainStolenBind(key, newLabel, oldAction)
  if not P.WarnBindsOn() or not P.Text(key) then return end
  local pretty = PrettyKey(key) or key
  local stock = HARDWARE_LABEL[key]
  if stock and P.Text(newLabel) and stock ~= newLabel then
    P.Report(pretty .. " was " .. stock .. ". That ability is click unless you bind another key.")
  end
  if oldAction == "CAMERAZOOMIN" or oldAction == "CAMERAZOOMOUT"
    or key == "MOUSEWHEELUP" or key == "MOUSEWHEELDOWN" then
    P.Report("Camera zoom is on Ctrl-Wheel and Numpad + / −. Ctrl-M4 / Ctrl-M5 also zoom if you set them in Keybindings.")
  end
end

function P.PrintBindNotices()
  if not P.WarnBindsOn() then return end
  local missing = {}
  for _, key in ipairs({"CTRL-BUTTON4", "CTRL-BUTTON5"}) do
    if not P.IsCameraBinding(key) then
      missing[#missing + 1] = PrettyKey(key) or key
    end
  end
  if #missing > 0 then
    P.Report(table.concat(missing, " / ") .. " is not camera zoom. Set Ctrl-M4 / Ctrl-M5 in ESC → Keybindings.")
  end
end

function P.PrintKeyGuide()
  print("|cff0070ddShaman Binds keys:|r")
  print("  |cffffffffReserved|r  Ctrl-Wheel = zoom. Ctrl-M4 / Ctrl-M5 = zoom (WoW Keybindings). Numpad + / − = zoom. Enter / = chat.")
  print("  |cffffffffTotem wheel|r  Shift-Up Wind Rush · Shift-Down Capacitor. Earthgrab and Thorn Bloom are click on Totems.")
  print("  |cffffffffBIND|r  Hover an icon, press a key or scroll. Replacing a totem chord leaves that totem as click.")
  print("  |cffffffffWoW Keybindings|r  This addon reclaims shaman mouse keys on apply, except camera zoom on Ctrl-Wheel and Ctrl-M4 / Ctrl-M5.")
  print("  Reminders: |cffffffffESC → Options → Shaman Binds|r, or |cffffffff/shamanbinds options|r.")
end

-- "SHIFT-BUTTON5" → prefix "shift-", suffix "5" for SecureActionButton attrs.
function P.MouseClickParts(key)
  if not P.IsMouseKey(key) then return nil end
  local suffix = key:match("BUTTON(%d+)$")
  if not suffix then return nil end
  local prefix = ""
  if key:find("ALT", 1, true) then prefix = prefix .. "alt-" end
  if key:find("CTRL", 1, true) then prefix = prefix .. "ctrl-" end
  if key:find("SHIFT", 1, true) then prefix = prefix .. "shift-" end
  return prefix, suffix
end

function P.ArmAllHardwareClicks()
  if Locked() then return end
  P.DisableMouseCatch()
  for _, tab in pairs(consoleTabs) do P.ArmHardwareClicks(tab) end
  for _, b in ipairs(allMenuButtons) do P.ArmHardwareClicks(b) end
  if console then
    P.ArmHardwareClicks(console._sbGrip)
    P.ArmHardwareClicks(console._sbRail)
  end
end

-- 6.74 full-screen catcher ate M4/M5 for the whole UI. AHK was the real
-- intercept; do not recreate this frame.
function P.DisableMouseCatch()
  local f = P.mouseCatch
  if not f then f = _G.ShamanBindsMouseCatch end
  if f then
    pcall(function()
      f:EnableMouse(false)
      f:Hide()
    end)
    P.mouseCatch = f
  end
end

P.MOUSE_MACRO = {
  [5] = "RushTotem",
  [8] = "FavMount",
  [9] = "FleeKit",
  [10] = "EarthEle",
  [11] = "CapTotem",
  [12] = "RootTotem",
}

-- Named macros BIND can attach to a mouse key. Click-only extras have no
-- ACTIONBUTTON; WoW ignores CLICK commands on wheel / M4 / M5.
P.MACRO_SHORT_BY_LABEL = {
  ["Wind Rush Totem"] = "RushTotem",
  ["Capacitor Totem"] = "CapTotem",
  ["Earthgrab Totem"] = "RootTotem",
  ["Earthbind Totem"] = "RootTotem",
  ["Thorn Bloom"] = "ThornBloom",
}

function P.NamedMacroCommand(short)
  if not P.Text(short) then return nil end
  local actual = (ShamanBindsDB.macroNames or {})[short] or ("SB_" .. short)
  local index = GetMacroIndexByName(actual)
  if (not index or index == 0) and actual ~= ("SB_" .. short) then
    actual = "SB_" .. short
    index = GetMacroIndexByName(actual)
  end
  if index and index > 0 then return "MACRO " .. actual, actual end
end

function P.ActionBindCommand(slot)
  if not P.ID(slot) then return nil end
  local named = P.MOUSE_MACRO[slot] and P.NamedMacroCommand(P.MOUSE_MACRO[slot])
  if named then return named end
  local ok, kind, id = pcall(GetActionInfo, slot)
  if ok and kind and not (issecretvalue and issecretvalue(kind)) then
    if kind == "macro" then
      local name = GetMacroInfo(id)
      if P.Text(name) then return "MACRO " .. name end
      -- Midnight sometimes reports a spell as type "macro" with the spell ID.
      local spell = P.ID(id) and ((C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or SpellName(id))
      if P.Text(spell) then return "SPELL " .. spell end
    elseif kind == "spell" then
      local name = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or SpellName(id)
      if P.Text(name) then return "SPELL " .. name end
    end
  end
  if slot <= 7 then return "ACTIONBUTTON" .. slot end
end

function P.MouseKeyCommand(key)
  local spec = MOUSE_HARDWARE[key]
  if not spec then return nil end
  if spec.macro then
    local cmd = P.NamedMacroCommand(spec.macro)
    if cmd then return cmd end
  end
  if spec.spell then
    local name = Known(spec.spell) or spec.spell
    if P.Text(name) then return "SPELL " .. name end
  end
  if spec.slot then return P.ActionBindCommand(spec.slot) end
end

-- Write both "shift-type4" and "shift-type-Button4". Midnight OnClick uses
-- the button token "Button4"; older clients use the numeric suffix.
function P.SetClickAttr(frame, prefix, suffix, attr, value)
  frame:SetAttribute(prefix .. attr .. suffix, value)
  frame:SetAttribute(prefix .. attr .. "-Button" .. suffix, value)
end

function P.ArmMacroClick(frame, prefix, suffix, macroName)
  if not macroName then return end
  P.SetClickAttr(frame, prefix, suffix, "type", "macro")
  P.SetClickAttr(frame, prefix, suffix, "typerelease", "macro")
  P.SetClickAttr(frame, prefix, suffix, "macro", macroName)
  P.SetClickAttr(frame, prefix, suffix, "action", nil)
  P.SetClickAttr(frame, prefix, suffix, "spell", nil)
end

function P.ArmSpellClick(frame, prefix, suffix, spell)
  if not P.Text(spell) then return end
  P.SetClickAttr(frame, prefix, suffix, "type", "spell")
  P.SetClickAttr(frame, prefix, suffix, "typerelease", "spell")
  P.SetClickAttr(frame, prefix, suffix, "spell", spell)
  P.SetClickAttr(frame, prefix, suffix, "macro", nil)
  P.SetClickAttr(frame, prefix, suffix, "action", nil)
end

-- Left click = this face. MMB/M4/M5 = hardware extras. Shift+M4/M5 must use
-- shift-type4/5 — with Shift down, SecureActionButton will not use type4.
function P.ArmHardwareClicks(frame)
  if not frame or Locked() or not frame.SetAttribute then return end
  pcall(function()
    frame:SetAttribute("checkselfcast", false)
    frame:SetAttribute("checkfocuscast", false)
  end)
  for _, suffix in ipairs({"3", "4", "5"}) do
    for _, prefix in ipairs({"", "shift-", "ctrl-", "alt-"}) do
      P.SetClickAttr(frame, prefix, suffix, "type", nil)
      P.SetClickAttr(frame, prefix, suffix, "typerelease", nil)
      P.SetClickAttr(frame, prefix, suffix, "macro", nil)
      P.SetClickAttr(frame, prefix, suffix, "spell", nil)
      P.SetClickAttr(frame, prefix, suffix, "action", nil)
    end
  end
  for key, spec in pairs(MOUSE_HARDWARE) do
    if not P.IsCameraBinding(key) then
    local prefix, suffix = P.MouseClickParts(key)
    if suffix then
      local macroName
      if spec.macro then
        local _, named = P.NamedMacroCommand(spec.macro)
        macroName = named
      end
      if not macroName and P.ID(spec.slot) then
        local short = P.MOUSE_MACRO[spec.slot]
        local _, named = short and P.NamedMacroCommand(short)
        macroName = named
      end
      if macroName then
        P.ArmMacroClick(frame, prefix, suffix, macroName)
      elseif spec.spell then
        P.ArmSpellClick(frame, prefix, suffix, Known(spec.spell) or spec.spell)
      elseif P.ID(spec.slot) then
        P.SetClickAttr(frame, prefix, suffix, "type", "action")
        P.SetClickAttr(frame, prefix, suffix, "typerelease", "action")
        P.SetClickAttr(frame, prefix, suffix, "action", spec.slot)
      end
    end
    end
  end
end

-- A CLICK binding keeps the physical modifiers. Copy type onto shift/ctrl/alt
-- so Shift-M5 still casts instead of looking for a missing shift-type1.
function P.ArmModifiedCast(frame)
  if not frame or Locked() then return end
  local typ = frame:GetAttribute("type")
  if not typ then return end
  -- Only LeftButton (suffix 1). Unsuffixed shift-action/shift-macro would
  -- steal Shift-M4/M5 from the hardware click attributes.
  for _, prefix in ipairs({"shift-", "ctrl-", "alt-"}) do
    frame:SetAttribute(prefix .. "type1", typ)
    frame:SetAttribute(prefix .. "typerelease1", typ)
    for _, attr in ipairs({"spell", "item", "macro", "macrotext", "action"}) do
      local value = frame:GetAttribute(attr)
      frame:SetAttribute(prefix .. attr .. "1", value)
    end
  end
end

-- Rootwalking cannot fire while Ghost Wolf is up. Drop form before UseAction.
function P.ArmCancelForm(frame, ability)
  local name = ability and (ability.name or ability.label)
  if not frame or not P.UsesActionOverride(name) then return end
  frame:SetScript("PreClick", function()
    if Locked() then return end
    if GetShapeshiftForm and GetShapeshiftForm() ~= 0 then pcall(CancelShapeshiftForm) end
  end)
end

local function AllocHiddenSlot(bindId)
  local info = hiddenByBindId[bindId]
  if info then return info end
  -- Real action slots, addressed by ACTIONBUTTON1-12. Occupied user slots
  -- are never allocated except reserved mouse extras on 8-12.
  local slot
  local bindKey = tostring(bindId or ""):match("^key:(.+)$")
  local reserved = bindKey and MOUSE_HARDWARE[bindKey]
  if reserved and P.ID(reserved.slot) and reserved.slot >= 8 and reserved.slot <= 12 then
    slot = reserved.slot
  else
    local taken = {}
    for _, spec in pairs(MOUSE_HARDWARE) do
      if P.ID(spec.slot) and spec.slot >= 8 then taken[spec.slot] = true end
    end
    -- M4/M5 mouse keys must land on 8-12 so the bind can be ACTIONBUTTON*
    -- (the only command mouse buttons reliably fire). MMB extras prefer 13-24
    -- so they do not eat those five slots. Never use 61-72 (visible bar 6).
    local id = tostring(bindId or "")
    local mouse45 = id:find("BUTTON4", 1, true) or id:find("BUTTON5", 1, true)
    local ranges = mouse45 and {{8, 12}} or {{13, 24}, {8, 12}}
    for _, range in ipairs(ranges) do
      for candidate = range[1], range[2] do
        if not taken[candidate] then
          local kind, id = GetActionInfo(candidate)
          local owned = ShamanBindsDB.hiddenSlots[candidate]
          local macroName = kind == "macro" and GetMacroInfo(id)
          local ours = owned or (type(macroName) == "string" and macroName:sub(1, 3) == "SB_")
          local free = not kind or ours
          if mouse45 then
            -- Claim 8-12 even when a leftover spell is sitting there. Those
            -- buttons are hidden; mouse extras have nowhere else that ACTIONBUTTON
            -- can reach.
            free = true
          else
            free = not kind or (owned and macroName == owned
              and ShamanBindsDB.macroNames["SB" .. candidate] == owned)
          end
          if not KEEP[candidate] and free then
            slot = candidate
            break
          end
        end
      end
      if slot then break end
    end
  end
  -- Full bars are normal. A saved macro can be addressed without an action slot.
  hiddenSlotN = hiddenSlotN + 1
  if slot then KEEP[slot] = true end
  local name = slot and ("ShamanBindsAction_" .. slot) or ("ShamanBindsMacro_" .. hiddenSlotN)
  local button = _G[name] or CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
  P.ClearAction(button)
  if slot then
    button:SetAttribute("type", "action")
    button:SetAttribute("typerelease", "action")
    button:SetAttribute("action", slot)
  end
  button:RegisterForClicks("AnyDown", "AnyUp")
  button:SetSize(1, 1)
  button:SetAlpha(0)
  button:EnableMouse(false)
  button:Show()
  P.ArmModifiedCast(button)
  info = {slot = slot, binding = "CLICK " .. name .. ":LeftButton", frame = name,
    macroName = not slot and ("Helper" .. hiddenSlotN) or nil}
  hiddenByBindId[bindId] = info
  return info
end

function P.PlaceHelper(info, icon, body, pulse)
  if info.slot then
    return PlaceMacro(info.slot, "SB" .. info.slot, icon, body, pulse, info.frame)
  end
  local index = EnsureMacro(info.macroName, icon, body)
  if not index then return false end
  info.macroIndex = index
  local button = _G[info.frame]
  button:SetAttribute("type", "macro")
  button:SetAttribute("typerelease", "macro")
  button:SetAttribute("macro", index)
  P.ArmModifiedCast(button)
  return true
end

local function HidePinnedActionButton(frameName)
  local f = _G[frameName]
  if not f or Locked() then return end
  f:SetAlpha(0)
  f:EnableMouse(false)
  -- Secure click targets stay shown; they do not depend on Blizzard bar visibility.
end

-- Ground-targeted: totems, plus named exceptions that are not "* Totem".
-- Do not match loose words like "Bloom" — that false-positives other spells.
local GROUND_EXCEPTIONS = {
  ["Thorn Bloom"] = true,
  ["Earthquake"] = true,
}

local function IsGroundName(name)
  if not name or name == "" then return false end
  return GROUND_EXCEPTIONS[name] or name:find("Totem", 1, true) ~= nil
end

local function AbilityCastStyle(ability)
  if not ability then return "plain" end
  local body = ability.macrotext
  if type(body) == "string" then
    if body:find("@cursor", 1, true) then return "cursor" end
    if body:find("@player", 1, true) then return "player" end
    return "plain"
  end
  if IsGroundName(ability.name or ability.label) then return "cursor" end
  return "plain"
end

local function FirstActionLine(body)
  if type(body) ~= "string" then return nil end
  return body:match("(/cast[^\r\n]+)") or body:match("(/use[^\r\n]+)")
end

local function InjectMod(mod, line)
  if not mod or not line then return nil end
  local cmd, rest = line:match("^(/cast)%s+(.+)$")
  if not cmd then cmd, rest = line:match("^(/use)%s+(.+)$") end
  if not cmd or not rest then return nil end
  if rest:sub(1, 1) == "[" then
    local cond, tail = rest:match("^%[(.-)%]%s*(.*)$")
    if not cond then return line end
    if cond:find("mod:", 1, true) then return cmd .. " [" .. cond .. "] " .. tail end
    return cmd .. " [mod:" .. mod .. "," .. cond .. "] " .. tail
  end
  return cmd .. " [mod:" .. mod .. "] " .. rest
end

local function WithNomod(line)
  if not line then return nil end
  local cmd, rest = line:match("^(/cast)%s+(.+)$")
  if not cmd then cmd, rest = line:match("^(/use)%s+(.+)$") end
  if not cmd or not rest then return line end
  if rest:sub(1, 1) == "[" then
    local cond, tail = rest:match("^%[(.-)%]%s*(.*)$")
    if not cond then return line end
    if cond:find("nomod", 1, true) then return line end
    return cmd .. " [nomod," .. cond .. "] " .. tail
  end
  return cmd .. " [nomod] " .. rest
end

local function TPrimaryAbility()
  local t = ShamanBindsDB.custom and ShamanBindsDB.custom.T
  if t and t.primary then return t.primary end
  return { name = "Wind Rush Totem", label = "Wind Rush Totem", icon = 538576 }
end

local function MMBNomodName()
  local a = TPrimaryAbility()
  return (a and (a.name or a.label)) or "Wind Rush Totem"
end

local function NomodActionLine(ability)
  if not ability then return "/cast [@cursor] Wind Rush Totem" end
  if ability.macrotext then
    return FirstActionLine(ability.macrotext) or "/cast [@cursor] Wind Rush Totem"
  end
  if ability.itemID then
    return "/use item:" .. ability.itemID
  end
  local name = ability.name or ability.label
  if not name then return "/cast [@cursor] Wind Rush Totem" end
  if AbilityCastStyle(ability) == "cursor" or IsGroundName(name) then
    return "/cast [@cursor] " .. name
  end
  return "/cast " .. name
end

-- Wind Rush on slot 5 is @cursor. Shift+wheel are their own binds.
-- Plain mouse wheel and Ctrl-wheel are left for camera zoom.
local MMB_CHORD = {
}

local function NoteChordLine(bindKey, line)
  if bindKey and line and MMB_CHORD[bindKey] then
    chordLine[bindKey] = line
  end
end

local function HardenActionButton5()
  -- Cursor targeting is explicit in the slot-5 totem macro. Do not modify the
  -- Blizzard ActionButton5 widget to enforce it.
end

local function ConfigureMMBChord()
  -- Slot 5 is Wind Rush @cursor. The key is Shift-WheelUp, so do not wrap
  -- [nomod] — that would swallow the cast while Shift is held.
  local ability = TPrimaryAbility()
  if not ability or Locked() then return end
  if ability.sba then
    local id = (C_AssistedCombat and C_AssistedCombat.GetActionSpell and C_AssistedCombat.GetActionSpell()) or SBA_ID
    PlaceID(5, id)
    HardenActionButton5()
    return
  end
  local name = ability.name or ability.label or "Wind Rush Totem"
  local nomod = FirstActionLine(ability.macrotext) or NomodActionLine(ability)
  local body = "#showtooltip " .. name .. "\n" .. nomod
  PlaceMacro(5, P.MOUSE_MACRO[5] or "RushTotem", ability.icon or 538576, body, name)
  HardenActionButton5()
end

local function SanitizeSavedBinds()
  P.EnsureDB()
  if P.IsFamilyMode() then return end
  P.PruneOrphanSBMacros()
  -- Ctrl-Q is unused (no Hex). Drop the old keyed slot so apply cannot restore it.
  if ShamanBindsDB.binds then ShamanBindsDB.binds["key:CTRL-Q"] = nil end
  if ShamanBindsDB.mods then ShamanBindsDB.mods["CTRL-Q"] = nil end
  -- Ground family left MMB for Shift/Ctrl+wheel. Drop stale keys so apply
  -- uses the new defaults instead of restoring BUTTON3.
  do
    local b = ShamanBindsDB.binds
    if b then
      b["key:SHIFT-BUTTON3"] = nil
      b["key:CTRL-BUTTON3"] = nil
      b["key:ALT-BUTTON3"] = nil
      local face = b["bar:5"]
      if face == "BUTTON3" or face == "T" or face == "SHIFT-BUTTON3"
        or face == "SHIFT-MWHEELUP" then b["bar:5"] = nil end
      b["key:SHIFT-MWHEELUP"] = nil
      b["key:SHIFT-MWHEELDOWN"] = nil
      b["key:CTRL-MWHEELUP"] = nil
      if b["spell:Heroism"] and not b["key:R"] then b["key:R"] = b["spell:Heroism"] end
      b["spell:Heroism"] = nil
      b["key:4"] = nil
      b["key:SHIFT-R"] = nil
      b["key:CTRL-R"] = nil
    end
    local bb = ShamanBindsDB.barBinds
    if bb then
      local k = bb["ACTIONBUTTON5"]
      if k == "BUTTON3" or k == "T" then bb["ACTIONBUTTON5"] = nil end
    end
    local mods = ShamanBindsDB.mods
    if mods then
      mods["BUTTON3"] = nil
      mods["SHIFT-BUTTON3"] = nil
      mods["CTRL-BUTTON3"] = nil
      mods["4"] = nil
      mods["SHIFT-R"] = nil
      mods["CTRL-R"] = nil
    end
    if b then b["bar:7"] = nil end
    if bb then bb["ACTIONBUTTON7"] = nil end
    -- Recuperate / Skyfury / Lightning Shield moved to click. RebindAll
    -- only assigns live keys, so drop the leftover hardware binds first.
    if not Locked() then
      pcall(SetBinding, "4")
      pcall(SetBinding, "SHIFT-R")
      pcall(SetBinding, "CTRL-R")
    end
  end
end



-- ============================== KEYBINDS ==============================

local BAR_BINDS = {
  ["Q"] = "ACTIONBUTTON1",
  ["E"] = "ACTIONBUTTON3",
  ["C"] = "ACTIONBUTTON4",
  ["SHIFT-MOUSEWHEELUP"] = "ACTIONBUTTON5",
  ["BUTTON4"] = "ACTIONBUTTON6",
  ["BUTTON5"] = "ACTIONBUTTON8",
  ["SHIFT-C"] = "TOGGLECHARACTER0",
}

local UNBIND = {
  "R", "F", "Z", "X", "V", "T", "G",
  "1", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=",
  "SHIFT-R", "SHIFT-F", "SHIFT-Z", "SHIFT-X", "SHIFT-V", "SHIFT-G",
  "SHIFT-1", "SHIFT-3", "SHIFT-4",
  "CTRL-Q", "CTRL-R", "CTRL-C",
}

-- ============================== ABILITY TEXTS ==============================

-- Favorite mount. MMB is Earth Elemental on its own bind, not this body.
local MOUNT_TEXT = "/dismount [mounted]\n/run if not IsMounted() and not InCombatLockdown() then C_MountJournal.SummonByID(0) end"

-- Spam-friendly flee kit (Shift-M4 extra). Spirit Walk is off-GCD.
local SPRINT_BODY = [[#showtooltip Ghost Wolf
/cast Spirit Walk
/cast [@player] Wind Rush Totem
/cast [noform] Ghost Wolf]]

local PURGE_TEXT = "#showtooltip Purge\n/cast [@mouseover,harm,nodead][] Purge"
local SHEAR_TEXT = "#showtooltip Wind Shear\n/cast [@mouseover,harm,nodead][] Wind Shear"
local LUNGE_TEXT = "#showtooltip Feral Lunge\n/cast [@mouseover,harm,nodead][] Feral Lunge"
local GUST_TEXT = "#showtooltip Gust of Wind\n/cast Gust of Wind"
local SURGE_TEXT = "#showtooltip Healing Surge\n/cast [mod:alt,@player][@mouseover,help,nodead][help,nodead][@player] Healing Surge"
local CHAIN_HEAL_TEXT = "#showtooltip Chain Heal\n/cast [mod:alt,@player][@mouseover,help,nodead][help,nodead][@player] Chain Heal"
local SHIELD_TEXT = "#showtooltip Earth Shield\n/cast [@mouseover,help,nodead][] Earth Shield"
local WALK_TEXT = "#showtooltip Spirit Walk\n/cast Spirit Walk"
local REZ_TEXT = "#showtooltip Ancestral Spirit\n/cast [@mouseover,help,dead][@mouseover,help,nodead][] Ancestral Spirit"
local RECUP_TEXT = "#showtooltip Recuperate\n/cast Recuperate"
local SKYFURY_TEXT = "#showtooltip Skyfury\n/cast Skyfury"
local LSHIELD_TEXT = "#showtooltip Lightning Shield\n/cast Lightning Shield"
local FARSIGHT_TEXT = "#showtooltip Far Sight\n/cast [@cursor] Far Sight"
local WWALK_TEXT = "#showtooltip Water Walking\n/cast [@mouseover,help,nodead][] Water Walking"

-- ====================== INVISIBLE MODIFIER-LAYER BUTTONS ======================
-- Buttons are named by a stable bindId (spell:Feral Lunge), not by the key.
-- Quick Keybind mode rewrites the key; the click target stays the same.

local clickButtons = {}

local function ItemBindId(item)
  if type(item) ~= "table" then return nil end
  if item.bindId then return item.bindId end
  -- Keyed slots stay on the same hidden Blizzard button when the spell changes.
  if item.bindKey then return "key:" .. item.bindKey end
  if item.itemID then return "item:" .. tostring(item.itemID) end
  if item.sba then return "sba" end
  if item.spell then return "spell:" .. tostring(item.spell[1]) end
  if item.macrotext then return "macro:" .. tostring(item.macrotext) end
  if item.name then return "spell:" .. tostring(item.name) end
  if item.itemID then return "item:" .. tostring(item.itemID) end
  if item.label then return "label:" .. tostring(item.label) end
end

local function CastMacro(name, style)
  if not name or name == "" then return nil end
  if style == "cursor" then
    return "#showtooltip " .. name .. "\n/cast [@cursor] " .. name
  end
  if style == "player" then
    return "#showtooltip " .. name .. "\n/cast [@player] " .. name
  end
  return "#showtooltip " .. name .. "\n/cast " .. name
end

function P.MountInfo(mountID)
  mountID = P.ID(mountID)
  if not mountID or not C_MountJournal or not C_MountJournal.GetMountInfoByID then return nil end
  local ok, name, spellID, icon = pcall(C_MountJournal.GetMountInfoByID, mountID)
  if not ok or not P.Text(name) then return nil end
  return { name = name, spellID = P.ID(spellID), icon = icon or 132250 }
end

function P.MountAbility(mountID)
  local info = P.MountInfo(mountID)
  if not info then return nil end
  return {
    kind = "mount", mountID = mountID, name = info.name, label = info.name,
    id = info.spellID, icon = info.icon,
    macrotext = "#showtooltip " .. info.name .. "\n/dismount [mounted]\n/cast " .. info.name,
  }
end

function NormalizeAbility(ab)
  if type(ab) ~= "table" then return nil end
  local itemID, id, mountID = P.ID(ab.itemID), P.ID(ab.id), P.ID(ab.mountID)
  if mountID and (not P.Text(ab.name) or not id) then
    local info = P.MountInfo(mountID)
    if info then
      ab = {
        kind = "mount", mountID = mountID, name = P.Text(ab.name) or info.name,
        label = P.Text(ab.label) or info.name, id = id or info.spellID,
        icon = ab.icon or info.icon, macrotext = ab.macrotext, itemID = ab.itemID, sba = ab.sba,
      }
      id = P.ID(ab.id)
    end
  end
  local body = P.Text(ab.macrotext)
  local sba = ab.sba == true
  if ab.itemID ~= nil and not itemID then return nil end
  if ab.macrotext ~= nil and not body then return nil end
  local name = P.Text(ab.name) or P.Text(ab.label)
  if not name and id then name = SpellName(id) end
  if not name and itemID then name = "Item " .. itemID end
  if not name and sba then name = "Assisted Rotation" end
  if not name then return nil end
  local icon = (P.ID(ab.icon) or P.Text(ab.icon)) or (id and SpellIcon(id)) or 134400
  if not body and mountID and name then
    body = "#showtooltip " .. name .. "\n/dismount [mounted]\n/cast " .. name
  end
  local result = {
    kind = mountID and "mount" or itemID and "item" or body and "macro" or sba and "sba" or "spell",
    name = name, label = P.Text(ab.label) or name, id = id, itemID = itemID,
    mountID = mountID, macrotext = body, sba = sba or nil, icon = icon,
  }
  if not body and not itemID and not sba and not mountID and IsGroundName(name) then
    result.macrotext = CastMacro(name, "cursor")
  end
  return result
end

function P.TrinketDefaultKey(slot)
  if slot == 13 then return "2" end
  if slot == 14 then return "3" end
end

function P.EvictKeysFromBinds(binds, barBinds, keys)
  if type(keys) ~= "table" then return end
  if type(binds) == "table" then
    for id, key in pairs(binds) do
      if keys[key] and not tostring(id):find("^equipment:", 1) then
        binds[id] = ""
      end
    end
  end
  if type(barBinds) == "table" then
    for action, key in pairs(barBinds) do
      if keys[key] then barBinds[action] = nil end
    end
  end
end

function P.ClaimTrinketKeys(db)
  db = db or ShamanBindsDB
  if type(db) ~= "table" or db.trinketKeyRevision == 1 then return end
  db.trinketKeyRevision = 1
  local keys = { ["2"] = true, ["3"] = true }
  local function claim(binds, barBinds)
    if type(binds) == "table" then
      binds["equipment:13"] = nil
      binds["equipment:14"] = nil
    end
    P.EvictKeysFromBinds(binds, barBinds, keys)
  end
  claim(db.binds, db.barBinds)
  for _, profile in pairs(db.profiles or {}) do
    if type(profile) == "table" then
      claim(profile.binds, profile.barBinds)
    end
  end
end

function P.EnsureDB()
  if type(ShamanBindsDB) ~= "table" then ShamanBindsDB = {} end
  local db = ShamanBindsDB
  for _, key in ipairs({"custom", "binds", "barBinds", "mods", "pos", "profiles", "macroNames", "hiddenSlots"}) do
    if type(db[key]) ~= "table" then db[key] = {} end
  end
  for _, field in ipairs({"binds", "barBinds", "macroNames"}) do
    for k, v in pairs(db[field]) do
      if type(k) ~= "string" or type(v) ~= "string" then db[field][k] = nil end
    end
  end
  for key, name in pairs(db.macroNames) do
    local prefix = "SB_" .. key
    if name:sub(1, #prefix) ~= prefix or not name:sub(#prefix + 1):match("^%d*$") then
      db.macroNames[key] = nil
    end
  end
  for k, v in pairs(db.mods) do
    db.mods[k] = P.Text(k) and NormalizeAbility(v) or nil
  end
  for tag, custom in pairs(db.custom) do
    if not P.Text(tag) or type(custom) ~= "table" then
      db.custom[tag] = nil
    else
      custom.primary = NormalizeAbility(custom.primary)
      local added, indices = {}, {}
      if type(custom.added) == "table" then
        for k in pairs(custom.added) do if P.ID(k) then indices[#indices + 1] = k end end
        table.sort(indices)
        for _, k in ipairs(indices) do
          local a = NormalizeAbility(custom.added[k])
          if a then added[#added + 1] = a end
        end
      end
      custom.added = added
      if type(custom.hidden) ~= "table" then custom.hidden = {} end
      for k, v in pairs(custom.hidden) do
        if not P.Text(k) or v ~= true then custom.hidden[k] = nil end
      end
      if custom.order ~= nil then
        local order = {}
        if type(custom.order) == "table" then
          for _, n in ipairs(custom.order) do if P.Text(n) then order[#order + 1] = n end end
        end
        custom.order = order
      end
    end
  end
  local anchors = {TOP=true, BOTTOM=true, LEFT=true, RIGHT=true, CENTER=true,
    TOPLEFT=true, TOPRIGHT=true, BOTTOMLEFT=true, BOTTOMRIGHT=true}
  for key, pos in pairs(db.pos) do
    if type(pos) ~= "table" or not anchors[pos[1]] or not anchors[pos[2]]
      or not P.Number(pos[3]) or not P.Number(pos[4]) then db.pos[key] = nil end
  end
  for name, profile in pairs(db.profiles) do
    if not P.Text(name) or type(profile) ~= "table" then db.profiles[name] = nil end
  end
  for slot, name in pairs(db.hiddenSlots) do
    if not P.ID(slot) or not P.Text(name) then db.hiddenSlots[slot] = nil end
  end
  if not P.Text(db.activeProfile) then db.activeProfile = nil end
  if type(db.totemPos) ~= "table" then db.totemPos = {} end
  for i, pos in pairs(db.totemPos) do
    if type(pos) ~= "table" or not P.Number(pos.x) or not P.Number(pos.y) then db.totemPos[i] = nil end
  end
  if db.totemScaleRev ~= 1 then
    for _, pos in pairs(db.totemPos) do
      if type(pos) == "table" and P.Number(pos.y) then pos.y = pos.y * 0.75 end
    end
    db.totemScaleRev = 1
  end
  db.applied = db.applied == true
  db.hideBar1 = db.hideBar1 == true
  if db.hideConsoleMounted == nil then db.hideConsoleMounted = true end
  db.hideConsoleMounted = db.hideConsoleMounted ~= false
  if db.useMountBar == nil then db.useMountBar = true end
  db.useMountBar = db.useMountBar ~= false
  if db.hideAutoManaged == nil then db.hideAutoManaged = true end
  db.hideAutoManaged = db.hideAutoManaged ~= false
  if db.warnBinds == nil then db.warnBinds = true end
  db.warnBinds = db.warnBinds ~= false
  db.schemaVersion = 2
  P.ClaimTrinketKeys(db)
  if db.familyMode ~= "families" and db.familyMode ~= "pocket"
    and db.familyMode ~= "prime" and db.familyMode ~= "farseer" and db.familyMode ~= "legacy" then
    if db.applied then
      db.familyMode = "legacy"
    else
      db.familyMode = "prime"
      db.familyRevision = 1
      if not P.Text(db.activeProfile) then db.activeProfile = "Prime" end
    end
  end
  if type(db.profiles.Pocket) ~= "table" then
    db.profiles.Pocket = {
      familyMode = "pocket",
      custom = {},
      pos = {},
      binds = {},
      barBinds = {},
      mods = {},
    }
  end
  if type(db.profiles.Prime) ~= "table" then
    db.profiles.Prime = {
      familyMode = "prime",
      custom = {},
      pos = {},
      binds = {},
      barBinds = {},
      mods = {},
    }
  end
  if type(db.profiles.Farseer) ~= "table" then
    db.profiles.Farseer = {
      familyMode = "farseer",
      custom = {},
      pos = {},
      binds = {},
      barBinds = {},
      mods = {},
    }
  end
end

P.EnsureDB()

function P.AbilityKey(a)
  a = NormalizeAbility(a)
  if not a then return nil end
  if a.mountID then return "mount:" .. tostring(a.mountID) end
  if a.itemID then return "item:" .. tostring(a.itemID) end
  if a.sba then return "sba" end
  if a.macrotext then return "macro:" .. a.macrotext end
  if a.id then return "spell:" .. tostring(a.id) end
  local name = P.Text(a.name) or P.Text(a.label)
  return name and "name:" .. name
end



-- Totems / @cursor must click a real Blizzard action slot, not an addon button.
local function RouteToHiddenSlot(r, bindNow)
  if not r or r.blizzardSlot or r.macroIndex then return r end
  if not NeedsBlizzardSlot(r) and not P.IsMouseKey(r.bindKey) then return r end
  local bindId = r.bindId or ItemBindId(r) or ("safe:" .. tostring(r.name or r.label or "x"))
  r.bindId = bindId
  local info = AllocHiddenSlot(bindId)
  if bindNow and not Locked() then
    local body = r.macrotext
    local name = r.name or r.label
    if not body and name then
      local ground = name:find("Totem", 1, true) or name == "Thorn Bloom"
      body = CastMacro(name, ground and "cursor" or "plain")
    end
    if P.UsesActionOverride(name) and info.slot then
      local placeId = r.id or P.SPELL_ID[name]
      if P.PlayerKnows(P.SPELL_ID["Rootwalking"]) then placeId = P.SPELL_ID["Rootwalking"] end
      if placeId then
        PlaceID(info.slot, placeId)
        HidePinnedActionButton(info.frame)
      end
    elseif body then
      P.PlaceHelper(info, r.icon or r.iconFile or 134400, body, name)
      HidePinnedActionButton(info.frame)
    end
  end
  r.blizzardSlot = info.slot
  r.macroIndex = info.macroIndex
  r.commandName = info.binding
  return r
end

-- Put whatever the tab is showing onto the same action-bar slot the key fires.
local function PlacePrimaryOnBar(slot, ability)
  if Locked() or not P.ID(slot) or type(ability) ~= "table" then return false end
  if ability.itemID then
    return PlaceMacro(slot, "SBBar" .. slot, ability.icon or 134400, "/use item:" .. ability.itemID)
  end
  if ability.sba then
    local id = (C_AssistedCombat and C_AssistedCombat.GetActionSpell and C_AssistedCombat.GetActionSpell()) or SBA_ID
    return PlaceID(slot, id)
  end
  if ability.macrotext then
    return PlaceMacro(slot, "SBBar" .. slot, ability.icon or 134400, ability.macrotext, ability.name or ability.label)
  end
  local name = ability.name or ability.label
  local id = ability.id or (name and BOOK[name])
  if name and IsGroundName(name) then
    return PlaceMacro(slot, "SBBar" .. slot, ability.icon or SpellIcon(id), CastMacro(name, "cursor"), name)
  end
  if id then return PlaceID(slot, id) end
  if name then
    return PlaceMacro(slot, "SBBar" .. slot, ability.icon or 134400, CastMacro(name, AbilityCastStyle(ability)), name)
  end
  return false
end

-- Rewrite a stock key-item from a dragged ability. Targeting comes from
-- the dropped ability, not from whatever used to live on this key.
local function OverrideIcon(ov)
  if not ov then return 134400 end
  return ov.icon or (ov.id and SpellIcon(ov.id)) or 134400
end

local function ApplyModOverride(item)
  if not item or not item.bindKey then return item end
  local ov = ShamanBindsDB.mods and ShamanBindsDB.mods[item.bindKey]
  if not ov then return item end
  if ov.sba then
    item.sba, item.spell, item.macrotext, item.itemID = true, nil, nil, nil
    item.label, item.name, item.iconFile = ov.label, ov.name, ov.icon
    item.requires, item.covers = nil, nil
    return item
  end
  item.sba = nil
  local style = AbilityCastStyle(ov)
  local icon = OverrideIcon(ov)
  if ov.macrotext then
    item.macrotext, item.spell, item.itemID = ov.macrotext, nil, ov.itemID
    item.label = ov.label or ov.name or item.label
    item.iconFile, item.iconOf = icon, ov.name or ov.label
    item.requires, item.covers = nil, ov.name and { ov.name } or item.covers
    return item
  end
  if ov.itemID then
    item.macrotext = "/use item:" .. ov.itemID
    item.itemID, item.spell = ov.itemID, nil
    item.label = ov.label or item.label
    item.iconFile, item.iconOf = icon, nil
    item.requires = nil
    return item
  end
  local name = ov.name or ov.label
  if not name then return item end
  if style == "cursor" or IsGroundName(name) then style = "cursor" end
  item.macrotext = CastMacro(name, style)
  item.spell, item.itemID = nil, nil
  item.label, item.iconOf, item.iconFile = ov.label or name, name, icon
  item.covers, item.requires = { name }, nil
  return item
end

local function CanPlaceOnKey(bindKey, ability, nomodName)
  return P.Text(bindKey) ~= nil and NormalizeAbility(ability) ~= nil
end

local function SetModAbility(bindKey, ability, quiet, nomodName)
  ability = NormalizeAbility(ability)
  if Locked() or not P.Text(bindKey) or not ability then return false end
  if not CanPlaceOnKey(bindKey, ability, nomodName) then return false end
  ShamanBindsDB.mods = ShamanBindsDB.mods or {}
  ShamanBindsDB.mods[bindKey] = NormalizeAbility(ability)
  if not quiet then
    local name = ability.name or ability.label
    print("|cff0070ddShaman Binds:|r " .. ShortKey(bindKey) .. " is now |cffffffff" .. (name or "?") .. "|r")
  end
  return true
end

local function EffectiveKey(bindId, defaultKey)
  local saved = ShamanBindsDB.binds and ShamanBindsDB.binds[bindId]
  if saved == "" then return nil end
  if saved then return saved end
  return defaultKey
end

local function EnsureClickButton(bindId)
  local token = bindId:gsub(".", function(c) return string.format("%02x", string.byte(c)) end)
  local name = "ShamanBindsKey_" .. token
  local b = clickButtons[bindId]
  if not b then
    b = _G[name] or CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    b:SetSize(1, 1)
    b:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    b:SetAlpha(0)
    b:SetAttribute("pressAndHoldAction", true)
    b:RegisterForClicks("AnyDown", "AnyUp")
    b:EnableMouse(false)
    b:Show()
    clickButtons[bindId] = b
  end
  return b, name
end

local function SetupClickButton(bindId, spec)
  if Locked() or not P.Text(bindId) or type(spec) ~= "table" then return nil end
  local b, name = EnsureClickButton(bindId)
  P.ClearAction(b)
  if spec.macroIndex then
    b:SetAttribute("type", "macro")
    b:SetAttribute("typerelease", "macro")
    b:SetAttribute("macro", spec.macroIndex)
  elseif spec.macrotext then
    b:SetAttribute("type", "macro")
    b:SetAttribute("typerelease", "macro")
    b:SetAttribute("macrotext", spec.macrotext)
  elseif spec.itemID then
    b:SetAttribute("type", "item")
    b:SetAttribute("typerelease", "item")
    b:SetAttribute("item", "item:" .. spec.itemID)
    b:SetScript("PostClick", nil)
  elseif spec.sba then
    local id = (C_AssistedCombat and C_AssistedCombat.GetActionSpell and C_AssistedCombat.GetActionSpell()) or SBA_ID
    b:SetAttribute("type", "spell")
    b:SetAttribute("typerelease", "spell")
    b:SetAttribute("spell", id)
    b:SetScript("PostClick", nil)
  else
    local spell = spec.name
    if not spell and spec.spell then spell = Known(unpack(spec.spell)) end
    if spell then
      b:SetAttribute("type", "spell")
      b:SetAttribute("typerelease", "spell")
      b:SetAttribute("spell", spell)
    end
  end
  P.ArmModifiedCast(b)
  return b, name
end

local function ClickCommand(bindId)
  local _, name = EnsureClickButton(bindId)
  return "CLICK " .. name .. ":LeftButton"
end

local function ClearCommandKeys(command)
  if not command then return end
  for _, key in ipairs({GetBindingKey(command)}) do
    SetBinding(key)
    if P.IsChatKey(key) then P.RestoreChatKeys() end
  end
end

function P.IsChatKey(key)
  return key == "ENTER" or key == "NUMPADENTER" or key == "/"
end

-- Apply used to leave ENTER and / as NONE, which kills chat.
function P.RestoreChatKeys()
  if Locked() then return false end
  local want = { ENTER = "OPENCHAT", NUMPADENTER = "OPENCHAT", ["/"] = "OPENCHATSLASH" }
  local changed = false
  for key, cmd in pairs(want) do
    local have = GetBindingAction(key)
    if have ~= cmd then
      local ok, accepted = pcall(SetBinding, key, cmd)
      if ok and accepted then changed = true end
    end
  end
  return changed
end

local function KeyOwnedByBar(key, bindId)
  if not key then return false end
  for id, k in pairs(ShamanBindsDB.binds or {}) do
    if k == key and id ~= bindId and tostring(id):find("^bar:") then return true end
  end
  for _, action in pairs(BAR_BINDS) do
    if type(action) == "string" and action:find("ACTIONBUTTON", 1, true) then
      if ShamanBindsDB.barBinds and ShamanBindsDB.barBinds[action] == key then return true end
    end
  end
end

local function KeyTaken(key, bindId)
  if not key then return false end
  if KeyOwnedByBar(key, bindId) then return true end
  for id, k in pairs(ShamanBindsDB.binds or {}) do
    if k == key and id ~= bindId then return true end
  end
end

local function ApplyClickBind(bindId, defaultKey)
  local _, name = EnsureClickButton(bindId)
  local command = "CLICK " .. name .. ":LeftButton"
  ClearCommandKeys(command)
  local key = EffectiveKey(bindId, defaultKey)
  if key and not KeyTaken(key, bindId) then SetBindingClick(key, name) end
end

-- item = {bindKey=, spell={names} | macrotext=, requires=}
local function BindKeyTo(item, bindNow)
  ApplyModOverride(item)
  if item.spell and not item.macrotext and (NeedsBlizzardSlot(item) or P.IsMouseKey(item.bindKey)) then
    local spell, id = Known(unpack(item.spell))
    if spell and P.UsesActionOverride(spell) then
      -- Named /cast misses the Return override. Park the base spell on a
      -- real action slot so UseAction fires Rootwalking: Return.
      local bindId = ItemBindId(item)
      if bindId then
        local info = AllocHiddenSlot(bindId)
        if bindNow and info.slot then
          local placeId = id or P.SPELL_ID[spell]
          if P.PlayerKnows(P.SPELL_ID["Rootwalking"]) then placeId = P.SPELL_ID["Rootwalking"] end
          if placeId then
            PlaceID(info.slot, placeId)
            HidePinnedActionButton(info.frame)
          end
        end
      end
      item.label = item.label or spell
      item.iconFile = item.iconFile or SpellIcon(id, spell)
      return true
    elseif spell then
      item.macrotext = CastMacro(spell, IsGroundName(spell) and "cursor" or "plain")
      item.label = item.label or spell
      item.iconFile = item.iconFile or SpellIcon(id, spell)
    end
  end
  NoteChordLine(item.bindKey, FirstActionLine(item.macrotext))
  local bindId = ItemBindId(item)
  if not bindId then return end
  if item.macrotext then
    if item.requires and not Known(item.requires) then
      if item.bindKey then chordLine[item.bindKey] = nil end
      -- An unavailable spell must not clear a key now owned by another command.
      return nil
    end
    local hw = item.bindKey and MOUSE_HARDWARE[item.bindKey]
    if NeedsBlizzardSlot(item)
      or (hw and P.ID(hw.slot))
      or (item.bindKey and ShamanBindsDB.mods and ShamanBindsDB.mods[item.bindKey]) then
      local info = AllocHiddenSlot(bindId)
      if bindNow then
        local icon = item.iconFile or 134400
        local pulse = item.label or (item.covers and item.covers[1])
        P.PlaceHelper(info, icon, item.macrotext, pulse)
        HidePinnedActionButton(info.frame)
        local key = EffectiveKey(bindId, item.bindKey)
        -- Bound centrally after every target is configured.
      end
      return true
    end
    if item.savedMacroName then
      local index
      if bindNow then index=EnsureMacro(item.savedMacroName,item.iconFile or 134400,item.macrotext)
      else local _,name=P.NamedMacroCommand(item.savedMacroName);index=name and MacroIndex(name) end
      if not index or index==0 then return nil end
      local info=hiddenByBindId[bindId] or {}
      info.macroIndex,info.binding=index,P.NamedMacroCommand(item.savedMacroName)
      hiddenByBindId[bindId]=info
      return true
    end
    SetupClickButton(bindId, item)
    -- Bindings are reconciled after the complete layout has been built.
    return true
  elseif item.spell then
    local spell, id = Known(unpack(item.spell))
    if not spell then
      -- An unavailable spell must not clear a key now owned by another command.
      return nil
    end
    SetupClickButton(bindId, { name = spell, spell = item.spell })
    -- Bindings are reconciled after the complete layout has been built.
    return spell, id
  elseif item.itemID then
    SetupClickButton(bindId, item)
    -- Bindings are reconciled after the complete layout has been built.
    return true
  end
end

local function AttachBindMeta(r, defaultKey)
  if r.bindKey then
    r.bindId = "key:" .. r.bindKey
    r.defaultKey = r.bindKey
  else
    r.bindId = r.bindId or ItemBindId(r)
    r.defaultKey = defaultKey or r.defaultKey
  end
  if not r.bindId then return r end
  local hidden = hiddenByBindId[r.bindId]
  if hidden then
    r.blizzardSlot = hidden.slot
    r.macroIndex = hidden.macroIndex
    r.commandName = (P.HardwareCommand and P.HardwareCommand(r.bindKey, hidden.slot, hidden.binding)) or hidden.binding
  else
    SetupClickButton(r.bindId, r)
    r.commandName = ClickCommand(r.bindId)
  end
  -- Hotkeys belong to the slot (bindKey), never the spell that currently sits there.
  if r.bindKey then
    local live = EffectiveKey(r.bindId, r.bindKey)
    r.key = PrettyKey(live)
    r.shortKey = ShortKey(live)
  elseif r.defaultKey then
    local live = EffectiveKey(r.bindId, r.defaultKey)
    r.key = PrettyKey(live)
    r.shortKey = ShortKey(live)
  else
    r.key, r.shortKey = nil, nil
  end
  return r
end


local AssignHoveredBind, ChordFromKey

local function EnsureQKBHighlight(frame)
  if frame._qkbHL then return frame._qkbHL end
  local hl = frame:CreateTexture(nil, "OVERLAY")
  hl:SetAllPoints()
  hl:SetColorTexture(0.27, 0.78, 0.76, 0.22)
  hl:Hide()
  frame._qkbHL = hl
  return hl
end

local MOUSE_TO_BIND = {
  RightButton = "BUTTON2",
  MiddleButton = "BUTTON3",
  Button4 = "BUTTON4",
  Button5 = "BUTTON5",
}

local function MouseChord(button)
  local base = MOUSE_TO_BIND[button]
  if not base then return nil end
  return ChordFromKey(base)
end

local qkbHover

local function OverOwn(frame)
  if not frame or not frame:IsVisible() then return false end
  local l, btm, w, h = frame:GetLeft(), frame:GetBottom(), frame:GetWidth(), frame:GetHeight()
  if not l or not btm or not w or not h then return false end
  local x, y = GetCursorPosition()
  local s = frame:GetEffectiveScale()
  if not s or s == 0 then return false end
  x, y = x / s, y / s
  return x >= l and x <= l + w and y >= btm and y <= btm + h
end

local function WireQuickKeybind(frame, commandName, bindId, defaultKey)
  if not frame then return end
  frame.commandName = commandName
  frame._sbBindId = bindId
  frame._sbDefaultKey = defaultKey
  EnsureQKBHighlight(frame)
  if not frame._qkbHoverWired then
    frame._qkbHoverWired = true
    frame:HookScript("OnEnter", function(self)
      if InQuickKeybind() then qkbHover = self end
    end)
    frame:HookScript("OnLeave", function(self)
      if qkbHover == self then qkbHover = nil end
    end)
  end
  if not frame._qkbWheelWired then
    frame._qkbWheelWired = true
    frame:HookScript("OnMouseWheel", function(_, delta)
      P.HandleQkbWheel(delta)
    end)
  end
  if frame._qkbMouseWired then return end
  frame._qkbMouseWired = true
  frame:HookScript("OnMouseDown", function(self, button)
    if not InQuickKeybind() then return end
    if button == "LeftButton" then return end
    local chord = MouseChord(button)
    if chord == nil then return end
    AssignHoveredBind(self, chord)
  end)
end

local function BindableUnderMouse()
  -- Own-rect first so an open drawer does not steal the big primary tab,
  -- and so hovering the tab does not count as hovering its child extras.
  for _, b in ipairs(allMenuButtons) do
    if b._sbBindId and b:IsShown() and OverOwn(b) then return b end
  end
  for _, tab in pairs(consoleTabs) do
    if tab._sbBindId and OverOwn(tab) then return tab end
  end
  if qkbHover and qkbHover._sbBindId and OverOwn(qkbHover) then return qkbHover end
  if GetMouseFoci then
    local foci = GetMouseFoci()
    if foci then
      for _, f in ipairs(foci) do
        if f and f._sbBindId then return f end
      end
    end
  end
  if GetMouseFocus then
    local f = GetMouseFocus()
    if f and f._sbBindId then return f end
  end
end

local function RefreshBindLabels()
  local function refresh(frame)
    if not (frame._sbBindId and frame.keyText) then return end
    local saved = ShamanBindsDB.binds and ShamanBindsDB.binds[frame._sbBindId]
    -- Recover's "+" is a group mark, not a hotkey, unless BIND set one.
    if (frame.tipKey == "+" or frame.keyText:GetText() == "+") and not P.Text(saved) then
      return
    end
    local key
    if saved == "" then
      key = nil
    elseif P.Text(saved) then
      -- BIND's choice wins. Wheel/mouse live on MACRO/SPELL, so
      -- GetBindingKey(CLICK / ACTIONBUTTON) still shows the old keyboard key.
      key = saved
    else
      key = frame.commandName and GetBindingKey(frame.commandName)
      if not key or key == "" then
        local slot = P.BarSlotOf(frame)
        if slot then key = GetBindingKey("ACTIONBUTTON" .. slot) end
      end
      if (not key or key == "") and P.IsMouseKey(frame._sbDefaultKey) and P.MouseKeyCommand then
        local cmd = P.MouseKeyCommand(frame._sbDefaultKey)
        if cmd then key = GetBindingKey(cmd) end
      end
      if not key or key == "" then key = frame._sbDefaultKey end
    end
    if key and key ~= "" then
      local label = ShortKey(key) or PrettyKey(key) or key
      frame.keyText:SetText(label)
      frame.tipKey = label
      if frame._sbClickHint then frame._sbClickHint:Hide() end
      return
    end
    if frame.keyText:GetText() == "+" then return end
    frame.keyText:SetText("Click")
    frame.tipKey = nil
    if frame._sbClickHint then frame._sbClickHint:Hide() end
  end
  for _, tab in pairs(consoleTabs) do refresh(tab) end
  for _, button in ipairs(allMenuButtons) do refresh(button) end
end

local MOD_ONLY = {
  LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true,
  LALT = true, RALT = true, LMETA = true, RMETA = true,
  SHIFT = true, CTRL = true, ALT = true,
}

local KEY_ALIAS = {
  MiddleButton = "BUTTON3",
  RightButton = "BUTTON2",
  LeftButton = "BUTTON1",
  Button4 = "BUTTON4",
  Button5 = "BUTTON5",
}

function ChordFromKey(key)
  if not key or MOD_ONLY[key] then return nil end
  if key == "ESCAPE" then return false end
  if P.IsChatKey(key) then return nil end
  key = KEY_ALIAS[key] or key
  -- Mouse chords must be BUTTON3 / MOUSEWHEELUP, not "MiddleButton" / "MouseWheel".
  -- Midnight: IsShiftKeyDown / IsControlKeyDown can be secret. Prefer the
  -- MODIFIER_STATE_CHANGED bits, same as the move pads.
  if key:find("BUTTON", 1, true) or key:find("MOUSEWHEEL", 1, true) then
    local parts = {}
    if P.shiftHeld or P.FlagFn(IsShiftKeyDown) then parts[#parts + 1] = "SHIFT" end
    if P.ctrlHeld or P.FlagFn(IsControlKeyDown) then parts[#parts + 1] = "CTRL" end
    if P.altHeld or P.FlagFn(IsAltKeyDown) then parts[#parts + 1] = "ALT" end
    parts[#parts + 1] = key
    return table.concat(parts, "-")
  end
  if CreateKeyChordStringUsingMetaKeyState then
    local chord = CreateKeyChordStringUsingMetaKeyState(key)
    if chord and chord ~= "" then return chord end
  end
  local parts = {}
  if IsShiftKeyDown() then parts[#parts + 1] = "SHIFT" end
  if P.ctrlHeld then parts[#parts + 1] = "CTRL" end
  if IsAltKeyDown() then parts[#parts + 1] = "ALT" end
  parts[#parts + 1] = key
  return table.concat(parts, "-")
end

local lastQkbAssign = { t = 0, id = nil, key = nil }

function P.QkbMouseCommand(frame, key)
  if not frame then return nil end
  local slot = P.BarSlotOf(frame)
  local typ = frame._sbTypeSaved
  if typ == false then typ = nil end
  if typ == nil and frame.GetAttribute then typ = frame:GetAttribute("type") end
  if not slot and typ == "action" and frame.GetAttribute then
    slot = P.ID(frame:GetAttribute("action"))
  end
  if P.ID(slot) then
    return P.ActionBindCommand(slot) or (slot <= 12 and ("ACTIONBUTTON" .. slot)) or nil
  end
  local ab = frame._ability
  if ab then
    if P.Text(ab.savedMacroName) then
      local cmd = P.NamedMacroCommand(ab.savedMacroName)
      if cmd then return cmd end
    end
    if P.Text(ab.name) then return "SPELL " .. ab.name end
  end
  if typ == "spell" and frame.GetAttribute then
    local spell = frame:GetAttribute("spell") or frame._sbSpellSaved
    if P.Text(spell) then return "SPELL " .. spell end
  end
  if typ == "macro" and frame.GetAttribute then
    local macro = frame:GetAttribute("macro") or frame._sbMacroSaved
    if type(macro) == "number" then
      local name = GetMacroInfo(macro)
      if P.Text(name) then return "MACRO " .. name end
    elseif P.Text(macro) then
      return "MACRO " .. macro
    end
  end
  if P.Text(frame.commandName) then return frame.commandName end
  return P.MouseKeyCommand(frame._sbDefaultKey)
end

function P.AbilityMacroCommand(frame)
  if not frame then return nil end
  local ab = frame._ability
  local label = ab and (ab.label or ab.name)
  local short = ab and ab.savedMacroName
  if not short and P.Text(label) then short = P.MACRO_SHORT_BY_LABEL[label] end
  if short then
    local cmd = P.NamedMacroCommand(short)
    if cmd then return cmd end
  end
  local body = ab and ab.macrotext
  if not P.Text(body) and frame.GetAttribute then body = frame:GetAttribute("macrotext") end
  if not P.Text(body) and P.Text(label) and (label == "Thorn Bloom" or label:find("Totem", 1, true)) then
    body = "#showtooltip " .. label .. "\n/cast [@cursor] " .. label
  end
  if not P.Text(body) or Locked() then return nil end
  if not short then
    local token = tostring(frame._sbBindId or label or "x"):gsub("%W", "")
    short = "Mouse" .. token:sub(-12)
  end
  if not EnsureMacro(short, (ab and ab.icon) or 134400, body) then return nil end
  return P.NamedMacroCommand(short)
end

function P.FireableMouseCommand(frame, key)
  if not frame or not P.IsMouseKey(key) then return nil end
  local function ok(cmd)
    return type(cmd) == "string" and cmd ~= "" and not cmd:find("^CLICK")
  end
  local cmd
  -- This icon's own command (ThornBloom), never the stock command of the
  -- chord we're stealing (RushTotem on Shift-WheelUp).
  if P.IsMouseKey(frame._sbDefaultKey) then
    cmd = P.MouseKeyCommand(frame._sbDefaultKey)
    if ok(cmd) then return cmd end
  end
  cmd = P.QkbMouseCommand(frame, key)
  if ok(cmd) then return cmd end
  cmd = P.AbilityMacroCommand(frame)
  if ok(cmd) then return cmd end
  local slot = P.BarSlotOf(frame)
  if P.ID(slot) and slot <= 12 then
    cmd = P.ActionBindCommand(slot) or ("ACTIONBUTTON" .. slot)
    if ok(cmd) then return cmd end
  end
end

function P.EnsureModDriver()
  if not P.modPoll then
    local poll = CreateFrame("Frame")
    P.modPoll = poll
    poll:RegisterEvent("MODIFIER_STATE_CHANGED")
    poll:SetScript("OnEvent", function(_, _, key, down)
      if type(key) ~= "string" then return end
      local k = string.upper(key)
      if k:find("SHIFT", 1, true) then P.shiftHeld = down == 1 or down == true end
      if k:find("CTRL", 1, true) then P.ctrlHeld = down == 1 or down == true end
      if k:find("ALT", 1, true) then P.altHeld = down == 1 or down == true end
    end)
  end
  if P.modDriver then return P.modDriver end
  local d = CreateFrame("Frame", "ShamanBindsModDriver", UIParent, "SecureHandlerStateTemplate")
  P.modDriver = d
  d:Hide()
  pcall(RegisterStateDriver, d, "shift", "[mod:shift]1;0")
  pcall(RegisterStateDriver, d, "ctrl", "[mod:ctrl]1;0")
  pcall(RegisterStateDriver, d, "alt", "[mod:alt]1;0")
  d:HookScript("OnAttributeChanged", function(_, attr)
    if attr == "state-shift" or attr == "state-ctrl" or attr == "state-alt" then
      P.SyncModState()
    end
  end)
  P.SyncModState()
  return d
end

function P.SyncModState()
  local d = P.modDriver
  if not d then return end
  local function bit(attr, current)
    local v = d:GetAttribute(attr)
    if v == "1" or v == 1 then return true end
    if v == "0" or v == 0 then return false end
    return current
  end
  P.shiftHeld = bit("state-shift", P.shiftHeld)
  P.ctrlHeld = bit("state-ctrl", P.ctrlHeld)
  P.altHeld = bit("state-alt", P.altHeld)
end

function P.HandleQkbWheel(delta)
  if not InQuickKeybind() or not delta or delta == 0 then return end
  P.EnsureModDriver()
  local d = P.modDriver
  local function down(attr, held)
    local v = d and d:GetAttribute(attr)
    if v == "1" or v == 1 then return true end
    return held == true
  end
  local shift = down("state-shift", P.shiftHeld)
  local ctrl = down("state-ctrl", P.ctrlHeld)
  local alt = down("state-alt", P.altHeld)
  local dir = delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"
  local parts = {}
  if shift then parts[#parts + 1] = "SHIFT" end
  if ctrl then parts[#parts + 1] = "CTRL" end
  if alt then parts[#parts + 1] = "ALT" end
  parts[#parts + 1] = dir
  local btn = BindableUnderMouse()
  if not btn then return end
  AssignHoveredBind(btn, table.concat(parts, "-"))
end

function AssignHoveredBind(frame, keyOrClear)
  if Locked() or busy or not frame or not P.Text(frame._sbBindId)
    or not P.Text(frame.commandName) then return false end
  if keyOrClear ~= nil and keyOrClear ~= false and not P.Text(keyOrClear) then return false end
  local bindId = frame._sbBindId
  local key = keyOrClear or ""
  local reserved = P.ReservedBindReason(key)
  if reserved then
    P.Report(reserved)
    return false
  end
  local command = frame.commandName
  local mouseKey = P.IsMouseKey(key)
  if mouseKey then
    command = P.FireableMouseCommand(frame, key)
    if not P.Text(command) then
      P.Report("That icon cannot take a mouse key. Hover a spell or totem.")
      return false
    end
  end
  if not P.Text(command) then return false end
  local now = GetTime and GetTime() or 0
  if lastQkbAssign.id == bindId and lastQkbAssign.key == key and (now - (lastQkbAssign.t or 0)) < 0.2 then
    return true
  end
  lastQkbAssign.t, lastQkbAssign.id, lastQkbAssign.key = now, bindId, key
  P.EnsureDB()
  -- SetBinding emits UPDATE_BINDINGS synchronously. Do not observe half a change.
  busy = true
  local oldKeys = {GetBindingKey(command)}
  local oldCommand = key ~= "" and GetBindingAction(key) or nil
  local oldBinds = P.CopyData(ShamanBindsDB.binds)
  local oldBarBinds = P.CopyData(ShamanBindsDB.barBinds)
  local ok, err = pcall(function()
    -- SetBinding already steals `key`. Clearing the command first wipes every
    -- other key on that slot — Shift-WheelUp on ACTIONBUTTON5 / MACRO RushTotem.
    if not mouseKey then ClearCommandKeys(command) end
    if key ~= "" and not SetBinding(key, command) then error("WoW rejected key " .. key) end
    for id, saved in pairs(ShamanBindsDB.binds) do
      if key ~= "" and saved == key and id ~= bindId then ShamanBindsDB.binds[id] = "" end
    end
    for action, saved in pairs(ShamanBindsDB.barBinds) do
      if key ~= "" and saved == key and action ~= command then ShamanBindsDB.barBinds[action] = "" end
    end
    for _, other in ipairs(P.BindFrames()) do
      if other._sbBindId ~= bindId and key ~= "" and EffectiveKey(other._sbBindId, other._sbDefaultKey) == key then
        ShamanBindsDB.binds[other._sbBindId] = ""
        if other._sbBindId:match("^bar:") then ShamanBindsDB.barBinds[other.commandName] = "" end
      end
    end
    ShamanBindsDB.binds[bindId] = key
    if bindId:match("^bar:") then
      local slot = bindId:match("^bar:(%d+)$")
      local barCmd = slot and ("ACTIONBUTTON" .. slot) or command
      ShamanBindsDB.barBinds[barCmd] = key
    end
    if SaveBindings(GetCurrentBindingSet()) == false then error("WoW could not save bindings.") end
  end)
  if not ok then
    ShamanBindsDB.binds, ShamanBindsDB.barBinds = oldBinds, oldBarBinds
    ClearCommandKeys(command)
    for _, oldKey in ipairs(oldKeys) do SetBinding(oldKey, command) end
    if key ~= "" and oldCommand and oldCommand ~= "" then SetBinding(key, oldCommand) end
    P.Report(err)
  end
  busy = false
  RefreshBindLabels()
  if ok then
    local label = (frame._ability and (frame._ability.label or frame._ability.name)) or frame.tipText
    if P.Text(label) and P.Text(key) then
      P.Report((PrettyKey(key) or key) .. " → " .. label)
    end
    P.ExplainStolenBind(key, label, oldCommand)
    if P.IsMouseKey(key) and not Locked() then
      P.RebuildOverrideList()
      P.FlushOverrides()
      RefreshBindLabels()
    end
  end
  return ok
end

function P.BarSlotOf(frame)
  local id = frame and frame._sbBindId
  if type(id) ~= "string" then return nil end
  local slot = id:match("^bar:(%d+)$")
  return slot and tonumber(slot)
end

function P.BindFrames()
  local frames = {}
  for _, tab in ipairs(consoleTabs) do
    if tab._sbBindId and tab.commandName then frames[#frames + 1] = tab end
  end
  for _, b in ipairs(allMenuButtons) do
    -- Include hidden drawer rows. After BIND the T menu collapses, and
    -- Thorn Bloom must still own a stolen Shift-WheelUp override.
    if b._sbBindId and b.commandName then frames[#frames + 1] = b end
  end
  -- The original layout has one secondary native action with no console tab.
  -- Keep its defence binding when reconciling the visible controls.
  for _, frame in ipairs(P.extraBarBindings or {}) do frames[#frames + 1] = frame end
  return frames
end

function P.RebindAll()
  local frames = P.BindFrames()
  local owners, commands = {}, {}
  for _, frame in ipairs(frames) do
    commands[frame.commandName] = true
  end
  for command in pairs(P.managedCommands or {}) do ClearCommandKeys(command) end
  for command in pairs(commands) do ClearCommandKeys(command) end
  -- Explicit choices win over defaults, with stable iteration on conflicts.
  for _, explicit in ipairs({true, false}) do
    for _, frame in ipairs(frames) do
      local id, command = frame._sbBindId, frame.commandName
      local saved = ShamanBindsDB.binds[id]
      if id:match("^bar:") and saved == nil then
        local slot = id:match("^bar:(%d+)$")
        saved = (ShamanBindsDB.barBinds or {})["ACTIONBUTTON" .. slot]
      end
      if (saved ~= nil) == explicit then
        local key = saved
        if key == nil then key = frame._sbDefaultKey end
        if key and key ~= "" and not P.IsChatKey(key) and not owners[key] then
          if P.IsMouseKey(key) then
            -- CLICK commands never fire for mouse buttons. ForceMouseHardware owns these.
            owners[key] = id
          else
          local slot = P.BarSlotOf(frame)
          -- Bar keys stay ACTIONBUTTON underneath so a mount/vehicle bar can
          -- use them when shaman overrides are cleared.
          local bindTo = (slot and ("ACTIONBUTTON" .. slot)) or command
          local ok, accepted = pcall(SetBinding, key, bindTo)
          if ok and accepted then
            owners[key] = id
          else
            P.Report("WoW rejected binding " .. key .. ". Reassign it in binding mode.")
          end
          end
        end
      end
    end
  end
  P.managedCommands = commands
  P.ForceMouseHardware()
  P.RestoreChatKeys()
  RefreshBindLabels()
end

local function SetQKBHighlights(on)
  for _, tab in pairs(consoleTabs) do
    if tab._qkbHL then tab._qkbHL:SetShown(on and tab._sbBindId) end
  end
  for _, b in ipairs(allMenuButtons) do
    if b._qkbHL then b._qkbHL:SetShown(on and b:IsShown() and b._sbBindId) end
  end
end

local function SetQKBCastSafe(on)
  if Locked() then P.pendingQKB = true; return end
  local function arm(frame)
    if not frame then return end
    if on then
      if frame._sbTypeSaved == nil then
        frame._sbTypeSaved = frame:GetAttribute("type") or false
        frame._sbRelSaved = frame:GetAttribute("typerelease")
        frame._sbSpellSaved = frame:GetAttribute("spell")
        frame._sbMacroSaved = frame:GetAttribute("macro")
      end
      frame:SetAttribute("type", nil)
      frame:SetAttribute("typerelease", nil)
      if frame.EnableMouseWheel then frame:EnableMouseWheel(true) end
    elseif frame._sbTypeSaved ~= nil then
      frame:SetAttribute("type", frame._sbTypeSaved or nil)
      frame:SetAttribute("typerelease", frame._sbRelSaved)
      frame._sbTypeSaved, frame._sbRelSaved = nil, nil
      frame._sbSpellSaved, frame._sbMacroSaved = nil, nil
      if frame.EnableMouseWheel then frame:EnableMouseWheel(false) end
    end
  end
  for _, tab in pairs(consoleTabs) do arm(tab) end
  for _, b in ipairs(allMenuButtons) do arm(b) end
end

-- Hover drawers pin to their tab. BIND opens every drawer at once, so
-- spread them into a wrapping row above the console instead of stacking.
function P.LayoutBindMenus(on)
  if Locked() or not console then return end
  if not on then
    P._sbBindBoardTop = nil
    for i, menu in pairs(menus) do
      local tab = consoleTabs[i]
      if menu and tab then
        menu:ClearAllPoints()
        menu:SetPoint("BOTTOM", tab, "TOP", 0, -1)
      end
    end
    return
  end
  local items = {}
  local idxs = {}
  for i in pairs(menus) do idxs[#idxs + 1] = i end
  table.sort(idxs)
  for _, i in ipairs(idxs) do
    local menu = menus[i]
    local w, h = menu and menu._sbW, menu and menu._sbH
    if (not w or not h) and menu and menu.GetWidth then
      w, h = menu:GetWidth(), menu:GetHeight()
    end
    if menu and P.Number(w) and P.Number(h) and w > 8 and h > 8 then
      items[#items + 1] = { menu = menu, w = w, h = h }
      menu:Show()
    end
  end
  local gap, maxW = 8, 1000
  local rows, row, rowW, rowH = {}, {}, 0, 0
  local function flush()
    if #row == 0 then return end
    rows[#rows + 1] = { items = row, w = rowW - gap, h = rowH }
    row, rowW, rowH = {}, 0, 0
  end
  for _, it in ipairs(items) do
    if #row > 0 and rowW + it.w > maxW then flush() end
    row[#row + 1] = it
    rowW = rowW + it.w + gap
    if it.h > rowH then rowH = it.h end
  end
  flush()
  local cw = console:GetWidth()
  if not P.Number(cw) then cw = 400 end
  local y = 12
  for _, band in ipairs(rows) do
    local x = (cw - band.w) / 2
    for _, it in ipairs(band.items) do
      it.menu:ClearAllPoints()
      it.menu:SetPoint("BOTTOMLEFT", console, "TOPLEFT", x, y)
      x = x + it.w + gap
    end
    y = y + band.h + gap
  end
  P._sbBindBoardTop = y
end

local function OnQuickKeybindMode(on)
  if P.EnsureModDriver then P.EnsureModDriver() end
  if P.SyncModState then P.SyncModState() end
  if P.UpdateMovePads then P.UpdateMovePads() end
  if Locked() then P.pendingQKB = true; return end
  if HoldMenus then HoldMenus(on) end
  if on then
    for _, menu in pairs(menus) do menu:Show() end
  end
  if P.LayoutBindMenus then P.LayoutBindMenus(on) end
  SetQKBHighlights(on)
  SetQKBCastSafe(on)
  if P.UpdateBindModeButton then P.UpdateBindModeButton() end
end

local qkbHooked = false
local function HookQuickKeybindFrame()
  local f = QuickKeybindFrame
  if not f or qkbHooked then return f and true end
  qkbHooked = true
  f:HookScript("OnKeyDown", function(_, key)
    local btn = BindableUnderMouse()
    if not btn then return end
    local chord = ChordFromKey(key)
    if chord == nil then return end
    AssignHoveredBind(btn, chord)
  end)
  if not f._sbWheelWrap then
    f._sbWheelWrap = true
    local prev = f:GetScript("OnMouseWheel")
    pcall(function() f:EnableMouseWheel(true) end)
    f:SetScript("OnMouseWheel", function(self, delta)
      -- Overlay sits above the console, so tab OnMouseWheel never fires.
      -- Consume only when the cursor is on our icon; otherwise let Blizzard
      -- Quick Keybind keep mouse-wheel for the main action bar.
      if BindableUnderMouse() then
        P.HandleQkbWheel(delta)
        return
      end
      if prev then prev(self, delta) end
    end)
  end
  f:HookScript("OnShow", function() OnQuickKeybindMode(true) end)
  f:HookScript("OnHide", function() OnQuickKeybindMode(false) end)
  if f:IsShown() then OnQuickKeybindMode(true) end
  return true
end

local qkbWatch = CreateFrame("Frame")
qkbWatch._on = false
qkbWatch:RegisterEvent("PLAYER_ENTERING_WORLD")
qkbWatch:RegisterEvent("ADDON_LOADED")
qkbWatch:RegisterEvent("UPDATE_BINDINGS")
qkbWatch:SetScript("OnEvent", function(_, event)
  HookQuickKeybindFrame()
  -- Reclaiming overrides can emit UPDATE_BINDINGS synchronously. Ignore our
  -- own writes here, before they can queue another next-frame reclaim.
  if event ~= "UPDATE_BINDINGS" or busy or P.rebindingMouse or not ShamanBindsDB.applied then return end
  if P.bindingObserveQueued then return end
  P.bindingObserveQueued = true
  C_Timer.After(0, function()
    P.bindingObserveQueued = nil
    if busy then return end
    P.EnsureDB()
    for _, frame in ipairs(P.BindFrames()) do
      local saved = ShamanBindsDB.binds[frame._sbBindId]
      if P.IsMouseKey(saved) then
        -- BIND's mouse/wheel choice is not on commandName. Do not overwrite it.
      elseif not P.IsMouseKey(frame._sbDefaultKey) and not (frame._sbBindId and tostring(frame._sbBindId):find("BUTTON", 1, true))
        and not (frame._sbBindId and tostring(frame._sbBindId):find("WHEEL", 1, true))
        and not (frame._sbBindId and tostring(frame._sbBindId):match("^bar:")) then
      local key = GetBindingKey(frame.commandName) or ""
      ShamanBindsDB.binds[frame._sbBindId] = key
      end
    end
    RefreshBindLabels()
    if not P.rebindingMouse then
      P.rebindingMouse = true
      P.ReclaimMouseOverrides()
      P.rebindingMouse = nil
    end
  end)
end)
local qkbMouseWas = {}
local QKB_MOUSE_BTNS = { "MiddleButton", "RightButton", "Button4", "Button5" }

local function PollQkbMouse()
  local target = BindableUnderMouse()
  for _, button in ipairs(QKB_MOUSE_BTNS) do
    local down = IsMouseButtonDown(button)
    if down and not qkbMouseWas[button] and target then
      local chord = MouseChord(button)
      if chord then AssignHoveredBind(target, chord) end
    end
    qkbMouseWas[button] = down
  end
end

qkbWatch:SetScript("OnUpdate", function(self)
  if not qkbHooked then HookQuickKeybindFrame() end
  local on = InQuickKeybind()
  if on ~= self._on then
    self._on = on
    wipe(qkbMouseWas)
    OnQuickKeybindMode(on)
  end
  if on then
    SetQKBHighlights(true)
    PollQkbMouse()
  end
end)

if WorldFrame and not WorldFrame._sbQkbHooked then
  WorldFrame._sbQkbHooked = true
  WorldFrame:HookScript("OnMouseDown", function(_, button)
    if not InQuickKeybind() then return end
    if button == "LeftButton" then return end
    local target = BindableUnderMouse()
    if not target then return end
    local chord = MouseChord(button)
    if chord then AssignHoveredBind(target, chord) end
  end)
end

local function OpenQuickKeybind()
  if Locked() then P.Report("Leave combat before changing bindings."); return end
  if C_AddOns and C_AddOns.LoadAddOn then
    pcall(C_AddOns.LoadAddOn, "Blizzard_BindingUI")
  elseif LoadAddOn then
    pcall(LoadAddOn, "Blizzard_BindingUI")
  end
  HookQuickKeybindFrame()
  if QuickKeybindFrame then
    QuickKeybindFrame:Show()
    if P.UpdateBindModeButton then P.UpdateBindModeButton() end
    return
  end
  print("|cff0070ddShaman Binds:|r open |cffffffffESC → Options → Keybindings → Quick Keybind Mode|r, then hover a console icon and press a key.")
end

function P.CloseQuickKeybind()
  if QuickKeybindFrame and QuickKeybindFrame.Hide then
    pcall(function() QuickKeybindFrame:Hide() end)
  end
  OnQuickKeybindMode(false)
  if P.UpdateBindModeButton then P.UpdateBindModeButton() end
end

function P.ToggleQuickKeybind()
  if InQuickKeybind() then
    P.CloseQuickKeybind()
    return
  end
  OpenQuickKeybind()
end

-- ============================== LAYOUT SPEC ==============================
-- One structure drives: bar 1, key bindings, console drop-downs, key map.
--
-- Family fields:
--   tag     : short label on the console tab
--   title   : keymap heading
--   bar     : {slot=, key=, sba|spell|macro, note} placed on bar 1
--   items   : drop-down members, in order. Each:
--     {spell={names}, bindKey=, key=, macrotext=, label=, iconFile=,
--      requires=, covers={names}, note=}
--     (bindKey -> also key-bound invisibly; everything is clickable in menu)

local function BuildLegacyFamilies()
  local fRacials = {}
  for _, n in ipairs(RACIALS) do
    if n ~= "Thorn Bloom" then fRacials[#fRacials + 1] = n end
  end
  local racialName = Known(unpack(fRacials))
  local rootName = Known("Earthgrab Totem", "Earthbind Totem") or "Earthgrab Totem"
  local lustName = Known("Heroism", "Bloodlust") or "Heroism"

  return {
    {
      tag = "E", title = "Hit  ·  E",
      bar = { slot = 3, key = "E", sba = true, label = "Assisted Rotation" },
      items = {
        { bindKey = "SHIFT-E", key = "Shift-E", macrotext = LUNGE_TEXT, label = "Feral Lunge", iconOf = "Feral Lunge", iconFile = 1027879, covers = { "Feral Lunge" }, requires = "Feral Lunge", note = "gap closer" },
        { bindKey = "CTRL-E", key = "Ctrl-E", spell = { "Ascendance", "Doom Winds" }, note = "burst" },
      },
    },
    {
      tag = "Q", title = "Stop them  ·  Q",
      bar = { slot = 1, key = "Q", macro = { "WindShear", 136018, SHEAR_TEXT }, label = "Wind Shear", covers = { "Wind Shear" }, note = "mouseover interrupt" },
      items = {
        { bindKey = "SHIFT-Q", key = "Shift-Q", macrotext = PURGE_TEXT, label = "Purge", iconOf = "Purge", iconFile = 136075, covers = { "Purge" }, requires = "Purge", note = "offensive dispel" },
      },
    },
    {
      tag = "2", title = "Stay up",
      bar = { slot = 2, macro = { "HealSurge", 136052, "#showtooltip Healing Surge\n/cast [@mouseover,help,nodead][] Healing Surge" }, label = "Healing Surge", covers = { "Healing Surge" }, note = "mouseover ally, else self" },
      items = {
        { bindKey = "SHIFT-2", key = "Shift-2", spell = { "Astral Shift" }, covers = { "Astral Shift" }, requires = "Astral Shift", note = "defensive wall" },
        { bindKey = "CTRL-2", key = "Ctrl-2", macrotext = CHAIN_HEAL_TEXT, label = "Chain Heal", iconOf = "Chain Heal", iconFile = 136042, covers = { "Chain Heal" }, requires = "Chain Heal", note = "mouseover group heal" },
        { macrotext = SHIELD_TEXT, label = "Earth Shield", iconOf = "Earth Shield", iconFile = 136089, covers = { "Earth Shield" }, requires = "Earth Shield", note = "mouseover ally, else self" },
        { bindKey = "SHIFT-3", key = "Shift-3", macrotext = REZ_TEXT, label = "Ancestral Spirit", iconOf = "Ancestral Spirit", iconFile = 136077, covers = { "Ancestral Spirit" }, requires = "Ancestral Spirit", note = "mouseover resurrect" },
      },
    },
    {
      tag = "T", title = "Ground  ·  wheel",
      bar = { slot = 5, key = "Shift-WheelUp", bindKey = "SHIFT-MOUSEWHEELUP", macro = { "RushTotem", 538576, "#showtooltip Wind Rush Totem\n/cast [@cursor] Wind Rush Totem" }, label = "Wind Rush Totem", covers = { "Wind Rush Totem" }, note = "speed @cursor" },
      items = {
        { bindKey = "SHIFT-MOUSEWHEELDOWN", key = "Shift-WheelDown", macrotext = "/cast [@cursor] Capacitor Totem", label = "Capacitor Totem", iconOf = "Capacitor Totem", iconFile = 136013, covers = { "Capacitor Totem" }, note = "stun @cursor" },
        { macrotext = "/cast [@cursor] " .. rootName, label = rootName, iconOf = rootName, iconFile = 136102, covers = { rootName }, note = "root @cursor · click" },
        { macrotext = "#showtooltip Thorn Bloom\n/cast [@cursor] Thorn Bloom", label = "Thorn Bloom", iconOf = "Thorn Bloom", iconFile = 7491039, covers = { "Thorn Bloom" }, requires = "Thorn Bloom", note = "racial @cursor · click" },
      },
    },
    {
      tag = "M4", title = "Move  ·  M4",
      bar = { slot = 6, key = "M4", spell = { "Ghost Wolf" }, note = "travel form" },
      items = {
        { bindKey = "SHIFT-BUTTON4", key = "Shift-M4", macrotext = SPRINT_BODY, label = "Flee kit", iconFile = 136095, covers = { "Spirit Walk" }, note = "spam: Spirit Walk + Wind Rush + wolf" },
        { label = "Spirit Walk", iconOf = "Spirit Walk", iconFile = 132328, macrotext = WALK_TEXT, covers = { "Spirit Walk" }, requires = "Spirit Walk", note = "root break · click" },
      },
    },
    {
      tag = "M5", title = "Call  ·  M5",
      items = {
        { bindKey = "BUTTON5", key = "M5", macrotext = MOUNT_TEXT, label = "Favorite mount", iconFile = 132250 },
        { bindKey = "BUTTON3", key = "MMB", spell = { "Earth Elemental" }, note = "pocket tank" },
      },
    },
    {
      tag = "C", title = "Overflow  ·  C",
      bar = { slot = 4, key = "C", spell = { "Chain Lightning" }, note = "manual spender" },
      items = {
        { bindKey = "F", key = "F", spell = fRacials, label = racialName or "Racial", note = "racial" },
      },
    },
    {
      tag = "BUF", title = "Hour  ·  R",
      items = {
        { bindKey = "R", key = "R", macrotext = "#showtooltip " .. lustName .. "\n/cast " .. lustName, label = lustName, iconOf = lustName, iconFile = 132313, covers = { "Heroism", "Bloodlust" }, requires = lustName, note = "bloodlust" },
      },
    },
    {
      tag = "TP", title = "See  ·  V",
      items = {
        { bindKey = "V", key = "V", macrotext = FARSIGHT_TEXT, label = "Far Sight", iconOf = "Far Sight", iconFile = 136033, covers = { "Far Sight" }, requires = "Far Sight", note = "see @cursor" },
        { bindKey = "X", key = "X", macrotext = WWALK_TEXT, label = "Water Walking", iconOf = "Water Walking", iconFile = 135863, covers = { "Water Walking" }, requires = "Water Walking", note = "mouseover ally, else self" },
      },
    },
    {
      tag = "+", title = "Click",
      items = {
        { spell = { "Recuperate" }, covers = { "Recuperate" }, note = "out of combat" },
        { spell = { "Skyfury" }, covers = { "Skyfury" }, note = "raid buff · SBA" },
        { spell = { "Lightning Shield" }, covers = { "Lightning Shield" }, note = "SBA" },
        { itemID = 6948, label = "Hearthstone" },
        { spell = { "Astral Recall" }, label = "Astral Recall" },
      },
    },
  }
end

-- Purpose-based defaults for Aeru. Only active spells in BOOK are offered.
function P.FamilySpell(family, names, key, target, note)
  if type(names)=="string" then names={names} end
  local name,id=Known(unpack(names))
  if not name then return end
  local item={spell={name},label=name,bindKey=key,key=PrettyKey(key),note=note}
  if target then
    local conditions={help="[mod:alt,@player][@mouseover,help,nodead][help,nodead][@player] ",
      harm="[@mouseover,harm,nodead][] ",cursor="[@cursor] "}
    item.spell=nil
    item.macrotext="#showtooltip "..name.."\n/cast "..(conditions[target] or "")..name
    item.requires,item.iconOf,item.iconFile,item.covers=name,name,SpellIcon(id),{name}
    item.id, item.name = id, name
  end
  family.items[#family.items+1]=item
end

function P.IsFamilyMode()
  local mode = ShamanBindsDB and ShamanBindsDB.familyMode
  return mode == "families" or mode == "pocket" or mode == "prime" or mode == "farseer"
end

function P.RestoreCameraWheel()
  if Locked() then return end
  local claimed = {}
  for _, store in ipairs({ ShamanBindsDB.binds, ShamanBindsDB.barBinds }) do
    if store then
      for _, key in pairs(store) do
        if key == "MOUSEWHEELUP" or key == "MOUSEWHEELDOWN" then claimed[key] = true end
      end
    end
  end
  local want = {
    MOUSEWHEELUP = "CAMERAZOOMIN",
    MOUSEWHEELDOWN = "CAMERAZOOMOUT",
    ["CTRL-MOUSEWHEELUP"] = "CAMERAZOOMIN",
    ["CTRL-MOUSEWHEELDOWN"] = "CAMERAZOOMOUT",
    NUMPADPLUS = "CAMERAZOOMIN",
    NUMPADMINUS = "CAMERAZOOMOUT",
  }
  for key, cmd in pairs(want) do
    if not claimed[key] then
      local have = GetBindingAction(key)
      if have ~= cmd then pcall(SetBinding, key, cmd) end
    end
  end
end

function P.RestoreTotemWheelBinds()
  -- Camera zoom is restored only for wheel directions BIND has not claimed.
  P.RestoreCameraWheel()
end

function P.SelectFamilyHardware()
  P.RestoreTotemWheelBinds()
  local mode = ShamanBindsDB.familyMode
  local primeLike = (mode == "prime" or mode == "farseer")
  BAR_BINDS["2"] = nil
  BAR_BINDS["SHIFT-C"] = primeLike and nil or "TOGGLECHARACTER0"
  MOUSE_HARDWARE.BUTTON3 = { slot = 10, spell = "Earth Elemental", macro = "EarthEle" }
  P.MOUSE_MACRO[10] = "EarthEle"
  if primeLike then
    local lungeMacro = (mode == "farseer") and "GustWind" or "FeralLunge"
    MOUSE_HARDWARE.BUTTON3 = { macro = "EarthEle" }
    MOUSE_HARDWARE.BUTTON5 = { slot = 8, macro = "HealSurge" }
    P.MOUSE_MACRO[8] = "HealSurge"
    P.MOUSE_MACRO[9] = lungeMacro
    P.MOUSE_MACRO[10] = "ChainHeal"
    MOUSE_HARDWARE["SHIFT-BUTTON4"] = { slot = 9, macro = lungeMacro }
    MOUSE_HARDWARE["SHIFT-BUTTON5"] = { slot = 10, macro = "ChainHeal" }
    MOUSE_HARDWARE["SHIFT-BUTTON3"] = { spell = "Spiritwalker's Grace" }
    if ShamanBindsDB.binds then
      ShamanBindsDB.binds["key:CTRL-C"] = nil
      ShamanBindsDB.binds["key:Z"] = nil
      if mode == "farseer" then ShamanBindsDB.binds["key:SHIFT-E"] = nil end
    end
    if mode == "farseer" and ShamanBindsDB.mods then ShamanBindsDB.mods["SHIFT-E"] = nil end
    P.Visual.families = { E="ATTACK", Q="DISRUPT", M5="HEAL", T="TOTEMS", M4="MOVE", C="PROTECT", R="EMPOWER", X="TRAVEL", BUF="BUFFS", ["+"]="RECOVER" }
  else
    local wall = mode == "families"
    MOUSE_HARDWARE.BUTTON5 = { slot = 8, macro = wall and "AstralWall" or "FavMount" }
    P.MOUSE_MACRO[8] = wall and "AstralWall" or "FavMount"
    MOUSE_HARDWARE["SHIFT-BUTTON4"] = { slot = 9, macro = "FleeKit" }
    MOUSE_HARDWARE["SHIFT-BUTTON5"] = nil
    MOUSE_HARDWARE["SHIFT-BUTTON3"] = nil
    if ShamanBindsDB.binds then
      ShamanBindsDB.binds["key:SHIFT-BUTTON5"] = nil
      if ShamanBindsDB.binds["bar:10"] == "SHIFT-BUTTON5" then ShamanBindsDB.binds["bar:10"] = nil end
    end
    if ShamanBindsDB.barBinds and ShamanBindsDB.barBinds["ACTIONBUTTON10"] == "SHIFT-BUTTON5" then
      ShamanBindsDB.barBinds["ACTIONBUTTON10"] = nil
    end
    if mode == "pocket" then
      P.Visual.families = { E="ATTACK", Q="CONTROL", ["2"]="HEAL", T="TOTEMS", M4="MOVE", M5="CALL", C="OVERFLOW", R="POWER", X="DEFEND", BUF="BUFFS", ["+"]="RECOVER" }
    elseif mode == "families" then
      P.Visual.families = { E="ATTACK", Q="CONTROL", ["2"]="HEAL", T="TOTEMS", M4="MOVE", M5="DEFEND", C="CLEANSE", R="POWER", TP="TRAVEL", BUF="BUFFS", ["+"]="RECOVER" }
    else
      P.Visual.families = { E="HIT", Q="INTERRUPT", ["2"]="SUSTAIN", T="GROUND", M4="MOVE", M5="SUMMON", C="OVERFLOW", BUF="EMPOWER", TP="EXPLORE", ["+"]="UTILITY" }
    end
  end
  -- Ctrl-Wheel and Ctrl-M4 / Ctrl-M5 are camera zoom. Do not reclaim them.
  MOUSE_HARDWARE["CTRL-BUTTON4"] = nil
  MOUSE_HARDWARE["CTRL-BUTTON5"] = nil
  MOUSE_HARDWARE["CTRL-MOUSEWHEELUP"] = nil
  MOUSE_HARDWARE["CTRL-MOUSEWHEELDOWN"] = nil
  if ShamanBindsDB.binds then
    ShamanBindsDB.binds["key:CTRL-BUTTON4"] = nil
    ShamanBindsDB.binds["key:CTRL-BUTTON5"] = nil
    ShamanBindsDB.binds["key:CTRL-MOUSEWHEELUP"] = nil
    ShamanBindsDB.binds["key:CTRL-MOUSEWHEELDOWN"] = nil
  end
  P.EvictKeysFromBinds(ShamanBindsDB.binds, ShamanBindsDB.barBinds, {
    ["CTRL-MOUSEWHEELUP"] = true,
    ["CTRL-MOUSEWHEELDOWN"] = true,
  })
end

function P.BuildPurposeFamilies()
  local attack={tag="E",title="Attack · E / F",bar={slot=3,key="E",sba=true,label="Assisted Rotation"},items={}}
  local control={tag="Q",title="Control · Q",bar={slot=1,key="Q",macro={"WindShear",136018,SHEAR_TEXT},label="Wind Shear",covers={"Wind Shear"}},items={}}
  local heal={tag="2",title="Heal",bar={slot=2,macro={"HealSurge",136052,
    "#showtooltip Healing Surge\n/cast [mod:alt,@player][@mouseover,help,nodead][help,nodead][@player] Healing Surge"},label="Healing Surge",covers={"Healing Surge"}},items={}}
  local totems={tag="T",title="Totems · wheel / T / G",bar={slot=5,key="Shift-WheelUp",bindKey="SHIFT-MOUSEWHEELUP",macro={"RushTotem",538576,"#showtooltip Wind Rush Totem\n/cast [@cursor] Wind Rush Totem"},label="Wind Rush Totem",covers={"Wind Rush Totem"}},items={}}
  local move={tag="M4",title="Move · M4",bar={slot=6,key="M4",spell={"Ghost Wolf"}},items={}}
  local defend={tag="M5",title="Defend · M5",bar={slot=8,key="M5",bindKey="BUTTON5",macro={"AstralWall",538565,"#showtooltip Astral Shift\n/cast Astral Shift"},label="Astral Shift",covers={"Astral Shift"}},items={}}
  local cleanse={tag="C",title="Cleanse · C",items={}}
  local name,id=Known("Cleanse Spirit","Purify Spirit")
  if not name then
    for bookName,bookId in pairs(BOOK) do
      if type(bookName)=="string" and not bookName:find("Totem",1,true) then
        local low=bookName:lower()
        if low:find("cleanse",1,true) or low:find("purify",1,true) then
          name,id=bookName,bookId
          break
        end
      end
    end
  end
  name=name or "Cleanse Spirit"
  id=id or P.SPELL_ID[name] or 51886
  local icon=SpellIcon(id,name)
  if not icon or icon==134400 then icon=136087 end
  cleanse.bar={slot=4,key="C",bindKey="C",macro={"Cleanse",icon,"#showtooltip "..name.."\n/cast [mod:alt,@player][@mouseover,help,nodead][help,nodead][@player] "..name},label=name,covers={name}}
  local power={tag="R",title="Power · R",items={}}
  local travel={tag="TP",title="Travel · V / X",items={}}
  local buffs={tag="BUF",title="Buffs · click",items={}}
  local recover={tag="+",title="Recover · click",items={}}

  P.FamilySpell(attack,"Feral Lunge","SHIFT-E","harm","engage")
  P.FamilySpell(attack,"Sundering","CTRL-E",nil,"deliberate damage burst")
  P.FamilySpell(attack,{"Lightning Bolt","Tempest"},"F","harm","ranged single target; replacement uses the same spell action")
  P.FamilySpell(attack,"Chain Lightning","SHIFT-F","harm","ranged area damage")
  P.FamilySpell(attack,{"Voltaic Blaze","Flame Shock"},"CTRL-F","harm","apply damage over time")
  P.FamilySpell(attack,{"Stormstrike","Windstrike"},nil,nil,"SBA-covered; manual access")
  P.FamilySpell(attack,"Lava Lash",nil,nil,"SBA-covered; manual access")
  P.FamilySpell(attack,"Crash Lightning",nil,nil,"SBA-covered; manual access")
  P.FamilySpell(attack,"Fire Nova",nil,nil,"SBA-covered; manual access")
  P.FamilySpell(control,"Purge","SHIFT-Q","harm","remove enemy buff")
  -- Retain the explicit no-Hex / no-Ctrl-Q preference.
  P.FamilySpell(control,"Lightning Lasso","Z","harm","combat channel, when selected")
  P.FamilySpell(heal,"Chain Heal","SHIFT-2","help","group heal; Alt forces self target")
  P.FamilySpell(totems,"Capacitor Totem","SHIFT-MOUSEWHEELDOWN","cursor","stun at the cursor")
  P.FamilySpell(totems,{"Earthgrab Totem","Earthbind Totem"},nil,"cursor","control enemies · click")
  P.FamilySpell(totems,"Thorn Bloom",nil,"cursor","Haranir area ability · click")
  P.FamilySpell(totems,"Healing Stream Totem","T","cursor","sustain allies")
  P.FamilySpell(totems,"Tremor Totem","SHIFT-T","cursor","anti-fear utility")
  P.FamilySpell(totems,"Poison Cleansing Totem","CTRL-T","cursor","group cleanse")
  P.FamilySpell(totems,"Totemic Projection","G","cursor","relocate totems")
  P.FamilySpell(totems,"Grounding Totem","SHIFT-G","cursor","spell protection, when selected")
  P.FamilySpell(totems,"Static Field Totem","CTRL-G","cursor","area control, when selected")
  P.FamilySpell(totems,"Counterstrike Totem","CTRL-SHIFT-G","cursor","when selected")
  move.items[#move.items+1]={bindKey="SHIFT-BUTTON4",key="Shift-M4",macrotext=SPRINT_BODY,label="Flee kit",iconFile=136095,note="spam: Spirit Walk + Wind Rush + wolf"}
  P.FamilySpell(move,"Spirit Walk",nil,"plain","break roots")
  P.FamilySpell(move,"Spiritwalker's Grace","SHIFT-X","plain","cast while moving, when learned")
  P.FamilySpell(defend,"Earth Elemental","BUTTON3",nil,"defensive summon")
  P.FamilySpell(power,{"Ascendance","Doom Winds"},"R",nil,"active personal burst; replacement keeps this key")
  P.FamilySpell(power,{"Heroism","Bloodlust"},"CTRL-R","plain","deliberate group haste")
  P.FamilySpell(power,"Surging Totem","SHIFT-R","cursor","only if actually learned in another hero build")
  P.FamilySpell(travel,"Far Sight","V","cursor","look ahead")
  travel.items[#travel.items+1]={bindKey="SHIFT-V",key="Shift-V",macrotext=MOUNT_TEXT,label="Favorite mount",iconFile=132250,savedMacroName="FavMount"}
  P.FamilySpell(travel,"Water Walking","X","help","water travel")
  for _,spell in ipairs({"Skyfury","Lightning Shield","Earth Shield","Flametongue Weapon","Windfury Weapon","Water Shield","Earthliving Weapon"}) do
    P.FamilySpell(buffs,spell,nil,nil,"maintenance; manual access")
  end
  for _,spell in ipairs({"Recuperate","Ancestral Spirit","Astral Recall"}) do
    P.FamilySpell(recover,spell,nil,nil,"recovery / travel")
  end
  do
    local retName=Known("Rootwalking: Return")
    local root,rootId=Known("Rootwalking","Rootwalking: Return")
    if root then
      recover.items[#recover.items+1]={
        spell={root},label=retName or root,iconFile=SpellIcon(rootId,root),
        covers={"Rootwalking","Rootwalking: Return"},
        note="Haranir racial; leave Ghost Wolf, then click. Return is this same slot.",
      }
    end
  end
  recover.items[#recover.items+1]={itemID=6948,label="Hearthstone"}
  local families={attack,control,heal,totems,move,defend,cleanse,power,travel,buffs,recover}
  -- Keep every learned active spell reachable. The explicit catalogue owns keys;
  -- uncatalogued spells never grab unrelated player bindings automatically.
  local seen={Hex=true}
  for _,fam in ipairs(families) do
    if fam.bar then
      for _,n in ipairs(fam.bar.covers or fam.bar.spell or {}) do seen[n]=true end
    end
    for _,it in ipairs(fam.items) do
      for _,n in ipairs(it.covers or it.spell or {}) do seen[n]=true end
    end
  end
  local extra={}
  for spell,id in pairs(BOOK) do if not seen[spell] and id~=SBA_ID then extra[#extra+1]=spell end end
  table.sort(extra)
  P.unmappedFamilySpells={}
  for _,spell in ipairs(extra) do
    if P.ParkUnmappedSpell(spell, totems, attack, recover) then
      P.unmappedFamilySpells[#P.unmappedFamilySpells+1]=spell
    end
  end
  return families
end

-- WASD-pocket faces: unmod on E/M5/M4/C/Q/R/X, then Shift, then Ctrl.
-- Loaded only via the Pocket profile so the current purpose layout stays put.
function P.BuildPocketFamilies()
  local attack={tag="E",title="Attack · E / F",bar={slot=3,key="E",sba=true,label="Assisted Rotation"},items={}}
  local control={tag="Q",title="Control · Q",bar={slot=1,key="Q",macro={"WindShear",136018,SHEAR_TEXT},label="Wind Shear",covers={"Wind Shear"}},items={}}
  local heal={tag="2",title="Heal",bar={slot=2,macro={"HealSurge",136052,
    "#showtooltip Healing Surge\n/cast [mod:alt,@player][@mouseover,help,nodead][help,nodead][@player] Healing Surge"},label="Healing Surge",covers={"Healing Surge"}},items={}}
  local totems={tag="T",title="Totems · wheel / T / G",bar={slot=5,key="Shift-WheelUp",bindKey="SHIFT-MOUSEWHEELUP",macro={"RushTotem",538576,"#showtooltip Wind Rush Totem\n/cast [@cursor] Wind Rush Totem"},label="Wind Rush Totem",covers={"Wind Rush Totem"}},items={}}
  local move={tag="M4",title="Move · M4",bar={slot=6,key="M4",spell={"Ghost Wolf"}},items={}}
  local call={tag="M5",title="Call · M5",items={
    {bindKey="BUTTON5",key="M5",macrotext=MOUNT_TEXT,label="Favorite mount",iconFile=132250,savedMacroName="FavMount"},
  }}
  local overflow={tag="C",title="Overflow · C",bar={slot=4,key="C",spell={"Chain Lightning"},note="manual spender"},items={}}
  local power={tag="R",title="Power · R",items={}}
  local defend={tag="X",title="Defend · X",items={}}
  local buffs={tag="BUF",title="Buffs · click",items={}}
  local recover={tag="+",title="Recover · click",items={}}

  P.FamilySpell(attack,"Feral Lunge","SHIFT-E","harm","engage")
  P.FamilySpell(attack,"Sundering","CTRL-E",nil,"deliberate damage burst")
  P.FamilySpell(attack,{"Lightning Bolt","Tempest"},"F","harm","ranged single target; replacement uses the same spell action")
  P.FamilySpell(attack,{"Voltaic Blaze","Flame Shock"},"CTRL-F","harm","apply damage over time")
  P.FamilySpell(attack,{"Stormstrike","Windstrike"},nil,nil,"SBA-covered; manual access")
  P.FamilySpell(attack,"Lava Lash",nil,nil,"SBA-covered; manual access")
  P.FamilySpell(attack,"Crash Lightning",nil,nil,"SBA-covered; manual access")
  P.FamilySpell(attack,"Fire Nova",nil,nil,"SBA-covered; manual access")
  P.FamilySpell(control,"Purge","SHIFT-Q","harm","remove enemy buff")
  P.FamilySpell(control,{"Cleanse Spirit","Purify Spirit"},nil,"help","defensive dispel; same family as Purge")
  P.FamilySpell(control,"Lightning Lasso","Z","harm","combat channel, when selected")
  P.FamilySpell(heal,"Chain Heal","SHIFT-2","help","group heal; Alt forces self target")
  P.FamilySpell(totems,"Capacitor Totem","SHIFT-MOUSEWHEELDOWN","cursor","stun at the cursor")
  P.FamilySpell(totems,{"Earthgrab Totem","Earthbind Totem"},nil,"cursor","control enemies · click")
  P.FamilySpell(totems,"Thorn Bloom",nil,"cursor","Haranir area ability · click")
  P.FamilySpell(totems,"Healing Stream Totem","T","cursor","sustain allies")
  P.FamilySpell(totems,"Tremor Totem","SHIFT-T","cursor","anti-fear utility")
  P.FamilySpell(totems,"Poison Cleansing Totem","CTRL-T","cursor","group cleanse")
  P.FamilySpell(totems,"Totemic Projection","G","cursor","relocate totems")
  P.FamilySpell(totems,"Grounding Totem","SHIFT-G","cursor","spell protection, when selected")
  P.FamilySpell(totems,"Static Field Totem","CTRL-G","cursor","area control, when selected")
  P.FamilySpell(totems,"Counterstrike Totem","CTRL-SHIFT-G","cursor","when selected")
  move.items[#move.items+1]={bindKey="SHIFT-BUTTON4",key="Shift-M4",macrotext=SPRINT_BODY,label="Flee kit",iconFile=136095,note="spam: Spirit Walk + Wind Rush + wolf"}
  P.FamilySpell(move,"Spirit Walk",nil,"plain","break roots")
  P.FamilySpell(call,"Earth Elemental","BUTTON3",nil,"defensive summon")
  P.FamilySpell(defend,"Astral Shift","X",nil,"personal defensive")
  P.FamilySpell(defend,"Spiritwalker's Grace","SHIFT-X","plain","cast while moving, when learned")
  P.FamilySpell(power,{"Ascendance","Doom Winds"},"R",nil,"active personal burst; replacement keeps this key")
  P.FamilySpell(power,{"Heroism","Bloodlust"},"CTRL-R","plain","deliberate group haste")
  P.FamilySpell(power,"Surging Totem","SHIFT-R","cursor","only if actually learned in another hero build")
  for _,spell in ipairs({"Skyfury","Lightning Shield","Earth Shield","Flametongue Weapon","Windfury Weapon","Water Shield","Earthliving Weapon"}) do
    P.FamilySpell(buffs,spell,nil,nil,"maintenance; manual access")
  end
  for _,spell in ipairs({"Recuperate","Ancestral Spirit","Astral Recall"}) do
    P.FamilySpell(recover,spell,nil,nil,"recovery / travel")
  end
  P.FamilySpell(recover,"Far Sight",nil,"cursor","look ahead")
  P.FamilySpell(recover,"Water Walking",nil,"help","water travel")
  do
    local retName=Known("Rootwalking: Return")
    local root,rootId=Known("Rootwalking","Rootwalking: Return")
    if root then
      recover.items[#recover.items+1]={
        spell={root},label=retName or root,iconFile=SpellIcon(rootId,root),
        covers={"Rootwalking","Rootwalking: Return"},
        note="Haranir racial; leave Ghost Wolf, then click. Return is this same slot.",
      }
    end
  end
  recover.items[#recover.items+1]={itemID=6948,label="Hearthstone"}
  local families={attack,control,heal,totems,move,call,overflow,power,defend,buffs,recover}
  local seen={Hex=true}
  for _,fam in ipairs(families) do
    if fam.bar then
      for _,n in ipairs(fam.bar.covers or fam.bar.spell or {}) do seen[n]=true end
    end
    for _,it in ipairs(fam.items) do
      for _,n in ipairs(it.covers or it.spell or {}) do seen[n]=true end
    end
  end
  local extra={}
  for spell,id in pairs(BOOK) do if not seen[spell] and id~=SBA_ID then extra[#extra+1]=spell end end
  table.sort(extra)
  P.unmappedFamilySpells={}
  for _,spell in ipairs(extra) do
    if P.ParkUnmappedSpell(spell, totems, attack, recover) then
      P.unmappedFamilySpells[#P.unmappedFamilySpells+1]=spell
    end
  end
  return families
end

-- Accessibility import: E→M5→M4→C→Q→R→X, Shift then Ctrl. No flee kit, no Hex.
function P.BuildPrimeFamilies()
  local attack={tag="E",title="Attack · E",bar={slot=3,key="E",sba=true,label="Assisted Rotation"},items={}}
  local disrupt={tag="Q",title="Disrupt · Q",bar={slot=1,key="Q",macro={"WindShear",136018,SHEAR_TEXT},label="Wind Shear",covers={"Wind Shear"}},items={}}
  local heal={tag="M5",title="Heal · M5",bar={slot=8,key="M5",bindKey="BUTTON5",macro={"HealSurge",136052,SURGE_TEXT},label="Healing Surge",covers={"Healing Surge"}},items={}}
  local totems={tag="T",title="Totems · wheel / T",bar={slot=5,key="Shift-WheelUp",bindKey="SHIFT-MOUSEWHEELUP",macro={"RushTotem",538576,"#showtooltip Wind Rush Totem\n/cast [@cursor] Wind Rush Totem"},label="Wind Rush Totem",covers={"Wind Rush Totem"}},items={}}
  local move={tag="M4",title="Move · M4",bar={slot=6,key="M4",spell={"Ghost Wolf"}},items={}}
  local protect={tag="C",title="Protect · C",bar={slot=4,key="C",bindKey="C",macro={"AstralWall",538565,"#showtooltip Astral Shift\n/cast Astral Shift"},label="Astral Shift",covers={"Astral Shift"}},items={}}
  local empower={tag="R",title="Empower · R",items={}}
  local travel={tag="X",title="Travel · X",items={
    {bindKey="X",key="X",macrotext=MOUNT_TEXT,label="Favorite mount",iconFile=132250,savedMacroName="FavMount"},
  }}
  local buffs={tag="BUF",title="Buffs · click",items={}}
  local recover={tag="+",title="Recover · click",items={}}

  P.FamilySpell(attack,"Chain Lightning","SHIFT-E","harm","ranged area damage")
  P.FamilySpell(attack,{"Lightning Bolt","Tempest"},"CTRL-E","harm","ranged single target; replacement uses the same spell action")
  P.FamilySpell(attack,"Sundering",nil,nil,"frontal damage burst")
  P.FamilySpell(attack,{"Stormstrike","Windstrike"},nil,nil,"SBA-covered; manual access")
  P.FamilySpell(attack,"Lava Lash",nil,nil,"SBA-covered; manual access")
  P.FamilySpell(attack,"Crash Lightning",nil,nil,"SBA-covered; manual access")
  P.FamilySpell(attack,"Fire Nova",nil,nil,"SBA-covered; manual access")
  P.FamilySpell(disrupt,"Purge","SHIFT-Q","harm","remove enemy buff")
  P.FamilySpell(heal,"Chain Heal","SHIFT-BUTTON5","help","group heal; Alt forces self")
  P.FamilySpell(totems,"Capacitor Totem","SHIFT-MOUSEWHEELDOWN","cursor","stun at the cursor")
  P.FamilySpell(totems,{"Earthgrab Totem","Earthbind Totem"},nil,"cursor","control enemies · click")
  P.FamilySpell(totems,"Thorn Bloom",nil,"cursor","Haranir area ability · click")
  P.FamilySpell(totems,"Healing Stream Totem","T","cursor","sustain allies")
  P.FamilySpell(totems,"Tremor Totem","SHIFT-T","cursor","anti-fear utility")
  P.FamilySpell(totems,"Poison Cleansing Totem","CTRL-T","cursor","group cleanse")
  P.FamilySpell(move,"Feral Lunge","SHIFT-BUTTON4","harm","gap closer")
  P.FamilySpell(move,"Spirit Walk",nil,"plain","break roots")
  P.FamilySpell(protect,{"Cleanse Spirit","Purify Spirit"},"SHIFT-C","help","defensive dispel")
  P.FamilySpell(protect,"Spiritwalker's Grace","SHIFT-BUTTON3","plain","cast while moving")
  P.FamilySpell(protect,"Earth Elemental","BUTTON3",nil,"defensive summon")
  P.FamilySpell(empower,{"Ascendance","Doom Winds"},"R",nil,"active personal burst; replacement keeps this key")
  P.FamilySpell(empower,{"Heroism","Bloodlust"},"SHIFT-R","plain","deliberate group haste")
  P.FamilySpell(travel,"Water Walking","SHIFT-X","help","water travel")
  P.FamilySpell(travel,"Far Sight","CTRL-X","cursor","look ahead")
  for _,spell in ipairs({"Skyfury","Lightning Shield","Earth Shield","Flametongue Weapon","Windfury Weapon","Water Shield","Earthliving Weapon"}) do
    P.FamilySpell(buffs,spell,nil,nil,"maintenance; manual access")
  end
  for _,spell in ipairs({"Recuperate","Ancestral Spirit","Astral Recall"}) do
    P.FamilySpell(recover,spell,nil,nil,"recovery / travel")
  end
  do
    local retName=Known("Rootwalking: Return")
    local root,rootId=Known("Rootwalking","Rootwalking: Return")
    if root then
      recover.items[#recover.items+1]={
        spell={root},label=retName or root,iconFile=SpellIcon(rootId,root),
        covers={"Rootwalking","Rootwalking: Return"},
        note="Haranir racial; leave Ghost Wolf, then click. Return is this same slot.",
      }
    end
  end
  recover.items[#recover.items+1]={itemID=6948,label="Hearthstone"}
  local primeFams={attack,disrupt,heal,totems,move,protect,empower,travel,buffs,recover}
  local seenP={Hex=true}
  for _,fam in ipairs(primeFams) do
    if fam.bar then
      for _,n in ipairs(fam.bar.covers or fam.bar.spell or {}) do seenP[n]=true end
    end
    for _,it in ipairs(fam.items) do
      for _,n in ipairs(it.covers or it.spell or {}) do seenP[n]=true end
    end
  end
  local extraP={}
  for spell,id in pairs(BOOK) do if not seenP[spell] and id~=SBA_ID then extraP[#extraP+1]=spell end end
  table.sort(extraP)
  P.unmappedFamilySpells={}
  for _,spell in ipairs(extraP) do
    if P.ParkUnmappedSpell(spell, totems, attack, recover) then
      P.unmappedFamilySpells[#P.unmappedFamilySpells+1]=spell
    end
  end
  return primeFams
end

-- Elemental Farseer on Prime faces: EQ / Chain Lightning instead of CL / Bolt,
-- Gust of Wind instead of Feral Lunge, Stormkeeper on Ctrl-R.
function P.BuildFarseerFamilies()
  local attack={tag="E",title="Attack · E",bar={slot=3,key="E",sba=true,label="Assisted Rotation"},items={}}
  local disrupt={tag="Q",title="Disrupt · Q",bar={slot=1,key="Q",macro={"WindShear",136018,SHEAR_TEXT},label="Wind Shear",covers={"Wind Shear"}},items={}}
  local heal={tag="M5",title="Heal · M5",bar={slot=8,key="M5",bindKey="BUTTON5",macro={"HealSurge",136052,SURGE_TEXT},label="Healing Surge",covers={"Healing Surge"}},items={}}
  local totems={tag="T",title="Totems · wheel / T",bar={slot=5,key="Shift-WheelUp",bindKey="SHIFT-MOUSEWHEELUP",macro={"RushTotem",538576,"#showtooltip Wind Rush Totem\n/cast [@cursor] Wind Rush Totem"},label="Wind Rush Totem",covers={"Wind Rush Totem"}},items={}}
  local move={tag="M4",title="Move · M4",bar={slot=6,key="M4",spell={"Ghost Wolf"}},items={}}
  local protect={tag="C",title="Protect · C",bar={slot=4,key="C",bindKey="C",macro={"AstralWall",538565,"#showtooltip Astral Shift\n/cast Astral Shift"},label="Astral Shift",covers={"Astral Shift"}},items={}}
  local empower={tag="R",title="Empower · R",items={}}
  local travel={tag="X",title="Travel · X",items={
    {bindKey="X",key="X",macrotext=MOUNT_TEXT,label="Favorite mount",iconFile=132250,savedMacroName="FavMount"},
  }}
  local buffs={tag="BUF",title="Buffs · click",items={}}
  local recover={tag="+",title="Recover · click",items={}}

  P.FamilySpell(attack,{"Thunderstorm","Thunder Storm"},"SHIFT-E","plain","talented knockback / interrupt")
  P.FamilySpell(attack,"Chain Lightning","CTRL-E","harm","ranged area damage")
  P.FamilySpell(attack,{"Lightning Bolt","Tempest"},nil,nil,"SBA-covered; manual access")
  P.FamilySpell(attack,"Lava Burst",nil,nil,"SBA-covered; manual access")
  P.FamilySpell(attack,"Elemental Blast",nil,nil,"SBA-covered; manual access")
  P.FamilySpell(attack,{"Voltaic Blaze","Flame Shock"},nil,nil,"apply damage over time")
  P.FamilySpell(attack,"Earth Shock",nil,nil,"SBA-covered; manual access")
  P.FamilySpell(disrupt,"Purge","SHIFT-Q","harm","remove enemy buff")
  P.FamilySpell(disrupt,"Earthquake","CTRL-Q","cursor","maelstrom spender at cursor")
  P.FamilySpell(heal,"Chain Heal","SHIFT-BUTTON5","help","group heal; Alt forces self")
  P.FamilySpell(heal,"Nature's Swiftness",nil,nil,"instant next nature spell")
  P.FamilySpell(totems,"Capacitor Totem","SHIFT-MOUSEWHEELDOWN","cursor","stun at the cursor")
  P.FamilySpell(totems,{"Earthgrab Totem","Earthbind Totem"},nil,"cursor","control enemies · click")
  P.FamilySpell(totems,"Thorn Bloom",nil,"cursor","Haranir area ability · click")
  P.FamilySpell(totems,"Healing Stream Totem","T","cursor","sustain allies")
  P.FamilySpell(totems,"Tremor Totem","SHIFT-T","cursor","anti-fear utility")
  P.FamilySpell(totems,"Poison Cleansing Totem","CTRL-T","cursor","group cleanse")
  P.FamilySpell(move,"Gust of Wind","SHIFT-BUTTON4","plain","gap closer")
  P.FamilySpell(move,"Spirit Walk",nil,"plain","break roots")
  P.FamilySpell(protect,{"Cleanse Spirit","Purify Spirit"},"SHIFT-C","help","defensive dispel")
  P.FamilySpell(protect,"Spiritwalker's Grace","SHIFT-BUTTON3","plain","cast while moving")
  P.FamilySpell(protect,"Earth Elemental","BUTTON3",nil,"defensive summon")
  P.FamilySpell(empower,{"Ascendance","Doom Winds"},"R",nil,"active personal burst; replacement keeps this key")
  P.FamilySpell(empower,{"Heroism","Bloodlust"},"SHIFT-R","plain","deliberate group haste")
  P.FamilySpell(empower,"Stormkeeper","CTRL-R",nil,"charge lightning / blast")
  P.FamilySpell(travel,"Water Walking","SHIFT-X","help","water travel")
  P.FamilySpell(travel,"Far Sight","CTRL-X","cursor","look ahead")
  for _,spell in ipairs({"Skyfury","Lightning Shield","Earth Shield","Flametongue Weapon","Windfury Weapon","Water Shield","Earthliving Weapon"}) do
    P.FamilySpell(buffs,spell,nil,nil,"maintenance; manual access")
  end
  for _,spell in ipairs({"Recuperate","Ancestral Spirit","Astral Recall"}) do
    P.FamilySpell(recover,spell,nil,nil,"recovery / travel")
  end
  do
    local retName=Known("Rootwalking: Return")
    local root,rootId=Known("Rootwalking","Rootwalking: Return")
    if root then
      recover.items[#recover.items+1]={
        spell={root},label=retName or root,iconFile=SpellIcon(rootId,root),
        covers={"Rootwalking","Rootwalking: Return"},
        note="Haranir racial; leave Ghost Wolf, then click. Return is this same slot.",
      }
    end
  end
  recover.items[#recover.items+1]={itemID=6948,label="Hearthstone"}
  local farseerFams={attack,disrupt,heal,totems,move,protect,empower,travel,buffs,recover}
  local seenF={Hex=true}
  for _,fam in ipairs(farseerFams) do
    if fam.bar then
      for _,n in ipairs(fam.bar.covers or fam.bar.spell or {}) do seenF[n]=true end
    end
    for _,it in ipairs(fam.items) do
      for _,n in ipairs(it.covers or it.spell or {}) do seenF[n]=true end
    end
  end
  local extraF={}
  for spell,id in pairs(BOOK) do if not seenF[spell] and id~=SBA_ID then extraF[#extraF+1]=spell end end
  table.sort(extraF)
  P.unmappedFamilySpells={}
  for _,spell in ipairs(extraF) do
    if P.ParkUnmappedSpell(spell, totems, attack, recover) then
      P.unmappedFamilySpells[#P.unmappedFamilySpells+1]=spell
    end
  end
  return farseerFams
end

local function BuildFamilies()
  P.SelectFamilyHardware()
  if ShamanBindsDB.familyMode=="prime" then return P.BuildPrimeFamilies() end
  if ShamanBindsDB.familyMode=="farseer" then return P.BuildFarseerFamilies() end
  if ShamanBindsDB.familyMode=="pocket" then return P.BuildPocketFamilies() end
  if ShamanBindsDB.familyMode=="families" then return P.BuildPurposeFamilies() end
  return BuildLegacyFamilies()
end

function P.ClearFamilyKeys()
  -- Clear only commands belonging to our helpers, leaving unrelated bindings alone.
  local families=BuildFamilies()
  local keys={}
  for key in pairs(BAR_BINDS) do keys[key]=true end
  for _,family in ipairs(families) do for _,it in ipairs(family.items) do if it.bindKey then keys[it.bindKey]=true end end end
  for _,key in pairs(ShamanBindsDB.binds or {}) do if key~="" then keys[key]=true end end
  for key in pairs(keys) do
    local cmd=GetBindingAction(key)
    if type(cmd)=="string" and (cmd:find("^CLICK ShamanBinds") or cmd:find("^MACRO SB_")) then SetBinding(key) end
  end
  P.RestoreChatKeys()
end

function P.ActivatePurposeFamilies(force)
  local db=ShamanBindsDB
  if not force then
    if db.familyRevision==1 then return end
    if db.familyMode=="prime" or db.familyMode=="farseer" or db.familyMode=="pocket" or db.familyMode=="families" then
      db.familyRevision=1
      return
    end
  end
  if Locked() or P.OnSpecialBar() or not next(BOOK) then return end
  local name="Before family layout";local suffix=1
  while db.profiles[name] do suffix=suffix+1;name="Before family layout "..suffix end
  db.profiles[name]=P.SnapshotCurrent()
  P.ClearFamilyKeys()
  local old=db.custom
  db.custom,db.binds,db.barBinds,db.mods={},{},{},{}
  local tags={M5="TP",C="E",BUF="R"}
  if db.familyMode=="families" then tags={} end
  for tag,custom in pairs(old) do
    if type(custom)=="table" and type(custom.added)=="table" then
      local dest=tags[tag] or tag
      db.custom[dest]=db.custom[dest] or {added={},hidden={}}
      for _,item in ipairs(custom.added) do db.custom[dest].added[#db.custom[dest].added+1]=P.CopyData(item) end
    end
  end
  if force then
    db.familyMode,db.familyRevision,db.activeProfile="families",1,nil
    P.Report("Purpose-based families enabled. Previous setup saved as '"..name.."'.")
  else
    db.familyMode,db.familyRevision,db.activeProfile="prime",1,"Prime"
    P.Report("Prime is the default layout. Previous setup saved as '"..name.."'.")
  end
  P.SelectFamilyHardware()
end

-- ============================== CONSOLE (tab strip + drop-downs) ==============================

-- console / consoleTabs / allMenuButtons are declared at file top.

local function SavePosition(key, frame)
  local point, _, relPoint, x, y = frame:GetPoint(1)
  ShamanBindsDB.pos = ShamanBindsDB.pos or {}
  ShamanBindsDB.pos[key] = { point, relPoint, x, y }
end

local TAB_W, TAB_H = 48, 48
-- Empty width after the last tab, matching the :: grip on the left.
P.CONSOLE_END_PAD = 24
local TAB_GAP = 6
local BTN, GAP = 38, 5

-- Shadows are regions of the existing frame. No sibling frames, polling or hit areas.
local function AttachDropShadow(frame)
  if not frame or frame._sbShadow then return frame and frame._sbShadow end
  local layers = {}
  for i = 1, 3 do
    local shadow = P.VisualTexture(frame, "BACKGROUND", {0, 0, 0, 0.12 + i * 0.035}, -8 + i)
    shadow:SetPoint("TOPLEFT", -i, i - 1)
    shadow:SetPoint("BOTTOMRIGHT", i, -i - 2)
    layers[#layers + 1] = shadow
  end
  frame._sbShadow = layers
  return layers
end

local function DressIcon(frame, icon, opts)
  if not frame or not icon or frame._sbDressed then return end
  frame._sbDressed = true
  icon:ClearAllPoints()
  icon:SetPoint("TOPLEFT", 3, -3)
  icon:SetPoint("BOTTOMRIGHT", -3, 3)
  icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  if icon.SetSnapToPixelGrid then icon:SetSnapToPixelGrid(true) end
  P.VisualPanel(frame, P.Visual.panel, P.Visual.brass)
  frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=10,
    insets={left=2,right=2,top=2,bottom=2}})
  frame:SetBackdropColor(unpack(P.Visual.panel))
  frame:SetBackdropBorderColor(unpack(P.Visual.brass))
  frame._sbTopShine = P.VisualLine(frame, {0.85, 0.76, 0.56, 0.48}, 2, -2)
  local vignette = P.VisualTexture(frame, "OVERLAY", {0.015, 0.022, 0.03, 0.80}, 4)
  vignette:SetPoint("BOTTOMLEFT", 3, 3)
  vignette:SetPoint("BOTTOMRIGHT", -3, 3)
  vignette:SetHeight(15)
  frame._sbVignette = vignette
  if not (opts and opts.noHover) and not frame._sbHoverDress then
    frame._sbHoverDress = true
    frame:HookScript("OnEnter", function(self)
      self:SetBackdropBorderColor(unpack(P.Visual.teal))
    end)
    frame:HookScript("OnLeave", function(self)
      self:SetBackdropBorderColor(unpack(self._sbVisualLabel and P.Visual.edge or P.Visual.brass))
    end)
  end
  AttachDropShadow(frame)
end

-- Default action-button swipe on console faces. Totem sculptures keep the fill meter.
-- Pass cooldown numbers straight into SetCooldown. Midnight may secret them; the
-- widget can still animate. Do not compare or print start/duration.
function P.EnsureIconCooldown(frame)
  if not frame then return nil end
  if frame.cooldown then return frame.cooldown end
  local name = frame.GetName and frame:GetName()
  local cd = CreateFrame("Cooldown", name and (name .. "Cooldown") or nil, frame, "CooldownFrameTemplate")
  local icon = frame.icon
  if icon then
    cd:ClearAllPoints()
    cd:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
    cd:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
  else
    cd:SetAllPoints(frame)
  end
  if cd.SetDrawEdge then cd:SetDrawEdge(false) end
  if cd.SetHideCountdownNumbers then cd:SetHideCountdownNumbers(false) end
  if cd.SetSwipeColor then cd:SetSwipeColor(0, 0, 0, 0.8) end
  pcall(function() cd:SetFrameLevel((frame:GetFrameLevel() or 1) + 1) end)
  if frame.keyText and frame.keyText.SetDrawLayer then
    frame.keyText:SetDrawLayer("OVERLAY", 7)
  end
  frame.cooldown = cd
  return cd
end

function P.AbilitySpellIdentity(ab)
  if type(ab) ~= "table" then return nil, nil end
  local name = P.Text(ab.name) or P.Text(ab.label) or P.Text(ab.iconOf) or P.Text(ab.requires)
  if not name and P.Text(ab.macrotext) then
    name = ab.macrotext:match("#showtooltip%s+([^\r\n]+)")
    if name then name = name:match("^%s*(.-)%s*$") end
    if not P.Text(name) then
      name = ab.macrotext:match("/cast%s+%b[]%s*([^\r\n]+)") or ab.macrotext:match("/cast%s+([^\r\n]+)")
    end
    if name then name = name:match("^%s*(.-)%s*$") end
  end
  if not name and type(ab.covers) == "table" then
    for _, n in ipairs(ab.covers) do
      if P.Text(n) then name = n; break end
    end
  end
  local id = P.ID(ab.id)
  if not id and name then
    id = P.ID(BOOK[name] or (P.SPELL_ID and P.SPELL_ID[name]))
  end
  if not id and type(ab.covers) == "table" then
    for _, n in ipairs(ab.covers) do
      id = P.ID(BOOK[n] or (P.SPELL_ID and P.SPELL_ID[n]))
      if id then
        name = name or n
        break
      end
    end
  end
  if P.Text(name) then
    local knownName, knownId = Known(name)
    if knownId then id = id or P.ID(knownId) end
    name = knownName or name
  end
  return name, id
end

function P.CooldownSource(frame)
  if not frame then return nil end
  -- Drawer extras: use the ability cooldown, not a parked helper action slot.
  if frame._sbVisualLabel then
    if P.ID(frame.itemID) then return "item", frame.itemID end
    local inv = frame._sbEquipmentSlot or frame.equipmentSlot
    if P.ID(inv) then return "inv", inv end
    if P.ID(frame.spellID) then return "spell", frame.spellID end
    local name, id = P.AbilitySpellIdentity(frame._ability)
    if P.ID(id) then return "spell", id end
    if P.Text(name) then return "spellname", name end
  end
  local slot = P.BarSlotOf(frame)
  if not slot and frame.GetAttribute then
    if frame:GetAttribute("type") == "action" then
      slot = tonumber(frame:GetAttribute("action"))
    end
  end
  if P.ID(slot) then return "action", slot end
  local inv = frame._sbEquipmentSlot or frame.equipmentSlot
  if P.ID(inv) then return "inv", inv end
  if P.ID(frame.itemID) then return "item", frame.itemID end
  if P.ID(frame.spellID) then return "spell", frame.spellID end
  local ab = frame._ability
  if ab then
    if P.ID(ab.itemID) then return "item", ab.itemID end
    local name, id = P.AbilitySpellIdentity(ab)
    if P.ID(id) then return "spell", id end
    if P.Text(name) then return "spellname", name end
  end
end

function P.ReadIconCooldown(kind, id)
  local start, duration, modRate, enabled
  pcall(function()
    if kind == "action" and GetActionCooldown then
      start, duration, enabled, modRate = GetActionCooldown(id)
    elseif kind == "inv" and GetInventoryItemCooldown then
      start, duration = GetInventoryItemCooldown("player", id)
    elseif kind == "item" then
      if C_Container and C_Container.GetItemCooldown then
        start, duration = C_Container.GetItemCooldown(id)
      elseif GetItemCooldown then
        start, duration = GetItemCooldown(id)
      end
    elseif kind == "spell" or kind == "spellname" then
      local sid = id
      if kind == "spellname" then
        sid = BOOK[id] or (P.SPELL_ID and P.SPELL_ID[id])
      end
      if C_Spell and C_Spell.GetSpellCooldown then
        local a, b, c, d = C_Spell.GetSpellCooldown(sid or id)
        if type(a) == "table" then
          start, duration, modRate = a.startTime, a.duration, a.modRate
        else
          start, duration, modRate = a, b, d
        end
      elseif GetSpellCooldown then
        start, duration = GetSpellCooldown(sid or id)
      end
    end
  end)
  return start, duration, modRate
end

function P.ApplyIconCooldown(frame)
  if not frame then return end
  local cd = P.EnsureIconCooldown(frame)
  if not cd then return end
  local kind, id = P.CooldownSource(frame)
  if not kind then
    pcall(function() cd:Clear() end)
    return
  end
  local start, duration, modRate = P.ReadIconCooldown(kind, id)
  pcall(function()
    cd:SetCooldown(start, duration, modRate)
  end)
end

function P.DriveIconCooldowns()
  for _, tab in pairs(consoleTabs or {}) do
    if tab then P.ApplyIconCooldown(tab) end
  end
  for _, b in ipairs(allMenuButtons or {}) do
    if b then P.ApplyIconCooldown(b) end
  end
end

do
  local w = CreateFrame("Frame")
  w:RegisterEvent("SPELL_UPDATE_COOLDOWN")
  w:RegisterEvent("SPELL_UPDATE_CHARGES")
  w:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
  w:RegisterEvent("BAG_UPDATE_COOLDOWN")
  w:RegisterEvent("PLAYER_ENTERING_WORLD")
  w:SetScript("OnEvent", function()
    if P.DriveIconCooldowns then P.DriveIconCooldowns() end
  end)
end

-- Paint-only assisted highlight on console faces. Do not register as ActionButtons.
-- Totem sculptures stay on the fill meter. Do not compare secret spell IDs.
function P.AssistedHighlightActive()
  if AssistedCombatManager and AssistedCombatManager.IsAssistedHighlightActive then
    if P.FlagFn(function() return AssistedCombatManager:IsAssistedHighlightActive() end) then
      return true
    end
  end
  return P.FlagFn(function() return GetCVarBool("assistedCombatHighlight") end)
end

function P.ReadNextCastSpell()
  if not P.AssistedHighlightActive() then return nil end
  local id
  pcall(function()
    if C_AssistedCombat and C_AssistedCombat.GetNextCastSpell then
      -- false: recommend even when our faces are not Blizzard action buttons.
      id = C_AssistedCombat.GetNextCastSpell(false)
    end
  end)
  return P.ID(P.PublicNumber(id))
end

function P.SpellIDsMatch(a, b)
  a, b = P.ID(P.PublicNumber(a)), P.ID(P.PublicNumber(b))
  if not a or not b then return false end
  if a == b then return true end
  local ov
  pcall(function()
    if C_Spell and C_Spell.GetOverrideSpell then ov = C_Spell.GetOverrideSpell(a) end
  end)
  ov = P.ID(P.PublicNumber(ov))
  return ov and ov == b
end

function P.IconIsAssistedSBA(frame)
  local ab = frame and frame._ability
  if ab and ab.sba then return true end
  local id = P.ID(P.PublicNumber(frame and frame.spellID))
  if not id then return false end
  if id == SBA_ID then return true end
  local actionID
  pcall(function()
    if C_AssistedCombat and C_AssistedCombat.GetActionSpell then
      actionID = C_AssistedCombat.GetActionSpell()
    end
  end)
  actionID = P.ID(P.PublicNumber(actionID))
  return actionID and id == actionID
end

function P.IconMatchesNextCast(frame, nextID)
  if not frame or not nextID then return false end
  if not frame:IsShown() then return false end
  if P.IconIsAssistedSBA(frame) then return true end
  if P.SpellIDsMatch(frame.spellID, nextID) then return true end
  local ab = frame._ability
  local name, id = P.AbilitySpellIdentity(ab)
  if P.SpellIDsMatch(id, nextID) then return true end
  if P.Text(name) then
    if BOOK[name] and P.ID(P.PublicNumber(BOOK[name])) == nextID then return true end
    local nextName
    pcall(function() nextName = SpellName(nextID) end)
    if type(nextName) == "string" and nextName == name then return true end
  end
  if ab and type(ab.covers) == "table" then
    local nextName
    pcall(function() nextName = SpellName(nextID) end)
    for _, n in ipairs(ab.covers) do
      if P.Text(n) then
        if BOOK[n] and P.ID(P.PublicNumber(BOOK[n])) == nextID then return true end
        if type(nextName) == "string" and nextName == n then return true end
      end
    end
  end
  return false
end

function P.SizeAssistedHighlight(frame, hl)
  if not frame or not hl then return end
  -- Drawer rows are wide; wrap the 36px icon. Tabs are square; wrap the brass face.
  -- 1.4 matches Blizzard's action-button glow, which sits around the square, not inside it.
  local anchor, w, h = frame, frame:GetWidth(), frame:GetHeight()
  if frame._sbVisualLabel and frame.icon then
    anchor = frame.icon
    w, h = frame.icon:GetWidth(), frame.icon:GetHeight()
  end
  if not (P.Number(w) and P.Number(h) and w > 8 and h > 8) then
    w, h = 48, 48
  end
  hl:ClearAllPoints()
  hl:SetPoint("CENTER", anchor, "CENTER")
  hl:SetSize(w * 1.4, h * 1.4)
  if hl.Flipbook then
    hl.Flipbook:ClearAllPoints()
    hl.Flipbook:SetAllPoints(hl)
  end
end

function P.EnsureAssistedHighlight(frame)
  if not frame then return nil end
  if frame.AssistedCombatHighlightFrame then return frame.AssistedCombatHighlightFrame end
  local hl
  pcall(function()
    hl = CreateFrame("Frame", nil, frame, "ActionBarButtonAssistedCombatHighlightTemplate")
  end)
  if not hl then
    hl = CreateFrame("Frame", nil, frame)
    local tex = hl:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    tex:SetBlendMode("ADD")
    tex:SetVertexColor(0.12, 0.72, 1.0)
    hl.Fallback = tex
  end
  frame.AssistedCombatHighlightFrame = hl
  hl:EnableMouse(false)
  if hl.SetMouseClickEnabled then hl:SetMouseClickEnabled(false) end
  pcall(function() hl:SetFrameLevel((frame:GetFrameLevel() or 1) + 10) end)
  P.SizeAssistedHighlight(frame, hl)
  -- Crop the flipbook to one cell. Without Play-then-Stop the whole sheet
  -- draws as a tiny looping square.
  if hl.Flipbook and hl.Flipbook.Anim then
    pcall(function()
      hl.Flipbook.Anim:Play()
      hl.Flipbook.Anim:Stop()
    end)
  end
  hl:Hide()
  return hl
end

function P.ApplyAssistedHighlight(frame, nextID, inCombat)
  if not frame then return end
  local show = nextID and P.IconMatchesNextCast(frame, nextID) or false
  local hl = frame.AssistedCombatHighlightFrame
  if not show then
    if hl then
      hl:Hide()
      if hl.Flipbook and hl.Flipbook.Anim then
        pcall(function()
          if hl.Flipbook.Anim.IsPlaying and hl.Flipbook.Anim:IsPlaying() then
            hl.Flipbook.Anim:Stop()
          end
        end)
      end
    end
    return
  end
  hl = P.EnsureAssistedHighlight(frame)
  if not hl then return end
  hl:Show()
  if hl.Flipbook and hl.Flipbook.Anim then
    pcall(function()
      local anim = hl.Flipbook.Anim
      local playing = anim.IsPlaying and anim:IsPlaying()
      if inCombat then
        if not playing then anim:Play() end
      elseif playing then
        anim:Stop()
      end
    end)
  end
end

function P.DriveAssistedHighlights()
  local nextID = P.ReadNextCastSpell()
  local inCombat = P.regenCombat == true
  for _, tab in pairs(consoleTabs or {}) do
    if tab then P.ApplyAssistedHighlight(tab, nextID, inCombat) end
  end
  for _, b in ipairs(allMenuButtons or {}) do
    if b then P.ApplyAssistedHighlight(b, nextID, inCombat) end
  end
end

do
  local w = CreateFrame("Frame")
  local wait = 0
  w:SetScript("OnUpdate", function(_, elapsed)
    wait = wait - (elapsed or 0)
    if wait > 0 then return end
    local rate = 0.05
    if AssistedCombatManager and AssistedCombatManager.GetUpdateRate then
      pcall(function() rate = AssistedCombatManager:GetUpdateRate() or 0 end)
    end
    if not P.Number(rate) or rate < 0 then rate = 0.05 end
    wait = rate
    if P.DriveAssistedHighlights then P.DriveAssistedHighlights() end
  end)
  w:RegisterEvent("PLAYER_ENTERING_WORLD")
  w:RegisterEvent("PLAYER_REGEN_DISABLED")
  w:RegisterEvent("PLAYER_REGEN_ENABLED")
  w:SetScript("OnEvent", function()
    wait = 0
    if P.DriveAssistedHighlights then P.DriveAssistedHighlights() end
  end)
  pcall(function()
    if EventRegistry and EventRegistry.RegisterCallback then
      EventRegistry:RegisterCallback("AssistedCombatManager.OnSetUseAssistedHighlight", function()
        wait = 0
        if P.DriveAssistedHighlights then P.DriveAssistedHighlights() end
      end)
      EventRegistry:RegisterCallback("AssistedCombatManager.OnAssistedHighlightSpellChange", function()
        wait = 0
        if P.DriveAssistedHighlights then P.DriveAssistedHighlights() end
      end)
    end
  end)
end


-- Wheel totems: show the carved art above the bar while that spell is off cooldown.
P.TOTEM_READY = {
  { names = {"Wind Rush Totem"}, file = "Interface\\AddOns\\ShamanBinds\\Media\\TotemWindRush", width = 66, height = 133, tuck = 0, uv = { l = 95/256, r = 161/256, t = 111/256, b = 244/256 }, glow = {0.92, 0.97, 1.00} },
  { names = {"Capacitor Totem"}, file = "Interface\\AddOns\\ShamanBinds\\Media\\TotemCapacitor", tipInset = 58, glow = {0.30, 0.78, 1.00} },
  { names = {"Earthgrab Totem", "Earthbind Totem"}, file = "Interface\\AddOns\\ShamanBinds\\Media\\TotemEarthgrab", behind = true, fillTop = 63/256, glow = {0.40, 1.00, 0.45} },
  { names = {"Thorn Bloom"}, file = "Interface\\AddOns\\ShamanBinds\\Media\\TotemThornBloom", behind = true, size = 96, tuck = 0, uv = { l = 8/256, r = 248/256, t = 29/256, b = 1 }, glow = {1.00, 0.80, 0.28} },
  { names = {"Earth Elemental"},
    extra = true, size = 96, tuck = 8, cd = 300, glow = {1.00, 0.38, 0.12},
    file = "Interface\\AddOns\\ShamanBinds\\Media\\EarthElemental",
    skins = {
      { requires = {"Primal Elementalist"}, file = "Interface\\AddOns\\ShamanBinds\\Media\\EarthElemental" },
      { file = "Interface\\AddOns\\ShamanBinds\\Media\\EarthElemental" },
    },
  },
}

-- 256 * 0.75. Tuck keeps the same fraction of the image under the plate.
P.TOTEM_SIZE = 192
P.TOTEM_TUCK = 96

function P.EntrySize(entry)
  if entry and P.Number(entry.size) then return entry.size end
  return P.TOTEM_SIZE
end

function P.EntryWidth(entry)
  if entry and P.Number(entry.width) then return entry.width end
  return P.EntrySize(entry)
end

function P.EntryHeight(entry)
  if entry and P.Number(entry.height) then return entry.height end
  return P.EntrySize(entry)
end

function P.EntryTuck(entry)
  if entry and P.Number(entry.tuck) then return entry.tuck end
  if entry and entry.extra then return 8 end
  return P.TOTEM_TUCK
end

-- Pixel from the frame bottom where painted art ends. Uncropped textures
-- (Earthgrab) leave empty pad above the sculpture; the timer must stop there.
function P.TotemFillCap(entry, size)
  size = size or P.EntrySize(entry)
  local top = entry and entry.fillTop
  if P.Number(top) and top > 0 and top < 0.95 then
    return size * (1 - top)
  end
  return size
end

function P.TotemSpreadCount()
  local n = 0
  for _, e in ipairs(P.TOTEM_READY) do
    if not e.extra then n = n + 1 end
  end
  return math.max(n, 1)
end

function P.EntryRequiresMet(req)
  if req == nil then return true end
  if type(req) == "string" then return Known(req) and true or false end
  if type(req) ~= "table" then return false end
  for _, name in ipairs(req) do
    if not Known(name) then return false end
  end
  return true
end

function P.ResolveEntryFile(entry)
  if not entry then return nil end
  if type(entry.skins) == "table" then
    for _, skin in ipairs(entry.skins) do
      if P.EntryRequiresMet(skin.requires) then return skin.file end
    end
  end
  return entry.file
end

function P.TotemTexCoord(entry)
  local uv = entry and entry.uv
  if type(uv) == "table" and P.Number(uv.l) and P.Number(uv.r) and P.Number(uv.t) and P.Number(uv.b) then
    return uv.l, uv.r, uv.t, uv.b
  end
  return 0, 1, 0, 1
end

function P.ApplyTotemTexCoord(frame)
  if not frame then return end
  local l, r, t, b = P.TotemTexCoord(frame._sbEntry)
  if frame.grey and frame.grey.SetTexCoord then frame.grey:SetTexCoord(l, r, t, b) end
  if frame.fill and frame.fill.SetTexCoord then frame.fill:SetTexCoord(l, r, t, b) end
end

function P.ApplyTotemArt(frame)
  if not frame or not frame._sbEntry then return end
  local file = P.ResolveEntryFile(frame._sbEntry)
  if not file or frame._sbArtFile == file then return end
  frame._sbArtFile = file
  if frame.grey then frame.grey:SetTexture(file) end
  if frame.fill then frame.fill:SetTexture(file) end
  if frame.tex then frame.tex:SetTexture(file) end
  P.ApplyTotemTexCoord(frame)
end

function P.SpellCooldownPair(name)
  if not P.Text(name) then return nil, nil end
  local _, id = Known(name)
  if not P.ID(id) then id = BOOK[name] or P.SPELL_ID[name] end
  if not P.ID(id) then return nil, nil end
  local start, duration
  pcall(function()
    if C_Spell and C_Spell.GetSpellCooldown then
      local a, b = C_Spell.GetSpellCooldown(id)
      if issecretvalue and (issecretvalue(a) or issecretvalue(b)) then return end
      if type(a) == "table" then
        start = a.startTime
        duration = a.duration
      else
        start = a
        duration = b
      end
    elseif GetSpellCooldown then
      start, duration = GetSpellCooldown(id)
    end
  end)
  return P.PublicNumber(start), P.PublicNumber(duration)
end

function P.SpellCooldownDuration(name)
  local _, duration = P.SpellCooldownPair(name)
  return duration
end

function P.AscendanceReadyState()
  if P.PlayerIsHorde() then return false end
  local duration = P.SpellCooldownDuration("Ascendance")
  local usedAt = P._sbAscUsedAt
  if usedAt and (GetTime() - usedAt) < 3 then
    if duration and duration > 1.7 then
      P._sbAscUsedAt = nil
    else
      P._sbAscReady = false
      return false
    end
  elseif usedAt then
    P._sbAscUsedAt = nil
  end
  if duration == nil then
    if not P.PlayerKnows(114050) and not P.PlayerKnows(114051) and not P.PlayerKnows(114052)
      and not (BOOK and BOOK["Ascendance"]) then
      return false
    end
    if P._sbAscReady == nil then P._sbAscReady = true end
    return P._sbAscReady
  end
  P._sbAscReady = duration <= 1.7
  return P._sbAscReady
end

function P.UpdateEndcapEyes()
  if P.EnsureEndcapEyes then P.EnsureEndcapEyes() end
  if not console or not console._sbEyeGlows then return end
  local show = console:IsShown() and not P.PlayerIsHorde() and P.AscendanceReadyState()
  P._sbEyesReady = show and true or nil
  if not show then
    for _, glow in ipairs(console._sbEyeGlows) do
      if glow then glow:SetAlpha(0) end
    end
  end
  if P.PulseEndcapEyes then P.PulseEndcapEyes() end
  if P.DriveTotemFills then P.DriveTotemFills() end
end

function P.SpellBaseCooldown(name)
  local _, id = Known(name)
  if not P.ID(id) then id = BOOK[name] or P.SPELL_ID[name] end
  if not P.ID(id) then return nil end
  local ms
  pcall(function()
    if C_Spell and C_Spell.GetSpellBaseCooldown then
      ms = C_Spell.GetSpellBaseCooldown(id)
      if type(ms) == "table" then ms = ms[1] or ms.baseCooldown end
    elseif GetSpellBaseCooldown then
      ms = GetSpellBaseCooldown(id)
    end
  end)
  ms = P.PublicNumber(ms)
  if ms and ms > 2000 then return ms / 1000 end
end

function P.TotemKnownName(entry)
  if entry._sbKnown and Known(entry._sbKnown) then return entry._sbKnown end
  local name = Known(unpack(entry.names))
  if name then entry._sbKnown = name end
  return name or entry._sbKnown
end

-- true / false / nil (nil = Midnight hid the number; keep last vis)
function P.TotemSpellReady(entry)
  local name = P.TotemKnownName(entry)
  if not name then return false end
  local duration = P.SpellCooldownDuration(name)
  if duration == nil then return nil end
  -- GCD reports ~1.5s on every spell. Real totem CDs are much longer.
  return duration <= 1.7
end

-- Fill from the brass lip upward when the shaft is tucked under the plate.
function P.TotemFillWindow(frame)
  local entry = frame and frame._sbEntry
  local size = (frame and frame.GetHeight and frame:GetHeight()) or P.EntrySize(entry)
  if not size or size < 1 then size = P.EntrySize(entry) end
  local tuck = P.EntryTuck(entry)
  local base, vis = 0, size
  local parent = console
  if frame and frame.GetBottom and parent and parent.GetTop then
    local fb, ct = frame:GetBottom(), parent:GetTop()
    if fb and ct then
      local fs = frame:GetEffectiveScale() or 1
      local ps = parent:GetEffectiveScale() or 1
      local overlap = (ct * ps / fs) - fb
      if overlap > 4 and overlap < size - 4 then
        base = overlap
        vis = size - overlap
      end
    elseif not frame._sbUserPlaced then
      base = tuck
      vis = size - tuck
    end
  elseif frame and not frame._sbUserPlaced then
    base = tuck
    vis = size - tuck
  end
  local cap = P.TotemFillCap(entry, size)
  if cap < size and cap > base + 8 then
    vis = cap - base
  end
  if vis < 8 then
    base, vis = 0, size
  end
  return base, vis, size
end

function P.InvalidateTotemFillWindow(frame)
  if not frame then return end
  frame._sbFillBase, frame._sbFillVis, frame._sbFillSize = nil, nil, nil
  frame._sbFillH, frame._sbFillSetup = nil, nil
end

function P.CacheTotemFillWindow(frame)
  if frame and P.Number(frame._sbFillBase) and P.Number(frame._sbFillVis) and P.Number(frame._sbFillSize) then
    return frame._sbFillBase, frame._sbFillVis, frame._sbFillSize
  end
  local base, vis, size = P.TotemFillWindow(frame)
  base = math.floor((base or 0) + 0.5)
  size = math.floor((size or P.EntrySize(frame and frame._sbEntry)) + 0.5)
  vis = math.floor((vis or size) + 0.5)
  if vis < 8 then
    base, vis = 0, size
  end
  if frame then
    frame._sbFillBase, frame._sbFillVis, frame._sbFillSize = base, vis, size
  end
  return base, vis, size
end

function P.TotemFillProgress(frame)
  if not frame then return 1 end
  if frame._sbReady then return 1 end
  local start, dur = frame._sbCdStart, frame._sbCdDur
  if not P.Number(start) or not P.Number(dur) or dur <= 1.7 then return 1 end
  local p = (GetTime() - start) / dur
  if p < 0 then return 0 end
  if p > 1 then return 1 end
  return p
end

function P.TotemFillHideTip(frame)
  if frame.tip then frame.tip:Hide() end
  if frame.bloom then frame.bloom:Hide() end
end

function P.TotemFillShowReady(frame)
  local fill, grey, mask = frame.fill, frame.grey, frame.mask
  if grey then grey:Hide() end
  if fill and mask and frame._sbMasked then
    pcall(function() fill:RemoveMaskTexture(mask) end)
    frame._sbMasked = nil
  end
  if fill then
    fill:Show()
    fill:SetParent(frame)
    fill:ClearAllPoints()
    fill:SetAllPoints(frame)
    P.ApplyTotemTexCoord(frame)
  end
  P.TotemFillHideTip(frame)
  frame._sbFillH, frame._sbFillSetup = nil, nil
end

function P.UpdateTotemFillTip(frame, p, base, vis)
  local tip, bloom = frame.tip, frame.bloom
  if not tip then return end
  if not p or p <= 0.02 or p >= 0.98 then
    P.TotemFillHideTip(frame)
    return
  end
  local y = base + vis * p
  local pulse = 0.70 + 0.30 * math.sin(GetTime() * 11)
  local glow = (frame._sbEntry and frame._sbEntry.glow) or {1, 1, 1}
  local scale = (frame:GetWidth() or P.TOTEM_SIZE) / P.TOTEM_SIZE
  local inset, th = 22 * scale, 20 * scale
  local custom = frame._sbEntry and frame._sbEntry.tipInset
  if P.Number(custom) then inset = custom * scale end
  tip:SetVertexColor(glow[1], glow[2], glow[3])
  tip:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", inset, y - th / 2)
  tip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, y - th / 2)
  tip:SetHeight(th)
  tip:SetAlpha(pulse * 0.5)
  tip:Show()
  if bloom then
    local bh = 36 * scale
    bloom:SetVertexColor(glow[1], glow[2], glow[3])
    bloom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", inset - 10 * scale, y - bh / 2)
    bloom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(inset - 10 * scale), y - bh / 2)
    bloom:SetHeight(bh)
    bloom:SetAlpha(0.14 + 0.11 * pulse)
    bloom:Show()
  end
end

function P.TotemFillShowCooldown(frame, p)
  local fill, grey, mask = frame.fill, frame.grey, frame.mask
  if not fill or not mask then return end
  local base, vis = P.CacheTotemFillWindow(frame)
  local h = math.floor((vis * p) + 1e-6)
  if h < 0 then h = 0 end
  if not frame._sbFillSetup then
    if grey then grey:Show() end
    fill:SetParent(frame)
    fill:ClearAllPoints()
    fill:SetAllPoints(frame)
    P.ApplyTotemTexCoord(frame)
    if not frame._sbMasked then
      pcall(function() fill:AddMaskTexture(mask) end)
      frame._sbMasked = true
    end
    mask:ClearAllPoints()
    mask:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, base)
    mask:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, base)
    frame._sbFillSetup = true
  end
  if frame._sbFillH ~= h then
    frame._sbFillH = h
    if h < 1 then
      fill:Hide()
    else
      fill:Show()
      mask:SetHeight(h)
    end
  end
  P.UpdateTotemFillTip(frame, p, base, vis)
end

function P.ApplyTotemFill(frame, progress)
  if not frame or not frame.fill then return end
  local p = progress
  if p == nil then p = P.TotemFillProgress(frame) end
  if p >= 0.995 then
    P.TotemFillShowReady(frame)
    return
  end
  P.TotemFillShowCooldown(frame, p)
end

function P.DriveTotemFills()
  local rack = P.totemReadyRack
  local watch = P.totemReadyWatch
  if not watch then return end
  local any = false
  if rack then
    for _, f in ipairs(rack.icons or {}) do
      if f:IsShown() and P.TotemFillProgress(f) < 0.995 then
        any = true
        break
      end
    end
  end
  if any or P._sbEyesReady then
    if not watch._sbFillOn then
      watch._sbFillOn = true
      watch:SetScript("OnUpdate", P.TotemFillOnUpdate)
    end
  elseif watch._sbFillOn then
    watch._sbFillOn = nil
    watch:SetScript("OnUpdate", nil)
  end
end

function P.TotemFillOnUpdate()
  local rack = P.totemReadyRack
  local any = false
  if rack then
    for _, f in ipairs(rack.icons or {}) do
      if f:IsShown() then
        local p = P.TotemFillProgress(f)
        if p >= 1 then
          if f._sbCdStart or f._sbFillSetup then
            f._sbReady = true
            f._sbCdStart, f._sbCdDur = nil, nil
            P.ApplyTotemFill(f, 1)
          end
        else
          any = true
          P.ApplyTotemFill(f, p)
        end
      end
    end
  end
  local eyesOn = P.PulseEndcapEyes and P.PulseEndcapEyes()
  if not any and not eyesOn then P.DriveTotemFills() end
end

function P.ArmTotemCooldown(frame, start, duration)
  if not frame then return end
  if not P.Number(duration) or duration <= 1.7 then
    frame._sbCdStart, frame._sbCdDur = nil, nil
    frame._sbReady = true
    P.ApplyTotemFill(frame, 1)
    return
  end
  start = start or GetTime()
  if P.Number(frame._sbCdStart) and P.Number(frame._sbCdDur) and frame._sbCdDur > 1.7 then
    local oldEnd = frame._sbCdStart + frame._sbCdDur
    if math.abs(oldEnd - (start + duration)) < 0.4 then
      P.DriveTotemFills()
      return
    end
  end
  frame._sbCdStart = start
  frame._sbCdDur = duration
  frame._sbReady = false
  P.InvalidateTotemFillWindow(frame)
  P.ApplyTotemFill(frame, P.TotemFillProgress(frame))
  P.DriveTotemFills()
end

function P.MarkTotemUsed(spellName)
  if not P.Text(spellName) or not P.totemReadyRack then return end
  for _, f in ipairs(P.totemReadyRack.icons or {}) do
    local entry = f._sbEntry
    local match = false
    for _, n in ipairs(entry.names) do
      if n == spellName then match = true; break end
    end
    if not match and entry._sbKnown == spellName then match = true end
    if match then
      local start, duration = P.SpellCooldownPair(spellName)
      if not duration or duration <= 1.7 then
        duration = P.SpellBaseCooldown(spellName) or entry.cd or 30
        start = GetTime()
      end
      if f._sbTimer and f._sbTimer.Cancel then f._sbTimer:Cancel() end
      P.ArmTotemCooldown(f, start, duration)
      if C_Timer and C_Timer.NewTimer then
        f._sbTimer = C_Timer.NewTimer(duration + 0.08, function()
          f._sbTimer = nil
          f._sbReady = true
          f._sbCdStart, f._sbCdDur = nil, nil
          P.UpdateTotemReady()
        end)
      end
    end
  end
  P.UpdateTotemReady()
end

function P.TotemFrameLevel(entry)
  if entry and entry.behind then return 6 end
  return 12
end

function P.ApplyTotemChrome(frame)
  if not frame then return end
  local entry = frame._sbEntry or {}
  frame:SetFrameStrata("MEDIUM")
  frame:SetFrameLevel(frame._dragging and 20 or P.TotemFrameLevel(entry))
  local hit = frame.hit
  if not hit then return end
  hit:ClearAllPoints()
  if entry.behind or entry.extra then
    hit:SetAllPoints(frame)
  else
    -- Narrower grab so the back two can be reached around Wind Rush / Capacitor.
    -- Small frames cannot spare a 39px inset (Wind Rush is 66px wide).
    local w = (frame.GetWidth and frame:GetWidth()) or P.EntryWidth(entry) or P.TOTEM_SIZE
    if P.Number(w) and w < 90 then
      hit:SetAllPoints(frame)
    else
      hit:SetPoint("TOPLEFT", 39, 0)
      hit:SetPoint("BOTTOMRIGHT", -39, 0)
    end
  end
  hit:EnableMouse(not Locked() and not P.MenusBlockingTotems())
  pcall(function() hit:SetFrameLevel(frame:GetFrameLevel() + 1) end)
end

function P.TotemFrameOffset(frame)
  local parent = console
  if not frame or not parent then return 0, -P.EntryTuck(frame._sbEntry) end
  local fl, fb, fw = frame:GetLeft(), frame:GetBottom(), frame:GetWidth()
  local cl, ct, cw = parent:GetLeft(), parent:GetTop(), parent:GetWidth()
  if not fl or not fb or not cl or not ct then return 0, -P.EntryTuck(frame._sbEntry) end
  local fs, ps = frame:GetEffectiveScale(), parent:GetEffectiveScale()
  local x = ((fl + fw / 2) * fs - (cl + cw / 2) * ps) / ps
  local y = (fb * fs - ct * ps) / ps
  return math.floor(x * 10 + 0.5) / 10, math.floor(y * 10 + 0.5) / 10
end

function P.CommitTotemPlace(frame)
  if not frame or not frame._sbIndex then return end
  P.EnsureDB()
  local x, y = P.TotemFrameOffset(frame)
  ShamanBindsDB.totemPos = ShamanBindsDB.totemPos or {}
  ShamanBindsDB.totemPos[frame._sbIndex] = { x = x, y = y }
  frame._sbUserPlaced = true
  frame:ClearAllPoints()
  if console then frame:SetPoint("BOTTOM", console, "TOP", x, y) end
  P.InvalidateTotemFillWindow(frame)
  P.ApplyTotemChrome(frame)
end

function P.ApplyTotemPlace(frame)
  if not frame or not console then return end
  local entry = frame._sbEntry or {}
  local W = P.EntryWidth(entry)
  local H = P.EntryHeight(entry)
  local TUCK = P.EntryTuck(entry)
  frame:SetSize(W, H)
  local n = P.TotemSpreadCount()
  local barW = console:GetWidth() or 1
  local x, y
  local saved = ShamanBindsDB.totemPos and ShamanBindsDB.totemPos[frame._sbIndex]
  if type(saved) == "table" and P.Number(saved.x) and P.Number(saved.y) then
    x, y = saved.x, saved.y
    frame._sbUserPlaced = true
  elseif entry.extra then
    x = barW / 2 - 12
    y = -TUCK
  else
    x = -barW / 2 + (frame._sbIndex - 0.5) / n * barW
    y = -TUCK
  end
  frame:ClearAllPoints()
  frame:SetPoint("BOTTOM", console, "TOP", x, y)
  P.InvalidateTotemFillWindow(frame)
end

function P.TotemDragOnUpdate(self)
  if not self._dragging then return end
  if not IsMouseButtonDown("LeftButton") then
    self._dragging = false
    self:SetScript("OnUpdate", nil)
    P.CommitTotemPlace(self)
    return
  end
  local s = UIParent:GetEffectiveScale()
  local cx, cy = GetCursorPosition()
  self:ClearAllPoints()
  self:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", cx / s + (self._dx or 0), cy / s + (self._dy or 0))
end

function P.BeginTotemDrag(f)
  if Locked() or not f then return end
  local s = UIParent:GetEffectiveScale()
  local cx, cy = GetCursorPosition()
  cx, cy = cx / s, cy / s
  local left, bottom, w = f:GetLeft(), f:GetBottom(), f:GetWidth()
  if not left or not bottom then return end
  f._dx = (left + w / 2) - cx
  f._dy = bottom - cy
  f._dragging = true
  f._sbLaidOut = true
  P.ApplyTotemChrome(f)
  f:SetScript("OnUpdate", P.TotemDragOnUpdate)
end

function P.EnsureTotemReady(owner)
  owner = owner or console
  if not owner then return nil end
  if owner._sbTotemReady and owner._sbTotemReady.placeVer == 18 then
    P.totemReadyRack = owner._sbTotemReady
    for _, f in ipairs(owner._sbTotemReady.icons or {}) do P.ApplyTotemChrome(f) end
    return owner._sbTotemReady
  end
  if owner._sbTotemReady then
    if owner._sbTotemReady.Hide then owner._sbTotemReady:Hide() end
    for _, old in ipairs(owner._sbTotemReady.icons or {}) do
      if old.Hide then old:Hide() end
      if old.SetTexture then old:SetTexture(nil) end
    end
  end
  local rack = { icons = {}, parent = owner, placeVer = 18 }
  for i, entry in ipairs(P.TOTEM_READY) do
    local f = CreateFrame("Frame", "ShamanBindsTotemPlace"..i, UIParent)
    f:SetParent(UIParent)
    f:SetSize(P.EntryWidth(entry), P.EntryHeight(entry))
    f._sbEntry = entry
    f._sbIndex = i
    local artFile = P.ResolveEntryFile(entry) or entry.file
    local grey = f:CreateTexture(nil, "BACKGROUND")
    grey:SetAllPoints()
    grey:SetTexture(artFile)
    P.SmoothUITexture(grey)
    if grey.SetDesaturated then grey:SetDesaturated(true) end
    grey:SetVertexColor(0.52, 0.52, 0.56)
    grey:Hide()
    f.grey = grey
    local fill = f:CreateTexture(nil, "ARTWORK")
    fill:SetAllPoints()
    fill:SetTexture(artFile)
    P.SmoothUITexture(fill)
    f.fill = fill
    f.tex = fill
    f._sbArtFile = artFile
    P.ApplyTotemTexCoord(f)
    local mask
    if f.CreateMaskTexture then
      mask = f:CreateMaskTexture()
    else
      mask = f:CreateTexture(nil, "ARTWORK")
    end
    pcall(function()
      mask:SetTexture("Interface\\Buttons\\WHITE8X8", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    end)
    if mask.GetTexture and not mask:GetTexture() then
      mask:SetTexture("Interface\\Buttons\\WHITE8X8")
    end
    f.mask = mask
    local glowFile = "Interface\\AddOns\\ShamanBinds\\Media\\TotemFillTip"
    local glow = entry.glow or {1, 1, 1}
    local bloom = f:CreateTexture(nil, "OVERLAY")
    bloom:SetTexture(glowFile)
    bloom:SetBlendMode("ADD")
    bloom:SetVertexColor(glow[1], glow[2], glow[3])
    P.SmoothUITexture(bloom)
    bloom:Hide()
    f.bloom = bloom
    local tip = f:CreateTexture(nil, "OVERLAY", nil, 1)
    tip:SetTexture(glowFile)
    tip:SetBlendMode("ADD")
    tip:SetVertexColor(glow[1], glow[2], glow[3])
    P.SmoothUITexture(tip)
    tip:Hide()
    f.tip = tip
    local hit = f.hit
    if not hit then
      hit = CreateFrame("Frame", nil, f)
      f.hit = hit
    end
    hit:SetScript("OnMouseDown", function(_, button)
      if button == "LeftButton" then P.BeginTotemDrag(f) end
    end)
    hit:SetScript("OnEnter", function()
      P.ShowConsoleTooltip(hit, { tipText = (entry.names[1] or "Totem") }, {
        line = "Drag to place.",
      })
    end)
    hit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    P.ApplyTotemChrome(f)
    f:Hide()
    rack.icons[i] = f
  end
  owner._sbTotemReady = rack
  P.totemReadyRack = rack
  if not P.totemReadyWatch then
    local w = CreateFrame("Frame")
    w:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    w:RegisterEvent("SPELL_UPDATE_USABLE")
    w:RegisterEvent("SPELLS_CHANGED")
    w:RegisterEvent("PLAYER_ENTERING_WORLD")
    w:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    w:RegisterEvent("PLAYER_REGEN_DISABLED")
    w:RegisterEvent("PLAYER_REGEN_ENABLED")
    w:SetScript("OnEvent", function(_, event, unit, _, spellID)
      if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit ~= "player" then return end
        local name
        pcall(function()
          if issecretvalue and issecretvalue(spellID) then return end
          name = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)) or GetSpellInfo(spellID)
        end)
        if P.Text(name) then
          P.MarkTotemUsed(name)
          if name == "Ascendance" then
            P._sbAscReady = false
            P._sbAscUsedAt = GetTime()
            P._sbEyesReady = nil
            if P.PulseEndcapEyes then P.PulseEndcapEyes() end
            if P.DriveTotemFills then P.DriveTotemFills() end
          end
        end
        return
      end
      if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        for _, f in ipairs((P.totemReadyRack and P.totemReadyRack.icons) or {}) do
          P.ApplyTotemChrome(f)
        end
        if event == "PLAYER_REGEN_DISABLED" then return end
      end
      if P.totemReadyQueued then return end
      P.totemReadyQueued = true
      C_Timer.After(0, function()
        P.totemReadyQueued = nil
        P.UpdateTotemReady()
      end)
    end)
    P.totemReadyWatch = w
  end
  P.UpdateTotemReady()
  return rack
end

function P.UpdateTotemReady()
  local rack = P.totemReadyRack
  if not rack and console then P.EnsureTotemReady(console); rack = P.totemReadyRack end
  if not rack then
    if P.UpdateEndcapEyes then P.UpdateEndcapEyes() end
    return
  end
  if not console or not console:IsShown() then
    for _, f in ipairs(rack.icons) do f:Hide() end
    if P.UpdateEndcapEyes then P.UpdateEndcapEyes() end
    return
  end
  local wait
  for _, f in ipairs(rack.icons) do
    local entry = f._sbEntry
    local name = P.TotemKnownName(entry)
    if not name then
      f:Hide()
    else
      if not f._sbLaidOut then
        P.ApplyTotemPlace(f)
        f._sbLaidOut = true
      end
      f:Show()
      P.ApplyTotemArt(f)
      P.ApplyTotemChrome(f)
      local start, duration = P.SpellCooldownPair(name)
      local ready = P.TotemSpellReady(entry)
      if ready == true then
        -- GCD is ~1.5s and looks "ready". Keep a real totem CD fill going.
        if f._sbCdDur and f._sbCdDur > 1.7 and P.TotemFillProgress(f) < 0.995 then
          P.ApplyTotemFill(f, P.TotemFillProgress(f))
          local remaining = f._sbCdDur - (GetTime() - f._sbCdStart)
          if remaining > 0.05 and (not wait or remaining < wait) then wait = remaining end
        else
          f._sbReady = true
          f._sbCdStart, f._sbCdDur = nil, nil
          P.ApplyTotemFill(f, 1)
        end
      elseif ready == false and duration and duration > 1.7 then
        P.ArmTotemCooldown(f, start, duration)
        if not wait or duration < wait then wait = duration end
      elseif f._sbCdStart and f._sbCdDur then
        local p = P.TotemFillProgress(f)
        if p >= 1 then
          f._sbReady = true
          f._sbCdStart, f._sbCdDur = nil, nil
          P.ApplyTotemFill(f, 1)
        else
          P.ApplyTotemFill(f, p)
          local remaining = f._sbCdDur - (GetTime() - f._sbCdStart)
          if remaining > 0.05 and (not wait or remaining < wait) then wait = remaining end
        end
      else
        if f._sbReady == nil then f._sbReady = true end
        P.ApplyTotemFill(f, f._sbReady and 1 or 0)
      end
    end
  end
  if P.totemReadyHandle and P.totemReadyHandle.Cancel then
    P.totemReadyHandle:Cancel()
    P.totemReadyHandle = nil
  end
  if wait and C_Timer and C_Timer.NewTimer then
    P.totemReadyHandle = C_Timer.NewTimer(wait + 0.08, function()
      P.totemReadyHandle = nil
      P.UpdateTotemReady()
    end)
  end
  if P.UpdateEndcapEyes then P.UpdateEndcapEyes() end
end

P.QKB_ICON = "Interface\\Icons\\INV_Misc_Key_03"

function P.UpdateBindModeButton()
  local b = console and console._sbBindBtn
  if not b then return end
  local on = InQuickKeybind()
  if b.icon then
    b.icon:SetVertexColor(1, 1, 1)
  end
  if b._sbGlow then b._sbGlow:SetShown(on) end
  if b.label then
    b.label:SetText(on and "DONE" or "BIND")
    if on then
      b.label:SetTextColor(unpack(P.Visual.teal))
    else
      b.label:SetTextColor(unpack(P.Visual.text))
    end
  end
  if b.SetBackdropBorderColor then
    b:SetBackdropBorderColor(unpack(on and P.Visual.teal or P.Visual.brass))
  end
  if b._sbHint then
    b._sbHint:ClearAllPoints()
    if on then
      b._sbHint:SetPoint("BOTTOM", console, "TOP", 0, (P._sbBindBoardTop or 12) + 6)
    else
      b._sbHint:SetPoint("BOTTOM", console, "TOP", 0, 10)
    end
    b._sbHint:SetShown(on)
  end
end

function P.EnsureBindModeButton(owner)
  owner = owner or console
  if not owner then return nil end
  if owner._sbBindBtn then
    P.WireBindMove(owner._sbBindBtn)
    P.PlaceBindButton(owner._sbBindBtn)
    P.UpdateBindModeButton()
    return owner._sbBindBtn
  end
  -- UIParent, not the console: dragging BIND must not pick up the bar.
  local b = CreateFrame("Button", "ShamanBindsBindMode", UIParent, "BackdropTemplate")
  b:SetSize(TAB_H, TAB_H)
  b:SetFrameStrata("HIGH")
  b:SetFrameLevel(200)
  P.WireBindMove(b)
  P.PlaceBindButton(b)
  local icon = b:CreateTexture(nil, "ARTWORK")
  b.icon = icon
  DressIcon(b, icon)
  icon:SetTexture(P.QKB_ICON)
  local glow = b:CreateTexture(nil, "OVERLAY")
  glow:SetAllPoints()
  glow:SetColorTexture(0.27, 0.78, 0.76, 0.28)
  glow:Hide()
  b._sbGlow = glow
  local label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("BOTTOM", 0, 3)
  P.VisualFont(label, 9, P.Visual.text, "OUTLINE")
  label:SetText("BIND")
  b.label = label
  local hint = owner:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  hint:SetPoint("BOTTOM", owner, "TOP", 0, 10)
  P.VisualFont(hint, 11, P.Visual.teal)
  hint:SetText("Hover an icon, press a key or scroll. Ctrl-Wheel and Ctrl-M4/M5 stay zoom. Esc finishes.")
  hint:Hide()
  b._sbHint = hint
  b:SetScript("OnClick", function()
    P.ToggleQuickKeybind()
  end)
  b:HookScript("OnEnter", function()
    local on = InQuickKeybind()
    P.ShowConsoleTooltip(b, {
      tipText = on and "Finish keybind" or "Quick keybind",
    }, {
      line = on
        and "Click to leave bind mode. Escape also exits. Drag the gold lip to place this key."
        or "Hover a console icon and press a key or scroll. Ctrl-Wheel and Ctrl-M4/M5 stay camera zoom. Drag the gold lip to place this key.",
    })
  end)
  b:HookScript("OnLeave", function()
    GameTooltip:Hide()
    P.UpdateBindModeButton()
  end)
  owner._sbBindBtn = b
  P.UpdateBindModeButton()
  return b
end

local function EnsureConsole()
  if console then return console end
  console = CreateFrame("Frame", "ShamanBindsConsole", UIParent)
  console:SetSize(10, TAB_H)
  console:SetMovable(true)
  console:SetClampedToScreen(true)
  -- Above faded ActionButtons. Those stay mouse-enabled when the bar is
  -- shown, and used to sit on top of M5 and steal Astral Shift clicks.
  console:SetFrameStrata("HIGH")
  console:SetFrameLevel(50)
  P.SelectClassTheme()
  P.SkinConsole(console)

  local saved = ShamanBindsDB.pos and ShamanBindsDB.pos.console
  if saved then
    console:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
  elseif MainMenuBar then
    console:SetPoint("BOTTOM", MainMenuBar, "TOP", 0, 8)
  else
    console:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 120)
  end

  -- Always-visible move handle. Shift-drag on a tab picks up the ability;
  -- this grip (or Ctrl-drag a tab) moves the whole console.
  local grip = CreateFrame("Button", "ShamanBindsMoveGrip", console, "SecureActionButtonTemplate")
  grip:SetPoint("RIGHT", console, "LEFT", -2, 0)
  grip:SetSize(22, TAB_H)
  grip:SetFrameStrata("HIGH")
  grip:SetFrameLevel(200)
  console._sbGrip = grip
  P.RegisterFaceClicks(grip)
  P.WireMoveHandle(grip)
  local dots = grip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  dots:SetPoint("CENTER")
  dots:SetText("::")
  P.VisualFont(dots, 16, P.Visual.brass)
  dots:SetTextColor(0.96, 0.90, 0.76)
  dots:SetAlpha(0.85)
  grip:SetScript("OnEnter", function()
    dots:SetAlpha(1)
    P.ShowConsoleTooltip(grip, { tipText = "Move console" }, {
      line = "Drag here, Ctrl-drag a tab, or right-drag a tab.",
    })
  end)
  grip:SetScript("OnLeave", function()
    dots:SetAlpha(0.85)
    GameTooltip:Hide()
  end)

  local rail = CreateFrame("Button", "ShamanBindsMoveRail", console, "SecureActionButtonTemplate")
  rail:SetPoint("TOPLEFT", console, "BOTTOMLEFT", 0, -14)
  rail:SetPoint("TOPRIGHT", console, "BOTTOMRIGHT", 0, -14)
  rail:SetHeight(8)
  P.RegisterFaceClicks(rail)
  P.WireMoveHandle(rail)
  local railTex = rail:CreateTexture(nil, "BACKGROUND")
  railTex:SetAllPoints()
  railTex:SetColorTexture(P.Visual.teal[1], P.Visual.teal[2], P.Visual.teal[3], 0.10)
  console._sbRail = rail
  console._sbRailTex = railTex
  console:HookScript("OnHide", function()
    if P.UpdateMovePads then P.UpdateMovePads() end
    if P.UpdateTotemReady then P.UpdateTotemReady() end
    if console._sbBindBtn then console._sbBindBtn:Hide() end
  end)
  console:HookScript("OnShow", function()
    if P.UpdateMovePads then P.UpdateMovePads() end
    if P.UpdateTotemReady then P.UpdateTotemReady() end
    if console._sbBindBtn then console._sbBindBtn:Show() end
  end)

  P.EnsureBarDriver()
  P.ApplyConsoleMountedHide()
  P.EnsureTotemReady(console)
  if P.EnsureBindModeButton then P.EnsureBindModeButton(console) end
  return console
end

local function NewMenuButton(menu, famTag, i)
  local name = "ShamanBindsMenu_" .. famTag .. "_" .. i
  local b = CreateFrame("Button", name, menu, "SecureActionButtonTemplate, BackdropTemplate")
  b:SetSize(BTN, BTN)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  DressIcon(b, b.icon)

  b.keyText = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  b.keyText:SetPoint("BOTTOM", b, "BOTTOM", 0, 1)
  StyleKeyText(b.keyText)

  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  b:SetAttribute("pressAndHoldAction", true)
  b:EnableMouse(true)
  if b.SetMouseClickEnabled then b:SetMouseClickEnabled(true) end
  P.RegisterFaceClicks(b)

  b:SetScript("OnEnter", function(self)
    if self.spellID or self.itemID or self.tipText then
      P.ShowConsoleTooltip(self, self)
    end
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- Combat-safe collapse: when the mouse leaves this button and is no longer
  -- anywhere over the menu, hide the menu (runs in the secure environment).
  if menu.WrapScript then
    menu:WrapScript(b, "OnLeave", [[ if not owner:GetAttribute("holdopen") and not owner:IsUnderMouse(true) then owner:Hide() end ]])
  end

  P.SkinDrawer(b)
  allMenuButtons[#allMenuButtons + 1] = b
  return b
end

-- menus is declared at file top.

function P.StopConsoleMove()
  if not console then return end
  if Locked() then P.pendingMoveStop = true; return end
  pcall(function() console:StopMovingOrSizing() end)
  console._moving = false
  console:SetScript("OnUpdate", nil)
  P.pendingMoveStop = nil
  SavePosition("console", console)
end

function P.WireMoveHandle(frame)
  if not frame then return end
  frame:EnableMouse(true)
  frame:Show()
  frame:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" then P.StartConsoleMove() end
  end)
  frame:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then P.StopConsoleMove() end
  end)
  frame._sbMoveHandle = true
end

function P.PlaceBindButton(b)
  b = b or (console and console._sbBindBtn)
  if not b or not console then return end
  local saved = ShamanBindsDB.pos and ShamanBindsDB.pos.bind
  b:ClearAllPoints()
  if type(saved) == "table" and saved[1] and P.Number(saved[3]) and P.Number(saved[4]) then
    b:SetPoint(saved[1], console, saved[2] or "BOTTOMLEFT", saved[3], saved[4])
  else
    local grip = console._sbGrip
    if grip then
      b:SetPoint("RIGHT", grip, "LEFT", -6, 0)
    else
      b:SetPoint("RIGHT", console, "LEFT", -30, 0)
    end
  end
end

function P.BindDragOnUpdate(self)
  if not self._dragging then return end
  if not IsMouseButtonDown("LeftButton") then
    self._dragging = false
    self:SetScript("OnUpdate", nil)
    P.CommitBindPlace(self)
    return
  end
  local s = UIParent:GetEffectiveScale()
  local cx, cy = GetCursorPosition()
  self:ClearAllPoints()
  self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx / s + (self._dx or 0), cy / s + (self._dy or 0))
end

function P.BeginBindDrag(b)
  if Locked() or not b then return end
  local s = UIParent:GetEffectiveScale()
  local cx, cy = GetCursorPosition()
  cx, cy = cx / s, cy / s
  local left, bottom = b:GetLeft(), b:GetBottom()
  if not left or not bottom then return end
  b._dx = left - cx
  b._dy = bottom - cy
  b._dragging = true
  b:SetScript("OnUpdate", P.BindDragOnUpdate)
end

function P.CommitBindPlace(b)
  if not b or not console then return end
  local fl, fb = b:GetLeft(), b:GetBottom()
  local cl, cb = console:GetLeft(), console:GetBottom()
  if not P.Number(fl) or not P.Number(fb) or not P.Number(cl) or not P.Number(cb) then return end
  local x = math.floor((fl - cl) * 10 + 0.5) / 10
  local y = math.floor((fb - cb) * 10 + 0.5) / 10
  ShamanBindsDB.pos = ShamanBindsDB.pos or {}
  ShamanBindsDB.pos.bind = { "BOTTOMLEFT", "BOTTOMLEFT", x, y }
  b:ClearAllPoints()
  b:SetPoint("BOTTOMLEFT", console, "BOTTOMLEFT", x, y)
end

-- Click the key for Quick Keybind. The gold lip above it places BIND only.
function P.WireBindMove(frame)
  if not frame then return end
  frame:EnableMouse(true)
  frame:RegisterForClicks("LeftButtonUp")
  local handle = frame._sbDragHandle
  if not handle then
    handle = CreateFrame("Frame", "ShamanBindsBindGrip", frame)
    handle:SetHeight(10)
    local tex = handle:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetColorTexture(0.96, 0.90, 0.76, 0.70)
    handle.tex = tex
    handle:EnableMouse(true)
    handle:SetScript("OnMouseDown", function(_, button)
      if button == "LeftButton" then P.BeginBindDrag(frame) end
    end)
    handle:SetScript("OnEnter", function()
      tex:SetAlpha(1)
      P.ShowConsoleTooltip(handle, { tipText = "Move BIND" }, {
        line = "Drag this lip to place the key. The console stays put. Click the key to bind.",
      })
    end)
    handle:SetScript("OnLeave", function()
      tex:SetAlpha(0.70)
      GameTooltip:Hide()
    end)
    frame._sbDragHandle = handle
  end
  handle:ClearAllPoints()
  handle:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
  handle:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 2)
  handle:SetFrameStrata("HIGH")
  handle:SetFrameLevel((frame:GetFrameLevel() or 200) + 8)
  handle:Show()
end

function P.StartConsoleMove()
  if Locked() or drag.ability or InQuickKeybind() then return false end
  local c = EnsureConsole()
  -- A previous drag that never got MouseUp leaves _moving set; StartMoving
  -- then becomes a no-op. Always tear down and start a fresh move.
  if c._moving then pcall(function() c:StopMovingOrSizing() end) end
  c:StartMoving()
  c._moving = true
  for _, m in pairs(menus) do m:Hide() end
  return true
end

function P.RefreshMoveChrome()
  if not console then return end
  if console._moving then P.StopConsoleMove() end
  console:SetFrameStrata("HIGH")
  console:SetFrameLevel(50)
  if console._sbGrip then
    console._sbGrip:SetFrameStrata("HIGH")
    console._sbGrip:SetFrameLevel(200)
    P.WireMoveHandle(console._sbGrip)
  end
  if console._sbBindBtn then
    console._sbBindBtn:SetFrameStrata("HIGH")
    console._sbBindBtn:SetFrameLevel(200)
    P.WireBindMove(console._sbBindBtn)
  end
  if console._sbRail then
    console._sbRail:SetFrameStrata("HIGH")
    console._sbRail:SetFrameLevel(200)
    P.WireMoveHandle(console._sbRail)
  end
  for _, tab in pairs(consoleTabs) do
    local handle = tab._sbDragHandle
    if handle then
      handle:ClearAllPoints()
      handle:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
      handle:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 0, 0)
      handle:SetFrameLevel((tab:GetFrameLevel() or 1) + 50)
      pcall(function()
        if handle.SetMouseClickEnabled then handle:SetMouseClickEnabled(false) end
        handle:EnableMouse(false)
      end)
      handle:Show()
    end
  end
end

-- Ctrl-drag pads sit above the secure tab only while Ctrl is held, so a
-- normal click is never stolen. Alt is SELFCAST and never reaches us.
-- Track modifiers from MODIFIER_STATE_CHANGED only. IsControlKeyDown is
-- secret in Midnight and must not overwrite the event bit.
local movePads, movePoll = {}, nil

function P.UpdateMovePads()
  local on = P.ctrlHeld and not P.shiftHeld and not Locked() and not InQuickKeybind() and not drag.active
  for _, pad in ipairs(movePads) do
    pcall(function() pad:EnableMouse(on) end)
    if on and pad:GetParent() then
      pad:SetFrameLevel(pad:GetParent():GetFrameLevel() + 20)
    end
  end
end

local function EnsureMovePoll()
  if movePoll then return end
  movePoll = CreateFrame("Frame")
  movePoll:RegisterEvent("MODIFIER_STATE_CHANGED")
  movePoll:RegisterEvent("PLAYER_REGEN_ENABLED")
  movePoll:SetScript("OnEvent", function(_, event, key, down)
    if event == "PLAYER_REGEN_ENABLED" then
      if P.pendingMoveStop then P.StopConsoleMove() end
      P.UpdateMovePads()
      return
    end
    if type(key) ~= "string" then return end
    local k = string.upper(key)
    if k:find("CTRL", 1, true) then P.ctrlHeld = down == 1 or down == true end
    if k:find("SHIFT", 1, true) then P.shiftHeld = down == 1 or down == true end
    if k:find("ALT", 1, true) then P.altHeld = down == 1 or down == true end
    P.UpdateMovePads()
  end)
end

local function WireTabMove(tab)
  if not tab._moveWired then
    tab._moveWired = true
    pcall(function()
      tab:SetAttribute("shift-type1", "")
      tab:SetAttribute("ctrl-type1", "")
      tab:SetAttribute("alt-type1", "")
      tab:SetAttribute("checkselfcast", false)
    end)
    local pad = CreateFrame("Frame", nil, tab)
    pad:SetAllPoints(tab)
    pad:SetFrameLevel(tab:GetFrameLevel() + 20)
    pad:EnableMouse(false)
    pad:SetScript("OnMouseDown", function(_, button)
      if button == "LeftButton" then P.StartConsoleMove() end
    end)
    pad:SetScript("OnMouseUp", function(_, button)
      if button == "LeftButton" then P.StopConsoleMove() end
    end)
    tab._sbMovePad = pad
    movePads[#movePads + 1] = pad
    EnsureMovePoll()
    local handle = CreateFrame("Frame", nil, tab)
    handle:SetHeight(10)
    handle:EnableMouse(false)
    handle:SetScript("OnMouseDown", function(_, button)
      if button == "LeftButton" then P.StartConsoleMove() end
    end)
    handle:SetScript("OnMouseUp", function(_, button)
      if button == "LeftButton" then P.StopConsoleMove() end
    end)
    local tex = handle:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetColorTexture(0.96, 0.90, 0.76, 0.22)
    tab._sbDragHandle = handle
    tab:HookScript("OnMouseDown", function(_, button)
      if button == "RightButton" then P.StartConsoleMove() end
    end)
    tab:HookScript("OnMouseUp", function(_, button)
      if button == "RightButton" then P.StopConsoleMove() end
    end)
  end
  -- Re-arm after /load. Frame levels change; a stuck _moving flag is cleared
  -- in RefreshMoveChrome.
  local handle = tab._sbDragHandle
  if handle then
    handle:ClearAllPoints()
    handle:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
    handle:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 0, 0)
    handle:SetFrameLevel((tab:GetFrameLevel() or 1) + 50)
    -- Visual lip only. Clicks pass through to the tab so M4/M5 still fire.
    pcall(function()
      if handle.SetMouseClickEnabled then handle:SetMouseClickEnabled(false) end
      if handle.SetMouseMotionEnabled then handle:SetMouseMotionEnabled(false) end
      handle:EnableMouse(false)
    end)
    handle:Show()
  end
end

-- The tab opens its drawer; the catcher bridges only the gap ABOVE the icon.
-- Neither hover nor movement overlays cover ordinary parent clicks.
local CATCHER_ENTER = [[
  local m = self:GetFrameRef("menu")
  if m then m:Show() end
]]
local CATCHER_LEAVE = [[
  local m = self:GetFrameRef("menu")
  if not m or m:GetAttribute("holdopen") then return end
  local t = self:GetParent()
  if m:IsUnderMouse(true) or (t and t:IsUnderMouse(true)) then return end
  m:Hide()
]]
local TAB_HOVER_LEAVE = [[
  local m = self:GetFrameRef("menu")
  if not m or m:GetAttribute("holdopen") then return end
  if self:IsUnderMouse(true) or m:IsUnderMouse(true) then return end
  m:Hide()
]]
local MENU_HOVER_LEAVE = [[
  if self:GetAttribute("holdopen") then return end
  local t = self:GetParent()
  if self:IsUnderMouse(true) or (t and t:IsUnderMouse(true)) then return end
  self:Hide()
]]

local function FamilyStillHovered(tab, menu)
  if tab:IsMouseOver() then return true end
  if menu:IsMouseOver() then return true end
  local catcher = tab._sbCatcher
  return catcher and catcher:IsMouseOver()
end

local function ScheduleCollapse(tab, menu)
  C_Timer.After(0.12, function()
    if Locked() or not menu or menu:GetAttribute("holdopen") then return end
    if FamilyStillHovered(tab, menu) then return end
    pcall(function() menu:Hide() end)
  end)
end

-- Mixed templates do not reliably install the SetFrameRef convenience method.
-- Use the global secure API; it does not depend on template OnLoad ordering.
function P.SetSecureFrameRef(frame, label, target)
  if Locked() then return false end
  if type(SecureHandlerSetFrameRef) == "function" then
    SecureHandlerSetFrameRef(frame, label, target)
  elseif type(frame.SetFrameRef) == "function" then
    frame:SetFrameRef(label, target)
  else
    error("Secure frame-reference API unavailable; cannot configure drawer hover.")
  end
  return true
end

local function EnsureHoverCatcher(tab, menu)
  local catcher = tab._sbCatcher
  if not catcher then
    if Locked() then return nil end
    catcher = CreateFrame("Frame", tab:GetName() .. "Hover", tab,
      "SecureHandlerBaseTemplate, SecureHandlerEnterLeaveTemplate")
    catcher:EnableMouse(true)
    -- Hover only. Clicks must fall through to the tab so M4/M5 are not eaten.
    if catcher.SetMouseMotionEnabled then catcher:SetMouseMotionEnabled(true) end
    if catcher.SetMouseClickEnabled then catcher:SetMouseClickEnabled(false) end
    tab._sbCatcher = catcher
  end
  -- Always re-anchor. Older builds covered the icon; this strip is ONLY the
  -- gap above it. The tab itself owns hover/click on the full icon.
  catcher:ClearAllPoints()
  catcher:SetPoint("BOTTOMLEFT", tab, "TOPLEFT", 0, 0)
  catcher:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 0, 12)
  catcher:SetFrameLevel(tab:GetFrameLevel() + 10)
  if catcher.SetMouseClickEnabled then catcher:SetMouseClickEnabled(false) end
  P.SetSecureFrameRef(catcher, "menu", menu)
  catcher:SetAttribute("_onenter", CATCHER_ENTER)
  catcher:SetAttribute("_onleave", CATCHER_LEAVE)
  return catcher
end

local function WireHover(tab, menu)
  if not tab or not menu then return end
  menu:SetAttribute("_onleave", MENU_HOVER_LEAVE)
  P.SetSecureFrameRef(tab, "menu", menu)
  tab:SetAttribute("_onenter", CATCHER_ENTER)
  tab:SetAttribute("_onleave", TAB_HOVER_LEAVE)
  if not tab._sbMenuOnEnter then
    tab._sbMenuOnEnter = true
    tab:HookScript("OnEnter", function()
      if not Locked() then menu:Show() end
    end)
    tab:HookScript("OnLeave", function()
      ScheduleCollapse(tab, menu)
    end)
  end
  local catcher = EnsureHoverCatcher(tab, menu)
  if catcher and not catcher._sbTip then
    catcher._sbTip = true
    catcher:HookScript("OnEnter", function()
      if not Locked() then menu:Show() end
      if tab.spellID or tab.itemID or tab.tipText then
        P.ShowConsoleTooltip(tab, tab)
      end
    end)
    catcher:HookScript("OnLeave", function()
      GameTooltip:Hide()
      ScheduleCollapse(tab, menu)
    end)
  end
  if not menu._sbHoverInsecure then
    menu._sbHoverInsecure = true
    menu:HookScript("OnLeave", function() ScheduleCollapse(tab, menu) end)
  end
end

local function EnsureTab(famIndex, fam)
  local tab = consoleTabs[famIndex]
  if tab then
    tab:SetSize(TAB_W, TAB_H)
    tab:ClearAllPoints()
    tab:SetPoint("LEFT", EnsureConsole(), "LEFT", (famIndex - 1) * (TAB_W + TAB_GAP), 0)
    if tab.icon then DressIcon(tab, tab.icon) end
    P.RegisterFaceClicks(tab)
    tab:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    WireTabMove(tab)
    WireHover(tab, menus[famIndex])
    P.SkinParent(tab, fam)
    P.ArmMenuMouse(menus[famIndex])
    tab:Show()
    return tab, menus[famIndex]
  end

  local parent = EnsureConsole()
  -- Secure hover handlers share the parent action button. Frame references use
  -- the global API because mixed templates can omit convenience methods.
  tab = CreateFrame("Button", "ShamanBindsTab_" .. famIndex, parent,
    "SecureActionButtonTemplate, SecureHandlerBaseTemplate, SecureHandlerEnterLeaveTemplate, BackdropTemplate")
  tab:SetAttribute("pressAndHoldAction", true)
  P.RegisterFaceClicks(tab)
  tab:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  tab:EnableMouse(true)
  if tab.SetMouseClickEnabled then tab:SetMouseClickEnabled(true) end
  tab:SetSize(TAB_W, TAB_H)
  tab:SetPoint("LEFT", parent, "LEFT", (famIndex - 1) * (TAB_W + TAB_GAP), 0)
  tab.icon = tab:CreateTexture(nil, "ARTWORK")
  DressIcon(tab, tab.icon)

  tab.keyText = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  tab.keyText:SetPoint("BOTTOM", tab, "BOTTOM", 0, 2)
  StyleKeyText(tab.keyText)

  tab:HookScript("OnEnter", function(self)
    if self.spellID or self.itemID or self.tipText then
      P.ShowConsoleTooltip(self, self)
    end
  end)
  tab:HookScript("OnLeave", function() GameTooltip:Hide() end)

  local menu = CreateFrame("Frame", "ShamanBindsMenu_" .. famIndex, tab,
    "SecureHandlerBaseTemplate, SecureHandlerEnterLeaveTemplate, SecureHandlerShowHideTemplate, SecureHandlerStateTemplate, BackdropTemplate")
  menu:SetPoint("BOTTOM", tab, "TOP", 0, -1) -- overlap: no dead gap on the way up
  menu:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  P.SkinParent(tab, fam)
  P.SkinMenu(menu, tab)
  menu:Hide()
  menu.buttons = {}
  P.ArmMenuMouse(menu)

  WireHover(tab, menu)

  consoleTabs[famIndex] = tab
  menus[famIndex] = menu
  WireTabMove(tab)
  return tab, menu
end

-- Paint the tab as the family's primary icon (not a text label).
local function SetTabFace(tab, primary)
  P.ClearAction(tab)
  tab._sbBindId, tab.commandName, tab._sbDefaultKey = nil, nil, nil
  tab.spellID, tab.itemID, tab.tipText, tab.tipKey = nil, nil, nil, nil
  if not primary then
    tab.icon:SetTexture(134400)
    if tab.keyText then tab.keyText:SetText("") end
    return
  end
  tab.icon:SetTexture(primary.icon or 134400)
  tab.equipmentSlot, tab._sbEquipmentSlot = primary.equipmentSlot, primary.equipmentSlot
  if primary.equipmentSlot then tab.itemID = primary.tooltipItemID end
  tab.tipText = primary.label
  tab.tipKey = ShortKey(primary.key) or primary.key
  if tab.keyText then
    StyleKeyText(tab.keyText)
    tab.keyText:SetText(tab.tipKey or "")
  end
  if not Locked() then
    if primary.itemID then
      tab.itemID = primary.itemID
      tab:SetAttribute("type", "item")
      tab:SetAttribute("typerelease", "item")
      tab:SetAttribute("item", "item:" .. primary.itemID)
    elseif primary.macroIndex then
      tab:SetAttribute("type", "macro")
      tab:SetAttribute("typerelease", "macro")
      tab:SetAttribute("macro", primary.macroIndex)
    elseif primary.macrotext then
      tab:SetAttribute("type", "macro")
      tab:SetAttribute("typerelease", "macro")
      tab:SetAttribute("macrotext", primary.macrotext)
    elseif NeedsBlizzardSlot(primary) then
      -- Icon only. Caller wires type=action to a Blizzard slot.
    elseif primary.sba then
      local id = (C_AssistedCombat and C_AssistedCombat.GetActionSpell and C_AssistedCombat.GetActionSpell()) or SBA_ID
      tab.spellID = id
      tab:SetAttribute("type", "spell")
      tab:SetAttribute("typerelease", "spell")
      tab:SetAttribute("spell", id)
    elseif primary.name then
      tab.spellID = primary.id
      tab:SetAttribute("type", "spell")
      tab:SetAttribute("typerelease", "spell")
      tab:SetAttribute("spell", primary.name)
    end
  end
end

-- ============================== CUSTOM LAYOUT (shift-drop / shift-drag) ==============================

local function EnsureCustom(tag)
  if type(ShamanBindsDB.custom) ~= "table" then ShamanBindsDB.custom = {} end
  if type(ShamanBindsDB.custom[tag]) ~= "table" then ShamanBindsDB.custom[tag] = {} end
  local custom = ShamanBindsDB.custom[tag]
  if type(custom.added) ~= "table" then custom.added = {} end
  if type(custom.hidden) ~= "table" then custom.hidden = {} end
  return ShamanBindsDB.custom[tag]
end

-- GetCursorInfo("spell") is either (spellID) or (bookSlot, "spell").
-- Never treat a book slot as a spell ID, and never pass "spell" into
-- GetSpellBookItemInfo — that's the error you just hit.
local function CursorAbility()
  local function pub(value)
    if value == nil then return nil end
    if issecretvalue and issecretvalue(value) then return nil end
    return value
  end
  local function fromSpellID(id)
    if id == nil then return nil end
    local info
    pcall(function()
      if C_Spell and C_Spell.GetSpellInfo then info = C_Spell.GetSpellInfo(id) end
    end)
    local name, icon
    if type(info) == "table" then
      name = P.Text(info.name)
      icon = info.iconID or info.icon
    end
    if not name then
      local raw
      pcall(function() raw = SpellName(id) end)
      name = P.Text(raw)
    end
    if not name then return nil end
    local pubId = P.ID(P.PublicNumber(id))
    if not pubId and type(info) == "table" then pubId = P.ID(P.PublicNumber(info.spellID)) end
    if not pubId then pubId = BOOK[name] end
    return { kind = "spell", name = name, id = pubId, label = name, icon = SpellIcon(pubId, name) or icon or 134400 }
  end
  local function fromBookSlot(slot)
    if not P.ID(slot) then return nil end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    local info = P.BookInfo(slot, bank)
    return info and P.ID(info.spellID) or nil
  end
  local ok, ctype, a, b, spellID = pcall(GetCursorInfo)
  if not ok then return nil end
  -- Midnight can secret the id while leaving type="spell". Do not fail the
  -- whole pickup just because a payload field is secret.
  ctype = pub(ctype)
  if not ctype then return nil end
  if ctype == "mount" then
    return P.MountAbility(P.ID(pub(a)) or P.ID(pub(b)))
  end
  if ctype == "action" then
    local slot = P.ID(pub(a))
    if not slot then return nil end
    local actionType, id
    pcall(function() actionType, id = GetActionInfo(slot) end)
    actionType = pub(actionType)
    if actionType == "spell" then return fromSpellID(id) end
    if actionType == "macro" then
      local name, icon, body = GetMacroInfo(P.ID(pub(id)) or id)
      return { kind = "macro", label = name, icon = icon, macrotext = body }
    end
    if actionType == "item" then
      local item = P.ID(pub(id))
      if not item then return nil end
      local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(item)) or 134400
      return { kind = "item", itemID = item, label = "Item", icon = icon }
    end
    if actionType == "mount" or actionType == "summonmount" or actionType == "companion" then
      return P.MountAbility(id) or fromSpellID(id)
    end
    return nil
  end
  if ctype == "spell" then
    local pubSpell, pubA, pubB = pub(spellID), pub(a), pub(b)
    if P.ID(pubSpell) then return fromSpellID(pubSpell) end
    if pubB == "spell" or pubB == "pet" then
      local fromSlot = fromBookSlot(pubA)
      if fromSlot then return fromSpellID(fromSlot) end
    end
    local fromRaw = fromSpellID(spellID)
    if fromRaw then return fromRaw end
    if pubB ~= "spell" and pubB ~= "pet" then return fromSpellID(a) end
    return nil
  end
  if ctype == "item" then
    if not P.ID(a) then return nil end
    local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(a)) or 134400
    return { kind = "item", itemID = a, label = "Item", icon = icon }
  end
  if ctype == "macro" then
    if not P.ID(a) then return nil end
    local name, icon, body = GetMacroInfo(a)
    return { kind = "macro", label = name, icon = icon, macrotext = body }
  end
end

-- Payload is the FIRST ability picked up. Rebuilds must not overwrite it
-- (PlaceAction on Ghost Wolf was re-dropping 10 times while Shift was held).
-- busy / finishing are declared at file top.
local HideAllPlusSlots, ShowAllPlusSlots, PlacePlusSlot

local dragGhost

local function HideDragGhost()
  if dragGhost then dragGhost:Hide() end
end

local function PlaceDragGhost()
  if not dragGhost or not dragGhost:IsShown() then return end
  local x, y = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  dragGhost:ClearAllPoints()
  dragGhost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (x / scale) + 18, (y / scale) - 2)
end

local function ShowDragGhost(ability)
  if not dragGhost then
    local f = CreateFrame("Frame", "ShamanBindsDragGhost", UIParent, "BackdropTemplate")
    f:SetSize(34, 34)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(10000)
    f:EnableMouse(false)
    f:SetClampedToScreen(true)
    local tex = f:CreateTexture(nil, "ARTWORK")
    f.tex = tex
    f.icon = tex
    DressIcon(f, tex)
    f:SetBackdropBorderColor(0.93, 0.87, 0.72, 0.95)
    dragGhost = f
  end
  dragGhost.tex:SetTexture((ability and ability.icon) or 134400)
  dragGhost:SetBackdropBorderColor(unpack(P.Visual.teal))
  dragGhost:SetAlpha(0.95)
  dragGhost:Show()
  PlaceDragGhost()
end

local function ClearDrag()
  drag.ability, drag.fromTag, drag.bindKey, drag.fromPrimary, drag.active, drag.sawDown = nil, nil, nil, false, false, false
  HideDragGhost()
  HideAllPlusSlots()
  if P.dragWatch then P.dragWatch:Hide() end
  if P.dropRail then P.dropRail:Hide() end
  if P.trinketRefreshPending and P.QueueTrinketRefresh then P.QueueTrinketRefresh() end
  if P.pendingRefresh then
    C_Timer.After(0, function()
      if P.pendingRefresh and not Locked() and not busy and not drag.active
        and not P.dropRefreshQueued then RefreshLayout(true) end
    end)
  end
end

function P.CancelDrag(clearCursor)
  local external = drag.active and not drag.fromTag
  ClearDrag()
  if Locked() then P.pendingDragCleanup = true else HoldMenus(false) end
  if clearCursor and external and not Locked() then ClearCursor() end
end

local function TabUnderMouse()
  for _, tab in pairs(consoleTabs) do
    if OverOwn(tab) then return tab end
  end
end

local function MenuUnderMouse()
  for _, menu in pairs(menus) do
    if menu:IsShown() and menu:IsMouseOver() then return menu end
  end
end

-- Classic WoW plus-button art — reads as "add a slot".
-- A fixed row of add targets below the family captions. These are ordinary
-- UIParent frames: no native action widgets or protected click attributes.
function P.EnsureDropRail()
  if P.dropRail then return P.dropRail end
  local f = CreateFrame("Frame", "ShamanBindsDropRail", UIParent, "BackdropTemplate")
  f:SetFrameStrata("DIALOG")
  f:SetFrameLevel(250)
  f:SetClampedToScreen(true)
  f:EnableMouse(false)
  P.VisualPanel(f, P.Visual.ink, P.Visual.edge)
  P.VisualLine(f, P.Visual.teal, 1, -1)
  AttachDropShadow(f)
  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.title:SetPoint("TOPLEFT", 10, -8)
  f.title:SetJustifyH("LEFT")
  f.title:SetWordWrap(false)
  P.VisualFont(f.title, 10, P.Visual.text)
  f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.hint:SetPoint("TOPRIGHT", -10, -8)
  P.VisualFont(f.hint, 9, P.Visual.muted)
  f.hint:SetText("Esc / right-click to cancel")
  f.detail = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.detail:SetPoint("BOTTOMLEFT", 10, 9)
  f.detail:SetJustifyH("LEFT")
  f.detail:SetWordWrap(false)
  P.VisualFont(f.detail, 10, P.Visual.teal)
  f:SetScript("OnKeyDown", function(self, key)
    local cancel = key == "ESCAPE" and drag.active and not Locked()
    self:SetPropagateKeyboardInput(not cancel)
    if cancel then P.CancelDrag(true) end
  end)
  f:SetScript("OnUpdate", function(self, elapsed)
    -- Brief presentation fades only; no cursor, action or binding writes here.
    self.age = (self.age or 0) + elapsed
    if self.notice then
      if self.age >= 2 then self:Hide(); return end
      self:SetAlpha(math.min(1, (2 - self.age) / 0.2))
    end
  end)
  f:Hide()
  P.dropRail = f
  return f
end

function P.PositionDropRail(f)
  local scale = console:GetEffectiveScale() / UIParent:GetEffectiveScale()
  f:SetScale(scale)
  f:SetWidth(console:GetWidth() + 16)
  f.title:SetWidth(math.max(80, f:GetWidth() - 180))
  f.detail:SetWidth(f:GetWidth() - 20)
  f:ClearAllPoints()
  if (console:GetBottom() or 0) >= 108 then
    f:SetPoint("TOPLEFT", console, "BOTTOMLEFT", -8, -20)
  else
    -- A console parked at the screen bottom needs room above its drawers.
    -- Decide once at pickup, so opening a drawer cannot move the target.
    local height = 0
    for i, menu in ipairs(menus) do
      if consoleTabs[i] and consoleTabs[i]:IsShown() then height = math.max(height, menu:GetHeight()) end
    end
    f:SetPoint("BOTTOMLEFT", console, "TOPLEFT", -8, height + 12)
  end
end

function P.SetPlusHover(plus, over)
  if plus._sbOver == over then return end
  plus._sbOver = over
  plus:SetBackdropColor(unpack(over and {0.08, 0.23, 0.24, 1} or P.Visual.panel))
  plus:SetBackdropBorderColor(unpack(over and P.Visual.teal or P.Visual.edge))
  plus.glyph:SetTextColor(unpack(over and P.Visual.text or P.Visual.teal))
  plus.marker:SetAlpha(over and 1 or 0)
end

local function EnsurePlusSlot(tab, tag)
  if tab.plusSlot then tab.plusSlot.famTag = tag; return tab.plusSlot end
  local plus = CreateFrame("Button", nil, P.EnsureDropRail(), "BackdropTemplate")
  plus:SetSize(TAB_W, 32)
  plus:EnableMouse(true)
  plus:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
  P.VisualPanel(plus, P.Visual.panel, P.Visual.edge)
  plus.glyph = plus:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  plus.glyph:SetPoint("CENTER", 0, 1)
  P.VisualFont(plus.glyph, 22, P.Visual.teal)
  plus.glyph:SetText("+")
  plus.marker = P.VisualLine(plus, P.Visual.teal, 1, -1)
  plus.isPlusSlot, plus.famTag = true, tag
  plus:SetScript("OnEnter", function(self) P.SetPlusHover(self, true); GameTooltip:Hide() end)
  plus:SetScript("OnLeave", function(self) P.SetPlusHover(self, false) end)
  plus:SetScript("OnReceiveDrag", function() if P.ReceiveDrop then P.ReceiveDrop() end end)
  -- Commit on mouse-down. Click-drop clears the cursor before MouseUp, which
  -- used to cancel the session before + could add.
  plus:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" and P.ReceiveDrop then P.ReceiveDrop() end
  end)
  plus:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" and P.ReceiveDrop then P.ReceiveDrop() end
  end)
  P.SetPlusHover(plus, false)
  plus:Hide()
  tab.plusSlot = plus
  return plus
end

function PlacePlusSlot(tab)
  local plus = tab.plusSlot
  if not plus then return end
  plus:ClearAllPoints()
  plus:SetPoint("TOPLEFT", P.dropRail, "TOPLEFT", 8 + (tab._sbDropIndex - 1) * (TAB_W + TAB_GAP), -25)
end

function ShowAllPlusSlots()
  if not console or not console:IsShown() then return end
  local f = P.EnsureDropRail()
  P.PositionDropRail(f)
  f:SetHeight(82)
  f.title:SetText("ADD TO A FAMILY")
  f.hint:Show()
  f.detail:SetText("Choose a + below a family. New entries are click-to-use.")
  f.age, f.notice, f.preview = 0, false, nil
  f:SetAlpha(1)
  f:EnableKeyboard(true)
  f:SetPropagateKeyboardInput(true)
  for i, tab in ipairs(consoleTabs) do
    if tab.famTag and tab:IsShown() and not tab._sbEquipmentSlot then
      tab._sbDropIndex = i
      local plus = EnsurePlusSlot(tab, tab.famTag)
      plus._sbOver = nil
      P.SetPlusHover(plus, false)
      PlacePlusSlot(tab)
      plus:Show()
    elseif tab.plusSlot then tab.plusSlot:Hide() end
  end
  f:Show()
  GameTooltip:Hide()
end

function HideAllPlusSlots()
  for _, tab in pairs(consoleTabs) do
    if tab.plusSlot then tab.plusSlot:Hide() end
  end
end

function P.DropNotice(message)
  local f = P.EnsureDropRail()
  f:EnableKeyboard(false)
  f:SetHeight(46)
  f.title:SetText("FAMILY UPDATED")
  f.hint:Hide()
  f.detail:SetText(message)
  f.age, f.notice = 0, true
  f:SetAlpha(1)
  f:Show()
end

local function PlusUnderMouse()
  for _, tab in pairs(consoleTabs) do
    local plus = tab.plusSlot
    if plus and plus:IsVisible() and plus:IsMouseOver() then return plus end
  end
end

function HoldMenus(open)
  if Locked() then return end
  for _, menu in pairs(menus) do
    pcall(function()
      menu:SetAttribute("holdopen", open or nil)
      if not open and not menu:IsMouseOver() then menu:Hide() end
    end)
  end
end

local function SameAbility(a, b)
  local ak, bk = P.AbilityKey(a), P.AbilityKey(b)
  return ak ~= nil and ak == bk
end

local function AbilitySnapshot(ab)
  return NormalizeAbility(ab)
end

local function RecoverBindKey(tag, ability)
  if not tag or not ability then return nil end
  for _, b in ipairs(allMenuButtons) do
    if b:IsShown() and b.famTag == tag and b._sbBindKey and SameAbility(b._ability, ability) then
      return b._sbBindKey
    end
  end
end

local function InAdded(tag, ability)
  local c = ShamanBindsDB.custom and ShamanBindsDB.custom[tag]
  if not c or not c.added or not ability then return false end
  for _, e in ipairs(c.added) do
    if SameAbility(e, ability) then return true end
  end
  return false
end

local function ShownExtraNames(tag)
  local names = {}
  for _, b in ipairs(allMenuButtons) do
    if b:IsShown() and b.famTag == tag and b._ability then
      names[#names + 1] = P.AbilityKey(b._ability)
    end
  end
  return names
end

local function SwapExtraOrder(tag, a, b)
  local na, nb = P.AbilityKey(a), P.AbilityKey(b)
  if not tag or not na or not nb or na == nb then return false end
  local c = EnsureCustom(tag)
  -- The rendered order is authoritative, including entries added since a save.
  local order = ShownExtraNames(tag)
  local iA, iB
  for i, n in ipairs(order) do
    if n == na then iA = i end
    if n == nb then iB = i end
  end
  if not iA or not iB then return false end
  order[iA], order[iB] = order[iB], order[iA]
  c.order = order
  return true
end

local function ApplyExtraOrder(tag, extras)
  local c = ShamanBindsDB.custom and ShamanBindsDB.custom[tag]
  if not c or not c.order or #c.order == 0 then return extras end
  local used, out = {}, {}
  for _, saved in ipairs(c.order) do
    for i, r in ipairs(extras) do
      -- Read legacy label-based orders, then use full identities on the next swap.
      if not used[i] and (P.AbilityKey(r) == saved or (r.name or r.label) == saved) then
        out[#out + 1] = r; used[i] = true; break
      end
    end
  end
  for i, r in ipairs(extras) do if not used[i] then out[#out + 1] = r end end
  return out
end

local function DedupResolved(list)
  local seen, keyed, rest, out = {}, {}, {}, {}
  for _, r in ipairs(list) do
    if r.bindKey then
      keyed[#keyed + 1] = r
      local key = P.AbilityKey(r)
      if key then seen[key] = true end
    else rest[#rest + 1] = r end
  end
  for _, r in ipairs(keyed) do out[#out + 1] = r end
  for _, r in ipairs(rest) do
    local key = P.AbilityKey(r)
    if not key or not seen[key] then
      if key then seen[key] = true end
      out[#out + 1] = r
    end
  end
  return out
end

local function ReplaceAdded(tag, oldAb, newAb)
  local c = EnsureCustom(tag)
  c.added = c.added or {}
  for i, e in ipairs(c.added) do
    if SameAbility(e, oldAb) then
      if newAb then
        c.added[i] = AbilitySnapshot(newAb)
      else
        table.remove(c.added, i)
      end
      return true
    end
  end
  return false
end

local function RemoveExtra(tag, ability, quiet)
  local c = ShamanBindsDB.custom and ShamanBindsDB.custom[tag]
  if not c or not c.added then return false end
  local removed = false
  for i = #c.added, 1, -1 do
    if SameAbility(c.added[i], ability) then
      table.remove(c.added, i)
      removed = true
    end
  end
  if removed and not quiet then
    print("|cff0070ddShaman Binds:|r removed |cffffffff" .. (ability.label or ability.name or "?") .. "|r from " .. tag)
  end
  return removed
end

local function ClearModAbility(bindKey)
  if not bindKey or not ShamanBindsDB.mods or not ShamanBindsDB.mods[bindKey] then return false end
  ShamanBindsDB.mods[bindKey] = nil
  print("|cff0070ddShaman Binds:|r " .. ShortKey(bindKey) .. " reset to stock.")
  return true
end

local function AddExtra(tag, ability, quiet)
  ability = NormalizeAbility(ability)
  if Locked() or not ability or not P.Text(tag) then return false end
  local c = EnsureCustom(tag)
  c.added = c.added or {}
  for _, e in ipairs(c.added) do
    if SameAbility(e, ability) then return false end
  end
  -- Deduplicate within this family, not against every spell in the addon.
  -- Quiet callers are slot swaps: their old rows still exist until the rebuild.
  if not quiet then
    for _, tab in ipairs(consoleTabs) do
      if tab:IsShown() and tab.famTag == tag and SameAbility(tab._ability, ability) then return false end
    end
    for _, button in ipairs(allMenuButtons) do
      if button:IsShown() and button.famTag == tag and SameAbility(button._ability, ability) then return false end
    end
  end
  c.hidden[P.AbilityKey(ability)] = nil
  -- + is click-only. Drop onto a labelled extra (Shift-E, Ctrl-2, …) to key it.
  c.added[#c.added + 1] = AbilitySnapshot(ability)
  if not quiet then
    print("|cff0070ddShaman Binds:|r added |cffffffff" .. (ability.label or "?") .. "|r to " .. tag .. " (click). Drop on a keyed icon to bind it.")
  end
  return true
end

local function SetCustomPrimary(tag, ability, quiet)
  ability = NormalizeAbility(ability)
  if Locked() or not ability or not P.Text(tag) then return false end
  local c = EnsureCustom(tag)
  c.primary = NormalizeAbility(ability) or AbilitySnapshot(ability)
  if c.added then
    for i = #c.added, 1, -1 do
      if SameAbility(c.added[i], ability) then table.remove(c.added, i) end
    end
  end
  if not quiet then
    print("|cff0070ddShaman Binds:|r " .. tag .. " primary is now |cffffffff" .. (ability.label or "?") .. "|r")
  end
  return true
end

local function DisplaceIntoFamily(tag, incoming, displaced, dest)
  incoming = NormalizeAbility(incoming)
  displaced = displaced and NormalizeAbility(displaced) or nil
  dest = dest or {}
  if Locked() or not incoming or not P.Text(tag) then return false end
  if displaced and SameAbility(incoming, displaced) then return false end
  local placed = false
  if dest.primary then
    placed = SetCustomPrimary(tag, incoming, true)
  elseif dest.key then
    placed = SetModAbility(dest.key, incoming, true)
  else
    if displaced and InAdded(tag, displaced) then
      placed = ReplaceAdded(tag, displaced, incoming)
    end
    if not placed then placed = AddExtra(tag, incoming, true) end
  end
  if not placed then return false end
  if displaced then AddExtra(tag, displaced, true) end
  if displaced and not dest.primary and not dest.key then
    EnsureCustom(tag).hidden[P.AbilityKey(displaced)] = true
  end
  local into = (dest.tab and P.Text(dest.tab.famTitle)) or P.Visual.families[tag] or tag
  local newName = incoming.label or incoming.name or "Ability"
  local oldName = displaced and (displaced.label or displaced.name)
  if oldName then
    return true, newName .. " on " .. into .. " · " .. oldName .. " moved to the family"
  end
  return true, newName .. " added to " .. into
end

local function ExtraUnderMouse()
  for _, b in ipairs(allMenuButtons) do
    if b:IsShown() and OverOwn(b) and b._ability then return b end
  end
end

local function VacateSource(fromTag, fromKey, fromPrimary, ability)
  local changed = false
  if fromPrimary then
    local c = EnsureCustom(fromTag)
    if c.primary then
      c.primary = nil
      if fromKey then ClearModAbility(fromKey) end
      changed = true
      print("|cff0070ddShaman Binds:|r " .. fromTag .. " primary reset to stock.")
    end
    return changed
  end
  if fromKey then changed = ClearModAbility(fromKey) or changed end
  changed = RemoveExtra(fromTag, ability, true) or changed
  return changed
end

-- Swap two slots on the same family. Keys stay on their slots; only the
-- abilities move. dest/src fields: tag, key, primary, ability, added.
local function SwapSlots(src, dest)
  if Locked() or type(src) ~= "table" or type(dest) ~= "table"
    or not P.Text(src.tag) or src.tag ~= dest.tag then return false end
  local a = NormalizeAbility(src.ability)
  local b = NormalizeAbility(dest.ability)
  if not a or not b or SameAbility(a, b) then return false end
  if src.primary and dest.primary or src.key and src.key == dest.key then return false end
  if src.added and not InAdded(src.tag, a) or dest.added and not InAdded(dest.tag, b) then return false end
  -- Two unkeyed entries change visual order only, never overwrite each other's data.
  if not src.key and not src.primary and not dest.key and not dest.primary then
    return SwapExtraOrder(src.tag, a, b)
  end

  -- If this swap changes the T primary, modifier keys may hold Capacitor —
  -- that is only a no-op while Capacitor is still the nomod MMB spell.
  local newNomod = MMBNomodName()
  if dest.primary then
    newNomod = a.name or newNomod
  elseif src.primary then
    newNomod = b.name or newNomod
  end
  if dest.key and not CanPlaceOnKey(dest.key, a, newNomod) then return false end
  if src.key and not CanPlaceOnKey(src.key, b, newNomod) then return false end

  if dest.primary then
    SetCustomPrimary(dest.tag, a, true)
    if dest.key then SetModAbility(dest.key, a, true, newNomod) end
  elseif dest.key then
    SetModAbility(dest.key, a, true, newNomod)
  elseif dest.added then
    if not ReplaceAdded(dest.tag, dest.ability, a) then AddExtra(dest.tag, a, true) end
  else
    EnsureCustom(dest.tag).hidden[P.AbilityKey(b)] = true
    AddExtra(dest.tag, a, true)
  end

  if src.primary then
    SetCustomPrimary(src.tag, b, true)
    if src.key then SetModAbility(src.key, b, true, newNomod) end
  elseif src.key then
    SetModAbility(src.key, b, true, newNomod)
  elseif src.added then
    if not ReplaceAdded(src.tag, src.ability, b) then
      AddExtra(src.tag, b, true)
    end
  else
    EnsureCustom(src.tag).hidden[P.AbilityKey(a)] = true
    AddExtra(src.tag, b, true)
  end

  if not src.key and not src.primary and not dest.key and not dest.primary then
    SwapExtraOrder(src.tag, a, b)
  end

  print("|cff0070ddShaman Binds:|r swapped |cffffffff" .. (a.label or a.name) .. "|r and |cffffffff" .. (b.label or b.name) .. "|r")
  return true
end

function P.FinishDragImpl()
  if Locked() then P.pendingDragCleanup = true; return end
  if console and console._moving then return end
  if busy or finishing then return end
  local ability = drag.ability
  if not ability then
    ClearDrag()
    HoldMenus(false)
    return
  end
  local plus = PlusUnderMouse()
  local extra = ExtraUnderMouse()
  local tab = TabUnderMouse()
  local menu = MenuUnderMouse()
  local onRail = P.dropRail and P.dropRail:IsMouseOver()
  local fromTag = drag.fromTag
  local fromKey = drag.bindKey
  local fromPrimary = drag.fromPrimary
  if fromTag and not fromKey and not fromPrimary then
    fromKey = RecoverBindKey(fromTag, ability)
  end
  if not fromTag and not (plus or extra or tab or menu) then
    local ok, current = pcall(CursorAbility)
    if ok and current and SameAbility(current, ability) then
      -- Releasing over empty space can leave WoW's cursor occupied. Keep the
      -- targets available for a subsequent click instead of abandoning it.
      drag.sawDown = false
      return
    end
  end
  finishing = true
  ClearDrag()

  -- Drawer extras sit above the tab; a hit on an extra is not a tab drop.
  if plus then extra, tab, menu = nil, nil, nil end
  if extra then tab = nil end
  if extra or plus then menu = nil end

  local destTag = (extra and extra.famTag) or (plus and plus.famTag) or (tab and tab.famTag) or (menu and menu.famTag)
  local sameBar = fromTag and destTag and fromTag == destTag
  local srcAb = AbilitySnapshot(ability)

  -- Dropping a slot on itself is a no-op.
  if extra and sameBar and fromKey and extra._sbBindKey == fromKey then
    HoldMenus(false)
    finishing = false
    return
  end
  if tab and fromPrimary and tab.famTag == fromTag then
    HoldMenus(false)
    finishing = false
    return
  end
  if extra and sameBar and not fromKey and not fromPrimary and SameAbility(extra._ability, srcAb) then
    HoldMenus(false)
    finishing = false
    return
  end

  if (extra and extra._sbEquipmentSlot) or (tab and tab._sbEquipmentSlot) then
    HoldMenus(false)
    finishing = false
    P.Report("Trinket buttons follow equipped gear. Drop on + to add an ability instead.")
    return
  end
  local src = fromTag and {
    tag = fromTag,
    key = fromKey,
    primary = fromPrimary and true or nil,
    ability = srcAb,
    added = (not fromKey and not fromPrimary and InAdded(fromTag, srcAb)) or nil,
  }

  local changed, accepted, notice = false, false, nil
  if extra and extra._ability then
    local dest = {
      tag = extra.famTag,
      key = extra._sbBindKey,
      ability = AbilitySnapshot(extra._ability),
      added = (not extra._sbBindKey and InAdded(extra.famTag, extra._ability)) or nil,
      tab = extra,
    }
    if sameBar and src then
      changed = SwapSlots(src, dest)
    else
      changed, notice = DisplaceIntoFamily(extra.famTag, srcAb, dest.ability, dest)
      accepted = true
      if changed and fromTag then VacateSource(fromTag, fromKey, fromPrimary, srcAb) end
    end
  elseif plus and plus.famTag then
    changed = AddExtra(plus.famTag, srcAb)
    accepted = true
    if changed and fromTag then VacateSource(fromTag, fromKey, fromPrimary, srcAb) end
    notice = (srcAb.label or srcAb.name) .. (changed and " added to " or " already in ")
      .. (P.Visual.families[plus.famTag] or plus.famTag)
  elseif tab and tab.famTag then
    if fromTag and sameBar and src then
      local dest = {
        tag = tab.famTag,
        primary = true,
        key = tab._sbPrimaryKey,
        ability = NormalizeAbility(tab._ability) or AbilitySnapshot(tab._ability),
      }
      changed = SwapSlots(src, dest)
    else
      changed, notice = DisplaceIntoFamily(tab.famTag, srcAb, tab._ability, {
        primary = true, key = tab._sbPrimaryKey, tab = tab,
      })
      accepted = true
      if changed and fromTag then VacateSource(fromTag, fromKey, fromPrimary, srcAb) end
    end
  elseif menu and menu.famTag and not fromTag then
    changed = AddExtra(menu.famTag, srcAb)
    accepted = true
    notice = (srcAb.label or srcAb.name) .. (changed and " added to " or " already in ")
      .. (P.Visual.families[menu.famTag] or menu.famTag)
  elseif fromTag and not menu and not onRail then
    -- Shift-drag a drawer icon into empty space removes it.
    changed = VacateSource(fromTag, fromKey, fromPrimary, srcAb)
  end
  HoldMenus(false)
  if (changed or accepted) and not fromTag then ClearCursor() end
  if changed then
    -- One explicit drop, one deferred apply. Never place actions while hovering.
    -- Adding an ordinary click-only ability needs only our console rebuilt.
    local consoleOnly = not fromTag and not NeedsBlizzardSlot(srcAb)
      and not (tab and P.BarSlotOf(tab))
      and not (extra and P.BarSlotOf(extra))
    P.dropRefreshQueued = true
    C_Timer.After(0, function()
      P.dropRefreshQueued = false
      if RefreshLayout(consoleOnly) then
        if notice then P.DropNotice(notice) end
      else
        P.Report("Saved the drop. Leave combat, clear the cursor, then /shamanbinds to apply it.")
      end
    end)
  elseif notice then P.DropNotice(notice) end
  finishing = false
end

local function FinishDrag()
  if Locked() then P.pendingDragCleanup = true; return end
  if busy or finishing then return end
  local custom, mods = P.CopyData(ShamanBindsDB.custom), P.CopyData(ShamanBindsDB.mods)
  local ok, err = pcall(P.FinishDragImpl)
  finishing = false
  if not ok then
    ShamanBindsDB.custom, ShamanBindsDB.mods = custom, mods
    ClearDrag()
    HoldMenus(false)
    P.Report("Drop cancelled: " .. tostring(err))
  end
end

local function BeginInternalDrag(ability, tag, bindKey, fromPrimary)
  ability = NormalizeAbility(ability)
  if Locked() or busy or finishing or P.dropRefreshQueued or drag.active or not ability then return end
  if not bindKey and not fromPrimary then
    bindKey = RecoverBindKey(tag, ability)
  end
  drag.ability, drag.fromTag, drag.bindKey, drag.fromPrimary = ability, tag, bindKey, fromPrimary and true or false
  drag.active, drag.sawDown = true, true
  if P.dragWatch then P.dragWatch:Show() end
  ShowDragGhost(ability)
  HoldMenus(true)
  ShowAllPlusSlots()
  for i, t in pairs(consoleTabs) do
    if t.famTag == tag and menus[i] then menus[i]:Show() end
  end
end

local function WireTabPickup(tab, tag)
  tab.famTag = tag
  if tab._pickupWired then return end
  tab._pickupWired = true
  pcall(function()
    tab:SetAttribute("shift-type1", "")
    tab:SetAttribute("alt-type1", "")
  end)
  tab:HookScript("OnMouseDown", function(self, button)
    if self._sbEquipmentSlot then return end
    if InQuickKeybind() then return end
    if button ~= "LeftButton" or not P.shiftHeld then return end
    if drag.ability or (P.CursorKind() and P.CursorKind() ~= "secret") then return end
    for _, m in pairs(menus) do
      if m:IsShown() and m:IsMouseOver() then return end
    end
    if self._ability then
      BeginInternalDrag(self._ability, self.famTag or tag, self._sbPrimaryKey, true)
    end
  end)
  local catcher = tab._sbCatcher
  if catcher and not catcher._pickupWired then
    catcher._pickupWired = true
    catcher:HookScript("OnMouseDown", function(_, button)
      if tab._sbEquipmentSlot then return end
      if InQuickKeybind() then return end
      if button ~= "LeftButton" or not P.shiftHeld then return end
      if drag.ability or (P.CursorKind() and P.CursorKind() ~= "secret") then return end
      for _, m in pairs(menus) do
        if m:IsShown() and OverOwn(m) then return end
      end
      if tab._ability then
        BeginInternalDrag(tab._ability, tab.famTag or tag, tab._sbPrimaryKey, true)
      end
    end)
  end
end

local function WireDropTargets(tab, menu, tag)
  tab.famTag = tag
  menu.famTag = tag
  WireTabPickup(tab, tag)
  -- Also support click-to-pick-up, click-to-drop from the spellbook.
  tab:SetScript("OnReceiveDrag", function() P.ReceiveDrop() end)
  menu:SetScript("OnReceiveDrag", function() P.ReceiveDrop() end)
end

local function WireExtraDrag(b, tag)
  b.famTag = tag
  pcall(function()
    b:SetAttribute("shift-type1", "")
    b:SetAttribute("shift-type*", "")
  end)
  if b._dragWired then return end
  b._dragWired = true
  b:HookScript("OnMouseDown", function(self, button)
    if self._sbEquipmentSlot then return end
    if InQuickKeybind() then return end
    if button ~= "LeftButton" or not P.shiftHeld then return end
    BeginInternalDrag(self._ability, self.famTag or tag, self._sbBindKey)
  end)
  b:SetScript("OnReceiveDrag", function() if P.ReceiveDrop then P.ReceiveDrop() end end)
end

function P.StartExternalDrag()
  if Locked() or busy or finishing or P.dropRefreshQueued or InQuickKeybind() then return false end
  if drag.active then return true end
  local ok, ability = pcall(CursorAbility)
  ability = ok and NormalizeAbility(ability) or nil
  if not ability then return false end
  drag.ability, drag.active, drag.fromTag, drag.fromPrimary, drag.bindKey = ability, true, nil, false, nil
  drag.sawDown = IsMouseButtonDown("LeftButton") and true or false
  if P.dragWatch then P.dragWatch:Show() end
  -- WoW already draws the external cursor icon. Only internal drags need a ghost.
  HoldMenus(true)
  ShowAllPlusSlots()
  return true
end

function P.ReceiveDrop()
  if Locked() or busy or finishing or P.dropRefreshQueued then return end
  if not drag.active and not P.StartExternalDrag() then return end
  drag.sawDown = true
  FinishDrag()
end

function P.UpdateDropPreview()
  local rail = P.dropRail
  if not rail or not rail:IsShown() or rail.notice then return end
  local plus, extra, tab = PlusUnderMouse(), ExtraUnderMouse(), TabUnderMouse()
  local ability = drag.ability
  if not ability then return end
  local name = ability.label or ability.name or "Ability"
  local target = plus or extra or tab
  local family = target and (P.Visual.families[target.famTag] or target.famTag)
  local message
  if plus then
    message = name .. "  >  " .. family .. "  /  Release to add; click to use"
  elseif extra then
    if drag.fromTag == extra.famTag then
      message = name .. "  /  Swap with " .. (extra._ability.label or extra._ability.name or "this ability")
    else
      message = name .. "  >  " .. family .. "  /  Place here; current ability moves to the family"
    end
  elseif tab then
    if drag.fromTag then
      message = name .. "  >  " .. family .. "  /  Replace the parent ability"
    else
      message = name .. "  >  " .. family .. "  /  Place here; current ability moves to the family"
    end
  elseif drag.fromTag and not MenuUnderMouse() and not rail:IsMouseOver() then
    message = name .. "  /  Release outside to remove or reset this slot. Esc cancels."
  else
    message = name .. "  /  Choose a + to add. Esc cancels."
  end
  if rail.preview ~= message then rail.preview = message; rail.detail:SetText(message) end
  for _, parent in ipairs(consoleTabs) do
    if parent.plusSlot and parent.plusSlot:IsShown() then P.SetPlusHover(parent.plusSlot, parent.plusSlot == plus) end
  end
end

-- Cursor events start/cancel a session; one release commits it. A stale payload
-- must never survive Escape, a drop outside the addon, or a different pickup.
local dragWatch = CreateFrame("Frame")
P.dragWatch = dragWatch
dragWatch:Hide() -- events still arrive; no idle OnUpdate polling
dragWatch:RegisterEvent("CURSOR_CHANGED")
dragWatch:RegisterEvent("GLOBAL_MOUSE_DOWN")
dragWatch:RegisterEvent("PLAYER_REGEN_DISABLED")
dragWatch:SetScript("OnEvent", function(_, event, button)
  if event == "PLAYER_REGEN_DISABLED" then
    if drag.active then P.CancelDrag(false) end
    return
  end
  if event == "GLOBAL_MOUSE_DOWN" then
    if button == "RightButton" and drag.active then P.CancelDrag(true) end
    return
  end
  if Locked() or busy or finishing or P.dropRefreshQueued then return end
  if drag.active then
    if drag.fromTag then return end
    local ok, current = pcall(CursorAbility)
    if ok and current and SameAbility(current, drag.ability) then return end
    -- Spellbook can keep a live cursor while GetCursorInfo ids go secret.
    local kind = P.CursorKind()
    if kind == "spell" or kind == "pet" or kind == "secret" then return end
    -- Click-drop on + clears the cursor before MouseUp. Do not cancel while
    -- the pointer is still over a drop target.
    if not kind then
      if PlusUnderMouse() or ExtraUnderMouse() or TabUnderMouse() or MenuUnderMouse() then return end
    end
    P.CancelDrag(false)
  end
  P.StartExternalDrag()
end)
dragWatch:SetScript("OnUpdate", function()
  if not drag.active then return end
  if Locked() then P.CancelDrag(false); return end
  if busy or finishing or P.dropRefreshQueued then return end
  if not console or not console:IsShown() or InQuickKeybind() then P.CancelDrag(false); return end
  PlaceDragGhost()
  P.UpdateDropPreview()
  if IsMouseButtonDown("LeftButton") then drag.sawDown = true; return end
  if drag.sawDown then FinishDrag() end
end)

local function BarPrimary(barEntry)
  if not barEntry then return nil end
  if barEntry.sba then
    return {
      sba = true, label = barEntry.label, icon = SpellIcon(SBA_ID),
      key = barEntry.key, note = barEntry.note,
    }
  elseif barEntry.macro then
    return {
      macrotext = barEntry.macro[3], label = barEntry.label or barEntry.macro[1],
      icon = barEntry.macro[2], key = barEntry.key, note = barEntry.note,
    }
  elseif barEntry.spell then
    local name, id = Known(unpack(barEntry.spell))
    if not name then return nil end
    return {
      name = name, id = id, label = barEntry.label or name, icon = SpellIcon(id, name),
      key = barEntry.key, note = barEntry.note,
    }
  end
end

-- Configure one drop-down button for a resolved item.
local function SetMenuButton(b, r, bindNow)
  P.ClearAction(b)
  b._sbBindId, b.commandName, b._sbDefaultKey = nil, nil, nil
  b.spellID, b.itemID, b.tipText = nil, nil, nil
  if NeedsBlizzardSlot(r) and not r.blizzardSlot then
    RouteToHiddenSlot(r, bindNow == true and not Locked())
  end
  if r.itemID then
    b.itemID = r.itemID
    b:SetAttribute("type", "item")
    b:SetAttribute("typerelease", "item")
    b:SetAttribute("item", "item:" .. r.itemID)
    b.icon:SetTexture(r.icon)
  elseif r.macroIndex then
    b.tipText = r.label
    b:SetAttribute("type", "macro")
    b:SetAttribute("typerelease", "macro")
    b:SetAttribute("macro", r.macroIndex)
    b.icon:SetTexture(r.icon)
  elseif r.blizzardSlot then
    b.tipText = r.label
    b:SetAttribute("type", "action")
    b:SetAttribute("typerelease", "action")
    b:SetAttribute("action", r.blizzardSlot)
    b.icon:SetTexture(r.icon)
  elseif r.macrotext then
    b.tipText = r.label
    b:SetAttribute("type", "macro")
    b:SetAttribute("typerelease", "macro")
    b:SetAttribute("macrotext", r.macrotext)
    b.icon:SetTexture(r.icon)
  elseif r.sba then
    b.spellID = (C_AssistedCombat and C_AssistedCombat.GetActionSpell and C_AssistedCombat.GetActionSpell()) or SBA_ID
    b:SetAttribute("type", "spell")
    b:SetAttribute("typerelease", "spell")
    b:SetAttribute("spell", b.spellID)
    b.icon:SetTexture(r.icon)
  else
    b.spellID = r.id
    b:SetAttribute("type", "spell")
    b:SetAttribute("typerelease", "spell")
    b:SetAttribute("spell", r.name)
    b.icon:SetTexture(r.icon)
  end
  if not P.ID(b.spellID) then
    local _, sid = P.AbilitySpellIdentity(r)
    if P.ID(sid) then b.spellID = sid end
  end
  b._sbBindKey = r.bindKey
  b.equipmentSlot, b._sbEquipmentSlot = r.equipmentSlot, r.equipmentSlot
  if r.equipmentSlot then b.itemID = r.tooltipItemID end
  P.ArmModifiedCast(b)
  P.ArmCancelForm(b, r)
  if r.bindId then
    SetupClickButton(r.bindId, r)
    WireQuickKeybind(b, P.HardwareCommand(r.bindKey, r.blizzardSlot, r.commandName or ClickCommand(r.bindId)), r.bindId, r.bindKey)
  end
  local clickLabel = r.equipmentSlot and ("Trinket " .. (r.equipmentSlot - 12) .. "  /  Click") or "Click"
  b.keyText:SetText(ShortKey(EffectiveKey(r.bindId, r.bindKey)) or (r.bindKey and "") or clickLabel)


  b._ability = {
    kind = r.mountID and "mount" or r.itemID and "item" or r.sba and "sba" or r.macrotext and "macro" or "spell",
    name = r.name, id = r.id, label = r.label, icon = r.icon,
    itemID = r.itemID, mountID = r.mountID, macrotext = r.macrotext, sba = r.sba,
    covers = r.covers, iconOf = r.iconOf, requires = r.requires,
    savedMacroName = r.savedMacroName or (P.MACRO_SHORT_BY_LABEL and (P.MACRO_SHORT_BY_LABEL[r.label] or P.MACRO_SHORT_BY_LABEL[r.name])),
  }
  if not P.ID(b._ability.id) or not P.Text(b._ability.name) then
    local nm, sid = P.AbilitySpellIdentity(b._ability)
    b._ability.name = b._ability.name or nm
    b._ability.id = b._ability.id or sid
    b.spellID = b.spellID or sid
  end
  P.UpdateDrawerVisual(b, r)
  if P.ApplyIconCooldown then P.ApplyIconCooldown(b) end
  b:Show()
  if P.ApplyAssistedHighlight then
    P.ApplyAssistedHighlight(b, P.ReadNextCastSpell and P.ReadNextCastSpell(), P.regenCombat == true)
  end
end

-- Lay a menu's resolved items into a grid and size the backdrop.
local function LayoutMenu(famIndex, famTag, resolved, cols, bindNow)
  local _, menu = nil, menus[famIndex]
  cols = cols or ((#resolved > 7) and 2 or 1)
  local pad = P.Visual.menuPad
  local rowWidth, rowHeight = P.Visual.rowWidth, P.Visual.rowHeight
  menu._sbVisualTitle:SetText(P.Visual.families[famTag] or famTag)
  menu._sbVisualCount:SetText(tostring(#resolved))
  for i, r in ipairs(resolved) do
    local b = menu.buttons[i]
    if not b then
      b = NewMenuButton(menu, famTag, i)
      menu.buttons[i] = b
    end
    local col = (i - 1) % cols
    local row = math.floor((i - 1) / cols)
    b:SetSize(rowWidth, rowHeight)
    b:ClearAllPoints()
    b:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT",
      pad + col * (rowWidth + GAP), pad + row * (rowHeight + GAP))
    SetMenuButton(b, r, bindNow)
    WireExtraDrag(b, famTag)
  end
  for j = #resolved + 1, #menu.buttons do
    local b = menu.buttons[j]
    P.ClearAction(b)
    b.spellID, b._ability, b._sbBindId, b.commandName, b._sbDefaultKey, b._sbBindKey = nil, nil, nil, nil, nil, nil
    if b.cooldown then pcall(function() b.cooldown:Clear() end) end
    if b.AssistedCombatHighlightFrame then b.AssistedCombatHighlightFrame:Hide() end
    b:Hide()
  end
  if #resolved == 0 then
    menu._sbVisualTitle:Hide()
    menu._sbVisualCount:Hide()
    menu._sbVisualRule:Hide()
    menu:SetSize(1, 1)
    menu._sbW, menu._sbH = 1, 1
    return
  end
  menu._sbVisualTitle:Show()
  menu._sbVisualCount:Show()
  menu._sbVisualRule:Show()
  local rows = math.ceil(#resolved / cols)
  local colsUsed = math.min(#resolved, cols)
  local mw = pad * 2 + colsUsed * rowWidth + (colsUsed - 1) * GAP
  local mh = pad * 2 + rows * rowHeight + (rows - 1) * GAP + P.Visual.menuHeader
  menu:SetSize(mw, mh)
  menu._sbW, menu._sbH = mw, mh
  P.ArmMenuMouse(menu)
end

-- ============================== KEY MAP WINDOW ==============================

local keymapFrame

function P.EnsureKeymapFrame()
  if keymapFrame then return keymapFrame end
  local f = CreateFrame("Frame", "ShamanBindsKeymap", UIParent, "BackdropTemplate")
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetFrameStrata("HIGH")
  P.VisualPanel(f, P.Visual.ink, P.Visual.brass)
  AttachDropShadow(f)
  P.VisualLine(f, P.Visual.teal, 1, -1)
  local brand = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  brand:SetPoint("TOPLEFT", 24, -18)
  brand:SetText("SHAMAN BINDS")
  P.VisualFont(brand, 10, P.Visual.teal)
  f.TitleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.TitleText:SetPoint("TOPLEFT", 23, -35)
  f.TitleText:SetText("Your field guide")
  P.VisualFont(f.TitleText, 24, P.Visual.text)
  local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  subtitle:SetPoint("TOPLEFT", 24, -67)
  subtitle:SetText("Every ability. Every binding.")
  P.VisualFont(subtitle, 11, P.Visual.muted)
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -8, -8)
  close:SetScript("OnClick", function() f:Hide() end)
  f.CloseButton = close
  P.VisualLine(f, P.Visual.edge, 24, -89)
  local scroll = CreateFrame("ScrollFrame", "ShamanBindsKeymapScroll", f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 24, -102)
  scroll:SetPoint("BOTTOMRIGHT", -42, 44)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(746, 1)
  scroll:SetScrollChild(content)
  f.scroll, f.content, f.groups = scroll, content, {}
  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", 24, 18)
  hint:SetText("/shamanbinds bind  to change keys     |     Ctrl-drag to move the console")
  P.VisualFont(hint, 10, P.Visual.muted)
  f.widgets = {}
  tinsert(UISpecialFrames, "ShamanBindsKeymap")
  keymapFrame = f
  return f
end


local function AddWidget(f, w)
  f.widgets[#f.widgets + 1] = w
  return w
end

-- Reads the live console tabs and drawers — not a stale snapshot.
function P.LiveKeymapDisplay()
  local display = {}
  for i, tab in ipairs(consoleTabs) do
    local entries = {}
    local pKey = tab.tipKey or (tab.keyText and tab.keyText:GetText()) or ""
    if pKey == "" or pKey == "+" then pKey = nil end
    -- Click group has no hotkey primary. Listing the tab face again duplicates it.
    if tab.famTag ~= "+" then
      entries[1] = {
        key = pKey,
        label = tab.tipText or tab.famTag or "Primary",
        icon = tab.icon and tab.icon:GetTexture() or 134400,
        note = "primary",
      }
    end
    local menu = menus[i]
    if menu then
      for _, b in ipairs(menu.buttons) do
        if b:IsShown() then
          local a = b._ability
          local k = ShortKey(EffectiveKey(b._sbBindId, b._sbBindKey))
          entries[#entries + 1] = {
            key = k,
            label = (a and (a.label or a.name)) or b.tipText or "?",
            icon = (b.icon and b.icon:GetTexture()) or (a and a.icon) or 134400,
          }
        end
      end
    end
    display[#display + 1] = {
      title = tab.famTitle or tab.famTag or ("Group " .. i),
      col = (i <= 4) and 1 or 2,
      entries = entries,
    }
  end
  return display
end

function P.KeymapGroup(f, index)
  local group = f.groups[index]
  if group then return group end
  group = CreateFrame("Frame", nil, f.content, "BackdropTemplate")
  P.VisualPanel(group, P.Visual.panel, P.Visual.edge)
  group:SetWidth(365)
  group.rows = {}
  local marker = P.VisualTexture(group, "OVERLAY", P.Visual.teal)
  marker:SetPoint("TOPLEFT", 0, 0)
  marker:SetSize(2, 33)
  group.title = group:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  group.title:SetPoint("TOPLEFT", 12, -12)
  group.title:SetWidth(330)
  group.title:SetJustifyH("LEFT")
  P.VisualFont(group.title, 12, P.Visual.text)
  P.VisualLine(group, P.Visual.edge, 12, -33)
  f.groups[index] = group
  return group
end

function P.KeymapRow(group, index)
  local row = group.rows[index]
  if row then return row end
  row = CreateFrame("Frame", nil, group)
  row:SetSize(341, 34)
  local wash = P.VisualTexture(row, "BACKGROUND", {0.11, 0.14, 0.16, index % 2 == 1 and 0.5 or 0})
  wash:SetAllPoints()
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(26, 26)
  row.icon:SetPoint("LEFT", 4, 0)
  row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.label:SetPoint("LEFT", 39, 0)
  row.label:SetWidth(208)
  row.label:SetHeight(30)
  row.label:SetJustifyH("LEFT")
  row.label:SetWordWrap(true)
  P.VisualFont(row.label, 11, P.Visual.text)
  local badge = P.VisualTexture(row, "BACKGROUND", {0.025, 0.037, 0.045, 0.9})
  badge:SetSize(73, 22)
  badge:SetPoint("RIGHT", -4, 0)
  row.key = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.key:SetPoint("CENTER", badge, "CENTER")
  row.key:SetWidth(69)
  P.VisualFont(row.key, 11, P.Visual.teal)
  group.rows[index] = row
  return row
end

function P.PopulateKeymap(display)
  display = display or P.LiveKeymapDisplay()
  local f = P.EnsureKeymapFrame()
  local columnY = {0, 0}
  for index, data in ipairs(display) do
    local group = P.KeymapGroup(f, index)
    local column = columnY[1] <= columnY[2] and 1 or 2
    group:ClearAllPoints()
    group:SetPoint("TOPLEFT", (column - 1) * 381, -columnY[column])
    group.title:SetText(data.title or "Abilities")
    for i, entry in ipairs(data.entries or {}) do
      local row = P.KeymapRow(group, i)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", 12, -40 - (i - 1) * 35)
      row.icon:SetTexture(entry.icon or 134400)
      row.label:SetText(entry.label or "Ability")
      row.key:SetText(entry.key and ShortKey(entry.key) or "CLICK")
      row.key:SetTextColor(unpack(entry.key and P.Visual.teal or P.Visual.muted))
      row:Show()
    end
    for i = #(data.entries or {}) + 1, #group.rows do group.rows[i]:Hide() end
    local height = 48 + #(data.entries or {}) * 35
    group:SetHeight(height)
    group:Show()
    columnY[column] = columnY[column] + height + 12
  end
  for i = #display + 1, #f.groups do f.groups[i]:Hide() end
  local contentHeight = math.max(columnY[1], columnY[2], 1)
  f.content:SetHeight(contentHeight)
  local availableHeight = (UIParent:GetHeight() or 900) * 0.85
  f:SetSize(812, math.min(contentHeight + 150, math.max(320, availableHeight)))
  -- Downscale the reference window on smaller displays, retaining its scroll area.
  f:SetScale(math.min(1, ((UIParent:GetWidth() or 1024) - 40) / 812))
  f.scroll:SetVerticalScroll(0)
end


function P.ShowKeymap()
  if not console then
    print("|cff0070ddShaman Binds:|r run |cffffffff/shamanbinds default|r to build the stock layout first.")
    return
  end
  P.PopulateKeymap(P.LiveKeymapDisplay())
  P.EnsureKeymapFrame():Show()
end

function P.ToggleKeymap()
  local f = P.EnsureKeymapFrame()
  if f:IsShown() then f:Hide() return end
  P.ShowKeymap()
end

-- ============================== BUILD / APPLY ==============================

function P.RotationSet()
  local set = {}
  pcall(function()
    for _, id in pairs(C_AssistedCombat.GetRotationSpells()) do
      set[SpellName(id)] = true
    end
  end)
  return set
end

function P.PrintSBA()
  local names = {}
  for name in pairs(P.RotationSet()) do names[#names + 1] = name end
  if #names == 0 then return end
  table.sort(names)
  print("|cff0070ddSBA on E presses:|r " .. table.concat(names, ", "))
end

function P.HideAutoManaged()
  return not ShamanBindsDB or ShamanBindsDB.hideAutoManaged ~= false
end

function P.IsAutoManagedName(name)
  if type(name) ~= "string" or name == "" then return false end
  if STATIC_EXCLUDE[name] then return true end
  local rot = P._rotationHideSet
  if type(rot) ~= "table" then
    rot = P.RotationSet()
    P._rotationHideSet = rot
  end
  return rot[name] == true
end

function P.IsAutoManagedAbility(r)
  if type(r) ~= "table" then return false end
  if r.bindKey then return false end
  if type(r.note) == "string" and r.note:find("SBA-covered", 1, true) then return true end
  if P.IsAutoManagedName(r.name) or P.IsAutoManagedName(r.label) then return true end
  if type(r.covers) == "table" then
    for _, n in ipairs(r.covers) do if P.IsAutoManagedName(n) then return true end end
  end
  if type(r.spell) == "table" then
    for _, n in ipairs(r.spell) do if P.IsAutoManagedName(n) then return true end end
  end
  return false
end

function P.ParkUnmappedSpell(spell, totems, attack, recover)
  local dest
  if type(spell) == "string" and spell:find("Totem", 1, true) then
    dest = totems
  elseif P.HideAutoManaged() then
    if P.IsAutoManagedName(spell) then return false end
    dest = recover or attack
  else
    dest = attack
  end
  P.FamilySpell(dest, spell, nil, dest == totems and "cursor" or nil, "additional learned ability; hover-bind if needed")
  return true
end

local EXTRA_BAR_FRAMES = {
  "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
  "MultiBar5", "MultiBar6", "MultiBar7", "StanceBar",
}

-- Vehicle / possess / skyriding bars replace ACTIONBUTTON1-12. Our shaman
-- layer is override bindings on top of those commands so we can drop it
-- without losing the hotkeys.
local SPECIAL_BAR_STATE = "[overridebar]1;[vehicleui]1;[possessbar]1;[mounted]1;[bonusbar:5]1;[bonusbar:4]1;[bonusbar:3]1;[bonusbar:2]1;[bonusbar:1]1;0"

function P.FlagFn(fn)
  if type(fn) ~= "function" then return false end
  local ok, value = pcall(fn)
  if not ok or (issecretvalue and issecretvalue(value)) then return false end
  return value and true or false
end

function P.OnSpecialBar()
  local d = P.barDriver
  if d then
    local s = d:GetAttribute("state-special")
    if s == "1" or s == 1 then return true end
  end
  if P.FlagFn(HasOverrideActionBar) or P.FlagFn(HasVehicleActionBar)
    or P.FlagFn(HasTempShapeshiftActionBar) or P.FlagFn(HasBonusActionBar) then
    return true
  end
  if P.FlagFn(function() return UnitHasVehicleUI("player") end) then return true end
  if P.FlagFn(function() return UnitInVehicle and UnitInVehicle("player") end) then return true end
  if C_PlayerInfo and C_PlayerInfo.GetGlidingInfo then
    local ok, isGliding = pcall(C_PlayerInfo.GetGlidingInfo)
    if ok and isGliding == true then return true end
  end
  if P.FlagFn(IsMounted) then return true end
  return false
end

function P.UseMountBar()
  return ShamanBindsDB.useMountBar ~= false and P.OnSpecialBar()
end

function P.SyncMountBarDriver()
  local d = P.barDriver
  if not d then return end
  d:SetAttribute("useMount", (ShamanBindsDB.useMountBar ~= false) and "1" or "0")
end

function P.EnsureBarDriver()
  if P.barDriver then return P.barDriver end
  local d = CreateFrame("Frame", "ShamanBindsBarDriver", UIParent, "SecureHandlerStateTemplate")
  P.barDriver = d
  d:Hide()
  d:SetAttribute("_onstate-special", [[
    self:ClearBindings()
    local yield = self:GetAttribute("useMount") == "1"
    if newstate ~= "1" or not yield then
      local n = self:GetAttribute("n") or 0
      for i = 1, n do
        local key = self:GetAttribute("k"..i)
        local cmd = self:GetAttribute("c"..i)
        if key and cmd then self:SetBinding(true, key, cmd) end
      end
    end
  ]])
  P.SyncMountBarDriver()
  pcall(RegisterStateDriver, d, "special", SPECIAL_BAR_STATE)
  if P.EnsureModDriver then P.EnsureModDriver() end
  d:HookScript("OnAttributeChanged", function(_, attr)
    if attr ~= "state-special" then return end
    C_Timer.After(0, function()
      P.ApplyBar1Chrome()
    end)
  end)
  return d
end

function P.ResetOverrideList()
  P.overrideList = {}
end

function P.QueueOverride(key, command)
  if not P.Text(key) or not P.Text(command) then return end
  P.overrideList = P.overrideList or {}
  P.overrideList[#P.overrideList + 1] = { key, command }
end

function P.RebuildOverrideList()
  P.ResetOverrideList()
  local claimed = {}
  local binds = ShamanBindsDB.binds or {}
  for id, saved in pairs(binds) do
    if type(saved) == "string" and P.IsMouseKey(saved) then
      claimed[saved] = id
    end
  end
  for _, frame in ipairs(P.BindFrames()) do
    local key = EffectiveKey(frame._sbBindId, frame._sbDefaultKey)
    if key and frame.commandName and P.BarSlotOf(frame) and not P.IsMouseKey(key) then
      P.QueueOverride(key, frame.commandName)
    end
    local saved = binds[frame._sbBindId]
    if type(saved) == "string" and P.IsMouseKey(saved)
      and not P.IsAddonCameraKey(saved)
      and not P.IsCameraBinding(saved) then
      local cmd = P.FireableMouseCommand(frame, saved)
      if cmd then
        P.QueueOverride(saved, cmd)
        claimed[saved] = frame._sbBindId
      end
    end
  end
  for key in pairs(MOUSE_HARDWARE) do
    if not claimed[key] and not P.IsCameraBinding(key)
      and not P.IsAddonCameraKey(key) then
      local command = P.MouseKeyCommand(key)
      if command then P.QueueOverride(key, command) end
    end
  end
end

function P.FlushOverrides()
  if Locked() then return end
  local d = P.EnsureBarDriver()
  pcall(ClearOverrideBindings, d)
  if console then pcall(ClearOverrideBindings, console) end
  P.overrideList = P.overrideList or {}
  local n = 0
  for _, pair in ipairs(P.overrideList) do
    n = n + 1
    d:SetAttribute("k" .. n, pair[1])
    d:SetAttribute("c" .. n, pair[2])
  end
  local old = d:GetAttribute("n") or 0
  if type(old) ~= "number" then old = 0 end
  for i = n + 1, old do
    d:SetAttribute("k" .. i, nil)
    d:SetAttribute("c" .. i, nil)
  end
  d:SetAttribute("n", n)
  if P.UseMountBar() then return end
  for _, pair in ipairs(P.overrideList) do
    pcall(SetOverrideBinding, d, true, pair[1], pair[2])
  end
  P.BindThunderstormShiftE()
end

-- Console is ours. Blizzard's mount/vehicle bar can stay. Default: hide the
-- console while mounted; /shamanbinds console toggles it.
function P.ApplyConsoleMountedHide()
  local c = console
  if not c then return end
  if Locked() then
    P.pendingConsoleVis = true
    return
  end
  P.pendingConsoleVis = nil
  if ShamanBindsDB.hideConsoleMounted then
    pcall(RegisterStateDriver, c, "visibility", "[mounted]hide;[vehicleui]hide;[overridebar]hide;show")
  else
    pcall(UnregisterStateDriver, c, "visibility")
    c:Show()
  end
end

-- hideBar1 fades MainActionBar. Extra / zone buttons must stay visible
-- without leaving that tree. SetParent onto UIParent taints
-- UIParent_ManageFramePositions; Character / Progression then receive the
-- click and do nothing. That call is skipped in combat (Locked), which is
-- why the same buttons worked mid-fight. Ignore parent alpha only.
-- Do not touch ExtraAbilityContainer — empty plate, mouse-enabled.
function P.KeepUtilityButtonsVisible()
  if Locked() then return end
  local names = {
    "ExtraActionBarFrame",
    "ZoneAbilityFrame", "ZoneAbilityFrameExtraButton",
    "ExtraActionButton1", "ExtraActionButton2", "ExtraActionButton3",
  }
  for _, name in ipairs(names) do
    local f = _G[name]
    if f then
      pcall(function()
        if f.SetIgnoreParentAlpha then f:SetIgnoreParentAlpha(true) end
        f:SetAlpha(1)
      end)
    end
  end
end

function P.HudAddonLoaded()
  if _G.Bartender4 or _G.Dominos then return true end
  local loaded = C_AddOns and C_AddOns.IsAddOnLoaded
  if loaded and (loaded("Bartender4") or loaded("Dominos")) then return true end
  return false
end

function P.DimActionBar(bar, show)
  if not bar then return end
  pcall(function()
    local a = show and 1 or 0
    bar:SetAlpha(a)
    if bar.EndCaps then bar.EndCaps:SetAlpha(a) end
    if bar.BorderArt then bar.BorderArt:SetAlpha(a) end
    if bar.Background then bar.Background:SetAlpha(a) end
    if bar.ActionBarPageNumber then bar.ActionBarPageNumber:SetAlpha(a) end
  end)
end

function P.ApplyBar1Chrome()
  P.ApplyConsoleMountedHide()
  if P.UseMountBar() then
    P.DimActionBar(_G.MainActionBar, true)
    P.DimActionBar(_G.OverrideActionBar, true)
    P.KeepUtilityButtonsVisible()
    return
  end
  P.DimActionBar(_G.MainActionBar, not ShamanBindsDB.hideBar1)
  P.KeepUtilityButtonsVisible()
  if not P._sbExtrasHidden and not Locked() then
    P.HideAllMultiBars()
    P._sbExtrasHidden = true
  end
end

function P.HideOneExtraBar(f)
  if not f then return end
  pcall(RegisterStateDriver, f, "visibility", "hide")
end

function P.HideAllMultiBars()
  if Locked() then return end
  if P.HudAddonLoaded() then return end
  for _, name in ipairs(EXTRA_BAR_FRAMES) do
    P.HideOneExtraBar(_G[name])
  end
end

-- ACTIONBUTTON* follows the selected page. Our slots 1-7 are absolute IDs
-- on page 1. Up/down paging (or leftover bar-6 helpers) made every key miss.
function P.ForceMainPage()
  if Locked() or P.UseMountBar() then return end
  local ok, page = pcall(GetActionBarPage)
  if ok and P.ID(page) and page ~= 1 and ChangeActionBarPage then
    pcall(ChangeActionBarPage, 1)
  end
end

function P.UnbindPagingKeys()
  if Locked() then return end
  for _, cmd in ipairs({"ActionBarUp", "ActionBarDown"}) do
    for _, key in ipairs({ GetBindingKey(cmd) }) do
      pcall(SetBinding, key)
    end
  end
end

function P.VacateBar6Helpers()
  if Locked() then return end
  for slot = 61, 72 do
    local owned = ShamanBindsDB.hiddenSlots and ShamanBindsDB.hiddenSlots[slot]
    local kind, id = GetActionInfo(slot)
    local macroName = kind == "macro" and GetMacroInfo(id)
    if owned or (type(macroName) == "string" and macroName:sub(1, 3) == "SB_") then
      ClearSlot(slot)
      if ShamanBindsDB.hiddenSlots then ShamanBindsDB.hiddenSlots[slot] = nil end
    end
  end
end

function P.OwnClick(frame)
  return frame and frame.GetName and ("CLICK " .. frame:GetName() .. ":LeftButton") or nil
end

-- Absolute slot clicker. ACTIONBUTTON* follows the selected page; this does not.
-- Mouse-button keys must target this hidden button, not the visible tab.
function P.SlotClickCommand(slot)
  if not P.ID(slot) then return nil end
  local name = "ShamanBindsSlotClick_" .. slot
  local b = _G[name]
  if not b then
    b = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    b:SetSize(1, 1)
    b:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    b:SetAlpha(0)
    b:EnableMouse(false)
    b:RegisterForClicks("AnyDown", "AnyUp")
    b:SetAttribute("pressAndHoldAction", true)
    b:Show()
  end
  if not Locked() then
    b:SetAttribute("type", "action")
    b:SetAttribute("typerelease", "action")
    b:SetAttribute("action", slot)
    P.ArmModifiedCast(b)
  end
  return "CLICK " .. name .. ":LeftButton"
end

-- Mouse buttons do not fire CLICK commands. ACTIONBUTTON1-12 on page 1 do.
function P.HardwareCommand(key, slot, fallback)
  if P.IsMouseKey(key) and P.ID(slot) and slot >= 1 and slot <= 12 then
    return "ACTIONBUTTON" .. slot
  end
  return fallback
end

function P.HotkeyCommand(tab, slot, key)
  return P.HardwareCommand(key, slot, P.OwnClick(tab))
end

-- Mouse buttons ignore CLICK commands. Override spell/macro binds on the
-- console fire them the same way a keyboard key would.
function P.BindMouseOverride(owner, key, frame)
  if Locked() or not owner or not P.IsMouseKey(key) or not frame then return end
  local typ = frame.GetAttribute and frame:GetAttribute("type")
  if typ == "spell" then
    local spell = frame:GetAttribute("spell")
    if spell then pcall(SetOverrideBindingSpell, owner, true, key, spell) end
    return
  end
  if typ == "item" then
    local item = frame:GetAttribute("item")
    if item then pcall(SetOverrideBindingItem, owner, true, key, item) end
    return
  end
  if typ == "macro" then
    local index = frame:GetAttribute("macro")
    local name = index and GetMacroInfo(index)
    local body = frame:GetAttribute("macrotext")
    if not name and body then
      local token = key:gsub("%W", "")
      index = EnsureMacro("OV" .. token, 134400, body)
      name = index and GetMacroInfo(index)
    end
    if name then pcall(SetOverrideBindingMacro, owner, true, key, name) end
    return
  end
  if typ == "action" then
    local slot = frame:GetAttribute("action")
    if P.ID(slot) and slot <= 12 then
      pcall(SetOverrideBinding, owner, true, key, "ACTIONBUTTON" .. slot)
    end
  end
end

function P.ApplyMouseOverrides()
  if Locked() then return end
  local owner = EnsureConsole()
  pcall(ClearOverrideBindings, owner)
  local used = {}
  local function apply(key, frame)
    if not key or used[key] or not P.IsMouseKey(key) then return end
    used[key] = true
    P.BindMouseOverride(owner, key, frame)
  end
  for _, tab in ipairs(consoleTabs) do
    apply(EffectiveKey(tab._sbBindId, tab._sbDefaultKey), tab)
  end
  for _, b in ipairs(allMenuButtons) do
    apply(b._sbBindKey or EffectiveKey(b._sbBindId, b._sbDefaultKey), b)
  end
end

function P.PinHardwareButtons()
  -- Compatibility entry point for existing callers. Slots hold actions without
  -- addon writes to their native button widgets. Main-bar chrome owns visibility.
end

local function SlotLooksEmpty(slot)
  local ok, kind = pcall(GetActionInfo, slot)
  if not ok then return true end
  if issecretvalue and issecretvalue(kind) then return false end
  return not kind
end

function P.BindMouseHardware()
  if Locked() then return end
  P.EnsureBarDriver()
  pcall(SetBinding, "ALT-BUTTON3")
  -- Farseer uses Ctrl-Q for Earthquake. Other layouts leave it empty (no Hex).
  if ShamanBindsDB.familyMode ~= "farseer" then
    pcall(SetBinding, "CTRL-Q")
  end
  -- Old T-family MMB chords and the rejected MWHEEL* names.
  P.RestoreCameraWheel()
  for _, key in ipairs({"CTRL-BUTTON4", "CTRL-BUTTON5"}) do
    if not P.IsCameraBinding(key) then
      local have = GetBindingAction(key)
      if type(have) == "string" and (have:find("SpiritWalk", 1, true) or have:find("ShamanBinds", 1, true)) then
        pcall(SetBinding, key)
      end
    end
  end
  pcall(SetBinding, "BUTTON3")
  pcall(SetBinding, "SHIFT-BUTTON3")
  pcall(SetBinding, "CTRL-BUTTON3")
  if not MOUSE_HARDWARE["SHIFT-BUTTON5"] then pcall(SetBinding, "SHIFT-BUTTON5") end
  pcall(SetBinding, "SHIFT-MWHEELUP")
  pcall(SetBinding, "SHIFT-MWHEELDOWN")
  pcall(SetBinding, "CTRL-MWHEELUP")
  pcall(SetBinding, "CTRL-MWHEELDOWN")
  local claimed = {}
  local binds = ShamanBindsDB.binds or {}
  for id, key in pairs(binds) do
    if type(key) == "string" and P.IsMouseKey(key) then
      claimed[key] = id
    end
  end
  for key, spec in pairs(MOUSE_HARDWARE) do
    if not claimed[key] and not P.IsCameraBinding(key)
      and not P.IsAddonCameraKey(key) then
      pcall(SetBinding, key)
      local cmd = P.MouseKeyCommand(key)
      if not cmd and P.ID(spec.slot) then cmd = "ACTIONBUTTON" .. spec.slot end
      if cmd then pcall(SetBinding, key, cmd) end
    end
  end
  for _, frame in ipairs(P.BindFrames()) do
    local key = binds[frame._sbBindId]
    if type(key) == "string" and claimed[key] == frame._sbBindId
      and not P.IsCameraBinding(key)
      and not P.IsAddonCameraKey(key) then
      local cmd = P.FireableMouseCommand(frame, key)
      if cmd then pcall(SetBinding, key, cmd) end
    end
  end
  P.RebuildOverrideList()
  P.FlushOverrides()
end

function P.ReclaimMouseOverrides()
  if Locked() or not ShamanBindsDB.applied then return end
  P.EnsureBarDriver()
  if P.UseMountBar() then
    pcall(ClearOverrideBindings, P.barDriver)
    if console then pcall(ClearOverrideBindings, console) end
    P.ApplyBar1Chrome()
    return
  end
  P.RebuildOverrideList()
  P.FlushOverrides()
end

function P.PrintMouseDiag()
  print("|cff0070ddShaman Binds mouse:|r", P.OnSpecialBar() and "mount/vehicle bar active" or "shaman layer")
  for _, key in ipairs({"BUTTON3", "SHIFT-BUTTON3", "SHIFT-MOUSEWHEELUP", "SHIFT-MOUSEWHEELDOWN", "CTRL-MOUSEWHEELUP", "CTRL-MOUSEWHEELDOWN", "BUTTON4", "CTRL-BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5"}) do
    local spec = MOUSE_HARDWARE[key]
    local slot = spec and spec.slot
    local bind = GetBindingAction(key)
    local want = P.MouseKeyCommand(key)
    local kind, extra
    if slot then
      local ok, a, b = pcall(GetActionInfo, slot)
      if ok then kind, extra = a, b end
    end
    print((ShortKey(key) or key), "have", (bind and bind ~= "") and bind or "(none)", "want", want or "?", slot and ("slot " .. slot) or "", tostring(kind or ""), tostring(extra or ""))
  end
end

-- Last word on mouse keys. RebindAll must not write CLICK onto BUTTON4/5.
-- Park extras on page-1 slots 8-12. Bind MACRO/SPELL so Bartender4 cannot
-- remap them to CLICK BT4Button:Keybind (mouse buttons ignore that).
function P.ForceMouseHardware()
  if Locked() then return end
  if P.UseMountBar() then
    P.ApplyBar1Chrome()
    P.EnsureBarDriver()
    pcall(ClearOverrideBindings, P.barDriver)
    if console then pcall(ClearOverrideBindings, console) end
    return
  end
  P.ForceMainPage()
  P.VacateBar6Helpers()
  P.PinHardwareButtons()
  do
    local eleName = Known("Earth Elemental") or "Earth Elemental"
    EnsureMacro("EarthEle", 136024, "/cast " .. eleName)
  end
  local mode = ShamanBindsDB.familyMode
  if mode == "prime" or mode == "farseer" then
    PlaceMacro(8, "HealSurge", 136052, SURGE_TEXT, "Healing Surge")
    if mode == "farseer" then
      PlaceMacro(9, "GustWind", 1029585, GUST_TEXT, "Gust of Wind")
    else
      PlaceMacro(9, "FeralLunge", 1027879, LUNGE_TEXT, "Feral Lunge")
    end
    PlaceMacro(10, "ChainHeal", 136042, CHAIN_HEAL_TEXT, "Chain Heal")
    for _, key in ipairs({"2", "SHIFT-2", "CTRL-2", "F", "SHIFT-F", "V", "SHIFT-V", "G", "SHIFT-G", "CTRL-G", "Z"}) do
      pcall(SetBinding, key)
    end
    -- Prime leaves Ctrl-R empty. Farseer keeps it for Stormkeeper.
    if mode == "prime" then pcall(SetBinding, "CTRL-R") end
  else
    pcall(SetBinding, "SHIFT-C", "TOGGLECHARACTER0")
    pcall(SetBinding, "SHIFT-BUTTON5")
    if mode == "pocket" then
      pcall(SetBinding, "V")
      pcall(SetBinding, "SHIFT-V")
    end
    if mode == "families" then
      PlaceMacro(8, "AstralWall", 538565, "#showtooltip Astral Shift\n/cast Astral Shift", "Astral Shift")
    else
      PlaceMacro(8, "FavMount", 132250, MOUNT_TEXT, "Favorite mount")
    end
    PlaceMacro(9, "FleeKit", 136095, SPRINT_BODY, "Ghost Wolf")
    do
      local eleName = Known("Earth Elemental") or "Earth Elemental"
      PlaceMacro(10, "EarthEle", 136024, "/cast " .. eleName, eleName)
    end
  end
  do
    local root = Known("Earthgrab Totem", "Earthbind Totem")
    if root then
      PlaceMacro(12, "RootTotem", 136102, "/cast [@cursor] " .. root, root)
    end
  end
  PlaceMacro(11, "CapTotem", 136013, "/cast [@cursor] Capacitor Totem", "Capacitor Totem")
  EnsureMacro("SpiritWalk", 132328, WALK_TEXT)
  if Known("Thorn Bloom") then
    EnsureMacro("ThornBloom", 7491039, "#showtooltip Thorn Bloom\n/cast [@cursor] Thorn Bloom")
  end
  for i = 8, 12 do
    ClearCommandKeys("ACTIONBUTTON" .. i)
  end
  P.BindMouseHardware()
  P.RestoreChatKeys()
  P.BindThunderstormShiftE()
  pcall(SaveBindings, GetCurrentBindingSet())
  P.PinHardwareButtons()
  P.ArmAllHardwareClicks()
end

function P.ThunderstormName()
  local name = Known("Thunderstorm", "Thunder Storm")
  if name then return name end
  if P.PlayerKnows(51490) then
    return (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(51490)) or "Thunderstorm"
  end
end

-- Last word. CLICK + leftover Shift-E Earthquake binds were winning after apply.
function P.BindThunderstormShiftE()
  if Locked() then return end
  if ShamanBindsDB.familyMode ~= "farseer" then return end
  if ShamanBindsDB.mods then ShamanBindsDB.mods["SHIFT-E"] = nil end
  if ShamanBindsDB.binds then ShamanBindsDB.binds["key:SHIFT-E"] = nil end
  local name = P.ThunderstormName() or "Thunderstorm"
  local cmd = "SPELL " .. name
  -- FlushOverrides also reaches this on UPDATE_BINDINGS. Clearing and
  -- resetting the same key there creates an endless next-frame event loop.
  -- Compare the saved binding, not the temporary mount/console override.
  if GetBindingAction("SHIFT-E") ~= cmd then
    pcall(SetBinding, "SHIFT-E", cmd)
  end
end

local function SetActionBar1Visible(visible)
  ShamanBindsDB.hideBar1 = not visible
  P.ApplyBar1Chrome()
end

local barPin = CreateFrame("Frame")
barPin:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
barPin:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
barPin:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
barPin:RegisterEvent("PLAYER_GAINS_VEHICLE_DATA")
barPin:RegisterEvent("PLAYER_LOSES_VEHICLE_DATA")
barPin:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
pcall(function()
  barPin:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
  barPin:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
end)
barPin:SetScript("OnEvent", function()
  if not ShamanBindsDB.applied then return end
  C_Timer.After(0, function()
    P.EnsureBarDriver()
    P.ApplyBar1Chrome()
    if Locked() then return end
    if P.UseMountBar() then
      pcall(ClearOverrideBindings, P.barDriver)
      if console then pcall(ClearOverrideBindings, console) end
    end
    P.DisableMouseCatch()
  end)
end)

-- Resolve one item spec -> {name,id,icon,macrotext,itemID,label,shortKey,key,note}
local function ResolveItem(item, bindNow)
  ApplyModOverride(item)
  if item.sba then
    return AttachBindMeta({sba=true, name=item.name, label=item.label,
      icon=item.iconFile or SpellIcon(SBA_ID), bindKey=item.bindKey}, item.bindKey)
  end
  if item.itemID then
    PLACED_SPELLS[item.label or ""] = true
    BindKeyTo(item, bindNow)
    return AttachBindMeta({
      itemID = item.itemID, label = item.label,
      icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(item.itemID)) or 134414,
      note = item.note, bindKey = item.bindKey,
    }, item.bindKey)
  end
  if item.covers then
    for _, n in ipairs(item.covers) do PLACED_SPELLS[n] = true end
  end
  if item.macrotext then
    if item.requires and not Known(item.requires) then return nil end
    if not BindKeyTo(item, bindNow) then return nil end
    local iconID = item.iconOf and select(2, Known(item.iconOf))
    return AttachBindMeta({
      macrotext = item.macrotext, label = item.label,
      name = item.name or item.label or item.iconOf or item.requires,
      id = item.id or (item.iconOf and select(2, Known(item.iconOf))) or (item.requires and select(2, Known(item.requires))),
      bindId = item.bindId, equipmentSlot = item.equipmentSlot, tooltipItemID = item.tooltipItemID,
      icon = (iconID and SpellIcon(iconID)) or item.iconFile or 134400,
      note = item.note, bindKey = item.bindKey, covers = item.covers,
      iconOf = item.iconOf, requires = item.requires, savedMacroName = item.savedMacroName,
      defaultKey = item.defaultKey,
    }, item.bindKey or item.defaultKey)
  end
  if item.spell then
    local name, id = Known(unpack(item.spell))
    if not name then
      -- An unavailable spell must not clear a key now owned by another command.
      return nil
    end
    if PLACED_SPELLS[name] and not item.bindKey then return nil end -- dedupe click-only repeats
    PLACED_SPELLS[name] = true
    BindKeyTo(item, bindNow)
    return AttachBindMeta({
      name = name, id = id, label = item.label or name,
      icon = item.iconFile or SpellIcon(id, name),
      note = item.note, bindKey = item.bindKey, spell = item.spell,
    }, item.bindKey)
  end
end

-- Builds console + returns keymap display. bindNow=false on login rebuild
-- (bindings already persist; only attributes/menus need rebuilding).
-- No-bar families (M5, …): the tab IS the first keyed extra. That bindKey
-- must not also appear in the drawer, or the primary icon duplicates.
local function FamilyPrimaryBindKey(fam)
  if not fam or fam.bar then return nil end
  for _, it in ipairs(fam.items or {}) do
    if it.bindKey then return it.bindKey end
  end
end

function P.ConnectCastRoutes()
  -- Clear stale ACTIONBUTTON keys, then RebindAll puts mouse buttons back
  -- on ACTIONBUTTON 1-12 (page-locked) and keyboard keys on CLICK tabs.
  if Locked() then return end
  if P.UseMountBar() then
    P.ApplyBar1Chrome()
    return
  end
  P.ForceMainPage()
  P.UnbindPagingKeys()
  P.VacateBar6Helpers()
  P.HideAllMultiBars()
  P.managedCommands = P.managedCommands or {}
  for _, cmd in pairs(BAR_BINDS) do
    if type(cmd) == "string" and cmd:find("ACTIONBUTTON", 1, true) then
      ClearCommandKeys(cmd)
      P.managedCommands[cmd] = true
    end
  end
  for i = 8, 12 do
    local cmd = "ACTIONBUTTON" .. i
    ClearCommandKeys(cmd)
    P.managedCommands[cmd] = true
  end
end

local function BuildEverything(bindNow)
  if bindNow then SanitizeSavedBinds() else P.EnsureDB() end
  ScanBook()
  wipe(PLACED_SPELLS)
  if bindNow then
    ResetHiddenSlots()
  else
    -- Preserve helper identities across SPELLS_CHANGED. Reallocating against
    -- KEEP can point the rebuilt drawer at a different, unpopulated slot.
    wipe(chordLine)
  end
  if bindNow and P.OnSpecialBar() then
    P.EnsureBarDriver()
    P.ApplyBar1Chrome()
    bindNow = false
  end
  P.trinketRefreshPending = nil
  local trinkets = P.EquippedTrinkets()
  P._rotationHideSet = P.RotationSet()
  local families = BuildFamilies()
  P.AppendTrinketFamilies(families, trinkets)
  local rotation = P._rotationHideSet
  local display = {}

  -- Pass 1: bar-1 placements (only when applying fully).
  if bindNow then
    P.ForceMainPage()
    P.VacateBar6Helpers()
    wipe(KEEP)
    P.extraBarBindings = {}
    ClearSlot(7)
    if ShamanBindsDB.familyMode == "prime" or ShamanBindsDB.familyMode == "farseer" then ClearSlot(2) end
    for _, fam in ipairs(families) do
      for _, barEntry in ipairs({ fam.bar, fam.bar2 }) do
        if barEntry then
          local customP = fam.tag and ShamanBindsDB.custom and ShamanBindsDB.custom[fam.tag] and ShamanBindsDB.custom[fam.tag].primary
          if customP and barEntry == fam.bar and barEntry.slot ~= 5 then
            PlacePrimaryOnBar(barEntry.slot, customP)
            local pn = customP.name or customP.label
            if pn then PLACED_SPELLS[pn] = true end
          elseif barEntry.sba then
            local id = (C_AssistedCombat and C_AssistedCombat.GetActionSpell and C_AssistedCombat.GetActionSpell()) or SBA_ID
            PlaceID(barEntry.slot, id)
          elseif barEntry.macro then
            PlaceMacro(barEntry.slot, barEntry.macro[1], barEntry.macro[2], barEntry.macro[3])
            if barEntry.covers then
              for _, n in ipairs(barEntry.covers) do PLACED_SPELLS[n] = true end
            end
          elseif barEntry.spell then
            local name, id = Known(unpack(barEntry.spell))
            if name then
              PlaceID(barEntry.slot, id)
              PLACED_SPELLS[name] = true
            end
          end
          if barEntry == fam.bar2 and KEEP[barEntry.slot] then
            local bindId = "bar:" .. barEntry.slot
            local helper = EnsureClickButton(bindId)
            if not Locked() then
              P.ClearAction(helper)
              helper:SetAttribute("type", "action")
              helper:SetAttribute("typerelease", "action")
              helper:SetAttribute("action", barEntry.slot)
            end
            local defaultKey
            for key, action in pairs(BAR_BINDS) do
              if action == "ACTIONBUTTON" .. barEntry.slot then defaultKey = key; break end
            end
            P.ArmModifiedCast(helper)
            P.extraBarBindings[#P.extraBarBindings + 1] = {
              _sbBindId = bindId, commandName = ClickCommand(bindId), _sbDefaultKey = defaultKey,
            }
          end
        end
      end
    end
  else
    -- Mark bar spells so drop-downs / autofill don't duplicate them.
    for _, fam in ipairs(families) do
      for _, barEntry in ipairs({ fam.bar, fam.bar2 }) do
        if barEntry then
          if barEntry.covers then
            for _, n in ipairs(barEntry.covers) do PLACED_SPELLS[n] = true end
          end
          if barEntry.spell then
            local name = Known(unpack(barEntry.spell))
            if name then PLACED_SPELLS[name] = true end
          end
        end
      end
    end
  end

  -- SBA already covers these; never put them in a drawer.
  if not P.IsFamilyMode() or P.HideAutoManaged() then
    for nm in pairs(rotation) do PLACED_SPELLS[nm] = true end
    for nm in pairs(STATIC_EXCLUDE) do PLACED_SPELLS[nm] = true end
  end

  -- Explicit additions count toward leftover coverage, without suppressing
  -- stock rows in another family just because a custom family renders first.
  local customCoverage = {}
  for _, custom in pairs(ShamanBindsDB.custom or {}) do
    for _, ability in ipairs(custom.added or {}) do
      if ability.name then customCoverage[ability.name] = true end
    end
  end
  -- Pass 2: menus.
  EnsureConsole()
  for famIndex, fam in ipairs(families) do
    local tab, menu = EnsureTab(famIndex, fam)
    tab.famTitle = fam.title
    WireDropTargets(tab, menu, fam.tag)
    local custom = not fam.equipmentSlot and ShamanBindsDB.custom and ShamanBindsDB.custom[fam.tag]
    local primaryBindKey = FamilyPrimaryBindKey(fam)
    -- Keep the tab face and the primary key on the same ability.
    if custom and custom.primary and primaryBindKey then
      ShamanBindsDB.mods = ShamanBindsDB.mods or {}
      ShamanBindsDB.mods[primaryBindKey] = custom.primary
    end
    local resolved = {}
    for _, item in ipairs(fam.items) do
      local r = ResolveItem(item, bindNow)
      if r and not (P.HideAutoManaged() and P.IsAutoManagedAbility(r)) then
        resolved[#resolved + 1] = r
      end
    end

    -- Leftovers only go in the "+" drawer -- never into E.
    if fam.autoFill == "rest" then
      local names = {}
      for nm in pairs(BOOK) do
        if not PLACED_SPELLS[nm] and not STATIC_EXCLUDE[nm] and not customCoverage[nm] then
          names[#names + 1] = nm
        end
      end
      table.sort(names)
      for _, nm in ipairs(names) do
        PLACED_SPELLS[nm] = true
        resolved[#resolved + 1] = AttachBindMeta({ name = nm, id = BOOK[nm], label = nm, icon = SpellIcon(BOOK[nm]) })
      end
    end

    if custom then
      local visible = {}
      for _, r in ipairs(resolved) do
        if r.bindKey or not custom.hidden[P.AbilityKey(r)] then visible[#visible + 1] = r end
      end
      resolved = visible
      for _, a in ipairs(custom.added) do
        local copy = NormalizeAbility(a)
        -- Explicit user additions may live in more than one family. The global
        -- coverage table is only for auto-fill; DedupResolved handles this drawer.
        if copy then
          resolved[#resolved + 1] = RouteToHiddenSlot(AttachBindMeta(copy), bindNow)
        end
      end
    end



    resolved = DedupResolved(resolved)

    local slotKey = fam.bar and fam.bar.key or primaryBindKey
    local slotFace
    if primaryBindKey then
      for _, r in ipairs(resolved) do
        if r.bindKey == primaryBindKey then slotFace = r break end
      end
    end

    local primary
    if fam.bar then primary = BarPrimary(fam.bar)
    else primary = slotFace or resolved[1] end
    if custom and custom.primary then
      local p = custom.primary
      primary = {
        name = p.name, id = p.id, label = p.label or p.name, icon = p.icon or SpellIcon(p.id),
        itemID = p.itemID, macrotext = p.macrotext, sba = p.sba, key = slotKey,
      }
      -- The primary action was placed during pass 1 (slot 5 is finalized below).
    elseif slotFace then
      primary = slotFace
      primary.key = slotKey
    elseif primary then
      primary.key = slotKey or primary.key
    end
    SetTabFace(tab, primary)
    if fam.tag == "+" and tab.keyText then
      StyleKeyText(tab.keyText)
      tab.keyText:SetText("+")
      tab.tipKey = "+"
    end
    tab._ability = primary
    tab._sbPrimaryKey = primaryBindKey
    if tab._ability and not tab._ability.name then
      tab._ability.name = tab._ability.label
    end
    -- Bar faces: click and hotkey both UseAction on that slot. hide/show
    -- only fades ActionButton 1-7; do not disable their mouse.
    if primary and fam.bar and fam.bar.slot and not Locked() then
      tab:EnableMouse(true)
      if tab.SetMouseClickEnabled then tab:SetMouseClickEnabled(true) end
      tab:SetAttribute("type", "action")
      tab:SetAttribute("typerelease", "action")
      tab:SetAttribute("action", fam.bar.slot)
    end
    if primary and fam.bar and fam.bar.slot then
      local action = "ACTIONBUTTON" .. fam.bar.slot
      local defaultKey = fam.bar.bindKey
      if not defaultKey then
        for key, act in pairs(BAR_BINDS) do
          if act == action then defaultKey = key break end
        end
      end
      local bindId = "bar:" .. fam.bar.slot
      -- Keyboard: CLICK the tab (absolute action). Mouse: ACTIONBUTTON
      -- on this slot — CLICK helpers do not fire for M4/M5.
      WireQuickKeybind(tab, P.HotkeyCommand(tab, fam.bar.slot, defaultKey), bindId, defaultKey)
      local live = EffectiveKey(bindId, defaultKey)
      local label = ShortKey(live) or ""
      if tab.keyText then tab.keyText:SetText(label) end
      tab.tipKey = label
    elseif primary and slotKey then
      -- No-bar keys (M5): click the tab (macro/spell). Hotkey is ACTIONBUTTON
      -- on a hidden page-1 slot — not CLICK, which mouse buttons ignore.
      local bindId = "key:" .. slotKey
      if primary then
        primary.bindKey = primary.bindKey or slotKey
        primary.bindId = bindId
        if P.IsMouseKey(slotKey) then
          RouteToHiddenSlot(primary, bindNow)
          if not primary.blizzardSlot then
            local info = AllocHiddenSlot(bindId)
            local body = primary.macrotext
            if not body and (primary.name or primary.label) then
              body = CastMacro(primary.name or primary.label, "plain")
            end
            if bindNow and body then
              P.PlaceHelper(info, primary.icon or 134400, body, primary.name or primary.label)
            end
            primary.blizzardSlot = info.slot
            primary.commandName = P.HardwareCommand(slotKey, info.slot, info.binding)
          else
            primary.commandName = P.HardwareCommand(slotKey, primary.blizzardSlot, primary.commandName)
          end
        else
          RouteToHiddenSlot(primary, bindNow)
        end
      end
      if primary and primary.blizzardSlot and NeedsBlizzardSlot(primary) and not Locked() then
        tab:EnableMouse(true)
        if tab.SetMouseClickEnabled then tab:SetMouseClickEnabled(true) end
        tab:SetAttribute("type", "action")
        tab:SetAttribute("typerelease", "action")
        tab:SetAttribute("action", primary.blizzardSlot)
        WireQuickKeybind(tab, primary.commandName, bindId, slotKey)
      elseif primary.macroIndex then
        tab:EnableMouse(true)
        if tab.SetMouseClickEnabled then tab:SetMouseClickEnabled(true) end
        tab:SetAttribute("type", "macro")
        tab:SetAttribute("typerelease", "macro")
        tab:SetAttribute("macro", primary.macroIndex)
        WireQuickKeybind(tab, P.HardwareCommand(slotKey, primary.blizzardSlot, primary.commandName), bindId, slotKey)
      else
        if primary then SetupClickButton(bindId, primary) end
        tab:EnableMouse(true)
        if tab.SetMouseClickEnabled then tab:SetMouseClickEnabled(true) end
        WireQuickKeybind(tab, P.HardwareCommand(slotKey, primary.blizzardSlot, ClickCommand(bindId)), bindId, slotKey)
        if not Locked() then
          local helper = EnsureClickButton(bindId)
          if helper then
            helper:EnableMouse(false)
            tab:SetAttribute("type", helper:GetAttribute("type"))
            tab:SetAttribute("typerelease", helper:GetAttribute("typerelease"))
            for _, attr in ipairs({"spell", "item", "macro", "macrotext", "action"}) do
              tab:SetAttribute(attr, helper:GetAttribute(attr))
            end
          end
        end
      end
      local live = EffectiveKey(bindId, slotKey)
      local label = ShortKey(live) or ""
      if tab.keyText then tab.keyText:SetText(label) end
      tab.tipKey = label
    elseif primary then
      local bindId = primary.equipmentSlot and primary.bindId or ("primary:" .. fam.tag)
      primary.bindId = bindId
      RouteToHiddenSlot(primary, bindNow)
      if primary.blizzardSlot then
        tab:SetAttribute("type", "action")
        tab:SetAttribute("typerelease", "action")
        tab:SetAttribute("action", primary.blizzardSlot)
      elseif primary.macroIndex then
        tab:SetAttribute("type", "macro")
        tab:SetAttribute("typerelease", "macro")
        tab:SetAttribute("macro", primary.macroIndex)
      end
      SetupClickButton(bindId, primary)
      tab:EnableMouse(true)
      if tab.SetMouseClickEnabled then tab:SetMouseClickEnabled(true) end
      local defaultKey = primary.defaultKey or P.TrinketDefaultKey(primary.equipmentSlot)
      WireQuickKeybind(tab, primary.commandName or ClickCommand(bindId), bindId, defaultKey)
      tab.tipKey = ShortKey(EffectiveKey(bindId, defaultKey))
      if tab.keyText then tab.keyText:SetText(tab.tipKey or "") end
    else
      if tab.keyText then tab.keyText:SetText("") end
      tab.tipKey = nil
    end
    if P.ApplyIconCooldown then P.ApplyIconCooldown(tab) end

    -- Tab owns the primary key (M5, or the bar face). Never list that slot again.
    local extras = {}
    for _, r in ipairs(resolved) do
      if primaryBindKey and r.bindKey == primaryBindKey then
        -- tab slot
      elseif primary and SameAbility(r, primary) and not r.bindKey then
        -- unkeyed copy of the tab face
      else
        extras[#extras + 1] = r
      end
    end
    extras = ApplyExtraOrder(fam.tag, extras)
    -- Wheel extra keys fire through their own hidden slots. Chord lines must match
    -- the icons we just resolved, not leftover stock macros.
    if fam.tag == "T" then
      for _, r in ipairs(extras) do
        if r.bindKey and MMB_CHORD[r.bindKey] then
          local line = FirstActionLine(r.macrotext)
          if not line and r.name then
            line = (IsGroundName(r.name) and "/cast [@cursor] " or "/cast ") .. r.name
          end
          NoteChordLine(r.bindKey, line)
        end
      end
    end
    LayoutMenu(famIndex, fam.tag, extras, nil, bindNow)

    -- Keymap group.
    local entries = {}
    for _, barEntry in ipairs({ fam.bar, fam.bar2 }) do
      if barEntry then
        local label, icon
        if barEntry.sba then
          label, icon = barEntry.label, SpellIcon(SBA_ID)
        elseif barEntry.macro then
          label, icon = barEntry.label or barEntry.macro[1], barEntry.macro[2]
        elseif barEntry.spell then
          local name, id = Known(unpack(barEntry.spell))
          if name then label, icon = barEntry.label or name, SpellIcon(id) end
        end
        if label then
          entries[#entries + 1] = { key = barEntry.key, label = label, icon = icon, note = barEntry.note }
        end
      end
    end
    for _, r in ipairs(resolved) do
      entries[#entries + 1] = { key = r.key, label = r.label, icon = r.icon, note = r.note }
    end
    if #entries > 0 then
      display[#display + 1] = {
        title = fam.title,
        col = (famIndex <= 4) and 1 or 2,
        entries = entries,
      }
    end
  end

  for i=#families+1,#consoleTabs do
    local tab=consoleTabs[i]
    P.ClearAction(tab)
    tab._ability = nil
    tab._sbBindId,tab.commandName,tab._sbDefaultKey,tab._sbBindKey=nil,nil,nil,nil
    tab:Hide()
    if tab.AssistedCombatHighlightFrame then tab.AssistedCombatHighlightFrame:Hide() end
    if menus[i] then
      for _,button in ipairs(menus[i].buttons or {}) do
        P.ClearAction(button)
        button._sbBindId,button.commandName,button._sbDefaultKey,button._sbBindKey=nil,nil,nil,nil
        if button.AssistedCombatHighlightFrame then button.AssistedCombatHighlightFrame:Hide() end
        button:Hide()
      end
      menus[i]:Hide()
    end
  end
  console:SetWidth(#families * (TAB_W + TAB_GAP) - TAB_GAP + P.CONSOLE_END_PAD)
  console:SetHeight(TAB_H)
  if bindNow then
    ConfigureMMBChord()
    P.ConnectCastRoutes()
    P.RebindAll()
  end
  P.ArmAllHardwareClicks()
  OnQuickKeybindMode(InQuickKeybind())
  P.UpdateMovePads()
  P.RefreshMoveChrome()
  P.EnsureTotemReady(console)
  P.UpdateTotemReady()
  if P.DriveIconCooldowns then P.DriveIconCooldowns() end
  if P.DriveAssistedHighlights then P.DriveAssistedHighlights() end
  return display
end

function P.RebuildConsole()
  P.EnsureDB()
  pcall(BuildEverything, false)
end

local function Apply(showKeymap)
  if Locked() then P.Report("Leave combat before applying a layout."); return false end
  if busy then
    P.Report("Still finishing a layout pass. Wait a second, then /shamanbinds again.")
    return false
  end
  local cursorKind = P.CursorKind()
  if cursorKind and cursorKind ~= "secret" then
    P.Report("Finish the cursor drag before applying.")
    return false
  end
  if select(2, UnitClass("player")) ~= "SHAMAN" then
    print("|cff0070ddShaman Binds:|r not a shaman.")
    return
  end
  if P.OnSpecialBar() then
    P.Report("Dismount or leave the vehicle before applying.")
    return false
  end

  busy = true
  local ok, err = pcall(function()
  P.EnsureDB()
  ScanBook()
  P.ActivatePurposeFamilies()
  SanitizeSavedBinds()
  P.EnsureBarDriver()
  P.ForceMainPage()
  P.UnbindPagingKeys()
  P.ApplyBar1Chrome()
  -- Applying owns this addon's target slots only. Do not wipe other bars,
  -- delete macros by generic name, or clear unrelated user keys.


  local display = BuildEverything(true)

  SaveBindings(GetCurrentBindingSet())



  ShamanBindsDB.display = display
  ShamanBindsDB.applied = true

  P.PrintSBA()
  print("|cff0070ddAeru layout applied.|r |cffffffff/shamanbinds save|r / |cffffffffload|r / |cfffffffflist|r  ·  |cffffffff/shamanbinds default|r opens the key map.")
  if ShamanBindsDB.familyMode == "prime" then
    P.Report("Prime: E SBA  ·  M5 surge  ·  M4 wolf  ·  C Astral Shift  ·  Q shear  ·  R burst  ·  X mount  ·  MMB earth ele.")
    P.Report("Shift-E lightning  ·  Shift-M5 chain heal  ·  Shift-M4 lunge  ·  Shift-C cleanse  ·  Shift-R lust  ·  Shift-MMB Spiritwalker's Grace.")
  elseif ShamanBindsDB.familyMode == "farseer" then
    P.Report("Farseer: E SBA  ·  M5 surge  ·  M4 wolf  ·  C Astral Shift  ·  Q shear  ·  R burst  ·  X mount  ·  MMB earth ele.")
    P.Report("Shift-E Thunderstorm  ·  Ctrl-E chain lightning  ·  Shift-M4 Gust of Wind  ·  Ctrl-Q Earthquake  ·  Shift-C cleanse  ·  Shift-MMB Spiritwalker's Grace  ·  Ctrl-R Stormkeeper.")
  elseif ShamanBindsDB.familyMode == "pocket" then
    P.Report("Pocket: E SBA  ·  M5 mount  ·  M4 wolf  ·  C lightning  ·  Q shear  ·  R burst  ·  X Astral Shift  ·  2 surge  ·  MMB earth ele.")
    P.Report("Shift then Ctrl on the same key. Cleanse is click in Q. Far Sight / Water Walking are in +. V is unbound.")
  elseif ShamanBindsDB.familyMode == "families" then
    P.Report("E attack; Q control; 2 heal; C cleanse; M4 move; M5 defend; MMB earth ele; R personal burst, Ctrl-R group haste.")
    P.Report("Wheel: Shift-Up Wind Rush, Shift-Down Capacitor. Ctrl-Wheel zooms. Earthgrab and Thorn Bloom are click. T/Shift-T/Ctrl-T: stream/tremor/poison. V Far Sight, Shift-V mount, X Water Walking.")
    P.Report("Buffs share one click drawer. Recovery, resurrection and Rootwalking are in +. /keymap shows learned abilities.")
  else
  print("|cff0070ddGround:|r Shift-WheelUp Wind Rush  ·  Shift-WheelDown Capacitor  ·  Earthgrab / Thorn Bloom are click  ·  Ctrl-Wheel zoom")
  print("|cff0070ddMove:|r M4 Ghost Wolf  ·  Shift-M4 flee kit  ·  Spirit Walk is click on Move")
  print("|cff0070ddStay up:|r 2 Surge  ·  Shift-2 Astral Shift  ·  3 Earth Shield  ·  Shift-3 rez  ·  Ctrl-2 Chain Heal  ·  F racial")
  print("|cff0070ddHour:|r R Heroism  ·  V Far Sight  ·  X Water Walking")
  print("|cff999999Click: Recuperate, Skyfury, Lightning Shield, Hearth, Astral Recall. Plain wheel and Ctrl-Wheel are camera zoom.|r")
  end
  if P.PrintBindNotices then P.PrintBindNotices() end
  if ShamanBindsPrompt then ShamanBindsPrompt:Hide() end
  if showKeymap then
    P.PopulateKeymap(P.LiveKeymapDisplay())
    P.EnsureKeymapFrame():Show()
  elseif keymapFrame then
    keymapFrame:Hide()
  end
  ClearDrag()
  end)
  busy = false
  if not ok then P.Report(err) end
  return ok
end

-- ============================== EQUIPPED ON-USE TRINKETS ==============================
-- Runtime rows, not SavedVariables additions. No cooldown reads or native bar
-- placements. The macro follows the equipment slot, never a stale item in bags.
P.trinketRequests = {}

function P.EquipmentRead(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, a, b = pcall(fn, ...)
  if not ok then return nil end
  if issecretvalue and (issecretvalue(a) or issecretvalue(b)) then return nil end
  return a, b
end

function P.EquippedTrinketID(slot)
  return P.ID(P.EquipmentRead(GetInventoryItemID, "player", slot))
end

function P.RequestTrinketData(id)
  if P.trinketRequests[id] or not (C_Item and C_Item.RequestLoadItemDataByID) then return end
  -- Mark before requesting: ITEM_DATA_LOAD_RESULT may be synchronous.
  P.trinketRequests[id] = true
  pcall(C_Item.RequestLoadItemDataByID, id)
end

function P.EquippedTrinkets()
  local rows, active = {}, {}
  for slot = 13, 14 do
    local id = P.EquippedTrinketID(slot)
    if id then
      local cached = P.EquipmentRead(C_Item and C_Item.IsItemDataCachedByID, id)
      local link = P.Text(P.EquipmentRead(GetInventoryItemLink, "player", slot))
      local spell, spellID
      if cached ~= false then
        spell, spellID = P.EquipmentRead((C_Item and C_Item.GetItemSpell) or GetItemSpell, link or id)
      end
      if P.Text(spell) and P.ID(spellID) then
        local label = P.Text(P.EquipmentRead((C_Item and C_Item.GetItemInfo) or GetItemInfo, link or id))
        local icon = P.EquipmentRead(GetInventoryItemTexture, "player", slot)
        if not P.ID(icon) and not P.Text(icon) then icon = 134400 end
        local key = P.TrinketDefaultKey(slot)
        rows[#rows + 1] = {
          bindId = "equipment:" .. slot,
          equipmentSlot = slot, tooltipItemID = id, defaultKey = key,
          label = label or ("Trinket " .. (slot - 12)), icon = icon,
          macrotext = "#showtooltip " .. slot .. "\n/use " .. slot,
          note = "Equipped trinket " .. (slot - 12) .. "; key " .. key .. " follows this slot",
        }
        active[slot] = true
        if not label then P.RequestTrinketData(id) end
      elseif cached ~= true then
        -- A missing spell on an uncached item is unknown, not proof of a passive.
        P.RequestTrinketData(id)
      end
    end
  end
  -- Keep a user-assigned hover binding's identity but disarm an empty/passive slot.
  for slot = 13, 14 do
    if not active[slot] then P.ClearAction(clickButtons["equipment:" .. slot]) end
  end
  return rows
end

function P.AppendTrinketFamilies(families, trinkets)
  for _, item in ipairs(trinkets) do
    local number = item.equipmentSlot - 12
    local tag = "EQUIP" .. item.equipmentSlot
    P.Visual.families[tag] = "TRINKET " .. number
    item.iconFile = item.icon
    families[#families + 1] = {
      tag = tag, title = "Trinket · " .. (item.defaultKey or number),
      equipmentSlot = item.equipmentSlot,
      items = {item},
    }
  end
end

function P.QueueTrinketRefresh()
  if not ShamanBindsDB.applied then return end
  P.trinketRefreshPending = true
  if P.trinketRefreshQueued then return end
  P.trinketRefreshQueued = true
  C_Timer.After(0, function()
    P.trinketRefreshQueued = nil
    if not P.trinketRefreshPending then return end
    if Locked() then P.pendingRefresh = true; return end
    -- Internal drags have no native cursor. Defer those too so their rows stay put.
    if busy or drag.active or P.dropRefreshQueued then return end
    local kind = P.CursorKind()
    if kind and kind ~= "secret" then return end
    P.trinketRefreshPending = nil
    RefreshLayout(true)
  end)
end

do
  local watcher = CreateFrame("Frame")
  watcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  watcher:RegisterEvent("ITEM_DATA_LOAD_RESULT")
  watcher:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
  watcher:RegisterEvent("CURSOR_CHANGED")
  watcher:SetScript("OnEvent", function(_, event, arg, success)
    if event == "PLAYER_EQUIPMENT_CHANGED" then
      if issecretvalue and issecretvalue(arg) then return end
      if arg ~= 13 and arg ~= 14 then return end
      local id = P.EquippedTrinketID(arg)
      if id then P.trinketRequests[id] = nil end
      P.QueueTrinketRefresh()
    elseif event == "ITEM_DATA_LOAD_RESULT" or event == "GET_ITEM_INFO_RECEIVED" then
      if issecretvalue and (issecretvalue(arg) or issecretvalue(success)) then return end
      if not P.ID(arg) or success ~= true then return end
      if arg == P.EquippedTrinketID(13) or arg == P.EquippedTrinketID(14) then P.QueueTrinketRefresh() end
    elseif P.trinketRefreshPending then
      P.QueueTrinketRefresh()
    end
  end)
end

-- ============================== BOOTSTRAP ==============================

do
local prompt
local function ReleasePromptKeys()
  if not prompt then return end
  prompt:EnableKeyboard(false)
  if prompt.ClearFocus then prompt:ClearFocus() end
  if prompt.SetPropagateKeyboardInput then prompt:SetPropagateKeyboardInput(true) end
end

function P.ShowPrompt()
  local function go()
    ReleasePromptKeys()
    if prompt then prompt:Hide() end
    Apply()
  end
  if prompt then
    ReleasePromptKeys()
    prompt:Show()
    return
  end
  prompt = CreateFrame("Button", "ShamanBindsPrompt", UIParent, "UIPanelButtonTemplate")
  prompt:SetSize(340, 36)
  prompt:SetPoint("CENTER", 0, 220)
  prompt:SetText("Apply Prime layout  (/shamanbinds)")
  prompt:SetFrameStrata("DIALOG")
  prompt:EnableKeyboard(false)
  prompt:SetScript("OnClick", go)
  prompt:SetScript("OnHide", ReleasePromptKeys)
  prompt:Show()
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:RegisterEvent("PLAYER_REGEN_DISABLED")
boot:RegisterEvent("PLAYER_REGEN_ENABLED")
boot:RegisterEvent("SPELLS_CHANGED")
boot:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
boot:SetScript("OnEvent", function(self, event)
  if select(2, UnitClass("player")) ~= "SHAMAN" then return end
  if event == "PLAYER_REGEN_DISABLED" then
    P.regenCombat = true
    P.pendingDragCleanup = drag.active or P.pendingDragCleanup
    P.pendingQKB = true
    return
  end
  if event == "PLAYER_REGEN_ENABLED" then
    P.regenCombat = false
    if P.pendingDragCleanup then ClearDrag(); HoldMenus(false); P.pendingDragCleanup = nil end
    if P.pendingQKB then OnQuickKeybindMode(InQuickKeybind()); P.pendingQKB = nil end
    if P.pendingConsoleVis then P.ApplyConsoleMountedHide() end
    if P.pendingRefresh then RefreshLayout(true) end
    P.RestoreChatKeys()
    return
  end
  if event ~= "PLAYER_ENTERING_WORLD" and event ~= "SPELLS_CHANGED"
    and event ~= "PLAYER_SPECIALIZATION_CHANGED" then return end
  P.SelectClassTheme()
  if busy or P.bootQueued then return end
  P.bootQueued = true
  C_Timer.After(event == "PLAYER_ENTERING_WORLD" and 1.5 or 0, function()
    P.bootQueued = nil
    P.EnsureDB()
    P.RegisterSettings()
    P.RestoreChatKeys()
    if ShamanBindsDB.applied then
      RefreshLayout(event ~= "PLAYER_SPECIALIZATION_CHANGED")
    elseif not Locked() then P.ShowPrompt() end
  end)
end)
-- Retry a combat-deferred rebuild after an external cursor drag is completed.
boot:RegisterEvent("CURSOR_CHANGED")
boot:HookScript("OnEvent", function(_, event)
  if event == "CURSOR_CHANGED" and P.pendingRefresh and not Locked() and not P.CursorKind() then
    C_Timer.After(0, function() if P.pendingRefresh then RefreshLayout(true) end end)
  end
end)
end

function RefreshLayout(automatic)
  if Locked() or busy or drag.active or P.dropRefreshQueued then
    P.pendingRefresh = true
    return false
  end
  local kind = P.CursorKind()
  if kind and kind ~= "secret" then
    P.pendingRefresh = true
    return false
  end
  P.pendingRefresh = false
  busy = true
  local ok, err = pcall(function()
    -- automatic (login / SPELLS_CHANGED): rebuild the console only.
    -- Pickup/Place on the bar puts the icon on the cursor and taints
    -- ActionButton cooldown updates.
    ShamanBindsDB.display = BuildEverything(automatic ~= true)
    P.EnsureBarDriver()
    P.ApplyBar1Chrome()
    P.RebuildOverrideList()
    P.FlushOverrides()
    P.RestoreChatKeys()
  end)
  busy = false
  if not ok then P.Report("Layout update failed: " .. tostring(err)) end
  return ok
end

function P.CopyData(value, seen)
  if type(value) ~= "table" then return value end
  seen = seen or {}
  if seen[value] then return seen[value] end
  local copy = {}
  seen[value] = copy
  for k, v in pairs(value) do copy[P.CopyData(k, seen)] = P.CopyData(v, seen) end
  return copy
end

function P.RestoreTotemPlaces()
  local rack = P.totemReadyRack
  if not rack then return end
  for _, f in ipairs(rack.icons or {}) do
    f._sbLaidOut = nil
    P.ApplyTotemPlace(f)
    f._sbLaidOut = true
  end
end

function P.RestorePositions()
  local pos = ShamanBindsDB.pos
  if pos and console and pos.console then
    local p = pos.console
    console:ClearAllPoints()
    console:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  end
  P.RestoreTotemPlaces()
  if P.PlaceBindButton then P.PlaceBindButton() end
end

function P.SnapshotCurrent()
  if console then SavePosition("console", console) end
  return {
    familyMode = ShamanBindsDB.familyMode or "legacy",
    custom = P.CopyData(ShamanBindsDB.custom or {}),
    pos = P.CopyData(ShamanBindsDB.pos or {}),
    totemPos = P.CopyData(ShamanBindsDB.totemPos or {}),
    binds = P.CopyData(ShamanBindsDB.binds or {}),
    barBinds = P.CopyData(ShamanBindsDB.barBinds or {}),
    mods = P.CopyData(ShamanBindsDB.mods or {}),
  }
end

function P.ProfileNames()
  local names = {}
  for name in pairs(ShamanBindsDB.profiles or {}) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

function P.SaveProfile(name)
  P.EnsureDB()
  name = strtrim(type(name) == "string" and name or "")
  if name == "" then
    name = ShamanBindsDB.activeProfile or "Aeru"
  end
  ShamanBindsDB.profiles = ShamanBindsDB.profiles or {}
  ShamanBindsDB.profiles[name] = P.SnapshotCurrent()
  ShamanBindsDB.activeProfile = name
  print("|cff0070ddShaman Binds:|r saved profile |cffffffff" .. name .. "|r")
end

function P.LoadProfile(name)
  local cursorKind = P.CursorKind()
  if Locked() or busy or drag.active or P.dropRefreshQueued
    or (cursorKind and cursorKind ~= "secret") then
    P.Report("Finish combat or dragging before loading a profile."); return false
  end
  -- Apply rejects special bars. Reject here before clearing keys or changing DB.
  if P.OnSpecialBar() then
    P.Report("Dismount or leave the vehicle before loading a profile."); return false
  end
  P.EnsureDB()
  name = strtrim(type(name) == "string" and name or "")
  if name == "" then
    print("|cff0070ddShaman Binds:|r usage: |cffffffff/shamanbinds load <name>|r")
    return
  end
  local profile = ShamanBindsDB.profiles and ShamanBindsDB.profiles[name]
  if not profile then
    for n, p in pairs(ShamanBindsDB.profiles or {}) do
      if strlower(n) == strlower(name) then profile, name = p, n break end
    end
  end
  if not profile then
    print("|cff0070ddShaman Binds:|r no profile named |cffffffff" .. name .. "|r. |cffffffff/shamanbinds list|r")
    return
  end
  P.ClearFamilyKeys()
  local mode = profile.familyMode
  if mode ~= "families" and mode ~= "pocket" and mode ~= "prime" and mode ~= "farseer" then mode = "legacy" end
  if (name == "Pocket" or name == "Prime" or name == "Farseer") and ShamanBindsDB.familyMode ~= mode then
    local base = (name == "Prime") and "Before prime layout" or (name == "Farseer") and "Before farseer layout" or "Before pocket layout"
    local backup = base
    local suffix = 1
    while ShamanBindsDB.profiles[backup] do
      suffix = suffix + 1
      backup = base .. " " .. suffix
    end
    ShamanBindsDB.profiles[backup] = P.SnapshotCurrent()
    P.Report("Current setup saved as '" .. backup .. "'.")
  end
  ShamanBindsDB.familyMode = mode
  ShamanBindsDB.familyRevision = 1
  P.SelectFamilyHardware()
  ShamanBindsDB.custom = P.CopyData(profile.custom or {})
  if type(profile.pos) == "table" and next(profile.pos) then
    ShamanBindsDB.pos = P.CopyData(profile.pos)
  end
  if type(profile.totemPos) == "table" then
    ShamanBindsDB.totemPos = P.CopyData(profile.totemPos)
  end
  ShamanBindsDB.binds = P.CopyData(profile.binds or {})
  ShamanBindsDB.barBinds = P.CopyData(profile.barBinds or {})
  ShamanBindsDB.mods = P.CopyData(profile.mods or {})
  ShamanBindsDB.activeProfile = name
  P.EnsureDB()
  if not Apply() then return false end
  P.RestorePositions()
  P.RefreshMoveChrome()
  print("|cff0070ddShaman Binds:|r loaded profile |cffffffff" .. name .. "|r")
end

function P.DeleteProfile(name)
  name = strtrim(type(name) == "string" and name or "")
  if name == "" or not (ShamanBindsDB.profiles and ShamanBindsDB.profiles[name]) then
    print("|cff0070ddShaman Binds:|r no profile named |cffffffff" .. (name ~= "" and name or "?") .. "|r")
    return
  end
  ShamanBindsDB.profiles[name] = nil
  if ShamanBindsDB.activeProfile == name then ShamanBindsDB.activeProfile = nil end
  print("|cff0070ddShaman Binds:|r deleted profile |cffffffff" .. name .. "|r")
end

function P.ListProfiles()
  local names = P.ProfileNames()
  if #names == 0 then
    print("|cff0070ddShaman Binds:|r no saved profiles. |cffffffff/shamanbinds save <name>|r")
    return
  end
  local active = ShamanBindsDB.activeProfile
  print("|cff0070ddShaman Binds profiles:|r")
  for _, name in ipairs(names) do
    local mark = (name == active) and " |cffaaaaaa(active)|r" or ""
    if name == "Pocket" then mark = mark .. " |cff999999(WASD Pocket)|r" end
    if name == "Prime" then mark = mark .. " |cff999999(default Prime)|r" end
    if name == "Farseer" then mark = mark .. " |cff999999(Elemental Farseer)|r" end
    print("  |cffffffff" .. name .. "|r" .. mark)
  end
end

function P.ApplyMountBarSetting()
  P.EnsureBarDriver()
  P.SyncMountBarDriver()
  P.ApplyBar1Chrome()
  if Locked() then return end
  if P.UseMountBar() then
    pcall(ClearOverrideBindings, P.barDriver)
    if console then pcall(ClearOverrideBindings, console) end
  else
    P.RebuildOverrideList()
    P.FlushOverrides()
  end
end

function P.OpenSettings()
  P.RegisterSettings()
  local cat = P.settingsCategory
  if not cat or type(Settings) ~= "table" or type(Settings.OpenToCategory) ~= "function" then
    P.Report("Settings panel is not available on this client.")
    return
  end
  local id = cat.GetID and cat:GetID() or cat.ID
  if id then Settings.OpenToCategory(id) end
end

function P.RegisterSettings()
  if P.settingsCategory then return end
  if type(Settings) ~= "table" then return end
  if type(Settings.RegisterVerticalLayoutCategory) ~= "function" then return end
  if type(Settings.RegisterProxySetting) ~= "function" then return end
  P.EnsureDB()
  local category, layout = Settings.RegisterVerticalLayoutCategory("Shaman Binds")
  P.settingsCategory = category
  local boolType = (Settings.VarType and Settings.VarType.Boolean) or type(false)
  local defTrue = (Settings.Default and Settings.Default.True)
  if defTrue == nil then defTrue = true end
  local defFalse = (Settings.Default and Settings.Default.False)
  if defFalse == nil then defFalse = false end

  local function addBool(key, name, default, tooltip, apply)
    local setting = Settings.RegisterProxySetting(
      category,
      "SHAMANBINDS_" .. key,
      boolType,
      name,
      default,
      function() return ShamanBindsDB[key] and true or false end,
      function(value)
        ShamanBindsDB[key] = value and true or false
        if apply then apply(value) end
      end
    )
    Settings.CreateCheckbox(category, setting, tooltip)
  end

  if type(CreateSettingsListSectionHeaderInitializer) == "function" and layout then
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Bars"))
  end
  addBool("hideBar1", "Hide Blizzard action bar 1", defFalse,
    "Fade the stock main action bar. The shaman console stays. Mount/vehicle bars can still appear if that option is on.",
    function() P.ApplyBar1Chrome() end)
  addBool("hideConsoleMounted", "Hide shaman bar while mounted", defTrue,
    "Hide the shaman console on a mount or in a vehicle. The Blizzard mount bar can still show.",
    function() P.ApplyConsoleMountedHide() end)

  if type(CreateSettingsListSectionHeaderInitializer) == "function" and layout then
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Console"))
  end
  addBool("hideAutoManaged", "Hide auto-managed abilities", defTrue,
    "Hide click buttons that Assisted Combat already presses. Bound keys stay visible. Turn off to show leftover clicks.",
    function() P.RebuildConsole() end)

  if type(CreateSettingsListSectionHeaderInitializer) == "function" and layout then
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Mounting"))
  end
  addBool("useMountBar", "Use Blizzard mount / vehicle bar", defTrue,
    "When you mount or enter a vehicle, show the Blizzard bar and give it your hotkeys. Turn off to keep shaman keys.",
    function() P.ApplyMountBarSetting() end)

  if type(CreateSettingsListSectionHeaderInitializer) == "function" and layout then
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Keys"))
  end
  addBool("warnBinds", "Warn about camera and totem key conflicts", defTrue,
    "Chat reminders when BIND takes a totem wheel chord or camera zoom, and when Ctrl-Wheel / Ctrl-M4 / Ctrl-M5 are not zoom. /shamanbinds keys prints the full guide.",
    nil)

  if type(CreateSettingsButtonInitializer) == "function" and layout then
    if type(CreateSettingsListSectionHeaderInitializer) == "function" then
      layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Layout"))
    end
    layout:AddInitializer(CreateSettingsButtonInitializer(
      "Apply layout", "Apply",
      function() if Apply then Apply() end end,
      "Place the current shaman layout and keybinds.", true))
    layout:AddInitializer(CreateSettingsButtonInitializer(
      "Key map", "Open",
      function() if P.ShowKeymap then P.ShowKeymap() end end,
      "Show the live key map window.", true))
    layout:AddInitializer(CreateSettingsButtonInitializer(
      "Hover-bind", "Start / Stop",
      function() if P.ToggleQuickKeybind then P.ToggleQuickKeybind() end end,
      "Hover a console icon and press a key or scroll. Ctrl-Wheel and Ctrl-M4 / Ctrl-M5 stay camera zoom. Click again or press Escape to finish.", true))
  end

  Settings.RegisterAddOnCategory(category)
end

function ShamanBinds_OnCompartmentClick()
  P.OpenSettings()
end

-- Level 80 Stormbringer leveling path (Icy Veins 12.1). Website import
-- strings are 90-point / stale and fail in-game before Apex unlocks.
-- Spend by matching live tree names so it still works when node IDs move.
-- Built inside a function so the file chunk stays under Lua's register cap.
function P.EnsureTalent80Names()
  if P.TALENT80_NAMES then return P.TALENT80_NAMES end
  P.TALENT80_NAMES = {
    "ascendance", "ascendingair", "arcdischarge", "ashencatalyst", "astralshift",
    "awakeningstorms", "brimmingwithlife", "capacitor totem", "capacitortotem",
    "chainheal", "chainingstorms", "chainlightning", "conductiveenergy",
    "convergingstorms", "crashlightning", "descending skies", "descendingskies",
    "doomwinds", "earthelemental", "earthgrabtotem", "earthshield",
    "elementalassault", "elementalorbit", "elementaltempo", "elementalwarding",
    "elementalweapons", "enhancedimbues", "feralspirit", "fireandice", "firenova",
    "flametongueweapon", "flurry", "forcefulwinds", "instinctiveimbuements",
    "lavalash", "lightningstrikes", "maelstromweapon", "moltenassault",
    "naturalgift", "naturesfury", "naturesguardian", "overflowingmaelstrom",
    "planestraveler", "purge", "ragingmaelstrom", "refreshingwaters",
    "ridethelightning", "spiritwalk", "spiritwolf", "spiritualawakening",
    "staticaccumulation", "stormblast", "stormbringer", "stormcaller",
    "stormflurry", "stormswrath", "stormwell", "supercharge", "tempest",
    "therazanesresilience", "thorimsinvocation", "thundercapacitor",
    "totemicfocus", "unlimitedpower", "unrulywinds", "voltaicblaze",
    "voltaicsurge", "windfuryweapon", "windrush totem", "windrushtotem",
    "winds of alakir", "windsofalakir", "windshear", "windveil",
  }
  return P.TALENT80_NAMES
end

function P.TalentKey(name)
  name = P.Text(name)
  return name and name:lower():gsub("[^%w]+", "") or nil
end

function P.WantedTalent(name)
  local key = P.TalentKey(name)
  if not key then return false end
  if not P.TALENT80_SET then
    P.TALENT80_SET = {}
    for _, label in ipairs(P.EnsureTalent80Names()) do
      P.TALENT80_SET[P.TalentKey(label)] = true
    end
  end
  return P.TALENT80_SET[key] and true or false
end

function P.EntryTalentName(configID, entryID)
  if not entryID then return nil end
  local ok, entry = pcall(C_Traits.GetEntryInfo, configID, entryID)
  if not ok or type(entry) ~= "table" then return nil end
  if entry.subTreeID and C_Traits.GetSubTreeInfo then
    local okSub, sub = pcall(C_Traits.GetSubTreeInfo, configID, entry.subTreeID)
    if okSub and type(sub) == "table" and P.Text(sub.name) then return sub.name end
  end
  if entry.definitionID then
    local okDef, def = pcall(C_Traits.GetDefinitionInfo, entry.definitionID)
    if okDef and type(def) == "table" then
      if P.Text(def.overrideName) then return def.overrideName end
      local spellID = P.ID(def.spellID)
      if spellID then
        if C_Spell and C_Spell.GetSpellName then
          local n = C_Spell.GetSpellName(spellID)
          if P.Text(n) then return n end
        end
        if GetSpellInfo then
          local n = GetSpellInfo(spellID)
          if P.Text(n) then return n end
        end
      end
    end
  end
  return nil
end

function P.WantedEntry(configID, node)
  local pick, pickName
  for _, entryID in ipairs(node.entryIDs or {}) do
    local name = P.EntryTalentName(configID, entryID)
    if P.WantedTalent(name) then
      pick, pickName = entryID, name
      break
    end
  end
  return pick, pickName
end

function P.ApplyLevel80Talents()
  if Locked() then
    P.Report("Leave combat first.")
    return
  end
  if select(2, UnitClass("player")) ~= "SHAMAN" then
    P.Report("This command is shaman-only.")
    return
  end
  local specID = PlayerUtil and PlayerUtil.GetCurrentSpecID and PlayerUtil.GetCurrentSpecID()
  if specID and specID ~= 263 then
    P.Report("Switch to Enhancement first.")
    return
  end
  if not C_ClassTalents or not C_Traits then
    P.Report("Talent API missing.")
    return
  end
  if C_ClassTalents.GetStarterBuildActive and C_ClassTalents.GetStarterBuildActive() then
    pcall(C_ClassTalents.SetStarterBuildActive, false)
  end
  local configID = C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
  if not configID then
    P.Report("No active talent loadout. Open Talents and create one, then try again.")
    return
  end
  local okInfo, info = pcall(C_Traits.GetConfigInfo, configID)
  if not okInfo or type(info) ~= "table" then
    P.Report("Could not read the talent tree.")
    return
  end
  local treeIDs = info.treeIDs
  if type(treeIDs) ~= "table" or not treeIDs[1] then
    P.Report("Could not find the talent tree id.")
    return
  end
  for _, treeID in ipairs(treeIDs) do
    pcall(C_Traits.ResetTree, configID, treeID)
  end
  local bought, passes = 0, 0
  while passes < 48 do
    passes = passes + 1
    local progress = 0
    for _, treeID in ipairs(treeIDs) do
      local okNodes, nodes = pcall(C_Traits.GetTreeNodes, treeID)
      if okNodes and type(nodes) == "table" then
        for _, nodeID in ipairs(nodes) do
          local okNode, node = pcall(C_Traits.GetNodeInfo, configID, nodeID)
          if okNode and type(node) == "table" and node.isVisible ~= false then
            local entryID = P.WantedEntry(configID, node)
            if entryID then
              local choice = node.entryIDs and #node.entryIDs > 1
              if choice then
                local active = node.activeEntry and node.activeEntry.entryID
                if active ~= entryID then
                  pcall(C_Traits.SetSelection, configID, nodeID, entryID)
                  local okAfter, after = pcall(C_Traits.GetNodeInfo, configID, nodeID)
                  local now = okAfter and after and after.activeEntry and after.activeEntry.entryID
                  if now == entryID then progress = progress + 1; bought = bought + 1 end
                end
              else
                local have = tonumber(node.ranksPurchased) or 0
                local maxRanks = tonumber(node.maxRanks) or 1
                if have < maxRanks then
                  pcall(C_Traits.PurchaseRank, configID, nodeID)
                  local okAfter, after = pcall(C_Traits.GetNodeInfo, configID, nodeID)
                  local now = okAfter and after and tonumber(after.ranksPurchased) or have
                  if now > have then progress = progress + 1; bought = bought + 1 end
                end
              end
            end
          end
        end
      end
    end
    if progress == 0 then break end
  end
  if C_ClassTalents.CommitConfig then
    pcall(C_ClassTalents.CommitConfig, configID)
  elseif C_Traits.CommitConfig then
    pcall(C_Traits.CommitConfig, configID)
  end
  print("|cff0070ddShaman Binds:|r spent the level-80 Stormbringer path (" .. tostring(bought) .. " purchases). Check Talents, then click Apply if Blizzard asks.")
end

function P.SlashHelp()
  print("|cff0070ddShaman Binds commands:|r")
  print("  |cffffffff/shamanbinds|r  apply current layout and show the key map")
  print("  |cffffffff/shamanbinds default|r  restore Prime (heal on M5, protect on C, mount on X)")
  print("  |cffffffff/shamanbinds families|r  back up current setup and apply purpose-based defaults")
  print("  |cffffffff/shamanbinds map|r  show the live key map")
  print("  |cffffffff/shamanbinds bind|r  Quick Keybind (click BIND on the console). Same command or Esc exits.")
  print("  |cffffffff/shamanbinds keys|r  reserved chords, totem wheel, and BIND warnings")
  print("  |cffffffff/shamanbinds save [name]|r  save custom bar + position")
  print("  |cffffffff/shamanbinds load Pocket|r  WASD-pocket faces (mount on M5, shift on X)")
  print("  |cffffffff/shamanbinds load Prime|r  Prime (already the default)")
  print("  |cffffffff/shamanbinds load Farseer|r  Elemental Farseer on Prime faces")
  print("  |cffffffff/shamanbinds load <name>|r  load a profile")
  print("  |cffffffff/shamanbinds list|r  show profiles")
  print("  |cffffffff/shamanbinds delete <name>|r  remove a profile")
  print("  |cffffffff/shamanbinds hide|r  hide action bar 1")
  print("  |cffffffff/shamanbinds show|r  show action bar 1")
  print("  |cffffffff/shamanbinds console|r  toggle hiding the shaman bar while mounted")
  print("  |cffffffff/shamanbinds options|r  open the addon settings page")
  print("  |cffffffff/shamanbinds mouse|r  print M4/M5 bind + slot info")
  print("  |cffffffff/shamanbinds talents|r  spend the level-80 Stormbringer leveling build")
  print("  |cffffffff/shamanbinds chat|r  restore Enter and / to open chat")
end

function P.SlashBinds(msg)
  P.EnsureDB()
  msg = strtrim(type(msg) == "string" and msg or "")
  local cmd, rest = msg:match("^(%S+)%s*(.*)$")
  cmd = strlower(cmd or "")
  rest = strtrim(rest or "")
  if cmd == "" then
    Apply(true)
    return
  end
  if cmd == "default" or cmd == "defaults" or cmd == "reset" then
    if Locked() or busy or GetCursorInfo() then P.Report("Finish combat or dragging before resetting."); return end
    P.ClearFamilyKeys()
    ShamanBindsDB.familyMode, ShamanBindsDB.familyRevision = "prime", 1
    ShamanBindsDB.custom = {}
    ShamanBindsDB.binds = {}
    ShamanBindsDB.barBinds = {}
    ShamanBindsDB.mods = {}
    ShamanBindsDB.activeProfile = "Prime"
    print("|cff0070ddShaman Binds:|r loaded Prime (default).")
    Apply(true)
    return
  end
  if cmd == "families" then
    if Locked() or busy or P.OnSpecialBar() then P.Report("Leave combat and dismount first."); return end
    local kind=P.CursorKind()
    if kind and kind~="secret" then P.Report("Finish the cursor drag first."); return end
    ScanBook()
    P.ActivatePurposeFamilies(true)
    Apply(true)
    return
  end
  if cmd == "save" then
    P.SaveProfile(rest)
    return
  end
  if cmd == "load" then
    P.LoadProfile(rest)
    return
  end
  if cmd == "list" or cmd == "profiles" then
    P.ListProfiles()
    return
  end
  if cmd == "delete" or cmd == "del" or cmd == "remove" then
    P.DeleteProfile(rest)
    return
  end
  if cmd == "map" or cmd == "keymap" then
    P.ShowKeymap()
    return
  end
  if cmd == "bind" or cmd == "binds" or cmd == "keybind" then
    local sub = (rest or ""):lower():match("^%s*(%S*)")
    if sub == "off" or sub == "done" or sub == "exit" or sub == "stop" then
      P.CloseQuickKeybind()
      return
    end
    P.ToggleQuickKeybind()
    return
  end
  if cmd == "keys" or cmd == "key" or cmd == "reserved" then
    P.PrintKeyGuide()
    return
  end
  if cmd == "help" or cmd == "?" then
    P.SlashHelp()
    return
  end
  if cmd == "options" or cmd == "settings" or cmd == "config" then
    P.OpenSettings()
    return
  end
  if cmd == "hide" then
    SetActionBar1Visible(false)
    print("|cff0070ddShaman Binds:|r Blizzard action bars hidden. Console stays. |cffffffff/shamanbinds show|r shows bar 1.")
    return
  end
  if cmd == "show" then
    SetActionBar1Visible(true)
    print("|cff0070ddShaman Binds:|r Blizzard action bar 1 shown. Console stays — both are visible.")
    return
  end
  if cmd == "console" or cmd == "mounted" then
    ShamanBindsDB.hideConsoleMounted = not ShamanBindsDB.hideConsoleMounted
    P.ApplyConsoleMountedHide()
    if ShamanBindsDB.hideConsoleMounted then
      print("|cff0070ddShaman Binds:|r shaman bar hides while mounted. |cffffffff/shamanbinds console|r shows it.")
    else
      print("|cff0070ddShaman Binds:|r shaman bar stays visible while mounted. |cffffffff/shamanbinds console|r hides it.")
    end
    return
  end
  if cmd == "mouse" or cmd == "diag" then
    P.PrintMouseDiag()
    return
  end
  if cmd == "talents" or cmd == "talent" or cmd == "build" then
    P.ApplyLevel80Talents()
    return
  end
  if cmd == "chat" then
    if Locked() then P.Report("Leave combat first."); return end
    P.RestoreChatKeys()
    pcall(SaveBindings, GetCurrentBindingSet())
    print("|cff0070ddShaman Binds:|r Enter opens chat. / opens a slash command.")
    return
  end
  print("|cff0070ddShaman Binds:|r unknown command. |cffffffff/shamanbinds help|r")
end

SLASH_SHAMANBINDS1 = "/shamanbinds"
SLASH_SHAMANBINDS2 = "/sbinds"
SlashCmdList.SHAMANBINDS = P.SlashBinds

SLASH_SBKEYMAP1 = "/keymap"
SLASH_SBKEYMAP2 = "/km"
SlashCmdList.SBKEYMAP = P.ToggleKeymap

print("|cff0070ddShaman Binds:|r 8.34 helper cooldown and glow loaded. Prime is the default. |cffffffff/shamanbinds load Farseer|r for Elemental. |cffffffff/shamanbinds keys|r for reserved chords.")
pcall(function() P.RegisterSettings() end)
