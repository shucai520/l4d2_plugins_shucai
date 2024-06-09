#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools_functions>
#include <l4d2util_weapons>
#include <sdkhooks>

#define VERSION "1.0"

bool g_bFlag;

public Plugin myinfo = 
{
	name = "需要切到副武器才能捡手枪",
	author = "蔬菜",
	version = VERSION,
	url = "https://steamcommunity.com/profiles/76561198354605943"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_pickup_pistol_manger_version", VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	ConVar cvar = CreateConVar("l4d2_pickup_pistol_manger_enable", "1", "Enable or disable");
	OnConVarChanged(cvar, "", "");
	cvar.AddChangeHook(OnConVarChanged);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bFlag = convar.BoolValue;
}

public void OnClientPutInServer(int client)
{
	if(!IsFakeClient(client))
	{
		SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	}
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

public Action WeaponCanUse(int client, int weapon)
{
	if (!g_bFlag || GetClientTeam(client) != 2)
	{
		return Plugin_Continue;
	}

	if(IdentifyWeapon(weapon) != 1)
	{
		return Plugin_Continue;
	}
	
	int slotWeapon = GetPlayerWeaponSlot(client, 1);
	if (slotWeapon == -1)
	{
		return Plugin_Continue;
	}

	if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != slotWeapon && IdentifyWeapon(slotWeapon) != 1)
	{
		PrintToChat(client, "需要切换到 副武器 才能拾取手枪");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}