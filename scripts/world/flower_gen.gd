class_name FlowerGen
## Sinh hoa dại phong cách Ghibli


const FLOWER_COLORS := [
	Color(1.0, 0.8, 0.3),   # vàng
	Color(1.0, 0.5, 0.5),   # hồng
	Color(0.9, 0.6, 1.0),   # tím
	Color(1.0, 1.0, 0.9),   # trắng
	Color(1.0, 0.6, 0.3),   # cam
]


static func spawn(parent: Node3D, pos: Vector3, color: Color, rng: RandomNumberGenerator) -> void:
	var flower := Node3D.new()
	flower.position = pos
	flower.name = "Flower"
	parent.add_child(flower)

	# Thân cây - box mỏng xanh
	var stem := MeshInstance3D.new()
	var stem_mesh := BoxMesh.new()
	stem_mesh.size = Vector3(0.04, 0.35, 0.04)
	stem.mesh = stem_mesh
	stem.position = Vector3(0, 0.175, 0)
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.35, 0.6, 0.25)
	stem_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stem.material_override = stem_mat
	flower.add_child(stem)

	# Cánh hoa - 4 cánh xếp hình chữ thập (box)
	for k in 4:
		var petal := MeshInstance3D.new()
		var petal_mesh := BoxMesh.new()
		petal_mesh.size = Vector3(0.18, 0.02, 0.18)
		petal.mesh = petal_mesh
		petal.position = Vector3(0, 0.38, 0)
		petal.rotation.y = (k / 4.0) * TAU
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		petal.material_override = mat
		flower.add_child(petal)

	# Nhụy - box nhỏ vàng
	var center := MeshInstance3D.new()
	var center_mesh := BoxMesh.new()
	center_mesh.size = Vector3(0.08, 0.08, 0.08)
	center.mesh = center_mesh
	center.position = Vector3(0, 0.38, 0)
	var center_mat := StandardMaterial3D.new()
	center_mat.albedo_color = Color(1.0, 0.85, 0.2)
	center_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	center.material_override = center_mat
	flower.add_child(center)

	SwayAnim.sway(flower, rng.randf_range(1.0, 2.0), rng.randf_range(0.02, 0.04), rng)


static func generate(parent: Node3D, count: int, world_size: float, rng: RandomNumberGenerator) -> void:
	for i in count:
		var pos := _random_pos(world_size, rng)
		var color: Color = FLOWER_COLORS[rng.randi_range(0, FLOWER_COLORS.size() - 1)]
		spawn(parent, pos, color, rng)


static func _random_pos(world_size: float, rng: RandomNumberGenerator) -> Vector3:
	var x := rng.randf_range(-world_size / 2.0, world_size / 2.0)
	var z := rng.randf_range(-world_size / 2.0, world_size / 2.0)
	return Vector3(x, 0, z)