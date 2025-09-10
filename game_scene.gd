extends Node2D

@onready var paper = $paper
@onready var student_paper = $"student paper"
@onready var student_paper2 = $"student paper2"
@onready var student_paper3 = $"student paper3"
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

var all_reports = Global.correct_student_report + Global.incorrect_student_report

var chosen_report1 = null
var chosen_report2 = null
var chosen_report3 = null

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
	student_paper2.visible = false
	student_paper3.visible = false
	
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
		
	# Setup timer
	game_timer.one_shot = true
	game_timer.start()
	game_timer.timeout.connect(_on_game_timer_timeout)
	
	# Initialize label
	_update_timer_label()


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
	
	
func _set_paper_text_from_report(report: Dictionary) -> void:
	if report == null or report.is_empty():
		paper_text.text = "No report found."
		return

	var report_text = "[b][font_size=10]%s[/font_size][/b]\n\n" % report["headline"]
	var highlighted_body = "%s %s %s on %s %s." % [
		"[color=F25907][u]" + report["who"] + "[/u][/color]",
		report["what"],
		report["where"],
		"[color=F25907][u]" + report["when"] + "[/u][/color]",
		report["why"]
	]
	report_text += highlighted_body + "\n\n" + report["additional_info"]

	paper_text.bbcode_enabled = true
	paper_text.bbcode_text = report_text
	
# Add this new function to your script
func open_paper_with_report(report_data: Dictionary) -> void:
	# Set the global variable
	Global.current_student_report = report_data

	# Hide the student papers and show the main paper
	paper_open = true
	paper.visible = true
	student_paper.visible = false
	student_paper2.visible = false
	student_paper3.visible = false

	# Refresh pen references (good practice)
	refresh_pens_paper_reference()

	# Use your helper function to display the content
	_set_paper_text_from_report(Global.current_student_report)

	print("Paper opened with report: ", report_data["headline"])

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
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

		# Now always use chosen_report3
		var report_text = "[b][font_size=50]%s[/font_size][/b]\n\n" % chosen_report1["headline"]

		var highlighted_body = "%s %s %s on %s %s." % [
			"[color=F25907][u]" + chosen_report1["who"] + "[/u][/color]",
			chosen_report1["what"],
			chosen_report1["where"],
			"[color=F25907][u]" + chosen_report1["when"] + "[/u][/color]",
			chosen_report1["why"]
		]
		report_text += highlighted_body + "\n\n" + chosen_report1["additional_info"]

		paper_text.bbcode_enabled = true
		paper_text.text = report_text

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
		
		# NEVER close the paper if stamp options are visible
		if paper_open and stamp_options and stamp_options.visible:
			# Paper stays open when stamp options are visible - do nothing
			pass
		# Only close paper if stamp options are NOT visible, not dragging, and no pen interaction
		elif paper_open and not dragging_check and not dragging_x and not pen_interaction_active:
			var tex_size = paper.texture.get_size()*paper.scale
			var top_left = paper.global_position - (tex_size * 0.5)
			var paper_rect = Rect2(top_left, tex_size)
			
			if not paper_rect.has_point(mouse_pos):
				# Don't play cursor effect here - this was causing it to play everywhere
				paper_open = false
				paper.visible = false
				student_paper.visible = true
				student_paper2.visible = true
				student_paper3.visible = true
				
				
				# Reset pen interaction flag when paper is closed
				pen_interaction_active = false
				active_pen_node = null
		
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
	
	# Update timer label
	if game_timer.time_left > 0:
		_update_timer_label()

func _on_checklist_icon_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		checklist_ui.visible = true
 
func _on_player_reached_middle():
	show_student_paper()

# New function to handle showing student paper
func show_student_paper():
	print("Student paper opened!")
	student_paper.visible = true
	student_paper2.visible = true
	student_paper3.visible = true
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
				report["additional_info"]
			]
			print("Initial student report generated: ", report["headline"])

