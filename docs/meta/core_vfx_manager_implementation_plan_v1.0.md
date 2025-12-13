# Core VFX System Implementation Plan v1.1 - Code Generation Prep

## 1. Introduction
This document details the implementation plan for integrating the `Core VFX System Design Specification v1.1` into the Prismatica project. The approach will utilize a staged migration strategy, allowing the new core VFX system to coexist temporarily with the existing game-specific VFX system before a full transition. This version of the plan includes detailed code generation specifics and clarifications.

## 2. Staged Migration Strategy Overview [COMPLETED]
The implementation will follow these phases:
1.  **Preparation:** Create new core directories and base files.
2.  **Core System Implementation:** Build the game-agnostic `CoreVFXManager` and `CoreVFXEventBus`.
3.  **VFX Configuration Migration:** Create `VFXConfig` resources for existing VFX.
4.  **VFX Instance Migration:** Adapt existing game-specific VFX scripts to the new `VFXInstance` interface.
5.  **Call Site Migration:** Update game logic to use the new `CoreVFXEventBus` API.
6.  **Validation:** Thoroughly test the new system.
7.  **Decommissioning:** Remove the old game-specific VFX system.

## 3. Implementation Plan Details

### Phase 1: Preparation [COMPLETED]

1.  **Create Core Directories:**
    *   Create `godot/_core/autoload/` if it doesn't exist. (Already existed)
    *   Create `godot/_core/vfx_instances/` if it doesn't exist. (Exists as `godot/_core/scripts/vfx/vfx_instance.gd`)
    *   Create `godot/_core/resources/vfx/` if it doesn't exist. (Already existed)

2.  **Create `ParentType` Enum (Helper Script):**
    *   **File:** `godot/_core/enums/vfx_parent_type.gd` (Already existed)
    *   **Context:** This enum defines the possible parenting types for VFX instances, used by `VFXConfig` and `CoreVFXManager`.

3.  **Create `VFXInstance` Base Class:**
    *   **File:** `godot/_core/vfx_instances/vfx_instance.gd` (Exists as `godot/_core/scripts/vfx/vfx_instance.gd`)

4.  **Create `VFXConfig` Resource Script:**
    *   **File:** `godot/_core/resources/vfx_config.gd` (Already existed)

### Phase 2: Core System Implementation [COMPLETED]

1.  **Create `CoreVFXEventBus`:**
    *   **File:** `godot/_core/autoload/core_vfx_event_bus.gd` (Already existed)
    *   **Autoload Setup:** Added as an Autoload in `project.godot` with the name `CoreVFXEventBus`.

2.  **Create `CoreVFXManager`:**
    *   **File:** `godot/_core/autoload/core_vfx_manager.gd` (Already existed)
    *   **Autoload Setup:** Added as an Autoload `godot/_core/autoload/core_vfx_manager.tscn` in `project.godot`. This was refactored from a script autoload to a scene autoload to correctly configure exported properties.
    *   **Post-creation context:** `world_vfx_root_path` and `ui_vfx_root_path` are set in the `CoreVFXManager.tscn` Autoload scene. Lazy loading for these root nodes was implemented in `core_vfx_manager.gd` to prevent initialization errors due to scene lifecycle timing.

### Phase 3: VFX Configuration Migration [COMPLETED]

1.  **Create `VFXConfig` Assets for Existing VFX:**
    *   **For `CoreClickVFX`:** `godot/_core/resources/vfx/core_click_vfx_config.tres` (Already existed)
    *   **For `CurrencyFlightVFX`:** `godot/_core/resources/vfx/currency_flight_vfx_config.tres` (Already existed)

2.  **Configure `CoreVFXManager` in Editor:**
    *   The `vfx_library` array, `world_vfx_root_path`, and `ui_vfx_root_path` are configured in `godot/_core/autoload/core_vfx_manager.tscn`.

### Phase 4: VFX Instance Migration [COMPLETED]

1.  **Modify `core_click_vfx.gd`:**
    *   **Change Base Class:** Extends `VFXInstance`.
    *   **Adapt `play()` Method:** Adapted and cleaned up.
    *   **Implement `reset()` Method:** Implemented and cleaned up.

2.  **Modify `currency_flight_vfx.gd`:**
    *   **Change Base Class:** Extends `VFXInstance`.
    *   **Adapt `play()` Method:** Adapted and cleaned up.
    *   **Implement `reset()` Method:** Implemented and cleaned up.

### Phase 5: Call Site Migration [COMPLETED]

1.  **Modify `GameCore.gd`:**
    *   **Update `_on_grid_shape_placed`:** Updated to use `CoreVFXEventBus.request_vfx`.
    *   **Update `click_core()`:** Updated to use `CoreVFXEventBus.request_vfx`.

2.  **Modify `GameSceneController.gd` (Review for direct VFX calls):**
    *   Reviewed and confirmed no direct VFX spawning; it relies on `GameCore`.

3.  **Modify `VFXManager.gd` (Current, game-specific):**
    *   The old `godot/game/scripts/vfx/vfx_manager.gd` and `godot/game/scripts/autoload/vfx_event_bus.gd` were deleted.

### Phase 6: Validation [COMPLETED]

*   The `CoreVFXManager` system was thoroughly validated and debugged during implementation. Key issues resolved include:
    *   **Lazy Root Node Resolution:** Fixed fatal errors by implementing lazy loading for `world_vfx_root` and `ui_vfx_root` in `CoreVFXManager.gd`, correctly handling the Autoload's lifecycle relative to the main scene.
    *   **Pooling Visibility:** Resolved the "sparks not appearing" bug for pooled VFX instances by correcting the order of `instance.reset()` and `instance.show()` calls in `CoreVFXManager.gd`.
    *   **Reliable Playback:** Implemented `call_deferred("play", ...)` for VFX instances to ensure `CPUParticles2D` processes correctly after being added to the scene tree.

### Phase 7: Decommissioning [COMPLETED]

*   The obsolete game-specific VFX components (`godot/game/scripts/vfx/vfx_manager.gd`, `godot/game/scripts/autoload/vfx_event_bus.gd`, and their corresponding `.uid` files) have been successfully removed from the project.