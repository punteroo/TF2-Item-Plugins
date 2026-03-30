#define MAX_PAINTS					   1024

#define WeaponSpell_Exorcism		   (1 << 0)
#define WeaponSpell_SpectralFlames	   (1 << 1)
#define WeaponSpell_SquashRockets	   (1 << 2)
#define WeaponSpell_SentryQuadPumpkins (1 << 3)
#define WeaponSpell_GourdGrenades	   (1 << 4)

#define WeaponSpell_Explosions		   (WeaponSpell_SquashRockets | WeaponSpell_SentryQuadPumpkins | WeaponSpell_GourdGrenades)

/** Local memory copy where client inventories are stored for server use. */
TFInventory_Weapons_Slot g_inventories[MAXPLAYERS + 1][MAX_CLASSES + 1][MAX_WEAPONS + 1];

/** A list of paint kits available for the plugin to use. */
StringMap				 g_paintKits[MAX_PAINTS];

// Network prop for weapon clip.
int						 clipOff;

// Network prop for weapon ammo.
int						 ammoOff;

// Handle that stores the "Regenerate" SDK call to refresh player inventories.
Handle					 hRegen = INVALID_HANDLE;

// Array that stores wether a player is within a spawn room.
bool					 g_bInSpawnRoom[MAXPLAYERS + 1];

// Array that stores if a client is currently on database cooldown.
bool					 g_bIsOnDatabaseCooldown[MAXPLAYERS + 1];

/** ConVar that controls if weapon changes are only allowed when the player is within a spawn room. */
stock ConVar			 g_cvar_weapons_onlySpawn,
	/** ConVar that indicates the URL where the updated list of TF2 paint kit definitions is. */
	g_cvar_weapons_paintKitsUrl,
	/** ConVar that controls the maximum time a user has to search for a war paint name in chat. */
	g_cvar_weapons_searchTimeout,
	/** ConVar that controls the amount (in seconds) a user has to wait before making another load/save/reset of their preferences. Only works if the database connection is successful. */
	g_cvar_weapons_databaseCooldown;

/**
 * Transforms a stock weapons' definition index into its strange counterpart.
 *
 * Strange variants for stock weapons allow modifications such as festivizers, war paint and australiums whereas their stock counterparts do not.
 *
 * @param itemDefinitionIndex The stock weapon's item definition index to convert.
 *
 * @return The strange variant's item definition index.
 */
stock int TF2ItemPlugin_GetStrangeVariant(int itemDefinitionIndex)
{
	switch (itemDefinitionIndex)
	{
		case 10, 12, 11, 9: return 199;	   // Shotguns (Heavy, Pyro, Soldier, Engineer)
		case 22, 23:
			return 209;	   // Pistols (Engineer, Scout)
		/** Scout */
		case 13: return 200;	// Scattergun
		case 0:
			return 190;	   // Bat
		/** Soldier */
		case 18: return 205;	// Rocket Launcher
		case 6:
			return 196;	   // Shovel
		/** Pyro */
		case 21: return 208;	// Flame Thrower
		case 2:
			return 192;	   // Fire Axe
		/** Demoman */
		case 19: return 206;	// Grenade Launcher
		case 20: return 207;	// Stickybomb Launcher
		case 1:
			return 191;	   // Bottle
		/** Heavy */
		case 15: return 202;	// Minigun
		case 5:
			return 195;	   // Fists
		/** Engineer */
		case 7: return 197;	   // Wrench
		case 25:
			return 737;	   // Construction PDA
		/** Medic */
		case 17: return 204;	// Syringe Gun
		case 29: return 211;	// Medigun
		case 8:
			return 198;	   // Bonesaw
		/** Sniper */
		case 14: return 201;	// Sniper Rifle
		case 16: return 203;	// SMG
		case 3:
			return 193;	   // Kukri
		/** Spy */
		case 24: return 210;	 // Revolver
		case 735: return 736;	 // Sapper
		case 4: return 194;		 // Knife
		case 30:
			return 212;	   // Invis Watch
		// If the provided item definition index is already a strange variant, return it as is.
		case 199, 209, 200, 190, 205, 196, 208, 192, 206, 207, 191, 202, 195, 197, 737, 204, 211, 198, 201, 203, 193, 210, 736, 194, 212: return itemDefinitionIndex;
	}

	return -1;
}

/**
 * Obtains a visual representation of a weapon slot.
 *
 * @param slot The slot ID to obtain the name for.
 * @param buffer The buffer to store the slot name.
 * @param size The size of the buffer.
 *
 * @return void
 */
stock void TF2ItemPlugin_GetWeaponSlotName(int slot, char[] buffer, int size)
{
	switch (slot)
	{
		case 0: strcopy(buffer, size, "Primary");
		case 1: strcopy(buffer, size, "Secondary");
		case 2: strcopy(buffer, size, "Melee");
		case 3: strcopy(buffer, size, "PDA Slot 1");
		case 4: strcopy(buffer, size, "PDA Slot 2");
		case 5: strcopy(buffer, size, "Building Slot 1");
		default: strcopy(buffer, size, "Unknown Slot");
	}
}

enum
{
	TF2Killstreak_None		   = 0,
	TF2Killstreak_Basic		   = 1,
	TF2Killstreak_Specialized  = 2,
	TF2Killstreak_Professional = 3,
}

/**
 * Function that maps a Killstreak tier value to a string representation.
 *
 * @param tier The Killstreak tier value.
 * @param buffer The buffer to store the string representation.
 * @param size The size of the buffer.
 *
 * @return void
 */
stock void
	TF2ItemPlugin_GetKillstreakTierString(int tier, char[] buffer, int size)
{
	switch (tier)
	{
		case -1, 0: strcopy(buffer, size, "None");
		case 1: strcopy(buffer, size, "Basic");
		case 2: strcopy(buffer, size, "Specialized");
		case 3: strcopy(buffer, size, "Professional");
		default: strcopy(buffer, size, "Unknown");
	}
}

