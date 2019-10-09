-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--                   ## GUI ##
--                Log - Player View
--

-- See Log.lua for information about this class.

myClass={}

local function IsSession(Log)
  if QDKP2log_GetType(Log)==QDKP2LOG_SESSION then return true; end
end

local function CreateVoice(Log)
  local voice={}
  voice.Log=Log
  voice.Time=QDKP2log_GetModEntryDateTime(Log)
  voice.DKPchange=QDKP2log_GetChange(Log)
  voice.Desc=QDKP2log_GetModEntryText(Log,QDKP2GUI_Log.MainSelection=='RAID')
  voice.Type=QDKP2log_GetType(Log)
  voice.ID=QDKP2log_GetTS(Log)
  voice.Player=QDKP2GUI_Log.MainSelection
  return voice
end

myClass.GetList=function()
  local name=QDKP2GUI_Log.MainSelection
  if not name then return {}; end
  local origList=QDKP2log_ParsePlayerLog(name)

  local dkpList
  if QDKP2GUI_Log.MainSelection ~= 'RAID' then
    dkpList=QDKP2log_GetNetAmounts(origList, QDKP2_GetNet(name))
  else
    dkpList={}
  end
  local list={}
  for i=1,#origList do
    local v=origList[i]
    local voice=CreateVoice(v)
    voice.DKPhist=dkpList[i]
    if IsSession(v) then
      local SID=QDKP2log_GetReason(v)
      local Session=origList[SID]
      local dkpSess
      if QDKP2GUI_Log.MainSelection ~= 'RAID' then
        dkpSess=QDKP2log_GetNetAmounts(Session, voice.DKPhist)
      else
        dkpSess={}
      end
      local SIDList={}
      for j=1,#Session do
        local w=Session[j]
        local subVoice=CreateVoice(w)
        subVoice.DKPhist=dkpSess[j]
        subVoice.isChild=voice
        table.insert(SIDList,subVoice)
      end
      voice.SubList=SIDList
      voice.SubListID=SID
    end
    table.insert(list,voice)
  end
  return list
end

myClass.GetTitle=function()
  return QDKP2GUI_Log.MainSelection.."'s Log"
end


myClass.MenuVoices={
}


myClass.VoiceMenu=function()
end

myClass.WindowMenu=function() return; end

myClass.MakeReport=function(list,Type,channel,subChannel)
  local Header
  local Add={}
  if Type=="this" then Header="Single log voice"
  elseif Type=="sub" then
    local SID=QDKP2GUI_Log.MenuVoice.SubListID or QDKP2GUI_Log.MenuVoice.isChild.SubListID
    local _,Name,Mantainer,Code,DateStart,DateStop,ModDate=QDKP2_GetSessionInfo(SID)
    Name=Name or '<'..QDKP2_LOC_Unknown..'>'
    Header="Session "..Name
    if DateStop then table.insert(Add,"Closed on: "..QDKP2_GetDateTextFromTS(DateStart)); end
    if DateStart then table.insert(Add,"Started on: "..QDKP2_GetDateTextFromTS(DateStart)); end
    table.insert(Add,"Session manager: "..tostring(Mantainer or '-'))
  elseif Type=="curr" then Header="Personal overview"
  end
  local logList={}
  for i,v in pairs(list) do logList[i]=v.Log; end
  out=QDKP2_GetReport(logList, QDKP2GUI_Log.MainSelection, Header)
  for k,v in pairs(Add) do
    table.insert(out,2,v)
  end
  return out
end


QDKP2GUI_Log.LogViews.player=myClass
