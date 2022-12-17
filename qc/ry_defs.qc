//Definitions added by Ryason55

//Ry: Mod name for MOTD messages (Doesn't include prompts; See rogue_teamplay.qc for those)
#ifdef GAME_HIPNOTIC
  string THISMOD = "Armagon Ry-vitalized V3.0";
#elifdef GAME_ROGUE
  string THISMOD = "Dissolution Ry-vitalized V3.0";
#else
  string THISMOD = "Quake Ry-vitalized V3.0";
#endif

//Ry: Values for custom centerprint stuff
float	CPRINT_NONE     = 0;
float	CPRINT_NAME     = 1;
float	CPRINT_WORLD    = 2;
float	CPRINT_MOTD     = 3;
float	CPRINT_FRAG     = 4;
float	CPRINT_GAMEMODE = 5;
float CPRINT_CHOICE   = 6;

//World flags that modify game behavior
float RY_FL_DISABLE_FOOTSTEPS     =    1;
float RY_FL_DISABLE_GREMITEMSTEAL =    2;
float RY_FL_DISABLE_HIPREBALANCE  =    4;
float RY_FL_DISABLE_WIDELIGHTNING =    8;
float RY_FL_DISABLE_WIDESPIKES    =   16;
float RY_FL_FASTMONSTERS          =  128;
float RY_FL_COPPERNIGHTMARE       =  256;
float RY_FL_PREFERID1WEPS         =  512;
float RY_FL_EXITWARP              = 1024;
float RY_FL_ALWAYSGRAPPLE         = 2048;
float RY_FL_ALTPLASMA             = 4096;

float ENTTYPE_LEVEL = 0;
float ENTTYPE_MONSTER = 1;
float ENTTYPE_GAMEPLAY = 2;
float ENTTYPE_HORDE = 3;
float ENTTYPE_CTF = 4;

float TEAM_RED = 1;
float TEAM_BLUE = 2;

#ifdef ENGINE_KEX
  string SETTINGS_CVAR = "temp5";
#else
  string SETTINGS_CVAR = "temp1";
#endif

#ifdef GAME_HIPNOTIC
  float grem_itemstealallowed;
#endif
#ifdef GAME_ROGUE
  float grappleenabled;
  float altplasma;
#endif
#ifndef GAME_ID1
  float hip_rebalance;
#endif
float exitwarp;
float wide_lightning;
float wide_spikes;
float copper_nightmare;
float fastmonsters;
float debugspawns; //Ry: For debugging spawn points in Deathmatch

vector default_view_ofs = '0 0 22';

entity entity_null;

float playerindexinuse; //Ry: To track player indexes in use
float highestplayerindex; //Ry: Highest player index

float mapstartweapons; //Ry: For giving the weapons everyone else has in Co-op

float visible_distance; //Ry: From hip_defs.qc
entity damage_inflictor;


float	enemy_vis, enemy_infront, enemy_range; //Ry: Defined here now instead of in fight.qc
float	enemy_yaw;

.float  lastimpulse; //Ry: The last impulse a player issued
.float  lastimpulsetime; //Ry: The last time a player issued an impulse command
.float  checkdirection; //Ry: For trigger_monsterjump, to ensure the monster is moving the same general direction as the trigger
.float  spawnhostile; //Ry: For func_spawn; Makes a spawned monster angry at the player that triggered the spawn
.string altmap;

.float  multidmg_damage; //Ry: To better handle Shotgun multidamage, so each entity tracks the damage
.entity multidmg_next;

//Ry: To define the starting position of doors for linking, since I need to account for a different starting origin
.vector start_mins, start_maxs;

//Ry: For setting light effects based on engine [08-22-2022]
float SET_EF_DIM = 1;
float SET_EF_QUAD = 2;
float SET_EF_PENTA = 3;
float SET_EF_CANDLE = 4;

#ifndef GAME_ID1
  //Ry: For automated entity replacements
  float missionpackmap;
  float replacetime_ents;
  #ifdef GAME_HIPNOTIC
    float replacetime_weapons;
  #endif
#endif

.float motd_time;
.float motd_count;
#if defined(ENGINE_KEX) || defined(GAME_ROGUE)
  .float motd_cmd;
#endif
float motd_priority;

//Ry: New spawn flags for entities in Horde/CTF
.float ryspawnflags;

