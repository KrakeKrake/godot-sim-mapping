extends Node2D

# The exports that are needed to describe the basics of any map

# y by x because... wait idk.
@export var MAP_SIZE: Vector2i
@export var PLATE_COUNT: int = 5
@export var view_debug_steps: bool = false
@export var colour_gradient: Gradient


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gen_planet()
	
	


#region funcs calling funcs

signal plate_gen_complete
var _plate_thread: Thread
func gen_planet() -> void:
	_plate_thread = Thread.new()
	_plate_thread.start(generate_plates)

func generate_plates() -> void:
	seed_points()
	print("Points seeded")
	flood_fill()
	print("Flood filled")
	base_tectonic_elevations()
	print("Elevations set")
	setup_noise()
	print("Noise setup")
	add_noise_to_elevation()
	print("Added noise to elevation map")
	apply_plate_boundary_effects()
	print("Added noise to elevation map")
	call_deferred("on_plate_gen_complete")

func on_plate_gen_complete():
	_plate_thread.wait_to_finish()
	visualise_elevation()
	print("Elevation visualised")
	plate_gen_complete.emit()

#endregion

#region Voronoi Seeding
var plate_id_map: Array = []
var plates: Dictionary = {}
var elevation_map: Array = []

## Seed points on the map size in such a way they are always far away from other points
func seed_points():
	# Initilise the plate id map
	for x in MAP_SIZE.x:
		plate_id_map.append([])
		for y in MAP_SIZE.y:
			plate_id_map[x].append(-1)
			
	create_plate(0, Vector2i(randi_range(0, MAP_SIZE.x-1), randi_range(0, MAP_SIZE.y-1)))
	for i in range(1, PLATE_COUNT):
		
		var best_pos = Vector2i.ZERO
		var best_dist = -1.0
		for j in range(50):
			var candidate_position = Vector2i(randi_range(0, MAP_SIZE.x-1), randi_range(0, MAP_SIZE.y-1))
			var dist_to_nearest_plate = INF
			for plate_i in plates:
				var plate = plates[plate_i]
				var distance: float = Vector2(candidate_position - plate.seed_point).length()
				if distance < dist_to_nearest_plate:
					dist_to_nearest_plate = distance
			if dist_to_nearest_plate > best_dist:
				best_dist = dist_to_nearest_plate
				best_pos = candidate_position
		create_plate(i, best_pos)
		
var warp_noise: FastNoiseLite = FastNoiseLite.new()
func get_warped_plate(x: int, y: int) -> int:
	var warp_strength = 120.0
	var wx = x + warp_noise.get_noise_2d(x * 0.3, y * 0.3) * warp_strength
	var wy = y + warp_noise.get_noise_2d(x * 0.3 + 500, y * 0.3 + 500) * warp_strength
	var sx = clamp(int(wx), 0, MAP_SIZE.x - 1)
	var sy = clamp(int(wy), 0, MAP_SIZE.y - 1)
	return plate_id_map[sx][sy]

func base_tectonic_elevations() -> void:
	# Initialise the elevation map
	
	for x in MAP_SIZE.x:
		elevation_map.append([])
		for y in MAP_SIZE.y:
			elevation_map[x].append(null)
			
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var plate = plates[get_warped_plate(x, y)]
			elevation_map[x][y] = -1000.0 if plate.oceanic else 150.0


var boundary_distance_map: Array = []
var nearest_boundary_map: Array = []
func build_boundary_distance_map() -> void:
	# initialise the map
	for x in MAP_SIZE.x: 
		boundary_distance_map.append([])
		nearest_boundary_map.append([])
		for y in MAP_SIZE.y:
			boundary_distance_map[x].append(-1.0)
			nearest_boundary_map[x].append(Vector2i(-1, -1))
	
	# *First* queue up all the boundaries
	
	var queue: Array = []
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			for neighbour in get_neighbours(Vector2i(x, y)):
				if plate_id_map[x][y] != plate_id_map[neighbour.x][neighbour.y]:
					nearest_boundary_map[x][y] = Vector2i(x, y)
					boundary_distance_map[x][y] = 0.0
					queue.append(Vector2i(x, y))
					break
					
	#Then do math on them
	while queue.size() > 0:
		var cell = queue.pop_front()
		for neighbour in get_neighbours(cell):
			if boundary_distance_map[neighbour.x][neighbour.y] == -1.0:
				# Propagate the nearest boundary position, not hop count
				nearest_boundary_map[neighbour.x][neighbour.y] = nearest_boundary_map[cell.x][cell.y]
				# Real distance to the boundary cell
				var boundary_pos = nearest_boundary_map[cell.x][cell.y]
				boundary_distance_map[neighbour.x][neighbour.y] = distance_all_ways(neighbour, boundary_pos).dist
				queue.append(neighbour)

