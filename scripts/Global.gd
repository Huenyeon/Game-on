extends Node




var active_reports: Array = []
var correct_student_report: Array = []
var incorrect_student_report: Array =[]

var player_has_reached_middle = false

var current_student_report = null  # Store the selected student report
var used_reports = []  # Track which reports have already been used

# New: whether the stamp area was clicked and the stamp UI is open
var stamp_ui_opened: bool = false

# New: store last stamp decision and associated student report for result scene
var last_stamp = null

# New: if true, invert correctness logic in end-result scene
var end_result_inverted: bool = false


# Publishers & Dates are always randomized separately
var publishers = [
	"BrightFuture Daily",
	"NextWave Newsroom",
	"Knowledge Spark Gazette",
	"Future Focus Times"
]

var dates = [
	"August 21, 2025",
	"August 19, 2025",
	"August 17, 2025",
	"July 30, 2025",
	"June 15, 2025"
]

var additional_info  = [
	"Greenhill City Library now lets members borrow VR headsets for interactive storytelling. This was reported by Global Voice Tribune on August 18, 2025.",
	"Metro schools passed a rule for AI-powered tutors in all classrooms, as reported by Future Horizons Weekly on August 20, 2025. This has sparked debate among teachers and parents.",
	"The city council of Greenfield passed a law banning homework on Fridays for all students. This was published by Knowledge Spark Gazette on August 17, 2025.",
	"According to a NextWave Newsroom report, Riverdale High will let students graduate a year early if they plant 100 trees. The article, published on August 19, 2025, included student testimonials but no official school statement.",
	"Scientists at SunTech Academy developed a solar panel paint that can charge a phone directly from any wall. BrightFuture Daily reported on this on August 21, 2025."
	
]

# Now each report "template" groups headline + 5Ws
var report_templates = [
	{
		"headline": "Solar Paint Charges Phones 🔋 ",
		"who": "Scientists at SunTech Academy",
		"what": "developed a paint that acts like a solar panel",
		"where": "in Horizon Valley",
		"when": "August 21, 2025",
		"why": "to promote renewable energy use"
	},
	{
		"headline": "Plant Trees, Graduate Early 🌳",
		"who": "Students of Riverdale High",
		"what": "started planting 100 trees to graduate early",
		"where": "in Riverdale Town",
		"when": "August 19, 2025",
		"why": "to encourage environmental awareness"
	},
	{
		"headline": "Fridays Are Now Homework-Free 📑",
		"who": "Sity council of Greenfield",
		"what": "passed a law banning homework on Fridays",
		"where": "in Greenfield City",
		"when": "August 17, 2025",
		"why": "to reduce student stress"
	},
	{
		"headline": "AI Teacher Assistant Enters Schools 🤖",
		"who": "Mayor Elisa Tran",
		"what": "introduced a robot assistant for classrooms",
		"where": "in Crestwood",
		"when": "July 30, 2025",
		"why": "to modernize learning"
	},
	{
		"headline": "Underground Library Discovered 📚",
		"who": "A group of teachers",
		"what": "opened a hidden library to the public",
		"where": "in Metro City",
		"when": "June 15, 2025",
		"why": "to preserve cultural heritage"
	}
]



# Generate random reports
func get_random_reports(count: int) -> void:
	active_reports.clear()
	for i in range(count):
		var template = report_templates[randi() % report_templates.size()]
		var report = {
			"publisher": publishers[randi() % publishers.size()],
			"date": dates[randi() % dates.size()],
			"additional_info": additional_info[randi() % additional_info.size()],
			"headline": template["headline"],
			"who": template["who"],
			"what": template["what"],
			"where": template["where"],
			"when": template["when"],
			"why": template["why"]
		}
		# build body text
		report["body"] = "%s %s %s on %s %s." % [
			report["who"],
			report["what"],
			report["where"],
			report["when"],
			report["why"]
		]
		active_reports.append(report)
		
func get_random_student_reports(correct_count: int) -> void:
	correct_student_report.clear()
	incorrect_student_report.clear()
	
	correct_count = clamp(correct_count, 0,3)
	var incorrect_count = 3 - correct_count
	
	for i in range(min(correct_count, active_reports.size())):
		var correct_copy = active_reports[i].duplicate()
		correct_student_report.append(correct_copy)
		
	for i in range(incorrect_count):
		var template = report_templates[i % report_templates.size()]
		var report = {
			"publisher": publishers[i % publishers.size()],
			"date": dates[i % dates.size()],
			"additional_info": additional_info[i % additional_info.size()],
			"headline": template["headline"], # keep headline
			"who": template["who"],
			"what": template["what"],
			"where": template["where"],
			"when": template["when"],
			"why": template["why"]
		}
		report["body"] = "%s %s %s on %s %s." % [
			report["who"],
			report["what"],
			report["where"],
			report["when"],
			report["why"]
		]
		incorrect_student_report.append(report)
		
		print("correct reports:", correct_student_report.size())
		print("Incorrect reports:", incorrect_student_report.size())
		
	
func reset_report_tracking():
	current_student_report = null
	used_reports = []

