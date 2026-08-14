class_name EncounterValues
extends RefCounted

static func primary(profile: BBProfile, support_bonus: float) -> float:
	return 7.0 + profile.stat("power") * 0.075 + profile.stat("technique") * 0.045 + support_bonus * 0.35

static func technique(profile: BBProfile, support_bonus: float) -> float:
	return 15.0 + profile.stat("technique") * 0.12 + support_bonus * 0.75

static func counterpart(profile: BBProfile) -> float:
	return 6.5 + profile.stat("power") * 0.07

static func counter(profile: BBProfile) -> float:
	return 5.0 + profile.stat("technique") * 0.07

static func support(support_bonus: float) -> float:
	return 3.5 + support_bonus * 0.95
