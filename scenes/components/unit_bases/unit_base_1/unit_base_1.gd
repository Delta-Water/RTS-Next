class_name UnitBase1
extends CharacterBody2D

enum State { IDLE, ROTATING, SLIDING}

@export var acceleration: float = 100.0
@export var deceleration: float = 100.0
@export var max_speed: float = 50.0
var decelerating_distance = (max_speed * max_speed) / (2 * deceleration)
@export var rotate_speed: float = 3
@export var can_move_while_rotating: bool = true
## 碰撞体积半径。（与避障半径自动关联）
@export_range(0.1, 50.0, 0.1, "or_greater")
var radius: float = 10.0:
	set(val):
		radius = val
		if collision_shape_2d and navigation_agent_2d:
			(collision_shape_2d.shape as CircleShape2D).radius = val
			navigation_agent_2d.radius = val + 3

## 显示体积半径。
@export_range(0.1, 50.0, 0.1, "or_greater")
var display_radius: float = 10.0

## 同步碰撞体积和显示体积的半径。
func set_both_radius(new_radius: float) -> void:
	radius = new_radius
	display_radius = new_radius

var current_state: State = State.IDLE
var rotate_tween: Tween
var is_selected: bool = false
var target_position:Vector2 = Vector2(0, 0)
var last_new_speed: float

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	navigation_agent_2d.velocity_computed.connect(_on_velocity_computed)
	
	# 再次调用set函数保证子节点属性被正确赋值
	radius = radius
	display_radius = display_radius

## 接收服务器回传的安全速度
func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	print("a: ", velocity)
	move_and_slide()

func set_movement_target(target: Vector2):
	_interrupt_current_action()
	target_position = target
	navigation_agent_2d.target_position = target
	# 状态将在 physics_process 中更新
	current_state = State.SLIDING

func _interrupt_current_action():
	if rotate_tween and rotate_tween.is_running():
		rotate_tween.kill()
	current_state = State.IDLE

func _physics_process(delta: float):
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			move_and_slide()
		
		State.ROTATING:
			_monitor_velocity_direction()
			if can_move_while_rotating:
				_perform_move(delta)
			else:
				# 旋转前保持静止
				velocity = Vector2.ZERO
				move_and_slide()
		
		State.SLIDING:
			_monitor_velocity_direction()
			_perform_move(delta)

var target_angle: float:
	set(val):
		if not is_equal_approx(target_angle, val):
			target_angle = val
			# 计算最短旋转角度
			rotation = wrapf(rotation, -PI, PI)
			var angle_diff = abs(target_angle - rotation)
			var rotation_direction: int = 1
			
			if rotation >= target_angle:
				rotation_direction = -1
			if angle_diff > PI:
				angle_diff = 2 * PI - angle_diff
				rotation_direction *= -1
			
			# 微小角度直接设置
			if abs(angle_diff) < 0.01:
				rotation = target_angle
				return
			else:
				_start_rotation(angle_diff, rotation_direction)

func _monitor_velocity_direction():
	if velocity != Vector2(0, 0):
		target_angle = velocity.angle()

func _perform_move(delta):
	if navigation_agent_2d.is_navigation_finished():
		current_state = State.IDLE
		return
	
	var current_path = navigation_agent_2d.get_current_navigation_path()
	var current_index = navigation_agent_2d.get_current_navigation_path_index()
	var next_path_pos = navigation_agent_2d.get_next_path_position()
	# 这里就是最后更改的，因为我以为是期望速度方向不正确，但现在看上去也不是这个问题
	#原为（改回去应该就不会有飞出去的问题了）：
	#var direction = global_position.direction_to(next_path_pos)
	var direction = current_path[current_index - 1].direction_to(current_path[current_index])
	var distance_to_target: float
	var current_speed: float = velocity.length()
	var new_speed: float
	
	if can_move_while_rotating:
		distance_to_target = global_position.distance_to(navigation_agent_2d.target_position)
	else:
		distance_to_target = global_position.distance_to(next_path_pos)
	
	if current_speed < max_speed:
		decelerating_distance = current_speed * current_speed / (2 * deceleration)
	
	if distance_to_target > decelerating_distance:
		if current_speed < max_speed:
			new_speed = min(current_speed + acceleration * delta, max_speed)
		else:
			new_speed = max_speed
	else:
		new_speed = max(current_speed - deceleration * delta, 0)
	
	if navigation_agent_2d.avoidance_enabled:
		print("b: ", direction * new_speed)
		navigation_agent_2d.set_velocity(direction * new_speed)
	else:
		_on_velocity_computed(direction * new_speed)

## 旋转
func _start_rotation(angle_diff: float, rotation_direction: int):
	current_state = State.ROTATING
	
	# 清除现有动画
	if rotate_tween and rotate_tween.is_valid():
		rotate_tween.kill()
	
	# 创建旋转动画
	rotate_tween = create_tween()
	var rot_duration = angle_diff / rotate_speed
	
	rotate_tween.tween_property(
		self, 
		"rotation", 
		rotation + angle_diff * rotation_direction, 
		rot_duration
	).set_ease(Tween.EASE_OUT)
	
	rotate_tween.tween_callback(_on_rotation_finished)

func _on_rotation_finished():
	if current_state == State.ROTATING:  # 防止中断后仍切换状态
		if navigation_agent_2d.is_navigation_finished():
			current_state = State.IDLE
		else:
			current_state = State.SLIDING
	rotate_tween = null

func change_selected_state(state: bool):
	is_selected = state
