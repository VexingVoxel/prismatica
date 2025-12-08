extends SceneTree

# Preload required classes
const BigNumber = preload("res://game/resources/big_number.gd")
const GridDataResource = preload("res://game/resources/grid_data_resource.gd")
const SquareStrategy = preload("res://game/scripts/grid/strategies/square_strategy.gd")

func _init():
	print("========================================")
	print("Running Game Logic Integration Tests...")
	print("========================================")
	
	var passed = true
	passed = passed and test_bignumber()
	passed = passed and test_grid_logic()
	# Persistence testing requires SaveManager which depends on filesystem.
	# We'll skip complex persistence here for the unit/integration logic test.
	
	if passed:
		print("\n[SUCCESS] All Tests Passed!")
		quit(0)
	else:
		print("\n[FAILURE] Some Tests Failed.")
		quit(1)

func test_bignumber() -> bool:
	print("\n- Testing BigNumber...")
	
	# Test Addition
	var a = BigNumber.new(1.0, 3) # 1000
	var b = BigNumber.new(2.0, 3) # 2000
	var c = a.plus(b)
	if not (c.mantissa == 3.0 and c.exponent == 3):
		printerr("  [FAIL] Addition: 1e3 + 2e3 != 3e3")
		return false
	
	# Test Multiplication
	var d = BigNumber.new(2.0, 0) # 2
	var e = a.multiply(d) # 1000 * 2 = 2000
	if not (e.mantissa == 2.0 and e.exponent == 3):
		printerr("  [FAIL] Multiplication: 1e3 * 2 != 2e3. Got: ", e.to_formatted_string())
		return false
		
	print("  [PASS] BigNumber OK")
	return true

func test_grid_logic() -> bool:
	print("\n- Testing Grid Logic...")
	
	var grid = GridDataResource.new()
	
	# Test 1: Place Square at (0,1) - Touching Core
	var success = grid.place_shape(Vector2i(0,1), "Square")
	if not success:
		printerr("  [FAIL] Failed to place Square at (0,1)")
		return false
		
	if not grid.is_occupied(Vector2i(0,1)):
		printerr("  [FAIL] Cell (0,1) should be occupied")
		return false
		
	# Test 2: Calculate Production
	# Base: 1. Core Bonus: +10% -> 1.1
	var prod = grid.get_total_production()
	
	# Verify value. 1.1 should be mantissa 1.1, exp 0
	# Or mantissa 1.1, exp 0.
	# Floating point comparison requires tolerance.
	var expected_val = 1.1
	var actual_val = prod.mantissa * pow(10, prod.exponent)
	
	if abs(actual_val - expected_val) > 0.001:
		printerr("  [FAIL] Production Mismatch. Expected ~1.1, Got: ", actual_val)
		return false
		
	# Test 3: Place Square at (2,0) - NOT Touching Core
	grid.place_shape(Vector2i(2,0), "Square")
	
	# Total Production: 
	# Shape 1 (0,1): 1.1
	# Shape 2 (2,0): 1.0 (Base 1, No Bonus)
	# Total: 2.1
	prod = grid.get_total_production()
	expected_val = 2.1
	actual_val = prod.mantissa * pow(10, prod.exponent)
	
	if abs(actual_val - expected_val) > 0.001:
		printerr("  [FAIL] Production Mismatch (2 Shapes). Expected ~2.1, Got: ", actual_val)
		return false

	print("  [PASS] Grid Logic OK")
	return true
