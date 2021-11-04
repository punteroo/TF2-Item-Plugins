# TF2 Item Management Plugins

Some months ago I started developing private plugins for communities that modify items for the game. It **IS AGAINST TOS**, and I know this can't be released on **AlliedModders** because of such, but because **VALVe** doesn't care for their game and it's been 7 years since a token ban has been issued I'll be releasing these public.

As [404](https://github.com/404UNFca) said once:
```
It technically is against the TOS, and using something like it could have potentially gotten your server blacklisted about 8-9 years ago. Nowadays, not so much. Many community servers in existence are using this system.

For example, Skial uses it for their "!items" system that allows you to equip any weapon or cosmetic you want (even rare ones like the Wiki Cap, Top Notch, Golden Wrench, Golden Frying Pan, etc) and they're visible to other players. What has changed in the past 8-9 years is that Valve is now more focused on CS:GO and Half Life: Alyx.

TF2 servers have not suffered any GLST token bans in many years. Even CS:GO servers, which were frequently hit by GLST token bans for using fake knife/gun/etc skin plugins, have slowly over time stopped being hit by GLST token bans. It seems Valve has either lightened up on former community "restrictions", or they're too busy with HL:A to notice. lmao nevermind, seems they just banned the GLST tokens of someone in our community who was generating them en masse. Be careful if you choose to use this fucker as Valve could rear their heads towards Team Fortress 2 next. Especially be careful if you're a group like Skial that abuses this netprop.

Basically, by using this plugin, you are acknowledging that there is still the possibility that Valve could come around one day and blacklist your server. Don't blame me if such a thing happens either.
```
[source](https://github.com/NiagaraDryGuy/TF2ServersidePlayerAttachmentFixer/blob/90c2a2f41cd8b4fc872de59d05114913064066cd/README.md#frequently-asked-question-yes-singular)

I might make some other releases if people want things fixed or whatever. I just release them because keeping them private is worthless, they're already everywhere and even some other devs have made their own versions of this public as well.
Feel free to use these plugins wherever you want.

**This plugin makes use of the ``m_bValidatedAttachedEntity`` networked property, which bypasses the restriction made by VALVe where fake items are invisible to others. Everyone on the server will be able to see your items with these plugins.**

If you have any doubts or want something else, just write it down on the **Issues** tab or contact me directly through **Discord**. My tag is **puntero#6566**. Enjoy.

# TODO
- [x] Translations, for Spanish and English users.
- [X] Merge everything to maintain functionality, as one removes the others' effects.
- [X] Implement preference saving on **tf2item_cosmetics** and **tf2item_weapons** so selected user effects are applied whenever the user re-joins the server. This would nullify the player from opening the menus again each map change to re-apply said preferences.
- [X] Fix Unusual Effects (custom or legit) not being kept after applying a custom paint effect, could probably be permanently fixed when the merge is applied (merge is done).
- [x] ~~Refresh handles upon re-loading to prevent plugin failing on late-load (reload, refresh or unload and load)~~ Replace all ``Handle``s for ``enum struct``s.
- [x] Fix a **probably problematic** memory leak when applying Unusual Effects.

# Requirements

In order for these plugins to work you need the following dependencies installed on your server:
* [TF2Items (1.6.4-279)](https://forums.alliedmods.net/showthread.php?t=115100)
* [TF2Attributes (nosoop's Fork)](https://github.com/nosoop/tf2attributes)
* [TFEconData (latest)](https://github.com/nosoop/SM-TFEconData)

For compilation you require my custom includes provided in the repository, the includes from the dependencies mentioned above and the following includes as well:
* [MoreColors](https://forums.alliedmods.net/showthread.php?t=185016)

# Installation

As of **v3.0.0** TF2IDB is no longer required. Installation is literally a Drag & Drop of what's inside the **.zip** file.

Read all the articles inside the [Requirements](https://github.com/punteroo/TF2-Item-Plugins#requirements) section and install them independently, then head over to the [Releases](https://github.com/punteroo/TF2-Item-Plugins/releases) section in this repository and download the latest one. **NOW** you can Drag & Drop the contents of the **.zip** into ``addons/sourcemod/``.

If any error was present during installation, contact me through **Discord** and I'll help you out whenever I'm able to.

# Updating

Only update whenever a new **TF2 Update** fires (I know, weird but happens). I've written **.py** scripts inside the ``sourcemod/translations`` folder to update the **Unusual Effects** and **War Paint** names. The plugin checks for an existing translation phrase for each **ID**, if none is found the particle/protodef ID is skipped.

You will require to run these **.py** scripts to update each of them.

## Updating tf2item_cosmetics

1. Head over to your **SourceMod** installation and into the ``translations`` folder.
2. You should see a **Python Script** named [unusual_names_updater.py](https://github.com/punteroo/TF2-Item-Plugins/blob/production/translations/unusual_names_updater.py) (if not, click on the link and download it). Write down its absolute location (For ex.: ``C:/unusual_names_updater.py``)
3. **NOTE:** The scripts' location is not important, it doesn't have to be in the translations folder.
4. Fire up ``cmd`` as Administrator (or Terminal on an user with write and read rights to both files if on Linux) and ``cd`` into the script's location.
5. Write ``py <script location> -tf <tf_english.txt location> -out <output location>`` and hit **ENTER**.
6. **NOTE:** tf_english.txt is always located in your Team Fortress 2 installation at ``tf/resource/tf_english.txt``. For output, you can target anything and copy the file later to your SourceMod installation's ``translations`` folder. **Make sure the output filename is ``unusuals.phrases.txt``.**
7. If everything goes well, the updated translations file should be outputted without any issues.

## Updating tf2item_weapons

The script is primitive. I will write an easier to use script later (PRs are also welcome).

Also Unused War Paints are parsed, so watch out!

1. Head over to your **SourceMod** installation and into the ``translations`` folder.
2. You should see a **Python Script** named [paintkits.py](https://github.com/punteroo/TF2-Item-Plugins/blob/production/translations/paintkits.py) (if not, click on the link and download it). Write down its absolute location (For ex.: ``C:/paintkits.py``)
3. **NOTE:** The scripts' location is not important, it doesn't have to be in the translations folder.
4. Create a ``.txt`` file named``paintkits.txt`` on the same directory as the script.
5. Fill its contents with entries from the file ``tf_proto_obj_defs.txt`` that start with ``9_`` located in your ``tf/resource/`` folder inside your TF2 Installation.
6. **NOTE:** There's an example entry file on the repo if you need an example for format. Those entries should look like this, just copy the ones that start with ``9_``:
```
	"9_0_field { field_number: 2 }"		"Red Rock Roscoe"
	"9_100_field { field_number: 2 }"		"100: (Unused) Red Rock Roscoe"
	"9_101_field { field_number: 2 }"		"101: (Unused) Sand Cannon"
	"9_102_field { field_number: 2 }"		"Wrapped Reviver Mk.II"
	"9_103_field { field_number: 2 }"		"103: (Unused) Psychedelic Slugger"
	
	...
```
8. The script will print out the translations content. Copy the scripts' output and create a file inside your SourceMod installation's ``translations`` folder named ``weapons.phrases.txt``.

# Plugin Pack Usage

## ConVars (new with v3.0.1)
You can now customize the plugin pack's functionality utilizing **ConVars**.

ConVar | Description | Plugin it Affects | Default Value
------ | ----------- | ----------------- | -------------
tf2items_general_onlyspawn | Restricts players to only be able to utilize any manager inside a spawn region. | **tf2item_cosmetics** & **tf2item_weapons** | 0
tf2items_cosmetics_show_missing_particles | Logs whenever a valid ID for a War Paint or Unusual Effect is tried to be added onto a menu, but fails because of a missing translation phrase. Good to know for updating, but bad because of the spam amount. | **tf2item_cosmetics** & **tf2item_weapons** | 0
tf2items_cosmetics_unusuals | Toggles the ability for players to utilize Unusual Overrides on their cosmetics. | **tf2item_cosmetics** | 1
tf2items_cosmetics_paints | Toggles the ability for players to utilize Paint Overrides on their cosmetics. | **tf2item_cosmetics** | 1
tf2items_cosmetics_spells | Toggles the ability for players to utilize Halloween Spell Overrides on their cosmetics. | **tf2item_cosmetics** | 1
tf2items_cosmetics_append_ids | Appends the Unusual Effect ID to its name on the menu. Ex.: ``Burning Flames (#13)`` | **tf2item_cosmetics** | 0

## tf2item_cosmetics
* Players can customize their legit cosmetic items at will, applying Unusual effects, paint colors, spells and spell paints.
* Overrides set by this plugin will always keep in mind original attributes, for ex.: _if you have a legit **Unusual Pomade Prince** with **Halloween Spell: Voices From Below** and **Molten Mallard** effect, they will not disappear when setting a paint colour on it, only when overriden by the same attribute (such as changing the Unusual effect to **Burning Flames**)_

Command | Description | Example
----------- | ------------- | ----------
sm_cosmetics | Opens up the Cosmetics Manager. | [YouTube Video Demonstration](https://www.youtube.com/watch?v=XsFySomgYYk)
sm_hats | Same as the command above, just different | N/A
sm_myhats | Same as the command above, just different | N/A

## tf2item_weapons
* Players can customize their legit weapons at will, applying Unusual effects, setting Australiums and/or Festivizers, custom War Paints with custom Wears, spells and entire Killstreak combinations.
* All War Paints in the game are listed ([if there's a translation phrase registered for that specific one](https://github.com/punteroo/TF2-Item-Plugins#Updating-tf2item_cosmetics)), but that doesn't mean they can all be applied to a certain weapon.
* War Paints can either: keep the Wear of the original weapon (if it has it) or set a custom one.
* Overrides set by this plugin will always keep in mind original attributes, for ex.: _if you have a legit **Australium Scattergun** with **Specialized Killstreak** and **Team Shine** sheen, they will not dissapear when setting (for example) an Unusual effect on it, only when overriden by the same attrbute (such as changing the applied Sheen on it)_

Command | Description | Example
----------- | ------------- | ----------
sm_weapons | Opens up the Weapons Manager. | [YouTube Video Demonstration](https://www.youtube.com/watch?v=jCfrcZXz_FQ)
sm_weps | Same as the command above, just different | N/A
sm_myweps | Same as the command above, just different | N/A

## vip-unusual-glow
* Allows players to apply one of the new 'player glow' Unusual taunt effects on them permanently.
* This plugin has reports of lowering other players' FPS due to the Unusual effect being constantly applied to the player. There is nothing I can do about this issue other than tell you to get a better PC or blame the game for not having great optimization in this matter.

Command | Description | Example
----------- | ------------- | ----------
sm_unuglow | Opens up the Unusual Glowing configuration menu. | [YouTube Video Demonstration](https://www.youtube.com/watch?v=zKSHS9405z8)
sm_glowme | Same as the command above, just different | N/A

## vip-system
* A customizable menu that displays commands for your **VIP** members. This hasn't got to do with the repository, but I dip this in just if someone needs it.
* Everything is explained in the configuration file located in ``configs/vip-system.cfg`` with an example of how it must be written.

### Configuration File
* To modify the menu, edit the config located in ``addons/sourcemod/configs/vip-system.cfg``. An example structure for the config would be as such:
```cpp
"VIP-System"
{
	"Cosmetics Manager" // What the player reads in the menu as an option.
	{
		"command"		"sm_hats" // The command that is executed for the player.
	}
	"Weapons Manager"
	{
		"command"		"sm_weps"
	}
	"Unusual Glow"
	{
		"command"		"sm_unuglow"
	}
}
```

Command | Description | Example
----------- | ------------- | ----------
sm_vipmenu | Opens up the VIP menu. Everything is controlled and modified from the configuration file. | N/A
sm_vip | Alias for the main command. | N/A
sm_donor | Alias for the main command. | N/A
sm_donator | Alias for the main command. | N/A
