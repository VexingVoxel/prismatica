class_name BigNumber extends Resource

## BigNumber
##
## Responsibility: Handles arithmetic for numbers larger than 64-bit integers (~9e18).
## Uses scientific notation logic (mantissa * 10^exponent).
##
## Precision: 
## - Mantissa is a float (approx 15-17 significant decimal digits).
## - Exponent is an int (allows for effectively infinite magnitude for this context).
##
## Usage:
## var huge_val: BigNumber = BigNumber.new(1.5, 20) # 1.5e20
## var result: BigNumber = huge_val.plus(other_val)

# ------------------------------------------------------------------------------
# Properties
# ------------------------------------------------------------------------------

@export var mantissa: float = 0.0
@export var exponent: int = 0

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _init(p_mantissa: float = 0.0, p_exponent: int = 0) -> void:
	mantissa = p_mantissa
	exponent = p_exponent
	normalize()

# ------------------------------------------------------------------------------
# Core Logic
# ------------------------------------------------------------------------------

## Normalizes the number so mantissa is between [1, 10) or (-10, -1].
## E.g., 15.0 e2 -> 1.5 e3
func normalize() -> void:
	if mantissa == 0.0:
		exponent = 0
		return

	# Handle extremely small numbers (close to 0) as 0
	if absf(mantissa) < 1e-9 and exponent == 0:
		mantissa = 0.0
		exponent = 0
		return

	# Normalize magnitude
	while absf(mantissa) >= 10.0:
		mantissa /= 10.0
		exponent += 1
		
	while absf(mantissa) < 1.0 and mantissa != 0.0:
		mantissa *= 10.0
		exponent -= 1

# ------------------------------------------------------------------------------
# Arithmetic Operations (Immutable - Returns New Instance)
# ------------------------------------------------------------------------------

## Adds another BigNumber to this one.
func plus(other: BigNumber) -> BigNumber:
	# Optimization: If difference in magnitude is massive, ignore smaller number
	var exp_diff: int = exponent - other.exponent
	
	if exp_diff > 15: # self is way bigger
		return self.duplicate_val()
	if exp_diff < -15: # other is way bigger
		return other.duplicate_val()
		
	# Align exponents to the larger one
	var target_exp: int = int(max(exponent, other.exponent))
	var my_scaled_mantissa: float = mantissa * pow(10, exponent - target_exp)
	var other_scaled_mantissa: float = other.mantissa * pow(10, other.exponent - target_exp)
	
	return BigNumber.new(my_scaled_mantissa + other_scaled_mantissa, target_exp)

## Subtracts another BigNumber from this one.
func minus(other: BigNumber) -> BigNumber:
	var neg_other: BigNumber = BigNumber.new(-other.mantissa, other.exponent)
	return self.plus(neg_other)

## Multiplies this BigNumber by another.
func multiply(other: BigNumber) -> BigNumber:
	return BigNumber.new(mantissa * other.mantissa, exponent + other.exponent)

## Divides this BigNumber by another.
func divide(other: BigNumber) -> BigNumber:
	if other.is_zero():
		push_error("BigNumber: Division by zero")
		return BigNumber.new(0.0, 0)
		
	return BigNumber.new(mantissa / other.mantissa, exponent - other.exponent)

# ------------------------------------------------------------------------------
# Comparison
# ------------------------------------------------------------------------------

func is_greater_than(other: BigNumber) -> bool:
	if exponent > other.exponent: return mantissa > 0
	if exponent < other.exponent: return mantissa < 0
	if exponent == other.exponent: return mantissa > other.mantissa
	return false # Should be caught by exp check but fallback

func is_less_than(other: BigNumber) -> bool:
	return other.is_greater_than(self)

func is_equal_to(other: BigNumber) -> bool:
	# Warning: Float equality check
	return exponent == other.exponent and is_equal_approx(mantissa, other.mantissa)

func is_zero() -> bool:
	return mantissa == 0.0

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

func duplicate_val() -> BigNumber:
	return BigNumber.new(mantissa, exponent)

## Returns a human-readable string.
## Modes: "scientific" (1.5e20), "suffix" (1.5 Qi), "plain" (1500 - for small nums)
func to_formatted_string(mode: String = "suffix") -> String:
	if exponent < 3:
		# Small number, show standard float/int representation
		var val: float = mantissa * pow(10, exponent)
		# Start truncation if it looks like an integer
		if is_equal_approx(val, roundf(val)):
			return "%d" % int(val)
		return "%.2f" % val
		
	if mode == "scientific":
		return "%.2fe%d" % [mantissa, exponent]
		
	if mode == "suffix":
		return _get_suffix_string()
		
	return "%.2fe%d" % [mantissa, exponent]

func _get_suffix_string() -> String:
	var suffixes: Array[String] = ["", "k", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var suffix_index: int = int(floor(exponent / 3.0))
	
	if suffix_index < suffixes.size():
		var display_mantissa: float = mantissa * pow(10, exponent % 3)
		return "%.2f%s" % [display_mantissa, suffixes[suffix_index]]
	else:
		# Fallback to scientific for massive numbers
		return "%.2fe%d" % [mantissa, exponent]

# ------------------------------------------------------------------------------
# Static Factories
# ------------------------------------------------------------------------------

static func from_int(value: int) -> BigNumber:
	return BigNumber.new(float(value), 0)

static func from_float(value: float) -> BigNumber:
	return BigNumber.new(value, 0)
