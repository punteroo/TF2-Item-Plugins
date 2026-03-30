#define TFEquip_WholeHead	  (1 << 0)
#define TFEquip_Hat			  (1 << 1)
#define TFEquip_Face		  (1 << 2)
#define TFEquip_Glasses		  (1 << 3)
#define TFEquip_Lenses		  (1 << 4)
#define TFEquip_Pants		  (1 << 5)
#define TFEquip_Beard		  (1 << 6)
#define TFEquip_Shirt		  (1 << 7)
#define TFEquip_Medal		  (1 << 8)
#define TFEquip_Arms		  (1 << 9)
#define TFEquip_Back		  (1 << 10)
#define TFEquip_Feet		  (1 << 11)
#define TFEquip_Necklace	  (1 << 12)
#define TFEquip_Grenades	  (1 << 13)
#define TFEquip_ArmTatoos	  (1 << 14)
#define TFEquip_Flair		  (1 << 15)
#define TFEquip_HeadSkin	  (1 << 16)
#define TFEquip_Ears		  (1 << 17)
#define TFEquip_LeftShoulder  (1 << 18)
#define TFEquip_BeltMisc	  (1 << 19)
#define TFEquip_Floating	  (1 << 20)
#define TFEquip_Zombie		  (1 << 21)
#define TFEquip_Sleeves		  (1 << 22)
#define TFEquip_RightShoulder (1 << 23)

#define TFEquip_Unusual		  (TFEquip_WholeHead | TFEquip_Hat | TFEquip_Face | TFEquip_Glasses | TFEquip_Lenses | TFEquip_Beard | TFEquip_HeadSkin)

#define MAX_UNUSUAL_EFFECTS	  2048

/** Global variable that keeps track in-memory of user inventories for cosmetic modifications. */
TFInventory_Cosmetics_Slot g_inventories[MAXPLAYERS + 1][MAX_CLASSES + 1][MAX_COSMETICS + 1];

// Network prop for weapon clip.
int						   clipOff;

// Network prop for weapon ammo.
int						   ammoOff;

// Handle that stores the "Regenerate" SDK call to refresh player inventories.
Handle					   hRegen = INVALID_HANDLE;

// Array that stores wether a player is within a spawn room.
bool					   g_bInSpawnRoom[MAXPLAYERS + 1];

// Array that stores if a client is currently on database cooldown.
bool					   g_bIsOnDatabaseCooldown[MAXPLAYERS + 1];

/** Global variable where Unusual effects information is stored in. */
StringMap				   g_unusualEffects[MAX_UNUSUAL_EFFECTS];

/** ConVar that controls if cosmetic changes should only be allowed on spawn regions. */
stock ConVar			   g_cvar_cosmetics_onlySpawn,
	/** ConVar that sets the URL where the raw Unusual effects data is stored at. */
	g_cvar_cosmetics_unusualEffectsURL,
	/** ConVar that sets the timeout for the Unusual effects search. */
	g_cvar_cosmetics_searchTimeout,
	/** ConVar that controls the amount (in seconds) a user has to wait before making another load/save/reset of their preferences. Only works if the database connection is successful. */
	g_cvar_cosmetics_databaseCooldown;

/**
 * Wrapper for the regeneration function to delete wearables correctly before firing the SDK call.
 *
 * @param client The client index to regenerate the loadout for.
 *
 * @return void
 */
stock void TF2ItemPlugin_Cosmetics_RegenerateLoadout(int client)
{
	// Remove all cosmetics from the client.
	int cosmetic = -1;
	while ((cosmetic = FindEntityByClassname(cosmetic, "tf_wearable")) != -1)
	{
		if (GetEntPropEnt(cosmetic, Prop_Send, "m_hOwnerEntity") == client)
		{
			// Obtain the cosmetic definition index.
			int itemDefIndex = GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex");

			// Skip wearable weapons.
			if (TF2ItemPlugin_IsCosmeticWearableWeapon(itemDefIndex))
				continue;

			// Remove the cosmetic.
			AcceptEntityInput(cosmetic, "Kill");
		}
	}

	// Fire a next frame call to regenerate the loadout.
	CreateTimer(0.025, TF2ItemPlugin_Cosmetics_RegenerateLoadout_NextFrame, GetClientUserId(client));
}

public Action TF2ItemPlugin_Cosmetics_RegenerateLoadout_NextFrame(Handle timer, int userId)
{
	// Get the client index.
	int client = GetClientOfUserId(userId);

	// Call the regeneration function.
	TF2ItemPlugin_RegenerateLoadout(client, hRegen, clipOff, ammoOff);

	// Return the default action.
	return Plugin_Stop;
}

