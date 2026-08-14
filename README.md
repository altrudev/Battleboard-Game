# Battleboard Game

Battleboard is a tactical action RPG about assembling a tournament board from recruits whose position aptitude, predispositions, history and relationships affect how they perform together.

## v0.2 visual proof

This build connects the management layer to the signature visual loop:

**recruit → assign board role → deploy → tactical move → challenge → direct third-person control → affinity intervention → tactical resolution**

### Run

1. Install Godot `4.7.1-stable`.
2. Open `project.godot`.
3. Run the main scene.
4. Select **Hana** and then **Iron Ward** on the highlighted hostile Knight destination.
5. In direct control use:
   - `WASD` — move
   - left click — strike
   - `Q` — focus technique
   - `E` — parry
   - `Shift` — evade
6. Ren begins adjacent to Hana and can trigger the first visible affinity intervention.

## What is intentionally prototype-quality

The articulated characters are generated from primitive meshes so mechanics, camera, silhouettes and animation-state timing can be proven before final Blender/glTF assets exist. Their public presentation API is designed to survive the asset replacement.
