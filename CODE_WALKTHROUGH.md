# PhLib – Code Walkthrough

This document walks through the PhLib addon’s source code: load order, what each file does, and how data and UI flow through the addon.

---

## 1. Load order and dependencies

The **PhLib.toc** lists Lua files in this order:

| Order | File                 | Purpose |
|-------|----------------------|---------|
| 1     | PhLib.lua            | Creates `PhLib`, `PhLib.state`, and the event frame. No slash command here. |
| 2     | PhLibProfessions.lua | Defines `PhLib_Professions` (profession → specialty options). Edit this file to add/change professions. |
| 3     | PhLibUtils.lua       | Defines `PhLib.Utils` (realm, trim, link parsing; GetSpecialtyOptionsFor reads from PhLib_Professions). |
| 4     | PhLibData.lua        | Defines `PhLib.Data` (capture trade/craft, persist, owner list, current profession). |
| 5     | PhLibApi.lua         | Defines `_G.PhLibAPI` (public API: `SaveOpenProfessionFor`). |
| 6     | PhLibGui.lua         | Defines `PhLib.GUI`, creates the main window, registers `/phlib`. |

Dependency flow: **PhLib.lua** → **PhLibProfessions.lua** (data) → **Utils** (uses PhLib_Professions) → **Data** (uses Utils) → **Api** (uses Data) → **Gui** (uses Utils, Data, state, PhLibAPI).

---

## 2. PhLib.lua (main / init)

- **Creates**
  - `PhLib` – global addon table (and SavedVariables root).
  - `PhLib.state` – UI state: `selectedOwner`, `guiSelectedSpec`.
- **Registers events** on a frame:
  - **ADDON_LOADED** (arg1 == `"PhLib"`): only ensures `PhLib` exists (reassign after load if needed).
  - **TRADE_SKILL_SHOW** / **CRAFT_SHOW**: if `PhLib.GUI` exists, calls `PhLib.GUI.NotifyProfessionWindowOpened()` so the open profession name and specialty dropdown stay in sync when you open a profession window.

Slash command is **not** registered here; it is registered in **PhLibGui.lua** after the GUI is built, so `/phlib` always has a valid UI to toggle.

---

## 3. PhLibUtils.lua

Assigns **`PhLib.Utils`** with pure helper functions (no UI, no persistence):

- **realmKey()** – current realm name (for `PhLib[realm]`).
- **ensure(tbl, key)** – creates `tbl[key] = {}` if missing; returns `tbl[key]`.
- **trim(s)** – trims leading/trailing whitespace.
- **parseLinkTypeAndID(link)** – returns link type and numeric ID from item/spell links.
- **qualityFromItemLink(link)** – returns quality number and text (poor, common, …).
- **GetSpecialtyOptionsFor(prof)** – returns the dropdown option list for a profession from `PhLib_Professions[prof:lower()]` (strings and the second element of `{ spellID, name }` tables).
- **detectSpecialtySelfOnly(profName)** – from the same list, returns the first `{ spellID, name }` entry whose spell the player knows.

Used by **PhLibData** (parsing, realm, ensure) and **PhLibGui** (trim, realm, specialty options).

---

## 3b. PhLibProfessions.lua (data – easy to edit)

Defines one global table **`PhLib_Professions`**: keys are **lowercase** profession names, values are a single list per profession. Each list entry is either a **string** (e.g. `"(unspecified)"`) for the dropdown only, or a **table** `{ spellID, "Specialty Name" }` for both the dropdown and auto-detect (first spell the player knows wins). Order matters for auto-detect. Non-coders edit this one file; use `/reload` in game to apply.

---

## 4. PhLibData.lua

Assigns **`PhLib.Data`** and does all “data” work: capturing the open profession and writing to `PhLib`.

- **collectTradeSkill()** – if a Trade Skill window is open, expands headers, iterates recipes, builds a table with profession name, rank, and per-recipe fields (name, itemLink, itemID, quality, spellLink, spellID, min/max made, etc.). Restores collapse state and returns the table or `nil, err`.
- **collectCraft()** – same idea for the Craft window (same shape of data).
- **persistCapture(owner, info)** – takes the table returned by collectTradeSkill/collectCraft and writes it under `PhLib[realm][owner][profession]`. Sets `info.specialty` from GUI selection, self-detection, or previous save. Uses `PhLib.Utils.ensure` and `realmKey`. Prints a short “saved” message.
- **GetOwnerList()** – returns a sorted list of owner names for the current realm (from `PhLib[realm]`).
- **getOpenProfessionName()** – returns the name of the currently open profession (Trade Skill or Craft), or `nil`.

