-- Super Binds 0.5.117 — class-agnostic port of the Shaman Binds 8.34 engine.
-- Packs live in Profiles/. Engine: native ACTIONBUTTON faces, BIND, drawers, shimmer.
SuperBindsDB = type(SuperBindsDB) == "table" and SuperBindsDB or {}

local SBA_ID = 1229376

local KEEP = {}
local PLACED_SPELLS = {}

local drag = { ability = nil, fromTag = nil, bindKey = nil, fromPrimary = false, active = false }
local console, consoleTabs, menus, allMenuButtons, HoldMenus
local busy, finishing = false, false
consoleTabs, menus, allMenuButtons = {}, {}, {}
-- Helpers on P do not count toward Lua's 200-local file limit.
local P = {}
local RefreshLayout, NormalizeAbility, Locked, Known, ClearSlot

P.Packs = {}
function P.RegisterProfile(t)
  if type(t) ~= "table" or not P.Text(t.name) then return false end
  P.Packs[t.name] = t
  return true
end
function P.PlayerClass()
  local ok, _, token = pcall(UnitClass, "player")
  return ok and token or nil
end
function P.PackMatches(t)
  if type(t) ~= "table" then return false end
  local class = P.PlayerClass()
  return not t.class or t.class == class
end
function P.FindPack(name)
  if not P.Text(name) then return end
  local want = name:lower()
  for n, t in pairs(P.Packs) do
    if n:lower() == want then return t, n end
  end
  for n, t in pairs(P.Packs) do
    local mode = t.familyMode
    if type(mode) == "string" and mode:lower() == want then return t, n end
  end
end
function P.DefaultPack()
  local specPack = P.PackForPlayerSpec and P.PackForPlayerSpec()
  if specPack then return specPack end
  local fallback
  for _, t in pairs(P.Packs) do
    if P.PackMatches(t) then
      if t.default then return t end
      fallback = fallback or t
    end
  end
  return fallback
end
function P.ClassHasPack()
  return P.DefaultPack() ~= nil
end
function P.PlayerSpecName()
  local name
  pcall(function()
    local idx
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
      idx = C_SpecializationInfo.GetSpecialization()
    elseif GetSpecialization then
      idx = GetSpecialization()
    end
    if not idx then return end
    local n
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
      _, n = C_SpecializationInfo.GetSpecializationInfo(idx)
    elseif GetSpecializationInfo then
      _, n = GetSpecializationInfo(idx)
    end
    name = P.Text(n)
  end)
  return name
end
function P.PlayerSpecID()
  local id
  pcall(function()
    local idx
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
      idx = C_SpecializationInfo.GetSpecialization()
    elseif GetSpecialization then
      idx = GetSpecialization()
    end
    if not idx then return end
    local specID
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
      specID = C_SpecializationInfo.GetSpecializationInfo(idx)
    elseif GetSpecializationInfo then
      specID = GetSpecializationInfo(idx)
    end
    id = P.ID(specID)
  end)
  return id
end
function P.PlayerHeroTalentID()
  local id
  pcall(function()
    if C_ClassTalents and C_ClassTalents.GetActiveHeroTalentSpec then
      id = P.ID(C_ClassTalents.GetActiveHeroTalentSpec())
    end
  end)
  return id
end
function P.PackForPlayerSpec()
  local specID = P.PlayerSpecID and P.PlayerSpecID()
  local heroID = P.PlayerHeroTalentID and P.PlayerHeroTalentID()
  local exact, generic, preferred
  if specID then
    for _, pack in pairs(P.Packs) do
      if P.PackMatches(pack) and pack.spec == specID then
        if heroID and pack.hero == heroID then
          if pack.default then exact = pack
          else exact = exact or pack end
        elseif not pack.hero then
          generic = generic or pack
        end
        if pack.default then preferred = preferred or pack end
      end
    end
    if exact then return exact, exact.name end
    if heroID then
      if generic then return generic, generic.name end
    else
      if preferred then return preferred, preferred.name end
      if generic then return generic, generic.name end
    end
    for _, pack in pairs(P.Packs) do
      if P.PackMatches(pack) and pack.spec == specID then return pack, pack.name end
    end
  end
  local spec = P.PlayerSpecName()
  if not P.Text(spec) then return nil end
  local t, n = P.FindPack(spec)
  if t and P.PackMatches(t) then return t, n or t.name end
  local want = spec:lower()
  for _, pack in pairs(P.Packs) do
    if P.PackMatches(pack) then
      local mode = pack.familyMode or pack.name
      if type(mode) == "string" and mode:lower() == want then return pack, pack.name end
    end
  end
end
function P.CurrentPack()
  local specPack = P.PackForPlayerSpec and select(1, P.PackForPlayerSpec())
  local name = SuperBindsDB and SuperBindsDB.activeProfile
  local t = name and P.FindPack(name)
  if specPack and t and t ~= specPack and t.class and specPack.class and t.class == specPack.class then
    return specPack
  end
  if t and P.PackMatches(t) then return t end
  return specPack or P.DefaultPack()
end
function P.BarPages()
  return NUM_ACTIONBAR_PAGES or 6
end
function P.BarButtons()
  return NUM_ACTIONBAR_BUTTONS or 12
end
function P.UnclaimedBonusOffset()
  local ok, offset = pcall(GetBonusBarOffset)
  if not ok or not P.Number(offset) or offset <= 0 then return nil end
  local pack = P.CurrentPack and P.CurrentPack()
  for _, spec in pairs((pack and pack.actionBars) or {}) do
    if type(spec) == "table" and tonumber(spec.bonus) == offset and not P.Text(spec.use) then
      return nil
    end
  end
  return offset
end

function P.BarOwner(form)
  local pack = P.CurrentPack()
  if not pack or not form then return form end
  local spec = pack.actionBars and pack.actionBars[form]
  -- Ground travel may share caster slots. Skyriding travel is bonus 5, not caster.
  if type(spec) == "table" and P.Text(spec.use) then
    if P.UnclaimedBonusOffset and P.UnclaimedBonusOffset() then return form end
    return spec.use
  end
  return form
end
function P.CurrentForm()
  local pack = P.CurrentPack()
  local fallback = pack and pack.form or "caster"
  if type(GetShapeshiftForm) ~= "function" then return fallback end
  local ok, index = pcall(GetShapeshiftForm)
  -- Secret/unknown must not pretend we are caster. Next-cast returns nil instead.
  if not ok or (issecretvalue and issecretvalue(index)) or not P.Number(index) then return nil end
  if index == 0 then
    -- Druid flight / skyriding is still Travel Form. GetShapeshiftForm is 0.
    local aura = P.FormFromAuras and P.FormFromAuras()
    if aura then return aura end
    -- Unmatched bonus (skyriding ~5) is not caster. Moonkin with no pack bar
    -- stays unknown rather than stealing the last stance's overlay.
    if P.UnclaimedBonusOffset and P.UnclaimedBonusOffset() then
      if pack and type(pack.forms) == "table" and pack.forms.travel then return "travel" end
      return nil
    end
    return fallback
  end
  local infoOk, formName, _, _, id = pcall(GetShapeshiftFormInfo, index)
  if not infoOk then return nil end
  id = P.ID(id)
  formName = P.Text(formName)
  if pack and type(pack.forms) == "table" then
    for name, spec in pairs(pack.forms) do
      for _, sid in ipairs((type(spec) == "table" and spec.spells) or {}) do
        if id and sid == id then return name end
      end
    end
    -- Haranir / alternate shapeshift IDs still use the localized form name.
    if formName then
      local lower = formName:lower()
      for name, spec in pairs(pack.forms) do
        if P.Text(name) and lower:find(name:lower(), 1, true) then return name end
        for _, sid in ipairs((type(spec) == "table" and spec.spells) or {}) do
          local sn = C_Spell and C_Spell.GetSpellName and P.Text(C_Spell.GetSpellName(sid))
          if sn and (sn == formName or sn:lower() == lower) then return name end
        end
      end
    end
  end
  return nil
end

-- Stance page actually shown. GetShapeshiftFormInfo IDs can miss Haranir
-- forms and then PackFormNow used to pretend we were caster.
function P.BonusBarForm()
  local pack = P.CurrentPack and P.CurrentPack()
  if not pack or type(pack.actionBars) ~= "table" then return nil end
  local ok, offset = pcall(GetBonusBarOffset)
  if not ok or not P.Number(offset) then return nil end
  if offset <= 0 then
    -- Shifted but bonus not public yet is not caster.
    local idxOk, index = pcall(GetShapeshiftForm)
    if idxOk and P.Number(index) and index > 0 then return nil end
    return "caster"
  end
  for name, spec in pairs(pack.actionBars) do
    if type(spec) == "table" and tonumber(spec.bonus) == offset and not P.Text(spec.use) then
      return name
    end
  end
end

function P.PackFormNow()
  local pack = P.CurrentPack and P.CurrentPack()
  if not pack then return "caster" end
  local form = P.BonusBarForm and P.BonusBarForm()
  if not form then form = P.CurrentForm and P.CurrentForm() end
  if form and P.BarOwner then form = P.BarOwner(form) or form end
  if P.Text(form) then
    P._barForm = form
    return form
  end
  -- Unmatched bonus (skyriding) is not the last stance and not caster.
  if P.UnclaimedBonusOffset and P.UnclaimedBonusOffset() then return nil end
  if P._barForm then return P._barForm end
  if pack.actionBars then return nil end
  return pack.form or "caster"
end
function P.PackNativeForm(pack)
  pack = pack or (P.CurrentPack and P.CurrentPack())
  if type(pack) ~= "table" then return nil end
  if P.Text(pack.nativeForm) then return pack.nativeForm end
  local mode = pack.familyMode or pack.name
  if type(mode) ~= "string" then return nil end
  mode = mode:lower()
  if mode == "guardian" then return "bear" end
  if mode == "feral" then return "cat" end
  if mode == "balance" then return "moonkin" end
end
function P.AbilityLooksLikeShapeshift(ab)
  if type(ab) ~= "table" then return false end
  local name = P.Text(ab.name) or P.Text(ab.label)
  if name and name:find("Form", 1, true) then return true end
  local pack = P.CurrentPack and P.CurrentPack()
  local ids = {}
  local function take(sid)
    sid = P.ID(sid)
    if sid then ids[sid] = true end
  end
  if type(ab.spell) == "table" then
    for _, sid in ipairs(ab.spell) do take(sid) end
  end
  take(ab.id)
  for _, spec in pairs((pack and pack.forms) or {}) do
    for _, sid in ipairs((type(spec) == "table" and spec.spells) or {}) do
      if ids[P.ID(sid)] then return true end
    end
  end
  return false
end

function P.PlayerHasSpellAura(id)
  id = P.ID(id)
  if not id then return false end
  if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
    local ok, info = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
    if ok and type(info) == "table" then return true end
  end
  local name = C_Spell and C_Spell.GetSpellName and P.Text(C_Spell.GetSpellName(id))
  if name and AuraUtil and AuraUtil.FindAuraByName then
    local ok, aura = pcall(AuraUtil.FindAuraByName, name, "player")
    if ok and aura then return true end
  end
  return false
end

function P.FormFromAuras()
  local pack = P.CurrentPack and P.CurrentPack()
  if type(pack) ~= "table" or type(pack.forms) ~= "table" then return nil end
  for name, spec in pairs(pack.forms) do
    for _, sid in ipairs((type(spec) == "table" and spec.spells) or {}) do
      if P.PlayerHasSpellAura(sid) then return name end
    end
    local title = P.Text(name)
    if title then
      local pretty = title:sub(1, 1):upper() .. title:sub(2) .. " Form"
      if AuraUtil and AuraUtil.FindAuraByName then
        local ok, aura = pcall(AuraUtil.FindAuraByName, pretty, "player")
        if ok and aura then return name end
      end
    end
  end
end

function P.CollectFormBinds()
  local out = {}
  local pack = P.CurrentPack and P.CurrentPack()
  local function take(spec)
    if type(spec) ~= "table" or not P.AbilityLooksLikeShapeshift(spec) then return end
    local key = P.Text(spec.bindKey)
    if not key then return end
    local cmd = P.SpellBindCommand and P.SpellBindCommand(spec.spell)
    local name = cmd and cmd:match("^SPELL (.+)$")
    if name then out[key] = name end
  end
  for _, fam in ipairs((pack and pack.families) or {}) do
    take(fam.bar)
    if type(fam.bars) == "table" then
      for _, spec in pairs(fam.bars) do take(spec) end
    end
    for _, it in ipairs(fam.items or {}) do take(it) end
  end
  return out
end

function P.FormBindCommand(key)
  key = P.Text(key)
  if not key then return nil end
  local name = P.CollectFormBinds()[key]
  return name and ("SPELL " .. name) or nil
end

function P.PackFaceCommand(key)
  key = P.Text(key)
  if not key then return nil end
  local formCmd = P.FormBindCommand(key)
  if formCmd then return formCmd end
  local pack = P.CurrentPack and P.CurrentPack()
  local function take(spec)
    if type(spec) ~= "table" or P.Text(spec.bindKey) ~= key then return nil end
    if type(spec.macro) == "table" then
      local cmd = P.NamedMacroCommand and P.NamedMacroCommand(spec.macro[1])
      if cmd then return cmd end
    end
    if spec.spell then return P.SpellBindCommand and P.SpellBindCommand(spec.spell) end
  end
  for _, fam in ipairs((pack and pack.families) or {}) do
    local cmd = take(fam.bar)
    if cmd then return cmd end
    if type(fam.bars) == "table" then
      for _, spec in pairs(fam.bars) do
        cmd = take(spec)
        if cmd then return cmd end
      end
    end
    for _, it in ipairs(fam.items or {}) do
      cmd = take(it)
      if cmd then return cmd end
    end
  end
end

-- Live skyriding bar: E/Q/C already own Surge / Second Wind / Whirling.
-- Aerial Halt and Skyward Ascent sit on our form/thorn columns; they move to 1/2.
P.SKYRIDING_KEYS = {
  ["Aerial Halt"] = "1",
  ["Skyward Ascent"] = "2",
}

function P.SkyridingExtraKeys()
  local out = {}
  if not (P.UseMountBar and P.UseMountBar()) then return out end
  local seen = {}
  local n = (P.BarButtons and P.BarButtons()) or 12
  for rel = 1, n do
    local abs = P.LiveActionSlot and P.LiveActionSlot(rel)
    local native = abs and P.NativeAbility and P.NativeAbility(abs)
    local name = native and (P.Text(native.name) or P.Text(native.label))
    local key = name and P.SKYRIDING_KEYS[name]
    if key and not seen[key] then
      seen[key] = true
      out[#out + 1] = {
        key = key, name = name, label = name,
        id = native.id, icon = native.icon,
      }
    end
  end
  table.sort(out, function(a, b) return a.key < b.key end)
  return out
end

function P.SyncSkyridingDriver()
  local d = P.barDriver
  if not d then return end
  local i = 0
  local function add(key, spell)
    key, spell = P.Text(key), P.Text(spell)
    if not key or not spell then return end
    i = i + 1
    d:SetAttribute("sk" .. i, key)
    d:SetAttribute("ss" .. i, spell)
  end
  for key, name in pairs(P.CollectFormBinds()) do add(key, name) end
  for _, row in ipairs(P.SkyridingExtraKeys()) do add(row.key, row.name) end
  local old = tonumber(d:GetAttribute("sn")) or 0
  for j = i + 1, old do
    d:SetAttribute("sk" .. j, nil)
    d:SetAttribute("ss" .. j, nil)
  end
  d:SetAttribute("sn", i)
end

function P.ApplySkyridingKeybinds(owner)
  if Locked() then return end
  owner = owner or P.barDriver
  if not owner then return end
  P.SyncSkyridingDriver()
  if not (P.UseMountBar and P.UseMountBar()) then return end
  for key, name in pairs(P.CollectFormBinds()) do
    pcall(SetOverrideBindingSpell, owner, true, key, name)
  end
  for _, row in ipairs(P.SkyridingExtraKeys()) do
    pcall(SetOverrideBindingSpell, owner, true, row.key, row.name)
  end
end

function P.FamilyHasBars(tag)
  if not P.Text(tag) then return false end
  local pack = P.CurrentPack and P.CurrentPack()
  if type(pack) ~= "table" or type(pack.families) ~= "table" then return false end
  for _, fam in ipairs(pack.families) do
    if fam.tag == tag then
      if type(fam.bars) == "table" then return true end
      if type(fam.bar) == "table" and tonumber(fam.bar.slot) then return true end
    end
  end
  return false
end

function P.FamilyBarSpec(tag, form)
  if not P.Text(tag) then return nil end
  local pack = P.CurrentPack and P.CurrentPack()
  if type(pack) ~= "table" then return nil end
  form = form or (P.PackFormNow and P.PackFormNow())
  if form and P.BarOwner then form = P.BarOwner(form) or form end
  for _, fam in ipairs(pack.families or {}) do
    if fam.tag == tag then
      if type(fam.bars) == "table" then
        -- A missing form entry is not permission to write the caster bar.
        -- Unknown stance state must fail closed until Blizzard exposes it.
        return fam.bars[form]
      end
      return fam.bar
    end
  end
end
function P.SlotBase(form)
  form = P.BarOwner(form)
  local pack = P.CurrentPack()
  local spec = pack and pack.actionBars and pack.actionBars[form]
  local n = P.BarButtons()
  if type(spec) == "table" then
    local bonus = tonumber(spec.bonus)
    if bonus and bonus > 0 then return (P.BarPages() + bonus - 1) * n end
    local page = tonumber(spec.page) or 1
    return (page - 1) * n
  end
  return 0
end
function P.ActionSlot(rel, form)
  rel = tonumber(rel)
  if not rel or rel < 1 or rel > P.BarButtons() then return nil end
  local pack = P.CurrentPack()
  if not (pack and pack.actionBars) then return rel end
  return P.SlotBase(form) + rel
end
-- Bear E is 97, not page-1 slot 1. Named form can miss Haranir IDs; the live
-- bonus offset is what ACTIONBUTTON1 actually fires. Never guess caster
-- because a shapeshift id missed.
function P.LiveActionSlot(rel)
  rel = tonumber(rel)
  if not rel or rel < 1 or rel > P.BarButtons() then return nil end
  local n = P.BarButtons()
  local ok, offset = pcall(GetBonusBarOffset)
  if ok and P.Number(offset) then
    if offset > 0 then
      return (P.BarPages() + offset - 1) * n + rel
    end
    return P.ActionSlot(rel, "caster") or rel
  end
  local form = P.PackFormNow and P.PackFormNow()
  if form then return P.ActionSlot(rel, form) end
end
-- Relative 1-12 columns this pack actually owns (faces + hardware + barBinds).
-- Apply vacates the rest so a profile switch does not leave Growl on 11.
function P.PackClaimedRelSlots()
  local owned = {}
  local pack = P.CurrentPack and P.CurrentPack()
  if type(pack) ~= "table" then return owned end
  local function claim(spec)
    if type(spec) ~= "table" then return end
    local slot = tonumber(spec.slot)
    if slot and slot >= 1 and slot <= 12 then owned[slot] = true end
  end
  for _, fam in ipairs(pack.families or {}) do
    if type(fam.bars) == "table" then
      for _, spec in pairs(fam.bars) do claim(spec) end
    end
    claim(fam.bar)
    claim(fam.bar2)
    for _, it in ipairs(fam.items or {}) do claim(it) end
  end
  for _, spec in pairs(pack.hardware or {}) do claim(spec) end
  for _, cmd in pairs(pack.barBinds or {}) do
    if type(cmd) == "string" then
      local slot = tonumber(cmd:match("ACTIONBUTTON(%d+)"))
      if slot and slot >= 1 and slot <= 12 then owned[slot] = true end
    end
  end
  return owned
end

function P.VacateUnclaimedBarSlots()
  if Locked() then return end
  local owned = P.PackClaimedRelSlots and P.PackClaimedRelSlots() or {}
  local n = P.BarButtons()
  for _, form in ipairs(P.UniqueBarForms()) do
    for rel = 1, n do
      if not owned[rel] then
        local abs = P.ActionSlot(rel, form)
        if abs then
          pcall(ClearCursor)
          ClearSlot(abs)
        end
      end
    end
  end
  pcall(ClearCursor)
end

function P.UniqueBarForms()
  local pack = P.CurrentPack()
  local out, seen = {}, {}
  local function add(form)
    form = P.BarOwner(form)
    if form and not seen[form] then seen[form] = true; out[#out + 1] = form end
  end
  if pack then
    add(pack.form or "caster")
    for name in pairs(pack.forms or {}) do add(name) end
    for name, spec in pairs(pack.actionBars or {}) do
      if type(spec) == "table" and not P.Text(spec.use) then add(name) end
    end
  else
    add("caster")
  end
  return out
end
function P.NeverSuggest(id, name)
  local pack = P.CurrentPack()
  local list = pack and pack.neverSuggest
  if type(list) ~= "table" then return false end
  if list[id] or (name and list[name]) then return true end
  for _, v in ipairs(list) do
    if v == id or v == name then return true end
  end
  return false
end
function P.SpellReady(id)
  if not id then return false end
  local usable = true
  if C_Spell and C_Spell.IsSpellUsable then
    local ok, u = pcall(C_Spell.IsSpellUsable, id)
    if ok then
      if issecretvalue and issecretvalue(u) then return nil end
      if u == false then return false end
    end
  end
  if C_Spell and C_Spell.GetSpellCooldown then
    local ok, cd = pcall(C_Spell.GetSpellCooldown, id)
    if ok and type(cd) == "table" then
      local start, duration = cd.startTime, cd.duration
      if issecretvalue and (issecretvalue(start) or issecretvalue(duration)) then
        return nil
      end
      start, duration = tonumber(start), tonumber(duration)
      if start and duration then
        local onCd = false
        local ok2 = pcall(function()
          onCd = duration > 1.6 and (start + duration) > GetTime()
        end)
        if not ok2 then return nil end
        if onCd then return false end
      end
    end
  end
  return usable
end
function P.ProfileNextCast()
  local pack = P.CurrentPack()
  local form = P.CurrentForm()
  if not pack or not form then return nil end
  local rules = pack.rotation and pack.rotation[form]
  if type(rules) ~= "table" then return nil end
  local fallback
  for _, rule in ipairs(rules) do
    if type(rule) == "table" and type(rule.spell) == "table" then
      local name, id = Known(unpack(rule.spell))
      if id and not P.NeverSuggest(id, name) then
        if rule.auraMissing then
          local rec = P.castAt and P.castAt[id]
          if rec and rec.t and (GetTime() - rec.t) < (rule.dot or 16) then
            name = nil
          elseif C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName and name then
            local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, "target", name, "HARMFUL|PLAYER")
            if ok and aura ~= nil and not (issecretvalue and issecretvalue(aura)) then
              name = nil
            end
          end
        end
        if name and rule.minPower then
          local value
          pcall(function() value = UnitPower and UnitPower("player", rule.powerType) end)
          if issecretvalue and issecretvalue(value) then
            name = nil
          elseif not P.ID(value) or value < rule.minPower then
            name = nil
          end
        end
        if name and id then
          if rule.fallback then fallback = id
          elseif P.SpellReady(id) then return id end
        end
      end
    end
  end
  return fallback
end
function P.EnsureFormPageDriver()
  if Locked() then return end
  local pack = P.CurrentPack()
  if not (pack and pack.actionBars) then return end
  local d = P.formPageDriver
  if not d then
    d = CreateFrame("Frame", "SuperBindsFormPage", UIParent, "SecureHandlerStateTemplate")
    P.formPageDriver = d
    d:SetAttribute("_onstate-page", [[
      local page = tonumber(newstate) or 1
      local n = self:GetAttribute("n") or 0
      local buttons = tonumber(self:GetAttribute("buttons")) or 12
      for i = 1, n do
        local tab = self:GetFrameRef("t"..i)
        local rel = tab and tonumber(tab:GetAttribute("relslot"))
        if tab and rel then
          tab:SetAttribute("action", (page - 1) * buttons + rel)
        end
      end
    ]])
  end
  d:SetAttribute("buttons", P.BarButtons())
  local n = 0
  for _, tab in ipairs(consoleTabs) do
    if tab:GetAttribute("relslot") then
      n = n + 1
      d:SetFrameRef("t" .. n, tab)
    end
  end
  d:SetAttribute("n", n)
  local pages, parts, seen = P.BarPages(), {}, {}
  for _, spec in pairs(pack.actionBars) do
    local bonus = type(spec) == "table" and tonumber(spec.bonus)
    if bonus and bonus > 0 and not seen[bonus] then
      seen[bonus] = true
      parts[#parts + 1] = string.format("[bonusbar:%d] %d", bonus, pages + bonus)
    end
  end
  for n = 1, 5 do
    if not seen[n] then
      parts[#parts + 1] = string.format("[bonusbar:%d] %d", n, pages + n)
    end
  end
  parts[#parts + 1] = "1"
  pcall(RegisterStateDriver, d, "page", table.concat(parts, "; "))
end

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
    if P.ApplyPressPulseShown then P.ApplyPressPulseShown() end
  end)
end

function Locked()
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

-- Secret-safe unwrap for non-numbers (textures, names).
function P.Public(value)
  if value == nil then return nil end
  if issecretvalue and issecretvalue(value) then return nil end
  return value
end

-- pcall a Blizzard getter and return its results. Missing fn is a no-op.
function P.Read(fn, ...)
  if type(fn) ~= "function" then return end
  local ok, a, b, c, d, e, f = pcall(fn, ...)
  if not ok then return end
  return a, b, c, d, e, f
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
  print("|cff0070ddSuper Binds:|r " .. tostring(err))
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
P.GAP = 5

-- Class-selected presentation only. Ability engines remain Shaman-specific.
P.ClassThemes = {
  DEFAULT={accent={0.65,0.73,0.82,1}, metal={0.51,0.52,0.55,1},
    endcap="Interface\\AddOns\\SuperBinds\\Media\\ShamanEndcap.tga",
    endcapW=70, endcapH=120,
    endcapHorde="Interface\\AddOns\\SuperBinds\\Media\\DruidEndcap_horde.tga",
    endcapHordeW=90, endcapHordeH=120},
}

function P.PlayerIsHorde()
  if type(UnitFactionGroup)~="function" then return false end
  local ok, group=pcall(UnitFactionGroup, "player")
  return ok and group=="Horde"
end

function P.FormEndcap()
  local by = P.Visual.endcaps
  if type(by) ~= "table" then return nil end
  local form
  if P.CurrentForm then form = P.CurrentForm() end
  -- Art follows the animal, not the bar page. Travel shares caster slots
  -- (use="caster") so BarOwner would look up endcaps.caster and miss the sable.
  if P.Text(form) then P._endcapForm = form else form = P._endcapForm end
  if not P.Text(form) then return nil end
  local spec = by[form]
  if type(spec) == "string" then return spec, nil, nil, false end
  if type(spec) ~= "table" then return nil end
  local path = spec.path or spec.file or spec.texture
  if not P.Text(path) then return nil end
  return path, spec.w or spec.width or spec.endcapWidth,
    spec.h or spec.height or spec.endcapHeight, spec.eyes and true or false,
    spec.leftIn or spec.left, spec.rightIn or spec.right
end

function P.ApplyEndcapArt()
  P.ApplyFactionChrome()
end

function P.TintTex(tex, color, alpha)
  if not tex or not color then return end
  tex:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
end

function P.PlaceEndcaps(path, w, h)
  if not path or not console then return end
  local plate = console._sbVisualPlate
  local leftIn = P.Visual.endcapLeftIn or 36
  local rightIn = P.Visual.endcapRightIn or -36
  for i, art in ipairs(console._sbEndcaps or {}) do
    art:SetTexture(path)
    if w and h then art:SetSize(w, h) end
    P.SmoothUITexture(art)
    if plate then
      art:ClearAllPoints()
      if i == 1 then
        art:SetPoint("RIGHT", plate, "LEFT", leftIn, 14)
      else
        art:SetPoint("LEFT", plate, "RIGHT", rightIn, 14)
      end
    end
  end
end

function P.ApplyFactionChrome()
  local path, w, h = P.Visual.endcap, P.Visual.endcapW, P.Visual.endcapH
  local eyes = P.Visual.faction ~= "Horde"
  P.Visual.endcapLeftIn = 36
  P.Visual.endcapRightIn = -36
  local fp, fw, fh, feyes, leftIn, rightIn = P.FormEndcap()
  if fp then
    path = fp
    if fw then w = fw end
    if fh then h = fh end
    eyes = feyes
    if leftIn then P.Visual.endcapLeftIn = leftIn end
    if rightIn then P.Visual.endcapRightIn = rightIn end
  end
  P.Visual.endcapEyes = eyes
  if path and console then
    P.PlaceEndcaps(path, w, h)
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
      glow:SetTexture("Interface\\AddOns\\SuperBinds\\Media\\ShamanEndcap_owl_eyes")
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
  local on = P._sbEyesReady and console:IsShown() and P.Visual.endcapEyes
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
  P.Visual.endcaps=theme.endcaps
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
        art:SetPoint("RIGHT",plate,"LEFT",P.Visual.endcapLeftIn or 36,14)
        art:SetTexCoord(0, 1, 0, 1)
      else
        art:SetDrawLayer("OVERLAY", 7)
        art:SetPoint("LEFT",plate,"RIGHT",P.Visual.endcapRightIn or -36,14)
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
  if type(id) == "string" and id ~= "" then return id end
  if type(id) ~= "number" or id <= 0 then return nil end
  local nm = P.Read(C_Spell and C_Spell.GetSpellName, id)
  return P.Text(nm)
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
P.SPELL_ID = {}
P.SPELL_ICON = {}

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
  local pack = P.CurrentPack and P.CurrentPack()
  if type(name) ~= "string" or not pack then return false end
  local list = pack.actionOverride
  if type(list) ~= "table" then return false end
  for _, n in ipairs(list) do if n == name then return true end end
  return list[name] == true
end

function Known(...)
  local function spellInfo(ident)
    if type(ident) == "number" then
      if ident <= 0 then return nil end
    elseif type(ident) ~= "string" or ident == "" then
      return nil
    end
    local info = P.Read(C_Spell and C_Spell.GetSpellInfo, ident)
    return type(info) == "table" and info or nil
  end
  for i = 1, select("#", ...) do
    local want = select(i, ...)
    if type(want) == "number" and want > 0 then
      local nm = SpellName(want)
      if not nm then
        local info = spellInfo(want)
        nm = info and P.Text(info.name)
      end
      if nm and (P.PlayerKnows(want) or BOOK[nm]) then return nm, want end
    elseif type(want) == "string" and want ~= "" and BOOK[want] then
      return want, BOOK[want]
    end
  end
  for i = 1, select("#", ...) do
    local name = select(i, ...)
    if type(name) == "string" and name ~= "" then
      local id = P.SPELL_ID[name]
      if id and P.PlayerKnows(id) then return name, id end
    end
    local info = spellInfo(name)
    if info then
      local id2 = P.ID(info.spellID)
      local nm = P.Text(info.name) or (type(name) == "string" and name) or nil
      if id2 and nm and P.PlayerKnows(id2) then return nm, id2 end
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
  id = P.ID(id)
  if id then
    local tex = P.Read(C_Spell and C_Spell.GetSpellTexture, id)
    if tex and tex ~= 0 and tex ~= 134400 then return tex end
  end
  if name and P.SPELL_ICON[name] then return P.SPELL_ICON[name] end
  return 134400
end

local RACIALS = {
  "Blood Fury", "Berserking", "War Stomp", "Stoneform", "Gift of the Naaru",
  "Quaking Palm", "Arcane Torrent", "Fireblood", "Ancestral Call", "Bull Rush",
  "Spatial Rift", "Light's Judgment", "Rocket Barrage", "Bag of Tricks",
  "Regeneratin'", "Shadowmeld", "Escape Artist", "Every Man for Himself",
  "Will to Survive", "Darkflight", "Haymaker",
}

-- SBA / passives / replaced buttons. Never dump these into +.
local STATIC_EXCLUDE = {
}

local function PickupID(id)
  if C_Spell and C_Spell.PickupSpell then C_Spell.PickupSpell(id) else PickupSpell(id) end
end

function ClearSlot(slot)
  PickupAction(slot)
  pcall(ClearCursor)
  if P.CursorHasPickup and P.CursorHasPickup() then
    -- Secret cursor: dump onto hidden bar 6 then destroy, or leftover
    -- PickupAction shuffles Growl/Barkskin across unused 11-12.
    PlaceAction(72)
    PickupAction(72)
    pcall(ClearCursor)
  end
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
  -- GetCursorInfo may be secret even when the cursor looks empty. Clear it
  -- before every native placement so PickupSpell cannot swap a previous action
  -- into the next form slot.
  pcall(ClearCursor)
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

-- Spellbook / rune-book drops already hold the ability. Place that cursor
-- onto the live slot. Clearing first and PickupSpell(1229376) is how SBA
-- drops used to vanish — Assisted Combat is not a normal pickupable spell.
function P.PlaceCursorOnSlot(slot)
  if Locked() or not P.ID(slot) then return false end
  local kind = P.CursorKind()
  if not kind then return false end
  if kind == "secret" and not (P.CursorIsAssisted and P.CursorIsAssisted()) then
    return false
  end
  PlaceAction(slot)
  ClearCursor()
  KEEP[slot] = true
  return true
end

function P.CursorHasPickup()
  if P.CursorIsAssisted and P.CursorIsAssisted() then return true end
  local kind = P.CursorKind()
  if kind and kind ~= "secret" then
    return kind == "spell" or kind == "item" or kind == "macro" or kind == "mount"
      or kind == "pet" or kind == "action" or kind == "flyout" or kind == "companion"
      or kind == "petaction"
  end
  local function has(fn)
    if type(fn) ~= "function" then return false end
    local ok, v = pcall(fn)
    if not ok then return false end
    if issecretvalue and issecretvalue(v) then return false end
    return v and true or false
  end
  return has(CursorHasSpell) or has(CursorHasItem) or has(CursorHasMacro)
end

function P.FindAssistedBookSlot()
  local api = C_SpellBook
  if not api or not api.GetNumSpellBookSkillLines then return end
  local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
  local want = P.AssistedActionID and P.AssistedActionID()
  local assistedType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.AssistedCombat
  local n = api.GetNumSpellBookSkillLines()
  for line = 1, n or 0 do
    local li = api.GetSpellBookSkillLineInfo(line)
    if li and not li.offSpecID then
      for j = (li.itemIndexOffset or 0) + 1, (li.itemIndexOffset or 0) + (li.numSpellBookItems or 0) do
        local it = P.BookInfo(j, bank)
        if it then
          if assistedType and it.itemType == assistedType then return j, bank end
          if P.IsAssistedToken(it.itemType) or P.IsAssistedToken(it.name) then return j, bank end
          local sid = P.ID(it.spellID)
          if sid and (sid == SBA_ID or sid == want) then return j, bank end
        end
      end
    end
  end
end

function P.PickupAssisted()
  if P.CursorIsAssisted and P.CursorIsAssisted() then return true end
  local kind = P.CursorKind()
  if kind and kind ~= "secret" then pcall(ClearCursor) end
  PickupID(P.AssistedActionID())
  if P.CursorIsAssisted and P.CursorIsAssisted() then return true end
  if P.CursorHasPickup and P.CursorHasPickup() then return true end
  pcall(ClearCursor)
  local slot, bank = P.FindAssistedBookSlot()
  if not slot then return false end
  pcall(function()
    if C_SpellBook and C_SpellBook.PickupSpellBookItem then
      C_SpellBook.PickupSpellBookItem(slot, bank)
    elseif PickupSpellBookItem then
      PickupSpellBookItem(slot, "spell")
    end
  end)
  return (P.CursorIsAssisted and P.CursorIsAssisted()) or (P.CursorHasPickup and P.CursorHasPickup()) or false
end

function P.PlaceAssisted(slot)
  if Locked() or not P.ID(slot) then return false end
  if not P.PickupAssisted() then return false end
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
  for _, name in pairs(SuperBindsDB.macroNames or {}) do keep[name] = true end
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
  local registry = SuperBindsDB.macroNames
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
    P.Report("Macro storage full. Free a macro slot, then /superbinds. Existing macros were preserved.")
  end
  return nil
end

local function PlaceMacro(slot, name, icon, body, pulseName, frameName)
  if Locked() then return false end
  pcall(ClearCursor)
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
  if slot >= 13 and slot <= 24 then SuperBindsDB.hiddenSlots[slot] = GetMacroInfo(index) end
  return true
end

-- Midnight blocks @cursor (and some totem) casts from addon SecureActionButtons.
-- Those macros must sit on a real Blizzard action slot; the key clicks that slot.
-- Hidden helpers park on 13-24. Columns 8-12 are faces (M5, R, M4). Never 61-72.
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
-- Hidden helpers park on 13-24. M4/M5/R are faces on 8-12.
local function NeedsBlizzardSlot(item)
  if type(item) ~= "table" then return false end
  if item.equipmentSlot then return false end
  if item.target == "cursor" then return true end
  local t = item.macrotext
  if t and t:find("@cursor", 1, true) then return true end
  if item.blizzardSlot or item.needsSlot then return true end
  local nm = item.name or item.label
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
}

function P.HardwareLabel(key)
  return HARDWARE_LABEL[key]
end

function P.WarnBindsOn()
  return SuperBindsDB.warnBinds ~= false
end

function P.ReservedBindReason(key)
  local pack = P.CurrentPack and P.CurrentPack()
  local reserved = pack and pack.reserved
  if type(reserved) == "table" and reserved[key] then
    return reserved[key]
  end
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
  print("|cff0070ddSuper Binds keys:|r")
  print("  |cffffffffReserved|r  Ctrl-Wheel = zoom. Ctrl-M4 / Ctrl-M5 = zoom (WoW Keybindings). Numpad + / − = zoom. Enter / = chat.")
  print("  |cffffffffWheel|r  Unmodified wheel stays camera unless this pack claims it (Guardian: forms).")
  print("  |cffffffffBIND|r  Hover an icon, press a key or scroll. Labels follow the live ACTIONBUTTON bind.")
  print("  |cffffffffWoW Keybindings|r  Rebinding Action Button N in WoW updates the matching console face.")
  print("  Reminders: |cffffffff/superbinds options|r")
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
  if not f then f = _G.SuperBindsMouseCatch end
  if f then
    pcall(function()
      f:EnableMouse(false)
      f:Hide()
    end)
    P.mouseCatch = f
  end
end

P.MOUSE_MACRO = {
}

P.MACRO_SHORT_BY_LABEL = {
}

function P.NamedMacroCommand(short)
  if not P.Text(short) then return nil end
  local actual = (SuperBindsDB.macroNames or {})[short] or ("SB_" .. short)
  local index = GetMacroIndexByName(actual)
  if (not index or index == 0) and actual ~= ("SB_" .. short) then
    actual = "SB_" .. short
    index = GetMacroIndexByName(actual)
  end
  if index and index > 0 then return "MACRO " .. actual, actual end
end

-- MACRO/SPELL currently sitting on this relative column (live abs slot).
-- Wheel fallback when the client rejects ACTIONBUTTON on MOUSEWHEEL*.
function P.SlotContentCommand(rel)
  if not P.ID(rel) then return nil end
  local named = P.MOUSE_MACRO[rel] and P.NamedMacroCommand(P.MOUSE_MACRO[rel])
  if named then return named end
  local abs = (P.LiveActionSlot and P.LiveActionSlot(rel)) or rel
  local ok, kind, id = pcall(GetActionInfo, abs)
  if not ok or not kind or (issecretvalue and issecretvalue(kind)) then return nil end
  if kind == "macro" then
    local name = GetMacroInfo(id)
    if P.Text(name) then return "MACRO " .. name end
    local spell = P.ID(id) and ((C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or SpellName(id))
    return P.Text(spell) and ("SPELL " .. spell) or nil
  end
  if kind == "spell" then
    local name = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or SpellName(id)
    return P.Text(name) and ("SPELL " .. name) or nil
  end
end

function P.ActionBindCommand(slot)
  if not P.ID(slot) then return nil end
  if slot >= 1 and slot <= 12 then return "ACTIONBUTTON" .. slot end
  return P.SlotContentCommand(slot)
end

function P.SpellBindCommand(spell)
  local name
  if type(spell) == "table" then
    name = Known(unpack(spell))
  elseif type(spell) == "number" then
    name = Known(spell)
  else
    name = Known(spell) or spell
  end
  return P.Text(name) and ("SPELL " .. name) or nil
end

function P.MouseKeyCommand(key)
  local spec = MOUSE_HARDWARE[key]
  if not spec then return nil end
  -- Shapeshifts are the same spell on every page. Skyriding empties those
  -- columns (Aerial Halt is not a form) so wheel must CAST the form, not
  -- ACTIONBUTTON on the live skyriding slot.
  local formCmd = P.FormBindCommand and P.FormBindCommand(key)
  if formCmd then return formCmd end
  -- E/Q/C follow the skyriding columns. Thorn and other wheel chords stay pack faces.
  if P.UseMountBar and P.UseMountBar() then
    local rel = tonumber(spec.slot)
    if rel ~= 1 and rel ~= 2 and rel ~= 7 then
      local packCmd = P.PackFaceCommand and P.PackFaceCommand(key)
      if packCmd then return packCmd end
    end
  end
  -- Stance page supplies the spell. Wheel/M4/M5 that own a column bind that
  -- column, not a form-static SPELL name (Thorn Bloom vs the @cursor macro).
  if P.ID(spec.slot) and spec.slot >= 1 and spec.slot <= 12 then
    return "ACTIONBUTTON" .. spec.slot
  end
  if spec.macro then
    local cmd = P.NamedMacroCommand(spec.macro)
    if cmd then return cmd end
  end
  if spec.spell then
    return P.SpellBindCommand(spec.spell)
  end
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

function P.MouseBindClaimed(key)
  if not P.IsMouseKey(key) then return false end
  for _, saved in pairs(SuperBindsDB.binds or {}) do
    if saved == key then return true end
  end
  for _, saved in pairs(SuperBindsDB.barBinds or {}) do
    if saved == key then return true end
  end
  return false
end

-- Left click = this face. MMB/M4/M5 = hardware extras unless BIND claimed that
-- mouse key for another icon. Claimed keys must not also UseAction(Dash slot).
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
    if not P.IsCameraBinding(key) and not P.MouseBindClaimed(key) then
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

-- Drop form before UseAction when the pack marks an ability as actionOverride.
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
  -- Faces own 1-12 (M5=8, R=9, M4=10). Helpers park on 13-24 only.
  local slot
  local taken = {}
  for _, spec in pairs(MOUSE_HARDWARE) do
    if P.ID(spec.slot) and spec.slot >= 1 and spec.slot <= 12 then
      taken[spec.slot] = true
    end
  end
  for candidate = 13, 24 do
    if not taken[candidate] then
      local kind, id = GetActionInfo(candidate)
      local owned = SuperBindsDB.hiddenSlots[candidate]
      local macroName = kind == "macro" and GetMacroInfo(id)
      local free = not kind or (owned and macroName == owned
        and SuperBindsDB.macroNames["SB" .. candidate] == owned)
      if not KEEP[candidate] and free then
        slot = candidate
        break
      end
    end
  end
  -- Full bars are normal. A saved macro can be addressed without an action slot.
  hiddenSlotN = hiddenSlotN + 1
  if slot then KEEP[slot] = true end
  local name = slot and ("SuperBindsAction_" .. slot) or ("SuperBindsMacro_" .. hiddenSlotN)
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
}

local function IsGroundName(name)
  if not name or name == "" then return false end
  if GROUND_EXCEPTIONS[name] then return true end
  local pack = P.CurrentPack and P.CurrentPack()
  local ground = pack and pack.ground
  if type(ground) == "table" and (ground[name] or (function()
    for _, n in ipairs(ground) do if n == name then return true end end
  end)()) then return true end
  return false
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
  local t = SuperBindsDB.custom and SuperBindsDB.custom.T
  if t and t.primary then return t.primary end
  return nil
end

local function MMBNomodName()
  local a = TPrimaryAbility()
  return a and (a.name or a.label)
end

local function NomodActionLine(ability)
  if not ability then return nil end
  if ability.macrotext then
    return FirstActionLine(ability.macrotext)
  end
  if ability.itemID then
    return "/use item:" .. ability.itemID
  end
  local name = ability.name or ability.label
  if not name then return nil end
  if AbilityCastStyle(ability) == "cursor" or IsGroundName(name) then
    return "/cast [@cursor] " .. name
  end
  return "/cast " .. name
end

-- Slot 5 chord is pack-opt-in (chordSlot5). Wheel stays camera unless BIND claimed it.
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
  local pack = P.CurrentPack and P.CurrentPack()
  if pack and pack.chordSlot5 ~= true then return end
  local ability = TPrimaryAbility()
  if not ability or Locked() then return end
  if ability.sba then
    local id = (C_AssistedCombat and C_AssistedCombat.GetActionSpell and C_AssistedCombat.GetActionSpell()) or SBA_ID
    PlaceID(5, id)
    HardenActionButton5()
    return
  end
  local name = ability.name or ability.label
  local nomod = FirstActionLine(ability.macrotext) or NomodActionLine(ability)
  local body = "#showtooltip " .. name .. "\n" .. nomod
  PlaceMacro(5, P.MOUSE_MACRO[5] or "RushTotem", ability.icon or 538576, body, name)
  HardenActionButton5()
end

local function SanitizeSavedBinds()
  P.EnsureDB()
  P.PruneOrphanSBMacros()
  -- Empty string means "no saved key", not an explicit unbind. The 0.5.75
  -- ACTIONBUTTON wipe stored "" for R and then RebindAll never restored it.
  local function dropEmpty(t)
    if type(t) ~= "table" then return end
    for k, v in pairs(t) do
      if v == "" then t[k] = nil end
    end
  end
  dropEmpty(SuperBindsDB.binds)
  dropEmpty(SuperBindsDB.barBinds)
  if P.CurrentPack and P.CurrentPack() then return end
  if SuperBindsDB.binds then SuperBindsDB.binds["key:CTRL-Q"] = nil end
  if SuperBindsDB.mods then SuperBindsDB.mods["CTRL-Q"] = nil end
  -- Ground family left MMB for Shift/Ctrl+wheel. Drop stale keys so apply
  -- uses the new defaults instead of restoring BUTTON3.
  do
    local b = SuperBindsDB.binds
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
    local bb = SuperBindsDB.barBinds
    if bb then
      local k = bb["ACTIONBUTTON5"]
      if k == "BUTTON3" or k == "T" then bb["ACTIONBUTTON5"] = nil end
    end
    local mods = SuperBindsDB.mods
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
}

