extends Node2D

func _ready():
	# Default visibility
	$NewsContent.visible = true
	$PublishersContent.visible = false
	$NewsDetails.visible = false

	$NewsButton.button_pressed = true
	$PublishersButton.button_pressed = false

	# Connect buttons
	$NewsButton.pressed.connect(_on_news_button_pressed)
	$PublishersButton.pressed.connect(_on_publisher_button_pressed)
	$NewsDetails/BackButton.pressed.connect(_on_back_button_pressed)

	# Connect each news button to show details
	for i in $NewsContent.get_children().size():
		var button = $NewsContent.get_child(i)
		button.pressed.connect(_on_news_item_pressed.bind(i))


func _on_news_button_pressed():
	# Cursor effect will play automatically via global input
	$NewsContent.visible = true
	$PublishersContent.visible = false
	$NewsDetails.visible = false
	$NewsButton.button_pressed = true
	$PublishersButton.button_pressed = false


func _on_publisher_button_pressed():
	# Cursor effect will play automatically via global input
	$NewsContent.visible = false
	$PublishersContent.visible = true
	$NewsDetails.visible = false
	$NewsButton.button_pressed = false
	$PublishersButton.button_pressed = true


func _on_news_item_pressed(index: int):
	# Cursor effect will play automatically via global input
	$NewsContent.visible = false
	$NewsDetails.visible = true
	$PublishersButton.visible = false
	$NewsButton.visible = false
	# Hide all sets first
	for child in $NewsDetails.get_children():
		if child.name != "BackButton":
			child.visible = false

	# Show the set corresponding to the clicked button
	var target_set = $NewsDetails.get_child(index)
	if target_set:
		target_set.visible = true


func _on_back_button_pressed():
	# Cursor effect will play automatically via global input
	# Hide details, return to news list
	$NewsDetails.visible = false
	$NewsContent.visible = true
	$PublishersButton.visible = true
	$NewsButton.visible = true
	




func _on_back_pressed() -> void:
	pass # Replace with function body.


func _on_button_pressed() -> void:
	pass # Replace with function body.



func on_pressed_back_to_scene_button() -> void:
	get_tree().change_scene_to_file("res://scene/game_scene.tscn")
