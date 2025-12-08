# Prismatica Implementation Plan

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

## Phase 4: Presentation & Interaction (The Game Loop) [MOSTLY DONE]
*Goal: Build the visible game scene.*

9.  **Main Scene Scaffold:** [DONE]
    *   Create `godot/game/scenes/main.tscn`.
    *   Add `GameSceneController` (Node), `GridView` (Node2D), `HUD` (CanvasLayer).
    *   Add `Camera2D` with Shake script.

10. **HUD Controller:** [DONE]
    *   Create `godot/game/ui/hud_controller.gd`.
    *   Connect to `GameplayEventBus.resource_changed` to update a Label.

11. **Game Scene Controller (Input):** [DONE]
    *   Create `godot/game/scripts/controllers/game_scene_controller.gd`.
    *   Implement "Click-to-Select / Click-to-Place" logic.
    *   Call `GameCore.try_place_shape()` on click.

12. **Grid View (Visuals):** [DONE]
    *   Create `godot/game/scripts/views/grid_view.gd`.
    *   Listen for `grid_shape_placed`.
    *   Instantiate simple `Polygon2D` placeholders with Liquid Shader.

---

## Phase 5: The Juice (V0.3 Polish) & Advanced Logic [DONE]
*Goal: Make it feel good (Shaders & Shake) and complete the V0.5.3 mechanics.*

13. **Camera Shake:** [DONE]
    *   Create `godot/game/scripts/vfx/camera_shake.gd`.
    *   Apply noise offset on `core_clicked`.

14. **Visual Shape State (Shaders):** [DONE]
    *   Create `liquid_fill.gdshader` (Done).
    *   Create `data_flow.gdshader` (Done).

15. **Advanced Game Mechanics (v0.5.3 Gaps):** [DONE]
    *   **Overload Ability:** Implemented in `GameCore` and `HUDController`.
    *   **Shape Leveling:** Implemented `upgrade_shape` in `GridDataResource`.
    *   **Zoom/Prestige:** Added "Ascend" mechanic to `GameCore` and HUD.

16. **VFX Particles:** [DONE]
    *   Implemented particle spawning in `VFXManager`.

---

## Phase 6: Final Verification [MANUAL VERIFICATION PASSED]
*Goal: Ensure all acceptance criteria are met.*

17. **Integration Test:** [BLOCKED - Headless]
    *   *Blocked by Headless Configuration Issue.*
    *   Manual Verification Completed:
        *   [x] Core Click (Sparks + Visual Pulse).
        *   [x] Square Placement (Cost deducted, visual appears).
        *   [x] Square Fill Animation (0% -> 20% on Level 1).
        *   [x] Passive Income Generation.
        *   [x] Square Upgrade (Level Up -> Fill Increase).
        *   [x] Overload Ability (x2 Production).
        *   [x] Prestige / Ascend (Reset + Light Bonus).

---

## Post-Implementation Fixes (Dec 7, 2025)
*Issues resolved during the V0.5.3 POC debugging session:*

*   **Visuals:**
    *   **Polygon2D UVs:** Fixed incorrect UV mapping which caused shaders to render incorrectly (all black).
    *   **Liquid Shader:** Simplified shader to remove "wave" effect and ensure strictly vertical fill bar based on user feedback.
    *   **Initial Placement:** Corrected logic so squares spawn at 0% fill and animate to their current level (20% for Level 1).
    *   **Camera Shake:** Disabled camera shake on Core Click to prevent rendering artifacts ("flashing squares").
*   **Logic:**
    *   **Core Overlap:** Added 3x3 exclusion zone in `GameSceneController` to prevent placing squares visually on top of the Core.
    *   **Code Integrity:** Fixed duplicate function definitions and parse errors in `GameCore` and `GridDataResource`.
    *   **Grid Data:** Identified potential issue with Dictionary referencing in Resources (mitigated by relying on explicit updates).

---

## Next Steps / Backlog
*For future sessions:*

*   **Testing:** Configure headless environment to allow running `game_logic_test.gd`.
*   **Visual Polish:**
    *   Replace `Polygon2D` primitives with actual Sprites/Textures.
    *   Design distinct particle effects for Level Up vs Placement.
    *   Implement "Prismatica" UI Theme.
*   **Gameplay Expansion:**
    *   Implement `TriangleStrategy` and other shapes.
    *   Balance costs and production curves.
    *   Refine "Data Flow" shader for connections.
