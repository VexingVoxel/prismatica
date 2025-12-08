class_name GameplayEventBusClass extends Node

## GameplayEventBus
##
## Responsibility: Handles high-frequency game logic events.
## Separates Game Logic from Core Infrastructure.

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------

## The heartbeat of the game. Shaders and economy sync to this.
signal game_tick(tick_count: int)

## Emitted when the primary currency (Sparks) changes.
## Used by UI (Label) and Visuals (Core Glow).
signal resource_changed(type: String, amount_bignum: BigNumber, formatted_str: String)

## Emitted when a structure is successfully placed on the grid.
signal grid_shape_placed(coords: Vector2i, type: String)
signal grid_shape_leveled(coords: Vector2i, new_level: int, is_max: bool)
signal grid_adjacency_updated(coords_list: Array[Vector2i])
signal core_clicked(position: Vector2)
