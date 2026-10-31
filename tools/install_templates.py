"""Fetch only official Windows templates using HTTPS byte ranges.
ZIP size/CRC verification is retained; no third-party executable sources.
"""
import urllib.request,struct,zlib,pathlib,os
url='https://github.com/godotengine/godot/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz'
def getrange(start,end):
 req=urllib.request.Request(url,headers={'Range':f'bytes={start}-{end}'})
 with urllib.request.urlopen(req,timeout=60) as f:
  if f.status!=206: raise RuntimeError('Server did not honor range; stopping partial download')
  return f.read()
with urllib.request.urlopen(urllib.request.Request(url,method='HEAD'),timeout=60) as response:
 total=int(response.headers['Content-Length'])
tail=getrange(total-65536,total-1)
i=tail.rfind(b'PK\x05\x06')
e=struct.unpack_from('<4s4H2LH',tail,i)
size,offset=e[5],e[6]
central=getrange(offset,offset+size-1)
# Parse central directory metadata without fetching unrelated platforms.
pos=0
out=pathlib.Path(os.environ.get('XDG_DATA_HOME','/workspace/.runtime/godot/data'))/'godot/export_templates/4.6.3.stable';out.mkdir(parents=True,exist_ok=True)
while pos<len(central):
 fields=struct.unpack_from('<4s6H3L5H2L',central,pos)
 name_len,extra_len,comment_len=fields[10:13]
 name=central[pos+46:pos+46+name_len].decode()
 compressed,crc,uncompressed,local=fields[8],fields[7],fields[9],fields[16]
 if name in ['templates/windows_release_x86_64.exe','templates/windows_debug_x86_64.exe']:
  target=out/name.split('/')[-1]
  if target.exists():
   cached=target.read_bytes()
   if len(cached)==uncompressed and zlib.crc32(cached)==crc:
    print(name,'cached template integrity verified',flush=True)
    pos+=46+name_len+extra_len+comment_len
    continue
  header=getrange(local,local+29)
  h=struct.unpack('<4s5H3L2H',header)
  start=local+30+h[-2]+h[-1]
  data=getrange(start,start+compressed-1)
  raw=zlib.decompress(data,-15) if fields[4]==8 else data
  assert len(raw)==uncompressed and zlib.crc32(raw)==crc,'ZIP integrity failed'
  (out/name.split('/')[-1]).write_bytes(raw)
  print(name,len(raw),'verified ZIP CRC',flush=True)
 pos+=46+name_len+extra_len+comment_len
