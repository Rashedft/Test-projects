"""Validate the playable subset against pinned, historical X/Y reference rows."""
import json,pathlib
R=pathlib.Path(__file__).resolve().parents[1]/'data'
def read(n): return json.loads((R/n).read_text())
ref=lambda n:read('reference/'+n+'.json')
species=read('species.json'); moves=read('moves.json')
ref_moves={x['identifier'].replace('-','_'):x for x in ref('moves')}
types={x['id']:x['identifier'] for x in ref('types')}
xy=read('reference/xy_learnsets.json')
checks=0
def check(ok,msg):
 global checks
 checks+=1
 assert ok,msg
for id,p in species.items():
 stats={x['stat_id']:int(x['base_stat']) for x in ref('pokemon_stats') if x['pokemon_id']==id}
 for row in sorted(ref('pokemon_stats_past'),key=lambda x:int(x['generation_id']),reverse=True):
  if row['pokemon_id']==id and int(row['generation_id'])>=6: stats[row['stat_id']]=int(row['base_stat'])
 check(p['base']==[stats[str(i)] for i in range(1,7)],f'{id}: stats')
 expected_types=[types[x['type_id']] for x in sorted(ref('pokemon_types'),key=lambda x:int(x['slot'])) if x['pokemon_id']==id]
 # Curated species have no post-Gen-VI type changes; fail closed if that changes.
 check(not any(x['pokemon_id']==id and int(x['generation_id'])>=6 for x in ref('pokemon_types_past')),f'{id}: needs historical type override')
 check(p['types']==expected_types,f'{id}: types')
 move_ids={int(x['id']):x['identifier'].replace('-','_') for x in ref('moves')}
 expected=sorted([(x['level'],move_ids[x['move_id']]) for x in xy[id]['level_up'] if x['level']<=10])
 check(sorted(map(tuple,p['learn']))==expected,f'{id}: exact X/Y learnset through level 10')
for key,m in moves.items():
 if key=='struggle': continue
 source=ref_moves[key].copy()
 for row in sorted(ref('move_changelog'),key=lambda x:int(x['changed_in_version_group_id']),reverse=True):
  if row['move_id']==source['id'] and int(row['changed_in_version_group_id'])>15:
   for k,v in row.items():
    if v and k in source: source[k]=v
 for k in ['power','accuracy','pp','priority']:
  # Missing accuracy denotes an always-hit move. Runtime stores 100 plus explicit always-hit handling.
  expected=int(source[k]) if source[k] else (100 if k=='accuracy' else 0)
  check(m[k]==expected,f'{key}: {k}: {m[k]} != {expected}')
 check(m['type']==types[source['type_id']],f'{key}: move type')
 check(m['category']=={'1':'status','2':'physical','3':'special'}[source['damage_class_id']],f'{key}: category')
print(f'{checks} historical data checks passed')
