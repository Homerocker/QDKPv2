-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## LOGGING SYSTEM ##
--             Log Entry functions

-- API Documentation
-- QDKP2log_Entry: Creates a new log entry. See the function description for mole details.
-- QDKP2log_Event(name,event): Dummy of QDKP2log_Entry, gives a fast interface to create a new Event type log entry
-- QDKP2log_Link: Not-real-dummy of QDKP2log_Entry that creates a link to a given log.
-- QDKP2log_UnDoEntry(name,log,SID,[on,off]): Toggle a DKP log entry between ACTIVE and INACTIVE status. Takes care to add/subtract DKPs.
-- QDKP2log_SetLogEntry(name,log,SID,[G,S,H,Reason]): Changes the log's DKP and reason.
-- QDKP2log_AwardLinkedEntry(name,log,SID,todo=toggle): Set log to award or not-award. Works only with linked logs (not main)
-- QDKP2log_UpdateLinkedDKPLog(name,Log,SID): Updates a linked DKP log entry (Raid aw, ZS). To be used when you modify a main DKP entry.

-- QDKP2log_GetModEntryText(Log,isRaid): Returns a human-readable description of Log. Trasparent to links.
-- QDKP2log_GetLastLogText(name): dummy of GetModEntryText, returns the description of the last log made for <Name>
-- QDKP2log_CheckLink(Log): Resolves Link,true if Log is a link, returns Log,false if not.

-- QDKP2log_GetData(Log)        : Unpacker for Log data.
-- QDKP2log_GetType(Log)        : Returns the type of LogEntry
-- QDKP2log_GetTS(Log)          : Returns the TimeStamp of Log
-- QDKP2log_GetModEntryDateTime(Log): Returns the date the log entry was created in standard QDKP form (Dummy)
-- QDKP2log_GetReason(Log)      : Returns the reason field of Log
-- QDKP2log_GetVersion(Log)     : Returns the Version of Log
-- QDKP2log_GetAmounts(Log)     : Returns the amounts in the log (if any) in this form: awards,spends,hours,coefficent,nominalAward
-- QDKP2log_GetChange(LogEntry) : Returns the net DKP change subtended by LogEntry.
-- QDKP2log_GetFlags(Log)       : Retruns the flag of Log, if any
-- QDKP2log_GetCreator(Log,SID) : Returns the name of the log creator
-- QDKP2log_GetModder(Log, SID) : Retruns the name of the last log modder.

-- QDKP2log_GetStr(LogEntry); Coverts the Log in a string.
-- QDKP2log_GetLogFromStr(LogEntry); convers a string made with QDKP2log_GetStr back to a log.

-- QDKP2log_BackupSave(session,name,Log): Called before modifying a DKP entry, stores a copy to revert back if needed.
-- QDKP2log_BackupDelete(session,name,Log): Deletes the log backup with the given coordinates (if any)
-- QDKP2log_getBackup(SID,name,Log); returns true if the log has been modified and not yet uploaded.
-- QDKP2log_BackupRevert(SID,name,Log); takes the backup copy (if any) and overwrite the given coordinates with it, reverting to last save.
-- QDKP2log_getBackupList(): Returns a list of the currently saved Backup entries in this format: {{SID1,Log1},{SID2,Log2},...}


----------------------QDKP2log_Entry----------------------
--[[Adds to the Log an entry
  Usage QDKP2log_Entry(name, action, type, [undo], [timestamp], flags, outsideSession)
    name: string, the name of the player to loc. Can be "RAID" for raid log
    action: string, the action that has to ble logged
    type: an identifier of the log entry. can be QDKP2LOG_EVENT, QDKP2LOG_CRITICAL,... (look at the beginning of the file)
    undo: a table with this structure: {[1]=x, [2]=y, [3]=z}. used to undo that command (on click)}
          x= total increase, y= spent increase and z=hours increase
    timestamp: tells the program the time to use
    flags: used to store additional numbers/bits for advanced entries like linked awards. Should not be referenced when used as API
    outsideSession: Records the entry in the general session regardless os the ongoing session.

    returns the session SID in which the entry was stored. nil if aborted.
]]--

function QDKP2log_Entry(name, action, Type, undo, timestamp, flags, outsideSession)

  QDKP2_Debug(2,"Logging","QDKP2log_Entry called. N:"..tostring(name).." ACT:"..tostring(action).." T:"..tostring(Type).." U:"..tostring(undo).." Tm:"..tostring(timestamp))

  if not QDKP2_OfficerMode() and not (Type==QDKP2LOG_EXTERNAL) then
		QDKP2_Debug(1,"Logging","Trying to create a log entry, but you aren't in officer mode!")
--    QDKP2_Msg(QDKP2_LOC_NoRights)
    return
  end

  if name=="RAID" and not QDKP2_IsManagingSession() then
    QDKP2_Debug(1,"Logging","Trying to create a RAID entry while no sessions are active!")
    return
  end

	name=QDKP2_GetMain(name)
  local SessPlayer=(QDKP2log[QDKP2_OngoingSession()] or {})[name] --this will be nil if player didn't took part in the session
  if (name=='RAID' or QDKP2_IsSessionRelated(Type) or SessPlayer or QDKP2_IsInRaid(name)) and not outsideSession then
    SID = QDKP2_OngoingSession()
  else
    SID='0'
  end
  SessionLog=QDKP2log[SID]

  if SID=='0' and QDKP2_IsSessionRelated(Type) then
    QDKP2_Debug(1,"Logging", "Trying to make a log entry that is related to a Session, but the session to write into is the <0>. ACT="..tostring(action))
    return
  end

  if not SessionLog then
    QDKP2_Debug(1,"Logging","OngoingSession index of QDKP2log is nil?!?! (SID: "..tostring(SID)..")")
    return
  end

  if not SessionLog[name] then
    QDKP2_Debug(3,"Logging","Initializing the session for the given player")
    SessionLog[name] = {}
  end
  local net
  PlayersLog=SessionLog[name]

  timestamp = timestamp or QDKP2_Timestamp()

  local version
  if QDKP2_IsVersionedEntry(Type) then
    version=0
  end

  local tempEntry
  if SID=="0" then
    --             type     timest.    spam     Vrs   amounts mod  date  flags      creator            Sign
    tempEntry = {Type, timestamp, action, version, undo,  nil, nil , flags, QDKP2_PLAYER_NAME_12}
  else
    tempEntry = {Type, timestamp, action, version, undo,  nil, nil , flags}
  end

  --Defining empty log backup so the revert will delete the entry.
  if Type==QDKP2LOG_MODIFY then QDKP2log_BackupSave(SID,name,tempEntry,true); end

  local LogSize = table.getn(PlayersLog) and QDKP2_LOG_MAXSIZE
  --add the entry at the top of the log
  local tempLog={tempEntry}
  local MaxSize=QDKP2_LOG_MAXSIZE
  if name=="RAID" then MaxSize=QDKP2_LOG_RAIDMAXSIZE;end
  MaxSize=MaxSize-1
  if LogSize > MaxSize then LogSize = MaxSize;end  --pop the last entries if i'm at the maximum log's length
  for buildLog=1, LogSize do table.insert(tempLog, PlayersLog[buildLog]); end

  SessionLog[name] = tempLog
  QDKP2_Debug(3,"Logging","Log entry successful created")

  return SID
