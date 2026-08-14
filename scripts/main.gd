extends Node3D

const VERSION := "0.2.0-visual-proof"

var recruitment := RecruitmentManager.new()
var roster := RosterManager.new()
var board := BoardController.new()
var encounter := EncounterController.new()
var camera := Camera3D.new()
var roster_label := Label.new()
var detail_label := Label.new()
var candidate_box := VBoxContainer.new()
var encounter_label := Label.new()

func _ready() -> void:
	_setup_world()
	_setup_systems()
	_setup_ui()
	recruitment.load_pool()
	_seed_demo_board()
	_refresh_ui()

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
	encounter.status_changed.connect(func(text: String): encounter_label.text = text)

func _setup_world() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-58, -28, 0)
	key.light_energy = 1.05
	key.shadow_enabled = true
	add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-8, 7, 4)
	rim.omni_range = 22.0
	rim.light_energy = 4.0
	rim.light_color = Color("#6d82a4")
	add_child(rim)
	var warm := OmniLight3D.new()
	warm.position = Vector3(8, 5, -5)
	warm.omni_range = 17.0
	warm.light_energy = 3.0
	warm.light_color = Color("#a66b53")
	add_child(warm)
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#0b1017")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#9aa9bf")
	env.ambient_light_energy = 0.48
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)
	_build_arena()
	camera.position = Vector3(0, 20.5, 18.5)
	camera.fov = 48
	camera.look_at(Vector3.ZERO, Vector3.UP)
	add_child(camera)

func _build_arena() -> void:
	_add_box(Vector3(0, -0.62, 0), Vector3(30, 0.25, 30), Color("#11161d"))
	for z in [-12.0, 12.0]:
		_add_gate(Vector3(0, 0, z))
	for x in [-12.0, 12.0]:
		for z in [-8.0, -2.5, 2.5, 8.0]:
			_add_lantern(Vector3(x, 0, z))
	for x in [-7.5, 7.5]:
		for z in [-11.4, 11.4]:
			_add_box(Vector3(x, 2.0, z), Vector3(1.2, 2.4, 0.08), Color("#693f42") if z > 0 else Color("#435a78"))

func _add_gate(origin: Vector3) -> void:
	for x in [-3.4, 3.4]:
		_add_box(origin + Vector3(x, 2.0, 0), Vector3(0.48, 4.4, 0.48), Color("#3a2526"))
	_add_box(origin + Vector3(0, 4.0, 0), Vector3(8.4, 0.42, 0.62), Color("#3a2526"))
	_add_box(origin + Vector3(0, 4.46, 0), Vector3(9.2, 0.22, 0.85), Color("#3a2526"))

func _add_lantern(origin: Vector3) -> void:
	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.06
	post_mesh.bottom_radius = 0.08
	post_mesh.height = 2.0
	post.mesh = post_mesh
	post.position = origin + Vector3(0, 0.6, 0)
	post.material_override = _mat(Color("#292d32"), 0.75)
	add_child(post)
	var lamp := MeshInstance3D.new()
	var lamp_mesh := BoxMesh.new()
	lamp_mesh.size = Vector3(0.42, 0.58, 0.42)
	lamp.mesh = lamp_mesh
	lamp.position = origin + Vector3(0, 1.55, 0)
	var glow := _mat(Color("#e5b96a"), 0.38)
	glow.emission_enabled = true
	glow.emission = Color("#d99d42")
	glow.emission_energy_multiplier = 1.8
	lamp.material_override = glow
	add_child(lamp)

