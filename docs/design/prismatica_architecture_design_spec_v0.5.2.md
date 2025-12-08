# Prismatica: Architecture Design Specification v0.5.2 (Consolidated)

**Goal:** Establish a robust architecture that integrates Prismatica's specific gameplay logic (from v0.2) with the provided "Core" infrastructure modules, while preserving the "Juice" implementation details (from v0.3).

**Key Principle:** **Separation of Concerns.**
*   **Infrastructure (The Core):** Handles *how* system operations occur (I/O, Windowing).
*   **Game Logic (The Brain):** Handles *what* occurs (Math, Mechanics, Strategy).
*   **Presentation (The Face):** Handles *feedback* (Shaders, VFX, SFX).

---

## 1. Infrastructure Layer (The "Core")
*These modules are treated as "Black Boxes" provided by the framework. We do not modify them.*

*   **`CoreEventBus`:** Tier 1 System Bus (Lifecycle, IO, Global Audio).
*   **`InputManager`:** InputMap & Profiles.
*   **`SaveManager`:** Raw JSON I/O.
*   **`AudioManager`:** Stream Pools & Buses.
*   **`WindowManager`:** Resolution & Focus.

**Autoload Execution Order (Project Settings):**
1.  `CoreEventBus`
2.  `InputManager` / `SaveManager` / `AudioManager` / `WindowManager`
3.  `GameplayEventBus`
4.  `GameCore`

---

## 2. Communication Layer (The Dual-Bus System)

### A. `CoreEventBus` (Infrastructure)
*   **Role:** Request system services.
*   **Signals:** `sfx_play_requested`, `music_play_requested`, `critical_error_occurred`.

### B. `GameplayEventBus` (Game Logic)
*   **Implementation:** Autoload script `GameplayEventBus.gd`.
*   **Role:** High-frequency game events.
*   **Signals:**
    *   `game_tick(tick_count)`: The heartbeat for shaders/economy.
    *   `resource_changed(type, amount_bignum, formatted_str)`: Updates UI & Core Glow.
    *   `grid_shape_placed(coords, type)`: Triggers logic & VFX.
    *   `grid_shape_leveled(coords, level, is_max)`: Triggers "Liquid Fill" shader.
    *   `grid_adjacency_updated(coords_list)`: Triggers "Data Flow" line shaders.
    *   `core_clicked(position)`: Triggers input logic & "Juice".

---

## 3. Data Layer (Logic & Persistence)

### A. `GameCore.gd` (The Conductor)
*   **Role:** Managing the `BigNumber` economy and the "Math Tick" loop.
*   **Mechanics (v0.2 Integration):**
    *   **The Spark:** Generates resources on click.
    *   **Overload Ability (Surger):** Manages cooldown/duration state. Emits signals for UI/VFX to react.
    *   **Zoom Out (Voyager):** Tracks total lifetime production to trigger camera state changes.

### B. `GamePersistenceBridge.gd` (The Bridge)
*   **Role:** Translator between Game Data and `SaveManager`.
*   **Serialization Rules:**
    *   `BigNumber` -> String (Save) -> `BigNumber` (Load).
    *   `GridDataResource` -> Dictionary (Save) -> `GridDataResource` (Load).

### C. `GridDataResource.gd` (The Context)
*   **Role:** Holds the `Dictionary[Vector2i, GridCellData]` state.
*   **Pattern:** **Strategy Pattern** (v0.5 req).
    *   Uses `ShapeStrategy` classes (e.g., `SquareStrategy`, `TriangleStrategy`) to calculate production/adjacency.
    *   *Why:* Allows the "Tinkerer" to swap strategies later (if game design expands) and keeps complex adjacency math out of the main loop.
*   **Mechanics (v0.2 Integration):**
    *   **Adjacency Bonuses:** Checks neighbors for the +10% bonus.
    *   **Visual Evolution:** Tracks `level` to signal when the visual shift (Gray -> Cyan) occurs.

---

## 4. Audio & VFX Implementation (The "Juice" - v0.3)

### `VFXManager.gd` (The Controller)
*   **Role:** Manages particle pools (Object Pooling).
*   **Audio Bridge:** Converts 2D game events to 3D Core Audio requests.
    *   `CoreEventBus.sfx_play_requested.emit(id, Vector3(pos.x, pos.y, 0.0), ...)`

### `CameraShake.gd` (The Impact)
*   **Role:** Listens to `core_clicked` and `grid_shape_placed` for visceral feedback.

---

## 5. Presentation Layer (Visuals - v0.3)

### `GridView.gd` (Visual Manager)
*   **Pattern:** **State Pattern** (`VisualShapeState`).
*   **Responsibility:** Manages Godot Nodes (Sprites, Line2Ds).
*   **Shader Integration:**
    *   **Liquid Light:** On `grid_shape_leveled(is_max=true)`, tweens a shader uniform `fill_progress`.
    *   **Data Flow:** On `grid_adjacency_updated`, updates `Line2D` shader params to scroll UVs between connected nodes.

---

## 6. Input & Interaction

### `GameSceneController.gd` (Input Router)
*   **Pattern:** **Command Pattern**.
*   **Role:** Translates `Input.is_action_just_pressed` into Game Commands (Place, Click, Upgrade).
*   **Tooltips:** Uses `InputManager.get_action_key_string()` to show correct hotkeys.
