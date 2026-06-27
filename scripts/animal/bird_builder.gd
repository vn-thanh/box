class_name BirdBuilder
## Builder cho chim — body + head + beak + wings (pivot) + tail
## Bay trên cao, vỗ cánh

static func build(a: Animal3D) -> void:
	var body_colors := [
		Color(0.3, 0.5, 0.8),   # xanh dương
		Color(0.8, 0.3, 0.3),   # đỏ
		Color(0.9, 0.8, 0.3),   # vàng
		Color(0.5, 0.4, 0.3),   # nâu
		Color(0.3, 0.6, 0.5),   # xanh lá nhạt
	]
	var body_mat := a._mat(body_colors[randi() % body_colors.size()], 0.8)
	var beak_mat := a._mat(Color(1.0, 0.7, 0.2), 0.6)

	# Body
	a._add_box(a._skeleton, Vector3(0.25, 0.22, 0.4), Vector3.ZERO, body_mat)

	# Head
	a._add_box(a._skeleton, Vector3(0.18, 0.18, 0.18), Vector3(0, 0.08, 0.25), body_mat)

	# Beak
	a._add_box(a._skeleton, Vector3(0.06, 0.05, 0.1), Vector3(0, 0.05, 0.36), beak_mat)

	# Wings — pivot tại vai, mesh offset ra ngoài
	var wing_box := BoxMesh.new()
	wing_box.size = Vector3(0.3, 0.04, 0.25)

	a._wing_l = Node3D.new()
	a._wing_l.name = "WingL"
	a._wing_l.position = Vector3(0.14, 0.05, 0)
	a._skeleton.add_child(a._wing_l)
	var wing_l_mesh := MeshInstance3D.new()
	wing_l_mesh.mesh = wing_box
	wing_l_mesh.position = Vector3(0.15, 0, 0)
	wing_l_mesh.material_override = body_mat
	a._wing_l.add_child(wing_l_mesh)

	a._wing_r = Node3D.new()
	a._wing_r.name = "WingR"
	a._wing_r.position = Vector3(-0.14, 0.05, 0)
	a._skeleton.add_child(a._wing_r)
	var wing_r_mesh := MeshInstance3D.new()
	wing_r_mesh.mesh = wing_box
	wing_r_mesh.position = Vector3(-0.15, 0, 0)
	wing_r_mesh.material_override = body_mat
	a._wing_r.add_child(wing_r_mesh)

	# Tail
	a._add_box(a._skeleton, Vector3(0.12, 0.06, 0.18), Vector3(0, 0.03, -0.28), body_mat)

	a._skeleton.scale = Vector3(0.6, 0.6, 0.6)