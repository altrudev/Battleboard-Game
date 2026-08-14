class_name EncounterMotion
extends RefCounted

static func input_vector() -> Vector3:
	return Vector3(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		0.0,
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)

static func move_actor(actor: CharacterBody3D, direction: Vector3, speed: float, center: Vector3, radius: float) -> void:
	if direction.length() <= 0.0:
		actor.velocity = Vector3.ZERO
		return
	var d := direction.normalized()
	actor.velocity = d * speed
	actor.rotation.y = atan2(-d.x, -d.z)
	actor.move_and_slide()
	actor.global_position = clamp_point(actor.global_position, center, radius)

static func follow_actor(actor: CharacterBody3D, target: Node3D, speed: float, center: Vector3, radius: float, stop_distance: float) -> float:
	var offset := target.global_position - actor.global_position
	if offset.length() > stop_distance:
		move_actor(actor, Vector3(offset.x, 0, offset.z), speed, center, radius)
	else:
		actor.velocity = Vector3.ZERO
		face(actor, target.global_position)
	return offset.length()

static func face(actor: Node3D, point: Vector3) -> void:
	var direction := point - actor.global_position
	direction.y = 0
	if direction.length() > 0.01:
		actor.rotation.y = atan2(-direction.x, -direction.z)

static func clamp_point(point: Vector3, center: Vector3, radius: float) -> Vector3:
	var offset := point - center
	offset.y = 0
	if offset.length() > radius:
		offset = offset.normalized() * radius
	return center + offset

static func view_transform(a: Vector3, b: Vector3) -> Transform3D:
	var direction := b - a
	direction.y = 0
	if direction.length() < 0.01: direction = Vector3.RIGHT
	direction = direction.normalized()
	var side := Vector3(-direction.z, 0, direction.x)
	var position := a - direction * 4.25 + side * 1.15 + Vector3(0, 2.45, 0)
	return Transform3D(Basis.IDENTITY, position).looking_at((a + b) * 0.5 + Vector3.UP * 0.95, Vector3.UP)
