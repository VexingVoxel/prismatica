class_name GameCoreClass extends Node

## GameCore
##
## Responsibility: The Conductor. Manages the "Big Math" state (Economy)
## and the main game loop (Tick).
##
## Execution Order: Must run AFTER GameplayEventBus.

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------

const TICK_RATE: float = 0.1 # 10Hz Logic Tick
const OVERLOAD_DURATION: float = 5.0
const OVERLOAD_COOLDOWN: float = 15.0
const OVERLOAD_MULTIPLIER: float = 2.0
const PRESTIGE_BONUS_PER_LIGHT: float = 0.1 # Example: +10% production per Light
const PRESTIGE_THRESHOLD_LIFETIME_SPARKS: int = 1000 # Lifetime sparks needed to gain 1 Light (placeholder)
const CLICK_BASE_VALUE: int = 1
const UPGRADE_COST_SCALING_FACTOR: int = 50 # Base cost per level for upgrading a shape

# ------------------------------------------------------------------------------
# State
# ------------------------------------------------------------------------------

var _sparks: BigNumber
var _lifetime_sparks: BigNumber # Track for prestige
var _light: BigNumber # Prestige Currency
var _grid_data_resource: GridDataResource # The grid's data
var _tick_timer: Timer
var _total_ticks: int = 0

# Overload State
var _is_overloaded: bool = false
var _overload_time_left: float = 0.0
var _overload_cooldown_left: float = 0.0

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	_init_economy()
	_setup_timer()

func _process(delta: float) -> void:
	_handle_overload_timers(delta)

func _init_economy() -> void:
	_sparks = BigNumber.new(0.0, 0)
	_lifetime_sparks = BigNumber.new(0.0, 0)
	_light = BigNumber.new(0.0, 0)
	_grid_data_resource = GridDataResource.new()

func _setup_timer() -> void:
	_tick_timer = Timer.new()
	_tick_timer.name = "MathTickTimer"
	_tick_timer.wait_time = TICK_RATE
	_tick_timer.autostart = true
	_tick_timer.one_shot = false
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)

# ------------------------------------------------------------------------------
# Game Loop
# ------------------------------------------------------------------------------

func _on_tick() -> void:
	_total_ticks += 1
	
	var passive_income: BigNumber = _grid_data_resource.get_total_production()
	
	# Apply Prestige Bonus (+10% per Light)
	if not _light.is_zero():
		var prestige_mult: BigNumber = BigNumber.from_float(1.0).plus(_light.multiply(BigNumber.from_float(PRESTIGE_BONUS_PER_LIGHT)))
		passive_income = passive_income.multiply(prestige_mult)
	
	if _is_overloaded:
		passive_income = passive_income.multiply(BigNumber.from_float(OVERLOAD_MULTIPLIER))
	
	_add_sparks(passive_income)
	
	GameplayEventBus.game_tick.emit(_total_ticks)

func _handle_overload_timers(delta: float) -> void:
	var state_changed: bool = false
	
	# Active Duration
	if _is_overloaded:
		_overload_time_left -= delta
		if _overload_time_left <= 0.0:
			_is_overloaded = false
			_overload_cooldown_left = OVERLOAD_COOLDOWN
			GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Overload Ended")
			state_changed = true
	
	# Cooldown
	if not _is_overloaded and _overload_cooldown_left > 0.0:
		_overload_cooldown_left -= delta
		if _overload_cooldown_left < 0.0:
			_overload_cooldown_left = 0.0
			GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Overload Ready!")
			state_changed = true

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

## Returns the amount of Light the player would gain if they prestige now.
## Formula: (Lifetime Sparks / 1e6) ^ 0.5 (Placeholder)
func get_prestige_potential() -> BigNumber:
	# Simple placeholder logic: 1 Light for every 1000 lifetime sparks
	# In real implementation, use a proper log/sqrt formula.
	# For POC: plain division.
	var threshold: BigNumber = BigNumber.from_int(PRESTIGE_THRESHOLD_LIFETIME_SPARKS)
	if _lifetime_sparks.is_less_than(threshold):
		return BigNumber.new(0.0, 0)
	
	# This is a hacky division for BigNumber POC. 
	# Assuming BigNumber doesn't have full division yet, we estimate.
	# TODO: Implement BigNumber division.
	# For now, let's just say 1 Light per 1000 sparks fixed.
	return BigNumber.from_int(1) # Stub

## Resets the game to gain Light.
func prestige() -> void:
	var potential: BigNumber = get_prestige_potential()
	if potential.is_zero():
		GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Not enough energy to Ascend!")
		return
		
	_light = _light.plus(potential)
	_sparks = BigNumber.new(0.0, 0)
	_lifetime_sparks = BigNumber.new(0.0, 0) # Usually lifetime resets for the *next* prestige calculation, or it's cumulative? 
	# Usually cumulative, but for simple formula (Current Run / X), we reset.
	
	_grid_data_resource = GridDataResource.new() # Wipe grid
	_is_overloaded = false
	
	GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "ASCENDED! Light Gained: " + potential.to_formatted_string())
	GameplayEventBus.resource_changed.emit("light", _light.duplicate_val(), _light.to_formatted_string())
	GameplayEventBus.resource_changed.emit("sparks", _sparks.duplicate_val(), "0")
	
	# Signal grid wipe to visuals
	# GridView needs to know to clear visuals.
	# We can just reload the scene or emit a special signal.
	# Let's emit `grid_adjacency_updated` with empty list? No.
	# Emitting `grid_shape_placed` for every cleared cell is slow.
	# Let's rely on `grid_adjacency_updated` or add a `grid_cleared` signal.
	# For POC, we'll just reload the scene via the Controller or let GridView poll.
	get_tree().reload_current_scene() # Safest for POC reset

