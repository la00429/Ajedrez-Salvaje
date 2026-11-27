class_name RandomWalk
extends RefCounted

enum EdgePolicy { STAY, REDRAW }

const INCREMENT_PROBABILITY := 0.25

var origin: Vector2i
var position: Vector2i
var step_count := 0
var policy: EdgePolicy


func _init(p_origin: Vector2i, p_policy: EdgePolicy = EdgePolicy.REDRAW) -> void:
	origin = p_origin
	position = p_origin
	policy = p_policy


func step(source: RandomSource, walkable: Callable = Callable()) -> WalkStep:
	var rule := walkable if walkable.is_valid() else _inside_board
	var from := position
	position = from + _increment(source, rule)
	step_count += 1
	return WalkStep.new(from, position)


func displacement() -> Vector2i:
	return position - origin


func squared_distance() -> int:
	var offset := displacement()
	return offset.x * offset.x + offset.y * offset.y


static func increment_for(r: float) -> Vector2i:
	var index := mini(int(r / INCREMENT_PROBABILITY), Board.ORTHOGONAL_DIRECTIONS.size() - 1)
	return Board.ORTHOGONAL_DIRECTIONS[index]


func _increment(source: RandomSource, walkable: Callable) -> Vector2i:
	if policy == EdgePolicy.STAY:
		var increment := increment_for(source.next_r())
		return increment if walkable.call(position + increment) else Vector2i.ZERO
	var options := _valid_increments(walkable)
	return options[source.next_int(options.size())] if not options.is_empty() else Vector2i.ZERO


func _inside_board(coord: Vector2i) -> bool:
	return Board.is_inside(coord)


func _valid_increments(walkable: Callable) -> Array[Vector2i]:
	var options: Array[Vector2i] = []
	for increment in Board.ORTHOGONAL_DIRECTIONS:
		if walkable.call(position + increment):
			options.append(increment)
	return options
