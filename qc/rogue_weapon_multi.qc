// multi_weapons.qc
// pmack
// sept 96



//======================
//  New Subs by Ryason
//======================

void() PlasmaTouch;

vector(entity player) GetBarrelPosition =
{
	makevectors (player.v_angle);
  return (player.origin + v_forward*24 + '0 0 16');
}

float(entity owner) Plasma_InWater =
{
  local float cells;
  #ifdef ENGINE_KEX
    local float oldfrags;
  #endif
	if (owner.waterlevel > 1)
	{
    owner.deathtype = "discharge"; //Ry: Track this better
		cells = owner.ammo_plasma;
		owner.ammo_plasma = 0;
    #ifdef ENGINE_KEX
      oldfrags = self.frags;
    #endif
		T_RadiusDamage (owner, owner, 35*cells, world);
    if (owner.health > 0) //Ry: Only run this function if the player survives, since it'll soft-lock the player if they die but don't gib
    {
      W_SetCurrentAmmo ();
      #ifdef ENGINE_KEX
        //Ry: Plasma Gun Discharge achievement check [09-03-2022]
        if (self.frags > oldfrags)
        {
          msg_entity = owner;
          WriteByte(MSG_ONE, SVC_ACHIEVEMENT);
          WriteString(MSG_ONE, "ACH_SURVIVE_DISCHARGE");
        }
      #endif
    }
    else
      W_UpdateAmmo();
		return TRUE;
	}
  return FALSE;
}

//Ry: Plasma ball is on the barrel, preparing to be launched
void() PlasmaCharging =
{
  local vector dir;
  local entity stemp;

  //Ry: Detonate if player dies, suicides, or disconnects
  if (self.owner.health <= 0 || (time < self.owner.lastspawntime + 0.2) || !self.owner.important)
  {
    other = world;
    PlasmaTouch();
    return;
  }

  //Ry: Continue to check for water
  if (Plasma_InWater(self.owner))
  {
    remove(self);
    return;
  }

  setorigin (self, GetBarrelPosition(self.owner));

  if (time >= self.delay)
  {
    self.owner.punchangle_x = -2;
    self.solid = SOLID_BBOX;
    self.touch = PlasmaTouch;

    stemp = self;
    self = self.owner;
    dir = aim ( self.owner, 1000 );
    self = stemp;

    self.velocity = dir * ProjectileSpeed(self.owner,1250);

    self.nextthink = time + 5;
    self.think = SUB_Remove;
  }
  else
    self.nextthink = time;
}

//Ry: Spawn a Plasma Ball and attach it to the barrel
void() PlasmaPrepare =
{
	local entity	missile;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_NOT;
	missile.classname = "plasma";

  missile.avelocity = '300 300 300';

	setmodel (missile, "progs/plasma.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, GetBarrelPosition(self));

	sound (missile, CHAN_WEAPON, "plasma/flight.wav", 1, ATTN_NORM);
  missile.effects = EF_BRIGHTLIGHT;

  missile.think = PlasmaCharging;
  missile.nextthink = time;
  missile.delay = time + 0.4;
}

//===================
//  End of new subs
//===================



//=============================================================================
// Multi Grenade Code
//=============================================================================
void() MultiGrenadeTouch;

//================================
//================================
void() MiniGrenadeExplode =
{
	if ( self.owner.classname == "player")
		T_RadiusDamage (self, self.owner, 90, world);
	else
		T_RadiusDamage (self, self.owner, 60, world);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION2);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
  WriteByte (MSG_BROADCAST, 230);
  WriteByte (MSG_BROADCAST, 5);

	BecomeExplosion ();
};

//================================
//================================
void(float offsetAngle) MiniGrenadeLaunch =
{
	local	entity missile;
	local	float	tempRand;
	
	missile = spawn ();
	missile.owner = self.owner;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "MiniGrenade";
		
// set missile speed	
	missile.v_angle = self.v_angle;
	missile.v_angle_y = missile.v_angle_y + offsetAngle;
	makevectors (missile.v_angle);
		
  missile.velocity = v_forward*100 + v_up*400;
  tempRand = (crandom()*60) - 30;
  missile.velocity = missile.velocity + tempRand * v_forward;
  tempRand = (crandom()*40) - 20;
  missile.velocity = missile.velocity + tempRand * v_right;
  tempRand = (crandom()*60) - 30;
  missile.velocity = missile.velocity + tempRand * v_up;

	missile.avelocity = '300 300 300';
	missile.angles = vectoangles(missile.velocity);
	missile.touch = MultiGrenadeTouch;
	
	setmodel (missile, "progs/mervup.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin);

// set missile duration
	missile.nextthink = time + 1 + (crandom() * 0.5);
	missile.think = MiniGrenadeExplode;
};

//================================
//================================
void() MultiGrenadeExplode =
{
	MiniGrenadeLaunch(0);
	MiniGrenadeLaunch(72);
	MiniGrenadeLaunch(144);
	MiniGrenadeLaunch(216);
	MiniGrenadeLaunch(288);

	remove (self);
};

//================================
//================================
void() MultiGrenadeTouch =
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
		if (self.classname == "MiniGrenade")
			MiniGrenadeExplode();
		else
		{
			if (self.owner.classname == "player")
				GrenadeExplode();
			else
				MiniGrenadeExplode();
		}
		return;
	}
	// bounce sound
	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);	
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

