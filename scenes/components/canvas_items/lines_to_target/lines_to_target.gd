extends Node2D

var state: bool:
	set(val):
		if state != val:
			state = val
			if val:
				state = val
				show()
				#start_scale()
			else:
				hide()

var unit_position: Vector2 = Vector2(0, 0)
var target_position: Vector2 = Vector2(0, 0)
var scale_tween: Tween

func _ready() -> void:
	hide()

func _physics_process(_delta: float) -> void:
	#position = unit_position
	queue_redraw()

func _draw() -> void:
	var start_point = unit_position
	var end_point = target_position
	# 定义颜色（红色）
	var line_color = Color(0, 1, 0) # 绿色
	# 绘制直线，线宽为2，不抗锯齿
	draw_line(start_point, end_point, line_color, 1, false)

func set_selected_state(is_selected: bool):
		state = is_selected

func start_scale() -> void:
	if scale_tween and scale_tween.is_running():
		scale_tween.kill()
	
	# 动画序列
	scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_IN)
	scale_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_SPRING) # 放大到120%
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SPRING)  # 缩小回原始大小
	scale_tween.tween_callback(func(): scale_tween = null)
