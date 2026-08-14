from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
recruits = json.loads((ROOT / "data/recruits/recruit_pool.json").read_text())
opponent = json.loads((ROOT / "data/opponents/qualifier_gate.json").read_text())
limits = {"king": 1, "queen": 1, "rook": 1, "bishop": 1, "knight": 1, "pawn": 3}
seed = {"goro": "king", "mira": "bishop", "hana": "knight", "ren": "pawn", "sora": "pawn"}
assert len(seed) == 5
missing = {role: limits[role] - list(seed.values()).count(role) for role in limits}
assert missing == {"king": 0, "queen": 1, "rook": 1, "bishop": 0, "knight": 0, "pawn": 1}
by_id = {row["id"]: row for row in recruits}
for required in ["kael", "taro", "emi"]: assert required in by_id
assert by_id["kael"]["aptitudes"]["queen"] >= 90
assert by_id["taro"]["aptitudes"]["rook"] >= 90
assert by_id["emi"]["aptitudes"]["pawn"] >= 85
roles = {role: 0 for role in limits}
for row in opponent: roles[row["role"]] += 1
assert roles == limits and len(opponent) == 8
def cost(row): return 60 + row["level"] * 22
assert sum(cost(by_id[i]) for i in ["kael", "taro", "emi"]) <= 520
print("PASS qualification contracts")
