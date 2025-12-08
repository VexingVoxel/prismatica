class_name GridDataResource extends Resource

## GridDataResource
##
## Responsibility: Holds the authoritative state of the game grid.
## Manages placing shapes, and calculating production based on strategies.
## Uses Strategy Pattern for shape-specific logic.

# ------------------------------------------------------------------------------
# Properties
# ------------------------------------------------------------------------------

var grid_cells: Dictionary = {} # Stores { Vector2i: GridCellData }
var _shape_strategies: Dictionary = {} # Stores { type_string: ShapeStrategy }

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _init() -> void:
	# Register strategies
	_shape_strategies["Square"] = SquareStrategy.new()
	# TODO: Add other shape strategies here as they are implemented

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

## Places a shape at the given coordinates. Returns true on success, false if occupied.
func place_shape(coords: Vector2i, type: String) -> bool:
	if grid_cells.has(coords):
		return false
	
	if not _shape_strategies.has(type):
		push_error("GridDataResource: Attempted to place unknown shape type '%s'" % type)
		return false
		
	grid_cells[coords] = {
		"type": type,
		"level": 1 # All shapes start at level 1
	}
	
	return true

## Upgrades the shape at the given coordinates. Returns true on success.
func upgrade_shape(coords: Vector2i) -> bool:
	if not grid_cells.has(coords):
		return false
		
	var cell: Dictionary = grid_cells[coords]
	cell["level"] = cell.get("level", 1) + 1
	return true

## Checks if a cell is occupied.
func is_occupied(coords: Vector2i) -> bool:
	return grid_cells.has(coords)

## Returns the GridCellData for a given coordinate.
func get_cell_data(coords: Vector2i) -> Dictionary:
	return grid_cells.get(coords, {})

## Calculates the total spark production from all shapes on the grid.
func get_total_production() -> BigNumber:
	var total_production: BigNumber = BigNumber.from_int(0)
	
	for coords in grid_cells:
		var cell_data: Dictionary = grid_cells[coords]
		var type: String = cell_data.get("type", "")
		var level: int = cell_data.get("level", 1)
		
		var strategy: ShapeStrategy = _shape_strategies.get(type)
		if not strategy:
			push_warning("GridDataResource: No strategy found for type '%s' at %s" % [type, coords])
			continue
			
		var base_prod: BigNumber = strategy.calculate_production(level)
		var effective_prod: BigNumber = base_prod
		
		# Apply Adjacency Bonus (Core) - v0.2 spec
		if _is_adjacent_to_core(coords):
			var core_adj_multiplier: float = 1.1 # +10%
			effective_prod = effective_prod.multiply(BigNumber.from_float(core_adj_multiplier))
			
		# Apply Adjacency Bonus (Shape-to-Shape) - Future expansion via strategy.get_adjacency_multiplier
		# For now, SquareStrategy returns 1.0, so this has no effect.
		var neighbors_data: Dictionary = _get_neighbor_data(coords)
		var shape_adj_multiplier: float = strategy.get_adjacency_multiplier(level, neighbors_data)
		effective_prod = effective_prod.multiply(BigNumber.from_float(shape_adj_multiplier))
		
		total_production = total_production.plus(effective_prod)
		
	return total_production

# ------------------------------------------------------------------------------
# Internal Helpers
# ------------------------------------------------------------------------------

func _is_adjacent_to_core(coords: Vector2i) -> bool:
	# Core is at (0,0)
	var diff: Vector2i = coords.abs()
	# Check Manhattan distance of 1 (Up, Down, Left, Right)
	return (diff.x + diff.y) == 1

func _get_neighbor_data(coords: Vector2i) -> Dictionary:
	var neighbors_data: Dictionary = {}
	var directions: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)
	]
	
	for dir in directions:
		var neighbor_coords: Vector2i = coords + dir
		if grid_cells.has(neighbor_coords):
			neighbors_data[neighbor_coords] = grid_cells[neighbor_coords]
			
	return neighbors_data
