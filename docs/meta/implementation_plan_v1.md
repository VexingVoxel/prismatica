# Prismatica Implementation Plan

**Objective:** Build the Prismatica POC based on `prismatica_architecture_design_spec_v0.5.3.md`.
**Methodology:** Sequential implementation by layer, verifying each step with minimal "test scenes" before moving to the next.
**Executor:** Gemini CLI Agent.

---

## Phase 1: Communication & Data Foundation
*Goal: Establish the buses and the central data economy (BigNumber).*

1.  **BigNumber System:**
    *   Create `godot/game/resources/big_number.gd`.
    *   Implement scientific notation, arithmetic (`plus`, `minus`, `multiply`), and string formatting.
    *   *Verification:* Create a unit test script to assert `1e18 + 1 = 1e18` (precision check) and formatting output.

2.  **Gameplay Event Bus:**
    *   Create `godot/game/scripts/autoload/gameplay_event_bus.gd`.
    *   Define all signals: `game_tick`, `resource_changed`, `grid_shape_placed`, etc.
    *   Register in `project.godot` (Autoload order #3).

3.  **Game Core (Economy):**
    *   Create `godot/game/scripts/autoload/game_core.gd`.
    *   Implement the `_process` or `Timer` loop for the "Math Tick" (10Hz).
    *   Implement `click_core()` to emit `resource_changed`.
    *   Register in `project.godot` (Autoload order #4).

---

## Phase 2: The Grid Data Layer
*Goal: Implement the pure logic for the grid (Strategy Pattern).*

4.  **Shape Strategy Base:**
    *   Create `godot/game/scripts/grid/shape_strategy.gd` (Base Class).
    *   Define interface: `calculate_production(level, neighbors)`, `get_adjacency_bonus(neighbor_type)`.

5.  **Square Strategy:**
    *   Create `godot/game/scripts/grid/strategies/square_strategy.gd`.
    *   Implement the "+10% if touching core" logic from v0.2.

6.  **Grid Data Resource:**
    *   Create `godot/game/resources/grid_data_resource.gd`.
    *   Implement `Dictionary[Vector2i, Dictionary]` storage.
    *   Implement `place_shape(coords, type)` and `get_production()`.

---

## Phase 3: Infrastructure Integration
*Goal: Connect the Game to the provided Core Skeleton.*

7.  **Game Persistence Bridge:**
    *   Create `godot/game/scripts/system/game_persistence_bridge.gd`.
    *   Implement serialization (BigNumber -> String).
    *   Connect to `SaveManager` (Core) to handle Save/Load.
    *   *Verification:* Run the game, generate sparks, save, restart, verify sparks persist.

8.  **VFX Manager (Audio Bridge):**
    *   Create `godot/game/scripts/vfx/vfx_manager.gd`.
    *   Implement `play_sfx_2d(id, pos)` which emits `CoreEventBus.sfx_play_requested` with a Vector3 conversion.

---

## Phase 4: Presentation & Interaction (The Game Loop)
*Goal: Build the visible game scene.*

9.  **Main Scene Scaffold:**
    *   Create `godot/game/scenes/main.tscn`.
    *   Add `GameSceneController` (Node), `GridView` (Node2D), `HUD` (CanvasLayer).

10. **HUD Controller:**
    *   Create `godot/game/ui/hud_controller.gd`.
    *   Connect to `GameplayEventBus.resource_changed` to update a Label.
    *   Add a "Square" button to toggle "Placement Mode".

11. **Game Scene Controller (Input):**
    *   Create `godot/game/scripts/controllers/game_scene_controller.gd`.
    *   Implement "Click-to-Select / Click-to-Place" logic.
    *   Call `GameCore.try_place_shape()` on click.

12. **Grid View (Visuals):**
    *   Create `godot/game/scripts/views/grid_view.gd`.
    *   Listen for `grid_shape_placed`.
    *   Instantiate simple `Polygon2D` placeholders (Cyan Squares) at grid coordinates.

---

## Phase 5: The Juice (V0.3 Polish)
*Goal: Make it feel good (Shaders & Shake).*

13. **Camera Shake:**
    *   Create `godot/game/scripts/vfx/camera_shake.gd`.
    *   Apply noise offset on `core_clicked`.

14. **Visual Shape State (Shaders):**
    *   Create basic `ShaderMaterial` for the "Liquid Fill" effect.
    *   Apply to Grid Shapes.

---

## Phase 6: Final Verification
*Goal: Ensure all acceptance criteria are met.*

15. **Integration Test:**
    *   Verify "Visceral Check" (Clicking feels good).
    *   Verify "Scale Check" (BigNumber works).
    *   Verify "Spatial Check" (Adjacency boosts production).
    *   Verify "Persistence" (Save/Load works).
