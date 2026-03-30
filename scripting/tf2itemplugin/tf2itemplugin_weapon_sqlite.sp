#include <dbi>

Database		  g_db_weapons	= null;

bool			  g_isConnected = false;

/**
 * Schema for the tf2itemplugin_weapons table.
 */
char sqlite_schema_tf2itemplugin_weapons[2048] = 
"CREATE TABLE IF NOT EXISTS tf2itemplugin_weapons (" ...
	"steam_id VARCHAR(64) NOT NULL," ...
	"class INTEGER NOT NULL," ...
	"slotId INTEGER NOT NULL," ...
	"isActiveOverride INTEGER NOT NULL," ...
	"weaponDefIndex INTEGER NOT NULL," ...
	"stockWeaponDefIndex INTEGER NOT NULL," ...
	"quality INTEGER NOT NULL," ...
	"level INTEGER NOT NULL," ...
	"isAustralium INTEGER NOT NULL," ...
	"isFestive INTEGER NOT NULL," ...
	"warPaintId INTEGER NOT NULL," ...
	"warPaintWear REAL NOT NULL," ...
	"unusualEffectId INTEGER NOT NULL," ...
	"halloweenSpellIsActive INTEGER NOT NULL," ...
	"halloweenSpellSpells INTEGER NOT NULL," ...
	"killstreakIsActive INTEGER NOT NULL," ...
	"killstreakTier INTEGER NOT NULL," ...
	"killstreakSheen INTEGER NOT NULL," ...
	"killstreakKillstreaker INTEGER NOT NULL," ...
	"PRIMARY KEY (steam_id, class, slotId)" ...
");";

public void TF2ItemPlugin_SQL_ConnectToDatabase(Database db, const char[] error, any data)
{
	// If no database object was found, preference saving is now disabled.
	if (db == null)
	{
		LogError("FATAL ERROR: Could not connect to SQLite database. Preference saving/loading will be disabled until a plugin reload is made.");
		g_isConnected = false;

		return;
	}

	// Establish the global database connection handle.
	g_db_weapons  = db;
	g_isConnected = true;

	// Make sure schemas are created.
	g_db_weapons.Query(TF2ItemPlugin_SQLCallback_NullQueryResults, sqlite_schema_tf2itemplugin_weapons);

	// Log the result.
	LogMessage("Connected successfully to database.");
}

public void TF2ItemPlugin_SQLCallback_NullQueryResults(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || results == null)
	{
		LogError("Query has failed: \"%s\"", error);
		return;
	}

	LogMessage("Query has been executed successfully.");

	// Nullify the results handle.
	delete results;
}

/**
 * Sends a query to obtain a player's saved preferences and loads them on memory.
 *
 * @param client The client ID to search for.
 *
 * @return void
 */
stock void TF2ItemPlugin_SQL_SearchPlayerPreferences(int client)
{
	// If the user is on cooldown, ignore the request.
	if (g_bIsOnDatabaseCooldown[client])
	{
		CPrintToChat(client, "%s You are currently on cooldown. Please wait a moment before trying again.", PLUGIN_CHATTAG);
		return;
	}

	if (!g_isConnected)
	{
		LogError("Database connection is not established. Ignoring search request.");
		return;
	}

	// Obtain the client's Steam2 ID.
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

	// Build a query to search for all the client's preferences.
	char query[512];
	g_db_weapons.Format(query, sizeof(query),
						"SELECT * FROM tf2itemplugin_weapons WHERE steam_id = '%s'",
						steamId);

	LogMessage("Searching for preferences for user %s", steamId);

	g_db_weapons.Query(TF2ItemPlugin_SQLCallback_PreferenceSearch, query, GetClientUserId(client));
}

