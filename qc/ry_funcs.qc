//Custom funcs and relevant subroutines by Ryason55

//Ry: Custom touchfield for DM2 Lava pit. Using via button will record the activator, and anyone triggering via touching will set the recorded activator as lastdamager on them
void() damageownerfield_touch =
{
  if ( other.flags & (FL_CLIENT | FL_MONSTER) )
  {
    if (time <= (other.lastdamagetime + 3))
      other.lastdamagetime = time;
    else if (self.lastdamager && (self.lastdamager != other)) //Will be set once if the player wasn't already recently damaged by someone else
    {
      other.lastdamager = self.lastdamager;
      other.lastdamagetime = time;
    }

  }
};

void() damageownerfield_use =
{
  self.lastdamager = activator;
}

void() func_damageownerfield =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;

  if (!self.mins && !self.maxs)
  {
    self.mins = '-64 -64 -64';
    self.maxs = '64 64 64';
  }
  setorigin(self,self.origin);
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_TRIGGER;
  self.touch = damageownerfield_touch;
  self.use = damageownerfield_use;
};


void() trigger_teleport;
void() teleport_touch;
float	SILENT = 2;

//Ry: A teleport trigger that also changes what map we'll go to next
void() teleport_togglemap_touch =
{
  local entity ent;
  local string currmap;
  local float count, total;

  //Ry: Only works for Player 1
  ent = find(world,classname,"player");
  if (ent && (other == ent))
  {
    ent = find(world,classname,"trigger_changelevel"); //Ry: Adjust every matching exit to lead to the alternate map
    while (ent)
    {
      total = total + 1;
      if (ent.map == self.map)
      {
        ent.map = self.altmap;
        count = count + 1;
      }
      ent = find(ent,classname,"trigger_changelevel");
    }
    if (count > 0)
    {
      currmap = self.map;
      self.map = self.altmap;
      self.altmap = currmap;
      if (world.model == "maps/start.bsp")
      {
        FilteredCenterPrint_All(CPRINT_WORLD, "The slipgates now lead to ", self.map);
      }
      else
      {
        if (count > 1)
          FilteredCenterPrint_All(CPRINT_WORLD, "Exits now lead to ", self.map);
        else if (total == count)
          FilteredCenterPrint_All(CPRINT_WORLD, "The exit now leads to ", self.map);
        else
          FilteredCenterPrint_All(CPRINT_WORLD, "An exit now leads to ", self.map);
      }
    }
    teleport_touch();
  }
	else if (other.health > 0 || other.classname == "grenade") //Ry: Push away other players
	{
    other.velocity = self.speed * self.movedir * 10;
		if (other.classname == "player")
		{
			if (other.fly_sound < time)
			{
				other.fly_sound = time + 1.5;
				sound (other, CHAN_AUTO, "ambience/windfly.wav", 1, ATTN_NORM);
        FilteredCenterPrint(other, CPRINT_WORLD, "Only ", ent.netname, " can use this");
			}
		}
		if(other.flags & FL_MONSTER) other.flags (-) FL_ONGROUND;
	}
}

void() trigger_teleport_togglenextmap =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;
    
  if (!self.map || !self.altmap) //Ry: If not set up properly, set up as a regular teleport
  {
    dprint("trigger_teleport_togglenextmap missing map definitions; Setting up as regular teleporter\n");
    trigger_teleport();
    return;
  }

  local vector o;

  if (self.targetname) //Ry: Get rid of this if present
    self.targetname = string_null;
  if (self.angles == '0 0 0')
    self.angles = '0 360 0';

	InitTrigger ();
	self.touch = teleport_togglemap_touch;
	// find the destination
	if (!self.target)
		objerror ("no target");

	precache_sound ("ambience/windfly.wav");
	if (!self.speed)
		self.speed = 30;

	if (!(self.spawnflags & SILENT))
	{
		precache_sound ("ambience/hum1.wav");
		o = (self.mins + self.maxs)*0.5;
		ambientsound (o, "ambience/hum1.wav",0.5 , ATTN_STATIC);
	}
}


//Ry: Point entity that will assist monsters in navigating to a foe behind a corner
void() path_trafficmirror =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL))
    return;

  if (!(self.spawnflags & 1)) //Ry: Drop down flag
  {
    if (!droptofloor(0,0))
    {
      dprint("traffic mirror unable to drop to floor\n");
      remove(self);
      return;
    }
  }
  self.origin_z += 24;
  setorigin(self,self.origin);
  
  if (!self.distance)
    self.distance = 32;
}


// ==================
//   Remaster Funcs
// ==================


// ======================================================
/*QUAKED trigger_multitouch (.5 .5 .5) ?
A trigger that fires its targets on "first touch", "emptied" or both

YODER Feb08, 2022
*/
float IGNORE_FIRST_TOUCH = 16;
float IGNORE_EMPTIED = 32;

void() trigger_multitouch_think =
{
    self.wait = 0;
    if (!(self.spawnflags & IGNORE_EMPTIED))
        SUB_UseTargets();
};

void() trigger_multitouch_touch =
{
  if (other.classname != "player")
    return;
	if (other.health <= 0)
		return;

  if (self.wait == 0) // first touch?
  {
      self.wait = 1;
      if (!(self.spawnflags & IGNORE_FIRST_TOUCH))
          SUB_UseTargets();
  }

  // think
  self.think = trigger_multitouch_think;
  self.nextthink = time + 0.2;
};

void() trigger_multitouch =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;

  InitTrigger ();
  self.touch = trigger_multitouch_touch;
  self.wait = 0; // 0 is empty, 1 is touched
};



// =====================
//   Placeholder Funcs
// =====================

#ifndef GAME_HIPNOTIC
  void() weapon_proximity_gun = { remove(self); }
  void() weapon_laser_gun = { remove(self); }
  void() weapon_mjolnir = { remove(self); }
  void() item_artifact_empathy_shields = { remove(self); }
  void() item_artifact_wetsuit = { remove(self); }
  void() item_hornofconjuring = { remove(self); }
  void() func_spawn = { remove(self); }
  void() func_spawn_small = { remove(self); }
#endif

#ifndef GAME_ROGUE
  void() item_powerup_shield = { remove(self); }
  void() item_powerup_belt = { remove(self); }
  void() item_sphere = { remove(self); }
  void() item_random_powerup = { remove(self); }
  void() item_lava_spikes = { remove(self); }
  void() item_multi_rockets = { remove(self); }
  void() item_plasma = { remove(self); }
  void() dmatch_tag_token = { remove(self); }
  void() item_flag_team1 = { remove(self); }
  void() item_flag_team2 = { remove(self); }
  void() item_flag = { remove(self); }
  void() info_player_team1 = { remove(self); }
  void() info_player_team2 = { remove(self); }
#endif