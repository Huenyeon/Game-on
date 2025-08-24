extends Node2D

func _ready():
	randomize()
	# Connect the button's pressed signal to this script
	$Control/start.pressed.connect(_on_start_pressed)
	
	
func _on_start_pressed() -> void:
	#generate news reports
	
	# Call your singleton’s function
	Global.get_random_reports(3)
	# Print them nicely
	for report in Global.active_reports:
		print("==========================")
		print("Publisher:", report["publisher"])
		print("Date:", report["date"])
		print("Headline:", report["headline"])
		print("Who:", report["who"])
		print("What:", report["what"])
		print("Where:", report["where"])
		print("When:", report["when"])
		print("Why:", report["why"])
		print("More info:", report["body"])
		print("==========================")
	
	get_tree().change_scene_to_file("res://scene/game_scene.tscn")
	

func _on_quit_pressed() -> void:
	get_tree().quit()
