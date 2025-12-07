class_name SaveManagerClass extends Node

## SaveManager
##
## Responsibility: Handles raw File I/O of game data using atomic writes to prevent corruption.
## Manages save slots and metadata. Agnostic to specific game data schema.

# ------------------------------------------------------------------------------
# Constants & Signals
# ------------------------------------------------------------------------------

const SAVE_DIR: String = "user://saves/"

## Emitted when a save operation begins.
signal save_started(slot_id: String)

## Emitted when a save operation completes successfully.
signal save_completed(slot_id: String, success: bool)

## Emitted when a save operation fails (e.g., I/O error).
signal save_failed(slot_id: String, reason: String)

## Emitted when a save file exists but cannot be parsed (JSON error).
signal save_corrupted(slot_id: String)

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	_ensure_save_directory()

func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		var err := DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		if err != OK:
			push_error("SaveManager: Failed to create save directory at %s. Error: %d" % [SAVE_DIR, err])

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

## Asynchronously saves game content and metadata to the specified slot using atomic writes.
## [param slot_id]: Unique identifier for the save (filename without extension).
## [param content]: The dictionary containing the game state.
## [param metadata]: Optional extra info (thumbnails, description). Timestamp/Version added automatically.
func save_game(slot_id: String, content: Dictionary, metadata: Dictionary = {}) -> void:
	save_started.emit(slot_id)
	
	# 1. Prepare Metadata
	var full_metadata: Dictionary = metadata.duplicate()
	full_metadata["timestamp"] = Time.get_unix_time_from_system()
	full_metadata["iso_time"] = Time.get_datetime_string_from_system()
	full_metadata["version"] = ProjectSettings.get_setting("application/config/version", "1.0.0")
	
	# 2. Write Content (Atomic)
	var content_path: String = SAVE_DIR + slot_id + ".json"
	if not _atomic_write(content_path, content):
		save_failed.emit(slot_id, "Failed to write content file.")
		return
		
	# 3. Write Metadata (Atomic)
	var meta_path: String = SAVE_DIR + slot_id + ".meta"
	if not _atomic_write(meta_path, full_metadata):
		save_failed.emit(slot_id, "Failed to write metadata file.")
		return
	
	save_completed.emit(slot_id, true)

## Loads and returns the game content for a specific slot.
## Returns an empty Dictionary if the file is missing or corrupted.
func load_game(slot_id: String) -> Dictionary:
	var path: String = SAVE_DIR + slot_id + ".json"
	
	if not FileAccess.file_exists(path):
		push_warning("SaveManager: Save file not found: %s" % path)
		return {}
		
	var data: Dictionary = _load_json_file(path)
	if data.is_empty():
		save_corrupted.emit(slot_id)
		return {}
		
	return data

## Loads the metadata for a specific slot.
func get_save_metadata(slot_id: String) -> Dictionary:
	var path: String = SAVE_DIR + slot_id + ".meta"
	if not FileAccess.file_exists(path):
		return {}
	return _load_json_file(path)

## Checks if a save slot exists (specifically the content file).
func save_exists(slot_id: String) -> bool:
	return FileAccess.file_exists(SAVE_DIR + slot_id + ".json")

## Deletes the save content and metadata for a specific slot.
func delete_save(slot_id: String) -> void:
	var paths: Array[String] = [
		SAVE_DIR + slot_id + ".json",
		SAVE_DIR + slot_id + ".meta"
	]
	
	for path in paths:
		if FileAccess.file_exists(path):
			var err := DirAccess.remove_absolute(path)
			if err != OK:
				push_error("SaveManager: Failed to delete %s. Error: %d" % [path, err])

## Scans the save directory and returns a list of all valid save metadata.
## The returned array is sorted by timestamp (newest first).
func get_all_save_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var dir := DirAccess.open(SAVE_DIR)
	
	if not dir:
		return []
		
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".meta"):
			var slot_id: String = file_name.get_basename() # Strips extension
			
			# Verify corresponding content file exists
			if save_exists(slot_id):
				var meta: Dictionary = get_save_metadata(slot_id)
				meta["slot_id"] = slot_id # Inject ID for UI convenience
				slots.append(meta)
				
		file_name = dir.get_next()
		
	# Sort by timestamp descending (newest first)
	slots.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))
	
	return slots

# ------------------------------------------------------------------------------
# Internal Helpers
# ------------------------------------------------------------------------------

## Performs an atomic write: Write to .tmp -> Rename to target.
func _atomic_write(target_path: String, data: Dictionary) -> bool:
	var tmp_path: String = target_path + ".tmp"
	
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Could not create temp file: %s" % tmp_path)
		return false
		
	var json_string: String = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close() # Ensure flush before rename
	
	# Rename is atomic on most POSIX systems
	var err := DirAccess.rename_absolute(tmp_path, target_path)
	if err != OK:
		push_error("SaveManager: Failed to rename %s to %s. Error: %d" % [tmp_path, target_path, err])
		return false
		
	return true

## Helper to read and parse a JSON file.
func _load_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
		
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	
	if parse_result != OK:
		push_error("SaveManager: Parse Error in %s: %s" % [path, json.get_error_message()])
		return {}
		
	if not (json.data is Dictionary):
		push_error("SaveManager: File %s did not contain a Dictionary." % path)
		return {}
		
	return json.data