end

--two dummies for QDKP2log_Entry

function QDKP2log_Event(name,event)
  --this creates a generic log entry.
  QDKP2log_Entry(name,event,QDKP2LOG_EVENT)
end

function QDKP2log_Link(name, nametolink, timestamp, session)
  --a link to a log entry.
  session = session or QDKP2_OngoingSession()
  QDKP2_Debug(2,"Logging","Creating a log link from "..name.." to "..nametolink.." in session "..session)
  if not timestamp then
    QDKP2_Debug(1,"Logging","Trying to create a log link without providing the timestamp!")
    return
  end
  if not nametolink then
    QDKP2_Debug(1,"Logging","Trying to create a log link without providing the linked player!")
    return
  end
  local out=session
  if QDKP2_IsAlt(nametolink) then
    out=out.."|"..QDKP2_GetMain(nametolink)
  end
  out=out.."|"..nametolink
  QDKP2log_Entry(name, out, QDKP2LOG_LINK, nil, timestamp)
  return out
end


---------------------- Revert Mirrors (Backups) ------------------------------------


function QDKP2log_BackupSave(SID,name,Log,deleteIt)
-- Saves a log entry, so you can revert it to this state. Used before editing a DKP log entry.
-- return true if succeeds.
  QDKP2logEntries_BackMod[name]=QDKP2logEntries_BackMod[name] or {}
  local playerBackups=QDKP2logEntries_BackMod[name]
  local ts=tostring(Log[QDKP2LOG_FIELD_TIME])
  local key=SID.."|"..ts
  if not playerBackups[key] then  --if not nil then i already have the original saved.
    QDKP2_Debug(3,"Logging","Saving "..key.." for "..name.." before modifying it...")
    local Undo=Log[QDKP2LOG_FIELD_AMOUNTS]
    local backupLog=QDKP2_CopyTable(Log)
    if Undo then backupLog[QDKP2LOG_FIELD_AMOUNTS]=QDKP2_CopyTable(Undo); end
    if deleteIt then backupLog[QDKP2LOG_FIELD_TYPE]=nil; end
    playerBackups[key]=backupLog
    return true
  else
    QDKP2_Debug(3,"Logging","I'm not saving "..key.." for "..name.."because there is already a backup.")
  end
end

function QDKP2log_BackupDel(SID,name,Log)
  local playerBackups=QDKP2logEntries_BackMod[name]
  if not playerBackups then return; end
  local ts=tostring(Log[QDKP2LOG_FIELD_TIME])
  local key=SID.."|"..ts
  if playerBackups[key] then
    playerBackups[key]=nil
    return true
  end
end

function QDKP2log_getBackup(SID,name,Log)
  local playerBackups=QDKP2logEntries_BackMod[name]
  if not playerBackups then return; end
  if not QDKP2_IsInGuild(name) then
    QDKP2log_BackupDel(SID,name,Log)
    return
  end
  local ts=tostring(Log[QDKP2LOG_FIELD_TIME])
  local key=SID.."|"..ts
  return playerBackups[key]
end

function QDKP2log_BackupRevert(SID,name,Log)
-- reverts a modified entry back to its original conditions. returns true if succeeds.
  QDKP2_Debug(2,"Logging","Reverting log entry "..SID..":"..tostring(Log).." in "..name.."'s log")
  local Backup=QDKP2log_getBackup(SID,name,Log)
  if not Backup then
    QDKP2_Debug(1,"Logging","Trying to revert a Log Entry that does not have a Backup.")
    return
  end
  if not QDKP2_IsInGuild(name) then
    QDKP2_Debug(1,"Logging","Trying to revert a Log Entry of a player that is not in guild. removing.")
    QDKP2log_BackupDel(SID,name,Log)
    return
  end
  local ts=Log[QDKP2LOG_FIELD_TIME]
  local List=QDKP2log_GetPlayer(SID,name)
  if not List then
    QDKP2_Debug(1,"Logging","Trying to revert a log with an invalid SID/name code")
    return
  end
  local index=QDKP2log_FindIndex(List,ts)
  if not index then
    QDKP2_Debug(1,"Logging","Trying to revert an Inexisting log entry!")
    return
  end
  if Backup[QDKP2LOG_FIELD_TYPE] then
    List[index]=Backup
  else
    table.remove(List,index)
  end
  local key=SID.."|"..tostring(ts)
  QDKP2logEntries_BackMod[name][key]=nil
  return true
end

function QDKP2log_getBackupList(name)
-- returns a list of coordinates of logs with backups, in this way: {{sid1,log1},{sid2,log2},...}
-- it also cleans the BackModlist from entries that are avilable no more.
  local playerBackups=QDKP2logEntries_BackMod[name]
  if not playerBackups then return {}; end
  local out={}
  table.foreach(playerBackups, function(key,Backup)
    local _,_,SID,ts=string.find(key,"([^,]*)|([^,]*)")
    ts=tonumber(ts)
    if not ts or not SID then return; end
    local Log
    local SessList=QDKP2log[SID]
    if SessList then
      local LogList=SessList[name]
      if LogList then
        Log=QDKP2log_Find(SessList[name],ts)
      end
    end
    if Log then
      table.insert(out,{SID,Log})
    else
      QDKP2_Msg(2,"Logging","Removing "..key.." from "..name.."'s log backups because can't find corresponding log.")
      playerBackups[key]=nil --backup does not have a corresponding log. delete it.
    end
  end)
  return out
end

----------------------LOG ENTRY FUNCTIONS------------------------------------
--- Readers

-- QDKP2log_GetModEntryText(Log,isRaid)
-- Returns the log's human-readable description.
--also used as integrity check, will return text,broken on corrupted entry. text is a description of the error, and broken wll be true.
-- Log is the source of the description, Raid must be set to true if is in the raid log.

