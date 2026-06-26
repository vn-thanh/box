class_name TreeGen
## Sinh cây cổ thụ blocky phong cách Ghibli


const LEAF_COLORS := [
	Color(0.2, 0.45, 0.2),
	Color(0.25, 0.5, 0.25),
	Color(0.3, 0.55, 0.3),
	Color(0.35, 0.6, 0.3),
]


static func spawn(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var tree := Node3D.new()
	tree.position = pos
	tree.name = "Tree"
	parent.add_child(tree)

	var trunk_height := rng.randf_range(2.0, 4.0)
	var trunk_radius := rng.randf_range(0.2, 0.35)

	# Thân cây - box nâu
	var trunk := MeshInstance3D.new()
	var trunk_mesh := BoxMesh.new()
	var trunk_w := trunk_radius * 1.5
	trunk_mesh.size = Vector3(trunk_w, trunk_height, trunk_w)
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(0, trunk_height / 2.0, 0)
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.35, 0.25, 0.15)
	trunk_mat.roughness = 0.95
	trunk.material_override = trunk_mat
	tree.add_child(trunk)

	# Tán lá - 2-4 box xanh đậm chồng lên nhau
	var canopy_layers := rng.randi_range(2, 4)
	for j in canopy_layers:
		var canopy := MeshInstance3D.new()
		var box := BoxMesh.new()
		var s := rng.randf_range(1.5, 2.8)
		box.size = Vector3(s, s * 0.8, s)
		canopy.mesh = box
		var offset := Vector3(
			rng.randf_range(-0.5, 0.5),
			trunk_height + rng.randf_range(0.0, 0.8),
			rng.randf_range(-0.5, 0.5)
		)
		canopy.position = offset

		var mat := StandardMaterial3D.new()
		mat.albedo_color = LEAF_COLORS[rng.randi_range(0, LEAF_COLORS.size() - 1)]
		mat.roughness = 1.0
		canopy.material_override = mat
		tree.add_child(canopy)

	# Sway animation cho tán lá
	SwayAnim.sway_tree(tree, rng.randf_range(1.5, 3.0), rng.randf_range(0.01, 0.03), rng)


static func generate(parent: Node3D, count: int, world_size: float, rng: RandomNumberGenerator) -> void:
	for i in count:
		var pos := _random_pos(world_size, rng)
		# Tránh spawn quá gần center (nơi player start)
		if pos.length() < 5.0:
			pos = pos.normalized() * 5.0
		spawn(parent, pos, rng)


static func _random_pos(world_size: float, rng: RandomNumberGenerator) -> Vector3:
	var x := rng.randf_range(-world_size / 2.0, world_size / 2.0)
	var z := rng.randf_range(-world_size / 2.0, world_size / 2.0)
	return Vector3(x, 0, z)