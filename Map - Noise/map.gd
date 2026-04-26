@tool
extends Node2D

@export var MAP_SIZE: Vector2i
@export var continental_noise: NoiseTexture2D
@export var erosion_noise: NoiseTexture2D
@export var tectonic_noise: NoiseTexture2D
@export var ridge_noise: NoiseTexture2D
@export var detail_noise: NoiseTexture2D

@export var continent_curve: Curve
@export var erosion_curve: Curve
@export var tectonic_curve: Curve
@export var ridge_curve: Curve

@export var colour_gradient: Gradient
var cells_total: int = 0


#Stuff for the renderer, chunks and cache
var pre_generated_world: bool = false
var world_size := Vector2i(1408, 512)

var CHUNK_CACHE: Dictionary = {}
const CHUNK_SIZE: Vector2i = Vector2i(1408, 512)
const WORLD_SIZE: Vector2i = Vector2i(64, 64)
const TILE_SIZE: Vector2i = Vector2i(4, 4)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	$Camera2D.position = Vector2(
		WORLD_SIZE.x * TILE_SIZE.x / 2.0,
		WORLD_SIZE.y * TILE_SIZE.y / 2.0
	)
	init_noise()
	setup_debug_view()
	
	if load_world() == false:
		pre_generated_world = false
	else:
		pre_generated_world = true
		print(full_elevation_map)
	
	# We check if we are in the editor so it doesn't error out
	if Engine.is_editor_hint():
		continental_noise.changed.connect(visualise_elevation)
		erosion_noise.changed.connect(visualise_elevation)
		tectonic_noise.changed.connect(visualise_elevation)
		ridge_noise.changed.connect(visualise_elevation)
		erosion_noise.changed.connect(visualise_elevation)
		detail_noise.changed.connect(visualise_elevation)
		colour_gradient.changed.connect(visualise_elevation)
		continent_curve.changed.connect(visualise_elevation)
		erosion_curve.changed.connect(visualise_elevation)
		tectonic_curve.changed.connect(visualise_elevation)
		ridge_curve.changed.connect(visualise_elevation)
		self.editor_description_changed.connect(visualise_elevation)
		self.script_changed.connect(visualise_elevation)
	save_world()
	visualise_elevation()
var full_elevation_map: Array

func save_world() -> void:
	var save = ConfigFile.new()
	save.set_value("map", "seed", chosen_seed)
	# Save the elevation
	full_elevation_map = []
	for x in MAP_SIZE.x:
		full_elevation_map.append([])
		for y in MAP_SIZE.y:
			full_elevation_map[x].append(get_elevation(x, y))
	save.set_value("map", "elevation_map", full_elevation_map)
	save.save("res://Map - Noise/map.cfg")
	print("Saved")
	
func load_world() -> bool:
	
	var save = ConfigFile.new()
	if save.load("res://Map - Noise/map.cfg") != OK:
		print("Not loaded:(")
		return false
	print("LOADED")
	full_elevation_map = save.get_value("map", "elevation_map")
	chosen_seed = save.get_value("map", "seed")
	
	return false
var lowest = INF
var highest = -INF
var chosen_seed: int = 0
#region noise elevation making
func init_noise() -> void:
	chosen_seed = randi()
	print(chosen_seed)
	continental_noise.width = MAP_SIZE.x
	continental_noise.height = MAP_SIZE.y
	continental_noise.noise.frequency = 3.828/MAP_SIZE.x
	continental_noise.noise.seed = chosen_seed
	erosion_noise.width = MAP_SIZE.x
	erosion_noise.height = MAP_SIZE.y
	erosion_noise.noise.frequency = 2.4024/MAP_SIZE.x
	erosion_noise.noise.seed = chosen_seed
	tectonic_noise.width = MAP_SIZE.x
	tectonic_noise.height = MAP_SIZE.y
	tectonic_noise.noise.frequency = 16.8432/MAP_SIZE.x
	tectonic_noise.noise.seed = chosen_seed
	ridge_noise.width = MAP_SIZE.x
	ridge_noise.height = MAP_SIZE.y
	ridge_noise.noise.frequency = 7.92/MAP_SIZE.x
	ridge_noise.noise.seed = chosen_seed
	detail_noise.width = MAP_SIZE.x
	detail_noise.height = MAP_SIZE.y
	detail_noise.noise.frequency = 7.92/MAP_SIZE.x
	detail_noise.noise.seed = chosen_seed
	print("Generation Complete")

