-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--            DKP Managing interface
--
--      All functions involved in a Raid's DKP management.
--      This includes bonuses, charges and "hybrids" (like the zerosum share).
--
-- API Documentation:
--
-- RAID AWARD - ZEROSUM
-- QDKP2_RaidAward(amount, [Reason], [giverName]). Awards DKP to the raid OR makes Zerosums.
--
-- QDKP2_BossKilled(bossName) --Triggers a BossAward if the given bossName is in the QDKP2_Bosses table. Checks dungeon difficulty.
--
-- TIMER:
-- QDKP2_TimerOn(DoNotControl) --Starts the timer. if DoNotControl, doesn't check if you are in management mode.
-- QDKP2_TimerOff()            -- Stops the timer and discad data.
-- QDKP2_TimerPause(do)        -- Pause the timer. Works only if the timer is on. do='on' pauses, do='off' resumes.
-- QDKP2_isTimerPaused()       -- Returns true if the timer is actually paused.
-- QDKP2_TimerSetBonus(amount) -- Sets the hourly bonus to amount.
-- QDKP2_isTimerOn()           -- Returns true if the timer is on.
--
-- IRONMAN:
-- QDKP2_IronManStart()         -- Sets the start mark for the ironman bonus
-- QDKP2_IronManWipe()          -- clean any previously placed ironman mark
-- QDKP2_InronManFinish(BonusDKP) -- calculates the played net time for each player in session from the start mark and award
                                  -- the ones that reached a given threshold.
-- QDKP2_IronManIsOn()          -- returns true if i have the IronMan bonus still going.
--
-- CHARGING:
-- QDKP2_Decay(TypeOrList, Perc)        --reduces the net dkp of TypeOrList by perc. TypeOrList can be 'guild', 'raid' or a custom list.




--------- RAID AWARD / ZEROSUM

function QDKP2_RaidAward(amount,reason,giverName) --if giverName != nil, this will become a zerosum share.

-- Awards DKP to the raid, or makes zerosums if giverName is a valid guild member.
-- Amount: The amount od DKP to reward the raid OR the share amount.
-- Reason: Optional, a generic text to comment the operation.
-- giverName: Optional, if is a valid guild member he will be charged for amount and that amount will be shared in the active raid (ZeroSum)
-- This function should be error-proof in most cases, since is called almost directly by both the GUI and the command line interface.

  --initial controls
  if not QDKP2_ManagementMode() then
    QDKP2_NeedManagementMode()
    return
  end

  local SID=QDKP2_OngoingSession()

  if type(amount)=="string" then
    if giverName then amount=QDKP2_GetAmountFromText(amount,giverName)
    else amount=tonumber(amount)
    end
  end

  if not amount or RoundNum(amount)==0 then
    QDKP2_Debug(1,"RaidAward","Called RaidAward with "..tostring(amount).." DKP amount. Exiting...")
    return
  end
  amount=RoundNum(amount)

  if giverName and not QDKP2_IsChargeable(giverName, amount) then
    QDKP2_Debug(1,"RaidAward","Trying to make a zerosum share with an invalid giver: "..tostring(giverName))
    return
  elseif giverName and not QDKP2log[SID][giverName] then
        QDKP2_Msg(giverName.." is not in the current raid and thus cannot be used as source for the zerosum award.","ERROR")
        return
    end

  QDKP2_Debug(2,"RaidAward","RaidAward called. DKP="..amount..", Reason="..tostring(reason)..", Giver="..tostring(giverName))

  --common data initialization
  local timeStamp = QDKP2_Timestamp()
  local nameBase={}
  for i=1, QDKP2_GetNumRaidMembers() do
    local name, rank, subgroup, level, class, fileName, zone, online, inguild, standby, removed=QDKP2_GetRaidRosterInfo(i);
    if inguild and not removed then table.insert(nameBase,name); end
  end
  QDKP2_DoubleCheckInit()

    --this forks the values basing on the type of the award
  local Flags, AwardType
  local ReasonField=reason
  if giverName then
    AwardType = "zerosum"
    QDKP2_ProcessedMain(giverName) --to prevent the giver or one of his alts to get part in the share.
    Flags=QDKP2log_PacketFlags(nil,true)
    QDKP2log_Entry(giverName, reason, QDKP2LOG_MODIFY,  {nil, 0, nil}, timeStamp,Flags+4)
    ReasonField=QDKP2log_Link("RAID", giverName, timeStamp)
  else
    AwardType = "raidaward"
    Flags=QDKP2log_PacketFlags(true)
    QDKP2log_Entry("RAID",reason,QDKP2LOG_MODIFY, {0,nil,nil},timeStamp,Flags+4)
  end

  for i=1, QDKP2_GetNumRaidMembers() do
    local name, rank, subgroup, level, class, fileName, zone, online, inguild, standby, removed=QDKP2_GetRaidRosterInfo(i);
    if inguild and not removed and not QDKP2_IsMainAlreadyProcessed(name) then
      local InZone = zone == QDKP2_RaidLeaderZone or zone=="Offline"
      -- Checks if <name> is able to get the award.
      local eligible,percentage,NoReason=QDKP2_GetEligibility(name,AwardType,amount,online,inzone)

      if eligible then
        --Crea l'entry per dare l'award.
        QDKP2log_Entry(name,ReasonField,QDKP2LOG_MODIFY, {0, nil, nil, percentage}, timeStamp , Flags)
        QDKP2_ProcessedMain(name)
      elseif not QDKP2_AltsStillToCome(name, nameBase, i) then
        if NoReason then
          QDKP2log_Entry(name, ReasonField, QDKP2LOG_NODKP, {0, nil, nil}, timeStamp,Flags+QDKP2log_PacketFlags(nil,nil,nil,nil,NoReason))
          if QDKP2_AnnounceFailAw and QDKP2online[name] then
            local msg=QDKP2log_GetLastLogText(name)
            QDKP2_SendHiddenWhisper(msg,name)
          end
        else
          QDKP2_Debug(1,"RaidAward","Select case of why RaidAward/ZS has failed has failed. Player "..name)
        end
      end
    end
  end
  local Msg, MsgReason, Log
  if giverName then
    Log=QDKP2log_GetLastLog(QDKP2_GetMain(giverName))
    Msg=QDKP2_LOC_ZSRec
    MsgReason=QDKP2_LOC_ZSRecReas
