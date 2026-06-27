extends Node3D

var npc_scene: PackedScene = preload("res://scenes/NPC.tscn")
var building_scene: PackedScene = preload("res://scenes/Building.tscn")

@onready var camera: Camera3D = $Camera3D
@onready var ground_mesh: MeshInstance3D = $Ground/GroundMesh
@onready var world_gen: WorldGenerator = $WorldGenerator
@onready var env: Environment = $WorldEnvironment.environment
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var info_panel: Panel = $CanvasLayer/InfoPanel
@onready var info_name: Label = $CanvasLayer/InfoPanel/HBox/InfoVBox/NameLabel
@onready var info_details: Label = $CanvasLayer/InfoPanel/HBox/InfoVBox/DetailsLabel
@onready var info_job: Label = $CanvasLayer/InfoPanel/HBox/InfoVBox/JobLabel
@onready var portrait_vp: SubViewport = $CanvasLayer/InfoPanel/HBox/Portrait/PortraitVP
@onready var portrait_cam: Camera3D = $CanvasLayer/InfoPanel/HBox/Portrait/PortraitVP/Cam

# Build mode UI
@onready var build_toolbar: Panel = $CanvasLayer/BuildToolbar
@onready var btn_sawmill: Button = $CanvasLayer/BuildToolbar/BtnScroll/BtnVBox/BtnSawmill
@onready var btn_church: Button = $CanvasLayer/BuildToolbar/BtnScroll/BtnVBox/BtnChurch
@onready var btn_hospital: Button = $CanvasLayer/BuildToolbar/BtnScroll/BtnVBox/BtnHospital
@onready var btn_school: Button = $CanvasLayer/BuildToolbar/BtnScroll/BtnVBox/BtnSchool
@onready var btn_house: Button = $CanvasLayer/BuildToolbar/BtnScroll/BtnVBox/BtnHouse
@onready var btn_road: Button = $CanvasLayer/BuildToolbar/BtnScroll/BtnVBox/BtnRoad
@onready var cancel_btn: Button = $CanvasLayer/BuildToolbar/CancelBtn
@onready var bld_info_panel: Panel = $CanvasLayer/BuildingInfoPanel
@onready var bld_name_label: Label = $CanvasLayer/BuildingInfoPanel/BldNameLabel
@onready var bld_slots_label: Label = $CanvasLayer/BuildingInfoPanel/BldSlotsLabel
@onready var bld_workers_label: Label = $CanvasLayer/BuildingInfoPanel/BldWorkersLabel

# Hover/selected NPC state
var _hovered_npc: NPC3D = null
var _selected_npc: NPC3D = null
var _portrait_npc: NPC3D = null  # clone currently shown in portrait

# Selected building state
var _selected_building: Building3D = null

# Danh sách công trình
var _buildings: Array = []

const NPC_COUNT: int = 8

# World config — nhận từ MainMenu hoặc mặc định
var world_name: String = "World"
var world_size: float = 80.0
var _is_loaded_game: bool = false
var _load_data: Dictionary = {}

# Camera control — WASD pans, scroll zooms
var cam_target: Vector3 = Vector3.ZERO
var cam_target_smooth: Vector3 = Vector3.ZERO
const CAM_SPEED: float = 35.0
const CAM_SMOOTH: float = 6.0

# Zoom
var zoom: float = 1.0
var zoom_current: float = 1.0
const ZOOM_MIN: float = 0.4
const ZOOM_MAX: float = 2.5
const ZOOM_SPEED: float = 0.15
const ZOOM_SMOOTH: float = 8.0
const CAM_BASE_SIZE: float = 18.0

# Isometric offset: 45° Y rotation, ~35° tilt (true iso = 1:1:1)
var _cam_offset: Vector3 = Vector3(1, 1, 1).normalized() * 25.0

