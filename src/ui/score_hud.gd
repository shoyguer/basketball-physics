class_name ScoreHUD
extends Control
## Top-right HUD panel showing how many of each ball type the player has scored.
##
## Each label is a plain counter (+1 per ball). The actual point total
## (distance × multiplier) is tracked by the hoop's own ScoreLabel.
## All three labels are always visible regardless of the throw-strength UI.


var _regular_count: int = 0
var _golden_count: int = 0
var _emerald_count: int = 0

@onready var _regular_label: Label = $Panel/VBox/Regular
@onready var _golden_label: Label = $Panel/VBox/Golden
@onready var _emerald_label: Label = $Panel/VBox/Emerald


func _ready() -> void:
	Signals.ball_scored.connect(_on_ball_scored)
	_update_labels()


## Increments the counter for the ball type that just scored.
func _on_ball_scored(ball_type: int, _distance_zone: int) -> void:
	match ball_type:
		PhysicsBall.BallType.REGULAR:
			_regular_count += 1
		PhysicsBall.BallType.GOLDEN:
			_golden_count += 1
		PhysicsBall.BallType.EMERALD:
			_emerald_count += 1
	_update_labels()


func _update_labels() -> void:
	_regular_label.text = "Regular: %d" % _regular_count
	_golden_label.text = "Golden: %d" % _golden_count
	_emerald_label.text = "Emerald: %d" % _emerald_count
