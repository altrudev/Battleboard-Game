class_name MatchController
extends Node

signal encounter_requested(context: BBEncounterContext)
signal turn_changed(turn: String)
signal match_started
signal match_finished(won: bool, summary: String, defeated_player_ids: Array[String])
signal status_changed(text: String)

var board: BoardController
var active := false
var turn := "player"
var pending_turn := ""
var suppress_move_event := false
var defeated_player_ids: Array[String] = []
var turn_count := 0

func setup(active_board: BoardController) -> void:
	board = active_board
	board.moved.connect(_on_board_moved)
	board.challenge_requested.connect(_on_player_challenge)

func start_match(player_profiles: Array[BBProfile], assignments: Dictionary) -> void:
	if not QualificationRules.ready(assignments): return
	_clear_board()
	_place_player(player_profiles,assignments)
	_place_rival()
	active = true
	turn = "player"
	turn_count = 1
	defeated_player_ids.clear()
	board.interaction_enabled = true
	match_started.emit()
	turn_changed.emit(turn)
	status_changed.emit("LOCAL QUALIFIER · Your move")

func resolve_encounter(winner_id: String, loser_id: String, destination: Vector2i) -> void:
	if not active: return
	var loser_side := board.state.side_of(loser_id)
	var loser_role := board.state.role_of(loser_id)
	if loser_side == "player": defeated_player_ids.append(loser_id)
	suppress_move_event = true
	board.resolve_challenge(winner_id,loser_id,destination)
	suppress_move_event = false
	if loser_role == "king":
		_finish(loser_side == "rival")
		return
	if _side_count("player") == 0 or _side_count("rival") == 0:
		_finish(_side_count("rival") == 0)
		return
	if pending_turn == "player": _begin_rival_turn()
	else: _begin_player_turn()
	pending_turn = ""

func _on_board_moved(profile_id: String,_origin: Vector2i,_destination: Vector2i) -> void:
	if suppress_move_event or not active: return
	if turn == "player" and board.state.side_of(profile_id) == "player": _begin_rival_turn()

func _on_player_challenge(initiator_id: String,counterpart_id: String,destination: Vector2i) -> void:
	if not active or turn != "player": return
	pending_turn = "player"
	board.interaction_enabled = false
	encounter_requested.emit(_context_for_player(initiator_id,counterpart_id,destination))

func _begin_rival_turn() -> void:
	if not active: return
	turn = "rival"
	board.interaction_enabled = false
	turn_changed.emit(turn)
	status_changed.emit("LOCAL QUALIFIER · Rival calculating")
	get_tree().create_timer(0.65).timeout.connect(_execute_rival_turn)

func _execute_rival_turn() -> void:
	if not active: return
	var decision := BBTacticalPlanner.choose_move(board.state,board.profiles,"rival")
	if decision.is_empty():
		_finish(true)
		return
	var rival_id := str(decision["profile_id"])
	var destination: Vector2i = decision["destination"]
	var target_id := str(decision["target_id"])
	if target_id == "":
		suppress_move_event = true
		_programmatic_move(rival_id,destination)
		suppress_move_event = false
		_begin_player_turn()
	else:
		pending_turn = "rival"
		encounter_requested.emit(_context_for_player(target_id,rival_id,destination))

func _begin_player_turn() -> void:
	if not active: return
	turn_count += 1
	if turn_count > 60:
		_finish(_material_score("player") >= _material_score("rival"))
		return
	turn = "player"
	board.interaction_enabled = true
	turn_changed.emit(turn)
	status_changed.emit("LOCAL QUALIFIER · Your move · Turn %d" % turn_count)

func _context_for_player(player_id: String,opponent_id: String,destination: Vector2i) -> BBEncounterContext:
	var context := BBEncounterContext.new(player_id,opponent_id,destination)
	var supports := board.active_support(player_id)
	if not supports.is_empty():
		var best: Dictionary = supports[0]
		context.initiator_support.append(str(best["profile_id"]))
		context.affinity_snapshot = {"supporter_id":str(best["profile_id"]),"support_bonus":maxf(0.0,float(best["affinity"]["score"])*0.04),"resonance":str(best["affinity"]["resonance"])}
	return context

func _clear_board() -> void:
	var ids: Array = board.pieces.keys()
	for raw_id in ids: board.remove_profile(str(raw_id))
	board.selected_id = ""
	board.interaction_enabled = false

func _programmatic_move(profile_id: String,destination: Vector2i) -> void:
	var origin := board.state.cell_of(profile_id)
	board.state.move_profile(profile_id,destination)
	board._move_visual(profile_id,destination)
	board.moved.emit(profile_id,origin,destination)

func _place_player(player_profiles: Array[BBProfile],assignments: Dictionary) -> void:
	var used := {}
	for profile in player_profiles:
		var role := str(assignments.get(profile.profile_id,""))
		if role == "": continue
		var index := int(used.get(role,0))
		var cells := QualificationRules.cells_for("player",role)
		if index < cells.size():
			board.add_profile(profile,cells[index],"player",role)
			used[role] = index + 1

func _place_rival() -> void:
	var file := FileAccess.open("res://data/opponents/qualifier_gate.json",FileAccess.READ)
	if file == null: return
	var rows = JSON.parse_string(file.get_as_text())
	var used := {}
	for row in rows:
		var role := str(row.get("role","pawn"))
		var profile := BBProfile.from_dictionary(row)
		var index := int(used.get(role,0))
		var cells := QualificationRules.cells_for("rival",role)
		if index < cells.size():
			board.add_profile(profile,cells[index],"rival",role)
			used[role] = index + 1

func _side_count(side: String) -> int:
	var count := 0
	for profile_id in board.state.cell_by_profile.keys():
		if board.state.side_of(str(profile_id)) == side: count += 1
	return count

func _material_score(side: String) -> float:
	var values := {"king":100.0,"queen":9.0,"rook":5.0,"bishop":3.0,"knight":3.0,"pawn":1.0}
	var score := 0.0
	for profile_id in board.state.cell_by_profile.keys():
		if board.state.side_of(str(profile_id)) == side: score += float(values.get(board.state.role_of(str(profile_id)),1.0))
	return score

func _finish(won: bool) -> void:
	active = false
	board.interaction_enabled = false
	var summary := "QUALIFIER WON" if won else "QUALIFIER LOST"
	status_changed.emit(summary)
	match_finished.emit(won,summary,defeated_player_ids.duplicate())
