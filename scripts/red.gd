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
			# Check if this pen can be used
			var game_scene = get_tree().current_scene
			if game_scene and game_scene.has_method("can_use_pen"):
				if not game_scene.can_use_pen(self):
					print("Cannot use this pen - another pen is active")
					return
			
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
			
			# Notify game scene that pen interaction is active
			if game_scene and game_scene.has_method("set_pen_interaction"):
				game_scene.set_pen_interaction(true, self)
		else:
			# Click while dragging - return the pen
			sticking = false
			set_process(false)
			return_to_start()

func _input(event):
	# Add escape key handling
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if sticking:
			sticking = false
			set_process(false)
			return_to_start()
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not sticking:
			# Check if this pen can be used
			var game_scene = get_tree().current_scene
			if game_scene and game_scene.has_method("can_use_pen"):
				if not game_scene.can_use_pen(self):
					print("Cannot use this pen - another pen is active")
					return
			
			# Check if dialog is still active
			if game_scene and game_scene.has_method("is_interaction_allowed"):
				if not game_scene.is_interaction_allowed():
					print("Cannot use pen - dialog is still playing")
					return
			
			
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
						
						# Notify game scene that pen interaction is active
						if game_scene and game_scene.has_method("set_pen_interaction"):
							game_scene.set_pen_interaction(true, self)
						
						return
						
	# --- Handle right click for drawing ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			start_drawing()
		else:
			stop_drawing()
						

func _process(delta):
	if sticking:
		# Keep the tip exactly on the cursor while dragging
		global_position = get_global_mouse_position() + drag_offset
	# If drawing, add new point following pen tip
	if drawing and current_line:
		current_line.add_point(marker.global_position)

func force_release():
	# Immediately stop dragging and drawing
	sticking = false
	drawing = false
	set_process(false)
	if current_line:
		current_line = null
	print("Pen force released")

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
	
	# Ensure pen interaction flag is reset
	var game_scene = get_tree().current_scene
	if game_scene and game_scene.has_method("set_pen_interaction"):
		game_scene.set_pen_interaction(false, self)
	
	print("Pen returned to start position")
	
func start_drawing():
	if drawing:
		return
	current_line = Line2D.new()
	current_line.width = pen_width
	current_line.default_color = pen_color
	get_parent().add_child(current_line) # put line beside pen, under parent
	current_line.add_point(marker.global_position)
	drawing = true

func stop_drawing():
	drawing = false
	current_line = null
	
	
	
