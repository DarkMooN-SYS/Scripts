# Live Roblox Remote Inventory

Game: **Conquer The World WW2 [🎃]**  
Place ID: `14422394494`  
Inspected place version: `12949`  

This is a read-only inventory of remotes exposed by the live client. An exposed remote is not automatically callable: the server may validate arguments, ownership, cooldowns, game state, and permissions. Use the normal in-game UI for legitimate actions.

The game-specific scan found **100 remotes under `ReplicatedStorage`**. A whole-DataModel scan found **131 total remotes**; the additional 31 are Roblox platform/system remotes under `RobloxReplicatedStorage` and are listed at the end.

## Government

| Type | Name | Path |
|---|---|---|
| RemoteFunction | `TryStartFocus` | `ReplicatedStorage.Government.TryStartFocus` |
| RemoteFunction | `TryChangeIdeology` | `ReplicatedStorage.Government.TryChangeIdeology` |
| RemoteFunction | `TryFormCountry` | `ReplicatedStorage.Government.TryFormCountry` |
| RemoteEvent | `OnFocusUnlocked` | `ReplicatedStorage.Government.OnFocusUnlocked` |
| RemoteEvent | `FormableAvailable` | `ReplicatedStorage.Government.FormableAvailable` |
| RemoteEvent | `CountryFormed` | `ReplicatedStorage.Government.CountryFormed` |

## Player and map

| Type | Name | Path |
|---|---|---|
| RemoteEvent | `CountrySelected` | `ReplicatedStorage.Player.CountrySelected` |
| RemoteEvent | `MoveTroop` | `ReplicatedStorage.Player.MoveTroop` |
| RemoteEvent | `VoteMap` | `ReplicatedStorage.Player.VoteMap` |
| RemoteEvent | `SetSetting` | `ReplicatedStorage.Player.SetSetting` |
| RemoteEvent | `TeleportHome` | `ReplicatedStorage.Player.TeleportHome` |
| RemoteEvent | `SendFeedback` | `ReplicatedStorage.Player.SendFeedback` |
| RemoteEvent | `EnabledNotifications` | `ReplicatedStorage.Player.EnabledNotifications` |
| RemoteEvent | `SystemChatMessage` | `ReplicatedStorage.Player.SystemChatMessage` |
| RemoteEvent | `OnExpGained` | `ReplicatedStorage.Player.OnExpGained` |

## Army

| Type | Name | Path |
|---|---|---|
| RemoteFunction | `TryIncreaseTarget` | `ReplicatedStorage.Army.TryIncreaseTarget` |
| RemoteFunction | `TryDisbandTroop` | `ReplicatedStorage.Army.TryDisbandTroop` |
| RemoteFunction | `TrySetArmyGroupGeneral` | `ReplicatedStorage.Army.TrySetArmyGroupGeneral` |
| RemoteFunction | `TryUnlockGeneral` | `ReplicatedStorage.Army.TryUnlockGeneral` |
| RemoteFunction | `TryBuyManpower` | `ReplicatedStorage.Army.TryBuyManpower` |
| RemoteEvent | `AddArmy` | `ReplicatedStorage.Army.AddArmy` |
| RemoteEvent | `AddTroopFromTileToArmy` | `ReplicatedStorage.Army.AddTroopFromTileToArmy` |
| RemoteEvent | `AutoAssignTroopsToArmy` | `ReplicatedStorage.Army.AutoAssignTroopsToArmy` |
| RemoteEvent | `ChangeArmyOrder` | `ReplicatedStorage.Army.ChangeArmyOrder` |
| RemoteEvent | `ChangeTargetCountries` | `ReplicatedStorage.Army.ChangeTargetCountries` |
| RemoteEvent | `DisbandArmy` | `ReplicatedStorage.Army.DisbandArmy` |
| RemoteEvent | `HaltTroop` | `ReplicatedStorage.Army.HaltTroop` |
| RemoteEvent | `SetPriorityCity` | `ReplicatedStorage.Army.SetPriorityCity` |
| RemoteEvent | `ToggleArmyReplenish` | `ReplicatedStorage.Army.ToggleArmyReplenish` |
| RemoteEvent | `DescreaseTarget` | `ReplicatedStorage.Army.DescreaseTarget` |

