extends Node3D
class_name Building3D

## Công trình phong cách Ghibli — base class với helpers dùng chung
## Mỗi loại công trình có builder riêng trong scripts/building/
## Đặt bởi PlacementSystem (grid snap), lưu trong Main._buildings

enum Type { SAWMILL, CHURCH, HOSPITAL, SCHOOL, HOUSE }

@export var building_type: Type = Type.SAWMILL
@export var job_slots: int = 2

# NPC đang làm việc ở đây
var workers: Array[NPC3D] = []

# Vị trí "cửa ra vào" — NPC đi đến đây rồi đi vào làm việc
var entrance_offset: Vector3 = Vector3(0, 0, 2.0)

# Kích thước footprint trên grid (số cell)
var grid_w: int = 2
var grid_h: int = 2

var _meshes: Array[MeshInstance3D] = []
var _label: Label3D = null

# --- Bảng màu dùng chung (Ghibli warm) ---
const STONE_COL := Color(0.55, 0.50, 0.45)
const WOOD_DARK := Color(0.35, 0.24, 0.15)
const GLASS_WARM := Color(0.6, 0.75, 0.55, 0.55)
const FOUND_H := 0.3  # chiều cao foundation


func _ready() -> void:
	_build_mesh()
	_add_label()


## Trả về vị trí cửa (world pos) để NPC đi đến
func get_entrance() -> Vector3:
	return global_position + entrance_offset


## Số việc trống
func get_open_slots() -> int:
	return job_slots - workers.size()


## Thêm worker, trả về true nếu có chỗ
func assign_worker(npc: NPC3D) -> bool:
	if workers.size() >= job_slots:
		return false
	if npc in workers:
		return false
	workers.append(npc)
	npc.job = _type_to_job(building_type)
	npc.workplace = self
	_update_label()
	return true


## Gỡ worker
func remove_worker(npc: NPC3D) -> void:
	workers.erase(npc)
	if npc.workplace == self:
		npc.workplace = null
	if npc.job == _type_to_job(building_type):
		npc.job = NPC3D.JobType.NONE
	_update_label()


static func _type_to_job(t: Type) -> int:
	match t:
		Type.SAWMILL: return NPC3D.JobType.LUMBERJACK
		Type.CHURCH: return NPC3D.JobType.PRIEST
		Type.HOSPITAL: return NPC3D.JobType.DOCTOR
		Type.SCHOOL: return NPC3D.JobType.TEACHER
		_: return NPC3D.JobType.NONE


# ============================================================
# MESH DISPATCH — ủy thác cho builder riêng từng loại
# ============================================================

func _build_mesh() -> void:
	match building_type:
		Type.SAWMILL:
			SawmillBuilder.build(self)
		Type.CHURCH:
			ChurchBuilder.build(self)
		Type.HOSPITAL:
			HospitalBuilder.build(self)
		Type.SCHOOL:
			SchoolBuilder.build(self)
		Type.HOUSE:
			HouseBuilder.build(self)


# ============================================================
# HELPERS — dùng chung cho tất cả builder
# ============================================================

func _add_box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
	_meshes.append(mi)
	return mi


func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


func _emat(color: Color, energy: float = 0.8, rough: float = 0.4) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


func _add_gable_roof(w: float, base_h: float, d: float, mat: Material, overhang: float, roof_h: float) -> void:
	var half_w := w / 2.0 + overhang
	var slope_len := sqrt(half_w * half_w + roof_h * roof_h)
	var slope_angle := atan2(roof_h, half_w)
	var roof_thickness := 0.12
	var roof_depth := d + overhang * 2.0

	var left := _add_box(Vector3(slope_len, roof_thickness, roof_depth),
			Vector3(-w / 4.0 - overhang / 2.0, base_h + roof_h / 2.0, 0), mat)
	left.rotation.z = slope_angle

	var right := _add_box(Vector3(slope_len, roof_thickness, roof_depth),
			Vector3(w / 4.0 + overhang / 2.0, base_h + roof_h / 2.0, 0), mat)
	right.rotation.z = -slope_angle

	_add_box(Vector3(0.15, 0.1, roof_depth), Vector3(0, base_h + roof_h, 0), mat)


func _add_foundation(w: float, d: float, mat: Material) -> void:
	_add_box(Vector3(w + 0.2, FOUND_H, d + 0.2), Vector3(0, FOUND_H / 2.0, 0), mat)


func _add_window(center_x: float, center_y: float, face_z: float, w: float, h: float,
		frame_mat: Material, glass_mat: Material) -> void:
	var ft := 0.06
	_add_box(Vector3(w + ft * 2, ft, 0.05), Vector3(center_x, center_y + h / 2.0 + ft / 2.0, face_z), frame_mat)
	_add_box(Vector3(w + ft * 2, ft, 0.05), Vector3(center_x, center_y - h / 2.0 - ft / 2.0, face_z), frame_mat)
	_add_box(Vector3(ft, h, 0.05), Vector3(center_x - w / 2.0 - ft / 2.0, center_y, face_z), frame_mat)
	_add_box(Vector3(ft, h, 0.05), Vector3(center_x + w / 2.0 + ft / 2.0, center_y, face_z), frame_mat)
	_add_box(Vector3(w, h, 0.04), Vector3(center_x, center_y, face_z - 0.01), glass_mat)
	_add_box(Vector3(w, 0.03, 0.05), Vector3(center_x, center_y, face_z), frame_mat)


