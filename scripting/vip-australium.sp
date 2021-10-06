#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.3.2"

/////////////////////
// GLOBAL DECLARES //
/////////////////////

// Declare the weapons slots amount
#define		WEAPON_SLOTS	3

// Attribute IDs required for an australium weapon.
//#define AUS_ATTRS "2027 ; 1 ; 2022 ; 1 ; 542 ; 1"		old define i used
int AttribId[3] =  { 2027, 2022, 542 };

// Per-client Boolean for Australium Mode
bool Australium[MAXPLAYERS + 1] = false;
bool AustraliumSE[MAXPLAYERS + 1] = false;

// New Golden Weapons
int clientGold[MAXPLAYERS + 1] = 0;

int goldWeps[3] =  { 264, 423, 169 };
char goldNames[3][32] =  { "Aus_SpecialWeps_GoldenPan", "Aus_SpecialWeps_Saxxy", "Aus_SpecialWeps_GoldenWrench" };

/////////////////////
/////////////////////
/////////////////////

public Plugin myinfo =  {
	name = "[VIP Module] Australium Weapons",
	author = "Lucas 'puntero' Maza",
	description = "Australium weapons plugin for VIP members.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=213425"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_australium", CMD_Aussie, ADMFLAG_RESERVATION, "Toggles the australium weapon mode.");
	RegAdminCmd("sm_aussie", CMD_Aussie, ADMFLAG_RESERVATION, "Toggles the australium weapon mode.");
	// Just some other detection for a short and long command.
	
	HookEvent("post_inventory_application", OnItems);
	HookEvent("player_spawn", OnItems);
	// Hook to the items given / resupply event, this manages when to give the user their weapons.
	// Also hook into the player_spawn event just in case post_inventory_application isn't called (happens sometimes)
	
	LoadTranslations("australiums.phrases.txt");
	// Translations !
}

public void OnMapStart()
{
	for (int i = 0; i < sizeof(Australium); i++) {
		Australium[i] = false;
		AustraliumSE[i] = false;
		clientGold[i] = -1;
	}
}

public void OnClientConnected(int client)
{
	// Disable all australiums on connection.
	Australium[client] = false;
	AustraliumSE[client] = false;
	clientGold[client] = 0;
}

public void OnClientDisconnect(int client)
{
	// Disable all australiums on disconnection.
	Australium[client] = false;
	AustraliumSE[client] = false;
	clientGold[client] = -1;
}

public Action CMD_Aussie(int client, int args)
{
	OpenAustraliumMenu(client);
	
	// We're done with the command.
	return Plugin_Handled;
}

