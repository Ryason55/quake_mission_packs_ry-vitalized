/*
*/
//JIM
void( vector pos ) placebullethole;
void (entity targ, entity inflictor, entity attacker, float damage) T_Damage;
void () player_run;
void(entity bomb, entity attacker, float rad, entity ignore) T_RadiusDamage;
void(vector org, vector vel, float damage) SpawnBlood;
void() SuperDamageSound;

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
   local float mag;
   local float r;

   self.owner = world;
   self.cnt = self.cnt + 1;
   if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
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
//      self.dmg = 0.66 * self.dmg;
      self.dmg = 0.9 * self.dmg;
//      self.speed = 0.95 * self.speed;
      self.velocity = oldvel+(2*trace_plane_normal);
      self.velocity = normalize(self.velocity);
      self.velocity = self.speed * self.velocity;
      self.old_velocity = self.velocity;
      if (self.flags & FL_ONGROUND)
         self.flags = self.flags - FL_ONGROUND;
      r = random();
      sound (self, CHAN_WEAPON, "hipweap/laserric.wav", 1, ATTN_STATIC);
/*
      if (r<0.33)
         sound (self, CHAN_WEAPON, "weapons/ric1.wav", 1, ATTN_STATIC);
      else if (r<0.66)
         sound (self, CHAN_WEAPON, "weapons/ric2.wav", 1, ATTN_STATIC);
      else
         sound (self, CHAN_WEAPON, "weapons/ric3.wav", 1, ATTN_STATIC);
*/
      return;
      }
   sound (self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC);
   remove(self);

};
void() HIP_LaserThink =
   {
   local float delta;


   if (time>self.attack_finished)
      {
      remove(self);
      return;
      }
   if (self.flags & FL_ONGROUND)
      self.flags = self.flags - FL_ONGROUND;
   self.velocity = self.old_velocity;
   self.angles = vectoangles(self.velocity);
   self.nextthink = time+0.1;
   };

void(vector org, vector vec, float light) HIP_LaunchLaser =
{
//   sound (self ,CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
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

   setmodel (newmis, "progs/lasrspik.mdl");
	setsize (newmis, '0 0 0', '0 0 0');

	setorigin (newmis, org);

   newmis.speed = 1000;
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
   if (self.ammo_cells < 1)
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
//   org = self.origin + (1*v_forward);
   dir = aim (self, 1000);
   aofs = ofs * 0.707;
   if (stat == 0)
      {
      self.currentammo = self.ammo_cells = self.ammo_cells - 1;
      org = org + (aofs*v_right);
      org = org - (aofs*v_up);
      HIP_LaunchLaser(org, dir, 0);
      org = org - (2*aofs*v_right);
      HIP_LaunchLaser(org, dir, 0);
      }
   else if (stat == 1)
      {
      self.currentammo = self.ammo_cells = self.ammo_cells - 1;
      org = org + (ofs*v_up);
      if (random()<0.1)
         {
         HIP_LaunchLaser(org, dir, 1);
         newmis.dmg = 25;
         }
      else
         HIP_LaunchLaser(org, dir, 0);
      }
   self.punchangle_x = -1;
   };

/*
=================
HIP_HammerDamage
=================
*/
void(vector p1, vector p2, entity from, float damage) HIP_HammerDamage =
{
	local entity		e1, e2;
	local vector		f;

	f = p2 - p1;
	normalize (f);
	f_x = 0 - f_y;
	f_y = f_x;
	f_z = 0;
	f = f*16;

	e1 = e2 = world;

	traceline (p1, p2, FALSE, self);
//JIM
	if (trace_ent.takedamage && !trace_ent.wetsuit_finished )
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
		if (self.classname == "player")
		{
			if (other.classname == "player")
				trace_ent.velocity_z = trace_ent.velocity_z + 400;
		}
	}
	e1 = trace_ent;

	traceline (p1 + f, p2 + f, FALSE, self);
//JIM
	if (trace_ent != e1 && trace_ent.takedamage &&
		!trace_ent.wetsuit_finished )
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
	}
	e2 = trace_ent;

	traceline (p1 - f, p2 - f, FALSE, self);
//JIM
	if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage &&
		!trace_ent.wetsuit_finished )
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
	}
};

