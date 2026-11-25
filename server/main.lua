local RES = GetCurrentResourceName()
local bells, pending, calls, viewers, busy = {}, {}, {}, {}, {}
local rings, motions, sirens, connecting = {}, {}, {}, {}
local previewRequests, previewCooldown, previewDownloads = {}, {}, {}
local PREVIEW_MAX = 96000
local function validPreview(v)
 return type(v)=='string' and #v<=PREVIEW_MAX and (v:match('^data:image/webp;base64,[A-Za-z0-9+/=]+$') or v:match('^data:image/jpeg;base64,[A-Za-z0-9+/=]+$'))
end
local function now() return os.time() end
local function autoInterval() return math.floor(math.max(5,math.min(10,tonumber(Config.AutoPreviewMinutes) or 5)))*60 end
local function save()
 local list = {}; for _, b in pairs(bells) do list[#list+1]=b end
 SaveResourceFile(RES,'data/doorbells.json',json.encode(list),-1)
end
local function load()
 local ok,list=pcall(json.decode,LoadResourceFile(RES,'data/doorbells.json') or '[]')
 if ok and type(list)=='table' then for _,b in ipairs(list) do if b.id then b.owner=tostring(b.owner); b.bucket=b.bucket or 0; bells[b.id]=b end end end
end
load()
local function char(src) return Bridge.identifier(src) end
local function access(src,b)
 local c=char(src); return c~=nil and b~=nil and (b.owner==c or (b.shared and b.shared[c]~=nil))
end
local function owner(src,b) return b and char(src)~=nil and b.owner==char(src) end
local function near(src,b,dist)
 local ped=GetPlayerPed(src)
 return ped~=0 and GetPlayerRoutingBucket(src)==b.bucket and #(GetEntityCoords(ped)-vector3(b.x,b.y,b.z))<=dist
end
local function public(b) return {id=b.id,x=b.x,y=b.y,z=b.z,h=b.h,finish=b.finish} end
local function push(src,event,data) pcall(function() exports.whip_phone:Push(src,'vista_home',event,data) end) end
local function notify(src,b,kind,who)
 pcall(function() exports.whip_phone:Notify(src,{app='vista_home',title=b.label,text=kind=='ring' and 'Someone is at your door' or kind=='motion' and 'Motion detected' or 'Doorbell shared with you',kind=kind=='ring' and 'command' or 'chat',args={id=b.id}}) end)
 push(src,'changed',{id=b.id,kind=kind})
end
local function online(b,fn)
 for _,s in ipairs(GetPlayers()) do local src=tonumber(s); if access(src,b) then fn(src) end end
end
local function fx(b,event)
 for _,s in ipairs(GetPlayers()) do local src=tonumber(s); if GetPlayerRoutingBucket(src)==b.bucket then TriggerClientEvent('whip_doorbell:'..event,src,b.id) end end
end
local function event(b,kind,who)
 b.history=b.history or {}; table.insert(b.history,1,{t=now(),kind=kind,who=who})
 while #b.history>Config.HistoryLimit do table.remove(b.history) end
 save()
end
local function active(src,b)
 local c=calls[b.id]; return c and c.host==src and c.hostChar==char(src)
end
local function endCall(id,why,skipClose)
 local c=calls[id]; if not c then return end
 calls[id]=nil
 if not skipClose then pcall(Whip.voice,'CloseLine',c.line) end
 push(c.host,'voice',{id=id,active=false,reason=why}); TriggerClientEvent('whip_doorbell:visitorVoice',c.visitor,id,false)
 if char(c.visitor)==c.visitorChar then Whip.core:NotifyPlayer(c.visitor,'Doorbell intercom ended','info') end
end
local function endView(src)
 if viewers[src] then local id=viewers[src].id; viewers[src]=nil; TriggerClientEvent('whip_doorbell:camera',src,false); push(src,'camera',{id=id}) end
end
local function cleanDevice(id)
 for token,r in pairs(previewRequests) do if r.id==id then previewRequests[token]=nil end end
 pending[id]=nil; endCall(id,'Device removed')
 for src,v in pairs(viewers) do if v.id==id then endView(src) end end
end
local function invalidate(b)
 online(b,function(p)
  push(p,'changed',{id=b.id})
 end)
end
local function safeLabel(v) if type(v)~='string' then return nil end; v=v:gsub('[%c<>~]',''):sub(1,24); return #v>0 and v or nil end
local function finite(v) return type(v)=='number' and v==v and math.abs(v)<100000 end
local H={}
H.world=function(src,a)
 local bucket=GetPlayerRoutingBucket(src); local owned={}; local list={}; for _,b in pairs(bells) do if b.bucket==bucket then if access(src,b) then owned[#owned+1]=b.id end; if a.bucket~=bucket then list[#list+1]=public(b) end end end
 return {bucket=bucket,list=a.bucket~=bucket and list or nil,owned=owned}
end
H.install=function(src,a)
 if not (finite(a.x) and finite(a.y) and finite(a.z) and finite(a.h)) then return false,'Invalid position' end
 local idf=char(src); if not idf then return false,'No character' end
 local b={x=a.x,y=a.y,z=a.z,h=a.h%360,bucket=GetPlayerRoutingBucket(src)}
 if not near(src,b,3.5) then return false,'Too far from wall' end
 local valid=false; for _,f in ipairs(Config.Finishes) do if f.id==a.finish then valid=true end end
 if not valid then return false,'Invalid finish' end
 local count=0; for _,other in pairs(bells) do
  if other.owner==idf then count=count+1 end
  if other.bucket==b.bucket and #(vector3(b.x,b.y,b.z)-vector3(other.x,other.y,other.z))<0.45 then return false,'Doorbell already installed here' end
 end
 if count>=Config.MaxPerPlayer then return false,'Device limit reached' end
 if not Bridge.removeItem(src) then return false,'You need a Vista Doorbell item' end
 repeat b.id=('VD-%08X'):format(math.random(0,0x7fffffff)) until not bells[b.id]
 b.owner=idf; b.ownerName=Bridge.name(src); b.label=safeLabel(a.label) or 'Front Door'; b.finish=a.finish; b.shared={}; b.history={}; b.motion=true; b.created=now()
 bells[b.id]=b; event(b,'installed',b.ownerName)
 for _,s in ipairs(GetPlayers()) do local p=tonumber(s); if GetPlayerRoutingBucket(p)==b.bucket then TriggerClientEvent('whip_doorbell:add',p,public(b)) end end
 invalidate(b); return b.id
end
H.mine=function(src)
 local list={}; for _,b in pairs(bells) do if access(src,b) then
  local shared={}; if owner(src,b) then for id,name in pairs(b.shared or {}) do shared[#shared+1]={id=id,name=name} end end
  local p=pending[b.id]; list[#list+1]={id=b.id,label=b.label,finish=b.finish,owner=owner(src,b),ownerName=b.ownerName,history=b.history or {},shared=shared,motion=b.motion~=false,ringing=p~=nil and p.src~=src and p.untilTime>=now() and near(p.src,b,Config.TalkRange),talking=active(src,b) and true or false,viewing=viewers[src]~=nil and viewers[src].id==b.id,previewAt=validPreview(b.preview) and b.previewAt or nil}
 end end
 table.sort(list,function(a,b) return a.label<b.label end); return {list=list,autoPreview=Config.AutoPreview~=false,autoInterval=autoInterval(),serverTime=now()}
end
H.ring=function(src,a)
 local b=bells[a.id]; if not b or not near(src,b,2.8) then return false,'Too far from doorbell' end
 if calls[b.id] then return false,'The intercom is already in use' end
 local k=b.id..':'..src; if (rings[k] or 0)>now() then return false,'Please wait before ringing again' end
 rings[k]=now()+Config.RingCooldown
 if not calls[b.id] then pending[b.id]={src=src,character=char(src),untilTime=now()+Config.RingAnswerSeconds} end
 event(b,'ring',Config.ShowVisitorNames and Bridge.name(src) or 'Person'); fx(b,'ringFx')
 online(b,function(p) notify(p,b,'ring') end); return true
end
H.motion=function(src,a)
 local b=bells[a.id]; if not b or b.motion==false or access(src,b) or not near(src,b,Config.MotionRange) then return false,'No motion' end
 if (motions[b.id] or 0)>now() then return false,'Cooldown' end
 local c=GetEntityCoords(GetPlayerPed(src)); local r=math.rad(b.h); local dx,dy=c.x-b.x,c.y-b.y
 if dx*math.sin(r)-dy*math.cos(r)<=0.25*math.sqrt(dx*dx+dy*dy) then return false,'Outside sensor' end
 motions[b.id]=now()+Config.MotionCooldown; event(b,'motion',Config.ShowVisitorNames and Bridge.name(src) or 'Person')
 online(b,function(p) notify(p,b,'motion') end); return true
end
H.answer=function(src,a)
 local b=bells[a.id]; if not access(src,b) then return false,'No device access' end
 if calls[b.id] or busy[b.id] or connecting[src] then return false,'Intercom already in use' end
 for _,c in pairs(calls) do if c.host==src or c.visitor==src then return false,'You are already on an intercom' end end
 local p=pending[b.id]
 if not p or p.untilTime<now() or p.src==src or char(p.src)~=p.character or not near(p.src,b,Config.TalkRange) then return false,'No visitor waiting at the door' end
 if connecting[p.src] then return false,'Visitor is connecting' end
 for _,c in pairs(calls) do if c.host==p.src or c.visitor==p.src then return false,'Visitor already on an intercom' end end
 local hostChar=char(src); busy[b.id]=true; connecting[src]=true; connecting[p.src]=true
 local ok,line,why=pcall(Whip.voice,'OpenLine',{members={src,p.src},track='voice',recipe={{'band',low=300,high=3400},{'compress',threshold=-24,ratio=4}},pickup=false,minMembers=2,onEnd=function(id) local c=calls[b.id]; if c and c.line==id then endCall(b.id,'Voice disconnected',true) end end,onLeave=function(id) local c=calls[b.id]; if c and c.line==id then endCall(b.id,'Participant left') end end})
 busy[b.id]=nil; connecting[src]=nil; connecting[p.src]=nil
 if not ok or not line then return false,why or 'Voice service unavailable' end
 if char(src)~=hostChar or not access(src,b) or not near(p.src,b,Config.TalkRange) or char(p.src)~=p.character or bells[b.id]~=b then Whip.voice('CloseLine',line); return false,'Visitor or device no longer available' end
 calls[b.id]={line=line,host=src,hostChar=char(src),visitor=p.src,visitorChar=p.character,untilTime=now()+Config.TalkSeconds}; pending[b.id]=nil
 Whip.core:NotifyPlayer(p.src,'Doorbell answered. Use your usual voice key to talk. Stay near the doorbell.','success',6500)
 TriggerClientEvent('whip_doorbell:visitorVoice',p.src,b.id,true); push(src,'voice',{id=b.id,active=true}); invalidate(b); return true
end
H.hangup=function(src,a)
 local c=calls[a.id]; if c and (c.host==src or c.visitor==src) then endCall(a.id,'Ended'); return true end
 return true
end
H.leave=function(src)
 for id,c in pairs(calls) do if c.host==src then endCall(id,'Phone app closed') end end
 endView(src); for token,r in pairs(previewRequests) do if r.src==src then previewRequests[token]=nil; TriggerClientEvent('whip_doorbell:cancelPreview',src) end end; return true
end
H.preview=function(src,a)
 local b=bells[a.id]; if not access(src,b) then return false,'No device access' end
 if GetPlayerRoutingBucket(src)~=b.bucket then return false,'Doorbell is in another instance' end
 if viewers[src] then return false,'Close live view before refreshing the preview' end
 local t=now(); local automatic=a.automatic==true
 if automatic then
  if Config.AutoPreview==false then return false,'Automatic previews disabled' end
  if validPreview(b.preview) and t-(tonumber(b.previewAt) or 0)<autoInterval() then return false,'Preview is already up to date' end
  if pending[b.id] or calls[b.id] or busy[b.id] or connecting[src] then return false,'Doorbell is busy' end
  for _,c in pairs(calls) do if c.host==src or c.visitor==src then return false,'Intercom in progress' end end
  local ped=GetPlayerPed(src); if ped==0 or GetVehiclePedIsIn(ped,false)~=0 or GetEntitySpeed(ped)>0.5 then return false,'Automatic preview deferred while moving' end
 end
 if (previewCooldown[src] or 0)>t then return false,'Please wait before refreshing again' end
 for _,r in pairs(previewRequests) do if (r.src==src or r.id==b.id) and r.untilTime>=t then return false,'A capture is already in progress' end end
 previewCooldown[src]=t+8
 local token=('%d:%d:%d'):format(src,t,math.random(100000,999999))
 previewRequests[token]={src=src,id=b.id,character=char(src),untilTime=t+50}
 TriggerClientEvent('whip_doorbell:capturePreview',src,public(b),token,automatic)
 return {queued=true}
end
H.previewImage=function(src,a)
 local b=bells[a.id]; if not access(src,b) then return false,'No device access' end
 if not validPreview(b.preview) then return false,'No saved preview' end
 local t=GetGameTimer(); if (previewDownloads[src] or 0)>t then return false,'Preview download is cooling down' end
 previewDownloads[src]=t+1000
 TriggerLatentClientEvent('whip_doorbell:previewImage',src,64000,b.id,b.previewAt,b.preview)
 return true
end

H.camera=function(src,a)
 local b=bells[a.id]; if not access(src,b) then return false,'No device access' end
 if GetPlayerRoutingBucket(src)~=b.bucket then return false,'Camera is in another instance' end
 endView(src); viewers[src]={id=b.id,character=char(src),untilTime=now()+Config.TalkSeconds}; TriggerClientEvent('whip_doorbell:camera',src,public(b)); return true
end
H.endCamera=function(src) endView(src); return true end
H.pan=function(src,a)
 local v=viewers[src]; if not v or not access(src,bells[v.id]) then return false,'Camera not open' end
 if a.dir~='left' and a.dir~='right' and a.dir~='up' and a.dir~='down' then return false,'Invalid direction' end
 TriggerClientEvent('whip_doorbell:pan',src,a.dir); return true
end
H.siren=function(src,a)
 local b=bells[a.id]; if not access(src,b) then return false,'No device access' end
 if (sirens[b.id] or 0)>now() then return false,'Siren cooling down' end
 sirens[b.id]=now()+math.ceil(Config.SirenTime/1000)+5; event(b,'siren',Bridge.name(src)); fx(b,'siren'); invalidate(b); return true
end
H.rename=function(src,a) local b=bells[a.id]; local l=safeLabel(a.label); if not owner(src,b) or not l then return false,'Invalid name or owner' end; b.label=l; save(); invalidate(b); return true end
H.motionToggle=function(src,a) local b=bells[a.id]; if not owner(src,b) or type(a.on)~='boolean' then return false,'Owner only' end; b.motion=a.on; save(); invalidate(b); return true end
H.share=function(src,a)
 local b=bells[a.id]; if not owner(src,b) then return false,'Owner only' end
 local target=tonumber(a.target); if not target or target<1 or target%1~=0 or target>65535 then return false,'Invalid server ID' end; local c=char(target); if not c or c==char(src) then return false,'Invalid online player' end
 b.shared=b.shared or {}; b.shared[c]=Bridge.name(target); save(); notify(target,b,'shared'); invalidate(b); return true
end
H.unshare=function(src,a)
 local b=bells[a.id]; if not owner(src,b) or type(a.idf)~='string' then return false,'Owner only' end
 local c=b.shared and b.shared[a.idf]; if not c then return true end
 b.shared[a.idf]=nil; save(); local call=calls[b.id]; if call and call.hostChar==a.idf then endCall(b.id,'Access revoked') end
 for _,s in ipairs(GetPlayers()) do local p=tonumber(s); if char(p)==a.idf then if viewers[p] and viewers[p].id==b.id then endView(p) end; push(p,'changed',{id=b.id}) end end
 invalidate(b); return true
end
H.remove=function(src,a)
 local b=bells[a.id]; if not owner(src,b) then return false,'Owner only' end
 if not near(src,b,3.5) then return false,'Stand next to the doorbell to remove it' end
 if not Bridge.addItem(src) then return false,'Could not return item' end
 cleanDevice(b.id); bells[b.id]=nil; save(); fx(b,'remove'); invalidate(b); return true
end
H.waypoint=function(src,a) local b=bells[a.id]; if not access(src,b) then return false,'No device access' end; TriggerClientEvent('whip_doorbell:waypoint',src,b.x,b.y); return true end
Whip.register(function()
 for name,handler in pairs(H) do
  Whip.core:SecureCallback(RES..':'..name,{rateLimit=(name=='pan' or name=='mine' or name=='previewImage') and 150 or 450,params={{'args','any'}}},function(src,player,args)
   if type(args)~='table' then args={} end
   if not player or not player.charId then return false,'No character loaded' end
   if args.id~=nil and (type(args.id)~='string' or #args.id>40) then return false,'Invalid device' end
   return handler(src,args)
  end)
 end
end)
CreateThread(function()
 while true do
  local t=now()
  for id,p in pairs(pending) do local b=bells[id]; if not b or t>p.untilTime or char(p.src)~=p.character or not near(p.src,b,Config.TalkRange) then pending[id]=nil; if b then invalidate(b) end end end
  for id,c in pairs(calls) do local b=bells[id]; if not b or t>c.untilTime or char(c.host)~=c.hostChar or not access(c.host,b) or char(c.visitor)~=c.visitorChar or not near(c.visitor,b,Config.TalkRange) then endCall(id,'Visitor left or session expired') end end
  for src,v in pairs(viewers) do local b=bells[v.id]; if not b or t>v.untilTime or char(src)~=v.character or not access(src,b) or GetPlayerRoutingBucket(src)~=b.bucket then endView(src) end end
  for k,till in pairs(rings) do if t>till then rings[k]=nil end end
  for token,r in pairs(previewRequests) do if t>r.untilTime then previewRequests[token]=nil; push(r.src,'previewResult',{id=r.id,ok=false,reason='Capture timed out'}) end end
  for src,till in pairs(previewCooldown) do if t>till then previewCooldown[src]=nil end end
  Wait((next(pending) or next(calls) or next(viewers)) and 750 or 2000)
 end
end)
AddEventHandler('playerDropped',function() local src=source; viewers[src]=nil; previewDownloads[src]=nil; previewCooldown[src]=nil; for id,c in pairs(calls) do if c.host==src or c.visitor==src then endCall(id,'Participant disconnected') end end for token, req in pairs(previewRequests) do if req.src==src then previewRequests[token]=nil end end end)

RegisterNetEvent('whip_doorbell:previewCapture',function(token,id,data,reason)
 local src=source
 if type(token)~='string' or #token>80 or type(id)~='string' then return end
 local req=previewRequests[token]
 if not req or req.src~=src or req.id~=id or req.untilTime<now() or char(src)~=req.character then return end
 previewRequests[token]=nil
 local b=bells[id]
 if not b or not access(src,b) or GetPlayerRoutingBucket(src)~=b.bucket then return end
 if validPreview(data) then
  b.preview=data
  b.previewAt=now()
  save()
  push(src,'previewResult',{id=id,ok=true,previewAt=b.previewAt})
  invalidate(b)
 else
  push(src,'previewResult',{id=id,ok=false,reason=type(reason)=='string' and reason:sub(1,180) or 'WHIP screenshot failed. Check whip_core version and try again.'})
 end
end)
AddEventHandler('onResourceStop',function(res) if res==RES then save(); for id in pairs(calls) do endCall(id,'Resource stopped') end elseif res=='whip_voice' or res=='whip_phone' then for id in pairs(calls) do endCall(id,'Service restarted',res=='whip_voice') end; for src in pairs(viewers) do endView(src) end end end)