# Middle mouse drag
var _dragging: bool = false
var _drag_last_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Đọc meta từ MainMenu (new game hoặc load)
	var tree := get_tree()
	if tree.has_meta("new_game_meta"):
		var meta: Dictionary = tree.get_meta("new_game_meta")
		world_name = meta.get("world_name", "World")
		world_size = float(meta.get("world_size", 80.0))
		tree.remove_meta("new_game_meta")
	elif tree.has_meta("load_game_data"):
		_load_data = tree.get_meta("load_game_data")
		world_name = _load_data.get("world_name", "World")
		world_size = float(_load_data.get("world_size", 80.0))
		_is_loaded_game = true
		tree.remove_meta("load_game_data")

	# Áp dụng world_size cho WorldGenerator
	if world_gen:
		world_gen.world_size = world_size
		# Scale ground mesh theo world_size
		var ground_scale := world_size / 80.0
		ground_mesh.scale = Vector3(ground_scale, 1, ground_scale)
		# Generate world SAU khi set world_size
		world_gen.generate()

	# Ground màu cỏ
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.42, 0.55, 0.28)
	ground_mat.roughness = 1.0
	ground_mesh.material_override = ground_mat

	if _is_loaded_game:
		_load_npcs()
		_load_buildings()
	else:
		_spawn_npcs()

	# Khởi tạo pathfinding grid
	var water_areas: Array = world_gen.get_water_areas() if world_gen else []
	PathfindingSystem.init_grid(world_size, water_areas, _buildings)

	# Connect build toolbar buttons
	btn_sawmill.pressed.connect(func(): _start_build(Building3D.Type.SAWMILL))
	btn_church.pressed.connect(func(): _start_build(Building3D.Type.CHURCH))
	btn_hospital.pressed.connect(func(): _start_build(Building3D.Type.HOSPITAL))
	btn_school.pressed.connect(func(): _start_build(Building3D.Type.SCHOOL))
	btn_house.pressed.connect(func(): _start_build(Building3D.Type.HOUSE))
	btn_road.pressed.connect(func(): _start_build(Building3D.Type.ROAD))
	cancel_btn.pressed.connect(_cancel_build)


func _spawn_npcs() -> void:
	var water_areas: Array = world_gen.get_water_areas() if world_gen else []
	for i in NPC_COUNT:
		var npc := npc_scene.instantiate() as NPC3D
		add_child(npc)
		var pos := Vector3.ZERO
		for _attempt in 30:
			var angle := randf() * TAU
			var dist := randf_range(5.0, world_size * 0.4)
			pos = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
			if not WaterGen.is_in_water(pos, water_areas, 2.0):
				break
		npc.global_position = pos
		npc.world_bounds = world_size * 0.45
		npc.water_areas = water_areas


func _load_npcs() -> void:
	var water_areas: Array = world_gen.get_water_areas() if world_gen else []
	var npcs: Array = _load_data.get("npcs", [])
	for npc_data in npcs:
		var npc := npc_scene.instantiate() as NPC3D
		# Set identity TRƯỚC khi add_child để _ready() không ghi đè
		npc.npc_name = npc_data.get("name", "")
		npc.age = int(npc_data.get("age", 25))
		npc.gender = npc_data.get("gender", "male")
		add_child(npc)
		# Khôi phục vị trí (sau add_child để global_position hoạt động)
		npc.global_position = Vector3(
			float(npc_data.get("pos_x", 0.0)),
			0,
			float(npc_data.get("pos_z", 0.0))
		)
		npc.world_bounds = world_size * 0.45
		npc.water_areas = water_areas


func _load_buildings() -> void:
	var building_data: Array = _load_data.get("buildings", [])
	for bdata in building_data:
		var bld := building_scene.instantiate() as Building3D
		bld.building_type = int(bdata.get("type", 0))
		bld.job_slots = int(bdata.get("job_slots", 2))
		add_child(bld)
		bld.global_position = Vector3(
			float(bdata.get("pos_x", 0.0)),
			0,
			float(bdata.get("pos_z", 0.0))
		)
		bld.rotation.y = float(bdata.get("rot_y", 0.0))
		_buildings.append(bld)
	# Gán lại NPC vào building theo save data
	var npc_list: Array = []
	for child in get_children():
		if child is NPC3D:
			npc_list.append(child)
	for bdata in building_data:
		var worker_names: Array = bdata.get("workers", [])
		for bld in _buildings:
			var b := bld as Building3D
			if not b:
				continue
			for wname in worker_names:
				for npc_child in npc_list:
					var npc := npc_child as NPC3D
					if npc and npc.npc_name == wname:
						b.assign_worker(npc)
						break


