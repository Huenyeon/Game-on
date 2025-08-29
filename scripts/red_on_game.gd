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
@onready var canvas_board = get_tree().get_current_scene()

func _ready():
	start_pos = global_position
	set_process(false)
	# Try different ways to find the paper node
	canvas_board = get_tree().get_current_scene().find_child("paper", true, false)
	

	if canvas_board == null:
		print("Error: 'paper' node not found!")
		canvas_board = get_tree().get_current_scene()  # fallback to main scene
	else:
		print("Found paper node: ", canvas_board.name)
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
		# Get the paper node to convert coordinates
		var paper_node = current_line.get_parent()
		if paper_node and paper_node.name == "paper":
			# Check if pen tip is inside paper boundaries before drawing
			if is_pen_inside_paper(marker.global_position, paper_node):
				# Convert global position to paper's local space
				var local_pos = paper_node.to_local(marker.global_position)
				current_line.add_point(local_pos)
				print("Added drawing point on paper at: ", local_pos)
			else:
				print("Pen outside paper boundaries - not drawing")
		else:
			# Fallback to global if paper reference is lost
			current_line.add_point(marker.global_position)
			print("Added global point at: ", marker.global_position)

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
	
	print("Starting drawing...")
	
	# Find the paper node to draw on it
	var paper_node = get_tree().current_scene.find_child("paper", true, false)
	if paper_node == null:
		print("Error: Paper node not found!")
		return
	
	# Check if paper is visible
	if not paper_node.visible:
		print("Paper is not visible, cannot draw!")
		return
	
	print("Drawing on paper: ", paper_node.name)
	
	current_line = Line2D.new()
	current_line.width = pen_width
	current_line.default_color = pen_color
	current_line.z_index = 100  # High z-index to appear above paper
	
	# Add the line as a child of the paper node so it stays within paper boundaries
	paper_node.add_child(current_line)
	
	# Convert global pen position to paper's local coordinates
	var local_pos = paper_node.to_local(marker.global_position)
	current_line.add_point(local_pos)
	drawing = true
	print("Drawing started! Line created on paper with z-index: ", current_line.z_index)

func stop_drawing():
	drawing = false
	current_line = null

func is_pen_inside_paper(pen_global_pos: Vector2, paper_node: Node) -> bool:
	# Get paper texture size and position
	var paper_texture = paper_node.texture
	if paper_texture == null:
		return false
	
	var paper_size = paper_texture.get_size() * paper_node.scale
	var paper_center = paper_node.global_position
	var paper_left = paper_center.x - (paper_size.x / 2)
	var paper_right = paper_center.x + (paper_size.x / 2)
	var paper_top = paper_center.y - (paper_size.y / 2)
	var paper_bottom = paper_center.y + (paper_size.y / 2)
	
	# Check if pen tip is inside paper boundaries
	return (pen_global_pos.x >= paper_left and 
			pen_global_pos.x <= paper_right and 
			pen_global_pos.y >= paper_top and 
			pen_global_pos.y <= paper_bottom)
