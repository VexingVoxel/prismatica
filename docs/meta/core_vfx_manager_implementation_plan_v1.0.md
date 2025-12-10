# Core VFX System Implementation Plan v1.1 - Code Generation Prep

## 1. Introduction
This document details the implementation plan for integrating the `Core VFX System Design Specification v1.1` into the Prismatica project. The approach will utilize a staged migration strategy, allowing the new core VFX system to coexist temporarily with the existing game-specific VFX system before a full transition. This version of the plan includes detailed code generation specifics and clarifications.

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
    *   **File:** `godot/_core/enums/vfx_parent_type.gd`
    *   **Content:**
        ```gdscript
        # godot/_core/enums/vfx_parent_type.gd
        class_name VFXParentType
        
        enum ParentType {
        	WORLD_SPACE, # For effects in the game world
        	UI_SPACE     # For effects in the UI overlay
        }
        ```
    *   **Context:** This enum defines the possible parenting types for VFX instances, used by `VFXConfig` and `CoreVFXManager`.

3.  **Create `VFXInstance` Base Class:**
    *   **File:** `godot/_core/vfx_instances/vfx_instance.gd`
    *   **Content:**
        ```gdscript
        # godot/_core/vfx_instances/vfx_instance.gd
        class_name VFXInstance extends Node2D # Defaulting to Node2D for 2D projects
        
        signal finished
        
        # Method to initialize and start the VFX with given parameters.
        # Derived classes must implement this to configure and activate the effect.
        # @param params: Dictionary of parameters (e.g., color, target_pos, speed).
        func play(params: Dictionary = {}) -> void:
        	# Derived classes will implement specific logic here.
        	# Example:
        	# var particles: GPUParticles2D = $GPUParticles2D
        	# if particles and params.has("color"):
        	#	particles.process_material.set_shader_parameter("emission_color", params.color)
        	# particles.restart()
        	printerr("VFXInstance: play() not implemented in derived class: ", get_class())
        	finished.emit() # Ensure signal is emitted even if not implemented
        
        # Method to reset the VFX to its initial state for pooling.
        # Derived classes must implement this to stop particles, reset tweens/animations,
        # clear states, and hide the instance.
        func reset() -> void:
        	# Derived classes will implement specific reset logic here.
        	# Example:
        	# var particles: GPUParticles2D = $GPUParticles2D
        	# if particles:
        	#	particles.emitting = false
        	#	particles.clear_particles()
        	# global_position = Vector2.ZERO
        	hide() # Ensure hidden when returned to pool
        	# Kill any running tweens/animations
        
        # Guidance on _init(), _ready(), play(), reset() usage in derived classes:
        # - _init(): Reserved for minimal, one-time setup that does NOT rely on being in the scene tree or having child nodes.
        # - _ready(): Primarily for getting child nodes via `$Path` or connecting internal signals. Runs every time an instance enters the scene tree.
        # - play(): Handles dynamic configuration (from CoreVFXManager via event parameters) and initiates the effect.
        # - reset(): Clears state, stops effects, and prepares for reuse in object pooling.
        #             Should be called by CoreVFXManager before returning to pool.
        ```

4.  **Create `VFXConfig` Resource Script:**
    *   **File:** `godot/_core/resources/vfx_config.gd`
    *   **Content:**
        ```gdscript
        # godot/_core/resources/vfx_config.gd
        class_name VFXConfig extends Resource
        
        # Unique identifier for this VFX. Used in request_vfx signal.
        @export var id: String = ""
        
        # Reference to the PackedScene (.tscn) for this VFX.
        @export var packed_scene: PackedScene
        
        # How this VFX should be parented (World space or UI space).
        @export var parent_type: VFXParentType.ParentType = VFXParentType.ParentType.WORLD_SPACE
        
        # Pooling options
        @export var can_be_pooled: bool = true
        @export var initial_pool_size: int = 5   # Number of instances to pre-create
        @export var max_pool_size: int = 20      # Max instances in pool. If exceeded, instance is queue_free()'d.
        
        # Default parameters to pass to VFXInstance.play() if not overridden by the request.
        @export var default_params: Dictionary = {}
        ```
    *   **Context:** Requires `VFXParentType.ParentType` for the `parent_type` enum.

