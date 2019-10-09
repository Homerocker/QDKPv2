-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## LOGGING SYSTEM ##
--              Database functions

-- API Documentation
-- QDKP2log_GetSession(SID)
-- QDKP2log_GetPlayer(SID,Player)
-- QDKP2log_GetLog(SID,Player,ID)
-- QDKP2log_GetMainDKPEntry(Log,SID) if Log is a linked entry (Raid Award, Zerosum or noDKP), returns the log and the coordinates of the man entry (Log, Session,Player,ID)
-- QDKP2log_GetPlayersInSession(SID): Returns a list of the members that took part to the given session.
-- QDKP2log_ParsePlayerLog(name): Returns the global log for player.
-- QDKP2log_GetNetAmounts(Log, Net): Given a log list and a start net value, returns a list with the net dkp value history
-- QDKP2log_ResumDKPChanges(LogList): Given a log list, returns a UnDo-like field with the sum of all amounts.





--Function that returns a session given his sid
function QDKP2log_GetSession(SID)
  if not SID then
    QDKP2_Debug(1,"Log-DB","Asking for session log but given a nil SID")
    return nil
  end
  local out=QDKP2log[SID] or {}
  return out
end


--Function that returns a player's log
function QDKP2log_GetPlayer(SID,Player)
  if not Player then
    QDKP2_Debug(1,"Log-DB","Asking for player's log but given a NIL name")
    return
  end
  local Session=QDKP2log_GetSession(SID)
  return Session[QDKP2_GetMain(Player)] or {}
end

--function that returns a log entry. returns nil on error
function QDKP2log_GetLog(SID,Player,index)
  if not index then
    QDKP2_Debug(1,"Log-DB","Asking for log but given a NIL index")
    return nil
  end
  local PlayerLog=QDKP2log_GetPlayer(SID,Player)
  return PlayerLog[index] or {}
end

--
function QDKP2log_GetMainDKPEntry(Log,SID)
  local Type=QDKP2log_GetType(Log)
  local RaidAw,ZeroS,MainAw = QDKP2log_GetFlags(Log)
  if (QDKP2_IsDKPEntry(Type) or QDKP2_IsNODKPEntry(Type)) and ((RaidAw or ZeroS) and not MainAw) then
    local outLog,outSID,outPlayer,outIndex, outPlayerMain
    if RaidAw then
      outSID=SID
      outPlayer="RAID"
    elseif ZeroS then
      outSID,outPlayer,outPlayerMain = QDKP2log_GetLinkedPlayer(Log)
    end
    local List=QDKP2log_GetPlayer(outSID,outPlayer)
    outIndex=QDKP2log_FindIndex(List,QDKP2log_GetTS(Log))
    if not outIndex then
      QDKP2_Debug(1,"Log_DB","GetMainDKPEntry couldn't find the main dkp entry")
      return
    end
    outLog=List[outIndex]
    return outLog,outSID,outPlayer,outIndex,outPlayerMain
  else
    QDKP2_Debug(1,"Log_DB","GetMainDKPEntry called for a dkp entry that is not a liked slave")
  end
end

--Function that, given a SID, returns all the player that toke part in that session.
function QDKP2log_GetPlayersInSession(SID)
  QDKP2_Debug(3,"Log-DB","Asked for players that toke part to session "..tostring(SID))
  local SessionLog=QDKP2log[SID]
  if not SessionLog then
    QDKP2_Debug(1,"Log-DB","Trying to get the players that toke part at a inexistent session.")
    return
  end
  local List=ListFromDict(SessionLog)
  local output={}
  for i=1,table.getn(List) do
    local name=List[i]
    if string.sub(name,1,1) ~= "_" and name ~= "RAID" and QDKP2_IsInGuild(name) then
      table.insert(output,name)
    end
  end
  QDKP2_Debug(3,"Log-DB","Found "..tostring(table.getn(output)).." players")
  return output
end


