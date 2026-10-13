"""Local conservative super-resolution. Never overwrites original assets."""
from pathlib import Path
from PIL import Image, ImageDraw
import hashlib, json, subprocess, time

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'landing-desktop/assets'
OUTPUT = ROOT / 'output/BOXZY-HD-20260929'
ENGINE = Path(__file__).resolve().parent
MASTERS = OUTPUT / '高清PNG'
WEB = OUTPUT / '网页WebP'
QA = OUTPUT / '对比检查'
WORK = OUTPUT / '.working'
for folder in [MASTERS, WEB, QA, WORK]:
    folder.mkdir(parents=True, exist_ok=True)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def compare(src, result, name):
    # Identical crop and display scale; original uses ordinary Lanczos enlargement.
    full = name == 'logo'
    w, h = result.size
    if full:
        box = (0, 0, w, h)
    elif name.startswith('14-'):
        box = (int(w*.08), int(h*.06), int(w*.62), int(h*.42))
    elif name == 'hero-art':
        box = (int(w*.52), int(h*.25), int(w*.78), int(h*.56))
    elif name == 'shop-scene':
        box = (int(w*.39), int(h*.20), int(w*.72), int(h*.73))
    else:
        box = (int(w*.10), int(h*.12), int(w*.90), int(h*.90))
    a = src.resize(result.size, Image.Resampling.LANCZOS).crop(box)
    b = result.crop(box)
    a.thumbnail((700,650),Image.Resampling.LANCZOS)
    b = b.resize(a.size,Image.Resampling.LANCZOS)
    sheet = Image.new('RGB',(a.width*2+36,a.height+62),(20,20,20))
    draw = ImageDraw.Draw(sheet)
    draw.text((12,16),'Original, enlarged to same display size',fill='white')
    draw.text((a.width+24,16),'Conservative super-resolution',fill='white')
    for im,x in [(a,12),(b,a.width+24)]:
        sheet.paste(im,(x,48),im.getchannel('A') if im.mode=='RGBA' else None)
    sheet.save(QA / f'{name}-compare.png')

records=[]
files=sorted(p for p in SOURCE.iterdir() if p.suffix.lower() in ['.png','.webp'])
for i,path in enumerate(files,1):
    start=time.time()
    before=digest(path)
    original=Image.open(path)
    transparent='A' in original.getbands()
    mode='RGBA' if transparent else 'RGB'
    original=original.convert(mode)
    scale=4 if path.suffix=='.webp' else 2
    target=(original.width*scale,original.height*scale)
    method='Real-ESRGAN x4plus + original blend'
    weight=0.60 if path.suffix=='.webp' else 0.50
    dest=MASTERS / f'{path.stem}-{scale}x.png'
    print(f'[{i}/{len(files)}] {path.name} -> {target}',flush=True)
    if path.stem=='logo':
        result=original.resize(target,Image.Resampling.LANCZOS)
        weight=0
        method='Lanczos 2x; no neural modification to brand mark'
    else:
        raw=WORK / f'{path.stem}-raw4x.png'
        sample=OUTPUT / 'sample-team-up-4x.png'
        if path.name=='14-team-up-booster-box.webp' and sample.exists():
            raw=sample
        if not raw.exists():
            cmd=[str(ENGINE/'realesrgan-ncnn-vulkan'),'-i',str(path),'-o',str(raw),
                 '-n','realesrgan-x4plus','-s','4','-t','128','-m',str(ENGINE/'models'),'-j','1:1:1']
            with (WORK/f'{path.stem}.log').open('w') as log:
                subprocess.run(cmd,stdout=log,stderr=log,check=True)
        neural=Image.open(raw).convert(mode)
        if neural.size != (original.width*4,original.height*4):
            raise RuntimeError('Unexpected model dimensions: '+path.name)
        if neural.size!=target:
            neural=neural.resize(target,Image.Resampling.LANCZOS)
        base=original.resize(target,Image.Resampling.LANCZOS)
        result=Image.blend(base,neural,weight)
        if transparent:
            result.putalpha(original.getchannel('A').resize(target,Image.Resampling.LANCZOS))
        neural.close()
    result.save(dest,compress_level=6)
    web=WEB / f'{path.stem}-{scale}x.webp'
    result.save(web,format='WEBP',lossless=True,method=4,exact=True)
    assert digest(path)==before, 'Original changed'
    with Image.open(dest) as check:
        check.load()
        assert check.size==target
        assert ('A' in check.getbands())==transparent
        if transparent:
            assert check.getchannel('A').tobytes()==original.getchannel('A').resize(target,Image.Resampling.LANCZOS).tobytes()
    compare(original,result,path.stem)
    records.append({'source':str(path.relative_to(ROOT)),'sha256':before,'source_size':original.size,
                    'output_size':target,'scale':scale,'method':method,'neural_blend':weight,
                    'alpha_preserved':transparent,'png':str(dest.relative_to(OUTPUT)),
                    'webp':str(web.relative_to(OUTPUT)),'seconds':round(time.time()-start,1)})
    (OUTPUT/'manifest.json').write_text(json.dumps(records,indent=2,ensure_ascii=False))
    print(f'  saved; {records[-1]["seconds"]}s',flush=True)
    result.close();original.close()
print('COMPLETE: '+str(len(records))+' assets',flush=True)
