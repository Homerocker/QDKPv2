-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--              Low Level DKP API
--
--      These functions are the low-level interface to the QDKP DKP system. They let you read
--      and write DKP amounts for any given guild member. They are trasparent for alts and externals, and
--      the write functions take care of the logging aswell. The only thing you have to be sure of is
--      to pass a valid name (case sensitive).
--
-- API Documentation:
-- READ
-- QDKP2_GetTotal(name): Returns the total DKP amount of <name>
-- QDKP2_GetSpent(name): Returns the total spent DKP amount of <name>
-- QDKP2_GetNet(name): Returns the net DKP amount of <name>
-- QDKP2_GetHours(name): Returns the total raiding time of <name>
-- QDKP2_GetSessEarn(name): Returns the DKP earned in current session by <name> (if any) WIP
-- QDKP2_GetSessSpent(name): Returns the DKP spent in current session by <name> (if any) WIP

-- WRITE
-- QDKP2_AddTotals(...): Modifies <name>'s DKP. Check the function description for more info. Needs OfficerMode.
-- QDKP2_PlayerGains(name,amount,reason,NoLog,NoMsg): Dummy of AddTotals, adds <amount> DKP to <name>
-- QDKP2_PlayerSpends(name,amount,reason,NoLog,NoMsg): Dummy of AddTotals, subtracts <amount> DKP to <name>
-- QDKP2_PlayerIncTime(name,amount,reason,NoLog,NoMsg): Dummy of AddTotals, increase raiding time of <name> by <amount> hours.
-- QDKP2_GetAmountFromText(text,name): Returns text as integer number. if text is xx%, returns a percentage of name's net dkp.


-------------------- GetValues ------------------------------------------------------------------------------
-- Functions that gets the DKP values. They're trasparent to alts and externals. Perform some checks, but you
-- have to provide a valid player name.
-- name: the name of the player. case sensitive
-- doNotReset: by default, this function will reset the player data on errors. Set this to true to hinibit.

function QDKP2_GetTotal(name, doNotReset)
  name = QDKP2_GetMain(name)
  if not QDKP2rankIndex[name] then
    QDKP2_Debug(1, "Core", "Asked total DKP of " .. tostring(name) .. " but he's not in guild.")
    return 0
  end
  if not QDKP2note[name] then
    QDKP2_Debug(1, "Core", "Asked total DKP of " .. tostring(name) .. " but he has not DKP values?!?!?")
    GuildRoster()
    return 0
  end
  local Total = QDKP2note[name][QDKP2_TOTAL]
  if not Total then
    QDKP2_Debug(1, "Core", "Error while getting Total amount for " .. name .. ". Doesn't have a valid data array.")
    if doNotReset then
      Total = 0
    else
      QDKP2_ResetPlayer(name)
      Total = QDKP2_GetTotal(name, true)
    end
  end
  return Total
end

function QDKP2_GetSpent(name, doNotReset)
  name = QDKP2_GetMain(name)
  if not QDKP2rankIndex[name] then
    QDKP2_Debug(1, "Core", "Asked total DKP of " .. tostring(name) .. " but he's not in guild.")
    return 0
  end
  if not QDKP2note[name] then
    QDKP2_Debug(1, "Core", "Asked total DKP of " .. tostring(name) .. " but he has not DKP values?!?!?")
    GuildRoster()
    return 0
  end
  local Spent = QDKP2note[name][QDKP2_SPENT]
  if not Spent then
    QDKP2_Debug(1, "Core", "Error while getting Spent amount for " .. name .. ". Doesn't have a valid data array,")
    if doNotReset then
      Spent = 0
    else
      QDKP2_ResetPlayer(name)
      Spent = QDKP2_GetSpent(name, true)
    end
  end
  return Spent
end

function QDKP2_GetNet(name)
  return QDKP2_GetTotal(name) - QDKP2_GetSpent(name)
end

