-- Copyright 2010 Riccardo Belloli (rb@belloli.net)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--      ## COMMAND LINE INTERPRETER ##


 -- Setup slash commands.
function QDKP2_SetSlashCommands()
  SLASH_QDKP21 = "/dkp"
  SLASH_QDKP22 = "/qdkp2"
  SLASH_QDKP23 = "/qdkp"
  SlashCmdList["QDKP2"] = QDKP2_CLI_ProcessCommand
end

local validwords_number="[0-9]+"
local validwords_integer="(-)?"..validwords_number
local validwords_int_perc=validwords_integer.."(%%)?"
local validwords_name="[^0-9]{3,21}"
local validwords_on="on|yes|y|1|active|activate|start"
local validwords_off="off|no|n|0|deactive|deactivate|stop|close|finish"
local validwords_onoff=validwords_on.."|"..validwords_off
local validwords_channel="guild|raid|officer|say|yell|channel|whisper|party|battleground|raid_waring"
local validwords_guildplayer="%GUILDMEMBERS%"

validwords_channelsDesc="guild, raid, raid_warning, officer, say, yell, whisper, party"

QDKP2_CmdLineFunctions={
--[[
{-- Function
Q1={}, --table or string
Q2={},
needOfficer=true,
needManag=true,
needGUI=true,
func=function(...) end,
syntax="",
desc="",
examples="",
},
{--Var
name=""
longName=""
readOnly=true
tyep="int" --can be int,string,float or bool
onChange=function(...) end,
}
--]]

{Q1="about|info|version|v",
func=function()
	local version="QDKP V"..QDKP2_VERSION
	if QDKP2_BETA then version=version.." BETA"; end
	QDKP2_Msg(version)
	QDKP2_Msg("DB REQUESTED="..QDKP2_DBREQ)
	QDKP2_Msg("DEBUG LEVEL="..QDKP2_DEBUG)
	if QDKP2_OfficerMode() then
		QDKP2_Msg("Running in officer mode")
	else
		QDKP2_Msg("Running in view-only mode")
	end
	print("To report bug and ask for help, mail to rb@belloli.net")
end
},

{Q1="newsession|startsession",
needOfficer=true,
func=function(...)
    local i=string.find(string.lower(text),"session")
    local sessionName=string.sub(text,i+8)
		if #sessionName==0 then sessionName=nil; end
    QDKP2_StartSession(sessionName)
end,
syntax="newsession [<sessionname>]",
desc="Starts a new session. You must be a dkp officer and be in a raid.\nSessionname is an optional label and can be everything you want",
examples="newsession\nnewsession ICC10 group b",
},

{Q1="stopsession|endsession",
needOfficer=true,
func=function(...) QDKP2_StopSession(); end,
syntax="stopsession",
desc="Ends an ongoing session.",
},

{Q1="upload|send|sync|syncronize",
needOfficer=true,
func=function(...) QDKP2_UploadAll(); end,
syntax="upload",
desc="Sends all DKP changes to the officer/public guild notes.\nHas no effect if you haven't made any DKP operation.",
},

{Q1="timer",
Q2=validwords_onoff,
needOfficer=true,
func=function(...)
	if QDKP2_CLI_IsOnOff(W2)==true then QDKP2_TimerOn()
	elseif QDKP2_CLI_IsOnOff(W2)==false then QDKP2_TimerOff()
	elseif W2=="pause" then QDKP2_TimerPause()
--	elseif tonumber(W2) then
--		QDKP2_TimerSetBonus(tonumber(W2))
--		if QDKP2GUI then QDKP2GUI_Main:dkpPerHourSet(tonumber(W2)); end
--		QDKP2_Msg("Hourly bonus set to "..tonumber(W2))
	end
end,
syntax="timer on|off|pause",
desc='Lets you start, stop and pause the raid timer. Use the command "hourlybonus" (or the GUI) to read and change the DKP amount to give to players on the hour.',
},

{Q1="ironman|im|ironm|iman",
Q2="wipe|finish|"..validwords_on,
Q3=validwords_integer.."|nil", --numbers or nil
needOfficer=true,
needManag=true, 
func=function(...)
	if QDKP2_CLI_IsOnOff(W2)==true then QDKP2_IronManStart()
	elseif W2=="finish" and tonumber(W2) then QDKP2_InronManFinish(tonumber(W2))
	elseif W2=="wipe" then QDKP2_IronManWipe()
  else return "syntax_error"
	end
end,
syntax="ironman start|finish|wipe [<amount>]",
desc='Lets you start, cancel (wipe) and award the Iron Man bonus.\nWhen you award it, you must specify the amount of DKP you wish to give.',
},

{Q1="(boss)|(autoboss)|(bossbonus)|(bossaward)",
needOfficer=true,
needManag=true,
func=function(...) QDKP2_CLI_StdOnOffToggleHandler(QDKP2_BossBonusSet,...); end,
syntax="bossaward on|off|toggle",
desc="Enables/disables the Boss Kill bonus. You must have set the DKP amounts to award on bosses' death in the Options.ini file.",
},

{Q1="(winnerdetector)|(windetect)|(detectwin)",
needOfficer=true,
needManag=true,
func=function(...) QDKP2_CLI_STDonoffHandler(QDKP2_DetectBidSet,...); end,
syntax="detectwin on|off|toggle",
desc='Enables/disables the raid chat monitor to look for item wins. It activates when finds a chat entry with a vaild guild member name, a number and a triggering word like "dkp", "win", "goes",...',
},

{Q1="gui|main",
needOfficer=true,
needGUI=true,
func=function(...) QDKP2_CLI_STDshowhideHandler(QDKP2GUI_Main,...); end,
syntax="gui show||hide||toggle",
desc='Show/hides the main QDKP window',
},

{Q1="roster",
needGUI=true,
func=function(...) QDKP2_CLI_STDshowhideHandler(QDKP2GUI_Roster,...); end,
syntax="roster show||hide||toggle",
desc='Show/hides the roster',
},

{Q1="log",
needGUI=true,
func=function(...) QDKP2_CLI_STDshowhideHandler(QDKP2GUI_Log,...); end,
syntax="log show||hide||toggle",
desc="Show/hides the roster",
},

{Q1="(toolbox)|(tb)",
needGUI=true,
func=function(...) QDKP2_CLI_STDshowhideHandler(QDKP2GUI_Toolbox,...); end,
syntax="toolbox show||hide||toggle",
desc="Show/hides the toolbox (the window to modify DKP amounts)",
},

{Q1="showlog",
Q2=validwords_name,
needGUI=true,
func=function(...)
	W2=QDKP2_FormatName(W2)
	if W2=="Raid" then QDKP2GUI_Log:ShowRaid()
	elseif QDKP2_IsInGuild(W2) then QDKP2GUI_Log:ShowPlayer(W2)
	else QDKP2_CLI_WrongGuildmemberName()
	end
end,
syntax="showlog <name>",
desc="Shows the log for the specified player.",
},
{Q1="showtoolbox",
Q2=validwords_name,
needGUI=true,
func=function(...)
	W2=QDKP2_FormatName(W2)
	if W2=="Raid" then QDKP2GUI_Log:ShowRaid()
	elseif QDKP2_IsInGuild(W2) then QDKP2GUI_Toolbox:Popup(W2)
	else QDKP2_CLI_WrongGuildmemberName()
	end
end,
syntax="showtoolbox <name>",
desc="Shows the toolbox for the specified player.",
},

{Q1="raidaward|raidawards",
Q2=validwords_integer,
Q3="for|nil",
needOfficer=true,
needManag=true,
func=function(...)
	local amount, reason=tonumber(W2)
	local i=string.find(string.lower(text)," for ")
	if i then reason=string.sub(text,i+5); end
	QDKP2_RaidAward(amount,reason)
end,
syntax="raidaward <amount> [for <reason>]",
desc="Gives a DKP award to all eligible raid members. You need to be in a raid and have an open session to do this.\nAmount must be an integer number (can be negative). You can also specify a optional reason to label the entry in the raid and players' logs.",
examples="raidaward 34\nraidaward 12 for great performance\nraidaward -45 for bad behavior",
},

{Q1="do",
Q2=validwords_guildplayer,
Q3="spend|spends|-|award|awards|+|gain|gains|earn|earns|zerosum|zerosums|zs",
Q4=validwords_int_perc,
Q5="for|nil",
needOfficer=true,
func=function(...)
	W4=tostring(W4)
	local reason
	local i=string.find(string.lower(text)," for ")
	if i then reason=string.sub(text,i+5); end
	if W3=="zerosum" or W3=="zerosums" or W3=="zs" then
		if not QDKP2_ManagementMode() then QDKP2_NeedManagementMode(); return; end
		QDKP2_RaidAward(W4, reason, W2)
	elseif W3=="spend" or W3=="spends" or W3=="-" then QDKP2_PlayerSpends(W2,W4, reason)
	else QDKP2_PlayerGains(W2, W4, reason)
	end
	QDKP2_Events:Fire("DATA_UPDATED","all")
 end,
syntax="do <name> gain|spend|zerosum <amount> [for <reason>]",
desc="Gives/subtracts DKP to the given guildmember. While managing an open session, you can also use this to set up a zerosum payment made by <name>. <amount> must be an integer number (can be negative), and can be expressed as percentual of the player's NET dkp amount. You can also specify an optional reason to label the entry in the players' logs.",
examples="do killerbe gain 23\ndo ballanzone spend 50 for being late at invite\ndo rosky zerosums 100 for [itemlink]\ndo retiles spend 50% for screwing up stuff",
},

{Q1="set",
Q2=	validwords_guildplayer,
Q3="net|total|spent|hours|n|t|s|h",
Q4=validwords_integer,
needOfficer=true,
func=function(...)
	local amount=tonumber(W4)
	if W3=="net" or W3=="n" then
		local tot,spent
		if amount>QDKP2_GetNet(W2) then tot=amount - QDKP2_GetNet(W2)
		elseif amount<QDKP2_GetNet(W2) then spent=QDKP2_GetNet(W2) - amount
		end
		QDKP2_AddTotals(W2, tot, spent, nil, "Command Line editing")
	elseif W3=="total" or W3=="t" then
		QDKP2_AddTotals(W2, amount - QDKP2_GetTotal(W2), nil, nil, "Command Line editing")
	elseif W3=="spent" or W3=="s" then
		QDKP2_AddTotals(W2, nil,  amount - QDKP2_GetSpent(W2), nil, "Command Line editing")
	else
		QDKP2_AddTotals(W2, nil, nil,  amount - QDKP2_GetHours(W2), "Command Line editing")
	end
	QDKP2_Events:Fire("DATA_UPDATED","all")
end,
syntax="set <name> net|total|spent|hours <amount>",
desc="Sets <name>'s specified DKP field. The available fields are net, total and spent DKP, plus raiding hours. Please note that, since the net amount is calculated as total-spent, setting it means settings the total or the spent field. <amount> must be a integer number (can be negative)",
examples="set killerbee total 100\nset ballanzone spent 0\nset rosky net 10\nset retiles hours 0",	
},

{Q1="decay",
Q2=validwords_int_perc,
needOfficer=true,
func=function(...) QDKP2_Decay("guild",W2); end,
syntax="decay <amount>[%]",
desc="This function subtracts a fixed amount or a percentage of net DKP for every player in the guild. You can't use this function while you are managing an opened session.",
examples="decay 35\ndecay 10%",
},

{Q1="getvalues|getvalue|values|value|get",
Q2=validwords_guildplayer,
func=function(...)
	QDKP2_Msg(W2.." values:")
	QDKP2_Msg("Net="..tostring(QDKP2_GetNet(W2)).." DKP")
	QDKP2_Msg("Total="..tostring(QDKP2_GetTotal(W2)).." DKP")
	QDKP2_Msg("Spent="..tostring(QDKP2_GetSpent(W2)).." DKP")
	if QDKP2_StoreHours then
		QDKP2_Msg("Time="..tostring(QDKP2_GetHours(W2)).." Hours")
	end
end,
syntax="getvalues <name>",
desc="Prints a list of specified player's DKP amounts, plus raiding time (if enabled)."
},

{Q1="notify",
Q2=validwords_guildplayer.."|all|raid",
func=function(...)
	if W2=="raid" then QDKP2_NotifyRaid()
	elseif W2=="guild" then QDKP2_NotifyGuild()
	else QDKP2_Notify(W2)
	end
end,
syntax="notify <name>|guild|raid",
desc='Whispers the specified guildmember his DKP amount. Write the target "guild" to notify DKP to every online guild member, and"raid" to notify all the members of the raid you are into.',
},

{Q1="charge",
Q2="loot|chat",
needOfficer=true,
needManag=true,
func=function(...)
    if W2=="loot" then QDKP2_BIND_ChargeLastLoot()
    else QDKP2_BIND_ChargeLastSeen()
    end
end,
syntax="charge loot|chat",
desc='Used to charge players for looting an item. "charge loot" will let you charge the last player that looted an epic item. "charge chat" takes the last epic item seen in raid chat and asks who has to be charged for that, then opens his toolbox window.\nBoth these functions can only be used while managing an opened session.',
},

{Q1="report",
Q2=validwords_guildplayer.."|raid",
Q3="all|session|current",
Q4=validwords_channel.."|nil",
func=function(...)
	local Loglist,Type,Channel
	if W3=="all" then
		Loglist=QDKP2log_ParsePlayerLog(W2)
		Type="Overview"
	else
		local Session=QDKP2_IsManagingSession()
		if not Session then
			QDKP2_Msg("You aren't managing any open session.","ERROR"); return
		end
		local _,SessName=QDKP2_GetSessionInfo(Session)
		Type="Current session "..SessName
		Loglist=QDKP2log_GetPlayer(Session,W2)
	end
	if not Loglist or table.getn(Loglist)==0 then
		QDKP2_Msg("Given player's log is empty.","WARNING"); return
	end
	if QDKP2_CLI_CheckChannelAddition(W4,W5) then
		QDKP2_MakeAndSendReport(Loglist,Target,Type,W4,W5)
	end
end,
syntax="report <name> session|all <channel> [<whisperto>|<channelname>]",
desc='Builds a log report for the specified member name and sends it to the given channel. Valid channels are: guild,officer,raid,whisper,say,yell,channel or the first letter of each. If you specify "whisper" or "channel", you have to futher provide the player or the channel'.."'"..'s name where you wish to post the report to.',
examples="report killerbee session guild\nreport ballanzone session whisper ballanzone\nreport killerbee all r",
},

{Q1="db|database",
Q2="list|del|delete|import",
needOfficer=true,
func=function(...)
	local DBguilds=ListFromDict(QDKP2_Data)
	for i=1,#DBguilds do if DBguilds[i]=="StoreVers" then table.remove(DBguilds,i); end; end    if W2=="list" then
		QDKP2_Msg("List of realm-guilds currently stored in the Database:")
		for i=1,#DBguilds do
			local guildName=DBguilds[i]
			if guildName == QDKP2_DataLoaded then guildName=guildName.."*"; end
			QDKP2_Msg(tostring(i)..": "..tostring(guildName))
		end
	elseif W2=="del" or W2=="delete" and W3 and tonumber(W3) then
		local GuildName=DBguilds[tonumber(W3)]
		if not GuildName then
			QDKP2_Msg('You must provide a valid database index. List of guilds currently recordedin the database',"WARNING")
			QDKP2_CL_ProcessCommand("db list")
		elseif GuildName == QDKP2_DataLoaded then
			QDKP2_Msg('You cannot remove your current guild from the database! Use "/dkp wipe local" instead.',"WARNING")
		else
			QDKP2_InitData(GuildName,true)
			QDKP2_Data[GuildName]=nil
			QDKP2_Msg('Guild "'..GuildName..'" removed from the database.',"INFO")
		end
--[[
    elseif w2=="import" and W3 and tonumber(W3) then
      local GuildName=DBguilds[tonumber(W3)]
      if not GuildName or not QDKP2_Data[GuildName] or GuildName=="StoreVers" then
        QDKP2_Msg('You must provide a valid database index. Type "/qdkp db list" to get a list.',"WARNING")
        QDKP2_CL_ProcessCommand("db list")
        return
      end
	  if not QDKP2_DataLoaded then
        QDKP2_Msg("You must be in a guild to import data from annother.","ERROR")
        return
      end
      if GuildName == QDKP2_DataLoaded then
        QDKP2_Msg("You can't import your current guild.","ERROR")
        return
      end
	  QDKP2_Data[QDKP2_DataLoaded] = QDKP2_Data[GuildName]
	  QDKP2_ReadDatabase(GuildName)
	  QDKP2_DownloadGuild(Revert)
	  QDKP2_Msg('Database imported.')
--]] --TBD: When I import the data i should also set the guild note (or i'll lose all the logs) and maybe also
     -- the data fields? Or i can leave it to the backup function. But i have to warn the user
	end
end,
syntax="db list|delete [<number>]",
desc="Lets you manage the QDKP's Guild database. You can list the guilds currently stored in the database, or delete an entry. Please note that you can't delete the data of the guild you currently are in. You can use the command "..'"wipe local"'.." to do it.",
},
--[[
{Q1="key|guildkey",
Q2="new|create|remove|delete",
func=function(...)
	if not IsGuildLeader(UnitName("player")) then
		QDKP2_Msg("You must be the Guild Master to set up or remove the guild key.","ERROR")
	elseif W2=="new" or W2=="create"then
		QDKP2_Crypt_GenKey()
	elseif W2=="remove" or W2=="delete" then
		--clear the key
	end
end
},
--]]

{Q1="rights|right|checkright|checkrights",
func=function(...)
	local M1,M2,M3 = QDKP2_GetPermissions()
	QDKP2_Msg(M1);QDKP2_Msg(M2);--QDKP2_Msg(M3)
end,
syntax="checkrights",
desc="Prints a list of the guild DKP rights you have with the currently logged toon. To be able to edit DKPs (ie. switch to officer mode), you need to have all the listed rights.",
},

{Q1="debug",
Q2=validwords_onoff.."full|verbose|error|errors",
func=function(...)
	local switch=QDKP2_CLI_IsOnOff(W2)
	if switch==false then
		QDKP2_DEBUG=0
		QDKP2_Msg("Debug disabled")
	elseif switch==true or W2=="full" then
		QDKP2_DEBUG=2
		QDKP2_Msg("Debug enabled. Level=2 (Full)")
	elseif W2=="verbose" then
		QDKP2_DEBUG=3
		QDKP2_Msg("Debug enabled. Level=3 (Verbose)")
	elseif W2=="error" or W2=="errors" then
		QDKP2_DEBUG=1
		QDKP2_Msg("Debug enabled. Level=1 (Errors)")
	end
end,
syntax="debug on|off|verbose|errors",
desc='Enables or disables the debug messages. The first arguments sets the debug level. "verbose" is the most spamming level, "full" the middle one and "error" the less spamming. "on" is the same as"full".',
},

{Q1=="debugfilter",
func=function(...)
	local status=QDKP2_CLI_IsOnOff(W3)
	if W2=="clear" then status=false
	elseif status==nil then status=true
	end
	if W2=="all" or W2=="clear" then
		QDKP2_Debug_FilterAll(status)
		if status then QDKP2_Msg("All debug filters active")
		else QDKP2_Msg("All debug filters removed")
		end
	else
		local exist=QDKP2_Debug_SetFilter(W3,status)
		if not exist then QDKP2_Msg("Invalid subsystem","ERROR"); return; end
		if status then QDKP2_Msg('Activated filter on "'..W2..'" subsystem debug messages.')
		else QDKP2_Msg('Removed filter on "'..W2..'" subsystem debug messages.')
		end
	end
end,
syntax="debugfilter  clear|all|<subsystem> [<on-off>]",
desc='includes or excludes given subsystems from the debug output. "on" activates a filter on the given subsystem, thus preventinngiit from being printed. "off" removes the filter. Use the argument "all" to include all subsystems at once, and "clear" to remove all placed filters (same as "debugfilter all off"). If no status is provided, then "on" is assumed.',
examples="debugfilter GUI\ndebugfilter Init on\ndebugfilter all on\ndebugfilter clear",
},

{Q1="wipe|clear|reset",
Q2="hours|log|dkp|local|all",
func=function(...)
	if W2=="hours" then QDKP2_resetAllGuildHours()
	elseif W2=="log" then QDKP2log_PurgeWipe(true)
	elseif W2=="dkp" then QDKP2_resetDKPAmounts()
	elseif W2=="local" then QDKP2_resetAll()
	elseif W2=="all" then QDKP2_resetGuild()
	end
	QDKP2_Events:Fire("DATA_UPDATED","all")
end,
syntax="wipe hours|log|dkp|local|all",
desc='Wipes all data for the selected context. "local" clears all DKP data regarding your actual guild from your own PC, and is the only wipe you can perform if not a DKP officer. "hours" resets raiding hours to 0 for every member in the guild, "log" clears the log at guild level, "dkp" resets every DKP amount to 0, and "all" combines all of the previous to  completely eradicate QDKP data from both your computer and the guild.',
},

{Q1="makealt",
Q2=validwords_guildplayer,
Q3=validwords_guildplayer,
needOfficer=true,
func=function(...)
	if W2==W3 then QDKP2_Msg("An alt's Main must be different from the alt himself.","ERROR")
	elseif QDKP2_IsAlt(W3) then QDKP2_Msg("You can't define an alt as a main.","ERROR")
	else
		QDKP2altsRestore[W2]=W3
		QDKP2_DownloadGuild(nil,false)
		QDKP2_Events:Fire("DATA_UPDATED","toolbox")
		QDKP2_Events:Fire("DATA_UPDATED","roster")
		QDKP2_Msg("Upload Changes to store the modifications.","WARNING")
	end
end,
syntax="makealt <alt> <main>",
desc="Makes <alt> an alt character of <name>. Both <alt> and <name> must be valid guildmembers, and you can't use an already defined alt as a main. Alts shares their main's DKP pool and log. Use it if your guild lets the players to use DKP gained with other characters of the same player (ie. DKP pool is player based, not character based). Remember to upload changes to store the alt statusin the officer notes.",
example="makealt killerbee straker",
},

{Q1="clearalt",
Q2=validwords_guildplayer,
needOfficer=true,
func=function(...)
	if not QDKP2_IsAlt(W2) then QDKP2_Msg("That player is not an alt.","ERROR")
	else
		QDKP2altsRestore[W2]=""
		QDKP2alts[W2]=nil
		QDKP2_DownloadGuild(nil,false)
		QDKP2_Events:Fire("DATA_UPDATED","toolbox")
		QDKP2_Events:Fire("DATA_UPDATED","roster")
		QDKP2_Msg("Upload Changes to store the modifications.","WARNING")
	end
end,
syntax="clearalt <alt>",
desc="Clears the alt status for the given alt. Obiviously enough, <alt> must be a previously defined alt.",
},

{Q1="exernal",
Q2="add|remove|rem|delete|del|list",
Q3="nil|"..validwords_name,
needOfficer=true,
func=function(...)
	if W2=="list" then
    local list=ListFromDict(QDKP2externals)
    if #list==0 then
      QDKP2_Msg("No external has been added to the guild roster.")
    else
      QDKP2_Msg("Externals currently in the guild roster:")
      for i=1,#list do QDKP2_Msg(list[i]); end
    end
  elseif W2=="add" and W3 then
    W3=QDKP2_FormatName(W3)
    if not QDKP2_NewExternal(W3) then QDKP2_Msg("Couldn't add "..W3.." to the guild roster.","ERROR"); end
  elseif W2=="remove" and W3 then
    W3=QDKP2_FormatName(W3)
    QDKP2_DelExternal(W3) 
	end
  QDKP2_DownloadGuild(nil,false)
  QDKP2_UpdateRaid()
  QDKP2_Events:Fire("DATA_UPDATED","roster")
end,
syntax="exernal add|remove|list [<name>]",
desc='Lets you add or remove players that are not in guild from QDKP roster. use "list" to print a list of currently defined externals.',
examples="external add dexter\nexternal list\nexternal remove dexter",
},

{Q1="standby",
Q2="list|add|remove",
Q3="nil|"..validwords_guildplayer,
needOfficer=true,
func=function(...)
	if W2=="list" then
		if #QDKP2standby==0 then
			QDKP2_Msg("No players added to the raid roster as standby at the moment.","WARNING")
		else
			QDKP2_Msg("Players added to the current raid roster as standby:")
			for i=1,#QDKP2standby do QDKP2_Msg(QDKP2standby[i]); end
		end
		return
	elseif W2=="add" and W3 then
		if QDKP2_IsInRaid(W3) then QDKP2_Msg('The given player is already in the Raid',"WARNING"); return
		elseif QDKP2_AddStandby(W3) then QDKP2_Msg(W3.." added to the raid")
		else QDKP2_Msg("Couldn't add "..W3.." to the raid roster.","ERROR"); return
		end
	elseif W2=="remove" and W3 then
		if not QDKP2_IsStandby(W3) then QDKP2_Msg(W3.." is not a standby member.","WARNING")
		elseif QDKP2_RemStandby(W3) then QDKP2_Msg(W3.." removed from the raid")
		else QDKP2_Msg("Couldn't remove "..W3.." from the raid roster.","ERROR"); return
		end
	end
	QDKP2_Events:Fire("DATA_UPDATED","roster")
	QDKP2_Events:Fire("DATA_UPDATED","log")
end,
syntax="standby add|remove|list <guildmember>",
desc="This is to manage standby players. You can add, remove and list the guild members that are included in QDKP's raid roster without being in the real raid.",
examples="standby add killerbee\nstandby remove killerbee",
},

{Q1="classdkp",
Q2="death knight|dk|druid|hunter|mage|paladin|priest|rogue|shaman|warlock|warrior",
Q3=validwords_channel.."|nil",
func=function(...)
	local class=W2
	if class=="dk" then class="death knight"; end
	local output={"QDKP2 - Top DKP players for "..origClass.." class:"}
	local list={}
	for i,name in ipairs(QDKP2name) do
		local classAct=QDKP2classEnglish[QDKP2class[name]] or QDKP2class[name]
		if string.lower(classAct)==class then
			table.insert(list,name)
		end
	end
	if table.getn(list)==0 then QDKP2_Msg('No Guild Members for the given class',"WARNING")
	else
		QDKP2_netSort(list)
		for i,name in ipairs(list) do
			if i > 10 then break; end
			local DKP=QDKP2_GetNet(name)
			table.insert(output,QDKP2_GetName(name)..": "..tostring(DKP).." DKP")
		end
		if QDKP2_CLI_CheckChannelAddition(W3,W4) then QDKP2_SendList(output,W3,W4); end
	end
end,
syntax="classdkp <class> [<channel>] [<subchannel>]",
desc='Sends a top-ten list for toon of the given class, sorted by descending net DKP amount, to the given channel or to the local console if no channel is provided. You must use english names for classes. Valid channels are: '..validwords_channelsDesc..". subchannel must be used when the whisper channel is selected, to specify the name of the player to whisper to.",
examples="classdkp warrior guild\nclassdkp dk raid\nclassdkp druid whisper killerbee",
},

{Q1="rankdkp",
Q2=".+",
Q3=validwords_channel.."|nil",
func=function(...)
	local output={"QDKP2 - Top DKP players for "..W2.."rank:"}
	local list={}
	for i,name in ipairs(QDKP2name) do
		local rankAct=string.lower(QDKP2rank[name])
		if rankAct==W2 then
			table.insert(list,name)
		end
	end
	if table.getn(list)==0 then QDKP2_Msg("No Guild Members for the given rank","WARNING")
	else
		QDKP2_netSort(list)
		for i,name in ipairs(list) do
			if i > 10 then break; end
			local DKP=QDKP2_GetNet(name)
			table.insert(output,QDKP2_GetName(name)..": "..tostring(DKP).." DKP")
		end
		if QDKP2_CLI_CheckChannelAddition(W3,W4) then QDKP2_SendList(output,W3,W4); end
	end
end,
syntax="rankdkp <rank> [<channel>] [<subchannel>]",
desc='Sends a top-ten list for toon of the given rank, sorted by descending net DKP amount, to the given channel or to the local console if no channel is provided. If the rank name has spaces, you must enclose it in quotation marks. Valid channels are: '..validwords_channelsDesc..". subchannel must be used when the whisper channel is selected, to specify the name of the player to whisper to.",
examples='rankdkp raider guild\nclassdkp "guild master" raid\nclassdkp veterans whisper killerbee',
},

{Q1="bid",
Q2="start|stop|finish|cancel|reset|countdown|list|win|winner",
needOfficer=true,
func=function(...)
	if W2=="start" then
		local item=text:sub(11)
		if #item==0 then item=nil; end
		QDKP2_BidM_StartBid(item)
	elseif W2=="stop" or W2=="finish" then
		if not QDKP2_BidM_isBidding() then QDKP2_Msg("There is not an ongoing bidding!","ERROR")
		else  QDKP2_BidM_CloseBid()
		end
	elseif W2=="cancel" then
		if not QDKP2_BidM_isBidding() then QDKP2_Msg("There is not an ongoing bidding!","ERROR")
		else QDKP2_BidM_CancelBid()
		end
	elseif w2=="reset" or W2=="clear" then
		QDKP2_BidM_Reset()
	elseif W2=="countdown" then
		QDKP2_BidM_Countdown()
	elseif W2=="list" then
		local channel
		if string.find(W3,validwords_channel) then channel=string.upper(W3); end
		if channel then ChatThrottleLib:SendChatMessage("ALERT", "QDKP2", "Bidders list", channel ,nil, W4)
		else print('Bidders list')
		end
		for name,bid in pairs(QDKP2_BidM.LIST) do
			local msg=tostring(name)..' bid='..tostring(bid.txt)..' value='..tostring(bid.value)..' roll='..tostring(bid.roll or '')
			if channel then ChatThrottleLib:SendChatMessage("ALERT", "QDKP2", msg, channel ,nil, W4)
			else print(msg)
			end
		end
	elseif (W2=="win" or W2=="winner") and W3 then
		local player=QDKP2_FormatName(W3)
		local winner=QDKP2_BidM.LIST[player]
		if winner then QDKP2_BidM_Winner(player)
		else QDKP2_Msg(player.." is not a valid bidder name. use /dkp bid list to get a list of current bidders.","WARNING")
		end
	end
end,
syntax="bid start|stop|cancel|list|win [<item or winner>]",
desc="Lets you start, stop, cancel bids and announce/charge the winner. See the examples for more infos.",
examples="bid start [Sword of Imba Pownage]\nbid stop\nbid list\nbid win killerbee\nbid cancel",
},

{Q1="export",
Q2="dkp|values",
Q3="nil|txt|html|xml",
func=function(...)
	if W2=="dkp"or W2=="values" then
		QDKP2_Export_Popup("guild",W3 or 'txt')
	end
end,
syntax="export values [txt|html|xml]",
desc="Opens a dialog to export various QDKP data. Just copy the already selected text pressing CTRL+C on your keyboard (or the equivalent if you're on mac) and paste where you wish. The standard formats you can output is plain text (useful in local text files, or on forums where HTML is not allowed), HTML for sites and enabled forums, and XML for advanced uses.",
},

{Q1="help|h|?",
func=function(...)
	if W2 then
		for i,voice in ipairs(QDKP2_CmdLineFunctions) do
			if string.find(W2,voice.Q1) and voice.syntax then
				QDKP2_CLI_HelpCommand(voice)
				return
			end
		end
		QDKP2_Msg("The specified command does not exist.","ERROR")
	else QDKP2_CLI_Help()
	end
end
},

}

function QDKP2_CLI_ProcessCommand(text)
  QDKP2_Debug(2,"CLI","Got command: "..tostring(text))
  if not QDKP2_ACTIVE then
    QDKP2_Msg("Quick DKP is not fully initialized yet. Please wait 5 seconds and try again.","WARNING")
    return
  end
	local cmd={}
  cmd[1],cmd[2],cmd[3],cmd[4],cmd[5]=QDKP2libs.AceConsole:GetArgs(string.lower(text), 5)
	cmd[1]=tostring(cmd[1]); cmd[2]=tostring(cmd[2]); cmd[3]=tostring(cmd[3]); cmd[4]=tostring(cmd[4]); cmd[5]=tostring(cmd[5])
  QDKP2_Debug(2,"CLI","Unpacked into: "..cmd[1]..", "..cmd[2]..", "..cmd[3]..", "..cmd[4]..", "..cmd[5])
	local officer=QDKP2_OfficerMode()
	local session=QDKP2_isManagingSession()
	for i,voice in ipairs(QDKP2_CmdLineFunctions) do
		if string.find(cmd[1],voice.Q1) then			
			if voice.needOfficer and not officer then QDKP2_Msg(QDKP2_LOC_NoRights,"ERROR")
			elseif voice.needManag and not session then QDKP2_Msg(QDKP2_LOC_NeedManagementMode,"WARNING")
			elseif voice.needGUI and not QDKP2GUI_OnLoad then QDKP2_Msg("This command needs the addon's GUI component to be enabled and loaded.","ERROR")
			else
				local guildplayers=''
				for i=2,5 do
					local Q=voice["Q"..i]
					if not Q then break; end
					local W=cmd[i]
					if string.find(Q,validwords_guildplayer) then
						if #guildplayers=='' then 
							for i,name in ipairs(QDKP2name) do guildplayers=guildplayers..name..'|'; end
							guildplayers=string.sub(guildplayers,1,-1)
						end
						if Q==validwords_guildplayer and not string.find(W,guildplayers) then
							if W=="nil" then QDKP2_Msg("You must specify a guild member to use this command.","ERROR")
							else QDKP2_Msg(W.." is not a valid guild member.","WARNING")
							end
						else Q=string.gsub(Q,validwords_guildplayer,guildplayers)
						end
					end
					if not string.find(W,Q) then
						QDKP2_Msg("Wrong syntax!","ERROR")
						QDKP2_CLI_HelpCommand(voice,"SHORT")
						return
					end
				end
				local ret=voice.func(text,W1,W2,W3,W4,W5)
				if ret=="syntax_error" then 
					QDKP2_Msg("Wrong syntax!","ERROR")
					QDKP2_CLI_HelpCommand(voice,"SHORT")
				end
				return
			end
		end
	end
	QDKP2_Msg("The specified command does not exist.","ERROR")
end

function QDKP2_CLI_Help(Type)
	local officer=QDKP2_OfficerMode()
	local session=QDKP2_isManagingSession()
	QDKP2_Msg("List of available CLI commands:")
	for i,voice in ipairs(QDKP2_CmdLineFunctions) do
		if voice.syntax and (officer or not voice.needOfficer) and (QDKP2GUI_OnLoad or not voice.needGUI) then
			local msg=""
			if voice.needManag and not session then msg=msg.."(*) "; end
			msg=msg..voice.syntax
			print(msg)
		end
	end
	if officer and not session then QDKP2_Msg("Commands preceded by (*) need to be executed while managing a session and thus cannot be used now."); end
	QDKP2_Msg("text inside <..> has to be replaced with the required variable, arguments inside [..] are optional.")
	QDKP2_Msg('Use "/qdkp help <command>" to get more detail about a specific command.')
end

function QDKP2_CLI_HelpCommand(Voice,Type)
	Type=Type or "FULL"
	print('Command usage: "\qdkp '..QDKP2_COLOR_BLUE..voice.syntax..'"')
	if Type~="FULL" then
		if voice.desc and TYPE~="SHORT" then
			print("")
			print(voice.desc)
		end
		if voice.examples then
			print("Examples:")
			print(voice.examples)
			end
		end
	end
end

------- MISC FUNCTIONS ----------------


--sets all hours to zero in the guild
function QDKP2_resetAllGuildHours()
  if not QDKP2_OfficerMode() then QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR"); return; end
  for i=1, table.getn(QDKP2name) do
    local name = QDKP2name[i]
    if not QDKP2_IsAlt(name) then
      local hour = QDKP2note[name][QDKP2_HOURS]
      --QDKP2session[name][QDKP2_HOURS] = QDKP2session[name][QDKP2_HOURS] - hour
      QDKP2note[name][QDKP2_HOURS] = 0
      QDKP2log_Entry(name,"Raiding hours has been wiped. (Was "..hour..")",QDKP2LOG_EVENT)
    end
	end
  QDKP2_Msg(QDKP2_COLOR_WHITE.."Raiding hours wiped. Upload changes to store in the notes.");
  QDKP2_StopCheck()
  QDKP2_Events:Fire("DATA_UPDATED","all")
end

function QDKP2_resetDKPAmounts(sure)
  if not QDKP2_OfficerMode() then QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR"); return; end
  if not sure then
    QDKP2_AskUser("You are about to clear all guild's\nDKP notes. You will lose all DKP\namounts and every defined Alt relation.\nAre you sure you want to do that?",QDKP2_resetDKPAmounts,true)
    return
  end
  for i=1,QDKP2_GetNumGuildMembers() do
    QDKP2_GuildRosterSetDatafield(i, '')
  end
  QDKP2_Msg("All DKP notes have been cleared. Please wait some seconds for QDKP to update the local amounts.")
end

function QDKP2_resetAll(sure)
  if not GetGuildInfo("player") then
    QDKP2_Msg(QDKP2_LOC_NotIntoAGuild,"ERROR")
    return
  end
  if not sure then
    QDKP2_AskUser("You are about to wipe EVERY data\nQuick DKP has stored in your pc regarding\nyour current guild.\nThis includes the log and the externals.\nAre you sure you want to do that?",QDKP2_resetAll,true)
    return
  end
  QDKP2_InitData(GetRealmName()..'-'..GetGuildInfo("player"))
  ReloadUI()
end

function QDKP2_resetGuild(sure)
  if not QDKP2_OfficerMode then
    QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")
    return
  end
  if not sure then
    QDKP2_AskUser("You are about to wipe EVERY data from\nboth your PC and the Guild. Please note that\nThere is no Undo.\nAre you sure you what to do that? ",QDKP2_resetGuild,true)
    return
  end
  QDKP2_ACTIVE=false
  QDKP2_resetDKPAmounts(true)
  QDKP2_SID.INDEX=1
  QDKP2_SetGuildNotes()
  QDKP2_resetAll(true)
end

function QDKP2_CLI_IsLegalOnOfT(word)
  if QDKP2_CLI_IsOnOff(word)==true then return "on"
  elseif QDKP2_CLI_IsOnOff(word)==false then return "off"
  elseif word=="toggle" then return "toggle"
  end
end

function QDKP2_CLI_IsOnOff(word)
	if QDKP2_CLI_IsOn(word) then return true
	elseif QDKP2_CLI_IsOff(word) then return false
  end
end

function QDKP2_CLI_IsOn(word)
  if string.find(word,validwords_on) then return true; end
end

function QDKP2_CLI_IsOff(word)
	if string.find(word,validwords_off) then return true; end
end

function QDKP2_NeedGUI()
  QDKP2_Msg('You need to enable "Quick DKP V2 - GUI" addon to use this feature.','ERROR')
end

function QDKP2_CLI_CheckChannelAddition(Channel,Addition)
	if Channel=="CHANNEL" and not Addition then
		QDKP2_Msg("You must write the channela name or number.","WARNING")
	elseif (Channel=="WHISPER" or Channel=="C") and notAddition then
		QDKP2_Msg("You must include the player's name to whisper to.","WARNING")
	else return true
	end
end