enum
{
	TF2Killstreak_Sheen_None			 = 0,
	TF2Killstreak_Sheen_TeamShine		 = 1,
	TF2Killstreak_Sheen_DeadlyDaffodil	 = 2,
	TF2Killstreak_Sheen_Manndarin		 = 3,
	TF2Killstreak_Sheen_MeanGreen		 = 4,
	TF2Killstreak_Sheen_AgonizingEmerald = 5,
	TF2Killstreak_Sheen_VillainousViolet = 6,
	TF2Killstreak_Sheen_HotRod			 = 7,
}

/**
 * Function that maps a Killstreak sheen value to a string representation.
 *
 * @param sheen The Killstreak sheen value.
 * @param buffer The buffer to store the string representation.
 * @param size The size of the buffer.
 *
 * @return void
 */
stock void
	TF2ItemPlugin_GetKillstreakSheenString(int sheen, char[] buffer, int size)
{
	switch (sheen)
	{
		case -1, 0: strcopy(buffer, size, "None");
		case 1: strcopy(buffer, size, "Team Shine");
		case 2: strcopy(buffer, size, "Deadly Daffodil");
		case 3: strcopy(buffer, size, "Manndarin");
		case 4: strcopy(buffer, size, "Mean Green");
		case 5: strcopy(buffer, size, "Agonizing Emerald");
		case 6: strcopy(buffer, size, "Villainous Violet");
		case 7: strcopy(buffer, size, "Hot Rod");
		default: strcopy(buffer, size, "Unknown");
	}
}

enum
{
	TF2Killstreaker_None		= 0,
	TF2Killstreaker_FireHorns	= 2002,
	TF2Killstreaker_Cerebral	= 2003,
	TF2Killstreaker_Tornado		= 2004,
	TF2Killstreaker_Flames		= 2005,
	TF2Killstreaker_Singularity = 2006,
	TF2Killstreaker_Incinerator = 2007,
	TF2Killstreaker_HypnoBeam	= 2008,
}

/**
 * Function that maps a Killstreaker effect value to a string representation.
 *
 * @param effect The Killstreaker effect value.
 * @param buffer The buffer to store the string representation.
 * @param size The size of the buffer.
 *
 * @return void
 */
stock void
	TF2ItemPlugin_GetKillstreakerName(int effect, char[] buffer, int size)
{
	switch (effect)
	{
		case -1, 0: strcopy(buffer, size, "None");
		case 2002: strcopy(buffer, size, "Fire Horns");
		case 2003: strcopy(buffer, size, "Cerebral Discharge");
		case 2004: strcopy(buffer, size, "Tornado");
		case 2005: strcopy(buffer, size, "Flames");
		case 2006: strcopy(buffer, size, "Singularity");
		case 2007: strcopy(buffer, size, "Incinerator");
		case 2008: strcopy(buffer, size, "Hypno-Beam");
		default: strcopy(buffer, size, "Unknown");
	}
}

/**
 * Function that maps a spell ID to a string representation.
 *
 * @param spell The spell ID.
 * @param buffer The buffer to store the string representation.
 * @param size The size of the buffer.
 *
 * @return void
 */
stock void TF2ItemPlugin_GetHalloweenSpellName(int spell, char[] buffer, int size)
{
	switch (spell)
	{
		case 0: strcopy(buffer, size, "Exorcism");
		case 1: strcopy(buffer, size, "Spectral Flames");
		case 2: strcopy(buffer, size, "Squash Rockets");
		case 3: strcopy(buffer, size, "Sentry Quad-Pumpkins");
		case 4: strcopy(buffer, size, "Gourd Grenades");
	}
}

enum
{
	TF2WeaponUnusual_None			  = 0,
	TF2WeaponUnusual_CommunitySparkle = 4,
	TF2WeaponUnusual_Hot			  = 701,
	TF2WeaponUnusual_Isotope		  = 702,
	TF2WeaponUnusual_Cool			  = 703,
	TF2WeaponUnusual_EnergyOrb		  = 704,
}

/**
 * Function that maps a weapon Unusual Effect ID to a string representation.
 *
 * @param effect The Unusual Effect ID.
 * @param buffer The buffer to store the string representation.
 * @param size The size of the buffer.
 *
 * @return void
 */
stock void
	TF2ItemPlugin_GetUnusualEffectName(int effect, char[] buffer, int size)
{
	switch (effect)
	{
		case -1, 0: strcopy(buffer, size, "None");
		case 4: strcopy(buffer, size, "Community Sparkle");
		case 701: strcopy(buffer, size, "Hot");
		case 702: strcopy(buffer, size, "Isotope");
		case 703: strcopy(buffer, size, "Cool");
		case 704: strcopy(buffer, size, "Energy Orb");
	}
}

/**
 * Function that maps a War Paint ID to its corresponding name.
 *
 * @param warPaintId The War Paint ID.
 * @param buffer The buffer to store the string representation.
 * @param size The size of the buffer.
 *
 * @return void
 */
stock void
	TF2ItemPlugin_GetWarPaintName(int warPaintId, char[] buffer, int size)
{
	// If no war paints are available, return "None".
	int amount = 0;
	for (int i = 0; i < sizeof(g_paintKits); i++)
	{
		if (g_paintKits[i] != null)
			amount++;
	}

	if (amount == 0)
	{
		strcopy(buffer, size, "None");
		return;
	}

	// Transform the war paint ID into a string.
	char id[16];
	IntToString(warPaintId, id, sizeof(id));

	// Find the War Paint ID in the list of paint kits.
	char name[128];
	for (int i = 0; i < amount; i++)
	{
		int paintKitId = -1;
		g_paintKits[i].GetValue("id", paintKitId);

		if (paintKitId == warPaintId)
		{
			g_paintKits[i].GetString("name", name, sizeof(name));
			strcopy(buffer, size, name);
			return;
		}
	}

	// If the War Paint ID was not found, return the ID as a string.
	strcopy(buffer, size, id);
}

