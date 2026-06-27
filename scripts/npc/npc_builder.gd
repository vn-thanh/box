class_name NPCBuilder
## Builder cho NPC skeleton — humanoid box mesh
## Tạo hierarchy bone: hips → torso → head, arms; hips → legs
## Palette riêng cho nam/nữ, người già tóc bạc, trẻ em nhỏ hơn

static func build(npc: NPC3D) -> void:
	npc.skeleton = Node3D.new()
	npc.skeleton.name = "Skeleton"
	npc.add_child(npc.skeleton)

	# Age + gender scale
	var gender_scale := 1.0 if npc.gender == "male" else 0.93
	npc.body_scale = npc._age_to_scale(npc.age) * gender_scale
	npc.skeleton.scale = Vector3.ONE * npc.body_scale

	# Females có vai hẹp hơn
	var shoulder_factor := 1.0 if npc.gender == "male" else 0.88

	# Random palette
	var shirt_colors := [
		Color(0.3, 0.55, 0.7),
		Color(0.7, 0.3, 0.3),
		Color(0.3, 0.6, 0.35),
		Color(0.5, 0.35, 0.6),
		Color(0.8, 0.6, 0.3),
		Color(0.35, 0.35, 0.4),
	]
	if npc.gender == "female":
		shirt_colors = [
			Color(0.9, 0.4, 0.55),
			Color(0.85, 0.5, 0.7),
			Color(0.7, 0.4, 0.8),
			Color(0.5, 0.7, 0.9),
			Color(0.9, 0.7, 0.4),
			Color(0.6, 0.8, 0.5),
		]
	var pants_colors := [
		Color(0.2, 0.22, 0.3),
		Color(0.25, 0.2, 0.15),
		Color(0.3, 0.3, 0.32),
		Color(0.15, 0.15, 0.18),
	]
	if npc.gender == "female":
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
	if npc.age > 65:
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
	npc.bone_hips = Node3D.new()
	npc.bone_hips.name = "Hips"
	npc.bone_hips.position = Vector3(0, 0.9, 0)
	npc.skeleton.add_child(npc.bone_hips)

	# Torso
	npc.bone_torso = Node3D.new()
	npc.bone_torso.name = "Torso"
	npc.bone_hips.add_child(npc.bone_torso)
	npc._add_box(npc.bone_torso, Vector3(0.45 * shoulder_factor, 0.55, 0.28), Vector3(0, 0.3, 0), cloth_mat)

	# Người già còng lưng
	if npc.age > 60:
		var lean := clampf((npc.age - 60) / 25.0, 0, 1) * 0.18
		npc.bone_torso.rotation.x = lean

	# Head
	npc.bone_head = Node3D.new()
	npc.bone_head.name = "Head"
	npc.bone_head.position = Vector3(0, 0.65, 0)
	npc.bone_torso.add_child(npc.bone_head)
	npc._add_box(npc.bone_head, Vector3(0.3, 0.32, 0.3), Vector3.ZERO, skin_mat)
	npc._add_box(npc.bone_head, Vector3(0.34, 0.18, 0.34), Vector3(0, 0.22, -0.02), hair_mat)

	# Nữ có tóc dài phía sau đầu
	if npc.gender == "female":
		npc._add_box(npc.bone_head, Vector3(0.36, 0.55, 0.08), Vector3(0, -0.1, -0.18), hair_mat)

	# Arms
	npc.bone_arm_l = Node3D.new()
	npc.bone_arm_l.name = "ArmL"
	npc.bone_arm_l.position = Vector3(0.28 * shoulder_factor, 0.55, 0)
	npc.bone_torso.add_child(npc.bone_arm_l)
	npc._add_box(npc.bone_arm_l, Vector3(0.12, 0.5, 0.12), Vector3(0, -0.25, 0), cloth_mat)

	npc.bone_arm_r = Node3D.new()
	npc.bone_arm_r.name = "ArmR"
	npc.bone_arm_r.position = Vector3(-0.28 * shoulder_factor, 0.55, 0)
	npc.bone_torso.add_child(npc.bone_arm_r)
	npc._add_box(npc.bone_arm_r, Vector3(0.12, 0.5, 0.12), Vector3(0, -0.25, 0), cloth_mat)

	# Legs
	npc.bone_leg_l = Node3D.new()
	npc.bone_leg_l.name = "LegL"
	npc.bone_leg_l.position = Vector3(0.12, -0.05, 0)
	npc.bone_hips.add_child(npc.bone_leg_l)
	npc._add_box(npc.bone_leg_l, Vector3(0.14, 0.7, 0.14), Vector3(0, -0.35, 0), pants_mat)

	npc.bone_leg_r = Node3D.new()
	npc.bone_leg_r.name = "LegR"
	npc.bone_leg_r.position = Vector3(-0.12, -0.05, 0)
	npc.bone_hips.add_child(npc.bone_leg_r)
	npc._add_box(npc.bone_leg_r, Vector3(0.14, 0.7, 0.14), Vector3(0, -0.35, 0), pants_mat)

	# Nữ mặc váy
	if npc.gender == "female":
		npc._add_box(npc.bone_hips, Vector3(0.52 * shoulder_factor, 0.5, 0.32), Vector3(0, -0.15, 0), pants_mat)