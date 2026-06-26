extends Node3D
class_name WorldGenerator

## Sinh môi trường phong cách Ghibli: đồng cỏ, cây cổ thụ, hoa dại, đá, ao nước
## Tất cả dùng mesh primitive + màu thủ công, không cần asset ngoài

@export var world_size: float = 80.0
@export var tree_count: int = 40
@export var flower_count: int = 120
@export var grass_clump_count: int = 200
@export var rock_count: int = 25
@export var pond_count: int = 3
@export var seed: int = 42

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = seed
	_generate_all()


func _generate_all() -> void:
	_generate_ponds()
	_generate_grass()
	_generate_flowers()
	_generate_rocks()
	_generate_trees()


# ============================================================
# AO NƯỚC
# ============================================================
func _generate_ponds() -> void:
	for i in pond_count:
		var pos := _random_pos()
		var radius := _rng.randf_range(4.0, 8.0)

		# Mặt nước - plane màu xanh lam nhạt, hơi trong suốt
		var water := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(radius * 2, 0.1, radius * 2)
		water.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.55, 0.75, 0.8)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.1
		water.material_override = mat
		water.position = pos + Vector3(0, 0.05, 0)
		water.name = "Pond%d" % i
		add_child(water)

		# Viền ao - vòng đá nhỏ blocky
		for j in 12:
			var a := (j / 12.0) * TAU
			var r := radius + _rng.randf_range(0.3, 0.8)
			_spawn_rock(pos + Vector3(cos(a) * r, 0, sin(a) * r), _rng.randf_range(0.3, 0.6))


# ============================================================
# CỎ LÚA - đung đưa theo gió
# ============================================================
func _generate_grass() -> void:
	for i in grass_clump_count:
		var pos := _random_pos()
		_spawn_grass_clump(pos)


func _spawn_grass_clump(pos: Vector3) -> void:
	var clump := Node3D.new()
	clump.position = pos
	clump.name = "GrassClump"
	add_child(clump)

	var blade_count := _rng.randi_range(3, 7)
	for j in blade_count:
		var offset := Vector3(_rng.randf_range(-0.4, 0.4), 0, _rng.randf_range(-0.4, 0.4))
		var height := _rng.randf_range(0.3, 0.6)
		var blade := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.08, height, 0.02)
		blade.mesh = mesh
		blade.position = offset + Vector3(0, height / 2.0, 0)
		blade.rotation.y = _rng.randf() * TAU

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45 + _rng.randf_range(-0.05, 0.08), 0.65 + _rng.randf_range(-0.05, 0.05), 0.3, 1.0)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		blade.material_override = mat
		clump.add_child(blade)

	# Sway animation
	_animate_sway(clump, _rng.randf_range(0.8, 1.5), _rng.randf_range(0.03, 0.06))


# ============================================================
# HOA DẠI
# ============================================================
func _generate_flowers() -> void:
	var flower_colors := [
		Color(1.0, 0.8, 0.3),   # vàng
		Color(1.0, 0.5, 0.5),   # hồng
		Color(0.9, 0.6, 1.0),   # tím
		Color(1.0, 1.0, 0.9),   # trắng
		Color(1.0, 0.6, 0.3),   # cam
	]
	for i in flower_count:
		var pos := _random_pos()
		_spawn_flower(pos, flower_colors[_rng.randi_range(0, flower_colors.size() - 1)])


func _spawn_flower(pos: Vector3, color: Color) -> void:
	var flower := Node3D.new()
	flower.position = pos
	flower.name = "Flower"
	add_child(flower)

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

	# Nhụt - box nhỏ vàng
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

	_animate_sway(flower, _rng.randf_range(1.0, 2.0), _rng.randf_range(0.02, 0.04))


# ============================================================
# ĐÁ
# ============================================================
func _generate_rocks() -> void:
	for i in rock_count:
		var pos := _random_pos()
		_spawn_rock(pos, _rng.randf_range(0.3, 0.8))


func _spawn_rock(pos: Vector3, scale_val: float) -> void:
	var rock := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(scale_val, scale_val * 0.6, scale_val)
	rock.mesh = mesh
	rock.position = pos + Vector3(0, scale_val * 0.3, 0)
	rock.rotation = Vector3(0, _rng.randf() * TAU, 0)

	var mat := StandardMaterial3D.new()
	var gray := _rng.randf_range(0.4, 0.55)
	mat.albedo_color = Color(gray, gray + 0.03, gray + 0.02)
	mat.roughness = 0.9
	rock.material_override = mat
	rock.name = "Rock"
	add_child(rock)


# ============================================================
# CÂY CỔ THỤ
# ============================================================
func _generate_trees() -> void:
	for i in tree_count:
		var pos := _random_pos()
		# Tránh spawn quá gần center (nơi player start)
		if pos.length() < 5.0:
			pos = pos.normalized() * 5.0
		_spawn_tree(pos)


func _spawn_tree(pos: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = pos
	tree.name = "Tree"
	add_child(tree)

	var trunk_height := _rng.randf_range(2.0, 4.0)
	var trunk_radius := _rng.randf_range(0.2, 0.35)

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
	var leaf_colors := [
		Color(0.2, 0.45, 0.2),
		Color(0.25, 0.5, 0.25),
		Color(0.3, 0.55, 0.3),
		Color(0.35, 0.6, 0.3),
	]
	var canopy_layers := _rng.randi_range(2, 4)
	for j in canopy_layers:
		var canopy := MeshInstance3D.new()
		var box := BoxMesh.new()
		var s := _rng.randf_range(1.5, 2.8)
		box.size = Vector3(s, s * 0.8, s)
		canopy.mesh = box
		var offset := Vector3(
			_rng.randf_range(-0.5, 0.5),
			trunk_height + _rng.randf_range(0.0, 0.8),
			_rng.randf_range(-0.5, 0.5)
		)
		canopy.position = offset

		var mat := StandardMaterial3D.new()
		mat.albedo_color = leaf_colors[_rng.randi_range(0, leaf_colors.size() - 1)]
		mat.roughness = 1.0
		canopy.material_override = mat
		tree.add_child(canopy)

	# Sway animation cho tán lá
	_animate_sway_tree(tree, _rng.randf_range(1.5, 3.0), _rng.randf_range(0.01, 0.03))


# ============================================================
# SWAY ANIMATION (gió thổi)
# ============================================================
func _animate_sway(node: Node3D, period: float, amplitude: float) -> void:
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	# Sway rotation Z
	var t := 0.0
	var phase := _rng.randf() * TAU
	tween.tween_method(
		func(val: float) -> void: node.rotation.z = sin(val) * amplitude,
		phase, phase + TAU, period
	)


func _animate_sway_tree(node: Node3D, period: float, amplitude: float) -> void:
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	var phase := _rng.randf() * TAU
	# Sway toàn bộ cây nhẹ nhàng
	tween.tween_method(
		func(val: float) -> void:
			node.rotation.z = sin(val) * amplitude
			node.rotation.x = cos(val * 0.7) * amplitude * 0.5,
		phase, phase + TAU, period
	)


# ============================================================
# UTILS
# ============================================================
func _random_pos() -> Vector3:
	var x := _rng.randf_range(-world_size / 2.0, world_size / 2.0)
	var z := _rng.randf_range(-world_size / 2.0, world_size / 2.0)
	return Vector3(x, 0, z)