function QDKP2log_GetModEntryText(Log,isRaid)
  if not Log then return "NULL Entry"; end
  local LinkedName, AltLinkedName
  local Type=QDKP2log_GetType(Log)
  local Bit0,Bit1,Bit2,Bit3,Var1,Var2=QDKP2log_GetFlags(Log)
  local RaidAw,ZeroSum,MainEntry=Bit0,Bit1,Bit2 --for easier reading
  local output = ""
  local DataLog=Log

  if Type==QDKP2LOG_LINK or (ZeroSum and not MainEntry) then
    Log,LinkedName,AltLinkedName=QDKP2log_FindLink(Log)
    if QDKP2_IsInvalidEntry(Type) then return Log[QDKP2LOG_FIELD_ACTION]; end
    if not ZeroSum or MainEntry then
      LinkedName=LinkedName or '*'..UNKNOWN..'*'
      if AltLinkedName then output=output..AltLinkedName.." ("..LinkedName..") "
      else output=output..LinkedName.." "
      end
      DataLog=Log
      Bit0,Bit1,Bit2,Bit3,Var1,Var2=QDKP2log_GetFlags(Log)
      RaidAw,ZeroSum,MainEntry=Bit0,Bit1,Bit2
      Type = QDKP2log_GetType(Log)
    end
  end
  local reason = Log[QDKP2LOG_FIELD_ACTION]

  if Type==QDKP2LOG_SESSION then
    local SessList,SessName=QDKP2_GetSessionInfo(reason)
    SessName=SessName or '<'..UNKNOWN ..'>'
    if isRaid then
      output=output .. QDKP2_LOC_Session .. " $SESSION"
    else
      output=output .. QDKP2_LOC_SessJoin
    end
    output=string.gsub(output,"$SESSION",SessName)

  elseif QDKP2_IsDKPEntry(Type) then
    local gained,spent,hours,Mod,Ngained=QDKP2log_GetAmounts(DataLog)

    if (not Ngained and not spent and not hours) then
      if (RaidAw or ZeroSum) and not MainEntry then
        Ngained=0
      else
        Ngained=0
        spent=0
      end
    end

    if Type==QDKP2LOG_EXTERNAL then
      output=output .. QDKP2_LOC_ExtMod
    elseif reason then
      if RaidAw and not MainEntry then
        output=output .. QDKP2_LOC_RaidAwReas
      elseif RaidAw then
        output=output .. QDKP2_LOC_RaidAwMainReas
      elseif ZeroSum and not MainEntry then
        output = output .. QDKP2_LOC_ZeroSumAwReas
      elseif ZeroSum then
        output = output .. QDKP2_LOC_ZeroSumSpReas
      elseif spent and not gained and not hours and GetItemIcon(reason) then --i use getitemicon to tell if reason is a valid item name/link
        output= output .. QDKP2_LOC_DKPPurchase
        output=string.gsub(output,"$ITEM",reason)
        output=string.gsub(output,"$AMOUNT",spent)
        return output
      else
        output= output .. QDKP2_LOC_GenericReas
      end
      output=string.gsub(output,"$REASON",tostring(reason))
    else
      if RaidAw and not MainEntry then
        output=output .. QDKP2_LOC_RaidAw
      elseif RaidAw then
        output=output .. QDKP2_LOC_RaidAwMain
      elseif ZeroSum and not MainEntry then
        output = output .. QDKP2_LOC_ZeroSumAw
      elseif ZeroSum then
        output = output .. QDKP2_LOC_ZeroSumSp
      else
        output = output .. QDKP2_LOC_Generic
      end
    end
    if ZeroSum then
      local giver=""
      if AltLinkedName then giver=AltLinkedName.." ("..LinkedName..")"
      elseif LinkedName then giver=LinkedName
      end
      output=string.gsub(output,"$GIVER",giver)
      gained=tostring(Ngained)
      if Mod and Mod ~= 100 then
        gained=gained.."x"..tostring(Mod).."%%"
      end
      output=string.gsub(output,"$AMOUNT",gained)
      output=string.gsub(output,"$SPENT",tostring(spent))
    end

    local AwardSpendText=QDKP2_GetAwardSpendText(Ngained, spent, hours,Mod)
    output=string.gsub(output,"$AWARDSPENDTEXT",AwardSpendText)

  elseif Type==QDKP2LOG_LOOT then
    if Bit0 then
      output=output .. QDKP2_LOC_ShardsItem
    else
      output=output .. QDKP2_LOC_LootsItem
    end
    local itemName,itemLink=GetItemInfo(reason or '')
    local text=itemLink or ''
    if Var1>1 then text=text.."x"..tostring(Var1); end
    output=string.gsub(output,"$ITEM",text)

  elseif Type==QDKP2LOG_BOSS then
    output=QDKP2_LOC_BossKill
    output=string.gsub(output,"$BOSS",tostring(reason))

  elseif QDKP2_IsNODKPEntry(Type) then

    local gained, spent, hours, Mod, Ngained = QDKP2log_GetAmounts(DataLog)

    if Var1==QDKP2LOG_NODKP_MANUAL then
      whynot=QDKP2_LOC_NODKP_Manual
    elseif Var1==QDKP2LOG_NODKP_OFFLINE then
      whynot = QDKP2_LOC_NODKP_Offline
    elseif Var1==QDKP2LOG_NODKP_RANK then
      whynot = QDKP2_LOC_NODKP_Rank
    elseif Var1==QDKP2LOG_NODKP_ZONE then
      whynot = QDKP2_LOC_NODKP_Zone
    elseif Var1==QDKP2LOG_NODKP_LOWRAID then
      whynot = QDKP2_LOC_NODKP_LowAtt
      whynot=string.gsub(whynot,"$PERC",tostring(Var2 or "??"))
    elseif Var1==QDKP2LOG_NODKP_LIMIT then
      whynot= QDKP2_LOC_NODKP_NetLimit
    elseif Var1==QDKP2LOG_NODKP_IMSTART then
      whynot= QDKP2_LOC_NODKP_IMStart
    elseif Var1==QDKP2LOG_NODKP_IMSTOP then
      whynot= QDKP2_LOC_NODKP_IMStop
    else
      whynot= QDKP2_LOC_NODKP_Generic
    end
    if gained then
      if reason then
        if RaidAw and not MainEntry then
          output = output .. QDKP2_LOC_NoDKPRaidReas
        else
          output = output .. QDKP2_LOC_NoDKPZSReas
        end
        output = string.gsub(output,"$REASON",reason)
      else
        if RaidAw and not MainEntry then
          output = output .. QDKP2_LOC_NoDKPRaid
        else
        output = output .. QDKP2_LOC_NoDKPZS
        end
      end
      local gainTxt=tostring(Ngained)
      if Mod and Mod ~= 100 then gainTxt=gainTxt.."x"..tostring(Mod).."%%"; end
      output = string.gsub(output,"$AMOUNT",gainTxt)
    elseif hours then
      output = output .. QDKP2_LOC_NoTick
    end

    if ZeroSum then
      local giver=""
      if AltLinkedName then giver=AltLinkedName.." ("..LinkedName..")"
      elseif LinkedName then giver=LinkedName
      end
      output=string.gsub(output,"$GIVER",giver)
    end

    output = string.gsub(output,"$WHYNOT",whynot)

  else
    output = output..reason
  end
  if not output or string.len(output)==0 then output="<NIL>"; end
  return output
