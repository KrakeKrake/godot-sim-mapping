extends Node
class_name province


var id: int # Should be same as index in the world_data?
var neighbours: Array[province]
var capital_location: Vector2
var boundary_points
var is_selected: bool
var province_colour: Color
var prov_owner = null
var population: float # So... lets say 1 is 1 million?


func _init() -> void:
	pass
