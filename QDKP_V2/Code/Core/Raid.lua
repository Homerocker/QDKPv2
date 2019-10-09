-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--               Raid Functions
--
--      The common interface to the ongoing raid/party. Gives a updater tool to parse the data and
--      some utilities that mimes the common WoW APIs.
--      These function will refere to the raid or, if absent, to a party, giving a uniform interface for both.
--
--  API Documentation:
--      QDKP2_UpdateRaid(): Builds a list of players in the current raid (that are in the guild).
--      QDKP2_IsInRaid(name): returns true if <name> is in party/raid.
--      QDKP2_IsRaidPresent(): returns true if you are in a party/raid.
--      QDKP2_GetRaidRosterInfo(i): returns infos about the <i>th member of the party/raid
--      QDKP2_GetNumRaidMembers(): returns the number of the members of the party/raid you are cuurently in
--      QDKP2_AddStandby(name): adds <name> to the raid roster as stadby. must be a valid guild member name and not in real raid.
--      QDKP2_RemStandby(name): removes <name> from the standby list. Must be a standby member (added with AddStandby)
--      QDKP2_IsStandby(name): returns true if <name> is a standby member.
--      QDKP2_RemoveFromRaid(name,todo): if todo is nil or true will remove <name> from the raid roster. if false will include.
--      QDKP2_IsRemoved(name): returns true if <name> has been removed from raid roster


------------------------------------ LOCAL FUNCTIONS ------------------------------------
local function CheckDeleted()
  local tempRemoved={}
  table.foreach(QDKP2raidRemoved,function(key,value) tempRemoved[key]=true; end)
  for i=1,GetNumRaidMembers() do
    local name = GetRaidRosterInfo(i)
    if tempRemoved[name] then tempRemoved[name]=nil; end
  end
  local RemovedToDel=ListFromDict(tempRemoved)
  for i=1,#RemovedToDel do
	local name=RemovedToDel[i]
	QDKP2_Debug(2,"Update", name.." was deleted from raid but left it. Removing deleted status,,,")
	QDKP2raidRemoved[name]=nil
  end
end


local function FindLeavers(name,left)
  if left then
    if QDKP2raidRemoved[name] then
      QDKP2log_Entry(name, QDKP2_LOC_RemRaid, QDKP2LOG_LEFT)
    else
      QDKP2log_Entry(name, QDKP2_LOC_LeftRaid, QDKP2LOG_LEFT)
    end
  end
end

-------------------------------------- RAID REFRESH -------------------------------------

--this function build a new list of raid members (that are in guild), and checks for
--members who left/joined.

