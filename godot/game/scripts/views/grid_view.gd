class_name GridViewClass extends Node2D

## GridView
##
## Responsibility: Manages the visual representation of the grid.
## Listens to GameplayEventBus to spawn/update/animate shape nodes.
##
## Note: In a real implementation, this would handle object pooling for shapes.

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------

const GRID_CELL_SIZE: int = 64
const SHAPE_SHELL_SHADER = preload("res://assets/shaders/shape_shell.gdshader")
const DATA_FLOW_SHADER = preload("res://assets/shaders/data_flow.gdshader")

# ------------------------------------------------------------------------------
# Nodes
# ------------------------------------------------------------------------------

@onready var core_visual: Node2D = $CoreVisual # We'll need to create this in the scene

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

var _visuals: Dictionary = {} # { Vector2i: Node2D }
var _light_positions: Array[Vector2] = []
@onready var grid_lines: ColorRect = get_node_or_null("/root/Main/GridCanvas/GridLines")
@onready var floor_rect: ColorRect = get_node_or_null("/root/Main/GridCanvas/FloorRect")

func _ready() -> void:
	# Initialize Lighting with Core Position
	_add_light_source(Vector2.ZERO)
	
	# Camera2D will handle centering (Core is at 0,0)
	
	_draw_core_visual()
	_connect_signals()
	_draw_existing_grid() # In case of load game

func _connect_signals() -> void:
	GameplayEventBus.grid_shape_placed.connect(_on_grid_shape_placed)
	GameplayEventBus.grid_shape_leveled.connect(_on_grid_shape_leveled)
	GameplayEventBus.core_clicked.connect(_on_core_clicked)
	# GameplayEventBus.resource_changed.connect(...) for updating visual level if needed

func _add_light_source(pos: Vector2) -> void:
	_light_positions.append(pos)
	
	# Update Grid Lines Shader
	if grid_lines and grid_lines.material:
		var mat: ShaderMaterial = grid_lines.material
		mat.set_shader_parameter("light_count", _light_positions.size())
		mat.set_shader_parameter("light_sources", PackedVector2Array(_light_positions))
		
	# Update Floor Shader
	if floor_rect and floor_rect.material:
		var mat: ShaderMaterial = floor_rect.material
		mat.set_shader_parameter("light_count", _light_positions.size())
		mat.set_shader_parameter("light_sources", PackedVector2Array(_light_positions))

# ------------------------------------------------------------------------------
# Event Handlers
# ------------------------------------------------------------------------------

func _on_grid_shape_placed(coords: Vector2i, type: String) -> void:
	_spawn_shape_visual(coords, type, 1) # Default level 1
	_on_grid_shape_leveled(coords, 1, false) # Animate to Level 1 fill
	_update_connections(coords)

