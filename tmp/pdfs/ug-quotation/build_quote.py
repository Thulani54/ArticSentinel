from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import Paragraph, Table, TableStyle
from reportlab.lib.styles import ParagraphStyle
from pathlib import Path
from pypdf import PdfReader
import re

OUT=Path('/Users/thulanimoyo/Downloads/Quotation_Uncovering_Greatness_Mr_Caiphus_R87000.pdf')
W,H=A4; M=40; CW=W-2*M
c=canvas.Canvas(str(OUT),pagesize=A4)
c.setTitle('Quotation | Uncovering Greatness | Mr Caiphus | R87,000')
c.setAuthor('Mr Caiphus')
BLACK=colors.HexColor('#171717'); GREY=colors.HexColor('#666666'); LIGHT=colors.HexColor('#f3f3f3'); LINE=colors.HexColor('#cccccc')
body=ParagraphStyle('body',fontName='Helvetica',fontSize=9.5,leading=13.2,textColor=BLACK,spaceAfter=0)
small=ParagraphStyle('small',parent=body,fontSize=8.4,leading=11.5)
y=0

def para(text,x,y,width=CW,style=body):
 p=Paragraph(text,style); _,h=p.wrap(width,1000); p.drawOn(c,x,y-h); return y-h

def txt(text,x,y,size=9,bold=False,color=BLACK):
 c.setFillColor(color);c.setFont('Helvetica-Bold' if bold else 'Helvetica',size);c.drawString(x,y,text)

def right(text,x,y,size=9,bold=False,color=BLACK):
 c.setFillColor(color);c.setFont('Helvetica-Bold' if bold else 'Helvetica',size);c.drawRightString(x,y,text)

def footer(n):
 c.setStrokeColor(LINE);c.setLineWidth(.5);c.line(M,36,W-M,36)
 txt('MR CAIPHUS  |  QUO-UG-20261108  |  SOFTWARE DEVELOPMENT',M,24,7,color=GREY)
 right(f'{n} / 4',W-M,24,7,color=GREY)

def pagehead(n,title,sub):
 global y
 txt('QUOTATION',M,H-65,25,True)
 right('QUO-UG-20261108',W-M,H-53,9,True)
 right('08/11/2026',W-M,H-68,9,color=GREY)
 c.setStrokeColor(LINE);c.line(M,H-84,W-M,H-84)
 txt(title,M,H-113,16,True)
 y=para(sub,M,H-128,style=small)-20

def section(title,text):
 global y
 txt(title,M,y,10.3,True);y-=8
 y=para(text,M,y)-16

