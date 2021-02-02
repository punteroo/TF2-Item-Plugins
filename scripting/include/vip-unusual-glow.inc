#include <tf2attributes>

char glowNames[6][64] = {
	"None", "Emerald Allurement", "Pyrophoric Personality", "Spellbound Aspect",
	"Static Shock", "Veno Shock"
};

float glowIds[6] = {
	0.0, 3041.0, 3042.0, 3043.0,
	3044.0, 3045.0
}

/* CreateGlowMenu()
 * Creates a menu with all the glow options.
 * ----------------------------------
 * return - Menu Handle with all data needed. Handler name is "glowHdlr"
 */
Menu CreateGlowMenu()
{
	Menu menu = CreateMenu(glowHdlr);
	
	menu.SetTitle("Glow Effects");
	
	for (int i = 0; i < sizeof(glowNames); i++) {
		char idStr[12];
		FloatToString(glowIds[i], idStr, sizeof(idStr));
		
		menu.AddItem(idStr, glowNames[i]);
	}
	
	menu.ExitButton = true;
	
	return menu;
}

/*
 * SetGlow(int client, float eff)
 * Sets the glow effect on the specified client.
 * A value of eff = 0.0 will remove the particle effect.
 * ----------------------------------------------
 * client - Client index of the player to set the effect on.
 * eff    - Effect ID to set on the client.
 * return - True if the effect was applied successfully, false if there was an error (client has no m_Item net table)
 */
bool SetGlow(int client, float eff)
{
	TF2Attrib_RemoveByName(client, "attach particle effect");
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && eff > 0.0)
		return TF2Attrib_SetByName(client, "attach particle effect", eff);
}