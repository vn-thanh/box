extends CharacterBody3D
class_name NPC3D

@export var world_bounds: float = 35.0

# --- Focus state (set by Main via raycast) ---
var hovered: bool = false:
	set(v):
		if hovered != v:
			hovered = v
			_update_focus_visual()
var selected: bool = false:
	set(v):
		if selected != v:
			selected = v
			_update_focus_visual()

# All mesh instances for outline/emissive toggle
var _meshes: Array[MeshInstance3D] = []

# --- Portrait mode (used by info panel SubViewport) ---
var preview: bool = false

# --- Character identity ---
var npc_name: String = ""
var age: int = 25
var gender: String = "male"
var body_scale: float = 1.0

# --- Humanoid skeleton ---
var skeleton: Node3D
var bone_hips: Node3D
var bone_torso: Node3D
var bone_head: Node3D
var bone_arm_l: Node3D
var bone_arm_r: Node3D
var bone_leg_l: Node3D
var bone_leg_r: Node3D
var _name_label: Label3D

# --- Animation ---
var _walk_phase: float = 0.0
var _walk_amp: float = 0.0
var _is_moving: bool = false
var _face_angle: float = 0.0
var _idle_offset: float = 0.0

# --- Wander AI ---
var _wander_timer: float = 0.0
var _wander_dir: Vector3 = Vector3.ZERO
var _speed: float = 2.0

# --- Name pools ---
const SURNAMES := ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Wilson", "Anderson", "Taylor", "Thomas", "Moore", "Jackson", "Martin", "Lee", "Thompson", "White", "Harris", "Clark", "Lewis", "Walker", "Hall", "Allen", "Young", "King", "Wright", "Hill"]
const MALE_NAMES := ["James", "John", "Robert", "Michael", "William", "David", "Joseph", "Charles", "Thomas", "Daniel", "Matthew", "Andrew", "Christopher", "Anthony", "Mark", "Steven", "Paul", "Andrew", "Joshua", "Kenneth", "Kevin", "Brian", "George", "Edward", "Ronald", "Timothy", "Jason", "Jeffrey", "Ryan"]
const FEMALE_NAMES := ["Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara", "Susan", "Jessica", "Sarah", "Karen", "Lisa", "Nancy", "Betty", "Margaret", "Sandra", "Ashley", "Dorothy", "Kimberly", "Emily", "Donna", "Michelle", "Carol", "Amanda", "Melissa", "Deborah", "Stephanie", "Rebecca", "Laura", "Sharon"]


func _ready() -> void:
	_idle_offset = randf() * TAU
	_generate_identity()
	_build_skeleton()
	_add_name_label()
	if not preview:
		_adjust_collision()
		_pick_new_wander()


func _generate_identity() -> void:
	# Chỉ generate nếu chưa được set (khi load game, identity được set trước add_child)
	if not npc_name.is_empty():
		return
	gender = "male" if randf() < 0.5 else "female"
	age = randi_range(5, 85)
	if gender == "male":
		npc_name = SURNAMES[randi() % SURNAMES.size()] + " " + MALE_NAMES[randi() % MALE_NAMES.size()]
	else:
		npc_name = SURNAMES[randi() % SURNAMES.size()] + " " + FEMALE_NAMES[randi() % FEMALE_NAMES.size()]


func _age_to_scale(age_val: float) -> float:
	if age_val <= 3:
		return lerpf(0.35, 0.45, age_val / 3.0)
	elif age_val <= 12:
		return lerpf(0.45, 0.75, (age_val - 3) / 9.0)
	elif age_val <= 17:
		return lerpf(0.75, 0.98, (age_val - 12) / 5.0)
	elif age_val <= 60:
		return 1.0
	elif age_val <= 80:
		return lerpf(1.0, 0.92, (age_val - 60) / 20.0)
	else:
		return lerpf(0.92, 0.85, clampf((age_val - 80) / 20.0, 0, 1))