function QDKP2log_GetNetAmounts(Log, Net, invert)
-- Given a log list and the starting DKP, returns a list with the same lenght with the net amount history and the changes for the given player.
  if not Log or Log=={} then return {},{}; end
	local Nets={}
	local Changes={}
  local start=1
  local stop=#Log
  local step=1
  if invert then
    start=stop
    stop=1
    step=-1
  end
	for i=start,stop,step do
		local LogEntry=Log[i]
		local Change=QDKP2log_GetChange(LogEntry)
		Nets[i]=Net
		Changes[i]=Change
		if Change then Net=Net-Change; end
	end
	return Nets,Changes
end


function QDKP2log_ResumDKPChanges(LogList)
-- Given a log list, Retruns a UnDo-like table with the net change of the log entries ({Gain,Spent,Hours})
  if not LogList then
    QDKP2_Debug(1,"Log-DB","Trying to resum DKP changes of a nil LogList")
    return {}
  end
  local out={0,0,0}
  for i=1,#LogList do
    local Log=LogList[i]
    Log=QDKP2log_CheckLink(Log)
    local Type=Log[QDKP2LOG_FIELD_TYPE]
    if QDKP2_IsActiveDKPEntry(Type) then
      local G,S,H=QDKP2log_GetAmounts(Log)
      out[1]=out[1]+(G or 0)
      out[2]=out[2]+(S or 0)
      out[3]=out[3]+(H or 0)
    end
  end
  if out[1]==0 then out[1]=nil; end
  if out[2]==0 then out[2]=nil; end
  if out[3]==0 then out[3]=nil; end
  return out
end


function QDKP2log_GetLinkedPlayer(Log)
--Returns the names used in links, made in the form "SID|name" or "SID|mainName|altName".
  local Text=Log[QDKP2LOG_FIELD_ACTION]
  if not Text then
    QDKP2_Debug(1,"Log-DB","Link entry with nil action field!")
  end
  local _,_,SID,Linked,AltLinked = string.find(Text,"([^|]+)|([^|]+)|([^|]+)")
  if not SID then
    _,_,SID,Linked = string.find(Text,"([^|]+)|([^|]+)")
  end
  if not SID then
    QDKP2_Debug(1,"Log-DB","Couldn't unpack link data. ("..Text..")")
    return
  end
  if not Linked then
    QDKP2_Debug(1,"Log-DB","Can't extract linked player from link. ("..Text..")")
    return
  end
  return SID,Linked,AltLinked
end



function QDKP2log_FindIndex(LogList,timestamp)
--this function returns the index of the Log with the given coordinates
--it does a iterative research to find the entry in a ordinate list.
  if not LogList or table.getn(LogList)==0 then
    QDKP2_Debug(1, "Log-DB", "Called FindIndex with a nil or empty log list")
    return
  end
  local a=1
  local b=table.getn(LogList)
  if LogList[a][QDKP2LOG_FIELD_TIME]<timestamp or LogList[b][QDKP2LOG_FIELD_TIME]>timestamp then
    QDKP2_Debug(2,"Log-DB","Called findindex with a timestamp outside first and last timpestamps of the given list")
    return
  end
  if LogList[a][QDKP2LOG_FIELD_TIME]==timestamp then
    QDKP2_Debug(3,"Log-DB","Log found as the first of the list")
    return a
  end
  if LogList[b][QDKP2LOG_FIELD_TIME]==timestamp then
    QDKP2_Debug(3,"Log-DB","Log found as the last of the list")
    return b
  end
  if b==1 or b==2 then
    QDKP2_Debug(2,"Log-DB","Loglist lenght is 1 or 2 and the log isn't the first or the last")
    return
  end
  local i=1
  while (b-a) > 1 do
    local c=math.floor((a+b)/2)
    local ts=LogList[c][QDKP2LOG_FIELD_TIME]
    if ts==timestamp then
      QDKP2_Debug(3,"Log-DB","Log found in "..tostring(i).." iterations")
      return c
    elseif ts>timestamp then a=c
    elseif ts<timestamp then b=c
    end
    i=i+1
  end
  QDKP2_Debug(3,"Log-DB","Failed to find the given log")
