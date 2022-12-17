/*
*/
#ifdef GAME_HIPNOTIC
  //JIM
  void( vector pos ) placebullethole;
#endif

void (entity targ, entity inflictor, entity attacker, float damage) T_Damage;
void () player_run;
void(entity bomb, entity attacker, float rad, entity ignore) T_RadiusDamage;
void(vector org, vector vel, float damage) SpawnBlood;
void() SuperDamageSound;

//Ry: Moved this var up here for the added function [08-01-2022]
entity	multi_ent;


//======================
//  New Subs by Ryason
//======================

void() GrenadeExplode;
#ifdef GAME_ROGUE
  void() MultiGrenadeExplode;
#endif

//Ry: Function from Remaster, to check if the Grenade gets stuck on a downwards slope
void GrenadeThink()
{
  #ifdef GAME_ROGUE
  if (self.classname == "MultiGrenade")
  {
    if (time >= self.delay)
    {
      MultiGrenadeExplode();
      return;
    }
    //Ry: For players, Multi-Grenades will auto-cluster when they get near an enemy
    if (hip_rebalance && self.owner.classname == "player")
    {
      local entity ent;
      ent = findradius(self.origin,135);
      while (ent)
      {
        if ( (ent.flags & (FL_MONSTER|FL_CLIENT)) && (ent.takedamage == DAMAGE_AIM) && ((ent.team == 0) || (ent.team != self.owner.team)) )
        {
          if (BBoxIntersection(self,ent,32))
          {
            MultiGrenadeExplode();
            return;
          }
        }
        ent = ent.chain;
      }
    }
    self.nextthink = time + 0.01; //Ry: Check more frequently
  }
  else
  {
  #endif
    if (time >= self.delay)
    {
      GrenadeExplode();
      return;
    }
    self.nextthink = time + 0.05;
  #ifdef GAME_ROGUE
  }
  #endif
	float oldVel = vlen(self.oldorigin);
	float vel = vlen(self.velocity);
	if(vel == 0) //Stuck on downward slope?
	{
		if(oldVel > 120 && self.oldorigin_z < 0) //Were we moving downwards at a decent speed last tick?
		{
			// Trace straight down and find the normal of the surface it bounced off
			traceline(self.origin + '0 0 4', self.origin - '0 0 8', TRUE, self);
			if(trace_fraction < 1.0) // Hit something...
			{
				// dprint("reflected grenade bounce\n");
				// Reflect the previous velocity off that normal
				vector reflected = self.oldorigin - 2 * (self.oldorigin * trace_plane_normal) * trace_plane_normal;
	
				self.flags &~= FL_ONGROUND; //Remove FL_ONGROUND
				self.velocity = reflected * 0.6; // Scale it down a bit so it feels better
				self.avelocity = '400 400 400'; // Roll that sucker around
			}
		}
	}
	self.oldorigin = self.velocity;
}

//Ry: These "Missile Fields" allow projectiles (currently Nails and Lasers) to effectively have a larger hitbox when used against other players
void() MissileFieldTouch =
{
  if ( !self.owner || !self.owner.touch )
  {
    self.touch = SUB_Null;
    self.think = SUB_Remove;
    self.nextthink = time;
    return;
  }
  else if ( (other != self.owner) && (other.flags & FL_CLIENT) && !other.deadflag && ( (other.team == 0) || !(other.team == self.owner.owner.team) ) )
  {
    traceline(self.origin,other.origin,FALSE,self.owner);
    if (trace_ent == other)
    {
      self = self.owner;
      self.touch();
    }
  }
}

void() UpdateMissileField = //Ry: Call this whenever the base projectile gets redirected or changes velocity
{
  if (self.trigger_field)
  {
    self.trigger_field.origin = self.origin;
    self.trigger_field.velocity = self.velocity;
  }
}

void() RemoveMissile = //Ry: Removes Missile Field along with the projectile
{
  if (self.trigger_field)
  {
    self.trigger_field.touch = SUB_Null;
    self.trigger_field.think = SUB_Remove;
    self.trigger_field.nextthink = time;
  }
  remove(self);
}

void(entity missile, float radius) CreateMissileField =
{
  if (wide_spikes && deathmatch && (missile.movetype == MOVETYPE_FLYMISSILE))
  {
    local entity field = spawn();
    field.classname = "missile_field";
    field.owner = missile;
    field.mins = '0 0 0';
    field.mins_x = -radius;
    field.mins_y = -radius;
    field.mins_z = -radius;
    field.maxs = '0 0 0';
    field.maxs_x = radius;
    field.maxs_y = radius;
    field.maxs_z = radius;
    field.movetype = MOVETYPE_NOCLIP;
    field.solid = SOLID_TRIGGER;
    field.origin = missile.origin;
    field.velocity = missile.velocity;
    field.touch = MissileFieldTouch;
    missile.trigger_field = field;
  }
}

//Ry: Returns false if the target is dead or is guaranteed to be gibbed already [07-31-2022]
float(entity targ, float ownerteam) ShouldTraceAgainstTarget =
{
  local float dmgtemp;
  if (targ && targ.flags & (FL_MONSTER|FL_CLIENT))
  {
    if ( targ.takedamage && (trace_ent.health > 0) && (!teamplay || (trace_ent.team == 0) || (trace_ent.team != ownerteam)) )
    {
      if (multi_ent && !targ.invincible_finished) //Ry: A Shotgun attack is occuring; Check if target will be gibbed by the end of this attack
      {
        dmgtemp = targ.multidmg_damage;
        if (self.super_damage_finished) //Ry: Need to account for powerup damage modifiers
          dmgtemp = dmgtemp * 4;
        #ifdef GAME_HIPNOTIC
          if (targ.empathy_finished)
            dmgtemp = dmgtemp / 2;
        #endif
        if ((targ.health - dmgtemp) >= targ.gib_health)
          return TRUE;
      }
      else
        return TRUE;
    }
    return FALSE;
  }
  return TRUE;
}

//Ry: Keep tracing until a valid entity is hit, ignoring dead monsters and same team [07-31-2022]
//    This will expect self to be set to the attacker (ownerteam is separate so certain sources don't account for team)
void(vector vec1,vector vec2,float ignoremonsters,entity ignoreent,float ownerteam) traceline_ignoreinvalid =
{
  local float count = 0;
  if (ignoremonsters != 1)
  {
    trace_endpos = vec1;
    while (TRUE)
    {
      count += 1;
      traceline(trace_endpos,vec2,ignoremonsters,ignoreent);
      if (trace_ent && trace_fraction < 1) //Ry: Something other than the world was hit
      {
        if ( ShouldTraceAgainstTarget(trace_ent,ownerteam) )
        {
          if (count > 1) //Ry: Make the trace_fraction make sense if we did more than 1 trace
            trace_fraction = vlen(vec1-trace_endpos) / vlen(vec1-vec2);
          return;
        }
        ignoreent = trace_ent;
      }
      else
        break;
    }
  }
  traceline(vec1,vec2,TRUE,ignoreent); //Ry: Just trace against world as a fallback
}

//Ry: Version of W_SetCurrentAmmo that doesn't reset player or weapon state
void() W_UpdateAmmo =
{
	if (self.weapon == IT_SHOTGUN || self.weapon == IT_SUPER_SHOTGUN)
		self.currentammo = self.AMMO_SHELLS;
	else if (self.weapon == IT_NAILGUN || self.weapon == IT_SUPER_NAILGUN)
		self.currentammo = self.AMMO_NAILS;
  else if (self.weapon == IT_GRENADE_LAUNCHER || self.weapon == IT_ROCKET_LAUNCHER)
    self.currentammo = self.AMMO_ROCKETS;
  else if (self.weapon == IT_LIGHTNING)
    self.currentammo = self.AMMO_CELLS;
  #ifdef GAME_HIPNOTIC
    else if (self.weapon == IT_PROXIMITY_GUN)
      self.currentammo = self.AMMO_ROCKETS;
    else if (self.weapon == IT_LASER_CANNON || (self.weapon == IT_MJOLNIR && !self.mjolnirdisable))
      self.currentammo = self.AMMO_CELLS;
  #endif
  #ifdef GAME_ROGUE
    else if (self.weapon == IT_LAVA_NAILGUN || self.weapon == IT_LAVA_SUPER_NAILGUN)
      self.currentammo = self.ammo_lava_nails;
    else if (self.weapon == IT_MULTI_GRENADE || self.weapon == IT_MULTI_ROCKET)
      self.currentammo = self.ammo_multi_rockets;
    else if (self.weapon == IT_PLASMA_GUN)
      self.currentammo = self.ammo_plasma;
  #endif
  else
		self.currentammo = 0;
};

float(entity player, float weapon) GetAmmoForWeapon =
{
  if (weapon & (IT_SHOTGUN|IT_SUPER_SHOTGUN))
    return player.AMMO_SHELLS;
  else if (weapon & (IT_NAILGUN|IT_SUPER_NAILGUN))
    return player.AMMO_NAILS;
  else if (weapon & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER))
    return player.AMMO_ROCKETS;
  else if (weapon & (IT_LIGHTNING))
    return player.AMMO_CELLS;
  #ifdef GAME_HIPNOTIC
    else if (weapon & (IT_PROXIMITY_GUN))
      return player.AMMO_ROCKETS;
    else if (weapon & (IT_LASER_CANNON|IT_MJOLNIR))
      return player.AMMO_CELLS;
  #endif
  #ifdef GAME_ROGUE
    else if (weapon & (IT_LAVA_NAILGUN|IT_LAVA_SUPER_NAILGUN))
      return player.ammo_lava_nails;
    else if (weapon & (IT_MULTI_GRENADE|IT_MULTI_ROCKET))
      return player.ammo_multi_rockets;
    else if (weapon & (IT_PLASMA_GUN))
      return player.ammo_plasma;
  #endif
  return 0;
}

float cyclestate;

float CYCLE_CONTINUE = 0;
float CYCLE_FOUND = 1;
float CYCLE_NOAMMO = 2;

void(float wep1, float wep2, float reqammo) TryCycleWeapon =
{
  if (cyclestate == CYCLE_CONTINUE && self.weapon == wep1)
  {
    self.weapon = wep2;
    cyclestate = CYCLE_FOUND;
    if (reqammo)
    {
      if (GetAmmoForWeapon(self,wep2) < reqammo)
        cyclestate = CYCLE_NOAMMO;
    }
  }
}

