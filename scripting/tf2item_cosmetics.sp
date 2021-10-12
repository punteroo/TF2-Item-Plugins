#include "tf2items/cosmetics.sp"

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "3.0.0"

public Plugin myinfo = 
{
	name = "[TF2] Cosmetics Manager",
	author = "Lucas 'puntero' Maza",
	description = "Gives the ability for users to customize their cosmetics (hats, miscs)",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=213425"
};

/////////////////////
// GLOBAL DECLARES //
/////////////////////

// Tag
#define PGTAG		   "{mythical}[TF2Items]{white}"

// Global Regeneration SDKCall Handle (Used to update items the player has)
Handle hRegen = INVALID_HANDLE;

// Cosmetic information for every player in the server.
CosmeticsInfo pCosmetics[MAXPLAYERS + 1];

// Original Cosmetic Information for every player
Cosmetic orgCosmetics[MAXPLAYERS + 1][3];

// Networkable Server Offsets (used for regen)
int clipOff;
int ammoOff;

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
}

public void OnPluginStart()
{
	RegAdminCmd("sm_cosmetics", 	CMD_Cosmetics, ADMFLAG_RESERVATION, "Opens the cosmetics manager menu.");
	RegAdminCmd("sm_hats", 			CMD_Cosmetics, ADMFLAG_RESERVATION, "Opens the cosmetics manager menu.");
	RegAdminCmd("sm_myhats", 		CMD_Cosmetics, ADMFLAG_RESERVATION, "Opens the cosmetics manager menu.");
	// Various ways of invoking the command. For user commodity ;)
	//RegConsoleCmd("sm_my", CMD_My);
	
	Handle hGameConf = LoadGameConfigFile("sm-tf2.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "Regenerate");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	
	hRegen = EndPrepSDKCall();
	// This piece of code makes an SDKCall for the Regenerate function inside the game's gamedata.
	// Refreshes the entire player to ensure changes take effect instantly.
	
	LoadTranslations("cosmetics.phrases.txt");
	LoadTranslations("unusuals.phrases.txt");
	// Translations!
}

public void OnClientPostAdminCheck(int client) {
	for (int i = 0; i < 3; i++)
		pCosmetics[client].ResetFor(i);
}

/* Only utilized for testing
public Action CMD_My(int client, int args) {
	PrintToChatAll("My Status:");
	PrintToChatAll("Hat Indexes: %d, %d, %d", pCosmetics[client].iItemIndex[0], pCosmetics[client].iItemIndex[1], pCosmetics[client].iItemIndex[2]);
	PrintToChatAll("Unusual Overrides: %d, %d, %d", pCosmetics[client].uEffects[0], pCosmetics[client].uEffects[1], pCosmetics[client].uEffects[2]);
	PrintToChatAll("Paint Overrides: %d, %d, %d", pCosmetics[client].cPaint[0], pCosmetics[client].cPaint[1], pCosmetics[client].cPaint[2]);
	PrintToChatAll("Spell Paint Overrides: %d, %d, %d", pCosmetics[client].sPaint[0], pCosmetics[client].sPaint[1], pCosmetics[client].sPaint[2]);
	PrintToChatAll("Footprint Overrides: %d, %d, %d", pCosmetics[client].sFoot[0], pCosmetics[client].sFoot[1], pCosmetics[client].sFoot[2]);
	return Plugin_Handled;
}*/

public Action CMD_Cosmetics(int client, int args)
{
	GenerateHatsMenu(client);
	return Plugin_Handled;
}

//
// Normal Menus Handlers
////////////////////////

public int MainHdlr(Menu menu, MenuAction action, int client, int p2) {
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			int id = StringToInt(sel);
			if (id > 0)
				IntermediaryMenu(client, id, p2);
		}
		case MenuAction_End: delete menu;
	}
	
	return 0;
}

