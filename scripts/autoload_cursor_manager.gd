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
var cursor_scale = 2.0  # Make cursors 2x bigger
var cursor_hotspot = Vector2(0, 0)  # Hotspot position (top-left corner)

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
	
	# Print debug info to ensure cursor system is working
	print("Cursor system initialized - Scale: ", cursor_scale, " Hotspot: ", cursor_hotspot)
	print("Current cursor: ", current_cursor)
	
	# Test the cursor system after a short delay
	await get_tree().create_timer(1.0).timeout
	test_cursor_system()

func _input(event):
	# Catch EVERY mouse click anywhere on the screen
	if event is InputEventMouseButton and event.pressed:
		# Play cursor effect on every single click
		play_press_effect()

# Function to test cursor system
func test_cursor_system():
	print("Testing cursor system...")
	print("Available cursors: ", cursor_textures.keys())
	print("Current cursor: ", current_cursor)
	print("Cursor scale: ", cursor_scale)
	print("Cursor hotspot: ", cursor_hotspot)
	
	# Test setting each cursor
	for cursor_name in cursor_textures.keys():
		print("Setting cursor: ", cursor_name)
		set_cursor(cursor_name)
		await get_tree().create_timer(0.5).timeout
	
	# Return to cursor1
	set_cursor("cursor1")
	print("Cursor system test completed!")

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
			
			# Adjust hotspot for larger cursor (center it)
			cursor_hotspot = new_size / 2
		
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

# Function to get current cursor size
func get_cursor_size() -> float:
	return cursor_scale

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
