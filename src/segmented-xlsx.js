const sectionHeaders=['SKU ID','Image URL','Product name *','Market price *\nUSD','Purchase cost *\nUSD','Purchase / Market\nCalculated','Available stock\nNew SKU only','Total drawn\nSystem','Weight *','Draw probability\nSystem','Cost contribution\nUSD / draw · System'];
const cleanHeader=x=>typeof x==='string'?x.replace(/\s+/g,' ').trim().toLowerCase():'';
const blankCell=x=>x===undefined||x===null||x==='';
function formulaRatio(r){return `IF(OR(ISBLANK(D${r}),ISBLANK(E${r})),"",IF(OR(NOT(ISNUMBER(D${r})),NOT(ISNUMBER(E${r}))),"Check prices",IF(OR(D${r}<=0,E${r}<0),"Check prices",E${r}/D${r})))`}

// Reuse the approved workbook's styles, dimensions, fonts and column layout.
async function segmentedWorkbook(c,template=false,boxId=box.id){
 const bytes=Uint8Array.from(atob(PRIZE_TEMPLATE),c=>c.charCodeAt(0));
 const files=await unzipFile(new File([bytes],'template.xlsx'));
 const doc=parseXml(files['xl/worksheets/sheet1.xml']),ns=doc.documentElement.namespaceURI;
 const el=name=>doc.createElementNS(ns,name);
 const originals=new Map([...doc.querySelectorAll('sheetData row')].map(r=>[+r.getAttribute('r'),r]));
 const data=doc.querySelector('sheetData');data.replaceChildren();
 const e=economics(c),sections=[];let next=11;
 function copyRow(old,r){const row=originals.get(old).cloneNode(true);row.setAttribute('r',r);row.querySelectorAll('c').forEach(cell=>cell.setAttribute('r',cell.getAttribute('r').replace(/\d+$/,r)));data.append(row);return row;}
 function value(row,col,v,formula=null){
  const ref=String.fromCharCode(65+col)+row.getAttribute('r');let cell=[...row.querySelectorAll('c')].find(c=>c.getAttribute('r')===ref);
  if(!cell){cell=el('c');cell.setAttribute('r',ref);const after=[...row.children].find(c=>c.getAttribute('r').replace(/\d+$/,'')>String.fromCharCode(65+col));row.insertBefore(cell,after||null);}
  cell.replaceChildren();cell.removeAttribute('t');
  if(formula){cell.append(el('f'));cell.firstChild.textContent=formula;}
  if(blankCell(v))return;
  if(typeof v==='number'&&Number.isFinite(v)){const n=el('v');n.textContent=v;cell.append(n);}
  else{cell.setAttribute('t','inlineStr');const text=el('is'),t=el('t');t.textContent=String(v);text.append(t);cell.append(text);}
 }
 for(let r=1;r<=10;r++)if(originals.has(r)){const row=copyRow(r,r);if(r===4){value(row,0,'Box ID: '+boxId);value(row,2,'Box name: '+c.name);value(row,6,'Open price: '+money(c.price));}}
 categories.forEach((cat,i)=>{
  const old=11+i*10,items=template?[]:e.rows.filter(x=>x.category===i),count=Math.max(5,items.length),start=next;
  sections.push({old,start,count});
  const band=copyRow(old,next++);value(band,6,'Category probability: '+c.q[i]+'%');copyRow(old+1,next++);copyRow(old+2,next++);
  for(let j=0;j<count;j++){
   const row=copyRow(old+3,next++),s=items[j];
   const vals=s?[s.id,s.imageUrl||'local-image:'+(s.id||s.tempId),s.name,s.market,s.cost,s.ratio,s.stock,s.drawn,s.weight,s.p,s.contribution]:['','','','','','',10000,'','','',''];
   vals.forEach((v,col)=>value(row,col,v,col===5?formulaRatio(next-1):null));
  }
  copyRow(old+8,next++);if(originals.has(old+9))copyRow(old+9,next);next++;
 });
 function shiftRow(r){if(r<11)return r;const g=sections[Math.min(5,Math.floor((r-11)/10))];const local=r-g.old;return g.start+(local>=8?local+g.count-5:local);}
 const shiftRef=ref=>ref.replace(/([A-Z]+)(\d+)/g,(_,col,n)=>col+shiftRow(+n));
 doc.querySelectorAll('mergeCell').forEach(n=>n.setAttribute('ref',shiftRef(n.getAttribute('ref'))));
 // Expand each category's price/stock validations and ratio formatting to all exported rows.
 doc.querySelectorAll('dataValidation,conditionalFormatting').forEach(n=>{
  const ref=n.getAttribute('sqref'),m=ref.match(/([A-Z]+)(\d+):([A-Z]+)(\d+)/);if(!m)return;
  const section=sections.find(x=>+m[2]===x.old+3);if(!section)return;
  n.setAttribute('sqref',m[1]+(section.start+3)+':'+m[3]+(section.start+2+section.count));
 });
 const dim=doc.querySelector('dimension');if(dim)dim.setAttribute('ref','A1:K'+(next-1));
 files['xl/worksheets/sheet1.xml']=new XMLSerializer().serializeToString(doc);
 const wb=parseXml(files['xl/workbook.xml']),wns=wb.documentElement.namespaceURI;
 let names=wb.querySelector('definedNames');if(!names){names=wb.createElementNS(wns,'definedNames');const calc=wb.querySelector('calcPr');wb.documentElement.insertBefore(names,calc||null);}
 for(const [name,text]of [['_BOXZY_TEMPLATE_VERSION','2'],['_BOXZY_BOX_ID','"'+boxId+'"']]){let n=[...names.children].find(n=>n.getAttribute('name')===name);if(!n){n=wb.createElementNS(wns,'definedName');n.setAttribute('name',name);names.append(n)}n.textContent=text;}
 files['xl/workbook.xml']=new XMLSerializer().serializeToString(wb);
 return zipStore(files);
}

