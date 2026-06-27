class_name PlacementSystem
## Hệ thống đặt công trình: grid snap + ghost preview + click đặt
## Dùng static methods, state giữ qua biến static nội bộ

const BUILDING_SCENE := preload("res://scenes/Building.tscn")
const CELL_SIZE: float = 2.0  # grid snap 2 units

# Trạng thái build mode
static var _active: bool = false
static var _build_type: int = 0  # Building3D.Type
static var _ghost: Building3D = null
static var _parent: Node3D = null
static var _camera: Camera3D = null
static var _water_areas: Array = []
static var _buildings: Array = []

# UI callback khi đặt xong
static var _on_placed: Callable = Callable()

# Grid visualization
static var _grid_node: Node3D = null
static var _world_size: float = 80.0

# Chặn click đầu tiên sau khi chọn building (tránh đặt ngay)
static var just_started: bool = false

# Rotation hiện tại của ghost (radian)
static var _build_rot: float = 0.0

# --- Road drag-build ---
# Bấm giữ chuột ở điểm đầu, kéo đến điểm cuối, hiện preview đoạn đường
# Thả tay → đặt toàn bộ road tiles dọc theo L-path (x rồi z hoặc z rồi x)
static var _road_dragging: bool = false
static var _road_start: Vector3 = Vector3.ZERO  # grid-snapped world pos
static var _road_preview: Array = []  # preview tiles
const ROAD_TILE_SIZE: float = 4.0  # road footprint 4x4
const ROAD_STEP: float = 2.0  # grid snap step = CELL_SIZE


static func is_active() -> bool:
	return _active


## Bắt đầu build mode với loại công trình
static func start_build(parent: Node3D, cam: Camera3D, build_type: int, water_areas: Array, buildings: Array, on_placed: Callable) -> void:
	_parent = parent
	_camera = cam
	_build_type = build_type
	_water_areas = water_areas
	_buildings = buildings
	_on_placed = on_placed
	_active = true
	_build_rot = 0.0
	# Lấy world_size từ parent (Main)
	if _parent.has_method("get") and _parent.get("world_size"):
		_world_size = _parent.get("world_size")
	# Hiện grid
	_show_grid()
	# Tạo ghost (preview)
	_create_ghost()
	just_started = true


## Thoát build mode
static func cancel() -> void:
	_active = false
	cancel_road_drag()
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	_hide_grid()


## Update mỗi frame — di chuyển ghost theo chuột
static func update(mouse_pos: Vector2) -> void:
	if not _active or not _ghost:
		return
	var pos := _snap_to_ground(mouse_pos)
	if pos != Vector3.ZERO:
		_ghost.global_position = pos
		# Check valid — đổi màu ghost
		var valid := PathfindingSystem.can_place(pos, _water_areas, _buildings, _ghost.grid_w, _ghost.grid_h)
		for mi in _ghost._meshes:
			var mat := mi.material_override as StandardMaterial3D
			if mat:
				if valid:
					mat.albedo_color = mat.albedo_color.lerp(Color(0.4, 1.0, 0.4), 0.5)
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				else:
					mat.albedo_color = mat.albedo_color.lerp(Color(1.0, 0.3, 0.3), 0.5)
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


## Xác nhận đặt công trình
static func confirm_place() -> Building3D:
	if not _active or not _ghost:
		return null
	var pos := _ghost.global_position
	var valid := PathfindingSystem.can_place(pos, _water_areas, _buildings, _ghost.grid_w, _ghost.grid_h)
	if not valid:
		return null
	# Tạo building thật
	var bld := BUILDING_SCENE.instantiate() as Building3D
	bld.building_type = _build_type
	_parent.add_child(bld)
	bld.global_position = pos
	bld.rotation.y = _build_rot
	_buildings.append(bld)
	PathfindingSystem.add_building(bld)
	# Đường: xóa decor (cây/cỏ/hoa/đá) nằm trong footprint
	if bld.building_type == Building3D.Type.ROAD:
		_clear_decor_in_footprint(pos, 2.0)
	# Callback
	if _on_placed.is_valid():
		_on_placed.call(bld)
	# Reset ghost cho lần đặt tiếp
	_ghost.queue_free()
	_ghost = null
	_create_ghost()
	return bld


static func _create_ghost() -> void:
	_ghost = BUILDING_SCENE.instantiate() as Building3D
	_ghost.building_type = _build_type
	_parent.add_child(_ghost)
	_ghost.rotation.y = _build_rot
	# Làm mờ tất cả mesh
	for mi in _ghost._meshes:
		var mat := mi.material_override as StandardMaterial3D
		if mat:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.5