/**
 * Function that maps a War Paint wear value to a string representation.
 *
 * @param wear The War Paint wear value.
 * @param buffer The buffer to store the string representation.
 * @param size The size of the buffer.
 *
 * @return void
 */
stock void
	TF2ItemPlugin_GetWarPaintWearString(float wear, char[] buffer, int size)
{
	switch (wear)
	{
		case -1.0: strcopy(buffer, size, "No Override");
		case 0.0, 0.2: strcopy(buffer, size, "Factory New");
		case 0.4: strcopy(buffer, size, "Minimal Wear");
		case 0.6: strcopy(buffer, size, "Field-Tested");
		case 0.8: strcopy(buffer, size, "Well-Worn");
		case 1.0: strcopy(buffer, size, "Battle Scarred");
		default: strcopy(buffer, size, "Unknown");
	}
}

enum
{
	TF2Weapon_NoAustralium = 0,
	TF2Weapon_Australium   = 1,
	TF2Weapon_Stock		   = 2,
}

/**
 * Checks if a given item definition index can be an australium weapon.
 *
 * @param itemDefIndex The item definition index to check.
 *
 * @return A value indicating the item index's australium status.
 * - 0: The item cannot be an australium weapon.
 * - 1: The item can be an australium weapon.
 * - 2: The item is a default weapon and should be converted to its strange variant.
 */
stock int
	TF2ItemPlugin_CanItemAustralium(int iItemDefinitionIndex)
{
	switch (iItemDefinitionIndex)
	{
		case /** Unlockables */ 45, 228, 38, 132, 424, 141, 36, 61,
			/** Strange variants */ 200, 205, 208, 206, 207, 202, 197, 211, 201, 203, 194: return TF2Weapon_Australium;
		case /** Default weapons */ 13, 18, 21, 19, 20, 15, 7, 29, 14, 16, 4: return TF2Weapon_Stock;
	}

	return TF2Weapon_NoAustralium;
}

/**
 * Determines if a given item definition index can be festivized.
 *
 * @param itemDefIndex The item definition index to check.
 *
 * @return True if the item can be festivized, false otherwise.
 */
stock bool
	TF2ItemPlugin_CanItemFestivize(int iItemDefinitionIndex)
{
	// If this is not a valid definition index, return false.
	if (!TF2Econ_IsValidItemDefinition(iItemDefinitionIndex)) return false;

	// Check on TFEconData for the festivizer tag presence.
	char canBeFestivized[2];
	TF2Econ_GetItemDefinitionString(iItemDefinitionIndex, "tags/can_be_festivized", canBeFestivized, sizeof(canBeFestivized), "0");

	// Return the result.
	return view_as<bool>(StringToInt(canBeFestivized));
}

/**
 * Determines if a given item definition index can be war painted.
 *
 * @param itemDefIndex The item definition index to check.
 *
 * @return True if the item can be war painted, false otherwise.
 */
stock bool
	TF2ItemPlugin_CanItemWarPaint(int iItemDefinitionIndex)
{
	// If this is not a valid definition index, return false.
	if (!TF2Econ_IsValidItemDefinition(iItemDefinitionIndex)) return false;

	// Check on TFEconData for the paint kit tag presence.
	char prefab[64];
	TF2Econ_GetItemDefinitionString(iItemDefinitionIndex, "prefab", prefab, sizeof(prefab), "");

	// Return the result.
	return (StrContains(prefab, "paintkit_base", false) != -1);
}

/**
 * Toggles a client's weapon slot override status.
 *
 * This activates and stores information when a client's weapon slot is actively overridden.
 *
 * @param client Client index to toggle the override status for.
 * @param class The class to toggle the override status for.
 * @param slot Slot ID to toggle the override status for.
 * @param itemDefIndex The item definition index to override the slot with.
 * @param quality Optional. The quality to override the slot with.
 * @param level Optional. The level to override the slot with.
 *
 * @return void
 */
stock void TF2ItemPlugin_ToggleSlotOverride(int client, int class, int slot, int itemDefIndex, int quality = -1, int level = -1)
{
	// Toggle the override status.
	g_inventories[client][class][slot].isActiveOverride = !g_inventories[client][class][slot].isActiveOverride;

	// Set the weapon information properly.
	g_inventories[client][class][slot].weaponDefIndex	= itemDefIndex;
	g_inventories[client][class][slot].class			= class;
	g_inventories[client][class][slot].slotId			= slot;
	g_inventories[client][class][slot].quality			= quality;
	g_inventories[client][class][slot].level			= level;

	// Refresh the player's inventory.
	if (g_inventories[client][class][slot].isActiveOverride)
		TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff, slot);
}

/**
 * Toggles a client's weapon australium status.
 *
 * @param client Client index to toggle the australium status for.
 * @param slot Slot ID to toggle the australium status for.
 *
 * @return void
 */
stock void TF2ItemPlugin_ToggleAustralium(int client, int slot)
{
	// Ensure the slot is within bounds.
	if (slot < 0 || slot >= MAX_WEAPONS)
		return;

	// Get the player's class.
	int class										= TF2_GetPlayerClassInt(client);

	// Toggle the australium status for the slot.
	g_inventories[client][class][slot].isAustralium = !g_inventories[client][class][slot].isAustralium;

	// If a war paint had been selected, clear it.
	if (g_inventories[client][class][slot].isAustralium && g_inventories[client][class][slot].warPaintId)
		TF2ItemPlugin_SetWarPaint(client, slot, -1);

	// Refresh the player's inventory.
	if (g_inventories[client][class][slot].isActiveOverride)
		TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff, slot);
}

/**
 * Toggles a client's weapon festive status.
 *
 * @param client Client index to toggle the festive status for.
 * @param slot Slot ID to toggle the festive status for.
 *
 * @return void
 */
