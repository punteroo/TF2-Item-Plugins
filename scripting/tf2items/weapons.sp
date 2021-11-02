// This file contains all needed declarations for the tf2item_weapons plugin.
#include "tf2items/tf2item_base.inc"

// Bit Values for Spells
#define WeaponSpell_Exorcism           (1 << 0)
#define WeaponSpell_SquashRockets      (1 << 1)
#define WeaponSpell_SpectralFlames     (1 << 2)
#define WeaponSpell_SentryQuadPumpkins (1 << 3)
#define WeaponSpell_GourdGrenades      (1 << 4)

#define WeaponSpell_Explosions         (WeaponSpell_SquashRockets | WeaponSpell_SentryQuadPumpkins | WeaponSpell_GourdGrenades)

// Custom Defines
#define MAX_WEAPONS            3
#define INVALID_WEAPON_ENTITY -1

// Global ArrayLists
ArrayList wPaintNames, wPaintProtoDef;

// Weapon
//
//  Represents a single weapon instance for the user.
//  This is utilized to define each original weapon's properties if overrides are not set.
enum struct Weapon {
	int iItemIndex;
	
	int uEffects;
	
	int   wPaint;
	float wWear;
	
	bool Aussie;
	bool Festive;
	
	int kType;
	int kSheen;
	int kStreaker;
	
	// Spells [Bitfield]
	int sSpells;
	
	// Original Quality
	int iQuality;
	
	void Popularize(int iItemDefinitionIndex = -1, int uEffect = -1, int wPaint = -1, float wWear = -1.0, bool Aussie = false, bool Festive = false, int kType = -1,
					int kSheen = -1, int kStreaker = -1, int sSpells = -1, int iQuality = -1) {
		this.iItemIndex = iItemDefinitionIndex;
		
		this.uEffects = uEffect;
		
		this.wPaint = wPaint;
		this.wWear  = wWear;
		
		this.Aussie  = Aussie;
		this.Festive = Festive;
		
		this.kType     = kType;
		this.kSheen    = kSheen;
		this.kStreaker = kStreaker;
		
		this.sSpells = sSpells;
		
		this.iQuality = iQuality;
	}
}

// WeaponsInfo
//
//  Defines a player's custom weapon overrides.
//  Holds data for each weapon australium and/or festivized state, war paint, unusual effects or whatever the user has chosen that overrides their current ones.
//
//  If a 'no override' setting is selected, -1 is the value for each one.
//  A player can have a maximum override of 3 weapons and configure each individually.
//
//	iItemIndex - Weapon Item Definition Index array to know which weapons have been selected (and override accordingly)
//
//  uEffects   - Holds the effect index selected by the user on that slot.
//
//	wPaint     - War Paint index selected by the user on that slot.
//		NOTE: War Paint IDs are obtained through TF2EconData, as for names they are all defined in weapons.phrases.txt
//		 I made a .py script to extract their names, so if an update ever appears I'll update them ASAP (bc idk of a dynamic method to obtain the names)
//  wWear      - Wear type selected by the user on that slot (Paint Wear).
//		0.2 - Factory New
//		0.4 - Minimal Wear
//		0.6 - Field-Tested
//		0.8 - Well-Worn
//		1.0 - Battle Scarred
//
//	Aussie     - Is weapon Australium overrided?
//  Festive    - Is weapon Festive overrided?
//
//  kType      - Killstreak Type selected by the user on that slot.
//  kSheen     - Specialized Killstreak Sheen selected by the user on that slot [Type must be 1]
//  kStreaker  - Professional Killstreak Killstreaker selected by the user on that slot [Type must be 2]
//
//  FOR SPELLS:
//	 This will be controlled with boolean values, and must be checked on each spawn for class incompatibility.
//   Excorcism isn't an issue as it can be applied to any weapon.
//		Exorcism  - Can be applied to any weapon.
//		Squash    - Can ONLY BE APPLIED on Rocket Launcher weapons [Soldier]
//		Spectral  - Can ONLY BE APPLIED on Flamethrower weapons [Pyro]
//		Sentry    - Can ONLY BE APPLIED on Wrench weapons [Engineer]
//		Gourd     - Can ONLY BE APPLIED on Greande Launcher & Stickybomb Launcher weapons [Demoman]
//
//	 So this will be controlled by a bitfield consisting of 5 bits for each spell value.
//	 This decision wasn't made to complicate everything, but because of performance on checking compatibility since bit operations are lightning fast
//	taking up just one CPU cycle to process. Also like said before, we'll be checking this all the time.
//
enum struct WeaponsInfo {
	int iItemIndex[3];
	
