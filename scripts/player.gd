extends CharacterBody2D

const SPEED = 150.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var checklist_ui: Node2D

# States
enum State { ENTERING, STOPPED }
var state = State.ENTERING

# Target position for the middle of the table
var target_x = 350 # Adjust based on your table's position
var start_x = -100 # Start position off-screen to the left
var stop_distance = 5  # Distance threshold before stopping

signal reached_middle

# Stamp variables
var _selected_stamp: Sprite2D = null
var _stamp_type: String = ""
var _custom_cursor: Sprite2D = null
var _has_stamped: bool = false  # new: player-level guard to prevent further stamp selection

func _ready() -> void:
	# Always start from the left side for the walking animation
	# Reset the global flag to ensure walking happens
	Global.player_has_reached_middle = false
	print("Player starting from left side - will walk to middle")
	state = State.ENTERING
	# Start from the left side for walking animation
	position.x = start_x
	print("Player starting position: ", position.x, " Target: ", target_x)

	# Create a custom cursor sprite that follows the mouse
	_custom_cursor = Sprite2D.new()
	_custom_cursor.visible = false
	_custom_cursor.z_index = 1000
	add_child(_custom_cursor)
	
	# Auto-add stamp nodes to the "stamp" group
	for child in get_children():
		if child is Sprite2D and "stamp" in child.name.to_lower():
			if not child.is_in_group("stamp"):
				child.add_to_group("stamp")

func set_checklist_ui(ui: Node2D) -> void:
	checklist_ui = ui

func _physics_process(delta: float) -> void:
	if state == State.ENTERING:
		_auto_move_to_middle()
	else:
		velocity.x = 0

	# Apply gravity (in case floor is sloped)
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

func _auto_move_to_middle() -> void:
	if abs(position.x - target_x) > stop_distance:
		var dir = sign(target_x - position.x)
		velocity.x = dir * SPEED
		print("Player moving: pos=", position.x, " target=", target_x, " velocity=", velocity.x)
	else:
		velocity.x = 0
		state = State.STOPPED
		Global.player_has_reached_middle = true  # Set the global flag
		print("Player reached middle position!")
		emit_signal("reached_middle") # Notify main scene

# Update cursor position to follow mouse
func _process(_delta: float) -> void:
	if _custom_cursor and _custom_cursor.visible:
		_custom_cursor.global_position = get_viewport().get_mouse_position()

# Handle stamp selection and application
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if dialog is still active
		var game_scene = get_tree().current_scene
		if game_scene and game_scene.has_method("is_interaction_allowed"):
			if not game_scene.is_interaction_allowed():
				print("Cannot interact with stamps - dialog is still playing")
				return
		
		
		var mp = get_viewport().get_mouse_position()
		
		# Require the stamp Area2D was clicked (stamp UI opened) before allowing stamp selection.
		var stamp_area_clicked := false
		if "stamp_ui_opened" in Global:
			stamp_area_clicked = Global.stamp_ui_opened
		
		# If no stamp is currently selected, check if we're clicking on a stamp
		if _selected_stamp == null:
			# Do not allow selecting any stamp if the player has already stamped
			# and also require the stamp Area2D to have been clicked first.
			if not _has_stamped and stamp_area_clicked:
				for stamp in get_tree().get_nodes_in_group("stamp"):
					if stamp is Sprite2D and _is_point_in_sprite(stamp, mp):
						# Don't select the stamp if we're clicking on the stamp area itself (for toggling)
						# Only select stamp option sprites, not the main stamp area
						if "StampOption" in stamp.name or "Approve" in stamp.name or "Denied" in stamp.name:
							_select_stamp(stamp)
							break
		else:
			# A stamp is already selected, check if clicking on paper
			var applied = false
			var clicked_on_paper = false
			for paper in get_tree().get_nodes_in_group("paper"):
				if paper is Sprite2D and _is_point_in_sprite(paper, mp):
					clicked_on_paper = true
					applied = await _apply_stamp_to_paper(paper, mp) # await coroutine
					if applied:
						# mark player as having stamped so they can't pick another stamp
						_has_stamped = true
						# Clear global stamp UI flag after stamping (prevent re-select)
						if "stamp_ui_opened" in Global:
							Global.stamp_ui_opened = false
						break
					
			# Deselect the stamp only if it was applied or if click was not on any paper
			if applied or not clicked_on_paper:
				_deselect_stamp()

