local bells, props, access, litUntil, motionSent = {}, {}, {}, {}, {}
local live, bucket, visitorCall = nil, nil, nil
RegisterNetEvent('whip_doorbell:visitorVoice',function(id,on) if on then visitorCall=id elseif visitorCall==id then visitorCall=nil end end)
local function request(name,args) return Whip.core:Callback(GetCurrentResourceName()..':'..name,args or {}) end
local function nui(action,data) SendNUIMessage({action=action,data=data}) end
local function notify(msg,kind) Whip.core:Notify(msg,kind or 'info') end
local function frontDir(h) local r=math.rad(h); return vector3(math.sin(r),-math.cos(r),0.0) end
local function localToWorld(b,x,y,z) local r=math.rad(b.h); return vector3(b.x+x*math.cos(r)-y*math.sin(r),b.y+x*math.sin(r)+y*math.cos(r),b.z+z) end
local function model(finish,lit) return joaat(('vista_doorbell_%s%s'):format(finish,lit and '_lit' or '')) end
local function loadModel(m) if not IsModelInCdimage(m) then return false end; RequestModel(m); local t=GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer()-t<3000 do Wait(0) end; return HasModelLoaded(m) end
local function despawn(id)
 local p=props[id]; if p and DoesEntityExist(p.obj) then DeleteEntity(p.obj) end; props[id]=nil
end
local function spawn(id,lit)
 local b=bells[id]; if not b then return end
 local m=model(b.finish,lit); if not loadModel(m) then return end
 if bells[id]~=b then SetModelAsNoLongerNeeded(m); return end
 local obj=CreateObjectNoOffset(m,b.x,b.y,b.z,false,false,false); SetModelAsNoLongerNeeded(m)
 if obj==0 then return end
 SetEntityHeading(obj,b.h); FreezeEntityPosition(obj,true); SetEntityInvincible(obj,true)
 despawn(id); props[id]={obj=obj,lit=lit}
end
local function add(b)
 bells[b.id]=b
 Whip.core:AddAction({id='vista_'..b.id,at={coords=localToWorld(b,0,-0.06,-0.0275)},label=function() return visitorCall==b.id and 'End conversation' or 'Ring doorbell' end,reach=2.0,press=true,onSelect=function()
  if visitorCall==b.id then request('hangup',{id=b.id}); return end
  local ok,why=request('ring',{id=b.id}); if not ok then notify(why or 'Unable to ring','error') else notify('Doorbell rung. Stay nearby to speak when answered.','info') end
 end})
end
local function remove(id) despawn(id); bells[id]=nil; access[id]=nil; litUntil[id]=nil; motionSent[id]=nil; Whip.core:RemoveAction('vista_'..id) end
local function clear() for id in pairs(bells) do remove(id) end end
RegisterNetEvent('whip_doorbell:add',add)
RegisterNetEvent('whip_doorbell:remove',remove)
RegisterNetEvent('whip_doorbell:waypoint',function(x,y) SetNewWaypoint(x,y) end)
Whip.register(function() bucket=nil end)
CreateThread(function()
 while true do
  if Whip.core:IsPlayerLoaded() then
   local result=request('world',{bucket=bucket}); if result then
    if result.list then clear(); for _,b in ipairs(result.list) do add(b) end end; bucket=result.bucket; access={}; for _,id in ipairs(result.owned or {}) do access[id]=true end
   end
  elseif bucket~=nil then clear(); bucket=nil end
  Wait(5000)
 end
end)
CreateThread(function()
 while true do
  local pc=GetEntityCoords(PlayerPedId()); local t=GetGameTimer()
  for id,b in pairs(bells) do
   local pos=vector3(b.x,b.y,b.z); local d=#(pc-pos); local wantLit=(litUntil[id] or 0)>t
   local cameraNear=live and #(live.pos-pos)<Config.DrawDistance
   if d<Config.DrawDistance or cameraNear then
    if not props[id] or props[id].lit~=wantLit or not DoesEntityExist(props[id].obj) then spawn(id,wantLit) end
   elseif props[id] then despawn(id) end
   if d<Config.MotionRange and not access[id] and (motionSent[id] or 0)<t then
    local rel=pc-pos; local f=frontDir(b.h)
    if (rel.x*f.x+rel.y*f.y)/math.max(d,0.01)>0.25 then
     motionSent[id]=t+Config.MotionCooldown*1000
     CreateThread(function() request('motion',{id=id}) end)
    end
   end
  end
  Wait(next(bells) and 750 or 1500)
 end
end)
local function sound(id,name,range,volume,duration)
 local b=bells[id]; if not b then return end
 local d=#(GetEntityCoords(PlayerPedId())-vector3(b.x,b.y,b.z)); if live and live.id==id then d=0 end
 if d<range and volume>0 then nui('sound',{name=name,volume=(1-d/range)^1.6*volume,duration=duration}) end
