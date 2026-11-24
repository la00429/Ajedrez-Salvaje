class_name MM1Theory
extends RefCounted


static func utilization(arrival_rate: float, service_rate: float) -> float:
	return arrival_rate / service_rate


static func has_steady_state(arrival_rate: float, service_rate: float) -> bool:
	return utilization(arrival_rate, service_rate) < 1.0


static func system_length(arrival_rate: float, service_rate: float) -> float:
	if not has_steady_state(arrival_rate, service_rate):
		return INF
	var rho := utilization(arrival_rate, service_rate)
	return rho / (1.0 - rho)


static func queue_length(arrival_rate: float, service_rate: float) -> float:
	if not has_steady_state(arrival_rate, service_rate):
		return INF
	var rho := utilization(arrival_rate, service_rate)
	return rho * rho / (1.0 - rho)


static func system_time(arrival_rate: float, service_rate: float) -> float:
	if not has_steady_state(arrival_rate, service_rate):
		return INF
	return 1.0 / (service_rate - arrival_rate)


static func queue_wait(arrival_rate: float, service_rate: float) -> float:
	if not has_steady_state(arrival_rate, service_rate):
		return INF
	return utilization(arrival_rate, service_rate) / (service_rate - arrival_rate)
