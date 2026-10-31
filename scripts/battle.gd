class_name BattleSession
extends RefCounted

var game: Node
var enemy: Dictionary
var trainer = false
var ended = false
var active = 0
var stages: Dictionary = {}
var seeded: Dictionary = {}
var rng = RandomNumberGenerator.new()
var turns = 0
var flinched: Dictionary = {}

# Gen VI chart, including the Fairy type and Steel's neutral Ghost/Dark matchups.
const CHART = {
"normal":{"rock":0.5,"ghost":0.0,"steel":0.5},
"fire":{"fire":0.5,"water":0.5,"grass":2.0,"ice":2.0,"bug":2.0,"rock":0.5,"dragon":0.5,"steel":2.0},
"water":{"fire":2.0,"water":0.5,"grass":0.5,"ground":2.0,"rock":2.0,"dragon":0.5},
"electric":{"water":2.0,"electric":0.5,"grass":0.5,"ground":0.0,"flying":2.0,"dragon":0.5},
"grass":{"fire":0.5,"water":2.0,"grass":0.5,"poison":0.5,"ground":2.0,"flying":0.5,"bug":0.5,"rock":2.0,"dragon":0.5,"steel":0.5},
"ice":{"fire":0.5,"water":0.5,"grass":2.0,"ice":0.5,"ground":2.0,"flying":2.0,"dragon":2.0,"steel":0.5},
"fighting":{"normal":2.0,"ice":2.0,"poison":0.5,"flying":0.5,"psychic":0.5,"bug":0.5,"rock":2.0,"ghost":0.0,"dark":2.0,"steel":2.0,"fairy":0.5},
"poison":{"grass":2.0,"poison":0.5,"ground":0.5,"rock":0.5,"ghost":0.5,"steel":0.0,"fairy":2.0},
"ground":{"fire":2.0,"electric":2.0,"grass":0.5,"poison":2.0,"flying":0.0,"bug":0.5,"rock":2.0,"steel":2.0},
"flying":{"electric":0.5,"grass":2.0,"fighting":2.0,"bug":2.0,"rock":0.5,"steel":0.5},
"psychic":{"fighting":2.0,"poison":2.0,"psychic":0.5,"dark":0.0,"steel":0.5},
"bug":{"fire":0.5,"grass":2.0,"fighting":0.5,"poison":0.5,"flying":0.5,"psychic":2.0,"ghost":0.5,"dark":2.0,"steel":0.5,"fairy":0.5},
"rock":{"fire":2.0,"ice":2.0,"fighting":0.5,"ground":0.5,"flying":2.0,"bug":2.0,"steel":0.5},
"ghost":{"normal":0.0,"psychic":2.0,"ghost":2.0,"dark":0.5},
"dragon":{"dragon":2.0,"steel":0.5,"fairy":0.0},
"dark":{"fighting":0.5,"psychic":2.0,"ghost":2.0,"dark":0.5,"fairy":0.5},
"steel":{"fire":0.5,"water":0.5,"electric":0.5,"ice":2.0,"rock":2.0,"steel":0.5,"fairy":2.0},
"fairy":{"fire":0.5,"fighting":2.0,"poison":0.5,"dragon":2.0,"dark":2.0,"steel":0.5}}

func _init(g: Node, foe: Dictionary, is_trainer: bool = false) -> void:
	game = g
	enemy = foe
	trainer = is_trainer
	rng.randomize()
	for i in range(game.state.party.size()):
		if game.state.party[i].hp > 0:
			active = i
			break

static func effectiveness(type: String, types: Array) -> float:
	var result = 1.0
	for t in types: result *= float(CHART.get(type,{}).get(t,1.0))
	return result

func stage(p: Dictionary, key: String) -> int:
	return int(stages.get(p.uid,{}).get(key,0))

func multiplier(value: int, accuracy: bool = false) -> float:
	var base = 3.0 if accuracy else 2.0
	return (base+value)/base if value >= 0 else base/(base-value)

func change_stage(p: Dictionary, key: String, delta: int) -> void:
	if not stages.has(p.uid): stages[p.uid] = {}
	stages[p.uid][key] = clampi(stage(p,key)+delta,-6,6)

func speed(p: Dictionary) -> float:
	return game.stats(p)[5] * multiplier(stage(p,"speed")) * (0.25 if p.status == "paralysis" else 1.0)

