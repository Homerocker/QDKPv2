-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## LOGGING SYSTEM ##
--                   Costants

--Log Types
QDKP2LOG_EVENT = 1          --generic log event
QDKP2LOG_CONFIRMED = 2  --modify entry succesfully uploaded (see QDKP2LOG_FIELD_MODIFY)
QDKP2LOG_CRITICAL = 3       --generic log error (related to QDKP, to the upload or to the sync)
QDKP2LOG_MODIFY = 4        --entry that log a DKP modification and has not created/modified and not uploaded yet.
QDKP2LOG_LINK = 5           --this entry is a lin k to annother entry
QDKP2LOG_JOINED = 7         --player that joined the raid (either because he was invited or because he returned online)
QDKP2LOG_LEFT = 8        --player that left the raid (either because he really leaved the raid or because he went offline)
QDKP2LOG_LOOT = 9          --logging of a loot
QDKP2LOG_ABORTED = 10   --modify entry that has been deactivated
QDKP2LOG_NODKP = 11       --Lost award
QDKP2LOG_BOSS=12        --Created when a boss is killed
QDKP2LOG_BIDDING=13   --used by the bid manager
QDKP2LOG_EXTERNAL=50
QDKP2LOG_SESSION=101     --virtual entry that is used to aggregate all entries created in a given session (the "joins session <xyz>")
QDKP2LOG_INVALID=0    --Returned if the log has a nil typ

QDKP2log_LogTypesDict = {}
QDKP2log_LogTypesDict[1]= 'Generic Event'
QDKP2log_LogTypesDict[2] = 'DKP-Confirmed'
QDKP2log_LogTypesDict[3] = 'Error'
QDKP2log_LogTypesDict[4] = 'DKP-Unuploaded'
QDKP2log_LogTypesDict[5] = 'Log link'
QDKP2log_LogTypesDict[7] = 'Raid join'
QDKP2log_LogTypesDict[8] = 'Raid leave'
QDKP2log_LogTypesDict[9] = 'Loot'
QDKP2log_LogTypesDict[10] = 'DKP-Inactive'
QDKP2log_LogTypesDict[11] = 'Lost award'
QDKP2log_LogTypesDict[12] = 'Boss kill'
QDKP2log_LogTypesDict[50] = 'External mod.'
QDKP2log_LogTypesDict[101] = 'Session'
QDKP2log_LogTypesDict[0] = 'INVALID'




--NoDKP subtypes
QDKP2LOG_NODKP_MANUAL=0   -- Manually excluded. 
QDKP2LOG_NODKP_OFFLINE=1  -- Player was offline
QDKP2LOG_NODKP_RANK=2     -- UnDKP-able rank
QDKP2LOG_NODKP_ZONE=3     -- Out of zone
QDKP2LOG_NODKP_LOWRAID=4  -- Low raid attendance - used for IronMan bonus
QDKP2LOG_NODKP_LIMIT=5    -- Player was already at max net DKP limit.
QDKP2LOG_NODKP_IMSTART=6  -- Out of raid at IronMan start mark
QDKP2LOG_NODKP_IMSTOP=7   -- Out of raid at IronMan finish.

--fields for each log entry
QDKP2LOG_FIELD_TYPE = 1
QDKP2LOG_FIELD_TIME = 2
QDKP2LOG_FIELD_ACTION = 3
QDKP2LOG_FIELD_VERSION = 4
QDKP2LOG_FIELD_AMOUNTS = 5
QDKP2LOG_FIELD_MODBY = 6
QDKP2LOG_FIELD_MODDATE = 7
QDKP2LOG_FIELD_FLAGS = 8 -- nil = no link, 0 don't link, 1 link
QDKP2LOG_FIELD_CREATOR = 9 -- used only in the general sessions entries. don't use it in other sessions or you'll
                           -- break the 255 bytes limit for the sync string.
QDKP2LOG_FIELD_SIGN = 10

--These are the functions controlled by the session mantainers.
QDKP2LOG_SESSFUN_HOURLY="Hourly"
QDKP2LOG_SESSFUN_BOSSES="Bosses"
QDKP2LOG_SESSFUN_IRONMAN="IronMan"
QDKP2LOG_SESSFUN_WINDETECT="WinDetect"
QDKP2LOG_SESSFUN_BIDMANAGER="BidManager"
QDKP2LOG_SESSFUN_PRICES="Prices"