local UNBIND = {
}

-- Pack macros live in profile files. Engine keeps no class bodies.

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

function P.AssistedActionID()
  local id
  pcall(function()
    if C_AssistedCombat and C_AssistedCombat.GetActionSpell then
      id = C_AssistedCombat.GetActionSpell()
    end
  end)
  return P.ID(id) or SBA_ID
end

function P.IsAssistedToken(v)
  if v == true then return true end
  if issecretvalue and issecretvalue(v) then return false end
  if type(v) == "string" then
    local s = v:lower()
    if s == "assistedcombat" or s == "assisted combat" or s == "assisted rotation"
      or s == "single-button assistant" or s == "sba" then
      return true
    end
    if s:find("assisted", 1, true) then return true end
  end
  local id = P.ID(v)
  return id == SBA_ID
end

function P.AssistedAbility()
  local id = P.AssistedActionID()
  return {
    kind = "sba", sba = true, id = id,
    name = "Assisted Rotation", label = "Assisted Rotation",
    icon = SpellIcon(id) or SpellIcon(SBA_ID) or 134400,
  }
end

function P.ActionIsAssisted(slot)
  slot = P.ID(slot)
  if not slot then return false end
  if P.FlagFn and P.FlagFn(function()
    return C_ActionBar and C_ActionBar.IsAssistedCombatAction
      and C_ActionBar.IsAssistedCombatAction(slot)
  end) then
    return true
  end
  local kind, id, sub
  pcall(function() kind, id, sub = GetActionInfo(slot) end)
  if P.IsAssistedToken(kind) or P.IsAssistedToken(id) or P.IsAssistedToken(sub) then
    return true
  end
  return P.IsAssistedAbility(id)
end

function P.CursorIsAssisted()
  local ok, ctype, a, b, spellID, extra = pcall(GetCursorInfo)
  if not ok then return false end
  local function pub(v)
    if v == nil then return nil end
    if issecretvalue and issecretvalue(v) then return nil end
    return v
  end
  if P.IsAssistedToken(pub(ctype)) or P.IsAssistedToken(pub(a)) or P.IsAssistedToken(pub(b))
    or P.IsAssistedToken(pub(spellID)) or P.IsAssistedToken(pub(extra)) then
    return true
  end
  local cur = P.ID(pub(spellID)) or P.ID(pub(a))
  if cur and (cur == SBA_ID or cur == P.AssistedActionID()) then return true end
  local info
  pcall(function()
    if C_Spell and C_Spell.GetSpellInfo then
      info = C_Spell.GetSpellInfo(spellID or a)
    end
  end)
  if type(info) == "table" and (P.IsAssistedToken(P.Text(info.name)) or P.IsAssistedToken(info.name)) then
    return true
  end
  local want = P.AssistedActionID()
  local tex, wantTex
  pcall(function()
    if C_Spell and C_Spell.GetSpellTexture then
      tex = C_Spell.GetSpellTexture(spellID or a)
      wantTex = C_Spell.GetSpellTexture(want)
    end
  end)
  tex, wantTex = P.Public(tex), P.Public(wantTex)
  if tex and wantTex and tex == wantTex then return true end
  return false
end

