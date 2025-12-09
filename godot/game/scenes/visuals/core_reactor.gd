class_name CoreReactor extends Node2D

signal light_source_registered(position: Vector2)

func _ready() -> void:
	_draw_core_reactor()
	print("CoreReactor: Emitting signal with global_position:", global_position)
	emit_signal("light_source_registered", global_position)

func _draw_core_reactor() -> void:
	# Draw the Core Reactor
	self.z_index = 10 # Draw on top relative to GridView

	# 1. Reactor Floor (Socket)
	var floor_rect = ColorRect.new()
	floor_rect.size = Vector2(192, 192)
	floor_rect.position = Vector2(-96, -96)
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor_rect.z_index = -5 # Draw behind core rings

	var floor_mat = ShaderMaterial.new()
	floor_mat.shader = preload("res://assets/shaders/reactor_floor.gdshader")
	floor_rect.material = floor_mat

	add_child(floor_rect) # Add to CoreReactor scene directly

	# Helper to create rings
	var create_ring = func(radius: float, width: float, color: Color, shader_path: String, params: Dictionary) -> Line2D:
		var line = Line2D.new()
		var points = PackedVector2Array()
		var segments = 64
		for i in range(segments + 1): # +1 to close loop smoothly
			var angle = (TAU / segments) * i
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		line.points = points
		line.width = width
		line.default_color = color
		# Use STRETCH to ensure UV.x goes 0..1 around the full circle
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.texture = PlaceholderTexture2D.new()

		var mat = ShaderMaterial.new()
		mat.shader = load(shader_path)
		for k in params:
			mat.set_shader_parameter(k, params[k])
		line.material = mat

		add_child(line) # Add to CoreReactor scene directly
		return line

	# 2. Outer Ring (Gyro - Slow Segmented)
	var outer_ring = create_ring.call(64.0, 4.0, Color.CYAN, "res://assets/shaders/segmented_ring.gdshader", {
		"ring_color": Color(0.0, 1.0, 1.0, 0.5), # Dimmer
		"segments": 12,
		"gap_size": 0.3,
		"speed": 0.1
	})
	# Rotate Outer
	var t_out = create_tween().set_loops()
	t_out.tween_property(outer_ring, "rotation", TAU, 20.0).as_relative() # Slow Spin

	# 3. Primary Ring (Energy Flow - Static Geometry, Scrolling Texture)
	create_ring.call(48.0, 8.0, Color.WHITE, "res://assets/shaders/energy_flow.gdshader", {
		"base_color": Color(4.0, 4.0, 4.0), # Reverted
		"flow_color": Color(0.0, 2.0, 2.0),
		"speed": 2.0,
		"turbulence": 5.0
	})

	# 4. Inner Ring (Gyro - Fast Energy)
	var inner_ring = create_ring.call(32.0, 2.0, Color.WHITE, "res://assets/shaders/energy_flow.gdshader", {
		"base_color": Color(8.0, 8.0, 8.0), # Reverted
		"flow_color": Color(0.0, 1.0, 1.0),
		"speed": 5.0,
		"turbulence": 2.0
	})
	# Rotate Inner (Counter-Clockwise)
	var t_in = create_tween().set_loops()
	t_in.tween_property(inner_ring, "rotation", -TAU, 4.0).as_relative()

	# 5. Singularity Orb (Center)
	var orb = ColorRect.new()
	var orb_size = 48.0
	orb.size = Vector2(orb_size, orb_size)
	orb.position = Vector2(-orb_size/2, -orb_size/2)
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var orb_mat = ShaderMaterial.new()
	orb_mat.shader = preload("res://assets/shaders/singularity_orb.gdshader")
	orb_mat.set_shader_parameter("core_color", Color(4.0, 2.0, 0.5, 1.0)) # Reverted
	orb_mat.set_shader_parameter("edge_color", Color(4.0, 0.5, 0.0, 1.0)) # Reverted
	orb.material = orb_mat
	
	add_child(orb) # Add to CoreReactor scene directly
	
	# Pulse Orb
	var t_orb = create_tween().set_loops()
	t_orb.tween_property(orb, "scale", Vector2(1.1, 1.1), 1.0).set_trans(Tween.TRANS_SINE)
	t_orb.tween_property(orb, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)
	# Adjust pivot for scale to work from center
	orb.pivot_offset = Vector2(orb_size/2, orb_size/2)
