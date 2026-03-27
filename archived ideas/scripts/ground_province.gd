extends province
class_name ground_province


var prov: province
var capital_sprite: Node2D
var area: Area2D
var border_lines: Node
var name_label: Label
var hover_timer: Timer = null
var development: float = 0 # How developed this province is 100 is like courosant, and 0 is like siberia
var infrastructure_level: float = 0 # So... out of 100... 0 is... siberia, 50 is Tokyo


func _ready() -> void:
	capital_sprite = $Capital
	area = $provincal_area
	name_label = $name_label
	border_lines = $border_lines
	
func _setup(provinceData: province, colour: Color = Color(randf(), randf(), randf(), 0.3)):
	self.position = provinceData.capital_location
	boundary_points = provinceData.boundary_points
	area.set_polys(boundary_points)
	area.update_colour(colour)
	province_colour = colour
	is_selected = provinceData.is_selected
	border_lines.setup(boundary_points)
	name_label.text = str(get_polygon_size(boundary_points))

func calculate_development():
	var population_factor
	var infrastructure_factor
	if population > 0:
		population_factor = 20 * log(population * 10) / log(10)
		
	if infrastructure_level <= 60:
		infrastructure_factor = infrastructure_level * 0.6
	else:
		infrastructure_factor = 36 + (infrastructure_level - 60) * 0.3
	var base_score = population_factor + infrastructure_factor
	var synergy = sqrt(infrastructure_factor * population_factor) * 0.1
	return clamp(base_score + synergy, 0, 100)

func mouse_entered():
	if hover_timer:
		hover_timer.queue_free()
	hover_timer = Timer.new()
	hover_timer.one_shot = true
	hover_timer.wait_time = 1.0
	add_child(hover_timer)
	hover_timer.start()
	hover_timer.connect("timeout", show_tooltip)

func get_polygon_size(points: PackedVector2Array):
	var area_size = 0.0
	var n = points.size()
	for i in range(n):
		var j = (i + 1) % n
		area_size += points[i].x * points[j].y
		area_size -= points[j].x * points[i].y
	area_size = abs(area_size) / 2.0
	return area_size

func show_tooltip():
	name_label.visible = true

func mouse_exited():
	name_label.visible = false
	if hover_timer:
		hover_timer.queue_free()
	
func update_owner(new_owner):
	if new_owner:
		prov_owner = new_owner
	else:
		prov_owner = null
		
func update_colour(colour):
	area.update_colour(colour)