end


function QDKP2log_Find(LogList,timestamp)
--Dummy of FindLogIndex that returns the log and not the index
  if not timestamp then return {QDKP2LOG_INVALID, 0, "*FIND LOG: No timestamp in the query*"}; end
  if not LogList or table.getn(LogList)<=0 then return {QDKP2LOG_INVALID, timestamp, "*FIND LOG: Null or empty Log List passed*"}; end
  local index=QDKP2log_FindIndex(LogList,timestamp)
  if not index then return {QDKP2LOG_INVALID, timestamp, "*FIND LOG: Can't find the entry*"}; end
  return LogList[index]
end

function QDKP2log_FindLink(LinkLog)
--Almost identical to QDKP2_FindLog, but extracts the data he needs from the given log link.
  local SID,name,altName=QDKP2log_GetLinkedPlayer(LinkLog)
  local timestamp=LinkLog[QDKP2LOG_FIELD_TIME]
  if not timestamp then return {QDKP2LOG_INVALID, nil, QDKP2_LOC_InvalidLinkTime}; end
  if not name then return {QDKP2LOG_INVALID, timestamp, QDKP2_LOC_InvalidLinkPlayer}; end
  if not SID then return {QDKP2LOG_INVALID, timestamp, QDKP2_LOC_InvalidLinkSession}; end
  if not QDKP2log[SID] then return {QDKP2LOG_INVALID, timestamp, QDKP2_LOC_InvalidLinkSessName}; end
  local LogList=QDKP2log[SID][name]
  if not LogList or table.getn(LogList)<=0 then return {QDKP2LOG_INVALID, timestamp, "*INVALID LINK: Can't find linked player ("..name..")'s log*"}; end
  local index=QDKP2log_FindIndex(LogList,timestamp)
  if not index then return {QDKP2LOG_INVALID, timestamp, "*INVALID LINK: Can't find the entry in linked player's log ("..name..")*"}; end
  return LogList[index], name, altName, SID
end



function QDKP2log_GetList(SID, timestamp)
--this searchs the whole session for entries that has the given timestamp and
--returns a list of logs and name
-- { NameList , LogList}
  local out={}
  local nameList,indexList=QDKP2log_GetIndexList(SID, timestamp)
  if nameList and indexList then
    for i=1,table.getn(indexList) do
      local name=nameList[i]
      local index=indexList[i]
      local Log=QDKP2log[SID][name][index]
      if Log then
        table.insert(out,Log)
      end
    end
  end
  return nameList, out
end



function QDKP2log_GetIndexList(SID, timestamp)
--this searchs a whole session for entries that have the given timestamp and
--returns a list of indexes and name
-- { NameList , IndexList}
  QDKP2_Debug(2,"Log-DB","Retriving all logs with TS "..tostring(timestamp).."in session"..tostring(SID))
  local nameList = {}
  local indexList={}
  local session=QDKP2log[SID]
  if not timestamp then
    QDKP2_Debug(1,"Log-DB", "Asked to find logs with a given timestamp but nil timestamp provided")
    return {},{}
  end
  if not session then
    QDKP2_Debug(1,"Log-DB","Asked to find logs with a given timestamp but invalid session provided: "..tostring(SID))
    return {},{}
  end

  local LogNames=ListFromDict(QDKP2log[SID])
  for i=1, table.getn(LogNames) do
    local name = LogNames[i]
    if string.sub(name,1,1) ~= '_' and QDKP2_IsInGuild(name) then
      local logList=QDKP2log[SID][name]
      if logList then
        local index = QDKP2log_FindIndex(QDKP2log[SID][name], timestamp)
        if index then
          table.insert(nameList, name)
          table.insert(indexList, index)
        end
      end
    end
  end
  QDKP2_Debug(3,"Log-DB","Found "..tostring(table.getn(nameList)).." entries")
  return nameList, indexList
