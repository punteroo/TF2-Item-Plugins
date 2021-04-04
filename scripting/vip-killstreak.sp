#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

// Custom made "class" (actually a methodmap) to manage user selections.
#include <killstreak-class>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.3.3"

#define MAX_SHEENS 		8
#define MAX_STREAKERS	8

public Plugin myinfo = 
{
	name = "[VIP Module] Killstreak Manager",
	author = "Lucas 'puntero' Maza",
	description = "Gives the ability for users to customize their weapons' killstreak effects.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=213425"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_TF2)
		SetFailState("This plugin was made for use with Team Fortress 2 only.");
}

/////////////////////
// GLOBAL DECLARES //
/////////////////////

// Per client stringmap
KsClient Ks[MAXPLAYERS + 1];

/////////////////////
/////////////////////
/////////////////////

public void OnPluginStart()
{
	RegAdminCmd("sm_killstreak", 	CMD_Ks, ADMFLAG_RESERVATION, "Opens the killstreak configuration menu.");
	RegAdminCmd("sm_ks", 			CMD_Ks, ADMFLAG_RESERVATION, "Opens the killstreak configuration menu.");
	RegAdminCmd("sm_killstreaks",	CMD_Ks, ADMFLAG_RESERVATION, "Opens the killstreak configuration menu.");
	// Various ways of invoking the command. For user commodity ;)
	
	HookEvent("post_inventory_application", OnItems);

	HookEvent("player_spawn", 				OnItems);
	// Event for item "refresh" detection.
	// Hook to the items given / resupply event, this manages when to give the user their weapons.
	// Also hook into the player_spawn event just in case post_inventory_application isn't called (happens sometimes)
	
	LoadTranslations("killstreaks.phrases.txt");
	// Translations !
}

public Action CMD_Ks (int client, int args)
{
	// Open up the main menu for the client.
	GenerateMenu(client);
}

public Action OnItems (Event event, char[] name, bool dontBroadcast)
{
	// Apply killstreak effects upon spawn or resupply touch.
	CreateTimer(0.2, Apply, GetClientOfUserId(GetEventInt(event, "userid")));
}

public Action Apply (Handle timer, any client)
{
	// Callback for that timer on the event callback (duh)
	
	// ONLY APPLY KILLSTREAK EFFECTS IF THE PLAYER IS ALIVE
	// Menus can be used even when dead, so we must make sure he doesn't fuck anything up on accident.
	if (IsPlayerAlive(client) && IsClientInGame(client))
		ApplyKillstreak(client);
}

public int MainHdlr (Menu menu, MenuAction action, int client, int p2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			if (StrEqual(sel, "kD", false) ||
				StrEqual(sel, "kE", false)) {
				Ks[client].all = !Ks[client].all;
				
				GenerateMenu(client);
			}
			else {
				int slot = StringToInt(sel);
				Ks[client].slot = slot;
				
				GenerateWeaponMenu(client, slot);
			}
		}
	}
	return 0;
}

public int WeaponHdlr (Menu menu, MenuAction action, int client, int p2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// Fuck strings man, seriously.
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			if (StrEqual(sel, "type", false)) {
				int slot = Ks[client].slot;
				
				int newKs = Ks[client].type[slot] + 1;
				Ks[client].type[slot] = ((0 <= Ks[client].type[slot] <= 3) ? newKs : 0);
				
				SetClientKillstreak(client, newKs, slot);
				
				switch (newKs) {
					case 0, 1, 2: {
						if (IsPlayerAlive(client) && IsClientInGame(client))
							RemoveKillstreak(client, newKs);
					}
				}
				
				// ONLY APPLY KILLSTREAK EFFECTS IF THE PLAYER IS ALIVE
				// Menus can be used even when dead, so we must make sure he doesn't fuck anything up on accident.
				if (IsPlayerAlive(client))
					ApplyKillstreak(client);
				
				GenerateWeaponMenu(client, slot);
				
				return 0;
			}
			if (StrEqual(sel, "sheen", false)) 
				GenerateEffectsMenu(client);
			if (StrEqual(sel, "streaker", false))
				GenerateEffectsMenu(client, true);
		}
	}
	return 0;
}

public int SheenHdlr (Menu menu, MenuAction action, int client, int p2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// Fuck strings man, seriously.
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			int slot = Ks[client].slot;
			
			Ks[client].sheen[slot] = StringToInt(sel);
			
			// ONLY APPLY KILLSTREAK EFFECTS IF THE PLAYER IS ALIVE
			// Menus can be used even when dead, so we must make sure he doesn't fuck anything up on accident.
			if (IsPlayerAlive(client) && IsClientInGame(client))
				ApplyKillstreak(client);
			
			GenerateWeaponMenu(client, slot);
			return 0;
		}
	}
	return 0;
}

