extends Control

@onready var pause_button: TextureButton = $PauseContainer/PauseButton
@onready var exit_button: TextureButton = $ExitContainer/ExitButton
@onready var help_button: TextureButton = $HelpContainer/HelpButton
@onready var exit_confirm: ConfirmationDialog = $ExitConfirm
@onready var help_dialog: AcceptDialog = $HelpDialog

var is_paused := false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# When entering gameplay from skip, ensure player doesn't auto-walk
	if "player_has_reached_middle" in Global and not Global.player_has_reached_middle:
		# Optional: leave as-is; intro already sets it when skipping
		pass
	_update_pause_button()

	pause_button.pressed.connect(_on_pause_pressed)
	help_button.pressed.connect(_on_help_pressed)
	exit_button.pressed.connect(func(): exit_confirm.popup_centered())

	exit_confirm.confirmed.connect(_on_exit_confirmed)

func _on_pause_pressed():
	is_paused = not is_paused
	get_tree().paused = is_paused
	_update_pause_button()

func _update_pause_button():
	if is_paused:
		pause_button.texture_normal = load("res://assets/Icons/Play.png")
	else:
		pause_button.texture_normal = load("res://assets/Icons/Pause.png")

func _on_help_pressed():
	help_dialog.popup_centered()

func _on_exit_confirmed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/menu.tscn")
