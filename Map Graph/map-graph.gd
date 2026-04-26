extends Node2D

@export var MAP_SIZE: Vector2i = Vector2i(1920, 1080)




## This will hold a list of provinces
var PROVINCES: Array
var neighbour_set: Dictionary = {} 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func generate_random_points(count: int, enforce_mind_dist: bool = false):
	var points: Array[Vector2]
	for i in range(count):
		points.append(Vector2(randf_range(0, MAP_SIZE.x), randf_range(0, MAP_SIZE.y)))
	return points
	
func calculate_circumcenter(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	# Translate so A is at the origin — simplifies the maths
	var ax = b.x - a.x
	var ay = b.y - a.y
	var bx = c.x - a.x
	var by = c.y - a.y
	var D = 2.0 * (ax * by - ay * bx)
	
	# D == 0 means the three points are collinear — no valid circumcenter
	if abs(D) < 0.0001:
		return Vector2.INF  # Sentinel value — caller should skip this triangle
	
	var ux = (by * (ax*ax + ay*ay) - ay * (bx*bx + by*by)) / D
	var uy = (ax * (bx*bx + by*by) - bx * (ax*ax + ay*ay)) / D
	
	# Translate back from A's origin to world space
	return Vector2(ux + a.x, uy + a.y)

func generate_provinces(count):
	
	# Ok, so delaunay triangles will connect all the capitals
	# in such a way. We then have to find the circumcenter
	# of the circles that touch the triangles, and then
	# connect all these circumcenters.
	
	var points = generate_random_points(count)
	var delaunay = Geometry2D.triangulate_delaunay(points)
	
	# Should be empty anyways?
	PROVINCES = []
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
