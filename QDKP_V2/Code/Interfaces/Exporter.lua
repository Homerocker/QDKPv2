-- Copyright 2006-2009 Riccardo Belloli (rb@belloli.net)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## EXPORTER ##
--
--      Outputs a table of all the DKP values for the guild or raid members.
--      it can uses the ASCII or the HTML backend to produce the table.

--  API Documentation:







------------------------------------- LOCALS-----------------------

local function ColortableToHtml(colorTable)
  local num=colorTable.b*255
  local num=num+bit.band(colorTable.g*65280,0xFF00)
  local num=num+bit.band(colorTable.r*16711680,0xFF0000)
  local str=string.format("%X",num)
  return "#"..string.rep("0",6-#str)..str
end

local GenericXMLHeader='<?xml version="1.0" encoding="ISO-8859-1" ?>'


local function DecodeItemLink(str,format)
--reformats al item links in the text to be human readable
	repeat
		local istart, istop, istring = string.find(str, "|c%x+|H(.+)|h%[.*%]|h|r")
		if istart then
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(istring)
			if format=="html" and itemName then
				local _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId, linkLevel = string.split(":", istring)
				local _,_,_,color=GetItemQualityColor(itemRarity)
				color=string.sub(color,5)
				ilink=string.format('<a href="http://www.wowhead.com/?item=%s"><font color="#%s"><b>[%s]</b></font></a>',itemId,color,itemName)
			else
				ilink=string.format('[%s]',tostring(itemName))
			end
			str=string.sub(str,1,istart-1)..ilink..string.sub(str,istop+1)
		end
	until not istart
	return str
end



--Generic exporter prototype
local GenericExporter={}
GenericExporter.Formats={"Text","HTML","XML"}
function GenericExporter:GetData(EntryList,Format)
	local rowList={}
	for i,x in ipairs(EntryList) do
		local row={}
		for j,culumn in ipairs(self.Columns) do
			if not culumn.isDisabled or not culumn.isDisabled(x,Format) then
				local cell=culumn.query(x,Format)
				table.insert(row,cell)
			end
		end
		table.insert(rowList,row)
	end
	return rowList
end
--Export
function GenericExporter:MakeTable(Format,rowList)
	local width={}
	table.insert(rowList,1,{}) --making room for header
	for i,culumn in ipairs(self.Columns) do
		if not culumn.isDisabled or not culumn.isDisabled(x,Format) then
			table.insert(width,culumn.width)
			table.insert(rowList[1],culumn.header)
			rowList[1].color='#E5D000'
		end
	end
  if Format=='text' then
		return QDKP2_BuildAsciiTable(rowList,width,true,true)
  elseif Format=='html' then
		return QDKP2_BuildHtmlTable(rowList,'#FFFFFF','#202020','#B0B0B0',true,true)
  end
end

function GenericExporter:MakeXML(rowList)
	local out=''
	for i,row in ipairs(rowList) do
		out=out.."  <"..self.XMLRowVoiceName.." "
		for j,cell in ipairs(row) do
			local header=self.Columns[j].xmlHeader
			if cell then out=out..header..'="'..tostring(cell)..'" '
			end
		end
		out=out..'/>\n'
	end
	return out
end
--Column
function GenericExporter:MakeHeader(Format,Header)
	local out=Header or ''
	if Format=='html' then
		out=out:gsub("<","&lt;")
		out=out:gsub(">","&gt;")
		out=string.gsub(out,'QDKP2','<A HREF="http://wow.curse.com/downloads/wow-addons/details/quick-dkp-v2.aspx">QDKP2</A>')
	end
	out=string.gsub(out,"$TIME",date())
	out=string.gsub(out,"$GUILDNAME",QDKP2_GUILD_NAME or '')
	if Format=='text' then
		out=out..'\n\n[CODE]\n'
	elseif Format=='html' then
		out=out..'\n<BR><BR>\n'
	end
	return out
end
function GenericExporter:MakeTail(Format,Tail)
	out=Tail or ''
  if Format=='text' then
    out=out..'\n[/CODE]'
  end
	return out
end


--Guild roster DKP exporter
local GuildExport=QDKP2_CopyTable(GenericExporter)
function GuildExport:Export(Format)
  local nameList = self:GetMembers()
  local out
	local rowList=self:GetData(nameList,Format)
  if Format=='xml' then
    out=GenericXMLHeader..'\n'
    out=out..'<QDKP2EXPORT-DKP list="guild" time="'..time()..'" guild="'..tostring(GetGuildInfo("player"))..'" exporter="'..tostring(UnitName('player'))..'" >\n'
		out=out..self:MakeXML(rowList)
    out=out..'</QDKP2EXPORT-DKP>'
  else
    header=self:MakeHeader(Format,QDKP2_Export_TXT_Header)
		body=self:MakeTable(Format,rowList,width).."\n"
		tail=self:MakeTail(Format)
    out=header..body..tail
  end
  return out
end
function GuildExport:GetMembers() return QDKP2name; end
GuildExport.XMLRowVoiceName="PLAYER"
GuildExport.Columns={
{
header = "Name",
xmlHeader="name",
width = 24,
query = function(name,Format)
  if Format=='html' then
    return '<B>'..QDKP2_GetName(name)..'</B>'
  elseif Format=='xml' then
    return name
  else
    return QDKP2_GetName(name);
  end
end,
},
{
header = "Main",
xmlHeader = "main",
query = function(name,Format)
  return QDKP2alts[name] or false
end,
isDisabled = function(name,Format) if Format=="xml" then return false; end; return true; end,
},
{
header = "Class",
xmlHeader="class",
width = 16,
query = function(name,Format)
  if Format=='html' then
    local class=QDKP2classEnglish[(QDKP2class[name] or "")] or QDKP2class[name] or ""
    colors=QDKP2_GetClassColor(class)
    return '<FONT color="'..ColortableToHtml(colors)..'">'..(QDKP2class[name] or '-')..'</FONT>'
  else
    return QDKP2class[name]
  end
end,
},
{
header = "Rank",
xmlHeader="rank",
width = 12,
query = function(name) return QDKP2rank[name]; end,
},
{
header = "Net DKP",
xmlHeader="net",
width = 9,
query = function(name,Format)
  local net=QDKP2_GetNet(name)
  if net<0 and Format=='html' then
    net='<FONT COLOR="red">'..tostring(net)..'</FONT>'
  end
  return net
end,
},
{
header = "Total DKP",
xmlHeader="total",
width = 9,
query = function(name) return QDKP2_GetTotal(name); end,
},
{
header = "Spent DKP",
xmlHeader="spent",
width = 9,
query = function(name) return QDKP2_GetSpent(name); end,
},
{
header = "Hours",
xmlHeader="hours",
width = 6,
query = function(name) return QDKP2_GetHours(name); end,
isDisabled = function (name,Format) if not QDKP2_StoreHours then return true; end; end,
}
}

--Raid roster DKP exporter
local RaidExport=QDKP2_CopyTable(GuildExport)
function RaidExport:GetMembers() return QDKP2raid; end

--LogList exporter
local LogListExport=QDKP2_CopyTable(GenericExporter)
LogListExport.Formats={"Text","HTML"}
function LogListExport:Export(Format,LogList)
	local rowList=self:GetData(LogList,Format)
	for i=1,#LogList do
		rowList[i].color=ColortableToHtml(QDKP2log_GetEntryColor(QDKP2log_GetType(LogList[i])))
	end
	header=self:MakeHeader(Format,LogExport_TXT_Header)
	body=self:MakeTable(Format,rowList,width).."\n"
	tail=self:MakeTail(Format)
	return header..body..tail
end
LogListExport.Columns={
{header="Time",
xmlHeader="timestamp",
width=12,
query=function(log,Format)
	local ts=QDKP2log_GetTS(log)
	if Format=="xml" then return ts
	else return QDKP2_GetDateTextFromTS(ts)
	end
end,
},
{header="DKP Change",
xmlHeader="change",
width=10,
query=function(log) return QDKP2log_GetChange(log) or ''; end,
},
{header="Description",
xmlHeader="description",
width=42,
query=QDKP2log_GetModEntryText,
},
}

--Log Session exporter
local LogSessionExport=QDKP2_CopyTable(LogListExport)
function LogSessionExport:Export(Format,SID)
	local LogList=QDKP2log_GetPlayer(SID,"RAID")
	if not LogList then return ''; end
	return LogListExport:Export(Format,LogList)
end


--Extended Log Session exporter
local ExtLogSessionExport=QDKP2_CopyTable(LogListExport)
function ExtLogSessionExport:Export(Format,SID)
	local LogList,NameList=QDKP2log_GetSessionDetails(SID)
	QDKP2_Export_PlayerNames=NameList
	--local turn={}
	--for i,v in ipairs(LogList) do turn[#LogList-i+1]=v; end
	--LogList=turn
	return LogListExport.Export(self,Format,LogList)
end

ExtLogSessionExport.Columns=QDKP2_CopyTable(LogListExport.Columns)
table.insert(ExtLogSessionExport.Columns,2,{
header="Player",
xmlHeader="player",
width=24,
query=function(log,Format)
	local name=QDKP2_Export_PlayerNames[log]
	if name~=RAID then name=QDKP2_FormatName(name); end
	return name or ''
	end,
})

local ExporterList={
guild=GuildExport,
raid=RaidExport,
loglist=LogListExport,
logsession=LogSessionExport,
extlogsession=ExtLogSessionExport,
}



function QDKP2_Export_Popup(Type,Format,OptPar)
	local obj=ExporterList[Type]
	if not obj then
		QDKP2_Debug(1,"Core","Asked for unknow export type: "..tostring(Type))
		return
	end
	QDKP2_Export_Type=Type
	QDKP2_Export_OptPar=OptPar
	Format=Format or obj.Formats[1]
	QDKP2_CopyWindow_FormatManager=QDKP2_Export_ManageCheckBox
	QDKP2_Export_ManageCheckBox(Format)
end


function QDKP2_Export_ManageCheckBox(Format)
	local obj=ExporterList[QDKP2_Export_Type]
	if not obj then
		QDKP2_Debug(1,"Core","Asked for unknow export type: "..tostring(Type))
		return
	end
	local formatName
	for i=1,4 do
    local f=obj.Formats[i]
    local check=getglobal("QDKP2_CopyWindow_Format"..i)
    local checkText=getglobal("QDKP2_CopyWindow_Format"..i.."Text")
    if f then
      check:Show()
      checkText:SetText(f)
      if i==Format or string.lower(f)==string.lower(Format) then
        formatName=string.lower(f)
        check:SetChecked(true)
      else
        check:SetChecked(false)
      end
    else
      check:Hide()
		end
	end
	local Text=''
	if not formatName then
		QDKP2_Debug(1,"Core","Asked for unsupported export format: "..tostring(Format))
	else
	  Text=QDKP2_Export(QDKP2_Export_Type,formatName,QDKP2_Export_OptPar)
	end
  QDKP2_OpenCopyWindow(Text,true)
end


function QDKP2_Export(Type,Format,OptPar)
	local obj=ExporterList[Type]
	if not obj then
		QDKP2_Debug(1,"Core","Asking for unknow export type: "..tostring(Type))
		return
	end
  return obj:Export(Format,OptPar)
end



------------ Helper functions ----------------


local nl='\n'

-- this function builds a table made with ascii characters.
-- rowList should have all the lines to be inserted in the table, and
-- all rows must be lists with the cells content.
-- culWidth is a list with the width, in characters, of each culumn
-- header: if true, the first row in list is treated as table header.
-- rowBord: if true and is a number, each n row a horizontal line is placed.
-- culBord: if true, each culumn is separed from each other by a line

local function makeTextLine(line,culWidth,culBord)
    local sep=''
    if culBord then sep = '|'; end
    local out='|'
    for i=1,#culWidth do
      local cw=culWidth[i]
			local cell=DecodeItemLink(tostring(line[i] or ''))
			local cell=QDKP2_CenterString(QDKP2_CutString(cell,cw),cw)
      out=out..cell..sep
    end
    if not culBord then out=out..'|'; end
    return out
end


function QDKP2_BuildAsciiTable(rowList,culWidth,header,culBord,rowBord)
  local testLine=makeTextLine(culWidth or {},culWidth,culBord)
  local sep1=string.rep('-',#testLine)
  local sep2=string.rep('=',#testLine)
  local out=sep1
  for i,row in ipairs(rowList) do
    out=out..nl..(makeTextLine(row,culWidth,culBord))
    if i==1 and header then
      out=out..nl..sep2
    elseif rowBord and i%rowBord == 0 then
      out=out..nl..sep1
    end
  end
  out=out..nl..sep1
  return out
end

function QDKP2_BuildHtmlTable(rowList,txtColor,bgColor,borderColor,header,culBord,rowBord)
  local TableTag='<TABLE cellpadding="10" style="color: $TXTCOLOR;" bgcolor="$BGCOLOR" border="$BORDERWIDTH" bordercolor="$BORDERCOLOR" rules="$BORDERRULE" frame="box">'
  local borderW = '2'
  local borderRule = 'all'
  if culBord and rowBord then
  elseif culBord and header then borderRule='groups'
  elseif culBord then borderRule='cols'
  elseif rowBord then borderRule='rows'
  else borderW='0'
  end
  TableTag=string.gsub(TableTag,"$TXTCOLOR",txtColor)
  TableTag=string.gsub(TableTag,"$BGCOLOR",bgColor)
  TableTag=string.gsub(TableTag,"$BORDERCOLOR",borderColor)
  TableTag=string.gsub(TableTag,"$BORDERRULE",borderRule)
  TableTag=string.gsub(TableTag,"$BORDERWIDTH",borderW)
  local out=TableTag..nl
  if borderRule=='groups' then
    for i=1,#rowList[1] do
      out=out..'<COLGROUP></COLGROUP>'
    end
    out=out..nl
  end
  for i,row in ipairs(rowList) do
    local cellTag='<TD>'
    local cellTagEnd='</TD>'
    local theadStop=''
    if i==1 and header then
      cellTag='<TH>'
      cellTagEnd='</TH>'
      out=out..'<THEAD>'
      theadStop='</THEAD>'
    end
    local rowTag='<TR align="center">'
    if row.color then
      rowTag='<TR align="center" style="color: $ROWCOLOR;">'
      rowTag=string.gsub(rowTag,"$ROWCOLOR",row.color)
    end
    out=out..rowTag..nl
    for i,cell in ipairs(row) do
			cell=DecodeItemLink(cell,'html')
      out=out..cellTag..tostring(cell)..cellTagEnd
    end
    out=out..nl..'</TR>'..theadStop..nl
  end
  out=out..'</TABLE>'..nl
  return out
end