//================================
//================================
void() W_FireMultiGrenade =
{
	local	entity missile;
	
	self.currentammo = self.ammo_multi_rockets = self.ammo_multi_rockets - 1;
	UpdateAmmoCounts (self);
	
	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "MultiGrenade";
		
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
	missile.touch = MultiGrenadeTouch;
	
// set missile duration
	//missile.nextthink = time + 1;
	//missile.think = MultiGrenadeExplode;
	missile.nextthink = time + 0.2;
	missile.think = GrenadeThink; //Ry: Downwards slope fix, and also automatic splitting
  missile.delay = time + 1; //Ry: Time before it splits

	setmodel (missile, "progs/mervup.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin);
};

//=============================================================================
// Multi Rocket Code
//=============================================================================

//================================
//================================
void() MultiRocketExplode = 
{
	local float	damg;

//	Stock Single Rocket Damage...
//	damg = 100 + random()*20;

	damg = 60 + random()*15;

	if (other.health)
	{
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;	// mostly immune
		if (other.classname == "monster_dragon")
			damg = damg * 0.5;	// mostly immune
		T_Damage (other, self, self.owner, damg );
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact
//	Stock single rocket damage.
//	T_RadiusDamage (self, self.owner, 120, other);

	T_RadiusDamage (self, self.owner, 75, other);

//	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

//================================
//================================
void() MultiRocketTouch =
{
	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	MultiRocketExplode ();
};


//================================
//================================
void() HomingMissileThink =
{
	local vector	dir;

	if (self.enemy.health < 1)
	{
		remove(self);
		return;
	}

	dir = normalize(self.enemy.origin - self.origin);
	self.velocity = dir * 1000;
	self.nextthink = time + 0.1;
	self.think = HomingMissileThink;	
};


//================================
//================================
void() HomingMissileAcquire =
{
	local vector	oldVelocity;
	local vector	aimangle;

	if ( self.delay < time )
	{
		MultiRocketExplode ();
		return;
	}

	oldVelocity = self.velocity;
	makevectors (self.v_angle);
	self.velocity = aim (self, 1000);
	self.velocity = self.velocity * 1000;

	aimangle = self.origin + self.velocity;	
	traceline ( self.origin, aimangle, FALSE, self );
	if (trace_fraction < 1)
	{
		if (trace_ent.flags & FL_MONSTER)
		{
			self.enemy = trace_ent;
			HomingMissileThink();
			return;
		}
	}
	
	self.velocity = oldVelocity;
	self.v_angle = vectoangles ( self.velocity );
	self.angles = self.v_angle;
	self.think = HomingMissileAcquire;
	self.nextthink = time + 0.2;
};

//================================
//================================
void(float offset, float frameNum) MultiRocketLaunch = 
{
	local entity 	missile;
	local vector	aimangle;
	
	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "MultiRocket";
	missile.delay = time + 4;
	missile.frame = frameNum;
	missile.touch = MultiRocketTouch;

	setmodel (missile, "progs/rockup.mdl");

	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin + v_forward*8 + '0 0 16');
	
	if ( coop || deathmatch)
	{
		aimangle = self.v_angle;
		aimangle_y = aimangle_y + (offset * 0.66);
		makevectors (aimangle);
		missile.velocity = aim(self, 1000);
		missile.velocity = missile.velocity * 1000;
		missile.angles = vectoangles(missile.velocity);

		missile.think = MultiRocketExplode;
		missile.nextthink = time + 4;
	}
	else
	{
		makevectors (self.v_angle);
		missile.velocity = v_forward * 1000 - v_right*offset*8;
		missile.angles = vectoangles(missile.velocity);
		missile.v_angle = self.v_angle;	

		aimangle = missile.origin + missile.velocity;
		traceline ( missile.origin, aimangle, FALSE, self );
		if (trace_fraction < 1)
		{
			if (trace_ent.flags & FL_MONSTER)
			{
				missile.enemy = trace_ent;
				missile.think = HomingMissileThink;
				return;
			}
		}

		missile.think = HomingMissileAcquire;
		missile.nextthink = time + 0.1;
	}
};

//================================
//================================
void() W_FireMultiRocket =
{
	self.currentammo = self.ammo_multi_rockets = self.ammo_multi_rockets - 1;
	UpdateAmmoCounts (self);
	
	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;
	
	MultiRocketLaunch ( -10, 2 );
	MultiRocketLaunch ( -5, 3 );
	MultiRocketLaunch ( 5, 0 );
	MultiRocketLaunch ( 10, 1 );
};

//=============================================================================
// Plasma Gun Code
//=============================================================================

void(entity current, float doDamage) PlasmaDischarge =
{
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, current);
	WriteCoord (MSG_BROADCAST, current.origin_x);
	WriteCoord (MSG_BROADCAST, current.origin_y);
	WriteCoord (MSG_BROADCAST, current.origin_z);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	sound (self, CHAN_VOICE, "weapons/lhit.wav", 1, ATTN_NORM);
	if (doDamage == 1) //Ry: PlasmaDamage's only difference was that it attributed the damage to self.owner, which my version of LightningDamage can do [09-06-2022]
    LightningDamage (self.origin, current.origin, self.owner, self, 50, FALSE, self.owner.team);
};

//================================
//================================
void() PlasmaGroundOut = 
{
	local entity 	current, start;
	local float		monstersHit;
	
	monstersHit = 0;
	current = findradius ( self.origin, 320 );
	start = current;
	while ( monstersHit < 5 )
	{
		if ( current.flags & FL_MONSTER || current.classname == "player")
		{
			if ( current != self.owner )
			{
        //Ry: Don't zap teammates [09-06-2022]
        if (!teamplay || (current.team == 0) || (current.team != self.owner.team))
        {
          traceline ( self.origin, current.origin, TRUE, world );
          if (trace_fraction == 1)
          {
            monstersHit = monstersHit + 1;
            PlasmaDischarge ( current, 1 );
          }
        }
			}
		}
		current = current.chain;
		if (start == current || !current)
			return;
	}
};

//================================
//================================
void() PlasmaTouch = 
{
	local float	damg;

	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damg = 80 + random()*20;
	sound (self, CHAN_WEAPON, "plasma/explode.wav", 1, ATTN_NORM);
	
	if (other.health)
	{
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;	// mostly immune
		T_Damage (other, self, self.owner, damg );
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact
	T_RadiusDamage (self, self.owner, 70, other);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION2);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	WriteByte (MSG_BROADCAST, 244);
	WriteByte (MSG_BROADCAST, 3);

	PlasmaGroundOut();
	remove (self);
};

//================================
//================================
void() PlasmaLaunch =
{
	self.velocity = normalize(self.velocity);
	self.velocity = self.velocity * ProjectileSpeed(self,1250);

	self.nextthink = time + 5;
	self.think = SUB_Remove;
};

void(vector org, vector dir) launch_plasma =
{
	local entity	missile;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "plasma";
	
// set missile speed	
	missile.velocity = dir * 0.01;
	missile.avelocity = '300 300 300';
	missile.angles = vectoangles(missile.velocity);
	missile.touch = PlasmaTouch;
	
	setmodel (missile, "progs/plasma.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, org);

	sound (missile, CHAN_WEAPON, "plasma/flight.wav", 1, ATTN_NORM);
  missile.effects = EF_BRIGHTLIGHT;

  missile.think = PlasmaLaunch;
  missile.nextthink = time + 0.1;
};

//================================
//================================
void() W_FirePlasma = 
{
	if (self.ammo_plasma < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

// explode if under water
  if (Plasma_InWater(self))
    return;

	self.currentammo = self.ammo_plasma = self.ammo_plasma - 1;
	UpdateAmmoCounts (self);
	sound (self, CHAN_WEAPON, "plasma/fire.wav", 0.5, ATTN_NORM);
  
  if (altplasma) //Ry: Attach projectile to barrel for 0.4 seconds [09-11-2022]
  {
    PlasmaPrepare();
  }
  else //Ry: Original behavior; Fire off immediately
  {
    local vector dir;
    self.punchangle_x = -2;
    makevectors (self.v_angle);
    dir = aim ( self, 1000 );
    launch_plasma ( GetBarrelPosition(self), dir);
  }
};

