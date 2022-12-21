Armagon Ry-vitalized & Dissolution Ry-vitalized  
====================================  

This mod implements a lot of quality of life, rebalancing, and bug fixes into Quake Mission Pack 1: Scourge of Armagon and Quake Mission Pack 2: Dissolution of Eternity, with changes applied to both campaign play and Deathmatch. Also some fun things thrown in here and there. The goal overall has been to keep the changes server-side, so that clients without the mod can join without issue. Originally made for use with the Quake Remaster, but I have made a version that works with Quakespasm.  

Highlights:  
-Improved Hipnotic weapons and powerups for campaign play.  
-Bug fixes and adjustments for Hipnotic monsters, as well as for a lot of previously existing mechanics.  
-Adjustments made to certain maps, to try and improve campaign and/or Deathmatch play.  
-Ability to play ID1 maps with the new changes and some Mission Pack content.  
-Quality-of-life improvements for Cooperative play, including joining with the weapons everyone else has, keeping new weapons after death, and all players being able to collect all weapon, ammo, health, and armor items.  
-Some modern features for Deathmatch play, including centered kill notifications and Ring Outs.  
-Navigation files for all Hipnotic maps that didn't have them before, allowing Deathmatch play with the bots in Remaster on all Hipnotic maps.  
-:new: Ability to play Dissolution's Capture the Flag and Deathmatch Tag modes in Remaster.  
-:new: Horde mode support, with a small number of maps set up to work with it.  


QuakeC Changes
---------------------------

----- General -----  
-All Hipnotic maps now have bot navs; See the `Remaster Bot Navs` section at the bottom for more info.  
-When playing Co-op or Deathmatch, a message will show up for each player announcing the mod name and current mode. Where appropriate, it will also show the difficulty, friendly fire status, and some other notable settings.  
-Implemented a name display for players (and charmed monsters) that will tell you their name and alliance. Note that for this to show up, the `Alternate Typeface` accessibility option must be disabled.  
-When connecting to a game running the mod, if the client has stuffcmd allowed, the game will run the alias `RyModJoin` on the client. This alias can be set up to do whatever on the client end. Do remember that in Remaster, only one impulse command in an alias will work.  

----- Gameplay -----  
-[SoA] Footstep sounds are enabled by default (they used to require `crosshair 2`, which is no longer a command in Remaster), and are on a sound channel that doesn't clash with powerup pickup sounds.  
-Fixed up player pain sounds so you won't play slime/lava pain sounds from non-slime/lava sources unless you're submerged, you won't play slime/drowning pain sounds at all while in the Biosuit (similarly won't play drowning sounds with the Wetsuit), and Axe pain sounds should no longer get "stored" for the next time you get damaged if for some reason the sound doesn't play.  
-[SoA] If ID1 campaign maps are played in any mode, Wetsuits will show up instead of Biosuits when they're near water but not near slime. E3M5 is an exception which will always have Wetsuits.  
-[SoA] SP/Co-op: It's possible to access the ID1 maps from the Hipnotic START map by taking a hidden teleporter near the Normal difficulty slipgate. This teleporter can only be used by Player 1 in Co-op, as to prevent a lot of flip-flopping.  
-:new: [DoE] If ID1 campaign maps are played in any mode, alternate ammo boxes can appear in place of regular ammo, more common around secrets.  
-:new: [DoE] SP/Co-op: The Episode 2 slipgate in the Rogue START map now instead leads to the ID1 campaign.  
-SP/Co-op: If ID1 campaign maps are played:  
&nbsp;&nbsp;-[SoA] A Proximity Gun will appear in place of the first Grenade Launcher you'd find.  
&nbsp;&nbsp;-[SoA] A Laser Cannon will appear in place of the first Thunderbolt you'd find.  
&nbsp;&nbsp;-[SoA] The Mjolnir will appear in place of the second Thunderbolt you'd find. The exception is if you go through E4M8, where you are guaranteed a Thunderbolt.  
&nbsp;&nbsp;-[SoA] Ogres in certain locations can be replaced with Centroids, which will drop 30 nails when killed (and not gibbed).  
&nbsp;&nbsp;-[SoA] Knights can be replaced with Gremlins.  
&nbsp;&nbsp;-:new: [DoE] Standing Knights can be replaced with Phantom Swordsmen.  
&nbsp;&nbsp;-:new: [DoE] Vores can be replaced with Wraths.  
&nbsp;&nbsp;-Finishing an episode will immediately start the next one.  
&nbsp;&nbsp;-Beating END will bring you to the mission pack's START map.  
-Deathmatch: If a player activates a func_door entity (such as for traps, like the cage crushers in DM2), and that door kills someone on its first movement, it counts as that player's frag.  
-Deathmatch: Almost all one-time triggers, buttons, and (damagable) doors should automatically activate when starting a map, to help with navigating campaign maps.  
-Implemented the swim up via jump speed fix from Copper, so that [Jump] is as fast as using [Swim Up] in the water. Also accounts for Wetsuit, and the speed is properly capped.  
-Added settable flags to modify gameplay, mainly for disabling some additions. You use these by adding up the desired values from below, and inputting them into `temp5 #` in the console. There are also alias commands you can use to toggle these settings while a map is running. Changes will take effect on the next map:  
&nbsp;&nbsp;1 = `footsteps` - [SoA] Disable Footstep sounds.  
&nbsp;&nbsp;2 = `gremitemsteal` - [SoA] Disable Gremlins being able to pick up items.  
&nbsp;&nbsp;4 = `rebalance` - Disable the (primarily SP/Co-op) Hipnotic Weapon and Powerup rebalancing; Affects Proximity Gun, Mjolnir, Empathy Shields, and Horn of Conjuring.  
&nbsp;&nbsp;8 = `widelightning` - Disable the Wide Lightning fix, where the Thunderbolt (and Shamblers) have wider bolts that can hit things to the sides a bit easier.  
&nbsp;&nbsp;16 = `widespikes` - Deathmatch: Disable Nails and Lasers having larger hitboxes against players.  
&nbsp;&nbsp;:new: 128 = `fastmonsters` - SP/Co-op: Makes monsters act at 2x speed, like Doom's Fast Monsters. Monster projectiles are 1.5x faster as well.  
&nbsp;&nbsp;:new: 256 = `coppernightmare` - SP/Co-op: Makes monsters always behave like they're on Hard difficulty, and cuts the player's max HP to 50 on Nightmare. Based on Copper's implementation of Nightmare.  
&nbsp;&nbsp;512 = `preferid1weps` - SP/Co-op: Regarding playing ID1 campaign maps, prefer getting the ID1 weapons first.  
&nbsp;&nbsp;1024 = `exitwarp` - Deathmatch: Entering the exit warps you to the start of the map. The join message will indicate if this is enabled and relevant.  
&nbsp;&nbsp;:new: 2048 = `grapple` - [DoE] Players have the Grappling Hook in all modes, no longer being restricted to CTF.  
&nbsp;&nbsp;:new: 4096 = `altplasma` - [DoE] Modifies the Plasma Gun's firing so it moreso matches up with the firing sound. Not recommended for online play.  
-Related to the previous, entering `impulse 55` into console will display which options above are enabled and relevant.  
-Non-rotating key doors now no longer innately deal damage. This fixes a problem where certain key doors could drag you into a wall or ceiling for extreme damage.  
-:new: [DoE] Lava Nail traps no longer generate on regular nail traps that have difficulty spawnflags. Relevant for Nail Traps in ID1 maps.  
-:new: [DoE] SP/Co-op: Earthquakes no longer have horizontal shaking, and just have increased bouncing.  

