extends Sprite2D

var report: Dictionary

func set_report(new_report: Dictionary) -> void:
	report = new_report
	# Update the text label if it exists
	if has_node("Text") and report:
		var text_label = get_node("Text")
		text_label.text = report.get("headline", "") + "\n\n" + report.get("body", "")
