class_name SchoolBuilder
## Builder cho trường học — vàng butter, mái russet, tháp chuông, cờ, bảng đen

static func build(b: Building3D) -> void:
	var wall_mat := b._mat(Color(0.82, 0.72, 0.40))
	var roof_mat := b._mat(Color(0.45, 0.22, 0.12))
	var door_mat := b._mat(Color(0.28, 0.16, 0.08))
	var foundation_mat := b._mat(Building3D.STONE_COL)
	b._build_shell(3.5, 2.5, 3.5, wall_mat, roof_mat, door_mat, foundation_mat, true, 1.0, 0.4)

	# Tháp chuông nhỏ trên mái
	b._add_box(Vector3(0.8, 0.9, 0.8), Vector3(0, Building3D.FOUND_H + 2.5 + 0.85, 0), b._mat(Color(0.72, 0.58, 0.28)))
	# Mái tháp — 2 tầng
	b._add_box(Vector3(1.0, 0.3, 1.0), Vector3(0, Building3D.FOUND_H + 2.5 + 1.45, 0), roof_mat)
	b._add_box(Vector3(0.7, 0.25, 0.7), Vector3(0, Building3D.FOUND_H + 2.5 + 1.7, 0), roof_mat)
	# Chuông
	b._add_box(Vector3(0.3, 0.3, 0.3), Vector3(0, Building3D.FOUND_H + 2.5 + 0.9, 0), b._mat(Color(0.6, 0.45, 0.1), 0.4))

	# Cột cờ
	b._add_box(Vector3(0.08, 3.5, 0.08), Vector3(2.2, Building3D.FOUND_H + 1.75, 2.0), b._mat(Color(0.28, 0.28, 0.28)))
	# Cờ
	b._add_box(Vector3(0.5, 0.3, 0.02), Vector3(2.45, Building3D.FOUND_H + 3.2, 2.0), b._mat(Color(0.8, 0.15, 0.15)))

	# Bảng đen + khung
	b._add_box(Vector3(1.4, 0.9, 0.04), Vector3(0, Building3D.FOUND_H + 1.5, 1.77), b._mat(Color(0.30, 0.18, 0.10)))
	b._add_box(Vector3(1.2, 0.7, 0.06), Vector3(0, Building3D.FOUND_H + 1.5, 1.78), b._mat(Color(0.08, 0.08, 0.10), 0.3))

	# Đèn lồng
	b._add_lantern(Vector3(1.5, 1.7, 2.0))

	# Bụi cây
	b._add_bush(Vector3(-2.0, Building3D.FOUND_H, 0.5), 0.8, Color(0.32, 0.52, 0.28))
	b._add_bush(Vector3(2.0, Building3D.FOUND_H, -1.0), 0.9, Color(0.35, 0.50, 0.25))

	# Path đá
	b._add_path_stones(Vector3(0, 0.03, 1.8), Vector3(0, 0.03, 3.2), 3)