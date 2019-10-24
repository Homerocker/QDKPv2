-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--             Bid Manager Functions
--
--      Function to detect, import and manages bids
--
-- API Documentation:
-- QDKP2_BidM_Start(item): Starts a new bidding for ITEM. item is not mandatory, but highly raccomanded.
-- QDKP2_BidM_CancelBid(): Stops the current bidding (if any) and cancels all bids.
-- QDKP2_BidM_Winner(winner): Process the winner. triggers countdown if set so, then announce if set so.
-- QDKP2_BidM_Reset(): Clears all the bids. Does not process notifications
-- QDKP2_BidM_Countdown(sec,winner): Triggers a countdown. if winner, triggers a win at end.
-- QDKP2_BidM_CountdownCancel(): Cancels an ongoing countdown
-- QDKP2_BidM_BidWatcher(text, sender, channel): Called by chat events to acquire potential loots
-- QDKP2_BidM_RollWatch(player,roll,rollLow,rollHigh): Called every time a /roll is detected.
-- QDKP2_BidM_CancelPlayer(name): Removes name from the bid list. Sends a message if set so.



--------------------- BID START/STOP --------------------------

function QDKP2_BidM_StartBid(item)
-- Starts a new bid. item is the string of the item to bid (or a generic reason)
  if QDKP2_BidM_LogBids and not QDKP2_ManagementMode() then
    QDKP2_NeedManagementMode()
    return
  end
  if QDKP2_BidM.BIDDING then
    QDKP2_BidM_CancelBid()
  elseif QDKP2_BidM.LIST then
    QDKP2_BidM_Reset()
  end
  QDKP2_BidM.ITEM = item
  QDKP2_BidM.LIST = {}
  QDKP2_BidM.BIDDING = true
  QDKP2_BidM.ACCEPT_BID = true
  if QDKP2_BidM_AnnounceStart and item and #item>0 then
    local mess=QDKP2_LOC_BidMStartString
    mess=string.gsub(mess,"$ITEM",tostring(QDKP2_BidM.ITEM or '-'))
    QDKP2_BidM_SendMessage(nil,"MANAGER","bid_start",mess)
  end
  if QDKP2_BidM_LogBids and item and #item>0 then
    local mess=QDKP2_LOC_BidStartLog
    mess=mess:gsub("$ITEM",tostring(QDKP2_BidM.ITEM or '-'))
		QDKP2log_Entry("RAID",mess, QDKP2LOG_BIDDING)
    QDKP2_Events:Fire("DATA_UPDATED","log")
  end
end

function QDKP2_BidM_CloseBid()
--stops the bidding. Does not clear the data.
  QDKP2_BidM.BIDDING = nil
  QDKP2_Events:Fire("DATA_UPDATED","roster")
end

function QDKP2_BidM_CancelBid()
-- Cancels the bidding
-- Clears the data
  if QDKP2_BidM_CountdownCount then QDKP2_BidM_CountdownCancel(); end
  if QDKP2_BidM_LogBids and QDKP2_BidM.ITEM and #QDKP2_BidM.ITEM>0 then
    local mess=QDKP2_LOC_BidCancelLog
    mess=mess:gsub("$ITEM",tostring(QDKP2_BidM.ITEM or '-'))
		QDKP2log_Entry("RAID",mess, QDKP2LOG_BIDDING)
    QDKP2_Events:Fire("DATA_UPDATED","log")
  end

  local tempSetting=QDKP2_BidM_AckRejBids    --avoids a crapload of "Your bid has been cancelled" messages
  QDKP2_BidM_AckRejBids=false
  for name,obj in pairs(QDKP2_BidM.LIST) do
    QDKP2_BidM_CancelPlayer(name)
  end
  QDKP2_BidM_AckRejBids=tempSetting

  if QDKP2_BidM_AnnounceCancel and QDKP2_BidM.ITEM and #QDKP2_BidM.ITEM>0 then
    local mess=QDKP2_LOC_BidMCancelString
    mess=string.gsub(mess,"$ITEM",tostring(QDKP2_BidM.ITEM or '-'))
    QDKP2_BidM_SendMessage(nil,"MANAGER","bid_cancel",mess)
  end

  QDKP2_BidM_CloseBid()
  QDKP2_BidM.ITEM=nil
  QDKP2_BidM_Reset()
end

function QDKP2_BidM_Reset()
-- Clears allthe bid. Does not stop a ongoing bidding.
  QDKP2_BidM.LIST={}
  QDKP2_Events:Fire("DATA_UPDATED","roster")
