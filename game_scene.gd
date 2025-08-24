extends Node2D

@onready var paper = $paper
@onready var student_paper = $"student paper"
@onready var paper_text: RichTextLabel = $paper/MarginContainer/Text

@onready var checklist_icon: Sprite2D = $checklist_icon
@onready var checklist_ui: Node2D = $ChecklistUI
@onready var close_button: Button = $CloseButton

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
	
	checklist_ui.visible = false
	close_button.visible = false
	
	$checklist_icon/Area2D.input_event.connect(_on_checklist_icon_input_event)
	close_button.pressed.connect(_on_close_button_pressed)
	


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Play cursor effect
		GlobalCursorManager.play_press_effect()
		paper_open = true
		paper.visible = true
		student_paper.visible = false
		
		#show text 
		var idx := rng.randi_range(0, articles.size() - 1)
		paper_text.text = articles[idx]

		
func _unhandled_input(event: InputEvent) -> void:
	if paper_open and event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_viewport().get_mouse_position()
		
		var tex_size = paper.texture.get_size()*paper.scale
		var top_left = paper.global_position - (tex_size * 0.5)
		var paper_rect = Rect2(top_left, tex_size)
		
		if not paper_rect.has_point(mouse_pos):
			# Don't play cursor effect here - this was causing it to play everywhere
			paper_open = false
			paper.visible = false
			student_paper.visible = true
			
# When the checklist icon is clicked
func _on_checklist_icon_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		checklist_ui.visible = true
		close_button.visible = true
 
# Close button
func _on_close_button_pressed() -> void:
	checklist_ui.visible = false
	close_button.visible = false
