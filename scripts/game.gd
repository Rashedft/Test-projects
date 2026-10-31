extends Node

signal changed
const SAVE_VERSION = 1
var species: Dictionary
var moves: Dictionary
var natures: Dictionary
var state: Dictionary
var save_root = "user://"
var last_error = ""

func _ready() -> void:
	species = JSON.parse_string(FileAccess.get_file_as_string("res://data/species.json"))
	moves = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves.json"))
	natures = JSON.parse_string(FileAccess.get_file_as_string("res://data/natures.json"))
	new_game()

func new_game() -> void:
	state = {"version": SAVE_VERSION, "party": [], "boxes": [], "items": {"potion": 5, "poke_ball": 10, "thunder_stone": 1}, "flags": {}, "money": 3000, "region": "kanto", "map": "pallet", "position": [0, 0.9, 5], "badges": {"kanto": [], "johto": [], "hoenn": []}, "leagues": {}, "quests": {}, "rivals": {}, "seen": [], "caught": []}
	changed.emit()

func threshold(level: int, growth: String) -> int:
	if level <= 1: return 0
	if growth == "medium_slow": return maxi(0, int(6.0 * pow(level,3)/5.0 - 15*level*level + 100*level - 140))
	return level*level*level

func stats(p: Dictionary) -> Array:
	var b: Array = species[str(int(p.species))].base
	var result: Array = []
	for i in range(6):
		var value = int((2 * int(b[i]) + int(p.ivs[i]) + int(int(p.evs[i])/4)) * int(p.level) / 100.0)
		if i == 0: value += int(p.level)+10
		else:
			value += 5
			var nature: Dictionary = natures.get(p.get("nature","Hardy"),natures.Hardy)
			if nature.up != nature.down:
				if i==int(nature.up): value = int(floor(value*1.1))
				if i==int(nature.down): value = int(floor(value*0.9))
		result.append(value)
	return result

func create_pokemon(id: int, level: int) -> Dictionary:
	var s: Dictionary = species[str(id)]
	var learned: Array = []
	for entry in s.learn:
		if int(entry[0]) <= level and not entry[1] in learned: learned.append(entry[1])
	while learned.size() > 4: learned.pop_front()
	var slots: Array = []
	for key in learned: slots.append({"id": key, "pp": int(moves[key].pp)})
	var ivs: Array = []
	for i in range(6): ivs.append(randi_range(0,31))
	var p = {"uid": str(Time.get_unix_time_from_system()) + "-" + str(randi()), "species": id, "nickname": s.name, "level": level, "xp": threshold(level,s.growth), "ivs": ivs, "evs": [0,0,0,0,0,0], "nature": natures.keys()[randi()%natures.size()], "ability": s.ability, "friendship": 70, "moves": slots, "status": "", "hp": 1}
	p.hp = stats(p)[0]
	return p

func own(p: Dictionary) -> void:
	if state.party.size() < 6: state.party.append(p)
	else: state.boxes.append(p)
	if not int(p.species) in state.caught: state.caught.append(int(p.species))
	changed.emit()

func gift(event: String) -> String:
	if state.flags.get(event,false): return "You already received this gift."
	if event == "oak":
		if state.party.size() >= 6: return "Make room in your party first."
		own(create_pokemon(25,5))
		state.flags.oak = true
		changed.emit()
		return "Oak: Pikachu will be your partner! Visit your mom before leaving town."
	if event == "mom":
		if not state.flags.get("oak",false): return "Mom: Professor Oak is waiting for you at the lab."
		if state.party.size() > 3: return "Make room for three partners first."
		for id in [1,4,7]: own(create_pokemon(id,5))
		state.flags.mom = true
		changed.emit()
		return "Mom: Bulbasaur, Charmander and Squirtle are joining you! All three are level 5."
	return "Unknown event."

func heal() -> void:
	for p in state.party:
		p.hp = stats(p)[0]
		p.status = ""
		for m in p.moves: m.pp = int(moves[m.id].pp)
	changed.emit()

