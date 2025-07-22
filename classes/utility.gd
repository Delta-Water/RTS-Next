extends Node

func create_rect2_from_points(point1: Vector2, point2: Vector2) -> Rect2:
	var width = abs(point1.x - point2.x)
	var height = abs(point1.y - point2.y)
	var x = min(point1.x, point2.x)
	var y = min(point1.y, point2.y)
	return Rect2(x, y, width, height)
