Role: Senior Godot 4 Engineer
Task: Generate the GDScript implementation for the 'SaveManager' based strictly on the Design Specification provided in save_manager_spec.md.

Constraints & Requirements:
1.  **Language:** GDScript 2.0.
2.  **Class Structure:**
    * `class_name SaveManager extends Node`
    * Define const `SAVE_DIR = "user://saves/"`
3.  **Core Logic:**
    * Implement **Atomic Writes**: Write to a temporary file path first, then use `DirAccess.rename()` to finalize.
    * Implement `_ready()` to ensure the `SAVE_DIR` exists (`DirAccess.make_dir_recursive_absolute`).
4.  **Metadata:**
    * Automatically add "timestamp" (Time.get_unix_time_from_system()) and "version" to any metadata dictionary passed in.
5.  **Signals:**
    * `save_started(slot_id)`
    * `save_completed(slot_id, success)`
    * `save_failed(slot_id, reason)`
6.  **Documentation:** Use `##` docstrings for public methods.

Output:
Provide **only** the GDScript code for `SaveManager.gd`.