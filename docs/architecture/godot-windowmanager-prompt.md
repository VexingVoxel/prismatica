Role: Senior Godot 4 Engineer / Systems Architect
Task: Generate the GDScript implementation for the 'WindowManager' based on the Design Specification provided in /docs/godot-windowmanager-spec.md.

Constraints & Requirements:
1.  **Language:** GDScript 2.0 (Godot 4.x syntax).
2.  **Type Safety:** Use strong typing (e.g., `var _config: Dictionary`, `func apply(s: Vector2i) -> void`) wherever possible.
3.  **Class Structure:**
    * Define `class_name WindowManager extends Node`.
    * Use a constant Dictionary or Enum for the Window Modes to abstract `DisplayServer` complexity.
4.  **Error Handling:**
    * Wrap file I/O in `FileAccess` checks.
    * Use `push_warning` for non-critical failures (like missing config files).
5.  **Thread Safety:** Ensure `DisplayServer` calls are safe (use `call_deferred` where necessary during init).
6.  **Code Style:**
    * Follow the official Godot style guide (snake_case functions).
    * Include comments explaining the "Sanity Check" math logic.
    * Add a standard header with the class responsibility.

Output:
Provide **only** the GDScript code for `WindowManager.gd`. Do not provide the JSON files or project setup steps, just the script.