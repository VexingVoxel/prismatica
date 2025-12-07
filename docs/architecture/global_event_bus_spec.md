# System Design Specification: CoreEventBus

## 1. System Overview
* **Module Name:** `CoreEventBus`
* **Type:** `Autoload` (Singleton)
* **Responsibility:** Acts as the "Tier 1" Infrastructure Bus. Handles application lifecycle, global I/O requests (Audio/Save), and critical system state.
* **Scope:** STRICTLY Game-Agnostic. No gameplay logic (e.g., "Health", "Inventory", "Damage") allowed.

## 2. Signal Architecture

### A. Application Lifecycle
* `app_boot_complete()`: Emitted when all Autoloads (Window, Input, Audio) report ready.
* `quit_requested()`: Emitted when the user requests exit (allows for "Are you sure?" dialogs or auto-saving).
* `process_mode_toggled(is_paused: bool)`: Emitted when the application pauses/unpauses.

### B. Global Audio Service
* `music_play_requested(stream_id: String, crossfade_duration: float)`:
    * Generic request to change background tracks.
    * `stream_id` maps to a string key in the AudioManager.
* `music_stop_requested(fade_out_duration: float)`: Silences the music layer.
* `sfx_play_requested(sound_id: String, position_3d: Vector3, volume_db: float, pitch_scale: float)`:
    * The universal sound trigger.
    * **Sentinel Value:** If `position_3d` is `Vector3(INF, INF, INF)`, it is treated as **Non-Positional (UI/2D)** sound.
    * `sound_id`: The key for the sound resource.
    * `volume_db`: Helper for variance (default 0.0).
    * `pitch_scale`: Helper for variance (default 1.0).

### C. Scene & Context Management
* `scene_change_requested(scene_path: String, context: Dictionary)`:
    * Triggers the "Director" to swap the main content container.
* `loading_screen_requested(visible: bool)`:
    * Toggles the "Curtain" overlay to hide scene transition artifacts.

### D. System Feedback & Errors
* `toast_notification_requested(title: String, message: String, type: int)`:
    * Request to show a transient UI popup (Info, Warning, Error).
* `critical_error_occurred(error_code: int, details: String)`:
    * Signals a fatal state (e.g., Save File Corruption) that requires user intervention.

## 3. Implementation Details
* **Type:** `Node` (Code-only).
* **Constants:**
    * Define `AUDIO_3D_NULL: Vector3 = Vector3(INF, INF, INF)` for checking non-positional audio requests.
    * Define `TOAST_TYPE_INFO`, `TOAST_TYPE_WARNING`, `TOAST_TYPE_ERROR` enums for notifications.
* **Debug:** Include a `_verbose` flag and a helper `log_bus_event(name, args)` function to print signals to the console if enabled.