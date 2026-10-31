"""Pinned PokeAPI reference snapshot. Runtime is deliberately curated separately.
No models, ROM contents, sprites, music or flavor text are imported.
"""
import csv, hashlib, io, json, pathlib, urllib.request
from concurrent.futures import ThreadPoolExecutor
ROOT=pathlib.Path(__file__).resolve().parents[1]
COMMIT='2bf639e5572812a67d2b94903fdcb9d095f5aeb2'
BASE=f'https://raw.githubusercontent.com/PokeAPI/pokeapi/{COMMIT}/'
FILES=['pokemon','pokemon_species','pokemon_stats','pokemon_stats_past','pokemon_types','pokemon_types_past','pokemon_abilities','pokemon_abilities_past','abilities','moves','move_changelog','pokemon_moves','types','version_groups','pokemon_evolution','evolution_triggers','natures','growth_rates']
OUT=ROOT/'data'/'reference'
OUT.mkdir(parents=True,exist_ok=True)
def fetch(name):
    url=BASE+'data/v2/csv/'+name+'.csv'
    raw=urllib.request.urlopen(url,timeout=60).read()
    return name,list(csv.DictReader(io.StringIO(raw.decode()))),{'url':url,'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
results=list(ThreadPoolExecutor(max_workers=6).map(fetch,FILES))
tables={n:rows for n,rows,_ in results}
manifest={n:meta for n,_,meta in results}
# Retain relevant rows in source schema. Historical changes remain explicit for auditing.
ids=set(range(1,494))
filtered={}
for name,rows in tables.items():
    if name=='pokemon': rows=[r for r in rows if int(r['id']) in ids]
    elif name=='pokemon_species': rows=[r for r in rows if int(r['id']) in ids]
    elif name.startswith('pokemon_') and name!='pokemon_evolution': rows=[r for r in rows if int(r['pokemon_id']) in ids]
    elif name=='pokemon_evolution': rows=[r for r in rows if int(r['evolved_species_id']) in ids]
    filtered[name]=rows
    (OUT/(name+'.json')).write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
# Exact X/Y learnsets, not ORAS or original-generation learnsets.
xy={str(i):{'level_up':[],'machine':[],'egg':[],'tutor':[]} for i in ids}
method={'1':'level_up','2':'egg','3':'tutor','4':'machine'}
for row in filtered['pokemon_moves']:
    if row['version_group_id']=='15' and row['pokemon_move_method_id'] in method:
        xy[row['pokemon_id']][method[row['pokemon_move_method_id']]].append({'move_id':int(row['move_id']),'level':int(row['level'])})
(OUT/'xy_learnsets.json').write_text(json.dumps(xy,indent=2)+'\n')
# Raw all-version move rows are unnecessary once exact XY selection is extracted.
(OUT/'pokemon_moves.json').unlink()
(OUT/'manifest.json').write_text(json.dumps({'repository':'https://github.com/PokeAPI/pokeapi','commit':COMMIT,'files':manifest,'version_group':15,'note':'Reference only; modern stats, types, abilities and moves require historical rollback before runtime use. Evolution rows require Gen VI audit. No redistribution rights to Pokemon art are implied.'},indent=2)+'\n')
print('Imported',len(filtered['pokemon_species']),'species reference records and exact X/Y learnset rows:',sum(len(v['level_up']) for v in xy.values()))
