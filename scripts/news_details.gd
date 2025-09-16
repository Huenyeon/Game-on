extends Node2D


@onready var set1 = $set1
@onready var set2 = $set2
@onready var set3 = $set3

func _ready():
	display_reports()

func display_reports():
	var sets = [set1, set2, set3]

	for i in range(Global.active_reports.size()):
		var report = Global.active_reports[i]
		var set_node = sets[i]

		set_node.get_node("HeadlineLabel").text = report["headline"]
		set_node.get_node("BodyLabel").text = report["body"]
		set_node.get_node("PublisherLabel").text = "Publisher: " + report["publisher"]
		set_node.get_node("DateLabel").text = "Date Published: " + report["published_date"]
