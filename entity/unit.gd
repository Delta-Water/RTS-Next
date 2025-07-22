class_name Unit
extends RigidBody2D

## 该单位所在的世界
@export var world: RtsWorld = null

var _collision_area: RtsCollisionArea
## 用于创建碰撞区域和碰撞区域显示节点的Object。
## 被赋值时会自动删除旧节点，更新`collision_shape`和`area_display`并插入。
var collision_area: RtsCollisionArea :
	set(val):
		if collision_shape != null:
			collision_area.queue_free()
			collision_area = null
		if area_display != null:
			area_display.queue_free()
			area_display = null
		_collision_area = val
		if val != null:
			collision_shape = val.build_collision_shape()
			add_child.call_deferred(collision_shape)
			area_display = val.build_area_display()
			area_display.visible = false
			add_child.call_deferred(area_display)
	get(): return _collision_area

## 实际提供碰撞区域的节点，更新`collision_area`时自动更新。
## 也可以创建自己的逻辑更新该节点。
var collision_shape: CollisionShape2D

## 显示碰撞区域的节点，更新`collision_area`时自动更新。
## 也可以创建自己的逻辑更新该节点。
var area_display: Node2D

## 标识该单位是否被`SelectRegion`选中
var is_selected: bool = false :
	get: return is_selected
	set(value):
		is_selected = value
		area_display.visible = value

var _unit_id: int = randi()
## 单位的唯一标识符，随机数生成。
## 只读。
var unit_id: int :
	get: return _unit_id

## 获取单位的类型id，该id由具体实现指定，未实现时默认返回`rts:basic_unit`并输出一个警告。
func get_unit_type_id() -> String:
	push_warning("Trying to access an unit's type id, which is not specified by its implementation")
	return "rts:basic_unit"

var unit_type_id: String :
	get: return get_unit_type_id()

var ability: int = PathFinding.ABILITY_LAND

func _ready() -> void:
	collision_layer = CollisionGroup.UNIT
	collision_mask = CollisionGroup.UNIT
	lock_rotation = true
	if world != null && !world.is_node_ready():
		world.ready.connect(_world_ready)
	else:
		_world_ready()

## 可被覆盖的回调函数。
## 触发条件：当前节点已Ready且associated `world`也已Ready.
func _world_ready() -> void:
	pass

## 使用`RtsCollisionArea`注册单位的碰撞体积和轮廓显示。
## 不调用这个方法也可以，不过需要手动添加`RigidBody2D`的形状，设置property `area_display`。
func init_collision_area(area: RtsCollisionArea):
	collision_area = area

## 初始化瓦片碰撞体。
## 瓦片碰撞体通过一个`PinJoint2D`与父节点固定住。
func init_tile_collision():
	var sub_body = RigidBody2D.new()
	sub_body.lock_rotation = true
	sub_body.mass = mass
	sub_body.collision_layer = CollisionGroup.UNIT_TILE
	sub_body.collision_mask = PathFinding.ability_to_collision_mask(ability)
	var sub_body_area = CollisionShape2D.new()
	var sub_body_shape = CircleShape2D.new()
	sub_body_shape.radius = world.map_manager.terrain_layer.tile_set.tile_size.x * 0.47
	sub_body_area.shape = sub_body_shape
	sub_body.add_child(sub_body_area)
	
	var pin = PinJoint2D.new()
	pin.disable_collision = true
	pin.bias = 3
	pin.softness = 1
	
	var lets_pin = func():
		add_child(sub_body)
		pin.node_a = get_path()
		pin.node_b = sub_body.get_path()
		add_child(pin)
	
	lets_pin.call_deferred()

func debug_dump():
	print("Dumping unit {} ({}) information:".format([get_unit_type_id(), unit_id]))
	print("    mass = {}".format(mass))
