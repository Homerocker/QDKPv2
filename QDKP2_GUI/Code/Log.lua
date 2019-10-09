-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--                   ## GUI ##
--                      Log
--
--[[
The log uses "LogView" classes to define Log modes. each class must be added to QDKP2GUI_Log.LogViews using the
same key as their name.
Each LogView class must contain the following methods:

view.GetList(): Returns a LogVoices list (More about voices later.)
view.GetTitle(): Returns a string used as window's title.
view.VoiceMenu(Voice): Returns a list of menu entries to be added to the voice menu.
view.WindowMenu(): Returns a list of menu entries to be added to the window menu.
view.MakeReport(List,Type,Channel,SubChannel): Called when a report is requested.

ENTRIES:
Entries are dictionaries with the following keys:
Log: The log entry that is represented by the entry. REQUESTED
ID : A unique value that permanently identifies the voice. REQUESTED
all the following keys are optional.
Time: The time to be shown
DKPhist: The amount to be shown in the log, 1st position. Usually used for the Net DKP history.
DKPchange: The amount to be shown in the log, 2nd position. Usually used for the Net DKP change.
Desc: The description field.
Player: If the log is relative to a player that name should go here.
SubList: A list with sub voices. Used, for example, by the Session entries.
SubListID : A unique value that permanently identifies the Sublist. In the Session entries is the session's SID.
isChild : Used in the voices in the SubSection lists, it points to the parent voice.

MENU VOICES:
A menu voice is defined with a dictionary with all the keys defined by UIDropDownMenu. Most notably:
title: the string that will be shown in the menu
func: The function to be called when the menu entry is clicked.
disabled: If true the log entry will be grayed and unclickable.
checked: a function that return true or false/nil. If true the menu voice will have a check icon near to it.
The following keys are specific to QDKP:
dclick: Used when a Log Voice is double clicked. QDKP will search the first menu entry with this flag set to true
        and will execute its "func" field.

NOTABLE GLOBALS:
All log window variables are available under QDKP2GUI_Log. Most notable variables are:
QDKP2GUI_Log.MainSelection: The main selection of the current view. Used in the player log to select the player.
QDKP2GUI_Log.MenuVoice: To be used in menu-related methods, this variable represent the log voice that has been clicked. That is, the entry that generated the menu.
]]--

------------ Class Initialization and defaults -------------


local myClass={}

myClass.ServiceList={}
myClass.List={}
myClass.Expanded={}
myClass.Childs={}
myClass.ENTRIES=25
myClass.Offset=0
myClass.EntryName="QDKP2_frame5_entry"
myClass.Type='player'
myClass.LogViews={}
myClass.History={}


function myClass.OnLoad(self)
  myClass.Frame=this
  myClass.MenuFrame = CreateFrame("Frame", "QDKP2_Frame5_DropDownMenu", myClass.Frame , "UIDropDownMenuTemplate")
  myClass.SubMenuFrame = CreateFrame("Frame", "QDKP2_Frame5_DropDownSubMenu", myClass.MenuFrame , "UIDropDownMenuTemplate")
end

-------------------- Window management ----------------------


function myClass.Show(self)
  QDKP2_Toggle(5, true)
  myClass:Refresh()
end

function myClass.Hide(self)
   QDKP2_FramesOpen[5]=false
   myClass.Frame:Hide()
end

function myClass.Toggle(self)
  if myClass.Frame:IsVisible() then
    myClass:Hide()
  else
    myClass:Show()
  end
end


