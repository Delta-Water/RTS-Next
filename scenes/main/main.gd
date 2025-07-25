extends Node2D

@onready var units: Units = %Units

func _ready() -> void:
	units.spawn_unit("combat_engineer", Vector2(20, 20))
