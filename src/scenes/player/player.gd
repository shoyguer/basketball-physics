class_name Player
extends CharacterBody3D
## First-person player controller with interaction and grab support.
##
## Handles movement, mouse look, a short-range raycast for highlighting
## nearby interactables, and a Portal 2 style grab system that lets the
## player pick up, carry, drop, and launch physics objects.


#region Properties
## Emitted when the player looks at a new interactable object.
signal interactable_focused(target: Node3D)
## Emitted when the player stops looking at any interactable.
signal interactable_unfocused

## Movement speed in metres per second.
const SPEED: float = 5.0
## Sprint multiplier applied on top of [constant SPEED].
const SPRINT_MULTIPLIER: float = 1.6
## Jump impulse strength.
const JUMP_FORCE: float = 4.5
## Mouse sensitivity scale for look input.
const MOUSE_SENSITIVITY: float = 0.002

## Maximum interaction reach in metres.
const INTERACT_REACH: float = 3.0
## Hold distance when launch power is at maximum (object pulled close).
const HOLD_DISTANCE_NEAR: float = 0.6
## Hold distance when launch power is at minimum (object pushed far).
const HOLD_DISTANCE_FAR: float = 1.0
## How far to the right the held object drifts from screen-centre.
const HOLD_RIGHT_OFFSET: float = 0.4
## Speed at which the right-offset eases in after a grab (1/s).
const HOLD_SIDE_EASE: float = 4.0
## Spring stiffness for the held object pull.
const HOLD_SPRING: float = 40.0
## Damping factor to prevent oscillation while holding.
const HOLD_DAMP: float = 8.0

## Impulse strength when the player walks into a rigid body.
const PUSH_FORCE: float = 2.0
## Minimum impulse when launching at zero power.
const LAUNCH_FORCE_MIN: float = 0.5
## Maximum impulse when launching at full power.
const LAUNCH_FORCE_MAX: float = 25.0
## How much each scroll tick changes the launch power (0 to 1 range).
const SCROLL_STEP: float = 0.025
## How much launch power drops per second while an object is held.
const POWER_DECAY: float = 0.02

## Multiplier for gravity.
@export var gravity_scale: float = 1.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _focused_interactable: Node3D = null
var _held_object: RigidBody3D = null
var _held_previous_gravity: float = 0.0
var _launch_power: float = 0.5
var _hold_side_t: float = 0.0

@onready var _camera: Camera3D = $CameraPivot/Camera3D
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _interact_ray: RayCast3D = $CameraPivot/Camera3D/InteractRay
@onready var _hold_ui: UI = $HUD/UI
#endregion


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if GameManager.ui_is_open: return
	
	if event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			return

	_handle_mouse_look(event)
	_handle_scroll(event)

	if event.is_action_pressed("interact"):
		_handle_interact_press()

	if event.is_action_pressed("launch"):
		_launch_held_object()

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _physics_process(delta: float) -> void:
	if GameManager.ui_is_open: return
	
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()
	move_and_slide()
	_push_rigid_bodies()
	_update_interact_ray()
	_update_held_object(delta)


#region Movement
## Rotates the camera on mouse motion.
func _handle_mouse_look(event: InputEvent) -> void:
	if not event is InputEventMouseMotion: return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: return

	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	rotate_y(-motion.relative.x * MOUSE_SENSITIVITY)
	_camera_pivot.rotate_x(-motion.relative.y * MOUSE_SENSITIVITY)
	_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -1.48, 1.48)


## Applies gravity to vertical velocity each physics frame.
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * gravity_scale * delta


## Applies a jump impulse when the player is grounded and presses jump.
func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_FORCE


## Translates movement input into horizontal velocity.
func _handle_movement() -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed: float = SPEED * (SPRINT_MULTIPLIER if Input.is_action_pressed("sprint") else 1.0)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
#endregion


#region Interaction
## Decides whether to grab, drop, or interact based on the current state.
func _handle_interact_press() -> void:
	if _held_object:
		_drop_held_object()
		return

	if not _focused_interactable: return

	if _focused_interactable.has_method("grab"):
		_grab_object(_focused_interactable as RigidBody3D)
	elif _focused_interactable.has_method("interact"):
		_focused_interactable.interact()


## Checks the raycast each frame and updates the focused interactable.
func _update_interact_ray() -> void:
	if _held_object:
		_set_focused(null)
		return

	if not _interact_ray.is_colliding():
		_set_focused(null)
		return

	var hit: Node3D = _interact_ray.get_collider() as Node3D
	if not hit:
		_set_focused(null)
		return

	var interactable: Node3D = _find_interactable(hit)
	_set_focused(interactable)


