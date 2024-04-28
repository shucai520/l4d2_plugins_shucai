#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define VERSION "1.0"

ConVar g_cHunterTime, g_cJockeyTime, g_cSourceTime;
float g_fHunterTime, g_fJockeyTime, backupTime;

public Plugin myinfo = 
{
	name = "自定义修改Hunter, Jockey 震开幸存者的僵直时间",
	author = "蔬菜",
	version = VERSION,
	url = "https://steamcommunity.com/profiles/76561198354605943"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_change_stragger_time_version", VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cHunterTime = CreateConVar("l4d2_hunter_stragger_time", "0.5", "Hunter震开幸存者的僵直时间, -1 = 默认z_max_stagger_duration", FCVAR_NONE, true, -1.0, true, 2.0);
	g_cJockeyTime = CreateConVar("l4d2_jockey_stragger_time", "0.5", "Jockey震开幸存者的僵直时间, -1 = 默认z_max_stagger_duration", FCVAR_NONE, true, -1.0, true, 2.0);
	Init();

	g_cSourceTime = FindConVar("z_max_stagger_duration");

	OnConVarChanged(null, "", "");
	g_cHunterTime.AddChangeHook(OnConVarChanged);
	g_cJockeyTime.AddChangeHook(OnConVarChanged);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fHunterTime = g_cHunterTime.FloatValue;
	g_fJockeyTime = g_cJockeyTime.FloatValue;
}

MRESReturn CTerrorPlayer_OnLeptOnSurvivor_Pre()
{
	backupTime = g_cSourceTime.FloatValue;
	if(g_fJockeyTime >= 0.0)
		g_cSourceTime.FloatValue = g_fJockeyTime;
	return MRES_Ignored;
}

MRESReturn CTerrorPlayer_OnLeptOnSurvivor_Post()
{
	g_cSourceTime.FloatValue = backupTime;
	return MRES_Ignored;
}

MRESReturn CTerrorPlayer_OnPouncedOnSurvivor_Pre()
{
	backupTime = g_cSourceTime.FloatValue;
	if(g_fHunterTime >= 0.0)
		g_cSourceTime.FloatValue = g_fHunterTime;
	return MRES_Ignored;
}

MRESReturn CTerrorPlayer_OnPouncedOnSurvivor_Post()
{
	g_cSourceTime.FloatValue = backupTime;
	return MRES_Ignored;
}

void Init() {
	GameData hGameData = new GameData("l4d2_change_stragger_time");

	DynamicDetour dDetour = DynamicDetour.FromConf(hGameData, "DD::CTerrorPlayer::OnLeptOnSurvivor");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: DD::CTerrorPlayer::OnLeptOnSurvivor");
	if (!dDetour.Enable(Hook_Pre, CTerrorPlayer_OnLeptOnSurvivor_Pre))
		SetFailState("Failed to detour post: DD::CTerrorPlayer::OnLeptOnSurvivor");
	if (!dDetour.Enable(Hook_Post, CTerrorPlayer_OnLeptOnSurvivor_Post))
		SetFailState("Failed to detour post: CTerrorPlayer_OnLeptOnSurvivor_Post");
	delete dDetour;

	dDetour = DynamicDetour.FromConf(hGameData, "DD::CTerrorPlayer::OnPouncedOnSurvivor");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: DD::CTerrorPlayer::OnPouncedOnSurvivor");
	if (!dDetour.Enable(Hook_Pre, CTerrorPlayer_OnPouncedOnSurvivor_Pre))
		SetFailState("Failed to detour post: DD::CTerrorPlayer::OnPouncedOnSurvivor");
	if (!dDetour.Enable(Hook_Post, CTerrorPlayer_OnPouncedOnSurvivor_Post))
		SetFailState("Failed to detour post: DD::CTerrorPlayer::OnPouncedOnSurvivor_Post");
	delete dDetour;

	delete hGameData;
}