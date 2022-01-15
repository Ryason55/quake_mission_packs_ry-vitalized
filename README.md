====================================
Ry Mod for Quake: Scourge of Armagon
====================================

This mod makes miscellaneous changes to Armagon Cooperative and Deathmatch in Quake Remaster. Various quality of life, rebalancing, and bug fixes.

=== General ===
-Deathmatch: Weapons have a 5 second respawn time (except for Mjolnir which is 30)
-Deathmatch: Recollecting a weapon you already have will give you a small amount of ammo
-Deathmatch: Collecting a new weapon via backpack in Deathmatch will guarantee a minimum amount of ammo for that weapon is given
-Deathmatch: Implemented Ring Out mechanics; If you were recently damaged by another player, dying to non-player damage will count as a frag for the player that last hurt you
-Deathmatch: Implemented frag notifications, which will appear in the top-middle of your screen when you get a frag. Fragging additional players while the message remains up will show how many players you've killed in a row (Double Kill, Triple Kill, etc) to an extent.
-Deathmatch: Almost all one-time triggers, buttons, and (damagable) doors should automatically activate when starting a map, to help with navigating campaign maps
-Deathmatch: Items that are close to respawning will have a ghost of the item appear.
-Powerups are now dropped on death; The respawn time for the Quad Damage and Empathy Shields have been increased to 2 minutes to account for this.
-Quad Damage and Pentagram powerup items now innately glow
-Obituaries for projectile weapons are now based on the actual projectile instead of the weapon the attacking player was holding at the time of the victim's death
-Obituaries now better handle falling and liquid deaths. Your "deathtype" was never reset if you survived fall damage, so the falling death message could come up when dying in certain other ways. Liquids now also use deathtype, so you don't always get liquid obituaries while touching any amount of liquid.
-Implemented Remaster ID1's deferred spawning, for when all of the spawn points in Deathmatch are clogged up
-Adjusted (original) Nightmare so enemies only have a 50% chance to fire again instantly. There you go, unpredictability.
-You can now drop a backpack when suiciding (using "kill") in Co-op/Deathmatch. There is a cooldown to suiciding in Deathmatch to prevent backpack drop spam.
-Picking up weapon and ammo items will no longer reset your weapon's firing animation. Affects all weapons, but also fixes a bug where the Mjolnir's attack animation would get interrupted.
-Enemies will no longer get stun-locked if multiple players are firing rapid-fire weapons at one.
-Co-op mechanics reworked:
 -Dying and respawning will keep all the weapons you found in the level, but your HP and armor are reset to default, and you only carry a small amount of the ammo you were carrying before, including 25 guaranteed shells. The kept ammo is taken away from the backpack you'd drop, so it is possible you may not drop a backpack if your ammo is low enough. Your dropped backpacks also no longer include a weapon because of this.
 -Dropped player backpacks are now protected, distinguished by a glowing aura. Any other player who walks over the backpack will only collect up to a small amount of ammo, similar to the respawn ammo counts. These backpacks will also try to teleport up to safety if they fall into slime or lava (or off the edge in HIPDM1).
 -Players will only collect up to the ammo and weapons they need from backpacks in general.
 -If you fail to collect your own dropped backpack before the level ends, the ammo contained will automatically be returned to you.
 -Every weapon, ammo, health, and armor item is able to be picked up by every player. The latter three will demote to a smaller version each time a player picks them, if they aren't already the smallest. Each item will turn transparent when either every active player has collected the item, or a player who already has the item is standing over it.
 -Deferred spawning is now used when all Co-op spawn points are occupied, preventing telefrag-fests on map start if there's more than 4 players.
 -Players will be given any weapons they're missing when they first spawn in in a level, whether from a level transition or when (re)connecting.
 -Added `impulse 20` from Dissolution, which throws a backpack containing an amount of your current ammo for sharing with allies.
-The messages for bots connecting and disconnecting now indicate that it's a bot.
-You no longer earn frags from killing other players in Co-op, whether it's via friendly fire or telefrag.
-Fixed up player pain sounds so you won't play slime/lava pain sounds from non-slime/lava sources unless you're submerged, you won't play slime/drowning pain sounds at all while in the Biosuit (similarly won't play drowning sounds with the Wetsuit), and Axe pain sounds should no longer get "stored" for the next time you get damaged if for some reason the sound doesn't play.
-You can no longer suicide during intermission to respawn on the map.