# ... [Existing API methods] ...

# ------------------------------------------------------------------------------
# Internal Helpers
# ------------------------------------------------------------------------------

func _add_sparks(amount: BigNumber) -> void:
	if amount.is_zero():
		return
		
	_sparks = _sparks.plus(amount)
	_lifetime_sparks = _lifetime_sparks.plus(amount)
	
	# Notify Listeners (UI, Audio, VFX)
	GameplayEventBus.resource_changed.emit(
		"sparks", 
		_sparks.duplicate_val(), 
		_sparks.to_formatted_string()
	)

func activate_overload() -> bool:
	if _is_overloaded:
		return false
	
	if _overload_cooldown_left > 0.0:
		GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Overload on Cooldown!")
		return false
		
	_is_overloaded = true
	_overload_time_left = OVERLOAD_DURATION
	GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "OVERLOAD ACTIVATED!")
	return true

func get_overload_state() -> Dictionary:
	return {
		"active": _is_overloaded,
		"time_left": _overload_time_left,
		"cooldown_left": _overload_cooldown_left,
		"duration": OVERLOAD_DURATION,
		"cooldown_max": OVERLOAD_COOLDOWN
	}

## Called by Input Controller when player clicks the Core.
func click_core(screen_pos: Vector2) -> void:
	# 1. Logic: Add Resources
	var click_val: BigNumber = BigNumber.from_int(CLICK_BASE_VALUE)
	
	if _is_overloaded:
		click_val = click_val.multiply(BigNumber.from_float(OVERLOAD_MULTIPLIER))
		
	_add_sparks(click_val)
	
	# 2. Feedback: Emit Signal for VFX/Juice
	GameplayEventBus.core_clicked.emit(screen_pos)

## Attempts to place a shape on the grid. Handles cost.
func try_place_shape(coords: Vector2i, type: String, cost: BigNumber) -> bool:
	if _grid_data_resource.is_occupied(coords):
		GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Cell is occupied!")
		return false
		
	if cost.is_greater_than(_sparks):
		GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Not enough Sparks!")
		return false
		
	# Deduct cost
	_sparks = _sparks.minus(cost)
	
	# Place the shape in the data resource
	var placed: bool = _grid_data_resource.place_shape(coords, type)
	if placed:
		GameplayEventBus.resource_changed.emit(
			"sparks", 
			_sparks.duplicate_val(), 
			_sparks.to_formatted_string()
		)
		GameplayEventBus.grid_shape_placed.emit(coords, type)
		return true
	
	return false

## Attempts to upgrade the shape at the given coordinates.
func try_upgrade_shape(coords: Vector2i) -> bool:
	if not _grid_data_resource.is_occupied(coords):
		return false
		
	var cell: Dictionary = _grid_data_resource.get_cell_data(coords)
	var current_level: int = cell.get("level", 1)
	var cost: BigNumber = BigNumber.from_int(current_level * UPGRADE_COST_SCALING_FACTOR) # Simple linear cost scaling
	
	if cost.is_greater_than(_sparks):
		GameplayEventBus.resource_changed.emit("feedback_message", BigNumber.new(0,0), "Not enough Sparks to upgrade!")
		return false
		
	_sparks = _sparks.minus(cost)
	
	var upgraded: bool = _grid_data_resource.upgrade_shape(coords)
	if upgraded:
		GameplayEventBus.resource_changed.emit(
			"sparks", 
			_sparks.duplicate_val(), 
			_sparks.to_formatted_string()
		)
		# Emit signal for Visuals (Liquid Fill)
		GameplayEventBus.emit_signal("grid_shape_leveled", coords, current_level + 1, false) 
		
		return true
		
	return false

func get_sparks() -> BigNumber:
	return _sparks.duplicate_val()

func set_sparks(amount: BigNumber) -> void:
	_sparks = amount.duplicate_val()
	GameplayEventBus.resource_changed.emit(
		"sparks", 
		_sparks.duplicate_val(), 
		_sparks.to_formatted_string()
	)

func get_light() -> BigNumber:
	return _light.duplicate_val()

func set_light(amount: BigNumber) -> void:
	_light = amount.duplicate_val()
	# Emit resource_changed for light if needed for UI

func get_grid_data() -> Dictionary:
	return _grid_data_resource.grid_cells.duplicate() # Return a copy of the raw grid data

func set_grid_data(data: Dictionary) -> void:
	_grid_data_resource.grid_cells = data.duplicate()
	# Emit signal for GridView to re-draw if needed
