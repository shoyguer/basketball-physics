extends Node
## Manages game stats, streak tracking, and timed mode.


#region Stats
var total_shots_attempted: int = 0
var total_shots_made: int = 0
var current_streak: int = 0
var best_streak: int = 0
var accuracy: float = 0.0
#endregion

#region Timed Mode
const DEFAULT_DURATION: float = 120.0
var timed_mode_active: bool = false
var timed_mode_duration: float = DEFAULT_DURATION
var time_remaining: float = 0.0
var timed_mode_score: int = 0
var high_score: int = 0

var _timer: Timer = null
var _tick_timer: Timer = null
#endregion


## Set to true when a modal UI is open, preventing player movement and input.
var ui_is_open: bool = false


func _ready() -> void:
	Signals.ball_scored.connect(_on_ball_scored)
	Signals.shot_attempted.connect(_on_shot_attempted)


func _on_shot_attempted() -> void:
	total_shots_attempted += 1
	_update_accuracy()


func _on_ball_scored(_ball_type: int, _distance_zone: int) -> void:
	total_shots_made += 1
	current_streak += 1
	if current_streak > best_streak:
		best_streak = current_streak
	
	_update_accuracy()
	Signals.streak_changed.emit(current_streak)
	
	if timed_mode_active:
		timed_mode_score += 1


## Call this when a shot misses (ball hits ground or goes out of bounds without scoring)
func break_streak() -> void:
	if current_streak > 0:
		current_streak = 0
		Signals.streak_changed.emit(0)

func _update_accuracy() -> void:
	if total_shots_attempted > 0:
		accuracy = (float(total_shots_made) / float(total_shots_attempted)) * 100.0
	else:
		accuracy = 0.0
	Signals.accuracy_changed.emit(accuracy)

## Starts a timed mode session with the given duration in seconds.
func start_timed_mode(duration: float = DEFAULT_DURATION) -> void:
	if timed_mode_active: return
	
	timed_mode_duration = duration
	time_remaining = duration
	timed_mode_score = 0
	timed_mode_active = true
	
	total_shots_attempted = 0
	total_shots_made = 0
	current_streak = 0
	accuracy = 0.0
	Signals.streak_changed.emit(0)
	Signals.accuracy_changed.emit(0.0)
	
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = duration
	_timer.timeout.connect(_end_timed_mode)
	add_child(_timer)
	_timer.start()
	
	_tick_timer = Timer.new()
	_tick_timer.one_shot = false
	_tick_timer.wait_time = 1.0
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)
	_tick_timer.start()
	
	Signals.timed_mode_started.emit(duration)


func _on_tick() -> void:
	time_remaining -= 1.0
	Signals.timed_mode_tick.emit(time_remaining)
	
	if time_remaining <= 0:
		_tick_timer.stop()
		_tick_timer.queue_free()
		_tick_timer = null


func _end_timed_mode() -> void:
	timed_mode_active = false
	if timed_mode_score > high_score:
		high_score = timed_mode_score
	Signals.timed_mode_ended.emit(timed_mode_score)


func stop_timed_mode() -> void:
	if _timer:
		_timer.stop()
		_timer.queue_free()
		_timer = null
	if _tick_timer:
		_tick_timer.stop()
		_tick_timer.queue_free()
		_tick_timer = null
	_end_timed_mode()


## Resets all stats (for new game)
func reset_stats() -> void:
	total_shots_attempted = 0
	total_shots_made = 0
	current_streak = 0
	accuracy = 0.0
	Signals.streak_changed.emit(0)
	Signals.accuracy_changed.emit(0.0)
