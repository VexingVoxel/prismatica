# Core VFX System Design Specification v1.1

## 1. Introduction
This document outlines the architecture and design of a generic, robust, and reusable Core VFX (Visual Effects) Manager system for Godot 4.x. The goal is to provide a foundational component suitable for integration into a core library project, emphasizing modularity, reusability, performance, and flexibility, particularly with GPU-based particles.

## 2. Guiding Principles & Design Goals
*   **Game-Agnostic Core:** The core manager's logic contains no direct references to game-specific scene nodes, constants, or tightly coupled VFX assets. It should be plug-and-play across different Godot projects.
*   **Data-Driven Configuration:** VFX definitions and behaviors are primarily configured via external `Resource` files, allowing designers to create and modify effects without code changes to the manager.
*   **Flexible & Unified API:** A single, generic event bus interface for triggering any VFX, highly configurable via a universal parameter dictionary.
*   **Performance Optimization:** Built-in support for object pooling with configurable pool sizes per VFX type. Encourages the use of highly performant GPU particles.
*   **Extensibility:** New VFX types can be easily integrated by creating new scenes and `VFXConfig` resources, without altering the core manager.
*   **Clear Separation of Concerns:** Distinct responsibilities for the manager (lifecycle), event bus (communication), and individual VFX instances (visual behavior).

## 3. Architecture Overview

The Core VFX System comprises a Central Manager, a Generic Event Bus, Data-Driven Configurations, and a common interface for all VFX Instances.

```mermaid
graph TD
    A[Game Logic / Controllers] -- emit request (id, transform, params) --> B(CoreVFXEventBus)
    B -- signal --> C(CoreVFXManager)
    C -- "1. Lookup VFXConfig by id" --> D{VFXConfig Resources}
    C -- "2. Get instance (from pool/new)" --> E(VFX Instance Node)
    E -- Base Class: VFXInstance --> F[Specific VFX Scripts (e.g., CoreClickVFX)]
    C -- "3. Parent to Global Container (World/UI)" --> G[World / UI VFX Root Node]
    C -- "4. Set global_transform" --> E
    C -- "5. Call play(params) method" --> E
    E -- "6. Effect plays" --> H[Visual Output (GPUParticles, etc.)]
    E -- "7. signal finished" --> C
    C -- "8. Return to Pool / queue_free()" --> E
```

## 4. Key Components

### 4.1. `CoreVFXManagerClass` (`core_vfx_manager.gd`) - The Central Orchestrator

*   **Type:** Godot Autoload (Singleton).
*   **Location:** `godot/_core/autoload/core_vfx_manager.gd`.
*   **Purpose:** Manages the entire lifecycle (instantiation, parenting, activation, recycling/cleanup) of all visual effects.
*   **Key Responsibilities:**
    *   **VFX Configuration Management:**
        *   Holds an `@export var vfx_library: Array[VFXConfig]` which is a collection of `VFXConfig` `Resource` files, allowing definition in the editor.
        *   **Recommendation Integrated:** In `_ready()`, an internal `_vfx_config_map: Dictionary = {}` will be populated from `vfx_library` for `O(1)` lookup by `id`. Duplicate `VFXConfig.id`s will trigger `printerr` warnings.
    *   **Object Pooling:**
        *   Manages a `Dictionary` of `Arrays` (`pools: Dictionary[String, Array[VFXInstance]]`) for inactive VFX instances, one pool per `vfx_id`.
        *   Implements `_get_from_pool(id)`: Attempts to retrieve an instance from the pool; if none are available or the pool is exhausted and `VFXConfig.can_be_pooled` is false, it creates a new instance.
        *   Implements `_return_to_pool(id, instance)`: Returns a `VFXInstance` to its pool, resetting its state and hiding it. If the pool is full or pooling is disabled, it calls `queue_free()`.
    *   **Request Handling:** Connects to `CoreVFXEventBus.request_vfx` signal.
    *   **Instantiation & Activation:**
        *   Looks up the `VFXConfig` using the provided `id`.
        *   Retrieves/creates a `VFXInstance` node.
        *   Sets the instance's `global_transform` based on the event parameter.
        *   Determines the correct parent container (`world_vfx_root` or `ui_vfx_root`) based on `VFXConfig.parent_type` and adds the `VFXInstance` as a child.
        *   Calls the `VFXInstance.play(params)` method, passing parameters from the event, merged with `VFXConfig.default_params`.
    *   **Lifecycle Management:** Connects to the `VFXInstance.finished` signal (using `CONNECT_ONE_SHOT` to ensure the connection is automatically disconnected after the first emission for pooled items). When `finished` is emitted, it returns the instance to the pool.
    *   **Global Containers:**
        *   `@export var world_vfx_root_path: NodePath` (e.g., to `/root/Game/WorldVFX`). This `Node2D` acts as the parent for all world-space VFX.
        *   `@export var ui_vfx_root_path: NodePath` (e.g., to `/root/Game/UIVFX`). This `CanvasLayer` acts as the parent for all UI-space VFX.
        *   These `NodePath`s are configured in `project.godot` or the scene hierarchy in the editor, making the manager independent of specific scene names.
        *   **Recommendation Integrated:** Implement `_ready()` checks for the validity of these paths, printing `printerr` warnings and establishing fallback if necessary (e.g., using `get_tree().root`).

