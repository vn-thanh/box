extends Node3D
class_name Animal3D

## Động vật môi trường phong cách Ghibli — chim bay + thỏ nhảy
## Wander AI đơn giản, skeleton bằng box mesh giống NPC

enum Type { BIRD, RABBIT }

@export var animal_type: Type = Type.BIRD
@export var world_bounds: float = 35.0

# --- Wander ---
var _wander_timer: float = 0.0
var _wander_dir: Vector3 = Vector3.ZERO
var _speed: float = 2.0
var _is_moving: bool = true
var _face_angle: float = 0.0

# --- Animation phases ---
var _phase: float = 0.0
var _wing_phase: float = 0.0
var _hop_phase: float = 0.0

# --- Bird ---
var _fly_altitude: float = 4.0

# --- Skeleton parts ---
var _skeleton: Node3D
var _wing_l: Node3D
var _wing_r: Node3D
var _ear_l: Node3D
var _ear_r: Node3D


func _ready() -> void:
	_phase = randf() * TAU
	_build_body()
	_pick_new_wander()
	if animal_type == Type.BIRD:
		_fly_altitude = randf_range(3.0, 6.0)
		global_position.y = _fly_altitude


func _build_body() -> void:
	_skeleton = Node3D.new()
	_skeleton.name = "Skeleton"
	add_child(_skeleton)
	if animal_type == Type.BIRD:
		_build_bird()
	else:
		_build_rabbit()


func _build_bird() -> void:
	var body_colors := [
		Color(0.3, 0.5, 0.8),   # xanh dương
		Color(0.8, 0.3, 0.3),   # đỏ
		Color(0.9, 0.8, 0.3),   # vàng
		Color(0.5, 0.4, 0.3),   # nâu
		Color(0.3, 0.6, 0.5),   # xanh lá nhạt
	]
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = body_colors[randi() % body_colors.size()]
	body_mat.roughness = 0.8

	var beak_mat := StandardMaterial3D.new()
	beak_mat.albedo_color = Color(1.0, 0.7, 0.2)
	beak_mat.roughness = 0.6

	# Body
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.25, 0.22, 0.4)
	body.mesh = body_mesh
	body.material_override = body_mat
	_skeleton.add_child(body)

	# Head
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.18, 0.18, 0.18)
	head.mesh = head_mesh
	head.position = Vector3(0, 0.08, 0.25)
	head.material_override = body_mat
	_skeleton.add_child(head)

	# Beak
	var beak := MeshInstance3D.new()
	var beak_mesh := BoxMesh.new()
	beak_mesh.size = Vector3(0.06, 0.05, 0.1)
	beak.mesh = beak_mesh
	beak.position = Vector3(0, 0.05, 0.36)
	beak.material_override = beak_mat
	_skeleton.add_child(beak)

	# Wings — pivot tại vai, mesh offset ra ngoài
	var wing_box := BoxMesh.new()
	wing_box.size = Vector3(0.3, 0.04, 0.25)

	_wing_l = Node3D.new()
	_wing_l.name = "WingL"
	_wing_l.position = Vector3(0.14, 0.05, 0)
	_skeleton.add_child(_wing_l)
	var wing_l_mesh := MeshInstance3D.new()
	wing_l_mesh.mesh = wing_box
	wing_l_mesh.position = Vector3(0.15, 0, 0)
	wing_l_mesh.material_override = body_mat
	_wing_l.add_child(wing_l_mesh)

	_wing_r = Node3D.new()
	_wing_r.name = "WingR"
	_wing_r.position = Vector3(-0.14, 0.05, 0)
	_skeleton.add_child(_wing_r)
	var wing_r_mesh := MeshInstance3D.new()
	wing_r_mesh.mesh = wing_box
	wing_r_mesh.position = Vector3(-0.15, 0, 0)
	wing_r_mesh.material_override = body_mat
	_wing_r.add_child(wing_r_mesh)

	# Tail
	var tail := MeshInstance3D.new()
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.12, 0.06, 0.18)
	tail.mesh = tail_mesh
	tail.position = Vector3(0, 0.03, -0.28)
	tail.material_override = body_mat
	_skeleton.add_child(tail)

	_skeleton.scale = Vector3(0.6, 0.6, 0.6)


