extends Node3D

var npc_scene: PackedScene = preload("res://scenes/NPC.tscn")

@onready var camera: Camera3D = $Camera3D
@onready var ground_mesh: MeshInstance3D = $Ground/GroundMesh
@onready var world_gen: WorldGenerator = $WorldGenerator
@onready var env: Environment = $WorldEnvironment.environment
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var info_panel: Panel = $CanvasLayer/InfoPanel
@onready var info_name: Label = $CanvasLayer/InfoPanel/VBox/NameLabel
@onready var info_age: Label = $CanvasLayer/InfoPanel/VBox/AgeLabel
@onready var info_gender: Label = $CanvasLayer/InfoPanel/VBox/GenderLabel
@onready var portrait_vp: SubViewport = $CanvasLayer/InfoPanel/VBox/Portrait/PortraitVP
@onready var portrait_cam: Camera3D = $CanvasLayer/InfoPanel/VBox/Portrait/PortraitVP/Cam

# Hover/selected NPC state
var _hovered_npc: NPC3D = null
var _selected_npc: NPC3D = null
var _portrait_npc: NPC3D = null  # clone currently shown in portrait

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
	else:
		_spawn_npcs()


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
	_update_hover()


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
	info_age.text = "Tuổi: %d" % npc.age
	var g_text := "Nữ" if npc.gender == "female" else "Nam"
	info_gender.text = "Giới tính: %s" % g_text
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
	portrait_cam.global_position = Vector3(0, 1.0, 3.5)
	portrait_cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	_portrait_npc = clone


func _clear_portrait() -> void:
	if _portrait_npc:
		_portrait_npc.queue_free()
		_portrait_npc = null


func _unhandled_input(event: InputEvent) -> void:
	# Click to select NPC (left button)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _hovered_npc:
			# Deselect previous
			if _selected_npc:
				_selected_npc.selected = false
			_selected_npc = _hovered_npc
			_selected_npc.selected = true
			_show_npc_info(_selected_npc)
		else:
			# Click empty space → deselect
			if _selected_npc:
				_selected_npc.selected = false
				_selected_npc = null
			_hide_npc_info()

	# Scroll wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - ZOOM_SPEED, ZOOM_MIN, ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + ZOOM_SPEED, ZOOM_MIN, ZOOM_MAX)

	# ESC → quay lại main menu
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_save_and_quit_to_menu()

	# F5 → quick save
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		_save_current_game()


func _save_current_game() -> void:
	var npc_data: Array = []
	for child in get_children():
		if child is NPC3D:
			npc_data.append({
				"name": child.npc_name,
				"age": child.age,
				"gender": child.gender,
				"pos_x": child.global_position.x,
				"pos_z": child.global_position.z,
			})
	var ok := SaveSystem.save_game(world_name, world_size, npc_data)
	if ok:
		print("[Save] Saved world '%s' (%d NPCs)" % [world_name, npc_data.size()])
	else:
		push_error("[Save] Failed to save world '%s'" % world_name)


func _save_and_quit_to_menu() -> void:
	_save_current_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")