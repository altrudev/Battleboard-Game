from pathlib import Path
import json,re,sys
root=Path(__file__).resolve().parents[1]
errors=[]
project=(root/'project.godot').read_text()
if 'config/version="0.3.0"' not in project: errors.append('project version is not 0.3.0')
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
for path in root.rglob('*.gd'):
    text=path.read_text()
    m=re.search(r'^class_name\s+(\w+)',text,re.M)
    if m:
        if m.group(1) in classes: errors.append(f'duplicate class {m.group(1)}')
        classes[m.group(1)]=str(path.relative_to(root))
    for bad in ['keycoe','B_face','_constrain(initiator)_']:
        if bad in text: errors.append(f'known corruption token {bad} in {path}')
required=['CampaignState','QualificationRules','TrainingManager','ProgressionManager','SaveManager','MatchController','CampaignUI','BBTacticalPlanner']
for name in required:
    if name not in classes: errors.append(f'missing class {name}')
if errors:
    print('FAIL')
    for e in errors: print('-',e)
    sys.exit(1)
print(f'PASS: {len(recruits)} recruits, {len(opponents)}-fighter qualifier, {len(classes)} named classes')