## Xoay ghost 90 độ khi bấm R
static func rotate_ghost() -> void:
	if not _ghost:
		return
	_build_rot += PI / 2.0
	if _build_rot >= TAU - 0.01:
		_build_rot = 0.0
	_ghost.rotation.y = _build_rot


static func _snap_to_ground(mouse_pos: Vector2) -> Vector3:
	if not _camera:
		return Vector3.ZERO
	var from := _camera.project_ray_origin(mouse_pos)
	var dir := _camera.project_ray_normal(mouse_pos)
	# Intersect y=0 plane
	if abs(dir.y) < 0.001:
		return Vector3.ZERO
	var t := -from.y / dir.y
	if t < 0:
		return Vector3.ZERO
	var point := from + dir * t
	# Snap to grid
	point.x = round(point.x / CELL_SIZE) * CELL_SIZE
	point.z = round(point.z / CELL_SIZE) * CELL_SIZE
	return point


## Danh sách loại công trình có thể xây (cho UI toolbar)
static func get_build_options() -> Array[Dictionary]:
	return [
		{ "type": Building3D.Type.SAWMILL, "name": "Xưởng gỗ", "slots": 2, "icon": "🪵" },
		{ "type": Building3D.Type.CHURCH, "name": "Nhà thờ", "slots": 1, "icon": "⛪" },
		{ "type": Building3D.Type.HOSPITAL, "name": "Bệnh viện", "slots": 3, "icon": "🏥" },
		{ "type": Building3D.Type.SCHOOL, "name": "Trường học", "slots": 2, "icon": "🏫" },
		{ "type": Building3D.Type.HOUSE, "name": "Nhà ở", "slots": 0, "icon": "🏠" },
		{ "type": Building3D.Type.ROAD, "name": "Đường", "slots": 0, "icon": "🛤️" },
	]


## Xóa decor (cây/cỏ/hoa/đá) nằm trong bán kính footprint khi đặt đường
static func _clear_decor_in_footprint(pos: Vector3, radius: float) -> void:
	if not _parent:
		return
	var world_gen := _parent.get_node_or_null("WorldGenerator")
	if not world_gen:
		return
	var to_remove: Array = []
	for child in world_gen.get_children():
		if not (child is Node3D):
			continue
		var decor := child as Node3D
		# Chỉ xóa decor có tên Tree / Flower / GrassClump / Rock
		var name := decor.name
		if not (name == "Tree" or name == "Flower" or name == "GrassClump" or name == "Rock"):
			continue
		if decor.global_position.distance_to(Vector3(pos.x, 0, pos.z)) <= radius:
			to_remove.append(decor)
	for d in to_remove:
		d.queue_free()


## Hiện grid overlay khi build mode — vạch kẻ cell trên mặt đất
static func _show_grid() -> void:
	if _grid_node:
		return  # đã hiện rồi
	_grid_node = Node3D.new()
	_grid_node.name = "BuildGrid"
	_parent.add_child(_grid_node)
	var half := _world_size / 2.0
	var cells := int(_world_size / CELL_SIZE)
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(1.0, 1.0, 0.6, 0.25)
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Vạch kẻ dọc (theo trục X)
	for i in range(-cells / 2, cells / 2 + 1):
		var x := i * CELL_SIZE
		if abs(x) > half:
			continue
		var line := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.02, 0.02, _world_size)
		line.mesh = box
		line.position = Vector3(x, 0.02, 0)
		line.material_override = line_mat
		_grid_node.add_child(line)
	# Vạch kẻ ngang (theo trục Z)
	for i in range(-cells / 2, cells / 2 + 1):
		var z := i * CELL_SIZE
		if abs(z) > half:
			continue
		var line := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(_world_size, 0.02, 0.02)
		line.mesh = box
		line.position = Vector3(0, 0.02, z)
		line.material_override = line_mat
		_grid_node.add_child(line)


## Ẩn grid khi thoát build mode
static func _hide_grid() -> void:
	if _grid_node:
		_grid_node.queue_free()
		_grid_node = null


# ============================================================
# ROAD DRAG-BUILD
# ============================================================

## True nếu đang trong road drag-build mode
static func is_road_dragging() -> bool:
	return _road_dragging


## Bắt đầu drag — gọi khi nhấn chuột trái với road type
static func start_road_drag(mouse_pos: Vector2) -> void:
	var pos := _snap_to_ground(mouse_pos)
	if pos == Vector3.ZERO:
		return
	_road_start = pos
	_road_dragging = true
	# Ẩn ghost đơn khi bắt đầu drag
	if _ghost:
		_ghost.visible = false


