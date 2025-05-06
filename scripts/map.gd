extends Node2D


var world: world_data


func _ready() -> void:
	world = world_data.new(1920, 1080, 1000)
	for prov in world.provinces:
		add_child(prov.poly)
		var capital = ColorRect.new()
		capital.color = Color(randf(), randf(), randf())
		capital.size = Vector2(1, 1)
		capital.position = prov.capital_location
		add_child(capital)
