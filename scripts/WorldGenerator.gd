extends Node3D
class_name WorldGenerator

## Sinh môi trường phong cách Ghibli: hồ/sông, cây rừng, hoa, cỏ, đá
## Coordinator mỏng — ủy thác cho các generator riêng trong scripts/world/
## Sinh nước trước, truyền vùng nước cho generators khác để tránh

@export var world_size: float = 80.0
@export var tree_count: int = 40
@export var flower_count: int = 120
@export var grass_clump_count: int = 200
@export var rock_count: int = 25
@export var pond_count: int = 3
@export var river_count: int = 1
@export var seed: int = 42

var _rng := RandomNumberGenerator.new()
var _water_areas: Array = []
var _generated: bool = false


func _ready() -> void:
	_rng.seed = seed
	# Không tự generate ở đây — đợi Main gọi generate() sau khi set world_size


## Main gọi hàm này sau khi set world_size từ menu
func generate() -> void:
	if _generated:
		return
	_generated = true
	# Sinh nước trước — trả về vùng nước để generators khác tránh
	_water_areas = WaterGen.generate(self, pond_count, river_count, world_size, _rng)
	# Sau đó sinh còn lại, truyền water_areas
	GrassGen.generate(self, grass_clump_count, world_size, _rng, _water_areas)
	FlowerGen.generate(self, flower_count, world_size, _rng, _water_areas)
	RockGen.generate(self, rock_count, world_size, _rng, _water_areas)
	TreeGen.generate(self, tree_count, world_size, _rng, _water_areas)