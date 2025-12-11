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