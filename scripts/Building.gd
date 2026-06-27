extends Node3D
class_name Building3D

## Công trình: có job slot cho NPC, mesh procedural chi tiết theo loại
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
# MESH BUILDING — chi tiết cho từng loại công trình
# ============================================================

func _build_mesh() -> void:
	match building_type:
		Type.SAWMILL:
			_build_sawmill()
		Type.CHURCH:
			_build_church()
		Type.HOSPITAL:
			_build_hospital()
		Type.SCHOOL:
			_build_school()
		Type.HOUSE:
			_build_house()


# --- Helper: tạo box mesh instance ---
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


# --- Helper: tạo material ---
func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


# --- Helper: thân nhà cơ bản (tường + mái + cửa + sổ) ---
func _build_shell(w: float, h: float, d: float, wall_mat: Material, roof_mat: Material, door_mat: Material, has_windows: bool = true) -> void:
	# Tường chính — tâm ở h/2 để đáy chạm y=0
	_add_box(Vector3(w, h, d), Vector3(0, h * 0.5, 0), wall_mat)
	# Mái
	var roof_h := 0.7
	_add_box(Vector3(w + 0.4, roof_h, d + 0.4), Vector3(0, h + roof_h * 0.5, 0), roof_mat)
	# Cửa chính — đáy ở y=0, tâm y=0.75
	_add_box(Vector3(1.0, 1.5, 0.12), Vector3(0, 0.75, d * 0.5 + 0.01), door_mat)
	# Sổ cửa 2 bên
	if has_windows:
		var glass_mat := _mat(Color(0.5, 0.7, 0.85, 0.7), 0.1)
		glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_add_box(Vector3(0.6, 0.5, 0.08), Vector3(w * 0.3, 1.1, d * 0.5 + 0.01), glass_mat)
		_add_box(Vector3(0.6, 0.5, 0.08), Vector3(-w * 0.3, 1.1, d * 0.5 + 0.01), glass_mat)


# ============================================================
# XƯỞNG GỖ — thân gỗ, mái nâu, ống khói, gỗ chất bên cạnh
# ============================================================
func _build_sawmill() -> void:
	var wall_mat := _mat(Color(0.55, 0.42, 0.28))
	var roof_mat := _mat(Color(0.38, 0.22, 0.12))
	var door_mat := _mat(Color(0.25, 0.15, 0.08))
	_build_shell(3.5, 2.2, 3.0, wall_mat, roof_mat, door_mat)
	# Ống khói — đáy ở 2.2, tâm = 2.2 + 0.7 = 2.9
	_add_box(Vector3(0.4, 1.4, 0.4), Vector3(1.2, 2.9, -0.5), _mat(Color(0.25, 0.2, 0.15)))
	# Khúc gỗ chất bên hông — mỗi khúc dày 0.25, tâm = đáy + 0.125
	var log_mat := _mat(Color(0.45, 0.3, 0.15), 0.95)
	for i in 3:
		var z_off := -1.0 + i * 0.5
		_add_box(Vector3(1.2, 0.25, 0.25), Vector3(-2.0, 0.125 + i * 0.25, z_off), log_mat)
	# Bàn gỗ phía trước — mặt bàn ở 0.7, dày 0.1, tâm = 0.7 - 0.05 = 0.65
	_add_box(Vector3(1.0, 0.1, 0.5), Vector3(0, 0.65, 2.2), _mat(Color(0.4, 0.25, 0.12)))


