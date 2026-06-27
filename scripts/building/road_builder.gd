class_name RoadBuilder
## Builder cho đường — tile đất nén phẳng, trơn
## Không có job_slots, không block pathfinding (NPC đi trên đường được)
## Khi đặt, PlacementSystem sẽ xóa decor (cây/cỏ/hoa/đá) nằm trong footprint

static func build(b: Building3D) -> void:
	# Mặt đường đất nén phẳng, trơn — không vạch kẻ, không trang trí
	var road_mat := b._mat(Color(0.52, 0.44, 0.34), 0.95)
	b._add_box(Vector3(4.0, 0.08, 4.0), Vector3(0, 0.04, 0), road_mat)