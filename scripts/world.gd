extends Node3D

var player: CharacterBody3D
var follower: Node3D
var camera: Camera3D
var canvas: CanvasLayer
var hud: Label
var message: Label
var modal: PanelContainer
var content: VBoxContainer
var npcs: Array = []
var battle: BattleSession
var battle_models: Node3D
var battle_log: Array = []
var follower_id = -1
var encounter_steps = 0.0
var selected = 0
var mode = "world"
var clock = 0.0
var last_position = Vector3.ZERO
var follower_stuck = 0.0

func _ready() -> void:
	seed(Time.get_ticks_usec())
	build_environment()
	build_ui()
	Game.changed.connect(refresh)
	refresh()
	say("Welcome to Pallet Town. Find Professor Oak outside the lab.\nWASD / arrows: move · E: interact · P: party · Esc: menu")

var builder: TownBuilder
func build_environment() -> void:
	builder = TownBuilder.new(self)
	builder.build_environment()

func creature(parent: Node3D, id: int) -> Node3D:
	return builder.creature(parent,id)

func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, collision: bool = false) -> Node3D:
	return builder.box(parent,size,pos,color,collision)

func panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("172b40",0.97)
	style.border_color = Color("97c8bf")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style

func build_ui() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	var theme = Theme.new()
	theme.default_font_size = 25
	root.theme = theme
	hud = Label.new()
	hud.position = Vector2(26,20)
	hud.add_theme_color_override("font_color",Color("f9f1d8"))
	root.add_child(hud)
	var bottom = PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -155
	bottom.offset_bottom = -22
	bottom.add_theme_stylebox_override("panel",panel_style())
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size",24)
	bottom.add_child(message)
	modal = PanelContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.offset_left = 280
	modal.offset_right = -280
	modal.offset_top = 80
	modal.offset_bottom = -190
	modal.add_theme_stylebox_override("panel",panel_style())
	root.add_child(modal)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",12)
	scroll.add_child(content)
	modal.hide()

func clear_menu(title: String) -> void:
	modal.offset_left = 1120 if battle!=null else 280
	modal.offset_right = -24 if battle!=null else -280
	modal.offset_top = 100 if battle!=null else 80
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	modal.show()
	var heading = Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size",36)
	content.add_child(heading)

func text_line(value: String) -> void:
	var l = Label.new()
	l.text = value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(l)

func button(value: String, action: Callable) -> Button:
	var b = Button.new()
	b.text = value
	b.tooltip_text = value
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.custom_minimum_size.y = 50
	b.pressed.connect(action)
	content.add_child(b)
	return b

func say(value: String) -> void:
	message.text = value

func refresh() -> void:
	if not is_instance_valid(hud): return
	var lead = "No partner yet"
	if not Game.state.party.is_empty(): lead = str(Game.state.party[0].nickname)+" Lv."+str(int(Game.state.party[0].level))
	hud.text = "POKE JOURNEY  /  DEVELOPMENT 0.1\nKanto · Pallet Town / Route 1\n"+lead+"  |  ₽"+str(int(Game.state.money))+"\n[E] Interact   [P] Party   [Esc] Menu"
	var id = int(Game.state.party[0].species) if not Game.state.party.is_empty() else -1
	if id != follower_id:
		if is_instance_valid(follower): follower.queue_free()
		follower_id = id
		if id >= 0:
			follower = creature(self,id)
			follower.position = player.position+Vector3(0,0,2)