func _build_skeleton() -> void:
	skeleton = Node3D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)

	# Age + gender scale
	var gender_scale := 1.0 if gender == "male" else 0.93
	body_scale = _age_to_scale(age) * gender_scale
	skeleton.scale = Vector3.ONE * body_scale

	# Females có vai hẹp hơn
	var shoulder_factor := 1.0 if gender == "male" else 0.88

	# Random palette
	var shirt_colors := [
		Color(0.3, 0.55, 0.7),
		Color(0.7, 0.3, 0.3),
		Color(0.3, 0.6, 0.35),
		Color(0.5, 0.35, 0.6),
		Color(0.8, 0.6, 0.3),
		Color(0.35, 0.35, 0.4),
	]
	# Nữ mặc màu nổi/hồng hơn
	if gender == "female":
		shirt_colors = [
			Color(0.9, 0.4, 0.55),   # hồng
			Color(0.85, 0.5, 0.7),   # hồng đậm
			Color(0.7, 0.4, 0.8),    # tím
			Color(0.5, 0.7, 0.9),    # xanh nhạt
			Color(0.9, 0.7, 0.4),    # vàng đất
			Color(0.6, 0.8, 0.5),    # xanh mint
		]
	var pants_colors := [
		Color(0.2, 0.22, 0.3),
		Color(0.25, 0.2, 0.15),
		Color(0.3, 0.3, 0.32),
		Color(0.15, 0.15, 0.18),
	]
	# Nữ mặc váy màu sáng hơn
	if gender == "female":
		pants_colors = [
			Color(0.35, 0.3, 0.45),
			Color(0.3, 0.25, 0.35),
			Color(0.25, 0.3, 0.4),
			Color(0.4, 0.35, 0.3),
		]
	var hair_colors := [
		Color(0.25, 0.18, 0.12),
		Color(0.15, 0.1, 0.08),
		Color(0.4, 0.3, 0.15),
		Color(0.1, 0.1, 0.12),
		Color(0.5, 0.4, 0.2),
	]
	var skin_colors := [
		Color(0.85, 0.72, 0.6),
		Color(0.78, 0.65, 0.52),
		Color(0.7, 0.58, 0.45),
		Color(0.9, 0.78, 0.65),
	]

	# Người già tóc bạc
	if age > 65:
		hair_colors = [Color(0.8, 0.8, 0.78), Color(0.7, 0.7, 0.68), Color(0.6, 0.6, 0.58)]

	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = skin_colors[randi() % skin_colors.size()]
	skin_mat.roughness = 0.8

	var cloth_mat := StandardMaterial3D.new()
	cloth_mat.albedo_color = shirt_colors[randi() % shirt_colors.size()]
	cloth_mat.roughness = 0.85

	var pants_mat := StandardMaterial3D.new()
	pants_mat.albedo_color = pants_colors[randi() % pants_colors.size()]
	pants_mat.roughness = 0.9

	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = hair_colors[randi() % hair_colors.size()]
	hair_mat.roughness = 0.95

	# Hips
	bone_hips = Node3D.new()
	bone_hips.name = "Hips"
	bone_hips.position = Vector3(0, 0.9, 0)
	skeleton.add_child(bone_hips)

	# Torso
	bone_torso = Node3D.new()
	bone_torso.name = "Torso"
	bone_hips.add_child(bone_torso)
	_add_box(bone_torso, Vector3(0.45 * shoulder_factor, 0.55, 0.28), Vector3(0, 0.3, 0), cloth_mat)

	# Người già còng lưng
	if age > 60:
		var lean := clampf((age - 60) / 25.0, 0, 1) * 0.18
		bone_torso.rotation.x = lean

	# Head
	bone_head = Node3D.new()
	bone_head.name = "Head"
	bone_head.position = Vector3(0, 0.65, 0)
	bone_torso.add_child(bone_head)
	_add_box(bone_head, Vector3(0.3, 0.32, 0.3), Vector3.ZERO, skin_mat)
	_add_box(bone_head, Vector3(0.34, 0.18, 0.34), Vector3(0, 0.22, -0.02), hair_mat)

	# Nữ có tóc dài phía sau đầu (-Z là phía sau khi rotation.y = 0)
	if gender == "female":
		_add_box(bone_head, Vector3(0.36, 0.55, 0.08), Vector3(0, -0.1, -0.18), hair_mat)

	# Arms
	bone_arm_l = Node3D.new()
	bone_arm_l.name = "ArmL"
	bone_arm_l.position = Vector3(0.28 * shoulder_factor, 0.55, 0)
	bone_torso.add_child(bone_arm_l)
	_add_box(bone_arm_l, Vector3(0.12, 0.5, 0.12), Vector3(0, -0.25, 0), cloth_mat)

	bone_arm_r = Node3D.new()
	bone_arm_r.name = "ArmR"
	bone_arm_r.position = Vector3(-0.28 * shoulder_factor, 0.55, 0)
	bone_torso.add_child(bone_arm_r)
	_add_box(bone_arm_r, Vector3(0.12, 0.5, 0.12), Vector3(0, -0.25, 0), cloth_mat)

	# Legs
	bone_leg_l = Node3D.new()
	bone_leg_l.name = "LegL"
	bone_leg_l.position = Vector3(0.12, -0.05, 0)
	bone_hips.add_child(bone_leg_l)
	_add_box(bone_leg_l, Vector3(0.14, 0.7, 0.14), Vector3(0, -0.35, 0), pants_mat)

	bone_leg_r = Node3D.new()
	bone_leg_r.name = "LegR"
	bone_leg_r.position = Vector3(-0.12, -0.05, 0)
	bone_hips.add_child(bone_leg_r)
	_add_box(bone_leg_r, Vector3(0.14, 0.7, 0.14), Vector3(0, -0.35, 0), pants_mat)

	# Nữ mặc váy — box rộng ở hông kéo xuống giữa đùi
	if gender == "female":
		_add_box(bone_hips, Vector3(0.52 * shoulder_factor, 0.5, 0.32), Vector3(0, -0.15, 0), pants_mat)


