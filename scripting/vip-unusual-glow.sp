#include <sourcemod>
#include <tf2_stocks>
#include <morecolors>

#include <vip-unusual-glow>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.3.2"

public Plugin myinfo = 
{
	name = "[VIP Module] Unusual Glow",
	author = "Lucas 'puntero' Maza",
	description = "Makes your player glow constantly.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=213425"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_TF2)
	{
		SetFailState("This plugin was made for use with Team Fortress 2 only.");
	}
}

// Per-Player effect variable to hold which effect they've selected.
float clientEffect[MAXPLAYERS + 1] = 0.0;

public void OnPluginStart()
{
	RegAdminCmd("sm_unuglow", CMD_UnuGlow, ADMFLAG_RESERVATION, "Opens the Unusual Glowing menu.");
	RegAdminCmd("sm_glowme",  CMD_UnuGlow, ADMFLAG_RESERVATION, "Opens the Unusual Glowing menu.");
	
	HookEvent("player_spawn", OnPlayerSpawn);
	
	LoadTranslations("unusualglow.phrases.txt");
	// Translations !
}

public void OnMapStart()
{
	for (int i = 0; i < sizeof(clientEffect); i++) {
		clientEffect[i] = 0.0;
	}
}

public void OnClientConnected(int client)
{
	clientEffect[client] = 0.0;
}

public void OnClientDisconnect(int client)
{
	clientEffect[client] = 0.0;
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (clientEffect[client] > 0.0)
		SetGlow(client, clientEffect[client]);
	
	return Plugin_Continue;
}

public Action CMD_UnuGlow(int client, int args)
{
	CreateGlowMenu(client);
	return Plugin_Handled;
}

public int glowHdlr(Menu menu, MenuAction action, int client, int p2)
{
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			float eff = StringToFloat(sel);
			
			SetGlow(client, eff);
			
			clientEffect[client] = eff;
			CPrintToChat(client, "%T", "UnuGlow_Message", client);
		}
	}
	return 0;
}