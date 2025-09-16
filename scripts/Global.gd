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


var audio_player: AudioStreamPlayer

# Publishers & Dates are always randomized separately
var publishers = [
	"Philippine Bright",
	"Inquire Daily",
	"AGM News",
	"Daily Sunlight",
	"MMDZ",
	"Bulletin Man",
	"NextGen PH News",
	"Star Sun",
	"NextWave Times",
	"Philippine Today"
]

var published_dates = []


func _ready():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.autoplay = false

func generate_random_published_dates(count: int = 3):
	published_dates.clear()

	var month_names = [
		"January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"
	]

	for i in range(count):
		var year = randi() % (2025 - 2016 + 1) + 2016  # random year 2016–2025
		var month = randi() % 12 + 1                   # random month 1–12
		var day = randi() % 17 + 15                    # random day 15–31
		
		# handle invalid dates (Feb, 30-day months)
		var valid_date = true
		if month == 2:
			var is_leap = (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)
			if day > 29 or (day == 29 and not is_leap):
				day = 28
		elif month in [4, 6, 9, 11] and day > 30:
			day = 30
		
		var month_name = month_names[month - 1]
		published_dates.append("%s %d, %d" % [month_name, day, year])


# Now each report "template" groups headline + 5Ws
var report_templates = [
	{
		"headline": "Flood Control Scandal Rocks Government ",
		"who": "Philippine Congress & Public Works Officials",
		"what": "implicated in a massive corruption scheme involving billions in flood control funds",
		"where": "nationwide",
		"when": "September 12, 2025",
		"why": "to investigate substandard or non-existent infrastructure funded by public money"
	},
	{
		"headline": "South China Sea Tensions Escalate 🇵🇭🇨🇳",
		"who": "Philippine Government & Chinese Officials",
		"what": "disputed China's plan to designate Scarborough Shoal as a nature preserve",
		"where": "Scarborough Shoal, South China Sea",
		"when": "September 12, 2025",
		"why": "to defend Philippine territorial claims and protect fishermen's rights"
	},
	{
		"headline": "Guimaras Bridge Funding Suspended by South Korea 🌉",
		"who": "Philippine Department of Finance & Korean Government",
		"what": "suspended funding for the Panay–Guimaras–Negros Bridge project",
		"where": "Panay, Guimaras, Negros Islands",
		"when": "September 2025",
		"why": "due to concerns over potential misuse and corruption amid infrastructure scandals"
	},
		{
		"headline": "Elon Musk No Longer World's Richest Man 💰",
		"who": "Elon Musk & Larry Ellison",
		"what": "Ellison surpassed Musk as the world's richest person due to Oracle's strong earnings",
		"where": "Global / United States",
		"when": "September 10, 2025",
		"why": "because Musk's Tesla stock declined while Ellison's net worth soared"
	},
	{
		"headline": "KPop Demon Hunters Takes South Korea by Storm 🎤👹",
		"who": "K-pop group HUNTR/X & Maggie Kang",
		"what": "fight evil using their music in the animated movie 'KPop Demon Hunters'",
		"where": "South Korea",
		"when": "September 2025",
		"why": "due to the film's popularity, merchandise, and chart-topping soundtrack"
	},
	{
		"headline": "AI-Generated Fire Photo Tricks Manila Firefighters 🚒🤖",
		"who": "Manila Fire Department & AI Developers",
		"what": "responded to a truck 'on fire' that was actually AI-generated",
		"where": "Parola, Manila",
		"when": "September 2025",
		"why": "to highlight dangers of AI-generated misinformation and fake news"
	}
]


# Build separate pools only for who/where/when
func get_field_pool(field: String) -> Array:
	var pool = []
	for template in report_templates:
		pool.append(template[field])
	return pool

var pool_who = get_field_pool("who")
var pool_where = get_field_pool("where")
var pool_when = get_field_pool("when")

# Utility: return shuffled copy of array
func shuffled_copy(arr: Array) -> Array:
	var copy = arr.duplicate()
	copy.shuffle()
	return copy

# Generate random reports
func get_random_reports(count: int) -> void:
	
	active_reports.clear()
	
	# shuffle templates so headline/what/why don’t duplicate
	var shuffled_templates = shuffled_copy(report_templates)
	
	# shuffle pools for who/where/when (so they don’t repeat until exhausted)
	var shuffled_who = shuffled_copy(pool_who)
	var shuffled_where = shuffled_copy(pool_where)
	var shuffled_when = shuffled_copy(pool_when)
	generate_random_published_dates()
	
	for i in range(count):
		var template = shuffled_templates[i % shuffled_templates.size()]
		
		var report = {
			"publisher": publishers[randi() % publishers.size()],
			"published_date": published_dates[randi() % published_dates.size()],

			# guaranteed unique per template
			"headline": template["headline"],
			"what": template["what"],
			"why": template["why"],

			"who": shuffled_who[i % shuffled_who.size()],
			"where": shuffled_where[i % shuffled_where.size()],
			"when": shuffled_when[i % shuffled_when.size()]
	}
		
		# Build body text
		report["body"] = "%s %s %s on %s %s." % [
			report["who"],
			report["what"],
			report["where"],
			report["when"],
			report["why"]
		]
		
		active_reports.append(report)

#add a date that's d halata nga outdated na like (January 2025)
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
			"date": published_dates[i % published_dates.size()],
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
	
	
		
var gamescene_songs = {
	"music1" :"res://assets/desktop/music1.mp3",
	"music2" :"res://assets/desktop/music2.mp3",
	"music3": "res://assets/desktop/music3.mp3"
}

var current_song_index: int = 1  # Track which song is selected globally
var current_note_name: String = "red"  # Track which note is selected

func _set_gamescene_song(index = 1):
	var song_name = "music%d" % index
	if gamescene_songs.has(song_name):
		var music_path = gamescene_songs[song_name]
		var audio_stream = load(music_path)
		if audio_stream:
			audio_stream.loop = true
			audio_player.stream = audio_stream
			audio_player.play()
			current_song_index = index  # Update global tracking
		else:
			print("Failed to load audio:", music_path)
	else:
		print("Song not found:", song_name)

func stop_music():
	if audio_player.stream and audio_player.stream.resource_path.ends_with("BG_Music.mp3"):
		audio_player.stop()
