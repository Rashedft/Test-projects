extends Node3D

var player: CharacterBody3D
var follower: Node3D
var camera: Camera3D
var canvas: CanvasLayer
var hud: Label
var hud_panel: PanelContainer
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
var battle_creatures: Node3D
var battle_player_model: Node3D
var battle_enemy_model: Node3D
var battle_effect_layer: BattleEffects
var camera_zoom = 1.0
var gallery_stage: Node3D
var gallery_model: Node3D
var gallery_spin = true
var gallery_species = 25
const EXPLORATION_CAMERA = Vector3(0,10.5,13.5)
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
	style.bg_color = Color("fffdf4",0.98)
	style.shadow_color = Color(0.08,0.17,0.22,0.2)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0,4)
	style.border_color = Color("588e9d")
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
	theme.set_color("font_color","Label",Color("304c60"))
	theme.set_color("font_color","Button",Color("304c60"))
	theme.set_color("font_hover_color","Button",Color("213e50"))
	theme.set_color("font_pressed_color","Button",Color("213e50"))
	theme.set_color("font_focus_color","Button",Color("213e50"))
	for state_name in ["normal","hover","pressed","focus","disabled"]:
		var button_style = StyleBoxFlat.new()
		button_style.bg_color = Color("cde5e6") if state_name in ["hover","pressed","focus"] else Color("eef2e8")
		button_style.border_color = Color("9cbec1")
		button_style.set_border_width_all(1)
		button_style.border_width_bottom = 4
		button_style.set_corner_radius_all(10)
		button_style.content_margin_left = 18
		button_style.content_margin_right = 18
		theme.set_stylebox(state_name,"Button",button_style)
	root.theme = theme
	hud_panel = PanelContainer.new()
	hud_panel.position = Vector2(28,24)
	hud_panel.custom_minimum_size = Vector2(530,110)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_panel.add_theme_stylebox_override("panel",panel_style())
	root.add_child(hud_panel)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size",23)
	hud_panel.add_child(hud)
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
	modal.offset_left = 1120 if battle!=null or mode=="gallery" else 280
	modal.offset_right = -24 if battle!=null or mode=="gallery" else -280
	modal.offset_top = 100 if battle!=null or mode=="gallery" else 80
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
	hud.text = "PALLET TOWN  /  KANTO\n"+lead+"   ·   ₽"+str(int(Game.state.money))
	var id = int(Game.state.party[0].species) if not Game.state.party.is_empty() else -1
	if id != follower_id:
		if is_instance_valid(follower): follower.queue_free()
		follower_id = id
		if id >= 0:
			follower = creature(self,id)
			follower.position = player.position+Vector3(0,0,2)

func _physics_process(delta: float) -> void:
	clock += delta
	if mode=="gallery":
		if is_instance_valid(gallery_model) and gallery_spin: gallery_model.rotation.y += delta*0.35
		return
	if mode != "world":
		var idle_human = player.get_node_or_null("CharacterVisual")
		if idle_human is AnimatedActor: idle_human.walking = 0
		if is_instance_valid(follower):
			var idle_partner = follower.get_node("Body").get_child(0)
			if idle_partner is AnimatedActor: idle_partner.walking = 0
		return
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
	var human_visual = player.get_node_or_null("CharacterVisual")
	if human_visual is AnimatedActor: human_visual.walking = direction.length()
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
		var actor = follower.get_node("Body").get_child(0)
		if actor is AnimatedActor: actor.walking = direction.length()
		follower.get_node("Body").position.y = 0.55+sin(clock*9)*0.04 if direction.length()>0 else 0.55
	camera.position = camera.position.lerp(player.position+EXPLORATION_CAMERA*camera_zoom,delta*5)
	camera.look_at(player.position+Vector3(0,0.5,-1.2))
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
		if mode=="gallery":
			close_gallery()
			return
		if battle != null:
			if battle.ended: finish_battle()
			else: battle_menu()
		elif mode=="world": main_menu()
		else: close_menu()
	elif event.physical_keycode==KEY_P and battle==null and mode!="gallery": party_menu()
	elif event.physical_keycode==KEY_E and mode=="world": interact()

func close_menu() -> void:
	modal.hide()
	mode = "world"