func swap_lead(index: int) -> bool:
	if index < 0 or index >= state.party.size(): return false
	var p = state.party.pop_at(index)
	state.party.push_front(p)
	changed.emit()
	return true

func store(index: int) -> bool:
	if state.party.size() <= 1 or index < 0 or index >= state.party.size(): return false
	state.boxes.append(state.party.pop_at(index))
	changed.emit()
	return true

func withdraw(index: int) -> bool:
	if state.party.size() >= 6 or index < 0 or index >= state.boxes.size(): return false
	state.party.append(state.boxes.pop_at(index))
	changed.emit()
	return true

func potion(index: int) -> String:
	if index < 0 or index >= state.party.size(): return "Choose a partner."
	var p: Dictionary = state.party[index]
	if int(p.hp) <= 0: return "A Potion cannot revive a fainted Pokémon."
	if int(p.hp) >= stats(p)[0]: return "HP is already full."
	if int(state.items.get("potion",0)) <= 0: return "No Potions remaining."
	state.items.potion -= 1
	p.hp = mini(stats(p)[0],int(p.hp)+20)
	changed.emit()
	return "Restored up to 20 HP."

func evolve(index: int) -> String:
	if index < 0 or index >= state.party.size(): return "Choose a partner."
	var p: Dictionary = state.party[index]
	var e: Dictionary = species[str(int(p.species))].get("evolution",{})
	if e.get("item", "") != "thunder_stone": return "The Thunder Stone has no effect."
	if int(state.items.get("thunder_stone",0)) < 1: return "No Thunder Stone remaining."
	state.items.thunder_stone -= 1
	return evolve_to(p,int(e.to))

func evolve_to(p: Dictionary, id: int) -> String:
	var old: String = species[str(int(p.species))].name
	var old_hp: int = stats(p)[0]
	p.species = id
	if p.nickname == old: p.nickname = species[str(id)].name
	p.ability = species[str(id)].ability
	if p.hp > 0: p.hp += stats(p)[0] - old_hp
	if not id in state.caught: state.caught.append(id)
	changed.emit()
	return old + " evolved into " + str(species[str(id)].name) + "!"

func gain_xp(p: Dictionary, amount: int) -> Array:
	var messages: Array = []
	p.xp += amount
	while p.level < 100 and p.xp >= threshold(int(p.level)+1,species[str(int(p.species))].growth):
		var old_hp: int = stats(p)[0]
		p.level += 1
		if p.hp > 0: p.hp += stats(p)[0] - old_hp
		messages.append(str(p.nickname)+" reached level "+str(int(p.level))+"!")
		for entry in species[str(int(p.species))].learn:
			if int(entry[0]) == int(p.level):
				var known = false
				for m in p.moves:
					if m.id == entry[1]: known = true
				if not known and p.moves.size() < 4:
					p.moves.append({"id":entry[1],"pp":int(moves[entry[1]].pp)})
					messages.append("Learned "+str(moves[entry[1]].name)+"!")
				elif not known: messages.append("Move replacement is not available yet: "+str(moves[entry[1]].name))
		var e: Dictionary = species[str(int(p.species))].get("evolution",{})
		if e.has("level") and p.level >= e.level: messages.append(evolve_to(p,int(e.to)))
	changed.emit()
	return messages

func save_game(slot: int = 1) -> bool:
	last_error = ""
	var path = save_root.path_join("slot_%d.json" % slot)
	var f = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f == null:
		last_error = "Cannot write save: " + error_string(FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(state))
	f.flush()
	f.close()
	if FileAccess.file_exists(path):
		var err = DirAccess.copy_absolute(path,path+".bak")
		if err != OK:
			last_error = "Cannot preserve backup: "+error_string(err)
			return false
	var err = DirAccess.rename_absolute(path+".tmp",path)
	if err != OK: last_error = error_string(err)
	return err == OK

func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))

