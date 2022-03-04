Ry Mod for Quake: Scourge of Armagon  
====================================  

This mod makes miscellaneous changes to Armagon Cooperative and Deathmatch in Quake Remaster. Various quality of life, rebalancing, and bug fixes.

QuakeC Changes
---------------------------
=== General ===  
-Deathmatch: Weapons have a 5 second respawn time (except for Mjolnir which is 30).  
-Deathmatch: Recollecting a weapon you already have will give you a small amount of ammo.  
-Deathmatch: Collecting a new weapon via backpack in Deathmatch will guarantee a minimum amount of ammo for that weapon is given.  
-Deathmatch: Implemented Ring Out mechanics; If you were recently damaged by another player, dying to non-player damage will count as a frag for the player that last hurt you.  
-[NEW] Deathmatch: If a player activates a func_door entity (such as for traps, like the cage crushers in DM2), and that door kills someone on its first movement, it counts as that player's frag.  
-Deathmatch: Implemented frag notifications, which will appear in the top-middle of your screen when you get a frag. Fragging additional players while the message remains up will show how many players you've killed in a row (Double Kill, Triple Kill, etc) to an extent.  
-Deathmatch: Almost all one-time triggers, buttons, and (damagable) doors should automatically activate when starting a map, to help with navigating campaign maps  
-Deathmatch: Items that are close to respawning will have a ghost of the item appear.  
-[NEW] Deathmatch: The number of available bodies for dead players that have respawned has been doubled from 4 to 8.  
-Co-op: Dying and respawning will keep all the weapons you found in the level, but your HP and armor are reset to default, and you only carry a small amount of the ammo you were carrying before, including 25 guaranteed shells. The kept ammo is taken away from the backpack you'd drop, so it is possible you may not drop a backpack if your ammo is low enough. Your dropped backpacks also no longer include a weapon because of this.  
-Co-op: Dropped player backpacks are now protected, distinguished by a glowing aura. Any other player who walks over the backpack will only collect up to a small amount of ammo, similar to the respawn ammo counts. These backpacks will also try to teleport up to safety if they fall into slime or lava (or off the edge in HIPDM1).  
-Co-op: Players will only collect up to the ammo and weapons they need from backpacks in general.  
-Co-op: If you fail to collect your own dropped backpack before the level ends, the ammo contained will automatically be returned to you.  
-Co-op: Every weapon, ammo, health, and armor item is able to be picked up by every player. The latter three will demote to a smaller version each time a player picks them, if they aren't already the smallest. Each item will turn transparent when either every active player has collected the item, or a player who already has the item is standing over it.  
-Co-op: Deferred spawning is now used when all Co-op spawn points are occupied, preventing telefrag-fests on map start if there's more than 4 players.  
-Co-op: Players will be given any weapons they're missing when they first spawn in in a level, whether from a level transition or when (re)connecting.  
-Co-op: Added `impulse 20` from Dissolution, which throws a backpack containing an amount of your current ammo for sharing with allies.  
-Co-op: You no longer earn frags from killing other players in Co-op, whether it's via friendly fire or telefrag.  
-[NEW] Co-op: The mod announcement message now only ever appears one time for each client on join, no longer showing up every subsequent map. This can't be done for Deathmatch, as you always return to lobby between maps there.  
-Powerups are now dropped on death; The respawn time for the Quad Damage and Empathy Shields have been increased to 2 minutes to account for this.  
-Quad Damage and Pentagram powerup items now innately glow.  
-Obituaries for projectile weapons are now based on the actual projectile instead of the weapon the attacking player was holding at the time of the victim's death.  
-Obituaries now better handle falling and liquid deaths. Your "deathtype" was never reset if you survived fall damage, so the falling death message could come up when dying in certain other ways. Liquids now also use deathtype, so you don't always get liquid obituaries while touching any amount of liquid.  
-Obituaries now account for remaster bots switching weapons before the recoil finishes, tracking which weapon was last fired instead of the current weapon (was mainly a problem with Mjolnir).  
-[NEW] The name of the player (and charmed monsters) you're looking at now shows up on the HUD when there aren't other messages showing. Internally, I now intercept every centerprint call, and give each one a different priority.   
-Implemented Remaster ID1's deferred spawning, for when all of the spawn points in Deathmatch are clogged up.  
-Adjusted (original) Nightmare so enemies only have a 50% chance to fire again instantly. There you go, unpredictability.  
-You can now drop a backpack when suiciding (using "kill") in Co-op/Deathmatch. There is a cooldown to suiciding in Deathmatch to prevent backpack drop spam.  
-Picking up weapon and ammo items will no longer reset your weapon's firing animation. Affects all weapons, but also fixes a bug where the Mjolnir's attack animation would get interrupted.  
-Enemies will no longer get stun-locked if multiple players are firing rapid-fire weapons at one.  
-The messages for bots connecting and disconnecting now indicate that it's a bot.  
-Fixed up player pain sounds so you won't play slime/lava pain sounds from non-slime/lava sources unless you're submerged, you won't play slime/drowning pain sounds at all while in the Biosuit (similarly won't play drowning sounds with the Wetsuit), and Axe pain sounds should no longer get "stored" for the next time you get damaged if for some reason the sound doesn't play.  
-You can no longer suicide during intermission to respawn on the map.  

