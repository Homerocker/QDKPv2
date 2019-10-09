-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--           External Players Functions
--
--      Functions to add, remove or query for an external.

-- API Documentation:
-- QDKP2_NewExternal(name,data): adds an external with the given name. Defaults its data field with <data>
-- QDKP2_DelExternal(name): Removes <name> from the external list
-- QDKP2_IsExternal(name): Returns true if <name> is an external
-- QDKP2_PostExternals(channel,subChannel): Posts in the given channel (or guild) all externals data.


function QDKP2_NewExternal(name,data)
  if not QDKP2_OfficerMode() then QDKP2_Msg(QDKP2_LOC_NoRights,"ERROR")(); return; end
  if not name or name=="" then
    QDKP2_OpenInputBox("Please enter the name of the external",QDKP2_NewExternal,data)
    return
  end
  if not name or #name<3 or #name>12 or string.find(name,"[%c%d%p%s%z]") then
    QDKP2_Msg(QDKP2_LOC_InvalidExternalName,"WARNING")
    return
  end
  if QDKP2_IsInGuild(name) then
    QDKP2_Msg(name.." is already in the guild roster","ERROR")
  end
  name=QDKP2_FormatName(name)
  QDKP2_Debug(2,"Core","Adding "..name.." as external")
  if QDKP2_IsInGuild(name) then
    local msg=string.gsub(QDKP2_LOC_CantAddExternalInGuild,"$NAME",name)
    QDKP2_Msg(msg, "ERROR")
    return
  end
  QDKP2externals[name]={}
  if text then
    QDKP2externals[name].datafield=data
  else
    QDKP2externals[name].datafield=""
  end
  QDKP2externals[name].class="--"
  QDKP2externals[name].version=1
  QDKP2_DownloadGuild()
  return true
end

function QDKP2_DelExternal(name,sure)
  if not QDKP2_OfficerMode() then QDKP2_Msg(QDKP2_LOC_NoRights,"ERROR")(); return; end
  if not QDKP2externals[name] then
    local msg=string.gsub(QDKP2_LOC_CantDeleteUnexistingExternals,"$NAME",name)
    QDKP2_Msg(msg, "ERROR")
    return
  end
  if not sure then
    QDKP2_AskUser("You are deleting "..name.." from the\nGuild Roster.\nThere is no undo. Continue?",QDKP2_DelExternal,name,true)
    return
  end
  QDKP2externals[name]=nil
  QDKP2_DownloadGuild()
  local msg=string.gsub(QDKP2_LOC_ExternalRemoved, "$NAME",name)
  QDKP2_Msg(msg,"INFO")
end

function QDKP2_IsExternal(name)
  if QDKP2externals[name] then return true;
  end
end


function QDKP2_PostExternals(channel,subChannel)
--prints to the given channel (default: guild) a list of Externals' DKP amounts.
  channel=channel or "GUILD"
  local lines={}
  local QDKP2ext_list=ListFromDict(QDKP2externals)
  if table.getn(QDKP2ext_list)==0 then return;end
  table.insert(lines, QDKP2_LOC_ExtPost)
  for i=1, table.getn(QDKP2ext_list) do
    local Name=QDKP2ext_list[i]
    if not QDKP2_IsAlt(Name) then
      local Net=QDKP2_GetNet(Name)
      local Spent=QDKP2_GetSpent(Name)
      local Total=QDKP2_GetTotal(Name)
      local Hours=QDKP2_GetHours(Name)
      local msg=QDKP2_LOC_ExtLine
      msg=string.gsub(msg,"$NAME", Name)
      msg=string.gsub(msg,"$NET", Net)
      msg=string.gsub(msg,"$SPENT", Spent)
      msg=string.gsub(msg,"$TOTAL", Total)
      msg=string.gsub(msg,"$HOURS", Hours)
      table.insert(lines, msg)
    end
  end
  for i=1, table.getn(lines) do
    ChatThrottleLib:SendChatMessage("NORMAL","QDKP2",lines[i],channel,nil,subChannel)
  end
end
