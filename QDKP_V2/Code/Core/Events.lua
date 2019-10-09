-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--                Events Handler

-- These functions shouldn't be called by the user.



-------------------------------- Local Functions -----------------------------


--Searches for winners communications.
local function SearchForWinner(txt)
  QDKP2_Debug(3,"Core","Searching for winner in "..txt)
  local buildWord = ""
  local stringSize=string.len(txt)
  local amount
  local name
  local str=string.lower(txt)
  local FoundTrigger
  for  i,triggerW in pairs(QDKP2_WinTrigger) do
    if string.find(str, triggerW) then
      FoundTrigger=true
      QDKP2_Debug(2,"Core","Found triggering word "..triggerW.." in text")
      break
    end
  end

  if QDKP2_DetectBids and FoundTrigger then
    for i=1, stringSize do
      local char = string.sub(str,i,i)
      if (char ~= " " and char ~= "," and char ~= ".") then
        buildWord = buildWord .. char
      end
      if char == " " or char == "," or char == "." or i == stringSize then
        local numberTry = tonumber(buildWord)
        local FormatName = QDKP2_FormatName(buildWord)
        if numberTry then
          amount=numberTry
        elseif QDKP2_IsInGuild(FormatName) then
          name= FormatName
        end
        buildWord = ""
      end
    end
    if amount and name and QDKP2_ChatLootItem then
      QDKP2_OpenToolboxForCharge(name,amount,QDKP2_ChatLootItem)
    end
  end
end
-------------------------------------------------------------------------------------

