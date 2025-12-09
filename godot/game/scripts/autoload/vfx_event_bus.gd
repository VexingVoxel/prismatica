class_name VFXEventBusClass extends Node

signal play_core_click_vfx_requested(position: Vector2, color: Color)
signal play_currency_flight_vfx_requested(start_screen_pos: Vector2, target_screen_pos: Vector2, color: Color)

func _ready() -> void:
	pass # Connections are made by VFXManager
