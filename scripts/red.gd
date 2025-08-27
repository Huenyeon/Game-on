extends Node2D
@onready var marker = $Marker2D  # tip of the pen
@onready var sprite = $AnimatedSprite2D # assuming you have a sprite for the pen
var sticking := false
var start_pos: Vector2
var drag_offset := Vector2.ZERO

func _ready():
	start_pos = global_position
	set_process(false)
	
	# AnimatedSprite2D doesn't have input_event signal by default
	# We'll use global input detection with sprite bounds checking
	if sprite == null:
		print("Error: $red sprite not found! Check your node path.")
	else:
		print("Using AnimatedSprite2D with global input detection")

# This function is kept for potential future use with Area2D setup
func _on_sprite_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not sticking:
			# Get the mouse position and snap the pen tip to it
			var mouse_pos = get_global_mouse_position()
			
			# Calculate the offset needed to put the tip exactly at the cursor
			drag_offset = marker.global_position - global_position
			var new_pen_position = mouse_pos - drag_offset
			
			# Move the pen so its tip is at the cursor
			global_position = new_pen_position
			
			# Now start dragging mode
			sticking = true
			drag_offset = global_position - mouse_pos
			set_process(true)
		else:
			# Click while dragging - return the pen
			sticking = false
			set_process(false)
			return_to_start()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not sticking:
			# Check if click is on the AnimatedSprite2D
			var mouse_pos = get_global_mouse_position()
			
			# Get sprite bounds for collision detection
			if sprite != null:
				# For AnimatedSprite2D, we need to get the current frame's texture
				var current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
				if current_texture != null:
					var sprite_size = current_texture.get_size()
					# Account for sprite's transform
					var sprite_scale = sprite.scale
					var actual_size = sprite_size * sprite_scale
					var sprite_global_rect = Rect2(sprite.global_position - actual_size/2, actual_size)
					
					if sprite_global_rect.has_point(mouse_pos):
						# Clicked on sprite - snap pen tip to cursor
						drag_offset = marker.global_position - global_position
						var new_pen_position = mouse_pos - drag_offset
						global_position = new_pen_position
						
						sticking = true
						drag_offset = global_position - mouse_pos
						set_process(true)
						return
		
		# If we're already sticking or clicked outside, stop dragging
		if sticking:
			sticking = false
			set_process(false)
			return_to_start()

func _process(delta):
	if sticking:
		# Keep the tip exactly on the cursor while dragging
		global_position = get_global_mouse_position() + drag_offset

func return_to_start():
	# Create a simple animation without tween
	var duration = 0.3
	var elapsed = 0.0
	var initial_pos = global_position
	
	# Use a while loop for the animation
	while elapsed < duration:
		elapsed += get_process_delta_time()
		var t = min(elapsed / duration, 1.0)
		# Smooth easing function
		t = t * t * (3.0 - 2.0 * t)
		global_position = initial_pos.lerp(start_pos, t)
		await get_tree().process_frame
	
	global_position = start_pos
	print("Pen returned to start position")
