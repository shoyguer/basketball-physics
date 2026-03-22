class_name ParticleBurst
extends Node3D
## A reusable glowing particle burst effect for scoring feedback.
##
## Pre-positioned in the hoop scene and triggered via [method play]
## when a successful shot is made. Restarts particle emission and light flash.


@onready var _particles: CPUParticles3D = $CPUParticles3D


func _ready() -> void:
	_particles.emitting = false


## Triggers the particle burst and light flash effect.
func play() -> void:
	_particles.restart()
	
	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.8, 0.2)
	light.light_energy = 0.8
	light.omni_range = 2.0
	add_child(light)
	
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.3)
	tween.finished.connect(light.queue_free)
