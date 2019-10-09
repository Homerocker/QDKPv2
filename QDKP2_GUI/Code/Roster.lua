-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--                   ## GUI ##
--                     Roster
--


------------ Class Initialization and defaults -------------

local myClass={}

myClass.Offset=0
myClass.Sel="guild"
myClass.ENTRIES=20
myClass.LINES_ON_SCROLL=10
myClass.SelectedPlayers= {}
myClass.LastClickIndex=1
myClass.EntryName="QDKP2_frame2_entry"
myClass.Sort={}
myClass.Sort.Order="Alpha"
myClass.Sort.LastLen=0

myClass.PlayersColor={}
myClass.PlayersColor.Default={r=1,g=1,b=1}
myClass.PlayersColor.Modified={r=0.27,g=0.92,b=1}
myClass.PlayersColor.Standby={r=1,g=0.7,b=0}
myClass.PlayersColor.Alt={r=1,g=0.3,b=1}
myClass.PlayersColor.External={r=0.4,g=1,b=0.4}
myClass.PlayersColor.NoClass={r=0.5,g=0.5,b=0.5}
myClass.PlayersColor.NoGuild={r=0.5,g=0.5,b=0.5}

myClass.ColumnWidth={
deltatotal = 40,
deltaspent = 40,
hours = 45,
roll = 40,
bid = 55,
value = 50,
}

-------------------- Window management ----------------------

function myClass.OnLoad(self)
  self.Frame=QDKP2_Frame2
  self.MenuFrame = CreateFrame("Frame", "QDKP2_Frame2_DropDownMenu", self.Frame , "UIDropDownMenuTemplate")
  self.SubMenuFrame = CreateFrame("Frame", "QDKP2_Frame2_DropDownMenu", self.MenuFrame , "UIDropDownMenuTemplate")
end

function myClass.Show(self)
  QDKP2_Toggle(2, true)
  QDKP2GUI_Roster:Refresh()
end

function myClass.Hide(self)
  QDKP2_Frame2:Hide()
  myClass.SelectNone()
end

function myClass.Toggle(self)
  if QDKP2_Frame2:IsVisible() then
    self.Hide()
  else
    self.Show()
  end
end