--                                                   name,                Log,SID,newGained,newSpent,newHours,newCoeff,newReason, Activate, NoIncreaseVersion
    QDKP2log_SetEntry(QDKP2_GetMain(giverName),Log,SID,      nil,          amount,        nil,          nil,             nil,             nil,               true)
  else
    Log=QDKP2log_GetLastLog("RAID")
    Msg=QDKP2_LOC_Received
    MsgReason=QDKP2_LOC_ReceivedReas
--                                   name,Log,SID,newGained,newSpent,newHours,newCoeff,newReason, Activate, NoIncreaseVersion
    QDKP2log_SetEntry("RAID",Log,SID,  amount,         nil,            nil,            nil,             nil,           nil,               true)
  end
  if reason then Msg=MsgReason; end
  Msg=string.gsub(Msg,"$AMOUNT",tostring(amount))
  Msg=string.gsub(Msg,"$REASON",tostring(reason))
  Msg=string.gsub(Msg,"$NAME",tostring(giverName))
  QDKP2_Msg(Msg,"AWARD")
  QDKP2_Events:Fire("DATA_UPDATED","all")
  if (QDKP2_SENDTRIG_RAIDAWARD and not giverName) or (QDKP2_SENDTRIG_ZS and giverName) then
    QDKP2_UploadAll()
  end
end



--ZeroSum Award

function QDKP2_ZeroSum(giverName, amount, item)
  --this is a dummy to mantain compatibility after the inclusion of ZeroSum to RaidAward.
  QDKP2_Debug(1,"Core","Using deprecated QDKP2_ZeroSum function. User QDKP2_RaidAward instead.")
  if not giverName then
    QDKP2_Debug(1,"Core","Trying to make a zerosum with a nil amount")
  else
    QDKP2_RaidAward(amount,item,giverName)
  end
end


------------- TIMER -----------

function QDKP2_isTimerOn()
  if QDKP2timerBase.TIMER then return true; end
end

