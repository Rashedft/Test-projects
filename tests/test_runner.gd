extends SceneTree

var checks = 0
var failures = 0
var game: Node
func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: "+label)
	else: print("PASS: "+label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(4242)
	game = root.get_node("Game")
	game.save_root = "user://tests"
	DirAccess.make_dir_recursive_absolute(game.save_root)
	game.new_game()
	check(game.state.party.is_empty(),"New game has no free Pokémon")
	game.gift("mom")
	check(game.state.party.is_empty(),"Mom requires Oak event")
	game.gift("oak")
	game.gift("oak")
	check(game.state.party.size()==1 and game.state.party[0].species==25,"Oak gift once")
	game.gift("mom")
	game.gift("mom")
	check(game.state.party.size()==4,"Mom gives three starters once")
	for p in game.state.party: check(p.level==5,"Starter level 5")
	var p: Dictionary = game.state.party[0]
	p.ivs = [0,0,0,0,0,0]
	p.nature = "Hardy"
	check(game.stats(p)==[18,10,9,10,10,14],"Gen VI Pikachu base stats with zero IVs at level 5")
	var initial_moves: Array = []
	for slot in p.moves: initial_moves.append(slot.id)
	check(initial_moves.size()==3 and "thunder_shock" in initial_moves and "tail_whip" in initial_moves and "growl" in initial_moves,"XY Pikachu level-5 starter moves")
	game.swap_lead(3)
	check(game.state.party[0].species==7,"Party rearrangement")
	game.swap_lead(1)
	check(game.state.party[0].species==25,"Pikachu restored as lead")
	var hp: int = game.state.party[0].hp
	game.evolve(0)
	check(game.state.party[0].species==26 and game.state.items.thunder_stone==0,"Thunder Stone evolves and consumes item")
	game.evolve(0)
	check(game.state.items.thunder_stone==0,"Stone cannot be consumed twice")
	game.state.party[0].hp = 0
	var potions: int = game.state.items.potion
	game.potion(0)
	check(game.state.items.potion==potions,"Potion cannot revive")
	game.heal()
	check(game.state.party[0].hp==game.stats(game.state.party[0])[0],"Center restores HP")
	game.state.party[0].hp -= 2
	game.potion(0)
	check(game.state.party[0].hp==game.stats(game.state.party[0])[0] and game.state.items.potion==potions-1,"Potion clamps and consumes once")
	for i in range(3): game.own(game.create_pokemon(19,3))
	check(game.state.party.size()==6 and game.state.boxes.size()==1,"Full party sends capture to PC")
	check(game.store(2) and game.withdraw(0),"PC deposit and withdraw")
	check(game.save_game(1),"Save succeeds")
	var expected = JSON.stringify(game.state)
	game.state.money = 1
	check(game.load_game(1) and JSON.parse_string(JSON.stringify(game.state))==JSON.parse_string(expected),"Entire state round-trips through JSON")
	check(game.save_game(1) and FileAccess.file_exists(game.save_root.path_join("slot_1.json.bak")),"Previous save backup retained")
	var file = FileAccess.open(game.save_root.path_join("slot_2.json"),FileAccess.WRITE)
	file.store_string('{"version":99}')
	file.close()
	check(not game.load_game(2) and JSON.parse_string(JSON.stringify(game.state))==JSON.parse_string(expected),"Invalid save leaves live state intact")
	game.gift("oak")
	game.gift("mom")
	check(game.state.party.size()==6,"Gift flags survive loading")
	check(BattleSession.effectiveness("electric",["ground"])==0,"Electric Ground immunity")
	check(BattleSession.effectiveness("dragon",["fairy"])==0,"Gen VI Dragon Fairy immunity")
	check(BattleSession.effectiveness("ghost",["steel"])==1,"Gen VI Steel no longer resists Ghost")
	check(BattleSession.effectiveness("fire",["grass","steel"])==4,"Dual type effectiveness")
	var session = BattleSession.new(game,game.create_pokemon(19,5))
	session.rng.seed = 123
	p = game.state.party[0]
	var before: int = p.moves[0].pp
	session.move_turn(0)
	check(p.moves[0].pp==before-1,"Battle consumes move PP")
	session = BattleSession.new(game,game.create_pokemon(16,5),true)
	session.capture()
	check(not session.ended,"Trainer capture forbidden")
	session.flee()
	check(not session.ended,"Trainer escape forbidden")
	game.heal()
	for mon in game.state.party:
		mon.status = ""
		for slot in mon.moves: slot.pp = 0
	session = BattleSession.new(game,game.create_pokemon(19,3))
	var struggle_hp: int = game.state.party[session.active].hp
	session.move_turn(-1)
	check(game.state.party[session.active].hp<struggle_hp,"Zero PP Struggle recoil")
	game.heal()
	session = BattleSession.new(game,game.create_pokemon(19,3))
	session.rng.seed = 6789
	session.enemy.hp = 1
	var count: int = game.state.party.size()+game.state.boxes.size()
	for i in range(30):
		if session.ended: break
		session.capture()
	check(session.ended and game.state.party.size()+game.state.boxes.size()==count+1,"Capture integrates with persistent ownership")

	var valid_state: Dictionary = game.state.duplicate(true)
	var malformed: Dictionary = valid_state.duplicate(true)
	malformed.party[0].hp = "bad"
	check(not game.valid_save(malformed),"Save validator rejects string HP without crashing")
	malformed = valid_state.duplicate(true)
	malformed.party[0].moves = ["bad"]
	check(not game.valid_save(malformed),"Save validator rejects invalid move structures")
	malformed = valid_state.duplicate(true)
	malformed.party[0].ivs = [0,0,0,0,0,999]
	check(not game.valid_save(malformed),"Save validator rejects invalid IVs")
	malformed = valid_state.duplicate(true)
	malformed.party[1] = malformed.party[0].duplicate(true)
	check(not game.valid_save(malformed),"Save validator rejects duplicate creature identities")
	malformed = valid_state.duplicate(true)
	malformed.items.poke_ball = -1
	check(not game.valid_save(malformed),"Save validator rejects negative inventory")
	var test_mon: Dictionary = game.create_pokemon(25,50)
	test_mon.ivs = [0,0,0,0,0,0]
	test_mon.nature = "Adamant"
	check(game.stats(test_mon)[1]==66 and game.stats(test_mon)[3]==49,"Nature modifiers round down correctly")
	test_mon.nature = "Hardy"
	var target: Dictionary = game.create_pokemon(19,50)
	target.ivs = [0,0,0,0,0,0]
	target.nature = "Hardy"
	var calc = BattleSession.new(game,target)
	check(calc.damage(test_mon,target,game.moves.thunder_shock,false,100)==39,"Known Gen VI neutral STAB damage vector")
	check(calc.damage(test_mon,target,game.moves.thunder_shock,true,100)==58,"Gen VI critical multiplier 1.5")
	var learner: Dictionary = game.create_pokemon(4,6)
	game.gain_xp(learner,game.threshold(7,"medium_slow")-int(learner.xp))
	var learned_ember = false
	for slot in learner.moves:
		if slot.id=="ember": learned_ember = true
	check(learner.level==7 and learned_ember,"Level-up learns XY Ember at level 7")
	learner = game.create_pokemon(4,15)
	game.gain_xp(learner,game.threshold(16,"medium_slow")-int(learner.xp))
	check(learner.species==5,"Level-based evolution transforms species")
	var money: int = game.state.money
	var balls: int = game.state.items.poke_ball
	game.buy("poke_ball")
	check(game.state.money==money-200 and game.state.items.poke_ball==balls+1,"Shop purchase updates money and inventory")
	game.state.money = 0
	game.buy("potion")
	check(game.state.money==0,"Insufficient funds cannot create negative money")
	game.state.quests = {}
	game.state.caught.append(16)
	game.complete_field_research()
	game.complete_field_research()
	check(game.state.money==600 and game.state.quests.mira_field=="complete","Research quest reward is one-time")
	game.new_game()
	game.gift("oak")
	game.gift("mom")
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	check(world.follower_id==25,"Follower uses party slot one")
	game.swap_lead(3)
	check(world.follower_id==7,"Follower changes immediately with party order")
	game.swap_lead(1)
	game.evolve(0)
	check(world.follower_id==26,"Follower changes on evolution")
	world.main_menu()
	await process_frame
	check(world.modal.visible and world.mode=="menu","Main menu opens and pauses exploration")
	world.party_menu()
	await process_frame
	for child in world.content.get_children():
		if child is Button: check(child.size.x<=world.modal.size.x,"Party row fits menu width")
	root.size = Vector2i(1920,1080)
	await process_frame
	check(world.modal.get_global_rect().end.x<=1920 and world.modal.get_global_rect().end.y<=1080,"Party menu fits 1080p")
	root.size = Vector2i(1280,720)
	await process_frame
	check(world.modal.get_global_rect().end.x<=1920 and world.modal.get_global_rect().end.y<=1080,"Party menu remains within scaled viewport")
	world.summary(0)
	world.save_menu()
	world.player.position = Vector3(8,0.1,11)
	world.pc_menu()
	world.dex_menu()
	world.journal_menu()
	world.close_menu()
	world.start_battle(true)
	check(world.battle!=null and world.mode=="battle","World transitions to trainer battle")
	world.fight_menu()
	world.party_menu()
	world.summary(1)
	world.battle_action(world.battle.switch_to(1))
	check(world.battle.active==1,"Battle party switch integrated")
	world.battle.ended = true
	world.finish_battle()
	check(world.battle==null and world.mode=="world","Battle returns to exploration")
	game.new_game()
	world.player.position = Vector3(8,0.1,-3)
	world.interact()
	check(game.state.party.size()==1 and game.state.flags.oak,"World Oak interaction awards Pikachu")
	world.player.position = Vector3(-8,0.1,4)
	world.interact()
	world.interact()
	check(game.state.party.size()==4 and game.state.flags.mom,"World Mom interaction integrates one-time gifts")
	world.player.position = Vector3(0,0.1,5)
	var key = InputEventKey.new()
	key.physical_keycode = KEY_W
	key.keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key.duplicate())
	for i in range(15): await physics_frame
	key.pressed = false
	Input.parse_input_event(key.duplicate())
	check(world.player.position.z<4.5,"Keyboard input moves the physical player")
	world.main_menu()
	var paused_position: Vector3 = world.player.position
	key.pressed = true
	Input.parse_input_event(key.duplicate())
	for i in range(8): await physics_frame
	key.pressed = false
	Input.parse_input_event(key.duplicate())
	check(world.player.position.distance_to(paused_position)<0.001,"Menus pause movement")
	world.close_menu()
	world.player.position = Vector3(8,0.1,-4)
	key.pressed = true
	Input.parse_input_event(key.duplicate())
	for i in range(40): await physics_frame
	key.pressed = false
	Input.parse_input_event(key.duplicate())
	check(world.player.position.z>-5.8 and world.player.position.z<-4.5,"Lab collision blocks walking through walls")
	world.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
