extends Node
## Autoload for Signal bus.
## 
## This holds global signals used throughout the game.


## Emitted by BasketballHoop each time a ball scores.
## ball_type matches PhysicsBall.BallType (0 = REGULAR, 1 = GOLDEN, 2 = EMERALD).
## distance_zone is 1 (close), 2 (mid), or 3 (far).
@warning_ignore("unused_signal")
signal ball_scored(ball_type: int, distance_zone: int)