## Return the distance (after check all ways)
## Returns best_dist, dx, dy.
func distance_all_ways(point_a: Vector2i, point_b: Vector2i) -> Dictionary:
	# Change in distance in x and y
	var dx: float = point_b.x - point_a.x
	var dy: float = point_b.y - point_a.y
	
	# We ignore why because the the tops of the world do not connect
	# The sides do
	var dx_direct = dx
	var dx_left = dx - MAP_SIZE.x
	var dx_right = dx + MAP_SIZE.x
	
	# The "best" distance to it, both left and right directions get returned
	var best_dx = dx_direct
	if abs(dx_left) < abs(best_dx): best_dx = dx_left
	if abs(dx_right) < abs(best_dx): best_dx = dx_right
	
	# Calculate final distance 
	var dist = sqrt(best_dx * best_dx + dy * dy)
	return {"dist": dist, "dx": best_dx, "dy": dy}

func apply_plate_boundary_effects() -> void:
	build_boundary_distance_map()
	var ridge_noise: FastNoiseLite = FastNoiseLite.new()
	ridge_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	ridge_noise.frequency = 0.008
	
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var dist = boundary_distance_map[x][y]
			var max_influence = 10.0
			
			if dist > max_influence: continue
			
			# Falloff: strong at boundary, zero at max_influence
			var Falloff = 1.0 - clamp(dist / max_influence, 0.0, 1.0)
			Falloff = Falloff * Falloff
			
			# Ridged noise: abs() of normal noise flipped gives ridges at 0-crossings
			var n = abs(ridge_noise.get_noise_2d(x, y))
			
			var plate = plates[get_warped_plate(x, y)]
			if plate.oceanic:
				n = (n * 2) - 1.0
				elevation_map[x][y] += Falloff * n * 400.0
			else:
				n = (n * 2) - 0.4
				elevation_map[x][y] += Falloff * n * 2500.0
			

## Create a plate with a seed point.
## It append the plates array with: 
## id, seed_point, oceanic
## And turns the plate id at the seed position to it's own
func create_plate(id: int, seed_point: Vector2i, oceanic: bool = randf() > 0.35):
	var plate = {
		"id": id,
		"seed_point": seed_point,
		"oceanic": oceanic
	}
	plates[id] = plate
	plate_id_map[seed_point.x][seed_point.y] = id

## Flood fill from the plates array
func flood_fill() -> void:
	# The nigbours of each pixel. Not diagonal bcs... well they arent technically neighbours.	
	# So the queue is a list of pixels that have been claimed
	# But havent checked their neighbours yet. One all their neighborus are checked (and claimed) 
	# That is removed from the queue.
	
	var queue = []
	for plate_i in plates:
		var plate = plates[plate_i]
		var seed_pos: Vector2i = plate.seed_point
		
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
				queue.shuffle()
				if view_debug_steps and steps % 6000 == 0 and not _plate_thread.is_started():
					visualise_plate_id_map()
					await get_tree().process_frame

# Get neighbours including warpping around the world.
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

#endregion

#region Noise and elevation
var elevation_noise: FastNoiseLite

var elevation_ocean_noise: FastNoiseLite

func setup_noise() -> void:
	# Do the setuip for elevation noise
	# Seed is there so if I really like one I can keep it, random by default iirc.
	elevation_noise = FastNoiseLite.new()
	elevation_noise.frequency = 0.005
	elevation_noise.seed = randi()

	elevation_ocean_noise = FastNoiseLite.new()
	elevation_ocean_noise.frequency = 0.002
	elevation_ocean_noise.seed = randi()

func add_noise_to_elevation() -> void:
	pass
	#for x in MAP_SIZE.x: 
		#for y in MAP_SIZE.y:
			## Large scale (continental shape) + small scale (local detail)
			#var large = elevation_noise.get_noise_2d(x, y) * 1200.0
			#var detail = elevation_noise.get_noise_2d(x * 4.0, y * 4.0) * 300.0
			#elevation_map[x][y] += large + detail

#endregion

#region Visual debugging

var plate_id_image: Image
var elevation_image: Image
var plate_colours: Array[Color] = []
@onready var tex: ImageTexture = ImageTexture.create_from_image(Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGB8))

func setup_debug_views():
	for i in range(PLATE_COUNT):
		plate_colours.append(Color(randf(), randf(), randf()))
	plate_colours.append(Color(1.0, 1.0, 1.0))
	$Sprite2D.texture = tex

func visualise_plate_id_map():
	if not view_debug_steps: setup_debug_views()
	plate_id_image = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGB8)
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var plate_colour = plate_colours[plate_id_map[x][y]]
			plate_id_image.set_pixel(x, y, plate_colour)
	tex.update(plate_id_image)
	
	
func visualise_elevation():
	if not view_debug_steps: setup_debug_views()
	var min_elev = INF
	var max_elev = -INF
	
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var elev_at_point: float = elevation_map[x][y]
			if elev_at_point > max_elev:
				max_elev = elev_at_point
			elif elev_at_point < min_elev:
				min_elev = elev_at_point
	
	var elev_range = max_elev - min_elev
	print(elev_range)

	elevation_image = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGB8)
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var t = clamp((elevation_map[x][y] - min_elev) / elev_range, 0.0, 1.0)
			elevation_image.set_pixel(x, y, colour_gradient.sample(t))
			if elevation_map[x][y] <= 0:
				elevation_image.set_pixel(x, y, Color.BLUE)
				
	
	tex.update(elevation_image)
#endregion
