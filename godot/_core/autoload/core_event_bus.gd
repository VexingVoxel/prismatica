class_name CoreEventBusClass extends Node

## CoreEventBus
##
## Responsibility: Acts as the "Tier 1" Infrastructure Bus. Handles application lifecycle, 
## global I/O requests (Audio/Save), and critical system state.
## Scope: STRICTLY Game-Agnostic. No gameplay logic allowed.

# ------------------------------------------------------------------------------
# Constants & Enums
# ------------------------------------------------------------------------------

## Sentinel value for non-positional (UI/2D) audio requests.
const AUDIO_3D_NULL: Vector3 = Vector3(INF, INF, INF)

## Types of toast notifications.
enum ToastType {
	INFO = 0,
	WARNING = 1,
	ERROR = 2
}

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------

# --- Application Lifecycle ---

## Emitted when all Autoloads (Window, Input, Audio) report ready.
signal app_boot_complete()

## Emitted when the user requests exit (allows for "Are you sure?" dialogs or auto-saving).
signal quit_requested()

## Emitted when the application pauses/unpauses.
signal process_mode_toggled(is_paused: bool)

# --- Global Audio Service ---

## Generic request to change background tracks.
## stream_id maps to a string key in the AudioManager.
signal music_play_requested(stream_id: String, crossfade_duration: float)

## Silences the music layer.
signal music_stop_requested(fade_out_duration: float)

## The universal sound trigger.
## Use the `request_sfx` helper function to utilize default arguments.
signal sfx_play_requested(sound_id: String, position_3d: Vector3, volume_db: float, pitch_scale: float)

# --- Scene & Context Management ---

## Triggers the "Director" to swap the main content container.
signal scene_change_requested(scene_path: String, context: Dictionary)

## Toggles the "Curtain" overlay to hide scene transition artifacts.
signal loading_screen_requested(visible: bool)

# --- System Feedback & Errors ---

## Request to show a transient UI popup (Info, Warning, Error).
signal toast_notification_requested(title: String, message: String, type: ToastType)

## Signals a fatal state (e.g., Save File Corruption) that requires user intervention.
signal critical_error_occurred(error_code: int, details: String)

# ------------------------------------------------------------------------------
# State Variables
# ------------------------------------------------------------------------------

## Toggle to enable console logging of bus events.
var _verbose: bool = false

# ------------------------------------------------------------------------------
# Debug Helpers
# ------------------------------------------------------------------------------

## Helper to print formatted messages when _verbose is true.
func log_bus_event(event_name: String, args: Array = []) -> void:
	if _verbose:
		print("[Bus] Signal: %s | Args: %s" % [event_name, str(args)])

# ------------------------------------------------------------------------------
# Public API Helpers
# ------------------------------------------------------------------------------

## Helper to emit sfx_play_requested with default values.
## Default values: position_3d = AUDIO_3D_NULL, volume_db = 0.0, pitch_scale = 1.0.
func request_sfx(sound_id: String, position_3d: Vector3 = AUDIO_3D_NULL, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	sfx_play_requested.emit(sound_id, position_3d, volume_db, pitch_scale)
	log_bus_event("sfx_play_requested", [sound_id, position_3d, volume_db, pitch_scale])
