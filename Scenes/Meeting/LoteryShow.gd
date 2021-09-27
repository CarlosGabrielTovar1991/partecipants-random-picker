extends Control

var path_data_Partecipants = "user://data/partecipants/partecipants.json"
var data_Partecipants = {}
var MeetingActive = true

var isSelectingNextPartecipant = false
var isSelectionOver = true
var partecipantsWheelId = 0

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
	$LightBulbs.setStatus('loop')
	$ShowPartecipantContainerSquare/LabelShowPartecipant.text = "Benvenuti!"
	var dataFile = File.new()
	#Load next partecipant Stream
	nextPartecipantStream = preload("res://Assets/Sounds/nextpartecipant.ogg")
	# Load meeting Ends Stream
	meetingEndsStream =  preload("res://Assets/Sounds/meetingends.ogg")
	meetingEndsStreamMusic =  preload("res://Assets/Sounds/loping_sting.ogg")
	# Load meeting ends image
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
		$LightBulbs.setStatus('loop')
		$ShowPartecipantContainerSquare/ShowPartecipantPicture.set_texture(meetingEndsTexture)
		$ShowPartecipantContainerSquare/LabelShowPartecipant.text = "Arrivederci!"
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
	var partecipantCard = load("res://Scenes/Meeting/PartecipantBallObject.tscn")
	var partecipantBallInstance = partecipantCard.instance()
	processPartecipants[data_Partecipants[currentPartecipant]._id] = processPartecipantObject
	partecipantBallInstance.find_node("PartecipantPicture").set_texture(textureFromImage)
	partecipantBallInstance.set_name(data_Partecipants[currentPartecipant]._id)
	partecipantBallInstance.set_collision_layer_bit(0, true)
	partecipantBallInstance.set_collision_mask_bit(0, true)
	partecipantBallInstance.set_collision_layer_bit(1, false)
	partecipantBallInstance.set_collision_mask_bit(1, false)
	partecipantBallInstance.set_collision_layer_bit(10, false)
	partecipantBallInstance.set_collision_mask_bit(10, false)
	partecipantBallInstance.set_z_index(1)
	partecipantBallInstance.position = Vector2(285, -25)
	add_child(partecipantBallInstance)
	partecipantsIdArray.push_back(data_Partecipants[currentPartecipant]._id)
	if (fromQuick == true && isSelectionOver == true):
		if (partecipantsIdArray.size() == 1):
			$CallNextOneButton.text = "FINALIZZARE IL MEETING"
		elif (currentPartecipantId != null):
			$CallNextOneButton.text = "AVANTI IL PROSSIMO!"
			$SkipPartecipantButton.disabled = false
			$SkipPartecipantButton.visible = true

func shufflePartecipantsList():
	var shuffledList = []
	var indexList = range(partecipantsIdArrayDisplay.size())
	for _i in range(partecipantsIdArrayDisplay.size()):
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
	var _nextScene = CommonScene.goto_scene("res://Scenes/Menu/Menu.tscn")

func find_node_by_name(root, name):
	if(root.get_name() == name): return root
	for child in root.get_children():
		if(child.get_name() == name):
			return child
		var found = find_node_by_name(child, name)
		if(found): return found
	return null

func startPartecipartSelectionProcess():
	$BallsContainer/PushUp/PushUpAreaCollision.disabled = false
	$BallsContainer/PushLeft/PushLeftAreaCollision.disabled = false
	$BallsContainer/PushRight/PushRightAreaCollision.disabled = false
	$SelectingMusicStream.play()
	$Timer.start()
	partecipantsWheelId = 0
	isSelectingNextPartecipant = true
	isSelectionOver = false
	$LightBulbs.setStatus('ring')
	$CallNextOneButton.disabled = true
	$CallNextOneButton.visible = false
	$SkipPartecipantButton.disabled = true
	$SkipPartecipantButton.visible = false

func get_random_number():
	randomNumberGenerator.randomize()
	return randomNumberGenerator.randi_range(0, partecipantsIdArray.size() - 1)

