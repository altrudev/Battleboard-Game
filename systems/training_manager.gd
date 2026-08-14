class_name TrainingManager
extends Node

signal trained(profile: BBProfile, role: String, gain: float)

var campaign: CampaignState
var sessions: Dictionary = {}

func setup(active_campaign: CampaignState) -> void:
	campaign = active_campaign

func train(profile: BBProfile, role: String) -> bool:
	if profile == null or campaign == null: return false
	role = role.to_lower()
	if not QualificationRules.ROLE_LIMITS.has(role): return false
	if not campaign.consume_training_token(): return false
	var key := "%s:%s" % [profile.profile_id,role]
	var count := int(sessions.get(key,0)) + 1
	sessions[key] = count
	var gain := maxf(0.75,2.5-float(count-1)*0.25)
	profile.aptitudes[role] = minf(99.0,profile.aptitude_for(role)+gain)
	match role:
		"rook", "king": profile.stats["guard"] = minf(99.0,profile.stat("guard")+0.4)
		"knight", "queen": profile.stats["speed"] = minf(99.0,profile.stat("speed")+0.4)
		"bishop": profile.stats["technique"] = minf(99.0,profile.stat("technique")+0.45)
		_: profile.stats["will"] = minf(99.0,profile.stat("will")+0.35)
	trained.emit(profile,role,gain)
	return true

func to_dictionary() -> Dictionary:
	return sessions.duplicate(true)

func from_dictionary(data: Dictionary) -> void:
	sessions = data.duplicate(true)
