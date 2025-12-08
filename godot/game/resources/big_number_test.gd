class_name BigNumberTest extends Node

func _ready() -> void:
	print("--- Starting BigNumber Test ---")
	test_basic_arithmetic()
	test_scientific_normalization()
	test_formatting()
	print("--- BigNumber Test Complete ---")

func test_basic_arithmetic() -> void:
	var a: BigNumber = BigNumber.new(1.0, 18) # 1e18
	var b: BigNumber = BigNumber.new(2.0, 18) # 2e18
	
	# Addition
	var sum: BigNumber = a.plus(b)
	assert_val(sum, 3.0, 18, "1e18 + 2e18")
	
	# Subtraction
	var sub: BigNumber = b.minus(a)
	assert_val(sub, 1.0, 18, "2e18 - 1e18")
	
	# Multiplication
	var mult: BigNumber = a.multiply(BigNumber.new(2.0, 0))
	assert_val(mult, 2.0, 18, "1e18 * 2")
	
	# Division
	var div: BigNumber = a.divide(BigNumber.new(2.0, 0))
	assert_val(div, 5.0, 17, "1e18 / 2") # 0.5e18 -> 5.0e17

func test_scientific_normalization() -> void:
	var a: BigNumber = BigNumber.new(15.0, 2) # 1500
	assert_val(a, 1.5, 3, "Normalize 15.0e2 -> 1.5e3")
	
	var b: BigNumber = BigNumber.new(0.001, 5) # 100
	assert_val(b, 1.0, 2, "Normalize 0.001e5 -> 1.0e2")

func test_formatting() -> void:
	var a: BigNumber = BigNumber.new(1.5, 3) # 1.5k
	print("1.5e3 formatted: " + a.to_formatted_string())
	assert(a.to_formatted_string() == "1.50k", "Format 1.5e3 failed")
	
	var b: BigNumber = BigNumber.new(2.5, 18) # 2.5 Qi
	print("2.5e18 formatted: " + b.to_formatted_string())
	assert(b.to_formatted_string() == "2.50Qi", "Format 2.5e18 failed")

func assert_val(bn: BigNumber, m: float, e: int, msg: String) -> void:
	var m_match: bool = is_equal_approx(bn.mantissa, m)
	var e_match: bool = (bn.exponent == e)
	if m_match and e_match:
		print("[PASS] " + msg)
	else:
		push_error("[FAIL] %s. Expected %.2fe%d, Got %.2fe%d" % [msg, m, e, bn.mantissa, bn.exponent])

