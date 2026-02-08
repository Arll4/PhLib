------------------------------------------------------------
-- PhLib - GUI: main window, dropdowns (open via /phlib or macro)
------------------------------------------------------------

local U = PhLib.Utils
local D = PhLib.Data
local state = PhLib.state
local ns = _G.PhLibAPI

local GUI = { frame = nil, ownerBox = nil, ownerDD = nil, profText = nil, specDD = nil }

local function RefreshOwnerDropdown()
  if not GUI.ownerDD then return end
  local owners = D.GetOwnerList()
  UIDropDownMenu_Initialize(GUI.ownerDD, function(self, level)
    if not owners or #owners == 0 then
      local info = UIDropDownMenu_CreateInfo()
      info.text = "(no owners yet)"
      info.notCheckable = true
      info.disabled = true
      UIDropDownMenu_AddButton(info, level)
      return
    end
    for _, name in ipairs(owners) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = name
      info.func = function()
        state.selectedOwner = name
        UIDropDownMenu_SetText(GUI.ownerDD, name)
        if GUI.ownerBox then GUI.ownerBox:SetText("") end
      end
      info.checked = (state.selectedOwner == name)
      UIDropDownMenu_AddButton(info, level)
    end
  end)
  UIDropDownMenu_SetText(GUI.ownerDD, state.selectedOwner or "")
end

