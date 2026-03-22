class_name BasketballHoop
extends Node3D
## A basketball hoop that awards points when balls pass through the rim.
##
## Uses a two-zone gate system: the ball must enter TopZone moving downward
## to become a candidate, then pass through BottomZone to confirm the score.
## Reaching [constant GOLDEN_SCORE] spawns a golden ball reward.
## Reaching [constant EMERALD_SCORE] spawns an emerald ball reward.




## Points needed to earn the golden ball reward.
const GOLDEN_SCORE: int = 10
## Points needed to earn the emerald ball reward.
const EMERALD_SCORE: int = 25
## Seconds before a ball can score again after a successful shot.
const SCORE_COOLDOWN: float = 1.0
## Scene to instantiate as the golden ball.
const GOLDEN_BALL_SCENE: PackedScene = preload("res://scenes/objects/ball/golden_ball.tscn")
## Scene to instantiate as the emerald ball.
const EMERALD_BALL_SCENE: PackedScene = preload("res://scenes/objects/ball/emerald_ball.tscn")

const MID_SHOT_Z: float = -13.6
const NEAR_SHOT_Z: float = -11.5

## Node to spawn the golden ball at when the reward is earned.
@export var spawn_node: Marker3D = null

var _score: int = 0
var _reward_given: bool = false
var _emerald_given: bool = false
var _recent_balls: Array[RigidBody3D] = []
var _candidates: Array[RigidBody3D] = []

@onready var _score_label: Label3D = $ScoreLabel
@onready var _top_zone: Area3D = $TopZone
@onready var _bottom_zone: Area3D = $BottomZone
@onready var _score_vfx: ParticleBurst = $ScoreVFX


func _ready() -> void:
	_update_label()
	_top_zone.body_entered.connect(_on_top_zone_entered)
	_top_zone.body_exited.connect(_on_top_zone_exited)
	_bottom_zone.body_entered.connect(_on_bottom_zone_entered)


## Marks the ball as a scoring candidate when it enters the rim from above.
func _on_top_zone_entered(body: Node3D) -> void:
	if not body is PhysicsBall: return
	var ball: PhysicsBall = body as PhysicsBall
	if ball.is_held: return
	if ball.linear_velocity.y < 0.0 and ball not in _candidates:
		_candidates.append(ball)


## Cancels candidacy if the ball bounces back up through the top zone.
func _on_top_zone_exited(body: Node3D) -> void:
	if not body is PhysicsBall: return
	var ball: RigidBody3D = body as RigidBody3D
	if ball in _candidates and ball.linear_velocity.y >= 0.0:
		_candidates.erase(ball)


## Scores a point when a candidate ball exits through the bottom of the rim.
func _on_bottom_zone_entered(body: Node3D) -> void:
	if not body is PhysicsBall: return
	var pb: PhysicsBall = body as PhysicsBall
	if pb.is_held or pb not in _candidates or pb in _recent_balls: return

	_candidates.erase(pb)
	_recent_balls.append(pb)

	var distance_zone: int = _get_distance_zone(pb)
	var multiplier: int = _get_multiplier(pb.ball_type)
	_score += distance_zone * multiplier
	_update_label()

	Signals.ball_scored.emit(pb.ball_type, distance_zone)

	_spawn_score_vfx()

	get_tree().create_timer(SCORE_COOLDOWN).timeout.connect(_clear_recent.bind(pb))

	if _score >= GOLDEN_SCORE and not _reward_given:
		_reward_given = true
		_spawn_golden_ball()

	if _score >= EMERALD_SCORE and not _emerald_given:
		_emerald_given = true
		_spawn_emerald_ball()


## Removes a ball from the cooldown list so it can score again.
func _clear_recent(ball: RigidBody3D) -> void:
	_recent_balls.erase(ball)


## Instantiates the golden ball at the configured spawn location.
func _spawn_golden_ball() -> void:
	if not spawn_node: return
	var ball: Node3D = GOLDEN_BALL_SCENE.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_position = spawn_node.global_position


## Instantiates the emerald ball at the configured spawn location.
func _spawn_emerald_ball() -> void:
	if not spawn_node: return
	var ball: Node3D = EMERALD_BALL_SCENE.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_position = spawn_node.global_position


## Updates the score label text.
func _update_label() -> void:
	_score_label.text = "Score: %d" % [_score]


## Returns the score multiplier for the given BallType.
func _get_multiplier(ball_type: int) -> int:
	match ball_type:
		PhysicsBall.BallType.GOLDEN:
			return 2
		PhysicsBall.BallType.EMERALD:
			return 5
		_:
			return 1


## Returns the distance zone (1–3) based on where the ball was last released.
## Separators in Room 2 sit at z = –11.5 (far), –13.6 (mid), –15.9 (near hoop).
## 1 pt: shot from near the hoop, so from first separator forward.
## 2 pts: mid-court shot, so after second separator but before third separator.
## 3 pts: long shot from far end, so anything behind last separator.
func _get_distance_zone(ball: PhysicsBall) -> int:
	var z: float = ball.launch_position.z
	if z <= MID_SHOT_Z:
		return 1
	elif z <= NEAR_SHOT_Z:
		return 2
	return 3


## Triggers the score VFX particle burst.
func _spawn_score_vfx() -> void:
	_score_vfx.play()
