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
var board: BoardController
var camera: Camera3D
var return_view: Transform3D
var center := Vector3.ZERO
var initiator_resolve := 100.0
var counterpart_resolve := 100.0
var focus := 100.0
var support_bonus := 0.0
var supporter_id := ""
var support_name := ""
var support_clock := 2.1
var support_used := false
var counterpart_clock := 0.9
var evade_window := 0.0
var counter_window := 0.0
var primary_cooldown := 0.0
var technique_cooldown := 0.0
var last_event := ""

func start(context: BBEncounterContext, active_board: BoardController, active_camera: Camera3D) -> void:
	if active or transitioning: return
	board = active_board
	camera = active_camera
	return_view = camera.global_transform
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
	initiator_resolve = 100.0
	counterpart_resolve = 100.0
	focus = 100.0
	support_bonus = float(context.affinity_snapshot.get("support_bonus", 0.0))
	supporter_id = str(context.affinity_snapshot.get("supporter_id", ""))
	support_name = str(context.affinity_snapshot.get("resonance", ""))
	support_clock = 2.1
	support_used = false
	counterpart_clock = 0.9
	center = board.cell_to_world(destination)
	last_event = "Challenge"
	_enter_direct_view()

func _physics_process(delta: float) -> void:
	if not active or transitioning: return
	evade_window = maxf(0.0, evade_window - delta)
	counter_window = maxf(0.0, counter_window - delta)
	primary_cooldown = maxf(0.0, primary_cooldown - delta)
	technique_cooldown = maxf(0.0, technique_cooldown - delta)
	focus = minf(100.0, focus + delta * 7.0)
	var input := EncounterMotion.input_vector()
	if evade_window <= 0.12:
		EncounterMotion.move_actor(initiator, input, 3.0 + initiator_profile.stat("speed") / 95.0, center, 4.25)
	var distance := EncounterMotion.follow_actor(counterpart, initiator, 1.75 + counterpart_profile.stat("speed") / 180.0, center, 4.25, 1.72)
	counterpart_clock -= delta
	if counterpart_clock <= 0.0 and distance <= 1.95:
		counterpart_clock = 1.2
		_counterpart_action()
	_update_support(delta)
	camera.global_transform = camera.global_transform.interpolate_with(EncounterMotion.view_transform(initiator.global_position, counterpart.global_position), 0.085)
	status_changed.emit(_status_text())

func _unhandled_input(event: InputEvent) -> void:
	if not active or transitioning: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_primary()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q: _technique()
		elif event.keycode == KEY_E: _counter()
		elif event.keycode == KEY_SHIFT: _evade()

func _enter_direct_view() -> void:
	active = true
	transitioning = true
	if initiator_visual != null: initiator_visual.play_state("run", 0.82)
	var a := center + Vector3(-1.7, 0, 0)
	var b := center + Vector3(0.85, 0, 0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(initiator, "global_position", a, 0.78)
	tween.tween_property(counterpart, "global_position", b, 0.62)
	tween.tween_property(camera, "global_transform", EncounterMotion.view_transform(a, b), 0.78)
	tween.finished.connect(func():
		transitioning = false
		EncounterMotion.face(initiator, counterpart.global_position)
		EncounterMotion.face(counterpart, initiator.global_position)
		last_event = "Direct control"
	)

func _primary() -> void:
	if primary_cooldown > 0.0 or _distance() > 2.25: return
	primary_cooldown = 0.48
	EncounterMotion.face(initiator, counterpart.global_position)
	if initiator_visual != null: initiator_visual.play_state("primary", 0.44)
	_apply_counterpart(EncounterValues.primary(initiator_profile, support_bonus), "Primary")

func _technique() -> void:
	if technique_cooldown > 0.0 or focus < 35.0 or _distance() > 2.75: return
	focus -= 35.0
	technique_cooldown = 0.85
	EncounterMotion.face(initiator, counterpart.global_position)
	if initiator_visual != null: initiator_visual.play_state("technique", 0.68)
	_apply_counterpart(EncounterValues.technique(initiator_profile, support_bonus), "Technique")

func _counter() -> void:
	if counter_window > 0.0: return
	counter_window = 0.43
	if initiator_visual != null: initiator_visual.play_state("parry", 0.46)
	last_event = "Counter window"

func _evade() -> void:
	if evade_window > 0.0: return
	evade_window = 0.52
	if initiator_visual != null: initiator_visual.play_state("dodge", 0.50)
	var away := initiator.global_position - counterpart.global_position
	away.y = 0
	if away.length() < 0.01: away = Vector3.LEFT
	create_tween().tween_property(initiator, "global_position", EncounterMotion.clamp_point(initiator.global_position + away.normalized() * 0.95, center, 4.25), 0.18)
	last_event = "Evade"

func _counterpart_action() -> void:
	EncounterMotion.face(counterpart, initiator.global_position)
	if counterpart_visual != null: counterpart_visual.play_state("primary", 0.42)
	get_tree().create_timer(0.19).timeout.connect(_resolve_counterpart_action)

func _resolve_counterpart_action() -> void:
	if not active or transitioning: return
	if _distance() > 2.18:
		last_event = "Counterpart missed"
		return
	if counter_window > 0.0:
		focus = minf(100.0, focus + 14.0)
		_apply_counterpart(EncounterValues.counter(initiator_profile), "Counter")
		return
	if evade_window > 0.0:
		last_event = "EVADE"
		return
	initiator_resolve -= EncounterValues.counterpart(counterpart_profile)
	if initiator_visual != null: initiator_visual.play_state("impact", 0.30)
	last_event = "Pressure"
	_check_result()

func _update_support(delta: float) -> void:
	if support_used or supporter_id == "": return
	support_clock -= delta
	if support_clock > 0.0: return
	support_used = true
	var support_visual := board.visual(supporter_id)
	if support_visual != null: support_visual.play_state("support", 0.72)
	var label := support_name if support_name != "" else "Support"
	board.spawn_affinity_projectile(supporter_id, counterpart_id, label, func():
		if active: _apply_counterpart(EncounterValues.support(support_bonus), "%s support" % label)
	)

func _apply_counterpart(value: float, label: String) -> void:
	counterpart_resolve -= value
	if counterpart_visual != null: counterpart_visual.play_state("impact", 0.30)
	last_event = "%s +%d" % [label, roundi(value)]
	_check_result()

func _check_result() -> void:
	if counterpart_resolve <= 0.0: _finish(initiator_id, counterpart_id)
	elif initiator_resolve <= 0.0: _finish(counterpart_id, initiator_id)

func _finish(winner: String, loser: String) -> void:
	if not active: return
	active = false
	transitioning = true
	var loser_visual := board.visual(loser)
	if loser_visual != null: loser_visual.set_down()
	last_event = "%s holds the square" % winner
	var tween := create_tween()
	tween.tween_property(camera, "global_transform", return_view, 0.78)
	tween.finished.connect(func():
		transitioning = false
		resolved.emit(winner, loser, destination)
	)

func _distance() -> float:
	return initiator.global_position.distance_to(counterpart.global_position)

func _status_text() -> String:
	if initiator_profile == null or counterpart_profile == null: return last_event
	return "%s Resolve %d  Focus %d   vs   %s Resolve %d\n%s\nWASD move · Click primary · Q technique · E counter · Shift evade" % [
		initiator_profile.display_name, maxi(0, roundi(initiator_resolve)), roundi(focus),
		counterpart_profile.display_name, maxi(0, roundi(counterpart_resolve)), last_event
	]
