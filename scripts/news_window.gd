extends Sprite2D
class_name NewsWindow

var dragging = false
var of = Vector2.ZERO

func _process(delta: float) -> void:
	if dragging:
		var new_pos = get_global_mouse_position() - of

		var cam := get_viewport().get_camera_2d()
		if cam and texture:
			# Get the camera's actual visible world area
			var viewport_size = get_viewport().get_visible_rect().size
			var zoom = cam.zoom
			var cam_center = cam.global_position
			
			# Calculate the camera's world boundaries
			var cam_world_left = cam_center.x - (viewport_size.x / 2.0) / zoom.x
			var cam_world_right = cam_center.x + (viewport_size.x / 2.0) / zoom.x
			var cam_world_top = cam_center.y - (viewport_size.y / 2.0) / zoom.y
			var cam_world_bottom = cam_center.y + (viewport_size.y / 2.0) / zoom.y
			
			var tex_size = texture.get_size()
			
			# Clamp position to keep sprite fully visible
			new_pos.x = clamp(
				new_pos.x,
				cam_world_left,  # Can't go past left edge
				cam_world_right - tex_size.x  # Can't go past right edge
			)

			new_pos.y = clamp(
				new_pos.y,
				cam_world_top,  # Can't go past top edge
				cam_world_bottom - tex_size.y  # Can't go past bottom edge
			)

		global_position = new_pos

func _on_button_button_down() -> void:
	dragging = true
	of = get_global_mouse_position() - global_position

func _on_button_button_up() -> void:
	dragging = false
	
func _on_close_window_button_pressed():
	print("Closing window: ", name)
	queue_free()  # Remove the window from the scene
	
