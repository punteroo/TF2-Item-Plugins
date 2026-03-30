#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <steamworks>

#include "tf2itemplugin/tf2itemplugin_base.sp"
#include "tf2itemplugin/tf2itemplugin_weapon_base.sp"
#include "tf2itemplugin/tf2itemplugin_weapon_sqlite.sp"
#include "tf2itemplugin/tf2itemplugin_weapon_data.sp"
#include "tf2itemplugin/tf2itemplugin_weapon_menus.sp"
#include "tf2itemplugin/tf2itemplugin_weapon_requests.sp"

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "4.0.2"
#define DEBUG          false

public Plugin myinfo =
{
    name        = "TF2 Item Plugins - Weapons Manager",
    author      = "Lucas 'punteroo' Maza",
    description = "Customize your weapons and manage your server inventory.",
    version     = PLUGIN_VERSION,
    url         = "https://github.com/punteroo/TF2-Item-Plugins"
};

/**
 * Load the "Regenerate" SDK call to refresh player inventories.
 *
 * @return Handle to the "Regenerate" SDK call.
 */
Handle TF2ItemPlugin_LoadRegenerateSDK()
{
    Handle hGameConf = LoadGameConfigFile("sm-tf2.games");
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "Regenerate");
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
    
    Handle call = EndPrepSDKCall();
    delete hGameConf;
    return call;
}

/**
 * Uses hooks to attach into the maps' `func_respawnroom` entities to determine if a player is within a spawn room.
 *
 * @return void
 */
void TF2ItemPlugin_AttachSpawnRoomHooks()
{
    int trigger = -1;
    while ((trigger = FindEntityByClassname(trigger, "func_respawnroom")) != -1)
    {
        SDKHook(trigger, SDKHook_StartTouch, OnStartTouchSpawnRoom);
        SDKHook(trigger, SDKHook_EndTouch, OnEndTouchSpawnRoom);
    }
}

public Action OnStartTouchSpawnRoom(int entity, int other)
{
    if (IsValidClient(other))
        g_bInSpawnRoom[other] = true;
    return Plugin_Continue;
}

public Action OnEndTouchSpawnRoom(int entity, int other)
{
    if (IsValidClient(other))
        g_bInSpawnRoom[other] = false;
    return Plugin_Continue;
}

public void OnPluginStart()
{
    g_cvar_weapons_onlySpawn = CreateConVar("tf2items_weapons_spawnonly", "0", "If enabled, weapon changes are only allowed when the player is within a spawn room.", _, true, 0.0, true, 1.0);
    g_cvar_weapons_paintKitsUrl = CreateConVar("tf2items_weapons_paintkits_url", "https://raw.githubusercontent.com/punteroo/TF2-Item-Plugins/production/tf2_protos.json", "The URL to the JSON file containing the War Paints and their IDs. Must be a valid JSON array.");
    g_cvar_weapons_searchTimeout = CreateConVar("tf2items_weapons_search_timeout", "20.0", "The amount of time in seconds to wait for a search to complete before timing out.", _, true, 5.0, true, 60.0);
    g_cvar_weapons_databaseCooldown = CreateConVar("tf2items_weapons_database_cooldown", "15.0", "The amount of time in seconds to wait before a player can perform a database action. -1 disables the cooldown.", _, true, -1.0);

    hRegen = TF2ItemPlugin_LoadRegenerateSDK();
    clipOff = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
    ammoOff = FindSendPropInfo("CTFPlayer", "m_iAmmo");

    RegConsoleCmd("sm_weapons", CMD_TF2ItemPlugin_WeaponManager, "Manage weapons on the server.");
    RegConsoleCmd("sm_weapon", CMD_TF2ItemPlugin_WeaponManager, "Manage weapons on the server.");
    RegConsoleCmd("sm_wep", CMD_TF2ItemPlugin_WeaponManager, "Manage weapons on the server.");
    RegConsoleCmd("sm_weps", CMD_TF2ItemPlugin_WeaponManager, "Manage weapons on the server.");

    Database.Connect(TF2ItemPlugin_SQL_ConnectToDatabase, "tf2itemplugins_db");

#if defined DEBUG
    RegAdminCmd("sm_weapons_debug", CMD_TF2ItemPlugin_DebugInventory, ADMFLAG_ROOT, "Print the player's inventory state.");
    RegAdminCmd("sm_weapons_debug_current", CMD_TF2ItemPlugin_DebugCurrent, ADMFLAG_ROOT, "Print the player's current weapon state.");
    RegAdminCmd("sm_weapons_debug_force_call", CMD_TF2ItemPlugin_ForceCall, ADMFLAG_ROOT, "Force a call to the Regenerate function.");
#endif
}

public void OnMapStart()
{
    TF2ItemPlugin_AttachSpawnRoomHooks();

    char url[512];
    g_cvar_weapons_paintKitsUrl.GetString(url, sizeof(url));
    LogMessage("Requesting paint kit data from %s", url);
    TF2ItemPlugin_RequestPaintKitData(url);
}