/**
 * Checks if a cosmetic is a wearable weapon.
 *
 * @param itemDefIndex The item definition index to check.
 *
 * @return True if the cosmetic is a wearable weapon, false otherwise.
 */
stock bool TF2ItemPlugin_IsCosmeticWearableWeapon(int itemDefIndex)
{
	switch (itemDefIndex)
	{
		case 133, 444, 405, 608, 231, 642:
			return true;
	}

	return false;
}

/**
 * Function that checks if an item can be equipped with an Unusual effect.
 *
 * @param itemDefIndex The item definition index to check.
 *
 * @return True if the item can be equipped with an Unusual effect, false otherwise.
 */
stock bool TF2ItemPlugin_CanCosmeticBeUnusual(int itemDefIndex)
{
	// Obtain the region equip bits for this specific cosmetic.
	int				  regionBits			   = TF2Econ_GetItemEquipRegionGroupBits(itemDefIndex);

	// Obtain the equip region bits available in TF2.
	StringMap		  g_equip_regions		   = TF2Econ_GetEquipRegionGroups();
	StringMapSnapshot g_equip_regions_snapshot = g_equip_regions.Snapshot();

	// Loop through all equip regions and check if the item can be equipped with an Unusual effect.
	for (int i = 0; i < g_equip_regions_snapshot.Length; i++)
	{
		// Obtain the key name.
		char key[32];
		g_equip_regions_snapshot.GetKey(i, key, sizeof(key));

		// Access the stored value for this region.
		int regionValue;
		g_equip_regions.GetValue(key, regionValue);

		// Check if the item can be equipped with an Unusual effect.
		if ((1 << regionValue) & regionBits & TFEquip_Unusual)
			return true;
	}

	// The item cannot be equipped with an Unusual effect.
	return false;
}

/**
 * Function that checks if an item index can be a paintable cosmetic.
 *
 * @param itemDefIndex The item definition index to check.
 *
 * @return True if the item can be painted, false otherwise.
 */
stock bool TF2ItemPlugin_CanCosmeticBePainted(int itemDefIndex)
{
	char paintable[12];
	TF2Econ_GetItemDefinitionString(itemDefIndex, "capabilities/paintable", paintable, sizeof(paintable));

	return view_as<bool>(StringToInt(paintable));
}

/**
 * Searches through the list of available Unusual effects and returns the name of the effect.
 *
 * @param unusualEffect The unusual effect ID to search for.
 * @param buffer The buffer to store the effect name.
 * @param length The maximum length of the buffer.
 *
 * @return voif
 */
stock void TF2ItemPlugin_GetUnusualEffectName(int unusualEffect, char[] buffer, int length)
{
	if (unusualEffect < 0 || unusualEffect >= MAX_UNUSUAL_EFFECTS)
	{
		strcopy(buffer, length, "Unknown");
		return;
	}

	// Count the amount of set effects.
	int count = 0;
	for (int i = 0; i < MAX_UNUSUAL_EFFECTS; i++)
	{
		if (g_unusualEffects[i] != null)
			count++;
	}

	if (count == 0)
	{
		strcopy(buffer, length, "Unknown");
		return;
	}

	// Find the name of this Unusual effect ID.
	char name[128];
	for (int i = 0; i < count; i++)
	{
		// Obtain the Unusual ID at this index.
		int id = -1;
		g_unusualEffects[i].GetValue("id", id);

		if (id == -1) continue;

		// Check if this is the Unusual effect we are looking for.
		if (id == unusualEffect)
		{
			// Obtain the name and copy it to the buffer.
			g_unusualEffects[i].GetString("name", name, sizeof(name));
			strcopy(buffer, length, name);
			return;
		}
	}

	// The Unusual effect was not found.
	strcopy(buffer, length, "Unknown");
}

