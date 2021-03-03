#include <tf2attributes>

int glowIds[6] = {
	0, 3041, 3042, 3043,
	3044, 3045
}

/* CreateGlowMenu(int client)
 * Creates a menu with all the glow options, and displays it to the player.
 * ----------------------------------
 * return - void()
 */
void CreateGlowMenu(int client)
{
	Menu menu = new Menu(glowHdlr);
	
	menu.SetTitle("%T", "UnuGlow_MenuTitle", client);
	
	for (int i = 0; i < sizeof(glowIds); i++) {
		char idStr[12], glowName[64];
		IntToString(glowIds[i], idStr, sizeof(idStr));
		
		Format(glowName, sizeof(glowName), "UnuGlow%d", glowIds[i]);
		Format(glowName, sizeof(glowName), "%T", glowName, client);
		
		menu.AddItem(idStr, glowName);
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
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
	return false;
}