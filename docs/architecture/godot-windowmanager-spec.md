# System Design Specification: Godot WindowManager

## 1. System Overview
* **Module Name:** `WindowManager`
* **Type:** `Autoload` (Singleton)
* **Responsibility:** Manages application window state, multi-monitor safety, focus behavior, and persistent user settings.
* **Dependencies:** `DisplayServer`, `OS`, `AudioServer`, `JSON`.

## 2. Data Schema (Configuration)

### A. Default Configuration
**Source:** `res://config/default_window_settings.json` (Read-Only)
This file serves as the fallback if user data is missing or corrupt.

```json
{
  "window_mode": 0,          // 0=Windowed, 1=Borderless_Window, 2=Exclusive_Fullscreen
  "resolution_width": 1920,
  "resolution_height": 1080,
  "monitor_index": 0,
  "refresh_rate_cap": 0,     // 0 = Unlimited/Vsync default
  "vsync_mode": 1,           // 0=Disabled, 1=Enabled, 2=Adaptive
  "ui_scale": 1.0,
  "mute_on_focus_loss": true,
  "eco_mode_on_focus_loss": true // Caps FPS when alt-tabbed
}
```

### B. User Configuration
**Source:** `user://window_settings.json` (Runtime Persistence)
Follows the same schema as above. Generated/Updated at runtime.

## 3. Logic Flow Specification

### Phase 1: Initialization (`_ready`)
1.  **Load Config:**
    * Attempt to parse `user://window_settings.json`.
    * If file missing or parse error: Load `res://config/default_window_settings.json`.
2.  **Sanity Check (monitor_safety_check):**
    * Get `DisplayServer.get_screen_count()`.
    * **Rule:** If `saved_monitor_index` >= `screen_count`, reset index to `0`.
    * **Rule:** If mode is `WINDOWED`:
        * Calculate the saved window `Rect2` (position + size).
        * Get `DisplayServer.screen_get_usable_rect(current_screen)`.
        * Check intersection. If the intersection area is < 20% of the window size (window is mostly off-screen), force the window to center of primary monitor.
3.  **Apply Settings:**
    * Call internal `apply_settings()` to push state to `DisplayServer`.
    * **Crucial:** Use `call_deferred` for the actual window resizing to allow the OS window manager to catch up during startup.

### Phase 2: Runtime Event Handling
The manager must connect to `SceneTree` notifications (`_notification(what)`).

* **Event: `NOTIFICATION_APPLICATION_FOCUS_OUT`**
    * If `mute_on_focus_loss` is `true`:
        * Store current Master Bus volume.
        * Tween Master Bus volume to `-80.0` dB (0.5s duration).
    * If `Input.mouse_mode` == `CAPTURED`:
        * Store state `was_captured = true`.
        * Set `Input.mouse_mode = VISIBLE`.
    * If `eco_mode_on_focus_loss` is `true`:
        * Set `Engine.max_fps = 15`.

* **Event: `NOTIFICATION_APPLICATION_FOCUS_IN`**
    * Tween Master Bus volume back to stored volume.
    * If `was_captured == true`, set `Input.mouse_mode = CAPTURED`.
    * Restore `Engine.max_fps` to `0` (or user preference).

* **Event: `NOTIFICATION_WM_CLOSE_REQUEST`**
    * Call `save_current_state()`.
    * Only after save is complete, call `get_tree().quit()`.

### Phase 3: State Persistence (`save_current_state`)
1.  **Capture Data:**
    * Identify current `DisplayServer` mode.
    * Identify `DisplayServer.window_get_current_screen()`.
    * If not Fullscreen: Capture `window_get_size()` and `window_get_position()`.
2.  **Serialize:** Write dictionary to `user://window_settings.json` as a string.

## 4. API Surface (Public Methods)

* `set_window_mode(mode: int)`: Handles the complex `DisplayServer` state mapping:
    * **Mode 0 (Windowed):**
        * Set `WINDOW_MODE_WINDOWED`.
        * Set `WINDOW_FLAG_BORDERLESS` to `false`.
    * **Mode 1 (Borderless Windowed - "True Borderless"):**
        * *Step 1:* Set `WINDOW_MODE_WINDOWED` (force compositor control).
        * *Step 2:* Set `WINDOW_FLAG_BORDERLESS` to `true`.
        * *Step 3:* Set `WINDOW_MODE_MAXIMIZED`.
        * *Note:* Do not use `WINDOW_MODE_FULLSCREEN` for this mode, as it causes focus/multi-monitor issues on Linux/Wayland.
    * **Mode 2 (Exclusive Fullscreen):**
        * Set `WINDOW_MODE_EXCLUSIVE_FULLSCREEN`.

* `set_resolution(w: int, h: int)`:
    * Sets window size.
    * If called while in a Fullscreen/Maximized mode, it stores these values in a `_saved_window_size` variable to be applied next time the user switches to Windowed mode.

* `set_monitor(index: int)`:
    * Moves the window to the target monitor index.
    * **Logic:** Calculates the center position of the target screen and moves the window there.
    * **Safety:** Checks if `index` is valid via `DisplayServer.get_screen_count()`.

* `set_ui_scale(scale: float)`:
    * Sets `get_window().content_scale_factor`.
    * Useful for 4K support where the interface might become too small.

* `center_window()`:
    * Helper to center the window on the currently active screen (essential after resolution changes).
