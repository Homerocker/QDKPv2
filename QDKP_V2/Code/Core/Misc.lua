-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## QDKP2 CORE FUNCTIONS ##
--            Miscellaneous core functions

--    In this file are included all the functions that couldn't be included in any proper code group.
--
-- API DOCUMENTATION:
--
-- QDKP2_Notify(<name>)
-- QDKP2_NotifyAll()
-- QDKP2_PostExternals(channel,subChannel)
--
-- QDKP2_Debug(<level>,<system>,<text>): Creates a debug output for the given system. Level can be 1 (high), 2 or 3 (low).
-- QDKP2_Debug_SetLevel(Level): Sets the minimum debug level to be shown
-- QDKP2_Debug_SetFilter(System,Status): Sets a debug filter. system is a debug subsystem, status can be true or false.
-- QDKP2_Debug_FilterAll(status): Like setfilter, but selects all subsystem. set <status> to true to display them all, false to hide.
--
-- QDKP2_UnuploadedChanges(): Returns true if i have some DKP modifications not yet saved to the officer notes
-- QDKP2_CleanSession(): Returns true if the current session has not been touched yet.
-- QDKP2_minRank(<name>): returns true if name's guild rank is not in the unDKP-able ranks list
-- QDKP2_isChargeable(<name>,<amount>): returns true if name can safely be charged by <amount>
-- QDKP2_Msg(msg, [Type], [Color], [Channel]): Standard message handler.
--
-- QDKP2_FormatName(name): Retruns a formatted copy of name ("airiena" becomes "Airiena")
-- QDKP2_GetDateTextFromTS(Time): Extracts the date from the given timestamp.
-- QDKP2_Time(): Returns the second since the epoch using the delta founded by GuessTimeZone
-- MergeList(list1,list2): returns a new list that is the union between list1 and 2
-- RoundNum(number)


----------------------- GLOBAL VARS ----------------


---------------------- GENERAL GLOBALS ------------------

QDKP2_VERSION      = "2.6.7"
QDKP2_DBREQ        = 20550
QDKP2_BETA         = false
QDKP2_DEBUG	       = 0
------------------------------COLOR GLOBALS------------------------

QDKP2_COLOR_RED    = "|cffff0000";
QDKP2_COLOR_YELLOW = "|cffffff00";
QDKP2_COLOR_GREEN  = "|cff00ff00";
QDKP2_COLOR_GREY   = "|caaaaaaaa";
QDKP2_COLOR_WHITE  = "|cffffffff";
QDKP2_COLOR_BLUE   = "|cff3366ff";
QDKP2_COLOR_CLOSE  = "|r";

---------------------- INDEX GLOBALS --------------------------
QDKP2_TOTAL=1
QDKP2_SPENT=2
QDKP2_HOURS=3

---------------------------GLOBALS/FLAGS INIT------------------------------

QDKP2_CHECK_RUN = 0
QDKP2_CHECK_RENEW_TIMER = 0
QDKP2_REFRESHED_GUILD_ROSTER = false
QDKP2_RESET_WARNED = false
QDKP2_GUILD_NAME = ""
QDKP2checkTries = 0
QDKP2_EID = 0

QDKP2_TOTAL=1
QDKP2_SPENT=2
QDKP2_HOURS=3

QDKP2_outputstyle=4

---------------------------------------NOTIFY----------------------------

--notifies the raid of gains
function QDKP2_NotifyAll()
  if QDKP2_ManagementMode() then
    for i=1, QDKP2_GetNumRaidMembers() do
	  local name, rank, subgroup, level, class, fileName, zone, online, inguild, standby, removed = QDKP2_GetRaidRosterInfo(i)
	  if online and inguild and not removed then QDKP2_Notify(name); end
    end
  else
    QDKP2_NeedManagementMode()
  end
end

--notifies name of his gains and spent
function QDKP2_Notify(name)
  if QDKP2_IsInGuild(name) then
    ChatThrottleLib:SendChatMessage("ALERT","QDKP2",QDKP2_MakeNotifyMsg(name), "WHISPER", nil, name);
  end
end

