class_name ArenaBuilder
extends RefCounted

static func build(parent: Node3D) -> void:
	_box(parent,Vector3(0,-0.62,0),Vector3(30,0.25,30),Color("#11161d"))
	for z in [-12.0,12.0]: _gate(parent,Vector3(0,0,z))
	for x in [-12.0,12.0]:
		for z in [-8.0,-2.5,2.5,8.0]: _lantern(parent,Vector3(x,0,z))
	for x in [-7.5,7.5]:
		for z in [-11.4,11.4]: _box(parent,Vector3(x,2,z),Vector3(1.2,2.4,0.08),Color("#693f42") if z > 0 else Color("#435a78"))

static func _gate(parent: Node3D,origin: Vector3) -> void:
	for x in [-3.4,3.4]: _box(parent,origin+Vector3(x,2,0),Vector3(0.48,4.4,0.48),Color("#3a2526"))
	_box(parent,origin+Vector3(0,4,0),Vector3(8.4,0.42,0.62),Color("#3a2526"))
	_box(parent,origin+Vector3(0,4.46,0),Vector3(9.2,0.22,0.85),Color("#3a2526"))

static func _lantern(parent: Node3D,origin: Vector3) -> void:
	var post := MeshInstance3D.new(); var pm := CylinderMesh.new(); pm.top_radius=0.06; pm.bottom_radius=0.08; pm.height=2.0
	post.mesh=pm; post.position=origin+Vector3(0,0.6,0); post.material_override=_mat(Color("#292d32"),0.75); parent.add_child(post)
	var lamp := MeshInstance3D.new(); var lm := BoxMesh.new(); lm.size=Vector3(0.42,0.58,0.42); lamp.mesh=lm; lamp.position=origin+Vector3(0,1.55,0)
	var glow:=_mat(Color("#e5b96a"),0.38); glow.emission_enabled=true; glow.emission=Color("#d99d42"); glow.emission_energy_multiplier=1.8
	lamp.material_override=glow; parent.add_child(lamp)

static func _box(parent: Node3D,pos: Vector3,size: Vector3,color: Color) -> void:
	var node:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size; node.mesh=mesh; node.position=pos; node.material_override=_mat(color,0.75); parent.add_child(node)

static func _mat(color: Color,roughness: float) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=color; m.roughness=roughness; return m