end

--dummy of GetModEntryText,
--Returns the description of the last log entry of name.
--session is optional.
function QDKP2log_GetLastLogText(name,session)
  local Log=QDKP2log_GetLastLog(name,session)
  return QDKP2log_GetModEntryText(Log,name=='RAID')
end


local LogColors={}
LogColors.Default={r=1,g=1,b=1}
LogColors.NegativeDKP={r=1,g=0.3,b=0.3}
LogColors.PositiveDKP={r=0,g=1,b=0}
LogColors.LostDKP={r=0.6,g=0.6,b=0.6}
LogColors[QDKP2LOG_EVENT]={r=1,g=1,b=1}
LogColors[QDKP2LOG_CONFIRMED]={r=0.3,g=1,b=0.3}
LogColors[QDKP2LOG_CRITICAL]={r=1,g=0.3,b=0.3}
LogColors[QDKP2LOG_MODIFY]={r=0.4,g=1,b=1}
LogColors[QDKP2LOG_JOINED]={r=1,g=0.6,b=0}
LogColors[QDKP2LOG_LEFT]={r=1,g=0.6,b=0}
LogColors[QDKP2LOG_LOOT]={r=1,g=1,b=0}
LogColors[QDKP2LOG_ABORTED]={r=0.6,g=0.6,b=0.6}
LogColors[QDKP2LOG_NODKP]={r=1,g=0.5,b=0.5}
LogColors[QDKP2LOG_BOSS]={r=1,g=1,b=1}
LogColors[QDKP2LOG_BIDDING]={r=1,g=0.3,b=1}
LogColors[QDKP2LOG_SESSION]={r=1,g=1,b=0.5}
LogColors[QDKP2LOG_INVALID]={r=1,g=1,b=1}
LogColors[QDKP2LOG_EXTERNAL]={r=1,g=1,b=1}

function QDKP2log_GetEntryColor(type)
	return (LogColors[type] or LogColors.Default)
end
---------------------------------- Low level Retrivers ---------------------------------------------

function QDKP2log_GetData(Log)
-- retruns all the raw data contained in a log
-- Type,Time,Action,Version,Amounts,ModBy,ModDate,Flags,Creator = QDKP2log_GetData(Log)
  return Log[1],Log[2],Log[3],Log[4],Log[5],Log[6],Log[7],Log[8],Log[9]
end

--Returns the type of the log
function QDKP2log_GetType(Log)
  return Log[QDKP2LOG_FIELD_TYPE] or QDKP2LOG_INVALID
end

function QDKP2log_GetTS(Log)          -- returns the TimeStamp of Log
-- Returns the TimeStamp of log (returns 0 if is nil. raise an error if Log is nil.)
  return Log[QDKP2LOG_FIELD_TIME] or 0
end
function QDKP2log_GetModEntryDateTime(Log)
--returns the date and time for the log voice passed
  return QDKP2_GetDateTextFromTS(QDKP2log_GetTS(Log))
end

function QDKP2log_GetReason(Log)
--REturns the reason field of Log
  return Log[QDKP2LOG_FIELD_ACTION]
end

function QDKP2log_GetAmounts(Log)
--Returns the amounts in the log
--gain,spend,hours,Coeff,Ngain = QDKP2log_GetAmounts(log)
--where gain is the effective gained amount modified by Mod, and
--Ngain is the nominal amount.
 local Undo = Log[QDKP2LOG_FIELD_AMOUNTS]
 if not Undo or type(Undo)~="table" then
   QDKP2_Debug(1,"Logging","Asking the amounts for a log entry withouth Undo field!")
   return
  end
 --print("{"..tostring(Undo[1])..","..tostring(Undo[2])..","..tostring(Undo[3])..","..tostring(Undo[4]).."}")
 local Ngain=Undo[1]
 local spend=Undo[2]
 local hours=Undo[3]
 local Coeff=Undo[4]
 local gain
 if Ngain then gain = RoundNum(Ngain * (Coeff or 100)/100); end
 return gain,spend,hours,Coeff,Ngain
end

--returns the net change of given log entry.
function QDKP2log_GetChange(LogEntry)
    LogEntry,link=QDKP2log_CheckLink(LogEntry)
    local Type=LogEntry[QDKP2LOG_FIELD_TYPE]
    if not QDKP2_IsActiveDKPEntry(Type) then return; end
    local Total,Spent=QDKP2log_GetAmounts(LogEntry)
    return (Total or 0)-(Spent or 0)
end

function QDKP2log_GetFlags(Log)
--Extracts the flags from the number in QDKP2LOG_FIELD_FLAGS. Extracts up to 4 bits and 2 bytes.
  if not Log then return; end
  local Data=Log[QDKP2LOG_FIELD_FLAGS] or 0
  Data=math.floor(Data)
  local Bit0,Bit1,Bit2,Bit3,Var1,Var2
  Bit0 = bit.band(Data,0x00001);
  Bit1 = bit.band(Data,0x00002);
  Bit2 = bit.band(Data,0x00004);
  Bit3 = bit.band(Data,0x00008);
  Var1 = bit.band(Data,0x00FF0);
  Var2 = bit.band(Data,0xFF000);
  if Bit0==0 then Bit0=false; end
  if Bit1==0 then Bit1=false; end
  if Bit2==0 then Bit2=false; end
  if Bit3==0 then Bit3=false; end
  return Bit0,Bit1,Bit2,Bit3,bit.rshift(Var1,4),bit.rshift(Var2,12)
end

function QDKP2log_GetCreator(Log,SID)
--returns the name of the creator of the log. Needs SID
--Returns the name of the last editor of the log. Needs SID.
  local name=Log[QDKP2LOG_FIELD_CREATOR]
  if name then return name; end
  local _,_,name = QDKP2_GetSessionInfo(SID)
  return name
end

function QDKP2log_GetModder(Log, SID)
--Returns the name of the last editor of the log. Needs SID.
  local name=Log[QDKP2LOG_FIELD_MODBY] or QDKP2log_GetCreator(Log,SID)
  return name
end

function QDKP2log_GetModDate(Log,SID)
  return Log[QDKP2LOG_FIELD_MODDATE]
end


------------- Modificators

function QDKP2log_UnDoEntry(name,Log,SID,onofftog)

