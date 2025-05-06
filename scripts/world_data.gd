extends Node
class_name world_data

var heightmap
var provinces: Array[province]
var width: int
var height: int


func _init(w: int, h: int, num_provinces: int) -> void:
	width = w
	height = h
	heightmap = generate_2d_heightmap(width, height)
	provinces = generate_provinces(num_provinces)

	
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
		var prov = province.new(points[i])
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
				var ab_midpoint = (a + b) / 2
				var bc_midpoint = (b + c) / 2
				# Get the slopes of the perpendiclar lines
				# Remember rise over run?
				# If it's vertical do big number
				var ab_slope = -1 / ((b.y - a.y) / (b.x - a.x)) if b.x != a.x else 100000
				var bc_slope = -1 / ((c.y - b.y) / (c.x - b.x)) if c.x != b.x else 100000
				
				var intercept_ab = ab_midpoint.y - ab_slope * ab_midpoint.x
				var intercept_bc = bc_midpoint.y - bc_slope * bc_midpoint.x
				
				var x = (intercept_bc - intercept_ab) / (ab_slope - bc_slope)
				var y = ab_slope * x + intercept_ab
				var circumcenter = Vector2(x, y)
				verticies.append(circumcenter)
		
		# Sort the verticies
		verticies.sort_custom(func(a, b):
			var angle_a = atan2(a.y - provinces[i].capital_location.y, 
								a.x - provinces[i].capital_location.x)
			var angle_b = atan2(b.y - provinces[i].capital_location.y, 
								b.x - provinces[i].capital_location.x)
			return angle_a < angle_b
		)
		provinces[i].boundary_points = verticies
		provinces[i].poly = Polygon2D.new()
		provinces[i].poly.polygon = verticies
		provinces[i].poly.color = Color(randf(), randf(), randf(), 0.4)
		
		
		
	return provinces
		
		

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

func generate_random_points(count: int, enforce_mind_dist: bool = false):
	var points: Array[Vector2]
	var min_dist = width*height/float(count)*0.5
	for i in range(count):
		points.append(Vector2(randf_range(0, width), randf_range(0, height)))
		
	if enforce_mind_dist:
		var done: bool
		while done:
			done = true
			for point1 in points:
				for point2 in points:
					if point1.distance_to(point2) < min_dist:
						points.remove_at(points.find(point2))
						points.append(Vector2(randf_range(0, width), randf_range(0, height)))
						done = false
	return points


# Make a noise based heightmap
func generate_2d_heightmap( 
						type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_SIMPLEX_SMOOTH,
						freq: float = 0.003,
						domain_warp: bool = false,
):
	var noise = FastNoiseLite.new()
	noise.noise_type = type
	noise.frequency = freq
	noise.domain_warp_enabled = domain_warp
	
	var map: = []
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(noise.get_noise_2d(x, y))
		map.append(row)
	return map
	
	
