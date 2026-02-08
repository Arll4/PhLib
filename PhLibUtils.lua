------------------------------------------------------------
-- PhLib - Utility functions (realm, strings, links, specialties)
------------------------------------------------------------

local U = {}

function U.realmKey()
  local _, realm = UnitName("player")
  return realm or GetRealmName() or "UnknownRealm"
end

function U.ensure(tbl, key)
  tbl[key] = tbl[key] or {}
  return tbl[key]
end

function U.trim(s)
  if not s then return s end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local QUALITY_TEXT = {
  [0]="poor",[1]="common",[2]="uncommon",[3]="rare",[4]="epic",[5]="legendary"
}

function U.parseLinkTypeAndID(link)
  if type(link) ~= "string" then return nil, nil end
  local ltype, id = link:match("|H([^:]+):(%d+)")
  return ltype, id and tonumber(id) or nil
end

function U.qualityFromItemLink(link)
  if type(link) ~= "string" then return nil, nil end
  local _, _, q = GetItemInfo(link)
  if q then return q, QUALITY_TEXT[q] end
  local color = link:match("^|c(%x%x%x%x%x%x%x%x)")
  if not color then return nil, nil end
  local hex = color:sub(3)
  local cmap = {["9d9d9d"]="poor",["ffffff"]="common",["1eff00"]="uncommon",
                ["0070dd"]="rare",["a335ee"]="epic",["ff8000"]="legendary"}
  local txt = cmap[hex]
  if not txt then return nil, nil end
  for k, v in pairs(QUALITY_TEXT) do if v == txt then return k, v end end
  return nil, nil
end

local function professionKey(prof)
  if not prof then return nil end
  local key = prof:lower()
  if PhLib_ProfessionAliases and PhLib_ProfessionAliases[key] then
    key = PhLib_ProfessionAliases[key]
  end
  return key
end

function U.GetSpecialtyOptionsFor(prof)
  if not prof then return {"(unspecified)"} end
  local key = professionKey(prof)
  local list = PhLib_Professions and PhLib_Professions[key]
  if not list then return {"(unspecified)"} end
  local opts = {}
  for _, entry in ipairs(list) do
    if type(entry) == "string" then
      table.insert(opts, entry)
    else
      table.insert(opts, entry[2])
    end
  end
  return opts
end

function U.detectSpecialtySelfOnly(profName)
  if not profName then return nil end
  local key = professionKey(profName)
  local list = PhLib_Professions and PhLib_Professions[key]
  if not list then return nil end
  for _, entry in ipairs(list) do
    if type(entry) == "table" and entry[1] and IsSpellKnown(entry[1]) then
      return entry[2]
    end
  end
  return nil
end

PhLib.Utils = U
