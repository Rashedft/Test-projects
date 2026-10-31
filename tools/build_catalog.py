"""Normalize the offline reference into a Gen-VI base-form catalog.
This catalog is not automatically activated by the playable build: battle effects,
evolution conditions, XP yields and presentation need separate implementation/audit.
"""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]/'data'
def load(n): return json.loads((R/'reference'/(n+'.json')).read_text())
def write(n,v): (R/'catalog').mkdir(exist_ok=True);(R/'catalog'/(n+'.json')).write_text(json.dumps(v,indent=2)+'\n')
types={r['id']:r['identifier'] for r in load('types')}
abilities={r['id']:r['identifier'] for r in load('abilities')}
stat_map={}; type_map={}; ability_map={}
for row in load('pokemon_stats'): stat_map.setdefault(row['pokemon_id'],{})[row['stat_id']]=int(row['base_stat'])
for row in sorted(load('pokemon_stats_past'),key=lambda r:int(r['generation_id']),reverse=True):
 if int(row['generation_id'])>=6 and row['stat_id'] in ['1','2','3','4','5','6']:
  stat_map.setdefault(row['pokemon_id'],{})[row['stat_id']]=int(row['base_stat'])
for row in load('pokemon_types'): type_map.setdefault(row['pokemon_id'],{})[row['slot']]=types[row['type_id']]
# A past type group is a complete replacement, not additive (e.g. a Fairy change).
past_types={}
for row in load('pokemon_types_past'):
 if int(row['generation_id'])>=6: past_types.setdefault((row['pokemon_id'],int(row['generation_id'])),{})[row['slot']]=types[row['type_id']]
for (id,generation),slots in sorted(past_types.items(),key=lambda x:x[0][1],reverse=True): type_map[id]=slots
for row in load('pokemon_abilities'): ability_map.setdefault(row['pokemon_id'],{})[row['slot']]={'name':abilities[row['ability_id']],'hidden':row['is_hidden']=='1'}
for row in sorted(load('pokemon_abilities_past'),key=lambda r:int(r['generation_id']),reverse=True):
 if int(row['generation_id'])>=6:
  slots=ability_map.setdefault(row['pokemon_id'],{})
  if row['ability_id']: slots[row['slot']]={'name':abilities[row['ability_id']],'hidden':row['is_hidden']=='1'}
  else: slots.pop(row['slot'],None)
growth={r['id']:r['identifier'] for r in load('growth_rates')}
xy=load('xy_learnsets')
move_rows={r['id']:r.copy() for r in load('moves') if int(r['id'])<=617}
for row in sorted(load('move_changelog'),key=lambda r:int(r['changed_in_version_group_id']),reverse=True):
 if int(row['changed_in_version_group_id'])>15 and row['move_id'] in move_rows:
  for k,v in row.items():
   if k in move_rows[row['move_id']] and v: move_rows[row['move_id']][k]=v
moves={id:{'id':int(id),'key':m['identifier'],'type':types[m['type_id']],'power':int(m['power']) if m['power'] else None,'accuracy':int(m['accuracy']) if m['accuracy'] else None,'pp':int(m['pp']) if m['pp'] else None,'priority':int(m['priority']),'category':{'1':'status','2':'physical','3':'special'}[m['damage_class_id']],'target_id':int(m['target_id']),'effect_id':int(m['effect_id']) if m['effect_id'] else None,'effect_chance':int(m['effect_chance']) if m['effect_chance'] else None,'implemented_in_runtime':m['identifier'].replace('-','_') in json.loads((R/'moves.json').read_text())} for id,m in move_rows.items()}
# PokeAPI's move_changelog schema omits damage class. Showdown's Gen VI
# override independently records Water Shuriken as Physical; see SOURCES.md.
water_shuriken=next(m for m in moves.values() if m['key']=='water-shuriken')
water_shuriken['category']='physical'
species={}
for r in load('pokemon_species'):
 id=r['id']
 species[id]={'id':int(id),'key':r['identifier'],'types':[v for _,v in sorted(type_map[id].items())],'base_stats':[stat_map[id][str(i)] for i in range(1,7)],'abilities':list(ability_map[id].values()),'growth_rate':growth[r['growth_rate_id']],'learnset_version_group':'x-y','learnsets':xy[id],'capture_rate_reference':int(r['capture_rate']),'gender_rate':int(r['gender_rate']),'base_happiness_reference':int(r['base_happiness']),'evolution_chain_id':int(r['evolution_chain_id']),'runtime_ready':False}
write('species',species);write('moves',moves)
write('README',{'status':'Reference catalog; not a complete game implementation.','species':493,'moves':617,'forms':'National Dex base/default forms only. No Mega forms or stones.','historical_fields':'Gen VI stats/types/abilities and X/Y learnsets; move field changes rolled back to version group 15.','pending_audit':['Capture and friendship historical overrides','Gen VI evolution condition extraction','Move effect/target semantics','Ability effect implementation','XP yield history','Alternate non-Mega forms','TM/HM item-number mappings'],'source_commit':load('manifest')['commit']})
assert len(species)==493 and set(map(int,species))==set(range(1,494))
assert species['35']['types']==['fairy']
assert species['94']['abilities'][0]['name']=='levitate'
assert species['51']['base_stats'][1]==80
assert water_shuriken['category']=='physical'
assert moves['33']['power']==50
assert moves['141']['power']==20  # Leech Life, before the Gen VII buff
assert moves['282']['power']==65  # Knock Off buff already present in XY
for s in species.values():
 assert len(s['base_stats'])==6 and len(s['types']) in [1,2]
 for method,rows in s['learnsets'].items():
  for row in rows: assert str(row['move_id']) in moves,(s['key'],row)
print('Catalog normalized: 493 species, 617 move records; historical regression and all learnset references passed')
