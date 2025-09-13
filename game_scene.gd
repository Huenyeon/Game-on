extends Node2D

@onready var paper = $paper
@onready var student_paper = $"student paper"


@onready var paper_text: RichTextLabel = $paper/MarginContainer/Text
@onready var player = $Player

@onready var checklist_icon: Sprite2D = $checklist_icon
@onready var checklist_ui: Node2D = $ChecklistUI
@onready var clipboard_sprite: Sprite2D = $ChecklistUI/Clipboard

@onready var stamp_options: Node2D = $stamp/StampOptions
@onready var check_option_sprite: Sprite2D = $stamp/StampOptions/CheckOption
@onready var x_option_sprite: Sprite2D = $stamp/StampOptions/XOption

@onready var game_timer: Timer = $TimerBackground/TimerLabel/GameTimer
@onready var timer_label: Label = $TimerBackground/TimerLabel
@onready var jinu_dialogue: Panel = $JinuDialogue

var paper_open = false
var rng := RandomNumberGenerator.new()
var dragging_check := false
var dragging_x := false
var grid_size := 16.0
var drag_start_mouse := Vector2.ZERO
var check_start_pos := Vector2.ZERO
var x_start_pos := Vector2.ZERO
var check_option_original_global := Vector2.ZERO
var x_option_original_global := Vector2.ZERO
var approve_stamp_tex: Texture2D = preload("res://assets/stamp_approved.png")
var denied_stamp_tex: Texture2D = preload("res://assets/stamp_denied.png")
var stamps_layer: Node2D
var check_armed := false
var x_armed := false
var placed_stamp_target_scale := 3.0
var current_student_report_text: String = ""  # Store the current report text
var pen_interaction_active := false  # Flag to track when a pen is being interacted with
var active_pen_node: Node = null # Track the currently active pen node
var dialog_active := true  # Flag to track if dialog is currently playing

var all_reports = Global.correct_student_report + Global.incorrect_student_report

var chosen_report1 = null

# Track stamping state for win/lose logic
var stamped_papers_count := 0
var correct_stamps_count := 0
var stamped_papers := [] # To track which papers have been stamped

# Helper to check if a report is correct
func _is_report_correct(report: Dictionary) -> bool:
	return Global.correct_student_report.has(report)

func _ready() -> void:
	paper.visible = false
	student_paper.visible = false
	
	checklist_ui.visible = false
	
	# Signal connection handled in scene file
	if player:
		player.connect("reached_middle", Callable(self, "_on_player_reached_middle"))
		
		# Check if player is already in the middle when scene loads
		if Global.player_has_reached_middle:
			show_student_paper()
		player.set_checklist_ui(checklist_ui)
		
		# Check if player is already in the middle when scene loads
		if Global.player_has_reached_middle:
			show_student_paper()
		
	# Setup timer (but don't start yet - wait for dialog to finish)
	game_timer.one_shot = true
	game_timer.autostart = false  # Disable autostart so we can control when it starts
	game_timer.stop()  # Force stop the timer immediately
	game_timer.timeout.connect(_on_game_timer_timeout)
	print("Timer setup - is_stopped: ", game_timer.is_stopped(), " time_left: ", game_timer.time_left)
	
	# Connect to dialog finished signal
	if jinu_dialogue:
		jinu_dialogue.dialog_finished.connect(_on_dialog_finished)
		# Also check if dialog is already finished
		_start_timer_when_dialog_done()
	
	# Initialize label with full time (not counting down yet)
	_initialize_timer_label()


	# Ensure stamp options start hidden
	if stamp_options:
		stamp_options.visible = false

	# Assign textures for stamp options (scene doesn't set them)
	if check_option_sprite and check_option_sprite.texture == null:
		check_option_sprite.texture = load("res://assets/Stamp checkbox.png")
	if x_option_sprite and x_option_sprite.texture == null:
		x_option_sprite.texture = load("res://assets/Stamp x.png")

	# Cache original global positions so we can reset on reopen
	if check_option_sprite:
		check_option_original_global = check_option_sprite.global_position
	if x_option_sprite:
		x_option_original_global = x_option_sprite.global_position

	# Create a layer to hold placed stamps
	stamps_layer = Node2D.new()
	add_child(stamps_layer)

	# --- Added: make paper detectable by player.gd and make stamp options part of "stamp" group ---
	if paper:
		# allow player.gd to find paper via group "paper"
		if not paper.is_in_group("paper"):
			paper.add_to_group("paper")
	if student_paper:
		# optional: allow detection if needed
		if not student_paper.is_in_group("paper"):
			student_paper.add_to_group("paper")

	# Rename and group stamp option sprites so player.gd recognizes them when clicked
	if check_option_sprite:
		# include 'approve' in the name so player.gd infers approved stamp
		check_option_sprite.name = "Approve_StampOption"
		if not check_option_sprite.is_in_group("stamp"):
			check_option_sprite.add_to_group("stamp")
	if x_option_sprite:
		# include 'deny' or 'denied' in the name so player.gd infers denied stamp
		x_option_sprite.name = "Denied_StampOption"
		if not x_option_sprite.is_in_group("stamp"):
			x_option_sprite.add_to_group("stamp")
	
	if has_node("stamp"):
		var stamp_root = get_node("stamp")
		# add the root stamp Sprite2D
		if stamp_root is CanvasItem and not stamp_root.is_in_group("stamp"):
			stamp_root.add_to_group("stamp")
		# add top-level Area2D (the click zone) if present
		if stamp_root.has_node("Area2D"):
			var sa = stamp_root.get_node("Area2D")
			if not sa.is_in_group("stamp"):
				sa.add_to_group("stamp")
		# add StampOptions and any Area2D children under it
		if stamp_root.has_node("StampOptions"):
			var so = stamp_root.get_node("StampOptions")
			if not so.is_in_group("stamp"):
				so.add_to_group("stamp")
			# Add nested Area2D nodes (CheckOption/Area2D, XOption/Area2D)
			if so.has_node("CheckOption/Area2D"):
				var ca = so.get_node("CheckOption/Area2D")
				if not ca.is_in_group("stamp"):
					ca.add_to_group("stamp")
			if so.has_node("XOption/Area2D"):
				var xa = so.get_node("XOption/Area2D")
				if not xa.is_in_group("stamp"):
					xa.add_to_group("stamp")

