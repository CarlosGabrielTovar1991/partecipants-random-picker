extends Control

var path_data_Partecipants = "user://data/partecipants/partecipants.json"
var data_Partecipants = {}
var MeetingActive = true

var isSelectingNextPartecipant = false
var isSelectionOver = true
var partecipantsWheelId = 0
var cardOriginPosition = 0

var processPartecipants = {}
var partecipantsIdArray = []
var partecipantsIdArrayDisplay = []

var currentPartecipantId = null
var randomNumberGenerator = RandomNumberGenerator.new()

var nextPartecipantStream = null
var meetingEndsStream = null
var meetingEndsStreamMusic = null
var meetingEndsTexture = null

var partecipantsLoaded = false
var meetWelcomeEnd = false
var meetCanStart = false

var quickAddPartecipantIndex = null

func _ready():
	$CancelMeetingButton.disabled = true
	$CancelMeetingButton.visible = false
	$QuickAddButton.disabled = true
	$QuickAddButton.visible = false
	$SkipPartecipantButton.disabled = true
	$SkipPartecipantButton.visible = false
	$CallNextOneButton.disabled = true
	$CallNextOneButton.visible = false
	$LightBulbsRing.setStatus('loop')
	var dataFile = File.new()
	#Load next partecipant Stream
	nextPartecipantStream = preload("res://Assets/Sounds/nextpartecipant.ogg")
	# Load meeting Ends Stream
	meetingEndsStream =  preload("res://Assets/Sounds/meetingends.ogg")
	meetingEndsStreamMusic =  preload("res://Assets/Sounds/loping_sting.ogg")
	# Load meeting ends image
	var textureFromImage = ImageTexture.new()
	var newImage = preload("res://Assets/Images/hands.jpg")
	meetingEndsTexture = newImage
	
	if (dataFile.file_exists(path_data_Partecipants)):
		dataFile.open(path_data_Partecipants, dataFile.READ)
		data_Partecipants = parse_json(dataFile.get_as_text())
		dataFile.close()
		processsAndSetData()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (MeetingActive == false):
		$QuickAddButton.disabled = true
		$QuickAddButton.visible = false
	if (meetCanStart == false):
		enableStartButton()

func finishMeeting():
	if (partecipantsIdArray.size() <= 0 && currentPartecipantId != null):
		currentPartecipantId = null
		$LightBulbsRing.setStatus('loop')
		$ShowPartecipantContainer/ShowPartecipantPicture.set_texture(meetingEndsTexture)
		$ShowPartecipantContainer/LabelShowPartecipant.text = "Meeting concluso!\nGrazie e Buona giornata a tutti!"
		$WelcomeMusicStream.stream = meetingEndsStream
		$WelcomeMusicStream.play()
		# $BackgroundMusic.stop()
		# $BackgroundMusic.stream = meetingEndsStreamMusic
		# $BackgroundMusic.play()
		$PartecipantNameAudioStream.stream = null
		$CallNextOneButton.disabled = true
		$CallNextOneButton.visible = false
		MeetingActive = false


func _on_Timer_timeout():
	if (isSelectingNextPartecipant):
		displayCurrentPartecipantData(partecipantsIdArrayDisplay[partecipantsWheelId])
		partecipantsWheelId = partecipantsWheelId + 1
		if (partecipantsWheelId == partecipantsIdArrayDisplay.size()):
			partecipantsWheelId = 0

func insertPartecipantOnCurrentMeet(currentPartecipant, processPartecipantObject, textureFromImage, fromQuick = false):
	var partecipantCard = load("res://Scenes/Meeting/PartecipantCardObject.tscn")
	var partecipantCardInstance = partecipantCard.instance()
	processPartecipants[data_Partecipants[currentPartecipant]._id] = processPartecipantObject
	partecipantCardInstance.find_node("PartecipantPicture").set_texture(textureFromImage)
	partecipantCardInstance.set_name(data_Partecipants[currentPartecipant]._id)
	partecipantCardInstance.set_z_index(1)
	if (cardOriginPosition == 0):
		partecipantCardInstance.position = Vector2(175, -100)
		cardOriginPosition = 1
	elif (cardOriginPosition == 1):
		partecipantCardInstance.position = Vector2(1105, -100)
		cardOriginPosition = 0
	partecipantCardInstance.find_node("PartecipantNameLabel").text = data_Partecipants[currentPartecipant].name
	add_child(partecipantCardInstance)
	partecipantsIdArray.push_back(data_Partecipants[currentPartecipant]._id)
	if (fromQuick == true && isSelectionOver == true):
		if (partecipantsIdArray.size() == 1):
			$CallNextOneButton.text = "FINALIZZARE IL MEETING"
		else:
			$CallNextOneButton.text = "AVANTI IL PROSSIMO!"
			$SkipPartecipantButton.disabled = false
			$SkipPartecipantButton.visible = true

