extends Control

const NEXT_SCENE := "res://scenes/boot.tscn"

@onready var status_label: Label = $Center/Panel/Box/Status
@onready var start_button: Button = $Center/Panel/Box/Start

func _ready() -> void:
	print("BATTLEBOARD WEB ENTRY READY")
	status_label.text = "WEB RUNTIME READY"
	start_button.pressed.connect(_start_battleboard)

func _start_battleboard() -> void:
	start_button.disabled = true
	status_label.text = "Opening Battleboard boot…"
	var error: Error = get_tree().change_scene_to_file(NEXT_SCENE)
	if error != OK:
		status_label.text = "SCENE HANDOFF FAILED · error %d" % int(error)
		start_button.disabled = false