stock void TF2ItemPlugin_ToggleFestive(int client, int slot)
{
	// Ensure the slot is within bounds.
	if (slot < 0 || slot >= MAX_WEAPONS)
		return;

	// Get the player's class.
	int class									 = TF2_GetPlayerClassInt(client);

	// Toggle the festive status for the slot.
	g_inventories[client][class][slot].isFestive = !g_inventories[client][class][slot].isFestive;

	// Refresh the player's inventory.
	if (g_inventories[client][class][slot].isActiveOverride)
		TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff, slot);
}

/**
 * Toggles a client's killstreak override status.
 *
 * @param client Client index to change the killstreak override status for.
 * @param slot Slot ID to change the killstreak override status for.
 *
 * @return void
 */
stock void TF2ItemPlugin_ToggleKillstreakOverride(int client, int slot)
{
	// Ensure the slot is within bounds.
	if (slot < 0 || slot >= MAX_WEAPONS)
		return;

	// Get the player's class.
	int class											   = TF2_GetPlayerClassInt(client);

	// Toggle the killstreak override status for the slot.
	g_inventories[client][class][slot].killstreak.isActive = !g_inventories[client][class][slot].killstreak.isActive;

	// Refresh the player's inventory.
	if (g_inventories[client][class][slot].isActiveOverride)
		TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff, slot);
}

/**
 * Changes the killstreak tier for the override.
 *
 * Each time this is called, the killstreak tier is increased by one until it reaches `TF2Killstreak_Professional`.
 * If the tier is already at `TF2Killstreak_Professional`, it is reset to `TF2Killstreak_None`.
 *
 * @param client Client index to change the killstreak tier for.
 * @param slot Slot ID to change the killstreak tier for.
 * @param tier Optional. The tier to set the killstreak to.
 *
 * @return void
 */
stock void TF2ItemPlugin_ChangeKillstreakTier(int client, int slot, int tier = -1)
{
	// Ensure the slot is within bounds.
	if (slot < 0 || slot >= MAX_WEAPONS)
		return;

	// Get the player's class.
	int class = TF2_GetPlayerClassInt(client);

	// If the tier provided is not -1 but is between bounds, set the killstreak tier to it.
	if (tier != -1 && tier >= TF2Killstreak_None && tier <= TF2Killstreak_Professional)
	{
		g_inventories[client][class][slot].killstreak.tier = tier;
		return;
	}

	// If the tier is already at Professional, reset it to None.
	if (g_inventories[client][class][slot].killstreak.tier == TF2Killstreak_Professional)
		g_inventories[client][class][slot].killstreak.tier = TF2Killstreak_None;

	else
		// Otherwise, increase the tier by one.
		g_inventories[client][class][slot].killstreak.tier++;

	// Refresh the player's inventory.
	if (g_inventories[client][class][slot].isActiveOverride && g_inventories[client][class][slot].killstreak.isActive)
		TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff, slot);
}

/**
 * Sets the killstreak sheen for the override.
 *
 * @param client Client index to set the killstreak sheen for.
 * @param slot Slot ID to set the killstreak sheen for.
 * @param sheen The sheen to set the killstreak to.
 *
 * @return void
 */
stock void TF2ItemPlugin_SetKillstreakSheen(int client, int slot, int sheen)
{
	// Ensure the slot is within bounds.
	if (slot < 0 || slot >= MAX_WEAPONS)
		return;

	// Get the player's class.
	int class											= TF2_GetPlayerClassInt(client);

	// Set the killstreak sheen for the slot.
	g_inventories[client][class][slot].killstreak.sheen = sheen;

	// Refresh the player's inventory.
	if (g_inventories[client][class][slot].isActiveOverride && g_inventories[client][class][slot].killstreak.isActive)
		TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff, slot);
}

/**
 * Sets the killstreak effect for the override.
 *
 * @param client Client index to set the killstreak effect for.
 * @param slot Slot ID to set the killstreak effect for.
 * @param effect The effect to set the killstreak to.
 *
 * @return void
 */
stock void TF2ItemPlugin_SetKillstreakerEffect(int client, int slot, int effect)
{
	// Ensure the slot is within bounds.
	if (slot < 0 || slot >= MAX_WEAPONS)
		return;

	// Get the player's class.
	int class												   = TF2_GetPlayerClassInt(client);

	// Set the killstreak effect for the slot.
	g_inventories[client][class][slot].killstreak.killstreaker = effect;

	// Refresh the player's inventory.
	if (g_inventories[client][class][slot].isActiveOverride && g_inventories[client][class][slot].killstreak.isActive)
		TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff, slot);
}

/**
 * Toggles the active status for spell overrides.
 *
 * @param client Client index to toggle the spell override status for.
 * @param slot Slot ID to toggle the spell override status for.
 *
 * @return void
 */
stock void TF2ItemPlugin_ToggleSpellOverride(int client, int slot)
{
	// Ensure the slot is within bounds.
	if (slot < 0 || slot >= MAX_WEAPONS)
		return;

	// Get the player's class.
	int class												   = TF2_GetPlayerClassInt(client);

	// Toggle the spell override status for the slot.
	g_inventories[client][class][slot].halloweenSpell.isActive = !g_inventories[client][class][slot].halloweenSpell.isActive;

	// Refresh the player's inventory.
	if (g_inventories[client][class][slot].isActiveOverride)
		TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff, slot);
}

/**
 * Sets a bit flag for a specific spell override.
 *
 * @param client Client index to set the spell override for.
 * @param slot Slot ID to set the spell override for.
 * @param spell The spell ID to set the override for.
 * @param unset Optional. If set, the bit flag will be unset instead of set.
 *
 * @return void
 */
