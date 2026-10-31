class_name BattleEffects
extends Node3D

var rng = RandomNumberGenerator.new()
func _ready() -> void: rng.seed = 9167

func effect_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func sphere(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2
	mesh.radial_segments = 8
	mesh.rings = 4
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node

func play_hit(event: Dictionary, source: Vector3, target: Vector3, delay: float) -> void:
	var color = Color({"electric":"ffe89a","fire":"f1a06b","water":"8cd4e9","grass":"acd889","dark":"b394c0","flying":"d4e4e5"}.get(event.get("type","normal"),"fff7df"))
	color.a = 0.9
	var material = effect_material(color)
	var root = Node3D.new()
	root.name = "MoveEffect"
	root.position = to_local(target)
	root.hide()
	add_child(root)
	if event.get("kind","")=="status":
		var torus = TorusMesh.new()
		torus.inner_radius = 0.57
		torus.outer_radius = 0.64
		torus.rings = 24
		torus.ring_segments = 8
		var ring = MeshInstance3D.new()
		ring.mesh = torus
		ring.material_override = material
		ring.rotation.x = PI/2
		root.add_child(ring)
	else:
		for i in range(12):
			var angle = i*TAU/12
			var pos = Vector3(cos(angle),sin(angle),rng.randf_range(-0.3,0.3))*rng.randf_range(0.25,0.55)
			sphere(root,pos,0.06 if i%2 else 0.09,material)
		if event.get("type","")=="electric":
			var start = root.to_local(source)
			for i in range(8):
				var a = start.lerp(Vector3.ZERO,i/8.0)+Vector3(0,sin(i*3.9)*0.22,0)
				var b = start.lerp(Vector3.ZERO,(i+1)/8.0)+Vector3(0,sin((i+1)*3.9)*0.22,0)
				var c = CylinderMesh.new()
				c.top_radius = 0.025
				c.bottom_radius = 0.025
				c.height = a.distance_to(b)
				c.radial_segments = 6
				var bolt = MeshInstance3D.new()
				bolt.mesh = c
				bolt.material_override = material
				bolt.position = (a+b)*0.5
				bolt.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
				root.add_child(bolt)
	var tween = root.create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(root.show)
	tween.tween_property(material,"albedo_color:a",0.0,0.5)
	tween.tween_callback(root.queue_free)