=== Remaster Mechanics ===
-Deathmatch spawns are semi-random and will attempt to not spawn in sight of other players (as opposed to just spawning in spawn point order)
-Players under the effect of Quad or Pentagram will be lit up with the appropriate color (Pentagram takes priority)
-Killing enemies in Co-op gives you frags
-You cannot harm other players in Co-op if Friendly Fire is turned off
-Death Knight flames and Ogre grenades have a faint glow (the latter wasn't actually implemented for remaster hipnotic)
-Beating END or HIPEND will give the credits screen in SP, or go back to the Start map in Co-op

=== Armagon-specific ===
-Footstep sounds are enabled by default (they used to require `crosshair 2`, which is no longer a command in Remaster), and are on a sound channel that doesn't clash with powerup pickup sounds
-Deathmatch: Weapon and ammo items will no longer switch you off of Mjolnir if it's usable
-Deathmatch: Discharging when you have the Wetsuit now counts for the Discharge achievement
-Deathmatch: Discharging with the Mjolnir gives the discharge message, and can give the achievement if conditions are met
-Mjolnir will no longer target allies with Friendly Fire disabled
-Mjolnir now deals double damage against monsters, bringing the damage up to 400 max for the 15 cells you spend.
-Mjolnir is now less effective against a player with the Ring of Shadows, requiring them to be closer to hit
-Mjolnir will now discharge in shallow (ankle-deep) water. Before you could use it in shallow water, but the bolts were blocked by the surface of the water anyways.
-Proximity Bombs you've fired now glow when you have Quad Damage
-A Proxy Bomb dislodged by a Grenade will now properly collide with the world and re-plant itself
-The Megahealth rotting and respawn are now handled with a separate entity in multiplayer, that way bots in DM don't keep trying to recollect it while it's yet to respawn
-Empathy Shields buffed. You now always take half damage even if it's your own damage, and monsters take full damage back.
-The random spawns for the Horn of Conjuring no longer include the Rottweiler and Zombie, leaving only the Ogre, Fiend, and rare chance of Shambler. Note that some maps have specific spawns set, which this will not affect.
-Shield of Empathy and Horn of Conjuring now have the same hitbox height as other powerups
-Enemies charmed by the Horn of Conjuring in Co-op will never retaliate against players who hurt them; Before, only the charmer was exempt from this
-Centroids will no longer try and dodge absolutely every projectile that comes their way (the egregious example being nails); There's now a delay between dodges, which was originally intended by the code, but not properly implemented
-Centroids will now dodge in the direction they have the most space to move in
-Gremlins will now pick up weapon items they come across (as well as ammo if they're in need of it), holding the item hostage until the Gremlin is killed.
-Gremlins in Nightmare difficulty will no longer pick fights with other monsters if they have a gun, will steal weapons more often, and on stealing a gun will switch the player down to the Shotgun (or Axe if no shells).
-Gremlins now know how to switch weapons if they have multiple weapons, and will put away their weapon once their foe is killed instead of tossing the weapon aside
-Gremlins that steal the Thunderbolt will no longer discharge in ankle-deep water.
-If a Gremlin gets "stuck" while doing the backflip death, they'll gib instead of repeating the animation
-Spike Mines now properly slow down when the player is looking at them. It was incorrectly implemented, instead checking if the mine was looking at the player, which effectively made it random since it constantly spins around.
-Armagon's health now scales to the player count in Co-op, giving him an additional 50% HP per extra player. (Example: Hard which normally has 3500 HP, will be 8750 HP with 4 players)
-If ID1 maps are played in Co-op, finishing an episode will start the next one.
-The cutscene Ranger used in the ending cutscene will no longer react to damage. Before it was possible to leave Proxy Bombs before the ending cutscene started to damage cutscene Ranger, who would then get angry at the player and effectively lock up the cutscene.

=== Under the Hood ===
-Additional Gremlins created from a Gremlin spawned from the Horn of Conjuring will now also be under the charmed effect
-Added optional auto-spawning mechanics to func_spawn, which will trigger after X amount of time with an optional message, and can trigger additional entities when it does so.
-Armagon himself is now properly spawnable via func_spawn
-Did some work getting the Horn of Conjuring to work in Deathmatch. The charmed monster (spawned from func_spawn) will now go after other players, and any kills they get will add to your score.
-Added a "Busy" mechanic, where an enemy performing an attack will wait until the attack is finished before changing target to whoever hurt them. Currently only implemented for Armagon.


Known problems:
-A monster spawned with func_spawn (such as from Horn of Conjuring) has no telefrag interaction, meaning it can get stuck in another living entity on spawn (Vanilla bug)
-Bots in Deathmatch will shoot at monsters they've summoned via the Horn of Conjuring (Currently not in any DM maps)
-A bot replacing a player in a full (8 player) server in Deathmatch won't see other players/bots for some reason. The bot can be kicked with `kickbot` to bring in a bot that'll work.
