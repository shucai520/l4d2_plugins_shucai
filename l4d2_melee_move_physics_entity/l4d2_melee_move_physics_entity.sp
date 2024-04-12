#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <sdkhooks>

#define VERSION "1.0"

ConVar g_cFlag, g_cDmg, g_cForce, g_cForceHeight;

float client_ves[MAXPLAYERS + 1][3];
bool flag;
float g_fDmg, g_fForce, g_fForceHeight;

public Plugin myinfo = 
{
	name = "近战打铁",
	author = "蔬菜",
	version = VERSION,
	url = "https://steamcommunity.com/profiles/76561198354605943"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_melee_move_physics_entity_version", VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cFlag = CreateConVar("l4d2_melee_move_enable", "1", "开启关闭");
	g_cDmg = CreateConVar("l4d2_melee_move_damage", "650", "打铁伤害");
	g_cForce = CreateConVar("l4d2_melee_move_force", "500", "打铁力度");
	g_cForceHeight = CreateConVar("l4d2_melee_move_height_force", "350", "击飞力度");

	Init();
	EnableFlag(null, "", "");
	OnConVarChanged(null, "", "");
	g_cFlag.AddChangeHook(EnableFlag);
	g_cDmg.AddChangeHook(OnConVarChanged);
	g_cForce.AddChangeHook(OnConVarChanged);
	g_cForceHeight.AddChangeHook(OnConVarChanged);
}

public void OnClientPutInServer(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

void EnableFlag(ConVar convar, const char[] oldValue, const char[] newValue)
{
	flag = g_cFlag.BoolValue;
	if(!flag)
		SDKUnhookFunc();
	else
		SDKHookFunc();
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fDmg = g_cDmg.FloatValue;
	if(g_fDmg == 0)
		g_fDmg = 79.0;

	g_fForce = g_cForce.FloatValue;
	g_fForceHeight = g_cForceHeight.FloatValue;
}

void Init() {
	GameData hGameData = new GameData("l4d2_melee_move_physics_entity");

	DynamicDetour dDetour = DynamicDetour.FromConf(hGameData, "DD::CTerrorMeleeWeapon::ShouldHitEntity");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: CTerrorMeleeWeapon::ShouldHitEntity");
	if (!dDetour.Enable(Hook_Post, DD_CTerrorWeapon_ShouldHitEntity))
		SetFailState("Failed to detour post: CTerrorMeleeWeapon::ShouldHitEntity");
	delete dDetour;

	dDetour = DynamicDetour.FromConf(hGameData, "DD::CTerrorMeleeWeapon::TestMeleeSwingCollision");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: DD::CTerrorMeleeWeapon::TestMeleeSwingCollision");
	if (!dDetour.Enable(Hook_Pre, DD_CTerrorWeapon_TestMeleeSwingCollision))
		SetFailState("Failed to detour post: DD::CTerrorMeleeWeapon::TestMeleeSwingCollision");
	delete dDetour;
	delete hGameData;
}

void SDKUnhookFunc()
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
			SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	}
}

void SDKHookFunc()
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(damagetype == 1 && IsValidClient(attacker, 2))
	{
		if(IsValidClient(victim, 2))
		{
			damage = 0.0;
			return Plugin_Changed;
		}

		damage = g_fDmg;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

MRESReturn DD_CTerrorWeapon_TestMeleeSwingCollision(int pthis, DHookReturn hReturn, DHookParam hParams)
{
	int client = GetEntPropEnt(pthis, Prop_Send, "m_hOwner");
	hParams.GetVector(1, client_ves[client]);
	return MRES_Ignored;
}

MRESReturn DD_CTerrorWeapon_ShouldHitEntity(int pthis, DHookReturn hReturn, DHookParam hParams)
{
	if(!flag) return MRES_Ignored;

	int entity = hParams.Get(1);
	static char name[32];
	GetEdictClassname(entity, name, sizeof name);
	if(strcmp("prop_physics", name) && strcmp("prop_car_alarm", name)) 
	{
		return MRES_Ignored;
	}

	int client = GetEntPropEnt(pthis, Prop_Send, "m_hOwner");
	client_ves[client][0] *= g_fForce;
	client_ves[client][1] *= g_fForce;
	client_ves[client][2] = client_ves[client][2] * g_fForce + g_fForceHeight;

	SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
	SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, client_ves[client]);
	return MRES_Ignored;
}

bool IsValidClient(int client, int team)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			return true;
		}
	}
	return false;
}