enum
{
	TF2CosmeticPaint_IndubitablyGreen = 0,
	TF2CosmeticPaint_ZepheniahsGreed,
	TF2CosmeticPaint_NobleHattersViolet,
	TF2CosmeticPaint_ColorNo219190216,
	TF2CosmeticPaint_DeepCommitmentToPurple,
	TF2CosmeticPaint_MannCoOrange,
	TF2CosmeticPaint_Muskelmannbraun,
	TF2CosmeticPaint_PeculiarlyDrabTincture,
	TF2CosmeticPaint_RadiganConagherBrown,
	TF2CosmeticPaint_YeOldeRusticColor,
	TF2CosmeticPaint_AustraliumGold,
	TF2CosmeticPaint_AgedMoustacheGrey,
	TF2CosmeticPaint_AnExtraordinaryAbundanceOfTinge,
	TF2CosmeticPaint_ADistinctiveLackOfHue,
	TF2CosmeticPaint_PinkAsHell,
	TF2CosmeticPaint_ColorSimilarToSlate,
	TF2CosmeticPaint_DrablyOlive,
	TF2CosmeticPaint_TheBitterTasteOfDefeatAndLime,
	TF2CosmeticPaint_TheColorOfAGentlemannsBusinessPants,
	TF2CosmeticPaint_DarkSalmonInjustice,
	TF2CosmeticPaint_AMannsMint,
	TF2CosmeticPaint_AfterEight,
	TF2CosmeticPaint_TeamSpirit,
	TF2CosmeticPaint_OperatorsOveralls,
	TF2CosmeticPaint_WaterloggedLabCoat,
	TF2CosmeticPaint_BalaclavasAreForever,
	TF2CosmeticPaint_AnAirOfDebonair,
	TF2CosmeticPaint_TheValueOfTeamwork,
	TF2CosmeticPaint_CreamSpirit
}

enum
{
	TF2CosmeticPaint_Spell_DieJob = 0,
	TF2CosmeticPaint_Spell_ChromaticCorruption,
	TF2CosmeticPaint_Spell_PutrescentPigmentation,
	TF2CosmeticPaint_Spell_SpectralSpectrum,
	TF2CosmeticPaint_Spell_SinisterStaining
}

enum
{
	TF2Cosmetic_Footsteps_TeamSpirit = 0,
	TF2Cosmetic_Footsteps_HeadlessHorseshoes,
	TF2Cosmetic_Footsteps_RottenOrange,
	TF2Cosmetic_Footsteps_CorpseGray,
	TF2Cosmetic_Footsteps_ViolentViolet,
	TF2Cosmetic_Footsteps_BruisedPurple,
	TF2Cosmetic_Footsteps_Gangreen
}

/**
 * Maps a paint ID to its respective color name.
 *
 * @param paintId The paint ID to map.
 * @param buffer The buffer to store the color name.
 * @param length The maximum length of the buffer.
 *
 * @return void
 */
stock void
	TF2ItemPlugin_GetPaintName(int paintId, char[] buffer, int length)
{
	switch (paintId)
	{
		case TF2CosmeticPaint_IndubitablyGreen: strcopy(buffer, length, "Indubitably Green");
		case TF2CosmeticPaint_ZepheniahsGreed: strcopy(buffer, length, "Zepheniah's Greed");
		case TF2CosmeticPaint_NobleHattersViolet: strcopy(buffer, length, "Noble Hatter's Violet");
		case TF2CosmeticPaint_ColorNo219190216: strcopy(buffer, length, "Color No. 216-190-216");
		case TF2CosmeticPaint_DeepCommitmentToPurple: strcopy(buffer, length, "Deep Commitment to Purple");
		case TF2CosmeticPaint_MannCoOrange: strcopy(buffer, length, "Mann Co. Orange");
		case TF2CosmeticPaint_Muskelmannbraun: strcopy(buffer, length, "Muskelmannbraun");
		case TF2CosmeticPaint_PeculiarlyDrabTincture: strcopy(buffer, length, "Peculiarly Drab Tincture");
		case TF2CosmeticPaint_RadiganConagherBrown: strcopy(buffer, length, "Radigan Conagher Brown");
		case TF2CosmeticPaint_YeOldeRusticColor: strcopy(buffer, length, "Ye Olde Rustic Color");
		case TF2CosmeticPaint_AustraliumGold: strcopy(buffer, length, "Australium Gold");
		case TF2CosmeticPaint_AgedMoustacheGrey: strcopy(buffer, length, "Aged Moustache Grey");
		case TF2CosmeticPaint_AnExtraordinaryAbundanceOfTinge: strcopy(buffer, length, "An Extraordinary Abundance of Tinge");
		case TF2CosmeticPaint_ADistinctiveLackOfHue: strcopy(buffer, length, "A Distinctive Lack of Hue");
		case TF2CosmeticPaint_PinkAsHell: strcopy(buffer, length, "Pink as Hell");
		case TF2CosmeticPaint_ColorSimilarToSlate: strcopy(buffer, length, "Color Similar to Slate");
		case TF2CosmeticPaint_DrablyOlive: strcopy(buffer, length, "Drably Olive");
		case TF2CosmeticPaint_TheBitterTasteOfDefeatAndLime: strcopy(buffer, length, "The Bitter Taste of Defeat and Lime");
		case TF2CosmeticPaint_TheColorOfAGentlemannsBusinessPants: strcopy(buffer, length, "The Color of a Gentlemann's Business Pants");
		case TF2CosmeticPaint_DarkSalmonInjustice: strcopy(buffer, length, "Dark Salmon Injustice");
		case TF2CosmeticPaint_AMannsMint: strcopy(buffer, length, "A Mann's Mint");
		case TF2CosmeticPaint_AfterEight: strcopy(buffer, length, "After Eight");
		case TF2CosmeticPaint_TeamSpirit: strcopy(buffer, length, "Team Spirit");
		case TF2CosmeticPaint_OperatorsOveralls: strcopy(buffer, length, "Operator's Overalls");
		case TF2CosmeticPaint_WaterloggedLabCoat: strcopy(buffer, length, "Waterlogged Lab Coat");
		case TF2CosmeticPaint_BalaclavasAreForever: strcopy(buffer, length, "Balaclavas Are Forever");
		case TF2CosmeticPaint_AnAirOfDebonair: strcopy(buffer, length, "An Air of Debonair");
		case TF2CosmeticPaint_TheValueOfTeamwork: strcopy(buffer, length, "The Value of Teamwork");
		case TF2CosmeticPaint_CreamSpirit: strcopy(buffer, length, "Cream Spirit");
		default: strcopy(buffer, length, "Unknown");
	}
}

