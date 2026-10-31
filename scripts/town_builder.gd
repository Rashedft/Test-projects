class_name TownBuilder
extends RefCounted

var world: Node3D
func _init(owner_node: Node3D) -> void:
	world = owner_node

func material(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	return m

func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.mesh = shape
	n.position = pos
	n.material_override = material(color)
	parent.add_child(n)
	return n

func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, collision: bool = false) -> Node3D:
	var shape = BoxMesh.new()
	shape.size = size
	var result = mesh(parent,shape,pos,color)
	if collision:
		var body = StaticBody3D.new()
		var c = CollisionShape3D.new()
		var b = BoxShape3D.new()
		b.size = size
		c.shape = b
		body.add_child(c)
		result.add_child(body)
	return result

func sphere(parent: Node3D, pos: Vector3, scale_v: Vector3, color: Color) -> MeshInstance3D:
	var s = SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	var n = mesh(parent,s,pos,color)
	n.scale = scale_v
	return n

func label3d(parent: Node3D, text: String, pos: Vector3, size: int = 40) -> void:
	var l = Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.008
	l.outline_size = 10
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)

func human(parent: Node3D, color: Color) -> Node3D:
	var model = Node3D.new()
	parent.add_child(model)
	sphere(model,Vector3(0,0.9,0),Vector3(0.6,0.85,0.4),color)
	sphere(model,Vector3(0,1.52,0),Vector3.ONE*0.49,Color("edc9a6"))
	sphere(model,Vector3(0,1.73,0.02),Vector3(0.55,0.23,0.5),Color("30394f"))
	for x in [-0.18,0.18]:
		box(model,Vector3(0.2,0.55,0.22),Vector3(x,0.3,0),Color("34475e"))
	return model

func creature(parent: Node3D, id: int) -> Node3D:
	var model = Node3D.new()
	parent.add_child(model)
	var color = Color(Game.species[str(id)].color)
	var body = sphere(model,Vector3(0,0.55,0),Vector3(0.7,0.8,0.6),color)
	body.name = "Body"
	sphere(model,Vector3(0,0.98,-0.07),Vector3(0.66,0.58,0.58),color)
	for x in [-0.17,0.17]:
		sphere(model,Vector3(x,1.04,-0.32),Vector3(0.085,0.12,0.05),Color("222333"))
		sphere(model,Vector3(x,0.13,-0.04),Vector3(0.26,0.2,0.36),color)
	if id in [25,26]:
		for x in [-0.22,0.22]:
			var ear = box(model,Vector3(0.15,0.65,0.14),Vector3(x,1.47,0),color)
			ear.rotation.z = -x
			sphere(model,Vector3(x,0.89,-0.32),Vector3.ONE*0.14,Color("dd523b"))
		box(model,Vector3(0.17,0.65,0.16),Vector3(0.4,0.65,0.27),color).rotation.z = -0.65
	elif id in [1,2]:
		sphere(model,Vector3(0,0.85,0.3),Vector3(0.7,0.65,0.65),Color("33775c"))
	elif id in [4,5]:
		sphere(model,Vector3(0,0.4,0.55),Vector3(0.22,0.25,0.8),color)
		sphere(model,Vector3(0,0.54,0.85),Vector3(0.22,0.4,0.22),Color("ffc35a"))
	elif id in [7,8]:
		sphere(model,Vector3(0,0.55,0.23),Vector3(0.78,0.8,0.4),Color("8b684d"))
	elif id==16:
		for x in [-0.4,0.4]: sphere(model,Vector3(x,0.6,0),Vector3(0.5,0.23,0.6),color.darkened(0.2))
	return model

