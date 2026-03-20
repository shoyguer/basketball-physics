class_name BasketballHoop
extends Node3D
## A basketball hoop that awards points when balls pass through the rim.
##
## Tracks the score and spawns a golden ball reward once the target
## is reached. Only downward-moving [PhysicsBall] instances count.


## Points needed to earn the golden ball reward.
const TARGET_SCORE: int = 10
## Scene to instantiate as the golden ball.
const GOLDEN_BALL_SCENE: PackedScene = preload("res://scenes/objects/golden_ball.tscn")

## Path to the node whose position is used for spawning the golden ball.
@export var spawn_path: NodePath = NodePath("")

var _score: int = 0
var _reward_given: bool = false
var _recent_balls: Array[RigidBody3D] = []

@onready var _score_label: Label3D = $ScoreLabel
@onready var _score_zone: Area3D = $ScoreZone


func _ready() -> void:
	_update_label()
	_score_zone.body_entered.connect(_on_body_entered_score_zone)


## Awards a point when a ball falls through the hoop.
func _on_body_entered_score_zone(body: Node3D) -> void:
	if not body is PhysicsBall: return

	var ball: RigidBody3D = body as RigidBody3D
	if ball in _recent_balls: return
	if ball.linear_velocity.y >= 0.0: return

	_recent_balls.append(ball)
	_score += 1
	_update_label()

	get_tree().create_timer(2.0).timeout.connect(_clear_recent.bind(ball))

	if _score >= TARGET_SCORE and not _reward_given:
		_reward_given = true
		_spawn_golden_ball()


## Removes a ball from the cooldown list so it can score again.
func _clear_recent(ball: RigidBody3D) -> void:
	_recent_balls.erase(ball)


## Instantiates the golden ball at the configured spawn location.
func _spawn_golden_ball() -> void:
	if spawn_path.is_empty(): return

	var spawn_node: Node3D = get_node(spawn_path) as Node3D

	var ball: Node3D = GOLDEN_BALL_SCENE.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_position = spawn_node.global_position


## Updates the score label text.
func _update_label() -> void:
	_score_label.text = "Score: %d" % [_score]
