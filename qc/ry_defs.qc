//Definitions added by Ryason55


//Ry: Values for custom centerprint stuff
float	CPRINT_NONE  = 0;
float	CPRINT_NAME  = 1;
float	CPRINT_WORLD = 2;
float	CPRINT_MOTD  = 3;
float	CPRINT_FRAG  = 4;

//World flags that modify game behavior
float RY_FL_DISABLE_FOOTSTEPS = 1;
float RY_FL_DISABLE_GREMITEMSTEAL = 2;
float RY_FL_DISABLE_HIPREBALANCE = 4;
float RY_FL_DISABLE_WIDELIGHTNING = 8;
float RY_FL_DISABLE_WIDESPIKES = 16;
float RY_FL_PREFERID1WEPS = 512;
float RY_FL_EXITWARP = 1024;
//float RY_FL_DEBUGSPAWNS = 4096;

float grem_itemstealallowed;
float hip_rebalance;
float exitwarp;
float wide_lightning;
float wide_spikes;
float debugspawns; //Ry: For debugging spawn points in Deathmatch

vector default_view_ofs = '0 0 22';

entity entity_null;

float playerindexinuse; //Ry: To track player indexes in use
float highestplayerindex; //Ry: Highest player index

float mapstartweapons; //Ry: For giving the weapons everyone else has in Co-op

float	enemy_vis, enemy_infront, enemy_range; //Ry: Defined here now instead of in fight.qc
float	enemy_yaw;

float use_new_cprint;

.float  lastimpulse; //Ry: The last impulse a player issued
.float  lastimpulsetime; //Ry: The last time a player issued an impulse command
.float  checkdirection; //Ry: For trigger_monsterjump, to ensure the monster is moving the same general direction as the trigger
.float  spawnhostile; //Ry: For func_spawn; Makes a spawned monster angry at the player that triggered the spawn
.string altmap;



// ===============
//   Player Defs
// ===============

float modelindex_eyes, modelindex_player, modelindex_hammer; //Ry: Moved from player.qc, so they're global now

.entity		invincible_item; //Ry: For dropping powerups
.entity		invisible_item;
.entity		super_item;
.entity		radsuit_item;
.float		invincible_validdroptime; //Ry: In case *somehow* the players manage to make a powerup last longer than the respawn time
.float		invisible_validdroptime;
.float		super_validdroptime;
.float		radsuit_validdroptime;

.float    megarot_count;
.float    megarot_time;

.entity		empathy_item, wetsuit_item; //Ry: Hipnotic-specific powerups
.float		empathy_validdroptime, wetsuit_validdroptime;

.float    lastfragtime; //Ry: Last time player got a frag
.float    fragcombo; //Ry: Frags in quick succession
.float    lastspawntime; //Ry: Time that the player last spawned
.float    justrespawned; //Ry: When a client just respawned
.float    firstspawn; //Ry: First time player has spawned in the map, for giving additional weapons in Co-op
.float    spawn_deferred; //Ry: Remaster spawn stuff

.float    lastdamagetime; //Ry: Time when player was last damaged
.entity   lastdamager; //Ry: Player entity that last damaged this player

.float    lastsafecheck; //Ry: Last time safe vect was checked
.vector   lastsafevect; //Ry: Safe place for backpack to warp to

.float    lastfiredweapon; //Ry: To better track what bots are firing, since they switch weapons faster than their recoil

.float    lastcenterprinttype; //Ry: For custom centerprint handler
.float    lastcenterprinttime;
.entity   lastprobedplayer;
.float    lastprobetime;

.float    bossdamage; //Ry: Amount of damage player has dealt to the current boss

.float    mapsfinished; //Ry: How many maps the player has been around for the completion of
.float    playerprobe; //Ry: Whether or not the player has opted in to seeing other player's names (Thanks Update 3)

.entity   desiredspawnpoint; //Ry: Where the player should spawn on the next frame
.float    stolenitems; //Ry: Items that were stolen from this player, such as by Gremlins

.float    charmedmonsters; //Ry: Number of monsters this player currently has charmed


// ================
//   Monster Defs
// ================

.float    lastfoetime; //Ry: Records last time foe was assigned
.float    busy; //Ry: Enemy will not change targets while this is set
.entity   nextenemy; //Ry: Enemy to target after attack is finished
.float    navcooldowntime; //Ry: For when a monster using nav runs into something
.entity   customtarget; //Ry: For Charmed and Gremlin AI
.vector   effectiveorigin; //Ry: Spawn point, accounting for being teleported in from a spawn box

