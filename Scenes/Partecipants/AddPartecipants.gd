extends Control

var node_Partecipants = null

var currentLoadingType = ""
var nameIsSet = false
var imageIsSet = false
var tmpImagePath = ""
var audioIsSet = false
var tmpAudioPath = ""

func _ready():
	node_Partecipants = find_parent("Partecipants")
	var dir = Directory.new()
	# Check if temporal files folder exists
	if !dir.dir_exists("user://_tmp/"):
		dir.make_dir("user://_tmp/")
	else:
		dir.remove("user://_tmp/user_image.jpg")
		dir.remove("user://_tmp/user_image.jpeg")
		dir.remove("user://_tmp/user_image.png")
		dir.remove("user://_tmp/user_audio.ogg")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (imageIsSet):
		$AddPictureButton.text = ("Modificare foto")
		$RemovePictureButton.disabled = false
		$RemovePictureButton.visible = true
	else:
		$RemovePictureButton.disabled = true
		$RemovePictureButton.visible = false
		$AddPictureButton.text = ("Aggiungere foto")
		
	if (audioIsSet):
		if ($PlayPauseButton.disabled):
			$PlayPauseButton.disabled = false
		$AddVoiceButton.text = ("Modificare voce")
		$RemoveVoiceButton.disabled = false
		$RemoveVoiceButton.visible = true
	else:
		$RemoveVoiceButton.disabled = true
		$RemoveVoiceButton.visible = false
		$PlayPauseButton.texture_normal = null
		if (!($PlayPauseButton.disabled)):
			$PlayPauseButton.disabled = true
		$AddVoiceButton.text = ("Aggiungere voce")
	
	if(nameIsSet):
		$AddPartecipantFormButtons/ConfirmPartecipantButton.disabled = false
	else:
		$AddPartecipantFormButtons/ConfirmPartecipantButton.disabled = true

func setCurrentPartecipantImage(path):
	var dir = Directory.new()
	var newImage = Image.new()
	var textureFromImage = ImageTexture.new()
	var error = newImage.load(path)
	if error != OK:
		print("Error on load image")
		return
	error = dir.copy(path, "user://_tmp/user_image." + path.get_extension())
	if error != OK:
		print("Error on save image copy")
		return
	tmpImagePath = "user://_tmp/user_image." + path.get_extension()
	textureFromImage.create_from_image(newImage)
	$PartecipantPictureDisplay.set_texture(textureFromImage)
	imageIsSet = true

func setCurrentPartecipantAudio(path):
	var dir = Directory.new()
	var ogg_file = File.new()
	var error = dir.copy(path, "user://_tmp/user_audio." + path.get_extension())
	if error != OK:
		print("Error on save audio copy")
		return
	tmpAudioPath = "user://_tmp/user_audio." + path.get_extension()
	ogg_file.open(path, File.READ)
	var bytes = ogg_file.get_buffer(ogg_file.get_len())
	var stream = AudioStreamOGGVorbis.new()
	stream.data = bytes
	$AddPartecipantAudioStream.stream = stream
	$PlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")
	ogg_file.close()
	audioIsSet = true

func _on_AddPictureButton_pressed():
	currentLoadingType = "image"
	$FileLoader.filters = PoolStringArray(["*.png ; PNG Images","*.jpg ; JPG Images","*.jpeg ; JPEG Images"])
	$FileLoader.popup();

func _on_AddVoiceButton_pressed():
	currentLoadingType = "audio"
	$FileLoader.filters = PoolStringArray(["*.ogg ; OGG Audio"])
	$FileLoader.popup();

func _on_FileLoader_file_selected(path):
	if (currentLoadingType == "image"):
		setCurrentPartecipantImage(path)
	if currentLoadingType == "audio":
		setCurrentPartecipantAudio(path)
	currentLoadingType = ""

func _on_AudioStreamPlayer_finished():
	$PlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")

func _on_TextureButton_pressed():
	$AddPartecipantAudioStream.play()

func _on_PlayPauseButton_pressed():
	if ($AddPartecipantAudioStream.playing):
		$AddPartecipantAudioStream.stop()
		$PlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")
	else:
		$AddPartecipantAudioStream.play()
		$PlayPauseButton.texture_normal = load("res://Assets/Icons/pause.svg")

func _on_NameInput_text_changed(new_text):
	if ($NameInput.text.strip_edges().length() >= 3):
		nameIsSet = true
	else:
		nameIsSet = false

func clearPartecipantData():
	var dir = Directory.new()
	imageIsSet = false
	nameIsSet = false
	audioIsSet = false
	tmpAudioPath = ""
	tmpImagePath = ""
	$NameInput.text = ""
	$AddPartecipantAudioStream.stream = null
	$PartecipantPictureDisplay.set_texture(load("res://Assets/Images/default_avatar.png"))
	dir.remove("user://_tmp/user_image.jpg")
	dir.remove("user://_tmp/user_audio.ogg")


func _on_RemoveVoiceButton_pressed():
	var dir = Directory.new()
	audioIsSet = false
	tmpAudioPath = ""
	$AddPartecipantAudioStream.stream = null
	dir.remove("user://_tmp/user_audio.ogg")

func _on_RemovePictureButton_pressed():
	var dir = Directory.new()
	imageIsSet = false
	tmpImagePath = ""
	$PartecipantPictureDisplay.set_texture(load("res://Assets/Images/default_avatar.png"))
	dir.remove("user://_tmp/user_image.jpg")

func _on_ResetPartecipantButton_pressed():
	clearPartecipantData()

func _on_ConfirmPartecipantButton_pressed():
	var partecipantAdded = node_Partecipants.onAddEditPartecipant($NameInput.text.strip_edges(), imageIsSet, tmpImagePath, audioIsSet, tmpAudioPath)
	if (partecipantAdded):
		clearPartecipantData()
		node_Partecipants.abortAddPartecipant()

func _on_CancelPartecipantButton_pressed():
	clearPartecipantData()
	node_Partecipants.abortAddPartecipant()
