extends Node3D
class_name Building3D

## Công trình: có job slot cho NPC, mesh procedural theo loại
## Đặt bởi PlacementSystem (grid snap), lưu trong Main._buildings

enum Type { SAWMILL, QUARRY, FARM, HOUSE }

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
		Type.QUARRY: return NPC3D.JobType.MASON
		Type.FARM: return NPC3D.JobType.FARMER
		_: return NPC3D.JobType.NONE


func _build_mesh() -> void:
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.6, 0.5, 0.35)
	wall_mat.roughness = 0.9

	var roof_mat := StandardMaterial3D.new()
	roof_mat.roughness = 0.85

	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.35, 0.2, 0.12)
	door_mat.roughness = 0.9

	match building_type:
		Type.SAWMILL:
			roof_mat.albedo_color = Color(0.4, 0.25, 0.15)
			_build_box_building(wall_mat, roof_mat, door_mat, 3.0, 2.2, 3.0)
			# Thêm ống khói
			_add_chimney(wall_mat)
		Type.QUARRY:
			roof_mat.albedo_color = Color(0.45, 0.45, 0.42)
			_build_box_building(wall_mat, roof_mat, door_mat, 3.2, 2.0, 3.2)
		Type.FARM:
			roof_mat.albedo_color = Color(0.35, 0.55, 0.25)
			_build_box_building(wall_mat, roof_mat, door_mat, 4.0, 2.0, 3.0)
			# Thêm hàng rào nhỏ phía trước
			_add_fence()
		Type.HOUSE:
			roof_mat.albedo_color = Color(0.5, 0.3, 0.2)
			_build_box_building(wall_mat, roof_mat, door_mat, 3.0, 2.5, 3.0)


func _build_box_building(wall_mat: Material, roof_mat: Material, door_mat: Material,
		w: float, h: float, d: float) -> void:
	# Tường (4 mặt) — dùng 1 box lớn cho thân
	_add_box(Vector3(w, h, d), Vector3.ZERO, wall_mat)
	# Mái dốc — 2 box nghiêng
	var roof_h := 0.8
	_add_box(Vector3(w + 0.3, roof_h, d + 0.3), Vector3(0, h + roof_h * 0.3, 0), roof_mat)
	# Cửa
	_add_box(Vector3(0.9, 1.4, 0.1), Vector3(0, 0.7, d * 0.5), door_mat)


func _add_chimney(wall_mat: Material) -> void:
	var chim := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 1.2, 0.4)
	chim.mesh = box
	chim.position = Vector3(1.0, 2.8, -0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.25, 0.2)
	mat.roughness = 0.95
	chim.material_override = mat
	add_child(chim)
	_meshes.append(chim)


func _add_fence() -> void:
	var fence_mat := StandardMaterial3D.new()
	fence_mat.albedo_color = Color(0.5, 0.38, 0.22)
	fence_mat.roughness = 0.9
	for i in 5:
		var x := -1.8 + i * 0.9
		_add_box(Vector3(0.08, 0.6, 0.08), Vector3(x, 0.3, 2.5), fence_mat)


func _add_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
	_meshes.append(mi)


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
	_label.position = Vector3(0, 3.5, 0)
	add_child(_label)


func _update_label() -> void:
	if _label:
		_label.text = _type_name() + " %d/%d" % [workers.size(), job_slots]


func _type_name() -> String:
	match building_type:
		Type.SAWMILL: return "Xưởng gỗ"
		Type.QUARRY: return "Mỏ đá"
		Type.FARM: return "Trại nông"
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