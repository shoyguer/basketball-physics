@tool
class_name PhysicsBall
extends RigidBody3D
## A physics-enabled rubber ball the player can grab and throw.
##
## Supports the grab system by exposing [method grab],
## [method on_grabbed], and [method on_released]. Also shows
## an outline and billboard label when the player looks at it.


## Radius of the ball in metres.
@export var ball_radius: float = 0.25:
	set(value):
		ball_radius = value
		if is_node_ready():
			_apply_size()

var _highlight := InteractableHelper.new()


func _ready() -> void:
	_apply_size()
	if not Engine.is_editor_hint():
		_highlight.setup(self, "[E] Grab")


## Updates collision and mesh to match [member ball_radius].
func _apply_size() -> void:
	var col_shape: CollisionShape3D = $CollisionShape3D as CollisionShape3D
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = ball_radius
	col_shape.shape = sphere_shape

	var csg: CSGSphere3D = $CSGSphere3D as CSGSphere3D
	csg.radius = ball_radius


## Called when the player picks this object up.
func on_grabbed() -> void:
	_highlight.hide_highlight()


## Enables the outline and billboard label.
func show_highlight() -> void:
	_highlight.show_highlight()


## Disables the outline and billboard label.
func hide_highlight() -> void:
	_highlight.hide_highlight()