function QDKP2_GetHours(name, doNotReset)
  name = QDKP2_GetMain(name)
  if not QDKP2rankIndex[name] then
    QDKP2_Debug(1, "Core", "Asked total DKP of " .. tostring(name) .. " but he's not in guild.")
    return 0
  end
  if not QDKP2note[name] then
    QDKP2_Debug(1, "Core", "Asked total DKP of " .. tostring(name) .. " but he has not DKP values?!?!?")
    GuildRoster()
    return 0
  end
  if not QDKP2note[name] then
    QDKP2_Debug(1, "Core", "Asked hours of " .. tostring(name) .. " but he's not in guild.")
    GuildRoster()
    return 0
  end
  local Hours = QDKP2note[name][QDKP2_HOURS]
  if not Hours then
    QDKP2_Debug(1, "Core", "Error while getting Hours amount for " .. name .. ". Doesn't have a valid data array,")
    if doNotReset then
      Hours = 0
    else
      QDKP2_ResetPlayer(name)
      Hours = QDKP2_GetHours(name, true)
    end
  end
  return Hours
end

function QDKP2_GetTotSpentRatio(name, doNOtReset)
  --returns the quotient between Total and Spent DKP. This is to add a EP/GP support to QDKP2.
  --returns a float. If Spent is 0 returns 9999
  local Total = QDKP2_GetTotal(name, doNotReset)
  local Spent = QDKP2_GetTotal(name, doNotReset)
  if Spent == 0 then
    return 9999;
  end
  return (Total / Spent)
end

function QDKP2_GetSessionAmounts(name)
  local G, S
  local sessions = QDKP2_IsSessionPresent()
  if #sessions > 0 then
    G = 0;
    S = 0
    for i, SID in pairs(sessions) do
      local LogList = QDKP2log_GetPlayer(SID, name)
      if LogList and #LogList > 0 then
        local sums = QDKP2log_ResumDKPChanges(LogList)
        G = G + (sums[1] or 0)
        S = S + (sums[2] or 0)
      end
    end
  end
  return G, S
end