//===================
//  End of new subs
//===================


//Ry: Hipnotic weapons moved to their own file: hip_weapons.qc

// called by worldspawn
void() W_Precache =
{
	precache_sound ("weapons/r_exp3.wav");	// new rocket explosion
	precache_sound ("weapons/rocket1i.wav");	// spike gun
	precache_sound ("weapons/sgun1.wav");
	precache_sound ("weapons/guncock.wav");	// player shotgun
	precache_sound ("weapons/ric1.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric2.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric3.wav");	// ricochet (used in c code)
	precache_sound ("weapons/spike2.wav");	// super spikes
	precache_sound ("weapons/tink1.wav");	// spikes tink (used in c code)
	precache_sound ("weapons/grenade.wav");	// grenade launcher
	precache_sound ("weapons/bounce.wav");		// grenade bounce
	precache_sound ("weapons/shotgn2.wav");	// super shotgun
  #ifdef GAME_HIPNOTIC
    //MED
    precache_sound ("enforcer/enfstop.wav");   // laser cannon
    //MED 11/06/96
    precache_sound ("knight/sword1.wav");   // laser cannon
    precache_sound ("hipweap/laserg.wav");   // laser cannon
    precache_sound ("hipweap/laserric.wav");   // laser cannon ricochet
    precache_sound ("hipweap/proxwarn.wav");   // proximity bomb
    precache_sound ("hipweap/proxbomb.wav");   // proximity bomb
    //MED 11/19/96
    precache_sound ("hipweap/mjolhit.wav");   // mjolnir
    precache_sound ("hipweap/mjolslap.wav");   // mjolnir
    precache_sound ("hipweap/mjoltink.wav");   // mjolnir
  #endif
  #ifdef GAME_ROGUE
    //ZOID--
    // grapple
    precache_sound("weapons/chain1.wav");
    precache_sound("pendulum/hit.wav");
    //--ZOID

    precache_sound ("lavagun/snail.wav");		// lava nail gun cooldown
  #endif

  precache_sound ("items/damage2.wav"); //Ry: Precache these for the powerup dev cheats
  precache_sound ("items/damage3.wav");
  #ifdef GAME_HIPNOTIC
    precache_sound ("misc/wetsuit.wav");
    precache_sound ("items/suit2.wav");
    precache_sound ("hipitems/empathy2.wav");
  #endif
  #ifdef GAME_ROGUE
    precache_model ("progs/p_shield.mdl");
    precache_sound ("shield/hit.wav");
    precache_sound ("shield/fadeout.wav");
    precache_sound ("belt/use.wav");
    precache_sound ("belt/fadeout.wav");
  #endif
};

float() crandom =
{
	return 2*(random() - 0.5);
};

/*
================
W_FireAxe
================
*/
void() W_FireAxe =
{
	local	vector	source;
	local	vector	org;

  makevectors (self.v_angle);
  source = self.origin + '0 0 16';
	traceline (source, source + v_forward*64, FALSE, self);
	if (trace_fraction == 1.0)
		return;

	org = trace_endpos - v_forward*4;

	if (trace_ent.takedamage)
	{
		trace_ent.axhitme = 1;
		SpawnBlood (org, '0 0 0', 20);
		T_Damage (trace_ent, self, self, 20);
    #ifdef GAME_ROGUE
      //Ry: If target is grappled to the player, detach them [10-03-2022]
      local entity stemp;
      if ((trace_ent.classname == "player") && (trace_ent.hookstatus == HOOK_ATTACHED) && (trace_ent.hook) && (trace_ent.hook.enemy == self))
      {
        stemp = self;
        self = trace_ent.hook;
        GrappleReset();
        self = stemp;
        sound (self, CHAN_WEAPON, "weapons/ric1.wav", 1, ATTN_NORM);
      }
    #endif
	}
	else
	{	// hit wall
		sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};


//============================================================================


vector() wall_velocity =
{
	local vector	vel;

	vel = normalize (self.velocity);
	vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;

	return vel;
};


/*
================
SpawnMeatSpray
================
*/
void(vector org, vector vel) SpawnMeatSpray =
{
	local	entity missile;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_NOT;

	makevectors (self.angles);

	missile.velocity = vel;
	missile.velocity_z = missile.velocity_z + 250 + 50*random();

	missile.avelocity = '3000 1000 2000';

// set missile duration
	missile.nextthink = time + 1;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/zom_gib.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, org);
};

/*
================
SpawnBlood
================
*/
void(vector org, vector vel, float damage) SpawnBlood =
{
	particle (org, vel*0.1, 73, damage*2);
};

/*
================
spawn_touchblood
================
*/
void(float damage) spawn_touchblood =
{
	local vector	vel;

	vel = wall_velocity () * 0.2;
	SpawnBlood (self.origin + vel*0.01, vel, damage);
};


/*
================
SpawnChunk
================
*/
void(vector org, vector vel) SpawnChunk =
{
	particle (org, vel*0.02, 0, 10);
};

/*
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
*/

void() ApplyMultiDamage =
{
  local entity ent;
	if (!multi_ent)
		return;
  while (multi_ent) //Ry: Iterate over the chain of entities that were hit [07-31-2022]
  {
    ent = multi_ent.multidmg_next;
    /*dprint("Dealing ");
    dprint(ftos(multi_ent.multidmg_damage));
    dprint(" damage to ");
    dprint(multi_ent.classname);
    dprint(" with ");
    dprint(ftos(multi_ent.health));
    dprint(" HP\n");*/
    T_Damage (multi_ent, self, self, multi_ent.multidmg_damage);
    multi_ent.multidmg_damage = 0;
    multi_ent.multidmg_next = world;
    multi_ent = ent; //Ry: By virtue, this should already reset the var to world when it's done
  }
};

void(entity hit, float damage) AddMultiDamage =
{
  local entity ent;

	if (!hit)
		return;

  //Ry: Instead of using a single global, track damage on each hit entity, and store them in a chain [07-31-2022]
  if (!multi_ent)
  {
    multi_ent = hit;
    multi_ent.multidmg_next = world;
    multi_ent.multidmg_damage = damage;
  }
  else
  {
    ent = multi_ent;
    while (ent) //Ry: See if the hit entity is already in the chain
    {
      if (ent == hit)
        break;
      ent = ent.multidmg_next;
    }
    if (!ent) //Ry: If not in the chain, add it to the start
    {
      ent = multi_ent;
      multi_ent = hit;
      multi_ent.multidmg_next = ent;
      multi_ent.multidmg_damage = 0;
      ent = multi_ent;
    }
    ent.multidmg_damage += damage; //Ry: Add the damage
  }
};

/*
==============================================================================

BULLETS

==============================================================================
*/

/*
================
TraceAttack
================
*/
void(float damage, vector dir) TraceAttack =
{
	local	vector	vel, org;

	vel = normalize(dir + v_up*crandom() + v_right*crandom());
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;

	org = trace_endpos - dir*4;

	if (trace_ent.takedamage)
	{
		SpawnBlood (org, vel*0.2, damage);
		AddMultiDamage (trace_ent, damage);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};

/*
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void(float shotcount, vector dir, vector spread) FireBullets =
{
	local	vector direction;
	local	vector	src;
  #ifdef GAME_HIPNOTIC
    //JIM
    local float bullet;
    bullet = 0;
  #endif

	makevectors(self.v_angle);

	src = self.origin + v_forward*10;
	src_z = self.absmin_z + self.size_z * 0.7;

	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

		traceline_ignoreinvalid (src, src + direction*2048, FALSE, self, 0); //Ry: Pass through dying monsters [07-31-2022]
		if (trace_fraction != 1.0)
    //JIM
    {
      TraceAttack (4, direction);
      #ifdef GAME_HIPNOTIC
        if ( ( !bullet ) && ( trace_ent == world ) )
        {
          placebullethole( trace_endpos );
          bullet = 1;
        }
      #endif
    }

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();
};

/*
================
W_FireShotgun
================
*/
void() W_FireShotgun =
{
	local vector dir;

	sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

  self.currentammo = self.AMMO_SHELLS -= 1;
  #ifdef GAME_ROGUE
    UpdateAmmoCounts(self);
  #endif
	dir = aim (self, 100000);
	FireBullets (6, dir, '0.04 0.04 0');
};


/*
================
W_FireSuperShotgun
================
*/
void() W_FireSuperShotgun =
{
	local vector dir;

	if (self.currentammo == 1)
	{
		W_FireShotgun ();
		return;
	}

	sound (self ,CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);

	self.punchangle_x = -4;

  self.currentammo = self.AMMO_SHELLS -= 2;
  #ifdef GAME_ROGUE
    UpdateAmmoCounts(self);
  #endif
	dir = aim (self, 100000);
	FireBullets (14, dir, '0.14 0.08 0');
};


/*
==============================================================================

ROCKETS

==============================================================================
*/

void()	s_explode1	=	[0,		s_explode2] {};
void()	s_explode2	=	[1,		s_explode3] {};
void()	s_explode3	=	[2,		s_explode4] {};
void()	s_explode4	=	[3,		s_explode5] {};
void()	s_explode5	=	[4,		s_explode6] {};
void()	s_explode6	=	[5,		SUB_Remove] {};

void() BecomeExplosion =
{
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};

void() T_MissileTouch =
{
	local float	damg;

	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damg = 100 + random()*20;

	if (other.health)
	{
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;	// mostly immune
		T_Damage (other, self, self.owner, damg );
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact
	T_RadiusDamage (self, self.owner, 120, other);

//	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};



/*
================
W_FireRocket
================
*/
void() W_FireRocket =
{
	local	entity missile;

  self.currentammo = self.AMMO_ROCKETS -= 1;
  #ifdef GAME_ROGUE
    UpdateAmmoCounts(self);
  #endif

	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "missile";

// set missile speed

	makevectors (self.v_angle);
	missile.velocity = aim(self, 1000);
	missile.velocity = missile.velocity * ProjectileSpeed(self,1000);
	missile.angles = vectoangles(missile.velocity);

	missile.touch = T_MissileTouch;

// set missile duration
	missile.nextthink = time + 5;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/missile.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin + v_forward*8 + '0 0 16');
//MED 11/09/96
   newmis = missile;
};

/*
===============================================================================

LIGHTNING

===============================================================================
*/

/*
=================
LightningDamage
=================
*/

//Ry: Added inflictor (for use with trap_gods_wrath) and extratraces
void(vector p1, vector p2, entity from, entity inflictor, float damage, float extratraces, float ownerteam) LightningDamage =
{
	local entity		e1, e2;
	local vector		f, f2;

	f = p2 - p1; //Ry: Fixed up these calculations so the 3 beams work correctly, based on information here: https://quake.speeddemosarchive.com/quake/misc/lbug/
	f = normalize (f);
	f2_x = 0 - f_y;
	f2_y = f_x;
	f2_z = 0;
	f = f2*16;

	e1 = e2 = world;

	traceline_ignoreinvalid (p1, p2, FALSE, self, ownerteam);
  #ifdef GAME_HIPNOTIC
  //JIM
	if (trace_ent.takedamage && !trace_ent.wetsuit_finished )
  #else
  if (trace_ent.takedamage )
  #endif
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
    T_Damage (trace_ent, inflictor, from, damage); //Ry: Added inflictor to these
	}

  if (wide_lightning && extratraces) //Ry: Only do this for the Thunderbolt and Shamblers
  {
    e1 = trace_ent;

    traceline_ignoreinvalid (p1 + f, p2 + f, FALSE, self, ownerteam);
    #ifdef GAME_HIPNOTIC
    //JIM
    if (trace_ent != e1 && trace_ent.takedamage && !trace_ent.wetsuit_finished )
    #else
    if (trace_ent != e1 && trace_ent.takedamage )
    #endif
    {
      particle (trace_endpos, '0 0 100', 225, damage*4);
      T_Damage (trace_ent, inflictor, from, damage);
    }
    e2 = trace_ent;

    traceline_ignoreinvalid (p1 - f, p2 - f, FALSE, self, ownerteam);
    #ifdef GAME_HIPNOTIC
    //JIM
    if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage && !trace_ent.wetsuit_finished )
    #else
    if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage )
    #endif
    {
      particle (trace_endpos, '0 0 100', 225, damage*4);
      T_Damage (trace_ent, inflictor, from, damage);
    }
  }
};

