class_name AnimatedActor
extends Node3D

var walking = 0.0
var phase = 0.0
var limbs: Array[Node3D] = []
var tail: Node3D
var eyes: Array[Node3D] = []
var winged = false

func _process(delta: float) -> void:
	phase += delta
	var stride = sin(phase*10.0)*walking
	for i in range(limbs.size()):
		limbs[i].rotation.x = stride * (0.48 if i%2==0 else -0.48)
	if is_instance_valid(tail): tail.rotation.y = sin(phase*2.7)*0.12 + stride*0.12
	var blink = 0.12 if fmod(phase,4.7)>4.55 else 1.0
	for eye in eyes: eye.scale.y = blink
	if winged:
		for i in range(limbs.size()): limbs[i].rotation.z = sin(phase*3.5)*0.09 * (-1 if i%2 else 1)
