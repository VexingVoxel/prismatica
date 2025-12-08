class_name VFXManagerClass extends Node

var _spark_texture: GradientTexture2D

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	_init_resources()
	_connect_signals()

func _init_resources() -> void:
	_spark_texture = GradientTexture2D.new()
	_spark_texture.fill = GradientTexture2D.FILL_RADIAL
	_spark_texture.fill_from = Vector2(0.5, 0.5)
	_spark_texture.fill_to = Vector2(0.5, 0.0)
	_spark_texture.width = 16
	_spark_texture.height = 16
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	_spark_texture.gradient = grad

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
	_spawn_particles(position, Color(4.0, 3.5, 1.0), 16, 0.5, 200.0)
	# 2. Visuals: Fly to HUD (Single significant spark)
	spawn_currency_flight(position, 1)
	
	# 3. Audio: Play click sound
	play_sfx_2d("sfx_core_click", position)

# ...

func spawn_currency_flight(start_pos: Vector2, amount: int) -> void:
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	# 1. Calculate Positions in Screen Space (HUD)
	var transform = viewport.canvas_transform
	var start_screen_pos = transform * start_pos
	var target_screen_pos = Vector2(screen_size.x / 2.0, 60.0) # Top Center
	
	# 2. Find a valid parent (CanvasLayer)
	# Try to find the HUD layer, or create a temporary one if needed
	# For simplicity in this POC, we'll create a temporary CanvasLayer for this burst
	# (Optimisation: Pool this layer)
	var vfx_layer = CanvasLayer.new()
	vfx_layer.layer = 100 # High layer
	get_tree().current_scene.add_child(vfx_layer)
	
	# Auto-cleanup layer after animation
	var total_duration = 1.5
	get_tree().create_timer(total_duration).timeout.connect(vfx_layer.queue_free)
	
	for i in range(amount):
		var sprite = Sprite2D.new()
		sprite.texture = _spark_texture 
		sprite.scale = Vector2(1.0, 1.0) # 16px
		sprite.position = start_screen_pos
		# No Z-Index needed, Layer 100 handles it
		vfx_layer.add_child(sprite)
		
		# Add Sizzle Trail
		var trail = CPUParticles2D.new()
		trail.amount = 16
		trail.lifetime = 0.5
		trail.local_coords = false
		trail.texture = _spark_texture
		trail.scale_amount_min = 0.2
		trail.scale_amount_max = 0.5
		trail.color = Color(1.0, 0.8, 0.2) # Gold Sizzle
		trail.gravity = Vector2(0, 100)
		trail.emitting = true
		sprite.add_child(trail)
		
		var duration = randf_range(0.8, 1.2)
		var spread = Vector2(randf_range(-32, 32), randf_range(-32, 32))
		
		var tween = vfx_layer.create_tween() # Bound to layer
		
		# Burst out (Screen Space spread)
		tween.tween_property(sprite, "position", start_screen_pos + spread, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# Fly to target
		tween.tween_property(sprite, "position", target_screen_pos, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN).set_delay(0.05)
		
		# No shrink, just vanish on queue_free (persists until layer cleanup)
		
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
	parts.z_index = 200 # Render above everything
	
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
