class_name CoreClickVFX extends VFXInstance

const PARTICLE_LIFETIME_BUFFER: float = 0.1

func _init() -> void:
	pass

func _ready() -> void:
	pass

func play(params: Dictionary = {}) -> void:
	# global_transform is already set by CoreVFXManager, so position is handled.
	
	var color: Color = params.get("color", Color.WHITE)
	
	var particles: CPUParticles2D = $Particles
	if particles:
		particles.color = color
		particles.restart() # Ensure particles play from start
		# Auto-cleanup after particles finish
		await get_tree().create_timer(particles.lifetime + particles.lifetime_randomness + PARTICLE_LIFETIME_BUFFER).timeout
		finished.emit()
	else:
		printerr("ERROR: CoreClickVFX: No 'Particles' node found for playing!")
		finished.emit() # Emit finished even if particles aren't found for cleanup

func reset() -> void:
	var particles: CPUParticles2D = $Particles
	if particles:
		particles.emitting = false
		# particles.clear_particles() # clear_particles() might not be available on CPUParticles2D in Godot 4.x? Checking... 
		# It is available. But restart() usually clears.
		# For pooling, we just want it to stop.
		pass
	
	global_position = Vector2.ZERO
	rotation = 0.0
	scale = Vector2.ONE
	hide()
