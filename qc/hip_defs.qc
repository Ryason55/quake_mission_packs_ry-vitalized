/* Level pack definitons
   Copyright (c)1996 Hipnotic Interactive, Inc.
   All rights reserved.
   Distributed (unsupported) on 3.12.97
*/

//entity nullentity;
entity bulletholes;
//entity lastbullet;
//float numbulletholes;
float IT_MJOLNIR = 128;
float IT_LASER_CANNON = 8388608;
float IT_PROXIMITY_GUN = 65536;
float HIP_IT_WETSUIT = 2;
float HIP_IT_EMPATHY_SHIELDS = 4;
float HIP_IT_HORN_OF_CONJURING = 8;
.void()     th_turn;
float AS_DODGING     = 5;
float CHARMED_RADIUS = 1500;
float MAX_CHARMER_DISTANCE = 200;
float MIN_CHARMER_DISTANCE = 150;
float TOOCLOSE_CHARMER_DISTANCE = 120;
//float visible_distance; //Ry: Moved to ry_defs.qc
//entity damage_inflictor; //Ry: Moved to ry_defs.qc
float footsteps;

//MED 11/09/96 added new spawnflags
//float SPAWNFLAG_SUPERSPIKE	= 1; //Ry: Moved to ry_defs.qc
//float SPAWNFLAG_LASER = 2;
//float SPAWNFLAG_LAVABALL = 4;
//float SPAWNFLAG_ROCKET = 8;
//float SPAWNFLAG_SILENT = 16;

// Hipnotic Constants
float MIN_ANGLE_DELTA = 10;

.float wetsuit_finished;
.float wetsuit_time;
.float empathy_finished;
.float empathy_time;
.float empathy_sound;
.float color;

//
// Hipnotic entries
//
// gremlin stuff
//.float      gorging;
//.float      stoleweapon;
.entity     lastvictim;
// spawn variables
.void()     spawnfunction;
//.string     spawnclassname;
.float      spawnsolidtype;
.string     spawnmodel;
.void()     spawnthink;
//.entity     spawnmaster;
.vector     spawnmins;
.vector     spawnmaxs;
//.float      spawnsilent;
.float      spawnmulti;
// horn of conjuring
.float      charmed;
.entity     charmer;
.float      huntingcharmer;
float horn_active;
entity horn_charmer;
// laser cannon
.vector     old_velocity;
//misc
.float      duration;
// used for linked list of entities
.entity     next_ent;
// Mjolnir
.float      struck_by_mjolnir;
// teleport invulnerability
.float      last_teleport_time;

// Rotation
.vector neworigin;
.vector rotate;
.float  endtime;
.float  rotate_type;
.string path;
.string group;
.string event;

//MED 01/05/97 added discharge variable
//float discharged; //Ry: removed discharge variable [07-12-2022]
//MED 01/05/97 added hipnotic decoy
entity hipdecoy;
//
// Hipnotic's Prototypes
//
void() StopEarthQuake;
void( float value ) EarthQuakeTime;
void() earthquake_postthink;
void() earthquake_prethink;
float( entity counter ) counter_GetCount;
vector ( vector ang ) SUB_NormalizeAngles;
void (entity srcent, entity destent) SUB_CopyEntity;
//multi explosion
void( vector loc, float rad, float damage, float dur, float pause, float vol) multi_explosion;
void(string targ, vector orig) become_decoy;


//void(vector origin, vector dir, float color, float count, float lifespan) particlestream = #79;

void() RotateTargets;
void() RotateTargetsFinal;
void() SetTargetOrigin;
void() LinkRotateTargets;
