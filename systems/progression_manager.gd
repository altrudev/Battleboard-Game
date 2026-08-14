class_name ProgressionManager
extends Node

signal progression_changed

var xp: Dictionary = {}
var knockouts: Dictionary = {}
var injuries: Dictionary = {}

func xp_for(profile_id: String) -> int:
	return int(xp.get(profile_id,0))

func injury_for(profile_id: String) -> String:
	return str(injuries.get(profile_id,""))

func award_match(profiles: Array[BBProfile], won: bool, defeated_player_ids: Array[String]) -> Array[String]:
	var notices: Array[String] = []
	for profile in profiles:
		var gain := 28 if won else 16
		var new_xp := xp_for(profile.profile_id) + gain
		while new_xp >= 100:
			new_xp -= 100
			profile.level += 1
			profile.stats["will"] = minf(99.0,profile.stat("will")+1.0)
			notices.append("%s reached level %d" % [profile.display_name,profile.level])
		xp[profile.profile_id] = new_xp
	for profile_id in defeated_player_ids:
		var count := int(knockouts.get(profile_id,0)) + 1
		knockouts[profile_id] = count
		injuries[profile_id] = "Bruised" if count < 3 else "Scarred"
		if count >= 3:
			var profile := _find(profiles,profile_id)
			if profile != null and "scarred_survivor" not in profile.traits:
				profile.traits.append("scarred_survivor")
				notices.append("%s gained Scarred Survivor" % profile.display_name)
	_bond_team(profiles,1.5 if won else 0.75)
	progression_changed.emit()
	return notices

func _bond_team(profiles: Array[BBProfile], amount: float) -> void:
	for a in profiles:
		for b in profiles:
			if a == b: continue
			a.adjust_relationship(b.profile_id,amount)

func _find(profiles: Array[BBProfile], profile_id: String) -> BBProfile:
	for profile in profiles:
		if profile.profile_id == profile_id: return profile
	return null

func to_dictionary() -> Dictionary:
	return {"xp":xp.duplicate(true),"knockouts":knockouts.duplicate(true),"injuries":injuries.duplicate(true)}

func from_dictionary(data: Dictionary) -> void:
	xp = data.get("xp",{}).duplicate(true)
	knockouts = data.get("knockouts",{}).duplicate(true)
	injuries = data.get("injuries",{}).duplicate(true)
