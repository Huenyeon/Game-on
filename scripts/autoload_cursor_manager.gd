extends Node

# Cursor textures
var cursor_textures = {
	"cursor1": preload("res://assets/Cursors/Cursor1.png"),
	"cursor2": preload("res://assets/Cursors/Cursor2.png"),
	"cursor3": preload("res://assets/Cursors/Cursor3.png"),
	"cursor4": preload("res://assets/Cursors/Cursor4.png"),
	"cursor5": preload("res://assets/Cursors/Cursor5.png")
}

# Animation settings
var animation_speed = 0.05  # Time between each cursor frame
var is_playing_effect = false
# Removed cooldown restrictions - effect will play on every click

# Current cursor state
var current_cursor = "cursor1"

func _ready():
	# Set initial cursor
	set_cursor("cursor1")
	# Enable global input handling to catch every click
	set_process_input(true)

func _input(event):
	# Catch EVERY mouse click anywhere on the screen
	if event is InputEventMouseButton and event.pressed:
		# Play cursor effect on every single click
		play_press_effect()

# Function to set cursor
func set_cursor(cursor_name: String):
	if cursor_name in cursor_textures:
		current_cursor = cursor_name
		Input.set_custom_mouse_cursor(cursor_textures[cursor_name])

# Function to play the press effect animation
func play_press_effect():
	if is_playing_effect:
		return  # Don't start if already playing
		
	is_playing_effect = true
	
	# Play the sequence: Cursor2 -> Cursor3 -> Cursor4 -> back to Cursor1
	await get_tree().create_timer(animation_speed).timeout
	set_cursor("cursor2")
	
	await get_tree().create_timer(animation_speed).timeout
	set_cursor("cursor3")
	
	await get_tree().create_timer(animation_speed).timeout
	set_cursor("cursor4")
	
	await get_tree().create_timer(animation_speed).timeout
	set_cursor("cursor1")
	
	is_playing_effect = false

# Function to play the press effect animation only when explicitly requested
func play_press_effect_on_interaction():
	# Only play if not already playing and if this is a meaningful interaction
	if not is_playing_effect:
		play_press_effect()

# Function to check if effect is currently playing
func is_effect_playing() -> bool:
	return is_playing_effect

# Function to check if it's okay to play the effect (not on cooldown)
func can_play_effect() -> bool:
	return not is_playing_effect