end



---------------------- BID QUERYING -----------------------
function QDKP2_BidM_GetBidderList()
  if not QDKP2_BidM.LIST then return {}; end
  local list=ListFromDict(QDKP2_BidM.LIST) or {}
  return list
end

function QDKP2_BidM_GetBidder(name)
--returns the bid object if name is a bidder, nil otherwise.)
  if not QDKP2_BidM.LIST then return; end
  return QDKP2_BidM.LIST[name]
end

---------------------- BID FINALIZATION -------------------


local function notify_winner(winner)
  if not QDKP2_BidM.LIST[winner] then
    QDKP2_Debug(1,"BidManager","Called award_winner with a winner that is not in the bid list")
    return
  end
  local bid=QDKP2_BidM.LIST[winner]
  if bid.value then
    if not QDKP2_UpdateBid(winner,bid,true) then return; end
  end
  local dkp = bid.dkp or bid.value
  if QDKP2_IsInGuild(winner) and dkp and dkp ~= 0 then
    dkp=math.floor(dkp)
    QDKP2_OpenToolboxForCharge(winner, dkp, QDKP2_BidM.ITEM)
  end
  if QDKP2_BidM_AnnounceWinner and QDKP2_BidM.ITEM and #QDKP2_BidM.ITEM>0 then
    if dkp and dkp ~= 0 then
      msg=QDKP2_LOC_BidMWinnerString
      msg=msg:gsub("$AMOUNT",tostring(dkp))
    else
      msg=QDKP2_LOC_BidMWinnerStringNoDKP
      local lootmethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod()
      if lootmethod == "master" and masterlooterPartyID == 0 and GetNumLootItems() ~= 0 then
        for ci = 1, 40 do
          if GetMasterLootCandidate(ci) == winner then
          for li = 1, GetNumLootItems() do
            if GetLootSlotLink(li) == QDKP2_BidM.ITEM then
            GiveMasterLoot(li, ci)
            break
            end
          end
          break
          end
        end
      end
    end
    msg=msg:gsub("$NAME",winner)
    msg=msg:gsub("$ITEM",QDKP2_BidM.ITEM or '-')
    QDKP2_BidM_SendMessage(nil,"MANAGER","bid_winner",msg)
  end
  if QDKP2_IsInGuild(winner) and QDKP2_BidM_LogBids and QDKP2_BidM.ITEM and #QDKP2_BidM.ITEM>0  then
    local mess=QDKP2_LOC_BidWinLog
    local timestamp=QDKP2_Timestamp()
    mess=mess:gsub("$ITEM",tostring(QDKP2_BidM.ITEM or '-'))
    QDKP2log_Entry(winner, mess, QDKP2LOG_BIDDING, nil, timestamp)
    if QDKP2_IsManagingSession() then QDKP2log_Link("RAID",winner,timestamp,QDKP2_OngoingSession()); end
    QDKP2_Events:Fire("DATA_UPDATED","log")
  end
  QDKP2_BidM_CloseBid()
end


function QDKP2_BidM_Winner(winner)
  if not QDKP2_BidM.LIST[winner] then
    QDKP2_Debug(1,"BidManager","Called award_winner with a winner that is not in the bid list")
    return
  end
  if QDKP2_BidM_CountStop then QDKP2_BidM_Countdown(winner)
  else notify_winner(winner)
  end
end


local function countdown_tick()
  if not QDKP2_BidM_CountdownCount then
    QDKP2_BidM_CountdownCancel()
    return
  end
  if QDKP2_BidM_CountdownCount>0 then
    local str='- '..tostring(QDKP2_BidM_CountdownCount)
    QDKP2_BidM_SendMessage(nil,"MANAGER","countdown",str)
    QDKP2_BidM_CountdownCount=QDKP2_BidM_CountdownCount-1
  elseif QDKP2_BidM_CountdownCount==0 then
    QDKP2_BidM_CountdownCancel()
    if QDKP2_BidM_CountdownWinner then
      notify_winner(QDKP2_BidM_CountdownWinner)
    end
  end
end

function QDKP2_BidM_Countdown(winner,sec)
-- Initializes a countdown (is set so), then annouce the winner (if given).
  if QDKP2_BidM_CountdownCount then QDKP2_BidM_CountdownCancel(); end --avoid double timers
  QDKP2_BidM_CountdownCount=sec or QDKP2_BidM_CountAmount
  QDKP2_BidM_CountdownWinner=winner
  QDKP2_BidM_CountdownTimer=QDKP2libs.Timer:ScheduleRepeatingTimer(countdown_tick, 1.5)
  countdown_tick()
