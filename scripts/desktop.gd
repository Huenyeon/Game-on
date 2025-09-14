extends Control
func _on_desktop_clicked(event):
	# Only handle left mouse button presses
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if dialog is still active
		var game_scene = get_tree().current_scene
		if game_scene and game_scene.has_method("is_interaction_allowed"):
			if not game_scene.is_interaction_allowed():
				print("Cannot interact with desktop - dialog is still playing")
				return
		
		
		# Check if the click is within the desktop bounds first
		var desktop_rect = Rect2(Vector2.ZERO, size)
		var local_pos = get_local_mouse_position()
		
		# Only trigger if clicking within the desktop bounds
		if desktop_rect.has_point(local_pos):
			var current_scene = get_tree().current_scene
			
			# Close paper if open when clicking desktop
			if current_scene and current_scene.has_method("close_paper_if_open"):
				current_scene.close_paper_if_open()
			
			# Close clipboard if open when clicking desktop
			if current_scene and current_scene.has_method("close_clipboard_if_open"):
				current_scene.close_clipboard_if_open()
			
			# Check if desktop is already open
			if current_scene and current_scene.has_node("InsideDesktop"):
				print("Desktop already open - closing desktop overlay")
				
				# Force release any active pens when closing desktop
				if current_scene.has_method("close_pen_interactions_if_open"):
					current_scene.close_pen_interactions_if_open()
					print("Pen interactions force released when desktop closed")
				
				# Close the desktop overlay
				var inside_desktop = current_scene.get_node("InsideDesktop")
				if inside_desktop:
					inside_desktop.queue_free()
				
				# Show game controls again
				var controls := current_scene.get_node_or_null("CanvasLayer/UIRoot/GameControls")
				if controls:
					controls.visible = true
					print("Game controls shown")
				
				print("Desktop closed")
			else:
				print("Desktop clicked - opening desktop overlay")
				
				# Close paper, stamp options, and pen interactions when desktop opens
				if current_scene.has_method("close_paper_if_open"):
					current_scene.close_paper_if_open()
					print("Paper closed when desktop opened")
				if current_scene.has_method("close_stamp_options_if_open"):
					current_scene.close_stamp_options_if_open()
					print("Stamp options closed when desktop opened")
				if current_scene.has_method("close_pen_interactions_if_open"):
					current_scene.close_pen_interactions_if_open()
					print("Pen interactions closed when desktop opened")
				
				# Open inside_desktop as an overlay instead of changing the whole scene
				if current_scene and not current_scene.has_node("InsideDesktop"):
					print("Creating InsideDesktop overlay")
					var inside_desktop_scene: PackedScene = load("res://scene/inside_desktop.tscn")
					var overlay = inside_desktop_scene.instantiate()
					# Ensure the root node keeps its name for lookup when closing
					overlay.name = "InsideDesktop"
					current_scene.add_child(overlay)
					print("InsideDesktop overlay added to scene")
					# Hide top-left controls while desktop is open
					var controls := current_scene.get_node_or_null("CanvasLayer/UIRoot/GameControls")
					if controls:
						controls.visible = false
						print("Game controls hidden")
				else:
					print("InsideDesktop already exists, not creating new one")
	# Ignore all other input events - don't trigger cursor effect


func _ready():
	# Start background music
	AudioManager.play_background_music()
	
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
		# Force all children to inherit scale
	for child in get_children():
		if child is CanvasItem:
			child.scale = scale


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
	