end
RegisterNetEvent('whip_doorbell:ringFx',function(id) if bells[id] then litUntil[id]=GetGameTimer()+Config.RingLightTime; sound(id,'chime',Config.ChimeRange,Config.ChimeVolume) end end)
RegisterNetEvent('whip_doorbell:siren',function(id) sound(id,'siren',45.0,0.8,Config.SirenTime) end)
local installing, installGhost = false, nil
local function camDirection()
  local rot = GetGameplayCamRot(2)
  local rx, rz = math.rad(rot.x), math.rad(rot.z)
  return vector3(-math.sin(rz) * math.abs(math.cos(rx)), math.cos(rz) * math.abs(math.cos(rx)), math.sin(rx))
end

local function startInstall()
  if installing or live then return end
  installing = true
  local fi = 1
  local ghost, ghostFinish
  local lastUi = nil
  local label = 'Front Door'
  nui('install', { show = true, finish = Config.Finishes[fi].label })
  while installing do
    Wait(0)
    if IsEntityDead(PlayerPedId()) then break end
    DisableControlAction(0, 24, true); DisableControlAction(0, 25, true); DisableControlAction(0, 140, true)
    DisableControlAction(0, 174, true); DisableControlAction(0, 175, true); DisableControlAction(0, 177, true)
    DisableControlAction(0, 191, true); DisableControlAction(0, 199, true); DisableControlAction(0, 200, true)
    local from = GetGameplayCamCoord()
    local to = from + camDirection() * 6.0
    local ray = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 1 + 16, PlayerPedId(), 7)
    local _, hit, pos, normal = GetShapeTestResult(ray)
    local finish = Config.Finishes[fi].id
    if not ghost or ghostFinish ~= finish then
      if ghost then DeleteEntity(ghost); ghost=nil; installGhost=nil end
      local m = model(finish, false)
      if loadModel(m) then
        ghost = CreateObjectNoOffset(m, pos.x, pos.y, pos.z, false, false, false); installGhost=ghost
        SetEntityCollision(ghost, false, false); SetEntityAlpha(ghost, 190, false); FreezeEntityPosition(ghost, true)
        ghostFinish = finish; SetModelAsNoLongerNeeded(m)
      end
    end
    local valid = hit == 1 and math.abs(normal.z) < 0.35 and #(GetEntityCoords(PlayerPedId()) - pos) < 3.0
    local h = math.deg(math.atan(normal.x, -normal.y))
    if ghost then
      if hit == 1 then
        local p = pos + normal * 0.002
        SetEntityCoordsNoOffset(ghost, p.x, p.y, p.z, false, false, false)
        SetEntityHeading(ghost, h)
        SetEntityVisible(ghost, true, false)
      else
        SetEntityVisible(ghost, false, false)
      end
      SetEntityAlpha(ghost, valid and 220 or 90, false)
    end
    local uiKey = tostring(fi)..tostring(valid)
    if uiKey ~= lastUi then lastUi = uiKey; nui('install', { show = true, finish = Config.Finishes[fi].label, valid = valid }) end
    if IsDisabledControlJustPressed(0, 174) then fi = fi == 1 and #Config.Finishes or fi - 1 end
    if IsDisabledControlJustPressed(0, 175) then fi = fi % #Config.Finishes + 1 end
    if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) then break end
    if (IsDisabledControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 24)) and valid then
      local p = pos + normal * 0.002
      local ped = PlayerPedId()
      TaskTurnPedToFaceCoord(ped, p.x, p.y, p.z, 800)
      Wait(500)
      TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_HAMMERING', 0, true)
      Wait(3500)
      ClearPedTasks(ped)
      local res, err = request('install', { x = p.x, y = p.y, z = p.z, h = h, finish = finish, label = label,  })
      if res then notify('Vista Doorbell installed. Open Vista Home on your phone.','success'); access[res] = true
      else notify(tostring(err),'error') end
      break
    end
  end
  if ghost then DeleteEntity(ghost) end; installGhost=nil
  nui('install', { show = false })
  installing = false
end

