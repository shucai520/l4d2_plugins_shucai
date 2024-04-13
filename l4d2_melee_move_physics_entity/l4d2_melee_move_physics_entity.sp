/*=======================================================================================

v1.1
	- 实体停止后重置速度, 增加碾压打铁伤害开关

=======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <sdkhooks>

#define VERSION "1.1"

ConVar g_cFlag, g_cBlockDmg, g_cDmg, g_cForce, g_cForceHeight;

float client_ves[MAXPLAYERS + 1][3];

bool flag, g_bBlockDmg;
float g_fDmg, g_fForce, g_fForceHeight;

static float vec[3];
static float vector_time[2049][2];

ArrayList entityList;

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
	g_cBlockDmg = CreateConVar("l4d2_melee_move_block_dmg_enable", "1", "免疫来自幸存者对 队友和自身 造成的 碾压打铁伤害");

	g_cDmg = CreateConVar("l4d2_melee_move_damage", "650", "打铁对特感的伤害");
	g_cForce = CreateConVar("l4d2_melee_move_force", "500", "打铁力度");
	g_cForceHeight = CreateConVar("l4d2_melee_move_height_force", "350", "击飞力度");

	HookEvent("round_start", Event_RoundStart);

	Init();
	EnableFlag(null, "", "");
	OnConVarChanged(null, "", "");
	g_cFlag.AddChangeHook(EnableFlag);

	g_cBlockDmg.AddChangeHook(OnConVarChanged);
	g_cDmg.AddChangeHook(OnConVarChanged);
	g_cForce.AddChangeHook(OnConVarChanged);
	g_cForceHeight.AddChangeHook(OnConVarChanged);

	entityList = new ArrayList();
	//https://forums.alliedmods.net/showthread.php?p=1179742
	CreateTimer(0.3, CheckEntity, _, TIMER_REPEAT);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	entityList.Clear();
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
	g_bBlockDmg = g_cBlockDmg.BoolValue;

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
			SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	//damagetype 1|0
	if(!(damagetype & (damagetype - 1)) && IsValidClient(attacker, 2))
	{
		if(IsValidClient(victim, 2))
		{
			if(g_bBlockDmg)
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

	float time = GetGameTime();
	int index = entityList.FindValue(entity);
	
	if(index == -1)
	{
		entityList.Push(entity);
	}
	else if(time - vector_time[entity][1] < 0.5) //间隔太短
	{
		return MRES_Ignored;
	}

	int client = GetEntPropEnt(pthis, Prop_Send, "m_hOwner");

	client_ves[client][0] *= g_fForce;
	client_ves[client][1] *= g_fForce;
	client_ves[client][2] = client_ves[client][2] * g_fForce + g_fForceHeight;

	SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
	SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", time);
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, client_ves[client]);

	//GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vec);
	//vector_time[entity][0] = vec[0];

	return MRES_Ignored;
}

Action CheckEntity(Handle timer)
{
	for(int i = entityList.Length - 1; i >= 0; --i)
	{
		int entity = entityList.Get(i);
		if(!IsValidEntity(entity))
		{
			entityList.Erase(i);
			continue;
		}

		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vec);
		if(vector_time[entity][0] == vec[0])
		{
			entityList.Erase(i);
			vector_time[entity][0] = 0.0;
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, {0.0, 0.0, 0.0});
			continue;
		}

		vector_time[entity][0] = vec[0];
	}

	return Plugin_Continue;
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