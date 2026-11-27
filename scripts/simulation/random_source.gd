class_name RandomSource
extends RefCounted


func next_r() -> float:
	assert(false, "RandomSource.next_r debe implementarse")
	return 0.0


func derive_seed(_stream: int) -> int:
	assert(false, "RandomSource.derive_seed debe implementarse")
	return 0


func fork(_stream: int) -> RandomSource:
	assert(false, "RandomSource.fork debe implementarse")
	return null


func next_int(bound: int) -> int:
	assert(bound > 0, "bound debe ser positivo")
	return mini(int(next_r() * bound), bound - 1)


func chance(probability: float) -> bool:
	return next_r() < probability


static func greatest_common_divisor(a: int, b: int) -> int:
	while b != 0:
		var rest := a % b
		a = b
		b = rest
	return absi(a)
