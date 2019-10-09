-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--                   ## GUI ##
--                  Main Window
--



------------ Class Initialization and defaults -------------

local myClass={}

-------------------- WINDOW MANAGEMENT --------------------

--Manages the main window
--todo can be "show", "hide", "toggle" and "refresh"
function myClass.Show(self)
  QDKP2_Toggle(1,true)
  self:Refresh()
end

function myClass.Hide(self)
   QDKP2_ToggleOffAfter(1,true)
end

function myClass.Toggle(self)
   if self.Frame:IsVisible() then
     self:Hide()
   else
     self:Show()
   end
end

function myClass.Refresh(self)
    if not self.Frame:IsVisible() then return; end
    QDKP2_Debug(2, "Refresh","Refreshing Main Window")
    local EditMode=QDKP2_ManagementMode()
    local Session=QDKP2_IsManagingSession()
    local ActiveStringColor={GameFontNormal:GetTextColor()}
    local InactiveStringColor={GameFontDisable:GetTextColor()}
    if EditMode then
      --myClass.raid_text:Enable()
      QDKP2frame1_dkpBox:Enable()
      QDKP2frame1_upbutton:Enable()
      QDKP2frame1_downbutton:Enable()
      --myClass.raidDKP_text:Enable()
      QDKP2frame1_award:Enable()
      --myClass.timer_text:Enable()
      QDKP2frame1_dkpBox_perhr:Enable()
      QDKP2frame1_hourlybonus_upbutton:Enable()
      QDKP2frame1_hourlybonus_downbutton:Enable()
      --myClass.timerDKP_text:Enable()
      QDKP2frame1_onOff:Enable()
      --myClass.timer_status_text:Enable()
      QDKP2frame1_IM:Enable()
      QDKP2frame1_dkpBox_IM:Enable()
      QDKP2frame1_IMbonus_upbutton:Enable()
      QDKP2frame1_IMbonus_downbutton:Enable()
      --myClass.IMDKP_text:Enable()
      QDKP2frame1_ironman:Enable()
      if DBM then
        QDKP2frame1_UseBossMod:Enable()
        QDKP2frame1_UseBossModText:SetTextColor(unpack(ActiveStringColor))
      else
        QDKP2frame1_UseBossMod:Disable()
        QDKP2frame1_UseBossModText:SetTextColor(unpack(InactiveStringColor))
      end
      QDKP2frame1_DetectBids:Enable()
      QDKP2frame1_DetectBidsText:SetTextColor(unpack(ActiveStringColor))
      QDKP2frame1_FixedPrice:Enable()
      QDKP2frame1_FixedPriceText:SetTextColor(unpack(ActiveStringColor))
    else
      --myClass.raid_text:Disable()
      QDKP2frame1_dkpBox:Disable()
      QDKP2frame1_upbutton:Disable()
      QDKP2frame1_downbutton:Disable()
      --myClass.raidDKP_text:Disable()
      QDKP2frame1_award:Disable()
      --myClass.timer_text:Disable()
      QDKP2frame1_dkpBox_perhr:Disable()
      QDKP2frame1_hourlybonus_upbutton:Disable()
      QDKP2frame1_hourlybonus_downbutton:Disable()
      --myClass.timerDKP_text:Disable()
      QDKP2frame1_onOff:Disable()
      --myClass.timer_status_text:Disable()
      QDKP2frame1_IM:Disable()
      QDKP2frame1_dkpBox_IM:Disable()
      QDKP2frame1_IMbonus_upbutton:Disable()
      QDKP2frame1_IMbonus_downbutton:Disable()
      --myClass.IMDKP_text:Disable()
      QDKP2frame1_ironman:Disable()
      QDKP2frame1_UseBossMod:Disable()
      QDKP2frame1_UseBossModText:SetTextColor(unpack(InactiveStringColor))
      QDKP2frame1_DetectBids:Disable()
      QDKP2frame1_DetectBidsText:SetTextColor(unpack(InactiveStringColor))
      QDKP2frame1_FixedPrice:Disable()
      QDKP2frame1_FixedPriceText:SetTextColor(unpack(InactiveStringColor))
    end
    if not QDKP2_OfficerMode() or not QDKP2_IsRaidPresent() then
      QDKP2frame1_CurrentSession:SetText(QDKP2_LOC_NotIntoARaid)
    elseif not Session then
      QDKP2frame1_CurrentSession:SetText("No ongoing session.")
    else
      local _,Name=QDKP2_GetSessionInfo(Session)
      QDKP2frame1_CurrentSession:SetText("Current session: "..QDKP2_COLOR_WHITE..tostring(Name))
    end
    if not Session and QDKP2_IsRaidPresent() and QDKP2_OfficerMode() then
      QDKP2frame1_newSession:Enable()
    else QDKP2frame1_newSession:Disable()
    end
    if Session then QDKP2frame1_closeSession:Enable()
    else QDKP2frame1_closeSession:Disable()
    end
    if QDKP2_IronManIsOn() then QDKP2frame1_ironman:SetText(QDKP2_LOC_Finish)
    else QDKP2frame1_ironman:SetText(QDKP2_LOC_Start)
    end
    if QDKP2_isTimerPaused() then QDKP2frame1_onOff:SetText(QDKP2_LOC_Resume)
    elseif QDKP2_isTimerOn() then QDKP2frame1_onOff:SetText(QDKP2_LOC_Stop)
    else
      QDKP2frame1_onOff:SetText(QDKP2_LOC_Start)
      QDKP2_Frame1_timer_status_text:SetText(QDKP2_COLOR_RED..QDKP2_LOC_TimerStop..".")
    end
    if QDKP2_AutoBossEarn then QDKP2frame1_UseBossMod:SetChecked(1)
    else QDKP2frame1_UseBossMod:SetChecked(0)
    end
    if QDKP2_DetectBids then QDKP2frame1_DetectBids:SetChecked(1)
    else QDKP2frame1_DetectBids:SetChecked(0)
    end
    if QDKP2_FixedPrices then QDKP2frame1_FixedPrice:SetChecked(1)
    else QDKP2frame1_FixedPrice:SetChecked(0)
    end
    -- update the backup's date
    local TimeString
    if QDKP2backup.DATE then
      TimeString = "Last backup: "..QDKP2_GetDateTextFromTS(QDKP2backup.DATE)
    else
      TimeString = "No backup found"
    end
    QDKP2frame1_dkpBox:SetText(QDKP2GUI_Vars.DKP_RaidBonus)
    QDKP2frame1_dkpBox_perhr:SetText(QDKP2GUI_Vars.DKP_Timer)
    QDKP2frame1_dkpBox_IM:SetText(QDKP2GUI_Vars.DKP_IM)
    QDKP2_frame1_BackupDate:SetText(TimeString)
