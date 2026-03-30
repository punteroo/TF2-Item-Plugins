<h1 align="center">Team Fortress 2 - Item Management Plugins</h1>

A 2024 refresh rewrite for plugins that manage player cosmetics & weapons, along with a provisory **VIP system** menu for servers to use.

> I no longer have the means nor interest to keep this plugin kit alive. I no longer play this game and wish to keep it that way.
> If someone wishes to maintain this project I suggest forking it. Thank you!

## TOS & `m_bValidatedAttachedEntity`

Some months ago I started developing private plugins for communities that modify items for the game. It **IS AGAINST TOS**, and I know this can't be released on **AlliedModders** because of such, but because **VALVe** doesn't care for their game and it's been 7 years since a token ban has been issued I'll be releasing these public.

As **NiagaraDryGuy/404** said once:
```
It technically is against the TOS, and using something like it could have potentially gotten your server blacklisted about 8-9 years ago. Nowadays, not so much. Many community servers in existence are using this system.

For example, Skial uses it for their "!items" system that allows you to equip any weapon or cosmetic you want (even rare ones like the Wiki Cap, Top Notch, Golden Wrench, Golden Frying Pan, etc) and they're visible to other players. What has changed in the past 8-9 years is that Valve is now more focused on CS:GO and Half Life: Alyx.

TF2 servers have not suffered any GLST token bans in many years. Even CS:GO servers, which were frequently hit by GLST token bans for using fake knife/gun/etc skin plugins, have slowly over time stopped being hit by GLST token bans. It seems Valve has either lightened up on former community "restrictions", or they're too busy with HL:A to notice. lmao nevermind, seems they just banned the GLST tokens of someone in our community who was generating them en masse. Be careful if you choose to use this fucker as Valve could rear their heads towards Team Fortress 2 next. Especially be careful if you're a group like Skial that abuses this netprop.

Basically, by using this plugin, you are acknowledging that there is still the possibility that Valve could come around one day and blacklist your server. Don't blame me if such a thing happens either.
```
[source](https://github.com/delux-internal/TF2ServersidePlayerAttachmentFixer/blob/034847e92814dc879b0829bd4072924857cb17dd/README.md)

I might make some other releases if people want things fixed or whatever. I just release them because keeping them private is worthless, they're already everywhere and even some other devs have made their own versions of this public as well.
Feel free to use these plugins wherever you want.

**This plugin makes use of the ``m_bValidatedAttachedEntity`` networked property, which bypasses the restriction made by VALVe where fake items are invisible to others. Everyone on the server will be able to see your items with these plugins.**

## Pre-requisites

The plugins depend on the following extensions/plugins to be installed **and be working** on your server:
* [TF2Items (1.6.4-279)](https://forums.alliedmods.net/showthread.php?t=115100)
* [TF2Attributes](https://github.com/FlaminSarge/tf2attributes)
* [TFEconData](https://github.com/nosoop/SM-TFEconData)
* [SteamWorks](https://users.alliedmods.net/~kyles/builds/SteamWorks/)
* [SMJansson](https://forums.alliedmods.net/showthread.php?t=184604)

**Only for devs**: For compilation you require my custom includes provided in the repository, the includes from the dependencies mentioned above and the following includes as well:
* [MoreColors](https://forums.alliedmods.net/showthread.php?t=185016)

## Installation

**Read before asking or creating an issue**. You first need to install the requirements, for this read all the articles inside the [Requirements](https://github.com/punteroo/TF2-Item-Plugins#requirements) section (links) and install them independently following their tutorials, then head over to the [Releases](https://github.com/punteroo/TF2-Item-Plugins/releases) section in this repository and download the latest one.

To enable **preference saving** which is a feature that comes with the plugin pack, add this entry in your `addons/sourcemod/configs/databases.cfg` file for your server:
```
"tf2itemplugins_db"
{
    "driver"		"sqlite"
    "host"			"localhost"
    "database"		"tf2itemplugins_db"
    "user"			"root"
    "pass"			""
}
```

If you have installed the requirements correctly, and made sure they run on your server as expected, you can now proceed to do the following:
1. Download the latest release from [**right here**](https://github.com/punteroo/TF2-Item-Plugins/releases/latest).
2. Unpack both `.smx` files from the `plugins` folder inside into your `tf/sourcemod/plugins` server folder.
3. Restart your server.

**Be warned**: Loading/reloading these plugins manually via server console could cause issues. **YOU HAVE BEEN WARNED**.

Do not use the provided `gamedata` in this repository's source code, as it could be outdated in regards to the original repository.

## ConVars
### `tf2itemplugin_weapons`
- `tf2items_weapons_spawnonly`: Controls if weapon changes can only be made within spawn areas. Defaults to `0.0` (allow anywhere).
- `tf2items_weapons_paintkits_url`: An URL with a raw JSON file that holds all paint kits in the game along their names. If you want to use your own, make sure your server replies with the raw content and follows the schema. By default this is set to my provided file. **I am not responsible if War Paint options don't load when you change this.**
- `tf2items_weapons_search_timeout`: Amount of time in seconds to allow players to look up War Paint names before re-enabling them to chat. Defaults to `20.0` seconds.
- `tf2items_weapons_database_cooldown`: Amount of time in seconds a player must wait after perfoming a database operation (saving/loading/deleting preferences). Defaults to `15.0` seconds.

### `tf2itemplugin_cosmetics`
- `tf2items_cosmetics_spawn_only`: Same as weapons, but for cosmetics. Defaults to `0.0` (allow anywhere).
- `tf2items_cosmetics_unusuals_url`: An URL with a raw JSON file that holds all Unusual effects in the game currently along their names. If you want to use your own, make sure your server replies with the raw content and follows the schema. By default this is set to my provided file. **I am not responsible if Unusual options don't load when you change this.**
- `tf2items_cosmetics_search_timeout`: Same as weapons, but for when searching Unusual effects. Defaults to `15.0` seconds.
- `tf2items_cosmetics_database_cooldown`: Same as weapons, but for cosmetic preferences.
