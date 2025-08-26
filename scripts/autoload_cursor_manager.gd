extends Node

# Cursor textures
var cursor_textures = {
	"cursor1": preload("res://assets/Cursors/Cursor1.png"),
	"cursor2": preload("res://assets/Cursors/Cursor2.png"),
	"cursor3": preload("res://assets/Cursors/Cursor3.png"),
	"cursor4": preload("res://assets/Cursors/Cursor4.png"),
	"cursor5": preload("res://assets/Cursors/Cursor5.png")
}

# Cursor settings for better visibility
var cursor_scale = 1.4  # Set to 1.4x for balanced size
# You can change this to 1.2 or 1.0 if you want it even smaller
var cursor_hotspot = Vector2(0, 0)  # Hotspot position (top-left corner)

# Animation settings
var animation_speed = 0.06  # Time between each cursor frame
var is_playing_effect = false
var animation_tween: Tween

# Current cursor state
var current_cursor = "cursor1"

func _ready():
	# Set initial cursor
	set_cursor("cursor1")
	# Enable global input handling to catch every click anywhere
	set_process_input(true)
	
	# Print debug info to ensure cursor system is working
	print("Cursor system initialized - Scale: ", cursor_scale, " Hotspot: ", cursor_hotspot)
	print("Current cursor: ", current_cursor)

func _input(event):
	# Catch EVERY mouse click anywhere on the screen
	if event is InputEventMouseButton and event.pressed:
		# Play cursor effect on every single click, but only if not already playing
		if not is_playing_effect:
			play_press_effect()

# Function to set cursor with proper scaling and hotspot
func set_cursor(cursor_name: String):
	if cursor_name in cursor_textures:
		current_cursor = cursor_name
		var texture = cursor_textures[cursor_name]
		
		# Create a scaled version of the cursor
		var scaled_texture = texture
		if cursor_scale != 1.0:
			# Scale the texture
			var image = texture.get_image()
			var new_size = image.get_size() * cursor_scale
			image.resize(new_size.x, new_size.y, Image.INTERPOLATE_LANCZOS)
			scaled_texture = ImageTexture.create_from_image(image)
			
			# Better hotspot calculation - offset from top-left for more natural feel
			cursor_hotspot = Vector2(new_size.x * 0.12, new_size.y * 0.12)
		else:
			# For original size, use a small offset
			cursor_hotspot = Vector2(8, 8)
		
		# Set the cursor with proper hotspot
		Input.set_custom_mouse_cursor(scaled_texture, Input.CURSOR_ARROW, cursor_hotspot)
		print("Cursor set to: ", cursor_name, " (Scale: ", cursor_scale, ", Hotspot: ", cursor_hotspot, ")")
	else:
		print("Error: Cursor '", cursor_name, "' not found!")

# Function to change cursor size
func set_cursor_size(scale: float):
	cursor_scale = scale
	# Reapply current cursor with new size
	set_cursor(current_cursor)

# Function to make cursor smaller (quick adjustment)
func make_cursor_smaller():
	cursor_scale = max(1.0, cursor_scale - 0.2)  # Reduce by 0.2 but don't go below 1.0
	set_cursor(current_cursor)

# Function to make cursor bigger (quick adjustment)
func make_cursor_bigger():
	cursor_scale = min(2.0, cursor_scale + 0.2)  # Increase by 0.2 but don't go above 2.0
	set_cursor(current_cursor)

# Function to get current cursor size
func get_cursor_size() -> float:
	return cursor_scale

# Function to play the press effect animation
func play_press_effect():
	if is_playing_effect:
		return  # Don't start if already playing
		
	is_playing_effect = true
	
	# Use Tween for smoother animations that work properly in Godot
	if animation_tween:
		animation_tween.kill()
	
	animation_tween = create_tween()
	animation_tween.set_parallel(false)
	
	# Smooth sequence: Cursor2 -> Cursor3 -> Cursor4 -> back to Cursor1
	animation_tween.tween_callback(set_cursor.bind("cursor2")).set_delay(0.0)
	animation_tween.tween_interval(animation_speed)
	animation_tween.tween_callback(set_cursor.bind("cursor3"))
	animation_tween.tween_interval(animation_speed)
	animation_tween.tween_callback(set_cursor.bind("cursor4"))
	animation_tween.tween_interval(animation_speed)
	animation_tween.tween_callback(set_cursor.bind("cursor1"))
	animation_tween.tween_callback(func(): is_playing_effect = false)

# Function to check if effect is currently playing
func is_effect_playing() -> bool:
	return is_playing_effect

# Function to check if it's okay to play the effect
func can_play_effect() -> bool:
	return not is_playing_effect
