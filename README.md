# PhLib

**PhLib** is a World of Warcraft 3.3.5 (WotLK) addon that saves profession data (recipes, rank, specialty) into a single Lua table stored in SavedVariables. Data is saved only when you press **Add / Save** in the UI.

---

## Features

- **Save profession data** – With a profession window open (Trade Skill or Craft), choose an owner (character name), optionally pick a specialty, and click **Add / Save** to store the current profession and all recipes.
- **Owner dropdown** – Pick from previously saved owners or type a new name.
- **Specialty support** – Detects or lets you choose specialties (e.g. Gnomish Engineering, Armorsmith, Elixir Master).
- **Realm-scoped** – Data is stored per realm under `PhLib[realm][owner][profession]`.
- **No automatic saving** – Nothing is written until you click **Add / Save**.

---

## Installation

1. Copy the **PhLib** folder into your WoW addons directory:
   ```
   World of Warcraft\Interface\AddOns\PhLib\
   ```
2. Ensure these files are present: `PhLib.toc`, `PhLib.lua`, `PhLibUtils.lua`, `PhLibData.lua`, `PhLibApi.lua`, `PhLibGui.lua`.
3. Restart WoW or type `/reload` and enable PhLib on the character select screen if needed.

---

## How to Use

### Opening the UI

- Type **`/phlib`** in chat, or  
- Use a **macro** with the command:
  ```
  /phlib
  ```
  Put that in a macro and drag it to your action bar to open or close the PhLib window.

### Saving a profession

1. Open your **Trade Skill** or **Craft** window in game (e.g. open your profession from the spellbook).
2. Open PhLib with **`/phlib`** (or your macro).
3. In PhLib:
   - **Owner:** Choose an existing owner from the dropdown or type a new character name.
   - **Specialty:** Leave as “(unspecified)” or pick the correct specialty for that profession.
4. Click **Add / Save**.  
   PhLib will capture the open profession and all recipes and save them under that owner. A confirmation message will print in chat.

### Data storage

- Saved data lives in **SavedVariables** as the global table **`PhLib`**.
- Structure: `PhLib[realm][owner][profession]` → `{ api, rank, maxRank, captured, specialty, recipes }`.

---

## Version

- **Addon version:** 0.6.0  
- **Game client:** Interface 30300 (WotLK 3.3.5)

---

## Finding spell IDs

The numbers in **PhLibProfessions.lua** (e.g. `20219` for Gnomish Engineering) are **WoW spell IDs**. You need them when adding or editing specialties that should auto-detect.

**On the web (easiest)**  
- Go to [Wowhead](https://www.wowhead.com) and pick your game version (e.g. WotLK).
- Search for the spell name (e.g. “Gnomish Engineering”).
- Open the spell page. The **spell ID is in the URL**:  
  `https://www.wowhead.com/wotlk/spell=20219` → the ID is **20219**.

**In-game**  
- If you have the spell in your spellbook, you can use a macro to print its ID. Create a macro and try:
  ```lua
  /run local name = "Gnomish Engineering"  -- change this
  for i=1,300 do local link=GetSpellLink(i,BOOKTYPE_SPELL)
  if link then local id=link:match("spell:(%d+)") local n=GetSpellBookItemName(i,BOOKTYPE_SPELL)
  if n and n:find(name) then print(n, "→ spell ID:", id) end end end
  ```
- Replace `"Gnomish Engineering"` with (part of) the spell name. When you run the macro, the chat will show the spell ID.

---

## Author

Arll4
