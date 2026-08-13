class_name RosterManager
extends Node

signal roster_changed

const FULL_BOARD_SIZE := 16
var roster: Dictionary = {}
var assignments: Dictionary = {}
var role_limits := {"king":1, "queen":1, "rook":2, "bishop":2, "knight":2, "pawn":8}

func add_profile(profile: BBProfile) -> bool:
	if roster.has(profile.profile_id) or roster.size() >= FULL_BOARD_SIZE:
		return false
	roster[profile.profile_id] = profile
	roster_changed.emit()
	return true

func assign(profile_id: String, role: String) -> bool:
	if not roster.has(profile_id): return false
	role = role.to_lower()
	if not role_limits.has(role): return false
	var used := 0
	for assigned_role in assignments.values():
		if assigned_role == role: used += 1
	if used >= int(role_limits[role]): return false
	assignments[profile_id] = role
	roster_changed.emit()
	return true

func completion() -> float:
	return float(assignments.size()) / float(FULL_BOARD_SIZE)
