-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--           Notes reading and writing
--
--      Functions to read/write data from/to the officier(public) notes.
--
--  API Documentation:
-- QDKP2_MakeNote(net,total,spent,hours): Creates the note text with the given data, using the format type in QDKP2_outputstyle
-- QDKP2_ParseNote(incParse): Returns net, total, spent (dkp) and time (hours) parsing the given note. returns 0 for everything on error or undefinited.
-- QDKP2_FirstWord(str): Returns the first word of str, to check for alts.
-- QDKP2_GetMaximumFieldNumber(): Returns the maximum number it can be stored in the officer notes with the ongoing settings.


-------------------------- LOCALS ----------------------------------

local function ExtractNum(str, keys)

  local i1, i2, tmpstr, value, key

  for j=1, table.getn(keys) do
    key=keys[j]
  -- find key voice
    i1, i2 = string.find(str, key..QDKP2_NOTE_DASH.."[^%d]*")
    if i1 and i2 then
      i1, i2 = string.find(str, "[%d.]*", i2+1)        -- find digits
      if (i1 == nil or i2 == nil or i2 < i1) then break; end   --control #1
      tmpstr = string.sub(str, i1, i2)
      value = tonumber(tmpstr)
      if not value then return; end
      if (i1 > 1) then
        if (string.sub(str, i1-1, i1-1) == "-") then value = 0 - value; end    -- check for negatives
      end
      break
    end
  end
  return value
end
----------------------------------------------------------------------

function QDKP2_MakeNote(incNet, incTotal, incSpent, incHours)
--puts the data back into a note

  incNet=RoundNum(incNet)
  incTotal=RoundNum(incTotal)
  incSpent=RoundNum(incSpent)
  incHours=RoundNum(incHours*10)/10

  local out=''
  local netLabel='Net'
  local optLabel, optValue='Tot', incTotal
  local hrsLabel='Hrs'
  if QDKP2_TotalOrSpent==2 then
    optLabel = 'Spt'
    optValue = incSpent
  end
  if QDKP2_CompactNoteMode then
    netLabel='N'
    hrsLabel='H'
    optLabel=string.sub(optLabel,1,1)
  end

  local limitMax,limitMin=QDKP2_GetMaximumFieldNumber()
  if incNet>limitMax then incNet=limitMax
  elseif incNet<limitMin then incNet=limitMin
  end
  if optValue>limitMax then optValue=limitMax
  elseif optValue<limitMin then optValue=limitMin
  end
  if incHours>999.9 then incHours='999.9'
  elseif incHours<0 then incHours='0'
  end

  local out=netLabel..QDKP2_NOTE_DASH..tostring(incNet)..QDKP2_NOTE_BREAK..optLabel..QDKP2_NOTE_DASH..tostring(optValue)
  if QDKP2_StoreHours then
    out=out..QDKP2_NOTE_BREAK..hrsLabel..QDKP2_NOTE_DASH..tostring(incHours)
  end
  return out
end

function QDKP2_GetMaximumFieldNumber()
  if QDKP2_CompactNoteMode and not QDKP2_StoreHours then
    return 999999999999,-99999999999
  elseif QDKP2_CompactNoteMode and QDKP2_StoreHours then
    return 99999999,-9999999
  elseif not QDKP2_CompactNoteMode and not QDKP2_StoreHours then
    return 9999999999,-999999999
  else
    return 999999,-99999
  end
end


function QDKP2_ParseNote(incParse)
-- Given string str, find and return net,total,spent,hours
-- returns 0 on not found.
-- does NOT rely on outputformat for the parsing.

  local nettemp=0
  local spenttemp=0
  local totaltemp=0
  local hourstemp=0

  nettemp   = ExtractNum(incParse, {"Net", "DKP", "N"})     -- Net is any number following n=, net=
  totaltemp = ExtractNum(incParse, {"Total","Tot","T","G"}) -- Total is any number following g=, t=, tot=, total=
  spenttemp = ExtractNum(incParse, {"Spent", "Spt","S"})   -- Spent is any number following s=,spt=,spent=
  hourstemp = ExtractNum(incParse, {"Hours","Hrs","H"})   -- Hours is any number following hours=, hrs=, h=

  --if there isn't any compatible QDKP2 text in the note, return all 0
  if not spenttemp and not totaltemp and not nettemp then
    nettemp=0
    totaltemp=0
    spenttemp=0
  end

  --this is to fix output format with only NET field (DKP:xx)
  if not spenttemp and not totaltemp then
    totaltemp=nettemp
  end

  --this is to fix output format with only total
  if not nettemp and not spenttemp then
    nettemp=totaltemp
  end

  --this is to fix output formats with only spent (????)
  if not nettemp and not totaltemp then
    totaltemp=spenttemp
  end

  --fixups for empty fields
  nettemp=nettemp or totaltemp - spenttemp
  spenttemp=spenttemp or totaltemp - nettemp
  totaltemp=totaltemp or nettemp + spenttemp
  hourstemp=hourstemp or 0

  return nettemp, totaltemp, spenttemp, hourstemp
end


function QDKP2_FirstWord(str)
--Returns the first word of str, to check for alts.
   if str == nil then
      str = ""
   end
   local first = string.sub(str, 1,1)
   local fin = string.find(str, " ") or (string.len(str) + 1)
   local remainder = string.sub(str, 2, fin - 1)
   local output = string.upper(first)..string.lower(remainder)

   if (QDKP2_AutoLinkAlts == false) then
      return "---"  -- will not ever match a guild member name, so won't be linked
   else
      return output
   end

   return output
end




