#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

ConVar CvarInterval;
float g_fInterval, g_fLastTime[MAXPLAYERS];
//检查是否按住
Handle Timers;
int TimersCount[33];

public Plugin myinfo = 
{
	name = "L4D2 give ammo",
	author = "fdxx",
	version = "0.1"
};

public void OnPluginStart()
{
	CvarInterval = CreateConVar("l4d2_give_ammo_time", "90.0", "使用命令的最小间隔时间", FCVAR_NONE);
	g_fInterval = CvarInterval.FloatValue;
	CvarInterval.AddChangeHook(ConVarChange);

	RegConsoleCmd("sm_ammo", Cmd_GiveAmmo);

	AutoExecConfig(true, "l4d2_give_ammo");
}

public void ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fInterval = CvarInterval.FloatValue;
}

public void OnMapStart()
{
	if(Timers == null)
		Timers = CreateTimer(0.2, PlayerTimer, INVALID_HANDLE, TIMER_REPEAT);
}

public void OnMapEnd()
{
	ClearTimer();
}


stock void ClearTimer()
{
	if(Timers != null)
	{
		delete Timers;
	}
}

public Action PlayerTimer(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if(!IsValidEntity(client) || IsFakeClient(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		{
			continue;
		}
		int buttons = GetClientButtons(client);
		if(buttons & IN_RELOAD)
		{
			TimersCount[client]++;
			if(TimersCount[client] >= 5)
			{
				Cmd_GiveAmmo(client, 0);
				TimersCount[client] = 0;
			}
		}
		else
		{
			TimersCount[client] = 0;
		}
	}
	return Plugin_Continue;
}

public Action Cmd_GiveAmmo(int client, int args)
{
	if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		float fTime = GetEngineTime() - g_fLastTime[client] - g_fInterval;
		if (fTime >= 0.0)
		{
			CheatCommand(client, "give", "ammo");
			g_fLastTime[client] = GetEngineTime();
		}
		else PrintToChat(client, "\x01请等待 \x04%.0f \x01秒后在使用本命令", FloatAbs(fTime));
	}
	return Plugin_Handled;
}

void CheatCommand(int client, char[] command, char[] args = "")
{
	int iFlags = GetCommandFlags(command);
	SetCommandFlags(command, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, args);
	SetCommandFlags(command, iFlags);
}