RegisterNetEvent('whip_doorbell:startInstall',function() CreateThread(startInstall) end)
local function endLive()
 if not live then return end
 RenderScriptCams(false,false,0,true,true); DestroyCam(live.cam,false); ClearFocus(); ClearTimecycleModifier(); ClearExtraTimecycleModifier(); DisplayRadar(true); live=nil
end

local function startLiveView(b)
 endLive(); if not b then return end
 local pos=localToWorld(b,0,-0.04,0.0405)
 SetFocusPosAndVel(pos.x,pos.y,pos.z,0,0,0)
 local cam=CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',pos.x,pos.y,pos.z,-6.0,0,b.h+180.0,Config.CameraFov,false,2)
 SetCamActive(cam,true); RenderScriptCams(true,false,0,true,true)
 local h=GetClockHours(); local a,e=Config.NightStart,Config.NightEnd; local night=(a<e and h>=a and h<e) or (a>e and (h>=a or h<e))
 if night then SetTimecycleModifier('CAMERA_BW'); SetTimecycleModifierStrength(1.0) end
 live={cam=cam,id=b.id,pos=pos,yaw=0,pitch=-6,baseH=b.h+180.0}; DisplayRadar(false)
end

-- TakeScreenshot is a yielding WHIP export. Keep the capture camera separate
-- from the phone's normal live-view session and restore the original DUI camera.
local capturing = nil
local PREVIEW_MAX = 96000
local function phonePush(event, data)
 if GetResourceState('whip_phone')=='started' then
  local ok, err=pcall(function() exports.whip_phone:Push('vista_home',event,data) end)
  if not ok then print('[whip_doorbell] preview phone bridge: '..tostring(err)) end
 end
end
local function reportCapture(b,token,reason)
 print('[whip_doorbell] preview failed: '..reason)
 phonePush('previewStatus',{id=b.id,stage='error',reason=reason})
 TriggerServerEvent('whip_doorbell:previewCapture',token,b.id,false,reason)
end
local function finishCapture(session)
 if capturing~=session then return end
 capturing=nil
 if DoesCamExist(session.cam) then
  if GetRenderingCam()==session.cam or IsCamActive(session.cam) then
   if session.previous and session.previous>0 and DoesCamExist(session.previous) and exports.whip_phone:IsOpen() then
    SetCamActive(session.previous,true); RenderScriptCams(true,false,0,true,true)
   else RenderScriptCams(false,false,0,true,true) end
  end
  DestroyCam(session.cam,false)
 end
 ClearFocus()
end
local function validImage(image)
 return type(image)=='string' and #image<=PREVIEW_MAX and (image:match('^data:image/webp;base64,[A-Za-z0-9+/=]+$') or image:match('^data:image/jpeg;base64,[A-Za-z0-9+/=]+$'))
end
local function safeAutoCapture()
 local ped=PlayerPedId()
 return not IsEntityDead(ped) and not IsPedInAnyVehicle(ped,false) and not IsPauseMenuActive() and not visitorCall and GetEntitySpeed(ped)<=0.5
