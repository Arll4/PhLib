local U = PhLib.Utils
local state = PhLib.state

local function safe_GetTradeSkillNumMade(i)
  if not GetTradeSkillNumMade then return nil, nil end
  local ok, a, b = pcall(GetTradeSkillNumMade, i)
  return ok and a or nil, ok and b or nil
end

local function safe_GetCraftNumMade(i)
  if not GetCraftNumMade then return nil, nil end
  local ok, a, b = pcall(GetCraftNumMade, i)
  return ok and a or nil, ok and b or nil
end

local function collectTradeSkill()
  local profName, curRank, maxRank = GetTradeSkillLine()
  if not profName then return nil, "No trade skill open" end

  local expandState = {}
  local num = GetNumTradeSkills()
  for i = 1, num do
    local _, skillType, _, isExpanded = GetTradeSkillInfo(i)
    if skillType == "header" and not isExpanded then
      expandState[i] = false
      ExpandTradeSkillSubClass(i)
    else
      expandState[i] = true
    end
  end

  num = GetNumTradeSkills()
  local recipes = {}
  for i = 1, num do
    local name, skillType, numAvail = GetTradeSkillInfo(i)
    if skillType ~= "header" and name then
      local itemLink  = GetTradeSkillItemLink(i)
      local spellLink = GetTradeSkillRecipeLink and GetTradeSkillRecipeLink(i) or nil
      local minMade, maxMade = safe_GetTradeSkillNumMade(i)
      local ltype, itemID = U.parseLinkTypeAndID(itemLink)
      if ltype ~= "item" then itemLink, itemID = nil, nil end
      local spellID = nil
      if type(spellLink) == "string" then
        spellID = tonumber(spellLink:match("spell:(%d+)") or "")
      end
      local qnum, qtxt = U.qualityFromItemLink(itemLink)

      table.insert(recipes, {
        index        = i,
        name         = name,
        difficulty   = skillType,
        itemLink     = itemLink,
        itemID       = itemID,
        rarity       = qtxt,
        quality      = qnum,
        spellLink    = spellLink,
        spellID      = spellID,
        minMade      = minMade,
        maxMade      = maxMade,
        numAvailable = numAvail,
      })
    end
  end

  for i = 1, GetNumTradeSkills() do
    local _, t, _, isExpanded = GetTradeSkillInfo(i)
    if t == "header" and expandState[i] == false and isExpanded then
      CollapseTradeSkillSubClass(i)
    end
  end

  return {
    api        = "TradeSkill",
    profession = profName,
    rank       = curRank or 0,
    maxRank    = maxRank or 0,
    recipes    = recipes,
    captured   = time(),
  }
end

local function collectCraft()
  if not GetNumCrafts then return nil, "Craft API not available" end
  local num = GetNumCrafts()
  if not num or num == 0 then return nil, "No craft open" end

  local profName = (GetCraftDisplaySkillLine and GetCraftDisplaySkillLine()) or "Craft"
  local recipes = {}
  local expandState = {}

  for i = 1, num do
    local _, _, skillType, _, isExpanded = GetCraftInfo(i)
    if skillType == "header" and not isExpanded then
      expandState[i] = false
      ExpandCraftSkillLine(i)
    else
      expandState[i] = true
    end
  end

  num = GetNumCrafts()
  for i = 1, num do
    local name, subText, skillType = GetCraftInfo(i)
    if skillType ~= "header" and name then
      local itemLink  = GetCraftItemLink(i)
      local spellLink = GetCraftSpellLink and GetCraftSpellLink(i) or nil
      local minMade, maxMade = safe_GetCraftNumMade(i)
      local ltype, itemID = U.parseLinkTypeAndID(itemLink)
      if ltype ~= "item" then itemLink, itemID = nil, nil end
      local spellID = nil
      if type(spellLink) == "string" then
        spellID = tonumber(spellLink:match("spell:(%d+)") or "")
      end
      local qnum, qtxt = U.qualityFromItemLink(itemLink)

      table.insert(recipes, {
        index      = i,
        name       = name,
        subText    = subText,
        difficulty = skillType,
        itemLink   = itemLink,
        itemID     = itemID,
        rarity     = qtxt,
        quality    = qnum,
        spellLink  = spellLink,
        spellID    = spellID,
        minMade    = minMade,
        maxMade    = maxMade,
      })
    end
  end

  for i = 1, GetNumCrafts() do
    local _, _, skillType, _, isExpanded = GetCraftInfo(i)
    if skillType == "header" and expandState[i] == false and isExpanded then
      CollapseCraftSkillLine(i)
    end
  end

  return {
    api        = "Craft",
    profession = profName,
    rank       = 0,
    maxRank    = 0,
    recipes    = recipes,
    captured   = time(),
  }
end

local function persistCapture(owner, info)
  if not info or not info.profession then return end

  local explicit = (state.guiSelectedSpec and state.guiSelectedSpec ~= "" and state.guiSelectedSpec ~= "(unspecified)") and state.guiSelectedSpec or nil
  local selfDetect = U.detectSpecialtySelfOnly(info.profession)
  local realm = U.realmKey()
  local prev = PhLib[realm] and PhLib[realm][owner] and PhLib[realm][owner][info.profession]
  info.specialty = explicit or selfDetect or (prev and prev.specialty) or nil

  local root = U.ensure(PhLib, realm)
  local node = U.ensure(root, owner)
  node[info.profession] = {
    api       = info.api,
    rank      = info.rank,
    maxRank   = info.maxRank,
    captured  = info.captured,
    specialty = info.specialty,
    recipes   = info.recipes,
  }

  print(string.format("|cff33ff99PhLib|r saved: %s - %s (%d recipes%s)",
    owner, info.profession, #(info.recipes or {}),
    info.specialty and (", " .. info.specialty) or ""))
end

local function GetOwnerList()
  local list = {}
  local r = PhLib and PhLib[U.realmKey()]
  if r then
    for owner, _ in pairs(r) do table.insert(list, owner) end
    table.sort(list, function(a, b) return a:lower() < b:lower() end)
  end
  return list
end

local function getOpenProfessionName()
  local prof = GetTradeSkillLine()
  if prof then return prof end
  if GetCraftDisplaySkillLine then
    local p = GetCraftDisplaySkillLine()
    if p then return p end
  end
  return nil
end

PhLib.Data = {
  collectTradeSkill      = collectTradeSkill,
  collectCraft           = collectCraft,
  persistCapture         = persistCapture,
  GetOwnerList           = GetOwnerList,
  getOpenProfessionName  = getOpenProfessionName,
}
