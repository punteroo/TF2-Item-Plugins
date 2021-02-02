#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>

// Custom made "class" for unusual clients
#include <unusual-class.inc>
#include "custom-includes/paintcosmetics.inc"

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.0.0"

public Plugin myinfo = 
{
	name = "[VIP Module] Unusual Manager",
	author = "Lucas 'puntero' Maza",
	description = "Gives the ability for users to customize unusual effects on their hats!",
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

/////////////////////
// GLOBAL DECLARES //
/////////////////////

// Global Regeneration SDKCall Handle (Used to update items the player has)
Handle hRegen = INVALID_HANDLE;

// Valid Equip Regions for Unusual items (to prevent weird unusual items such as an unusual flapjack)
char validRegions[8][24] =  { "pyro_head_replacement", "hat", "face", "glasses", "beard", "whole_head", "lenses", "head_skin" };

// Per Client unusual effect chosen and ID
UnusualClient Unu[MAXPLAYERS + 1];

// Per Client painted hat information, first dimension is Client Index, second dimension is Hat Slot.
PaintedHat PPlayer[MAXPLAYERS + 1][3];

// Global effects Menu
// it's always static, so generate it only once.
Menu effMenu;

// Networkable Server Offsets (used for regen)
int clipOff;
int ammoOff;

/////////////////////
/////////////////////
/////////////////////

public void OnPluginStart()
{
	RegAdminCmd("sm_unusual", 	CMD_Unusual, ADMFLAG_RESERVATION, "Opens the Unusual menu.");
	RegAdminCmd("sm_unu", 		CMD_Unusual, ADMFLAG_RESERVATION, "Opens the Unusual menu.");
	RegAdminCmd("sm_inusual", 	CMD_Unusual, ADMFLAG_RESERVATION, "Opens the Unusual menu.");
	// Various ways of invoking the command. For user commodity ;)
	
	Handle hGameConf = LoadGameConfigFile("sm-tf2.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "Regenerate");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	
	hRegen = EndPrepSDKCall();
	// This piece of code makes an SDKCall for the Regenerate function inside the game's gamedata.
	// Refreshes the entire player to ensure Unusuals take effect instantly.
	
	EffectsMenu();
	// Generates the effects menu (with all the unusual effects available)
}

public void OnMapStart()
{
	for (int i = 0; i < sizeof(Unu); i++) {
		delete Unu[i];
		CloseHandle(Unu[i]);
	}
	
	delete effMenu;
	
	EffectsMenu();
}

public void OnClientConnected(int client)
{
	// Generate a new UnusualClient handle for the player.
	Unu[client] = new UnusualClient();
	Unu[client].Initialize();
}

public void OnClientDisconnect(int client)
{
	// Empty the old Unusual slot for new players joining.
	delete Unu[client];
	CloseHandle(Unu[client]);
}

public Action CMD_Unusual(int client, int args)
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
			
			int id = StringToInt(sel);
			if (id > 0) {
				Unu[client].SetSlot(p2);
				Unu[client].SetId(id);
				
				DisplayMenu(effMenu, client, MENU_TIME_FOREVER);
			}
		}
	}
	return 0;
}

public int EffectHdlr(Menu menu, MenuAction action, int client, int p2)
{
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));

			Unu[client].SetUnusual(StringToFloat(sel));
			
			ForceChange(client);
		}
	}
	return 0;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle& hItem)
{
	// This is where the magic happens :)
	// First check if it's a hat and not any weapon or item.
	if ((StrEqual(classname, "tf_wearable")) && !IsWearableWeapon(iItemDefinitionIndex) && IsHatUnusual(iItemDefinitionIndex)) {
		for (int i = 0; i < 3; i++) {
			float unusual = Unu[client].GetUnusual(i);
			
			int id = Unu[client].GetId(i);
			if ((iItemDefinitionIndex == id) && (unusual > 0.0)) {
				int flags = OVERRIDE_ALL | FORCE_GENERATION;
				
				hItem = TF2Items_CreateItem(flags);
				
				TF2Items_SetClassname(hItem, classname);
				TF2Items_SetItemIndex(hItem, iItemDefinitionIndex);
				TF2Items_SetLevel(hItem, 69);
				
				TF2Items_SetQuality(hItem, 5);
				
				TF2Items_SetNumAttributes(hItem, 4);
				
				TF2Items_SetAttribute(hItem, 0, 134, unusual);
				
				int attribs[3] =  { 142, 261, 1004 };
				for (int j = 0; j < sizeof(attribs); j++) {
					float paints[3];
					PPlayer[client][j].WriteValues(paints);
					
					if (PPlayer[client][j].hatIndex == iItemDefinitionIndex) {
						for (int k = 0; k < sizeof(paints); k++) {
							if (paints[k] > 0.0)
								TF2Items_SetAttribute(hItem, k + 1, attribs[k], paints[k]);
						}
					}
				}
				
				return Plugin_Changed;
			}
			continue;
		}
	}
	return Plugin_Continue;
}



													///////////////////////////////////////////////////////////////////////
													///////////////////////////////////////////////////////////////////////
													// Below this section lie my beautiful (horrendous) custom functions.//
													// 						Laughing is allowed.		 				 //
													///////////////////////////////////////////////////////////////////////
													///////////////////////////////////////////////////////////////////////



