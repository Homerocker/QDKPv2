-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## GRAPHICAL INTERFACE ##
--
--      Notifies & ask things to the users.


function QDKP2_OpenInputBox(text,func,arg2,arg3,arg4,arg5)
  QDKP2_InputBox_text:SetText(text)
  QDKP2_InputBox_Data:SetText("")
  QDKP2_InputBox_Data:SetFocus()
  QDKP2_InputBox:SetHeight(QDKP2_InputBox_text:GetStringHeight()+100)
  QDKP2_InputBox:Show()
  QDKP2_InputBox_func=func
  QDKP2_InputBox_arg2=arg2
  QDKP2_InputBox_arg3=arg3
  QDKP2_InputBox_arg4=arg4
  QDKP2_InputBox_arg5=arg5
  QDKP2_InputBox_Data:HighlightText()
end

function QDKP2_InputBox_OnEnter()
  QDKP2_InputBox:Hide()
  local data=QDKP2_InputBox_Data:GetText()
  if data == "" then data = nil; end
  QDKP2_InputBox_func(data,QDKP2_InputBox_arg2,QDKP2_InputBox_arg3,QDKP2_InputBox_arg4,QDKP2_InputBox_arg5)
end


function QDKP2_InputBox_SetDefault(text)
  QDKP2_InputBox_Data:SetText(text)
  QDKP2_InputBox_Data:HighlightText()
end

function QDKP2_AskUser(text,func,arg1,arg2,arg3,arg4,arg5)

  QDKP2_QuestionBox_text:SetText(text)
  QDKP2_InputBox:SetHeight(QDKP2_QuestionBox_text:GetStringHeight()+100)
  QDKP2_QuestionBox:Show()
  QDKP2_QuestionBox_func=func
  QDKP2_QuestionBox_arg1=arg1
  QDKP2_QuestionBox_arg2=arg2
  QDKP2_QuestionBox_arg3=arg3
  QDKP2_QuestionBox_arg4=arg4
  QDKP2_QuestionBox_arg5=arg5
end

function QDKP2_AskUser_OnEnter(PressedYes)
  QDKP2_QuestionBox:Hide()
  if PressedYes then
    QDKP2_QuestionBox_func(QDKP2_QuestionBox_arg1, QDKP2_QuestionBox_arg2, QDKP2_QuestionBox_arg3, QDKP2_QuestionBox_arg4, QDKP2_QuestionBox_arg5)
  end
end



function QDKP2_NotifyUser(text)
  QDKP2_NotifyBox_text:SetText(text)
  QDKP2_InputBox:SetHeight(QDKP2_NotifyBox_text:GetStringHeight()+100)
  QDKP2_NotifyBox:Show()
end


function QDKP2_OpenCopyWindow(text,showCheckBox)
  QDKP2_CopyWindow_LinesNum=1
  for i=1,#text do
    if string.sub(text,i,i)=='\n' then QDKP2_CopyWindow_LinesNum=QDKP2_CopyWindow_LinesNum+1; end
  end
  QDKP2_CopyWindow_TextBuff=text
  QDKP2_CopyWindow:Show()
  QDKP2_CopyWindow_text:SetText("Press CTRL+C on the keyboard to copy the export in your clipboard.")
  QDKP2_CopyWindow_Data:SetText(QDKP2_CopyWindow_TextBuff)
  QDKP2_CopyWindow_Data:HighlightText()
  QDKP2_CopyWindow_Data:SetFocus()
end