end



-------------------- EVENT MANAGER -----------------------------


--Allows for the up and down arrows to work on frame 1  "+" = up, "-" = down... duh

function myClass.NewSession()
  QDKP2_NewSession("")
end

function myClass.dkpAwardRaidSet(self,todo)
  if not todo then
    QDKP2GUI_Vars.DKP_RaidBonus = 0
  elseif todo=="+" then
    QDKP2GUI_Vars.DKP_RaidBonus = QDKP2GUI_Vars.DKP_RaidBonus + 1
  elseif todo=="-" then
    QDKP2GUI_Vars.DKP_RaidBonus = QDKP2GUI_Vars.DKP_RaidBonus - 1
  elseif tonumber(todo) then
    QDKP2GUI_Vars.DKP_RaidBonus = floor(tonumber(todo))
  end
  myClass:Refresh()
end

--increases and decreases the value of the DKP per hr
function myClass.dkpPerHourSet(self,todo)
  if not todo then
    QDKP2GUI_Vars.DKP_Timer = 0
  elseif todo=="+" then
    QDKP2GUI_Vars.DKP_Timer = QDKP2GUI_Vars.DKP_Timer + 1
  elseif todo=="-" then
    QDKP2GUI_Vars.DKP_Timer = QDKP2GUI_Vars.DKP_Timer - 1
  elseif tonumber(todo) then
    QDKP2GUI_Vars.DKP_Timer = floor(tonumber(todo))
  end
  QDKP2_TimerSetBonus(QDKP2GUI_Vars.DKP_Timer)
  myClass:Refresh()