public void OnClientAuthorized(int client)
{
    TF2ItemPlugin_InitializeInventory(client);
    TF2ItemPlugin_SQL_SearchPlayerPreferences(client);
    g_bIsOnDatabaseCooldown[client] = false;
}

public Action CMD_TF2ItemPlugin_WeaponManager(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (!g_bInSpawnRoom[client] && g_cvar_weapons_onlySpawn.BoolValue)
    {
        CPrintToChat(client, "%s You must be in a spawn room to manage your weapons.", PLUGIN_CHATTAG);
        return Plugin_Handled;
    }

    TF2ItemPlugin_Menus_MainMenu(client);
    return Plugin_Handled;
}

#if defined DEBUG
void Print_Slot(int client, int class, int slot)
{
    PrintToConsole(client, "Slot %d:\n"
        ... "Client ID: %d\n"
        ... "Class ID: %d\n"
        ... "Slot ID: %d\n"
        ... "Active Override: %d\n"
        ... "Weapon Def Index: %d\n"
        ... "Stock Def Index: %d\n"
        ... "Quality: %d\n"
        ... "Level: %d\n"
        ... "Australium: %d\n"
        ... "Festive: %d\n"
        ... "Unusual Effect: %d\n"
        ... "War Paint ID: %d\n"
        ... "War Paint Wear: %f\n"
        ... "- Killstreak:\n"
        ... "  - Active: %d\n"
        ... "  - Tier: %d\n"
        ... "  - Sheen: %d\n"
        ... "  - Killstreaker: %d\n"
        ... "Spells Bitfield: %d\n"
        ... "\n\n",
        slot, g_inventories[client][class][slot].client,
        g_inventories[client][class][slot].class, g_inventories[client][class][slot].slotId,
        g_inventories[client][class][slot].isActiveOverride, g_inventories[client][class][slot].weaponDefIndex, g_inventories[client][class][slot].stockWeaponDefIndex,
        g_inventories[client][class][slot].quality, g_inventories[client][class][slot].level,
        g_inventories[client][class][slot].isAustralium, g_inventories[client][class][slot].isFestive,
        g_inventories[client][class][slot].unusualEffectId, g_inventories[client][class][slot].warPaintId,
        g_inventories[client][class][slot].warPaintWear, g_inventories[client][class][slot].killstreak.isActive,
        g_inventories[client][class][slot].killstreak.tier, g_inventories[client][class][slot].killstreak.sheen,
        g_inventories[client][class][slot].killstreak.killstreaker, g_inventories[client][class][slot].halloweenSpell.spells);
}

public Action CMD_TF2ItemPlugin_DebugInventory(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    PrintToConsole(client, "Inventory Debug\n\n\n");

    if (args >= 1)
    {
        char class[2];
        GetCmdArg(1, class, sizeof(class));
        int iclass = StringToInt(class);

        if (args >= 2)
        {
            char slot[2];
            GetCmdArg(2, slot, sizeof(slot));
            int islot = StringToInt(slot);

            PrintToConsole(client, "For class %d, slot %d\n", iclass, islot);
            Print_Slot(client, iclass, islot);
            return Plugin_Handled;
        }

        PrintToConsole(client, "For class %d\n", iclass);
        for (int j = 0; j < MAX_WEAPONS; j++)
            Print_Slot(client, iclass, j);

        return Plugin_Handled;
    }

    for (int i = 0; i < MAX_CLASSES; i++)
    {
        PrintToConsole(client, "For class %d\n", i);
        for (int j = 0; j < MAX_WEAPONS; j++)
        {
            Print_Slot(client, i, j);
        }
    }

    return Plugin_Handled;
}

public Action CMD_TF2ItemPlugin_DebugCurrent(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

    if (!IsValidEntity(weapon))
    {
        PrintToConsole(client, "No weapon found.");
        return Plugin_Handled;
    }

    int defIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

    int indexes[16];
    float values[16];
    TF2Attrib_GetSOCAttribs(weapon, indexes, values);

    PrintToConsole(client, "Current Weapon: %d\n"
        ... "Item Definition Index: %d\n\n", weapon, defIndex);

    PrintToConsole(client, "SOC Attributes\n\n");
    for (int i = 0; i < 16; i++)
    {
        if (indexes[i] == 0)
            break;

        PrintToConsole(client, "SOC Attribute %d: %d = %f", i, indexes[i], values[i]);
    }

    PrintToConsole(client, "Attributes\n\n");

    int attributes[16];
    int count = TF2Attrib_ListDefIndices(weapon, attributes);

    for (int i = 0; i < count; i++)
    {
        if (attributes[i] == 0)
            continue;

        Address attrib = TF2Attrib_GetByDefIndex(weapon, attributes[i]);
        float value = TF2Attrib_GetValue(attrib);

        PrintToConsole(client, "Attribute %d: %d = %f", i, attributes[i], value);
    }

    return Plugin_Handled;
}

public Action CMD_TF2ItemPlugin_ForceCall(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    SDKCall(hRegen, client, false);
    return Plugin_Handled;
}
#endif

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && !IsClientReplay(client));
}
