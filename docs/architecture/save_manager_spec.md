# System Design Specification: SaveManager

## 1. System Overview
* **Module Name:** `SaveManager`
* **Type:** `Autoload` (Singleton)
* **Responsibility:** Handles the raw File I/O of game data. Manages Save Slots, Metadata, and Atomic Writes to prevent corruption.
* **Scope:** Core Infrastructure. Strictly agnostic (accepts generic Dictionaries, doesn't know game schema).

## 2. File Structure
* **Content File:** `user://saves/{slot_id}.json` (The actual game data).
* **Metadata File:** `user://saves/{slot_id}.meta` (Lightweight info: timestamp, game version, thumbnail path).
* **Global Index:** `user://saves/save_index.json` (Optional list of all valid slots).

## 3. Logic Flow Specification

### A. Saving Data (`write_save_data`)
* **Input:** `slot_id` (String), `content` (Dictionary), `metadata_extra` (Dictionary).
* **Process:**
    1.  **Timestamp:** Inject `unix_time` and `iso_time` into metadata.
    2.  **Version:** Inject `ProjectSettings.get_setting("application/config/version")`.
    3.  **Atomic Write:**
        * Open `user://saves/{slot_id}.tmp` for write.
        * `store_string(JSON.stringify(content))`.
        * Close file.
        * `DirAccess.rename` .tmp to .json (overwriting old save safely).
    4.  **Write Metadata:** Repeat atomic process for the `.meta` file.
    5.  **Signal:** Emit `save_completed(slot_id, success)`.

### B. Loading Data (`load_save_data`)
* **Input:** `slot_id`.
* **Process:**
    1.  Check if file exists.
    2.  Open and Parse JSON.
    3.  **Error Handling:** If JSON parse fails, emit `save_corrupted(slot_id)`.
    4.  **Return:** The dictionary content.

### C. Slot Management
* `get_all_save_slots() -> Array[Dictionary]`:
    * Scans `user://saves/` directory.
    * parses all `.meta` files.
    * Returns an array of metadata (sorted by timestamp descending) to populate the "Load Game" menu.
* `delete_save_slot(slot_id)`:
    * Removes both .json and .meta files.

## 4. API Surface (Public Methods)
* `save_game(slot_id: String, content: Dictionary, metadata: Dictionary = {}) -> void`
* `load_game(slot_id: String) -> Dictionary`
* `get_save_metadata(slot_id: String) -> Dictionary`
* `delete_save(slot_id: String) -> void`
* `save_exists(slot_id: String) -> bool`

## 5. Technical Constraints
* **Directory:** Ensure `user://saves/` directory exists on `_ready`.
* **Format:** JSON + Indent ("\t") for readability (DevOps preference).
* **Safety:** Always use `FileAccess.store_string` paired with `JSON.stringify`.