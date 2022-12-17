//MED 10/18/96
void(float damage) spawn_touchblood;
/*
================
HIPNOTIC WEAPONS
================
*/
void() HIP_LaserTouch =
{
	local vector org;
  local vector spot1,spot2;
  local vector oldvel;
  local float r;

  self.owner = world;
  self.cnt = self.cnt + 1;
  if (pointcontents(self.origin) == CONTENT_SKY)
	{
    RemoveMissile();
		return;
	}
  oldvel = normalize(self.old_velocity);
  spot1 = self.origin - (16*oldvel);
  spot2 = self.origin + (16*oldvel);
  traceline (spot1, spot2, FALSE, self);  // see through other monsters
  self.origin = trace_endpos;

  org = self.origin;

	if (other.health)
  {
    if (self.lastvictim == other)
    {
      self.dmg = self.dmg / 2;
    }
    spawn_touchblood (self.dmg);
    T_Damage (other, self, self.lastvictim, self.dmg);
  }
  else if ((self.cnt == 3) || (random()<0.15))
  {
    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte (MSG_BROADCAST, TE_GUNSHOT);
    WriteCoord (MSG_BROADCAST, org_x);
    WriteCoord (MSG_BROADCAST, org_y);
    WriteCoord (MSG_BROADCAST, org_z);
  }
  else
  {
//    self.dmg = 0.66 * self.dmg;
    self.dmg = 0.9 * self.dmg;
//    self.speed = 0.95 * self.speed;
    self.velocity = oldvel+(2*trace_plane_normal);
    self.velocity = normalize(self.velocity);
    self.velocity = self.speed * self.velocity;
    self.old_velocity = self.velocity;
    if (self.flags & FL_ONGROUND)
      self.flags = self.flags - FL_ONGROUND;
    r = random();
    sound (self, CHAN_WEAPON, "hipweap/laserric.wav", 1, ATTN_STATIC);
    UpdateMissileField();
    return;
  }
  sound (self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC);
  RemoveMissile();
};

void() HIP_LaserThink =
{
  if (time>self.attack_finished)
  {
    RemoveMissile();
    return;
  }
  if (self.flags & FL_ONGROUND)
    self.flags = self.flags - FL_ONGROUND;
  self.velocity = self.old_velocity;
  self.angles = vectoangles(self.velocity);
  self.nextthink = time+0.1;
  UpdateMissileField();
};

void(vector org, vector vec, float light) HIP_LaunchLaser =
{
  sound (self ,CHAN_WEAPON, "hipweap/laserg.wav", 1, ATTN_NORM);

  vec = normalize(vec);

	newmis = spawn();
  newmis.owner = self;
  newmis.classname = "hiplaser";
  newmis.lastvictim = self;
  newmis.movetype = MOVETYPE_FLYMISSILE;
  newmis.solid = SOLID_BBOX;
  if (light)
    newmis.effects = EF_DIMLIGHT;
  else
    SetLightEffect(newmis,SET_EF_CANDLE,TRUE); //Ry: Normally have a small glow now [10-31-2022]

  setmodel (newmis, "progs/lasrspik.mdl");
	setsize (newmis, '0 0 0', '0 0 0');

	setorigin (newmis, org);

  newmis.speed = ProjectileSpeed(self,1000);
  newmis.dmg = 18;
  newmis.velocity = vec * newmis.speed;
  newmis.old_velocity = newmis.velocity;
  newmis.angles = vectoangles(newmis.velocity);
  newmis.avelocity = '0 0 400';

  newmis.nextthink = time;
  newmis.attack_finished = time + 5;
  newmis.think = HIP_LaserThink;
  newmis.touch = HIP_LaserTouch;
  newmis.count = 0;

  CreateMissileField(newmis,4); //Ry: Give bigger hitbox against players in Deathmatch
};