func damage(user: Dictionary, target: Dictionary, move: Dictionary, critical: bool = false, roll: int = 100) -> int:
	var types: Array = game.species[str(int(target.species))].types
	var eff = effectiveness(move.type,types)
	if eff == 0: return 0
	var physical: bool = move.category == "physical"
	var attack_stage = stage(user,"attack" if physical else "sp_attack")
	var defense_stage = stage(target,"defense" if physical else "sp_defense")
	if critical:
		attack_stage = maxi(0,attack_stage)
		defense_stage = mini(0,defense_stage)
	var atk: float = game.stats(user)[1 if physical else 3] * multiplier(attack_stage)
	var defense: float = game.stats(target)[2 if physical else 4] * multiplier(defense_stage)
	var power = float(move.power)
	if user.hp <= game.stats(user)[0]/3.0:
		if (user.ability=="Overgrow" and move.type=="grass") or (user.ability=="Blaze" and move.type=="fire") or (user.ability=="Torrent" and move.type=="water"): power *= 1.5
	var base = floor(floor(floor(2.0*user.level/5.0+2)*power*atk/defense)/50.0)+2
	if critical: base = floor(base*1.5)
	base = floor(base*roll/100.0)
	if move.type in game.species[str(int(user.species))].types: base = floor(base*1.5)
	base = floor(base*eff)
	if physical and user.status == "burn": base = floor(base*0.5)
	return maxi(1,int(base))

func choose_enemy_move() -> int:
	var best = -1
	var score = -1.0
	for i in range(enemy.moves.size()):
		var slot: Dictionary = enemy.moves[i]
		if slot.pp <= 0: continue
		var m: Dictionary = game.moves[slot.id]
		var value = float(m.power)*effectiveness(m.type,game.species[str(int(game.state.party[active].species))].types)
		if m.category == "status": value = 16.0 if turns < 2 else 1.0
		if value > score:
			score = value
			best = i
	return best

func act(user: Dictionary, target: Dictionary, index: int, log: Array) -> void:
	if user.hp <= 0 or target.hp <= 0: return
	if flinched.get(user.uid,false):
		log.append(str(user.nickname)+" flinched!")
		return
	if user.status == "paralysis" and rng.randf() < 0.25:
		log.append(str(user.nickname)+" is fully paralyzed!")
		return
	var m: Dictionary = game.moves.struggle
	if index >= 0:
		var slot: Dictionary = user.moves[index]
		if slot.pp <= 0: return
		slot.pp -= 1
		m = game.moves[slot.id]
	log.append(str(user.nickname)+" used "+str(m.name)+"!")
	var accuracy = float(m.accuracy) * multiplier(stage(user,"accuracy"),true)
	if m.name not in ["Play Nice","Focus Energy","Withdraw"] and rng.randf()*100 >= accuracy:
		log.append("The move missed!")
		return
	var eff = effectiveness(m.type,game.species[str(int(target.species))].types)
	if m.power > 0:
		if eff == 0:
			log.append("It has no effect.")
			return
		var crit_stage = stage(user,"critical")
		var critical = rng.randf() < ([1.0/16,1.0/8,0.5,1.0][mini(3,crit_stage)])
		var hit = damage(user,target,m,critical,rng.randi_range(85,100))
		target.hp = maxi(0,int(target.hp)-hit)
		log.append("%d damage.%s%s" % [hit," Critical hit!" if critical else "", " Super effective!" if eff>1 else " Not very effective." if eff<1 else ""])
		if m.effect == "recoil": user.hp = maxi(0,int(user.hp)-maxi(1,int(game.stats(user)[0]/4)))
		if target.hp > 0 and m.category == "physical" and target.ability == "Static" and rng.randf()<0.3 and user.status == "" and not "electric" in game.species[str(int(user.species))].types:
			user.status = "paralysis"
			log.append("Static paralyzed "+str(user.nickname)+"!")
	if target.hp <= 0: return
	if m.category == "status":
		match m.effect:
			"focus": change_stage(user,"critical",2)
			"attack_down": change_stage(target,"attack",-1)
			"defense_down": change_stage(target,"defense",-1)
			"accuracy_down":
				if target.ability != "Keen Eye": change_stage(target,"accuracy",-1)
			"defense_up": change_stage(user,"defense",1)
			"seed":
				if not "grass" in game.species[str(int(target.species))].types: seeded[target.uid] = user
		log.append("Battle conditions changed.")
	elif m.effect == "flinch" and rng.randi_range(1,100)<=m.chance:
		flinched[target.uid] = true
	elif m.chance > 0 and rng.randi_range(1,100) <= m.chance and target.status == "":
		var immune = (m.effect=="burn" and "fire" in game.species[str(int(target.species))].types) or (m.effect=="paralysis" and "electric" in game.species[str(int(target.species))].types)
		if not immune:
			target.status = m.effect
			log.append(str(target.nickname)+" received "+str(m.effect)+"!")

