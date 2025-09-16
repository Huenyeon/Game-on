
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
	

	# Connect each news button
	for i in range($NewsControl.get_child_count()):
		var child = $NewsControl.get_child(i)
		if child is TextureButton:
			child.pressed.connect(_on_news_item_pressed.bind(i))
			


func _on_news_item_pressed(index: int) -> void:
	# If window already exists, just bring it to front
	if index in open_windows and is_instance_valid(open_windows[index]):
		bring_window_to_front(open_windows[index])
		var existing_window: Node2D = open_windows[index]
		if !existing_window.visible:
			existing_window.visible = true
		return

	# Create new window
	var new_window = window_scene.instantiate()
	
	# Get the NewsWindow child and fix its position and scale
	var news_window = new_window.get_node("NewsWindow") as Node2D
	#if news_window:
		## RESET the problematic position and scale
		#news_window.position = Vector2.ZERO
		#news_window.scale = Vector2.ONE
	
	# Set up the window with data
	if new_window.has_method("setup_window"):
		var report = Global.active_reports[index]
		new_window.setup_window(index, self, report)

	# Set initial z-index and add to scene
	new_window.z_index = z_index_counter
	z_index_counter += 1
	add_child(new_window)
	
	# Now that it's in the scene tree, set its global position to the center of the viewport
	var viewport_size = get_viewport().get_visible_rect().size
	new_window.global_position = viewport_size / 4
	
	open_windows[index] = new_window
	

	print("Window spawned at: ", new_window.global_position)



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


func _on_red_note_1_pressed() -> void:
	print("redpressed")
	_activate_note("red", 1)


func _on_blue_note_1_pressed() -> void:
	_activate_note("blue", 2)
	print("bluepressed")


func _on_violet_note_1_pressed() -> void:
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
	
	
	Global.current_song_index = song_index
	Global.current_note_name = note_name
	Global._set_gamescene_song(song_index)  



func on_pressed_back_to_scene_button() -> void:
	# Close the overlay without reloading the game scene
	# Show the game controls again
	var current_scene = get_tree().current_scene
	if current_scene:
		var controls := current_scene.get_node_or_null("CanvasLayer/UIRoot/GameControls")
		if controls:
			controls.visible = true
		
		# Close paper when desktop is closed
		if current_scene.has_method("close_paper_if_open"):
			current_scene.close_paper_if_open()
		
		# Close stamp options when desktop is closed
		if current_scene.has_method("close_stamp_options_if_open"):
			current_scene.close_stamp_options_if_open()
	queue_free()
