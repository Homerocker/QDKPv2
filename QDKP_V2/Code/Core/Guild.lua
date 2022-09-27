-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--              Guild Interface
--
--      These functions are the interface that talk directly with the guild data.
--      Includes functions to read the local guild cache and functions to write stuff in the officiers/public notes.
--
-- API Documentation:
-- QDKP2_DownloadGuild(Revert): Read the guild information from the local cache. Called everytime i update it (30 secs).
-- QDKP2_RefreshGuild: Same as DownloadGuild with the Revert flag set to false.
-- QDKP2_Revert: calls DownloadGuild with the revert flag. This will reset all local data to the guild actual infos.
-- QDKP2_UploadAll(): updates the officier/public notes field for every modified guild member
-- QDKP2_GetNumGuildMembers(): same as GetNumGuildMembers, but counts externals as well.
-- QDKP2_GetIndexList(): returns a list in the form i=List[name]. Useful for the following functions.
-- QDKP2_GetGuildRosterInfo(i): same as GetGuildRosterInfo, but counts externals as well. retruns an extra flag 'inGuild'.
-- QDKP2_GuildRosterSetDatafield(i, data): set the officer of pubblic note field of <i> (index)
-- QDKP2_IsInGuild(name): returns true if <name> is in guild, including added externals.



-------------------------------------- DOWNLOAD FUNCTIONS ----------------

--two dummies of QDKP_DownloadGuild for a better reading
function QDKP2_RefreshGuild()
  QDKP2_DownloadGuild(false)
end

function QDKP2_Revert()
  QDKP2_DownloadGuild(true)
end


--DownloadGuild will update the not-modified players if called with nil or false, will reset all as in the
--officer notes otherwise.

