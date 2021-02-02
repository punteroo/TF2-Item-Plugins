#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo = 
{
	name = "VIP Management System",
	author = "Lucas 'puntero' Maza",
	description = "Private VIP System made for Prophet's server.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=213425"
};

/////////////////////
// GLOBAL DECLARES //
/////////////////////

// Maximum commands allowed
// You can modify this if you reaaaally need more commands.
// Default limit is 30
#define	MAX_VIP_COMMANDS	30

// Commands array
char 	Commands[MAX_VIP_COMMANDS][64];

// Config Path n' Handle
char 	CfgPath[PLATFORM_MAX_PATH];
Handle 	CfgKv = INVALID_HANDLE;

// Menus after loading config
// Main Menu
Menu 	VIPMenu;

/////////////////////
/////////////////////
/////////////////////

public void OnPluginStart()
{
	RegAdminCmd("sm_vipmenu",	CMD_VIP, ADMFLAG_RESERVATION, "Opens up the VIP menu.");
	RegAdminCmd("sm_vip", 		CMD_VIP, ADMFLAG_RESERVATION, "Opens up the VIP menu.");
	RegAdminCmd("sm_donor", 	CMD_VIP, ADMFLAG_RESERVATION, "Opens up the VIP menu.");
	RegAdminCmd("sm_donator", 	CMD_VIP, ADMFLAG_RESERVATION, "Opens up the VIP menu.");
	// Just registering many ways of invoking the command, for convinience.
	
	BuildPath(Path_SM, CfgPath, sizeof(CfgPath), "configs/vip-system.cfg");
	// Used to get the full path to the config file so we can load it.
	
	LoadVIP();
	// Load dat config boi.
}

public void OnMapStart()
{
	LoadVIP();
	// Reload the config on each map change, to prevent the menu from corrupting.
}

public Action CMD_VIP (int client, int args)
{
	// If the menu is fine, we just show it to the player and we're done.
	if (VIPMenu != INVALID_HANDLE) {
		DisplayMenu(VIPMenu, client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	
	// If the menu is indeed wrong (which is impossible), we log an error message.
	LogMessage("[VIP] ERROR: Config was loaded correctly, yet menu is invalid.");
	return Plugin_Handled;
}

public int MainVIPh (Menu menu, MenuAction action, int p1, int p2)
{
	// no yanderedev code here, we do this prestigiously
	switch (action)
	{
		// Whenever the client selects something from the menu.
		case MenuAction_Select:
		{
			char sel[3];
			
			GetMenuItem(menu, p2, sel, sizeof(sel));
			int id = StringToInt(sel);
			// Get the selected item ID (what i told you in the loading function we'll use later :3)
			
			// Now, since we have an array of commands each corresponding to each ID, we just execute the one the player selected!
			ClientCommand(p1, Commands[id]);
			// We're done here.
			return 1;
		}
	}
	return 0;
}



													///////////////////////////////////////////////////////////////////////
													///////////////////////////////////////////////////////////////////////
													// Below this section lie my beautiful (horrendous) custom functions.//
													// 						Laughing is allowed.		 				 //
													///////////////////////////////////////////////////////////////////////
													///////////////////////////////////////////////////////////////////////



// LoadVIP() - Loads the VIP config file.
void LoadVIP()
{
	// Check if the config file is where it should be.
	if (!FileExists(CfgPath))
		SetFailState("[VIP] Config file wasn't found at %s. Plugin will not run.", CfgPath);
	
	// Validate the handle beforehand.
	CfgKv = CreateKeyValues("VIP-System");
	
	// Check if the config file is valid on parse.
	if (!FileToKeyValues(CfgKv, CfgPath))
		SetFailState("[VIP] Invalid configuration file structure. Plugin will not run.");
	
	// Jump inside the structure.
	if (KvGotoFirstSubKey(CfgKv)) {
		// Just an easy int that tracks how many commands are there. If it exceeds MAX_VIP_COMMANDS, the plugin stops loading commands.
		int foundCmds = 0;
		
		// Create the main menu (we only fill it ONCE)
		VIPMenu = CreateMenu(MainVIPh);
		SetMenuTitle(VIPMenu, "--VIP Menu--");
		
		// Now load the menu!
		do
		{
			char CmdName[64], ID[3];
			
			// Section name is the sub-key value (what will be displayed as item in the menu)
			KvGetSectionName(CfgKv, CmdName, sizeof(CmdName));
			// Get all attributes (there aren't many now but we'll work on it)
			KvGetString(CfgKv, "command", Commands[foundCmds], sizeof(Commands[]));
			
			// We convert foundCmds to a string for internal usage. You'll see later why!
			IntToString(foundCmds, ID, sizeof(ID));
			
			// Add dat shit in the menu.
			AddMenuItem(VIPMenu, ID, CmdName);
			
			// Increase it by one each loop, until it breaks.
			foundCmds++;
		} while (KvGotoNextKey(CfgKv) && (foundCmds < MAX_VIP_COMMANDS));
		// Loop through all the commands in the config, until there aren't any more or the limit is reached.
		
		// We're done loading it all in.
		LogMessage("[VIP] Configuration file loaded correctly! %d commands are available.", foundCmds);
		return;
	}
	// If we couldn't jump into the structure some medicine must be applied to the config file.
	SetFailState("[VIP] Could not read the config's content. Make sure no bracket is left unclosed, plugin will not run.");
}