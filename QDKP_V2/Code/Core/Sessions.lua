-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--              Session management
--
--      Functions that start, stop and modify locally created sessions.
--      Includes functions to check for management mode, and relative errors.
--
-- API Documentation:

function QDKP2_StartSession(SessionName)

  QDKP2_Debug(3, "Session", "Asked to start a new session: "..tostring(SessionName))
  if not QDKP2_OfficerMode() then
    QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")
    return
  end

  if not QDKP2_IsRaidPresent() then
    QDKP2_Msg(QDKP2_LOC_NotIntoARaid, "ERROR")
    return
  end

  if not QDPK2_ReadGuildInfo then
    QDKP2_Msg("Still waiting to read guild data. Please retry in few seconds.", "ERROR")
    return
  end

  if QDKP2_IsManagingSession() then
    QDKP2_Msg("You are managing an open session. To start annother you first need to close this one.")
    return
  end
  local Diff
  local instDiff=GetInstanceDifficulty()
  if     instDiff==1 then Diff="10"
  elseif instDiff==2 then Diff="25"
  elseif instDiff==3 then Diff="10H"
  elseif instDiff==4 then Diff="25H"
  end
  local DefaultSessName=(GetRealZoneText() or UNKNOWN)..' ('..Diff..')'

  if SessionName=="" then
    QDKP2_OpenInputBox(QDKP2_LOC_NewSessionQ,QDKP2_StartSession)
    QDKP2_InputBox_SetDefault(DefaultSessName)
    return
  end

  SessionName=SessionName or QDKP2_LOC_NoSessName

  QDKP2_SID.INDEX=QDKP2_SID.INDEX+1
  QDKP2_SetGuildNotes()
  SID=tostring(QDKP2_SID.INDEX)..'.'..QDKP2_PLAYER_NAME_12
  QDKP2_SID.MANAGING=SID

  --Reset the Raid custom tables
  table.wipe(QDKP2standby)
  table.wipe(QDKP2raidRemoved)

  local msg=string.gsub(QDKP2_LOC_NewSession,"$SESSIONNAME",SessionName)
  QDKP2_Msg(msg)
  QDKP2log_StartSession(QDKP2_SID.MANAGING, SessionName, QDKP2_PLAYER_NAME_12, QDKP2_SID.INDEX)
  local List=QDKP2log_GetSession(SID)
  for i=1, #QDKP2raid do
--    local name = QDKP2_GetMain(QDKP2raid[i])
    local name=QDKP2raid[i]
    local online = QDKP2raidOffline[name]
    local name = QDKP2_GetMain(name)
    if not List[name] then
      if online=="online" then
        QDKP2log_Entry(name,QDKP2_LOC_IsInRaid,QDKP2LOG_JOINED)
      else
        QDKP2log_Entry(name,QDKP2_LOC_IsInRaidOffline,QDKP2LOG_LEFT)
      end
    end
  end

  QDKP2_Events:Fire("SESSION_START",SID)
  QDKP2_Events:Fire("DATA_UPDATED","all")
end

function QDKP2_StopSession(sure)
  local SID=QDKP2_SID.MANAGING
  QDKP2_Debug(2,"Session","Halting current session "..tostring(SID))
  if not SID then
    QDKP2_Msg("No ongoing session.")
    return
  end
  if QDKP2_IronManIsOn() and not sure then
    local msg=QDKP2_LOC_CloseIMSessWarn
    QDKP2_AskUser(msg,QDKP2_StopSession,true)
    return
  end

  if QDKP2_IronManIsOn() then QDKP2_IronManWipe(); end
  if QDKP2_isTimerOn() then QDKP2_TimerOff(); end
  if QDKP2_BidM_isBidding() then QDKP2_BidM_CancelBid(); end
  QDKP2_BidM_CountdownCancel()

  local SID=QDKP2_OngoingSession()
  QDKP2log_StopSession(QDKP2_SID.MANAGING)

  QDKP2_SID.MANAGING=nil
  QDKP2libs.Timer:CancelTimer(QDKP2_CloseSessionTimer,true)

  --Reset the Raid custom tables
  table.wipe(QDKP2standby)
  table.wipe(QDKP2raidRemoved)

  QDKP2_Events:Fire("SESSION_END",SID)
  QDKP2_Events:Fire("DATA_UPDATED","all")
end

--SID = QDKP2_OngoingSession()
--Returns the ongoing session. If no sessions are active, returns the general session.
function QDKP2_OngoingSession()
  return QDKP2_SID.MANAGING or "0"
end

function QDKP2_OngoingSessionDetails()
--just an extension of QDKP2_OngoingSession
--returns List,Name,Mantainer,Code,DateStart,DateStop,DateMod
  local List,Name,Mantainer,Code,DateStart,DateStop,DateMod=QDKP2_GetSessionInfo(QDKP2_OngoingSession())
  if not List then
    QDKP2_Debug(1,"Core","Can't get data of the ongoing session. I'm closing it (if any)")
    QDKP2_StopSession(sure)
  end
  return List,Name,Mantainer,Code,DateStart,DateStop,DateMod
end

function QDKP2_IsSessionPresent()
-- This function will return a list of open sessions where you are currently involved.
-- ATM is same as managingsession as there is no sync.
  return {QDKP2_SID.MANAGING}
end

function QDKP2_IsManagingSession()
  return QDKP2_SID.MANAGING
end

function QDKP2_ManagementMode()
  if QDKP2_IsManagingSession() and QDKP2_OfficerMode() and QDKP2_IsRaidPresent() then return true; end
  return false
end

function QDKP2_OfficerMode()
  --if true then return true; end
  if
  not CanEditGuildInfo() or
  (QDKP2_OfficerOrPublic==2 and not CanEditPublicNote()) or
  (QDKP2_OfficerOrPublic~=2 and not CanEditOfficerNote()) then
    return
  end
  return true
end

function QDKP2_GetPermissions()
--prints a list with the status of the rightsyou need to be a DKP officers.
  local CanEditNote, NoteName, CanEditGuildNotes, GotKey
  if QDKP2_OfficerOrPublic==2 then
    CanEditNote=CanEditPublicNote()
    NoteName="public"
  else
    CanEditNote=CanEditOfficerNote()
    NoteName="officer"
  end
  if CanEditNote then
    CanEditNote=QDKP2_COLOR_GREEN.."CAN"..QDKP2_COLOR_CLOSE
  else
    CanEditNote=QDKP2_COLOR_RED.."CAN'T"..QDKP2_COLOR_CLOSE
  end
--  if QDKP2_RSA.PRIV and QDKP2_RSA.PUB and QDKP2_RSA.MOD and QDKP2_RSA_CheckPrivKey() then
--    GotKey=QDKP2_COLOR_GREEN.."HAVE"..QDKP2_COLOR_CLOSE
--  else
--    GotKey=QDKP2_COLOR_RED.."HAVEN'T"..QDKP2_COLOR_CLOSE
--  end
  if CanEditGuildInfo() then
    CanEditGuildNotes=QDKP2_COLOR_GREEN.."CAN"..QDKP2_COLOR_CLOSE
  else
    CanEditGuildNotes=QDKP2_COLOR_RED.."CAN'T"..QDKP2_COLOR_CLOSE
  end
  local M1="You "..CanEditNote.." edit "..NoteName.." notes."
  local M2="You "..CanEditGuildNotes.." edit Guild infos."
--  local M3="You "..GotKey.." the Guild's private key."
  return M1,M2--,M3
end

function QDKP2_NeedManagementMode()
  QDKP2_Msg(QDKP2_LOC_NeedManagementMode, "WARNING")
end

