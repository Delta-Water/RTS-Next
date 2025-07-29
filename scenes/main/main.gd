extends Node2D

@onready var units_manager: UnitsManager = %UnitsManager

func _ready() -> void:
	units_manager.spawn_unit("rts:heavy_missile_ship", Vector2(448, 128))
	units_manager.spawn_unit("rts:test_tank", Vector2(80, 80))
	units_manager.spawn_unit("rts:combat_engineer", Vector2(300, 300))
