#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

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

public void L4D_MolotovProjectile_Post(int client, int projectile, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3])
{
	if(g_bEnable)
	{
		SetEntProp(projectile, Prop_Send, "m_nSolidType", SOLID_BSP);
	}
}