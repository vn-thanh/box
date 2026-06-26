extends Node3D
class_name WorldGenerator

## Sinh môi trường phong cách Ghibli: đồng cỏ, cây cổ thụ, hoa dại, đá, ao nước
## Coordinator mỏng — ủy thác cho các generator riêng trong scripts/world/

@export var world_size: float = 80.0
@export var tree_count: int = 40
@export var flower_count: int = 120
@export var grass_clump_count: int = 200
@export var rock_count: int = 25
@export var pond_count: int = 3
@export var seed: int = 42

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = seed
	_generate_all()


func _generate_all() -> void:
	PondGen.generate(self, pond_count, world_size, _rng)
	GrassGen.generate(self, grass_clump_count, world_size, _rng)
	FlowerGen.generate(self, flower_count, world_size, _rng)
	RockGen.generate(self, rock_count, world_size, _rng)
	TreeGen.generate(self, tree_count, world_size, _rng)