class_name EncounterController
extends Node

signal resolved(winner_id: String, loser_id: String, destination: Vector2i)
signal status_changed(text: String)

var active := false
var initiator_id := ""
var counterpart_id := ""
var destination := Vector2i.ZERO
var initiator: CharacterBody3D
var counterpart: CharacterBody3D
var initiator_profile: BBProfile
var counterpart_profile: BBProfile
var camera: Camera3D
var board_camera_transform: Transform3D
var initiator_hp := 100.0
var counterpart_hp := 100.0
var focus := 100.0
var support_bonus := 0.0
var opponent_clock := 0.0
var dodge_clock := 0.0

func start(context: BBEncounterContext, board: BoardController, active_camera: Camera3D) -> void:
	active = true
	camera = active_camera
	board_camera_transform = camera.global_transform
	initiator_id = context.initiator_id
	counterpart_id = context.counterpart_id
	destination = context.destination
	initiator = board.piece(initiator_id)
	counterpart = board.piece(counterpart_id)
	initiator_profile = board.profile(initiator_id)
	counterpart_profile = board.profile(counterpart_id)
	initiator_hp = 100.0
	counterpart_hp = 100.0
	focus = 100.0
	support_bonus = float(context.affinity_snapshot.get("support_bonus", 0.0))
	counterpart.position = board.cell_to_world(destination) + Vector3(0.7, 0.9, 0)
	initiator.position = board.cell_to_world(destination) + Vector3(-2.2, 0.9, 0)
	_update_camera(true)
	status_changed.emit(_status_text())

func _physics_process(delta: float) -> void:
	if not active: return
	dodge_clock = maxf(0.0, dodge_clock - delta)
	focus = minf(100.0, focus + delta * 8.0)
	var input := Vector3(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		0.0,
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	if input.length() > 0.0:
		initiator.velocity = input.normalized() * (3.1 + initiator_profile.stat("speed") / 100.0)
		initiator.move_and_slide()
	else:
		initiator.velocity = Vector3.ZERO
	var delta_to_player := initiator.global_position - counterpart.global_position
	if delta_to_player.length() > 1.7:
		counterpart.velocity = Vector3(delta_to_player.x, 0, delta_to_player.z).normalized() * 2.0
		counterpart.move_and_slide()
	else:
		counterpart.velocity = Vector3.ZERO
	opponent_clock -= delta
	if opponent_clock <= 0.0 and delta_to_player.length() <= 1.9:
		opponent_clock = 1.2
		if dodge_clock <= 0.0:
			initiator_hp -= 7.0 + counterpart_profile.stat("power") * 0.08
			_check_resolution()
	status_changed.emit(_status_text())
	_update_camera(false)

func _unhandled_input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_primary_action()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q: _focus_action()
		elif event.keycode == KEY_SHIFT: dodge_clock = 0.55

func _primary_action() -> void:
	if initiator.global_position.distance_to(counterpart.global_position) > 2.2: return
	counterpart_hp -= 8.0 + initiator_profile.stat("power") * 0.08 + initiator_profile.stat("technique") * 0.05 + support_bonus
	_check_resolution()

func _focus_action() -> void:
	if focus < 35.0 or initiator.global_position.distance_to(counterpart.global_position) > 2.7: return
	focus -= 35.0
	counterpart_hp -= 18.0 + initiator_profile.stat("technique") * 0.12 + support_bonus * 1.5
	_check_resolution()

func _check_resolution() -> void:
	if counterpart_hp <= 0.0:
		_finish(initiator_id, counterpart_id)
	elif initiator_hp <= 0.0:
		_finish(counterpart_id, initiator_id)

func _finish(winner: String, loser: String) -> void:
	active = false
	status_changed.emit("Result: %s holds the square" % winner)
	var tween := create_tween()
	tween.tween_property(camera, "global_transform", board_camera_transform, 0.65)
	tween.finished.connect(func(): resolved.emit(winner, loser, destination))

func _update_camera(snap: bool) -> void:
	var direction := (counterpart.global_position - initiator.global_position).normalized()
	var target_pos := initiator.global_position - direction * 4.4 + Vector3(0, 2.3, 0)
	if snap:
		camera.global_position = target_pos
	else:
		camera.global_position = camera.global_position.lerp(target_pos, 0.08)
	camera.look_at(counterpart.global_position + Vector3.UP * 0.65, Vector3.UP)

func _status_text() -> String:
	return "%s HP %d  Focus %d   vs   %s HP %d\nWASD move · Click action · Q technique · Shift evade" % [initiator_profile.display_name, roundi(initiator_hp), roundi(focus), counterpart_profile.display_name, roundi(counterpart_hp)]
