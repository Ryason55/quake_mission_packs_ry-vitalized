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
  if (!EntityValidForMode(FALSE,FALSE)) //Ry: For hybrid horde/campaign maps
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

//Ry: [Unfinished] Pushes back players while allowing monsters through. Can be deactivated with a key, or on use.
void() playerbarrier =
{
  if (!self.mins && !self.maxs)
  {
    self.mins = '-64 -64 -64';
    self.maxs = '64 64 64';
  }
}