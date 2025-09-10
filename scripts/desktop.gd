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
			# Open inside_desktop as an overlay instead of changing the whole scene
			var current_scene = get_tree().current_scene
			if current_scene and not current_scene.has_node("InsideDesktop"):
				var inside_desktop_scene: PackedScene = load("res://scene/inside_desktop.tscn")
				var overlay = inside_desktop_scene.instantiate()
				# Ensure the root node keeps its name for lookup when closing
				overlay.name = "InsideDesktop"
				current_scene.add_child(overlay)
				# Hide top-left controls while desktop is open
				var controls := current_scene.get_node_or_null("CanvasLayer/UIRoot/GameControls")
				if controls:
					controls.visible = false
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
	