public void TF2ItemPlugin_SQLCallback_PreferenceSearch(Database db, DBResultSet results, const char[] error, int userId)
{
	if (db == null || results == null)
	{
		LogError("Preference search query has failed: \"%s\"", error);
		return;
	}

	// Obtain the client entity ID.
	int client = GetClientOfUserId(userId);

	// If no results were found, simply ignore.
	if (!results.RowCount)
	{
		// If the user is in-game, notify them.
		if (IsClientInGame(client))
			CPrintToChat(client, "%s You have no saved preferences on this server.", PLUGIN_CHATTAG);

		LogMessage("No preferences found for user %d", userId);
		return;
	}

	// Load every row into the corresponding slot.
	while (results.FetchRow())
	{
		// Temporary variable to obtain field indices.
		int						 temp = 0;

		// Declare an inventory for this row, fully reset.
		TFInventory_Weapons_Slot inventory;
		inventory.Reset(true);

		inventory.client = client;

		// Build the instance.
		results.FieldNameToNum("class", temp);
		inventory.class = results.FetchInt(temp);

		results.FieldNameToNum("slotId", temp);
		inventory.slotId = results.FetchInt(temp);

		results.FieldNameToNum("isActiveOverride", temp);
		inventory.isActiveOverride = view_as<bool>(results.FetchInt(temp));

		results.FieldNameToNum("weaponDefIndex", temp);
		inventory.weaponDefIndex = results.FetchInt(temp);

		results.FieldNameToNum("stockWeaponDefIndex", temp);
		inventory.stockWeaponDefIndex = results.FetchInt(temp);

		results.FieldNameToNum("quality", temp);
		inventory.quality = results.FetchInt(temp);

		results.FieldNameToNum("level", temp);
		inventory.level = results.FetchInt(temp);

		results.FieldNameToNum("isAustralium", temp);
		inventory.isAustralium = view_as<bool>(results.FetchInt(temp));

		results.FieldNameToNum("isFestive", temp);
		inventory.isFestive = view_as<bool>(results.FetchInt(temp));

		results.FieldNameToNum("warPaintId", temp);
		inventory.warPaintId = results.FetchInt(temp);

		results.FieldNameToNum("warPaintWear", temp);
		inventory.warPaintWear = results.FetchFloat(temp);

		results.FieldNameToNum("unusualEffectId", temp);
		inventory.unusualEffectId = results.FetchInt(temp);

		results.FieldNameToNum("halloweenSpellIsActive", temp);
		inventory.halloweenSpell.isActive = view_as<bool>(results.FetchInt(temp));

		results.FieldNameToNum("halloweenSpellSpells", temp);
		inventory.halloweenSpell.spells = results.FetchInt(temp);

		results.FieldNameToNum("killstreakIsActive", temp);
		inventory.killstreak.isActive = view_as<bool>(results.FetchInt(temp));

		results.FieldNameToNum("killstreakTier", temp);
		inventory.killstreak.tier = results.FetchInt(temp);

		results.FieldNameToNum("killstreakSheen", temp);
		inventory.killstreak.sheen = results.FetchInt(temp);

		results.FieldNameToNum("killstreakKillstreaker", temp);
		inventory.killstreak.killstreaker						 = results.FetchInt(temp);

		// Apply the inventory to the client.
		g_inventories[client][inventory.class][inventory.slotId] = inventory;
	}

	// Enable their cooldown status.
	float cooldown					= g_cvar_weapons_databaseCooldown.FloatValue;
	g_bIsOnDatabaseCooldown[client] = (cooldown > -1.0);

	if (g_bIsOnDatabaseCooldown[client])
		CreateTimer(cooldown, TF2ItemPlugin_SQL_HandlePlayerCooldown, userId);

	if (IsClientInGame(client))
		CPrintToChat(client, "%s %d preferences have been loaded. Changes will take effect on next respawn.", PLUGIN_CHATTAG, results.RowCount);

	LogMessage("Loaded %d preferences for user %d", results.RowCount, userId);
}

/**
 * Saves all current preferences for a client into the database.
 *
 * @param client The client ID to save preferences for.
 *
 * @return void
 */