func _on_grid_shape_leveled(coords: Vector2i, new_level: int, _is_max: bool) -> void:
	if not _visuals.has(coords):
		return
		
	var visual: Node2D = _visuals[coords]
	var poly: Polygon2D = visual.get_node("Poly")
	if poly and poly.material:
		var mat: ShaderMaterial = poly.material
		
		# Colors
		var color_low: Color = Color(0.0, 0.4, 0.4, 0.8) # Dim
		var color_mid: Color = Color(0.0, 1.0, 1.0, 1.0) # Standard
		var color_high: Color = Color(0.0, 2.0, 2.0, 1.0) # HDR
		var color_max: Color = Color(0.0, 4.0, 4.0, 1.0) # Pure HDR Cyan (No Red)
		
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
			target_width = 4.0 # Slight bump for max
			target_fill_alpha = 0.6 # Semi-transparent fill to show outline contrast
		
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(mat, "shader_parameter/outline_color", target_color, 0.5)
		tween.tween_property(mat, "shader_parameter/outline_width", target_width, 0.5)
		tween.tween_property(mat, "shader_parameter/fill_alpha", target_fill_alpha, 0.5)
		
		# Pop Effect on transition
		tween.tween_property(visual, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(visual, "scale", Vector2(1.0, 1.0), 0.1)

func _on_core_clicked(_pos: Vector2) -> void:
	# Simple tween for the circle pulse (Visceral Check)
	var tween: Tween = create_tween()
	tween.tween_property(core_visual, "scale", Vector2(1.1, 1.1), 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(core_visual, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

# ------------------------------------------------------------------------------
# Visual Logic
# ------------------------------------------------------------------------------

func _draw_core_visual() -> void:
	# Draw the Core Circle
	core_visual.z_index = 10 # Draw on top
	
	# 1. Reactor Floor (Background)
	var floor_rect = ColorRect.new()
	floor_rect.size = Vector2(192, 192)
	floor_rect.position = Vector2(-96, -96)
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var floor_mat = ShaderMaterial.new()
	floor_mat.shader = preload("res://assets/shaders/reactor_floor.gdshader")
	floor_rect.material = floor_mat
	
	core_visual.add_child(floor_rect)
	
	# 2. Core Geometry
	var poly: Polygon2D = Polygon2D.new()
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 32
	var radius: float = 48.0
	for i in range(segments):
		var angle: float = (TAU / segments) * i
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	poly.polygon = points
	poly.color = Color.WHITE
	
	var line: Line2D = Line2D.new()
	line.points = points
	line.add_point(points[0]) # Close loop
	line.width = 6.0
	line.default_color = Color.WHITE
	
	# Energy Flow Shader
	var shader = preload("res://assets/shaders/energy_flow.gdshader")
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", Color(4.0, 4.0, 4.0)) # HDR White
	material.set_shader_parameter("flow_color", Color(0.0, 2.0, 2.0)) # HDR Cyan
	material.set_shader_parameter("speed", 3.0)
	material.set_shader_parameter("turbulence", 10.0)
	line.material = material
	
	# REQUIRED: Texture for UV mapping on Line2D
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.texture = PlaceholderTexture2D.new()
	
	core_visual.add_child(line)

func _spawn_shape_visual(coords: Vector2i, type: String, level: int = 1) -> void:
	if _visuals.has(coords):
		return
		
	# Convert Grid Coords to Local Pos
	var local_pos: Vector2 = Vector2(coords) * GRID_CELL_SIZE
	
	# Register Light Source for Grid Shader
	_add_light_source(local_pos)
	
	# Create Visual
	var visual: Node2D = Node2D.new()
	visual.position = local_pos
	
	var poly: Polygon2D = Polygon2D.new()
	poly.name = "Poly" # Name it for finding later
	var size: float = GRID_CELL_SIZE * 0.8 
	var offset: float = size / 2.0
	poly.polygon = PackedVector2Array([
		Vector2(-offset, -offset), # Top Left
		Vector2(offset, -offset),  # Top Right
		Vector2(offset, offset),   # Bottom Right
		Vector2(-offset, offset)   # Bottom Left
	])
	# Use Normalized UVs for Shader
	poly.uv = PackedVector2Array([
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(1, 1),
		Vector2(0, 1)
	])
	
	# Apply Shader
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHAPE_SHELL_SHADER
	# Initial params (Level 0/1)
	material.set_shader_parameter("outline_color", Color(0.0, 0.4, 0.4, 0.5)) # Dim Cyan
	material.set_shader_parameter("fill_color", Color(0.0, 1.0, 1.0, 1.0)) # Solid Cyan
	material.set_shader_parameter("outline_width", 2.0)
	material.set_shader_parameter("fill_alpha", 0.0) # Empty
	material.set_shader_parameter("size", Vector2(size, size))
	poly.material = material
	
	# REQUIRED: Texture for UV mapping
	var texture: PlaceholderTexture2D = PlaceholderTexture2D.new()
	texture.size = Vector2(1, 1) # 1x1 Texture ensures 0..1 UVs map 1:1 to Shader UVs
	poly.texture = texture
	
	visual.add_child(poly)

	add_child(visual)
	_visuals[coords] = visual
	
	# Update to current level visuals
	_on_grid_shape_leveled(coords, level, false)

func _draw_existing_grid() -> void:
	# On load, we need to populate visuals
	var data: Dictionary = GameCore.get_grid_data()
	for coords in data:
		var cell: Dictionary = data[coords]
		_spawn_shape_visual(coords, cell.get("type"), cell.get("level", 1))
		_on_grid_shape_leveled(coords, cell.get("level", 1), false) # Animate to current level fill
		_update_connections(coords)

func _update_connections(coords: Vector2i) -> void:
	# Disabled for visual clarity (v0.2 Refinement)
	pass
	# Check adjacent neighbors and draw lines
	# var neighbors: Array[Vector2i] = [ ...

func _spawn_connection_line(from_coords: Vector2i, to_coords: Vector2i) -> void:
	# Check if line already exists? For POC, just draw it.
	# To avoid double drawing, only draw if from < to (lexicographical check?)
	# Or just draw. Double alpha might look cool.
	
	var from_pos: Vector2 = Vector2(from_coords) * GRID_CELL_SIZE
	var to_pos: Vector2 = Vector2(to_coords) * GRID_CELL_SIZE
	
	var line: Line2D = Line2D.new()
	line.points = PackedVector2Array([from_pos, to_pos])
	line.width = 4.0
	line.default_color = Color.CYAN
	
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = DATA_FLOW_SHADER
	material.set_shader_parameter("flow_color", Color(0, 1, 1, 0.5))
	material.set_shader_parameter("speed", 2.0)
	line.material = material
	
	# Z-Index below shapes
	line.z_index = -1
	
	# Add to GridView root so it's behind everything (if z_index works relative to parent)
	add_child(line)
