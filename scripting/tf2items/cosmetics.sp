// This file contains all needed declarations for the tf2item_cosmetics plugin.
#include "tf2items/tf2item_base.inc"

// Just for the sake of not repeating everything and looking up every bit possible, define all possible equip regions' bitfields.
// Thanks a lot CreatorsTF: https://github.com/CreatorTF/creators.tf-gameservers/blob/152b9f499a29dd99c761d6907d1afe1998dbc11b/tf/addons/sourcemod/scripting/include/ce_core.inc#L12-L35

#define TFEquip_WholeHead 		(1<<0)
#define TFEquip_Hat 			(1<<1)
#define TFEquip_Face 			(1<<2)
#define TFEquip_Glasses 		(1<<3)
#define TFEquip_Lenses 			(1<<4)
#define TFEquip_Pants 			(1<<5)
#define TFEquip_Beard 			(1<<6)
#define TFEquip_Shirt 			(1<<7)
#define TFEquip_Medal 			(1<<8)
#define TFEquip_Arms 			(1<<9)
#define TFEquip_Back 			(1<<10)
#define TFEquip_Feet 			(1<<11)
#define TFEquip_Necklace 		(1<<12)
#define TFEquip_Grenades 		(1<<13)
#define TFEquip_ArmTatoos 		(1<<14)
#define TFEquip_Flair 			(1<<15)
#define TFEquip_HeadSkin 		(1<<16)
#define TFEquip_Ears 			(1<<17)
#define TFEquip_LeftShoulder 	(1<<18)
#define TFEquip_BeltMisc 		(1<<19)
#define TFEquip_Floating 		(1<<20)
#define TFEquip_Zombie 			(1<<21)
#define TFEquip_Sleeves 		(1<<22)
#define TFEquip_RightShoulder   (1<<23)

// Constants
#define MAX_PAINTS 29

// Valid Unusual Equip Region
#define TFEquip_Unusual         (TFEquip_WholeHead | TFEquip_Hat | TFEquip_Face | TFEquip_Glasses | TFEquip_Lenses | TFEquip_Beard | TFEquip_HeadSkin)


/* ditched for TF2Econ_GetParticleAttributeList()
static int unusualIds[150] =  {
	0, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 29, 30, 31, 
	32, 33, 34, 35, 36, 37, 38, 39, 40, 43, 44, 45, 46, 47, 56, 57, 
	58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 
	74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 
	90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 
	105, 106, 107, 108, 109, 110, 
	111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 
	124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 
	137, 138, 139, 141, 142, 143, 144, 145, 147, 148, 149, 
	150, 151, 152, 153, 154, 155, 
	156, 157, 158, 159, 160, 161, 162, 163, 
	164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175
};*/

// Cosmetic
//
//  Represents a single cosmetic instance for the user.
enum struct Cosmetic {
	int iItemIndex;
	
	int uEffect;
	
	int rPaint;
	int bPaint;
	
	int sPaint;
	
	int sFoot;
	
	int sVoices;
	
	int iQuality;
	
	// void Populate(int iItemDefinitionIndex = -1, int uEffect = -1, int redPaint = -1, int bluPaint = -1, int spellPaint = -1, int spellFootstep = -1, int spellVoices = 0, int iQuality = -1)
	void Populate(int iItemDefinitionIndex = -1, int uEffect = -1, int redPaint = -1, int bluPaint = -1, int spellPaint = -1, int spellFootstep = -1, int spellVoices = 0, int iQuality = -1) {
		this.iItemIndex = iItemDefinitionIndex;
		this.uEffect = uEffect;
		this.rPaint = redPaint;
		this.bPaint = bluPaint;
		this.sPaint = spellPaint;
		this.sFoot = spellFootstep;
		this.sVoices = spellVoices;
		this.iQuality = iQuality;
	}
}

// CosmeticsInfo
//
//  Defines a player's custom cosmetic overrides.
//  Holds data for each cosmetic's paint, spells, unusual effects or whatever the user has chosen that overrides their current ones.
//
//  If a 'no override' setting is selected, -1 is the value for each one.
//  A player can have a maximum override of 3 cosmetics items (not including taunts) and configure each individually.
//
//	iItemIndex - Cosmetic Item Definition Index array to know which hats have been selected (and override accordingly)
//  uEffects   - Holds the effect index selected by the user on that slot.
//  cPaint     - The paint value this user has selected on this cosmetic.
//		NOTE: Normal paint values are n > 7. Whereas values 0 <= n < 7 mean a Team Paint has been selected.
//  sPaint     - The spell paint value this user has selected on this cosmetic.
//		NOTE: Spell Paints and Normal Paints cannot co-exist on the hat. Player can only select ONE of each.
//
//	sFoot      - The footstep spell this user has selected on this cosmetic.
enum struct CosmeticsInfo {
	int iItemIndex[3];
	