float RYSPAWNFLAG_HORDEONLY    =  1;
float RYSPAWNFLAG_HORDEENABLE  =  2;
float RYSPAWNFLAG_HORDEDISABLE =  4;
#ifdef GAME_ROGUE
  float RYSPAWNFLAG_CTFONLY      =  8;
  float RYSPAWNFLAG_CTFEXCLUDE   = 16;
#endif


// ======
//  SUBS
// ======

//Ry: In horde.qc
vector(entity monster, vector org, string class) LoadMonster;

void(entity player, float type, string message1, string message2 = "", string message3 = "", string message4 = "", string message5 = "", string message6 = "") FilteredCenterPrint;
void(entity ent, float effecttype, float state) SetLightEffect;
float(entity ent, float val) AttackRecoil;

float PromptSupported();
void() MOTD;

void(entity attacker, float damage) SUB_Null_Pain = {};

#ifdef GAME_ROGUE
  void(entity player) SendTeamplayValue;
#endif


// ============
//  ITEM NAMES
// ============

//Ry: God, they included "the" in the translation strings for the ID1/Rogue weapons and powerups
//  This was going to be for setting translation strings when compiled for Remaster, but ehhhhhh
/*#ifdef ENGINE_KEX

#else
  string  NAME_AXE                  = "Axe";
  string  NAME_SHOTGUN              = "Shotgun";
  string  NAME_SUPER_SHOTGUN        = "Double-barreled Shotgun";
  string  NAME_NAILGUN              = "Nailgun";
  string  NAME_SUPER_NAILGUN        = "Super Nailgun";
  string  NAME_GRENADE_LAUNCHER     = "Grenade Launcher";
  string  NAME_ROCKET_LAUNCHER      = "Rocket Launcher";
  string  NAME_LIGHTING             = "Thunderbolt";
  
  string  NAME_SHELLS				        = "shells";
  string  NAME_NAILS				        = "nails";
  string  NAME_ROCKETS				      = "rockets";
  string  NAME_CELLS				        = "cells";

  string  NAME_INVISIBILITY			    = "Ring of Shadows";
  string  NAME_INVULNERABILITY		  = "Pentagram of Protection";
  string  NAME_SUIT					        = "Biosuit";
  string  NAME_QUAD					        = "Quad Damage";
  
  #ifdef GAME_HIPNOTIC
    string  NAME_PROXIMITY_GUN      = "Proximity Gun";
    string  NAME_LASER_CANNON       = "Laser Cannon";
    string  NAME_MJOLNIR            = "Mjolnir";

    string  NAME_WETSUIT            = "Wetsuit";
    string  NAME_EMPATHY_SHIELDS    = "Empathy Shields";
    string  NAME_HORN_OF_CONJURING  = "Horn of Conjuring";
  #endif
#endif*/


// ===============
//   Player Defs
// ===============

float modelindex_eyes; //Ry: Moved from player.qc, so they're global now
float modelindex_player;
#ifdef GAME_HIPNOTIC
  float modelindex_hammer;
#endif

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

#ifdef GAME_HIPNOTIC
  .entity		empathy_item, wetsuit_item; //Ry: Hipnotic-specific powerups
  .float		empathy_validdroptime, wetsuit_validdroptime;
#endif

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

.float    mapsfinished; //Ry: How many maps the player has been around for the completion of

#ifdef GAME_HIPNOTIC
  .float    bossdamage; //Ry: Amount of damage player has dealt to the current boss
  .float    stolenitems; //Ry: Items that were stolen from this player, such as by Gremlins
  .float    charmedmonsters; //Ry: Number of monsters this player currently has charmed
#endif

.entity   currentdummymodel; //Ry: For placing models
.float    placegridsnap;

float    ammocap_rockets; //Ry: Settable ammo caps for rockets
#ifdef GAME_ROGUE
  .float    lavagunfired; //Ry: If the player is firing a lava nailgun, for the cooldown sound
  float    ammocap_lava, ammocap_multi, ammocap_plasma; //Ry: Settable ammo caps for alt ammos
#endif


// ================
//   Monster Defs
// ================