function P.IsAssistedAbility(ab, name)
  if ab == true then return true end
  local id, nm
  if type(ab) == "table" then
    if ab.sba == true or P.IsAssistedToken(ab.kind) then return true end
    id = ab.id
    nm = P.Text(ab.name) or P.Text(ab.label)
  elseif type(ab) == "number" or type(ab) == "string" then
    id = ab
    nm = P.Text(name)
  else
    nm = P.Text(ab) or P.Text(name)
  end
  if P.IsAssistedToken(id) or P.IsAssistedToken(nm) then return true end
  id = P.ID(id)
  if not id then return false end
  if id == SBA_ID then return true end
  local actionID = P.AssistedActionID()
  return actionID and id == actionID
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
  local sba = ab.sba == true or P.IsAssistedAbility({ id = id, name = ab.name, label = ab.label, sba = ab.sba })
  if sba then id = id or SBA_ID end
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
  db = db or SuperBindsDB
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
  if type(SuperBindsDB) ~= "table" then SuperBindsDB = {} end
  local db = SuperBindsDB
  for _, key in ipairs({"custom", "binds", "barBinds", "formBinds", "mods", "pos", "profiles", "macroNames", "hiddenSlots"}) do
    if type(db[key]) ~= "table" then db[key] = {} end
  end
  for _, field in ipairs({"binds", "barBinds", "macroNames"}) do
    for k, v in pairs(db[field]) do
      if type(k) ~= "string" or type(v) ~= "string" then db[field][k] = nil end
    end
  end
  if type(db.formBinds) ~= "table" then db.formBinds = {} end
  for form, keys in pairs(db.formBinds) do
    if not P.Text(form) or type(keys) ~= "table" then
      db.formBinds[form] = nil
    else
      for id, key in pairs(keys) do
        if not P.Text(id) or not P.Text(key) then keys[id] = nil end
      end
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
      custom.primary = (type(custom.primary) == "table" and custom.primary.empty)
        and { empty = true, kind = "empty", name = "", label = "", icon = 134400 }
        or NormalizeAbility(custom.primary)
      if type(custom.formPrimary) == "table" then
        for form, ab in pairs(custom.formPrimary) do
          custom.formPrimary[form] = P.Text(form) and (
            (type(ab) == "table" and ab.empty)
              and { empty = true, kind = "empty", name = "", label = "", icon = 134400 }
              or NormalizeAbility(ab)
          ) or nil
        end
      else
        custom.formPrimary = nil
      end
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
      if type(custom.addedForms) ~= "table" then custom.addedForms = {} end
      for form, list in pairs(custom.addedForms) do
        if not P.Text(form) or type(list) ~= "table" then
          custom.addedForms[form] = nil
        else
          local kept, idx = {}, {}
          for k in pairs(list) do if P.ID(k) then idx[#idx + 1] = k end end
          table.sort(idx)
          for _, k in ipairs(idx) do
            local a = NormalizeAbility(list[k])
            if a then kept[#kept + 1] = a end
          end
          custom.addedForms[form] = kept
        end
      end
      if custom.addedPerForm ~= true then custom.addedPerForm = custom.addedPerForm == true end
      if type(custom.hiddenForms) ~= "table" then custom.hiddenForms = {} end
      for form, keys in pairs(custom.hiddenForms) do
        if not P.Text(form) or type(keys) ~= "table" then
          custom.hiddenForms[form] = nil
        else
          for k, v in pairs(keys) do
            if not P.Text(k) or v ~= true then keys[k] = nil end
          end
        end
      end
      if custom.order ~= nil then
        local order = {}
        if type(custom.order) == "table" then
          for _, n in ipairs(custom.order) do if P.Text(n) then order[#order + 1] = n end end
        end
        custom.order = order
      end
      if type(custom.orderForms) ~= "table" then custom.orderForms = {} end
      for form, order in pairs(custom.orderForms) do
        if not P.Text(form) or type(order) ~= "table" then
          custom.orderForms[form] = nil
        else
          local kept = {}
          for _, n in ipairs(order) do if P.Text(n) then kept[#kept + 1] = n end end
          custom.orderForms[form] = kept
        end
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
  if db.hideBar1 == nil then db.hideBar1 = true end
  db.hideBar1 = db.hideBar1 == true
  if db.hideConsoleMounted == nil then db.hideConsoleMounted = true end
  db.hideConsoleMounted = db.hideConsoleMounted ~= false
  if db.useMountBar == nil then db.useMountBar = true end
  db.useMountBar = db.useMountBar ~= false
  if db.hideAutoManaged == nil then db.hideAutoManaged = true end
  db.hideAutoManaged = db.hideAutoManaged ~= false
  if db.warnBinds == nil then db.warnBinds = true end
  db.warnBinds = db.warnBinds ~= false
  if db.showPressPulse == nil then db.showPressPulse = true end
  db.showPressPulse = db.showPressPulse ~= false
  if db.experimentalNBA == nil then db.experimentalNBA = false end
  db.experimentalNBA = db.experimentalNBA == true
  if db.experimentalNbaName == nil then db.experimentalNbaName = true end
  db.experimentalNbaName = db.experimentalNbaName == true
  db.nbaCollapsed = db.nbaCollapsed == true
  if db.pulseOpacityRev ~= 2 then
    local old = P.PublicNumber(db.pulseOpacity)
    if not old or old >= 0.99 then
      db.pulseOpacity = 0.2
    else
      db.pulseOpacity = 0.2 * old
    end
    db.pulseOpacityRev = 2
  end
  if not P.Number(db.pulseOpacity) then db.pulseOpacity = 0.2 end
  if db.pulseOpacity < 0.1 then db.pulseOpacity = 0.1 end
  if db.pulseOpacity > 1 then db.pulseOpacity = 1 end
  if not P.Number(db.pulseWindow) then db.pulseWindow = P.PULSE_WINDOW_DEFAULT or 0.75 end
  if db.pulseWindow < 0.1 then db.pulseWindow = 0.1 end
  if db.pulseWindow > 1.5 then db.pulseWindow = 1.5 end
  db.schemaVersion = 2
  P.ClaimTrinketKeys(db)
  if not P.Text(db.familyMode) then
    local pack = P.DefaultPack and P.DefaultPack()
    if pack then
      db.familyMode = pack.familyMode or pack.name
      db.familyRevision = 1
      if not P.Text(db.activeProfile) then db.activeProfile = pack.name end
    end
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
      local ground = IsGroundName(name)
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
  if P.IsEmptyPrimary and P.IsEmptyPrimary(ability) then return false end
  if ability.itemID then
    return PlaceMacro(slot, "SBBar" .. slot, ability.icon or 134400, "/use item:" .. ability.itemID)
  end
  if ability.sba or P.IsAssistedAbility(ability) then
    return P.PlaceAssisted(slot)
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
  local ov = SuperBindsDB.mods and SuperBindsDB.mods[item.bindKey]
  if not ov then return item end
  if ov.sba or P.IsAssistedAbility(ov) then
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
  SuperBindsDB.mods = SuperBindsDB.mods or {}
  SuperBindsDB.mods[bindKey] = NormalizeAbility(ability)
  if not quiet then
    local name = ability.name or ability.label
    print("|cff0070ddSuper Binds:|r " .. ShortKey(bindKey) .. " is now |cffffffff" .. (name or "?") .. "|r")
  end
  return true
end

function P.FormBindFor(bindId, form)
  bindId = P.Text(bindId)
  if not bindId then return nil end
  local by = SuperBindsDB.formBinds
  if type(by) ~= "table" then return nil end
  local function at(name)
    name = P.Text(name)
    if not name or type(by[name]) ~= "table" then return nil end
    local key = by[name][bindId]
    if key == "" then return nil end
    return P.Text(key)
  end
  return at(form)
    or at(P.PackFormNow and P.PackFormNow())
    or at(P.DrawerForm and P.DrawerForm())
    or at(P.BonusBarForm and P.BonusBarForm())
end

local function EffectiveKey(bindId, defaultKey)
  if tostring(bindId or ""):match("^bar:") and P.FormBindFor then
    local formKey = P.FormBindFor(bindId)
    if formKey then return formKey end
  end
  local saved = SuperBindsDB.binds and SuperBindsDB.binds[bindId]
  if saved == "" then return nil end
  if saved then return saved end
  return defaultKey
end

local function EnsureClickButton(bindId)
  local token = bindId:gsub(".", function(c) return string.format("%02x", string.byte(c)) end)
  local name = "SuperBindsKey_" .. token
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

-- SPELL / MACRO / ITEM only: one icon should keep one hotkey after BIND.
-- Do not wipe ACTIONBUTTON or CLICK — those slots can share chords.
function P.ExclusiveBindCommand(command)
  if not P.Text(command) then return nil end
  if command:find("^SPELL ", 1, true) or command:find("^MACRO ", 1, true)
    or command:find("^ITEM ", 1, true) then
    return command
  end
end

function P.AbilityBindCommands(frame, command)
  local out, seen = {}, {}
  local function add(cmd)
    cmd = P.ExclusiveBindCommand(cmd)
    if cmd and not seen[cmd] then
      seen[cmd] = true
      out[#out + 1] = cmd
    end
  end
  add(command)
  add(P.PaintedSpellCommand and P.PaintedSpellCommand(frame))
  local ab = frame and frame._ability
  if type(ab) == "table" then
    local name = P.Text(ab.name) or P.Text(ab.label)
    if name then add("SPELL " .. name) end
    if P.Text(ab.savedMacroName) and P.NamedMacroCommand then
      add(P.NamedMacroCommand(ab.savedMacroName))
    end
  end
  return out
end

-- BIND / apply moved this icon. Drop leftover keys that still fire the same
-- spell (Ctrl-E after M5, talent defaults, a previous extra bindId).
function P.ReleaseStaleBindKeys(frame, bindId, keepKey, command)
  keepKey = P.Text(keepKey)
  local function drop(key)
    if not P.Text(key) or key == keepKey then return end
    pcall(SetBinding, key)
    if P.IsChatKey(key) then P.RestoreChatKeys() end
  end
  for _, cmd in ipairs(P.AbilityBindCommands(frame, command)) do
    for _, key in ipairs({GetBindingKey(cmd)}) do
      drop(key)
    end
  end
  local prev = SuperBindsDB.binds and SuperBindsDB.binds[bindId]
  if prev == "" then prev = nil end
  local default = frame and frame._sbDefaultKey
  local want = {}
  for _, cmd in ipairs(P.AbilityBindCommands(frame, command)) do
    want[cmd] = true
  end
  for _, key in ipairs({prev, default}) do
    if P.Text(key) and key ~= keepKey then
      local act = GetBindingAction(key)
      if want[act] then drop(key) end
    end
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
  local form = P.PackFormNow and P.PackFormNow()
  local fb = form and SuperBindsDB.formBinds and SuperBindsDB.formBinds[form]
  if type(fb) == "table" then
    for id, k in pairs(fb) do
      if k == key and id ~= bindId and tostring(id):find("^bar:", 1, true) then return true end
    end
  end
  for id, k in pairs(SuperBindsDB.binds or {}) do
    if k == key and id ~= bindId and tostring(id):find("^bar:") then return true end
  end
  for _, action in pairs(BAR_BINDS) do
    if type(action) == "string" and action:find("ACTIONBUTTON", 1, true) then
      if SuperBindsDB.barBinds and SuperBindsDB.barBinds[action] == key then return true end
    end
  end
end

local function KeyTaken(key, bindId)
  if not key then return false end
  if KeyOwnedByBar(key, bindId) then return true end
  for id, k in pairs(SuperBindsDB.binds or {}) do
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
      or (item.bindKey and SuperBindsDB.mods and SuperBindsDB.mods[item.bindKey]) then
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

function P.FirstBindingKey(command)
  if not P.Text(command) then return nil end
  local ok, a, b, c = pcall(GetBindingKey, command)
  if not ok then return nil end
  return P.Text(a) or P.Text(b) or P.Text(c)
end

function P.BarDefaultKey(slot, frame)
  if frame and P.Text(frame._sbDefaultKey) then return frame._sbDefaultKey end
  slot = tonumber(slot)
  if not slot then return nil end
  local action = "ACTIONBUTTON" .. slot
  for key, act in pairs(BAR_BINDS) do
    if act == action then return key end
  end
end

-- What the face actually fires. ACTIONBUTTON first (unified bar), then the
-- painted SPELL/MACRO leftover from BIND, then the pack column default.
-- An empty ACTIONBUTTON is not "Click".
function P.LiveFaceKey(frame)
  if not frame then return nil end
  local barSlot = P.BarSlotOf(frame)
  if barSlot then
    local formKey = P.FormBindFor and P.FormBindFor(frame._sbBindId or ("bar:" .. barSlot))
    if formKey then return formKey end
    local key = P.FirstBindingKey("ACTIONBUTTON" .. barSlot)
    if key then return key end
    local painted = P.PaintedSpellCommand and P.PaintedSpellCommand(frame)
    key = painted and P.FirstBindingKey(painted)
    if key then return key end
    return P.BarDefaultKey(barSlot, frame)
  end
  local saved = SuperBindsDB.binds and SuperBindsDB.binds[frame._sbBindId]
  if saved == "" then return nil end
  if P.Text(saved) then return saved end
  local key = P.FirstBindingKey(frame.commandName)
  if key then return key end
  local painted = P.PaintedSpellCommand and P.PaintedSpellCommand(frame)
  key = painted and P.FirstBindingKey(painted)
  if key then return key end
  if P.IsMouseKey(frame._sbDefaultKey) and P.MouseKeyCommand then
    local cmd = P.MouseKeyCommand(frame._sbDefaultKey)
    key = cmd and P.FirstBindingKey(cmd)
    if key then return key end
  end
  return P.Text(frame._sbDefaultKey)
end

local function RefreshBindLabels()
  local function refresh(frame)
    if not (frame._sbBindId and frame.keyText) then return end
    local saved = SuperBindsDB.binds and SuperBindsDB.binds[frame._sbBindId]
    local formKey = P.FormBindFor and P.FormBindFor(frame._sbBindId)
    -- Recover's "+" is a group mark, not a hotkey, unless BIND set one.
    if (frame.tipKey == "+" or frame.keyText:GetText() == "+")
      and not P.Text(saved) and not formKey then
      return
    end
    local key = formKey or EffectiveKey(frame._sbBindId, frame._sbDefaultKey) or P.LiveFaceKey(frame)
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
  local painted = P.PaintedSpellCommand(frame)
  if painted then return painted end
  local typ = frame._sbTypeSaved
  if typ == false then typ = nil end
  if typ == nil and frame.GetAttribute then typ = frame:GetAttribute("type") end
  local slot = P.BindActionSlot(frame)
  if P.ID(slot) then
    return P.ActionBindCommand(slot) or (slot <= 12 and ("ACTIONBUTTON" .. slot)) or nil
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
  if not P.Text(body) and P.Text(label) and IsGroundName(label) then
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
  local cmd = P.FormBindCommand and P.FormBindCommand(key)
  if ok(cmd) then return cmd end
  local hw = MOUSE_HARDWARE[key] or (frame._sbDefaultKey and MOUSE_HARDWARE[frame._sbDefaultKey])
  local slot = (hw and tonumber(hw.slot)) or P.BarSlotOf(frame)
  if P.UseMountBar and P.UseMountBar() and slot ~= 1 and slot ~= 2 and slot ~= 7 then
    cmd = P.PackFaceCommand and P.PackFaceCommand(key)
    if ok(cmd) then return cmd end
  end
  if P.ID(slot) and slot >= 1 and slot <= 12 then
    cmd = "ACTIONBUTTON" .. slot
    if ok(cmd) then return cmd end
  end
  if P.IsMouseKey(frame._sbDefaultKey) then
    cmd = P.MouseKeyCommand(frame._sbDefaultKey)
    if ok(cmd) then return cmd end
  end
  cmd = P.QkbMouseCommand(frame, key)
  if ok(cmd) then return cmd end
  cmd = P.AbilityMacroCommand(frame)
  if ok(cmd) then return cmd end
  slot = P.BindActionSlot(frame) or slot
  if P.ID(slot) then
    cmd = P.ActionBindCommand(slot) or (slot <= 12 and ("ACTIONBUTTON" .. slot)) or nil
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
  local d = CreateFrame("Frame", "SuperBindsModDriver", UIParent, "SecureHandlerStateTemplate")
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

function P.SyncFormKeyDriver()
  if Locked() then P.pendingFormKeys = true; return end
  local d = P.formKeyDriver
  if not d then
    d = CreateFrame("Frame", "SuperBindsFormKeys", UIParent, "SecureHandlerStateTemplate")
    P.formKeyDriver = d
    d:Hide()
    d:SetAttribute("_onstate-formkeys", [[
      self:ClearBindings()
      local form = newstate
      if not form or form == "" or form == "0" then return end
      for i = 1, 12 do
        local key = self:GetAttribute(form .. ":" .. i)
        if key and key ~= "" then
          self:SetBinding(true, key, "ACTIONBUTTON" .. i)
        end
      end
    ]])
  end
  local forms = { caster = true, cat = true, bear = true, moonkin = true, travel = true }
  local fb = SuperBindsDB.formBinds or {}
  for form in pairs(fb) do forms[form] = true end
  local pack = P.CurrentPack and P.CurrentPack()
  for name in pairs((pack and pack.actionBars) or {}) do forms[name] = true end
  for form in pairs(forms) do
    for i = 1, 12 do
      d:SetAttribute(form .. ":" .. i, nil)
    end
  end
  for form, keys in pairs(fb) do
    if type(keys) == "table" then
      for id, key in pairs(keys) do
        local slot = tonumber(tostring(id):match("^bar:(%d+)$"))
        if slot and P.Text(key) and not (P.IsMouseKey and P.IsMouseKey(key)) then
          d:SetAttribute(form .. ":" .. slot, key)
        end
      end
    end
  end
  local parts = {}
  for name, spec in pairs((pack and pack.actionBars) or {}) do
    if type(spec) == "table" and tonumber(spec.bonus) and tonumber(spec.bonus) > 0
      and not P.Text(spec.use) then
      parts[#parts + 1] = string.format("[bonusbar:%d] %s", spec.bonus, name)
    end
  end
  parts[#parts + 1] = "caster"
  local cond = table.concat(parts, ";")
  if P._formKeyCond ~= cond then
    pcall(RegisterStateDriver, d, "formkeys", cond)
    P._formKeyCond = cond
  end
  local form = (P.PackFormNow and P.PackFormNow()) or "caster"
  local cur = d:GetAttribute("state-formkeys")
  if cur == form then
    d:SetAttribute("state-formkeys", "")
  end
  d:SetAttribute("state-formkeys", form)
  P.pendingFormKeys = nil
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
  if P.ResolveBarBind then
    local bid, cmd = P.ResolveBarBind(frame, key)
    if P.Text(bid) then bindId = bid end
    if P.Text(cmd) then command = cmd end
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
  local oldBinds = P.CopyData(SuperBindsDB.binds)
  local oldBarBinds = P.CopyData(SuperBindsDB.barBinds)
  local oldFormBinds = P.CopyData(SuperBindsDB.formBinds)
  local slot = bindId:match("^bar:(%d+)$")
  local formNow = (slot and not mouseKey and P.PackFormNow and P.Text(P.PackFormNow())) or nil
  local ok, err = pcall(function()
    if formNow and slot then
      -- Column keys are per stance. Do not rewrite ACTIONBUTTON for every form.
      SuperBindsDB.formBinds = SuperBindsDB.formBinds or {}
      SuperBindsDB.formBinds[formNow] = SuperBindsDB.formBinds[formNow] or {}
      if key ~= "" then
        local act = GetBindingAction(key)
        if type(act) == "string" and act:find("^ACTIONBUTTON", 1, true) then
          pcall(SetBinding, key)
        end
      end
      local packDefault = P.BarDefaultKey(tonumber(slot), frame)
      local action = "ACTIONBUTTON" .. slot
      if packDefault then
        if GetBindingAction(packDefault) ~= action then
          pcall(SetBinding, packDefault, action)
        end
        SuperBindsDB.barBinds[action] = packDefault
      end
      SuperBindsDB.binds[bindId] = nil
      if key == "" or (packDefault and key == packDefault) then
        SuperBindsDB.formBinds[formNow][bindId] = nil
      else
        SuperBindsDB.formBinds[formNow][bindId] = key
      end
      for id, k in pairs(SuperBindsDB.formBinds[formNow]) do
        if key ~= "" and k == key and id ~= bindId then
          SuperBindsDB.formBinds[formNow][id] = nil
        end
      end
      if P.SyncFormKeyDriver then P.SyncFormKeyDriver() end
    else
      -- SetBinding already steals `key`. Clearing an ACTIONBUTTON command first
      -- wipes every other key on that slot — Shift-WheelUp on ACTIONBUTTON5.
      if not mouseKey then ClearCommandKeys(command) end
      P.ReleaseStaleBindKeys(frame, bindId, key, command)
      if key ~= "" and not SetBinding(key, command) then error("WoW rejected key " .. key) end
      for id, saved in pairs(SuperBindsDB.binds) do
        if key ~= "" and saved == key and id ~= bindId then SuperBindsDB.binds[id] = "" end
      end
      for action, saved in pairs(SuperBindsDB.barBinds) do
        if key ~= "" and saved == key and action ~= command then SuperBindsDB.barBinds[action] = "" end
      end
      for _, other in ipairs(P.BindFrames()) do
        if other._sbBindId ~= bindId and key ~= "" and EffectiveKey(other._sbBindId, other._sbDefaultKey) == key then
          SuperBindsDB.binds[other._sbBindId] = ""
          if other._sbBindId:match("^bar:") then SuperBindsDB.barBinds[other.commandName] = "" end
        end
      end
      SuperBindsDB.binds[bindId] = key
      if bindId:match("^bar:") then
        local barSlot = bindId:match("^bar:(%d+)$")
        local barCmd = barSlot and ("ACTIONBUTTON" .. barSlot) or command
        SuperBindsDB.barBinds[barCmd] = key
      end
    end
    if SaveBindings(GetCurrentBindingSet()) == false then error("WoW could not save bindings.") end
  end)
  if not ok then
    SuperBindsDB.binds, SuperBindsDB.barBinds, SuperBindsDB.formBinds = oldBinds, oldBarBinds, oldFormBinds
    ClearCommandKeys(command)
    for _, oldKey in ipairs(oldKeys) do SetBinding(oldKey, command) end
    if key ~= "" and oldCommand and oldCommand ~= "" then SetBinding(key, oldCommand) end
    P.Report(err)
  end
  busy = false
  if ok and frame.keyText and P.Text(key) then
    local painted = ShortKey(key) or PrettyKey(key) or key
    frame.keyText:SetText(painted)
    frame.tipKey = painted
  end
  RefreshBindLabels()
  if ok then
    local label = (frame._ability and (frame._ability.label or frame._ability.name)) or frame.tipText
    local form = (P.DrawerForm and P.DrawerForm()) or formNow or (P.PackFormNow and P.PackFormNow())
    if P.Text(label) then
      local dest = P.Text(key) and (PrettyKey(key) or key) or "unbound"
      P.Report(label .. (P.Text(form) and (" " .. form) or "") .. " → " .. dest)
    end
    P.ExplainStolenBind(key, label, oldCommand)
    if P.IsMouseKey(key) and not Locked() then
      P.RebuildOverrideList()
      P.FlushOverrides()
      if P.ArmAllHardwareClicks then P.ArmAllHardwareClicks() end
      RefreshBindLabels()
    end
    if P._bindPromoted then
      P._bindPromoted = nil
      if RefreshLayout then RefreshLayout(true) end
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
    -- Hidden extras must still own a stolen mouse/wheel override.
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
      local saved = SuperBindsDB.binds[id]
      if saved == "" then saved = nil end
      if id:match("^bar:") then
        local slot = id:match("^bar:(%d+)$")
        if P.IsMouseKey(frame._sbDefaultKey) then
          if saved == nil then
            saved = (SuperBindsDB.barBinds or {})["ACTIONBUTTON" .. slot]
            if saved == "" then saved = nil end
          end
        else
          -- Keyboard columns keep the pack default. Per-form keys are overlays.
          saved = nil
        end
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
  P.BindPackBarKeys()
  if P.SyncFormKeyDriver then P.SyncFormKeyDriver() end
  -- Apply / reload must not keep a previous BIND's SPELL key (Ctrl-E) after
  -- the icon's saved hotkey moved (M5).
  for _, frame in ipairs(frames) do
    local keep = EffectiveKey(frame._sbBindId, frame._sbDefaultKey)
    P.ReleaseStaleBindKeys(frame, frame._sbBindId, keep, frame.commandName)
  end
  P.RestoreChatKeys()
  RefreshBindLabels()
end

local function SetQKBHighlights(on)
  for _, tab in pairs(consoleTabs) do
    if tab._qkbHL then tab._qkbHL:SetShown(on and tab._sbBindId) end
  end
  for _, b in ipairs(allMenuButtons) do
    if b._qkbHL then
      local menu = b.GetParent and b:GetParent()
      local wash = menu and menu._sbBindCompact
      b._qkbHL:SetShown(on and b:IsShown() and b._sbBindId and not wash)
    end
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

-- Hover drawers pin to their tab. BIND opens every non-empty drawer as a
-- one-line column. Two rows, each packed into non-overlapping slots so
-- neighbors cannot cover each other.
function P.LayoutBindMenus(on)
  if Locked() or not console then return end
  local gapPx = P.GAP or 5
  local function shownButtons(menu)
    local list = {}
    for _, b in ipairs(menu.buttons or {}) do
      if b:IsShown() then list[#list + 1] = b end
    end
    return list
  end
  local function textW(fs)
    if not fs then return 0 end
    local t = fs.GetText and fs:GetText()
    if not t or t == "" then return 0 end
    local prev = fs.GetWidth and fs:GetWidth()
    if fs.SetWidth then fs:SetWidth(360) end
    local w = fs.GetStringWidth and fs:GetStringWidth() or 0
    if prev and fs.SetWidth then fs:SetWidth(prev) end
    return w
  end
  local function restore(menu)
    if not menu or not menu._sbBindCompact then return end
    menu._sbBindCompact = nil
    local list = shownButtons(menu)
    local n = #list
    local cols = (n > 7) and 2 or 1
    local pad, header = P.Visual.menuPad, P.Visual.menuHeader
    local rowW, rowH = P.Visual.rowWidth, P.Visual.rowHeight
    for i, b in ipairs(list) do
      local col = (i - 1) % cols
      local row = math.floor((i - 1) / cols)
      b:SetSize(rowW, rowH)
      b:ClearAllPoints()
      b:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT",
        pad + col * (rowW + gapPx), pad + row * (rowH + gapPx))
      if b.icon then
        b.icon:ClearAllPoints()
        b.icon:SetPoint("LEFT", 5, 0)
        b.icon:SetSize(36, 36)
      end
      if b._sbVisualLabel then
        b._sbVisualLabel:ClearAllPoints()
        b._sbVisualLabel:SetPoint("TOPLEFT", 50, -8)
        b._sbVisualLabel:SetWidth(rowW - 60)
        b._sbVisualLabel:SetHeight(15)
        P.VisualFont(b._sbVisualLabel, 11, P.Visual.text)
      end
      if b.keyText then
        b.keyText:ClearAllPoints()
        b.keyText:SetPoint("BOTTOMLEFT", 50, 7)
        b.keyText:SetWidth(150)
        if b.keyText.SetJustifyH then b.keyText:SetJustifyH("LEFT") end
        P.VisualFont(b.keyText, 10, P.Visual.teal)
      end
    end
    if menu._sbVisualTitle then
      menu._sbVisualTitle:ClearAllPoints()
      menu._sbVisualTitle:SetPoint("TOPLEFT", 12, -11)
    end
    if menu._sbVisualCount then menu._sbVisualCount:Show() end
    if menu._sbVisualRule then menu._sbVisualRule:Show() end
    if n == 0 then
      menu:SetSize(1, 1)
      menu._sbW, menu._sbH = 1, 1
      return
    end
    local colsUsed = math.min(n, cols)
    local rows = math.ceil(n / cols)
    local mw = pad * 2 + colsUsed * rowW + (colsUsed - 1) * gapPx
    local mh = pad * 2 + rows * rowH + (rows - 1) * gapPx + header
    menu:SetSize(mw, mh)
    menu._sbW, menu._sbH = mw, mh
  end
  local function compact(menu, maxW)
    local list = shownButtons(menu)
    local n = #list
    if n == 0 then
      menu:Hide()
      menu:SetSize(1, 1)
      menu._sbW, menu._sbH = 1, 1
      return
    end
    local nameW, keyW = 40, 28
    for _, b in ipairs(list) do
      nameW = math.max(nameW, textW(b._sbVisualLabel))
      keyW = math.max(keyW, textW(b.keyText))
    end
    if menu._sbVisualTitle then
      nameW = math.max(nameW, (textW(menu._sbVisualTitle) or 0) - 10)
    end
    local cap = 196
    local pad, rowH, header, gap = 4, 20, 16, 1
    local rowW = math.floor(22 + nameW + 6 + keyW + 6)
    if rowW < 96 then rowW = 96 end
    if rowW > cap then
      rowW = cap
      nameW = cap - 22 - 6 - keyW - 6
      if nameW < 36 then nameW = 36 end
    end
    if maxW then
      local inner = math.floor(maxW - pad * 2)
      if inner < 80 then inner = 80 end
      if rowW > inner then
        rowW = inner
        nameW = rowW - 22 - 6 - keyW - 6
        if nameW < 28 then nameW = 28 end
      end
    end
    for i, b in ipairs(list) do
      b:SetSize(rowW, rowH)
      b:ClearAllPoints()
      b:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", pad, pad + (i - 1) * (rowH + gap))
      if b.icon then
        b.icon:ClearAllPoints()
        b.icon:SetPoint("LEFT", 3, 0)
        b.icon:SetSize(16, 16)
      end
      if b._sbVisualLabel then
        b._sbVisualLabel:ClearAllPoints()
        b._sbVisualLabel:SetPoint("LEFT", 22, 0)
        b._sbVisualLabel:SetWidth(nameW)
        b._sbVisualLabel:SetHeight(16)
        P.VisualFont(b._sbVisualLabel, 10, P.Visual.text)
      end
      if b.keyText then
        b.keyText:ClearAllPoints()
        b.keyText:SetPoint("RIGHT", -4, 0)
        b.keyText:SetWidth(keyW)
        b.keyText:SetJustifyH("RIGHT")
        P.VisualFont(b.keyText, 9, P.Visual.teal)
      end
      if b._sbClickHint then b._sbClickHint:Hide() end
    end
    if menu._sbVisualTitle then
      menu._sbVisualTitle:ClearAllPoints()
      menu._sbVisualTitle:SetPoint("TOPLEFT", 6, -4)
      menu._sbVisualTitle:SetWidth(rowW - 8)
    end
    if menu._sbVisualCount then menu._sbVisualCount:Hide() end
    if menu._sbVisualRule then menu._sbVisualRule:Hide() end
    local mw = pad * 2 + rowW
    local mh = pad * 2 + n * rowH + (n - 1) * gap + header
    menu:SetSize(mw, mh)
    menu._sbW, menu._sbH = mw, mh
    menu._sbBindCompact = true
  end
  if not on then
    P._sbBindBoardTop = nil
    for i, menu in pairs(menus) do
      restore(menu)
      local tab = consoleTabs[i]
      if menu and tab then
        menu:ClearAllPoints()
        menu:SetPoint("BOTTOM", tab, "TOP", 0, -1)
      end
    end
    return
  end
  local pitch = (P.TAB_W or 48) + (P.TAB_GAP or 6)
  local tabW = P.TAB_W or 48
  local nTabs = 0
  for i = 1, 24 do
    if consoleTabs[i] then nTabs = i end
  end
  local stripW = (nTabs > 0) and ((nTabs - 1) * pitch + tabW) or (11 * pitch)
  local placed = {}
  for i = 1, nTabs do
    local menu, tab = menus[i], consoleTabs[i]
    if menu and tab and tab:IsShown() then
      compact(menu)
      if menu._sbW and menu._sbW > 8 then
        local cx = (i - 1) * pitch + tabW / 2
        local t0 = consoleTabs[1]
        local origin = t0 and t0.GetLeft and t0:GetLeft()
        local left = tab.GetLeft and tab:GetLeft()
        if origin and left then
          cx = left - origin + (tab:GetWidth() or tabW) / 2
        end
        placed[#placed + 1] = {
          i = i, menu = menu, tab = tab,
          w = menu._sbW, h = menu._sbH, cx = cx,
        }
      else
        menu:Hide()
      end
    end
  end
  local low, high = {}, {}
  for _, it in ipairs(placed) do
    if it.i % 2 == 0 then
      low[#low + 1] = it
    else
      high[#high + 1] = it
    end
  end
  local function layoutRow(list, lift)
    local n = #list
    if n == 0 then return lift end
    local col = stripW / n
    local slot = math.floor(col - 4)
    if slot < 72 then slot = 72 end
    if slot > col - 2 then slot = math.floor(col - 2) end
    if slot < 64 then slot = math.max(64, math.floor(col - 2)) end
    for i, it in ipairs(list) do
      compact(it.menu, slot)
      it.w = it.menu._sbW or slot
      it.h = it.menu._sbH or it.h
      local w = it.w
      local x = it.cx
      local half = w / 2
      local left = (i - 1) * col
      local right = i * col
      if x - half < left + 1 then x = left + 1 + half end
      if x + half > right - 1 then x = right - 1 - half end
      it.x = x
      it.menu:Show()
      it.menu:ClearAllPoints()
      it.menu:SetPoint("BOTTOM", it.tab, "TOP", x - it.cx, lift)
      local lvl = (it.tab.GetFrameLevel and it.tab:GetFrameLevel()) or 10
      it.menu:SetFrameLevel(lvl + 8 + it.i)
    end
    local rowH = 0
    for _, it in ipairs(list) do
      if it.h > rowH then rowH = it.h end
    end
    return lift + rowH + 6
  end
  local top = layoutRow(low, 2)
  top = layoutRow(high, top)
  P._sbBindBoardTop = top
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
  if event ~= "UPDATE_BINDINGS" or busy or P.rebindingMouse or not SuperBindsDB.applied then return end
  if P.bindingObserveQueued then return end
  P.bindingObserveQueued = true
  C_Timer.After(0, function()
    P.bindingObserveQueued = nil
    if busy then return end
    P.EnsureDB()
    for _, frame in ipairs(P.BindFrames()) do
      local saved = SuperBindsDB.binds[frame._sbBindId]
      if P.IsMouseKey(saved) then
        -- BIND's mouse/wheel choice is not on commandName. Do not overwrite it.
      elseif frame._sbBindId and tostring(frame._sbBindId):match("^bar:(%d+)$") then
        -- Keyboard column labels follow formBinds. Do not copy the live
        -- ACTIONBUTTON key into every stance.
      elseif not P.IsMouseKey(frame._sbDefaultKey) and not (frame._sbBindId and tostring(frame._sbBindId):find("BUTTON", 1, true))
        and not (frame._sbBindId and tostring(frame._sbBindId):find("WHEEL", 1, true))
        and not (frame._sbBindId and tostring(frame._sbBindId):match("^bar:")) then
      local key = GetBindingKey(frame.commandName) or ""
      SuperBindsDB.binds[frame._sbBindId] = key
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
  print("|cff0070ddSuper Binds:|r open |cffffffffESC → Options → Keybindings → Quick Keybind Mode|r, then hover a console icon and press a key.")
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
  return P.CurrentPack and P.CurrentPack() ~= nil
end

function P.RestoreCameraWheel()
  if Locked() then return end
  local claimed = {}
  local function claim(key)
    if type(key) == "string" and (key:find("MOUSEWHEEL", 1, true) or key:find("MWHEEL", 1, true)) then
      claimed[key] = true
    end
  end
  for _, store in ipairs({ SuperBindsDB.binds, SuperBindsDB.barBinds }) do
    if store then
      for k, v in pairs(store) do
        claim(v)
        claim(k)
      end
    end
  end
  local pack = P.CurrentPack and P.CurrentPack()
  if pack then
    for key in pairs(pack.hardware or {}) do claim(key) end
    for key in pairs(pack.barBinds or {}) do claim(key) end
  end
  for key in pairs(MOUSE_HARDWARE) do claim(key) end
  local want = (pack and pack.camera) or {
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
  local pack = P.CurrentPack and P.CurrentPack()
  wipe(MOUSE_HARDWARE)
  wipe(BAR_BINDS)
  wipe(HARDWARE_LABEL)
  wipe(STATIC_EXCLUDE)
  wipe(P.SPELL_ID)
  wipe(P.SPELL_ICON)
  wipe(P.MOUSE_MACRO)
  wipe(P.MACRO_SHORT_BY_LABEL)
  wipe(GROUND_EXCEPTIONS)
  P.TOTEM_READY = {}
  if type(pack) ~= "table" then return end
  for k, v in pairs(pack.hardware or {}) do MOUSE_HARDWARE[k] = v end
  for k, v in pairs(pack.barBinds or {}) do BAR_BINDS[k] = v end
  for k, v in pairs(pack.reserved or {}) do HARDWARE_LABEL[k] = v end
  local hwlab = pack.hardwareLabel
  if type(hwlab) == "table" then for k, v in pairs(hwlab) do HARDWARE_LABEL[k] = v end end
  for k, v in pairs(pack.exclude or {}) do STATIC_EXCLUDE[k] = v and true or nil end
  if type(pack.neverBind) == "table" then
    for _, n in ipairs(pack.neverBind) do if type(n) == "string" then STATIC_EXCLUDE[n] = true end end
  end
  for k, v in pairs(pack.spellIds or pack.SPELL_ID or {}) do P.SPELL_ID[k] = v end
  for k, v in pairs(pack.spellIcons or {}) do P.SPELL_ICON[k] = v end
  for k, v in pairs(pack.mouseMacro or {}) do P.MOUSE_MACRO[k] = v end
  for k, v in pairs(pack.macros or {}) do
    if type(v) == "table" and v.short then P.MACRO_SHORT_BY_LABEL[v.label or k] = v.short end
  end
  for k, v in pairs(pack.ground or {}) do
    if type(k) == "string" then GROUND_EXCEPTIONS[k] = v and true or nil
    elseif type(v) == "string" then GROUND_EXCEPTIONS[v] = true end
  end
  if type(pack.sculptures) == "table" then P.TOTEM_READY = pack.sculptures end
  if type(pack.theme) == "table" then
    local t = pack.theme
    P.ClassThemes.DEFAULT = {
      accent = t.accent or t.teal or {0.35, 0.65, 0.9, 1},
      metal = t.brass or t.metal or {0.65, 0.51, 0.28, 1},
      endcap = t.endcap or t.endcapLeft,
      endcapW = t.endcapWidth or t.endcapW or 70,
      endcapH = t.endcapHeight or t.endcapH or 120,
      endcapHorde = t.endcapHorde,
      endcapHordeW = t.endcapHordeWidth or t.endcapHordeW,
      endcapHordeH = t.endcapHordeHeight or t.endcapHordeH,
      endcaps = t.endcaps,
    }
    P.SelectClassTheme()
  end
  local vis = {}
  for _, fam in ipairs(pack.families or {}) do
    if fam.tag then vis[fam.tag] = fam.caption or fam.tag end
  end
  P.Visual.families = vis
  P.RestoreTotemWheelBinds()
end

local function PackFormNow()
  return P.PackFormNow and P.PackFormNow()
end

function P.EachBarSlot(barEntry, fn)
  if type(barEntry) ~= "table" or type(fn) ~= "function" then return end
  local rel = tonumber(barEntry.slot)
  if not rel then return end
  if barEntry.allBars then
    for _, formName in ipairs(P.UniqueBarForms()) do
      local abs = P.ActionSlot(rel, formName)
      if abs then fn(abs, formName) end
    end
    return
  end
  local formName = barEntry.form or PackFormNow()
  local abs = P.ActionSlot(rel, formName)
  if abs then fn(abs, formName) end
end

-- Write this family's primary onto the stance bar you are actually on.
-- Drops must not PlaceID every form — leftover cursor swaps shuffle the bar.
function P.PlaceFamilyPrimaryNow(tag, ability)
  if Locked() or not P.Text(tag) then return false end
  local spec = P.FamilyBarSpec and P.FamilyBarSpec(tag)
  local rel = spec and tonumber(spec.slot)
  -- Travel / skyriding have no own family bar row. Do not fall back to bear
  -- and PlaceID the live bonus page (flight E is Surge, not Mangle).
  if not rel then return false end
  local abs = (P.LiveActionSlot and P.LiveActionSlot(rel)) or P.ActionSlot(rel, PackFormNow())
  if not abs then return false end
  if P.IsEmptyPrimary and P.IsEmptyPrimary(ability) then
    pcall(ClearCursor)
    ClearSlot(abs)
    return true
  end
  if type(ability) == "table" then
    -- Live spellbook drop: PlaceAction the cursor you already have onto the
    -- bear/cat page. PickupSpell(SBA) is why E never took Assisted Combat.
    if P.CursorHasPickup and P.CursorHasPickup() then
      return P.PlaceCursorOnSlot(abs)
    end
    pcall(ClearCursor)
    return PlacePrimaryOnBar(abs, ability)
  end
  pcall(ClearCursor)
  if spec.sba then return P.PlaceAssisted(abs) end
  if spec.macro then
    return PlaceMacro(abs, spec.macro[1], spec.macro[2], spec.macro[3])
  end
  if type(spec.spell) == "table" then
    local _, id = Known(unpack(spec.spell))
    if id then return PlaceID(abs, id) end
  end
  return false
end

-- Stock every stance page for this family (caster + cat + bear + moonkin).
-- Restoring only PackFormNow() used to write page 1 and leave cat E as Attack.
function P.PlaceFamilyStockAllForms(tag)
  if Locked() or not P.Text(tag) then return false end
  local pack = P.CurrentPack and P.CurrentPack()
  local fam
  for _, f in ipairs((pack and pack.families) or {}) do
    if f.tag == tag then fam = f; break end
  end
  if not fam then return false end
  local placed = {}
  local function placeSpec(spec, formName)
    if type(spec) ~= "table" then return false end
    local rel = tonumber(spec.slot)
    if not rel then return false end
    local abs = P.ActionSlot(rel, formName)
    if not abs then return false end
    if placed[abs] then return false end
    placed[abs] = true
    pcall(ClearCursor)
    if spec.sba then return P.PlaceAssisted(abs) end
    if spec.macro then
      return PlaceMacro(abs, spec.macro[1], spec.macro[2], spec.macro[3])
    end
    if type(spec.spell) == "table" then
      local _, id = Known(unpack(spec.spell))
      if id then return PlaceID(abs, id) end
    end
    return false
  end
  local any = false
  if type(fam.bars) == "table" then
    for formName, spec in pairs(fam.bars) do
      if placeSpec(spec, formName) then any = true end
    end
  elseif fam.bar then
    if placeSpec(fam.bar, PackFormNow()) then any = true end
  end
  pcall(ClearCursor)
  return any
end

local function CopyItem(it)
  if type(it) ~= "table" then return it end
  local c = {}
  for k, v in pairs(it) do c[k] = v end
  return c
end

-- Drawer extras: no form = every stance. form="cat" or form={"cat","bear"}.
-- Flight / skyriding are Travel Form for extras; they must not match caster.
function P.ItemFormOk(it, form)
  local want = it and it.form
  if want == nil or want == false then return true end
  form = P.Text(form)
  if not form then return false end
  local function same(a, b)
    a, b = P.Text(a), P.Text(b)
    if not a or not b then return false end
    if a == b then return true end
    if (a == "travel" or a == "flight" or a == "skyriding")
      and (b == "travel" or b == "flight" or b == "skyriding") then
      return true
    end
    return false
  end
  local function hit(name)
    return same(name, form)
  end
  if type(want) == "string" then return hit(want) end
  if type(want) == "table" then
    for i = 1, #want do
      if hit(want[i]) then return true end
    end
  end
  return false
end

local function BuildFamilies()
  P.SelectFamilyHardware()
  local pack = P.CurrentPack and P.CurrentPack()
  if type(pack) ~= "table" or type(pack.families) ~= "table" then return {} end
  local barForm = PackFormNow()
  local extraForm = (P.DrawerForm and P.DrawerForm()) or barForm
  local families = {}
  for _, fam in ipairs(pack.families) do
    local f = {
      tag = fam.tag, title = fam.title, caption = fam.caption,
      autoFill = fam.autoFill, items = {},
    }
    if type(fam.bars) == "table" then
      f.bars = fam.bars
      f.bar = (barForm and fam.bars[barForm]) or fam.bar
      if not f.bar then
        for _, spec in pairs(fam.bars) do
          if type(spec) == "table" and tonumber(spec.slot) then
            f.bar = spec
            break
          end
        end
      end
    elseif fam.bar then
      f.bar = fam.bar
    end
    for _, it in ipairs(fam.items or {}) do
      if P.ItemFormOk(it, extraForm) then
        f.items[#f.items + 1] = CopyItem(it)
      end
    end
    families[#families + 1] = f
  end
  -- Skyriding Halt / Ascent belong on 1 and 2, not on Forms or Thorn.
  local sky = P.SkyridingExtraKeys and P.SkyridingExtraKeys() or {}
  if #sky > 0 then
    local at = #families
    for i, f in ipairs(families) do
      if f.tag == "C" then at = i break end
    end
    for j, row in ipairs(sky) do
      table.insert(families, at + j, {
        tag = "SKY" .. row.key,
        title = row.label .. " · " .. row.key,
        caption = row.key,
        items = {{
          skyriding = true, bindKey = row.key, key = row.key,
          label = row.label, name = row.name, id = row.id, iconFile = row.icon,
        }},
      })
    end
  end
  return families
end

function P.ClearFamilyKeys()
  -- Clear only commands belonging to our helpers, leaving unrelated bindings alone.
  local families=BuildFamilies()
  local keys={}
  for key in pairs(BAR_BINDS) do keys[key]=true end
  for _,family in ipairs(families) do for _,it in ipairs(family.items) do if it.bindKey then keys[it.bindKey]=true end end end
  for _,key in pairs(SuperBindsDB.binds or {}) do if key~="" then keys[key]=true end end
  for key in pairs(keys) do
    local cmd=GetBindingAction(key)
    if type(cmd)=="string" and (cmd:find("^CLICK SuperBinds") or cmd:find("^MACRO SB_")) then SetBinding(key) end
  end
  P.RestoreChatKeys()
end

function P.ActivatePurposeFamilies(force)
  return
end

local function SavePosition(key, frame)
  local point, _, relPoint, x, y = frame:GetPoint(1)
  SuperBindsDB.pos = SuperBindsDB.pos or {}
  SuperBindsDB.pos[key] = { point, relPoint, x, y }
end

local TAB_W, TAB_H = 48, 48
P.TAB_W, P.TAB_H = TAB_W, TAB_H
-- Empty width after the last tab, matching the :: grip on the left.
P.CONSOLE_END_PAD = 24
local TAB_GAP = 6
P.TAB_GAP = TAB_GAP
local BTN, GAP = 38, 5
P.GAP = GAP

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
  if cd.SetDrawSwipe then cd:SetDrawSwipe(true) end
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
  -- Shown face first. bar:N is a relative column; GetActionCooldown(1) is
  -- caster page-1, not cat/bear slot 73/97. SBA uses the live action slot so
  -- the GCD follows whatever Blizzard is actually firing.
  local ab = frame._ability
  if not (ab and P.IsAssistedAbility(ab)) then
    if P.ID(frame.spellID) then return "spell", frame.spellID end
    if ab then
      if P.ID(ab.itemID) then return "item", ab.itemID end
      local name, id = P.AbilitySpellIdentity(ab)
      if P.ID(id) then return "spell", id end
      if P.Text(name) then return "spellname", name end
    end
  end
  if frame.GetAttribute and frame:GetAttribute("type") == "action" then
    local abs = tonumber(frame:GetAttribute("action"))
    if P.ID(abs) then return "action", abs end
  end
  local rel = P.BarSlotOf(frame)
  if P.ID(rel) then
    local pack = P.CurrentPack and P.CurrentPack()
    if pack and pack.actionBars and P.ActionSlot then
      local abs = P.ActionSlot(rel, PackFormNow())
      if P.ID(abs) then return "action", abs end
    end
    return "action", rel
  end
  local inv = frame._sbEquipmentSlot or frame.equipmentSlot
  if P.ID(inv) then return "inv", inv end
  if P.ID(frame.itemID) then return "item", frame.itemID end
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

function P.ApplyDurationCooldown(cd, kind, id)
  if not cd or id == nil then return end
  pcall(function()
    local duration
    if kind == "action" and C_ActionBar and C_ActionBar.GetActionCooldownDuration then
      duration = C_ActionBar.GetActionCooldownDuration(id)
    elseif kind == "inv" and GetInventoryItemCooldownDuration then
      duration = GetInventoryItemCooldownDuration("player", id)
    elseif kind == "item" and C_Container and C_Container.GetItemCooldownDuration then
      duration = C_Container.GetItemCooldownDuration(id)
    elseif (kind == "spell" or kind == "spellname") and C_Spell and C_Spell.GetSpellCooldownDuration then
      local sid = id
      if kind == "spellname" then sid = BOOK[id] or (P.SPELL_ID and P.SPELL_ID[id]) or id end
      duration = C_Spell.GetSpellCooldownDuration(sid)
    end
    if duration and cd.SetCooldownFromDurationObject then
      cd:SetCooldownFromDurationObject(duration, true)
      return
    end
    local start, dur, modRate = P.ReadIconCooldown(kind, id)
    cd:SetCooldown(start, dur, modRate)
  end)
end

function P.PaintAssistedFace(frame)
  if not frame or not frame._ability or not P.IsAssistedAbility(frame._ability)
    or not P.NativeSlotIsAssisted(frame) then return end
  local cd = P.EnsureIconCooldown(frame)
  if cd then cd:Show() end
  if frame.icon then frame.icon:SetAlpha(1) end
  -- Do not read, compare, or unwrap the next-cast id. Pass it straight into
  -- texture/cooldown widgets so Midnight combat secrets still display.
  -- Out of combat SBA often returns Auto Attack (6603) or nil; painting that
  -- over the SBA plate looks like Attack and SBA fighting for the face.
  pcall(function()
    local spellID = C_AssistedCombat and C_AssistedCombat.GetNextCastSpell and C_AssistedCombat.GetNextCastSpell(false)
    if not InCombatLockdown() then
      local pub = P.PublicNumber(spellID)
      if not pub or pub == 6603 then spellID = SBA_ID end
    end
    local tex
    if frame.icon and C_Spell and C_Spell.GetSpellTexture then
      tex = C_Spell.GetSpellTexture(spellID)
    end
    if (not tex or tex == 0) and frame.icon then
      tex = SpellIcon(SBA_ID)
    end
    if frame.icon and tex then frame.icon:SetTexture(tex) end
    if cd and C_Spell and C_Spell.GetSpellCooldownDuration and cd.SetCooldownFromDurationObject then
      cd:SetCooldownFromDurationObject(C_Spell.GetSpellCooldownDuration(spellID), true)
    end
  end)
end

function P.ApplyIconCooldown(frame)
  if not frame then return end
  if frame._ability and P.IsAssistedAbility(frame._ability) then
    P.PaintAssistedFace(frame)
    return
  end
  local cd = P.EnsureIconCooldown(frame)
  if not cd then return end
  local kind, id = P.CooldownSource(frame)
  if not kind then
    pcall(function() cd:Clear() end)
    return
  end
  P.ApplyDurationCooldown(cd, kind, id)
end

function P.DriveIconCooldowns()
  for _, tab in pairs(consoleTabs or {}) do
    if tab then P.ApplyIconCooldown(tab) end
  end
  for _, b in ipairs(allMenuButtons or {}) do
    if b then P.ApplyIconCooldown(b) end
  end
  if P.DriveNbaCooldowns then P.DriveNbaCooldowns() end
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
    if P.DrivePressPulse then P.DrivePressPulse() end
  end)
end

-- GCD pulse: combat-only bezel. Native cooldown swipe, gold channel.
-- Secret-safe: duration objects go straight into Cooldown.
P.GCD_SPELL = 61304
P.PULSE_FX = "Interface\\AddOns\\SuperBinds\\Media\\"
P.PULSE_RING = 64
P.PULSE_OPACITY_DEFAULT = 0.2
P.PULSE_WINDOW_DEFAULT = 0.75
P.PULSE_WINDOW_MIN = 0.1
P.PULSE_WINDOW_MAX = 1.5
P.PULSE_WINDOW_FADE = 0.28
P.PULSE_ZONE_FRAC = 76 / 360
P.PULSE_ZONE_TWEEN = 0.22
P.PULSE_ZONE_CATCH = 4.5

function P.PulseOpacity()
  local v = P.PublicNumber(SuperBindsDB.pulseOpacity)
  if not v then v = P.PULSE_OPACITY_DEFAULT end
  if v < 0.1 then v = 0.1 end
  if v > 1 then v = 1 end
  return v
end

function P.PulseOpacityPercent(value)
  local n = P.PublicNumber(value)
  if not n then n = tonumber(value) end
  if not n then n = P.PulseOpacity() * 100 end
  if n > 0 and n <= 1.0001 then n = n * 100 end
  if n < 10 then n = 10 end
  if n > 100 then n = 100 end
  return n
end

function P.PulseGain()
  local d = P.PULSE_OPACITY_DEFAULT
  if d < 0.05 then d = 0.05 end
  local g = P.PulseOpacity() / d
  if g > 5 then g = 5 end
  return g
end

function P.SettingsPanelShown()
  local panel = _G.SettingsPanel
  return panel and panel.IsShown and panel:IsShown() and true or false
end

function P.WatchSettingsPulsePreview()
  if P._settingsPulseHooked then return end
  local panel = _G.SettingsPanel
  if not panel or not panel.HookScript then return end
  P._settingsPulseHooked = true
  panel:HookScript("OnHide", function()
    if P.EndPulsePreview then P.EndPulsePreview() end
  end)
end

function P.PulseWindow()
  local v = P.PublicNumber(SuperBindsDB.pulseWindow)
  if not v then v = P.PULSE_WINDOW_DEFAULT or 0.75 end
  if v < 0.1 then v = 0.1 end
  if v > 1.5 then v = 1.5 end
  return v
end

function P.PulseWindowHundredths(value)
  local n = P.PublicNumber(value)
  if not n then n = tonumber(value) end
  if not n then n = P.PulseWindow() * 100 end
  if n > 0 and n <= 1.5001 then n = n * 100 end
  if n < 10 then n = 10 end
  if n > 150 then n = 150 end
  return n
end

function P.CommitPulseWindow(value, preview)
  P.EnsureDB()
  SuperBindsDB.pulseWindow = P.PulseWindowHundredths(value) / 100
  if preview ~= false and P.BeginPulsePreview then P.BeginPulsePreview() end
end

function P.CommitPulseOpacity(value, preview)
  P.EnsureDB()
  SuperBindsDB.pulseOpacity = P.PulseOpacityPercent(value) / 100
  if P.TunePressPulseChrome then P.TunePressPulseChrome() end
  if preview ~= false and P.BeginPulsePreview then P.BeginPulsePreview() end
end

function P.ApplyPulseOpacity()
  P.CommitPulseOpacity(P.PulseOpacityPercent(), true)
end

function P.PulsePreviewStrata(f, on)
  f = f or P.pulse
  if not f then return end
  if on then
    f:SetParent(UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(1000)
    if f.SetToplevel then f:SetToplevel(true) end
  else
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(80)
    if f.SetToplevel then f:SetToplevel(false) end
  end
end

function P.BeginPulsePreview()
  if SuperBindsDB.showPressPulse == false then return end
  P._pulsePreview = true
  P._pulsePreviewUntil = (GetTime() or 0) + 6
  P._pulsePreviewGen = (P._pulsePreviewGen or 0) + 1
  local gen = P._pulsePreviewGen
  local f = P.EnsurePressPulse()
  if not f then return end
  P.PulsePreviewStrata(f, true)
  if f._sbHideAg then f._sbHideAg:Stop() end
  f:SetAlpha(1)
  f:Show()
  P.TunePressPulseChrome()
  if not f._sbCharging and not f._sbWindowing then P.StartPulseCharge() end
  if C_Timer and C_Timer.After then
    C_Timer.After(6, function()
      if P._pulsePreviewGen ~= gen then return end
      if P.SettingsPanelShown and P.SettingsPanelShown() then return end
      P.EndPulsePreview()
    end)
  end
end

function P.PulseChrome()
  local b = P.Visual and P.Visual.brass or {0.68, 0.55, 0.35}
  local s = P.Visual and P.Visual.shine or {0.86, 0.73, 0.49}
  local c = P.Visual and P.Visual.text or {0.94, 0.91, 0.83}
  return b[1], b[2], b[3], s[1], s[2], s[3], c[1], c[2], c[3]
end

function P.PulseGuessGcd()
  return P.PublicNumber(P.PULSE_GCD) or 1.5
end

function P.PulseLearnGcd(elapsed)
  elapsed = P.PublicNumber(elapsed)
  if not elapsed then return end
  if elapsed < 0.55 or elapsed > 2.15 then return end
  local cur = P.PublicNumber(P.PULSE_GCD) or elapsed
  P.PULSE_GCD = cur * 0.4 + elapsed * 0.6
end

function P.PulseLight(parent, layer, file, dim, r, g, b, a, blend)
  local t = parent:CreateTexture(nil, layer)
  t:SetSize(dim, dim)
  t:SetPoint("CENTER")
  t:SetTexture(file)
  t:SetBlendMode(blend or "ADD")
  t:SetVertexColor(r, g, b, a)
  if P.SmoothUITexture then P.SmoothUITexture(t) end
  t:Hide()
  return t
end

function P.PulseBurst(parent, file, dim, r, g, b, duration, fromScale, toScale, delay, ox, oy)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetPoint("CENTER", ox or 0, oy or 0)
  holder:SetSize(dim, dim)
  holder:SetFrameLevel(parent:GetFrameLevel() + 14)
  holder:Hide()
  local t = holder:CreateTexture(nil, "OVERLAY")
  t:SetAllPoints()
  t:SetTexture(file)
  t:SetBlendMode("ADD")
  t:SetVertexColor(r, g, b, 1)
  if P.SmoothUITexture then P.SmoothUITexture(t) end
  local ag = holder:CreateAnimationGroup()
  local fade = ag:CreateAnimation("Alpha")
  fade:SetFromAlpha(1)
  fade:SetToAlpha(0)
  fade:SetDuration(duration)
  fade:SetSmoothing("OUT")
  if delay and delay > 0 then fade:SetStartDelay(delay) end
  local scale = ag:CreateAnimation("Scale")
  if scale.SetScaleTo then
    scale:SetScaleFrom(fromScale, fromScale)
    scale:SetScaleTo(toScale, toScale)
  else
    scale:SetScale(toScale, toScale)
  end
  scale:SetDuration(duration)
  scale:SetSmoothing("OUT")
  if delay and delay > 0 then scale:SetStartDelay(delay) end
  ag:SetScript("OnPlay", function() holder:Show() end)
  ag:SetScript("OnFinished", function() holder:Hide() end)
  return ag
end

function P.PulseMkAlpha(frame, fromA, toA, dur, smooth)
  local ag = frame:CreateAnimationGroup()
  local a = ag:CreateAnimation("Alpha")
  a:SetFromAlpha(fromA or 0)
  a:SetToAlpha(toA or 1)
  a:SetDuration(dur or 0.2)
  if a.SetSmoothing then pcall(a.SetSmoothing, a, smooth or "OUT") end
  ag._sbA = a
  return ag
end

function P.PulseMkLoop(frame, lo, hi, dIn, dOut)
  local ag = frame:CreateAnimationGroup()
  ag:SetLooping("REPEAT")
  local a = ag:CreateAnimation("Alpha")
  a:SetFromAlpha(lo)
  a:SetToAlpha(hi)
  a:SetDuration(dIn)
  a:SetOrder(1)
  if a.SetSmoothing then pcall(a.SetSmoothing, a, "IN_OUT") end
  local b = ag:CreateAnimation("Alpha")
  b:SetFromAlpha(hi)
  b:SetToAlpha(lo)
  b:SetDuration(dOut)
  b:SetOrder(2)
  if b.SetSmoothing then pcall(b.SetSmoothing, b, "IN_OUT") end
  return ag
end

function P.PulseEnsureWindowFx(f)
  if not f then return end
  local fx = P.PULSE_FX
  local dim = P.PULSE_RING or 64
  if f._sbGlowHold and not f._sbHitBreath then
    f._sbHitBreath = P.PulseMkLoop(f._sbGlowHold, 0.55, 1, 0.10, 0.12)
  end
  if f._sbReadyHold and not f._sbReadyBreath then
    f._sbReadyBreath = P.PulseMkLoop(f._sbReadyHold, 0.40, 1, 0.11, 0.13)
  end
  if not f._sbHitBurst and fx then
    f._sbHitBurst = P.PulseBurst(f, fx .. "PulseReady", dim + 20, 0.96, 0.88, 0.55, 0.32, 0.88, 1.55)
  end
  if f._sbApproach then
    f._sbApproach:Hide()
    f._sbApproach = nil
  end
  if not f._sbZone and fx then
    local z = CreateFrame("Frame", nil, f)
    z:SetAllPoints()
    z:EnableMouse(false)
    z:SetFrameLevel(f:GetFrameLevel() + 5)
    local zt = z:CreateTexture(nil, "ARTWORK")
    zt:SetPoint("CENTER")
    zt:SetSize(dim, dim)
    zt:SetTexture(fx .. "PulseHitZone")
    zt:SetBlendMode("BLEND")
    zt:SetVertexColor(0.78, 0.62, 0.34, 1)
    if P.SmoothUITexture then P.SmoothUITexture(zt) end
    f._sbZone = z
    f._sbZoneTex = zt
    if zt.SetSnapToPixelGrid then pcall(zt.SetSnapToPixelGrid, zt, false) end
  end
  if not f._sbPip and fx then
    local pip = CreateFrame("Frame", nil, f)
    pip:SetAllPoints()
    pip:EnableMouse(false)
    pip:SetFrameLevel(f:GetFrameLevel() + 9)
    local pt = pip:CreateTexture(nil, "OVERLAY")
    pt:SetPoint("CENTER")
    pt:SetSize(dim, dim)
    pt:SetTexture(fx .. "PulseEdge")
    pt:SetBlendMode("ADD")
    pt:SetVertexColor(0.95, 0.82, 0.42, 1)
    if P.SmoothUITexture then P.SmoothUITexture(pt) end
    if pt.SetSnapToPixelGrid then pcall(pt.SetSnapToPixelGrid, pt, false) end
    f._sbPip = pip
    f._sbPipTex = pt
  end
  if f._sbPip then f._sbPip:Show() end
  local vis = f.cooldown
  if vis then
    vis:Hide()
    vis:SetAlpha(0)
    vis._sbPulseArmed = false
  end
  local cd = f.cooldown
  if cd and not f._sbCdOut then
    f._sbCdOut = P.PulseMkAlpha(cd, 1, 0, 0.10, "IN")
    f._sbCdIn = P.PulseMkAlpha(cd, 0, 1, 0.16, "OUT")
    if f._sbCdOut.SetToFinalAlpha then f._sbCdOut:SetToFinalAlpha(true) end
    if f._sbCdIn.SetToFinalAlpha then f._sbCdIn:SetToFinalAlpha(true) end
    f._sbCdOut:SetScript("OnFinished", function()
      if P.PulseCommitCd then P.PulseCommitCd() end
      local hoop = P.pulse
      local c = hoop and hoop.cooldown
      if not c then return end
      if c:IsShown() and hoop._sbCdIn and hoop._sbCdIn._sbA then
        c:SetAlpha(0)
        hoop._sbCdIn._sbA:SetFromAlpha(0)
        hoop._sbCdIn._sbA:SetToAlpha(1)
        hoop._sbCdIn:Play()
      else
        c:SetAlpha(1)
      end
    end)
    f._sbCdIn:SetScript("OnFinished", function()
      if f.cooldown then f.cooldown:SetAlpha(1) end
    end)
  end
  if f._sbReadyAg and not f._sbReadyAg._sbSettle then
    f._sbReadyAg._sbSettle = true
    f._sbReadyAg:SetScript("OnFinished", function()
      local a = f._sbReadyAg._sbA
      local to = 0
      if a and a.GetToAlpha then pcall(function() to = a:GetToAlpha() end) end
      to = P.PublicNumber(to) or 0
      if f._sbReadyHold then f._sbReadyHold:SetAlpha(to) end
    end)
  end
  f:SetScript("OnUpdate", function(self, elapsed)
    if P.PulseTick then P.PulseTick(self, elapsed) end
  end)
end

function P.PulseEaseOut(u)
  u = P.PublicNumber(u) or 0
  if u < 0 then u = 0 end
  if u > 1 then u = 1 end
  local s = 1 - u
  return 1 - s * s * s
end

function P.PulseZoneFrac()
  local z = P.PublicNumber(P.PULSE_ZONE_FRAC)
  if not z then z = 76 / 360 end
  if z < 0.12 then z = 0.12 end
  if z > 0.28 then z = 0.28 end
  return z
end

function P.PulseSpinRate()
  local hold = P.PulseWindow and P.PulseWindow() or 0.75
  if hold < 0.1 then hold = 0.1 end
  return P.PulseZoneFrac() * 360 / hold
end

function P.PulseNormAng(a)
  a = P.PublicNumber(a) or 0
  a = a % 360
  if a < 0 then a = a + 360 end
  return a
end

function P.PulseShortDelta(from, to)
  local d = P.PulseNormAng((P.PublicNumber(to) or 0) - (P.PublicNumber(from) or 0))
  if d > 180 then d = d - 360 end
  return d
end

function P.PulseDrawSpin()
  local f = P.pulse
  if not f then return end
  local rad = math.pi / 180
  local ang = P.PulseNormAng(f._sbSpinAng)
  local pip = f._sbPipTex
  if pip and pip.SetRotation then
    pcall(pip.SetRotation, pip, -ang * rad)
  end
  local zr = P.PulseNormAng(f._sbZoneRot)
  local zt = f._sbZoneTex
  if zt and zt.SetRotation then
    pcall(zt.SetRotation, zt, -zr * rad)
  end
end

function P.PulseZoneHome()
  return 360 * (1 - P.PulseZoneFrac())
end

function P.PulseZoneDest(ahead)
  local f = P.pulse
  if not f then return 0 end
  if f._sbSpinAng == nil then f._sbSpinAng = 0 end
  ahead = P.PublicNumber(ahead)
  if not ahead then ahead = P.PulseGuessGcd() end
  if ahead < 0.05 then ahead = 0.05 end
  local entry = P.PulseNormAng(f._sbSpinAng + P.PulseSpinRate() * ahead)
  return P.PulseNormAng(entry - P.PulseZoneHome())
end

function P.PulseZoneChase(elapsed)
  local f = P.pulse
  if not f then return end
  elapsed = P.PublicNumber(elapsed) or 0
  local dest = P.PulseZoneDest(P.PulseGuessGcd())
  local cur = P.PulseNormAng(f._sbZoneRot)
  local d = P.PulseShortDelta(cur, dest)
  local ad = d
  if ad < 0 then ad = -ad end
  local step = P.PulseSpinRate() * elapsed * (P.PULSE_ZONE_CATCH or 4.5)
  if ad <= step or ad < 0.8 then
    f._sbZoneRot = dest
    return
  end
  if d > 0 then
    f._sbZoneRot = P.PulseNormAng(cur + step)
  else
    f._sbZoneRot = P.PulseNormAng(cur - step)
  end
end

function P.PulsePlaceZone(tween)
  local f = P.pulse
  if not f then return end
  if f._sbSpinAng == nil then f._sbSpinAng = 0 end
  f._sbZoneLock = true
  f._sbMissed = false
  local gcd = P.PublicNumber(f._sbGcdLen) or P.PulseGuessGcd()
  if gcd < 0.4 then gcd = 0.4 end
  local remain = gcd
  if f._sbHandStart then
    local t
    pcall(function() t = GetTime() - f._sbHandStart end)
    t = P.PublicNumber(t)
    if t then remain = gcd - t end
  end
  local dest = P.PulseZoneDest(remain)
  local cur = P.PulseNormAng(f._sbZoneRot)
  local jump = P.PulseShortDelta(cur, dest)
  if jump < 0 then jump = -jump end
  local canTween = tween
  if canTween == nil then canTween = true end
  if canTween and jump > 6 then
    f._sbZoneFrom = cur
    f._sbZoneTo = dest
    f._sbZoneT = 0
    f._sbZoneDur = P.PULSE_ZONE_TWEEN or 0.22
  else
    f._sbZoneDur = nil
    f._sbZoneRot = dest
  end
  if f._sbPip then f._sbPip:Show() end
  P.PulseDrawSpin()
end

function P.PulseHitAmount()
  local f = P.pulse
  if f and f._sbWindowing then return 1 end
  return 0
end

function P.PulseTuneZone()
  local f = P.pulse
  local z = f and f._sbZone
  if not z then return end
  local g = P.PulseGain and P.PulseGain() or 1
  if g > 1.6 then g = 1.6 end
  local a, r, gv, b
  if f._sbWindowing then
    a = 0.92 * g
    if a > 1 then a = 1 end
    r, gv, b = 0.98, 0.86, 0.38
  elseif f._sbCharging then
    a = 0.46 * g
    if a < 0.32 then a = 0.32 end
    r, gv, b = 0.72, 0.58, 0.32
  elseif f._sbMissed then
    a = 0.36 * g
    if a < 0.26 then a = 0.26 end
    r, gv, b = 0.68, 0.54, 0.30
  else
    a = 0.30 * g
    if a < 0.22 then a = 0.22 end
    r, gv, b = 0.62, 0.50, 0.28
  end
  z:Show()
  z:SetAlpha(a)
  if f._sbZoneTex then f._sbZoneTex:SetVertexColor(r, gv, b, 1) end
  local pip = f._sbPip
  if pip then
    pip:Show()
    if f._sbWindowing then
      pip:SetAlpha(1)
      if f._sbPipTex then f._sbPipTex:SetVertexColor(1, 0.92, 0.55, 1) end
    else
      pip:SetAlpha(0.92)
      if f._sbPipTex then f._sbPipTex:SetVertexColor(0.92, 0.78, 0.42, 1) end
    end
  end
end

function P.PulseApplySize(dim)
  local f = P.pulse
  if not f then return end
  local base = P.PULSE_RING or 64
  dim = P.PublicNumber(dim) or base
  f:SetSize(dim, dim)
  if f._sbGlow then f._sbGlow:SetSize(dim + 8 + (dim - base) * 0.25, dim + 8 + (dim - base) * 0.25) end
  if f._sbZoneTex then f._sbZoneTex:SetSize(dim, dim) end
  if f._sbPipTex then f._sbPipTex:SetSize(dim, dim) end
end

function P.PulseTweenSize(toDim, dur)
  local f = P.pulse
  if not f then return end
  local w
  pcall(function() w = f:GetWidth() end)
  w = P.PublicNumber(w) or P.PULSE_RING or 64
  toDim = P.PublicNumber(toDim) or P.PULSE_RING or 64
  local d = w - toDim
  if d < 0 then d = -d end
  if d < 0.6 then
    f._sbSzDur = nil
    P.PulseApplySize(toDim)
    return
  end
  f._sbSzFrom = w
  f._sbSzTo = toDim
  f._sbSzT = 0
  f._sbSzDur = dur or 0.22
end

function P.PulseTick(f, elapsed)
  if not f then return end
  elapsed = P.PublicNumber(elapsed) or 0
  if f._sbSzDur then
    f._sbSzT = (f._sbSzT or 0) + elapsed
    local u = f._sbSzT / f._sbSzDur
    if u >= 1 then
      u = 1
      f._sbSzDur = nil
    end
    u = P.PulseEaseOut(u)
    P.PulseApplySize(f._sbSzFrom + (f._sbSzTo - f._sbSzFrom) * u)
    if P.TunePressPulseChrome then P.TunePressPulseChrome() end
  end
  local shown = false
  if P.PulseShouldShow and P.PulseShouldShow() then shown = true end
  if P._pulsePreview then shown = true end
  if shown then
    if f._sbSpinAng == nil then f._sbSpinAng = 0 end
    f._sbSpinAng = f._sbSpinAng + P.PulseSpinRate() * elapsed
    if f._sbZoneLock then
      if f._sbZoneDur then
        f._sbZoneT = (f._sbZoneT or 0) + elapsed
        local zu = f._sbZoneT / f._sbZoneDur
        if zu >= 1 then
          f._sbZoneDur = nil
          f._sbZoneRot = f._sbZoneTo
        else
          zu = P.PulseEaseOut(zu)
          f._sbZoneRot = P.PulseNormAng(f._sbZoneFrom + P.PulseShortDelta(f._sbZoneFrom, f._sbZoneTo) * zu)
        end
      end
    else
      f._sbZoneDur = nil
      P.PulseZoneChase(elapsed)
    end
    P.PulseDrawSpin()
  end
  if f._sbWindowing and f._sbWindowStart then
    local hold = P.PulseWindow and P.PulseWindow() or 0.75
    local t
    pcall(function() t = GetTime() - f._sbWindowStart end)
    t = P.PublicNumber(t)
    if t and t >= hold then
      if P.ClosePulseWindow then P.ClosePulseWindow(true) end
      return
    end
  end
  if f._sbCharging and P.PulseChargeExpired and P.PulseChargeExpired() and P.PulseEnterWindow then
    P.PulseEnterWindow()
  end
end

function P.PulseCommitCd()
  local f = P.pulse
  if not f then return end
  local p = f._sbCdPending
  f._sbCdPending = nil
  if not p then return end
  local cd = f.cooldown
  if p.mode == "idle" then
    P.PulseApplySwipe("idle")
    if cd then cd:SetAlpha(1) end
    return
  end
  P.PulseApplySwipe(p.mode)
  if cd then
    cd._sbPulseArmed = p.armed or p.mode
    cd:Show()
    if p.start and p.dur then
      pcall(cd.SetCooldown, cd, p.start, p.dur)
    elseif p.dur then
      pcall(cd.SetCooldown, cd, GetTime(), p.dur)
    end
  end
end

function P.PulseCrossfadeCd(mode, start, dur, armed)
  local f = P.pulse
  if not f then return end
  if P.PulseEnsureWindowFx then P.PulseEnsureWindowFx(f) end
  f._sbCdPending = { mode = mode, start = start, dur = dur, armed = armed or mode }
  local cd = f.cooldown
  if not cd then
    P.PulseCommitCd()
    return
  end
  local shown = cd:IsShown() and true or false
  local a
  pcall(function() a = cd:GetAlpha() end)
  a = P.PublicNumber(a) or 1
  if f._sbCdOut then f._sbCdOut:Stop() end
  if f._sbCdIn then f._sbCdIn:Stop() end
  if (not shown) or a < 0.08 then
    P.PulseCommitCd()
    if mode ~= "idle" then
      cd:SetAlpha(0)
      cd:Show()
      if f._sbCdIn and f._sbCdIn._sbA then
        f._sbCdIn._sbA:SetFromAlpha(0)
        f._sbCdIn._sbA:SetToAlpha(1)
        f._sbCdIn:Play()
      else
        cd:SetAlpha(1)
      end
    end
    return
  end
  if f._sbCdOut and f._sbCdOut._sbA then
    f._sbCdOut._sbA:SetFromAlpha(a)
    f._sbCdOut._sbA:SetToAlpha(0)
    f._sbCdOut:Play()
  else
    cd:SetAlpha(0)
    P.PulseCommitCd()
    if mode ~= "idle" then cd:SetAlpha(1) end
  end
end

function P.PulseStopHitLoops()
  local f = P.pulse
  if not f then return end
  if f._sbHitBreath then f._sbHitBreath:Stop() end
  if f._sbReadyBreath then f._sbReadyBreath:Stop() end
  if f._sbGlowHold then f._sbGlowHold:SetAlpha(1) end
end

function P.PulseReadyTo(to, dur)
  local f = P.pulse
  if not f or not f._sbReadyHold then return end
  to = to or 0
  dur = dur or 0.18
  local cur = 0
  pcall(function() cur = f._sbReadyHold:GetAlpha() end)
  cur = P.PublicNumber(cur) or 0
  if f._sbReadyAg then f._sbReadyAg:Stop() end
  if f._sbReadyAg and f._sbReadyAg._sbA then
    f._sbReadyAg._sbA:SetFromAlpha(cur)
    f._sbReadyAg._sbA:SetToAlpha(to)
    f._sbReadyAg._sbA:SetDuration(dur)
    f._sbReadyAg:Play()
  else
    f._sbReadyHold:SetAlpha(to)
  end
end

function P.PulseSettle(kind, hit)
  local f = P.pulse
  if not f then return end
  if P.PulseEnsureWindowFx then P.PulseEnsureWindowFx(f) end
  local dim = P.PULSE_RING or 64
  P.PulseTweenSize(dim, 0.12)
  if kind == "window" then
    P.PulseIdleBreath(false)
    P.PulseStopHitLoops()
    P.PulseApplySwipe("window")
    P.PulseReadyTo(1, 0.12)
  elseif kind == "gcd" then
    P.PulseIdleBreath(false)
    P.PulseStopHitLoops()
    P.PulseApplySwipe("gcd")
    if P.PulsePlaceZone then P.PulsePlaceZone(true) end
    if hit then P.PulseReadyTo(0, 0.20) else P.PulseReadyTo(0, 0.10) end
  elseif kind == "miss" then
    P.PulseIdleBreath(false)
    P.PulseStopHitLoops()
    P.PulseApplySwipe("miss")
    f._sbZoneLock = false
    f._sbMissed = true
    f._sbZoneDur = nil
    P.PulseReadyTo(0, 0.20)
  else
    P.PulseStopHitLoops()
    P.PulseApplySwipe("idle")
    f._sbZoneLock = false
    f._sbZoneDur = nil
    P.PulseReadyTo(0, 0.16)
    P.PulseIdleBreath(true)
  end
  if P.TunePressPulseChrome then P.TunePressPulseChrome() end
  if P.PaintPulseNextName then P.PaintPulseNextName() end
end

function P.PulseWindowFx(on)
  if P.PulseSettle then
    P.PulseSettle(on and "window" or "idle")
  end
end

function P.EndPulsePreview()
  if not P._pulsePreview then return end
  P._pulsePreview = false
  P.PulsePreviewStrata(P.pulse, false)
  if P.ApplyPressPulseShown then P.ApplyPressPulseShown() end
end

function P.PulseIdleBreath(on)
  local f = P.pulse
  if not f or not f._sbBreath then return end
  if on and P.PulseShouldShow() and not f._sbCharging and not f._sbWindowing then
    if not f._sbBreath:IsPlaying() then f._sbBreath:Play() end
  else
    f._sbBreath:Stop()
    if f._sbGlowHold then f._sbGlowHold:SetAlpha(1) end
  end
end

function P.PulseFade(f, show)
  if not f then return end
  if show then
    if f._sbHideAg then f._sbHideAg:Stop() end
    f:Show()
    local cur = f:GetAlpha() or 0
    if cur > 0.97 then
      f:SetAlpha(1)
      P.PulseIdleBreath(true)
      return
    end
    if f._sbShowAg and f._sbShowAg._sbA then
      f._sbShowAg._sbA:SetFromAlpha(cur)
      f._sbShowAg._sbA:SetToAlpha(1)
      f._sbShowAg:Play()
    else
      f:SetAlpha(1)
    end
    P.PulseIdleBreath(true)
    return
  end
  if f._sbShowAg then f._sbShowAg:Stop() end
  P.PulseIdleBreath(false)
  if P.ClosePulseWindow then P.ClosePulseWindow(false) end
  if f._sbCharging then P.StopPulseCharge() end
  if P.PulseApplySize then P.PulseApplySize(P.PULSE_RING or 64) end
  local cur = f:GetAlpha() or 0
  if cur < 0.03 or not f:IsShown() then
    f:SetAlpha(0)
    f:Hide()
    return
  end
  if f._sbHideAg and f._sbHideAg._sbA then
    f._sbHideAg._sbA:SetFromAlpha(cur)
    f._sbHideAg._sbA:SetToAlpha(0)
    f._sbHideAg:Play()
  else
    f:SetAlpha(0)
    f:Hide()
  end
end

function P.EnsurePulseNextName(f)
  f = f or P.pulse
  if not f then return nil end
  if f._sbNextName then return f._sbNextName end
  local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("BOTTOM", f, "TOP", 0, 6)
  fs:SetWidth(200)
  fs:SetJustifyH("CENTER")
  P.VisualFont(fs, 18, P.Visual.text, "OUTLINE")
  fs:SetText("")
  f._sbNextName = fs
  return fs
end

function P.NextPressLabel()
  if not (P.NbaEnabled and P.NbaEnabled()) then return nil end
  if not (P.NbaFormList and P.NbaFormList()) then return nil end
  if not P._nbaShown then return nil end
  local _, row = P.NbaNextId()
  if type(row) ~= "table" or not P.NbaLiveKey then return nil end
  local k = P.NbaLiveKey(row.id, row.name or row.label)
  if P.Text(k) then return k end
end

function P.PaintPulseNextName()
  local f = P.pulse
  if not f and P.PulseShouldShow and P.PulseShouldShow() then
    f = P.EnsurePressPulse and P.EnsurePressPulse()
  end
  if not f then return end
  local fs = P.EnsurePulseNextName(f)
  if not fs then return end
  if not (P.NbaNameEnabled and P.NbaNameEnabled()) then
    fs:SetText("")
    fs:Hide()
    return
  end
  if not (P.NbaEnabled and P.NbaEnabled() and P.NbaFormList and P.NbaFormList()) then
    fs:SetText("")
    fs:Hide()
    return
  end
  local label = P.NextPressLabel and P.NextPressLabel()
  if P.Text(label) then
    fs:SetText(label)
    fs:Show()
    fs:SetAlpha(1)
    local hoop = P.pulse
    if hoop and hoop._sbWindowing then
      P.VisualFont(fs, 24, P.Visual.shine or P.Visual.brass or P.Visual.text, "OUTLINE")
    else
      P.VisualFont(fs, 18, P.Visual.text, "OUTLINE")
    end
  else
    fs:SetText("")
    fs:Hide()
  end
end

function P.EnsurePressPulse()
  if P.pulse then
    P.EnsurePulseNextName(P.pulse)
    if P.PulseEnsureWindowFx then P.PulseEnsureWindowFx(P.pulse) end
    return P.pulse
  end
  local fx = P.PULSE_FX
  local dim = P.PULSE_RING
  local f = CreateFrame('Frame', 'SuperBindsPressPulse', UIParent)
  f:SetSize(dim, dim)
  f:SetFrameStrata('HIGH')
  f:SetFrameLevel(80)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetAlpha(0)
  f:RegisterForDrag('LeftButton')
  f:SetScript('OnDragStart', function(self) self:StartMoving() end)
  f:SetScript('OnDragStop', function(self)
    self:StopMovingOrSizing()
    SavePosition('pulse', self)
  end)

  local cd = CreateFrame('Cooldown', 'SuperBindsPressPulseCD', f, 'CooldownFrameTemplate')
  cd:SetAllPoints()
  cd:EnableMouse(false)
  cd:SetAlpha(1)
  if cd.SetDrawSwipe then cd:SetDrawSwipe(true) end
  if cd.SetDrawEdge then cd:SetDrawEdge(true) end
  if cd.SetDrawBling then cd:SetDrawBling(false) end
  if cd.SetHideCountdownNumbers then cd:SetHideCountdownNumbers(true) end
  if cd.SetUseCircularEdge then pcall(cd.SetUseCircularEdge, cd, true) end
  if cd.SetReverse then pcall(cd.SetReverse, cd, false) end
  if cd.SetSwipeTexture then pcall(cd.SetSwipeTexture, cd, fx .. "PulseSwipe") end
  if cd.SetSwipeColor then pcall(cd.SetSwipeColor, cd, 0.22, 0.16, 0.08, 0.27) end
  if cd.SetEdgeTexture then pcall(cd.SetEdgeTexture, cd, fx .. "PulseEdge") end
  if cd.SetEdgeScale then pcall(cd.SetEdgeScale, cd, 0.72) end
  cd:Hide()
  cd:SetScript('OnCooldownDone', function(self)
    local kind = self._sbPulseArmed
    self._sbPulseArmed = false
    if not kind then return end
    local hoop = P.pulse
    local elapsed
    if hoop and hoop._sbHandStart then
      pcall(function() elapsed = GetTime() - hoop._sbHandStart end)
      elapsed = P.PublicNumber(elapsed)
    end
    if kind == "spin" or kind == "gcd" or kind == true then
      if hoop and hoop._sbWindowing then return end
      if elapsed and elapsed < 0.12 then
        self._sbPulseArmed = "spin"
        return
      end
      if hoop and hoop._sbHandStart then P.PulseLearnGcd(GetTime() - hoop._sbHandStart) end
      if P.PulseEnterWindow then P.PulseEnterWindow() end
    elseif kind == "window" or kind == "cycle" then
      if elapsed and elapsed < 0.12 then
        self._sbPulseArmed = kind
        return
      end
      if P.ClosePulseWindow then P.ClosePulseWindow(true) end
      if P._pulsePreview and P.PulseShouldShow and P.PulseShouldShow() then
        if C_Timer and C_Timer.After then
          C_Timer.After(0.28, function()
            if P._pulsePreview and P.StartPulseCharge then P.StartPulseCharge() end
          end)
        end
      end
    end
  end)
  f.cooldown = cd

  local watch = CreateFrame('Cooldown', 'SuperBindsPressPulseGcdWatch', f, 'CooldownFrameTemplate')
  watch:SetSize(1, 1)
  watch:SetPoint("CENTER")
  watch:EnableMouse(false)
  watch:SetAlpha(0)
  if watch.SetDrawBling then watch:SetDrawBling(false) end
  if watch.SetHideCountdownNumbers then watch:SetHideCountdownNumbers(true) end
  watch:Hide()
  watch:SetScript('OnCooldownDone', function(self)
    if not self._sbWatchArmed then return end
    self._sbWatchArmed = false
    local hoop = P.pulse
    local elapsed
    if hoop and hoop._sbHandStart then
      pcall(function() elapsed = GetTime() - hoop._sbHandStart end)
      elapsed = P.PublicNumber(elapsed)
    end
    if elapsed and elapsed < 0.12 then
      self._sbWatchArmed = true
      return
    end
    if hoop and hoop._sbHandStart then P.PulseLearnGcd(GetTime() - hoop._sbHandStart) end
    if P.PulseEnterWindow then P.PulseEnterWindow() end
  end)
  f._sbGcdWatch = watch

  local glowHold = CreateFrame('Frame', nil, f)
  glowHold:SetAllPoints()
  glowHold:EnableMouse(false)
  glowHold:SetFrameLevel(f:GetFrameLevel() + 7)
  f._sbGlowHold = glowHold
  local glow = glowHold:CreateTexture(nil, 'ARTWORK')
  glow:SetPoint('CENTER')
  glow:SetSize(dim + 8, dim + 8)
  glow:SetTexture(fx .. 'PulseGlow')
  glow:SetBlendMode('ADD')
  glow:SetVertexColor(0.90, 0.76, 0.42, 1)
  if P.SmoothUITexture then P.SmoothUITexture(glow) end
  f._sbGlow = glow
  local breath = glowHold:CreateAnimationGroup()
  breath:SetLooping('REPEAT')
  local bIn = breath:CreateAnimation('Alpha')
  bIn:SetFromAlpha(0.70)
  bIn:SetToAlpha(1)
  bIn:SetDuration(1.40)
  bIn:SetOrder(1)
  if bIn.SetSmoothing then pcall(bIn.SetSmoothing, bIn, 'IN_OUT') end
  local bOut = breath:CreateAnimation('Alpha')
  bOut:SetFromAlpha(1)
  bOut:SetToAlpha(0.70)
  bOut:SetDuration(1.65)
  bOut:SetOrder(2)
  if bOut.SetSmoothing then pcall(bOut.SetSmoothing, bOut, 'IN_OUT') end
  f._sbBreath = breath

  local bezelHold = CreateFrame('Frame', nil, f)
  bezelHold:SetAllPoints()
  bezelHold:EnableMouse(false)
  bezelHold:SetFrameLevel(f:GetFrameLevel() + 6)
  f._sbBezelHold = bezelHold
  local bezel = bezelHold:CreateTexture(nil, 'OVERLAY')
  bezel:SetAllPoints()
  bezel:SetTexture(fx .. 'PulseBezel')
  bezel:SetBlendMode('BLEND')
  bezel:SetVertexColor(0.84, 0.70, 0.42, 1)
  if P.SmoothUITexture then P.SmoothUITexture(bezel) end
  f._sbBezel = bezel

  local readyHold = CreateFrame('Frame', nil, f)
  readyHold:SetAllPoints()
  readyHold:EnableMouse(false)
  readyHold:SetFrameLevel(f:GetFrameLevel() + 8)
  readyHold:SetAlpha(0)
  f._sbReadyHold = readyHold
  local readyTex = readyHold:CreateTexture(nil, 'OVERLAY')
  readyTex:SetAllPoints()
  readyTex:SetTexture(fx .. 'PulseReady')
  readyTex:SetBlendMode('ADD')
  readyTex:SetVertexColor(0.94, 0.88, 0.62, 1)
  if P.SmoothUITexture then P.SmoothUITexture(readyTex) end
  f._sbReadyTex = readyTex
  f._sbReadyAg = P.PulseMkAlpha(readyHold, 1, 0, P.PULSE_WINDOW_FADE or 0.28, "OUT")
  if f._sbReadyAg then
    f._sbReadyAg:SetScript("OnFinished", function()
      if f._sbReadyHold then f._sbReadyHold:SetAlpha(0) end
    end)
  end

  f._sbShowAg = P.PulseMkAlpha(f, 0, 1, 0.20, "OUT")
  if f._sbShowAg.SetToFinalAlpha then f._sbShowAg:SetToFinalAlpha(true) end
  f._sbShowAg:SetScript('OnPlay', function() f:Show() end)
  f._sbShowAg:SetScript('OnFinished', function() f:SetAlpha(1) end)
  f._sbHideAg = P.PulseMkAlpha(f, 1, 0, 0.28, "OUT")
  if f._sbHideAg.SetToFinalAlpha then f._sbHideAg:SetToFinalAlpha(true) end
  f._sbHideAg:SetScript('OnFinished', function()
    f:SetAlpha(0)
    f:Hide()
    P.PulseIdleBreath(false)
  end)

  f:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    GameTooltip:SetText("GCD pulse")
    GameTooltip:AddLine("The pip spins at a steady rate. Gold slice is the press window — it slides to the next landing when you hit. Drag to move.", 0.82, 0.86, 0.84, true)
    GameTooltip:Show()
  end)
  f:SetScript('OnLeave', function() GameTooltip:Hide() end)
  f:SetScript("OnUpdate", function(self, elapsed)
    if P.PulseTick then P.PulseTick(self, elapsed) end
  end)

  P.pulse = f
  P.EnsurePulseNextName(f)
  P.PulseEnsureWindowFx(f)
  P.PlacePressPulse()
  P.ApplyPressPulseShown()
  return f
end

function P.PlacePressPulse()
  local f = P.pulse
  if not f then return end
  local saved = SuperBindsDB.pos and SuperBindsDB.pos.pulse
  f:ClearAllPoints()
  if type(saved) == "table" and saved[1] and P.Number(saved[3]) and P.Number(saved[4]) then
    f:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
  else
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -36)
  end
end

function P.PulseShouldShow()
  if SuperBindsDB.showPressPulse == false then return false end
  if P._pulsePreview then return true end
  if P.HUDMapOpen and P.HUDMapOpen() then return false end
  return P.regenCombat == true
end

function P.PulseApplySwipe(mode)
  local f = P.pulse
  local cd = f and f.cooldown
  if not cd then return end
  cd._sbPulseArmed = false
  cd:SetAlpha(0)
  cd:Hide()
end

function P.PulsePingReady(dur)
  local f = P.pulse
  if not f then return end
  dur = dur or 0.18
  if f._sbReadyAg then f._sbReadyAg:Stop() end
  if f._sbReadyHold then f._sbReadyHold:SetAlpha(1) end
  if f._sbReadyAg and f._sbReadyAg._sbA then
    f._sbReadyAg._sbA:SetFromAlpha(1)
    f._sbReadyAg._sbA:SetToAlpha(0)
    f._sbReadyAg._sbA:SetDuration(dur)
    f._sbReadyAg:Play()
  end
end

function P.PulseChargeExpired()
  local f = P.pulse
  if not f or not f._sbCharging or not f._sbHandStart then return false end
  local len = P.PublicNumber(f._sbGcdLen) or P.PulseGuessGcd()
  local t
  pcall(function() t = GetTime() - f._sbHandStart end)
  t = P.PublicNumber(t)
  len = P.PublicNumber(len)
  if not t or not len then return false end
  return t >= (len - 0.04)
end

function P.PulseArmGcdWatch()
  local f = P.pulse
  local w = f and f._sbGcdWatch
  if not w or P._pulsePreview then return end
  w._sbWatchArmed = true
  pcall(function()
    if C_Spell and C_Spell.GetSpellCooldownDuration and w.SetCooldownFromDurationObject then
      w:SetCooldownFromDurationObject(C_Spell.GetSpellCooldownDuration(P.GCD_SPELL), true)
      return
    end
    local start, dur, modRate = P.ReadIconCooldown("spell", P.GCD_SPELL)
    w:SetCooldown(start, dur, modRate)
  end)
end

function P.StartPulseCharge()
  local f = P.pulse
  if not f or not P.PulseShouldShow() then return end
  local fromWindow = f._sbWindowing
  f._sbCharging = true
  f._sbMissed = false
  if P.ClosePulseWindow then P.ClosePulseWindow(false) end
  f._sbWindowing = false
  local gcd = P.PulseGuessGcd()
  f._sbGcdLen = gcd
  f._sbHandStart = GetTime()
  if f._sbHideAg then f._sbHideAg:Stop() end
  f:SetAlpha(1)
  f:Show()
  if P.PulseSettle then P.PulseSettle("gcd", fromWindow) end
  if P.PulseArmGcdWatch then P.PulseArmGcdWatch() end
  if P.PaintPulseNextName then P.PaintPulseNextName() end
end

function P.StopPulseCharge()
  local f = P.pulse
  if not f then return end
  f._sbCharging = false
end

function P.TunePressPulseChrome()
  local f = P.pulse
  if not f then return end
  local on = P.PulseShouldShow()
  f:EnableMouse(on)
  if f.SetMouseClickThrough then pcall(f.SetMouseClickThrough, f, not on) end
  local g = P.PulseGain()
  local fade = 0.85
  local br, bg, bb, sr, sg, sb, cr, cg, cb = P.PulseChrome()
  local restBezel, restGlow
  if f._sbCharging then
    restBezel = 0.42 * fade * g
    restGlow = 0.18 * fade * g
  else
    restBezel = 0.38 * fade * g
    restGlow = 0.16 * fade * g
    if restBezel < 0.24 then restBezel = 0.24 end
    if restGlow < 0.10 then restGlow = 0.10 end
  end
  local winBezel = 1
  local winGlow = 0.88 * fade * g
  if winGlow > 0.95 then winGlow = 0.95 end
  local u = 0
  if P.PulseHitAmount then u = P.PulseHitAmount() end
  local bezelA = restBezel + (winBezel - restBezel) * u
  local glowA = restGlow + (winGlow - restGlow) * u
  if bezelA > 1 then bezelA = 1 end
  if glowA > 0.95 then glowA = 0.95 end
  if f._sbGlow then
    f._sbGlow:SetVertexColor(
      (sr * 0.72 + cr * 0.28) * (1 - u) + (cr * 0.35 + sr * 0.65) * u,
      (sg * 0.72 + cg * 0.28) * (1 - u) + (cg * 0.35 + sg * 0.65) * u,
      (sb * 0.72 + cb * 0.28) * (1 - u) + (cb * 0.35 + sb * 0.65) * u,
      1)
    f._sbGlow:SetAlpha(glowA)
    f._sbGlow:Show()
  end
  if f._sbBezel then
    f._sbBezel:SetVertexColor(
      (br * 0.42 + sr * 0.58) * (1 - u) + (sr * 0.35 + cr * 0.65) * u,
      (bg * 0.42 + sg * 0.58) * (1 - u) + (sg * 0.35 + cg * 0.65) * u,
      (bb * 0.42 + sb * 0.58) * (1 - u) + (sb * 0.35 + cb * 0.65) * u,
      1)
    f._sbBezel:SetAlpha(bezelA)
    f._sbBezel:Show()
  end
  if f._sbWell then f._sbWell:Hide() end
  if f._sbReadyTex then
    f._sbReadyTex:SetVertexColor(cr, cg, cb, 1)
  end
  if P.PulseTuneZone then P.PulseTuneZone() end
end

function P.ApplyPressPulseShown()
  local f = P.EnsurePressPulse()
  if not f then return end
  if P._pulsePreview then
    P.PulsePreviewStrata(f, true)
    if f._sbHideAg then f._sbHideAg:Stop() end
    f:SetAlpha(1)
    f:Show()
    P.TunePressPulseChrome()
    if not f._sbCharging and not f._sbWindowing then P.StartPulseCharge() end
    if P.PaintPulseNextName then P.PaintPulseNextName() end
    return
  end
  P.PulsePreviewStrata(f, false)
  local want = P.PulseShouldShow()
  P.TunePressPulseChrome()
  if want then
    P.PulseFade(f, true)
    P.DrivePressPulse()
    if P.PaintPulseNextName then P.PaintPulseNextName() end
    return
  end
  P.PulseFade(f, false)
end

function P.PulseEnterWindow()
  local f = P.pulse
  if not f or not P.PulseShouldShow() then return end
  if f._sbWindowing then return end
  local elapsed
  if f._sbHandStart then
    pcall(function() elapsed = GetTime() - f._sbHandStart end)
    elapsed = P.PublicNumber(elapsed)
  end
  if elapsed and elapsed < 0.12 then return end
  f._sbCharging = false
  f._sbWindowing = true
  f._sbWindowGen = (f._sbWindowGen or 0) + 1
  f._sbWindowStart = GetTime()
  if f._sbHideAg then f._sbHideAg:Stop() end
  f:SetAlpha(1)
  f:Show()
  if P.PulseSettle then P.PulseSettle("window") end
end

function P.StartPulseWindow()
  if P.PulseEnterWindow then P.PulseEnterWindow() end
end

function P.ClosePulseWindow(late)
  local f = P.pulse
  if not f then return end
  local was = f._sbWindowing
  f._sbWindowing = false
  f._sbWindowStart = nil
  f._sbWindowGen = (f._sbWindowGen or 0) + 1
  local cd = f.cooldown
  if late and cd then cd._sbPulseArmed = false end
  if not late then return end
  f._sbCharging = false
  f._sbMissed = true
  f._sbZoneLock = false
  if was or late then
    if P.PulseSettle then P.PulseSettle("miss") end
  end
  if P._pulsePreview and P.PulseShouldShow and P.PulseShouldShow() then
    if C_Timer and C_Timer.After then
      C_Timer.After(0.18, function()
        if P._pulsePreview and P.StartPulseCharge then P.StartPulseCharge() end
      end)
    end
  end
end

function P.FlashPressPulse()
  if P.PulseEnterWindow then P.PulseEnterWindow() end
end

function P.NotePressPulseCast(spellID)
  if spellID == nil then return end
  if not P.PulseShouldShow or not P.PulseShouldShow() then return end
  P._pulseCast = spellID
  if not (P.pulse or P.EnsurePressPulse()) then return end
  P.StartPulseCharge()
  if P.DrivePressPulse then P.DrivePressPulse() end
end

function P.DrivePressPulse()
  if P.PaintPulseNextName then P.PaintPulseNextName() end
  if not P.PulseShouldShow or not P.PulseShouldShow() then return end
  local f = P.pulse or P.EnsurePressPulse()
  if not f or not f:IsShown() then return end
  if P._pulsePreview then return end
  P.TunePressPulseChrome()
  if f._sbWindowing then return end
  if f._sbCharging and P.PulseChargeExpired and P.PulseChargeExpired() then
    if P.PulseEnterWindow then P.PulseEnterWindow() end
    return
  end
  if not f._sbCharging then return end
  if P.PulseArmGcdWatch then P.PulseArmGcdWatch() end
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
  -- Off-form NBA readout owns the flash. Do not paint Shred/SBA on E.
  if P.NbaEnabled and P.NbaEnabled() and P.NbaFormList and P.NbaFormList() then
    return nil
  end
  local pack = P.CurrentPack and P.CurrentPack()
  local faceSBA = false
  for _, tab in pairs(consoleTabs or {}) do
    if tab and tab.IsShown and tab:IsShown() and tab._ability and P.IsAssistedAbility(tab._ability) then
      faceSBA = true
      break
    end
  end
  if pack and pack.useBlizzardSBA == false and not faceSBA then
    local id
    pcall(function() id = P.ProfileNextCast and P.ProfileNextCast() end)
    return P.ID(P.PublicNumber(id))
  end
  if not faceSBA and not P.AssistedHighlightActive() then return nil end
  local id
  pcall(function()
    if C_AssistedCombat and C_AssistedCombat.GetNextCastSpell then
      id = C_AssistedCombat.GetNextCastSpell(false)
    end
  end)
  return P.ID(P.PublicNumber(id))
end

function P.SpellIDsMatch(a, b)
  a, b = P.ID(P.PublicNumber(a)), P.ID(P.PublicNumber(b))
  if not a or not b then return false end
  if a == b then return true end
  local function ov(id)
    local v
    pcall(function()
      if C_Spell and C_Spell.GetOverrideSpell then v = C_Spell.GetOverrideSpell(id) end
    end)
    return P.ID(P.PublicNumber(v))
  end
  local oa, ob = ov(a), ov(b)
  return (oa and oa == b) or (ob and ob == a) or (oa and ob and oa == ob)
end

function P.IconIsAssistedSBA(frame)
  local ab = frame and frame._ability
  if ab and P.IsAssistedAbility(ab) then return true end
  local abs = frame and frame.GetAttribute and P.ID(frame:GetAttribute("action"))
  if abs and P.ActionIsAssisted and P.ActionIsAssisted(abs) then return true end
  return P.IsAssistedAbility(frame and frame.spellID)
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
  local show = false
  if P.IconIsAssistedSBA(frame) then
    show = inCombat == true
  else
    show = nextID and P.IconMatchesNextCast(frame, nextID) or false
  end
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

function P.SyncAssistedFace(frame)
  P.PaintAssistedFace(frame)
end

function P.DriveAssistedHighlights()
  local nextID = P.ReadNextCastSpell()
  local inCombat = P.regenCombat == true
  for _, tab in pairs(consoleTabs or {}) do
    if tab then
      P.SyncAssistedFace(tab)
      P.ApplyAssistedHighlight(tab, nextID, inCombat)
    end
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
    if P.DriveNbaStrip then P.DriveNbaStrip() end
    if P.PaintPulseNextName then P.PaintPulseNextName() end
  end)
  w:RegisterEvent("PLAYER_ENTERING_WORLD")
  w:RegisterEvent("PLAYER_REGEN_DISABLED")
  w:RegisterEvent("PLAYER_REGEN_ENABLED")
  w:SetScript("OnEvent", function()
    wait = 0
    if P.DriveAssistedHighlights then P.DriveAssistedHighlights() end
    if P.DriveNbaStrip then P.DriveNbaStrip() end
    if P.PaintPulseNextName then P.PaintPulseNextName() end
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


-- Experimental next-best readout. Pack `nba` lists + settings toggle.
-- Hidden in nativeForm. No extra ACTIONBUTTON slots. See docs/EXPERIMENTAL.md.
function P.NbaEnabled()
  P.EnsureDB()
  return SuperBindsDB.experimentalNBA == true
end

function P.NbaNameEnabled()
  P.EnsureDB()
  return SuperBindsDB.experimentalNbaName ~= false
end

function P.NbaCollapsed()
  P.EnsureDB()
  return SuperBindsDB.nbaCollapsed == true
end

function P.NbaPinTop(f)
  f = f or P.nbaStrip
  if not f or not f.GetLeft then return end
  local left, right, top
  pcall(function()
    left = f:GetLeft()
    right = f:GetRight()
    top = f:GetTop()
  end)
  left = P.PublicNumber(left)
  right = P.PublicNumber(right)
  top = P.PublicNumber(top)
  if left == nil or right == nil or top == nil then return end
  local cx = (left + right) / 2
  f:ClearAllPoints()
  f:SetPoint("TOP", UIParent, "BOTTOMLEFT", cx, top)
end

function P.EnsureNbaArrow(f)
  f = f or P.nbaStrip
  if not f then return nil end
  if f._sbArrow then return f._sbArrow end
  local arrow = CreateFrame("Button", nil, f)
  arrow:SetSize(16, 16)
  arrow:SetPoint("TOP", 0, -3)
  arrow:SetFrameLevel((f:GetFrameLevel() or 90) + 6)
  if f.SetClipsChildren then pcall(f.SetClipsChildren, f, false) end
  arrow:EnableMouse(true)
  arrow:RegisterForClicks("LeftButtonUp")
  arrow:RegisterForDrag("LeftButton")
  arrow:SetScript("OnDragStart", function() f:StartMoving() end)
  arrow:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    SavePosition("nba", f)
  end)
  local tex = arrow:CreateTexture(nil, "ARTWORK")
  tex:SetAllPoints()
  tex:SetVertexColor(unpack(P.Visual.brass or {0.68, 0.55, 0.35, 1}))
  arrow._sbTex = tex
  arrow:SetScript("OnClick", function()
    if Locked() then
      P.Report("Leave combat to hide or show NEXT BEST.")
      return
    end
    SuperBindsDB.nbaCollapsed = not P.NbaCollapsed()
    if P.ApplyNbaCollapse then P.ApplyNbaCollapse() end
  end)
  arrow:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if P.NbaCollapsed() then
      GameTooltip:SetText("Show NEXT BEST")
    else
      GameTooltip:SetText("Hide NEXT BEST")
    end
    GameTooltip:Show()
  end)
  arrow:SetScript("OnLeave", function() GameTooltip:Hide() end)
  f._sbArrow = arrow
  return arrow
end

function P.ApplyNbaCollapse()
  local f = P.nbaStrip
  if not f then return end
  P.EnsureNbaArrow(f)
  if f.SetClipsChildren then pcall(f.SetClipsChildren, f, false) end
  local collapsed = P.NbaCollapsed()
  local arrow = f._sbArrow
  if arrow and arrow._sbTex then
    if collapsed then
      arrow._sbTex:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    else
      arrow._sbTex:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
    end
    arrow:Show()
    arrow:ClearAllPoints()
    arrow:SetPoint("TOP", 0, -3)
  end
  if f._sbTitle then
    if collapsed then f._sbTitle:Hide() else f._sbTitle:Show() end
  end
  for _, b in ipairs(f.buttons or {}) do
    if collapsed then
      b:Hide()
    elseif b.spellID then
      b:Show()
    end
  end
  if P.NbaPinTop then P.NbaPinTop(f) end
  if collapsed then
    f:SetBackdropColor(0, 0, 0, 0)
    f:SetBackdropBorderColor(0, 0, 0, 0)
    f:SetSize(24, 22)
    if f._sbGrip then
      f._sbGrip:SetHeight(16)
      f._sbGrip:EnableMouse(false)
    end
  else
    if P.Visual and P.Visual.ink then
      f:SetBackdropColor(unpack(P.Visual.ink))
    end
    if P.Visual and P.Visual.brass then
      f:SetBackdropBorderColor(unpack(P.Visual.brass))
    end
    if f._sbTitle then
      f._sbTitle:ClearAllPoints()
      f._sbTitle:SetPoint("TOP", 0, -20)
    end
    if f._sbGrip then
      f._sbGrip:EnableMouse(true)
      f._sbGrip:ClearAllPoints()
      f._sbGrip:SetPoint("TOPLEFT", 0, -18)
      f._sbGrip:SetPoint("TOPRIGHT", 0, -18)
      f._sbGrip:SetHeight(16)
    end
    if not Locked() and P._nbaShown then
      local n = #P._nbaShown
      local pad, gap, btn, header = 6, 4, 36, 34
      local w = pad * 2 + n * btn + (n - 1) * gap
      if w < 88 then w = 88 end
      f:SetSize(w, header + btn + pad)
    end
  end
end

function P.NbaFormList(form)
  local pack = P.CurrentPack and P.CurrentPack()
  form = form or (P.DrawerForm and P.DrawerForm()) or (P.PackFormNow and P.PackFormNow())
  if type(pack) ~= "table" or type(pack.nba) ~= "table" or not P.Text(form) then return nil end
  local native = P.PackNativeForm and P.PackNativeForm(pack)
  if native and form == native then return nil end
  local list = pack.nba[form]
  if type(list) ~= "table" or #list == 0 then return nil end
  return list, pack
end

function P.NbaResolve(form)
  local list = P.NbaFormList(form)
  if not list then return nil end
  local rows = {}
  for _, rule in ipairs(list) do
    if type(rule) == "table" and type(rule.spell) == "table" then
      local name, id = Known(unpack(rule.spell))
      if id and not (P.NeverSuggest and P.NeverSuggest(id, name)) then
        rows[#rows + 1] = {
          name = name, id = id, label = P.Text(rule.label) or name,
          loop = rule.loop == true,
          combo = rule.combo,
        }
      end
    end
  end
  if #rows == 0 then return nil end
  rows.comboMax = P.PublicNumber(list.comboMax) or 5
  return rows
end

function P.NbaLiveKey(id, name)
  local function hit(frame)
    if not frame or not frame.IsShown or not frame:IsShown() then return nil end
    if P.SpellIDsMatch and P.SpellIDsMatch(frame.spellID, id) then
      local t = frame.keyText and frame.keyText.GetText and frame.keyText:GetText()
      if P.Text(t) then return t end
    end
    local ab = frame._ability
    if type(ab) == "table" then
      if P.SpellIDsMatch and P.SpellIDsMatch(ab.id, id) then
        local t = frame.keyText and frame.keyText.GetText and frame.keyText:GetText()
        if P.Text(t) then return t end
      end
      local nm = P.Text(ab.name) or P.Text(ab.label)
      if name and nm and nm == name then
        local t = frame.keyText and frame.keyText.GetText and frame.keyText:GetText()
        if P.Text(t) then return t end
      end
    end
  end
  for _, tab in pairs(consoleTabs or {}) do
    local k = hit(tab)
    if k then return k end
  end
  for _, b in ipairs(allMenuButtons or {}) do
    local k = hit(b)
    if k then return k end
  end
  return "Click"
end

function P.EnsureNbaStrip()
  if P.nbaStrip then
    P.EnsureNbaArrow(P.nbaStrip)
    return P.nbaStrip
  end
  local f = CreateFrame("Frame", "SuperBindsNbaStrip", UIParent, "BackdropTemplate")
  f:SetSize(200, 58)
  f:SetFrameStrata("HIGH")
  f:SetFrameLevel(90)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  if f.SetClipsChildren then pcall(f.SetClipsChildren, f, false) end
  f:Hide()
  P.VisualPanel(f, P.Visual.ink, P.Visual.brass)
  f:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  f:SetBackdropColor(unpack(P.Visual.ink))
  f:SetBackdropBorderColor(unpack(P.Visual.brass))
  local grip = CreateFrame("Frame", nil, f)
  grip:SetPoint("TOPLEFT", 0, -18)
  grip:SetPoint("TOPRIGHT", 0, -18)
  grip:SetHeight(16)
  grip:EnableMouse(true)
  grip:RegisterForDrag("LeftButton")
  grip:SetScript("OnDragStart", function() f:StartMoving() end)
  grip:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    SavePosition("nba", f)
  end)
  f._sbGrip = grip
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  title:SetPoint("TOP", 0, -20)
  P.VisualFont(title, 10, P.Visual.muted)
  title:SetText("NEXT BEST")
  f._sbTitle = title
  f.buttons = {}
  P.nbaStrip = f
  P.EnsureNbaArrow(f)
  local saved = SuperBindsDB.pos and SuperBindsDB.pos.nba
  f:ClearAllPoints()
  if type(saved) == "table" and saved[1] and P.Number(saved[3]) and P.Number(saved[4]) then
    f:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
  else
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
  end
  return f
end

function P.NbaMakeButton(strip, i)
  local b = strip.buttons[i]
  if b then return b end
  b = CreateFrame("Button", "SuperBindsNba_" .. i, strip,
    "SecureActionButtonTemplate, BackdropTemplate")
  b:SetSize(36, 36)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  DressIcon(b, b.icon)
  b.keyText = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  b.keyText:SetPoint("BOTTOM", 0, 1)
  P.VisualFont(b.keyText, 9, P.Visual.text, "OUTLINE")
  if b.RegisterForClicks then b:RegisterForClicks("AnyUp", "AnyDown") end
  if b.HookScript then
    b:HookScript("OnClick", function(self)
      if self.spellID and P.NbaNoteCast then pcall(P.NbaNoteCast, self.spellID, true) end
    end)
  end
  strip.buttons[i] = b
  return b
end

function P.NbaHide()
  local f = P.nbaStrip
  if f then f:Hide() end
end

function P.LayoutNbaStrip()
  if not P.NbaEnabled() then P.NbaHide(); return end
  local rows = P.NbaResolve()
  if not rows then
    P._nbaShown = nil
    P._nbaFormAttributed = nil
    P.NbaHide()
    return
  end
  local f = P.EnsureNbaStrip()
  local n = #rows
  local pad, gap, btn, header = 6, 4, 36, 34
  local w = pad * 2 + n * btn + (n - 1) * gap
  if w < 88 then w = 88 end
  if not P.NbaCollapsed() then
    if P.NbaPinTop then P.NbaPinTop(f) end
    f:SetSize(w, header + btn + pad)
  end
  for i = 1, n do
    local row = rows[i]
    local b = P.NbaMakeButton(f, i)
    b:ClearAllPoints()
    b:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", pad + (i - 1) * (btn + gap), pad)
    b:Show()
    b.spellID = row.id
    b._ability = { id = row.id, name = row.name, label = row.label }
    if b.icon then b.icon:SetTexture(SpellIcon(row.id, row.name)) end
    if b.keyText then b.keyText:SetText(P.NbaLiveKey(row.id, row.name) or "Click") end
    P.EnsureIconCooldown(b)
    if not Locked() then
      b:SetAttribute("type", "spell")
      b:SetAttribute("spell", row.id)
    end
  end
  for i = n + 1, #(f.buttons or {}) do
    local b = f.buttons[i]
    if b then
      b:Hide()
      b.spellID = nil
      b._ability = nil
      if not Locked() then
        b:SetAttribute("type", nil)
        b:SetAttribute("spell", nil)
      end
    end
  end
  P._nbaShown = rows
  P._nbaFormAttributed = (P.DrawerForm and P.DrawerForm()) or (P.PackFormNow and P.PackFormNow())
  P._nbaComboMax = P.PublicNumber(rows.comboMax) or 5
  P._nbaCp = 0
  P._nbaOpened = false
  P._nbaProwled = false
  P._nbaSpendI = 1
  P.NbaSetCursor(1)
  f:Show()
  if P.ApplyNbaCollapse then P.ApplyNbaCollapse() end
  if P.DriveNbaStrip then P.DriveNbaStrip() end
  if P.PaintPulseNextName then P.PaintPulseNextName() end
end

function P.RefreshNbaStrip()
  if not P.NbaEnabled() then P.NbaHide(); return end
  local form = (P.DrawerForm and P.DrawerForm()) or (P.PackFormNow and P.PackFormNow())
  local list = P.NbaFormList(form)
  if not list then P.NbaHide(); return end
  if Locked() then
    local f = P.nbaStrip
    if f and P._nbaFormAttributed == form and P._nbaShown then
      f:Show()
      if P.ApplyNbaCollapse then P.ApplyNbaCollapse() end
    else
      P.NbaHide()
    end
    return
  end
  P.LayoutNbaStrip()
end

function P.NbaSetCursor(i)
  P._nbaCursor = i or 1
end

function P.NbaLoopRows()
  local rows = P._nbaShown
  if not rows then return nil end
  local loop = {}
  for _, row in ipairs(rows) do
    if row.loop then loop[#loop + 1] = row end
  end
  if #loop == 0 then return rows end
  return loop
end

function P.NbaRowSpend(row)
  if not row then return false end
  if row.combo == "spend" then return true end
  if row.combo == "build" or row.combo == "open" or row.combo == "stealth" then return false end
  local n = row.label or row.name or ""
  return n == "Rip" or n == "Ferocious Bite"
end

function P.NbaRowBuild(row)
  if not row then return false end
  if row.combo == "spend" or row.combo == "stealth" then return false end
  if row.combo == "build" or row.combo == "open" then return true end
  local n = row.label or row.name or ""
  return n == "Rake" or n == "Shred"
end

function P.NbaRowOpen(row)
  if not row then return false end
  if row.combo == "open" then return true end
  if row.combo then return false end
  local n = row.label or row.name or ""
  return n == "Rake"
end

function P.NbaRowFill(row)
  if not row then return false end
  if row.combo == "open" or row.combo == "spend" or row.combo == "stealth" then return false end
  if row.combo == "build" then return true end
  local n = row.label or row.name or ""
  return n == "Shred"
end

function P.NbaRowStealth(row)
  return row and row.combo == "stealth"
end

function P.NbaFindRow(kind)
  local loop = P.NbaLoopRows()
  if not loop then return nil end
  for _, row in ipairs(loop) do
    if kind == "spend" and P.NbaRowSpend(row) then return row end
    if kind == "open" and P.NbaRowOpen(row) then return row end
    if kind == "fill" and P.NbaRowFill(row) then return row end
    if kind == "stealth" and P.NbaRowStealth(row) then return row end
  end
end

function P.NbaIsStealthed()
  local v
  pcall(function()
    if IsStealthed then v = IsStealthed() end
  end)
  if issecretvalue and issecretvalue(v) then return nil end
  if v == true then return true end
  if v == false then return false end
  return nil
end

function P.NbaStealthReady(row)
  if not row or not row.id then return false end
  if P._nbaProwled or P._nbaOpened or (P.PublicNumber(P._nbaCp) or 0) > 0 then return false end
  local stealthed = P.NbaIsStealthed()
  if stealthed == true then
    P._nbaProwled = true
    return false
  end
  local ready
  pcall(function() ready = P.SpellReady(row.id) end)
  if ready == false then return false end
  if ready == true then return true end
  return P.regenCombat ~= true
end

function P.NbaEventName(spellID)
  local name
  pcall(function()
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    if type(info) == "table" then name = P.Text(info.name) end
  end)
  return name
end

function P.NbaRowMatches(row, spellID)
  if not row then return false end
  local id = P.ID(P.PublicNumber(spellID))
  if id and P.SpellIDsMatch and P.SpellIDsMatch(row.id, id) then return true end
  local n = P.NbaEventName(spellID)
  if n and ((row.name and n == row.name) or (row.label and n == row.label)) then return true end
  return false
end

function P.NbaComboNeed()
  return P.PublicNumber(P._nbaComboMax) or 5
end

function P.NbaSpendRows()
  local loop = P.NbaLoopRows()
  if not loop then return nil end
  local spend = {}
  for _, row in ipairs(loop) do
    if P.NbaRowSpend(row) then spend[#spend + 1] = row end
  end
  if #spend == 0 then return nil end
  return spend
end

function P.NbaSpendNow()
  local spend = P.NbaSpendRows()
  if not spend then return nil end
  local i = P.PublicNumber(P._nbaSpendI) or 1
  if i < 1 or i > #spend then i = 1 end
  P._nbaSpendI = i
  return spend[i]
end

function P.NbaAdvanceSpend(row)
  local spend = P.NbaSpendRows()
  if not spend then
    P._nbaSpendI = 1
    return
  end
  local i = 1
  for n, r in ipairs(spend) do
    if r == row then i = n; break end
  end
  P._nbaSpendI = (i % #spend) + 1
end

function P.NbaNextId()
  local loop = P.NbaLoopRows()
  if not loop then return nil end
  local stealth = P.NbaFindRow("stealth")
  if stealth and P.NbaStealthReady(stealth) then return stealth.id, stealth end
  local need = P.NbaComboNeed()
  local cp = P.PublicNumber(P._nbaCp) or 0
  local row
  if cp >= need then
    row = P.NbaSpendNow()
  elseif P._nbaOpened then
    row = P.NbaFindRow("fill") or P.NbaFindRow("open")
  else
    row = P.NbaFindRow("open") or P.NbaFindRow("fill")
  end
  return row and row.id, row
end

function P.NbaApplyCombo(row, fromClick)
  if not row then return end
  if P.NbaRowStealth(row) then
    P._nbaProwled = true
    return
  end
  local need = P.NbaComboNeed()
  local cp = P.PublicNumber(P._nbaCp) or 0
  if P.NbaRowBuild(row) then
    P._nbaCp = math.min(need, cp + 1)
    P._nbaOpened = true
  elseif P.NbaRowSpend(row) then
    if fromClick and cp < need then return end
    P._nbaCp = 0
    P._nbaOpened = true
    P.NbaAdvanceSpend(row)
  end
end

function P.NbaNoteCast(spellID, fromClick)
  if not P.NbaEnabled() or not P._nbaShown then return end
  for _, row in ipairs(P._nbaShown) do
    if P.NbaRowMatches(row, spellID) then
      P.NbaApplyCombo(row, fromClick)
      return
    end
  end
end

function P.DriveNbaCooldowns()
  local f = P.nbaStrip
  if not f or not f:IsShown() then return end
  for _, b in ipairs(f.buttons or {}) do
    if b:IsShown() then P.ApplyIconCooldown(b) end
  end
end

function P.DriveNbaStrip()
  local f = P.nbaStrip
  if not f or not f:IsShown() then return end
  local nextID = P.NbaNextId()
  local inCombat = P.regenCombat == true
  for _, b in ipairs(f.buttons or {}) do
    if b:IsShown() then
      P.ApplyAssistedHighlight(b, nextID, inCombat)
    end
  end
  if P.PaintPulseNextName then P.PaintPulseNextName() end
end

-- Wheel totems: show the carved art above the bar while that spell is off cooldown.
P.TOTEM_READY = {
}

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
  local show = console:IsShown() and P.Visual.endcapEyes and P.AscendanceReadyState()
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
    -- Narrower grab so overlapping sculptures stay reachable.
    -- Small frames cannot spare a 39px inset.
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
  SuperBindsDB.totemPos = SuperBindsDB.totemPos or {}
  SuperBindsDB.totemPos[frame._sbIndex] = { x = x, y = y }
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
  local saved = SuperBindsDB.totemPos and SuperBindsDB.totemPos[frame._sbIndex]
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
    local f = CreateFrame("Frame", "SuperBindsTotemPlace"..i, UIParent)
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
    local glowFile = "Interface\\AddOns\\SuperBinds\\Media\\TotemFillTip"
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
  local b = CreateFrame("Button", "SuperBindsBindMode", UIParent, "BackdropTemplate")
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
  console = CreateFrame("Frame", "SuperBindsConsole", UIParent)
  console:SetSize(10, TAB_H)
  console:SetMovable(true)
  console:SetClampedToScreen(true)
  -- Above faded ActionButtons. Those stay mouse-enabled when the bar is
  -- shown, and used to sit on top of mouse-bound tabs.
  console:SetFrameStrata("HIGH")
  console:SetFrameLevel(50)
  P.SelectClassTheme()
  P.SkinConsole(console)

  local saved = SuperBindsDB.pos and SuperBindsDB.pos.console
  if saved then
    console:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
  elseif MainMenuBar then
    console:SetPoint("BOTTOM", MainMenuBar, "TOP", 0, 8)
  else
    console:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 120)
  end

  -- Always-visible move handle. Shift-drag on a tab picks up the ability;
  -- this grip (or Ctrl-drag a tab) moves the whole console.
  local grip = CreateFrame("Button", "SuperBindsMoveGrip", console, "SecureActionButtonTemplate")
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

  local rail = CreateFrame("Button", "SuperBindsMoveRail", console, "SecureActionButtonTemplate")
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
  local name = "SuperBindsMenu_" .. famTag .. "_" .. i
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
  local saved = SuperBindsDB.pos and SuperBindsDB.pos.bind
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
  SuperBindsDB.pos = SuperBindsDB.pos or {}
  SuperBindsDB.pos.bind = { "BOTTOMLEFT", "BOTTOMLEFT", x, y }
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
    handle = CreateFrame("Frame", "SuperBindsBindGrip", frame)
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
  tab = CreateFrame("Button", "SuperBindsTab_" .. famIndex, parent,
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

  local menu = CreateFrame("Frame", "SuperBindsMenu_" .. famIndex, tab,
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
  if not primary or (P.IsEmptyPrimary and P.IsEmptyPrimary(primary)) then
    tab.icon:SetTexture(134400)
    local key = primary and (ShortKey(primary.key) or primary.key) or ""
    if tab.keyText then
      StyleKeyText(tab.keyText)
      tab.keyText:SetText(key)
    end
    tab.tipKey = (key ~= "") and key or nil
    return
  end
  tab.icon:SetTexture(primary.icon or 134400)
  tab.equipmentSlot, tab._sbEquipmentSlot = primary.equipmentSlot, primary.equipmentSlot
  if primary.equipmentSlot then tab.itemID = primary.tooltipItemID end
  tab.tipText = primary.label
  tab.tipKey = ShortKey(primary.key) or primary.key
  tab.spellID = P.ID(primary.id) or tab.spellID
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
  if type(SuperBindsDB.custom) ~= "table" then SuperBindsDB.custom = {} end
  if type(SuperBindsDB.custom[tag]) ~= "table" then SuperBindsDB.custom[tag] = {} end
  local custom = SuperBindsDB.custom[tag]
  if type(custom.added) ~= "table" then custom.added = {} end
  if type(custom.hidden) ~= "table" then custom.hidden = {} end
  if type(custom.hiddenForms) ~= "table" then custom.hiddenForms = {} end
  if type(custom.addedForms) ~= "table" then custom.addedForms = {} end
  if type(custom.orderForms) ~= "table" then custom.orderForms = {} end
  return SuperBindsDB.custom[tag]
end

function P.DrawerForm()
  -- Extras follow the shapeshift, not the bar page. Ground travel shares
  -- caster slots (use="caster") but keeps its own added/hidden lists.
  local form = P.BonusBarForm and P.BonusBarForm()
  if not form then form = P.CurrentForm and P.CurrentForm() end
  if not form then form = P.FormFromAuras and P.FormFromAuras() end
  form = P.Text(form)
  if not form or form == "caster" then
    local sky = P.UnclaimedBonusOffset and P.UnclaimedBonusOffset()
    if sky then
      local idxOk, index = pcall(GetShapeshiftForm)
      local shifted = idxOk and P.Number(index) and index > 0
      if not shifted then
        local pack = P.CurrentPack and P.CurrentPack()
        local aura = P.FormFromAuras and P.FormFromAuras()
        form = P.Text(aura)
        if not form and pack and type(pack.forms) == "table" and pack.forms.travel then
          form = "travel"
        end
      end
    end
  end
  if form then
    P._drawerForm = form
    return form
  end
  return P.Text(P._drawerForm)
end

function P.ExtraIsHidden(custom, ability, form)
  if type(custom) ~= "table" then return false end
  local key = P.AbilityKey(ability)
  form = P.Text(form) or (P.DrawerForm and P.DrawerForm())
  if not key or not form then return false end
  local byForm = custom.hiddenForms
  return type(byForm) == "table" and type(byForm[form]) == "table"
    and byForm[form][key] == true
end

function P.UnhideExtra(tag, ability, form)
  local key = P.AbilityKey(ability)
  form = P.Text(form) or (P.DrawerForm and P.DrawerForm())
  if not key or not P.Text(tag) or not form then return false end
  local c = SuperBindsDB.custom and SuperBindsDB.custom[tag]
  if type(c) ~= "table" or type(c.hiddenForms) ~= "table" then return false end
  if type(c.hiddenForms[form]) ~= "table" or c.hiddenForms[form][key] ~= true then return false end
  c.hiddenForms[form][key] = nil
  return true
end

function P.MigrateAddedPerForm(custom, form)
  if type(custom) ~= "table" then return end
  form = P.Text(form) or (P.DrawerForm and P.DrawerForm())
  if not form then return end
  custom.addedForms = custom.addedForms or {}
  if type(custom.addedForms[form]) ~= "table" then custom.addedForms[form] = {} end
  if type(custom.added) == "table" and #custom.added > 0 then
    local dest = custom.addedForms[form]
    for _, a in ipairs(custom.added) do
      dest[#dest + 1] = a
    end
    custom.added = {}
  end
  if type(custom.hidden) == "table" then
    custom.hiddenForms = custom.hiddenForms or {}
    if type(custom.hiddenForms[form]) ~= "table" then custom.hiddenForms[form] = {} end
    for k, v in pairs(custom.hidden) do
      if v == true then custom.hiddenForms[form][k] = true end
    end
    custom.hidden = {}
  end
  custom.addedPerForm = true
end

function P.HideExtra(tag, ability, form)
  if not P.Text(tag) then return false end
  local key = P.AbilityKey(ability)
  form = P.Text(form) or (P.DrawerForm and P.DrawerForm())
  if not key or not form then return false end
  local c = EnsureCustom(tag)
  c.hiddenForms = c.hiddenForms or {}
  c.hiddenForms[form] = c.hiddenForms[form] or {}
  if c.hiddenForms[form][key] == true then return false end
  c.hiddenForms[form][key] = true
  return true
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
    if P.IsAssistedAbility(id, name) or P.IsAssistedToken(id) or P.IsAssistedToken(name) then
      return P.AssistedAbility()
    end
    if not name then return nil end
    local pubId = P.ID(P.PublicNumber(id))
    if not pubId and type(info) == "table" then pubId = P.ID(P.PublicNumber(info.spellID)) end
    if not pubId then pubId = BOOK[name] end
    if P.IsAssistedAbility(pubId, name) then return P.AssistedAbility() end
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
    if P.ActionIsAssisted and P.ActionIsAssisted(slot) then return P.AssistedAbility() end
    local actionType, id, sub
    pcall(function() actionType, id, sub = GetActionInfo(slot) end)
    actionType = pub(actionType)
    if P.IsAssistedToken(actionType) or P.IsAssistedToken(id) or P.IsAssistedToken(pub(sub)) then
      return P.AssistedAbility()
    end
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
    if P.CursorIsAssisted and P.CursorIsAssisted() then return P.AssistedAbility() end
    local pubSpell, pubA, pubB = pub(spellID), pub(a), pub(b)
    if P.IsAssistedToken(pubSpell) or P.IsAssistedToken(pubA) or P.IsAssistedToken(pubB) then
      return P.AssistedAbility()
    end
    if P.ID(pubSpell) then return fromSpellID(pubSpell) end
    if pubB == "spell" or pubB == "pet" then
      local fromSlot = fromBookSlot(pubA)
      if fromSlot then return fromSpellID(fromSlot) end
    end
    local fromRaw = fromSpellID(spellID)
    if fromRaw then return fromRaw end
    if pubB ~= "spell" and pubB ~= "pet" then return fromSpellID(a) end
    -- Secret SBA from the rune book: book slot + id both fail closed.
    if P.CursorIsAssisted and P.CursorIsAssisted() then return P.AssistedAbility() end
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
-- Shift-drag pickup used to re-drop while Shift was held.
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
    local f = CreateFrame("Frame", "SuperBindsDragGhost", UIParent, "BackdropTemplate")
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
  local f = CreateFrame("Frame", "SuperBindsDropRail", UIParent, "BackdropTemplate")
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
  if ak ~= nil and ak == bk then return true end
  a, b = NormalizeAbility(a), NormalizeAbility(b)
  if not a or not b then return false end
  if a.sba and b.sba then return true end
  local an = P.Text(a.name) or P.Text(a.label)
  local bn = P.Text(b.name) or P.Text(b.label)
  if an and bn and an:lower() == bn:lower() then return true end
  return false
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

local function FormNow()
  if P.DrawerForm then return P.DrawerForm() end
  return PackFormNow and PackFormNow()
end

local function AddedList(c, form)
  if type(c) ~= "table" then return nil end
  form = P.Text(form) or FormNow()
  if not form then return nil end
  c.addedForms = c.addedForms or {}
  if type(c.addedForms[form]) ~= "table" then c.addedForms[form] = {} end
  return c.addedForms[form]
end

local function InAdded(tag, ability)
  local c = SuperBindsDB.custom and SuperBindsDB.custom[tag]
  if not c or not ability then return false end
  local list = AddedList(c, FormNow())
  if type(list) ~= "table" then return false end
  for _, e in ipairs(list) do
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
  local form = FormNow()
  if not form then return false end
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
  c.orderForms = c.orderForms or {}
  c.orderForms[form] = order
  return true
end

local function ApplyExtraOrder(tag, extras)
  local c = SuperBindsDB.custom and SuperBindsDB.custom[tag]
  if type(c) ~= "table" then return extras end
  local form = FormNow()
  local order = form and type(c.orderForms) == "table" and c.orderForms[form]
  if type(order) ~= "table" or #order == 0 then return extras end
  local used, out = {}, {}
  for _, saved in ipairs(order) do
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
  local function bump(list)
    if type(list) ~= "table" then return false end
    for i, e in ipairs(list) do
      if SameAbility(e, oldAb) then
        if newAb then list[i] = AbilitySnapshot(newAb) else table.remove(list, i) end
        return true
      end
    end
  end
  return bump(AddedList(c, FormNow()))
end

local function RemoveExtra(tag, ability, quiet)
  local c = SuperBindsDB.custom and SuperBindsDB.custom[tag]
  if not c or not ability then return false end
  local list = AddedList(c, FormNow())
  if type(list) ~= "table" then return false end
  local removed = false
  for i = #list, 1, -1 do
    if SameAbility(list[i], ability) then
      table.remove(list, i)
      removed = true
    end
  end
  if removed and not quiet then
    print("|cff0070ddSuper Binds:|r removed |cffffffff" .. (ability.label or ability.name or "?") .. "|r from " .. tag)
  end
  return removed
end

local function ClearModAbility(bindKey)
  if not bindKey or not SuperBindsDB.mods or not SuperBindsDB.mods[bindKey] then return false end
  SuperBindsDB.mods[bindKey] = nil
  print("|cff0070ddSuper Binds:|r " .. ShortKey(bindKey) .. " reset to stock.")
  return true
end

local function AddExtra(tag, ability, quiet)
  ability = NormalizeAbility(ability)
  if Locked() or not ability or not P.Text(tag) then return false end
  local form = FormNow()
  if not form then
    if not quiet then
      print("|cff0070ddSuper Binds:|r extras stay on one stance. Shift into cat, bear, or caster first.")
    end
    return false
  end
  local c = EnsureCustom(tag)
  if P.MigrateAddedPerForm then P.MigrateAddedPerForm(c, form) end
  if P.UnhideExtra and P.UnhideExtra(tag, ability, form) then
    if not quiet then
      print("|cff0070ddSuper Binds:|r restored |cffffffff" .. (ability.label or ability.name or "?") .. "|r on " .. tag .. " (" .. form .. ").")
    end
    return true
  end
  local list = AddedList(c, form)
  if type(list) ~= "table" then return false end
  for _, e in ipairs(list) do
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
  list[#list + 1] = AbilitySnapshot(ability)
  if not quiet then
    print("|cff0070ddSuper Binds:|r added |cffffffff" .. (ability.label or "?") .. "|r to " .. tag .. " (" .. (form or "this form") .. ", click). Drop on a keyed icon to bind it.")
  end
  return true
end

function P.IsEmptyPrimary(ab)
  return ab == false or (type(ab) == "table" and ab.empty == true)
end

function P.EmptyPrimary()
  return { empty = true, kind = "empty", name = "Empty", label = "Empty", icon = 134400 }
end

function P.CustomPrimaryFor(tag, form)
  if not P.Text(tag) then return nil end
  local c = SuperBindsDB.custom and SuperBindsDB.custom[tag]
  if type(c) ~= "table" then return nil end
  form = form or PackFormNow()
  if type(c.formPrimary) == "table" and form and c.formPrimary[form] ~= nil then
    return c.formPrimary[form]
  end
  -- Form-bar families are stock per stance. A leftover global c.primary
  -- (old Attack↔SBA swap) must not paint every face.
  if P.FamilyHasBars(tag) then return nil end
  return c.primary
end

function P.MigrateFormPrimary(tag)
  if not P.Text(tag) or not P.FamilyHasBars(tag) then return end
  local c = SuperBindsDB.custom and SuperBindsDB.custom[tag]
  if type(c) ~= "table" then return end
  if type(c.formPrimary) == "table" then
    for _, ab in pairs(c.formPrimary) do
      if ab then
        c.primary = nil
        return
      end
    end
  end
  if not c.primary then return end
  local p = NormalizeAbility(c.primary)
  if not p then
    c.primary = nil
    return
  end
  local form
  if P.IsAssistedAbility(p) then
    form = (P.PackNativeForm and P.PackNativeForm()) or PackFormNow()
  else
    form = PackFormNow()
  end
  if not form then return end
  c.formPrimary = c.formPrimary or {}
  c.formPrimary[form] = p
  c.primary = nil
end

local function SetCustomPrimary(tag, ability, quiet)
  ability = NormalizeAbility(ability)
  if Locked() or not ability or not P.Text(tag) then return false end
  local c = EnsureCustom(tag)
  ability = NormalizeAbility(ability) or AbilitySnapshot(ability)
  if P.FamilyHasBars(tag) then
    local form = PackFormNow()
    if not form then return false end
    c.formPrimary = c.formPrimary or {}
    c.formPrimary[form] = ability
  else
    c.primary = ability
  end
  local added = AddedList(c, FormNow())
  if type(added) == "table" then
    for i = #added, 1, -1 do
      if SameAbility(added[i], ability) then table.remove(added, i) end
    end
  end
  if not quiet then
    print("|cff0070ddSuper Binds:|r " .. tag .. " primary is now |cffffffff" .. (ability.label or "?") .. "|r")
  end
  return true
end

-- Spellbook / rune-book drop: PlaceAction the live cursor onto this form's
-- absolute slot, then log formPrimary from the slot. Overlay is not the
-- drop authority. Do not PickupSpell(SBA) — Assisted Combat is not a normal spell.
function P.CommitCursorToTab(tab, force)
  if Locked() or not tab or not P.Text(tab.famTag) then return false end
  if P._placingCursor then return false end
  if not force then
    if not (P.CursorHasPickup and P.CursorHasPickup())
      and not (P.CursorIsAssisted and P.CursorIsAssisted()) then
      return false
    end
  end
  local rel = tonumber(tab.GetAttribute and tab:GetAttribute("relslot"))
  if not rel then
    local spec = P.FamilyBarSpec and P.FamilyBarSpec(tab.famTag)
    rel = spec and tonumber(spec.slot)
  end
  local abs = (rel and P.LiveActionSlot and P.LiveActionSlot(rel))
    or P.ID(tab.GetAttribute and tab:GetAttribute("action"))
  if not abs then return false end
  P._placingCursor = true
  local displaced = tab._ability and NormalizeAbility(tab._ability)
  PlaceAction(abs)
  KEEP[abs] = true
  pcall(ClearCursor)
  local placed
  if P.ActionIsAssisted and P.ActionIsAssisted(abs) then
    placed = P.AssistedAbility()
  else
    placed = P.NativeAbility and P.NativeAbility(abs)
  end
  if not placed then
    P._placingCursor = false
    return false
  end
  SetCustomPrimary(tab.famTag, placed, true)
  if displaced and P.AbilityKey(displaced) ~= P.AbilityKey(placed) then
    AddExtra(tab.famTag, displaced, true)
  end
  P._placingCursor = false
  local into = P.Visual.families[tab.famTag] or tab.famTag
  local notice = (placed.label or placed.name or "Ability") .. " on " .. into
  if displaced then
    notice = notice .. " · " .. (displaced.label or displaced.name or "Ability") .. " moved to the family"
  end
  P.dropRefreshQueued = true
  C_Timer.After(0, function()
    P.dropRefreshQueued = false
    if RefreshLayout then RefreshLayout(true) end
    if P.DropNotice then P.DropNotice(notice) end
  end)
  return true
end

function P.ClearFamilySpellBinds(tag, ability, onlyKey)
  local names = {}
  local function addName(n)
    if P.Text(n) then names[n] = true end
  end
  if type(ability) == "table" then
    addName(ability.name)
    addName(ability.label)
  end
  local pack = P.CurrentPack and P.CurrentPack()
  for _, fam in ipairs((pack and pack.families) or {}) do
    if fam.tag == tag and type(fam.bars) == "table" then
      for _, spec in pairs(fam.bars) do
        if type(spec) == "table" then
          addName(spec.label)
          if type(spec.spell) == "table" then
            for _, sid in ipairs(spec.spell) do
              local n
              if Known then n = Known(sid) end
              if not P.Text(n) and P.ID(sid) and C_Spell and C_Spell.GetSpellName then
                n = C_Spell.GetSpellName(sid)
              end
              addName(n)
            end
          end
        end
      end
    end
  end
  for n in pairs(names) do
    for _, k in ipairs({ GetBindingKey("SPELL " .. n) }) do
      if not onlyKey or k == onlyKey then pcall(SetBinding, k) end
    end
  end
end

-- Which native column currently owns this hotkey (Q, E, M4, …).
-- Drawer extras that already have the chord are not bar owners.
function P.BarFaceForKey(key)
  if not P.Text(key) then return nil end
  local slot
  local act = GetBindingAction and GetBindingAction(key)
  if type(act) == "string" then
    slot = tonumber(act:match("^ACTIONBUTTON(%d+)$"))
  end
  if not slot then
    for action, saved in pairs(SuperBindsDB.barBinds or {}) do
      if saved == key then
        slot = tonumber(tostring(action):match("ACTIONBUTTON(%d+)"))
        if slot then break end
      end
    end
  end
  if not slot then
    local cmd = BAR_BINDS[key]
    if type(cmd) == "string" then
      slot = tonumber(cmd:match("ACTIONBUTTON(%d+)"))
    end
  end
  for _, tab in ipairs(consoleTabs) do
    local tabSlot = P.BarSlotOf(tab)
    if tabSlot and (tabSlot == slot or P.LiveFaceKey(tab) == key or tab._sbDefaultKey == key) then
      return tab, tabSlot, tab.famTag, tab._ability
    end
  end
end

function P.ResolveBarBind(frame, key)
  if not frame then return end
  local ability = NormalizeAbility and NormalizeAbility(frame._ability) or frame._ability
  local slot = P.BarSlotOf(frame)

  -- Hovering the strip face: rebind this column (per-form overlay).
  -- Do not PlaceAction (same spell on its own slot toggles it off).
  if slot then
    P.ClearFamilySpellBinds(frame.famTag, ability)
    if P.IsMouseKey(key) then
      local cmd = P.PaintedSpellCommand(frame)
      if P.Text(cmd) then return "bar:" .. slot, "ACTIONBUTTON" .. slot end
    end
    return "bar:" .. slot, "ACTIONBUTTON" .. slot
  end
  -- Drawer extra: bind the extra itself. Never promote onto a strip key
  -- (that stole 2 from Shred in the drawer and put it back on the bar).
end

function P.AbilityIsFamilyBarSpell(tag, ability)
  if not P.Text(tag) or type(ability) ~= "table" then return false end
  local pack = P.CurrentPack and P.CurrentPack()
  for _, fam in ipairs((pack and pack.families) or {}) do
    if fam.tag == tag and type(fam.bars) == "table" then
      for formName, spec in pairs(fam.bars) do
        if type(spec) == "table" then
          local stock = {
            name = spec.label, label = spec.label,
            id = type(spec.spell) == "table" and spec.spell[1] or nil,
          }
          if SameAbility(ability, stock) then return true, formName end
          if ability.id and type(spec.spell) == "table" then
            for _, sid in ipairs(spec.spell) do
              if sid == ability.id then return true, formName end
            end
          end
          if P.Text(ability.name) and P.Text(spec.label) and ability.name == spec.label then
            return true, formName
          end
        end
      end
    end
  end
  local c = SuperBindsDB.custom and SuperBindsDB.custom[tag]
  if type(c) == "table" and type(c.formPrimary) == "table" then
    for formName, ab in pairs(c.formPrimary) do
      if SameAbility(ability, ab) then return true, formName end
    end
  end
  return false
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
    if P.HideExtra then P.HideExtra(tag, displaced, FormNow()) end
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

local function VacateSource(fromTag, fromKey, fromPrimary, ability, emptySlot)
  local changed = false
  if fromPrimary then
    if type(ability) == "table" and ability.equipmentSlot then return false end
    local form = PackFormNow()
    if emptySlot then
      if not form then return false end
      local c = EnsureCustom(fromTag)
      c.formPrimary = c.formPrimary or {}
      c.formPrimary[form] = P.EmptyPrimary()
      if fromKey then ClearModAbility(fromKey) end
      if P.PlaceFamilyPrimaryNow then
        P.PlaceFamilyPrimaryNow(fromTag, c.formPrimary[form])
      end
      return true
    end
    local c = EnsureCustom(fromTag)
    if form and type(c.formPrimary) == "table" and c.formPrimary[form] then
      c.formPrimary[form] = nil
      changed = true
    elseif c.primary then
      c.primary = nil
      changed = true
    end
    if fromKey then ClearModAbility(fromKey) end
    if changed then
      print("|cff0070ddSuper Binds:|r " .. fromTag .. " primary reset to stock.")
    end
    return changed
  end
  if fromKey then changed = ClearModAbility(fromKey) or changed end
  changed = RemoveExtra(fromTag, ability, true) or changed
  -- Pack stock extras are not in custom.added. Hide this stance only so
  -- cat can keep Thrash after you yank it off bear.
  if P.HideExtra(fromTag, ability, FormNow()) then
    changed = true
  end
  -- The extra they yanked may be the ability that replaced the parent.
  -- Removing it from the drawer used to leave formPrimary (and the bar) stuck.
  local form = PackFormNow()
  local c = SuperBindsDB.custom and SuperBindsDB.custom[fromTag]
  if type(c) == "table" then
    if form and type(c.formPrimary) == "table" and SameAbility(c.formPrimary[form], ability) then
      c.formPrimary[form] = nil
      changed = true
      print("|cff0070ddSuper Binds:|r " .. fromTag .. " primary reset to stock.")
    elseif SameAbility(c.primary, ability) then
      c.primary = nil
      changed = true
      print("|cff0070ddSuper Binds:|r " .. fromTag .. " primary reset to stock.")
    end
  end
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

  local function columnKey(tag, key)
    if not key or not P.FamilyHasBars(tag) then return false end
    local spec = P.FamilyBarSpec(tag)
    return type(spec) == "table" and (key == spec.key or key == spec.bindKey)
  end

  if dest.primary then
    if not SetCustomPrimary(dest.tag, a, true) then return false end
    if dest.key and not columnKey(dest.tag, dest.key) then
      SetModAbility(dest.key, a, true, newNomod)
    end
  elseif dest.key then
    SetModAbility(dest.key, a, true, newNomod)
  elseif dest.added then
    if not ReplaceAdded(dest.tag, dest.ability, a) then AddExtra(dest.tag, a, true) end
  else
    if P.HideExtra then P.HideExtra(dest.tag, b, FormNow()) end
    AddExtra(dest.tag, a, true)
  end

  if src.primary then
    if not SetCustomPrimary(src.tag, b, true) then return false end
    if src.key and not columnKey(src.tag, src.key) then
      SetModAbility(src.key, b, true, newNomod)
    end
  elseif src.key then
    SetModAbility(src.key, b, true, newNomod)
  elseif src.added then
    if not ReplaceAdded(src.tag, src.ability, b) then
      AddExtra(src.tag, b, true)
    end
  else
    if P.HideExtra then P.HideExtra(src.tag, a, FormNow()) end
    AddExtra(src.tag, b, true)
  end

  if not src.key and not src.primary and not dest.key and not dest.primary then
    SwapExtraOrder(src.tag, a, b)
  end

  print("|cff0070ddSuper Binds:|r swapped |cffffffff" .. (a.label or a.name) .. "|r and |cffffffff" .. (b.label or b.name) .. "|r")
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
  local slotAlreadyPlaced = false

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
    local destAb = tab._ability
    local destFilled = destAb and not (P.IsEmptyPrimary and P.IsEmptyPrimary(destAb)) and NormalizeAbility(destAb)
    if not fromTag then
      slotAlreadyPlaced = P.CommitCursorToTab and P.CommitCursorToTab(tab, true)
      changed = slotAlreadyPlaced
      accepted = true
    elseif fromTag and sameBar and src and destFilled then
      local dest = {
        tag = tab.famTag,
        primary = true,
        key = tab._sbPrimaryKey,
        ability = destFilled,
      }
      changed = SwapSlots(src, dest)
    else
      changed, notice = DisplaceIntoFamily(tab.famTag, srcAb, destFilled, {
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
  elseif fromTag then
    -- Shift-drag a face or extra off a plus / extra / tab: empty the parent
    -- or remove the extra. Open drawers and the drop rail are not drop targets.
    changed = VacateSource(fromTag, fromKey, fromPrimary, srcAb, true)
    if changed then
      if fromPrimary then
        notice = (fromKey or fromTag) .. " emptied this form · drop a spell to fill"
      else
        notice = (srcAb.label or srcAb.name or "Ability") .. " removed"
      end
    end
  end
  HoldMenus(false)
  if changed and not slotAlreadyPlaced then
    -- Place only the stance slot that changed. A full PlaceID pass picks up
    -- each slot onto the cursor and writes caster page 1 while you are in cat.
    -- CommitCursorToTab already PlaceAction'd the live abs slot.
    local function applyBar(tag)
      if tag and P.FamilyHasBars(tag) and P.PlaceFamilyPrimaryNow then
        P.PlaceFamilyPrimaryNow(tag, P.CustomPrimaryFor(tag, PackFormNow()))
      end
    end
    if tab and tab.famTag then applyBar(tab.famTag) end
    if fromTag then applyBar(fromTag) end
  end
  if changed or accepted then pcall(ClearCursor) end
  if changed then
    local consoleOnly = true
    P.dropRefreshQueued = true
    C_Timer.After(0, function()
      P.dropRefreshQueued = false
      if RefreshLayout(consoleOnly) then
        if notice then P.DropNotice(notice) end
      else
        P.Report("Saved the drop. Leave combat, clear the cursor, then /superbinds to apply it.")
      end
    end)
  elseif notice then P.DropNotice(notice) end
  finishing = false
end

local function FinishDrag()
  if Locked() then P.pendingDragCleanup = true; return end
  if busy or finishing then return end
  local custom, mods = P.CopyData(SuperBindsDB.custom), P.CopyData(SuperBindsDB.mods)
  local ok, err = pcall(P.FinishDragImpl)
  finishing = false
  if not ok then
    SuperBindsDB.custom, SuperBindsDB.mods = custom, mods
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
    if button ~= "LeftButton" then return end
    if P.CommitCursorToTab and P.CommitCursorToTab(self) then return end
    if not P.shiftHeld then return end
    if drag.ability then return end
    if P.CursorHasPickup and P.CursorHasPickup() then return end
    for _, m in pairs(menus) do
      if m:IsShown() and m:IsMouseOver() then return end
    end
    if self._ability and not (P.IsEmptyPrimary and P.IsEmptyPrimary(self._ability)) then
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
  tab:SetScript("OnReceiveDrag", function(self)
    if P.CommitCursorToTab and P.CommitCursorToTab(self, true) then return end
    if P.ReceiveDrop then P.ReceiveDrop() end
  end)
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
    if button ~= "LeftButton" then return end
    if P.CursorHasPickup and P.CursorHasPickup() then
      if P.ReceiveDrop then P.ReceiveDrop() end
      return
    end
    if not P.shiftHeld then return end
    BeginInternalDrag(self._ability, self.famTag or tag, self._sbBindKey)
  end)
  b:SetScript("OnReceiveDrag", function() if P.ReceiveDrop then P.ReceiveDrop() end end)
end

function P.StartExternalDrag()
  if Locked() or busy or finishing or P.dropRefreshQueued or InQuickKeybind() then return false end
  if drag.active then return true end
  local ok, ability = pcall(CursorAbility)
  ability = ok and NormalizeAbility(ability) or nil
  if not ability and P.CursorIsAssisted and P.CursorIsAssisted() then
    ability = NormalizeAbility(P.AssistedAbility())
  end
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
  elseif drag.fromTag and not MenuUnderMouse() then
    if drag.fromPrimary then
      message = name .. "  /  Release off the bar to empty this slot. Esc cancels."
    else
      message = name .. "  /  Release off the bar to remove this extra. Esc cancels."
    end
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
  pcall(function()
    b:SetAttribute("shift-type1", "")
    b:SetAttribute("shift-type*", "")
    b:SetAttribute("shift-typerelease1", "")
  end)
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
  local f = CreateFrame("Frame", "SuperBindsKeymap", UIParent, "BackdropTemplate")
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
  brand:SetText("SUPER BINDS")
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
  local scroll = CreateFrame("ScrollFrame", "SuperBindsKeymapScroll", f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 24, -102)
  scroll:SetPoint("BOTTOMRIGHT", -42, 44)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(746, 1)
  scroll:SetScrollChild(content)
  f.scroll, f.content, f.groups = scroll, content, {}
  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", 24, 18)
  hint:SetText("/superbinds bind  to change keys     |     Ctrl-drag to move the console")
  P.VisualFont(hint, 10, P.Visual.muted)
  f.widgets = {}
  tinsert(UISpecialFrames, "SuperBindsKeymap")
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
    print("|cff0070ddSuper Binds:|r run |cffffffff/superbinds default|r to build the stock layout first.")
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

function P.PrintNameList(title, names)
  names = names or {}
  table.sort(names)
  if #names == 0 then
    print("|cff0070dd" .. title .. ":|r (none)")
    return
  end
  local acc, n = {}, 0
  local function flush()
    if n == 0 then return end
    print("|cff0070dd" .. title .. ":|r " .. table.concat(acc, ", "))
    acc, n = {}, 0
  end
  for i = 1, #names do
    local name = names[i]
    local add = (n > 0 and 2 or 0) + #name
    if n > 0 and n + add > 180 then flush() end
    acc[#acc + 1] = name
    n = n + add
  end
  flush()
end

function P.ProbeSpellLabel(id)
  if id == nil then return nil end
  if issecretvalue and issecretvalue(id) then return "(secret)" end
  local pub = P.PublicNumber(id) or P.ID(id)
  if not pub then return "(secret)" end
  local name
  pcall(function() name = SpellName(pub) end)
  name = P.Text(name)
  if name and name ~= tostring(pub) then return name end
  return "#" .. tostring(pub)
end

function P.EnsureProbeFrame()
  if P.probeFrame then return P.probeFrame end
  local f = CreateFrame("Frame", "SuperBindsProbeFrame", UIParent, "BackdropTemplate")
  f:SetSize(600, 560)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetFrameLevel(200)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  if P.VisualPanel then P.VisualPanel(f, P.Visual.ink, P.Visual.brass) end
  if AttachDropShadow then AttachDropShadow(f) end
  if P.VisualLine then P.VisualLine(f, P.Visual.teal, 1, -1) end
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 18, -16)
  title:SetText("Copy dump")
  if P.VisualFont then P.VisualFont(title, 18, P.Visual.text) end
  f.TitleText = title
  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  hint:SetPoint("TOPLEFT", 18, -38)
  hint:SetText("Ctrl+A, Ctrl+C  ·  or /reload so the log can be read from SavedVariables")
  if P.VisualFont then P.VisualFont(hint, 10, P.Visual.muted) end
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)
  close:SetScript("OnClick", function() f:Hide() end)
  local scroll = CreateFrame("ScrollFrame", "SuperBindsProbeScroll", f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 16, -56)
  scroll:SetPoint("BOTTOMRIGHT", -36, 16)
  local edit = CreateFrame("EditBox", "SuperBindsProbeEdit", scroll)
  edit:SetMultiLine(true)
  edit:SetAutoFocus(false)
  edit:SetFontObject(GameFontHighlightSmall)
  edit:SetWidth(530)
  if edit.SetMaxLetters then pcall(edit.SetMaxLetters, edit, 0) end
  edit:SetScript("OnEscapePressed", function(self) self:ClearFocus(); f:Hide() end)
  scroll:SetScrollChild(edit)
  f.edit = edit
  tinsert(UISpecialFrames, "SuperBindsProbeFrame")
  P.probeFrame = f
  return f
end

function P.ShowProbeText(text, title)
  local f = P.EnsureProbeFrame()
  if not f or not f.edit then return end
  if f.TitleText and P.Text(title) then f.TitleText:SetText(title) end
  f.edit:SetText(text or "")
  f:Show()
  f.edit:SetFocus()
  if f.edit.HighlightText then f.edit:HighlightText() end
end

function P.ProbeDumpText(dump)
  dump = dump or {}
  local lines = {
    "Super Binds probe",
    "at=" .. tostring(dump.at or ""),
    "race=" .. tostring(dump.race or "?")
      .. "  class=" .. tostring(dump.class or "?")
      .. "  spec=" .. tostring(dump.spec or "?") .. " " .. tostring(dump.specName or "")
      .. "  hero=" .. tostring(dump.hero or "none")
      .. "  pack=" .. tostring(dump.pack or "none"),
    "SBA button: " .. tostring(dump.sbaButton or "?"),
  }
  if (dump.sbaSecret or 0) > 0 then
    lines[#lines + 1] = "SBA secret ids: " .. tostring(dump.sbaSecret) .. " (leave combat and probe again)"
  end
  local function addList(title, names)
    names = names or {}
    if #names == 0 then
      lines[#lines + 1] = title .. ": (none)"
      return
    end
    lines[#lines + 1] = title .. ": " .. table.concat(names, ", ")
  end
  addList("SBA presses", dump.sba)
  for i = 1, #(dump.lines or {}) do
    local row = dump.lines[i]
    if type(row) == "table" then
      addList((row.name or "line") .. " · active", row.active)
      addList((row.name or "line") .. " · passive", row.passive)
    end
  end
  addList("Shapeshifts", dump.shapeshifts)
  return table.concat(lines, "\n")
end

function P.DumpAbilityLabel(spec)
  if type(spec) ~= "table" then return "?" end
  if spec.empty or (P.IsEmptyPrimary and P.IsEmptyPrimary(spec)) then return "(empty)" end
  if spec.sba then return "Assisted Rotation" end
  if type(spec.spell) == "table" then
    local name = Known(unpack(spec.spell))
    if name then return name end
  end
  return P.Text(spec.label) or P.Text(spec.name) or (spec.macro and tostring(spec.macro[1])) or "?"
end

function P.DumpNativeLabel(abs)
  abs = P.ID(abs)
  if not abs then return "(none)" end
  local ab = P.NativeAbility and P.NativeAbility(abs)
  if ab then return P.Text(ab.label) or P.Text(ab.name) or "?" end
  local kind = P.Read(GetActionInfo, abs)
  if not kind then return "(empty)" end
  return tostring(kind)
end

function P.DumpBindingKeys(command)
  if not P.Text(command) or type(GetBindingKey) ~= "function" then return "" end
  local a, b, c, d = P.Read(GetBindingKey, command)
  local parts = {}
  if P.Text(a) then parts[#parts + 1] = a end
  if P.Text(b) then parts[#parts + 1] = b end
  if P.Text(c) then parts[#parts + 1] = c end
  if P.Text(d) then parts[#parts + 1] = d end
  return table.concat(parts, ", ")
end

function P.CollectLayoutDump()
  local pack = P.CurrentPack and P.CurrentPack()
  local form = (P.PackFormNow and P.PackFormNow()) or (P.CurrentForm and P.CurrentForm())
  local bonus
  pcall(function() bonus = GetBonusBarOffset() end)
  local stamp
  pcall(function() stamp = date("%Y-%m-%d %H:%M:%S") end)
  local layout = {
    at = stamp or "",
    pack = (pack and pack.name) or "none",
    form = form or "?",
    bonus = bonus,
    console = {},
    liveBar = {},
    liveConsole = {},
    chords = {},
    overlays = {},
    wheelActionButton = P._wheelActionButtonRejected and "rejected" or nil,
  }
  if type(pack) == "table" then
    for _, fam in ipairs(pack.families or {}) do
      local row = {
        tag = fam.tag, caption = fam.caption, title = fam.title,
        slot = nil, key = nil, faces = {}, extras = {}, overlay = {},
      }
      if type(fam.bars) == "table" then
        for formName, spec in pairs(fam.bars) do
          if type(spec) == "table" then
            row.faces[formName] = P.DumpAbilityLabel(spec)
            row.slot = row.slot or spec.slot
            row.key = row.key or spec.bindKey or spec.key
          end
        end
      elseif type(fam.bar) == "table" then
        row.faces.all = P.DumpAbilityLabel(fam.bar)
        row.slot = fam.bar.slot
        row.key = fam.bar.bindKey or fam.bar.key
      end
      for _, it in ipairs(fam.items or {}) do
        row.extras[#row.extras + 1] = {
          key = it.bindKey or it.key,
          label = P.DumpAbilityLabel(it),
          slot = it.slot,
          click = not (it.bindKey or it.key) or nil,
        }
      end
      if fam.tag and P.CustomPrimaryFor then
        local forms = {"caster", "cat", "bear", "moonkin", "travel"}
        for i = 1, #forms do
          local ov = P.CustomPrimaryFor(fam.tag, forms[i])
          if ov then
            row.overlay[forms[i]] = P.DumpAbilityLabel(ov)
          end
        end
      end
      layout.console[#layout.console + 1] = row
    end
  end
  local n = (P.BarButtons and P.BarButtons()) or 12
  for rel = 1, n do
    local abs = (P.LiveActionSlot and P.LiveActionSlot(rel)) or (P.ActionSlot and P.ActionSlot(rel, form)) or rel
    local cmd = "ACTIONBUTTON" .. rel
    layout.liveBar[#layout.liveBar + 1] = {
      rel = rel, abs = abs, cmd = cmd,
      key = P.DumpBindingKeys(cmd),
      label = P.DumpNativeLabel(abs),
    }
  end
  if type(consoleTabs) == "table" then
    local live = P.LiveKeymapDisplay and P.LiveKeymapDisplay()
    if type(live) == "table" then
      for i = 1, #live do
        local g = live[i]
        local entries = {}
        for j = 1, #(g.entries or {}) do
          local e = g.entries[j]
          entries[#entries + 1] = { key = e.key, label = e.label }
        end
        layout.liveConsole[#layout.liveConsole + 1] = { title = g.title, entries = entries }
      end
    end
  end
  local want = {}
  local function claim(key)
    key = P.Text(key)
    if key then want[key] = true end
  end
  if pack then
    for key in pairs(pack.barBinds or {}) do claim(key) end
    for key in pairs(pack.hardware or {}) do claim(key) end
    for key in pairs(pack.camera or {}) do claim(key) end
    for _, fam in ipairs(pack.families or {}) do
      if fam.bar then claim(fam.bar.bindKey or fam.bar.key) end
      if type(fam.bars) == "table" then
        for _, spec in pairs(fam.bars) do claim(spec.bindKey or spec.key) end
      end
      for _, it in ipairs(fam.items or {}) do claim(it.bindKey or it.key) end
    end
  end
  for rel = 1, n do
    local a, b, c, d = P.Read(GetBindingKey, "ACTIONBUTTON" .. rel)
    claim(a); claim(b); claim(c); claim(d)
  end
  for bindId, key in pairs((SuperBindsDB and SuperBindsDB.binds) or {}) do
    if type(bindId) == "string" and bindId:find("^key:", 1, true) then claim(key) end
  end
  local keys = {}
  for key in pairs(want) do keys[#keys + 1] = key end
  table.sort(keys)
  for i = 1, #keys do
    local key = keys[i]
    local cmd = P.Read(GetBindingAction, key) or ""
    layout.chords[#layout.chords + 1] = { key = key, command = cmd }
  end
  for tag, custom in pairs((SuperBindsDB and SuperBindsDB.custom) or {}) do
    local fp = custom and custom.formPrimary
    if type(fp) == "table" then
      for formName, ab in pairs(fp) do
        layout.overlays[#layout.overlays + 1] = {
          tag = tag, form = formName, label = P.DumpAbilityLabel(ab),
        }
      end
    end
  end
  table.sort(layout.overlays, function(a, b)
    if a.tag == b.tag then return tostring(a.form) < tostring(b.form) end
    return tostring(a.tag) < tostring(b.tag)
  end)
  return layout
end

function P.LayoutDumpText(layout)
  layout = layout or {}
  local lines = {
    "Keys",
    "at=" .. tostring(layout.at or ""),
    "pack=" .. tostring(layout.pack or "none") .. "  form=" .. tostring(layout.form or "?")
      .. "  bonus=" .. tostring(layout.bonus or "?"),
  }
  local formOrder = {"caster", "cat", "bear", "moonkin", "travel", "all"}
  lines[#lines + 1] = "Console (pack stock)"
  for i = 1, #(layout.console or {}) do
    local row = layout.console[i]
    local head = "  " .. tostring(row.tag or "?")
    if row.caption then head = head .. " " .. row.caption end
    if row.slot then head = head .. "  slot=" .. tostring(row.slot) end
    if row.key then head = head .. "  key=" .. tostring(row.key) end
    lines[#lines + 1] = head
    local faces = {}
    local seen = {}
    for fi = 1, #formOrder do
      local f = formOrder[fi]
      if row.faces and row.faces[f] then
        seen[f] = true
        faces[#faces + 1] = f .. "=" .. row.faces[f]
      end
    end
    if type(row.faces) == "table" then
      for f, v in pairs(row.faces) do
        if not seen[f] then faces[#faces + 1] = f .. "=" .. tostring(v) end
      end
    end
    if #faces > 0 then lines[#lines + 1] = "    faces: " .. table.concat(faces, "  ") end
    if type(row.overlay) == "table" then
      local ovs = {}
      for fi = 1, #formOrder do
        local f = formOrder[fi]
        if row.overlay[f] then ovs[#ovs + 1] = f .. "=" .. row.overlay[f] end
      end
      if #ovs > 0 then lines[#lines + 1] = "    overlay: " .. table.concat(ovs, "  ") end
    end
    for j = 1, #(row.extras or {}) do
      local ex = row.extras[j]
      local bit = ex.click and "click" or tostring(ex.key or "")
      if ex.slot then bit = bit .. " slot=" .. tostring(ex.slot) end
      lines[#lines + 1] = "    extra: " .. bit .. "  " .. tostring(ex.label or "?")
    end
  end
  lines[#lines + 1] = "Live ACTIONBUTTON (" .. tostring(layout.form or "?") .. ")"
  for i = 1, #(layout.liveBar or {}) do
    local s = layout.liveBar[i]
    local key = P.Text(s.key) or "(unbound)"
    lines[#lines + 1] = "  " .. tostring(s.rel) .. "  " .. key
      .. "  abs=" .. tostring(s.abs) .. "  " .. tostring(s.label or "?")
  end
  if #(layout.liveConsole or {}) > 0 then
    lines[#lines + 1] = "Live console (painted)"
    for i = 1, #layout.liveConsole do
      local g = layout.liveConsole[i]
      lines[#lines + 1] = "  " .. tostring(g.title or "?")
      for j = 1, #(g.entries or {}) do
        local e = g.entries[j]
        local k = P.Text(e.key) or "click"
        lines[#lines + 1] = "    " .. k .. "  " .. tostring(e.label or "?")
      end
    end
  end
  lines[#lines + 1] = "Chords (GetBindingAction)"
  if #(layout.chords or {}) == 0 then
    lines[#lines + 1] = "  (none)"
  else
    for i = 1, #layout.chords do
      local c = layout.chords[i]
      lines[#lines + 1] = "  " .. tostring(c.key) .. " = " .. (P.Text(c.command) or "(empty)")
    end
  end
  lines[#lines + 1] = "Overlays (formPrimary)"
  if #(layout.overlays or {}) == 0 then
    lines[#lines + 1] = "  (none)"
  else
    for i = 1, #layout.overlays do
      local o = layout.overlays[i]
      lines[#lines + 1] = "  " .. tostring(o.tag) .. " " .. tostring(o.form) .. " = " .. tostring(o.label)
    end
  end
  if layout.wheelActionButton == "rejected" then
    lines[#lines + 1] = "Wheel: ACTIONBUTTON rejected by client; bound slot contents (MACRO/SPELL)"
  end
  return table.concat(lines, "\n")
end

function P.CollectProbeDump()
  P.EnsureDB()
  pcall(ScanBook)
  local function sortedCopy(list)
    local out = {}
    for i = 1, #(list or {}) do out[i] = list[i] end
    table.sort(out)
    return out
  end
  local race = P.Text(UnitRace and UnitRace("player"))
  local classLoc, classToken
  pcall(function() classLoc, classToken = UnitClass("player") end)
  local specID = P.PlayerSpecID and P.PlayerSpecID()
  local specName = P.PlayerSpecName and P.PlayerSpecName()
  local heroID = P.PlayerHeroTalentID and P.PlayerHeroTalentID()
  local pack = P.CurrentPack and P.CurrentPack()
  local sbaNames, sbaSecret = {}, 0
  pcall(function()
    if not (C_AssistedCombat and C_AssistedCombat.GetRotationSpells) then return end
    for _, id in pairs(C_AssistedCombat.GetRotationSpells()) do
      local label = P.ProbeSpellLabel(id)
      if label == "(secret)" then
        sbaSecret = sbaSecret + 1
      elseif label then
        sbaNames[#sbaNames + 1] = label
      end
    end
  end)
  local byLine, lineOrder = {}, {}
  pcall(function()
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    local types = Enum and Enum.SpellBookItemType
    for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
      local li = C_SpellBook.GetSpellBookSkillLineInfo(line)
      if li and not li.offSpecID then
        local lineName = P.Text(li.name) or ("line " .. line)
        if not byLine[lineName] then
          byLine[lineName] = { active = {}, passive = {} }
          lineOrder[#lineOrder + 1] = lineName
        end
        local bucket = byLine[lineName]
        for j = (li.itemIndexOffset or 0) + 1, (li.itemIndexOffset or 0) + (li.numSpellBookItems or 0) do
          local it = P.BookInfo(j, bank)
          if it and not it.isOffSpec then
            local kind = it.itemType
            if not (types and kind == types.FutureSpell) then
              local name = P.Text(it.name) or P.ProbeSpellLabel(it.spellID)
              if name and name ~= "(secret)" then
                if types and (kind == types.AssistedCombat or P.IsAssistedToken(kind) or P.IsAssistedToken(name)) then
                  name = name .. " [SBA]"
                elseif types and kind == types.Flyout then
                  name = name .. " [flyout]"
                end
                if it.isPassive then
                  bucket.passive[#bucket.passive + 1] = name
                else
                  bucket.active[#bucket.active + 1] = name
                end
              end
            end
          end
        end
      end
    end
  end)
  local forms = {}
  pcall(function()
    local n = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
    for i = 1, n do
      local _, _, _, spellID = GetShapeshiftFormInfo(i)
      local label = P.ProbeSpellLabel(spellID)
      if label then forms[#forms + 1] = label end
    end
  end)
  local lines = {}
  for i = 1, #lineOrder do
    local name = lineOrder[i]
    local bucket = byLine[name]
    lines[#lines + 1] = {
      name = name,
      active = sortedCopy(bucket.active),
      passive = sortedCopy(bucket.passive),
    }
  end
  local stamp
  pcall(function() stamp = date("%Y-%m-%d %H:%M:%S") end)
  local dump = {
    at = stamp or "",
    race = race or "?",
    class = P.Text(classToken) or P.Text(classLoc) or "?",
    spec = specID or 0,
    specName = specName or "",
    hero = heroID or 0,
    pack = (pack and pack.name) or "none",
    sbaButton = P.ProbeSpellLabel(P.AssistedActionID and P.AssistedActionID()) or "Assisted Rotation",
    sba = sortedCopy(sbaNames),
    sbaSecret = sbaSecret,
    lines = lines,
    shapeshifts = sortedCopy(forms),
  }
  SuperBindsDB.probe = dump
  return dump
end

function P.PrintProbe()
  local dump = P.CollectProbeDump()
  local layout = P.CollectLayoutDump()
  SuperBindsDB.dump = layout
  local text = P.ProbeDumpText(dump) .. "\n\n" .. P.LayoutDumpText(layout)
  P.ShowProbeText(text, "Spell + keys")
  print("|cff0070ddSuper Binds:|r dump saved. Copy the window (Ctrl+A, Ctrl+C), or |cffffffff/reload|r so it can be read from SavedVariables.")
end

function P.PrintSBA()
  local pack = P.CurrentPack and P.CurrentPack()
  if pack and pack.useBlizzardSBA == false then return end
  local names = {}
  for name in pairs(P.RotationSet()) do names[#names + 1] = name end
  if #names == 0 then return end
  table.sort(names)
  print("|cff0070ddSBA on E presses:|r " .. table.concat(names, ", "))
end

function P.HideAutoManaged()
  local pack = P.CurrentPack and P.CurrentPack()
  if pack and pack.useBlizzardSBA == false then return false end
  return not SuperBindsDB or SuperBindsDB.hideAutoManaged ~= false
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
  if type(spell) == "string" and IsGroundName(spell) then
    dest = totems or recover or attack
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
local function SpecialBarState()
  local parts = {"[overridebar]1", "[vehicleui]1", "[possessbar]1", "[mounted]1"}
  local claimed = {}
  local pack = P.CurrentPack and P.CurrentPack()
  if pack and type(pack.actionBars) == "table" then
    for _, spec in pairs(pack.actionBars) do
      local bonus = type(spec) == "table" and tonumber(spec.bonus)
      if bonus then claimed[bonus] = true end
    end
  end
  for n = 1, 5 do
    if not claimed[n] then parts[#parts + 1] = "[bonusbar:" .. n .. "]1" end
  end
  parts[#parts + 1] = "0"
  return table.concat(parts, ";")
end

function P.SyncSpecialBarState()
  if not P.barDriver then return end
  if Locked() then
    P._pendingSpecialBar = true
    return
  end
  local cond = SpecialBarState()
  if P._specialBarCond == cond then return end
  local ok = pcall(RegisterStateDriver, P.barDriver, "special", cond)
  if ok then
    P._specialBarCond = cond
    P._pendingSpecialBar = nil
  end
end
local SPECIAL_BAR_STATE = "[overridebar]1;[vehicleui]1;[possessbar]1;[mounted]1;0"

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
  -- Form bonus bars belong to the pack. Do not treat cat/bear/stance as a mount bar.
  if P.FlagFn(HasOverrideActionBar) or P.FlagFn(HasVehicleActionBar) then
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
  return SuperBindsDB.useMountBar ~= false and P.OnSpecialBar()
end

function P.SyncMountBarDriver()
  local d = P.barDriver
  if not d then return end
  d:SetAttribute("useMount", (SuperBindsDB.useMountBar ~= false) and "1" or "0")
end

function P.EnsureBarDriver()
  if P.barDriver then return P.barDriver end
  local d = CreateFrame("Frame", "SuperBindsBarDriver", UIParent, "SecureHandlerStateTemplate")
  P.barDriver = d
  d:Hide()
  d:SetAttribute("_onstate-special", [[
    self:ClearBindings()
    local n = tonumber(self:GetAttribute("n")) or 0
    for i = 1, n do
      local key = self:GetAttribute("k"..i)
      local cmd = self:GetAttribute("c"..i)
      if key and cmd then self:SetBinding(true, key, cmd) end
    end
    if newstate == "1" and self:GetAttribute("useMount") == "1" then
      local sn = tonumber(self:GetAttribute("sn")) or 0
      for i = 1, sn do
        local key = self:GetAttribute("sk"..i)
        local spell = self:GetAttribute("ss"..i)
        if key and spell then self:SetBindingSpell(true, key, spell) end
      end
    end
  ]])
  P.SyncMountBarDriver()
  P._specialBarCond = nil
  P.SyncSpecialBarState()
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
  local binds = SuperBindsDB.binds or {}
  for id, saved in pairs(binds) do
    if type(saved) == "string" and P.IsMouseKey(saved) then
      claimed[saved] = id
    end
  end
  for _, frame in ipairs(P.BindFrames()) do
    local key = EffectiveKey(frame._sbBindId, frame._sbDefaultKey)
    if key and not P.IsMouseKey(key) then
      local slot = P.BarSlotOf(frame)
      local cmd = (slot and ("ACTIONBUTTON" .. slot)) or frame.commandName
      if cmd then P.QueueOverride(key, cmd) end
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
    if not claimed[key] and not P.IsAddonCameraKey(key) then
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
  for _, pair in ipairs(P.overrideList) do
    pcall(SetOverrideBinding, d, true, pair[1], pair[2])
  end
  if P.ApplySkyridingKeybinds then P.ApplySkyridingKeybinds(d) end
  P.BindThunderstormShiftE()
end

-- Console is ours. Blizzard's mount/vehicle bar can stay. Default: hide the
-- console while mounted; /superbinds console toggles it. The world map is
-- HIGH/DIALOG; our bar is HIGH and used to sit on top of M.
function P.HUDMapOpen()
  local function shown(name)
    local f = _G[name]
    return f and f.IsShown and f:IsShown() and true or false
  end
  return shown("WorldMapFrame") or shown("FlightMapFrame")
end

function P.WatchHUDMap()
  local function hook(f)
    if not f or f._sbMapHook then return end
    f._sbMapHook = true
    f:HookScript("OnShow", function()
      if P.ApplyConsoleMountedHide then P.ApplyConsoleMountedHide() end
    end)
    f:HookScript("OnHide", function()
      if P.ApplyConsoleMountedHide then P.ApplyConsoleMountedHide() end
    end)
  end
  hook(_G.WorldMapFrame)
  hook(_G.FlightMapFrame)
end

function P.ConsoleVisibilityDriver()
  if P.HUDMapOpen() then return "hide" end
  -- Shapeshift packs keep the console in flight form. Forms keys still work.
  local hideMount = SuperBindsDB.hideConsoleMounted
  if P.CollectFormBinds then
    if next(P.CollectFormBinds()) then hideMount = false end
  end
  if hideMount then
    return "[petbattle]hide;[mounted]hide;[vehicleui]hide;[overridebar]hide;show"
  end
  return "[petbattle]hide;show"
end

function P.ApplyConsoleMountedHide()
  local c = console
  if not c then return end
  P.WatchHUDMap()
  local mapOpen = P.HUDMapOpen()
  if mapOpen then
    c:SetFrameStrata("BACKGROUND")
    if P.dropRail then P.dropRail:Hide() end
  else
    c:SetFrameStrata("HIGH")
    c:SetFrameLevel(50)
  end
  if Locked() then
    P.pendingConsoleVis = true
    if P.ApplyPressPulseShown then P.ApplyPressPulseShown() end
    return
  end
  P.pendingConsoleVis = nil
  pcall(RegisterStateDriver, c, "visibility", P.ConsoleVisibilityDriver())
  if P.ApplyPressPulseShown then P.ApplyPressPulseShown() end
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

function P.NativeActionButton(rel)
  rel = tonumber(rel)
  if not rel then return nil end
  return _G["ActionButton" .. rel]
end

function P.SkinHostedActionButton(b, hosted)
  if not b then return end
  local a = hosted and 0 or 1
  local function fade(tex)
    if tex and tex.SetAlpha then pcall(function() tex:SetAlpha(a) end) end
  end
  pcall(function()
    fade(b.GetNormalTexture and b:GetNormalTexture())
    fade(b.GetPushedTexture and b:GetPushedTexture())
    fade(b.GetHighlightTexture and b:GetHighlightTexture())
    fade(b.GetCheckedTexture and b:GetCheckedTexture())
  end)
  if b.HotKey then pcall(function() b.HotKey:SetAlpha(a) end) end
  if b.Name then pcall(function() b.Name:SetAlpha(a) end) end
  if b.SlotBackground then pcall(function() b.SlotBackground:SetAlpha(a) end) end
  if b.SlotArt then pcall(function() b.SlotArt:SetAlpha(a) end) end
  if b.Border then pcall(function() b.Border:SetAlpha(a) end) end
end

function P.CaptureNativeHome(rel)
  P._nativeHome = P._nativeHome or {}
  if P._nativeHome[rel] then return end
  local b = P.NativeActionButton(rel)
  if not b then return end
  local points = {}
  local n = (b.GetNumPoints and b:GetNumPoints()) or 0
  for i = 1, n do
    points[i] = { b:GetPoint(i) }
  end
  P._nativeHome[rel] = {
    parent = b:GetParent(),
    points = points,
    scale = b.GetScale and b:GetScale() or 1,
    level = b.GetFrameLevel and b:GetFrameLevel() or 1,
    mouse = not (b.IsMouseEnabled and not b:IsMouseEnabled()),
  }
end

function P.RestoreNativeButton(rel)
  local b = P.NativeActionButton(rel)
  if not b then return end
  P.SkinHostedActionButton(b, false)
  if Locked() then
    pcall(function()
      b:SetAlpha(0)
      if b.EnableMouse then b:EnableMouse(false) end
    end)
    return
  end
  local home = P._nativeHome and P._nativeHome[rel]
  if not home then return end
  pcall(function()
    if home.parent then b:SetParent(home.parent) end
    b:ClearAllPoints()
    for _, p in ipairs(home.points or {}) do
      if p and p[1] then b:SetPoint(unpack(p)) end
    end
    if b.SetScale then b:SetScale(home.scale or 1) end
    if b.SetFrameLevel then b:SetFrameLevel(home.level or 1) end
    if b.EnableMouse then b:EnableMouse(home.mouse ~= false) end
    if b.SetIgnoreParentAlpha then b:SetIgnoreParentAlpha(false) end
  end)
end

function P.ReleaseNativeHost(tab)
  if not tab or not tab._sbHostedRel then return end
  local rel = tab._sbHostedRel
  tab._sbHostedRel = nil
  tab._sbWantHost = nil
  if P._hostedByRel and P._hostedByRel[rel] == tab then
    P._hostedByRel[rel] = nil
  end
  if tab.icon then tab.icon:SetAlpha(1) end
  if tab.cooldown then tab.cooldown:Show() end
  P.RestoreNativeButton(rel)
end

function P.HostNativeOnTab(tab, rel)
  rel = tonumber(rel)
  local b = P.NativeActionButton(rel)
  if not tab or not b then return false end
  if tab._sbHostedRel == rel and b:GetParent() == tab then
    pcall(function()
      if b.SetIgnoreParentAlpha then b:SetIgnoreParentAlpha(true) end
      b:SetAlpha(1)
    end)
    return true
  end
  if P._hostedByRel and P._hostedByRel[rel] and P._hostedByRel[rel] ~= tab then
    P.ReleaseNativeHost(P._hostedByRel[rel])
  end
  if tab._sbHostedRel and tab._sbHostedRel ~= rel then
    P.ReleaseNativeHost(tab)
  end
  if Locked() then
    tab._sbWantHost = rel
    return false
  end
  P.CaptureNativeHome(rel)
  pcall(function()
    b:SetParent(tab)
    if b.SetIgnoreParentAlpha then b:SetIgnoreParentAlpha(true) end
    b:SetAlpha(1)
    b:ClearAllPoints()
    local icon = tab.icon
    if icon then
      b:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
      b:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
      icon:SetAlpha(0)
    else
      b:SetAllPoints(tab)
    end
    if b.EnableMouse then b:EnableMouse(false) end
  end)
  P.SkinHostedActionButton(b, true)
  if not tab._sbKeyLayer then
    local layer = CreateFrame("Frame", nil, tab)
    layer:SetAllPoints(tab)
    tab._sbKeyLayer = layer
    if tab.keyText then tab.keyText:SetParent(layer) end
  end
  pcall(function()
    tab._sbKeyLayer:SetFrameLevel((b:GetFrameLevel() or 1) + 8)
  end)
  if tab.cooldown then tab.cooldown:Hide() end
  if tab.AssistedCombatHighlightFrame then tab.AssistedCombatHighlightFrame:Hide() end
  tab._sbHostedRel = rel
  tab._sbWantHost = nil
  P._hostedByRel = P._hostedByRel or {}
  P._hostedByRel[rel] = tab
  return true
end

function P.SyncNativeSBAHosts()
  -- Do not host ActionButton widgets. SBA's live icon/cooldown are secret in
  -- combat; only GetNextCastSpell piped into texture/duration APIs can show them.
  for _, tab in pairs(consoleTabs or {}) do
    P.ReleaseNativeHost(tab)
  end
end

function P.DimMainButtons(show)
  -- Native action buttons are Blizzard's secure controls. Do not change their
  -- alpha or mouse state. Fade the MainActionBar parent instead.
end

function P.NativeSlotIsAssisted(frame)
  if not frame then return false end
  local abs = frame.GetAttribute and P.ID(frame:GetAttribute("action"))
  if not abs then
    local rel = P.BarSlotOf(frame)
    abs = rel and ((P.LiveActionSlot and P.LiveActionSlot(rel)) or P.ActionSlot(rel, PackFormNow()))
  end
  if not abs then return false end
  if P.ActionIsAssisted and P.ActionIsAssisted(abs) then return true end
  local kind, id, sub = P.Read(GetActionInfo, abs)
  if P.IsAssistedToken(kind) or P.IsAssistedToken(id) or P.IsAssistedToken(sub) then return true end
  if kind ~= "spell" then return false end
  id = P.ID(id)
  if id then return P.IsAssistedAbility(id) end
  -- Combat may hide the action ID. The marker is set only from a prior native
  -- slot read or a successful native SBA placement.
  return frame._sbNativeSBA == true
end

-- Read the action currently occupying a native slot. This is presentation
-- data only: the slot remains the authority for what the key and tab execute.
function P.NativeAbility(abs)
  abs = P.ID(abs)
  if not abs then return nil end
  if P.ActionIsAssisted and P.ActionIsAssisted(abs) then
    return P.AssistedAbility()
  end
  local kind, id, sub = P.Read(GetActionInfo, abs)
  if P.IsAssistedToken(kind) or P.IsAssistedToken(id) or P.IsAssistedToken(sub) then
    return P.AssistedAbility()
  end
  if kind == "spell" then
    id = P.ID(id)
    if not id then return nil end
    local info = P.Read(C_Spell and C_Spell.GetSpellInfo, id)
    if type(info) == "table" and P.Text(info.name) then
      return {name=info.name, label=info.name, id=id,
        icon=P.Public(info.iconID) or SpellIcon(id, info.name)}
    end
  elseif kind == "macro" then
    local name = P.Text(GetMacroInfo and GetMacroInfo(id))
    if name then
      return {name=name, label=name, macroIndex=id,
        icon=P.Public(select(2, GetMacroInfo(id))) or 134400}
    end
  elseif kind == "item" then
    local itemID = P.ID(id)
    if itemID then
      return {name="Item "..itemID, label="Item "..itemID, itemID=itemID,
        icon=(C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)) or 134400}
    end
  end
end

function P.ApplyBar1Chrome()
  P.ApplyConsoleMountedHide()
  if P.UseMountBar() then
    P.DimActionBar(_G.MainActionBar, false)
    P.DimActionBar(_G.OverrideActionBar, false)
    P.DimActionBar(_G.MainMenuBar, false)
    P.DimMainButtons(false)
    P.KeepUtilityButtonsVisible()
    if not Locked() then P.HideAllMultiBars() end
    return
  end
  local show = not SuperBindsDB.hideBar1
  P.DimActionBar(_G.MainActionBar, show)
  P.DimMainButtons(show)
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
    local owned = SuperBindsDB.hiddenSlots and SuperBindsDB.hiddenSlots[slot]
    local kind, id = GetActionInfo(slot)
    local macroName = kind == "macro" and GetMacroInfo(id)
    if owned or (type(macroName) == "string" and macroName:sub(1, 3) == "SB_") then
      ClearSlot(slot)
      if SuperBindsDB.hiddenSlots then SuperBindsDB.hiddenSlots[slot] = nil end
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
  local name = "SuperBindsSlotClick_" .. slot
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

-- Keyboard and mouse bar faces bind ACTIONBUTTON so the labeled key fires
-- that column on the current stance bar. CLICK helpers do not.
function P.HardwareCommand(key, slot, fallback)
  if P.ID(slot) and slot >= 1 and slot <= 12 then
    return "ACTIONBUTTON" .. slot
  end
  return fallback
end

function P.HotkeyCommand(tab, slot, key)
  local formCmd = P.FormBindCommand and P.FormBindCommand(key)
  if formCmd then return formCmd end
  if P.ID(slot) and slot >= 1 and slot <= 12 then
    return "ACTIONBUTTON" .. slot
  end
  return P.HardwareCommand(key, slot, P.OwnClick(tab))
end

function P.PaintedSpellCommand(frame)
  local ab = frame and frame._ability
  if type(ab) ~= "table" then return nil end
  if P.Text(ab.savedMacroName) then
    local cmd = P.NamedMacroCommand(ab.savedMacroName)
    if cmd then return cmd end
  end
  local name = P.Text(ab.name) or P.Text(ab.label)
  return name and ("SPELL " .. name) or nil
end

function P.BindActionSlot(frame)
  if not frame then return nil end
  if frame.GetAttribute then
    local abs = P.ID(frame:GetAttribute("action"))
    if abs and abs > P.BarButtons() then return abs end
    if abs then
      local rel = ((abs - 1) % P.BarButtons()) + 1
      return (P.LiveActionSlot and P.LiveActionSlot(rel)) or abs
    end
  end
  local rel = P.BarSlotOf(frame)
  if not P.ID(rel) then return nil end
  return (P.LiveActionSlot and P.LiveActionSlot(rel)) or rel
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
    local slot = P.ID(frame:GetAttribute("action"))
    if slot then
      local rel = ((slot - 1) % P.BarButtons()) + 1
      pcall(SetOverrideBinding, owner, true, key, "ACTIONBUTTON" .. rel)
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
  if not (P.CurrentPack and P.CurrentPack()) then
    pcall(SetBinding, "CTRL-Q")
  end
  P.RestoreCameraWheel()
  for _, key in ipairs({"CTRL-BUTTON4", "CTRL-BUTTON5"}) do
    if not P.IsCameraBinding(key) then
      local have = GetBindingAction(key)
      if type(have) == "string" and (have:find("SpiritWalk", 1, true) or have:find("SuperBinds", 1, true)) then
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
  P._wheelActionButtonRejected = nil
  local claimed = {}
  local binds = SuperBindsDB.binds or {}
  for id, key in pairs(binds) do
    if type(key) == "string" and P.IsMouseKey(key) then
      claimed[key] = id
    end
  end
  local function bindKey(key, cmd, spec)
    if not P.Text(cmd) then return false end
    local ok, accepted = pcall(SetBinding, key, cmd)
    if ok and accepted then return true end
    -- Retail wheel often rejects ACTIONBUTTON. Bind the live slot's macro/spell
    -- so Shift-wheel-up matches click-THORN, not a named racial.
    if spec and P.ID(spec.slot) then
      local fallback = P.SlotContentCommand and P.SlotContentCommand(spec.slot)
      if P.Text(fallback) and fallback ~= cmd then
        ok, accepted = pcall(SetBinding, key, fallback)
        if ok and accepted then
          if type(key) == "string" and key:find("MOUSEWHEEL", 1, true) then
            P._wheelActionButtonRejected = true
          end
          return true
        end
      end
    end
    return false
  end
  for key, spec in pairs(MOUSE_HARDWARE) do
    if not P.IsAddonCameraKey(key) then
      pcall(SetBinding, key)
      local cmd = P.MouseKeyCommand(key)
      if not cmd and P.ID(spec.slot) then cmd = "ACTIONBUTTON" .. spec.slot end
      bindKey(key, cmd, spec)
    end
  end
  for _, frame in ipairs(P.BindFrames()) do
    local key = binds[frame._sbBindId]
    if type(key) == "string" and claimed[key] == frame._sbBindId
      and not P.IsCameraBinding(key)
      and not P.IsAddonCameraKey(key) then
      local cmd = P.FireableMouseCommand(frame, key)
      local spec = MOUSE_HARDWARE[key]
      pcall(SetBinding, key)
      bindKey(key, cmd, spec)
    end
  end
  P.RebuildOverrideList()
  P.FlushOverrides()
end

-- Keyboard pack faces (R = ACTIONBUTTON9). Call after mouse hardware so a
-- leftover wipe cannot leave R empty.
function P.BindPackBarKeys()
  if Locked() then return end
  for key, cmd in pairs(BAR_BINDS) do
    if P.Text(key) and type(cmd) == "string" and cmd:find("^ACTIONBUTTON")
      and not P.IsMouseKey(key) then
      local have = GetBindingAction(key)
      if not P.Text(have) then
        pcall(SetBinding, key, cmd)
      end
    end
  end
end

function P.ReclaimMouseOverrides()
  if Locked() or not SuperBindsDB.applied then return end
  P.EnsureBarDriver()
  P.RebuildOverrideList()
  P.FlushOverrides()
end

function P.PrintMouseDiag()
  print("|cff0070ddSuper Binds mouse:|r", P.OnSpecialBar() and "mount/vehicle bar active" or "addon layer")
  for _, key in ipairs({
    "MOUSEWHEELUP", "MOUSEWHEELDOWN", "SHIFT-MOUSEWHEELUP", "SHIFT-MOUSEWHEELDOWN",
    "CTRL-MOUSEWHEELUP", "CTRL-MOUSEWHEELDOWN",
    "BUTTON3", "SHIFT-BUTTON3", "BUTTON4", "CTRL-BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5",
  }) do
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
-- Faces on 8-12 (M5, R, M4) keep ACTIONBUTTON. This only rebinds mouse keys
-- onto those columns; it never wipes a keyboard chord such as R.
function P.ForceMouseHardware()
  if Locked() then return end
  if P.UseMountBar() then
    P.ApplyBar1Chrome()
    P.EnsureBarDriver()
    P.RebuildOverrideList()
    P.FlushOverrides()
    return
  end
  P.ForceMainPage()
  P.VacateBar6Helpers()
  P.PinHardwareButtons()
  P.BindMouseHardware()
  P.RestoreChatKeys()
  pcall(SaveBindings, GetCurrentBindingSet())
  P.PinHardwareButtons()
  P.ArmAllHardwareClicks()
end

function P.ThunderstormName()
  return nil
end

function P.BindThunderstormShiftE()
end

local function SetActionBar1Visible(visible)
  SuperBindsDB.hideBar1 = not visible
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
  if not SuperBindsDB.applied then return end
  C_Timer.After(0, function()
    P.EnsureBarDriver()
    P.ApplyBar1Chrome()
    if Locked() then P.pendingRefresh = true; return end
    if RefreshLayout then RefreshLayout(true) end
    P.DisableMouseCatch()
  end)
end)

-- Resolve one item spec -> {name,id,icon,macrotext,itemID,label,shortKey,key,note}
local function ResolveItem(item, bindNow)
  ApplyModOverride(item)
  if item.skyriding then
    if not (P.UseMountBar and P.UseMountBar()) then return nil end
    local name = P.Text(item.label) or P.Text(item.name)
    if not name then return nil end
    return AttachBindMeta({
      name = name, label = name, id = item.id,
      icon = item.iconFile or SpellIcon(item.id, name),
      bindKey = item.bindKey, key = item.key,
    }, item.bindKey)
  end
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
  -- Clear stale ACTIONBUTTON keys. RebindAll puts keyboard and mouse back on
  -- ACTIONBUTTON 1-12 so the same key follows the stance page.
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
  -- Hidden helpers only. Slots 8-10 are Heal / Empower / Move columns.
  local claimed = {}
  for _, cmd in pairs(BAR_BINDS) do
    if type(cmd) == "string" then claimed[cmd] = true end
  end
  for i = 8, 12 do
    local cmd = "ACTIONBUTTON" .. i
    if not claimed[cmd] then
      ClearCommandKeys(cmd)
      P.managedCommands[cmd] = true
    end
  end
end

-- Lua 5.1: one function may close over 60 outer locals. BuildEverything
-- is too large; call helpers through this table (one upvalue: P).
P._L = {
  SanitizeSavedBinds = SanitizeSavedBinds,
  ScanBook = ScanBook,
  ResetHiddenSlots = ResetHiddenSlots,
  BuildFamilies = BuildFamilies,
  CopyItem = CopyItem,
  PlacePrimaryOnBar = PlacePrimaryOnBar,
  PlaceMacro = PlaceMacro,
  PlaceID = PlaceID,
  EnsureClickButton = EnsureClickButton,
  ClickCommand = ClickCommand,
  FormNow = FormNow,
  EnsureConsole = EnsureConsole,
  EnsureTab = EnsureTab,
  WireDropTargets = WireDropTargets,
  PackFormNow = PackFormNow,
  FamilyPrimaryBindKey = FamilyPrimaryBindKey,
  ResolveItem = ResolveItem,
  SpellIcon = SpellIcon,
  NormalizeAbility = NormalizeAbility,
  RouteToHiddenSlot = RouteToHiddenSlot,
  AttachBindMeta = AttachBindMeta,
  DedupResolved = DedupResolved,
  BarPrimary = BarPrimary,
  EffectiveKey = EffectiveKey,
  SetTabFace = SetTabFace,
  StyleKeyText = StyleKeyText,
  WireQuickKeybind = WireQuickKeybind,
  ShortKey = ShortKey,
  PrettyKey = PrettyKey,
  AllocHiddenSlot = AllocHiddenSlot,
  CastMacro = CastMacro,
  NeedsBlizzardSlot = NeedsBlizzardSlot,
  SetupClickButton = SetupClickButton,
  SameAbility = SameAbility,
  ApplyExtraOrder = ApplyExtraOrder,
  FirstActionLine = FirstActionLine,
  IsGroundName = IsGroundName,
  NoteChordLine = NoteChordLine,
  LayoutMenu = LayoutMenu,
  ConfigureMMBChord = ConfigureMMBChord,
  RefreshBindLabels = RefreshBindLabels,
  OnQuickKeybindMode = OnQuickKeybindMode,
  InQuickKeybind = InQuickKeybind,
  Known = Known,
  Locked = Locked,
  ClearSlot = ClearSlot,
}

local function BuildEverything(bindNow)
  local L = P._L
  if bindNow then L.SanitizeSavedBinds() else P.EnsureDB() end
  L.ScanBook()
  wipe(PLACED_SPELLS)
  if bindNow then
    L.ResetHiddenSlots()
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
  local families = L.BuildFamilies()
  P.AppendTrinketFamilies(families, trinkets)
  local rotation = P._rotationHideSet
  local display = {}

  -- Pass 1: bar-1 placements (only when applying fully).
  if bindNow then
    P.ForceMainPage()
    P.VacateBar6Helpers()
    wipe(KEEP)
    P.VacateUnclaimedBarSlots()
    P.extraBarBindings = {}
    local placedAbsolute = {}
    local function placeEach(entry, fn)
      P.EachBarSlot(entry, function(abs, formName)
        if not placedAbsolute[abs] then
          placedAbsolute[abs] = true
          fn(abs, formName)
        end
      end)
    end
    for _, fam in ipairs(families) do
      if fam.tag then P.MigrateFormPrimary(fam.tag) end
      local barList = {}
      if type(fam.bars) == "table" then
        for formName, spec in pairs(fam.bars) do
          if type(spec) == "table" then
            local e = L.CopyItem(spec)
            e.form = formName
            barList[#barList + 1] = e
          end
        end
      else
        if fam.bar then barList[#barList + 1] = fam.bar end
        if fam.bar2 then barList[#barList + 1] = fam.bar2 end
      end
      for _, it in ipairs(fam.items or {}) do
        if it.slot and (it.spell or it.macro or it.sba) then
          barList[#barList + 1] = it
        end
      end
      for _, barEntry in ipairs(barList) do
        if barEntry then
          placeEach(barEntry, function(abs, formName)
            pcall(ClearCursor)
            local overlay = fam.tag and P.CustomPrimaryFor(fam.tag, formName or barEntry.form)
            if overlay and P.IsEmptyPrimary(overlay) then
              L.ClearSlot(abs)
              pcall(ClearCursor)
              return
            end
            if overlay then
              L.PlacePrimaryOnBar(abs, overlay)
              local pn = overlay.name or overlay.label
              if P.Text(pn) then PLACED_SPELLS[pn] = true end
              pcall(ClearCursor)
              return
            end
            if barEntry.sba then
              P.PlaceAssisted(abs)
            elseif barEntry.macro then
              L.PlaceMacro(abs, barEntry.macro[1], barEntry.macro[2], barEntry.macro[3])
              if barEntry.covers then
                for _, n in ipairs(barEntry.covers) do PLACED_SPELLS[n] = true end
              end
            elseif barEntry.spell then
              local name, id = L.Known(unpack(barEntry.spell))
              if name then
                L.PlaceID(abs, id)
                PLACED_SPELLS[name] = true
              end
            end
            pcall(ClearCursor)
          end)
          if barEntry == fam.bar2 and KEEP[barEntry.slot] then
            local bindId = "bar:" .. barEntry.slot
            local helper = L.EnsureClickButton(bindId)
            if not L.Locked() then
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
              _sbBindId = bindId, commandName = L.ClickCommand(bindId), _sbDefaultKey = defaultKey,
            }
          end
        end
      end
    end
    pcall(ClearCursor)
    P.VacateUnclaimedBarSlots()
  else
    -- Mark bar spells so drop-downs / autofill don't duplicate them.
    for _, fam in ipairs(families) do
      local barList = { fam.bar, fam.bar2 }
      if type(fam.bars) == "table" then
        for _, spec in pairs(fam.bars) do barList[#barList + 1] = spec end
      end
      for _, it in ipairs(fam.items or {}) do
        if it.slot then barList[#barList + 1] = it end
      end
      for _, barEntry in ipairs(barList) do
        if barEntry then
          if barEntry.covers then
            for _, n in ipairs(barEntry.covers) do PLACED_SPELLS[n] = true end
          end
          if barEntry.spell then
            local name = L.Known(unpack(barEntry.spell))
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
  for _, custom in pairs(SuperBindsDB.custom or {}) do
    if P.MigrateAddedPerForm then P.MigrateAddedPerForm(custom, L.FormNow and L.FormNow()) end
    if type(custom.addedForms) == "table" then
      for _, list in pairs(custom.addedForms) do
        if type(list) == "table" then
          for _, ability in ipairs(list) do
            if ability.name then customCoverage[ability.name] = true end
          end
        end
      end
    end
  end
  -- Pass 2: menus.
  L.EnsureConsole()
  for famIndex, fam in ipairs(families) do
    local tab, menu = L.EnsureTab(famIndex, fam)
    tab.famTitle = fam.title
    L.WireDropTargets(tab, menu, fam.tag)
    if fam.tag then P.MigrateFormPrimary(fam.tag) end
    local custom = not fam.equipmentSlot and SuperBindsDB.custom and SuperBindsDB.custom[fam.tag]
    local customP = fam.tag and P.CustomPrimaryFor(fam.tag, L.PackFormNow())
    local primaryBindKey = L.FamilyPrimaryBindKey(fam)
    -- Keep the tab face and the primary key on the same ability.
    if customP and primaryBindKey and not P.IsEmptyPrimary(customP) then
      SuperBindsDB.mods = SuperBindsDB.mods or {}
      SuperBindsDB.mods[primaryBindKey] = customP
    elseif customP and P.IsEmptyPrimary(customP) and primaryBindKey then
      SuperBindsDB.mods = SuperBindsDB.mods or {}
      SuperBindsDB.mods[primaryBindKey] = nil
    end
    local resolved = {}
    for _, item in ipairs(fam.items) do
      local r = L.ResolveItem(item, bindNow)
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
        resolved[#resolved + 1] = L.AttachBindMeta({ name = nm, id = BOOK[nm], label = nm, icon = L.SpellIcon(BOOK[nm]) })
      end
    end

    if custom then
      local formNow = L.FormNow and L.FormNow() or (P.DrawerForm and P.DrawerForm()) or (L.PackFormNow and L.PackFormNow())
      local visible = {}
      for _, r in ipairs(resolved) do
        if not (P.ExtraIsHidden and P.ExtraIsHidden(custom, r, formNow)) then
          visible[#visible + 1] = r
        end
      end
      resolved = visible
      if P.MigrateAddedPerForm then P.MigrateAddedPerForm(custom, formNow) end
      local extras = {}
      if formNow and type(custom.addedForms) == "table" and type(custom.addedForms[formNow]) == "table" then
        for _, a in ipairs(custom.addedForms[formNow]) do extras[#extras + 1] = a end
      end
      for _, a in ipairs(extras) do
        local copy = L.NormalizeAbility(a)
        -- Explicit user additions may live in more than one family. The global
        -- coverage table is only for auto-fill; L.DedupResolved handles this drawer.
        if copy then
          copy.bindKey = a.bindKey or copy.bindKey
          resolved[#resolved + 1] = L.RouteToHiddenSlot(L.AttachBindMeta(copy), bindNow)
        end
      end
    end



    resolved = L.DedupResolved(resolved)

    local slotKey = fam.bar and fam.bar.key or primaryBindKey
    local slotFace
    if primaryBindKey then
      for _, r in ipairs(resolved) do
        if r.bindKey == primaryBindKey then slotFace = r break end
      end
    end

    local primary
    if fam.bar then primary = L.BarPrimary(fam.bar)
    else primary = slotFace or resolved[1] end
    if customP and P.IsEmptyPrimary(customP) then
      primary = { empty = true, label = "", name = "", icon = 134400, key = slotKey }
    elseif customP then
      local p = customP
      primary = {
        name = p.name, id = p.id, label = p.label or p.name, icon = p.icon or L.SpellIcon(p.id),
        itemID = p.itemID, macrotext = p.macrotext, sba = p.sba or P.IsAssistedAbility(p) or nil, key = slotKey,
      }
      -- The primary action was placed during pass 1 (slot 5 is finalized below).
    elseif slotFace then
      primary = slotFace
      primary.key = slotKey
    elseif primary then
      primary.key = slotKey or primary.key
    end
    if fam.bar and fam.bar.slot then
      local bindId = "bar:" .. fam.bar.slot
      local defaultKey = fam.bar.bindKey or fam.bar.key or slotKey
      if primary then
        primary.key = L.EffectiveKey(bindId, defaultKey) or defaultKey or primary.key
      end
    end
    if fam.bar and fam.bar.slot then
      local abs = (P.LiveActionSlot and P.LiveActionSlot(fam.bar.slot)) or P.ActionSlot(fam.bar.slot, L.PackFormNow())
      local native = P.NativeAbility(abs)
      local shapeshiftFace = P.AbilityLooksLikeShapeshift and P.AbilityLooksLikeShapeshift(fam.bar)
      if native then
        native.key = slotKey
        native.sba = P.IsAssistedAbility(native) or nil
        if shapeshiftFace then
          if P.AbilityLooksLikeShapeshift(native) then primary = native end
        elseif P.UseMountBar and P.UseMountBar() then
          local rel = tonumber(fam.bar.slot)
          if rel == 1 or rel == 2 or rel == 7 then primary = native end
        else
          primary = native
        end
      end
    end
    if primary and fam.bar and fam.bar.slot then
      local bindId = "bar:" .. fam.bar.slot
      local defaultKey = fam.bar.bindKey or fam.bar.key or slotKey
      primary.key = L.EffectiveKey(bindId, defaultKey) or defaultKey or primary.key
    end
    L.SetTabFace(tab, primary)
    tab._sbNativeSBA = primary and P.IsAssistedAbility(primary) or false
    if fam.tag == "+" and tab.keyText then
      L.StyleKeyText(tab.keyText)
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
    -- Shapeshifts are the same spell on every page, including skyriding.
    local shapeshiftFace = fam.bar and P.AbilityLooksLikeShapeshift and P.AbilityLooksLikeShapeshift(fam.bar)
    if shapeshiftFace and primary and not L.Locked() then
      tab:EnableMouse(true)
      if tab.SetMouseClickEnabled then tab:SetMouseClickEnabled(true) end
      tab:SetAttribute("type", "spell")
      tab:SetAttribute("typerelease", "spell")
      tab:SetAttribute("spell", primary.name or primary.label)
      tab:SetAttribute("relslot", nil)
      tab:SetAttribute("action", nil)
      tab:SetAttribute("shift-type1", "")
      tab:SetAttribute("shift-typerelease1", "")
    elseif primary and fam.bar and fam.bar.slot and not L.Locked() then
      tab:EnableMouse(true)
      if tab.SetMouseClickEnabled then tab:SetMouseClickEnabled(true) end
      tab:SetAttribute("type", "action")
      tab:SetAttribute("typerelease", "action")
      tab:SetAttribute("relslot", fam.bar.slot)
      local abs = (P.LiveActionSlot and P.LiveActionSlot(fam.bar.slot))
        or (P.ActionSlot and P.ActionSlot(fam.bar.slot, L.PackFormNow())) or fam.bar.slot
      tab:SetAttribute("action", abs)
      -- Shift is layout-drag, not a modified cast of this face.
      tab:SetAttribute("shift-type1", "")
      tab:SetAttribute("shift-typerelease1", "")
    end
    if shapeshiftFace and primary and fam.bar and fam.bar.slot then
      local defaultKey = fam.bar.bindKey or fam.bar.key
      local bindId = "bar:" .. fam.bar.slot
      L.WireQuickKeybind(tab, P.HotkeyCommand(tab, fam.bar.slot, defaultKey), bindId, defaultKey)
      local live = L.EffectiveKey(bindId, defaultKey)
      local label = L.ShortKey(live) or L.PrettyKey(live) or live or ""
      if tab.keyText then tab.keyText:SetText(label) end
      tab.tipKey = label
    elseif primary and fam.bar and fam.bar.slot then
      local action = "ACTIONBUTTON" .. fam.bar.slot
      local defaultKey = fam.bar.bindKey or fam.bar.key
      if not defaultKey then
        for key, act in pairs(BAR_BINDS) do
          if act == action then defaultKey = key break end
        end
      end
      local bindId = "bar:" .. fam.bar.slot
      -- Keyboard: CLICK the tab (absolute action). Mouse: ACTIONBUTTON
      -- on this slot — CLICK helpers do not fire for M4/M5.
      L.WireQuickKeybind(tab, P.HotkeyCommand(tab, fam.bar.slot, defaultKey), bindId, defaultKey)
      local live = L.EffectiveKey(bindId, defaultKey)
      local label = L.ShortKey(live) or L.PrettyKey(live) or live or ""
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
          L.RouteToHiddenSlot(primary, bindNow)
          if not primary.blizzardSlot then
            local info = L.AllocHiddenSlot(bindId)
            local body = primary.macrotext
            if not body and (primary.name or primary.label) then
              body = L.CastMacro(primary.name or primary.label, "plain")
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
          L.RouteToHiddenSlot(primary, bindNow)
        end
      end
      if primary and primary.blizzardSlot and L.NeedsBlizzardSlot(primary) and not L.Locked() then
        tab:EnableMouse(true)
        if tab.SetMouseClickEnabled then tab:SetMouseClickEnabled(true) end
        tab:SetAttribute("type", "action")
        tab:SetAttribute("typerelease", "action")
        tab:SetAttribute("action", primary.blizzardSlot)
        L.WireQuickKeybind(tab, primary.commandName, bindId, slotKey)
      elseif primary.macroIndex then
        tab:EnableMouse(true)
        if tab.SetMouseClickEnabled then tab:SetMouseClickEnabled(true) end
        tab:SetAttribute("type", "macro")
        tab:SetAttribute("typerelease", "macro")
        tab:SetAttribute("macro", primary.macroIndex)
        L.WireQuickKeybind(tab, P.HardwareCommand(slotKey, primary.blizzardSlot, primary.commandName), bindId, slotKey)
      else
        if primary then L.SetupClickButton(bindId, primary) end
        tab:EnableMouse(true)
        if tab.SetMouseClickEnabled then tab:SetMouseClickEnabled(true) end
        L.WireQuickKeybind(tab, P.HardwareCommand(slotKey, primary.blizzardSlot, L.ClickCommand(bindId)), bindId, slotKey)
        if not L.Locked() then
          local helper = L.EnsureClickButton(bindId)
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
      local live = L.EffectiveKey(bindId, slotKey)
      local label = L.ShortKey(live) or L.PrettyKey(live) or live or ""
      if tab.keyText then tab.keyText:SetText(label) end
      tab.tipKey = label
    elseif primary then
      local bindId = primary.equipmentSlot and primary.bindId or ("primary:" .. fam.tag)
      primary.bindId = bindId
      L.RouteToHiddenSlot(primary, bindNow)
      if primary.blizzardSlot then
        tab:SetAttribute("type", "action")
        tab:SetAttribute("typerelease", "action")
        tab:SetAttribute("action", primary.blizzardSlot)
      elseif primary.macroIndex then
        tab:SetAttribute("type", "macro")
        tab:SetAttribute("typerelease", "macro")
        tab:SetAttribute("macro", primary.macroIndex)
      end
      L.SetupClickButton(bindId, primary)
      tab:EnableMouse(true)
      if tab.SetMouseClickEnabled then tab:SetMouseClickEnabled(true) end
      local defaultKey = primary.defaultKey or P.TrinketDefaultKey(primary.equipmentSlot)
      L.WireQuickKeybind(tab, primary.commandName or L.ClickCommand(bindId), bindId, defaultKey)
      tab.tipKey = L.ShortKey(L.EffectiveKey(bindId, defaultKey))
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
      elseif primary and L.SameAbility(r, primary) then
        -- this spell is the face now (BIND swap); do not keep it in the drawer
      else
        extras[#extras + 1] = r
      end
    end
    extras = L.ApplyExtraOrder(fam.tag, extras)
    -- Wheel extra keys fire through their own hidden slots. Chord lines must match
    -- the icons we just resolved, not leftover stock macros.
    if fam.tag == "T" then
      for _, r in ipairs(extras) do
        if r.bindKey and MMB_CHORD[r.bindKey] then
          local line = L.FirstActionLine(r.macrotext)
          if not line and r.name then
            line = (L.IsGroundName(r.name) and "/cast [@cursor] " or "/cast ") .. r.name
          end
          L.NoteChordLine(r.bindKey, line)
        end
      end
    end
    L.LayoutMenu(famIndex, fam.tag, extras, nil, bindNow)

    -- Keymap group.
    local entries = {}
    for _, barEntry in ipairs({ fam.bar, fam.bar2 }) do
      if barEntry then
        local label, icon
        if barEntry.sba then
          label, icon = barEntry.label, L.SpellIcon(SBA_ID)
        elseif barEntry.macro then
          label, icon = barEntry.label or barEntry.macro[1], barEntry.macro[2]
        elseif barEntry.spell then
          local name, id = L.Known(unpack(barEntry.spell))
          if name then label, icon = barEntry.label or name, L.SpellIcon(id) end
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
    P.ReleaseNativeHost(tab)
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
    L.ConfigureMMBChord()
    P.ConnectCastRoutes()
    P.RebindAll()
  else
    L.RefreshBindLabels()
    if not L.Locked() then
      for _, frame in ipairs(P.BindFrames()) do
        local keep = L.EffectiveKey(frame._sbBindId, frame._sbDefaultKey)
        P.ReleaseStaleBindKeys(frame, frame._sbBindId, keep, frame.commandName)
      end
    end
  end
  -- Login / form rebuild must still arm the stance-page clicker. bindNow-only
  -- left tabs stuck on caster slots after /reload until the next full Apply.
  if P.EnsureFormPageDriver then P.EnsureFormPageDriver() end
  P.ArmAllHardwareClicks()
  L.OnQuickKeybindMode(L.InQuickKeybind())
  P.UpdateMovePads()
  P.RefreshMoveChrome()
  P.EnsureTotemReady(console)
  P.UpdateTotemReady()
  if P.SyncNativeSBAHosts then P.SyncNativeSBAHosts() end
  if P.DriveIconCooldowns then P.DriveIconCooldowns() end
  if P.DriveAssistedHighlights then P.DriveAssistedHighlights() end
  return display
end

function P.RebuildConsole()
  P.EnsureDB()
  pcall(BuildEverything, false)
  if P.RefreshNbaStrip then P.RefreshNbaStrip() end
end

local function Apply(showKeymap)
  if Locked() then P.Report("Leave combat before applying a layout."); return false end
  if busy then
    P.Report("Still finishing a layout pass. Wait a second, then /superbinds again.")
    return false
  end
  local cursorKind = P.CursorKind()
  if cursorKind and cursorKind ~= "secret" then
    P.Report("Finish the cursor drag before applying.")
    return false
  end
  if not P.ClassHasPack or not P.ClassHasPack() then
    print("|cff0070ddSuper Binds:|r no pack for this class.")
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
  SuperBindsDB.hideBar1 = true
  P.ApplyBar1Chrome()
  -- Applying owns this addon's target slots only. Do not wipe other bars,
  -- delete macros by generic name, or clear unrelated user keys.


  local display = BuildEverything(true)
  P.ApplyBar1Chrome()

  SaveBindings(GetCurrentBindingSet())



  SuperBindsDB.display = display
  SuperBindsDB.applied = true

  P.PrintSBA()
  local pack = P.CurrentPack and P.CurrentPack()
  print("|cff0070ddSuper Binds:|r layout applied. |cffffffff/superbinds save|r / |cffffffffload|r / |cfffffffflist|r  ·  |cffffffff/superbinds reset|r restores pack keys.")
  if pack and P.Text(pack.appliedNote) then
    P.Report(pack.appliedNote)
  end
  if P.PrintBindNotices then P.PrintBindNotices() end
  if SuperBindsPrompt then SuperBindsPrompt:Hide() end
  if showKeymap then
    P.PopulateKeymap(P.LiveKeymapDisplay())
    P.EnsureKeymapFrame():Show()
  elseif keymapFrame then
    keymapFrame:Hide()
  end
  ClearDrag()
  if P.RefreshNbaStrip then P.RefreshNbaStrip() end
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
  if not SuperBindsDB.applied then return end
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
  prompt = CreateFrame("Button", "SuperBindsPrompt", UIParent, "UIPanelButtonTemplate")
  prompt:SetSize(340, 36)
  prompt:SetPoint("CENTER", 0, 220)
  prompt:SetText("Apply Super Binds  (/superbinds)")
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
boot:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
boot:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
boot:SetScript("OnEvent", function(self, event, unit, _, spellID)
  if P.ClassHasPack and not P.ClassHasPack() then return end
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
    if P._pendingSpecialBar and P.SyncSpecialBarState then P.SyncSpecialBarState() end
    if P.pendingFormKeys and P.SyncFormKeyDriver then P.SyncFormKeyDriver() end
    if P.pendingSpecPack then
      local n = P.pendingSpecPack
      P.pendingSpecPack = nil
      if P.LoadProfile then P.LoadProfile(n) end
    end
    if P.SyncNativeSBAHosts then P.SyncNativeSBAHosts() end
    P.RestoreChatKeys()
    P._nbaCp = 0
    P._nbaOpened = false
    P._nbaProwled = false
    P._nbaSpendI = 1
    return
  end
  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    if unit ~= "player" then return end
    if P.NotePressPulseCast then P.NotePressPulseCast(spellID) end
    if P.NbaNoteCast then pcall(P.NbaNoteCast, spellID) end
    local id = P.ID(spellID)
    if id then
      P.castAt = P.castAt or {}
      P.castAt[id] = { t = GetTime() }
    end
    return
  end
  if event == "UPDATE_SHAPESHIFT_FORM" then
    P.PULSE_GCD = nil
    -- Icons only. Bars were placed on apply; PlaceID on every shift steals the cursor.
    if P.ApplyEndcapArt then P.ApplyEndcapArt() end
    if P.RefreshNbaStrip then P.RefreshNbaStrip() end
    if SuperBindsDB.applied then
      local barForm = PackFormNow()
      local drawerForm = P.DrawerForm and P.DrawerForm()
      -- Ground travel keeps caster slots. Drawers still change caster → travel.
      if barForm == P._layoutForm and drawerForm == P._layoutDrawerForm then
        if P.DriveIconCooldowns then P.DriveIconCooldowns() end
        return
      end
      P._layoutForm = barForm
      P._layoutDrawerForm = drawerForm
      P._shapeGen = (P._shapeGen or 0) + 1
      local gen = P._shapeGen
      C_Timer.After(0.08, function()
        if gen ~= P._shapeGen then return end
        if P.DrawerForm then P.DrawerForm() end
        if Locked() then P.pendingRefresh = true
        else RefreshLayout(true) end
      end)
    end
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
    if P.FollowSpecPack and P.FollowSpecPack() then
      return
    end
    if SuperBindsDB.applied then
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
    SuperBindsDB.display = BuildEverything(automatic ~= true)
    P.EnsureBarDriver()
    P.SyncSpecialBarState()
    P.ApplyBar1Chrome()
    P.RebuildOverrideList()
    P.FlushOverrides()
    P.RestoreChatKeys()
    if InQuickKeybind and InQuickKeybind() then
      if HoldMenus then HoldMenus(true) end
      for _, menu in pairs(menus) do menu:Show() end
      if P.LayoutBindMenus then P.LayoutBindMenus(true) end
    end
    if P.RefreshNbaStrip then P.RefreshNbaStrip() end
    if P.SyncFormKeyDriver then P.SyncFormKeyDriver() end
  end)
  busy = false
  if not ok then P.Report("Layout update failed: " .. tostring(err))
  else
    P._layoutForm = PackFormNow and PackFormNow()
    P._layoutDrawerForm = P.DrawerForm and P.DrawerForm()
  end
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
  local pos = SuperBindsDB.pos
  if pos and console and pos.console then
    local p = pos.console
    console:ClearAllPoints()
    console:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  end
  P.RestoreTotemPlaces()
  if P.PlaceBindButton then P.PlaceBindButton() end
  if P.PlacePressPulse then P.PlacePressPulse() end
end

function P.SnapshotCurrent()
  if console then SavePosition("console", console) end
  return {
    familyMode = SuperBindsDB.familyMode or "legacy",
    custom = P.CopyData(SuperBindsDB.custom or {}),
    pos = P.CopyData(SuperBindsDB.pos or {}),
    totemPos = P.CopyData(SuperBindsDB.totemPos or {}),
    binds = P.CopyData(SuperBindsDB.binds or {}),
    barBinds = P.CopyData(SuperBindsDB.barBinds or {}),
    formBinds = P.CopyData(SuperBindsDB.formBinds or {}),
    mods = P.CopyData(SuperBindsDB.mods or {}),
  }
end

function P.ProfileNames()
  local names = {}
  for name in pairs(SuperBindsDB.profiles or {}) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

function P.SaveProfile(name)
  P.EnsureDB()
  name = strtrim(type(name) == "string" and name or "")
  if name == "" then
    name = SuperBindsDB.activeProfile or (P.CurrentPack and P.CurrentPack() and P.CurrentPack().name) or "Default"
  end
  SuperBindsDB.profiles = SuperBindsDB.profiles or {}
  SuperBindsDB.profiles[name] = P.SnapshotCurrent()
  SuperBindsDB.activeProfile = name
  print("|cff0070ddSuper Binds:|r saved profile |cffffffff" .. name .. "|r")
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
    print("|cff0070ddSuper Binds:|r usage: |cffffffff/superbinds load <name>|r")
    return
  end
  local pack = P.FindPack and P.FindPack(name)
  local profile = SuperBindsDB.profiles and SuperBindsDB.profiles[name]
  if not profile then
    for n, p in pairs(SuperBindsDB.profiles or {}) do
      if strlower(n) == strlower(name) then profile, name = p, n break end
    end
  end
  if pack and not profile then
    profile = { familyMode = pack.familyMode or pack.name, custom = {}, pos = {}, binds = {}, barBinds = {}, mods = {} }
    name = pack.name
  end
  if not profile then
    print("|cff0070ddSuper Binds:|r no profile named |cffffffff" .. name .. "|r. |cffffffff/superbinds list|r")
    return
  end
  P.ClearFamilyKeys()
  local mode = profile.familyMode or (pack and (pack.familyMode or pack.name))
  if not P.Text(mode) then mode = name end
  if pack and SuperBindsDB.applied then
    local prev = SuperBindsDB.activeProfile
    if P.Text(prev) and prev ~= name and P.SnapshotCurrent then
      SuperBindsDB.profiles[prev] = P.SnapshotCurrent()
    end
    local backup, n = "Before " .. pack.name, 1
    while SuperBindsDB.profiles[backup] do n = n + 1; backup = "Before " .. pack.name .. " " .. n end
    SuperBindsDB.profiles[backup] = P.SnapshotCurrent()
    P.Report("Current setup saved as '" .. backup .. "'.")
  end
  SuperBindsDB.familyMode = mode
  SuperBindsDB.familyRevision = 1
  P.SelectFamilyHardware()
  SuperBindsDB.custom = P.CopyData(profile.custom or {})
  if type(profile.pos) == "table" and next(profile.pos) then
    SuperBindsDB.pos = P.CopyData(profile.pos)
  end
  if type(profile.totemPos) == "table" then
    SuperBindsDB.totemPos = P.CopyData(profile.totemPos)
  end
  SuperBindsDB.binds = P.CopyData(profile.binds or {})
  SuperBindsDB.barBinds = P.CopyData(profile.barBinds or {})
  SuperBindsDB.formBinds = P.CopyData(profile.formBinds or {})
  SuperBindsDB.mods = P.CopyData(profile.mods or {})
  SuperBindsDB.activeProfile = name
  P.EnsureDB()
  if not Apply() then return false end
  P.RestorePositions()
  P.RefreshMoveChrome()
  print("|cff0070ddSuper Binds:|r loaded profile |cffffffff" .. name .. "|r")
  return true
end

function P.FollowSpecPack()
  local pack, name = P.PackForPlayerSpec()
  if not pack or not P.Text(name) then return false end
  if SuperBindsDB.activeProfile == name then return false end
  if Locked() then
    P.pendingSpecPack = name
    return false
  end
  return P.LoadProfile(name) == true
end

function P.DeleteProfile(name)
  name = strtrim(type(name) == "string" and name or "")
  if name == "" or not (SuperBindsDB.profiles and SuperBindsDB.profiles[name]) then
    print("|cff0070ddSuper Binds:|r no profile named |cffffffff" .. (name ~= "" and name or "?") .. "|r")
    return
  end
  SuperBindsDB.profiles[name] = nil
  if SuperBindsDB.activeProfile == name then SuperBindsDB.activeProfile = nil end
  print("|cff0070ddSuper Binds:|r deleted profile |cffffffff" .. name .. "|r")
end

function P.ListProfiles()
  P.EnsureDB()
  local names, seen = {}, {}
  for n, t in pairs(P.Packs or {}) do
    if P.PackMatches(t) then names[#names + 1] = n; seen[n] = true end
  end
  for n in pairs(SuperBindsDB.profiles or {}) do
    if not seen[n] then names[#names + 1] = n end
  end
  table.sort(names)
  if #names == 0 then
    print("|cff0070ddSuper Binds:|r no packs. Add a profile lua to the TOC.")
    return
  end
  local active = SuperBindsDB.activeProfile
  print("|cff0070ddSuper Binds packs:|r")
  for _, name in ipairs(names) do
    local mark = (name == active) and " |cffaaaaaa(active)|r" or ""
    local pack = P.FindPack and P.FindPack(name)
    if pack and pack.default then mark = mark .. " |cff999999(default)|r" end
    print("  |cffffffff" .. name .. "|r" .. mark)
  end
end

function P.ApplyMountBarSetting()
  P.EnsureBarDriver()
  P.SyncMountBarDriver()
  P.ApplyBar1Chrome()
  if Locked() then return end
  P.RebuildOverrideList()
  P.FlushOverrides()
end

function P.OpenSettings()
  P.RegisterSettings()
  if P.WatchSettingsPulsePreview then P.WatchSettingsPulsePreview() end
  local cat = P.settingsCategory
  if not cat or type(Settings) ~= "table" or type(Settings.OpenToCategory) ~= "function" then
    P.Report("Settings panel is not available on this client.")
    return
  end
  local id = cat.GetID and cat:GetID() or cat.ID
  if id then Settings.OpenToCategory(id) end
  if SuperBindsDB.showPressPulse ~= false and P.BeginPulsePreview then
    P.BeginPulsePreview()
  end
end

function P.RegisterSettings()
  if P.WatchSettingsPulsePreview then P.WatchSettingsPulsePreview() end
  if P.settingsCategory then return end
  if type(Settings) ~= "table" then return end
  if type(Settings.RegisterVerticalLayoutCategory) ~= "function" then return end
  if type(Settings.RegisterProxySetting) ~= "function" then return end
  P.EnsureDB()
  local category, layout = Settings.RegisterVerticalLayoutCategory("Super Binds")
  P.settingsCategory = category
  local boolType = (Settings.VarType and Settings.VarType.Boolean) or type(false)
  local defTrue = (Settings.Default and Settings.Default.True)
  if defTrue == nil then defTrue = true end
  local defFalse = (Settings.Default and Settings.Default.False)
  if defFalse == nil then defFalse = false end

  local function addBool(key, name, default, tooltip, apply)
    local setting = Settings.RegisterProxySetting(
      category,
      "SUPERBINDS_" .. key,
      boolType,
      name,
      default,
      function() return SuperBindsDB[key] and true or false end,
      function(value)
        SuperBindsDB[key] = value and true or false
        if apply then apply(value) end
      end
    )
    Settings.CreateCheckbox(category, setting, tooltip)
  end

  if type(CreateSettingsListSectionHeaderInitializer) == "function" and layout then
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Bars"))
  end
  addBool("hideBar1", "Hide Blizzard action bar 1", defTrue,
    "Fade the stock main action bar. The console stays. Mount/vehicle bars can still appear if that option is on.",
    function() P.ApplyBar1Chrome() end)
  addBool("hideConsoleMounted", "Hide console while mounted", defTrue,
    "Hide the console on a mount or in a vehicle. The Blizzard mount bar can still show.",
    function() P.ApplyConsoleMountedHide() end)

  if type(CreateSettingsListSectionHeaderInitializer) == "function" and layout then
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("GCD pulse"))
  end
  addBool("showPressPulse", "Show GCD pulse", defTrue,
    "Combat-only gold ring. Dark swipe runs to the gold slice during the GCD. Press while the edge is in that slice. Opening this panel previews the loop. Drag the ring to move it.",
    function(value)
      if value then
        if P.BeginPulsePreview then P.BeginPulsePreview() end
      else
        if P.EndPulsePreview then P.EndPulsePreview() end
        if P.ApplyPressPulseShown then P.ApplyPressPulseShown() end
      end
    end)

  local numType = (Settings.VarType and Settings.VarType.Number) or type(1)
  local pulseOpacitySetting
  if type(Settings.CreateSliderOptions) == "function" then
    pulseOpacitySetting = Settings.RegisterProxySetting(
      category,
      "SUPERBINDS_pulseOpacity",
      numType,
      "GCD pulse opacity",
      20,
      function()
        return P.PulseOpacityPercent()
      end,
      function(value)
        P.CommitPulseOpacity(value, true)
      end
    )
    pcall(function()
      pulseOpacitySetting:SetValueChangedCallback(function(_, value)
        P.CommitPulseOpacity(value, true)
      end)
    end)
    local options = Settings.CreateSliderOptions(10, 100, 5)
    if options.SetLabelFormatter then
      pcall(function()
        local label = MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label and MinimalSliderWithSteppersMixin.Label.Right
        options:SetLabelFormatter(label, function(v)
          return tostring(math.floor((P.PublicNumber(v) or 0) + 0.5)) .. "%"
        end)
      end)
    end
    local tooltip = "How solid the GCD pulse is. 20% is the shipped look. Drag to preview out of combat; glow and bezel follow this slider."
    if type(Settings.CreateSlider) == "function" then
      Settings.CreateSlider(category, pulseOpacitySetting, options, tooltip)
    elseif type(Settings.CreateSliderInitializer) == "function" and layout then
      layout:AddInitializer(Settings.CreateSliderInitializer(pulseOpacitySetting, options, tooltip))
    end
  end
  if type(CreateSettingsButtonInitializer) == "function" and layout then
    layout:AddInitializer(CreateSettingsButtonInitializer(
      "GCD pulse opacity", "Default",
      function()
        SuperBindsDB.pulseOpacity = P.PULSE_OPACITY_DEFAULT or 0.2
        if pulseOpacitySetting and pulseOpacitySetting.SetValue then
          pcall(pulseOpacitySetting.SetValue, pulseOpacitySetting, 20)
        end
        if P.CommitPulseOpacity then P.CommitPulseOpacity(20, true) end
      end,
      "Restore the shipped GCD pulse opacity (20%).", true))
  end

  local pulseWindowSetting
  if type(Settings.CreateSliderOptions) == "function" then
    pulseWindowSetting = Settings.RegisterProxySetting(
      category,
      "SUPERBINDS_pulseWindow",
      numType,
      "Hit window",
      75,
      function()
        return P.PulseWindowHundredths()
      end,
      function(value)
        P.CommitPulseWindow(value, true)
      end
    )
    pcall(function()
      pulseWindowSetting:SetValueChangedCallback(function(_, value)
        P.CommitPulseWindow(value, true)
      end)
    end)
    local winOpts = Settings.CreateSliderOptions(10, 150, 5)
    if winOpts.SetLabelFormatter then
      pcall(function()
        local label = MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label and MinimalSliderWithSteppersMixin.Label.Right
        winOpts:SetLabelFormatter(label, function(v)
          local n = P.PulseWindowHundredths(v)
          return string.format("%.2fs", n / 100)
        end)
      end)
    end
    local winTip = "How long the edge spends traveling through the gold slice. Default 0.75s. 0.10–1.50s."
    if type(Settings.CreateSlider) == "function" then
      Settings.CreateSlider(category, pulseWindowSetting, winOpts, winTip)
    elseif type(Settings.CreateSliderInitializer) == "function" and layout then
      layout:AddInitializer(Settings.CreateSliderInitializer(pulseWindowSetting, winOpts, winTip))
    end
  end

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
    "When you mount or enter a vehicle, show the Blizzard bar and give it your hotkeys. Turn off to keep this addon's keys.",
    function() P.ApplyMountBarSetting() end)

  if type(CreateSettingsListSectionHeaderInitializer) == "function" and layout then
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Keys"))
  end
  addBool("warnBinds", "Warn about camera and totem key conflicts", defTrue,
    "Chat reminders when BIND takes a totem wheel chord or camera zoom, and when Ctrl-Wheel / Ctrl-M4 / Ctrl-M5 are not zoom. /superbinds keys prints the full guide.",
    nil)

  if type(CreateSettingsListSectionHeaderInitializer) == "function" and layout then
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Druid only (experimental)"))
  end
  addBool("experimentalNBA", "Druid only: off-form next-best readout", defFalse,
    "DRUID ONLY. Cheat-sheet for forms Blizzard Assisted Combat does not cover (Guardian in cat). Hidden in bear / your native form. Does nothing on other classes. Drag the NEXT BEST title to move. Off by default.",
    function()
      if P.RefreshNbaStrip then P.RefreshNbaStrip() end
    end)
  addBool("experimentalNbaName", "Pulse next-press key", defTrue,
    "Title above the GCD pulse: the hotkey to press next (E, 1, R…). Off-role only — same gate as NEXT BEST (pack nativeForm, not a hardcoded bear). Guardian: cat, not bear. On by default.",
    function()
      if P.PaintPulseNextName then P.PaintPulseNextName() end
    end)

  if type(CreateSettingsButtonInitializer) == "function" and layout then
    if type(CreateSettingsListSectionHeaderInitializer) == "function" then
      layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Layout"))
    end
    layout:AddInitializer(CreateSettingsButtonInitializer(
      "Import Druid layout", "Import",
      function() if P.ImportDruid then P.ImportDruid() end end,
      "The one shipped layout: Elune Prime (Guardian + Elune's Chosen). Druid only. Use Start clean first if you want no leftover overlays.", true))
    layout:AddInitializer(CreateSettingsButtonInitializer(
      "Start clean", "Wipe overlay",
      function() if P.StartClean then P.StartClean() end end,
      "Clears saved binds, per-form slots, drawers, console position, and named profiles. Loads the stock Druid pack. Out of combat. To wipe WTF too, close the game and delete SavedVariables/SuperBinds.lua.", true))
    layout:AddInitializer(CreateSettingsButtonInitializer(
      "Apply layout", "Apply",
      function() if Apply then Apply() end end,
      "Place the current pack onto each form's native action slots.", true))
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

function SuperBinds_OnCompartmentClick()
  P.OpenSettings()
end

-- Level 80 Stormbringer leveling path (Icy Veins 12.1). Website import
-- strings are 90-point / stale and fail in-game before Apex unlocks.
-- Spend by matching live tree names so it still works when node IDs move.
-- Built inside a function so the file chunk stays under Lua's register cap.
function P.EnsureTalent80Names()
  P.TALENT80_NAMES = P.TALENT80_NAMES or {}
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
  P.Report("Talent spend is pack data. This engine does not spend a class tree.")
end

function P.RestoreStockPrimary(tag)
  if Locked() then P.Report("Leave combat first."); return false end
  local function one(t)
    if not P.Text(t) or not P.FamilyHasBars(t) then return false end
    local c = SuperBindsDB.custom and SuperBindsDB.custom[t]
    if type(c) == "table" then
      c.formPrimary = nil
      c.primary = nil
    end
    if P.PlaceFamilyStockAllForms then P.PlaceFamilyStockAllForms(t) end
    return true
  end
  local n = 0
  if P.Text(tag) then
    if one(tag) then n = 1 end
  else
    local pack = P.CurrentPack and P.CurrentPack()
    for _, fam in ipairs((pack and pack.families) or {}) do
      if fam.tag and one(fam.tag) then n = n + 1 end
    end
  end
  if n == 0 then P.Report("No form-bar family to restore."); return false end
  RefreshLayout(true)
  if P.Text(tag) then
    print("|cff0070ddSuper Binds:|r " .. tag .. " parent is stock on every form bar.")
  else
    print("|cff0070ddSuper Binds:|r form-bar parents restored to stock on every form bar.")
  end
  return true
end

function P.ImportDruid()
  if P.PlayerClass and P.PlayerClass() ~= "DRUID" then
    P.Report("The shipped import is Druid-only. The engine is class-agnostic — add a Profiles/<Class> pack for yours.")
    return false
  end
  if P.LoadProfile then return P.LoadProfile("Elune Prime") end
  return false
end

function P.StartClean()
  if Locked() or busy or GetCursorInfo() then
    P.Report("Finish combat or dragging first.")
    return false
  end
  P.EnsureDB()
  if P.ClearFamilyKeys then P.ClearFamilyKeys() end
  SuperBindsDB.custom = {}
  SuperBindsDB.binds = {}
  SuperBindsDB.barBinds = {}
  SuperBindsDB.formBinds = {}
  SuperBindsDB.mods = {}
  SuperBindsDB.profiles = {}
  SuperBindsDB.pos = {}
  SuperBindsDB.totemPos = {}
  SuperBindsDB.macroNames = {}
  SuperBindsDB.hiddenSlots = {}
  SuperBindsDB.applied = nil
  SuperBindsDB.nbaCollapsed = nil
  local pack
  if P.PlayerClass and P.PlayerClass() == "DRUID" and P.FindPack then
    pack = P.FindPack("Elune Prime")
  end
  pack = pack or (P.DefaultPack and P.DefaultPack())
  if pack then
    SuperBindsDB.familyMode = pack.familyMode or pack.name
    SuperBindsDB.familyRevision = 1
    SuperBindsDB.activeProfile = pack.name
  else
    SuperBindsDB.activeProfile = nil
    SuperBindsDB.familyMode = nil
  end
  P._forcePackKeys = true
  if pack and Apply then Apply(true) end
  P._forcePackKeys = nil
  if pack then
    print("|cff0070ddSuper Binds:|r started clean on |cffffffff" .. pack.name .. "|r. Overlay wiped. |cffffffff/reload|r if anything looks leftover.")
  else
    print("|cff0070ddSuper Binds:|r overlay wiped. No shipped pack for this class — add a profile lua.")
  end
  return true
end

function P.SlashHelp()
  print("|cff0070ddSuper Binds commands:|r")
  print("  |cffffffff/superbinds|r  apply current pack and show the key map")
  print("  |cffffffff/superbinds reset|r  restore pack default keys; console stays")
  print("  |cffffffff/superbinds clean|r  wipe overlays and load the stock Druid pack")
  print("  |cffffffff/superbinds restore [E]|r  stock parent for this form (extras stay)")
  print("  |cffffffff/superbinds load <name>|r  load a shipped or saved pack")
  print("  |cffffffff/superbinds save [name]|r  save overlay (keys, faces, positions)")
  print("  |cffffffff/superbinds list|r  shipped + saved packs")
  print("  |cffffffff/superbinds bind|r  Quick Keybind (BIND on the console)")
  print("  |cffffffff/superbinds map|r  field guide")
  print("  |cffffffff/superbinds keys|r  reserved chords")
  print("  |cffffffff/superbinds probe|r  spellbook + keys + live slots (copy window; /reload to save)")
  print("  |cffffffff/superbinds hide|r / |cffffffffshow|r  Blizzard bar 1")
  print("  |cffffffff/superbinds options|r  settings (experimental next-best readout is off by default)")
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
  if cmd == "restore" or cmd == "stock" then
    local tag = rest ~= "" and rest or nil
    if tag then
      tag = tag:upper()
      if tag == "M5" or tag == "M4" then
        -- keep mouse-family tags as written
      elseif tag == "BUTTON5" then tag = "M5"
      elseif tag == "BUTTON4" then tag = "M4"
      end
    end
    P.RestoreStockPrimary(tag)
    return
  end
  if cmd == "default" or cmd == "defaults" or cmd == "reset" then
    if Locked() or busy or GetCursorInfo() then P.Report("Finish combat or dragging before resetting."); return end
    P.ClearFamilyKeys()
    local pack = (P.CurrentPack and P.CurrentPack()) or (P.DefaultPack and P.DefaultPack())
    local snapshot = P.SnapshotCurrent and P.SnapshotCurrent()
    if snapshot then
      local backup, n = "Before reset", 1
      while SuperBindsDB.profiles[backup] do n = n + 1; backup = "Before reset " .. n end
      SuperBindsDB.profiles[backup] = snapshot
    end
    SuperBindsDB.custom = {}
    SuperBindsDB.binds = {}
    SuperBindsDB.barBinds = {}
    SuperBindsDB.formBinds = {}
    SuperBindsDB.mods = {}
    if pack then
      SuperBindsDB.familyMode, SuperBindsDB.familyRevision = pack.familyMode or pack.name, 1
      SuperBindsDB.activeProfile = pack.name
      print("|cff0070ddSuper Binds:|r reset to " .. pack.name .. " defaults.")
    end
    P._forcePackKeys = true
    Apply(true)
    P._forcePackKeys = nil
    return
  end
  if cmd == "clean" or cmd == "wipe" or cmd == "fresh" then
    P.StartClean()
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
  if cmd == "probe" or cmd == "spells" or cmd == "book" or cmd == "dump" or cmd == "layout" or cmd == "log" then
    P.PrintProbe()
    return
  end
  if cmd == "options" or cmd == "settings" or cmd == "config" then
    P.OpenSettings()
    return
  end
  if cmd == "hide" then
    SetActionBar1Visible(false)
    print("|cff0070ddSuper Binds:|r Blizzard action bars hidden. Console stays. |cffffffff/superbinds show|r shows bar 1.")
    return
  end
  if cmd == "show" then
    SetActionBar1Visible(true)
    print("|cff0070ddSuper Binds:|r Blizzard action bar 1 shown. Console stays — both are visible.")
    return
  end
  if cmd == "console" or cmd == "mounted" then
    SuperBindsDB.hideConsoleMounted = not SuperBindsDB.hideConsoleMounted
    P.ApplyConsoleMountedHide()
    if SuperBindsDB.hideConsoleMounted then
      print("|cff0070ddSuper Binds:|r console hides while mounted. |cffffffff/superbinds console|r shows it.")
    else
      print("|cff0070ddSuper Binds:|r console stays visible while mounted. |cffffffff/superbinds console|r hides it.")
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
    print("|cff0070ddSuper Binds:|r Enter opens chat. / opens a slash command.")
    return
  end
  print("|cff0070ddSuper Binds:|r unknown command. |cffffffff/superbinds help|r")
end

SLASH_SUPERBINDS1 = "/superbinds"
SLASH_SUPERBINDS2 = "/sbinds"
SlashCmdList.SUPERBINDS = P.SlashBinds

SLASH_SBKEYMAP1 = "/keymap"
SLASH_SBKEYMAP2 = "/km"
SlashCmdList.SBKEYMAP = P.ToggleKeymap

print("|cff0070ddSuper Binds:|r 0.5.117 loaded. |cffffffff/superbinds clean|r for a stock Druid layout. |cffffffff/superbinds load Elune Prime|r to import. |cffffffff/superbinds keys|r for reserved chords.")
pcall(function() P.RegisterSettings() end)

SuperBinds = P