func shufflePartecipantsList():
	var shuffledList = []
	var indexList = range(partecipantsIdArrayDisplay.size())
	for i in range(partecipantsIdArrayDisplay.size()):
		randomNumberGenerator.randomize()
		var x = randomNumberGenerator.randi() % indexList.size()
		shuffledList.append(partecipantsIdArrayDisplay[indexList[x]])
		indexList.remove(x)
	return shuffledList

func processsAndSetData():
	for currentPartecipant in data_Partecipants:
		var newImage = Image.new()
		var textureFromImage = ImageTexture.new()
		var _error = newImage.load(data_Partecipants[currentPartecipant].image_path)
		textureFromImage.create_from_image(newImage)
		var ogg_file = File.new()
		ogg_file.open(data_Partecipants[currentPartecipant].audio_path, File.READ)
		var bytes = ogg_file.get_buffer(ogg_file.get_len())
		var stream = AudioStreamOGGVorbis.new()
		stream.data = bytes
		stream.loop = false
		var processPartecipantObject = {
			"_id": data_Partecipants[currentPartecipant]._id,
			"name": data_Partecipants[currentPartecipant].name,
			"active": data_Partecipants[currentPartecipant].active,
			"audioStreamData": stream,
			"imageTextureData": textureFromImage
		}
		partecipantsIdArrayDisplay.push_back(processPartecipantObject)
		ogg_file.close()
	var shuffledPartecipantsList = shufflePartecipantsList()
	for currentPartecipant in shuffledPartecipantsList:
		if (currentPartecipant.active == true):
			insertPartecipantOnCurrentMeet(currentPartecipant._id, currentPartecipant, currentPartecipant.imageTextureData)
			yield(get_tree().create_timer(0.3),"timeout")
	partecipantsLoaded = true

func _on_WelcomeMusicStream_finished():
	meetWelcomeEnd = true

func enableStartButton():
	if (meetWelcomeEnd == true && partecipantsLoaded == true):
		meetCanStart = true
		$CallNextOneButton.disabled = false
		$CallNextOneButton.visible = true
		$CancelMeetingButton.disabled = false
		$CancelMeetingButton.visible = true
		$QuickAddButton.disabled = false
		$QuickAddButton.visible = true
		

func _on_CancelMeetingButton_pressed():
	var _nextScene = get_tree().change_scene("res://Scenes/Menu/Menu.tscn")

func find_node_by_name(root, name):
	if(root.get_name() == name): return root
	for child in root.get_children():
		if(child.get_name() == name):
			return child
		var found = find_node_by_name(child, name)
		if(found): return found
	return null

func startPartecipartSelectionProcess():
	$SelectingMusicStream.play()
	$Timer.start()
	partecipantsWheelId = 0
	isSelectingNextPartecipant = true
	isSelectionOver = false
	$LightBulbsRing.setStatus('ring')
	$CallNextOneButton.disabled = true
	$CallNextOneButton.visible = false
	$SkipPartecipantButton.disabled = true
	$SkipPartecipantButton.visible = false

func get_random_number():
	randomNumberGenerator.randomize()
	return randomNumberGenerator.randi_range(0, partecipantsIdArray.size() - 1)

