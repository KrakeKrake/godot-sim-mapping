extends Node2D


@export var map_width: int = 1920
@export var map_height: int = 1080

var left_viewport: SubViewport
var main_viewport: SubViewport
var right_viewport: SubViewport


func _ready() -> void:
	left_viewport = $LeftSubViewportContainer/LeftSubViewPort
	main_viewport = $MainSubViewportContainer/MainSubViewPort
	right_viewport = $RightSubViewportContainer/RightSubViewPort
	
	
	
	
	
	
	
	