public int StreakerHdlr (Menu menu, MenuAction action, int client, int p2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// Fuck strings man, seriously.
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			int slot = Ks[client].slot;
			
			Ks[client].streaker[slot] = StringToInt(sel);
			
			// ONLY APPLY KILLSTREAK EFFECTS IF THE PLAYER IS ALIVE
			// Menus can be used even when dead, so we must make sure he doesn't fuck anything up on accident.
			if (IsPlayerAlive(client) && IsClientInGame(client))
				ApplyKillstreak(client);
			
			GenerateWeaponMenu(client, slot);
			return 0;
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



// SetClientKillstreak() - Sets the current clients' killstreak preferences according to the type.
// @arg int client - Represents the client integer.
// @arg float type - The type of Killstreak the client chose.
// @noreturn
void SetClientKillstreak(int client, int type, int slot = 0)
{
	// This function all it does is reset Sheen values and Killstreaker values whenever the client switches types of killstreaks.
	// Since we support All Weapons Mode, there is a different method for either.
	// Makes this block kind of repetitive but it doesn't matter.
	
	// First check if the client has All Weapons Mode enabled.
	if (Ks[client].all) {
		// If he does, we'll loop through all the slots and set them to 0.
		for (int i = 0; i < 3; i++) {
			// Use as an Integer to avoid 0.0 or 1.0
			switch (type) {
				case 0, 1: {
					// If he has no Killstreak enabled or a Normal Killstreak, empty Sheen and Killstreaker values.
					Ks[client].sheen[i] = 0;
					Ks[client].streaker[i] = 0;
				}
				case 2:
					// If he has a Specialized Killstreak, empty only the Sheen value.
					Ks[client].streaker[i] = 0;
			}
		}
	}
	// Same goes here, except it's just for one specific slot.
	else {
		switch (type) {
			case 0, 1: {
				Ks[client].sheen[slot] = 0;
				Ks[client].streaker[slot] = 0;
			}
			case 2:
				Ks[client].streaker[slot] = 0;
		}
	}
}
// GenerateMenu() - Generates a menu with the client's weapons, and displays it to them. This allows them to choose individual weapon effects.
void GenerateMenu(int client)
{
	Menu menu = new Menu(MainHdlr);
	
	char title[64];
	Format(title, 64, "%T", "Ks_MenuTitle", client);
	menu.SetTitle(title);
	
	bool isAll = Ks[client].all;
	
	if (!isAll) {
		for (int i = 1; i < 4; i++) {
			char slot[32], temp[32], iStr[4];
			IntToString(i - 1, iStr, sizeof(iStr));
			Format(temp, 32, "Ks_Slot_%d", i);
			
			Format(slot, 32, "%T", temp, client);
			
			menu.AddItem(iStr, slot);
		}
	}
	else {
		char slot[32];
		Format(slot, 32, "%T", "Ks_Slot_All", client);
		
		menu.AddItem("0", slot);
	}
	
	menu.AddItem("-", "-----------------", ITEMDRAW_DISABLED);
	
	char applyMsg[64];
	Format(applyMsg, 64, "%T", isAll ? "Ks_AllWeps_Apply_On" : "Ks_AllWeps_Apply_Off", client);
	menu.AddItem(isAll ? "kD" : "kE", applyMsg);
	
	menu.ExitButton = true;
	
	menu.Display(client, MENU_TIME_FOREVER);
}

// GenerateWeaponMenu() - Generates a menu that lets you see the details of the selected weapon, and set them accordingly.
void GenerateWeaponMenu(int client, int slot)
{
	Menu menu = new Menu(WeaponHdlr);
	
	char title[20];
	bool isAll = Ks[client].all;
	
	if (!isAll) {
		char slotStr[32];
		Format(slotStr, sizeof(slotStr), "Ks_Slot_%d", slot + 1);
		
		Format(title, sizeof(title), "%T", slotStr, client);
	}
	else
		Format(title, sizeof(title), "%T", "Ks_Slot_All", client);
	
	menu.SetTitle("%T", "Ks_Edit_MenuTitle", client, title);
	
	int 	type = Ks[client].type[slot], 			sheen = Ks[client].sheen[slot], 			streaker = Ks[client].streaker[slot];
	char 	typeStr[64], 							sheenStr[64], 								streakerStr[64];
	
	char temp[64];
	Format(temp, sizeof(temp), "Ks_Edit_Killstreak%d", type);
	Format(temp, sizeof(temp), "%T", temp, client);
	
	Format(typeStr, sizeof(typeStr), "%T", "Ks_Edit_Killstreak", client, temp);
	
	menu.AddItem("type", typeStr);
	
	if (type > 1) {
		Format(temp, sizeof(temp), "Ks_Edit_Sheen%d", sheen);
		Format(temp, sizeof(temp), "%T", temp, client);
		
		Format(sheenStr, sizeof(sheenStr), "%T", "Ks_Edit_Sheen", client, temp);
		
		menu.AddItem("sheen", sheenStr);
		
		if (type > 2) {
			Format(temp, sizeof(temp), "Ks_Edit_Streaker%d", (streaker == 0) ? 2001 : streaker);
			Format(temp, sizeof(temp), "%T", temp, client);
			
			Format(streakerStr, sizeof(streakerStr), "%T", "Ks_Edit_Streaker", client, temp);
			
			menu.AddItem("streaker", streakerStr);
		}
	}
	
	menu.AddItem("-", "----------------------------------", ITEMDRAW_DISABLED);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// GenerateEffectsMenu() - This generates the menus utilized to select effects on weapons.
void GenerateEffectsMenu(int client, bool showStr = false)
{
	/////////////////////////////////////////////////
	// SHEENS MENU
	Menu m1 = new Menu(SheenHdlr);
	
	m1.SetTitle("%T", "Ks_Edit_Sheen_MenuTitle", client);
	
	for (int i = 0; i < MAX_SHEENS; i++) {
		// SourcePawn strings are a pain in the ass to manage
		char info[32], sheen[64];
		Format(info, sizeof(info), "%d", i);
		
		Format(sheen, sizeof(sheen), "Ks_Edit_Sheen%d", i);
		Format(sheen, sizeof(sheen), "%T", sheen, client);
		
		m1.AddItem(info, sheen);
	}
	
	m1.ExitButton = true;
	
	if (!showStr)
		m1.Display(client, MENU_TIME_FOREVER);
	/////////////////////////////////////////////////
	// KILLSTREAKER MENU
	Menu m2 = new Menu(StreakerHdlr);
	
	m2.SetTitle("%T", "Ks_Edit_Streaker_MenuTitle", client);

	for (int i = 2001; i < (MAX_STREAKERS + 2001); i++) {
		char info[32], streaker[64];
		Format(info, sizeof(info), "%d", i);
		
		Format(streaker, sizeof(streaker), "Ks_Edit_Streaker%d", i);
		Format(streaker, sizeof(streaker), "%T", streaker, client);
		
		m2.AddItem(info, streaker);
	}
	
	m2.ExitButton = true;
	
	if (showStr)
		m2.Display(client, MENU_TIME_FOREVER);
	/////////////////////////////////////////////////
}

// ApplyKillstreak() - Applies corresponding killstreak effects on each weapon indicated.
void ApplyKillstreak(int client)
{
	int entity[3] = INVALID_ENT_REFERENCE;
	
	for (int i = 0; i < sizeof(entity); i++) {
		entity[i] = GetPlayerWeaponSlot(client, i);
		
		int type = Ks[client].type[i], sheen = Ks[client].sheen[i], streaker = Ks[client].streaker[i];
		if (entity[i] != INVALID_ENT_REFERENCE) {
			if (type > 0) {
				TF2Attrib_SetByDefIndex(entity[i], 2025, float(type));
				if (type > 1) {
					TF2Attrib_SetByDefIndex(entity[i], 2014, float(sheen));
					if (type > 2)
						TF2Attrib_SetByDefIndex(entity[i], 2013, float(streaker));
				}
			}
		}
	}
}

// RemoveKilltreak() - Removes Killstreak effects off clients depending on their type.
void RemoveKillstreak(int client, int type)
{
	int entity[3] = INVALID_ENT_REFERENCE;
	
	for (int i = 0; i < sizeof(entity); i++) {
		entity[i] = GetPlayerWeaponSlot(client, i);
		
		if (entity[i] != INVALID_ENT_REFERENCE) {
			int ids[3] =  { 2014, 2013, 2025 }, len = 0;
			switch (type) {
				case 0:
					len = 3;
				case 1:
					len = 2;
				case 2:
					len = 1;
			}
			
			for (int x = 0; x < len; x++) {
				TF2Attrib_SetByDefIndex(entity[i], ids[x], 0.0);
				TF2Attrib_RemoveByDefIndex(entity[i], ids[x]);
			}
		}
	}
}