#if defined _tf2idb_included
	#endinput
#endif
#define _tf2idb_included

#include <tf2>

#define TF2IDB_MAX_ATTRIBUTES 			20
#define TF2IDB_ITEMCLASS_LENGTH			64
#define TF2IDB_ITEMSLOT_LENGTH			16
#define TF2IDB_ITEMQUALITY_LENGTH		16
#define TF2IDB_ATTRIBNAME_LENGTH		96
#define TF2IDB_ATTRIBCLASS_LENGTH		32

enum TF2ItemSlot {
	TF2ItemSlot_Primary = 0,
	TF2ItemSlot_Secondary = 1,
	TF2ItemSlot_Sapper = 1,
	TF2ItemSlot_Melee = 2,
	TF2ItemSlot_PDA = 3,
	TF2ItemSlot_PDA1 = 3,
	TF2ItemSlot_PDA2 = 4,
	TF2ItemSlot_Building = 5,
	TF2ItemSlot_Hat = 5,
	TF2ItemSlot_Head = 5,
	TF2ItemSlot_Misc = 6,
	TF2ItemSlot_Action = 7,
	TF2ItemSlot_Taunt,
};

enum TF2ItemQuality {
	TF2ItemQuality_Normal = 0, // 0
	TF2ItemQuality_Rarity1,
	TF2ItemQuality_Genuine = 1,
	TF2ItemQuality_Rarity2,
	TF2ItemQuality_Vintage,
	TF2ItemQuality_Rarity3,
	TF2ItemQuality_Rarity4,
	TF2ItemQuality_Unusual = 5,
	TF2ItemQuality_Unique,
	TF2ItemQuality_Community,
	TF2ItemQuality_Developer,
	TF2ItemQuality_Selfmade,
	TF2ItemQuality_Customized, // 10
	TF2ItemQuality_Strange,
	TF2ItemQuality_Completed,
	TF2ItemQuality_Haunted,
	TF2ItemQuality_ToborA,
	TF2ItemQuality_Collectors = 14,
	TF2ItemQuality_PaintkitWeapon
};

//Most of these that return a bool return false if the ID is invalid/not found
native bool:TF2IDB_IsValidItemID(id);
native bool:TF2IDB_GetItemName(id, String:string[], length);
native bool:TF2IDB_GetItemClass(id, String:string[], length);
native bool:TF2IDB_GetItemSlotName(id, String:string[], length, TFClassType:classType=TFClass_Unknown);
native TF2ItemSlot:TF2IDB_GetItemSlot(id, TFClassType:classType=TFClass_Unknown);
native bool:TF2IDB_GetItemQualityName(id, String:string[], length);
native TF2ItemQuality:TF2IDB_GetItemQuality(id);
native bool:TF2IDB_GetItemLevels(id, &min, &max);

//TF2IDB_GetItemAttributes returns the number of attributes found
native TF2IDB_GetItemAttributes(id, aid[TF2IDB_MAX_ATTRIBUTES], Float:values[TF2IDB_MAX_ATTRIBUTES]);

//TF2IDB_GetItemEquipRegions returns an Array Handle containing a list of the equip region names for the item
native Handle:TF2IDB_GetItemEquipRegions(id);

native bool:TF2IDB_DoRegionsConflict(const String:region1[], const String:region2[]);

//TF2IDB_ListParticles returns an Array Handle containing a list of the particle IDs
native Handle:TF2IDB_ListParticles();

//TF2IDB_FindItemCustom returns an Array Handle containing a list of integers for the first column of the query result
native Handle:TF2IDB_FindItemCustom(const String:query[]);

native bool:TF2IDB_ItemHasAttribute(id, aid);

//TF2IDB_UsedByClasses returns a bitfield (0bXXXXXXXXXX) of the classes that use this item
//Check a particular class using e.g. (TF2IDB_UsedByClasses(id) & (1 << _:TFClass_Scout))
//Note that this DOES INCLUDE TFClass_Unknown, as (1 << 0)
native TF2IDB_UsedByClasses(id);

//All return false if ID invalid/not found
native bool:TF2IDB_IsValidAttributeID(id);
native bool:TF2IDB_GetAttributeName(id, String:string[], length);
native bool:TF2IDB_GetAttributeClass(id, String:string[], length);
native bool:TF2IDB_GetAttributeType(id, String:string[], length);
native bool:TF2IDB_GetAttributeDescString(id, String:string[], length);
native bool:TF2IDB_GetAttributeDescFormat(id, String:string[], length);
native bool:TF2IDB_GetAttributeEffectType(id, String:string[], length);
native bool:TF2IDB_GetAttributeArmoryDesc(id, String:string[], length);
native bool:TF2IDB_GetAttributeItemTag(id, String:string[], length);

