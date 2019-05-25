#include <sourcemod>
#include <sdktools>

new const String:PLUGIN_VERSION[] = "0.0.1";

new String:g_strConfigFile[PLATFORM_MAX_PATH];

ArrayList red_origin;
ArrayList blue_origin;
int iMaxRED, iMaxBLU;

public Plugin myinfo =
{
	name = "[TF2] Teleport",
	author = "caxanga334",
	description = "Teleport players to a random entity",
	version = PLUGIN_VERSION,
	url = "https://github.com/caxanga334/"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_teleme", Command_teleme, ADMFLAG_ROOT);
	BuildPath(Path_SM, g_strConfigFile, sizeof(g_strConfigFile), "configs/teleport_coords.cfg");
	red_origin = new ArrayList(3);
	blue_origin = new ArrayList(3);
	Load_Config();
}

public Action Command_teleme(int client, int args)
{
	//char arg1[128];
	TeleportPlayerToRandomOrigin(client, GetClientTeam(client));
	LogAction(client, -1, "Player %L teleported.", client);
	ReplyToCommand(client, "Teleporting...");
	return Plugin_Handled;
}

public Load_Config()
{	
	decl String:CfgOrigin[16];
	decl Float:Origin[3];
	decl String:CurrentMap[MAX_NAME_LENGTH];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	if(!FileExists(g_strConfigFile))
	{
		SetFailState("Configuration file %s not found!", g_strConfigFile);
		return;
	}
	red_origin.Clear();
	blue_origin.Clear();

	KeyValues kv = new KeyValues("Teleport");
	kv.ImportFromFile(g_strConfigFile);
	
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		delete kv;
	}
	
	// Iterate over subsections at the same nesting level
	char buffer[255];
	do
	{
		kv.GetSectionName(buffer, sizeof(buffer));
		if (StrEqual(buffer, CurrentMap))
		{
			// RED
			kv.JumpToKey("red", false);
			iMaxRED = kv.GetNum("max");
			for (int i = 1; i <= iMaxRED; i++)
			{
				Format(CfgOrigin, sizeof(CfgOrigin), "origin%i", i);
				kv.GetVector(CfgOrigin, Origin);
				red_origin.PushArray(Origin);
			}
			kv.GoBack();
			// BLU
			kv.JumpToKey("blue", false);
			iMaxBLU = kv.GetNum("max");
			for (int i = 1; i <= iMaxBLU; i++)
			{
				Format(CfgOrigin, sizeof(CfgOrigin), "origin%i", i);
				kv.GetVector(CfgOrigin, Origin);
				blue_origin.PushArray(Origin);
			}
			kv.GoBack();			
		}
	} while (kv.GotoNextKey());
	
	delete kv;
}

stock TeleportPlayerToRandomOrigin(int iClient, int iTeam)
{
	decl Float:Origin[3];
	int iTarget;
	if(iTeam == 2)
	{
		iTarget = GetRandomInt(0, iMaxRED - 1);
		red_origin.GetArray(iTarget, Origin);
	}
	else if(iTeam == 3)
	{
		iTarget = GetRandomInt(0, iMaxBLU - 1);
		blue_origin.GetArray(iTarget, Origin);
	}
	TeleportEntity(iClient, Origin, NULL_VECTOR, NULL_VECTOR);
}