-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--      ## COMMAND LINE INTERPRETER #


 -- Setup slash commands.
function QDKP2_SetSlashCommands()
  SLASH_QDKP21 = "/dkp"
  SLASH_QDKP22 = "/qdkp2"
  SLASH_QDKP23 = "/qdkp"
  SlashCmdList["QDKP2"] = QDKP2_CLI_ProcessCommand
end


function QDKP2_CLI_ProcessCommand(text)
  QDKP2_Debug(2,"CLI","Got command: "..tostring(text))

  if not QDKP2_ACTIVE then
    QDKP2_Msg("Quick DKP is not fully initialized yet. Please wait 5 seconds and try again.","WARNING")
    return
  end

  local W1,W2,W3,W4,W5=QDKP2libs.AceConsole:GetArgs(string.lower(text), 5)

  QDKP2_Debug(2,"CLI","Unpacked into: "..tostring(W1)..", "..tostring(W2)..", "..tostring(W3)..", "..tostring(W4)..", "..tostring(W5))

  if ((W1=="new" or W1=="start") and W2=="session") or W1=="newsession" or W1=="startsession" then
    local i=string.find(string.lower(text),"session")
    local sessionName=string.sub(text,i+8)
    QDKP2_StartSession(sessionName)
    return

  elseif ((W1=="stop" or W1=="end") and W2=="session") or W1=="stopsession" or W1=="endsession"  then
    QDKP2_StopSession()
    return

  elseif W1=="upload" or W1=="send" or W1=="sync" or W1=="syncronize" then
    QDKP2_UploadAll()
    return

  elseif W1=="timer" or W1=="tim" or W1=="t" then
    if QDKP2_CLI_IsOnOff(W2)==true then
      QDKP2_TimerOn()
    elseif QDKP2_CLI_IsOnOff(W2)==false then
      QDKP2_TimerOff()
    elseif W2=="bonus" or W2=="dkp" or W2=="setbonus" and tonumber(W3) then
      QDKP2_TimerSetBonus(tonumber(W3))
      if QDKP2GUI then
        QDKP2GUI_Main:dkpPerHourSet(tonumber(W3))
        QDKP2_Msg("Hourly bonus set to "..tonumber(W3))
      end
    else
      QDKP2_CLI_ShowUsage("timer on|off|bonus [<dkp>]"); return
    end
    return


  elseif W1=="ironman" or W1=="im" or W1=="ironm" then
    if QDKP2_CLI_IsOnOff(W2)==true then
      QDKP2_IronManStart()
    elseif QDKP2_CLI_IsOnOff(W2)==false and tonumber(W3) then
      QDKP2_InronManFinish(tonumber(W3))
    elseif W2=="wipe" then
      QDKP2_IronManWipe()
    else
      QDKP2_CLI_ShowUsage("ironman start|stop|wipe [<amount>]")
    end
    return


  elseif (W1=="autoboss" or W1=="boss") then
    local W2=QDKP2_CLI_IsLegalOnOfT(W2)
    if W2 then
      QDKP2_BossBonusSet(W2);
    else
      QDKP2_CLI_ShowUsage("autoboss on|off||toggle")
    end
    return

  elseif W1=="detectwin" or W1=="detectwinners" then
    local W2=QDKP2_CLI_IsLegalOnOfT(W2)
    if W2 then
      QDKP2_DetectBidSet(W2)
    else
      QDKP2_CLI_ShowUsage("detectwin on|off||toggle")
    end
    return

  elseif W1=="gui" or W1=="main" then
    if not QDKP2GUI then QDKP2_NeedGUI(); end
    local W2=QDKP2_CLI_IsLegalOnOfT(W2) or W2
    if not W2 or W2=="toggle" then
      QDKP2GUI_Main:Toggle()
    elseif W2=="on" then
      QDKP2GUI_Main:Show()
    elseif W2=="off" then
      QDKP2GUI_Main:Hide()
    else
      QDKP2_CLI_ShowUsage("gui show||hide||toggle")
    end
    return

  elseif W1=="roster" or W1=="list" then
    if not QDKP2GUI then QDKP2_NeedGUI(); end
    local W2=QDKP2_CLI_IsLegalOnOfT(W2) or W2
    if not W2 or W2=="toggle" then
      QDKP2GUI_Roster:Toggle()
    elseif W2=="on" then
      QDKP2GUI_Roster:Show()
    elseif W2=="off" then
      QDKP2GUI_Roster:Hide()
    else
      QDKP2_CLI_ShowUsage("roster show||hide||toggle")
    end
    return

  elseif W1=="log" then
    if not QDKP2GUI then QDKP2_NeedGUI(); end
    local W2=QDKP2_CLI_IsLegalOnOfT(W2) or W2
    if not W2 or W2=="toggle" then
      QDKP2GUI_Log:Toggle()
    elseif W2=="on" then
      QDKP2GUI_Log:Show()
    elseif W2=="off" then
      QDKP2GUI_Log:Hide()
    else
      QDKP2_CLI_ShowUsage("log show||hide||toggle")
    end
    return

  elseif W1=="toolbox" or W1=="tb" then
    if not QDKP2GUI then QDKP2_NeedGUI(); end
    local W2=QDKP2_CLI_IsLegalOnOfT(W2) or W2
    if not W2 or W2=="toggle" then
      QDKP2GUI_Toolbox:Toggle()
    elseif W2=="on" then
      QDKP2GUI_Toolbox:Show()
    elseif W2=="off" then
      QDKP2GUI_Toolbox:Hide()
    else
      QDKP2_CLI_ShowUsage("toolbox show||hide||toggle")
    end
    return

  elseif W1=="showlog" then
    if not QDKP2GUI then QDKP2_NeedGUI(); end
    W2=QDKP2_FormatName(W2)
    if W2=="Raid" then QDKP2GUI_Log:ShowRaid()
    elseif QDKP2_IsInGuild(W2) then QDKP2GUI_Log:ShowPlayer(W2)
    elseif #W2>0 then QDKP2_Msg(QDKP2_COLOR_RED.."No matching with that guildmember name.")
    else
      QDKP2_CLI_ShowUsage("showlog <name>||raid")
    end
    return

  elseif (W1=="showtoolbox" or W1=="showtb") then
    if not QDKP2GUI then QDKP2_NeedGUI(); end
    W2=QDKP2_FormatName(W2)
    if QDKP2_IsInGuild(W2) then QDKP2GUI_Toolbox:Popup(W2)
    elseif #W2>0 then QDKP2_Msg(QDKP2_COLOR_RED.."No matching with that guildmember name.")
    else
      QDKP2_CLI_ShowUsage("showtoolbox <name>")
    end
    return

  elseif W1=="raidawards" or W1=="raidaward" then
    local amount=tonumber(W2)
    if amount and (not W3 or W3=="for") then
      local i=string.find(string.lower(text)," for ")
      local reason
      if i then reason=string.sub(text,i+5); end
      QDKP2_RaidAward(amount,reason)
    else
      QDKP2_CLI_ShowUsage("raidaward <amount> [for <reason>]")
    end
    return


  elseif W1=="do" then
    local amount = W4
    if amount and W2 and ((W3=="spend" or W3=="spends" or W3=="-") or (W3=="award" or W3=="awards" or W3=="+" or W3=="gain" or W3=="gains") or (W3=="zerosum" or W3=="zs")) and (not W5 or W5=="for") then
      W2=QDKP2_FormatName(W2)
      if QDKP2_IsInGuild(W2) then
	local i=string.find(string.lower(text)," for ")
        local reason
        if i then reason=string.sub(text,i+5); end
        if W3=="zerosum" or W3=="zs" then
          QDKP2_RaidAward(amount, reason, W2)
        elseif W3=="spend" or W3=="spends" or W3=="-" then
          QDKP2_PlayerSpends(W2,amount, reason)
        else
          QDKP2_PlayerGains(W2, amount, reason)
        end
        QDKP2_Events:Fire("DATA_UPDATED","all")
      else QDKP2_Msg(QDKP2_COLOR_RED.."No matching with that guildmember name.")
      end
    else
      QDKP2_CLI_ShowUsage("do <name> gain|spend|zerosum <amount> [for <reason>]")
    end
    return

  elseif W1=="set" then
    local amount = tonumber(W4)
    if amount and W2 and (W3=="net" or W3=="total" or W3=="spent" or W4=="hours") then
      W2=QDKP2_FormatName(W2)
      if QDKP2_IsInGuild(W2) then
        if W3=="net" then
          local tot,spent
          if amount>QDKP2_GetNet(W2) then tot=amount - QDKP2_GetNet(W2)
          elseif amount<QDKP2_GetNet(W2) then spent=QDKP2_GetNet(W2) - amount
          end
          QDKP2_AddTotals(W2, tot, spent, nil, "Command Line editing")
        elseif W3=="total" then
          QDKP2_AddTotals(W2, amount - QDKP2_GetTotal(W2), nil, nil, "Command Line editing")
        elseif W3=="spent" then
          QDKP2_AddTotals(W2, nil,  amount - QDKP2_GetSpent(W2), nil, "Command Line editing")
        elseif W3=="hours" then
          QDKP2_AddTotals(W2, nil, nil,  amount - QDKP2_GetHours(W2), "Command Line editing")
        end
        QDKP2_Events:Fire("DATA_UPDATED","all")
      else
        QDKP2_Msg(QDKP2_COLOR_RED.."No matching with that guildmember name.")
        return
      end
    else
      QDKP2_CLI_ShowUsage("set <name> net||total|spent|Hours <amount>")
    end
    return

  elseif (W1=="decay" or W1=="guilddecay" or W1=="raiddecay") then
    local perc=W2 or ''
    perc=perc:gsub("%%","")
    perc=tonumber(perc)
    if perc then
      if W1=="raiddecay" then
        QDKP2_Decay("raid",perc)
      else
        QDKP2_Decay("guild",perc)
      end
    else
      QDKP2_CLI_ShowUsage("decay||raiddecay <%perc>")
    end
    return

  elseif W1=="getvalues" or W1=="getvalue" then
    W2=QDKP2_FormatName(W2)
    if QDKP2_IsInGuild(W2) then
      QDKP2_Msg(W2.." values:")
      QDKP2_Msg("Net="..tostring(QDKP2_GetNet(W2)).." DKP")
      QDKP2_Msg("Total="..tostring(QDKP2_GetTotal(W2)).." DKP")
      QDKP2_Msg("Spent="..tostring(QDKP2_GetSpent(W2)).." DKP")
      QDKP2_Msg("Time="..tostring(QDKP2_GetHours(W2)).." Hours")
    elseif #W2>0 then QDKP2_Msg(QDKP2_COLOR_RED.."No matching with that guildmember name.")
    else
      QDKP2_CLI_ShowUsage("getvalues <name>")
    end
    return

  elseif W1=="notify" then
    W2=QDKP2_FormatName(W2)
    if W2=="All" then
      QDKP2_NotifyAll()
    elseif QDKP2_IsInGuild(W2) then QDKP2_Notify(W2)
    elseif #W2>0 then QDKP2_Msg(QDKP2_COLOR_RED.."No matching with that guildmember name.")
    else
      QDKP2_CLI_ShowUsage("notify <name>|all")
    end
    return

  elseif W1=="charge" then
    if W2=="loot" then
      QDKP2_BIND_ChargeLastLoot()
    elseif W2=="chat" then
      QDKP2_BIND_ChargeLastSeen()
    else
      QDKP2_CLI_ShowUsage("charge loot|chat")
    end
    return

  elseif W1=="report" then
    if W2 and W3 and W4 then
      W2=QDKP2_FormatName(W2)
      local Target=W2
      if W2=="raid" then Target="RAID"
      elseif not IsInGuild(W2) then
        QDKP2_Msg(QDKP2_COLOR_RED.."No matching with that guildmember name.")
        return
      end
      local index=1
      local Loglist={}
      local Type
      if W3=="all" then
        Loglist=QDKP2log_ParsePlayerLog(W2)
        Type="Overview"
      elseif W3=="session" or W3=="current" then
        local Session=QDKP2_IsManagingSession()
        if not Session then
          QDKP2_Msg(QDKP2_COLOR_RED.."You haven't any active sessions.")
          return
        end
        local _,SessName=QDKP2_GetSessionInfo(Session)
        Type="Current session "..SessName
        Loglist=QDKP2log_GetPlayer(Session,W2)
      else
        QDKP2_Msg(QDKP2_COLOR_RED.."Wrong report Type.")
        return
      end
      if not Loglist or table.getn(Loglist)==0 then
        QDKP2_Msg(QDKP2_COLOR_RED.."Given player's log is empty.")
        return
      end
      local channel
      if W4=="say" or W4=="s" then channel="SAY"
      elseif W4=="yell" or W4=="y" then channel="YELL"
      elseif W4=="guild" or W4=="g" then channel="GUILD"
      elseif W4=="raid" or W4=="r" then channel="RAID"
      elseif W4=="officer" or W4=="o" then channel="OFFICER"
      elseif W4=="channel" then channel="CHANNEL"
      elseif W4=="whisper" or W4=="w" then channel="WHISPER"
      else
        QDKP2_Msg(QDKP2_COLOR_RED.."Wrong channel")
        return
      end
      if channel=="CHANNEL" and not W5 then
        QDKP2_Msg(QDKP2_COLOR_YELLOW.."You must include a channel name or number where you want to post the report into.")
        return
      end
      if channel=="WHISPER" and not W5 then
        QDKP2_Msg(QDKP2_COLOR_YELLOW.."You must include a player name you want to send the report to.")
        return
      end
      QDKP2_MakeAndSendReport(Loglist,Target,Type,channel,W5)
    else
      QDKP2_CLI_ShowUsage("report <name> all|session say|yell|guild|officer|channel|whisper [whispername|channelnumber]")
    end
    return

  elseif W1=="db" or W1=="database" then
    local DBguilds=ListFromDict(QDKP2_Data)
    for i=1,#DBguilds do if DBguilds[i]=="StoreVers" then table.remove(DBguilds,i); end; end
    if W2=="list" then
      QDKP2_Msg("List of realm-guilds currently stored in the Database:")
      for i=1,#DBguilds do
        local guildName=DBguilds[i]
        if guildName == QDKP2_DataLoaded then guildName=guildName.."*"; end
		QDKP2_Msg(tostring(i)..": "..tostring(guildName))
      end
      return

    elseif W2=="del" or W2=="delete" and W3 and tonumber(W3) then
      local GuildName=DBguilds[tonumber(W3)]
      if not GuildName then
        QDKP2_Msg('You must provide a valid database index. Type "/qdkp db list" to get a list.',"WARNING")
        QDKP2_CL_ProcessCommand("db list")
        return
      end
      if GuildName == QDKP2_DataLoaded then
        QDKP2_Msg('You cannot remove your current guild from the database! Use "/dkp wipe local" instead.',"WARNING")
        return
      end
      QDKP2_InitData(GuildName,true)
      QDKP2_Data[GuildName]=nil
      QDKP2_Msg('Guild "'..GuildName..'" removed from the database.',"INFO")
      return
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
     -- the data fields? Or i can leave it to the backup function. But i have to warn the user.

    else
      QDKP2_CLI_ShowUsage("db list|del <number>")
    end
    return

