extends Button

func on_pressed_button() -> void:
	get_tree().change_scene_to_file("res://scene/game_scene.tscn")
