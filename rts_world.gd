extends Node2D
class_name RtsWorld

var select_region_origin
var drag_camera_origin
var is_click: bool = true

@onready var select_region: SelectRegion = %SelectRegion
@onready var main_camera: Camera2D = %MainCamera
@onready var map_manager: RtsMapManager = %MapManager

signal click;
	
func _input(_event: InputEvent) -> void:
	if Input.is_action_pressed("select_region"):
		if select_region_origin == null:
			select_region_origin = %MainCamera.get_global_mouse_position()
			is_click = true
		else:
			var current_mouse = %MainCamera.get_global_mouse_position()
			if is_click && (current_mouse - select_region_origin).length() > 5:
				is_click = false
			if !is_click:
				%SelectRegion.set_region(Utility.create_rect2_from_points(select_region_origin, current_mouse))
	elif select_region_origin != null:
		select_region_origin = null
	if Input.is_action_just_released("select_region"):
		if is_click:
			click.emit()
		else:
			%SelectRegion.clear_region()
	
	if Input.is_action_pressed("drag_camera"):
		if drag_camera_origin != null:
			var current_mouse = %MainCamera.get_local_mouse_position()
			var camera_delta = drag_camera_origin - current_mouse
			%MainCamera.position += camera_delta
		drag_camera_origin = %MainCamera.get_local_mouse_position()
	elif drag_camera_origin != null:
		drag_camera_origin = null
	
	if Input.is_action_just_pressed("delete"):
		for obj in %SelectRegion.objects:
			obj.queue_free()
