#include "tf2itemplugin/tf2itemplugin_base.sp"
#include "tf2itemplugin/tf2itemplugin_cosmetics_base.sp"
#include "tf2itemplugin/tf2itemplugin_cosmetics_data.sp"
#include "tf2itemplugin/tf2itemplugin_cosmetics_requests.sp"
#include "tf2itemplugin/tf2itemplugin_cosmetics_sqlite.sp"
#include "tf2itemplugin/tf2itemplugin_cosmetics_menus.sp"

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "4.0.2"
#define DEBUG          true

public Plugin myinfo =
{
    name        = "TF2 Item Plugins - Cosmetics Manager",
    author      = "Lucas 'punteroo' Maza",
    description = "Customize your cosmetic items and manage your server inventory.",
    version     = PLUGIN_VERSION,
    url         = "https://github.com/punteroo/TF2-Item-Plugins"
};

/**
 * Load the "Regenerate" SDK call to refresh player inventories.
 *
 * @return Handle to the "Regenerate" SDK call.
 */
public Handle TF2ItemPlugin_LoadRegenerateSDK()
{
    // Load TF2 gamedata.
    Handle hGameConf = LoadGameConfigFile("sm-tf2.games");

    // Prepare the SDK call for the player entity.
    StartPrepSDKCall(SDKCall_Player);

    // Set the SDK call to find the "Regenerate" signature.
    PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "Regenerate");
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);

    // End the SDK call preparation.
    return EndPrepSDKCall();
}

/**
 * Uses hooks to attach into the maps' `func_respawnroom` entities to determine if a player is within a spawn room.
 *
 * @return void
 */
public void TF2ItemPlugin_AttachSpawnRoomHooks()
{
    // Declare a starting index for the spawn room entities.
    int trigger = -1;

    while ((trigger = FindEntityByClassname(trigger, "func_respawnroom")) != -1)
    {
        // Hook callbacks into the trigger.
        SDKHook(trigger, SDKHook_StartTouch, OnStartTouchSpawnRoom);
        SDKHook(trigger, SDKHook_EndTouch, OnEndTouchSpawnRoom);
    }
}

public Action OnStartTouchSpawnRoom(int entity, int other)
{
    // Check if the entity is a valid client index
    if (other < 1 || other > MaxClients)
        return Plugin_Continue;

    // Is this entity a player?
    if (!IsClientInGame(other))
        return Plugin_Continue;

    // If player is alive and real, mark them as in spawn room.
    if (IsPlayerAlive(other) && !IsClientSourceTV(other) && !IsClientObserver(other))
        g_bInSpawnRoom[other] = true;

    return Plugin_Continue;
}

public Action OnEndTouchSpawnRoom(int entity, int other)
{
    // Check if the entity is a valid client index
    if (other < 1 || other > MaxClients)
        return Plugin_Continue;

    // Is this entity a player?
    if (!IsClientInGame(other))
        return Plugin_Continue;

    // If player is alive and real, mark them as not in spawn room.
    if (IsPlayerAlive(other) && !IsClientSourceTV(other) && !IsClientObserver(other))
        g_bInSpawnRoom[other] = false;

    return Plugin_Continue;
}

public void OnPluginStart()
{
    g_cvar_cosmetics_onlySpawn         = CreateConVar("tf2items_cosmetics_spawn_only", "0.0",
                                            "If enabled, cosmetic overrides can only be changed in spawn regions.", 0, true, 0.0, true, 1.0);

    g_cvar_cosmetics_unusualEffectsURL = CreateConVar("tf2items_cosmetics_unusuals_url", "https://raw.githubusercontent.com/punteroo/TF2-Item-Plugins/production/tf2_unusuals.json",
                                            "URL from where to fetch the Unusual effects data.");

    g_cvar_cosmetics_searchTimeout     = CreateConVar("tf2items_cosmetics_search_timeout", "15.0",
                                            "The amount of time (in seconds) to wait before timing out a player Unusual effect search.", 0, true, 5.0, true, 60.0);

    g_cvar_cosmetics_databaseCooldown  = CreateConVar("tf2items_cosmetics_database_cooldown", "15.0",
                                            "The amount of time in seconds to wait before a player can perform a database action. -1 disables the cooldown.", 0, true, -1.0, true, 60.0);

    // Load the "Regenerate" SDK call.
    hRegen                             = TF2ItemPlugin_LoadRegenerateSDK();

    // Find the network offsets for the weapon clip and ammo.
    clipOff                            = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
    ammoOff                            = FindSendPropInfo("CTFPlayer", "m_iAmmo");

    // Register the cosmetic manager commands.
    RegConsoleCmd("sm_hats", CMD_TF2ItemPlugin_CosmeticManager, "Manage your cosmetics on the server.");
    RegConsoleCmd("sm_hat", CMD_TF2ItemPlugin_CosmeticManager, "Manage your cosmetics on the server.");
    RegConsoleCmd("sm_cosmetics", CMD_TF2ItemPlugin_CosmeticManager, "Manage your cosmetics on the server.");
    RegConsoleCmd("sm_cosmetic", CMD_TF2ItemPlugin_CosmeticManager, "Manage your cosmetics on the server.");
    RegConsoleCmd("sm_myhats", CMD_TF2ItemPlugin_CosmeticManager, "Manage your cosmetics on the server.");

    // Connect to the SQlite database.
    Database.Connect(TF2ItemPlugin_SQL_ConnectToDatabase, "tf2itemplugins_db");
}

public void OnClientAuthorized(int client, const char[] auth)
{
    // Initialize the inventory for the client.
    TF2ItemPlugin_InitializeInventory(client);

    // Search for the client's preferences.
    TF2ItemPlugin_SQL_SearchPlayerPreferences(client);

    // Disable their cooldown flag.
    g_bIsOnDatabaseCooldown[client] = false;
}

public void OnMapStart()
{
    // Attach hooks to the spawn room entities.
    TF2ItemPlugin_AttachSpawnRoomHooks();

    // Setup an HTTP request to obtain latest Unusual effects information.
    char url[512];
    g_cvar_cosmetics_unusualEffectsURL.GetString(url, sizeof(url));

    LogMessage("Requesting Unusual effects information from %s", url);

    TF2ItemPlugin_RequestUnusualEffectsData(url);
}

public Action CMD_TF2ItemPlugin_CosmeticManager(int client, int args)
{
    // If the client is not in a spawn room and the cvar is enabled, notify them.
    if (!g_bInSpawnRoom[client] && g_cvar_cosmetics_onlySpawn.BoolValue)
    {
        CPrintToChat(client, "%s You must be in a spawn room to manage your cosmetic items.", PLUGIN_CHATTAG);
        return Plugin_Handled;
    }

    // Open the cosmetics menu for the client.
    TF2ItemPlugin_Menus_MainMenu(client);

    return Plugin_Handled;
}