## Economy and production

| Type | Name | Path |
|---|---|---|
| RemoteEvent | `SetProductionPercentage` | `ReplicatedStorage.Production.SetProductionPercentage` |
| RemoteEvent | `PurchaseFactory` | `ReplicatedStorage.Cities.PurchaseFactory` |
| RemoteEvent | `PurchaseDefense` | `ReplicatedStorage.Cities.PurchaseDefense` |
| RemoteFunction | `TryUpgradeShipyard` | `ReplicatedStorage.Economy.TryUpgradeShipyard` |
| RemoteFunction | `TryPurchaseShip` | `ReplicatedStorage.Economy.TryPurchaseShip` |

## Research

| Type | Name | Path |
|---|---|---|
| RemoteFunction | `TryPurchaseTech` | `ReplicatedStorage.Research.TryPurchaseTech` |
| RemoteEvent | `StartResearch` | `ReplicatedStorage.Research.StartResearch` |
| RemoteEvent | `ClearResearchSlot` | `ReplicatedStorage.Research.ClearResearchSlot` |
| RemoteEvent | `OnTechResearched` | `ReplicatedStorage.Research.OnTechResearched` |
| RemoteEvent | `OnAllSlotsOccupied` | `ReplicatedStorage.Research.OnAllSlotsOccupied` |

## Diplomacy

| Type | Name | Path |
|---|---|---|
| RemoteFunction | `TryDeclareWar` | `ReplicatedStorage.Diplomacy.TryDeclareWar` |
| RemoteFunction | `TryRequestAlliance` | `ReplicatedStorage.Diplomacy.TryRequestAlliance` |
| RemoteFunction | `TrySendTreaty` | `ReplicatedStorage.Diplomacy.TrySendTreaty` |
| RemoteFunction | `TryJustifyWar` | `ReplicatedStorage.Diplomacy.TryJustifyWar` |
| RemoteFunction | `TryExitAlliance` | `ReplicatedStorage.Diplomacy.TryExitAlliance` |
| RemoteFunction | `TryFreePuppet` | `ReplicatedStorage.Diplomacy.TryFreePuppet` |
| RemoteFunction | `TryBreakFree` | `ReplicatedStorage.Diplomacy.TryBreakFree` |
| RemoteEvent | `AllianceCallToWar` | `ReplicatedStorage.Diplomacy.AllianceCallToWar` |
| RemoteEvent | `AllianceRequestResponse` | `ReplicatedStorage.Diplomacy.AllianceRequestResponse` |
| RemoteEvent | `TreatyResponse` | `ReplicatedStorage.Diplomacy.TreatyResponse` |
| RemoteEvent | `ShouldPuppet` | `ReplicatedStorage.Diplomacy.ShouldPuppet` |
| RemoteEvent | `JustificationCompleted` | `ReplicatedStorage.Diplomacy.JustificationCompleted` |
| RemoteEvent | `SendNotification` | `ReplicatedStorage.Diplomacy.SendNotification` |
| RemoteEvent | `AnnounceNews` | `ReplicatedStorage.Diplomacy.AnnounceNews` |
| RemoteEvent | `GameOver` | `ReplicatedStorage.Diplomacy.GameOver` |

## Air force and missiles

