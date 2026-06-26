class_name TreeGen
## Sinh cây cổ thụ blocky phong cách Ghibli
## Cây mọc thành cụm rừng, tránh vùng nước


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


## Sinh cây rải rác + cụm rừng, tránh vùng nước
static func generate(parent: Node3D, count: int, world_size: float, rng: RandomNumberGenerator, water_areas: Array = []) -> void:
	var spawned: int = 0
	var max_attempts: int = count * 5

	# ~60% cây mọc thành cụm rừng, ~40% rải rác
	var cluster_count := maxi(2, count / 6)
	var scattered_count := count - cluster_count * 4

	# Sinh cụm rừng — mỗi cluster có 4-6 cây gần nhau
	for _c in cluster_count:
		if spawned >= count:
			break
		var cluster_pos := WaterGen.safe_pos(world_size, rng, water_areas, 5.0)
		var trees_in_cluster := rng.randi_range(4, 6)
		for _t in trees_in_cluster:
			if spawned >= count:
				break
			# Cây trong cluster cách nhau 2-5 units
			var offset := Vector3(rng.randf_range(-5.0, 5.0), 0, rng.randf_range(-5.0, 5.0))
			var pos := cluster_pos + offset
			if _is_safe(pos, world_size, water_areas):
				spawn(parent, pos, rng)
				spawned += 1

	# Sinh cây rải rác
	for _s in scattered_count:
		if spawned >= count:
			break
		var pos := WaterGen.safe_pos(world_size, rng, water_areas, 3.0)
		# Tránh spawn quá gần center (nơi player start)
		if pos.length() < 5.0:
			pos = pos.normalized() * 5.0
		spawn(parent, pos, rng)
		spawned += 1


static func _is_safe(pos: Vector3, world_size: float, water_areas: Array) -> bool:
	if pos.length() < 5.0:
		return false
	if WaterGen.is_in_water(pos, water_areas, 2.0):
		return false
	return true