public int intHdlr(Menu menu, MenuAction action, int client, int p2) {
	switch (action) {
		case MenuAction_Select: {
			char sel[32], idStr[12], slotStr[2];
			// get embedded data on hidden menu items
			menu.GetItem(0, idStr, sizeof(idStr));
			menu.GetItem(1, slotStr, sizeof(slotStr));
			
			// get selected modification to do
			menu.GetItem(p2, sel, sizeof(sel));
			
			// convert to integers and get cosemtic name (thanks tf2econdata)
			int iItemDefinitionIndex = StringToInt(idStr), slot = StringToInt(slotStr);
			
			char name[64];
			TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
			
			// lmao sourcepawn strings lmao sourcepawn strings
			// open respective menu according to mod selection
			//
			// switch statement, thanks ampenis
			//
			switch (sel[0]) {
				case 'u': EffectsMenu(client, name, iItemDefinitionIndex, slot);
				case 'o': OthersMenu(client, name, iItemDefinitionIndex, slot);
				case 'r': {
					pCosmetics[client].ResetFor(slot);
				
					CPrintToChat(client, "%s Your changes to {gold}%s {white}have been reset. Respawn to apply them.", PGTAG, name);
				}
				default: PaintsMenu(client, name, iItemDefinitionIndex, slot);
				
			}
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				GenerateHatsMenu(client);
		}
		case MenuAction_End: delete menu;
	}

	return 0;
}

//
// Unusual Effects & Normal Paints Handler
//////////////////////////////////////////
public int paintHdlr(Menu menu, MenuAction action, int client, int p2) {
	char slotStr[2], idStr[14];
	GetMenuItem(menu, 0, slotStr, sizeof(slotStr));
	GetMenuItem(menu, 1, idStr, sizeof(idStr));
	
	int slot = StringToInt(slotStr), iItemDefinitionIndex = StringToInt(idStr);
	
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			int paint = StringToInt(sel);
			
			pCosmetics[client].iItemIndex[slot] = iItemDefinitionIndex;
			pCosmetics[client].cPaint[slot]     = paint;
			
			ForceChange(client, slot);
			IntermediaryMenu(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_Cancel, MenuAction_End: {
			delete menu;
			IntermediaryMenu(client, iItemDefinitionIndex, slot);
		}
	}

	return 0;
}