local function RefreshSpecialtyDropdown()
  if not GUI.specDD then return end
  local prof = D.getOpenProfessionName()
  local opts = U.GetSpecialtyOptionsFor(prof)
  state.guiSelectedSpec = nil

  UIDropDownMenu_Initialize(GUI.specDD, function(self, level)
    for _, val in ipairs(opts) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = val
      info.func = function()
        state.guiSelectedSpec = (val == "(unspecified)") and "" or val
        UIDropDownMenu_SetText(GUI.specDD, val)
      end
      info.checked = false
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  local owner = state.selectedOwner
  local realm = U.realmKey()
  local stored = owner and PhLib[realm] and PhLib[realm][owner] and PhLib[realm][owner][prof]
  local defaultText = "(unspecified)"
  if stored and stored.specialty and stored.specialty ~= "" then
    defaultText = stored.specialty
    state.guiSelectedSpec = stored.specialty
  end
  UIDropDownMenu_SetText(GUI.specDD, defaultText)
end

local function CreateMainUI()
  if GUI.frame then return end

  local PAD, ROW = 20, 28
  local f = CreateFrame("Frame", "PhLibUI", UIParent)
  f:SetSize(480, 240)
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetFrameStrata("DIALOG")
  f:Hide()

  -- Main background: dark, clean
  f:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  f:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
  f:SetBackdropBorderColor(0.35, 0.6, 0.4, 0.9)

  -- Title bar
  local titleBar = CreateFrame("Frame", nil, f)
  titleBar:SetPoint("TOPLEFT", 4, -4)
  titleBar:SetPoint("TOPRIGHT", -4, -4)
  titleBar:SetHeight(32)
  titleBar:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets   = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  titleBar:SetBackdropColor(0.12, 0.45, 0.28, 1)
  titleBar:SetBackdropBorderColor(0.2, 0.7, 0.45, 0.8)
  titleBar:EnableMouse(true)
  titleBar:RegisterForDrag("LeftButton")
  titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
  titleBar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

  local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  titleText:SetPoint("LEFT", titleBar, 12, 0)
  titleText:SetText("|cff88eeaaPhLib|r  —  Save profession data")
  titleText:SetTextColor(0.9, 0.95, 0.9, 1)

  local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
  closeBtn:SetPoint("RIGHT", titleBar, -4, 0)
  closeBtn:SetScript("OnClick", function() f:Hide() end)

  -- Content area (below title bar)
  local contentTop = -40

  -- Row 1: Owner
  local ownerLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ownerLabel:SetPoint("TOPLEFT", PAD, contentTop)
  ownerLabel:SetText("|cffaad4aaCharacter / Owner|r")

  local dd = CreateFrame("Frame", "PhLibOwnerDD", f, "UIDropDownMenuTemplate")
  dd:SetPoint("TOPLEFT", ownerLabel, "BOTTOMLEFT", -14, -6)
  UIDropDownMenu_SetWidth(dd, 200)
  UIDropDownMenu_SetText(dd, "")
  GUI.ownerDD = dd

  local eb = CreateFrame("EditBox", "PhLibOwnerEdit", f, "InputBoxTemplate")
  eb:SetAutoFocus(false)
  eb:SetSize(180, 22)
  eb:SetPoint("LEFT", dd, "RIGHT", 8, 0)
  eb:SetMaxLetters(64)
  eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  eb:SetText("")
  GUI.ownerBox = eb

  -- Row 2: Open profession + Specialty
  local profLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  profLabel:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 14, -14)
  profLabel:SetText("|cffaad4aaOpen profession|r")

  local profT = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  profT:SetPoint("TOPLEFT", profLabel, "BOTTOMLEFT", 0, -4)
  profT:SetText("-")
  GUI.profText = profT

  local specLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  specLabel:SetPoint("LEFT", profT, "RIGHT", 24, 0)
  specLabel:SetText("|cffaad4aaSpecialty|r")

  local specDD = CreateFrame("Frame", "PhLibSpecDD", f, "UIDropDownMenuTemplate")
  specDD:SetPoint("LEFT", specLabel, "RIGHT", -14, -6)
  UIDropDownMenu_SetWidth(specDD, 220)
  UIDropDownMenu_SetText(specDD, "(unspecified)")
  GUI.specDD = specDD

  -- Buttons
  local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  saveBtn:SetSize(120, 26)
  saveBtn:SetPoint("BOTTOMRIGHT", -PAD, PAD)
  saveBtn:SetText("Add / Save")
  saveBtn:SetScript("OnClick", function()
    local typed = U.trim(GUI.ownerBox:GetText() or "")
    local owner = typed ~= "" and typed or state.selectedOwner
    if not owner or owner == "" then
      print("|cff33ff99PhLib|r select an owner from the list or type a new name.")
      return
    end
    ns.SaveOpenProfessionFor(owner)
    state.selectedOwner = owner
    RefreshOwnerDropdown()
    RefreshSpecialtyDropdown()
  end)

  local closeBtn2 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  closeBtn2:SetSize(80, 26)
  closeBtn2:SetPoint("RIGHT", saveBtn, "LEFT", -10, 0)
  closeBtn2:SetText("Close")
  closeBtn2:SetScript("OnClick", function() f:Hide() end)

  f:SetScript("OnShow", function()
    GUI.profText:SetText(D.getOpenProfessionName() or "(none)")
    RefreshOwnerDropdown()
    RefreshSpecialtyDropdown()
  end)

  GUI.frame = f
end

local function ToggleUI()
  CreateMainUI()
  if GUI.frame:IsShown() then GUI.frame:Hide() else GUI.frame:Show() end
end

local function NotifyProfessionWindowOpened()
  if GUI.frame and GUI.frame:IsShown() then
    GUI.profText:SetText(D.getOpenProfessionName() or "(none)")
    RefreshSpecialtyDropdown()
  end
end

PhLib.GUI = {
  ToggleUI                   = ToggleUI,
  CreateMainUI               = CreateMainUI,
  RefreshOwnerDropdown       = RefreshOwnerDropdown,
  RefreshSpecialtyDropdown   = RefreshSpecialtyDropdown,
  NotifyProfessionWindowOpened = NotifyProfessionWindowOpened,
}

-- Create main UI when this file loads
CreateMainUI()

-- Register slash command here so it only runs after GUI is loaded
SLASH_PHLIB1 = "/phlib"
SlashCmdList["PHLIB"] = function()
  ToggleUI()
end
