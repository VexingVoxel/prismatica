# Prismatica: Architecture Design Specification v0.3 (Reactive Systems)

**Goal:** Establish a robust, decoupled architecture capable of supporting a highly dynamic, shader-driven visual experience without becoming unmaintainable.
**Key Principle:** The "Juice" (VFX, Shaders, SFX) must react to game state changes, never drive them. Data is the source of truth; visuals are just an interpretation of that data.

---

## 1. The Central Nervous System: The Signal Bus (Event Bus)
To keep systems decoupled (so the Core logic doesn't need to know about particle emitters), we will use a global signal bus. This is the "nervous system" mentioned in the visual spec.

**Implementation:** An Autoload script named `SignalBus.gd`.

**Core Signals:**
* **Time/Economy:**
    * `game_tick(tick_count: int)`: The heartbeat of the game. Shaders use this to sync their pulses rhythmically.
    * `resource_changed(currency_type: String, new_amount_big_num: Resource, formatted_string: String)`: UI updates text; Core shader intensifies its glow based on total amount.
* **Grid State:**
    * `grid_shape_placed(coords: Vector2i, type: String)`: VFX manager spawns a placement poof; GridView instantiates the visual scene.
    * `grid_shape_leveled(coords: Vector2i, new_level: int, is_max_level: bool)`: Critical for visuals. Triggers the "Liquid Fill" shader transition when `is_max_level` is true.
    * `grid_adjacency_updated(affected_coords_list: Array[Vector2i])`: GridView updates the glowing connection line shaders between these coordinates.
* **Player Action & Feedback:**
    * `core_clicked(position: Vector2)`: Triggers immediate VFX burst, screen shake, and SFX at the click location.
    * `request_floating_text(position: Vector2, text: String, color_type: String)`: A generic request for the UI layer to spawn a damage-number style pop-up (e.g., "+1").

---

## 2. Core Autoloads (The Brains)
These exist globally and manage the definitive state of the game.

### A. `GameCore.gd` (The Conductor)
Remains the central hub for time and money, but now delegates feedback via the `SignalBus`.
* **Responsibility:** Manages the BigNumber currency wallet. Runs the main timer loop.
* **Juice Integration:** On every timer cycle, it calculates total income, adds it to the wallet, and emits `game_tick` via the SignalBus. It does *not* touch visuals directly.

### B. `SaveLoadManager.gd` (New)
Incremental games die without persistence. We need this early.
* **Responsibility:** Serializes the `GridDataResource` and `GameCore` state into JSON/binary format and saves to user disk. Handles auto-saving on a timer and loading on startup.

### C. `AudioManager.gd` (New)
Juice requires sound, but 50 shapes leveling up at once will destroy ears without management.
* **Responsibility:** Centralized sound pool. Uses Godot's AudioBuses to manage ducking (lowering music volume during intense SFX bursts) and limiting concurrency (preventing too many identical sounds from playing at once).

---

## 3. The Data Layer (Source of Truth)

### `GridDataResource.gd` (The Blueprint)
Remains the Resource-based data structure, but emphasize its purity. It contains *no* node references, textures, or shaders. Only dictionaries, numbers, and strings.

* **Data Structure:** `Dictionary[Vector2i, GridCellData]`
* **GridCellData (Inner Class):** Holds `type (String)`, `level (int)`, `calculated_multiplier (float)`.
* **Adjacency Logic:** The `calculate_total_production()` function remains the optimized math loop. Crucially, when it detects a change in adjacency, it doesn't just update the math; it tells the `SignalBus` *which* coordinates changed so the visuals can update precisely, rather than redrawing the whole grid.

---

## 4. The Presentation Layer (The Bridge)
This is where the architectural "juice" happens. This layer translates cold data into hot shaders.

### A. `GameSceneController.gd` (The Scene Root)
The glue that holds the main gameplay scene together. It initializes the `GridDataResource`, connects the major components, and handles user input routing.

### B. `GridView.gd` (The Visual Translator)
This node listens to the `SignalBus` regarding grid changes and updates the actual Godot Nodes (Sprites, Line2Ds). **Crucially, it manages the Shader Parameters.**

* **Reacting to `grid_shape_leveled(coords, level, is_max)`:**
    * Finds the visual node at `coords`.
    * If `is_max` is true, it accesses the node's `ShaderMaterial` and tweens a "fill_progress" uniform from 0.0 to 1.0, triggering the "Liquid Light Fill" effect.
* **Reacting to `grid_adjacency_updated(coords_list)`:**
    * Iterates through the list.
    * Instantiates or updates `Line2D` nodes between connected shapes.
    * Sets the `ShaderMaterial` on the lines to activate the "Data Flow" scrolling UV effect.

### C. `VFXManager.gd` (The Particle Pool)
To maintain performance with high amounts of "juice," we cannot instantiate and free particles constantly.

* **Responsibility:** Maintains object pools of common particle effects (e.g., Amber click burst, Cyan level-up poof).
* **Action:** Listens to `core_clicked` or `grid_shape_placed` on the SignalBus, grabs an inactive emitter from the pool, moves it to the target location, emits, and returns it to the pool when done.

### D. `CameraShake.gd` (The Impact)
A small, dedicated node attached to the main Camera2D.

* **Action:** Listens for specific high-impact signals (like clicking the core or activating a skill) and applies a decaying noise offset to the camera's position, providing visceral weight to player actions.