extends Control

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