func _process(delta: float) -> void:
	# WASD camera movement — screen-relative directions
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := camera.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	cam_target += (forward * (-input.y) + right * input.x) * CAM_SPEED * delta

	# Middle mouse drag — di chuyển camera theo chuột (1:1, không delay)
	if _dragging:
		var mouse_pos := get_viewport().get_mouse_position()
		var delta_mouse := mouse_pos - _drag_last_pos
		# Orthographic: world units per pixel = camera.size / viewport_height
		# Drag sang phải = camera sang trái, drag xuống = camera lùi
		var vp_size := get_viewport().get_visible_rect().size
		var world_per_pixel := camera.size / vp_size.y
		cam_target -= right * delta_mouse.x * world_per_pixel
		cam_target += forward * delta_mouse.y * world_per_pixel
		# Sync ngay — không smooth khi drag
		cam_target_smooth = cam_target
		_drag_last_pos = mouse_pos
	else:
		cam_target_smooth = cam_target_smooth.lerp(cam_target, CAM_SMOOTH * delta)

	# Smooth zoom
	zoom_current = lerpf(zoom_current, zoom, ZOOM_SMOOTH * delta)
	camera.size = CAM_BASE_SIZE * zoom_current

	# Fog density tỷ lệ nghịch với zoom — zoom out = fog mỏng hơn để nhìn xa
	# zoom 0.4 (close) → density 0.02, zoom 2.5 (far) → density 0.004
	if env:
		var fog_factor := remap(zoom_current, ZOOM_MIN, ZOOM_MAX, 0.02, 0.004)
		env.fog_density = lerpf(env.fog_density, fog_factor, CAM_SMOOTH * delta)

	# Shadow distance scale theo zoom — đảm bảo toàn bộ vùng nhìn thấy đều có bóng
	# Orthographic camera: viewport width ≈ camera.size, diagonal ≈ size * 1.4
	# shadow distance cần >= diagonal để phủ hết màn hình
	if sun:
		var view_extent: float = camera.size * 1.5
		sun.directional_shadow_max_distance = lerpf(
			sun.directional_shadow_max_distance,
			view_extent,
			CAM_SMOOTH * delta
		)

	# Position camera at isometric angle, look at target
	camera.global_position = cam_target_smooth + _cam_offset
	camera.look_at(cam_target_smooth, Vector3.UP)

	# Hover detection via mouse raycast
	if not PlacementSystem.is_active():
		_update_hover()
	else:
		PlacementSystem.update(get_viewport().get_mouse_position())


func _update_hover() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	var closest_npc: NPC3D = null
	var closest_dist: float = INF
	for child in get_children():
		if child is NPC3D:
			var npc := child as NPC3D
			# Approximate NPC as sphere at chest height
			var center := npc.global_position + Vector3(0, 0.85 * npc.body_scale, 0)
			var radius := 0.6 * npc.body_scale
			var oc := from - center
			var b := oc.dot(dir)
			var c := oc.dot(oc) - radius * radius
			var h := b * b - c
			if h > 0.0:
				var t := -b - sqrt(h)
				if t < closest_dist and t > 0.0:
					closest_dist = t
					closest_npc = npc
	if closest_npc != _hovered_npc:
		if _hovered_npc:
			_hovered_npc.hovered = false
		_hovered_npc = closest_npc
		if _hovered_npc:
			_hovered_npc.hovered = true
			# Only auto-show panel on hover if nothing selected
			if not _selected_npc:
				_show_npc_info(_hovered_npc)
	elif _selected_npc == null and closest_npc == null:
		_hide_npc_info()


func _show_npc_info(npc: NPC3D) -> void:
	info_name.text = npc.npc_name
	var g_text := "Nữ" if npc.gender == "female" else "Nam"
	info_details.text = "Tuổi: %d • %s" % [npc.age, g_text]
	info_job.text = "Nghề: %s" % JobSystem.job_name(npc.job)
	_swap_portrait(npc)
	info_panel.visible = true


func _hide_npc_info() -> void:
	info_panel.visible = false
	_clear_portrait()


func _swap_portrait(npc: NPC3D) -> void:
	# Nếu đã là cùng NPC thì skip
	if _portrait_npc and _portrait_npc.npc_name == npc.npc_name \
			and _portrait_npc.age == npc.age and _portrait_npc.gender == npc.gender:
		return
	_clear_portrait()
	# Spawn clone với identity của NPC gốc
	var clone := npc_scene.instantiate() as NPC3D
	clone.preview = true
	clone.npc_name = npc.npc_name
	clone.age = npc.age
	clone.gender = npc.gender
	portrait_vp.add_child(clone)
	clone.global_position = Vector3.ZERO
	# Camera nhìn thẳng mặt: NPC forward là +Z, camera ở +Z nhìn về -Z
	portrait_cam.global_position = Vector3(0, 1.0, 4.7)
	portrait_cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	_portrait_npc = clone


func _clear_portrait() -> void:
	if _portrait_npc:
		_portrait_npc.queue_free()
		_portrait_npc = null