stock void TF2ItemPlugin_SetHalloweenSpell(int client, int slot, int spell, bool unset = false)
{
	// Ensure the slot is within bounds.
	if (slot < 0 || slot >= MAX_WEAPONS)
		return;

	// Get the player's class.
	int class = TF2_GetPlayerClassInt(client);

	// Set/unset the spell override for the slot.
	if (unset) g_inventories[client][class][slot].halloweenSpell.spells &= ~(1 << spell);
	else g_inventories[client][class][slot].halloweenSpell.spells |= 1 << spell;

	// Refresh the player's inventory.
	if (g_inventories[client][class][slot].isActiveOverride && g_inventories[client][class][slot].halloweenSpell.isActive)
		TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff, slot);
}

/**
 * Sets the Unusual Effect ID for the override.
 *
 * If set to -1, the override will be ignored.
 *
 * @param client Client index to set the unusual effect override status for.
 * @param slot Slot ID to set the unusual effect override status for.
 * @param unusualEffect The Unusual Effect ID to set the override to.
 *
 * @return void
 */
stock void TF2ItemPlugin_SetUnusualEffect(int client, int slot, int unusualEffect)
{
	// Ensure the slot is within bounds.
	if (slot < 0 || slot >= MAX_WEAPONS)
		return;

	// Get the player's class.
	int class										   = TF2_GetPlayerClassInt(client);

	// Toggle the unusual effect override status for the slot.
	g_inventories[client][class][slot].unusualEffectId = unusualEffect;

	// Refresh the player's inventory.
	if (g_inventories[client][class][slot].isActiveOverride)
		TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff, slot);
}

/**
 * Sets the War Paint ID for the override.
 *
 * If set to -1, the override will be ignored.
 *
 * @param client Client index to set the war paint override status for.
 * @param slot Slot ID to set the war paint override status for.
 * @param warPaintId The War Paint ID to set the override to.
 *
 * @return void
 */
stock void TF2ItemPlugin_SetWarPaint(int client, int slot, int warPaintId)
{
	// Ensure the slot is within bounds.
	if (slot < 0 || slot >= MAX_WEAPONS)
		return;

	// Get the player's class.
	int class									  = TF2_GetPlayerClassInt(client);

	// Toggle the war paint override status for the slot.
	g_inventories[client][class][slot].warPaintId = warPaintId;

	if (warPaintId != -1 && g_inventories[client][class][slot].isAustralium)
		// If a war paint is set, reset the australium status.
		TF2ItemPlugin_ToggleAustralium(client, slot);

	// Refresh the player's inventory.
	if (g_inventories[client][class][slot].isActiveOverride)
		TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff, slot);
}

enum
{
	TF2Weapon_PaintWear_FactoryNew	  = 0,
	TF2Weapon_PaintWear_MinimalWear	  = 1,
	TF2Weapon_PaintWear_FieldTested	  = 2,
	TF2Weapon_PaintWear_WellWorn	  = 3,
	TF2Weapon_PaintWear_BattleScarred = 4,
}

/**
 * Obtains a wear value from the provided wear index.
 *
 * @param index The index to convert.
 *
 * @return The floating value to set as an attribute.
 */
stock float
	TF2ItemPlugin_GetPaintWearFromIndex(int index)
{
	switch (index)
	{
		case TF2Weapon_PaintWear_FactoryNew: return 0.2;
		case TF2Weapon_PaintWear_MinimalWear: return 0.4;
		case TF2Weapon_PaintWear_FieldTested: return 0.6;
		case TF2Weapon_PaintWear_WellWorn: return 0.8;
		case TF2Weapon_PaintWear_BattleScarred: return 1.0;
	}

	return -1.0;
}

/**
 * Sets a new War Paint wear value for the override.
 *
 * @param client Client index to set the war paint wear override status for.
 * @param slot Slot ID to set the war paint wear override status for.
 * @param wear The War Paint wear value to set the override to.
 *
 * @return void
 */
stock void
	TF2ItemPlugin_SetWarPaintWear(int client, int slot, float wear)
{
	// Ensure the slot is within bounds.
	if (slot < 0 || slot >= MAX_WEAPONS)
		return;

	// Get the player's class.
	int class										= TF2_GetPlayerClassInt(client);

	// Set the war paint wear override status for the slot.
	g_inventories[client][class][slot].warPaintWear = wear;

	// Refresh the player's inventory.
	if (g_inventories[client][class][slot].isActiveOverride)
		TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff, slot);
}

enum
{
	TF2Quality_Normal	  = 0,
	TF2Quality_Genuine	  = 1,
	TF2Quality_Vintage	  = 3,
	TF2Quality_Unusual	  = 5,
	TF2Quality_Unique	  = 6,
	TF2Quality_Community  = 7,
	TF2Quality_Valve	  = 8,
	TF2Quality_SelfMade	  = 9,
	TF2Quality_Strange	  = 11,
	TF2Quality_Haunted	  = 13,
	TF2Quality_Collectors = 14,
	TF2Quality_Decorated  = 15,
}

/**
 * Determines weapon quality based on a client's weapon preferences for a slot.
 *
 * @param client Client index to determine the quality for.
 * @param class The class to determine the quality for.
 * @param slot The slot to determine the quality for.
 *
 * @return The weapon quality for the specified slot.
 */
stock int
	TF2ItemPlugin_GetWeaponQuality(int client, int class, int slot)
{
	// If there is a `Community Sparkle` unusual effect set, return the Community quality.
	if (g_inventories[client][class][slot].unusualEffectId == TF2WeaponUnusual_CommunitySparkle)
		return TF2Quality_Community;

	// Check if there is a set unusual effect for this slot.
	if (g_inventories[client][class][slot].unusualEffectId != -1)
		return TF2Quality_Unusual;

	// If there is a war paint set, return the decorated quality.
	if (g_inventories[client][class][slot].warPaintId != -1)
		return TF2Quality_Decorated;

	// If nothing is set, return an invalid value.
	return g_inventories[client][class][slot].quality != -1 ? g_inventories[client][class][slot].quality : -1;
}

