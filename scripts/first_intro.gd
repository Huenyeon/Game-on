extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var dialogue_label: Label = $Camera2D/CanvasLayer/Panel/Label 

var dialogues= [
	"As the bell rang, students hurried to their seats, notebooks and pens \n at the ready. The classroom buzzed with chatter as their \n teacher stood at the front, clearing her throat to begin.",
	"She spoke about a troubling matter spreading quickly—fake news \n that was fooling even the most careful readers.",
	"To prepare, she announced a new assignment: each student must learn \n to spot  the truth hidden among lies."]

var dialogue_index := 0
var typing_speed := 0.03
var typing_timer: Timer

var current_text := ""
var target_text := ""
var char_index := 0

func _ready():
	print("Camera found: ", camera != null)
	print("Dialogue label found: ", dialogue_label != null)
	
	# Start background music
	AudioManager.play_background_music()

	if camera:
		camera.make_current()
		var tween = create_tween()
		tween.tween_property(
			camera,
			"position",
			Vector2(camera.position.x + 500, camera.position.y),
			10.0
		)
		tween.finished.connect(_on_camera_pan_finished)
		print("Camera pan started")

	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.timeout.connect(_on_typewriter_step)
	add_child(typing_timer)

	show_dialogue()


func show_dialogue():
	if dialogue_index < dialogues.size():
		target_text = dialogues[dialogue_index]
		current_text = ""
		char_index = 0
		if dialogue_label:
			dialogue_label.text = ""
		typing_timer.start()
		print("Started typing dialogue: ", target_text)
	else:
		change_scene()

func _on_typewriter_step():
	if char_index < target_text.length():
		current_text += target_text[char_index]
		if dialogue_label:
			dialogue_label.text = current_text
		char_index += 1
	else:
		typing_timer.stop()
		# Auto advance after 1.5 seconds pause
		var auto_timer = get_tree().create_timer(1.5)
		auto_timer.timeout.connect(func():
			dialogue_index += 1
			show_dialogue()
		)


func _input(event):
	if event.is_action_pressed("ui_accept"):
		print("Input received: ui_accept")
		if not typing_timer.is_stopped():
			# Finish current line instantly
			typing_timer.stop()
			if dialogue_label:
				dialogue_label.text = target_text
			print("Skipped typing, showing full line: ", target_text)
		else:
			# Go to next line
			dialogue_index += 1
			print("Moving to dialogue index: ", dialogue_index)
			show_dialogue()

func _on_camera_pan_finished():
	print("Camera pan finished!")


func change_scene():
	print("Changing scene...")
	get_tree().change_scene_to_file("res://scene/intro_2.tscn")
