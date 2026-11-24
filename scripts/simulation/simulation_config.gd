class_name SimulationConfig
extends Resource

const MAX_LEVEL := 3

@export_group("Generadores")
@export var random_seed: int = 20260101

@export_group("Niveles")
@export var rounds_per_level: int = 10
@export var final_round: int = 30
@export var harsh_climate_level: int = 2
@export var excavator_level: int = 3

@export_group("Agua")
@export var initial_water: float = 100.0
@export var max_water: float = 100.0
@export var time_step: float = 1.0
@export var plant_condensation: float = 0.2
@export var base_evaporation: float = 1.0
@export var frost_evaporation_factor: float = 3.0
@export var rain_gain: float = 4.0
@export var catastrophe_loss: float = 8.0
@export var consumption_per_animal: float = 0.6 / 7.0

@export_group("Clima normal")
@export_range(0.0, 1.0) var rain_probability: float = 0.15
@export_range(0.0, 1.0) var frost_probability: float = 0.13
@export_range(0.0, 1.0) var catastrophe_probability: float = 0.02

@export_group("Clima severo")
@export_range(0.0, 1.0) var harsh_rain_probability: float = 0.10
@export_range(0.0, 1.0) var harsh_frost_probability: float = 0.25
@export_range(0.0, 1.0) var harsh_catastrophe_probability: float = 0.05

@export_group("Vivero")
@export var nursery_capacity: int = 16
@export var nursery_service_rate: float = 0.5
@export var nursery_water_threshold: float = 30.0

@export_group("Cazador")
@export var hunter_start := Vector2i(3, 3)

@export_group("Retroexcavadora")
@export var excavator_edge_policy: RandomWalk.EdgePolicy = RandomWalk.EdgePolicy.REDRAW


func level_for_round(round_number: int) -> int:
	return clampi(1 + int(float(round_number - 1) / rounds_per_level), 1, MAX_LEVEL)


func has_excavator(level: int) -> bool:
	return level >= excavator_level


func climate_matrix(level: int) -> MonteCarloMatrix:
	if level >= harsh_climate_level:
		return _matrix(harsh_rain_probability, harsh_frost_probability, harsh_catastrophe_probability)
	return _matrix(rain_probability, frost_probability, catastrophe_probability)


func _matrix(rain: float, frost: float, catastrophe: float) -> MonteCarloMatrix:
	var probabilities: Array[float] = [1.0 - rain - frost - catastrophe, rain, frost, catastrophe]
	return MonteCarloMatrix.new(Climate.EVENTS, probabilities)
