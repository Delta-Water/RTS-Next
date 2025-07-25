class_name Units
extends Node2D

@export var units_path: String = "res://scenes/units/"

var units_repository: Dictionary[String, PackedScene] = {} # 用于存放单位组件
var selected_units: Array = []

func _ready() -> void:
	units_repository = _load_units(units_path)
	print(units_repository)

func _input(event):
	# 监听单位移动事件
	# 监听单位选择事件
	pass

## 生成单位
func spawn_unit(type: String, unit_position: Vector2) -> UnitBase1:
	var scene: PackedScene = units_repository.get(type)
	var node: UnitBase1 = scene.instantiate()
	node.position = unit_position
	add_child(node)
	return node

# 单位选择逻辑
func _select_units():
	pass

func _load_units(dir_path: String) -> Dictionary[String, PackedScene]:
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
					dictionary[folder_name] = unit_scene
					print("成功加载单位: ", folder_name)
				else:
					push_error("加载失败: " + unit_scene_path + " 不是有效的PackedScene资源")
			else:
				push_error("单位场景文件不存在: " + unit_scene_path)
		
		folder_name = dir.get_next()
	
	return dictionary
