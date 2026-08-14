from pathlib import Path
import json, subprocess, sys, hashlib, datetime
ROOT=Path(__file__).resolve().parents[1]
steps=[[sys.executable,str(ROOT/'tools/validate_project.py')],[sys.executable,str(ROOT/'tests/test_qualification_contracts.py')]]
results=[]
for cmd in steps:
    run=subprocess.run(cmd,cwd=ROOT,text=True,capture_output=True)
    results.append({'command':Path(cmd[1]).name,'returncode':run.returncode,'stdout':run.stdout.strip(),'stderr':run.stderr.strip()})
tracked=[ROOT/'project.godot',ROOT/'data/recruits/recruit_pool.json',ROOT/'data/opponents/qualifier_gate.json',ROOT/'systems/match_controller.gd',ROOT/'systems/save_manager.gd',ROOT/'addons/battleboard_engine/runtime/tactical_planner.gd']
hashes={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in tracked}
evidence={'contract':'battleboard.v0.3.first-qualifier','generated_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pass':all(r['returncode']==0 for r in results),'results':results,'sha256':hashes,'runtime_execution':'requires Godot 4.7.1-stable'}
out=ROOT/'ddc/evidence/v03_gate.json'; out.parent.mkdir(parents=True,exist_ok=True); out.write_text(json.dumps(evidence,indent=2)+'\n')
print(json.dumps(evidence,indent=2)); sys.exit(0 if evidence['pass'] else 1)
