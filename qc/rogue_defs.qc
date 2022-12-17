// items
float	IT_LAVA_NAILGUN			  = 4096;		
float IT_LAVA_SUPER_NAILGUN	= 8192;			
float IT_MULTI_GRENADE		  = 16384;
float	IT_MULTI_ROCKET			  = 32768;
float	IT_PLASMA_GUN			    = 65536;	
//ZOID --
float	IT_GRAPPLE				    = 8388608;		// grapple overload, hope it
//-- ZOID										// doesn't mess things up!

float	IT2_ARMOR1				  = 1;
float	IT2_ARMOR2				  = 2;
float	IT2_ARMOR3				  = 4;
float	IT2_LAVA_NAILS			= 8;
float	IT2_PLASMA_AMMO			= 16;
float	IT2_MULTI_ROCKETS		= 32;
float IT2_SHIELD				  = 64;
float IT2_ANTIGRAV			  = 128;
float	IT2_SUPERHEALTH			= 256;
float	IT2_EARTHQUAKE			= 512;			
float	IT2_V_SPHERE			  = 1024;


// rogue globals!
float 	earthquake_active;
float	earthquake_intensity;
float	cutscene_running;
entity  tag_token_owner;


//
// player only fields
//

.float		shield_finished, antigrav_finished;
.float		shield_time, antigrav_time;
.entity		shield_entity;

.entity		shield_item, antigrav_item;
.float		shield_validdroptime, antigrav_validdroptime;

//
// elevator fields
//

.float 		elevatorLastUse;
.float		elevatorOnFloor;
.float		elevatorToFloor;
.vector		elevatorDestination; 

//
// plat2 fields
//
.float		plat2Called;
.float		plat2LastMove;
.float		plat2GoTime;
.float		plat2GoTo;

//
// new AI fields
//
.float		orbitPosition;

//
// dragon specific fields
// 
.float playerInRoom;
.float playerInTransit;
.float dragonInRoom;
.float dragonInTransit;
.float dragonAttacking;
.float dragonPainSequence;
.vector dragonLastVelocity;

//
// Other Rogue Fields
//
.float		AGping;
.float		childrenSpawned;
.float		ltrailLastUsed;
.float		shield_death_time;
.float		shieldSoundTime;
.float		dragonDeathState;

.float		tag_frags;
.float		tag_message_time;

//===========================================================================

// 
// new_items.qc
//
void(entity theEntity) UpdateAmmoCounts;

//
// dmatch.qc
//
void() tag_token_respawn;
void() tag_token_touch;
void() tag_token_drop;

// sphere.qc
void(entity ownerEntity) sphere_remove;