/**
 * Maps a spell paint ID to its respective spell name.
 *
 * @param spellPaintId The spell paint ID to map.
 * @param buffer The buffer to store the spell name.
 * @param length The maximum length of the buffer.
 *
 * @return void
 */
stock void TF2ItemPlugin_GetSpellPaintName(int spellPaintId, char[] buffer, int length)
{
	switch (spellPaintId)
	{
		case TF2CosmeticPaint_Spell_DieJob: strcopy(buffer, length, "Die Job");
		case TF2CosmeticPaint_Spell_ChromaticCorruption: strcopy(buffer, length, "Chromatic Corruption");
		case TF2CosmeticPaint_Spell_PutrescentPigmentation: strcopy(buffer, length, "Putrescent Pigmentation");
		case TF2CosmeticPaint_Spell_SpectralSpectrum: strcopy(buffer, length, "Spectral Spectrum");
		case TF2CosmeticPaint_Spell_SinisterStaining: strcopy(buffer, length, "Sinister Staining");
		default: strcopy(buffer, length, "Unknown");
	}
}

/**
 * Maps a Halloween footsteps ID to its respective footsteps name.
 *
 * @param footstepsId The footsteps ID to map.
 * @param buffer The buffer to store the footsteps name.
 * @param length The maximum length of the buffer.
 *
 * @return void
 */
stock void TF2ItemPlugin_GetFootstepsName(int footstepsId, char[] buffer, int length)
{
	switch (footstepsId)
	{
		case TF2Cosmetic_Footsteps_TeamSpirit: strcopy(buffer, length, "Team Spirit");
		case TF2Cosmetic_Footsteps_HeadlessHorseshoes: strcopy(buffer, length, "Headless Horseshoes");
		case TF2Cosmetic_Footsteps_RottenOrange: strcopy(buffer, length, "Rotten Orange");
		case TF2Cosmetic_Footsteps_CorpseGray: strcopy(buffer, length, "Corpse Gray");
		case TF2Cosmetic_Footsteps_ViolentViolet: strcopy(buffer, length, "Violent Violet");
		case TF2Cosmetic_Footsteps_BruisedPurple: strcopy(buffer, length, "Bruised Purple");
		case TF2Cosmetic_Footsteps_Gangreen: strcopy(buffer, length, "Gangreen");
		default: strcopy(buffer, length, "Unknown");
	}
}

/**
 * Maps a paint ID to its color values.
 *
 * First index is the RED teams' color value, and the second index is the BLU teams' color value.
 *
 * @param paintId The paint ID to map.
 * @param result An integer array of size 2 on which to store the color values.
 *
 * @return void
 */
