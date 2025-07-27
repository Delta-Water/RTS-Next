extends Node2D

@onready var units_manager: UnitsManager = %UnitsManager

func _ready() -> void:
	#units_manager.spawn_unit("rts:scout", Vector2(20, 40))
	units_manager.spawn_unit("rts:scout", Vector2(20, 80))
	units_manager.spawn_building("rts:mech_factory", Vector2i(2, 0))