public Action OnItems(Event event, char[] name, bool dontBroadcast)
{
	// Get the client that requested an item "refresh"
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Did he enable australium mode on himself?
	if (Australium[client]) {
		// If the client has australium mode and touches a resupply locker, he'll drop the weapon infinitely.
		// So we create a timer to remove those dropped weapons just as they are spawned in.
		CreateTimer(0.1, RemoveDropped, client);
		
		// While that is happening, we can give this person their weapon.
		// There's a little problem though, not all weapons are australium, only a few can be aussie.
		// So we need to check first if the weapon CAN be australium before being given.
		for (int i = 0; i < WEAPON_SLOTS; i++)
		{
			// Get the weapon the player has on i slot.
			int ent = GetPlayerWeaponSlot(client, i);
			
			// If it is a valid entity reference index, proceed.
			if (ent != INVALID_ENT_REFERENCE) {
				int id = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
				
				if (AustraliumSE[client] && i == 2) {
					char tClass[64];
					
					TFClassType iClass = TF2_GetPlayerClass(client);
					switch (iClass) {
						case TFClass_Scout:
						Format(tClass, sizeof(tClass), "tf_weapon_bat");
						case TFClass_Soldier:
						Format(tClass, sizeof(tClass), "tf_weapon_shovel");
						case TFClass_Pyro:
						Format(tClass, sizeof(tClass), "tf_weapon_fireaxe");
						case TFClass_DemoMan:
						Format(tClass, sizeof(tClass), "tf_weapon_bottle");
						case TFClass_Engineer:
						Format(tClass, sizeof(tClass), "tf_weapon_wrench");
						case TFClass_Heavy:
						Format(tClass, sizeof(tClass), "tf_weapon_fists");
						case TFClass_Sniper:
						Format(tClass, sizeof(tClass), "tf_weapon_club");
						case TFClass_Medic:
						Format(tClass, sizeof(tClass), "tf_weapon_bonesaw");
						case TFClass_Spy:
						Format(tClass, sizeof(tClass), "tf_weapon_knife");
					}
					
					GiveAustralium(client, tClass, goldWeps[clientGold[client]], 15, 11, i);
					continue;
				}
				
				// If the weapon is australizable, continue.
				if (IsAustralizable(id)) {
					char classname[32];
					GetEntityClassname(ent, classname, sizeof(classname));
					
					// Get the weapon level as well.
					int level = GetEntProp(ent, Prop_Send, "m_iEntityLevel");
					
					// Give them the australium weapon.
					GiveAustralium(client, classname, id, level, 11, i);
				}
			}
		}
		// We've done what we had to do.
		return Plugin_Continue;
	}
	// Just another user without Australium mode. Let's go somewhere else.
	return Plugin_Continue;
}

public Action RemoveDropped(Handle timer, any client)
{
	// Start with the first entity in the server.
	// Loop through all of the entities and only perform on "tf_dropped_weapon" (dropped weapons)
	int ent = FindEntityByClassname(-1, "tf_dropped_weapon");
	while (ent != -1) {
		RemoveEdict(ent);
		ent = FindEntityByClassname(-1, "tf_dropped_weapon");
	}
	return Plugin_Handled;
}

public int AussieHdlr(Menu menu, MenuAction action, int client, int p2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sel[64];
			GetMenuItem(menu, p2, sel, sizeof(sel));
			
			if (StrEqual(sel, "sw")) {
				// Invert the value of the boolean.
				Australium[client] = !Australium[client];
				
				// Check its state and reply to the user accordingly.
				Australium[client] ? CPrintToChat(client, "%T", "Aus_Enabled", client) : CPrintToChat(client, "%T", "Aus_Disabled", client);
				return 0;
			}
			
			if (StrEqual(sel, "ase")) {
				AustraliumSE[client] = !AustraliumSE[client];
				
				OpenAustraliumMenu(client);
				return 0;
			}
			
			if (StrEqual(sel, "gold")) {
				clientGold[client]++;
				
				if (clientGold[client] > 2 || clientGold[client] < 0)
					clientGold[client] = 0;
				
				OpenAustraliumMenu(client);
				return 0;
			}
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



// GiveAustralium() - Gives an australium weapon to the player.
bool GiveAustralium(int client, char[] classname, int index, int level, int quality, int slot)
{
	// Oh boy, custom items. They're a delight to see them work but an ass to code them in.
	// Let's begin with this shithole.
	
	// First of all these shitty flags.
	int flags = OVERRIDE_ALL | FORCE_GENERATION | PRESERVE_ATTRIBUTES;
	
	// Create the infamous weapon handle.
	Handle weapon = TF2Items_CreateItem(flags);
	// If it fails, stop there!
	if (weapon == INVALID_HANDLE)
		return false;
	
	// Set the parsed info through the function, easy stuff right?
	TF2Items_SetClassname(weapon, classname);
	
	int fId = StockToStrange(index);
	if (fId < 0)
		fId = index;
	
	TF2Items_SetItemIndex(weapon, fId);
	
	if ((fId == 169 || index == 169) && (TF2_GetPlayerClass(client) != TFClass_Engineer))
		TF2Items_SetItemIndex(weapon, 1071);
	
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	
	// Since aussies only need 3 attributes, we'll utilize only those.
	if (!IsSpecialWeapon(fId))
		TF2Items_SetNumAttributes(weapon, 3);
	else
		TF2Items_SetNumAttributes(weapon, 2);
	
	// Time to assign these attributes to our item.
	if (!IsSpecialWeapon(fId)) {
		for (int i = 0; i < sizeof(AttribId); i++)
		TF2Items_SetAttribute(weapon, i, AttribId[i], 1.0);
	}
	else {
		TF2Items_SetAttribute(weapon, 0, 542, 0.0);
		TF2Items_SetAttribute(weapon, 1, 150, 1.0);
	}
	
	// The item is ready, let's remove the weapon slot to give the new weapon.
	TF2_RemoveWeaponSlot(client, slot);
	
	// Now, let's give it to them!
	int entity = TF2Items_GiveNamedItem(client, weapon);
	
	// shh.... don't pay attention to this it isn't important...
	SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1, 1);
	
	// Give it to our lucky boi.
	EquipPlayerWeapon(client, entity);
	
	// Mission success.
	CloseHandle(weapon);
	return true;
}

