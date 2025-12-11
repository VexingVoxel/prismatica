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
	
	if instance.get_parent() != parent_node:
		if instance.get_parent():
			instance.get_parent().remove_child(instance)
		parent_node.add_child(instance)
		
	instance.global_transform = global_transform # Apply position, rotation, scale
	
	# Merge parameters: Event params override default params
	var final_params = config.default_params.duplicate(true) # Deep duplicate config defaults
	for key in event_params: # Overlay event-specific params
		final_params[key] = event_params[key]
	
	instance.play(final_params)
	instance.finished.connect(Callable(self, "_return_to_pool").bind(instance), CONNECT_ONE_SHOT)