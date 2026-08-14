#!/usr/bin/env python3
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "project.godot",
    "scenes/main.tscn",
    "scripts/main.gd",
    "scripts/board_controller.gd",
    "scripts/encounter_controller.gd",
    "systems/recruitment_manager.gd",
    "systems/roster_manager.gd",
    "addons/battleboard_engine/runtime/profile.gd",
    "addons/battleboard_engine/runtime/affinity_engine.gd",
    "addons/battleboard_engine/runtime/board_state.gd",
    "addons/battleboard_engine/runtime/board_rules.gd",
    "addons/battleboard_engine/runtime/encounter_context.gd",
    "addons/battleboard_engine/presentation/piece_visual.gd",
    "addons/battleboard_engine/presentation/piece_rig.gd",
    "addons/battleboard_engine/presentation/piece_pose.gd",
    "data/recruits/recruit_pool.json",
]


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)

for rel in REQUIRED:
    if not (ROOT / rel).is_file():
        fail(f"missing {rel}")

pool = json.loads((ROOT / "data/recruits/recruit_pool.json").read_text(encoding="utf-8"))
if not isinstance(pool, list) or len(pool) < 6:
    fail("recruit pool must contain at least six profiles")
required_roles = {"pawn", "knight", "bishop", "rook", "queen", "king"}
for recruit in pool:
    if not recruit.get("id") or not recruit.get("name"):
        fail("recruit missing id/name")
    if set(recruit.get("aptitudes", {})) != required_roles:
        fail(f"{recruit.get('id')} does not define all six position aptitudes")

classes = {}
for path in ROOT.rglob("*.gd"):
    text = path.read_text(encoding="utf-8")
    match = re.search(r"^class_name\s+(\w+)", text, re.MULTILINE)
    if match:
        name = match.group(1)
        if name in classes:
            fail(f"duplicate class_name {name}")
        classes[name] = path.relative_to(ROOT).as_posix()

expected_classes = {
    "BBProfile", "BBAffinityEngine", "BBBoardState", "BBBoardRules",
    "BBEncounterContext", "BBPieceVisual", "BBPieceRig", "BBPiecePose", "RecruitmentManager",
    "RosterManager", "BoardController", "EncounterController",
}
missing = expected_classes - set(classes)
if missing:
    fail(f"missing class registrations: {sorted(missing)}")

project = (ROOT / "project.godot").read_text(encoding="utf-8")
if 'run/main_scene="res://scenes/main.tscn"' not in project:
    fail("project main scene is not configured")

print(f"PASS: Battleboard project structure valid; {len(pool)} recruits; {len(classes)} named classes")
