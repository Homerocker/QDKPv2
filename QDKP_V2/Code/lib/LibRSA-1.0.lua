--[[
Copyright 2010 Riccardo Belloli-Ballanzone of EU crushridge(contact@belloli.net) and Martin Huesser

LibRSA 1.0.1

This library is written for WoW and implements a pure LUA RSA-like asymmetrical algorythm to sign/verify any
random string of any size. Has a limited support to crypt/decrypt strings, processing them in blocks
of up to 12 characters.
Has a built in function that creates a key pair of 128 bit, but the lib itself can use keys of any size.
Uses SHA1 as hashing algorythm for signing purpose

Since this is a pure LUA implementation, it has some heavy handicaps, the first and most important being
the key lenght of the built in generator, which brings some obivious strengh limitation.
The other limit is speed: the signing and decryption functions are very costly, using about 80-100 ms of full CPU
time on an average processor for each operation (this with a 128 bit key, using a bigger key will increase the time).
The key verification and the encrypt is much less cpu consuming, about 1-2 ms for each operation.

SHA1 needs the bitlib (included in the standard WoW implementation) to be usable in a real life scenarios.

Includes BigInt and Sha1, both libraries by Martin Huesser

You can find the latest version of this library on Curse.com
Last working link:

This library is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Please read Martin Huesser comments hereunder for his own code's licensing policy.


Library Documentation:
Unless otherwise indicated, all "text" label is supposed to be a string, all keys are in the BigInt format, and the
crypted text (this includes the sign) is in an armored and print-friendly 7bit ascii text.

* PubKey, PrivKey = LibRSA:GenKeyNow(randomtext)
	Creates a new key pair. you must give a random text to be used as seed. Will freeze your pc for some seconds.
	This WILL disconnect the user if he attempts to calculate the key in hi-traffic situations. (read: in cities or in raid)
	The PubKey is not the RSA pubkey: includes the RSA modulus and RSA pubkey.
	The key format is bigint(a list of numbers). use LibRSA:Armor(key) to convert it to a printable/sendable string.
	<randomtext> must be a string, and is used as seed to calculate the key. please keep in mind that no further entropy is
	added to the string: calculating two keys with same randomtext given will produce two identical key pairs.
	It's raccomanded to use the player as entropy source. You can use anything, from characters, to mouseclicks, to event etc.
	Just make sure that the stuff you use is not sniffable by other players, like in-game position. See GetWoWEntropy.

* LibRSA:GenKeyAsync(randomtext):
	Same as above, but returns immediately a KeyObj table that you can use in the LibRSA:ContinueMakingKey(KeyObj),
	which you have to call over and over on a timed basis (eg: AceTimer) until it returns PubKey,PrivKey.
	Calculating the key will need an average of
	If you don't use timed calls, but instead put it in a loop untill the key is calculated (which is
	what the GenKeyNow function does), you risk to get the user disconnected if he attempts to
	build the key pair in high crowded places such as major cities.

* LibRSA:GenKeyCont(keyobj)
	A step to calculate the key in async mode. You must pass the keyobj generated with the original GenKeyAsync.
	returns nil normally, and returns PubKey,PrivKey when the keys has been succesfully generated.
	Generating a key will need about 4000 calls to this function, which takes about 1 millisecond to execute on a
	average CPU.
	See the examples under for a template to use this function

* LibRSA:GetWoWEntropy()
	Returns a string with some random-based data gathered from the WoW API and from the user.
	it uses the cursor position, latency, bandwidth and framerate.
	Please keep in mind that a single call to this function does not give enought entropy to generate a
	good quality key. You'll have to give additional randomness, both by asking the user for random strings,
	by making him move the mouse, acquiring events etc.

* LibRSA:CheckKeyPair(pubkey,privkey): returns true if the given arguments are a valid and working key pair.
			This is a protected function: you can pass the data you got from untrusted sources with no security issue.
			returns nil on invalid input.

* LibRSA:Sign(text,pubKey,privKey):
	Signs the given text with the given key pair. Requires the private key.
	text can be a string of any size and with any character.
	returns a printable string as returned by LibRSA:Armor()

* LibRSA:SignAsync(text,pubKey,privKey):
	As said, the Sign functioln will take about 100ms of full CPU time. during that time, the game will freeze, and the
	the game will show (expecially on high-framerate situation) a noticeable glitch.
	If the sign is a one-time, one-packet process, this is accettable. if you need to sign a large amount of strings, or
	you plan to sign on a regular basis, then you need a async signing system.
	Call this function once. it will return immediately a table object that you have to keep for futher operations.
	This function is also useful if you are using a large key, and signing anything in the blocking mode would freeze
	the game for an unaccetable time even for a one-time one-string event only.

* LibRSA:SignAsyncCont(SignObj)
	Call this function to continue the signing. Give the table object you got from SignAsync. Normally, it
	will return nil. Returns the signature when the calculation is done.
	Signing a string with a regular 128 bit key will need about 100 calls to this function, which takes about 1 millisecond
	of cpu time to complete on a average processor.

* LibRSA:VerifySign(text,sign,pubKey):
	Validates the segnature for the given text and key. returns true if successful, nil if not.

* LibRSA:Crypt(text,pubKey):
	Crypts the given text. returning an armored printable string.
	PLEASE NOTE: This function crypts block of 12 characters. The crypt operation is quite fast but remember that, when the text
	will be decrypted, it will need about 50 ms for every of those packets..
	Also, if you crypt two strings that differs only for one byte, only the relative 12-byte section of the crypted code will be different.
	For the above limitation, you should only use this function for authoriting or for key exchange.

* LibRSA:Decrypt(crypt,pubKey,privKey):
	Decrypt a previously encrypted text. Requires the private key.

* LibRSA:Armor(bigint)  converts the given bigint table (eg: keys) to a printable 7bit ascii text.
* LibRSA:Dearmor(string) convert the given armored text in its bigint representation. returns nil if any inval[id character is found.
			This is a protected function: you can pass the data you got from untrusted sources with no security issue.

* LibRSA:Digest(text): Retruns a 96bit truncation of the sha1 digest algorythm, as hexadecimal number (string)
* LibRSA:Calculate_SHA1(text): Returns the full output (160 bit) of the sha1 digest algorythm, as hexadecimal number (string).

* LibRSA.BigInt : This is the bigint library. check the code for its own documentation.

EXAMPLES:

	--Example code to build a new key pair, blocking mode:
	local user_text = ""
	while #user_text < 20 do  --we want the random pattern to be at least 20 characters
 	  user_text = MyAddon:PromptUser("Please roll your face on the keyboard and press enter (20 chars min)") --PromptUser is not included in this library :-)
	end
	local random_wow_data = LibRSA:GetWoWEntropy()   --gets entropy from the wow client (this includes the net statistics, framerate, position of your gear in the inventory etc.)
	MyAddon.PubKey,MyAddon.PrivKey = LibRSA:GenKeyNow(user_text .. random_wow_data) -- calculate the key pair with the two strings chained as seed.
	MyAddon.PubKeyTransmit=LibRSA:Armor(MyAddon.PubKey) -- convert the bigint format of the pubkey to a 7bit ascii representation of the number, to be sent or pubblished.

  --Example code to build a new key pair in not-blocking mode (async)
		local user_random = MyAddon:GetUserEntropy() -- this must return a string with random data supplyed by the user. strings, timed mouseclicks... anything will do it.
		local client_random = LibRSA:GetWoWEntropy() -- some entropy gathered from the client
		local KeyObj = MyAddon:GenKeyAsync(user_random .. client_random)
		--this assumes you mixed in AceTimer in your addon. You can use any type of timed callback.
		--you can tweak the CPU usage by increasing the time between calls (1 sec in this example)
		local KeyTimer = MyAddon:ScheduleRepeatingTimer( function(KeyObj)
			local PubKey,PrivKey=LibRSA:GenKeyCont(KeyObj)  --Step to build the key
			if PubKey then                                                            --if the key has been calculated
				MyAddon.NewPubKey, MyAddon.NewPrivKey = PubKey, PrivKey  --store it somewere
				MyAddon:CancelTimer(KeyTimer,true)     --and stop the timed callback
			end
		end, 1)


	--import a foreign key
	--in the example, the armored public key I just received by SendName is in the variable ReceivedPubKey
  --Remember: You must be sure to receive the key from a trusted source, ideally from the key owner itself. Failing to do so
  --expones yourself to man-in-the-middle attacks.

	local PubKey=LibRSA:Dearmor(ReceivedPubKey)  --convert it back in the bigint format
	MyAddon.PubKeyring[SendName]=PubKey --It's a good idea to store the keys you receive in a common place. Keyring is a good name for that.


	--Use a public key to verify a signed message you just received
	--the message is stored in the var MsgTxt, the sign in MsgSign, and it is claimed to be signed by MsgOwner

	local Key=MyAddon.PubKeyring[MsgOwner]  --assuming you put your known keys in this list, then try to retrive the one you need
	if not Key then			--if you don't have it, then you can't verify anything. raise an error.
		error "you need "..MsgOwner.."'s public RSA key to be able to verify his signature."
	end
	return LibRSA:VerifySign(MsgTxt,MsgSign,Key)  --if you have it, return the result of the verification.

]]