end

--increases and decreases the value of the DKP of the IronMan bonus
function myClass.dkpIMSet(self,todo)
  if not todo then
    QDKP2GUI_Vars.DKP_IM = 0
  elseif todo=="+" then
    QDKP2GUI_Vars.DKP_IM = QDKP2GUI_Vars.DKP_IM + 1
  elseif todo=="-" then
    QDKP2GUI_Vars.DKP_IM = QDKP2GUI_Vars.DKP_IM - 1
  elseif tonumber(todo) then
    QDKP2GUI_Vars.DKP_IM = floor(tonumber(todo))
  end
  myClass:Refresh()
end

--gives awards DKP
function myClass.Award()
  local mess = "Write the reason of the award\n(leave blank for none)"
  QDKP2_OpenInputBox(mess,QDKP2_GUI_GiveRaidDKP)
end

function QDKP2_GUI_GiveRaidDKP(reason)
  local dkpIncrease = QDKP2frame1_dkpBox:GetText()
  if reason=="" then reason=nil; end
  QDKP2_RaidAward(dkpIncrease,reason)
end


---------------------------------------

--gives Ironman Bonus
function myClass.Ironman(self,Sure)

  if not QDKP2_IronManIsOn() then
    QDKP2_IronManStart()
  else
    local BonusDKP = tonumber(QDKP2frame1_dkpBox_IM:GetText())
    if BonusDKP == 0 then
      if not Sure then
        local mess = "The Raid Bonus is set to 0.\n Do you want to discard IronMan data?"
        QDKP2_AskUser(mess, function() myClass:Ironman(true); end)
        return
      end
      QDKP2_IronManWipe()
      QDKP2_Msg("IronMan data discarded")
    else
      if not Sure then
        local mess = "Close the IronMan bonus and award "..QDKP2frame1_dkpBox_IM:GetText().."\nDKP to the winners?"
        QDKP2_AskUser(mess, function() myClass:Ironman(true); end)
        return
      end
      QDKP2_InronManFinish(BonusDKP)
    end
  end
end
---------------------------------------

--toggles the off/on button for the timer
function myClass.TimerToggle(self)
  if QDKP2_isTimerOn() then
    if QDKP2_isTimerPaused() then
      QDKP2_TimerPause("off")
    elseif IsControlKeyDown() then
      QDKP2_TimerPause("on")
    else
      QDKP2_TimerOff()
    end
  else
    QDKP2_TimerOn()
    QDKP2_TimerSetBonus(QDKP2GUI_Vars.DKP_Timer)
  end
end


---------------------------------------
--Updates the timer tick countdown
function myClass.TimerCountdownRefresh(self,event,timetogo,timenow)
  timetogo=timetogo or 0
  timenow=timenow or 0
  local color=QDKP2_COLOR_GREEN
  local paused=""
  if QDKP2_isTimerPaused() then
    if self.TimerPauseColor then self.TimerPauseColor = nil
    else color=QDKP2_COLOR_RED; self.TimerPauseColor=true; end
  end
  if QDKP2_isTimerOn() then
    local dateStr=date(QDKP2_LOC_GUItimer,timetogo-timenow) or '...'
    QDKP2_Frame1_timer_status_text:SetText(color..dateStr)
  end
end

QDKP2GUI_Main=myClass
