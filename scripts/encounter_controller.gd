class_name EncounterController
extends Node

signal resolved(winner_id: String, loser_id: String, destination: Vector2i)
signal status_changed(text: String)

var active := false
var transitioning := false
var initiator_id := ""
var counterpart_id := ""
var destination := Vector2i.ZERO
var initiator: CharacterBody3D
var counterpart: CharacterBody3D
var initiator_visual: BBPieceVisual
var counterpart_visual: BBPieceVisual
var initiator_profile: BBProfile
var counterpart_profile: BBProfile
var camera: Camera3D
var board: BoardController
var board_camera_transform: Transform3D
var encounter_center := Vector3.ZERO
var initiator_hp := 100.0
var counterpart_hp := 100.0
var focus := 100.0
var support_bonus := 0.0
var supporter_id := ""
var support_resonance := ""
var support_clock := 2.15
var support_used := false
var opponent_clock := 0.85
var dodge_clock := 0.0
var parry_clock := 0.0
var attack_cooldown := 0.0
var technique_cooldown := 0.0
var last_event := ""

func start(context: BBEncounterContext, active_board: BoardController, active_camera: Camera3D) -> void:
	if active or transitioning: return
	board = active_board
	camera = active_camera
	board_camera_transform = camera.global_transform
	initiator_id = context.initiator_id
	counterpart_id = context.counterpart_id
	destination = context.destination
	initiator = board.piece(initiator_id)
	counterpart = board.piece(counterpart_id)
	initiator_visual = board.visual(initiator_id)
	counterpart_visual = board.visual(counterpart_id)
	initiator_profile = board.profile(initiator_id)
	counterpart_profile = board.profile(counterpart_id)
	if initiator == null or counterpart == null or initiator_profile == null or counterpart_profile == null:
		board.interaction_enabled = true
		return
	initiator_hp = 100.0
	counterpart_hp = 100.0
	focus = 100.0
	support_bonus = float(context.affinity_snapshot.get("support_bonus", 0.0))
	supporter_id = str(context.affinity_snapshot.get("supporter_id", ""))
	support_resonance = str(context.affinity_snapshot.get("resonance", ""))
	support_clock = 2.15
	support_used = false
	opponent_clock = 0.85
	dodge_clock = 0.0
	parry_clock = 0.0
	attack_cooldown = 0.0
	technique_cooldown = 0.0
	last_event = "CHALLENGE"
	encounter_center = board.cell_to_world(destination)
	_begin_transition()

