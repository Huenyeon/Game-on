extends Node2D
@onready var marker = $Marker2D  # tip of the pen
@onready var sprite =  $red# assuming you have a sprite for the pen
var sticking := false
var start_pos: Vector2
var drag_offset := Vector2.ZERO

var drawing := false
var current_line: Line2D
@export var pen_color: Color = Color.RED
@export var pen_width: float = 3.0
@onready var drawing_area =$"../../paper"

signal pen_clicked

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
			emit_signal("pen_clicked", self)  # Notify parent
		else:
			# Click while dragging - return the pen
			release()

func _input(event):
	# Add escape key handling
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if sticking:
			release()
		return
	
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
						emit_signal("pen_clicked", self)  # Notify parent
						return
						
	# --- Handle right click for drawing ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			start_drawing()
		else:
			stop_drawing()
						
func is_inside_drawing_area(point: Vector2) -> bool:
	if drawing_area == null:
		return false
	var sprite_size = drawing_area.texture.get_size() * drawing_area.scale
	var rect = Rect2(
	drawing_area.global_position - sprite_size / 2,
	sprite_size
	)
	return rect.has_point(point)

func _process(delta):
	if sticking:
		global_position = get_global_mouse_position() + drag_offset
	if drawing and current_line:
		var local_point = drawing_area.to_local(marker.global_position)
		if is_inside_drawing_area(marker.global_position):
			current_line.add_point(local_point)

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

# New function to release the pen
func release():
	if sticking:
		sticking = false
		set_process(false)
		return_to_start()
	
func start_drawing():
	if drawing:
		return
	current_line = Line2D.new()
	current_line.width = pen_width
	current_line.default_color = pen_color
	drawing_area.add_child(current_line) # ensures line stays inside drawing area
	current_line.add_point(drawing_area.to_local(marker.global_position))
	drawing = true

func stop_drawing():
	drawing = false
	current_line = null