	int uEffects[3];
	int cPaint[3];
	int sPaint[3];
	int sFoot[3];
	
	bool sVoices[3];
	
	/*
	 * void ResetFor(int slot)
	 *
	 * Resets the entire trie's selection for that specific slot; clears effect, paint, spell paints and footprints.
	 *
	 * int slot - The slot to clear.
	 * @noreturn
	 */
	void ResetFor(int slot) {
		this.iItemIndex[slot] = -1;
		this.uEffects[slot]   = -1;
		this.cPaint[slot]     = -1;
		this.sPaint[slot]     = -1;
		this.sFoot[slot]      = -1;
		this.sVoices[slot]    = false;
	}
	
	/*
	 * void ResetAll()
	 *
	 * Resets all slots from the trie. This is done every time a player leaves to free this specific client index.
	 * Simply loops through all slots and
	 *
	 * @noreturn
	 */
	void ResetAll() {
		for (int i = 0; i < 3; i++)
			this.ResetFor(i);
	}
	
	/*
	 * i love you
	 * :3
	 */
}

// Statics

// Spell Paints
static const char spNames[][] = {"Die Job", "Chromatic Corruption", "Putrescent Pigmentation", "Spectral Spectrum", "Sinister Staining"};
// Die Job - Chromatic Corruption - Putrescent Pigmentation - Spectral Spectrum
static const char spellPaints[][] = {"0", "1", "2", "3", "4" };

// Halloween Footprints
static const char fpNames[][] = {"Team Spirit", "Headless Horseshoes", "Rotten Orange", "Corpse Gray", "Violent Violet", "Bruised Purple", "Gangreen"};
// Team Spirit - Headless Horseshoes - Rotten Orange - Corpse Gray - Violent Violet - Bruised Purple - Gangreen
static const char footsteps[][] = {"1", "2", "13595446", "3100495", "5322826", "8208497" };

// Paint Values
int paintColors[22] = {
	7511618, 4345659, 5322826, 14204632, 8208497, 13595446, 10843461, 12955537, 6901050, 8154199, 15185211, 8289918, 15132390,
	1315860, 16738740, 3100495, 8421376, 3329330, 15787660, 15308410, 12377523, 2960676
};

// Paint Values (team colors | 1st is red, 2nd is blu)
int teamColors[7][2] = {
	{12073019, 5801378}, {4732984, 3686984}, {11049612, 8626083}, {3874595, 1581885}, {6637376, 2636109}, {8400928, 2452877}, {12807213, 12091445}
};


// Functions

// GetPaintName(int paintValue, char buffer, int size) - Copies the paint name corresponding to a value on a buffer.
void GetPaintName(int paintValue, char[] buffer, int size) {
	switch (paintValue) {
		case 7511618: strcopy(buffer, size, "Indubitably Green");
		case 4345659: strcopy(buffer, size, "Zepheniah's Greed");
		case 5322826: strcopy(buffer, size, "Noble Hatter's Violet");
		case 14204632: strcopy(buffer, size, "Color No. 219-190-216");
		case 8208497: strcopy(buffer, size, "Deep Commitment to Purple");
		case 13595446: strcopy(buffer, size, "Mann Co. Orange");
		case 10843461: strcopy(buffer, size, "Muskelmannbraun");
		case 12955537: strcopy(buffer, size, "Peculiarly Drab Tincture");
		case 6901050: strcopy(buffer, size, "Radigan Conagher Brown");
		case 8154199: strcopy(buffer, size, "Ye Olde Rustic Color");
		case 15185211: strcopy(buffer, size, "Australium Gold");
		case 8289918: strcopy(buffer, size, "Aged Moustache Grey");
		case 15132390: strcopy(buffer, size, "An Extraordinary Abundance of Tinge");
		case 1315860: strcopy(buffer, size, "A Distinctive Lack of Hue");
		case 16738740: strcopy(buffer, size, "Pink as Hell");
		case 3100495: strcopy(buffer, size, "Color Similar to Slate");
		case 8421376: strcopy(buffer, size, "Drably Olive");
		case 3329330: strcopy(buffer, size, "The Bitter Taste of Defeat and Lime");
		case 15787660: strcopy(buffer, size, "The Color of a Gentlemann's Business Pants");
		case 15308410: strcopy(buffer, size, "Dark Salmon Injustice");
		case 12377523: strcopy(buffer, size, "A Mann's Mint");
		case 2960676: strcopy(buffer, size, "After Eight");
		
		case 12073019, 5801378, 0: strcopy(buffer, size, "Team Spirit");
		case 4732984, 3686984, 1: strcopy(buffer, size, "Operator's Overalls");
		case 11049612, 8626083, 2: strcopy(buffer, size, "Waterlogged Lab Coat");
		case 3874595, 1581885, 3: strcopy(buffer, size, "Balaclavas Are Forever");
		case 6637376, 2636109, 4: strcopy(buffer, size, "An Air of Debonair");
		case 8400928, 2452877, 5: strcopy(buffer, size, "The Value of Teamwork");
		case 12807213, 12091445, 6: strcopy(buffer, size, "Cream Spirit");
	}
}