func get_random_reports(count: int) -> Array:
	var chosen = []
	var available_reports = Global.active_reports
	if available_reports.size() == 0:
		# If no active reports, generate some first
		Global.get_random_reports(3)
		available_reports = Global.active_reports
	
	while chosen.size() < count and available_reports.size() > 0:
		var candidate = available_reports[rng.randi() % available_reports.size()]
		if candidate not in chosen:
			chosen.append(candidate)
	return chosen
	
	
func _set_paper_text_from_report(report) -> void:
	if report == null or not report is Dictionary or report.is_empty():
		paper_text.text = "No report found."
		return

	var report_text = "[b][font_size=50]%s[/font_size][/b]\n\n" % report["headline"]
	var highlighted_body = "%s %s %s on %s %s." % [
		"[color=F25907]" + report["who"] + "[/color]",
		report["what"],
		report["where"],
		"[color=F25907]" + report["when"] + "[/color]",
		report["why"]
	]
	report_text += highlighted_body 

	paper_text.bbcode_enabled = true
	paper_text.bbcode_text = report_text
	
# Unified function to display paper with report content
func show_paper_with_report(report_data: Dictionary = {}) -> void:
	# Use provided report data or current student report
	var report_to_use = report_data if report_data.size() > 0 else Global.current_student_report
	
	# Always show the paper, even if no report data is available
	# Hide the student papers and show the main paper
	paper_open = true
	paper.visible = true
	student_paper.visible = false

	# Refresh pen references (good practice)
	refresh_pens_paper_reference()

	# If no report data available, show default message
	if report_to_use == null:
		paper_text.text = "No report found."
		print("Paper opened with no report data")
	else:
		# Set the global variable
		Global.current_student_report = report_to_use
		# Use your helper function to display the content
		_set_paper_text_from_report(Global.current_student_report)
		print("Paper opened with report: ", report_to_use["headline"])

# Legacy function name for backward compatibility
func open_paper_with_report(report_data: Dictionary) -> void:
	show_paper_with_report(report_data)

# Load report data for stamping (same logic as student paper click)
func _load_report_data_for_stamping() -> void:
	# Only choose a report the first time
	if chosen_report1 == null:
		var all_reports = Global.correct_student_report + Global.incorrect_student_report
		var available_reports = []

		# Filter out already used reports
		for report in all_reports:
			if not Global.used_reports.has(report):
				available_reports.append(report)

		# Reset if empty
		if available_reports.size() == 0:
			Global.used_reports.clear()
			available_reports = all_reports

		# Pick this paper's report once
		chosen_report1 = available_reports[0]
		Global.used_reports.append(chosen_report1)
	
	# Set the current student report to the chosen report
	Global.current_student_report = chosen_report1