/*
void() HIP_DiversionLightningThink =
   {
   local vector   org,end;

   if (time > self.delay)
      {
      remove(self);
      return;
      }

   makevectors(self.v_angle);
   org = self.origin;
   end = org + v_forward*200;
//   end = end + (((200*random()) - 100) * v_up);
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
   };
*/

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
         if(!(head.flags & FL_NOTARGET) && ((head.flags & FL_MONSTER) || (head.flags & FL_CLIENT && !(teamplay && (coop || (self.owner.owner.team == head.team) )) )) ) //Ry: Mjolnir shouldn't hit allies in teamplay
            {
//            if (visible(head) && (head!=self.owner.owner) && (head.health>0))
            if ((visible(head)) && (head!=self.owner.owner) && (head.health>0))
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
//         self.think = HIP_DiversionLightningThink;
//         self.nextthink = time;
//         self.delay = time + 0.30;
//         self.origin = self.owner.origin;
//         self.think();
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
    
   if (self.enemy.flags & FL_MONSTER) //Ry: Double damage against monsters
     dam = dam * 2;
   if (dot<=0.3) //Not in front of player
     dam = dam * 0.5;

   head = self;
   self = self.owner.owner;
   HIP_HammerDamage (org, trace_endpos, self, dam);
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
   };

void() HIP_SpawnMjolnirBase =
   {
   local entity light;
   // spawn lightning base
   light = spawn();
//   light.origin = self.origin - '0 0 24' + (32*v_forward);
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
   local vector   org;
	local	float		cells;

// explode if under water
	if (self.waterlevel > 0) //Ry: The attack originates at your feet, hence should discharge in shallow water (The lightning was blocked by the water surface anyways)
	{
    self.deathtype = "discharge"; //Ry: Track this better
		cells = self.ammo_cells;
		self.ammo_cells = 0;
      discharged = 1;
		T_RadiusDamage (self, self, 35*cells, world);
      discharged = 0;
		W_SetCurrentAmmo ();
		return;
	}

//   if (self.t_width < time)
//   {
//      sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
//      self.t_width = time + 0.6;
//   }
//   self.punchangle_x = 12;

   self.currentammo = self.ammo_cells = self.ammo_cells - 15;

   HIP_SpawnMjolnirBase();
   };