# ============================================================
# NHÀ THỜ — tường trắng/cream, tháp chuông cao, thập tự trên đỉnh
# ============================================================
func _build_church() -> void:
	var wall_mat := _mat(Color(0.85, 0.82, 0.72))
	var roof_mat := _mat(Color(0.35, 0.12, 0.08))
	var door_mat := _mat(Color(0.2, 0.1, 0.05))
	# Thân nhà thờ — dài hơn
	_build_shell(3.0, 2.8, 4.5, wall_mat, roof_mat, door_mat, false)
	# Cửa vòm (đắp nổi trên cửa) — tâm ở 1.6
	_add_box(Vector3(1.2, 0.3, 0.1), Vector3(0, 1.6, 2.26), wall_mat)
	# Tháp chuông phía trước — cao 4.5, đáy 0, tâm 2.25
	var tower_mat := _mat(Color(0.82, 0.78, 0.68))
	_add_box(Vector3(1.5, 4.5, 1.5), Vector3(0, 2.25, 2.5), tower_mat)
	# Mái tháp nhọn — cao 1.2, đáy 4.5, tâm 5.1
	_add_box(Vector3(1.8, 1.2, 1.8), Vector3(0, 5.1, 2.5), roof_mat)
	# Thập tự trên đỉnh tháp — chân ở 5.7
	var cross_mat := _mat(Color(0.85, 0.75, 0.2), 0.4)
	_add_box(Vector3(0.08, 0.6, 0.08), Vector3(0, 6.0, 2.5), cross_mat)
	_add_box(Vector3(0.3, 0.08, 0.08), Vector3(0, 5.9, 2.5), cross_mat)
	# Chuông — tâm ở 3.5 trong tháp
	var bell_mat := _mat(Color(0.6, 0.45, 0.1), 0.5)
	_add_box(Vector3(0.5, 0.5, 0.5), Vector3(0, 3.5, 2.5), bell_mat)
	# Cửa sổ kính màu 2 bên hông — tâm 1.5
	var glass_mat := _mat(Color(0.3, 0.2, 0.5, 0.6), 0.1)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 3:
		var z_off := -1.5 + i * 1.5
		_add_box(Vector3(0.08, 1.2, 0.4), Vector3(1.55, 1.5, z_off), glass_mat)
		_add_box(Vector3(0.08, 1.2, 0.4), Vector3(-1.55, 1.5, z_off), glass_mat)


# ============================================================
# BỆNH VIỆN — tường trắng, dấu thập đỏ lớn trên mái, cửa kính
# ============================================================
func _build_hospital() -> void:
	var wall_mat := _mat(Color(0.92, 0.92, 0.95))
	var roof_mat := _mat(Color(0.7, 0.72, 0.78))
	var door_mat := _mat(Color(0.3, 0.4, 0.5, 0.8))
	door_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_build_shell(4.0, 2.5, 3.5, wall_mat, roof_mat, door_mat)
	# Dấu thập đỏ trên mái — chân ở 2.85 (đỉnh mái)
	var red_mat := _mat(Color(0.85, 0.1, 0.1), 0.3)
	_add_box(Vector3(0.15, 0.6, 0.15), Vector3(0, 3.15, 0), red_mat)
	_add_box(Vector3(0.5, 0.15, 0.15), Vector3(0, 2.95, 0), red_mat)
	# Dấu thập đỏ trên tường phía trước — tâm 1.8
	_add_box(Vector3(0.1, 0.5, 0.08), Vector3(2.0, 1.8, 1.76), red_mat)
	_add_box(Vector3(0.35, 0.1, 0.08), Vector3(2.0, 1.8, 1.76), red_mat)
	# Bảng hiệu "bệnh viện" — tâm 2.2
	_add_box(Vector3(2.0, 0.4, 0.1), Vector3(0, 2.2, 1.77), _mat(Color(0.2, 0.25, 0.3)))
	# Cột đèn 2 bên cửa — cao 1.5, đáy 0, tâm 0.75
	_add_box(Vector3(0.12, 1.5, 0.12), Vector3(1.5, 0.75, 2.0), _mat(Color(0.3, 0.3, 0.3)))
	# Đèn — tâm 1.6
	var lamp_mat := _mat(Color(1.0, 0.95, 0.5), 0.2)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.9, 0.5)
	lamp_mat.emission_energy_multiplier = 0.8
	_add_box(Vector3(0.2, 0.2, 0.2), Vector3(1.5, 1.6, 2.0), lamp_mat)
	_add_box(Vector3(0.12, 1.5, 0.12), Vector3(-1.5, 0.75, 2.0), _mat(Color(0.3, 0.3, 0.3)))
	_add_box(Vector3(0.2, 0.2, 0.2), Vector3(-1.5, 1.6, 2.0), lamp_mat)


