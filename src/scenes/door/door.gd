class_name Door
extends Node3D
## A swinging door the player can open and close.
##
## Uses a Tween to smoothly rotate the door panel around its hinge pivot.
## Pressing interact toggles between the open and closed states.


## Fired whenever the door finishes moving to a new state.
signal state_changed(new_state: State)

## Represents the two stable states the door can be in.
enum State {
	## Door is fully closed.
	CLOSED,
	## Door is fully open.
	OPEN,
}

## Rotation angle in degrees the door swings to when fully open.
const OPEN_ANGLE: float = 90.0
## Duration in seconds of the open and close swing animation.
const SWING_DURATION: float = 0.5
## If this door should start open or closed.
@export var start_open: bool = false

var _state: State = State.CLOSED
var _is_moving: bool = false
var _tween: Tween = null
var _highlight := InteractableHelper.new()

@onready var _door_body: AnimatableBody3D = $DoorBody


func _ready() -> void:
	_highlight.setup(self, "[E] Open")

	if start_open:
		_state = State.OPEN
		_door_body.rotation_degrees.y = OPEN_ANGLE


## Toggles the door between open and closed when the player interacts.
func interact() -> void:
	if _is_moving: return

	if _state == State.CLOSED:
		_swing_to(State.OPEN, OPEN_ANGLE)
	else:
		_swing_to(State.CLOSED, 0.0)


## Animates the hinge rotation to the target angle and updates the state.
func _swing_to(target_state: State, target_angle: float) -> void:
	_is_moving = true

	if _tween: _tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(_door_body, "rotation_degrees:y", target_angle, SWING_DURATION)
	_tween.tween_callback(_on_tween_finished.bind(target_state))


func _on_tween_finished(arrived_state: State) -> void:
	_state = arrived_state
	_is_moving = false

	if arrived_state == State.OPEN:
		_door_body.collision_layer = 2
		_highlight.set_label_text("[E] Close")
	else:
		_door_body.collision_layer = 1
		_highlight.set_label_text("[E] Open")

	state_changed.emit(_state)


## Enables the outline and billboard label.
func show_highlight() -> void:
	_highlight.show_highlight()


## Disables the outline and billboard label.
func hide_highlight() -> void:
	_highlight.hide_highlight()
