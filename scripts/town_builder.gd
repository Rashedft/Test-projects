class_name TownBuilder
extends RefCounted

var world: Node3D
var art = CharacterArt.new()
var scenery_rng = RandomNumberGenerator.new()
var shared_materials: Dictionary = {}
func _init(owner_node: Node3D) -> void:
	world = owner_node
	scenery_rng.seed = 78214

func material(color: Color) -> StandardMaterial3D:
	var key = color.to_html()
	if shared_materials.has(key): return shared_materials[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = color.srgb_to_linear()
	m.roughness = 0.92
	shared_materials[key] = m
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
	s.radial_segments = 16
	s.rings = 8
	var n = mesh(parent,s,pos,color)
	n.scale = scale_v
	return n

func label3d(parent: Node3D, text: String, pos: Vector3, size: int = 40) -> void:
	var l = Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.005
	l.visibility_range_end = 28
	l.outline_size = 10
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)

func human(parent: Node3D, color: Color, role: String = "player") -> Node3D:
	return art.human(parent,color,role)

func creature(parent: Node3D, id: int) -> Node3D:
	return art.creature(parent,id)

func bake_static(root: Node3D) -> void:
	# Merge static primitive surfaces by material, preserving independent collision.
	var surfaces: Dictionary = {}
	var materials: Dictionary = {}
	for child in root.get_children():
		if not child is MeshInstance3D or not child.visible: continue
		var key = child.material_override.get_instance_id()
		if not surfaces.has(key):
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			surfaces[key] = st
			materials[key] = child.material_override
		for surface in range(child.mesh.get_surface_count()):
			surfaces[key].append_from(child.mesh,surface,root.global_transform.affine_inverse()*child.global_transform)
		for attached in child.get_children():
			if attached is StaticBody3D: attached.reparent(root,true)
		root.remove_child(child)
		child.queue_free()
	for key in surfaces:
		var merged = MeshInstance3D.new()
		merged.name = "BakedSurface"
		merged.mesh = surfaces[key].commit()
		merged.material_override = materials[key]
		root.add_child(merged)

func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, top: float = -1) -> MeshInstance3D:
	var c = CylinderMesh.new()
	c.bottom_radius = radius
	c.top_radius = radius if top<0 else top
	c.height = height
	c.radial_segments = 12
	return mesh(parent,c,at,color)

func instances(parent: Node3D, geometry: Mesh, transforms: Array, color: Color) -> MultiMeshInstance3D:
	var batch = MultiMeshInstance3D.new()
	var multi = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = geometry
	multi.instance_count = transforms.size()
	for i in range(transforms.size()): multi.set_instance_transform(i,transforms[i])
	batch.multimesh = multi
	batch.material_override = material(color)
	parent.add_child(batch)
	return batch

