class_name SideEcosystem
extends RefCounted

var side: int
var water: Stock
var nursery: NurseryServer


func _init(p_side: int, p_water: Stock, p_nursery: NurseryServer) -> void:
	side = p_side
	water = p_water
	nursery = p_nursery
