void() W_SetCurrentAmmo;
void() W_UpdateAmmo; //Ry: Added function name reference here
/* ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR */

void() SUB_regen =
{
	self.model = self.mdl;		// restore original model
	self.solid = SOLID_TRIGGER;	// allow it to be touched again
  SetLightEffect(self,self.itemeffect,TRUE); //Ry: Add item effect if defined
  #ifndef ENGINE_WINQUAKE
    self.alpha = 0; //Ry: Remove alpha effects
  #endif
	sound (self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);	// play respawn sound
	setorigin (self, self.origin);
};



//======================
//  New Subs by Ryason
//======================

void(vector org) spawn_tfog;

#ifdef GAME_HIPNOTIC
  void() GremlinItemSafety = //Ry: Ensure that a weapon item dropped by a Gremlin warps back if it ends up unreachable
  {
    local float content;
    if (self.solid == SOLID_TRIGGER)
    {
      content = pointcontents(self.origin);
      if ( (content == CONTENT_SOLID) || (content == CONTENT_SKY) || (self.watertype == CONTENT_SLIME) || (self.watertype == CONTENT_LAVA) || ((world.model == "maps/hipdm1.bsp") && ( self.origin_z < -1300 )) )
      {
        self.waterlevel = 0;
        if (self.static)
          self.movetype = MOVETYPE_FLY;
        setorigin(self,self.pickorigin);
        spawn_tfog(self.origin);
        self.displaced = FALSE;
      }
      else
        self.nextthink = time + 1;
    }
  };
#endif

void(entity item, float newalpha) UpdateItemVisibility = //Ry: In Co-op, set item to be transparent if all active players have picked the item
{
  if (coop)
  {
    local float currindex = 1;
    while (currindex <= highestplayerindex) //Ry: Check if any active players don't have the item
    {
      if ( (playerindexinuse & currindex) && !(item.pickers & currindex) )
      {
        #ifndef ENGINE_WINQUAKE
          item.alpha = newalpha;
        #endif
        if (item.solid != SOLID_TRIGGER) //Ry: Show the item again if it was hidden
        {
          item.solid = SOLID_TRIGGER;
          item.model = item.mdl;
        }
        return;
      }
      currindex = currindex * 2;
    }
    #ifndef ENGINE_WINQUAKE
      item.alpha = 0;
    #endif
    if (item.solid != SOLID_NOT) //Ry: If everyone has the item, hide it
    {
      item.model = string_null;
      item.solid = SOLID_NOT;
      if (item.displaced) //Ry: Put back where it belongs if it was displaced by a Gremlin
      {
        item.waterlevel = 0;
        if (item.static)
          item.movetype = MOVETYPE_FLY;
        setorigin(item,item.pickorigin);
        item.displaced = FALSE;
      }
    }
  }
}

void() TransparentThink = //Ry: Thinker version of the above
{
  UpdateItemVisibility(self,0);
  #ifdef GAME_HIPNOTIC
    if (self.displaced) //Ry: Reinstate safety thinker if it was running
    {
      self.think = GremlinItemSafety;
      self.nextthink = time + 1;
    }
  #endif
}

void() CreateExtraItemThinker = //Ry: External thinker for items, written to "trigger_field"
{
  if (!self.trigger_field)
  {
    self.trigger_field = spawn();
    self.trigger_field.classname = "itemthinker";
    self.trigger_field.origin = self.origin;
    self.trigger_field.origin_z = (self.trigger_field.origin_z + self.mins_z + 1000);
    self.trigger_field.enemy = self;
    self.trigger_field.respawntime = self.respawntime;
  }
}

#ifdef GAME_ROGUE
  void() random_regen;
  void() random_pick_type;
#endif

#ifndef ENGINE_WINQUAKE
  void() ItemPreSpawnGhost = //Ry: Show a ghost of the item shortly before spawning
  {
    self = self.enemy;
    #ifdef GAME_ROGUE
      if (self.lefty) //Ry: If is the random item, choose the next item at this point [09-01-2022]
        random_pick_type();
    #endif
    if (self.model == string_null)
      self.model = self.mdl;
    self.alpha = 0.2;
  }
#endif

void(float spawntime) PrepareItemRespawn =
{
  self.nextthink = spawntime;
  self.think = SUB_regen;
  #ifndef ENGINE_WINQUAKE
    if (deathmatch)
    {
      if (time >= (spawntime-5))
      {
        self.model = self.mdl;
        self.alpha = 0.2;
        if (self.trigger_field)
          self.trigger_field.nextthink = -1;
      }
      else
      {
        CreateExtraItemThinker();
        self.trigger_field.think = ItemPreSpawnGhost;
        self.trigger_field.nextthink = spawntime-5;
      }
    }
  #elifdef GAME_ROGUE
    if (self.lefty) //Ry: Random powerup
      self.think = random_regen;
  #endif
}

void() SUB_revertpowerup = //Ry: Put the powerup back into position for spawning normally
{
	self.solid = SOLID_NOT;
	self.model = string_null;
	setorigin (self, self.pickorigin);
  self.remaintime = 0;
  self.effects = 0;
  if (self.static) //Ry: Ensure no gravity is restored if the item is supposed to float
    self.movetype = MOVETYPE_FLY;
  if (deathmatch)
    PrepareItemRespawn(self.nextspawntime); //Ry: Now also sets up a ghost for the item when close to spawning
}

void(entity item, entity player) droppowerup = //Ry: Make the dropped powerup functional again, and place it where the player died
{
  //Ry: Don't drop powerups that everyone can pick [09-26-2022]
  if (item.oneperplayer)
    return;
  item.model = item.mdl;
  SetLightEffect(item,item.itemeffect,TRUE); //Ry: Add item effect if defined
  item.flags -= (item.flags & FL_ONGROUND);
  item.watertype = CONTENT_EMPTY;
  item.waterlevel = 0;
  setorigin(item,player.origin);
  item.solid = SOLID_TRIGGER;
  item.movetype = MOVETYPE_TOSS;
  item.velocity_z = 300;
  item.velocity_x = -100 + (random() * 200);
  item.velocity_y = -100 + (random() * 200);
  if (deathmatch)
  {
    if (self.trigger_field) //Ry: Disable item ghost thinker
      self.trigger_field.nextthink = -1;
    if (item.nextspawntime-time < 35)
      item.nextthink = item.nextspawntime - 5;
    else
      item.nextthink = time + 30;
    item.think = SUB_revertpowerup;
  }
}

void() DropPowerups = //Ry: New function for dropping each powerup on death
{
  if ( (self.super_damage_finished - time > 3) && ( coop || (time < self.super_validdroptime) ) && self.super_item )
  {
    self.super_item.remaintime = self.super_damage_finished - time;
    self.super_damage_finished = 0;
    self.super_time = 0;
    self.items = self.items - IT_QUAD;
    droppowerup(self.super_item,self);
  }
  if ( (self.invincible_finished - time > 3) && ( coop || (time < self.invincible_validdroptime) ) && self.invincible_item )
  {
    self.invincible_item.remaintime = self.invincible_finished - time;
    self.invincible_finished = 0;
    self.invincible_time = 0;
    self.items = self.items - IT_INVULNERABILITY;
    droppowerup(self.invincible_item,self);
  }
  if ( (self.invisible_finished - time > 3) && ( coop || (time < self.invisible_validdroptime) ) && self.invisible_item )
  {
    self.invisible_item.remaintime = self.invisible_finished - time;
    self.invisible_finished = 0;
    self.invisible_time = 0;
    self.items = self.items - IT_INVISIBILITY;
    droppowerup(self.invisible_item,self);
  }
  if ( (self.radsuit_finished - time > 3) &&  ( coop || (time < self.radsuit_validdroptime) ) && self.radsuit_item )
  {
    self.radsuit_item.remaintime = self.radsuit_finished - time;
    self.radsuit_finished = 0;
    self.rad_time = 0;
    self.items = self.items - IT_SUIT;
    droppowerup(self.radsuit_item,self);
  }
  #ifdef GAME_HIPNOTIC
    if ( (self.empathy_finished - time > 3) && ( coop || (time < self.empathy_validdroptime) ) && self.empathy_item ) //Ry: SoA Powerups
    {
      self.empathy_item.remaintime = self.empathy_finished - time;
      self.empathy_finished = 0;
      self.empathy_time = 0;
      self.items2 = self.items2 - HIP_IT_EMPATHY_SHIELDS;
      droppowerup(self.empathy_item,self);
    }
    if ( (self.wetsuit_finished - time > 3) && ( coop || (time < self.wetsuit_validdroptime) ) && self.wetsuit_item )
    {
      self.wetsuit_item.remaintime = self.wetsuit_finished - time;
      self.wetsuit_finished = 0;
      self.wetsuit_time = 0;
      self.items2 = self.items2 - HIP_IT_WETSUIT;
      droppowerup(self.wetsuit_item,self);
    }
  #endif
  #ifdef GAME_ROGUE
    if ( (self.shield_finished - time > 3) && ( coop || (time < self.shield_validdroptime) ) && self.shield_item ) //Ry: DoE Powerups
    {
      self.shield_item.remaintime = self.shield_finished - time;
      self.shield_finished = 0;
      self.shield_time = 0;
      self.items2 = self.items2 - IT2_SHIELD;
      droppowerup(self.shield_item,self);
    }
    if ( (self.antigrav_finished - time > 3) && ( coop || (time < self.antigrav_validdroptime) ) && self.antigrav_item )
    {
      self.antigrav_item.remaintime = self.antigrav_finished - time;
      self.antigrav_finished = 0;
      self.antigrav_time = 0;
      self.items2 = self.items2 - IT2_ANTIGRAV;
      droppowerup(self.antigrav_item,self);
    }
  #endif
  self.effects = 0;
}

void(entity item) RecoverItem =
{
  item.lastfragtime = time + 2;
  item.flags -= (item.flags & FL_ONGROUND);
  item.watertype = CONTENT_EMPTY;
  item.waterlevel = 0;
  setorigin(item,item.lastsafevect);
  item.solid = SOLID_TRIGGER;
  item.movetype = MOVETYPE_TOSS;
  item.velocity_z = 200;
  item.velocity_x = -1 + (random() * 2);
  item.velocity_y = -1 + (random() * 2);
  makevectors(item.angles);
  spawn_tfog(item.origin);
}

void() PlayerBackpackSafety = //Ry: Make sure a backpack dropped by a player stays collectable
{
  if (self.owner && self.owner.view_ofs == '0 0 0') //Ry: Return backpack contents immediately if players are exiting the level
  {
    local float acount = 0;
    self.owner.AMMO_SHELLS += self.AMMO_SHELLS;
    self.owner.AMMO_NAILS += self.AMMO_NAILS;
    self.owner.AMMO_ROCKETS += self.AMMO_ROCKETS;
    self.owner.AMMO_CELLS += self.AMMO_CELLS;
    
    if (self.owner.AMMO_SHELLS > 100)
      self.owner.AMMO_SHELLS = 100;
    if (self.owner.AMMO_NAILS > 200)
      self.owner.AMMO_NAILS = 200;
    if (self.owner.AMMO_ROCKETS > ammocap_rockets)
      self.owner.AMMO_ROCKETS = ammocap_rockets;
    if (self.owner.AMMO_CELLS > 100)
      self.owner.AMMO_CELLS = 100;
    
    #ifdef GAME_ROGUE
      self.owner.ammo_lava_nails += self.ammo_lava_nails;
      self.owner.ammo_multi_rockets += self.ammo_multi_rockets;
      self.owner.ammo_plasma += self.ammo_plasma;
      
      if (self.owner.ammo_lava_nails > ammocap_lava)
        self.owner.ammo_lava_nails = ammocap_lava;
      if (self.owner.ammo_multi_rockets > ammocap_multi)
        self.owner.ammo_multi_rockets = ammocap_multi;
      if (self.owner.ammo_plasma > ammocap_plasma)
        self.owner.ammo_plasma = ammocap_plasma;
    #endif
    
    sprint(self.owner,"Reclaimed "); //Ry: Let player know they got their stuff back
    if (self.AMMO_SHELLS > 0)
    {
      acount = 1;
      sprint (self.owner, ftos(self.AMMO_SHELLS) );
      sprint (self.owner, " shells");
    }
    if (self.AMMO_NAILS > 0)
    {
      if (acount)
        sprint(self.owner, ", ");
      acount = 1;
      sprint (self.owner, ftos(self.AMMO_NAILS) );
      sprint (self.owner, " nails");
    }
    if (self.AMMO_ROCKETS > 0)
    {
      if (acount)
        sprint(self.owner, ", ");
      acount = 1;
      sprint (self.owner, ftos(self.AMMO_ROCKETS) );
      sprint (self.owner, " rockets");
    }
    if (self.AMMO_CELLS > 0)
    {
      if (acount)
        sprint(self.owner, ", ");
      acount = 1;
      sprint (self.owner, ftos(self.AMMO_CELLS) );
      sprint (self.owner, " cells");
    }
    #ifdef GAME_ROGUE
      if (self.ammo_lava_nails > 0)
      {
        if (acount)
          sprint(self.owner, ", ");
        acount = 1;
        sprint (self.owner, ftos(self.ammo_lava_nails) );
        sprint (self.owner, " lava nails");
      }
      if (self.ammo_multi_rockets > 0)
      {
        if (acount)
          sprint(self.owner, ", ");
        acount = 1;
        sprint (self.owner, ftos(self.ammo_multi_rockets) );
        sprint (self.owner, " multi rockets");
      }
      if (self.ammo_plasma > 0)
      {
        if (acount)
          sprint(self.owner, ", ");
        acount = 1;
        sprint (self.owner, ftos(self.ammo_plasma) );
        sprint (self.owner, " plasma balls");
      }
    #endif
    sprint (self.owner, "\n");
    
    remove(self);
    return;
  }
  else if ( (self.watertype == CONTENT_SLIME) || (self.watertype == CONTENT_LAVA) || ((world.model == "maps/hipdm1.bsp") && ( self.origin_z < -1300 )) )
    RecoverItem(self);
  
  else if (self.owner && !(self.owner.flags & FL_CLIENT)) //Ry: Owner disconnected
  {
    self.owner = entity_null;
    self.effects = 0;
    self.nextthink = time + 120;
    self.think = SUB_Remove;
    return;
  }
    
  self.nextthink = time + 1;
}

