class_name WaterSystem
extends RefCounted

const CONDENSATION := &"condensation"
const RAIN := &"rain"
const EVAPORATION := &"evaporation"
const CONSUMPTION := &"consumption"
const CATASTROPHE := &"catastrophe"

var _config: SimulationConfig


func _init(config: SimulationConfig) -> void:
	_config = config


func new_stock() -> Stock:
	return Stock.new(_config.initial_water, 0.0, _config.max_water)


func step(stock: Stock, census: Census, climate: Climate.Type) -> StockStep:
	return stock.integrate(flows(census, climate), _config.time_step)


func flows(census: Census, climate: Climate.Type) -> Array[Flow]:
	var result: Array[Flow] = [
		Flow.new(CONDENSATION, Flow.POSITIVE, _config.plant_condensation * census.plants),
		Flow.new(RAIN, Flow.POSITIVE, _config.rain_gain if climate == Climate.Type.RAIN else 0.0),
		Flow.new(EVAPORATION, Flow.NEGATIVE, _evaporation(climate)),
		Flow.new(CONSUMPTION, Flow.NEGATIVE, _config.consumption_per_animal * census.animals),
		Flow.new(CATASTROPHE, Flow.NEGATIVE, _config.catastrophe_loss if climate == Climate.Type.CATASTROPHE else 0.0),
	]
	return result


func _evaporation(climate: Climate.Type) -> float:
	if climate == Climate.Type.FROST:
		return _config.base_evaporation * _config.frost_evaporation_factor
	return _config.base_evaporation
