extends Node

const GAME_SCENE := "res://scenes/main.tscn"
const SAVE_PATH := "user://battleboard_demo_save.json"
const LEGACY_PATH := "user://battleboard_v03_save.json"

@onready var boot_ui: CanvasLayer = $BootUI
@onready var status_label: Label = $BootUI/Root/Center/Panel/Box/Status
@onready var new_button: Button = $BootUI/Root/Center/Panel/Box/NewDemo
@onready var continue_button: Button = $BootUI/Root/Center/Panel/Box/Continue

var game_instance: Node
var launch_started := false

func _ready() -> void:
    continue_button.disabled = not FileAccess.file_exists(SAVE_PATH) and not FileAccess.file_exists(LEGACY_PATH)
    new_button.pressed.connect(_start_new)
    continue_button.pressed.connect(_start_continue)
    status_label.text = "READY · Godot runtime reached the Battleboard boot scene."

func _start_new() -> void:
    ProjectSettings.set_setting("battleboard/session_mode", "new")
    _launch_game()

func _start_continue() -> void:
    ProjectSettings.set_setting("battleboard/session_mode", "continue")
    _launch_game()

func _launch_game() -> void:
    if launch_started:
        return
    launch_started = true
    new_button.disabled = true
    continue_button.disabled = true
    status_label.text = "Loading Chapter One runtime…"
    await get_tree().process_frame

    var resource := ResourceLoader.load(GAME_SCENE)
    var packed := resource as PackedScene
    if packed == null:
        _show_failure("GAME SCENE COULD NOT LOAD · Switch to Editor → Output for the parser error.")
        return

    game_instance = packed.instantiate()
    if game_instance == null:
        _show_failure("GAME SCENE COULD NOT INSTANTIATE · Switch to Editor → Output for details.")
        return

    if game_instance.has_signal("runtime_ready"):
        game_instance.connect("runtime_ready", _on_runtime_ready)
    add_child(game_instance)

    await get_tree().create_timer(3.0).timeout
    if boot_ui.visible:
        status_label.text = "STARTUP HAS NOT COMPLETED · Switch to Editor → Output and send the first red error."

func _on_runtime_ready() -> void:
    status_label.text = "Runtime ready."
    boot_ui.visible = false

func _show_failure(message: String) -> void:
    status_label.text = message
    launch_started = false
    new_button.disabled = false
    continue_button.disabled = not FileAccess.file_exists(SAVE_PATH) and not FileAccess.file_exists(LEGACY_PATH)
