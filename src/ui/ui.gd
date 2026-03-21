class_name UI
extends Control
## HUD panel shown while the player is holding a physics object.
##
## Displays a colour-coded power bar and hint labels.
## Call [method set_power] each frame to keep the bar in sync.


@onready var holding_object: Control = $HoldingObject
@onready var power_bar: ProgressBar = $HoldingObject/PowerBar


func _ready() -> void:
	holding_object.hide()


## Updates the bar fill and colour to reflect [param power] (0–1 range).
func set_power(power: float) -> void:
	power_bar.value = power * 100.0
	var style := power_bar.get_theme_stylebox("fill") as StyleBoxFlat
	style.bg_color = Color(power, 1.0 - power, 0.0)
