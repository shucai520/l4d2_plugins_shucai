#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools_functions>
#include <left4dhooks>

#define VERSION "1.1"

static int emptySlot3[MAXPLAYERS + 1];
static int emptySlot4[MAXPLAYERS + 1];
static const char 
	g_sSlot3[][] =
	{
		"weapon_first_aid_kit*",
		"weapon_defibrillator*"
	},

	g_sSlot4[][] =
	{
		"weapon_pain_pills*",
		"weapon_adrenaline*"
	}
;

Handle g_hUseEntity;//, g_hIsInInitialCheckpoint_NoLandmark;
//Address pTerrorNavMesh;
ConVar g_cEnable;

public Plugin myinfo = 
{
	name = "L4D2出门自动拿走安全屋药包",
	author = "蔬菜",
	version = VERSION,
	url = "https://steamcommunity.com/profiles/76561198354605943"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_auto_get_saferoom_item_version", VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cEnable = CreateConVar("l4d2_auto_get_saferoom_item_enable", "1", "Enable or disable");
	Init();
}

// public void OnAllPluginsLoaded()
// {
// 	pTerrorNavMesh = L4D_GetPointer(POINTER_NAVMESH);
// }

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	if(g_cEnable.BoolValue)
		CreateTimer(1.1, CheckPlayerSlot);
}

Action CheckPlayerSlot(Handle timer)
{
	int playerIndex3, playerIndex4;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || IsFakeClient(i))
			continue;

		if(GetPlayerWeaponSlot(i, 3) == -1)
			emptySlot3[playerIndex3++] = i;

		if(GetPlayerWeaponSlot(i, 4) == -1)
			emptySlot4[playerIndex4++] = i;
	}

	for(int i = 0, playerIndex = 0; i < sizeof g_sSlot3; ++i)
	{
		if((playerIndex = AutoGetItem(g_sSlot3[i], emptySlot3, playerIndex, playerIndex3)) >= playerIndex3)
			break;
	}

	for(int i = 0, playerIndex = 0; i < sizeof g_sSlot4; ++i)
	{
		if((playerIndex = AutoGetItem(g_sSlot4[i], emptySlot4, playerIndex, playerIndex4)) >= playerIndex4)
			break;
	}

	return Plugin_Stop;
}

int AutoGetItem(const char[] itemName, int[] emptySlot, int start, int end)
{
	int entity = MaxClients + 1;
	while (start < end && (entity = FindEntityByClassname(entity, itemName)) != INVALID_ENT_REFERENCE)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != -1)
			continue;

		if(!IsInSaferoomArea(entity))
			continue;

		//item_count > 1
		do {
			int client = emptySlot[start++];
			SDKCall(g_hUseEntity, entity, client, client, Use_On, 0.0);
		} while(start < end && IsValidEntity(entity));
		
	}

	return start;
}

bool IsInSaferoomArea(int entity)
{
	static float vOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);

	// Address nav = view_as<Address>(L4D_GetNearestNavArea(vOrigin));
	// return nav != Address_Null && (SDKCall(g_hIsInInitialCheckpoint_NoLandmark, pTerrorNavMesh, nav) || GetSpawnAttributes(nav));
	//夏洛克fix
	return L4D_IsPositionInFirstCheckpoint(vOrigin);
}

// bool GetSpawnAttributes(Address nav)
// {
// 	int spawnAttributes = L4D_GetNavArea_SpawnAttributes(nav);
// 	return (spawnAttributes & NAV_SPAWN_CHECKPOINT) && (spawnAttributes & NAV_SPAWN_PLAYER_START);
// }

bool IsValidClient(int client)
{
	return IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

void Init()
{
	// GameData hGameData = new GameData("left4dhooks.l4d2");

	// StartPrepSDKCall(SDKCall_Raw);
	// if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::IsInInitialCheckpoint_NoLandmark"))
	// 	SetFailState("Failed to find signature: \"TerrorNavMesh::IsInInitialCheckpoint_NoLandmark\"");
	// PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	// PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	// g_hIsInInitialCheckpoint_NoLandmark = EndPrepSDKCall();
	// if(g_hIsInInitialCheckpoint_NoLandmark == null )
	// 	SetFailState("Failed to create SDKCall: \"TerrorNavMesh::IsInInitialCheckpoint_NoLandmark\"");

	// delete hGameData;

	//https://github.com/fdxx/l4d2_plugins/blob/main/l4d2_gear_transfer.sp
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetVirtual(GetOSType() ? 107 : 106);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	g_hUseEntity = EndPrepSDKCall();
	if (g_hUseEntity == null)
		SetFailState("Failed to create SDKCall: CBaseEntity::Use");
}