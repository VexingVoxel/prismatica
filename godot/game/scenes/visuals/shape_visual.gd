class_name ShapeVisual extends Node2D

signal light_source_registered(position: Vector2, coords: Vector2i)
signal light_source_unregistered(coords: Vector2i) # For pooling

# Constants moved from GridView
const GRID_CELL_SIZE: int = 64
const SHAPE_SHELL_SHADER = preload("res://assets/shaders/shape_shell.gdshader")

# New Constants for Shape Visuals
const SHAPE_SIZE_MULTIPLIER: float = 0.8
const DEFAULT_OUTLINE_COLOR: Color = Color(0.0, 0.4, 0.4, 1.0) # Very Muted Cyan
const DEFAULT_FILL_COLOR: Color = Color(0.0, 1.0, 1.0, 1.0)
const DEFAULT_OUTLINE_WIDTH: float = 2.0
const DEFAULT_FILL_ALPHA: float = 0.0

const LEVEL_ONE_THRESHOLD: int = 1
const LEVEL_FOUR_THRESHOLD: int = 4 # new_level < 5
const LEVEL_LERP_DIVISOR: float = 3.0 # For lerping between level 2-4

const HIGH_LEVEL_OUTLINE_WIDTH: float = 3.0
const HIGH_LEVEL_FILL_ALPHA: float = 0.2

const COLOR_LOW: Color = Color(0.0, 0.4, 0.4, 1.0) # Level 1 (Very Muted) - No Glow
const COLOR_MID: Color = Color(0.0, 0.6, 0.6, 1.0) # Level 2-3 (Subtle Visible) - No Glow
const COLOR_HIGH: Color = Color(0.0, 0.75, 0.75, 1.0) # Level 4 (Clearly Visible) - No Glow
const COLOR_MAX: Color = Color(0.0, 3.5, 3.5, 1.0) # Level 5 (Spot on glow)

const TWEEN_DURATION_COLOR_WIDTH_ALPHA: float = 0.5
const TWEEN_SCALE_MAX: float = 1.2
const TWEEN_SCALE_MIN: float = 1.0
const TWEEN_SCALE_DURATION: float = 0.1

var _coords: Vector2i = Vector2i.ZERO # Store grid coordinates for unique_id

var _poly: Polygon2D
var _material: ShaderMaterial

func _init() -> void:
	_poly = Polygon2D.new()
	_poly.name = "Poly" # Name it for finding later
	
	var size: float = GRID_CELL_SIZE * SHAPE_SIZE_MULTIPLIER # Slightly smaller than cell
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
	
	_material.set_shader_parameter("outline_color", DEFAULT_OUTLINE_COLOR)
	_material.set_shader_parameter("fill_color", DEFAULT_FILL_COLOR) 
	_material.set_shader_parameter("outline_width", DEFAULT_OUTLINE_WIDTH)
	_material.set_shader_parameter("fill_alpha", DEFAULT_FILL_ALPHA) 
	_material.set_shader_parameter("size", Vector2(GRID_CELL_SIZE * SHAPE_SIZE_MULTIPLIER, GRID_CELL_SIZE * SHAPE_SIZE_MULTIPLIER)) # Pass actual size
	
	update_visuals(level, type) # Type is unused for visuals currently
	
	# Emit signal when position is known and setup is complete
	emit_signal("light_source_registered", global_position, _coords)

func update_visuals(new_level: int, type: String) -> void: # Type is unused for visuals currently
	# Target Props
	var target_color: Color
	var target_width: float
	var target_fill_alpha: float
	
	if new_level <= LEVEL_ONE_THRESHOLD:
		target_color = COLOR_LOW
		target_width = HIGH_LEVEL_OUTLINE_WIDTH
		target_fill_alpha = DEFAULT_FILL_ALPHA
	elif new_level < LEVEL_FOUR_THRESHOLD + 1: # For levels 2-4
		# Lerp from Mid to High based on level 2-4
		var t: float = float(new_level - LEVEL_ONE_THRESHOLD) / LEVEL_LERP_DIVISOR # 0.0 to 1.0
		target_color = COLOR_MID.lerp(COLOR_HIGH, t)
		target_width = HIGH_LEVEL_OUTLINE_WIDTH # Constant width
		target_fill_alpha = DEFAULT_FILL_ALPHA
	else: # Level 5+
		target_color = COLOR_MAX
		target_width = HIGH_LEVEL_OUTLINE_WIDTH # Match others to prevent blob
		target_fill_alpha = HIGH_LEVEL_FILL_ALPHA # Very semi-transparent fill		
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(_material, "shader_parameter/outline_color", target_color, TWEEN_DURATION_COLOR_WIDTH_ALPHA)
	tween.tween_property(_material, "shader_parameter/outline_width", target_width, TWEEN_DURATION_COLOR_WIDTH_ALPHA)
	tween.tween_property(_material, "shader_parameter/fill_alpha", target_fill_alpha, TWEEN_DURATION_COLOR_WIDTH_ALPHA)
	
	# Pop Effect on transition
	tween.tween_property(self, "scale", Vector2(TWEEN_SCALE_MAX, TWEEN_SCALE_MAX), TWEEN_SCALE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2(TWEEN_SCALE_MIN, TWEEN_SCALE_MIN), TWEEN_SCALE_DURATION)

func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPARENTED and _coords != Vector2i.ZERO:
		emit_signal("light_source_unregistered", _coords)
		_coords = Vector2i.ZERO # Reset