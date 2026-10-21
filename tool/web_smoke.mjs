import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { readFile, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve, extname } from 'node:path';
const root = resolve(process.argv[2] || 'build/web');
const mime = {'.html':'text/html','.js':'application/javascript','.json':'application/json','.wasm':'application/wasm','.svg':'image/svg+xml','.css':'text/css'};
const server=createServer(async(req,res)=>{
  const path=resolve(root,'.'+new URL(req.url,'http://localhost').pathname);
  if(!path.startsWith(root+'/') && path!==root){res.writeHead(403).end();return;}
  try {const f=path===root||path.endsWith('/')?join(path,'index.html'):path;res.setHeader('Content-Type',mime[extname(f)]??'application/octet-stream');res.end(await readFile(f));}
  catch {res.writeHead(404).end();}
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const profile=await mkdtemp(join(tmpdir(),'liferpg-web-'));
const chrome=process.env.CHROME_BIN || ['/usr/bin/chromium','/usr/bin/google-chrome','/usr/bin/google-chrome-stable'].find(existsSync);
if(!chrome)throw Error('Set CHROME_BIN to a Chromium executable.');
const child=spawn(chrome,['--headless=new','--disable-gpu','--disable-dev-shm-usage','--no-sandbox','--no-first-run','--remote-debugging-port=0','--user-data-dir='+profile,'about:blank'],{stdio:'ignore'});
const delay=ms=>new Promise(r=>setTimeout(r,ms));
let socket;
try {
  let port;
  for(let i=0;i<100;i++){try{port=(await readFile(join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0];break;}catch{await delay(100);}}
  if(!port)throw Error('Chrome did not start');
  const pages=await(await fetch('http://127.0.0.1:'+port+'/json',{signal:AbortSignal.timeout(10000)})).json();
  socket=new WebSocket(pages.find(p=>p.type==='page').webSocketDebuggerUrl);
  await new Promise((r,j)=>{socket.addEventListener('open',r,{once:true});socket.addEventListener('error',j,{once:true});});
  let id=0;const pending=new Map();const events=[];
  socket.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.id){const job=pending.get(m.id);if(job){clearTimeout(job.timer);if(m.error)job.reject(Error(JSON.stringify(m.error)));else job.resolve(m.result);}pending.delete(m.id);}else if(['Runtime.exceptionThrown','Runtime.consoleAPICalled','Log.entryAdded'].includes(m.method))events.push(m);});
  const call=(method,params={})=>new Promise((resolve,reject)=>{const n=++id;const timer=setTimeout(()=>{pending.delete(n);reject(Error('CDP timed out: '+method));},15000);pending.set(n,{resolve,reject,timer});socket.send(JSON.stringify({id:n,method,params}));});
  await call('Runtime.enable');await call('Log.enable');await call('Page.enable');
  await call('Page.navigate',{url:'http://127.0.0.1:'+server.address().port+'/'});
  await delay(15000);
  for(const e of events){
    if(e.method==='Runtime.consoleAPICalled')console.log('CONSOLE',e.params.type,e.params.args.map(a=>a.value??a.description??'').join(' '));
    else if(e.method==='Runtime.exceptionThrown')console.log('EXCEPTION',e.params.exceptionDetails.exception?.description??e.params.exceptionDetails.text);
    else if(e.params.entry.level==='error')console.log('LOG_ERROR',e.params.entry.text);
  }
  const view=await call('Runtime.evaluate',{expression:"Boolean(document.querySelector('flutter-view,flt-glass-pane'))",returnByValue:true});
  await call('Runtime.evaluate',{expression:"document.querySelector('flt-semantics-placeholder')?.click()"});
  await delay(1000);
  const semantics=await call('Runtime.evaluate',{expression:"document.body.innerText + ' ' + Array.from(document.querySelectorAll('[aria-label]')).map(e=>e.getAttribute('aria-label')).join(' ')",returnByValue:true});
  const text=semantics.result?.value??'';
  if(!text.includes('Search missions') || !/Player\s+Adventurer/.test(text) || !text.includes('No missions found'))throw Error('Initial mission screen is not usable: '+text.slice(0,1000));
  const shot=await call('Page.captureScreenshot',{format:'png'});
  await writeFile('build/web-smoke.png',Buffer.from(shot.data,'base64'));
  const errors=events.filter(e=>e.method==='Runtime.exceptionThrown'||e.method==='Runtime.consoleAPICalled'&&e.params.type==='error'||e.method==='Log.entryAdded'&&e.params.entry.level==='error');
  if(errors.length || !view.result?.value)throw Error('Web startup failed: '+errors.length+' browser errors; Flutter view='+view.result?.value);
  console.log('Web startup passed: mission screen and default player are accessible, without browser errors.');
} finally {
  socket?.close();child.kill('SIGTERM');server.closeAllConnections();server.close();
  await delay(1000);await rm(profile,{recursive:true,force:true});
}
