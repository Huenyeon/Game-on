extends Node2D

func _ready():
	# Default visibility
	$NewsControl.visible = true
	$NewsDetails.visible = false

	# Connect back button
	$NewsDetails/BackButton.pressed.connect(_on_back_button_pressed)

	for i in range($NewsControl.get_child_count()):
		var sprite = $NewsControl.get_child(i)
		if sprite is Sprite2D:
			sprite.input_event.connect(_on_news_item_input.bind(i))


func _on_news_item_input(viewport, event, shape_idx, index):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_news_item_pressed(index)

func _on_news_button_pressed():
	# Cursor effect will play automatically via global input
	#$NewsControl.visible = true
	#$PublishersContent.visible = false
	#$NewsDetails.visible = false
	#$NewsButton.button_pressed = true
	#$PublishersButton.button_pressed = false
	pass


func _on_publisher_button_pressed():
	# Cursor effect will play automatically via global input
	#$NewsControl.visible = false
	#$PublishersContent.visible = true
	#$NewsDetails.visible = false
	#$NewsButton.button_pressed = false
	#$PublishersButton.button_pressed = true
	pass


func _on_news_item_pressed(index: int):
	# Hide news list
	$NewsDetails.visible = true
	$Button.visible = false
	#$PublishersButton.visible = false
	#$NewsButton.visible = false

	# Hide all detail sets first
	for child in $NewsDetails.get_children():
		if child.name != "BackButton":
			child.visible = false

	# Map index -> detail node name
	var mapping = {
		0: "set1",
		1: "set2_1",
		2: "set3_1",
		3: "set4_1",
		4: "set5_1"
	}

	# Show the correct detail set
	if mapping.has(index):
		var target_set = $NewsDetails.get_node(mapping[index])
		if target_set:
			target_set.visible = true
			print(target_set)


func _on_back_button_pressed():
	# Cursor effect will play automatically via global input
	# Hide details, return to news list
	$NewsDetails.visible = false
	$NewsControl.visible = true
	$PublishersButton.visible = true
	$NewsButton.visible = true
	$Button.visible= true
	

func _on_back_pressed() -> void:
	pass # Replace with function body.


func _on_button_pressed() -> void:
	pass # Replace with function body.



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
