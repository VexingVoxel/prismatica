class_name WindowManagerClass extends Node

## WindowManager
##
## Responsibility: Manages application window state, multi-monitor safety, 
## focus behavior, and persistent user settings.
## Acts as a Singleton (Autoload) to abstract DisplayServer complexity.

# ------------------------------------------------------------------------------
# Constants & Enums
# ------------------------------------------------------------------------------

const PATH_USER_CONFIG: String = "user://window_settings.json"
const PATH_DEFAULT_CONFIG: String = "res://_core/resources/default_window_settings.json"

## Maps to spec: 0=Windowed, 1=Borderless_Window, 2=Exclusive_Fullscreen
enum WindowMode {
	WINDOWED = 0,
	BORDERLESS_WINDOW = 1,
	EXCLUSIVE_FULLSCREEN = 2
}

# Default Fallback Configuration
const DEFAULT_CONFIG: Dictionary = {
	"window_mode": WindowMode.WINDOWED,
	"resolution_width": 1280,
	"resolution_height": 720,
	"monitor_index": 0,
	"refresh_rate_cap": 0,
	"vsync_mode": DisplayServer.VSYNC_ENABLED,
	"ui_scale": 1.0,
	"mute_on_focus_loss": true,
	"eco_mode_on_focus_loss": true,
	"saved_window_size": Vector2i(1280, 720) # Default to a common size
}

# ------------------------------------------------------------------------------
# State Variables
# ------------------------------------------------------------------------------

var _config: Dictionary = {}
var _was_mouse_captured: bool = false
var _saved_volume_db: float = 0.0
var _audio_tween: Tween
var _saved_window_size: Vector2i = Vector2i(0, 0) # Track size when maximized/fullscreen

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	# Prevent automatic quit so we can save state first
	get_tree().set_auto_accept_quit(false)
	
	_load_config()
	
	# Defer application to ensure OS window system is ready and to prevent
	# blocking the main thread during initial setup.
	call_deferred("_perform_sanity_check_and_apply")

func _perform_sanity_check_and_apply() -> void:
	_sanity_check_monitor()
	_apply_settings()

# ------------------------------------------------------------------------------
# Configuration Loading
# ------------------------------------------------------------------------------

func _load_config() -> void:
	var loaded_data: Dictionary = {}
	
	# 1. Attempt to load User Config
	if FileAccess.file_exists(PATH_USER_CONFIG):
		var file := FileAccess.open(PATH_USER_CONFIG, FileAccess.READ)
		if file:
			var json := JSON.new()
			var parse_result := json.parse(file.get_as_text())
			if parse_result == OK:
				loaded_data = json.data
			else:
				push_warning("WindowManager: Failed to parse user config. JSON Error: %s" % json.get_error_message())
		else:
			push_warning("WindowManager: Could not open user config file.")
	
	# 2. Attempt to load Default Config if user config failed or was empty
	if loaded_data.is_empty():
		if FileAccess.file_exists(PATH_DEFAULT_CONFIG):
			var file := FileAccess.open(PATH_DEFAULT_CONFIG, FileAccess.READ)
			if file:
				var json := JSON.new()
				var parse_result := json.parse(file.get_as_text())
				if parse_result == OK:
					loaded_data = json.data
				else:
					push_warning("WindowManager: Failed to parse default config.")
	
	# 3. Merge with hardcoded defaults to ensure all keys exist
	_config = DEFAULT_CONFIG.duplicate()
	_config.merge(loaded_data, true) # Overwrite defaults with loaded data

# ------------------------------------------------------------------------------
# Sanity Checks
# ------------------------------------------------------------------------------

