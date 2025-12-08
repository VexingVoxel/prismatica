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
const LIQUID_SHADER = preload("res://assets/shaders/liquid_fill.gdshader")
const DATA_FLOW_SHADER = preload("res://assets/shaders/data_flow.gdshader")

# ------------------------------------------------------------------------------
# Nodes
# ------------------------------------------------------------------------------

@onready var core_visual: Node2D = $CoreVisual # We'll need to create this in the scene

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	# Camera2D will handle centering (Core is at 0,0)
	
	_draw_core_visual()
	_connect_signals()
	_draw_existing_grid() # In case of load game

func _connect_signals() -> void:
	GameplayEventBus.grid_shape_placed.connect(_on_grid_shape_placed)
	GameplayEventBus.grid_shape_leveled.connect(_on_grid_shape_leveled)
	GameplayEventBus.core_clicked.connect(_on_core_clicked)
	# GameplayEventBus.resource_changed.connect(...) for updating visual level if needed

# ------------------------------------------------------------------------------
# Event Handlers
# ------------------------------------------------------------------------------

func _on_grid_shape_placed(coords: Vector2i, type: String) -> void:
	_spawn_shape_visual(coords, type, 1) # Default level 1
	_on_grid_shape_leveled(coords, 1, false) # Animate to Level 1 fill
	_update_connections(coords)

func _on_grid_shape_leveled(coords: Vector2i, new_level: int, _is_max: bool) -> void:
	# Find the visual node (We need a tracking dictionary)
	if not _visuals.has(coords):
		return
		
	var visual: Node2D = _visuals[coords]
	var poly: Polygon2D = visual.get_node("Poly")
	if poly and poly.material:
		# Visual Feedback: Increase fill
		var target_fill: float = clamp(0.2 * (new_level - 1), 0.0, 1.0)
		
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		# Animate Fill
		tween.tween_property(poly.material, "shader_parameter/fill_level", target_fill, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# Pop Effect
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

var _visuals: Dictionary = {} # { Vector2i: Node2D }

func _draw_core_visual() -> void:
	# Draw the Core Circle
	# In a real scene, this would be a Sprite or separate scene.
	# For POC, we draw primitives.
	core_visual.z_index = 10 # Draw on top
	
	# We can't draw directly on a Node2D easily without _draw().
	# Let's add a Polygon2D child to it dynamically or assume it exists.
	# Better: Use _draw() on the CoreVisual node if it was a custom script, 
	# but since it's a generic Node2D, we'll attach a Polygon2D.
	
	var poly: Polygon2D = Polygon2D.new()
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 32
	var radius: float = 48.0
	for i in range(segments):
		var angle: float = (TAU / segments) * i
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	poly.polygon = points
	poly.color = Color.WHITE
	# Make it hollow-ish (Visual Spec: Hollow White Circle)
	# Polygon2D is solid. We need a Line2D or a hollow polygon.
	# Let's use Line2D for the outline.
	
	var line: Line2D = Line2D.new()
	line.points = points
	line.add_point(points[0]) # Close loop
	line.width = 4.0
	line.default_color = Color.WHITE
	
	core_visual.add_child(line)

func _spawn_shape_visual(coords: Vector2i, type: String, level: int = 1) -> void:
	if _visuals.has(coords):
		return
		
	# Convert Grid Coords to Local Pos
	var local_pos: Vector2 = Vector2(coords) * GRID_CELL_SIZE
	
	# Create Visual
	# Placeholder: Cyan Square (Polygon2D)
	var visual: Node2D = Node2D.new()
	visual.position = local_pos
	
	var poly: Polygon2D = Polygon2D.new()
	poly.name = "Poly" # Name it for finding later
	var size: float = GRID_CELL_SIZE * 0.8 # Slightly smaller than cell
	var offset: float = size / 2.0
	poly.polygon = PackedVector2Array([
		Vector2(-offset, -offset), # Top Left
		Vector2(offset, -offset),  # Top Right
		Vector2(offset, offset),   # Bottom Right
		Vector2(-offset, offset)   # Bottom Left
	])
	poly.uv = PackedVector2Array([
		Vector2(0, 0),
		Vector2(size, 0),
		Vector2(size, size),
		Vector2(0, size)
	])
	
	# Apply Shader
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = LIQUID_SHADER
	material.set_shader_parameter("fill_color", Color.CYAN)
	material.set_shader_parameter("bg_color", Color(0.0, 0.2, 0.2, 0.5)) # Dark Cyan container
	material.set_shader_parameter("fill_level", 0.0) # Start Empty
	poly.material = material
	
	# REQUIRED: Texture for UV mapping
	var texture: PlaceholderTexture2D = PlaceholderTexture2D.new()
	texture.size = Vector2(size, size)
	poly.texture = texture
	
	visual.add_child(poly)
	add_child(visual)
	_visuals[coords] = visual
	
	# Initial fill level is 0.0, animation will be triggered by _on_grid_shape_leveled


func _draw_existing_grid() -> void:
	# On load, we need to populate visuals
	var data: Dictionary = GameCore.get_grid_data()
	for coords in data:
		var cell: Dictionary = data[coords]
		_spawn_shape_visual(coords, cell.get("type"), cell.get("level", 1))
		_on_grid_shape_leveled(coords, cell.get("level", 1), false) # Animate to current level fill
		_update_connections(coords)

func _update_connections(coords: Vector2i) -> void:
	# Check adjacent neighbors and draw lines
	var neighbors: Array[Vector2i] = [
		coords + Vector2i.UP,
		coords + Vector2i.DOWN,
		coords + Vector2i.LEFT,
		coords + Vector2i.RIGHT
	]
	
	for neighbor in neighbors:
		if _visuals.has(neighbor):
			_spawn_connection_line(coords, neighbor)

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
