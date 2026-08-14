# Battleboard v0.2 Visual Proof

## Goal

Prove that tactical board movement, persistent recruits, affinity support and direct third-person control read as one continuous game.

## Implemented

- 8x8 physical tactical board.
- Recruit pool, roster assignment and six board-position aptitudes.
- Affinity/resonance projection from predispositions, shared experience and relationships.
- Articulated stylized humanoid fighter rig built at runtime.
- Named joint hierarchy and right-hand weapon socket.
- Role-specific sword/staff/hammer silhouettes.
- Procedural idle/run/attack/technique/parry/dodge/hit/support/down animation states.
- Smooth tactical-camera to direct-control transition without loading another scene.
- Direct encounter controls: WASD movement, click strike, Q technique, E parry, Shift evade.
- Rival pursuit and counterattacks.
- Visible affinity intervention: the strongest compatible adjacent ally performs a support animation and launches an in-world resonance projectile.
- Encounter resolution returns to tactical camera and updates authoritative board occupancy.
- Stylized arena frame, gates, lanterns, banners and layered lighting.

## Immediate test path

1. Launch the project.
2. Select Hana on the lower-left side of the board.
3. Select the red Iron Ward square at C4-equivalent coordinates (`Vector2i(2,3)`).
4. Camera should descend into direct control.
5. Use WASD / Click / Q / E / Shift.
6. Ren is adjacent to Hana; positive affinity should produce one visible support intervention during the encounter.
7. On resolution the camera should return to tactical view and board occupancy should update.

## Production boundary

The v0.2 character is a procedural proof rig, not final art. Production Blender/glTF characters should replace the mesh parts while preserving the gameplay/presentation API and weapon socket contract.