// GenerateHatsMenu() - Generates the first menu where the player's hats are listed
void GenerateHatsMenu(int client)
{
	Menu menu = CreateMenu(MainHdlr);
	
	SetMenuTitle(menu, "Unusual Hat Manager");

	int hat = -1, found = 0;
	while ((hat = FindEntityByClassname(hat, "tf_wearable")) != -1) {
		if ((hat != INVALID_ENT_REFERENCE) && (GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client)) {
			int id = GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex");
			
			if (IsHatUnusual(id)) {
				char idStr[12], hatName[42];
				IntToString(id, idStr, sizeof(idStr));
				TF2IDB_GetItemName(id, hatName, sizeof(hatName));
				
				AddMenuItem(menu, idStr, hatName);
				found++;
			}
		}
	}
	if (!found) {
		AddMenuItem(menu, "-", "No se encontraron hats compatibles.", ITEMDRAW_DISABLED);
	}
	
	AddMenuItem(menu, "-", "Uso: Selecciona tu hat equipado y el efecto deseado.", ITEMDRAW_DISABLED);
	
	AddMenuItem(menu, "-", "- - - - - - - - - - - - - - - - - -", ITEMDRAW_DISABLED);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

// EffectsMenu() - Generates the effects menu. This is done always on start.
void EffectsMenu()
{
	effMenu = CreateMenu(EffectHdlr);
	
	SetMenuTitle(effMenu, "Seleccionar Efecto");
	
	AddUnusuals(effMenu);
	
	SetMenuExitButton(effMenu, true);
}

// ForceChange() - Forces an SDKCall on the player to get the Unusual effects to be applied instantly.
void ForceChange(int client)
{	
	int ent = -1, hatsC = 0;
	while ((ent = FindEntityByClassname(ent, "tf_wearable")) != INVALID_ENT_REFERENCE) {		
		if (client == GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")) {
			int itemDef = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
			
			if (IsHatPaintable(itemDef)) {
				float val[16];
				int   ids[16];
				int   amount = TF2Attrib_GetSOCAttribs(ent, ids, val);
				
				float paints[3];
				GetPaint(val, ids, amount, paints);
				
				for (int i = 0; i < 3; i++)
					PPlayer[client][hatsC].values[i] = paints[i];
				PPlayer[client][hatsC].hatIndex = itemDef;
				
				hatsC++;
			}
			
			AcceptEntityInput(ent, "Kill");
		}
	}
	
	CreateTimer(0.06, ForceTimer, client);
}

// ForceChange's timer callback
public Action ForceTimer(Handle timer, any client)
{
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
	
	GenerateHatsMenu(client);
}

// IsHatUnusual() - Retrieves wether the current worn hat CAN have an Unusual effect.
// @ int iItemDefinitionIndex	- The Item Index for the hat being tested.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// @return bool					- True if the hat can be Unusual, false if not.
bool IsHatUnusual(int iItemDefinitionIndex)
{
	Handle region = TF2IDB_GetItemEquipRegions(iItemDefinitionIndex);
	
	if (region != INVALID_HANDLE) {
		for (int i = 0; i < GetArraySize(region); i++) {
			char regionStr[32];
			GetArrayString(region, i, regionStr, sizeof(regionStr));
			
			// VALID EQUIP REGIONS FOR UNUSUALS: pyro_head_replacement, hat, face, glasses, beard, whole_head, lenses, head_skin
			// Contained in the string array validRegions
			for (int x = 0; x < sizeof(validRegions); x++) {
				if (StrEqual(regionStr, validRegions[x], false)) {
					delete region;
					return true;
				}
				continue;
			}
		}
	}
	delete region;
	return false;
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