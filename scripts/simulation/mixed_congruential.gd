class_name MixedCongruential
extends RandomSource

const DEFAULT_MULTIPLIER := 1664525
const DEFAULT_INCREMENT := 1013904223
const DEFAULT_MODULUS := 4294967296

var x0: int
var multiplier: int
var increment: int
var modulus: int

var _x: int


func _init(p_x0: int = 1, p_multiplier: int = DEFAULT_MULTIPLIER, p_increment: int = DEFAULT_INCREMENT, p_modulus: int = DEFAULT_MODULUS) -> void:
	assert(p_modulus > 1 and p_multiplier > 0 and p_multiplier < p_modulus, "multiplicador fuera de rango")
	assert(p_increment >= 0 and p_increment < p_modulus, "incremento fuera de rango")
	multiplier = p_multiplier
	increment = p_increment
	modulus = p_modulus
	x0 = posmod(p_x0, p_modulus)
	_x = x0


func next_x() -> int:
	_x = (multiplier * _x + increment) % modulus
	return _x


func next_r() -> float:
	return float(next_x()) / float(modulus)


func derive_seed(stream: int) -> int:
	return SeedMixer.derive(x0, stream)


func fork(stream: int) -> RandomSource:
	return MixedCongruential.new(derive_seed(stream), multiplier, increment, modulus)


static func satisfies_hull_dobell(a: int, c: int, m: int) -> bool:
	var coprime := greatest_common_divisor(c, m) == 1
	var shares_prime_factors := _prime_factors(m).all(func(p: int) -> bool: return (a - 1) % p == 0)
	var multiple_of_four := m % 4 != 0 or (a - 1) % 4 == 0
	return coprime and shares_prime_factors and multiple_of_four


static func _prime_factors(value: int) -> Array[int]:
	var factors: Array[int] = []
	var divisor := 2
	while divisor * divisor <= value:
		if value % divisor == 0:
			factors.append(divisor)
			while value % divisor == 0:
				value /= divisor
		divisor += 1
	if value > 1:
		factors.append(value)
	return factors
