from pathlib import Path
import json, re

ROOT = Path(__file__).resolve().parents[1]
errors = []

project = (ROOT / 'project.godot').read_text()
if 'config/version="0.4.3"' not in project:
    errors.append('demo project version must be 0.4.3')

story = json.loads((ROOT / 'data/story/chapter1.json').read_text())
if len(story.get('opening', [])) < 5:
    errors.append('opening story must contain at least five beats')
if len(story.get('victory', [])) < 4:
    errors.append('victory story must contain at least four beats')
for sequence_name in ['opening', 'victory']:
    for i, page in enumerate(story.get(sequence_name, [])):
        for field in ['speaker', 'title', 'text']:
            if not str(page.get(field, '')).strip():
                errors.append(f'{sequence_name}[{i}] missing {field}')

required_files = [
    'systems/demo_director.gd',
    'scripts/demo_title_screen.gd',
    'scripts/story_overlay.gd',
    'scripts/tutorial_overlay.gd',
    'scripts/boot.gd',
    'scenes/boot.tscn',
]
for rel in required_files:
    if not (ROOT / rel).exists():
        errors.append(f'missing demo surface: {rel}')

main = (ROOT / 'scripts/main.gd').read_text()
for token in ['runtime_ready', '_new_demo', '_continue_demo', 'story.show_sequence("opening")', 'story.show_sequence("victory")']:
    if token not in main:
        errors.append(f'main demo flow missing {token}')

campaign = (ROOT / 'systems/campaign_state.gd').read_text()
for token in ['intro_seen', 'ending_seen', 'demo_completed', 'reset_demo']:
    if token not in campaign:
        errors.append(f'campaign persistence missing {token}')

save = (ROOT / 'systems/save_manager.gd').read_text()
if 'SAVE_VERSION := 4' not in save:
    errors.append('save schema must be v4')
if 'LEGACY_PATH' not in save or 'battleboard_v03_save.json' not in save:
    errors.append('v0.3 save migration path missing')

recruits = {row['id']: row for row in json.loads((ROOT / 'data/recruits/recruit_pool.json').read_text())}
canonical = ['taro', 'emi', 'kael']
if not all(pid in recruits for pid in canonical):
    errors.append('canonical demo recruitment path missing')
else:
    total_cost = sum(60 + int(recruits[pid]['level']) * 22 for pid in canonical)
    if total_cost > 520:
        errors.append(f'canonical demo recruit path costs {total_cost}, exceeds starting 520 crowns')
    if recruits['taro']['aptitudes']['rook'] < 80:
        errors.append('Taro must remain a strong Rook demo option')
    if recruits['emi']['aptitudes']['pawn'] < 80:
        errors.append('Emi must remain a strong Pawn demo option')
    if recruits['kael']['aptitudes']['queen'] < 85:
        errors.append('Kael must remain a strong Queen demo option')

demo_director = (ROOT / 'systems/demo_director.gd').read_text()
if 'func _set(' in demo_director:
    errors.append('DemoDirector must not shadow Godot Object._set')

boot = (ROOT / 'scripts/boot.gd').read_text() if (ROOT / 'scripts/boot.gd').exists() else ''
if 'run/main_scene="res://scenes/boot.tscn"' not in project:
    errors.append('demo must launch through diagnostic boot scene')
for token in ['ResourceLoader.load', 'runtime_ready', 'STARTUP HAS NOT COMPLETED']:
    if token not in boot:
        errors.append(f'boot flow missing {token}')

campaign_ui = (ROOT / 'scripts/campaign_ui.gd').read_text()
for callback in ['_request_start_match', '_request_save', '_request_recruit']:
    if f'func {callback}(' not in campaign_ui:
        errors.append(f'CampaignUI callback missing: {callback}')

board_rules = (ROOT / 'addons/battleboard_engine/runtime/board_rules.gd').read_text()
if 'var c := origin + d' in board_rules or 'for d in [Vector2i' in board_rules:
    errors.append('board_rules contains Godot 4.7.1 unsafe Variant vector inference')
for token in ['Array[Vector2i]', 'var cell: Vector2i', 'var other: String']:
    if token not in board_rules:
        errors.append(f'board_rules explicit typing missing: {token}')

if errors:
    print('FAIL')
    for error in errors:
        print('-', error)
    raise SystemExit(1)

print('PASS: v0.4.3 Chapter One demo contract, diagnostic boot, runtime callback/parser regressions, v4 save migration')
