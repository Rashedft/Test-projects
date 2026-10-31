extends SceneTree
var world: Node3D
func _initialize() -> void: call_deferred("run")
func shot(label: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	var result = image.save_png("/tmp/PokeJourney-0.2-"+label+".png")
	assert(result==OK)
	print("Rendered ",label," · ",image.get_width(),"×",image.get_height()," · draw calls: ",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
func run() -> void:
	root.size = Vector2i(1920,1080)
	world = load("res://main.tscn").instantiate()
	root.add_child(world)
	var g = root.get_node("Game")
	g.gift("oak")
	g.gift("mom")
	await shot("town")
	world.party_menu()
	await shot("party")
	world.close_menu()
	world.start_battle(true)
	await shot("battle")
	var shock = 0
	for i in range(g.state.party[0].moves.size()):
		if g.state.party[0].moves[i].id=="thunder_shock": shock = i
	Engine.time_scale = 0.05
	world.battle_action(world.battle.move_turn(shock))
	await shot("battle-effects")
	Engine.time_scale = 1.0
	world.battle.ended = true
	world.finish_battle()
	world.show_gallery()
	world.gallery_spin = false
	for id in [25,1,4,7,26,2,5,8,16,19]:
		world.select_gallery_species(id)
		await shot("model-"+str(id))
	world.close_gallery()
	world.close_menu()
	world.canvas.hide()
	var roster = Node3D.new()
	world.add_child(roster)
	world.builder.box(roster,Vector3(30,0.2,22),Vector3(300,-0.1,0),Color("9cb28d"))
	var i = 0
	for id in [25,1,4,7,26,2,5,8,16,19]:
		var at = Vector3(293.2+(i%5)*3.4,0.04,-3 if i<5 else 3)
		var model = world.creature(roster,id)
		model.position = at
		model.scale = Vector3.ONE*1.6
		model.rotation.y = PI
		world.builder.label3d(roster,g.species[str(id)].name,at+Vector3(0,0.1,1.4),44)
		i += 1
	world.camera.h_offset = 0
	world.camera.position = Vector3(300,11,17)
	world.camera.look_at(Vector3(300,0.6,0))
	world.mode = "capture"
	await shot("roster")
	world.queue_free()
	await process_frame
	quit()
