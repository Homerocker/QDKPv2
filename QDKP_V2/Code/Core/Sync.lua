-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--          ## IN-GAME SYNCRONIZATION FUNCTIONS ##


QDKP2sync_TYPE_VOICE="v"
QDKP2sync_TYPE_SESS="s"
QDKP2sync_TYPE_NOTES="n"

QDKP2sync_PriorityQueue={}
QDKP2sync_PauseBetweenPackets=5
QDKP2sync_CorrRatioExp=0.5

QDKP2sync_DesideredBPS=300  --this is the desidered bps of packets per second. It's comparated with the BPS from all received addon's message.


function QDKP2sync_Load()
	QDKP2sync_ResetMonitor()
	Chronos.schedule(QDKP2sync_SendMsg, QDKP2sync_PauseBetweenPackets)
	Chronos.scheduleRepeating("MonitorBandWidth", 5, QDKP2sync_BandThrottle)
end

--This function tries to set the bandwidth to meet the desidered overall guild's Addons Bytes-per-second.
function QDKP2sync_BandThrottle()
	local NowTime=time()
	local Band=QDKP2sync_RecBytes/(QDKP2sync_ResetTime-NowTime)   --BPS
	local CorrectionRateo=(Band/QDKP2sync_DesideredBPS) ^ QDKP2sync_CorrRatioExp  --the % of time-between-packets of the next window

	if CorrectionRateo<0.5 then CorrectionRateo=0.5 --This is to avoid big changes and divergence.
	elseif CorrectionRateo>2 then CorrectionRateo=2
	end
	local NewPause=QDKP2sync_PauseBetweenPackets * CorrectionRateo

	if NewPause<0.5 then NewPause=0.5
	elseif NewPause>9 then NewPause=9
	end

	QDKP2sync_ResetMonitor()
	QDKP2sync_PauseBetweenPackets=NewPause
	QDKP2_Debug(2,"Sync","Thottle: BPS="..tostring(Band)..", T%="..tostring(CorrectionRateo*100)..", New T="..tostring(NewPause))
end

-------------------------------------------------------------------------
-- SendFunction


function QDKP2sync_SendMsg()
	if table.getn(QDKP2sync_PriorityQueue)>0 then
		QDKP2sync_EmptyPriorityQueue()
	else
		QDKP2sync_RouteMsg(QDKP2sync_GetNewBulkMsg(),"BULK")
	end
	Chronos.schedule(QDKP2sync_PauseBetweenPackets, QDKP2sync_SendMsg)
end

--Sends all Packet in the Priority Queue
function QDKP2sync_EmptyPriorityQueue()
	while table.getn(QDKP2sync_PriorityQueue)>0 do
		local Msg=table.remove(QDKP2sync_PriorityQueue,1)
		QDKP2sync_RouteMsg(Msg,"NORMAL")
	end
end

--Route the given Packet
--If i'm not in a raid, all communications are routed to Guild's channel
--If i'm in a raid and no externals are in, all is sent to Guild anyway
--If there are up to 3 external, all output is sent to Guild, and a copy is sent to each external thru whisper channel
--If there are more than 3 external, all is sent to the Raid channel. Live communications and External's Note are sent by copy to the Guild Channel.
function QDKP2sync_RouteMsg(Msg,Priority)
	local Channel
	if not QDKP2_IsRaidPresent() then Channel="GUILD"; end
	else
		local ExtRaidMembers=QDKP2_GetExtRaidMembers()
		if ExtRaidMembers<=3 then
			for i=1,table.getn(ExtRaidMembers) do
				local ExtName=ExtRaidMembers[i]
				QDKP2sync_SendAddonMsg(Priority,Msg,"WHISPER",ExtName)
			end
			Channel="GUILD"
		else
			local Type,Player=QDKP2sync_ParseMsg(Msg)
			if Priority=="NORMAL" or Priority=="ALERT" or (Type==QDKP2sync_TYPE_NOTES and QDKP2_IsExternal(Player)) then
				QDKP2sync_SendAddonMsg(Priority, Msg, "GUILD")
				if Priority=="BULK" then QDKP2sync_BandWEaten(Msg)
			end
			Channel="RAID"
		end
	end
	QDKP2sync_SendAddonMsg(Priority, Msg, Channel)
	if Priority=="BULK" then QDKP2sync_BandWEaten(Msg)
end


--This function returns an entry ready to be sent every time it's called.
function QDKP2sync_GetNewBulkMsg()
	return "abc"
end


