extends Control

var path_data_Partecipants = "user://data/partecipants/partecipants.json"
var data_Partecipants = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = Directory.new()
	var dataFile = File.new()
	var counter = 0
	#Check if folders for partecipant main data file exists
	if !dir.dir_exists("user://data/partecipants/"):
		dir.make_dir_recursive("user://data/partecipants/")
	else:
		if (dataFile.file_exists(path_data_Partecipants)):
			dataFile.open(path_data_Partecipants, dataFile.READ)
			data_Partecipants = parse_json(dataFile.get_as_text())
			dataFile.close()
	#Check if folders for partecipants files exists
	if !dir.dir_exists("user://data/partecipants/audios/"):
		dir.make_dir_recursive("user://data/partecipants/audios/")
	if !dir.dir_exists("user://data/partecipants/images/"):
		dir.make_dir_recursive("user://data/partecipants/images/")
		
	for currentPartecipant in data_Partecipants:
		if (data_Partecipants[currentPartecipant].active == true):
			counter = counter + 1
	if (counter <= 1):
		$StartMeetingButton.disabled = true
		$StartMeetingButton.hint_tooltip = "Per comminciare ci serve un elenco di almeno 2 partecipanti"
	else:
		$StartMeetingButton.disabled = false
		$StartMeetingButton.hint_tooltip = ""

# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(_delta):
#	pass


func _on_GoToPartecipantsListButton_pressed():
	CommonScene.goto_scene("res://Scenes/Partecipants/Partecipants.tscn")

func _on_ExitButton_pressed():
	CommonScene.quitGame()

func _on_StartMeetingButton_pressed():
	CommonScene.goto_scene("res://Scenes/Meeting/LoteryShow.tscn")