func _add_lantern(pos: Vector3) -> void:
	_add_box(Vector3(0.06, 0.3, 0.06), Vector3(pos.x, pos.y - 0.2, pos.z), _mat(WOOD_DARK))
	_add_box(Vector3(0.2, 0.25, 0.2), pos, _emat(Color(1.0, 0.82, 0.45), 0.7))


func _add_bush(pos: Vector3, scale: float, color: Color) -> void:
	var mat := _mat(color, 0.95)
	_add_box(Vector3(0.5 * scale, 0.4 * scale, 0.5 * scale), pos, mat)
	_add_box(Vector3(0.35 * scale, 0.3 * scale, 0.35 * scale),
			pos + Vector3(0.2 * scale, 0.15 * scale, 0), mat)
	_add_box(Vector3(0.3 * scale, 0.25 * scale, 0.3 * scale),
			pos + Vector3(-0.15 * scale, 0.1 * scale, 0.15 * scale), mat)


func _add_path_stones(start: Vector3, end: Vector3, count: int) -> void:
	var mat := _mat(Color(0.52, 0.48, 0.43), 0.95)
	for i in count:
		var t := (i + 0.5) / float(count)
		var pos := start.lerp(end, t)
		pos.x += randf_range(-0.15, 0.15)
		var s := randf_range(0.25, 0.4)
		_add_box(Vector3(s, 0.06, s), pos, mat)


func _build_shell(w: float, h: float, d: float, wall_mat: Material, roof_mat: Material,
		door_mat: Material, foundation_mat: Material, has_windows: bool = true,
		roof_h: float = 1.0, overhang: float = 0.4) -> void:
	_add_foundation(w, d, foundation_mat)
	_add_box(Vector3(w, h, d), Vector3(0, FOUND_H + h / 2.0, 0), wall_mat)
	_add_gable_roof(w, FOUND_H + h, d, roof_mat, overhang, roof_h)

	# Cửa chính — ở mặt +Z
	var door_h := 1.5
	var door_w := 0.9
	var door_z := d / 2.0 + 0.02
	var ft := 0.08
	_add_box(Vector3(door_w + ft, ft, 0.06), Vector3(0, FOUND_H + door_h + ft / 2.0, door_z), _mat(WOOD_DARK))
	_add_box(Vector3(ft, door_h, 0.06), Vector3(-door_w / 2.0 - ft / 2.0, FOUND_H + door_h / 2.0, door_z), _mat(WOOD_DARK))
	_add_box(Vector3(ft, door_h, 0.06), Vector3(door_w / 2.0 + ft / 2.0, FOUND_H + door_h / 2.0, door_z), _mat(WOOD_DARK))
	_add_box(Vector3(door_w, door_h, 0.08), Vector3(0, FOUND_H + door_h / 2.0, door_z), door_mat)
	_add_box(Vector3(0.05, 0.15, 0.04),
			Vector3(door_w / 2.0 - 0.12, FOUND_H + door_h / 2.0, door_z + 0.02),
			_mat(Color(0.7, 0.6, 0.3), 0.3))

	if has_windows:
		var glass_mat := _mat(GLASS_WARM, 0.1)
		glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var win_y := FOUND_H + 1.1
		_add_window(w * 0.28, win_y, d / 2.0 + 0.02, 0.55, 0.55, _mat(WOOD_DARK), glass_mat)
		_add_window(-w * 0.28, win_y, d / 2.0 + 0.02, 0.55, 0.55, _mat(WOOD_DARK), glass_mat)


# ============================================================
# LABEL
# ============================================================

func _add_label() -> void:
	if building_type == Type.HOUSE:
		return
	_label = Label3D.new()
	_label.text = _type_name() + " 0/%d" % job_slots
	_label.font_size = 36
	_label.outline_size = 8
	_label.outline_modulate = Color(0, 0, 0, 0.85)
	_label.modulate = Color(1.0, 0.95, 0.7)
	_label.pixel_size = 0.012
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	var label_y := 4.0
	match building_type:
		Type.CHURCH: label_y = 7.0
		Type.HOSPITAL: label_y = 4.3
		Type.SCHOOL: label_y = 5.3
		Type.SAWMILL: label_y = 4.0
	_label.position = Vector3(0, label_y, 0)
	add_child(_label)


func _update_label() -> void:
	if _label:
		_label.text = _type_name() + " %d/%d" % [workers.size(), job_slots]


func _type_name() -> String:
	match building_type:
		Type.SAWMILL: return "Xưởng gỗ"
		Type.CHURCH: return "Nhà thờ"
		Type.HOSPITAL: return "Bệnh viện"
		Type.SCHOOL: return "Trường học"
		Type.HOUSE: return "Nhà ở"
		_: return "Công trình"


## Serialize cho save/load
func to_dict() -> Dictionary:
	return {
		"type": building_type,
		"job_slots": job_slots,
		"pos_x": global_position.x,
		"pos_z": global_position.z,
		"rot_y": rotation.y,
		"workers": workers.map(func(w): return w.npc_name),
	}


func get_type_name() -> String:
	return _type_name()