/*
=================
HIP_FireLaser
=================
*/
void(float stat) HIP_FireLaser =
{
	local vector org;
  local vector dir;
  local vector out;
  local float ofs;
  local float aofs;

  if (!self.button0)
  {
    player_run ();
    return;
  }
  if (self.AMMO_CELLS < 1)
  {
    self.weapon = W_BestWeapon ();
    W_SetCurrentAmmo ();
    return;
  }
     
  SuperDamageSound();
  self.effects = self.effects | EF_MUZZLEFLASH;
  makevectors (self.v_angle);
  ofs = 6;
  out = v_forward;
  out_z = 0;
  out = normalize(out);
  org = self.origin + ((12-ofs) * v_up) + (12*out);
  dir = aim (self, 1000);
  aofs = ofs * 0.707;
  self.currentammo = self.AMMO_CELLS -= 1;
  if (stat == 0)
  {
    org = org + (aofs*v_right);
    org = org - (aofs*v_up);
    HIP_LaunchLaser(org, dir, 0);
    org = org - (2*aofs*v_right);
    HIP_LaunchLaser(org, dir, 0);
  }
  else if (stat == 1)
  {
    org = org + (ofs*v_up);
    //Ry: In SP/Co-op, always do the higher damage laser instead of being random [11-06-2022]
    if ( (hip_rebalance && !deathmatch) || (random()<0.1) )
    {
      HIP_LaunchLaser(org, dir, 1);
      newmis.dmg = 25;
    }
    else
      HIP_LaunchLaser(org, dir, 0);
  }
  self.punchangle_x = -1;
};

//void(entity prev, entity owner, float dst) HIP_SpawnMjolnirLightning;
void() HIP_LightningThink =
{
  local vector org;
  local vector dst;
  local entity head;
  local entity selected;
  local float cur_dist;
  local float head_dist;
  local vector vec;
  local float dot;
  local float oldstate;
  local float dam;

  if (time > self.delay)
  {
    if (self.enemy != world)
      self.enemy.struck_by_mjolnir = 0;
    remove(self);
    return;
  }
  oldstate = self.state;
  if (self.state==0)
  {
    // look in our immediate vicinity
    self.enemy = world;
    selected = world;
    cur_dist = self.distance;
    head = findradius(self.owner.origin, self.distance);
    while(head)
    {
      //Ry: Mjolnir shouldn't target allies, including charmed monsters [08-01-2022]
      if( !(head.flags & FL_NOTARGET) && (head.flags & (FL_CLIENT|FL_MONSTER)) && ((head.team == 0) || (head.team != self.owner.owner.team)) )
      {
        if (visible(head) && (head!=self.owner.owner) && (head.health>0))
        {
          head_dist = vlen(head.origin - self.lastvictim.origin);
          if (head.invisible_finished) //Ry: Ring of Shadows now makes it harder for Mjonlir to hit
            head_dist = head_dist * 2;
          if ((head_dist<cur_dist) && (head_dist <= self.distance) && (head.struck_by_mjolnir==0))
          {
            selected = head;
            cur_dist = head_dist;
          }
        }
      }
      head = head.chain;
    }
    if (selected != world)
    {
      self.state = 1;
      self.enemy = selected;
      self.enemy.struck_by_mjolnir = 1;
    }
    else
    {
      local vector  end;

      makevectors(self.v_angle);
      org = self.owner.origin;
      end = org + v_forward*200;
      end = end + (((400*random()) - 200) * v_right);

      traceline (org, end, TRUE, self);

      WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
      WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
      WriteEntity (MSG_BROADCAST, self);
      WriteCoord (MSG_BROADCAST, org_x);
      WriteCoord (MSG_BROADCAST, org_y);
      WriteCoord (MSG_BROADCAST, org_z);
      WriteCoord (MSG_BROADCAST, trace_endpos_x);
      WriteCoord (MSG_BROADCAST, trace_endpos_y);
      WriteCoord (MSG_BROADCAST, trace_endpos_z);

      self.nextthink = time + 0.1;
//      self.think = HIP_DiversionLightningThink;
//      self.nextthink = time;
//      self.delay = time + 0.30;
//      self.origin = self.owner.origin;
//      self.think();
      return;
    }
  }
  org = self.lastvictim.origin;
  dst = self.enemy.absmin + 0.25*(self.enemy.absmax-self.enemy.absmin);
  dst = dst + (random()*0.5*(self.enemy.absmax-self.enemy.absmin));
  traceline (org, dst, TRUE, self.owner.owner);

  if (trace_fraction != 1.0 || self.enemy.health<=0)
  {
    self.enemy.struck_by_mjolnir = 0;
    self.state = 0;
    self.nextthink = time + 0.1;
    return;
  }
  WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
  WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
  WriteEntity (MSG_BROADCAST, self);
  WriteCoord (MSG_BROADCAST, org_x);
  WriteCoord (MSG_BROADCAST, org_y);
  WriteCoord (MSG_BROADCAST, org_z);
  WriteCoord (MSG_BROADCAST, trace_endpos_x);
  WriteCoord (MSG_BROADCAST, trace_endpos_y);
  WriteCoord (MSG_BROADCAST, trace_endpos_z);
  vec = normalize(self.enemy.origin - self.owner.origin);
  dot = vec * self.owner.movedir;
  if (oldstate==0) 
    dam = 80;
  else
    dam = 30;

  if (hip_rebalance && (self.enemy.flags & FL_MONSTER)) //Ry: Double damage against monsters
    dam = dam * 2;
  if (dot<=0.3) //Not in front of player
    dam = dam * 0.5;

  head = self;
  self = self.owner.owner;
  LightningDamage (org, trace_endpos, self, head, dam, FALSE, self.team); //Ry: The function used before was basically a 1:1 duplicate
  self = head;

  self.nextthink = time + 0.2;
};

