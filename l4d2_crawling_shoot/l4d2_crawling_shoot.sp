#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define VERSION "1.0"

MemoryPatch g_mPatch;

public Plugin myinfo = 
{
	name = "倒地移动射击",
	author = "蔬菜",
	version = VERSION,
	url = "https://steamcommunity.com/profiles/76561198354605943"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_crawling_shoot_version", VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	ConVar cvar = CreateConVar("l4d2_crawling_shoot_enable", "1", "Enable or disable");
	Init();
	OnConVarChanged(cvar, "", "");
	cvar.AddChangeHook(OnConVarChanged);
}

void Init() {
	delete g_mPatch;

	GameData hGameData = new GameData("l4d2_crawling_shoot");

	g_mPatch = MemoryPatch.CreateFromConf(hGameData, "CTerrorWeapon::CanDeployFor::Patch");
	if (!g_mPatch.Validate())
		SetFailState("Verify patch failed!: %s", "CTerrorWeapon::CanDeployFor::Patch");
	if (!g_mPatch.Enable())
		SetFailState("Enable patch failed!: %s", "CTerrorWeapon::CanDeployFor::Patch");
	delete hGameData;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar.BoolValue) 
	{
		g_mPatch.Enable();
	}
	else
	{
		g_mPatch.Disable();
	}
}