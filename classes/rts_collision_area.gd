class_name RtsCollisionArea
extends Node

## 标识碰撞区域的类型
## NOTICE: Types except circle are not implemented yet
enum ShapeType {
	CIRCLE,
	RECTANGLE,
}

var internal_shape: InternalShape

class InternalShape:
	func build_collision_shape() -> CollisionShape2D:
		return null
	func build_area_display() -> Node2D:
		return null
	func type() -> ShapeType:
		return ShapeType.CIRCLE

class Circle extends InternalShape:
	var radius: float
	func _init(init_radius: float) -> void:
		radius = init_radius

	func build_collision_shape() -> CollisionShape2D:
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = radius
		collision.shape = shape
		return collision

	func build_area_display() -> Node2D:
		var points = PackedVector2Array()
		var cuts = ceil(radius * PI) as int
		var radian_delta = 2.0 * PI / cuts
		for i in range(cuts):
			var radian = radian_delta * i
			points.push_back(Vector2(cos(radian), sin(radian)) * radius)
		var line = Line2D.new()
		line.points = points
		line.closed = true
		line.width = 2
		line.default_color = Color.AQUAMARINE
		return line

	func type() -> ShapeType:
		return ShapeType.CIRCLE

func build_collision_shape() -> CollisionShape2D:
	return internal_shape.build_collision_shape()

func build_area_display() -> Node2D:
	return internal_shape.build_area_display()

func type() -> ShapeType:
	return internal_shape.type()

static func new_circle(radius: float) -> RtsCollisionArea:
	var obj = RtsCollisionArea.new()
	obj.internal_shape = Circle.new(radius)
	return obj