**PhLib.Data** does not register any events or UI; it is used by **PhLibApi** (collect + persist) and **PhLibGui** (owner list, current profession name).

---

## 5. PhLibApi.lua

Defines **`_G.PhLibAPI`**, the public API for other addons (or internal use):

- **SaveOpenProfessionFor(owner)**  
  - Validates `owner`.  
  - Tries `PhLib.Data.collectTradeSkill()`, then `PhLib.Data.collectCraft()`.  
  - If it got a table, calls `PhLib.Data.persistCapture(owner, info)`.  
  - Otherwise prints an error (e.g. “nothing to save”).

No UI, no slash commands. The GUI’s “Add / Save” button calls this.

---

## 6. PhLibGui.lua

Builds the UI and registers the only slash command.

- **RefreshOwnerDropdown()** – fills the owner dropdown from `PhLib.Data.GetOwnerList()`, sets selected owner text.
- **RefreshSpecialtyDropdown()** – fills the specialty dropdown from `PhLib.Utils.GetSpecialtyOptionsFor(prof)` (prof = current open profession), restores stored specialty for the selected owner if any.
- **CreateMainUI()** – creates the main frame once: title “PhLib - Add / Save”, owner dropdown + edit box, “Open profession” label + text, specialty dropdown, **Add / Save** button (calls `PhLibAPI.SaveOpenProfessionFor(owner)`, then refreshes dropdowns), **Close** button. Frame is movable, hidden by default. OnShow: updates profession text and refreshes both dropdowns.
- **ToggleUI()** – ensures main frame exists, then shows or hides it.
- **NotifyProfessionWindowOpened()** – if the main frame is visible, updates the “Open profession” text and refreshes the specialty dropdown (used from PhLib.lua on TRADE_SKILL_SHOW / CRAFT_SHOW).

At the end of the file:

1. **PhLib.GUI** is set to the table of the functions above.
2. **CreateMainUI()** is called so the window exists as soon as the addon is loaded.
3. **SLASH_PHLIB1** and **SlashCmdList["PHLIB"]** are set so typing `/phlib` (or running a macro with `/phlib`) calls **ToggleUI()**.

So the only user-facing “command” is **`/phlib`**, which toggles the PhLib window. There is no on-screen “Ph” button; the UI is opened only via `/phlib` or a macro.

---

## 7. Data shape (SavedVariables)

- **PhLib** (global, saved):
  - **PhLib.state** – not saved in the same way; it’s in-memory UI state (`selectedOwner`, `guiSelectedSpec`).
  - **PhLib[realm]** – per-realm table.
    - **PhLib[realm][owner]** – per-owner (character name).
      - **PhLib[realm][owner][profession]** – one table per profession, e.g.:
        - `api` – `"TradeSkill"` or `"Craft"`.
        - `rank`, `maxRank`, `captured`, `specialty`.
        - `recipes` – array of recipe tables (name, itemLink, itemID, quality, spellLink, spellID, minMade, maxMade, etc.).

Other addons can read/write `PhLib` and call `PhLibAPI.SaveOpenProfessionFor(owner)` to save the currently open profession without using the GUI.

---

## 8. example.lua

**example.lua** is a separate example addon (e.g. CraftExp) and is **not** loaded by PhLib.toc. It is not part of PhLib’s runtime; you can ignore it for PhLib behavior or remove it if you don’t need the example.

---

## 9. Quick reference

| Want to…                          | Look in / use |
|-----------------------------------|---------------|
| Change how data is stored         | PhLibData.lua → `persistCapture`, and the structure written to `PhLib[realm][owner][profession]`. |
| Change what is captured per recipe| PhLibData.lua → `collectTradeSkill`, `collectCraft`. |
| Add or change slash commands      | PhLibGui.lua (bottom: `SLASH_PHLIB1`, `SlashCmdList["PHLIB"]`). |
| Change the main window layout     | PhLibGui.lua → `CreateMainUI()`. |
| Expose more to other addons       | PhLibApi.lua → add functions to `ns` (e.g. `PhLibAPI`). |
| Fix realm or specialty logic     | PhLibUtils.lua (realm, specialty options, detectSpecialtySelfOnly). |

This should be enough to navigate and modify the addon with confidence.
