"""Developer-only validation: python -m pip install lupa Pillow; python Tests/validate.py."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
from PIL import Image

root=Path(__file__).resolve().parent.parent
lua=LuaRuntime(unpack_returned_tuples=True)
toc=(root/'PetPulseForever.toc').read_text(encoding='utf-8').splitlines()
files=[line for line in toc if line and not line.startswith('#')]
assert len(files)==18 and len(set(files))==18
compile_lua=lua.eval('function(s,n) local f,e=loadstring(s,n); assert(f,e); return f end')
for path in root.rglob('*.lua'):
    compile_lua(path.read_text(encoding='utf-8'),str(path))
print('PASS Lua 5.1 compilation: all Lua files',flush=True)
lua.execute((root/'Tests/Mock.lua').read_text(encoding='utf-8'))
ns=lua.table();lua.globals().TEST_NS=ns
for name in files:
    assert (root/name).is_file(),name
    compile_lua((root/name).read_text(encoding='utf-8'),name)('PetPulseForever',ns)
print('PASS TOC paths and load order',flush=True)
lua.execute((root/'Tests/Run.lua').read_text(encoding='utf-8'))
lua.execute((root/'Tests/Guide.lua').read_text(encoding='utf-8'))
for name in ['disc','mask','ring','pip','happy','content','unhappy']:
    im=Image.open(root/'Media'/(name+'.tga'))
    assert im.size==(64,64) and im.mode=='RGBA'
print('PASS all referenced assets: 7 RGBA power-of-two TGA files',flush=True)
im=Image.open(root/'Media/shard.tga');assert im.size==(256,256) and im.mode=='RGBA'
print('PASS connected shard RGBA 256px texture',flush=True)
print('LIMITATION: mocked API; no real WoW secure execution or in-game rendering tested.',flush=True)

for name in ["portrait-halo","portrait-frame","portrait-gem"]:
    im=Image.open(root/"Media"/(name+".tga"));assert im.size==(128,128) and im.mode=="RGBA"
print("PASS permanent portrait textures")
im=Image.open(root/'Media/socket.tga');assert im.size==(64,64) and im.mode=='RGBA'
print('PASS open satellite socket texture')

for animal in ['wolf','fox','cat','crocolisk','bat','bear','birdofprey','boar','carrionbird','corehound','crab','gorilla','hyena','raptor','scorpid','spider','tallstrider','turtle','windserpent']:
    for mood in ['happy','content','unhappy']:
        im=Image.open(root/'Media'/f'mood-{animal}-{mood}.tga')
        assert im.size==(128,128) and im.mode=='RGBA'
        assert im.getextrema()[3]==(0,255)
print('PASS 57 mood textures: correct dimensions and genuine transparency')

for name,size in [('logo',(512,128)),('hover-ring',(128,128)),('menu-medallion',(128,128))]:
    im=Image.open(root/'Media'/(name+'.tga'))
    assert im.mode=='RGBA' and im.size==size
    assert im.getpixel((0,0))[3]==0
print('PASS native logo and circular ornaments; transparent corners')

im=Image.open(root/'Media/xp-ring.tga')
assert im.size==(1024,512) and im.mode=='RGBA'
assert im.crop((0,0,64,64)).getbbox() is None
for step in (25,50,75,100):
    tile=im.crop(((step%16)*64,(step//16)*64,(step%16+1)*64,(step//16+1)*64))
    assert tile.getbbox() is not None and tile.getpixel((32,32))[3]==0
print('PASS XP ring atlas: empty zero, visible progress and clear portrait center')


im=Image.open(root/"Media/minimap.tga");assert im.size==(64,64) and im.mode=="RGBA" and im.getpixel((0,0))[3]==0
print("PASS standalone minimap paw: RGBA 64px with transparent corners")