# Function called by desktop click to show paper
func show_desktop_paper() -> void:
	# Load report data the same way student paper does
	_load_report_data_for_stamping()
	# Show paper with the loaded report (no animation)
	show_paper_with_report()


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and is_interaction_allowed():
		# Only choose a report the first time
		if chosen_report1 == null:
			var all_reports = Global.correct_student_report + Global.incorrect_student_report
			var available_reports = []

			# Filter out already used reports
			for report in all_reports:
				if not Global.used_reports.has(report):
					available_reports.append(report)

			# Reset if empty
			if available_reports.size() == 0:
				Global.used_reports.clear()
				available_reports = all_reports

			# Pick this paper’s report once
			chosen_report1 = available_reports[0]   # or pick index 2 if you want the 3rd slot
			Global.used_reports.append(chosen_report1)

		# Now always use chosen_report1
		open_paper_with_report(chosen_report1)

func refresh_pens_paper_reference():
	# Find all pens and refresh their paper reference
	var pens = get_node_or_null("Pens")
	if pens:
		for pen in pens.get_children():
			if pen.has_method("refresh_paper_reference"):
				pen.refresh_paper_reference()
				print("Refreshed paper reference for pen: ", pen.name)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_viewport().get_mouse_position()
		
		# Handle stamp options and paper closing when clicking outside
		if stamp_options and stamp_options.visible:
			# Check if click is outside stamp options area
			if not _is_click_on_stamp_options(mouse_pos):
				# Close both stamp options and paper when clicking outside
				stamp_options.visible = false
				paper_open = false
				paper.visible = false
				student_paper.visible = true
				dragging_check = false
				dragging_x = false
				check_armed = false
				x_armed = false
				# Force release any active pens when closing stamp options
				close_pen_interactions_if_open()
				# Clear global stamp UI opened flag
				Global.stamp_ui_opened = false
		# Only close paper if stamp options are NOT visible, not dragging, and no pen interaction
		elif paper_open and not dragging_check and not dragging_x and not pen_interaction_active:
			# Check if click is on exempted elements (pens or upper-left buttons)
			if _is_click_on_exempted_elements(mouse_pos):
				# Don't close paper if clicking on exempted elements
				pass
			else:
				var tex_size = paper.texture.get_size()*paper.scale
				var top_left = paper.global_position - (tex_size * 0.5)
				var paper_rect = Rect2(top_left, tex_size)
				
				if not paper_rect.has_point(mouse_pos):
					# Don't play cursor effect here - this was causing it to play everywhere
					paper_open = false
					paper.visible = false
					student_paper.visible = true
					
					# Force release any active pens when closing paper
					close_pen_interactions_if_open()
		
		# Handle checklist closing when clicking outside
		if checklist_ui.visible:
			var should_close := true
			if clipboard_sprite and clipboard_sprite.texture:
				var clip_size := clipboard_sprite.texture.get_size() * clipboard_sprite.scale
				var clip_top_left := clipboard_sprite.global_position - (clip_size * 0.5)
				var clipboard_rect := Rect2(clip_top_left, clip_size)
				should_close = not clipboard_rect.has_point(mouse_pos)
			if should_close:
				checklist_ui.visible = false
				# Force release any active pens when closing checklist
				close_pen_interactions_if_open()
	
	# Stop dragging on mouse release
	if event is InputEventMouseButton and not event.pressed:
		dragging_check = false
		dragging_x = false
	
func _input(event: InputEvent) -> void:
	# Also stop dragging on any mouse release, even if another node handled it
	if event is InputEventMouseButton and not event.pressed:
		dragging_check = false
		dragging_x = false

func _process(_delta: float) -> void:
	# Update drag every frame so we don't depend on motion events propagation
	if dragging_check and check_option_sprite:
		var delta := get_viewport().get_mouse_position() - drag_start_mouse
		var snapped := Vector2(round(delta.x / grid_size) * grid_size, round(delta.y / grid_size) * grid_size)
		check_option_sprite.global_position = check_start_pos + snapped
	elif dragging_x and x_option_sprite:
		var delta_x := get_viewport().get_mouse_position() - drag_start_mouse
		var snapped_x := Vector2(round(delta_x.x / grid_size) * grid_size, round(delta_x.y / grid_size) * grid_size)
		x_option_sprite.global_position = x_start_pos + snapped_x
	
	# Update timer label only if timer is running
	if not game_timer.is_stopped() and game_timer.time_left > 0:
		_update_timer_label()
	elif dialog_active and not game_timer.is_stopped():
		print("WARNING: Timer is running during dialog! Stopping it...")
		game_timer.stop()

