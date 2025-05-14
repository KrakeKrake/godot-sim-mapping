extends Camera2D

@export var pan_speed: float = 5000.0


# Zoom properties
@export var min_zoom: float = 0.85
@export var max_zoom: float = 100.0
@export var zoom_speed: float = 0.1
@export var zoom_margin: float = 0.1

# WE like it smooth
@export var smoothing_enabled: bool = true
@export var smoothing_speed: float = 5.0

# Internal variables
var target_zoom: Vector2 = Vector2(1.0, 1.0)
var map_size: Vector2
var dragging: bool = false
var drag_start_pos: Vector2
var drag_current_pos: Vector2

func _ready() -> void:
	map_size = Vector2(1920 * 1.0, 1080 * 1.0)
	
	zoom = Vector2(1.0, 1.0)
	target_zoom = zoom


func _process(delta: float) -> void:
	if smoothing_enabled and zoom != target_zoom:
		zoom = zoom + (target_zoom - zoom) * (smoothing_speed * delta)
	var dir = Vector2()
	if Input.is_action_just_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_just_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_just_pressed("ui_up"):
		dir.y -= 1
	if Input.is_action_just_pressed("ui_down"):
		dir.y += 1
	dir = dir.normalized() 	
	
	position += dir * pan_speed * delta / zoom.x
	position.x = clamp(position.x, -map_size.x/2, map_size.x/2)
	position.y = clamp(position.y, -map_size.y/2, map_size.y/2)
	#wrap_position()
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var new_zoom = target_zoom * (1 + zoom_speed)
			new_zoom.x = min(new_zoom.x, max_zoom)
			new_zoom.y = min(new_zoom.y, max_zoom)
			target_zoom = new_zoom
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var new_zoom = target_zoom * (1 - zoom_speed)
			new_zoom.x = max(new_zoom.x, min_zoom)
			new_zoom.y = max(new_zoom.y, min_zoom)
			target_zoom = new_zoom
			
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				dragging = true
				drag_start_pos = event.position
			else:
				dragging = false
	
	if event is InputEventMouseMotion and dragging:
		drag_current_pos = event.position
		position -= (drag_current_pos - drag_start_pos) / zoom.x
		drag_start_pos = drag_current_pos
	
	position.x = clamp(position.x, -map_size.x/2, map_size.x/2)
	position.y = clamp(position.y, -map_size.y/2, map_size.y/2)
	#wrap_position()
	
	
func wrap_position():
	# Wrap horizontally
	if position.x < 0:
		position.x += map_size.x
	elif position.x > map_size.x:
		position.x -= map_size.x
