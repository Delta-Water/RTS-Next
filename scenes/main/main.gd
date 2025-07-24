extends Node2D

@onready var units: Units = %Units

func _ready() -> void:
	units.spawn_unit("rts:combat_engineer", Vector2(20, 20))