func _add_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = _mat(color, 0.75)
	add_child(node)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var left := _panel(Vector2(18, 18), Vector2(340, 650), canvas)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 8)
	left.add_child(left_box)
	var title := Label.new()
	title.text = "BATTLEBOARD // ASSEMBLY"
	title.add_theme_font_size_override("font_size", 20)
	left_box.add_child(title)
	var version := Label.new()
	version.text = VERSION
	version.modulate = Color("#97a6ba")
	left_box.add_child(version)
	left_box.add_child(roster_label)
	left_box.add_child(HSeparator.new())
	left_box.add_child(detail_label)
	var right := _panel(Vector2(965, 18), Vector2(295, 560), canvas)
	var right_box := VBoxContainer.new()
	right.add_child(right_box)
	var recruit_title := Label.new()
	recruit_title.text = "SCOUTED RECRUITS"
	recruit_title.add_theme_font_size_override("font_size", 18)
	right_box.add_child(recruit_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(275, 500)
	right_box.add_child(scroll)
	candidate_box = VBoxContainer.new()
	candidate_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(candidate_box)
	encounter_label.position = Vector2(350, 18)
	encounter_label.size = Vector2(590, 100)
	encounter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	encounter_label.add_theme_font_size_override("font_size", 17)
	canvas.add_child(encounter_label)
	var hint := Label.new()
	hint.position = Vector2(395, 665)
	hint.size = Vector2(500, 40)
	hint.text = "TACTICAL: click fighter → highlighted square    DIRECT: WASD / Click / Q / E / Shift"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color("#b7c1ce")
	canvas.add_child(hint)

func _panel(pos: Vector2, size: Vector2, parent: Node) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = size
	parent.add_child(panel)
	return panel

func _seed_demo_board() -> void:
	var hana := recruitment.recruit("hana")
	var ren := recruitment.recruit("ren")
	roster.assign("hana", "knight")
	roster.assign("ren", "pawn")
	board.add_profile(hana, Vector2i(1, 1), "player", "knight")
	board.add_profile(ren, Vector2i(2, 1), "player", "pawn")
	var ward := _rival("iron_ward", "Iron Ward", "Arena Guard", 78, 52, 60, 84)
	var sage := _rival("glass_sage", "Glass Sage", "House Arcanist", 48, 82, 69, 46)
	board.add_profile(ward, Vector2i(2, 3), "rival", "knight")
	board.add_profile(sage, Vector2i(5, 5), "rival", "bishop")
	encounter_label.text = "Select Hana, then Iron Ward. Ren begins adjacent for an affinity intervention."

func _rival(id: String, name: String, background: String, power: float, technique: float, speed: float, defense: float) -> BBProfile:
	return BBProfile.from_dictionary({
		"id": id, "name": name, "background": background, "level": 9,
		"stats": {"power": power, "technique": technique, "speed": speed, "defense": defense},
		"aptitudes": {"pawn": 50, "knight": 72, "bishop": 72, "rook": 72, "queen": 60, "king": 60},
		"predispositions": ["disciplined"], "experiences": ["league_match"], "traits": [], "relationships": {}
	})

func _on_challenge(initiator_id: String, counterpart_id: String, destination: Vector2i) -> void:
	var context := BBEncounterContext.new(initiator_id, counterpart_id, destination)
	var supports := board.active_support(initiator_id)
	if not supports.is_empty():
		var best: Dictionary = supports[0]
		context.initiator_support.append(str(best["profile_id"]))
		context.affinity_snapshot = {
			"supporter_id": str(best["profile_id"]),
			"support_bonus": maxf(0.0, float(best["affinity"]["score"]) * 0.04),
			"resonance": str(best["affinity"]["resonance"]),
		}
	encounter.start(context, board, camera)

func _on_encounter_resolved(winner_id: String, loser_id: String, destination: Vector2i) -> void:
	board.resolve_challenge(winner_id, loser_id, destination)
	_refresh_ui()

func _on_recruited(profile: BBProfile) -> void:
	roster.add_profile(profile)
	_refresh_ui()

func _on_selection(profile_id: String) -> void:
	if profile_id == "":
		detail_label.text = "Select a fighter to inspect board role and affinity."
		return
	var profile := board.profile(profile_id)
	if profile == null: return
	detail_label.text = "%s\n%s\nRole: %s\nCell: %s\nAptitude: %d" % [profile.display_name, profile.background, board.state.role_of(profile_id).capitalize(), board.profile_cell(profile_id), roundi(profile.aptitude_for(board.state.role_of(profile_id)))]

func _refresh_ui() -> void:
	roster_label.text = "QUALIFICATION BOARD  %d / 16\n%s" % [roster.roster.size(), roster.qualification_summary()]
	for child in candidate_box.get_children(): child.queue_free()
	for candidate in recruitment.candidates():
		var card := VBoxContainer.new()
		var name := Label.new()
		name.text = "%s // Lv.%d" % [candidate.display_name, candidate.level]
		name.add_theme_font_size_override("font_size", 16)
		card.add_child(name)
		var summary := Label.new()
		summary.text = _candidate_summary(candidate)
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(summary)
		var button := Button.new()
		button.text = "Recruit"
		button.pressed.connect(func(id = candidate.profile_id): recruitment.recruit(id))
		card.add_child(button)
		card.add_child(HSeparator.new())
		candidate_box.add_child(card)

func _candidate_summary(profile: BBProfile) -> String:
	var best_role := "pawn"
	var best_score := -1.0
	for role in profile.aptitudes.keys():
		var score := profile.aptitude_for(role)
		if score > best_score:
			best_score = score
			best_role = role
	return "%s\nBest fit: %s %d\n%s" % [profile.background, best_role.capitalize(), roundi(best_score), _chemistry_projection(profile)]

func _chemistry_projection(candidate: BBProfile) -> String:
	if roster.roster.is_empty(): return "Chemistry: unknown"
	var best_name := ""
	var best_score := -999.0
	var resonance := "Neutral"
	for other in roster.roster.values():
		var result := BBAffinityEngine.evaluate(candidate, other)
		if float(result["score"]) > best_score:
			best_score = float(result["score"])
			best_name = other.display_name
			resonance = str(result["resonance"])
	return "Best chemistry: %s // %s (%+d)" % [best_name, resonance, roundi(best_score)]
