# System Design Specification: InputManager (Core)

## 1. System Overview
* **Module Name:** `InputManager`
* **Type:** `Autoload` (Singleton)
* **Responsibility:** Manages the runtime state of the `InputMap`. Handles action discovery, remapping, saving/loading custom bindings, and restoring defaults.
* **Scope:** Core Infrastructure. Strictly agnostic (does not know about "Jump" or "Shoot", only deals with the `InputMap` API).

## 2. Data Schema (Persistence)
* **File:** `user://input_profiles.json`
* **Format:** Dictionary mapping Action Names (String) to a list of serialized InputEvents.
    ```json
    {
      "game_jump": {
          "keys": [ { "keycode": 32, "physical": false } ],  // Space
          "joypads": [ { "button_index": 0, "device": 0 } ]
      }
    }
    ```

## 3. Logic Flow Specification

### Phase 1: Initialization (`_ready`)
1.  **Action Discovery (The Agnostic Logic):**
    * Iterate through `InputMap.get_actions()`.
    * **Filter Rule:** Ignore any action name starting with `ui_` (built-in UI navigation) or `godot_` (editor internal).
    * Store valid names in `var _remappable_actions: Array[StringName]`.
2.  **Backup Defaults:**
    * For every action in `_remappable_actions`, store its default `InputEvent` list in a private `_default_input_map` dictionary.
3.  **Load User Profile:**
    * Check for `user://input_profiles.json`.
    * If exists: Call `_apply_profile(data)`.
    * If missing: Do nothing (keep Project Settings defaults).

### Phase 2: Remapping Logic
* **Differentiation:** The system must treat Keyboard/Mouse bindings separately from Joypad bindings to allow hybrid play.
* **Swap Logic (`remap_action`):**
    * Input: `action_name`, `new_event`.
    * Identify event type (Key/Mouse vs Joypad).
    * Erase existing events *of that specific type* for the action (keep the others).
    * Add the `new_event`.
    * Trigger autosave.

### Phase 3: Helper API
* `get_action_display_string(action: String) -> String`:
    * Returns a human-readable string for the first valid event.
    * Uses `OS.get_keycode_string()` for keyboard events.
    * Returns "Unbound" if empty.

## 4. API Surface (Public Methods)
* `get_remappable_actions() -> Array[StringName]`: Returns the list of discovered actions.
* `remap_action(action: String, new_event: InputEvent) -> void`: Applies change and saves.
* `reset_to_defaults() -> void`: Restores the backup state from boot.
* `get_action_key_string(action: String) -> String`: Helper for UI tooltips.

## 5. Technical Constraints
* **File I/O:** Use `FileAccess` and `JSON`.
* **Safety:** Handle missing files gracefully. Use `push_warning` for invalid action names.