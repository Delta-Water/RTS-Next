class_name UnitsManager
extends Node2D

@export var units_path: String = "res://scenes/units_manager/"

@onready var units: Node2D = $Units
@onready var select_region := $SelectRegion

var units_repository: Dictionary[String, PackedScene] = {} # 用于存放单位组件
var selected_units: Array[UnitBase1] = [] # 用于存放被选择的单位

func _ready() -> void:
	# 加载单位
	units_repository = _load_units(units_path)
	# 监听单位选择事件
	select_region.unit_enter.connect(func(unit):
		selected_units.push_back(unit)
	)
	select_region.unit_exit.connect(func(unit):
		var idx = selected_units.find(unit)
		if idx >= 0:
			selected_units.remove_at(idx)
	)
	select_region.clear_units.connect(func():
		self.selected_units.clear()
	)

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("select_units"):
		if Input.is_action_just_pressed("select_units"):
			select_region.enable = true
			select_region.start_point = get_global_mouse_position()
		else:
			select_region.end_point = get_global_mouse_position()
	elif Input.is_action_just_released("select_units"):
		select_region.enable = false

## 生成单位
func spawn_unit(type: String, unit_position: Vector2) -> UnitBase1:
	var scene: PackedScene = units_repository.get(type)
	var node: UnitBase1 = scene.instantiate()
	node.position = unit_position
	units.add_child(node)
	return node

## 自动加载单位场景
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
