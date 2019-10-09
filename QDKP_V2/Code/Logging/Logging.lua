-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## LOGGING SYSTEM ##
--           Miscellaneous functions

-- API Documentation
-- QDKP2_Is<spam>Entry(Type): Returns true if Type is in the <spam> class
-- QDKP2log_ConfirmEntries(Name, successup): This will mark as confirmed (or cancelled
--      if not successup) all modified log entries for <name>.



-- return true if the log entry is a Deleted entry

function QDKP2_IsDKPEntry(Type)
 if Type == QDKP2LOG_ABORTED or Type == QDKP2LOG_MODIFY or Type == QDKP2LOG_CONFIRMED or Type == QDKP2LOG_EXTERNAL then
   return true
 end
end

function QDKP2_IsActiveDKPEntry(Type)
  if Type == QDKP2LOG_MODIFY or Type == QDKP2LOG_CONFIRMED or Type == QDKP2LOG_SESSION or Type == QDKP2LOG_EXTERNAL then return true; end
end

function QDKP2_IsLinkDKPEntry(Log)
  local Bit0,Bit1,Bit2,Bit3,Var1,Var2=QDKP2log_GetFlags(Log)
  local Type=QDKP2log_GetType(Log)
  if not QDKP2_IsDKPEntry(Type) and not QDKP2_IsNODKPEntry(Type) then return; end
  if (Bit0 or Bit1) and not Bit2 then -- if RaidAward or ZeroSum but not main entry
    return true
  end
end

function QDKP2_IsDeletedEntry(Type)
  if Type == QDKP2LOG_ABORTED then
    return true
  end
end

function QDKP2_IsInvalidEntry(Type)
  if not Type or not tonumber(Type) or Type<1 then
    return true
  end
end

function QDKP2_IsNODKPEntry(Type)
  if Type == QDKP2LOG_NODKP then
    return true
  end
end

function QDKP2_IsVersionedEntry(Type)
  if QDKP2_IsDKPEntry(Type) or QDKP2_IsNODKPEntry(Type) or Type==QDKP2LOG_LOOT then return true; end
end

function QDKP2_IsVirtualEntry(Type)
  if Type > 100 then return true; end
end

function QDKP2_IsSessionRelated(Type)
  if Type==QDKP2LOG_JOINED or Type==QDKP2LOG_LEFT or Type==QDKP2LOG_LOOT or Type==QDKP2LOG_BOSS or Type==QDKP2LOG_NODKP or Type==QDKP2LOG_BIDDING then return true; end
end

function QDKP2_Timestamp() --returns a timestamp with a Entry ID, to avoid collisions on linked items
  QDKP2_EID=QDKP2_EID+0.01
  return QDKP2_Time()+QDKP2_EID
end

function QDKP2log_GetLastLog(name,session)
--dummy of GetLog
--returns the last log entry of the current session
  local SID=session or QDKP2_OngoingSession()
  return QDKP2log_GetLog(SID,name,1)
end

function QDKP2log_ConfirmEntries(name,successup)
-- Called after a confirmed upload or reset, change the log_type of all the last QDKP2LOG_MODIFY to a new type.
-- if successup=true will change type to QDKP2LOG_CONFIRMED, else QDKP2LOG_ABORTED.
-- checks for backups. will delete it if successup is true, revert if false.
-- It fowards every confirmed entry to the sync function.
  if QDKP2_CheckInProgress then
    QDKP2_Msg(QDKP2_LOC_NoRevertOnCheck,"WARNING")
    return
  end
  local BackupsList=QDKP2log_getBackupList(name)
  if successup then
    QDKP2_Debug(2,"Logging","Confirming "..tostring(#BackupsList).." changed log entries in "..name.."'s log")
  else
    QDKP2_Debug(2,"Logging","Reverting "..tostring(#BackupsList).." changed log entries in "..name.."'s log")
  end
  local gotChanges
  for i=1,#BackupsList do
    local SID,Log=unpack(BackupsList[i])
    QDKP2_Debug(3,"Logging","Doing entry "..tostring(Log).." in session "..SID)
    if successup then
      if Log[QDKP2LOG_FIELD_TYPE]==QDKP2LOG_MODIFY then
        QDKP2log_SetTypeField(Log, QDKP2LOG_CONFIRMED,true)
      end
      QDKP2log_BackupDel(SID,name,Log)
    else
      QDKP2log_BackupRevert(SID,name,Log)
    end
  end
end

