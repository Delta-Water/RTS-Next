extends Node2D

var collision_shape_2d: CollisionShape2D
var is_selected = false

func _ready() -> void:
	collision_shape_2d = get_parent().get_child(1)

func _physics_process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var center = Vector2(0, 0)
	var current_radius = collision_shape_2d.shape.radius# * scale_factor
	
	# 绘制圆形轮廓
	var outline_color = Color(0.2, 0.8, 0.2)  # 绿色轮廓
	draw_circle(center, current_radius, outline_color, false, 1)  # 线宽2像素
	
	# 绘制半透明填充
	var fill_color = Color(0, 1, 0, 0.2)  # 半透明绿色填充
	draw_circle(center, current_radius, fill_color, true)  # -1表示填充
	
func set_selected_state(state: bool):
	if state:
		show()
	else:
		hide()
