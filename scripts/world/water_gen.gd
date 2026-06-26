class_name WaterGen
## Sinh vùng nước tự nhiên: hồ bất quy tắc + sông uốn lượn
## Trả về danh sách vùng nước (center + radius) để generators khác tránh


# Một vùng nước (hồ hoặc đoạn sông)
class WaterArea:
	var center: Vector3
	var radius: float
	func _init(c: Vector3, r: float) -> void:
		center = c
		radius = r


# Kiểm tra điểm có nằm trong vùng nước nào không
static func is_in_water(pos: Vector3, areas: Array, margin: float = 1.0) -> bool:
	for area in areas:
		var wa := area as WaterArea
		if pos.distance_to(wa.center) < wa.radius + margin:
			return true
	return false


# Tìm vị trí ngẫu nhiên không trong nước
static func safe_pos(world_size: float, rng: RandomNumberGenerator, water_areas: Array, margin: float = 2.0) -> Vector3:
	for _attempt in 30:
		var x := rng.randf_range(-world_size / 2.0, world_size / 2.0)
		var z := rng.randf_range(-world_size / 2.0, world_size / 2.0)
		var pos := Vector3(x, 0, z)
		if not is_in_water(pos, water_areas, margin):
			return pos
	# Fallback: điểm xa nhất có thể
	return Vector3(rng.randf_range(-world_size / 2.0, world_size / 2.0), 0, rng.randf_range(-world_size / 2.0, world_size / 2.0))


# ============================================================
# HỒ NƯỚC — hình bất quy tắc bằng nhiều segment tròn chồng nhau
# ============================================================
static func spawn_pond(parent: Node3D, center: Vector3, base_radius: float, rng: RandomNumberGenerator) -> WaterArea:
	var blob_count := rng.randi_range(3, 6)
	var max_r: float = base_radius

	# Sinh các blob nhỏ xung quanh center tạo hình bất quy tắc
	for i in blob_count:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.0, base_radius * 0.6)
		var blob_pos := center + Vector3(cos(a) * d, 0, sin(a) * d)
		var blob_r := base_radius * rng.randf_range(0.5, 0.9)

		_spawn_water_segment(parent, blob_pos, blob_r, rng)
		max_r = max(max_r, d + blob_r)

	# Viền đá — rải dọc theo viền blob lớn nhất
	var stone_count := 16
	for j in stone_count:
		var a := (j / float(stone_count)) * TAU + rng.randf_range(-0.15, 0.15)
		var r := base_radius * rng.randf_range(0.85, 1.1)
		RockGen.spawn(parent, center + Vector3(cos(a) * r, 0, sin(a) * r), rng.randf_range(0.25, 0.55), rng)

	return WaterArea.new(center, max_r + 1.0)


# ============================================================
# SÔNG — uốn lượn theo path, mỗi đoạn là một segment nước
# ============================================================
static func spawn_river(parent: Node3D, start: Vector3, world_size: float, rng: RandomNumberGenerator) -> Array:
	var areas: Array = []
	var width := rng.randf_range(2.5, 4.5)
	var pos := start
	var dir := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
	var segment_count := rng.randi_range(15, 25)
	var step := world_size / float(segment_count) * 0.8

	for i in segment_count:
		# Uốn lượn: xoay hướng ngẫu nhiên mỗi bước
		dir = dir.rotated(Vector3.UP, rng.randf_range(-0.4, 0.4)).normalized()
		pos += dir * step

		# Giữ trong bounds
		var half := world_size / 2.0
		if abs(pos.x) > half or abs(pos.z) > half:
			break

		# Width dao động nhẹ
		var w := width * rng.randf_range(0.8, 1.2)
		_spawn_water_segment(parent, pos, w, rng)
		areas.append(WaterArea.new(pos, w + 0.5))

		# Đá dọc bờ sông (thỉnh thoảng)
		if rng.randf() < 0.3:
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			var perp := Vector3(-dir.z, 0, dir.x) * side
			RockGen.spawn(parent, pos + perp * (w + rng.randf_range(0.2, 0.8)), rng.randf_range(0.2, 0.5), rng)

	return areas


# ============================================================
# SEGMENT NƯỚC — một mảnh mặt nước hình tròn
# ============================================================
static func _spawn_water_segment(parent: Node3D, pos: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
	var water := MeshInstance3D.new()
	var box := BoxMesh.new()
	# Dùng box vuông nhỏ cho mỗi segment — nhiều segment chồng nhau tạo hình tự nhiên
	var s := radius * 2.0
	box.size = Vector3(s, 0.1, s)
	water.mesh = box

	var mat := StandardMaterial3D.new()
	# Màu nước đậm hơn ở giữa, nhưng dùng 1 màu cho đơn giản
	mat.albedo_color = Color(0.2, 0.45, 0.65, 0.82)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.08
	mat.metallic = 0.3
	water.material_override = mat
	water.position = pos + Vector3(0, 0.05, 0)
	water.name = "Water"
	parent.add_child(water)


# ============================================================
# GENERATE — sinh hồ + sông, trả về tất cả vùng nước
# ============================================================
static func generate(parent: Node3D, pond_count: int, river_count: int, world_size: float, rng: RandomNumberGenerator) -> Array:
	var all_areas: Array = []

	# Sinh hồ trước
	for i in pond_count:
		var pos := _random_pos(world_size, rng)
		# Hồ thường ở xa center một chút
		if pos.length() < 8.0:
			pos = pos.normalized() * 8.0
		var radius := rng.randf_range(4.0, 8.0)
		var area := spawn_pond(parent, pos, radius, rng)
		all_areas.append(area)

	# Sinh sông — bắt đầu từ rìa map
	for i in river_count:
		var edge_angle := rng.randf() * TAU
		var start := Vector3(cos(edge_angle), 0, sin(edge_angle)) * (world_size * 0.45)
		var river_areas := spawn_river(parent, start, world_size, rng)
		all_areas.append_array(river_areas)

	return all_areas


static func _random_pos(world_size: float, rng: RandomNumberGenerator) -> Vector3:
	var x := rng.randf_range(-world_size / 2.0, world_size / 2.0)
	var z := rng.randf_range(-world_size / 2.0, world_size / 2.0)
	return Vector3(x, 0, z)