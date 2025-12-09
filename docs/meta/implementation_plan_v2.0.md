# Prismatica Implementation Plan v2.0

**Objective:** Build the Prismatica POC based on `prismatica_architecture_design_spec_v0.5.3.md`.
**Methodology:** Sequential implementation by layer, verifying each step with minimal "test scenes" before moving to the next.
**Executor:** Gemini CLI Agent.

---

## Phase 1: Communication & Data Foundation [DONE]
*Goal: Establish the buses and the central data economy (BigNumber).*

1.  **BigNumber System:** [DONE]
    *   Create `godot/game/resources/big_number.gd`.
    *   Implement scientific notation, arithmetic (`plus`, `minus`, `multiply`), and string formatting.

2.  **Gameplay Event Bus:** [DONE]
    *   Create `godot/game/scripts/autoload/gameplay_event_bus.gd`.
    *   Define all signals: `game_tick`, `resource_changed`, `grid_shape_placed`, etc.
    *   Register in `project.godot` (Autoload order #3).

3.  **Game Core (Economy):** [DONE]
    *   Create `godot/game/scripts/autoload/game_core.gd`.
    *   Implement the `_process` or `Timer` loop for the "Math Tick" (10Hz).
    *   Implement `click_core()` to emit `resource_changed`.
    *   Register in `project.godot` (Autoload order #4).

---

## Phase 2: The Grid Data Layer [DONE]
*Goal: Implement the pure logic for the grid (Strategy Pattern).*

4.  **Shape Strategy Base:** [DONE]
    *   Create `godot/game/scripts/grid/shape_strategy.gd` (Base Class).
    *   Define interface: `calculate_production(level, neighbors)`, `get_adjacency_multiplier(level, neighbors)`.

5.  **Square Strategy:** [DONE]
    *   Create `godot/game/scripts/grid/strategies/square_strategy.gd`.
    *   Implement the "+10% if touching core" logic (handled via GameCore/GridDataResource context).

6.  **Grid Data Resource:** [DONE]
    *   Create `godot/game/resources/grid_data_resource.gd`.
    *   Implement `Dictionary[Vector2i, Dictionary]` storage.
    *   Implement `place_shape(coords, type)` and `get_production()`.

---

## Phase 3: Infrastructure Integration [DONE]
*Goal: Connect the Game to the provided Core Skeleton.*

7.  **Game Persistence Bridge:** [DONE]
    *   Create `godot/game/scripts/system/game_persistence_bridge.gd`.
    *   Implement serialization (BigNumber -> String).
    *   Connect to `SaveManager` (Core) to handle Save/Load.

8.  **VFX Manager (Audio Bridge):** [DONE]
    *   Create `godot/game/scripts/vfx/vfx_manager.gd`.
    *   Implement `play_sfx_2d(id, pos)` which emits `CoreEventBus.sfx_play_requested` with a Vector3 conversion.

---

## Phase 4: Presentation & Interaction (The Game Loop) [COMPLETED]
*Goal: Build the visible game scene and establish interaction.*

9.  **Main Scene Scaffold:** [COMPLETED]
    *   Created `godot/game/scenes/main.tscn`.
    *   Implemented CanvasLayer structure for Background, Grid, and Gameplay.
    *   Added `GameSceneController` (Node), `GridView` (Node2D), `HUD` (CanvasLayer).
    *   Added `Camera2D` with Shake script.

10. **HUD Controller:** [COMPLETED]
    *   Created `godot/game/ui/hud_controller.gd`.
    *   Connected to `GameplayEventBus.resource_changed` to update a Label.
    *   Refactored to be scene-based (`hud.tscn`).

11. **Game Scene Controller (Input):** [COMPLETED]
    *   Create `godot/game/scripts/controllers/game_scene_controller.gd`.
    *   Implement "Click-to-Select / Click-to-Place" logic.
    *   Calls `GameCore.try_place_shape()` on click.

12. **Grid View (Visuals):** [COMPLETED]
    *   Create `godot/game/scripts/views/grid_view.gd`.
    *   Manages dynamic visual elements for shapes and Core.

---

## Phase 5: The Juice (V0.3 Visual Polish) [COMPLETED]
*Goal: Implement the "Bioluminescent Geometric" visual style.*

13. **Camera Shake:** [COMPLETED]
    *   Created `godot/game/scripts/vfx/camera_shake.gd`.
    *   Applies noise offset on `core_clicked`.

14. **Visual Shape State (Shaders):** [COMPLETED]
    *   Created `liquid_fill.gdshader` (Replaced by `shape_shell.gdshader`).
    *   Created `data_flow.gdshader`.
    *   Implemented `shape_shell.gdshader` for progressive shape visuals (hollow -> glowing fill).

15. **Advanced Game Mechanics (v0.5.3 Gaps):** [COMPLETED]
    *   **Overload Ability:** Implemented in `GameCore` and `HUDController`.
    *   **Shape Leveling:** Implemented `upgrade_shape` in `GridDataResource`.
    *   **Zoom/Prestige:** Added "Ascend" mechanic to `GameCore` and HUD.

16. **VFX Particles:** [COMPLETED]
    *   Implemented particle spawning in `VFXManager`.
    *   Refined Core click sparks into "Harvest Sparks" VFX.

17. **Core Reactor Visuals:** [COMPLETED]
    *   Implemented multi-layered "Singularity Reactor" with `reactor_floor.gdshader`, `segmented_ring.gdshader`, `singularity_orb.gdshader`.

18. **Environment Visuals:** [COMPLETED]
    *   Implemented `plasma_fog.gdshader` for background.
    *   Implemented `floor_reveal.gdshader` and `grid_lines.gdshader` for shader-based Fog of War.

---

## Phase 6: Refactoring & Modularity (v2.0) [COMPLETED]
*Goal: Enhance modularity, maintainability, and scalability of the codebase, leaning into procedural generation where appropriate.*

19. **Extract Core Reactor Scene:** [COMPLETED]
20. **Extract Shape Visual Scene:** [COMPLETED]

21. **Refactor HUD UI:** [COMPLETED]
    *   Convert procedural UI creation in `HUDController.gd` (e.g., `_create_overload_ui`, `_create_prestige_ui`) to declarative scene definition within `godot/game/scenes/hud.tscn`.
    *   **In `hud.tscn`, define the following nodes (under `HUDController`):**
        *   `TopPanel` (HBoxContainer)
        *   `SparksLabel` (Label) - Set `unique_name_in_owner = true`.
        *   `MessageLog` (VBoxContainer) - Set `unique_name_in_owner = true`.
        *   `OverloadButton` (Button) - *This node currently has procedural properties; ensure those are set in the scene.*
        *   `OverloadProgressBar` (ProgressBar) - *This node currently has procedural properties; ensure those are set in the scene.*
        *   `PrestigeButton` (Button) - *This node currently has procedural properties; ensure those are set in the scene.*
    *   **In `HUDController.gd`, update `@onready` links:**
        *   `@onready var sparks_label: Label = %SparksLabel` (already exists).
        *   `@onready var message_log: VBoxContainer = %MessageLog` (already exists).
        *   `@onready var overload_button: Button = %OverloadButton`.
        *   `@onready var overload_progress_bar: ProgressBar = %OverloadProgressBar`.
        *   `@onready var prestige_button: Button = %PrestigeButton`.
    *   Remove procedural UI creation functions (`_create_overload_ui`, `_create_prestige_ui`) from `HUDController.gd`.

22. **Centralize VFX Spawning:** [COMPLETED]
    *   Refine `VFXManager.gd` to use reusable, dedicated VFX *scenes*.
    *   **Define `core_click_vfx.tscn`:**
        *   Root: `Node2D` with script `core_click_vfx.gd`.
        *   Child: `CPUParticles2D` node (named "Particles") pre-configured with explosion properties (color, amount, lifetime, spread, speed from `_spawn_particles` in `VFXManager.gd`).
        *   `core_click_vfx.gd` API: `func play(position: Vector2, color: Color) -> void` - Sets position, sets color (if needed), emits particles, and `queue_free()`s itself after lifetime.
    *   **Define `currency_flight_vfx.tscn`:**
        *   Root: `CanvasLayer` (layer 100) with script `currency_flight_vfx.gd`.
        *   Child of Root: `Node2D` (or `Sprite2D` named "Spark", if easier for visual setup).
        *   Child of Spark: `CPUParticles2D` node (named "Trail") pre-configured with sizzle trail properties.
        *   `currency_flight_vfx.gd` API: `func play(start_screen_pos: Vector2, target_screen_pos: Vector2, color: Color) -> void` - Sets start pos, tweens to target, sets color, manages its own `queue_free()` when finished.
    *   **`VFXManager.gd` Integration:**
        *   Replace direct particle/sprite creation with `preload()` and `instance()` calls for these new VFX scenes.
        *   Call their respective `play()` methods.

23. **Code Cleanup:** [COMPLETED]
    *   Address any remaining hardcoded "magic numbers" in scripts by converting them to constants or `@export` variables.
    *   Remove unused variables (e.g., `_light_template` in `GridView`).
    *   Remove commented-out or unused functions (e.g., `_spawn_connection_line` in `GridView`).
    *   Ensure consistent code style and remove unnecessary comments.

---

## Post-Implementation Fixes (Dec 7, 2025) [COMPLETED]
*Issues resolved during the V0.5.3 POC debugging session, now integrated into Phase 5 completion status:*

*   **Visuals:**
    *   **Polygon2D UVs:** Fixed incorrect UV mapping.
    *   **Liquid Shader:** Replaced by `shape_shell.gdshader`.
    *   **Initial Placement:** Corrected logic for shape fill animation.
    *   **Camera Shake:** Tuned for effect.
*   **Logic:**
    *   **Core Overlap:** Added 3x3 exclusion zone in `GameSceneController`.
    *   **Code Integrity:** Fixed duplicate function definitions and parse errors.
    *   **Grid Data:** Mitigated potential issue with Dictionary referencing in Resources.

---

## Next Steps / Backlog
*For future sessions:*

*   **Gameplay Economy:**
    *   Implement "Resonance Network" (Core Amplification) model.
    *   Balance costs and contributions based on new economy.
*   **Gameplay Expansion:**
    *   Implement `TriangleStrategy` and other shapes.
*   **Testing:** Configure headless environment to allow running `game_logic_test.gd`.
*   **UI/UX:**
    *   Implement "Prismatica" UI Theme.
    *   Add explicit onboarding/tutorial for the early game.
    *   Foreshadowing for other player types (locked tabs, silhouettes).
