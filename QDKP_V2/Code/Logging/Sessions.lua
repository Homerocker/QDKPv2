-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## LOGGING SYSTEM ##
--                   Sessions

-- API Documentation
-- QDKP2log_StartSession(SID) ...
-- QDKP2log_StopSession(SID): ...
-- QDKP2log_SetSessionName(SID, NewName): ...
-- QDKP2log_GetSessionInfo(SID) Return the following info about the session: List,Name,Mantainer,Code,DateStart,DateStop
-- QDKP2_GetSessionMods(SID,Player) Returns the modifications detail od the given sid. Processes only Player if given.
-- QDKP2log_AddManagementMode(SID, Mode): Called when the holder is mantaining a given raid management aspect.


function QDKP2log_StartSession(SID, Name, Manager, Code, StartTime)

  StartTime=StartTime or QDKP2_Timestamp()

  QDKP2_Debug(2, "Logging", "Starting new session "..SID)

  if QDKP2log[SID] then
    QDKP2_Debug(1,"Logging","Asked to start a session that is already in the log: "..SID..". Exiting...")
    return
  end

  if Name and #Name>32 then Name=string.sub(Name,1,32); end
  QDKP2log[SID]={}
  QDKP2log[SID]._KPR=Manager
  QDKP2log[SID]._TSTA=StartTime
  QDKP2log[SID]._NAME=Name
  QDKP2log[SID]._CODE=Code
  QDKP2log[SID]._MANAGE={}
  QDKP2log[SID].RAID={}

  QDKP2log_PurgeSessions(QDKP2_LOG_MAXSESSIONS, true)
  QDKP2_Debug(3,"Logging","Session "..SID.." has started")
end

function QDKP2log_StopSession(SID, StopTime)

  if not SID then
    QDKP2_Debug(1,"Logging","StopSession called but nil SID provided. exiting...")
    return
  end

  QDKP2_Debug(3,"Logging","Closing session "..SID)

  StopTime=StopTime or QDKP2_Timestamp()

  local SessionLog=QDKP2log[SID]

  if not SessionLog then
    QDKP2_Debug(1,"Logging","Asked to stop a session that does not exist in QDKP2log: "..SID)
	return
  end

  if SessionLog._TSTO then
    QDKP2_Debug(1,"Logging","Asked to stop a session that is already closed: "..SID)
  end

  SessionLog._TSTO = StopTime

  QDKP2log_UpdateSessionModTime(SID)
  QDKP2_Debug(3,"Logging","Session "..SID.." has been closed")
end

function QDKP2log_SetSessionName(SID,NewSessionName)
  if not SID or SID=='0' then
    QDKP2_Debug(1,"Logging","Trying to change the name of nil session or SID=0")
    return
  end
  if NewSessionName=="" then NewSessionName=nil; end
  if NewSessionName and #NewSessionName>32 then NewSessionName=string.sub(NewSessionName,1,32); end
  local Session=QDKP2log[SID]
  if not Session then
    QDKP2_Debug(1,"Logging","Trying to change the name of an inexistent session.")
    return
  end
  Session._NAME=NewSessionName
  QDKP2log_UpdateSessionModTime(SID)
  QDKP2_Events:Fire("DATA_UPDATED","all")
end

  --Returns data out a given SID
function QDKP2_GetSessionInfo(SID)
  local List,Name,Mantainer,Code,DateStart,DateStop,DateMod
  if SID=="0" then
    if not QDKP2log["0"] then QDKP2log["0"]={}; end
    List=QDKP2log["0"]
    Name=QDKP2_LOC_GeneralSessName
    Code=0
    ModID=0
  else
    List=QDKP2log[SID]
    if not List then return; end
    Mantainer=List._KPR
    Name=List._NAME or QDKP2_LOC_NoSessName
    Code=List._CODE
    DateStart=List._TSTA
    DateStop=List._TSTO
    DateMod=List._TMOD
  end
  Name="<"..Name..">"
  return List,Name,Mantainer,Code,DateStart,DateStop,DateMod
end

function QDKP2_GetSessionMods(SID,Player)
--Scans session SID to get the current Version and the last modification detail.
--[Player] Is optional and, if
--use: ModID,ModDate,ModName=QDKP2_GetSessionMods(SID,Player)
--ModID is the sum of every modID of the contained entries. ModDate and ModName is referred to the last modification done.

  QDKP2_Debug(3,"Logging","Extracting modification infos about session "..tostring(SID))
  local Session=QDKP2log[SID]
  if not Session then
    QDKP2_Debug(1,"Logging","Asking for session mod detail but invalid SID given: "..tostring(SID))
    return
  end
  local PlayersList=ListFromDict(Session)
  local ModID=0
  local ModDate
  local ModBy
  for i=1,table.getn(PlayersList) do
    local Name=Player or PlayersList[i] --trik to force the player name, if provided.
    if string.sub(Name,1,1) ~= "_" then
      local PlayerLog=Session[Name]
      if PlayerLog then
        for j=1,table.getn(PlayerLog) do
          local Log=PlayerLog[j]
          ModID=ModID+(Log[QDKP2LOG_FIELD_VERSION] or 0)
          if (Log[QDKP2LOG_FIELD_MODDATE] or 0) > (ModDate or 0) then
            ModDate=Log[QDKP2LOG_FIELD_MODDATE]
            ModBy=Log[QDKP2LOG_FIELD_MODBY] or Log[QDKP2LOG_FIELD_CREATOR] or Session._KPR or UNKNOWN
          end
        end
      end
    end
    if Player then break; end
  end
  if ModID == 0 then ModID=nil; end
  QDKP2_Debug(3,"Logging","ModID="..tostring(ModID)..", ModDate="..tostring(ModDate)..", ModBy="..tostring(ModBy))
  return ModID,ModDate,ModBy
end

function QDKP2log_UpdateSessionModTime(SID)
  if not SID or SID=='0' then
    QDKP2_Debug(1,"Logging","Can't update mod date of session '0'!")
    return
  end
  List=QDKP2log[SID]
  if not List then
    QDKP2_Debug(1,"Logging","Can't increas mod version of inexistent session ("..tostring(SID)..')')
    return
  end
  List._TMOD=QDKP2_Time()
  return true
end


function QDKP2log_AddManagementMode(Mode,SID,arg)
  if not SID then
    SID=QDKP2_OngoingSession()
  end
  if SID=="0" then return; end
  local Session=QDKP2log[SID]
  if not Session then return; end
  if not Session._MANAGE[Mode] then
    Session._MANAGE[Mode]=arg or 1
  end
  QDKP2log_UpdateSessionModTime(SID)
end
