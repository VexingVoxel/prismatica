class_name AudioManagerClass extends Node

## AudioManager
##
## Responsibility: Manages global audio playback. Handles music crossfading, 
## SFX pooling (polyphony control), and bus volume management.
## Listens to CoreEventBus for requests.

# ------------------------------------------------------------------------------
# Constants & Enums
# ------------------------------------------------------------------------------

const NUM_SFX_PLAYERS: int = 12
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_UI: String = "UI"

# ------------------------------------------------------------------------------
# State Variables
# ------------------------------------------------------------------------------

# Music (Double Deck System)
var _music_player_1: AudioStreamPlayer
var _music_player_2: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer = null
var _music_tween: Tween

# SFX Pools
var _sfx_players_2d: Array[AudioStreamPlayer] = []
var _sfx_players_3d: Array[AudioStreamPlayer3D] = []

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	_setup_music_system()
	_setup_sfx_pools()
	_connect_signals()

func _setup_music_system() -> void:
	_music_player_1 = AudioStreamPlayer.new()
	_music_player_1.name = "MusicPlayer1"
	_music_player_1.bus = BUS_MUSIC
	add_child(_music_player_1)

	_music_player_2 = AudioStreamPlayer.new()
	_music_player_2.name = "MusicPlayer2"
	_music_player_2.bus = BUS_MUSIC
	add_child(_music_player_2)

	_active_music_player = _music_player_1

func _setup_sfx_pools() -> void:
	# 2D/UI Pool
	for i in range(NUM_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.name = "SFX_Player_2D_%d" % i
		player.bus = BUS_UI # Default to UI bus for non-positional
		_sfx_players_2d.append(player)
		add_child(player)
		
	# 3D Pool
	for i in range(NUM_SFX_PLAYERS):
		var player := AudioStreamPlayer3D.new()
		player.name = "SFX_Player_3D_%d" % i
		player.bus = BUS_SFX
		_sfx_players_3d.append(player)
		add_child(player)

func _connect_signals() -> void:
	if not CoreEventBus:
		push_error("AudioManager: CoreEventBus not found!")
		return
		
	CoreEventBus.music_play_requested.connect(play_music)
	CoreEventBus.music_stop_requested.connect(stop_music)
	CoreEventBus.sfx_play_requested.connect(play_sfx)

# ------------------------------------------------------------------------------
# Music Logic
# ------------------------------------------------------------------------------

## Plays music with a crossfade.
func play_music(stream_id: String, crossfade_duration: float = 1.0) -> void:
	var stream: AudioStream = load(stream_id)
	if not stream:
		push_warning("AudioManager: Could not load music stream: %s" % stream_id)
		return

	# Determine Active vs Inactive
	var incoming_player: AudioStreamPlayer
	var outgoing_player: AudioStreamPlayer
	
	if _active_music_player == _music_player_1:
		outgoing_player = _music_player_1
		incoming_player = _music_player_2
	else:
		outgoing_player = _music_player_2
		incoming_player = _music_player_1
		
	# Setup Incoming
	incoming_player.stream = stream
	incoming_player.volume_db = -80.0
	incoming_player.play()
	
	# Tween Crossfade
	if _music_tween: _music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	
	# Fade In
	_music_tween.tween_property(incoming_player, "volume_db", 0.0, crossfade_duration)
	
	# Fade Out (if playing)
	if outgoing_player.playing:
		_music_tween.tween_property(outgoing_player, "volume_db", -80.0, crossfade_duration)
		# Stop outgoing after fade
		_music_tween.chain().tween_callback(outgoing_player.stop)
	
	# Swap Active Reference
	_active_music_player = incoming_player

## Stops the currently playing music with a fade out.
func stop_music(fade_out_duration: float = 1.0) -> void:
	if not _active_music_player.playing:
		return
		
	if _music_tween: _music_tween.kill()
	_music_tween = create_tween()
	
	_music_tween.tween_property(_active_music_player, "volume_db", -80.0, fade_out_duration)
	_music_tween.tween_callback(_active_music_player.stop)

# ------------------------------------------------------------------------------
# SFX Logic
# ------------------------------------------------------------------------------

## Plays a sound effect.
## If position_3d is AUDIO_3D_NULL (Vector3(INF, INF, INF)), plays non-positionally (2D/UI).
func play_sfx(sound_id: String, position_3d: Vector3, volume_db: float, pitch_scale: float) -> void:
	var stream: AudioStream = load(sound_id)
	if not stream:
		push_warning("AudioManager: Could not load sfx stream: %s" % sound_id)
		return

	var is_positional: bool = (position_3d != CoreEventBus.AUDIO_3D_NULL)
	
	if is_positional:
		_play_3d(stream, position_3d, volume_db, pitch_scale)
	else:
		_play_2d(stream, volume_db, pitch_scale)

func _play_2d(stream: AudioStream, volume_db: float, pitch_scale: float) -> void:
	var player: AudioStreamPlayer = _get_available_player_2d()
	if not player:
		# Pool exhausted, drop sound
		return
		
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func _play_3d(stream: AudioStream, pos: Vector3, volume_db: float, pitch_scale: float) -> void:
	var player: AudioStreamPlayer3D = _get_available_player_3d()
	if not player:
		# Pool exhausted, drop sound
		return
		
	player.stream = stream
	player.position = pos
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func _get_available_player_2d() -> AudioStreamPlayer:
	for player in _sfx_players_2d:
		if not player.playing:
			return player
	return null

func _get_available_player_3d() -> AudioStreamPlayer3D:
	for player in _sfx_players_3d:
		if not player.playing:
			return player
	return null

# ------------------------------------------------------------------------------
# Volume Control
# ------------------------------------------------------------------------------

## Sets a bus volume using a linear (0.0 - 1.0) value.
func set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("AudioManager: Bus '%s' not found." % bus_name)
		return
		
	var db_value: float = linear_to_db(linear_value)
	AudioServer.set_bus_volume_db(bus_index, db_value)
