class_name CameraShake extends Camera2D

## CameraShake
##
## Responsibility: Adds "Juice" to the game by shaking the camera on impact events.
## Uses FastNoiseLite for organic shake movement.

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------

const DECAY_RATE: float = 3.0 # How fast the shake stops
const MAX_OFFSET: Vector2 = Vector2(25.0, 25.0) # Maximum shake in pixels
const MAX_ROLL: float = 0.1 # Maximum rotation in radians
const NOISE_SPEED: float = 20.0 # How fast we sample the noise

# ------------------------------------------------------------------------------
# State
# ------------------------------------------------------------------------------

var _trauma: float = 0.0 # Current shake intensity (0.0 to 1.0)
var _noise: FastNoiseLite
var _noise_y: float = 0.0 # Time value for noise sampling

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	_init_noise()
	_connect_signals()

func _init_noise() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.frequency = 0.5
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM

func _connect_signals() -> void:
	GameplayEventBus.core_clicked.connect(_on_core_clicked)
	# Can add more events here (e.g., big combo, level up)

# ------------------------------------------------------------------------------
# Event Handlers
# ------------------------------------------------------------------------------

func _on_core_clicked(_pos: Vector2) -> void:
	# add_trauma(0.2) # Temporarily disabled to prevent visual artifacts
	pass

# ------------------------------------------------------------------------------
# Logic
# ------------------------------------------------------------------------------

func add_trauma(amount: float) -> void:
	_trauma = min(_trauma + amount, 1.0)

func _process(delta: float) -> void:
	if _trauma > 0.0:
		_decay_trauma(delta)
		_apply_shake(delta)
	else:
		# Reset to exact center/rotation when done
		offset = Vector2.ZERO
		rotation = 0.0

func _decay_trauma(delta: float) -> void:
	# Linear decay? Or exponential? Plan says "Noise offset". 
	# Power of 2 or 3 usually feels better for "trauma".
	_trauma = max(_trauma - DECAY_RATE * delta, 0.0)

func _apply_shake(delta: float) -> void:
	# Trauma is non-linear (square it) so weak shakes are very weak, strong are strong
	var shake_amount: float = _trauma * _trauma
	
	_noise_y += NOISE_SPEED * delta
	
	# Sample noise for X, Y, and Rotation
	# We use different seeds/offsets for each axis to keep them independent
	var noise_x: float = _noise.get_noise_2d(_noise.seed, _noise_y)
	var noise_y: float = _noise.get_noise_2d(_noise.seed + 100, _noise_y)
	var noise_r: float = _noise.get_noise_2d(_noise.seed + 200, _noise_y)
	
	offset.x = MAX_OFFSET.x * shake_amount * noise_x
	offset.y = MAX_OFFSET.y * shake_amount * noise_y
	rotation = MAX_ROLL * shake_amount * noise_r