local function HoursTick()
--gives dkp on the hour
  QDKP2_Debug(2,"Timer","Timer tick")
  if QDKP_TIMER_RAIDLOG_TICK then
    local msg=string.gsub(QDKP2_LOC_RaidTimerLog,"$TIME",tostring(QDKP2_TIME_UNTIL_UPLOAD/60))
    QDKP2log_Event("RAID",msg)
  end

  local SomeoneAwarded

  --used for check for alts still to come
  local nameBase={}
  for i=1, QDKP2_GetNumRaidMembers() do
    local name, rank, subgroup, level, class, fileName, zone, online, inguild, standby, removed=QDKP2_GetRaidRosterInfo(i);
    if inguild and not removed then table.insert(nameBase,name); end
  end
  QDKP2_DoubleCheckInit(name)

  local toAdd = QDKP2_TIME_UNTIL_UPLOAD/60

  for i=1, QDKP2_GetNumRaidMembers() do
    local name, rank, subgroup, level, class, fileName, zone, online, inguild, standby, removed=QDKP2_GetRaidRosterInfo(i);
    QDKP2_Debug(3,"Timer","Doing "..name)
    local InZone = zone == QDKP2_RaidLeaderZone or zone=="Offline"

    if inguild and not removed and not QDKP2_IsMainAlreadyProcessed(name) then
      local eligible,percentage,reasonNo=QDKP2_GetEligibility(name, "timer", QDKP2timerBase.BONUS, online, inzone)
      if eligible then
        QDKP2_Debug(3,"Timer","Gets the time")

        local CurRaidTime=QDKP2timerBase[name] or 0
        local OrigHours = math.floor(CurRaidTime + 0.01)

        if QDKP2_StoreHours then
          QDKP2_AddTotals(name, nil, nil, toAdd, QDKP2_LOC_TimerTick, nil, nil, true)
        end
        QDKP2_ProcessedMain(name)
        QDKP2timerBase[name]=CurRaidTime + toAdd
        local NowHours = math.floor(QDKP2timerBase[name]+0.01)
        if NowHours ~= OrigHours then  --use this to detect if i've hit an integer (eg 2.9 + 0.2 = 3.1)
          QDKP2_Debug(3,"Timer","It's the hour for "..tostring(name))
          --QDKP2_AddTotals(name, QDKP2timerBase.BONUS, nil, nil, QDKP2_LOC_IntegerTime)
          QDKP2log_Entry(name, QDKP2_LOC_IntegerTime, QDKP2LOG_MODIFY,  {0, nil, nil,percentage})
          local Log=QDKP2log_GetLastLog(QDKP2_GetMain(name))
          --name, Log,SID,newGained,newSpent,newHours,newCoeff,newReason,Activate, NoIncreaseVersion
          QDKP2log_SetEntry(QDKP2_GetMain(name),Log,SID, QDKP2timerBase.BONUS, nil,        nil,          nil,                nil,             nil,               true)
          SomeoneAwarded = true
        end
      elseif QDKP2_IsMainAlreadyProcessed(name) then
        local a=1  --passa al prossimo
      elseif not QDKP2_AltsStillToCome(name, nameBase, i) then
        if reasonNo then
          QDKP2log_Entry(name, QDKP2_LOC_IntegerTime, QDKP2LOG_NODKP,  {QDKP2timerBase.BONUS, nil, nil},nil,QDKP2log_PacketFlags(nil,nil,nil,nil,reasonNo))
          QDKP2log_Entry(name, nil, QDKP2LOG_NODKP,  {nil, nil, toAdd},nil,QDKP2log_PacketFlags(nil,nil,nil,nil,reasonNo))
          if QDKP2_AnnounceFailHo and QDKP2online[name] then
            local msg=QDKP2log_GetLastLogText(name)
            QDKP2_SendHiddenWhisper(msg,name)
          end
        end
      end
    end
  end

  QDKP2_Msg(QDKP2_LOC_TimerTick,"TIMERTICK")
  if (SomeoneAwarded and QDKP2_SENDTRIG_TIMER_AWARD) or QDKP2_SENDTRIG_TIMER_TICK then
    QDKP2_UploadAll()
  else
    QDKP2_Events:Fire("DATA_UPDATED","all")
  end
end

function QDKP2_CheckHours()
--called every 1 second, checks the time since the last timer tick. if it's greater than
--QDKP2_TIME_UNTIL_UPLOAD it call the hour tick. i use this way rather than
--just using LibAce:Timer to call QDKP2_HoursTick() every tick because in this way
--i can save QDKP2timerBase and thus resuming it if i get a DC.
  QDKP2_Debug(3,"Core","Timer check")
  if QDKP2_isTimerOn() then
    if QDKP2_isTimerPaused() then
      QDKP2timerBase.TIMER = time() - QDKP2timerBase.PAUSE
    end
    if QDKP2_ManagementMode() then
      if (time() - QDKP2timerBase.TIMER) / 60  >= QDKP2_TIME_UNTIL_UPLOAD then
        QDKP2timerBase.TIMER = QDKP2timerBase.TIMER + (QDKP2_TIME_UNTIL_UPLOAD*60)
        HoursTick()
      end
      QDKP2_Events:Fire("TIMERBASE_UPDATED",QDKP2timerBase.TIMER+(QDKP2_TIME_UNTIL_UPLOAD*60),time())
    elseif not QDKP2_IsManagingSession() then --if i leave the raid/stop the session, close the timer.
      QDKP2_TimerOff()
    end
  end