### 4.2. `CoreVFXEventBusClass` (`core_vfx_event_bus.gd`) - The Generic Communication Channel

*   **Type:** Godot Autoload (Singleton).
*   **Location:** `godot/_core/autoload/core_vfx_event_bus.gd`.
*   **Purpose:** Provides a decoupled, game-agnostic communication channel for game systems to request VFX.
*   **Key Responsibilities:**
    *   Defines a single, generic signal for requesting any VFX:
        `signal request_vfx(id: String, global_transform: Transform2D, params: Dictionary)`
        *   `id`: A `String` that uniquely identifies the requested VFX, matching a `VFXConfig.id`.
        *   **Recommendation Integrated:** For 2D VFX, `global_transform` is `Transform2D` specifying the position, rotation, and scale. For 3D VFX, a separate signal (e.g., `request_vfx_3d`) with `Transform3D` or an extension to `params` would be used. This specification primarily covers the 2D case.
        *   `params`: A `Dictionary` containing any additional, specific parameters the VFX instance might need (e.g., `color`, `speed_multiplier`, `target_position`). This allows for highly dynamic VFX.
    *   Other game systems emit this signal with the relevant data.

### 4.3. `VFXConfig` (`vfx_config.gd`) - Data-Driven VFX Definitions

*   **Type:** `Resource` (`.tres` file).
*   **Location:** `godot/_core/resources/vfx/vfx_config.gd`.
*   **Purpose:** To define the properties and behavior for a specific type of visual effect in a data-driven manner, decoupled from code.
*   **Key Properties (`@export` for editor configurability):**
    *   `id: String`: A unique identifier for this VFX (e.g., "core_click_explosion", "currency_flight_spark"). Matches the `id` in `request_vfx` signal.
    *   `packed_scene: PackedScene`: A reference to the `.tscn` file containing the actual visual effect (e.g., `res://game/scenes/vfx/core_click_vfx.tscn`).
    *   `parent_type: ParentType` (Enum: `WORLD_SPACE`, `UI_SPACE`): Specifies whether the VFX should be parented to `CoreVFXManager.world_vfx_root` or `CoreVFXManager.ui_vfx_root`.
    *   `can_be_pooled: bool = true`: If `true`, the `CoreVFXManager` will attempt to pool instances of this VFX.
    *   `initial_pool_size: int = 5`: The number of instances to pre-create in the pool at startup if `can_be_pooled` is true.
    *   `max_pool_size: int = 20`: The maximum number of instances to keep in the pool. If exceeded, instances will be `queue_free()`d.
    *   `default_params: Dictionary`: A dictionary of default parameters (`key: Variant`) to pass to the `VFXInstance.play()` method.
        *   **Recommendation Integrated:** When `CoreVFXManager` calls `VFXInstance.play()`, parameters from the `request_vfx` signal will override any matching keys in `default_params` from the `VFXConfig`. The merging strategy is `event_params.merge(config_default_params, true)`.

### 4.4. `VFXInstance` (`vfx_instance.gd`) - Base Class for All VFX Scripts

*   **Type:** `Node2D` (or `Node3D` for 3D effects). This would be the base class for *all* specific VFX scripts.
*   **Location:** `godot/_core/vfx_instances/vfx_instance.gd`.
*   **Purpose:** Provides a common interface for `CoreVFXManager` to interact with any VFX, ensuring type-safe and consistent communication.
*   **Key Interface Elements:**
    *   **`class_name VFXInstance`:** A `class_name` that specific VFX scripts will `extends`.
    *   **`play(params: Dictionary = {}) -> void`:** An overridable method that specific VFX scripts must implement. It takes a `Dictionary` of parameters, merges them with any internal defaults, and uses them to configure and activate the visual effect (e.g., set `GPUParticles2D.process_material` properties, start tweens, play animations).
    *   **`signal finished`:** A signal that specific VFX scripts must emit when their visual effect has fully completed its intended duration or animation sequence. This is the trigger for `CoreVFXManager` to recycle or free the instance.
    *   **`reset() -> void`:** An overridable method to reset the VFX instance to its initial state, preparing it for reuse when returned to the pool. Essential for pooling.
    *   **Recommendation Integrated:**
        *   **Method Usage Guidance:**
            *   `_init()`: Should be reserved for minimal, one-time setup that doesn't rely on being in the scene tree.
            *   `_ready()`: Primarily for getting child nodes via `$Path` or for connecting internal signals. It will run every time an instance enters the scene tree (including when retrieved from a pool if it was `set_process_mode(Node.PROCESS_MODE_DISABLED)` then re-enabled).
            *   `play()`: Handles dynamic configuration based on event parameters and initiates the effect (e.g., `GPUParticles2D.restart()`).
            *   `reset()`: Crucial for pooled instances. It must clear any state, hide the instance, stop animations/particles, and prepare it for the next use.

