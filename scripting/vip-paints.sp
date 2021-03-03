#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <tf2idb>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.3.2"

#define MAX_PAINTS 30

public Plugin myinfo = 
{
	name = "[VIP Module] Hat Painter",
	author = "Lucas 'puntero' Maza",
	description = "Lets users paint their hats respectively.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=213425"
};

enum struct PaintPlayer {
	// This enum controls a player's painted hats status.
	// A maximum of 3 painted hats can be used at a time.
	
	// Paint values stored from player selections.
	float values[3];
	// Hat m_iItemDefinitionIndex
	int   hats[3];
	
	// Temporary slot variable to keep track of selections during apply.
	int   tSlot;
	
	// Did the user choose a team-colored paint?
	bool  hasTeamPaint;
	// Team ID the player currently has.
	int   teamIndex;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_TF2)
	{
		SetFailState("This plugin was made for use with Team Fortress 2 only.");
	}
}

// GLOBALS /////////////////////////////////////////////

// Per-Player PaintPlayer object, this allows a "smoother" management of the paints applied.
PaintPlayer PPlayer[MAXPLAYERS + 1];

// Global Regeneration SDKCall
Handle hRegen = INVALID_HANDLE;

// Networkable Server Offsets (used for regen)
int clipOff;
int ammoOff;

// Paint Values (individual colors)
int paintColors[23] = {
	0, 7511618, 4345659, 5322826, 14204632, 8208497, 13595446, 10843461, 12955537, 6901050, 8154199, 15185211, 8289918, 15132390,
	1315860, 16738740, 3100495, 8421376, 3329330, 15787660, 15308410, 12377523, 2960676
};

// Paint Values (team colors)
int teamColors[7][2] = {
	{12073019, 5801378}, {4732984, 3686984}, {11049612, 8626083}, {3874595, 1581885}, {6637376, 2636109}, {8400928, 2452877}, {12807213, 12091445}
};

////////////////////////////////////////////////////////

public void OnPluginStart()
{
	RegAdminCmd("sm_paint", CMD_Paint, ADMFLAG_RESERVATION, "Opens the Paint Menu.");
	
	Handle hGameConf = LoadGameConfigFile("sm-tf2.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "Regenerate");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	
	hRegen = EndPrepSDKCall();
	// This piece of code makes an SDKCall for the Regenerate function inside the game's gamedata.
	// Refreshes the entire player to ensure Unusuals take effect instantly.
	
	LoadTranslations("paints.phrases.txt");
	// Translations !
}

public Action CMD_Paint(int client, int args)
{
	GenerateHatsMenu(client);
	
	return Plugin_Handled;
}

public int MainHdlr(Menu menu, MenuAction action, int client, int p2)
{
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			int slot = p2, id = StringToInt(sel);
			
			PPlayer[client].tSlot = slot;
			PPlayer[client].hats[slot] = id;
			
			GeneratePaintsMenu(client);
		}
	}
	return 0;
}

public int PaintMgr(Menu menu, MenuAction action, int client, int p2)
{
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			int slot = PPlayer[client].tSlot;
			
			bool isTeam = (StrContains(sel, "t", false) != -1);
			
			PPlayer[client].values[slot] = isTeam ? -1.0 : StringToFloat(sel);
			
			PPlayer[client].hasTeamPaint = isTeam;
			PPlayer[client].teamIndex = (isTeam ? (p2 - 23) : 0);
			
			AdministerPaint(client);
		}
	}
	return 0;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle& hItem)
{
	if (StrEqual(classname, "tf_wearable", false) && !IsWearableWeapon(iItemDefinitionIndex)) {
		for (int i = 0; i < 3; i++) {
			int hatId = PPlayer[client].hats[i];
			
			if (hatId > 0 && iItemDefinitionIndex == hatId) {
				float paint = PPlayer[client].values[i];
				
				int flags = OVERRIDE_ALL | FORCE_GENERATION;
					
				hItem = TF2Items_CreateItem(flags);
					
				TF2Items_SetClassname(hItem, classname);
				TF2Items_SetItemIndex(hItem, iItemDefinitionIndex);
				TF2Items_SetLevel(hItem, GetRandomInt(0, 126));
					
				TF2Items_SetQuality(hItem, 6);
				
				int numAttribs = (paint > 0.0) ? 1 : (paint == -1.0) ? 2 : 0;
				
				if (numAttribs) {
					TF2Items_SetNumAttributes(hItem, numAttribs);
					
					int attribs[2] =  { 142, 261 }, paintIndex = PPlayer[client].teamIndex;
					for (int x = 0; x < numAttribs; x++)
						TF2Items_SetAttribute(hItem, x, attribs[x], (paint == -1.0) ? float(teamColors[paintIndex][x]) : paint);
					
					return Plugin_Changed;
				}
			}
			continue;
		}
	}
	return Plugin_Continue;
}



