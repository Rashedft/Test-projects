extends SceneTree
var checks = 0
var failures = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: "+label)
	else:
		failures += 1
		push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func mesh_bounds(node: Node) -> AABB:
	var result = AABB()
	if node is MeshInstance3D: result = node.global_transform*node.get_aabb()
	for child in node.get_children(): result = result.merge(mesh_bounds(child))
	return result
func run() -> void:
	var g = root.get_node("Game")
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	for key in g.species:
		var model = world.creature(world,int(key))
		check(model.has_node("Body") and model.get_node("Body").get_child(0) is AnimatedActor,"Animated model root: "+str(g.species[key].name))
		var bounds = mesh_bounds(model)
		check(bounds.size.y>0.6 and bounds.size.y<3.0 and bounds.size.x>0.3 and bounds.position.y> -0.16,"Model fits camera and ground bounds: "+str(g.species[key].name))
		model.queue_free()
	var human: AnimatedActor = world.player.get_node("CharacterVisual")
	check(human.limbs.size()==4 and human.eyes.size()==2,"Human rig has paired arms, legs and blinking eyes")
	human.walking = 1.0
	human._process(0.11)
	check(absf(human.limbs[0].rotation.x)>0.01,"Walk animation changes joint pose")
	var safe: Vector3 = world.safe_spawn(Vector3(8,0.1,-8))
	check(safe.distance_to(Vector3(8,0.1,-8))>2,"Legacy spawn inside lab moves to safe ground")
	safe = world.safe_spawn(Vector3(-14,0.1,17))
	check(safe.distance_to(Vector3(-14,0.1,17))>2,"Legacy spawn inside pond moves to safe ground")
	check(world.safe_spawn(Vector3(0,0.1,6)).is_equal_approx(Vector3(0,0.1,6)),"Valid spawn position is preserved")
	var before = JSON.stringify(g.state)
	world.show_gallery()
	check(world.mode=="gallery" and is_instance_valid(world.gallery_model),"Model viewer opens inside unified game")
	for key in g.species: world.select_gallery_species(int(key))
	check(before==JSON.stringify(g.state),"Model viewer does not alter party, inventory or save state")
	world.close_gallery()
	check(world.mode=="menu" and world.gallery_stage==null and world.camera.h_offset==0 and world.hud_panel.visible,"Model viewer restores exploration camera")
	world.close_menu()
	g.gift("oak")
	g.gift("mom")
	world.start_battle(true)
	var scenery: int = world.battle_models.get_child_count()
	world.battle_action(world.battle.switch_to(1))
	check(world.battle_models.get_child_count()==scenery,"Battle action retains decorated arena")
	var bars: Array = []
	for child in world.content.get_children():
		if child is ProgressBar: bars.append(child)
	check(bars.size()==2,"Battle HUD shows both HP bars")
	world.battle_bag()
	check(world.modal.visible,"Battle bag remains accessible after UI redesign")
	world.battle.ended = true
	world.finish_battle()
	check(world.mode=="world" and world.battle==null,"Decorated battle returns to exploration")
	world.queue_free()
	await process_frame
	print("VISUAL INTEGRATION RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
