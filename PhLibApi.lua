local D = PhLib.Data
local ns = {}

function ns.SaveOpenProfessionFor(owner)
  if not owner or owner == "" then
    print("|cff33ff99PhLib|r owner is required.")
    return
  end
  local info, err = D.collectTradeSkill()
  if not info then
    info, err = D.collectCraft()
  end
  if not info then
    print("|cff33ff99PhLib|r nothing to save:", err or "no open window")
    return
  end
  D.persistCapture(owner, info)
end

_G.PhLibAPI = ns
