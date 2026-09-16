-- Shaman Prime profile. Fill from _reference/ShamanBinds.lua BuildPrimeFamilies.
-- Engine must not hardcode these spells.

if SuperBinds and SuperBinds.RegisterProfile then
  SuperBinds.RegisterProfile({
    name = "Prime",
    class = "SHAMAN",
    default = true,
    families = {},
    hardware = {},
    reserved = {},
    camera = {},
    exclude = {},
    neverBind = { "Hex" },
    sculptures = {},
    theme = {},
    macros = {},
    barBinds = {},
  })
end