void() W_FireLightning =
{
	local	vector		org;
	local	float		cells;
  #ifdef ENGINE_KEX
    local float oldfrags;
  #endif

	if (self.AMMO_CELLS < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

// explode if under water
	if (self.waterlevel > 1)
	{
    self.deathtype = "discharge"; //Ry: Track this better
		cells = self.AMMO_CELLS;
		self.AMMO_CELLS = 0;
    #ifdef ENGINE_KEX
      oldfrags = self.frags;
    #endif
		T_RadiusDamage (self, self, 35*cells, world);
    if (self.health > 0) //Ry: Only run this function if the player survives, since it'll soft-lock the player if they die but don't gib
    {
      W_SetCurrentAmmo ();
      #ifdef ENGINE_KEX
        //Ry: Thunderbolt Discharge achievement check [09-03-2022]
        if (self.frags > oldfrags)
        {
          msg_entity = self;
          WriteByte(MSG_ONE, SVC_ACHIEVEMENT);
          WriteString(MSG_ONE, "ACH_SURVIVE_DISCHARGE");
        }
      #endif
    }
    else
      W_UpdateAmmo();
		return;
	}

	if (self.t_width < time)
	{
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}
	self.punchangle_x = -2;

  self.currentammo = self.AMMO_CELLS -= 1;
  #ifdef GAME_ROGUE
    UpdateAmmoCounts(self);
  #endif

	org = self.origin + '0 0 16';

	traceline (org, org + v_forward*600, TRUE, self);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);

  //Ry: Added inflictor, extra traces, and blank team [07-31-2022]
	LightningDamage (self.origin, trace_endpos + v_forward*4, self, self, 30, TRUE, 0);
};


//=============================================================================


void() GrenadeExplode =
{
	T_RadiusDamage (self, self.owner, 120, world);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

void() GrenadeTouch =
{
	if (other == self.owner)
		return;		// don't explode on owner

  if (pointcontents(self.origin) == CONTENT_SKY) //Ry: Remove when fired into the sky [11-01-2022]
	{
    remove(self);
		return;
	}

	if (other.takedamage == DAMAGE_AIM)
	{
		GrenadeExplode();
		return;
	}
	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);	// bounce sound
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

/*
================
W_FireGrenade
================
*/
void() W_FireGrenade =
{
	local	entity missile;

  self.currentammo = self.AMMO_ROCKETS -= 1;
  #ifdef GAME_ROGUE
    UpdateAmmoCounts(self);
  #endif

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "grenade";

// set missile speed

	makevectors (self.v_angle);

	if (self.v_angle_x)
		missile.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		missile.velocity = aim(self, 10000);
		missile.velocity = missile.velocity * 600;
		missile.velocity_z = 200;
	}

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);

	missile.touch = GrenadeTouch;

	missile.nextthink = time + 0.05; //Ry: Implemented Remaster's downwards slope bounce fix
	missile.think = GrenadeThink;
  missile.delay = time + 2.5; //Ry: Time before explosion

	setmodel (missile, "progs/grenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};

//=============================================================================

void() spike_touch;
void() superspike_touch;
#ifdef GAME_ROGUE
  void() lavaspike_touch;
  void() superlavaspike_touch;
#endif

/*
===============
launch_spike

Used for both the player and the ogre
===============
*/
void(vector org, vector dir) launch_spike =
{
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);

	newmis.touch = spike_touch;
	newmis.classname = "spike";
	newmis.think = RemoveMissile;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	setorigin (newmis, org);

	newmis.velocity = dir * ProjectileSpeed(self,1000);
};

void() W_FireSuperSpikes =
{
	local vector	dir;

	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
  self.currentammo = self.AMMO_NAILS -= 2;
  #ifdef GAME_ROGUE
    UpdateAmmoCounts(self);
  #endif
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16', dir);
  CreateMissileField(newmis,4); //Ry: Give bigger hitbox against players in Deathmatch
	newmis.touch = superspike_touch;
  newmis.classname = "super_spike"; //Ry: Super Nail given a different class name for obituary purposes
	setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	self.punchangle_x = -2;
};

void(float ox) W_FireSpikes =
{
	local vector	dir;

	makevectors (self.v_angle);

	if (self.AMMO_NAILS >= 2 && self.weapon == IT_SUPER_NAILGUN)
	{
		W_FireSuperSpikes ();
		return;
	}

	if (self.AMMO_NAILS < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
  self.currentammo = self.AMMO_NAILS -= 1;
  #ifdef GAME_ROGUE
    UpdateAmmoCounts(self);
  #endif
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16' + v_right*ox, dir);
  CreateMissileField(newmis,6); //Ry: Give bigger hitbox against players in Deathmatch

	self.punchangle_x = -2;
};



.float hit_z;
void() spike_touch =
{
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
    RemoveMissile();
		return;
	}

// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (9);
		T_Damage (other, self, self.owner, 9);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);

		if (self.classname == "wizspike")
			WriteByte (MSG_BROADCAST, TE_WIZSPIKE);
		else if (self.classname == "knightspike")
			WriteByte (MSG_BROADCAST, TE_KNIGHTSPIKE);
		else
			WriteByte (MSG_BROADCAST, TE_SPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

  RemoveMissile();

};

void() superspike_touch =
{
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
    RemoveMissile();
		return;
	}

// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (18);
		T_Damage (other, self, self.owner, 18);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

  RemoveMissile();

};


/*
===============================================================================

PLAYER WEAPON USE

===============================================================================
*/

//MED 10/18/96 added HIPWEAPONS
void() W_SetCurrentAmmo =
{
  player_run ();		// get out of any weapon firing states

	self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS) );
  #ifdef GAME_ROGUE
    self.items2 = self.items2 - (self.items2 & (IT2_LAVA_NAILS|IT2_PLASMA_AMMO|IT2_MULTI_ROCKETS));
  #endif

	if (self.weapon == IT_AXE)
	{
		self.currentammo = 0;
		self.weaponmodel = "progs/v_axe.mdl";
		self.weaponframe = 0;
	}
  #ifdef GAME_ROGUE
    //ZOID--
    else if (self.weapon == IT_GRAPPLE)
    {
      self.currentammo = 0;
      self.weaponmodel = "progs/v_grpple.mdl";
      self.weaponframe = 0;
    }
    //--ZOID
  #endif
	else if (self.weapon == IT_SHOTGUN)
	{
    self.currentammo = self.AMMO_SHELLS;
		self.weaponmodel = "progs/v_shot.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
    self.currentammo = self.AMMO_SHELLS;
		self.weaponmodel = "progs/v_shot2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_NAILGUN)
	{
    self.currentammo = self.AMMO_NAILS;
		self.weaponmodel = "progs/v_nail.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
    self.currentammo = self.AMMO_NAILS;
		self.weaponmodel = "progs/v_nail2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
	}
  else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
    self.currentammo = self.AMMO_ROCKETS;
		self.weaponmodel = "progs/v_rock.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
    self.currentammo = self.AMMO_ROCKETS;
		self.weaponmodel = "progs/v_rock2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
    self.currentammo = self.AMMO_CELLS;
		self.weaponmodel = "progs/v_light.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_CELLS;
	}
  #ifdef GAME_HIPNOTIC
    //MED
    else if (self.weapon == IT_LASER_CANNON)
    {
      self.currentammo = self.AMMO_CELLS;
      self.weaponmodel = "progs/v_laserg.mdl";
      self.weaponframe = 0;
      self.items = self.items | IT_CELLS;
    }
    //MED
    else if (self.weapon == IT_MJOLNIR)
    {
      if (self.mjolnirdisable) //Ry: Disable Cells display while lightning attack is disabled
        self.currentammo = 0;
      else
      {
        self.currentammo = self.AMMO_CELLS;
        self.items = self.items | IT_CELLS;
      }
      self.weaponmodel = "progs/v_hammer.mdl";
      self.weaponframe = 0;
    }
    //MED
    else if (self.weapon == IT_PROXIMITY_GUN)
    {
      self.currentammo = self.AMMO_ROCKETS;
      self.weaponmodel = "progs/v_prox.mdl";
      self.weaponframe = 0;
      self.items = self.items | IT_ROCKETS;
    }
  #endif
  #ifdef GAME_ROGUE
    else if (self.weapon == IT_LAVA_NAILGUN)
    {
      self.currentammo = self.ammo_lava_nails;
      self.weaponmodel = "progs/v_lava.mdl";
      self.weaponframe = 0;
      self.items2 = self.items2 | IT2_LAVA_NAILS;
    }
    else if (self.weapon == IT_LAVA_SUPER_NAILGUN)
    {
      self.currentammo = self.ammo_lava_nails;
      self.weaponmodel = "progs/v_lava2.mdl";
      self.weaponframe = 0;
      self.items2 = self.items2 | IT2_LAVA_NAILS;
    }
    else if (self.weapon == IT_MULTI_GRENADE)
    {
      self.currentammo = self.ammo_multi_rockets;
      self.weaponmodel = "progs/v_multi.mdl";
      self.weaponframe = 0;
      self.items2 = self.items2 | IT2_MULTI_ROCKETS;
    }
    else if (self.weapon == IT_MULTI_ROCKET)
    {
      self.currentammo = self.ammo_multi_rockets;
      self.weaponmodel = "progs/v_multi2.mdl";
      self.weaponframe = 0;
      self.items2 = self.items2 | IT2_MULTI_ROCKETS;
    }
    else if (self.weapon == IT_PLASMA_GUN)
    {
      self.currentammo = self.ammo_plasma;
      self.weaponmodel = "progs/v_plasma.mdl";
      self.weaponframe = 0;
      self.items2 = self.items2 | IT2_PLASMA_AMMO;
    }
  #endif
  else
  {
    self.currentammo = 0;
    self.weaponmodel = "";
    self.weaponframe = 0;
  }
  #ifdef GAME_ROGUE
    UpdateAmmoCounts(self);
  #endif
};

