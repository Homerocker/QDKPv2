-- Copyright 2010 Riccardo Belloli (rb@belloli.net)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## LOGGING SYSTEM ##
--                   Reports

-- API Documentation
--


--this will create the report and send it on the given channel (GetReport+SendList)
function QDKP2_MakeAndSendReport(List,Name,Type,channel,channelSub)
  local reportList = QDKP2_GetReport(List,Name,Type)
  QDKP2_SendList(reportList,channel,channelSub)
end

function QDKP2_SendListGetChannelSub(channelSub,List,channel)
  QDKP2_SendList(List,channel,channelSub)
end

function QDKP2_SendList(List,channel,channelSub)
  if channel == "CHANNEL" and not channelSub then
    QDKP2_OpenInputBox("Please enter the number of the channel\n to send the report",QDKP2_SendListGetChannelSub, List, channel)
    return
  end
  if channel == "WHISPER" and not channelSub then
    QDKP2_OpenInputBox("Please enter the name of the player\n to send the report",QDKP2_SendListGetChannelSub, List, channel)
    return
  end
  for i=1, #List do
		if channel then ChatThrottleLib:SendChatMessage("ALERT", "QDKP2", List[i], channel ,nil, channelSub)
		else print(List[i])
		end
 end
end

function QDKP2_GetReport(List, name, TypeHeader)
  if not List then
    QDKP2_Debug(1,"Log-Report","Can't make a log report from nil Loglist")
    return {}
  end
  if not name then
    QDKP2_Debug(1,"Log-Report","Can't make a log report without providing a name")
    return {}
  end
  if #List == 0 then
    QDKP2_Debug(1,"Log-Report","Gived a empty Loglist. Aborting Report.")
    return {}
  end

  TypeHeader  = TypeHeader or "unspecified"
  List=List or {}
  local reportList = QDKP2_Invert(List)

  local header = "<QDKP2>"..QDKP2_Reports_Header
  header = string.gsub(header, '$NAME', QDKP2_GetName(name))
  header = string.gsub(header, '$TYPE', TypeHeader)

  local tail = "<QDKP2>"..QDKP2_Reports_Tail

  return QDKP2_GetReportLines(name, reportList, header, tail)
end

function QDKP2_GetReportLines(name, LogList, header, tail) --returns a list with the lines of the report
  name=QDKP2_GetMain(name)
  local output = {}
  if header then
    output = {}
    if name == "RAID" then
      output = {header,
              "    Time       Action",
              "-----------------------------",
              }
    else
      output = {header,
              "    Time      Net      Action",
              "--------------------------------------",
              }
    end
  end

  local Nets={}
  local isRaid=true
  if name ~= 'RAID' then
    Nets=QDKP2log_GetNetAmounts(LogList,QDKP2_GetNet(name),true)
    isRaid=false
  end
  local NoUploadedYet
  for i=1,#LogList  do
    local OriginalLog = LogList[i]
    local Log, isLink = QDKP2log_CheckLink(OriginalLog)

    local Type = Log[QDKP2LOG_FIELD_TYPE]

    if not QDKP2_IsDeletedEntry(Type) then
      local action=QDKP2log_GetModEntryText(OriginalLog,isRaid)
      local datetime = QDKP2log_GetModEntryDateTime(Log)
      local net = tostring(Nets[i])
      local str
      if net and name ~= "RAID" then
        str=datetime.." <"..net.."> "..action
      else
        str=datetime.." - "..action
      end
      str=str.."."
      if Type==QDKP2LOG_MODIFY then
        str=str.." (*)"
        NoUploadedYet=true
      end
      table.insert(output, str)
    end
  end

  if tail then
    table.insert(output, "--------------------------------")
    if NoUploadedYet then
      table.insert(output, "(*): This voice has not been syncronized yet.")
    end
    table.insert(output, tail)
  end
  return output
end

