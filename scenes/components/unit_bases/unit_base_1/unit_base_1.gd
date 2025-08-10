class_name UnitBase1
extends RigidBody2D

enum State { IDLE, ROTATING, SLIDING }

enum Ability {
	Land = 0b0001,
	Water = 0b0010,
	Cliff = 0b0100,
	Air = 0b0111,
}

@export_flags("Land", "Water", "Cliff", "Air") var ability: int = Ability.Land :
	set(val):
		var out_collision_mask: int = 0b1111_0000
		if (val & Ability.Land) != 0:
			out_collision_mask ^= 0b0010_0000
			if (val & Ability.Cliff) != 0:
				out_collision_mask ^= 0b1000_0000
		if (val & Ability.Water) != 0:
			out_collision_mask ^= 0b0001_0000
		ability = val
		
		if !is_node_ready():
			return
		var maps := get_tree().get_nodes_in_group("maps")[0] as Maps
		if !maps:
			push_error("Got a map having incorrect type")
			return 
		if map_rigid_body:
			map_rigid_body.collision_mask = out_collision_mask
		if navigation_agent_2d:
			navigation_agent_2d.set_navigation_map(maps.request_navigation_layer_for_mask(out_collision_mask))

# 移动属性
@export var acceleration: float = 100.0
@export var deceleration: float = 100.0
@export var max_speed: float = 50.0
var decelerating_distance = (max_speed * max_speed) / (2 * deceleration)

# 旋转属性
@export var rotate_acceleration: float = 10.0
@export var rotate_deceleration: float = 10.0
@export var max_rotate_speed: float = 5
var decelerating_angle = (max_rotate_speed * max_rotate_speed) / (2 * rotate_deceleration)

## 是否能够边移动边旋转
@export var can_move_while_rotating: bool = true

## 碰撞体积半径。（与避障半径自动关联）
@export_range(0.1, 50.0, 0.1, "or_greater")
var radius: float = 10.0:
	set(val):
		radius = val
		if collision_shape_2d and navigation_agent_2d:
			(collision_shape_2d.shape as CircleShape2D).radius = val
			navigation_agent_2d.radius = val

## 显示体积半径。
@export_range(0.1, 50.0, 0.1, "or_greater")
var display_radius: float = 10.0

## 同步碰撞体积和显示体积的半径。
func set_both_radius(new_radius: float) -> void:
	radius = new_radius
	display_radius = new_radius

# 运行时变量
var current_state: State = State.IDLE
var is_selected: bool = false
var target_position:Vector2 = Vector2(0, 0)
var _delta: float

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var map_rigid_body: RigidBody2D = $MapRigidBody

func _ready() -> void:
	# 在设置静态障碍之前不要启用
	navigation_agent_2d.velocity_computed.connect(_on_velocity_computed)
	
	# 再次调用set函数保证子节点属性被正确赋值
	radius = radius
	display_radius = display_radius
	ability = ability
# 更新障碍物状态

func _on_velocity_computed(safe_velocity: Vector2):
	# 计算需要施加的力 (F = m * a)
	# 加速度 = (期望速度 - 当前速度) / delta
	var force = mass * (safe_velocity - linear_velocity) / _delta
	
	# 应用力
	apply_central_force(force)

## 设置移动目标
func set_movement_target(target: Vector2):
	_interrupt_current_action()
	target_position = target
	navigation_agent_2d.target_position = target
	current_state = State.SLIDING

func _interrupt_current_action():
	current_state = State.IDLE
	# 停止所有物理运动
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

func _physics_process(delta: float):
	_delta = delta
	match current_state:
		State.IDLE:
			# 使用阻尼使物体自然停止
			apply_central_force(-linear_velocity * mass * 10)
			apply_torque(-angular_velocity * inertia * 10)
		
		State.ROTATING:
			_monitor_velocity_direction(delta)
			if can_move_while_rotating:
				_perform_move(delta)
			else:
				# 旋转前保持静止
				apply_central_force(-linear_velocity * mass * 10)
		
		State.SLIDING:
			_monitor_velocity_direction(delta)
			_perform_move(delta)

func _monitor_velocity_direction(delta: float):
	if linear_velocity != Vector2.ZERO:
		var target_angle = linear_velocity.angle()
		rotation = wrapf(rotation, -PI, PI)
		var angle_diff = abs(target_angle - rotation)
		var rotation_direction: int = 1
		
		if rotation >= target_angle:
			rotation_direction = -1
		if angle_diff > PI:
			angle_diff = 2 * PI - angle_diff
			rotation_direction *= -1
		
		# 微小角度直接设置
		if angle_diff <= 0.005:
			rotation = target_angle
			_on_rotation_finished()
			return
		else:
			_perform_rotation(angle_diff, rotation_direction, delta)

func _perform_move(delta):
	if navigation_agent_2d.is_navigation_finished():
		current_state = State.IDLE
		return
	
	var next_path_pos = navigation_agent_2d.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	var distance_to_target: float
	var current_speed: float = linear_velocity.length()
	var current_decelerating_distance: float
	var new_speed: float
	
	if can_move_while_rotating:
		distance_to_target = global_position.distance_to(navigation_agent_2d.target_position)
	else:
		distance_to_target = global_position.distance_to(next_path_pos)
	
	if current_speed < max_speed:
		current_decelerating_distance = current_speed * current_speed / (2 * deceleration)
	else:
		current_decelerating_distance = decelerating_distance
	
	if distance_to_target > current_decelerating_distance:
		if current_speed < max_speed:
			new_speed = min(current_speed + acceleration * delta, max_speed)
		else:
			new_speed = max_speed
	else:
		new_speed = max(current_speed - deceleration * delta, 0)
	
	# 计算期望速度向量
	var desired_velocity = direction * new_speed
	
	# 没有启用避障之前不要取消注释
	if navigation_agent_2d.avoidance_enabled:
		#print("b: ", direction * new_speed)
		navigation_agent_2d.set_velocity(desired_velocity)
	else:
		_on_velocity_computed(desired_velocity)
		
	## 计算需要施加的力 (F = m * a)
	## 加速度 = (期望速度 - 当前速度) / delta
	#var force = mass * (desired_velocity - linear_velocity) / delta
	#
	## 应用力
	#apply_central_force(force)

## 旋转
func _perform_rotation(diff_angle: float, rotation_direction: int, delta: float):
	current_state = State.ROTATING
	var new_rotate_speed: float
	var current_decelerating_angle: float
	
	if angular_velocity < max_rotate_speed:
		current_decelerating_angle = angular_velocity * angular_velocity / (2 * rotate_deceleration)
	else:
		current_decelerating_angle = decelerating_angle
	
	if diff_angle > current_decelerating_angle:
		if angular_velocity < max_rotate_speed:
			new_rotate_speed = min(angular_velocity + rotate_acceleration * delta, max_rotate_speed)
		else:
			new_rotate_speed = max_rotate_speed
	else:
		new_rotate_speed = max(angular_velocity - rotate_deceleration * delta, 0)
	
	var torque = rotation_direction * inertia * (new_rotate_speed - angular_velocity) / delta
	apply_torque(torque)

func _on_rotation_finished():
	if current_state == State.ROTATING:  # 防止中断后仍切换状态
		if navigation_agent_2d.is_navigation_finished():
			current_state = State.IDLE
		else:
			current_state = State.SLIDING

func change_selected_state(state: bool):
	is_selected = state
