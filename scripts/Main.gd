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

# Build mode UI (built in code)
var _fab: Button
var _build_grid: Control
var _tooltip: Label
var _build_cells: Array = []  # Array of Panel cells

# Building definitions: type, name, price, job_slots
const BUILD_DEFS: Array = [
	{type = 0, name = "Xưởng gỗ", price = 100, jobs = 2},   # SAWMILL
	{type = 1, name = "Nhà thờ", price = 200, jobs = 1},     # CHURCH
	{type = 2, name = "Bệnh viện", price = 300, jobs = 3},   # HOSPITAL
	{type = 3, name = "Trường học", price = 150, jobs = 2},  # SCHOOL
	{type = 4, name = "Nhà ở", price = 80, jobs = 0},        # HOUSE
	{type = 5, name = "Đường", price = 10, jobs = 0},        # ROAD
]

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

	# Build mode UI — built in code
	_build_build_ui()


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
		# Road drag: update preview mỗi frame
		if PlacementSystem.is_road_dragging():
			PlacementSystem.update_road_drag(get_viewport().get_mouse_position())


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
		# Bỏ qua click đầu tiên sau khi chọn building (tránh đặt ngay lập tức)
		if PlacementSystem.just_started:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				PlacementSystem.just_started = false
				return
			if event is InputEventMouseMotion:
				PlacementSystem.just_started = false
				return
		# Road drag-build
		if _build_type_is_road():
			if PlacementSystem.is_road_dragging():
				# Đang drag → thả chuột đặt road, motion update preview
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
					var count := PlacementSystem.finish_road_drag(get_viewport().get_mouse_position())
					if count > 0:
						print("[Build] Placed %d road tiles" % count)
					return
				if event is InputEventMouseMotion:
					PlacementSystem.update_road_drag(get_viewport().get_mouse_position())
					return
				if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
					PlacementSystem.cancel_road_drag()
					_cancel_build()
					return
			else:
				# Chưa drag → nhấn chuột trái bắt đầu drag
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					PlacementSystem.start_road_drag(get_viewport().get_mouse_position())
					return
				if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
					PlacementSystem.cancel_road_drag()
					_cancel_build()
					return
			return
		# Building thường (không phải road): click để đặt 1 công trình
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var bld := PlacementSystem.confirm_place()
			if bld:
				print("[Build] Placed %s at %s" % [bld.get_type_name(), bld.global_position])
				_auto_assign_workers()
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			PlacementSystem.cancel_road_drag()
			_cancel_build()
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

	# B → toggle build grid
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		_toggle_build_grid()

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


# --- Build mode UI ---

const CELL_SIZE_UI := 90
const GRID_COLS := 3
const GRID_ROWS := 2
const GRID_GAP := 8

func _build_build_ui() -> void:
	var screen := get_viewport().get_visible_rect().size
	var canvas := $CanvasLayer

	# FAB (floating action button) — góc dưới phải
	_fab = Button.new()
	_fab.text = "✚ Build"
	_fab.add_theme_font_size_override("font_size", 18)
	var fab_w := 100
	var fab_h := 44
	_fab.size = Vector2(fab_w, fab_h)
	_fab.position = Vector2(screen.x - fab_w - 20, screen.y - fab_h - 20)
	var fab_normal := StyleBoxFlat.new()
	fab_normal.bg_color = Color(0.2, 0.5, 0.35, 0.95)
	fab_normal.corner_radius_top_left = 22
	fab_normal.corner_radius_top_right = 22
	fab_normal.corner_radius_bottom_left = 22
	fab_normal.corner_radius_bottom_right = 22
	var fab_hover := StyleBoxFlat.new()
	fab_hover.bg_color = Color(0.25, 0.6, 0.4, 1.0)
	fab_hover.corner_radius_top_left = 22
	fab_hover.corner_radius_top_right = 22
	fab_hover.corner_radius_bottom_left = 22
	fab_hover.corner_radius_bottom_right = 22
	_fab.add_theme_stylebox_override("normal", fab_normal)
	_fab.add_theme_stylebox_override("hover", fab_hover)
	_fab.add_theme_stylebox_override("pressed", fab_hover)
	_fab.pressed.connect(_toggle_build_grid)
	canvas.add_child(_fab)

	# Build grid container
	var grid_w := GRID_COLS * CELL_SIZE_UI + (GRID_COLS - 1) * GRID_GAP + 16
	var grid_h := GRID_ROWS * CELL_SIZE_UI + (GRID_ROWS - 1) * GRID_GAP + 16
	_build_grid = Control.new()
	_build_grid.size = Vector2(grid_w, grid_h)
	_build_grid.position = Vector2(screen.x - grid_w - 20, screen.y - grid_h - 20 - fab_h - 10)
	_build_grid.visible = false
	canvas.add_child(_build_grid)

	# Grid background
	var grid_bg := Panel.new()
	grid_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.15, 0.22, 0.95)
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.35, 0.45, 0.6, 0.8)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.content_margin_left = 8.0
	bg_style.content_margin_top = 8.0
	bg_style.content_margin_right = 8.0
	bg_style.content_margin_bottom = 8.0
	grid_bg.add_theme_stylebox_override("panel", bg_style)
	_build_grid.add_child(grid_bg)

	# Tooltip (hidden by default)
	_tooltip = Label.new()
	_tooltip.add_theme_font_size_override("font_size", 14)
	_tooltip.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_tooltip.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_tooltip.add_theme_constant_override("shadow_offset_x", 1)
	_tooltip.add_theme_constant_override("shadow_offset_y", 1)
	_tooltip.visible = false
	_tooltip.z_index = 100
	canvas.add_child(_tooltip)

	# Build cells
	_build_cells.clear()
	for i in BUILD_DEFS.size():
		var def: Dictionary = BUILD_DEFS[i]
		var col := i % GRID_COLS
		var row := i / GRID_COLS
		var cell := _make_build_cell(def, col, row)
		_build_grid.add_child(cell)
		_build_cells.append(cell)