	int uEffects[3];
	
	int   wPaint[3];
	float wWear[3];
	
	bool Aussie[3];
	bool Festive[3];
	
	int kType[3];
	int kSheen[3];
	int kStreaker[3];
	
	// Spells [Bitfield]
	int sSpells[3];
	
	// Special Weapon Selection
	// Players can set a preference for Special Weapons (functionality previously seen in vip-australium)
	int Special;
	
	/*
	 * void ResetAll()
	 *	Called to reset everything on the weapon. All is set to -1.
	 */
	void ResetAll(bool all = false) {
		for (int i = 0; i < 3; i++)
			this.ResetFor(i, all);
	}
	
	void ResetFor(int slot, bool resetAll = false) {
		this.iItemIndex[slot] = -1;
		
		this.uEffects[slot]   = -1;
		
		this.wPaint[slot]     = -1;
		this.wWear[slot]      = -1.0;
		
		this.Aussie[slot]     = false;
		this.Festive[slot]    = false;
		
		this.kType[slot]      = -1;
		this.kSheen[slot]     = -1;
		this.kStreaker[slot]  = -1;
		
		// Spells are set to 0 bc it's a bitfield
		this.sSpells[slot]    = 0;
		
		// Do not reset the override if not needed.		
		if (resetAll)
			this.Special          = -1;
	}
}

//
// Menu Creators
////////////////

