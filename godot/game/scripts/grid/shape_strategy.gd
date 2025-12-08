class_name ShapeStrategy extends Resource

## ShapeStrategy
##
## Responsibility: Base class for all grid shape behaviors (production, bonuses, etc.).
## Uses the Strategy Pattern to allow GridCellData to delegate specific logic.

# ------------------------------------------------------------------------------
# Properties
# ------------------------------------------------------------------------------

@export var type: String = "base_shape" # Unique identifier for the shape

# ------------------------------------------------------------------------------
# Public API (Virtual Methods)
# ------------------------------------------------------------------------------

## Calculates the base production of this shape for a given level.
## To be overridden by concrete strategies.
func calculate_production(level: int) -> BigNumber:
	push_warning("ShapeStrategy: calculate_production() not implemented for type: %s" % type)
	return BigNumber.new(0.0, 0)

## Calculates additional production multiplier based on neighbors.
## To be overridden by concrete strategies.
func get_adjacency_multiplier(level: int, neighbors: Dictionary) -> float:
	return 1.0