end


function QDKP2log_GetSessionsOfPlayers(Name)
--Function that, given a player, returns a list of the SID of the sessions he took part.
  local SessList=ListFromDict(QDKP2log)
  local output={}
  for i=1, table.getn(SessList) do
    local SID=SessList[i]
    local Session=QDKP2log[SID]
    if Session[Name] then table.insert(output,SID); end
  end
  return output
end

function QDKP2log_GetSessionDetails(SID)
--returns a list of every log related to a session, sorted by time, chaining in all logs for the player that toke part.
--as second argoument, returns a list that retruns the owner of the log used as index.
	local LogList={}
	local LogNames={}
	local Log=QDKP2log_GetSession(SID)
	if Log then
		for Name,PlayerLog in pairs(Log) do
			if string.sub(Name,1,1)~='_' then
				for j,Voice in ipairs(PlayerLog) do
					local Type=QDKP2log_GetType(Voice)
					if Type~=QDKP2LOG_LINK and --DO NOT WANT links
						(Name~="RAID" or not QDKP2_IsDKPEntry(Type)) then
						table.insert(LogList,Voice)
						LogNames[Voice]=Name
					end
				end
			end
		end
	end
	table.sort(LogList,QDKP2log_CreatedDateSort)
	return LogList,LogNames
end


function QDKP2log_ParsePlayerLog(Name)
--Function that, given a player, returns his personal log with this structure:
--  Log-+
--      |
--      +-[1]=[Log1]
--      +-[2]=[Log2]
--      +-[3]=[Log3]
--      +-[4]=[QDKP2LOG_SESSION,STARTTIME,<"Session1">]
--      +-[5]=[Log4]
--      +-[6]=[QDKP2LOG_SESSION,STARTTIME,<"Session2">]
--      ...
--      +-["<Session1>"]=QDKP2log["<Session1>"][PLAYER]
--      ...
  if not Name then error("QDKP2log_ParsePlayerLog: <Name> parameter is nil!"); end
  QDKP2_Debug(3,"Log-DB","Requesting parsed log for "..Name)
  local out={}
  local sessions={}
  local PlayerSessions=QDKP2log_GetSessionsOfPlayers(Name)
  QDKP2_Debug(3,"Log-DB","Found that he took part at "..tostring(table.getn(PlayerSessions)).." sessions")
  for i=1,table.getn(PlayerSessions) do
    local SID=PlayerSessions[i]
    if SID ~= "0" then
      local Session=QDKP2log[SID]
      local SessionLogList=Session[Name]
      local UnDo
      if Name=="RAID" then local GainDKP,SpentDKP,Hours=QDKP2log_SessionStatistics(SID); UnDo={GainDKP,SpentDKP,Hours}
      else UnDo=QDKP2log_ResumDKPChanges(SessionLogList)
      end
      local List,SessName,Mantainer,Code,DateStart,DateStop,DateMod = QDKP2_GetSessionInfo(SID)
      local SessVoice={QDKP2LOG_SESSION,DateStop or DateStart,SID,Code,UnDo,nil,DateMod,nil,Mantainer}
      table.insert(out,SessVoice)
      sessions[SID]=SessionLogList
    end
  end
  local GeneralSess=QDKP2log["0"] or {}
  local PlayerGeneralSess=GeneralSess[Name]
  if PlayerGeneralSess then
    for i=1,#PlayerGeneralSess do table.insert(out,PlayerGeneralSess[i]); end
  end
  table.sort(out,QDKP2log_CreatedDateSort)
  for i=1,#out do sessions[i]=out[i]; end
  return sessions
end


