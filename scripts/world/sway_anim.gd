class_name SwayAnim
## Utility tạo hiệu ứng đung đưa theo gió cho node 3D (cỏ, hoa, cây)


static func sway(node: Node3D, period: float, amplitude: float, rng: RandomNumberGenerator) -> void:
	var tween := node.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	var phase := rng.randf() * TAU
	tween.tween_method(
		func(val: float) -> void: node.rotation.z = sin(val) * amplitude,
		phase, phase + TAU, period
	)


static func sway_tree(node: Node3D, period: float, amplitude: float, rng: RandomNumberGenerator) -> void:
	var tween := node.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	var phase := rng.randf() * TAU
	tween.tween_method(
		func(val: float) -> void:
			node.rotation.z = sin(val) * amplitude
			node.rotation.x = cos(val * 0.7) * amplitude * 0.5,
		phase, phase + TAU, period
	)