-- Interface to ChatThrottleLib
function QDKP2sync_SendAddonMsg(Priority,Msg,Channel,SubChannel)
	if Priority=="ALERT" then
		QDKP2_Debug(1,"Sync","Sent ALERT packet to "..tostring(Channel).."/"..tostring(SubChannel))
		QDKP2_Debug(1,"Sync",Msg)
	elseif Priority=="NORMAL" then
		QDKP2_Debug(2,"Sync","Sent NORMAL packet to "..tostring(Channel).."/"..tostring(SubChannel))
		QDKP2_Debug(2,"Sync",Msg)
	elseif Priority=="BULK" then
		QDKP2_Debug(3,"Sync","Sent BULK packet to "..tostring(Channel).."/"..tostring(SubChannel))
		QDKP2_Debug(3,"Sync",Msg)
	ChatThrottleLib:SendAddonMessage(Priority, "QDKP_"..tostring(QDKP2_DBREQ), Msg, Channel,SubChannel)
end

-------------------------------------------------------------------------
-- Receive Functions

function QDKP2sync_HandleAddonMsg(header,msg,channel,sender)
	QDKP2sync_BandWEaten(MsgToSend)
	if header ~= "QDKP_"..tostring(QDKP2_DBREQ) then return; end  --if the message is from annother addon or annother version , leave
	if not QDKP2_IsInGuild(sender) then return; end -- if the message comes from an unknown player, discard
	Type=string.sub(msg,1,1)
	if not Type then
		QDKP2_Debug(1,"Sync","Invalid packet from "..sender..", no datatype")
		QDKP2_Debug(1,"Sync",msg)
		return
	end-- if the message is invalid, discard
	if       Type==QDKP2sync_TYPE_VOICE then
		if (not QDKP2_RecSecureLogData) or QDKP2sync_IsSecureRank(sender) then
			QDKP2sync_REC_Voice(sender,msg)
		end
	elseif Type==QDKP2sync_TYPE_SESS then
		if (not QDKP2_RecSecureLogData) or QDKP2sync_IsSecureRank(sender) then
			QDKP2sync_REC_Session(sender,msg)
		end
	elseif Type==QDKP2sync_TYPE_NOTES then
		if (not QDKP2_RecSecureDKPData) or QDKP2sync_IsSecureRank(sender) then
			QDKP2sync_REC_Amounts(sender,msg)
		end
	else
		QDKP2_Debug(1,"Sync","Invalid packet from "..sender..", wrong datatype")
		QDKP2_Debug(1,"Sync",msg)
	end
end


function QDKP2sync_REC_Voice(sender,msg)
	local Type,Session,Player,ModifyVersion,Timestamp,LogType,Memo,Undo,SubType = QDKP2sync_ParseMsg(msg)
	ModifyVersion=tonumber(ModifyVersion)
	Timestamp=tonumber(Timestamp)
	LogType=tonumber(LogType)
	local UndoSuc,UndoErr
	if Undo~="" then
		UndoSuc,UndoErr=pcall(loadstring("Undo={"..Undo.."}"))
	else
		UndoSuc=true
	end
	if SubType~="" then SubType=tonumber(SubType); end
	local ErrorString
	if (not Session) or Session=="" then ErrorString="no Session name"
	elseif (not Player) or Player==""  then ErrorString="no Player name"
	elseif not ModifyVersion then ErrorString="no modify version"
	elseif (not LogType) or (not QDKP2log_IsValidType(LogType)) then ErrorString="no Type"
	elseif (not Timestamp) or Timestamp<0 then ErrorString="no Timestamp"
	elseif not UndoSuc then ErrorString="no Undo ("..UndoErr..")"
	elseif Undo=="" and (QDKP2_IsNODKPEntry(LogType) or QDKP2_IsDKPEntry(LogType)) then  ErrorString="DKP entry and no Undo"
	elseif not SubType or (not QDKP2log_IsValidSubType(SubType)) then ErrorString="no SubType"
	end
	if ErrorString then
		QDKP2_Debug(1,"Sync","Invalid voice packet from "..sender..", "..ErrorString)
		QDKP2_Debug(1,"Sync",msg)
		return
	end
	local SessionInfos=QDKP2log_GetSessionInfo(Session)
	if not SessionInfos then return; end --if the session has not been created yet, drop the packet

	local UpdateIt,Index=QDKP2log_GetPositionToInsert(Session,Player,Timestamp)
	local LogList=QDKP2log_GetPlayerLog(Session,Player)

	if UpdateIt then
		local My_ModifyVersion = QDKP2log_GetVoiceModifyVersion(Session,Player,Index)
		if My_ModifyVersion and My_LastModify>=ModifyVersion then
			QDKP2_Debug(2,"Sync","Packet dropped because my voice data is newer or equal")
			--I'd like to add here a way to send a "correction" of the just received packet to the same channel.
			return
		end
	end

	local LogEntry
	if Memo=="" then Memo=nil; end
	if Undo=="" then Undo=nil; end
	if SubType=="" then SubType=nil; end

	--[[
	if Memo=="" and Undo=="" and SubType=="" then
		LogEntry=Timestamp..";;"..ModifyVersion..";;"..LogType
	elseif Undo=="" and SubType=="" then
		LogEntry=Timestamp..";;"..ModifyVersion..";;"..LogType..";;"..Memo
	elseif SubType=="" then
		LogEntry=Timestamp..";;"..ModifyVersion..";;"..LogType..";;"..Memo..";;"..Undo
	else
		LogEntry=Timestamp..";;"..ModifyVersion..";;"..LogType..";;"..Memo..";;"..Undo..";;"..SubType
	end
	]]

	if UpdateIt then
		QDKP2log_UpdateEntry(Session,Player,Index,Timestamp,ModifyVersion,LogType,Memo,Undo,Subtype)
	else
		QDKP2log_InsertEntry(Session,Player,Timestamp,ModifyVersion,LogType,Memo,Undo,Subtype,Index)
	end
	QDKP2_Events:Fire("DATA_UPDATED","all")
