#include "tf2items/weapons.sp"

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "3.0.0"

public Plugin myinfo = 
{
	name = "[TF2] Weapons Manager",
	author = "Lucas 'puntero' Maza",
	description = "Gives the ability for users to customize their weapons.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=213425"
};

/////////////////////
// GLOBAL DECLARES //
/////////////////////

// Global Regeneration SDKCall Handle (Used to update items the player has)
Handle hRegen = INVALID_HANDLE;

// Weapon information for every player in the server.
WeaponsInfo pWeapons[MAXPLAYERS + 1];

// Original Weapon Information for every player
Weapon orgWeapons[MAXPLAYERS + 1][3];

// Networkable Server Offsets (used for regen)
int clipOff;
int ammoOff;

// Global Late Loading Value
bool bLateLoad;

/////////////////////
/////////////////////
/////////////////////

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_TF2)
	{
		SetFailState("This plugin was made for use with Team Fortress 2 only.");
	}
	
	bLateLoad = late;
}

public void OnPluginStart() {
	RegAdminCmd("sm_weapons", CMD_Weapons, ADMFLAG_RESERVATION, "Opens the Weapons Manager menu.");
	RegAdminCmd("sm_weps", 	  CMD_Weapons, ADMFLAG_RESERVATION, "Opens the Weapons Manager menu.");
	RegAdminCmd("sm_myweps",  CMD_Weapons, ADMFLAG_RESERVATION, "Opens the Weapons Manager menu.");
	// Various ways of invoking the command. For user commodity ;)
	//RegConsoleCmd("sm_my", CMD_Test);
	
	Handle hGameConf = LoadGameConfigFile("sm-tf2.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "Regenerate");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	
	hRegen = EndPrepSDKCall();
	// This piece of code makes an SDKCall for the Regenerate function inside the game's gamedata.
	// Refreshes the entire player to ensure changes take effect instantly.
	
	LoadTranslations("weapons.phrases.txt");
	// Translations!
	
	if (bLateLoad) {
		for (int i = 1; i < MaxClients; i++) {
			if (IsClientInGame(i) && !IsClientSourceTV(i) && !IsFakeClient(i))
				pWeapons[i].ResetAll();
		}
	}
}

/*public Action CMD_Test(int client, int args) {
	PrintToConsole(client, "Your Overrides:");
	PrintToConsole(client, "Item Indexes:   %d, %d, %d", pWeapons[client].iItemIndex[0], pWeapons[client].iItemIndex[1], pWeapons[client].iItemIndex[2]);
	PrintToConsole(client, "Unusual Weps:   %d, %d, %d", pWeapons[client].uEffects[0], pWeapons[client].uEffects[1], pWeapons[client].uEffects[2]);
	PrintToConsole(client, "War Paint:      %d, %d, %d", pWeapons[client].wPaint[0], pWeapons[client].wPaint[1], pWeapons[client].wPaint[2]);
	PrintToConsole(client, "War Paint Wear: %f, %f, %f", pWeapons[client].wWear[0], pWeapons[client].wWear[1], pWeapons[client].wWear[2]);
	PrintToConsole(client, "Australium?     %d, %d, %d", pWeapons[client].Aussie[0], pWeapons[client].Aussie[1], pWeapons[client].Aussie[2]);
	PrintToConsole(client, "Festivized?     %d, %d, %d", pWeapons[client].Festive[0], pWeapons[client].Festive[1], pWeapons[client].Festive[2]);
	PrintToConsole(client, "Ks. Type:       %d, %d, %d", pWeapons[client].kType[0], pWeapons[client].kType[1], pWeapons[client].kType[2]);
	PrintToConsole(client, "Ks. Sheen:      %d, %d, %d", pWeapons[client].kSheen[0], pWeapons[client].kSheen[1], pWeapons[client].kSheen[2]);
	PrintToConsole(client, "Ks. Streaker:   %d, %d, %d", pWeapons[client].kStreaker[0], pWeapons[client].kStreaker[1], pWeapons[client].kStreaker[2]);
	PrintToConsole(client, "Spell Overr.:   %b, %b, %b", pWeapons[client].sSpells[0], pWeapons[client].sSpells[1], pWeapons[client].sSpells[2]);
	return Plugin_Handled;
}*/

public Action CMD_Weapons(int client, int args) {
	mMainMenu(client);
	return Plugin_Handled;
}

//
// Normal Menus Handlers
////////////////////////
public int mainHdlr(Menu menu, MenuAction action, int client, int p2) {
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			wMainMenu(client, StringToInt(sel), p2);
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}

public int wepHdlr(Menu menu, MenuAction action, int client, int p2) {
	switch (action) {
		case MenuAction_Select: {
			char sel[32], idStr[12], slotStr[4];
			GetMenuItem(menu, 0, idStr, sizeof(idStr));
			GetMenuItem(menu, 1, slotStr, sizeof(slotStr));
			
			int iItemDefinitionIndex = StringToInt(idStr), slot = StringToInt(slotStr);
			
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			switch (sel[0]) {
				case 'a': {
					if (pWeapons[client].iItemIndex[slot] != iItemDefinitionIndex)
						pWeapons[client].ResetFor(slot);
					
					pWeapons[client].iItemIndex[slot] = iItemDefinitionIndex;
					
					pWeapons[client].Aussie[slot] = !pWeapons[client].Aussie[slot];
					wMainMenu(client, iItemDefinitionIndex, slot);
					
					ForceChange(client, slot);
				}
				case 'f': {
					if (pWeapons[client].iItemIndex[slot] != iItemDefinitionIndex)
						pWeapons[client].ResetFor(slot);
					
					pWeapons[client].iItemIndex[slot] = iItemDefinitionIndex;
					
					pWeapons[client].Festive[slot] = !pWeapons[client].Festive[slot];
					wMainMenu(client, iItemDefinitionIndex, slot);
					
					ForceChange(client, slot);
				}
				case 'w': wWarPaint(client, iItemDefinitionIndex, slot);
				case 'k': kKillstreaks(client, iItemDefinitionIndex, slot);
				case 'u': wUnusual(client, iItemDefinitionIndex, slot);
				case 's': wSpells(client, iItemDefinitionIndex, slot);
				case 'r': {
					pWeapons[client].ResetFor(slot);
					
					ForceChange(client, slot);
					
					wMainMenu(client, iItemDefinitionIndex, slot);					
				}
			}
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				mMainMenu(client);
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}

//
// War Paint Handlers
/////////////////////
public int wPaintHdlr(Menu menu, MenuAction action, int client, int p2) {
	char idStr[12], slotStr[4];
	GetMenuItem(menu, 0, idStr, sizeof(idStr));
	GetMenuItem(menu, 1, slotStr, sizeof(slotStr));
	
	int iItemDefinitionIndex = StringToInt(idStr), slot = StringToInt(slotStr);
	
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			switch (sel[0]) {
				case 'p': wWarPaintProtodef(client, iItemDefinitionIndex, slot);
				case 'w': wWarPaintWear(client, iItemDefinitionIndex, slot);
			}
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				wMainMenu(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}

public int wPaintProtoHdlr(Menu menu, MenuAction action, int client, int p2) {
	char idStr[12], slotStr[4];
	GetMenuItem(menu, 0, idStr, sizeof(idStr));
	GetMenuItem(menu, 1, slotStr, sizeof(slotStr));
	
	int iItemDefinitionIndex = StringToInt(idStr), slot = StringToInt(slotStr);
	
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			if (pWeapons[client].iItemIndex[slot] != iItemDefinitionIndex)
				pWeapons[client].ResetFor(slot);
			
			pWeapons[client].iItemIndex[slot] = iItemDefinitionIndex;
			pWeapons[client].wPaint[slot]     = StringToInt(sel);
			
			ForceChange(client, slot);
			
			wWarPaint(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				wWarPaint(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}

public int wWarPaintWearHdlr(Menu menu, MenuAction action, int client, int p2) {
	char idStr[12], slotStr[4];
	GetMenuItem(menu, 0, idStr, sizeof(idStr));
	GetMenuItem(menu, 1, slotStr, sizeof(slotStr));
	
	int iItemDefinitionIndex = StringToInt(idStr), slot = StringToInt(slotStr);
	
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			if (pWeapons[client].iItemIndex[slot] != iItemDefinitionIndex)
				pWeapons[client].ResetFor(slot);
			
			pWeapons[client].iItemIndex[slot] = iItemDefinitionIndex;
			pWeapons[client].wWear[slot]      = StringToFloat(sel);
			
			ForceChange(client, slot);
			
			wWarPaint(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				wWarPaint(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}

//
// Killstreak Handlers
//////////////////////
public int kKillstreakHdlr(Menu menu, MenuAction action, int client, int p2) {
	char idStr[12], slotStr[4];
	GetMenuItem(menu, 0, idStr, sizeof(idStr));
	GetMenuItem(menu, 1, slotStr, sizeof(slotStr));
	
	int iItemDefinitionIndex = StringToInt(idStr), slot = StringToInt(slotStr);
	
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			switch (sel[0]) {
				case 't': {
					int type = pWeapons[client].kType[slot] + 1;
					if (type > 3) type = -1;
					
					if (pWeapons[client].iItemIndex[slot] != iItemDefinitionIndex)
						pWeapons[client].ResetFor(slot);
					
					pWeapons[client].iItemIndex[slot] = iItemDefinitionIndex;
					pWeapons[client].kType[slot] = type;
					
					ForceChange(client, slot);
					
					kKillstreaks(client, iItemDefinitionIndex, slot);
				}
				case 's': kKillstreaksSheen(client, iItemDefinitionIndex, slot);
				case 'k': kKillstreaksKillstreaker(client, iItemDefinitionIndex, slot);
			}
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				wMainMenu(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}

public int kKillstreakSheenHdlr(Menu menu, MenuAction action, int client, int p2) {
	char idStr[12], slotStr[4];
	GetMenuItem(menu, 0, idStr, sizeof(idStr));
	GetMenuItem(menu, 1, slotStr, sizeof(slotStr));
	
	int iItemDefinitionIndex = StringToInt(idStr), slot = StringToInt(slotStr);
	
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			if (pWeapons[client].iItemIndex[slot] != iItemDefinitionIndex)
				pWeapons[client].ResetFor(slot);
			
			pWeapons[client].iItemIndex[slot] = iItemDefinitionIndex;
			pWeapons[client].kSheen[slot] = StringToInt(sel);
			
			ForceChange(client, slot);
			
			kKillstreaks(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				kKillstreaks(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}

public int kKillstreakKillstreakerHdlr(Menu menu, MenuAction action, int client, int p2) {
	char idStr[12], slotStr[4];
	GetMenuItem(menu, 0, idStr, sizeof(idStr));
	GetMenuItem(menu, 1, slotStr, sizeof(slotStr));
	
	int iItemDefinitionIndex = StringToInt(idStr), slot = StringToInt(slotStr);
	
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			if (pWeapons[client].iItemIndex[slot] != iItemDefinitionIndex)
				pWeapons[client].ResetFor(slot);
			
			pWeapons[client].iItemIndex[slot] = iItemDefinitionIndex;
			pWeapons[client].kStreaker[slot]  = StringToInt(sel);
			
			ForceChange(client, slot);
			
			kKillstreaks(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				kKillstreaks(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}

//
// Unusual Effect Handlers
//////////////////////////
public int wUnusualHdlr(Menu menu, MenuAction action, int client, int p2) {
	char idStr[12], slotStr[4];
	GetMenuItem(menu, 0, idStr, sizeof(idStr));
	GetMenuItem(menu, 1, slotStr, sizeof(slotStr));
	
	int iItemDefinitionIndex = StringToInt(idStr), slot = StringToInt(slotStr);
	
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			if (pWeapons[client].iItemIndex[slot] != iItemDefinitionIndex)
				pWeapons[client].ResetFor(slot);
			
			pWeapons[client].iItemIndex[slot] = iItemDefinitionIndex;
			pWeapons[client].uEffects[slot] = StringToInt(sel);
			
			ForceChange(client, slot);
			
			wMainMenu(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				wMainMenu(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}

//
// Halloween Spells Handlers
/////////////////////////////
public int wSpellsHdlr(Menu menu, MenuAction action, int client, int p2) {
	char idStr[12], slotStr[4];
	GetMenuItem(menu, 0, idStr, sizeof(idStr));
	GetMenuItem(menu, 1, slotStr, sizeof(slotStr));
	
	int iItemDefinitionIndex = StringToInt(idStr), slot = StringToInt(slotStr);
	
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			if (pWeapons[client].iItemIndex[slot] != iItemDefinitionIndex)
				pWeapons[client].ResetFor(slot);
			
			pWeapons[client].iItemIndex[slot] =  iItemDefinitionIndex;
			
			int spells = pWeapons[client].sSpells[slot];
			
			switch (sel[0]) {
				case 'e': spells = (spells & WeaponSpell_Exorcism)      	 ? (spells ^ WeaponSpell_Exorcism)      	 : (spells | WeaponSpell_Exorcism);
				case 'r': spells = (spells & WeaponSpell_SquashRockets) 	 ? (spells ^ WeaponSpell_SquashRockets) 	 : (spells | WeaponSpell_SquashRockets);
				case 's': spells = (spells & WeaponSpell_SentryQuadPumpkins) ? (spells ^ WeaponSpell_SentryQuadPumpkins) : (spells | WeaponSpell_SquashRockets);
				case 'g': spells = (spells & WeaponSpell_GourdGrenades) 	 ? (spells ^ WeaponSpell_GourdGrenades)   	 : (spells | WeaponSpell_GourdGrenades);
				case 'f': spells = (spells & WeaponSpell_SpectralFlames)     ? (spells ^ WeaponSpell_SpectralFlames)     : (spells | WeaponSpell_SpectralFlames);
			}
			
			pWeapons[client].sSpells[slot] = spells;
			
			ForceChange(client, slot);
			
			wSpells(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				wMainMenu(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}



//
// TF2Items Callback
////////////////////

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle& hItem)
{
	// Ignore cosmetic items.
	if (StrContains(classname, "tf_wearable", false) != -1) return Plugin_Continue;
	
	// Turn the item ID into the strange variant just to be sure.
	bool changed = StockToStrange(iItemDefinitionIndex);
	
	// Time to check for weapons.
	for (int i = 0; i < 3; i++) {
		int overItemIndex = pWeapons[client].iItemIndex[i];
		
		// Override detected for this item ID?
		if (overItemIndex == iItemDefinitionIndex) {
			// Declare item flags
			int flags = OVERRIDE_ALL | PRESERVE_ATTRIBUTES | FORCE_GENERATION;
			
			// For some reason, if it's an allclass melee it requires the FORCE_GENERATION flag
			if (StrContains(classname, "saxxy", false) != -1)
				flags |= FORCE_GENERATION;
			
			// Is this a class based weapon? This is only for Shotgun weapons.
			//  Shotgun variants:
			//		tf_weapon_shotgun_hwg     - Heavy Shotgun
			//		tf_weapon_shotgun_pyro    - Pyro Shotgun
			//		tf_weapon_shotgun_soldier - Soldier Shotgun
			//		tf_weapon_shotgun_primary - Engineer Shotgun
			bool classWep = (iItemDefinitionIndex == 199);
			
			// Find the class based classname for this weapon and set it.
			if (classWep) {
				switch (TF2_GetPlayerClass(client)) {
					case TFClass_Soldier:  strcopy(classname, 64, "tf_weapon_shotgun_soldier");
					case TFClass_Pyro:     strcopy(classname, 64, "tf_weapon_shotgun_pyro");
					case TFClass_Heavy:    strcopy(classname, 64, "tf_weapon_shotgun_hwg");
					case TFClass_Engineer: strcopy(classname, 64, "tf_weapon_shotgun_primary");
				}
			}
			
			// Is this a Stock->Strange transformation?
			if (changed) {
				// Create a DataPack to send through the timer for the strange variant.
				DataPack pack = new DataPack();
				
				pack.WriteCell(client);
				pack.WriteCell(iItemDefinitionIndex);
				pack.WriteString(classname);
				pack.WriteCell(i);
				pack.WriteCell(flags);
				
				// Create the timer to fire 1ms after this callback is invoked
				CreateTimer(0.01, HandleStrange, pack);
				
				// Return Plugin_Handled to stop the original stock item from being given in the first place.
				return Plugin_Handled;
			} else // Else just apply normal changes if this is not a stock ID.
				return ApplyChanges(hItem, client, iItemDefinitionIndex, classname, i, flags, false);
		}
	}
	// No overrides, just give normally!
	return Plugin_Continue;
}

// Apply the m_bValidatedAttachedEntity property on all given weapons
// This property makes these weapons be visible to everyone on the server (great valve!)
public void TF2Items_OnGiveNamedItem_Post(int client, char[] classname, int iItemDefinitionIndex, int itemLevel, int itemQuality, int entityIndex) {
	if (HasEntProp(entityIndex, Prop_Send, "m_bValidatedAttachedEntity"))
		SetEntProp(entityIndex, Prop_Send, "m_bValidatedAttachedEntity", 1);
}

// Handle the Strange Variant to give.
public Action HandleStrange(Handle timer, DataPack pack) {
	// Null the timer (prevent Handle leaks)
	timer = null;
	
	// Reset DataPack to position 0
	pack.Reset();
	
	// Read in order: client, item id, classname, slot, flags
	int client = pack.ReadCell(), iItemDefinitionIndex = pack.ReadCell();
	
	char classname[64];
	pack.ReadString(classname, sizeof(classname));
	
	int slot = pack.ReadCell(), flags = pack.ReadCell();
	
	// Set-up the new weapon (strange variant of the stock)
	GiveStrangeWeapon(client, iItemDefinitionIndex, classname, slot, flags);
	
	// Clean the timer.
	return Plugin_Stop;
}

// Applies all attributes from overrides on the hItem handle and returns the proper response accordingly.
Action ApplyChanges(Handle& hItem, int client, int iItemDefinitionIndex, char[] classname, int slot, int flags, bool isNew = false) {
	hItem = TF2Items_CreateItem(flags);
			
	// Set the same ID (if it was stock it will now be the strange variant)
	TF2Items_SetItemIndex(hItem, iItemDefinitionIndex);
	
	// Set same Classname (or shotgun classname if it needed a change)
	TF2Items_SetClassname(hItem, classname);
	
	// Set a random level
	TF2Items_SetLevel(hItem, GetRandomInt(1, 80));
	
	// Quality would be:
	//	Unusual (5)    - If there's an unusual override, this quality will be enforced.
	//  Decorated (15) - If there's a war paint override, this quality will be enforced.
	//
	// If no override is met, original item quality will be set.
	int quality = orgWeapons[client][slot].iQuality;
	
	bool hasUnusual = pWeapons[client].uEffects[slot] != -1, hasWarPaint = pWeapons[client].wPaint[slot] != -1;
	// Check first for War Paint, Unusual quality overrides a War Paint quality.
	if (hasWarPaint) quality = 15;
	if (hasUnusual)  quality = 5;
	
	// Set the quality it should have
	TF2Items_SetQuality(hItem, quality);
	
	// Now for the Attributes.
	//
	// Unusuals:
	// 134 - attach particle effect (Unusual Particle ID)
	// 
	// Australium:
	// 2027 - is australium item
	// 2022 - loot rarity		  (Required to render Australium)
	// 542  - item style override (Required to render Australium)
	//
	// Festivized:
	// 2053 - is_festivized
	// 
	// Killstreaks:
	// 2025 - killstreak tier      (Killstreak Type)
	// 2013 - killstreak effect    (Killstreaker)
	// 2014 - killstreak idleefect (Sheen)
	//
	// War Paints:
	// 834 - paintkit_proto_def_index (War Paint ID)
	// 725 - set_item_texture_wear    (War Paint Wear)
	//
	// Spells:
	// 1009 - SPELL: Halloween death ghosts 	  (Exorcism)
	// 1008 - SPELL: Halloween green flames 	  (Spectral Flames)
	// 1007 - SPELL: Halloween pumpkin explosions (Squash Rockets, Sentry Quad-Pumpkings & Gourd Grenades)
	//
	// Total Possible Attributes: 13 (holy shit)
	TF2Items_SetNumAttributes(hItem, 13);
	
	// Has Unusual override?
	int unusual = hasUnusual ? pWeapons[client].uEffects[slot] : orgWeapons[client][slot].uEffects;
	
	TF2Items_SetAttribute(hItem, 0, 134, float(unusual));
	
	// Has Australium Override?
	//
	// If they do not have an override, depending on the original value the others are set accordingly.
	// Also, if they have a War Paint override, Australium will not be set.
	bool hasAussie = pWeapons[client].Aussie[slot] && !hasWarPaint, orgAussie = orgWeapons[client][slot].Aussie;
	
	TF2Items_SetAttribute(hItem, 1, 2027, hasAussie ? float(hasAussie) : float(orgAussie));
	TF2Items_SetAttribute(hItem, 2, 2022, hasAussie ? float(hasAussie) : float(orgAussie));
	TF2Items_SetAttribute(hItem, 3, 542,  hasAussie ? float(hasAussie) : float(orgAussie));
	
	// Has Festive Override?
	bool hasFestive = pWeapons[client].Festive[slot], orgFestive = orgWeapons[client][slot].Festive;
	
	TF2Items_SetAttribute(hItem, 4, 2053, hasFestive ? float(hasFestive) : float(orgFestive));
	
	// Has Killstreaks Override?
	bool hasKs = pWeapons[client].kType[slot] != -1;
	int kType     = hasKs ? pWeapons[client].kType[slot]     : orgWeapons[client][slot].kType,
		kSheen    = hasKs ? pWeapons[client].kSheen[slot]    : orgWeapons[client][slot].kSheen,
		kStreaker = hasKs ? pWeapons[client].kStreaker[slot] : orgWeapons[client][slot].kStreaker;
	
	TF2Items_SetAttribute(hItem, 5, 2025, float(kType));
	TF2Items_SetAttribute(hItem, 6, 2014, float(kSheen));
	TF2Items_SetAttribute(hItem, 7, 2013, float(kStreaker));
	
	// Has War Paint Override?
	int   wPaint = hasWarPaint ? pWeapons[client].wPaint[slot] : orgWeapons[client][slot].wPaint;
	float wWear  = hasWarPaint ? pWeapons[client].wWear[slot]  : orgWeapons[client][slot].wWear;
	
	TF2Items_SetAttribute(hItem, 8, 834, view_as<float>(wPaint));
	TF2Items_SetAttribute(hItem, 9, 725, wWear);
	
	// Lastly, any Spell Overrides?
	int spells = pWeapons[client].sSpells[slot], oSpells = orgWeapons[client][slot].sSpells;
	bool hasExorcism  = view_as<bool>(spells & WeaponSpell_Exorcism),
		 hasFlames    = view_as<bool>(spells & WeaponSpell_SpectralFlames),
		 hasExplosion = view_as<bool>(spells & WeaponSpell_Explosions);
	
	TF2Items_SetAttribute(hItem, 10, 1009, hasExorcism   ? float(hasExorcism)  : float(view_as<bool>(oSpells & WeaponSpell_Exorcism)));
	TF2Items_SetAttribute(hItem, 11, 1008, hasFlames     ? float(hasFlames)    : float(view_as<bool>(oSpells & WeaponSpell_SpectralFlames)));
	TF2Items_SetAttribute(hItem, 12, 1007, hasExplosion  ? float(hasExplosion) : float(view_as<bool>(oSpells & WeaponSpell_Explosions)));
	
	TF2Items_SetFlags(hItem, flags);
	
	// If this is a new weapon (stock -> strange) fire another method.
	if (isNew)
		GivePostWeapon(client, slot, hItem);
	
	return isNew ? Plugin_Handled : Plugin_Changed;
}

// GiveStrangeWeapon - Issues a new TF2ItemType Handle and gives the player a completely new Strange variant weapon for TF2Items_OnGiveNamedItem to apply changes on.
void GiveStrangeWeapon(int client, int iItemDefinitionIndex, char[] classname, int slot, int flags) {
	// Create new Item Handle for the Strange Variant
	Handle hItem = INVALID_HANDLE;
	
	// Apply all attribute changes on it
	ApplyChanges(hItem, client, iItemDefinitionIndex, classname, slot, flags, true);
	
	// Delete the handle, no memory leaks!
	delete hItem;
}

// GivePostWeapon - Gives a player their changed weapon after, utilized for stock -> strange conversions as TF2Items won't allow iItemDefinitionIndex changes on a TF2ItemType Handle
void GivePostWeapon(int client, int slot, Handle& hItem) {
	if (GetPlayerWeaponSlot(client, slot) != -1)
		TF2_RemoveWeaponSlot(client, slot);
	
	int weapon = TF2Items_GiveNamedItem(client, hItem);
	
	// :)
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	// Equip, we're done!
	EquipPlayerWeapon(client, weapon);
}



													///////////////////////////////////////////////////////////////////////
													///////////////////////////////////////////////////////////////////////
													// Below this section lie my beautiful (horrendous) custom functions.//
													// 						Laughing is allowed.		 				 //
													///////////////////////////////////////////////////////////////////////
													///////////////////////////////////////////////////////////////////////



// GetOriginalAttributes - Fills the orgWeapons variable with the original data (SOC) from a weapon for later use.
void GetOriginalAttributes(int client, int slot) {
	int weapon = GetPlayerWeaponSlot(client, slot);
	
	if (weapon != INVALID_ENT_REFERENCE) {
		// First, let's get what we can with networked properties (quality and item index)
		// Item Index
		int iItemDefinitionIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), iQuality = GetEntProp(weapon, Prop_Send, "m_iEntityQuality");
		
		// Now, for attributes, we need to get SOC ones (the ones we care about)
		int   ids[16];
		float vals[16];
		int   amount = TF2Attrib_GetSOCAttribs(weapon, ids, vals);
		
		// Now, to loop them all. But we need to fill each variable with the value we find.
		int uEffect   = -1,
			wPaint    = -1,
			kType     = -1,
			kSheen    = -1,
			kStreaker = -1,
			sSpells   = 0;
		
		float wWear = -1.0;
		
		bool Aussie  = false,
			 Festive = false;
			 
		// Unusuals:
		// 134 - attach particle effect (Unusual Particle ID)
		// 
		// Australium:
		// 2027 - is australium item
		//
		// Festivized:
		// 2053 - is_festivized
		// 
		// Killstreaks:
		// 2025 - killstreak tier      (Killstreak Type)
		// 2013 - killstreak effect    (Killstreaker)
		// 2014 - killstreak idleefect (Sheen)
		//
		// War Paints:
		// 834 - paintkit_proto_def_index (War Paint ID)
		// 725 - set_item_texture_wear    (War Paint Wear)
		//
		// Spells:
		// 1009 - SPELL: Halloween death ghosts 	  (Exorcism)
		// 1008 - SPELL: Halloween green flames 	  (Spectral Flames)
		// 1007 - SPELL: Halloween pumpkin explosions (Squash Rockets, Sentry Quad-Pumpkings & Gourd Grenades)
		
		for (int i = 0; i < amount; i++) {
			// debug PrintToChatAll("%d = %f", ids[i], vals[i]);
			
			int value = view_as<int>(vals[i]);
			switch (ids[i]) {
				case 134:  uEffect   =  value;
				case 2027: Aussie    =  true;
				case 2053: Festive   =  true;
				case 2025: kType     =  value;
				case 2014: kSheen    =  value;
				case 2013: kStreaker =  value;
				case 834:  wPaint    =  value;
				case 725:  wWear     =  vals[i];
				case 1009: sSpells   |= WeaponSpell_Exorcism;
				case 1008: sSpells   |= WeaponSpell_SpectralFlames;
				case 1007: sSpells   |= WeaponSpell_Explosions;
			}
		}
		
		// Now after checking, let's fill the orgWeapons global for this player
		orgWeapons[client][slot].Popularize(iItemDefinitionIndex, uEffect, wPaint, wWear, Aussie, Festive, kType, kSheen, kStreaker, sSpells, iQuality);
		
		// We're done!
	}
}

// ForceChange() - Forces an SDKCall on the player to get effects applied instantly.
void ForceChange(int client, int slot) {
	// Get all SOC attribs he had so we check for No Override settings
	GetOriginalAttributes(client, slot);
	
	// DataPack for timer (slot and client ID)
	DataPack data = new DataPack();
	data.WriteCell(client);
	data.WriteCell(slot);
	
	// Force a Regenerate call onto the client in 1ms
	CreateTimer(0.01, ForceTimer, data);
}

// ForceChange's timer callback
public Action ForceTimer(Handle timer, DataPack data)
{
	// Nullify timer
	timer = null;
	
	// Reset DataPack position so we can read cells in write order	
	data.Reset();
	int client = data.ReadCell(), slot = data.ReadCell();
	
	// You are not needed anymore!
	delete data;
	
	// Get the actual HP, clip and ammo for the current weapon we're forcing the change on.
	int hp = GetClientHealth(client), clip[2], ammo[2];
	
	clipOff = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	ammoOff = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	
	// If the player is a Medic, we would also want to maintain their Übercharge for the change.
	float uber = -1.0;
	
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
		uber = GetEntPropFloat(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_flChargeLevel");
	
	// Fill the Ammo and Clip values for later restoration
	for (int i = 0; i < sizeof(clip); i++) {
		int wep = GetPlayerWeaponSlot(client, i);
		if (wep != INVALID_ENT_REFERENCE) {
			int ammoOff2 = GetEntProp(wep, Prop_Send, "m_iPrimaryAmmoType", 1) * 4 + ammoOff;
			
			clip[i] = GetEntData(wep, clipOff);
			ammo[i] = GetEntData(wep, ammoOff2);
		}
	}
	
	// Remove all weapons from the player to re-fire OnGiveNamedItem when Regenerate is finished.
	TF2_RemoveAllWeapons(client);
	
	// Regenerate the player (SDK Call)
	SDKCall(hRegen, client, 0);
	
	// Restore everything
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
	
	// Set active weapon as the changed one
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, slot));
	
	// Clean timer
	return Plugin_Stop;
}

// wMainMenu - Main menu for selected weapons; shows a resume of what can be modified on it and what can't (according to compatibility).
void wMainMenu(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(wepHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("What will you modify on %s?", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	bool sameItem = pWeapons[client].iItemIndex[slot] == iItemDefinitionIndex;
	
	////////////////////////////////////////////////////////
	// Can be Australium?
	bool isAussie = pWeapons[client].Aussie[slot], canAussie = CanBeAustralium(iItemDefinitionIndex);
	
	menu.AddItem("a", (isAussie && canAussie && sameItem) ? "Australium: [X]" : "Australium: [ ]", canAussie ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Can be Festivized?
	bool isFestive = pWeapons[client].Festive[slot], canFestive = CanBeFestivized(iItemDefinitionIndex);
	
	menu.AddItem("f", (isFestive && canFestive && sameItem) ? "Festivized: [X]" : "Festivized: [ ]", canFestive ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Can be War Painted?
	int wPaint = pWeapons[client].wPaint[slot], canWar = CanBePainted(iItemDefinitionIndex);
	
	char wPaintName[128];
	if (wPaint > -1) {
		char wPaintWear[128];
		GetWarPaintWearName(pWeapons[client].wWear[slot], wPaintWear, sizeof(wPaintWear));
		
		Format(wPaintName, sizeof(wPaintName), "%d", wPaint);
		
		// If a translation for this War Paint exists, we use it. Else, just set it as unknown.
		// There shouldn't be EVER a case where a War Paint is Unknown. This is because selectable War Paints are checked before adding them to the menu.
		if (TranslationPhraseExists(wPaintName) && sameItem)
			Format(wPaintName, sizeof(wPaintName), "War Paint: %T (Wear: %s)", wPaintName, client, wPaintWear);
		else
			Format(wPaintName, sizeof(wPaintName), "War Paint: Unknown (Wear: %s)", wPaintWear);
	}
	
	menu.AddItem("w", strlen(wPaintName) > 0 ? wPaintName : "War Paint: N/A", canWar ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Now, here comes everything that's always appliable.
	// Killstreak Effects
	menu.AddItem("k", "Killstreak Effects");
	
	// Unusual Effects
	int uEffect = pWeapons[client].uEffects[slot];
	char uName[64];
	GetUnusualWeaponName(sameItem ? uEffect : -1, uName, sizeof(uName));
	
	Format(uName, sizeof(uName), "Unusual Effect: %s", uName);
	
	menu.AddItem("u", uName);
	
	// Halloween Spells (only Exorcism is always appliable)
	menu.AddItem("s", "Halloween Spells");
	
	// Reset all option
	menu.AddItem("r", "RESET EVERYTHING");
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// wWarPaint - Menu that allows players to select their War Paint settings (Specific protodef ID and wear value)
void wWarPaint(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(wPaintHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("War Paint Settings for %s", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	bool sameItem = pWeapons[client].iItemIndex[slot] == iItemDefinitionIndex;
	
	// Actual options
	int   wPaint = pWeapons[client].wPaint[slot];
	float wear   = pWeapons[client].wWear[slot];
	
	char wPaintName[128], wPaintWearName[128];
	// Format War Paint Display String
	Format(wPaintName, sizeof(wPaintName), "%d", wPaint);
	if (TranslationPhraseExists(wPaintName) && sameItem)
		Format(wPaintName, sizeof(wPaintName), "War Paint: %T", wPaintName, client);
	else
		Format(wPaintName, sizeof(wPaintName), "War Paint: No Override");
	
	// Format Wear Display String
	GetWarPaintWearName(sameItem ? wear : -1.0, wPaintWearName, sizeof(wPaintWearName));
	Format(wPaintWearName, sizeof(wPaintWearName), "War Paint Wear: %s", wPaintWearName);
	
	menu.AddItem("p", wPaintName);
	menu.AddItem("w", wPaintWearName);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// kKillstreaks - Main Killstreak effects menu. Allows the user to visualize their Killstreak effects preferences currently set.
void kKillstreaks(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(kKillstreakHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("Killstreak Preferences for %s", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	bool sameItem = pWeapons[client].iItemIndex[slot] == iItemDefinitionIndex;
	
	// Killstreak Type
	int type = pWeapons[client].kType[slot];
	char kTypeName[128];
	
	GetKillstreakTypeName(sameItem ? type : -1, kTypeName, sizeof(kTypeName));
	Format(kTypeName, sizeof(kTypeName), "Killstreak Type: %s", kTypeName);
	
	menu.AddItem("t", kTypeName);
	
	// Killstreak Sheen (Depends on the type, this will either be disabled or enabled for selection)
	// It is also checked the user has a correct Killstreak type set to apply an overriden sheen/streaker.
	//
	// TODO: identify original killstreak type to allow sheen and killstreaker overrides without enforcing a type
	//
	int sheen = pWeapons[client].kSheen[slot];
	char kSheenName[128];
	
	GetSheenName(sameItem ? sheen : -1, kSheenName, sizeof(kSheenName));
	Format(kSheenName, sizeof(kSheenName), "Sheen: %s", kSheenName);
	
	menu.AddItem("s", kSheenName, (1 < type <= 3) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Killstreaker (same as sheen, only this time it MUST BE 3)
	int killstreaker = pWeapons[client].kStreaker[slot];
	char kStreakerName[128];
	
	GetKillstreakerName(sameItem ? killstreaker : -1, kStreakerName, sizeof(kStreakerName));
	Format(kStreakerName, sizeof(kStreakerName), "Killstreaker: %s", kStreakerName);
	
	menu.AddItem("k", kStreakerName, (type == 3) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Done!
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// wSpells - Allows a player to set Halloween Spells on their weapon (if applicable)
void wSpells(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(wSpellsHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("Toggling Spells on %s", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	// Time to see applicability
	int spells = pWeapons[client].sSpells[slot]; // Spell Bitfield
	TFClassType class = TF2_GetPlayerClass(client);
	
	bool sameItem = pWeapons[client].iItemIndex[slot] == iItemDefinitionIndex;
	
	// Exorcism can always be applied
	menu.AddItem("e", (spells & WeaponSpell_Exorcism && sameItem) ? "Exorcism: [X]" : "Exorcism: [ ]");
	
	// Squash Rockets (Only on Soldier Primaries)
	// Since "slot" is relative to the weapon slot, we can compare it.
	menu.AddItem("r", (spells & WeaponSpell_SquashRockets && sameItem) ? "Squash Rockets: [X]" : "Squash Rockets: [ ]", (class == TFClass_Soldier && slot == 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Spectral Flames (Only on Pyro Primaries)
	menu.AddItem("f", (spells & WeaponSpell_SpectralFlames && sameItem) ? "Spectral Flames: [X]" : "Spectral Flames: [ ]", (class == TFClass_Pyro && slot == 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Sentry Quad Pumpkins (Only on Engineer Melee)
	menu.AddItem("s", (spells & WeaponSpell_SentryQuadPumpkins && sameItem) ? "Sentry Quad-Pumpkins: [X]" : "Sentry Quad-Pumpkins: [ ]", (class == TFClass_Engineer && slot == 2) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Gourd Grenades (Only on Demoman Primaries & Secondaries)
	menu.AddItem("g", (spells & WeaponSpell_GourdGrenades && sameItem) ? "Gourd Grenades: [X]" : "Gourd Grenades: [ ]", (class == TFClass_DemoMan && (0 <= slot <= 1)) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}