### Phase 2: Core System Implementation

1.  **Create `CoreVFXEventBus`:**
    *   **File:** `godot/_core/autoload/core_vfx_event_bus.gd`
    *   **Content:**
        ```gdscript
        # godot/_core/autoload/core_vfx_event_bus.gd
        class_name CoreVFXEventBusClass extends Node
        
        # Signal to request a VFX.
        # - id: String matching a VFXConfig.id.
        # - global_transform: Transform2D for 2D VFX (position, rotation, scale).
        # - params: Dictionary for additional dynamic parameters.
        signal request_vfx(id: String, global_transform: Transform2D, params: Dictionary)
        
        # Note: For 3D VFX, an extension (e.g., request_vfx_3d with Transform3D)
        # or a more complex 'params' dictionary would be used. This plan focuses on 2D.
        ```
    *   **Autoload Setup:** Add this script as an Autoload in `project.godot` with the name `CoreVFXEventBus` (priority 0 or higher).

2.  **Create `CoreVFXManager`:**
    *   **File:** `godot/_core/autoload/core_vfx_manager.gd`
    *   **Content:**
        ```gdscript
        # godot/_core/autoload/core_vfx_manager.gd
        class_name CoreVFXManagerClass extends Node
        
        @export var vfx_library: Array[VFXConfig] # Populated in editor with VFXConfig resources
        
        # Global root nodes for parenting VFX. Set these NodePaths in project.godot or scene.
        @export var world_vfx_root_path: NodePath
        @export var ui_vfx_root_path: NodePath
        
        var _vfx_config_map: Dictionary = {} # For O(1) lookup: {id: VFXConfig}
        var _pools: Dictionary = {} # {id: Array[VFXInstance]} - Stores inactive instances
        
        var _world_vfx_root: Node # Resolved Node for world-space VFX
        var _ui_vfx_root: Node    # Resolved Node for UI-space VFX
        
        func _ready() -> void:
        	_initialize_config_map()
        	_initialize_root_nodes()
        	_initialize_pools()
        	_connect_event_bus()
        
        # Populates _vfx_config_map from vfx_library, checking for duplicate IDs.
        func _initialize_config_map() -> void:
        	for config in vfx_library:
        		if not config or config.id.is_empty() or not config.packed_scene:
        			printerr("CoreVFXManager: Invalid VFXConfig in library. ID or PackedScene missing.")
        			continue
        		if _vfx_config_map.has(config.id):
        			printerr("CoreVFXManager: Duplicate VFXConfig ID found: ", config.id, ". Skipping.")
        			continue
        		_vfx_config_map[config.id] = config
        	if _vfx_config_map.is_empty():
        		printerr("CoreVFXManager: No valid VFXConfigs loaded.")
        
        # Resolves NodePath roots for parenting VFX, with validation and fallbacks.
        func _initialize_root_nodes() -> void:
        	_world_vfx_root = get_node_or_null(world_vfx_root_path)
        	if not is_instance_valid(_world_vfx_root):
        		printerr("ERROR: CoreVFXManager: World VFX root path (", world_vfx_root_path, ") is invalid. Falling back to '/root/Main'.")
        		_world_vfx_root = get_tree().root.get_node_or_null("Main") # Common fallback
        		if not is_instance_valid(_world_vfx_root):
        			printerr("FATAL ERROR: CoreVFXManager: Fallback '/root/Main' is also invalid! World VFX may not appear.")
        			
        	_ui_vfx_root = get_node_or_null(ui_vfx_root_path)
        	if not is_instance_valid(_ui_vfx_root):
        		printerr("ERROR: CoreVFXManager: UI VFX root path (", ui_vfx_root_path, ") is invalid. Falling back to '/root/Main/HUD'.")
        		_ui_vfx_root = get_tree().root.get_node_or_null("Main/HUD") # Common fallback
        		if not is_instance_valid(_ui_vfx_root):
        			printerr("FATAL ERROR: CoreVFXManager: Fallback '/root/Main/HUD' is also invalid! UI VFX may not appear.")
        
        # Pre-populates object pools based on VFXConfig settings.
        func _initialize_pools() -> void:
        	for id in _vfx_config_map:
        		var config: VFXConfig = _vfx_config_map[id]
        		if config.can_be_pooled and config.initial_pool_size > 0:
        			_pools[id] = []
        			for _i in range(config.initial_pool_size):
        				var instance: VFXInstance = _create_new_vfx_instance(config)
        				if instance:
        					instance.hide()
        					instance.set_process_mode(Node.PROCESS_MODE_DISABLED) # Disable processing when in pool
        					_pools[id].append(instance)
        					# Add to scene tree once to be ready for use, then remove
        					# Or add to a "hidden" parent for pools
        					# For simplicity, we'll add to parent on demand
        					# The instance is not added to the tree here.
        					# This is fine for pre-creation, add_child happens in _setup_and_play_vfx
        
        # Connects to the CoreVFXEventBus signal.
        func _connect_event_bus() -> void:
        	CoreVFXEventBus.request_vfx.connect(_on_request_vfx)
        
        # Handler for CoreVFXEventBus.request_vfx signal.
        func _on_request_vfx(id: String, global_transform: Transform2D, params: Dictionary) -> void:
        	var config: VFXConfig = _vfx_config_map.get(id)
        	if not config:
        		printerr("CoreVFXManager: No VFXConfig found for ID: ", id, ". Request ignored.")
        		return
        	
        	var vfx_instance: VFXInstance = _get_vfx_instance(id, config)
        	if not vfx_instance:
        		printerr("CoreVFXManager: Failed to get/create VFXInstance for ID: ", id, ". Request ignored.")
        		return
        		
        	_setup_and_play_vfx(vfx_instance, config, global_transform, params)
        
        # Creates a new VFXInstance from its PackedScene.
        func _create_new_vfx_instance(config: VFXConfig) -> VFXInstance:
        	if not config.packed_scene:
        		printerr("CoreVFXManager: VFXConfig for ", config.id, " has no PackedScene defined.")
        		return null
        		
        	var instance: VFXInstance = config.packed_scene.instantiate() as VFXInstance
        	if not instance:
        		printerr("CoreVFXManager: Failed to instantiate PackedScene for ID: ", config.id, ". Is the root of the scene a VFXInstance or extends it?")
        		return null
        	
        	instance.name = config.id + "_Instance" # Give it a descriptive name
        	return instance
        
        # Retrieves a VFXInstance from the pool or creates a new one.
        func _get_vfx_instance(id: String, config: VFXConfig) -> VFXInstance:
        	if config.can_be_pooled and _pools.has(id) and not _pools[id].is_empty():
        		var instance: VFXInstance = _pools[id].pop_back()
        		instance.show()
        		instance.set_process_mode(Node.PROCESS_MODE_INHERIT) # Re-enable processing
        		instance.reset() # Reset before use
        		return instance
        	
        	# If not pooled, or pool is empty/full, create new.
        	return _create_new_vfx_instance(config)
        
        # Returns a VFXInstance to its pool or frees it.
        func _return_to_pool(instance: VFXInstance) -> void:
        	var config_id = instance.name.get_slice("_", 0) # Assumes naming convention "id_Instance"
        	var config: VFXConfig = _vfx_config_map.get(config_id)
        	
        	if config and config.can_be_pooled and _pools.has(config_id) and _pools[config_id].size() < config.max_pool_size:
        		instance.hide()
        		instance.set_process_mode(Node.PROCESS_MODE_DISABLED) # Disable processing when in pool
        		instance.reset() # Reset for future use
        		if instance.get_parent():
        			instance.get_parent().remove_child(instance) # Remove from active tree
        		_pools[config_id].append(instance)
        	else:
        		instance.queue_free()
        
        # Sets up the VFXInstance's properties and calls its play method.
        func _setup_and_play_vfx(instance: VFXInstance, config: VFXConfig, global_transform: Transform2D, event_params: Dictionary) -> void:
        	var parent_node: Node
        	match config.parent_type:
        		VFXParentType.ParentType.WORLD_SPACE:
        			parent_node = _world_vfx_root
        		VFXParentType.ParentType.UI_SPACE:
        			parent_node = _ui_vfx_root
        		_:
        			printerr("CoreVFXManager: Unknown ParentType for ID: ", config.id, ". Falling back to world_vfx_root.")
        			parent_node = _world_vfx_root
        			
        	if not is_instance_valid(parent_node):
        		printerr("FATAL ERROR: CoreVFXManager: Parent node is invalid for ID: ", config.id, ". VFX will not be spawned.")
        		instance.queue_free()
        		return
        	
        	parent_node.add_child(instance)
        	instance.global_transform = global_transform # Apply position, rotation, scale
        	
        	# Merge parameters: Event params override default params
        	var final_params = config.default_params.duplicate(true) # Deep duplicate config defaults
        	for key in event_params: # Overlay event-specific params
        		final_params[key] = event_params[key]
        	
        	instance.play(final_params)
        	instance.finished.connect(Callable(self, "_return_to_pool").bind(instance), CONNECT_ONE_SHOT)
        
        ```
    *   **Autoload Setup:** Add this script as an Autoload in `project.godot` with the name `CoreVFXManager` (priority 1 or higher).
    *   **Post-creation context:** Make sure to set `world_vfx_root_path` and `ui_vfx_root_path` in the `CoreVFXManager` Autoload settings in the Godot editor. For example, `/root/Main` for world VFX and `/root/Main/HUD` for UI VFX. These paths should point to actual nodes in your main scene that will serve as containers.

