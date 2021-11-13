#include <sourcemod>
#include <lang>
#include <tf2_stocks>
#include <sdkhooks>
#include <clientprefs>

#include <morecolors>

#include <tf2items>
#include <tf2attributes>
#include <tf_econ_data>

/*
 * Change-Log
 *
 * 3.1.3 - 13/11/21
 * tf2item_weapons
 *  - Fixed #16
 *    - Players with set overrides on any class could mask item indexes to be given weapons they must not equip by disguising.
 *    - Disguise Weapons would fire TF2Items_OnGiveNamedItem
 *
 * 3.1.2 - 04/11/21
 * General
 *  - Fixed ArrayLists not being properly initialized through map changes.
 *
 * 3.1.1 - 03/11/21
 * General
 *  - Fixed #13
 *    - Overlooked ConVar declaration mistake in logic.
 *
 * 3.1.0 - 02/11/21
 * General
 *  - Implemented search functionality for Unusual effects and War Paints.
 *    - Players can now select an option and type their query on chat to search for specific entries.
 *    - Players have 15 seconds before this query expires.
 *  - Implemented preference saving.
 *    - Added a new ConVar: tf2items_save_preferences
 *      - Controls if both plugins will utilize the Cookies system to keep user preferences. Requires plugin reload on change.
 *    - Player selections and overrides will be saved after making any change to their modifications.
 *  - Fixed #11
 *    - Plugins late loading would throw an Invalid ConVar error due to it not being declared before hand on late loading.
 *  - Bug fixes and more memory management to prevent leaks.
 * tf2item_weapons
 *  - Fixed setting War Paints on real Australium weapons not being displayed due to bad logic handling.
 *
 * 3.0.2 - 14/10/21
 * tf2item_weapons
 *  - Fixed a wrongly initialized value for connecting players causing them to recieve a stock bat regardless of class.
 * tf2item_cosmetics
 *  - Fixed Unusual overrides not being added to the menu regardless of ConVar value (parenthesis mistake)
 *
 * 3.0.1 - 13/10/21
 * 
 * General
 *  - Implemented ConVar functionality
 * tf2item_weapons
 *  - Implemented a manual classname re-write for saxxy weapons (Issue #5).
 *    - TF2Items does not automatically set the proper classname for multi-class weapons.
 *  - Adapted functionality to utilize "Special Weapons"
 *    - Players can give themselves special weapons such as: The Golden Frying Pan, The Saxxy and The Golden Wrench
 *
 * 3.0.0 - 12/10/21
 *
 *  - Initial release (Full changes: https://github.com/punteroo/TF2-Item-Plugins/releases/tag/v3.0.0)
 *
 * Legacy Versions (Those before v3.0.0): https://github.com/punteroo/TF2-Item-Plugins/releases
 */

// Global Static Defines
////////////////////////

#define PGTAG            "{mythical}[TF2Items]{white}"

// Is the player currently in a spawn region?
bool bPlayerInSpawn[MAXPLAYERS + 1] = false;

// I am now officially a student of dark arts. Don't thank me, thank my master: Scag :)
stock ConVar CV_OnlySpawn, CV_LogMissingTranslations, CV_UseCookies,

CV_Cosmetics_Unusuals, CV_Cosmetics_Paint, CV_Cosmetics_Spells, CV_Cosmetics_ShowIDs, CV_Cosmetics_UParticles;

//    ConVars and more customization for user experiences.
// 			TODO: Implement convar usage
public void OnConfigsExecuted() {
	// Global
	CV_OnlySpawn              = CreateConVar("tf2items_general_onlyspawn", "0", "Controls wether players can only modify their items inside spawn boundaries. Default is 1.", _, true, 0.0, true, 1.0);
	CV_LogMissingTranslations = CreateConVar("tf2items_cosmetics_show_missing_particles", "0", "Logs to the server whenever a parsed Unusual Particle/War Paint ID does not have an" ...
																							 " existing translation for their name. I recommend leaving this off, as it causes" ...
																							 " too much console spam and should only be used to debug. Default is 0.", _, true, 0.0, true, 1.0),
	CV_UseCookies			  = CreateConVar("tf2items_save_preferences", "1", "Enables the use of Player Cookies to save selected preferences. Default is 1.", _, true, 0.0, false, 1.0);
	
	// Cosmetics Manager
	CV_Cosmetics_Unusuals   = CreateConVar("tf2items_cosmetics_unusuals", "1", "Are unusual overrides enabled? Default is 1.", _, true, 0.0, true, 1.0);
	CV_Cosmetics_Paint      = CreateConVar("tf2items_cosmetics_paints", "1", "Are paint overrides enabled? Default is 1.", _, true, 0.0, true, 1.0);
	CV_Cosmetics_Spells     = CreateConVar("tf2items_cosmetics_spells", "1", "Are halloween spells overrides enabled? Default is 1.", _, true, 0.0, true, 1.0);
	CV_Cosmetics_ShowIDs    = CreateConVar("tf2items_cosmetics_append_ids", "0", "Should Item Definition Indexes and Unusual Effect Indexes be appended onto their names? " ...
																				 "Example: 'Burning Flames (#13)'", _, true, 0.0, true, 1.0);
																							 	
}

// Weapons Manager


// General Functions
////////////////////

// Hooks func_respawnroom entities in the map to detect players that get in it.
void HookRespawns(bool unhook = false) {
	// If the value is off, this hooking should not be done.
	if (!CV_OnlySpawn.BoolValue) return;
	
	int ent = -1;
	while ( (ent = FindEntityByClassname(ent, "func_respawnroom")) != -1) {
		unhook ? SDKUnhook(ent, SDKHook_Touch,    OnTouchSpawn)        : SDKHook(ent, SDKHook_Touch,    OnTouchSpawn);
		unhook ? SDKUnhook(ent, SDKHook_EndTouch, OnStopTouchingSpawn) : SDKHook(ent, SDKHook_EndTouch, OnStopTouchingSpawn);
	}
	
	if (unhook) {
		for (int i = 1; i < MaxClients; i++)
			bPlayerInSpawn[i] = false;
	}
}

public void OnTouchSpawn(int entity, int client) {
	// Ignore invalid entities.
	if (!IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client) || client > MaxClients || !CV_OnlySpawn.BoolValue) return;
	
	if (GetClientTeam(client) == GetEntProp(entity, Prop_Send, "m_iTeamNum"))
		bPlayerInSpawn[client] = true;
}

public void OnStopTouchingSpawn(int entity, int client) {
	// Ignore invalid entities.
	if (!IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client) || client > MaxClients || !CV_OnlySpawn.BoolValue) return;
	
	if (GetClientTeam(client) == GetEntProp(entity, Prop_Send, "m_iTeamNum"))
		bPlayerInSpawn[client] = false;
}