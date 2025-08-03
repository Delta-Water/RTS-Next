extends Node2D

@onready var units_manager: UnitsManager = %UnitsManager

func _ready() -> void:
	#units_manager.spawn_unit("rts:heavy_missile_ship", Vector2(448, 128))
	units_manager.spawn_unit("rts:test_tank", Vector2(80, 80))
	units_manager.spawn_unit("rts:test_tank", Vector2(90, 80))
	units_manager.spawn_unit("rts:test_tank", Vector2(100, 80))
	units_manager.spawn_unit("rts:test_tank", Vector2(110, 80))
	units_manager.spawn_unit("rts:test_tank", Vector2(120, 80))
	units_manager.spawn_unit("rts:test_tank", Vector2(130, 80))
	units_manager.spawn_unit("rts:test_tank", Vector2(140, 80))
	units_manager.spawn_unit("rts:test_tank", Vector2(150, 80))
	units_manager.spawn_unit("rts:test_tank", Vector2(160, 80))
	units_manager.spawn_unit("rts:combat_engineer", Vector2(300, 300))