func get_elevation(x: float, y: float) -> float:
	#region raw noise
	if pre_generated_world:
		print("Got from the save!")
		return full_elevation_map[x][y]
		
	var continent = continental_noise.noise.get_noise_2d(x, y)
	var dx = ((x - MAP_SIZE.x/2.0) / (MAP_SIZE.x/2.0)) / 1.05
	var dy = (y - MAP_SIZE.y/2.0) / (MAP_SIZE.y/2.0)
	var distance = sqrt(dy * dy + dx * dx)
	var edge_mask = smoothstep(0.8, 1.1, distance)
	continent = lerp(continent, -0.7, edge_mask) 
	continent = continent_curve.sample(continent)
	
	var erosion = erosion_noise.noise.get_noise_2d(x, y)
	erosion = erosion_curve.sample(erosion)
	
	var tectonic = tectonic_noise.noise.get_noise_2d(x, y)
	tectonic = tectonic_curve.sample(tectonic)
	
	var ridge = ridge_noise.noise.get_noise_2d(x, y)
	ridge = ridge_curve.sample(ridge)
	
	# Widen coast_mask and use it to suppress tectonic noise near shore
	var coast_blend = smoothstep(-0.15, 0.3, continent)  # 0 in water, 1 inland
	var tectonic_damped = tectonic * coast_blend
	
	#endregion
	# The base elevation
	var elevation = continent * 2000.0
	
	#region Water masks and elevation
	var land_mask = smoothstep(-0.05, 0.25, continent)
	# Where are we in water or not.
	var water_mask = 1.0 - land_mask
	# When we are in *deep* water, this will get higher.
	var deep_water_mask = 1.0 - smoothstep(-0.8, -0.2, continent)
	var shallow_water_mask = water_mask * (1.0 - deep_water_mask)
	# Islands should appear... along ridges in deep water.
	var islands_mask = smoothstep(0.4, 0.7, tectonic) * shallow_water_mask
	var trench_mask = smoothstep(0.0, 0.9, tectonic) * deep_water_mask
	var abyssal_mask = deep_water_mask * (1.0 - trench_mask)
	var coast_mask = smoothstep(-0.1, 0.0, continent) * smoothstep(0.2, 0.05, continent)
	
	var island_elev = ((tectonic + ridge) * islands_mask) * 2500.0
	var abyssal_elev = tectonic * 80.0 * abyssal_mask
	var trench_elev = (ridge - 0.2) * -3500.0 * trench_mask
	var continental_shelf_elev = shallow_water_mask * 300.0
	elevation += continental_shelf_elev + island_elev + abyssal_elev + trench_elev
	
	#endregion
	
	#region land stuff
	var highland_mask = smoothstep(0.3, 0.6, continent)
	var lowland_mask = land_mask * (1.0 - highland_mask)
	var mountain_mask = smoothstep(0.4, 0.8, tectonic_damped) * land_mask
	var rift_mask = smoothstep(-0.8, -0.5, tectonic_damped) * land_mask
	var erosion_mask = smoothstep(0.4, 0.8, erosion) * land_mask
	var young_mask = (1.0 - erosion_mask) * land_mask
	
	# In the format of masks * noise * multiplier
	var mountain_elev = (mountain_mask * young_mask) * ridge * 4000.0
	var highland_elev = (highland_mask * erosion_mask) * tectonic * 800.0
	var rift_elev = (land_mask * rift_mask) * ridge * -400.0
	var costal_elev = (lowland_mask * coast_mask) * tectonic * 50.0
	var peak_elev = (land_mask * mountain_mask) * 1500.0
	elevation += mountain_elev + highland_elev + rift_elev + costal_elev + peak_elev
	#endregion
	return elevation + (detail_noise.noise.get_noise_2d(x, y) * 50.0)
#endregion

#region Visual stuff

var elevation_img: Image
@onready var tex: ImageTexture = ImageTexture.create_from_image(Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGB8))
func setup_debug_view() -> void:
	tex.update(Image.create_empty(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGB8))
	$Display.texture = tex

var cells_done: int = 0
func visualise_elevation() -> void:
	if not is_inside_tree() or not $Display: return
	
	var min_elev = 0.0
	var max_elev = 0.0
	
	# 1. Create a cache to avoid calling noise math twice
	var cache: Array[float] = []
	cache.resize(MAP_SIZE.x * MAP_SIZE.y)
	
	# 2. First pass: Calculate elevation and find bounds
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var elev = get_elevation(x, y)
			cache[x + y * MAP_SIZE.x] = elev
			
			if elev > max_elev: max_elev = elev
			if elev < min_elev: min_elev = elev
	
	# Safety check to avoid division by zero if map is perfectly flat
	if min_elev == 0: min_elev = -0.01
	if max_elev == 0: max_elev = 0.01

	# 3. Second pass: Map to colors
	elevation_img = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGB8)
	
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var elev = cache[x + y * MAP_SIZE.x]
			var t: float
			
			if elev < 0:
				# Remap negative elevation from [Min, 0] to [0.0, 0.5]
				t = remap(elev, min_elev, 0.0, 0.0, 0.5)
			else:
				# Remap positive elevation from [0, Max] to [0.5, 1.0]
				t = remap(elev, 0.0, max_elev, 0.5, 1.0)
			
			# Sample your gradient using the fixed 0.5 midpoint
			elevation_img.set_pixel(x, y, colour_gradient.sample(t))
			cells_done += 1
			update_ui()
			#await get_tree().process_frame
	
	tex = ImageTexture.create_from_image(elevation_img)
	
	$Display.texture = tex

func update_ui() -> void:
	var percent_done: float = (float(cells_done) / float(cells_total)) * 100.0
	$Control/Label.text = "Completed: {0}, out of {1}, {2}% done".format([cells_done, cells_total, percent_done])

#func visualise_elevation() -> void:
	#elevation_img = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGB8)
	#for x in MAP_SIZE.x:
		#for y in MAP_SIZE.y:
			#var elev = get_elevation(x, y)
			#var t = clamp((elev - -1.0) / 2.0, 0.0, 1.0)
			#elevation_img.set_pixel(x, y, colour_gradient.sample(t))
				#
	#tex = ImageTexture.create_from_image(elevation_img)
	#$Display.texture = tex
	#print(lowest)
	#print(highest)
	
	
#region rendering