## Update drag preview — gọi mỗi frame khi đang drag
static func update_road_drag(mouse_pos: Vector2) -> void:
	if not _road_dragging:
		return
	var end_pos := _snap_to_ground(mouse_pos)
	if end_pos == Vector3.ZERO:
		return
	_clear_road_preview()
	var tiles := _road_path(_road_start, end_pos)
	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.52, 0.44, 0.34, 0.6)
	road_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	road_mat.roughness = 0.95
	for tile_pos in tiles:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(ROAD_TILE_SIZE, 0.08, ROAD_TILE_SIZE)
		mi.mesh = box
		mi.position = tile_pos
		mi.material_override = road_mat
		_parent.add_child(mi)
		_road_preview.append(mi)


## Kết thúc drag — đặt toàn bộ road tiles, trả về số tile đã đặt
static func finish_road_drag(mouse_pos: Vector2) -> int:
	if not _road_dragging:
		return 0
	_road_dragging = false
	_clear_road_preview()
	var end_pos := _snap_to_ground(mouse_pos)
	if end_pos == Vector3.ZERO:
		end_pos = _road_start
	var tiles := _road_path(_road_start, end_pos)
	var count := 0
	for tile_pos in tiles:
		# Check valid — cho phép đặt đè lên road cũ
		var ok := _can_place_road(tile_pos)
		if not ok:
			continue
		var bld := BUILDING_SCENE.instantiate() as Building3D
		bld.building_type = _build_type
		_parent.add_child(bld)
		bld.global_position = tile_pos
		bld.rotation.y = 0.0
		_buildings.append(bld)
		PathfindingSystem.add_building(bld)
		_clear_decor_in_footprint(tile_pos, 2.0)
		if _on_placed.is_valid():
			_on_placed.call(bld)
		count += 1
	# Hiện lại ghost cho lần click tiếp theo
	if _ghost:
		_ghost.visible = true
	return count


## Hủy drag (ESC hoặc right-click)
static func cancel_road_drag() -> void:
	_road_dragging = false
	_clear_road_preview()
	if _ghost:
		_ghost.visible = true


## Tính danh sách tile positions cho đoạn đường L-shaped
## Đi theo trục X trước rồi Z (hoặc Z rồi X — chọn path ngắn nhất = thẳng)
static func _road_path(start: Vector3, end: Vector3) -> Array:
	var tiles: Array = []
	var sx := start.x
	var sz := start.z
	var ex := end.x
	var ez := end.z
	# Nếu thẳng hàng 1 trục → đường thẳng
	if sx == ex:
		# Đường dọc Z
		var z := sz
		while abs(z - ez) > 0.01:
			tiles.append(Vector3(sx, 0.04, z))
			z += sign(ez - sz) * ROAD_STEP
		tiles.append(Vector3(ex, 0.04, ez))
	elif sz == ez:
		# Đường ngang X
		var x := sx
		while abs(x - ex) > 0.01:
			tiles.append(Vector3(x, 0.04, sz))
			x += sign(ex - sx) * ROAD_STEP
		tiles.append(Vector3(ex, 0.04, ez))
	else:
		# L-shaped: đi X trước rồi Z
		var x := sx
		while abs(x - ex) > 0.01:
			tiles.append(Vector3(x, 0.04, sz))
			x += sign(ex - sx) * ROAD_STEP
		tiles.append(Vector3(ex, 0.04, sz))
		var z := sz
		while abs(z - ez) > 0.01:
			tiles.append(Vector3(ex, 0.04, z))
			z += sign(ez - sz) * ROAD_STEP
		tiles.append(Vector3(ex, 0.04, ez))
	return tiles


## Check placement cho road — cho phép đặt đè lên road cũ
static func _can_place_road(pos: Vector3) -> bool:
	# Check bounds
	if abs(pos.x) > _world_size / 2.0 - 2 or abs(pos.z) > _world_size / 2.0 - 2:
		return false
	# Check nước
	if WaterGen.is_in_water(pos, _water_areas, 2.0):
		return false
	# Check building khác (bỏ qua road)
	for b in _buildings:
		var bld := b as Building3D
		if not bld:
			continue
		if bld.building_type == Building3D.Type.ROAD:
			continue
		var dx: float = abs(pos.x - bld.global_position.x)
		var dz: float = abs(pos.z - bld.global_position.z)
		if dx < 4.0 and dz < 4.0:
			return false
	return true


## Xóa preview tiles
static func _clear_road_preview() -> void:
	for mi in _road_preview:
		if is_instance_valid(mi):
			mi.queue_free()
	_road_preview.clear()