--Creates a notify message ("You have xyz dkp...").
-- Name is the name of the player.
-- if u3p  is true, it will output a report in third person. ("Frank has xyz dkp....")

function QDKP2_MakeNotifyMsg(name,u3p)
  local logList=QDKP2log["RAID"]
  local _,SName = QDKP2_OngoingSessionDetails()

  local msg
  if u3p then
    msg=QDKP2_LOC_NotifyString_u3p
  else
    msg=QDKP2_LOC_NotifyString
  end

  local gained=0
  local spent =0
  local hours=0
  local gained,spent=QDKP2_GetSessionAmounts(name)

  msg=string.gsub(msg,"$NAME",QDKP2_GetName(name))
  msg=string.gsub(msg,"$GUILDNAME",QDKP2_GUILD_NAME)
  msg=string.gsub(msg,"$RANK", QDKP2rank[name])
  msg=string.gsub(msg,"$CLASS", QDKP2class[name])
  msg=string.gsub(msg,"$NET",tostring(QDKP2_GetNet(name)))
  msg=string.gsub(msg,"$TOTAL",tostring(QDKP2_GetTotal(name)))
  msg=string.gsub(msg,"$SPENT",tostring(QDKP2_GetSpent(name)))
  msg=string.gsub(msg,"$TIME",tostring(QDKP2_GetHours(name)))
  msg=string.gsub(msg,"$SESSGAINED",tostring(gained or 0))
  msg=string.gsub(msg,"$SESSSPENT",tostring(spent or 0))
  msg=string.gsub(msg,"$SESSNAME",SName)
  return msg
end

------------------------------ DEBUG -----------------------

QDKP2_Debug_Subsystems={"General","Core","Logging","Guild","Raid","Session","Init","CLI","Log-DB","Update"}

-- Outputs a Debug message if level is equal or greater to QDKP2_DEBUG. Applies QDKP2_DebugFilter (if defined)
function QDKP2_Debug(level,system,text)
  if QDKP2_Debug_List then
    QDKP2_Debug_List:insert(tostring(level)..'-'..tostring(system)..'-'..tostring(text))
  end
  level=level or 1
  if level>QDKP2_DEBUG then return; end
  system=system or "General"
  if QDKP2_Debug_Filter and  QDKP2_Debug_Filter[string.lower(system)] then return; end
  text=text or "nil"
  DEFAULT_CHAT_FRAME:AddMessage(QDKP2_COLOR_YELLOW.."<QDKP2-DBG> "..system..": "..QDKP2_COLOR_WHITE..tostring(text)..QDKP2_COLOR_CLOSE);
end

function QDKP2_Debug_SetLevel(Level)
-- set the debug level to the given value.
-- At the moment, the levels are:
-- 0: no debug
-- 1: Errors
-- 2: Relevant situation
-- 3: All

  QDKP2_DEBUG=Level
end

function QDKP2_Debug_SetFilter(System,Status)
-- sets a filter for the gives system. Status can be true or false
-- true will show that subsystem, false will hide.
  System=string.lower(System)
  local subsystems={}
  table.foreach(QDKP2_Debug_Subsystems, function(key,val) subsystems[string.lower(val)]=true; end)
  if not subsystems[System] then return; end
  if not QDKP2_Debug_Filter then QDKP2_Debug_Filter={}; end
  QDKP2_Debug_Filter[System]=Status
  return true
end

function QDKP2_Debug_FilterAll(status)
  if not status then
--removes the debug filter
    QDKP2_Debug_Filter=nil
  else
--filter all
	QDKP2_Debug_Filter={}
	for i=1,#QDKP2_Debug_Subsystems do
	  local subsystem=QDKP2_Debug_Subsystems[i]
	  QDKP2_Debug_Filter[string.lower(subsystem)]=status
	end
  end
end



--------------------- MISCELLANEOUS QDKP FUNCTIONS ---------


