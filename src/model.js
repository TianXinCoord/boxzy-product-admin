const clone=x=>JSON.parse(JSON.stringify(x));
const categories=['Common','Uncommon','Rare','Epic','Legendary','Grail'];
const probabilities=[...DEMO_BOX_DATA[1].q];
function seedDB(){return DEMO_BOX_DATA.map((sample,i)=>{
 const items=sample.items.map(({exampleProbability,imageIndex,sourceSheet,sourceRow,sourceType,...s})=>({...s,image:ASSETS[imageIndex]}));
 const c={name:'$'+sample.price+' Box',price:sample.price,minValue:[1,5,20,40][i],maxValue:[120,800,3000,8000][i],image:ASSETS[i%ASSETS.length],q:[...sample.q],items};
 return{inventory:Object.fromEntries(items.map(x=>[x.id,{stock:x.stock,drawn:x.drawn}])),id:sample.id,live:i<2,published:clone(c),draft:i===1?clone(c):null};
});}
const numberPresent=x=>x!==''&&x!==null&&x!==undefined&&Number.isFinite(Number(x));
function calculationIssues(c){
 const errors=[];
 if(!numberPresent(c.price)||Number(c.price)<=0)errors.push('Open price must be a finite number greater than zero.');
 if(c.q.length!==6||c.q.some(q=>!numberPresent(q)||q<0||q>100)||Math.abs(c.q.reduce((a,b)=>a+Number(b),0)-100)>1e-8)errors.push('Enter all six rarity probabilities with a total of 100%.');
 c.items.forEach(s=>{const id=s.id||s.name||'New SKU';
  if(!Number.isInteger(s.category)||s.category<0||s.category>=6)errors.push(id+': select a valid category.');
  if(!numberPresent(s.market)||s.market<=0||!numberPresent(s.cost)||s.cost<0)errors.push(id+': enter a market price above zero and a purchase cost of zero or more.');
  if(!numberPresent(s.weight)||s.weight<=0)errors.push(id+': weight must be greater than zero.');
  if(!numberPresent(s.stock)||!Number.isSafeInteger(Number(s.stock))||s.stock<0)errors.push(id+': stock must be a non-negative whole number.');
 });return errors;
}
function economics(c){
 const issues=calculationIssues(c),weights=categories.map((_,r)=>c.items.filter(x=>x.category===r&&x.stock>0&&numberPresent(x.weight)&&x.weight>0).reduce((s,x)=>s+Number(x.weight),0));
 c.q.forEach((q,r)=>{if(q>0&&weights[r]===0)issues.push(categories[r]+': no in-stock SKU with a valid weight.');});
 if(weights.some(w=>!Number.isFinite(w)))issues.push('Category weight total is too large.');
 const valid=issues.length===0;
 const rows=c.items.map(x=>{const p=valid?(x.stock>0&&weights[x.category]>0?Number(c.q[x.category])/100*Number(x.weight)/weights[x.category]:0):null;return{...x,p,contribution:p===null?null:Number(x.cost)*p,ratio:numberPresent(x.market)&&x.market>0&&numberPresent(x.cost)&&x.cost>=0?Number(x.cost)/Number(x.market):null};});
 const cost=valid?rows.reduce((s,x)=>s+x.contribution,0):null;
 return{valid,issues,rows,cost,profit:cost===null?null:Number(c.price)-cost,weights};
}
function boxMediaErrors(c){
 const errors=[];
 for(const [key,label,required] of [['imageUrl','Box image URL',true],['webOpeningVideoUrl','Web opening video URL',false],['appOpeningVideoUrl','App opening video URL',false]]){
  const value=String(c[key]??'').trim();
  if(!value){if(required&&!(c.image&&c.imageUrl===undefined))errors.push('Enter a Box image URL.');continue}
  try{const url=new URL(value);if(url.protocol!=='https:'||!url.hostname)throw Error();}catch{errors.push(label+' must be a valid HTTPS URL.')}
 }
 return errors;
}
function boxValueErrors(c){
 const errors=[];
 for(const [key,label] of [['minValue','Min Value'],['maxValue','Max Value']]){
  const raw=String(c[key]??'').trim();
  if(!/^\d+(?:\.\d{1,2})?$/.test(raw)||!Number.isSafeInteger(Math.round(Number(raw)*100))||Number(raw)>90071992547409)errors.push(label+' is required. Enter a non-negative USD amount with up to 2 decimal places.');
 }
 if(!errors.length&&Number(c.minValue)>Number(c.maxValue))errors.push('Min Value must be less than or equal to Max Value.');
 return errors;
}
function stockAlertErrors(s){
 if(s.stockAlertEnabled!==true)return [];
 const raw=String(s.stockAlertThreshold??'').trim();
 return /^\d+$/.test(raw)&&Number.isSafeInteger(Number(raw))?[]:['Enter a whole number of 0 or more for the stock alert threshold.'];
}
function isStockAlert(s){return s.stockAlertEnabled===true&&!stockAlertErrors(s).length&&Number(s.stock)<=Number(s.stockAlertThreshold)}
function validateConfig(c,publish=false){const errors=publish?[...economics(c).issues]:calculationIssues(c);if(!c.name.trim())errors.unshift('Enter a Box name.');errors.push(...boxValueErrors(c),...boxMediaErrors(c));c.items.forEach(s=>{errors.push(...stockAlertErrors(s).map(e=>(s.id||s.name||'New SKU')+': '+e));if(!s.name.trim()||!s.image)errors.push('Complete the name and image for SKU '+(s.id||s.name||'New SKU')+'.');});return [...new Set(errors)];}
const fingerprint=c=>JSON.stringify({price:c.price,q:c.q,items:c.items.map(x=>[x.id,x.category,x.cost,x.weight,Number(x.stock)])});
function simulate(c,n=100000,random=Math.random){
 if(!Number.isSafeInteger(n)||n<1)throw Error('Simulation draw limit must be a positive integer.');
 const issues=calculationIssues(c);if(issues.length)throw Error(issues.join(' '));
 const snapshot=clone(c),counts=Array(c.items.length).fill(0),depleted=[];
 let e=economics(snapshot),initial=e,totalCost=0,expectedTotal=0,completed=0,distribution=[];
 const rebuild=()=>{let sum=0;distribution=e.rows.flatMap((x,i)=>x.p>0?[{i,end:sum+=x.p}]:[])};
 const stopReason=()=>!e.valid?'category-empty':e.profit<=0?'non-positive-profit':null;
 let reason=stopReason();if(!reason)rebuild();
 while(completed<n&&!reason){
  const u=random();if(!Number.isFinite(u)||u<0||u>=1)throw Error('Invalid random sample.');
  const selected=distribution.find(x=>u<x.end)||distribution[distribution.length-1];
  const item=snapshot.items[selected.i];
  expectedTotal+=e.cost;totalCost+=Number(item.cost);counts[selected.i]++;item.stock=Number(item.stock)-1;completed++;
  if(item.stock===0){
   depleted.push({id:item.id||item.tempId||'',name:item.name,category:item.category,draw:completed});
   e=economics(snapshot);reason=stopReason();if(!reason)rebuild();
  }
 }
 const totalRevenue=completed*Number(c.price),totalProfit=totalRevenue-totalCost;
 return{mode:'dynamic-stock',n:completed,requested:n,price:Number(c.price),totalCost,totalRevenue,totalProfit,
  average:completed?totalCost/completed:null,profit:completed?totalProfit/completed:null,
  expected:initial.cost,initialProfit:initial.profit,expectedAverage:completed?expectedTotal/completed:null,
  difference:completed?(totalCost-expectedTotal)/completed:null,
  finalCost:e.cost,finalProfit:e.profit,finalMargin:e.profit===null?null:e.profit/Number(c.price),
  stopReason:reason||'draw-limit',issues:e.issues,emptyCategories:categories.filter((_,i)=>Number(c.q[i])>0&&e.weights[i]===0),
  depleted,remainingStocks:snapshot.items.map(x=>Number(x.stock)),counts,fingerprint:fingerprint(c)};
}