local MAJOR, MINOR = "LibRSA-1.0", 1
local LibRSA,oldminor = LibStub:NewLibrary(MAJOR, MINOR)

--LibRSA={}
if not LibRSA then return; end


function LibRSA:GetCPUSpeed()
--subroutine to figure out your PC raw flops.
	local i=0
	local t=GetTime()
	while i<5000000 do
		i=i+1
	end
	return 5000000/(GetTime()-t)
end

LibRSA.CPUSpeed=LibRSA:GetCPUSpeed()

------------------------------LOCAL FUNCTIONS------------------------



local function isPrime(n,steps,divisor)
-- timed research of prime numbers.
-- does <steps>.
-- returns isPrime,remaningSteps
-- isPrime is true if found so, false if found not. in those case, remaningSteps hold the steps that are left.
-- if steps run off while checking, returns steps=0 and isPrime is the divisor to start over.
	steps=steps or -1
  local c=divisor or 3
  local tresh=math.sqrt(n) --once you check till the square root you're done.
  while c <= tresh do
    if n % c == 0 then
      return false,steps
    end
		c=c+2; steps=steps-1
		if steps==0 then return c,steps; end
  end
  return true,steps
end


local function FindE(phi) -- Finds a number < phi and prime with phi.
  local resto={0}
  local n=1
  local r
  while #resto==1 and resto[1]==0 do
    n=n+1
    if isPrime(n) then
      r,resto=LibRSA.BigInt:Div(phi,{n})
    end
  end
  return n
