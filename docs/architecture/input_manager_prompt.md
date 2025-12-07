Role: Senior Godot 4 Engineer
Task: Generate the GDScript implementation for the 'InputManager' based strictly on the Design Specification provided in input_manager_spec.md.

Constraints & Requirements:
1.  **Language:** GDScript 2.0.
2.  **Class Structure:**
    * `class_name InputManager extends Node`
    * Define const `PATH_INPUT_CONFIG = "user://input_profiles.json"`
3.  **Signals (New):**
    * `input_profile_changed()`: Emit this whenever a remap is applied or defaults are restored. (UI needs this to refresh button labels).
    * `input_scheme_changed(device_type: int)`: Emit this if you detect input source changes (Optional skeleton for now).
4.  **Discovery Logic (Crucial):**
    * In `_ready`, assume `InputMap` is populated.
    * Populate `var _remappable_actions: Array[StringName]` by iterating `InputMap.get_actions()`.
    * **Filter:** Exclude actions starting with "ui_" or "godot_".
    * **Backup:** Store `InputMap.action_get_events(action)` into `_default_input_map`.
5.  **Persistence:**
    * `save_profile()`: Serialize `_remappable_actions` to JSON.
    * `load_profile()`: Deserialize. **Crucial:** Call `InputMap.action_erase_events(action)` before re-adding saved ones.
6.  **Helper API:**
    * `remap_action(action, event)`: Apply change, save, **and emit `input_profile_changed`**.
    * `reset_to_defaults()`: Restore, save, **and emit `input_profile_changed`**.
    * `get_action_key_string(action)`: Helper for UI tooltips.

Output:
Provide **only** the GDScript code for `InputManager.gd`.