--Returns a delta in seconds that lets you uniform the local time with the server time.
--if QDKP2_LOCALTIME_MANUALDELTA is true, will use it instead of the guessed amount.
function QDKP2_GuessTimeZone()
  if QDKP2_LOCALTIME_MANUALDELTA then
    return math.floor(QDKP2_LOCALTIME_MANUALDELTA*3600)
  end
  local ServerTimeHrs, ServerTimeMin = GetGameTime()
  local ServerSecFromMidnight=ServerTimeHrs*3600 + ServerTimeMin*60
  local LocalSecFromMidnight=tonumber(date("%H"))*3600 + tonumber(date("%M"))*60
  local out= math.floor((ServerSecFromMidnight - LocalSecFromMidnight)/60.0)*60
--If the delay is > 12 hours then assume the delay to be negative. This means that the maximum difference between local
--time and server time that does not generate a date error is 12 hours.
  if out>12*3600 then out=24*3600-out; end
  QDKP2_Debug(2,"Core","GuessTimeZone returns "..tostring(out))
  return out
end


function QDKP2_Time()
-- since I want to uniform time zones, I use a TZ detector to guess the delta of seconds between
-- local time and server time (see QDKP2_GuessTimeZone). This is used instead of the builtin time() function
  return time()+QDKP2_TimeDelta
end


-- returns true if you have unuploaded changes, nil otherwise.
function QDKP2_UnuploadedChanges()
  for i=1, table.getn(QDKP2name) do
    if QDKP2_IsModified(QDKP2name[i]) then
      return true
    end
  end
end


--returns true if <name>'s guild rank is not in the UNDKPABLE_RANKs table
function QDKP2_minRank(name)
  local rank = QDKP2rank[name]
  for i=1, table.getn(QDKP2_UNDKPABLE_RANK) do      --checks the rank
    if(rank==QDKP2_UNDKPABLE_RANK[i]) then
      return false
    end
  end
  return true
end


--returns true if players can spend dkp. That is, if is net DKP amount is greater then the minimum net
--dkp cap both before and after the loss.
function QDKP2_IsChargeable(name, amount)
  local Net=QDKP2_GetNet(name)
  if Net==QDKP2_MINIMUM_NET then
    local msg=QDKP2_LOC_EqToLowCap
    msg=string.gsub(msg,"$NAME",name)
    QDKP2_Msg(msg, "WARNING")
    return
  end
  if Net-amount < QDKP2_MINIMUM_NET then
    local msg=QDKP2_LOC_NearToLowCap
    msg=string.gsub(msg,"$NAME",name)
    msg=string.gsub(msg,"$MAXCHARGE", tostring(Net-QDKP2_MINIMUM_NET))
    QDKP2_Msg(msg, "WARNING")
    return
  end
  return true
end


--retrun true if there is an uploaded change in the player log
function QDKP2_IsModified(name)
  if not QDKP2_IsInGuild(name) then return; end
  name = QDKP2_GetMain(name)
  if QDKP2note[name][QDKP2_TOTAL] ~= QDKP2stored[name][QDKP2_TOTAL] or QDKP2note[name][QDKP2_SPENT] ~= QDKP2stored[name][QDKP2_SPENT] or math.abs(QDKP2note[name][QDKP2_HOURS] - QDKP2stored[name][QDKP2_HOURS]) > 0.09 then
    return true
  else
    return false
  end
end

-- returns true if i haven't modified anyone in the current session
function QDKP2_CleanSession()
  for i=1, table.getn(QDKP2name) do
    local name = QDKP2name[i]
    if QDKP2_GetRaidGained(name) ~= 0 or QDKP2_GetRaidSpent(name) ~= 0 or QDKP2_GetRaidHours(name) ~= 0 then
      return false
    end
  end
  return true
end