function QDKP2_OnEvent(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
--Event manager
-- RECEIVER FOR THE MOBS DEATH EVENT
-- this is a very spammy event, so i put on top for performance matters.
  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    if arg2=="UNIT_DIED" and QDKP2_ManagementMode() and arg7 then     --fired when an hostile mob dies nearby
      local boss=arg7
      if boss and QDKP2_IsInBossTable(boss) then
        QDKP2_Debug(2,"Core","SlainDetector triggers a boss kill:"..boss)
        QDKP2_BossKilled(boss)
      end
    end
    return
  end

-- ADDON SUCCESSFULLY LOADED
 -- if (event == "ADDON_LOADED") then  --fired on succesfil addon load (all stored var are ready)
 --   if arg1 == "QDKP_V2" then  --in arg1 you have the name of the addon loaded
 --     QDKP2_OnLoad()
 --   end

 QDKP2_Debug(3,"Core","Event received: "..tostring(event)..", "..tostring(arg1)..", "..tostring(arg2)..", "..tostring(arg3))

-- PLAYER ENTERS WORLD
  if event== "PLAYER_ENTERING_WORLD" and not QDKP2_TimeDelta then
    QDKP2_Debug(2,"Init","Player entered world.")
    QDKP2_EnteredWorld=true
    QDKP2libs.Timer:ScheduleTimer(function()
    if not QDKP2_ACTIVE then
      QDKP2_Debug(2,"Init","Giving up, I assume you aren't in guild.")
      QDKP2_OnLoad()
    end
    end, 10)

-- RAID/PARTY ROSTER UPDATED
  elseif(event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED") then  --fired on raid members add/leave, maybe even on loot change
    if QDKP2GUI_Roster then QDKP2GUI_Roster.Sort.LastLen = -1; end --this forces a resort.
    QDKP2_UpdateRaid()


-- GUILD ROSTER UPDATED
  elseif(event ==  "GUILD_ROSTER_UPDATE") then  --fired when a new fresh guild cache is downloaded.
    if GetNumGuildMembers(true) > 0 then
      if QDKP2_EnteredWorld and not QDKP2_ACTIVE then QDKP2_OnLoad(); end
      --QDKP2_Msg("Guild updated")
      QDKP2_REFRESHED_GUILD_ROSTER = true
      QDKP2_RefreshGuild()
      if QDKP2GUI_Roster then QDKP2GUI_Roster.Sort.LastLen = -1; end --this forces a resort.
    end

--WHISPER SNIFFER
  elseif event=="CHAT_MSG_WHISPER" then
		if QDKP2processedWhispers ~= time()..arg2..arg1 then
			local answer = QDKP2_OD(arg1, arg2)
			if answer then
				if not QDKP2_OS_VIEWWHSP then QDKP2_SuppressIncomingWhisper(arg2,arg1) end
				QDKP2_Debug(2,"Core", "OD system triggered by "..arg2..": "..arg1)
				QDKP2_SendHiddenWhisper(answer,arg2)
			else
				if QDKP2_BidM_isBidding() then
					local goodBid = QDKP2_BidM_BidWatcher(arg1,arg2,"WHISPER")
					if goodBid~=nil and QDKP2_BidM_HideWispBids then --BidWatcher returns nil if it doesn't find any bid word.
						QDKP2_SuppressIncomingWhisper(arg2,arg1)
					end
				end
			end
		end
		QDKP2processedWhispers=time()..arg2..arg1

--RAID CHAT SNIFFER
  elseif event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_WARNING" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_PARTY" then
    local channel='RAID'
    if event=='CHAT_MSG_PARTY' then channel='PARTY'; end
    if QDKP2_BidM_isBidding() then QDKP2_BidM_BidWatcher(arg1,arg2,channel); end
    QDKP2_OnGroupChat(arg1,arg2,arg3)

-- ROLLS MONITOR
  elseif event=="CHAT_MSG_SYSTEM" and QDKP2_BidM_isBidding() then
    local player,roll,rollLow,rollHigh=QDKP2libs.Deformat(arg1,RANDOM_ROLL_RESULT)
    if player then QDKP2_BidM_RollWatch(player,roll,rollLow,rollHigh); end

  end



  --here begin the events that are used only by dkp management functions.
  if not QDKP2_ACTIVE or not QDKP2_ManagementMode() then return; end

-- Addon message
  if event=="CHAT_MSG_ADDON" then
    --this is to detect boss deaths using bigwigs.
    --I use it only if DBM is not present, because this can be exploitable by a raid member
    if arg1 == "BigWigs" and string.sub(arg2,1,5) == "Death" and not DBM then
      local name=string.sub(arg2,7)
      QDKP2_Debug(2,"Core","BigWigs triggered a boss kill: "..name)
      QDKP2_BossKilled(name)
    end

-- LOOT SNIFFER
  elseif (event == "CHAT_MSG_LOOT" ) then  --fired on a loot
    QDKP2_Debug(2,"Core","Loot detected: "..arg1)
    local name, itemString=QDKP2libs.Deformat(arg1, LOOT_ITEM)
    if not itemString then
      itemString = QDKP2libs.Deformat(arg1, LOOT_ITEM_SELF)
      name=UnitName('player')
    end
    if not itemString then
      itemString = QDKP2libs.Deformat(arg1, LOOT_ITEM_PUSHED_SELF)
      name=UnitName('player')
    end
    if not itemString then
      QDKP2_Debug(2,"Core","Quitting OnLoot because no item could be located in the loot string.")
      return
    end
    if not QDKP2_IsInGuild(name) then
      QDKP2_Debug(3,"Core","Quitting OnLoot because "..name.." is not a guild member!")
      return
    end
    local item=QDKP2_GetItemFromText(itemString)
    if not item then
      QDKP2_Debug(1,"Core","Quitting OnLoot because i can't extract item from "..itemString)
      return
    end
    itemString=string.gsub(itemString,"^|c%x+|H.+|h%[.*%]","")  --remove the itemLink
    local _,_,itemQty=string.find(itemString,"([0-9]+)")       --the quantity should be the only number still there.
    itemQty=tonumber(itemQty) or 1
    QDKP2_Debug(3,"Core","Unpacked as "..item.." x"..tostring(itemQty).." looted by "..name)
    QDKP2_OnLoot(name, item, itemQty)

  end
end

----------------------- HANDLERS ------------------------------------
--I Use deformat to get the loot variables. Can have problems if you play with a
--client with a different locale than the server (is it true?)


--Fired when you join a raid
function QDKP2_IJoinedRaid()
  QDKP2_Debug(2,"Update","Joined a group")
  table.wipe(QDKP2raidOffline)
  QDKP2libs.Timer:CancelTimer(QDKP2_CloseSessionTimer,true)
  if QDKP2_isTimerPaused() then QDKP2_TimerPause("off","Raid"); end
end

--Fired when i leave the raid
function QDKP2_ILeftRaid()
  QDKP2_Debug(2,"Raid","You exit from raid.")
  if QDKP2_IsManagingSession() then
    QDKP2log_Entry(UnitName("player"), QDKP2_LOC_LeftRaid, QDKP2LOG_LEFT)
    QDKP2_AskUser(QDKP2_LOC_CloseSessionWithRaid, QDKP2_StopSession, true)
    QDKP2_CloseSessionTimer = QDKP2libs.Timer:ScheduleTimer(QDKP2_StopSession, 300, true)
    if QDKP2_isTimerOn() then QDKP2_TimerPause("on","Raid"); end
  end
end

-- Raid/party chat handler
function QDKP2_OnGroupChat(arg1,arg2,arg3)
  QDKP2_Debug(3,"Core","Got group chat")
  local itemStr = QDKP2_GetItemFromText(arg1)
  if itemStr then
    itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, invTexture = GetItemInfo(itemStr)
    if not itemLink then return; end
    QDKP2_Debug(2,"Core","Found "..tostring(itemLink).." in the chat!")
    if itemName then
      if itemRarity >= MIN_CHARGABLE_CHAT_QUALITY then
        QDKP2_ChatLootItem=itemLink
      end
      if itemRarity >= MIN_LISTABLE_QUALITY then
        QDKP2frame3_reasonBox:AddHistoryLine(itemLink)
      end
    end
  end
  if QDKP2_DetectBids then SearchForWinner(arg1); end
end


--chat handler. This hooks the standard chat handler. Used to intercept QDKP2 OD whispers.
function QDKP2_ChatMsgHandler(...)
  if not arg1 or not arg2 then QDKP2_OriginalChatMsgHandler(...); return; end
  if event=="CHAT_MSG_WHISPER_INFORM" and QDKP2suppressWhispers['>'..arg2..arg1] then
    QDKP2suppressWhispers['>'..arg2..arg1]=nil
    QDKP2_Debug(2,"Core", "OD answer intercepted!")
		return
  elseif event=="CHAT_MSG_WHISPER"  and QDKP2suppressWhispers['<'..arg2..arg1] then
    QDKP2suppressWhispers['<'..arg2..arg1]=nil
    QDKP2_Debug(2,"Core", "OD whisper intercepted!")
		return
  elseif event=="CHAT_MSG_WHISPER" and QDKP2processedWhispers~=tostring(time)..arg2..arg1 then
	  QDKP2_OnEvent(...) --this is because sometime ChatMsgHandler get called before the CHAT_MSG_WHISPER event.
		if QDKP2suppressWhispers['<'..arg2..arg1] then
      QDKP2_Debug(2,"Core", "Tricky OD whisper fixed!")
      QDKP2suppressWhispers['<'..arg2..arg1]=nil
			return
		end
	end
  QDKP2_OriginalChatMsgHandler(...)
end



-- This is to connect to the Deadly Boss Mod for boss kills.
function QDKP2_DBMBossKill(event,Encounter)
  if not QDKP2_ManagementMode() then return; end
  local name=Encounter.combatInfo.name
  QDKP_PD=Encounter
  QDKP2_Debug(2,"Core","DBM triggered a boss kill: "..name)
  QDKP2_BossKilled(name)
end

-- this is used to refresh the guild cache update timeout
function QDKP2_TimeToRefresh()
  if IsInGuild() then GuildRoster()
  else
    QDKP2_Debug(3, "Update", "No guild detected, refreshing guild roster from local data")
--dunno if it makes sense, but this will keep refreshing Guild Roster even
--if you aren't in a guild.
    QDKP2_RefreshGuild()
  end
end


--[[
--Events callbacks
QDKP2_Events= {
  Handlers={},
  Fire = function (self,event,arg1,arg2,arg3,arg4,arg5)
    print("firing "..event,self.Handlers[event])
    if not self.Handlers[event] then return; end
    table.foreach(self.Handlers[event],function(key,value)
      value(arg1,arg2,arg3,arg4,arg5)
      end
    )
  end,
  RegisterCallback= function (self,event,func)
    print("Registering "..event)
    self.Handlers[event]=func
  end
}
]]--

