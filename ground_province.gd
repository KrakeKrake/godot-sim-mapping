extends Polygon2D
class_name ground_province


var prov: province
var capital_sprite: ColorRect
var provinceShape: Polygon2D

func _ready() -> void:
	capital_sprite = $Capital

func _setup(capital_pos: Vector2) -> void:
	capital_sprite.position = capital_pos
	
