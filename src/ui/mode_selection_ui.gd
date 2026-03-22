class_name ModeSelectionUI
extends Control
## Popup UI for selecting game mode.
##
## Displays a modal panel with buttons for each available game mode.
## When a mode is selected, starts a countdown before emitting the selection signal.


## Emitted when a game mode is selected after the countdown completes.
signal mode_selected(mode_index: int)


## Duration of the countdown before starting the selected mode.
const COUNTDOWN_DURATION: float = 3.0


var _selected_mode: int = -1
var _countdown: float = 0.0
var _modes: Array[String] = ["Free Play", "Timed Challenge (120s)"]

@onready var _panel: PanelContainer = $Panel
@onready var _mode_buttons: VBoxContainer = $Panel/VBox/ModeButtons
@onready var _countdown_label: Label = $Panel/VBox/CountdownLabel
@onready var _timer: Timer = $Timer


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	hide()
	_create_mode_buttons()
	Signals.timed_mode_started.connect(_on_timed_mode_started)


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_timer.stop()
		if _timer.timeout.is_connected(_on_countdown_tick):
			_timer.timeout.disconnect(_on_countdown_tick)
		hide()
		GameManager.ui_is_open = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


## Shows the mode selection UI and enables mouse interaction.
func show_ui() -> void:
	_selected_mode = -1
	_countdown_label.hide()
	_panel.show()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GameManager.ui_is_open = true
	
	for btn: Button in _mode_buttons.get_children():
		btn.disabled = false


func _create_mode_buttons() -> void:
	for i: int in _modes.size():
		var btn := Button.new()
		btn.text = _modes[i]
		btn.add_theme_font_size_override("font_size", 32)
		btn.pressed.connect(_on_mode_button_pressed.bind(i))
		_mode_buttons.add_child(btn)


## Handles mode button press by starting the selection countdown.
func _on_mode_button_pressed(mode_index: int) -> void:
	_selected_mode = mode_index
	
	for btn: Button in _mode_buttons.get_children():
		btn.disabled = true
	
	_countdown = COUNTDOWN_DURATION
	_countdown_label.text = "Starting in %.0f..." % _countdown
	_countdown_label.show()
	
	_timer.wait_time = 1.0
	_timer.start()
	_timer.timeout.connect(_on_countdown_tick)


## Updates the countdown each tick and starts the mode when reaching zero.
func _on_countdown_tick() -> void:
	_countdown -= 1.0
	
	if _countdown <= 0:
		_timer.stop()
		_timer.timeout.disconnect(_on_countdown_tick)
		_countdown_label.text = "Starting now!"
		
		mode_selected.emit(_selected_mode)
		hide()
		GameManager.ui_is_open = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		_countdown_label.text = "Starting in %.0f..." % _countdown


## Closes the UI if timed mode starts externally.
func _on_timed_mode_started(_duration: float) -> void:
	if visible:
		hide()
		GameManager.ui_is_open = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