func _build_rabbit() -> void:
	var fur_colors := [
		Color(0.85, 0.8, 0.75),  # be
		Color(0.6, 0.5, 0.4),    # nâu
		Color(0.9, 0.9, 0.88),   # trắng
		Color(0.45, 0.4, 0.35),  # nâu đậm
	]
	var fur_mat := StandardMaterial3D.new()
	fur_mat.albedo_color = fur_colors[randi() % fur_colors.size()]
	fur_mat.roughness = 0.95

	# Body
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.3, 0.28, 0.45)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.25, 0)
	body.material_override = fur_mat
	_skeleton.add_child(body)

	# Head
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.22, 0.22, 0.22)
	head.mesh = head_mesh
	head.position = Vector3(0, 0.45, 0.22)
	head.material_override = fur_mat
	_skeleton.add_child(head)

	# Ears — pivot tại gốc tai, mesh offset lên trên
	var ear_box := BoxMesh.new()
	ear_box.size = Vector3(0.06, 0.22, 0.04)

	_ear_l = Node3D.new()
	_ear_l.name = "EarL"
	_ear_l.position = Vector3(0.07, 0.56, 0.2)
	_skeleton.add_child(_ear_l)
	var ear_l_mesh := MeshInstance3D.new()
	ear_l_mesh.mesh = ear_box
	ear_l_mesh.position = Vector3(0, 0.11, 0)
	ear_l_mesh.material_override = fur_mat
	_ear_l.add_child(ear_l_mesh)

	_ear_r = Node3D.new()
	_ear_r.name = "EarR"
	_ear_r.position = Vector3(-0.07, 0.56, 0.2)
	_skeleton.add_child(_ear_r)
	var ear_r_mesh := MeshInstance3D.new()
	ear_r_mesh.mesh = ear_box
	ear_r_mesh.position = Vector3(0, 0.11, 0)
	ear_r_mesh.material_override = fur_mat
	_ear_r.add_child(ear_r_mesh)

	# Tail — Box trắng nhỏ
	var tail := MeshInstance3D.new()
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.1, 0.1, 0.1)
	tail.mesh = tail_mesh
	tail.position = Vector3(0, 0.28, -0.25)
	var tail_mat := StandardMaterial3D.new()
	tail_mat.albedo_color = Color(0.95, 0.95, 0.95)
	tail_mat.roughness = 0.9
	tail.material_override = tail_mat
	_skeleton.add_child(tail)

	# Legs — 4 box nhỏ
	for sx in [0.1, -0.1]:
		for sz in [0.15, -0.15]:
			var leg := MeshInstance3D.new()
			var leg_mesh := BoxMesh.new()
			leg_mesh.size = Vector3(0.08, 0.15, 0.08)
			leg.mesh = leg_mesh
			leg.position = Vector3(sx, 0.08, sz)
			leg.material_override = fur_mat
			_skeleton.add_child(leg)


func _process(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0:
		_pick_new_wander()

	var pos := global_position

	if animal_type == Type.BIRD:
		pos += _wander_dir * _speed * delta
		_phase += delta * 2.0
		pos.y = _fly_altitude + sin(_phase) * 0.3
		_wing_phase += delta * 12.0
		var flap := sin(_wing_phase) * 0.6
		if _wing_l:
			_wing_l.rotation.z = flap
		if _wing_r:
			_wing_r.rotation.z = -flap
	else:
		pos += _wander_dir * _speed * delta
		if _is_moving:
			_hop_phase += delta * 8.0
			pos.y = abs(sin(_hop_phase)) * 0.3
		else:
			pos.y = lerpf(pos.y, 0.0, 0.2)
		# Tai đung đưa khi nhảy
		if _ear_l and _ear_r:
			var ear_wobble := sin(_hop_phase) * 0.15
			_ear_l.rotation.x = ear_wobble
			_ear_r.rotation.x = ear_wobble

	# Bounce off world bounds
	if abs(pos.x) > world_bounds:
		pos.x = clampf(pos.x, -world_bounds, world_bounds)
		_wander_dir.x *= -1
	if abs(pos.z) > world_bounds:
		pos.z = clampf(pos.z, -world_bounds, world_bounds)
		_wander_dir.z *= -1

	global_position = pos

	# Face direction of movement
	if _wander_dir.length_squared() > 0.1:
		var target := atan2(_wander_dir.x, _wander_dir.z)
		var diff := angle_difference(_face_angle, target)
		_face_angle += diff * 0.1
	if _skeleton:
		_skeleton.rotation.y = _face_angle


func _pick_new_wander() -> void:
	if animal_type == Type.BIRD:
		# Chim luôn bay, đổi hướng ngẫu nhiên
		var angle := randf() * TAU
		_wander_dir = Vector3(cos(angle), 0, sin(angle))
		_speed = randf_range(2.0, 4.0)
		_wander_timer = randf_range(3.0, 7.0)
	else:
		# Thỏ lúc nhảy lúc đứng yên
		_is_moving = randf() < 0.75
		if _is_moving:
			var angle := randf() * TAU
			_wander_dir = Vector3(cos(angle), 0, sin(angle))
			_speed = randf_range(1.5, 3.0)
		else:
			_wander_dir = Vector3.ZERO
		_wander_timer = randf_range(2.0, 5.0)