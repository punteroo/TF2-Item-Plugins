# TF2 Item Management Plugins
Some months ago I started developing private plugins for communities that modify items for the game. It **IS AGAINST TOS**, and I know this can't be released on **AlliedModders** because of such, but because **VALVe** doesn't care for their game and it's been 7 years since a token ban has been issued I'll be releasing these public.

As @NiagaraDryGuy said once:
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
- [ ] Translations, for Spanish and English users.
- [ ] Merge **vip-unusuals** with **vip-paints** to maintain functionality between them, as one removes the others' effects.
- [ ] Implement preference saving on **vip-australium**, **vip-unusuals** and **vip-paints** so selected user effects are applied whenever the user re-joins the server. This would nullify the player from opening the menus again each map change to re-apply said preferences.
- [ ] Fix Unusual Effects (custom or legit) not being kept after applying a custom paint effect, could probably be permanently fixed when the merge is applied.
- [x] **ONLY FIXED ON ``vip-unusuals``** Refresh handles upon re-loading to prevent plugin failing on late-load (reload, refresh or unload and load)
- [x] Fix a **probably problematic** memory leak in **vip-unusuals**.

# Requirements

In order for these plugins to work you need the following dependencies installed on your server:
* [TF2Items](https://forums.alliedmods.net/showthread.php?t=115100)
* [TF2Attributes](https://forums.alliedmods.net/showthread.php?t=210221)
* [TF2IDB (FlaminSarge)](https://github.com/FlaminSarge/tf2idb)

For compilation you require my custom includes provided in the repository, the includes from the dependencies mentioned above and the following includes as well:
* [MoreColors](https://forums.alliedmods.net/showthread.php?t=185016)

# Plugin Pack Usage

## vip-australium
* Controls players' weapons for Australium variants, and also enables them to have special weapons such as **The Golden Frying Pan**, **The Golden Wrench** and **The Saxxy**.
* Users can open up a menu where they configurate their preferences. They **are not** saved, I may include preference saving on the next release.

Command | Description | Example
----------- | ------------- | ----------
sm_australium | Opens up the Australium weapons configuration menu. Highly customizable, not only for australium weapons but also special ones. | [YouTube Video Demonstration](https://youtu.be/b8KsEIfNUyQ?t=94)
sm_aussie | Same as the command above, just shorter. | N/A

## vip-killstreak
* Controls players' weapons for Killstreak properties. It offers a **Sheen** (if **Specialized**) and **Killstreaker** (if **Professional**) effect selector for **each individual weapon**. This means that your primary, secondary and melee may have different types of Killstreaks and also different types of effects on each of them.
* It also has an option to apply the same type and effects on every weapon. Everything is controlled by a menu.

Command | Description | Example
----------- | ------------- | ----------
sm_ks | Opens up the Killstreak configuration menu. Effects can be applied to each weapon individually, or activate a mode to set the same type, sheen and killstreaker on every weapon. | [YouTube Video Demonstration](https://youtu.be/b8KsEIfNUyQ?t=13)
sm_killstreak | Same as the command above, just longer. | N/A
sm_killstreaks | Same as the command above, just longer. | N/A

## vip-unusuals
* Controls players' cosmetics and applies selective Unusual effects on them. Works very similar to [vip-killstreak](https://github.com/punteroo/TF2-Item-Plugins/blob/production/scripting/vip-killstreak.sp) where you can select individual effects for each one of the compatible hats.
* Not every hat is able to be Unusual, for now only hats that are equipped on the ``head`` region are able to gain an Unusual effect. I may change this to only filter cosmetics that do not have the capability of being Unusual.
* If the Unusual effect is applied to a multi-class hat, the effect persists on class change.
* If the cosmetic is **painted**, then the paint is kept with the unusual effect applied. Should also work with **halloween spells**.
* There is a chance for this plugin to cause a memory leak, I've fixed it on a previous release, but in case this happens again please report it to the **Issues** page on this Git Repo.

Command | Description | Example
----------- | ------------- | ----------
sm_unu | Opens up the Unusual cosmetics configuration menu. Can be applied to multiple hats and each one with a different effect. If it doesn't show up on the list it isn't compatible. | [YouTube Video Demonstration](https://youtu.be/b8KsEIfNUyQ?t=133)
sm_unusual | Same as the command above, just longer. | N/A
sm_inusual | Same as the command above, just longer. | N/A

## vip-paints
* Lets players choose a custom paint color for their cosmetics. Only allows cosmetics with the ``paintable`` capability to be chosen.
* This plugin **does not** work in conjuction with [vip-unusuals](https://github.com/punteroo/TF2-Item-Plugins/blob/production/scripting/vip-unusuals.sp) as it deletes the Unusual effect applied on the hat to replace it with paint. I might merge these 2 plugins in order to achieve full functionality, probably in a future release.
* The paint will remove the Unusual effect present, regardless if it's from the plugin or a legit one. I'll probably fix this on a future release.
* This plugin **supports team paints**. They're applied respectively according to your team.

Command | Description | Example
----------- | ------------- | ----------
sm_paint | Opens up the cosmetic painting configuration menu. **Painting will remove Unusual effects if applied.** | [YouTube Video Demonstration](https://www.youtube.com/watch?v=vkGS_XP9HLw)

## vip-unusual-glow
* Allows players to apply one of the new 'player glow' Unusual taunt effects on them permanently.
* This plugin has reports of lowering other players' FPS due to the Unusual effect being constantly applied to the player. There is nothing I can do about this issue other than tell you to get a better PC.

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
	"Unusual Menu"					// What the player reads in the menu as an option.
	{
		"command"		"sm_unu"		// The command that is executed for the player.
	}
	"Killstreak Menu"
	{
		"command"		"sm_killstreak"
	}
	"Australium & Special Weapons Menu"
	{
		"command"		"sm_aussie"
	}
	"Unusual Glow Menu"
	{
		"command"		"sm_unuglow"
	}
	"Hat Paints Menu"
	{
		"command"		"sm_paint"
	}
}
```

Command | Description | Example
----------- | ------------- | ----------
sm_vipmenu | Opens up the VIP menu. Everything is controlled and modified from the configuration file. | N/A
sm_vip | Alias for the main command. | N/A
sm_donor | Alias for the main command. | N/A
sm_donator | Alias for the main command. | N/A