// =============
//   Item Defs
// =============

.vector		pickorigin;	// Spot to return to when respawning after having been dropped
.float		remaintime;	// Amount of time left on the powerup if it was dropped
.float    nextspawntime; //Next time the powerup should spawn
.float    itemeffect; //Light effect on item
.float    delayspawn; //Delay before spawning in Deathmatch
.float    static; //Item does not drop to the ground
.float    pickers; //Track which player indexes have already collected the item
.float    playerindex; //Identifier for items
.string   enttype; //Used for easily searching items
.float    displaced; //Item was displaced by a Gremlin
.float    respawntimesp, respawntimecoop, respawntimedm, respawntime; //So respawn time can be overwritten
#ifndef ENGINE_WINQUAKE
  .float    alpha; //Transparency
#endif



#ifdef GAME_HIPNOTIC
  // =================
  //   Hipnotic Defs
  // =================

  entity horn_item; //Ry: Which horn is being used

  float     NumGremlins; //Ry: These are global now
  float     NumSpawnGremlins;

  .float    proxyimmunetime; //Ry: Time in which Proxy bombs won't react to players, for spawning and teleporting
  .float    mjolnirdisable; //Ry: If Mjolnir's electrical attack is disabled

  float hipnoticmap; //Ry: Whether or not map has hipnotic entities on it
  float hip_entconverttime;
  float hip_weaponconverttime;

  //monster_gremlin
  //.float    stealitem; //Gremlin is after an item
  .float    isspawnee; //To keep track of extra spawned Gremlins
  .float    gremstate; //New gremlin state holder for "stoleweapon", "gorging", and "stealitem"; Used for some other entities as well to determine Gremlin interactions

  float GREM_DEFAULT = 0;
  float GREM_GORGING = 1;
  float GREM_STEALITEM = 2;
  float GREM_ARMED = 3;
  float GREM_ARMEDRETREAT = 4;

  //func_spawn
  float     initspawner; //Set when a func_spawn is spawning an entity
  .float    spawnmovetype;
  .float    autospawndelay;  //Ry: New auto spawn time for func_spawn
  .string   prespawnmessage; //Ry: Message when entity is close to auto-spawning
  .string   spawnmessage;    //Ry: Message when entity is auto-spawned
  .entity   lastspawnee;     //Ry: Last spawned entity

  //monster_armagon
  .entity   conjoinedentity; //For Armagon's torso, instead of using trigger_field

  vector	VEC_HULL_ARMAGON_MIN = '-48 -48 -24';
  vector	VEC_HULL_ARMAGON_MAX = '48 48 84';
#endif



// =================
//   Remaster Defs
// =================

.float monstersize;

float campaign_valid;
float campaign;
float cheats_allowed;

float ach_weaponfired, ach_damagetaken; //Ry: Global versions of ID1 Remaster achievements

.float  allowPathFind; // Ry: Whether a monster can use Remaster AI pathing at all

// Combat style
.float 	combat_style;
float   CS_NONE 		   = 0; // default - used for bosses or other monsters that don't move
float 	CS_RANGED		   = 1;
float 	CS_MELEE		   = 2;
float 	CS_MIXED		   = 3; // can do ranged or melee equally.
float 	CS_MIXED_ABOVE = 4; // Ry: Similar to above, but is alright with being higher up

// team numbers for Coop
float TEAM_MONSTERS		= 0;
float TEAM_HUMANS		= 1;

// mal: basic colors - based on the Quake color palette.
float COLOR_RED			= 251;
float COLOR_GREEN		= 184;
float COLOR_BLUE		= 208;
float COLOR_YELLOW		= 192;
float COLOR_WHITE		= 254;
float COLOR_BLACK		= 0;
float COLOR_CYAN		= 244;
float COLOR_ORANGE		= 95;

float DRAW_AI_SINGLE_FRAME		= .1; // mal: use for AI that think every 10th of a second
float DRAW_GAME_SINGLE_FRAME	= -1; // mal: use in game code that updates every frame.

// player expanded settings flags
float PEF_CHANGEONLYNEW	= 1;
float PEF_CHANGENEVER   = 2;

