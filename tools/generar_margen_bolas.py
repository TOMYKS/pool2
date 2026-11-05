"""Genera margen de 32 texeles fuera de las islas; no modifica el interior ni originales."""
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import json
root=Path(__file__).resolve().parents[1]
paths=json.loads((root/'tools/bolas_texturas.json').read_text())
entries=[]
for path in paths:
    src=root/path.removeprefix('res://')
    img=Image.open(src).convert('RGB'); rgb=np.array(img)
    mask=Image.fromarray(np.where(rgb.max(axis=2)<=2,255,0).astype('uint8')).copy()
    # Solo negro conectado al borde: conservar números y rayaduras interiores.
    w,h=mask.size
    for x,y in [(x,y) for x in range(w) for y in (0,h-1)]+[(x,y) for y in range(h) for x in (0,w-1)]:
        if mask.getpixel((x,y))==255: ImageDraw.floodfill(mask,(x,y),128)
    outside=np.array(mask)==128
    # Retirar también 4 texeles de borde antialiasado contaminado por negro.
    for _ in range(4):
        outside |= np.roll(outside,1,0) | np.roll(outside,-1,0) | np.roll(outside,1,1) | np.roll(outside,-1,1)
    original=rgb.copy(); known=~outside
    for _ in range(32):
        previous=known.copy()
        for axis,shift in [(0,1),(0,-1),(1,1),(1,-1)]:
            neighbor=np.roll(previous,shift,axis=axis)
            if axis==0: neighbor[0 if shift==1 else -1,:]=False
            else: neighbor[:,0 if shift==1 else -1]=False
            take=(~known)&neighbor
            rgb[take]=np.roll(rgb,shift,axis=axis)[take]
            known[take]=True
    assert np.array_equal(rgb[~outside],original[~outside])
    assert np.count_nonzero(np.any(rgb != original, axis=2)) > 1000, src.name
    dest=root/'assets/bolas_sin_costuras'/src.name
    Image.fromarray(rgb).save(dest)
    # Mantener mipmaps; evitar bloques de compresión en los márgenes.
    settings=src.with_suffix('.png.import').read_text()
    params=settings[settings.index('[params]'):].replace('compress/mode=2','compress/mode=0')
    dest.with_suffix('.png.import').write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n'+params)
    entries.append('    "%s": preload("res://assets/bolas_sin_costuras/%s"),'%(path,src.name))
(root/'scripts/texturas_bolas.gd').write_text('extends RefCounted\n\nconst ALBEDOS := {\n'+'\n'.join(entries)+'\n}\n',encoding='utf8')
print('16 texturas generadas; píxeles interiores intactos')



