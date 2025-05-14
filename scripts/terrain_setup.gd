extends Node

var width
var height
var area: ColorRect
var terrain_map: Texture2D
var all_terrains = TerrainTypes.get_all_terrains()
func _ready() -> void:
	area = $terrain_shader
	width = get_parent().width
	height = get_parent().height

func setup(terrain_info: Texture2D, 
			) -> void:
	terrain_map = terrain_info
	area.size.x = width
	area.size.y = height
	set_shader()
	
	
func set_shader():
	area.material.set_shader_parameter("terrain_texture", terrain_map)
	area.material.set_shader_parameter("debug_options", 0)
	var colormap = TerrainTypes.colourMap(TerrainTypes.get_all_terrains())
	area.material.set_shader_parameter("terrain_colour_map", colormap)

func get_terrain_at(x, y):
	if x < 0 or x >= width or y < 0 or y >= height:
		return null
	
	var image = terrain_map.get_image()
	var pixel = image.get_pixel(x, y)
	var terrain_id = TerrainTypes.get_terrain_id(pixel.r, pixel.b, pixel.g)
	return all_terrains[terrain_id]
	
	
