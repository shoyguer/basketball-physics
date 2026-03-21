@tool
class_name PhysicsBox
extends RigidBody3D
## A physics-enabled crate the player can grab and throw.
##
## Supports the grab system by exposing [method grab],
## [method on_grabbed], and [method on_released]. Also shows
## an outline and billboard label when the player looks at it.


## Size of the box in metres.
@export var box_size: Vector3 = Vector3(0.5, 0.5, 0.5):
	set(value):
		box_size = value
		if is_node_ready():
			_apply_size()

var _highlight := InteractableHelper.new()


func _ready() -> void:
	_apply_size()
	if not Engine.is_editor_hint():
		_highlight.setup(self, "[E] Grab")


## Updates collision and mesh to match [member box_size].
func _apply_size() -> void:
	var col_shape: CollisionShape3D = $CollisionShape3D as CollisionShape3D
	var box_shape := BoxShape3D.new()
	box_shape.size = box_size
	col_shape.shape = box_shape

	var csg: CSGBox3D = $CSGBox3D as CSGBox3D
	csg.size = box_size


## Called when the player picks this object up.
func grab() -> void:
	pass


## Called when this object is carried by the player.
func on_grabbed() -> void:
	_highlight.hide_highlight()


## Called when the player drops or launches this object.
func on_released() -> void:
	pass


## Enables the outline and billboard label.
func show_highlight() -> void:
	_highlight.show_highlight()


## Disables the outline and billboard label.
func hide_highlight() -> void:
	_highlight.hide_highlight()