function QDKP2_AddTotals(name, award, spent, hours, reason, noMsgIt, timestamp, noLogIt, outsideSession)
  -- this adds to the value in the local varables that store the DKPs (both total and cumulative)
  -- Usage = QDKP2_AddTotals(name, award, spent, hours, reason, NoMsg, timestamp, NoLog)
  -- award, spent and hours are the amounts to add/subtract.
  -- reason is an optional string that describes the operation. Used for log and for the message.
  -- noMsgIt suppress the printing of the operation.
  -- *********** The next arguments should NOT be used when the function is called as API. *************
  -- Timestamp is used to create linked log entries.
  -- noLogit suppress the creation of a log entry with the operation done.
  --
  -- all arguments are optionals except for the name.
  -- you can pass a string like "10%" for total and/or spent, and it will be calculated in relation with net DKP.
  -- logIt will add a DKP log entry.
  -- msgIt will display a text of the modification to the given channel.

  QDKP2_Debug(2, "Core", "Calling AddTotal for " .. name .. ". +DKP=" .. tostring(award) .. ", -DKP=" .. tostring(spent) .. ", Hours=" .. tostring(hours) .. ", Coeff=" .. tostring(coefficent))

  if not QDKP2_OfficerMode() then
    QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")();
    return ;
  end

  if not QDKP2_IsInGuild(name) then
    QDKP2_Debug(1, "Core", "Calling AddTotals with a player that is not in the guild!")
    return
  end

  if type(award) == "string" then
    award = QDKP2_GetAmountFromText(award, name);
  end
  if type(spent) == "string" then
    spent = QDKP2_GetAmountFromText(spent, name);
  end

  hours = tonumber(hours)

  coeff = tonumber(coeff)

  local OriginalName = name
  name = QDKP2_GetMain(name)

  if not QDKP2note[name] then
    QDKP2_Msg(QDKP2_COLOR_RED .. QDKP2_LOC_NoPlayerInChance)
    return
  end

  local oldTotal = QDKP2_GetTotal(name)
  local oldSpent = QDKP2_GetSpent(name)
  local oldHours = QDKP2_GetHours(name)

  if award then
    award = RoundNum(award)
  end
  if spent then
    spent = RoundNum(spent)
  end
  if hours then
    hours = RoundNum(hours * 10) / 10
  end

  local Net = QDKP2_GetNet(name)
  local Gain = 0
  if award then
    Gain = Gain + award;
  end
  if spent then
    Gain = Gain - spent;
  end
  local newNet = Net + Gain
  if (newNet > QDKP2_MAXIMUM_NET) then
    if not award then
      award = 0;
    end
    award = award - (newNet - QDKP2_MAXIMUM_NET)
    local Msg = QDKP2_LOC_MaxNetLimit
    Msg = string.gsub(Msg, "$NAME", name)
    Msg = string.gsub(Msg, "$MAXIMUMNET", tostring(QDKP2_MAXIMUM_NET))
    QDKP2_Msg(QDKP2_COLOR_YELLOW .. Msg)
    QDKP2log_Event(name, QDKP2_LOC_MaxNetLimitLog)
  end
  if (newNet < QDKP2_MINIMUM_NET) then
    if not spent then
      spent = 0;
    end
    spent = spent - (QDKP2_MINIMUM_NET - newNet)
    local Msg = QDKP2_LOC_MinNetLimit
    Msg = string.gsub(Msg, "$NAME", name)
    Msg = string.gsub(Msg, "$MINIMUMNET", tostring(QDKP2_MINIMUM_NET))
    QDKP2_Msg(QDKP2_COLOR_YELLOW .. Msg)
    QDKP2log_Event(name, QDKP2_LOC_MinNetLimitLog)
  end

  local DTotal
  local DSpent
  local DHours

  local Gained = 0

  local HaveModify

  local limitMax, limitMin = QDKP2_GetMaximumFieldNumber()

  if award then
    if award ~= 0 then
      DTotal = award
      local newTotal = award + oldTotal
      if newTotal > limitMax then
        newTotal = limitMax
      elseif newTotal < limitMin then
        newTotal = limitMin
      end
      QDKP2note[name][QDKP2_TOTAL] = newTotal

      Gained = Gained + DTotal
      HaveModify = true
    end
  end
  if spent then
    if spent ~= 0 then
      DSpent = spent
      local newSpent = spent + oldSpent
      if newSpent > limitMax then
        newSpent = limitMax
      elseif newSpent < limitMin then
        newSpent = limitMin
      end
      QDKP2note[name][QDKP2_SPENT] = newSpent
      Gained = Gained - DSpent
      HaveModify = true
    end
  end
  if hours then
    if hours ~= 0 then
      DHours = hours
      local newHours = hours + oldHours
      if newHours < 0 then
        newHours = 0
      elseif newHours > 999.9 then
        newHours = 999.9
      end
      QDKP2note[name][QDKP2_HOURS] = newHours
      HaveModify = true
    end
  end

  if not HaveModify and not reason then
    return ;
  end

  QDKP2GUI_MiniBtn_Refresh()
  QDKP2GUI_Main:refreshIcon()

  if not noLogIt then

    if Gained == 0 then
      Gained = nil;
    end

    local sessionOut = QDKP2log_Entry(name, reason, QDKP2LOG_MODIFY, { DTotal, DSpent, DHours }, timestamp, nil, outsideSession)

    if not noMsgIt then
      local description = QDKP2log_GetLastLogText(name, sessionOut)
      QDKP2_Msg(QDKP2_GetName(OriginalName) .. " " .. description, "DKP")
    end
  end

  local Net = QDKP2_GetNet(name)

  if QDKP2_AnnounceWhisper and Gained ~= 0 then
    local msg
    if reason then
      msg = QDKP2_LOC_AnnounceWhisperRes
      msg = string.gsub(msg, '$REASON', reason)

      local lootmethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod()
      if lootmethod == "master" and masterlooterPartyID == 0 and GetNumLootItems() ~= 0 and QDKP2online[OriginalName] then
        for ci = 1, 40 do
          if GetMasterLootCandidate(ci) == OriginalName then
            for li = 1, GetNumLootItems() do
              if GetLootSlotLink(li) == reason then
                GiveMasterLoot(li, ci)
                break
              end
            end
            break
          end
        end
      end

    else
      msg = QDKP2_LOC_AnnounceWhisperTxt
    end
    if award == 0 then
      award = nil;
    end
    if spent == 0 then
      spent = nil;
    end
    local awsp = QDKP2_GetAwardSpendText(award, spent)
    msg = string.gsub(msg, '$AWARDSPENDTXT', awsp)
    msg = string.gsub(msg, '$NET', tostring(Net))
    QDKP2_SendHiddenWhisper(msg, OriginalName)
  end

  if QDKP2_CHANGE_NOTIFY_NEGATIVE then
    if Net < 0 then
      local msg = string.gsub(QDKP2_LOC_Negative, "$NAME", OriginalName)
      QDKP2_Msg(msg, 'NEGATIVE')
    end
  end

  if QDKP2_CHANGE_NOTIFY_WENT_NEGATIVE then
    if (Net < 0) and (oldTotal - oldSpent >= 0) then
      local msg = string.gsub(QDKP2_LOC_GoesNegative, "$NAME", OriginalName)
      QDKP2_Msg(msg, 'GOESNEGATIVE')
    end
  end

  QDKP2_StopCheck()
