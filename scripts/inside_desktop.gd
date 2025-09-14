extends Node2D

@onready var window_scene = preload("res://scene/window.tscn")

var open_windows := {}
var z_index_counter := 0
var current_note_pressed: String = ""  # tracks which note is currently active

func _ready():
	$NewsControl.visible = true
	$MuscifyControls.visible = false
	$MuscifyBgBig.visible = false
	$AnimatedSprite2D.visible = false
	
	$Credible.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	$Muscify.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Connect each news button
	for i in range($NewsControl.get_child_count()):
		var child = $NewsControl.get_child(i)
		if child is TextureButton:
			child.pressed.connect(_on_news_item_pressed.bind(i))
			
	#Global._set_gamescene_song(1)

func _on_news_item_pressed(index: int):
	# If window already exists, just bring it to front
	if index in open_windows and is_instance_valid(open_windows[index]):
		bring_window_to_front(open_windows[index])
		return

	# Create new window
	var new_window = window_scene.instantiate()
	var cam = get_viewport().get_camera_2d()
	if cam:
		var cam_pos = cam.global_position
		var sprite = new_window.get_node("Sprite2D")
		if sprite and sprite.texture:
			var window_size = sprite.texture.get_size()
			new_window.position = cam_pos - (window_size / 2)
		else:
			new_window.position = cam_pos
	
	# Set up the window with data
	if new_window.has_method("setup_window"):
		var report = Global.active_reports[index]
		new_window.setup_window(index, self, report)
	
	# Set initial z-index and add to scene
	new_window.z_index = z_index_counter
	z_index_counter += 1
	add_child(new_window)  # Add directly to main scene
	open_windows[index] = new_window

func bring_window_to_front(window):
	window.z_index = z_index_counter
	z_index_counter += 1

func remove_window(index):
	if index in open_windows:
		open_windows.erase(index)

func _on_back_button_pressed():
	# Close all windows when going back
	for index in open_windows.keys():
		if is_instance_valid(open_windows[index]):
			open_windows[index].queue_free()
	open_windows.clear()


func _on_muscify_button_press():
	$MuscifyControls.visible = true
	$NewsControl.visible = false
	$MuscifyBgBig.visible=true
	$AnimatedSprite2D.visible = true
	


func _on_news_pressed() -> void:
	$MuscifyControls.visible = false
	$NewsControl.visible = true
	$MuscifyBgBig.visible= false
	$AnimatedSprite2D. visible = false


func _on_RedNote_pressed() -> void:
	print("redpressed")
	_activate_note("red", 1)

func _on_BlueNote_pressed() -> void:
	_activate_note("blue", 2)
	print("bluepressed")
	

func _on_VioletNote_pressed() -> void:
	print("violetpressed")
	_activate_note("violet", 3)

func _activate_note(note_name: String, song_index: int):
	if current_note_pressed == note_name:
		return
		
	if current_note_pressed != "":
		var prev_color_rect = $MuscifyControls.get_node("%sNote1/ColorRect" % current_note_pressed.capitalize())
		prev_color_rect.color = Color(0,0,0,0)  
		
	var new_color_rect = $MuscifyControls.get_node("%sNote1/ColorRect" % note_name.capitalize())
	new_color_rect.color = Color("#424747cc")  
	current_note_pressed = note_name
	
	# Update global song index AND note name separately
	Global.current_song_index = song_index
	Global.current_note_name = note_name
	Global._set_gamescene_song(song_index)  # Only pass the index


	


func _on_leave_button_pressed() -> void:
	var game_scene = load("res://scene/game_scene.tscn").instantiate()
	get_tree().root.add_child(game_scene)
	get_tree().current_scene.queue_free()  # Remove current scene
	get_tree().current_scene = game_scene  # Set new current scene