end

function QDKP2sync_REC_Session(sender,msg)
	local Type,Session,ModifyVersion,StartTime,StopTime,Curator = QDKP2sync_ParseMsg(msg)
	ModifyVersion=tonumber(ModifyVersion)
	StartTime=tonumber(StartTime)
	StopTime=tonumber(StopTime)
	local ErrorString
	if (not Session) or Session=="" then ErrorString="no Session"
	elseif not ModifyVersion then ErrorString="no Modify Version"
	elseif not StartTime then ErrorString="no Start Time"
	elseif not StopTime then ErrorString="no Stop Time"
	elseif not Curator or Curator=="" then ErrorString="no Curator's name"
	end
	if ErrorString then
		QDKP2_Debug(1,"Sync","Invalid session packet from "..sender..", "..ErrorString)
		QDKP2_Debug(1,"Sync",msg)
		return
	end
	local StartTime,StopTime,Curator,MyModifyVersion=QDKP2log_GetSessionInfo(Session)
	if MyModifyVersion and MyModifyVersion>=ModifyVersion then
		QDKP2_Debug(2,"Sync","Packet dropped because my session data is newer or equal")
		--I'd like to add here a way to send a "correction" of the just received packet to the same channel.
		return
	end
	QDKP2log_SetSessionInfo(StartTime,StopTime,Curator,MyModifyVersion)
	QDKP2_RefreshAll()
end

function QDKP2sync_REC_Amounts(sender,msg)
	local Type,Player,ModifyVersion,NoteString,Class = QDKP2sync_ParseMsg(msg)
	ModifyVersion=tonumber(ModifyVersion)
	local ErrorString
	if (not Player) or Player=="" then ErrorString="no Player's name"
	elseif not ModifyVersion then ErrorString="no Modify version"
	elseif not Class then ErrorString="no Class"
	end
	if ErrorString then
		QDKP2_Debug(1,"Sync","Invalid player's Note packet from "..sender..", "..ErrorString)
		QDKP2_Debug(1,"Sync",msg)
		return
	end
	local IsInguild=QDKP2_IsInGuild(Player)
	local IsExternal=QDKP2_IsExternal(Player)
	if IsInGuild and not IsExternal then return; end  --if is in guild and not external, i have officier/public notes and i don't need totals.
	if not IsInGuild and QDKP2_AddReceivedExternals and not QDKP2_WasDeletedExternal(Player) then
		QDKP2_NewExternal(Player, NoteString, Class)
	elseif not IsInGuild then
		--if i'm here, it means that i don't want to add "Player" as external. Just drop.
		return
	end
	local My_ModifyVersion=QDKP2_GetExternalModifyVersion(Player)
	if ModifyVersion~=-1 and My_ModifyVersion and My_ModifyVersion>=ModifyVersion then
		QDKP2_Debug(2,"Sync","Packet dropped because my external's Note is newer or equal")
		--I'd like to add here a way to send a "correction" of the just received packet to the same channel.
		return
	end
	if ModifyVersion==-1 then ModifyVersion=0; end
	QDKP2externals[name]={NoteString,Class,ModifyVersion}
	QDKP2_RefreshGuild()
	QDKP2_RefreshRaid()
	QDKP2_RefreshAll()

end

--------------------------------------------------------------------------------
-- Various functions

function QDKP2sync_ResetMonitor()
	QDKP2sync_RecBytes=0
	QDKP2sync_ResetTime=time()
end

function QDKP2sync_BandWEaten(Msg)
	QDKP2sync_RecBytes=QDKP2sync_RecBytes + string.len(Msg) + 12
end

