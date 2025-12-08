# Prismatica: Architecture Design Specification v0.5.1 (Risk Mitigated)

**Goal:** Establish a robust architecture that integrates Prismatica's specific gameplay logic with the provided "Core" infrastructure modules, with explicit handling for integration edge cases.
**Key Principle:** **Separation of Concerns.** The Core Infrastructure handles *how* system operations occur; Prismatica handles *what* occurs.

---

## 1. Infrastructure Layer (The "Core")
These modules are treated as "Black Boxes" provided by the core framework. We do not modify them.

* **`CoreEventBus` (System Bus):** The Tier 1 infrastructure bus. Handles lifecycle and global IO requests.
* **`InputManager`:** Manages the `InputMap` and persists bindings.
* **`SaveManager`:** Handles raw atomic writing/reading of JSON files.
* **`AudioManager`:** Manages `AudioStreamPlayer` pools and bus volumes.
* **`WindowManager`:** Manages resolution and focus behavior.

**CRITICAL IMPLEMENTATION NOTE:**
* **Autoload Execution Order:** To prevent dependency crashes, Autoloads must be registered in Project Settings in this strict order:
    1. `CoreEventBus` (Must be first)
    2. `InputManager` / `SaveManager` / `AudioManager` / `WindowManager`
    3. `GameplayEventBus`
    4. `GameCore`

---

## 2. Communication Layer (The Dual-Bus System)

### A. `CoreEventBus` (Infrastructure)
* **Usage:** Prismatica emits signals here to request system-level services.
* **Key Signals:** `sfx_play_requested`, `music_play_requested`, `critical_error_occurred`.

### B. `GameplayEventBus` (Game Logic)
* **Implementation:** Autoload script `GameplayEventBus.gd`.
* **Responsibility:** Handles high-frequency, Prismatica-specific logic events.
* **Signals:** `game_tick`, `resource_changed`, `grid_shape_placed`, `grid_shape_leveled`, `core_clicked`.

---

## 3. Data Layer (Logic & Persistence)

### A. `GamePersistenceBridge.gd` (The Bridge)
* **Responsibility:** Translator between Game Data objects and the Core `SaveManager`.
* **Risk Mitigation (BigNumber Serialization):**
    * **Saving:** When creating the save dictionary, the BigNumber object for `sparks` must be manually converted to a String (e.g., `"10500"`) because `JSON.stringify` cannot handle custom Objects.
    * **Loading:** When parsing the save data, the String value must be fed into the BigNumber constructor to recreate the Object.
* **Workflow:**
    1.  Listens for auto-save.
    2.  Serializes `GridDataResource` and `GameCore` (converting BigNums to Strings).
    3.  Calls `SaveManager.save_game(slot_id, combined_dict, metadata)`.

### B. `GridDataResource.gd` (The Context)
* **Pattern:** **Strategy Pattern**.
* **Responsibility:** Holds the `Dictionary[Vector2i, GridCellData]` state.
* **Logic:** Delegates math to interchangeable strategy classes (e.g., `SquareStrategy`) to keep the codebase extendable.

---

## 4. Audio & VFX Implementation

### `VFXManager.gd` (The Controller)
* **Responsibility:** Manages particle pools and visual feedback.
* **Risk Mitigation (Audio Dimensionality):**
    * **Issue:** Prismatica is 2D (`Vector2`), but Core Audio is 3D (`Vector3`).
    * **Fix:** When emitting `sfx_play_requested`, the Z-axis must be set to 0.0.
    * *Code:* `CoreEventBus.sfx_play_requested.emit("sfx_place", Vector3(pos.x, pos.y, 0.0), ...)`

### `GameCore.gd` (The Conductor)
* **Music Integration:** Requests background music updates via `CoreEventBus`.

---

## 5. Input & Interaction

### `GameSceneController.gd` (Input Router)
* **Pattern:** **Command Pattern**.
* **Responsibility:** Translates raw input into `GameCommands`.
* **Integration:**
    * Uses standard `Input.is_action_just_pressed`.
    * Calls `InputManager.get_action_key_string` for tooltips.

---

## 6. Presentation Layer (Visuals)

### `GridView.gd` (Visual Manager)
* **Pattern:** **State Pattern**.
* **Responsibility:** Manages the visual node pool.
* **Logic:** Listens to `GameplayEventBus`. Assigns `VisualShapeState` objects to nodes to handle shader transitions.

---

## 7. Configuration & Settings UI

### `SettingsMenu.gd`
* **Responsibility:** UI for user configuration.
* **Integration:** Calls APIs on `WindowManager`, `AudioManager`, and `InputManager` directly.