end


local function DoFindD(u,u_s,v,v_s,q,q_s)
  local m=LibRSA.BigInt:Mul(q,v)
  local m_s=q_s*v_s
  local invert=LibRSA.BigInt:isGreater(m,u)
  local t,t_s
  if invert then
    t_s=m_s*-1
    if m_s==u_s then t=LibRSA.BigInt:Sub(m,u)  -- (+5) - (+10) = -5 | (-5) - (-10)  = 5 OK
    else t=LibRSA.BigInt:Add(u,m)              -- (+5) - (-10) = +15| (-5) - (+10) = -15 OK
    end
  else
    t_s=u_s
    if m_s==u_s then t=LibRSA.BigInt:Sub(u,m)  -- (+10) - (+5) = +5 | (-10) - (-5) = -5 OK
    else t=LibRSA.BigInt:Add(u,m)              -- (+10) - (-5) = +15| (-10) - (+5) = -15 OK
    end
  end
  return t, t_s
end

local function FindD(n,m) -- Extendend Euclidean algorythm. Finds the multiplicative inverse of n mod m.
  local u1 = {1}
  local u2 = {0}
  local u3 = m
  local v1 = {0}
  local v2 = {1}
  local v3 = {n}
  local u1_s,u2_s,u3_s,v1_s,v2_s,v3_s=1,1,1,1,1,1
  while #v3>1 or v3[1] ~= 0 do
    local q = LibRSA.BigInt:Div(u3,v3)
    local q_s=u3_s*v3_s
    local t1,t1_s=DoFindD(u1,u1_s,v1,v1_s,q,q_s)
    local t2,t2_s=DoFindD(u2,u2_s,v2,v2_s,q,q_s)
    local t3,t3_s=DoFindD(u3,u3_s,v3,v3_s,q,q_s)

    u1 = v1; u1_s=v1_s
    u2 = v2; u2_s=v2_s
    u3 = v3; u3_s=v3_s

    v1 = t1; v1_s=t1_s
    v2 = t2; v2_s=t2_s
    v3 = t3; v3_s=t3_s
  end
  local out = u2
  if u2_s<0 then out=LibRSA.BigInt:Sub(m,u2); end
  return out
end

local function num2hex(num)  --converts a number his hexadecimal string expression.
  local out=''
  while num>0 do
    local r=num%16
    out=string.format("%X",r)..out
    num=(num-r)/16
  end
  if #out==0 then out='0'; end
  return out
end


