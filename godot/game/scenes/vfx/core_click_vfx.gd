class_name CoreClickVFX extends Node2D

signal finished

func _init() -> void:
	pass

func _ready() -> void:
	pass

func play(position: Vector2, color: Color) -> void:
	global_position = position
	var particles: CPUParticles2D = $Particles # Assuming CPUParticles2D is a child named "Particles"
	if particles:
		particles.color = color
		particles.restart() # Ensure particles play from start
		# Auto-cleanup after particles finish
		await get_tree().create_timer(particles.lifetime + particles.lifetime_randomness + 0.1).timeout
		finished.emit()
	else:
		printerr("ERROR: CoreClickVFX: No 'Particles' node found for playing!")
		finished.emit() # Emit finished even if particles aren't found for cleanup
