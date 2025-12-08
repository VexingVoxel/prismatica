class_name GamePersistenceBridgeClass extends Node

## GamePersistenceBridge
##
## Responsibility: Translates between Game Data (BigNumber, GridDataResource)
## and the Core SaveManager for persistence.
## Handles serialization/deserialization details like BigNumber to String conversion.

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------

const AUTO_SAVE_INTERVAL: float = 60.0 # Save every 60 seconds
const GAME_SAVE_SLOT: String = "game_slot_0"

# ------------------------------------------------------------------------------
# State
# ------------------------------------------------------------------------------

var _auto_save_timer: Timer

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	_setup_auto_save_timer()
	_load_game_state() # Attempt to load on startup

func _setup_auto_save_timer() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_save_timer.autostart = true
	_auto_save_timer.one_shot = false
	_auto_save_timer.timeout.connect(func(): save_game_state(GAME_SAVE_SLOT))
	add_child(_auto_save_timer)

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

## Saves the current game state to the specified slot.
func save_game_state(slot_id: String) -> void:
	# 1. Collect data from GameCore and GridDataResource
	var game_data: Dictionary = {}
	
	# Serialize BigNumbers to String (as per v0.5.3 spec)
	game_data["sparks"] = GameCore.get_sparks().to_formatted_string("scientific")
	game_data["light"] = GameCore.get_light().to_formatted_string("scientific") # Assuming GameCore will have get_light()
	
	# Serialize GridDataResource
	game_data["grid_cells"] = _serialize_grid_cells(GameCore.get_grid_data())
	
	# 2. Pass to Core SaveManager
	# SaveManager is an Autoload from _core/autoload/save_manager.gd
	SaveManager.save_game(slot_id, game_data)
	
	GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Game Saved!")
	print("Game saved to slot: %s" % slot_id)

## Loads game state from the specified slot.
func _load_game_state() -> void:
	if not SaveManager.save_exists(GAME_SAVE_SLOT):
		print("No save game found for slot: %s" % GAME_SAVE_SLOT)
		return
		
	var loaded_data: Dictionary = SaveManager.load_game(GAME_SAVE_SLOT)
	if loaded_data.is_empty():
		GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Failed to load game!")
		return
	
	# Deserialize BigNumbers
	GameCore.set_sparks(_bignum_from_string(loaded_data.get("sparks", "0e0")))
	GameCore.set_light(_bignum_from_string(loaded_data.get("light", "0e0")))
	
	# Deserialize GridDataResource
	GameCore.set_grid_data(_deserialize_grid_cells(loaded_data.get("grid_cells", {})))
	
	GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Game Loaded!")
	print("Game loaded from slot: %s" % GAME_SAVE_SLOT)

# ------------------------------------------------------------------------------
# Internal Helpers (Serialization)
# ------------------------------------------------------------------------------

func _serialize_grid_cells(grid_cells: Dictionary) -> Array:
	var serialized_array: Array = []
	for coords in grid_cells:
		var cell_data: Dictionary = grid_cells[coords]
		serialized_array.append({
			"x": coords.x,
			"y": coords.y,
			"type": cell_data.get("type"),
			"level": cell_data.get("level")
		})
	return serialized_array

func _deserialize_grid_cells(serialized_array: Array) -> Dictionary:
	var grid_cells: Dictionary = {}
	for entry in serialized_array:
		var coords: Vector2i = Vector2i(entry.get("x", 0), entry.get("y", 0))
		grid_cells[coords] = {
			"type": entry.get("type"),
			"level": entry.get("level")
		}
	return grid_cells

func _bignum_from_string(s: String) -> BigNumber:
	var parts: PackedStringArray = s.split("e")
	if parts.size() == 2:
		var mantissa: float = parts[0].to_float()
		var exponent: int = parts[1].to_int()
		return BigNumber.new(mantissa, exponent)
	return BigNumber.new(0.0, 0)
