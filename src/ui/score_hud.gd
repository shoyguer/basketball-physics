class_name ScoreHUD
extends Control
## Top-right HUD panel showing stats: ball counts, streak, accuracy, and timed mode.


var _regular_count: int = 0
var _golden_count: int = 0
var _emerald_count: int = 0

@onready var _regular_label: Label = $Panel/VBox/Regular
@onready var _golden_label: Label = $Panel/VBox/Golden
@onready var _emerald_label: Label = $Panel/VBox/Emerald
@onready var _streak_label: Label = $Panel/VBox/Streak
@onready var _accuracy_label: Label = $Panel/VBox/Accuracy
@onready var _timed_panel: PanelContainer = $TimedPanel
@onready var _time_label: Label = $TimedPanel/VBox/TimeLabel
@onready var _timed_score_label: Label = $TimedPanel/VBox/TimedScore


func _ready() -> void:
	Signals.ball_scored.connect(_on_ball_scored)
	Signals.streak_changed.connect(_on_streak_changed)
	Signals.accuracy_changed.connect(_on_accuracy_changed)
	Signals.timed_mode_started.connect(_on_timed_mode_started)
	Signals.timed_mode_tick.connect(_on_timed_mode_tick)
	Signals.timed_mode_ended.connect(_on_timed_mode_ended)
	_update_labels()
	_timed_panel.hide()


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


func _on_streak_changed(streak: int) -> void:
	_streak_label.text = "Streak: %d" % streak
	# Highlight streak with color
	if streak >= 5:
		_streak_label.modulate = Color(1, 0.5, 0, 1)  # Orange
	elif streak >= 3:
		_streak_label.modulate = Color(1, 0.84, 0, 1)  # Gold
	else:
		_streak_label.modulate = Color(1, 1, 1, 1)  # White


func _on_accuracy_changed(accuracy: float) -> void:
	_accuracy_label.text = "Accuracy: %.0f%%" % accuracy


func _on_timed_mode_started(_duration: float) -> void:
	_timed_panel.show()
	_regular_count = 0
	_golden_count = 0
	_emerald_count = 0
	_update_labels()


func _on_timed_mode_tick(time_left: float) -> void:
	_time_label.text = "Time: %.0f" % time_left
	_timed_score_label.text = "Score: %d" % GameManager.timed_mode_score


func _on_timed_mode_ended(final_score: int) -> void:
	_timed_panel.hide()
	# Show a brief summary - this could be expanded to a full modal
	print("Timed mode ended! Final score: %d (High: %d)" % [final_score, GameManager.high_score])


func _update_labels() -> void:
	_regular_label.text = "Regular: %d" % _regular_count
	_golden_label.text = "Golden: %d" % _golden_count
	_emerald_label.text = "Emerald: %d" % _emerald_count