# Check if a point is inside a sprite's visible area
func _is_point_in_sprite(sprite: Sprite2D, point: Vector2) -> bool:
	if not sprite.texture:
		return false
	var tex_size = sprite.texture.get_size()
	var half_size = (tex_size * sprite.scale) * 0.5
	var center = sprite.global_position
	var rect = Rect2(center - half_size, half_size * 2)
	return rect.has_point(point)

# Select a stamp and update cursor
func _select_stamp(stamp: Sprite2D) -> void:
	_selected_stamp = stamp
	var lname := stamp.name.to_lower()
	_stamp_type = "approved" if "approve" in lname or "approved" in lname else "denied"
	
	# Hide the original stamp sprite
	stamp.visible = false
	
	# Set the cursor to the stamp texture and make it 20x smaller
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_custom_cursor.texture = stamp.texture
	var base_scale = stamp.scale if stamp.scale else Vector2.ONE
	_custom_cursor.scale = base_scale / 5.0
	_custom_cursor.visible = true

# Deselect the stamp and restore cursor
func _deselect_stamp() -> void:
	if _selected_stamp:
		_selected_stamp.visible = true
		_selected_stamp = null
		_stamp_type = ""
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_custom_cursor.visible = false
	_custom_cursor.texture = null

# Apply a stamp to a paper
func _apply_stamp_to_paper(paper: Sprite2D, position: Vector2) -> bool:
	# If this paper is already stamped, do not stamp again
	if paper.has_meta("stamped") and paper.get_meta("stamped"):
		return false
	
	# Create a new stamp sprite
	var new_stamp = Sprite2D.new()
	
	# Set texture based on stamp type
	var stamp_path = ""
	if _stamp_type == "approved":
		stamp_path = "res://assets/stamp_approved.png"
	else:
		stamp_path = "res://assets/stamp_denied.png"
	
	# Load the stamp texture
	var stamp_texture = load(stamp_path)
	if stamp_texture:
		new_stamp.texture = stamp_texture
		
		# Use the selected stamp's scale if available, otherwise a sensible default
		# Apply 20x larger scale to the stamps
		if _selected_stamp and _selected_stamp.scale:
			new_stamp.scale = _selected_stamp.scale * 10.0
		else:
			new_stamp.scale = Vector2.ONE * 30.0
		
		# Ensure stamp appears above the paper
		new_stamp.z_index = 100
		
		# Add the stamp to the paper
		paper.add_child(new_stamp)
		
		# Convert global position to local position relative to paper
		new_stamp.position = paper.to_local(position)
		
		# Mark paper as stamped to prevent future stamps
		paper.set_meta("stamped", true)
		paper.set_meta("stamp_type", _stamp_type)
		
		# Optional: Signal that the paper has been stamped
		if paper.has_method("on_stamped"):
			paper.call("on_stamped", _stamp_type)
		
		# Save decision so end scene can evaluate
		Global.last_stamp = {
			"type": _stamp_type,
			"report": (Global.current_student_report if Global.current_student_report != null else null)
		}
		# default to normal logic
		Global.end_result_inverted = false
		
		# mark player as having stamped so they can't pick another stamp
		_has_stamped = true
		
		# Deselect the stamp and restore cursor immediately
		_deselect_stamp()
		
		# Pause briefly so player sees the placed stamp before showing result
		await get_tree().create_timer(1.0).timeout
		
		# Switch to end-result scene to display 1.png/2.png based on correctness
		get_tree().change_scene_to_file("res://scene/end_result.tscn")
		
		return true

	return false