end


function QDKP2_TimerOn(DoNotControl) -- start the timer
  if QDKP2_ManagementMode() or DoNotControl then
    if QDKP2_isTimerOn() then
      QDKP2_Msg(QDKP2_LOC_TimerResumed,"TIMERTICK")
    else
      table.wipe(QDKP2timerBase)
      QDKP2timerBase.TIMER = time()
      QDKP2_Msg(QDKP2_LOC_TimerStarted,"TIMERTICK")
      QDKP2log_Event("RAID",QDKP2_LOC_TimerStarted)
    end
    QDKP2_HourlyTimerObj=QDKP2libs.Timer:ScheduleRepeatingTimer(QDKP2_CheckHours, 1)
    QDKP2timerBase.BONUS=QDKP2timerBase.BONUS or 0
    QDKP2_Events:Fire("TIMER_START")
    QDKP2_CheckHours()
    QDKP2_Events:Fire("DATA_UPDATED","log")
  else
    QDKP2_NeedManagementMode()
  end
end

function QDKP2_TimerPause(todo,reason)
-- Pauses the timer. todo can be 'on' or 'off', where on pauses the
-- timer and off resumes it. Can be called only if the timer is already
-- running.
-- reason is optional string. It is used to create instance of the pause. This
-- way you can pause and resume the timer for specific events (like the leaving
-- of a raid) and avoid that different reason overlaps.

  if not QDKP2_isTimerOn() then
    QDKP2_Debug(1,"Core","TimerPause called but timer is not active.")
    return
  end
  if todo=="toggle" then
    if QDKP2_isTimerPaused() then QDKP2_TimerPause("off")
    else QDKP2_TimerPause("on")
    end
  elseif todo=="on" then
    QDKP2timerBase.PAUSE=time()-QDKP2timerBase.TIMER
    if reason then
      QDKP2timerBase.PAUSE_REASON=QDKP2timerBase.PAUSE_REASON or {}
      QDKP2timerBase.PAUSE_REASON[reason]=true
    end
    QDKP2_Events:Fire("TIMER_PAUSED")
    QDKP2_Msg(QDKP2_LOC_TimerPaused,"INFO")
  elseif todo=="off" then
    if reason and (not QDKP2timerBase.PAUSE_REASON or not QDKP2timerBase.PAUSE_REASON[reason]) then
      return
    elseif reason then
      QDKP2timerBase.PAUSE_REASON[reason]=nil
    end
    QDKP2timerBase.PAUSE=nil
    QDKP2_Events:Fire("TIMER_START")
    QDKP2_Msg(QDKP2_LOC_TimerResumed,"INFO")
  end
end

function QDKP2_isTimerPaused()
  return QDKP2timerBase.PAUSE
end

function QDKP2_TimerOff() --stops the timer
  QDKP2_Msg(QDKP2_LOC_TimerStop,"TIMERTICK")
  QDKP2log_Event("RAID",QDKP2_LOC_TimerStop)
  table.wipe(QDKP2timerBase)
  QDKP2libs.Timer:CancelTimer(QDKP2_HourlyTimerObj,true)
  QDKP2_HourlyTimerObj=nil
  QDKP2_Events:Fire("TIMER_STOP")
  QDKP2_Events:Fire("DATA_UPDATED","log")
end

function QDKP2_TimerSetBonus(amount)
  if not amount then
    QDKP2_Debug(1,"Core", "Trying to set nil DKP amount for the timer bonus")
    return
  end
  if QDKP2timerBase then
    QDKP2timerBase.BONUS = amount
  end
end

------------ IRONMAN -----------------------

