class_name HunterAgent
extends RefCounted

const STAY := Vector2i.ZERO
const ACTIONS: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), STAY]

var target := Board.INVALID
var total_reward := 0.0


func policy(observation: HunterObservation, source: RandomSource) -> Vector2i:
	update_state(perceive(observation), source)
	return _approach(observation, source)


func perceive(observation: HunterObservation) -> HunterPerception:
	var nearest: Array[Vector2i] = []
	var best := 1 << 30
	for piece in observation.pieces:
		var distance := Board.manhattan_distance(piece, observation.hunter)
		if distance < best:
			best = distance
			nearest.clear()
		if distance == best:
			nearest.append(piece)
	return HunterPerception.new(nearest, best if not nearest.is_empty() else -1)


func update_state(perception: HunterPerception, source: RandomSource) -> void:
	if not perception.sees_prey():
		target = Board.INVALID
	elif not perception.nearest_pieces.has(target):
		target = perception.nearest_pieces[source.next_int(perception.nearest_pieces.size())]


func receive(transition: HunterTransition) -> void:
	total_reward += transition.reward


func reset() -> void:
	target = Board.INVALID
	total_reward = 0.0


func _approach(observation: HunterObservation, source: RandomSource) -> Vector2i:
	var closer := _actions_toward_target(observation)
	return closer[source.next_int(closer.size())] if not closer.is_empty() else STAY


func _actions_toward_target(observation: HunterObservation) -> Array[Vector2i]:
	var closer: Array[Vector2i] = []
	if not Board.is_inside(target):
		return closer
	var distance := Board.manhattan_distance(observation.hunter, target)
	for action in observation.legal_actions:
		if Board.manhattan_distance(observation.hunter + action, target) < distance:
			closer.append(action)
	return closer
