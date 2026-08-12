class_name ImageLocator
extends Node

## 仅用于开发测试场景的图片资源定位器，不参与正式游戏流程。
@export var scan_on_ready := true
@export var include_empty_textures := true

const IMPORTANT_KEYWORDS: PackedStringArray = [
	"background",
	"bg",
	"portrait",
	"image",
	"preview",
	"paper",
	"texture",
	"icon",
	"button",
]


func _ready() -> void:
	if scan_on_ready:
		call_deferred("scan_current_scene")


func scan_current_scene() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		push_warning("ImageLocator: 当前没有可扫描的场景。")
		return

	print("==============================")
	print("Pink_Main_Game 图片资源列表")
	print("==============================")
	_scan_node(scene_root, scene_root)
	print("==============================")


func _scan_node(node: Node, scene_root: Node) -> void:
	if _is_supported_visual_node(node):
		_print_visual_node(node, scene_root)
	for child in node.get_children():
		_scan_node(child, scene_root)


func _is_supported_visual_node(node: Node) -> bool:
	return (
		node is TextureRect
		or node is Sprite2D
		or node is AnimatedSprite2D
		or node is TextureButton
	)


func _print_visual_node(node: Node, scene_root: Node) -> void:
	var texture_entries := _get_texture_entries(node)
	if texture_entries.is_empty() and not include_empty_textures:
		return

	if _is_important_node(node):
		print("★★ 可替换图片位置 ★★")
	print("[%s]" % node.get_class())
	print("Node:")
	print(_get_display_path(node, scene_root))
	if texture_entries.is_empty():
		print("Texture:")
		print("<empty>")
	else:
		for entry: Dictionary in texture_entries:
			print(str(entry["label"]) + ":")
			print(_get_texture_path(entry["texture"]))
	print("")


func _get_texture_entries(node: Node) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if node is TextureRect:
		_append_texture(entries, "Texture", (node as TextureRect).texture)
	elif node is Sprite2D:
		_append_texture(entries, "Texture", (node as Sprite2D).texture)
	elif node is AnimatedSprite2D:
		var animated_sprite := node as AnimatedSprite2D
		var frame_texture: Texture2D
		if (
			animated_sprite.sprite_frames != null
			and animated_sprite.sprite_frames.has_animation(animated_sprite.animation)
			and animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation) > 0
		):
			var frame_index := clampi(
				animated_sprite.frame,
				0,
				animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation) - 1
			)
			frame_texture = animated_sprite.sprite_frames.get_frame_texture(
				animated_sprite.animation,
				frame_index
			)
		_append_texture(entries, "Texture (%s frame %d)" % [animated_sprite.animation, animated_sprite.frame], frame_texture)
	elif node is TextureButton:
		var texture_button := node as TextureButton
		_append_texture(entries, "Texture (normal)", texture_button.texture_normal)
		_append_texture(entries, "Texture (hover)", texture_button.texture_hover)
		_append_texture(entries, "Texture (pressed)", texture_button.texture_pressed)
		_append_texture(entries, "Texture (disabled)", texture_button.texture_disabled)
		_append_texture(entries, "Texture (focused)", texture_button.texture_focused)
	return entries


func _append_texture(entries: Array[Dictionary], label: String, texture: Texture2D) -> void:
	if texture == null and not include_empty_textures:
		return
	entries.append({"label": label, "texture": texture})


func _get_texture_path(texture: Texture2D) -> String:
	if texture == null:
		return "<empty>"
	var path := texture.resource_path
	if path.is_empty():
		return "<embedded %s>" % texture.get_class()
	return path


func _is_important_node(node: Node) -> bool:
	var normalized_name := String(node.name).to_lower()
	for keyword in IMPORTANT_KEYWORDS:
		if normalized_name.contains(keyword):
			return true
	return false


func _get_display_path(node: Node, scene_root: Node) -> String:
	if node == scene_root:
		return String(scene_root.name)
	return "%s/%s" % [scene_root.name, scene_root.get_path_to(node)]
