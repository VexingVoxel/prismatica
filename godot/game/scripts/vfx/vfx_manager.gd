class_name VFXManagerClass extends Node

const CORE_CLICK_VFX_PATH = "res://game/scenes/vfx/core_click_vfx.tscn"
const CURRENCY_FLIGHT_VFX_PATH = "res://game/scenes/vfx/currency_flight_vfx.tscn"

var _core_click_vfx_packed_scene: PackedScene
var _currency_flight_vfx_packed_scene: PackedScene

# Dedicated containers for different types of VFX
@onready var _world_vfx_container: Node2D = get_tree().root.get_node("Main") # Assuming Main scene is direct child of root, or adjust path
@onready var _ui_vfx_container: CanvasLayer = get_tree().root.get_node("Main").get_node("HUD") # Assuming HUD has an FXLayer for UI VFX

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	_core_click_vfx_packed_scene = load(CORE_CLICK_VFX_PATH)
	if not _core_click_vfx_packed_scene:
		printerr("ERROR: Failed to load CoreClickVFX PackedScene at %s" % CORE_CLICK_VFX_PATH)
	
	_currency_flight_vfx_packed_scene = load(CURRENCY_FLIGHT_VFX_PATH)
	if not _currency_flight_vfx_packed_scene:
		printerr("ERROR: Failed to load CurrencyFlightVFX PackedScene at %s" % CURRENCY_FLIGHT_VFX_PATH)
	
	if not is_instance_valid(_world_vfx_container):
		printerr("ERROR: _world_vfx_container is not valid! Check path: /root/Main")
	if not is_instance_valid(_ui_vfx_container):
		printerr("ERROR: _ui_vfx_container is not valid! Check path: /root/Main/HUD")
	
	_connect_signals()
	_connect_vfx_event_bus_signals()

func _connect_signals() -> void:
	# Listen for gameplay events that need audio feedback
	GameplayEventBus.grid_shape_placed.connect(_on_grid_shape_placed)
	GameplayEventBus.core_clicked.connect(_on_core_clicked)

func _connect_vfx_event_bus_signals() -> void:
	VFXEventBus.play_core_click_vfx_requested.connect(_on_play_core_click_vfx_requested)
	VFXEventBus.play_currency_flight_vfx_requested.connect(_on_play_currency_flight_vfx_requested)

# ------------------------------------------------------------------------------
# Event Handlers (Now just emit signals on VFXEventBus)
# ------------------------------------------------------------------------------

func _on_grid_shape_placed(coords: Vector2i, _type: String) -> void:
	# 1. Visuals: Emit signal for CoreClickVFX to spawn and play
	var world_pos: Vector2 = Vector2(coords) * 64.0 
	VFXEventBus.play_core_click_vfx_requested.emit(world_pos, Color.CYAN)
	
	# 2. Audio: Play placement sound
	play_sfx_2d("sfx_place_shape", world_pos)

func _on_core_clicked(position: Vector2) -> void:
	# 1. Visuals: Emit signal for CoreClickVFX to spawn and play
	VFXEventBus.play_core_click_vfx_requested.emit(position, Color(4.0, 3.5, 1.0)) # HDR Gold for explosion

	# 2. Visuals: Emit signal for CurrencyFlightVFX to spawn and play
	# Convert world position to screen position for CurrencyFlightVFX
	var viewport = get_viewport()
	var transform = viewport.canvas_transform
	var start_screen_pos = transform * position
	var screen_size = viewport.get_visible_rect().size
	var target_screen_pos = Vector2(screen_size.x / 2.0, 60.0) # Top Center
	
	VFXEventBus.play_currency_flight_vfx_requested.emit(start_screen_pos, target_screen_pos, Color(1.0, 0.8, 0.0, 1.0))
	
	# 3. Audio: Play click sound
	play_sfx_2d("sfx_core_clicked", position) # Changed from "sfx_core_click" to "sfx_core_clicked" for consistency.

# ------------------------------------------------------------------------------
# New Instance Methods for VFX Spawning (Orchestrated by VFXManager)
# ------------------------------------------------------------------------------

func _on_play_core_click_vfx_requested(position: Vector2, color: Color) -> void:
	if not _core_click_vfx_packed_scene:
		printerr("ERROR: CoreClickVFX PackedScene not loaded!")
		return

	var vfx_instance: CoreClickVFX = _core_click_vfx_packed_scene.instantiate() as CoreClickVFX
	if not vfx_instance:
		printerr("ERROR: Failed to instance CoreClickVFX!")
		return
	
	if not is_instance_valid(_world_vfx_container):
		printerr("ERROR: _world_vfx_container became invalid during CoreClickVFX spawning!")
		vfx_instance.queue_free()
		return

	_world_vfx_container.add_child(vfx_instance)
	vfx_instance.play(position, color)
	vfx_instance.finished.connect(Callable(vfx_instance, "queue_free"), CONNECT_ONE_SHOT)

func _on_play_currency_flight_vfx_requested(start_screen_pos: Vector2, target_screen_pos: Vector2, color: Color) -> void:
	if not _currency_flight_vfx_packed_scene:
		printerr("ERROR: CurrencyFlightVFX PackedScene not loaded!")
		return

	var vfx_instance: CurrencyFlightVFX = _currency_flight_vfx_packed_scene.instantiate() as CurrencyFlightVFX
	if not vfx_instance:
		printerr("ERROR: Instantiate returned NULL or failed to cast for CurrencyFlightVFX. PackedScene: " + str(_currency_flight_vfx_packed_scene))
		var instance_debug = _currency_flight_vfx_packed_scene.instantiate()
		if instance_debug:
			printerr("ERROR: Debug: Node instantiated, but cast failed. Node type: " + instance_debug.get_class() + ", Script: " + str(instance_debug.get_script()))
			instance_debug.queue_free() # Clean up debug instance
		else:
			printerr("ERROR: Debug: instantiate() returned NULL for CurrencyFlightVFX.")
		return

	if not is_instance_valid(_ui_vfx_container):
		printerr("ERROR: _ui_vfx_container became invalid during CurrencyFlightVFX spawning!")
		vfx_instance.queue_free()
		return

	_ui_vfx_container.add_child(vfx_instance)
	vfx_instance.play(start_screen_pos, target_screen_pos, color)
	vfx_instance.finished.connect(Callable(vfx_instance, "queue_free"), CONNECT_ONE_SHOT)

# ------------------------------------------------------------------------------
# Public API (Audio Bridge)
# ------------------------------------------------------------------------------

## Plays a 2D sound effect by converting it to a 3D request for the Core AudioManager.
## [param sound_id]: The resource path or key for the sound.
## [param pos_2d]: The screen/world position in 2D.
func play_sfx_2d(sound_id: String, pos_2d: Vector2) -> void:
	# Convert 2D position to 3D (Z=0) as per v0.5.3 Spec
	var pos_3d: Vector3 = Vector3(pos_2d.x, pos_2d.y, 0.0)
	
	# Emit to CoreEventBus (Infrastructure)
	# Signature: sfx_play_requested(sound_id, position_3d, volume_db, pitch_scale)
	CoreEventBus.sfx_play_requested.emit(sound_id, pos_3d, 0.0, 1.0)
