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
	# Tạo ghost (preview)
	_create_ghost()


## Thoát build mode
static func cancel() -> void:
	_active = false
	if _ghost:
		_ghost.queue_free()
		_ghost = null


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
	_buildings.append(bld)
	PathfindingSystem.add_building(bld)
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
	# Làm mờ tất cả mesh
	for mi in _ghost._meshes:
		var mat := mi.material_override as StandardMaterial3D
		if mat:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.5


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
	]