end

function QDKP2_BidM_CountdownCancel()
  QDKP2_BidM_CountdownCount=nil
  QDKP2libs.Timer:CancelTimer(QDKP2_BidM_CountdownTimer,true)
end




------------------ BIDS DETECTOR ---------------------

function QDKP2_BidM_BidWatcher(txt,player,channel)
-- Watch for bids from raid. If detected, import them and do all the things as set in the configuration.
  QDKP2_Debug(3,"BidM","BidWatcher called. txt="..tostring(txt)..", player="..tostring(player)..", channel="..tostring(channel))
  if not QDKP2_BidM_isBidding() or not QDKP2_BidM.ACCEPT_BID then return; end
  if channel=="WHISPER" and not QDKP2_BidM_GetFromWhisper then return; end
  if channel~="WHISPER" and not QDKP2_BidM_GetFromGroup then return; end
  txt=string.lower(txt)
  txt=string.gsub(txt,"^[%s]+","")
  txt=string.gsub(txt,"[%s]+$","")
  table.insert(QDKP2_BidM_Keywords, {keywords="$nk, $nк",value="$n*1000"})
  for i,v in pairs(QDKP2_BidM_Keywords) do
    local kw=string.lower(v.keywords)
    kwl= QDKP2_SplitString(kw,',')
    for j,w in pairs(kwl) do
      local trigStr=w
      trigStr=string.gsub(trigStr,"$n","[0-9]+")
      trigStr=string.gsub(trigStr,"^[%s]+","")
      trigStr=string.gsub(trigStr,"[%s]+$","")
      trigStr="^"..trigStr.."$"
      if string.find(txt,trigStr) then
        QDKP2_Debug(2,"BidManager",'Found bid. Trig="'..trigStr..'"')
        if not QDKP2_IsInGuild(player) and not QDKP2_BidM_CanOutGuild then
          QDKP2_BidM_SendMessage(player,"NOBID",channel,QDKP2_LOC_BidNoGuild)
          return false
        end
        local oldBet=QDKP2_BidM.LIST[player]
        if QDKP2_BidM_AllowMultipleBid  or not (oldBet and oldBet.txt) then
          local _,_,bid=string.find(txt,"([0-9]+)")
          if not oldBet then oldBet={}; end
          local oldValue = oldBet.value
          local oldDkp = oldBet.dkp
          local newBet={}
          newBet.roll=oldBet.roll
          newBet.txt=txt
          newBet.bid_voice=v
          newBet.channel=channel
          newBet.trig_str=w
          newBet.bid=bid

          --updates the value and dkp variables. if returns nil, has encountered an error.
          if not QDKP2_UpdateBid(player,newBet) then return; end

          --controls
          --all controls must be made at bid time. Can't say at the end of the bid that the winner's bet is invalid.

          if not newBet.eligible then
            QDKP2_BidM_SendMessage(player,"NOBID",channel,QDKP2_LOC_NoEligible)
            return false
          end
          if newBet.value and oldValue then
            if oldValue==newBet.value then    --is it the same bid as the previous?
              QDKP2_BidM_SendMessage(player,"NOBID",channel,QDKP2_LOC_BidEqual)
              return false
            elseif oldValue>newBet.value and not QDKP2_BidM_AllowLesserBid then   --is the bid less then the previous?
              QDKP2_BidM_SendMessage(player,"NOBID",channel,QDKP2_LOC_BidLess)
              return false
            end
          end
          local dkp=newBet.dkp or newBet.value
          if dkp then
            if not QDKP2_BidM_OverBid and QDKP2_GetNet(player)<newBet.minBid then  --has the player enought dkp to bid at all?
              local mess=QDKP2_LOC_BidnoDKP
              mess=mess:gsub('$MINBID',tostring(newBet.minBid))
              mess=mess:gsub('$NET',tostring(QDKP2_GetNet(player)))
              QDKP2_BidM_SendMessage(player,"NOBID",channel,mess)
              return false
            elseif dkp < newBet.minBid then                               --does the bid reach the minimum bid amount?
              local mess=QDKP2_LOC_BidLessMinimum
              mess=mess:gsub("$MINBID",tostring(newBet.minBid))
              QDKP2_BidM_SendMessage(player,"NOBID",channel,mess)
              return false
            elseif newBet.maxBid and dkp > newBet.maxBid then
              local mess=QDKP2_LOC_BidMoreMaximum
              mess=mess:gsub("$MAXBID",tostring(newBet.maxBid))
              QDKP2_BidM_SendMessage(player,"NOBID",channel,mess)
              return false
            elseif not QDKP2_BidM_OverBid and dkp > QDKP2_GetNet(player) then --is the bid more than the player has?
              local txt=QDKP2_LOC_BidGreater
              txt=string.gsub(txt,"$NET",tostring(QDKP2_GetNet(player)))
              QDKP2_BidM_SendMessage(player,"NOBID",channel,txt)
              return false
            end
          end

          QDKP2_Debug(3,"BidM","Bid ok, adding to the list.")
          QDKP2_BidM.LIST[player]=newBet
          if QDKP2_BidM_CountdownCount then QDKP2_BidM_CountdownCancel(); end--if i'm doing a countdown, cancel it
          QDKP2_BidM_SendMessage(player,"ACK",channel,QDKP2_LOC_BidAck)
          if QDKP2_BidM_LogBids and QDKP2_BidM.ITEM and #QDKP2_BidM.ITEM>0 then
            local mess=QDKP2_LOC_BidPlaceLog
            mess=mess:gsub("$ITEM",QDKP2_BidM.ITEM)
            mess=mess:gsub("$BIDTEXT",txt or "-")
            if txt ~= tostring(newBet.value) then
              mess=mess..QDKP2_LOC_BidPlaceLogVal:gsub("$VALUE", tostring(newBet.value or "-"))
            end
            QDKP2log_Entry(player,mess, QDKP2LOG_BIDDING)
            QDKP2_Events:Fire("DATA_UPDATED","log")
          end
          QDKP2_Events:Fire("DATA_UPDATED","roster")
          return true
        else
          QDKP2_BidM_SendMessage(player,"NOBID",channel,QDKP2_LOC_CantRebid)
        end
        return false
      end
    end
  end
