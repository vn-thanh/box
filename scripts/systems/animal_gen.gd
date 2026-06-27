class_name AnimalGen
## Sinh động vật (chim, thỏ) — chim bay trên cao, thỏ chạy dưới đất

const ANIMAL_SCENE := preload("res://scenes/Animal.tscn")


static func generate(parent: Node3D, bird_count: int, rabbit_count: int, world_size: float, rng: RandomNumberGenerator, water_areas: Array = []) -> void:
	for _i in bird_count:
		var bird := ANIMAL_SCENE.instantiate() as Animal3D
		bird.animal_type = Animal3D.Type.BIRD
		parent.add_child(bird)
		bird.global_position = WaterGen.safe_pos(world_size, rng, water_areas, 2.0)
		bird.world_bounds = world_size * 0.45

	for _i in rabbit_count:
		var pos := WaterGen.safe_pos(world_size, rng, water_areas, 1.0)
		if pos.length() < 5.0:
			pos = pos.normalized() * 5.0
		var rabbit := ANIMAL_SCENE.instantiate() as Animal3D
		rabbit.animal_type = Animal3D.Type.RABBIT
		rabbit.water_areas = water_areas
		parent.add_child(rabbit)
		rabbit.global_position = pos
		rabbit.world_bounds = world_size * 0.45