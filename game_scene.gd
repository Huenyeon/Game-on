extends Node2D

@onready var paper = $paper
@onready var student_paper = $"student paper"
@onready var paper_text: RichTextLabel = $paper/MarginContainer/Text
@onready var player = $Player

var paper_open = false
var rng := RandomNumberGenerator.new()

var reports = [
	{
		"publisher": "BrightFuture Daily",
		"headline": "New Solar Panel Paint Can Charge Phones in Sunlight ☀️📱",
		"body": "On August 21, 2025, BrightFuture Daily reported that scientists at SunTech Academy developed a paint that can act like a solar panel. The article claimed that “any wall covered in the paint can charge a phone directly.”",
		"5ws": {
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
		"5ws": {
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
		"5ws": {
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
		"5ws": {
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
		"5ws": {
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
	
	player.connect("reached_middle", Callable(self, "_on_player_reached_middle"))


func get_random_reports(count: int) -> Array:
	var chosen = []
	while chosen.size() < count:
		var candidate = reports[rng.randi() % reports.size()]
		if candidate not in chosen:
			chosen.append(candidate)
	return chosen

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		paper_open = true
		paper.visible = true
		student_paper.visible = false
		
		# Pick one random report
		# Pick one random report
		var random_report = get_random_reports(1)[0]
		var w5 = random_report["5ws"]

		# Build plain text without BBCode
		var text_to_show = random_report.publisher + "\n\n" \
			+ "\"" + random_report.headline + "\"\n\n" \
			+ random_report.body + "\n\n" \
			
			+ "Who: " + w5["Who"] + "\n" \
			+ "What: " + w5["What"] + "\n" \
			+ "When: " + w5["When"] + "\n" \
			+ "Where: " + w5["Where"] + "\n" \
			+ "Why: " + w5["Why"] + "\n\n" \
			+ random_report.date
			
		paper_text.text = text_to_show

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
			
func _on_player_reached_middle():
	student_paper.visible = true

func _on_student_paper_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		paper.visible = true
		
