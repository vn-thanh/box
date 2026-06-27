class_name JobSystem
## Quản lý phân việc: tự động gán NPC thất nghiệp vào building có slot trống
## Priority: NONE (thất nghiệp) > GATHERER (nghề thấp) → ưu tiên nâng job

## Tự động gán NPC vào building mới đặt hoặc tất cả building trống
static func auto_assign(npcs: Array, buildings: Array) -> void:
	# Duyệt building có slot trống,优先 job cao hơn (sawmill/quarry/farm trước)
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


## Gán NPC cụ thể vào building (manual assign)
static func assign_npc(npc: NPC3D, building: Building3D) -> bool:
	if npc.age < 14 or npc.age > 70:
		return false
	return building.assign_worker(npc)


## Gỡ NPC khỏi building, trở thành thất nghiệp
static func unassign(npc: NPC3D) -> void:
	if npc.workplace:
		npc.workplace.remove_worker(npc)


## Đếm NPC theo job
static func count_by_job(npcs: Array) -> Dictionary:
	var counts := {}
	for child in npcs:
		var npc := child as NPC3D
		if not npc:
			continue
		var key: int = npc.job
		counts[key] = counts.get(key, 0) + 1
	return counts


## Lấy tên job tiếng Việt
static func job_name(j: int) -> String:
	match j:
		NPC3D.JobType.NONE: return "Thất nghiệp"
		NPC3D.JobType.GATHERER: return "Hái lượm"
		NPC3D.JobType.LUMBERJACK: return "Thợ gỗ"
		NPC3D.JobType.MASON: return "Thợ đá"
		NPC3D.JobType.FARMER: return "Nông dân"
		_: return "Không rõ"