function QDKP2_UpdateRaid()

  if not QDKP2_ACTIVE then
    QDKP2_Debug(1, "Update","Aborting Raid Update, I am not ready")
    return
  end

  QDKP2_Debug(3, "Update","Updating Raid Data")

  local Manag=QDKP2_ManagementMode()

  local EnterRaid = false
  if #QDKP2raid == 0 then
    EnterRaid = true
  end

  local raidList={}
  local skippedNames={}
  local NameList = DictFromList(QDKP2raid, true)
  local raidListNameCon = DictFromList(QDKP2raid, true)
  local StandbyDict = DictFromList(QDKP2standby, true)
  local gotChanges
  CheckDeleted()

  if QDKP2_IsRaidPresent() then
    if EnterRaid then QDKP2_IJoinedRaid(); end
    for i=1, QDKP2_GetNumRaidMembers() do
      local name, rank, subgroup, level, class, fileName, zone, online, inguild, standby, removed = QDKP2_GetRaidRosterInfo(i);
      if name then --this is to avoid exception due to a broken raid roster OR when you are in a battleground raid.
        QDKP2_Debug(3,"Update","Updating raid status for "..name)
        if not standby then
          if StandbyDict[name] then
            QDKP2_RemStandby(name)
            if Manag then
              local Msg=QDKP2_LOC_ExtJoins
              Msg=string.gsub(Msg,"$NAME",name)
              QDKP2_Msg(QDKP2_COLOR_YELLOW..Msg)
              QDKP2log_Entry(name, QDKP2_LOC_JoinsActive, QDKP2LOG_JOINED)
              gotChanges=true
            end
            QDKP2_UpdateRaid()
            return
          end
        end
        if rank == 2 then QDKP2_RaidLeaderZone=zone; end
        if inguild and not removed then
          QDKP2_Debug(3,"Raid","Is in guild, adding to roster.")
          table.insert(raidList,name)
          raidListNameCon[name] = false
          if Manag and not NameList[name] then --wasn't in the raid, joins now
            if standby then
              QDKP2log_Entry(name, QDKP2_LOC_JoinsRaidSby, QDKP2LOG_JOINED)
            end
            if not online then
              QDKP2log_Entry(name,QDKP2_LOC_IsInRaidOffline,QDKP2LOG_LEFT)
   --         elseif EnterRaid then
   --           QDKP2log_Entry(name, QDKP2_LOC_IsInRaid, QDKP2LOG_JOINED)
            elseif not standby then
              QDKP2log_Entry(name, QDKP2_LOC_JoinsRaid, QDKP2LOG_JOINED)
            end
            gotChanges=true
          elseif NameList[name] then        --check for online/ofline
            OnOfflineStatus=QDKP2raidOffline[name]
            if (not OnOfflineStatus or OnOfflineStatus == "online") and not online then
              if Manag then QDKP2log_Entry(name,QDKP2_LOC_GoesOffline,QDKP2LOG_LEFT); end
              gotChanges=true
            elseif OnOfflineStatus == "offline" and online then
              if Manag then QDKP2log_Entry(name,QDKP2_LOC_GoesOnline,QDKP2LOG_JOINED); end
              gotChanges=true
            end
          end
          if online then
            QDKP2raidOffline[name]= "online"
          else
            QDKP2raidOffline[name]= "offline"
          end
        elseif not inguild then
          table.insert(skippedNames, name)
        end
      end
    end

    if table.getn(QDKP2raid) ~= table.getn(raidList) and QDKP2_ALERT_NOT_IN_GUILD then
      if(table.getn(skippedNames)>1)then  --formats the skipped names
        local namesstring=""
        for i=1, table.getn(skippedNames) do
          namesstring = namesstring..skippedNames[i]

          if(skippedNames[i+1]~=nil)then
            namesstring=namesstring..", "
          end
        end
        local msg=string.gsub(QDKP2_LOC_NoInGuild,"$NAMES",namesstring)
        QDKP2_Msg(QDKP2_COLOR_RED..msg)
      elseif(table.getn(skippedNames) == 1) then
        local msg=string.gsub(QDKP2_LOC_NoInGuild,"$NAMES",skippedNames[1])
        QDKP2_Msg(QDKP2_COLOR_RED..msg)
      end
    end
    if Manag then table.foreach(raidListNameCon, FindLeavers); end
  else
    table.wipe(QDKP2raidOffline)
    if #QDKP2raid >= 1 then -- if i had raid and now i have it no more means that i left (o'rly?)
      QDKP2_ILeftRaid()
      gotChanges=true
    end
  end
  table.wipe(QDKP2raid)
  QDKP2_CopyTable(raidList,QDKP2raid)
  QDKP2_Sort_Lastn=-1
  if gotChanges then QDKP2_Events:Fire("DATA_UPDATED","all"); end
end


function QDKP2_IsInRaid(namePlayer) --returns true if the player is in the raid
  for i=1, QDKP2_GetNumRaidMembers() do
    local name = QDKP2_GetRaidRosterInfo(i);
    if name==namePlayer then
      return true
    end
  end
end


function QDKP2_IsRaidPresent()
  if QDKP2_GetNumRaidMembers() > 0 then return true
  end
end