end


local function BidSorter(player1,player2)
  local value1=QDKP2_BidM.LIST[player1].value or -9999999999999
  local value2=QDKP2_BidM.LIST[player2].value or -9999999999999
  return value1<value2
end

local function EvaluateExpression(player,bid_obj,expr,bidList)
  local net=QDKP2_GetNet(player)
  local total=QDKP2_GetTotal(player)
  local spent=QDKP2_GetSpent(player)
  local sectopbid=bidList[#bidList-1]

  local mintowin=(sectopbid and sectopbid+1) or QDKP2_BidM_MinBid or 0  --mintowin is defined as the second greatest bid +1, but must be <= the top bid.
  if sectopbid and mintowin>QDKP2_BidM_MinBid and mintowin > bidList[#bidList] then mintowin=bidList[#bidList]; end

  for i=1,#bidList do
    expr=string.gsub(expr,"$lowerbid"..tostring(i),tostring(bidList[i]))
    expr=string.gsub(expr,"$higherbid"..tostring(#bidList-i+1),tostring(bidList[i]))
  end
  for i = 1,10 do
    expr=string.gsub(expr,"$lowerbid"..tostring(i),'nil')
    expr=string.gsub(expr,"$higherbid"..tostring(i),'nil')
  end

  expr=string.gsub(expr,"$net",tostring(net))
  expr=string.gsub(expr,"$total",tostring(total))
  expr=string.gsub(expr,"$spent",tostring(spent))
  expr=string.gsub(expr,"$roll",tostring(bid_obj.roll))
	expr=string.gsub(expr,"$vroll",tostring(bid_obj.roll)) --this is to bypass $roll keyword checking, if needed.
  expr=string.gsub(expr,"$minbid",tostring(QDKP2_BidM_MinBid))
  expr=string.gsub(expr,"$mintowin", tostring(mintowin))
  expr=string.gsub(expr,"$n",tostring(bid_obj.bid))  --must be last because it would bug all keywords that begin with n
  local Exec,value
  if bid_obj.asFunc then Exec,value=loadstring(expr)
  else Exec,value=loadstring("return "..expr)
  end
  if not Exec then return nil, value; end
  local callStat; callStat, value= pcall(Exec)
  if callStat and type(value)=='number' and QDKP2_BidM_RoundValue then value=RoundNum(value); end
  return callStat, value
end

function QDKP2_UpdateBid(player,bid_obj,finalUpdate)
-- this updates the value and dkp fields of a bid_obj.
-- finalupdate must be set to true if this is the update made by winnerbid.
  QDKP2_Debug(3,"BidM","Updating bid values for "..tostring(player))
  bid_obj=bid_obj or {}
  bid_voice=bid_obj.bid_voice or {}
  local good
  local bidList={}
  for iplayer,ibid in pairs(QDKP2_BidM.LIST) do
    if ibid.value then table.insert(bidList,ibid.value); end
  end
  table.sort(bidList)

  --auto-roll if enabled and needed
  if not bid_obj.roll and
		string.find(tostring(bid_voice.value)..tostring(bid_voice.dkp)..tostring(bid_voice.min)..tostring(bid_voice.max)..tostring(bid_voice.eligible),"$roll") then
		if QDKP2_BidM_AutoRoll then
			bid_obj.roll=math.random(1,100)
			QDKP2_Debug(2,"BidM","Roll needed and not already detected. Silent rolling: "..tostring(bid_obj.roll))
		else
			QDKP2_BidM_SendMessage(player,"NOBID",bid_obj.channel,QDKP2_LOC_BidRollFirst)
		end
  end

  --eligibility calculation
  if  not bid_voice.eligible then bid_obj.eligible=true
  else
    local expr=bid_voice.eligible
    good,bid_obj.eligible=EvaluateExpression(player,bid_obj,expr,bidList)
    if not good then
      local msg='Bidmanager: Error in "eligible" field!\n'..tostring(bid_obj.eligible).."\nExpression="..tostring(expr)
      if QDKP2_BidM_DebugValues then
        QDKP2_Msg(msg,"ERROR")
      else
        QDKP2_Debug(1,"BidM",msg)
      end
      return false
    end
    if not bid_obj.eligible then return true; end
  end

  -- min bid calculation
  bid_obj.minBid = QDKP2_BidM_MinBid
  if bid_voice.min then
    local expr=bid_voice.min
    good,bid_obj.minBid=EvaluateExpression(player,bid_obj,expr,bidList)
    if not good or not bid_obj.minBid or not tonumber(bid_obj.minBid) then
      local msg='Bidmanager: Error in "min" field!\n'..tostring(bid_obj.value).."\nExpression="..tostring(expr)
      if QDKP2_BidM_DebugValues then
        QDKP2_Msg(msg,"ERROR")
      else
        QDKP2_Debug(1,"BidM",msg)
      end
      return false
    end
  end

  --max bid calculation
  bid_obj.maxBid = QDKP2_BidM_MaxBid
  if bid_voice.max then
    local expr=bid_voice.max
    good,bid_obj.maxBid=EvaluateExpression(player,bid_obj,expr,bidList)
    if not good or not bid_obj.maxBid or not tonumber(bid_obj.maxBid) then
      local msg='Bidmanager: Error in "max" field!\n'..tostring(bid_obj.value).."\nExpression="..tostring(expr)
      if QDKP2_BidM_DebugValues then
        QDKP2_Msg(msg,"ERROR")
      else
        QDKP2_Debug(1,"BidM",msg)
      end
      return false
    end
  end

  -- bid_obj.value calculation
  if bid_voice.value or string.find(bid_obj.trig_str,"$n") then
    local expr=bid_voice.value or "$n"
    good,bid_obj.value=EvaluateExpression(player,bid_obj,expr,bidList)
    if not good or not bid_obj.value or not tonumber(bid_obj.value) then
      local msg='Bidmanager: Error in "value" field!\n'..tostring(bid_obj.value).."\nExpression="..tostring(expr)
      if QDKP2_BidM_DebugValues then
        QDKP2_Msg(msg,"ERROR")
      else
        QDKP2_Debug(1,"BidM",msg)
      end
      return false
    end
  end

  --the bid list (and the min bid) must be guessed here for initial bid evaluation.
  --I assume that the worst case scenario for a bid system is that we have other bids with the same values.
  --This can be wrong for very special bid systems, but i couldn't figure out a better way.
  if not finalUpdate then
    local context_bid=bid_obj.value or bid_obj.bid or bid_obj.minBid or 0
    bidList={context_bid, context_bid, context_bid} --3 should be enought.
  end

  --bid_obj.dkp calculation
  if bid_voice.dkp and #bid_voice.dkp>0 then
    local expr=bid_voice.dkp
    good,bid_obj.dkp=EvaluateExpression(player,bid_obj,expr,bidList)
    if not good or not bid_obj.dkp or not tonumber(bid_obj.dkp) then
      local msg='BidManager: Error in "dkp" field!\n'..tostring(bid_obj.dkp).."\nExpression="..expr
      if QDKP2_BidM_DebugValues then
        QDKP2_Msg(msg,"ERROR")
      else
        QDKP2_Debug(1,"BidM",msg)
      end
      return false
    end
  end
  return true
end


function QDKP2_BidM_SendMessage(player, t,  channel, txt)
  if (t=="ACK" and not QDKP2_BidM_AckBids)
  or (t=="NOBID" and not QDKP2_BidM_AckRejBids) then
    return
  end
  if      channel == "bid_start" then channel=QDKP2_BidM_ChannelStart
  elseif channel == "bid_cancel" then channel=QDKP2_BidM_ChannelCanc
  elseif channel == "bid_winner" then channel=QDKP2_BidM_ChannelWin
  elseif channel == "countdown" then channel=QDKP2_BidM_ChannelCount
  end

  if channel== "RAID_WARNING" and not IsRaidOfficer() then channel="GROUP"; end

  if channel == "GROUP" then
    if GetNumRaidMembers()>0 then channel="RAID"
    elseif GetNumPartyMembers()>0 then channel="PARTY"
    elseif player then channel="WHISPER"
    else channel=nil
    end
  end

  if channel == "WHISPER" then
    QDKP2_SendHiddenWhisper(txt,player)
  elseif channel then
    if t=="ACK" or t=="NOBID" then txt=player..' - '..txt; end
    ChatThrottleLib:SendChatMessage("NORMAL", "QDKP2", txt, channel)
  end
end


function QDKP2_BidM_RollWatch(player,roll,rollLow,rollHigh)
  QDKP2_Debug(3,"BidManager","Got /roll by "..tostring(player)..": "..tostring(roll))

  if not QDKP2_BidM_isBidding() or not QDKP2_BidM_CatchRoll or not QDKP2_BidM.ACCEPT_BID then return; end

  if not QDKP2_IsInGuild(player) and not QDKP2_BidM_CanOutGuild then
    QDKP2_BidM_SendMessage(player,"NOBID","GROUP",QDKP2_LOC_BidNoGuild)
    return
  end

  if rollLow ~= 1 or rollHigh ~= 100 then
    QDKP2_BidM_SendMessage(player,"NOBID","GROUP",QDKP2_LOC_BidRollWrong)
    return
  end

  if not (QDKP2_BidM.LIST[player] and QDKP2_BidM.LIST[player].roll) then
    QDKP2_BidM.LIST[player] = QDKP2_BidM.LIST[player] or {}
    QDKP2_BidM.LIST[player].roll=roll
    QDKP2_BidM.LIST[player].channel="GROUP"
    --QDKP2_BidM_SendMessage(player,"ACK","GROUP",QDKP2_LOC_BidRollAck)
    if QDKP2_BidM_LogBids and QDKP2_BidM.ITEM and #QDKP2_BidM.ITEM>0 then
      local mess=QDKP2_LOC_BidRollsLog
      mess=mess:gsub("$ROLL",tostring(roll))
      mess=mess:gsub("$ITEM",QDKP2_BidM.ITEM)
			QDKP2log_Entry(player,mess, QDKP2LOG_BIDDING)
      QDKP2_Events:Fire("DATA_UPDATED","log")
    end
    QDKP2_BidM_BidWatcher("/roll",player,"GROUP")
    QDKP2_Events:Fire("DATA_UPDATED","roster")
  else
    QDKP2_BidM_SendMessage(player,"NOBID","GROUP",QDKP2_LOC_BidRollMulti)
  end
end


function QDKP2_BidM_CancelPlayer(name)
--  removes name from the bid.
  local bid=QDKP2_BidM.LIST[name]
  if bid then
    QDKP2_BidM.LIST[name]=nil
    QDKP2_Events:Fire("DATA_UPDATED","roster")
    QDKP2_BidM_SendMessage(name,"NOBID",bid.channel,QDKP2_LOC_BidRemove)
    QDKP2_Events:Fire("DATA_UPDATED","log")
  else
    QDKP2_Debug(1,"BidManager","Trying to remove a bidder that isn't in list.")
  end
end


function QDKP2_BidM_isBidding()
  return QDKP2_BidM.BIDDING
end








