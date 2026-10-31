class_name CharacterArt
extends RefCounted

# Original mesh designs authored for Poke Journey. No ROM/model extraction.
var mats: Dictionary = {}
var balls: Dictionary = {}
var outline: ShaderMaterial

func mat(hex: String, emission: bool = false) -> StandardMaterial3D:
	var key = hex+str(emission)
	if mats.has(key): return mats[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(hex).srgb_to_linear()
	m.roughness = 0.85
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	if emission:
		m.emission_enabled = true
		m.emission = Color(hex).srgb_to_linear()
		m.emission_energy_multiplier = 0.5
	if not emission:
		if outline==null:
			outline = ShaderMaterial.new()
			outline.shader = load("res://shaders/character_outline.gdshader")
		m.next_pass = outline
	mats[key] = m
	return m

func shape(parent: Node3D, geometry: Mesh, at: Vector3, color: String) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.mesh = geometry
	n.material_override = mat(color)
	n.position = at
	parent.add_child(n)
	return n

func ell(parent: Node3D, at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var sphere: SphereMesh
	if balls.has("smooth"): sphere = balls.smooth
	else:
		sphere = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 20
		sphere.rings = 10
		balls.smooth = sphere
	var n = shape(parent,sphere,at,color)
	n.scale = size
	return n

func block(parent: Node3D, at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var b = BoxMesh.new()
	b.size = size
	return shape(parent,b,at,color)

func cone(parent: Node3D, at: Vector3, radius: float, height: float, color: String) -> MeshInstance3D:
	var c = CylinderMesh.new()
	c.top_radius = 0
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 12
	return shape(parent,c,at,color)

func tube(parent: Node3D, points: Array, radius: float, color: String) -> void:
	for i in range(points.size()-1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i+1]
		var direction = b-a
		var c = CylinderMesh.new()
		c.top_radius = radius*0.85
		c.bottom_radius = radius
		c.height = direction.length()
		c.radial_segments = 10
		var n = shape(parent,c,(a+b)*0.5,color)
		if direction.length()>0.001: n.quaternion = Quaternion(Vector3.UP,direction.normalized())
		ell(parent,b,Vector3.ONE*radius*1.7,color)

func polygon(parent: Node3D, points: Array, depth: float, color: String) -> void:
	# Extruded silhouette, with real side faces, used for ears and lightning tails.
	points = points.duplicate()
	var flat = PackedVector2Array()
	for p in points: flat.append(Vector2(p.x,p.y))
	if Geometry2D.is_polygon_clockwise(flat):
		points.reverse()
		flat.reverse()
	var triangles = Geometry2D.triangulate_polygon(flat)
	var vertices = PackedVector3Array()
	for side in [-1.0,1.0]:
		for p in points: vertices.append(Vector3(p.x,p.y,p.z+side*depth*0.5))
	var count = points.size()
	var indices = PackedInt32Array()
	for t in range(0,triangles.size(),3):
		var a = triangles[t]
		var b = triangles[t+1]
		var c = triangles[t+2]
		indices.append_array([a,c,b,a+count,b+count,c+count])
	for i in range(count):
		var next = (i+1)%count
		indices.append_array([i,next,count+next,i,count+next,count+i])
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,indices.size(),3):
		for index in [indices[i],indices[i+2],indices[i+1]]: st.add_vertex(vertices[index])
	st.generate_normals()
	shape(parent,st.commit(),Vector3.ZERO,color)

func eye(parent: Node3D, at: Vector3, size: Vector3, color: String = "222636", sclera: bool = false) -> Node3D:
	var root = Node3D.new()
	root.position = at
	parent.add_child(root)
	if sclera: ell(root,Vector3(0,0,0.018),size*1.25,"fffaf0")
	ell(root,Vector3.ZERO,size,color)
	ell(root,Vector3(-size.x*0.12,size.y*0.21,-size.z*0.45),size*Vector3(0.32,0.3,0.3),"ffffff")
	return root

func human(parent: Node3D, shirt: Color, role: String = "player") -> AnimatedActor:
	var rig = AnimatedActor.new()
	rig.name = "CharacterVisual"
	parent.add_child(rig)
	var skin = "efc6a2"
	var cloth = shirt.to_html(false)
	var dark = "293e56"
	if role=="oak": cloth = "e9e7d9"
	# Four-head chibi proportions, separate shoulder/hip pivots for walk cycles.
	ell(rig,Vector3(0,0.91,0),Vector3(0.58,0.72,0.37),cloth)
	ell(rig,Vector3(0,1.45,-0.03),Vector3(0.6,0.64,0.52),skin)
	ell(rig,Vector3(0,1.78,0.02),Vector3(0.62,0.23,0.54),"77766e" if role=="oak" else "49382f")
	for side in [-1.0,1.0]:
		ell(rig,Vector3(side*0.3,1.44,-0.03),Vector3(0.13,0.2,0.13),skin)
		var e = eye(rig,Vector3(side*0.125,1.49,-0.282),Vector3(0.072,0.11,0.035))
		rig.eyes.append(e)
		ell(rig,Vector3(side*0.13,1.57,-0.27),Vector3(0.1,0.025,0.035),"655141")
	ell(rig,Vector3(0,1.38,-0.3),Vector3(0.08,0.07,0.06),skin)
	block(rig,Vector3(0,1.31,-0.272),Vector3(0.1,0.018,0.022),"aa6d63")
	for side in [-1.0,1.0]:
		var leg = Node3D.new()
		leg.position = Vector3(side*0.16,0.65,0)
		rig.add_child(leg)
		ell(leg,Vector3(0,-0.24,0),Vector3(0.23,0.53,0.25),dark)
		ell(leg,Vector3(0,-0.51,-0.07),Vector3(0.25,0.17,0.38),"433d3c")
		block(leg,Vector3(0,-0.57,-0.07),Vector3(0.25,0.04,0.32),"dce0d4")
		rig.limbs.append(leg)
	for side in [-1.0,1.0]:
		var arm = Node3D.new()
		arm.position = Vector3(side*0.31,1.15,0)
		rig.add_child(arm)
		ell(arm,Vector3(side*0.035,-0.12,0),Vector3(0.2,0.36,0.23),cloth)
		ell(arm,Vector3(side*0.04,-0.34,-0.025),Vector3(0.16,0.27,0.17),skin if role!="oak" else cloth)
		ell(arm,Vector3(side*0.04,-0.48,-0.02),Vector3(0.17,0.19,0.17),skin)
		rig.limbs.append(arm)
	if role=="oak":
		for x in [-0.16,0.16]:
			block(rig,Vector3(x,0.78,-0.19),Vector3(0.18,0.2,0.025),"d2d4c5")
		block(rig,Vector3(0,1.08,-0.2),Vector3(0.11,0.28,0.03),"61695d")
		for y in [0.75,0.94,1.1]: ell(rig,Vector3(0.06,y,-0.22),Vector3.ONE*0.035,"b6aa8b")
	elif role in ["mom","heal"]:
		ell(rig,Vector3(0,0.7,0),Vector3(0.75,0.55,0.53),cloth)
		ell(rig,Vector3(0,1.51,0.16),Vector3(0.62,0.64,0.3),"714b3c" if role=="mom" else "c27883")
		block(rig,Vector3(0,0.9,-0.22),Vector3(0.31,0.42,0.02),"f4ead7")
		if role=="heal":
			ell(rig,Vector3(0,1.8,-0.02),Vector3(0.61,0.14,0.4),"fff8e4")
			block(rig,Vector3(0,1.79,-0.23),Vector3(0.13,0.04,0.025),"b95869")
			block(rig,Vector3(0,1.79,-0.23),Vector3(0.04,0.12,0.027),"b95869")
	else:
		# Hair fringe, original blue/red cap and an actual little backpack.
		for side in [-1.0,0.0,1.0]:
			var fringe = cone(rig,Vector3(side*0.17,1.68,-0.22),0.11,0.28,"49382f")
			fringe.rotation.z = PI
		ell(rig,Vector3(0,1.83,0.01),Vector3(0.68,0.2,0.56),"c05c57" if role=="player" else "798b65")
		ell(rig,Vector3(0,1.78,-0.29),Vector3(0.58,0.06,0.37),"c05c57" if role=="player" else "798b65")
		ell(rig,Vector3(0,0.99,0.28),Vector3(0.49,0.58,0.25),"b2874c")
		for x in [-0.2,0.2]: block(rig,Vector3(x,1.02,-0.19),Vector3(0.06,0.48,0.03),"6a4c37")
		block(rig,Vector3(0,0.8,0.44),Vector3(0.3,0.18,0.03),"9e7643")
	return rig

func foot(rig: AnimatedActor, at: Vector3, color: String, size: Vector3) -> void:
	var pivot = Node3D.new()
	pivot.position = at
	rig.add_child(pivot)
	ell(pivot,Vector3(0,-0.08,-0.045),size,color)
	rig.limbs.append(pivot)

func creature(parent: Node3D, id: int) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	var body = AnimatedActor.new()
	body.name = "Body"
	body.position.y = 0.55
	root.add_child(body)
	# Geometry is authored with its feet at y=0, then offset into the animated pivot.
	var model = AnimatedActor.new()
	model.position.y = -0.55
	body.add_child(model)
	match id:
		25,26: mouse(model,id==26)
		1,2: bulb(model,id==2)
		4,5: lizard(model,id==5)
		7,8: turtle(model,id==8)
		16: bird(model)
		19: rat(model)
	return root

func mouse(rig: AnimatedActor, evolved: bool) -> void:
	var color = "d69537" if evolved else "e8c342"
	var dark = "634a32" if evolved else "343039"
	ell(rig,Vector3(0,0.58,0.04),Vector3(0.67,0.85,0.52),color)
	ell(rig,Vector3(0,0.53,-0.19),Vector3(0.45,0.58,0.15),"f2dfb0" if evolved else "eed16b")
	ell(rig,Vector3(0,1.05,-0.08),Vector3(0.76,0.66,0.57),color)
	for side in [-1.0,1.0]:
		var ear = Node3D.new()
		ear.position = Vector3(side*0.25,1.28,-0.02)
		ear.rotation.z = -side*(0.6 if evolved else 0.26)
		rig.add_child(ear)
		ell(ear,Vector3(0,0.23,0),Vector3(0.19 if evolved else 0.16,0.63,0.1),dark if evolved else color)
		if not evolved: ell(ear,Vector3(0,0.46,0),Vector3(0.155,0.2,0.105),dark)
		ell(ear,Vector3(0,0.1,-0.04),Vector3(0.12,0.34,0.07),color)
		rig.eyes.append(eye(rig,Vector3(side*0.17,1.1,-0.353),Vector3(0.105,0.14,0.055)))
		ell(rig,Vector3(side*0.29,0.96,-0.32),Vector3(0.17,0.15,0.055),"f4d55b" if evolved else "ce5343")
		ell(rig,Vector3(side*0.34,0.63,-0.08),Vector3(0.23,0.4,0.23),color).rotation.z = side*0.38
		foot(rig,Vector3(side*0.2,0.17,0),dark if evolved else color,Vector3(0.27,0.2,0.4))
	ell(rig,Vector3(0,1.01,-0.39),Vector3(0.07,0.045,0.05),"3c3332")
	tube(rig,[Vector3(-0.08,0.94,-0.37),Vector3(0,0.915,-0.38),Vector3(0.08,0.94,-0.37)],0.012,"805130")
	for y in [0.46,0.65]: ell(rig,Vector3(0,y,0.295),Vector3(0.51,0.09,0.035),"8c5f36")
	var tail = Node3D.new()
	tail.position = Vector3(0.18,0.35,0.22)
	rig.add_child(tail)
	rig.tail = tail
	if evolved:
		tube(tail,[Vector3.ZERO,Vector3(0.45,0.1,0.22),Vector3(0.63,0.38,0.35),Vector3(0.64,0.65,0.32)],0.025,dark)
	var contour: Array = []
	for point in [Vector2(-0.05,0),Vector2(0.12,-0.03),Vector2(0.27,0.3),Vector2(0.43,0.23),Vector2(0.56,0.61),Vector2(0.75,0.55),Vector2(0.92,1.08),Vector2(0.49,1.17),Vector2(0.35,0.82),Vector2(0.48,0.77),Vector2(0.31,0.43),Vector2(0.17,0.5)]:
		var at: Vector2 = point*0.55+Vector2(0.55,0.47) if evolved else point
		contour.append(Vector3(at.x,at.y,0.04))
	polygon(tail,contour,0.07,color)

func bulb(rig: AnimatedActor, evolved: bool) -> void:
	var color = "559b8d" if evolved else "69b9a3"
	ell(rig,Vector3(0,0.42,0.1),Vector3(0.85,0.63,1.05),color)
	ell(rig,Vector3(0,0.62,-0.42),Vector3(0.93,0.67,0.73),color)
	for side in [-1.0,1.0]:
		cone(rig,Vector3(side*0.34,0.95,-0.34),0.13,0.32,color).rotation.z = -side*0.2
		var e = eye(rig,Vector3(side*0.26,0.68,-0.745),Vector3(0.15,0.19,0.055),"b64e62",true)
		rig.eyes.append(e)
		for z in [-0.34,0.4]:
			foot(rig,Vector3(side*0.3,0.23,z),color,Vector3(0.29,0.36,0.31))
			for offset in [-0.06,0.06]: ell(rig,Vector3(side*0.3+offset,0.08,z-0.15),Vector3(0.06,0.06,0.1),"f2e9cf")
		for y in [0.48,0.81]: ell(rig,Vector3(side*0.42,y,-0.43),Vector3(0.07,0.15,0.17),"37736a")
	tube(rig,[Vector3(-0.19,0.47,-0.76),Vector3(0,0.43,-0.78),Vector3(0.19,0.47,-0.76)],0.015,"386961")
	for side in [-1.0,1.0]: ell(rig,Vector3(side*0.2,0.48,-0.77),Vector3(0.05,0.07,0.03),"fff4d8")
	ell(rig,Vector3(0,0.88,0.24),Vector3(0.74,0.76,0.72),"4d895a")
	for angle in range(5):
		var a = angle*TAU/5
		var leaf = ell(rig,Vector3(sin(a)*0.25,1.04,0.24+cos(a)*0.25),Vector3(0.23,0.62,0.25),"659c58")
		leaf.rotation = Vector3(cos(a)*0.35,0,-sin(a)*0.35)
	if evolved:
		for side in [-1.0,1.0]: ell(rig,Vector3(side*0.39,1.0,0.25),Vector3(0.58,0.13,0.65),"448757")
		ell(rig,Vector3(0,1.44,0.25),Vector3(0.47,0.61,0.46),"c76b86")

func lizard(rig: AnimatedActor, evolved: bool) -> void:
	var color = "c45c43" if evolved else "e79b56"
	ell(rig,Vector3(0,0.56,0),Vector3(0.62,0.83,0.53),color)
	ell(rig,Vector3(0,0.52,-0.23),Vector3(0.39,0.61,0.1),"f0d5a0")
	ell(rig,Vector3(0,1.06,-0.04),Vector3(0.67,0.66,0.55),color)
	ell(rig,Vector3(0,0.92,-0.28),Vector3(0.51,0.31,0.38),color)
	for side in [-1.0,1.0]:
		rig.eyes.append(eye(rig,Vector3(side*0.22,1.13,-0.29),Vector3(0.13,0.2,0.055),"3e788a",true))
		ell(rig,Vector3(side*0.32,0.67,-0.03),Vector3(0.22,0.4,0.22),color).rotation.z = side*0.4
		foot(rig,Vector3(side*0.22,0.23,0.02),color,Vector3(0.31,0.34,0.48))
		for x in [-0.06,0.06]: ell(rig,Vector3(side*0.22+x,0.11,-0.2),Vector3(0.06,0.06,0.13),"f7e9d4")
		ell(rig,Vector3(side*0.12,0.97,-0.46),Vector3(0.03,0.025,0.02),"986b44")
	tube(rig,[Vector3(-0.17,0.85,-0.42),Vector3(0,0.82,-0.45),Vector3(0.17,0.85,-0.42)],0.012,"9b6241")
	if evolved: cone(rig,Vector3(0,1.48,0.13),0.16,0.45,color).rotation.x = -0.3
	var tail = Node3D.new()
	rig.add_child(tail)
	rig.tail = tail
	tube(tail,[Vector3(0,0.28,0.16),Vector3(0.17,0.25,0.51),Vector3(0.34,0.42,0.78),Vector3(0.39,0.7,0.9)],0.13,color)
	for i in range(3):
		var flame = ell(tail,Vector3(0.39+i*0.035,0.8+i*0.08,0.9),Vector3(0.24-i*0.04,0.42-i*0.07,0.2-i*0.03),["d66436","f2a348","f8d875"][i])
		flame.material_override = mat(["d66436","f2a348","f8d875"][i],true)

func turtle(rig: AnimatedActor, evolved: bool) -> void:
	var color = "729bbf" if evolved else "7ebbc3"
	ell(rig,Vector3(0,0.58,0.1),Vector3(0.8,0.86,0.61),"ead7a3")
	ell(rig,Vector3(0,0.6,0.26),Vector3(0.9,0.94,0.54),"efdfb1")
	ell(rig,Vector3(0,0.61,0.34),Vector3(0.77,0.82,0.45),"9d7050")
	for x in [-0.21,0,0.21]:
		tube(rig,[Vector3(x,0.3,0.51),Vector3(x*1.3,0.6,0.55),Vector3(x,0.93,0.47)],0.014,"71523e")
	for y in [0.46,0.7]: tube(rig,[Vector3(-0.3,y,0.48),Vector3(0,y,0.57),Vector3(0.3,y,0.48)],0.014,"71523e")
	for y in [0.43,0.64]: tube(rig,[Vector3(-0.27,y,-0.19),Vector3(0,y-0.02,-0.225),Vector3(0.27,y,-0.19)],0.014,"b8a377")
	ell(rig,Vector3(0,1.1,-0.1),Vector3(0.78,0.67,0.62),color)
	ell(rig,Vector3(0,0.98,-0.32),Vector3(0.6,0.25,0.3),color)
	for side in [-1.0,1.0]:
		rig.eyes.append(eye(rig,Vector3(side*0.23,1.18,-0.36),Vector3(0.15,0.24,0.055),"7a514e",true))
		ell(rig,Vector3(side*0.41,0.65,0),Vector3(0.26,0.44,0.28),color).rotation.z = side*0.5
		foot(rig,Vector3(side*0.27,0.23,0.02),color,Vector3(0.35,0.32,0.45))
		if evolved:
			var ear = ell(rig,Vector3(side*0.43,1.41,0),Vector3(0.22,0.6,0.11),"c5e0e8")
			ear.rotation.z = -side*0.52
	tube(rig,[Vector3(-0.16,0.91,-0.43),Vector3(0,0.88,-0.46),Vector3(0.16,0.91,-0.43)],0.012,"507c88")
	var tail = Node3D.new()
	rig.add_child(tail)
	rig.tail = tail
	tube(tail,[Vector3(0,0.3,0.38),Vector3(0.16,0.31,0.7),Vector3(0.27,0.52,0.79),Vector3(0.17,0.65,0.72),Vector3(0.06,0.55,0.66)],0.12,"b5d8e3" if evolved else color)

func bird(rig: AnimatedActor) -> void:
	rig.winged = true
	ell(rig,Vector3(0,0.49,0.02),Vector3(0.64,0.75,0.61),"ac8d65")
	ell(rig,Vector3(0,0.45,-0.22),Vector3(0.46,0.55,0.16),"ecddb3")
	ell(rig,Vector3(0,0.94,-0.09),Vector3(0.63,0.61,0.55),"b19772")
	for side in [-1.0,1.0]:
		ell(rig,Vector3(side*0.22,0.94,-0.22),Vector3(0.27,0.31,0.23),"eee0b9")
		rig.eyes.append(eye(rig,Vector3(side*0.2,1.0,-0.345),Vector3(0.09,0.12,0.04)))
		tube(rig,[Vector3(side*0.09,1.09,-0.34),Vector3(side*0.28,1.04,-0.31)],0.04,"6b5949")
		var wing = Node3D.new()
		wing.position = Vector3(side*0.3,0.65,0.08)
		rig.add_child(wing)
		for i in range(4): ell(wing,Vector3(side*(i*0.045),-i*0.07,i*0.08),Vector3(0.26,0.38,0.21),"8d7457" if i%2 else "b49b78")
		rig.limbs.append(wing)
		for digit in [-0.06,0,0.06]: tube(rig,[Vector3(side*0.16,0.2,0),Vector3(side*0.16+digit,0.08,-0.2)],0.022,"bd7772")
	var beak = cone(rig,Vector3(0,0.9,-0.43),0.11,0.27,"c68b75")
	beak.rotation.x = -PI/2
	for i in range(3): ell(rig,Vector3((i-1)*0.12,1.2,0.04),Vector3(0.15,0.26,0.4),"907451")
	for i in range(3): ell(rig,Vector3((i-1)*0.13,0.44,0.48),Vector3(0.17,0.18,0.61),"806a51")

func rat(rig: AnimatedActor) -> void:
	ell(rig,Vector3(0,0.38,0.14),Vector3(0.68,0.64,1.0),"9974aa")
	ell(rig,Vector3(0,0.59,-0.38),Vector3(0.75,0.66,0.68),"9974aa")
	ell(rig,Vector3(0,0.43,-0.62),Vector3(0.53,0.3,0.3),"e4d3af")
	for side in [-1.0,1.0]:
		ell(rig,Vector3(side*0.31,0.94,-0.22),Vector3(0.36,0.4,0.15),"9974aa")
		ell(rig,Vector3(side*0.31,0.94,-0.31),Vector3(0.23,0.26,0.04),"c996a9")
		rig.eyes.append(eye(rig,Vector3(side*0.22,0.68,-0.66),Vector3(0.13,0.16,0.04),"a75b69",true))
		block(rig,Vector3(side*0.07,0.32,-0.75),Vector3(0.11,0.16,0.04),"fff3da")
		for z in [-0.36,0.41]: foot(rig,Vector3(side*0.25,0.13,z),"d4b4aa",Vector3(0.23,0.19,0.33))
		for y in [0.43,0.51]: tube(rig,[Vector3(side*0.2,y,-0.71),Vector3(side*0.58,y+0.04,-0.63)],0.012,"d8c9ba")
	ell(rig,Vector3(0,0.51,-0.78),Vector3(0.13,0.08,0.06),"b57587")
	var tail = Node3D.new()
	rig.add_child(tail)
	rig.tail = tail
	tube(tail,[Vector3(0,0.27,0.45),Vector3(0.2,0.25,0.74),Vector3(0.48,0.43,0.86),Vector3(0.45,0.7,0.77),Vector3(0.2,0.74,0.72)],0.045,"a481ae")