### Phase 3: VFX Configuration Migration

1.  **Create `VFXConfig` Assets for Existing VFX:**
    *   **Context:** These `.tres` files must be created manually in the Godot editor.
    *   **For `CoreClickVFX`:**
        *   **Path:** `godot/_core/resources/vfx/core_click_vfx_config.tres`
        *   **Properties:**
            *   `id`: `"core_click_vfx"`
            *   `packed_scene`: `res://game/scenes/vfx/core_click_vfx.tscn`
            *   `parent_type`: `VFXParentType.ParentType.WORLD_SPACE`
            *   `can_be_pooled`: `true`
            *   `initial_pool_size`: `5` (or a reasonable default)
            *   `max_pool_size`: `20` (or a reasonable max)
            *   `default_params`: `{"color": Color(4.0, 3.5, 1.0)}` (HDR Gold)
    *   **For `CurrencyFlightVFX`:**
        *   **Path:** `godot/_core/resources/vfx/currency_flight_vfx_config.tres`
        *   **Properties:**
            *   `id`: `"currency_flight_vfx"`
            *   `packed_scene`: `res://game/scenes/vfx/currency_flight_vfx.tscn`
            *   `parent_type`: `VFXParentType.ParentType.UI_SPACE`
            *   `can_be_pooled`: `true`
            *   `initial_pool_size`: `3` (or a reasonable default)
            *   `max_pool_size`: `10` (or a reasonable max)
            *   `default_params`: `{"start_screen_pos": Vector2(0,0), "target_screen_pos": Vector2(0,0), "color": Color(1.0, 0.8, 0.0, 1.0)}` (Note: `start_screen_pos` and `target_screen_pos` will be set dynamically via `request_vfx` params, these defaults are just placeholders or for testing).

