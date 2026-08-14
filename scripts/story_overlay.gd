class_name StoryOverlay
extends CanvasLayer

signal sequence_finished(sequence_id: String)

var root := Control.new()
var title_label := Label.new()
var speaker_label := Label.new()
var text_label := Label.new()
var continue_button := Button.new()
var sequences: Dictionary = {}
var active_sequence := ""
var pages: Array = []
var page_index := 0

func setup(path := "res://data/story/chapter1.json") -> void:
    layer = 35
    _load_story(path)
    _build()
    root.visible = false

func is_open() -> bool:
    return root.visible

func show_sequence(sequence_id: String) -> void:
    if not sequences.has(sequence_id):
        sequence_finished.emit(sequence_id)
        return
    active_sequence = sequence_id
    pages = sequences[sequence_id]
    page_index = 0
    root.visible = true
    _render_page()

func close() -> void:
    root.visible = false

func _load_story(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Story file could not be opened: %s" % path)
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) == TYPE_DICTIONARY:
        sequences = parsed

func _build() -> void:
    add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shade := ColorRect.new()
    shade.color = Color(0.01, 0.015, 0.025, 0.88)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(shade)

    var panel := PanelContainer.new()
    panel.position = Vector2(170, 405)
    panel.size = Vector2(940, 255)
    root.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    panel.add_child(box)

    title_label.add_theme_font_size_override("font_size", 16)
    box.add_child(title_label)
    speaker_label.add_theme_font_size_override("font_size", 22)
    box.add_child(speaker_label)
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text_label.custom_minimum_size = Vector2(900, 105)
    text_label.add_theme_font_size_override("font_size", 18)
    box.add_child(text_label)
    continue_button.text = "CONTINUE"
    continue_button.pressed.connect(_next_page)
    box.add_child(continue_button)

func _render_page() -> void:
    if page_index < 0 or page_index >= pages.size():
        _finish()
        return
    var page: Dictionary = pages[page_index]
    title_label.text = str(page.get("title", ""))
    speaker_label.text = str(page.get("speaker", ""))
    text_label.text = str(page.get("text", ""))
    continue_button.text = "BEGIN" if page_index == pages.size() - 1 and active_sequence == "opening" else ("FINISH" if page_index == pages.size() - 1 else "CONTINUE")

func _next_page() -> void:
    page_index += 1
    if page_index >= pages.size():
        _finish()
    else:
        _render_page()

func _finish() -> void:
    var finished_id := active_sequence
    root.visible = false
    active_sequence = ""
    pages = []
    page_index = 0
    sequence_finished.emit(finished_id)
