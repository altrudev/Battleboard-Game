class_name CampaignUI
extends CanvasLayer

signal recruit_requested(profile_id: String)
signal train_requested(profile_id: String, role: String)
signal assign_requested(profile_id: String, role: String)
signal start_match_requested
signal save_requested

var selected_id := ""
var campaign: CampaignState
var recruitment: RecruitmentManager
var roster: RosterManager
var training: TrainingManager
var progression: ProgressionManager
var hq_root := Control.new()
var match_root := Control.new()
var stable_box := VBoxContainer.new()
var scout_box := VBoxContainer.new()
var detail := Label.new()
var top_status := Label.new()
var board_status := Label.new()
var role_picker := OptionButton.new()
var start_button := Button.new()
var match_status := Label.new()
var result_panel := PanelContainer.new()
var result_label := Label.new()

func setup(c: CampaignState, rec: RecruitmentManager, r: RosterManager, t: TrainingManager, p: ProgressionManager) -> void:
	campaign = c
	recruitment = rec
	roster = r
	training = t
	progression = p
	_build_hq()
	_build_match_hud()
	refresh()

func _build_hq() -> void:
	add_child(hq_root)
	hq_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var top := PanelContainer.new()
	top.position = Vector2(18, 14)
	top.size = Vector2(1244, 62)
	hq_root.add_child(top)
	top_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_status.add_theme_font_size_override("font_size", 18)
	top.add_child(top_status)

	var left := _panel(Vector2(18, 90), Vector2(355, 585))
	var left_box := VBoxContainer.new()
	left.add_child(left_box)
	var left_title := Label.new()
	left_title.text = "YOUR STABLE"
	left_title.add_theme_font_size_override("font_size", 20)
	left_box.add_child(left_title)
	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size = Vector2(335, 420)
	left_box.add_child(left_scroll)
	stable_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(stable_box)
	board_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_box.add_child(board_status)
	start_button.text = "ENTER LOCAL QUALIFIER"
	start_button.pressed.connect(_request_start_match)
	left_box.add_child(start_button)

	var center := _panel(Vector2(390, 90), Vector2(470, 585))
	var center_box := VBoxContainer.new()
	center.add_child(center_box)
	var center_title := Label.new()
	center_title.text = "FIGHTER DEVELOPMENT"
	center_title.add_theme_font_size_override("font_size", 20)
	center_box.add_child(center_title)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(440, 315)
	center_box.add_child(detail)
	for role in QualificationRules.ROLE_ORDER:
		role_picker.add_item(role.capitalize())
	center_box.add_child(role_picker)
	var train_button := Button.new()
	train_button.text = "TRAIN SELECTED ROLE (1 token)"
	train_button.pressed.connect(_train_pressed)
	center_box.add_child(train_button)
	var assign_button := Button.new()
	assign_button.text = "ASSIGN TO BOARD ROLE"
	assign_button.pressed.connect(_assign_pressed)
	center_box.add_child(assign_button)
	var save_button := Button.new()
	save_button.text = "SAVE CAMPAIGN"
	save_button.pressed.connect(_request_save)
	center_box.add_child(save_button)

	var right := _panel(Vector2(877, 90), Vector2(385, 585))
	var right_box := VBoxContainer.new()
	right.add_child(right_box)
	var right_title := Label.new()
	right_title.text = "SCOUTING BOARD"
	right_title.add_theme_font_size_override("font_size", 20)
	right_box.add_child(right_title)
	var right_scroll := ScrollContainer.new()
	right_scroll.custom_minimum_size = Vector2(365, 500)
	right_box.add_child(right_scroll)
	scout_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(scout_box)

func _build_match_hud() -> void:
	add_child(match_root)
	match_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	match_root.visible = false
	match_status.position = Vector2(330, 14)
	match_status.size = Vector2(620, 80)
	match_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match_status.add_theme_font_size_override("font_size", 18)
	match_root.add_child(match_status)
	result_panel.position = Vector2(430, 235)
	result_panel.size = Vector2(420, 210)
	result_panel.visible = false
	match_root.add_child(result_panel)
	var box := VBoxContainer.new()
	result_panel.add_child(box)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 24)
	box.add_child(result_label)
	var back_button := Button.new()
	back_button.text = "RETURN TO HQ"
	back_button.pressed.connect(show_hq)
	box.add_child(back_button)

