class_name RoadBuilder
## Builder cho đường — tile đất nén phẳng
## Không block pathfinding, PlacementSystem xóa decor trong footprint khi đặt

static func build(b: Building3D) -> void:
	b._add_box(Vector3(4.0, 0.08, 4.0), Vector3(0, 0.04, 0), b._mat(Color(0.52, 0.44, 0.34), 0.95))