function QDKP2_IronManStart() --sets the ironman mark
  QDKP2_Debug(2,"Core","Placing IronMan start mark")
  if QDKP2_ManagementMode() then
    QDKP2ironMan.PLAYERS=DictFromList(QDKP2raid,true)
    QDKP2ironMan.TIME = QDKP2_Time()
    QDKP2log_Event("RAID",QDKP2_LOC_IronmanMarkPlaced)
    QDKP2_Msg(QDKP2_LOC_IronmanMarkPlaced,"IRONMAN")
    QDKP2_Events:Fire("DATA_UPDATED","log")
    QDKP2_Events:Fire("IRONMAN_START",QDKP2ironMan.TIME)
  else
    QDKP2_NeedManagementMode()
  end
end

function QDKP2_IronManWipe() --abort the ironman couting without giving anything
  QDKP2_Debug(2,"Core","Wiping IronMan data")
  if QDKP2_IronManIsOn() then
    table.wipe(QDKP2ironMan)
    QDKP2log_Event("RAID",QDKP2_LOC_DataWiped)
    QDKP2_Msg(QDKP2_LOC_DataWiped, "IRONMAN")
    QDKP2_Events:Fire("IRONMAN_STOP")
    QDKP2_Events:Fire("DATA_UPDATED","log")
  else
    QDKP2_Debug(1,"Core","Can't wipe IronMan data: no ironMan data is up.")
  end
end


function QDKP2_InronManFinish(BonusDKP) --calculates who award the ironman bonus and award them BonusDKP

  if not QDKP2_IronManIsOn() then
    QDKP2_Debug(1,"Core","IronManFinish called but no ongoing ironman!")
    return
  end
  QDKP2_Debug(2,"Core","Calculating IronMan bonus. BonusDKP="..tostring(BonusDKP))
  if not QDKP2_OfficerMode() then QDKP2_Msg(QDKP2_LOC_NoRights,"ERROR")(); return; end
  local startMark=QDKP2ironMan.TIME
  if not startMark then
    QDKP2_Debug(1,"Core","Trying to calculate IronMan bonus but no start mark has been placed.")
    return
  end

  BonusDKP=tonumber(BonusDKP)
  if not BonusDKP then
    QDKP2_Debug(1,"Core","Trying to calculate IronMan bonus but BonusDKP is nil!")
    return
  end

  local SID=QDKP2_IsManagingSession()
  if not SID then
    QDKP2_Debug(1,"Core","CurrentSession is NIL. Can't give IronMan Bonus.")
    return
  end

  local playerList=QDKP2log_GetPlayersInSession(SID)
  if not playerList or #playerList==0 then
    QDKP2_Debug(1,"Core","Trying to calculate IronMan bonus but session seems empty. Exiting.")
    return
  end

  local endMark = QDKP2_Time()
  local timeStamp = QDKP2_Timestamp()
  local awarded = 0
  local AltSum={}
  QDKP2_DoubleCheckInit()

  for i=1, #playerList do
    local name = playerList[i]
    QDKP2_Debug(3,"Core","Calculating "..name)
    local AltsStillToCome=QDKP2_AltsStillToCome(name,playerList,i)
    local isIn=(not QDKP2_IRONMAN_INWHENENDS or QDKP2_IsInRaid(name))
    local wasIn=(not QDKP2_IRONMAN_INWHENSTARTS or QDKP2ironMan.PLAYERS[QDKP2_GetMain(name)])
    local eligible,percentage,noreason=QDKP2_GetEligibility(name,'ironman',BonusDKP,true,true)
    if eligible and isIn and wasIn then

      QDKP2_Debug(3,"Core","Eligible for calculation!")

      name=QDKP2_GetMain(name)

      local LogList=QDKP2log_GetPlayer(SID,name)

      local timePos=startMark
      local online=false
      local timeTot=AltSum[name] or 0 --to sum all the raiding time made by alts of the same player.
      for j=#LogList,0,-1 do
        local LogType,LogTime
        local Log=LogList[j]
        if Log then LogType,LogTime=QDKP2log_GetData(Log)
        else     --trick to close the calculation after the last log entry.
          LogTime=endMark
          LogType=QDKP2LOG_LEFT
        end
        if LogType==QDKP2LOG_JOINED and not online then
          if LogTime>timePos then timePos=LogTime; end
          online=true
        elseif LogType==QDKP2LOG_LEFT and online then
          if LogTime>timePos then timeTot=timeTot+LogTime-timePos; end
          online=false
        end
      end

      if not AltsStillToCome then

        local Presence = (100 * timeTot) / (endMark - startMark)
        local PresenceSTR=tostring(timeTot).."/"..tostring(endMark - startMark).." = "..tostring(Presence).."%"
        if Presence >= QDKP2_IRONMAN_PER_REQ then
          QDKP2_Debug(2,"IronMan",name.." GAINS IronMan ("..PresenceSTR..")")
          QDKP2_AddTotals(name,BonusDKP,nil,nil,nil,nil,nil,true)
          QDKP2log_Entry(name,"Iron Man Bonus",QDKP2LOG_MODIFY, {BonusDKP, nil, nil, percentage}, timeStamp ,1)
          awarded=awarded+1
        else
          QDKP2_Debug(2,"IronMan",name.." LOSES IronMan ("..PresenceSTR..")")
          QDKP2log_Entry(name, "Iron Man Bonus", QDKP2LOG_NODKP,  {BonusDKP, nil, nil},
            timeStamp, QDKP2log_PacketFlags(true,nil,nil,nil,QDKP2LOG_NODKP_LOWRAID,math.floor(Presence))
          )
          if QDKP2_AnnounceFailIM and QDKP2online[name] then
            local msg=QDKP2log_GetLastLogText(name)
            QDKP2_SendHiddenWhisper(msg,name)
          end
        end
      else
        QDKP2_Debug(3,"Core","Partial time calculated. Didn't finalized because there are Alts still to come.")
      end

    elseif QDKP2_AltsStillToCome(name,playerList,i) then

    else
      if not isIn then
        noreason=QDKP2LOG_NODKP_IMSTOP
      elseif not wasIn then
        noreason=QDKP2LOG_NODKP_IMSTART
      end
            QDKP2_Debug(2,"Core",name.." loses Iron Man bonus, SubType reason="..tostring(noreason))
      if noreason then
        QDKP2log_Entry(name, "Iron Man Bonus", QDKP2LOG_NODKP, {BonusDKP, nil, nil},
          timeStamp,QDKP2log_PacketFlags(true,nil,nil,nil,noreason)
        )
        if QDKP2_AnnounceFailIM and QDKP2online[name] then
          local msg=QDKP2log_GetLastLogText(name)
          QDKP2_SendHiddenWhisper(msg,name)
        end
      end
    end
  end
  QDKP2log_Entry("RAID","Iron Man bonus", QDKP2LOG_MODIFY, {BonusDKP,nil,nil}, timeStamp,5)
  if awarded==0 then
    QDKP2_Msg(QDKP2_LOC_No1Awarded,"AWARD",QDKP2_COLOR_GREY)
  else
    local msg=QDKP2_LOC_NumAwarded
    msg=string.gsub(msg,"$NUMBER",tostring(awarded))
    msg=string.gsub(msg,"$DKP",tostring(BonusDKP))
    QDKP2_Msg(msg,"AWARD")
  end
  if QDKP2_SENDTRIG_IRONMAN then
    QDKP2_UploadAll()
  end
  table.wipe(QDKP2ironMan)
  QDKP2_Events:Fire("IRONMAN_STOP")
  QDKP2_Events:Fire("DATA_UPDATED","all")
  QDKP2_AskUser(QDKP2_LOC_CloseSessNow,QDKP2_StopSession,true)
