extends Node2D


@export var MAP_SIZE: Vector2i = Vector2i(100, 100)
@export var SEED_POINTS: int = 8
@export var debug_mode: bool = false

var plates: Array[Dictionary] = []
var plate_id_map: Array = []
var elevation_map: Array = []
var plate_colours: Array[Color] = []
var plate_lookup: Dictionary = {}



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	seed_plates(SEED_POINTS)
	for i in range(plates.size()):
		plate_colours.append(Color(randf(), randf(), randf()))
	plate_colours.append(Color(1.0, 1.0, 1.0))
	
	# Initialise the platemap as all -1.
	for x in MAP_SIZE.x:
		plate_id_map.append([])
		elevation_map.append([])
		for y in MAP_SIZE.y:
			plate_id_map[x].append(-1)
			elevation_map[x].append(-1)
	setup_plate_id_map_visual()
	await flood_fill_plates()
	print("Flood filled")
	build_plate_lookup()
	print("Built Plate Lookup")
	visualise_plate_id_map()
	await get_tree().process_frame
	generate_base_elevations()
	print("Base elevation finished")
	blur_elevation()
	print("Gaussian Blurred")
	visualise_elevation()
	print("finished")

func in_bounds(coords: Vector2i) -> bool:
	# So they dont go above 0 or below the map size (index error)
	if coords.x < 0 or coords.x >= MAP_SIZE.x: return false
	if coords.y < 0 or coords.y >= MAP_SIZE.y: return false
	return true

func get_neighbours(coords: Vector2i) -> Array[Vector2i]:
	var neighbours: Array[Vector2i] = []
	for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var neighbour: Vector2i = coords + offset
		if neighbour.y < 0 or neighbour.y >= MAP_SIZE.y: continue
		if neighbour.x < 0:
			neighbour.x = MAP_SIZE.x - 1
		elif neighbour.x >= MAP_SIZE.x:
			neighbour.x = 0
		neighbours.append(neighbour)
	return neighbours


func build_plate_lookup():
	for plate in plates:
		plate_lookup[plate.id] = plate
		
## Returns the position of cell that is a boundary between 2 plates.
## Returns the following keys: boundary_position, boundary_position_neighbour, plate_1, plate_2
func plate_boundaries() -> Array:
	var boundaries: Array = []
	# Look through all of the possible things, ask it if the pixel to the diaganl up of you is different.
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var original_plate = plate_id_map[x][y]
			for neighbour in get_neighbours(Vector2i(x, y)):
				if plate_id_map[neighbour.x][neighbour.y] != original_plate:
					boundaries.append({
						"boundary_position": Vector2i(x, y),
						"boundary_position_neighbour": neighbour, # Position of the nieghbour
						"plate_1": original_plate,
						"plate_2": plate_id_map[neighbour.x][neighbour.y]
					})
	return boundaries

