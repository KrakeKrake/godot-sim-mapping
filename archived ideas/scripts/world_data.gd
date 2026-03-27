extends Node
class_name world_data

var heightmap
var tempmap
var moisturemap
var provinces: Array[province]
var terrain_texture: ImageTexture
var width: int
var height: int
var terrain_sets: Dictionary
var terrain_manager: Node
var terrain_type_set: String = "Terran"
var actual_width: int
var actual_height: int
var terrain_types = TerrainTypes.get_all_terrains()

func _init(w: int, h: int, num_provinces: int) -> void:
	width = w + 150
	height = h + 150
	actual_width = w
	actual_height = h
	# Make sure to convert this into just 1 image so the shaders
	# can read it

	terrain_texture = ImageTexture.create_from_image(noise_terrain())
	
	provinces = generate_provinces(num_provinces)


func noise_terrain():
	var terrain_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center_x = width / 2.0
	var center_y = height / 2.0
	var noise_scale: float = 0.10 * (1500.0 / max(width, height))
	# Generate data for each pixel
	var elevation_noise = NoiseTexture2D.new()
	var temperature_noise = NoiseTexture2D.new()
	var moisture_noise = NoiseTexture2D.new()
	elevation_noise.seamless = true
	elevation_noise.seamless_blend_skirt = 0.7
	elevation_noise.width = actual_width
	elevation_noise.height = actual_height
	elevation_noise.noise = FastNoiseLite.new()
	elevation_noise.noise.seed = randi()
	elevation_noise.noise.noise_type = FastNoiseLite.TYPE_VALUE
	elevation_noise.noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	elevation_noise.noise.fractal_octaves = 7
	elevation_noise.noise.fractal_gain = 0.5
	elevation_noise.noise.frequency = noise_scale * 1.8
	
	
	# Configure temperature noise
	temperature_noise.seamless = true
	temperature_noise.seamless_blend_skirt = 0.7
	temperature_noise.width = actual_width
	temperature_noise.height = actual_height
	temperature_noise.noise = FastNoiseLite.new()
	temperature_noise.noise.seed = randi()
	temperature_noise.noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	temperature_noise.noise.fractal_octaves = 3
	temperature_noise.noise.frequency = noise_scale * 0.3
	
	# Configure moisture noise
	moisture_noise.seamless = true
	moisture_noise.seamless_blend_skirt = 0.7
	moisture_noise.width = actual_width
	moisture_noise.height = actual_height
	moisture_noise.noise = FastNoiseLite.new()
	moisture_noise.noise.seed = randi()
	moisture_noise.noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	moisture_noise.noise.fractal_octaves = 4
	moisture_noise.noise.frequency = noise_scale * 0.8
	for x in range(width):
		for y in range(height):
			# Get elevation using noise
			var nx = x * noise_scale
			var ny = y * noise_scale
			var elevation = (elevation_noise.noise.get_noise_2d(nx, ny) + 1) / 2.0
			var dx = (x - center_x) / center_x
			var dy = (y - center_y) / center_y
			var distance = sqrt(dy * dy + dx * dx)
			elevation *= 1.0 - smoothstep(0.6, 0.9, distance/1.25)
			
			# Get temperature (varies by latitude/y-position and has noise)
			var base_temp = 1.0 - abs((2.0 * y / height) - 1.0)
			var temp_noise = (temperature_noise.noise.get_noise_2d(nx, ny) + 1) / 2.0
			var temperature = base_temp * 0.7 + temp_noise * 0.3
			
			# Get moisture using noise
			var moisture = (moisture_noise.noise.get_noise_2d(nx, ny) + 1) / 2.0
			
			# Resources (just use noise for now)
			var terrain_id = TerrainTypes.get_terrain_id(elevation, temperature, moisture)
			
			# Store all data in the RGBA channels
			var colour = Color(elevation, temperature, moisture, float(terrain_id) / 255.0)
			terrain_image.set_pixel(x, y, colour)
			
	
	
	return terrain_image