func building(pos: Vector3, title: String, roof_color: Color) -> void:
	box(world,Vector3(5,3,4),pos+Vector3(0,1.5,0),Color("f0e3c7"),true)
	var roof = PrismMesh.new()
	roof.size = Vector3(5.8,1.8,4.8)
	mesh(world,roof,pos+Vector3(0,3.8,0),roof_color)
	box(world,Vector3(1,1.9,0.08),pos+Vector3(0,0.95,2.05),Color("50646d"))
	for x in [-1.7,1.7]:
		box(world,Vector3(0.9,0.9,0.1),pos+Vector3(x,1.8,2.07),Color("a6d8e5"))
	label3d(world,title,pos+Vector3(0,4.9,0),35)

func npc(pos: Vector3, name_text: String, kind: String, color: Color) -> void:
	var n = human(world,color)
	n.position = pos
	label3d(n,name_text,Vector3(0,2.15,0),30)
	world.npcs.append({"node":n,"kind":kind,"name":name_text})

func build_environment() -> void:
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("90bbcf")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("d4e3e5")
	e.ambient_light_energy = 0.3
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-25,0)
	sun.light_color = Color("fff0cf")
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	world.add_child(sun)
	box(world,Vector3(52,0.5,68),Vector3(0,-0.25,-8),Color("79a76a"),true)
	box(world,Vector3(5,0.03,57),Vector3(0,0.02,-6),Color("cfbf9a"))
	box(world,Vector3(28,0.035,4),Vector3(0,0.03,3),Color("cfbf9a"))
	building(Vector3(-8,0,0),"YOUR HOME",Color("b55e53"))
	building(Vector3(8,0,-8),"OAK'S LAB",Color("54878f"))
	building(Vector3(8,0,8),"FIELD STATION / PC",Color("a55465"))
	npc(Vector3(8,0,-4.2),"Professor Oak","oak",Color("f2eee0"))
	npc(Vector3(-8,0,3.2),"Mom","mom",Color("b86186"))
	npc(Vector3(8,0,11.2),"Nurse / PC","heal",Color("e8a6ac"))
	npc(Vector3(-6,0,11),"Field supplies","shop",Color("b9a34e"))
	npc(Vector3(-4,0,-17),"Mira · field researcher","rival",Color("627ac1"))
	label3d(world,"PALLET TOWN",Vector3(0,2,14),48)
	label3d(world,"ROUTE 1 · FIELD AREA",Vector3(0,2,-23),38)
	for i in range(45):
		var x = [-1,1][i%2] * randf_range(17,23)
		var z = randf_range(-37,20)
		box(world,Vector3(0.7,2.5,0.7),Vector3(x,1.25,z),Color("78624a"),true)
		for h in [2.7,3.7]: sphere(world,Vector3(x,h,z),Vector3(3,2.4,3),Color("477d57"))
	for i in range(150):
		var pos = Vector3(randf_range(-10,10),0.18,randf_range(-35,-24))
		box(world,Vector3(0.12,0.45,0.12),pos,Color("44874c"))
	for i in range(40):
		var pos = Vector3(randf_range(-15,15),0.12,randf_range(7,20))
		sphere(world,pos,Vector3.ONE*0.15,Color("f2d58c") if i%2 else Color("e5b8cd"))
	# Soft world boundaries prevent walking out of the playable area.
	for side in [-1,1]: box(world,Vector3(1,3,68),Vector3(side*25,1,-8),Color("537957"),true)
	for z in [-41,25]: box(world,Vector3(52,3,1),Vector3(0,1,z),Color("537957"),true)
	world.player = CharacterBody3D.new()
	world.player.name = "Player"
	world.add_child(world.player)
	world.player.position = Vector3(0,0.1,6)
	var c = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	c.shape = capsule
	c.position.y = 0.85
	world.player.add_child(c)
	human(world.player,Color("527db4"))
	world.camera = Camera3D.new()
	world.camera.fov = 43
	world.camera.far = 160
	world.add_child(world.camera)
	world.camera.position = world.player.position+Vector3(0,15,19)
	world.camera.look_at(world.player.position+Vector3(0,0,-2))