local function hex2num(hex)
  local out=0
  for i=#hex,1,-1 do
    local s=string.sub(hex,i,i)
    out=out+tonumber('0x'..s)*16^(#hex-i)
  end
	return out
end

local function finalize_keys(keyobj)
  a=LibRSA.BigInt:HexToNum(num2hex(keyobj.a[1]))
  b=LibRSA.BigInt:HexToNum(num2hex(keyobj.b[1]))

  local C=LibRSA.BigInt:Mul(a,b)
  local phi=LibRSA.BigInt:Mul(LibRSA.BigInt:Sub(a,{1}),LibRSA.BigInt:Sub(b,{1}))
  local e = FindE(phi)
  if e>63 then  -- i publish the pubkey as additional ascii character in the armor, so must fit in 6 bits.
    --print("Pubkey too high, recalculating")
		LibRSA:GenKeyAsync(keyobj.SHA1,keyobj) --calculate another key pair
		return
  end
  local d=FindD(e,phi)
  C['1']={e}
  return C,d,e
end

---------------------------------- KEY GENERATION -----------------------------

function LibRSA:GenKeyAsync(randomtext,keyobj)
  if not randomtext then
    error "You must give some random text to initiate the RSA key generator."
  elseif #randomtext<20 then
    --print "The RSA key generator needs at least 20 character as random text to produce good keys.
  end

	local keyobj=keyobj or {}
  keyobj.SHA1=LibRSA:Calculate_SHA1(randomtext)
	--keyobj.SHA1="8234567890123456789092345678901234567890"
	keyobj.a={}
	keyobj.b={}
--	LibRSA:GenKeyCont(keyobj)
	return keyobj
end

local GenKeySteps = 15000 --steps to do on the single GenKeyCont call. dimmed to use 1 milliseconds of CPU time on a average processor.
function LibRSA:GenKeyCont(keyobj)
	local prim=keyobj.a
	if prim[2] then
		prim=keyobj.b
		if prim[2] then return finalize_keys(keyobj); end  --if you found both the needed primes, then calculate the key.
	end

	if not prim[1] then
		prim[1]=hex2num(string.sub(keyobj.SHA1,1,13))  --13 * 4 = 52 bit
		if prim[1]<0x10000000000000 then prim[1]=prim[1]+0x10000000000000; end --force each prime to be 52 bit long.
		if prim[1]%2 == 0 then prim[1]=prim[1]-1; end --don't want even numbers
		keyobj.SHA1=string.sub(keyobj.SHA1,14)  --cut the 13 characters you used from the entropy source
		keyobj.div=nil
	end

	local steps,isprime=GenKeySteps
	while steps>0 do
		isprime,steps=isPrime(prim[1],steps,keyobj.div)
		if isprime==true then --if you found the prime then
			prim[2]=true              --mark the number as prime
			keyobj.div=nil
		elseif isprime==false then
			prim[1]=prim[1]-2
			keyobj.div=nil
		else
			keyobj.div=isprime
			--this is if steps run off while calculating
		end
	end
	--print(prim[1])
end

function LibRSA:GenKeyNow(randomtext)
  if not randomtext then
    error "You must give some random text to initiate the RSA key generator."
  elseif #randomtext<20 then
    --print "The RSA key generator needs at least 20 character as random text to produce good keys.
  end

	local keyobj=LibRSA:GenKeyAsync(randomtext)
	local pubkey,privkey
	local i=0
	while not pubkey do
		pubkey,privkey=LibRSA:GenKeyCont(keyobj)
		i=i+1
	end
	--print("Key found in "..i.." iterations")
	return pubkey,privkey
end


function LibRSA:GetWoWEntropy()
--	this function returns a string with some entropy-based infos you can get from WoW.
--	I'd like to add the camera values to the mixing, but
--	couldn't find the function to get them.

	local c_x,c_y=GetCursorPosition()
	local d,u,l=GetNetStats()
	local out=''

	for r=1,math.random(5,10) do  --get a random number with 25 to 50 digits
		out=out..tostring(math.random(99999))
	end
	out=out..tostring(GetFramerate())
	out=out..tostring(GetTime())
	out=out..tostring(c_x)..tostring(c_y)
	out=out..tostring(d)..tostring(u)..tostring(l)

	--[[
	for bag = 0,4 do  --chain in a list of gear you have in the inventory
		for slot = 1,GetContainerNumSlots(bag) do
			out = out..tostring(GetContainerItemLink(bag,slot) or math.random(1000000))
		end
	end
]]

	for r=1,math.random(5,10) do  --get a random number with 25 to 50 digits
		out=out..tostring(math.random(99999))
	end

	return out
end




----------------------------------- SIGN/CRYPT FUNCTION ---------------------------------------------------------

function LibRSA:Sign(text,pubkey,privkey)
  if type(text)~='string' and type(privkey)~='table' and not type(pubkey)~='table' then
	error "usage: LibRSA:Sign(text as string, pubkey as bigint(table), privkey as bigint(table)"
  end
	local modulus=pubkey
	local hash=LibRSA:Digest(text)
  local n=LibRSA.BigInt:HexToNum(hash)
  local sign=LibRSA.BigInt:ModPower(n,privkey,modulus)
  local arm= LibRSA:Armor(sign)
  return arm, hash
end

function LibRSA:VerifySign(text,signArm,pubkey)
  if type(text)~='string' or type(signArm)~='string' or type(pubkey)~='table' or type(pubkey['1'])~='table' then
	error "usage: LibRSA:VerifySign(text as string, sign as armor(string), pubkey as bigint(table)"
  end
  local sign=LibRSA:Dearmor(signArm)
  if not type(sign)=='table' then error "usage: LibRSA:VerifySign(text as string, sign as armor(string), pubkey as bigint(table)"; end
	local modulus,pubkey=pubkey,pubkey['1']
  local hash=LibRSA:Digest(text)
  local signDec=LibRSA.BigInt:NumToHex(LibRSA.BigInt:ModPower(sign,pubkey,modulus))
  return hash==signDec, hash
end

function LibRSA:Crypt(text,pubkey)
	if type(text)~='string' or type(pubkey)~='table' or type(pubkey['1'])~='table' then
		error 'usage: LibRSA:Crypt(text as string, pubkey as bigint(table)'
	end
	local modulus,pubkey=pubkey,pubkey['1']
	local numbers={}
	for i=1,#text,12 do
		local num=''
		local chunk=string.sub(text,i,i+11)
		for j=0,#chunk-1 do
			local c=num2hex(string.byte(text,i+j))
			if #c==1 then h='0'..c; end
			num=num..c
		end
		num=LibRSA.BigInt:HexToNum(num)
		table.insert(numbers,num)
	end
	local out={}
	for i=1,#numbers do
		local enc=LibRSA.BigInt:ModPower(numbers[i],pubkey,modulus)
		out[tostring(i-1)]=enc
	end
	out=LibRSA:Armor(out)
	return out
end

function LibRSA:Decrypt(crytext,pubkey,privkey)
	if type(crytext)~='string' or type(pubkey)~='table' or type(privkey)~='table' then
		error 'usage: LibRSA:Decrypt(cryptext as armor(string), pubkey as bigint(table), privkey(table))'
	end
	local modulus=pubkey
	local numbers=LibRSA:Dearmor(crytext)
	local out=''
	local i=0
	local dnum=numbers['0']
	while dnum do
		local decr= LibRSA.BigInt:ModPower(dnum,privkey,modulus)
		local hex=LibRSA.BigInt:NumToHex(decr)
		for j=1,#hex,2 do
			local c=hex2num(string.sub(hex,j,j+1))
			out=out..string.char(c)
		end
		i=i+1
		dnum=numbers[tostring(i)]
	end
	return out
end


--------------------------- MISC STUFF ------------------------

function LibRSA:CheckKeyPair(pubkey,privkey)
-- Does a crypt/decrypt to check the given key pair.
-- function strenghtened to accept any type of input.
	if type(pubkey)~='table' or type(privkey)~='table' then return; end
	if #pubkey==0 or #privkey==0 then return; end
	local modulus,pubkey=pubkey,pubkey['1']
	if not pubkey then return; end

	local bn=LibRSA.BigInt:HexToNum("1234567890ABCDEFEDCBA098")
  local success,enc=pcall(LibRSA.BigInt.ModPower,nil,bn,privkey,modulus)
	if not success then return; end
  local success,dec=pcall(LibRSA.BigInt.ModPower,nil,enc,pubkey,modulus)
	if not success then return
  elseif LibRSA.BigInt:NumToHex(dec)=="1234567890ABCDEFEDCBA098" then return true; end
end

function LibRSA:Digest(stuff)
-- Returns a 96 bit hash from a custom string.
  local hash=LibRSA:Calculate_SHA1(stuff)
  return string.sub(hash,1,24)
end



--[[

-------------------------------------------------
---      *** BigInteger for Lua ***           ---
-------------------------------------------------
--- Author:  Martin Huesser                   ---
--- Date:    2008-06-16                       ---
--- License: You may use this code in your    ---
---          projects as long as this header  ---
---          stays intact.                    ---
-------------------------------------------------
Modified By RB

BigInteger it's a library to circumvent lua's limitation on integer number, that is 2^53
It stores the number breaking it in 24 bit chunks, and storing them in a list.

you can access the library under LibRSA.BigInt

functions:

LibRSA.BigInt:NumToHex(bigint) return the hex string representation of the given bigint
LibRSA.Bigint:HexToNumber(txt) returns the bigint given a hex string representation
LibRSA.Bigint:Add(bigint1,bigint2) retruns the sum of the given bigints
LibRSA.BigInt:Mul(bigint1,bigint2) returns the product of the given bigints
LibRSA.BigInt:Div(bigint1,bigint2) returns the quotient and rest of bigind1 over bigint2
LibRSA.BigInt:ModPower(b,e,m) returns b^e mod m. all input are bigints.
]]


LibRSA.BigInt={}

---------------------------------------
--- Lua 5.0/5.1/WoW Header ------------
---------------------------------------

local strlen  = string.len
local strchar = string.char
local strbyte = string.byte
local strsub  = string.sub
local max     = math.max
local min     = math.min
local floor   = math.floor
local ceil    = math.ceil
local mod     = math.fmod
local getn    = function(t) return #t end
local setn    = function() end
local tinsert = table.insert
--[[local bnot    = bit.bnot
local band    = bit.band
local bor     = bit.bor
local bxor    = bit.bxor
local shl     = bit.lshift
local shr     = bit.rshift]]
local h0, h1, h2, h3, h4

---------------------------------------
--- Helper Functions ------------------

local function Clean(x)						--remove leading zeros
	local i = getn(x)
	while (i>1 and x[i]==0) do
		x[i] = nil
		i = i-1
	end
	setn(x,i)
end

---------------------------------------
--- String Conversion -----------------
---------------------------------------

---------------------------------------

function LibRSA.BigInt:NumToHex(x)					--convert bignumber to hexstring
	local s,i,j,c = ""
	for i = #x,1,-1 do
		local hex=num2hex(x[i])
		if #hex<6 and i~=#x then hex=string.rep('0',6-#hex)..hex; end
		s=s..hex
	end
	return s
end

---------------------------------------

function LibRSA.BigInt:HexToNum(h)					--convert hexstring to bignumber
  local x,i,j = {}
  for i = 1,ceil(strlen(h)/6) do
    local ie=#h-6*(i-1)
    local is=max(ie-5,0)
    local s=string.sub(h,is,ie) or '0'
    x[i] = hex2num(s)
  end
  --Clean(x)
  return x
end

----------------------------------------
--- Math Functions --------------------
---------------------------------------

function LibRSA.BigInt:Add(x,y)					--add numbers
	local z,l,a,i,r = {},max(getn(x),getn(y)),0
	for i = 1,l do
		r = (x[i] or 0)+(y[i] or 0)+a
		if (r>16777215) then
			z[i] = r-16777216
			z[i+1] = 1
			a=1
		else
			z[i] = r
			a=0
		end
	end
	--Clean(z)
	return z
end

---------------------------------------

function LibRSA.BigInt:Sub(x,y)					--subtract numbers
	local z,l,i,r = {},max(getn(x),getn(y))
	z[1] = 0
	for i = 1,l do
		r = (x[i] or 0) - (y[i] or 0) -z[i]
		if (r<0) then
			z[i] = r+16777216
			z[i+1] = 1
		else
			z[i] = r
			z[i+1] = 0
		end
	end
	--i=l+1
	if (z[l+1]==1) then
		return nil
	--elseif z[l+1]==0 then z[l+1]=nil
	end
	Clean(z)
	return z
end

---------------------------------------

function LibRSA.BigInt:Mul(x,y)					--multiply numbers
	local z,t,i,j,r = {},{}
	for i = #y,1,-1 do
		t[1] = 0
		for j = 1,#x do
			r = x[j]*y[i]+t[j]
			t[j+1] = floor(r/16777216)
			t[j] = r-t[j+1]*16777216
		end
		tinsert(z,1,0)
		z = LibRSA.BigInt:Add(z,t)
	end
	Clean(z)
	return z
end

---------------------------------------

local function Div2(x)						--divide number by 2, (modifies
	local u,v,i = 0						          --passed number and returns
	for i = getn(x),1,-1 do					--remainder)
		v = x[i]
		if (u==1) then
			x[i] = floor(v/2)+8388608
		else
			x[i] = floor(v/2)
		end
		u = mod(v,2)
	end
	Clean(x)
	return u
end

---------------------------------------

local function SimpleDiv(x,y)					--divide numbers, result
	local z,u,v,i,j = {},0					--must fit into 1 digit!
	j = 16777216
	for i,n in ipairs(y) do					--This function is costly and
		z[i+1] = n					        --may benefit most from an
	end							                  --optimized algorithm!
	z[1] = 0
	for i = 23,0,-1 do
		j = j/2
		Div2(z)
		v = LibRSA.BigInt:Sub(x,z)
		if v~=nil then
 			u = u+j
			x = v
		end
	end
	return u,x
end


---------------------------------------

function LibRSA.BigInt:Div(x,y)					--divide numbers
	local z,u,i,v = {},{},getn(x)
	for v = 1,min(getn(x),getn(y))-1 do
		tinsert(u,1,x[i])
		i = i - 1
	end
	while (i>0) do
		tinsert(u,1,x[i])
		i = i - 1
		v,u = SimpleDiv(u,y)
		tinsert(z,1,v)
	end
	Clean(z)
	return z,u
end

---------------------------------------

function LibRSA.BigInt:ModPower(b,e,m)					--calculate b^e mod m
	local t,s,r = {},{1}
	for r = 1,#e do
		t[r] = e[r]
	end
	repeat
		r = Div2(t)
		if (r==1) then
			r,s = LibRSA.BigInt:Div(LibRSA.BigInt:Mul(s,b),m)
		end
		r,b = LibRSA.BigInt:Div(LibRSA.BigInt:Mul(b,b),m)
	until (t[1]==0 and #t==1)
	return s
end

---------------------------------------
--- ModPower Step Functions -----------
---------------------------------------

function LibRSA.BigInt:MP_StepInit(b,e,m)				--initialize nonblocking ModPower,
	local x,i = {b,{},m,{1},1}				--pass resulting table to StepExec!
	for i = 1,getn(e) do
		x[2][i] = e[i]
	end
	return x
end

---------------------------------------

function LibRSA.BigInt:MP_StepExec(x)					--execute next calculation step,
	local r							--finished if result~=nil.
	if (x[5]==1) then
		x[5] = 2
		r = Div2(x[2])
		if (r==1) then
			r,x[4] = LibRSA.BigInt:Div(LibRSA.BigInt:Mul(x[4],x[1]),x[3])
		end
		return nil
	end
	if (x[5]==2) then
		x[5] = 1
		r,x[1] = LibRSA.BigInt:Div(LibRSA.BigInt:Mul(x[1],x[1]),x[3])
		if (getn(x[2])==1 and x[2][1]==0) then
			x[5] = 0
			return x[4]
		end
		return nil
	end
	return nil
end


function LibRSA.BigInt:isGreater(x,y)
  if #x>#y then return true
  elseif #x<#y then return false
  else
    for i=#x,1,-1 do
      if x[i]>y[i] then return true
      elseif x[i]<y[i] then return false
      end
    end
  end
  return false
end

function LibRSA.BigInt:isEqual(x,y)
	if #x~=#y then return false; end
	for i=1,#x do
		if x[i]~=y[i] then return false; end
	end
	return true
end

---------------------------------------

local function FactorizeBy2(num)
	local x={}
	for i,n in ipairs(num) do x[i]=n; end --copy input table
	local e=0
	while x[1]%2==0 do
		Div2(x)
		e=e+1
	end
	return e,x
end

---------------------------------------
--[[
write n - 1 as 2s·d with d odd by factoring powers of 2 from n - 1
LOOP: repeat k times:
   pick a randomly in the range [2, n - 1]
   x <- ad mod n
   if x = 1 or x = n - 1 then do next LOOP
   for r = 1 .. s - 1
      x <- x2 mod n
      if x = 1 then return composite
      if x = n - 1 then do next LOOP
   return composite
return probably prime
]]
--[[local t={}
for i=2,100 do
local r=2
while r*i<200 do t[r*i]=true; r=r+1;end
end
for i=2,200 do
	if not t[i] then print(i); end
end
]]
local primes={{3},{5},{7},{11},{13},{17},{19},{23},{29},
                      {31},{37},{41},{43},{47},{53},{59},{61},{67},
											{71},{73},{79},{83},{89},{97},{101},{103},{107},
											{109},{113},{127},{131},{137},{139},{149},{151},
											{157},{163},{167},{173},{179},{181},{191},{193},
											{197},{199}}
function LibRSA.BigInt:IsTrivialComposite(n)
--returns true if the number is divisible by one of the primes above.
	for i,p in pairs(primes) do
		local q,r=LibRSA.BigInt:Div(n,p)
		if r[1]==0 then return true; end
	end
end

--implement the Miller-Rabin probabilistic primality test
function LibRSA.BigInt:IsPrimeStart(n,k)
	local obj={}
	obj.k=k or 1
	obj.n=n
	obj.nm1=LibRSA.BigInt:Sub(n,{1})
	obj.s,obj.d=FactorizeBy2(obj.nm1)
	return obj
end

local function next_step(obj)
	obj.a=nil
	obj.x=nil
	if obj.k==1 then
		obj.finish=true
		return true
	else obj.k=obj.k-1
	end
end

function LibRSA.BigInt:IsPrimeStep(obj,num)
	if obj.finish then
		return true
	elseif not obj.a then
		obj.a={}
		for i=1,#obj.nm1 do
			if i==#obj.nm1 then obj.a[i]=math.random(obj.nm1[i])
			else obj.a[i]=math.random(0xffffff)
			end
		end
		obj.mps=LibRSA.BigInt:MP_StepInit(obj.a,obj.d,obj.n)
	elseif not obj.x then
		num=num or 1
		for i=1,num do
			obj.x=LibRSA.BigInt:MP_StepExec(obj.mps)
			if obj.x then
				if (obj.x[1]==1 and #obj.x==1) or LibRSA.BigInt:isEqual(obj.x,obj.nm1) then
					return next_step(obj)
				else
					break
				end
			end
		end
	else
		for i=1,obj.s-1 do
			obj.x=LibRSA.BigInt:ModPower(obj.x,{2},obj.n)
			if obj.x[1]==1 and #obj.x==1 then return false; end
			if LibRSA.BigInt:isEqual(obj.x,obj.nm1) then return next_step(obj); end
		end
		return false
	end
end



---------------------- ARMOR FUNCTIONS -------------------------

local function digit2ascii(d) --d must be 0<=d<=63
	local c
	if d<26 then c=65+d
	elseif d<52 then c=71+d
	elseif d<62 then c=d-4
	elseif d==62 then c=35
	else c=42
	end
	return c
end

local function ascii2digit(c)
	local d
	if c>64 and c<91 then d=c-65
	elseif c>96 and c<193 then d=c-71
	elseif c>47 and c<58 then d=c+4
	elseif c==35 then d=62
	elseif c==42 then d=63
	else return
	end
	return d
end


function LibRSA:Armor(n)
	local s,t,c =""
	local sn=n['0'] or n
	local k=0
	while sn do
		if k>0 then s=s..'.';end
		for i,x in ipairs(sn) do
			for j=1,4 do
				t=x%64
				local c=digit2ascii(t)
				s=s..string.char(c)
				x=(x-t)/64
				if x==0 and not sn[i+1] then break; end
			end
			s=s or 'A'
		end
		k=k+1
		sn=n[tostring(k)]
	end
	return s
end

function LibRSA:Dearmor(s)
	-- protection check
	-- since this is primarly used to import data receivedby untrusted sources,
	-- we must strenghten the function aganist malformed input
	if type(s) ~= 'string' then return nil; end
	if string.find(s,'[^a-zA-Z0-9*#\.]') then return nil; end
	if #s>1000 then return nil; end --maximum string size is 1000 characters.
	-- end protection check

	local o,t,c={}
	local ot=o
	local k=0
	local i=1
	while i<=#s do
		local n=0
		local ins=true
		for j=0,3 do
			if i+j>#s then break; end
			local c=string.byte(s,i+j)
			if c==46 then
				table.insert(ot,n)
				ins=false
				k=k+1
				ot={}
				o[tostring(k)]=ot
				i=i+j-3
				break
			else
				local d=ascii2digit(c)
				if not d then return; end
				n=n+d*64^j
			end
		end
		if ins then table.insert(ot,n); end
		i=i+4
	end
	Clean(o)
	o['0']=o
	return o
end

--[[
-------------------------------------------------
---      *** SHA-1 algorithm for Lua ***      ---
-------------------------------------------------
--- Author:  Martin Huesser                   ---
--- Date:    2008-06-16                       ---
--- License: You may use this code in your    ---
---          projects as long as this header  ---
---          stays intact.                    ---
-------------------------------------------------


Calculates the sha1 has for the given string input

LibRSA:Calculate_SHA1(text) is the function. retruns the 160 bit hash as an hexadecimal string.
]]
-------------------------------------------------

local function LeftRotate(val, nr)
	return shl(val, nr) + shr(val, 32 - nr)
end

-------------------------------------------------

local function PreProcess(str)
	local bitlen, i
	local str2 = ""
	bitlen = strlen(str) * 8
	str = str .. strchar(128)
	i = 56 - band(strlen(str), 63)
	if (i < 0) then
		i = i + 64
	end
	for i = 1, i do
		str = str .. strchar(0)
	end
	for i = 1, 8 do
		str2 = strchar(band(bitlen, 255)) .. str2
		bitlen = floor(bitlen / 256)
	end
	return str .. str2
end

-------------------------------------------------

local function MainLoop(str)
	local a, b, c, d, e, f, k, t
	local i, j
	local w = {}
	while (str ~= "") do
		for i = 0, 15 do
			w[i] = 0
			for j = 1, 4 do
				w[i] = w[i] * 256 + strbyte(str, i * 4 + j)
			end
		end
		for i = 16, 79 do
			w[i] = LeftRotate(bxor(bxor(w[i - 3], w[i - 8]), bxor(w[i - 14], w[i - 16])), 1)
		end
		a = h0
		b = h1
		c = h2
		d = h3
		e = h4
		for i = 0, 79 do
			if (i < 20) then
				f = bor(band(b, c), band(bnot(b), d))
				k = 1518500249
			elseif (i < 40) then
				f = bxor(bxor(b, c), d)
				k = 1859775393
			elseif (i < 60) then
				f = bor(bor(band(b, c), band(b, d)), band(c, d))
				k = 2400959708
			else
				f = bxor(bxor(b, c), d)
				k = 3395469782
			end
			t = LeftRotate(a, 5) + f + e + k + w[i]
			e = d
			d = c
			c = LeftRotate(b, 30)
			b = a
			a = t
		end
		h0 = band(h0 + a, 4294967295)
		h1 = band(h1 + b, 4294967295)
		h2 = band(h2 + c, 4294967295)
		h3 = band(h3 + d, 4294967295)
		h4 = band(h4 + e, 4294967295)
		str = strsub(str, 65)
	end
end

-------------------------------------------------

function LibRSA:Calculate_SHA1(str)
	str = PreProcess(str)
	h0  = 1732584193
	h1  = 4023233417
	h2  = 2562383102
	h3  = 0271733878
	h4  = 3285377520
	MainLoop(str)
	return  ''..
		num2hex(h0) ..
		num2hex(h1) ..
		num2hex(h2) ..
		num2hex(h3) ..
		num2hex(h4)
end



--local n=LibRSA.BigInt:HexToNum('1000080000000000000000000000000000000000')
--print(n[1],n[2])
--local x,n=factorizeby2(n)
--print(x,LibRSA.BigInt:NumToHex(n))

--local p,pr=LibRSA:GenKeyNow('dlnlwdplnwcd')
--print(LibRSA:CheckKeyPair(p,pr))
--print(LibRSA:Armor(p),LibRSA:Armor(pr))
--local p,pr=LibRSA:Dearmor('lkoHRb*p0z#hwLrRSI.F'), LibRSA:Dearmor('9OEJQtgdQPy0m8IOoG')

--local tod=LibRSA.BigInt:HexToNum('123456789012345678901234')

--print(LibRSA:Armor(LibRSA.BigInt:ModPower(tod,p,pr)))

--local obj=LibRSA.BigInt:MP_StepInit(tod,p,pr)
--local n,r=0
--while not r do
--	n=n+1
--	r=LibRSA.BigInt:MP_StepExec(obj)
--end
--print(n)
--print(LibRSA:Armor(r))
