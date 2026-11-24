extends RandomSource

var _values: Array
var _index := 0


func _init(values: Array) -> void:
	_values = values


func next_r() -> float:
	var value: float = _values[_index % _values.size()]
	_index += 1
	return value


func derive_seed(stream: int) -> int:
	return stream


func fork(_stream: int) -> RandomSource:
	return get_script().new(_values)
