class_name GrassGen
## Sinh cụm cỏ lúa đung đưa theo gió, phong cách Ghibli


static func spawn_clump(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var clump := Node3D.new()
	clump.position = pos
	clump.name = "GrassClump"
	parent.add_child(clump)

	var blade_count := rng.randi_range(3, 7)
	for j in blade_count:
		var offset := Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
		var height := rng.randf_range(0.3, 0.6)
		var blade := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.08, height, 0.02)
		blade.mesh = mesh
		blade.position = offset + Vector3(0, height / 2.0, 0)
		blade.rotation.y = rng.randf() * TAU

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(
			0.45 + rng.randf_range(-0.05, 0.08),
			0.65 + rng.randf_range(-0.05, 0.05),
			0.3, 1.0
		)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		blade.material_override = mat
		clump.add_child(blade)

	SwayAnim.sway(clump, rng.randf_range(0.8, 1.5), rng.randf_range(0.03, 0.06), rng)


static func generate(parent: Node3D, count: int, world_size: float, rng: RandomNumberGenerator) -> void:
	for i in count:
		var pos := _random_pos(world_size, rng)
		spawn_clump(parent, pos, rng)


static func _random_pos(world_size: float, rng: RandomNumberGenerator) -> Vector3:
	var x := rng.randf_range(-world_size / 2.0, world_size / 2.0)
	var z := rng.randf_range(-world_size / 2.0, world_size / 2.0)
	return Vector3(x, 0, z)