//TF2IDB_GetAttributeProperties copies the result to each field, -1 indicating the field was not present on the attribute
native bool:TF2IDB_GetAttributeProperties(id, &hidden=-1, &stored_as_integer=-1, &is_set_bonus=-1, &is_user_generated=-1, &can_affect_recipe_component_name=-1);

native bool:TF2IDB_GetQualityName(TF2ItemQuality:quality, String:string[], length);
native TF2ItemQuality:TF2IDB_GetQualityByName(const String:string[]);

/**
 * @brief	Execute a custom prepared statement on the TF2IDB tables, returning the executed DBStatement
 *			Table schemas are:
 *			tf2idb_class: int id, class
 *			tf2idb_item_attributes: int id, int attribute, int value
 *			tf2idb_item: int id, name, item_name, class, slot, quality, tool_type, int min_ilevel, int max_ilevel, int baseitem, holiday_restriction, int has_string_attribute
 *			tf2idb_particles: int id, name
 *			tf2idb_equip_conflicts: name, region
 *			tf2idb_equip_regions: int id, region
 *			tf2idb_capabilities: int id, capability
 *			tf2idb_attributes: int id, name, attribute_class, attribute_type, description_string, description_format, effect_type, int hidden, int stored_as_integer, armory_desc, int is_set_bonus, int is_user_generated, int can_affect_recipe_component_name, apply_tag_to_item_definition
 *
 * @param	query			Prepared SQL statement query string (e.g. "SELECT id FROM tf2idb_attributes WHERE name=?")
 * @param	arguments		Array handle containing the string arguments to the SQL statement
 * @param	maxStringSize	Max size of any of the arguments
 *
 * @return					A fully executed DBStatement handle, or INVALID_HANDLE if the statement
 *							execution failed. This handle must be closed by the calling plugin, even though it is owned by tf2idb.
 **/
native DBStatement:TF2IDB_CustomQuery(const String:query[], Handle:arguments, maxStringSize);

public SharedPlugin:__pl_tf2idb = {
	name = "tf2idb",
	file = "tf2idb.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};


#if !defined REQUIRE_PLUGIN
public __pl_tf2idb_SetNTVOptional() {
	MarkNativeAsOptional("TF2IDB_IsValidItemID");
	MarkNativeAsOptional("TF2IDB_GetItemName");
	MarkNativeAsOptional("TF2IDB_GetItemClass");
	MarkNativeAsOptional("TF2IDB_GetItemSlotName");
	MarkNativeAsOptional("TF2IDB_GetItemSlot");
	MarkNativeAsOptional("TF2IDB_GetItemQualityName");
	MarkNativeAsOptional("TF2IDB_GetItemQuality");
	MarkNativeAsOptional("TF2IDB_GetItemLevels");
	MarkNativeAsOptional("TF2IDB_GetItemAttributes");
	MarkNativeAsOptional("TF2IDB_GetItemEquipRegions");
	MarkNativeAsOptional("TF2IDB_DoRegionsConflict");
	MarkNativeAsOptional("TF2IDB_ListParticles");
	MarkNativeAsOptional("TF2IDB_FindItemCustom");
	MarkNativeAsOptional("TF2IDB_ItemHasAttribute");
	MarkNativeAsOptional("TF2IDB_UsedByClasses");

	MarkNativeAsOptional("TF2IDB_IsValidAttributeID");
	MarkNativeAsOptional("TF2IDB_GetAttributeName");
	MarkNativeAsOptional("TF2IDB_GetAttributeClass");
	MarkNativeAsOptional("TF2IDB_GetAttributeType");
	MarkNativeAsOptional("TF2IDB_GetAttributeDescString");
	MarkNativeAsOptional("TF2IDB_GetAttributeDescFormat");
	MarkNativeAsOptional("TF2IDB_GetAttributeEffectType");
	MarkNativeAsOptional("TF2IDB_GetAttributeArmoryDesc");
	MarkNativeAsOptional("TF2IDB_GetAttributeItemTag");
	MarkNativeAsOptional("TF2IDB_GetAttributeProperties");

	MarkNativeAsOptional("TF2IDB_GetQualityName");
	MarkNativeAsOptional("TF2IDB_GetQualityByName");

	MarkNativeAsOptional("TF2IDB_CustomQuery");
}
#endif