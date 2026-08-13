extends Node3D

var recruitment := RecruitmentManager.new()
var roster := RosterManager.new()
var board := BoardController.new()
var encounter := EncounterController.new()
var camera := Camera3D.new()
var roster_label := Label.new()
var detail_label := Label.new()
var candidate_box := VBoxContainer.new()
var roster_box := VBoxContainer.new()
var encounter_label := Label.new()

func _ready() -> void:
	_setup_world()
	_setup_systems()
	_setup_ui()
	recruitment.load_pool()
	_seed_demo_board()
	_refresh_ui()

func _setup_world() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-30,0)
	light.shadow_enabled = true
	add_child(light)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#111720")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b9c6d8")
	env.ambient_light_energy = 0.62
	environment.environment = env
	add_child(environment)
	camera.position = Vector3(0,20,18)
	camera.fov = 48
	camera.look_at(Vector3.ZERO, Vector3.UP)
	add_child(camera)

func _setup_systems() -> void:
	add_child(recruitment)
	add_child(roster)
	add_child(board)
	add_child(encounter)
	board.setup(camera)
	recruitment.recruited.connect(_on_recruited)
	board.selection_changed.connect(_on_selection)
	board.challenge_requested.connect(_on_challenge)
	encounter.resolved.connect(_on_encounter_resolved)
	encounter.status_changed.connect(func(text): encounter_label.text = text)

