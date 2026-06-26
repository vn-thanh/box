extends Node3D

var npc_scene: PackedScene = preload("res://scenes/NPC.tscn")

@onready var camera: Camera3D = $Camera3D
@onready var ground_mesh: MeshInstance3D = $Ground/GroundMesh

const NPC_COUNT: int = 15

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
	# Ground màu cỏ
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.42, 0.55, 0.28)
	ground_mat.roughness = 1.0
	ground_mesh.material_override = ground_mat

	# Spawn NPCs at random positions
	for i in NPC_COUNT:
		var npc := npc_scene.instantiate() as NPC3D
		add_child(npc)
		var angle := randf() * TAU
		var dist := randf_range(5.0, 30.0)
		npc.global_position = Vector3(cos(angle) * dist, 0, sin(angle) * dist)


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

	# Position camera at isometric angle, look at target
	camera.global_position = cam_target_smooth + _cam_offset
	camera.look_at(cam_target_smooth, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	# Scroll wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - ZOOM_SPEED, ZOOM_MIN, ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + ZOOM_SPEED, ZOOM_MIN, ZOOM_MAX)