end
local function capturePreview(b,token,automatic)
 if automatic and not safeAutoCapture() then reportCapture(b,token,'Automatic preview deferred while busy.'); return end
 if capturing or live or installing or not exports.whip_phone:IsOpen() then
  reportCapture(b,token,'Close live view and keep the phone open.'); return
 end
 local pos=localToWorld(b,0,-0.10,0.0405)
 local previous=GetRenderingCam()
 local cam=CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',pos.x,pos.y,pos.z,-6.0,0,b.h+180.0,Config.CameraFov,false,2)
 if not cam or cam==0 or not DoesCamExist(cam) then reportCapture(b,token,'Could not create the doorbell camera.'); return end
 local session={cam=cam,previous=previous}; capturing=session
 phonePush('previewStatus',{id=b.id,stage='camera'})
 SetFocusPosAndVel(pos.x,pos.y,pos.z,0,0,0); RequestCollisionAtCoord(pos.x,pos.y,pos.z)
 SetCamActive(cam,true); RenderScriptCams(true,false,0,true,true)
 local deadline=GetGameTimer()+2500
 -- RenderingCam can still refer to the previous DUI camera during the first frames.
 while capturing==session and GetRenderingCam()~=cam and GetGameTimer()<deadline do Wait(0) end
 if capturing~=session then return end
 if GetRenderingCam()~=cam then finishCapture(session); reportCapture(b,token,'Doorbell camera did not become active.'); return end
 CreateThread(function()
  while capturing==session do
   if not exports.whip_phone:IsOpen() or IsEntityDead(PlayerPedId()) or (automatic and not safeAutoCapture()) then finishCapture(session); break end
   HideHudAndRadarThisFrame(); DisableControlAction(0,30,true); DisableControlAction(0,31,true); DisableControlAction(0,24,true); DisableControlAction(0,25,true); Wait(0)
  end
 end)
 Wait(1500)
 if capturing~=session then reportCapture(b,token,'Capture cancelled.'); return end
 phonePush('previewStatus',{id=b.id,stage='capture'})
 local image,reason=nil,'Screenshot unavailable.'
 local options={{format='jpg',quality=0.62,width=640,height=360,ui=false},{format='webp',quality=0.45,width=480,height=270,ui=false}}
 for _,opts in ipairs(options) do
  if capturing~=session or GetRenderingCam()~=cam then reason='Doorbell camera was interrupted.'; break end
  local ok,result,why=pcall(function() return exports.whip_core:TakeScreenshot(opts) end)
  if ok and validImage(result) then image=result; break end
  if not ok then reason='WHIP capture export error: '..tostring(result); break end
  if type(result)=='string' and #result>PREVIEW_MAX then reason='Screenshot exceeded the thumbnail limit.'
  elseif result==false or result==nil then reason='WHIP capture failed: '..tostring(why or 'no image returned')
  else reason='WHIP returned an unsupported image.' end
 end
 local valid=capturing==session and GetRenderingCam()==cam and image~=nil
 finishCapture(session)
 if not valid then reportCapture(b,token,reason); return end
 -- Show the local screenshot immediately, independently of the server round trip.
 phonePush('previewLocal',{id=b.id,preview=image})
 print(('[whip_doorbell] captured %s (%d bytes), saving'):format(b.id,#image))
 TriggerLatentServerEvent('whip_doorbell:previewCapture',64000,token,b.id,image)
end
RegisterNetEvent('whip_doorbell:capturePreview',function(b,token,automatic)
 if source~=65535 then return end
 CreateThread(function() local ok,err=pcall(capturePreview,b,token,automatic==true); if not ok then if capturing then finishCapture(capturing) end; reportCapture(b,token,'Capture error: '..tostring(err)) end end)
end)
RegisterNetEvent('whip_doorbell:cancelPreview',function() if source==65535 and capturing then finishCapture(capturing) end end)
RegisterNetEvent('whip_doorbell:previewImage',function(id,at,image)
 if source~=65535 or not validImage(image) then return end
 if GetResourceState('whip_phone')=='started' and exports.whip_phone:IsOpen() then phonePush('preview',{id=id,previewAt=at,preview=image}) end
end)
RegisterNetEvent('whip_doorbell:camera',function(b)
 if capturing then finishCapture(capturing) end
 startLiveView(b)
end)
RegisterNetEvent('whip_doorbell:pan',function(dir)
 if not live then return end
 if dir=='left' then live.yaw=math.min(Config.MaxPan,live.yaw+8) elseif dir=='right' then live.yaw=math.max(-Config.MaxPan,live.yaw-8) elseif dir=='up' then live.pitch=math.min(15,live.pitch+5) elseif dir=='down' then live.pitch=math.max(-35,live.pitch-5) end
 SetCamRot(live.cam,live.pitch,0,live.baseH+live.yaw,2)
end)
CreateThread(function()
 while true do
  if live then
   if not exports.whip_phone:IsOpen() or IsEntityDead(PlayerPedId()) then endLive(); CreateThread(function() request('endCamera') end); Wait(300) else
    HideHudAndRadarThisFrame(); DisableControlAction(0,30,true); DisableControlAction(0,31,true); DisableControlAction(0,24,true); DisableControlAction(0,25,true); Wait(0)
   end
  else Wait(300) end
 end
end)
local function registerPhone()
 if GetResourceState('whip_phone')=='started' then
  local ok,why=exports.whip_phone:RegisterModule({id='vista_home',script='html/phone_app_v207.js'}); if not ok then print('[whip_doorbell] phone module: '..tostring(why)) end
 end
end
CreateThread(registerPhone)
AddEventHandler('onResourceStart',function(res) if res=='whip_phone' then registerPhone() end end)
AddEventHandler('onResourceStop',function(res) if res==GetCurrentResourceName() then if capturing then finishCapture(capturing) end; endLive(); if installGhost then DeleteEntity(installGhost); ClearPedTasks(PlayerPedId()) end; clear(); if GetResourceState('whip_phone')=='started' then exports.whip_phone:UnregisterModule('vista_home') end elseif res=='whip_phone' then if capturing then finishCapture(capturing) end; endLive() end end)
