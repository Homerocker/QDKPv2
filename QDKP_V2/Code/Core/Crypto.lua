-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## RSA ENCRYPTION ##
--
-- This file is an interface to the LibRSA library. Basically, it manages the keys and provides an entropy source for the key generator.
--
-- API Documentation:
-- QDKP2_Crypt_Sign(text): Returns a signature for the given text. Returns nil if you have not the public/private key.
-- QDKP2_Crypt_Verify(text,sign): Returns true if sign is correct with the current key. returns nil if you have not the public key
-- QDKP2_Crypt_GenKey(string): Calculates a new key pair. Displays a dialog with a button to be clicked to improve randomness
-- QDKP2_Crypt_GotPubKey(): Returns true if you have the public key
-- QDKP2_Crypt_GotPrivKey(): Return true if you have a valid public/private key pair.




function QDKP2_Crypt_Sign(text)
	if not QDKP2_Crypt.PubKey then
		QDKP2_Debug(1,"Core","Trying to sign stuff but you have not even the public key")
		return
	end
	if not QDKP2_Crypt.PrivKey then
		QDKP2_Debug(1,"Core","Trying to sign stuff but you have not the private key")
		return
	end

	return QDKP2libs.RSA:Sign(text,QDKP2_Crypt.PubKey,QDKP2_Crypt.PrivKey)
end

function QDKP2_Crypt_Verify(text,sign)
	if not QDKP2_Crypt.PubKey then
		QDKP2_Debug(1,"Core","You are trying to verify a sign but you have not the public key")
		return
	end

	return QDKP2libs.RSA:VerifySign(text,sign,QDKP2_Crypt.PubKey)
end

function QDKP2_Crypt_GotPubKey()
	return QDKP2_Crypt.PubKey
end

function QDKP2_Crypt_GotPrivKey()
	if not QDKP2_Crypt.PubKey then return; end
	if not QDKP2_Crypt.PrivKey then return; end
	return QDKP2libs.RSA:CheckKeyPair(QDKP2_Crypt.PubKey,QDKP2_Crypt.PrivKey)
end



------------------------- KEY GENERATION ---------------------------

---locales

local function ContinueMakingKey()
	if InCombatLockdown() then return; end --we don't want the game to be choppy while on combat
	local PubKey,PrivKey=QDKP2libs.RSA:GenKeyCont(QDKP2_Crypt_KeyGenObj)
	if PubKey then
		QDKP2_Crypt.PubKey=PubKey
		QDKP2_Crypt.PrivKey=PrivKey
    local time_sec=time() - QDKP2_Crypt_KeyGenObj.startime
		QDKP2_Msg("The new key pair has been successfully built in "..tostring(time_sec).." seconds.")
		QDKP2libs.Timer:CancelTimer(QDKP2_Crypt_KeyGenTimerStep)
		QDKP2_Crypt_GenKeyCount=nil
	else
		QDKP2_Crypt_GenKeyCount=QDKP2_Crypt_GenKeyCount+1
	end
end

local function StartMakingKey(entr)
	QDKP2_Msg("The key will be built in the background while you are out of combat. It will take about 2-3 minutes.")
	QDKP2_Crypt_KeyGenObj=QDKP2libs.RSA:GenKeyAsync(entr)
	QDKP2_Crypt_GenKeyCount=0
  QDKP2_Crypt_KeyGenObj.startime=time()
	QDKP2_Crypt_KeyGenTimerStep=QDKP2libs.Timer:ScheduleRepeatingTimer(ContinueMakingKey, 1)
end

local function GetEntropy()
	if not QDKP2_Crypt_GenKeyCount then
		QDKP2_Msg("QDKP will get the entropy it needs to build the key from your mouse movements. Please move it now.")
		QDKP2_Crypt_GenKeyCount=0
		QDKP2_Crypt_GenKeyBuffer=""
		QDKP2_Crypt_GenKeyOldX=0
		QDKP2_Crypt_GenKeyOldY=0
		QDKP2_Crypt_KeyGenTimerEntr=QDKP2libs.Timer:ScheduleRepeatingTimer(GetEntropy,1)
	end

	if QDKP2_Crypt_GenKeyCount<8 then
		c_x,c_y=GetCursorPosition()
		if c_x ~= QDKP2_Crypt_GenKeyOldX and c_y ~= QDKP2_Crypt_GenKeyOldY then
      local ent=QDKP2libs.RSA:GetWoWEntropy()
			QDKP2_Crypt_GenKeyBuffer=QDKP2_Crypt_GenKeyBuffer..ent
			QDKP2_Crypt_GenKeyOldX=c_x; QDKP2_Crypt_GenKeyOldY=c_y
			QDKP2_Crypt_GenKeyCount=QDKP2_Crypt_GenKeyCount+1
		else
			QDKP2_Debug(2,"Core","Entropy sample discarded: the cursor didn't move.")
		end
	else
		StartMakingKey(QDKP2_Crypt_GenKeyBuffer)
		QDKP2libs.Timer:CancelTimer(QDKP2_Crypt_KeyGenTimerEntr)
	end
end

function QDKP2_Crypt_GenKey(proceed)
	if QDKP2_Crypt_GenKeyCount then return; end
  if not IsGuildLeader(UnitName("player")) and false then
    QDKP2_Msg("You must be the Guild Master to set up or remove the guild key.","ERROR")
    return
  end
	if not proceed then
		QDKP2_AskUser("You are about to build a new key pair.\n"..
                  "This will enforce DKP officer permissions,\n"..
                  "but they won't be able to edit DKP until\n"..
                  "they log while you are online.\n"..
                  "Are you sure you want to proceed?",
    QDKP2_Crypt_GenKey,true)
		return
	end
	GetEntropy()
	return
end


