-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--          ## GUI FUNCTIONS ##


-------------------GUI Constants-------------------------------

QDKP2_FramesOpen = {}

------------------GUI DEFAULTS---------------------------------
QDKP2_dkpPerHour = 10
QDKP2_dkpIM = 10
QDKP2_dkpAwardRaid = 10
QDKP2_dkpMenuAward = 10

----------------------------------------TOGGLES------------------------
--Brings up popup GUI
function QDKP2_Toggle_Main(showFrame) --showFrame is optional
  if not QDKP2_ACTIVE then
    QDKP2_Msg("Quick DKP is not fully initialized yet. Please wait 5 seconds and try again.","WARNING")
    return
  end
  if QDKP2_OfficerMode() then QDKP2GUI_Main:Toggle()
  else QDKP2GUI_Roster:Toggle()
  end
end


--toggles it so that it will hide windows past closed window, but shows them if that one is opened again
function QDKP2_SmartToggle(toggleFrame)
  if(QDKP2_FramesOpen[toggleFrame]) then
    QDKP2_FramesOpen[toggleFrame]=false
  else
    QDKP2_FramesOpen[toggleFrame]=true
  end

  for i=1, 5 do
    local incFrame = getglobal("QDKP2_Frame"..i)
    if(QDKP2_FramesOpen[i]) then
      if QDKP2_OfficerMode() or (i==2 or i==5) then
        incFrame:Show()
      end
    else
      incFrame:Hide()
    end
  end
end


--toggles target frame.. secondvar is optional
function QDKP2_Toggle(frameNum, showFrame)
  local incFrame = getglobal("QDKP2_Frame"..frameNum)
  if incFrame then
    if showFrame==true then
      if QDKP2_OfficerMode() or (frameNum==2 or frameNum==5) then
        incFrame:Show()
        QDKP2_FramesOpen[frameNum] = true
      end
    elseif showFrame==false then
      incFrame:Hide();
      QDKP2_FramesOpen[frameNum] = false
    else
      if incFrame:IsVisible() then
        incFrame:Hide();
        QDKP2_FramesOpen[frameNum] = false
      else
        if QDKP2_OfficerMode() or (frameNum==2 or frameNum==5) then
	  incFrame:Show()
          QDKP2_FramesOpen[frameNum] = true
	end
      end
    end
  end
end

---------------------------------------

--Toglges all frames after index off, but only first on
function QDKP2_ToggleOffAfter(index)

  local temp = getglobal("QDKP2_Frame"..index)
  local isOn = false
  if(temp:IsVisible() ) then
    isOn = true
    local incFrame = getglobal("QDKP2_Frame"..index)
    incFrame:Hide();
  else
    local incFrame = getglobal("QDKP2_Frame"..index)
    if QDKP2_OfficerMode() or (index==2 or index==5) then incFrame:Show(); end
  end

  if index <= 1 and isOn then
    QDKP2GUI_Roster.SelectedPlayers={}
    QDKP2GUI_Log:Hide()
  end
  if index == 5 and isOn then
    QDKP2GUI_Log:Hide()
    QDKP2_Refresh_ModifyPane("hide")
  end
  for i=index, 4 do
    local incFrame = getglobal("QDKP2_Frame"..i)
    if(isOn == true ) then
      incFrame:Hide();
    end

  end
end

---------------------------------------

--Toggles all frames after index off/on
function QDKP2_ToggleAfter(index)
  local temp = getglobal("QDKP2_Frame"..index)
  local isOn = false
  if(temp:IsVisible() ) then
    isOn = true
    local incFrame = getglobal("QDKP2_Frame"..index)
    incFrame:Hide();
  else
    local incFrame = getglobal("QDKP2_Frame"..index)
    if QDKP2_OfficerMode() or (index==2 or index==5) then incFrame:Show(); end
  end
  if index <= 1 and isOn then
    QDKP2GUI_Roster.SelectedPlayers={}
    QDKP2GUI_Log:Hide()
  end
  if index == 5 and isOn then
    QDKP2GUI_Log:Hide()
  end
  for i=index, 4 do
    local incFrame = getglobal("QDKP2_Frame"..i)
    if(isOn == true ) then
      incFrame:Hide();
    else
      if QDKP2_OfficerMode() or (i==2 or i==5) then incFrame:Show(); end
    end
  end
end

---------------------------------------Frame Utility---------------

function QDKP2_RefreshAll()
  QDKP2GUI_Main:Refresh()
  QDKP2GUI_Roster:Refresh(true) --forces a resort
  QDKP2GUI_Log:Refresh()
  QDKP2GUI_Toolbox:Refresh()
  --QDKP2_Refresh_ModifyPane("refresh")
end

function QDKP2GUI_GetClickedEntry(class,suffix)
  local buttonName = this:GetName()
  suffix=suffix or ""
  local indexFromButton = 0
  for i=1, class.ENTRIES do
    local button = class.EntryName..tostring(i)..suffix
    if buttonName==button then
      indexFromButton = i
      break
    end
  end
  local EntryIndex= indexFromButton + class.Offset
  return class.List[EntryIndex],EntryIndex
end

function QDKP2GUI_IsDoubleClick(class)
  local double
  local itemName=this:GetName()
  if class.DoubleClick_Time and time()-class.DoubleClick_Time<0.2 and class.DoubleClick_Name==itemName then double=true; end
  class.DoubleClick_Time=time()
  class.DoubleClick_Name=itemName
  return double
end

function QDKP2GUI_CloseMenus()
  CloseDropDownMenus(1)
  QDKP2GUI_LogEntryMod:Hide()
end