float() W_BestWeapon =
{
	local	float	it;

	it = self.items;

  #ifdef GAME_ROGUE
    local vector orig, dir;
    local float rockwep, grenwep, nolava;

    //Ry: Allow BestWeapon to switch between similar explosive weapons [09-04-2022]
    if ((self.weapon == IT_ROCKET_LAUNCHER) || (self.weapon == IT_MULTI_ROCKET) || (self.weapon == IT_PLASMA_GUN))
      rockwep = TRUE;
    if ((self.weapon == IT_GRENADE_LAUNCHER) || (self.weapon == IT_MULTI_GRENADE))
      grenwep = TRUE;

    //Ry: Don't auto-switch to Lava Nailguns when fighting Hephaestus [09-26-2022]
    dir = aim(self,1000);
    orig = self.origin + '0 0 16';
    traceline(orig,orig+(dir*1000),FALSE,self);
    if (trace_ent.classname == "monster_lava_man")
      nolava = TRUE;

    if ((self.weapon == IT_MULTI_ROCKET) && (self.ammo_multi_rockets >= 1) && (it & IT_MULTI_ROCKET))
      return IT_MULTI_ROCKET;
    else if (rockwep && (self.waterlevel<=1) && (self.ammo_plasma >= 1) && (it & IT_PLASMA_GUN))
      return IT_PLASMA_GUN;
    else if (rockwep && (self.AMMO_ROCKETS >= 1) && (it & IT_ROCKET_LAUNCHER))
      return IT_ROCKET_LAUNCHER;
    else if (grenwep && (self.ammo_multi_rockets >= 1) && (it & IT_MULTI_GRENADE))
      return IT_MULTI_GRENADE;
    else if (grenwep && (self.AMMO_ROCKETS >= 1) && (it & IT_GRENADE_LAUNCHER))
      return IT_GRENADE_LAUNCHER;

    else if(self.waterlevel<=1 && self.AMMO_CELLS >=1 && (it & IT_LIGHTNING))
      return IT_LIGHTNING;
    else if(self.ammo_lava_nails >= 2 && (it & IT_LAVA_SUPER_NAILGUN) && !nolava )
      return IT_LAVA_SUPER_NAILGUN;
    else if(self.AMMO_NAILS >= 2 && (it & IT_SUPER_NAILGUN) )
      return IT_SUPER_NAILGUN;
    else if(self.ammo_lava_nails >= 1 && (it & IT_LAVA_NAILGUN) && !nolava )
      return IT_LAVA_NAILGUN;
    else if(self.AMMO_NAILS >= 1 && (it & IT_NAILGUN) )
      return IT_NAILGUN;
    else if(self.AMMO_SHELLS >= 2 && (it & IT_SUPER_SHOTGUN) )
      return IT_SUPER_SHOTGUN;
    else if(self.AMMO_SHELLS >= 1 && (it & IT_SHOTGUN) )
      return IT_SHOTGUN;
  #else
    if (self.waterlevel <= 1 && self.AMMO_CELLS >= 1 && (it & IT_LIGHTNING) )
        return IT_LIGHTNING;
    
    #ifdef GAME_HIPNOTIC
      if (self.classname == "monster_gremlin") //Ry: Gremlins don't care
        if(self.AMMO_ROCKETS >= 1 && (it & IT_ROCKET_LAUNCHER) )
          return IT_ROCKET_LAUNCHER;

      //MED
      if(self.AMMO_CELLS >= 1 && (it & IT_LASER_CANNON) )
        return IT_LASER_CANNON;
    #endif
    else if(self.AMMO_NAILS >= 2 && (it & IT_SUPER_NAILGUN) )
      return IT_SUPER_NAILGUN;
    
    #ifdef GAME_HIPNOTIC
      if (self.classname == "monster_gremlin") //Ry: Gremlins don't care, Pt 2
        if(self.AMMO_ROCKETS >= 1 && (it & IT_PROXIMITY_GUN) ) //Ry: Added Proxy Gun
          return IT_PROXIMITY_GUN;
        else if(self.AMMO_ROCKETS >= 1 && (it & IT_GRENADE_LAUNCHER) )
          return IT_GRENADE_LAUNCHER;
    #endif
    if(self.AMMO_SHELLS >= 2 && (it & IT_SUPER_SHOTGUN) )
      return IT_SUPER_SHOTGUN;
    else if(self.AMMO_NAILS >= 1 && (it & IT_NAILGUN) )
      return IT_NAILGUN;
    else if(self.AMMO_SHELLS >= 1 && (it & IT_SHOTGUN) )
      return IT_SHOTGUN;
    #ifdef GAME_HIPNOTIC
      //MED
      else if( it & IT_MJOLNIR && (self.waterlevel <= 0 || self.AMMO_CELLS < 15) ) //Ry: Avoid drawing Mjolnir in water when it has a charge
        return IT_MJOLNIR;
    #endif
  #endif

	return IT_AXE;
};

/*
============
W_Attack

An attack impulse can be triggered now
============
*/
void()	player_axe1;
void()	player_axeb1;
void()	player_axec1;
void()	player_axed1;
void()	player_shot1;
void()	player_nail1;
void()	player_light1;
void()	player_rocket1;
#ifdef GAME_HIPNOTIC
  //MED
  void()  player_laser1;
  void()  player_hammer1;
  void()  player_mjolnir1;
  void()  W_FireProximityGrenade;
#endif
#ifdef GAME_ROGUE
  void()	player_lava_nail1;
  //ZOID--
  void()  player_grapple1;
  void()  player_grapple3;
  //--ZOID

  void()  player_plasma1;

  void() W_FireMultiGrenade;
  void() W_FireMultiRocket;
#endif


void() W_Attack =
{
	local	float	r;

	if (!W_CheckNoAmmo ())
		return;

	makevectors	(self.v_angle);			// calculate forward angle for velocity

  #ifdef GAME_HIPNOTIC
  if ( (self.weapon != IT_AXE) && (self.weapon != IT_MJOLNIR) ) //Ry: For the Pacifist achievement
  #else
  if ( self.weapon != IT_AXE )
  #endif
	{
		ach_weaponfired = TRUE;
    self.show_hostile = time + 1;	// wake monsters up //Ry: But exclude the melee weapons
	}

	if (self.weapon == IT_AXE)
	{
    self.lastfiredweapon = IT_AXE; //Ry: Track which weapon was last fired
		sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);
		r = random();
		if (r < 0.25)
			player_axe1 ();
		else if (r<0.5)
			player_axeb1 ();
		else if (r<0.75)
			player_axec1 ();
		else
			player_axed1 ();
    #ifdef GAME_ROGUE
      self.attack_finished = time + RuneApplyHell(0.5, self);
    #else
      self.attack_finished = time + 0.5;
    #endif
	}
  #ifdef GAME_ROGUE
    //ZOID--
    else if (self.weapon == IT_GRAPPLE)
    {
      //Ry: Must repress fire if the hook breaks [09-09-2022]
      if (self.hookstatus != HOOK_RELEASED)
      {
        self.lastfiredweapon = IT_GRAPPLE;
        if (self.hookstatus < HOOK_FIRED)
          player_grapple1();
        else
          player_grapple3();
        self.attack_finished = time + 0.1;
      }
    }
    //--ZOID
  #endif
	else if (self.weapon == IT_SHOTGUN)
	{
    self.lastfiredweapon = IT_SHOTGUN;
		player_shot1 ();
		W_FireShotgun ();
    #ifdef GAME_ROGUE
      self.attack_finished = time + RuneApplyHell(0.5, self);
    #else
      self.attack_finished = time + 0.5;
    #endif
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
    self.lastfiredweapon = IT_SUPER_SHOTGUN;
		player_shot1 ();
		W_FireSuperShotgun ();
    #ifdef GAME_ROGUE
      self.attack_finished = time + RuneApplyHell(0.7, self);
    #else
      self.attack_finished = time + 0.7;
    #endif
	}
  #ifdef GAME_ROGUE
    else if (self.weapon == IT_LAVA_NAILGUN)
    {
      self.lastfiredweapon = IT_LAVA_NAILGUN;
      self.lavagunfired = TRUE;
      player_lava_nail1 ();
    }
    else if (self.weapon == IT_LAVA_SUPER_NAILGUN)
    {
      self.lastfiredweapon = IT_LAVA_SUPER_NAILGUN;
      self.lavagunfired = TRUE;
      player_lava_nail1 ();
    }
    else if (self.weapon == IT_MULTI_GRENADE)
    {
      self.lastfiredweapon = IT_MULTI_GRENADE;
      player_rocket1();
      W_FireMultiGrenade();
      self.attack_finished = time + RuneApplyHell(0.6, self);
    }
    else if (self.weapon == IT_MULTI_ROCKET)
    {
      self.lastfiredweapon = IT_MULTI_ROCKET;
      player_rocket1();
      W_FireMultiRocket();
      self.attack_finished = time + RuneApplyHell(0.8, self);
    }
    else if (self.weapon == IT_PLASMA_GUN)
    {
      self.lastfiredweapon = IT_PLASMA_GUN;
      self.attack_finished = time + RuneApplyHell(1.0, self);
      player_plasma1 (); //Ry: New animation [09-10-2022]
    }
  #endif
	else if (self.weapon == IT_NAILGUN)
	{
    self.lastfiredweapon = IT_NAILGUN;
		player_nail1 ();
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
    self.lastfiredweapon = IT_SUPER_NAILGUN;
		player_nail1 ();
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
    self.lastfiredweapon = IT_GRENADE_LAUNCHER;
		player_rocket1();
		W_FireGrenade();
    #ifdef GAME_ROGUE
      self.attack_finished = time + RuneApplyHell(0.6, self);
    #else
      self.attack_finished = time + 0.6;
    #endif
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
    self.lastfiredweapon = IT_ROCKET_LAUNCHER;
		player_rocket1();
		W_FireRocket();
    #ifdef GAME_ROGUE
      self.attack_finished = time + RuneApplyHell(0.8, self);
    #else
      self.attack_finished = time + 0.8;
    #endif
	}
	else if (self.weapon == IT_LIGHTNING)
	{
    self.lastfiredweapon = IT_LIGHTNING;
		player_light1();
		self.attack_finished = time + 0.1;
		sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
	}
  #ifdef GAME_HIPNOTIC
    //MED
    else if (self.weapon == IT_LASER_CANNON)
    {
      self.lastfiredweapon = IT_LASER_CANNON;
      player_laser1();
    }
    //MED
    else if (self.weapon == IT_MJOLNIR)
    {
      self.lastfiredweapon = IT_MJOLNIR;
      if (self.AMMO_CELLS < 30)
        player_hammer1();
      else
        player_mjolnir1();
      #ifdef GAME_ROGUE
        self.attack_finished = time + RuneApplyHell(0.8, self);
      #else
        self.attack_finished = time + 0.8;
      #endif
    }
    //MED
    else if (self.weapon == IT_PROXIMITY_GUN)
    {
      self.lastfiredweapon = IT_PROXIMITY_GUN;
      player_rocket1();
      W_FireProximityGrenade();
      #ifdef GAME_ROGUE
        self.attack_finished = time + RuneApplyHell(0.6, self);
      #else
        self.attack_finished = time + 0.6;
      #endif
    }
  #endif
};

