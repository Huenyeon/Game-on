extends Control

@onready var pause_button: TextureButton = $PauseContainer/PauseButton
@onready var skip_button: TextureButton = $SkipContainer/SkipButton
@onready var exit_button: TextureButton = $ExitContainer/ExitButton
@onready var skip_confirm: ConfirmationDialog = $SkipConfirm
@onready var exit_confirm: ConfirmationDialog = $ExitConfirm

var is_paused := false

func _ready():
	# Ensure UI stays active when the scene tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	_update_pause_button()

	pause_button.pressed.connect(_on_pause_pressed)
	skip_button.pressed.connect(func(): skip_confirm.popup_centered())
	exit_button.pressed.connect(func(): exit_confirm.popup_centered())

	skip_confirm.confirmed.connect(_on_skip_confirmed)
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

func _on_skip_confirmed():
	# Skip all intros and go directly to the game scene
	get_tree().paused = false
	# Ensure the player starts in the stopped state at the table
	if "player_has_reached_middle" in Global:
		Global.player_has_reached_middle = true
	get_tree().change_scene_to_file("res://scene/game_scene.tscn")

func _on_exit_confirmed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/menu.tscn")