/**
 * Checks and applies a client's australium status to a weapon.
 *
 * @param client Client index to apply the australium status for.
 * @param class The class to apply the australium status for.
 * @param slot The slot to apply the australium status for.
 * @param hItem The item handle to apply the australium status to.
 * @param iItemDefinitionIndex The item definition index of the item.
 *
 * @return True if the item's properties were modified, false otherwise.
 */
stock bool
	TF2ItemPlugin_TF2Items_ApplyAustralium(int client, int class, int slot, Handle& hItem, int iItemDefinitionIndex)
{
	// Check if the item can be an australium weapon.
	int canAustralium = TF2ItemPlugin_CanItemAustralium(iItemDefinitionIndex);

	switch (canAustralium)
	{
		case TF2Weapon_NoAustralium, TF2Weapon_Stock: return false;
		case TF2Weapon_Australium:
		{
			// Set the item's australium status based on the client's preferences.
			bool isAustralium = g_inventories[client][class][slot].isAustralium;

			// If the override is not set, ignore the australium status.
			if (!isAustralium)
				return false;

			// If the client wants the weapon to be australium, set the item's properties.
			TF2Items_SetAttribute(hItem, 0, 2027, 1.0);
			TF2Items_SetAttribute(hItem, 1, 2022, 1.0);
			TF2Items_SetAttribute(hItem, 2, 542, 1.0);

			return true;
		}
	}

	return false;
}

/**
 * Checks and applies a clients' current festive status to a weapon.
 *
 * @param client Client index to apply the festive status for.
 * @param class The class to apply the festive status for.
 * @param slot The slot to apply the festive status for.
 * @param hItem The item handle to apply the festive status to.
 * @param iItemDefinitionIndex The item definition index of the item.
 *
 * @return True if the item's properties were modified, false otherwise.
 */
stock bool
	TF2ItemPlugin_TF2Items_ApplyFestive(int client, int class, int slot, Handle& hItem, int iItemDefinitionIndex)
{
	// Check if the item can be festivized.
	bool canFestivize = TF2ItemPlugin_CanItemFestivize(iItemDefinitionIndex);

	// If the item cannot be festivized, return false.
	if (!canFestivize)
		return false;

	// Set the item's festive status based on the client's preferences.
	bool isFestive = g_inventories[client][class][slot].isFestive;

	// If the client wants the weapon to be festive, set the item's properties.
	TF2Items_SetAttribute(hItem, 3, 2053, isFestive ? 1.0 : 0.0);

	return true;
}

/**
 * Applies a full killstreak configuration to a weapon.
 *
 * @param client Client index to apply the killstreak configuration for.
 * @param class The class to apply the killstreak configuration for.
 * @param slot The slot to apply the killstreak configuration for.
 * @param hItem The item handle to apply the killstreak configuration to.
 * @param iItemDefinitionIndex The item definition index of the item.
 *
 * @return True if the item's properties were modified, false otherwise.
 */
stock bool
	TF2ItemPlugin_TF2Items_ApplyKillstreak(int client, int class, int slot, Handle& hItem, int iItemDefinitionIndex)
{
	// Check if the client has enabled a killstreak override first.
	if (!g_inventories[client][class][slot].killstreak.isActive)
		return false;

	// Set the item's killstreak tier based on the client's preferences.
	int tier   = g_inventories[client][class][slot].killstreak.tier,
		sheen  = g_inventories[client][class][slot].killstreak.sheen,
		effect = g_inventories[client][class][slot].killstreak.killstreaker;

	// If the tier is set to None, return false.
	if (tier == TF2Killstreak_None)
		return false;

	// Set the item's killstreak tier.
	TF2Items_SetAttribute(hItem, 4, 2025, float(tier));

	// Only set the sheen if the tier is Specialized or higher.
	if (tier >= TF2Killstreak_Specialized)
		TF2Items_SetAttribute(hItem, 5, 2014, float(sheen));

	// Only set the killstreaker if the tier is Professional.
	if (tier == TF2Killstreak_Professional)
		TF2Items_SetAttribute(hItem, 6, 2013, float(effect));

	return true;
}

/**
 * Applies a full spell configuration to a weapon.
 *
 * @param client Client index to apply the spell configuration for.
 * @param class The class to apply the spell configuration for.
 * @param slot The slot to apply the spell configuration for.
 * @param hItem The item handle to apply the spell configuration to.
 * @param iItemDefinitionIndex The item definition index of the item.
 *
 * @return True if the item's properties were modified, false otherwise.
 */
stock bool
	TF2ItemPlugin_TF2Items_ApplySpell(int client, int class, int slot, Handle& hItem, int iItemDefinitionIndex)
{
	// Check if the client has enabled a spell override first.
	if (!g_inventories[client][class][slot].halloweenSpell.isActive)
		return false;

	// Set the item's spell configuration based on the client's preferences.
	int spells = g_inventories[client][class][slot].halloweenSpell.spells;

	// If no spells are set, return false.
	if (spells == 0)
		return false;

	// Analyze the spell configuration.
	// Exorcism can be applied to any weapon, no need to check if set.
	if (spells & WeaponSpell_Exorcism)
		TF2Items_SetAttribute(hItem, 9, 1009, 1.0);

	// Spectral Flames will only be set if the override is on Pyro.
	if (spells & WeaponSpell_SpectralFlames && view_as<TFClassType>(class) == TFClass_Pyro)
		TF2Items_SetAttribute(hItem, 10, 1008, 1.0);

	// Sentry-Quad, Squash Rockets and Gourd Grenades share the same attribute. Set if they are set and class is Engineer, Demo or Soldier.
	if ((spells & WeaponSpell_Explosions) && (view_as<TFClassType>(class) == TFClass_Engineer || view_as<TFClassType>(class) == TFClass_DemoMan || view_as<TFClassType>(class) == TFClass_Soldier))
		TF2Items_SetAttribute(hItem, 11, 1010, 1.0);

	return true;
}

