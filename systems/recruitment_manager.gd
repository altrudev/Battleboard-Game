class_name RecruitmentManager
extends Node

signal recruited(profile: BBProfile)
signal pool_changed

var available: Dictionary = {}
var recruited_profiles: Dictionary = {}

func load_pool(path := "res://data/recruits/recruit_pool.json") -> void:
	available.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Recruit pool could not be opened: %s" % path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Recruit pool is not an array")
		return
	for row in parsed:
		var profile := BBProfile.from_dictionary(row)
		available[profile.profile_id] = profile
	pool_changed.emit()

func recruit(profile_id: String) -> BBProfile:
	if not available.has(profile_id):
		return null
	var profile: BBProfile = available[profile_id]
	available.erase(profile_id)
	recruited_profiles[profile_id] = profile
	recruited.emit(profile)
	pool_changed.emit()
	return profile

func candidates() -> Array[BBProfile]:
	var result: Array[BBProfile] = []
	for value in available.values():
		result.append(value)
	return result