function normalizeImportRows(raw){
 const first=(raw[0]||[]).map(h=>h==='Units drawn'?'Total drawn':h);
 if(headers.every(h=>first.includes(h))){const rows=raw.slice(1);rows.unshift(first);return rows;}
 if(raw.templateVersion!==undefined&&raw.templateVersion!==2)throw Error('Unsupported template version. Download a new template.');
 if(raw.boxId&&raw.boxId!==box.id)throw Error('This workbook belongs to '+raw.boxId+'. Import it into that Box.');
 const result=[headers],seen=new Set();let categoryIndex=-1,map=null,closed=false;
 const metadata=raw.find(r=>r._row===4)?.[0];if(typeof metadata==='string'&&/^Box ID: BX\d+$/.test(metadata)&&metadata.slice(8)!==box.id)throw Error('This workbook belongs to '+metadata.slice(8)+'. Import it into that Box.');
 for(const row of raw){
  if(row._row<11)continue;
  const firstText=typeof row[0]==='string'?row[0].trim():'',cat=categories.findIndex(c=>c.toUpperCase()===firstText.toUpperCase());
  if(cat>=0){
   if(categoryIndex>=0&&!map)throw Error('Missing column headers for '+categories[categoryIndex]+'.');
   if(seen.has(cat))throw Error('Duplicate category section at row '+row._row+': '+categories[cat]+'.');
   seen.add(cat);categoryIndex=cat;map=null;closed=false;continue;
  }
  if(!row.some(x=>!blankCell(x)))continue;
  if(firstText==='Product'&&row[3]==='Pricing'&&row[6]==='Inventory & history'&&row[8]==='Probability & cost')continue;
  if(firstText==='Insert additional product rows above this line.'){closed=true;continue;}
  if(firstText==='SKU ID'){
   if(categoryIndex<0||map)throw Error('Unexpected column header at row '+row._row+'.');
   const normalized=row.map(cleanHeader);map=sectionHeaders.map(h=>normalized.indexOf(cleanHeader(h)));
   if(map.some(i=>i<0)||new Set(map).size!==11)throw Error('Column headers are missing or changed in '+categories[categoryIndex]+' at row '+row._row+'.');
   continue;
  }
  if(categoryIndex<0||!map||closed)throw Error('Unexpected content at row '+row._row+'. Keep the six category sections and place products above the insertion line.');
  const v=i=>row[map[i]]??'';
  // Reserved stock and calculated formulas alone do not create a new product.
  if([0,1,2,3,4,8].every(i=>blankCell(v(i)))&&(blankCell(v(6))||Number(v(6))===10000))continue;
  const item=[v(0),v(2),categories[categoryIndex],v(1),v(3),v(4),v(8),v(6),v(7),v(5),v(9),v(10)];item._row=row._row;result.push(item);
 }
 if(seen.size!==6||!map)throw Error('Keep all six category sections and their column headers, including empty categories.');
 return result;
}
