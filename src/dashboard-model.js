/* Read-only, deterministic demonstration ledger. Independent of pool configuration.
   One row per purchased Box unit; money is integer USD cents. */
const DashboardModel = (() => {
  const DAY = 86400000;
  const snapshotDay = '2026-10-12';
  const firstDay = '2026-09-01';
  const boxes = [5,20,50,100].map((price,i)=>({id:`BX00${i+1}`,name:`$${price} Box`,priceCents:price*100}));
  const stamp = day => Date.parse(day+'T00:00:00Z');
  const iso = value => new Date(value).toISOString().slice(0,10);
  const shift = (day,n) => iso(stamp(day)+n*DAY);
  const days = (start,end) => Array.from({length:Math.round((stamp(end)-stamp(start))/DAY)+1},(_,i)=>shift(start,i));
  const validDay = day => /^\d{4}-\d{2}-\d{2}$/.test(day)&&Number.isFinite(stamp(day))&&iso(stamp(day))===day;
  function range(preset) {
    const end=snapshotDay;
    return {start:preset==='today'?end:preset==='yesterday'?shift(end,-1):preset==='last7'?shift(end,-6):preset==='last30'?shift(end,-29):preset==='month'?end.slice(0,7)+'-01':firstDay,end:preset==='yesterday'?shift(end,-1):end};
  }
  function validate(filter) {
    if(!validDay(filter.start)||!validDay(filter.end))return 'Choose a valid start and end date.';
    if(filter.start>filter.end)return 'Start date must be on or before end date.';
    if(filter.end>snapshotDay)return 'Choose a date on or before Oct 12, 2026 (demo snapshot).';
    if((stamp(filter.end)-stamp(filter.start))/DAY>=366)return 'Choose a date range of 366 days or less.';
    if(filter.boxId!=='all'&&!boxes.some(b=>b.id===filter.boxId))return 'Choose a valid Box type.';
    return '';
  }
  function split(total,count,index) { return Math.floor(total/count)+(index<total%count?1:0); }
  function generate() {
    const records=[];
    const currentSold=[1040,760,460,220],priorSold=[900,680,402,218];
    const pending=[280,202,128,62],unopened=[108,72,44,20],shipping=[176,138,82,42];
    const buybackCost=[150000,400000,700000,642000];
    const recycledMarket=[392000,984000,1326000,1140000],shippingCost=[145000,412000,598000,530000],pendingMarket=[226000,542000,816000,852000];
    const weights=[.113,.125,.137,.145,.133,.161,.186];
    boxes.forEach((box,b)=>{
      let serial=0;
      const create=(date)=>{
        const paidAt=stamp(date)+9*3600000,market=box.priceCents+125;
        const r={unitId:`${box.id}-U${++serial}`,boxId:box.id,paidAt,paidCents:box.priceCents,openedAt:paidAt+3600000,recycledAt:null,recycledMarketCents:null,buybackCostCents:null,shippingRequestedAt:null,shippingCostCents:null,marketHistory:[{at:paidAt,cents:market}]};
        records.push(r);return r;
      };
      days(firstDay,'2026-09-28').forEach((day,d)=>{
        const count=12+(d*7+b*9)%30;
        for(let i=0;i<count;i++) {const r=create(day);if(i%2){r.recycledAt=r.openedAt+3600000;r.recycledMarketCents=r.marketHistory[0].cents;r.buybackCostCents=Math.round(box.priceCents*.6);}else{r.shippingRequestedAt=r.openedAt+3600000;r.shippingCostCents=Math.round(box.priceCents*.85);}}
      });
      [priorSold[b],currentSold[b]].forEach((count,period)=>{
        const weekStart=period?'2026-10-06':'2026-09-29',unitDays=[];
        let used=0;
        weights.forEach((w,d)=>{const n=d===6?count-used:Math.floor(count*w);used+=n;for(let i=0;i<n;i++)unitDays.push(shift(weekStart,d));});
        // Permute assignments so each day's events include all outcomes.
        const ranked=unitDays.map((day,i)=>({day,key:((i*2654435761)>>>0)})).sort((a,c)=>a.key-c.key);
        for(let i=0;i<count;i++) {
          const r=create(ranked[i].day);
          if(!period){if(i%2){r.recycledAt=r.openedAt+3600000;r.recycledMarketCents=r.marketHistory[0].cents;r.buybackCostCents=Math.round(box.priceCents*.6);}else{r.shippingRequestedAt=r.openedAt+3600000;r.shippingCostCents=Math.round(box.priceCents*.8);}continue;}
          if(i<unopened[b])r.openedAt=null;
          else if(i<unopened[b]+pending[b])r.marketHistory=[{at:r.openedAt,cents:split(pendingMarket[b],pending[b],i-unopened[b])}];
          else if(i<unopened[b]+pending[b]+shipping[b]){r.shippingRequestedAt=r.openedAt+3600000;r.shippingCostCents=split(shippingCost[b],shipping[b],i-unopened[b]-pending[b]);}
          else {const n=count-unopened[b]-pending[b]-shipping[b];r.recycledAt=r.openedAt+3600000;r.recycledMarketCents=split(recycledMarket[b],n,i-unopened[b]-pending[b]-shipping[b]);r.buybackCostCents=split(buybackCost[b],n,i-unopened[b]-pending[b]-shipping[b]);}
        }
      });
    });
    return records;
  }
  const records=generate();
  const keys=['sold','revenue','recycled','recycledValue','shipping','shippingValue','pending','pendingValue','unopened','realizedRevenue','buybackCost','totalRealizedCost','realizedProfit','pendingRevenue','unopenedRevenue','unrealizedRevenue','unrealizedBoxes'];
  const amountKeys=['revenue','recycledValue','shippingValue','pendingValue','realizedRevenue','buybackCost','totalRealizedCost','realizedProfit','pendingRevenue','unopenedRevenue','unrealizedRevenue'];
  function empty(id) {return {boxId:id,...Object.fromEntries(keys.map(k=>[k,0])),missing:Object.fromEntries(amountKeys.map(k=>[k,0]))};}
  function aggregate(filter,source=records) {
    const error=validate(filter);if(error)throw new Error(error);
    const start=stamp(filter.start),end=stamp(filter.end)+DAY;
    const selected=boxes.filter(b=>filter.boxId==='all'||b.id===filter.boxId);
    const rows=selected.map(b=>({...empty(b.id),name:b.name}));
    const rowById=new Map(rows.map(r=>[r.boxId,r]));
    const within=t=>Number.isFinite(t)&&t>=start&&t<end;
    const before=t=>Number.isFinite(t)&&t<end;
    const seen=new Set();
    function value(row,key,cents){if(Number.isSafeInteger(cents)&&cents>=0)row[key]+=cents;else row.missing[key]++;}
    for(const r of source){
      const row=rowById.get(r.boxId);
      if(!row||seen.has(r.unitId))continue;
      seen.add(r.unitId);
      if(within(r.paidAt)){row.sold++;value(row,'revenue',r.paidCents);}
      // The first successful outcome resolves a unit once. Failed clicks are not ledger events.
      const recycled=Number.isFinite(r.recycledAt)&&(!Number.isFinite(r.shippingRequestedAt)||r.recycledAt<=r.shippingRequestedAt);
      const resolvedAt=recycled?r.recycledAt:r.shippingRequestedAt;
      if(within(resolvedAt)){
        value(row,'realizedRevenue',r.paidCents);
        if(recycled){row.recycled++;value(row,'recycledValue',r.recycledMarketCents);value(row,'buybackCost',r.buybackCostCents);}
        else{row.shipping++;value(row,'shippingValue',r.shippingCostCents);}
      }
      if(before(r.paidAt)&&!before(r.openedAt)&&!before(resolvedAt)){row.unopened++;value(row,'unopenedRevenue',r.paidCents);}
      if(before(r.openedAt)&&!before(r.recycledAt)&&!before(r.shippingRequestedAt)){
        row.pending++;value(row,'pendingRevenue',r.paidCents);
        const price=(r.marketHistory||[]).filter(x=>before(x.at)).sort((a,b)=>b.at-a.at)[0];
        value(row,'pendingValue',price?.cents);
      }
    }
    rows.forEach(r=>{r.unrealizedBoxes=r.pending+r.unopened;r.unrealizedRevenue=r.pendingRevenue+r.unopenedRevenue;r.missing.unrealizedRevenue=r.missing.pendingRevenue+r.missing.unopenedRevenue;r.totalRealizedCost=r.buybackCost+r.shippingValue;r.realizedProfit=r.realizedRevenue-r.totalRealizedCost;r.missing.totalRealizedCost=r.missing.buybackCost+r.missing.shippingValue;r.missing.realizedProfit=r.missing.realizedRevenue+r.missing.totalRealizedCost;});
    const total=empty('all');rows.forEach(r=>{keys.forEach(k=>total[k]+=r[k]);Object.keys(total.missing).forEach(k=>total.missing[k]+=r.missing[k]);});
    return {rows,total};
  }
  return {DAY,snapshotDay,firstDay,boxes,records,stamp,iso,shift,days,range,validate,aggregate,keys};
})();
if(typeof module!=='undefined')module.exports=DashboardModel;