2.  **Configure `CoreVFXManager` in Editor:**
    *   In the Godot editor, select the `CoreVFXManager` Autoload (Project -> Project Settings -> Autoload).
    *   Drag and drop the newly created `VFXConfig` `.tres` files (`core_click_vfx_config.tres`, `currency_flight_vfx_config.tres`) into its `vfx_library` array.
    *   Set `world_vfx_root_path` to the `NodePath` of your main world container (e.g., `/root/Main`).
    *   Set `ui_vfx_root_path` to the `NodePath` of your main UI container (e.g., `/root/Main/HUD`).

### Phase 4: VFX Instance Migration

1.  **Modify `core_click_vfx.gd`:**
    *   **Change Base Class:**
        ```gdscript
        # Before: class_name CoreClickVFX extends Node2D
        class_name CoreClickVFX extends VFXInstance # Extends new base class
        ```
    *   **Adapt `play()` Method:**
        ```gdscript
        func play(params: Dictionary = {}) -> void:
        	# global_transform is already set by CoreVFXManager
        	var color: Color = params.get("color", Color.WHITE) # Get color from params
        
        	var particles: CPUParticles2D = $Particles
        	if particles:
        		particles.color = color
        		particles.restart() # Ensure particles play from start
        		# Auto-cleanup after particles finish
        		await get_tree().create_timer(particles.lifetime + particles.lifetime_randomness + PARTICLE_LIFETIME_BUFFER).timeout
        		finished.emit()
        	else:
        		printerr("ERROR: CoreClickVFX: No 'Particles' node found for playing! Emitting finished.")
        		finished.emit() # Emit finished even if particles aren't found for cleanup
        ```
    *   **Implement `reset()` Method:**
        ```gdscript
        func reset() -> void:
        	var particles: CPUParticles2D = $Particles
        	if particles:
        		particles.emitting = false # Stop particles
        		particles.clear_particles() # Clear any remaining particles
        	global_position = Vector2.ZERO # Reset position
        	rotation = 0.0 # Reset rotation
        	scale = Vector2.ONE # Reset scale
        	# Reset any tweens, animations if applicable
        	hide() # Ensure hidden when returned to pool
        ```