void(entity prev, entity own, float dst) HIP_SpawnMjolnirLightning =
{
  local entity light;
  // spawn actual lightning
  light = spawn();
  light.delay = time + 0.8;
  light.state = 0;
  light.lastvictim = prev;
  light.distance = dst;
  light.owner = own;
  light.v_angle = self.angles;
  light.v_angle_x = 0;
  light.v_angle_z = 0;
  light.origin = own.origin;
  light.think = HIP_LightningThink;
  light.nextthink = time;
  light.classname = "mjolnir_lightning_beam"; //Ry: Class name for this too [07-31-2022]
};

void() HIP_SpawnMjolnirBase =
{
  local entity light;
  // spawn lightning base
  light = spawn();
//  light.origin = self.origin - '0 0 24' + (32*v_forward);
  light.origin = trace_endpos;
  light.flags = 0;
  light.owner = self;
  light.struck_by_mjolnir = 1;
  light.think = SUB_Remove;
  light.nextthink = time + 1;
  light.classname = "mjolnir_lightning_base"; //Ry: Added class name to be picked up by obituaries
  sound (light, CHAN_AUTO, "hipweap/mjolslap.wav", 1, ATTN_NORM);
  sound (light, CHAN_WEAPON, "hipweap/mjolhit.wav", 1, ATTN_NORM);
  makevectors(self.v_angle);
  light.movedir = v_forward;
  HIP_SpawnMjolnirLightning( light, light, 350 );
  HIP_SpawnMjolnirLightning( light, light, 350 );
  HIP_SpawnMjolnirLightning( light, light, 350 );
  HIP_SpawnMjolnirLightning( light, light, 350 );
};