func building(pos: Vector3, title: String, roof_color: Color) -> void:
	var home = Node3D.new()
	home.name = "Building_"+title.validate_node_name()
	home.position = pos
	world.add_child(home)
	box(home,Vector3(5,2.7,4),Vector3(0,1.35,0),Color("e6d9bb"),true)
	# Stone foundation, timber corners, plaster courses and rain gutters.
	box(home,Vector3(5.12,0.38,4.12),Vector3(0,0.19,0),Color("8c9488"))
	for y in [0.48,2.48,2.72]: box(home,Vector3(5.14,0.12,4.15),Vector3(0,y,0),Color("c5b88f"))
	for x in [-2.44,2.44]:
		for z in [-1.94,1.94]: box(home,Vector3(0.15,2.4,0.15),Vector3(x,1.45,z),Color("a59b7b"))
	var roof = PrismMesh.new()
	roof.size = Vector3(5.8,1.5,4.9)
	mesh(home,roof,Vector3(0,3.45,0),roof_color.darkened(0.15))
	# Instanced ceramic tiles follow both sloping roof planes (three material batches).
	for variation in range(3):
		var tiles: Array = []
		for side in [-1,1]:
			for row in range(6):
				for col in range(11):
					if (row+col)%3!=variation: continue
					var x = side*(0.24+row*0.48)
					var transform = Transform3D(Basis(Vector3.FORWARD,side*0.48),Vector3(x,4.27-absf(x)*0.51,-2.3+col*0.46))
					tiles.append(transform)
		var tile = BoxMesh.new()
		tile.size = Vector3(0.53,0.09,0.49)
		instances(home,tile,tiles,roof_color.lightened(variation*0.035))
	box(home,Vector3(0.18,0.18,5.05),Vector3(0,4.3,0),roof_color.darkened(0.2))
	for x in [-2.95,2.95]: box(home,Vector3(0.13,0.15,5.05),Vector3(x,2.83,0),Color("ded3b5"))
	# Chimney, warm framed glazing, muntins, shutters and planter boxes.
	box(home,Vector3(0.55,1.4,0.65),Vector3(-1.5,3.8,-1.05),Color("a28773"))
	box(home,Vector3(0.7,0.14,0.8),Vector3(-1.5,4.52,-1.05),Color("817565"))
	for x in [-1.65,1.65]:
		box(home,Vector3(1.02,1.05,0.17),Vector3(x,1.61,2.03),Color("f4e8ca"))
		box(home,Vector3(0.8,0.84,0.04),Vector3(x,1.63,2.13),Color("81b0b4"))
		for offset in [-0.52,0.52]:
			box(home,Vector3(0.24,1.02,0.12),Vector3(x+offset,1.63,2.12),roof_color.darkened(0.05))
			for y in [1.3,1.48,1.66,1.84]: box(home,Vector3(0.22,0.025,0.04),Vector3(x+offset,y,2.2),roof_color.lightened(0.1))
		box(home,Vector3(0.055,0.88,0.06),Vector3(x,1.63,2.17),Color("eee2bf"))
		box(home,Vector3(0.85,0.055,0.06),Vector3(x,1.63,2.17),Color("eee2bf"))
		box(home,Vector3(1.0,0.19,0.38),Vector3(x,1.0,2.16),Color("957b5a"))
		for offset in [-0.32,0,0.32]:
			sphere(home,Vector3(x+offset,1.15,2.2),Vector3(0.33,0.23,0.28),Color("628456"))
			sphere(home,Vector3(x+offset,1.29,2.22),Vector3.ONE*0.13,Color("d49c8b"))
	box(home,Vector3(1.14,2.02,0.17),Vector3(0,1.02,2.03),Color("f1e4c9"))
	box(home,Vector3(0.88,1.83,0.05),Vector3(0,0.96,2.14),Color("796955"))
	box(home,Vector3(0.64,0.66,0.04),Vector3(0,1.35,2.18),Color("88b3b3"))
	box(home,Vector3(0.045,0.66,0.05),Vector3(0,1.35,2.21),Color("ede0bd"))
	sphere(home,Vector3(0.3,0.83,2.2),Vector3.ONE*0.075,Color("d5bc75"))
	for step in range(3): box(home,Vector3(1.6+step*0.12,0.08,0.3),Vector3(0,0.18-step*0.045,2.18+step*0.3),Color("b6b5a3"))
	box(home,Vector3(1.8,0.12,0.85),Vector3(0,2.32,2.3),roof_color)
	for x in [-0.84,0.84]: cylinder(home,Vector3(x,1.2,2.62),0.045,2.2,Color("d6c8a4"))
	# Sign uses real world scale and fades at distance, rather than giant floating lettering.
	box(home,Vector3(2.3,0.42,0.1),Vector3(0,2.7,2.65),Color("546a61"))
	label3d(home,title,Vector3(0,2.7,2.72),28)
	# Round attic window on the front gable.
	cylinder(home,Vector3(0,3.48,2.49),0.26,0.04,Color("e6d5ad")).rotation.x = PI/2
	cylinder(home,Vector3(0,3.48,2.52),0.19,0.045,Color("76989f")).rotation.x = PI/2
	bake_static(home)

