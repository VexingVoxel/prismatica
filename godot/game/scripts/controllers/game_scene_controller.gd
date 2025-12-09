class_name GameSceneControllerClass extends Node2D

## GameSceneController
##
## Responsibility: Translates raw user input into Game Commands (Place, Click, Upgrade).
## Implements the "Click-to-Select / Click-to-Place" interaction model (v0.5.3).

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------

const GRID_CELL_SIZE: int = 64
const CORE_CLICK_RADIUS: float = 64.0 # Radius for detecting a click on the Core
const CORE_EXCLUSION_RADIUS: int = 1 # 3x3 area around the core (0,0) where shapes cannot be placed
const SHAPE_PLACEMENT_COST: int = 10 # Base cost in Sparks for placing a square shape

# ------------------------------------------------------------------------------
# State
# ------------------------------------------------------------------------------

# Input State Machine
enum InputState {
	IDLE,
	PLACING_SHAPE
}

var _current_state: InputState = InputState.IDLE
var _selected_shape_type: String = ""

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	pass # Ready for logic

# ------------------------------------------------------------------------------
# Event Handlers (Input)
# ------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click()

func _handle_left_click(screen_pos: Vector2) -> void:
	match _current_state:
		InputState.IDLE:
			# With Camera2D centered at (0,0), the global mouse position is the world position.
			# Core is at World (0,0).
			var world_pos: Vector2 = get_global_mouse_position()
			
			# Simple distance check for Core Click
			if world_pos.length() < CORE_CLICK_RADIUS:
				GameCore.click_core(world_pos)
			else:
				# Check if clicked on a grid shape -> Upgrade
				var grid_x: int = int(round(world_pos.x / GRID_CELL_SIZE))
				var grid_y: int = int(round(world_pos.y / GRID_CELL_SIZE))
				var coords: Vector2i = Vector2i(grid_x, grid_y)
				
				if GameCore.get_grid_data().has(coords):
					GameCore.try_upgrade_shape(coords)
				
		InputState.PLACING_SHAPE:
			_attempt_place_shape(screen_pos)

func _handle_right_click() -> void:
	# Right click cancels placement
	if _current_state == InputState.PLACING_SHAPE:
		_set_input_state(InputState.IDLE)
		GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Placement Cancelled")
	else:
		# Debug: Enable placement mode for "Square" on right click for testing
		start_placement_mode("Square") # Keeping this for quick testing for now, can be removed later

# ------------------------------------------------------------------------------
# Logic
# ------------------------------------------------------------------------------

func start_placement_mode(shape_type: String) -> void:
	_selected_shape_type = shape_type
	_set_input_state(InputState.PLACING_SHAPE)
	GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Placing: " + shape_type)

func _attempt_place_shape(_screen_pos: Vector2) -> void:
	# Use Global/World position for Grid logic
	var world_pos: Vector2 = get_global_mouse_position()
	
	var grid_x: int = int(round(world_pos.x / GRID_CELL_SIZE))
	var grid_y: int = int(round(world_pos.y / GRID_CELL_SIZE))
	var coords: Vector2i = Vector2i(grid_x, grid_y)
	
	# Prevent placing in the 3x3 area around the Core (0,0)
	if abs(coords.x) <= CORE_EXCLUSION_RADIUS and abs(coords.y) <= CORE_EXCLUSION_RADIUS:
		GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Cannot place so close to the Core!")
		return
	
	# Cost Logic
	var cost: BigNumber = BigNumber.from_int(SHAPE_PLACEMENT_COST)
	
	var success: bool = GameCore.try_place_shape(coords, _selected_shape_type, cost)
	if success:
		pass # Continuous placement is nicer for testing

func _set_input_state(new_state: InputState) -> void:
	_current_state = new_state
	# TODO: Update Cursor visual
