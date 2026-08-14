class_name QualificationRules
extends RefCounted

const BOARD_SIZE := 8
const ROLE_LIMITS := {"king":1,"queen":1,"rook":1,"bishop":1,"knight":1,"pawn":3}
const ROLE_ORDER := ["king","queen","rook","bishop","knight","pawn"]
const PLAYER_CELLS := {"king":[Vector2i(4,0)],"queen":[Vector2i(3,0)],"rook":[Vector2i(0,0)],"bishop":[Vector2i(2,0)],"knight":[Vector2i(1,0)],"pawn":[Vector2i(1,1),Vector2i(3,1),Vector2i(5,1)]}
const RIVAL_CELLS := {"king":[Vector2i(4,7)],"queen":[Vector2i(3,7)],"rook":[Vector2i(7,7)],"bishop":[Vector2i(5,7)],"knight":[Vector2i(6,7)],"pawn":[Vector2i(2,6),Vector2i(4,6),Vector2i(6,6)]}

static func ready(assignments: Dictionary) -> bool:
	if assignments.size() != BOARD_SIZE: return false
	for role in ROLE_LIMITS.keys():
		var count := 0
		for value in assignments.values():
			if str(value) == role: count += 1
		if count != int(ROLE_LIMITS[role]): return false
	return true

static func summary(assignments: Dictionary) -> String:
	var parts: Array[String] = []
	for role in ROLE_ORDER:
		var used := 0
		for value in assignments.values():
			if str(value) == role: used += 1
		parts.append("%s %d/%d" % [role.capitalize(),used,int(ROLE_LIMITS[role])])
	return "  ·  ".join(parts)

static func cells_for(side: String, role: String) -> Array:
	return (PLAYER_CELLS if side == "player" else RIVAL_CELLS).get(role,[])
