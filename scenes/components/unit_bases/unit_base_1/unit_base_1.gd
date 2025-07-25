class_name UnitBase1
extends CharacterBody2D

enum State { IDLE, ROTATING, MOVING }

@export var movement_speed = 50
@export var rotate_speed: float = 3
@export var can_move_while_rotating: bool = true

var current_state: State = State.IDLE
var rotate_tween: Tween
var current_path_index: int = -1

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	navigation_agent.velocity_computed.connect(_on_velocity_computed)

func _input(event: InputEvent):
	if event.is_action_pressed("click"):
		_interrupt_current_action()
		current_path_index = -1
		set_movement_target(event.position)
		# 状态将在 physics_process 中更新
		current_state = State.IDLE

func _physics_process(delta: float):
	match current_state:
		State.IDLE:
			# 等待导航路径更新
			if not navigation_agent.is_navigation_finished():
				_start_moving()
			else:
				velocity = Vector2.ZERO
				move_and_slide()
		
		State.ROTATING:
			if can_move_while_rotating:
				_perform_move()
			else:
				# 旋转前保持静止
				velocity = Vector2.ZERO
				move_and_slide()
		
		State.MOVING:
			_perform_move()

func _perform_move():
	if navigation_agent.is_navigation_finished():
		current_state = State.IDLE
		return
		
	var next_path_pos = navigation_agent.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_pos) * movement_speed
	
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
	
	# 检查路径点变化
	var new_index = navigation_agent.get_current_navigation_path_index()
	if current_path_index != new_index:
		current_path_index = new_index
		_start_rotation(navigation_agent.get_next_path_position())

func _interrupt_current_action():
	if rotate_tween and rotate_tween.is_running():
		rotate_tween.kill()
	current_state = State.IDLE

func set_movement_target(target: Vector2):
	navigation_agent.target_position = target

func _start_moving():
	if navigation_agent.is_navigation_finished():
		return
	
	# 初始旋转
	_start_rotation(navigation_agent.get_next_path_position())

func _start_rotation(target_position: Vector2):
	current_state = State.ROTATING
	navigation_agent.set_velocity_forced(Vector2.ZERO)
	
	# 清除现有动画
	if rotate_tween and rotate_tween.is_valid():
		rotate_tween.kill()
	
	# 计算目标方向（使用全局位置）
	var direction_to_target = (target_position - global_position).normalized()
	var target_angle = direction_to_target.angle()
	
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
		current_state = State.MOVING
		return
	
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
		current_state = State.MOVING
	rotate_tween = null

func _on_velocity_computed(safe_velocity: Vector2):
	if can_move_while_rotating || current_state == State.MOVING:
		velocity = safe_velocity
		move_and_slide()