func _physics_process(delta: float) -> void:
	clock += delta
	if mode != "world": return
	var direction = Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): direction.z -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): direction.z += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): direction.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): direction.x += 1
	direction = direction.normalized()
	player.velocity.x = direction.x*5
	player.velocity.z = direction.z*5
	player.velocity.y = -8
	player.move_and_slide()
	if direction.length()>0: player.rotation.y = lerp_angle(player.rotation.y,atan2(-direction.x,-direction.z),delta*12)
	var moved = player.position.distance_to(last_position)
	last_position = player.position
	if is_instance_valid(follower):
		var target = player.position+player.basis.z*1.7
		var distance = follower.position.distance_to(target)
		if distance > 9: follower.position = target
		elif distance > 0.3:
			var next = follower.position.move_toward(target,delta*maxf(3.5,distance*2))
			var query = PhysicsRayQueryParameters3D.create(follower.position+Vector3.UP*0.5,next+Vector3.UP*0.5)
			query.exclude = [player.get_rid()]
			if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				follower.position = next
				follower_stuck = 0
			else:
				follower_stuck += delta
				if follower_stuck>2:
					follower.position = player.position+Vector3(0,0,1)
					follower_stuck = 0
			follower.rotation.y = lerp_angle(follower.rotation.y,atan2(follower.position.x-target.x,follower.position.z-target.z),delta*8)
		follower.get_node("Body").position.y = 0.55+sin(clock*9)*0.04 if direction.length()>0 else 0.55
	camera.position = camera.position.lerp(player.position+Vector3(0,15,19),delta*5)
	camera.look_at(player.position+Vector3(0,0,-2))
	if player.position.z < -21 and not Game.state.flags.get("mom",false):
		player.position.z = -20
		say("Visit Oak and Mom first. Your four partners are waiting!")
	if player.position.z < -24 and absf(player.position.x)<10 and moved<1:
		encounter_steps += moved
		if encounter_steps>7:
			encounter_steps = 0
			if randf()<0.65: start_battle(false)
	else: encounter_steps = 0

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode == KEY_ESCAPE:
		if battle != null:
			if battle.ended: finish_battle()
			else: battle_menu()
		elif mode=="world": main_menu()
		else: close_menu()
	elif event.physical_keycode==KEY_P and battle==null: party_menu()
	elif event.physical_keycode==KEY_E and mode=="world": interact()

func close_menu() -> void:
	modal.hide()
	mode = "world"

func interact() -> void:
	var nearest: Dictionary = {}
	var dist = 3.0
	for n in npcs:
		var d = player.position.distance_to(n.node.position)
		if d<dist:
			dist = d
			nearest = n
	if nearest.is_empty():
		say("Walk close to Oak, Mom, the Nurse or Mira, then press E.")
		return
	match nearest.kind:
		"oak", "mom": say(Game.gift(nearest.kind))
		"heal":
			Game.heal()
			say("Nurse: Your party is fully healed, including PP and status. PC storage is available in the menu.")
		"shop": shop_menu()
		"rival":
			if Game.state.party.is_empty(): say("Mira: Get your partner from Oak first. I study how partners work together.")
			else:
				mode = "menu"
				clear_menu("Mira · field researcher")
				text_line("I want to connect the regions through field research. Shall we try a practice battle? My Pidgey is level 5. Its level does not scale with yours.")
				button("Field research",func(): say(Game.complete_field_research()); close_menu())
				button("Battle Mira",func(): start_battle(true))
				button("Not now",close_menu)

func main_menu() -> void:
	mode = "menu"
	clear_menu("Adventure menu")
	button("Pokémon party",party_menu)
	button("Bag",bag_menu)
	button("PC storage",pc_menu)
	button("Pokédex · research records",dex_menu)
	button("Journal / region map",journal_menu)
	button("Save / load",save_menu)
	button("Controls / build information",func():
		clear_menu("Controls & build information")
		text_line("WASD or arrow keys: movement\nE: interact nearby\nP: party · Esc: menu/back\nMouse: menu selection\n\nOriginal procedural placeholder art. Compatibility renderer is used for cloud testing. This is an opening development build, not the complete adventure. Gamepad, audio, interiors and regional campaigns are pending.")
		button("Back",main_menu))
	button("Return to exploration",close_menu)

func party_menu() -> void:
	mode = "menu" if battle==null else "battle"
	clear_menu("Pokémon party · %d / 6" % Game.state.party.size())
	if Game.state.party.is_empty(): text_line("Professor Oak has your first partner.")
	for i in range(Game.state.party.size()):
		var p: Dictionary = Game.state.party[i]
		button("%d. %s · Lv.%d · HP %d/%d · %s%s" % [i+1,p.nickname,p.level,p.hp,Game.stats(p)[0]," / ".join(Game.species[str(int(p.species))].types)," · "+str(p.status) if p.status!="" else ""],func(): summary(i))
	button("Back",battle_menu if battle!=null else main_menu)

