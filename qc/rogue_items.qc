// New Items
//
// Items added for the Rogue XPACK.

void() sphere_spawn;

void(entity theEntity) UpdateAmmoCounts =
{
	if ( theEntity.weapon >= IT_LAVA_NAILGUN ) //Ry: Use the defined entity, not self [10-28-2022]
	{
		theEntity.ammo_shells = theEntity.ammo_shells1;
		theEntity.ammo_nails = theEntity.ammo_lava_nails;
		theEntity.ammo_rockets = theEntity.ammo_multi_rockets;
		theEntity.ammo_cells = theEntity.ammo_plasma;
	}
	else
	{
		theEntity.ammo_shells = theEntity.ammo_shells1;
		theEntity.ammo_nails = theEntity.ammo_nails1;
		theEntity.ammo_rockets = theEntity.ammo_rockets1;
		theEntity.ammo_cells = theEntity.ammo_cells1;
	}
};

void() newitems_touch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
		
	// only one per person, please.
	if (self.classname == "item_sphere")
		if (other.items2 & IT2_V_SPHERE)
			return;

  //Ry: Each player can collect a Belt once in Co-op [09-26-2022]
  if (self.oneperplayer && (self.pickers & other.playerindex))
  {
    #ifndef ENGINE_WINQUAKE
      if (!(self.alpha == 0.25)) //Ry: Item will turn transparent when a player that already used it is standing over it
        self.alpha = 0.25;
      self.nextthink = time + 0.1;
      self.think = TransparentThink;
    #endif
    return;
  }
  
  local float poweruptime; //Ry: Adjust powerup time if it was dropped
  if (self.remaintime > 0)
  {
    poweruptime = time + self.remaintime;
    if ( deathmatch && (poweruptime > (self.nextspawntime - 2)) ) //Ry: Cap powerup time to 2 seconds before it should respawn in Deathmatch
      poweruptime = (self.nextspawntime - 2);
  }
  else if (self.classname == "item_powerup_belt")
    poweruptime = time + 45;
  else
    poweruptime = time + 30;

	if (deathmatch)
	{
		if (self.classname == "item_sphere")
		{
			self.nextspawntime = time + self.respawntime;
			PrepareItemRespawn(self.nextspawntime);
		}
		else if (self.remaintime == 0) //Ry: Regularly spawned powerup (also condensed random powerup into this)
		{
      if (self.lefty) //Ry: Random item
        self.nextspawntime = time + 120;
      else
        self.nextspawntime = time + self.respawntime;
      
      self.pickorigin = self.origin;
      PrepareItemRespawn(self.nextspawntime);
		}
    else //Ry: Dropped powerup. Put it back in it's original spot when it's picked up
    {
      SUB_revertpowerup();
    }
	}

  if (poweruptime > 0) //Ry: Just to make sure
  {
    sprint (other, "You got the ");
    sprint (other, self.netname);
    sprint (other,"\n");

    //Ry: New channel for powerup pickups [09-04-2022]
    sound (other, CHAN_POWERUP, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");
    other.items = other.items | self.items;
    other.items2 = other.items2 | self.items2;

  // do the appropriate action
    if ((self.classname == "item_powerup_shield") && (other.shield_finished < poweruptime)) //Ry: Ensure you don't lose time off your current powerup by picking up a dropped powerup
    {
      other.shield_time = 1;
      other.shield_finished = poweruptime;
      other.shield_item = self;
      other.shield_validdroptime = self.nextspawntime - 5;
    }
    else if ((self.classname == "item_powerup_belt") && (other.antigrav_finished < poweruptime))
    {
      other.antigrav_time = 1;
      other.antigrav_finished = poweruptime;
      other.antigrav_item = self;
      other.antigrav_validdroptime = self.nextspawntime - 5;
    }
    else if (self.classname == "item_sphere")
    {
      other.items2 = other.items2 | IT2_V_SPHERE;
      sphere_spawn();
    }
  }

  if (self.oneperplayer)
  {
    self.pickers = self.pickers + other.playerindex; //Ry: Mark off that this player has picked the item
    UpdateItemVisibility(self,0.25); //Ry: If everyone has the item, hide it
    if (self.solid == SOLID_TRIGGER) //Ry: Otherwise, set the transparency thinker so the item becomes solid when the player steps off it
    {
      self.nextthink = time + 0.1;
      self.think = TransparentThink;
    }
  }
  else
  {
    self.solid = SOLID_NOT;
    self.model = string_null;
    self.effects = 0; //Ry: Disable effect on item
  }
	
	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};


/*QUAKED item_powerup_shield (0 .5 .8) (-16 -16 -24) (16 16 32)
The shield upgrade
*/
void() item_powerup_shield =
{
  missionpackmap = TRUE; //Ry: Map has Rogue entity
	self.touch = newitems_touch;

	precache_model ("progs/shield.mdl");
	precache_model ("progs/p_shield.mdl");
	precache_sound ("shield/pickup.wav");
	precache_sound ("shield/hit.wav");
	precache_sound ("shield/fadeout.wav");
	self.noise = "shield/pickup.wav";
	setmodel (self, "progs/shield.mdl");
	self.netname = "Power Shield";
	self.items2 = IT2_SHIELD;
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 120;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_powerup_belt (0 .5 .8) (-16 -16 -24) (16 16 32)
The anti-grav belt
*/
void() item_powerup_belt =
{
  missionpackmap = TRUE; //Ry: Map has Rogue entity
	self.touch = newitems_touch;

	precache_model ("progs/beltup.mdl");
	precache_sound ("belt/pickup.wav");
	precache_sound ("belt/use.wav");
	precache_sound ("belt/fadeout.wav");
	self.noise = "belt/pickup.wav";
	setmodel (self, "progs/beltup.mdl");
	self.netname = "Anti-Grav Belt";
	self.items2 = IT2_ANTIGRAV;
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 60;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};




