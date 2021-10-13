#include <sourcemod>
#include <lang>
#include <tf2_stocks>

#include <morecolors>

#include <tf2items>
#include <tf2attributes>
#include <tf_econ_data>

/*
 * Change-Log
 *
 * 3.0.1 - 13/10/21
 * 
 * General
 *  - Implemented ConVar functionality
 * tf2item_weapons
 *  - Implemented a manual classname re-write for saxxy weapons (Issue #5).
 *    - TF2Items does not automatically set the proper classname for multi-class weapons.
 *  - Added functionality to utilize "Special Weapons"
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

//    ConVars and more customization for user experiences.
// 			TODO: Implement convar usage
// Global
ConVar CV_OnlySpawn = CreateConVar("tf2items_general_onlyspawn", "0", "Controls wether players can only modify their items inside spawn boundaries. Default is 1.", _, true, 0.0, true, 1.0),
	   
// Cosmetics Manager
CV_Cosmetics_Unusuals   = CreateConVar("tf2items_cosmetics_unusuals", "1", "Are unusual overrides enabled? Default is 1.", _, true, 0.0, true, 1.0),
CV_Cosmetics_Paint      = CreateConVar("tf2items_cosmetics_paints", "1", "Are paint overrides enabled? Default is 1.", _, true, 0.0, true, 1.0),
CV_Cosmetics_Spells     = CreateConVar("tf2items_cosmetics_spells", "1", "Are halloween spells overrides enabled? Default is 1.", _, true, 0.0, true, 1.0),
CV_Cosmetics_ShowIDs    = CreateConVar("tf2items_cosmetics_append_ids", "0", "Should Item Definition Indexes and Unusual Effect Indexes be appended onto their names? " ...
																			 "Example: 'Burning Flames (#13)'", _, true, 0.0, true, 1.0),
CV_Cosmetics_UParticles = CreateConVar("tf2items_cosmetics_show_missing_particles", "0", "Logs to the server whenever a parsed Unusual Particle ID does not have an" ...
																						 " existing translation for their name. I recommend leaving this off, as it causes" ...
																						 " too much console spam and should only be used to debug. Default is 0.", _, true, 0.0, true, 1.0);

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