--[[  elseif W1=="key" or W1=="guildkey" then
    if not IsGuildLeader(UnitName("player")) then
      QDKP2_Msg("You must be the Guild Master to set up or remove the guild key.","ERROR")
    elseif W2=="new" or W2=="create"then
      QDKP2_Crypt_GenKey()
    elseif W2=="remove" or W2=="delete" then
      --clear the key
    else
      QDKP2_CLI_ShowUsage("guilkey create|remove")
    end
    return]]

  elseif W1=="rights" or W1=="checkright" or W1=="checkrights" then
    local M1,M2,M3 = QDKP2_GetPermissions()
    QDKP2_Msg(M1);QDKP2_Msg(M2);--QDKP2_Msg(M3)
    return

  elseif W1=="debug" then
    local switch=QDKP2_CLI_IsOnOff(W2)
    if switch==false then
      QDKP2_DEBUG=0
      QDKP2_Msg("Debug disabled")
    elseif switch==true then
      QDKP2_DEBUG=2
      QDKP2_Msg("Debug enabled. Level=2 (Full)")
    elseif W2=="verbose" then
      QDKP2_DEBUG=3
      QDKP2_Msg("Debug enabled. Level=3 (Verbose)")
    elseif W2=="error" or W2=="errors" then
      QDKP2_DEBUG=1
      QDKP2_Msg("Debug enabled. Level=1 (Errors)")
    elseif (W2=="set" or W2=="level") then
      local level=tonumber(W3)
      if level then
        QDKP2_DEBUG=tonumber(W3)
        QDKP2_Msg("Debug enabled. Level="..W3)
      else
        QDKP2_CLI_ShowUsage("debug set 1|2|3")
      end
    elseif W2=="filter" and W3 then
      local status=QDKP2_CLI_IsOnOff(W4)
      if status==nil then status=true; end
      if W3=="all" then
        QDKP2_Debug_FilterAll(status)
        if status then QDKP2_Msg("All debug filters active")
        else QDKP2_Msg("All debug filters removed")
        end
        return
      else
        local exist=QDKP2_Debug_SetFilter(W3,status)
        if not exist then QDKP2_Msg("Invalid subsystem","ERROR"); return; end
        if status then QDKP2_Msg('Activated filter on "'..W3..'" subsystem debug messages.')
        else QDKP2_Msg('Removed filter on "'..W3..'" subsystem debug messages.')
        end
        return
      end
    else
      QDKP2_CLI_ShowUsage("debug on|off|filter|clear [<system>|all|on|off]")
    end
    return


  elseif W1=="reset" or W1=="wipe" or W1=="clear" then
    if W2=="hours" then
      QDKP2_resetAllGuildHours()
    elseif W2=="log" then
      QDKP2log_PurgeWipe(true)
    elseif W2=="dkp" then
      QDKP2_resetDKPAmounts()
    elseif W2=="local" then
      QDKP2_resetAll()
    elseif W2=="all" then
      QDKP2_resetGuild()
    else
      QDKP2_CLI_ShowUsage("wipe hours|log|local|dkp|all")
    end
    QDKP2_Events:Fire("DATA_UPDATED","all")
    return


  elseif not W1 or W1=="" or W1=="help" or W1=="h" or W1=="?" then
    QDKP2_CLI_Help()
    return

  elseif W1=="makealt" then
    if W2 and W3 then
      W2=QDKP2_FormatName(W2)
      W3=QDKP2_FormatName(W3)
      if not QDKP2_IsInGuild(W2) then QDKP2_Msg(QDKP2_COLOR_RED..W2..': No matching with this guildmember name.')
      elseif not QDKP2_IsInGuild(W3) then QDKP2_Msg(QDKP2_COLOR_RED..W3..': No matching with this guildmember name.')
      elseif W2==W3 then QDKP2_Msg(QDKP2_COLOR_RED.."An alt's Main must be different from the alt himself.")
      elseif QDKP2_IsAlt(W3) then QDKP2_Msg(QDKP2_COLOR_RED.."You can't define an alt as a main.")
      else
        QDKP2altsRestore[W2]=W3
        QDKP2_DownloadGuild(nil,false)
        QDKP2_Events:Fire("DATA_UPDATED","toolbox")
        QDKP2_Events:Fire("DATA_UPDATED","roster")
        QDKP2_Msg(QDKP2_COLOR_WHITE.."Upload Changes to store the modifications.")
      end
    else
      QDKP2_CLI_ShowUsage("makealt <altName> <mainName>")
    end
    return

  elseif W1=="clearalt" then
    if W2 then
      W2=QDKP2_FormatName(W2)
      if not QDKP2_IsInGuild(W2) then QDKP2_Msg(QDKP2_COLOR_RED..'No matching with that guildmember name.')
      elseif not QDKP2_IsAlt(W2) then QDKP2_Msg(QDKP2_COLOR_RED.."That player is not an alt.")
      else
        QDKP2altsRestore[W2]=""
        QDKP2alts[W2]=nil
        QDKP2_DownloadGuild(nil,false)
        QDKP2_Events:Fire("DATA_UPDATED","toolbox")
        QDKP2_Events:Fire("DATA_UPDATED","roster")
        QDKP2_Msg(QDKP2_COLOR_WHITE.."Upload Changes to store the modifications.")
      end
    else
      QDKP2_CLI_ShowUsage("clearalt <altName>")
    end
    return

  elseif W1=="external" then
    if W2=="list" then
      local list=ListFromDict(QDKP2externals)
      if #list==0 then
        QDKP2_Msg("No external has been added to the guild roster.")
      else
        QDKP2_Msg("Externals currently in the guild roster:")
        for i=1,#list do QDKP2_Msg(list[i]); end
      end
      return
    elseif W2=="add" and W3 then
      W3=QDKP2_FormatName(W3)
      if not QDKP2_NewExternal(W3) then QDKP2_Msg("Couldn't add "..W3.." to the guild roster.","ERROR"); return; end
    elseif W2=="remove" and W3 then
      W3=QDKP2_FormatName(W3)
      if not QDKP2_DelExternal(W3) then return; end
    else
      QDKP2_CLI_ShowUsage("external add||remove|list <name>")
      return
    end
    QDKP2_DownloadGuild(nil,false)
    QDKP2_UpdateRaid()
    QDKP2_Events:Fire("DATA_UPDATED","roster")
    return


  elseif W1=="standby" then
    if W2=="list" then
      if #QDKP2standby==0 then
        QDKP2_Msg("No players added to the raid roster as standby at the moment.")
      else
        QDKP2_Msg("Players added to the current raid roster as standby:")
        for i=1,#QDKP2standby do QDKP2_Msg(QDKP2standby[i]); end
      end
      return
    elseif W2=="add" and W3 then
      W3=QDKP2_FormatName(W3)
      if not W3 then QDKP2_Msg('You must specify the name of a guild member.'); return
      elseif not QDKP2_IsInGuild(W3) then QDKP2_Msg('The given player is not in the Guild',"ERROR"); return
      elseif QDKP2_IsInRaid(W3) then QDKP2_Msg('The given player is already in the Raid',"WARNING"); return
      elseif QDKP2_AddStandby(W3) then QDKP2_Msg(W3.." added to the raid")
      else QDKP2_Msg("Couldn't add "..W3.." to the raid roster.","ERROR"); return
      end
    elseif W2=="remove" and W3 then
      W3=QDKP2_FormatName(W3)
      if not W3 then QDKP2_Msg('You must specify the name of a guild member.'); return
      elseif not QDKP2_IsStandby(W3) then QDKP2_Msg(W3.." is not a standby member.","WARNING")
      elseif QDKP2_RemStandby(W3) then QDKP2_Msg(W3.." removed from the raid")
      else QDKP2_Msg("Couldn't remove "..W3.." to the raid roster.","ERROR"); return
      end
    else
      QDKP2_CLI_ShowUsage("standby add||remove|list <name>")
      return
    end
    QDKP2_Events:Fire("DATA_UPDATED","roster")
    QDKP2_Events:Fire("DATA_UPDATED","log")
    return

  elseif W1=="classdkp" then
    if W2 and W3 then
      local class
      local origClass=W2
      W2=QDKP2classEnglish[QDKP2_FormatName(W2)] or W2
      W2=string.lower(W2)
      if W2=="druid" then class=W2
      elseif W2=="hunter" then class=W2
      elseif W2=="mage" then class=W2
      elseif W2=="paladin" then class=W2
      elseif W2=="priest" then class=W2
      elseif W2=="rogue" then class=W2
      elseif W2=="shaman" then class=W2
      elseif W2=="warlock" then class=W2
      elseif W2=="warrior" then class=W2
      elseif W2=="dk" or W2=="death knight" then
        class="death knight"
      else
        QDKP2_Msg('You have to specify a valid class name.',"ERROR")
        return
      end
      local output={"QDKP2 - Top DKP players for "..origClass.." class:"}
      local list={}
      for i = 1,table.getn(QDKP2name) do
        local name=QDKP2name[i]
        local classAct=QDKP2classEnglish[QDKP2class[name]] or QDKP2class[name]
        if string.lower(classAct)==class then
          table.insert(list,name)
        end
      end
      if table.getn(list)==0 then
        QDKP2_Msg('No Guild Members for the given class',"WARNING")
        return
      end
      QDKP2_netSort(list)
      for i=1,table.getn(list) do
        if i > 10 then break; end
        local name=list[i]
        local DKP=QDKP2_GetNet(name)
        table.insert(output,QDKP2_GetName(name)..": "..tostring(DKP).." DKP")
      end
      local channel
      if W3=="say" or W3=="s" then channel="SAY"
      elseif W3=="yell" or W3=="y" then channel="YELL"
      elseif W3=="guild" or W3=="g" then channel="GUILD"
      elseif W3=="officer" or W3=="o" then channel="OFFICER"
      elseif W3=="channel" then channel="CHANNEL"
      elseif W4=="raid" or W4=="r" then channel="RAID"
      elseif W3=="whisper" or W3=="w" then channel="WHISPER"
      else
        QDKP2_Msg("Wrong channel","ERROR")
        return
      end
      if channel=="CHANNEL" and not W4 then
        QDKP2_Msg("You must include a channel name or number where you want to post the report into.","WARNING")
        return
      end
      if channel=="WHISPER" and not W4 then
        QDKP2_Msg("You must include a player name you want to send the report to.","WARNING")
        return
      end
      QDKP2_SendList(output,channel,W4)
    else
      QDKP2_CLI_ShowUsage('classdkp <class> say|yell|guild|officer|channel|whisper')
    end
    return

  elseif W1=="rankdkp" then
    if W2 and W3 then
      local output={"QDKP2 - Top DKP players for "..W2.."rank:"}
      local list={}
      for i = 1,table.getn(QDKP2name) do
        local name=QDKP2name[i]
        local rankAct=string.lower(QDKP2rank[name])
        if rankAct==W2 then
          table.insert(list,name)
        end
      end
      if table.getn(list)==0 then
        QDKP2_Msg(QDKP2_COLOR_RED.."No Guild Members for the given rank")
        return
      end
      QDKP2_netSort(list)
      for i=1,table.getn(list) do
        if i > 10 then break; end
        local name=list[i]
        local DKP=QDKP2_GetNet(name)
        table.insert(output,QDKP2_GetName(name)..": "..tostring(DKP).." DKP")
      end
      local channel
      if W3=="say" or W3=="s" then channel="SAY"
      elseif W3=="yell" or W3=="y" then channel="YELL"
      elseif W3=="guild" or W3=="g" then channel="GUILD"
      elseif W3=="officer" or W3=="o" then channel="OFFICER"
      elseif W3=="channel" then channel="CHANNEL"
      elseif W4=="raid" or W4=="r" then channel="RAID"
      elseif W3=="whisper" or W3=="w" then channel="WHISPER"
      else
        QDKP2_Msg("Wrong channel","ERROR")
        return
      end
      if channel=="CHANNEL" and not W4 then
        QDKP2_Msg("You must include a channel name or number where you want to post the report into.","WARNING")
        return
      end
      if channel=="WHISPER" and not W4 then
        QDKP2_Msg("You must include a player name you want to send the report to.","WARNING")
        return
      end
      QDKP2_SendList(output,channel,W4)
      return
    else
      QDKP2_CLI_ShowUsage("classdkp <class> say|yell|guild|officer|channel|whisper")
      return
    end

  elseif W1=="bid" then
    if not QDKP2_OfficerMode then
      QDKP2_Msg("Only DKP officers can use this feature.")
    elseif W2=="new" then
      local item=text:sub(9)
      if #item==0 then item=nil; end
      QDKP2_BidM_StartBid(item)
    elseif W2=="stop" or W2=="finish" then
      if not QDKP2_BidM_isBidding() then
        QDKP2_Msg("There is not an ongoing bidding!")
        return
      end
      QDKP2_BidM_CloseBid()
    elseif W2=="cancel" then
      if not QDKP2_BidM_isBidding() then
        QDKP2_Msg("There is not an ongoing bidding!")
        return
      end
      QDKP2_BidM_CancelBid()
    elseif w2=="reset" or W2=="clear" then
      QDKP2_BidM_Reset()
    elseif W2=="countdown" then
      QDKP2_BidM_Countdown()
    elseif W2=="list" then
      QDKP2_Msg('Bidders list')
      for name,bid in pairs(QDKP2_BidM.LIST) do
        QDKP2_Msg(tostring(name)..' bid='..tostring(bid.txt)..' value='..tostring(bid.value)..' roll='..tostring(bid.roll or ''))
      end
    elseif W2=="win" or W2=="winner" then
      if W3 then
        local player=QDKP2_FormatName(W3)
        local winner=QDKP2_BidM.LIST[player]
        if winner then
          QDKP2_BidM_Winner(player)
        else
          QDKP2_Msg(player.." is not a valid bidder name. use /dkp bid list to get a list of current bidders.")
        end
      else
        QDKP2_CLI_ShowUsage("bid win <winner name>")
      end
    else
      QDKP2_CLI_ShowUsage("bid new|cancel|win|clear|countdown")
    end
    return
  end
  QDKP2_Msg('Wrong command. Enter "/qdkp help" to see the commands list.',"ERROR")
