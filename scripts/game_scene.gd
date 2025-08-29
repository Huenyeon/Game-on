extends Node2D

@onready var paper = $paper
@onready var student_paper = $"student paper"
@onready var paper_text: RichTextLabel = $paper/MarginContainer/Text
@onready var stamp: Sprite2D = $stamp
@onready var stamp_options: Node2D = $stamp/StampOptions
@onready var stamp_check_option: Sprite2D = $stamp/StampOptions/CheckOption
@onready var stamp_x_option: Sprite2D = $stamp/StampOptions/XOption

# =======================
# Variables
# =======================
var paper_open = false
var rng := RandomNumberGenerator.new()

var articles := [
	"""BrightFuture Daily
	
“New Solar Panel Paint Can Charge Phones in Sunlight ”

On August 21, 2025, BrightFuture Daily reported that scientists at SunTech Academy developed a paint that can act like a solar panel. The article claimed that “any wall covered in the paint can charge a phone directly.”""",

	"""NextWave Newsroom

“Students in Riverdale Town Can Graduate Early by Planting 100 Trees ”

On August 19, 2025, NextWave Newsroom reported that Riverdale High would allow 
students to graduate one year earlier if they planted 100 trees. 
The article included student testimonials but no official school statement.""",

	""" Knowledge Spark Gazette

“Homework-Free Fridays Become Law in Greenfield City”

On August 17, 2025, Knowledge Spark Gazette published that the city council of 
Greenfield passed a law banning homework on Fridays for all students.

Date Published: May 2, 2023"""
]



func _ready() -> void:
	rng.randomize()
	paper.visible = false
	student_paper.visible = true
	paper_open = false 
	stamp_options.visible = false

	# Assign textures for stamp options
	var check_tex: Texture2D = load("res://assets/Stamp checkbox.png")
	var x_tex: Texture2D = load("res://assets/Stamp x.png")
	if check_tex:
		stamp_check_option.texture = check_tex
	if x_tex:
		stamp_x_option.texture = x_tex


# =======================
# When the player clicks on the student paper
# =======================
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		paper_open = true
		paper.visible = true
		student_paper.visible = false
		
		#show text 
		var idx := rng.randi_range(0, articles.size() - 1)
		paper_text.text = articles[idx]


func _on_stamp_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if stamp_options:
			var will_show := not stamp_options.visible
			stamp_options.visible = will_show
			# Track that the stamp Area2D was clicked (stamp UI opened)
			if "stamp_ui_opened" in Global:
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
				if "stamp_ui_opened" in Global:
					Global.stamp_ui_opened = false
			
			# Reset positions to original on reopen
			if will_show:
				if check_option_sprite:
					check_option_sprite.global_position = check_option_original_global
				if x_option_sprite:
					x_option_sprite.global_position = x_option_original_global


func _unhandled_input(event: InputEvent) -> void:
	if paper_open and event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_viewport().get_mouse_position()
		
		var tex_size = paper.texture.get_size()*paper.scale
		var top_left = paper.global_position - (tex_size * 0.5)
		var paper_rect = Rect2(top_left, tex_size)
		
		if not paper_rect.has_point(mouse_pos):
			paper_open = false
			paper.visible = false
			student_paper.visible = true

	# Hide stamp options when clicking elsewhere
	if event is InputEventMouseButton and event.pressed:
		if stamp_options.visible:
			var mouse_pos2 = get_viewport().get_mouse_position()
			var check_size := (check_option_sprite.texture != null) ? check_option_sprite.texture.get_size() * check_option_sprite.global_scale : Vector2.ZERO
			var x_size := (x_option_sprite.texture != null) ? x_option_sprite.texture.get_size() * x_option_sprite.global_scale : Vector2.ZERO
			var check_top_left := check_option_sprite.global_position - (check_size * 0.5)
			var x_top_left := x_option_sprite.global_position - (x_size * 0.5)
			var check_rect := Rect2(check_top_left, check_size)
			var x_rect := Rect2(x_top_left, x_size)
			if not (check_rect.has_point(mouse_pos2) or x_rect.has_point(mouse_pos2)):
				stamp_options.visible = false
				# Stamp UI closed -> clear global flag
				if "stamp_ui_opened" in Global:
					Global.stamp_ui_opened = false


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
			if "stamp_ui_opened" in Global:
				Global.stamp_ui_opened = false
			return
		# TODO: implement check stamping behavior
		get_tree().set_input_as_handled()


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
			if "stamp_ui_opened" in Global:
				Global.stamp_ui_opened = false
			return
		# TODO: implement X stamping behavior
		get_tree().set_input_as_handled()
