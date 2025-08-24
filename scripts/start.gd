extends Button

func _on_pressed():
	# Pick 3 random reports and store them in Global.active_reports
	Global.get_random_reports(3)

	# Debug log
	print("Chosen reports this session:", Global.active_reports)

	# You can then change scene to your next scene
	get_tree().change_scene_to_file("res://YourDisplayScene.tscn")