#ifdef GAME_HIPNOTIC
  void() GremlinBackpackSafety = //Ry: Trimmed version of above for Gremlin backpacks
  {
    if ( (self.watertype == CONTENT_SLIME) || (self.watertype == CONTENT_LAVA) || ((world.model == "maps/hipdm1.bsp") && ( self.origin_z < -1300 )) )
      RecoverItem(self);

    self.nextthink = time + 1;
  }
#endif

void() RecordSafeVect =
{
  if ( (self.flags & FL_ONGROUND) && ((self.movetype == MOVETYPE_WALK) || (self.movetype == MOVETYPE_STEP))
       && self.waterlevel <= 1 && !((self.watertype == CONTENT_SLIME) || (self.watertype == CONTENT_LAVA)) && (time >= (self.lastsafecheck + 0.25)) )
  {
    self.lastsafecheck = time;
    traceline(self.origin, self.origin + '0 0 -36', 1, self); //Ry: Ensure over solid level geometry (no moving platforms)
    if ( (trace_fraction < 1) && (trace_ent == world) )
      self.lastsafevect = self.origin;
  }
}

string(float weapon) GetWeaponName =
{
  if (weapon == IT_AXE)
    return "Axe";
  else if (weapon == IT_SHOTGUN)
    return "Shotgun";
  else if (weapon == IT_SUPER_SHOTGUN)
    return "Double-barrelled Shotgun";
  else if (weapon == IT_NAILGUN)
    return "Nailgun";
  else if (weapon == IT_SUPER_NAILGUN)
    return "Super Nailgun";
  else if (weapon == IT_GRENADE_LAUNCHER)
    return "Grenade Launcher";
  else if (weapon == IT_ROCKET_LAUNCHER)
    return "Rocket Launcher";
  else if (weapon == IT_LIGHTNING)
    return "Thunderbolt";
  #ifdef GAME_HIPNOTIC
    else if (weapon == IT_PROXIMITY_GUN)
      return "Proximity Gun";
    else if (weapon == IT_LASER_CANNON)
      return "Laser Cannon";
    else if (weapon == IT_MJOLNIR)
      return "Mjolnir";
  #endif
  #ifdef GAME_ROGUE
    else if (weapon == IT_LAVA_NAILGUN)
      return "Lava Nailgun";
    else if (weapon == IT_LAVA_SUPER_NAILGUN)
      return "Super Lava Nailgun";
    else if (weapon == IT_MULTI_GRENADE)
      return "Multi Grenade Launcher";
    else if (weapon == IT_MULTI_ROCKET)
      return "Multi Rocket Launcher";
    else if (weapon == IT_PLASMA_GUN)
      return "Plasma Gun";
  #endif
  return "";
}

float take_stolenweps, take_weps;

void(float weapon, float gremallowed) BackpackWeaponTake =
{
  if (self.items & weapon) //Ry: self is the item, other is the picker
  {
    #ifdef GAME_HIPNOTIC
      if (other.classname == "monster_gremlin")
      {
        if ( gremallowed && !(other.items & weapon) )
        {
          self.items = self.items - weapon;
          other.items |= weapon;
          if ( self.stolenitems & weapon )
            other.stolenitems |= weapon;
          take_weps += 1;
        }
      }
      //Ry: Player can collect if it isn't Co-op, or it's not a stolen weapon and they don't already have it, or that weapon had been stolen from them
      else if ( (other.flags & FL_CLIENT) && ( !coop || ( ((other.items & weapon) && !(self.stolenitems & weapon)) || (other.stolenitems & weapon)) ) )
      {
        if (other.stolenitems & weapon)
        {
          if (take_stolenweps == 0)
            sprint(other, "Retrieved your ");
          else
            sprint(other, ", ");
          sprint(other, GetWeaponName(weapon));
          take_stolenweps += 1;
        }
        else
        {
          self.netname = GetWeaponName(weapon);
        }
        take_weps += 1;
        
        self.items = self.items - weapon;
        other.items |= weapon;
        other.stolenitems -= (other.stolenitems & weapon);
      }
    #else
      if (!coop || !(other.items & weapon)) //Ry: Weapons in backpacks should no longer come up in Co-op in other games, but just in case
      {
        self.netname = GetWeaponName(weapon);
        take_weps += 1;
        self.items = self.items - weapon;
        other.items |= weapon;
      }
    #endif
  }
}

//===================
//  End of new subs
//===================



/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
void() noclass =
{
	dprint ("noclass spawned at");
	dprint (vtos(self.origin));
	dprint ("\n");
	remove (self);
};

/*
============
PlaceItem

plants the object on the floor
============
*/
void() PlaceItem =
{
	local float	oldz;
  
  if (!EntityValidForMode(ENTTYPE_GAMEPLAY)) //Ry: Don't place items unless flagged in hybrid maps
  {
    remove(self);
    return;
  }

	self.mdl = self.model;		// so it can be restored on respawn
	self.flags |= FL_ITEM;		// make extra wide  //Ry: Allow flags to have been previously applied [09-01-2022]
	self.solid = SOLID_TRIGGER;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	oldz = self.origin_z;
  
  self.pickorigin = self.origin; //Ry: For dropping powerups
  self.remaintime = 0;
  self.nextspawntime = 0;
  if (!self.category)
    self.category = "item"; //Ry: For easy searching
  
  //Ry: Set respawn time if an override is set
  if ( ((!deathmatch) && (!coop)) && (self.respawntimesp > 0) )
  {
    self.respawntime = self.respawntimesp;
  }
  else if ( (coop) && (self.respawntimecoop > 0) )
  {
    self.respawntime = self.respawntimecoop;
  }
  else if ( (deathmatch) && (self.respawntimedm > 0) )
  {
    self.respawntime = self.respawntimedm;
  }

  //Ry: Unset oneperplayer if there's a respawn time
  if (self.oneperplayer && (self.respawntime || !coop))
    self.oneperplayer = FALSE;

  if (self.static) //Ry: Added capability for items to be placed in the air
  {
    self.movetype = MOVETYPE_FLY;
  }
  else
  {
    self.movetype = MOVETYPE_TOSS;
    if (!droptofloor(0, 0))
    {
      dprint ("Bonus item fell out of level at ");
      dprint (vtos(self.origin));
      dprint ("\n");
      remove(self);
      return;
    }
    //Ry: If the item is on an elevator, attach to the elevator [06-26-2022]
    traceline(self.origin + '0 0 4', self.origin + '0 0 -32', TRUE, self);
    if ( trace_fraction < 1 && ( ((trace_ent.classname == "door") && (trace_ent.movedir_z != 0)) || (trace_ent.classname == "plat") ) )
    {
      self.owner = trace_ent;
      self.effectiveorigin = self.origin - trace_ent.origin;
      self.movetype = MOVETYPE_NOCLIP;
      while (trace_ent.super_item) //Ry: Make an entity chain, starting from the elevator
        trace_ent = trace_ent.super_item;
      trace_ent.super_item = self;
    }
  }
  
  if (self.delayspawn > 0.2) //Ry: Delayed spawning
  {
    self.solid = SOLID_NOT;
    self.model = string_null;
    PrepareItemRespawn(time + self.delayspawn - 0.2); //Ry: Now also sets up a ghost for the item when close to spawning
  }
  else
    SetLightEffect(self,self.itemeffect,TRUE); //Ry: Add item effect if defined
  
};

/*
============
StartItem

Sets the clipping size and plants the object on the floor
============
*/
void() StartItem =
{
  self.nextthink = time + 0.2;	// items start after other solids
  self.think = PlaceItem;
};

/*
=========================================================================

HEALTH BOX

=========================================================================
*/
//
// T_Heal: add health to an entity, limiting health to max_health
// "ignore" will ignore max_health limit
//
float (entity e, float healamount, float ignore) T_Heal =
{
	if (e.health <= 0)
		return 0;
	if ((!ignore) && (e.health >= other.max_health))
		return 0;
	healamount = ceil(healamount);

	e.health = e.health + healamount;
	if ((!ignore) && (e.health >= other.max_health))
		e.health = other.max_health;

	if (e.health > 250)
		e.health = 250;
	return 1;
};

/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
Health box. Normally gives 25 points.
Rotten box heals 5-10 points,
megahealth will add 100 health, then
rot you down to your maximum health limit,
one point per second.
*/

float	H_ROTTEN = 1;
float	H_MEGA = 2;
.float	healamount, healtype;
void() health_touch;
void() item_megahealth_rot;

