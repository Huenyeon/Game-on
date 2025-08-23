extends Control
func _on_desktop_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file("res://scene/inside_desktop.tscn")
		
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
	