// GenerateHatsMenu() - Generates the first menu where the player's hats are listed
void GenerateHatsMenu(int client)
{
	Menu menu = new Menu(MainHdlr);
	
	menu.SetTitle("Select a Cosmetic Item");

	int hat = -1, found = 0;
	while ((hat = FindEntityByClassname(hat, "tf_wearable")) != -1) {
		if ((hat != INVALID_ENT_REFERENCE) && (GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client)) {
			int id = GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex");
			
			if (IsHatUnusual(id) || IsHatPaintable(id)) {
				char idStr[12], hatName[42];
				IntToString(id, idStr, sizeof(idStr));
				TF2Econ_GetItemName(id, hatName, sizeof(hatName));
				//TF2IDB_GetItemName(id, hatName, sizeof(hatName)); fuck tf2idb, tf_econ_data for chads
				
				menu.AddItem(idStr, hatName);
				found++;
			}
		}
	}

	if (!found) {
		char msg[128];
		Format(msg, sizeof(msg), "No compatible hats have been found.");
		
		menu.AddItem("-", msg, ITEMDRAW_DISABLED);
	}
	
	char usage[128];
	Format(usage, sizeof(usage), "Usage: Select your desired cosmetic and begin modifying it!");
	
	menu.AddItem("-", usage, ITEMDRAW_DISABLED);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// PaintsMenu() - Generates the cosmetic paint menu.
// This menu shall only be opened on paintable hats.
void PaintsMenu(int client, const char[] name, int iItemDefinitionIndex, int slot) {
	Menu paintMenu = new Menu(paintHdlr);
	
	// embed data oh yes how do i love to do this
	char slotStr[12], idStr[14];
	Format(slotStr, sizeof(slotStr), "%d", slot);
	Format(idStr, sizeof(idStr), "%d", iItemDefinitionIndex);
	
	paintMenu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	paintMenu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	
	paintMenu.SetTitle("Select Paint for %s", name);
	
	AddPaints(paintMenu);
	
	paintMenu.ExitBackButton = true;
	paintMenu.Display(client, MENU_TIME_FOREVER);
}

// SpellsMenu() - Generates the cosmetic spell paints menu.
void SpellsMenu(int client, const char[] name, int iItemDefinitionIndex, int slot) {
	Menu spellMenu = new Menu(spellHdlr);
	
	spellMenu.SetTitle("Select Spell Paint for %s", name);
	
	char slotStr[2], idStr[14];
	Format(slotStr, sizeof(slotStr), "%d", slot);
	Format(idStr, sizeof(idStr), "%d", iItemDefinitionIndex);
	
	spellMenu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	spellMenu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	
	spellMenu.AddItem("-1", "No Override");
	
	for (int i = 0; i < sizeof(spellPaints); i++)
		spellMenu.AddItem(spellPaints[i], spNames[i]);
	
	spellMenu.ExitBackButton = true;
	spellMenu.Display(client, MENU_TIME_FOREVER);
}

// FootprintsMenu() - Generates the cosmetic spell footprints menu.
void FootprintsMenu(int client, const char[] name, int iItemDefinitionIndex, int slot) {
	Menu footMenu = new Menu(footHdlr);
	
	footMenu.SetTitle("Select Footprints for %s", name);
	
	char slotStr[2], idStr[14];
	Format(slotStr, sizeof(slotStr), "%d", slot);
	Format(idStr, sizeof(idStr), "%d", iItemDefinitionIndex);
	
	footMenu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	footMenu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	
	footMenu.AddItem("-1", "No Override");
	
	for (int i = 0; i < sizeof(footsteps); i++) 
		footMenu.AddItem(footsteps[i], fpNames[i]);
	
	footMenu.ExitBackButton = true;
	footMenu.Display(client, MENU_TIME_FOREVER);
}

// EffectsMenu() - Generates the effects menu. Now, generates every time a client needs it (because of translations)
void EffectsMenu(int client, const char[] name, int iItemDefinitionIndex, int slot)
{
	Menu effMenu = new Menu(EffectHdlr);
	
	effMenu.SetTitle("Select Unusual Effect for %s", name);
	
	// embed data oh yes how do i love to do this
	char slotStr[12], idStr[14];
	IntToString(slot, slotStr, sizeof(slotStr));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	
	effMenu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	effMenu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	
	// add unusual effects respectively
	AddUnusuals(effMenu, client);
	
	effMenu.ExitBackButton = true;
	effMenu.Display(client, MENU_TIME_FOREVER);
}

// AddUnusuals(Menu menu, int client) - Adds all Unusual Effects to a menu.
void AddUnusuals(Menu menu, int client)
{
	menu.AddItem("-1", "No Override");
	
	// Unusual Particle Effects ID List
	ArrayList unusuals = TF2Econ_GetParticleAttributeList(ParticleSet_CosmeticUnusualEffects);
	
	for (int i; i < unusuals.Length; i++) {
		int id = unusuals.Get(i);
		
		// remnants from the translation version, left this in because no need to write a function to get a name.
		char name[64], idStr[32];
		Format(name, sizeof(name), "Cosmetic_Eff%d", id);
		Format(idStr, sizeof(idStr), "%d", id);
		
		if (TranslationPhraseExists(name))
			Format(name, sizeof(name), "%T", name, client);
		else {
			char system[64];
			TF2Econ_GetParticleAttributeSystemName(id, system, sizeof(system));
			
			//if (CV_Cosmetics_UParticles.BoolValue)
			LogError("[TF2Cosmetics] Failure when adding particle %d (%s), might be new or undocumented; missing translation '%s'. This particle will be skipped!", id, system, name);
			continue;
		}
		
		menu.AddItem(idStr, name);
	}
}

// AddPaints(Menu menu) - Adds all of the possible paint colors to a menu.
void AddPaints(Menu menu) {
	menu.AddItem("-1", "No Override");
	
	for (int i; i < MAX_PAINTS; i++) {
		char paintName[64], val[64];
		IntToString((i < sizeof(paintColors)) ? paintColors[i] : (i - sizeof(paintColors)), val, sizeof(val));
		GetPaintName(StringToInt(val), paintName, sizeof(paintName));

		Format(paintName, sizeof(paintName), paintName);
		
		menu.AddItem(val, paintName);
	}
}

// GetOriginalAttributes() - Retrieves the original personalization attributes held on to the CTFWearable entity.
// @ int entity    - The entity index for the CTFWearable to extract values from.
// @ StringMap att - StringMap handle to store the results into.
//		StringMap Structure
//			"uEffect" => Unusual Particle Effect (Attribute 134)
//			"rPaint"  => RED Paint Value (Attribute 142)
//			"bPaint"  => BLU Paint Value (Attribute 261)
//			"sPaint"  => Spelled Paint Job (Attribute 1004)
//			"sFoot"   => Halloween Footstep Type (Attribute 1005)
//
//		NOTE: Remember to close your StringMap handle!
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// @return bool - True if they were found and extracted, false if no attribute was present or a (possible?) error.
bool GetOriginalAttributes(int entity, StringMap att) {
	// paint attributes are just 3 (the 3rd being halloween spells), while other modifications make up for a total of 5
	//
	//  134  = attach particle effect
	//  142  = set item tint RGB
	//	261  = set item tint RGB 2
	//  1004 = set item tint RGB override
	//  
	// then, for other modifications (halloween stuff) there's:
	//
	//	1005 = halloween footstep type
	//  1006 = halloween voice modulation
	//
	float values[16];
	int   ids[16];
	int   amount = TF2Attrib_GetSOCAttribs(entity, ids, values);
	
	att.SetValue("uEffect", -1.0); att.SetValue("rPaint", -1.0); att.SetValue("bPaint", -1.0); att.SetValue("sPaint", -1.0); att.SetValue("sFoot", -1.0); att.SetValue("sVoices", 0.0);
	
	for (int i; i < amount; i++) {
		switch (ids[i]) {
			case 134:  att.SetValue("uEffect",  values[i]);
			case 142:  att.SetValue("rPaint",   values[i]);
			case 261:  att.SetValue("bPaint",   values[i]);
			case 1004: att.SetValue("sPaint",   values[i]);
			case 1005: att.SetValue("sFoot",    values[i]);
			case 1006: att.SetValue("sVoices",  values[i]);
		}
	}
	return amount > 0;
}

// indexof(int element, int[] array) - Finds the index of said element in an array, or -1 if not found. Unused
/*int indexof(int element, int[] array, int size) {
	for (int i; i < size; i++) {
		if (array[i] == element)
			return i;
	}
	return -1;
}*/

// IsHatUnusual() - Retrieves wether the current worn hat CAN have an Unusual effect.
// @ int iItemDefinitionIndex	- The Item Index for the hat being tested.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// @return bool					- True if the hat can be Unusual, false if not.
bool IsHatUnusual(int iItemDefinitionIndex)
{
	if (!TF2Econ_IsValidItemDefinition(iItemDefinitionIndex)) return false;
	// this, was the biggest mindfuck of my life.
	// i'm studying systems' engineering, and i had this subject in one of my studies. everything about bit calculations and manipulation, parity and shit
	// THING IS I NEVER PUT IT ONTO PRACTICE AND STOOD STILL FOR 5 HOURS RELEARNING THE ENTIRE THING
	// pay attention in class people
	//
	// also, if you're seeing this, thank you so much "nosoop" (creator of tf_econ_data) for giving me a small helping hand with bitwise operations <3
	//
	
	// region is a bitfield containing the equip regions present on an item
	int       		  region  = TF2Econ_GetItemEquipRegionGroupBits(iItemDefinitionIndex); //TF2IDB_GetItemEquipRegions(iItemDefinitionIndex);
	// regions contains all region names as keys, whose values are the bits for that equip region
	// example:
	//   region  = 2 = 10
	//   regions = ["head": 10, "pants": "10000", "something": 10000000 ... ]
	StringMap 		  regions = TF2Econ_GetEquipRegionGroups();
	// a snapshot of all key names (this is to get the corresponding representative bit and do the logical comparsion)
	StringMapSnapshot names   = regions.Snapshot();
	
	// loop through all equip region names on the snapshot
	for (int i; i < names.Length; i++) {
		// get the equip region name
		char buff[64];
		names.GetKey(i, buff, sizeof(buff));
		
		// get the bit that corresponds to that region name
		int bit;
		regions.GetValue(buff, bit);
		// if 1 shifted "bit" times, has 1 on the same position as TFEquip_Unusual and region, then it is a valid one
		// explanation:
		//
		//   suppose TFEquip_Unusual = 1001000101000, and region = 101000. all the bits inside "regions" are powers of 2 in decimal form (1, 10, 100, 1000, 10000, and so on)
		//  which is also the same as saying "they're all shifted 1 position apart from each other".
		//   we want to check if the equip regions of the item being tested has at least one region valid for unusuals (which is the bitfield TFEquip_Unusual). so, we do an
		//  AND operation against the regions and the shifted bit.
		//			1 << bit = 1000 (if bit = 3)
		//
		//			so now we do (1<<bit) & TFEquip_Unusual
		//
		//			  0000000001000
		//          & 1001000101000
		//            0000000001000 <- The bit 1000 IS inside TFEquip_Unusual's bit-field, that means it is a valid unusual equip region.
		//							   but, is it a region from the item being tested?
		//
		//			so now we do ((1<<bit) & TFEquip_Unusual) & region
		//
		//			  001000
		//			& 101000
		//			  001000 <- The bit 1000 is ALSO inside "region"'s bit-field. That means the item has an unusual-valid equip region and CAN be unusualified.
		//
		if ((1 << bit) & TFEquip_Unusual & region)
			return true;
	}
	return false;
}

// IsHatPaintable() - Checks if you can paint this cosmetic or not.
// @ int iItemDefinitionIndex	- The Item Index for the hat being tested.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// @return bool					- True if the hat can be painted, false if not.
bool IsHatPaintable(int iItemDefinitionIndex) {
	char cap[12];
	TF2Econ_GetItemDefinitionString(iItemDefinitionIndex, "capabilities/paintable", cap, sizeof(cap));
	
	return view_as<bool>(StringToInt(cap));
}

// IsWearableWeapon() - Checks if the wearable is in a weapon slot (so we don't count it as a hat)
bool IsWearableWeapon(int id)
{
	switch (id) {
		case 133, 444, 405, 608, 231, 642:
			return true;
	}
	return false;
}