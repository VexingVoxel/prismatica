Role: Senior Godot 4 Engineer
Task: Generate the GDScript implementation for the 'AudioManager' based strictly on the Design Specification provided in audio_manager_spec.md.

Constraints & Requirements:
1.  **Language:** GDScript 2.0.
2.  **Class Structure:**
    * `class_name AudioManager extends Node`
    * Define const `NUM_SFX_PLAYERS = 12` (Pool size).
    * Define const `BUS_MUSIC = "Music"`, `BUS_SFX = "SFX"`, `BUS_UI = "UI"`.
3.  **Initialization:**
    * In `_ready`, create the Music players and the pools of SFX players (Node-based pooling). Add them as children of the manager.
    * Connect to `CoreEventBus` signals.
4.  **Music Logic:** Implement the "Double Deck" crossfade logic using Tweens.
5.  **SFX Logic:** Implement `_get_available_player()` to find a free node in the pool. If none are free, simply return `null` (sound doesn't play).
6.  **Helper:** Implement `linear_to_db` conversion for volume control.

Output:
Provide **only** the GDScript code for `AudioManager.gd`.