function myClass.Refresh(self, forceResort)
    if not QDKP2_Frame2:IsVisible() then return; end
    QDKP2_Debug(3, "GUI-roster","Refreshing")
    local Complete=QDKP2_OfficerMode()
    if Complete then
      QDKP2_frame2_showRaid:Hide()
      QDKP2frame2_selectList_Bid:Show()
    else
      QDKP2_frame2_showRaid:Show()
      QDKP2frame2_selectList_Bid:Hide()
    end
    QDKP2frame2_selectList_guild:SetChecked(false)
    QDKP2frame2_selectList_guildOnline:SetChecked(false)
    QDKP2frame2_selectList_Raid:SetChecked(false)
    QDKP2frame2_selectList_Bid:SetChecked(false)
    --QDKP2frame2_selectList_Session:SetChecked(false)

    myClass:PupulateList()

    if self.Sel=="guildonline" or self.Sel=="guild" then
      myClass:ShowColumn('deltatotal', false)
      myClass:ShowColumn('deltaspent', false)
      myClass:ShowColumn('roll', false)
      myClass:ShowColumn('bid', false)
      myClass:ShowColumn('value', false)
      QDKP2_Frame2_sesscount:Hide()
      QDKP2_Frame2_SessionZone:Hide()
      QDKP2_Frame2_bidcount:Hide()
      QDKP2_Frame2_BiddingZone:Hide()
      QDKP2_Frame2_Bid_Item:Hide()
      QDKP2_Frame2_Bid_Button:Hide()
      QDKP2_Frame2_Bid_ButtonWin:Hide()
      if self.Sel=='guild' then
        QDKP2frame2_selectList_guild:SetChecked(true)
      else
        QDKP2frame2_selectList_guildOnline:SetChecked(true)
      end
    elseif self.Sel=="raid" then
      myClass:ShowColumn('deltatotal', true)
      myClass:ShowColumn('deltaspent', true)
      myClass:ShowColumn('roll', false)
      myClass:ShowColumn('bid', false)
      myClass:ShowColumn('value', false)
      QDKP2_Frame2_sesscount:Show()
      QDKP2_Frame2_SessionZone:Show()
      QDKP2_Frame2_bidcount:Hide()
      QDKP2_Frame2_BiddingZone:Hide()
      QDKP2_Frame2_Bid_Item:Hide()
      QDKP2_Frame2_Bid_Button:Hide()
      QDKP2_Frame2_Bid_ButtonWin:Hide()
      QDKP2frame2_selectList_Raid:SetChecked(true)
    elseif self.Sel=="bid" then
      myClass:ShowColumn('deltatotal', true)
      myClass:ShowColumn('deltaspent', true)
      myClass:ShowColumn('roll', true)
      myClass:ShowColumn('bid', true)
      myClass:ShowColumn('value', true)
      QDKP2_Frame2_sesscount:Show()
      QDKP2_Frame2_SessionZone:Show()
      QDKP2_Frame2_bidcount:Show()
      QDKP2_Frame2_BiddingZone:Show()
      QDKP2_Frame2_Bid_Item:Show()
      QDKP2_Frame2_Bid_Button:Show()
      QDKP2_Frame2_Bid_ButtonWin:Show()
      if QDKP2_BidM_isBidding() then
        QDKP2_Frame2_Bid_Button:SetText("Cancel Bid")
      else
        QDKP2_Frame2_Bid_Button:SetText("Start Bid")
      end
      if QDKP2_BidM_isBidding() and myClass.SelectedPlayers and #myClass.SelectedPlayers==1 and QDKP2_BidM.LIST[myClass.SelectedPlayers[1]] then
        QDKP2_Frame2_Bid_ButtonWin:Enable()
      else
        QDKP2_Frame2_Bid_ButtonWin:Disable()
      end
      QDKP2frame2_selectList_Bid:SetChecked(true)
    end

    if QDKP2_StoreHours then
      myClass:ShowColumn('hours', true)
    else
      myClass:ShowColumn('hours', false)
    end

    if (self.Sel=='raid' or self.Sel=='bid') and QDKP2GUI_Vars.ShowOutGuild then forceResort=true; end
    self:SortList(nil,nil,forceResort)

    if self.Offset > #self.List then self.Offset=#self.List-1; end
    if self.Offset < 0 then self.Offset=0; end

    for i=1, QDKP2GUI_Roster.ENTRIES do  --fills in the list data
      local indexAt = self.Offset+i
      local ParentName="QDKP2_frame2_entry"..tostring(i)
      if indexAt <= #self.List then
        local name = self.List[indexAt]
        local class=QDKP2class[name] or UnitClass(name)
        local isinguild=QDKP2_IsInGuild(name)
        local colors=myClass.PlayersColor.Default
        if not isinguild then colors=myClass.PlayersColor.NoGuild
        elseif QDKP2_USE_CLASS_BASED_COLORS then
          colors=QDKP2_GetClassColor(class)
        else
          if QDKP2_IsModified(name) then colors=myClass.PlayersColor.Modified
          elseif QDKP2_IsStandby(name) then colors=myClass.PlayersColor.Standby
          elseif QDKP2_IsAlt(name) then colors=myClass.PlayersColor.Alt
          elseif QDKP2_IsExternal(name) then colors=myClass.PlayersColor.External
          else
          end
        end
        local r,g,b,a=colors.r, colors.g, colors.b, 1
        local DKP_Ast=""
        if QDKP2_USE_CLASS_BASED_COLORS and QDKP2_IsModified(name) then DKP_Ast="*"; end
        if self.Sel=='raid' and QDKP2_IsRemoved(name) then a=0.4; end

        --Setting fields color
        getglobal(ParentName.."_name"):SetVertexColor(r, g, b, a)
        getglobal(ParentName.."_roll"):SetVertexColor(r, g, b, a)
        getglobal(ParentName.."_bid"):SetVertexColor(r, g, b, a)
        getglobal(ParentName.."_value"):SetVertexColor(r, g, b, a)
        getglobal(ParentName.."_rank"):SetVertexColor(r, g, b, a)
        local classColor=colors
        if not QDKP2_USE_CLASS_BASED_COLORS then
          classColor=QDKP2_GetClassColor(class)
        end
        getglobal(ParentName.."_class"):SetVertexColor(classColor.r, classColor.g, classColor.b, a)
        if isinguild and QDKP2_GetNet(name)<0 then
          getglobal(ParentName.."_net"):SetVertexColor(1, 0.2, 0.2)
        else
          getglobal(ParentName.."_net"):SetVertexColor(r, g, b, a)
        end
        getglobal(ParentName.."_total"):SetVertexColor(r, g, b, a)
        getglobal(ParentName.."_spent"):SetVertexColor(r, g, b, a)
        getglobal(ParentName.."_hours"):SetVertexColor(r, g, b, a)
        getglobal(ParentName.."_deltatotal"):SetVertexColor(r, g, b, a)
        getglobal(ParentName.."_deltaspent"):SetVertexColor(r, g, b, a)

        --Setting content
        local nameS,roll,bid,value,rank,net,total,spent,hours,s_gain,s_spent
        nameS=QDKP2_GetName(name) or 'Unknown'
        if self.Sel == 'bid' then
          local BidEntry=QDKP2_BidM_GetBidder(name) or {}
          roll=BidEntry.roll
          bid=BidEntry.txt
          value=BidEntry.value
        else
          roll=''; bid=''; value=''
        end
        rank=QDKP2rank[name]
        if class=="Death Knight" then class="DK"; end
        if isinguild then
          net=QDKP2_GetNet(name)
          total=QDKP2_GetTotal(name)
          spent=QDKP2_GetSpent(name)
          if QDKP2_StoreHours then
            hours=tostring(QDKP2_GetHours(name))..DKP_Ast
          else hours=''
          end
          if self.Sel=="raid" or self.Sel=="bid" then
            s_gain,s_spent=QDKP2_GetSessionAmounts(name)
          else
            s_gain=''; s_spent=''
          end
        else
          net='-'; total='-'; spent='-'; hours=''; s_gain=''; s_spent=''
        end
        getglobal(ParentName.."_name"):SetText(tostring(nameS));
        getglobal(ParentName.."_roll"):SetText(tostring(roll or '-'))
        getglobal(ParentName.."_bid"):SetText(tostring(bid or '-'))
        getglobal(ParentName.."_value"):SetText(tostring(value or '-'))
        getglobal(ParentName.."_rank"):SetText(tostring(rank or '-'));
        getglobal(ParentName.."_class"):SetText(tostring(class or '-'));
        getglobal(ParentName.."_net"):SetText(tostring(net or '-')..DKP_Ast);
        getglobal(ParentName.."_total"):SetText(tostring(total or '-')..DKP_Ast);
        getglobal(ParentName.."_spent"):SetText(tostring(spent or '-')..DKP_Ast);
        getglobal(ParentName.."_hours"):SetText(tostring(hours or '-'));
        getglobal(ParentName.."_deltatotal"):SetText(tostring(s_gain or '-'));
        getglobal(ParentName.."_deltaspent"):SetText(tostring(s_spent or '-'));


        if self:isSelectedPlayer(name) then getglobal(ParentName.."_Highlight"):Show()
        else getglobal(ParentName.."_Highlight"):Hide()
        end
        getglobal(ParentName):Show();
      else
        getglobal(ParentName):Hide();
      end
    end

    local numEntries=QDKP2GUI_Roster.ENTRIES
    if #self.List<numEntries then numEntries=#self.List; end
    FauxScrollFrame_Update(QDKP2_frame2_scrollbar,#self.List,numEntries,16);
end

function myClass.Update(self)
  QDKP2_DownloadGuild()
  QDKP2_UpdateRaid()
  QDKP2_RefreshAll()
  GuildRoster()
end

function myClass.PupulateList(self)
  if self.Sel=='guild' then
    self.List=QDKP2name
    QDKP2frame2_selectList_guild:SetChecked(true)
  elseif self.Sel=='guildonline' then
    self.List={}
    for i,name in pairs(QDKP2name) do
      if QDKP2online[name] and not QDKP2_IsExternal(name) then table.insert(self.List,name); end
    end
  elseif self.Sel=='raid' then
    if QDKP2GUI_Vars.ShowOutGuild then
      local list={}
      for i=1,QDKP2_GetNumRaidMembers() do
        local name = QDKP2_GetRaidRosterInfo(i)
        table.insert(list,name)
      end
      self.List=list
    else
      self.List=QDKP2raid
    end
  elseif self.Sel=='bid' then
    self.List=QDKP2_CopyTable(QDKP2_BidM_GetBidderList())
    if not QDKP2GUI_Vars.ShowOutGuild then
      for i,name in pairs(self.List) do
        if not QDKP2_IsInGuild(name) then table.remove(self.List,i); end
      end
    end
  end
  QDKP2_Debug(2, "GUI-Roster","List populated. Voices="..tostring(#self.List))
end


function myClass.ShowColumn(self, Column, todo)
  local width=myClass.ColumnWidth[Column]
  local expand, reduce
  TestObj=getglobal("QDKP2_Frame2_SortBtn_"..Column)
  if TestObj:IsVisible() and not todo then
    QDKP2_Debug(3, "GUI-Roster","Hiding column "..tostring(Column))
    reduce=true
  elseif not TestObj:IsVisible() and todo then
    QDKP2_Debug(3, "GUI-Roster","showing column "..tostring(Column))
    expand=true
  end
  for i=1, QDKP2GUI_Roster.ENTRIES do
    local ParentName="QDKP2_frame2_entry"..tostring(i)
    local ColObj=getglobal(ParentName..'_'..Column)
    if todo then
      --ColObj:Show()
      ColObj:SetWidth(width+1)
    else
      --ColObj:Hide()
      ColObj:SetWidth(0)
    end
    local RowObj=getglobal(ParentName)
    if reduce then RowObj:SetWidth(RowObj:GetWidth()-(width))
    elseif expand then RowObj:SetWidth(RowObj:GetWidth()+(width))
    end
  end
  local TitleColObj=getglobal("QDKP2_frame2_title_"..Column)
  local SortButton=getglobal("QDKP2_Frame2_SortBtn_"..Column)
  if todo then
    --TitleColObj:Show()
    TitleColObj:SetWidth(width+1)
    SortButton:Show()
  else
    --TitleColObj:Hide()
    TitleColObj:SetWidth(0)
    SortButton:Hide()
  end
  if reduce then QDKP2_Frame2:SetWidth(QDKP2_Frame2:GetWidth()-(width))
  elseif expand then QDKP2_Frame2:SetWidth(QDKP2_Frame2:GetWidth()+(width))
  end
end

---------------------- OnClick functions --------------------------


function myClass.LeftClickEntry(self)
  local name,btnIndex=QDKP2GUI_GetClickedEntry(myClass)
  if IsShiftKeyDown() then
    if not myClass.PreviousShiftSelSet then
      myClass.PreviousShiftSelSet={}
      QDKP2_CopyTable(myClass.SelectedPlayers,myClass.PreviousShiftSelSet)
    else
      myClass.SelectedPlayers={}
      QDKP2_CopyTable(myClass.PreviousShiftSelSet,myClass.SelectedPlayers)
    end
    local begin,stop
    local list={}
    if btnIndex>myClass.LastClickIndex then
      begin=myClass.LastClickIndex+1
      stop=btnIndex
    else
      begin=btnIndex
      stop=myClass.LastClickIndex-1
    end
    for i=begin,stop do
      local name=myClass.List[i]
      if name then table.insert(list,name); end
    end
    local tempShiftSel=myClass.PreviousShiftSelSet
    self:SelectPlayer(list,true)
    myClass.PreviousShiftSelSet=tempShiftSel
  else
    if IsControlKeyDown() then
      self:SelectPlayer(name,true)
    elseif QDKP2GUI_IsDoubleClick(myClass) and QDKP2_IsInGuild(name) then
      if QDKP2_OfficerMode() then
        QDKP2GUI_Toolbox:Popup(self.SelectedPlayers) --double click
      else
        QDKP2GUI_Log:ShowPlayer(myClass.SelectedPlayers[1])
      end
    else
      self:SelectPlayer(name)
    end
    myClass.LastClickIndex=btnIndex
  end
end

function myClass.RightClickEntry(self)
  local name=QDKP2GUI_GetClickedEntry(myClass)
  if not IsControlKeyDown() and not myClass:isSelectedPlayer(name) then
    self:SelectPlayer(name)
  elseif QDKP2GUI_IsDoubleClick(myClass) and QDKP2_IsInGuild(name) then
    QDKP2GUI_Log:ShowPlayer(myClass.SelectedPlayers[1])
    QDKP2GUI_CloseMenus()
    return
  end
  self:PlayerMenu()
end

function myClass.ChangeList(self,Type)
  QDKP2_Debug(2, "GUI-Roster","Changing view to "..tostring(Type))
  self.Sel=Type
  myClass:PupulateList()
  local list={}
  for i,v in pairs(self.List) do
    if myClass:isSelectedPlayer(v) then table.insert(list,v); end
  end
  self.SelectedPlayers=list
  if Type=='bid'  then
    myClass.Sort.Order=''
    myClass.Sort.Reverse.BidValue=true
    myClass:SortList("BidValue")
  else
    myClass.Sort.LastLen=-1 --forces a resort
  end
  myClass:SelectPlayer(list) --this is to clean the selection if the previous selected players are no longer available.
end


function myClass.DragDropManager(self)
  local what,a1,a2=GetCursorInfo()
  if what=='item' then
    this:SetText(a2)
    ClearCursor()
  end
end


function myClass.PushedBidButton(self)
  if QDKP2_BidM_isBidding() then
    QDKP2_BidM_CancelBid()
    QDKP2_Frame2_Bid_Item:SetText("")
  else
    QDKP2_BidM_StartBid(QDKP2_Frame2_Bid_Item:GetText())
  end
  myClass:Refresh()
  QDKP2_Frame2_Bid_Item:ClearFocus()
end

function myClass.PushedBidWinButton(self)
  if QDKP2_BidM_isBidding() then
    if myClass.SelectedPlayers and #myClass.SelectedPlayers == 1 then
      QDKP2_BidM_Winner(myClass.SelectedPlayers[1])
    end
  end
end

---------- Entries Selection --------------------

function myClass.SelectPlayer(self,name,multiple)
--Selects given player. if multiple is true, does a multiple selection (ctrl key), wich will toggle the
--selected state of name.
  QDKP2_Debug(3, "GUI-Roster","Selecting"..tostring(name))
  myClass.PreviousShiftSelSet=nil
  if name=="RAID" then return; end
  self.SelectedPlayers=self.SelectedPlayers or {}
  if type(name)=="string" then name={name}; end
  if multiple then
    for i1,v1 in pairs(name) do
      local found
      for i2,v2 in pairs(self.SelectedPlayers) do
        if v1==v2 then
          table.remove(self.SelectedPlayers,i2)
          found=true
          break
        end
      end
      if not found then table.insert(self.SelectedPlayers, 1, v1); end
    end
  else
    QDKP2GUI_Roster.SelectedPlayers=name
  end
  if #self.SelectedPlayers>0 then
    if QDKP2_IsInGuild(self.SelectedPlayers[1]) then
      QDKP2GUI_Toolbox:SelectPlayer(self.SelectedPlayers)
      QDKP2GUI_Log:SelectPlayer(self.SelectedPlayers[1])
    elseif #self.SelectedPlayers>1 then
      QDKP2GUI_Toolbox:SelectPlayer(self.SelectedPlayers)
    else
      QDKP2GUI_Toolbox:Hide()
      QDKP2GUI_Log:Hide()
    end
  else
    QDKP2GUI_Toolbox:Hide()
  end
  QDKP2GUI_CloseMenus()
  self:Refresh()
end

function myClass.isSelectedPlayer(self,name)
  self.SelectedPlayers=self.SelectedPlayers or {}
  for i,v in pairs(myClass.SelectedPlayers) do
    if v==name then return i; end
  end
end

function myClass.SelectAll()
  myClass:SelectPlayer(myClass.List)
end

function myClass.SelectNone()
  myClass:SelectPlayer({})
end

function myClass.SelectInvert()
  local out={}
  for i1,v1 in pairs(myClass.List) do
    table.insert(out,v1)
    for i2,v2 in pairs(myClass.SelectedPlayers) do
      if v1==v2 then
        table.remove(out)
        break
      end
    end
  end
  myClass:SelectPlayer(out)
end


-------------------- Scroll ------------------

function myClass.ScrollBarUpdate()
  myClass.Offset=FauxScrollFrame_GetOffset(QDKP2_frame2_scrollbar)
  myClass:Refresh()
end

--------------------- Menus --------------------------

local function NYIfunc()
  QDKP2_Msg("To be done")
end

local QuickModifyVoices={
{template="Add $AMOUNT DKP",
func=function()
  QDKP2_PlayerGains(myClass.SelectedPlayers,QDKP2GUI_Vars.DKP_QuickModify)
  QDKP2GUI_CloseMenus()
  QDKP2_RefreshAll()
end},
{template="Subtract $AMOUNT DKP",
func=function()
  QDKP2_PlayerSpends(myClass.SelectedPlayers,QDKP2GUI_Vars.DKP_QuickModify)
  QDKP2GUI_CloseMenus()
  QDKP2_RefreshAll()
end},
{text="Subtract 50% DKP",
func=function()
  QDKP2_PlayerSpends(myClass.SelectedPlayers,"50%")
  QDKP2GUI_CloseMenus()
  QDKP2_RefreshAll()
end
},
{text="Subtract 100% DKP",
func=function()
  QDKP2_PlayerSpends(myClass.SelectedPlayers,"100%")
  QDKP2GUI_CloseMenus()
  QDKP2_RefreshAll()
end
},
{text="Add 1 hour",
func=function()
  QDKP2_PlayerIncTime(myClass.SelectedPlayers,1)
  QDKP2GUI_CloseMenus()
  QDKP2_RefreshAll()
end
},
{text="Reset Raiding time",
func=function()
  local Selection=myClass.SelectedPlayers
  if type(Selection)=="string" then Selection={Selection}; end
  local ts=QDKP2_Timestamp()
  for i,v in pairs(Selection) do
    local Hours=QDKP2_GetHours(v)
    if Hours and Hours > 0 then
      QDKP2_AddTotals(v, nil, nil, -Hours, "raid timer reset (single)", true,ts)
    end
  end
  QDKP2GUI_CloseMenus()
  QDKP2_RefreshAll()
end
},
{text="Reset DKP amounts",
func=function()
  local Selection=myClass.SelectedPlayers
  if type(Selection)=="string" then Selection={Selection}; end
  local ts=QDKP2_Timestamp()
  for i,v in pairs(Selection) do
    local Tot=QDKP2_GetTotal(v)
    local Spent=QDKP2_GetSpent(v)
    if Tot and Spent and (Tot~=0 or Spent~=0) then
      QDKP2_AddTotals(v, -Tot, -Spent, nil, "DKP reset (single)", true,ts)
    end
  end
  QDKP2GUI_CloseMenus()
  QDKP2_RefreshAll()
end
},
{text="Set quick modify amount...",
func=function()
  QDKP2GUI_CloseMenus()
  QDKP2_OpenInputBox("Enter the amount of DKP to be used in the\nquick modify log menu.",
    function(amount)
      amount=tonumber(amount)
      if amount then QDKP2GUI_Vars.DKP_QuickModify=amount; end
    end)
    QDKP2_InputBox_SetDefault(tostring(QDKP2GUI_Vars.DKP_QuickModify))
  end
},
}

local LogVoices={
-- Dictionary with all the log voices.
OpenLog={text="Open Log",
func=function()
  QDKP2GUI_Log:ShowPlayer(myClass.SelectedPlayers[1])
end,
},
OpenToolbox={text="Open Toolbox",
func=function()
  QDKP2GUI_Toolbox:Popup(myClass.SelectedPlayers)
end
},
OpenAmounts={text="Edit DKP amounts",
func=function()
  QDKP2GUI_SetAmounts:Popup(myClass.SelectedPlayers)
end
},
QuickMod={text="Quick Modify",
hasArrow=true,
menuList=QuickModifyVoices,
},
Notify={text="Notify DKP",
func=function()
  for i,name in pairs(myClass.SelectedPlayers) do
    if QDKP2online[name] then QDKP2_Notify(name); end
  end
end
},
AltClear={text="Clear Alt Status",
func=function()
  if #myClass.SelectedPlayers>1 then return; end
  QDKP2_ClearAlt(myClass.SelectedPlayers[1])
end
},
AltMake={text="Make alt",func=function()
  if #myClass.SelectedPlayers == 2 then
    local alt=myClass.SelectedPlayers[2]
    local main=myClass.SelectedPlayers[1]
    QDKP2_MakeAlt(alt,main)
  else
    QDKP2_NotifyUser('To define an alt you must select 2\ncharacters, first the alt and then his main.\nPress "Control" to perform a multiple\nselection.')
  end
end
},
ExternalAdd={text="Add External",
func=function()
  QDKP2_NewExternal()
end
},
ExternalRem={text="Remove External",
func=function()
  if #myClass.SelectedPlayers>1 then return; end
  QDKP2_DelExternal(myClass.SelectedPlayers[1])
end
},
AddAsExternal={text="Add player as exernal",
func=function()
  QDKP2_NewExternal(myClass.SelectedPlayers[1])
  myClass:Refresh()
end,
},
StandbyAdd={text="Add to raid as standby",
checked=function() return QDKP2_IsStandby(myClass.SelectedPlayers[1]); end,
func=function()
  local name=myClass.SelectedPlayers[1]
  if QDKP2_IsStandby(name) then
    QDKP2_RemStandby(name)
  else
    QDKP2_AddStandby(name)
  end
  myClass:Refresh()
  QDKP2GUI_Log:Refresh()
end
},
AllStandbyAdd={text="Add all to raid as standby",
func=function()
  for i,name in pairs(myClass.SelectedPlayers) do
	  if not QDKP2_IsInRaid(name) then QDKP2_AddStandby(name); end
	end
end,
},
ExcludeRaid={text="Exclude from Raid",
checked=function() return QDKP2_IsRemoved(myClass.SelectedPlayers[1]); end,
func=function()
  local name=myClass.SelectedPlayers[1]
  if QDKP2_IsRemoved(name) then
    QDKP2_RemoveFromRaid(name,true)
  end
end,
},
ShowOutGuild={text="Show players not in guild",
checked=function() return QDKP2GUI_Vars.ShowOutGuild; end,
func=function()
  if QDKP2GUI_Vars.ShowOutGuild then
    QDKP2GUI_Vars.ShowOutGuild=false
  else
    QDKP2GUI_Vars.ShowOutGuild=true
  end
  myClass:ChangeList(myClass.Sel)
end,
},
SetWinner={text="Set bid winner",
func=function()
  QDKP2_BidM_Winner(myClass.SelectedPlayers[1])
end
},
CancelBid={text="Cancel bet",
func=function()
  for i,name in pairs(myClass.SelectedPlayers) do
    QDKP2_BidM_CancelPlayer(name)
  end
end
},
ClearBid={text="Clear bid list",
func=function()
  QDKP2_BidM_Reset()
end
},
CountDown={text="Trigger countdown",
func=function()
  QDKP2_BidM_Countdown()
end
},
AcceptBids={text="Accept Bets",
checked=function() return QDKP2_BidM.ACCEPT_BID; end,
func=function()
  if not QDKP2_BidM.ACCEPT_BID then
    QDKP2_BidM.ACCEPT_BID = true
    QDKP2_Msg("Bet detection has been "..QDKP2_COLOR_GREEN.."enabled")
  else
    QDKP2_BidM.ACCEPT_BID = false
    QDKP2_Msg("Bet detection has been "..QDKP2_COLOR_RED.."disabled")
  end
end
},
PubblishBids={text="Pubblish Bids to Raid",
func=function()
  if not QDKP2_BidM.LIST then return; end
  local text
  if QDKP2_BidM.ITEM and #QDKP2_BidM.ITEM>0 then
    text="Current bidders for "..tostring(QDKP2_BidM.ITEM)..":"
  else
    text="Current bidders:"
  end
  ChatThrottleLib:SendChatMessage("NORMAL", "QDKP2", text, "RAID")
  for player,bid in pairs(QDKP2_BidM.LIST) do
    local text=player.." - bid:"..tostring(bid.value or '-')..", roll:"..tostring(bid.roll or '-')
    ChatThrottleLib:SendChatMessage("NORMAL", "QDKP2", text, "RAID")
  end
end
},
Revert={text="Revert changes",
func=function()
  for i,name in pairs(myClass.SelectedPlayers) do
    if QDKP2_IsInGuild(name) then QDKP2_ReverPlayer(name); end
  end
  QDKP2_RefreshAll()
end,
},
SelectAll={text="Select All", func=myClass.SelectAll},
SelectNone={text="Select None",func=myClass.SelectNone},
SelectInvert={text="Invert Selection",func=myClass.SelectInvert},
ExternalPost={text="Post External amounts", func=function() QDKP2_PostExternals("GUILD"); end},
RosterUpdate={text="Update Roster", func=myClass.Update},
MenuClose={text="Close menu", func=QDKP2GUI_CloseMenus},
spacer={text="", notClickable=true},
}

function myClass.PlayerMenu(self,List)
  if not QDKP2_OfficerMode() then return; end --view mode doesn't have a player menu.
  local managing=QDKP2_ManagementMode()
  local sel=List or self.SelectedPlayers
  local menu
  if #sel==1 and not QDKP2_IsInGuild(sel[1]) then
    menu={}
    table.insert(menu,{text=sel[1].."'s menu",isTitle=true})
    if self.Sel=="bid" then
      table.insert(menu,LogVoices.SetWinner)
      table.insert(menu,LogVoices.CancelBid)
    end
    table.insert(menu,LogVoices.AddAsExternal)
  elseif #sel==1 then
    local name=self.SelectedPlayers[1]
    menu={}
    table.insert(menu,{text=name.."'s menu",isTitle=true})
    if self.Sel=="bid" then
      table.insert(menu,LogVoices.SetWinner)
      table.insert(menu,LogVoices.CancelBid)
      table.insert(menu,LogVoices.spacer)
    end
    table.insert(menu,LogVoices.OpenLog)
    table.insert(menu,LogVoices.OpenToolbox)
    table.insert(menu,LogVoices.OpenAmounts)
    table.insert(menu,LogVoices.Notify)
    table.insert(menu,LogVoices.spacer)
    if QDKP2_IsAlt(name) then table.insert(menu,LogVoices.AltClear)
    else table.insert(menu,LogVoices.AltMake)
    end
    if managing and (QDKP2_IsStandby(name) or not QDKP2_IsInRaid(name)) then
      table.insert(menu,LogVoices.StandbyAdd)
    end
    if QDKP2_IsExternal(name) then
      table.insert(menu,LogVoices.ExternalRem)
    end
    table.insert(menu,LogVoices.QuickMod)
    table.insert(menu,LogVoices.Revert)
    QuickModifyVoices[1].text=string.gsub(QuickModifyVoices[1].template,"$AMOUNT",tostring(QDKP2GUI_Vars.DKP_QuickModify))
    QuickModifyVoices[2].text=string.gsub(QuickModifyVoices[2].template,"$AMOUNT",tostring(QDKP2GUI_Vars.DKP_QuickModify))
  elseif #sel>1 then
    menu={}
    table.insert(menu,{text="GROUP's actions:",isTitle=true})
    if self.Sel=="bid" then
      table.insert(menu,LogVoices.CancelBid)
      table.insert(menu,LogVoices.spacer)
    end
    table.insert(menu,LogVoices.OpenToolbox)
    table.insert(menu,LogVoices.OpenAmounts)
    table.insert(menu,LogVoices.Notify)
    table.insert(menu,LogVoices.spacer)
    if #sel==2 then table.insert(menu,LogVoices.AltMake); end
		if managing and (self.Sel=='guild' or self.Sel=='guildonline') then table.insert(menu,LogVoices.AllStandbyAdd); end
    table.insert(menu,LogVoices.QuickMod)
    table.insert(menu,LogVoices.Revert)
    QuickModifyVoices[1].text=string.gsub(QuickModifyVoices[1].template,"$AMOUNT",tostring(QDKP2GUI_Vars.DKP_QuickModify))
    QuickModifyVoices[2].text=string.gsub(QuickModifyVoices[2].template,"$AMOUNT",tostring(QDKP2GUI_Vars.DKP_QuickModify))
  end
  if not menu then return; end
  table.insert(menu,LogVoices.spacer)
  table.insert(menu,LogVoices.MenuClose)
  EasyMenu(menu, self.MenuFrame, "cursor",0,0, "MENU")
end

function myClass.RosterMenu(self)
  menu={}
  table.insert(menu,{text="ROSTER MENU", isTitle=true})
  table.insert(menu,LogVoices.SelectAll)
  table.insert(menu,LogVoices.SelectNone)
  table.insert(menu,LogVoices.SelectInvert)
  if self.Sel=="guild" or self.Sel=="guildonline" then
    menu[1].text="GUILD ROSTER MENU"
    if QDKP2_OfficerMode() then
      table.insert(menu,2,LogVoices.spacer)
      table.insert(menu,2,LogVoices.ExternalAdd)
      table.insert(menu,2,LogVoices.ExternalPost)
    end
  elseif self.Sel=="raid" then
    menu[1].text="RAID ROSTER MENU"
    table.insert(menu,2,LogVoices.spacer)
    table.insert(menu,2,LogVoices.ShowOutGuild)
  elseif self.Sel=="bid" then
    menu[1].text="BID MANAGER MENU"
    table.insert(menu,2,LogVoices.spacer)
    table.insert(menu,2,LogVoices.PubblishBids)
    table.insert(menu,2,LogVoices.ClearBid)
    if QDKP2_BidM_isBidding() then
      table.insert(menu,2,LogVoices.CountDown)
      table.insert(menu,2,LogVoices.AcceptBids)
    end
    table.insert(menu,3,LogVoices.ShowOutGuild)
  end

  table.insert(menu,LogVoices.spacer)
  table.insert(menu,LogVoices.RosterUpdate)
  table.insert(menu,LogVoices.MenuClose)
  EasyMenu(menu, self.MenuFrame, "cursor",0,0, "MENU")
end


--------------------- SORTING ALGORYTHMS -------------------

-- Perform all sorting at once. Values the sorting by category- highest power of 2 is most important.
-- When a new sorting category is used (say, rank), it will be incresed to max (8) and the others will be
-- adjusted downwards accordingly
myClass.Sort.Values={}
myClass.Sort.Values.BidValue = 2048
myClass.Sort.Values.BidText = 1024
myClass.Sort.Values.BidRoll = 512
myClass.Sort.Values.Alpha = 256
myClass.Sort.Values.Rank  = 128
myClass.Sort.Values.Class = 64
myClass.Sort.Values.Net = 32
myClass.Sort.Values.Total = 16
myClass.Sort.Values.Spent = 8
myClass.Sort.Values.Hours = 4
myClass.Sort.Values.SessGain = 2
myClass.Sort.Values.SessSpent = 1

myClass.Sort.Reverse={}
myClass.Sort.Reverse.BidValue = true
myClass.Sort.Reverse.BidText = true
myClass.Sort.Reverse.BidRoll = true
myClass.Sort.Reverse.Alpha = false
myClass.Sort.Reverse.Rank = false
myClass.Sort.Reverse.Class = false
myClass.Sort.Reverse.Net = true
myClass.Sort.Reverse.Total = true
myClass.Sort.Reverse.Spent = true
myClass.Sort.Reverse.Hours = true
myClass.Sort.Reverse.SessGain = true
myClass.Sort.Reverse.SessSpent = true


-- Incoming val1, val2 are names.
local function SortComparitor(val1, val2)
   local compare = 0;
   local test1, test2, increment, invertBuffer
   local Values=myClass.Sort.Values
   local Reverse=myClass.Sort.Reverse

   -- Alpha
   test1 = val1
   test2 = val2
   if Reverse.Alpha then invertBuffer=test2;test2=test1;test1=invertBuffer; end
   increment = Values.Alpha
   if (test1 < test2) then compare = compare - increment; elseif (test1 > test2) then compare = compare + increment; end

  if not QDKP2_IsInGuild(val1) then
    if QDKP2_IsInGuild(val2) then
      return false
    else
      return compare<0
    end
  elseif not QDKP2_IsInGuild(val2) then
    return true
  end

   -- Rank
   test1 = QDKP2rankIndex[val1] or 255
   test2 = QDKP2rankIndex[val2] or 255
   if Reverse.Rank then invertBuffer=test2;test2=test1;test1=invertBuffer; end
   increment = Values.Rank
   if (test1 < test2) then compare = compare - increment; elseif (test1 > test2) then compare = compare + increment; end

   -- Class
   test1 = QDKP2class[val1] or ""
   test2 = QDKP2class[val2] or ""
   if Reverse.Class then invertBuffer=test2;test2=test1;test1=invertBuffer; end
   increment = Values.Class
   if (test1 < test2) then compare = compare - increment; elseif (test1 > test2) then compare = compare + increment; end

   -- Net
   test1 = QDKP2_GetNet(val1) or QDKP2_MINIMUM_NET
   test2 = QDKP2_GetNet(val2) or QDKP2_MINIMUM_NET
   if Reverse.Net then invertBuffer=test2;test2=test1;test1=invertBuffer; end
   increment = Values.Net
   if (test1 < test2) then compare = compare - increment; elseif (test1 > test2) then compare = compare + increment; end

   -- Total
   test1 = QDKP2_GetTotal(val1) or QDKP2_MINIMUM_NET
   test2 = QDKP2_GetTotal(val2) or QDKP2_MINIMUM_NET
   if Reverse.Total then invertBuffer=test2;test2=test1;test1=invertBuffer; end
   increment = Values.Total
   if (test1 < test2) then compare = compare - increment; elseif (test1 > test2) then compare = compare + increment; end

   -- Spent
   test1 = QDKP2_GetSpent(val1) or QDKP2_MINIMUM_NET
   test2 = QDKP2_GetSpent(val2) or QDKP2_MINIMUM_NET
   if Reverse.Spent then invertBuffer=test2;test2=test1;test1=invertBuffer; end
   increment = Values.Spent
   if (test1 < test2) then compare = compare - increment; elseif (test1 > test2) then compare = compare + increment; end

   --Hours
   test1 = QDKP2_GetHours(val1) or 0
   test2 = QDKP2_GetHours(val2) or 0
   if Reverse.Hours then invertBuffer=test2;test2=test1;test1=invertBuffer; end
   increment = Values.Hours
   if (test1 < test2) then compare = compare - increment; elseif (test1 > test2) then compare = compare + increment; end

  if myClass.Sel == 'raid' or myClass.Sel == 'bid' then
    local s_gain1,s_spent1=QDKP2_GetSessionAmounts(val1)
    local s_gain2,s_spent2=QDKP2_GetSessionAmounts(val2)
    s_gain1=s_gain1 or QDKP2_MINIMUM_NET
    s_spent1=s_spent1 or QDKP2_MINIMUM_NET
    s_gain2=s_gain2 or QDKP2_MINIMUM_NET
    s_spent2=s_spent2 or QDKP2_MINIMUM_NET

    --Session Gain
    if Reverse.SessGain then invertBuffer=s_gain2;s_gain2=s_gain1;s_gain1=invertBuffer; end
    increment = Values.SessGain
    if (s_gain1 < s_gain2) then compare = compare - increment; elseif (s_gain1 > s_gain2) then compare = compare + increment; end

    --Session spent
    if Reverse.SessSpent then invertBuffer=s_spent2;s_spent2=s_spent1;s_spent1=invertBuffer; end
    increment = Values.SessSpent
    if (s_spent1 < s_spent2) then compare = compare - increment; elseif (s_spent1 > s_spent2) then compare = compare + increment; end

    if myClass.Sel=='bid' then

      local bid1=QDKP2_BidM_GetBidder(val1) or {}
      local bid2=QDKP2_BidM_GetBidder(val2) or {}

      --Bid Value
      test1 = bid1.value or -100000
      test2 = bid2.value or -100000
      if Reverse.BidValue then invertBuffer=test2;test2=test1;test1=invertBuffer; end
      increment = Values.BidValue
      if (test1 < test2) then compare = compare - increment; elseif (test1 > test2) then compare = compare + increment; end

      --Bid text
      test1 = bid1.txt or ' '
      test2 = bid2.txt or ' '
      if Reverse.BidText then invertBuffer=test2;test2=test1;test1=invertBuffer; end
      increment = Values.BidText
      if (test1 < test2) then compare = compare - increment; elseif (test1 > test2) then compare = compare + increment; end

      --Bid Roll
      test1 = bid1.roll or 0
      test2 = bid2.roll or 0
      if Reverse.BidRoll then invertBuffer=test2;test2=test1;test1=invertBuffer; end
      increment = Values.BidRoll
      if (test1 < test2) then compare = compare - increment; elseif (test1 > test2) then compare = compare + increment; end
    end
  end
  return compare < 0
end



function myClass.SortList(self,Order,List,forceResort)
-- Sorts the list of guild members given by <List> by <OrderToGive>. if Order is nil, will use
-- the default in QDKP2_Order, and in that case it won't sort if the order hasn't changed.

  List=List or myClass.List

  if (not Order) and (myClass.Sort.LastLen == #List) and not (forceResort) then return; end --no need to resort if the sorting or the entriesh haven't changed.
  local Values=myClass.Sort.Values

  --this manages the inversion when you click 2 times the same sorting button
  if Order and Order==myClass.Sort.Order then
    local InvFlag=QDKP2GUI_Roster.Sort.Reverse[Order]
    if InvFlag then InvFlag=false
    else InvFlag=true
    end
    QDKP2GUI_Roster.Sort.Reverse[Order]=InvFlag
  end

  Order=Order or myClass.Sort.Order
  QDKP2_Debug(2, "GUI-Roster", "Sorting by "..Order)

  -- Fixup valuation of ordering. (which is most important?)
  local lastmax
  if (Order == "Alpha") then lastmax = Values.Alpha
  elseif (Order == "Rank") then lastmax = Values.Rank
  elseif (Order == "Class") then lastmax = Values.Class
  elseif (Order == "Net") then lastmax = Values.Net
  elseif (Order == "Total") then lastmax = Values.Total
  elseif (Order == "Spent") then lastmax = Values.Spent
  elseif (Order == "Hours") then lastmax = Values.Hours
  elseif (Order == "SessGain") then lastmax = Values.SessGain
  elseif (Order == "SessSpent") then lastmax = Values.SessSpent
  elseif (Order == "BidRoll") then lastmax = Values.BidRoll
  elseif (Order == "BidText") then lastmax = Values.BidText
  elseif (Order == "BidValue") then lastmax = Values.BidValue
  else
    QDKP2_Debug(1,"GUI-Roster","Unknown sorting method: "..Order)
    return
  end
  if (Values.Alpha > lastmax) then Values.Alpha = Values.Alpha / 2; end
  if (Values.Rank > lastmax) then Values.Rank = Values.Rank / 2; end
  if (Values.Class > lastmax) then Values.Class = Values.Class / 2; end
  if (Values.Net > lastmax) then Values.Net = Values.Net / 2; end
  if (Values.Total > lastmax) then Values.Total = Values.Total / 2; end
  if (Values.Spent > lastmax) then Values.Spent = Values.Spent / 2; end
  if (Values.Hours > lastmax) then Values.Hours = Values.Hours / 2; end
  if (Values.SessGain > lastmax) then Values.SessGain = Values.SessGain / 2; end
  if (Values.SessSpent > lastmax) then Values.SessSpent = Values.SessSpent / 2; end
  if (Values.BidRoll > lastmax) then Values.BidRoll = Values.BidRoll / 2; end
  if (Values.BidText > lastmax) then Values.BidText = Values.BidText / 2; end
  if (Values.BidValue > lastmax) then Values.BidValue = Values.BidValue / 2; end
  if      (Order == "Alpha") then Values.Alpha = 2048
  elseif (Order == "Rank") then Values.Rank = 2048
  elseif (Order == "Class") then Values.Class = 2048
  elseif (Order == "Net") then Values.Net = 2048
  elseif (Order == "Total") then Values.Total = 2048
  elseif (Order == "Spent") then Values.Spent = 2048
  elseif (Order == "Hours") then Values.Hours = 2048
  elseif (Order == "SessGain") then Values.SessGain = 2048
  elseif (Order == "SessSpent") then Values.SessSpent = 2048
  elseif (Order == "BidRoll") then Values.BidRoll = 2048
  elseif (Order == "BidText") then Values.BidText = 2048
  elseif (Order == "BidValue") then Values.BidValue = 2048
  end
  table.sort(List, SortComparitor)
  myClass.Sort.LastLen=#List
  myClass.Sort.Order=Order
  return List
end

--Changes sort method.
function myClass.SortBy(self,order)
  QDKP2GUI_Roster:SortList(order)
  QDKP2GUI_Roster:Refresh()
end



QDKP2GUI_Roster=myClass
