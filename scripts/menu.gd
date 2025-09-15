extends Node2D

func _ready():
	randomize()
	
	
func _on_start_pressed() -> void:
	#generate news reports
	var rand_num = randi_range(1, 3)
	print("Random number:", rand_num)
	
	# Call your singleton's function
	Global.get_random_reports(rand_num)
	Global.get_random_student_reports(rand_num)
	
	# Print them nicely
	for report in Global.active_reports:
		print("==========================")
		print("Publisher:", report["publisher"])
		print("Date:", report["published_date"])
		print("Headline:", report["headline"])
		print("Who:", report["who"])
		print("What:", report["what"])
		print("Where:", report["where"])
		print("When:", report["when"])
		print("Why:", report["why"])
		print("More info:", report["body"])
		print("==========================")
		
	print("\n--- Student Reports ---")
	for student_report in Global.correct_student_report:
		print("==========================")
		print("Publisher:", student_report["publisher"])
		print("Date:", student_report["published_date"])
		print("Headline:", student_report["headline"])
		print("Who:", student_report["who"])
		print("What:", student_report["what"])
		print("Where:", student_report["where"])
		print("When:", student_report["when"])
		print("Why:", student_report["why"])
		print("More info:", student_report["body"])
		print("==========================")
	
	print("\n--- Student Reports (Incorrect) ---")
	for student_report in Global.incorrect_student_report:
		print("==========================")
		print("Publisher:", student_report["publisher"])
		print("Date:", student_report["date"])
		print("Headline:", student_report["headline"])
		print("Who:", student_report["who"])
		print("What:", student_report["what"])
		print("Where:", student_report["where"])
		print("When:", student_report["when"])
		print("Why:", student_report["why"])
		print("More info:", student_report["body"])
		print("==========================")
		
	# Cursor effect will play automatically via global input
	# Change scene immediately
	get_tree().change_scene_to_file("res://scene/node_2d.tscn")
	

func _on_quit_pressed() -> void:
	# Cursor effect will play automatically via global input
	# Quit immediately
	get_tree().quit()