void() HIP_FireMjolnirLightning =
{
	local	float		cells, content;
  #ifdef ENGINE_KEX
    local float oldfrags;
  #endif

  //Ry: Discharge if the attack would originate from within a liquid, instead of checking if the player is in water
  content = pointcontents(trace_endpos);
	if ( (content == CONTENT_WATER) || (content == CONTENT_SLIME) || (content == CONTENT_LAVA) )
	{
    self.deathtype = "discharge"; //Ry: Track this better
    self.watertype = content; //Ry: Set content directly for the death message
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
        //Ry: Mjolnir Discharge achievement check [09-03-2022]
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

  self.currentammo = self.AMMO_CELLS -= 15;
  self.show_hostile = time + 1; //Ry: Alert monsters when the attack goes off

  HIP_SpawnMjolnirBase();
};

void() HIP_FireMjolnir =
{
  local vector   org;
  local float    damage;
  local vector   source;

  self.attack_finished = time + 0.4;
  source = self.origin + '0 0 16';
  makevectors(self.v_angle);

  traceline (source, source + v_forward*32, FALSE, self);
  if (!self.mjolnirdisable)
  {
    if (trace_fraction == 1.0 && (self.AMMO_CELLS >= 15))
    {
      source = source + v_forward*32;
      traceline (source , source - v_up*50, FALSE, self);
      if (trace_fraction > 0.3 && trace_fraction< 1.0)
      {
        HIP_FireMjolnirLightning();
        self.attack_finished = time + 1.5;
        return;
      }
    }
  }
  org = trace_endpos - v_forward*4;

  if (trace_ent.takedamage)
  {
    damage = 50;
    if (trace_ent.classname == "monster_zombie")
      damage = 70;
    trace_ent.axhitme = 1;
    SpawnBlood (org, v_forward, damage);
    T_Damage (trace_ent, self, self, damage);
  }
  else
  {  // hit wall
    if (trace_fraction != 1.0)
    {
      sound (self, CHAN_WEAPON, "hipweap/mjoltink.wav", 1, ATTN_NORM);
      WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
      WriteByte (MSG_BROADCAST, TE_GUNSHOT);
      WriteCoord (MSG_BROADCAST, org_x);
      WriteCoord (MSG_BROADCAST, org_y);
      WriteCoord (MSG_BROADCAST, org_z);
    }
    else
    {
      sound (self, CHAN_WEAPON, "knight/sword1.wav", 1, ATTN_NORM);
    }
  }
  self.attack_finished = time + 0.4;

};

void() ProximityExplode =
{
  if (hip_rebalance && !deathmatch) //Ry: Increased damage in SP/Co-op
    T_RadiusDamage (self, self.owner, 120, world);
  else
    T_RadiusDamage (self, self.owner, 95, world);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

//MED 10/31/96
float NumProximityGrenades;
/*
================
ProximityGrenadeExplode
================
*/
void() ProximityGrenadeExplode =
{
  self.takedamage = DAMAGE_NO;
  NumProximityGrenades = NumProximityGrenades - 1;
  self.deathtype = "exploding";
  self.nextthink = time + 0.1;
  self.owner = self.lastvictim;
  self.think = ProximityExplode;
};

/*
================
ProximityGrenadeTouch
================
*/
void() ProximityGrenadeTouch =
{
  if (other == self)
    return;

  if (pointcontents(self.origin) == CONTENT_SKY) //Ry: Remove when fired into the sky [11-01-2022]
	{
    NumProximityGrenades = NumProximityGrenades - 1;
    remove(self);
		return;
	}

  if (other.classname == self.classname)
    return;
  //Ry: In SP/Co-op, ignore the owner and (if teamplay is enabled) their allies
  if ( hip_rebalance && !deathmatch && ((other == self.lastvictim) || (teamplay && (other.flags & (FL_CLIENT|FL_MONSTER)) && (other.team == self.lastvictim.team))) )
  {
    if (self.spawnmaster || (self.owner == self))
    {
      if (BBoxIntersection(self,other,1))
      {
        self.solid = SOLID_TRIGGER;
        setmodel(self, self.model);
        self.wait = time + 0.1;
        if (self.nextthink > time + 0.2)
        {
          self.nextthink = time + 0.2;
        }
      }
    }
    else
    {
      sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);
    }
    return;
  }
  if ( vlen(other.velocity) > 0 )
  {
    ProximityGrenadeExplode();
    self.think();
    return;
  }
  if (other.takedamage == DAMAGE_AIM)
  {
    ProximityGrenadeExplode();
    self.think();
    return;
  }
  self.waterlevel = 0; //Ry: Make sure splash sound doesn't play when dropping to the floor
  self.watertype = CONTENT_EMPTY;
  if (self.state > 0) //Ry: Dislodge properly, instead of falling into the void
  {
    self.movetype = MOVETYPE_TOSS;
    setsize (self, '-1 -1 -1', '1 1 1');
    self.spawnmaster = world;
    self.state = 0;
    return;
  }
  sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM); // bounce sound
  if ( (other.flags & (FL_CLIENT|FL_MONSTER)) && (other.health <= 0) ) //Ry: Ensure it's not sticking to a dying monster [08-01-2022]
    return;
  self.movetype = MOVETYPE_NONE;
  setsize (self, '-8 -8 -8', '8 8 8');
  self.state = 1;
  self.spawnmaster = other;

  //Ry: If owner or ally would get stuck in the bomb, set it to trigger collision so they can get out
  if ( hip_rebalance && !deathmatch )
  {
    self.owner = self;
    
    if (self.solid == SOLID_BBOX)
    {
      other = findradius(self.origin,92);
      while (other)
      {
        if ( (other.flags & (FL_CLIENT|FL_MONSTER)) && (other.team == self.lastvictim.team ) )
        {
          if (BBoxIntersection(self,other,9))
          {
            self.solid = SOLID_TRIGGER;
            setmodel(self, self.model);
            return;
          }
        }
        other = other.chain;
      }
    }
  }
};

