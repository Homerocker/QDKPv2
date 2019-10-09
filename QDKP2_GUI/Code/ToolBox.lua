-- Copyright 2010 Riccardo Belloli (belloli@email.it
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--                   ## GUI ##
--                    ToolBox
--


------------ Class Initialization and defaults -------------

local Toolbox={}
local SetAmounts={}

Toolbox.EditPlayers={}


-------------------- Window management ------------------------

function Toolbox.Show(self)
  self.Frame:Show()
  self.Refresh()
end

function Toolbox.Hide(self)
  self.Frame:Hide()
  SetAmounts:Hide()
  Toolbox:SetLootCharge()
end

function SetAmounts.Hide(self)
  self.Frame:Hide()
end

function Toolbox.Toggle(self)
  if self.Frame:IsVisible() then
    self:Hide()
  else
    self:Show()
  end
end


function Toolbox.Refresh(self)
    if not Toolbox.Frame:IsVisible() and not SetAmounts.Frame:IsVisible() then return; end
    Toolbox.EditPlayers=Toolbox.EditPlayers or {}
    if #Toolbox.EditPlayers<1 then return; end
    QDKP2_Debug(2, "GUI","Refreshing Toolbox")
    local multiple
    if #Toolbox.EditPlayers>1 then multiple=true; end
    if multiple then
      QDKP2_Frame3_Header:SetText("[Multiple Selection]")
    else
      local name=Toolbox.EditPlayers[1]
      QDKP2_Frame3_Header:SetText(QDKP2_GetName(name))
    end
end


SetAmounts.Show=Toolbox.Show
SetAmounts.Toggle=Toolbox.Toggle
SetAmounts.Refresh=Toolbox.Refresh


--------------------------- Data mangement -------------------------

function Toolbox.SetDKPbox(self,Value)
  QDKP2frame3_dkpBox:SetText(tostring(Value))
end

function Toolbox.SetLootCharge(self,item)
  if QDKP2_LootToPay or item then
    if not item then
      QDKP2frame3_reasonBox:SetText("")
    else
      QDKP2frame3_reasonBox:SetText(item)
    end
    QDKP2_LootToPay = item
    self:SetDKPbox('')
  end
end


function Toolbox.OnEnter()
  if QDKP2_LootToPay then
    if QDKP2_CHARGEWITHZS  then
      Toolbox:ChangeDKP("zs")
    else
      Toolbox:ChangeDKP("-")
    end
  end
end

--QDKP2_OpenToolboxForCharge
--Opens the toolbox to charge a player for a loot.
--usage f([name],[amount],[item])
--name=valid name of a player in guild. required
--amount=the amount of DKP to charge to the player. optional
--item=The reason of the charge (e.g. item link). optional
function Toolbox.OpenForCharge(self,name,amount,item)
  Toolbox:Popup(name)
  if item then Toolbox:SetLootCharge(item); end
  amount=amount or ""
  Toolbox:SetDKPbox(amount)
  QDKP2frame3_dkpBox:SetFocus()
end

function QDKP2_OpenToolboxForCharge(name,amount,item)
  Toolbox:OpenForCharge(name,amount,item)
end

function Toolbox.Popup(self,name)
  self:SelectPlayer(name)
  if not self.Frame:IsVisible() then self:Show(); end
end
SetAmounts.Popup=Toolbox.Popup

function Toolbox.SelectPlayer(self,name)
  if not name or #name==0 then
    Toolbox:Hide()
    SetAmounts:Hide()
  end
  if type(name)=="string" then name={name}; end
  Toolbox.EditPlayers=name
  SetAmounts:GetValues()
  if QDKP2_LootToPay then Toolbox:SetLootCharge(nil); end
  Toolbox:Refresh()
  SetAmounts:Refresh()
end
SetAmounts.SelectPlayer=Toolbox.SelectPlayer

function SetAmounts.GetValues(self)
  local name=Toolbox.EditPlayers
  if #name==1 and QDKP2_IsInGuild(name[1]) then
    QDKP2frame3_zsBtn:Enable()
    QDKP2frame4_TotalBox:SetText(tostring(QDKP2_GetTotal(name[1])))
    QDKP2frame4_NetBox:SetText(tostring(QDKP2_GetNet(name[1])))
    QDKP2frame4_HoursBox:SetText(tostring(QDKP2_GetHours(name[1])))
  else
    QDKP2frame3_zsBtn:Disable()
    QDKP2frame4_TotalBox:SetText('')
    QDKP2frame4_NetBox:SetText('')
    QDKP2frame4_HoursBox:SetText('')
  end
  if QDKP2_StoreHours then
    QDKP2frame4_HoursBox:Show()
    QDKP2frame4_hours:Show()
  else
    QDKP2frame4_HoursBox:Hide()
    QDKP2frame4_hours:Hide()
  end
end



--------------------- Clicks --------------------------

function Toolbox.ChangeDKP(self,inctype,Sure)
  local multiple = #Toolbox.EditPlayers > 1
  local change = QDKP2frame3_dkpBox:GetText()
  if not change then return; end
  local loot = QDKP2_LootToPay
  local reason = QDKP2frame3_reasonBox:GetText()
  if reason == "" then reason = nil; end
  if inctype=="+" then
    if loot and not Sure then
      local mess = "Really Give DKP for the loot of an object?"
      QDKP2_AskUser(mess, Toolbox.ChangeDKP, self, "+", true)
      return
    elseif loot then
      change = QDKP2_GetAmountFromText(change,Toolbox.EditPlayers[1])
      if not change then return; end
      QDKP2_PayLoot(Toolbox.EditPlayers[1], -change, reason)
    else
      QDKP2_PlayerGains(Toolbox.EditPlayers,change, reason)
    end
  elseif inctype=="-" then
    if loot then
      QDKP2_PayLoot(Toolbox.EditPlayers[1], change, reason)
    else
      QDKP2_PlayerSpends(Toolbox.EditPlayers,change, reason)
    end
  elseif inctype=="zs" and not multiple then
    if loot then
      QDKP2_PayLoot(Toolbox.EditPlayers[1], change, reason, true)
    else
      QDKP2_RaidAward(change,reason, Toolbox.EditPlayers[1])
    end
  end
  QDKP2GUI_Roster:Refresh()
  QDKP2GUI_Log:Refresh()

  if loot then
    Toolbox:Hide()
    SetAmounts:Hide()
    Toolbox:SetLootCharge(nil)
  end
end


--sets data from frame 4
function SetAmounts.Set(self,sure)
  local number=#Toolbox.EditPlayers
  if number>1 and not sure then
    QDKP2_AskUser("You are going to set the DKP of "..tostring(number).." selected\nguild members to the values you entered.\nContinue?",SetAmounts.Set,true,true)
    return
  end
  local net,total,hours
  local setNet = QDKP2frame4_NetBox:GetText()
  local setTotal = QDKP2frame4_TotalBox:GetText()
  local setHours = QDKP2frame4_HoursBox:GetText()
  if net=="" then net = nil; else net = tonumber(setNet); end
  if total=="" then total = nil; else total = tonumber(setTotal); end
  if hours=="" then hours = nil; else hours = tonumber(setHours); end
  if not net and not total and not hours then return; end
  QDKP2_DoubleCheckInit()
  for i,v in pairs(Toolbox.EditPlayers) do
    if not QDKP2_ProcessedMain(v) then
      local DTotal,DSpent, DHours
      if total then DTotal = total - QDKP2_GetTotal(v); end
      if net then DSpent = (total or QDKP2_GetTotal(v)) - net - QDKP2_GetSpent(v); end
      if hours then DHours = hours - QDKP2_GetHours(v); end
      if DTotal==0 then DTotal=nil; end
      if DSpent==0 then DSpent=nil; end
      if DHours==0 then DHours=nil; end
      if DTotal or DSpent or DHours then
        QDKP2_AddTotals(v, DTotal, DSpent, DHours, "manual edit", true)
        QDKP2_ProcessedMain(v)
      end
    end
  end
  QDKP2GUI_Roster:Refresh()
  QDKP2GUI_Log:Refresh()
end


---------------------- ShiftLink & DragDrop ----------------------------
--This function is called whenever an itemlink is shift clicked.
function Toolbox.ShiftClickItem(item)
  if item and Toolbox.Frame:IsVisible() then
    Toolbox:SetLootCharge(item)
    QDKP2frame3_dkpBox:SetFocus()
  elseif QDKP2frame6_ReasonBox:IsVisible() then
    QDKP2frame6_ReasonBox:SetText(item)
  end
end

function Toolbox.DragDropManager(self)
  local what,a1,a2=GetCursorInfo()
  if what=='item' then
    Toolbox:SetLootCharge(a2)
    QDKP2frame3_dkpBox:SetFocus()
    ClearCursor()
  end
end


hooksecurefunc("ChatEdit_InsertLink",Toolbox.ShiftClickItem)

QDKP2GUI_Toolbox=Toolbox
QDKP2GUI_SetAmounts=SetAmounts