stock void TF2ItemPlugin_GetPaintColor(int paintId, int result[2])
{
	switch (paintId)
	{
		case TF2CosmeticPaint_IndubitablyGreen: result = { 7511618, 7511618 };
		case TF2CosmeticPaint_ZepheniahsGreed: result = { 4345659, 4345659 };
		case TF2CosmeticPaint_NobleHattersViolet: result = { 5322826, 5322826 };
		case TF2CosmeticPaint_ColorNo219190216: result = { 14204632, 14204632 };
		case TF2CosmeticPaint_DeepCommitmentToPurple: result = { 8208497, 8208497 };
		case TF2CosmeticPaint_MannCoOrange: result = { 13595446, 13595446 };
		case TF2CosmeticPaint_Muskelmannbraun: result = { 10843461, 10843461 };
		case TF2CosmeticPaint_PeculiarlyDrabTincture: result = { 12955537, 12955537 };
		case TF2CosmeticPaint_RadiganConagherBrown: result = { 6901050, 6901050 };
		case TF2CosmeticPaint_YeOldeRusticColor: result = { 8154199, 8154199 };
		case TF2CosmeticPaint_AustraliumGold: result = { 15185211, 15185211 };
		case TF2CosmeticPaint_AgedMoustacheGrey: result = { 8289918, 8289918 };
		case TF2CosmeticPaint_AnExtraordinaryAbundanceOfTinge: result = { 15132390, 15132390 };
		case TF2CosmeticPaint_ADistinctiveLackOfHue: result = { 1315860, 1315860 };
		case TF2CosmeticPaint_PinkAsHell: result = { 16738740, 16738740 };
		case TF2CosmeticPaint_ColorSimilarToSlate: result = { 3100495, 3100495 };
		case TF2CosmeticPaint_DrablyOlive: result = { 8421376, 8421376 };
		case TF2CosmeticPaint_TheBitterTasteOfDefeatAndLime: result = { 3329330, 3329330 };
		case TF2CosmeticPaint_TheColorOfAGentlemannsBusinessPants: result = { 15787660, 15787660 };
		case TF2CosmeticPaint_DarkSalmonInjustice: result = { 15308410, 15308410 };
		case TF2CosmeticPaint_AMannsMint: result = { 12377523, 12377523 };
		case TF2CosmeticPaint_AfterEight: result = { 2960676, 2960676 };
		case TF2CosmeticPaint_TeamSpirit: result = { 12073019, 5801378 };
		case TF2CosmeticPaint_OperatorsOveralls: result = { 4732984, 3686984 };
		case TF2CosmeticPaint_WaterloggedLabCoat: result = { 11049612, 8626083 };
		case TF2CosmeticPaint_BalaclavasAreForever: result = { 3874595, 1581885 };
		case TF2CosmeticPaint_AnAirOfDebonair: result = { 6637376, 2636109 };
		case TF2CosmeticPaint_TheValueOfTeamwork: result = { 8400928, 2452877 };
		case TF2CosmeticPaint_CreamSpirit: result = { 12807213, 12091445 };
		default: result = { -1, -1 };
	}
}

/**
 * Maps a halloween footstep ID to its attribute value.
 *
 * @param footstepsId The footsteps ID to map.
 *
 * @return The footsteps attribute value.
 */
stock int TF2ItemPlugin_GetFootstepsValue(int footstepsId)
{
	switch (footstepsId)
	{
		case TF2Cosmetic_Footsteps_TeamSpirit: return 1;
		case TF2Cosmetic_Footsteps_HeadlessHorseshoes: return 2;
		case TF2Cosmetic_Footsteps_RottenOrange: return 13595446;
		case TF2Cosmetic_Footsteps_CorpseGray: return 3100495;
		case TF2Cosmetic_Footsteps_ViolentViolet: return 5322826;
		case TF2Cosmetic_Footsteps_BruisedPurple: return 8208497;
		case TF2Cosmetic_Footsteps_Gangreen: return 8421376;
		default: return -1;
	}
}

/**
 * Toggles the override status of a cosmetic slot for a client.
 *
 * @param client The client index to toggle the override for.
 * @param slot The slot index to toggle the override for.
 * @param itemDefIndex The item definition index to toggle the override for.
 *
 * @return void
 */
stock void TF2ItemPlugin_ToggleCosmeticSlotOverride(int client, int slot, int itemDefIndex)
{
	// Obtain the player class of the client.
	int class											= TF2_GetPlayerClassInt(client);

	// Toggle the override status.
	g_inventories[client][class][slot].isActiveOverride = !g_inventories[client][class][slot].isActiveOverride;

	// Set the client, class and item definition index.
	g_inventories[client][class][slot].client			= client;
	g_inventories[client][class][slot].class			= class;
	g_inventories[client][class][slot].slotId			= slot;
	g_inventories[client][class][slot].itemDefIndex		= itemDefIndex;

	// If the override is enabled trigger a player regenerate call.
	if (g_inventories[client][class][slot].isActiveOverride)
		TF2ItemPlugin_Cosmetics_RegenerateLoadout(client);
}

