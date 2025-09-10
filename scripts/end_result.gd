extends Node2D

@onready var result_sprite: Sprite2D = $Panel/ResultSprite
@onready var info_label: Label = $Panel/VBox/InfoLabel
@onready var continue_btn: Button = $Panel/VBox/ContinueButton

var tex_ok: Texture2D = preload("res://assets/images/2.png")
var tex_bad: Texture2D = preload("res://assets/images/1.png")

func _ready() -> void:
	# Safe read of the last stamp info
	var info = null
	if "last_stamp" in Global:
		info = Global.last_stamp
	if info == null:
		info_label.text = "Time's up! Let's go again."
		result_sprite.texture = tex_bad
		return

	var stamp_type: String = info.get("type", "")
	var report = info.get("report", null)

	# Determine whether the student's report matches any computer report (by headline)
	var matched := false
	if report != null:
		for r in Global.active_reports:
			if r.has("headline") and r["headline"] == report.get("headline", ""):
				matched = true
				break

	# Normal correctness: matched & approved OR not matched & denied
	var normal_correct := (matched and stamp_type == "approved") or (not matched and stamp_type == "denied")
	var correct_decision := normal_correct
	# Apply invert flag if present
	if "end_result_inverted" in Global and Global.end_result_inverted:
		correct_decision = not normal_correct

	# Show result image and message
	if correct_decision:
		result_sprite.texture = tex_ok
		info_label.text = "Great job scanning the paper!"
	else:
		result_sprite.texture = tex_bad
		info_label.text = "It looks like the scan didn’t come out quite right."
	# Ensure the TextureRect uses centered scaling (scene already uses CenterContainer + stretch mode)
	continue_btn.pressed.connect(_on_continue_pressed)

func _on_continue_pressed() -> void:
	# Clear last stamp so next round starts clean
	if "last_stamp" in Global:
		Global.last_stamp = null
	# Optionally clear current student report so next open gives new one
	Global.current_student_report = null
	# Return to game scene
	get_tree().change_scene_to_file("res://scene/menu.tscn")
	