func generate_provinces(count):
	
	# Ok, so delaunay triangles will connect all the capitals
	# in such a way. We then have to find the circumcenter
	# of the circles that touch the triangles, and then
	# connect all these circumcenters.
	
	var points = generate_random_points(count)
	var delaunay = Geometry2D.triangulate_delaunay(points)
	
	# Should be empty anyways?
	provinces = []
	for i in range(count):
		var prov = ground_province.new()
		prov.capital_location = points[i]
		provinces.append(prov)
	for i in range(provinces.size()):
		var verticies = []
		
		for t in range(0, delaunay.size(), 3):
			var has_point = false
			for j in range(3):
				if delaunay[t+j] == i:
					has_point = true
					break
			if has_point:
				var a = points[delaunay[t]]
				var b = points[delaunay[t + 1]]
				var c = points[delaunay[t + 2]]
				# Do stuff
				# calculate this... find midpoint of all triangle
				# lines, and draw a perpenicular line
				# Where these intersect, is our point!
				# The midpoints:
				var circumcenter = calculate_circumcenter(a, b, c)
				if circumcenter != null:
					verticies.append(circumcenter)
		if verticies.size() > 0:
			var is_edge_point = false
			var convex_hull = Geometry2D.convex_hull(points)
			for hull_point in convex_hull:
				if hull_point.distance_to(points[i]) < 0.1:
					is_edge_point = true
					break
			if is_edge_point:
				var map_center = Vector2(width/2.0, height/2.0)
				var direction = (points[i] - map_center).normalized()
				var edge_point = points[i] + direction * 1000
				verticies.append(edge_point)
		# Sort the verticies
		verticies.sort_custom(func(a, b):
			var angle_a = atan2(a.y - provinces[i].capital_location.y,
				a.x - provinces[i].capital_location.x)
			var angle_b = atan2(b.y - provinces[i].capital_location.y,
				b.x - provinces[i].capital_location.x)
			return angle_a < angle_b
		)
		var adjusted_vertices: Array = []
		for point in verticies:
			adjusted_vertices.append(point - provinces[i].capital_location)
		provinces[i].boundary_points = adjusted_vertices

	provinces = check_provinces(provinces)
	return provinces
	
	
func check_provinces(provinces_to_check: Array):
	var edges = [
		[Vector2(0, 0), Vector2(actual_width, 0)],      # Top
		[Vector2(actual_width, 0), Vector2(actual_width, actual_height)], # Right
		[Vector2(actual_width, actual_height), Vector2(0, actual_height)], # Bottom
		[Vector2(0, actual_height), Vector2(0, 0)]      # Left
	]
	# Go through every one, if *ALL* of it's points are out of bounds, remove it
	var partially_in_provs: Array[province] = []
	var valid_provinces: Array[province] = []

	for i in range(provinces_to_check.size()):
		var prov: ground_province = provinces_to_check[i]
		var has_in_bounds = false
		var has_out_bounds = false
		for point in prov.boundary_points:
			var absolute_point = prov.capital_location + point
			if is_in_bounds(absolute_point):
				has_in_bounds = true
			else:
				has_out_bounds = true
		if has_in_bounds and has_out_bounds:
			partially_in_provs.append(prov)
			valid_provinces.append(prov)
		elif has_in_bounds and has_out_bounds == false:
			valid_provinces.append(prov)
			
			
	# If a point is partially in the play area, then make sure it's capital is too
	if partially_in_provs.size() > 0:
		for prov: ground_province in partially_in_provs:
			var point = prov.capital_location
			if not is_in_bounds(point):
				var in_bounds_points = []
				# The capital is out of bounds, move it!
				for boundary_point in prov.boundary_points:
					var absouloute_point = prov.capital_location + boundary_point
					if is_in_bounds(absouloute_point):
						in_bounds_points.append(absouloute_point)
				if in_bounds_points.size() > 0:
					var centroid = Vector2.ZERO
					for poi in in_bounds_points:
						centroid += poi
					centroid /= in_bounds_points.size()
					
					var offset = centroid - prov.capital_location
					prov.capital_location = centroid
					for i in range(prov.boundary_points.size()):
						prov.boundary_points[i] -= offset
				
	# For the partially in ones, remove their points that are out of bounds, and add border points
	# that move in the same direction!
	for prov: ground_province in partially_in_provs:
		var points = prov.boundary_points
		var new_points = []
		var entry_edge = null
		var exit_edge = null
		var exit_point = null
		for i in range(points.size()):
			var current_rel = points[i]
			var next_rel = points[(i + 1) % len(points)]
			var current_abs = prov.capital_location + current_rel
			var next_abs = prov.capital_location + next_rel
			var current_in = is_in_bounds(current_abs)
			var next_in = is_in_bounds(next_abs)
			if current_in and next_in:
				new_points.append(current_rel)
			elif current_in and not next_in:
				new_points.append(current_rel)
				# find where the line crosses the border... easier said than done...
				var intersection = null
				for edge in edges:
					intersection = Geometry2D.segment_intersects_segment(current_abs, next_abs, edge[0], edge[1])
					if intersection != null:
						exit_edge = edge
						exit_point = new_points.size() - 1
						break
				if intersection != null:
					var intersection_rel = intersection - prov.capital_location
					new_points.append(intersection_rel)
			elif not current_in and next_in:
				var intersection = null
				for edge in edges:
					intersection = Geometry2D.segment_intersects_segment(current_abs, next_abs, edge[0], edge[1])
					if intersection != null:
						entry_edge = edge
						break
				if intersection != null:
					var intersection_rel = intersection - prov.capital_location
					new_points.append(intersection_rel)
			else:
				# Both out of bounds
				var intersections = []
				for edge in edges:
					var intersection = Geometry2D.segment_intersects_segment(current_abs, next_abs, edge[0], edge[1])
					if intersection != null:
						intersections.append(intersection)
				if intersections.size() >= 2:
					intersections.sort_custom(func(a, b):
						return current_abs.distance_to(a) < current_abs.distance_to(b)
						)
					
					for intersection in intersections:
						var intersection_rel = intersection - prov.capital_location
						new_points.append(intersection_rel)
		if (entry_edge != null and exit_edge != null) and (entry_edge != exit_edge):
			# get the corner of the entry and exit edge, and add it to the boundry points
			# After the exit_point
			var corner_point = null
			if entry_edge[0].is_equal_approx(exit_edge[0]):
				corner_point = entry_edge[0]
			# Check if entry_edge start matches exit_edge end
			elif entry_edge[0].is_equal_approx(exit_edge[1]):
				corner_point = entry_edge[0]
			# Check if entry_edge end matches exit_edge start
			elif entry_edge[1].is_equal_approx(exit_edge[0]):
				corner_point = entry_edge[1]
			# Check if entry_edge end matches exit_edge end
			elif entry_edge[1].is_equal_approx(exit_edge[1]):
				corner_point = entry_edge[1]
			if corner_point != null:
				var corner_rel = corner_point - prov.capital_location
				var insert_index = exit_point + 1
				new_points.insert((insert_index + 1) % len(new_points), corner_rel)
		prov.boundary_points = new_points
	
	# TODO: If a province is too small, merge it with it's smallest neighbour
	return valid_provinces
	