----- Multiplayer -----  
-Obituaries for projectile weapons are now based on the actual projectile instead of the weapon the attacking player was holding at the time of the victim's death.  
-Obituaries now better handle falling and liquid deaths. Your "deathtype" was never reset if you survived fall damage, so the falling death message could come up when dying in certain other ways. Liquids now also use deathtype, so you don't always get liquid obituaries while touching any amount of liquid.  
-Obituaries now account for remaster bots switching weapons before the recoil finishes, tracking which weapon was last fired instead of the current weapon (was mainly a problem with Mjolnir).  
-You can now drop a backpack when suiciding (using `kill`) in Co-op/Deathmatch. There is a cooldown to suiciding in Deathmatch to prevent backpack drop spam.  
-The messages for bots connecting and disconnecting now indicate that it's a bot.  
-You can no longer suicide during intermission to respawn on the map.  
-[SoA] Particle Fields should now display correctly if other clients exist on the map but aren't in sight of the Particle Field.  
-Co-op: You cannot harm other players if Friendly Fire is disabled.  
-Co-op: Dying and respawning will keep all the weapons you found in the level, but your HP and armor are reset to default, and you only carry a small amount of the ammo you were carrying before, including 25 guaranteed shells. The kept ammo is taken away from the backpack you'd drop, so it is possible you may not drop a backpack if your ammo is low enough. Your dropped backpacks also no longer include a weapon because of this.  
-Co-op: Dropped player backpacks are now protected, distinguished by a glowing aura. Any other player who walks over the backpack will only collect up to a small amount of ammo, similar to the respawn ammo counts. These backpacks will also try to teleport up to safety if they fall into slime or lava (or off the edge in HIPDM1).  
-Co-op: Players will only collect up to the ammo and weapons they need from backpacks in general.  
-Co-op: If you fail to collect your own dropped backpack before the level ends, the ammo contained will automatically be returned to you.  
-Co-op: Every weapon, ammo, health, and armor item is able to be picked up by every player. The latter three will demote to a smaller version each time a player picks them, if they aren't already the smallest. Standing over an item you've already taken will make it appear transparent. Once all active players have collected an item, it will disappear until a new player joins.  
-Co-op: Deferred spawning is now used when all Co-op spawn points are occupied, preventing telefrag-fests on map start if there's more than 4 players.  
-Co-op: Players will be given any weapons they're missing when they first spawn in in a level, whether from a level transition or when (re)connecting.  
-Co-op: Killing enemy monsters will award you frags, and you no longer earn frags for killing other players.  
-[SoA] Co-op: Added `impulse 20` from Dissolution, which throws a backpack containing an amount of your current ammo for sharing with allies.  
-Deathmatch: Implemented Ring Out mechanics; If you were recently damaged by another player, dying to non-player damage will count as a frag for the player that last hurt you.  
-Deathmatch: Implemented frag notifications, which will appear in the top-middle of your screen when you get a frag. Fragging additional players while the message remains up will show how many players you've killed in a row (Double Kill, Triple Kill, etc) to an extent.  
-Deathmatch: Player spawns are semi-random and will attempt to not spawn in sight of enemy players or monsters. You also won't spawn on spawn points obstructed by Proximity Bombs or allies.  
-Deathmatch: Implemented Remaster ID1's deferred spawning, for when all of the spawn points in Deathmatch are clogged up.  
-Deathmatch: The number of available bodies for dead players that have respawned has been doubled from 4 to 8.  
-Deathmatch: Nails and Lasers now have a larger hitbox against other players specifically. Nails from the regular Nailgun have a slightly larger hitbox than the others. Wall traps are not affected.  
-Deathmatch: Earthquakes from mission pack map events no longer cause players to shake.  
-:new: [DoE] Deathmatch: Alternate ammo types have lower ammo caps than campaign.  
-:new: [DoE] Deathmatch: Weapon pickups no longer give alternate ammo inherantly.  
-:new: [DoE] Deathmatch: Deathmatch Tag is now initiated with flag 32 in `gamecfg`, instead of `teamplay 3`.  
-:new: [DoE] Deathmatch: The Tag Token in Deathmatch Tag moves a lot smoother now.  
-:new: [DoE] Deathmatch: Various Dissolution-specific settings can be controlled through these `gamecfg` flags or aliases similarly to the `temp5` flags:  
&nbsp;&nbsp;1 = `runes` - Enables Threewave CTF-style runes.  
&nbsp;&nbsp;2 = `teamarmor` - Quakespasm only: Allows teammates to damage armor in CTF.  
&nbsp;&nbsp;4 = `teamhealth` - Quakespasm only: Allows teammates to damage health in CTF.  
&nbsp;&nbsp;16 = `autoteams` - Quakespasm only: Skip team selection and automatically assign a team.  
&nbsp;&nbsp;32 = `tag` - Remaster only: Enable Deathmatch Tag.  

----- :new: Horde Mode -----  
-Weapon items and pre-placed health/armor behave similarly to my Co-op implementation, staying around until everyone has picked them up, with the latter demoting each pick.  
-When you die, you can press Jump to spectate from fixed points.  
-When you respawn, you no longer need to re-collect the weapons on the map, and you keep a small amount of ammo.  
-A message appears on-screen when all players have died.  
-Bots can no longer click to advance to the lobby when everyone has died.  
-[SoA] Centroids can innately spawn under elite squads, including replacing Ogres during the "Army" waves.  
-[SoA] Gremlins can innately spawn under fodder and elite squads.  
-[SoA] A level can rarely include Spike Mines in the spawns by adding `allowspikemine` to the Horde Manager, and setting it to 1. They will appear on flying monster spawn points, if available.  
-[DoE] Phantom Swordsmen can innately spawn under fodder squads.  
-[DoE] Multi-Grenade Ogres and Wraths can innately spawn under boss squads.  
-Unique monsters like bosses can be set to spawn every 9th wave. The squad is set with `hordeboss_squadname`, the warning message is set with `hordeboss_message`, the number of regular boss monster slots the squad will take up is set with `hordeboss_slots`, and the spawn point type is set with `hordeboss_spawntype`.  
&nbsp;&nbsp;-[SoA] The only unique boss squad is `armagon`.  
&nbsp;&nbsp;-[DoE] Unique boss squads currently include `guardian aztec`, `guardian egypt`, `guardian greek`, and `guardian` (a random guardian). Overlord and Dragon are planned, but I'd have to make sure they work right when spawned this way.  

