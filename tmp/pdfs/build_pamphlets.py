from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
from PIL import Image
from pypdf import PdfReader
import zipfile
root=Path('/Users/thulanimoyo/Documents/Work/ArticSentinel')
assets=root/'output/marketing/articsentinel-pamphlets-20261010'
output=root/'output/pdf/ArticSentinel-three-pamphlets.pdf'
w,h=140*mm,210*mm
pdf=canvas.Canvas(str(output),pagesize=(w,h),pageCompression=1)
pdf.setTitle('ArticSentinel | Three gas-monitoring pamphlets')
pdf.setAuthor('ArticSentinel')
for name in ['01-mid-meal.png','02-dinner.png','03-how-much.png']:
 path=assets/name
 with Image.open(path) as im:
  print(name, im.size)
 pdf.drawImage(str(path),0,0,width=w,height=h,preserveAspectRatio=True,anchor='c')
 pdf.showPage()
pdf.save()
assert len(PdfReader(output).pages)==3
(assets/'README.txt').write_text('ArticSentinel pamphlets — 10 October 2026\n\nThree finished PNG designs plus a three-page PDF (140 × 210 mm portrait).\nPhone/WhatsApp supplied by the user: +27 66 253 8281.\nWebsite: articsentinel.com.\nEmail: support@articsentinel.com (from the project contact section).\nAdvertised price: R2 100, as supplied.\nSouth African flag and origin wording used as requested; no certification emblem.\nIllustrations are stylized product/app visuals.\nCreated with the built-in image-generation tool; complete generation prompts included.\n')
zip_path=root/'output/marketing/ArticSentinel-three-pamphlets.zip'
with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted(assets.iterdir()):
  if p.is_file(): z.write(p,p.name)
 z.write(output,output.name)
print(output)
print(zip_path)
