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

var reports = [
	{
		"publisher": "BrightFuture Daily",
		"headline": "New Solar Panel Paint Can Charge Phones in Sunlight ☀️📱",
		"body": 'On August 21, 2025, BrightFuture Daily reported that scientists at SunTech Academy developed a paint that can act like a solar panel. The article claimed that "any wall covered in the paint can charge a phone directly."',
		"five_ws": {
			"Who": "Scientists at SunTech Academy",
			"What": "Solar panel paint that charges phones",
			"When": "August 21, 2025",
			"Where": "Reported by BrightFuture Daily",
			"Why": "Claimed as renewable energy breakthrough"
		},
		"date": "August 21, 2025"
	},
	{
		"publisher": "NextWave Newsroom",
		"headline": "Students in Riverdale Town Can Graduate Early by Planting 100 Trees 🌳🎓",
		"body": "On August 19, 2025, NextWave Newsroom reported that Riverdale High would allow students to graduate one year earlier if they planted 100 trees. The article included student testimonials but no official school statement.",
		"five_ws": {
			"Who": "Riverdale High students",
			"What": "Claim about early graduation by planting trees",
			"When": "August 19, 2025",
			"Where": "Riverdale Town",
			"Why": "To promote environmental responsibility"
		},
		"date": "July 15, 2024"
	},
	{
		"publisher": "Knowledge Spark Gazette",
		"headline": "Homework-Free Fridays Become Law in Greenfield City 📝🎉",
		"body": "On August 17, 2025, Knowledge Spark Gazette published that the city council of Greenfield passed a law banning homework on Fridays for all students.",
		"five_ws": {
			"Who": "Greenfield City Council",
			"What": "Law banning homework on Fridays",
			"When": "August 17, 2025",
			"Where": "Greenfield City",
			"Why": "To reduce student stress"
		},
		"date": "May 2, 2023"
	},
	{
		"publisher": "Future Horizons Weekly",
		"headline": "AI Tutors Now Mandatory in Metro Schools 🤖📚",
		"body": "On August 20, 2025, Future Horizons Weekly claimed that Metro schools passed a rule requiring AI-powered tutors in all classrooms, raising debates among teachers and parents.",
		"five_ws": {
			"Who": "Metro Schools",
			"What": "Rule requiring AI tutors",
			"When": "August 20, 2025",
			"Where": "Metro City",
			"Why": "To enhance student learning"
		},
		"date": "August 20, 2025"
	},
	{
		"publisher": "Global Voice Tribune",
		"headline": "City Library Offers Free VR Headsets for Readers 📖🕶️",
		"body": "On August 18, 2025, Global Voice Tribune reported that Greenhill City Library introduced a program where members can borrow VR headsets to experience interactive storytelling.",
		"five_ws": {
			"Who": "Greenhill City Library",
			"What": "Free VR headset program",
			"When": "August 18, 2025",
			"Where": "Greenhill City",
			"Why": "To promote reading through technology"
		},
		"date": "August 18, 2025"
	}
]

func _ready() -> void:
	rng.randomize()
	paper.visible = false
	student_paper.visible = false
	paper_open = false 
	
	checklist_ui.visible = false
	
	$checklist_icon/Area2D.input_event.connect(_on_checklist_icon_input_event)
	
	
	if player:
		player.connect("reached_middle", Callable(self, "_on_player_reached_middle"))
		player.set_checklist_ui(checklist_ui)

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

func get_random_reports(count: int) -> Array:
	var chosen = []
	while chosen.size() < count:
		var candidate = reports[rng.randi() % reports.size()]
		if candidate not in chosen:
			chosen.append(candidate)
	return chosen



func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Cursor effect will play automatically via global input
		paper_open = true
		paper.visible = true
		student_paper.visible = false
		
		# Pick one random report
		var random_report = get_random_reports(1)[0]
		var w5 = random_report["five_ws"]

		# Build plain text without BBCode
		var text_to_show = random_report.publisher + "\n\n" + \
			"\"" + random_report.headline + "\"\n\n" + \
			random_report.body + "\n\n" + \
			"Who: " + w5["Who"] + "\n" + \
			"What: " + w5["What"] + "\n" + \
			"When: " + w5["When"] + "\n" + \
			"Where: " + w5["Where"] + "\n" + \
			"Why: " + w5["Why"] + "\n\n" + \
			random_report.date
			
		paper_text.text = text_to_show

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_viewport().get_mouse_position()
		
		# NEVER close the paper if stamp options are visible
		if paper_open and stamp_options and stamp_options.visible:
			# Paper stays open when stamp options are visible - do nothing
			pass
		# Only close paper if stamp options are NOT visible and not dragging
		elif paper_open and not dragging_check and not dragging_x:
			var tex_size = paper.texture.get_size()*paper.scale
			var top_left = paper.global_position - (tex_size * 0.5)
			var paper_rect = Rect2(top_left, tex_size)
			
			if not paper_rect.has_point(mouse_pos):
				# Don't play cursor effect here - this was causing it to play everywhere
				paper_open = false
				paper.visible = false
				student_paper.visible = true
		
		# Handle checklist closing when clicking outside
		if checklist_ui.visible:
			# Use the actual clipboard sprite rect if available
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

# When the checklist icon is clicked
func _on_checklist_icon_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		checklist_ui.visible = true
 


func _on_player_reached_middle():
	student_paper.visible = true

func _on_student_paper_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		paper.visible = true

func _on_stamp_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if stamp_options:
			var will_show := not stamp_options.visible
			stamp_options.visible = will_show
			
			# Also show/hide the student paper content when stamp options are toggled
			if will_show:
				# Show both stamp options and student paper content
				paper_open = true
				paper.visible = true
				student_paper.visible = false
				
				# Pick one random report to display
				var random_report = get_random_reports(1)[0]
				var w5 = random_report["five_ws"]

				# Build plain text without BBCode
				var text_to_show = random_report.publisher + "\n\n" + \
					"\"" + random_report.headline + "\"\n\n" + \
					random_report.body + "\n\n" + \
					"Who: " + w5["Who"] + "\n" + \
					"What: " + w5["What"] + "\n" + \
					"When: " + w5["When"] + "\n" + \
					"Where: " + w5["Where"] + "\n" + \
					"Why: " + w5["Why"] + "\n\n" + \
					random_report.date
					
				paper_text.text = text_to_show
			else:
				# Hide both stamp options and student paper content
				paper_open = false
				paper.visible = false
				student_paper.visible = true
				dragging_check = false
				dragging_x = false
				check_armed = false
				x_armed = false
			
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


 
