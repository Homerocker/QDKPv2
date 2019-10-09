-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--                   ## GUI ##
--              DKP Log Entries Editor
--

local myClass={}

function myClass.Show(self)
  QDKP2_modify_log_entry:Show()
  myClass.Refresh()
  QDKP2frame6_ReasonBox:ClearFocus()
end

function myClass.Hide(self)
  QDKP2_modify_log_entry:Hide()
end

function myClass.Toggle(self)
  if QDKP2_modify_log_entry:Show():IsVisible() then
    QDKP2_modify_log_entry:Hide()
  else
    QDKP2_modify_log_entry:Show()
  end
end

function myClass.Refresh(self)
  if not myClass.editedLog then
    myClass:Hide()
    return
  end
  local RaidAw,ZeroSum,MainEntry = QDKP2log_GetFlags(myClass.editedLog)
  if MainEntry then
    local nameList, logList =QDKP2log_GetList(myClass.editedSession,myClass.editedLog[QDKP2LOG_FIELD_TIME])
    logList=logList or {}
    QDKP2_modify_log_entry:SetHeight(150)
    QDKP2_modify_log_entry_linkText1:Show()
    QDKP2_modify_log_entry_linkText2:Show()
    QDKP2_modify_log_entry_linkText2:SetText(string.gsub("You are modifying $X entries.","$X",tostring(#logList)))    
  else
    QDKP2_modify_log_entry:SetHeight(125)
    QDKP2_modify_log_entry_linkText1:Hide()
    QDKP2_modify_log_entry_linkText2:Hide()
  end
  if RaidAw then
    QDKP2frame6_GainedBox:Show()
    QDKP2frame6_SpentBox:Hide()
  elseif ZeroSum then
    QDKP2frame6_GainedBox:Hide()
    QDKP2frame6_SpentBox:Show()
  else
    QDKP2frame6_GainedBox:Show()
    QDKP2frame6_SpentBox:Show()
  end
end

function myClass.Set(self)
  if not self.editedLog then return; end
  local newGain=QDKP2frame6_GainedBox:GetText()
  local newSpent=QDKP2frame6_SpentBox:GetText()
  local newReason=QDKP2frame6_ReasonBox:GetText()
  local gain,spent,hours,perc=QDKP2log_GetAmounts(self.editedLog)
  local text=QDKP2log_GetReason(self.editedLog)
  newGain=tonumber(newGain)
  newSpent=tonumber(newSpent)
  if (newGain and newGain ~= gain) or
     (newSpent and newSpent ~= spent) or
     text ~= newReason then
    QDKP2log_SetEntry(self.editedPlayer,self.editedLog,self.editedSession,newGain,newSpent,nil,nil,newReason)
    QDKP2_RefreshAll()
  end
end
function myClass.ModifyLog(self,Log,Player,Session)
  self.editedLog=Log
  self.editedPlayer=Player
  self.editedSession=Session
  local gain,spent,hours,perc=QDKP2log_GetAmounts(Log)
  local text=QDKP2log_GetReason(Log)
  QDKP2frame6_ReasonBox:SetText(text or '')
  QDKP2frame6_GainedBox:SetText(gain or '')
  QDKP2frame6_SpentBox:SetText(spent or '')
  myClass:Show()
end

function myClass.DragDropManager(self)
  local what,a1,a2=GetCursorInfo()
  if what=='item' then
    QDKP2frame6_ReasonBox:SetText(a2)
    ClearCursor()
  end
end

QDKP2GUI_LogEntryMod=myClass
