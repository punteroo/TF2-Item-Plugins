#include <sourcemod>
#include <lang>
#include <tf2_stocks>

#include <morecolors>

#include <tf2items>
#include <tf2attributes>
#include <tf_econ_data>

// Global Static Defines
////////////////////////

#define PGTAG		   "{mythical}[TF2Items]{white}"

//    ConVars and more customization for user experiences.
// 			TODO: Implement convar usage
// Global
ConVar CV_OnlySpawn = CreateConVar("tf2items_general_onlyspawn", "1", "Controls wether players can only modify their items inside spawn boundaries. Default is 1.", _, true, 0.0, true, 1.0),
	   CV_OnlyAdmin = CreateConVar("tf2items_general_onlyadmin", "0", "Should only administrators (flag 'b'+) be able to utilize these plugins? Default is 0.", _, true, 0.0, true, 1.0),
	   
// Cosmetics Manager
CV_Cosmetics_Unusuals = CreateConVar("tf2items_cosmetics_unusuals", "1", "Are unusual overrides enabled? Default is 1.", _, true, 0.0, true, 1.0),
CV_Cosmetics_Paint    = CreateConVar("tf2items_cosmetics_paints", "1", "Are paint overrides enabled? Default is 1.", _, true, 0.0, true, 1.0),
CV_Cosmetics_Spells   = CreateConVar("tf2items_cosmetics_spells", "1", "Are halloween spells overrides enabled? Default is 1.", _, true, 0.0, true, 1.0),

CV_Cosmetics_ShowIDs    = CreateConVar("tf2items_cosmetics_append_ids", "0", "Should Item Definition Indexes and Unusual Effect Indexes be appended onto their names? " ...
																			 "Example: 'Burning Flames (#13)'", _, true, 0.0, true, 1.0),
CV_Cosmetics_UParticles = CreateConVar("tf2items_cosmetics_show_missing_particles", "0", "Logs to the server whenever a parsed Unusual Particle ID does not have an" ...
																						 " existing translation for their name. I recommend leaving this off, as it causes" ...
																						 " too much console spam and should only be used to debug. Default is 0.", _, true, 0.0, true, 1.0);

//
// General Functions
////////////////////