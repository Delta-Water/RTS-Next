extends Node2D

@onready var units_manager: UnitsManager = %UnitsManager

func _ready() -> void:
	units_manager.spawn_unit("rts:scout", Vector2(20, 40))
	units_manager.spawn_unit("rts:combat_engineer", Vector2(20, 80))