function QDKP2log_SessionStatistics(SID)
  local PlayerList=QDKP2log_GetPlayersInSession(SID)
  table.insert(PlayerList,"RAID")
  local GainDKP=0
  local SpentDKP=0
  local GainHours=0
  local totalDrop=0
  local BossKilled=0
  for i,Player in pairs(PlayerList) do
    local LogList=QDKP2log_GetPlayer(SID,Player)
    for j,Log in pairs(LogList) do
      local Type=Log[QDKP2LOG_FIELD_TYPE]
      if Player=="RAID" then
        if Type==QDKP2LOG_BOSS then
          BossKilled=BossKilled+1
        end
      else
        if QDKP2_IsActiveDKPEntry(Type) then
          local G,S,H=QDKP2log_GetAmounts(Log)
          GainDKP=GainDKP+(G or 0)
          SpentDKP=SpentDKP+(S or 0)
          GainHours=GainHours+(H or 0)
        elseif Type==QDKP2LOG_LOOT then
          totalDrop=totalDrop+1
        end
      end
    end
  end
  return GainDKP,SpentDKP,GainHours,#PlayerList-1,totalDrop,BossKilled
end


----------------------PURGE FUNCTIONS ---------------------------------------

local function sortfunc(sid1,sid2)
  local _,_,_,id1=QDKP2_GetSessionInfo(sid1)
  local _,_,_,id2=QDKP2_GetSessionInfo(sid2)
  if (id1 or -1)<(id2 or -1) then return true; end
end

--Delete all but the last <number> sessions.
function QDKP2log_PurgeSessions(number,Sure)
  if not Sure then
    mess = "Do you want to erase all log entries\n except for last "..number.." sessions?"
    QDKP2_AskUser(mess,QDKP2_LOG_PurgeSessions, number, true)
    return
  end
  QDKP2_Debug(2,"Logging","Purging all log but the last "..tostring(number).." sessions.")
  local LogList = ListFromDict(QDKP2log)
  if table.getn(LogList)<=number then return; end

  local SessionCodes={}

  table.sort(LogList, sortfunc)

  local GenSess=QDKP2log['0']
  local CurSess=QDKP2_IsManagingSession()
  local CurSessList=QDKP2log[CurSess or 12345631] --the or is just to avoid index=nil exception

  for i=1,#LogList-number do
    QDKP2_Debug(3,"Logging","Removing session "..tostring(LogList[i]))
    QDKP2log[LogList[i]]=nil
  end

  QDKP2log['0']=GenSess  --this is to avoid the deletion of the current session.
  if CurSess then
    QDKP2log[CurSess]=CurSessList
  end
end


function QDKP2log_PurgeWipe(Sure)
  if not Sure then
    mess = "Do you want to cancel\n all the log data?"
    QDKP2_AskUser(mess,QDKP2_LOG_PurgeWipe, true)
    return
  end
  if QDKP2_IsManagingSession() then
    QDKP2_StopSession(true)
  end
  QDKP2log_Init()
  QDKP2_Msg("The log has been wiped.")
end

--resets the log
function QDKP2log_Init()
  QDKP2_Debug(1,"Logging","Initializing the log...")
  table.wipe(QDKP2log)
  QDKP2log["0"]=QDKP2log["0"] or {}
end


function QDKP2log_CreatedDateSort(log1,log2)
-- Function compatible with the LUA's sort method.
-- used to sort a list of logs by creation date, from newer to older.
  if log1[QDKP2LOG_FIELD_TIME] > log2[QDKP2LOG_FIELD_TIME] then return true
  else return false
  end
end

function QDKP2log_ModDateSort(log1,log2)
-- as above, but sort by modification date.
  local log1date=log1[QDKP2LOG_FIELD_MODDATE] or log1[QDKP2LOG_FIELD_TIME]
  local log2date=log2[QDKP2LOG_FIELD_MODDATE] or log2[QDKP2LOG_FIELD_TIME]
  if log1date > log2date then return true
  else return false
  end
end


