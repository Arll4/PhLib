------------------------------------------------------------
-- PhLib - Professions & specialties (edit this file, then /reload)
--
-- Each profession (lowercase) has a list. Each entry is either:
--   - A string like "(unspecified)"  → only for the dropdown.
--   - A table { number, "Name" }     → the NUMBER is the WoW spell ID of the
--     spell you learn when you pick that specialty. The addon uses it to
--     auto-detect your current specialty (if your character knows that spell,
--     that specialty is pre-selected). The NAME is what appears in the dropdown.
--
-- Where to find spell IDs: Wowhead (wowhead.com → search spell → ID is in the URL,
--   e.g. .../spell=20219). Or see README "Finding spell IDs".
------------------------------------------------------------

-- If the game uses two names for the same profession, map the alternate to the main key.
PhLib_ProfessionAliases = {
  ["blacksmith"] = "blacksmithing",
}

PhLib_Professions = {
  ["engineering"] = {
    "(unspecified)",
    { 20219, "Gnomish Engineering" },
    { 20222, "Goblin Engineering" },
  },

  ["blacksmithing"] = {
    "(unspecified)",
    { 9788, "Armorsmith" },
    { 17039, "Weaponsmith (Axesmith)" },
    { 17040, "Weaponsmith (Hammersmith)" },
    { 17041, "Weaponsmith (Swordsmith)" },
    { 9787, "Weaponsmith" },
  },

  ["leatherworking"] = {
    "(unspecified)",
    { 10656, "Dragonscale Leatherworking" },
    { 10658, "Elemental Leatherworking" },
    { 10660, "Tribal Leatherworking" },
  },

  ["alchemy"] = {
    "(unspecified)",
    { 28672, "Elixir Master" },
    { 28675, "Potion Master" },
    { 28677, "Transmutation Master" },
  },

  ["tailoring"] = {
    "(unspecified)",
    { 26798, "Mooncloth Tailoring" },
    { 26801, "Shadoweave Tailoring" },
    { 26797, "Spellfire Tailoring" },
  },
}
