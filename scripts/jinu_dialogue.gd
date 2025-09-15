extends Panel

@onready var text_box: RichTextLabel = $RichTextLabel
@export var typing_speed: float = 0.03  # seconds per character
@export var hide_after: float = 3.0  # seconds after typing finishes

signal dialog_finished

var full_text: String = ""
var current_index: int = 0
var typing_timer: Timer

func _ready():
	# Store the text already written in the editor
	full_text = text_box.text
	text_box.clear()

	# Create typing timer
	typing_timer = Timer.new()
	typing_timer.one_shot = false
	add_child(typing_timer)
	typing_timer.timeout.connect(_on_typing_timer_timeout)

	typing_timer.wait_time = typing_speed
	typing_timer.start()

func _on_typing_timer_timeout() -> void:
	if current_index < full_text.length():
		text_box.append_text(full_text[current_index])
		current_index += 1
	else:
		typing_timer.stop()
		# Wait 5 seconds, then hide both text and panel
		await get_tree().create_timer(hide_after).timeout
		text_box.visible = false
		visible = false
		# Emit signal when dialog is completely finished
		dialog_finished.emit()