// AdministerPaint() - Regenerates the player with the new paint applied on their selected wearables.
void AdministerPaint(int client)
{
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_wearable")) != INVALID_ENT_REFERENCE) {
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client) {
			AcceptEntityInput(ent, "Kill");
		}
	}
	CreateTimer(0.06, PaintTimer, client);
}

public Action PaintTimer(Handle timer, any client)
{
	if (IsPlayerAlive(client)) {
		int hp = GetClientHealth(client), clip[2], ammo[2];
		
		clipOff = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		ammoOff = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		
		float uber = -1.0;
		
		if (TF2_GetPlayerClass(client) == TFClass_Medic)
			uber = GetEntPropFloat(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_flChargeLevel");
		
		for (int i = 0; i < sizeof(clip); i++) {
			int wep = GetPlayerWeaponSlot(client, i);
			if (wep != INVALID_ENT_REFERENCE) {
				int ammoOff2 = GetEntProp(wep, Prop_Send, "m_iPrimaryAmmoType", 1) * 4 + ammoOff;
				
				clip[i] = GetEntData(wep, clipOff);
				ammo[i] = GetEntData(wep, ammoOff2);
			}
		}
		
		// Regenerate the player (SDK Call)
		SDKCall(hRegen, client, 0);
		
		SetEntityHealth(client, hp);
		if (uber > -1.0)
			SetEntPropFloat(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_flChargeLevel", uber);
		
		for (int i = 0; i < sizeof(clip); i++) {
			int wep = GetPlayerWeaponSlot(client, i);
			if (wep != INVALID_ENT_REFERENCE) {
				int ammoOff2 = GetEntProp(wep, Prop_Send, "m_iPrimaryAmmoType", 1) * 4 + ammoOff;
				
				SetEntData(wep, clipOff, clip[i]);
				SetEntData(wep, ammoOff2, ammo[i]);
			}
		}
	}
	delete timer;
}

// GenerateHatsMenu() - Generates the first menu where the player's hats are listed
void GenerateHatsMenu(int client)
{
	Menu menu = new Menu(MainHdlr);
	
	menu.SetTitle("%T", "Paint_MenuTitle", client);

	int hat = -1, found = 0;
	while ((hat = FindEntityByClassname(hat, "tf_wearable")) != -1) {
		if ((hat != INVALID_ENT_REFERENCE) && (GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client)) {
			int id = GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex");
			
			char query[64], idStr[16];
			Format(query, sizeof(query), "SELECT capability FROM tf2idb_capabilities WHERE id = ?");
			IntToString(id, idStr, sizeof(idStr));
			
			Handle arguments = CreateArray(sizeof(idStr));
			PushArrayString(arguments, idStr);
			
			DBStatement result = TF2IDB_CustomQuery(query, arguments, 16);
			
			if (result != INVALID_HANDLE) {
				while (SQL_FetchRow(result)) {
					char capability[32];
					SQL_FetchString(result, 0, capability, sizeof(capability));
					
					if (StrEqual(capability, "paintable")) {
						char hatName[42];
						TF2IDB_GetItemName(id, hatName, sizeof(hatName));
						
						menu.AddItem(idStr, hatName);
					}
				}
				found++;
			}
		}
	}
	
	if (!found) {
		char errInc[128];
		Format(errInc, sizeof(errInc), "%T", "Paint_ErrIncompatible", client);
		
		menu.AddItem("-", errInc, ITEMDRAW_DISABLED);
	}
		
	menu.AddItem("-", "- - - - - - - - - - - - - - - - - -", ITEMDRAW_DISABLED);
	
	char usage[128];
	Format(usage, sizeof(usage), "%T", "Paint_Usage", client);
	
	menu.AddItem("-", usage, ITEMDRAW_DISABLED);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// GeneratePaintsMenu(int client) - Displays the available paints to the user.
void GeneratePaintsMenu(int client)
{
	Menu PaintsMenu = new Menu(PaintMgr);
	
	PaintsMenu.SetTitle("%T", "Paint_Edit_MenuTitle", client);
	
	for (int i = 0; i < MAX_PAINTS; i++) {
		char valStr[42], paintName[64];
		(i < sizeof(paintColors)) ? IntToString(paintColors[i], valStr, sizeof(valStr)) : Format(valStr, sizeof(valStr), "t%d", i - 23);
		
		Format(paintName, sizeof(paintName), "Paint%d", i);
		Format(paintName, sizeof(paintName), "%T", paintName, client);
		
		PaintsMenu.AddItem(valStr, paintName);
	}
	
	PaintsMenu.ExitButton = true;
	PaintsMenu.Display(client, MENU_TIME_FOREVER);
}

// IsWearableWeapon() - Checks if the wearable is in a weapon slot (so we don't count it as a hat)
bool IsWearableWeapon(int id)
{
	switch (id) {
		case 133, 444, 405, 608, 231, 642:
			return true;
	}
	return false;
}