/**
 * Sets the Unusual effect ID for a cosmetic slot for a client.
 *
 * @param client The client index to set the Unusual effect for.
 * @param slot The slot index to set the Unusual effect for.
 * @param unusualEffect The Unusual effect ID to set.
 *
 * @return void
 */
stock void TF2ItemPlugin_SetCosmeticSlotUnusualEffect(int client, int slot, int unusualEffect)
{
	// Obtain the player class of the client.
	int class										 = TF2_GetPlayerClassInt(client);

	// Set the Unusual effect ID.
	g_inventories[client][class][slot].unusualEffect = unusualEffect;

	// If the Unusual effect is set, trigger a player regenerate call.
	if (unusualEffect != -1)
		TF2ItemPlugin_Cosmetics_RegenerateLoadout(client);
}

/**
 * Toggles a users' paint override setting.
 *
 * @param client The client index to toggle the paint override for.
 * @param slot The slot index to toggle the paint override for.
 *
 * @return void
 */
stock void TF2ItemPlugin_ToggleCosmeticSlotPaintOverride(int client, int slot)
{
	// Obtain the player class of the client.
	int class												  = TF2_GetPlayerClassInt(client);

	// Toggle the paint override setting.
	g_inventories[client][class][slot].paint.isActiveOverride = !g_inventories[client][class][slot].paint.isActiveOverride;

	// If the paint override is enabled, trigger a player regenerate call.
	if (g_inventories[client][class][slot].paint.isActiveOverride)
		TF2ItemPlugin_Cosmetics_RegenerateLoadout(client);
}

/**
 * Searches and sets the paint color values for a cosmetic slot for a client.
 *
 * @param client The client index to set the paint colors for.
 * @param slot The slot index to set the paint colors for.
 * @param paintId The paint ID to set the colors for.
 *
 * @return void
 */
stock void TF2ItemPlugin_SetCosmeticSlotPaintColor(int client, int slot, int paintId)
{
	// Obtain the player class of the client.
	int class = TF2_GetPlayerClassInt(client);

	// Obtain the paint color values from the ID.
	int paintColors[2];
	TF2ItemPlugin_GetPaintColor(paintId, paintColors);

	// Set the paint ID.
	g_inventories[client][class][slot].paint.paintIndex	 = paintId;
	g_inventories[client][class][slot].paint.paintColor1 = paintColors[0];
	g_inventories[client][class][slot].paint.paintColor2 = paintColors[1];

	// If the paint ID is set, trigger a player regenerate call.
	if (paintId != -1)
		TF2ItemPlugin_Cosmetics_RegenerateLoadout(client);
}

/**
 * Sets a cosmetic slot's Halloween spell paint index for a client.
 *
 * @param client The client index to set the Halloween spell paint index for.
 * @param slot The slot index to set the Halloween spell paint index for.
 * @param spellPaintId The Halloween spell paint index to set.
 *
 * @return void
 */
stock void TF2ItemPlugin_SetCosmeticSlotHalloweenSpellPaint(int client, int slot, int spellPaintId)
{
	// Obtain the player class of the client.
	int class													   = TF2_GetPlayerClassInt(client);

	// Set the Halloween spell paint index.
	g_inventories[client][class][slot].paint.halloweenSpellPaintId = spellPaintId;

	// If the Halloween spell paint index is set, trigger a player regenerate call.
	if (spellPaintId != -1)
		TF2ItemPlugin_Cosmetics_RegenerateLoadout(client);
}

/**
 * Toggles the override status for halloween options.
 *
 * @param client The client index to toggle the Halloween override for.
 * @param slot The slot index to toggle the Halloween override for.
 *
 * @return void
 */
stock void TF2ItemPlugin_ToggleCosmeticSlotHalloweenOverride(int client, int slot)
{
	// Obtain the player class of the client.
	int class													  = TF2_GetPlayerClassInt(client);

	// Toggle the Halloween override setting.
	g_inventories[client][class][slot].halloween.isActiveOverride = !g_inventories[client][class][slot].halloween.isActiveOverride;

	// If the Halloween override is enabled, trigger a player regenerate call.
	if (g_inventories[client][class][slot].halloween.isActiveOverride)
		TF2ItemPlugin_Cosmetics_RegenerateLoadout(client);
}

/**
 * Sets a cosmetic slot's Halloween footsteps for a client.
 *
 * @param client The client index to set the Halloween footsteps for.
 * @param slot The slot index to set the Halloween footsteps for.
 * @param footstepsId The Halloween footsteps to set.
 *
 * @return void
 */