----- :new: [DoE] Capture the Flag -----  
-Regular CTF can now be initiated from the menu in Remaster.  
-Implemented team selection on join, similar to Remaster's Threewave CTF.  
-Scoring in CTF is now based off of captures instead of frags.  
-If teams become unbalanced, a player can elect to switch teams with `impulse 100`.  
-The Laser Cannon bind (impulse 225) now reports the score of each team.  
-The Mjolnir bind (impulse 226) now reports flag statuses.  
-The original CTF HUD (replacing Ranger's face with the team color and score) now displays correctly for clients. Note this does not display at all with Remaster's minimal HUD.  

Notes:  
-While Remaster did add a score display on the HUD and an option to switch teams in the menu when playing Threewave CTF, these changes are hardcoded to only appear in `game ctf`, and thus I can't make use of them.  

----- Items -----  
-Deathmatch: Items that are close to respawning will have a ghost of the item appear.  
-Any item pre-placed on an up/down elevator will now be attached to the elevator. This makes sure that items on an elevator will not have their hitbox shrunken via elevator movement (such as in E2M6), and fixes a bug where the Rocket Launcher on the Silver Key elevator in HIP1M5 in Deathmatch would eventually fall through the elevator with enough use.  
-Changed Megahealth rot implementation by having it handled via the player entity. In Deathmatch, it now tracks how many Megahealth items are stocked, and rots by that much every second. In SP/Co-op, the Megahealth rot is capped to 1 per second. In all modes, picking up a new Megahealth while one is already rotting will pause the rotting momentarily.  

----- Weapons (General) -----  
-Picking up weapon and ammo items will no longer reset your weapon's firing animation. Affects all weapons, but also fixes a bug where the Mjolnir's attack animation would get interrupted.  
-Fixed a vanilla Hipnotic bug where discharging in water and not gibbing would soft-lock the player in a dead state.  
-Deathmatch: Weapons have a 5 second respawn time (except for Mjolnir which is 30).  
-Deathmatch: Recollecting a weapon you already have will give you a small amount of ammo.  
-Deathmatch: Collecting a new weapon via backpack in Deathmatch will guarantee a minimum amount of ammo for that weapon is given.  
-[SoA] Reworked bullet holes so that they're set up similar to bodyques, where it's a pre-existing chain of entities.  
-Axe and Mjolnir (up until the lightning attack) swings will not alarm unaware monsters.  
-Fixed the bugs with the LightningDamage function (used by the Thunderbolt and such), where there were supposed to be additional traces to widen the area you can hit in. I have however limited the extra traces to only occur with the Thunderbolt and Shamblers. Details on the bug here: https://quake.speeddemosarchive.com/quake/misc/lbug/  
-:new: Tracelines used by the shotguns and lightning-based weapons will now no longer be blocked by dying monsters.  
-:new: Gibbing enemies with the Shotguns is now much more reliable. As well, if enough pellets hit an enemy and cause them to gib, remaining pellets are able to go past and hit things behind. This is most notable when using the Double-Barreled Shotgun with Quad Damage.  
-:new: The Discharge achievement can now be rewarded for *any* discharge kill you do that you survive, no longer strictly requiring the Pentagram.  
-:new: [SoA] With Friendly Fire off, Mjolnir lightning bolts will no longer be blocked by teammates who get in the way.  

----- [SoA] Proximity Gun -----  
-Proximity Bombs you've fired now glow when you have Quad Damage.  
-When playing Co-op or Deathmatch, Proxy Bombs will now automatically go off if they're overlapping a relevant player spawn point.  
-SP/Co-op: Proximity Bombs will no longer react to or blow up on contact with players, and will blow up after about 20 seconds reliably instead of being semi-random.  
-SP/Co-op: Proximity Bombs now deal similar damage to Grenades.  

----- [SoA] Mjolnir -----  
-Mjolnir will no longer target allies with Friendly Fire disabled.  
-Mjolnir now deals double damage against monsters, bringing the damage up to 400 max for the 15 cells you spend.  
-Deathmatch: Weapon and ammo items will no longer switch you off of Mjolnir if it's usable.  
-Deathmatch: Discharging with the Mjolnir gives the discharge message, and can give the achievement if conditions are met.  
-Mjolnir will now discharge if the attack would originate from within water. Before you could use it in shallow water, but the bolts were blocked by the surface of the water anyways.  
-Sp/Co-op: It is now possible to disable the lightning strike attack by double tapping Mjolnir's bind (impulse 226) while it's out, allowing you to use the melee function (such as instantly gibbing Zombies) without risking wasting Cells.  

----- :new: [DoE] Grappling Hook -----  
-The hook is now able to hurt monsters, should the situation arise.  
-The hook can now be aborted mid-flight if you release the fire button.  
-If you're holding jump when you release the hook, you will now do a jump. This allows you to get on top of a ledge you hooked the side of.  
-If you're hooked to a wall or enemy while using another weapon, you're able to detach by jumping.  
-If the hook breaks for any reason while holding fire with the Grapple (going through a teleporter, tried to hook a teammate, hooked enemy died, etc), you now have to release the fire button to be able to fire the hook again.  
-If you get hooked by an enemy player, as an alternative to killing them, you can also get them off by hitting them with your Axe. This is for the case where an invulnerable player grapples to a vulnerable player.  

----- :new: [DoE] Lava Nail Guns -----  
-Fixed a bug where the cooldown hiss sound of the Lava Nailguns failed to play when there's multiple players.  
-Lava Nails now glow.  
-Lava Nails no longer show the bleeding effect when used against the Hephaestus (lava monsters) from R2M3, as they're immune to lava nails.  
-If you're aiming at a Hephaestus (who is immune to Lava Nails), you no longer auto-switch to a Lava Nailgun when you, for example, run out of cells for the Thunderbolt.  

----- :new: [DoE] Multi Grenade Launcher -----  
-Player-fired Multi-Grenades now automatically split into clusters when near an enemy.  

----- :new: [DoE] Multi Rocket Launcher -----  
-The projectiles now glow in multiplayer modes as well.  

----- :new: [DoE] Plasma Gun -----  
-The weapon and Ranger now animate when firing the gun.  
-The projectile now glows in multiplayer modes as well.  

----- Powerups (General) -----  
-Powerups are now dropped on death; The respawn time for the Quad Damage and Empathy Shields have been increased to 2 minutes to account for this.  
-Quad Damage and Pentagram powerup items now innately glow.  
-Players under the effect of Quad or Pentagram will be lit up with the appropriate color (Pentagram takes priority).  
-[SoA] Shield of Empathy and Horn of Conjuring now have the same hitbox height as other powerups.  
-:new: Cooperative: Powerups used for traversal (Biosuit, Wetsuit, Anti-Grav Belt) can now be collected by every player.  

----- Ring of Shadows -----  
-[SoA] Proximity Bombs no longer react to players using the Ring of Shadows (They will still detonate if collided with directly).  
-[SoA] Mjolnir is now less effective against a player with the Ring of Shadows, requiring them to be closer to hit.  
-[SoA] Players under the effect of the Ring of Shadows no longer have footstep sounds.  
-:new: Deathmatch: Respawn time reduced to 3 minutes, down from 5 minutes.  

----- [SoA] Empathy Shields -----  
-Empathy Shields buffed. You now always take half damage even if it's your own damage, and monsters take full damage back.  

----- [SoA] Horn of Conjuring -----  
-The random spawns for the Horn of Conjuring no longer include the Rottweiler and Zombie, leaving only the Ogre, Fiend, and rare chance of Shambler. Note that some maps have specific spawns set, which this will not affect.  
-Enemies charmed by the Horn of Conjuring in Co-op will never retaliate against players who hurt them; Before, only the charmer was exempt from this.  
-The Horn of Conjuring now works in Deathmatch. The charmed monster (spawned from func_spawn) will now go after other players, and any kills they get will add to your score. The Horn will only start the respawn countdown when all monsters it summoned have been killed, and the bodies of previously-spawned monsters will be removed on collecting the Horn again.  
-Enemy monsters will now retaliate against charmed monsters of the same species.  
-If a charmed monster sees that the player that summoned them is in combat (damage is exchanged while player and foe have line-of-sight), if navigation is possible, it will get angry at the player's foe without needing to have line-of-sight with the foe itself.  
-Charmed Ogres, Knights, and Death Knights now walk at 3x speed when following their charmer.  
-SP/Co-op: Horn of Conjuring monsters no longer affect the total/killed monster counts.  
-Deathmatch: Charmed monsters no longer glow.  
-:new: Charmed monsters now also benefit from having Friendly Fire disabled in Co-op, being unable to exchange damage with players. This ensures they don't quickly die off in chaotic Co-op sessions.  
-:new: Charmed monsters now have similar telefrag priority to players.  

----- :new: [DoE] Anti-Grav Belt -----  
-Anti-Grav will not take effect unless you're holding jump, and the Anti-Grav effect is greater.  
-Even if not using the Anti-Grav effect, fall damage is negated entirely.  
-Bots will never use the Anti-Grav effect, as it messes with their regular pathing.  
-Custom gravity (such as that in E1M8) will be countered by the Anti-Grav Belt.  

----- :new: [DoE] Power Shield -----  
-Now should no longer protect against directionless damage, such as liquids and triggers. Before it would protect you, but only if you were facing world origin.  
-When it comes to moving platforms and mechanisms, the shield will now protect you from crushing damage if you're facing the offending object (again, instead of world origin), but only if the object is moving horizontally.  

----- :new: [DoE] Vengeance Sphere -----  
-The owner of the Sphere is now awarded frags for any players that die from the explosion.  
-Now has a glowing effect.  

----- Monsters (General) -----  
-Monsters will no longer get stun-locked if multiple players are firing rapid-fire weapons at one.  
-Adjusted (original) Nightmare so monsters only have a 50% chance to fire again instantly. There you go, unpredictability.  
-Monsters spawned via func_spawn now use a telefrag trigger similar to regular enemy teleports, as to prevent the spawned monster from getting stuck in players or other monsters. However, charmed monsters called by the Horn of Conjuring will not be self-telefragged by players, and will instead delay their spawn if a player is in the way.  
-Added a "Busy" mechanic, where certain monsters in the middle of an attack will not immediately turn on whoever hurts them until either after the attack, or if a pain state is triggered. Currently implemented for the Vore, Shambler, and Armagon.  
-Fixed the "statue" bug that can rarely occur in vanilla when initializing a monster.  
-Most monsters when fighting a Zombie will give up on the Zombie when it gets knocked down.  
-[SoA] Gremlins, Armagon, and any ground-based monster summoned under the effect of the Horn of Conjuring now use Remaster's bot pathing to navigate.  

----- Zombie -----  
-Zombies can now be gibbed while they're down if a sufficient explosion goes off near them.  

----- Death Knight -----  
-Death Knight flames have a faint glow.  

----- Shambler -----  
-Fixed the vanilla bug where rockets can go through Shamblers on occasion.  

----- Vore -----  
-Vore projectiles will now drop out of the air after they've chased the player for long enough.  

----- [SoA] Centroids -----  
-Centroids will no longer try and dodge absolutely every projectile that comes their way (the egregious example being nails); There's now a delay between dodges, which was originally intended by the code, but not properly implemented.  
-Centroids will now dodge in the direction they have the most space to move in.  
-:new: The Centroid will now approach the player in a zig-zag pattern. This is a behavior that previously existed and can be seen briefly when first engaging one, but the state for that gets unset on initiating any attack, and never reinstated.  
-:new: Centroid is now able to use bot pathing on spawn.  

----- [SoA] Gremlins -----  
-Gremlins will now pick up weapon items they come across (as well as ammo if they're in need of it), holding the item hostage until the Gremlin is killed.  
-Gremlins in Nightmare difficulty will no longer pick fights with other monsters if they have a gun, will steal weapons more often, and on stealing a gun will switch the player down to the Shotgun (or Axe if no shells).  
-Gremlins now know how to switch weapons if they have multiple weapons, and will put away their weapon once their foe is killed instead of tossing the weapon aside.  
-Gremlins that steal the Thunderbolt will no longer discharge in ankle-deep water.  
-If a Gremlin gets "stuck" while doing the backflip death, they'll gib instead of repeating the animation.  
-Fixed a vanilla bug where a Gremlin gorging on a dead player will keep damaging the player if they respawn, improperly bringing the player's HP under 0 and putting the player in a zombie state where they can't respawn.  
-Gremlins can now gorge on the bodies ("bodyque") left behind by respawned players, and will change over to the body seamlessly if the player respawns when the Gremlin is trying to gorge on the player.  
-Gremlins have a new trick: If one jumps at you and collides with you, it will try to steal your weapon.  
-Gremlins have a second new trick: On Normal and above, if one successfully steals your weapon, other Gremlins around you that aren't occupied will also try to steal your weapon on their next melee check. On Nightmare, the weapon you auto-switch to is now based on if there's any nearby Gremlins that are able to steal; It'll switch to your best weapon (same order as if you ran out of ammo) if other Gremlins can steal, and to your Shotgun (or Axe) if there aren't.  
-Gremlin gorging has been adjusted. Originally, the Gremlin that finished gorging a body would be healed to full, but then have their HP split between it and the newly spawned Gremlin (so always 50 HP for both). Now, Gremlins will heal slightly for every hit of a gorge (up their maximum health of 100), and the Gremlin that finishes the gorge will no longer have their HP cut.  
-Adjusted decisions around gorging corpses:  
&nbsp;&nbsp;-On Normal and above, Gremlins will avoid looking for corpses to gorge while an enemy player is looking at them, unless they're at low HP and need to heal.  
&nbsp;&nbsp;-Gremlins won't seek out corpses if the maximum number of Gremlin spawns has been reached, unless the Gremlin is in need of healing.  
&nbsp;&nbsp;-Charmed Gremlins won't go too far out of their way to gorge on corpses, and must be brought closer to a corpse.  
-Improved compatibility between Gremlins and the Horn of Conjuring. Now Gremlins following their charmer move at double walk speed like other charmed monsters, and will also seek out items they can use without needing to be in combat. Additional Gremlins created from a charmed Gremlin will also be charmed as well.  
-Charmed Gremlins are now a bit more accurate with weapons.  
-Gremlins that fall into lava will properly die, instead of continuing to function as a gib head. The check for being in lava now also occurs while walking.  
-Gremlins that pick up a Double-Barreled Shotgun item will get 20 shells to work with, instead of 5 like a player would.  
-Gremlins using a stolen Double-Barreled Shotgun will fire a single shotgun blast if they only have 1 shell remaining, just like the player.  
-Gremlins using a stolen Super Nailgun will now actually fire super nails instead of regular nails.  
-Gremlins using a stolen Grenade Launcher will fire grenades that deal player damage instead of Ogre damage, and have a firing cone, to maintain consistency with other weapons they fire. The Grenades they fire also glow, to indicate they're more dangerous.  
-Gremlins that hurt themselves with a player weapon will no longer be able to get angry at themselves.  
-Gremlins are now capable of stealing weapons from other Gremlins, should infighting occur.  
-If a Gremlin infights with a Zombie, the Gremlin will gorge on the Zombie when it gets knocked down.  
-If a Gremlin tries to steal a weapon they already have, they'll instead steal ammo so they can resume using the weapon themselves.  
-In Co-op, if a backpack contains a weapon stolen by a Gremlin, only the player who had that weapon stolen is able to collect the weapon from the backpack.  
-Improved the messages for picking up a backpack containing stolen weapons in SP/Co-op, particularly in the case where there were multiple weapons.  
-SP/Co-op: Backpacks containing stolen weapons now have safety measures similar to those employed for player backpacks in Co-op, though they will not glow.  
-SP/Co-op: Gremlins will no longer go for weapon items that are much higher up than the player. This includes the Thunderbolt in HIP2M6, and the Rocket Launcher in HIP2M4.  
-:new: When a Gremlin steals from a player (or another Gremlin), it'll play an appropriate pickup sound.  

----- [SoA] Spike Mine -----  
-Spike Mines now properly slow down when the player is looking at them. It was incorrectly implemented, instead checking if the mine was looking at the player, which effectively made it random since it constantly spins around.  
-Spike Mines now use the small collision (similar to Players, Knights, Scrags, etc). This improves the Spike Mine's maneuverability in indoor areas, as before its odd-sized box collision would be rounded up to large (Shambler-sized) collision against the world.  
-Spike Mines will now wait until the player is within view of all 8 corners of their collision before starting to move, as to avoid immediately clipping walls. It is still possible to get them to ram into walls.  
-:new: If a Spike Mine in pursuit takes damage, it'll slow down for a bit based on how much damage it took. Minimum speed is half of their base speed on that difficulty, not including the speed up when the player isn't looking. A single rocket is basically guaranteed to cut a Spike Mine's speed in half temporarily.  
-:new: Spike Mines can now follow `path_corner`s, such as the ones set up for them in HIPDM1.  

----- [SoA] Armagon -----  
-Armagon's health now scales to the player count in Co-op, giving him an additional 50% HP per extra player. For example: Hard which normally has 3500 HP, will be 8750 HP with 4 players.  
-:new: Armagon's arena now includes markers that help Armagon get around the pillars. The previously-existing setup using path_follow and path_follow2 has been removed, as it only really worked for going around the pillars in one direction.  
-:new: The side-fire attacks are now aimed better when Armagon's upper body is turned.  
-:new: Armagon will keep trying to aim at the player if he's in the middle of an attack.  
-:new: Anything caught underneath a falling Armagon will be crushed. Relevant for Deathmatch and Horde variations of HIPEND.  
-:new: Armagon now has similar telefrag priority to players.  
-:new: Armagon now acknowledges NoTarget when looking for players.  

----- :new: [DoE] Overlord -----  
-The Overlord's health now scales based on the number of players.  

----- :new: [DoE] Guardian -----  
-No longer continues to play its death sound after it disappears.  
-The Guardian's health and maximum number of adds now scale based on the number of players.  

----- :new: [DoE] Hephaestus -----  
-Now is no longer able to incite or participate in infighting. It already wouldn't fight with other monsters itself due to hackiness, but now it should be properly implemented.  
-Will now retaliate if you hurt it while you're out of sight.  
-Added a spawn flag that makes it unable to move. Yes, it does move normally.  
-No longer moves during its attack, meaning it should no longer fidget around when up against a ledge/wall.  

----- :new: [DoE] Dragon -----  
-Made it less likely for the Dragon to get caught up circling around a marker after performing a melee attack.  
-The Dragon's health now scales based on the number of players.  

----- Internal Changes -----  
-Items can be set to float and ignore placement checks if `static` is set.  
-func_spawn: Now properly handles spawning monster_armagon.  
-func_spawn: Can also accept `static` to spawn the entity in midair.  
-func_spawn: Added simple auto-spawning capabilities. If `autospawndelay` is set to a time in seconds, and the spawner has no `targetname`, it will automatically spawn the entity after the set amount of time. If `spawnmulti` is set, and it's a monster spawner, it'll restart the countdown when the monster is killed. `spawnmessage` can be set to a string to broadcast a message to all players when the spawn occurs, and `prespawnmessage` will come up 10 seconds before the spawn happens, if the spawn time is 30 or more seconds. The auto spawner will trigger entities via `target`, so you can set up multiple spawners to go off at once from the one spawner, but currently only the one monster from the base spawner is considered when it comes to restarting the countdown.  
-func_door/func_door_secret: Doors can now deal 0 damage if `dmg` is set to a negative value.  
-trigger_monsterjump: Added `checkdirection`, which makes it so monsters will only be affected by the jump if they're going roughly the same direction.  
-trigger_monsterjump: Now charmed monsters will only be affected by a monster jump if the trigger itself also has `charmed` set.  
-trigger_hurt: Can be set to only hurt players with Spawn Flag 1.  
-func_button: Can be set to require a key similarly to doors, as some Horde maps require it.  
-func_spawn: A spawned monster can be set to be angry at the player who triggered it with `spawnhostile` set.  
-:new: func_exploder: Now accepts a `count` value, which allows it to be reused a set number of times, or indefinitely.  
-:new: trigger_teleport: Now no longer calls `objerror` if it can't find a target, which fixes "crash" teleporters like the one at the start of E4M8.  
-Probably more things I've forgotten.  

Map Changes
---------------------------
[SoA] START - Command HQ  
-SP/Co-op: Added an intermission camera position for use with deferred spawning in Co-op. (Previously-existing intermission cameras only appeared in Deathmatch)  
-SP/Co-op: The hidden teleporter near the Normal difficulty slipgate from Deathmatch is now accessible, and using it will toggle the next map between being HIP1M1 and E1M1. Only the first player is allowed to use this teleporter, as to prevent flip-flopping the next map.  
-:new: SP/Co-op: Restored the lights in the light strips in the Normal difficulty passage.  

[SoA] HIP1M1 - The Pumping Station  
-Deathmatch: Fixed a spawn point that was in a wall.  
-Deathmatch: The spawn point near the wall that explodes to reveal the Wetsuit is disabled until the area is safe.  

[SoA] HIP1M2 - Storage Facility  
-Deathmatch: Removed a large rockets box from the Red Armor room.  

[SoA] HIP1M3 - The Lost Mine  
-The health items in the cubby holes at the mine entrance now properly show up.  
-SP/Co-op: Added a Yellow Armor before the rock tumbler at the end. This armor will infinitely respawn in Co-op, as before, if players failed to get through the first time (or died to the enforcers afterwards), they'd have to try again with only 100 health, which generally took a lot of attempts.  
-SP/Co-op: At the Silver Key, swapped the monster spawns between Normal and Hard. Now a Centroid appears on Normal, and a Shambler appears on Hard. Yes, it was the reverse before.  
-Deathmatch: Moved the Nailgun at the start of the level to in front of the mine entrance.  
-Deathmatch: Moved the Grenade Launcher at the start of the mine so that it isn't hidden in shadow.  
-Deathmatch: Moved the Grenade Launcher in the back area above ground so that it's more convenient to get at from below.  
-Deathmatch: Replaced the Super Nailgun that's outside with a Double-Barreled Shotgun.  
-Deathmatch: Added a Super Nailgun, Double-Barreled Shotgun, Laser Cannon, and Nailgun to the Mines. Overall less Shotgun-fighting for people who spawn in the mines.  
-Deathmatch: Added a 3rd Rocket Launcher to the crusher hallway.  
-Deathmatch: Added *many* ammo items to the map overall, particularly to the mines and ending building.  
-Deathmatch: Adjusted spawn points and teleporter exits.  
-Deathmatch: The spawn point at the bottom of the rolling rock section is disabled until the area is safe.  

[SoA] HIP1M4 - Research Facility  
-The two elevators on the map now automatically return to the lower floor and have a slight delay before moving, to make them more intuitive, and work better with bots. They also now play sounds properly instead of using a separate func_door outside the map.  
-:new: The secret door in the Silver Key room now moves into the wall instead of down when it opens, as to not clip into the room below.  
-Deathmatch: Fixed a spawn point that was too close to a wall.  
-Deathmatch: More evenly distributed the weapons:  
&nbsp;&nbsp;-Laser Cannon from the ledge above map start moved to the Silver Key room.  
&nbsp;&nbsp;-Proximity Gun from the front entrance moved to the middle of the upper floor.  
&nbsp;&nbsp;-Super Nailgun moved within the entry room so it's more in the way.  
&nbsp;&nbsp;-Thunderbolt moved slightly so it's in the middle of the grating.  
-:new: Deathmatch: Adjusted the spinning basement room to be more streamlined. Now only the two doors with teleporters open up (with the items from the other doors being distributed around the room), there's no longer a Proximity Gun (only the Grenade Launcher), and there's a 15 health item at the bottom of the shaft you drop down.  

[SoA] HIP1M5 - Military Complex  
-Deathmatch: Via the mod, the Rocket Launcher on the Silver Key elevator will no longer fall through the world after enough use.  

:new: [SoA] HIP2M1 - Ancient Worlds  
-Now playable in Horde mode with a custom layout.  
-Deathmatch: The Horn of Conjuring from campaign now appears, which will spawn a Shambler.  
-Deathmatch: Added a Double-barreled Shotgun, Nailgun, and small Nails box to the passages around the circular area.  
-Deathmatch: The destructable wood bit in in front of the Empathy Shields is now removed.  

[SoA] HIP2M2 - The Black Cathedral  
-Deathmatch: Added a 2nd Laser Cannon near the staircase leading to the very top room.  
-Deathmatch: Added a Mjolnir on top of the support beam across from the one with the Megahealth in the starting room; Can be accessed by doing a slope jump off the entry gate (or rocket jumping).  

[SoA] HIP2M3 - The Catacombs  
-It's now possible to slope jump on top of the ending casket without hitting the end trigger; In Deathmatch this makes it possible to get to the Red Armor from below without a rocket jump  
-Fixed a problem where it was possible to get stuck in the re-pressable buttons if you stood in the way of them when they unpressed.  
-The lightning traps in the basement lava area now only go off if you're in their relevant hallway, just to reduce the amount of noise.  
-Added a small box of rockets in the hallway at the bottom of the spiral staircase.  
-SP/Co-op: The Fiend on a ledge before the castle on Hard mode will now jump down and actually be a threat.  
-SP/Co-op: The Fiends in the casket room that spawn after picking up the Megahealth can now actually jump down to reach the player.  
-SP/Co-op: Added a MonsterJump trigger in the waterway just before the silver door, to allow monsters to follow you in there.  
-SP/Co-op: Adjusted the encounters in the basement lava caves leading to the gold key on Normal difficulty and up:  
&nbsp;&nbsp;-The 2nd Spike Mine that appears on Hard difficulty on entering the area now only spawns after both Ogres have been killed. Before, the two Spike mines would just immediately go off and kill both Ogres, making it easier than Normal difficulty which only has one Spike Mine there.  
&nbsp;&nbsp;-The Shamblers near the gold key will now only react to seeing or getting hurt by the player themselves.  
&nbsp;&nbsp;-Spike Mines in the gold key room have had their positions tweaked slightly.  
&nbsp;&nbsp;-:new: Added a Nailgun on the last of the rising/falling pillars in the lava area.  
-Deathmatch: Fixed a spawn point that was in a ceiling  
-Deathmatch: Added a 2nd Double-barreled Shotgun to the casket room in Deathmatch  

[SoA] HIP2M4 - The Crypt  
-SP/Co-op: The stepladder you can use to climb on the shelf on Easy difficulty (allowing you to access the Horn of Conjuring easily) now also appears on Normal difficulty.  
-SP/Co-op: The Horn of Conjuring now also spawns a Death Knight, in addition to the regular Knight.  
-SP/Co-op: Added a number of MonsterJump triggers to help monsters with the vents and areas they lead to.  
-SP/Co-op: In the Silver Key spot, the floor gate that opens up when the vent is used will now also open for monsters.  
-:new: SP/Co-op: Moved a number of Spike Mines to be less likely to unexpectedly jump the player.  

[SoA] HIP2M5 - Mortum's Keep  
-Added additional ammo items to the level, as before, ammo got a bit tight in a couple spots, especially at the end.  
-Added a 25 health item right before the door to the final area. This health item will respawn in Singleplayer, to ensure you have a means of survival against the tesla coils if you're at super low HP.  
-SP/Co-op: Added the Thunderbolt to the penultimate room, because otherwise your only Cells option on a cold start is the secret Mjolnir.  
-:new: SP/Co-op: Moved a number of Spike Mines to be less likely to unexpectedly jump the player.  
-:new: SP/Co-op: Removed the Spike Mine that spawns at the top of the stairs near the start of the level. Players were very likely to back into it when fighting enemies on the path to the Horn of Conjuring.  
-:new: SP/Co-op: The other two Spike Mines that spawn in the starting room now have different triggers.  
-Deathmatch: Adjusted all spawn point positions, including moving them to the floor, fixing an obstructed spawn point, and adding some additional spawn points.  
-Deathmatch: In the room above Pentagram, moved the Nailgun to a more obvious location that isn't obscured by shadow. Added a 2nd small Nails item nearby as well. The other Nailgun in the starting room was removed.  
-Deathmatch: Added a Laser Cannon to the top of the dark elevator room.  
-Deathmatch: Removed a large rockets box from the ending room.  

[SoA] HIP3M1 - Tur Torment  
-Fixed a problem where a section of floor in the exit room wasn't collisionable to projectiles and traces. This is a bandaid fix done via filling in the "hole" with a large trigger model converted to func_wall.  
-Deathmatch: Made the Horn of Conjuring (and relevant monster spawner) from campaign show up.  
-Deathmatch: Removed the Rocket Launcher at the end of the map near one of the teleporters. Where that teleporter leads out is pretty much a dead end as it is, which already has its own Rocket Launcher.  
-Deathmatch: Added a 2nd Double Shotgun to the double staircase room, and added additional ammo and health items past that point.  
-Deathmatch: Replaced the Nailgun at the start of the map with a Super Nailgun, moved the Nailgun far down the hallway, and increased the size of a couple ammo items in the area.  
-Deathmatch: Added custom triggers near the teleporters at the end of the map that tell you which teleporter goes where.  
-Deathmatch: The Megahealth on the ledge in the double staircase room is now always there instead of spawning in when the button is hit, so that bots will go for it innately.  

[SoA] HIP3M2 - Pandemonium  
-Deathmatch: Adjusted all spawn point positions, including moving all but 2 of them to the floor, and fixing an obstructed spawn point.  
-Deathmatch: Moved the Thunderbolt to the starting room.  
-Deathmatch: Moved the hidden Nailgun to the Thunderbolt's original spot, and put a Megahealth in its place.  
-Deathmatch: Added a large Cells box to the caged area near the start.  

[SoA] HIP3M3 - Limbo  
-The button that reveals the Mjolnir is now only shootable the one time, so it'll be properly auto-triggered in Deathmatch  
-:new: Moved the ammo items in the Mjolnir secret so that the rockets box doesn't get pushed through a wall when the door opens.  
-:new: SP/Co-op: Adjusted the paths for the 2 monsters in the starting room so they pace instead of getting stuck at the end of their path.  
-Deathmatch: Fixed the spawn flags on a couple 25 health items that are supposed to be replaced by 15 healths in Deathmatch, located in the hallway bend where you can open and drop through a grate to get to the water area  

[SoA] HIP3M4 - The Gauntlet  
-SP/Co-op: The bars that trap players in the crusher trap room will no longer retract if a player (or monster) gets in the way on initially closing. This fixes a softlock in Co-op, where when the trap finishes, the bars would permanantly toggle into a closed state, preventing respawned players from advancing.  
-SP/Co-op: Upon pressing the button in the room beyond the silver door, a shortcut teleporter will open up near the start of the map for players that respawn in Co-op.  
-Deathmatch: Fixed a spawn point that was in the floor  
-Deathmatch: Swapped the positions of the Laser Cannon and Mjolnir  
-Deathmatch: Added a 2nd Double Shotgun to the bloody section in the room before the blood dive near the end  
-Deathmatch: The 3 buttons and counter for the trap door in the spike wall room no longer spawn in Deathmatch; They weren't accessible, but my Deathmatch auto-triggering would activate them.  
-The swinging doors at the end of the map will now keep trying to open if a player sneaks in and blocks one of them, instead of having that wing of the door shut indefinitely.  

[SoA] HIPDM1 - The Edge of Oblivion  
-Adjusted Navigation to work better for charmed monsters in campaign. Also some tweaks for bots as well, such as fixing up some long stretches that bots sometimes would get hung up on briefly.  
-:new: SP/Co-op: Fixed a Spike Mine spawner that got broken in Remaster.  
-:new: SP/Co-op: Restored the explosion effect that occurs when a Spike Mine is spawned.  

[SoA] HIPEND - Armagon's Lair  
-:new: Now playable in Horde mode with a custom layout.  
-:new: Removed the path_follow and path_follow2 entities used for Armagon in favor of a new system: path_trafficmirror. These are points on the map that the monster ai (as part of the mod) will look for if they don't have a clear path to the target, allowing monsters (like Armagon) to path around a corner if there's a clear path via one of these points.  
-SP/Co-op: The cutscene Ranger used in the ending cutscene will no longer react to damage. Before it was possible to leave Proxy Bombs before the ending cutscene started to damage cutscene Ranger, who would then get angry at the player and effectively lock up the cutscene.  
-SP/Co-op: Fixed a softlock that could occur if the player kills Armagon without triggering the container. Now the trigger for the container will also react to the cutscene Ranger.  
-Deathmatch: Removed the moving platform and invisible wind tunnel, to make way for *him*.  
-Deathmatch: Quad Damage and Pentagram removed from the portal above the map; The 100 Health and Red Armor remain.  

:new: [DoE] START - Split Decision  
-SP/Co-op: The Episode 2 slipgate now instead leads to E1M1, where you can play through the base Quake campaign.  
-Deathmatch: Fixed a spawn point that was too close to a wall.  

:new: [DoE] R2M1 - Tempus Fugit  
-Added a custom layout for Horde mode.  
-The monster closet teleporters are now silent.  
-One button that was repeatably pressable despite having permanant one-time effects now can only be pressed the one time.  
-Deathmatch: Fixed an item placement where two different sizes of Lava Nails would appear in the same spot.  
-Deathmatch: Moved a spawn point away from a teleporter exit.  

:new: [DoE] R2M6 - Blood Sacrifice  
-SP/Co-op: The entity used for the lightning trap (ltrail_start) now properly accounts for there being multiple players.  

:new: [DoE] CTF1 - Division of Change  
-Map now plays music track 9, instead of no music.  
-Improved bot navigation overall.  
-Improved level symmetry by removing an Anti-Grav Belt, Ring of Shadows, and the level exit from the blue side.  
-Added a Tag Token spawn point to the map, for use in Deathmatch Tag.  

DM1 - Place of Two Deaths  
-Promoted most of the Shell and Nail ammo items to big versions.  
-:new: Added a large Nails box to the teleporter exit hallway on the upper floor.  
-[SoA] Added a Horn of Conjuring to 2 of the more open rooms, both of which spawn 2 Gremlins each; one toting a Nailgun, and one toting a Double Shotgun.  
-[SoA] Made a bunch of adjustments to the Navigation so that Gremlins have an easier time getting around. Improved sections include around the staircase from the bottom floor and the path to the Grenade Launcher. Gremlins also now know to use the teleporter if they get into the teleporter hallway.  
-[SoA] Added a MonsterJump trigger at the drop-off where the button is, so a Gremlin passing through won't drop straight into the lava and perish.  
-:new: [DoE] Added 1 box of Multi Rockets to the Double Shotgun room.  
-:new: [DoE] Replaced 2 boxes of Nails with Lava Nails.  
-:new: [DoE] Power Shield added to the open room on the upper floor.  
-:new: [DoE] Anti-Grav Belt added on top of the structure in the Double Shotgun room; Good luck getting it.  
-:new: [DoE] Vengeance Sphere added to the open room on the lower floor.  
-:new: [DoE] Added a spawn point for the Tag Token in Deathmatch Tag.  

DM2 - Claustrophobopolis  
-Added a custom trigger that allows deaths to the lava pit to be attributed to the player who opened it up. Relatedly, via the mod itself, deaths to the crushers in the cages are attributed to whoever pressed the button outside.  
-:new: Edited navigation so that bots now shouldn't just walk into the lava pit when it's open, and are now able to use the crusher buttons if the lava pit is open. Bots should also be able to get over the lava pit in the hallway with the 2 moving platforms more consistently.  
-:new: All boxes of Nails have been promoted to large boxes.  
-:new: Added 2 boxes of Shells.  
-[SoA] Proximity Gun added to room near the shallow water; Nailgun moved to the path above.  
-[SoA] Mjolnir added to ledge above bridge button; Nearby rocket ammo pack removed.  
-[SoA] Empathy Shields added to lava pit trap room, which levitates so it won't fall in.  
-:new: [DoE] Replaced 1 box of Nails with Lava Nails, and added an additional box of Lava Nails.  
-:new: [DoE] Replaced 1 box of Rockets with Multi Rockets.  
-:new: [DoE] Power Shield added to lava pit trap room, which levitates so it won't fall in.  
-:new: [DoE] Anti-Grav Belt added to the room near the shallow water.  
-:new: [DoE] Added a spawn point for the Tag Token in Deathmatch Tag.  

DM3 - The Abandoned Base  
-Added Nailguns near the Pentagram and Megahealth.  
-Moved the spawn point in the elevator section past the Pentagram yard so it's in a corner and has view of both directions you can go. There's also a short delay before players are allowed to spawn there.  
-Moved the Thunderbolt to the bottom of the Red Armor room, where it replaces the Nailgun.  
-[SoA] Proximity Gun added near the Ring of Shadows.  
-[SoA] Laser Cannon is in the Thunderbolt's original spot in the pool.  
-[SoA] Mjolnir added to the room overlooking the outdoor Pentagram area.  
-[SoA] Wetsuit added to the upper part of the water room.  
-[SoA] Empathy Shields added to the Super Nailgun room.  
-:new: [DoE] A large box of Plasma is in the Thunderbolt's original spot in the pool.  
-:new: [DoE] Replaced 3 boxes of Nails with Lava Nails.  
-:new: [DoE] Replaced 2 boxes of Rockets with Multi Rockets.  
-:new: [DoE] Added 2 boxes of Plasma.  
-:new: [DoE] Anti-Grav Belt added to the room overlooking the outdoor Pentagram area.  
-:new: [DoE] Power Shield added to the Super Nailgun room.  
-:new: [DoE] Added a spawn point for the Tag Token in Deathmatch Tag.  

DM4 - The Bad Place  
-:new: All boxes of Nails have been promoted to large boxes.  
-[SoA] Proximity Gun added to the middle T bridge above lava.  
-[SoA] Laser Cannon added to the upper teleporter room.  
-[SoA] Empathy Shields added to the lower floor of the Yellow Armor room.  
-:new: [DoE] Replaced 2 boxes of Nails with Lava Nails.  
-:new: [DoE] Replaced 1 box of Rockets with Multi Rockets.  
-:new: [DoE] Added 1 box of Plasma.  
-:new: [DoE] Power Shield added to the lower floor of the Yellow Armor room.  
-:new: [DoE] Vengeance Sphere added to the upper teleporter room.  
-:new: [DoE] Added a spawn point for the Tag Token in Deathmatch Tag.  

DM5 - The Cistern  
-3 rocket ammo items added to the map.  
-Moved the Rocket Launcher to the bridge above the switch.  
-[SoA] Proximity Gun in the Grenade Launcher spot, with the GL being moved to the path above.  
-[SoA] Laser Cannon replaces the Thunderbolt.  
-[SoA] Mjolnir in the Rocket Launcher's original spot.  
-[SoA] Wetsuit added to the Yellow Armor room.  
-[SoA] Empathy Shields replaces the Pentagram.  
-:new: [DoE] Replaced 2 boxes of Nails with Lava Nails.  
-:new: [DoE] Replaced 1 box of Rockets with Multi Rockets.  
-:new: [DoE] 2 small boxes of Plasma are where the Rocket Launcher used to be.  
-:new: [DoE] Vengeance Sphere added to the Yellow Armor room.  
-:new: [DoE] Power Shield replaces the Pentagram.  
-:new: [DoE] Added a spawn point for the Tag Token in Deathmatch Tag.  

DM6 - The Dark Zone  
-Added 2 new large nail items, and changed the existing 2 to also be large.  
-[SoA] Proximity Gun added on upper ring section where the Grenade Launcher is; Grenade Launcher moved slightly in the same area.  
-[SoA] Laser Cannon added to teleport room where the Super Nailgun is; Super Nailgun and Green Armor moved down the path.  
-[SoA] Mjolnir added above the teleporter in the middle.  
-[SoA] Empathy Shields replace the Ring of Shadows.  
-:new: [DoE] Replaced 2 boxes of Nails with Lava Nails.  
-:new: [DoE] Replaced 1 box of Rockets with Multi Rockets.  
-:new: [DoE] Added 1 box of Plasma.  
-:new: [DoE] Random Powerup replaces the Ring of Shadows. It can be a Ring of Shadows, Power Shield, or Anti-Grav Belt.  
-:new: [DoE] Vengeance Sphere added above the teleporter in the middle.  
-:new: [DoE] Added a spawn point for the Tag Token in Deathmatch Tag.  

DM7 - The Edge  
-[SoA] Proximity Gun added on top of one of the stacks of crates in the crate room; Bot nav has been adjusted to be able to reach this.  
-[SoA] Laser Cannon added to the grassy outside area.  
-[SoA] Mjolnir added to the middle of the cylindrical outdoor area.  
-:new: [DoE] Added 5 boxes of Lava Nails.  
-:new: [DoE] Added 2 boxes of Multi Rockets.  
-:new: [DoE] Added 2 boxes of Plasma.  
-:new: [DoE] 2 Anti-Grav Belts added, one in each outdoor area.  
-:new: [DoE] Added a spawn point for the Tag Token in Deathmatch Tag.  

DM8 - Acrophobia  
-:new: Added 3 boxes of Nails.  
-:new: Added 2 boxes of Shells.  
-[SoA] Proximity Gun added to the water at the bottom of the middle structure.  
-[SoA] Laser Cannon added to the walkway on the 2nd floor of the structure in the middle.  
-[SoA] Wetsuit added in front of the windtunnel on the 1st floor that leads to the 2nd floor.  
-[SoA] Empathy Shields replace the Pentagram.  
-:new: [DoE] Added 2 boxes of Lava Nails in the water.  
-:new: [DoE] Added 1 box of Multi Rockets.  
-:new: [DoE] Added 2 boxes of Plasma in the water.  
-:new: [DoE] Anti-Grav Belt added in front of the windtunnel on the 1st floor that leads to the 2nd floor.  
-:new: [DoE] Power Shield replaces the Pentagram.  
-:new: [DoE] Added a spawn point for the Tag Token in Deathmatch Tag.  

DEATH32C - Death 32  
-:new: All boxes of Nails have been promoted to large boxes.  
-[SoA] The map now plays Track 7 for the music instead of none.  
-[SoA] Added a Wetsuit in the water between DM2 and DM4.  
-:new: [DoE] The map now plays Track 4 for the music instead of none.  
-:new: [DoE] Added Lava Nails, Multi Rockets, and Plasma in similar places to the modified base maps.  
-:new: [DoE] Added a Vengeance Sphere in the water between DM2 and DM4.  
-DM2: Added a custom trigger that allows deaths to the lava pit to be attributed to the player who opened it up. Relatedly, via the mod itself, deaths to the crushers in the cages are attributed to whoever pressed the button outside.  
-:new: DM2: Added 2 boxes of Shells.  
-[SoA] DM2: Proximity Gun added to room near the shallow water; Nailgun moved to the path above.  
-[SoA] DM2: Mjolnir added to ledge above bridge button; Nearby rocket ammo pack removed.  
-[SoA] DM2: Empathy Shields added to lava pit trap room, which levitates so it won't fall in.  
-:new: [DoE] DM2: Power Shield added to lava pit trap room, which levitates so it won't fall in.  
-:new: [DoE] DM2: Anti-Grav Belt added to the room near the shallow water.  
-[SoA] DM4: Proximity Gun added to the middle T bridge above lava.  
-[SoA] DM4: Laser Cannon added to the upper teleporter room.  
-DM4: Moved the Nailgun at the bottom a bit further into the passage leading to DM6.  
-[SoA] DM6: Proximity Gun added on upper ring section where the Grenade Launcher is; Grenade Launcher moved slightly in the same area.  
-[SoA] DM6: Laser Cannon added to teleport room where the Super Nailgun is; Super Nailgun and Green Armor moved down the path.  
-[SoA] DM6: Mjolnir added above the teleporter in the middle.  
-:new: [DoE] DM6: Vengeance Sphere added above the teleporter in the middle.  
-DM6: Added 2 new large nail items, and changed the existing 2 to also be large.  
-:new: [DoE] Added a spawn point for the Tag Token in Deathmatch Tag.  

E2M3 - The Crypt of Decay  
-Deathmatch: The spike shooters now only fire the EM shooters instead of both EM and H.  
-Deathmatch: Removed a wall that blocks off the bridge near the gold key door when a certain trigger is hit.  

END - Shub-Niggurath's Pit  
-All non-player teleporters on the map now no longer make the portal sound.  
-Adjusted navigation on the map, giving the nodes on the map actual width, and noded out the start area of the map for monster use.  
-The exit trigger that's high up in the main area is now located out-of-bounds.  
-:new: Deathmatch: Added 1 box of Shells.  
-:new: Deathmatch: Added 1 box of Nails.  
-:new: [DoE] Anti-Grav Belt replaces the Quad Damage.  
-SP/Co-op: Killing Shub now increments the killed monsters count. Previously she only incremented total monsters.  
-SP/Co-op: Gave a unique death message to the hurt trigger around Shub, based off the unused kill message.  
-SP/Co-op: The hurt trigger around Shub now goes off more reliably.  
-[SoA] SP/Co-op: Laser Cannon added to the room after the lava portal, to the left when coming in.  
-[SoA] SP/Co-op: Hand-placed some Hipnotic monsters to the map.  
-:new: [DoE] SP/Co-op: Hand-placed alternate ammo types, and some Dissolution monsters.  
-Deathmatch: Fixed a spawn point that was in a wall.  
-[SoA] Deathmatch: Laser Cannon added to the main path on the outside, between the Grenade Launcher and Super Nailgun.  
-[SoA] Deathmatch: Proximity Gun added to a new platform in the lava, near the Quad Damage; Bot nav has been adjusted to be able to reach this.  
-:new: [DoE] Deathmatch: Added 2 boxes of Lava Nails.  
-:new: [DoE] Deathmatch: Added 1 box of Multi Rockets.  
-:new: [DoE] Deathmatch: Added 1 box of Plasma.  
-:new: [DoE] Deathmatch: Power Shield added to the ledge near the Super Nailgun.  
-:new: [DoE] Deathmatch: Vengeance Sphere added to a new platform in the lava, near the Anti-Grav Belt.  
-:new: [DoE] Deathmatch: Added a spawn point for the Tag Token in Deathmatch Tag.  

Local Changes
---------------------------
-When starting one of the mission packs, the game will now load an appropriate config, either `hipnotic.cfg` or `rogue.cfg` based on the mission pack. This allows you to set up mission pack-specific binds and such.  
-Bot definition files modified, accounting for new things and some fixes. Some notable things being:  
&nbsp;&nbsp;-`interactables.txt`: Now accounts for door entities being renamed, allowing door-based elevators to be used by bots.  
&nbsp;&nbsp;-[SoA] `weapons.txt`: Mjolnir is no longer flagged as a melee weapon, as to stop bots from trying to fight Mjolnir users with the Axe.  
-Integrated the fixes I did for the Mjolnir and related models. Preview and separate download can be found here:  
https://twitter.com/ryason55/status/1481166358264098816  
https://www.mediafire.com/file/d5wd846r2wa8fyc/QuakeSoA_MjolnirModelFixes_V1.0.zip/file  
-:new: Dynamic shadows are disabled for Quad, Pentagram, and various mission pack projectiles.  
-:new: [DoE] Demo1 now plays music track 2. No more immediate anxiety music.  
-:new: [DoE] Made some changes to the weapon wheel:  
&nbsp;&nbsp;-The Grappling Hook is now included in the wheel.  
&nbsp;&nbsp;-The Axe now appears selectable by default, instead of requiring the Lava Nailgun to be in your possession.  
&nbsp;&nbsp;-Selecting the Thunderbolt a 2nd time will no longer select the Plasma Gun.  

:new: Quakespasm Version Differences
---------------------------
-Features specific to Remaster's engine are stripped out, including advanced monster navigation. Notable for Horde maps.  
-`temp5` settings are handled through `temp1` instead.  
-Changes to the maps have been ported to work with the original BSP files. They are also in ENT format. Changes to END are currently excluded, due to the major differences in map structure in Deathmatch.  
-[SoA] Charmed monsters under the effect of the Horn of Conjuring now use an improved system for navigation compared to vanilla behavior, where leading a charmed monster away will leave invisible "breadcrumbs" the monster will attempt to follow. Some things to note compared to Remaster bot navigation:  
&nbsp;&nbsp;-Charmed monsters have similar movement restrictions to regular monsters. Only new thing they can do is jump off high ledges innately.  
&nbsp;&nbsp;-A charmed monster in combat will not keep track of where you went, and will default to regular monster pathing if you're not directly pathable when it resumes following you.  
&nbsp;&nbsp;-There are certainly spots where this can fail.  
-[DoE] Deathmatch: Deathmatch Tag is initiated via `teamplay 3`, as it originally was.  

Notes:  
-Currently, any changes to item spawn behavior in Deathmatch only apply to `deathmatch 3`, which needs to be set manually in the console.  
-Horde versions of maps can be accessed by setting `horde 1` in the console, and using `map ___` to start a compatible level. Note that Quakespasm doesn't unset `horde` when starting a new game from the menu.  
-Other source ports haven't been extensively tested.  

Known Issues
---------------------------
-Apparently if a player leaves and rejoins in the same map, the player name display will just show them as "Player", which is my fallback for when they have no name.  
-If a client has dynamic shadows enabled, and they don't have the mod installed themselves, mission pack-exclusive entities and projectiles that have lights will partially (if not fully) block their own light. For example, the light indicating Quad Damage on Proxy Bombs in Armagon won't show up correctly.  
-The updated Mjolnir item model doesn't rotate on some source ports like Darkplaces.  

Remaster Bot Navs
---------------------------
Included with the mod is navigation files for every Hipnotic map that hasn't already gotten navs officially, as well as a for couple Dissolution maps. The included `mapdb.json` files will allow you to select these maps with bots ingame, as long as you're playing one of the mission packs. This can be done by either playing one of the maps normally, using `game hipnotic`/`game rogue` in the console, or having `+game hipnotic`/`+game rogue` as a launch command.  

Here are the bot navs included in this repository, as well as some notes about them:  

[SoA] HIP1M2 - Storage Facility  
-Bots will not interact with the switch that opens the path to the secret exit (where the Ring of Shadows is), but can take the path if someone else opens it while the bot is in the area.  
-Untested without auto-activation.  

[SoA] HIP1M3 - The Lost Mine  

[SoA] HIP1M4 - Research Facility  
-Bots don't know how to use the elevators on the unmodified version of the map, as they're *very* bot unfriendly. Not recommended for use without the modified maps.  
-Untested without auto-activation.  

[SoA] HIP1M5 - Military Complex  
-Bots won't take the underwater tunnel between the Wetsuit/Thunderbolt and the Ring of Shadows, since bots don't understand how to fight against the turbine's suction.  

[SoA] HIP2M1 - Ancient Worlds  
-There's a couple jumps the bots can have difficulty with.  
-Bots don't know they can destroy the X-shaped beams in front of the Empathy Shields, but can access it if a player destroys the beams. Not a problem in the modified maps since I've removed those beams in Deathmatch.  

[SoA] HIP2M2 - The Black Cathedral  
-Bots can't access the Mjolnir on the modified map.  

[SoA] HIP2M3 - The Catacombs  

[SoA] HIP2M4 - The Crypt  
-Bots can't access the super-secret Megahealth in the lava area.  

[SoA] HIP2M5 - Mortum's Keep  

[SoA] HIP2M6 - The Gremlin's Domain  

[SoA] HIP3M1 - Tur Torment  
-Bots won't innately go for the Red Armor (or Grenade Launcher) in the slime, as bots currently don't understand that they should have the Biosuit before diving in. They will go after it if they end up in the slime through external means, either from getting knocked into it, or slipping and falling when trying to traverse the top of the gondola track.  

[SoA] HIP3M2 - Pandemonium  

[SoA] HIP3M3 - Limbo  
-Due to the 3-floor elevator setup, bots will only use the elevator if it's on the top or bottom floor to get to the middle floor. They can also drop down the shaft if the platform isn't in the way.  

[SoA] HIP3M4 - The Gauntlet  
-Bots aren't set up to ride the big elevator up, since the wind tunnel up is easier, faster, and less likely to get them killed (since bots stand still on elevators). They can drop down the shaft or ride it down if necessary though.  

[SoA] HIPEND - Armagon's Lair  
-Sometimes bots will wait for the elevators, which is the thing that's most likely to get them killed on this map.  
-There is setup for the bots getting on the middle platform in the unmodified version of the map, but I can't make them rocket jump up into the portal, so they have no reason to do this.  

:new: [DoE] R2M1 - Tempus Fugit  
-I had to do some trickery due to some teleporter destinations being different in the Horde version of the map. As such, the navs do expect that you're using the modified version of the map.  

:new: [DoE] R2M8 - Source of Evil  
-Bots cannot reach the Quad Damage in the upper cave in the main room, as they have no concept of what the Anti-Grav Belt does.  