--Used to output info/errors/notifications.
--By default outputs to the chat frame.
--Type is nil for default (INFO) or one of these:
--"INFO"
--"WARNING"
--"ERROR"
--"NOTIFICATION"
--"DKP" (used for DKP acknowledgement like "abc spends x DKP for yyy")
--Color will override the default color for the msg type. Give it as color string.
--Channel overrides the default channel for the msg type. Give it in the standard libComm standard.
-- TBD
function QDKP2_Msg(msg, Type, Color, Channel)
  Type = Type or "INFO"
  if Type=="INFO" then
    Color=Color or QDKP2_COLOR_WHITE
    Channel=Channel or "CHAT"
  elseif Type=="TIMERTICK" then
    Color=Color or QDKP2_COLOR_GREEN
    Channel=Channel or "CHAT"
  elseif Type=="WARNING" then
    Color=Color or QDKP2_COLOR_YELLOW
    Channel=Channel or "CHAT"
  elseif Type=="ERROR" then
    Color=Color or QDKP2_COLOR_RED
    Channel=Channel or "CHAT"
  elseif Type=="DKP" or Type=="AWARD" then
    Color=Color or QDKP2_COLOR_BLUE
    Channel=Channel or "CHAT"
  elseif Type=="IRONMAN" then
    Color=Color or QDKP2_COLOR_WHITE
    Channel=Channel or "CHAT"
  elseif Type=="NEGATIVE" or Type=="GOESNEGATIVE" then
    Color=Color or QDKP2_COLOR_YELLOW
    Channel=Channel or "CHAT"
  end

  local Announce
  if Type == "AWARD" and QDKP2_AnnounceAwards then
    Announce = tostring(msg)
  elseif Type == "DKP" and QDKP2_AnnounceDKPChange then
    Announce = tostring(msg)
  elseif Type == "IRONMAN" and QDKP2_AnnounceIronman then
    Announce = tostring(msg)
  elseif Type == "GOESNEGATIVE" and QDKP2_AnnounceNegative then
    Announce = tostring(msg)
  elseif Type == "TIMERTICK" and QDKP2_AnnounceTimertick then
    Announce = tostring(msg)
  elseif Channel == "CHAT" then        --this is to avoid printing 2 times the same thing.
    DEFAULT_CHAT_FRAME:AddMessage(QDKP2_COLOR_GREY.."QDKP2> "..Color..tostring(msg)..QDKP2_COLOR_CLOSE)
  end

  if Announce then
    local channel=string.upper(QDKP2_AnnounceChannel)
    if ((channel ~= "RAID" and channel ~= "PARTY") or QDKP2_IsRaidPresent()) then
      ChatThrottleLib:SendChatMessage("NORMAL","QDKP2","QDKP2> "..Announce, channel);
    end
  end
end

function QDKP2_SendHiddenWhisper(lines,towho)
  if type(lines)=='string' then lines={lines}; end
  for i,line in pairs(lines) do
    local msg="QDKP> "..line
    QDKP2suppressWhispers['>'..towho..msg]=true
    ChatThrottleLib:SendChatMessage("NORMAL","QDKP2",msg,"WHISPER",nil,towho)
  end
end

function QDKP2_SuppressIncomingWhisper(who,what)
  QDKP2suppressWhispers['<'..who..what]=true;
end


function QDKP2_GetItemFromText(txt)
  local _, _, item = string.find(txt, "|c%x+|H(.+)|h%[.*%]")
  local printable = gsub(txt, "\124", "\124\124");
  return item
end



--------------------- STRING SERVICES ----------------------

function QDKP2_FormatName(name)
--formats the name properly.  ie airiena would become Airiena
--Unicode compatible

  assert(type(name)=='string')
  if #name<1 then return ""; end
  if #name==1 then return string.upper(name); end
  local till=1
  for i=1,#name do  --this is to get the real first character (UTF8)
    --if i==#name then return string.upper(name); end
    local char=strbyte(name,i+1)
    if not char or (char<128 or char>191)  then break; end
    i=i+1
    till=i
  end
  local first = string.sub(name, 1, till)
  local remainder = string.sub(name, 2)
  local output = string.upper(first)..string.lower(remainder)
  return output
end


function QDKP2_UTF8len(str)
  if #str<=1 then return #str; end
  l=0
  for i=1,#str do
    local char=strbyte(str,i)
    if char<128 or (char>193 and char<245) then l=l+1; end
  end
  return l
end


function QDKP2_CutString(txt,len)
-- Cuts txt if is longer than len, adding two dots at the end.
  if #txt>len then
    txt=string.sub(txt,1,len-2)..'..'
  end
  return txt
end