function myClass.Refresh(self,doNotUpdate)
  if not myClass.Frame:IsVisible() then return; end
  QDKP2_Debug(3, "GUI-Log","Refreshing")

  myClass.ViewClass=myClass.LogViews[myClass.Type]
  if not doNotUpdate then
    QDKP2_Debug(2, "GUI-Log","Updating list")
    myClass.ServiceList=myClass.ViewClass:GetList(myClass.MainSelection)
    myClass:UpdateExpanded()
  end

  if myClass.Offset > #myClass.List then myClass.Offset = #myClass.List-1; end
  if myClass.Offset < 0 then myClass.Offset = 0; end

  for i=1,myClass.ENTRIES do
    local ParentName="QDKP2_frame5_entry"..tostring(i)
    local indexAt = i+myClass.Offset
    if (indexAt <= #myClass.List) then
      local Voice=myClass.List[indexAt]
      getglobal(ParentName.."_date"):SetText(Voice.Time);
      if Voice.DKPhist then getglobal(ParentName.."_net"):SetText(Voice.DKPhist);
      else getglobal(ParentName.."_net"):SetText("")
      end
      if Voice.DKPchange then getglobal(ParentName.."_mod"):SetText(Voice.DKPchange);
      else getglobal(ParentName.."_mod"):SetText("");
      end
      local description=Voice.Desc or "NIL"
      if Voice.isChild then description="   "..description; end
      getglobal(ParentName.."_action"):SetText(description);
      local logType=Voice.Type
      if logType==QDKP2LOG_LINK then --the GetType function is not trasparent to links, so I have to explicit the case.
        local linkedLog=QDKP2log_FindLink(Voice.Log)
        logType=QDKP2log_GetType(linkedLog)
      end
      local colors=QDKP2log_GetEntryColor(logType)
      local netColors=QDKP2log_GetEntryColor("Default")
      local amountColors=netColors
      if Voice.DKPhist and Voice.DKPhist<0 then netColors=QDKP2log_GetEntryColor("NegativeDKP")
      elseif Voice.DKPhist and Voice.DKPhist>0 then netColors=QDKP2log_GetEntryColor("PositiveDKP")
      end
      if QDKP2_IsDeletedEntry(Voice.Type) then amountColors=QDKP2log_GetEntryColor("LostDKP")
      elseif Voice.DKPchange and Voice.DKPchange<0 then amountColors=QDKP2log_GetEntryColor("NegativeDKP")
      elseif Voice.DKPchange and Voice.DKPchange>0 then amountColors=QDKP2log_GetEntryColor("PositiveDKP")
      end
      getglobal(ParentName.."_date"):SetVertexColor(colors.r, colors.g, colors.b, 1)
      getglobal(ParentName.."_action"):SetVertexColor(colors.r, colors.g, colors.b, 1)
      getglobal(ParentName.."_net"):SetVertexColor(netColors.r, netColors.g, netColors.b, 1)
      getglobal(ParentName.."_mod"):SetVertexColor(amountColors.r, amountColors.g, amountColors.b, 1)
      local expandeBtn=getglobal(ParentName.."_expande")
      if Voice.SubList then
        expandeBtn:Show()
        if myClass.Expanded[Voice.ID] then expandeBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
        else expandeBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
        end
      else
        expandeBtn:Hide()
      end
      getglobal(ParentName):Show();
      if myClass.Selected==Voice.ID then getglobal(ParentName.."_Highlight"):Show()
      else getglobal(ParentName.."_Highlight"):Hide()
      end
    else
      getglobal(ParentName):Hide();
    end
  end
  QDKP2_Frame5_Header:SetText(myClass.ViewClass:GetTitle())

  local numEntries=myClass.ENTRIES
  if #myClass.List<numEntries then numEntries=#myClass.List; end
  FauxScrollFrame_Update(QDKP2_frame5_scrollbar,#myClass.List,numEntries,16);
end

function myClass.UpdateExpanded(self)
  local list={}
  for i=1,#myClass.ServiceList do
    local v=myClass.ServiceList[i]
    table.insert(list,v)
    if v.SubList and myClass.Expanded[v.ID] then
      for j=1,#v.SubList do table.insert(list,v.SubList[j]); end
    end
  end
  myClass.List=list
end

function myClass.SelectPlayer(self,name)
  name=QDKP2_GetMain(name)
  local Type='player'
  --if name=="RAID" then Type='raid'; end
  myClass:GoTo(Type,name,QDKP2_SID.MANAGING,nil,true) --reset History
end

function myClass.ShowPlayer(self,name)
  if not QDKP2_IsInGuild(name) then
    QDKP2_Debug(1,"GUI-Log","Trying to show the log of an inexisting guild player: "..tostring(name))
    return
  end
  myClass.Frame:Show()
  myClass:SelectPlayer(name)
end

function myClass.ShowRaid(self,name)
  myClass.Frame:Show()
  myClass:SelectPlayer('RAID')
end

---------------------- OnClick functions --------------------------

function myClass.LeftClick()
  QDKP2GUI_CloseMenus()
  local Voice=QDKP2GUI_GetClickedEntry(myClass)
  if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
    ChatFrameEditBox:Insert((Voice.Time or 'Unknown timestamp')..' - '..(Voice.Desc or "NIL"))
    return
  elseif QDKP2_OfficerMode() and QDKP2GUI_IsDoubleClick(myClass) then
    myClass:VoiceMenu(Voice,true)
  end
  myClass:SelectVoice(Voice)
end

function myClass.RightClick()
  QDKP2GUI_CloseMenus()
  local Voice=QDKP2GUI_GetClickedEntry(myClass)
  myClass:SelectVoice(Voice)
  myClass:VoiceMenu(Voice)
end

function myClass.ExpandeToggle(self,Voice)
  QDKP2GUI_CloseMenus()
  Voice=Voice or QDKP2GUI_GetClickedEntry(myClass,"_expande")
  local ID=Voice.ID
  if myClass.Expanded[ID] then myClass.Expanded[ID]=false
  else myClass.Expanded[ID]=true
  end
  myClass:UpdateExpanded()
  myClass:Refresh(true)
end

---------- Entries Selection --------------------


function myClass.SelectVoice(self,Voice)
  if Voice then myClass.Selected=Voice.ID
  else myClass.Selected=nil
  end
  myClass:Refresh(true) --no need to update the list, only to refresh the graphic.
end

function myClass.CollapseAll()
  QDKP2GUI_CloseMenus()
  myClass.Expanded={}
  myClass:UpdateExpanded()
  myClass:Refresh()
end

function myClass.ExpandeAll()
  for i,Voice in pairs(myClass.ServiceList) do
    if Voice.SubList then myClass.Expanded[Voice.ID]=true; end
  end
  myClass:UpdateExpanded()
  myClass:Refresh()
end

function myClass.GoTo(self,Type,MainSelection,SubListID,ID,resetHistory)
-- This function is used to jump to a new Log View. Manages the history lists.
-- arguments:
-- Type: The type of the log. if omitted, the actual log view will be used.
-- MainSelection: Optional. the main selection of the log Type, if used.
-- SubListID: The SubListID to search ID in (SID). If not provided GoTo will only search in the Top Level entries.
-- ID the ID to select. if nil then no entry will be selected.
-- resetHistory: Normally, GoTo will store the previous log state in a history stack. Set this to true to clear the history.
  QDKP2_Debug(2,"GUI-Log","Changing log view: Type="..tostring(Type))
  QDKP2GUI_CloseMenus()
  if resetHistory then
    myClass.History={}
  else
    local Hist={}
    Hist.Type=myClass.Type
    Hist.MainSelection=myClass.MainSelection
    Hist.Expanded=myClass.Expanded
    Hist.Offset=myClass.Offset
    Hist.Selected=myClass.Selected
    table.insert(myClass.History,1,Hist)
  end
  local Type=Type or myClass.Type
  if Type ~= myClass.Type then
    myClass.Expanded={}
    myClass.Type=Type
  end
  myClass.MainSelection = MainSelection
  myClass.Offset=0
  myClass.Selected=nil
  myClass.ShowingTooltip=nil
  myClass.ViewClass=myClass.LogViews[myClass.Type]
  if not myClass.Frame:IsVisible() then return; end
  local doNotUpdate
  if SubListID or ID then
    QDKP2_Debug(2,"GUI-Log","Updating Log within the goto function.")
    myClass.ServiceList=myClass.ViewClass:GetList(myClass.MainSelection)
    doNotUpdate=true
    if SubListID then
      for i,v in pairs(myClass.ServiceList) do
        if v.SubListID==SubListID then
          myClass.Expanded[v.ID]=true
          myClass.Offset=i
          break
        end
      end
    end
    myClass:UpdateExpanded()
    if ID then
      for i,v in pairs(myClass.List) do
        if v.ID==ID then
          myClass.Offset=i-10
          myClass.Selected=v.ID
          if myClass.Offset<0 then myClass.Offset=0; end
        end
      end
    end
  end
  if myClass.Offset<=myClass.ENTRIES then myClass.Offset=0; end
  myClass.Offset=myClass.Offset-10
  if myClass.Offset<0 then myClass.Offset=0; end
  myClass:Refresh(doNotUpdate)
end

------------------------------ Report ---------------------------------

local function isTargetGoodReport()
  if UnitName("target") and UnitIsPlayer("target") and UnitIsFriend("player","target") then return true; end
end

function myClass.Report(self,Type,channel,channelSub)
  if not myClass.MenuVoice then
    error("QDKP2GUI Log's Report function can only be called when a log voice has been stored MenuVoice.")
  end
  QDKP2GUI_CloseMenus()
  local reportFunc=myClass.ViewClass.MakeReport
  if not reportFunc then
    QDKP2_Msg("Reporting is not supported by the actual log type.","WARNING")
    return
  end
  if channel=="WHISPEROWNER" then
    channel="WHISPER"
    channelSub=myClass.MenuVoice.Player or myClass.MainSelection
    if not QDKP2online[channelSub] then return; end
  elseif channel=="WHISPERTARGET" then
    if not isTargetGoodReport() then return; end
    channel="WHISPER"
    channelSub=UnitName("target")
  elseif channel=="WHISPER" and not channelSub then
    QDKP2_OpenInputBox("Enter the name of the character to report to.",function(arg,Type,channel)
      myClass:Report(Type,channel,arg);
    end, Type, channel)
    return
  elseif channel=="CHANNEL" and not channelSub then
    QDKP2_OpenInputBox("Enter the name of the channel to report to.",function(arg,Type,channel)
      myClass:Report(Type,channel,arg);
    end, Type, channel)
    return
  end
  local reportLines
  local list
  if Type=="this" then
    list={myClass.MenuVoice}
  elseif Type=="sub" then
    local Voice=myClass.MenuVoice.isChild or myClass.MenuVoice
    list=Voice.SubList
  elseif Type=="curr" then
    list=self.List
  end
  if not list or #list==0 then return; end
  local reportLines=reportFunc(list,Type,channel,channelSub)
  QDKP2_SendList(reportLines,channel,channelSub)
end

local ChannelMenu={
{text="Guild", func=function() myClass:Report(UIDROPDOWNMENU_MENU_VALUE,"GUILD"); end},
{text="Officer", func=function() myClass:Report(UIDROPDOWNMENU_MENU_VALUE,"OFFICER"); end},
{text="Raid", func=function() myClass:Report(UIDROPDOWNMENU_MENU_VALUE,"RAID"); end},
{text="Party", func=function() myClass:Report(UIDROPDOWNMENU_MENU_VALUE,"PARTY"); end},
{text="Say", func=function() myClass:Report(UIDROPDOWNMENU_MENU_VALUE,"SAY"); end},
{text="Yell", func=function() myClass:Report(UIDROPDOWNMENU_MENU_VALUE,"YELL"); end},
{func=function() myClass:Report(UIDROPDOWNMENU_MENU_VALUE,"WHISPEROWNER"); end},
{text="Whisper Target", func=function() myClass:Report(UIDROPDOWNMENU_MENU_VALUE,"WHISPERTARGET"); end},
{text="Whisper to...", func=function() myClass:Report(UIDROPDOWNMENU_MENU_VALUE,"WHISPER"); end},
{text="Channel...", func=function() myClass:Report(UIDROPDOWNMENU_MENU_VALUE,"CHANNEL"); end},
}

local ReportMenu={
{text="This entry",
hasArrow=true,
value="this",
menuList=ChannelMenu,
},
{text="Subsection",
hasArrow=true,
value="sub",
menuList=ChannelMenu,
},
{text="Current Window",
hasArrow=true,
value="curr",
menuList=ChannelMenu,
},
}

------------------------------- Menu ----------------------------------
local function NYIfunc()
  QDKP2_Msg("To be done")
end

local LogVoices={

DisenchantedLoot={text="Disenchanted loot",
checked=function()
  local Bit0=QDKP2log_GetFlags(myClass.MenuVoice.Log)
  return Bit0
end,
func=function()
  local Bit0=QDKP2log_GetFlags(myClass.MenuVoice.Log)
  if Bit0 then Bit0=nil
  else Bit0=true
  end
  QDKP2log_SetFlags(myClass.MenuVoice.Log,Bit0)
  myClass:Refresh()
end
},

ChargePlayer={text="Charge looter",
  func=function()
  local name=QDKP2GUI_Log.MenuVoice.Player
  local itemStr=QDKP2log_GetReason(QDKP2GUI_Log.MenuVoice.Log)
  local itemName,itemLink=GetItemInfo(itemStr or '')
  if name and itemLink then
    QDKP2_OpenToolboxForCharge(name,nil,itemLink)
  end
end,
  dclick=true,
},

ModifyEntry={text="Edit DKP amounts...",
func=function()
  local SID=(myClass.MenuVoice.isChild or {}).SubListID or '0'
  QDKP2GUI_LogEntryMod:ModifyLog(myClass.MenuVoice.Log, myClass.MenuVoice.Player, SID)
end,
dclick=true,
},

EnableEntry={text="Enable DKP entry",
checked=function()
  if QDKP2_IsActiveDKPEntry(myClass.MenuVoice.Type) then return true; end
end,
func=function()
  local SID='0'
  if myClass.MenuVoice.isChild then SID=myClass.MenuVoice.isChild.SubListID; end
  QDKP2log_UnDoEntry(myClass.MenuVoice.Player,myClass.MenuVoice.Log, SID)
  QDKP2_RefreshAll()
end
},

EditMain={text="Edit main entry...",
func=function()
  local SID=(myClass.MenuVoice.isChild or {}).SubListID or '0'
  local vLog,vSID,vPlayer=QDKP2log_GetMainDKPEntry(myClass.MenuVoice.Log,SID)
  if vLog then
    QDKP2GUI_LogEntryMod:ModifyLog(vLog, vPlayer, vSID)
  else
    QDKP2_Msg("Can't find the main DKP entry.","ERROR")
  end
end},

SetAwRatio={text="Set award ratio...",
func=function()
  local _,_,_,oldCoeff=QDKP2log_GetAmounts(myClass.MenuVoice.Log)
  local txt="Insert the percentage of the award you\nwant to give to "..tostring(myClass.MenuVoice.Player)..".\nMust be between 0% and 250%."
  QDKP2_OpenInputBox(txt,function(newCoeff,Voice)
    if not newCoeff or newCoeff=='' then return; end
    newCoeff=string.gsub(newCoeff,"%%",'') --strip down percentages
    newCoeff=tonumber(newCoeff or '')
    if not newCoeff or newCoeff<0 or newCoeff>250 then
      QDKP2_Msg("Please enter a valid integer percentage from 0% to 250%.","ERROR")
      return
    end
    newCoeff=math.floor(newCoeff)
    local SID=(myClass.MenuVoice.isChild or {}).SubListID or '0'
    local vLog,vSID,vPlayer=QDKP2log_GetMainDKPEntry(myClass.MenuVoice.Log,SID)
    if not vLog then
      QDKP2_Msg("Can't find the main DKP entry.","ERROR")
      return
    end
    QDKP2log_SetEntry(Voice.Player,Voice.Log,SID,nil,nil,nil,newCoeff)
    QDKP2log_UpdateLinkedDKPLog(vPlayer, vLog, vSID) --update the linked DKP entry
    QDKP2_RefreshAll()
    end,myClass.MenuVoice)
  QDKP2_InputBox_SetDefault(tostring(oldCoeff or 100)..'%')
end,
dclick=true,
},

IncludePlayer={text="Award player",
checked=function()
  if not QDKP2_IsNODKPEntry(myClass.MenuVoice.Type) then return true; end
end,
func=function()
  local SID=myClass.MenuVoice.isChild.SubListID
  QDKP2log_AwardLinkedEntry(myClass.MenuVoice.Player,myClass.MenuVoice.Log,SID)
  QDKP2_RefreshAll()
end
},

ViewSession={text="View session in RAID Log",
func=function()
  local SID=myClass.MenuVoice.SubListID
  myClass:GoTo("player","RAID",SID)
end,
},

ViewLinked={text="View $PLAYER's log.",
func=function()
  local Type='player'
  local Player=myClass.MenuVoice.Player
  local SID=(myClass.MenuVoice.isChild or {}).SubListID
  if not Player or not SID then return
  elseif Player=='RAID' then Type='raid'; Player=nil
  end
  myClass:GoTo(Type,Player,SID,QDKP2log_GetTS(myClass.MenuVoice.Log))
end
},

ChangeSessName={text="Change Session name...",
func=function()
  local SID=myClass.MenuVoice.SubListID
  local List,Name=QDKP2_GetSessionInfo(SID)
  if not List then return; end
  Name=string.sub(Name or "",2,-2)
  if Name==QDKP2_LOC_NoSessName then Name=''; end
  QDKP2_OpenInputBox("Insert the new name for the selected\nsession.",function(NewSessionName,SID)
  QDKP2log_SetSessionName(SID,NewSessionName)
  end,SID)
  QDKP2_InputBox_SetDefault(Name)
  myClass:Refresh()
end,
},

ExportSession={text="Export Session (rollup)",
func=function()
	local SID=myClass.MenuVoice.SubListID
	QDKP2_Export_Popup("logsession",nil,SID)
end,
},

ExportExtSession={text="Export Session (detailed)",
func=function()
  local SID=myClass.MenuVoice.SubListID
	QDKP2_Export_Popup("extlogsession",nil,SID)
end,
},

ExportCurrView={text="Export current Log view",
func=function()
	local LogList={}
	for i,entry in ipairs(myClass.List) do
		table.insert(LogList,entry.Log)
	end
	QDKP2_Export_Popup("loglist",nil,LogList)
end,
},

ClearSel={text="Clear Selection",
  func=function() myClass.SelectVoice(nil); end,
},

Expand={text="Expand voice",
checked=function() if myClass.Expanded[myClass.MenuVoice.ID] then return true; end; end,
dclick=true,
func=function() myClass:ExpandeToggle(myClass.MenuVoice); end,
},

ShowInfo={text="Show entry info",
  func=function()
  if myClass.MakeTooltip[myClass.MenuVoice.Type] then
    local list
    list=myClass.MakeTooltip[myClass.MenuVoice.Type](myClass.MenuVoice)
    GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT");
    for i,v in pairs(list) do GameTooltip:AddLine(v); end
    GameTooltip:Show()
  end
end},

Report={text="Report Log",menuList=ReportMenu,hasArrow=true},
CollapseAll={text="Collapse All", func=myClass.CollapseAll},
ExpandeAll={text="Expande All", func=myClass.ExpandeAll},
LogUpdate={text="Update Log", func=myClass.Refresh},
MenuClose={text="Close menu", func=QDKP2GUI_CloseMenus},
spacer={text="", notClickable=true},
}

function QDKP2GUI_CloseMenus()
  CloseDropDownMenus(1)
end


function myClass.VoiceMenu(self,Voice,exe)
  if not QDKP2_OfficerMode() then return; end
  QDKP2GUI_CloseMenus()
  --If voice is a link, I must create a virtual voice that does resemble the linked entry
  if Voice.Type==QDKP2LOG_LINK then
    local tempVoice={}
    QDKP2_CopyTable(Voice,tempVoice)
    local LinkedLog, LinkedPlayer, _, SID = QDKP2log_FindLink(Voice.Log)
    tempVoice.Log=LinkedLog
    tempVoice.Type=QDKP2log_GetType(LinkedLog)
    tempVoice.Player=LinkedPlayer
    -- isChild should not be changed as cross-session links are not supported.
    tempVoice.isLink=true --this is a flag i use to let the program know this is a link.
    Voice=tempVoice
  end
  myClass.MenuVoice=Voice
  local linkEntry=QDKP2_IsLinkDKPEntry(Voice.Log)
  local B0,B1,B2,B3,V0,V1=QDKP2log_GetFlags(QDKP2GUI_Log.MenuVoice.Log)

  local menu=myClass.ViewClass:VoiceMenu(Voice) or {}

  table.insert(menu,1,{text="Log Entry Menu",isTitle=true})
  if QDKP2_IsDKPEntry(Voice.Type) and not linkEntry and Voice.Type~=QDKP2LOG_EXTERNAL then
    table.insert(menu,LogVoices.ModifyEntry)
    table.insert(menu,LogVoices.EnableEntry)
  end
  if linkEntry then
    table.insert(menu,LogVoices.EditMain)
    table.insert(menu,LogVoices.IncludePlayer)
    table.insert(menu,LogVoices.SetAwRatio)
  end
  if Voice.Type==QDKP2LOG_SESSION then
    table.insert(menu,LogVoices.ChangeSessName)
    if myClass.Type ~= "player" or myClass.MainSelection~='RAID' then
      table.insert(menu,LogVoices.ViewSession)
    end
		table.insert(menu,LogVoices.ExportSession)
    table.insert(menu,LogVoices.ExportExtSession)
  end
  if Voice.Type==QDKP2LOG_LOOT then
    if (myClass.MenuVoice.isChild or {}).SubListID == QDKP2_IsManagingSession() and not B0 then
      table.insert(menu,LogVoices.ChargePlayer)
    end
    table.insert(menu,LogVoices.DisenchantedLoot)
  end
  if Voice.SubList then
    table.insert(menu,LogVoices.Expand)
  end
  if Voice.isLink then
    LogVoices.ViewLinked.text=string.gsub(LogVoices.ViewLinked.text, "$PLAYER", tostring(Voice.Player))
    table.insert(menu,LogVoices.ViewLinked)
  end
  if #menu>1 then table.insert(menu,LogVoices.spacer); end --if I have anything else than the title then space them
  table.insert(menu,LogVoices.Report)
  if myClass.MakeTooltip[Voice.Type] then
    table.insert(menu,LogVoices.ShowInfo)
  end
  table.insert(menu,LogVoices.MenuClose)
  local dclick
  for i,v in pairs(menu) do
    if v.dclick then
      dclick=v
      if exe then dclick.func(); return
      else dclick.colorCode="|cFFBBFFBB"; break  --this will color the entry that is going to be executed on double click.
      end
    end
  end
  if Voice.isChild or Voice.SubList then
    ReportMenu[2].disabled=false
    ReportMenu[2].hasArrow=true
  else
    ReportMenu[2].disabled=true
    ReportMenu[2].hasArrow=false
  end
  if isTargetGoodReport() then ChannelMenu[8].disabled=false
  else ChannelMenu[8].disabled=true
  end
  if QDKP2_IsInGuild(Voice.Player or myClass.MainSelection) then
    ChannelMenu[7].text=string.gsub("Whisper to $NAME","$NAME",Voice.Player or myClass.MainSelection)
    ChannelMenu[7].disabled=false
  else
    ChannelMenu[7].text="Whisper to log owner"
    ChannelMenu[7].disabled=true
  end
  EasyMenu(menu, myClass.MenuFrame, "cursor",0,0, "MENU")
  if dclick then dclick.colorCode=nil; end
end

function myClass.WindowMenu(self)
  QDKP2GUI_CloseMenus()
  local menu=myClass.ViewClass:WindowMenu() or {}
  table.insert(menu,{text="Log Window Menu",isTitle=true})
  table.insert(menu,LogVoices.CollapseAll)
  table.insert(menu,LogVoices.ExpandeAll)
	table.insert(menu,LogVoices.ExportCurrView)
  table.insert(menu,LogVoices.LogUpdate)
  table.insert(menu,LogVoices.MenuClose)
  EasyMenu(menu, myClass.MenuFrame, "cursor",0,0, "MENU")
end


---------------- Tooltip generators ------------------


local function Maketooltip_NewLine(out, Key, Value)
  table.insert(out,QDKP2_COLOR_YELLOW..Key..': '..QDKP2_COLOR_WHITE..tostring(Value or '-'))
end

local function Maketooltip_DKPEntry(Voice)
  local Log=Voice.Log
  local Type,Time,Action,Version,Amounts,ModBy,ModDate,Flags,Creator = QDKP2log_GetData(Log)
  local SID
  if Voice.isChild then
    SID=Voice.isChild.SubListID
  else
    SID='0'
  end
  local out={}
  Maketooltip_NewLine(out, 'Log type', QDKP2log_LogTypesDict[Type])
  Maketooltip_NewLine(out, 'Created by', QDKP2log_GetCreator(Log,SID))
  table.insert(out,' ')
  if ModDate then
    Maketooltip_NewLine(out, 'Last modified on', QDKP2_GetDateTextFromTS(ModDate))
    Maketooltip_NewLine(out, 'By', QDKP2log_GetModder(Log, SID))
    table.insert(out,' ')
  end
  Maketooltip_NewLine(out, 'Version #', Version or 0)
  return out
end

local function Maketooltip_Session(Voice)
  local Log=Voice.Log
  local Type,Time,Action,Version,Amounts,ModBy,ModDate,Flags,Creator = QDKP2log_GetData(Log)
  local SID=Voice.SubListID
  local GainDKP,SpentDKP,GainHours,Partecipants,totalDrop,BossKilled=QDKP2log_SessionStatistics(SID)
  local List,Name,Mantainer,Code,DateStart,DateStop,DateMod=QDKP2_GetSessionInfo(SID)
  local ModID,ModDate,ModName=QDKP2_GetSessionMods(SID)
  local out={}
  Maketooltip_NewLine(out, 'SID', Action)
  Maketooltip_NewLine(out, 'Manager', Mantainer)
  table.insert(out,' ')
  Maketooltip_NewLine(out, 'Started on', QDKP2_GetDateTextFromTS(DateStart))
  Maketooltip_NewLine(out, 'Closed on', QDKP2_GetDateTextFromTS(DateStop))
  table.insert(out,' ')
  if ModDate then
    Maketooltip_NewLine(out, 'Last modified on', QDKP2_GetDateTextFromTS(ModDate))
    Maketooltip_NewLine(out, 'By', ModName)
    Maketooltip_NewLine(out, 'Cumulative version index', ModID)
    table.insert(out,' ')
  end
  Maketooltip_NewLine(out, 'Partecipants', Partecipants) --??
  Maketooltip_NewLine(out, 'Total DKP gained', GainDKP)
  Maketooltip_NewLine(out, 'Total DKP spent', SpentDKP)
  Maketooltip_NewLine(out, 'Bosses slain', BossKilled)
  Maketooltip_NewLine(out, 'Items looted',totalDrop)
  local avgAward='-'
  local avgSpent='-'
  local avgDrop='-'
  local avgPrice='-'
  if Partecipants and Partecipants>0 then
    avgAward=math.floor((GainDKP or 0)*100/Partecipants)/100.0
    avgSpent=math.floor((SpentDKP or 0)*100/Partecipants)/100.0
    avgDrop=math.floor((totalDrop or 0)*100/Partecipants)/100.0
  end
  if totalDrop>0 then
    avgPrice=math.floor((SpentDKP or 0)*100/totalDrop)/100.0
  end
  Maketooltip_NewLine(out, 'Avg DKP+/Player', avgAward)
  Maketooltip_NewLine(out, 'Avg DKP-/Player', avgSpent)
  Maketooltip_NewLine(out, 'Avg Loot/Player', avgDrop)
  Maketooltip_NewLine(out, 'Avg DKP-/Loot', avgPrice)
  return out
end

myClass.MakeTooltip = {}

myClass.MakeTooltip[QDKP2LOG_CONFIRMED]=Maketooltip_DKPEntry
myClass.MakeTooltip[QDKP2LOG_MODIFY]=Maketooltip_DKPEntry
myClass.MakeTooltip[QDKP2LOG_ABORTED]=Maketooltip_DKPEntry
myClass.MakeTooltip[QDKP2LOG_NODKP]=Maketooltip_DKPEntry
myClass.MakeTooltip[QDKP2LOG_SESSION]=Maketooltip_Session



-------------------- Scroll --------------------------


function myClass.ScrollBarUpdate()
  myClass.Offset=FauxScrollFrame_GetOffset(QDKP2_frame5_scrollbar)
  myClass:Refresh(true) --no need to update the list, only to refresh the graphic.
end

QDKP2GUI_Log=myClass
