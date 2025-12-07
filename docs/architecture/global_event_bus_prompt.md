Role: Senior Godot 4 Engineer
Task: Generate the GDScript implementation for the 'CoreEventBus' based strictly on the Design Specification provided in global_event_bus_spec.md.

Constraints & Requirements:
1.  **Language:** GDScript 2.0.
2.  **Class Structure:**
    * Define `class_name CoreEventBus extends Node`.
    * Define constants for `AUDIO_3D_NULL` (using `Vector3(INF, INF, INF)`) and Toast Types.
3.  **Signals:**
    * Implement all signals listed in Section 2.
    * Use strong typing for signal arguments.
    * **Audio Note:** Ensure `sfx_play_requested` has default values for its arguments: `position_3d = AUDIO_3D_NULL`, `volume_db = 0.0`, `pitch_scale = 1.0`.
4.  **Documentation:** Use `##` docstrings for every signal and constant.
5.  **Debug Helper:** Implement the `log_bus_event` helper to print formatted messages when `_verbose` is true.

Output:
Provide **only** the GDScript code for `CoreEventBus.gd`.