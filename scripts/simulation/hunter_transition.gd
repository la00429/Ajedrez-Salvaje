class_name HunterTransition
extends RefCounted

var observation: HunterObservation
var reward: float
var terminated: bool
var step: WalkStep


func _init(p_observation: HunterObservation, p_reward: float, p_terminated: bool, p_step: WalkStep) -> void:
	observation = p_observation
	reward = p_reward
	terminated = p_terminated
	step = p_step
