class_name CurrencyFlightVFX extends VFXInstance

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------

const SPARK_TEXTURE_SIZE: int = 16
const SPARK_TEXTURE_GRADIENT_END_COLOR: Color = Color(1, 1, 1, 0) # White transparent

const TRAIL_COLOR_MULTIPLIER: float = 0.8

const FLIGHT_DURATION_MIN: float = 0.8
const FLIGHT_DURATION_MAX: float = 1.2
const BURST_SPREAD_MAGNITUDE: float = 32.0
const BURST_OUT_DURATION: float = 0.2
const FLIGHT_DELAY: float = 0.05
const SHRINK_DURATION: float = 0.2
const SHRINK_DELAY_OFFSET: float = 0.2

var _spark_texture: GradientTexture2D
var _tween: Tween

func _init() -> void:
	pass

func _ready() -> void:
	# Initialize spark texture here, after the script is attached
	_spark_texture = GradientTexture2D.new()
	_spark_texture.fill = GradientTexture2D.FILL_RADIAL
	_spark_texture.fill_from = Vector2(0.5, 0.5)
	_spark_texture.fill_to = Vector2(0.5, 0.0)
	_spark_texture.width = SPARK_TEXTURE_SIZE
	_spark_texture.height = SPARK_TEXTURE_SIZE
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, SPARK_TEXTURE_GRADIENT_END_COLOR])
	_spark_texture.gradient = grad

	var sprite: Sprite2D = $Spark
	if sprite:
		sprite.texture = _spark_texture
		var trail: CPUParticles2D = sprite.get_node("Trail")
		if trail:
			trail.texture = _spark_texture
	else:
		printerr("ERROR: CurrencyFlightVFX: 'Spark' Sprite2D node not found in _ready().")

func play(params: Dictionary = {}) -> void:
	var start_screen_pos: Vector2 = params.get("start_screen_pos", Vector2.ZERO)
	var target_screen_pos: Vector2 = params.get("target_screen_pos", Vector2.ZERO)
	var color: Color = params.get("color", Color.WHITE)

	var sprite: Sprite2D = $Spark
	var trail: CPUParticles2D = sprite.get_node("Trail")

	if not sprite or not trail:
		printerr("ERROR: CurrencyFlightVFX: Missing 'Spark' or 'Trail' nodes when play() called. Emitting finished.")
		# If essential nodes are missing, emit finished and return to avoid errors
		finished.emit()
		return

	sprite.position = start_screen_pos
	sprite.modulate = color
	trail.color = color * TRAIL_COLOR_MULTIPLIER
	trail.emitting = true
	sprite.scale = Vector2.ONE # Ensure scale is reset
	
	var duration = randf_range(FLIGHT_DURATION_MIN, FLIGHT_DURATION_MAX)
	var spread = Vector2(randf_range(-BURST_SPREAD_MAGNITUDE, BURST_SPREAD_MAGNITUDE), randf_range(-BURST_SPREAD_MAGNITUDE, BURST_SPREAD_MAGNITUDE))
	
	if _tween: _tween.kill() # Safety check
	_tween = create_tween()
	
	# Burst out
	_tween.tween_property(sprite, "position", start_screen_pos + spread, BURST_OUT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Fly to target
	_tween.tween_property(sprite, "position", target_screen_pos, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN).set_delay(FLIGHT_DELAY)
	
	# Shrink (parallel)
	_tween.parallel().tween_property(sprite, "scale", Vector2(0,0), SHRINK_DURATION).set_delay(duration - SHRINK_DELAY_OFFSET)
	
	await _tween.finished
	finished.emit()

func reset() -> void:
	var sprite: Sprite2D = $Spark
	# Check for trail safely
	if sprite:
		var trail: CPUParticles2D = sprite.get_node_or_null("Trail")
		if trail:
			trail.emitting = false
		
		sprite.position = Vector2.ZERO
		sprite.scale = Vector2.ONE
		sprite.modulate = Color.WHITE
	
	if _tween:
		_tween.kill()
		_tween = null
	
	hide()