func _on_CallNextOneButton_pressed(skipped = false):
	var partecipantBallInstance = null
	var currentId = currentPartecipantId
	
	if (currentPartecipantId == null):
		currentPartecipantId = partecipantsIdArray[get_random_number()]
		startPartecipartSelectionProcess()
	else:
		partecipantBallInstance = find_node_by_name(get_tree().get_root(), data_Partecipants.get(currentPartecipantId)._id)
		if (skipped == false):
			partecipantsIdArray.erase(currentPartecipantId)
		if (partecipantsIdArray.size() > 0):
			while(currentId == currentPartecipantId):
				currentPartecipantId = partecipantsIdArray[get_random_number()]
			startPartecipartSelectionProcess()
		else:
			finishMeeting()
		if (skipped == false):
			partecipantBallInstance.set_z_index(2)
			partecipantBallInstance.set_mode(0)
			partecipantBallInstance.set_collision_layer_bit(0, false)
			partecipantBallInstance.set_collision_mask_bit(0, false)
			partecipantBallInstance.set_collision_layer_bit(1, true)
			partecipantBallInstance.set_collision_mask_bit(1, true)
			partecipantBallInstance.set_collision_layer_bit(10, false)
			partecipantBallInstance.set_collision_mask_bit(10, false)
			yield(get_tree().create_timer(5),"timeout")
			partecipantBallInstance.queue_free()
		else:
			partecipantBallInstance.set_collision_layer_bit(1, false)
			partecipantBallInstance.set_collision_mask_bit(1, false)
			partecipantBallInstance.set_collision_layer_bit(0, true)
			partecipantBallInstance.set_collision_mask_bit(0, true)
			partecipantBallInstance.set_collision_layer_bit(10, false)
			partecipantBallInstance.set_collision_mask_bit(10, false)

func _on_PartecipantNameAudioStream_finished():
	$SelectedMusicStream.play()

func displayCurrentPartecipantData(currentPartecipantData):
	$ShowPartecipantContainerSquare/LabelShowPartecipant.text = currentPartecipantData.name
	$ShowPartecipantContainerSquare/ShowPartecipantPicture.set_texture(currentPartecipantData.imageTextureData)

func setCurrentPartecipantData(currentPartecipantData):
	$LightBulbs.setStatus('loop')
	displayCurrentPartecipantData(currentPartecipantData)
	$PartecipantNameAudioStream.stream = currentPartecipantData.audioStreamData
	$PartecipantNameAudioStream.play()

func _on_SelectingMusicStream_finished():
	isSelectingNextPartecipant = false
	$BallsContainer/PushUp/PushUpAreaCollision.disabled = true
	$BallsContainer/PushLeft/PushLeftAreaCollision.disabled = true
	$BallsContainer/PushRight/PushRightAreaCollision.disabled = true
	var partecipantBallInstance = null
	partecipantBallInstance = find_node_by_name(get_tree().get_root(), data_Partecipants.get(currentPartecipantId)._id)
	partecipantBallInstance.set_collision_layer_bit(0, false)
	partecipantBallInstance.set_collision_mask_bit(0, false)
	partecipantBallInstance.set_collision_layer_bit(1, false)
	partecipantBallInstance.set_collision_mask_bit(1, false)
	partecipantBallInstance.set_collision_layer_bit(10, true)
	partecipantBallInstance.set_collision_mask_bit(10, true)
	partecipantBallInstance.set_z_index(4)
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
	$QuickAddLayer/QuickAddPartecipant/PartecipantsList.clear()
	for currentPartecipant in partecipantsIdArrayDisplay:
		if (!findPartecipantInCurrent(currentPartecipant._id)):
			$QuickAddLayer/QuickAddPartecipant/PartecipantsList.add_item(currentPartecipant.name, currentPartecipant.imageTextureData, true)
			$QuickAddLayer/QuickAddPartecipant/PartecipantsList.set_item_metadata($QuickAddLayer/QuickAddPartecipant/PartecipantsList.get_item_count() - 1, currentPartecipant)

func _on_QuickAddButton_pressed():
	if (MeetingActive == true):
		quickAddPartecipantIndex = null
		$CancelMeetingButton.disabled = true
		$QuickAddButton.disabled = true
		mapQuickAddPartecipantsList()
		$QuickAddLayer/QuickAddPartecipant.show_modal(true)

func _on_CancelQuickAdd_pressed():
	quickAddPartecipantIndex = null
	$CancelMeetingButton.disabled = false
	$QuickAddButton.disabled = false
	$QuickAddLayer/QuickAddPartecipant.hide()

func _on_PartecipantsList_item_selected(index):
	if (MeetingActive == true):
		if (quickAddPartecipantIndex == null || index != quickAddPartecipantIndex):
			quickAddPartecipantIndex = index
		else:
			var selectedPartecipantMetaData = $QuickAddLayer/QuickAddPartecipant/PartecipantsList.get_item_metadata(quickAddPartecipantIndex)
			insertPartecipantOnCurrentMeet(selectedPartecipantMetaData._id, selectedPartecipantMetaData, selectedPartecipantMetaData.imageTextureData, true)
			quickAddPartecipantIndex = null
			mapQuickAddPartecipantsList()
	pass
