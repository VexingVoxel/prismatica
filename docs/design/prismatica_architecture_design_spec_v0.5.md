# Prismatica: Architecture Design Specification v0.5 (Core Integration)

**Goal:** Establish a robust architecture that integrates Prismatica's specific gameplay logic with the provided "Core" infrastructure modules.
**Key Principle:** **Separation of Concerns.** The Core Infrastructure handles *how* system operations occur (I/O, Audio Mixing, Windowing); Prismatica handles *what* occurs (Grid Math, Game State).

---

## 1. Infrastructure Layer (The "Core")
These modules are treated as "Black Boxes" provided by the core framework. We do not modify them; we simply utilize their APIs and listen to their signals.

* **`CoreEventBus` (System Bus):** The Tier 1 infrastructure bus. Handles application lifecycle, scene switching (`scene_change_requested`), and global audio requests.
* **`InputManager`:** Manages the `InputMap`, action discovery, and remapping profiles. Persists bindings to `user://input_profiles.json`.
* **`SaveManager`:** Handles raw atomic writing/reading of JSON files to `user://saves/`. Manages save slots and metadata.
* **`AudioManager`:** Manages the `AudioStreamPlayer` pools (SFX/Music) and bus volumes. Listens to `CoreEventBus` for playback requests.
* **`WindowManager`:** Manages resolution, fullscreen modes, multi-monitor safety, and focus behavior.

---

## 2. Communication Layer (The Dual-Bus System)
Because `CoreEventBus` is strictly **Game-Agnostic**, it cannot handle gameplay-specific events like "Shape Placed". We utilize a Two-Bus architecture.

### A. `CoreEventBus` (Infrastructure)
* **Usage:** Prismatica emits signals here to request system-level services.
* **Key Signals Used:**
    * `sfx_play_requested` (VFX triggers).
    * `music_play_requested` (Background Music changes).
    * `critical_error_occurred` (Save/Load failures).

### B. `GameplayEventBus` (Game Logic)
* **Implementation:** Autoload script `GameplayEventBus.gd` (Formerly `SignalBus`).
* **Responsibility:** Handles high-frequency, Prismatica-specific logic events.
* **Core Signals:**
    * `game_tick(tick_count)`
    * `resource_changed(type, amount, formatted_str)`
    * `grid_shape_placed(coords, type)`
    * `grid_shape_leveled(coords, level, is_max)`
    * `grid_adjacency_updated(coords_list)`
    * `core_clicked(position)`

---

## 3. Data Layer (Logic & Persistence)

### A. `GamePersistenceBridge.gd` (The Bridge)
* **Replaces:** `SaveLoadManager.gd` (v0.4).
* **Responsibility:** Acts as the translator between Game Data objects and the Core `SaveManager`.
* **Saving Workflow:**
    1.  Listens for auto-save timer.
    2.  Serializes `GridDataResource` and `GameCore` economy data into a single Dictionary.
    3.  Calls `SaveManager.save_game(slot_id, combined_dict, metadata)`.
* **Loading Workflow:**
    1.  Calls `var data = SaveManager.load_game(slot_id)`.
    2.  Parses `data` and repopulates `GridDataResource` and `GameCore` state.

### B. `GridDataResource.gd` (The Context)
* **Pattern:** **Strategy Pattern**.
* **Responsibility:** Holds the `Dictionary[Vector2i, GridCellData]` state.
* **Logic:** Delegates math to interchangeable strategy classes (e.g., `SquareStrategy`, `TriangleStrategy`) to keep the codebase extendable.

---

## 4. Audio & VFX Implementation

### `VFXManager.gd` (The Controller)
* **Responsibility:** Manages particle pools and visual feedback.
* **Audio Integration:** Does *not* play sounds directly.
    * *Action:* When a shape is placed:
    * *Code:* `CoreEventBus.sfx_play_requested.emit("sfx_place_shape", position, 0.0, 1.0)`.
    * *Note:* The Core `AudioManager` picks this up and handles the pooling/playback.

### `GameCore.gd` (The Conductor)
* **Music Integration:** Requests background music updates.
    * *Code:* `CoreEventBus.music_play_requested.emit("bgm_ambient_void", 2.0)`.

---

## 5. Input & Interaction

### `GameSceneController.gd` (Input Router)
* **Pattern:** **Command Pattern**.
* **Responsibility:** Translates raw input into `GameCommands`.
* **Integration:**
    * Uses `InputManager` indirectly because `InputManager` automatically applies the `user://input_profiles.json` to the Godot `InputMap` on startup.
    * Uses standard `Input.is_action_just_pressed("action_name")` for checks.
    * Calls `InputManager.get_action_key_string("action_name")` to display correct tooltips (e.g., "Press [E] to Rotate").

---

## 6. Presentation Layer (Visuals)

### `GridView.gd` (Visual Manager)
* **Pattern:** **State Pattern**.
* **Responsibility:** Manages the visual node pool (Sprites/Line2Ds).
* **Logic:** Listens to `GameplayEventBus`. Assigns `VisualShapeState` objects (e.g., `WireframeState`, `SolidState`) to nodes to handle shader transitions like "Liquid Fill" or "Idle Hum".

---

## 7. Configuration & Settings UI

### `SettingsMenu.gd`
* **Responsibility:** Provides the UI for user configuration.
* **Window Settings:** Calls `WindowManager.set_window_mode()`, `set_resolution()`, etc..
* **Audio Settings:** Calls `AudioManager.set_bus_volume("Master", value)`.
* **Input Settings:** Calls `InputManager.remap_action(action, event)`.