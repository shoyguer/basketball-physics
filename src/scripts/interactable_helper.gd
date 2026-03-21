class_name InteractableHelper
extends RefCounted
## Utility that manages the outline glow and floating label for interactable nodes.
##
## Call [method setup] in the owner's [code]_ready[/code] to create the
## label and cache mesh references. Then use [method show_highlight]
## and [method hide_highlight] to toggle the visual cues.


const _LABEL_SCENE: PackedScene = preload("res://scripts/interactable_label.tscn")

var _owner: Node3D = null
var _label: Label3D = null
var _outline_material: ShaderMaterial = null
var _geometries: Array[GeometryInstance3D] = []


## Creates a label and caches meshes inside the owner node.
func setup(owner: Node3D, label_text: String) -> void:
	_owner = owner

	_outline_material = ShaderMaterial.new()
	_outline_material.shader = preload("res://shader/outline.gdshader")

	_label = _LABEL_SCENE.instantiate()
	_label.text = label_text
	owner.add_child(_label)

	_cache_geometries(owner)
	_position_label()


## Shows the outline on meshes and reveals the label.
func show_highlight() -> void:
	_label.visible = true

	for geo: GeometryInstance3D in _geometries:
		geo.material_overlay = _outline_material


## Hides the outline and the label.
func hide_highlight() -> void:
	_label.visible = false

	for geo: GeometryInstance3D in _geometries:
		geo.material_overlay = null


## Changes the label text.
func set_label_text(text: String) -> void:
	_label.text = text


## Recursively collects all visual geometry nodes under the given node.
func _cache_geometries(node: Node) -> void:
	for child: Node in node.get_children():
		if child is MeshInstance3D or child is CSGShape3D:
			_geometries.append(child as GeometryInstance3D)
		_cache_geometries(child)


## Positions the label above the owner's AABB.
func _position_label() -> void:
	if _geometries.is_empty():
		_label.position = Vector3(0.0, 1.5, 0.0)
		return

	var combined: AABB = AABB()
	for i: int in _geometries.size():
		var geo_aabb: AABB = _geometries[i].get_aabb()
		var local_pos: Vector3 = _owner.to_local(_geometries[i].global_position)
		geo_aabb.position += local_pos
		if i == 0:
			combined = geo_aabb
		else:
			combined = combined.merge(geo_aabb)

	_label.position = Vector3(combined.get_center().x, combined.end.y + 0.25, combined.get_center().z)
