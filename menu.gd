extends Node2D

func _on_start_pressed() -> void:
	# Play cursor effect
	GlobalCursorManager.play_press_effect()
	# Wait for effect to complete before changing scene
	await GlobalCursorManager.is_effect_playing()
	while GlobalCursorManager.is_effect_playing():
		await get_tree().process_frame
	get_tree().change_scene_to_file("res://scene/game_scene.tscn")
	

func _on_quit_pressed() -> void:
	# Play cursor effect
	GlobalCursorManager.play_press_effect()
	# Wait for effect to complete before quitting
	await GlobalCursorManager.is_effect_playing()
	while GlobalCursorManager.is_effect_playing():
		await get_tree().process_frame
	get_tree().quit()
