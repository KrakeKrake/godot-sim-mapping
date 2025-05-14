extends Area2D

var colour_poly: Polygon2D
var select_poly: CollisionPolygon2D
var graphical_poly: Polygon2D


func _ready() -> void:
	colour_poly = $poly
	select_poly = $select_poly

func set_polys(bounding_points):
	colour_poly.polygon = bounding_points
	select_poly.polygon = bounding_points


func update_colour(colour):
	if colour is Texture2D:
		colour_poly.color = Color(1.0, 1.0, 1.0, 0.0)
		colour_poly.texture = colour
	elif colour is Color:
		colour_poly.texture = null
		colour_poly.color = colour