func valid_pokemon(p: Variant) -> bool:
	if not p is Dictionary: return false
	for key in ["uid","nickname","nature","ability","status"]:
		if not p.get(key) is String: return false
	if p.uid.is_empty() or p.nickname.length()>24 or not natures.has(p.nature): return false
	if p.status not in ["","burn","paralysis"]: return false
	for key in ["species","level","xp","friendship","hp"]:
		if not number(p.get(key)): return false
	if not species.has(str(int(p.species))) or p.level<1 or p.level>100 or p.xp<0 or p.friendship<0 or p.friendship>255: return false
	for key in ["ivs","evs"]:
		if not p.get(key) is Array or p[key].size()!=6: return false
		for value in p[key]:
			if not number(value) or value<0 or value>(31 if key=="ivs" else 252): return false
	var ev_total = 0
	for value in p.evs: ev_total += int(value)
	if ev_total>510 or p.hp<0 or p.hp>stats(p)[0]: return false
	if not p.get("moves") is Array or p.moves.is_empty() or p.moves.size()>4: return false
	var known: Array = []
	for m in p.moves:
		if not m is Dictionary or not m.get("id") is String or not moves.has(m.id) or not number(m.get("pp")): return false
		if m.id in known or m.pp<0 or m.pp>moves[m.id].pp: return false
		known.append(m.id)
	return true

func valid_save(candidate: Variant) -> bool:
	if not candidate is Dictionary: return false
	for key in state.keys():
		if not candidate.has(key): return false
		if key in ["version","money"]:
			if not number(candidate[key]): return false
		elif typeof(candidate[key])!=typeof(state[key]): return false
	if int(candidate.version)!=SAVE_VERSION or candidate.money<0: return false
	if candidate.region!="kanto" or candidate.map!="pallet": return false
	if candidate.party.size()>6 or candidate.boxes.size()>960: return false
	if candidate.position.size()!=3: return false
	for n in candidate.position:
		if not (n is float or n is int) or not is_finite(float(n)): return false
	if absf(candidate.position[0])>24 or candidate.position[1]<-1 or candidate.position[1]>10 or candidate.position[2]<-40 or candidate.position[2]>24: return false
	for key in ["potion","poke_ball","thunder_stone"]:
		if not number(candidate.items.get(key)) or candidate.items[key]<0: return false
	for flag in candidate.flags.values():
		if not flag is bool: return false
	for key in ["kanto","johto","hoenn"]:
		if not candidate.badges.get(key) is Array or candidate.badges[key].size()>8: return false
	for key in ["seen","caught"]:
		for id in candidate[key]:
			if not number(id) or not species.has(str(int(id))): return false
	var uids: Array = []
	for collection in [candidate.party,candidate.boxes]:
		for p in collection:
			if not valid_pokemon(p) or p.uid in uids: return false
			uids.append(p.uid)
	return true

func load_game(slot: int = 1) -> bool:
	last_error = ""
	var path = save_root.path_join("slot_%d.json" % slot)
	var candidate = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not valid_save(candidate):
		last_error = "Save missing, unsupported or invalid. Current game was preserved."
		return false
	state = candidate
	changed.emit()
	return true

func buy(item: String, quantity: int = 1) -> String:
	var prices = {"potion":300,"poke_ball":200}
	if not prices.has(item) or quantity<1 or quantity>99: return "Invalid purchase."
	var cost: int = prices[item]*quantity
	if state.money<cost: return "Not enough money."
	state.money -= cost
	state.items[item] = int(state.items.get(item,0))+quantity
	changed.emit()
	return "Purchased %d %s." % [quantity,item.replace("_"," ")]

func complete_field_research() -> String:
	if state.quests.get("mira_field","")=="complete": return "Mira: Thank you for the research! Your partners are in good hands."
	var found = false
	for id in state.caught:
		if int(id) in [16,19]: found = true
	if not found:
		state.quests.mira_field = "active"
		changed.emit()
		return "Mira: Catch a Pidgey or Rattata in the northern field. Return to share your observations; I will fund more field supplies."
	state.quests.mira_field = "complete"
	state.money += 600
	changed.emit()
	return "Mira: Wonderful observations! Research complete. Received ₽600."