/*
============
W_ChangeWeapon

============
*/
//MED 10/18/96 added hipweapons
void() W_ChangeWeapon =
{
	local	float	it, am, fl;

  local string ammoreason = "Not enough ammo\n"; //Set these to explain why a weapon can't be switched to
  local string weapreason = "No weapon\n";

  #ifdef GAME_ROGUE
    EnableComboWeapons ( self );
    UpdateAmmoCounts ( self );
  #endif

	it = self.items;
	am = 0;

//MED
	if (self.impulse == 1)
	{
    weapreason = "No Axe\n";
    fl = IT_AXE;
    #ifdef GAME_ROGUE
      if ((self.items & IT_GRAPPLE) && (self.weapon != IT_GRAPPLE))
      {
        weapreason = "No Grapple Hook\n";
        fl = IT_GRAPPLE;
      }
    #endif
  }
  #ifdef GAME_ROGUE
    else if (self.impulse == 22)
    {
      weapreason = "No Grapple Hook\n";
      fl = IT_GRAPPLE;
    }
  #endif
	else if (self.impulse == 2)
	{
    weapreason = "No Shotgun\n";
    ammoreason = "Not enough Shells\n";
		fl = IT_SHOTGUN;
		if (self.AMMO_SHELLS < 1)
			am = 1;
	}
	else if (self.impulse == 3)
	{
    weapreason = "No Double-Barreled Shotgun\n";
    ammoreason = "Not enough Shells\n";
		fl = IT_SUPER_SHOTGUN;
		if (self.AMMO_SHELLS < 2)
			am = 1;
	}
	else if (self.impulse == 4)
	{
    #ifdef GAME_ROGUE
      if ((self.items & IT_NAILGUN) &&
          ( (self.weapon == IT_NAILGUN) || ((self.AMMO_NAILS < 1) && (self.ammo_lava_nails >= 1)) ) )
      {
        //Ry: Treat a lack of the weapon as a lack of ammo
        weapreason = "Not enough Lava Nails\n";
        ammoreason = "Not enough Lava Nails\n";
        fl = IT_LAVA_NAILGUN;
        if (self.ammo_lava_nails < 1)
          am = 1;
      }
      else
      {
        weapreason = "No Nailgun\n";
        ammoreason = "Not enough Nails\n";
        fl = IT_NAILGUN;
        if (self.AMMO_NAILS < 1)
          am = 1;
      }
    #else
      weapreason = "No Nailgun\n";
      ammoreason = "Not enough Nails\n";
      fl = IT_NAILGUN;
      if (self.AMMO_NAILS < 1)
        am = 1;
    #endif
	}
	else if (self.impulse == 5)
	{
    #ifdef GAME_ROGUE
      if ((self.items & IT_SUPER_NAILGUN) && 
          (self.weapon == IT_SUPER_NAILGUN || ((self.AMMO_NAILS < 2) && (self.ammo_lava_nails >= 2))))
      {
        weapreason = "Not enough Lava Nails\n";
        ammoreason = "Not enough Lava Nails\n";
        fl = IT_LAVA_SUPER_NAILGUN;
        if (self.ammo_lava_nails < 2)
          am = 1;
      }
      else
      {
        weapreason = "No Super Nailgun\n";
        ammoreason = "Not enough Nails\n";
        fl = IT_SUPER_NAILGUN;
        if (self.AMMO_NAILS < 2)
          am = 1;
      }
    #else
      weapreason = "No Super Nailgun\n";
      ammoreason = "Not enough Nails\n";
      fl = IT_SUPER_NAILGUN;
      if (self.AMMO_NAILS < 2)
        am = 1;
    #endif
	}
	else if (self.impulse == 6)
	{
    #ifdef GAME_ROGUE
      if ((self.items & IT_GRENADE_LAUNCHER) && 
          (self.weapon == IT_GRENADE_LAUNCHER || ((self.AMMO_ROCKETS < 1) && (self.ammo_multi_rockets >= 1))))
      {
        weapreason = "Not enough Multi Rockets\n";
        ammoreason = "Not enough Multi Rockets\n";
        fl = IT_MULTI_GRENADE;
        if (self.ammo_multi_rockets < 1)
          am = 1;
      }
      else
      {
        weapreason = "No Grenade Launcher\n";
        ammoreason = "Not enough Rockets\n";
        fl = IT_GRENADE_LAUNCHER;
        if (self.AMMO_ROCKETS < 1)
          am = 1;
      }
    #else
      ammoreason = "Not enough Rockets\n";
      #ifdef GAME_HIPNOTIC
      if (self.weapon == IT_GRENADE_LAUNCHER)
      {
        weapreason = "No Proximity Gun\n";
        fl = IT_PROXIMITY_GUN;
      }
      else
      {
      #endif
        weapreason = "No Grenade Launcher\n";
        fl = IT_GRENADE_LAUNCHER;
      #ifdef GAME_HIPNOTIC
      }
      #endif
      if (self.AMMO_ROCKETS < 1)
        am = 1;
    #endif
	}
	else if (self.impulse == 7)
	{
    #ifdef GAME_ROGUE
      if ((self.items & IT_ROCKET_LAUNCHER) && 
        (self.weapon == IT_ROCKET_LAUNCHER || ((self.AMMO_ROCKETS < 1) && (self.ammo_multi_rockets >= 1))))
      {
        weapreason = "Not enough Multi Rockets\n";
        ammoreason = "Not enough Multi Rockets\n";
        fl = IT_MULTI_ROCKET;
        if (self.ammo_multi_rockets < 1)
          am = 1;
      }
      else
      {
        weapreason = "No Rocket Launcher\n";
        ammoreason = "Not enough Rockets\n";
        fl = IT_ROCKET_LAUNCHER;
        if (self.AMMO_ROCKETS < 1)
          am = 1;
      }
    #else
      weapreason = "No Rocket Launcher\n";
      ammoreason = "Not enough Rockets\n";
      fl = IT_ROCKET_LAUNCHER;
      if (self.AMMO_ROCKETS < 1)
        am = 1;
    #endif
	}
	else if (self.impulse == 8)
	{
    #ifdef GAME_ROGUE
      if ((self.items & IT_LIGHTNING) && 
          (self.weapon == IT_LIGHTNING || ((self.AMMO_CELLS < 1) && (self.ammo_plasma >= 1))))
      {
        weapreason = "Not enough Plasma\n";
        ammoreason = "Not enough Plasma\n";
        fl = IT_PLASMA_GUN;
        if (self.ammo_plasma < 1)
          am = 1;
      }
      else
      {
        weapreason = "No Thunderbolt\n";
        ammoreason = "Not enough Cells\n";
        fl = IT_LIGHTNING;
        if (self.AMMO_CELLS < 1)
          am = 1;
      }
    #else
      weapreason = "No Thunderbolt\n";
      ammoreason = "Not enough Cells\n";
      fl = IT_LIGHTNING;
      if (self.AMMO_CELLS < 1)
        am = 1;
    #endif
  }
  #ifdef GAME_ROGUE
    else if (self.impulse == 60)
    {
      //Ry: Check if we have the original weapon, and give appropriate message
      if (self.items & IT_NAILGUN)
        weapreason = "Not enough Lava Nails\n";
      else
        weapreason = "No Nailgun to use Lava Nails\n";
      ammoreason = "Not enough Lava Nails\n";
      fl = IT_LAVA_NAILGUN;
      if (self.ammo_lava_nails < 1)
        am = 1;
    }
    else if (self.impulse == 61)
    {
      if (self.items & IT_SUPER_NAILGUN)
        weapreason = "Not enough Lava Nails\n";
      else
        weapreason = "No Super Nailgun to use Lava Nails\n";
      ammoreason = "Not enough Lava Nails\n";
      fl = IT_LAVA_SUPER_NAILGUN;
      if (self.ammo_lava_nails < 1)
        am = 1;
    }
    else if (self.impulse == 62)
    {
      if (self.items & IT_GRENADE_LAUNCHER)
        weapreason = "Not enough Multi Rockets\n";
      else
        weapreason = "No Grenade Launcher to use Multi Rockets\n";
      ammoreason = "Not enough Multi Rockets\n";
      fl = IT_MULTI_GRENADE;
      if (self.ammo_multi_rockets < 1)
        am = 1;
    }
    else if (self.impulse == 63)
    {
      if (self.items & IT_ROCKET_LAUNCHER)
        weapreason = "Not enough Multi Rockets\n";
      else
        weapreason = "No Rocket Launcher to use Multi Rockets\n";
      ammoreason = "Not enough Multi Rockets\n";
      fl = IT_MULTI_ROCKET;
      if (self.ammo_multi_rockets < 1)
        am = 1;
    }
    else if (self.impulse == 64)
    {
      if (self.items & IT_LIGHTNING)
        weapreason = "Not enough Plasma\n";
      else
        weapreason = "No Thunderbolt to use Plasma\n";
      ammoreason = "Not enough Plasma\n";
      fl = IT_PLASMA_GUN;
      if (self.ammo_plasma < 1)
        am = 1;
    }
    else if (self.impulse == 65) //Ry: Remaster binds for the basic weapons
    {
      weapreason = "No Nailgun\n";
      ammoreason = "Not enough Nails\n";
      fl = IT_NAILGUN;
      if (self.AMMO_NAILS < 1)
        am = 1;
    }
    else if (self.impulse == 66)
    {
      weapreason = "No Super Nailgun\n";
      ammoreason = "Not enough Nails\n";
      fl = IT_SUPER_NAILGUN;
      if (self.AMMO_NAILS < 1)
        am = 1;
    }
    else if (self.impulse == 67)
    {
      weapreason = "No Grenade Launcher\n";
      ammoreason = "Not enough Rockets\n";
      fl = IT_GRENADE_LAUNCHER;
      if (self.AMMO_ROCKETS < 1)
        am = 1;
    }
    else if (self.impulse == 68)
    {
      weapreason = "No Rocket Launcher\n";
      ammoreason = "Not enough Rockets\n";
      fl = IT_ROCKET_LAUNCHER;
      if (self.AMMO_ROCKETS < 1)
        am = 1;
    }
    else if (self.impulse == 69) //Ry: Remaster doesn't even have this impulse normally
    {
      weapreason = "No Thunderbolt\n";
      ammoreason = "Not enough Cells\n";
      fl = IT_LIGHTNING;
      if (self.AMMO_CELLS < 1)
        am = 1;
    }
  #endif
  #ifdef GAME_HIPNOTIC
    else if (self.impulse == 225)
    {
      weapreason = "No Laser Cannon\n";
      ammoreason = "Not enough Cells\n";
      fl = IT_LASER_CANNON;
      if (self.AMMO_CELLS < 1)
        am = 1;
    }
    else if (self.impulse == 226)
    {
      weapreason = "No Mjolnir\n";
      fl = IT_MJOLNIR;
    }
    else if (self.impulse == 227) //Ry: Re-implemented Remaster impulses for individual Proxy/Grenade
    {
      weapreason = "No Proximity Gun\n";
      ammoreason = "Not enough Rockets\n";
      fl = IT_PROXIMITY_GUN;
      if (self.AMMO_ROCKETS < 1)
        am = 1;
    }
    else if (self.impulse == 228)
    {
      weapreason = "No Grenade Launcher\n";
      ammoreason = "Not enough Rockets\n";
      fl = IT_GRENADE_LAUNCHER;
      if (self.AMMO_ROCKETS < 1)
        am = 1;
    }
    else if (self.impulse == 229) //Ry: Selects Thunderbolt, and then the Laser Cannon
    {
      ammoreason = "Not enough Cells\n";
      if (self.weapon == IT_LIGHTNING)
      {
        weapreason = "No Laser Cannon\n";
        fl = IT_LASER_CANNON;
      }
      else
      {
        weapreason = "No Thunderbolt\n";
        fl = IT_LIGHTNING;
      }
      if (self.AMMO_CELLS < 1)
        am = 1;
    }
  #endif

	if (!(self.items & fl))
  {
    #ifdef GAME_HIPNOTIC
    //MED  //Ry: Check if not already on the Proxy gun, and only do it for the regular impulse
    if ( (self.impulse == 6) && (!(self.weapon == IT_PROXIMITY_GUN)) )
    {
      fl = IT_PROXIMITY_GUN;
      if (!(self.items & fl))
      {
        sprint (self, weapreason);
        return;
      }
    }
    //Ry: Select Laser Cannon if player doesn't have the Thunderbolt for this impulse
    else if ( (self.impulse == 229) && (!(self.weapon == IT_LASER_CANNON)) )
    {
      fl = IT_LASER_CANNON;
      if (!(self.items & fl))
      {
        sprint (self, weapreason);
        return;
      }
    }
    else
    {
    #endif
      sprint (self, weapreason);
      return;
    #ifdef GAME_HIPNOTIC
    }
    #endif
  }

	if (am)
	{	// don't have the ammo
		sprint (self, ammoreason);
		return;
	}
  
  #ifdef GAME_HIPNOTIC
    if (fl == IT_MJOLNIR)
    {
      if ( !(self.weapon == IT_MJOLNIR) )
      {
        self.impulse = 0;
        self.mjolnirdisable = FALSE;
        if (self.AMMO_CELLS < 15) //Ry: Give warning if you don't have enough Cells to do the Mjolnir attack
          sprint (self, "Low Cells\n");
      }
      else if (!deathmatch) //Ry: Toggle Mjolnir's electrical attack if the impulse is used again
      {
        if ((self.lastimpulse == self.impulse) && (time < self.lastimpulsetime + 0.2)) //Ry: Double tap the appropriate key
        {
          self.impulse = 0;
          if (self.mjolnirdisable)
          {
            sprint(self,"Mjolnir Strike enabled\n");
            self.mjolnirdisable = FALSE;
          }
          else
          {
            sprint(self,"Mjolnir Strike disabled\n");
            self.mjolnirdisable = TRUE;
          }
        }
      }
    }
  #endif
  #ifdef GAME_ROGUE
    if (self.weapon != fl)
    {
      if (self.weapon == IT_LAVA_NAILGUN || 
          self.weapon == IT_LAVA_SUPER_NAILGUN)
      {
        if (fl == IT_NAILGUN || fl == IT_SUPER_NAILGUN)
          sprint (self, "Normal Nails\n");
      }
      else if (self.weapon == IT_MULTI_GRENADE)
      {
        if (fl == IT_GRENADE_LAUNCHER)
          sprint (self, "Normal Grenades\n");
      }
      else if (self.weapon == IT_MULTI_ROCKET)
      {
        if (fl == IT_ROCKET_LAUNCHER)
          sprint (self, "Normal Rockets\n");
      }
      else if (self.weapon == IT_PLASMA_GUN)
      {
        if (fl == IT_LIGHTNING)
          sprint (self, "Lightning Gun\n");
      }
      else if (fl == IT_LAVA_NAILGUN || fl == IT_LAVA_SUPER_NAILGUN)
      {
        sprint (self, "Lava Nails!\n");
      }
      else if(fl == IT_MULTI_GRENADE)
      {
        sprint (self, "Multi-Grenades!\n");
      }
      else if(fl == IT_MULTI_ROCKET)
      {
        sprint (self, "Multi-Rockets!\n");
      }
      else if(fl == IT_PLASMA_GUN)
      {
        sprint (self, "Plasma Gun!\n");
      }
    }
  #endif

//
// set weapon, set ammo
//
  self.weapon = fl;
	W_SetCurrentAmmo ();
};