func _on_checklist_icon_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		# Close paper if open when clicking clipboard
		if paper_open:
			paper_open = false
			paper.visible = false
			student_paper.visible = true
			# Reset pen interaction flag when paper is closed
			pen_interaction_active = false
			active_pen_node = null
		
		# Close pen interactions when clicking clipboard
		close_pen_interactions_if_open()
		
		checklist_ui.visible = true
 
func _on_player_reached_middle():
	# Add a small delay before showing the paper for better animation timing
	await get_tree().create_timer(0.5).timeout
	show_student_paper()

# New function to handle showing student paper
func show_student_paper():
	print("Student paper opened!")
	student_paper.visible = true
	Global.get_random_reports(3)
	Global.get_random_student_reports(1)
	
	# Reset player's stamp state when the student paper view opens
	if player and player.has_method("reset_stamp_state"):
		player.reset_stamp_state()
	
	# Generate the initial student report text
	if current_student_report_text == "":
		var all_reports = Global.correct_student_report + Global.incorrect_student_report
		
		if all_reports.size() > 0:
			var random_index = rng.randi() % all_reports.size()
			var report = all_reports[random_index]
			current_student_report_text = "%s\n\n%s\n\n%s" % [
				report["headline"],
				report["body"],
			]
			print("Initial student report generated: ", report["headline"])
	
	# Student paper appears simply when character reaches position

func _on_student_paper_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and is_interaction_allowed():
		# Close clipboard if open when clicking paper
		close_clipboard_if_open()
		
		# Close paper if open when clicking student paper
		close_paper_if_open()
		
		# Close pen interactions when clicking student paper
		close_pen_interactions_if_open()
		
		# Use unified function to show paper with current report
		show_paper_with_report()
		


func _on_stamp_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if stamp_options:
			var will_show := not stamp_options.visible
			stamp_options.visible = will_show
			# Track that the stamp Area2D was clicked (stamp UI opened)
			Global.stamp_ui_opened = will_show
			
			# Also show/hide the student paper content when stamp options are toggled
			if will_show:
				# Show both stamp options and student paper content
				paper_open = true
				paper.visible = true
				student_paper.visible = false
				
				# Prefer an already-selected Global.current_student_report.
				# If that's not present, prefer the local cached current_student_report_text.
				# Only generate a new random report as a last resort.
				if Global.current_student_report:
					# Use the selected global student report so opening stamps won't change it
					var report_text = "%s\n\n%s\n\n%s" % [
						Global.current_student_report["headline"],
						Global.current_student_report["body"],
						Global.current_student_report["additional_info"]
					]
					paper_text.text = report_text
				elif current_student_report_text != "":
					# Use cached text (won't overwrite an already-generated report)
					paper_text.text = current_student_report_text
				else:
					# Last resort: generate a local random report without modifying globals
					var all_reports = Global.correct_student_report + Global.incorrect_student_report
					if all_reports.size() > 0:
						var random_index = rng.randi() % all_reports.size()
						var report = all_reports[random_index]
						current_student_report_text = "%s\n\n%s\n\n%s" % [
							report["headline"],
							report["body"],
							report["additional_info"]
						]
						paper_text.text = current_student_report_text
			else:
				# Hide both stamp options and student paper content
				paper_open = false
				paper.visible = false
				student_paper.visible = true
				dragging_check = false
				dragging_x = false
				check_armed = false
				x_armed = false
				
				# Stamp UI closed -> clear global flag
				Global.stamp_ui_opened = false
			
			# Reset positions to original on reopen
			if will_show:
				if check_option_sprite:
					check_option_sprite.global_position = check_option_original_global
				if x_option_sprite:
					x_option_sprite.global_position = x_option_original_global


func _place_stamp(tex: Texture2D, global_pos: Vector2, scale: Vector2) -> void:
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.global_position = global_pos
	s.scale = Vector2.ONE * placed_stamp_target_scale
	s.z_index = 100
	stamps_layer.add_child(s)

	# Prevent the player from selecting another stamp after placing one via the UI
	# Close the stamp UI and mark the player's stamped state.
	if stamp_options:
		stamp_options.visible = false
	# Clear the global stamp UI opened flag so player selection requires reopening
	if "stamp_ui_opened" in Global:
		Global.stamp_ui_opened = false
	# If player exists, tell it that stamping occurred so it won't allow new selection
	if player and player.has_method("set_has_stamped"):
		player.set_has_stamped(true)
