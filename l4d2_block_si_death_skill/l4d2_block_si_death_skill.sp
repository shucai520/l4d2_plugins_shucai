#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define VERSION "1.0"

MemoryPatch 
	g_mSpitterBurning,
	g_mExplosion,
	g_mCloud,
	g_mCloudCamera;

GameData hGameData;

typedef SiFunction = function void();

enum struct SiPatch
{
	SiFunction func[2];
}

SiPatch siPatchArr[3];

ConVar g_cCough_radius;

public Plugin myinfo = 
{
	name = "L4D2 阻止Boomer, Spitter, Smoker 死后释放技能",
	author = "蔬菜",
	version = VERSION,
	url = "https://steamcommunity.com/profiles/76561198354605943"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_block_si_death_skill_version", VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	ConVar cvar = CreateConVar("l4d2_block_si_flag", "7", "0 = off, 1 = smoker, 2 = boomer, 4 = spitter, 7 = all", FCVAR_NONE, true, 0.0, true, 7.0);
	g_cCough_radius = FindConVar("z_cough_cloud_radius");

	Init();
	OnConVarChanged(cvar, "", "");
	cvar.AddChangeHook(OnConVarChanged);
}

public void OnPluginEnd()
{
	ResetConVar(g_cCough_radius);
}

void Init() {
	hGameData = new GameData("l4d2_block_si_death_skill");

	//smoker
	g_mCloud = CreateFromConfFunc("CTerrorPlayer::Event_Killed::BlockCloud");
	g_mCloudCamera = CreateFromConfFunc("CTerrorPlayer::Event_Killed::BlockCloudCamera");
	//boomer
	g_mExplosion = CreateFromConfFunc("CTerrorPlayer::Event_Killed::BlockExplosion");
	//spitter
	g_mSpitterBurning = CreateFromConfFunc("CTerrorPlayer::Event_Killed::BlockBurning");

	siPatchArr[0].func[1] = SomkerOn;
	siPatchArr[0].func[0] = SomkerOff;
	siPatchArr[1].func[1] = BoomerOn;
	siPatchArr[1].func[0] = BoomerOff;
	siPatchArr[2].func[1] = SpitterOn;
	siPatchArr[2].func[0] = SpitterOff;

	delete hGameData;
}

MemoryPatch CreateFromConfFunc(const char[] name)
{
	MemoryPatch patch = MemoryPatch.CreateFromConf(hGameData, name);
	if (!patch.Validate())
		SetFailState("Verify patch failed! : %s", name);
	if (!patch.Enable())
		SetFailState("Enable patch failed! : %s", name);
	return patch;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int flag = convar.IntValue;
	for(int i = 0; i < 3; ++i)
	{
		Call_StartFunction(null, siPatchArr[i].func[flag & 1]);
		Call_Finish();
		flag >>= 1;
	}
}

void SpitterOn() { g_mSpitterBurning.Enable(); }

void SpitterOff() { g_mSpitterBurning.Disable(); }

void BoomerOn() { g_mExplosion.Enable(); }

void BoomerOff() { g_mExplosion.Disable(); }

void SomkerOn()
{
	g_mCloud.Enable();
	g_mCloudCamera.Enable();
	g_cCough_radius.IntValue = 0;
}

void SomkerOff()
{
	g_mCloud.Disable();
	g_mCloudCamera.Disable();
	ResetConVar(g_cCough_radius);
}