func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var left := PanelContainer.new()
	left.position = Vector2(18,18)
	left.size = Vector2(340,650)
	canvas.add_child(left)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 8)
	left.add_child(left_box)
	var title := Label.new()
	title.text = "BATTLEBOARD // ASSEMBLY"
	title.add_theme_font_size_override("font_size", 20)
	left_box.add_child(title)
	left_box.add_child(roster_label)
	left_box.add_child(HSeparator.new())
	left_box.add_child(detail_label)
	left_box.add_child(HSeparator.new())
	var roster_title := Label.new()
	roster_title.text = "ROSTER / POSITION"
	roster_title.add_theme_font_size_override("font_size", 16)
	left_box.add_child(roster_title)
	var roster_scroll := ScrollContainer.new()
	roster_scroll.custom_minimum_size = Vector2(320,300)
	left_box.add_child(roster_scroll)
	roster_box = VBoxContainer.new()
	roster_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_scroll.add_child(roster_box)
	var right := PanelContainer.new()
	right.position = Vector2(965,18)
	right.size = Vector2(295,560)
	canvas.add_child(right)
	var right_box := VBoxContainer.new()
	right.add_child(right_box)
	var recruit_title := Label.new()
	recruit_title.text = "SCOUTED RECRUITS"
	recruit_title.add_theme_font_size_override("font_size", 18)
	right_box.add_child(recruit_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(275,500)
	right_box.add_child(scroll)
	candidate_box = VBoxContainer.new()
	candidate_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(candidate_box)
	encounter_label.position = Vector2(330,20)
	encounter_label.size = Vector2(620,70)
	encounter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	encounter_label.add_theme_font_size_override("font_size", 17)
	canvas.add_child(encounter_label)

func _seed_demo_board() -> void:
	var hana := recruitment.recruit("hana")
	var ren := recruitment.recruit("ren")
	roster.assign("hana","knight")
	roster.assign("ren","pawn")
	board.add_profile(hana, Vector2i(1,1), "player", "knight")
	board.add_profile(ren, Vector2i(2,1), "player", "pawn")
	var rival_a := BBProfile.from_dictionary({"id":"rival_rook","name":"Iron Ward","level":5,"stats":{"power":70,"guard":82,"speed":38,"technique":58},"aptitudes":{"rook":90},"predispositions":["disciplined","protective"],"experiences":["city_league"]})
	var rival_b := BBProfile.from_dictionary({"id":"rival_bishop","name":"Glass Sage","level":5,"stats":{"power":48,"guard":45,"speed":62,"technique":86},"aptitudes":{"bishop":92},"predispositions":["analytical","patient"],"experiences":["academy_league"]})
	board.add_profile(rival_a, Vector2i(4,4), "rival", "rook")
	board.add_profile(rival_b, Vector2i(6,5), "rival", "bishop")

func _on_recruited(profile: BBProfile) -> void:
	roster.add_profile(profile)
	_refresh_ui()

func _on_selection(profile_id: String) -> void:
	if profile_id == "":
		detail_label.text = "Select one of your deployed members.\nGreen = legal move · Red = challenge"
		return
	var p := board.profile(profile_id)
	var role := board.state.role_of(profile_id)
	var support := board.active_support(profile_id)
	var lines := ["%s // %s" % [p.display_name, role.to_upper()], "Aptitude: %d" % roundi(p.aptitude_for(role)), ""]
	if support.is_empty(): lines.append("No active nearby affinity")
	for row in support:
		var other := board.profile(row["profile_id"])
		var a: Dictionary = row["affinity"]
		lines.append("%s: %s (%+d)" % [other.display_name, a["resonance"], roundi(a["score"])])
	detail_label.text = "\n".join(lines)

func _on_challenge(initiator_id: String, counterpart_id: String, destination: Vector2i) -> void:
	var context := BBEncounterContext.new(initiator_id, counterpart_id, destination)
	var support := board.active_support(initiator_id)
	var total := 0.0
	for row in support:
		total += maxf(0.0, float(row["affinity"].score)) * 0.03
	context.affinity_snapshot = {"support_bonus": minf(total, 6.0)}
	encounter.start(context, board, camera)

func _on_encounter_resolved(winner_id: String, loser_id: String, destination: Vector2i) -> void:
	board.resolve_challenge(winner_id, loser_id, destination)
	_refresh_ui()

func _refresh_ui() -> void:
	roster_label.text = "QUALIFICATION BOARD\nAssigned: %d / 16\nRoster: %d / 16\nGoal: assemble and certify a full board." % [roster.assignments.size(), roster.roster.size()]
	for child in roster_box.get_children(): child.queue_free()
	for profile_id in roster.roster.keys():
		var p: BBProfile = roster.roster[profile_id]
		var row := VBoxContainer.new()
		var label := Label.new()
		if roster.assignments.has(profile_id):
			label.text = "%s // %s" % [p.display_name, str(roster.assignments[profile_id]).to_upper()]
			row.add_child(label)
		else:
			label.text = p.display_name
			row.add_child(label)
			var roles := OptionButton.new()
			for role in ["pawn","knight","bishop","rook","queen","king"]:
				roles.add_item("%s  %d" % [role.capitalize(), roundi(p.aptitude_for(role))])
				roles.set_item_metadata(roles.item_count-1, role)
			row.add_child(roles)
			var deploy := Button.new()
			deploy.text = "Assign & Deploy"
			deploy.pressed.connect(func(id=profile_id, picker=roles): _assign_and_deploy(id, str(picker.get_item_metadata(picker.selected))))
			row.add_child(deploy)
		row.add_child(HSeparator.new())
		roster_box.add_child(row)
	for child in candidate_box.get_children(): child.queue_free()
	for candidate in recruitment.candidates():
		var card := VBoxContainer.new()
		var name := Label.new()
		name.text = "%s  // Lv.%d" % [candidate.display_name, candidate.level]
		name.add_theme_font_size_override("font_size", 16)
		card.add_child(name)
		var summary := Label.new()
		summary.text = _candidate_summary(candidate) + "\n" + _chemistry_projection(candidate)
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(summary)
		var button := Button.new()
		button.text = "Recruit"
		button.pressed.connect(func(id=candidate.profile_id): recruitment.recruit(id))
		card.add_child(button)
		card.add_child(HSeparator.new())
		candidate_box.add_child(card)

func _candidate_summary(p: BBProfile) -> String:
	var best_role := "pawn"
	var best_score := -1.0
	for role in p.aptitudes.keys():
		var score := p.aptitude_for(role)
		if score > best_score:
			best_score = score
			best_role = role
	return "%s\nBest fit: %s %d\nPredisposition: %s" % [p.background, best_role.capitalize(), roundi(best_score), ", ".join(p.predispositions)]

func _assign_and_deploy(profile_id: String, role: String) -> void:
	if not roster.assign(profile_id, role):
		encounter_label.text = "That board position is already full or unavailable."
		return
	var p: BBProfile = roster.roster[profile_id]
	if board.profile(profile_id) == null:
		var cell := _next_home_cell()
		if cell.x < 0:
			encounter_label.text = "No deployment cell is open."
			return
		board.add_profile(p, cell, "player", role)
	encounter_label.text = "%s assigned as %s." % [p.display_name, role.capitalize()]
	_refresh_ui()

func _next_home_cell() -> Vector2i:
	for y in range(0,3):
		for x in range(0,8):
			var cell := Vector2i(x,y)
			if board.state.occupant(cell) == "": return cell
	return Vector2i(-1,-1)

func _chemistry_projection(candidate: BBProfile) -> String:
	var best_name := "No roster history yet"
	var best_score := -999.0
	var resonance := "Neutral"
	for other in roster.roster.values():
		var result := BBAffinityEngine.evaluate(candidate, other)
		if float(result["score"]) > best_score:
			best_score = float(result["score"])
			best_name = other.display_name
			resonance = str(result["resonance"])
	if best_score <= -999.0: return best_name
	return "Best chemistry: %s // %s (%+d)" % [best_name, resonance, roundi(best_score)]