end

function QDKP2_IronManIsOn()
  if QDKP2ironMan.TIME then return true; end
end

---------------------- CHARGING METHODS





function QDKP2_DetectBidSet(todo)
  if todo == "toggle" then
    if QDKP2_DetectBids then QDKP2_DetectBidSet("off")
    else QDKP2_DetectBidSet("on")
    end
  elseif todo == "on" then
    QDKP2_DetectBids = true
    QDKP2_Events:Fire("DETECTBID_ON")
    QDKP2_Msg(QDKP2_COLOR_YELLOW.."Winner Detection enabled")
  elseif todo == "off" then
    QDKP2_DetectBids = false
    QDKP2_Events:Fire("DETECTBID_OFF")
    QDKP2_Msg(QDKP2_COLOR_YELLOW.."Winner Detection disabled")
  end
end



function QDKP2_Decay(TypeOrList,Perc)
-- introduces a "tax" of %<perc> to the net DKPs of all members selected by TypeOrList
-- TypeOrList can be 'guild', 'raid' or a custom list with the names of the players to tax.
  if not QDKP2_OfficerMode() then QDKP2_Msg(QDKP2_LOC_NoRights,"ERROR")(); return; end
  if type(Perc)=='string' then
    Perc=string.gsub(Perc,'%%','')
    Perc=tonumber(Perc)
  end
  if not Perc then
    QDKP2_Debug(1,"Core","Decay needs a valide <Perc> value")
    return
  end
  QDKP2_Debug(2,"Core","Decaying "..tostring(Perc).."% DKP to "..tostring(TypeOrList))
    local NameList
    local reason="DKP decay"
    if TypeOrList=="raid" then
      if not QDKP2_ManagementMode then
        QDKP2_NeedManagementMode()
        return
      end
      NameList=QDKP2raid
      reason="Raid DKP decay"
    elseif TypeOrList=="guild" then
      if QDKP2_IsManagingSession() then
        QDKP2_Msg("You can't use the guild decay function with an active session ongoing.")
        return
      end
      NameList=QDKP2name
      reason="Guild DKP decay"
    else
      NameList=TypeOrList
    end
    QDKP2_DoubleCheckInit()
    for i=1,table.getn(NameList) do
      local name=NameList[i]
      local net=QDKP2_GetNet(name)
      if net > 0 then
        local change=RoundNum(net*Perc/100)
        --If you wish to decay negative DKP pools aswell, thus pushing
        --them toward zero, edit "change > 0" to "change ~= 0"
        if change > 0 and not QDKP2_IsMainAlreadyProcessed(name) then
          QDKP2_AddTotals(name,nil,change,nil,reason.." ("..tostring(Perc).."%%)",true)
      QDKP2_ProcessedMain(name)
        end
      end
    end
    if TypeOrList=="raid" then
      QDKP2_Msg("Raid members' DKP have been cut down by "..tostring(Perc).."%")
    elseif TypeOrList=="guild"  then
      QDKP2_Msg("Guild Members' DKP have been cut down by "..tostring(Perc).."%")
    else
      QDKP2_Msg("Given members' DKP have been cut down by "..tostring(Perc).."%")
    end
    QDKP2_Msg("Send changes to store them in the guild notes.")
    QDKP2_Events:Fire("DATA_UPDATED","all")