2.  **Modify `currency_flight_vfx.gd`:**
    *   **Change Base Class:**
        ```gdscript
        # Before: class_name CurrencyFlightVFX extends CanvasLayer
        class_name CurrencyFlightVFX extends VFXInstance # Extends new base class
        ```
    *   **Adapt `play()` Method:**
        ```gdscript
        func play(params: Dictionary = {}) -> void:
        	# global_transform is already set by CoreVFXManager
        	# Extract specific parameters for flight animation
        	var start_screen_pos: Vector2 = params.get("start_screen_pos", Vector2.ZERO)
        	var target_screen_pos: Vector2 = params.get("target_screen_pos", Vector2.ZERO)
        	var color: Color = params.get("color", Color.WHITE)
        
        	var sprite: Sprite2D = $Spark
        	var trail: CPUParticles2D = sprite.get_node_or_null("Trail")
        
        	if not sprite or not trail:
        		printerr("ERROR: CurrencyFlightVFX: Missing 'Spark' or 'Trail' nodes when play() called. Emitting finished.")
        		finished.emit()
        		return
        	
        	# Apply dynamic parameters
        	sprite.position = start_screen_pos # This is the key: set sprite position, not CanvasLayer's
        	sprite.modulate = color
        	trail.color = color * TRAIL_COLOR_MULTIPLIER
        	trail.emitting = true
        	sprite.scale = Vector2.ONE # Ensure scale is reset for animation
        
        	var duration = randf_range(FLIGHT_DURATION_MIN, FLIGHT_DURATION_MAX)
        	var spread = Vector2(randf_range(-BURST_SPREAD_MAGNITUDE, BURST_SPREAD_MAGNITUDE), randf_range(-BURST_SPREAD_MAGNITUDE, BURST_SPREAD_MAGNITUDE))
        	
        	var tween = create_tween()
        	tween.tween_property(sprite, "position", start_screen_pos + spread, BURST_OUT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        	tween.tween_property(sprite, "position", target_screen_pos, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN).set_delay(FLIGHT_DELAY)
        	tween.parallel().tween_property(sprite, "scale", Vector2(0,0), SHRINK_DURATION).set_delay(duration - SHRINK_DELAY_OFFSET)
        	
        	await tween.finished
        	finished.emit()
        ```
    *   **Implement `reset()` Method:**
        ```gdscript
        func reset() -> void:
        	var sprite: Sprite2D = $Spark
        	var trail: CPUParticles2D = sprite.get_node_or_null("Trail")
        	if trail:
        		trail.emitting = false
        		trail.clear_particles()
        	if sprite:
        		sprite.position = Vector2.ZERO
        		sprite.scale = Vector2.ONE
        		sprite.modulate = Color.WHITE # Reset modulate
        	# Kill any running tweens (Crucial for pooling to prevent conflicts)
        	var tweens = get_tree().get_tweens()
        	for t in tweens:
        		if t.is_valid() and t.get_target() == self:
        			t.kill()
        	hide() # Ensure hidden when returned to pool
        ```

