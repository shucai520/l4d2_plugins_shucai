#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define VERSION "1.0"

public Plugin myinfo = 
{
	name = "L4D2 起身闲置不刷新无敌时间",
	author = "蔬菜",
	version = VERSION,
	url = "https://steamcommunity.com/profiles/76561198354605943"
}

public void OnPluginStart()
{
	HookEvent("player_bot_replace", Event_BotPlay);
	HookEvent("bot_player_replace", Event_PlayerPlay);
}

public void Event_BotPlay(Event hEvent, char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(hEvent.GetInt("player"));
	int bot = GetClientOfUserId(hEvent.GetInt("bot"));

	CTimer_SetTimestamp(L4D2Direct_GetInvulnerabilityTimer(bot), CTimer_GetTimestamp(L4D2Direct_GetInvulnerabilityTimer(client)));
}

public void Event_PlayerPlay(Event hEvent, char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(hEvent.GetInt("player"));
	int bot = GetClientOfUserId(hEvent.GetInt("bot"));

	CTimer_SetTimestamp(L4D2Direct_GetInvulnerabilityTimer(client), CTimer_GetTimestamp(L4D2Direct_GetInvulnerabilityTimer(bot)));
}