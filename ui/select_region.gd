class_name SelectRegion
extends Node2D

@onready var display = %Display
#@onready var collision = %CollisionPolygon
@onready var region = %Region

@export var region_is_visible: bool = false
@export var objects: Array :
	get:
		var result = region.collision_result
		var new_objects = Array()
		for r in result:
			new_objects.push_back(r["collider"])
		return new_objects

var _opacity_tween

const FADING_ANIMATION_DURATION: float = 0.15

func _process(_delta: float) -> void:
	for object in objects:
		if object is Unit:
			object.is_selected = true

func kill_opacity_tween():
	if _opacity_tween != null:
		_opacity_tween.kill()
		_opacity_tween = null

func set_region(new_region: Rect2):
	var polygon = PackedVector2Array([
		new_region.position,
		new_region.position + Vector2(new_region.size.x, 0),
		new_region.position + new_region.size,
		new_region.position + Vector2(0, new_region.size.y),
	])
	display.polygon = polygon
	region.shape = RectangleShape2D.new()
	region.shape.size = new_region.size
	region.position = new_region.get_center()
	
	for obj in objects:
		if obj is Unit: obj.is_selected = false
	region.force_shapecast_update()
	for obj in objects:
		if obj is Unit: obj.is_selected = true
	
	if !region_is_visible:
		region_is_visible = true
		region.enabled = true
		display.visible = true
		if Env.is_animation_enabled:
			kill_opacity_tween()
			_opacity_tween = get_tree().create_tween()
			_opacity_tween.tween_property(display, "color:a", 0.3, FADING_ANIMATION_DURATION)
		else:
			display.color.a = 0.3
	
func clear_region():
	if region_is_visible:
		region_is_visible = false
		region.enabled = false
		if Env.is_animation_enabled:
			var hide_display = func():
				display.visible = false
			kill_opacity_tween()
			_opacity_tween = get_tree().create_tween()
			_opacity_tween.tween_property(display, "color:a", 0, FADING_ANIMATION_DURATION)
			_opacity_tween.tween_callback(hide_display).set_delay(FADING_ANIMATION_DURATION)
		else:
			display.color.a = 0.0
			display.visible = false
