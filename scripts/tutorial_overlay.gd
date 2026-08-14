class_name TutorialOverlay
extends CanvasLayer

var root := PanelContainer.new()
var step_label := Label.new()
var hint_label := Label.new()

func setup() -> void:
    layer = 20
    root.position = Vector2(885, 92)
    root.size = Vector2(365, 150)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    var box := VBoxContainer.new()
    root.add_child(box)
    step_label.add_theme_font_size_override("font_size", 16)
    box.add_child(step_label)
    hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint_label.add_theme_font_size_override("font_size", 14)
    box.add_child(hint_label)
    root.visible = false

func show_stage(stage: String, hint: String, step: int, total: int) -> void:
    root.visible = true
    step_label.text = "DEMO STEP %d/%d · %s" % [step, total, stage.to_upper()]
    hint_label.text = hint

func hide_guide() -> void:
    root.visible = false