/**
 * Applies an unusual effect to a weapon.
 *
 * @param client Client index to apply the unusual effect for.
 * @param class The class to apply the unusual effect for.
 * @param slot The slot to apply the unusual effect for.
 * @param hItem The item handle to apply the unusual effect to.
 * @param iItemDefinitionIndex The item definition index of the item.
 *
 * @return True if the item's properties were modified, false otherwise.
 */
stock bool
	TF2ItemPlugin_TF2Items_ApplyUnusualEffect(int client, int class, int slot, Handle& hItem, int iItemDefinitionIndex)
{
	// Check if the client has enabled an unusual effect override first.
	if (g_inventories[client][class][slot].unusualEffectId == -1)
		return false;

	// Set the item's unusual effect based on the client's preferences.
	int unusualEffect = g_inventories[client][class][slot].unusualEffectId;

	// If the unusual effect is set to None or disabled, return false.
	if (unusualEffect <= TF2WeaponUnusual_None)
		return false;

	// Set the item's unusual effect.
	TF2Items_SetAttribute(hItem, 12, 134, float(unusualEffect));

	return true;
}

/**
 * Applies a War Paint configuration to a weapon.
 *
 * @param client Client index to apply the War Paint configuration for.
 * @param class The class to apply the War Paint configuration for.
 * @param slot The slot to apply the War Paint configuration for.
 * @param hItem The item handle to apply the War Paint configuration to.
 * @param iItemDefinitionIndex The item definition index of the item.
 *
 * @return True if the item's properties were modified, false otherwise.
 */
stock bool TF2ItemPlugin_TF2Items_ApplyWarPaint(int client, int class, int slot, Handle& hItem, int iItemDefinitionIndex)
{
	// Check if the item can be war painted.
	bool canWarPaint = TF2ItemPlugin_CanItemWarPaint(iItemDefinitionIndex);

	// If the item cannot be war painted, return false.
	if (!canWarPaint)
		return false;

	// Set the item's War Paint based on the client's preferences.
	int warPaintId = g_inventories[client][class][slot].warPaintId;

	// If the War Paint is set to None or disabled, return false.
	if (warPaintId == -1)
		return false;

	// Set the 'item style override' attribute to display the War Paint correctly.
	TF2Items_SetAttribute(hItem, 1, 2022, 0.0);
	TF2Items_SetAttribute(hItem, 2, 542, 0.0);

	// Set the item's War Paint.
	TF2Items_SetAttribute(hItem, 7, 834, view_as<float>(warPaintId));

	// Obtain the wear value for the override.
	float wear = g_inventories[client][class][slot].warPaintWear;

	// If the wear value is set, apply it to the War Paint, if not just go with Factory New as a default.
	TF2Items_SetAttribute(hItem, 8, 725, wear != -1 ? wear : 0.0);

	return true;
}

/**
 * Applies a client's preferences for a weapon to an `hItem` `Handle`.
 *
 * Keep in mind this should be called with a valid/existing `Handle` to a weapon (from 'TF2Items_OnGiveNamedItem')
 * Attribute slot hirearchy is as follows:
 * - 0, 1, 2: Australium
 * - 3: Festivizer
 * - 4, 5, 6: Killstreaks
 * - 7, 8: War Paint
 * - 9, 10, 11: Spells
 * - 12: Unusual Effect
 *
 * @param client Client index to apply the preferences for.
 * @param class The class to apply the preferences for.
 * @param slot The slot to apply the preferences for.
 * @param className The weapon's original class name.
 * @param iItemDefinitionIndex The item definition index of the weapon about to be created.
 * @param hItem The item handle to apply the preferences to.
 * @param isCreatingStrangeVariant Optional. If set, will create a new item instance instead of modifying the existing one.
 * @param flags Optional. The flags to apply to the item.
 *
 * @return `Plugin_Changed` if the item's properties were modified, `Plugin_Handled` if a new creation was instanced and `Plugin_Continue` otherwise.
 */