function QDKP2_CenterString(txt,len)
--This adds whitespaces before and after txt to center it in a field of len characters
  local sect=len-QDKP2_UTF8len(txt)
  txt=string.rep(' ',math.floor(sect/2))..txt..string.rep(' ',math.ceil(sect/2))
  return txt
end


function QDKP2_SplitString(txt,delimiter)
--returns a list of substring of txt usind delimeter to break them.
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( txt, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( txt, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( txt, delimiter, from  )
  end
  table.insert( result, string.sub( txt, from  ) )
  return result
end

function QDKP2_GetClassColor(class)
  local colors
  if class then
    class=QDKP2classEnglish[class] or class
    colors=RAID_CLASS_COLORS[class:upper()]
  end
  colors=colors or {r=0.5,g=0.5,b=0.5}
  return colors
end




--------------------------------
--QDKP2_GetDateTextFromTS
--Convert a plain timestamp (Seconds since the epoch) to a human redable date, applying
--the QDKP2 format and settings.
function QDKP2_GetDateTextFromTS(Time)
  if not Time or type(Time)~='number' then return "-"; end
  local datestring = ""
  local entryTime = math.floor(Time)
  if not entryTime then return "Invalid Timestamp"; end
  local nowTime = time()
  if date("%x",nowTime) == date("%x",entryTime) or nowTime-entryTime < 3600 * QDKP2_DATE_TIME_TO_HOURS then
    datestring = date("%H:%M:%S",entryTime)
  elseif nowTime-entryTime < 86400 * QDKP2_DATE_TIME_TO_DAYS + tonumber(date("%H",nowTime))*3600 + tonumber(date("%M",nowTime))*60 then
    datestring = date("%a %H:%M",entryTime)
  else
    datestring = date("%d/%m %H:%M",entryTime)
  end
  return datestring
end

--------------------- LIST SERVICES ------------------------

--appends spaces to the end to help formatting in lists
function QDKP2_AppendSpace(text, number)
  local temp = ""
  for i=0, number do
    temp = temp.." "  --adds x number of spaces
  end
  text = text..temp   --adds spaces to text
  return text
end

--returns a copy of the list. if destList is given copies the data there.
function QDKP2_CopyTable(list,destList)
  local output = destList or {}
  for i,v in pairs(list) do output[i]=v; end
  return output
end

-- Inverts a list
function QDKP2_Invert(list)
  local output = {}
  for i=table.getn(list), 1, -1 do
    table.insert(output,list[i])
  end
  return output
end


--returns a list with all the key of the dictionary passed.
function ListFromDict(dict)
  ListFromDict_output = {}
  table.foreach(dict,function (key, value) table.insert(ListFromDict_output,key); end)
  return ListFromDict_output
end


--returns a dictionary from a list. all index
function DictFromList(list,content)
  local output = {}
  for i=1,#list do
    output[list[i]] = content
  end
  return output
end


--returns a table for random indexing
function QDKP2_RandTable(n)
  local output={}
  for i=1,n do
    local position=math.ceil(i*math.random())
    table.insert(output,position,i)
  end
  return output
end


 function QDKP2_netSort(nameList) --sorts a list of guildmebers by inverse net.
  table.sort(nameList, function(v1,v2)
    local net1=QDKP2_GetNet(v1)
    local net2=QDKP2_GetNet(v2)
    if net1>net2 then return true; end
  end)
end

--[[
function MergeLists(L1,L2)
  local o={}
  for i=1,#L1 do table.insert(o,L1[i]); end
  for i=1,#L2 do table.insert(o,L2[i]); end
  return o
end
]]--
--------------------- MATHS SERVICES -------------------------------

-- Rounds a given float to the nearest integer.
function RoundNum(number)
  local CeilValue = math.ceil(number)
  local FloorValue = math.floor(number)
  if math.abs(number - CeilValue) < math.abs(number - FloorValue) then
    return CeilValue
  else
    return FloorValue
  end
end


--I took this from RBDKP (a similar DKP mod) with no modification.  Why change something perfect.
--[[
function QDKP2_GetArgs(message, separator)
  local args = {};
  local i = 0;

  for value in string.gmatch(message, "[^"..separator.."]+") do
    i = i + 1;
    args[i] = value;
  end

  return args;
end
]]--

