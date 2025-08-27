extends Node2D
@onready var marker = $Marker2D  # tip of the pen
@onready var sprite = $green # assuming you have a sprite for the pen
@onready var paper = get_node("res://scene/game_scene.tscn/../paper") # adjust path as needed
@onready var dialogue = get_node("res://scene/game_scene.tscn/../RichTextLabel")  # adjust path as needed
var sticking := false
var start_pos: Vector2
var drag_offset := Vector2.ZERO
var writing := false
var paper_bounds: Rect2

func _ready():
	start_pos = global_position
	set_process(false)
	
	# Get paper bounds
	if paper != null:
		paper_bounds = get_paper_bounds()
		print("Paper bounds calculated: ", paper_bounds)
	else:
		print("Error: paper node not found!")
		
	# AnimatedSprite2D doesn't have input_event signal by default
	# We'll use global input detection with sprite bounds checking
	if sprite == null:
		print("Error: $green sprite not found! Check your node path.")
	else:
		print("Using AnimatedSprite2D with global input detection")

func get_paper_bounds() -> Rect2:
	# Calculate paper bounds based on node type
	if paper is Sprite2D:
		var texture = paper.texture
		if texture:
			var size = texture.get_size() * paper.scale
			return Rect2(paper.global_position - size/2, size)
	elif paper is AnimatedSprite2D:
		var current_texture = paper.sprite_frames.get_frame_texture(paper.animation, paper.frame)
		if current_texture:
			var size = current_texture.get_size() * paper.scale
			return Rect2(paper.global_position - size/2, size)
	elif paper is ColorRect or paper is NinePatchRect:
		return Rect2(paper.global_position, paper.size)
	elif paper is Control:
		return Rect2(paper.global_position, paper.size)
	
	# Fallback - return a default rect
	return Rect2(paper.global_position, Vector2(200, 200))

func is_point_on_paper(point: Vector2) -> bool:
	return paper_bounds.has_point(point)

func show_dialogue():
	if dialogue != null:
		dialogue.visible = true
		# Hide dialogue after 2 seconds
		await get_tree().create_timer(2.0).timeout
		dialogue.visible = false

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
	# Handle left click for picking up/putting down pen
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
			writing = false
			set_process(false)
			return_to_start()
	
	# Handle right click for writing
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if sticking:  # Only allow writing when pen is being held
			var tip_pos = marker.global_position
			
			if event.pressed:
				# Start writing
				if is_point_on_paper(tip_pos):
					writing = true
					print("Started writing on paper")
				else:
					# Trying to write outside paper - show dialogue
					show_dialogue()
					print("Cannot write outside paper area!")
			else:
				# Stop writing
				writing = false
				print("Stopped writing")

func _process(delta):
	if sticking:
		# Keep the tip exactly on the cursor while dragging
		global_position = get_global_mouse_position() + drag_offset
		
		# Check if we're writing and moved outside paper while writing
		if writing:
			var tip_pos = marker.global_position
			if not is_point_on_paper(tip_pos):
				writing = false
				show_dialogue()
				print("Moved outside paper - stopped writing")

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