| Type | Name | Path |
|---|---|---|
| RemoteFunction | `TryDeployPlanes` | `ReplicatedStorage.Planes.TryDeployPlanes` |
| RemoteFunction | `TryMovePlanes` | `ReplicatedStorage.Planes.TryMovePlanes` |
| RemoteFunction | `TryRetreat` | `ReplicatedStorage.Planes.TryRetreat` |
| RemoteFunction | `TryBuildAiport` | `ReplicatedStorage.Planes.TryBuildAiport` |
| RemoteFunction | `TryUpgradeAirfield` | `ReplicatedStorage.Planes.TryUpgradeAirfield` |
| RemoteFunction | `LaunchMissile` | `ReplicatedStorage.TileProjects.LaunchMissile` |
| RemoteEvent | `SetAirfieldPriority` | `ReplicatedStorage.Planes.SetAirfieldPriority` |
| RemoteEvent | `AirfieldBuilt` | `ReplicatedStorage.Planes.AirfieldBuilt` |
| RemoteEvent | `SetMissileInterception` | `ReplicatedStorage.TileProjects.SetMissileInterception` |
| RemoteEvent | `MissileLaunched` | `ReplicatedStorage.TileProjects.MissileLaunched` |
| RemoteEvent | `PurchaseMissileSilo` | `ReplicatedStorage.TileProjects.PurchaseMissileSilo` |
| RemoteEvent | `PurchaseFort` | `ReplicatedStorage.TileProjects.PurchaseFort` |

## Fleet and ports

| Type | Name | Path |
|---|---|---|
| RemoteEvent | `MoveFleet` | `ReplicatedStorage.Fleet.MoveFleet` |
| RemoteEvent | `HaltFleet` | `ReplicatedStorage.Fleet.HaltFleet` |
| RemoteEvent | `DestroyFleet` | `ReplicatedStorage.Fleet.DestroyFleet` |
| RemoteFunction | `TryExitPortWithFleet` | `ReplicatedStorage.Cities.Port.TryExitPortWithFleet` |
| RemoteEvent | `LoadDivisionOnShip` | `ReplicatedStorage.Cities.Port.LoadDivisionOnShip` |
| RemoteEvent | `UnloadDivisionFromShip` | `ReplicatedStorage.Cities.Port.UnloadDivisionFromShip` |
| RemoteEvent | `RemoveShipFromBuildQueue` | `ReplicatedStorage.Cities.Port.RemoveShipFromBuildQueue` |

## Other systems

Other exposed remotes include skins, tutorials, leaderboards, servers, competitive mode, private-server controls, cinematic access, and badges.

## Admin and restricted remotes

The client also exposes an `ReplicatedStorage.Admin` folder containing names such as `IncreaseMoney`, `ResetMap`, `ShutdownServer`, `BanPlayer`, and `KickPlayer`. These are administrative controls and are not legitimate player actions. Do not attempt to invoke them against a public server.

## Roblox platform/system remotes

These were found under `RobloxReplicatedStorage`, not the game’s own `ReplicatedStorage`. They belong to Roblox platform features such as chat, parties, profiles, leaderboards, localization, and playtest services. They are not game-play remotes:

`ReferredPlayerJoin`, `RequestDeviceCameraOrientationCapability`, `BuildExperiencePlaytestTeleport`, `SetDialogInUse`, `ServerSideBulkPurchaseEvent`, `CanChatWith`, `SetPlayerBlockList`, `UpdatePlayerBlockList`, `NewPlayerGroupDetails`, `NewPlayerCanManageDetails`, `SendPlayerBlockList`, `UpdateLocalPlayerBlockList`, `SendPlayerProfileSettings`, `RequestPlayerProfileSettings`, `ExpChatFeatureValueChanged`, `ModerateChatSettingUpdated`, `CreateOrJoinParty`, `ShowFriendJoinedPlayerToast`, `IntegrityCheckProcessorKey2_DynamicTranslationSender_LocalizationService`, `PlatformLeaderboardTabClosed`, `IntegrityCheckProcessorKey2_AutomaticAssetCaptureSender_LocalizationService`, `IntegrityCheckProcessorKey2_TextSafetyAnalyticsSender_LocalizationService`, `IntegrityCheckProcessorKey2_LocalizationTableAnalyticsSender_LocalizationService`, `PlatformLeaderboardPush`, `PlatformLeaderboardTabOpened`, `UpdatePlayerProfileSettings`, `ShowPlayerJoinedFriendsToast`, `WhisperChat`, `GetServerChannel`, `GetServerVersion`, and `GetServerType`.

## Safe usage note

For a legitimate action, click the corresponding in-game button and let the game provide the correct arguments. This inventory intentionally does not include arbitrary `FireServer`/`InvokeServer` payloads or exploit scripts.
