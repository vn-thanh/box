class_name RabbitBuilder
## Builder cho thỏ — body + head + ears (pivot) + tail trắng + 4 chân

static func build(a: Animal3D) -> void:
	var fur_colors := [
		Color(0.85, 0.8, 0.75), Color(0.6, 0.5, 0.4),
		Color(0.9, 0.9, 0.88), Color(0.45, 0.4, 0.35),
	]
	var fur_mat := a._mat(fur_colors[randi() % fur_colors.size()], 0.95)

	a._add_box(a._skeleton, Vector3(0.3, 0.28, 0.45), Vector3(0, 0.25, 0), fur_mat)
	a._add_box(a._skeleton, Vector3(0.22, 0.22, 0.22), Vector3(0, 0.45, 0.22), fur_mat)

	# Ears — pivot tại gốc tai, mesh offset lên trên
	var ear_box := BoxMesh.new()
	ear_box.size = Vector3(0.06, 0.22, 0.04)
	for side in [1, -1]:
		var ear := Node3D.new()
		ear.name = "EarL" if side > 0 else "EarR"
		ear.position = Vector3(0.07 * side, 0.56, 0.2)
		a._skeleton.add_child(ear)
		var ear_mesh := MeshInstance3D.new()
		ear_mesh.mesh = ear_box
		ear_mesh.position = Vector3(0, 0.11, 0)
		ear_mesh.material_override = fur_mat
		ear.add_child(ear_mesh)
		if side > 0:
			a._ear_l = ear
		else:
			a._ear_r = ear

	# Tail trắng
	a._add_box(a._skeleton, Vector3(0.1, 0.1, 0.1), Vector3(0, 0.28, -0.25), a._mat(Color(0.95, 0.95, 0.95), 0.9))

	# 4 chân
	for sx in [0.1, -0.1]:
		for sz in [0.15, -0.15]:
			a._add_box(a._skeleton, Vector3(0.08, 0.15, 0.08), Vector3(sx, 0.08, sz), fur_mat)