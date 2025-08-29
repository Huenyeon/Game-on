extends Node2D

@onready var paper = $paper
@onready var student_paper = $"student paper"
@onready var paper_text: RichTextLabel = $paper/MarginContainer/Text
@onready var player = $Player

@onready var checklist_icon: Sprite2D = $checklist_icon
@onready var checklist_ui: Node2D = $ChecklistUI
@onready var close_button: Button = $CloseButton

var paper_open = false



func _ready() -> void:
	paper.visible = false
	student_paper.visible = false
	
	checklist_ui.visible = false
	close_button.visible = false
	
	$checklist_icon/Area2D.input_event.connect(_on_checklist_icon_input_event)
	close_button.pressed.connect(_on_close_button_pressed)
	
	if player:
		player.connect("reached_middle", Callable(self, "_on_player_reached_middle"))
		
		# Check if player is already in the middle when scene loads
		if Global.player_has_reached_middle:
			show_student_paper()

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		paper_open = true
		paper.visible = true
		student_paper.visible = false
		
		# If we haven't selected a student report yet, choose one that hasn't been used
		if Global.current_student_report == null:
			var all_reports = Global.correct_student_report + Global.incorrect_student_report
			var available_reports = []
			
			# Filter out reports that have already been used
			for report in all_reports:
				if not Global.used_reports.has(report):
					available_reports.append(report)
			
			# If there are no available reports, reset the used reports list
			if available_reports.size() == 0:
				Global.used_reports = []
				available_reports = all_reports
			
			# Select a random report from available ones
			if available_reports.size() > 0:
				var random_index = randi() % available_reports.size()
				Global.current_student_report = available_reports[random_index]
				Global.used_reports.append(Global.current_student_report)
		
		# Display the selected student report
		if Global.current_student_report:
			var report_text = "%s\n\n%s\n\n%s" % [
				Global.current_student_report["headline"],
				Global.current_student_report["body"],
				Global.current_student_report["additional_info"]
			]
			paper_text.text = report_text
		

func _unhandled_input(event: InputEvent) -> void:
	if paper_open and event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_viewport().get_mouse_position()

		var tex_size = paper.texture.get_size() * paper.scale
		var top_left = paper.global_position - (tex_size * 0.5)
		var paper_rect = Rect2(top_left, tex_size)

		if not paper_rect.has_point(mouse_pos):
			paper_open = false
			student_paper.visible = true
			paper.visible = false
			

# When the checklist icon is clicked
func _on_checklist_icon_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		checklist_ui.visible = true
		close_button.visible = true
 
# Close button
func _on_close_button_pressed() -> void:
	checklist_ui.visible = false
	close_button.visible = false

func _on_player_reached_middle():
	show_student_paper()

# New function to handle showing student paper
func show_student_paper():
	student_paper.visible = true
	Global.get_random_reports(3)
	Global.get_random_student_reports(1)
	
	

func _on_student_paper_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		paper_open = true
		
		
