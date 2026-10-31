extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name_text: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/"+name_text+".png")
func run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await shot("three-regions-world")
	var g = root.get_node("Game")
	g.gift("oak")
	g.gift("mom")
	world.party_menu()
	await shot("three-regions-party")
	world.close_menu()
	world.start_battle(true)
	await shot("three-regions-battle")
	quit()
