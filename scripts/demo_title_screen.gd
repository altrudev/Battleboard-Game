class_name DemoTitleScreen
extends CanvasLayer

signal new_demo_requested
signal continue_requested

var root := Control.new()
var continue_button := Button.new()

func setup(can_continue: bool) -> void:
    layer = 40
    add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shade := ColorRect.new()
    shade.color = Color(0.025, 0.035, 0.05, 0.98)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(shade)

    var panel := PanelContainer.new()
    panel.position = Vector2(330, 135)
    panel.size = Vector2(620, 450)
    root.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 18)
    panel.add_child(box)

    var kicker := Label.new()
    kicker.text = "ALTRU.DEV // BATTLEBOARD"
    kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    kicker.add_theme_font_size_override("font_size", 16)
    box.add_child(kicker)

    var title := Label.new()
    title.text = "BATTLEBOARD"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 42)
    box.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "CHAPTER ONE DEMO · NO BOARD, NO ENTRY"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 18)
    box.add_child(subtitle)

    var premise := Label.new()
    premise.text = "Recruit. Train. Assemble eight positions.\nEvery contested square becomes a fight you control."
    premise.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    premise.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(premise)

    var new_button := Button.new()
    new_button.text = "NEW DEMO"
    new_button.custom_minimum_size = Vector2(0, 48)
    new_button.pressed.connect(_on_new_pressed)
    box.add_child(new_button)

    continue_button.text = "CONTINUE"
    continue_button.custom_minimum_size = Vector2(0, 48)
    continue_button.disabled = not can_continue
    continue_button.pressed.connect(_on_continue_pressed)
    box.add_child(continue_button)

    var note := Label.new()
    note.text = "Target: 20–30 minute first qualification loop · Godot 4.7.1"
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(note)

func set_open(value: bool) -> void:
    root.visible = value

func _on_new_pressed() -> void:
    set_open(false)
    new_demo_requested.emit()

func _on_continue_pressed() -> void:
    set_open(false)
    continue_requested.emit()