end

local function WorseThan(percentage,awardtype,guilt)
  local perc = _G["QDKP2_AWARD_"..guilt.."_"..string.upper(awardtype)]
  if perc == false then
    perc = 0
  elseif type(perc) == "string" then
    perc = string.gsub(perc, '%%', '')
    perc = tonumber(perc)
  elseif type(perc) == "number" then
    perc = tonumber(perc)
  else
    return
  end
  if perc < percentage then
    return perc
  end
end

function QDKP2_GetEligibility(name,awardtype,award,online,inzone)
  --returns eligible,percentage,reason
  --eligible is true if should get the award
  --percentage is to be passed to the AddTotals function
  --reason is the NODKP subtype to be used in the log entry.
  local percentage=100
  local reason, eligible
  local net=QDKP2_GetNet(name)
  if not online then
    local perc=WorseThan(percentage,awardtype,'OFFLINE')
    if perc then percentage = perc; reason = QDKP2LOG_NODKP_OFFLINE; end
  end
  if not inzone then
    local perc=WorseThan(percentage,awardtype,'ZONE')
    if perc then percentage=perc; reason=QDKP2LOG_NODKP_ZONE; end
  end
  if not QDKP2_minRank(name) then
    local perc = WorseThan(percentage,awardtype,'RANK')
    if perc then percentage=perc; reason=QDKP2LOG_NODKP_RANK; end
  end
  if QDKP2_IsAlt(name) then
    local perc = WorseThan(percentage,awardtype,'ALT')
    if perc then percentage=perc; reason=QDKP2LOG_NODKP_ALT; end
  end
  if QDKP2_IsStandby(name) then
    local perc = WorseThan(percentage,awardtype,'STANDBY')
    if perc then percentage=perc; reason=QDKP2LOG_NODKP_STANDBY; end
  end
  if QDKP2_IsExternal(name) then
    perc = WorseThan(percentage,awardtype,'EXTERNAL')
    if perc then percentage=perc; reason=QDKP2LOG_NODKP_EXTERNAL; end
  end
  if (net>=QDKP2_MAXIMUM_NET and award>0) or (net<=QDKP2_MINIMUM_NET and award<0) then
      reason=QDKP2LOG_NODKP_LIMIT
      percentage=0
  end
  if percentage~=0 then eligible=true; end
  if percentage == 100 then percentage=nil; end
  return eligible,percentage,reason
end