### 4.5. Specific VFX Scene Scripts (e.g., `core_click_vfx.gd`, `currency_flight_vfx.gd`)

*   **Type:** Scripts attached to their respective `.tscn` files, extending `VFXInstance`.
*   **Locations:** Typically `godot/game/scenes/vfx/` or `godot/assets/vfx/`.
*   **Purpose:** Implement the unique visual and temporal behavior of a specific effect using Godot's nodes (e.g., `GPUParticles2D`, `CPUParticles2D`, `Sprite2D`, `AnimationPlayer`, `Tween`).
*   **Key Responsibilities:**
    *   Extend `VFXInstance` (e.g., `class_name CoreClickVFX extends VFXInstance`).
    *   Implement the `play(params: Dictionary)` method to customize the effect based on parameters and start the animation. This is where `GPUParticles2D.emitting = true` or `GPUParticles2D.restart()` would be called after setting up properties.
    *   Emit the `finished` signal when the effect is truly done. For GPU particles, this might involve monitoring their `lifetime` or using a timer.
    *   Implement the `reset()` method to clear any state or ongoing effects for pooling.
    *   These scripts contain no `preload()` or `instantiate()` calls for themselves.

## 5. Implementation Considerations for GPU Particles

*   **Performance:** `GPUParticles2D`/`GPUParticles3D` are highly performant and ideal for this system. The `VFXInstance` base class should anticipate their use.
*   **Parameterization:** The `play(params: Dictionary)` method in a specific GPU particle VFX script would interpret `params` to dynamically set properties on the `GPUParticles2D.process_material` (e.g., colors, scales, emission shape properties) via `set_shader_parameter()`.
*   **Cleanup:** For `GPUParticles`, the `finished` signal can be emitted reliably after its `lifetime` plus any `lifetime_randomness` has passed, possibly with a small buffer. `one_shot` can be set to true and `emitting` set to true in the `play()` method.

## 6. Interaction Flow (Revised Generic)

1.  **System Request:** A game system (e.g., `GameCore`) determines a VFX is needed.
2.  **Emit Generic Signal:** The game system emits `CoreVFXEventBus.request_vfx(vfx_id, transform, custom_params)`.
3.  **Manager Receives:** `CoreVFXManager` receives the signal.
4.  **Config Lookup & Instance Retrieval:** `CoreVFXManager` looks up `vfx_id` in its `vfx_library`, then calls `_get_from_pool(vfx_id)` to get a `VFXInstance`.
5.  **Parenting:** `CoreVFXManager` attaches the `VFXInstance` to the appropriate `world_vfx_root` or `ui_vfx_root` based on `VFXConfig.parent_type`.
6.  **Configure & Play:** `CoreVFXManager` sets the `VFXInstance`'s `global_transform` and calls `vfx_instance.play(custom_params)`.
7.  **Effect Execution:** The `VFXInstance` uses its internal nodes (e.g., `GPUParticles2D`) and the `params` to display its effect.
8.  **Completion Signal:** The `VFXInstance` emits `finished` when its effect is done.
9.  **Recycling/Cleanup:** `CoreVFXManager` receives `finished`, calls `vfx_instance.reset()`, and returns the instance to its pool (or `queue_free()`s it if pooling is not used or the pool is full).

## 7. Future Expansion

*   **3D VFX Support:** Extend `CoreVFXEventBus.request_vfx` with `Transform3D` and create `VFXConfig` properties for `Node3D`-based `packed_scene`s and `world_vfx_root_3d: NodePath`.
*   **Global VFX Controls:** Add methods to `CoreVFXManager` for globally pausing/resuming, scaling intensity, or setting a performance budget.
*   **Visual Editor for VFXConfig:** Create a custom editor plugin to visually manage `VFXConfig` resources.

This design provides a clear, highly modular, and performant approach to managing visual effects across any Godot project, leveraging the engine's capabilities for rich and responsive feedback.