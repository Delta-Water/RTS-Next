extends TileMapLayer

var astar_grid = AStarGrid2D.new()
var cell_size = Vector2(20, 20)   # 单元格大小

func _ready():
	astar_grid.region = get_viewport_rect()
	astar_grid.cell_size = cell_size
	astar_grid.offset = cell_size / 2  # 路径点居中
	astar_grid.update()  # 生成网格
	
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES  # 允许对角线相邻存在至少一个无障碍中心点时启用对角线移动
	#astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN  # 曼哈顿
	
	#astar_grid.set_point_solid(Vector2i(12, 12), true)  # 在(12,12)处添加障碍
	astar_grid.jumping_enabled = true
	Core.tile_map = self

func get_path_grid(unit_position: Vector2, target_position: Vector2):
	var start_pos = self.local_to_map(unit_position)
	var end_pos = self.local_to_map(target_position)
	var path_grid = astar_grid.get_point_path(start_pos, end_pos)
	#if not path_grid.is_empty():
		#path_grid[-1] = target_position
		#return optimize(path_grid)
	#else:
		#return []
	return path_grid

#func optimize(original_path: Array):
	#var simplified = []
	## var last_direction: Vector2 = Vector2.ZERO
	#
	## 总是添加起点
	#simplified.append(original_path[0])
	#
	## 从第二个点开始遍历
	#for i in range(1, original_path.size() - 1):
		#var current = original_path[i]
		#var next = original_path[i + 1]
		#
		## 计算当前点与上一个点的方向
		#var prev_direction = (current - simplified.back()).normalized()
		#
		## 计算当前点与下一个点的方向
		#var next_direction = (next - current).normalized()
		#
		## 如果方向改变，保留当前点
		#if not prev_direction.is_equal_approx(next_direction):
			#simplified.append(current)
	#
	## 总是添加终点
	#simplified.append(original_path.back())
	#
	#return simplified