func move_turn(index: int) -> Array:
	var log: Array = []
	flinched.clear()
	if ended: return log
	var p: Dictionary = game.state.party[active]
	if p.hp <= 0: return ["Switch to a healthy partner first."]
	var has_pp = false
	for slot in p.moves:
		if slot.pp > 0: has_pp = true
	if has_pp and (index < 0 or index >= p.moves.size() or p.moves[index].pp <= 0): return ["Choose a move with PP."]
	if not has_pp: index = -1
	var other = choose_enemy_move()
	var a: Dictionary = game.moves[p.moves[index].id] if index >= 0 else game.moves.struggle
	var b: Dictionary = game.moves[enemy.moves[other].id] if other >= 0 else game.moves.struggle
	var first: bool = a.priority > b.priority or (a.priority==b.priority and (speed(p)>speed(enemy) or (speed(p)==speed(enemy) and rng.randf()<0.5)))
	if first:
		act(p,enemy,index,log)
		act(enemy,p,other,log)
	else:
		act(enemy,p,other,log)
		act(p,enemy,index,log)
	end_turn(log)
	return log

func end_turn(log: Array) -> void:
	turns += 1
	for p in [game.state.party[active],enemy]:
		if p.hp <= 0: continue
		if p.status == "burn":
			p.hp = maxi(0,int(p.hp)-maxi(1,int(game.stats(p)[0]/8)))
			log.append(str(p.nickname)+" was hurt by its burn.")
		if seeded.has(p.uid) and p.hp > 0:
			var recipient: Dictionary = seeded[p.uid]
			if recipient.hp > 0:
				var amount = mini(int(p.hp),maxi(1,int(game.stats(p)[0]/8)))
				p.hp -= amount
				recipient.hp = mini(game.stats(recipient)[0],int(recipient.hp)+amount)
				log.append("Leech Seed drained HP.")
	if enemy.hp <= 0:
		ended = true
		log.append("Opponent fainted. You won!")
		# Development reward; full species XP yields and participant distribution pending.
		var p: Dictionary = game.state.party[active]
		if p.hp > 0: log.append_array(game.gain_xp(p,int(enemy.level)*18))
		game.state.money += 40 if trainer else 0
	else:
		var alive = false
		for p in game.state.party:
			if p.hp > 0: alive = true
		if not alive:
			ended = true
			game.heal()
			log.append("Your party fainted. You returned to town and were healed.")
		elif game.state.party[active].hp <= 0: log.append("Your partner fainted. Choose Pokémon to switch.")
	game.changed.emit()

func switch_to(index: int) -> Array:
	if ended or index == active or index < 0 or index >= game.state.party.size() or game.state.party[index].hp <= 0: return ["Choose a different healthy partner."]
	stages.erase(game.state.party[active].uid)
	seeded.erase(game.state.party[active].uid)
	var forced: bool = game.state.party[active].hp <= 0
	active = index
	var log: Array = ["Go, "+str(game.state.party[active].nickname)+"!"]
	if not forced:
		act(enemy,game.state.party[active],choose_enemy_move(),log)
		end_turn(log)
	return log

func use_potion() -> Array:
	if ended: return []
	if game.state.party[active].hp <= 0: return ["Switch first."]
	var result: String = game.potion(active)
	var log: Array = [result]
	if result.begins_with("Restored"):
		act(enemy,game.state.party[active],choose_enemy_move(),log)
		end_turn(log)
	return log

func capture() -> Array:
	if ended: return []
	if trainer: return ["You cannot catch another trainer's Pokémon."]
	if game.state.party[active].hp <= 0: return ["Switch first."]
	if game.state.items.poke_ball <= 0: return ["No Poké Balls left."]
	game.state.items.poke_ball -= 1
	var max_hp: int = game.stats(enemy)[0]
	var rate = float(game.species[str(int(enemy.species))].catch)
	var status_bonus = 1.5 if enemy.status != "" else 1.0
	var a = floor((3.0*max_hp-2.0*enemy.hp)*rate/(3.0*max_hp)*status_bonus)
	var caught = a>=255
	if not caught and a>0:
		var b = 65536.0/pow(255.0/a,0.1875)
		caught = true
		for i in range(4):
			if rng.randi_range(0,65535)>=b: caught = false
	if caught:
		ended = true
		game.own(enemy)
		return ["Caught "+str(enemy.nickname)+"! "+("Sent to PC storage." if game.state.party.size()>=6 and enemy in game.state.boxes else "Joined your party.")]
	var log: Array = ["It broke free!"]
	act(enemy,game.state.party[active],choose_enemy_move(),log)
	end_turn(log)
	return log

func flee() -> Array:
	if ended: return []
	if trainer: return ["You cannot run from a trainer battle."]
	if game.state.party[active].hp <= 0: return ["Switch first."]
	# Development escape is guaranteed; Gen VI escape odds pending.
	ended = true
	return ["Got away safely."]
