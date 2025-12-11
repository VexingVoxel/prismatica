class_name VFXInstance extends Node2D # Defaulting to Node2D for 2D projects

signal finished

# Method to initialize and start the VFX with given parameters.
# Derived classes must implement this to configure and activate the effect.
# @param params: Dictionary of parameters (e.g., color, target_pos, speed).
func play(params: Dictionary = {}) -> void:
	# Derived classes will implement specific logic here.
	# Example:
	# var particles: GPUParticles2D = $GPUParticles2D
	# if particles and params.has("color"):
	#	particles.process_material.set_shader_parameter("emission_color", params.color)
	# particles.restart()
	printerr("VFXInstance: play() not implemented in derived class: ", get_class())
	finished.emit() # Ensure signal is emitted even if not implemented

# Method to reset the VFX to its initial state for pooling.
# Derived classes must implement this to stop particles, reset tweens/animations,
# clear states, and hide the instance.
func reset() -> void:
	# Derived classes will implement specific reset logic here.
	# Example:
	# var particles: GPUParticles2D = $GPUParticles2D
	# if particles:
	#	particles.emitting = false
	#	particles.clear_particles()
	# global_position = Vector2.ZERO
	hide() # Ensure hidden when returned to pool
	# Kill any running tweens/animations

# Guidance on _init(), _ready(), play(), reset() usage in derived classes:
# - _init(): Reserved for minimal, one-time setup that does NOT rely on being in the scene tree or having child nodes.
# - _ready(): Primarily for getting child nodes via `$Path` or connecting internal signals. Runs every time an instance enters the scene tree.
# - play(): Handles dynamic configuration (from CoreVFXManager via event parameters) and initiates the effect.
# - reset(): Clears state, stops effects, and prepares for reuse in object pooling.
#             Should be called by CoreVFXManager before returning to pool.