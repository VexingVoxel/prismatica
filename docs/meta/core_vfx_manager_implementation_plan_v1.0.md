# Core VFX System Implementation Plan v1.0

## 1. Introduction
This document details the implementation plan for integrating the `Core VFX System Design Specification v1.1` into the Prismatica project. The approach will utilize a staged migration strategy, allowing the new core VFX system to coexist temporarily with the existing game-specific VFX system before a full transition.

## 2. Staged Migration Strategy Overview
The implementation will follow these phases:
1.  **Preparation:** Create new core directories and base files.
2.  **Core System Implementation:** Build the game-agnostic `CoreVFXManager` and `CoreVFXEventBus`.
3.  **VFX Configuration Migration:** Create `VFXConfig` resources for existing VFX.
4.  **VFX Instance Migration:** Adapt existing game-specific VFX scripts to the new `VFXInstance` interface.
5.  **Call Site Migration:** Update game logic to use the new `CoreVFXEventBus` API.
6.  **Validation:** Thoroughly test the new system.
7.  **Decommissioning:** Remove the old game-specific VFX system.

## 3. Implementation Plan Details

### Phase 1: Preparation

1.  **Create Core Directories:**
    *   Create `godot/_core/autoload/` if it doesn't exist.
    *   Create `godot/_core/vfx_instances/` if it doesn't exist.
    *   Create `godot/_core/resources/vfx/` if it doesn't exist.

2.  **Create `ParentType` Enum (Helper Script):**
    *   Create `godot/_core/enums/vfx_parent_type.gd` (or similar location) to define `enum ParentType { WORLD_SPACE, UI_SPACE }`. This enum will be used by `VFXConfig` and `CoreVFXManager`.
        *   Alternatively, define it directly within `CoreVFXManager.gd` as an inner enum if preferred for encapsulation. *For reusability across related classes, a separate enum script is generally better.*

3.  **Create `VFXInstance` Base Class:**
    *   Create `godot/_core/vfx_instances/vfx_instance.gd`.
    *   Implement `class_name VFXInstance extends Node2D` (or `Node` if 3D support is an immediate concern, but Node2D is fine for 2D-centric core).
    *   Define `signal finished`.
    *   Define `func play(params: Dictionary = {}) -> void: pass` (must be overridden).
    *   Define `func reset() -> void: pass` (must be overridden, essential for pooling).
    *   Add comments clarifying expected usage of `_init()`, `_ready()`, `play()`, and `reset()`.

4.  **Create `VFXConfig` Resource Script:**
    *   Create `godot/_core/resources/vfx_config.gd`.
    *   Implement `class_name VFXConfig extends Resource`.
    *   Add all `@export` properties as defined in the spec: `id`, `packed_scene`, `parent_type`, `can_be_pooled`, `initial_pool_size`, `max_pool_size`, `default_params`.

### Phase 2: Core System Implementation

1.  **Create `CoreVFXEventBus`:**
    *   Create `godot/_core/autoload/core_vfx_event_bus.gd`.
    *   Implement `class_name CoreVFXEventBusClass extends Node`.
    *   Define `signal request_vfx(id: String, global_transform: Transform2D, params: Dictionary)`.
    *   Add this script as an Autoload in `project.godot` with the name `CoreVFXEventBus`.

2.  **Create `CoreVFXManager`:**
    *   Create `godot/_core/autoload/core_vfx_manager.gd`.
    *   Implement `class_name CoreVFXManagerClass extends Node`.
    *   Define `@export var vfx_library: Array[VFXConfig]`.
    *   Define `@export var world_vfx_root_path: NodePath` and `@export var ui_vfx_root_path: NodePath`.
    *   Implement `_ready()`:
        *   Populate internal `_vfx_config_map: Dictionary` from `vfx_library` (with duplicate ID check).
        *   Validate `world_vfx_root_path` and `ui_vfx_root_path` resolving to valid nodes, with `printerr` warnings/fallbacks.
        *   Connect to `CoreVFXEventBus.request_vfx`.
        *   Pre-populate object pools based on `VFXConfig`s.
    *   Implement `_on_request_vfx(id, global_transform, params)` handler:
        *   Retrieve `VFXConfig`.
        *   Get/create `VFXInstance` (from pool or new).
        *   Set `global_transform`.
        *   Parent to correct root node.
        *   Call `vfx_instance.play(merged_params)`.
        *   Connect `vfx_instance.finished` to `_return_to_pool` using `CONNECT_ONE_SHOT`.
    *   Implement `_get_from_pool`, `_return_to_pool`.
    *   Add this script as an Autoload in `project.godot` with the name `CoreVFXManager`.

### Phase 3: VFX Configuration Migration

