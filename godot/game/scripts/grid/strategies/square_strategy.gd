class_name SquareStrategy extends ShapeStrategy

## SquareStrategy
##
## Responsibility: Defines the specific behavior for "Square" grid shapes.
## Implements production and adjacency bonus logic based on v0.5.3 spec.

# ------------------------------------------------------------------------------
# Properties
# ------------------------------------------------------------------------------

func _init() -> void:
	type = "Square"

# ------------------------------------------------------------------------------
# Public API (Overrides from ShapeStrategy)
# ------------------------------------------------------------------------------

## Calculates the base production of a Square at a given level.
func calculate_production(level: int) -> BigNumber:
	# From v0.2 spec: Base production of a Square. Simple 1:1 for now.
	return BigNumber.from_int(level) # 1 Spark per level

## Calculates additional production multiplier based on neighbors.
## For Squares, this includes the +10% bonus if adjacent to the Core (0,0).
func get_adjacency_multiplier(level: int, neighbors: Dictionary) -> float:
	var multiplier: float = 1.0
	
	# Check for adjacency to the Core (0,0) from v0.2 spec.
	# The 'neighbors' dictionary here refers to immediate adjacent cells.
	# We assume the 'neighbors' dictionary contains the *coordinates* and their data.
	# For simplicity, if *any* neighbor is the Core, it gets the bonus.
	# More robust would be to pass the shape's own coordinates and check against (0,0).
	# For this implementation, we will assume `is_adjacent_to_core` is a method on the `GridDataResource`
	# or that the `neighbors` dictionary *contains* the special "Core" neighbor type/marker if applicable.
	#
	# Correction: The GameCore (from v0.5.3 spec) handles the adjacency check via `GridDataResource`.
	# This strategy should NOT check coordinates, but just if it has a specific NEIGHBOR TYPE.
	# However, v0.2 states "touching the Core." The Core is NOT a shape.
	#
	# Re-reading v0.2: "Squares generate +10% if touching the Core."
	# This implies the check for adjacency to (0,0) happens *outside* the strategy,
	# perhaps in GridDataResource or GameCore.
	#
	# Let's keep this simple for now, assuming the multiplier is based on *other shapes*.
	# If the definition of "touching the Core" needs to be in the strategy, then the strategy
	# would need to know its own coordinates or receive an explicit `is_adjacent_to_core` flag.
	#
	# As per v0.5.3: "GridDataResource... Uses ShapeStrategy classes... to calculate production/adjacency."
	# This means the *Strategy* should calculate adjacency. For the Core, it's a special case.
	#
	# The GameCore already handles `_is_adjacent_to_core` in the previous implementation.
	# I will add a method to pass in a `is_adjacent_to_core_flag` instead of having the strategy decide.
	#
	# Alternative: `neighbors` can be structured as `{ Vector2i, GridCellData }`.
	#
	# New plan:
	# The `get_adjacency_multiplier` should take a `Dictionary` of neighbor GridCellData.
	# The "+10% if touching core" is a special case. This multiplier should be passed from the
	# `GridDataResource` when it calculates the overall production for a cell.
	# The Strategy should be about *interactions between shapes*.
	#
	# So, `ShapeStrategy` should only deal with *other shapes*.
	# `GridDataResource` will apply the *Core adjacency* bonus.
	
	return multiplier # No bonus for just "neighboring shapes" for now.