# ============================================================
# TRƯỜNG HỌC — tường vàng ấm, tháp chuông nhỏ, bảng đen, cờ
# ============================================================
func _build_school() -> void:
	var wall_mat := _mat(Color(0.75, 0.6, 0.3))
	var roof_mat := _mat(Color(0.4, 0.2, 0.1))
	var door_mat := _mat(Color(0.3, 0.18, 0.1))
	_build_shell(3.5, 2.5, 3.5, wall_mat, roof_mat, door_mat)
	# Tháp chuông nhỏ trên mái — cao 1.0, đáy 2.85, tâm 3.35
	_add_box(Vector3(0.8, 1.0, 0.8), Vector3(0, 3.35, 0), _mat(Color(0.7, 0.55, 0.25)))
	# Mái tháp — cao 0.4, đáy 3.85, tâm 4.05
	_add_box(Vector3(1.0, 0.4, 1.0), Vector3(0, 4.05, 0), roof_mat)
	# Chuông — tâm 3.5
	_add_box(Vector3(0.3, 0.3, 0.3), Vector3(0, 3.5, 0), _mat(Color(0.6, 0.45, 0.1), 0.5))
	# Cột cờ trước trường — cao 3.5, đáy 0, tâm 1.75
	_add_box(Vector3(0.08, 3.5, 0.08), Vector3(2.2, 1.75, 2.0), _mat(Color(0.3, 0.3, 0.3)))
	# Cờ — box đỏ nhỏ trên đỉnh cột, tâm 3.2
	_add_box(Vector3(0.5, 0.3, 0.02), Vector3(2.45, 3.2, 2.0), _mat(Color(0.8, 0.15, 0.15)))
	# Bảng đen phía trước — tâm 1.5
	_add_box(Vector3(1.2, 0.7, 0.08), Vector3(0, 1.5, 1.77), _mat(Color(0.1, 0.1, 0.12), 0.3))
	# Khung bảng — tâm 1.5
	_add_box(Vector3(1.4, 0.9, 0.06), Vector3(0, 1.5, 1.76), _mat(Color(0.3, 0.18, 0.1)))


# ============================================================
# NHÀ Ở — nhỏ gọn, mái đỏ, ống khói, cửa sổ ấm cúng
# ============================================================
func _build_house() -> void:
	var wall_mat := _mat(Color(0.7, 0.55, 0.4))
	var roof_mat := _mat(Color(0.55, 0.2, 0.15))
	var door_mat := _mat(Color(0.25, 0.15, 0.08))
	_build_shell(3.0, 2.0, 3.0, wall_mat, roof_mat, door_mat)
	# Ống khói — cao 1.0, đáy 2.0, tâm 2.5
	_add_box(Vector3(0.3, 1.0, 0.3), Vector3(0.9, 2.5, -0.5), _mat(Color(0.3, 0.25, 0.2)))
	# Bậc cửa — dày 0.1, tâm 0.05
	_add_box(Vector3(1.2, 0.1, 0.3), Vector3(0, 0.05, 1.65), _mat(Color(0.4, 0.3, 0.2)))
	# Hàng rào nhỏ — cao 0.5, tâm 0.25
	var fence_mat := _mat(Color(0.5, 0.38, 0.22))
	for i in 4:
		var x := -1.5 + i * 1.0
		_add_box(Vector3(0.08, 0.5, 0.08), Vector3(x, 0.25, 2.3), fence_mat)
	# Thanh ngang hàng rào — dày 0.05, tâm 0.35
	_add_box(Vector3(3.0, 0.05, 0.05), Vector3(0, 0.35, 2.3), fence_mat)


# ============================================================
# LABEL
# ============================================================

func _add_label() -> void:
	if building_type == Type.HOUSE:
		return  # nhà ở không cần label
	_label = Label3D.new()
	_label.text = _type_name() + " 0/%d" % job_slots
	_label.font_size = 36
	_label.outline_size = 8
	_label.outline_modulate = Color(0, 0, 0, 0.85)
	_label.modulate = Color(1.0, 0.95, 0.7)
	_label.pixel_size = 0.012
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	# Vị trí label theo chiều cao tòa nhà
	var label_y := 3.5
	match building_type:
		Type.CHURCH: label_y = 6.8
		Type.HOSPITAL: label_y = 3.8
		Type.SCHOOL: label_y = 4.5
		Type.SAWMILL: label_y = 3.5
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