func _sanity_check_monitor() -> void:
	var screen_count: int = DisplayServer.get_screen_count()
	var target_monitor: int = _config.get("monitor_index", 0)
	
	# Rule 1: Reset monitor index if invalid
	if target_monitor >= screen_count or target_monitor < 0:
		push_warning("WindowManager: Saved monitor index %d invalid (count: %d). Resetting to 0." % [target_monitor, screen_count])
		_config["monitor_index"] = 0
		target_monitor = 0
	
	# Rule 2: Off-screen check for Windowed mode
	var current_mode: int = _config.get("window_mode", WindowMode.WINDOWED)
	if current_mode == WindowMode.WINDOWED:
		# We can't easily know the 'saved' position without storing it explicitly in config.
		# Assuming the config *might* contain pos_x/pos_y if we extended it, 
		# but spec says "Calculate the saved window Rect2". 
		# Since standard config only has res_w/res_h, we rely on current window position
		# if the window has already been created, or we check against default centering.
		
		# Use current window info as proxy for 'saved' intent during startup check
		var win_pos: Vector2i = DisplayServer.window_get_position()
		var win_size: Vector2i = Vector2i(_config["resolution_width"], _config["resolution_height"])
		
		# If we strictly followed spec, we'd load pos from config. 
		# Assuming standard Godot behavior where we haven't moved it yet,
		# we check if the intended resolution fits on the screen properly.
		
		var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(target_monitor)
		var window_rect: Rect2i = Rect2i(win_pos, win_size)
		
		var intersection: Rect2i = window_rect.intersection(screen_rect)
		var intersection_area: float = float(intersection.size.x * intersection.size.y)
		var window_area: float = float(window_rect.size.x * window_rect.size.y)
		
		# Math: Check if < 20% of the window is visible
		if window_area > 0 and (intersection_area / window_area) < 0.2:
			push_warning("WindowManager: Window detected mostly off-screen. Forcing center.")
			center_window()

# ------------------------------------------------------------------------------
# Application Logic
# ------------------------------------------------------------------------------

func _apply_settings() -> void:
	# Monitor
	var mon_idx: int = _config["monitor_index"]
	# Determine current screen early if possible, but usually set_current_screen applies to window
	DisplayServer.window_set_current_screen(mon_idx)
	
	# Resolution & Mode
	var width: int = _config["resolution_width"]
	var height: int = _config["resolution_height"]
	var mode: int = _config["window_mode"]
	
	set_resolution(width, height)
	set_window_mode(mode)
	
	# VSync
	DisplayServer.window_set_vsync_mode(_config["vsync_mode"])
	
	# Refresh Rate
	var refresh_cap: int = _config["refresh_rate_cap"]
	if refresh_cap > 0:
		Engine.max_fps = refresh_cap
	else:
		Engine.max_fps = 0 # Unlimited/Vsync controlled
		
	# UI Scale
	set_ui_scale(_config["ui_scale"])

# ------------------------------------------------------------------------------
# Runtime Event Handling
# ------------------------------------------------------------------------------

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_handle_focus_lost()
		
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_handle_focus_gained()
		
		NOTIFICATION_WM_CLOSE_REQUEST:
			_handle_close_request()

func _handle_focus_lost() -> void:
	# Audio Muting
	if _config.get("mute_on_focus_loss", true):
		var master_idx: int = AudioServer.get_bus_index("Master")
		_saved_volume_db = AudioServer.get_bus_volume_db(master_idx)
		
		if _audio_tween: _audio_tween.kill()
		_audio_tween = create_tween()
		_audio_tween.tween_method(func(v: float): AudioServer.set_bus_volume_db(master_idx, v), _saved_volume_db, -80.0, 0.5)
	
	# Mouse Capture
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_was_mouse_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		_was_mouse_captured = false
		
	# Eco Mode
	if _config.get("eco_mode_on_focus_loss", true):
		Engine.max_fps = 15

func _handle_focus_gained() -> void:
	# Restore Audio
	if _config.get("mute_on_focus_loss", true):
		var master_idx: int = AudioServer.get_bus_index("Master")
		if _audio_tween: _audio_tween.kill()
		_audio_tween = create_tween()
		# Tween back to saved volume
		_audio_tween.tween_method(func(v: float): AudioServer.set_bus_volume_db(master_idx, v), -80.0, _saved_volume_db, 0.5)
	
	# Restore Mouse
	if _was_mouse_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	# Restore FPS
	var refresh_cap: int = _config.get("refresh_rate_cap", 0)
	Engine.max_fps = refresh_cap

func _handle_close_request() -> void:
	save_current_state()
	# Quit after saving
	get_tree().quit()

# ------------------------------------------------------------------------------
# Persistence
# ------------------------------------------------------------------------------