=== Remaster Mechanics ===  
-Deathmatch spawns are semi-random and will attempt to not spawn in sight of other players (as opposed to just spawning in spawn point order).  
-Players under the effect of Quad or Pentagram will be lit up with the appropriate color (Pentagram takes priority).  
-Killing enemies in Co-op gives you frags.  
-You cannot harm other players in Co-op if Friendly Fire is turned off.  
-Death Knight flames and Ogre grenades have a faint glow (the latter wasn't actually implemented for remaster hipnotic).  
-[UPDATED] Beating HIPEND will give the credits screen in SP, or go back to the Start map in Co-op.  

=== Armagon-specific ===  
-Footstep sounds are enabled by default (they used to require `crosshair 2`, which is no longer a command in Remaster), and are on a sound channel that doesn't clash with powerup pickup sounds.  
-Deathmatch: Weapon and ammo items will no longer switch you off of Mjolnir if it's usable.  
-Deathmatch: Discharging when you have the Wetsuit now counts for the Discharge achievement.  
-Deathmatch: Discharging with the Mjolnir gives the discharge message, and can give the achievement if conditions are met.  
-Mjolnir will no longer target allies with Friendly Fire disabled.  
-Mjolnir now deals double damage against monsters, bringing the damage up to 400 max for the 15 cells you spend.  
-Mjolnir is now less effective against a player with the Ring of Shadows, requiring them to be closer to hit.  
-Mjolnir will now discharge in shallow (ankle-deep) water. Before you could use it in shallow water, but the bolts were blocked by the surface of the water anyways.  
-Proximity Bombs you've fired now glow when you have Quad Damage.  
-A Proxy Bomb dislodged by a Grenade will now properly collide with the world and re-plant itself.  
-[NEW] Proximity Bombs no longer react to players using the Ring of Shadows (They will still detonate if collided with directly).  
-[NEW] Fixed a vanilla hipnotic bug where discharging in water and not gibbing would soft-lock the player in a dead state.  
-The Megahealth rotting and respawn are now handled with a separate entity in multiplayer, that way bots in DM don't keep trying to recollect it while it's yet to respawn.  
-Empathy Shields buffed. You now always take half damage even if it's your own damage, and monsters take full damage back.  
-The random spawns for the Horn of Conjuring no longer include the Rottweiler and Zombie, leaving only the Ogre, Fiend, and rare chance of Shambler. Note that some maps have specific spawns set, which this will not affect.  
-Shield of Empathy and Horn of Conjuring now have the same hitbox height as other powerups.  
-Enemies charmed by the Horn of Conjuring in Co-op will never retaliate against players who hurt them; Before, only the charmer was exempt from this.  
-Centroids will no longer try and dodge absolutely every projectile that comes their way (the egregious example being nails); There's now a delay between dodges, which was originally intended by the code, but not properly implemented.  
-Centroids will now dodge in the direction they have the most space to move in.  
-Gremlins will now pick up weapon items they come across (as well as ammo if they're in need of it), holding the item hostage until the Gremlin is killed.  
-Gremlins in Nightmare difficulty will no longer pick fights with other monsters if they have a gun, will steal weapons more often, and on stealing a gun will switch the player down to the Shotgun (or Axe if no shells).  
-Gremlins now know how to switch weapons if they have multiple weapons, and will put away their weapon once their foe is killed instead of tossing the weapon aside.  
-Gremlins that steal the Thunderbolt will no longer discharge in ankle-deep water.  
-If a Gremlin gets "stuck" while doing the backflip death, they'll gib instead of repeating the animation.  
-[NEW] Fixed a vanilla bug where a Gremlin gorging on a dead player will keep damaging the player if they respawn, improperly bringing the player's HP under 0 and putting the player in a zombie state where they can't respawn.  
-[NEW] Gremlins can now gorge on the bodies ("bodyque") left behind by respawned players, and will change over to the body seamlessly if the player respawns when the Gremlin is trying to gorge on the player.  
-Spike Mines now properly slow down when the player is looking at them. It was incorrectly implemented, instead checking if the mine was looking at the player, which effectively made it random since it constantly spins around.  
-Armagon's health now scales to the player count in Co-op, giving him an additional 50% HP per extra player. For example: Hard which normally has 3500 HP, will be 8750 HP with 4 players.  
-The cutscene Ranger used in the ending cutscene will no longer react to damage. Before it was possible to leave Proxy Bombs before the ending cutscene started to damage cutscene Ranger, who would then get angry at the player and effectively lock up the cutscene.  
-[UPDATED] Monsters spawned via func_spawn now use a telefrag trigger like regular enemy teleports, as to prevent the spawned monster from getting stuck in players or other monsters. However, charmed monsters called by the Horn of Conjuring will not be self-telefragged by players, and will instead delay their spawn if a player is in the way.  
-[NEW] If ID1 campaign maps are played in any mode, Wetsuits will show up instead of Biosuits when they're near water but not near slime. E3M5 is an exception which will always have Wetsuits.  
-[NEW] If ID1 campaign maps are played in SP/Co-op:  
&nbsp;&nbsp;-If you already have the Grenade Launcher at map start, the Proximity Gun will show up instead of the Grenade Launcher.  
&nbsp;&nbsp;-If you already have the Thunderbolt at map start, the Laser Cannon will show up instead of the Thunderbolt.  
&nbsp;&nbsp;-If you already have the Thunderbolt *and* Laser Cannon at map start, the Mjolnir will show up instead of the Thunderbolt.  
&nbsp;&nbsp;-Finishing an episode will immediately start the next one.  
&nbsp;&nbsp;-Beating END will bring you to the hipnotic START map.  

=== Under the Hood ===  
-Additional Gremlins created from a Gremlin spawned from the Horn of Conjuring will now also be under the charmed effect.  
-Added optional auto-spawning mechanics to func_spawn, which will trigger after X amount of time with an optional message, and can trigger additional entities when it does so.  
-Armagon himself is now properly spawnable via func_spawn.  
-[UPDATED] The Horn of Conjuring should now mostly work in Deathmatch. The charmed monster (spawned from func_spawn) will now go after other players, and any kills they get will add to your score. The Horn will only start the respawn countdown when all monsters it summoned have been killed, and the bodies of previously-spawned monsters will be removed on collecting the Horn again.  
-Added a "Busy" mechanic, where an enemy performing an attack will wait until the attack is finished before changing target to whoever hurt them. Currently only implemented for Armagon.  

Known problems:  
-Bots in Deathmatch will shoot at monsters they've summoned via the Horn of Conjuring. This requires an engine fix.  
-If the player has dynamic shadows enabled, the light indicating Quad Damage on Proxy Bombs won't show up correctly.  
-[NEW] Apparently if a player leaves and rejoins in the same map, the player name display will just show them as "Player", which is my fallback for when they have no name.  
-[NEW] Having the Horn of Conjuring in a Deathmatch map (particularly with Gremlins) can leave a lot of extra blank entities around as the match goes on, which I tried to fix, but it caused other problems. It doesn't *seem* to affect networking, but may cause problems in extended matches.  

Map Changes
---------------------------
START - Command HQ  
-Added an intermission camera position for use with deferred spawning in Co-op. (Previously-existing intermission cameras only appeared in Deathmatch)  

HIP1M1 - The Pumping Station  
-Deathmatch: Fixed a spawn point that was in a wall.  

[NEW] HIP1M3 - The Lost Mine  
-SP/Co-op: Added a Yellow Armor before the rock tumbler at the end. This armor will infinitely respawn in Co-op, as before, if players failed to get through the first time (or died to the enforcers afterwards), they'd have to try again with only 100 health, which generally took a lot of attempts.  

HIP1M4 - Research Facility  
-The two elevators on the map now automatically return to the lower floor and have a slight delay before moving, to make them more intuitive, and work better with bots. They also now play sounds properly instead of using a separate func_door outside the map.  
-Deathmatch: Fixed a spawn point that was too close to a wall.  
-Deathmatch: More evenly distributed the weapons:  
&nbsp;&nbsp;-Laser Cannon from the ledge above map start moved to the Silver Key room.  
&nbsp;&nbsp;-Proximity Gun from the front entrance moved to the middle of the upper floor.  
&nbsp;&nbsp;-Super Nailgun moved within the entry room so it's more in the way.  
&nbsp;&nbsp;-Thunderbolt moved slightly so it's in the middle of the grating.  

HIP2M2 - The Black Cathedral  
-Deathmatch: Added a 2nd Laser Cannon near the staircase leading to the very top room.  
-Deathmatch: Added a Mjolnir on top of the support beam across from the one with the Megahealth in the starting room; Can be accessed by doing a slope jump off the entry gate (or rocket jumping).  

HIP2M3 - The Catacombs  
-It's now possible to slope jump on top of the ending casket without hitting the end trigger; In Deathmatch this makes it possible to get to the Red Armor from below without a rocket jump  
-Deathmatch: Fixed a spawn point that was in a ceiling  
-Deathmatch: Added a 2nd Double-barreled Shotgun to the casket room in Deathmatch  

[NEW] HIP2M5 - Mortum's Keep  
-SP/Co-op: Added the Thunderbolt to the penultimate room, because otherwise your only Cells option on a cold start is the secret Mjolnir.  
-Added additional ammo items to the level, as before, ammo got a bit tight in a couple spots, especially at the end.  
-Added a 25 health item right before the door to the final area. This health item will respawn in Singleplayer, to ensure you have a means of survival against the tesla coils if you're at super low HP.  

HIP3M3 - Limbo  
-The button that reveals the Mjolnir is now only shootable the one time, so it'll be properly auto-triggered in Deathmatch  
-Deathmatch: Fixed the spawn flags on a couple 25 health items that are supposed to be replaced by 15 healths in Deathmatch, located in the hallway bend where you can open and drop through a grate to get to the water area  

HIP3M4 - The Gauntlet  
-[NEW] SP/Co-op: The bars that trap players in the crusher trap room will no longer retract if a player (or monster) gets in the way on initially closing. This fixes a softlock in Co-op, where when the trap finishes, the bars would permanantly toggle into a closed state, preventing respawned players from advancing.  
-[NEW] SP/Co-op: Upon pressing the button in the room beyond the silver door, a shortcut teleporter will open up near the start of the map for players that respawn in Co-op.  
-Deathmatch: Fixed a spawn point that was in the floor  
-Deathmatch: Swapped the positions of the Laser Cannon and Mjolnir  
-Deathmatch: Added a 2nd Double Shotgun to the bloody section in the room before the blood dive near the end  
-Deathmatch: The 3 buttons and counter for the trap door in the spike wall room no longer spawn in Deathmatch; They weren't accessible, but my Deathmatch auto-triggering would activate them.  
-[NEW] The swinging doors at the end of the map will now keep trying to open if a player sneaks in and blocks one of them, instead of having that wing of the door shut indefinitely.  

HIPEND - Armagon's Lair  
-Deathmatch: Removed the moving platform and invisible wind tunnel, to make way for *him*.  
-Deathmatch: Quad Damage and Pentagram removed from the portal above the map; The 100 Health and Red Armor remain.  

[NEW] DM1 - Place of Two Deaths  
-Added a Horn of Conjuring to 2 of the more open rooms, both of which spawn 2 Gremlins each; one toting a Nailgun, and one toting a Double Shotgun.  
-Promoted most of the Shell and Nail ammo items to big versions.  

[NEW] DM2 - Claustrophobopolis  
-Proximity Gun added to room near the shallow water; Nailgun moved to the path above.  
-Mjolnir added to ledge above bridge button; Nearby rocket ammo pack removed.  
-Empathy Shields added to lava pit trap room, which levitates so it won't fall in.  
-Added a custom trigger that allows deaths to the lava pit to be attributed to the player who opened it up. Relatedly, via the mod itself, deaths to the crushers in the cages are attributed to whoever pressed the button outside.  

[NEW] DM3 - The Abandoned Base  
-Proximity Gun added to the winding Red Armor room, partway up.  
-Laser Cannon replaces the Thunderbolt.  
-Mjolnir added to the room overlooking the outdoor Pentagram area.  
-Wetsuit added to the upper part of the water room.  
-Empathy Shields added to the Super Nailgun room.  

[NEW] DM4 - The Bad Place  
-Proximity Gun added to the middle T bridge above lava.  
-Laser Cannon added to the upper teleporter room.  
-Empathy Shields added to the lower floor of the Yellow Armor room.  

[NEW] DM5 - The Cistern  
-3 rocket ammo items added to the map.  
-Proximity Gun in the Grenade Launcher spot, with the GL being moved to the path above.  
-Laser Cannon replaces the Thunderbolt.  
-Mjolnir in the Rocket Launcher spot, with the RL being moved to the bridge above the switch.  
-Wetsuit added to the Yellow Armor room.  
-Empathy Shields replaces the Pentagram.  

[NEW] DM6  The Dark Zone  
-Proximity Gun added on upper ring section where the Grenade Launcher is; Grenade Launcher moved slightly in the same area.  
-Laser Cannon added to teleport room where the Super Nailgun is; Super Nailgun and Green Armor moved down the path.  
-Mjolnir added above the teleporter in the middle.  
-Empathy Shields replace the Ring of Shadows.  
-Added 2 new large nail items, and changed the existing 2 to also be large.  

[NEW] DM7 - The Edge  
-Proximity Gun added on top of one of the stacks of crates in the crate room; Bot nav has been adjusted to be able to reach this.  
-Laser Cannon added to the grassy outside area.  
-Mjolnir added to the middle of the cylindrical outdoor area.  

[NEW] DM8 - Acrophobia
-Proximity Gun added to the water at the bottom of the middle structure.  
-Laser Cannon added to the walkway on the 2nd floor of the structure in the middle.  
-Wetsuit added in front of the windtunnel on the 1st floor that leads to the 2nd floor.  
-Empathy Shields replace the Pentagram.  

[NEW] E2M3 - The Crypt of Decay  
-Deathmatch: The spike shooters now only fire the EM shooters instead of both EM and H.  
-Deathmatch: Removed a wall that blocks off the bridge near the gold key door when a certain trigger is hit.  

[NEW] E4M8 - The Nameless City  
-A certain teleport trigger that causes a crash no longer appears.  

[NEW] END - Shub-Niggurath's Pit  
-SP/Co-op: Laser Cannon added to the room after the lava portal, to the left when coming in.  
-Deathmatch: Fixed a spawn point that was in a wall.  
-Deathmatch: Laser Cannon added to the main path on the outside, between the Grenade Launcher and Super Nailgun.  
-Deathmatch: Proximity Gun added to a new platform in the lava, near the Quad Damage; Bot nav has been adjusted to be able to reach this.  
-All non-player teleporters on the map now no longer make the portal sound.  

Other Changes
---------------------------
-`quake.rc`: Now loads `hipnotic.cfg` after the autoexec in your root rerelease folder, to allow for setting up armagon-specific commands/aliases. This only happens locally, and will not affect clients.  
-`bots/interactables.txt`: Now accounts for door entities being renamed, allowing door-based elevators to be used by bots.  
-`bots/weapons.txt`: Mjolnir is no longer flagged as a melee weapon, as to stop bots from trying to fight Mjolnir users with the Axe.  

Remaster Bot Navs
---------------------------
To be able to select these ingame from the menu when setting a minimum player count, you need a modified `mapdb.json` that has the individual maps marked off as compatible with bots. I'd recommend getting a pak editor, and making your own pak containing a modified `mapdb.json` in ID1 to enable bot usage on whatever maps. Alternatively, if you're just playing by yourself or with friends, you can use `addbot` in the console to add as many bots as you'd like, and `kickbot` to remove bots if necessary.

Here are the bot navs currently included in this repository, as well as some notes about them:

HIP1M2 - Storage Facility  
-Bots will not interact with the switch that opens the path to the secret exit (where the Ring of Shadows is), but can take the path if someone else opens it while the bot is in the area.  
-Untested without auto-activation.  

HIP1M4 - Research Facility  
-Bots don't know how to use the elevators on the unmodified version of the map, as they're *very* bot unfriendly. Not recommended for use without the modified maps.  
-Untested without auto-activation.  

HIP1M5 - Military Complex  
-Bots won't take the underwater tunnel between the Wetsuit/Thunderbolt and the Ring of Shadows, since bots don't understand how to fight against the turbine's suction.  

HIP2M1 - Ancient Worlds  
-There's a couple jumps the bots can have difficulty with.  
-Bots don't know they can destroy the X-shaped beams in front of the Empathy Shields, but can access it if a player destroys the beams.  

HIP2M2 - The Black Cathedral  
-Bots can't access the Mjolnir on the modified map.  

HIP2M3 - The Catacombs  

HIP2M4 - The Crypt  
-Bots can't access the super-secret Megahealth in the lava area.  

HIP3M3 - Limbo  
-Due to the 3-floor elevator setup, bots will only use the elevator if it's on the top or bottom floor to get to the middle floor. They can also drop down the shaft if the platform isn't in the way.  

HIP3M4 - The Gauntlet  
-Bots aren't set up to ride the big elevator up, since the wind tunnel up is easier, faster, and less likely to get them killed (since bots stand still on elevators). They can drop down the shaft or ride it down if necessary though.  

HIPEND - Armagon's Lair  
-Sometimes bots will wait for the elevators, which is the thing that's most likely to get them killed on this map.  
-There is setup for the bots getting on the middle platform in the unmodified version of the map, but I can't make them rocket jump up into the portal, so they have no reason to do this.  