func generate_base_elevations():
	# Do the base elevations, oceanic and not.
	# 0 is going to mean sea level from now on, I like that.
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var plate = plate_lookup[plate_id_map[x][y]]
			if plate.oceanic:
				elevation_map[x][y] = -10
			else:
				elevation_map[x][y] = 40

	# So we make a map (of size MAP_SIZE, and each cell is a float of the distance to the nearest boundary)
	# Then SOMEHOW get the type of boundary that the boundary we are near is, and if it is converging
	# mountain, if it is diverging, ravine, etc. The strength of the change basically.
	var dist_map: Array = []
	var strength_map: Array = []
	var queue: = []
	
	# Initialise said map
	for x in MAP_SIZE.x:
		dist_map.append([])
		strength_map.append([])
		for y in MAP_SIZE.y:
			dist_map[x].append(INF)
			strength_map[x].append(INF)
	
	var boundaries = plate_boundaries()
	for boundary in boundaries:
		var dot_product = plate_lookup[boundary.plate_1].drift_dir.dot(plate_lookup[boundary.plate_2].drift_dir)
		var strength = -dot_product * 20.0
		
		var plate_1 = plate_lookup[boundary.plate_1]
		var plate_2 = plate_lookup[boundary.plate_2]
		
		if plate_1.oceanic and plate_2.oceanic:
			strength = -dot_product * 15.0
		elif not plate_1.oceanic and not plate_2.oceanic:
			strength = -dot_product * 30.0
		else:
			# One of each so *subduction yayyyy*
			if plate_1.oceanic:
				strength = -dot_product * -20.0
			else:
				strength = -dot_product * 15.0
		
		if dist_map[boundary.boundary_position.x][boundary.boundary_position.y] == INF:
			dist_map[boundary.boundary_position.x][boundary.boundary_position.y] = 0.0
			strength_map[boundary.boundary_position.x][boundary.boundary_position.y] = strength
			queue.append(boundary.boundary_position)
		if dist_map[boundary.boundary_position_neighbour.x][boundary.boundary_position_neighbour.y] == INF:
			dist_map[boundary.boundary_position_neighbour.x][boundary.boundary_position_neighbour.y] = 0.0
			strength_map[boundary.boundary_position_neighbour.x][boundary.boundary_position_neighbour.y] = strength
			queue.append(boundary.boundary_position_neighbour)

	
	while queue.size() > 0:
		var cell = queue.pop_front()
		for neighbour in get_neighbours(cell):
			if dist_map[neighbour.x][neighbour.y] == INF:
				dist_map[neighbour.x][neighbour.y] = dist_map[cell.x][cell.y] + 1.0
				strength_map[neighbour.x][neighbour.y] = strength_map[cell.x][cell.y]
				queue.append(neighbour)
	
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var d = dist_map[x][y]
			var falloff = mountain_falloff(d)
			elevation_map[x][y] += strength_map[x][y] * falloff

##Gaussien blur!
func blur_elevation(passes: int = 3):
	for _pass in range(passes):
		var new_elevation: Array = []
		for x in MAP_SIZE.x:
			new_elevation.append([])
			for y in MAP_SIZE.y:
				new_elevation[x].append(0.0)
		
		for x in MAP_SIZE.x:
			for y in MAP_SIZE.y:
				var total = 0.0
				var count = 0
				# Get each neighbour, steal their elevation, add yourself, average it!
				for neighbour in get_neighbours(Vector2i(x, y)):
					total += elevation_map[neighbour.x][neighbour.y]
					count += 1
				total += elevation_map[x][y]  # include self
				count += 1
				new_elevation[x][y] = total / count
		
		elevation_map = new_elevation

func mountain_falloff(d: float) -> float:
	var steep_range = 15# randf_range(6.0, 15.0)   # mountains drop off hard within *some* cells
	var gentle_range = 60#randf_range(25.0, 100.0) # then gently fade to plains over *some* cells
	
	if d < steep_range:
		# Steep part: goes from 1.0 down to ~0.4
		var t = d / steep_range
		return lerp(1.0, 0.4, smoothstep(0.0, 1.0, t))
	else:
		# Gentle part: continues from 0.4 down to 0.0
		var t = (d - steep_range) / gentle_range
		return lerp(0.4, 0.0, smoothstep(0.0, 1.0, clamp(t, 0.0, 1.0)))

## Distance of point a to point b
## Considers moving directly on the map and "off" the map to the left and right
## [param point_a] - starting position
## [param point_b] - target position
## [br]Returns a Dictionary with keys: dist, dx, dy
func distance_all_ways(point_a: Vector2i, point_b: Vector2i) -> Dictionary:
	var dx: float = point_b.x - point_a.x
	var dy: float = point_b.y - point_a.y
	
	
	var dx_direct = dx
	var dx_left = dx - MAP_SIZE.x
	var dx_right = dx + MAP_SIZE.x
	
	var best_dx = dx_direct
	if abs(dx_left) < abs(best_dx): best_dx = dx_left
	if abs(dx_right) < abs(best_dx): best_dx = dx_right
	
	var dist = sqrt(best_dx * best_dx + dy * dy)
	return {"dist": dist, "dx": best_dx, "dy": dy}