-- Given a log entry, toggle between ACTIVE and INACTIVE and manages the DKPs.
-- It manages linked entries (raid awards, zerosums) activating/deactivating them too.
-- QDKP2log_UnDoEntry(name,Log,SID,onofftog)
-- name: The name of the player that owns the log.
-- Log: The log entry to activate/deactivate
-- onofftog: Optionals, can be "on" and "off". If nil will cause a toggle.

  QDKP2_Debug(2,"Logging","UnDoEntry Called for "..tostring(name)..". Log="..tostring(Log)..", SID="..SID..", onoff="..tostring(onofftog))

  local LogType = Log[QDKP2LOG_FIELD_TYPE]

  if onofftog=="on" and LogType~=QDKP2LOG_ABORTED then return
  elseif onofftog=="off" and LogType==QDKP2LOG_ABORTED then return
  elseif LogType==QDKP2LOG_ABORTED then onofftog="on"
  else onofftog="off"
  end
  local RaidAw,ZeroSum,MainEntry,Bit3,Var1,Var2=QDKP2log_GetFlags(Log)
  if MainEntry then

  end

  local addsub
  if QDKP2_IsDKPEntry(LogType) then
    local DTotal, DSpent, DHours, DMod, NTotal = QDKP2log_GetAmounts(Log)
    DMod=(DMod or 100)/100

    local SetTotal = NTotal
    local SetSpent = DSpent
    local SetHours = DHours
    local DeltaDKP = 0

    if onofftog == "on" then addsub = 1
    elseif onofftog == "off" then addsub = -1
    end

    if DTotal then
      DTotal = DTotal * addsub
      DeltaDKP = DTotal
    else
      SetTotal=0
    end

    if DSpent then
      DSpent = DSpent * addsub
      DeltaDKP = DeltaDKP - DSpent
    else
      SetSpent=0
    end

    if DHours then
      DHours = DHours *addsub
    else
      SetHours=0
    end

    local ChDeltaDKP=DeltaDKP
    if name~="RAID"  then
      local maxNet=QDKP2_GetNet(name)
      local minNet=QDKP2_GetNet(name)
      if maxNet+DeltaDKP>QDKP2_MAXIMUM_NET then
        QDKP2_Debug(2,"Logging","Limiting the gain because it would break the max Net limit")
        SetTotal=RoundNum((SetTotal-(maxNet+DeltaDKP-QDKP2_MAXIMUM_NET)/DMod))
        DTotal=RoundNum(SetTotal * DMod * addsub)
        DeltaDKP=QDKP2_MAXIMUM_NET - maxNet
      end
      if minNet+DeltaDKP<QDKP2_MINIMUM_NET then
        QDKP2_Debug(2,"Logging","Limiting the loss because it would break the min Net limit")
        SetSpent = SetSpent + (minNet+DeltaDKP-QDKP2_MINIMUM_NET)
        DSpent=SetSpent * addsub
        DeltaDKP=QDKP2_MINIMUM_NET-minNet
      end
    end
    ChDeltaDKP= ChDeltaDKP-DeltaDKP

    QDKP2log_BackupSave(SID,name,Log)

    -- Modifying the log entry --
    if name ~="RAID" then
      if SetTotal==0 then SetTotal=nil; end
      if SetSpent==0 then SetSpent=nil; end
      if SetHours==0 then SetHours=nil; end
      QDKP2log_SetAmountsField(Log, {SetTotal,SetSpent,SetHours})
      local newChange=0
      QDKP2_AddTotals(name, DTotal, DSpent, DHours, nil, nil, nil, true)
    end

    local newType
    if addsub==1 then
      newType = QDKP2LOG_MODIFY
    else
      newType = QDKP2LOG_ABORTED
    end
    QDKP2log_SetTypeField(Log, newType)

    local RaidAw,ZeroSum,MainEntry=QDKP2log_GetFlags(Log)
    if MainEntry then --update linked dkp entries
      QDKP2log_UpdateLinkedDKPLog(name,Log,SID)
    end

    QDKP2_Debug(3,"Logging","UnDo Entry finished for "..name)
  end
end


function QDKP2log_SetEntry(name,Log,SID,newGained,newSpent,newHours,newCoeff,newReason, Activate, NoIncreaseVersion)

-- Function to change a DKP entry's amounts.
-- It will take care of any linked entry (raid awards, zerosums,...)
-- QDKP2log_SetLogEntry(name,Log,newGained,newSpent,newHours,newMod,newReason, Activate, NoProcessZs)
-- name: The name of the player that owns the log
-- Log: The log to modify.
-- SID: The SID of the session the entry is.
-- newGained,newSpent,newHours, newReason, newMod: Guess wha! If nil, they won't be changed.

  QDKP2_Debug(2,"Logging","SetEntry called for "..tostring(name)..", log "..tostring(Log).." of session "..tostring(SID)..". NewUndo: "..tostring(newGained)..","..tostring(newSpent)..","..tostring(newHours)..","..tostring(newCoeff))
  if not name then
    QDKP2_Debug(1,"Logging","Calling SetEntry with nil name")
    return
  elseif not Log then
    QDKP2_Debug(1,"Logging","Calling SetEntry with nil Log")
    return
  end
  if not SID then
    QDKP2_Debug(1,"Logging","SetEntry called with nil SID")
    return
  end
  local SessList,SessName,SessMantainer=QDKP2_GetSessionInfo(SID)

  local LogType = QDKP2log_GetType(Log)

  name=QDKP2_GetMain(name)

  local oldGained
  local oldSpent
  local oldHours
  local oldMod
  local oldCoeff,oldNGained
  oldGained, oldSpent, oldHours, oldCoeff, oldNGained = QDKP2log_GetAmounts(Log)

  oldGained=oldGained or 0
  oldSpent=oldSpent or 0
  oldHours=oldHours or 0
  oldNGained=oldNGained or 0
  oldCoeff=oldCoeff or 100

  if QDKP2_IsNODKPEntry(LogType) then
    oldGained=0
    oldSpent=0
    oldHours=0
    oldNGained=0
  end

  local Dnet = 0

  local newNGained

  newNGained = tonumber(newGained or oldNGained) or oldNGained
  newSpent = tonumber(newSpent or oldSpent) or oldSpent
  newHours = tonumber(newHours or oldHours) or oldHours
  newCoeff = tonumber(newCoeff or oldCoeff) or oldCoeff
  newCoeff100 = newCoeff/100
  newGained = RoundNum(newNGained * newCoeff100)

  Dnet = newGained - newSpent

  if name~="RAID" and QDKP2_IsDKPEntry(LogType) then
    local maxNet=QDKP2_GetNet(name)
    local minNet=QDKP2_GetNet(name)
    --[[
    for i=index,1,-1 do
      local tmpNet = QDKP2log[name][i][QDKP2LOG_NET]
      if tmpNet and tmpNet<minNet then minNet=tmpNet; end
      if tmpNet and tmpNet>maxNet then maxNet=tmpNet; end
    end
    ]]-- Disabled. It serachs the maximum and minum net amounts in log history's. Bad for sync.
    if maxNet+Dnet>QDKP2_MAXIMUM_NET then
      QDKP2_Debug(2,"Logging","Limiting the change because it would break the maximum net DKP amount")
      newNGained=RoundNum((newNGained-(maxNet+Dnet-QDKP2_MAXIMUM_NET)/newCoeff100))
      newGained=newNGained * newCoeff100
      Dnet=QDKP2_MAXIMUM_NET-maxNet
    end
    if minNet+Dnet<QDKP2_MINIMUM_NET then
      QDKP2_Debug(2,"Logging","Limiting the change because it would break the minimum net DKP amount")
      newSpent=newSpent+((minNet+Dnet)-QDKP2_MINIMUM_NET)
      Dnet=QDKP2_MINIMUM_NET-minNet
    end
  end

  local Dgained = newGained - oldGained
  local Dspent = newSpent - oldSpent
  local Dhours = newHours - oldHours

  if (Activate or not QDKP2_IsDeletedEntry(LogType)) and QDKP2_IsDKPEntry(LogType) and name ~= "RAID" then
    QDKP2_AddTotals(name, Dgained, Dspent, Dhours, nil, nil, nil, true)
  end

  if not NoIncreaseVersion and LogType~=QDKP2LOG_MODIFY then
    QDKP2log_BackupSave(SID,name,Log)
  elseif NoIncreaseVersion and LogType==QDKP2LOG_MODIFY then
    QDKP2_Msg(3,"Logging","Updating log's backup to match new initial values.")
    QDKP2log_BackupDel(SID,name,Log)
    QDKP2log_BackupSave(SID,name,Log,true)
  end

  if Dgained ~= 0 or Dspent ~= 0 or math.abs(Dhours)>0.09 then
    if LogType == QDKP2LOG_CONFIRMED or Activate then
      QDKP2log_SetTypeField(Log,QDKP2LOG_MODIFY,NoIncreaseVersion)
    end
  end

  if newReason and (not ZeroSum or MainEntry) then
    if newReason=="" then newReason=nil; end
    QDKP2log_SetReasonField(Log, newReason, NoIncreaseVersion)
  end

  QDKP2log_SetAmountsField(Log,{newNGained,newSpent,newHours,newCoeff},NoIncreaseVersion)

    --this is to fix those log entries with a redundant MODBY name.
  if Log[QDKP2LOG_FIELD_MODBY]==SessMantainer then
    Log[QDKP2LOG_FIELD_MODBY]=nil
  end

  local RaidAw,ZeroSum,MainEntry=QDKP2log_GetFlags(Log)
  if MainEntry and not NoProcessZs then  --update linked dkp entries
    QDKP2log_UpdateLinkedDKPLog(name,Log,SID,NoIncreaseVersion)
  end

  QDKP2_Debug(3,"Logging","SetEntry successfully finished for "..name)
