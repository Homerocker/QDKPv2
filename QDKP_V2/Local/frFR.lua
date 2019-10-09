-- Copyright 2010 Riccardo Belloli (rb@belloli.net)
-- Localization file made by Daniel Valero (valerodaniel@free.fr)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--        ## Français - France (frFR) LOCALISATION ##

if GetLocale()=='frFR' then
	--General
	QDKP2_LOC_Net="Net"
	QDKP2_LOC_Spent="Dépensé"
	QDKP2_LOC_Total="Total"
	QDKP2_LOC_Hours="Heures"
	QDKP2_LOC_Start="Démarrer"
	QDKP2_LOC_Finish="Arrêter"
  QDKP2_LOC_Stop="Arrêter"

	--Warnings
	QDKP2_LOC_NotIntoARaid="Vous n'êtes pas dans un raid"
	QDKP2_LOC_BetaWarning="Vous utilisez une version beta de QDKP2.\nSi vous trouvez un bug, veuillez nous en avertir sur\nla page de l'addon sur CurseGaming.com\nMerci!"
--	QDKP2_LOC_OldOptFile="La page d'options de QDKP est périmée.\nVeuillez la remplaçer avec celle fournie\ndans le pack de la version courante."
	QDKP2_LOC_GoesNegative="Le total de points DKP de $NAME est devenu négatif."
	QDKP2_LOC_Negative="Le total de points DKP de $NAME's est négatif."
	QDKP2_LOC_ClearDB="La base de données locale a été nettoyée"
	QDKP2_LOC_Loaded=QDKP2_COLOR_RED.."$VERSION $BETA"..QDKP2_COLOR_WHITE.." Chargée"
	QDKP2_LOC_NoRights=QDKP2_COLOR_RED.."Vous n'êtes pas autorisé à éditer les points DKP."
	QDKP2_LOC_EqToLowCap="Impossible de débiter $NAME. Son montant DKP est égal au seuil minimum."
	QDKP2_LOC_NearToLowCap="Le montant DKP de $NAME's est insuffisant. Le montant maximal que vous pouvez utiliser est de $MAXCHARGE."

	--Auto Boss Award
	QDKP2_LOC_Killed="$MOB a été vaincu !"
	QDKP2_LOC_Kill=" vaincu" --used in the reason of DKP awards when a boss is illed (like 'gains 10 dkp for Onyxia _kill_')
	QDKP2_LOC_WinDetect_Q="Voulez-vous activer\nLe système de détection du vainqueur?"

	--Raid Manager
	QDKP2_LOC_IsInRaid="vient d'arriver dans le raid"
	QDKP2_LOC_JoinsRaid="rejoint le raid"
	QDKP2_LOC_GoesOnline="se connecte"
	QDKP2_LOC_GoesOffline="se déconnecte"
	QDKP2_LOC_IsOffline="est déconnecté"
	QDKP2_LOC_NoInGuild="$NAMES semble ne pas être dans la guilde. Mis de côté"
	QDKP2_LOC_LeftRaid="Quitte le raid"
	QDKP2_LOC_ExtJoins="$NAME a rejoint le raid. Ôté de la liste d'attente."

	--IRONMAN BONUS
	QDKP2_LOC_FinishWithRaid="Le bonus IronMan n'a pas encore été clos.\nVoulez-vous le clore maintenant?"
	QDKP2_LOC_StartButOffline="Le bonus IronMan bonus a démarré mais un joueur est déconnecté"
	QDKP2_LOC_IronmanMarkPlaced="Balise IronMan placée"
	QDKP2_LOC_DataWiped="Les données IronMan ont été effacées"

	--DKP Modify
	QDKP2_LOC_Gains="Gagne $GAIN DKP"
	QDKP2_LOC_GainsSpends="Gagne $GAIN and Dépense $SPEND DKP"
	QDKP2_LOC_GainsEarns="Gagne $GAIN DKP et ajoute $HOUR hours"
	QDKP2_LOC_GainsSpendsEarns=" Gagne $GAIN et dépense $SPEND DKP, et ajoute $HOUR hours"
	QDKP2_LOC_Spends="Dépense $SPEND DKP"
	QDKP2_LOC_SpendsEarns="Dépense $SPEND DKP et ajoute $HOUR hours"
	QDKP2_LOC_Earns="Ajoute $HOUR hours"
	QDKP2_LOC_ReceivedReas="Les membre du raid connectés reçoivent $AMOUNT DKP pour $REASON"
	QDKP2_LOC_Received="Les menmbres du raid connectés reçoivent $AMOUNT DKP"
	QDKP2_LOC_ZSRecReas="$NAME donne $AMOUNT DKP au raid pour $REASON"
	QDKP2_LOC_ZSRec="$NAME donne $AMOUNT DKP au raid"
	QDKP2_LOC_RaidAw="[Raid Award] $AWARDSPENDTEXT"
	QDKP2_LOC_RaidAwReas="[Raid Award] $AWARDSPENDTEXT pour $REASON"
	QDKP2_LOC_RaidAwMain="Raid $AWARDSPENDTEXT"
	QDKP2_LOC_RaidAwMainReas="Raid $AWARDSPENDTEXT pour $REASON"
	QDKP2_LOC_ZeroSumSp="Donne $SPENT DKP au raid"
	QDKP2_LOC_ZeroSumSpReas="Donne $SPENT DKP au raid pour $REASON"
	QDKP2_LOC_ZeroSumAw="Reçoit $AMOUNT DKP de $GIVER"
	QDKP2_LOC_ZeroSumAwReas="Reçoit $AMOUNT DKP de $GIVER pour $REASON"
	QDKP2_LOC_ExtMod="$AWARDSPENDTEXT for external editing"
	QDKP2_LOC_Generic="$AWARDSPENDTEXT" --these are used in the general case. (eg. manual editing to DKP)
	QDKP2_LOC_GenericReas="$AWARDSPENDTEXT pour $REASON"
	QDKP2_LOC_NoPlayerInChance="You are trying to modify a player that doesn't exist in local cache."
	QDKP2_LOC_MaxNetLimit="Le gain de DKP de $NAME a été limité car il a atteint le seuil maximum de DKP ($MAXIMUMNET)"
	QDKP2_LOC_MaxNetLimitLog="Le seuil maximum de DKP a été atteint. Le gain a été ajusté."
	QDKP2_LOC_MinNetLimit="La perte de points DKP de $NAME a été limité car le seuil minimum de DKP a été atteint ($MINIMUMNET)"
	QDKP2_LOC_MinNetLimitLog="Le seuil minimal de DKP a été atteint. Les pertes ont été ajustées."

	--lost awards
	QDKP2_LOC_Offline="Déconnecté"
	QDKP2_LOC_NoRank="Rang non DKPable"
	QDKP2_LOC_NoZone="Hors Zone"
	QDKP2_LOC_ManualRem="Manuellement exclu"
	QDKP2_LOC_LowAtt="Présence faible"
	QDKP2_LOC_NetLimit="Limite DKP"
	QDKP2_LOC_NoDKPRaid="$WHYNOT. Manque la récompense de raid de $AMOUNT DKP"
	QDKP2_LOC_NoDKPRaidReas="$WHYNOT. Manque la récompense de raid de $AMOUNT DKP pour $REASON"
	QDKP2_LOC_NoDKPZS="$WHYNOT. Manque le partage de $AMOUNT DKP de $GIVER"
	QDKP2_LOC_NoDKPZSReas="$WHYNOT. Manque le partage de $AMOUNT DKP pour $REASON"
	QDKP2_LOC_NoTick="$WHYNOT. Manque le Timer Tic"

	--timer
	QDKP2_LOC_TimerTick="Timer Tic"
	QDKP2_LOC_IntegerTime="Bonus Horaire"
	QDKP2_LOC_RaidTimerLog="Timer Tic. Les membre connectés reçoivent $TIME hours"
	QDKP2_LOC_HoursUpdted="Timer Tic"
	QDKP2_LOC_TimerStop="Timer arrêté"
	QDKP2_LOC_TimerResumed="Reprise du Timer"
	QDKP2_LOC_TimerStarted="Timer démarré"

	--upload
	QDKP2_LOC_NoMod="Aucune modification du DKP n'a été faite depuis le dernier download/upload"
	QDKP2_LOC_SucLocal="Rapport d'upload: $UPLOADED données externes depuis la RAM."
	QDKP2_LOC_Successful="Rapport d'upload: $UPLOADED notes envoyées. Attendez pour la vérification..."
	QDKP2_LOC_Failed="Rapport d'upload: $FAILED n'ont pas été correctement uploadés. Veuillez réessayer dans quelques secondes"
	QDKP2_LOC_IndexNoFound="l'index de guilde de $NAME n'a pas pu être trouvé, Ignoré. Nouvel essai dans une minute"
	QDKP2_LOC_IndexNoFoundLog="A brisé le cache de l'index de guilde (Upload impossible)"

	--Externals's DKP Posting
	QDKP2_LOC_ExtPost="<QDKP2> Somme DKP Externes"
	QDKP2_LOC_ExtLine="$NAME: Net=$NET, Total=$TOTAL, Heures=$HOURS"

	--Log
	QDKP2_LOC_NewSess="Nouvelle Session: $SESSIONNAME"
	QDKP2_LOC_NoSessName="<noname>"
	QDKP2_LOC_LootsItem="reçoit $ITEM"

	--download
	QDKP2_LOC_NewSessionQ="Nommez la nouvelle session"
	QDKP2_LOC_NewSession="Départe de la nouvelle session: $SESSIONNAME"
	QDKP2_LOC_DifferentTot="Le total net+dépensé de $NAME est différent. Veuillez vérifier"
	QDKP2_LOC_NewGuildMember="$NAME a été ajouté au roster de la guilde en tant que nouveau membre."
end