func _unhandled_input(event: InputEvent) -> void:
	if mode=="world" and event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: camera_zoom = maxf(0.8,camera_zoom-0.06)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN: camera_zoom = minf(1.3,camera_zoom+0.06)

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
	button("Model viewer · graphics preview",show_gallery)
	button("Controls / build information",func():
		clear_menu("Controls & build information")
		text_line("WASD or arrow keys: movement\nMouse wheel: exploration zoom\nE: interact nearby\nP: party · Esc: menu/back\nMouse: menu selection\n\nOriginal stylized art · graphics preview 0.2. Inspect the ten current models in Model viewer. This is an opening development build; regional campaigns, full battle rules, audio and gamepad support remain in development.")
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
				player.position = safe_spawn(Vector3(p[0],p[1],p[2]))
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
	builder.battle_arena(battle_models)
	battle_creatures = Node3D.new()
	battle_creatures.name = "Battlers"
	battle_models.add_child(battle_creatures)
	var a = creature(battle_creatures,int(Game.state.party[battle.active].species))
	battle_player_model = a
	a.set_meta("uid",Game.state.party[battle.active].uid)
	a.set_meta("species",int(Game.state.party[battle.active].species))
	a.position = Vector3(97,0.07,3)
	a.scale = Vector3.ONE*2.2
	a.rotation.y = 0
	var b = creature(battle_creatures,int(battle.enemy.species))
	battle_enemy_model = b
	b.rotation.y = PI
	b.position = Vector3(103,0.07,-3)
	b.scale = Vector3.ONE*2.2
	battle_effect_layer = BattleEffects.new()
	battle_models.add_child(battle_effect_layer)
	camera.h_offset = 4.0
	camera.position = Vector3(108,6.5,14)
	camera.look_at(Vector3(100,0.7,0))
	say("Trainer battle · Mira" if trainer else "Wild encounter · Route 1")
	battle_log = ["Mira sent out Pidgey!" if trainer else "A wild "+str(battle.enemy.nickname)+" appeared!"]
	battle_menu()

func hp_bar(current: int, maximum: int) -> void:
	var bar = ProgressBar.new()
	bar.max_value = maximum
	bar.value = current
	bar.show_percentage = false
	bar.custom_minimum_size.y = 17
	var back = StyleBoxFlat.new()
	back.bg_color = Color("d8dfd2")
	back.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("background",back)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color("6caa81") if float(current)/maximum>0.5 else Color("d8b75f") if float(current)/maximum>0.2 else Color("c96d6b")
	fill.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("fill",fill)
	content.add_child(bar)

func battle_menu() -> void:
	if battle==null: return
	var p: Dictionary = Game.state.party[battle.active]
	clear_menu("TRAINER BATTLE" if battle.trainer else "WILD ENCOUNTER")
	text_line("%s   Lv.%d
HP %d / %d" % [battle.enemy.nickname,battle.enemy.level,battle.enemy.hp,Game.stats(battle.enemy)[0]])
	hp_bar(int(battle.enemy.hp),Game.stats(battle.enemy)[0])
	text_line("%s   Lv.%d
HP %d / %d  %s" % [p.nickname,p.level,p.hp,Game.stats(p)[0],p.status])
	hp_bar(int(p.hp),Game.stats(p)[0])
	text_line("\n".join(battle_log.slice(maxi(0,battle_log.size()-4))))
	if battle.ended:
		button("Return to exploration",finish_battle)
		return
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	content.add_child(grid)
	var labels = ["FIGHT","POKÉMON","BAG","RUN"]
	var callbacks: Array[Callable] = [fight_menu,party_menu,battle_bag,func(): battle_action(battle.flee())]
	for i in range(4):
		var b = button(labels[i],callbacks[i])
		content.remove_child(b)
		grid.add_child(b)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 68

func battle_bag() -> void:
	clear_menu("Battle bag")
	button("Potion × %d" % Game.state.items.potion,func(): battle_action(battle.use_potion()))
	button("Poké Ball × %d" % Game.state.items.poke_ball,func(): battle_action(battle.capture()))
	button("Back",battle_menu)

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
		var active: Dictionary = Game.state.party[battle.active]
		if battle_player_model.get_meta("uid")!=active.uid or int(battle_player_model.get_meta("species"))!=int(active.species):
			battle_creatures.remove_child(battle_player_model)
			battle_player_model.queue_free()
			battle_player_model = creature(battle_creatures,int(active.species))
			battle_player_model.position = Vector3(97,0.07,3)
			battle_player_model.scale = Vector3.ONE*2.2
			battle_player_model.set_meta("uid",active.uid)
			battle_player_model.set_meta("species",int(active.species))
		var delay = 0.0
		for event in battle.events:
			var from_player: bool = event.actor_uid==active.uid
			var to_player: bool = event.target_uid==active.uid
			var source: Vector3 = (battle_player_model if from_player else battle_enemy_model).global_position+Vector3(0,1.2,0)
			var target: Vector3 = (battle_player_model if to_player else battle_enemy_model).global_position+Vector3(0,1.2,0)
			battle_effect_layer.play_hit(event,source,target,delay)
			delay += 0.35
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
	camera.position = player.position+EXPLORATION_CAMERA*camera_zoom
	camera.look_at(player.position+Vector3(0,0.5,-1.2))
	last_position = player.position
	close_menu()
	say("\n".join(battle_log.slice(maxi(0,battle_log.size()-2))))

func shop_menu() -> void:
	mode = "menu"
	clear_menu("Field supplies · ₽%d" % Game.state.money)
	button("Potion · ₽300 · restore 20 HP",func(): say(Game.buy("potion")); shop_menu())
	button("Poké Ball · ₽200",func(): say(Game.buy("poke_ball")); shop_menu())
	button("Return to exploration",close_menu)

func show_gallery() -> void:
	mode = "gallery"
	hud_panel.hide()
	if not is_instance_valid(gallery_stage):
		gallery_stage = Node3D.new()
		gallery_stage.name = "ModelViewer"
		gallery_stage.position.x = 100
		add_child(gallery_stage)
		builder.battle_arena(gallery_stage,false)
		builder.cylinder(gallery_stage,Vector3(100,0.01,0),2.5,0.08,Color("d2c29d"))
	select_gallery_species(gallery_species)

func select_gallery_species(id: int) -> void:
	gallery_species = id
	if is_instance_valid(gallery_model):
		gallery_stage.remove_child(gallery_model)
		gallery_model.queue_free()
	gallery_model = creature(gallery_stage,id)
	gallery_model.position = Vector3(100,0.06,0)
	gallery_model.scale = Vector3.ONE*3.0
	gallery_model.rotation.y = PI
	camera.h_offset = 3.4
	camera.position = Vector3(207,4.5,10)
	camera.look_at(Vector3(200,1.7,0))
	clear_menu("MODEL VIEWER")
	text_line(str(Game.species[str(id)].name)+"\n"+" / ".join(Game.species[str(id)].types))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",8)
	content.add_child(grid)
	for key in Game.species:
		var b = button(Game.species[key].name,func(): select_gallery_species(int(key)))
		content.remove_child(b)
		grid.add_child(b)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("Pause rotation" if gallery_spin else "Resume rotation",func(): gallery_spin = not gallery_spin; select_gallery_species(id))
	button("Back to menu",close_gallery)
	say("Poke Journey · graphics preview 0.2\nOriginal models in development. Choose a species to inspect its current appearance.")

func close_gallery() -> void:
	hud_panel.show()
	if is_instance_valid(gallery_stage): gallery_stage.queue_free()
	gallery_stage = null
	gallery_model = null
	camera.h_offset = 0
	camera.position = player.position+EXPLORATION_CAMERA*camera_zoom
	camera.look_at(player.position+Vector3(0,0.5,-1.2))
	main_menu()

func safe_spawn(requested: Vector3) -> Vector3:
	var shape = CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.7
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.exclude = [player.get_rid()]
	for ring in range(10):
		for step in range(1 if ring==0 else 16):
			var angle = step*TAU/16
			var candidate = Vector3(requested.x,0.1,requested.z)+Vector3(cos(angle),0,sin(angle))*ring*0.65
			if absf(candidate.x)>24 or candidate.z< -40 or candidate.z>24: continue
			query.transform = Transform3D(Basis.IDENTITY,candidate+Vector3(0,0.85,0))
			if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): return candidate
	return Vector3(0,0.1,6)