function QDKP2_GetRaidRosterInfo(i)
  local name, rank, subgroup, level, class, localClass, fileName, zone, online, inguild, standby, removed
  local GroupSize=0
  local RaidSize=GetNumRaidMembers()
  local PartySize=GetNumPartyMembers()
  if RaidSize>0 then
    GroupSize=RaidSize
  elseif PartySize>0 then
    GroupSize=PartySize+1
  end
  if not (i > GroupSize) then
    if RaidSize>0 then
      local unit="raid"..tostring(i)
      name, rank, subgroup, level, class, fileName, zone, online = GetRaidRosterInfo(i)
    else
      local unit
      if i==1 then unit="player"
      else unit="party"..tostring(i-1)
      end
      name=UnitName(unit)
      level=UnitLevel(unit)
      class=UnitClass(unit)
      zone="Party"
      online=QDKP2online[name]
      rank=0
      subgroup=1
      standby=false
    end
    if QDKP2_IsExternal(name) then
      QDKP2externals[name].class=class
    end
  elseif not (i- GroupSize > table.getn(QDKP2standby)) then
    name=QDKP2standby[i-GroupSize]
    standby=true
    level=80 --i don't use the raid roster to get the level anyway
    class=QDKP2class[name]
    online=QDKP2online[name]
    zone="Standby"
  end
  if QDKP2_IsInGuild(name) then inguild=true; end
  if QDKP2raidRemoved[name] then removed=true;end
  return name, rank, subgroup, level, class, fileName, zone, online, inguild, standby, removed
end

function QDKP2_GetNumRaidMembers()
 local total=0
 local RaidMembers=GetNumRaidMembers()
 local PartyMembers=GetNumPartyMembers()
 if RaidMembers>0 then total=RaidMembers
 elseif PartyMembers>0 then total=PartyMembers+1
 end
 total=total + #QDKP2standby
 return total
end


function QDKP2_AddStandby(name)
  if not QDKP2_ManagementMode() then QDKP2_NeedManagementMode(); return; end
  QDKP2_Debug(2,"Raid","Adding "..tostring(name).." to the standby list")
  if QDKP2_IsInRaid(name) then
    QDKP2_Debug(1,"Raid",name.." is already in the raid.")
    return
  elseif QDKP2_IsInGuild(name) then table.insert(QDKP2standby,name)
  else
    QDKP2_Debug(1,"Raid","Trying to add a standby that is not in the guild. ("..name..')')
    return
  end
  QDKP2_UpdateRaid()
  return true
end

function QDKP2_RemStandby(name)
  local StandbyIndex=QDKP2_IsStandby(name)
  if StandbyIndex then
    QDKP2_Debug(2,"Logging","Removing "..name.." from the standby list")
    table.remove(QDKP2standby,StandbyIndex)
  else
  end
  QDKP2_UpdateRaid()
  return true
end

function QDKP2_IsStandby(name)
  for i,v in pairs(QDKP2standby) do
    if v==name then
      return i
    end
  end
end

function QDKP2_RemoveFromRaid(name,todo)
  if not QDKP2_ManagementMode() then QDKP2_NeedManagementMode(); return; end
  if todo ~= false then
    QDKP2_Debug(2,"Raid","Removing "..tostring(name).." from Raid Roster")
    local NameList = DictFromList(QDKP2raid, true)
    if NameList[name] and not QDKP2_IsRemoved(name) then
      QDKP2raidRemoved[name] = true
    elseif QDKP2_IsRemoved(name) then
      QDKP2_Debug(1,"Raid","Trying to remove "..name.." who is not in the Raid roster")
      return
    end
  else
    if QDKP2_IsRemoved(name) then
      QDKP2raidRemoved[name]=nil
    else
      QDKP2_Debug(1,"Raid","Trying to unremove "..name.." from raid roster but he wasn't removed.")
      return
    end
  end
  QDKP2_UpdateRaid()
end

function QDKP2_IsRemoved(name)
  return QDKP2raidRemoved[name]
end
