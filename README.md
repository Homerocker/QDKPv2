# QDKPv2
Modified QDKPv2 2.6.7 for 3.3.5a

- "Options.ini" IS NOT compatible with original QDKP2 addon
- implemented heroic bosses detection (DKP_10N/DKP_10H/DKP_25N/DKP_25H)
- auto distribute loot when charging raid member for an item (loot window must be open)
- fixed "The Ruby Sanctum" zone name (fixed boss-award not working in RS)
- correctly parse "Halion the Twilight Destroyer" name (fixed boss-award not working for Halion)
- libBabble (translations) updated to latest 3.3.5 release
- libBabble: corrected Russian localizations for GSB, BPC and BQL according to latest stable DBM for 3.3.5a
- fixed Russian localization of Halion the Twilight Destroyer
- possible fix for incorrect alt links if bugged character with empty name is in guild
- auto distribute loot when raid member wins no-DKP roll (loot window must be open)
- accept bids in "5k" format
- fixed incorrect (often negative) DKP for characters who left and rejoined guild (database will be reset when upgrading from other version of QDKPv2 - all unuploaded changes, external characters, logs, etc. will be purged)
- better localization support
- Russian localization added
- quick modify DKP amount can be correctly set via Options.ini
- DKP modifiers for standby players