1.  **Create `VFXConfig` Assets for Existing VFX:**
    *   For `CoreClickVFX`: Create `godot/_core/resources/vfx/core_click_vfx_config.tres`.
        *   Set `id = "core_click_vfx"`.
        *   Set `packed_scene` to `res://game/scenes/vfx/core_click_vfx.tscn`.
        *   Set `parent_type = WORLD_SPACE`.
        *   Configure pooling properties.
        *   Configure `default_params` (e.g., `{"color": Color(4.0, 3.5, 1.0)}` for core click, `{"color": Color.CYAN}` for grid click).
    *   For `CurrencyFlightVFX`: Create `godot/_core/resources/vfx/currency_flight_vfx_config.tres`.
        *   Set `id = "currency_flight_vfx"`.
        *   Set `packed_scene` to `res://game/scenes/vfx/currency_flight_vfx.tscn`.
        *   Set `parent_type = UI_SPACE`.
        *   Configure pooling properties.
        *   Configure `default_params` (e.g., `{"color": Color(1.0, 0.8, 0.0, 1.0)}`).

2.  **Configure `CoreVFXManager` in Editor:**
    *   In `project.godot` or the main scene, select the `CoreVFXManager` Autoload.
    *   Drag and drop the newly created `VFXConfig` `.tres` files into its `vfx_library` array.
    *   Set `world_vfx_root_path` and `ui_vfx_root_path` to appropriate nodes in your main scene (`/root/Main` and `/root/Main/HUD` in the current project, but these should be abstract NodePaths like `../MainContainer` and `../HUDCanvasLayer` if more generic).

### Phase 4: VFX Instance Migration

1.  **Modify `core_click_vfx.gd`:**
    *   Change `class_name CoreClickVFX extends Node2D` to `class_name CoreClickVFX extends VFXInstance`.
    *   Adapt `play(position: Vector2, color: Color)` to `play(params: Dictionary)`. Extract `position` and `color` from `params`.
    *   Ensure `reset()` is correctly implemented.

2.  **Modify `currency_flight_vfx.gd`:**
    *   Change `class_name CurrencyFlightVFX extends CanvasLayer` to `class_name CurrencyFlightVFX extends VFXInstance`.
    *   Adapt `play(start_screen_pos: Vector2, target_screen_pos: Vector2, color: Color)` to `play(params: Dictionary)`. Extract all necessary parameters from `params`.
    *   Ensure `reset()` is correctly implemented.

### Phase 5: Call Site Migration

1.  **Modify `GameCore.gd`:**
    *   Update `click_core()`: Instead of `VFXEventBus.play_core_click_vfx_requested.emit(...)`, emit `CoreVFXEventBus.request_vfx("core_click_vfx", transform, params)`.
    *   Update `try_place_shape()`: Similarly, update its `VFXEventBus` emit to `CoreVFXEventBus.request_vfx("core_click_vfx", transform, params)`.
    *   The `params` dictionary will include dynamic data like `color` and `target_screen_pos` (for currency flight).

2.  **Modify `GameSceneController.gd` (if any direct VFX calls exist):**
    *   Review `_handle_left_click` or other input functions for any direct VFX spawning that needs migration. (Unlikely as `GameCore` usually orchestrates this).

3.  **Modify `VFXManager.gd` (Current, game-specific):**
    *   **Temporarily Disable:** To avoid duplicate VFX during migration, temporarily disconnect its signals or comment out its emit calls to the old `VFXEventBus`. This allows the new `CoreVFXManager` to take over gradually.

### Phase 6: Validation

1.  **Incremental Testing:** After each significant migration step (e.g., one VFX type, one call site), run the project and thoroughly test.
2.  **Console Monitoring:** Monitor the console for `printerr` warnings from `CoreVFXManager` regarding invalid paths or duplicate IDs.
3.  **Visual Verification:** Ensure all VFX (Core Click, Currency Flight) appear, animate, and clean up as expected using the new system.
4.  **Pooling Verification:** If desired, add `print()` statements to `_get_from_pool` and `_return_to_pool` to verify pooling behavior.

### Phase 7: Decommissioning (Once new system is fully validated)

1.  **Remove Old Autoloads:**
    *   From `project.godot`, remove the `VFXManager` Autoload entry.
    *   From `project.godot`, remove the `VFXEventBus` Autoload entry.
2.  **Delete Old Scripts:**
    *   Delete `godot/game/scripts/vfx/vfx_manager.gd`.
    *   Delete `godot/game/scripts/autoload/vfx_event_bus.gd`.
3.  **Cleanup Call Sites (Final Review):** Ensure no remaining code attempts to reference the old `VFXManager` or `VFXEventBus`.
4.  **Remove Temporary `VFXManager` Disabling:** Uncomment/re-enable any temporary disabling done in Phase 5.

This plan provides a structured and safe path to fully implementing the `Core VFX System Design Specification v1.1` in your project.