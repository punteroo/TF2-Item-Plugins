#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

// Custom made "class" (actually a methodmap) to manage user selections.
#include <killstreak-class>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

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

// Sheen names array
char Sheens[8][32] = {
	"None", "Team-Shine", "Deadly Daffodil", "Manndarin", "Mean Green", "Agonizing Emerald", "Villainous Violet", "Hot Rod"
};

// Killstreaker names array
char Streakers[8][32] = {
	"None", "Fire Horns", "Cerebral Discharge", "Tornado", "Flames", "Singularity", "Incinerator", "Hypno-Beam"
};

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
}

public void OnMapStart()
{
	for (int i = 0; i < sizeof(Ks); i++)
		delete Ks[i];
}
public void OnClientPostAdminCheck(int client)
{
	// We need to create a KsClient object for clients that join.
	// I planned to do this only for the ones who have CUSTOM1 flag access, but because of admin cache reloads i'll just assign it to everyone.
	// Also initialize values so we avoid any errors.
	Ks[client] = new KsClient();
	Ks[client].Initialize();
}

public void OnClientDisconnect(int client)
{
	// If he has disconnected, empty this object slot so we don't occupy any extra memory.
	delete Ks[client];
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
				Ks[client].AllWeapons(!Ks[client].IsAllMode());
				
				GenerateMenu(client);
			}
			else {
				int slot = StringToInt(sel);
				Ks[client].SetSlot(slot);
				
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
				float type[3];
				Ks[client].GetType(type);
				
				int slot = Ks[client].GetSlot();
				
				type[slot] += 1.0;
				Ks[client].SetType((0.0 <= type[slot] <= 3.0) ? type[slot] : 0.0, slot);
				
				SetClientKillstreak(client, type[slot], slot);
				
				switch (RoundToFloor(type[slot])) {
					case 0, 1, 2: {
						if (IsPlayerAlive(client) && IsClientInGame(client))
							RemoveKillstreak(client, RoundToFloor(type[slot]));
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
			
			int slot = Ks[client].GetSlot();
			
			Ks[client].SetSheen(StringToFloat(sel), slot);
			
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
			
			int slot = Ks[client].GetSlot();
			
			Ks[client].SetStreaker(StringToFloat(sel), slot);
			
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
void SetClientKillstreak(int client, float type, int slot = 0)
{
	// This function all it does is reset Sheen values and Killstreaker values whenever the client switches types of killstreaks.
	// Since we support All Weapons Mode, there is a different method for either.
	// Makes this block kind of repetitive but it doesn't matter.
	
	// First check if the client has All Weapons Mode enabled.
	if (Ks[client].IsAllMode()) {
		// If he does, we'll loop through all the slots and set them to 0.
		for (int i = 0; i < 3; i++) {
			// Use as an Integer to avoid 0.0 or 1.0
			switch (RoundToFloor(type)) {
				case 0, 1: {
					// If he has no Killstreak enabled or a Normal Killstreak, empty Sheen and Killstreaker values.
					Ks[client].SetSheen(0.0, i);
					Ks[client].SetStreaker(0.0, i);
				}
				case 2:
					// If he has a Specialized Killstreak, empty only the Sheen value.
					Ks[client].SetStreaker(0.0, i);
			}
		}
	}
	// Same goes here, except it's just for one specific slot.
	else {
		switch (RoundToFloor(type)) {
			case 0, 1: {
				Ks[client].SetSheen(0.0, slot);
				Ks[client].SetStreaker(0.0, slot);
			}
			case 2:
				Ks[client].SetStreaker(0.0, slot);
		}
	}
}
// GenerateMenu() - Generates a menu with the client's weapons, and displays it to them. This allows them to choose individual weapon effects.
void GenerateMenu(int client)
{
	Menu menu = CreateMenu(MainHdlr);
	
	SetMenuTitle(menu, "Killstreak Manager");
	
	bool isAll = Ks[client].IsAllMode();
	
	if (!isAll) {
		AddMenuItem(menu, "0", "Slot primario");
		AddMenuItem(menu, "1", "Slot secundario");
		AddMenuItem(menu, "2", "Slot melee");
	}
	else
		AddMenuItem(menu, "0", "Todas las Armas");
	
	AddMenuItem(menu, "-", "-----------------", ITEMDRAW_DISABLED);
	
	isAll ? AddMenuItem(menu, "kD", "Aplicar en todo: Sí") : AddMenuItem(menu, "kE", "Aplicar en todo: No");
	
	AddMenuItem(menu, "---", "Created by puntero @ 2020.", ITEMDRAW_DISABLED);
	
	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

// GenerateWeaponMenu() - Generates a menu that lets you see the details of the selected weapon, and set them accordingly.
void GenerateWeaponMenu(int client, int slot)
{
	Menu menu = CreateMenu(WeaponHdlr);
	
	char title[20];
	bool isAll = Ks[client].IsAllMode();
	
	if (!isAll) {
		switch (slot) {
			case 0:
				Format(title, sizeof(title), "Arma Primaria");
			case 1:
				Format(title, sizeof(title), "Arma Secundaria");
			case 2:
				Format(title, sizeof(title), "Arma Melee");
		}
	}
	else
		Format(title, sizeof(title), "Todas las Armas");
	
	SetMenuTitle(menu, "Configurando: %s", title);
	
	float 	type[3], 		sheen[3], 		streaker[3];
	char 	typeStr[64], 	sheenStr[64], 	streakerStr[64];
	Ks[client].GetType(type);
	Ks[client].GetSheen(sheen);
	Ks[client].GetStreaker(streaker);
	
	switch (RoundToFloor(type[slot])) {
		case 0:
			Format(typeStr, sizeof(typeStr), "Killstreak: Ninguno");
		case 1:
			Format(typeStr, sizeof(typeStr), "Killstreak: Normal");
		case 2:
			Format(typeStr, sizeof(typeStr), "Killstreak: Specialized");
		case 3:
			Format(typeStr, sizeof(typeStr), "Killstreak: Professional");
	}
	AddMenuItem(menu, "type", typeStr);
	
	/*if () {
		Format(sh, sizeof(sh), "Sheen: %s", All ? Sheens[RoundToFloor(KsAllVals[client][1])] : Sheens[RoundToFloor(KsFx[client][slot][0])]);
		AddMenuItem(menu, "sheen", sh);
		
		if ((All ? RoundToFloor(KsAllVals[client][0]) : KsSlots[client][slot]) > 2) {
			Format(st, sizeof(st), "Killstreaker: %s", All ? Streakers[(KsAllVals[client][2] > 2000) ? (RoundToFloor(KsAllVals[client][2]) - 2001) : RoundToFloor(KsAllVals[client][2])] : Streakers[(KsFx[client][slot][1] > 2000) ? (RoundToFloor(KsFx[client][slot][1]) - 2001) : RoundToFloor(KsFx[client][slot][1])]);
			AddMenuItem(menu, "streaker", st);
		}
	}			old shitty code, ignore this shithole			*/
	
	if (type[slot] > 1.0) {
		Format(sheenStr, sizeof(sheenStr), "Sheen: %s", Sheens[RoundToFloor(sheen[slot])]);
		AddMenuItem(menu, "sheen", sheenStr);
		
		if (type[slot] > 2.0) {
			Format(streakerStr, sizeof(streakerStr), "Killstreaker: %s", Streakers[RoundToFloor((streaker[slot] > 2000) ? (streaker[slot] - 2001) : streaker[slot])]);
			AddMenuItem(menu, "streaker", streakerStr);
		}
	}
	
	AddMenuItem(menu, "-", "----------------------------------", ITEMDRAW_DISABLED);
	
	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

// GenerateEffectsMenu() - This generates the menus utilized to select effects on weapons.
void GenerateEffectsMenu(int client, bool showStr = false)
{
	/////////////////////////////////////////////////
	// SHEENS MENU
	Menu m1 = CreateMenu(SheenHdlr);
	
	SetMenuTitle(m1, "Seleccionar Sheen");
	
	for (int i = 0; i < sizeof(Sheens); i++) {
		// SourcePawn strings are a pain in the ass to manage
		char info[32];
		Format(info, sizeof(info), "%d", i);
		
		AddMenuItem(m1, info, Sheens[i]);
	}
	
	SetMenuExitButton(m1, true);
	
	if (!showStr)
		DisplayMenu(m1, client, MENU_TIME_FOREVER);
	/////////////////////////////////////////////////
	// KILLSTREAKER MENU
	Menu m2 = CreateMenu(StreakerHdlr);
	
	SetMenuTitle(m2, "Selecionar Killstreaker");

	for (int i = 2001; i < (sizeof(Streakers) + 2001); i++) {
		char info[32];
		Format(info, sizeof(info), "%d", i);
		
		AddMenuItem(m2, info, Streakers[i - 2001]);
	}
	
	SetMenuExitButton(m2, true);
	
	if (showStr)
		DisplayMenu(m2, client, MENU_TIME_FOREVER);
	/////////////////////////////////////////////////
}

// ApplyKillstreak() - Applies corresponding killstreak effects on each weapon indicated.
void ApplyKillstreak(int client)
{
	int entity[3] = INVALID_ENT_REFERENCE;
	
	float types[3], sheens[3], streakers[3];
	Ks[client].GetType(types);
	Ks[client].GetSheen(sheens);
	Ks[client].GetStreaker(streakers);
	
	for (int i = 0; i < sizeof(entity); i++) {
		entity[i] = GetPlayerWeaponSlot(client, i);
		
		if (entity[i] != INVALID_ENT_REFERENCE) {
			if (types[i] > 0.0) {
				TF2Attrib_SetByDefIndex(entity[i], 2025, types[i]);
				if (types[i] > 1.0) {
					TF2Attrib_SetByDefIndex(entity[i], 2014, sheens[i]);
					if (types[i] > 2.0)
						TF2Attrib_SetByDefIndex(entity[i], 2013, streakers[i]);
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