func _panel(pos: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = size
	hq_root.add_child(panel)
	return panel

func refresh() -> void:
	if campaign == null:
		return
	top_status.text = "BRONZE LICENCE // Crowns %d   Training %d   Reputation %d   Record %d-%d\n%s" % [campaign.crowns, campaign.training_tokens, campaign.reputation, campaign.qualifier_wins, campaign.qualifier_losses, campaign.objective]
	board_status.text = "BOARD %d / 8\n%s" % [roster.assignments.size(), roster.qualification_summary()]
	start_button.disabled = not roster.is_qualification_ready()

	for child in stable_box.get_children():
		child.queue_free()
	var ids: Array = roster.roster.keys()
	ids.sort()
	for raw_id in ids:
		var profile_id := str(raw_id)
		var profile: BBProfile = roster.roster[profile_id]
		var button := Button.new()
		var role := roster.role_for(profile_id)
		var injury := progression.injury_for(profile_id)
		var status := role.capitalize() if role != "" else "Reserve"
		if injury != "":
			status += "  [%s]" % injury
		button.text = "%s  Lv.%d  %s" % [profile.display_name, profile.level, status]
		button.pressed.connect(select_profile.bind(profile_id))
		stable_box.add_child(button)

	for child in scout_box.get_children():
		child.queue_free()
	for profile in recruitment.candidates():
		var card := VBoxContainer.new()
		var label := Label.new()
		label.text = _scout_text(profile)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(label)
		var recruit_button := Button.new()
		var cost := recruitment.recruit_cost(profile)
		recruit_button.text = "RECRUIT · %d crowns" % cost
		recruit_button.disabled = not campaign.can_afford(cost)
		recruit_button.pressed.connect(_request_recruit.bind(profile.profile_id))
		card.add_child(recruit_button)
		card.add_child(HSeparator.new())
		scout_box.add_child(card)
	_refresh_detail()

func select_profile(profile_id: String) -> void:
	selected_id = profile_id
	_refresh_detail()

func _refresh_detail() -> void:
	if selected_id == "" or not roster.roster.has(selected_id):
		detail.text = "Select a fighter. Train them for a board position, then decide where they fit best in the eight-person qualifier board."
		return
	var profile: BBProfile = roster.roster[selected_id]
	var affinities: Array[String] = []
	for other in roster.roster.values():
		if other.profile_id == profile.profile_id:
			continue
		var result := BBAffinityEngine.evaluate(profile, other)
		if float(result["score"]) >= 15.0:
			affinities.append("%s: %s (%d)" % [other.display_name, str(result["resonance"]), roundi(float(result["score"]))])
	var affinity_text := "; ".join(PackedStringArray(affinities)) if not affinities.is_empty() else "No strong resonance discovered yet"
	var predisposition_text := ", ".join(PackedStringArray(profile.predispositions))
	detail.text = "%s // Lv.%d // XP %d/100\n%s\n\nPower %d  Guard %d  Speed %d  Technique %d\n\nAPTITUDES\nKing %d · Queen %d · Rook %d · Bishop %d · Knight %d · Pawn %d\n\nPredisposition: %s\nAffinity: %s" % [profile.display_name, profile.level, progression.xp_for(profile.profile_id), profile.background, roundi(profile.stat("power")), roundi(profile.stat("guard")), roundi(profile.stat("speed")), roundi(profile.stat("technique")), roundi(profile.aptitude_for("king")), roundi(profile.aptitude_for("queen")), roundi(profile.aptitude_for("rook")), roundi(profile.aptitude_for("bishop")), roundi(profile.aptitude_for("knight")), roundi(profile.aptitude_for("pawn")), predisposition_text, affinity_text]

func _scout_text(profile: BBProfile) -> String:
	var best := "pawn"
	var score := -1.0
	for role in profile.aptitudes.keys():
		if profile.aptitude_for(role) > score:
			score = profile.aptitude_for(role)
			best = str(role)
	var predisposition_text := ", ".join(PackedStringArray(profile.predispositions))
	return "%s // Lv.%d\n%s\nBest observed fit: %s %d\nPredisposition: %s" % [profile.display_name, profile.level, profile.background, best.capitalize(), roundi(score), predisposition_text]

func _selected_role() -> String:
	if role_picker.selected < 0:
		return "pawn"
	return role_picker.get_item_text(role_picker.selected).to_lower()

func _train_pressed() -> void:
	if selected_id != "":
		train_requested.emit(selected_id, _selected_role())

func _assign_pressed() -> void:
	if selected_id != "":
		assign_requested.emit(selected_id, _selected_role())

func _request_recruit(profile_id: String) -> void:
	recruit_requested.emit(profile_id)

func _request_start_match() -> void:
	start_match_requested.emit()

func _request_save() -> void:
	save_requested.emit()

func show_match(status: String) -> void:
	hq_root.visible = false
	match_root.visible = true
	result_panel.visible = false
	match_status.text = status

func update_match_status(text: String) -> void:
	match_status.text = text

func show_result(won: bool, text: String) -> void:
	match_root.visible = true
	result_panel.visible = true
	result_label.text = ("VICTORY\n" if won else "DEFEAT\n") + text

func show_hq() -> void:
	match_root.visible = false
	result_panel.visible = false
	hq_root.visible = true
	refresh()