func save_current_state() -> void:
	# 1. Capture Data
	var current_screen: int = DisplayServer.window_get_current_screen()
	var current_ds_mode: int = DisplayServer.window_get_mode()
	var is_borderless: bool = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS)
	var is_maximized: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED # Check for maximized state
	
	# Map back to internal Enum
	var mode_enum: int = WindowMode.WINDOWED
	if current_ds_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or current_ds_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		mode_enum = WindowMode.EXCLUSIVE_FULLSCREEN
	elif is_borderless and is_maximized: # True Borderless is borderless and maximized
		mode_enum = WindowMode.BORDERLESS_WINDOW
	else: # Default to Windowed if none of the above
		mode_enum = WindowMode.WINDOWED
	
	_config["monitor_index"] = current_screen
	_config["window_mode"] = mode_enum
	
	# Capture size/pos if not fullscreen and not maximized (to preserve windowed preferences)
	if mode_enum == WindowMode.WINDOWED:
		var size: Vector2i = DisplayServer.window_get_size()
		_config["resolution_width"] = size.x
		_config["resolution_height"] = size.y
		_config["saved_window_size"] = size # Also save to saved_window_size for explicit record
	
	# If in borderless/maximized or fullscreen, the _saved_window_size should already be in _config if set via set_resolution
	# If not set by set_resolution (e.g. user manually resized windowed then went fullscreen),
	# we might want to capture the size *before* going fullscreen/maximized.
	# For now, adhering strictly to the spec which implies set_resolution handles _saved_window_size.
	
	# 2. Serialize
	var json_string: String = JSON.stringify(_config, "\t")
	var file := FileAccess.open(PATH_USER_CONFIG, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		push_warning("WindowManager: Failed to write config to %s" % PATH_USER_CONFIG)
# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

## Sets the application's window mode.
## - WindowMode.WINDOWED: Standard windowed mode, restores saved size if available.
## - WindowMode.BORDERLESS_WINDOW: "True Borderless" mode (Windowed + Borderless + Maximized).
## - WindowMode.EXCLUSIVE_FULLSCREEN: Sets exclusive fullscreen mode.
func set_window_mode(mode: int) -> void:
	_config["window_mode"] = mode
	
	match mode:
		WindowMode.WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			if _saved_window_size.x > 0 and _saved_window_size.y > 0:
				DisplayServer.window_set_size(_saved_window_size)
				center_window() # Recenter after setting size
		WindowMode.BORDERLESS_WINDOW:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		WindowMode.EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			# Borderless flag is irrelevant in exclusive fullscreen but good hygiene to clear
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		_:
			push_warning("WindowManager: Unknown window mode %d" % mode)

## Sets the application's window resolution.
## If called while in fullscreen or maximized mode, the resolution is saved
## for the next windowed session and not applied immediately.
func set_resolution(w: int, h: int) -> void:
	if w <= 0 or h <= 0: return
	
	_config["resolution_width"] = w
	_config["resolution_height"] = h
	
	var current_ds_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	
	if current_ds_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(Vector2i(w, h))
		center_window()
	else:
		# If in fullscreen or maximized, save this resolution for when we switch back to windowed
		_saved_window_size = Vector2i(w, h)
		_config["saved_window_size"] = _saved_window_size

## Moves the application window to the specified monitor index and centers it.
## Bounds check ensures the index is valid.
func set_monitor(index: int) -> void:
	var screen_count: int = DisplayServer.get_screen_count()
	if index >= 0 and index < screen_count:
		_config["monitor_index"] = index
		DisplayServer.window_set_current_screen(index)
		center_window()

## Sets the UI content scale factor for the window.
## A scale of 1.0 is the default. Useful for adjusting UI size on high-DPI displays.
func set_ui_scale(scale: float) -> void:
	_config["ui_scale"] = scale
	get_window().content_scale_factor = scale

## Centers the application window on its current screen.
func center_window() -> void:
	var screen_idx: int = DisplayServer.window_get_current_screen()
	var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_idx)
	var win_size: Vector2i = DisplayServer.window_get_size()
	
	var center_pos: Vector2i = screen_rect.position + (screen_rect.size / 2) - (win_size / 2)
	DisplayServer.window_set_position(center_pos)