def table(rows,widths,header=True,font=9,pad=7):
 global y
 sty=ParagraphStyle('cell',parent=body,fontSize=font,leading=font+3)
 data=[[Paragraph(str(v),sty) for v in row] for row in rows]
 t=Table(data,colWidths=widths)
 cmds=[('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),pad),('RIGHTPADDING',(0,0),(-1,-1),pad),('TOPPADDING',(0,0),(-1,-1),pad),('BOTTOMPADDING',(0,0),(-1,-1),pad),('LINEABOVE',(0,0),(-1,0),.6,LINE),('LINEBELOW',(0,-1),(-1,-1),.6,LINE),('LINEBELOW',(0,0),(-1,-2),.4,LINE)]
 if header:cmds.append(('BACKGROUND',(0,0),(-1,0),LIGHT))
 t.setStyle(TableStyle(cmds)); _,h=t.wrap(CW,1000);t.drawOn(c,M,y-h);y-=h+16

def end(n):
 assert y>=54,(n,y)
 footer(n);c.showPage()

# Page 1: invoice-generator layout, changed to a quotation.
txt('QUOTATION',M,H-72,32,True)
metadata=[('NUMBER:','QUO-UG-20261108'),('REFERENCE:','UG Business Review'),('DATE:','08/11/2026'),('VALID UNTIL:','22/11/2026'),('PAGE:','1/4')]
for i,(label,value) in enumerate(metadata):
 yy=H-46-i*14;txt(label,310,yy,8,color=GREY);txt(value,400,yy,8,True)
top=H-165
for x,label in [(M,'FROM'),(305,'TO')]:txt(label,x,top,9,color=GREY)
txt('Mr Caiphus',M,top-23,14,True)
txt('Software development',M,top-43,9)
txt('Uncovering Greatness',305,top-23,14,True)
txt('The Sales Coach (Pty) Ltd',305,top-42,10)
txt('Attention: Barry',305,top-59,9)
y=top-100
y=para('<b>Business Review Platform - Phase 1</b><br/>Responsive web application based on the supplied developer brief and existing in-house development.',M,y)-20
items=[('Discovery, existing-code review & design',8000),('Diagnostic & Snapshot assessment engine',18000),('Scoring, dashboards & historical results',14000),('Client, administrator & consultant accounts',12000),('Branded PDF report generation',11000),('Payments, packages, subscriptions & teams',16000),('Testing, deployment, training & handover',8000)]
assert sum(v for _,v in items)==87000
rows=[['<b>Description</b>','<b>Qty</b>','<b>Unit price</b>','<b>Total</b>']]
rows += [[desc,'1',f'R{price:,.2f}',f'R{price:,.2f}'] for desc,price in items]
table(rows,[CW-209,40,83,86],font=9,pad=8)
y=para('The scope, milestone payments and proposed terms on pages 2-4 form part of this quotation.',M,y,style=small)-12
c.setStrokeColor(LINE);c.line(M,195,W-M,195)
para('<b>PAYMENT INFORMATION</b><br/>Payments follow accepted milestones.<br/>Banking details will be supplied by Mr Caiphus<br/>on the relevant milestone invoice.',M,176,255,small)
right('Discount: R0.00',W-M,174,9)
right('FINAL DEVELOPMENT TOTAL',W-M,142,10,color=GREY)
right('R87,000.00',W-M,111,26,True)
para('Includes any applicable VAT. No VAT will be added above the quoted development total. VAT registration and breakdown to be confirmed on invoicing.',M,86,CW,small)
y=55
end(1)

pagehead(2,'Included scope','Phase 1 | Build, launch and commercial functionality')
section('01  Discovery, design and existing work','Review the supplied code, database and deployment setup; identify reusable work; prepare the agreed functional specification, wireframes, user journeys and data model. Includes two consolidated design feedback rounds before build approval.')
section('02  Assessment engine','195-question diagnostic across 13 areas, using the approved 0-10 scale; separate 28-question Snapshot with independent scoring; individual area diagnostics. Section progress, autosave, stop/resume, unanswered-question checks and submission. UG can edit the question bank without recoding; published versions preserve historical assessments.')
section('03  Scoring, results and reports','Deterministic area averages, approved overall weighting, performance bands, rankings and priority rules. Dashboard includes the 13-area chart, overall and individual circular charts, strongest/weakest areas and report access. Repeated assessments, assessment history and basic period-to-period score comparison. Server-generated branded PDFs use one UG-approved report template and approved interpretation content.')
section('04  Accounts, company teams and administration','Registration, login and password recovery; client, UG administrator and assigned-consultant roles; server-side company data separation. Team invitations, individual assessments and a basic consolidated company score view using UG-approved aggregation. Admin tools for clients, completion status, questions, scoring configuration, reports, package access and CSV data exports.')
section('05  Commercial functionality and website integration','Connect one existing UG website/shop to the assessment platform and integrate one payment gateway using its supported checkout and recurring-payment capabilities. Assessment products, team packages, access codes, coupons, payment confirmations/receipts and subscription renewals. Payment status controls assessment access. Includes standard success, failure and cancellation flows; custom payment processing is outside scope.')
section('06  Quality, release and handover','Staging and production environments; automated scoring and access-control tests; browser and payment-flow checks; audit records for submissions, versions and key admin changes. Monitoring setup, automated backups and a demonstrated restore. Source repository, schema/export, deployment and operating guides, plus one remote administrator training session of up to two hours.')
end(2)

pagehead(3,'Delivery and milestone payments','Target: 10 weeks from kickoff, subject to timely access, content and approvals.')
rows=[['<b>Target</b>','<b>Accepted deliverable</b>','<b>%</b>','<b>Amount</b>'],['Weeks 1-2','Existing-code review; approved specification, design and architecture.','15%','R13,050.00'],['Weeks 3-4','Working accounts, company access and questionnaire save/resume.','25%','R21,750.00'],['Weeks 5-6','Approved scoring; dashboards and matching branded PDF reports.','30%','R26,100.00'],['Weeks 7-9','Commercial/team features; acceptance testing and production deployment.','20%','R17,400.00'],['Week 10','Documentation, training, code/data handover and final acceptance.','10%','R8,700.00'],['','<b>Total</b>','<b>100%</b>','<b>R87,000.00</b>']]
table(rows,[65,CW-193,38,90],font=9,pad=7)
section('Demonstrations and payment','Working demonstrations accompany each milestone. Milestone invoices are raised after written acceptance and are payable within seven calendar days. The final 10% is conditional on final acceptance and complete handover. Calendar dates are agreed at kickoff; client or third-party delays shift the schedule.')
section('Acceptance checks','Use at least three UG-controlled test companies with strong, weak and mixed results. Verify full diagnostic and Snapshot completion, autosave/resume, mathematically correct approved scores, matching dashboard/PDF figures and unchanged historical results after question or scoring updates. Verify company/team permissions, cross-company URL/API access protection, exports, payment/access/renewal flows, backup restoration and agreed desktop/mobile browser behaviour.')
section('Technical approach and portability','Reuse suitable existing components following review. If a new module is required, the proposed baseline is a React interface, Node.js server and PostgreSQL database, with server-generated reports and documented WordPress/shop integration. Separate assessment, scoring, reporting and account modules. UG receives repository access throughout development and deployment instructions suitable for an independent developer.')
section('Security and privacy implementation','HTTPS, secure authentication, role-based permissions, protected secrets and encrypted storage where supported by the selected hosting setup. Versioned assessment/scoring/report records and audit trails. Implement UG-approved consent/privacy text, retention and deletion rules, and a documented incident-response contact process. UG supplies or arranges review of final legal wording.')
end(3)

pagehead(4,'Commercial terms and boundaries','Proposed project terms | Final development total: R87,000.00')
section('Fixed price and existing-code dependency','R87,000 is the final development total for the scope stated in this quotation, including any applicable VAT. It assumes usable source code, deployment access and rights to the existing work are supplied. The review occurs before specification approval. Any material code defects, missing integrations or requested scope changes must be identified and resolved in writing before affected work proceeds; additional fees require written approval.')
section('Client inputs and review','UG supplies the full question bank, Snapshot content, approved scoring examples, weights, bands, interpretation rules, report template, brand assets, product pricing and company aggregation rules. UG also provides website/shop, hosting and gateway access, merchant approvals, test-company users and one decision-maker. Allow up to three business days for consolidated reviews; delayed inputs may extend delivery.')
section('External services and recurring costs','Hosting, domain renewals, database/storage, backups, transactional email, payment-provider transaction fees and any paid shop/subscription licences are separate operating costs paid directly by UG. Providers, licences, estimated running costs and portability restrictions must be documented for approval during discovery before a paid service is activated. Recurring service charges are excluded from the R87,000 development fee.')
section('Ownership, confidentiality and handover','UG retains its existing content, methodology and business/client data. Commissioned custom code, designs, configuration and documentation transfer to UG on final payment, subject to disclosed third-party licences and separately identified pre-existing components. Confidentiality obligations apply before proprietary access. UG content and client data may not be reused for other customers or shared with external AI providers without written authorisation. Handover includes controlled credential transfer, infrastructure configuration and data exports.')
section('Warranty and ongoing support','30 calendar days of defect correction after production acceptance for failures against the approved specification, at no additional development charge. Target acknowledgement: one business day for a production-blocking defect and two business days for other defects; resolution depends on severity. Enhancements, routine administration, third-party outages and ongoing maintenance are outside the warranty. Any continuing support plan is quoted separately.')
section('Exclusions and later phases','Phase 2 action planning, 90-day goals, task ownership and advanced progress workflows; Phase 3 AI narratives, benchmarking, portfolios and advanced consultant tools; native apps, a new marketing website/shop, CRM integrations, complex legacy-data migration, additional gateways, custom billing/tax engines, formal legal advice and independent penetration testing are excluded. Later phases require a separate scope, estimate and approval.')
y-=2
c.setStrokeColor(LINE);c.line(M,y,W-M,y);y-=21
txt('ACCEPTANCE',M,y,9,True);y-=20
txt('For UG: __________________________',M,y,9)
txt('Date: __________________',335,y,9);y-=24
txt('For Mr Caiphus: ___________________',M,y,9)
txt('Date: __________________',335,y,9);y-=12
end(4)
c.save()
r=PdfReader(str(OUT));assert len(r.pages)==4
all_text='\n'.join(p.extract_text() for p in r.pages)
assert 'Navario' not in all_text and 'NAVARIO' not in all_text
assert 'R87,000.00' in all_text and 'Mr Caiphus' in all_text
print(OUT)
print('4 pages; item total R87,000; milestone total R87,000; supplier verified.')
