
  function QDKP2GUI_MiniBtn_Click(arg1,arg2)
    QDKP2_Toggle_Main()
  end

  function QDKP2GUI_MiniBtn_LabelOn(arg1,arg2)
    if not QDKP2_ACTIVE then return; end
    if this.Dragging then return; end
    GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT");
    GameTooltip:AddLine("Quick DKP "..tostring(QDKP2_VERSION))
    if QDKP2_OfficerMode() then
      GameTooltip:AddLine("Officer mode",0.3,1,0.3)
    else
      GameTooltip:AddLine("Read-only mode",1,1,1)
    end
    local M1,M2,M3 = QDKP2_GetPermissions()
    GameTooltip:AddLine("DKP officer rights:")
    GameTooltip:AddLine(M1)     --officer notes
    GameTooltip:AddLine(M2)     --guild notes
    --GameTooltip:AddLine(M3)   --The RSA key is not used for now.
    GameTooltip:AddLine("CLICK: Show/Hide QDKP",.8,.8,.8,1)
    GameTooltip:AddLine("SHIFT+CLICK: Drag this button",.8,.8,.8,1)
    GameTooltip:Show()
  end

  function QDKP2GUI_MiniBtn_LabelOff(arg1,arg2)
    GameTooltip:Hide()
  end

  function QDKP2GUI_MiniBtn_DragOn(arg1,arg2)
  if IsShiftKeyDown()then
    this.Dragging = true;
    QDKP2GUI_MiniBtn_LabelOff();
  end
  end

  function QDKP2GUI_MiniBtn_DragOff(arg1,arg2)
    this:StopMovingOrSizing();
    this.Dragging = nil;
    this.Moving = nil;
  end

  function QDKP2GUI_MiniBtn_Press(arg1,arg2)
    QDKP2GUI_MiniBtnIcon:SetTexCoord(-0.05,0.95,-0.05,0.95)
  end

  function QDKP2GUI_MiniBtn_Release(arg1,arg2)
    QDKP2GUI_MiniBtnIcon:SetTexCoord(0,1,0,1)
  end

 function QDKP2GUI_MiniBtn_Update(arg1,arg2)
  if not this.Dragging then return; end
  local MapScale = Minimap:GetEffectiveScale();
  local CX, CY = GetCursorPosition();
  local X, Y = (Minimap:GetRight() - 70) * MapScale, (Minimap:GetTop() - 70) * MapScale;
  local Dist = sqrt(math.pow(X - CX, 2) + math.pow(Y - CY, 2)) / MapScale;
  local Scale = this:GetEffectiveScale();
  if(Dist <= 90)then
    if this.Moving then
      this:StopMovingOrSizing();
      this.Moving = nil;
    end
    local Angle = atan2(CY - Y, X - CX) - 90;
    this:ClearAllPoints();
    this:SetPoint("CENTER", Minimap, "TOPRIGHT", (sin(Angle) * 80 - 70) * MapScale / Scale, (cos(Angle) * 77 - 73) * MapScale / Scale);

  elseif not this.Moving then
    this:ClearAllPoints();
    this:SetPoint("CENTER", UIParent, "BOTTOMLEFT",CX / Scale, CY / Scale);
    this:StartMoving();
    this.Moving = true;
  end
end