func _on_check_option_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if check_armed:
			_place_stamp(approve_stamp_tex, check_option_sprite.global_position, check_option_sprite.scale)
			check_armed = false
			stamp_options.visible = false
			# Keep the paper visible when stamp is placed
			paper_open = true
			paper.visible = true
			student_paper.visible = false
			# reset option positions for next open
			x_option_sprite.global_position = x_option_original_global
			check_option_sprite.global_position = check_option_original_global
			# stamping done -> clear stamp UI opened flag
			Global.stamp_ui_opened = false
			return
		dragging_check = true
		drag_start_mouse = get_viewport().get_mouse_position()
		check_start_pos = check_option_sprite.global_position
		if not stamp_options.visible:
			stamp_options.visible = true
	elif event is InputEventMouseButton and not event.pressed:
		# Arm for next tap to place
		dragging_check = false
		check_armed = true

func _on_x_option_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if x_armed:
			_place_stamp(denied_stamp_tex, x_option_sprite.global_position, x_option_sprite.scale)
			x_armed = false
			stamp_options.visible = false
			# Keep the paper visible when stamp is placed
			paper_open = true
			paper.visible = true
			student_paper.visible = false
			# reset option positions for next open
			x_option_sprite.global_position = x_option_original_global
			check_option_sprite.global_position = check_option_original_global
			# stamping done -> clear stamp UI opened flag
			Global.stamp_ui_opened = false
			return
		dragging_x = true
		drag_start_mouse = get_viewport().get_mouse_position()
		x_start_pos = x_option_sprite.global_position
		if not stamp_options.visible:
			stamp_options.visible = true
	elif event is InputEventMouseButton and not event.pressed:
		# Arm for next tap to place
		dragging_x = false
		x_armed = true
		
func _on_game_timer_timeout():
	timer_label.text = "0"
	# Action when time runs out
	print("Time’s up! Game over.")
	# Example: hide everything or end scene
	paper.visible = false
	student_paper.visible = false
	checklist_ui.visible = false

	# Show end_result scene with tex_bad (denied)
	Global.last_stamp = null
	Global.end_result_inverted = false
	get_tree().change_scene_to_file("res://scene/end_result.tscn")

func _initialize_timer_label() -> void:
	# Show the full timer duration when dialog is still playing
	var full_time = int(game_timer.wait_time)
	timer_label.text = str(full_time)
	timer_label.add_theme_color_override("font_color", Color.GREEN)

func _update_timer_label() -> void:
	# Only update if timer is actually running
	if not game_timer.is_stopped():
		var time_left = int(game_timer.time_left)
		timer_label.text = str(time_left)

		if time_left <= 10:
			timer_label.add_theme_color_override("font_color", Color.RED)
		else:
			timer_label.add_theme_color_override("font_color", Color.GREEN)

# Called when dialog finishes
func _on_dialog_finished():
	print("Dialog finished, starting timer!")
	dialog_active = false
	game_timer.start()
	print("Timer started - is_stopped: ", game_timer.is_stopped(), " time_left: ", game_timer.time_left)
	_update_timer_label()

# Fallback method to start timer when dialog becomes invisible
func _start_timer_when_dialog_done():
	# Check if dialog is visible, if not start timer immediately
	if not jinu_dialogue.visible:
		print("No dialog visible, starting timer immediately!")
		dialog_active = false
		game_timer.start()
		_update_timer_label()
		return
	
	# If dialog is visible, wait for it to become invisible
	print("Dialog is visible, waiting for it to finish...")
	var check_timer = Timer.new()
	check_timer.wait_time = 0.1  # Check every 0.1 seconds
	check_timer.timeout.connect(_check_dialog_visibility)
	add_child(check_timer)
	check_timer.start()

func _check_dialog_visibility():
	if not jinu_dialogue.visible:
		print("Dialog became invisible, starting timer!")
		dialog_active = false
		game_timer.start()
		_update_timer_label()
		# Stop checking
		var check_timer = get_children().filter(func(child): return child is Timer and child != game_timer)
		for timer in check_timer:
			timer.queue_free()

# Helper function to check if interactions should be allowed
func is_interaction_allowed() -> bool:
	return not dialog_active

