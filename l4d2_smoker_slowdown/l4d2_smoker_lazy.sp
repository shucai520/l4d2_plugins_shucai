#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define VERSION "1.0"

MemoryPatch g_mPatch;

public Plugin myinfo = 
{
	name = "L4D2 被多个舌头拉停留不叠加",
	author = "蔬菜",
	version = VERSION,
}

public void OnPluginStart()
{
	CreateConVar("l4d2_smoker_lazy_version", VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	ConVar cvar = CreateConVar("l4d2_smoker_lazy_enable", "1", "Enable or disable");
	Init();
	OnConVarChanged(cvar, "", "");
	cvar.AddChangeHook(OnConVarChanged);
}

void Init() {
	delete g_mPatch;

	GameData hGameData = new GameData("l4d2_smoker_lazy");

	g_mPatch = MemoryPatch.CreateFromConf(hGameData, "CTerrorPlayer::OnReleasedByTongue::Cancel");
	if (!g_mPatch.Validate())
		SetFailState("Verify patch failed!");
	if (!g_mPatch.Enable())
		SetFailState("Enable patch failed!");

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