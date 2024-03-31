#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <left4dhooks>

#define VERSION "1.0"

float si_stagger_time[32];
float g_vStart[32][3];
Handle si_timer[32];

bool flag;

public Plugin myinfo = 
{
	name = "L4D2 特感落地保持被推状态",
	author = "蔬菜",
	version = VERSION,
	url = "https://steamcommunity.com/profiles/76561198354605943"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_keep_stagger_version", VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	ConVar cvar = CreateConVar("l4d2_keep_stagger_enable", "1", "Enable or disable");
	OnConVarChanged(cvar, "", "");
	cvar.AddChangeHook(OnConVarChanged);

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= 32; ++i)
	{
		if(si_timer[i])
		{
			delete si_timer[i];
			si_timer[i] = null;
		}
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(si_timer[client])
	{
		delete si_timer[client];
		si_timer[client] = null;
	}
}

public void L4D_OnShovedBySurvivor_Post(int client, int victim, const float vecDir[3])
{
	if(flag && IsValidClient(victim, 3) && GetEntProp(victim, Prop_Send, "m_zombieClass") <= 5)
	{
		si_stagger_time[victim] = GetEntPropFloat(victim, Prop_Send, "m_staggerTimer", 1);
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", g_vStart[victim]);
	}
	
}

public void L4D2_OnStagger_Post(int client, int source)
{
	if(flag && IsValidClient(client, 3))
	{
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", g_vStart[client]);
		si_stagger_time[client] = GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1);
	}
}

public void L4D_OnCancelStagger_Post(int client)
{
	if(flag && !OnGround(client) && IsValidClient(client, 3))
	{
		if(GetGameTime() < si_stagger_time[client])
		{
			if(!si_timer[client])
				si_timer[client] = CreateTimer(0.1, NextFrame_Set, client, TIMER_REPEAT);
		}
	}
}

Action NextFrame_Set(Handle timer, int client)
{
	if(OnGround(client))
	{
		L4D_StaggerPlayer(client, client, g_vStart[client]);
		SetEntPropFloat(client, Prop_Send, "m_staggerTimer", si_stagger_time[client], 1);

		si_timer[client] = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}


void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	flag = convar.BoolValue;
}

bool OnGround(int client)
{
	return (GetEntityFlags(client) & FL_ONGROUND) != 0;
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