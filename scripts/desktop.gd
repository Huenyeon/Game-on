extends Control
func _on_desktop_clicked(event):
	# Only handle left mouse button presses
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Only play cursor effect if clicking on the actual desktop area
		# Check if the click is within the desktop bounds
		var desktop_rect = Rect2(Vector2.ZERO, size)
		var local_pos = get_local_mouse_position()
		
		# Only trigger if clicking within the desktop bounds
		if desktop_rect.has_point(local_pos):
			# Play cursor effect before changing scene
			GlobalCursorManager.play_press_effect()
			# Wait for effect to complete before changing scene
			await GlobalCursorManager.is_effect_playing()
			while GlobalCursorManager.is_effect_playing():
				await get_tree().process_frame
			get_tree().change_scene_to_file("res://scene/inside_desktop.tscn")
	# Ignore all other input events - don't trigger cursor effect


func _ready():
	# Show news by default, hide publishers
	$NewsContent.visible = true
	$PublishersContent.visible = false

	# Set News button pressed by default
	$NewsButton.button_pressed = true
	$PublishersButton.button_pressed = false

	# Connect button signals
	$NewsButton.pressed.connect(_on_news_button_pressed)
	$PublishersButton.pressed.connect(_on_publisher_button_pressed)
	
	$".".mouse_filter = Control.MOUSE_FILTER_STOP
	$".".gui_input.connect(_on_desktop_clicked)


func _on_news_button_pressed():
	$NewsContent.visible = true
	$PublishersContent.visible = false
	$NewsButton.button_pressed = true
	$PublishersButton.button_pressed = false


func _on_publisher_button_pressed():
	$NewsContent.visible = false
	$PublishersContent.visible = true
	$NewsButton.button_pressed = false
	$PublishersButton.button_pressed = true
	
