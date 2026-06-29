class_name ResourceManager
## Quản lý tài nguyên: gold, wood, food
## Production: mỗi tick (day cycle), worker sinh tài nguyên theo nghề
## Cost: xây dựng trừ gold

static var _gold: int = 500
static var _wood: int = 50
static var _food: int = 50

## Mức sinh sản theo nghề (per worker, per day)
const PRODUCTION := {
	NPC3D.JobType.GATHERER: {"food": 3},
	NPC3D.JobType.LUMBERJACK: {"wood": 4},
	NPC3D.JobType.DOCTOR: {"gold": 2},
	NPC3D.JobType.PRIEST: {"gold": 1},
	NPC3D.JobType.TEACHER: {"gold": 2},
}

## Chi phí xây (theo Building.Type)
const BUILD_COSTS := {
	Building3D.Type.SAWMILL: 100,
	Building3D.Type.CHURCH: 200,
	Building3D.Type.HOSPITAL: 300,
	Building3D.Type.SCHOOL: 150,
	Building3D.Type.HOUSE: 80,
	Building3D.Type.ROAD: 10,
}


static func get_gold() -> int:
	return _gold

static func get_wood() -> int:
	return _wood

static func get_food() -> int:
	return _food


static func can_afford(building_type: int) -> bool:
	var cost: int = BUILD_COSTS.get(building_type, 0)
	return _gold >= cost


static func spend(building_type: int) -> void:
	var cost: int = BUILD_COSTS.get(building_type, 0)
	_gold -= cost
	_emit_changed()


static func add_gold(amount: int) -> void:
	_gold += amount
	_emit_changed()


## Sinh tài nguyên từ danh sách NPC (gọi mỗi day cycle)
static func produce(npcs: Array) -> void:
	var wood_gain := 0
	var food_gain := 0
	var gold_gain := 0
	for child in npcs:
		var npc := child as NPC3D
		if not npc or npc.age < 14 or npc.age > 70:
			continue
		var prod: Dictionary = PRODUCTION.get(npc.job, {})
		if prod.has("wood"):
			wood_gain += prod["wood"]
		if prod.has("food"):
			food_gain += prod["food"]
		if prod.has("gold"):
			gold_gain += prod["gold"]
	# Bán wood/food lấy gold (50% rate)
	if wood_gain > 0:
		_wood += wood_gain
		var sold := wood_gain / 2
		_wood -= sold
		gold_gain += sold * 2
	if food_gain > 0:
		_food += food_gain
		var sold := food_gain / 2
		_food -= sold
		gold_gain += sold * 2
	_gold += gold_gain
	_emit_changed()


## Tiêu hao food theo dân số (mỗi NPC ăn 1 food/ngày)
static func consume_food(npc_count: int) -> void:
	_food = max(0, _food - npc_count)
	_emit_changed()


static func reset() -> void:
	_gold = 500
	_wood = 50
	_food = 50
	_emit_changed()


static func load_from(data: Dictionary) -> void:
	_gold = int(data.get("gold", 500))
	_wood = int(data.get("wood", 50))
	_food = int(data.get("food", 50))
	_emit_changed()


static func to_dict() -> Dictionary:
	return {
		"gold": _gold,
		"wood": _wood,
		"food": _food,
	}


static func _emit_changed() -> void:
	pass