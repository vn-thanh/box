class_name HouseBuilder
## Builder cho nhà ở — peach ấm, mái đỏ, ống khói, hàng rào, bụi cây

static func build(b: Building3D) -> void:
	var wall_mat := b._mat(Color(0.82, 0.72, 0.60))
	var roof_mat := b._mat(Color(0.50, 0.22, 0.16))
	var door_mat := b._mat(Color(0.28, 0.16, 0.08))
	b._build_shell(3.0, 2.0, 3.0, wall_mat, roof_mat, door_mat, b._mat(Building3D.STONE_COL), true, 0.9, 0.35)

	# Ống khói + cap
	var chimney_mat := b._mat(Color(0.52, 0.35, 0.28))
	b._add_box(Vector3(0.3, 1.2, 0.3), Vector3(0.8, Building3D.FOUND_H + 2.6, -0.5), chimney_mat)
	b._add_box(Vector3(0.4, 0.08, 0.4), Vector3(0.8, Building3D.FOUND_H + 3.24, -0.5), chimney_mat)

	# Bậc cửa
	b._add_box(Vector3(1.0, 0.08, 0.25), Vector3(0, Building3D.FOUND_H + 0.04, 1.6), b._mat(Color(0.42, 0.32, 0.22)))

	# Hàng rào + thanh ngang
	var fence_mat := b._mat(Color(0.48, 0.35, 0.20))
	for i in 5:
		b._add_box(Vector3(0.06, 0.4, 0.06), Vector3(-1.8 + i * 0.9, Building3D.FOUND_H + 0.2, 2.2), fence_mat)
	b._add_box(Vector3(2.5, 0.04, 0.04), Vector3(0, Building3D.FOUND_H + 0.28, 2.2), fence_mat)

	# Bụi cây + đèn lồng + path đá
	b._add_bush(Vector3(-1.6, Building3D.FOUND_H, 0.8), 0.7, Color(0.32, 0.52, 0.28))
	b._add_bush(Vector3(1.6, Building3D.FOUND_H, 0.8), 0.7, Color(0.35, 0.50, 0.25))
	b._add_lantern(Vector3(0.8, 1.4, 1.65))
	b._add_path_stones(Vector3(0, 0.03, 1.7), Vector3(0, 0.03, 2.8), 3)