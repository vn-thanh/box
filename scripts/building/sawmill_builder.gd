class_name SawmillBuilder
## Builder cho xưởng gỗ — gỗ ấm, mái slate, ống khói, log pile, đèn lồng

static func build(b: Building3D) -> void:
	var wall_mat := b._mat(Color(0.58, 0.44, 0.30))
	var roof_mat := b._mat(Color(0.28, 0.22, 0.18))
	var door_mat := b._mat(Color(0.30, 0.18, 0.10))
	var foundation_mat := b._mat(Building3D.STONE_COL)
	b._build_shell(3.5, 2.2, 3.0, wall_mat, roof_mat, door_mat, foundation_mat, true, 1.0, 0.4)

	# Ván gỗ dọc tường
	var plank_mat := b._mat(Color(0.45, 0.30, 0.15), 0.95)
	for i in 4:
		b._add_box(Vector3(0.05, 1.9, 3.0), Vector3(-1.75 + i * 0.5, Building3D.FOUND_H + 0.95, 0), plank_mat)

	# Ống khói
	var chimney_mat := b._mat(Color(0.40, 0.32, 0.25))
	b._add_box(Vector3(0.4, 1.6, 0.4), Vector3(1.2, Building3D.FOUND_H + 2.2 + 0.8, -0.5), chimney_mat)
	b._add_box(Vector3(0.5, 0.1, 0.5), Vector3(1.2, Building3D.FOUND_H + 2.2 + 1.65, -0.5), chimney_mat)

	# Khúc gỗ chất bên hông
	var log_mat := b._mat(Color(0.50, 0.35, 0.18), 0.95)
	for i in 3:
		var z_off := -1.0 + i * 0.5
		b._add_box(Vector3(1.0, 0.22, 0.22), Vector3(-2.2, Building3D.FOUND_H + 0.11 + i * 0.22, z_off), log_mat)

	# Bàn gỗ phía trước
	b._add_box(Vector3(1.2, 0.08, 0.5), Vector3(0, Building3D.FOUND_H + 0.65, 2.2), b._mat(Color(0.40, 0.25, 0.12)))
	for sx in [0.5, -0.5]:
		b._add_box(Vector3(0.08, 0.6, 0.08), Vector3(sx, Building3D.FOUND_H + 0.3, 2.2), b._mat(Color(0.35, 0.22, 0.10)))

	# Đèn lồng bên cửa
	b._add_lantern(Vector3(1.5, 1.8, 2.0))

	# Path đá ra cửa
	b._add_path_stones(Vector3(0, 0.03, 1.7), Vector3(0, 0.03, 3.0), 3)