end


function QDKP2log_AwardLinkedEntry(name,Log,SID,todo,ReasonCode)
--Sets a slave link DKP entry a award or a not-award.
--name, Log, SID: Self descripting
--todo: can be 'award', 'not-award' and 'toggle'
--ReasonCode: The reason code (optional). Won't be touched if nil
  todo=todo or 'toggle'
  local RaidAw,ZeroSum,MainEntry,B3,V0,V1=QDKP2log_GetFlags(Log)
  if (not ZeroSum and not RaidAw) or MainEntry then
    QDKP2_Debug(1,"Logging","AwardLinkedEntry called with a log that isn't a linked log entry")
    return
  end
  QDKP2log_BackupSave(SID,name,Log)
  local Type=QDKP2log_GetType(Log)
  if todo=='award' and QDKP2_IsNODKPEntry(Type) then
    QDKP2log_SetTypeField(Log, QDKP2LOG_ABORTED)
  elseif todo=='not-award' and not QDKP2_IsNODKPEntry(Type) then
    QDKP2log_UnDoEntry(name,Log,SID,'off')
    QDKP2log_SetTypeField(Log, QDKP2LOG_NODKP)
    if not V0 then ReasonCode=QDKP2LOG_NODKP_MANUAL; end --default reason for entries that are switched off (Manually removed)
    if ReasonCode then
      QDKP2log_SetFlags(Log,RaidAw,ZeroSum,MainEntry,B3,ReasonCode,V1)
    end
  elseif todo=='toggle' then
    if QDKP2_IsNODKPEntry(Type) then QDKP2log_AwardLinkedEntry(name,Log,SID,'award',ReasonCode)
    else QDKP2log_AwardLinkedEntry(name,Log,SID,'not-award',ReasonCode)
    end
  else
    QDKP2_Debug(1,"Logging","AwardLinkedEntry got an invalid todo.")
    return
  end
  local vLog,vSID,vPlayer=QDKP2log_GetMainDKPEntry(Log,SID)
  QDKP2log_UpdateLinkedDKPLog(vPlayer, vLog, vSID)
end

--[[
function QDKP2log_ToggleAward(name,Log,SID,onofftog)
--Function that, given a slave DKP entry log, puts it from active to excluded state back and forth.

  if not name then
    QDKP2_Debug(1,"Log","Can't toggle award state: name is nil.")
    return
  elseif not Log then
    QDKP2_Debug(1,"Log","Can't toggle award state: Log is nil.")
    return
  end

  local _=QDKP2log_BackupSave(SID,name,Log) or QDKP2_Msg(1,"Logging","Couldn't update the log's backup.")
  local Type=QDKP2log_GetType(Log)
  local B0,B1,B2,B3,V0,V1=QDKP2log_GetFlags(Log)
  if QDKP2_IsNODKPEntry(Type) then
    QDKP2_Debug(2,"Log","Enabling Award for "..tostring(name)..", session="..tostring(SID))
    QDKP2log_SetTypeField(Log, QDKP2LOG_ABORTED)
  else
    QDKP2_Debug(2,"Log","Disabling Award for "..tostring(name)..", session="..tostring(SID))

  else
]]--


