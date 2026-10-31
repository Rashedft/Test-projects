"""Package the tested Windows executable and source without recursive download ZIPs."""
from pathlib import Path
import argparse, hashlib, struct, zipfile
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--version',required=True);p.add_argument('--out',default='/workspace/artifacts');args=p.parse_args()
out=Path(args.out);out.mkdir(parents=True,exist_ok=True)
exe=ROOT/'builds/PokeJourney.exe';raw=exe.read_bytes()
assert raw[:2]==b'MZ' and raw[-4:]==b'GDPC','Missing PE executable or embedded PCK'
pe=struct.unpack_from('<I',raw,0x3c)[0]
assert raw[pe:pe+4]==b'PE\0\0' and struct.unpack_from('<H',raw,pe+4)[0]==0x8664,'Not an x86-64 PE build'
windows=out/f'PokeJourney-{args.version}-Windows.zip'
source=out/f'PokeJourney-{args.version}-Source.zip'
with zipfile.ZipFile(windows,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 z.write(exe,'PokeJourney/PokeJourney.exe');z.write(ROOT/'builds/PLAY.txt','PokeJourney/PLAY.txt')
 for name in ['TESTING.md','POKEAPI-LICENSE.txt','GODOT-LICENSE.txt','EXPORT_RESULTS.txt']:
  z.write(ROOT/'documentation'/name,'PokeJourney/'+name)
with zipfile.ZipFile(source,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for file in sorted(ROOT.rglob('*')):
  rel=file.relative_to(ROOT)
  if not file.is_file() or rel.parts[0] in ['.git','.godot','builds','downloads','.runtime']:continue
  if '__pycache__' in rel.parts:continue
  z.write(file,'PokeJourney/'+rel.as_posix())
 z.writestr('PokeJourney/builds/.gitkeep','')
for archive in [windows,source]:
 with zipfile.ZipFile(archive) as z:assert z.testzip() is None
 print(archive.name,archive.stat().st_size,'bytes')
(out/f'PokeJourney-{args.version}-SHA256SUMS.txt').write_text(''.join(hashlib.sha256(file.read_bytes()).hexdigest()+'  '+file.name+'\n' for file in [windows,source]))