/*
================
ProximityBomb
================
*/
void() ProximityBomb =
{
  local entity   head;
  local float    blowup;

  if ((time > self.delay) || (NumProximityGrenades > 15) || (vlen(self.spawnmaster.velocity)>0) )
  {
    ProximityGrenadeExplode();
    self.think();
    return;
  }
  self.takedamage = DAMAGE_YES;
  head = findradius(self.origin, 140);
  blowup = 0;

  //Ry: Set back to solid when the allied entity is out of the collision
  if ( (self.solid == SOLID_TRIGGER) && (time >= self.wait) )
  {
    self.solid = SOLID_BBOX;
    setmodel(self, self.model);
  }
  if (!hip_rebalance || deathmatch)
  {
    self.owner = self;
    if (!(self.lastvictim.flags & FL_MONSTER)) //Ry: No need to update for monsters [08-20-2022]
    {
      if (self.lastvictim.super_damage_finished) //Ry: Glow when owner has Quad Damage
        SetLightEffect(self,SET_EF_CANDLE,TRUE);
      else
        self.effects = 0;
    }
  }

  while (head)
  {
    if (head != self) //Ry: Don't blow up when detecting self
    {
      //Ry: No longer react to invisible players. Also, players that are spawning or teleporting are ignored for a second.
      if ((head.health > 0) && (head.flags & (FL_CLIENT|FL_MONSTER)) && (!head.invisible_finished) && (time >= head.proxyimmunetime) && (head.classname!=self.classname))
        blowup = 1;
      if ((head.classname == self.classname) && (head.state==0))
        blowup = 1;
      //Ry: In SP/Co-op, ignore owner and allies
      if ( hip_rebalance && !deathmatch && (head.team == self.lastvictim.team) )
        blowup = 0;
      //Ry: Detonate when too close to a spawn point (Set up to only be detectable in the relevant modes)
      if ( (head.classname == "info_player_deathmatch") || (head.classname == "info_player_coop") || (head.classname == "info_player_start") )
      {
        if ( BBoxIntersection(self,head,4) )
        {
          blowup = 1;
        }
      }
      else if (blowup == 1) //Ry: Don't do unnecesary traces against things that don't trigger it
      {
        traceline(self.origin,head.origin,TRUE,self);
        if (trace_fraction != 1.0)
          blowup = 0;
      }
      if (blowup==1)
      {
        sound (self, CHAN_WEAPON, "hipweap/proxwarn.wav", 1, ATTN_NORM);
        ProximityGrenadeExplode();
        self.nextthink = time + 0.5;
        return;
      }
    }
    head = head.chain;
  }
  self.nextthink = time + 0.25;
  if (self.state == 1) //Ry: So spawn points know when the bomb has started thinking
    self.state = 2;
};

/*
================
W_FireProximityGrenade
================
*/
void() W_FireProximityGrenade =
{
  local entity missile;

  NumProximityGrenades = NumProximityGrenades + 1;
  self.currentammo = self.AMMO_ROCKETS = self.AMMO_ROCKETS - 1;

  sound (self, CHAN_WEAPON, "hipweap/proxbomb.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
  missile.owner = self;
  missile.lastvictim = self;
  missile.movetype = MOVETYPE_TOSS;
	missile.solid = SOLID_BBOX;
  missile.classname = "proximity_grenade";
  missile.takedamage = DAMAGE_NO;
  missile.health = 5;
  missile.state = 0;
  
  if ((!hip_rebalance || deathmatch) && self.super_damage_finished) //Ry: Glow when owner has Quad Damage in DM
    SetLightEffect(missile,SET_EF_CANDLE,TRUE);

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

  missile.avelocity = '100 600 100';

	missile.angles = vectoangles(missile.velocity);

  missile.touch = ProximityGrenadeTouch;

// set missile duration
  missile.nextthink = time + 2;
  if (hip_rebalance && !deathmatch) //Ry: Detonate at a predictable time in SP/Co-op
    missile.delay = time + 20;
  else
    missile.delay = time + 15 + (10*random());
  missile.think = ProximityBomb;
  missile.th_die = ProximityGrenadeExplode;

  setmodel (missile, "progs/proxbomb.mdl");
  setorigin (missile, self.origin);
  setsize (missile, '-1 -1 -1', '1 1 1');
};