--This updates a linked DKP entry (Raid Award or Zerosum).
--MUST be called everytime you modify a main DKP entry.
function QDKP2log_UpdateLinkedDKPLog(name,Log,SID,NoIncreaseVersion)
  if not (type(name)=='string') then
    QDKP2_Debug(1,"Logging", 'UpdateLinkedDKPLog called with invalid name: '..tostring(name))
    return
  end
  if not (type(Log)=='table') then
    QDKP2_Debug(1,"Logging", 'UpdateLinkedDKPLog called with invalid log')
    return
  end
  if not (type(SID)=='string') then
    QDKP2_Debug(1,"Logging", 'UpdateLinkedDKPLog called with SID that is not a string')
    return
  end
  local LogType = Log[QDKP2LOG_FIELD_TYPE]
  if not QDKP2_IsDKPEntry(LogType) then
    QDKP2_Debug(1,"Logging","Calling UpdateLinkedDKPLog with a log that is not a main DKP entry.")
    return
  end

  local RaidAw,ZeroSum,MainEntry,Bit3,Var1,Var2=QDKP2log_GetFlags(Log)
  local newGained,newSpent,newHours=QDKP2log_GetAmounts(Log)
  local newReason=QDKP2log_GetReason(Log)
  local nameList, logList

  if RaidAw and MainEntry then
    --RaidAward entry
    QDKP2_Debug(3,"Logging","Given log is a raid award main entry. Propagating the change to all the child entries.")
    nameList, logList =QDKP2log_GetList(SID,Log[QDKP2LOG_FIELD_TIME])

    for i=1, #nameList do
      local name2=nameList[i]
      local log2 = logList[i]
      if not QDKP2_IsAlt(name2) and name2 ~= name then
        QDKP2log_SetEntry(name2,log2,SID,newGained or 0,newSpent or 0,newHours or 0,nil,newReason or '',nil,NoIncreaseVersion)
      end
    end
  elseif (ZeroSum and MainEntry) then
    --Zerosum entry
    QDKP2_Debug(3,"Logging","Given log is a zerosum main entry. Propagating the change to all the child entries.")
    QDKP2_ZeroSum_Update(name,Log,SID,NoIncreaseVersion)
  end

  --this updates the status, active or deactive
  if not nameList then
    nameList, logList =QDKP2log_GetList(SID,Log[QDKP2LOG_FIELD_TIME])
  end
  for i=1, #nameList do
    local name2=nameList[i]
    if not QDKP2_IsAlt(name2) and name2~=name then
      local log2 = logList[i]
      log2type=QDKP2log_GetType(log2)
      local todo
      if LogType == log2type then todo=nil --all ok
      elseif QDKP2_IsActiveDKPEntry(LogType) and not QDKP2_IsActiveDKPEntry(log2type) then todo='on'
      elseif not QDKP2_IsActiveDKPEntry(LogType) and QDKP2_IsActiveDKPEntry(log2type) then todo='off'
      end
      if todo then QDKP2log_UnDoEntry(name2,log2,SID,todo); end
    end
  end
  return true
end


--Change type
function QDKP2log_SetTypeField(Log, newValue, NoIncreaseVersion)
  local oldValue=Log[QDKP2LOG_FIELD_TYPE]
  if oldValue ~= newValue then
    Log[QDKP2LOG_FIELD_TYPE]=newValue or QDKP2LOG_INVALID
    if not NoIncreaseVersion then QDKP2log_LogEntryModified(Log); end
  end
end

--Change Reason
function QDKP2log_SetReasonField(Log, newValue, NoIncreaseVersion)
  local oldValue=Log[QDKP2LOG_FIELD_ACTION]
  if oldValue ~= newValue then
    Log[QDKP2LOG_FIELD_ACTION]=newValue
    if not NoIncreaseVersion then QDKP2log_LogEntryModified(Log); end
  end
end

--Change amounts
function QDKP2log_SetAmountsField(Log, newValue, NoIncreaseVersion)
  if not newValue or type(newValue)~="table" then
    QDKP2_Debug(1,"Logging","SetAmountsField called without a valid newValue")
    return
  end
  local oldValue=Log[QDKP2LOG_FIELD_AMOUNTS] or {}
  newValue={newValue[1] or oldValue[1],newValue[2] or oldValue[2],newValue[3] or oldValue[3],newValue[4] or oldValue[4]}
  if newValue[1]==0 then newValue[1]=nil; end
  if newValue[2]==0 then newValue[2]=nil; end
  if newValue[3]==0 then newValue[3]=nil; end
  if newValue[4]==100 then newValue[4]=nil; end
  Log[QDKP2LOG_FIELD_AMOUNTS]=newValue
  if not NoIncreaseVersion then QDKP2log_LogEntryModified(Log); end
end


--Change flags/Variables.
function QDKP2log_SetFlags(Log,B0,B1,B2,B3,V0,V1)
  local flags=QDKP2log_PacketFlags(B0,B1,B2,B3,V0,V1)
  Log[QDKP2LOG_FIELD_FLAGS]=flags
  QDKP2log_LogEntryModified(Log)
end

---------------Utilities-------------------------


function QDKP2log_GetStr(Log)
  local reason=Log[3]
  local undo=Log[5]
  local flags=Log[8]
  if flags then flags=string.format("%X",flags)
  else flags=''
  end
  if undo then
    undo=tostring(undo[1])..","..tostring(undo[2])..","..tostring(undo[3])
    undo=string.gsub(undo,'nil','')
  else undo=''
  end
  if reason then reason=string.gsub(reason,"§","S")
  else reason=''
  end
  local out=tostring(Log[1] or '')..'§'..
            tostring(Log[2] or '')..'§'..
            reason..'§'..
            tostring(Log[4] or '')..'§'..
            undo..'§'..
            tostring(Log[6] or '')..'§'..
            tostring(Log[7] or '')..'§'..
            flags..'§'..
            tostring(Log[9] or '')..'§'..
            tostring(Log[10] or '')
  return out
end

function QDKP2log_GetLogFromString(str)
  local _,_,Type,TS,Act,Ver,UndoS,ModBy,ModDate,Flags,Own,Sign=string.find(
  '([^§]*)§([^§]*)§([^§]*)§([^§]*)§([^§]*)§([^§]*)§([^§]*)§([^§]*)§([^§]*)§([^§]*)')
  Type=tonumber(Type) or QDKP2LOG_INVALID
  TS=tonumber(TS)
  Ver=tonumber(Ver)
  local undo,_={}
  _,_,undo[1],undo[2],undo[3]=string.find(UndoS,'([^,]*),([^,]*),([^,]*)')
  undo=table.foreach(undo,tonumber)
end



function QDKP2log_PacketFlags(Bit0,Bit1,Bit2,Bit3,Val1,Val2)
--Packets the flags into a single integer
  local out=0
  if Bit0 then out=out+1; end
  if Bit1 then out=out+2; end
  if Bit2 then out=out+4; end
  if Bit3 then out=out+8; end
  if Val1 then
    Val1=math.floor(Val1)
    if Val1<0 then Val1=0
    elseif Val1>255 then Val1=255
    end
    out=out+Val1*16
  end
  if Val2 then
    Val2=math.floor(Val2)
    if Val2<0 then Val2=0
    elseif Val2>255 then Val2=255
    end
    out=out+Val2*4096
  end
  return out
end

function QDKP2log_CheckLink(Log)
-- Returns the linked log if is a link, and the log itself if not.
-- As second output returns true if the log is a link, false if is not.
  if QDKP2log_GetType(Log)==QDKP2LOG_LINK then
    return QDKP2log_FindLink(Log), true
  else
    return Log, false
  end
