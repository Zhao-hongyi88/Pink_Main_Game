extends Node


class TransitionProbe:
	extends Node


	func run() -> void:
		var transition_layer: Variant = SceneRouter.get_node_or_null("TransitionLayer")
		assert(transition_layer != null)
		assert(transition_layer is CanvasLayer)
		assert(transition_layer.layer >= 100)
		var overlay := transition_layer.get_node("%FadeOverlay") as ColorRect
		assert(overlay != null)
		assert(overlay.color == Color.BLACK)
		assert(is_zero_approx(overlay.modulate.a))
		assert(overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		assert(is_equal_approx(overlay.anchor_right, 1.0))
		assert(is_equal_approx(overlay.anchor_bottom, 1.0))

		transition_layer.fade_duration = 0.05
		await transition_layer.fade_out()
		assert(is_equal_approx(overlay.modulate.a, 1.0))
		assert(overlay.mouse_filter == Control.MOUSE_FILTER_STOP)
		await transition_layer.fade_in()
		assert(is_zero_approx(overlay.modulate.a))
		assert(overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)

		var payload := {
			"transition_test": "preserved",
			"nested": {"value": 42},
		}
		assert(SceneRouter.go_to(&"lobby", payload))
		assert(SceneRouter.is_transitioning())
		assert(not SceneRouter.go_to(&"home", {"should_not_replace": true}))

		for _frame in 300:
			if not SceneRouter.is_transitioning():
				break
			await get_tree().process_frame
		assert(not SceneRouter.is_transitioning())
		assert(get_tree().current_scene != null)
		assert(get_tree().current_scene.scene_file_path == SceneRouter.ROUTES[&"lobby"])
		assert(SceneRouter.current_route == &"lobby")
		assert(is_zero_approx(overlay.modulate.a))
		assert(overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)

		var received_payload := SceneRouter.take_payload()
		assert(received_payload == payload)
		assert(SceneRouter.take_payload().is_empty())
		print("TRANSITION_SYSTEM_SMOKE_TEST: PASS")
		get_tree().quit(0)


func _ready() -> void:
	call_deferred("_start_probe")


func _start_probe() -> void:
	var probe := TransitionProbe.new()
	get_tree().root.add_child(probe)
	probe.run()
