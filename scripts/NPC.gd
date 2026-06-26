extends CharacterBody3D
class_name NPC3D

@export var world_bounds: float = 35.0

# --- Humanoid skeleton ---
var skeleton: Node3D
var bone_hips: Node3D
var bone_torso: Node3D
var bone_head: Node3D
var bone_arm_l: Node3D
var bone_arm_r: Node3D
var bone_leg_l: Node3D
var bone_leg_r: Node3D

# --- Animation ---
var _walk_phase: float = 0.0
var _is_moving: bool = false
var _face_angle: float = 0.0
var _idle_offset: float = 0.0

# --- Wander AI ---
var _wander_timer: float = 0.0
var _wander_dir: Vector3 = Vector3.ZERO
var _speed: float = 2.0


func _ready() -> void:
	_idle_offset = randf() * TAU
	_build_skeleton()
	_pick_new_wander()


func _build_skeleton() -> void:
	skeleton = Node3D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)

	# Random palette
	var shirt_colors := [
		Color(0.3, 0.55, 0.7),    # xanh dương
		Color(0.7, 0.3, 0.3),     # đỏ
		Color(0.3, 0.6, 0.35),    # xanh lá
		Color(0.5, 0.35, 0.6),    # tím
		Color(0.8, 0.6, 0.3),     # cam
		Color(0.35, 0.35, 0.4),   # xám
	]
	var pants_colors := [
		Color(0.2, 0.22, 0.3),
		Color(0.25, 0.2, 0.15),
		Color(0.3, 0.3, 0.32),
		Color(0.15, 0.15, 0.18),
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
	_add_box(bone_torso, Vector3(0.45, 0.55, 0.28), Vector3(0, 0.3, 0), cloth_mat)

	# Head
	bone_head = Node3D.new()
	bone_head.name = "Head"
	bone_head.position = Vector3(0, 0.65, 0)
	bone_torso.add_child(bone_head)
	_add_box(bone_head, Vector3(0.3, 0.32, 0.3), Vector3.ZERO, skin_mat)
	_add_box(bone_head, Vector3(0.34, 0.18, 0.34), Vector3(0, 0.22, -0.02), hair_mat)

	# Arms
	bone_arm_l = Node3D.new()
	bone_arm_l.name = "ArmL"
	bone_arm_l.position = Vector3(0.28, 0.55, 0)
	bone_torso.add_child(bone_arm_l)
	_add_box(bone_arm_l, Vector3(0.12, 0.5, 0.12), Vector3(0, -0.25, 0), cloth_mat)

	bone_arm_r = Node3D.new()
	bone_arm_r.name = "ArmR"
	bone_arm_r.position = Vector3(-0.28, 0.55, 0)
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


func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)


func _physics_process(delta: float) -> void:
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
		_speed = randf_range(1.5, 3.5)
		_wander_timer = randf_range(2.0, 6.0)
	else:
		_is_moving = false
		_wander_timer = randf_range(1.0, 3.0)


func _update_face(delta: float) -> void:
	if velocity.length_squared() > 0.1:
		var target := atan2(velocity.x, velocity.z)
		var diff := angle_difference(_face_angle, target)
		_face_angle += diff * 0.1


func _update_visuals(delta: float) -> void:
	if skeleton:
		skeleton.rotation.y = _face_angle

	if _is_moving:
		_walk_phase += delta * 10.0
	else:
		_walk_phase = lerpf(_walk_phase, 0.0, 0.15)

	var swing := sin(_walk_phase) * 0.5
	var swing2 := sin(_walk_phase + PI) * 0.5

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
			bob = abs(sin(_walk_phase)) * 0.05
		else:
			bob = sin(Time.get_ticks_msec() * 0.002 + _idle_offset) * 0.01
		bone_torso.position.y = lerpf(bone_torso.position.y, bob, 0.2)