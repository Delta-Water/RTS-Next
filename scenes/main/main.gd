extends Node2D

@onready var units: Units = %Units
@onready var select_region := %SelectRegion

func _ready() -> void:
	#units.spawn_unit("rts:combat_engineer", Vector2(20, 20))
	select_region.unit_enter.connect(func(unit):
		units.selected_units.push_back(unit)
	)
	select_region.unit_exit.connect(func(unit):
		var idx = units.selected_units.find(unit)
		if idx >= 0:
			units.selected_units.remove_at(idx)
	)
	select_region.clear_units.connect(func():
		units.selected_units.clear()
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