void() item_health =
{
	self.touch = health_touch;
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 20;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;

	if (self.spawnflags & H_ROTTEN)
	{
		precache_model("maps/b_bh10.bsp");

		precache_sound("items/r_item1.wav");
		setmodel(self, "maps/b_bh10.bsp");
		self.noise = "items/r_item1.wav";
		self.healamount = 15;
		self.healtype = 0;
	}
	else
	if (self.spawnflags & H_MEGA)
	{
    
		precache_model("maps/b_bh10.bsp"); //Ry: Precache lower items
		precache_sound("items/r_item1.wav");
		precache_model("maps/b_bh25.bsp");
		precache_sound("items/health1.wav");
    
		precache_model("maps/b_bh100.bsp");
		precache_sound("items/r_item2.wav");
		setmodel(self, "maps/b_bh100.bsp");
		self.noise = "items/r_item2.wav";
		self.healamount = 100;
		self.healtype = 2;
	}
	else
	{
    
		precache_model("maps/b_bh10.bsp"); //Ry: Precache lower item
		precache_sound("items/r_item1.wav");
    
		precache_model("maps/b_bh25.bsp");
		precache_sound("items/health1.wav");
		setmodel(self, "maps/b_bh25.bsp");
		self.noise = "items/health1.wav";
		self.healamount = 25;
		self.healtype = 1;
	}
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


void() health_touch =
{
	local	string	s;

	if (other.classname != "player")
		return;
  
  if ( self.oneperplayer && (self.pickers & other.playerindex) ) //Ry: Cancel if player has already collected the item
  {
    #ifndef ENGINE_WINQUAKE
      if (!(self.alpha == 0.25)) //Ry: Item will turn transparent when a player that already used it is standing over it
        self.alpha = 0.25;
      self.nextthink = time + 0.1;
      self.think = TransparentThink;
    #endif
    return;
  }

	if (self.healtype == 2) // Megahealth?  Ignore max_health...
	{
		if (other.health >= 250)
			return;
		if (!T_Heal(other, self.healamount, 1))
			return;
	}
	else
	{
		if (!T_Heal(other, self.healamount, 0))
			return;
	}

	sprint(other, "You receive ");
	s = ftos(self.healamount);
	sprint(other, s);
	sprint(other, " health\n");

// health touch sound
	sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

	stuffcmd (other, "bf\n");
  
  if (!self.oneperplayer) //Ry: Leave health in Co-op
  {
    self.model = string_null;
    self.solid = SOLID_NOT;
  }

	// Megahealth = rot down the player's super health
	if (self.healtype == 2)
	{
// 11/02/96 removed SUPERHEALTH from defs.qc
//      other.items = other.items | IT_SUPERHEALTH;
    if (self.respawntime)
    {
      CreateExtraItemThinker(); //Ry: Separate entity to do the thinking; Co-op has a thinker for the transparency, and the 1 second nextthinks from rotting screw with bots in DM
      self.trigger_field.nextthink = time + 5;
      self.trigger_field.think = item_megahealth_rot;
      self.trigger_field.owner = other;
      
      if (self.respawntime && (deathmatch != 2)) //Ry: Max time; Rot thinker will lower it to respawntime when the rotting has finished
      {
        self.nextthink = time + 300;
        self.think = SUB_regen;
      }
    }
    other.megarot_time = time + 5; //Ry: Set rotting on the player [06-30-2022]
    other.megarot_count += 1;
    if (!deathmatch && other.megarot_count > 1)
      other.megarot_count = 1;
	}
	else if (self.respawntime && (deathmatch != 2))
	{
    PrepareItemRespawn(time + self.respawntime); //Ry: Now also sets up a ghost for the item when close to spawning
	}
  
  if (self.oneperplayer)
  {
    if (self.healtype > 0) //Ry: Demote the item each pick
    {
      if (self.healtype == 2) //Ry: Demote to 25
      {
        self.mdl = "maps/b_bh25.bsp";
        self.noise = "items/health1.wav";
        self.healamount = 25;
        self.healtype = 1;
      }
      else //Ry: Demote to 15
      {
        self.mdl = "maps/b_bh10.bsp";
        self.noise = "items/r_item1.wav";
        self.healamount = 15;
        self.healtype = 0;
      }
      setmodel(self,self.mdl);
      setsize (self, '0 0 0', '32 32 56');
    }
    self.pickers = self.pickers + other.playerindex; //Ry: Mark off that this player has picked the item
    UpdateItemVisibility(self,0.25); //Ry: If everyone has the item, hide it
    if (self.solid == SOLID_TRIGGER) //Ry: Otherwise, set the transparency thinker so the item becomes solid when the player steps off it
    {
      self.nextthink = time + 0.1;
      self.think = TransparentThink;
    }
  }

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

void() item_megahealth_rot =
{
	other = self.owner;

	if (other.health > other.max_health)
	{
		//other.health = other.health - 1; //Ry: HP reduction is now handled on the player entity [06-30-2022]
		self.nextthink = time + 1;
		return;
	}

// it is possible for a player to die and respawn between rots, so don't
// just blindly subtract the flag off
// MED 11/02/96 removed SUPERHEALTH
//   other.items = other.items - (other.items & IT_SUPERHEALTH);

  if (coop || deathmatch)
  {
    if (self.oneperplayer || !self.enemy.respawntime) //Ry: Multiplayer modes now use a separate thinker for the rotting, which can be removed when the rot is done
    {
      remove(self);
    }
    else if ( (deathmatch != 2) && (self.enemy.model == string_null) )
    {
      self = self.enemy;
      PrepareItemRespawn(time + self.respawntime); //Ry: Now also sets up a ghost for the item when close to spawning
    }
  }
};

/*
===============================================================================

ARMOR

===============================================================================
*/

void() armor_touch;

void() armor_touch =
{
	local	float	type, value, bit;

	if (other.health <= 0)
		return;
	if (other.classname != "player")
		return;
  
  if ( self.oneperplayer && (self.pickers & other.playerindex) ) //Ry: Cancel if player has already collected the item
  {
    #ifndef ENGINE_WINQUAKE
      if (!(self.alpha == 0.25)) //Ry: Item will turn transparent when a player that already used it is standing over it
        self.alpha = 0.25;
      self.nextthink = time + 0.1;
      self.think = TransparentThink;
    #endif
    return;
  }

	if (self.classname == "item_armor1")
	{
		type = 0.3;
		value = 100;
    #ifdef GAME_ROGUE
      bit = IT2_ARMOR1;
    #else
      bit = IT_ARMOR1;
    #endif
   }
	if (self.classname == "item_armor2")
	{
		type = 0.6;
		value = 150;
    #ifdef GAME_ROGUE
      bit = IT2_ARMOR2;
    #else
      bit = IT_ARMOR2;
    #endif
	}
	if (self.classname == "item_armorInv")
	{
		type = 0.8;
		value = 200;
    #ifdef GAME_ROGUE
      bit = IT2_ARMOR3;
    #else
      bit = IT_ARMOR3;
    #endif
	}
	if (other.armortype*other.armorvalue >= type*value)
		return;

	other.armortype = type;
	other.armorvalue = value;
  #ifdef GAME_ROGUE
    other.items2 = other.items2 - (other.items2 & (IT2_ARMOR1 | IT2_ARMOR2 | IT2_ARMOR3)) + bit;
  #else
    other.items = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + bit;
  #endif

  
  if (self.oneperplayer)
  {
    if (self.classname != "item_armor1") //Ry: Demote the item each pick
    {
      if (self.classname == "item_armorInv") //Ry: Demote to Yellow
      {
        self.classname = "item_armor2";
        self.skin = 1;
        self.armortype = 0.6;
        self.armorvalue = 150;
      }
      else //Ry: Demote to Green
      {
        self.classname = "item_armor1";
        self.skin = 0;
        self.armortype = 0.3;
        self.armorvalue = 100;
      }
    }
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
    if ( self.respawntime && (deathmatch != 2) )
    {
      PrepareItemRespawn(time + self.respawntime); //Ry: Now also sets up a ghost for the item when close to spawning
    }
  }

	sprint(other, "You got armor\n");
// armor touch sound
	sound(other, CHAN_ITEM, "items/armor1.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};


/*QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armor1 =
{
	self.touch = armor_touch;
	self.armortype = 0.3;
	self.armorvalue = 100;
	precache_model ("progs/armor.mdl");
	setmodel (self, "progs/armor.mdl");
	self.skin = 0;
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 20;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armor2 =
{
	self.touch = armor_touch;
	self.armortype = 0.6;
	self.armorvalue = 150;
	precache_model ("progs/armor.mdl");
	setmodel (self, "progs/armor.mdl");
	self.skin = 1;
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 20;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armorInv =
{
	self.touch = armor_touch;
  self.armortype = 0.8;
	self.armorvalue = 200;
	precache_model ("progs/armor.mdl");
	setmodel (self, "progs/armor.mdl");
	self.skin = 2;
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 20;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*
===============================================================================

WEAPONS

===============================================================================
*/

void() bound_other_ammo =
{
  if (other.AMMO_SHELLS > 100)
    other.AMMO_SHELLS = 100;
  if (other.AMMO_NAILS > 200)
    other.AMMO_NAILS = 200;
  if (other.AMMO_ROCKETS > ammocap_rockets)
    other.AMMO_ROCKETS = ammocap_rockets;
  if (other.AMMO_CELLS > 100)
    other.AMMO_CELLS = 100;
  #ifdef GAME_ROGUE
    // PGM addition
    if (other.ammo_lava_nails > ammocap_lava) //Ry: Separate ammo caps [09-06-2022]
      other.ammo_lava_nails = ammocap_lava;
    if (other.ammo_multi_rockets > ammocap_multi)
      other.ammo_multi_rockets = ammocap_multi;
    if (other.ammo_plasma > ammocap_plasma)
      other.ammo_plasma = ammocap_plasma;
  #endif
};


//MED 01/06/97 added hipnotic weapons into rankings
float(float w) RankForWeapon =
{
  #ifdef GAME_HIPNOTIC
    if (w == IT_LIGHTNING)
      return 1;
    if (w == IT_ROCKET_LAUNCHER)
      return 2;
    if (w == IT_LASER_CANNON)
      return 3;
    if (w == IT_SUPER_NAILGUN)
      return 4;
    if (w == IT_PROXIMITY_GUN)
      return 5;
    if (w == IT_GRENADE_LAUNCHER)
      return 6;
    if (w == IT_SUPER_SHOTGUN)
      return 7;
    if (w == IT_NAILGUN)
      return 8;
    if (w == IT_MJOLNIR)
      return 9;
    return 10;
  #elifdef GAME_ROGUE
    if (w == IT_PLASMA_GUN)
      return 1;
    if (w == IT_LIGHTNING)
      return 2;
    if (w == IT_MULTI_ROCKET)
      return 3;
    if (w == IT_ROCKET_LAUNCHER)
      return 4;
    if (w == IT_LAVA_SUPER_NAILGUN)
      return 5;
    if (w == IT_SUPER_NAILGUN)
      return 6;
    if (w == IT_MULTI_GRENADE)
      return 7;
    if (w == IT_GRENADE_LAUNCHER)
      return 8;
    if (w == IT_LAVA_NAILGUN)
      return 9;
    if (w == IT_SUPER_SHOTGUN)
      return 10;
    if (w == IT_NAILGUN)
      return 11;
    return 12;
  #else
    if (w == IT_LIGHTNING)
      return 1;
    if (w == IT_ROCKET_LAUNCHER)
      return 2;
    if (w == IT_SUPER_NAILGUN)
      return 3;
    if (w == IT_GRENADE_LAUNCHER)
      return 4;
    if (w == IT_SUPER_SHOTGUN)
      return 5;
    if (w == IT_NAILGUN)
      return 6;
    return 7;
  #endif
};

/*
=============
Deathmatch_Weapon

Deathmatch weapon change rules for picking up a weapon

.float		ammo_shells, ammo_nails, ammo_rockets, ammo_cells;
=============
*/
void(float old, float new) Deathmatch_Weapon =
{
  local float or, nr;
  
  if ( self.flags & FL_ISBOT )
    return;
  
  #ifdef GAME_HIPNOTIC
    //Ry: Don't switch off of Mjolnir (when usable) on picking an item pls
    if ((self.weapon == IT_MJOLNIR) && self.AMMO_CELLS >= 15)
      return;
  #endif
  
  #ifdef GAME_ROGUE
    // PGM - fix for changing to weapons when grappling.
    if (self.weapon == IT_GRAPPLE && self.button0)
      return;
  #endif

  // change self.weapon if desired
  or = RankForWeapon (self.weapon);
  nr = RankForWeapon (new);
  if ( nr < or )
    self.weapon = new;
}

#ifdef GAME_ROGUE
  void(entity comboOwner) EnableComboWeapons =
  {
    if (comboOwner.classname != "player")
      return;
    
    if (!(comboOwner.items & IT_LAVA_NAILGUN))
    {
      if (comboOwner.ammo_lava_nails > 0 && (comboOwner.items & IT_NAILGUN))
      {
        sprint (comboOwner, "Lava Enabled\n");
        comboOwner.items = comboOwner.items | IT_LAVA_NAILGUN;
      }
    }

    if (!(comboOwner.items & IT_LAVA_SUPER_NAILGUN))
    {
      if (comboOwner.ammo_lava_nails > 0 && 
                (comboOwner.items & IT_SUPER_NAILGUN))
      {
        sprint (comboOwner, "Super Lava Enabled\n");
        comboOwner.items = comboOwner.items | IT_LAVA_SUPER_NAILGUN;		
      }
    }

    if (!(comboOwner.items & IT_MULTI_GRENADE))
    {
      if (comboOwner.ammo_multi_rockets > 0 && 
                (comboOwner.items & IT_GRENADE_LAUNCHER))
      {
        sprint (comboOwner, "Multi Grenades Enabled\n");
        comboOwner.items = comboOwner.items | IT_MULTI_GRENADE;		
      }
    }

    if (!(comboOwner.items & IT_MULTI_ROCKET))
    {
      if (comboOwner.ammo_multi_rockets > 0 && 
                (comboOwner.items & IT_ROCKET_LAUNCHER))
      {
        sprint (comboOwner, "Multi Rockets Enabled\n");
        comboOwner.items = comboOwner.items | IT_MULTI_ROCKET;		
      }
    }

    if (!(comboOwner.items & IT_PLASMA_GUN))
    {
      if (comboOwner.ammo_plasma > 0 && (comboOwner.items & IT_LIGHTNING))
      {
        sprint (comboOwner, "Plasma Gun Enabled\n");
        comboOwner.items = comboOwner.items | IT_PLASMA_GUN;		
      }
    }
  };
#endif

/*
=============
weapon_touch
=============
*/

float() W_BestWeapon;
float(entity playerEnt, float old, float new) W_WantsToChangeWeapon;

void() weapon_touch =
{
	local	float	hadammo, best, new, olditems, oldweapon;
	local	entity	stemp;
	local	float	leave;
  local string itemname;
  //local float respawntime;

  #ifdef GAME_HIPNOTIC
  //Ry: Gremlins are now able to pick a weapon off the ground
	if (!(other.flags & FL_CLIENT || (grem_itemstealallowed && (other.classname == "monster_gremlin") && (other.gremstate != GREM_GORGING) && (!other.super_item) && (self.classname != "weapon_mjolnir") && (self.gremstate < GREM_ARMED)) ))
  #else
  if (!(other.flags & FL_CLIENT))
  #endif
		return;
	if (other.health <= 0) //Ry: Health wasn't being checked here
		return;
    
  if ( coop && (!self.respawntime) && (other.flags & FL_CLIENT) && (self.pickers & other.playerindex) ) //Ry: Cancel if player has already collected the weapon
  {
    #ifndef ENGINE_WINQUAKE
      if (!(self.alpha == 0.25)) //Ry: Item will turn transparent when a player that already used it is standing over it
        self.alpha = 0.25;
      self.nextthink = time + 0.1;
      self.think = TransparentThink;
    #endif
    return;
  }

// if the player was using his best weapon, change up to the new one if better
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;
  
  itemname = self.netname;
  //respawntime = 30;

  if (deathmatch == 3) //Ry: Weapons respawn quickly (except Mjolnir), and if you already have a weapon, you just get a small amount of ammo from it
  {
    leave = 0;
    if (self.classname == "weapon_nailgun")
    {
      hadammo = other.AMMO_NAILS;
        
      if (other.items & IT_NAILGUN)
      {
        other.AMMO_NAILS = other.AMMO_NAILS + 10;
        itemname = "nails";
      }
      else
      {
        new = IT_NAILGUN;
        other.AMMO_NAILS = other.AMMO_NAILS + 30;
      }
    }
    else if (self.classname == "weapon_supernailgun")
    {
      hadammo = other.AMMO_NAILS;
        
      if (other.items & IT_SUPER_NAILGUN)
      {
        other.AMMO_NAILS = other.AMMO_NAILS + 10;
        itemname = "nails";
      }
      else
      {
        new = IT_SUPER_NAILGUN;
        other.AMMO_NAILS = other.AMMO_NAILS + 30;
      }
    }
    else if (self.classname == "weapon_supershotgun")
    {
      hadammo = other.AMMO_SHELLS;
        
      other.AMMO_SHELLS = other.AMMO_SHELLS + 5;
      if (other.items & IT_SUPER_SHOTGUN)
        itemname = "shells";
      else
        new = IT_SUPER_SHOTGUN;
    }
    else if (self.classname == "weapon_rocketlauncher")
    {
      hadammo = other.AMMO_ROCKETS;
        
      if (other.items & IT_ROCKET_LAUNCHER)
      {
        other.AMMO_ROCKETS = other.AMMO_ROCKETS + 2;
        itemname = "rockets";
      }
      else
      {
        new = IT_ROCKET_LAUNCHER;
        other.AMMO_ROCKETS = other.AMMO_ROCKETS + 5;
      }
    }
    else if (self.classname == "weapon_grenadelauncher")
    {
      hadammo = other.AMMO_ROCKETS;
        
      if (other.items & IT_GRENADE_LAUNCHER)
      {
        other.AMMO_ROCKETS = other.AMMO_ROCKETS + 2;
        itemname = "rockets";
      }
      else
      {
        new = IT_GRENADE_LAUNCHER;
        other.AMMO_ROCKETS = other.AMMO_ROCKETS + 5;
      }
    }
    else if (self.classname == "weapon_lightning")
    {
      hadammo = other.AMMO_CELLS;
        
      if (other.items & IT_LIGHTNING)
      {
        other.AMMO_CELLS = other.AMMO_CELLS + 3;
        itemname = "cells";
      }
      else
      {
        new = IT_LIGHTNING;
        other.AMMO_CELLS = other.AMMO_CELLS + 15;
      }
    }
    #ifdef GAME_HIPNOTIC
    //MED
    else if (self.classname == "weapon_laser_gun")
    {
      hadammo = other.AMMO_CELLS;
        
      if (other.items & IT_LASER_CANNON)
      {
        other.AMMO_CELLS = other.AMMO_CELLS + 5;
        itemname = "cells";
      }
      else
      {
        new = IT_LASER_CANNON;
        other.AMMO_CELLS = other.AMMO_CELLS + 30;
      }
    }
    //MED
    else if (self.classname == "weapon_mjolnir")
    {
      hadammo = other.AMMO_CELLS;
      //respawntime = 30;
        
      if (other.items & IT_MJOLNIR)
      {
        other.AMMO_CELLS = other.AMMO_CELLS + 15;
        itemname = "cells";
      }
      else
      {
        new = IT_MJOLNIR;
        other.AMMO_CELLS = other.AMMO_CELLS + 30;
      }
    }
    //MED
    else if (self.classname == "weapon_proximity_gun")
    {
      hadammo = other.AMMO_ROCKETS;
        
      if (other.items & IT_PROXIMITY_GUN)
      {
        other.AMMO_ROCKETS = other.AMMO_ROCKETS + 2;
        itemname = "rockets";
      }
      else
      {
        new = IT_PROXIMITY_GUN;
        other.AMMO_ROCKETS = other.AMMO_ROCKETS + 6;
      }
    }
    #endif
    else
      objerror ("weapon_touch: unknown classname");
  }
  else
  {
    if ( deathmatch == 2 || (coop && (!self.respawntime)) )
      leave = 1;
    else
      leave = 0;
    
    if (deathmatch == 1) //Ry: deathmatch 1's original spawn times
      self.respawntime = 30;
      
    if (self.classname == "weapon_nailgun")
    {
      if (leave && (other.items & IT_NAILGUN) && (other.AMMO_NAILS >= 200) ) //Ry: Will only leave now if can't collect the ammo
        return;
      #ifdef GAME_HIPNOTIC
        if ((other.classname == "monster_gremlin") && (other.items & IT_NAILGUN)) //Ry: Gremlins leave the weapon if they already have a stolen one
          return;
      #endif
      hadammo = other.AMMO_NAILS;
      new = IT_NAILGUN;
      other.AMMO_NAILS = other.AMMO_NAILS + 30;
    }
    else if (self.classname == "weapon_supernailgun")
    {
      if (leave && (other.items & IT_SUPER_NAILGUN) && (other.AMMO_NAILS >= 200) )
        return;
      #ifdef GAME_HIPNOTIC
        if ((other.classname == "monster_gremlin") && (other.items & IT_SUPER_NAILGUN))
          return;
      #endif
      hadammo = other.AMMO_ROCKETS;
      new = IT_SUPER_NAILGUN;
      other.AMMO_NAILS = other.AMMO_NAILS + 30;
    }
    else if (self.classname == "weapon_supershotgun")
    {
      if (leave && (other.items & IT_SUPER_SHOTGUN) && (other.AMMO_SHELLS >= 100) )
        return;
      #ifdef GAME_HIPNOTIC
        if ((other.classname == "monster_gremlin") && (other.items & IT_SUPER_SHOTGUN))
          return;
      #endif
      hadammo = other.AMMO_ROCKETS;
      new = IT_SUPER_SHOTGUN;
      #ifdef GAME_HIPNOTIC
      if (other.classname == "monster_gremlin") //Ry: Give Gremlins a bit more shotgun ammo to work with, since they don't have starting shells like players
        other.AMMO_SHELLS = other.AMMO_SHELLS + 20;
      else
      #endif
        other.AMMO_SHELLS = other.AMMO_SHELLS + 5;
    }
    else if (self.classname == "weapon_rocketlauncher")
    {
      if (leave && (other.items & IT_ROCKET_LAUNCHER) && (other.AMMO_ROCKETS >= 100) )
        return;
      #ifdef GAME_HIPNOTIC
        if ((other.classname == "monster_gremlin") && (other.items & IT_ROCKET_LAUNCHER))
          return;
      #endif
      hadammo = other.AMMO_ROCKETS;
      new = IT_ROCKET_LAUNCHER;
      other.AMMO_ROCKETS = other.AMMO_ROCKETS + 5;
    }
    else if (self.classname == "weapon_grenadelauncher")
    {
      if (leave && (other.items & IT_GRENADE_LAUNCHER) && (other.AMMO_ROCKETS >= 100) )
        return;
      #ifdef GAME_HIPNOTIC
        if ((other.classname == "monster_gremlin") && (other.items & IT_GRENADE_LAUNCHER))
          return;
      #endif
      hadammo = other.AMMO_ROCKETS;
      new = IT_GRENADE_LAUNCHER;
      other.AMMO_ROCKETS = other.AMMO_ROCKETS + 5;
    }
    else if (self.classname == "weapon_lightning")
    {
      if (leave && (other.items & IT_LIGHTNING) && (other.AMMO_CELLS >= 100) )
        return;
      #ifdef GAME_HIPNOTIC
        if ((other.classname == "monster_gremlin") && (other.items & IT_LIGHTNING))
          return;
      #endif
      hadammo = other.AMMO_ROCKETS;
      new = IT_LIGHTNING;
      other.AMMO_CELLS = other.AMMO_CELLS + 15;
    }
    #ifdef GAME_HIPNOTIC
    //MED
    else if (self.classname == "weapon_laser_gun")
    {
      if (leave && (other.items & IT_LASER_CANNON) && (other.AMMO_CELLS >= 100) )
        return;
      if ((other.classname == "monster_gremlin") && (other.items & IT_LASER_CANNON))
        return;
      hadammo = other.AMMO_ROCKETS;
        new = IT_LASER_CANNON;
        other.AMMO_CELLS = other.AMMO_CELLS + 30;
    }
    //MED
    else if (self.classname == "weapon_mjolnir")
    {
      if (leave && (other.items & IT_MJOLNIR) && (other.AMMO_CELLS >= 100) )
        return;
      if ((other.classname == "monster_gremlin") && (other.items & IT_MJOLNIR))
        return;
      hadammo = other.AMMO_ROCKETS;
        new = IT_MJOLNIR;
        other.AMMO_CELLS = other.AMMO_CELLS + 30;
    }
    //MED
    else if (self.classname == "weapon_proximity_gun")
    {
      if (leave && (other.items & IT_PROXIMITY_GUN) && (other.AMMO_ROCKETS >= 100) )
        return;
      if ((other.classname == "monster_gremlin") && (other.items & IT_PROXIMITY_GUN))
        return;
      hadammo = other.AMMO_ROCKETS;
        new = IT_PROXIMITY_GUN;
        other.AMMO_ROCKETS = other.AMMO_ROCKETS + 6;
    }
    #endif
    else
      objerror ("weapon_touch: unknown classname");
  }
  
  if (other.flags & FL_CLIENT) //Ry: Don't run these at all on a Gremlin
  {
    sprint (other, "You got the ");
    sprint (other, itemname);
    sprint (other, "\n");
  
    stuffcmd (other, "bf\n");
    if ( coop && (!self.respawntime) )
    {
      self.pickers = self.pickers + other.playerindex; //Ry: Mark off that this player has picked the item
      UpdateItemVisibility(self,0.25); //Ry: If everyone has the item, hide it
      if (self.solid == SOLID_TRIGGER) //Ry: Otherwise, set the transparency thinker so the item becomes solid when the player steps off it
      {
        self.nextthink = time + 0.1;
        self.think = TransparentThink;
      }
    }
  }
  // weapon touch sound
  sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);

  bound_other_ammo ();

// change to the weapon
  oldweapon = other.weapon; //Ry: Store these separately
  olditems = other.items;
  other.items = other.items | new;
  
  #ifdef GAME_ROGUE
    EnableComboWeapons ( other );

    // PGM - fake picking up the plasma gun.
    if (new == IT_LIGHTNING)
    {
      if (other.ammo_plasma > 0)
        new = IT_PLASMA_GUN;
    }
    else if (new == IT_ROCKET_LAUNCHER)
    {
      if (other.ammo_multi_rockets > 0)
        new = IT_MULTI_ROCKET;
    }
    else if (new == IT_GRENADE_LAUNCHER)
    {
      if (other.ammo_multi_rockets > 0)
        new = IT_MULTI_GRENADE;
    }
    else if (new == IT_SUPER_NAILGUN)
    {
      if (other.ammo_lava_nails > 1)
        new = IT_LAVA_SUPER_NAILGUN;
    }
    else if (new == IT_NAILGUN)
    {
      if (other.ammo_lava_nails > 0)
        new = IT_LAVA_NAILGUN;
    }
  #endif

  stemp = self;
  self = other;

  #ifdef ENGINE_KEX
  if(W_WantsToChangeWeapon(other, olditems, other.items) == 1) //Ry: Remaster function for checking the user's weapon switch settings
  #endif
    if (!deathmatch)
    {
      #ifdef GAME_ROGUE
      //Ry: Don't switch off Grapple in use [09-10-2022]
      if ((self.weapon != IT_GRAPPLE) || (self.hookstatus < HOOK_FIRED))
      #endif
        self.weapon = new;
    }
    else
      Deathmatch_Weapon (oldweapon, new);

  #ifdef GAME_ROGUE
    UpdateAmmoCounts(self);
  #endif

  #ifdef GAME_HIPNOTIC
  if (self.classname == "monster_gremlin") //Ry: Gremlin
  {
    if (!self.pickorigin)
      self.pickorigin = self.origin; //Ry: Track where the item was picked from, so it can be put back if something happens to the item
    if (!deathmatch)
    {
      stemp.gremstate = GREM_ARMED; //Ry: Ensure only one Gremlin can grab the item on a frame
      self.super_item = stemp; //Store the weapon item so Gremlin can drop it
      leave = FALSE;
    }
    if (self.goalentity == stemp) //Ry: Be sure to reset goalentity correctly if item was desired
      GremlinAbandonItem();
    if (self.weapon && self.enemy) //Ry: Go into weapon state
      Gremlin_UpdateState(GREM_ARMED);
    W_UpdateAmmo();
  }
  else //Ry: Player
  #endif
    if (self.weapon == oldweapon) //Ry: Actually check if the weapon changed instead of always resetting weapon
      W_UpdateAmmo();
    else
      W_SetCurrentAmmo();

	self = stemp;

  // Moved up so the targets are fired even in coop, but only once.
  activator = other;
  SUB_UseTargets();				// fire all targets / killtargets

  if (leave)
  {
    self.target = string_null;
    return;
  }

// remove it in single player, or setup for respawning in deathmatch
	self.model = string_null;
	self.solid = SOLID_NOT;
  
	if (self.respawntime) //Ry: Respawn in Deathmatch always if the item doesn't stay
  {
    PrepareItemRespawn(time + self.respawntime); //Ry: Now also sets up a ghost for the item when close to spawning
  }

};


/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supershotgun =
{
	precache_model ("progs/g_shot.mdl");
	setmodel (self, "progs/g_shot.mdl");
	self.weapon = IT_SUPER_SHOTGUN;
	self.netname = "Double-barrelled Shotgun";
	self.touch = weapon_touch;
  if (deathmatch && (deathmatch != 2)) //Ry: DM Respawn time defined here now
    self.respawntime = 5;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_nailgun =
{
	precache_model ("progs/g_nail.mdl");
	setmodel (self, "progs/g_nail.mdl");
	self.weapon = IT_NAILGUN;
	self.netname = "Nailgun";
	self.touch = weapon_touch;
  if (deathmatch && (deathmatch != 2)) //Ry: DM Respawn time defined here now
    self.respawntime = 5;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supernailgun =
{
	precache_model ("progs/g_nail2.mdl");
	setmodel (self, "progs/g_nail2.mdl");
	self.weapon = IT_SUPER_NAILGUN;
	self.netname = "Super Nailgun";
	self.touch = weapon_touch;
  if (deathmatch && (deathmatch != 2)) //Ry: DM Respawn time defined here now
    self.respawntime = 5;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_grenadelauncher =
{
	precache_model ("progs/g_rock.mdl");
  #ifdef GAME_HIPNOTIC
    precache_model ("progs/g_prox.mdl"); //Ry: Also precache hipnotic's Proximity Gun
  #endif
	setmodel (self, "progs/g_rock.mdl");
	self.weapon = IT_GRENADE_LAUNCHER; //Ry: Was 3; Fixed
	self.netname = "Grenade Launcher";
	self.touch = weapon_touch;
  if (deathmatch && (deathmatch != 2)) //Ry: DM Respawn time defined here now
    self.respawntime = 5;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_rocketlauncher =
{
	precache_model ("progs/g_rock2.mdl");
	setmodel (self, "progs/g_rock2.mdl");
	self.weapon = IT_ROCKET_LAUNCHER; //Ry: Was 3; Fixed
	self.netname = "Rocket Launcher";
	self.touch = weapon_touch;
  if (deathmatch && (deathmatch != 2)) //Ry: DM Respawn time defined here now
    self.respawntime = 5;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};


/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_lightning =
{
  precache_model ("progs/g_light.mdl");
  #ifdef GAME_HIPNOTIC
    precache_model ("progs/g_laserg.mdl"); //Ry: Also precache hipnotic's Laser Cannon and Mjolnir
    precache_model ("progs/g_hammer.mdl");
  #endif
	setmodel (self, "progs/g_light.mdl");
	self.weapon = IT_LIGHTNING; //Ry: Was 3; Fixed
	self.netname = "Thunderbolt";
	self.touch = weapon_touch;
  if (deathmatch && (deathmatch != 2)) //Ry: DM Respawn time defined here now
    self.respawntime = 5;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};


/*
===============================================================================

AMMO

===============================================================================
*/

void() ammo_touch =
{
  local entity	stemp;
  local float		best;
  local	float	leave; //Ry: Now can leave ammo in Co-op

  #ifdef GAME_HIPNOTIC
	if (!(other.classname == "player" || ( grem_itemstealallowed && (other.classname == "monster_gremlin") && (other.gremstate != GREM_GORGING) && (self.gremstate < GREM_ARMED) ) )) //Ry: Gremlins now grab ammo if they have a gun that needs it
  #else
  if (other.classname != "player")
  #endif
		return;
	if (other.health <= 0)
		return;
  
  if ( self.oneperplayer && (self.pickers & other.playerindex) ) //Ry: Cancel if player has already collected the item
  {
    #ifndef ENGINE_WINQUAKE
      if (!(self.alpha == 0.25)) //Ry: Item will turn transparent when a player that already used it is standing over it
        self.alpha = 0.25;
      self.nextthink = time + 0.1;
      self.think = TransparentThink;
    #endif
    return;
  }

// if the player was using his best weapon, change up to the new one if better
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;


// shotgun
	if (self.weapon == 1)
	{
		if (other.AMMO_SHELLS >= 100)
			return;
    #ifdef GAME_HIPNOTIC
      if ((other.classname == "monster_gremlin") && !(other.items & (IT_SHOTGUN|IT_SUPER_SHOTGUN)) ) //Ry: Gremlin must have a relevant weapon
        return;
    #endif
		other.AMMO_SHELLS += self.aflag;
	}

// spikes
	if (self.weapon == 2)
	{
		if (other.AMMO_NAILS >= 200)
			return;
    #ifdef GAME_HIPNOTIC
      if ((other.classname == "monster_gremlin") && !(other.items & (IT_NAILGUN|IT_SUPER_NAILGUN)) )
        return;
    #endif
		other.AMMO_NAILS += self.aflag;
	}

//	rockets
	if (self.weapon == 3)
	{
		if (other.AMMO_ROCKETS >= ammocap_rockets)
			return;
    #ifdef GAME_HIPNOTIC
      if ((other.classname == "monster_gremlin") && !(other.items & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER|IT_PROXIMITY_GUN)) )
        return;
    #endif
		other.AMMO_ROCKETS += self.aflag;
	}

//	cells
	if (self.weapon == 4)
	{
		if (other.AMMO_CELLS >= 100)
			return;
    #ifdef GAME_HIPNOTIC
      if ((other.classname == "monster_gremlin") && !(other.items & (IT_LIGHTNING|IT_LASER_CANNON)) )
        return;
    #endif
		other.AMMO_CELLS += self.aflag;
	}

  #ifdef GAME_ROGUE
    //	lava spikes
    if (self.weapon == 5)
    {
      if(other.ammo_lava_nails >= ammocap_lava)
        return;			
      other.ammo_lava_nails += self.aflag;
    }

    //	multi grenades
    if (self.weapon == 6)
    {
      if(other.ammo_multi_rockets >= ammocap_multi)
        return;
      other.ammo_multi_rockets += self.aflag;
    }

    //	plasma
    if (self.weapon == 7)
    {
      if(other.ammo_plasma >= ammocap_plasma)
        return;
      other.ammo_plasma += self.aflag;
    }

    EnableComboWeapons ( other );
  #endif

	bound_other_ammo ();

  if (other.classname == "player") //Ry: Make sure these don't run on Gremlin
  {
    sprint (other, "You got the ");
    sprint (other, self.netname);
    sprint (other, "\n");
    stuffcmd (other, "bf\n");
  }
  #ifdef GAME_HIPNOTIC
  else if (!deathmatch) //Ry: Only one Gremlin can grab the ammo in campaign
    self.gremstate = GREM_ARMED;
  #endif

  if (self.oneperplayer)
  {
    leave = TRUE;
    if (self.spawnflags & WEAPON_BIG2) //Ry: Demote big item when the first player picks
    {
      self.spawnflags = self.spawnflags - WEAPON_BIG2;
      if (self.weapon == 1) 
      {
        self.mdl = "maps/b_shell0.bsp";
        self.aflag = 20;
        self.origin = self.origin + '4 4 0'; //Ry: Adjust origin so the item looks centered on where the big item was
        setmodel (self,self.mdl);
        setsize (self, '-4 -4 0', '28 28 56'); //Ry: While hitbox remains in basically the same place
        self.view_ofs = '12 12 0';
      }
      else if (self.weapon == 2)
      {
        self.mdl = "maps/b_nail0.bsp";
        self.aflag = 25;
        self.origin = self.origin + '4 4 0';
        setmodel (self,self.mdl);
        setsize (self, '-4 -4 0', '28 28 56');
        self.view_ofs = '12 12 0';
      }
      else if (self.weapon == 3)
      {
        self.mdl = "maps/b_rock0.bsp";
        self.aflag = 5;
        self.origin = self.origin + '8 0 0';
        setmodel (self,self.mdl);
        setsize (self, '-8 0 0', '24 32 56');
        self.view_ofs = '8 8 0';
      }
      else if (self.weapon == 4)
      {
        self.mdl = "maps/b_batt0.bsp";
        self.aflag = 6;
        self.origin = self.origin + '4 4 0';
        setmodel (self,self.mdl);
        setsize (self, '-4 -4 0', '28 28 56');
        self.view_ofs = '12 12 0';
      }
      #ifdef GAME_ROGUE
        else if (self.weapon == 5)
        {
          self.mdl = "maps/b_lnail0.bsp";
          self.aflag = 25;
          self.origin = self.origin + '4 4 0';
          setmodel (self,self.mdl);
          setsize (self, '-4 -4 0', '28 28 56');
          self.view_ofs = '12 12 0';
        }
        else if (self.weapon == 6)
        {
          self.mdl = "maps/b_mrock0.bsp";
          self.aflag = 5;
          self.origin = self.origin + '8 0 0';
          setmodel (self,self.mdl);
          setsize (self, '-8 0 0', '24 32 56');
          self.view_ofs = '8 8 0';
        }
        else if (self.weapon == 7)
        {
          self.mdl = "maps/b_plas0.bsp";
          self.aflag = 6;
          self.origin = self.origin + '4 4 0';
          setmodel (self,self.mdl);
          setsize (self, '-4 -4 0', '28 28 56');
          self.view_ofs = '12 12 0';
        }
      #endif
    }
    if (other.classname == "player")
    {
      self.pickers = self.pickers + other.playerindex; //Ry: Mark off that this player has picked the item
      UpdateItemVisibility(self,0.25); //Ry: If everyone has the item, hide it
      if (self.solid == SOLID_TRIGGER) //Ry: Otherwise, set the transparency thinker so the item becomes solid when the player steps off it
      {
        self.nextthink = time + 0.1;
        self.think = TransparentThink;
      }
    }
  }
  
// ammo touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);

// change to a better weapon if appropriate

  stemp = self;
  self = other;
  
  #ifdef GAME_HIPNOTIC
  if (self.classname == "monster_gremlin") //Ry: Gremlin
  {
    if ( (self.gremstate >= GREM_ARMED) && self.weapon )
    {
      best = W_BestWeapon();
      if ( self.weapon != best ) //Ry: Always change to best weapon on Gremlin
      {
        self.weapon = best;
      }
    }
    W_UpdateAmmo();
    if (self.goalentity == stemp) //Ry: Be sure to reset goalentity correctly if item was desired
      GremlinAbandonItem();
  }
  else //Ry: Player
  {
    //Ry: Condensed this a bit, made a lighter ammo update, and don't switch off usable Mjolnir. Also Remaster check for weapon switch setting.
    if ( self.weapon == best && (W_WantsToChangeWeapon(self, 0, 1) == 1) && (!deathmatch || !(self.weapon == IT_MJOLNIR) || self.AMMO_CELLS < 15 ) )
  #else
    if ( self.weapon == best && (W_WantsToChangeWeapon(self, 0, 1) == 1) )
  #endif
    {
      self.weapon = W_BestWeapon();
      W_SetCurrentAmmo ();
    }
    else
      W_UpdateAmmo();
  #ifdef GAME_HIPNOTIC
  }
  #endif

  #ifdef GAME_ROGUE
    UpdateAmmoCounts ( other );
  #endif

	self = stemp;
  
  if (leave)
    return;

// remove it in single player, or setup for respawning in deathmatch
	self.model = string_null;
	self.solid = SOLID_NOT;
	if (deathmatch && (deathmatch != 2)) //Ry: Respawn in Deathmatch 3/4 as well
  {
    PrepareItemRespawn(time + self.respawntime); //Ry: Now also sets up a ghost for the item when close to spawning
  }

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};



/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_shells =
{
	self.touch = ammo_touch;

  precache_model ("maps/b_shell0.bsp"); //Ry: Always precache smaller item now
	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_shell1.bsp");
		setmodel (self, "maps/b_shell1.bsp");
		self.aflag = 40;
    self.view_ofs = '16 16 0';
	}
	else
	{
		setmodel (self, "maps/b_shell0.bsp");
		self.aflag = 20;
    self.view_ofs = '12 12 0';
	}
	self.weapon = 1;
	self.netname = "shells";
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 30;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_spikes =
{
	self.touch = ammo_touch;

  precache_model ("maps/b_nail0.bsp"); //Ry: Always precache smaller item now
  #ifdef GAME_ROGUE
    precache_model ("maps/b_lnail0.bsp"); //Ry: Precache alternate ammo in case of replacement [09-08-2022]
  #endif
	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_nail1.bsp");
    #ifdef GAME_ROGUE
      precache_model ("maps/b_lnail1.bsp");
    #endif
		setmodel (self, "maps/b_nail1.bsp");
		self.aflag = 50;
    self.view_ofs = '16 16 0';
	}
	else
	{
		setmodel (self, "maps/b_nail0.bsp");
		self.aflag = 25;
    self.view_ofs = '12 12 0';
	}
	self.weapon = 2;
	self.netname = "nails";
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 30;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_rockets =
{
	self.touch = ammo_touch;

  precache_model ("maps/b_rock0.bsp"); //Ry: Always precache smaller item now
  #ifdef GAME_ROGUE
    precache_model ("maps/b_mrock0.bsp"); //Ry: Precache alternate ammo in case of replacement [09-08-2022]
  #endif
	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_rock1.bsp");
    #ifdef GAME_ROGUE
      precache_model ("maps/b_mrock1.bsp");
    #endif
		setmodel (self, "maps/b_rock1.bsp");
		self.aflag = 10;
    self.view_ofs = '16 8 0';
	}
	else
	{
		setmodel (self, "maps/b_rock0.bsp");
		self.aflag = 5;
    self.view_ofs = '8 8 0';
	}
	self.weapon = 3;
	self.netname = "rockets";
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 30;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_cells =
{
	self.touch = ammo_touch;

  precache_model ("maps/b_batt0.bsp"); //Ry: Always precache smaller item now
  #ifdef GAME_ROGUE
    precache_model ("maps/b_plas0.bsp"); //Ry: Precache alternate ammo in case of replacement [09-08-2022]
  #endif
	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_batt1.bsp");
    #ifdef GAME_ROGUE
      precache_model ("maps/b_plas1.bsp");
    #endif
		setmodel (self, "maps/b_batt1.bsp");
		self.aflag = 12;
    self.view_ofs = '16 16 0';
	}
	else
	{
		setmodel (self, "maps/b_batt0.bsp");
		self.aflag = 6;
    self.view_ofs = '12 12 0';
	}
	self.weapon = 4;
	self.netname = "cells";
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 30;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

#ifdef GAME_ROGUE
  /*QUAKED item_lava_spikes (0 .5 .8) (0 0 0) (32 32 32) big
  Small box is 25, Big box is 50.
  */

  void() item_lava_spikes =
  {
    missionpackmap = TRUE;
    self.touch = ammo_touch;

    precache_model ("maps/b_lnail0.bsp");
    if (self.spawnflags & WEAPON_BIG2)
    {
      precache_model ("maps/b_lnail1.bsp");
      setmodel (self, "maps/b_lnail1.bsp");
      self.aflag = 50;
      self.view_ofs = '16 16 0';
    }
    else
    {
      setmodel (self, "maps/b_lnail0.bsp");
      self.aflag = 25;
      self.view_ofs = '12 12 0';
    }
    self.weapon = 5;
    self.netname = "lava nails";
    if (deathmatch) //Ry: DM Respawn time defined here now
      self.respawntime = 30;
    else if (coop) //Ry: All players in Co-op can pick this once
      self.oneperplayer = TRUE;
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
  };

  /*QUAKED item_multi_rockets (0 .5 .8) (0 0 0) (32 32 32) big
  Small box is 5, Big box is 10.
  */

  void() item_multi_rockets =
  {
    missionpackmap = TRUE;
    self.touch = ammo_touch;

    precache_model ("maps/b_mrock0.bsp");
    if (self.spawnflags & WEAPON_BIG2)
    {
      precache_model ("maps/b_mrock1.bsp");
      setmodel (self, "maps/b_mrock1.bsp");
      self.aflag = 10;
      self.view_ofs = '16 8 0';
    }
    else
    {
      setmodel (self, "maps/b_mrock0.bsp");
      self.aflag = 5;
      self.view_ofs = '8 8 0';
    }
    self.weapon = 6;
    self.netname = "multi rockets";
    if (deathmatch) //Ry: DM Respawn time defined here now
      self.respawntime = 30;
    else if (coop) //Ry: All players in Co-op can pick this once
      self.oneperplayer = TRUE;
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
  };

  /*QUAKED item_plasma (0 .5 .8) (0 0 0) (32 32 32) big
  Small box is 6, Big box is 12.
  */
  void() item_plasma =
  {
    missionpackmap = TRUE;
    self.touch = ammo_touch;

    precache_model ("maps/b_plas0.bsp");
    if (self.spawnflags & WEAPON_BIG2)
    {
      precache_model ("maps/b_plas1.bsp");
      setmodel (self, "maps/b_plas1.bsp");
      self.aflag = 12;
    }
    else
    {
      setmodel (self, "maps/b_plas0.bsp");
      self.aflag = 6;
    }
    self.view_ofs = '16 12 0';
    self.weapon = 7;
    self.netname = "plasma";
    if (deathmatch) //Ry: DM Respawn time defined here now
      self.respawntime = 30;
    else if (coop) //Ry: All players in Co-op can pick this once
      self.oneperplayer = TRUE;
    setsize (self, '0 0 0', '32 32 56');
    StartItem ();
  };
#endif


/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/

float WEAPON_SHOTGUN = 1;
float WEAPON_ROCKET = 2;
float WEAPON_SPIKES = 4;
float WEAPON_BIG = 8;
void() item_weapon =
{
  //Ry: Translate this item into the proper items [09-26-2022]
	if (self.spawnflags & WEAPON_SHOTGUN)
	{
		if (self.spawnflags & WEAPON_BIG)
      self.spawnflags = WEAPON_BIG2;
		else
      self.spawnflags = 0;
    self.classname = "item_shells";
    item_shells();
    return;
	}

	if (self.spawnflags & WEAPON_SPIKES)
	{
		if (self.spawnflags & WEAPON_BIG)
      self.spawnflags = WEAPON_BIG2;
		else
      self.spawnflags = 0;
    self.classname = "item_spikes";
    item_spikes();
    return;
	}

	if (self.spawnflags & WEAPON_ROCKET)
	{
		if (self.spawnflags & WEAPON_BIG)
      self.spawnflags = WEAPON_BIG2;
		else
      self.spawnflags = 0;
    self.classname = "item_rockets";
    item_rockets();
    return;
	}

  dprint("item_weapon has no ammo type set at ");
  dprint(vtos(self.origin));
  dprint("\n");
  remove(self);
};


/*
===============================================================================

KEYS

===============================================================================
*/

void() key_touch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

  //Ry: Fire any targets even if the player already has the key
  if (self.target || self.killtarget)
  {
    activator = other;
    SUB_UseTargets();				// fire all targets / killtargets
    self.target = string_null; //Only fire the trigger once though.
    self.killtarget = string_null;
  }

	if (other.items & self.items)
		return;

	sprint (other, "You got the ");
	sprint (other, self.netname);
	sprint (other,"\n");

	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	other.items = other.items | self.items;

	if (!coop)
	{
		self.solid = SOLID_NOT;
		self.model = string_null;
	}
};


void() key_setsounds =
{
	if (world.worldtype == 0)
	{
		precache_sound ("misc/medkey.wav");
		self.noise = "misc/medkey.wav";
	}
	if (world.worldtype == 1)
	{
		precache_sound ("misc/runekey.wav");
		self.noise = "misc/runekey.wav";
	}
	if (world.worldtype == 2)
	{
		precache_sound2 ("misc/basekey.wav");
		self.noise = "misc/basekey.wav";
	}
};

/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
SILVER key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key1 =
{
	if (world.worldtype == 0)
	{
		precache_model ("progs/w_s_key.mdl");
		setmodel (self, "progs/w_s_key.mdl");
		self.netname = "silver key";
	}
	else if (world.worldtype == 1)
	{
		precache_model ("progs/m_s_key.mdl");
		setmodel (self, "progs/m_s_key.mdl");
		self.netname = "silver runekey";
	}
	else if (world.worldtype == 2)
	{
		precache_model2 ("progs/b_s_key.mdl");
		setmodel (self, "progs/b_s_key.mdl");
		self.netname = "silver keycard";
	}
	key_setsounds();
	self.touch = key_touch;
	self.items = IT_KEY1;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
GOLD key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key2 =
{
	if (world.worldtype == 0)
	{
		precache_model ("progs/w_g_key.mdl");
		setmodel (self, "progs/w_g_key.mdl");
		self.netname = "gold key";
	}
	if (world.worldtype == 1)
	{
		precache_model ("progs/m_g_key.mdl");
		setmodel (self, "progs/m_g_key.mdl");
		self.netname = "gold runekey";
	}
	if (world.worldtype == 2)
	{
		precache_model2 ("progs/b_g_key.mdl");
		setmodel (self, "progs/b_g_key.mdl");
		self.netname = "gold keycard";
	}
	key_setsounds();
	self.touch = key_touch;
	self.items = IT_KEY2;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};



/*
===============================================================================

END OF LEVEL RUNES

===============================================================================
*/

void() sigil_touch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	FilteredCenterPrint (other, CPRINT_WORLD, "You got the rune!");

	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	self.model = string_null;
	serverflags = serverflags | (self.spawnflags & 15);
	self.classname = "";		// so rune doors won't find it

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};


/*QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
End of level sigil, pick up to end episode and return to jrstart.
*/

void() item_sigil =
{
	if (!self.spawnflags)
		objerror ("no spawnflags");

	precache_sound ("misc/runekey.wav");
	self.noise = "misc/runekey.wav";

	if (self.spawnflags & 1)
	{
		precache_model ("progs/end1.mdl");
		setmodel (self, "progs/end1.mdl");
	}
	if (self.spawnflags & 2)
	{
		precache_model2 ("progs/end2.mdl");
		setmodel (self, "progs/end2.mdl");
	}
	if (self.spawnflags & 4)
	{
		precache_model2 ("progs/end3.mdl");
		setmodel (self, "progs/end3.mdl");
	}
	if (self.spawnflags & 8)
	{
		precache_model2 ("progs/end4.mdl");
		setmodel (self, "progs/end4.mdl");
	}

	self.touch = sigil_touch;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*
===============================================================================

POWERUPS

===============================================================================
*/

void() powerup_touch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

  //Ry: Each player can collect a Biosuit once in Co-op [09-26-2022]
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
  else if ( horde && ((self.classname == "item_artifact_super_damage") || (self.classname == "item_artifact_invulnerability")) )
  {
    if ( (self.classname == "item_artifact_super_damage") && other.super_damage_finished ) //Ry: Dropped powerups in Horde can now stack
      poweruptime = other.super_damage_finished + 5;
    else if ( (self.classname == "item_artifact_invulnerability") && other.invincible_finished )
      poweruptime = other.invincible_finished + 5;
    else
      poweruptime = time + 5;
    if ( poweruptime > (time + 30) ) //Ry: Make sure absurdities can't happen
      poweruptime = time + 30;
  }
  else
    poweruptime = time + 30;

	if (deathmatch)
	{
    if (self.remaintime == 0) //Ry: Regularly spawned powerup
		{
      self.nextspawntime = time + self.respawntime;
      #ifdef GAME_ROGUE
        if (self.lefty) //Ry: Random powerup
          self.nextspawntime = time + 120;
      #endif

      self.pickorigin = self.origin;
      PrepareItemRespawn(self.nextspawntime); //Ry: Now also sets up a ghost for the item when close to spawning
		}
    else //Ry: Dropped powerup. Put it back in it's original spot when it's picked up
    {
      SUB_revertpowerup();
    }
	}

  if (poweruptime > 0) //Ry: Just to make sure
  {
    sprint (other, "You got the "); //Ry: Moved this down here
    sprint (other, self.netname);
    sprint (other,"\n");

    //Ry: New channel for powerup pickups [09-04-2022]
    sound (other, CHAN_POWERUP, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");
    other.items = other.items | self.items;

  // do the appropriate action
    if ((self.classname == "item_artifact_envirosuit") && (other.radsuit_finished < poweruptime)) //Ry: Ensure you don't lose time off your current powerup by picking up a dropped powerup
    {
      other.rad_time = 1;
      other.radsuit_finished = poweruptime;
      other.radsuit_item = self;
      other.radsuit_validdroptime = self.nextspawntime - 5;
    }

    if ((self.classname == "item_artifact_invulnerability") && (other.invincible_finished < poweruptime))
    {
      other.invincible_time = 1;
      other.invincible_finished = poweruptime;
      other.invincible_item = self; //Ry: Normally can't die with this, but you can suicide or disconnect
      other.invincible_validdroptime = self.nextspawntime - 5;
    }

    if ((self.classname == "item_artifact_invisibility") && (other.invisible_finished < poweruptime))
    {
      other.invisible_time = 1;
      other.invisible_finished = poweruptime;
      other.invisible_item = self;
      other.invisible_validdroptime = self.nextspawntime - 5;
    }

    if ((self.classname == "item_artifact_super_damage") && (other.super_damage_finished < poweruptime))
    {
      other.super_time = 1;
      other.super_damage_finished = poweruptime;
      other.super_item = self;
      other.super_validdroptime = self.nextspawntime - 5;
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


/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable for 30 seconds
*/
void() item_artifact_invulnerability =
{
	self.touch = powerup_touch;

	precache_model ("progs/invulner.mdl");
	precache_sound ("items/protect.wav");
	precache_sound ("items/protect2.wav");
	precache_sound ("items/protect3.wav");
	self.noise = "items/protect.wav";
	setmodel (self, "progs/invulner.mdl");
	self.netname = "Pentagram of Protection";
	self.items = IT_INVULNERABILITY;
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 300;
	setsize (self, '-16 -16 -24', '16 16 32');
  self.itemeffect = SET_EF_PENTA; //Ry: New light for powerup
	StartItem ();
};

/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from water or slime for 30 seconds
*/
void() item_artifact_envirosuit =
{
	self.touch = powerup_touch;

	precache_model ("progs/suit.mdl");
	precache_sound ("items/suit.wav");
	precache_sound ("items/suit2.wav");

  #ifdef GAME_HIPNOTIC
    precache_model ("progs/wetsuit.mdl"); //Ry: Precache Wetsuit too
    precache_sound ("misc/wetsuit.wav");
    precache_sound ("misc/weton.wav");
    precache_sound ("items/suit2.wav");
  #endif
  
	self.noise = "items/suit.wav";
	setmodel (self, "progs/suit.mdl");
	self.netname = "Biosuit";
	self.items = IT_SUIT;
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 60;
  else if (coop) //Ry: All players in Co-op can pick this once
    self.oneperplayer = TRUE;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};


/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invisible for 30 seconds
*/
void() item_artifact_invisibility =
{
	self.touch = powerup_touch;

	precache_model ("progs/invisibl.mdl");
	precache_sound ("items/inv1.wav");
	precache_sound ("items/inv2.wav");
	precache_sound ("items/inv3.wav");
	self.noise = "items/inv1.wav";
	setmodel (self, "progs/invisibl.mdl");
	self.netname = "Ring of Shadows";
	self.items = IT_INVISIBILITY;
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 180; //Ry: Reduced to 3 minutes [11-01-2022]
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};


/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
The next attack from the player will do 4x damage
*/
void() item_artifact_super_damage =
{
	self.touch = powerup_touch;

  precache_model ("progs/quaddama.mdl");
	precache_sound ("items/damage.wav");
	precache_sound ("items/damage2.wav");
	precache_sound ("items/damage3.wav");
	self.noise = "items/damage.wav";
	setmodel (self, "progs/quaddama.mdl");
	self.netname = "Quad Damage";
	self.items = IT_QUAD;
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 120;
	setsize (self, '-16 -16 -24', '16 16 32');
  self.itemeffect = SET_EF_QUAD; //Ry: New light for powerup
	StartItem ();
};



/*
===============================================================================

PLAYER BACKPACKS

===============================================================================
*/

void() BackpackTouch =
{
  local entity stemp;
  local	float	acount;
  local float olditems, oldweapon, new;
  local float take_shells, take_nails, take_rockets, take_cells; //Ry: For Co-op
  #ifdef GAME_ROGUE
    local float take_lava, take_multi, take_plasma;
  #endif
  local float pickflags; //Ry: Consolidated leave, takenfrom, and fullpick into a single var [07-23-2022]

  #ifdef GAME_HIPNOTIC
	if (!(other.classname == "player" || (grem_itemstealallowed && (other.classname == "monster_gremlin") && (other.gremstate != GREM_GORGING)) )) //Ry: Gremlins can steal backpacks too now
  #else
  if (other.classname != "player")
  #endif
		return;
	if (other.health <= 0)
		return;

  if ( (other != self.owner) && (self.lastfragtime > time) ) //Ry: Players who aren't the owner have to wait between picks
    return;
  if ( (!self.owner) || (self.owner == other) )
    pickflags |= PICK_FULL;

  new = self.items; //Ry: Moved this bit up here
	if (new > 0)
  {
    if (deathmatch) //Ry: Give a minimum amount of ammo on picking up a new gun via backpack in deathmatch
    {
      self.items = 0;
      pickflags |= PICK_TAKENFROM;
      if ( ((new == IT_SHOTGUN) || (new == IT_SUPER_SHOTGUN)) && (self.AMMO_SHELLS < 5) )
        self.AMMO_SHELLS = 5;
      
      else if ( ((new == IT_NAILGUN) || (new == IT_SUPER_NAILGUN)) && (self.AMMO_NAILS < 30) )
        self.AMMO_NAILS = 30;
      
      else if ( ((new == IT_ROCKET_LAUNCHER) || (new == IT_GRENADE_LAUNCHER)) && (self.AMMO_ROCKETS < 5) )
        self.AMMO_ROCKETS = 5;
      #ifdef GAME_HIPNOTIC
        else if ( (new == IT_PROXIMITY_GUN) && (self.AMMO_ROCKETS < 6) )
          self.AMMO_ROCKETS = 6;
        
        else if ( ((new == IT_LIGHTNING) || (new == IT_MJOLNIR)) && (self.AMMO_CELLS < 15) ) //Mjolnir is good enough that just one guaranteed use is fine
          self.AMMO_CELLS = 15;
        else if ( (new == IT_LASER_CANNON) && (self.AMMO_CELLS < 30) )
          self.AMMO_CELLS = 30;
      #else
        else if ( (new == IT_LIGHTNING) && (self.AMMO_CELLS < 15) )
          self.AMMO_CELLS = 15;
      #endif
      #ifdef GAME_ROGUE
        else if ( ((new == IT_LAVA_NAILGUN) || (new == IT_LAVA_SUPER_NAILGUN)) && (self.ammo_lava_nails < 20) )
          self.ammo_lava_nails = 20;
        else if ( ((new == IT_MULTI_GRENADE) || (new == IT_MULTI_ROCKET)) && (self.ammo_multi_rockets < 3) )
          self.ammo_multi_rockets = 3;
        else if ( (new == IT_PLASMA_GUN) && (self.ammo_plasma < 5) )
          self.ammo_plasma = 5;
      #endif
    }
    else //Ry: Only collect the weapon in a backpack if you didn't already have it in Co-op (For Gremlin backpacks)
    {
      self.netname = "";
      if (pickflags & PICK_FULL)
      {
        take_stolenweps = 0; //Ry: Stolen weapons collected
        take_weps = 0; //Ry: Total weapons collected
        
        //Ry: This function now handles each weapon from the backpack; The function also sets up a unique message for recovering stolen weapons.
        BackpackWeaponTake(IT_AXE,FALSE);
        BackpackWeaponTake(IT_SHOTGUN,FALSE);
        BackpackWeaponTake(IT_SUPER_SHOTGUN,TRUE);
        BackpackWeaponTake(IT_NAILGUN,TRUE);
        BackpackWeaponTake(IT_SUPER_NAILGUN,TRUE);
        BackpackWeaponTake(IT_GRENADE_LAUNCHER,TRUE);
        #ifdef GAME_HIPNOTIC
          BackpackWeaponTake(IT_PROXIMITY_GUN,TRUE);
        #endif
        BackpackWeaponTake(IT_ROCKET_LAUNCHER,TRUE);
        BackpackWeaponTake(IT_LIGHTNING,TRUE);
        #ifdef GAME_HIPNOTIC
          BackpackWeaponTake(IT_LASER_CANNON,TRUE);
          BackpackWeaponTake(IT_MJOLNIR,FALSE);
        #endif
      
        if ( (take_stolenweps > 0) && (other.flags & FL_CLIENT) )
          sprint(other, "\n");
        
        if (take_weps > 0)
          pickflags |= PICK_TAKENFROM;
        
        if (take_weps < 1)
          new = other.weapon;
        else
        { //Ry: Equip the best weapon obtained from the backpack
          stemp = self;
          self = other;
          oldweapon = W_BestWeapon();
          if (new & oldweapon)
            new = oldweapon;
          else
            new = other.weapon;
          self = stemp;
        }
        
        if (self.items)
          pickflags |= PICK_LEAVE;
        
      }
      else
        new = other.weapon;
    }
  }
  else
		new = other.weapon;
	oldweapon = other.weapon; //Ry: Store these separately
  olditems = other.items;
  
  other.items = other.items | new;
  
  if (!coop) //Ry: Normal behavior for SP and DM, just with the new vars
  {
    take_shells = self.AMMO_SHELLS;
    other.AMMO_SHELLS = other.AMMO_SHELLS + self.AMMO_SHELLS;
    take_nails = self.AMMO_NAILS;
    other.AMMO_NAILS = other.AMMO_NAILS + self.AMMO_NAILS;
    take_rockets = self.AMMO_ROCKETS;
    other.AMMO_ROCKETS = other.AMMO_ROCKETS + self.AMMO_ROCKETS;
    take_cells = self.AMMO_CELLS;
    other.AMMO_CELLS = other.AMMO_CELLS + self.AMMO_CELLS;
    #ifdef GAME_ROGUE
      take_lava = self.ammo_lava_nails;
      other.ammo_lava_nails = other.ammo_lava_nails + self.ammo_lava_nails;
      take_multi = self.ammo_multi_rockets;
      other.ammo_multi_rockets = other.ammo_multi_rockets + self.ammo_multi_rockets;
      take_plasma = self.ammo_plasma;
      other.ammo_plasma = other.ammo_plasma + self.ammo_plasma;
    #endif
    pickflags |= PICK_TAKENFROM;
  }
  else //Ry: In Co-op, only take what you need from a backpack
  {

    if (pickflags & PICK_FULL)
    {
      take_shells = 100 - other.AMMO_SHELLS; //Ry: How much ammo of each the player can take
      take_nails = 200 - other.AMMO_NAILS;
      take_rockets = ammocap_rockets - other.AMMO_ROCKETS;
      take_cells = 100 - other.AMMO_CELLS;
      #ifdef GAME_ROGUE
        take_lava = ammocap_lava - other.ammo_lava_nails;
        take_multi = ammocap_multi - other.ammo_multi_rockets;
        take_plasma = ammocap_plasma - other.ammo_plasma;
      #endif
    }
    else //Ry: Non-owner players will only take spawn amounts of ammo
    {
      
      if (other.AMMO_SHELLS < 25)
        take_shells = 25 - other.AMMO_SHELLS;
      else
        take_shells = 0;
      
      if ( (other.items & (IT_NAILGUN|IT_SUPER_NAILGUN)) && (other.AMMO_NAILS < 30) )
        take_nails = 30 - other.AMMO_NAILS;
      else
        take_nails = 0;
      
      #ifdef GAME_HIPNOTIC
      if ( (other.items & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER|IT_PROXIMITY_GUN)) && (other.AMMO_ROCKETS < 5) )
      #else
      if ( (other.items & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER)) && (other.AMMO_ROCKETS < 5) )
      #endif
        take_rockets = 5 - other.AMMO_ROCKETS;
      else
        take_rockets = 0;
      
      #ifdef GAME_HIPNOTIC
      if ( (other.items & (IT_LIGHTNING|IT_LASER_CANNON|IT_MJOLNIR)) && (other.AMMO_CELLS < 15) )
      #else
      if ( (other.items & IT_LIGHTNING) && (other.AMMO_CELLS < 15) )
      #endif
        take_cells = 15 - other.AMMO_CELLS;
      else
        take_cells = 0;
      
      #ifdef GAME_ROGUE
        if ( (other.items & (IT_LAVA_NAILGUN|IT_LAVA_SUPER_NAILGUN)) && (other.ammo_lava_nails < 20) )
          take_lava = 20 - other.ammo_lava_nails;
        else
          take_lava = 0;
        
        if ( (other.items & (IT_MULTI_GRENADE|IT_MULTI_ROCKET)) && (other.ammo_multi_rockets < 3) )
          take_multi = 3 - other.ammo_multi_rockets;
        else
          take_multi = 0;
        
        if ( (other.items & IT_PLASMA_GUN) && (other.ammo_plasma < 5) )
          take_plasma = 5 - other.ammo_plasma;
        else
          take_plasma = 0;
      #endif
    }
    
    if (self.AMMO_SHELLS > 0)
    {
      if (take_shells > 0)
      {
        pickflags |= PICK_TAKENFROM;
        if (take_shells >= self.AMMO_SHELLS) //Ry: Higher capacity than given ammo
        {
          take_shells = self.AMMO_SHELLS;
          other.AMMO_SHELLS = other.AMMO_SHELLS + self.AMMO_SHELLS;
          self.AMMO_SHELLS = 0;
        }
        else //Ry: Can't carry all of it
        {
          other.AMMO_SHELLS = other.AMMO_SHELLS + take_shells;
          self.AMMO_SHELLS = self.AMMO_SHELLS - take_shells;
          pickflags |= PICK_LEAVE;
        }
      }
      else
        pickflags |= PICK_LEAVE;
    }
    else
      take_shells = 0;
    
    if (self.AMMO_NAILS > 0)
    {
      if (take_nails > 0)
      {
        pickflags |= PICK_TAKENFROM;
        if (take_nails >= self.AMMO_NAILS) //Ry: Higher capacity than given ammo
        {
          take_nails = self.AMMO_NAILS;
          other.AMMO_NAILS = other.AMMO_NAILS + self.AMMO_NAILS;
          self.AMMO_NAILS = 0;
        }
        else //Ry: Can't carry all of it
        {
          other.AMMO_NAILS = other.AMMO_NAILS + take_nails;
          self.AMMO_NAILS = self.AMMO_NAILS - take_nails;
          pickflags |= PICK_LEAVE;
        }
      }
      else
        pickflags |= PICK_LEAVE;
    }
    else
      take_nails = 0;
    
    if (self.AMMO_ROCKETS > 0)
    {
      if (take_rockets > 0)
      {
        pickflags |= PICK_TAKENFROM;
        if (take_rockets >= self.AMMO_ROCKETS) //Ry: Higher capacity than given ammo
        {
          take_rockets = self.AMMO_ROCKETS;
          other.AMMO_ROCKETS = other.AMMO_ROCKETS + self.AMMO_ROCKETS;
          self.AMMO_ROCKETS = 0;
        }
        else //Ry: Can't carry all of it
        {
          other.AMMO_ROCKETS = other.AMMO_ROCKETS + take_rockets;
          self.AMMO_ROCKETS = self.AMMO_ROCKETS - take_rockets;
          pickflags |= PICK_LEAVE;
        }
      }
      else
        pickflags |= PICK_LEAVE;
    }
    else
      take_rockets = 0;
    
    if (self.AMMO_CELLS > 0)
    {
      if (take_cells > 0)
      {
        pickflags |= PICK_TAKENFROM;
        if (take_cells >= self.AMMO_CELLS) //Ry: Higher capacity than given ammo
        {
          take_cells = self.AMMO_CELLS;
          other.AMMO_CELLS = other.AMMO_CELLS + self.AMMO_CELLS;
          self.AMMO_CELLS = 0;
        }
        else //Ry: Can't carry all of it
        {
          other.AMMO_CELLS = other.AMMO_CELLS + take_cells;
          self.AMMO_CELLS = self.AMMO_CELLS - take_cells;
          pickflags |= PICK_LEAVE;
        }
      }
      else
        pickflags |= PICK_LEAVE;
    }
    else
      take_cells = 0;
    
    #ifdef GAME_ROGUE
      if (self.ammo_lava_nails > 0)
      {
        if (take_lava > 0)
        {
          pickflags |= PICK_TAKENFROM;
          if (take_lava >= self.ammo_lava_nails) //Ry: Higher capacity than given ammo
          {
            take_lava = self.ammo_lava_nails;
            other.ammo_lava_nails = other.ammo_lava_nails + self.ammo_lava_nails;
            self.ammo_lava_nails = 0;
          }
          else //Ry: Can't carry all of it
          {
            other.ammo_lava_nails = other.ammo_lava_nails + take_lava;
            self.ammo_lava_nails = self.ammo_lava_nails - take_lava;
            pickflags |= PICK_LEAVE;
          }
        }
        else
          pickflags |= PICK_LEAVE;
      }
      else
        take_lava = 0;
      
      if (self.ammo_multi_rockets > 0)
      {
        if (take_multi > 0)
        {
          pickflags |= PICK_TAKENFROM;
          if (take_multi >= self.ammo_multi_rockets) //Ry: Higher capacity than given ammo
          {
            take_multi = self.ammo_multi_rockets;
            other.ammo_multi_rockets = other.ammo_multi_rockets + self.ammo_multi_rockets;
            self.ammo_multi_rockets = 0;
          }
          else //Ry: Can't carry all of it
          {
            other.ammo_multi_rockets = other.ammo_multi_rockets + take_multi;
            self.ammo_multi_rockets = self.ammo_multi_rockets - take_multi;
            pickflags |= PICK_LEAVE;
          }
        }
        else
          pickflags |= PICK_LEAVE;
      }
      else
        take_multi = 0;
      
      if (self.ammo_plasma > 0)
      {
        if (take_plasma > 0)
        {
          pickflags |= PICK_TAKENFROM;
          if (take_plasma >= self.ammo_plasma) //Ry: Higher capacity than given ammo
          {
            take_plasma = self.ammo_plasma;
            other.ammo_plasma = other.ammo_plasma + self.ammo_plasma;
            self.ammo_plasma = 0;
          }
          else //Ry: Can't carry all of it
          {
            other.ammo_plasma = other.ammo_plasma + take_plasma;
            self.ammo_plasma = self.ammo_plasma - take_plasma;
            pickflags |= PICK_LEAVE;
          }
        }
        else
          pickflags |= PICK_LEAVE;
      }
      else
        take_plasma = 0;
    #endif
    
  }

  if ( (pickflags & PICK_FULL) && (other == self.owner) ) //Ry: Unset owner once they run over the backpack (even if they don't collect anything)
  {
    self.owner = entity_null;
    self.effects = 0;
    self.nextthink = time + 120;
    self.think = SUB_Remove;
  }

  if (!(pickflags & PICK_TAKENFROM)) //Ry: Break if nothing was taken from the backpack
  {
    return;
  }

  if (other.classname == "player") //Ry: Don't run on Gremlins, moved weapon message down here, and merged
  {
    acount = 0;

    if (!(self.netname == ""))
    {
      acount = 1;
      sprint (other, "You got the ");
      sprint (other, self.netname);
      self.netname = "";
    }
    
    if (take_shells) //Ry: Now using new values for these
    {
      if (acount == 0)
        sprint (other, "You got ");
      else
        sprint(other, ", ");
      acount = 1;
      sprint (other, ftos(take_shells));
      sprint (other, " shells");
    }
    if (take_nails)
    {
      if (acount == 0)
        sprint (other, "You got ");
      else
        sprint(other, ", ");
      acount = 1;
      sprint (other, ftos(take_nails));
      sprint (other, " nails");
    }
    if (take_rockets)
    {
      if (acount == 0)
        sprint (other, "You got ");
      else
        sprint(other, ", ");
      acount = 1;
      sprint (other, ftos(take_rockets));
      sprint (other, " rockets");
    }
    if (take_cells)
    {
      if (acount == 0)
        sprint (other, "You got ");
      else
        sprint(other, ", ");
      acount = 1;
      sprint (other, ftos(take_cells));
      sprint (other, " cells");
    }
    #ifdef GAME_ROGUE
      if (take_lava)
      {
        if (acount == 0)
          sprint (other, "You got ");
        else
          sprint(other, ", ");
        acount = 1;
        sprint (other, ftos(take_lava));
        sprint (other, " lava nails");
      }
      if (take_multi)
      {
        if (acount == 0)
          sprint (other, "You got ");
        else
          sprint(other, ", ");
        acount = 1;
        sprint (other, ftos(take_multi));
        sprint (other, " multi rockets");
      }
      if (take_plasma)
      {
        if (acount == 0)
          sprint (other, "You got ");
        else
          sprint(other, ", ");
        acount = 1;
        sprint (other, ftos(take_plasma));
        sprint (other, " plasma balls");
      }
    #endif

    if (acount > 0)
    {
      sprint (other, "\n");
    }
    stuffcmd (other, "bf\n");

  }
// backpack touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);

  bound_other_ammo ();

  if (pickflags & PICK_LEAVE) //Ry: Leave the backpack if ammo remains
  {
    self.lastfragtime = time + 2; //Ry: Next time backpack can be picked
    #ifdef GAME_HIPNOTIC
      if ( (self.think == GremlinBackpackSafety) && !self.stolenitems ) //Ry: If all stolen weapons are collected from the backpack, revert to regular backpack operation
      {
        self.nextthink = time + 120;	// remove after 2 minutes
        self.think = SUB_Remove;
      }
    #endif
  }
  else
    remove(self);
	self = other;
  
  #ifdef GAME_ROGUE
    EnableComboWeapons ( self );
  #endif

// change to the weapon
  #ifdef ENGINE_KEX
  if(W_WantsToChangeWeapon(other, olditems, other.items) == 1) //Ry: Remaster function for checking the user's weapon switch settings
  #endif
    if (!deathmatch)
      self.weapon = new;
    else
      Deathmatch_Weapon (oldweapon, new);

  #ifdef GAME_ROGUE
    UpdateAmmoCounts (self);
  #endif

  #ifdef GAME_HIPNOTIC
  if (self.classname == "monster_gremlin") //Ry: Gremlin stuff
  {
    if (self.goalentity == stemp)
      GremlinAbandonItem();
    W_UpdateAmmo();
  }
  else if (self.weapon == oldweapon) //Ry: Actually check if the weapon changed instead of always resetting weapon
  #else
  if (self.weapon == oldweapon)
  #endif
    W_UpdateAmmo();
  else
    W_SetCurrentAmmo();
};

/*
===============
DropBackpack
===============
*/
void(float dropall) DropBackpack =
{
	local entity	item;
  local float backammo_shells, backammo_nails, backammo_rockets, backammo_cells;
  #ifdef GAME_ROGUE
    local float backammo_lava, backammo_multi, backammo_plasma;
  #endif
  
	// Yoder Sept24 2021 Horde Merge
	// don't drop backpacks in horde mode
	if (horde_ent)
		return; 
  
  if (!dropall && coop && (self.flags & FL_CLIENT)) //Ry: Players in Co-op will be given a minimum amount of ammo on respawn, which is also taken away from the backpack
  {
    
    if (self.AMMO_SHELLS > 25)
      backammo_shells = self.AMMO_SHELLS - 25;
    else
      backammo_shells = 0;
    
    if ( self.items & (IT_NAILGUN|IT_SUPER_NAILGUN) )
    {
      if (self.AMMO_NAILS > 30)
        backammo_nails = self.AMMO_NAILS - 30;
      else
        backammo_nails = 0;
    }
    else
      backammo_nails = self.AMMO_NAILS;
    
    #ifdef GAME_HIPNOTIC
    if ( self.items & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER|IT_PROXIMITY_GUN) )
    #else
    if ( self.items & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER) )
    #endif
    {
      if (self.AMMO_ROCKETS > 5)
        backammo_rockets = self.AMMO_ROCKETS - 5;
      else
        backammo_rockets = 0;
    }
    else
      backammo_rockets = self.AMMO_ROCKETS;
    
    #ifdef GAME_HIPNOTIC
    if ( self.items & (IT_LIGHTNING|IT_LASER_CANNON|IT_MJOLNIR) )
    #else
    if ( self.items & (IT_LIGHTNING) )
    #endif
    {
      if (self.AMMO_CELLS > 15)
        backammo_cells = self.AMMO_CELLS - 15;
      else
        backammo_cells = 0;
    }
    else
      backammo_cells = self.AMMO_CELLS;
    
    #ifdef GAME_ROGUE
      if ( self.items & (IT_LAVA_NAILGUN|IT_LAVA_SUPER_NAILGUN) )
      {
        if (self.ammo_lava_nails > 20)
          backammo_lava = self.ammo_lava_nails - 20;
        else
          backammo_lava = 0;
      }
      else
        backammo_lava = self.ammo_lava_nails;
      
      if ( self.items & (IT_MULTI_GRENADE|IT_MULTI_ROCKET) )
      {
        if (self.ammo_multi_rockets > 3)
          backammo_multi = self.ammo_multi_rockets - 3;
        else
          backammo_multi = 0;
      }
      else
        backammo_multi = self.ammo_multi_rockets;
      
      if ( self.items & IT_PLASMA_GUN )
      {
        if (self.ammo_plasma > 5)
          backammo_plasma = self.ammo_plasma - 5;
        else
          backammo_plasma = 0;
      }
      else
        backammo_plasma = self.ammo_plasma;
    #endif
    
  }
  else
  {
    backammo_shells = self.AMMO_SHELLS;
    backammo_nails = self.AMMO_NAILS;
    backammo_rockets = self.AMMO_ROCKETS;
    backammo_cells = self.AMMO_CELLS;
    #ifdef GAME_ROGUE
      backammo_lava = self.ammo_lava_nails;
      backammo_multi = self.ammo_multi_rockets;
      backammo_plasma = self.ammo_plasma;
    #endif
  }

  //Ry: Make sure non-starting weapons are dropped in DM, even with absolutely no ammo
  #ifdef GAME_ROGUE
	if ( (!(backammo_shells + backammo_nails + backammo_rockets + backammo_cells + backammo_lava + backammo_multi + backammo_plasma))
      && ( !deathmatch || (self.weapon == IT_AXE) || (self.weapon == IT_SHOTGUN) ) )
  #else
  if ( (!(backammo_shells + backammo_nails + backammo_rockets + backammo_cells))
      && ( !deathmatch || (self.weapon == IT_AXE) || (self.weapon == IT_SHOTGUN) ) )
  #endif
		return;	// nothing in it

	item = spawn();
  item.classname = "item_backpack"; //Ry: Actually give this a class name
	item.origin = self.origin - '0 0 24';

  if (deathmatch) //Ry: Normal behavior for DM
  {
    item.items = self.weapon;
    #ifdef GAME_ROGUE
      if (item.items == IT_LAVA_NAILGUN)
        item.items = IT_NAILGUN;
      else if (item.items == IT_LAVA_SUPER_NAILGUN)
        item.items = IT_SUPER_NAILGUN;
      else if (item.items == IT_MULTI_GRENADE)
        item.items = IT_GRENADE_LAUNCHER;
      else if (item.items == IT_MULTI_ROCKET)
        item.items = IT_ROCKET_LAUNCHER;
      else if (item.items == IT_PLASMA_GUN)
        item.items = IT_LIGHTNING;
    #endif
    item.netname = GetWeaponName(item.items);
  }

	item.AMMO_SHELLS = backammo_shells;
	item.AMMO_NAILS = backammo_nails;
	item.AMMO_ROCKETS = backammo_rockets;
	item.AMMO_CELLS = backammo_cells;
  #ifdef GAME_ROGUE
    item.ammo_lava_nails = backammo_lava;
    item.ammo_multi_rockets = backammo_multi;
    item.ammo_plasma = backammo_plasma;
  #endif

	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);

	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	setmodel (item, "progs/backpack.mdl");
	setsize (item, '-16 -16 0', '16 16 56');
	item.touch = BackpackTouch;
  
  item.lastfragtime = -999; //Ry: Using this to avoid repeated picking while firing

  if (!dropall && coop && self.classname == "player") //Ry: Ensure player backpacks stay safe in Co-op
  {
    item.owner = self;
    item.effects = EF_DIMLIGHT;
    item.nextthink = time + 1;
    item.think = PlayerBackpackSafety;
    item.lastsafevect = self.lastsafevect;
  }
  else
  {
    item.nextthink = time + 120;	// remove after 2 minutes
    item.think = SUB_Remove;
  }
};