/*
============
CheatCommand
============
*/

void(float key_item) horde_key_give;

void() CheatCommand =
{
  if ( !CheatsAllowed() ) //Ry: New check for if cheats are allowed [07-23-2022]
    return;

  //Ry: Reordered stuff here; It was bugging me [08-02-2022]
  self.AMMO_SHELLS = 100;
  self.AMMO_NAILS = 200;
  self.AMMO_ROCKETS = ammocap_rockets;
  self.AMMO_CELLS = 100; //Ry: Changed to actual ammo limit
  #ifdef GAME_ROGUE
    self.ammo_lava_nails = ammocap_lava;
    self.ammo_multi_rockets = ammocap_multi;
    self.ammo_plasma = ammocap_plasma;
  #endif

	self.items = self.items |
		IT_AXE |
		IT_SHOTGUN |
		IT_SUPER_SHOTGUN |
		IT_NAILGUN |
		IT_SUPER_NAILGUN |
		IT_GRENADE_LAUNCHER |
		IT_ROCKET_LAUNCHER |
    IT_LIGHTNING;

  #ifdef GAME_HIPNOTIC
    //MED
    self.items = self.items | IT_LASER_CANNON | IT_MJOLNIR | IT_PROXIMITY_GUN;
  #endif
  #ifdef GAME_ROGUE
    self.items = self.items | 
      IT_LAVA_NAILGUN | 
      IT_LAVA_SUPER_NAILGUN | 
      IT_MULTI_GRENADE |
      IT_MULTI_ROCKET | 
      IT_PLASMA_GUN;
  #endif

  if (horde_ent) //Ry: Add each key properly in Horde mode [08-02-2022]
  {
    if (keys_silver < 1)
    {
      horde_key_give(IT_KEY1);
      keys_silver = 9;
    }
    if (keys_gold < 1)
    {
      horde_key_give(IT_KEY2);
      keys_gold = 9;
    }
  }
  else
		self.items = self.items | IT_KEY1 | IT_KEY2;

	// mal: also give full armor...
	self.armortype = 0.8;
	self.armorvalue = 200;
  #ifdef GAME_ROGUE
    self.items2 = self.items2 - ( self.items2 & ( IT2_ARMOR1 | IT2_ARMOR2 | IT2_ARMOR3 ) ) + IT2_ARMOR3;
  #else
    self.items = self.items - ( self.items & ( IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3 ) ) + IT_ARMOR3;
  #endif

	self.weapon = IT_ROCKET_LAUNCHER;
	self.impulse = 0;
	W_SetCurrentAmmo ();
  if (deathmatch || coop)
  {
    bprint(self.netname);
    bprint(" used All Weapons cheat\n");
  }
};

