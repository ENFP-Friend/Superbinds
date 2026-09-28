local n = 0
if SuperBinds and SuperBinds.Packs then
  for _, pack in pairs(SuperBinds.Packs) do
    if type(pack) == "table" and pack.class == "DRUID" then n = n + 1 end
  end
end
print("|cff0070ddSuper Binds:|r Druid packs " .. n .. ".")
