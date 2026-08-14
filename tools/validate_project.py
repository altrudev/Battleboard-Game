from pathlib import Path
import json,re,sys
root=Path(__file__).resolve().parents[1]
errors=[]
project=(root/'project.godot').read_text()
if 'config/version="0.4.2"' not in project: errors.append('project version is not 0.4.2')
recruits=json.loads((root/'data/recruits/recruit_pool.json').read_text())
if len(recruits)<12: errors.append('expected at least 12 recruit profiles')
roles={'king','queen','rook','bishop','knight','pawn'}
for row in recruits:
    if set(row.get('aptitudes',{}))!=roles: errors.append(f"{row.get('id')} role aptitudes incomplete")
opponents=json.loads((root/'data/opponents/qualifier_gate.json').read_text())
if len(opponents)!=8: errors.append('qualifier opponent must contain 8 fighters')
counts={r:0 for r in roles}
for row in opponents: counts[row['role']]+=1
expected={'king':1,'queen':1,'rook':1,'bishop':1,'knight':1,'pawn':3}
if counts!=expected: errors.append(f'opponent roles invalid: {counts}')
classes={}
virtual_arity={
    '_get':1,'_get_property_list':0,'_iter_get':1,'_iter_init':1,'_iter_next':1,
    '_notification':1,'_property_can_revert':1,'_property_get_revert':1,'_set':2,
    '_to_string':0,'_validate_property':1,
    '_enter_tree':0,'_exit_tree':0,'_get_configuration_warnings':0,'_input':1,
    '_physics_process':1,'_process':1,'_ready':0,'_shortcut_input':1,
    '_unhandled_input':1,'_unhandled_key_input':1,
    '_draw':0,'_gui_input':1,'_get_minimum_size':0,
}
def _arg_count(arg_text):
    arg_text=arg_text.strip()
    if not arg_text: return 0
    return len([x for x in arg_text.split(',') if x.strip()])
for path in root.rglob('*.gd'):
    text=path.read_text()
    m=re.search(r'^class_name\s+(\w+)',text,re.M)
    for fn,args in re.findall(r'^func\s+(_\w+)\s*\(([^)]*)\)',text,re.M):
        if fn in virtual_arity and _arg_count(args) != virtual_arity[fn]:
            errors.append(f'Godot virtual callback signature collision {fn} in {path.relative_to(root)}: expected {virtual_arity[fn]} args, found {_arg_count(args)}')
    if m:
        if m.group(1) in classes: errors.append(f'duplicate class {m.group(1)}')
        classes[m.group(1)]=str(path.relative_to(root))
    for bad in ['keycoe','B_face','_constrain(initiator)_','\\n\\t']:
        if bad in text: errors.append(f'known corruption token {bad} in {path}')
required=['CampaignState','QualificationRules','TrainingManager','ProgressionManager','SaveManager','MatchController','CampaignUI','BBTacticalPlanner','DemoDirector','DemoTitleScreen','StoryOverlay','TutorialOverlay']
for name in required:
    if name not in classes: errors.append(f'missing class {name}')
story_path=root/'data/story/chapter1.json'
if not story_path.exists(): errors.append('missing Chapter One story data')
else:
    story=json.loads(story_path.read_text())
    if 'opening' not in story or 'victory' not in story: errors.append('story sequences incomplete')
boot_scene=root/'scenes/boot.tscn'
boot_script=root/'scripts/boot.gd'
if not boot_scene.exists(): errors.append('missing independent boot scene')
if not boot_script.exists(): errors.append('missing independent boot script')
if 'run/main_scene="res://scenes/boot.tscn"' not in project: errors.append('project must launch through boot scene')
if boot_script.exists():
    boot_text=boot_script.read_text()
    for forbidden in ['CampaignState','RecruitmentManager','BBProfile','BoardController','EncounterController']:
        if forbidden in boot_text: errors.append(f'boot script must remain runtime-independent; found {forbidden}')
    for required_token in ['ResourceLoader.load','runtime_ready','STARTUP HAS NOT COMPLETED']:
        if required_token not in boot_text: errors.append(f'boot diagnostics missing {required_token}')
if errors:
    print('FAIL')
    for e in errors: print('-',e)
    sys.exit(1)
print(f'PASS: {len(recruits)} recruits, {len(opponents)}-fighter qualifier, {len(classes)} named classes, Chapter One demo surfaces')