func get_polygon_size(points: PackedVector2Array):
	# Calculate area of polygon using shoelace formula
	var area = 0.0
	var j = points.size() - 1
	
	for i in range(points.size()):
		area += (points[j].x + points[i].x) * (points[j].y - points[i].y)
		j = i
	
	return abs(area) / 2.0



# I.e only check the real play area? Or the inflated width and height
func is_in_bounds(where: Vector2, play_area: bool = true):
	
	if play_area:
		if where.x < 0 or where.x > actual_width or where.y < 0 or where.y > actual_height:
			return false
		else:
			return true
	else:
		if where.x < 0 or where.x > width or where.y < 0 or where.y > height:
			return false
		else:
			return true

func find_closest_point(x, y, points):
	var point = Vector2(x, y)
	var lowest_dist = INF
	var closest_point: Vector2
	for i in points:
		var distance = point.distance_to(i)
		if distance < lowest_dist:
			lowest_dist = distance
			closest_point = i
	return closest_point

func calculate_circumcenter(a: Vector2, b: Vector2, c: Vector2):
	var d = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
	
	if abs(d) < 0.0001:
		return null
	var ux = ((a.x*a.x + a.y*a.y) * (b.y - c.y) + (b.x*b.x + b.y*b.y) * (c.y - a.y) + (c.x*c.x + c.y*c.y) * (a.y - b.y)) / d
	var uy = ((a.x*a.x + a.y*a.y) * (c.x - b.x) + (b.x*b.x + b.y*b.y) * (a.x - c.x) + (c.x*c.x + c.y*c.y) * (b.x - a.x)) / d
	return Vector2(ux, uy)

func generate_random_points(count: int, enforce_mind_dist: bool = false):
	var points: Array[Vector2]
	var min_dist = width * height/float(count)*0.5
	for i in range(count):
		points.append(Vector2(randf_range(-150, width), randf_range(-150, height)))
		
	if enforce_mind_dist:
		var done: bool
		while done:
			done = true
			for point1 in points:
				for point2 in points:
					if point1.distance_to(point2) < min_dist:
						points.remove_at(points.find(point2))
						points.append(Vector2(randf_range(-150, width), randf_range(-150, height)))
						done = false
	return points


# Make a noise based heightmap