.float    lastfoetime; //Ry: Records last time foe was assigned
.float    busy; //Ry: Enemy will not change targets while this is set
.entity   nextenemy; //Ry: Enemy to target after attack is finished
.entity   customtarget; //Ry: For Charmed and Gremlin AI
.vector   effectiveorigin; //Ry: Spawn point, accounting for being teleported in from a spawn box
.float    gib_health; //Ry: Health value required to gib the monster [07-31-2022]
.float    important; //Ry: Entity is treated similarly to a player [08-08-2022]
.float    lastframe; //Ry: Last frame this monster has played; Used for Fast Monsters [09-05-2022]
.float    nodamagereact; //Ry: Damage interactions with this monster won't draw aggro either way

#ifdef ENGINE_KEX
  float     USEPATH_NO = 0;
  float     USEPATH_ALLOW = 1;
  float     USEPATH_ALWAYS = 2;

  .float    allowPathFind; // Ry: Whether a monster can use Remaster AI pathing at all; If set to 2, will always use pathing [08-01-2022]
  .float    navcooldowntime; //Ry: For when a monster using nav runs into something
#endif

#ifndef GAME_ID1
  //Ry: Some func_spawn fields, but I'm also using them for replacement stuff
  .string     spawnclassname;
  .entity     spawnmaster;
  .float      spawnsilent;
#endif

// =============
//   Item Defs
// =============

float     WEAPON_BIG2 = 1; //Ry: From items.qc

float     PICK_FULL = 1; //Ry: Flags used when picking backpacks [07-23-2022]
float     PICK_LEAVE = 2;
float     PICK_TAKENFROM = 4;

.vector		pickorigin;	// Spot to return to when respawning after having been dropped
.float		remaintime;	// Amount of time left on the powerup if it was dropped
.float    nextspawntime; //Next time the powerup should spawn
.float    itemeffect; //Light effect on item, using the SET_EF_ constants [08-22-2022]
.float    delayspawn; //Delay before spawning in Deathmatch
.float    static; //Item does not drop to the ground
.float    pickers; //Track which player indexes have already collected the item
.float    playerindex; //Identifier for items
.float    displaced; //Item was displaced by a Gremlin
.float    respawntimesp, respawntimecoop, respawntimedm, respawntime; //So respawn time can be overwritten
#ifndef ENGINE_WINQUAKE
  .float    alpha; //Transparency
#endif
.float    oneperplayer; //For powerups


#ifdef GAME_HIPNOTIC
  // =================
  //   Hipnotic Defs
  // =================

  entity horn_item; //Ry: Which horn is being used

  float     NumGremlins; //Ry: These are global now
  float     NumSpawnGremlins;

  .float    proxyimmunetime; //Ry: Time in which Proxy bombs won't react to players, for spawning and teleporting
  .float    mjolnirdisable; //Ry: If Mjolnir's electrical attack is disabled

  //float hipnoticmap; //Ry: Whether or not map has hipnotic entities on it
  //float hip_entconverttime;
  //float hip_weaponconverttime;

  //monster_gremlin
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


#ifdef GAME_ROGUE
  // ============
  //  Rogue defs
  // ============
  
  float gameconfig;
  float dmatchtag;

  //Ry: Current state of the player's Grappling Hook
  .float  hookstatus;
  float   HOOK_READY    = 0;
  float   HOOK_RELEASED = 1;
  float   HOOK_FIRED    = 2;
  float   HOOK_ATTACHED = 3;
  
  .float  teamchangecooldown;
  .float  desireteamchangetime;
  
#endif


// =================
//   Remaster Defs
// =================

.float monstersize;

#ifndef ENGINE_WINQUAKE
  float campaign_valid;
  float campaign;
  float cheats_allowed;
#endif

float ach_weaponfired, ach_damagetaken; //Ry: Global versions of ID1 Remaster achievements

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

//Ry: These are to be set on the horde_manager
.string hordeboss_squadname; //Ry: Name of the squad to spawn
.string hordeboss_message; //Ry: Warning message at wave start
.float  hordeboss_slots; //Ry: How many boss monster slots are taken up
.float  hordeboss_spawntype; //Ry: What spawn point type should this squad use ("HORDE_SQUAD_TYPE_" constants, plus 1)
#ifdef GAME_HIPNOTIC
  .float allowspikemine; //Ry: If set, Spike Mines are allowed to spawn
#endif

float teamwipetime; //Ry: All players have been defeated


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

void() GibMonster;
float() HordeGetPlayersAlive;