// wWarPaintProtodef - Allows the user to select a specific War Paint Protodef ID to set on their weapon.
void wWarPaintProtodef(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(wPaintProtoHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("Select a War Paint for %s", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	// Utilize chat to search for a specific War Paint kit
	menu.AddItem("search", "Search for a War Paint...");
	
	menu.AddItem("-1", "No Override");
	
	// Clear search ArrayList values
	wPaintNames.Clear();
	wPaintProtoDef.Clear();
	
	// Get all valid War Paints at the moment.
	ArrayList paints = TF2Econ_GetPaintKitDefinitionList();
	for (int i = 0; i < paints.Length; i++) {
		int protodef = paints.Get(i);
		
		char pStr[12];
		IntToString(protodef, pStr, sizeof(pStr));
		
		if (TranslationPhraseExists(pStr)) {
			char pName[64];
			Format(pName, sizeof(pName), "%T", pStr, client);
			
			menu.AddItem(pStr, pName);
			
			// Save into ArrayList
			wPaintNames.PushString(pName);
			wPaintProtoDef.Push(protodef);
		} else if (CV_LogMissingTranslations.BoolValue)
			LogError("[TF2Weapons] Error while adding Paint Kit %s. Translation is missing. Paint Kit will not be added to the menu.", pStr);
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// wWarPaintWear - Allows the user to select a specific wear value for their weapon. This will only be issued as an attribute if a War Paint is present.
void wWarPaintWear(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(wWarPaintWearHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("Select a Wear value for %s", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	// Valid War Paint wear values
	static const char values[][] = { "-1.0", "0.2", "0.4", "0.6", "0.8", "1.0" };
	for (int i = 0; i < sizeof(values); i++) {
		char wPaintWearName[24];
		GetWarPaintWearName(StringToFloat(values[i]), wPaintWearName, sizeof(wPaintWearName));
		
		menu.AddItem(values[i], wPaintWearName);
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// kKillstreaksSheen - Allows players to select a Sheen override for their weapon.
void kKillstreaksSheen(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(kKillstreakSheenHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("Select a Sheen for %s", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	static const char sheens[][] = { "-1", "0", "1", "2", "3", "4", "5", "6", "7" };
	for (int i = 0; i < sizeof(sheens); i++) {
		char kSheenName[64];
		GetSheenName(StringToInt(sheens[i]), kSheenName, sizeof(kSheenName));
		
		menu.AddItem(sheens[i], kSheenName);
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// kKillstreaksKillstreaker - Allows player to select a Killstreaker override for their weapon.
void kKillstreaksKillstreaker(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(kKillstreakKillstreakerHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("Select a Killstreaker for %s", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	static const char killstreakers[][] = { "-1", "0", "2002", "2003", "2004", "2005", "2006", "2007", "2008" };
	for (int i = 0; i < sizeof(killstreakers); i++) {
		char kKillstreakerName[64];
		GetKillstreakerName(StringToInt(killstreakers[i]), kKillstreakerName, sizeof(kKillstreakerName));
		
		menu.AddItem(killstreakers[i], kKillstreakerName);
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// wUnusual - Allows a player to set their preferred Unusual effect on their weapon.
void wUnusual(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(wUnusualHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("Select an Unusual Effect for %s", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	static const char unusuals[][] = { "-1", "701", "702", "703", "704" };
	for (int i = 0; i < sizeof(unusuals); i++) {
		char wUnusualName[64];
		GetUnusualWeaponName(StringToInt(unusuals[i]), wUnusualName, sizeof(wUnusualName));
		
		menu.AddItem(unusuals[i], wUnusualName);
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

//
// Custom Functions
///////////////////

/*
 * void GetKillstreakTypeName
 * 
 *  Copies into a buffer the Killstreak Type name currently set for that number.
 */
void GetKillstreakTypeName(int type, char[] buffer, int size) {
	switch (type) {
		case -1: strcopy(buffer, size, "No Override");
		case 0:  strcopy(buffer, size, "Disabled");
		case 1:  strcopy(buffer, size, "Basic");
		case 2:  strcopy(buffer, size, "Specialized");
		case 3:  strcopy(buffer, size, "Professional");
		default: strcopy(buffer, size, "Unknown");
	}
}

/*
 * void GetSheenName
 * 
 *  Copies into a buffer the Killstreak Sheen name currently set for that number.
 */
void GetSheenName(int sheen, char[] buffer, int size) {
	switch (sheen) {
		case -1: strcopy(buffer, size, "No Override");
		case 0:  strcopy(buffer, size, "Disabled");
		case 1:  strcopy(buffer, size, "Team Shine");
		case 2:  strcopy(buffer, size, "Deadly Daffodil");
		case 3:  strcopy(buffer, size, "Manndarin");
		case 4:  strcopy(buffer, size, "Mean Green");
		case 5:  strcopy(buffer, size, "Agonizing Emerald");
		case 6:  strcopy(buffer, size, "Villanious Violet");
		case 7:  strcopy(buffer, size, "Hot Rod");
		default: strcopy(buffer, size, "Unknown");
	}
}

/*
 * void GetKillstreakerName
 * 
 *  Copies into a buffer the Killstreak Killstreaker name currently set for that number.
 */
void GetKillstreakerName(int killstreaker, char[] buffer, int size) {
	switch (killstreaker) {
		case -1:   strcopy(buffer, size, "No Override");
		case 0:    strcopy(buffer, size, "Disabled");
		case 2002: strcopy(buffer, size, "Fire Horns");
		case 2003: strcopy(buffer, size, "Cerebral Discharge");
		case 2004: strcopy(buffer, size, "Tornado");
		case 2005: strcopy(buffer, size, "Flames");
		case 2006: strcopy(buffer, size, "Singularity");
		case 2007: strcopy(buffer, size, "Incinerator");
		case 2008: strcopy(buffer, size, "Hypno-Beam");
		default:   strcopy(buffer, size, "Unknown");
	}
}

/*
 * void GetWarPaintWearName
 * 
 *  Copies into a buffer the War Paint wear currently set for that number.
 */
void GetWarPaintWearName(float wear, char[] buffer, int size) {
	switch (wear) {
		case -1.0:	   strcopy(buffer, size, "No Override");
		case 0.0, 0.2: strcopy(buffer, size, "Factory New");
		case 0.4: 	   strcopy(buffer, size, "Minimal Wear");
		case 0.6:	   strcopy(buffer, size, "Field-Tested");
		case 0.8:	   strcopy(buffer, size, "Well-Worn");
		case 1.0:	   strcopy(buffer, size, "Battle Scarred");
		default:	   strcopy(buffer, size, "Unknown");
	}
}

/*
 * void GetUnusualWeaponName
 * 
 *  Copies into a buffer the Unusual effect name for that specific ID.
 */
void GetUnusualWeaponName(int unusual, char[] buffer, int size) {
	switch (unusual) {
		case -1:  strcopy(buffer, size, "No Override");
		case 701: strcopy(buffer, size, "Hot");
		case 702: strcopy(buffer, size, "Isotope");
		case 703: strcopy(buffer, size, "Cool");
		case 704: strcopy(buffer, size, "Energy Orb");
		default:  strcopy(buffer, size, "Unknown");
	}
}

/*
 * bool CanBeFestivized
 * 
 *  Returns the iItemDefinitionIndex tags/can_be_festivized boolean value.
 *	Can return false if iItemDefinitionIndex does not exist.
 */
bool CanBeFestivized(int iItemDefinitionIndex) {
	if (!TF2Econ_IsValidItemDefinition(iItemDefinitionIndex)) return false;
	
	char fest[2];
	TF2Econ_GetItemDefinitionString(iItemDefinitionIndex, "tags/can_be_festivized", fest, sizeof(fest), "0");
	
	return view_as<bool>(StringToInt(fest));
}

/*
 * bool CanBePainted
 * 
 *  Returns if the iItemDefinitionIndex paintkit_base is present on its definition "prefab" key.
 *  Can return false if iItemDefinitionIndex does not exist.
 */
bool CanBePainted(int iItemDefinitionIndex) {
	if (!TF2Econ_IsValidItemDefinition(iItemDefinitionIndex)) return false;
	
	char prefab[64];
	TF2Econ_GetItemDefinitionString(iItemDefinitionIndex, "prefab", prefab, sizeof(prefab), "");
	
	return (StrContains(prefab, "paintkit_base", false) != -1);
}

/*
 * bool CanBeAustralium
 *
 *	Returns wether this iItemDefinitionIndex can be a valid Australium item.
 *  Makes use of the Stock->Strange Variant conversion if a Stock ID is detected.
 */
bool CanBeAustralium(int& iItemDefinitionIndex) {
	switch (iItemDefinitionIndex) {
		case 13, 18, 21, 19, 20, 15, 7, 29, 14, 16, 4: return StockToStrange(iItemDefinitionIndex);
		case /* Unlockables */      						 45, 228, 38, 132, 424, 141, 36, 61,
			 /* Strange Variants (No need for Conversion) */ 200, 205, 208, 206, 207, 202, 197, 211, 201, 203, 194: return true;
	}
	return false;
}

/*
 * bool StockToStrange
 *
 *	Grabs a referenced iItemDefinitionIndex instance and converts it to its Strange variant. Utilized to "australize" the weapon, as Australiums don't work on Stock IDs.
 *  Returns true if conversion was successful, false if an invalid Stock iItemDefinitionIndex was provided.
 */
bool StockToStrange(int& iItemDefinitionIndex) {
	int oldId = iItemDefinitionIndex;
	
	switch (iItemDefinitionIndex) {
		case 10, 12, 11, 9: iItemDefinitionIndex = 199;
		case 13: iItemDefinitionIndex = 200;
		case 18: iItemDefinitionIndex = 205;
		case 21: iItemDefinitionIndex = 208;
		case 22, 23: iItemDefinitionIndex = 209;
		case 19: iItemDefinitionIndex = 206;
		case 20: iItemDefinitionIndex = 207;
		case 15: iItemDefinitionIndex = 202;
		case 7:  iItemDefinitionIndex = 197;
		case 29: iItemDefinitionIndex = 211;
		case 14: iItemDefinitionIndex = 201;
		case 16: iItemDefinitionIndex = 203;
		case 4:  iItemDefinitionIndex = 194;
	}
	
	return (oldId != iItemDefinitionIndex);
}