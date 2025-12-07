class_name InputManagerClass extends Node

## InputManager
##
## Responsibility: Manages the runtime state of the InputMap. Handles action discovery, 
## remapping, saving/loading custom bindings, and restoring defaults.
## Scope: Core Infrastructure. Strictly agnostic.

# ------------------------------------------------------------------------------
# Constants & Signals
# ------------------------------------------------------------------------------

const PATH_INPUT_CONFIG: String = "user://input_profiles.json"

## Emitted whenever a remap is applied or defaults are restored.
signal input_profile_changed()

## Emitted if input source changes are detected (Placeholder for future implementation).
signal input_scheme_changed(device_type: int)

# ------------------------------------------------------------------------------
# State Variables
# ------------------------------------------------------------------------------

## List of actions that can be remapped (excludes 'ui_' and 'godot_').
var _remappable_actions: Array[StringName] = []

## Backup of the original project settings for restoration.
var _default_input_map: Dictionary = {}

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	_discover_actions()
	_load_profile()

func _discover_actions() -> void:
	var all_actions: Array[StringName] = InputMap.get_actions()
	
	for action in all_actions:
		var action_str: String = str(action)
		
		# Filter out built-in UI and editor actions
		if action_str.begins_with("ui_") or action_str.begins_with("godot_"):
			continue
			
		_remappable_actions.append(action)
		
		# Backup default configuration
		# We duplicate the array to ensure we have a value copy, not a reference
		_default_input_map[action] = InputMap.action_get_events(action).duplicate()

# ------------------------------------------------------------------------------
# Persistence
# ------------------------------------------------------------------------------

