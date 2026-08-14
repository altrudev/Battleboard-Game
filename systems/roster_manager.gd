class_name RosterManager
extends Node

signal roster_changed

const MAX_STABLE_SIZE := 20
var roster: Dictionary = {}
var assignments: Dictionary = {}

func clear() -> void:
	roster.clear()
	assignments.clear()
	roster_changed.emit()

func add_profile(profile: BBProfile) -> bool:
	if profile == null or roster.has(profile.profile_id) or roster.size() >= MAX_STABLE_SIZE: return false
	roster[profile.profile_id] = profile
	roster_changed.emit()
	return true

func assign(profile_id: String, role: String) -> bool:
	if not roster.has(profile_id): return false
	role = role.to_lower()
	if not QualificationRules.ROLE_LIMITS.has(role): return false
	var used := 0
	for other_id in assignments.keys():
		if str(other_id) == profile_id: continue
		if str(assignments[other_id]) == role: used += 1
	if used >= int(QualificationRules.ROLE_LIMITS[role]): return false
	assignments[profile_id] = role
	roster_changed.emit()
	return true

func unassign(profile_id: String) -> void:
	assignments.erase(profile_id)
	roster_changed.emit()

func is_qualification_ready() -> bool:
	return QualificationRules.ready(assignments)

func qualification_summary() -> String:
	return QualificationRules.summary(assignments)

func assigned_profiles() -> Array[BBProfile]:
	var result: Array[BBProfile] = []
	for profile_id in assignments.keys():
		if roster.has(profile_id): result.append(roster[profile_id])
	result.sort_custom(func(a: BBProfile,b: BBProfile): return a.profile_id < b.profile_id)
	return result

func role_for(profile_id: String) -> String:
	return str(assignments.get(profile_id,""))