public int EffectHdlr(Menu menu, MenuAction action, int client, int p2) {
	char slotStr[2], idStr[14];
	GetMenuItem(menu, 0, slotStr, sizeof(slotStr));
	GetMenuItem(menu, 1, idStr, sizeof(idStr));
	
	int slot = StringToInt(slotStr), iItemDefinitionIndex = StringToInt(idStr);
	
	switch (action) {
		case MenuAction_Select: {
			char sel[32];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			pCosmetics[client].iItemIndex[slot] = iItemDefinitionIndex;
			pCosmetics[client].uEffects[slot]   = StringToInt(sel);
			
			ForceChange(client, slot);
			IntermediaryMenu(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_Cancel, MenuAction_End: {
			delete menu;
			IntermediaryMenu(client, iItemDefinitionIndex, slot);
		}
	}

	return 0;
}

//
// Spell Paints & Footprints Handlers
//////////////////////////////////////

public int otherHdlr(Menu menu, MenuAction action, int client, int p2) {
	char slotStr[2], idStr[14], name[64];
	GetMenuItem(menu, 0, slotStr, sizeof(slotStr));
	GetMenuItem(menu, 1, idStr, sizeof(idStr));
	
	int slot = StringToInt(slotStr), iItemDefinitionIndex = StringToInt(idStr);
	
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	
	switch (action) {
		case MenuAction_Select: {
			char sel[64];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			switch (sel[0]) {
				case 'f': FootprintsMenu(client, name, iItemDefinitionIndex, slot);
				case 'p': SpellsMenu(client, name, iItemDefinitionIndex, slot);
			}
			
			// User selected Voices From Below toggle
			// don't laugh at this detection method pls :(
			if (p2 == 4) {
				pCosmetics[client].sVoices[slot] = !pCosmetics[client].sVoices[slot];
				
				ForceChange(client, slot);
				
				IntermediaryMenu(client, iItemDefinitionIndex, slot);
			}
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				IntermediaryMenu(client, iItemDefinitionIndex, slot);
		}
		case MenuAction_End: delete menu;
	}
	
	return 0;
}

public int spellHdlr(Menu menu, MenuAction action, int client, int p2) {
	char slotStr[2], idStr[14], name[64];
	GetMenuItem(menu, 0, slotStr, sizeof(slotStr));
	GetMenuItem(menu, 1, idStr, sizeof(idStr));
	
	int slot = StringToInt(slotStr), iItemDefinitionIndex = StringToInt(idStr);
	
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	
	switch (action) {
		case MenuAction_Select: {
			char sel[64];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			pCosmetics[client].iItemIndex[slot] = iItemDefinitionIndex;
			pCosmetics[client].sPaint[slot]     = StringToInt(sel);
			ForceChange(client, slot);
			
			OthersMenu(client, name, iItemDefinitionIndex, slot);
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				OthersMenu(client, name, iItemDefinitionIndex, slot);
		}
		case MenuAction_End: delete menu;
	}
	
	return 0;
}

public int footHdlr(Menu menu, MenuAction action, int client, int p2) {
	char slotStr[2], idStr[14], name[64];
	GetMenuItem(menu, 0, slotStr, sizeof(slotStr));
	GetMenuItem(menu, 1, idStr, sizeof(idStr));
	
	int slot = StringToInt(slotStr), iItemDefinitionIndex = StringToInt(idStr);
	
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	
	switch (action) {
		case MenuAction_Select: {
			char sel[64];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			pCosmetics[client].iItemIndex[slot] = iItemDefinitionIndex;
			pCosmetics[client].sFoot[slot]      = StringToInt(sel);
			ForceChange(client, slot);
			
			OthersMenu(client, name, iItemDefinitionIndex, slot);
		}
		case MenuAction_Cancel: {
			if (p2 == MenuCancel_ExitBack)
				OthersMenu(client, name, iItemDefinitionIndex, slot);
		}
		case MenuAction_End: delete menu;
	}
	
	return 0;
}

///////////////////////////////////
///////////////////////////////////
///////////////////////////////////

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle& hItem)
{
	// This is where the magic happens :)
	// First check if it's a cosmetic and not another type of item.
	if ((StrEqual(classname, "tf_wearable")) && !IsWearableWeapon(iItemDefinitionIndex)) {
		for (int i; i < 3; i++) {
			int id = pCosmetics[client].iItemIndex[i];
			
			if ((iItemDefinitionIndex == id) && (IsHatUnusual(iItemDefinitionIndex) || IsHatPaintable(iItemDefinitionIndex))) {
				int flags = OVERRIDE_ALL | FORCE_GENERATION;
				
				hItem = TF2Items_CreateItem(flags);
				
				TF2Items_SetClassname(hItem, classname);
				TF2Items_SetItemIndex(hItem, iItemDefinitionIndex);
				TF2Items_SetLevel(hItem, GetRandomInt(1, 80));
				
				// ahhh.... amount of attributes. you know that feeling when you got to declare something you're always unsure of?
				// i COULD calculate the amount of attributes needed to establish an override, but why do that? since we're already re-making the hat...
				// well here's the thing: there's a MAXIMUM possible of 5 attributes for paint, and 2 for unusuals. so FUCK IT, 7
				TF2Items_SetNumAttributes(hItem, 7);
				
				// quality will be: original if not doing an unusual override, 5 if unusual overriden
				bool hasUnusual = (pCosmetics[client].uEffects[i] != -1);
				TF2Items_SetQuality(hItem, hasUnusual ? 5 : orgCosmetics[client][i].iQuality);
				// attach particle effect
				TF2Items_SetAttribute(hItem, 0, 134, hasUnusual ? float(pCosmetics[client].uEffects[i]) : float(orgCosmetics[client][i].uEffect));
				// particle effect use head origin
				TF2Items_SetAttribute(hItem, 1, 520, 1.0);
				
				// now, very simple for unusuals. but paints is a whole other story :)
				// because: if the player had already legit paints applied, those must be re-specified here to take effect.
				//          if not, apply the overrides.
				//
				//  142  = set item tint RGB
				//	261  = set item tint RGB 2
				//  1004 = set item tint RGB override
				//
				//	1005 = halloween footstep type
				//  1006 = halloween voice modulation
				//
				int paint = pCosmetics[client].cPaint[i], oRedPaint = orgCosmetics[client][i].rPaint, oBluPaint = orgCosmetics[client][i].bPaint;
				bool hasPaint = (paint != -1), isTeam = (paint > -1 && paint < 7);
				
				if (hasPaint) {
					TF2Items_SetAttribute(hItem, 2, 142, isTeam ? float(teamColors[paint][0]) : float(paint));
					TF2Items_SetAttribute(hItem, 2, 261, isTeam ? float(teamColors[paint][1]) : float(paint));
				} else if (oRedPaint != -1 || oBluPaint != -1) {	
					TF2Items_SetAttribute(hItem, 2, 142, float(oRedPaint));
					TF2Items_SetAttribute(hItem, 2, 261, float(oBluPaint));
				}
				
				// do they have custom overrides for spell paint?
				int spell = pCosmetics[client].sPaint[i], oSpell = orgCosmetics[client][i].sPaint;
				bool hasSpell = (spell != -1);
				
				if (hasSpell)
					TF2Items_SetAttribute(hItem, 4, 1004, float(spell));
				else if (oSpell != -1)
					TF2Items_SetAttribute(hItem, 4, 1004, float(oSpell));
				
				// do they have custom overrides for footprints?
				int foot = pCosmetics[client].sFoot[i], oFoot = orgCosmetics[client][i].sFoot;
				bool hasFoot = (foot != -1);
				
				if (hasFoot)
					TF2Items_SetAttribute(hItem, 5, 1005, float(foot));
				else if (oFoot != -1)
					TF2Items_SetAttribute(hItem, 5, 1005, float(foot));
					
				// do they have a custom override for voice modulation?
				int voices = view_as<int>(pCosmetics[client].sVoices[i]);
				TF2Items_SetAttribute(hItem, 6, 1006, voices ? float(voices) : float(orgCosmetics[client][i].sVoices));
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



// IntermediaryMenu() - Shows the menu to check the cosmetic status, and if any unusual or paint has been selected for it.
void IntermediaryMenu(int client, int iItemDefinitionIndex, int slot) {
	Menu intMenu = new Menu(intHdlr);
	
	char name[128], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	intMenu.SetTitle("What do you want to change on %s?", name);
	
	// Passing data to menu handlers is done this way (without utilizing globals)
	// if somebody knows better please endulge me i refuse to believe this is the only way
	intMenu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	intMenu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	int anyMatch = 0;
	if (IsHatUnusual(iItemDefinitionIndex)) {
		int effect = pCosmetics[client].uEffects[slot];
		
		if (effect < 1 || pCosmetics[client].iItemIndex[slot] != iItemDefinitionIndex)
			Format(name, sizeof(name), "No Override");
		else {
			Format(name, sizeof(name), "Cosmetic_Eff%d", effect);
			Format(name, sizeof(name), "%T", name, client);
		}
		
		char fName[64];
		Format(fName, sizeof(fName), "Unusual Effect: %s", name);
		
		intMenu.AddItem("unu", fName);
		
		anyMatch |= (1 << 0);
	} if (IsHatPaintable(iItemDefinitionIndex)) {
		int paint = pCosmetics[client].cPaint[slot];
		
		char info[64];
		Format(info, sizeof(info), "%d", paint);
		
		if (paint < 0 || pCosmetics[client].iItemIndex[slot] != iItemDefinitionIndex)
			Format(name, sizeof(name), "No Override");
		else
			GetPaintName(paint, name, sizeof(name));
		
		char fName[128];
		Format(fName, sizeof(fName), "Paint: %s", name);
		
		intMenu.AddItem(info, fName);
		
		static const char other[] = "Halloween Spells";
		
		intMenu.AddItem("other", other);
		
		anyMatch |= (1 << 1);
	}
	
	if ((anyMatch & 3) != 0) {
		char reset[64];
		Format(reset, sizeof(reset), "Reset Everything");
		
		intMenu.AddItem("reset", reset);
	} else {
		char none[70];
		Format(none, sizeof(none), "No customization can be done to this cosmetic. How did you get here?");
		intMenu.AddItem("-", none, ITEMDRAW_DISABLED);
	}
	
	intMenu.ExitBackButton = true;
	intMenu.Display(client, MENU_TIME_FOREVER);
}

// OthersMenu() - Shows a menu to select other modifications for the cosmetic (halloween spells and/or paints)
// This menu shall only be opened on paintable hats.
void OthersMenu(int client, const char[] name, int iItemDefinitionIndex, int slot) {
	Menu otherMenu = new Menu(otherHdlr);
	
	otherMenu.SetTitle("Halloween Spells for %s", name);
	
	char foot[128],
		 paint[128];
		 
	bool isSameItem = pCosmetics[client].iItemIndex[slot] == iItemDefinitionIndex;
	
	char buffer[64];
	int footStep = pCosmetics[client].sFoot[slot];
	if (footStep > -1 && isSameItem) {
		Format(buffer, sizeof(buffer), "Cosmetic_Other_Footsteps_%d", footStep);
		Format(buffer, sizeof(buffer), "%T", buffer, client);
	} else
		Format(buffer, sizeof(buffer), "No Override");
	
	Format(foot, sizeof(foot), "%T", "Cosmetic_Other_Footprint", client, buffer);
	
	int spellPaint = pCosmetics[client].sPaint[slot];
	
	if (spellPaint > -1 && isSameItem) {
		Format(buffer, sizeof(buffer), "Cosmetic_Other_SpellPaint_%d", spellPaint);
		Format(buffer, sizeof(buffer), "%T", buffer, client);
	} else
		Format(buffer, sizeof(buffer), "No Override");
	
	Format(paint, sizeof(paint), "%T", "Cosmetic_Other_SpellPaint", client, buffer);
	
	//Format(voice, sizeof(voice), "%T", (Cosmetics[client].otherOverride & (1 << 3)) ? "Cosmetic_Other_Voices_On" : "Cosmetic_Other_Voices_Off", client);
	char slotStr[2], idStr[14];
	Format(slotStr, sizeof(slotStr), "%d", slot);
	Format(idStr, sizeof(idStr), "%d", iItemDefinitionIndex);
	
	// more data through menus lmao
	otherMenu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	otherMenu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	
	otherMenu.AddItem("foot", foot);
	otherMenu.AddItem("paint", paint);
	otherMenu.AddItem(isSameItem ? (pCosmetics[client].sVoices[slot] ? "0" : "1") : "1", isSameItem ? (pCosmetics[client].sVoices[slot] ? "Voices From Below: [X]" : "Voices From Below: [ ]") : "Voices From Below: [ ]");
	
	otherMenu.ExitBackButton = true;
	otherMenu.Display(client, MENU_TIME_FOREVER);
}

// ForceChange() - Forces an SDKCall on the player to get the Unusual effects to be applied instantly.
void ForceChange(int client, int slot) {
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_wearable")) != INVALID_ENT_REFERENCE) {		
		if (client == GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")) {
			int itemDef = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");

			if (IsHatPaintable(itemDef) || IsHatUnusual(itemDef)) {
				// if this is just a hat we have overriden, let's get the original data!
				// also check that the slot we're about to 
				if (pCosmetics[client].iItemIndex[slot] == itemDef) {
					StringMap cosmetic = new StringMap();
					GetOriginalAttributes(ent, cosmetic);
					
					// get quality
					int quality = GetEntProp(ent, Prop_Send, "m_iEntityQuality");
					
					// get the originally stored values on the StringMap
					float uEffect, redPaint, bluPaint, spellPaint, spellFootstep, spellVoices;
					cosmetic.GetValue("uEffect", uEffect);
					cosmetic.GetValue("rPaint", redPaint);
					cosmetic.GetValue("bPaint", bluPaint);
					cosmetic.GetValue("sPaint", spellPaint);
					cosmetic.GetValue("sFoot", spellFootstep);
					cosmetic.GetValue("sVoices", spellVoices);
					
					// clear StringMap, not needed anymore
					delete cosmetic;
					
					// populate user original cosmetic information
					orgCosmetics[client][slot].Populate(itemDef, RoundToFloor(uEffect), RoundToFloor(redPaint), RoundToFloor(bluPaint), RoundToFloor(spellPaint), RoundToFloor(spellFootstep), RoundToFloor(spellVoices), quality);
				}
			}
			AcceptEntityInput(ent, "Kill");
		}
	}
	CreateTimer(0.05, ForceTimer, client);
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
	
	//GenerateHatsMenu(client);
	
	delete timer;
	
	return Plugin_Stop;
}