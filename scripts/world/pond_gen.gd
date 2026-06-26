class_name PondGen
## Sinh ao nước phong cách Ghibli (mặt nước + viền đá)


static func spawn(parent: Node3D, pos: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
	# Mặt nước - plane màu xanh lam nhạt, hơi trong suốt
	var water := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(radius * 2, 0.1, radius * 2)
	water.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.55, 0.75, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	water.material_override = mat
	water.position = pos + Vector3(0, 0.05, 0)
	water.name = "Pond"
	parent.add_child(water)

	# Viền ao - vòng đá nhỏ blocky
	for j in 12:
		var a := (j / 12.0) * TAU
		var r := radius + rng.randf_range(0.3, 0.8)
		RockGen.spawn(parent, pos + Vector3(cos(a) * r, 0, sin(a) * r), rng.randf_range(0.3, 0.6), rng)


static func generate(parent: Node3D, count: int, world_size: float, rng: RandomNumberGenerator) -> void:
	for i in count:
		var pos := _random_pos(world_size, rng)
		var radius := rng.randf_range(4.0, 8.0)
		spawn(parent, pos, radius, rng)


static func _random_pos(world_size: float, rng: RandomNumberGenerator) -> Vector3:
	var x := rng.randf_range(-world_size / 2.0, world_size / 2.0)
	var z := rng.randf_range(-world_size / 2.0, world_size / 2.0)
	return Vector3(x, 0, z)