### Phase 5: Call Site Migration

1.  **Modify `GameCore.gd`:**
    *   **Context:** `GameCore` emits requests for both `core_click_vfx` and `currency_flight_vfx`.
    *   **Update `_on_grid_shape_placed` (for core_click_vfx):**
        ```gdscript
        func _on_grid_shape_placed(coords: Vector2i, _type: String) -> void:
        	var world_pos: Vector2 = Vector2(coords) * GRID_CELL_SIZE # Use GRID_CELL_SIZE constant
        	var vfx_transform = Transform2D(0, world_pos) # Identity rotation/scale, just position
        	CoreVFXEventBus.request_vfx("core_click_vfx", vfx_transform, {"color": CORE_CLICK_GRID_COLOR})
        	play_sfx_2d("sfx_place_shape", world_pos)
        ```
    *   **Update `click_core()` (for core_click_vfx & currency_flight_vfx):**
        ```gdscript
        func click_core(screen_pos: Vector2) -> void:
        	# ... (existing logic for adding sparks) ...
        
        	# Request CoreClickVFX
        	var core_click_transform = Transform2D(0, screen_pos)
        	CoreVFXEventBus.request_vfx("core_click_vfx", core_click_transform, {"color": CORE_CLICK_MAIN_COLOR})
        
        	# Request CurrencyFlightVFX
        	var viewport = get_viewport()
        	var transform_matrix = viewport.canvas_transform
        	var start_screen_pos_for_ui = transform_matrix * screen_pos
        	var screen_size = viewport.get_visible_rect().size
        	var target_screen_pos = Vector2(screen_size.x * CURRENCY_FLIGHT_TARGET_X_FACTOR, CURRENCY_FLIGHT_TARGET_Y_POS)
        	
        	# For CanvasLayer VFX, global_transform will position the CanvasLayer.
        	# The actual flight path (start/target) is passed via params.
        	CoreVFXEventBus.request_vfx("currency_flight_vfx", Transform2D(), {"start_screen_pos": start_screen_pos_for_ui, "target_screen_pos": target_screen_pos, "color": CURRENCY_FLIGHT_COLOR})
        
        	# ... (existing audio logic) ...
        ```
    *   **Context:** `GRID_CELL_SIZE`, `CORE_CLICK_GRID_COLOR`, `CORE_CLICK_MAIN_COLOR`, `CURRENCY_FLIGHT_TARGET_X_FACTOR`, `CURRENCY_FLIGHT_TARGET_Y_POS`, `CURRENCY_FLIGHT_COLOR` should be available as constants, likely passed from `VFXManager` if `GameCore` is not aware of them, or `GameCore` would define its own constants (less ideal). For a cleaner solution, the `VFXConfig` `default_params` should hold these, and `GameCore` just provides the dynamic `transform`.
        *   **Refinement:** Instead of `GameCore` having to know all these colors and positions, these should primarily live in `VFXConfig.default_params`. `GameCore` would just provide the `global_transform` and minimal context-specific parameters.

2.  **Modify `GameSceneController.gd` (Review for direct VFX calls):**
    *   *Context:* Ensure no direct VFX spawning. (Unlikely, as `GameCore` usually orchestrates this). If any, migrate them.

3.  **Modify `VFXManager.gd` (Current, game-specific):**
    *   **Temporarily Disable:** Comment out the `CoreEventBus.request_vfx.connect(_on_request_vfx)` line in its `_ready()` or disconnect existing signals. This will prevent it from responding to `GameplayEventBus` and emitting to the old `VFXEventBus`.
    *   **Recommendation:** Rename its `_connect_vfx_event_bus_signals()` to `_TEMP_connect_vfx_event_bus_signals()` and comment out its call in `_ready()` to prevent the old system from activating.

This detailed plan, with code snippets and explicit instructions, should significantly improve the probability of successful code generation and a smooth migration.