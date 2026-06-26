class_name RockGen
## Sinh đá blocky phong cách Ghibli


static func spawn(parent: Node3D, pos: Vector3, scale_val: float, rng: RandomNumberGenerator) -> void:
	var rock := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(scale_val, scale_val * 0.6, scale_val)
	rock.mesh = mesh
	rock.position = pos + Vector3(0, scale_val * 0.3, 0)
	rock.rotation = Vector3(0, rng.randf() * TAU, 0)

	var mat := StandardMaterial3D.new()
	var gray := rng.randf_range(0.4, 0.55)
	mat.albedo_color = Color(gray, gray + 0.03, gray + 0.02)
	mat.roughness = 0.9
	rock.material_override = mat
	rock.name = "Rock"
	parent.add_child(rock)


static func generate(parent: Node3D, count: int, world_size: float, rng: RandomNumberGenerator) -> void:
	for i in count:
		var pos := _random_pos(world_size, rng)
		spawn(parent, pos, rng.randf_range(0.3, 0.8), rng)


static func _random_pos(world_size: float, rng: RandomNumberGenerator) -> Vector3:
	var x := rng.randf_range(-world_size / 2.0, world_size / 2.0)
	var z := rng.randf_range(-world_size / 2.0, world_size / 2.0)
	return Vector3(x, 0, z)