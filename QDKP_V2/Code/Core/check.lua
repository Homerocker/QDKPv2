-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--                   Check
--
--  Subsystem used to check that DKP amounts have been correctly sent to the
--  Guild notes.
--
--  API Documentation:
--  QDKP2_InitiateCheck(): This starts the check process, which is a timed succession of subroutines. Will return immediately.
--  QDKP2_StopCheck(): Halt the ongoing check (if any).



-------------------------------------- Locals ---------------------------------------


local function StartPlannedRefresh()
-- sets the refreshed Guild Roster flag
  QDKP2_REFRESHED_GUILD_ROSTER = false
  GuildRoster()
end


local function CheckGo()
-- this will download all the officers notes , parse them and then check the
-- values.
  --if QDKP2_AbortCurrentCheck then return; end
  QDKP2_CheckInProgress = false
  local nok = 0
  for i=1, GetNumGuildMembers(true) do
    local name, rank, rankIndex, level, class, zone, note, officernote, online, status =  GetGuildRosterInfo(i);
    if QDKP2_IsInGuild(name) and not QDKP2_IsAlt(name) then
      local Datafield
      if QDKP2_OfficerOrPublic==1 then Datafield=officernote
      elseif QDKP2_OfficerOrPublic==2 then Datafield=note
      end
      local net,total,spent,hours = QDKP2_ParseNote(Datafield)
      if (QDKP2_GetNet(name) == net) and (QDKP2_GetTotal(name) == total) and (QDKP2_GetSpent(name) == spent) and (RoundNum(QDKP2_GetHours(name)*10) == RoundNum(hours*10)) then
        QDKP2log_ConfirmEntries(name,true)
      elseif QDKP2_IsModified(name) then
        if QDKP2checkTries < QDKP2_CHECK_TRIES then
          QDKP2_Debug(1,"Check","Some players aren't syncronized. Checking again...")
          QDKP2_InitiateCheck(1)
          return
        else
          QDKP2log_Entry(name, "CHECK: Values in officer notes aren't correct.",QDKP2LOG_CRITICAL)
          QDKP2_Msg(name.." is not syncronized.","ERROR")
          nok = nok + 1
        end
      end
    end
  end
  if nok == 0 then
    table.wipe(QDKP2altsRestore)
    QDKP2_Msg(QDKP2_COLOR_GREEN..QDKP2_LOC_CheckOK)
    QDKP2log_ConfirmEntries("RAID",true)
  else
    QDKP2_Msg("Please try to upload again.", "ERROR")
  end
  QDKP2_Events:Fire("DATA_UPDATED","roster")
  QDKP2_Events:Fire("DATA_UPDATED","log")
end



local function CheckStart()
  if not QDKP2_CheckInProgress then return; end
  if not QDKP2_REFRESHED_GUILD_ROSTER then
    QDKP2_CHECK_RUN = QDKP2_CHECK_RUN + 1
    if QDKP2_CHECK_RUN >= QDKP2_CHECK_TIMEOUT then
      QDKP2_Msg(QDKP2_COLOR_RED.."Cannot obtain an updated Guild list to check for unupdated DKP. Maybe you're lagging too much.")
      return
    end
    QDKP2_CHECK_RENEW_TIMER = QDKP2_CHECK_RENEW_TIMER+1
    if QDKP2_CHECK_RENEW_TIMER >= QDKP2_CHECK_RENEW then
      QDKP2_CHECK_RENEW_TIMER = 0
      GuildRoster()
    end
    QDKP2_CHECK_WaitRefresh=QDKP2libs.CheckTimer:ScheduleTimer(CheckStart, 1.0)
  else
    --QDKP2_AbortCurrentCheck = false
    QDKP2_CHECK_CheckGo = QDKP2libs.CheckTimer:ScheduleTimer(CheckGo, QDKP2_CHECK_UPLOAD_DELAY)
  end
end



------------------------------------------------CHECK--------------------------

--These functions controls if guildnotes and roster are in sync.

function QDKP2_InitiateCheck(AddTries)
  if QDKP2_CheckInProgress then QDKP2_StopCheck(true); end
  if AddTries then
    QDKP2checkTries=QDKP2checkTries+1
  else
    QDKP2checkTries=0
  end
  QDKP2_CHECK_RUN = 0  --plan the check
  QDKP2_CHECK_RENEW_TIMER = 0
  QDKP2_CheckInProgress = true
  QDKP2_CHECK_PlannedRefresh=QDKP2libs.CheckTimer:ScheduleTimer(StartPlannedRefresh, QDKP2_CHECK_REFRESH_DELAY)
  QDKP2_CHECK_Check = QDKP2libs.CheckTimer:ScheduleTimer(CheckStart, QDKP2_CHECK_REFRESH_DELAY+1)
end
--this is used to detect the update to the guild rooster and delay the real
--check to give time to the changes to propagate in the local cache. (really needed?)

function QDKP2_StopCheck(doNotInform)

  if QDKP2_CheckInProgress then
    if not doNotInform then QDKP2_Msg(QDKP2_LOC_CheckAborted,"WARNING"); end
    QDKP2_ModifiedDuringCheck = true
  end
  --QDKP2_AbortCurrentCheck = true
  QDKP2_CheckInProgress = false
  QDKP2libs.Timer:CancelTimer(QDKP2_CHECK_PlannedRefresh,true)
  QDKP2libs.Timer:CancelTimer(QDKP2_CHECK_Check,true)
  QDKP2libs.Timer:CancelTimer(QDKP2_CHECK_CheckGo,true)
  QDKP2libs.Timer:CancelTimer(QDKP2_CHECK_WaitRefresh,true)
end

