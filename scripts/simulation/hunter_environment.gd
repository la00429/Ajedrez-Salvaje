class_name HunterEnvironment
extends RefCounted

var hunter := Board.INVALID

var _pieces: Array[Vector2i] = []
var _walkable := Callable()


func reset(position: ChessPosition, p_hunter: Vector2i, walkable: Callable) -> HunterObservation:
	hunter = p_hunter
	_pieces = _piece_coords(position)
	_walkable = walkable
	return observe()


func observe() -> HunterObservation:
	return HunterObservation.new(hunter, _pieces.duplicate(), _legal_actions())


func step(action: Vector2i) -> HunterTransition:
	var from := hunter
	if action in _legal_actions():
		hunter += action
	var reward := _collect_prey(from)
	return HunterTransition.new(observe(), reward, _pieces.is_empty(), WalkStep.new(from, hunter))


func _collect_prey(from: Vector2i) -> float:
	if hunter == from or not _pieces.has(hunter):
		return 0.0
	_pieces.erase(hunter)
	return 1.0


func _legal_actions() -> Array[Vector2i]:
	var actions: Array[Vector2i] = []
	for action in HunterAgent.ACTIONS:
		if action == HunterAgent.STAY or _can_enter(hunter + action):
			actions.append(action)
	return actions


func _can_enter(coord: Vector2i) -> bool:
	return Board.is_inside(hunter) and _walkable.is_valid() and _walkable.call(coord)


static func _piece_coords(position: ChessPosition) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for index in 64:
		var code := position.squares[index]
		if code != ChessPosition.EMPTY and code != ChessPosition.NEUTRAL:
			coords.append(ChessPosition.to_coord(index))
	return coords