// mal: codes that the QuakeC built-ins "bot_movetopoint" and "bot_followentity" will return each time they're called
float BOT_GOAL_ERROR 		= 0;	// can't do this goal for some reason.
float BOT_GOAL_SUCCESS 		= 1;	// goal as requested is complete.
float BOT_GOAL_IN_PROGRESS 	= 2;	// goal is in progress

// mal: codes that the QuakeC built-in "walkpathtogoal" will return each time it's called
float PATH_ERROR 			= 0;	// something bad happened ( no nav nodes, no nearby nodes, no path, etc. ).
float PATH_REACHED_GOAL 	= 1;	// reached whatever we were trying to get to.
float PATH_REACHED_PATH_END = 2;	// reached the end of the path - can now move directly to target.
float PATH_MOVE_BLOCKED 	= 3;	// something ( or someone ) is in our way.
float PATH_IN_PROGRESS 		= 4;	// path was found, and we're following it.

float IDEAL_DIST_FROM_DM_SPAWN_POINT    = 384;
float MIN_DIST_FROM_DM_SPAWN_POINT    = 84;
float MIN_DIST_FROM_HORDE_SPAWN_POINT = 72;

// Yoder add, September 9 2020
const float COOP_ONLY = 32768; // yoder add, Jan 16 2021; Only spawn in coop. Used by items and monsters
const float COOP_SPAWN_ACTIVE = 73;

const float NOT_IN_COOP = 131072;
#define INHIBIT_COOP if(coop && self.spawnflags & NOT_IN_COOP) {remove(self); return;}


// ==============
//   Horde Defs
// ==============

float horde;
.float hybridhordemap; //Ry: For campaign maps that can also be used as horde maps. Enables the following flags:
.float hordeflags;

float HORDEFLAG_HORDEONLY    = 1;
float HORDEFLAG_HORDEENABLE  = 2;
float HORDEFLAG_HORDEDISABLE = 4;


const float WORLDTYPE_MEDIEVAL = 0;
const float WORLDTYPE_METAL = 1;
const float WORLDTYPE_BASE = 2;
const float WORLDTYPE_HUB = 3;
.float		worldtype;

float startingserverflags;
float reset_flag;


//
// horde.qc stuff
//
// Yoder, September 24 2021, merging Horde back into mg1 code
.float is_frozen; // defines whether an entity is frozen
float	FADETIME = 5; // STATIC GLOBAL, how long after death until monsters fade out

float DEFAULT_POWERUP_CHANCE = 0.025;
float POWERUP_CHANCE_GAIN = 0.025;
float powerup_chance;

entity horde_ent; // global horde manager so code can reference without lookup
void() remote_wavecheck; // trigger wavecheck from outside the base entity

float keys_silver; // number of silver keys the players are carrying
float keys_gold; // number of gold keys the players are carrying

.float killtime; // game time at which player got their last killed
.float killspree; // player's current killing spree
float KILLSPREE_GAP = 2; // amount of time that can lapse for a kill to no longer count as part of a spree

.string category; // to do find operations by type
string CATEGORY_MONSTER = "monster";

.vector old_velocity;

float MONSTER_IGNORE_DAMAGE_LAVA = 1;
float MONSTER_IGNORE_DAMAGE_SLIME = 2;

.float aggro_time; // when a monster is aggro'd, set this value to the time. Future aggro's check against this.
float AGGRO_MIN = 1; // how long to wait before allowing a new Aggro
float AGGRO_ADD = 1; // random additional wait

float HORDE_START_DELAY = 10; // how long to wait before starting
float HORDE_AMMO_RESPAWN_DELAY = 20; // how long between horde ammo spawns
//float horde;
.float hunger_time;
float HUNGER_MAX = 10; // max delay between hunger pangs
float HUNGER_MIN = 2.5; // min delay between hunger pangs

.float axe_hit_chain; // number of consecutive axe hits
.float axe_hit_chain_time; // time of last axe hit + combo time
float AXE_COMBO_TIME = 0.7; // max time before combo resets

// AY Dec15 2021, moving from item_runes to defs since these get used by horde now
float SIGIL_E1 = 1;
float SIGIL_E2 = 2;
float SIGIL_E3 = 4;
float SIGIL_E4 = 8;
float SIGIL_E5 = 16;
float SIGIL_E6 = 32;
float SIGIL_NUMBITS = 6;