class_name BoardController
extends Node3D

signal selection_changed(profile_id: String)
signal challenge_requested(initiator_id: String, counterpart_id: String, destination: Vector2i)
signal moved(profile_id: String, origin: Vector2i, destination: Vector2i)

const CELL_SIZE := 2.25
var state := BBBoardState.new()
var profiles: Dictionary = {}
var pieces: Dictionary = {}
var cell_meshes: Dictionary = {}
var selected_id := ""
var interaction_enabled := true
var camera: Camera3D

func setup(active_camera: Camera3D) -> void:
	camera = active_camera
	_build_board()

func add_profile(profile: BBProfile, cell: Vector2i, side: String, role: String) -> void:
	profiles[profile.profile_id] = profile
	state.register_profile(profile.profile_id, cell, role, side)
	var body := CharacterBody3D.new()
	body.name = profile.profile_id
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.75
	mesh.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#e8edf6") if side == "player" else Color("#343947")
	mesh.material_override = material
	body.add_child(mesh)
	var label := Label3D.new()
	label.text = "%s\n%s" % [profile.display_name, role.capitalize()]
	label.position = Vector3(0, 1.35, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	body.add_child(label)
	body.position = cell_to_world(cell) + Vector3(0, 0.9, 0)
	add_child(body)
	pieces[profile.profile_id] = body

func remove_profile(profile_id: String) -> void:
	state.remove_profile(profile_id)
	profiles.erase(profile_id)
	if pieces.has(profile_id):
		pieces[profile_id].queue_free()
		pieces.erase(profile_id)
	if selected_id == profile_id:
		selected_id = ""
	_refresh_highlights()

func resolve_challenge(winner_id: String, loser_id: String, destination: Vector2i) -> void:
	interaction_enabled = true
	if winner_id == loser_id: return
	var initiator_won := state.cell_of(winner_id) != destination
	remove_profile(loser_id)
	if initiator_won and pieces.has(winner_id):
		var origin := state.cell_of(winner_id)
		state.move_profile(winner_id, destination)
		_move_visual(winner_id, destination)
		moved.emit(winner_id, origin, destination)
	selected_id = ""
	_refresh_highlights()

func profile(profile_id: String) -> BBProfile:
	return profiles.get(profile_id)

func profile_cell(profile_id: String) -> Vector2i:
	return state.cell_of(profile_id)

func piece(profile_id: String) -> CharacterBody3D:
	return pieces.get(profile_id)

func active_support(profile_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var origin := state.cell_of(profile_id)
	var profile_a: BBProfile = profiles.get(profile_id)
	if profile_a == null: return result
	for other_id in state.cell_by_profile.keys():
		if other_id == profile_id or state.side_of(other_id) != state.side_of(profile_id): continue
		var other_cell := state.cell_of(other_id)
		if maxi(abs(other_cell.x-origin.x), abs(other_cell.y-origin.y)) <= 1:
			var affinity := BBAffinityEngine.evaluate(profile_a, profiles[other_id])
			result.append({"profile_id": other_id, "affinity": affinity})
	return result

func _unhandled_input(event: InputEvent) -> void:
	if not interaction_enabled or camera == null: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell := _mouse_to_cell(event.position)
		if state.inside(cell): _handle_cell_click(cell)

func _handle_cell_click(cell: Vector2i) -> void:
	var occupant := state.occupant(cell)
	if selected_id == "":
		if occupant != "" and state.side_of(occupant) == "player": _select(occupant)
		return
	if occupant == selected_id:
		selected_id = ""
		selection_changed.emit("")
		_refresh_highlights()
		return
	var legal := BBBoardRules.legal_moves(state, selected_id)
	if cell not in legal:
		if occupant != "" and state.side_of(occupant) == "player": _select(occupant)
		return
	if occupant == "":
		var origin := state.cell_of(selected_id)
		state.move_profile(selected_id, cell)
		_move_visual(selected_id, cell)
		moved.emit(selected_id, origin, cell)
		selected_id = ""
		selection_changed.emit("")
		_refresh_highlights()
	else:
		interaction_enabled = false
		challenge_requested.emit(selected_id, occupant, cell)

func _select(profile_id: String) -> void:
	selected_id = profile_id
	selection_changed.emit(profile_id)
	_refresh_highlights()

func _move_visual(profile_id: String, cell: Vector2i) -> void:
	var body: Node3D = pieces[profile_id]
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(body, "position", cell_to_world(cell) + Vector3(0,0.9,0), 0.35)

func _mouse_to_cell(mouse: Vector2) -> Vector2i:
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	var plane := Plane(Vector3.UP, 0.0)
	var hit = plane.intersects_ray(origin, direction)
	if hit == null: return Vector2i(-1,-1)
	return world_to_cell(hit)

func cell_to_world(cell: Vector2i) -> Vector3:
	var half := (BBBoardState.SIZE - 1) * CELL_SIZE * 0.5
	return Vector3(cell.x * CELL_SIZE - half, 0, cell.y * CELL_SIZE - half)

func world_to_cell(world: Vector3) -> Vector2i:
	var half := (BBBoardState.SIZE - 1) * CELL_SIZE * 0.5
	return Vector2i(roundi((world.x + half)/CELL_SIZE), roundi((world.z + half)/CELL_SIZE))

func _build_board() -> void:
	for x in BBBoardState.SIZE:
		for y in BBBoardState.SIZE:
			var cell := Vector2i(x,y)
			var tile := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(CELL_SIZE-0.05, 0.12, CELL_SIZE-0.05)
			tile.mesh = box
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color("#273241") if (x+y)%2==0 else Color("#445368")
			tile.material_override = mat
			tile.position = cell_to_world(cell) - Vector3(0,0.08,0)
			add_child(tile)
			cell_meshes[cell] = tile

func _refresh_highlights() -> void:
	var legal: Array[Vector2i] = []
	if selected_id != "": legal = BBBoardRules.legal_moves(state, selected_id)
	for cell in cell_meshes.keys():
		var tile: MeshInstance3D = cell_meshes[cell]
		var mat: StandardMaterial3D = tile.material_override
		var base := Color("#273241") if (cell.x+cell.y)%2==0 else Color("#445368")
		if cell in legal:
			base = Color("#607d63") if state.occupant(cell)=="" else Color("#8c5c56")
		elif selected_id != "" and cell == state.cell_of(selected_id):
			base = Color("#9a843f")
		mat.albedo_color = base
