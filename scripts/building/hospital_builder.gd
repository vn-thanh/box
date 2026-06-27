class_name HospitalBuilder
## Builder cho bệnh viện — mint white, mái teal, dấu thập đỏ phát sáng

static func build(b: Building3D) -> void:
	var wall_mat := b._mat(Color(0.90, 0.92, 0.88))
	var roof_mat := b._mat(Color(0.42, 0.55, 0.55))
	var door_mat := b._mat(Color(0.30, 0.42, 0.42, 0.8))
	door_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	b._build_shell(4.0, 2.5, 3.5, wall_mat, roof_mat, door_mat, b._mat(Building3D.STONE_COL), true, 1.0, 0.4)

	# Dấu thập đỏ phát sáng — trên mái + trên tường
	var red_mat := b._emat(Color(0.85, 0.12, 0.12), 0.3, 0.35)
	b._add_box(Vector3(0.12, 0.5, 0.12), Vector3(0, Building3D.FOUND_H + 3.15, 0), red_mat)
	b._add_box(Vector3(0.4, 0.12, 0.12), Vector3(0, Building3D.FOUND_H + 3.0, 0), red_mat)
	b._add_box(Vector3(0.1, 0.5, 0.08), Vector3(2.0, Building3D.FOUND_H + 1.8, 1.77), red_mat)
	b._add_box(Vector3(0.35, 0.1, 0.08), Vector3(2.0, Building3D.FOUND_H + 1.8, 1.77), red_mat)

	# Bảng hiệu
	b._add_box(Vector3(1.8, 0.35, 0.08), Vector3(0, Building3D.FOUND_H + 2.2, 1.78), b._mat(Color(0.18, 0.22, 0.28)))

	b._add_lantern(Vector3(1.5, 1.7, 2.0))
	b._add_lantern(Vector3(-1.5, 1.7, 2.0))
	b._add_bush(Vector3(2.0, Building3D.FOUND_H, 1.0), 1.0, Color(0.30, 0.50, 0.28))
	b._add_bush(Vector3(-2.0, Building3D.FOUND_H, 1.0), 1.0, Color(0.30, 0.50, 0.28))
	b._add_path_stones(Vector3(0, 0.03, 1.8), Vector3(0, 0.03, 3.2), 3)