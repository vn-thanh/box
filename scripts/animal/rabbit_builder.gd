class_name RabbitBuilder
## Builder cho thỏ — body + head + ears (pivot) + tail trắng + 4 chân
## Chạy nhảy dưới đất, tránh nước

static func build(a: Animal3D) -> void:
	var fur_colors := [
		Color(0.85, 0.8, 0.75),  # be
		Color(0.6, 0.5, 0.4),    # nâu
		Color(0.9, 0.9, 0.88),   # trắng
		Color(0.45, 0.4, 0.35),  # nâu đậm
	]
	var fur_mat := a._mat(fur_colors[randi() % fur_colors.size()], 0.95)

	# Body
	a._add_box(a._skeleton, Vector3(0.3, 0.28, 0.45), Vector3(0, 0.25, 0), fur_mat)

	# Head
	a._add_box(a._skeleton, Vector3(0.22, 0.22, 0.22), Vector3(0, 0.45, 0.22), fur_mat)

	# Ears — pivot tại gốc tai, mesh offset lên trên
	var ear_box := BoxMesh.new()
	ear_box.size = Vector3(0.06, 0.22, 0.04)

	a._ear_l = Node3D.new()
	a._ear_l.name = "EarL"
	a._ear_l.position = Vector3(0.07, 0.56, 0.2)
	a._skeleton.add_child(a._ear_l)
	var ear_l_mesh := MeshInstance3D.new()
	ear_l_mesh.mesh = ear_box
	ear_l_mesh.position = Vector3(0, 0.11, 0)
	ear_l_mesh.material_override = fur_mat
	a._ear_l.add_child(ear_l_mesh)

	a._ear_r = Node3D.new()
	a._ear_r.name = "EarR"
	a._ear_r.position = Vector3(-0.07, 0.56, 0.2)
	a._skeleton.add_child(a._ear_r)
	var ear_r_mesh := MeshInstance3D.new()
	ear_r_mesh.mesh = ear_box
	ear_r_mesh.position = Vector3(0, 0.11, 0)
	ear_r_mesh.material_override = fur_mat
	a._ear_r.add_child(ear_r_mesh)

	# Tail — box trắng nhỏ
	var tail_mat := a._mat(Color(0.95, 0.95, 0.95), 0.9)
	a._add_box(a._skeleton, Vector3(0.1, 0.1, 0.1), Vector3(0, 0.28, -0.25), tail_mat)

	# Legs — 4 box nhỏ
	for sx in [0.1, -0.1]:
		for sz in [0.15, -0.15]:
			a._add_box(a._skeleton, Vector3(0.08, 0.15, 0.08), Vector3(sx, 0.08, sz), fur_mat)