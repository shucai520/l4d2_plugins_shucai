#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define VERSION "1.0"
#define RUN 0
#define LIMP 1
#define FUMES 2

ConVar 
	g_cRunSpeed,
	g_cLimpSpeed,
	g_cFumesSpeed;

float g_fSpeed[3];

char g_GdName [][] = 
{
	"CTerrorPlayer::GetRunTopSpeed::RunSpeed",
	"CTerrorPlayer::GetRunTopSpeed::LimpSpeed",
	"CTerrorPlayer::GetRunTopSpeed::FumesSpeed"
};

public Plugin myinfo = 
{
	name = "幸存者移动速度",
	author = "蔬菜",
	version = VERSION,
	url = "https://steamcommunity.com/profiles/76561198354605943"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_survivor_run_speed_version", VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cRunSpeed = CreateConVar("l4d2_survivor_run_speed", "220.0", "普通移速", _, true, 0.0);
	g_cLimpSpeed = CreateConVar("l4d2_survivor_limp_speed", "150.0", "瘸腿移速", _, true, 0.0);
	g_cFumesSpeed = CreateConVar("l4d2_survivor_fumes_speed", "85.0", "1血移速", _, true, 0.0);

	Init();
	OnConVarChanged(null, "", "");
	g_cRunSpeed.AddChangeHook(OnConVarChanged);
	g_cLimpSpeed.AddChangeHook(OnConVarChanged);
	g_cFumesSpeed.AddChangeHook(OnConVarChanged);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fSpeed[RUN] = g_cRunSpeed.FloatValue;
	g_fSpeed[LIMP] = g_cLimpSpeed.FloatValue;
	g_fSpeed[FUMES] = g_cFumesSpeed.FloatValue;
}

void Init()
{
	GameData gd = new GameData("l4d2_survivor_run_speed");
	if (gd == null)
		SetFailState("Failed to load \"l4d2_survivor_run_speed.txt\" gamedata.");

	for(int i = 0; i < 3; ++i)
		SetMemoryPatch(gd, i, g_GdName[i]);

	delete gd;
}

void SetMemoryPatch(GameData gd, int index, const char[] name)
{
	MemoryPatch mp = MemoryPatch.CreateFromConf(gd, name);
	if (!mp.Validate())
		SetFailState("Verify patch failed : %s", name);
	if (!mp.Enable())
		SetFailState("Enable patch failed : %s", name);
	StoreToAddress(mp.Address + view_as<Address>(4), GetAddressOfCell(g_fSpeed[index]), NumberType_Int32);
}