func tree(parent: Node3D, pos: Vector3, scale_v: float = 1.0, collision: bool = true) -> void:
	var root = Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE*scale_v
	parent.add_child(root)
	cylinder(root,Vector3(0,1.2,0),0.26,2.4,Color("796b4c"),0.15)
	if collision: box(root,Vector3(0.6,2.4,0.6),Vector3(0,1.2,0),Color("796b4c"),true).hide()
	for side in [-1,1]:
		var branch = cylinder(root,Vector3(side*0.3,2.0,0),0.11,1.3,Color("796b4c"),0.06)
		branch.rotation.z = -side*0.6
	var leaf_colors = [Color("638b58"),Color("729660"),Color("7a9d64")]
	for i in range(7):
		var angle = i*2.4
		var radius = 0.7 if i>0 else 0.0
		sphere(root,Vector3(sin(angle)*radius,2.6+(i%3)*0.5,cos(angle)*radius),Vector3(2.4,1.8,2.3),leaf_colors[i%3])
	bake_static(root)

func fence(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var length_v = a.distance_to(b)
	var forward = (b-a).normalized()
	for i in range(int(length_v/0.65)+1):
		var pos = a+forward*(i*0.65)
		box(parent,Vector3(0.1,0.72,0.1),pos+Vector3(0,0.36,0),Color("dcd8be"))
		var cap = cylinder(parent,pos+Vector3(0,0.75,0),0.08,0.12,Color("e5dfc4"),0)
		cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for y in [0.28,0.57]:
		var rail = box(parent,Vector3(0.07,0.075,length_v),(a+b)*0.5+Vector3(0,y,0),Color("dcd8be"))
		rail.rotation.y = atan2(forward.x,forward.z)

func flowers(parent: Node3D, center: Vector3, count: int, radius: float, color: Color) -> void:
	var petals: Array = []
	var leaves: Array = []
	for i in range(count):
		var angle = scenery_rng.randf()*TAU
		var pos = center+Vector3(cos(angle),0,sin(angle))*sqrt(scenery_rng.randf())*radius
		for p in range(5): petals.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.12,0.065,0.09)),pos+Vector3(sin(p*TAU/5)*0.075,0.16,cos(p*TAU/5)*0.075)))
		leaves.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.26,0.08,0.2)),pos+Vector3(0,0.065,0)))
	var s = SphereMesh.new()
	s.radius = 0.5
	s.height = 1
	s.radial_segments = 8
	s.rings = 4
	instances(parent,s,petals,color)
	instances(parent,s,leaves,Color("6f8e59"))

func grass_patch(parent: Node3D, center: Vector3, count: int, size: Vector2) -> void:
	var blades: Array = []
	for i in range(count):
		var at = center+Vector3(scenery_rng.randf_range(-size.x/2,size.x/2),0,scenery_rng.randf_range(-size.y/2,size.y/2))
		for side in range(3): blades.append(Transform3D(Basis(Vector3.UP,side*PI/3).scaled(Vector3.ONE*scenery_rng.randf_range(0.8,1.3)),at))
	var geometry = PrismMesh.new()
	geometry.size = Vector3(0.18,0.55,0.025)
	var batch = instances(parent,geometry,blades,Color("60844e"))
	var shader = ShaderMaterial.new()
	shader.shader = load("res://shaders/grass.gdshader")
	batch.material_override = shader

