------------------------------------------------------------
-- PhLib - WotLK 3.3.5 | Profession data (SavedVariables)
-- Main: init, slash commands, events.
-- See: PhLibUtils, PhLibData, PhLibApi, PhLibGui
------------------------------------------------------------

PhLib = PhLib or {}
PhLib.state = PhLib.state or {
  selectedOwner   = nil,
  guiSelectedSpec = nil,
}

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("TRADE_SKILL_SHOW")
if CRAFT_SHOW then ev:RegisterEvent("CRAFT_SHOW") end

ev:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "PhLib" then
    PhLib = PhLib or {}
  elseif (event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW") and PhLib.GUI then
    PhLib.GUI.NotifyProfessionWindowOpened()
  end
end)
