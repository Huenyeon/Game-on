extends Button

func on_pressed_button() -> void:
	# Close overlay if present; otherwise do nothing
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_node("InsideDesktop"):
		current_scene.get_node("InsideDesktop").queue_free()
