
/*QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for spotlights, etc.
*/
void() info_null =
{
	remove(self);
};

/*QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for lightning.
*/
void() info_notnull =
{
};

//============================================================================

float START_OFF = 1;

void() light_use =
{
	if (self.spawnflags & START_OFF)
	{
		lightstyle(self.style, "m");
		self.spawnflags = self.spawnflags - START_OFF;
	}
	else
	{
		lightstyle(self.style, "a");
		self.spawnflags = self.spawnflags + START_OFF;
	}
};

/*QUAKED light (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
*/
void() light =
{
	if (!self.targetname)
	{	// inert light
		remove(self);
		return;
	}

	if (self.style >= 32)
	{
		self.use = light_use;
		if (self.spawnflags & START_OFF)
			lightstyle(self.style, "a");
		else
			lightstyle(self.style, "m");
	}
};

/*QUAKED light_fluoro (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
Makes steady fluorescent humming sound
*/
void() light_fluoro =
{
	if (self.style >= 32)
	{
		self.use = light_use;
		if (self.spawnflags & START_OFF)
			lightstyle(self.style, "a");
		else
			lightstyle(self.style, "m");
	}

	precache_sound ("ambience/fl_hum1.wav");
	ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED light_fluorospark (0 1 0) (-8 -8 -8) (8 8 8)
Non-displayed light.
Default light value is 300
Default style is 10
Makes sparking, broken fluorescent sound
*/
void() light_fluorospark =
{
	if (!self.style)
		self.style = 10;

	precache_sound ("ambience/buzz1.wav");
	ambientsound (self.origin, "ambience/buzz1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED light_globe (0 1 0) (-8 -8 -8) (8 8 8)
Sphere globe light.
Default light value is 300
Default style is 0
*/
void() light_globe =
{
	precache_model ("progs/s_light.spr");
	setmodel (self, "progs/s_light.spr");
	makestatic (self);
};

void() FireAmbient =
{
	precache_sound ("ambience/fire1.wav");
// attenuate fast
	ambientsound (self.origin, "ambience/fire1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED light_torch_small_walltorch (0 .5 0) (-10 -10 -20) (10 10 20)
Short wall torch
Default light value is 200
Default style is 0
*/
void() light_torch_small_walltorch =
{
	precache_model ("progs/flame.mdl");
	setmodel (self, "progs/flame.mdl");
  #ifdef GAME_ROGUE
  if (!(self.spawnflags & 1))
  #endif
    FireAmbient ();
	makestatic (self);
};

/*QUAKED light_flame_large_yellow (0 1 0) (-10 -10 -12) (12 12 18)
Large yellow flame ball
*/
void() light_flame_large_yellow =
{
	precache_model ("progs/flame2.mdl");
	setmodel (self, "progs/flame2.mdl");
	self.frame = 1;
	FireAmbient ();
	makestatic (self);
};

/*QUAKED light_flame_small_yellow (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Small yellow flame ball
*/
void() light_flame_small_yellow =
{
	precache_model ("progs/flame2.mdl");
	setmodel (self, "progs/flame2.mdl");
	FireAmbient ();
	makestatic (self);
};

/*QUAKED light_flame_small_white (0 1 0) (-10 -10 -40) (10 10 40) START_OFF
Small white flame ball
*/
void() light_flame_small_white =
{
	precache_model ("progs/flame2.mdl");
	setmodel (self, "progs/flame2.mdl");
	FireAmbient ();
	makestatic (self);
};

//============================================================================


/*QUAKED misc_fireball (0 .5 .8) (-8 -8 -8) (8 8 8)
Lava Balls
*/

void() fire_fly;
void() fire_touch;
void() misc_fireball =
{

	precache_model ("progs/lavaball.mdl");
	self.classname = "fireball";
	self.nextthink = time + 0.1 + (random() * 4.9);
	self.think = fire_fly;
	if (!self.speed)
		self.speed = 1000;
};

void() fire_fly =
{
local entity	fireball;

	fireball = spawn();
	fireball.solid = SOLID_TRIGGER;
	fireball.movetype = MOVETYPE_TOSS;
	fireball.velocity = '0 0 1000';
	fireball.velocity_x = (random() * 100) - 50;
	fireball.velocity_y = (random() * 100) - 50;
	fireball.velocity_z = self.speed + (random() * 200);
	fireball.classname = "fireball";
	setmodel (fireball, "progs/lavaball.mdl");
	setsize (fireball, '0 0 0', '0 0 0');
	setorigin (fireball, self.origin);
	fireball.nextthink = time + 5;
	fireball.think = SUB_Remove;
	fireball.touch = fire_touch;

	self.nextthink = time + (random() * 5) + 3;
	self.think = fire_fly;
};


void() fire_touch =
{
	T_Damage (other, self, self, 20);
	remove(self);
};

//============================================================================


//Ry: Remaster behavior, which fixes problems with doing radius damage on the same frame
void() barrel_explode =
{
	// did say self.owner
	T_RadiusDamage (self, self.enemy, 160, world);
	sound (self, CHAN_VOICE, "weapons/r_exp3.wav", 1, ATTN_NORM);
	particle (self.origin, '0 0 0', 75, 255);

	self.origin_z = self.origin_z + 32;
	BecomeExplosion ();
};

void() barrel_detonate =
{
	self.classname = "explo_box";
	self.takedamage = DAMAGE_NO;
	self.think = barrel_explode;
	self.nextthink = time + 0.1; //Ry: Tweaked a bit
}


/*QUAKED misc_explobox (0 .5 .8) (0 0 0) (32 32 64)
TESTING THING
*/

void() misc_explobox =
{
	local float	oldz;

	if(!self.mdl) //Ry: Remaster's setup [09-26-2022]
		self.mdl = "maps/b_explob.bsp";

	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_NONE;
	precache_model(self.mdl);
	setmodel(self,self.mdl);
	precache_sound("weapons/r_exp3.wav");
	self.health = 20;
	self.th_die = barrel_detonate;
	self.takedamage = DAMAGE_AIM;
  self.netname = "exploding barrel";

	self.origin_z = self.origin_z + 2;
	oldz = self.origin_z;
	droptofloor(0, 0);
	if (oldz - self.origin_z > 250)
	{
		dprint ("explobox fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
	}
};


/*QUAKED misc_explobox2 (0 .5 .8) (0 0 0) (32 32 64)
Smaller exploding box, REGISTERED ONLY
*/

void() misc_explobox2 =
{
  self.mdl = "maps/b_exbox2.bsp";
  misc_explobox();
};

//============================================================================

float SPAWNFLAG_SUPERSPIKE = 1;
float SPAWNFLAG_LASER = 2;
#ifdef GAME_HIPNOTIC
  float SPAWNFLAG_LAVABALL = 4;
  float SPAWNFLAG_ROCKET = 8;
  float SPAWNFLAG_SILENT = 16;
#elifdef GAME_ROGUE
  float SPAWNFLAG_LAVASPIKE = 4;
  float SPAWNFLAG_SUPERLAVA = 8;
  float SPAWNFLAG_LAVASKILL = 16;
  float SPAWNFLAG_FIREBALL = 32;

  void(vector org, vector dir) launch_lava_spike;
  void(vector org, vector dir) launch_fireball;
#endif
 
void(vector org, vector vec) LaunchLaser;

//MED 11/09/96 added lava ball and rocket
void() spikeshooter_use =
{
  #ifdef GAME_HIPNOTIC
    local entity lavaball;
  #endif
	if (self.spawnflags & SPAWNFLAG_LASER)
	{
    #ifdef GAME_HIPNOTIC
    if (!(self.spawnflags & SPAWNFLAG_SILENT))
    #endif
      sound (self, CHAN_VOICE, "enforcer/enfire.wav", 1, ATTN_NORM);
		LaunchLaser (self.origin, self.movedir);
    newmis.spawnflags = self.spawnflags;
	}
  #ifdef GAME_HIPNOTIC
    else if (self.spawnflags & SPAWNFLAG_LAVABALL)
    {
      if (!(self.spawnflags & SPAWNFLAG_SILENT))
        sound (self, CHAN_VOICE, "misc/spike.wav", 1, ATTN_NORM);
      lavaball = spawn();
      lavaball.movetype = MOVETYPE_FLYMISSILE;
      lavaball.solid = SOLID_BBOX;
      lavaball.classname = "lavaball";
      // set lavaball speed
      lavaball.velocity = self.movedir * 300;
      lavaball.angles = vectoangles(lavaball.velocity);
      lavaball.owner = self;
      lavaball.touch = T_MissileTouch;
      setmodel (lavaball, "progs/lavarock.mdl");
      setsize (lavaball, '-4 -4 -4', '4 4 4');
      setorigin (lavaball, self.origin);
      lavaball.avelocity = '0 0 400';
      lavaball.nextthink = time + 5;
      lavaball.think = SUB_Remove;
    }
    else if (self.spawnflags & SPAWNFLAG_ROCKET)
    {
      if (!(self.spawnflags & SPAWNFLAG_SILENT))
        sound (self, CHAN_VOICE, "weapons/sgun1.wav", 1, ATTN_NORM);
      W_FireRocket();
      newmis.velocity = self.movedir*1000;
      newmis.angles = vectoangles(newmis.velocity);
      setorigin (newmis, self.origin + self.movedir*8);
    }
  #elifdef GAME_ROGUE
    else if (self.spawnflags & SPAWNFLAG_FIREBALL)
    {
      launch_fireball (self.origin, self.movedir);
    }
    else if (self.spawnflags & (SPAWNFLAG_LAVASPIKE|SPAWNFLAG_SUPERLAVA|SPAWNFLAG_LAVASKILL))
    {
      sound (self, CHAN_VOICE, "weapons/spike2.wav", 1, ATTN_NORM);
      launch_lava_spike (self.origin, self.movedir);
      newmis.velocity = self.movedir * 500;
      if (self.spawnflags & SPAWNFLAG_SUPERLAVA)
        newmis.touch = superlavaspike_touch;
      else if ((self.spawnflags & SPAWNFLAG_LAVASKILL) && (skill > 1))
        newmis.touch = superlavaspike_touch;
    }
  #endif
  else
  {
    #ifdef GAME_HIPNOTIC
    if (!(self.spawnflags & SPAWNFLAG_SILENT))
    #endif
      sound (self, CHAN_VOICE, "weapons/spike2.wav", 1, ATTN_NORM);
		launch_spike (self.origin, self.movedir);
		newmis.velocity = self.movedir * 500;
    if (self.spawnflags & SPAWNFLAG_SUPERSPIKE)
    {
      newmis.touch = superspike_touch;
      //Ry: Give super spikes the actual model [09-26-2022]
      newmis.classname = "super_spike";
      setmodel (newmis, "progs/s_spike.mdl");
      setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
    }
	}
};

//MED 11/01/96 added state capability
void() shooter_think =
{
   if (self.state)
      {
      spikeshooter_use ();
      }
   self.nextthink = time + self.wait;
};


/*QUAKED trap_spikeshooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser lavaball rocket silent
When triggered, fires a spike in the direction set in QuakeEd.
Laser is only for REGISTERED.
*/

//MED 11/01/96 commented out setmovedir
void() trap_spikeshooter =
{
  SetMovedir ();
	self.use = spikeshooter_use;
	if (self.spawnflags & SPAWNFLAG_LASER)
	{
		precache_model2 ("progs/laser.mdl");

		precache_sound2 ("enforcer/enfire.wav");
		precache_sound2 ("enforcer/enfstop.wav");
	}
  #ifdef GAME_HIPNOTIC
    else if (self.spawnflags & SPAWNFLAG_LAVABALL)
    {
      precache_model ("progs/lavarock.mdl");
    //  self.classname = "fireball";
      precache_sound2 ("misc/spike.wav");
    }
    else if (self.spawnflags & SPAWNFLAG_ROCKET)
    {
      precache_model ("progs/missile.mdl");
      precache_sound ("weapons/sgun1.wav");
    }
  #endif
  #ifdef GAME_ROGUE
    else if (self.spawnflags & SPAWNFLAG_LAVASPIKE)
    {
      precache_model2 ("progs/lspike.mdl");
      precache_sound2 ("lavagun/snail.wav");		// lava nail gun cooldown
      precache_sound2 ("weapons/rocket1i.wav");
    }
    else if (self.spawnflags & SPAWNFLAG_SUPERLAVA)
    {
      precache_model2 ("progs/lspike.mdl");
      precache_sound2 ("lavagun/snail.wav");		// lava nail gun cooldown
      precache_sound2 ("weapons/spike2.wav");
    }
    else if (self.spawnflags & SPAWNFLAG_LAVASKILL)
    {
      precache_model2 ("progs/lspike.mdl");
      precache_sound2 ("lavagun/snail.wav");		// lava nail gun cooldown
      precache_sound2 ("weapons/rocket1i.wav");
      precache_sound2 ("weapons/spike2.wav");
    }
    else if (self.spawnflags & SPAWNFLAG_FIREBALL)
    {
      precache_model ("progs/fireball.mdl");
    }
  #endif
  else
    precache_sound ("weapons/spike2.wav");
};


/*QUAKED trap_shooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser lavaball rocket silent
Continuously fires spikes.
"wait" time between spike (1.0 default)
"nextthink" delay before firing first spike, so multiple shooters can be stagered.
*/
void() trap_shooter =
{
	trap_spikeshooter ();

	if (self.wait == 0)
		self.wait = 1;
//MED 11/01/96 added state capability
   self.state = 1;
	self.nextthink = self.nextthink + self.wait + self.ltime;
	self.think = shooter_think;
};

//MED 11/01/96 added new use function
void() trap_shooter_use =
   {
   self.state = 1 - self.state;
   };
//MED 11/01/96 added new function
/*QUAKED trap_switched_shooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser lavaball rocket silent
Continuously fires spikes.
"wait" time between spike (1.0 default)
"nextthink" delay before firing first spike, so multiple shooters can be stagered.
"state" 0 initially off, 1 initially on. (0 default)
*/
void() trap_switched_shooter =
   {
   trap_spikeshooter ();

	if (self.wait == 0)
		self.wait = 1;
//MED 11/01/96 added state capability
	self.nextthink = self.nextthink + self.wait + self.ltime;
	self.think = shooter_think;
   self.use = trap_shooter_use;
   };



/*
===============================================================================


===============================================================================
*/


void() make_bubbles;
void() bubble_remove;
void() bubble_bob;

/*QUAKED air_bubbles (0 .5 .8) (-8 -8 -8) (8 8 8)

testing air bubbles
*/

void() air_bubbles =

{
	if (deathmatch)
	{
		remove (self);
		return;
	}
	precache_model ("progs/s_bubble.spr");
	self.nextthink = time + 1;
	self.think = make_bubbles;
};

void() make_bubbles =
{
local entity	bubble;

	bubble = spawn();
	setmodel (bubble, "progs/s_bubble.spr");
	setorigin (bubble, self.origin);
	bubble.movetype = MOVETYPE_NOCLIP;
	bubble.solid = SOLID_NOT;
	bubble.velocity = '0 0 15';
	bubble.nextthink = time + 0.5;
	bubble.think = bubble_bob;
	bubble.touch = bubble_remove;
	bubble.classname = "bubble";
	bubble.frame = 0;
	bubble.cnt = 0;
	setsize (bubble, '-8 -8 -8', '8 8 8');
	self.nextthink = time + random() + 0.5;
	self.think = make_bubbles;
};

void() bubble_split =
{
local entity	bubble;
	bubble = spawn();
	setmodel (bubble, "progs/s_bubble.spr");
	setorigin (bubble, self.origin);
	bubble.movetype = MOVETYPE_NOCLIP;
	bubble.solid = SOLID_NOT;
	bubble.velocity = self.velocity;
	bubble.nextthink = time + 0.5;
	bubble.think = bubble_bob;
	bubble.touch = bubble_remove;
	bubble.classname = "bubble";
	bubble.frame = 1;
	bubble.cnt = 10;
	setsize (bubble, '-8 -8 -8', '8 8 8');
	self.frame = 1;
	self.cnt = 10;
	if (self.waterlevel != 3)
		remove (self);
};

void() bubble_remove =
{
	if (other.classname == self.classname)
	{
//		dprint ("bump");
		return;
	}
	remove(self);
};

void() bubble_bob =
{
  local float		rnd1, rnd2, rnd3;
  
	// PGM fix - 02/25/97 so bubbles won't go through walls
	rnd1 = pointcontents(self.origin);
	if (rnd1 == CONTENT_SOLID)
		remove(self);
	// PGM fix - 02/25/97 so bubbles pop 2 seconds after leaving water
	else if (rnd1 == CONTENT_EMPTY)
	{
		if (self.cnt < 16)
			self.cnt = 16;
	}

	self.cnt = self.cnt + 1;
	if (self.cnt == 4)
		bubble_split();
	if (self.cnt == 20)
		remove(self);

	rnd1 = self.velocity_x + (-10 + (random() * 20));
	rnd2 = self.velocity_y + (-10 + (random() * 20));
	rnd3 = self.velocity_z + 10 + random() * 10;

	if (rnd1 > 10)
		rnd1 = 5;
	if (rnd1 < -10)
		rnd1 = -5;

	if (rnd2 > 10)
		rnd2 = 5;
	if (rnd2 < -10)
		rnd2 = -5;

	if (rnd3 < 10)
		rnd3 = 15;
	if (rnd3 > 30)
		rnd3 = 25;

	self.velocity_x = rnd1;
	self.velocity_y = rnd2;
	self.velocity_z = rnd3;

	self.nextthink = time + 0.5;
	self.think = bubble_bob;
};

/*~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>
~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~*/

/*QUAKED viewthing (0 .5 .8) (-8 -8 -8) (8 8 8)

Just for the debugging level.  Don't use
*/

void() viewthing =

{
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	precache_model ("progs/player.mdl");
	setmodel (self, "progs/player.mdl");
};


/*
==============================================================================

SIMPLE BMODELS

==============================================================================
*/

void() func_wall_use =
{	// change to alternate textures
	self.frame = 1 - self.frame;
};

/*QUAKED func_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
*/
void() func_wall =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
  {
    remove(self);
    return;
  }
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};


/*QUAKED func_illusionary (0 .5 .8) ?
A simple entity that looks solid but lets you walk through it.
*/
void() func_illusionary =

{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
  {
    remove(self);
    return;
  }
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setmodel (self, self.model);
	makestatic (self); // Cataboligne 9.17.3 - fixed this compiler warning
};

/*QUAKED func_episodegate (0 .5 .8) ? E1 E2 E3 E4
This bmodel will appear if the episode has allready been completed, so players can't reenter it.
*/
void() func_episodegate =

{
	if (!(serverflags & self.spawnflags))
		return;			// can still enter episode

	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};

/*QUAKED func_bossgate (0 .5 .8) ?
This bmodel appears unless players have all of the episode sigils.
*/
void() func_bossgate =

{
	if ( (serverflags & 15) == 15)
		return;		// all episodes completed
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};

//============================================================================
/*QUAKED ambient_suck_wind (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_suck_wind =
{
	precache_sound ("ambience/suck1.wav");
	ambientsound (self.origin, "ambience/suck1.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_drone (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_drone =
{
	precache_sound ("ambience/drone6.wav");
	ambientsound (self.origin, "ambience/drone6.wav", 0.5, ATTN_STATIC);
};

/*QUAKED ambient_flouro_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_flouro_buzz =
{
	precache_sound ("ambience/buzz1.wav");
	ambientsound (self.origin, "ambience/buzz1.wav", 1, ATTN_STATIC);
};
/*QUAKED ambient_drip (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_drip =
{
	precache_sound ("ambience/drip1.wav");
	ambientsound (self.origin, "ambience/drip1.wav", 0.5, ATTN_STATIC);
};
/*QUAKED ambient_comp_hum (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_comp_hum =
{
	precache_sound ("ambience/comp1.wav");
	ambientsound (self.origin, "ambience/comp1.wav", 1, ATTN_STATIC);
};
/*QUAKED ambient_thunder (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_thunder =
{
	precache_sound ("ambience/thunder1.wav");
	ambientsound (self.origin, "ambience/thunder1.wav", 0.5, ATTN_STATIC);
};
/*QUAKED ambient_light_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_light_buzz =
{
	precache_sound ("ambience/fl_hum1.wav");
	ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
};
/*QUAKED ambient_swamp1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_swamp1 =
{
	precache_sound ("ambience/swamp1.wav");
	ambientsound (self.origin, "ambience/swamp1.wav", 0.5, ATTN_STATIC);
};
/*QUAKED ambient_swamp2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_swamp2 =
{
	precache_sound ("ambience/swamp2.wav");
	ambientsound (self.origin, "ambience/swamp2.wav", 0.5, ATTN_STATIC);
};

//============================================================================

void() noise_think =
{
	self.nextthink = time + 0.5;
	sound (self, 1, "enforcer/enfire.wav", 1, ATTN_NORM);
	sound (self, 2, "enforcer/enfstop.wav", 1, ATTN_NORM);
	sound (self, 3, "enforcer/sight1.wav", 1, ATTN_NORM);
	sound (self, 4, "enforcer/sight2.wav", 1, ATTN_NORM);
	sound (self, 5, "enforcer/sight3.wav", 1, ATTN_NORM);
	sound (self, 6, "enforcer/sight4.wav", 1, ATTN_NORM);
	sound (self, 7, "enforcer/pain1.wav", 1, ATTN_NORM);
};

/*QUAKED misc_noisemaker (1 0.5 0) (-10 -10 -10) (10 10 10)

For optimzation testing, starts a lot of sounds.
*/

void() misc_noisemaker =

{
	precache_sound2 ("enforcer/enfire.wav");
	precache_sound2 ("enforcer/enfstop.wav");
	precache_sound2 ("enforcer/sight1.wav");
	precache_sound2 ("enforcer/sight2.wav");
	precache_sound2 ("enforcer/sight3.wav");
	precache_sound2 ("enforcer/sight4.wav");
	precache_sound2 ("enforcer/pain1.wav");
	precache_sound2 ("enforcer/pain2.wav");
	precache_sound2 ("enforcer/death1.wav");
	precache_sound2 ("enforcer/idle1.wav");

	self.nextthink = time + 0.1 + random();
	self.think = noise_think;
};