func flood_fill_plates():    
	# The nigbours of each pixel. Not diagonal bcs... well they arent technically neighbours.	
	# So the queue is a list of pixels that have been claimed
	# But havent checked their neighbours yet. One all their neighborus are checked (and claimed) 
	# That is removed from the queue.
	
	var queue = []
	for plate in plates:
		var seed_pos: Vector2i = plate.seed_position
		
		plate_id_map[seed_pos.x][seed_pos.y] = plate.id
		queue.append(seed_pos)
	
	# While the queue has stuff in it go and check each one's neighbours
	var steps = 0
	while queue.size() > 0:
		var cell_pos: Vector2i = queue.pop_front()
		
		for cell in get_neighbours(cell_pos):
			# if not in_bounds(cell): continue
			
			# If they are claimed (I.e not -1), then skip also
			if plate_id_map[cell.x][cell.y] != -1: continue
			# So they are in bounds and not claimed, it's ours! Go <insert plate id>!
			plate_id_map[cell.x][cell.y] = plate_id_map[cell_pos.x][cell_pos.y]
			queue.append(cell)
			steps += 1
			if steps % 500 == 0:
				var chance: float = randf()
				if chance <= 1.0:
					queue.shuffle()
				else:
					queue.sort()
				if debug_mode and steps % 6000 == 0:
					visualise_plate_id_map()
					await get_tree().process_frame

func is_valid_map(map: Array) -> bool:
	for x in map:
		for y in x:
			if y == -1:
				return false
	return true

func seed_plates(plate_count: int) -> Array[Dictionary]:
	for i in plate_count:
		var plate: Dictionary = {
			"id": i, # THe ID, simple eesy
			"seed_position": Vector2i(randi_range(0, MAP_SIZE.x), randi_range(0, MAP_SIZE.y)),
			# The position at which the seed is placed, and the plate will grow from there out
			"drift_dir": Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized(),
			# The direction in which the plates drift. Which is how mountains and the like are born
			"oceanic": randf() < 0.4 # Oceanic stars low, if false starts high, simpelz
		}
		plates.append(plate)
	
	return plates

func get_plate_of_id(id: int) -> Dictionary:
	for plate in plates:
		if plate.id == id:
			return plate
	return {
			"id": -1, # THe ID, simple eesy
			"seed_position": Vector2i(randi_range(0, MAP_SIZE.x - 1), randi_range(0, MAP_SIZE.y - 1)),
			# The position at which the seed is placed, and the plate will grow from there out
			"drift_dir": Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized(),
			# The direction in which the plates drift. Which is how mountains and the like are born
			"oceanic": randf() < 0.4 # Oceanic stars low, if false starts high, simpelz
		}

# For visualising stuffs
var img: Image
var tex: ImageTexture

func setup_plate_id_map_visual():
	img = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGB8)
	tex = ImageTexture.create_from_image(img)
	$Sprite2D.texture = tex

func visualise_plate_id_map():
	img = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGB8)
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			img.set_pixel(x, y, plate_colours[plate_id_map[x][y]])
	tex.update(img)
	
func visualise_elevation():
	var SEA_LEVEL = 0.0
	var MIN_ELEV = -60.0
	var MAX_ELEV = 120.0
	var elev_range = MAX_ELEV - MIN_ELEV

	var colour_gradient: Gradient = Gradient.new()
	colour_gradient.add_point(0.0,                                    Color(0.05, 0.05, 0.3))  # deep ocean
	colour_gradient.add_point((SEA_LEVEL - 10 - MIN_ELEV) / elev_range, Color(0.1,  0.2,  0.6))  # shallow ocean
	colour_gradient.add_point((SEA_LEVEL - MIN_ELEV) / elev_range,      Color(0.76, 0.7,  0.5))  # beach
	colour_gradient.add_point((SEA_LEVEL + 5 - MIN_ELEV) / elev_range,  Color(0.3,  0.6,  0.2))  # lowland
	colour_gradient.add_point((SEA_LEVEL + 40 - MIN_ELEV) / elev_range, Color(0.2,  0.45, 0.1))  # highland
	colour_gradient.add_point((SEA_LEVEL + 80 - MIN_ELEV) / elev_range, Color(0.5,  0.4,  0.3))  # mountain
	colour_gradient.add_point(1.0,                                    Color(1.0,  1.0,  1.0))  # snow

	img = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGB8)
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var t = clamp((elevation_map[x][y] - MIN_ELEV) / elev_range, 0.0, 1.0)
			img.set_pixel(x, y, colour_gradient.sample(t))
	tex.update(img)