## Walks up the node tree to find the nearest ancestor that is interactable.
func _find_interactable(node: Node3D) -> Node3D:
	var current: Node = node
	while current:
		if current.has_method("interact") or current.has_method("grab"):
			return current as Node3D
		current = current.get_parent()
	return null


## Updates the focused interactable reference and toggles highlight.
func _set_focused(target: Node3D) -> void:
	if target == _focused_interactable: return

	if _focused_interactable != null and _focused_interactable.has_method("hide_highlight"):
		_focused_interactable.hide_highlight()

	_focused_interactable = target

	if _focused_interactable != null and _focused_interactable.has_method("show_highlight"):
		_focused_interactable.show_highlight()

	if target != null:
		interactable_focused.emit(target)
	else:
		interactable_unfocused.emit()
#endregion


#region Grab System
## Picks up a RigidBody3D and starts carrying it in front of the camera.
func _grab_object(body: RigidBody3D) -> void:
	_held_object = body
	_held_previous_gravity = body.gravity_scale

	body.gravity_scale = 0.0
	body.add_collision_exception_with(self)

	if body.has_method("on_grabbed"):
		body.on_grabbed()

	if body is PhysicsBall:
		body.launch_position = Vector3.ZERO

	_launch_power = 0.5
	_hold_side_t = 0.0
	_hold_ui.holding_object.show()
	_hold_ui.set_power(_launch_power)
	_set_focused(null)


## Releases the currently held object, restoring its physics state.
func _drop_held_object() -> void:
	if not _held_object: return

	_held_object.gravity_scale = _held_previous_gravity
	_held_object.remove_collision_exception_with(self)

	if _held_object is PhysicsBall:
		(_held_object as PhysicsBall).launch_position = global_position

	if _held_object.has_method("on_released"):
		_held_object.on_released()

	_held_object = null
	_hold_ui.holding_object.hide()


## Launches the held object forward with force based on the power meter.
func _launch_held_object() -> void:
	if not _held_object: return

	var launch_dir: Vector3 = -_camera.global_transform.basis.z
	var force: float = LAUNCH_FORCE_MIN + (LAUNCH_FORCE_MAX - LAUNCH_FORCE_MIN) * _launch_power
	var body: RigidBody3D = _held_object

	_drop_held_object()
	body.apply_central_impulse(launch_dir * force)
	
	# Track shot attempt
	Signals.shot_attempted.emit()


## Applies an impulse to any rigid body the player walks into.
func _push_rigid_bodies() -> void:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision3D = get_slide_collision(i)
		var collider: Node = collision.get_collider()
		if collider is RigidBody3D:
			var body: RigidBody3D = collider as RigidBody3D
			var push_dir: Vector3 = -collision.get_normal()
			body.apply_central_impulse(push_dir * PUSH_FORCE)


## Pulls the held object toward the hold point using a spring-damper system.
func _update_held_object(delta: float) -> void:
	if not _held_object: return

	_launch_power = maxf(_launch_power - POWER_DECAY * delta, 0.0)
	_hold_ui.set_power(_launch_power)

	_hold_side_t = minf(_hold_side_t + HOLD_SIDE_EASE * delta, 1.0)

	var hold_distance: float = lerpf(HOLD_DISTANCE_FAR, HOLD_DISTANCE_NEAR, _launch_power)

	var right_offset: Vector3 = _camera.global_transform.basis.x * HOLD_RIGHT_OFFSET * _hold_side_t
	var hold_point: Vector3 = _camera.global_position + (-_camera.global_transform.basis.z * hold_distance) + right_offset
	var offset: Vector3 = hold_point - _held_object.global_position
	var spring_force: Vector3 = offset * HOLD_SPRING - _held_object.linear_velocity * HOLD_DAMP
	_held_object.apply_central_force(spring_force * _held_object.mass)
	_held_object.angular_velocity = Vector3.ZERO


## Adjusts launch power with the mouse scroll wheel.
func _handle_scroll(event: InputEvent) -> void:
	if not _held_object: return
	if not event is InputEventMouseButton: return

	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed: return

	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		_launch_power = minf(_launch_power + SCROLL_STEP, 1.0)
	elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_launch_power = maxf(_launch_power - SCROLL_STEP, 0.0)
	else:
		return

	_hold_ui.set_power(_launch_power)
#endregion