end

--three dummies of AddTotal for easier reading.
--they will iterate name if is a list.
function QDKP2_PlayerGains(name, amount, reason, NoLog, NoMsg)
  if not QDKP2_OfficerMode() then
    QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")();
    return ;
  end
  if type(name) == "string" then
    name = { name };
  end
  QDKP2_DoubleCheckInit()
  for i, v in pairs(name) do
    if not QDKP2_IsMainAlreadyProcessed(v) then
      QDKP2_AddTotals(v, amount, nil, nil, reason, NoMsg, nil, NoLog)
      QDKP2_ProcessedMain(v)
    end
  end
  if QDKP2_SENDTRIG_MODIFY then
    QDKP2_UploadAll();
  end
end

function QDKP2_PlayerSpends(name, amount, reason, NoLog, NoMsg)
  if not QDKP2_OfficerMode() then
    QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")();
    return ;
  end
  if type(name) == "string" then
    name = { name };
  end
  QDKP2_DoubleCheckInit()
  for i, v in pairs(name) do
    if not QDKP2_IsMainAlreadyProcessed(v) then
      QDKP2_AddTotals(v, nil, amount, nil, reason, NoMsg, nil, NoLog)
      QDKP2_ProcessedMain(v)
    end
  end
  if QDKP2_SENDTRIG_MODIFY then
    QDKP2_UploadAll();
  end
end

function QDKP2_PlayerIncTime(name, hours, reason, NoLog, NoMsg)
  if not QDKP2_OfficerMode() then
    QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")();
    return ;
  end
  if type(name) == "string" then
    name = { name };
  end
  QDKP2_DoubleCheckInit()
  for i, v in pairs(name) do
    if not QDKP2_IsMainAlreadyProcessed(v) then
      QDKP2_AddTotals(v, nil, nil, hours, reason, NoMsg, nil, NoLog)
      QDKP2_ProcessedMain(v)
    end
  end
  if QDKP2_SENDTRIG_MODIFY then
    QDKP2_UploadAll();
  end
end

function QDKP2_GetAmountFromText(text, name)
  text = string.gsub(text, "[ \t]", "")
  if string.sub(text, -1) == "%" then
    local perc = tonumber(string.gsub(text, '%%', '') or '')
    if perc then
      text = QDKP2_GetNet(name) * perc / 100;
    end
    QDKP2_Debug(2, "Core", "Award passed as percentual. Calculation is award=" .. tostring(text))
  end
  return tonumber(text)
end
