// This file contains all needed declarations for the tf2item_weapons plugin.
#include "tf2items/tf2item_base.inc"

// Bit Values for Spells
#define WeaponSpell_Excorcism          (1 << 0)
#define WeaponSpell_SquashRockets      (1 << 1)
#define WeaponSpell_SpectralFlames     (1 << 2)
#define WeaponSpell_SentryQuadPumpkins (1 << 3)
#define WeaponSpell_GourdGrenades      (1 << 4)

// Custom Defines
#define MAX_WEAPONS            3
#define INVALID_WEAPON_ENTITY -1

// Weapon
//
//  Represents a single weapon instance for the user.
//  This is utilized to define each original weapon's properties if overrides are not set.
enum struct Cosmetic {
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
}

//
// Menu Creators
////////////////

// mMainMenu - Main menu for all users. Allows them to select one of their weapons to begin modifying them.
void mMainMenu(int client) {
	Menu menu = new Menu(mainHdlr);
	
	menu.SetTitle("Welcome! Select a Weapon");
	
	for (int i = 0; i < MAX_WEAPONS; i++) {
		int weapon = GetPlayerWeaponSlot(client, i);
		
		if (weapon != INVALID_WEAPON_ENTITY) {
			char name[64], idStr[12];
			
			int iItemDefinitionIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			
			Format(idStr, sizeof(idStr), "%d", iItemDefinitionIndex);
			TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
			
			menu.AddItem(idStr, name);
		}
	}
	
	menu.AddItem("-", "Usage: Select your desired weapon and start fiddling!");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// wMainMenu - Main menu for selected weapons; shows a resume of what can be modified on it and what can't (according to compatibility).
void wMainMenu(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(wepHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("What will you modify on %s?", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	bool sameItem = pWeapons[client].iItemIndex[slot] == iItemDefinitionIndex;
	
	////////////////////////////////////////////////////////
	// Can be Australium?
	bool isAussie = pWeapons[client].Aussie[slot], canAussie = CanBeAustralium(iItemDefinitionIndex);
	
	menu.AddItem("a", (isAussie && canAussie && sameItem) ? "Australium: [X]" : "Australium: [ ]", canAussie ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Can be Festivized?
	bool isFestive = pWeapons[client].Festive[slot], canFestive = CanBeFestivized(iItemDefinitionIndex);
	
	menu.AddItem("f", (isFestive && canFestive && sameItem) ? "Festivized: [X]" : "Festivized: [ ]", canFestive ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Can be War Painted?
	int wPaint = pWeapons[client].wPaint[slot], canWar = CanBePainted(iItemDefinitionIndex);
	
	char wPaintName[128];
	if (wPaint > -1) {
		char wPaintWear[128];
		GetWarPaintWearName(pWeapons[client].wWear[slot]);
		
		Format(wPaintName, sizeof(wPaintName), "%d", wPaint);
		
		// If a translation for this War Paint exists, we use it. Else, just set it as unknown.
		// There shouldn't be EVER a case where a War Paint is Unknown. This is because selectable War Paints are checked before adding them to the menu.
		if (TranslationPhraseExists(wPaintName) && sameItem)
			Format(wPaintName, sizeof(wPaintName), "War Paint: %T (Wear: %s)", wPaintName, client, wPaintWear);
		else
			Format(wPaintName, sizeof(wPaintName), "War Paint: Unknown (Wear: %s)", wPaintWear);
	}
	
	menu.AddItem("w", strlen(wPaintName) > 0 ? wPaintName : "War Paint: N/A", canWar ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Now, here comes everything that's always appliable.
	// Killstreak Effects
	menu.AddItem("k", "Killstreak Effects");
	
	// Unusual Effects
	int uEffect = pWeapons[client].uEffects[slot];
	char uName[64];
	GetUnusualWeaponName(sameItem ? uEffect : -1, uName, sizeof(uName));
	
	Format(uName, sizeof(uName), "Unusual Effect: %s", uName);
	
	menu.AddItem("u", uName);
	
	// Halloween Spells (only Exorcism is always appliable)
	menu.AddItem("s", "Halloween Spells");
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// wWarPaint - Menu that allows players to select their War Paint settings (Specific protodef ID and wear value)
void wWarPaint(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(wPaintHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("War Paint Settings for %s", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	bool sameItem = pWeapons[client].iItemIndex[slot] == iItemDefinitionIndex;
	
	// Actual options
	int   wPaint = pWeapons[client].wPaint[slot];
	float wear   = pWeapons[client].wWear[slot];
	
	char wPaintName[128], wPaintWearName[128];
	// Format War Paint Display String
	Format(wPaintName, sizeof(wPaintName), "%d", wPaint);
	if (TranslationPhraseExists(wPaintName) && sameItem)
		Format(wPaintName, sizeof(wPaintName), "War Paint: %T", wPaintName, client);
	else
		Format(wPaintName, sizeof(wPaintName), "War Paint: No Override");
	
	// Format Wear Display String
	GetWarPaintWearName(sameItem ? wear : -1.0, wPaintWearName, sizeof(wPaintWearName));
	Format(wPaintWearName, sizeof(wPaintWearName), "War Paint Wear: %s", wPaintWearName);
	
	menu.AddItem("p", wPaintName);
	menu.AddItem("w", wPaintWearName);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

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
	
	menu.AddItem("-1", "No Override");
	
	// Get all valid War Paints at the moment.
	ArrayList paints = TF2Econ_GetPaintKitDefinitionList();
	for (int i = 0; i < paints.Length; i++) {
		char pStr[12];
		IntToString(paints.Get(i));
		
		if (TranslationPhraseExists(pStr)) {
			char pName[64];
			Format(pName, sizeof(pName), "%T", pStr, client);
			
			menu.AddItem(pStr, pName);
		} else
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

// kKillstreaks - Main Killstreak effects menu. Allows the user to visualize their Killstreak effects preferences currently set.
void kKillstreaks(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(kKillstreakHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("Killstreak Preferences for %s", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	bool sameItem = pWeapons[client].iItemIndex[slot] == iItemDefinitionIndex;
	
	// Killstreak Type
	int type = pWeapons[client].kType[slot];
	char kTypeName[128];
	
	GetKillstreakTypeName(sameItem ? type : -1, kTypeName, sizeof(kTypeName));
	Format(kTypeName, sizeof(kTypeName), "Killstreak Type: %s", kTypeName);
	
	menu.AddItem("t", kTypeName);
	
	// Killstreak Sheen (Depends on the type, this will either be disabled or enabled for selection)
	// It is also checked the user has a correct Killstreak type set to apply an overriden sheen/streaker.
	//
	// TODO: identify original killstreak type to allow sheen and killstreaker overrides without enforcing a type
	//
	int sheen = pWeapons[client].kSheen[slot];
	char kSheenName[128];
	
	GetSheenName(sameItem ? sheen : -1, kSheenName, sizeof(kSheenName));
	Format(kSheenName, sizeof(kSheenName), "Sheen: %s", kSheenName);
	
	menu.AddItem("s", kSheenName, (1 < type <= 3) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Killstreaker (same as sheen, only this time it MUST BE 3)
	int killstreaker = pWeapons[client].kStreaker[slot];
	char kStreakerName[128];
	
	GetKillstreakerName(sameItem ? killstreaker : -1, kStreakerName, sizeof(kStreakerName));
	Format(kStreakerName, sizeof(kStreakerName), "Killstreaker: %s", kStreakerName);
	
	menu.AddItem("k", kStreakerName, (type == 3) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Done!
	
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
		GetSheenName(StringToInt(unusuals[i]), wUnusualName, sizeof(wUnusualName));
		
		menu.AddItem(unusuals[i], wUnusualName);
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// wSpells - Allows a player to set Halloween Spells on their weapon (if applicable)
void wSpells(int client, int iItemDefinitionIndex, int slot) {
	Menu menu = new Menu(wSpellsHdlr);
	
	char name[64], idStr[12], slotStr[2];
	TF2Econ_GetItemName(iItemDefinitionIndex, name, sizeof(name));
	IntToString(iItemDefinitionIndex, idStr, sizeof(idStr));
	IntToString(slot, slotStr, sizeof(slotStr));
	
	menu.SetTitle("Toggling Spells on %s", name);
	
	// Menu Data Embedding
	menu.AddItem(idStr, "", ITEMDRAW_IGNORE);
	menu.AddItem(slotStr, "", ITEMDRAW_IGNORE);
	
	// Time to see applicability
	int spells = pWeapons[client].sSpells; // Spell Bitfield
	TFClassType class = TF2_GetPlayerClass(client);
	
	bool sameItem = pWeapons[client].iItemIndex[slot] == iItemDefinitionIndex;
	
	// Exorcism can always be applied
	menu.AddItem("e", (spells & WeaponSpell_Excorcism && sameItem) ? "Exorcism: [X]" : "Exorcism: [ ]");
	
	// Squash Rockets (Only on Soldier Primaries)
	// Since "slot" is relative to the weapon slot, we can compare it.
	menu.AddItem("r", (spells & WeaponSpell_SquashRockets && sameItem) ? "Squash Rockets: [X]" : "Squash Rockets: [ ]", (class == TFClass_Soldier && slot == 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Spectral Flames (Only on Pyro Primaries)
	menu.AddItem("f", (spells & WeaponSpell_SpectralFlames && sameItem) ? "Spectral Flames: [X]" : "Spectral Flames: [ ]", (class == TFClass_Pyro && slot == 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Sentry Quad Pumpkins (Only on Engineer Melee)
	menu.AddItem("s", (spells & WeaponSpell_SentryQuadPumpkins && sameItem) ? "Sentry Quad-Pumpkins: [X]" : "Sentry Quad-Pumpkins: [ ]", (class == TFClass_Engineer && slot == 2) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	// Gourd Grenades (Only on Demoman Primaries & Secondaries)
	menu.AddItem("g", (spells & WeaponSpell_GourdGrenades && sameItem) ? "Gourd Grenades: [X]" : "Gourd Grenades: [ ]", (class == TFClass_DemoMan && (0 <= slot <= 1)) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
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
		case -1: StrCopy(buffer, size, "No Override");
		case 0:  StrCopy(buffer, size, "Disabled");
		case 1:  StrCopy(buffer, size, "Basic");
		case 2:  StrCopy(buffer, size, "Specialized");
		case 3:  StrCopy(buffer, size, "Professional");
		default: StrCopy(buffer, size, "Unknown");
	}
}

/*
 * void GetSheenName
 * 
 *  Copies into a buffer the Killstreak Sheen name currently set for that number.
 */
void GetSheenName(int sheen, char[] buffer, int size) {
	switch (sheen) {
		case -1: StrCopy(buffer, size, "No Override");
		case 0:  StrCopy(buffer, size, "Disabled");
		case 1:  StrCopy(buffer, size, "Team Shine");
		case 2:  StrCopy(buffer, size, "Deadly Daffodil");
		case 3:  StrCopy(buffer, size, "Manndarin");
		case 4:  StrCopy(buffer, size, "Mean Green");
		case 5:  StrCopy(buffer, size, "Agonizing Emerald");
		case 6:  StrCopy(buffer, size, "Villanious Violet");
		case 7:  StrCopy(buffer, size, "Hot Rod");
		default: StrCopy(buffer, size, "Unknown");
	}
}

/*
 * void GetKillstreakerName
 * 
 *  Copies into a buffer the Killstreak Killstreaker name currently set for that number.
 */
void GetKillstreakerName(int killstreaker, char[] buffer, int size) {
	switch (killstreaker) {
		case -1:   StrCopy(buffer, size, "No Override");
		case 0:    StrCopy(buffer, size, "Disabled");
		case 2002: StrCopy(buffer, size, "Fire Horns");
		case 2003: StrCopy(buffer, size, "Cerebral Discharge");
		case 2004: StrCopy(buffer, size, "Tornado");
		case 2005: StrCopy(buffer, size, "Flames");
		case 2006: StrCopy(buffer, size, "Singularity");
		case 2007: StrCopy(buffer, size, "Incinerator");
		case 2008: StrCopy(buffer, size, "Hypno-Beam");
		default:   StrCopy(buffer, size, "Unknown");
	}
}

/*
 * void GetWarPaintWearName
 * 
 *  Copies into a buffer the War Paint wear currently set for that number.
 */
void GetWarPaintWearName(float wear, char[] buffer, int size) {
	switch (wear) {
		case -1.0:	   StrCopy(buffer, size, "No Override");
		case 0.0, 0.2: StrCopy(buffer, size, "Factory New");
		case 0.4: 	   StrCopy(buffer, size, "Minimal Wear");
		case 0.6:	   StrCopy(buffer, size, "Field-Tested");
		case 0.8:	   StrCopy(buffer, size, "Well-Worn");
		case 1.0:	   StrCopy(buffer, size, "Battle Scarred");
		default:	   StrCopy(buffer, size, "Unknown");
	}
}

/*
 * void GetUnusualWeaponName
 * 
 *  Copies into a buffer the Unusual effect name for that specific ID.
 */
void GetUnusualWeaponName(int unusual, char[] buffer, int size) {
	switch (unusual) {
		case -1:  StrCopy(buffer, size, "No Override");
		case 701: StrCopy(buffer, size, "Hot");
		case 702: StrCopy(buffer, size, "Isotope");
		case 703: StrCopy(buffer, size, "Cool");
		case 704: StrCopy(buffer, size, "Energy Orb");
		default:  StrCopy(buffer, size, "Unknown");
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
bool CanBeAustralium(int iItemDefinitionIndex) {
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
bool StockToStrange(int iItemDefinitionIndex) {
	int oldId = iItemDefinitionIndex;
	
	switch (iItemDefinitionIndex) {
		case 13: iItemDefinitionIndex = 200;
		case 18: iItemDefinitionIndex = 205;
		case 21: iItemDefinitionIndex = 208;
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