end

--Updates the modification timer and name.
function QDKP2log_LogEntryModified(Log)
  QDKP2_Debug(2,"Logging","Increasing mod version of log "..tostring(Log))
  local Version=Log[QDKP2LOG_FIELD_VERSION]
  if not Version then
    QDKP2_Debug(1,"Logging","You can't increase the version of a not-versioned entry!")
    return
  end
  Log[QDKP2LOG_FIELD_MODDATE]=QDKP2_Time()
  Log[QDKP2LOG_FIELD_VERSION]=Version + 1
  Log[QDKP2LOG_FIELD_SIGN]=nil
  if Log[QDKP2LOG_FIELD_CREATOR]==QDKP2_PLAYER_NAME_12 then
    Log[QDKP2LOG_FIELD_MODBY]=nil
  else
    Log[QDKP2LOG_FIELD_MODBY]=QDKP2_PLAYER_NAME_12
  end
end


function QDKP2_ZeroSum_Update(giverName,mainLog,SID,NoIncreaseVersion)
--This is called when the zerosum main entry is changed.
  QDKP2_Debug(2, "RaidAward", "Updating Zerosum entry "..tostring(mainLog).." by "..tostring(giverName).." in session "..tostring(SID))
  if not giverName then
    QDKP2_Debug(1, "RaidAward", "Calling Update_Zerosum with nil giverName")
    return
  end
  if not mainLog then
    QDKP2_Debug(1, "RaidAward", "Calling Update_Zerosum with nil mainLog")
    return
  end
  if not SID then
    QDKP2_Debug(1,"RaidAward", "Calling Update_Zerosum with nil SID")
    return
  end
  local SessionLog=QDKP2log[SID]
  local Amount=mainLog[QDKP2LOG_FIELD_AMOUNTS][2]
  local timeStamp=QDKP2log_GetTS(mainLog)
  QDKP2_Debug(3, "RaidAward", tostring(Amount).." DKP to share")
  local nameList, LogList = QDKP2log_GetIndexList(SID, timeStamp)
  local whoGet={}
  local whoGetLog={}
  local whoDontGet={}
  local whoDontGetLog={}
  for i=1,table.getn(nameList) do
    local Name=nameList[i]
    local NameLog=SessionLog[Name]
    if Name ~= "RAID" and (Name ~= giverName or QDKP_GIVEZSTOLOOTER) then
      local index=LogList[i]
      local Log=NameLog[index]
      local Type=QDKP2log_GetType(Log)
      if QDKP2_IsDKPEntry(Type) then
        table.insert(whoGet,Name)
        table.insert(whoGetLog,Log)
      else
        table.insert(whoDontGet,Name)
        table.insert(whoDontGetLog,Log)
      end
    end
  end
  local Sharer = table.getn(whoGet)
  if Sharer==0 then
    QDKP2_Msg(QDKP2_COLOR_YELLOW.."Warning: No players eligible for the share found. Shared DKP will be destroyed.")

  end
  QDKP2_Debug(3, "RaidAward", tostring(Sharer).." players are elegible for the share")

  if Sharer > 0 then
      --here i use a iterative system to get the value that best shares the given DKP amount.
    local Share = 0  --initial values
    local Total = 0
    local oldShare, oldTotal
    local iter=0
    while true do
      local iterPrec=Share
      if not oldShare then
        Share=RoundNum(Amount/Sharer)  --prima iterata
      elseif oldTotal==Total then --this is to avoid division by zero, but should never happen.
        --pass
      else
        local x1=Amount - oldTotal
        local x2=Amount - Total
        local y1=oldShare
        local y2=Share
        Share=RoundNum(((x2*y1)-(x1*y2))/(x2-x1)) --newton's iteration
      end
      QDKP2_Debug(3,"RaidAward","UpdateZS - It. #"..tostring(iter+1)..", Share="..tostring(Share))
      if (Share==oldShare or Total==oldTotal) and iter>0 then
        QDKP2_Debug(2,"RaidAward","UpdateZS - Found aprox root after "..tostring(iter+1).." it. : S="..tostring(Share))
        break
      elseif iter>=20 then
        QDKP2_Message("Zerosum Award: some DKP couldn't be shared. (giving "..tostring(oldTotal).." over "..tostring(Amount).." DKP.")
      end
      oldShare=iterPrec
      oldTotal=Total
      Total=0
      for i=1,Sharer do
        local Name=whoGet[i]
        local Log=whoGetLog[i]
        QDKP2_Debug(3,"RaidAward",Name.." gets the share.")
        QDKP2log_SetEntry(Name,Log,SID,Share,nil,nil,nil,nil,nil,NoIncreaseVersion4)
        local gain,spend=QDKP2log_GetAmounts(Log)
        Total=Total+(gain or 0)
      end
      if Total==Amount then
        QDKP2_Debug(2,"RaidAward","UpdateZS - Found precise root after"..tostring(iter+1).." it. :S="..tostring(Share))
        break
      end
      iter=iter+1
    end
  end

  local ToNoDKP=math.ceil(Amount/(Sharer+1))
  for i=1,table.getn(whoDontGet) do
    local Name=whoDontGet[i]
    local Log=whoDontGetLog[i]
    local Undo=Log[QDKP2LOG_FIELD_AMOUNTS]
    local Reason=Log[QDKP2LOG_FIELD_ACTION]
    QDKP2_Debug(3,"RaidAward",Name.." loses the share ("..tostring(ToNoDKP).." DKP)")
    QDKP2log_SetEntry(Name,Log,SID,ToNoDKP,nil,nil,nil,nil,nil,NoIncreaseVersion)
  end
end


function QDKP2_GetAwardSpendText(gained, spent, hours, Mod)
--Returns a "Gains x and Spends y" report.
  if gained then
    if spent then
      if hours then
        output=QDKP2_LOC_GainsSpendsEarns
      else
        output=QDKP2_LOC_GainsSpends
      end
    else
      if hours then
        output=QDKP2_LOC_GainsEarns
      else
        output=QDKP2_LOC_Gains
      end
    end
  else
    if spent then
      if hours then
        output=QDKP2_LOC_SpendsEarns
      else
        output=QDKP2_LOC_Spends
      end
    else
      if hours then
        output=QDKP2_LOC_Earns
      else
        output=""
      end
    end
  end

  if gained then
    gained=tostring(gained)
    if Mod and Mod ~= 100 then
      gained=gained.."x"..tostring(Mod).."%%%%"
    end
    output=string.gsub(output,"$GAIN",gained)
  end
  if spent then
    output=string.gsub(output,"$SPEND",spent)
  end
  if hours then
    output=string.gsub(output,"$HOUR",hours)
  end
  return output
end
