# Battleboard — Chapter One Demo

Battleboard is a tactical board-management RPG where board movement determines the challenge, but contested squares are resolved through direct third-person control.

## v0.4.1 demo

**Chapter One: No Board, No Entry** turns the technical prototype into a guided first-session experience:

- New Demo / Continue title screen
- narrative registration rejection and Bronze Board objective
- five-fighter starting stable
- scouting and recruitment from a twelve-fighter pool
- six-position aptitude and role training
- affinity-aware eight-position board assembly
- Ashline Local Qualifier with deterministic rival tactical planning
- direct-control contested squares and visible ally resonance support
- XP, relationships, injuries, rewards and persistent save
- Chapter One ending after the first qualifier win

### v0.4.1 hotfix

The first real Godot 4.7.1 editor smoke test exposed a parser failure caused by a DemoDirector helper named `_set`, which collided with Godot `Object._set(StringName, Variant) -> bool`. The helper was renamed and project validation now checks Godot virtual callback signatures so this class of engine-name collision fails validation before packaging.

Target runtime: Godot 4.7.1-stable.