func _add_name_label() -> void:
	_name_label = Label3D.new()
	_name_label.text = "%s (%d)" % [npc_name, age]
	_name_label.font_size = 42
	_name_label.outline_size = 10
	_name_label.outline_modulate = Color(0, 0, 0, 0.85)
	# Nữ label hồng, nam label vàng nhạt
	if gender == "female":
		_name_label.modulate = Color(1.0, 0.5, 0.65, 1)
	else:
		_name_label.modulate = Color(0.8, 0.9, 1.0, 1)
	_name_label.pixel_size = 0.012
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	_name_label.position = Vector3(0, body_scale * 2.5 + 0.2, 0)
	# Ẩn mặc định — chỉ hiện khi hover/select
	# Portrait mode: không cần label
	if preview:
		_name_label.queue_free()
		_name_label = null
	else:
		_name_label.visible = false
		add_child(_name_label)


func _update_focus_visual() -> void:
	var focused: bool = hovered or selected
	if _name_label:
		_name_label.visible = focused
		if selected:
			_name_label.modulate = Color(1.2, 1.1, 0.5, 1)
		elif hovered:
			if gender == "female":
				_name_label.modulate = Color(1.0, 0.5, 0.65, 1)
			else:
				_name_label.modulate = Color(0.8, 0.9, 1.0, 1)
	for mi in _meshes:
		var mat := mi.material_override as StandardMaterial3D
		if mat:
			if focused:
				mat.emission_enabled = true
				if selected:
					mat.emission = Color(1.0, 0.85, 0.3)
					mat.emission_energy_multiplier = 0.6
				else:
					mat.emission = Color(0.5, 0.7, 1.0)
					mat.emission_energy_multiplier = 0.35
			else:
				mat.emission_enabled = false
				mat.emission_energy_multiplier = 0.0


func _adjust_collision() -> void:
	var col := $CollisionShape3D as CollisionShape3D
	if col and col.shape is CapsuleShape3D:
		var cap := col.shape as CapsuleShape3D
		cap.radius = 0.35 * body_scale
		cap.height = 1.7 * body_scale
		col.position.y = 0.85 * body_scale


func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	_meshes.append(mi)


func _physics_process(delta: float) -> void:
	if preview:
		_update_visuals(delta)
		return
	_wander_timer -= delta
	if _wander_timer <= 0:
		_pick_new_wander()

	if _is_moving:
		velocity = _wander_dir * _speed
	else:
		velocity = Vector3.ZERO

	# Bounce off world bounds
	var pos := global_position
	if abs(pos.x) > world_bounds:
		pos.x = clampf(pos.x, -world_bounds, world_bounds)
		_wander_dir.x *= -1
	if abs(pos.z) > world_bounds:
		pos.z = clampf(pos.z, -world_bounds, world_bounds)
		_wander_dir.z *= -1
	global_position = pos

	move_and_slide()
	_update_face(delta)
	_update_visuals(delta)


func _pick_new_wander() -> void:
	if randf() < 0.65:
		_is_moving = true
		var angle := randf() * TAU
		_wander_dir = Vector3(cos(angle), 0, sin(angle))
		# Người già và trẻ nhỏ đi chậm hơn
		var speed_mod := 1.0
		if age < 10:
			speed_mod = 0.6
		elif age > 65:
			speed_mod = 0.65
		_speed = randf_range(1.5, 3.5) * speed_mod
		_wander_timer = randf_range(2.0, 6.0)
	else:
		_is_moving = false
		_wander_timer = randf_range(1.0, 3.0)


func _update_face(delta: float) -> void:
	if velocity.length_squared() > 0.1:
		# Model forward là +Z, atan2(x, z) cho góc đúng
		var target := atan2(velocity.x, velocity.z)
		var diff := angle_difference(_face_angle, target)
		_face_angle += diff * 0.1


func _update_visuals(delta: float) -> void:
	if skeleton:
		skeleton.rotation.y = _face_angle

	if _is_moving:
		_walk_phase += delta * 10.0
		_walk_amp = lerpf(_walk_amp, 1.0, 0.1)
	else:
		_walk_amp = lerpf(_walk_amp, 0.0, 0.08)

	var swing := sin(_walk_phase) * 0.5 * _walk_amp
	var swing2 := sin(_walk_phase + PI) * 0.5 * _walk_amp

	if bone_leg_l:
		bone_leg_l.rotation.x = swing
	if bone_leg_r:
		bone_leg_r.rotation.x = swing2
	if bone_arm_l:
		bone_arm_l.rotation.x = swing2
	if bone_arm_r:
		bone_arm_r.rotation.x = swing

	# Torso bob — walking bob + idle breathing
	if bone_torso:
		var bob: float = 0.0
		if _is_moving:
			bob = abs(sin(_walk_phase)) * 0.05 * _walk_amp
		else:
			bob = sin(Time.get_ticks_msec() * 0.002 + _idle_offset) * 0.01
		bone_torso.position.y = lerpf(bone_torso.position.y, bob, 0.2)