func road(parent: Node3D, center: Vector3, size: Vector2) -> void:
	box(parent,Vector3(size.x,0.025,size.y),center,Color("b7af8d"))
	for variant in range(3):
		var transforms: Array = []
		for x in range(int(size.x/0.6)):
			for z in range(int(size.y/0.44)):
				if (x+z)%3!=variant: continue
				var at = center+Vector3(-size.x/2+0.3+x*0.6,0.025,-size.y/2+0.22+z*0.44)
				if size.x>10 and size.y<5 and absf(at.x)<2.5: continue
				transforms.append(Transform3D(Basis.IDENTITY,at))
		var tile = BoxMesh.new()
		tile.size = Vector3(0.57,0.04,0.4)
		instances(parent,tile,transforms,Color("cfbea0").lightened(variant*0.025)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func lamp(at: Vector3) -> void:
	cylinder(world,at+Vector3(0,1.05,0),0.045,2.1,Color("56695e"))
	box(world,Vector3(0.25,0.35,0.25),at+Vector3(0,2.17,0),Color("ead9ab"))
	box(world,Vector3(0.36,0.08,0.36),at+Vector3(0,2.38,0),Color("596c60"))
	for x in [-0.15,0.15]: box(world,Vector3(0.035,0.36,0.035),at+Vector3(x,2.17,-0.15),Color("596c60"))

func pond() -> void:
	var center = Vector3(-14,0.015,17)
	var shore = cylinder(world,center,4.4,0.06,Color("b3ae8c"))
	shore.scale.z = 0.8
	var water = cylinder(world,center+Vector3(0,0.04,0),3.9,0.03,Color("669eaa"))
	water.scale.z = 0.8
	var shader = ShaderMaterial.new()
	shader.shader = load("res://shaders/water.gdshader")
	water.material_override = shader
	box(world,Vector3(7.5,1,5.4),center+Vector3(0,-0.05,0),Color("669eaa"),true).hide()
	for i in range(20):
		var a = i*TAU/20
		sphere(world,center+Vector3(cos(a)*4.1,0.07,sin(a)*3.3),Vector3(0.6,0.35,0.45),Color("a2a28c"))
	flowers(world,center+Vector3(-2.5,0,-2.5),20,1.2,Color("d3bd83"))

func battle_arena(parent: Node3D, show_pads: bool = true) -> void:
	box(parent,Vector3(48,0.35,40),Vector3(100,-0.2,-4),Color("83a26d"))
	for at in ([Vector3(97,0.01,3),Vector3(103,0.01,-3)] if show_pads else []):
		cylinder(parent,at,2.5,0.08,Color("c9b993"))
		cylinder(parent,at+Vector3(0,0.04,0),2.25,0.025,Color("d3c69f"))
	fence(parent,Vector3(88,0,-10),Vector3(113,0,-10))
	for i in range(9): tree(parent,Vector3(87+i*3.4,0,-13-(i%2)*2),1.4,false)
	grass_patch(parent,Vector3(100,0.04,-7),180,Vector2(23,3))
	flowers(parent,Vector3(91,0,1),20,2,Color("e1ba8b"))
	flowers(parent,Vector3(109,0,-6),20,2,Color("d6a4a1"))

func npc(pos: Vector3, name_text: String, kind: String, color: Color) -> void:
	var n = human(world,color,kind)
	n.position = pos
	label3d(n,name_text,Vector3(0,2.15,0),30)
	world.npcs.append({"node":n,"kind":kind,"name":name_text})

func build_environment() -> void:
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("78a5c5")
	sky_mat.sky_horizon_color = Color("d7e4de")
	sky_mat.ground_horizon_color = Color("d7e4de")
	sky_mat.ground_bottom_color = Color("a4b998")
	var sky = Sky.new()
	sky.sky_material = sky_mat
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("d9e2d4")
	e.ambient_light_energy = 0.38
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = Color("b7cfc3")
	e.fog_density = 0.003
	e.fog_sky_affect = 0.1
	env.environment = e
	world.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-32,0)
	sun.light_color = Color("fff0d1")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 60
	sun.shadow_blur = 1.8
	sun.shadow_bias = 0.2
	sun.shadow_normal_bias = 3.0
	RenderingServer.directional_shadow_atlas_set_size(4096,false)
	world.add_child(sun)
	box(world,Vector3(72,0.5,94),Vector3(0,-0.25,-8),Color("88a96e"),true)
	road(world,Vector3(0,0.02,-6),Vector2(4.8,57))
	road(world,Vector3(0,0.023,3),Vector2(28,3.2))
	road(world,Vector3(8,0.025,-0.5),Vector2(1.7,6.5))
	road(world,Vector3(8,0.025,7),Vector2(1.7,8))
	building(Vector3(-8,0,0),"HOME",Color("b36a5b"))
	building(Vector3(8,0,-8),"OAK LABORATORY",Color("648f99"))
	building(Vector3(8,0,8),"FIELD STATION",Color("b86e77"))
	building(Vector3(-11,0,-12),"PALLET COTTAGE",Color("899773"))
	for x in [-12,-4]: fence(world,Vector3(x,0,-3),Vector3(x,0,4.7))
	fence(world,Vector3(-12,0,4.7),Vector3(-9.8,0,4.7))
	fence(world,Vector3(-6.3,0,4.7),Vector3(-4,0,4.7))
	for x in [4.7,11.5]: fence(world,Vector3(x,0,6),Vector3(x,0,12.8))
	flowers(world,Vector3(-10.5,0,3.5),28,1.0,Color("d3959d"))
	flowers(world,Vector3(-5,0,3.5),20,0.8,Color("e3cb8c"))
	flowers(world,Vector3(11.8,0,-6.2),28,1.3,Color("b6a6cc"))
	pond()
	for at in [Vector3(-3,0,5),Vector3(3,0,-11),Vector3(4,0,12)]: lamp(at)
	# Timber bench and crates anchor the researcher/supply areas.
	box(world,Vector3(1.8,0.12,0.55),Vector3(-5.5,0.45,8),Color("a28b66"))
	box(world,Vector3(1.8,0.48,0.1),Vector3(-5.5,0.78,8.25),Color("a28b66"))
	for x in [-6.2,-4.8]: box(world,Vector3(0.1,0.45,0.45),Vector3(x,0.22,8),Color("627263"))
	for x in [-7.1,-6.3]:
		box(world,Vector3(0.65,0.6,0.6),Vector3(x,0.3,11.7),Color("a58a5e"))
		for y in [0.1,0.5]: box(world,Vector3(0.69,0.065,0.64),Vector3(x,y,11.7),Color("7b6e51"))
	npc(Vector3(8,0,-4.2),"Professor Oak","oak",Color("e5e2cf"))
	npc(Vector3(-8,0,3.2),"Mom","mom",Color("ba788d"))
	npc(Vector3(8,0,11.2),"Nurse / PC","heal",Color("d7a3a5"))
	npc(Vector3(-6,0,11),"Field supplies","shop",Color("b6a175"))
	npc(Vector3(-4,0,-17),"Mira","rival",Color("7c91b3"))
	for side in [-1,1]:
		for i in range(17): tree(world,Vector3(side*scenery_rng.randf_range(18,23),0,-37+i*3.7),scenery_rng.randf_range(0.9,1.3))
	for i in range(9): tree(world,Vector3(-21+i*5.2,0,-39),1.4)
	for side in [-1,1]:
		for i in range(6): sphere(world,Vector3(side*(30+i*3),0,-35-i*7),Vector3(22,14+float(i%3)*3,20),Color("71947b"))
	grass_patch(world,Vector3(0,0.18,-29.5),700,Vector2(20,11))
	# Northern field sign and a low hedge boundary retain the original playable limits.
	for x in [-2.9,2.9]: cylinder(world,Vector3(x,0.7,-21),0.12,1.4,Color("9b8962"))
	box(world,Vector3(2.0,0.55,0.12),Vector3(-4.6,1,-21),Color("d6c79e"))
	label3d(world,"ROUTE 1",Vector3(-4.6,1,-20.9),32)
	for side in [-1,1]: box(world,Vector3(1,3,68),Vector3(side*25,1,-8),Color("71925e"),true).hide()
	for z in [-41,25]: box(world,Vector3(52,3,1),Vector3(0,1,z),Color("71925e"),true).hide()
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
	world.camera.fov = 39
	world.camera.far = 160
	world.add_child(world.camera)
	world.camera.position = world.player.position+Vector3(0,10.5,13.5)
	world.camera.look_at(world.player.position+Vector3(0,0.5,-1.2))