function QDKP2_DownloadGuild(Revert)

  QDKP2_Debug(3, "Guild", "Initiating guild data refresh. Revert=" .. tostring(Revert))

  if IsInGuild() and QDKP2_OfficerOrPublic == 1 and not CanViewOfficerNote() then
    if not QDKP2_WarnedCantRead then
      QDKP2_Msg(QDKP2_LOC_CantReadOfficerNotes)
      QDKP2_WarnedCantRead = true
    end
    return
  else
    QDKP2_WarnedCantRead = nil
  end

  if Revert and QDKP2_CheckInProgress then
    QDKP2_Msg(QDKP2_LOC_NoRevertOnCheck, "WARNING")
    return
  end

  if not QDKP2_ACTIVE then
    QDKP2_Debug(2, "Guild", "Aborting Guild Update, I'm not ready")
    return
  end

  local changedGuild
  if (IsInGuild() and GetGuildInfo("player") and GetGuildInfo("player") ~= QDKP2_GUILD_NAME) or (QDKP2_GUILD_NAME and not IsInGuild()) then
    QDKP2_Debug(1, "Guild", "You joined or left a guild. Reloading database.")
    --When i leave the guild, just update the guild name global and reload the database
    local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
    QDKP2_GUILD_NAME = guildName
    QDKP2_InitData()
    QDKP2_ReadDatabase()
    GuildRoster()
    QDKP2_Events:Fire("DATA_UPDATED", "all")
    return
  end

  --[[
  if QDKP2_OfficerMode() then
    QDKP2frame1_upload:Enable()
  else
    QDKP2frame1_upload:Disable()
  end
  ]]--

  local timeStamp = QDKP2_Timestamp()
  local num = 0
  local new = 0
  local updated = 0 --This is to avoid update log updates if DKPs didn't change.

  if Revert then
    QDKP2_Debug(2, "Guild", "Reverting all changes")
    table.wipe(QDKP2note)
    table.wipe(QDKP2altsRestore)
    QDKP2log_ConfirmEntries("RAID", false)
    updated = 100 --forces a update
  end

  table.wipe(QDKP2alts)
  local nameTemp = {}
  local rankIndexTemp = {} --I need this to perform IsInGuild() Check. Can't iterate each time throu QDKP2name. Little garbage generation but oh cmon.

  for i = 1, QDKP2_GetNumGuildMembers(true) do

    local name, rank, rankIndex, level, class, zone, note, officernote, datafield, online, status, isInGuild = QDKP2_GetGuildRosterInfo(i)
    if name == nil then
      name = ""
    end
    QDKP2_Debug(3, "Guild", "Processing " .. name)

    if isInGuild and QDKP2_IsExternal(name) then
      QDKP2_Msg(string.gsub(QDKP2_LOC_ExternalJoined, "$NAME", name), "WARNING")
      if not datafield or #datafield == 0 then
        QDKP2stored[name] = { 0, 0, 0 }
        QDKP2_UpdateNoteByName(name)
      end
      QDKP2_DelExternal(name, true)
      QDKP2_DownloadGuild(Revert)
      return
    end

    local Hide_Rank = false
    for v = 1, table.getn(QDKP2_HIDE_RANK) do
      if rank == QDKP2_HIDE_RANK[v] then
        QDKP2_Debug(3, "Guild", "Ignoring " .. name .. " because his rank is in the hide list")
        Hide_Rank = true
        break
      end
    end
    local Main = QDKP2_FirstWord(datafield)

    if not Hide_Rank and level >= QDKP2_MINIMUM_LEVEL and ((not QDKP2_IsInGuild(Main) and not QDKP2altsRestore[name]) or QDKP2altsRestore[name] == "") then

      local net, total, spent, hours = QDKP2_ParseNote(datafield)

      if (net + spent ~= total) then
        local msg = string.gsub(QDKP2_LOC_DifferentTot, "$NAME", name)
        QDKP2_Msg(msg, "ERROR")
        QDKP2_Msg(QDKP2_LOC_Net .. "=" .. net .. ", " .. QDKP2_LOC_Spent .. "=" .. spent .. ", " .. QDKP2_LOC_Total .. "=" .. total, "ERROR")
      end

      table.insert(nameTemp, name)  --used to keep track of the order
      QDKP2rank[name] = rank
      rankIndexTemp[name] = rankIndex
      QDKP2class[name] = class
      QDKP2online[name] = online

      local NewEntry = false
      if not QDKP2note[name] then
        QDKP2_Debug(2, "Guild", "New guild member detected:" .. name)
        QDKP2note[name] = QDKP2stored[name] or { total, spent, hours }
        new = new + 1
        NewEntry = true
      end

      --this is used to import changes done by other members.
      if QDKP2stored[name] and not QDKP2_ModifiedDuringCheck then
        local modTotal
        local modSpent
        local modHours
        local stored = QDKP2stored[name] or {}
        local actual = QDKP2note[name]
        local oldTotal = stored[QDKP2_TOTAL] or 0
        local oldSpent = stored[QDKP2_SPENT] or 0
        local oldHours = stored[QDKP2_HOURS] or 0
        local actualTotal = actual[QDKP2_TOTAL] or 0
        local actualSpent = actual[QDKP2_SPENT] or 0
        local actualHours = actual[QDKP2_HOURS] or 0
        local modifyAcquired --to detect when I detect my own modify on guild notes.

        if ((total ~= actualTotal or not QDKP2_ModifiedPlayers[name]) and total ~= oldTotal) then
          local diff = RoundNum(total - oldTotal)
          if math.abs(diff) >= 0.1 then
            QDKP2_Debug(2, "Guild", name .. "'s DKP Total changed for remote editing (" .. tostring(diff) .. "). Importing")
            QDKP2note[name][QDKP2_TOTAL] = actualTotal + diff
            --QDKP2_StopCheck()
            modTotal = diff
          end
        end
        --??? if total == actualTotal and total ~= oldTotal then QDKP2_ModifiedPlayers[name]=false; end

        if ((spent ~= actualSpent or not QDKP2_ModifiedPlayers[name]) and spent ~= oldSpent) then
          local diff = RoundNum(spent - oldSpent)
          if math.abs(diff) >= 0.1 then
            QDKP2_Debug(2, "Guild", name .. "'s DKP Spent changed for remote editing (" .. tostring(diff) .. "). Importing")
            QDKP2note[name][QDKP2_SPENT] = actualSpent + diff
            --QDKP2_StopCheck()
            modSpent = diff
          end
        end
        --??? if spent == actualSpent and spent ~= oldSpent then QDKP2_ModifiedPlayers[name]=false; end

        if (math.abs(hours - actualHours) > 0.09 or not QDKP2_ModifiedPlayers[name]) and math.abs(hours - oldHours) > 0.09 then
          local diff = RoundNum((hours - oldHours) * 10) / 10  --this to make the difference with only a decimal
          if math.abs(diff) > 0.01 then
            QDKP2_Debug(2, "Guild", name .. "'s DKP Hours changed for remote editing (" .. tostring(diff) .. "). Importing")
            QDKP2note[name][QDKP2_HOURS] = actualHours + diff
            --QDKP2_StopCheck()
            if QDKP_TIMER_LOG_TICK then
              modHours = diff
            end
          end
        end

        --this will stay as long as i don't implement the syncronization system.
        if modTotal or modSpent or modHours then
          QDKP2_Debug(2, "Guild", "Storing ExternalMod. actTotal=" .. tostring(total) .. ", oldTotal=" .. tostring(oldTotal) .. "; spent=" .. tostring(spent) .. ", oldSpent=" .. tostring(oldSpent))
          QDKP2log_Entry(name, nil, QDKP2LOG_EXTERNAL, { modTotal, modSpent, modHours }, nil, nil, true)
          updated = updated + 1
        end

        --this detects when i import (or better avoid to import) my modifications.
        if QDKP2_ModifiedPlayers[name] and
            (total == actualTotal) and
            (spent == actualSpent) and
            (math.abs(hours - actualHours) < 0.09) then
          QDKP2_ModifiedPlayers[name] = nil
          QDKP2_Debug(3, "Guild", "ExternalMod intercepted. actTotal=" .. tostring(total) .. ", oldTotal=" .. tostring(oldTotal) .. "; spent=" .. tostring(spent) .. ", oldSpent=" .. tostring(oldSpent))
        end
      end

      if NewEntry then
        if QDKP2_REPORT_NEW_GUILDMEMBER and not Revert then
          local msg = QDKP2_LOC_NewGuildMember
          msg = string.gsub(msg, "$NAME", name)
          QDKP2_Msg(msg, "INFO")
        end
        QDKP2_Sort_Lastn = -1 --forces a resort
      end

      if Revert then
        QDKP2log_ConfirmEntries(name, false)
      end

      if hours < 0 then
        hours = 0;
      end
      QDKP2stored[name] = { total, spent, hours }

      num = num + 1

    elseif (QDKP2_IsInGuild(Main) or QDKP2altsRestore[name]) and level >= QDKP2_MINIMUM_LEVEL and not Hide_Rank and name ~= "" then
      if QDKP2altsRestore[name] then
        Main = QDKP2altsRestore[name];
      end
      QDKP2_Debug(3, "Guild", name .. " is an Alt of " .. Main)
      table.insert(nameTemp, name)
      QDKP2alts[name] = Main
      QDKP2rank[name] = rank
      rankIndexTemp[name] = rankIndex
      QDKP2class[name] = class
      QDKP2online[name] = online
    end
    QDKP2_ModifiedDuringCheck = false

  end

  QDKP2name = nameTemp
  QDKP2rankIndex = rankIndexTemp

  QDKP2_UpdateRaid()
  QDKP2_Events:Fire("DATA_UPDATED", "roster")
  if updated > 0 then
    QDKP2_Events:Fire("DATA_UPDATED", "log")
  end

  if Revert then
    QDKP2_Msg(QDKP2_LOC_GuildRosterReverted, "DKP")
    QDKP2GUI_Main:refreshIcon()
    QDKP2GUI_MiniBtn_Refresh()
  elseif new ~= 0 and not QDKP2_REPORT_NEW_GUILDMEMBER then
    local msg = string.gsub(QDKP2_LOC_AddedToGuildRoster, "$NUM", tostring(new))
    QDKP2_Msg(msg, "INFO", QDKP2_COLOR_GREEN)
  end