stock void TF2ItemPlugin_SetCosmeticSlotHalloweenFootsteps(int client, int slot, int footstepsId)
{
	// Obtain the player class of the client.
	int class															 = TF2_GetPlayerClassInt(client);

	// Obtain the footprints value from the index.
	int footprintValue													 = TF2ItemPlugin_GetFootstepsValue(footstepsId);

	// Set the Halloween footsteps.
	g_inventories[client][class][slot].halloween.halloweenFootstepsIndex = footstepsId;
	g_inventories[client][class][slot].halloween.halloweenFootsteps		 = footprintValue;

	// If the Halloween footsteps are set, trigger a player regenerate call.
	if (footstepsId != -1)
		TF2ItemPlugin_Cosmetics_RegenerateLoadout(client);
}

/**
 * Toggles the Halloween voice modulation for a cosmetic slot for a client.
 *
 * @param client The client index to toggle the Halloween voice modulation for.
 * @param slot The slot index to toggle the Halloween voice modulation for.
 *
 * @return void
 */
stock void TF2ItemPlugin_ToggleCosmeticSlotHalloweenVoiceModulation(int client, int slot)
{
	// Obtain the player class of the client.
	int class															  = TF2_GetPlayerClassInt(client);

	// Toggle the Halloween voice modulation setting.
	g_inventories[client][class][slot].halloween.halloweenVoiceModulation = !g_inventories[client][class][slot].halloween.halloweenVoiceModulation;

	// If the Halloween voice modulation is enabled, trigger a player regenerate call.
	if (g_inventories[client][class][slot].halloween.isActiveOverride)
		TF2ItemPlugin_Cosmetics_RegenerateLoadout(client);
}

/**
 * Applies a client's Unusual effect settings on an item.
 *
 * @param client The client index to apply the settings for.
 * @param slot The slot index to apply the settings for.
 * @param hItem The item handle to apply the settings on.
 *
 * @return void
 */
stock void TF2ItemPlugin_TF2Items_ApplyCosmeticSlotUnusualEffect(int client, int slot, Handle& hItem)
{
	// Obtain the player class of the client.
	int class		  = TF2_GetPlayerClassInt(client);

	// Obtain the Unusual effect ID.
	int unusualEffect = g_inventories[client][class][slot].unusualEffect;

	// If the Unusual effect is not set, return.
	if (unusualEffect == -1)
		return;

	// Apply the Unusual effect on the item.
	TF2Items_SetAttribute(hItem, 0, 134, float(unusualEffect));

	// Make sure to set the "particle effect use head origin" attribute for the effect to show up correctly.
	TF2Items_SetAttribute(hItem, 1, 520, 1.0);
}

/**
 * Applies a client's preferences for normal paint colors on an item.
 *
 * @param client The client index to apply the settings for.q
 * @param slot The slot index to apply the settings for.
 * @param hItem The item handle to apply the settings on.
 *
 * @return void
 */
stock void TF2ItemPlugin_TF2Items_ApplyCosmeticSlotPaint(int client, int slot, Handle& hItem)
{
	// Obtain the player class of the client.
	int class = TF2_GetPlayerClassInt(client);

	// Is the override active?
	if (!g_inventories[client][class][slot].paint.isActiveOverride) return;

	// Obtain the paint colors.
	int paintColor1 = g_inventories[client][class][slot].paint.paintColor1, paintColor2 = g_inventories[client][class][slot].paint.paintColor2;

	// If they are unset, return.
	if (paintColor1 == -1 || paintColor2 == -1)
		return;

	// Apply the paint colors on the item.
	TF2Items_SetAttribute(hItem, 2, 142, float(paintColor1));
	TF2Items_SetAttribute(hItem, 3, 261, float(paintColor2));
}

/**
 * Applies a client's preferences for Halloween spell paint on an item.
 *
 * @param client The client index to apply the settings for.
 * @param slot The slot index to apply the settings for.
 * @param hItem The item handle to apply the settings on.
 *
 * @return void
 */
stock void TF2ItemPlugin_TF2Items_ApplyCosmeticSlotHalloweenSpellPaint(int client, int slot, Handle& hItem)
{
	// Obtain the player class of the client.
	int class = TF2_GetPlayerClassInt(client);

	// Is the paint override active?
	if (!g_inventories[client][class][slot].paint.isActiveOverride) return;

	// Obtain the Halloween spell paint index.
	int spellPaintId = g_inventories[client][class][slot].paint.halloweenSpellPaintId;

	// If the Halloween spell paint index is not set, return.
	if (spellPaintId == -1)
		return;

	// Apply the Halloween spell paint on the item.
	TF2Items_SetAttribute(hItem, 4, 1004, float(spellPaintId));
}

