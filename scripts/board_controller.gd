class_name BoardController
extends Node3D

signal selection_changed(profile_id: String)
signal challenge_requested(initiator_id: String, counterpart_id: String, destination: Vector2i)
signal moved(profile_id: String, origin: Vector2i, destination: Vector2i)

const CELL_SIZE := 2.25
var state := BBBoardState.new()
var profiles: Dictionary = {}
var pieces: Dictionary = {}
var visuals: Dictionary = {}
var cell_meshes: Dictionary = {}
var selected_id := ""
var interaction_enabled := true
var camera: Camera3D

func setup(active_camera: Camera3D) -> void:
	camera = active_camera
	_build_board()
	_build_board_frame()

func add_profile(profile: BBProfile, cell: Vector2i, side: String, role: String) -> void:
	profiles[profile.profile_id] = profile
	state.register_profile(profile.profile_id, cell, role, side)
	var body := CharacterBody3D.new()
	body.name = profile.profile_id
	body.collision_layer = 1
	body.collision_mask = 1
	var collider := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.34
	capsule_shape.height = 1.72
	collider.shape = capsule_shape
	collider.position = Vector3(0, 0.86, 0)
	body.add_child(collider)
	var visual := BBPieceVisual.new()
	visual.name = "FighterVisual"
	body.add_child(visual)
	visual.configure(profile, side, role)
	var label := Label3D.new()
	label.name = "IdentityLabel"
	label.text = "%s\n%s" % [profile.display_name, role.capitalize()]
	label.position = Vector3(0, 2.45, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 23
	label.outline_size = 5
	label.modulate = Color("#e8eef8") if side == "player" else Color("#f0b7b1")
	body.add_child(label)
	body.position = cell_to_world(cell)
	body.rotation.y = PI if side == "player" else 0.0
	add_child(body)
	pieces[profile.profile_id] = body
	visuals[profile.profile_id] = visual

func remove_profile(profile_id: String) -> void:
	state.remove_profile(profile_id)
	profiles.erase(profile_id)
	visuals.erase(profile_id)
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
	if visuals.has(loser_id):
		(visuals[loser_id] as BBPieceVisual).set_down()
	remove_profile(loser_id)
	if initiator_won and pieces.has(winner_id):
		var origin := state.cell_of(winner_id)
		state.move_profile(winner_id, destination)
		_move_visual(winner_id, destination)
		moved.emit(winner_id, origin, destination)
	selected_id = ""
	selection_changed.emit("")
	_refresh_highlights()

func profile(profile_id: String) -> BBProfile:
	return profiles.get(profile_id)

func profile_cell(profile_id: String) -> Vector2i:
	return state.cell_of(profile_id)

func piece(profile_id: String) -> CharacterBody3D:
	return pieces.get(profile_id)

func visual(profile_id: String) -> BBPieceVisual:
	return visuals.get(profile_id)

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
	result.sort_custom(func(a: Dictionary, b: Dictionary): return float(a["affinity"]["score"]) > float(b["affinity"]["score"]))
	return result

func show_world_callout(profile_id: String, text: String, color := Color("#d7c36a")) -> void:
	if not pieces.has(profile_id): return
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 30
	label.outline_size = 7
	label.modulate = color
	label.global_position = (pieces[profile_id] as Node3D).global_position + Vector3(0, 2.8, 0)
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 0.75, 0), 1.15)
	tween.tween_property(label, "modulate:a", 0.0, 1.15)
	tween.finished.connect(label.queue_free)

func spawn_affinity_projectile(source_id: String, target_id: String, resonance: String, on_arrival: Callable) -> void:
	if not pieces.has(source_id) or not pieces.has(target_id):
		on_arrival.call()
		return
	var source_visual: BBPieceVisual = visuals.get(source_id)
	var source_pos := source_visual.equipment_world_position() if source_visual != null else (pieces[source_id] as Node3D).global_position + Vector3.UP
	var target_pos := (pieces[target_id] as Node3D).global_position + Vector3.UP * 1.05
	var projectile := MeshInstance3D.new()
	var orb := SphereMesh.new()
	orb.radius = 0.11
	orb.height = 0.22
	projectile.mesh = orb
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#f3d875")
	mat.emission_enabled = true
	mat.emission = Color("#d8b84f")
	mat.emission_energy_multiplier = 2.4
	projectile.material_override = mat
	add_child(projectile)
	projectile.global_position = source_pos
	show_world_callout(source_id, resonance.to_upper())
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(projectile, "global_position", target_pos, 0.42)
	tween.finished.connect(func():
		projectile.queue_free()
		on_arrival.call()
	)

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
	var body: CharacterBody3D = pieces[profile_id]
	var v: BBPieceVisual = visuals.get(profile_id)
	if v != null: v.play_state("run", 0.45)
	var destination := cell_to_world(cell)
	var delta := destination - body.position
	if delta.length() > 0.01:
		body.rotation.y = atan2(-delta.x, -delta.z)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(body, "position", destination, 0.42)

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
			mat.albedo_color = Color("#252b33") if (x+y)%2==0 else Color("#55606a")
			mat.roughness = 0.86
			tile.material_override = mat
			tile.position = cell_to_world(cell) - Vector3(0,0.08,0)
			add_child(tile)
			cell_meshes[cell] = tile

func _build_board_frame() -> void:
	var board_width := BBBoardState.SIZE * CELL_SIZE + 1.2
	var base := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(board_width, 0.40, board_width)
	base.mesh = mesh
	base.position = Vector3(0, -0.31, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#14181d")
	mat.roughness = 0.78
	base.material_override = mat
	add_child(base)
	for corner in [Vector3(-10.0,0,-10.0), Vector3(10.0,0,-10.0), Vector3(-10.0,0,10.0), Vector3(10.0,0,10.0)]:
		var post := MeshInstance3D.new()
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = 0.18
		post_mesh.bottom_radius = 0.24
		post_mesh.height = 2.5
		post.mesh = post_mesh
		post.position = corner + Vector3(0,1.05,0)
		post.material_override = mat
		add_child(post)

func _refresh_highlights() -> void:
	var legal: Array[Vector2i] = []
	if selected_id != "": legal = BBBoardRules.legal_moves(state, selected_id)
	for cell in cell_meshes.keys():
		var tile: MeshInstance3D = cell_meshes[cell]
		var mat: StandardMaterial3D = tile.material_override
		var base := Color("#252b33") if (cell.x+cell.y)%2==0 else Color("#55606a")
		mat.emission_enabled = false
		if cell in legal:
			base = Color("#557a64") if state.occupant(cell)=="" else Color("#8e5150")
			mat.emission_enabled = true
			mat.emission = base * 0.20
			mat.emission_energy_multiplier = 1.15
		elif selected_id != "" and cell == state.cell_of(selected_id):
			base = Color("#9b8240")
			mat.emission_enabled = true
			mat.emission = base * 0.22
			mat.emission_energy_multiplier = 1.2
		mat.albedo_color = base