end

function QDKP2_ReverPlayer(name)
  if QDKP2_CheckInProgress then
    QDKP2_NotifyUser("You can't revert changes while a check\nis in progress. Wait for the check to\ncomplete then try again.")
    return
  end
  name = QDKP2_GetMain(name)
  QDKP2log_ConfirmEntries(name, false)
  QDKP2note[name] = QDKP2_CopyTable(QDKP2stored[name])
  if QDKP2_AnnounceWhisper and QDKP2online[name] then
    local mess = QDKP2_LOC_AnnounceWhisperRev
    mess = mess:gsub("$AMOUNT", QDKP2_GetNet(name))
    QDKP2_SendHiddenWhisper(mess, name)
  end
end


-------------------------------------- UPLOAD FUNCTIONS ----------------

-- this function will update all dkp changes in raid to officernotes or local data (for externals).
-- If something is modified, will trigger a check and a syncronization of the updated data.
-- Can handle externals and alts.
function QDKP2_UploadAll()
  QDKP2_Debug(3, "Upload", "UploadAll called")
  if not QDKP2_OfficerMode() then
    QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")
    return
  end
  local guildCount = 0
  local localCount = 0
  local uploaded = 0
  local indexList = QDKP2_GetIndexList()
  for i = 1, table.getn(QDKP2name) do
    local name = QDKP2name[i]
    if (QDKP2_IsModified(name) and not QDKP2_IsAlt(name)) or (QDKP2altsRestore[name] and QDKP2altsRestore[name] == "") then
      QDKP2_Debug(3, "Upload", "Processing " .. name .. " because he has modificatione")
      if QDKP2_UpdateNoteByName(name, indexList) then
        if QDKP2_IsExternal(name) then
          localCount = localCount + 1
        else
          guildCount = guildCount + 1
        end
      end
      uploaded = uploaded + 1
    elseif QDKP2altsRestore[name] and QDKP2altsRestore[name] ~= "" then
      QDKP2_Debug(3, "Upload", "Processing " .. name .. " because is in the AltsRestore list")
      local index = indexList[name]
      if index then
        QDKP2_GuildRosterSetDatafield(index, QDKP2altsRestore[name])
        if QDKP2_IsExternal(name) then
          localCount = localCount + 1
          QDKP2log_ConfirmEntries(name, true)
        else
          guildCount = guildCount + 1
        end
      end
      uploaded = uploaded + 1
    end
  end

  if (guildCount == 0 and localCount == 0) then
    -- if we had no uploads
    QDKP2_Msg(QDKP2_LOC_NoMod, "INFO", QDKP2_COLOR_GREY)
  elseif ((localCount + guildCount) ~= uploaded) then
    local msg = string.gsub(QDKP2_LOC_Failed, "$FAILED", tostring(count - uploaded))
    QDKP2_Msg(msg, "ERROR")
    GuildRoster()
  elseif guildCount == 0 then
    local msg = string.gsub(QDKP2_LOC_SucLocal, "$UPLOADED", tostring(localCount))
    QDKP2_Msg(msg, "INFO", QDKP2_COLOR_GREEN)
    QDKP2log_ConfirmEntries("RAID", true)
    QDKP2_DownloadGuild()
  else
    local msg = QDKP2_LOC_Successful
    msg = string.gsub(msg, "$UPLOADED", tostring(uploaded))
    msg = string.gsub(msg, "$TIME", tostring(QDKP2_CHECK_UPLOAD_DELAY + QDKP2_CHECK_REFRESH_DELAY))
    QDKP2_Msg(QDKP2_COLOR_GREEN .. msg)
    QDKP2_InitiateCheck()
  end

  if uploaded > 0 then
    QDKP2_Events:Fire("DATA_UPDATED", "all")
  end
