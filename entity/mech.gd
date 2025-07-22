class_name Mech
extends MoveableUnit

var path_finding: PathFinding
var desired_path: PackedVector2Array

func get_unit_type_id() -> String:
	return "rts:mech"

func _world_ready() -> void:
	world.click.connect(_on_click)
	init_collision_area(RtsCollisionArea.new_circle(20))
	init_tile_collision()
	path_finding = PathFinding.new(world.map_manager, PathFinding.ABILITY_LAND)

func _on_click() -> void:
	var mouse_position = get_global_mouse_position()
	path_finding.sync_terrain_layer()
	desired_path = path_finding.query_global_path(global_position, mouse_position)
	path_finding.clear()
	print(desired_path)

func _process(_delta: float) -> void:
	if !desired_path.is_empty():
		var next = desired_path[0]
		accelerate_to(global_position.direction_to(next).normalized() * max_speed)
		
		if (next - global_position).length_squared() < 10:
			desired_path.remove_at(0)
	
