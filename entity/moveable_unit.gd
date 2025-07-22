class_name MoveableUnit
extends Unit

var delta_speed: float = 0
var retrace_counter: int = 0
var retrace_critical_value: int = 120
var max_speed: float = 100
var acceleration: float = 7

func _ready() -> void:
	super._ready()
	linear_damp = 20

func accelerate_to(target_velocity: Vector2):
	var delta = target_velocity - linear_velocity
	if delta.length() < acceleration:
		linear_velocity += delta
	else:
		linear_velocity += delta.normalized() * acceleration