func _unhandled_input(event: InputEvent) -> void:
	# Build mode: click để đặt công trình
	if PlacementSystem.is_active():
		if PlacementSystem.just_started:
			# Bỏ qua click đầu tiên — chỉ reset flag, không đặt building
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				PlacementSystem.just_started = false
				return
			# Chuột di chuyển → cũng reset flag
			if event is InputEventMouseMotion:
				PlacementSystem.just_started = false
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var bld := PlacementSystem.confirm_place()
			if bld:
				print("[Build] Placed %s at %s" % [bld.get_type_name(), bld.global_position])
				# Auto-assign NPC vào building mới
				_auto_assign_workers()
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_cancel_build()
		# R → xoay ghost 90 độ
		if event is InputEventKey and event.pressed and event.keycode == KEY_R:
			PlacementSystem.rotate_ghost()
		return

	# Click to select NPC (left button)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _hovered_npc:
			# Deselect previous NPC
			if _selected_npc:
				_selected_npc.selected = false
			# Deselect previous building
			if _selected_building:
				_selected_building = null
				bld_info_panel.visible = false
			_selected_npc = _hovered_npc
			_selected_npc.selected = true
			_show_npc_info(_selected_npc)
		else:
			# Click building?
			var clicked_bld := _pick_building()
			if clicked_bld:
				if _selected_npc:
					_selected_npc.selected = false
					_selected_npc = null
					_hide_npc_info()
				_selected_building = clicked_bld
				_show_building_info(clicked_bld)
			else:
				# Click empty space → deselect all
				if _selected_npc:
					_selected_npc.selected = false
					_selected_npc = null
				if _selected_building:
					_selected_building = null
				_hide_npc_info()
				bld_info_panel.visible = false

	# B → toggle build toolbar
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		build_toolbar.visible = not build_toolbar.visible
		if not build_toolbar.visible:
			_cancel_build()

	# A → auto-assign (debug/test)
	if event is InputEventKey and event.pressed and event.keycode == KEY_A:
		_auto_assign_workers()

	# Scroll wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - ZOOM_SPEED, ZOOM_MIN, ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + ZOOM_SPEED, ZOOM_MIN, ZOOM_MAX)
		# Middle mouse drag — bắt đầu/kết thúc drag
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_dragging = true
				_drag_last_pos = get_viewport().get_mouse_position()
			else:
				_dragging = false

	# ESC → quay lại main menu (hoặc hủy build mode)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_save_and_quit_to_menu()

	# F5 → quick save
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		_save_current_game()


# --- Build mode ---

func _start_build(type: int) -> void:
	var water_areas: Array = world_gen.get_water_areas() if world_gen else []
	PlacementSystem.start_build(self, camera, type, water_areas, _buildings, _on_building_placed)


func _cancel_build() -> void:
	PlacementSystem.cancel()


func _on_building_placed(bld: Building3D) -> void:
	# Called after a building is placed
	pass


func _auto_assign_workers() -> void:
	var npcs: Array = []
	for child in get_children():
		if child is NPC3D:
			npcs.append(child)
	JobSystem.auto_assign(npcs, _buildings)
	# Trigger NPC đi làm
	for child in get_children():
		var npc := child as NPC3D
		if npc and npc.workplace and npc._commute_state == 0:
			npc.go_to_work()
	if _selected_building:
		_show_building_info(_selected_building)


func _pick_building() -> Building3D:
	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	var closest: Building3D = null
	var closest_dist: float = INF
	for bld in _buildings:
		var b := bld as Building3D
		if not b:
			continue
		# Check ray vs box at building pos (approx 3x3 area)
		var center := b.global_position + Vector3(0, 1.0, 0)
		var oc := from - center
		var bb := oc.dot(dir)
		var cc := oc.dot(oc) - 4.0  # radius ~2
		var h := bb * bb - cc
		if h > 0.0:
			var t := -bb - sqrt(h)
			if t > 0.0 and t < closest_dist:
				closest_dist = t
				closest = b
	return closest


func _show_building_info(bld: Building3D) -> void:
	bld_name_label.text = bld.get_type_name()
	bld_slots_label.text = "Thợ: %d/%d" % [bld.workers.size(), bld.job_slots]
	var names := bld.workers.map(func(w): return w.npc_name)
	bld_workers_label.text = "Danh sách thợ:\n" + "\n".join(names) if names.size() > 0 else "Chưa có thợ"
	bld_info_panel.visible = true
	_hide_npc_info()


func _save_current_game() -> void:
	var npc_data: Array = []
	for child in get_children():
		if child is NPC3D:
			var npc := child as NPC3D
			npc_data.append({
				"name": npc.npc_name,
				"age": npc.age,
				"gender": npc.gender,
				"pos_x": npc.global_position.x,
				"pos_z": npc.global_position.z,
				"job": npc.job,
			})
	var building_data: Array = []
	for bld in _buildings:
		var b := bld as Building3D
		if b:
			building_data.append(b.to_dict())
	var ok := SaveSystem.save_game(world_name, world_size, npc_data, building_data)
	if ok:
		print("[Save] Saved world '%s' (%d NPCs, %d buildings)" % [world_name, npc_data.size(), building_data.size()])
	else:
		push_error("[Save] Failed to save world '%s'" % world_name)


func _save_and_quit_to_menu() -> void:
	_save_current_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")