func _physics_process(delta: float) -> void:
	if not active or transitioning: return
	dodge_clock = maxf(0.0, dodge_clock - delta)
	parry_clock = maxf(0.0, parry_clock - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	technique_cooldown = maxf(0.0, technique_cooldown - delta)
	focus = minf(100.0, focus + delta * 7.0)

	var input := Vector3(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		0.0,
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	if input.length() > 0.0 and dodge_clock <= 0.12:
		input = input.normalized()
		initiator.velocity = input * (3.0 + initiator_profile.stat("speed") / 95.0)
		initiator.rotation.y = atan2(-input.x, -input.z)
		initiator.move_and_slide()
		_constrain_to_encounter(initiator)
	else:
		initiator.velocity = Vector3.ZERO

	var delta_to_player := initiator.global_position - counterpart.global_position
	if delta_to_player.length() > 1.72:
		var chase := Vector3(delta_to_player.x, 0, delta_to_player.z).normalized()
		counterpart.velocity = chase * (1.75 + counterpart_profile.stat("speed") / 180.0)
		counterpart.rotation.y = atan2(-chase.x, -chase.z)
		counterpart.move_and_slide()
		_constrain_to_encounter(counterpart)
	else:
		counterpart.velocity = Vector3.ZERO
		_face(counterpart, initiator.global_position)

	opponent_clock -= delta
	if opponent_clock <= 0.0 and delta_to_player.length() <= 1.95:
		opponent_clock = 1.18 + maxf(0.0, (70.0 - counterpart_profile.stat("speed")) * 0.004)
		_enemy_strike()

	if not support_used and supporter_id != "":
		support_clock -= delta
		if support_clock <= 0.0:
			_trigger_support_intervention()

	_update_camera()
	status_changed.emit(_status_text())

func _unhandled_input(event: InputEvent) -> void:
	if not active or transitioning: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_primary_action()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_focus_action()
		elif event.keycode == KEY_E:
			_parry()
		elif event.keycoe == KEY_SHIFT:
			_dodge()

func _begin_transition() -> void:
	active = true
	transitioning = true
	if initiator_visual != null: initiator_visual.play_state("run", 0.82)
	var attacker_target := encounter_center + Vector3(-1.7, 0, 0)
	var defender_target := encounter_center + Vector3(0.85, 0, 0)
	var cam_target := _camera_transform(attacker_target, defender_target)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(initiator, "global_position", attacker_target, 0.78)
	tween.tween_property(counterpart, "global_position", defender_target, 0.62)
	tween.tween_property(camera, "global_transform", cam_target, 0.78)
	tween.finished.connect(func():
		transitioning = false
		_face(initiator, counterpart.global_position)
		_face(counterpart, initiator.global_position)
		last_event = "Direct control"
		status_changed.emit(_status_text())
	)

func _primary_action() -> void:
	if attack_cooldown > 0.0: return
	if initiator.global_position.distance_to(counterpart.global_position) > 2.25:
		last_event = "Out of range"
		return
	attack_cooldown = 0.48
	_face(initiator, counterpart.global_position)
	if initiator_visual != null: initiator_visual.play_state("primary", 0.44)
	var amount := 7.0 + initiator_profile.stat("power") * 0.075 + initiator_profile.stat("technique") * 0.045 + support_bonus * 0.35
	counterpart_hp -= amount
	if counterpart_visual != null: counterpart_visual.play_state("impact", 0.28)
	last_event = "Strike %d" % roundi(amount)
	_check_resolution()

func _focus_action() -> void:
	if technique_cooldown > 0.0: return
	if focus < 35.0:
		last_event = "Not enough focus"
		return
	if initiator.global_position.distance_to(counterpart.global_position) > 2.75:
		last_event = "Technique out of range"
		return
	focus -= 35.0
	technique_cooldown = 0.85
B_face(initiator, counterpart.global_position)
	if initiator_visual != null: initiator_visual.play_state("technique", 0.68)
	var amount := 15.0 + initiator_profile.stat("technique") * 0.12 + support_bonus * 0.75
	counterpart_hp -= amount
	if counterpart_visual != null: counterpart_visual.play_state("impact", 0.34)
	last_event = "Technique %d" % roundi(amount)
	_check_resolution()

func _parry() -> void:
	if parry_clock > 0.0: return
	parry_clock = 0.43
	if initiator_visual != null: initiator_visual.play_state("parry", 0.46)
	last_event = "Parry window"

func _dodge() -> void:
	if dodge_clock > 0.0: return
	dodge_clock = 0.52
	if initiator_visual != null: initiator_visual.play_state("dodge", 0.50)
	var away := initiator.global_position - counterpart.global_position
	away.y = 0
	if away.length() < 0.01: away = Vector3.LEFT
	var target := initiator.global_position + away.normalized() * 0.95
	target = _clamp_point(target)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(initiator, "global_position", target, 0.18)
	last_event = "Evade"

func _enemy_strike() -> void:	_face(counterpart, initiator.global_position)
	if counterpart_visual != null: counterpart_visual.play_state("primary", 0.42)
	var timer := get_tree().create_timer(0.19)
	timer.timeout.connect(_resolve_enemy_impact)

func _resolve_enemy_impact() -> void:
	if not active or transitioning: return
	if initiator.global_position.distance_to(counterpart.global_position) > 2.18:
		last_event = "Enemy missed"
		return
	if parry_clock > 0.0:
		var counter_amount := 5.0 + initiator_profile.stat("technique") * 0.07
		counterpart_hp -= counter_amount
		focus = minf(100.0, focus + 14.0)
		if counterpart_visual != null: counterpart_visual.play_state("impact", 0.30)
		last_event = "PARRY + counter %d" % roundi(counter_amount)
		_check_resolution()
		return
	if dodge_clock > 0.0:
		last_event = "EVADE"
		return
	var amount := 6.5 + counterpart_profile.stat("power") * 0.07
	initiator_hp -= amount
	if initiator_visual != null: initiator_visual.play_state("impact", 0.30)
	last_event = "Hit -%d" % roundi(amount)
	_check_resolution()

func _trigger_support_intervention() -> void:
	support_used = true
	var support_visual := board.visual(supporter_id)
	if support_visual != null: support_visual.play_state("support", 0.72)
	var resonance_name := support_resonance if support_resonance != "" else "Support"
	last_event = "%s intervention" % resonance_name
	board.spawn_affinity_projectile(supporter_id, counterpart_id, resonance_name, func():
		if not active: return
		var amount := 3.5 + support_bonus * 0.95
		counterpart_hp -= amount
		if counterpart_visual != null: counterpart_visual.play_state("impact", 0.32)
		last_event = "%s support +%d" % [resonance_name, roundi(amount)]
		_check_resolution()
	)

func _check_resolution() -> void:
	if counterpart_hp <= 0.0:
	_finish(initiator_id, counterpart_id)
	elif initiator_hp <= 0.0:
	_finish(counterpart_id, initiator_id)

func _finish(winner: String, loser: String) -> void:
	if not active: return
	active = false
	transitioning = true
	var loser_visual := board.visual(loser)
	if loser_visual != null: loser_visual.set_down()
	last_event = "%s holds the square" % winner
	status_changed.emit(_status_text())
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_transform", board_camera_transform, 0.78)
	tween.finished.connect(func():
		transitioning = false
		resolved.emit(winner, loser, destination)
	)

func _update_camera() -> void:
	if camera == null or initiator == null or counterpart == null: return
	var target := _camera_transform(initiator.global_position, counterpart.global_position)
	camera.global_transform = camera.global_transform.interpolate_with(target, 0.085)

func _camera_transform(attacker_pos: Vector3, defender_pos: Vector3) -> Transform3D:
	var direction := defender_pos - attacker_pos
	direction.y = 0
	if direction.length() < 0.01: direction = Vector3.RIGHT
	direction = direction.normalized()
	var side_vec := Vector3(-direction.z, 0, direction.x)
	var camera_pos := attacker_pos - direction * 4.25 + side_vec * 1.15 + Vector3(0, 2.45, 0)
	var focus_point := (attacker_pos + defender_pos) * 0.5 + Vector3.UP * 0.95
	return Transform3D(Basis.IDENTITY, camera_pos).looking_at(focus_point, Vector3.UP)

func _face(body: Node3D, point: Vector3) -> void:
	var direction := point - body.global_position
	direction.y = 0
	if direction.length() > 0.01:
		body.rotation.y = atan2(-direction.x, -direction.z)

func _constrain_to_encounter(body: CharacterBody3D) -> void:
	body.global_position = _clamp_point(body.global_position)

func _clamp_point(point: Vector3) -> Vector3:
	var offset := point - encounter_center
	offset.y = 0
	if offset.length() > 4.25:
		offset = offset.normalized() * 4.25
	return encounter_center + offset

func _status_text() -> String:
	if initiator_profile == null or counterpart_profile == null:
		return last_event
	return "%s HP %d  Focus %d    vs    %s HP %d\n%s\nWASD move · Click strike · Q technique · E parry · Shift evade" % [
		initiator_profile.display_name,
		maxi(0, roundi(initiator_hp)),
		roundi(focus),
		counterpart_profile.display_name,
		maxi(0, roundi(counterpart_hp)),
		last_event
	]