/*
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void() CycleWeaponCommand =
{
	local	float	it;

  #ifdef GAME_ROGUE
    EnableComboWeapons ( self );
    UpdateAmmoCounts ( self );
  #endif

	it = self.items;
	self.impulse = 0;

  #ifdef GAME_HIPNOTIC
    self.mjolnirdisable = FALSE;
  #endif

	while (1) //Ry: Condensed this a lot [08-30-2022]
	{
		cyclestate = CYCLE_CONTINUE;

    TryCycleWeapon(IT_SHOTGUN,IT_SUPER_SHOTGUN,2);
    TryCycleWeapon(IT_SUPER_SHOTGUN,IT_NAILGUN,1);
    #ifdef GAME_ROGUE
      TryCycleWeapon(IT_NAILGUN,IT_LAVA_NAILGUN,1);
      TryCycleWeapon(IT_LAVA_NAILGUN,IT_SUPER_NAILGUN,2);
      TryCycleWeapon(IT_SUPER_NAILGUN,IT_LAVA_SUPER_NAILGUN,2);
      TryCycleWeapon(IT_LAVA_SUPER_NAILGUN,IT_GRENADE_LAUNCHER,1);
      TryCycleWeapon(IT_GRENADE_LAUNCHER,IT_MULTI_GRENADE,1);
      TryCycleWeapon(IT_MULTI_GRENADE,IT_ROCKET_LAUNCHER,1);
      TryCycleWeapon(IT_ROCKET_LAUNCHER,IT_MULTI_ROCKET,1);
      TryCycleWeapon(IT_MULTI_ROCKET,IT_LIGHTNING,1);
      TryCycleWeapon(IT_LIGHTNING,IT_PLASMA_GUN,1);
      TryCycleWeapon(IT_PLASMA_GUN,IT_AXE,0);
      if (grappleenabled)
        TryCycleWeapon(IT_AXE,IT_GRAPPLE,0);
      TryCycleWeapon(IT_GRAPPLE,IT_SHOTGUN,1);
      TryCycleWeapon(IT_AXE,IT_SHOTGUN,1);
    #else
      TryCycleWeapon(IT_NAILGUN,IT_SUPER_NAILGUN,2);
      TryCycleWeapon(IT_SUPER_NAILGUN,IT_GRENADE_LAUNCHER,1);
      #ifdef GAME_HIPNOTIC
        TryCycleWeapon(IT_GRENADE_LAUNCHER,IT_PROXIMITY_GUN,1);
        TryCycleWeapon(IT_PROXIMITY_GUN,IT_ROCKET_LAUNCHER,1);
        TryCycleWeapon(IT_ROCKET_LAUNCHER,IT_LIGHTNING,1);
        TryCycleWeapon(IT_LIGHTNING,IT_LASER_CANNON,1);
        TryCycleWeapon(IT_LASER_CANNON,IT_MJOLNIR,0);
        TryCycleWeapon(IT_MJOLNIR,IT_AXE,0);
      #else
        TryCycleWeapon(IT_GRENADE_LAUNCHER,IT_ROCKET_LAUNCHER,1);
        TryCycleWeapon(IT_ROCKET_LAUNCHER,IT_LIGHTNING,1);
        TryCycleWeapon(IT_LIGHTNING,IT_AXE,0);
      #endif
      TryCycleWeapon(IT_AXE,IT_SHOTGUN,1);
    #endif

		if ( (self.items & self.weapon) && (cyclestate != CYCLE_NOAMMO) )
		{
			W_SetCurrentAmmo ();
			return;
		}
	}

};

/*
============
CycleWeaponReverseCommand

Go to the prev weapon with ammo
============
*/
void() CycleWeaponReverseCommand =
{
	local	float	it;

  #ifdef GAME_ROGUE
    EnableComboWeapons ( self );
    UpdateAmmoCounts ( self );
  #endif

	it = self.items;
	self.impulse = 0;

  #ifdef GAME_HIPNOTIC
    self.mjolnirdisable = FALSE;
  #endif

	while (1)
	{
		cyclestate = CYCLE_CONTINUE;
    
    #ifdef GAME_ROGUE
      if (grappleenabled)
        TryCycleWeapon(IT_SHOTGUN,IT_GRAPPLE,0);
      TryCycleWeapon(IT_SHOTGUN,IT_AXE,0);
      TryCycleWeapon(IT_GRAPPLE,IT_AXE,0);
      TryCycleWeapon(IT_AXE,IT_PLASMA_GUN,1);
      TryCycleWeapon(IT_PLASMA_GUN,IT_LIGHTNING,1);
      TryCycleWeapon(IT_LIGHTNING,IT_MULTI_ROCKET,1);
      TryCycleWeapon(IT_MULTI_ROCKET,IT_ROCKET_LAUNCHER,1);
      TryCycleWeapon(IT_ROCKET_LAUNCHER,IT_MULTI_GRENADE,1);
      TryCycleWeapon(IT_MULTI_GRENADE,IT_GRENADE_LAUNCHER,1);
      TryCycleWeapon(IT_GRENADE_LAUNCHER,IT_LAVA_SUPER_NAILGUN,2);
      TryCycleWeapon(IT_LAVA_SUPER_NAILGUN,IT_SUPER_NAILGUN,2);
      TryCycleWeapon(IT_SUPER_NAILGUN,IT_LAVA_NAILGUN,1);
      TryCycleWeapon(IT_LAVA_NAILGUN,IT_NAILGUN,1);
    #else
      TryCycleWeapon(IT_SHOTGUN,IT_AXE,0);
      #ifdef GAME_HIPNOTIC
        TryCycleWeapon(IT_AXE,IT_MJOLNIR,0);
        TryCycleWeapon(IT_MJOLNIR,IT_LASER_CANNON,1);
        TryCycleWeapon(IT_LASER_CANNON,IT_LIGHTNING,1);
        TryCycleWeapon(IT_LIGHTNING,IT_ROCKET_LAUNCHER,1);
        TryCycleWeapon(IT_ROCKET_LAUNCHER,IT_PROXIMITY_GUN,1);
        TryCycleWeapon(IT_PROXIMITY_GUN,IT_GRENADE_LAUNCHER,1);
      #else
        TryCycleWeapon(IT_AXE,IT_LIGHTNING,1);
        TryCycleWeapon(IT_LIGHTNING,IT_ROCKET_LAUNCHER,1);
        TryCycleWeapon(IT_ROCKET_LAUNCHER,IT_GRENADE_LAUNCHER,1);
      #endif
      TryCycleWeapon(IT_GRENADE_LAUNCHER,IT_SUPER_NAILGUN,2);
      TryCycleWeapon(IT_SUPER_NAILGUN,IT_NAILGUN,1);
    #endif
    TryCycleWeapon(IT_NAILGUN,IT_SUPER_SHOTGUN,2);
    TryCycleWeapon(IT_SUPER_SHOTGUN,IT_SHOTGUN,1);

		if ( (it & self.weapon) && (cyclestate != CYCLE_NOAMMO) )
		{
			W_SetCurrentAmmo ();
			return;
		}
	}

};

/*
============
ServerflagsCommand

Just for development
============
*/
void() ServerflagsCommand =
{
	serverflags = serverflags * 2 + 1;
};

void() QuadCheat =
{
  if ( !CheatsAllowed() ) //Ry: New check for if cheats are allowed [07-23-2022]
    return;
  self.items = self.items | IT_QUAD;
	self.super_time = 1;
	self.super_damage_finished = time + 30;
  self.super_item = world;
  self.super_validdroptime = 0;
  if (deathmatch || coop) //Ry: Announce who used the cheat in multiplayer
  {
    bprint (self.netname);
    bprint (" used Quad cheat\n");
  }
  else
    bprint ("Quad cheat\n");
};

#ifdef GAME_HIPNOTIC
  //MED
  void() WetsuitCheat =
  {
    if ( !CheatsAllowed() ) //Ry: New check for if cheats are allowed [07-23-2022]
      return;
    self.items2 = self.items2 | HIP_IT_WETSUIT;
    self.wetsuit_time = 1;
    self.wetsuit_finished = time + 30;
    self.wetsuit_item = world;
    self.wetsuit_validdroptime = 0;
    if (deathmatch || coop) //Ry: Announce who used the cheat in multiplayer
    {
      bprint (self.netname);
      bprint (" used Wetsuit cheat\n");
    }
    else
      bprint("Wetsuit cheat\n");
  };

  //MED
  void() EmpathyShieldsCheat =
  {
    if ( !CheatsAllowed() ) //Ry: New check for if cheats are allowed [07-23-2022]
      return;
    self.items2 = self.items2 | HIP_IT_EMPATHY_SHIELDS;
    self.empathy_time = 1;
    self.empathy_finished = time + 30;
    self.empathy_item = world;
    self.empathy_validdroptime = 0;
    if (deathmatch || coop) //Ry: Announce who used the cheat in multiplayer
    {
      bprint (self.netname);
      bprint (" used Empathy Shields cheat\n");
    }
    else
      bprint("Empathy Shields cheat\n");
  };
#endif

#ifdef GAME_ROGUE
  //Ry: New cheats for Rogue powerups [09-19-2022]
  void() AntiGravCheat =
  {
    if ( !CheatsAllowed() )
      return;
    self.items2 = self.items2 | IT2_ANTIGRAV;
    self.antigrav_time = 1;
    self.antigrav_finished = time + 45;
    self.antigrav_item = world;
    self.antigrav_validdroptime = 0;
    if (deathmatch || coop)
    {
      bprint (self.netname);
      bprint (" used Anti-Grav Belt cheat\n");
    }
    else
      bprint("Anti-Grav Belt cheat\n");
  };

  void() PowerShieldCheat =
  {
    if ( !CheatsAllowed() )
      return;
    self.items2 = self.items2 | IT2_SHIELD;
    self.shield_time = 1;
    self.shield_finished = time + 30;
    self.shield_item = world;
    self.shield_validdroptime = 0;
    if (deathmatch || coop)
    {
      bprint (self.netname);
      bprint (" used Power Shield cheat\n");
    }
    else
      bprint("Power Shield cheat\n");
  };
#endif

