extends Node2D

var tween: Tween
var collision_shape_2d: CollisionShape2D

func _ready() -> void:
	hide()
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
		start_pulse()
	else:
		hide()

func start_pulse() -> void:
	if tween and tween.is_running():
		tween.kill()
	
	# 动画序列
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1) # 放大到150%
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)  # 缩小回原始大小