func _on_student_paper_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		paper.visible = true
		


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

				# Always use the already-chosen report for the currently opened paper
				var report_text = ""
				if paper.visible and not student_paper.visible and chosen_report1 != null:
					report_text = "[b][font_size=50]%s[/font_size][/b]\n\n" % chosen_report1["headline"]
					var highlighted_body = "%s %s %s on %s %s." % [
						"[color=F25907][u]" + chosen_report1["who"] + "[/u][/color]",
						chosen_report1["what"],
						chosen_report1["where"],
						"[color=F25907][u]" + chosen_report1["when"] + "[/u][/color]",
						chosen_report1["why"]
					]
					report_text += highlighted_body + "\n\n" + chosen_report1["additional_info"]
				elif paper.visible and not student_paper2.visible and chosen_report2 != null:
					report_text = "[b][font_size=50]%s[/font_size][/b]\n\n" % chosen_report2["headline"]
					var highlighted_body = "%s %s %s on %s %s." % [
						"[color=F25907][u]" + chosen_report2["who"] + "[/u][/color]",
						chosen_report2["what"],
						chosen_report2["where"],
						"[color=F25907][u]" + chosen_report2["when"] + "[/u][/color]",
						chosen_report2["why"]
					]
					report_text += highlighted_body + "\n\n" + chosen_report2["additional_info"]
				elif paper.visible and not student_paper3.visible and chosen_report3 != null:
					report_text = "[b][font_size=50]%s[/font_size][/b]\n\n" % chosen_report3["headline"]
					var highlighted_body = "%s %s %s on %s %s." % [
						"[color=F25907][u]" + chosen_report3["who"] + "[/u][/color]",
						chosen_report3["what"],
						chosen_report3["where"],
						"[color=F25907][u]" + chosen_report3["when"] + "[/u][/color]",
						chosen_report3["why"]
					]
					report_text += highlighted_body + "\n\n" + chosen_report3["additional_info"]
				if report_text != "":
					paper_text.bbcode_enabled = true
					paper_text.text = report_text
			else:
				# Hide both stamp options and student paper content
				paper_open = false
				paper.visible = false
				student_paper.visible = true
				student_paper2.visible = true
				student_paper3.visible = true
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

	# Determine which paper is being stamped
	var stamped_report = null
	if paper.visible and not student_paper.visible:
		stamped_report = chosen_report1
	elif paper.visible and not student_paper2.visible:
		stamped_report = chosen_report2
	elif paper.visible and not student_paper3.visible:
		stamped_report = chosen_report3

	if stamped_report != null and not stamped_papers.has(stamped_report):
		stamped_papers.append(stamped_report)
		stamped_papers_count += 1
		# Check if the stamp is correct (approve for correct, deny for incorrect)
		if tex == approve_stamp_tex and _is_report_correct(stamped_report):
			correct_stamps_count += 1
		elif tex == denied_stamp_tex and not _is_report_correct(stamped_report):
			correct_stamps_count += 1

	# Prevent the player from selecting another stamp after placing one via the UI
	if stamp_options:
		stamp_options.visible = false
	if "stamp_ui_opened" in Global:
		Global.stamp_ui_opened = false
	if player and player.has_method("set_has_stamped"):
		player.set_has_stamped(true)

	# Only end game after 3 papers have been stamped
	if stamped_papers_count >= 3:
		# Hide all UI
		paper.visible = false
		student_paper.visible = false
		student_paper2.visible = false
		student_paper3.visible = false
		checklist_ui.visible = false
		# Set result and go to end scene
		if correct_stamps_count >= 2:
			Global.end_result_inverted = false # Win
		else:
			Global.end_result_inverted = true # Lose
		get_tree().change_scene_to_file("res://scene/end_result.tscn")

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
	timer_label.text = "0:00"
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

func _update_timer_label() -> void:
	var time_left = int(game_timer.time_left)
	var minutes = time_left / 60
	var seconds = time_left % 60
	timer_label.text = str(minutes) + ":" + ("%02d" % seconds)

	if time_left <= 10:
		timer_label.add_theme_color_override("font_color", Color.RED)
	else:
		timer_label.add_theme_color_override("font_color", Color.GREEN)

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



func _on_area_2d_student_paper2_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Only choose a report the first time
		if chosen_report2 == null:
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
			chosen_report2 = available_reports[1]   # or pick index 2 if you want the 3rd slot
			Global.used_reports.append(chosen_report2)

		# Now always use chosen_report3
		var report_text = "[b][font_size=50]%s[/font_size][/b]\n\n" % chosen_report2["headline"]

		var highlighted_body = "%s %s %s on %s %s." % [
			"[color=F25907][u]" + chosen_report2["who"] + "[/u][/color]",
			chosen_report2["what"],
			chosen_report2["where"],
			"[color=F25907][u]" + chosen_report2["when"] + "[/u][/color]",
			chosen_report2["why"]
		]
		report_text += highlighted_body + "\n\n" + chosen_report2["additional_info"]

		paper_text.bbcode_enabled = true
		paper_text.text = report_text




func _on_area_2d_student_paper3_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Only choose a report the first time
		if chosen_report3 == null:
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
			chosen_report3 = available_reports[2]   # or pick index 2 if you want the 3rd slot
			Global.used_reports.append(chosen_report3)

		# Now always use chosen_report3
		var report_text = "[b][font_size=50]%s[/font_size][/b]\n\n" % chosen_report3["headline"]

		var highlighted_body = "%s %s %s on %s %s." % [
			"[color=F25907][u]" + chosen_report3["who"] + "[/u][/color]",
			chosen_report3["what"],
			chosen_report3["where"],
			"[color=F25907][u]" + chosen_report3["when"] + "[/u][/color]",
			chosen_report3["why"]
		]
		report_text += highlighted_body + "\n\n" + chosen_report3["additional_info"]

		paper_text.bbcode_enabled = true
		paper_text.text = report_text