end

--------------------------------

--this function modifies the officer notes of <name>. Indextable is optional,
--used to keep it in case of mass upload
function QDKP2_UpdateNoteByName(name, indexList)
  QDKP2_Debug(3, "Core", "Updating DKP note of " .. name)
  indexList = indexList or QDKP2_GetIndexList()
  local index = indexList[name]

  if index then
    local total = QDKP2_GetTotal(name)
    local spent = QDKP2_GetSpent(name)
    local net = total - spent
    local hours = QDKP2_GetHours(name)
    if QDKP2_IsExternal(name) then
      QDKP2log_ConfirmEntries(name, true)
    end
    local result = QDKP2_SetDKPNote(index, net, total, spent, hours)
    if result then
      QDKP2_ModifiedPlayers[name] = true;
    end
    return result
  else
    local msg = string.gsub(QDKP2_LOC_IndexNoFound, "$NAME", name)
    QDKP2_Msg(msg, "ERROR")
    QDKP2log_Entry(name, QDKP2_LOC_IndexNoFoundLog, QDKP2LOG_CRITICAL)
    QDKP2_Events:Fire("DATA_UPDATED", "log")
  end
end


--This fucntion will set a note given index and note parameters
function QDKP2_SetDKPNote(index, net, total, spent, hours)
  local output = QDKP2_MakeNote(net, total, spent, hours)
  if index then
    QDKP2_GuildRosterSetDatafield(index, output)
    return true
  end
