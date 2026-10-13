// Profit decision support. These values describe purchase cost, not net profit.
function lossNotice(c){const e=economics(c);return e.profit!==null&&e.profit<0?`<div class="loss-notice" role="alert"><strong>Expected loss: ${money(-e.profit)} per draw</strong><p>Open price ${money(c.price)} is below expected purchase cost ${money(e.cost)}. You can continue, or return to adjust the configuration.</p></div>`:''}
function poolIssues(e){return e.issues.length?`<div class="notice mt-3" role="alert"><strong>Calculation unavailable</strong><ul class="list-disc pl-5 mt-2">${e.issues.slice(0,4).map(x=>`<li>${esc(x)}</li>`).join('')}</ul>${e.issues.length>4?`<p>And ${e.issues.length-4} more input issues. Correct the fields before publishing.</p>`:''}</div>`:''}
function updatePoolEconomics(){
 const e=economics(work);
 if(!$('#cost-metric'))return;
 $('#cost-metric').textContent=money(e.cost);$('#profit-metric').textContent=money(e.profit);
 $('#profit-metric').parentElement.classList.toggle('is-loss',e.profit!==null&&e.profit<0);
 $('#profit-loss-label').hidden=!(e.profit!==null&&e.profit<0);
 const fresh=simulation?.fingerprint===fingerprint(work);
 $('#sim-status').textContent=simulation?(fresh?'Simulation complete':'Simulation outdated'):'Simulation not run';
 $('#sim-status').className='text-xs '+(simulation&&!fresh?'text-amber-700':'muted');
 $('#run-simulation').disabled=busy||readonly||!e.valid;
 $('#pool-issues').innerHTML=poolIssues(e);
 const indexed=new Map(e.rows.map(s=>[s.id||s.tempId,s]));
 $$('[data-prob]').forEach(el=>el.textContent=pct(indexed.get(el.dataset.prob)?.p??null));
 $$('[data-cost]').forEach(el=>el.textContent=money(indexed.get(el.dataset.cost)?.contribution??null,4));
 $$('.weight').forEach(el=>{const s=indexed.get(el.dataset.sku);const bad=!numberPresent(s.weight)||s.weight<=0;el.setAttribute('aria-invalid',String(bad));el.title=bad?'Enter a weight greater than zero.':'';});
 renderFooter();
}
function costBreakdown(){
 const c=currentConfig(),e=economics(c);
 if(!e.valid){showDialog('Cost breakdown',poolIssues(e),btn('Close','closeDialog()','primary'));return;}
 const rows=categories.map((name,r)=>({name,r,q:c.q[r],cost:e.rows.filter(x=>x.category===r).reduce((a,x)=>a+x.contribution,0)}));
 const drivers=[...e.rows].filter(s=>s.contribution>0).sort((a,b)=>b.contribution-a.contribution).slice(0,3);
 showDialog('Cost breakdown',`<p class="muted mb-4">Entire Box · ${'Current edits'} · All categories</p><table class="cost-breakdown"><thead><tr><th class="text-left">Category</th><th>Category probability</th><th>Cost / draw</th><th>Share of cost</th></tr></thead><tbody>${rows.map(r=>`<tr><td>${link(r.name,`closeDialog();page='pool';changeCategory(${r.r});sortRows('contribution');sortDir=-1;render()` )}</td><td>${r.q}%</td><td>${money(r.cost,4)}</td><td>${e.cost>0?pct(r.cost/e.cost):'—'}</td></tr>`).join('')}<tr><td><strong>Total</strong></td><td>100%</td><td><strong>${money(e.cost,4)}</strong></td><td>${e.cost>0?'100%':'—'}</td></tr></tbody></table><h3 class="mt-5 mb-2">Top 3 cost contributors</h3><p class="muted text-xs mb-2">Start here to review the largest current costs, not the biggest cost increases. A low-price SKU drawn often can contribute more.</p><ul class="cost-drivers">${drivers.map(s=>`<li><span>${esc(s.name)}<small class="block muted">${categories[s.category]} · SKU ${esc(s.id||'Not saved')}</small><small class="block muted">Purchase cost ${money(s.cost)} × draw probability ${pct(s.p)}</small></span><strong>${money(s.contribution,4)} / draw</strong></li>`).join('')||'<li>No positive cost contributions in this configuration.</li>'}</ul><p class="muted text-xs mt-4">Higher contribution means more of the expected cost, not a worse prize. Open a category to review all SKUs. Recheck the whole Box after weight or stock changes.</p><p class="muted text-xs mt-2">Gross profit = open price − expected purchase cost. Shipping, payment fees, discounts and refunds are not included. This is not net profit.</p>`,btn('Close','closeDialog()','primary'));
}
function stockImpact(v){
 const s=getSKU(stockEditingId);if(!v.valid||!s?.id||(stockStartingValue>0)===(v.n>0))return '';
 // Live impact must use the published configuration, never unsaved weights.
 const live=box.live&&box.published?.items.some(x=>x.id===s.id);
 const before=clone(live?box.published:work);
 before.items.forEach(x=>{if(box.inventory?.[x.id])x.stock=box.inventory[x.id].stock;});
 before.items.find(x=>x.id===s.id).stock=stockStartingValue;
 const after=clone(before);after.items.find(x=>x.id===s.id).stock=v.n;
 const a=economics(before),b=economics(after);
 return `<div class="stock-impact"><strong>${live?'Live Box impact · applies immediately':'Current configuration impact'}</strong>${b.valid?`<p class="mt-2">Expected gross profit / draw: ${money(a.profit)} → <strong class="${b.profit<0?'loss-text':''}">${money(b.profit)}</strong></p>${b.profit<0?'<p class="loss-text">Expected purchase cost exceeds the open price.</p>':''}`:`<p class="loss-text mt-2">${esc(b.issues[0])}</p><p>Replenish this category${live?' or take the Box offline':''}. Draw probabilities cannot cover the full Box configuration.</p>`}<p class="muted text-xs mt-2">${live?'Draft weights are not used in this preview. ':''}Crossing zero recalculates probabilities within this category.</p></div>`;
}