func _on_CallNextOneButton_pressed(skipped = false):
	var partecipantCardNode = null
	var currentId = currentPartecipantId
	
	if (currentPartecipantId == null):
		currentPartecipantId = partecipantsIdArray[get_random_number()]
		startPartecipartSelectionProcess()
	else:
		if (skipped == false):
			partecipantCardNode = find_node_by_name(get_tree().get_root(), data_Partecipants.get(currentPartecipantId)._id)
			partecipantsIdArray.erase(currentPartecipantId)
		if (partecipantsIdArray.size() > 0):
			while(currentId == currentPartecipantId):
				currentPartecipantId = partecipantsIdArray[get_random_number()]
			startPartecipartSelectionProcess()
		else:
			finishMeeting()
		if (skipped == false):
			partecipantCardNode.set_z_index(2)
			partecipantCardNode.set_mode(0)
			partecipantCardNode.set_collision_layer(32)
			partecipantCardNode.set_collision_mask(32)
			yield(get_tree().create_timer(5),"timeout")
			partecipantCardNode.queue_free()

func _on_PartecipantNameAudioStream_finished():
	$SelectedMusicStream.play()

func displayCurrentPartecipantData(currentPartecipantData):
	$ShowPartecipantContainer/LabelShowPartecipant.text = currentPartecipantData.name
	$ShowPartecipantContainer/ShowPartecipantPicture.set_texture(currentPartecipantData.imageTextureData)

func setCurrentPartecipantData(currentPartecipantData):
	$LightBulbsRing.setStatus('oddEvenLoop')
	displayCurrentPartecipantData(currentPartecipantData)
	$PartecipantNameAudioStream.stream = currentPartecipantData.audioStreamData
	$PartecipantNameAudioStream.play()

func _on_SelectingMusicStream_finished():
	isSelectingNextPartecipant = false
	$Timer.stop()
	$YouAreTheChoosedOne.play()
	setCurrentPartecipantData(processPartecipants.get(currentPartecipantId))

func _on_SelectedMusicStream_finished():
	$PartecipantNameAudioStream.stream = null
	isSelectionOver = true
	if (partecipantsIdArray.size() >= 1):
		$CallNextOneButton.disabled = false
		$CallNextOneButton.visible = true
		if (partecipantsIdArray.size() == 1):
			$CallNextOneButton.text = "FINALIZZARE IL MEETING"
		else:
			$SelectingMusicStream.stream = nextPartecipantStream
			$CallNextOneButton.text = "AVANTI IL PROSSIMO!"
			$SkipPartecipantButton.disabled = false
			$SkipPartecipantButton.visible = true
	else:
		$CallNextOneButton.disabled = true
		$CallNextOneButton.visible = false

func findPartecipantInCurrent(partecipantId):
	var find = false
	var i = 0
	while (i < partecipantsIdArray.size() && find == false):
		if partecipantsIdArray[i] == partecipantId:
			find = true
		i += 1
	return find

func mapQuickAddPartecipantsList():
	$QuickAddPartecipant/PartecipantsList.clear()
	for currentPartecipant in partecipantsIdArrayDisplay:
		if (!findPartecipantInCurrent(currentPartecipant._id)):
			$QuickAddPartecipant/PartecipantsList.add_item(currentPartecipant.name, currentPartecipant.imageTextureData, true)
			$QuickAddPartecipant/PartecipantsList.set_item_metadata($QuickAddPartecipant/PartecipantsList.get_item_count() - 1, currentPartecipant)

func _on_QuickAddButton_pressed():
	if (MeetingActive == true):
		quickAddPartecipantIndex = null
		$CancelMeetingButton.disabled = true
		$QuickAddButton.disabled = true
		mapQuickAddPartecipantsList()
		$QuickAddPartecipant.show_modal(true)

func _on_CancelQuickAdd_pressed():
	quickAddPartecipantIndex = null
	$CancelMeetingButton.disabled = false
	$QuickAddButton.disabled = false
	$QuickAddPartecipant.hide()

func _on_PartecipantsList_item_selected(index):
	if (MeetingActive == true):
		if (quickAddPartecipantIndex == null || index != quickAddPartecipantIndex):
			quickAddPartecipantIndex = index
		else:
			var selectedPartecipantMetaData = $QuickAddPartecipant/PartecipantsList.get_item_metadata(quickAddPartecipantIndex)
			insertPartecipantOnCurrentMeet(selectedPartecipantMetaData._id, selectedPartecipantMetaData, selectedPartecipantMetaData.imageTextureData, true)
			quickAddPartecipantIndex = null
			mapQuickAddPartecipantsList()
	pass
