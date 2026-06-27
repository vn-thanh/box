class_name ChurchBuilder
## Builder cho nhà thờ — cream ấm, mái terracotta, tháp chuông, kính màu

static func build(b: Building3D) -> void:
	var wall_mat := b._mat(Color(0.88, 0.84, 0.75))
	var roof_mat := b._mat(Color(0.50, 0.22, 0.15))
	var door_mat := b._mat(Color(0.20, 0.12, 0.06))
	var foundation_mat := b._mat(Building3D.STONE_COL)
	b._build_shell(3.0, 2.8, 4.5, wall_mat, roof_mat, door_mat, foundation_mat, false, 1.2, 0.5)

	# Vòm cửa (đắp nổi)
	b._add_box(Vector3(1.3, 0.25, 0.08), Vector3(0, Building3D.FOUND_H + 2.05, 2.27), wall_mat)
	b._add_box(Vector3(1.0, 0.25, 0.08), Vector3(0, Building3D.FOUND_H + 2.30, 2.27), wall_mat)

	# Tháp chuông
	var tower_mat := b._mat(Color(0.85, 0.80, 0.70))
	var tower_w := 1.4
	var tower_h := 4.5
	var tower_z := 2.5
	b._add_box(Vector3(tower_w, tower_h, tower_w), Vector3(0, Building3D.FOUND_H + tower_h / 2.0, tower_z), tower_mat)

	# Mái tháp — pyramid 3 tầng
	var pyramid_base := Building3D.FOUND_H + tower_h
	for i in 3:
		var sz := tower_w + 0.3 - i * 0.45
		b._add_box(Vector3(sz, 0.35, sz), Vector3(0, pyramid_base + 0.17 + i * 0.35, tower_z), roof_mat)
	b._add_box(Vector3(0.2, 0.3, 0.2), Vector3(0, pyramid_base + 1.4, tower_z), roof_mat)

	# Thập tự — phát sáng nhẹ
	var cross_mat := b._emat(Color(0.85, 0.75, 0.25), 0.4, 0.4)
	b._add_box(Vector3(0.08, 0.5, 0.08), Vector3(0, pyramid_base + 1.75, tower_z), cross_mat)
	b._add_box(Vector3(0.25, 0.08, 0.08), Vector3(0, pyramid_base + 1.65, tower_z), cross_mat)

	# Chuông trong tháp
	b._add_box(Vector3(0.45, 0.45, 0.45), Vector3(0, Building3D.FOUND_H + 3.5, tower_z), b._mat(Color(0.65, 0.50, 0.12), 0.4))

	# Kính màu 2 bên hông
	var stained := [
		Color(0.5, 0.2, 0.35, 0.6),
		Color(0.55, 0.35, 0.15, 0.6),
		Color(0.2, 0.35, 0.3, 0.6),
	]
	for i in 3:
		var z_off := -1.5 + i * 1.5
		var g1 := b._mat(stained[i], 0.1)
		g1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		b._add_window(1.55, Building3D.FOUND_H + 1.5, z_off, 0.35, 1.2, b._mat(Building3D.WOOD_DARK), g1)
		var g2 := b._mat(stained[(i + 1) % 3], 0.1)
		g2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		b._add_window(-1.55, Building3D.FOUND_H + 1.5, z_off, 0.35, 1.2, b._mat(Building3D.WOOD_DARK), g2)

	# Đèn lồng 2 bên cửa
	b._add_lantern(Vector3(1.2, 1.8, 2.3))
	b._add_lantern(Vector3(-1.2, 1.8, 2.3))

	# Path đá
	b._add_path_stones(Vector3(0, 0.03, 1.8), Vector3(0, 0.03, 3.5), 4)