stock void TF2ItemPlugin_SQL_SavePlayerPreferences(int client)
{
	// If the user is on cooldown, ignore the request.
	if (g_bIsOnDatabaseCooldown[client])
	{
		CPrintToChat(client, "%s You are currently on cooldown. Please wait a moment before trying again.", PLUGIN_CHATTAG);
		return;
	}

	if (!g_isConnected)
	{
		LogError("Database connection is not established. Ignoring save request.");
		return;
	}

	// Obtain the client's Steam2 ID.
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

	// Delete all previous preferences for this user.
	TF2ItemPlugin_SQL_DeletePlayerPreferences(client, true);

	// Iterate over all the client's preferences.
	for (int class = 0; class < MAX_CLASSES; class ++)
	{
		for (int slot = 0; slot < MAX_WEAPONS; slot++)
		{
			// Obtain the inventory slot.
			TFInventory_Weapons_Slot inventory;
			inventory = g_inventories[client][class][slot];

			// Build a query to insert the client's preferences.
			char query[1024];
			g_db_weapons.Format(query, sizeof(query),
								"INSERT INTO tf2itemplugin_weapons (steam_id, class, slotId, isActiveOverride, weaponDefIndex, stockWeaponDefIndex, quality, level, isAustralium, isFestive, warPaintId, warPaintWear, unusualEffectId, halloweenSpellIsActive, halloweenSpellSpells, killstreakIsActive, killstreakTier, killstreakSheen, killstreakKillstreaker) VALUES ('%s', %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %f, %d, %d, %d, %d, %d, %d, %d)",
								steamId, class, slot, inventory.isActiveOverride, inventory.weaponDefIndex, inventory.stockWeaponDefIndex, inventory.quality, inventory.level, inventory.isAustralium, inventory.isFestive, inventory.warPaintId, inventory.warPaintWear, inventory.unusualEffectId, inventory.halloweenSpell.isActive, inventory.halloweenSpell.spells, inventory.killstreak.isActive, inventory.killstreak.tier, inventory.killstreak.sheen, inventory.killstreak.killstreaker);

			LogMessage("Saving preferences for user %s", steamId);

			g_db_weapons.Query(TF2ItemPlugin_SQLCallback_NullQueryResults, query, client);
		}
	}

	// Enable their cooldown status.
	float cooldown					= g_cvar_weapons_databaseCooldown.FloatValue;
	g_bIsOnDatabaseCooldown[client] = (cooldown > -1.0);

	if (g_bIsOnDatabaseCooldown[client])
		CreateTimer(cooldown, TF2ItemPlugin_SQL_HandlePlayerCooldown, GetClientUserId(client));

	if (IsClientInGame(client))
		CPrintToChat(client, "%s Your preferences have been saved.", PLUGIN_CHATTAG);

	LogMessage("Saved preferences for user %s", steamId);
}

/**
 * Deletes all saved preferences for a client from the database.
 *
 * @param client The client ID to delete preferences for.
 *
 * @return void
 */
stock void TF2ItemPlugin_SQL_DeletePlayerPreferences(int client, bool silent = false)
{
	if (!g_isConnected)
	{
		LogError("Database connection is not established. Ignoring delete request.");
		return;
	}

	// Create a query string to delete all preferences for this user.
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

	char query[512];
	g_db_weapons.Format(query, sizeof(query),
						"DELETE FROM tf2itemplugin_weapons WHERE steam_id = '%s'",
						steamId);

	LogMessage("Deleting preferences for user %s", steamId);

	g_db_weapons.Query(TF2ItemPlugin_SQLCallback_NullQueryResults, query, client);

	// Enable their cooldown status.
	float cooldown					= g_cvar_weapons_databaseCooldown.FloatValue;
	g_bIsOnDatabaseCooldown[client] = (cooldown > -1.0);

	if (g_bIsOnDatabaseCooldown[client])
		CreateTimer(cooldown, TF2ItemPlugin_SQL_HandlePlayerCooldown, GetClientUserId(client));

	if (IsClientInGame(client) && !silent)
		CPrintToChat(client, "%s Your preferences have been deleted.", PLUGIN_CHATTAG);
}

/**
 * Handles the end of a cooldown for a client.
 */
public Action TF2ItemPlugin_SQL_HandlePlayerCooldown(Handle timer, int userId)
{
	// Obtain the client entity ID.
	int client						= GetClientOfUserId(userId);

	// Disable the cooldown status.
	g_bIsOnDatabaseCooldown[client] = false;

	return Plugin_Stop;
}