void() HIP_FireMjolnir =
   {
   local vector   org;
	local	float		cells;
   local float    damage;
   local vector   source;
   local vector   ang;


   self.attack_finished = time + 0.4;
   source = self.origin + '0 0 16';
//   ang = self.angles;
//   ang_x = 0;
//   ang_y = 0;
   makevectors(self.v_angle);
   traceline (source, source + v_forward*32, FALSE, self);
   if (trace_fraction == 1.0 && (self.ammo_cells >= 15))
      {
      source = source + v_forward*32;
      traceline (source , source - v_up*50, FALSE, self);
//      dprint("fraction = ");
//      dprint(ftos(trace_fraction));
//      dprint("\n");
      if (trace_fraction > 0.3 && trace_fraction< 1.0)
         {
         HIP_FireMjolnirLightning();
         self.attack_finished = time + 1.5;
         return;
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
//         sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
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
   
  precache_sound ("items/damage2.wav"); //Ry: Precache these for the powerup dev cheats
  precache_sound ("items/damage3.wav");
  precache_sound ("misc/wetsuit.wav");
  precache_sound ("items/suit2.wav");
  precache_sound ("hipitems/empathy2.wav");
  precache_sound ("items/suit2.wav");
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
	local	entity missile, mpuff;

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

entity	multi_ent;
float	multi_damage;

void() ClearMultiDamage =
{
	multi_ent = world;
	multi_damage = 0;
};

void() ApplyMultiDamage =
{
	if (!multi_ent)
		return;
	T_Damage (multi_ent, self, self, multi_damage);
};

void(entity hit, float damage) AddMultiDamage =
{
	if (!hit)
		return;

	if (hit != multi_ent)
	{
		ApplyMultiDamage ();
		multi_damage = damage;
		multi_ent = hit;
	}
	else
		multi_damage = multi_damage + damage;
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
   //JIM
   local float bullet;
   bullet = 0;

	makevectors(self.v_angle);

	src = self.origin + v_forward*10;
	src_z = self.absmin_z + self.size_z * 0.7;

	ClearMultiDamage ();
	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

		traceline (src, src + direction*2048, FALSE, self);
		if (trace_fraction != 1.0)
         //JIM
         {
			TraceAttack (4, direction);
         if ( ( !bullet ) && ( trace_ent == world ) )
            {
            placebullethole( trace_endpos );
            bullet = 1;
            }
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

	self.currentammo = self.ammo_shells = self.ammo_shells - 1;
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

	self.currentammo = self.ammo_shells = self.ammo_shells - 2;
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
	local	entity missile, mpuff;

	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

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
	missile.velocity = missile.velocity * 1000;
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
void(vector p1, vector p2, entity from, entity inflictor, float damage) LightningDamage = //Ry: Added inflictor, for use with trap_gods_wrath
{
	local entity		e1, e2;
	local vector		f;

	f = p2 - p1;
	normalize (f);
	f_x = 0 - f_y;
	f_y = f_x;
	f_z = 0;
	f = f*16;

	e1 = e2 = world;

	traceline (p1, p2, FALSE, self);
//JIM
	if (trace_ent.takedamage && !trace_ent.wetsuit_finished )
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
    T_Damage (trace_ent, inflictor, from, damage); //Ry: Added inflictor here
		if (self.classname == "player")
		{
			if (other.classname == "player")
				trace_ent.velocity_z = trace_ent.velocity_z + 400;
		}
	}
	e1 = trace_ent;

	traceline (p1 + f, p2 + f, FALSE, self);
//JIM
	if (trace_ent != e1 && trace_ent.takedamage &&
		!trace_ent.wetsuit_finished )
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
    T_Damage (trace_ent, inflictor, from, damage); //Ry: Here
	}
	e2 = trace_ent;

	traceline (p1 - f, p2 - f, FALSE, self);
//JIM
	if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage &&
		!trace_ent.wetsuit_finished )
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
    T_Damage (trace_ent, inflictor, from, damage); //Ry: And here
	}
};


void() W_FireLightning =
{
	local	vector		org;
	local	float		cells;

	if (self.ammo_cells < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

// explode if under water
	if (self.waterlevel > 1)
	{
    self.deathtype = "discharge"; //Ry: Track this better
		cells = self.ammo_cells;
		self.ammo_cells = 0;
      //MED 01/05/97 added discharge flag
      discharged = 1;
		T_RadiusDamage (self, self, 35*cells, world);
      discharged = 0;
		W_SetCurrentAmmo ();
		return;
	}

	if (self.t_width < time)
	{
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}
	self.punchangle_x = -2;

	self.currentammo = self.ammo_cells = self.ammo_cells - 1;

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

	LightningDamage (self.origin, trace_endpos + v_forward*4, self, self, 30); //Ry: Added inflictor, which is just the self again
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
	local	entity missile, mpuff;

	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

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

// set missile duration
	missile.nextthink = time + 2.5;
	missile.think = GrenadeExplode;

	setmodel (missile, "progs/grenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};

void() ProximityExplode =
{
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
   if (other.classname == self.classname)// || other.classname == "grenade") //Ry: Ignore basic grenades too
      return;
   self.movetype = MOVETYPE_TOSS;
   self.waterlevel = 0; //Ry: Make sure splash sound doesn't play when dropping to the floor
   self.watertype = CONTENT_EMPTY;
   if (self.state == 1) //Ry: Dislodge properly, instead of falling into the void
   {
     setsize (self, '-1 -1 -1', '1 1 1');
     self.spawnmaster = world;
     self.state = 0;
     return;
   }
   if (vlen(other.velocity) > 0)
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
   sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM); // bounce sound
   self.movetype = MOVETYPE_NONE;
   setsize (self, '-8 -8 -8', '8 8 8');
   self.state = 1;
   self.spawnmaster = other;
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
   self.owner = world;
   self.takedamage = DAMAGE_YES;
   head = findradius(self.origin, 140);
   blowup = 0;

   if (self.lastvictim.super_damage_finished) //Ry: Glow when owner has Quad Damage
     self.effects = EF_CANDLELIGHT;
   else
     self.effects = 0;

   while (head)
      {
      if (head != self) //Ry: Don't blow up when detecting self
      {
        if ((head.health > 0) && (head.flags & (FL_CLIENT|FL_MONSTER)) && (head.classname!=self.classname))
           blowup = 1;
        if ((head.classname == self.classname) && (head.state==0))
           blowup = 1;
        traceline(self.origin,head.origin,TRUE,self);
        if (trace_fraction != 1.0)
           blowup = 0;
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
   };

/*
================
W_FireProximityGrenade
================
*/
void() W_FireProximityGrenade =
   {
   local entity missile, mpuff;

   NumProximityGrenades = NumProximityGrenades + 1;
   self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

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
   missile.delay = time + 15 + (10*random());
   missile.think = ProximityBomb;
   missile.th_die = ProximityGrenadeExplode;

   setmodel (missile, "progs/proxbomb.mdl");
   setorigin (missile, self.origin);
   setsize (missile, '-1 -1 -1', '1 1 1');

   if (self.super_damage_finished) //Ry: Glow when owner has Quad Damage
     missile.effects = EF_CANDLELIGHT;
   };

//=============================================================================

void() spike_touch;
void() superspike_touch;


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
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	setorigin (newmis, org);

	newmis.velocity = dir * 1000;
};

void() W_FireSuperSpikes =
{
	local vector	dir;
	local entity	old;

	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_nails = self.ammo_nails - 2;
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16', dir);
	newmis.touch = superspike_touch;
  newmis.classname = "super_spike"; //Ry: Super Nail given a different class name for obituary purposes
	setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	self.punchangle_x = -2;
};

void(float ox) W_FireSpikes =
{
	local vector	dir;
	local entity	old;

	makevectors (self.v_angle);

	if (self.ammo_nails >= 2 && self.weapon == IT_SUPER_NAILGUN)
	{
		W_FireSuperSpikes ();
		return;
	}

	if (self.ammo_nails < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_nails = self.ammo_nails - 1;
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16' + v_right*ox, dir);

	self.punchangle_x = -2;
};



.float hit_z;
void() spike_touch =
{
local float rand;
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
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

	remove(self);

};

void() superspike_touch =
{
local float rand;
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
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

	remove(self);

};


/*
===============================================================================

PLAYER WEAPON USE

===============================================================================
*/

void() W_UpdateAmmo = //Ry: Version of the below function that *only* updates the current ammo (no resetting the weapon)
{
	if (self.weapon == IT_SHOTGUN || self.weapon == IT_SUPER_SHOTGUN)
		self.currentammo = self.ammo_shells;
	else if (self.weapon == IT_NAILGUN || self.weapon == IT_SUPER_NAILGUN)
		self.currentammo = self.ammo_nails;
  else if (self.weapon == IT_GRENADE_LAUNCHER || self.weapon == IT_ROCKET_LAUNCHER || self.weapon == IT_PROXIMITY_GUN)
		self.currentammo = self.ammo_rockets;
	else if (self.weapon == IT_LIGHTNING || self.weapon == IT_LASER_CANNON || self.weapon == IT_MJOLNIR)
		self.currentammo = self.ammo_cells;
  else
		self.currentammo = 0;
};


//MED 10/18/96 added HIPWEAPONS
void() W_SetCurrentAmmo =
{
  player_run ();		// get out of any weapon firing states

	self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS) );

	if (self.weapon == IT_AXE)
	{
		self.currentammo = 0;
		self.weaponmodel = "progs/v_axe.mdl";
		self.weaponframe = 0;
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
	}
//MED
   else if (self.weapon == IT_LASER_CANNON)
	{
		self.currentammo = self.ammo_cells;
      self.weaponmodel = "progs/v_laserg.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_CELLS;
	}
   else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		self.currentammo = self.ammo_cells;
		self.weaponmodel = "progs/v_light.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_CELLS;
	}
//MED
   else if (self.weapon == IT_MJOLNIR)
	{
      self.currentammo = self.ammo_cells;
      self.weaponmodel = "progs/v_hammer.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_CELLS;
	}
//MED
   else if (self.weapon == IT_PROXIMITY_GUN)
	{
      self.currentammo = self.ammo_rockets;
      self.weaponmodel = "progs/v_prox.mdl";
		self.weaponframe = 0;
      self.items = self.items | IT_ROCKETS;
	}
   else
	{
		self.currentammo = 0;
		self.weaponmodel = "";
		self.weaponframe = 0;
	}
};

float() W_BestWeapon =
{
	local	float	it;

	it = self.items;

  if (self.waterlevel <= 1 && self.ammo_cells >= 1 && (it & IT_LIGHTNING) )
      return IT_LIGHTNING;
    
  if (self.classname == "monster_gremlin") //Ry: Gremlins don't care
    if(self.ammo_rockets >= 1 && (it & IT_ROCKET_LAUNCHER) )
      return IT_ROCKET_LAUNCHER;
    
//MED
  if(self.ammo_cells >= 1 && (it & IT_LASER_CANNON) )
    return IT_LASER_CANNON;
  else if(self.ammo_nails >= 2 && (it & IT_SUPER_NAILGUN) )
		return IT_SUPER_NAILGUN;
  
  if (self.classname == "monster_gremlin") //Ry: Gremlins don't care, Pt 2
    if(self.ammo_rockets >= 1 && (it & IT_PROXIMITY_GUN) ) //Ry: Added Proxy Gun
      return IT_PROXIMITY_GUN;
    else if(self.ammo_rockets >= 1 && (it & IT_GRENADE_LAUNCHER) )
      return IT_GRENADE_LAUNCHER;
  
	if(self.ammo_shells >= 2 && (it & IT_SUPER_SHOTGUN) )
		return IT_SUPER_SHOTGUN;
	else if(self.ammo_nails >= 1 && (it & IT_NAILGUN) )
		return IT_NAILGUN;
	else if(self.ammo_shells >= 1 && (it & IT_SHOTGUN) )
		return IT_SHOTGUN;
//MED
   else if( it & IT_MJOLNIR && (self.waterlevel <= 0 || self.ammo_cells < 15) ) //Ry: Avoid drawing Mjolnir in water when it has a charge
      return IT_MJOLNIR;

	return IT_AXE;
};

float() W_CheckNoAmmo =
{
	if (self.currentammo > 0)
		return TRUE;

	if (self.weapon == IT_AXE)
		return TRUE;

//MED
   if (self.weapon == IT_MJOLNIR)
      {
      return TRUE;
      }

   self.weapon = W_BestWeapon ();

	W_SetCurrentAmmo ();

// drop the weapon down
	return FALSE;
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
//MED
void()   player_laser1;
void()   player_hammer1;
void()   player_mjolnir1;


void() W_Attack =
{
	local	float	r;

	if (!W_CheckNoAmmo ())
		return;

	makevectors	(self.v_angle);			// calculate forward angle for velocity
	self.show_hostile = time + 1;	// wake monsters up
  
  if ( (self.weapon != IT_AXE) && (self.weapon != IT_MJOLNIR) ) //Ry: For the Pacifist achievement
	{
		self.fired_weapon = TRUE;
	}

	if (self.weapon == IT_AXE)
	{
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
		self.attack_finished = time + 0.5;
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		player_shot1 ();
		W_FireShotgun ();
		self.attack_finished = time + 0.5;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		player_shot1 ();
		W_FireSuperShotgun ();
		self.attack_finished = time + 0.7;
	}
	else if (self.weapon == IT_NAILGUN)
	{
		player_nail1 ();
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		player_nail1 ();
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		player_rocket1();
		W_FireGrenade();
		self.attack_finished = time + 0.6;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		player_rocket1();
		W_FireRocket();
		self.attack_finished = time + 0.8;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		player_light1();
		self.attack_finished = time + 0.1;
		sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
	}
//MED
   else if (self.weapon == IT_LASER_CANNON)
   {
      player_laser1();
   }
//MED
   else if (self.weapon == IT_MJOLNIR)
   {
      if (self.ammo_cells < 30)
         player_hammer1();
      else
         player_mjolnir1();
      self.attack_finished = time + 0.8;
   }
//MED
   else if (self.weapon == IT_PROXIMITY_GUN)
   {
      player_rocket1();
      W_FireProximityGrenade();
      self.attack_finished = time + 0.6;
   }
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
   local float oldimpulse;

	it = self.items;
	am = 0;

//MED
	if (self.impulse == 1)
	{
      fl = IT_AXE;
   }
	else if (self.impulse == 2)
	{
		fl = IT_SHOTGUN;
		if (self.ammo_shells < 1)
			am = 1;
	}
	else if (self.impulse == 3)
	{
		fl = IT_SUPER_SHOTGUN;
		if (self.ammo_shells < 2)
			am = 1;
	}
	else if (self.impulse == 4)
	{
		fl = IT_NAILGUN;
		if (self.ammo_nails < 1)
			am = 1;
	}
//MED
	else if (self.impulse == 5)
	{
      fl = IT_SUPER_NAILGUN;
      if (self.ammo_nails < 2)
         am = 1;

	}
//MED
	else if (self.impulse == 6)
	{
      if (self.weapon == IT_GRENADE_LAUNCHER)
         {
         fl = IT_PROXIMITY_GUN;
         }
      else
         {
         fl = IT_GRENADE_LAUNCHER;
         }
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 7)
	{
		fl = IT_ROCKET_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
//MED
	else if (self.impulse == 8)
	{
      fl = IT_LIGHTNING;
      if (self.ammo_cells < 1)
         am = 1;
   }
   else if (self.impulse == 225)
	{
      fl = IT_LASER_CANNON;
      if (self.ammo_cells < 1)
         am = 1;
   }
   else if (self.impulse == 226)
	{
      fl = IT_MJOLNIR;
   }
	else if (self.impulse == 227) //Ry: Re-implemented Remaster impulses for individual Proxy/Grenade
	{
      fl = IT_PROXIMITY_GUN;
      if (self.ammo_rockets < 1)
         am = 1;
   }
	else if (self.impulse == 228)
	{
      fl = IT_GRENADE_LAUNCHER;
      if (self.ammo_rockets < 1)
         am = 1;
   }
  else if (self.impulse == 224) //Ry: Added impulse command that directly calls Best Weapon
      fl = W_BestWeapon();

//MED
   oldimpulse = self.impulse;
	self.impulse = 0;

	if (!(self.items & fl))
      {
//MED
      if (fl == IT_GRENADE_LAUNCHER)
         {
         fl = IT_PROXIMITY_GUN;
         if (!(self.items & fl))
            {
            sprint (self, "no weapon.\n");
            return;
            }
         if (self.ammo_rockets < 1)
            am = 1;
         else
            am = 0;
         }
      else
         {
         sprint (self, "no weapon.\n");
         return;
         }
      }

	if (am)
	{	// don't have the ammo
		sprint (self, "not enough ammo.\n");
		return;
	}

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
void() CheatCommand =
{
	if ((deathmatch || coop) && (cheats_allowed == FALSE)) //Ry: Remaster can allow this with sv_cheats 1
  {
    sprint(self,"sv_cheats must be enabled!\n");
		return;
  }

	self.ammo_rockets = 100;
	self.ammo_nails = 200;
	self.ammo_shells = 100;
	self.items = self.items |
		IT_AXE |
		IT_SHOTGUN |
		IT_SUPER_SHOTGUN |
		IT_NAILGUN |
		IT_SUPER_NAILGUN |
		IT_GRENADE_LAUNCHER |
		IT_ROCKET_LAUNCHER |
		IT_KEY1 | IT_KEY2;

	self.ammo_cells = 100; //Ry: Changed to actual ammo limit
	self.items = self.items | IT_LIGHTNING;
//MED
   self.items = self.items | IT_LASER_CANNON;
   self.items = self.items | IT_MJOLNIR;
   self.items = self.items | IT_PROXIMITY_GUN;

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
	local	float	it, am;

	it = self.items;
	self.impulse = 0;

	while (1)
	{
		am = 0;

//MED
      if (self.weapon == IT_MJOLNIR)
		{
			self.weapon = IT_AXE;
		}
		else if (self.weapon == IT_AXE)
		{
         self.weapon = IT_SHOTGUN;
         if (self.ammo_shells < 1)
				am = 1;
      }
      else if (self.weapon == IT_SHOTGUN)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
         self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
//MED
      else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
         self.weapon = IT_PROXIMITY_GUN;
			if (self.ammo_rockets < 1)
				am = 1;
		}
//MED
      else if (self.weapon == IT_PROXIMITY_GUN)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
      else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}
      else if (self.weapon == IT_LIGHTNING)
		{
         self.weapon = IT_LASER_CANNON;
         if (self.ammo_cells < 1)
				am = 1;
		}
      else if (self.weapon == IT_LASER_CANNON)
		{
         self.weapon = IT_MJOLNIR;
		}

		if ( (self.items & self.weapon) && am == 0)
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
	local	float	it, am;

	it = self.items;
	self.impulse = 0;

	while (1)
	{
		am = 0;

//MED
      if (self.weapon == IT_MJOLNIR)
		{
         self.weapon = IT_LASER_CANNON;
         if (self.ammo_cells < 1)
				am = 1;
		}
//MED
      else if (self.weapon == IT_LASER_CANNON)
		{
         self.weapon = IT_LIGHTNING;
         if (self.ammo_cells < 1)
				am = 1;
		}
      else if (self.weapon == IT_LIGHTNING)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
      else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
         self.weapon = IT_PROXIMITY_GUN;
			if (self.ammo_rockets < 1)
				am = 1;
		}
      else if (self.weapon == IT_PROXIMITY_GUN)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
      else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
      else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SHOTGUN)
		{
			self.weapon = IT_AXE;
		}
		else if (self.weapon == IT_AXE)
		{
         self.weapon = IT_MJOLNIR;
		}

		if ( (it & self.weapon) && am == 0)
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
	if ((deathmatch || coop) && (cheats_allowed == FALSE)) //Ry: Enabled with sv_cheats 1
  {
    sprint(self,"sv_cheats must be enabled!\n");
	  return;
  }
	self.super_time = 1;
	self.super_damage_finished = time + 30;
	self.items = self.items | IT_QUAD;
  if (deathmatch || coop) //Ry: Announce who used the cheat in multiplayer
  {
    bprint (self.netname);
    bprint (" used Quad cheat\n");
  }
  else
    bprint ("Quad cheat\n");
};

//MED
void() WetsuitCheat =
	{
	 if ((deathmatch || coop) && (cheats_allowed == FALSE)) //Ry: Enabled with sv_cheats 1
   {
     sprint(self,"sv_cheats must be enabled!\n");
	 	 return;
   }
   self.items2 = self.items2 | HIP_IT_WETSUIT;
	self.wetsuit_time = 1;
	self.wetsuit_finished = time + 30;
  if (deathmatch || coop) //Ry: Announce who used the cheat in multiplayer
  {
    bprint (self.netname);
    bprint (" used Wetsuit cheat\n");
  }
  else
    bprint( "Wetsuit cheat\n" );
	};

//MED
void() EmpathyShieldsCheat =
	{
	 if ((deathmatch || coop) && (cheats_allowed == FALSE)) //Ry: Enabled with sv_cheats 1
   {
     sprint(self,"sv_cheats must be enabled!\n");
		 return;
   }
   self.items2 = self.items2 | HIP_IT_EMPATHY_SHIELDS;
   self.empathy_time = 1;
   self.empathy_finished = time + 30;
  if (deathmatch || coop) //Ry: Announce who used the cheat in multiplayer
  {
    bprint (self.netname);
    bprint (" used Empathy Shields cheat\n");
  }
  else
    bprint( "Empathy Shields cheat\n" );
	};

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

   if ((deathmatch || coop) && (cheats_allowed == FALSE)) //Ry: Enabled with sv_cheats 1
   {
     sprint(self,"sv_cheats must be enabled!\n");
	 	 return;
   }
   bprint("Genocide!\n");
   head = nextent(world);
   while (head!=world)
      {
      if ((head.health > 0) && (head.flags & FL_MONSTER))
         {
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

void () DeleteWall = //Ry: Just a fun thing (impulse 207)
{
  if (cheats_allowed == FALSE) //Ry: Enabled with sv_cheats 1 only
  {
    sprint(self,"sv_cheats must be enabled!\n");
		return;
  }
  local vector org = self.origin+self.view_ofs;
  traceline (org, org + v_forward*600, TRUE, self);
  if (trace_fraction < 1)
  {
    if ( trace_ent.classname == "func_wall" )
    {
      sprint(self,"Removed wall\n");
      remove(trace_ent);
    }
    else if ( trace_ent.classname == "door" )
    {
      if (!(trace_ent.target)) //Only remove if it's not important for level scripting
      {
        sprint(self,"Removed door\n");
        remove(trace_ent);
      }
    }
  }
}

void () ProbeEntityData = //Ry: Debugging (impulse 208)
{
  local vector org = self.origin+self.view_ofs;
  traceline (org, org + v_forward*600, FALSE, self);
  if ((trace_fraction < 1) && (trace_ent != world))
  {
    dprint("==== ");
    dprint(trace_ent.classname);
    dprint(" ====\n");
    dprint("Origin: ");
    dprint(vtos(trace_ent.origin));
    dprint("\nMins: ");
    dprint(vtos(trace_ent.mins));
    dprint("\nMaxs: ");
    dprint(vtos(trace_ent.maxs));
    dprint("\nTarget: ");
    dprint(trace_ent.target);
    dprint("\nTargetName: ");
    dprint(trace_ent.targetname);
    dprint("\n");
  }
}

//Ry: Following lifted from Dissolution, just with Armagon weapons:
/* Toss out a backpack containing some ammo from your current weapon,
and any weapons you don't have.
*/
void() TossBackpack =
{
	local entity 	item;

	// If we don't have any ammo, return
	if(self.currentammo <= 0)
		return;

	// only valid in teamplay modes
	if (!coop && teamplay < 1) //Ry: Also allow in Friendly Fire-enabled Co-op
		return;

	item = spawn();

	// See if you have the Shotgun or Super Shotgun on
	if ((self.weapon == IT_SHOTGUN) || (self.weapon == IT_SUPER_SHOTGUN)) {
		if( self.ammo_shells >= 20 ) {
			item.ammo_shells = 20;
			self.ammo_shells = self.ammo_shells - 20;
		}
		else
		{
			item.ammo_shells = self.ammo_shells;
			self.ammo_shells = 0;
		}
	}		
	
	// See if you have neither the Shotgun or Super Shotgun
	if ( !(self.items & (IT_SHOTGUN|IT_SUPER_SHOTGUN)) ) {
		if( self.ammo_shells >= 20 ) {
			item.ammo_shells = 20;
			self.ammo_shells = self.ammo_shells - 20;
		} else {
			item.ammo_shells = self.ammo_shells;
			self.ammo_shells = 0;
		}
	}		
	
	// See if we are using a nailgun
	if ((self.weapon == IT_NAILGUN) || (self.weapon == IT_SUPER_NAILGUN) ) {
		if( self.ammo_nails >= 20 ) {
			item.ammo_nails = 20;
			self.ammo_nails = self.ammo_nails - 20;
		} else {
			item.ammo_nails = self.ammo_nails;
			self.ammo_nails = 0;
		}
	}	

	// Check to see if we have neither nailgun
	if ( !( self.items & (IT_NAILGUN|IT_SUPER_NAILGUN)) ) {
		if (self.ammo_nails >= 20) {
			item.ammo_nails = 20;
			self.ammo_nails = self.ammo_nails - 20;
		} else {
			item.ammo_nails = self.ammo_nails;
			self.ammo_nails = 0;
		}
	}	
	
	// See if we are using a grenade or rocket launcher
	if ((self.weapon == IT_GRENADE_LAUNCHER) || (self.weapon == IT_ROCKET_LAUNCHER) || (self.weapon == IT_PROXIMITY_GUN)) {
		if( self.ammo_rockets >= 10 ) {
			item.ammo_rockets = 10;
			self.ammo_rockets = self.ammo_rockets - 10;
		} else {
			item.ammo_rockets = self.ammo_rockets;
			self.ammo_rockets = 0;
		}
	}

	// See if we have neither the Grenade or rocket launcher
	if ( !(self.items & (IT_GRENADE_LAUNCHER|IT_ROCKET_LAUNCHER|IT_PROXIMITY_GUN)) ) {
		if( self.ammo_rockets >= 10 ) {
			item.ammo_rockets = 10;
			self.ammo_rockets = self.ammo_rockets - 10;
		} else {
			item.ammo_rockets = self.ammo_rockets;
			self.ammo_rockets = 0;
		}
	}

	// See if we're using the lightning gun
	if ( (self.weapon == IT_LIGHTNING) || (self.weapon == IT_LASER_CANNON) || (self.weapon == IT_MJOLNIR) ) {	
		if( self.ammo_cells >= 20 ) {
			item.ammo_cells = 20;
			self.ammo_cells = self.ammo_cells - 20;
		} else {
			item.ammo_cells = self.ammo_cells;
			self.ammo_cells = 0;
		}
	}

	// see if we don't have the lightning gun
	if ( !(self.items & (IT_LIGHTNING|IT_LASER_CANNON|IT_MJOLNIR)) ) {	
		if( self.ammo_cells >= 20 ) {
			item.ammo_cells = 20;
			self.ammo_cells = self.ammo_cells - 20;
		} else {
			item.ammo_cells = self.ammo_cells;
			self.ammo_cells = 0;
		}
	}
	 
	if (item.ammo_shells + item.ammo_nails + item.ammo_rockets + item.ammo_cells == 0) {
		sprint(self, "No ammo available!\n");
		remove(item);
		return;
	}
	 
	//item.owner = self;
  item.lastfragtime = time + 0.2; //Ry: Use delay instead of setting owner
	makevectors(self.v_angle);

	setorigin(item, self.origin + '0 0 16');
	item.velocity = aim(self, 1000);
	item.velocity = item.velocity * 500;
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_BOUNCE;

	setmodel (item, "progs/backpack.mdl");
	setsize(item, '-16 -16 0', '16 16 56');
	item.touch = BackpackTouch;
	item.nextthink = time + 120;	// remove after 2 minutes
	item.think = SUB_Remove;

	W_SetCurrentAmmo();
};


/*
============
ImpulseCommands

============
*/
void() ImpulseCommands =
{
	if (self.impulse >= 1 && self.impulse <= 8)
		W_ChangeWeapon ();

   if (self.impulse >= 224 && self.impulse <= 228) //Ry: Updated for Remaster commands
		W_ChangeWeapon ();

	if (self.impulse == 9)
		CheatCommand ();
   if (self.impulse == 10)
		CycleWeaponCommand ();
	if (self.impulse == 11)
		ServerflagsCommand ();
	if (self.impulse == 12)
		CycleWeaponReverseCommand ();
  
  if (self.impulse == 20) //Ry: Dissolution impulse to throw out a backpack with ammo in teamplay modes
    TossBackpack();
    
//JIM
	if ( self.impulse == 200 )
		WetsuitCheat();
//MED
   if ( self.impulse == 201 )
      EmpathyShieldsCheat();
   if ( self.impulse == 205 )
      Genocide();
   if ( self.impulse == 206 )
      ToggleDump();
   if ( self.impulse == 202 )
      DumpEntities();
   if ( self.impulse == 203 )
      DumpLiveEntities();
   if ( self.impulse == 207 )
      DeleteWall();
   if ( self.impulse == 208 )
      ProbeEntityData();
   if (self.impulse == 255)
		QuadCheat ();
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
};

/*
========
SuperDamageSound

Plays sound if needed
========
*/
void() SuperDamageSound =
{
	if (self.super_damage_finished > time)
	{
		if (self.super_sound < time)
		{
			self.super_sound = time + 1;
			sound (self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
		}
	}
	return;
};
