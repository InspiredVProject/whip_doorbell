Bridge = {}
function Bridge.identifier(src)
 local id = Whip.core:GetCharId(src)
 return id and tostring(id) or nil
end
function Bridge.name(src)
 local p = Whip.core:GetPlayer(src)
 return p and p.fullName or 'Person'
end
function Bridge.removeItem(src) return Whip.core:RemoveItem(src, Config.ItemName, 1, nil, {reason='Doorbell installation'}) end
function Bridge.addItem(src) return Whip.core:AddItem(src, Config.ItemName, 1, nil, {reason='Doorbell removal'}) end
Whip.register(function()
 Whip.core:RegisterItem(Config.ItemName,{name='Vista Doorbell',desc='Install a smart video doorbell on a wall.',weight=0.35,type='misc',stack=true,maxStack=5,usable=true,prop='vista_doorbell_nickel'})
 Whip.core:RegisterUseHandler(Config.ItemName,function(src)
  TriggerClientEvent('whip_doorbell:startInstall',src)
  -- WHIP consumes one item when a use handler returns true or nil.
  -- Keep it during placement; H.install removes one after validation.
  return false
 end)
end)