end

function QDKP2_CLI_Help()
  QDKP2_Msg("Quick DKP V"..QDKP2_VERSION)
  if QDKP2_OfficerMode() then
    QDKP2_Msg(QDKP2_COLOR_GREEN.."Officer mode")
  else
    QDKP2_Msg("View-only mode")
  end
  QDKP2_Msg("USE /qdkp2 or /qdkp or /dkp and one of these commands:")
  QDKP2_Msg("-------------------------")
  QDKP2_Msg("gui [show||toggle||hide]")
  QDKP2_Msg("roster [show||toggle||hide]")
  QDKP2_Msg("log [show||toggle||hide]")
  QDKP2_Msg("toolbox [show||toggle||hide]")
  QDKP2_Msg("showlog <player>||raid")
  QDKP2_Msg("showtoolbox <player>")
  QDKP2_Msg("getvalues <player>")
  QDKP2_Msg("db list|del <code>")
  QDKP2_Msg("debug off|errors|on|verbose")
  QDKP2_Msg("debug filter <system>|all on|off")
  QDKP2_Msg("wipe hours|dkp|log|all")
  QDKP2_Msg("checkrights")
  QDKP2_Msg("notify <player>|all")
  QDKP2_Msg("report <player>||raid all|session say|yell|guild|officer||raid|channel|whisper [whispername|channelnumber]")
  QDKP2_Msg("classdkp <class> say|yell|guild|officer||raid|channel|whisper [whispername|channelnumber]")
  QDKP2_Msg("rankdkp <class> say|yell|guild|officer||raid|channel|whisper [whispername|channelnumber]")
  if QDKP2_OfficerMode() then
    --QDKP2_Msg("guildkey create|remove")
    QDKP2_Msg("newsession [<sessionname>]")
    QDKP2_Msg("endsession")
    QDKP2_Msg("upload")
    QDKP2_Msg("timer on|off")
    QDKP2_Msg("ironman on|off|wipe [<dkp>]")
    QDKP2_Msg("autoboss on||toggle|off")
    QDKP2_Msg("detectwin on||toggle|off")
    QDKP2_Msg("raidaward <dkp> [for <reason]")
    QDKP2_Msg("do <player> spend|award|zerosum <dkp> [for <reason>]")
    QDKP2_Msg("set <player> total|spent||ours <amount>")
    QDKP2_Msg("decay <amount%>")
    QDKP2_Msg("raiddecay <amount%>")
    QDKP2_Msg("charge loot|chat")
    QDKP2_Msg("makealt <altName> <mainName>")
    QDKP2_Msg("clearalt <altName>")
    QDKP2_Msg("external add||remove|list [<name>]")
    QDKP2_Msg("standby add||remove|list [<name>]")
    QDKP2_Msg("bid new [<item or reason>]")
    QDKP2_Msg("bid stop|cancel|clear|list|countdown")
    QDKP2_Msg("bid win <number>")
  end
  QDKP2_Msg("------------------------")
  QDKP2_Msg("text inside [] means optional argument, | means multiple choice.")
  QDKP2_Msg("For more info read the mod's manual")
end


------- MISC FUNCTIONS ----------------

--[[
function QDKP2_CL_WordParser(text)
  local start=1
  local output={}
  for i=1,string.len(text) do
    if string.sub(text,i,i)==" " then
      table.insert(output,string.lower(string.sub(text,start,i-1)))
      start=i+1
    end
  end
  table.insert(output,string.lower(string.sub(text,start,string.len(text))))
  return output
end
]]--

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
  QDKP2_RSA={}
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
  if word=="on" or word=="yes" or word=="y" or word=="show" or word=="1" or word=="activate" or word=="active" or word=="start" then return true
  elseif word=="off" or word=="no" or word=="n" or word=="hide" or word=="0" or word=="deactivate" or word=="deactive" or word=="stop" then return false
  end
end

function QDKP2_CLI_ShowUsage(usage)
  QDKP2_Msg('Wrong syntax.',"ERROR")
  QDKP2_Msg('Usage: "/qdkp '..usage..'"',"WARNING")
end

function QDKP2_NeedGUI()
  QDKP2_Msg('You need to enable "Quick DKP V2 - GUI" addon to use this feature.','ERROR')
end