void() DumpEntities =
   {
   local entity   head;
   local float i;

   i = 1;
   head = nextent(world);
   while (head!=world)
      {
      dprint(ftos(i));
      dprint(" ");
      dprint(head.classname);
      dprint("\n");
      head = nextent(head);
      i = i + 1;
      }
   };

void() DumpLiveEntities =
   {
   local entity   head;
   local float i;

   i = 1;
   head = nextent(world);
   while (head!=world)
      {
      if (head.health > 0)
         {
         dprint(ftos(i));
         dprint(" ");
         dprint(head.classname);
         dprint(" ");
         dprint(vtos(head.origin));
         dprint("\n");
         dprint("--------------------\n");
         }
      head = nextent(head);
      i = i + 1;
      }
   };

void() Genocide =
{
  local entity   head;

  if ( !CheatsAllowed() ) //Ry: New check for if cheats are allowed [07-23-2022]
    return;
  bprint("Genocide!\n");
  head = nextent(world);
  while (head!=world)
  {
    if ((head.health > 0) && (head.flags & FL_MONSTER))
    {
      #ifdef GAME_ROGUE
      if (head.classname != "item_time_machine") //Ry: Don't kill the Time Machine
      #endif
        T_Damage(head,world,world,head.health+10);
    }
    head = nextent(head);
  }
};

float dump_coord;
void () ToggleDump =
   {
   dump_coord = 1 - dump_coord;
   if (dump_coord == 1)
      bprint("Dumping Player Location\n");
   };
void () DumpCoordinates =
   {
   local entity pl;
   pl = checkclient();
   if (pl)
      {
      bprint("Player: ");
      bprint(vtos(pl.origin));
      bprint("\n");
      }
   };

/*
============
ImpulseCommands

============
*/
void() ImpulseCommands =
{
  if (self.impulse)
  {
    if (self.impulse >= 1 && self.impulse <= 8)
      W_ChangeWeapon ();

    //Ry: Added standalone binds from Remaster
    #ifdef GAME_ROGUE
      else if (self.impulse >= 60 && self.impulse <= 69)
        W_ChangeWeapon ();
    #endif
    #ifdef GAME_HIPNOTIC
      else if (self.impulse >= 225 && self.impulse <= 229)
        W_ChangeWeapon ();
    #endif

    else if (self.impulse == 9)
      CheatCommand ();
    else if (self.impulse == 10)
      CycleWeaponCommand ();
    else if (self.impulse == 11)
      ServerflagsCommand ();
    else if (self.impulse == 12)
      CycleWeaponReverseCommand ();

    else if (self.impulse == 20) //Ry: Dissolution impulse to throw out a backpack with ammo in teamplay modes
      TossBackpack();
    #ifdef GAME_ROGUE
      //ZOID--
      //teamplay stuff
      else if (self.impulse == 21)
        TossWeapon();
      else if (self.impulse == 22)
        W_ChangeWeapon();
      else if ((self.impulse == 23) || (self.impulse == 226)) //Ry: Added to Mjolnir bind [09-06-2022]
        TeamFlagStatusReport();
      //--ZOID
      else if ((self.impulse == 24) || (self.impulse == 225)) //Ry: Report scores [09-11-2022]
        TeamScoreReport();
    #endif

    else if (self.impulse == 55) //Ry: Display what temp5 options are enabled and relevant
      QueryEnabledOptions();
      
    else if (self.impulse >= 70 && self.impulse < 100)
    {
      if (self.impulse == 70)
        ToggleSetting(SETTINGS_CVAR,RY_FL_DISABLE_FOOTSTEPS,"Footstep Sounds [Armagon]",TRUE);
      else if (self.impulse == 71)
        ToggleSetting(SETTINGS_CVAR,RY_FL_DISABLE_GREMITEMSTEAL,"Gremlin Item Steal [Armagon]",TRUE);
      else if (self.impulse == 72)
        ToggleSetting(SETTINGS_CVAR,RY_FL_DISABLE_HIPREBALANCE,"Mission Pack Rebalance",TRUE);
      else if (self.impulse == 73)
        ToggleSetting(SETTINGS_CVAR,RY_FL_DISABLE_WIDELIGHTNING,"Wide Lightning",TRUE);
      else if (self.impulse == 74)
        ToggleSetting(SETTINGS_CVAR,RY_FL_DISABLE_WIDESPIKES,"Wide Spikes/Lasers",TRUE);
      else if (self.impulse == 75)
        ToggleSetting(SETTINGS_CVAR,RY_FL_FASTMONSTERS,"Fast Monsters",FALSE);
      else if (self.impulse == 76)
        ToggleSetting(SETTINGS_CVAR,RY_FL_COPPERNIGHTMARE,"Copper Difficulty Balance",FALSE);
      else if (self.impulse == 77)
        ToggleSetting(SETTINGS_CVAR,RY_FL_PREFERID1WEPS,"Prefer ID1 Weapons [Armagon]",FALSE);
      else if (self.impulse == 78)
        ToggleSetting(SETTINGS_CVAR,RY_FL_EXITWARP,"Exit Warp",FALSE);
      else if (self.impulse == 79)
        ToggleSetting(SETTINGS_CVAR,RY_FL_ALWAYSGRAPPLE,"Grapple Always Available [Dissolution]",FALSE);
      else if (self.impulse == 80)
        ToggleSetting(SETTINGS_CVAR,RY_FL_ALTPLASMA,"Alternate Plasma Gun [Dissolution]",FALSE);
      #ifdef GAME_ROGUE
        else if (self.impulse == 90)
          ToggleSetting("gamecfg",GAMECFG_ENABLE_RUNES,"Deathmatch Runes [Dissolution]",FALSE);
        #ifndef ENGINE_KEX
          //Ry: These are set from the menu in Remaster
          else if (self.impulse == 91)
            ToggleSetting("gamecfg",GAMECFG_TEAM_ARMOR_DMG,"Team Armor Protection [Dissolution]",TRUE);
          else if (self.impulse == 92)
            ToggleSetting("gamecfg",GAMECFG_TEAM_HEALTH_DMG,"Team Health Protection [Dissolution]",TRUE);
          else if (self.impulse == 93)
            ToggleSetting("gamecfg",GAMECFG_AUTO_TEAM,"Automatic Teams [Dissolution]",FALSE);
        #else
          else if (self.impulse == 94)
            ToggleSetting("gamecfg",GAMECFG_DMATCH_TAG,"Deathmatch Tag [Dissolution]",FALSE);
        #endif
      #endif
    }

    #ifdef GAME_HIPNOTIC
      //JIM
      else if ( self.impulse == 200 )
        WetsuitCheat();
      //MED
      else if ( self.impulse == 201 )
        EmpathyShieldsCheat();
    #elifdef GAME_ROGUE
      //Ry: New cheats for Rogue powerups [09-19-2022]
      else if ( self.impulse == 200 )
        AntiGravCheat();
      else if ( self.impulse == 201 )
        PowerShieldCheat();
    #endif
    else if ( self.impulse == 205 )
      Genocide();
    else if ( self.impulse == 206 )
      ToggleDump();
    else if ( self.impulse == 202 )
      DumpEntities();
    else if ( self.impulse == 203 )
      DumpLiveEntities();

    else if ( self.impulse == 207 ) //Ry: My own debug impulses
      DeleteWall();
    else if ( self.impulse == 208 )
      ProbeEntityData();
    else if (self.impulse == 209)
      TestSpawnPoints();
   
    //Ry: Model placing impulses
    else if (self.impulse >= 230 && self.impulse <= 244)
    {
      if (self.impulse == 230)
        DummyModel_Place();
      else if (self.impulse == 231)
        DummyModel_GrabModel();
      else if (self.impulse == 232)
        DummyModel_IncreaseModelIndex();
      else if (self.impulse == 233)
        DummyModel_DecreaseModelIndex();
      else if (self.impulse == 234)
        DummyModel_MoveUp();
      else if (self.impulse == 235)
        DummyModel_MoveDown();
      else if (self.impulse == 236)
        DummyModel_CopyFacing();
      else if (self.impulse == 237)
        DummyModel_CopyFacingAngled();
      else if (self.impulse == 238)
        DummyModel_ResetFacing();
      else if (self.impulse == 239)
        DummyModel_IncreaseFrame();
      else if (self.impulse == 240)
        DummyModel_DecreaseFrame();
      else if (self.impulse == 241)
        DummyModel_Next();
      else if (self.impulse == 242)
        DummyModel_Copy();
      else if (self.impulse == 243)
        DummyModel_AdjustGridSnap();
      else if (self.impulse == 244)
        DummyModel_Print();
    }

    else if (self.impulse == 255)
      QuadCheat ();

    self.lastimpulse = self.impulse;
    self.lastimpulsetime = time;
  }
  if (dump_coord == 1)
    DumpCoordinates();

	self.impulse = 0;
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
void() W_WeaponFrame =
{
	if (time < self.attack_finished)
		return;

	ImpulseCommands ();

// check for attack
	if (self.button0 && !self.justrespawned) //Ry: Ensure player doesn't fire as soon as they respawn
	{
    SuperDamageSound ();
    W_Attack ();
	}
  #ifdef GAME_ROGUE
  else if (self.lavagunfired) //Ry: This used to be a global [09-01-2022]
  {
    if (self.weapon == IT_LAVA_NAILGUN || self.weapon == IT_LAVA_SUPER_NAILGUN)
      sound (self, CHAN_WEAPON, "lavagun/snail.wav", 1, ATTN_NORM);
    self.lavagunfired = FALSE;
  }
  #endif
};

/*
========
SuperDamageSound

Plays sound if needed
========
*/
void() SuperDamageSound =
{
  #ifdef GAME_ROGUE
    //Ry: Only play quad sound on grapple the one time, unless hooked to an enemy
    if ( (self.weapon == IT_GRAPPLE) && (self.hookstatus > HOOK_READY) && !(self.hook.enemy.flags & (FL_MONSTER|FL_CLIENT)) )
      return;
  #endif
      
	if (self.super_damage_finished > time)
	{
		if (self.super_sound < time)
		{
			self.super_sound = time + 1;
			sound (self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
		}
	}
  #ifdef GAME_ROGUE
    // ZOID--   //Ry: Moved this here [09-03-2022]
    RuneApplyBlackNoise(self); // make rune noise
    //--ZOID
  #endif
	return;
};