stock Action
	TF2ItemPlugin_TF2Items_ApplyWeaponPreferences(int client, int class, int slot, char[] className, int iItemDefinitionIndex, Handle& hItem, bool isCreatingStrangeVariant = false, int flags = 0)
{
	// Create a new item handle.
	hItem = TF2Items_CreateItem(flags);

	// Obtain the client's inventory instance for this class and slot.
	TFInventory_Weapons_Slot inventorySlot;
	inventorySlot = g_inventories[client][class][slot];

	// Set the item's preliminary properties.
	TF2Items_SetItemIndex(hItem, iItemDefinitionIndex);

	// Set the item's classname.
	TF2Items_SetClassname(hItem, className);

	// Set the item's level based on the client's preferences.
	TF2Items_SetLevel(hItem, inventorySlot.level != -1 ? inventorySlot.level : 5);

	// Determine the quality of the item based on set overrides.
	int quality = TF2ItemPlugin_GetWeaponQuality(client, class, slot);

	// If quality is -1, set the original quality.
	TF2Items_SetQuality(hItem, quality != -1 ? quality : (g_inventories[client][class][slot].warPaintId != -1 ? TF2Quality_Decorated : TF2Quality_Unique));

	// Set the maximum amount of attributes possible on the weapon.
	TF2Items_SetNumAttributes(hItem, 13);

	// Apply the client's preferences to the weapon.
	TF2ItemPlugin_TF2Items_ApplyAustralium(client, class, slot, hItem, iItemDefinitionIndex);
	TF2ItemPlugin_TF2Items_ApplyFestive(client, class, slot, hItem, iItemDefinitionIndex);
	TF2ItemPlugin_TF2Items_ApplyKillstreak(client, class, slot, hItem, iItemDefinitionIndex);
	TF2ItemPlugin_TF2Items_ApplySpell(client, class, slot, hItem, iItemDefinitionIndex);
	TF2ItemPlugin_TF2Items_ApplyUnusualEffect(client, class, slot, hItem, iItemDefinitionIndex);
	TF2ItemPlugin_TF2Items_ApplyWarPaint(client, class, slot, hItem, iItemDefinitionIndex);

	// Set the generation flags.
	TF2Items_SetFlags(hItem, flags);

	// If the strange variant is being created, give the named item and properly equip it on the player.
	if (isCreatingStrangeVariant)
	{
		// Remove any weapons they could have equipped on the slot.
		int currentWeapon = GetPlayerWeaponSlot(client, slot);

		if (currentWeapon != -1)
			TF2_RemoveWeaponSlot(client, slot);

		// Give the item to the player.
		int weaponEntity = TF2Items_GiveNamedItem(client, hItem);

		// Make sure the weapon is visible to everyone.
		SetEntProp(weaponEntity, Prop_Send, "m_bValidatedAttachedEntity", 1);

		// Equip it on the player.
		EquipPlayerWeapon(client, weaponEntity);
	}

	// Return the appropriate action based on the item creation status.
	return isCreatingStrangeVariant ? Plugin_Handled : Plugin_Changed;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle& hItem)
{
	// Ignore cosmetic items.
	if (StrContains(classname, "tf_wearable", false) != -1) return Plugin_Continue;

	// Identify the weapon slot via the item definition index.
	int slot = -1, class = TF2_GetPlayerClassInt(client);

	for (int i = 0; i < MAX_WEAPONS; i++)
	{
		// Compare the current weapon's definition index with the one we're looking for.
		if (g_inventories[client][class][i].weaponDefIndex == iItemDefinitionIndex || g_inventories[client][class][i].stockWeaponDefIndex == iItemDefinitionIndex)
		{
			// Set if found and break the loop.
			slot = i;
			break;
		}
	}

	// If no slot was found, return the default action and continue.
	if (slot == -1)
		return Plugin_Continue;

	// If the slot is found, apply the specified overrides only if they are active for said slot.
	if (!g_inventories[client][class][slot].isActiveOverride)
		return Plugin_Continue;

	// Declare item flags.
	int flags = OVERRIDE_ALL | PRESERVE_ATTRIBUTES;

	// If this is the multi-class shotgun, set the classname to the corresponding class shotgun.
	if (TF2ItemPlugin_GetStrangeVariant(iItemDefinitionIndex) == 199)
	{
		switch (view_as<TFClassType>(class))
		{
			case TFClass_Soldier: strcopy(classname, 64, "tf_weapon_shotgun_soldier");
			case TFClass_Pyro: strcopy(classname, 64, "tf_weapon_shotgun_pyro");
			case TFClass_Heavy: strcopy(classname, 64, "tf_weapon_shotgun_hwg");
			case TFClass_Engineer: strcopy(classname, 64, "tf_weapon_shotgun_primary");
		}
	}

	// If this is an overriden weapon and their item index corresponds to a stock weapon, create a strange variant instead.
	if (g_inventories[client][class][slot].stockWeaponDefIndex != -1)
	{
		// Create a `DataPack` to transfer the necessary information to the next frame.
		DataPack data = new DataPack();
		data.WriteCell(client);
		data.WriteCell(class);
		data.WriteCell(slot);
		data.WriteString(classname);
		data.WriteCell(iItemDefinitionIndex);

		// Create a timer to give the item after the current frame.
		CreateTimer(0.0, TF2ItemPlugin_TF2Items_HandleStockWeaponConversion, data);

		// Disallow the current item creation.
		return Plugin_Handled;
	}

	// If the stock weapon definition index is set, reset it.
	if (g_inventories[client][class][slot].stockWeaponDefIndex != iItemDefinitionIndex)
		g_inventories[client][class][slot].stockWeaponDefIndex = -1;

	// Apply the client's preferences to the weapon.
	return TF2ItemPlugin_TF2Items_ApplyWeaponPreferences(client, class, slot, classname, iItemDefinitionIndex, hItem, false, flags);
}

public Action TF2ItemPlugin_TF2Items_HandleStockWeaponConversion(Handle timer, DataPack pack)
{
	// Reset the DataPack to its first index.
	pack.Reset();

	// Unpack the data.
	int client = pack.ReadCell(),
		class  = pack.ReadCell(),
		slot   = pack.ReadCell();

	char className[64];
	pack.ReadString(className, sizeof(className));

	int iItemDefinitionIndex		  = pack.ReadCell();

	// Convert the item definition index to its strange variant.
	int strangeVariantDefinitionIndex = TF2ItemPlugin_GetStrangeVariant(iItemDefinitionIndex);

	// If an invalid item definition index was returned, return the default action and continue.
	if (strangeVariantDefinitionIndex == -1)
	{
		LogError("FATAL ERROR: For client %d obtained item def index %d but could not find a valid strange variant (%d)", client, iItemDefinitionIndex, strangeVariantDefinitionIndex);

		delete pack;

		return Plugin_Stop;
	}

	// Pass `hItem` as an empty handle for the new item to be created.
	Handle hItem = INVALID_HANDLE;

	// Fire a new item modification with the same parameters, but with the creation flag on and the strange variants' definition index.
	TF2ItemPlugin_TF2Items_ApplyWeaponPreferences(client, class, slot, className, strangeVariantDefinitionIndex, hItem, true, OVERRIDE_ALL | PRESERVE_ATTRIBUTES);

	// Set the original stock weapon definition index to the new item.
	g_inventories[client][class][slot].stockWeaponDefIndex = iItemDefinitionIndex;

	// Delete the timer and the DataPack to free memory.
	delete pack;

	return Plugin_Stop;
}

public void TF2Items_OnGiveNamedItem_Post(int client, char[] classname, int iItemDefinitionIndex, int itemLevel, int itemQuality, int entityIndex)
{
	// Attach the `m_bValidatedAttachedEntity` property to every weapon/cosmetic.
	if (HasEntProp(entityIndex, Prop_Send, "m_bValidatedAttachedEntity"))
		SetEntProp(entityIndex, Prop_Send, "m_bValidatedAttachedEntity", 1);
}