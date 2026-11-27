class_name MonteCarloModel
extends RefCounted


func estimate(trial: Callable, replicas: int, source: RandomSource) -> MonteCarloEstimate:
	var stats := RunningStats.new()
	for index in maxi(replicas, 0):
		stats.add(float(trial.call(source.fork(index))))
	return stats.to_estimate()
