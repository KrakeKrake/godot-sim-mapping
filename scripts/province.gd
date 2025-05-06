extends Node
class_name province


var id: int # Should be same as index in the world_data?
var neighbours: Array[province]
var poly: Polygon2D
var capital_location: Vector2
var boundary_points


func _init(center: Vector2) -> void:
	capital_location = center