end

-- This return a list in the form of [guildmember] = index, to use with QDKP2_SetDKPNote
function QDKP2_GetIndexList()
  local output = {}
  for i = 1, QDKP2_GetNumGuildMembers(true) do
    local name, rank, rankIndex, level, class, zone, note, officernote, datafield, online, status = QDKP2_GetGuildRosterInfo(i);
    output[name] = i
  end
  return output
end

-------------UTILITIES---------------------

function QDKP2_GetNumGuildMembers()
  if not IsInGuild() then
    return 0;
  end
  local QDKP2ext_list = ListFromDict(QDKP2externals)
  return GetNumGuildMembers(true) + table.getn(QDKP2ext_list)
end

function QDKP2_GetGuildRosterInfo(i)
  local name, rank, rankIndex, level, class, zone, note, officernote, datafield, online, status, isinguild
  local GuildSize = GetNumGuildMembers(true)
  if not IsInGuild() then
    GuildSize = 0;
  end                      --see QDKP2_GetNumGuildMembers()
  local ext_list = ListFromDict(QDKP2externals)
  if i <= GuildSize then
    name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i)
    isinguild = true
  elseif i - GuildSize <= #ext_list then
    name = ext_list[i - GuildSize]
    rank = "*External*"
    rankIndex = 255
    level = 255    --i can't know his level.
    class = QDKP2externals[name].class or UNKNOWN
    zone = UNKNOWN
    note = QDKP2externals[name].datafield or ""
    officernote = QDKP2externals[name].datafield or ""
    -- If he is in raid i'll get the online status from the GetRaidRosterInfo API.
    -- If you have an external in the standby list, it will be always reported as online even if he isn't
    online = true
    status = UNKNOWN
    isinguild = false
  end
  if QDKP2_OfficerOrPublic == 2 then
    datafield = note
  else
    datafield = officernote
  end
  return name, rank, rankIndex, level, class, zone, note, officernote, datafield, online, status, isinguild
end

function QDKP2_GuildRosterSetDatafield(i, data)
  local GuildSize = GetNumGuildMembers(true)
  local QDKP2ext_list = ListFromDict(QDKP2externals)
  if i <= GuildSize then
    if QDKP2_OfficerOrPublic == 2 then
      QDKP2_Debug(3, "Core", "Setting public note field of index " .. tostring(i) .. " to " .. data)
      GuildRosterSetPublicNote(i, data)
    else
      QDKP2_Debug(3, "Core", "Setting officer note field of index " .. tostring(i) .. " to " .. data)
      GuildRosterSetOfficerNote(i, data)
    end
  elseif i - GuildSize <= table.getn(QDKP2ext_list) then
    name = QDKP2ext_list[i - GuildSize]
    QDKP2externals[name].datafield = data
  end
end

function QDKP2_IsInGuild(name)
  --returns true if the player is in Guild
  if QDKP2rankIndex[name] then
    return true
  end
end
