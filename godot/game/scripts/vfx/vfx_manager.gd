class_name VFXManagerClass extends Node

## VFXManager
##
## Responsibility: Manages visual effects (particles) and acts as the
## 2D-to-3D bridge for the Core Audio system.
##
## Architecture: Autoload (Singleton)

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	# Listen for gameplay events that need audio feedback
	GameplayEventBus.grid_shape_placed.connect(_on_grid_shape_placed)
	GameplayEventBus.core_clicked.connect(_on_core_clicked)

# ------------------------------------------------------------------------------
# Event Handlers
# ------------------------------------------------------------------------------

func _on_grid_shape_placed(coords: Vector2i, _type: String) -> void:
	# 1. Visuals: Spawn particle effect
	var world_pos: Vector2 = Vector2(coords) * 64.0 
	_spawn_particles(world_pos, Color.CYAN)
	
	# 2. Audio: Play placement sound
	play_sfx_2d("sfx_place_shape", world_pos)

func _on_core_clicked(position: Vector2) -> void:
	# 1. Visuals: Spawn click burst
	_spawn_particles(position, Color.WHITE, 16, 0.5, 200.0)
	
	# 2. Audio: Play click sound
	play_sfx_2d("sfx_core_click", position)

# ------------------------------------------------------------------------------
# Internal Helpers
# ------------------------------------------------------------------------------

func _spawn_particles(pos: Vector2, color: Color, amount: int = 10, lifetime: float = 0.5, speed: float = 100.0) -> void:
	var parts: CPUParticles2D = CPUParticles2D.new()
	parts.position = pos
	parts.amount = amount
	parts.lifetime = lifetime
	parts.one_shot = true
	parts.explosiveness = 1.0
	parts.spread = 180.0
	parts.gravity = Vector2(0, 0)
	parts.initial_velocity_min = speed * 0.5
	parts.initial_velocity_max = speed
	parts.scale_amount_min = 2.0
	parts.scale_amount_max = 4.0
	parts.color = color
	
	# Add to scene tree - ideally to a specific layer, but we'll add to self (VFXManager is a Node)
	# Wait, VFXManager is an Autoload (Node). If we add child to it, where does it render?
	# Autoloads are at the root. It should render in the overlay or behind depending on tree order.
	# Better to add to the *Current Scene* or a specific VFX layer.
	# For POC, let's try adding to get_tree().current_scene
	if get_tree().current_scene:
		get_tree().current_scene.add_child(parts)
		parts.emitting = true
		
		# Auto-cleanup
		await get_tree().create_timer(lifetime + 0.1).timeout
		if is_instance_valid(parts):
			parts.queue_free()

# ------------------------------------------------------------------------------
# Public API (Audio Bridge)
# ------------------------------------------------------------------------------

## Plays a 2D sound effect by converting it to a 3D request for the Core AudioManager.
## [param sound_id]: The resource path or key for the sound.
## [param pos_2d]: The screen/world position in 2D.
func play_sfx_2d(sound_id: String, pos_2d: Vector2) -> void:
	# Convert 2D position to 3D (Z=0) as per v0.5.3 Spec
	var pos_3d: Vector3 = Vector3(pos_2d.x, pos_2d.y, 0.0)
	
	# Emit to CoreEventBus (Infrastructure)
	# Signature: sfx_play_requested(sound_id, position_3d, volume_db, pitch_scale)
	CoreEventBus.sfx_play_requested.emit(sound_id, pos_3d, 0.0, 1.0)