// OpenAustraliumMenu() - Opens an Australium preference menu.
void OpenAustraliumMenu(int client)
{
	Menu menu = new Menu(AussieHdlr);
	
	char title[64];
	Format(title, 64, "%T", "Aus_MenuTitle", client);
	
	menu.SetTitle(title);
	
	char aEnabled[128], spwAlways[128], spw[128];
	
	Format(spw, 128, "%T", "Aus_SpecialWeps", client);
	menu.AddItem("---", spw, ITEMDRAW_DISABLED);
	
	Format(aEnabled, 128, "%T", Australium[client] ? "Aus_Mode_On" : "Aus_Mode_Off", client);
	menu.AddItem("sw", aEnabled);
	
	Format(spwAlways, 128, "%T", AustraliumSE[client] ? "Aus_SpecialWeps_GiveAlways_On" : "Aus_SpecialWeps_GiveAlways_Off", client);
	menu.AddItem("ase", spwAlways);
	
	char goldWeapon[64];
	if (clientGold[client] > -1) {
		char wep[128];
		Format(wep, 128, "%T", goldNames[clientGold[client]], client);
		
		Format(goldWeapon, sizeof(goldWeapon), "%T", "Aus_SpecialWeps_Preffered", client, wep);
	}
	
	AddMenuItem(menu, "gold", goldWeapon, (AustraliumSE[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
	
	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

// IsAustralizable() - cool name xd. Checks if the weapon currently equipped can be australium.
bool IsAustralizable(int id)
{
	// Time to check!
	switch (id) {
		case 13, 200, 45,  // Scout
		18, 205, 228,  // Soldier
		21, 208, 38,  // Pyro
		19, 206, 20, 207, 132,  // Demoman
		15, 202, 424,  // Heavy
		141, 7, 197,  // Engineer
		36, 29, 211,  // Medic
		14, 201, 16, 203,  // Sniper
		61, 4, 194,  // Spy
		264: // Frying Pan (Multi-Class)
		{
			return true;
		}
	}
	return false;
}

// IsSpecialWeapon() - cool other name, checks if the weapon is not in the "special" weapon list
bool IsSpecialWeapon(int id)
{
	return ((id == 1071) || (id == 169) || (id == 423));
}

// StockToStrange() - Changes the Stock weapon ID to its Strange variant.
int StockToStrange(int id)
{
	switch (id) {
		case 13:
		return 200;
		case 18:
		return 205;
		case 21:
		return 208;
		case 19:
		return 206;
		case 20:
		return 207;
		case 15:
		return 202;
		case 7:
		return 197;
		case 29:
		return 211;
		case 14:
		return 201;
		case 16:
		return 203;
		case 4:
		return 194;
		case 264:
		return 1071;
	}
	return -1;
} 