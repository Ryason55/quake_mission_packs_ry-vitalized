/*
==============================================================================

spike mine

==============================================================================
*/


//Ry: This file used to be just a prototype, with the actual spike mine being defined in hip_items. For consistency, I moved the relevant Spike Mine stuff here.


//========================
//  Subs added by Ryason
//========================

//Ry: Modified visible check that also traces from the corners of self. Expects that the target is the same size or bigger.
float(entity targ) spikemine_visible =
{
	local vector	spot1, spot2, vec_offs;
  local float x,y,z;

	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;
  traceline (spot1, spot2, TRUE, self);

	if (trace_inopen && trace_inwater)
		return FALSE;			// sight line crossed contents

	if (trace_fraction == 1)
  {
    visible_distance = vlen(spot2-spot1);
    spot1 = self.origin;
    spot2 = targ.origin;
    x = 2;
    while (x) //Ry: Iterate over all corners
    {
      y = 2;
      while (y)
      {
        z = 2;
        while (z)
        {
          vec_offs = '0 0 0';

          if (x > 1)
            vec_offs_x = self.maxs_x;
          else
            vec_offs_x = self.mins_x;

          if (y > 1)
            vec_offs_y = self.maxs_y;
          else
            vec_offs_y = self.mins_y;

          if (z > 1)
            vec_offs_z = self.maxs_z;
          else
            vec_offs_z = self.mins_z;

          traceline (spot1+vec_offs, spot2+vec_offs, TRUE, self);
          if (trace_fraction < 1)
          {
            return FALSE;
          }

          z = z - 1;
        }
        y = y - 1;
      }
      x = x - 1;
    }
    return TRUE;
  }
	return FALSE;
};

//===================
//  End of new subs
//===================



void() spikemine_Home =
{
  local entity head, selected, stemp;
  local float cur_dist;
  local float head_dist;
  local vector dir, vtemp;

  self.frame = self.frame + 1;
  if (self.frame==9) self.frame = 0;
  self.nextthink = time + 0.2;
  self.think = spikemine_Home;

// look in our immediate vicinity

  if (self.search_time < time)
  {
    selected = world;
    cur_dist = 2000;
    head = findradius(self.origin, 2000);
    while(head)
    {
      if (!(head.flags & FL_NOTARGET) && (head.flags & FL_CLIENT))
      {
        if (spikemine_visible(head) && (head.health > 0)) //Ry: Modified visible function that also checks from corners
        {
          head_dist = vlen(head.origin-self.origin);
          if (head_dist < cur_dist)
          {
            selected = head;
            cur_dist = head_dist;
          }
        }
      }
      head = head.chain;
    }
//    if (selected != world && selected != self.enemy)
    if (selected != world)
      sound (self, CHAN_VOICE, "hipitems/spikmine.wav", 1, ATTN_NORM);
    self.enemy = selected;
    self.search_time = time + 1.3;
  }
  if (self.enemy == world)
  {
    sound (self, CHAN_VOICE, "misc/null.wav", 1, ATTN_NORM);
    self.velocity = '0 0 0';
    return;
  }
  vtemp = self.enemy.origin + '0 0 10';
	dir = normalize(vtemp - self.origin);
  stemp = self; //Ry: Fixed this, because before it was checking if the *mine* was facing the target
  self = stemp.enemy;
  if (infront(stemp))
    stemp.velocity = dir * ((skill*50) + 50);
  else
    stemp.velocity = dir * ((skill*50) + 150);
  self = stemp;
};

void() spikemine_Touch =
{
  if (self.health>0)
  {
    if (other.classname == "trap_spike_mine")
      return;
    if (other.classname == "missile")
      return;
    if (other.classname == "grenade")
      return;
    if (other.classname == "hiplaser")
      return;
    if (other.classname == "proximity_grenade")
      return;

    T_Damage(self,self,self,self.health+10);
  }

  T_RadiusDamage (self, self, 110, world);
	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

  sound (self, CHAN_VOICE, "misc/null.wav", 1, ATTN_NORM);
  self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};

/*
spike_mine_first_think
*/

void() spike_mine_first_think =
{
  self.think = spikemine_Home;
  self.nextthink = time + 0.1;
  self.search_time = 0;
  self.takedamage = DAMAGE_AIM;
	self.use = monster_use;
};

/*QUAKED trap_spike_mine (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() trap_spike_mine =
{
  hipnoticmap = TRUE; //Ry: Map has Hipnotic entity

  if (!EntityValidForMode(TRUE,FALSE)) //Ry: New function to handle func_spawn and horde mode
	{
		remove(self);
		return;
	}
  precache_model ("progs/spikmine.mdl");
  precache_sound ("weapons/r_exp3.wav");
  precache_sound ("hipitems/spikmine.wav");
  precache_sound ("misc/null.wav");
  self.netname = "Spike Mine"; //Ry: Name for Deathmatch
  setmodel (self, "progs/spikmine.mdl");
  setsize (self,VEC_HULL_MIN,VEC_HULL_MAX); //Ry: Give the Spike Mine the smaller size
  self.classname = "trap_spike_mine";
  self.solid = SOLID_BBOX;
  self.movetype = MOVETYPE_FLYMISSILE;

  self.avelocity = '-50 100 150';
  if (cvar("skill") <= 1)
    self.health = 200;
  else
    self.health = 400;
  self.frame = 0;
  self.think = spike_mine_first_think;
  self.touch = spikemine_Touch;
  self.th_die = spikemine_Touch;
  self.th_stand = spikemine_Home;
  self.th_walk = spikemine_Home;
  self.th_run = spikemine_Home;
  self.th_melee = spikemine_Home;
  self.th_missile = spikemine_Home;
  self.nextthink = time + 0.2;
  total_monsters = total_monsters + 1;
  self.flags = self.flags | FL_MONSTER;
  self.deathtype = "was blasted by a spike mine";
};

void() monster_spikemine =
{
  trap_spike_mine();
};
