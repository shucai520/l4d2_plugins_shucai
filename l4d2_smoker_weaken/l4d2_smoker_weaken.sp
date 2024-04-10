#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define VERSION "1.0"

ConVar g_cClubCut, g_cMeleeShove;
MemoryPatch g_mClubCut, g_mMeleeShove;

public Plugin myinfo = 
{
	name = "钝器断舌, 被拉近战可推 ",
	author = "蔬菜",
	version = VERSION,
	url = "https://steamcommunity.com/profiles/76561198354605943"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_smoker_weaken_version", VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cClubCut = CreateConVar("l4d2_club_cut_tongue_enable", "1", "钝器断舌");
	g_cMeleeShove = CreateConVar("l4d2_melee_can_shove_enable", "1", "被拉近战可推");
	Init();
	OnConVarChanged(null, "", "");
	g_cClubCut.AddChangeHook(OnConVarChanged);
	g_cMeleeShove.AddChangeHook(OnConVarChanged);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(g_cClubCut.BoolValue)
		g_mClubCut.Enable();
	else
		g_mClubCut.Disable();

	if(g_cMeleeShove.BoolValue)
		g_mMeleeShove.Enable();
	else
		g_mMeleeShove.Disable();
}

void Init() {
	GameData hGameData = new GameData("l4d2_smoker_weaken");

	g_mClubCut = MemoryPatch.CreateFromConf(hGameData, "MP::CTerrorMeleeWeapon::TestMeleeSwingCollision");
	if (!g_mClubCut.Validate())
		SetFailState("Verify patch failed!");
	if (!g_mClubCut.Enable())
		SetFailState("Enable patch failed!");

	g_mMeleeShove = MemoryPatch.CreateFromConf(hGameData, "MP::CTerrorMeleeWeapon::SecondaryAttack");
	if (!g_mMeleeShove.Validate())
		SetFailState("Verify patch failed!");
	if (!g_mMeleeShove.Enable())
		SetFailState("Enable patch failed!");
	
	delete hGameData;
}