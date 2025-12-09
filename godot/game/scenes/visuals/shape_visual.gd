class_name ShapeVisual extends Node2D

signal light_source_registered(position: Vector2, coords: Vector2i)
signal light_source_unregistered(coords: Vector2i) # For pooling

# Constants moved from GridView
const GRID_CELL_SIZE: int = 64
const SHAPE_SHELL_SHADER = preload("res://assets/shaders/shape_shell.gdshader")

var _coords: Vector2i = Vector2i.ZERO # Store grid coordinates for unique_id

var _poly: Polygon2D
var _material: ShaderMaterial

func _init() -> void:
	_poly = Polygon2D.new()
	_poly.name = "Poly" # Name it for finding later
	
	var size: float = GRID_CELL_SIZE * 0.8 # Slightly smaller than cell
	var offset: float = size / 2.0
	_poly.polygon = PackedVector2Array([
		Vector2(-offset, -offset), # Top Left
		Vector2(offset, -offset),  # Top Right
		Vector2(offset, offset),   # Bottom Right
		Vector2(-offset, offset)   # Bottom Left
	])
	_poly.uv = PackedVector2Array([
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(1, 1),
		Vector2(0, 1)
	])
	
	_material = ShaderMaterial.new()
	_material.shader = SHAPE_SHELL_SHADER
	_poly.material = _material
	
	var texture: PlaceholderTexture2D = PlaceholderTexture2D.new()
	texture.size = Vector2(1, 1) 
	_poly.texture = texture
	
	add_child(_poly)

func setup(coords: Vector2i, type: String, level: int = 1) -> void:
	self.position = Vector2(coords) * GRID_CELL_SIZE
	self._coords = coords
	
	_material.set_shader_parameter("outline_color", Color(0.0, 0.4, 0.4, 1.0)) # Very Muted Cyan
	_material.set_shader_parameter("fill_color", Color(0.0, 1.0, 1.0, 1.0)) 
	_material.set_shader_parameter("outline_width", 2.0)
	_material.set_shader_parameter("fill_alpha", 0.0) 
	_material.set_shader_parameter("size", Vector2(GRID_CELL_SIZE * 0.8, GRID_CELL_SIZE * 0.8)) # Pass actual size
	
	update_visuals(level, type) # Type is unused for visuals currently
	
	# Emit signal when position is known and setup is complete
	emit_signal("light_source_registered", global_position, _coords)

func update_visuals(new_level: int, type: String) -> void: # Type is unused for visuals currently
	# Colors - All HDR for Glow
	var color_low: Color = Color(0.0, 0.4, 0.4, 1.0) # Level 1 (Very Muted) - No Glow
	var color_mid: Color = Color(0.0, 0.6, 0.6, 1.0) # Level 2-3 (Subtle Visible) - No Glow
	var color_high: Color = Color(0.0, 0.75, 0.75, 1.0) # Level 4 (Clearly Visible) - No Glow
	var color_max: Color = Color(0.0, 3.5, 3.5, 1.0) # Level 5 (Spot on glow)
	
	# Target Props
	var target_color: Color
	var target_width: float
	var target_fill_alpha: float
	
	if new_level <= 1:
		target_color = color_low
		target_width = 3.0
		target_fill_alpha = 0.0
	elif new_level < 5:
		# Lerp from Mid to High based on level 2-4
		var t: float = float(new_level - 1) / 3.0 # 0.0 to 1.0
		target_color = color_mid.lerp(color_high, t)
		target_width = 3.0 # Constant width
		target_fill_alpha = 0.0
	else: # Level 5+
		target_color = color_max
		target_width = 3.0 # Match others to prevent blob
		target_fill_alpha = 0.2 # Very semi-transparent fill		
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(_material, "shader_parameter/outline_color", target_color, 0.5)
	tween.tween_property(_material, "shader_parameter/outline_width", target_width, 0.5)
	tween.tween_property(_material, "shader_parameter/fill_alpha", target_fill_alpha, 0.5)
	
	# Pop Effect on transition
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPARENTED and _coords != Vector2i.ZERO:
		emit_signal("light_source_unregistered", _coords)
		_coords = Vector2i.ZERO # Reset