# Helper function to close clipboard when other elements are clicked
func close_clipboard_if_open():
	if checklist_ui.visible:
		checklist_ui.visible = false


# Helper function to close paper when other elements are clicked
func close_paper_if_open():
	if paper_open:
		paper_open = false
		paper.visible = false
		student_paper.visible = true
		# Reset pen interaction flag when paper is closed
		pen_interaction_active = false
		active_pen_node = null

# Helper function to close stamp options when other elements are clicked
func close_stamp_options_if_open():
	if stamp_options and stamp_options.visible:
		stamp_options.visible = false
		# Clear global stamp UI opened flag
		Global.stamp_ui_opened = false
		# Reset stamp option states
		dragging_check = false
		dragging_x = false
		check_armed = false
		x_armed = false

# Helper function to close pen interactions when other elements are clicked
func close_pen_interactions_if_open():
	if pen_interaction_active and active_pen_node:
		# Immediately stop the pen from following the cursor
		if active_pen_node.has_method("force_release"):
			active_pen_node.force_release()
		# Tell the active pen to return to start position
		if active_pen_node.has_method("return_to_start"):
			active_pen_node.return_to_start()
		# Reset pen interaction state
		pen_interaction_active = false
		active_pen_node = null
		print("Pen interactions closed")

# Helper function to check if click is on stamp options area
func _is_click_on_stamp_options(mouse_pos: Vector2) -> bool:
	if not stamp_options or not stamp_options.visible:
		return false
	
	# Check if click is on stamp options sprites
	if check_option_sprite:
		var check_rect = Rect2(check_option_sprite.global_position - check_option_sprite.texture.get_size() * check_option_sprite.scale * 0.5, 
							  check_option_sprite.texture.get_size() * check_option_sprite.scale)
		if check_rect.has_point(mouse_pos):
			return true
	
	if x_option_sprite:
		var x_rect = Rect2(x_option_sprite.global_position - x_option_sprite.texture.get_size() * x_option_sprite.scale * 0.5, 
						  x_option_sprite.texture.get_size() * x_option_sprite.scale)
		if x_rect.has_point(mouse_pos):
			return true
	
	# Check if click is on the stamp area that opened the options
	var stamp_area = get_node_or_null("stamp/Area2D")
	if stamp_area:
		for child in stamp_area.get_children():
			if child is CollisionShape2D:
				var shape = child.shape
				if shape:
					var global_pos = stamp_area.global_position + child.position
					var shape_size = shape.get_rect().size
					var stamp_rect = Rect2(global_pos - shape_size * 0.5, shape_size)
					if stamp_rect.has_point(mouse_pos):
						return true
	
	return false

# Helper function to check if click is on exempted elements (pens or upper-left buttons)
func _is_click_on_exempted_elements(mouse_pos: Vector2) -> bool:
	# Check if click is on pens by checking the Pens node
	var pens = get_node_or_null("Pens")
	if pens:
		for pen in pens.get_children():
			if pen is Area2D:
				# Use the pen's collision detection
				for child in pen.get_children():
					if child is CollisionShape2D:
						var shape = child.shape
						if shape:
							# Get the global position of the collision shape
							var global_pos = pen.global_position + child.position
							var shape_size = shape.get_rect().size
							var pen_rect = Rect2(global_pos - shape_size * 0.5, shape_size)
							if pen_rect.has_point(mouse_pos):
								return true
	
	# Check if click is on upper-left buttons (GameControls)
	var game_controls = get_node_or_null("CanvasLayer/UIRoot/GameControls")
	if game_controls:
		var controls_rect = Rect2(game_controls.global_position, game_controls.size)
		if controls_rect.has_point(mouse_pos):
			return true
	
	# Check if click is on desktop (Desktop node)
	var desktop = get_node_or_null("Desktop")
	if desktop:
		var desktop_rect = Rect2(desktop.global_position, desktop.size)
		if desktop_rect.has_point(mouse_pos):
			return true
	
	return false

# Function for pens to call when they start/stop interaction
func set_pen_interaction(active: bool, pen_node: Node = null):
	if active and pen_node:
		# If another pen is already active, don't allow this one
		if pen_interaction_active and pen_node != active_pen_node:
			print("Another pen is already active, cannot use this pen")
			return false
		
		pen_interaction_active = true
		active_pen_node = pen_node
		print("Pen interaction started with: ", pen_node.name)
		return true
	else:
		pen_interaction_active = false
		active_pen_node = null
		print("Pen interaction ended")
		return true
