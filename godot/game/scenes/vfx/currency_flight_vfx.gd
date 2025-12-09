class_name CurrencyFlightVFX extends CanvasLayer

signal finished

var _spark_texture: GradientTexture2D

func _init() -> void:
	pass

func _ready() -> void:
	# Initialize spark texture here, after the script is attached
	_spark_texture = GradientTexture2D.new()
	_spark_texture.fill = GradientTexture2D.FILL_RADIAL
	_spark_texture.fill_from = Vector2(0.5, 0.5)
	_spark_texture.fill_to = Vector2(0.5, 0.0)
	_spark_texture.width = 16
	_spark_texture.height = 16
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	_spark_texture.gradient = grad

	var sprite: Sprite2D = $Spark
	if sprite:
		sprite.texture = _spark_texture
		var trail: CPUParticles2D = sprite.get_node("Trail")
		if trail:
			trail.texture = _spark_texture
	else:
		printerr("ERROR: CurrencyFlightVFX: 'Spark' Sprite2D node not found in _ready().")

func play(start_screen_pos: Vector2, target_screen_pos: Vector2, color: Color) -> void:
	var sprite: Sprite2D = $Spark
	var trail: CPUParticles2D = sprite.get_node("Trail")

	if not sprite or not trail:
		printerr("ERROR: CurrencyFlightVFX: Missing 'Spark' or 'Trail' nodes when play() called. Emitting finished.")
		# If essential nodes are missing, emit finished and return to avoid errors
		finished.emit()
		return

	sprite.position = start_screen_pos
	sprite.modulate = color
	trail.color = color * 0.8 # Slightly darker trail
	trail.emitting = true
	
	var duration = randf_range(0.8, 1.2)
	var spread = Vector2(randf_range(-32, 32), randf_range(-32, 32))
	
	var tween = create_tween()
	
	# Burst out
	tween.tween_property(sprite, "position", start_screen_pos + spread, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Fly to target
	tween.tween_property(sprite, "position", target_screen_pos, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN).set_delay(0.05)
	
	# Shrink (parallel)
	tween.parallel().tween_property(sprite, "scale", Vector2(0,0), 0.2).set_delay(duration - 0.2)
	
	await tween.finished
	finished.emit()
