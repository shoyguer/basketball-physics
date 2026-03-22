extends Node
## Autoload for Signal bus.
## 
## This holds global signals used throughout the game.


## Emitted by BasketballHoop each time a ball scores.
## ball_type matches PhysicsBall.BallType (0 = REGULAR, 1 = GOLDEN, 2 = EMERALD).
## distance_zone is 1 (close), 2 (mid), or 3 (far).
@warning_ignore("unused_signal")
signal ball_scored(ball_type: int, distance_zone: int)

## Emitted when a shot is attempted (ball launched).
@warning_ignore("unused_signal")
signal shot_attempted()

## Emitted when streak changes.
@warning_ignore("unused_signal")
signal streak_changed(streak: int)

## Emitted when accuracy changes (value 0-100).
@warning_ignore("unused_signal")
signal accuracy_changed(accuracy: float)

## Emitted when timed mode state changes.
@warning_ignore("unused_signal")
signal timed_mode_started(duration: float)

## Emitted each second during timed mode.
@warning_ignore("unused_signal")
signal timed_mode_tick(time_left: float)

## Emitted when timed mode ends.
@warning_ignore("unused_signal")
signal timed_mode_ended(final_score: int)
