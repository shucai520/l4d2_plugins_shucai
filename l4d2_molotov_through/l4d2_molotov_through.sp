#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define VERSION "1.0"

#define SOLID_BSP 1

ConVar g_cEnable;
bool g_bEnable;

public Plugin myinfo = 
{
	name = "L4D2 燃烧瓶穿过小僵尸",
	author = "蔬菜",
	version = VERSION,
	url = "https://steamcommunity.com/profiles/76561198354605943"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_molotov_through_version", VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cEnable = CreateConVar("l4d2_molotov_through_enable", "1", "Enable or disable");
	OnConVarChanged(g_cEnable, "", "");
	g_cEnable.AddChangeHook(OnConVarChanged);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnable = g_cEnable.BoolValue;
}

public void OnEntityCreated(int entity, const char[] sClassname)
{
	if(g_bEnable && !strcmp(sClassname, "molotov_projectile"))
	{
		SetEntProp(entity, Prop_Send, "m_nSolidType", SOLID_BSP);
	}
}