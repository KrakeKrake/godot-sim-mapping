extends Node2D

@export var width: int = 1920
@export var height: int = 1080

var world: world_data
var provinces_node: Node
var Terrain: Node2D
var Camera: Camera2D

func _ready() -> void:
	Terrain = $Terrain
	provinces_node = $Provinces
	var ground_prov_scene = load("res://ground_province.tscn")
	world = world_data.new(width, height, 100)
	Terrain.setup(world.terrain_texture)
	for prov_data in world.provinces:
		var prov = ground_prov_scene.instantiate()
		provinces_node.add_child(prov)
		prov._setup(prov_data)