/**
 * Applies a client's preferences for Halloween options on an item.
 *
 * @param client The client index to apply the settings for.
 * @param slot The slot index to apply the settings for.
 * @param hItem The item handle to apply the settings on.
 *
 * @return void
 */
stock void TF2ItemPlugin_TF2Items_ApplyCosmeticSlotHalloweenOptions(int client, int slot, Handle& hItem)
{
	// Obtain the player class of the client.
	int class = TF2_GetPlayerClassInt(client);

	// Are the halloween options active?
	if (!g_inventories[client][class][slot].halloween.isActiveOverride) return;

	// Obtain the Halloween footsteps index.
	int footstepsId = g_inventories[client][class][slot].halloween.halloweenFootstepsIndex;

	// If the Halloween footsteps index is not set, return.
	if (footstepsId == -1)
		return;

	// Obtain the Halloween footsteps value.
	int footstepsValue = g_inventories[client][class][slot].halloween.halloweenFootsteps;

	// Apply the Halloween footsteps on the item.
	TF2Items_SetAttribute(hItem, 5, 1005, float(footstepsValue));

	// Apply the Halloween voice modulation on the item.
	if (g_inventories[client][class][slot].halloween.halloweenVoiceModulation)
		TF2Items_SetAttribute(hItem, 6, 1006, 1.0);
}

/**
 * Applies cosmetic preferences on an item about to be given to a player.
 *
 * Attribute hierarchy is as follows:
 * 0, 1: Unusual effect
 * 2, 3: Paint colors
 * 4: Halloween spell paint index
 * 5: Halloween footsteps
 * 6: Halloween voice modulation
 *
 * @param client The client index to apply the preferences for.
 * @param slot The slot index to apply the preferences for.
 * @param classname The classname of the item being given.
 * @param itemDefinitionIndex The item definition index of the item being given.
 * @param hItem The handle of the item being given.
 * @param level Optional. The level of the item being given.
 *
 * @return The action to take.
 */
stock Action TF2ItemPlugin_TF2Items_ApplyCosmeticPreferences(int client, int slot, char[] classname, int itemDefinitionIndex, Handle& hItem, level = -1)
{
	// Create a new item handle.
	hItem = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);

	// Set preliminary settings.
	TF2Items_SetClassname(hItem, classname);
	TF2Items_SetItemIndex(hItem, itemDefinitionIndex);
	TF2Items_SetLevel(hItem, level == -1 ? GetRandomInt(1, 80) : level);

	// Set the maximum amount of attributes.
	TF2Items_SetNumAttributes(hItem, 7);

	// Apply user settings.
	TF2ItemPlugin_TF2Items_ApplyCosmeticSlotUnusualEffect(client, slot, hItem);
	TF2ItemPlugin_TF2Items_ApplyCosmeticSlotPaint(client, slot, hItem);
	TF2ItemPlugin_TF2Items_ApplyCosmeticSlotHalloweenSpellPaint(client, slot, hItem);
	TF2ItemPlugin_TF2Items_ApplyCosmeticSlotHalloweenOptions(client, slot, hItem);

	// Set the item flags.
	TF2Items_SetFlags(hItem, OVERRIDE_ALL | FORCE_GENERATION);

	// Return the change action.
	return Plugin_Changed;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle& hItem)
{
	// Ignore non-wearables.
	if (StrContains(classname, "tf_wearable", false) == -1)
		return Plugin_Continue;

	// Ignore wearable weapons.
	if (TF2ItemPlugin_IsCosmeticWearableWeapon(iItemDefinitionIndex))
		return Plugin_Continue;

	// Identify the cosmetic slot via the item definition index.
	int slot = -1, class = TF2_GetPlayerClassInt(client);

	for (int i = 0; i < MAX_COSMETICS; i++)
	{
		// Compare the current cosmetic's definition index with the one we're looking for.
		if (g_inventories[client][class][i].itemDefIndex == iItemDefinitionIndex)
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

	// Apply the user's preferences on the item.
	return TF2ItemPlugin_TF2Items_ApplyCosmeticPreferences(client, slot, classname, iItemDefinitionIndex, hItem);
}

public void TF2Items_OnGiveNamedItem_Post(int client, char[] classname, int iItemDefinitionIndex, int itemLevel, int itemQuality, int entityIndex)
{
	// Attach the `m_bValidatedAttachedEntity` property to every weapon/cosmetic.
	if (HasEntProp(entityIndex, Prop_Send, "m_bValidatedAttachedEntity"))
		SetEntProp(entityIndex, Prop_Send, "m_bValidatedAttachedEntity", 1);
}