func summary(index: int) -> void:
	selected = index
	var p: Dictionary = Game.state.party[index]
	clear_menu(str(p.nickname)+" · Lv."+str(int(p.level)))
	text_line("Types: "+" / ".join(Game.species[str(int(p.species))].types)+"\nHP / Atk / Def / SpA / SpD / Spe: "+str(Game.stats(p))+"\nAbility: "+str(p.ability)+" · Nature: "+str(p.nature)+"\nExperience: "+str(int(p.xp))+" · IVs: "+str(p.ivs)+" · EVs: "+str(p.evs))
	for m in p.moves: text_line(str(Game.moves[m.id].name)+" · PP %d/%d" % [m.pp,Game.moves[m.id].pp])
	var nickname = LineEdit.new()
	nickname.text = p.nickname
	nickname.max_length = 24
	nickname.placeholder_text = "Nickname"
	nickname.text_submitted.connect(func(value: String):
		if not value.strip_edges().is_empty():
			p.nickname = value.strip_edges()
			Game.changed.emit()
			say("Nickname updated."))
	content.add_child(nickname)
	if battle!=null:
		button("Switch into battle",func(): battle_action(battle.switch_to(index)))
	else:
		button("Make lead / following Pokémon",func(): Game.swap_lead(index); party_menu())
		button("Use Potion",func(): say(Game.potion(index)); summary(index))
		button("Use Thunder Stone",func(): say(Game.evolve(index)); summary(index))
		if player.position.distance_to(Vector3(8,0,11.2))<4:
			button("Deposit in PC",func(): say("Deposited." if Game.store(index) else "Keep at least one partner."); party_menu())
	button("Back",party_menu)

func bag_menu() -> void:
	clear_menu("Bag")
	for item in Game.state.items: text_line(str(item).replace("_"," ").capitalize()+" × "+str(int(Game.state.items[item])))
	text_line("Choose a partner in the party menu to use a Potion or Thunder Stone. Poké Balls are used during wild battles.")
	button("Back",main_menu)

func pc_menu() -> void:
	clear_menu("PC storage")
	if player.position.distance_to(Vector3(8,0,11.2))>=4: text_line("Visit the Nurse / PC station to manage storage.")
	else:
		if Game.state.boxes.is_empty(): text_line("No Pokémon in storage. Deposit partners from the party menu.")
		for i in range(Game.state.boxes.size()):
			var p: Dictionary = Game.state.boxes[i]
			button("Withdraw %s · Lv.%d" % [p.nickname,p.level],func(): say("Withdrawn." if Game.withdraw(i) else "Your party is full."); pc_menu())
	button("Back",main_menu)

func dex_menu() -> void:
	clear_menu("Pokédex · %d species owned" % Game.state.caught.size())
	for id in Game.state.caught:
		text_line("#%03d  %s · %s" % [id,Game.species[str(int(id))].name," / ".join(Game.species[str(int(id))].types)])
	text_line("Development dataset: 10 species. Full 493-species historical data import and Pokédex text are pending.")
	button("Back",main_menu)

func journal_menu() -> void:
	clear_menu("Journal / world progression")
	text_line("Mira field research: "+str(Game.state.quests.get("mira_field","not started")))
	text_line(("✓" if Game.state.flags.get("oak",false) else "○")+" Receive Pikachu from Professor Oak\n"+("✓" if Game.state.flags.get("mom",false) else "○")+" Receive three starters from Mom\n\nExplore the northern field, catch wild Pokémon and practice with Mira.\n\nPlayable: Pallet Town and a Route 1 field.\nNot built: gyms, regional storylines, leagues and ship travel.\nKanto → Johto requires eight Kanto badges and its League victory.\nJohto → Hoenn requires eight Johto badges and its League victory.\nTravel must retain the same party, storage and save record.")
	button("Back",main_menu)

func save_menu() -> void:
	clear_menu("Save / load · three slots")
	for slot in range(1,4):
		button("Save to slot %d" % slot,func():
			Game.state.position = [player.position.x,player.position.y,player.position.z]
			say("Saved slot %d. Previous save retained as .bak." % slot if Game.save_game(slot) else Game.last_error))
		button("Load slot %d" % slot,func():
			if Game.load_game(slot):
				var p: Array = Game.state.position
				player.position = Vector3(p[0],p[1],p[2])
				last_position = player.position
				say("Loaded slot %d." % slot)
				close_menu()
			else: say(Game.last_error))
	button("Back",main_menu)

