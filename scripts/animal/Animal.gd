extends Node3D
class_name Animal3D

## Động vật môi trường phong cách Ghibli — base class với wander AI
## Mỗi loại động vật có builder riêng trong scripts/animal/
## Skeleton bằng box mesh giống NPC

enum Type { BIRD, RABBIT }

@export var animal_type: Type = Type.BIRD
@export var world_bounds: float = 35.0

# Vùng nước — thỏ tránh đi vào (set bởi AnimalGen sau khi spawn)
var water_areas: Array = []

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
	match animal_type:
		Type.BIRD:
			BirdBuilder.build(self)
		Type.RABBIT:
			RabbitBuilder.build(self)


# ============================================================
# HELPERS — dùng chung cho builder
# ============================================================

func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


# ============================================================
# PROCESS — wander + animation
# ============================================================

func _process(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0:
		_pick_new_wander()

	var pos := global_position

	if animal_type == Type.BIRD:
		_process_bird(delta, pos)
	else:
		_process_rabbit(delta, pos)


func _process_bird(delta: float, pos: Vector3) -> void:
	pos += _wander_dir * _speed * delta
	_phase += delta * 2.0
	pos.y = _fly_altitude + sin(_phase) * 0.3
	_wing_phase += delta * 12.0
	var flap := sin(_wing_phase) * 0.6
	if _wing_l:
		_wing_l.rotation.z = flap
	if _wing_r:
		_wing_r.rotation.z = -flap

	# Bounce off world bounds
	if abs(pos.x) > world_bounds:
		pos.x = clampf(pos.x, -world_bounds, world_bounds)
		_wander_dir.x *= -1
	if abs(pos.z) > world_bounds:
		pos.z = clampf(pos.z, -world_bounds, world_bounds)
		_wander_dir.z *= -1

	global_position = pos

	if _wander_dir.length_squared() > 0.1:
		var target := atan2(_wander_dir.x, _wander_dir.z)
		var diff := angle_difference(_face_angle, target)
		_face_angle += diff * 0.1
	if _skeleton:
		_skeleton.rotation.y = _face_angle


func _process_rabbit(delta: float, pos: Vector3) -> void:
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

	# Thỏ tránh nước
	if water_areas.size() > 0:
		if WaterGen.is_in_water(pos, water_areas, 0.5):
			pos = global_position
			_wander_dir = -_wander_dir
			_is_moving = false
			_wander_timer = 0.0
		elif WaterGen.is_in_water(pos + _wander_dir * 2.0, water_areas, 0.5):
			_is_moving = false
			_wander_timer = 0.0

	global_position = pos

	if _wander_dir.length_squared() > 0.1:
		var target := atan2(_wander_dir.x, _wander_dir.z)
		var diff := angle_difference(_face_angle, target)
		_face_angle += diff * 0.1
	if _skeleton:
		_skeleton.rotation.y = _face_angle


func _pick_new_wander() -> void:
	match animal_type:
		Type.BIRD:
			_pick_bird_wander()
		Type.RABBIT:
			_pick_rabbit_wander()


func _pick_bird_wander() -> void:
	var angle := randf() * TAU
	_wander_dir = Vector3(cos(angle), 0, sin(angle))
	_speed = randf_range(2.0, 4.0)
	_wander_timer = randf_range(3.0, 7.0)


func _pick_rabbit_wander() -> void:
	_is_moving = randf() < 0.75
	if _is_moving:
		var angle := randf() * TAU
		for _attempt in 8:
			angle = randf() * TAU
			_wander_dir = Vector3(cos(angle), 0, sin(angle))
			if water_areas.size() == 0 or not WaterGen.is_in_water(global_position + _wander_dir * 3.0, water_areas, 0.5):
				break
		_speed = randf_range(1.5, 3.0)
	else:
		_wander_dir = Vector3.ZERO
	_wander_timer = randf_range(2.0, 5.0)