extends Button

func on_pressed_button() -> void:
	# Close overlay if present; otherwise do nothing
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_node("InsideDesktop"):
		current_scene.get_node("InsideDesktop").queue_free()
	
	# Reset global state and change scene
	Global.player_has_reached_middle = false
	Global.reset_report_tracking()
	get_tree().change_scene_to_file("res://scene/game_scene.tscn")