func start_battle(trainer: bool) -> void:
	var healthy = false
	for p in Game.state.party:
		if p.hp>0: healthy = true
	if not healthy:
		say("Visit the Nurse to heal your party first.")
		return
	battle = BattleSession.new(Game,Game.create_pokemon(16 if trainer else [16,19][randi()%2],5 if trainer else randi_range(3,6)),trainer)
	if not int(battle.enemy.species) in Game.state.seen: Game.state.seen.append(int(battle.enemy.species))
	mode = "battle"
	if is_instance_valid(follower): follower.hide()
	battle_models = Node3D.new()
	add_child(battle_models)
	box(battle_models,Vector3(24,0.3,18),Vector3(100,-0.15,0),Color("6b9472"))
	var a = creature(battle_models,int(Game.state.party[battle.active].species))
	a.position = Vector3(97,0,3)
	a.scale = Vector3.ONE*2.2
	a.rotation.y = 0
	var b = creature(battle_models,int(battle.enemy.species))
	b.rotation.y = PI
	b.position = Vector3(103,0,-3)
	b.scale = Vector3.ONE*2.2
	camera.h_offset = 4.0
	camera.position = Vector3(109,8,15)
	camera.look_at(Vector3(100,0.7,0))
	say("Trainer battle · Mira" if trainer else "Wild encounter · Route 1")
	battle_log = ["Mira sent out Pidgey!" if trainer else "A wild "+str(battle.enemy.nickname)+" appeared!"]
	battle_menu()

func battle_menu() -> void:
	if battle==null: return
	var p: Dictionary = Game.state.party[battle.active]
	clear_menu("BATTLE · "+str(battle.enemy.nickname)+" Lv."+str(int(battle.enemy.level)))
	text_line("Opponent HP: %d/%d  %s\n%s · Lv.%d · HP %d/%d  %s" % [battle.enemy.hp,Game.stats(battle.enemy)[0],battle.enemy.status,p.nickname,p.level,p.hp,Game.stats(p)[0],p.status])
	var hp = ProgressBar.new()
	hp.max_value = Game.stats(p)[0]
	hp.value = p.hp
	hp.custom_minimum_size.y = 22
	content.add_child(hp)
	text_line("\n".join(battle_log.slice(maxi(0,battle_log.size()-5))))
	if battle.ended:
		button("Return to exploration",finish_battle)
		return
	button("Fight",fight_menu)
	button("Pokémon",party_menu)
	button("Bag · Potion",func(): battle_action(battle.use_potion()))
	button("Bag · Poké Ball × %d" % Game.state.items.poke_ball,func(): battle_action(battle.capture()))
	button("Run",func(): battle_action(battle.flee()))

func fight_menu() -> void:
	clear_menu("Choose a move")
	var p: Dictionary = Game.state.party[battle.active]
	var has_pp = false
	for i in range(p.moves.size()):
		var slot: Dictionary = p.moves[i]
		var m: Dictionary = Game.moves[slot.id]
		var b = button("%s · %s · %s · Power %d · PP %d/%d" % [m.name,m.type,m.category,m.power,slot.pp,m.pp],func(): battle_action(battle.move_turn(i)))
		b.disabled = slot.pp<=0 or p.hp<=0
		if slot.pp>0: has_pp = true
	if not has_pp: button("Struggle",func(): battle_action(battle.move_turn(-1)))
	button("Back",battle_menu)

func battle_action(log: Array) -> void:
	battle_log.append_array(log)
	if is_instance_valid(battle_models):
		for child in battle_models.get_children():
			if child is Node3D and not child is MeshInstance3D:
				battle_models.remove_child(child)
				child.queue_free()
		var a = creature(battle_models,int(Game.state.party[battle.active].species))
		a.position = Vector3(97,0,3)
		a.scale = Vector3.ONE*2.2
		a.rotation.y = 0
		var b = creature(battle_models,int(battle.enemy.species))
		b.rotation.y = PI
		b.position = Vector3(103,0,-3)
		b.scale = Vector3.ONE*2.2
		var tween = create_tween()
		tween.tween_property(a,"position:y",0.35,0.12)
		tween.tween_property(a,"position:y",0.0,0.12)
	battle_menu()

func finish_battle() -> void:
	if battle==null or not battle.ended: return
	var lost = false
	for line in battle_log:
		if "returned to town" in line: lost = true
	if lost: player.position = Vector3(7,0.1,12)
	battle = null
	camera.h_offset = 0
	battle_models.queue_free()
	if is_instance_valid(follower): follower.show()
	camera.position = player.position+Vector3(0,15,19)
	camera.look_at(player.position+Vector3(0,0,-2))
	last_position = player.position
	close_menu()
	say("\n".join(battle_log.slice(maxi(0,battle_log.size()-2))))

func shop_menu() -> void:
	mode = "menu"
	clear_menu("Field supplies · ₽%d" % Game.state.money)
	button("Potion · ₽300 · restore 20 HP",func(): say(Game.buy("potion")); shop_menu())
	button("Poké Ball · ₽200",func(): say(Game.buy("poke_ball")); shop_menu())
	button("Return to exploration",close_menu)
