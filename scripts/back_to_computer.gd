extends Button

func on_pressed_button() -> void:
	Global.player_has_reached_middle = false
	Global.reset_report_tracking()
	get_tree().change_scene_to_file("res://scene/game_scene.tscn")