func _load_profile() -> void:
	if not FileAccess.file_exists(PATH_INPUT_CONFIG):
		return # Keep defaults if no save file exists

	var file := FileAccess.open(PATH_INPUT_CONFIG, FileAccess.READ)
	if not file:
		push_warning("InputManager: Failed to open config file.")
		return

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	
	if parse_result != OK:
		push_warning("InputManager: JSON Parse Error: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data
	_apply_profile(data)

func _apply_profile(data: Dictionary) -> void:
	for action_str in data.keys():
		if not InputMap.has_action(action_str):
			continue
			
		var action_name: StringName = StringName(action_str)
		
		# Only modify remappable actions
		if not _remappable_actions.has(action_name):
			continue

		# Clear existing events for this action to apply saved ones clean
		InputMap.action_erase_events(action_name)
		
		var events_data: Array = data[action_str]
		for event_dict in events_data:
			var event: InputEvent = _deserialize_event(event_dict)
			if event:
				InputMap.action_add_event(action_name, event)
	
	input_profile_changed.emit()

func save_profile() -> void:
	var data: Dictionary = {}
	
	for action in _remappable_actions:
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		var serialized_events: Array = []
		
		for event in events:
			var serialized: Dictionary = _serialize_event(event)
			if not serialized.is_empty():
				serialized_events.append(serialized)
		
		if not serialized_events.is_empty():
			data[str(action)] = serialized_events
			
	var json_string: String = JSON.stringify(data, "\t")
	var file := FileAccess.open(PATH_INPUT_CONFIG, FileAccess.WRITE)
	
	if file:
		file.store_string(json_string)
		file.close()
	else:
		push_warning("InputManager: Failed to save config to %s" % PATH_INPUT_CONFIG)

# ------------------------------------------------------------------------------
# Serialization Helpers
# ------------------------------------------------------------------------------

func _serialize_event(event: InputEvent) -> Dictionary:
	var dict: Dictionary = {}
	
	if event is InputEventKey:
		dict["type"] = "key"
		dict["keycode"] = event.keycode
		dict["physical_keycode"] = event.physical_keycode
		dict["unicode"] = event.unicode
		dict["pressed"] = event.pressed
		dict["echo"] = event.echo
	elif event is InputEventMouseButton:
		dict["type"] = "mouse_button"
		dict["button_index"] = event.button_index
		dict["pressed"] = event.pressed
		dict["double_click"] = event.double_click
	elif event is InputEventJoypadButton:
		dict["type"] = "joy_button"
		dict["button_index"] = event.button_index
		dict["pressure"] = event.pressure
		dict["pressed"] = event.pressed
	elif event is InputEventJoypadMotion:
		dict["type"] = "joy_motion"
		dict["axis"] = event.axis
		dict["axis_value"] = event.axis_value
	
	return dict

func _deserialize_event(dict: Dictionary) -> InputEvent:
	if not dict.has("type"):
		return null
		
	var type: String = dict["type"]
	
	match type:
		"key":
			var event := InputEventKey.new()
			event.keycode = dict.get("keycode", 0)
			event.physical_keycode = dict.get("physical_keycode", 0)
			event.unicode = dict.get("unicode", 0)
			event.pressed = dict.get("pressed", false)
			event.echo = dict.get("echo", false)
			return event
		"mouse_button":
			var event := InputEventMouseButton.new()
			event.button_index = dict.get("button_index", 0)
			event.pressed = dict.get("pressed", false)
			event.double_click = dict.get("double_click", false)
			return event
		"joy_button":
			var event := InputEventJoypadButton.new()
			event.button_index = dict.get("button_index", 0)
			event.pressure = dict.get("pressure", 0.0)
			event.pressed = dict.get("pressed", false)
			return event
		"joy_motion":
			var event := InputEventJoypadMotion.new()
			event.axis = dict.get("axis", 0)
			event.axis_value = dict.get("axis_value", 0.0)
			return event
	
	return null

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

## Returns the list of discovered actions that are safe to remap.
func get_remappable_actions() -> Array[StringName]:
	return _remappable_actions

## Applies a new InputEvent to an action, saves the profile, and notifies listeners.
## Handles replacement logic: it removes existing events of the same 'type' (Keyboard/Mouse vs Joypad) 
## before adding the new one, preserving hybrid bindings.
func remap_action(action: StringName, new_event: InputEvent) -> void:
	if not _remappable_actions.has(action):
		push_warning("InputManager: Cannot remap unknown or protected action '%s'" % action)
		return
		
	# 1. Identify Event Type Group
	var is_keyboard_mouse: bool = (new_event is InputEventKey) or (new_event is InputEventMouse)
	var is_joypad: bool = (new_event is InputEventJoypadButton) or (new_event is InputEventJoypadMotion)
	
	# 2. Get current events and filter out conflicting types
	var current_events: Array[InputEvent] = InputMap.action_get_events(action)
	var events_to_keep: Array[InputEvent] = []
	
	for event in current_events:
		var event_is_km: bool = (event is InputEventKey) or (event is InputEventMouse)
		var event_is_joy: bool = (event is InputEventJoypadButton) or (event is InputEventJoypadMotion)
		
		# If new event is KM, keep Joy. If new is Joy, keep KM.
		if is_keyboard_mouse and event_is_joy:
			events_to_keep.append(event)
		elif is_joypad and event_is_km:
			events_to_keep.append(event)
		# Else: it matches the type we are replacing, so we drop it (effectively replacing it)

	# 3. Apply changes
	InputMap.action_erase_events(action)
	
	# Add back non-conflicting events
	for event in events_to_keep:
		InputMap.action_add_event(action, event)
		
	# Add the new event
	InputMap.action_add_event(action, new_event)
	
	# 4. Save and Notify
	save_profile()
	input_profile_changed.emit()

## Restores all remappable actions to their project settings defaults.
func reset_to_defaults() -> void:
	for action in _remappable_actions:
		InputMap.action_erase_events(action)
		
		if _default_input_map.has(action):
			var default_events: Array = _default_input_map[action]
			for event in default_events:
				InputMap.action_add_event(action, event)
				
	# Overwrite the save file with defaults (or delete it? Strategy: Save defaults to explicit file)
	save_profile()
	input_profile_changed.emit()

## Helper for UI tooltips. Returns a human-readable string for the action's primary key.
func get_action_key_string(action: StringName) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
		elif event is InputEventMouseButton:
			return "Mouse Btn " + str(event.button_index)
		elif event is InputEventJoypadButton:
			return "Joy Btn " + str(event.button_index)
		
	return "Unbound"
