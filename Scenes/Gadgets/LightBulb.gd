extends Node

# Values for currentGroup
#		odd: odd number indexes
#		even: even number indexes
var currentGroup = 'even'

#	Values for status
#		ring: Do a ring animation 
#		oddEvenLoop: turn on/off the bulbs in group
#		loop: turn on/off all the bulbs 
#		off: all bulbs off
var status = 'off';

var runningRing = false
var runningIntermitent = false
var runningLoop = false
var setOff = true

var lightsOn = true
var bulbsLabel = "LightBulb%s"
var bulbCurrentIndex = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	match status:
		'off':
			if (setOff == false):
				runningIntermitent = false
				runningRing = false
				runningLoop = false
				$ringSwitchTimer.stop()
				$intermitentSwitchTimer.stop()
				$loopSwitchTimer.stop()
				turnOffAll()
				setOff = true
			pass
		'ring':
			$intermitentSwitchTimer.stop()
			$loopSwitchTimer.stop()
			runningIntermitent = false
			runningLoop = false
			setOff = false
			if (runningRing == false):
				turnOffAll()
				runningRing = true
				bulbCurrentIndex = 20
				$ringSwitchTimer.start()
				_on_ringSwitchTimer_timeout()
			pass
		'loop':
			$ringSwitchTimer.stop()
			$intermitentSwitchTimer.stop()
			runningRing = false
			runningIntermitent = true
			setOff = false
			if (runningLoop == false):
				turnOffAll()
				runningLoop = true
				lightsOn = true
				$loopSwitchTimer.start()
				_on_loopSwitchTimer_timeout()
			pass
		'oddEvenLoop':
			$ringSwitchTimer.stop()
			$loopSwitchTimer.stop()
			runningRing = false
			runningLoop = false
			setOff = false
			if (runningIntermitent == false):
				turnOffAll()
				runningIntermitent = true
				$intermitentSwitchTimer.start()
				_on_intermitentSwitchTimer_timeout()
			pass

func _on_ringSwitchTimer_timeout():
	bulbCurrentIndex += 1
	if (bulbCurrentIndex > 20):
		bulbCurrentIndex = 1
	var sp = get_node(bulbsLabel % bulbCurrentIndex)
	sp.animation = "turnOff"
	sp.set_frame(1)

func _on_intermitentSwitchTimer_timeout():
	for bulbIndex in range(1, 21):
		var sp = get_node(bulbsLabel % bulbIndex)
		if (bulbIndex % 2 == 0):
			if (currentGroup == 'even'):
				sp.animation = "turnOn"
				sp.set_frame(1)
			else:
				sp.animation = "turnOff"
				sp.set_frame(1)
		else:
			if (currentGroup == 'odd'):
				sp.animation = "turnOn"
				sp.set_frame(1)
			else:
				sp.animation = "turnOff"
				sp.set_frame(1)

	if (currentGroup == 'odd'):
		currentGroup = 'even'
	elif (currentGroup == 'even'):
		currentGroup = 'odd'

func _on_loopSwitchTimer_timeout():
	for bulbIndex in range(1, 21):
		var sp = get_node(bulbsLabel % bulbIndex)
		if (lightsOn == true):
			sp.animation = "on"
			sp.set_frame(1)
		else:
			sp.animation = "off"
			sp.set_frame(1)
	if (lightsOn == true):
		lightsOn = false
	elif (lightsOn == false):
		lightsOn = true

func turnOffAll():
	for bulbIndex in range(1, 21):
		var sp = get_node(bulbsLabel % bulbIndex)
		sp.animation = "turnOff"
		sp.set_frame(1)

func setStatus(newStatus):
	status = newStatus
