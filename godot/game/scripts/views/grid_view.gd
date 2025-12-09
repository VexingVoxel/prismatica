class_name GridViewClass extends Node2D

## GridView
##
## Responsibility: Manages the visual representation of the grid.
## Listens to GameplayEventBus to spawn/update/animate shape nodes.

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------

const GRID_CELL_SIZE: int = 64
const SHAPE_SHELL_SHADER = preload("res://assets/shaders/shape_shell.gdshader")
const DATA_FLOW_SHADER = preload("res://assets/shaders/data_flow.gdshader")
const SHAPE_VISUAL_SCENE = preload("res://game/scenes/visuals/shape_visual.tscn")
const CORE_REACTOR_SCENE = preload("res://game/scenes/visuals/core_reactor.tscn")

const LIGHT_RADIUS: float = 250.0
const LIGHT_FALLOFF: float = 50.0

# ------------------------------------------------------------------------------
# Nodes
# ------------------------------------------------------------------------------

@onready var core_visual: Node2D = $CoreVisual # The container for the Core Reactor visual

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

var _visuals: Dictionary = {} # { Vector2i: ShapeVisual }
var _light_source_positions: Dictionary = {} # { unique_id: Vector2 } - For tracking lights
var _object_pool: Array[ShapeVisual] = [] # Object pool for ShapeVisual
@onready var grid_lines: ColorRect = get_node_or_null("/root/Main/GridCanvas/GridLines")
@onready var floor_rect: ColorRect = get_node_or_null("/root/Main/GridCanvas/FloorRect")

func _ready() -> void:
	# Initialize Core Reactor
	_draw_core_visual()
	
	_connect_signals()
	_draw_existing_grid() # In case of load game

func _connect_signals() -> void:
	GameplayEventBus.grid_shape_placed.connect(_on_grid_shape_placed)
	GameplayEventBus.grid_shape_leveled.connect(_on_grid_shape_leveled)
	GameplayEventBus.core_clicked.connect(_on_core_clicked)
	# GameplayEventBus.resource_changed.connect(...) for updating visual level if needed

func _add_light_source(position: Vector2, unique_id: Variant) -> void:
	_light_source_positions[unique_id] = position
	_update_shader_light_params()

func _remove_light_source(unique_id: Variant) -> void:
	_light_source_positions.erase(unique_id)
	_update_shader_light_params()

func _update_shader_light_params() -> void:
	var positions_array = PackedVector2Array(_light_source_positions.values())
	
	# Update Grid Lines Shader
	if grid_lines and grid_lines.material:
		var mat: ShaderMaterial = grid_lines.material
		mat.set_shader_parameter("light_count", positions_array.size())
		mat.set_shader_parameter("light_sources", positions_array)
		mat.set_shader_parameter("light_radius", LIGHT_RADIUS)
		mat.set_shader_parameter("light_falloff", LIGHT_FALLOFF)
		
	# Update Floor Shader
	if floor_rect and floor_rect.material:
		var mat: ShaderMaterial = floor_rect.material
		mat.set_shader_parameter("light_count", positions_array.size())
		mat.set_shader_parameter("light_sources", positions_array)
		mat.set_shader_parameter("light_radius", LIGHT_RADIUS)
		mat.set_shader_parameter("light_falloff", LIGHT_FALLOFF)

# ------------------------------------------------------------------------------
# Object Pooling
# ------------------------------------------------------------------------------

func _get_shape_visual_from_pool() -> ShapeVisual:
	if _object_pool.size() > 0:
		var visual = _object_pool.pop_back()
		visual.visible = true
		visual.get_node("Poly").material.set_shader_parameter("fill_alpha", 0.0) # Reset state
		visual.get_node("Poly").material.set_shader_parameter("outline_width", 2.0)
		return visual
	
	var new_visual = SHAPE_VISUAL_SCENE.instantiate()
	add_child(new_visual) # Add to scene tree once
	return new_visual

func _return_shape_visual_to_pool(visual: ShapeVisual) -> void:
	visual.visible = false
	visual.position = Vector2.ZERO # Reset position
	_object_pool.append(visual)
	visual.light_source_unregistered.disconnect(_on_shape_visual_light_unregistered) # Disconnect to prevent multiple
	visual.light_source_registered.disconnect(_on_shape_visual_light_registered)

# ------------------------------------------------------------------------------
# Event Handlers
# ------------------------------------------------------------------------------

func _on_grid_shape_placed(coords: Vector2i, type: String) -> void:
	var visual: ShapeVisual = _get_shape_visual_from_pool()
	visual.light_source_registered.connect(_on_shape_visual_light_registered)
	visual.light_source_unregistered.connect(_on_shape_visual_light_unregistered) # Connect for future removal
	visual.setup(coords, type, 1)
	
	_visuals[coords] = visual
	
	_on_grid_shape_leveled(coords, 1, false) # Animate to Level 1 fill

func _on_grid_shape_leveled(coords: Vector2i, new_level: int, _is_max: bool) -> void:
	if not _visuals.has(coords):
		return
		
	var visual: ShapeVisual = _visuals[coords]
	visual.update_visuals(new_level, "") # Type is unused for visuals currently

func _on_core_clicked(_pos: Vector2) -> void:
	# Simple tween for the circle pulse (Visceral Check)
	var tween: Tween = create_tween()
	tween.tween_property(core_visual, "scale", Vector2(1.1, 1.1), 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(core_visual, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

func _on_core_reactor_light_registered(position: Vector2) -> void:
	_add_light_source(position, "core") # Use "core" as unique ID for the Core Reactor

func _on_shape_visual_light_registered(position: Vector2, coords: Vector2i) -> void:
	_add_light_source(position, coords)

func _on_shape_visual_light_unregistered(coords: Vector2i) -> void:
	_remove_light_source(coords)

# ------------------------------------------------------------------------------
# Visual Logic
# ------------------------------------------------------------------------------

func _draw_core_visual() -> void:
	# Instance the Core Reactor Scene
	var core_reactor_scene = preload("res://game/scenes/visuals/core_reactor.tscn")
	var core_reactor_instance = core_reactor_scene.instantiate()
	
	# Connect to its signal to register its position as a light source (BEFORE adding to tree)
	core_reactor_instance.light_source_registered.connect(_on_core_reactor_light_registered)
	
	# Add it to the core_visual container
	core_visual.add_child(core_reactor_instance)

func _draw_existing_grid() -> void:
	# On load, we need to populate visuals
	var data: Dictionary = GameCore.get_grid_data()
	for coords in data:
		var cell: Dictionary = data[coords]
		# Use object pool for existing shapes
		var visual: ShapeVisual = _get_shape_visual_from_pool()
		visual.light_source_registered.connect(_on_shape_visual_light_registered)
		visual.light_source_unregistered.connect(_on_shape_visual_light_unregistered)
		visual.setup(coords, cell.get("type"), cell.get("level", 1))
		_visuals[coords] = visual # Store it
		
		_on_grid_shape_leveled(coords, cell.get("level", 1), false) # Animate to current level fill
