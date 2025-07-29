class_name UnitsManager
extends Node2D

@export var units_path: String = "res://scenes/units_manager/"
## 为`false`时关闭下属节点的交互（单位选择框）。
@export var enable_interactions: bool = true :
	set(val):
		enable_interactions = val
		select_region.enable = false
		_mouse_origin = null

@onready var units: Node2D = $Units
@onready var canvas_manager: Node2D = $CanvasManager
@onready var select_region := $SelectRegion

## 点击信号，当`select_units`按下后鼠标未移动超过一定距离就松开时触发。
signal click

## 用于存放单位组件
var units_repository: Dictionary[String, PackedScene] = {}
## 用于存放被选择的单位
var selected_units: Array[UnitBase1] = []

## 存放鼠标按下的位置。因为需要`null`区分有没有按下鼠标，所以不标识类型。
var _mouse_origin = Vector2.ZERO

func _ready() -> void:
	# 加载单位
	units_repository = _load_units(units_path)
	# 监听单位选择事件
	select_region.unit_enter.connect(func(unit):
		unit.change_selected_state(true)
		selected_units.push_back(unit)
	)
	select_region.unit_exit.connect(func(unit):
		unit.change_selected_state(false)
		var idx = selected_units.find(unit)
		if idx >= 0:
			selected_units.remove_at(idx)
	)
	select_region.clear_units.connect(func():
		for unit in selected_units:
			unit.change_selected_state(false)
		selected_units.clear()
	)
	
	click.connect(_move_selected_units)

func _input(event: InputEvent) -> void:
	if enable_interactions:
		if Input.is_action_pressed("select_units"):
			if select_region.enable:
				select_region.end_point = get_global_mouse_position()
			elif event.is_action_pressed("select_units"):
				_mouse_origin = get_local_mouse_position()
			elif _mouse_origin != null && (_mouse_origin - get_local_mouse_position()).length_squared() > 64.0:
				select_region.start_point = get_global_mouse_position()
				select_region.enable = true
		elif event.is_action_released("select_units"):
			if select_region.enable:
				select_region.enable = false
			else:
				click.emit()
			_mouse_origin = null

func _move_selected_units() -> void:
	for unit: UnitBase1 in selected_units:
		unit.set_movement_target(get_global_mouse_position())

## 生成单位
func spawn_unit(type: String, unit_position: Vector2) -> UnitBase1:
	var scene: PackedScene = units_repository.get(type)
	var node: UnitBase1 = scene.instantiate()
	node.position = unit_position
	canvas_manager.create_canvas_for_unit(node)
	units.add_child(node)
	return node

## 从文件夹加载单位。
## 扫描`dir_path`，尝试加载子目录中的`${目录名}.tscn`场景文件，
## 并以`${mod_namespace}:${目录名}`为键存入返回的字典中。
func _load_units(dir_path: String, mod_namespace: String = "rts") -> Dictionary[String, PackedScene]:
	# 确保路径以斜杠结尾
	if not dir_path.ends_with("/"):
		dir_path += "/"
	
	var dictionary: Dictionary[String, PackedScene] = {}
	var dir = DirAccess.open(dir_path)
	
	if not dir:
		push_error("无法打开单位目录: " + dir_path)
		return dictionary  # 返回空字典而不是null
	
	# 开始遍历目录
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		# 跳过隐藏文件和上级目录
		if folder_name.begins_with(".") or folder_name == "..":
			folder_name = dir.get_next()
			continue
		
		# 只处理文件夹
		if dir.current_is_dir():
			# 构建单位场景路径
			var unit_scene_path = dir_path.path_join(folder_name).path_join(folder_name + ".tscn")
			
			# 检查文件是否存在
			if FileAccess.file_exists(unit_scene_path):
				# 加载单位场景
				var unit_scene = load(unit_scene_path)
				
				if unit_scene is PackedScene:
					var unit_id = "{0}:{1}".format([mod_namespace, folder_name])
					dictionary[unit_id] = unit_scene
					print("成功加载单位: ", unit_id)
				else:
					push_error("加载失败: " + unit_scene_path + " 不是有效的PackedScene资源")
			else:
				push_error("单位场景文件不存在: " + unit_scene_path)
		
		folder_name = dir.get_next()
	
	return dictionary
