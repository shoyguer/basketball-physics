extends Node3D
## Interactable game mode selector console for Room 2.
##
## Allows the player to switch between Free Play and Timed Challenge modes.
## Displays the current mode on a 3D label above the console.


## Scene containing the mode selection UI popup.
const MODE_UI_SCENE: PackedScene = preload("res://ui/mode_selection_ui.tscn")


var _highlight := InteractableHelper.new()
var _current_mode: int = 0
var _modes: Array[String] = ["Free Play", "Timed Challenge (120s)"]
var _mode_ui: CanvasLayer = null

@onready var _label3d: Label3D = $Label3D


func _ready() -> void:
	if not Engine.is_editor_hint():
		_highlight.setup(self, "[E] Select Mode")
		_update_label()
		
		_mode_ui = MODE_UI_SCENE.instantiate()
		_mode_ui.get_node("Control").mode_selected.connect(_on_mode_selected)
		get_tree().root.call_deferred("add_child", _mode_ui)


## Handles interaction by showing the mode selection UI.
func interact() -> void:
	if _mode_ui and not _mode_ui.get_node("Control").visible:
		_mode_ui.get_node("Control").show_ui()


## Handles mode selection by updating the label and starting/stopping timed mode.
func _on_mode_selected(mode_index: int) -> void:
	_current_mode = mode_index
	_update_label()
	
	match _current_mode:
		0:
			if GameManager.timed_mode_active:
				GameManager.stop_timed_mode()
		1:
			if not GameManager.timed_mode_active:
				GameManager.start_timed_mode(120.0)


## Updates the 3D label to show the current mode name.
func _update_label() -> void:
	_label3d.text = _modes[_current_mode]


## Shows the interaction highlight.
func show_highlight() -> void:
	_highlight.show_highlight()


## Hides the interaction highlight.
func hide_highlight() -> void:
	_highlight.hide_highlight()
