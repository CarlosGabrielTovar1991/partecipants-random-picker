extends Node

var currentScene = ""
var nextScene = ""
var exitGame = false

onready var animationPlayer = $"/root/CommonScene/CanvasLayer/ColorRect/AnimationPlayer"
onready var rectObject = $"/root/CommonScene/CanvasLayer/ColorRect"

func _ready():
	var root = get_tree().get_root()
	currentScene = root.get_child(root.get_child_count() - 1)
	animationPlayer.play("circle_size_change")

func goto_scene(path):
	rectObject.mouse_filter = 0
	CommonScene.nextScene = path
	animationPlayer.play_backwards()

func _deferred_goto_scene(path):
	# It is now safe to remove the current scene
	currentScene.free()
	# Load the new scene.
	var s = ResourceLoader.load(path)
	# Instance the new scene.
	currentScene = s.instance()
	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(currentScene)
	# Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(currentScene)
	rectObject.mouse_filter = 0
	animationPlayer.play()


func _on_AnimationPlayer_animation_finished(_anim_name):
	if (CommonScene.exitGame == true):
		get_tree().quit()
	else:
		rectObject.mouse_filter = 2
		if CommonScene.nextScene != "":
			call_deferred("_deferred_goto_scene", CommonScene.nextScene)
		CommonScene.nextScene = ""

func quitGame():
	CommonScene.exitGame = true
	rectObject.mouse_filter = 0
	animationPlayer.play_backwards()