func _make_build_cell(def: Dictionary, col: int, row: int) -> Control:
	var cell := Panel.new()
	var cx := 8 + col * (CELL_SIZE_UI + GRID_GAP)
	var cy := 8 + row * (CELL_SIZE_UI + GRID_GAP)
	cell.position = Vector2(cx, cy)
	cell.size = Vector2(CELL_SIZE_UI, CELL_SIZE_UI)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.22, 0.30, 0.9)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.35, 0.45, 0.6, 0.5)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	cell.add_theme_stylebox_override("panel", style)

	# Thumbnail SubViewport
	var vp := SubViewport.new()
	vp.size = Vector2i(CELL_SIZE_UI - 8, CELL_SIZE_UI - 8)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	cell.add_child(vp)

	# Camera nhìn building
	var cam := Camera3D.new()
	var cam_basis := Basis(Vector3(0.7071, 0, 0.7071), Vector3(0, 1, 0), Vector3(-0.7071, 0, 0.7071))
	cam.transform = Transform3D(cam_basis, Vector3(6.0, 5.0, 6.0))
	cam.fov = 35.0
	vp.add_child(cam)

	# WorldEnvironment — ambient light ấm, flat kiểu 2D Ghibli
	var env_res := Environment.new()
	env_res.ambient_light_color = Color(0.7, 0.75, 0.65, 1)
	env_res.ambient_light_energy = 1.0
	env_res.background_mode = Environment.BG_COLOR
	env_res.background_color = Color(0.82, 0.88, 0.78, 1)
	var we := WorldEnvironment.new()
	we.environment = env_res
	vp.add_child(we)

	# Building instance (no label)
	var bld := Building3D.new()
	bld.building_type = int(def.type) as Building3D.Type
	bld.show_label = false
	vp.add_child(bld)

	# Price label ở góc dưới phải
	var price_lbl := Label.new()
	price_lbl.text = str(def.price)
	price_lbl.add_theme_font_size_override("font_size", 13)
	price_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	price_lbl.size = Vector2(CELL_SIZE_UI - 4, 16)
	price_lbl.position = Vector2(2, CELL_SIZE_UI - 18)
	cell.add_child(price_lbl)

	# Hover + click handling
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	var def_name: String = def.name
	var btype: int = int(def.type)
	cell.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_on_cell_clicked(btype)
	)
	cell.mouse_entered.connect(func():
		_on_cell_hover(def_name, cell)
	)
	cell.mouse_exited.connect(func():
		_tooltip.visible = false
	)

	return cell


func _on_cell_hover(label_text: String, cell: Control) -> void:
	_tooltip.text = label_text
	_tooltip.size = Vector2(100, 20)
	var gp := cell.global_position
	_tooltip.position = Vector2(gp.x, gp.y - 22)
	_tooltip.visible = true
	_tooltip.z_index = 100


func _on_cell_clicked(btype: int) -> void:
	_start_build(btype)


func _toggle_build_grid() -> void:
	_build_grid.visible = not _build_grid.visible
	if not _build_grid.visible:
		_cancel_build()
		_tooltip.visible = false


# --- Build mode ---

func _build_type_is_road() -> bool:
	# PlacementSystem._build_type là static var — check type road
	return PlacementSystem._build_type == Building3D.Type.ROAD

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