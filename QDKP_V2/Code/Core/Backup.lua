-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--                Backup/Restore
--
--      Functions to backup all the officier notes in local, and to restore that backup in the guild infos.
--
-- API Documentation:
--      QDKP2_BackUp(): Immediatly backups all notes in local, overwriting the previous backup (if any).
--      QDKP2_Restore(): Changes the DKP values to restore the ones in the backup. You need to upload changes to make them live.


function QDKP2_Backup()
--Backup the officernotes. will backup all the dkp values of both guild members and externals.
  local tempBackup = {}
  QDKP2backup = {}
  for i=1, QDKP2_GetNumGuildMembers(true) do
    local name, rank, rankIndex, level, class, zone, note, officernote ,datafield, online, status = QDKP2_GetGuildRosterInfo(i);
    tempBackup[i] = {name, datafield}
  end
  QDKP2backup = tempBackup
  QDKP2backup.DATE = time()
  QDKP2_Msg(QDKP2_COLOR_GREEN.."Backup complete. "..table.getn(tempBackup).." entries.")
  QDKP2_Events:Fire("BACKUP_SAVED")
end


function QDKP2_Restore(DoNotAsk)
-- restores the backup. Will introduce a delta in the DKP values to align the live to the backup. You need to save them: untill you don't
-- the notes won't be alterned. This function will restore DKP values to externals' data ONLY IF the external is already defined. Won't
-- restore alts' status, log, raid settings and, more generally, anything else than the DKP values.
  if not QDKP2backup.DATE then
    QDKP2_Msg("No backups found")
    return
  end
  if not DoNotAsk then
    local mess="Do you want to restore all\n data as in the last backup?"
    QDKP2_AskUser(mess,QDKP2_Restore,true)
  else
    local count = 0
    local get = 0
    local tempBackup = QDKP2backup
    for i=1, table.getn(tempBackup) do
      local name = tempBackup[i][1]
      local datafield = tempBackup[i][2]
      if QDKP2_IsInGuild(name) and not QDKP2_IsAlt(name) then
        local net, total, spent, hours = QDKP2_ParseNote(datafield)
        local DTotal = total - QDKP2note[name][QDKP2_TOTAL]
        local DSpent = spent - QDKP2note[name][QDKP2_SPENT]
        local DHours = hours - QDKP2note[name][QDKP2_HOURS]
        get = get + 1
        if DTotal==0 then DTotal = nil; end
        if DSpent==0 then DSpent = nil; end
        if DHours==0 then DHours = nil; end
        if DTotal or DSpent or DHours then
          QDKP2_AddTotals(name, DTotal, DSpent, DHours, "restored backup", true, nil, nil, true)
        end
      elseif not QDKP2_IsAlt(name) then
        QDKP2_Debug(2,"Core",name.."has not been restored because is an alt of "..QDKP2_GetMain(name))
      else
        QDKP2_Debug(2,"Core",name.."has not been restored because doesn't seems to be in the guild.")
      end
      count = count + 1
    end
    QDKP2_Msg(QDKP2_COLOR_GREEN.."Restored "..get.." entries. Send changes to upload them in officer notes.")
    QDKP2_RefreshGuild()
    QDKP2_Events:Fire("BACKUP_RESTORED")
    QDKP2_Events:Fire("DATA_UPDATED","all")
  end
end
