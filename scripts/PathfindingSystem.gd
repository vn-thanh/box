class_name PathfindingSystem
## A* pathfinding trên grid 2D (XZ plane)
## Né vật cản: nước (WaterArea) + công trình (Building3D)
## Grid cell size = 1.0 unit, world bounds = [-half, +half]

const CELL_SIZE: float = 1.0

# Grid data: key = "x,z" (int), value = true (blocked) / false (free)
# Dùng Dictionary cho simplicity, không cần Array2D
static var _blocked: Dictionary = {}
static var _grid_half: float = 40.0


## Khởi tạo grid từ world size + water areas + buildings
static func init_grid(world_size: float, water_areas: Array, buildings: Array) -> void:
	_blocked.clear()
	_grid_half = world_size / 2.0

	# Block nước
	for area in water_areas:
		var wa = area
		var cx := int(round(wa.center.x / CELL_SIZE))
		var cz := int(round(wa.center.z / CELL_SIZE))
		var r := int(ceil(wa.radius / CELL_SIZE)) + 1
		for x in range(cx - r, cx + r + 1):
			for z in range(cx - r, cz + r + 1):
				var wx := x * CELL_SIZE
				var wz := z * CELL_SIZE
				if Vector3(wx, 0, wz).distance_to(Vector3(wa.center.x, 0, wa.center.z)) < wa.radius:
					_set_blocked(x, z, true)

	# Block công trình (footprint)
	for b in buildings:
		var bld := b as Building3D
		if not bld:
			continue
		var bx := int(round(bld.global_position.x / CELL_SIZE))
		var bz := int(round(bld.global_position.z / CELL_SIZE))
		for x in range(bx - bld.grid_w, bx + bld.grid_w + 1):
			for z in range(bz - bld.grid_h, bz + bld.grid_h + 1):
				_set_blocked(x, z, true)


## Thêm 1 công trình vào grid (sau khi đặt mới)
static func add_building(bld: Building3D) -> void:
	var bx := int(round(bld.global_position.x / CELL_SIZE))
	var bz := int(round(bld.global_position.z / CELL_SIZE))
	for x in range(bx - bld.grid_w, bx + bld.grid_w + 1):
		for z in range(bz - bld.grid_h, bz + bld.grid_h + 1):
			_set_blocked(x, z, true)


## Kiểm tra vị trí có đặt được công trình không (không đè nước/building khác)
static func can_place(pos: Vector3, water_areas: Array, buildings: Array, grid_w: int, grid_h: int) -> bool:
	# Check trong bounds
	var half := _grid_half
	if abs(pos.x) > half - grid_w or abs(pos.z) > half - grid_h:
		return false
	# Check nước
	if WaterGen.is_in_water(pos, water_areas, float(maxi(grid_w, grid_h))):
		return false
	# Check building khác (overlap footprint)
	for b in buildings:
		var bld := b as Building3D
		if not bld:
			continue
		var dx: float = abs(pos.x - bld.global_position.x)
		var dz: float = abs(pos.z - bld.global_position.z)
		if dx < (grid_w + bld.grid_w) * CELL_SIZE and dz < (grid_h + bld.grid_h) * CELL_SIZE:
			return false
	return true


## Tìm đường A* từ start đến goal (world coords)
## Trả về Array[Vector3] — danh sách waypoint (world coords), rỗng nếu không tìm thấy
static func find_path(start: Vector3, goal: Vector3) -> Array:
	var sx := int(round(start.x / CELL_SIZE))
	var sz := int(round(start.z / CELL_SIZE))
	var gx := int(round(goal.x / CELL_SIZE))
	var gz := int(round(goal.z / CELL_SIZE))

	# Goal bị block → tìm cell tự do gần nhất
	if _is_blocked(gx, gz):
		var alt := _nearest_free(gx, gz)
		if alt == Vector2i.ZERO:
			return []
		gx = alt.x
		gz = alt.y

	# A* với priority queue đơn giản
	var open: Array = [Vector2i(sx, sz)]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {}
	g_score[Vector2i(sx, sz)] = 0.0
	var f_score: Dictionary = {}
	f_score[Vector2i(sx, sz)] = _heuristic(sx, sz, gx, gz)

	var max_iter := 5000
	var iter := 0
	while open.size() > 0 and iter < max_iter:
		iter += 1
		# Tìm node có f_score nhỏ nhất
		var best_idx := 0
		var best_f: float = float(f_score.get(open[0], INF))
		for i in range(1, open.size()):
			var f: float = float(f_score.get(open[i], INF))
			if f < best_f:
				best_f = f
				best_idx = i
		var current: Vector2i = open[best_idx]

		if current.x == gx and current.y == gz:
			# reconstruct path
			return _reconstruct(came_from, current)

		open.remove_at(best_idx)

		# 8 hướng (cho đường chéo mượt hơn)
		var dirs := [
			Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
		]
		for d in dirs:
			var nx: int = current.x + d.x
			var nz: int = current.y + d.y
			var neighbor := Vector2i(nx, nz)

			# Kiểm tra bounds
			if abs(nx) > int(_grid_half / CELL_SIZE) or abs(nz) > int(_grid_half / CELL_SIZE):
				continue
			# Kiểm tra blocked (cho phép goal cell ngay cả khi blocked — đã handle ở trên)
			if _is_blocked(nx, nz) and not (nx == gx and nz == gz):
				continue
			# Chéo: không cho đi qua góc chéo nếu 2 cell kề bị block
			if d.x != 0 and d.y != 0:
				if _is_blocked(current.x + d.x, current.y) and _is_blocked(current.x, current.y + d.y):
					continue

			var step_cost := 1.414 if (d.x != 0 and d.y != 0) else 1.0
			var tentative: float = float(g_score.get(current, INF)) + step_cost
			if tentative < float(g_score.get(neighbor, INF)):
				came_from[neighbor] = current
				g_score[neighbor] = tentative
				f_score[neighbor] = tentative + _heuristic(nx, nz, gx, gz)
				if neighbor not in open:
					open.append(neighbor)

	return []  # không tìm thấy


static func _heuristic(x1: int, y1: int, x2: int, y2: int) -> float:
	# Octile distance
	var dx: int = abs(x1 - x2)
	var dy: int = abs(y1 - y2)
	return (dx + dy) + (1.414 - 2.0) * mini(dx, dy)


static func _reconstruct(came_from: Dictionary, current: Vector2i) -> Array:
	var path: Array = []
	var c: Vector2i = current
	while came_from.has(c):
		path.append(Vector3(c.x * CELL_SIZE, 0, c.y * CELL_SIZE))
		c = came_from[c]
	path.reverse()
	return path


static func _is_blocked(x: int, z: int) -> bool:
	return _blocked.get(Vector2i(x, z), false)


static func _set_blocked(x: int, z: int, blocked: bool) -> void:
	_blocked[Vector2i(x, z)] = blocked


## Tìm cell tự do gần nhất (BFS nhỏ)
static func _nearest_free(cx: int, cz: int) -> Vector2i:
	for r in range(1, 8):
		for x in range(cx - r, cx + r + 1):
			for z in range(cz - r, cz + r + 1):
				if abs(x - cx) != r and abs(z - cz) != r:
					continue
				if not _is_blocked(x, z):
					return Vector2i(x, z)
	return Vector2i.ZERO