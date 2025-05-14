extends CanvasGroup




func setup(points: Array) -> void:
	var line = Line2D.new()
	line.points = points
	line.default_color = Color(0.0, 0.0, 0.0, 1.0)
	line.width = 2
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED
	add_child(line)
