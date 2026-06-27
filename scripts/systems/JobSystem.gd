class_name JobSystem
## Quản lý phân việc: tự động gán NPC thất nghiệp vào building có slot trống
## Priority: NONE (thất nghiệp) > GATHERER (nghề thấp) → ưu tiên nâng job

## Tự động gán NPC vào building có slot trống
static func auto_assign(npcs: Array, buildings: Array) -> void:
	for bld in buildings:
		var building := bld as Building3D
		if not building or building.get_open_slots() <= 0:
			continue
		# Tìm NPC thất nghiệp hoặc gatherer gần nhất
		var best_npc: NPC3D = null
		var best_dist: float = INF
		for child in npcs:
			var npc := child as NPC3D
			if not npc:
				continue
			# Bỏ qua trẻ em và người già (không lao động)
			if npc.age < 14 or npc.age > 70:
				continue
			# Chỉ nhận NPC thất nghiệp hoặc gatherer (nghề thấp)
			if npc.job != NPC3D.JobType.NONE and npc.job != NPC3D.JobType.GATHERER:
				continue
			if npc.workplace != null:
				continue
			var d := npc.global_position.distance_to(building.global_position)
			if d < best_dist:
				best_dist = d
				best_npc = npc
		if best_npc:
			building.assign_worker(best_npc)


const JOB_NAMES := {
	NPC3D.JobType.NONE: "Thất nghiệp",
	NPC3D.JobType.GATHERER: "Hái lượm",
	NPC3D.JobType.LUMBERJACK: "Thợ gỗ",
	NPC3D.JobType.PRIEST: "Linh mục",
	NPC3D.JobType.DOCTOR: "Bác sĩ",
	NPC3D.JobType.TEACHER: "Giáo viên",
}

## Lấy tên job tiếng Việt
static func job_name(j: int) -> String:
	return JOB_NAMES.get(j, "Không rõ")