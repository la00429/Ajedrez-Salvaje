class_name MultiplicativeCongruential
extends RandomSource

const DEFAULT_MULTIPLIER := 16807
const DEFAULT_MODULUS := 2147483647

var x0: int
var multiplier: int
var modulus: int

var _x: int


func _init(p_x0: int = 1, p_multiplier: int = DEFAULT_MULTIPLIER, p_modulus: int = DEFAULT_MODULUS) -> void:
	assert(p_modulus > 1 and p_multiplier > 1 and p_multiplier < p_modulus, "multiplicador fuera de rango")
	multiplier = p_multiplier
	modulus = p_modulus
	x0 = _coprime_seed(p_x0, p_modulus)
	_x = x0


func next_x() -> int:
	_x = (multiplier * _x) % modulus
	return _x


func next_r() -> float:
	return float(next_x()) / float(modulus)


func derive_seed(stream: int) -> int:
	return SeedMixer.derive(x0, stream)


func fork(stream: int) -> RandomSource:
	return MultiplicativeCongruential.new(derive_seed(stream), multiplier, modulus)


static func is_valid_seed(seed_value: int, m: int) -> bool:
	return seed_value >= 1 and seed_value < m and greatest_common_divisor(seed_value, m) == 1


static func _coprime_seed(seed_value: int, m: int) -> int:
	var candidate := maxi(posmod(seed_value, m), 1)
	while not is_valid_seed(candidate, m):
		candidate = candidate % (m - 1) + 1
	return candidate
