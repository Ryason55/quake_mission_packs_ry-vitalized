void() W_SetCurrentAmmo;
void() W_UpdateAmmo; //Ry: Added function name reference here
/* ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR */


//Ry: New func, located in client.qc
void(entity player, float type, string message1, string message2 = "", string message3 = "", string message4 = "", string message5 = "", string message6 = "") FilteredCenterPrint;


void() SUB_regen =
{
	self.model = self.mdl;		// restore original model
	self.solid = SOLID_TRIGGER;	// allow it to be touched again
  self.effects = self.itemeffect; //Ry: Add item effect if defined
  self.alpha = 0; //Ry: Remove alpha effects
	sound (self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);	// play respawn sound
	setorigin (self, self.origin);
};



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

void() GremlinItemSafety;

void(entity item) UpdateItemTransparency = //Ry: In Co-op, set item to be transparent if all active players have picked the item
{
  if (coop)
  {
    local float currindex = 1;
    while (currindex <= highestplayerindex) //Ry: Check if any active players don't have the weapon
    {
      if ( (playerindexinuse & currindex) && !(item.pickers & currindex) )
      {
        item.alpha = 1;
        return;
      }
      currindex = currindex * 2;
    }
    item.alpha = 0.25;
  }
}

void() TransparentThink = //Ry: Thinker version of the above
{
  UpdateItemTransparency(self);
  if (self.displaced) //Ry: Reinstate safety thinker if it was running
  {
    self.think = GremlinItemSafety;
    self.nextthink = time + 1;
  }
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
  }
}

void() ItemPreSpawnGhost = //Ry: Show a ghost of the item shortly before spawning
{
  if (self.enemy.model == string_null)
  {
    self.enemy.model = self.enemy.mdl;
    self.enemy.alpha = 0.2;
  }
}

void(float spawntime) PrepareItemRespawn =
{
  self.nextthink = spawntime;
  self.think = SUB_regen;
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
}


/*
============
PlaceItem

plants the object on the floor
============
*/
void() PlaceItem =
{
	local float	oldz;

	self.mdl = self.model;		// so it can be restored on respawn
	self.flags = FL_ITEM;		// make extra wide
	self.solid = SOLID_TRIGGER;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	oldz = self.origin_z;
  
  self.pickorigin = self.origin; //Ry: For dropping powerups
  self.remaintime = 0;
  self.nextspawntime = 0;
  
  
  if ( ((!deathmatch) && (!coop)) && (self.respawntimesp > 0) ) //Ry: Set respawn time if an override is set
  {
    self.respawntime = self.respawntimesp;
    dprint("set respawn for SP item\n");
  }
  else if ( (coop) && (self.respawntimecoop > 0) )
  {
    self.respawntime = self.respawntimecoop;
    dprint("set respawn for Co-op item\n");
  }
  else if ( (deathmatch) && (self.respawntimedm > 0) )
  {
    self.respawntime = self.respawntimedm;
    dprint("set respawn for DM item\n");
  }
  
  if (self.nograv) //Ry: Added capability for items to be placed in the air
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
  }
  
  if (self.delayspawn > 0.2) //Ry: Delayed spawning
  {
    self.solid = SOLID_NOT;
    self.model = string_null;
    PrepareItemRespawn(time + self.delayspawn - 0.2); //Ry: Now also sets up a ghost for the item when close to spawning
  }
  else
    self.effects = self.itemeffect; //Ry: Add item effect if defined
  
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
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 20;

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
	local	float amount;
	local	string	s;

	if (other.classname != "player")
		return;
  
  if ( coop && (!self.respawntime) && (other.flags & FL_CLIENT) && (self.pickers & other.playerindex) ) //Ry: Cancel if player has already collected the item
  {
    if (!(self.alpha == 0.25)) //Ry: Item will turn transparent when a player that already used it is standing over it
      self.alpha = 0.25;
    self.nextthink = time + 0.1;
    self.think = TransparentThink;
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
  
  if (!coop || self.respawntime) //Ry: Leave health in Co-op
  {
    self.model = string_null;
    self.solid = SOLID_NOT;
  }

	// Megahealth = rot down the player's super health
	if (self.healtype == 2)
	{
// 11/02/96 removed SUPERHEALTH from defs.qc
//      other.items = other.items | IT_SUPERHEALTH;
    if (coop || self.respawntime)
    {
      CreateExtraItemThinker(); //Ry: Separate entity to do the thinking; Co-op has a thinker for the transparency, and the 1 second nextthinks from rotting screw with bots in DM
      self.trigger_field.nextthink = time + 5;
      self.trigger_field.think = item_megahealth_rot;
      self.trigger_field.owner = other;
      
      //local entity rot_ent = spawn(); //Ry: Separate entity to do the thinking; Co-op has a thinker for the transparency, and the 1 second nextthinks from rotting screw with bots in DM
      //rot_ent.classname = "megarot";
      //rot_ent.origin = self.origin + '16 16 0';
      //rot_ent.nextthink = time + 5;
      //rot_ent.think = item_megahealth_rot;
      //rot_ent.owner = other;
      //rot_ent.enemy = self;
      if (self.respawntime && (deathmatch != 2)) //Ry: Max time; Rot thinker will lower it to respawntime when the rotting has finished
      {
        self.nextthink = time + 300;
        self.think = SUB_regen;
      }
    }
    else
    {
      self.nextthink = time + 5;
      self.think = item_megahealth_rot;
      self.owner = other;
    }
	}
	else if (self.respawntime && (deathmatch != 2))
	{
    PrepareItemRespawn(time + self.respawntime); //Ry: Now also sets up a ghost for the item when close to spawning
    //self.nextthink = time + 20;
    //self.think = SUB_regen;
    //PrepareSpawnGhost();
	}
  
  if (coop && (!self.respawntime))
  {
    self.pickers = self.pickers + other.playerindex; //Ry: Mark off that this player has picked the item
    if (!(self.alpha == 0.25))
      self.alpha = 0.25;
    self.nextthink = time + 0.1;
    self.think = TransparentThink;
    if (self.healtype > 0) //Ry: Demote the item each pick
    {
      if (self.healtype == 2) //Ry: Demote to 25
      {
        setmodel(self, "maps/b_bh25.bsp");
        self.noise = "items/health1.wav";
        self.healamount = 25;
        self.healtype = 1;
      }
      else //Ry: Demote to 15
      {
        setmodel(self, "maps/b_bh10.bsp");
        self.noise = "items/r_item1.wav";
        self.healamount = 15;
        self.healtype = 0;
      }
      setsize (self, '0 0 0', '32 32 56');
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
		other.health = other.health - 1;
		self.nextthink = time + 1;
		return;
	}

// it is possible for a player to die and respawn between rots, so don't
// just blindly subtract the flag off
// MED 11/02/96 removed SUPERHEALTH
//   other.items = other.items - (other.items & IT_SUPERHEALTH);

  if (coop && (!self.respawntime)) //Ry: Multiplayer modes now use a separate thinker for the rotting, which can be removed when the rot is done
    remove(self);
	else if ( self.respawntime && (deathmatch != 2) && (self.enemy.model == string_null) )
	{
    self = self.enemy;
    PrepareItemRespawn(time + self.respawntime); //Ry: Now also sets up a ghost for the item when close to spawning
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
  
  if ( coop && (!self.respawntime) && (other.flags & FL_CLIENT) && (self.pickers & other.playerindex) ) //Ry: Cancel if player has already collected the item
  {
    if (!(self.alpha == 0.25)) //Ry: Item will turn transparent when a player that already used it is standing over it
      self.alpha = 0.25;
    self.nextthink = time + 0.1;
    self.think = TransparentThink;
    return;
  }

	if (self.classname == "item_armor1")
	{
		type = 0.3;
		value = 100;
      bit = IT_ARMOR1;
   }
	if (self.classname == "item_armor2")
	{
		type = 0.6;
		value = 150;
		bit = IT_ARMOR2;
	}
	if (self.classname == "item_armorInv")
	{
		type = 0.8;
		value = 200;
		bit = IT_ARMOR3;
	}
	if (other.armortype*other.armorvalue >= type*value)
		return;

	other.armortype = type;
	other.armorvalue = value;
   other.items = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + bit;

  
  if (coop && (!self.respawntime))
  {
    self.pickers = self.pickers + other.playerindex; //Ry: Mark off that this player has picked the item
    if (!(self.alpha == 0.25))
      self.alpha = 0.25;
    self.nextthink = time + 0.1;
    self.think = TransparentThink;
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
  }
  else
  {
    self.solid = SOLID_NOT;
    self.model = string_null;
    if ( self.respawntime && (deathmatch != 2) )
    {
      PrepareItemRespawn(time + self.respawntime); //Ry: Now also sets up a ghost for the item when close to spawning
      //self.nextthink = time + 20;
      //self.think = SUB_regen;
      //PrepareSpawnGhost(); //Ry: Ghost of the item appears when close to respawning
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
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 20;
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
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 20;
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
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch) //Ry: DM Respawn time defined here now
    self.respawntime = 20;
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
	if (other.ammo_shells > 100)
		other.ammo_shells = 100;
	if (other.ammo_nails > 200)
		other.ammo_nails = 200;
	if (other.ammo_rockets > 100)
		other.ammo_rockets = 100;
	if (other.ammo_cells > 100)
		other.ammo_cells = 100;
};


//MED 01/06/97 added hipnotic weapons into rankings
float(float w) RankForWeapon =
{
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
  if (!(self.weapon == IT_MJOLNIR) || self.ammo_cells < 15) //Ry: Don't switch off of Mjolnir (when usable) on picking an item pls
  {
    local float or, nr;

  // change self.weapon if desired
    or = RankForWeapon (self.weapon);
    nr = RankForWeapon (new);
    if ( nr < or )
      self.weapon = new;
  }
};

/*
=============
weapon_touch
=============
*/

float() W_BestWeapon;

void() weapon_touch =
{
	local	float	hadammo, best, new, old;
	local	entity	stemp;
	local	float	leave;
  local string itemname;
  //local float respawntime;

	if (!(other.flags & FL_CLIENT || ((other.classname == "monster_gremlin") && !(other.gorging) && !(self.stoleweapon) && !(other.super_item) && !(self.classname == "weapon_mjolnir")) )) //Ry: Gremlins now able to pick a weapon
		return;
	if (other.health <= 0) //Ry: Health wasn't being checked here
		return;
    
  if ( coop && (!self.respawntime) && (other.flags & FL_CLIENT) && (self.pickers & other.playerindex) ) //Ry: Cancel if player has already collected the weapon
  {
    if (!(self.alpha == 0.25)) //Ry: Item will turn transparent when a player that already used it is standing over it
      self.alpha = 0.25;
    self.nextthink = time + 0.1;
    self.think = TransparentThink;
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
    //if (deathmatch > 1)
    //  respawntime = 5;
    if (self.classname == "weapon_nailgun")
    {
      hadammo = other.ammo_nails;
        
      if (other.items & IT_NAILGUN)
      {
        other.ammo_nails = other.ammo_nails + 10;
        itemname = "nails";
      }
      else
      {
        new = IT_NAILGUN;
        other.ammo_nails = other.ammo_nails + 30;
      }
    }
    else if (self.classname == "weapon_supernailgun")
    {
      hadammo = other.ammo_nails;
        
      if (other.items & IT_SUPER_NAILGUN)
      {
        other.ammo_nails = other.ammo_nails + 10;
        itemname = "nails";
      }
      else
      {
        new = IT_SUPER_NAILGUN;
        other.ammo_nails = other.ammo_nails + 30;
      }
    }
    else if (self.classname == "weapon_supershotgun")
    {
      hadammo = other.ammo_shells;
        
      other.ammo_shells = other.ammo_shells + 5;
      if (other.items & IT_SUPER_SHOTGUN)
        itemname = "shells";
      else
        new = IT_SUPER_SHOTGUN;
    }
    else if (self.classname == "weapon_rocketlauncher")
    {
      hadammo = other.ammo_rockets;
        
      if (other.items & IT_ROCKET_LAUNCHER)
      {
        other.ammo_rockets = other.ammo_rockets + 2;
        itemname = "rockets";
      }
      else
      {
        new = IT_ROCKET_LAUNCHER;
        other.ammo_rockets = other.ammo_rockets + 5;
      }
    }
    else if (self.classname == "weapon_grenadelauncher")
    {
      hadammo = other.ammo_rockets;
        
      if (other.items & IT_GRENADE_LAUNCHER)
      {
        other.ammo_rockets = other.ammo_rockets + 2;
        itemname = "rockets";
      }
      else
      {
        new = IT_GRENADE_LAUNCHER;
        other.ammo_rockets = other.ammo_rockets + 5;
      }
    }
    else if (self.classname == "weapon_lightning")
    {
      hadammo = other.ammo_cells;
        
      if (other.items & IT_LIGHTNING)
      {
        other.ammo_cells = other.ammo_cells + 3;
        itemname = "cells";
      }
      else
      {
        new = IT_LIGHTNING;
        other.ammo_cells = other.ammo_cells + 15;
      }
    }
  //MED
     else if (self.classname == "weapon_laser_gun")
    {
      hadammo = other.ammo_cells;
        
      if (other.items & IT_LASER_CANNON)
      {
        other.ammo_cells = other.ammo_cells + 5;
        itemname = "cells";
      }
      else
      {
        new = IT_LASER_CANNON;
        other.ammo_cells = other.ammo_cells + 30;
      }
    }
  //MED
     else if (self.classname == "weapon_mjolnir")
    {
      hadammo = other.ammo_cells;
      //respawntime = 30;
        
      if (other.items & IT_MJOLNIR)
      {
        other.ammo_cells = other.ammo_cells + 15;
        itemname = "cells";
      }
      else
      {
        new = IT_MJOLNIR;
        other.ammo_cells = other.ammo_cells + 30;
      }
    }
  //MED
     else if (self.classname == "weapon_proximity_gun")
    {
      hadammo = other.ammo_rockets;
        
      if (other.items & IT_PROXIMITY_GUN)
      {
        other.ammo_rockets = other.ammo_rockets + 2;
        itemname = "rockets";
      }
      else
      {
        new = IT_PROXIMITY_GUN;
        other.ammo_rockets = other.ammo_rockets + 6;
      }
    }
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
      if (leave && (other.items & IT_NAILGUN) && (other.ammo_nails >= 200) ) //Ry: Will only leave now if can't collect the ammo
        return;
      if ((other.classname == "monster_gremlin") && (other.items & IT_NAILGUN)) //Ry: Gremlins leave the weapon if they already have a stolen one
        return;
      hadammo = other.ammo_nails;
      new = IT_NAILGUN;
      other.ammo_nails = other.ammo_nails + 30;
    }
    else if (self.classname == "weapon_supernailgun")
    {
      if (leave && (other.items & IT_SUPER_NAILGUN) && (other.ammo_nails >= 200) )
        return;
      if ((other.classname == "monster_gremlin") && (other.items & IT_SUPER_NAILGUN))
        return;
      hadammo = other.ammo_rockets;
      new = IT_SUPER_NAILGUN;
      other.ammo_nails = other.ammo_nails + 30;
    }
    else if (self.classname == "weapon_supershotgun")
    {
      if (leave && (other.items & IT_SUPER_SHOTGUN) && (other.ammo_shells >= 100) )
        return;
      if ((other.classname == "monster_gremlin") && (other.items & IT_SUPER_SHOTGUN))
        return;
      hadammo = other.ammo_rockets;
      new = IT_SUPER_SHOTGUN;
      other.ammo_shells = other.ammo_shells + 5;
    }
    else if (self.classname == "weapon_rocketlauncher")
    {
      if (leave && (other.items & IT_ROCKET_LAUNCHER) && (other.ammo_rockets >= 100) )
        return;
      if ((other.classname == "monster_gremlin") && (other.items & IT_ROCKET_LAUNCHER))
        return;
      hadammo = other.ammo_rockets;
      new = IT_ROCKET_LAUNCHER;
      other.ammo_rockets = other.ammo_rockets + 5;
    }
    else if (self.classname == "weapon_grenadelauncher")
    {
      if (leave && (other.items & IT_GRENADE_LAUNCHER) && (other.ammo_rockets >= 100) )
        return;
      if ((other.classname == "monster_gremlin") && (other.items & IT_GRENADE_LAUNCHER))
        return;
      hadammo = other.ammo_rockets;
      new = IT_GRENADE_LAUNCHER;
      other.ammo_rockets = other.ammo_rockets + 5;
    }
    else if (self.classname == "weapon_lightning")
    {
      if (leave && (other.items & IT_LIGHTNING) && (other.ammo_cells >= 100) )
        return;
      if ((other.classname == "monster_gremlin") && (other.items & IT_LIGHTNING))
        return;
      hadammo = other.ammo_rockets;
      new = IT_LIGHTNING;
      other.ammo_cells = other.ammo_cells + 15;
    }
  //MED
     else if (self.classname == "weapon_laser_gun")
    {
      if (leave && (other.items & IT_LASER_CANNON) && (other.ammo_cells >= 100) )
        return;
      if ((other.classname == "monster_gremlin") && (other.items & IT_LASER_CANNON))
        return;
      hadammo = other.ammo_rockets;
        new = IT_LASER_CANNON;
        other.ammo_cells = other.ammo_cells + 30;
    }
  //MED
     else if (self.classname == "weapon_mjolnir")
    {
      if (leave && (other.items & IT_MJOLNIR) && (other.ammo_cells >= 100) )
        return;
      if ((other.classname == "monster_gremlin") && (other.items & IT_MJOLNIR))
        return;
      hadammo = other.ammo_rockets;
        new = IT_MJOLNIR;
        other.ammo_cells = other.ammo_cells + 30;
    }
  //MED
     else if (self.classname == "weapon_proximity_gun")
    {
      if (leave && (other.items & IT_PROXIMITY_GUN) && (other.ammo_rockets >= 100) )
        return;
      if ((other.classname == "monster_gremlin") && (other.items & IT_PROXIMITY_GUN))
        return;
      hadammo = other.ammo_rockets;
        new = IT_PROXIMITY_GUN;
        other.ammo_rockets = other.ammo_rockets + 6;
    }
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
      if (!(self.alpha == 0.25))
        self.alpha = 0.25;
      self.nextthink = time + 0.1;
      self.think = TransparentThink;
    }
  }
  // weapon touch sound
  sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);

    bound_other_ammo ();

// change to the weapon
  old = other.weapon; //Ry: Making use of this now, since it wasn't even used before
  other.items = other.items | new;

  stemp = self;
  self = other;

  if (!deathmatch)
    self.weapon = new;
  else
    Deathmatch_Weapon (old, new);

  if (self.classname == "monster_gremlin") //Ry: Gremlin
  {
    self.stoleweapon = TRUE;
    if (!self.pickorigin)
      self.pickorigin = self.origin; //Ry: Track where the item was picked from, so it can be put back if something happens to the item
    W_UpdateAmmo();
    if (!deathmatch)
    {
      stemp.stoleweapon = TRUE; //Ry: Ensure only one Gremlin can grab the item on a frame
      self.super_item = stemp; //Store the weapon item so Gremlin can drop it
      leave = FALSE;
    }
  }
  else //Ry: Player
    if (self.weapon == old) //Ry: Actually check if the weapon changed instead of always resetting weapon
      W_UpdateAmmo();
    else
      W_SetCurrentAmmo();

	self = stemp;

	if (leave)
		return;

// remove it in single player, or setup for respawning in deathmatch
	self.model = string_null;
	self.solid = SOLID_NOT;
  
	if (self.respawntime) //Ry Edit: Respawn in Deathmatch always if the item doesn't stay
  {
    PrepareItemRespawn(time + self.respawntime); //Ry: Now also sets up a ghost for the item when close to spawning
		//self.nextthink = time + respawntime;
    //self.think = SUB_regen;
    //PrepareSpawnGhost(); //Ry: Ghost of the item appears when close to respawning
  }

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
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
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch && (deathmatch != 2)) //Ry: DM Respawn time defined here now
    self.respawntime = 5;
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
	self.netname = "nailgun";
	self.touch = weapon_touch;
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch && (deathmatch != 2)) //Ry: DM Respawn time defined here now
    self.respawntime = 5;
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
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch && (deathmatch != 2)) //Ry: DM Respawn time defined here now
    self.respawntime = 5;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_grenadelauncher =
{
	precache_model ("progs/g_rock.mdl");
  precache_model ("progs/g_prox.mdl"); //Ry: Also precache hipnotic's Proximity Gun
	setmodel (self, "progs/g_rock.mdl");
	self.weapon = IT_GRENADE_LAUNCHER; //Ry: Was 3; Fixed
	self.netname = "Grenade Launcher";
	self.touch = weapon_touch;
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch && (deathmatch != 2)) //Ry: DM Respawn time defined here now
    self.respawntime = 5;
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
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch && (deathmatch != 2)) //Ry: DM Respawn time defined here now
    self.respawntime = 5;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};


/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_lightning =
{
  precache_model ("progs/g_light.mdl");
	precache_model ("progs/g_laserg.mdl"); //Ry: Also precache hipnotic's Laser Cannon and Mjolnir
  precache_model ("progs/g_hammer.mdl");
	setmodel (self, "progs/g_light.mdl");
	self.weapon = IT_LIGHTNING; //Ry: Was 3; Fixed
	self.netname = "Thunderbolt";
	self.touch = weapon_touch;
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch && (deathmatch != 2)) //Ry: DM Respawn time defined here now
    self.respawntime = 5;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};


/*
===============================================================================

AMMO

===============================================================================
*/

float WEAPON_BIG2 = 1; //Ry: Moved this up here

void() ammo_touch =
{
  local entity	stemp;
  local float		best;
  local	float	leave; //Ry: Now can leave ammo in Co-op

	if (!(other.classname == "player" || ( (other.classname == "monster_gremlin") && !(other.gorging) && !self.stoleweapon ) )) //Ry: Gremlins now grab ammo if they have a gun that needs it
		return;
	if (other.health <= 0)
		return;
  
  if ( coop && (other.flags & FL_CLIENT) && (self.pickers & other.playerindex) ) //Ry: Cancel if player has already collected the item
  {
    if (!(self.alpha == 0.25)) //Ry: Item will turn transparent when a player that already used it is standing over it
      self.alpha = 0.25;
    self.nextthink = time + 0.1;
    self.think = TransparentThink;
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
		if (other.ammo_shells >= 100)
			return;
    if ((other.classname == "monster_gremlin") && !(other.items & IT_SUPER_SHOTGUN) ) //Ry: Gremlin must have a relevant weapon
      return;
		other.ammo_shells = other.ammo_shells + self.aflag;
	}

// spikes
	if (self.weapon == 2)
	{
		if (other.ammo_nails >= 200)
			return;
    if ((other.classname == "monster_gremlin") && !( (other.items & IT_NAILGUN) || (other.items & IT_SUPER_NAILGUN) ) )
      return;
		other.ammo_nails = other.ammo_nails + self.aflag;
	}

//	rockets
	if (self.weapon == 3)
	{
		if (other.ammo_rockets >= 100)
			return;
    if ((other.classname == "monster_gremlin") && !( (other.items & IT_ROCKET_LAUNCHER) || (other.items & IT_GRENADE_LAUNCHER) || (other.items & IT_PROXIMITY_GUN) ) )
      return;
		other.ammo_rockets = other.ammo_rockets + self.aflag;
	}

//	cells
	if (self.weapon == 4)
	{
		if (other.ammo_cells >= 100)
			return;
    if ((other.classname == "monster_gremlin") && !( (other.items & IT_LIGHTNING) || (other.items & IT_LASER_CANNON) ) )
      return;
		other.ammo_cells = other.ammo_cells + self.aflag;
	}

	bound_other_ammo ();

  if (other.classname == "player") //Ry: Make sure these don't run on Gremlin
  {
    sprint (other, "You got the ");
    sprint (other, self.netname);
    sprint (other, "\n");
    stuffcmd (other, "bf\n");
    if (coop)
    {
      self.pickers = self.pickers + other.playerindex; //Ry: Mark off that this player has picked the item
      if (!(self.alpha == 0.25))
        self.alpha = 0.25;
      self.nextthink = time + 0.1;
      self.think = TransparentThink;
    }
  }
  else if (!deathmatch) //Ry: Only one Gremlin can grab the ammo in campaign
    self.stoleweapon = TRUE;
  
  if (coop)
  {
    leave = TRUE;
    if (self.spawnflags & WEAPON_BIG2) //Ry: Demote big item when the first player picks
    {
      self.spawnflags = self.spawnflags - WEAPON_BIG2;
      if (self.weapon == 1 && self.aflag > 20) 
      {
        setmodel (self, "maps/b_shell0.bsp");
        self.aflag = 20;
        self.origin = self.origin + '4 4 0'; //Ry: Adjust origin so the item looks centered on where the big item was
        setsize (self, '-4 -4 0', '28 28 56'); //Ry: While hitbox remains in basically the same place
      }
      else if (self.weapon == 2 && self.aflag > 25)
      {
        setmodel (self, "maps/b_nail0.bsp");
        self.aflag = 25;
        self.origin = self.origin + '4 4 0';
        setsize (self, '-4 -4 0', '28 28 56');
      }
      else if (self.weapon == 3 && self.aflag > 5)
      {
        setmodel (self, "maps/b_rock0.bsp");
        self.aflag = 5;
        self.origin = self.origin + '8 0 0';
        setsize (self, '-8 0 0', '24 32 56');
      }
      else if (self.weapon == 4 && self.aflag > 6)
      {
        setmodel (self, "maps/b_batt0.bsp");
        self.aflag = 6;
        self.origin = self.origin + '4 4 0';
        setsize (self, '-4 -4 0', '28 28 56');
      }
    }
  }
  
// ammo touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);

// change to a better weapon if appropriate

  stemp = self;
  self = other;
  
  if (other.classname == "monster_gremlin") //Ry: Gremlin
  {
    if (other.weapon == best)
      self.weapon = W_BestWeapon();
    W_UpdateAmmo();
  }
  else //Ry: Player
  {
    if ( other.weapon == best && (!deathmatch || !(self.weapon == IT_MJOLNIR) || self.ammo_cells < 15 ) ) //Ry: Condensed this a bit, made a lighter ammo update, and don't switch off usable Mjolnir
    {
      self.weapon = W_BestWeapon();
      W_SetCurrentAmmo ();
    }
    else
      W_UpdateAmmo();
  }

	self = stemp;
  
  if (leave)
    return;

// remove it in single player, or setup for respawning in deathmatch
	self.model = string_null;
	self.solid = SOLID_NOT;
	if (deathmatch && (deathmatch != 2)) //Ry edit: Respawn in Deathmatch 3/4 as well
  {
    PrepareItemRespawn(time + 30); //Ry: Now also sets up a ghost for the item when close to spawning
		//self.nextthink = time + 30;
    //self.think = SUB_regen;
    //PrepareSpawnGhost(); //Ry: Ghost of the item appears when close to respawning
  }

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};



/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_shells =
{
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
    precache_model ("maps/b_shell0.bsp"); //Ry: Precache smaller item too now
		precache_model ("maps/b_shell1.bsp");
		setmodel (self, "maps/b_shell1.bsp");
		self.aflag = 40;
	}
	else
	{
		precache_model ("maps/b_shell0.bsp");
		setmodel (self, "maps/b_shell0.bsp");
		self.aflag = 20;
	}
	self.weapon = 1;
	self.netname = "shells";
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch) //Ry: Unused for this item type currently
    self.respawntime = 30;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_spikes =
{
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
    precache_model ("maps/b_nail0.bsp"); //Ry: Precache smaller item too now
		precache_model ("maps/b_nail1.bsp");
		setmodel (self, "maps/b_nail1.bsp");
		self.aflag = 50;
	}
	else
	{
		precache_model ("maps/b_nail0.bsp");
		setmodel (self, "maps/b_nail0.bsp");
		self.aflag = 25;
	}
	self.weapon = 2;
	self.netname = "nails";
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch) //Ry: Unused for this item type currently
    self.respawntime = 30;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_rockets =
{
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
    precache_model ("maps/b_rock0.bsp"); //Ry: Precache smaller item too now
		precache_model ("maps/b_rock1.bsp");
		setmodel (self, "maps/b_rock1.bsp");
		self.aflag = 10;
	}
	else
	{
		precache_model ("maps/b_rock0.bsp");
		setmodel (self, "maps/b_rock0.bsp");
		self.aflag = 5;
	}
	self.weapon = 3;
	self.netname = "rockets";
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch) //Ry: Unused for this item type currently
    self.respawntime = 30;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_cells =
{
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
    precache_model ("maps/b_batt0.bsp"); //Ry: Precache smaller item too now
		precache_model ("maps/b_batt1.bsp");
		setmodel (self, "maps/b_batt1.bsp");
		self.aflag = 12;
	}
	else
	{
		precache_model ("maps/b_batt0.bsp");
		setmodel (self, "maps/b_batt0.bsp");
		self.aflag = 6;
	}
	self.weapon = 4;
	self.netname = "cells";
  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch) //Ry: Unused for this item type currently
    self.respawntime = 30;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/

float WEAPON_SHOTGUN = 1;
float WEAPON_ROCKET = 2;
float WEAPON_SPIKES = 4;
float WEAPON_BIG = 8;
void() item_weapon =
{
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_SHOTGUN)
	{
		if (self.spawnflags & WEAPON_BIG)
		{
      precache_model ("maps/b_shell0.bsp"); //Ry: Precache smaller item too now
			precache_model ("maps/b_shell1.bsp");
			setmodel (self, "maps/b_shell1.bsp");
			self.aflag = 40;
		}
		else
		{
			precache_model ("maps/b_shell0.bsp");
			setmodel (self, "maps/b_shell0.bsp");
			self.aflag = 20;
		}
		self.weapon = 1;
		self.netname = "shells";
	}

	if (self.spawnflags & WEAPON_SPIKES)
	{
		if (self.spawnflags & WEAPON_BIG)
		{
      precache_model ("maps/b_nail0.bsp"); //Ry: Precache smaller item too now
			precache_model ("maps/b_nail1.bsp");
			setmodel (self, "maps/b_nail1.bsp");
			self.aflag = 40;
		}
		else
		{
			precache_model ("maps/b_nail0.bsp");
			setmodel (self, "maps/b_nail0.bsp");
			self.aflag = 20;
		}
		self.weapon = 2;
		self.netname = "spikes";
	}

	if (self.spawnflags & WEAPON_ROCKET)
	{
		if (self.spawnflags & WEAPON_BIG)
		{
      precache_model ("maps/b_rock0.bsp"); //Ry: Precache smaller item too now
			precache_model ("maps/b_rock1.bsp");
			setmodel (self, "maps/b_rock1.bsp");
			self.aflag = 10;
		}
		else
		{
			precache_model ("maps/b_rock0.bsp");
			setmodel (self, "maps/b_rock0.bsp");
			self.aflag = 5;
		}
		self.weapon = 3;
		self.netname = "rockets";
	}

  self.enttype = "item"; //Ry: For easy searching
  if (deathmatch) //Ry: Unused for this item type currently
    self.respawntime = 30;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*
===============================================================================

KEYS

===============================================================================
*/

void() key_touch =
{
local entity	stemp;
local float		best;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
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

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
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
local entity	stemp;
local float		best;

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

void() powerup_touch;

void() SUB_revertpowerup = //Ry: Put the powerup back into position for spawning normally
{
	self.solid = SOLID_NOT;
	self.model = string_null;
	setorigin (self, self.pickorigin);
  self.remaintime = 0;
  self.effects = 0;
  if (self.nograv) //Ry: Ensure no gravity is restored if the item is supposed to float
    self.movetype = MOVETYPE_FLY;
  if (deathmatch)
  {
    PrepareItemRespawn(self.nextspawntime); //Ry: Now also sets up a ghost for the item when close to spawning
    //self.nextthink = self.nextspawntime;
    //self.think = SUB_regen;
    //PrepareSpawnGhost(); //Ry: Ghost of the item appears when close to respawning
  }
  
}

void() powerup_touch =
{
local entity	stemp;
local float		best;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
  
  local float poweruptime; //Ry: Adjust powerup time if it was dropped
  if (self.remaintime > 0)
  {
    poweruptime = time + self.remaintime;
    if ( deathmatch && (poweruptime > (self.nextspawntime - 2)) ) //Ry: Cap powerup time to 2 seconds before it should respawn in Deathmatch
      poweruptime = (self.nextspawntime - 2);
  }
  else
    poweruptime = time + 30;

	if (deathmatch)
	{
    if (self.remaintime == 0) //Ry: Regularly spawned powerup
		{
      if ((self.classname == "item_artifact_invulnerability") ||
        (self.classname == "item_artifact_invisibility"))
        self.nextspawntime = time + 60*5;
      else if (self.classname == "item_artifact_envirosuit")
        self.nextspawntime = time + 60;
      else
        self.nextspawntime = time + 120; //Ry: Powerup respawn time extended since now the powerups will stay in play for longer

      self.pickorigin = self.origin;
      PrepareItemRespawn(self.nextspawntime); //Ry: Now also sets up a ghost for the item when close to spawning
      //self.nextthink = self.nextspawntime;
      //self.think = SUB_regen;
      //PrepareSpawnGhost(); //Ry: Ghost of the item appears when close to respawning
		}
    else //Ry: Dropped powerup. Put it back in it's original spot when it's picked up
    {
      SUB_revertpowerup();
    }
	}
  else if (coop && (self.classname == "item_artifact_envirosuit")) //Ry: Respawn in Co-op
  {
    self.nextthink = time + 3;
    self.think = SUB_regen;
  }
  
  self.solid = SOLID_NOT;
  self.model = string_null;
  self.effects = 0; //Ry: Disable effect on item

  if (poweruptime > 0) //Ry: Just to make sure
  {
    sprint (other, "You got the "); //Ry: Moved this down here
    sprint (other, self.netname);
    sprint (other,"\n");

    sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
    stuffcmd (other, "bf\n");
    other.items = other.items | self.items;

  // do the apropriate action
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
  else
  {
    sprint(other,"Oh, apparently that powerup was empty. That's not supposed to happen.\n");
  }

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

void(entity item, entity player) droppowerup = //Ry: Make the dropped powerup functional again, and place it where the player died
{
  item.model = item.mdl;
  item.effects = item.itemeffect; //Ry: Add item effect if defined
  item.origin = player.origin;
  item.flags = FL_ITEM;
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
  if ((self.super_damage_finished - time > 3) && ( coop || (time < self.super_validdroptime) ) && (self.super_item) )
  {
    self.super_item.remaintime = self.super_damage_finished - time;
    self.super_damage_finished = 0;
    self.super_time = 0;
    self.items = self.items - IT_QUAD;
    droppowerup(self.super_item,self);
  }
  if ((self.invincible_finished - time > 3) && ( coop || (time < self.invincible_validdroptime) ) && (self.invincible_item) )
  {
    self.invincible_item.remaintime = self.invincible_finished - time;
    self.invincible_finished = 0;
    self.invincible_time = 0;
    self.items = self.items - IT_INVULNERABILITY;
    droppowerup(self.invincible_item,self);
  }
  if ((self.invisible_finished - time > 3) && ( coop || (time < self.invisible_validdroptime) ) && (self.invisible_item))
  {
    self.invisible_item.remaintime = self.invisible_finished - time;
    self.invisible_finished = 0;
    self.invisible_time = 0;
    self.items = self.items - IT_INVISIBILITY;
    droppowerup(self.invisible_item,self);
  }
  if (!coop && (self.radsuit_finished - time > 3) && (time < self.radsuit_validdroptime) && (self.radsuit_item) ) //Ry: Don't drop in Co-op, since it's already shared
  {
    self.radsuit_item.remaintime = self.radsuit_finished - time;
    self.radsuit_finished = 0;
    self.rad_time = 0;
    self.items = self.items - IT_SUIT;
    droppowerup(self.radsuit_item,self);
  }
  if ((self.empathy_finished - time > 3) && ( coop || (time < self.empathy_validdroptime) ) && (self.empathy_item) ) //Ry: SoA Powerups
  {
    self.empathy_item.remaintime = self.empathy_finished - time;
    self.empathy_finished = 0;
    self.empathy_time = 0;
    self.items2 = self.items2 - HIP_IT_EMPATHY_SHIELDS;
    droppowerup(self.empathy_item,self);
  }
  if (!coop && (self.wetsuit_finished - time > 3) && (time < self.wetsuit_validdroptime) && (self.wetsuit_item) ) //Ry: Don't drop in Co-op, since it's already shared
  {
    self.wetsuit_item.remaintime = self.wetsuit_finished - time;
    self.wetsuit_finished = 0;
    self.wetsuit_time = 0;
    self.items2 = self.items2 - HIP_IT_WETSUIT;
    droppowerup(self.wetsuit_item,self);
  }
  self.effects = 0;
}


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
  if (deathmatch) //Ry: Unused for this item type currently
    self.respawntime = 300;
	setsize (self, '-16 -16 -24', '16 16 32');
  self.itemeffect = EF_PENTALIGHT; //Ry: New light for powerup
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
  
  precache_model ("progs/wetsuit.mdl"); //Ry: Precache Wetsuit too
  precache_sound ("misc/wetsuit.wav");
  precache_sound ("misc/weton.wav");
  precache_sound ("items/suit2.wav");
  
	self.noise = "items/suit.wav";
	setmodel (self, "progs/suit.mdl");
	self.netname = "Biosuit";
	self.items = IT_SUIT;
  if (deathmatch) //Ry: Unused for this item type currently
    self.respawntime = 60;
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
  if (deathmatch) //Ry: Unused for this item type currently
    self.respawntime = 300;
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
  if (deathmatch) //Ry: Unused for this item type currently
    self.respawntime = 120;
	setsize (self, '-16 -16 -24', '16 16 32');
  self.itemeffect = EF_QUADLIGHT; //Ry: New light for powerup
	StartItem ();
};



/*
===============================================================================

PLAYER BACKPACKS

===============================================================================
*/

void(vector org) spawn_tfog

void(entity item) RecoverItem =
{
  item.lastfragtime = time + 2;
  item.origin = item.lastsafevect;
  item.flags = FL_ITEM;
  item.waterlevel = 0;
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
  //bprint("Owner is ");
  //bprint(self.ownername);
  //bprint("\n");
  if (self.owner && self.owner.view_ofs == '0 0 0') //Ry: Return backpack contents immediately if players are exiting the level
  {
    local float acount = 0;
    self.owner.ammo_shells = self.owner.ammo_shells + self.ammo_shells;
    self.owner.ammo_nails = self.owner.ammo_nails + self.ammo_nails;
    self.owner.ammo_rockets = self.owner.ammo_rockets + self.ammo_rockets;
    self.owner.ammo_cells = self.owner.ammo_cells + self.ammo_cells;
    
    if (self.owner.ammo_shells > 100)
      self.owner.ammo_shells = 100;
    if (self.owner.ammo_nails > 200)
      self.owner.ammo_nails = 200;
    if (self.owner.ammo_rockets > 100)
      self.owner.ammo_rockets = 100;
    if (self.owner.ammo_cells > 100)
      self.owner.ammo_cells = 100;
    
    sprint(self.owner,"Reclaimed "); //Ry: Let player know they got their stuff back
    if (self.ammo_shells > 0)
    {
      acount = 1;
      sprint (self.owner, ftos(self.ammo_shells) );
      sprint (self.owner, " shells");
    }
    if (self.ammo_nails > 0)
    {
      if (acount)
        sprint(self.owner, ", ");
      acount = 1;
      sprint (self.owner, ftos(self.ammo_nails) );
      sprint (self.owner, " nails");
    }
    if (self.ammo_rockets > 0)
    {
      if (acount)
        sprint(self.owner, ", ");
      acount = 1;
      sprint (self.owner, ftos(self.ammo_rockets) );
      sprint (self.owner, " rockets");
    }
    if (self.ammo_cells > 0)
    {
      if (acount)
        sprint(self.owner, ", ");
      acount = 1;
      sprint (self.owner, ftos(self.ammo_cells) );
      sprint (self.owner, " cells");
    }
    sprint (self.owner, "\n");
    
    remove(self);
  }
  else if ( (self.watertype == CONTENT_SLIME) || (self.watertype == CONTENT_LAVA) || ((world.model == "maps/hipdm1.bsp") && ( self.origin_z < -1300 )) )
    RecoverItem(self);
  
  else if (self.owner && !(self.owner.flags & FL_CLIENT)) //Ry: Owner disconnected
  {
    //self.lastspawntime = time + 12;
    //bprint("Backpack owner gone, crab\n");
    self.owner = entity_null;
    self.effects = 0;
    self.nextthink = time + 120;
    self.think = SUB_Remove;
    return;
  }
  
  /*else if (!self.owner && self.ownername) //Ry: Apparently the player name is just instantly forgotten the moment the player leaves, even if stored on an external variable
  {
    local entity e; //Ry: Check if player comes back
    for (e = find(world, netname, self.ownername) ; e ; e = find(e, netname, self.ownername) )
    {
      if (e.flags & FL_CLIENT)
      {
        self.owner = e;
        bprint("Owner has returned\n");
        break;
      }
    }
    if (!self.owner && time >= self.lastspawntime) //Ry: Owner gone long enough; Anyone can claim it now
    {
      bprint("Backpack now unprotected\n");
      //self.ownername = string_null;
      self.effects = 0;
      self.nextthink = time + 120;
      self.think = SUB_Remove;
      return;
    }
  }*/
    
  self.nextthink = time + 1;
}

void() BackpackTouch =
{
   local string   s;
   local float old, new; //Ry: Removed 'best', cause it wasn't being used here
   local    entity   stemp;
	local	float	acount;
  local float take_shells, take_nails, take_rockets, take_cells, leave, takenfrom, fullpick; //Ry: For Co-op

	if (!(other.classname == "player" || ((other.classname == "monster_gremlin") && !(other.gorging)) )) //Ry: eheh
		return;
	if (other.health <= 0)
		return;
  
  if ( (other != self.owner) && (self.lastfragtime > time) ) //Ry: Players who aren't the owner have to wait between picks
    return;
  if ( (!self.owner) || (self.owner == other) )
    fullpick = TRUE;

// if the player was using his best weapon, change up to the new one if better
	//stemp = self;
	//self = other;
	//best = W_BestWeapon(); //Ry: This wasn't even being used
	//self = stemp;
  
  new = self.items; //Ry: Moved this bit up here
	if (new > 0)
  {
    if (deathmatch) //Ry: Give a minimum amount of ammo on picking up a new gun via backpack in deathmatch
    {
      
      self.items = 0;
      takenfrom = TRUE;
      if ( ((new == IT_SHOTGUN) || (new == IT_SUPER_SHOTGUN)) && (self.ammo_shells < 5) )
        self.ammo_shells = 5;
      
      else if ( ((new == IT_NAILGUN) || (new == IT_SUPER_NAILGUN)) && (self.ammo_nails < 30) )
        self.ammo_nails = 30;
      
      else if ( ((new == IT_ROCKET_LAUNCHER) || (new == IT_GRENADE_LAUNCHER)) && (self.ammo_rockets < 5) )
        self.ammo_rockets = 5;
      else if ( (new == IT_PROXIMITY_GUN) && (self.ammo_rockets < 6) )
        self.ammo_rockets = 6;
      
      else if ( ((new == IT_LIGHTNING) || (new == IT_MJOLNIR)) && (self.ammo_cells < 15) ) //Mjolnir is good enough that just one guaranteed use is fine
        self.ammo_cells = 15;
      else if ( (new == IT_LASER_CANNON) && (self.ammo_cells < 30) )
        self.ammo_cells = 30;

    }
    else if (coop) //Ry: Only collect the weapon in a backpack if you didn't already have it in Co-op (For Gremlin and disconnected player backpacks)
    {
      self.netname = "";
      if (fullpick)
      {
        local float weaponcount;
        if (self.items & IT_AXE)
        {
          self.items = self.items - IT_AXE;
          takenfrom = TRUE;
          self.netname = "Axe";
          weaponcount = weaponcount + 1;
        }
        
        if (self.items & IT_SHOTGUN)
        {
          self.items = self.items - IT_SHOTGUN;
          takenfrom = TRUE;
          self.netname = "Shotgun";
          weaponcount = weaponcount + 1;
        }
        
        if (self.items & IT_NAILGUN)
        {
          if (!(other.items & IT_NAILGUN))
          {
            self.items = self.items - IT_NAILGUN;
            takenfrom = TRUE;
            self.netname = "Nailgun";
            weaponcount = weaponcount + 1;
          }
          else
          {
            new = new - IT_NAILGUN;
            leave = TRUE;
          }
        }
        
        if (self.items & IT_SUPER_SHOTGUN)
        {
          if (!(other.items & IT_SUPER_SHOTGUN))
          {
            self.items = self.items - IT_SUPER_SHOTGUN;
            takenfrom = TRUE;
            self.netname = "Double-barrelled Shotgun";
            weaponcount = weaponcount + 1;
          }
          else
          {
            new = new - IT_SUPER_SHOTGUN;
            leave = TRUE;
          }
        }
        
        if (self.items & IT_SUPER_NAILGUN)
        {
          if (!(other.items & IT_SUPER_NAILGUN))
          {
            self.items = self.items - IT_SUPER_NAILGUN;
            takenfrom = TRUE;
            self.netname = "Super Nailgun";
            weaponcount = weaponcount + 1;
          }
          else
          {
            new = new - IT_SUPER_NAILGUN;
            leave = TRUE;
          }
        }
        
        if (self.items & IT_GRENADE_LAUNCHER)
        {
          if (!(other.items & IT_GRENADE_LAUNCHER))
          {
            self.items = self.items - IT_GRENADE_LAUNCHER;
            takenfrom = TRUE;
            self.netname = "Grenade Launcher";
            weaponcount = weaponcount + 1;
          }
          else
          {
            new = new - IT_GRENADE_LAUNCHER;
            leave = TRUE;
          }
        }
        
        if (self.items & IT_PROXIMITY_GUN)
        {
          if (!(other.items & IT_PROXIMITY_GUN))
          {
            self.items = self.items - IT_PROXIMITY_GUN;
            takenfrom = TRUE;
            self.netname = "Proximity Gun";
            weaponcount = weaponcount + 1;
          }
          else
          {
            new = new - IT_PROXIMITY_GUN;
            leave = TRUE;
          }
        }
        
        if (self.items & IT_ROCKET_LAUNCHER)
        {
          if (!(other.items & IT_ROCKET_LAUNCHER))
          {
            self.items = self.items - IT_ROCKET_LAUNCHER;
            takenfrom = TRUE;
            self.netname = "Rocket Launcher";
            weaponcount = weaponcount + 1;
          }
          else
          {
            new = new - IT_ROCKET_LAUNCHER;
            leave = TRUE;
          }
        }
        
        if (self.items & IT_LIGHTNING)
        {
          if (!(other.items & IT_LIGHTNING))
          {
            self.items = self.items - IT_LIGHTNING;
            takenfrom = TRUE;
            self.netname = "Thunderbolt";
            weaponcount = weaponcount + 1;
          }
          else
          {
            new = new - IT_LIGHTNING;
            leave = TRUE;
          }
        }
        
        if (self.items & IT_LASER_CANNON)
        {
          if (!(other.items & IT_LASER_CANNON))
          {
            self.items = self.items - IT_LASER_CANNON;
            takenfrom = TRUE;
            self.netname = "Laser Cannon";
            weaponcount = weaponcount + 1;
          }
          else
          {
            new = new - IT_LASER_CANNON;
            leave = TRUE;
          }
        }
        
        if (self.items & IT_MJOLNIR)
        {
          if (!(other.items & IT_MJOLNIR) && !(other.classname == "monster_gremlin"))
          {
            self.items = self.items - IT_MJOLNIR;
            takenfrom = TRUE;
            self.netname = "Mjolnir";
            weaponcount = weaponcount + 1;
          }
          else
          {
            new = new - IT_MJOLNIR;
            leave = TRUE;
          }
        }
        
        other.items = other.items | new; //Ry: Add weapons here so I can set the var for later
        
        if (weaponcount > 1)
        {
          self.netname = "weapons";
          new = other.weapon;
        }
        else if (weaponcount == 0)
          new = other.weapon;
        
      }
      else
        new = other.weapon;
    }
  }
  else
		new = other.weapon;
	old = other.weapon; //Ry: Making use of this var now, since it wasn't even used before
  
  other.items = other.items | new;
  
  if (!coop) //Ry: Normal behavior for SP and DM, just with the new vars
  {
    take_shells = self.ammo_shells;
    other.ammo_shells = other.ammo_shells + self.ammo_shells;
    take_nails = self.ammo_nails;
    other.ammo_nails = other.ammo_nails + self.ammo_nails;
    take_rockets = self.ammo_rockets;
    other.ammo_rockets = other.ammo_rockets + self.ammo_rockets;
    take_cells = self.ammo_cells;
    other.ammo_cells = other.ammo_cells + self.ammo_cells;
    takenfrom = TRUE;
  }
  else //Ry: In Co-op, only take what you need from a backpack
  {

    if (fullpick)
    {
      take_shells = 100 - other.ammo_shells; //Ry: How much ammo of each the player can take
      take_nails = 200 - other.ammo_nails;
      take_rockets = 100 - other.ammo_rockets;
      take_cells = 100 - other.ammo_cells;
    }
    else //Ry: Non-owner players will only take spawn amounts of ammo
    {
      
      if (other.ammo_shells < 25)
        take_shells = 25 - other.ammo_shells;
      else
        take_shells = 0;
      
      if ( ((other.items & IT_NAILGUN) || (other.items & IT_SUPER_NAILGUN)) && (other.ammo_nails < 30) )
        take_nails = 30 - other.ammo_nails;
      else
        take_nails = 0;
      
      if ( ((other.items & IT_ROCKET_LAUNCHER) || (other.items & IT_GRENADE_LAUNCHER) || (other.items & IT_PROXIMITY_GUN)) && (other.ammo_rockets < 5) )
        take_rockets = 5 - other.ammo_rockets;
      else
        take_rockets = 0;
      
      if ( ((other.items & IT_LIGHTNING) || (other.items & IT_LASER_CANNON) || (other.items & IT_MJOLNIR)) && (other.ammo_cells < 15) )
        take_cells = 15 - other.ammo_cells;
      else
        take_cells = 0;
      
    }
    
    if (self.ammo_shells > 0)
    {
      if (take_shells > 0)
      {
        takenfrom = TRUE;
        if (take_shells >= self.ammo_shells) //Ry: Higher capacity than given ammo
        {
          take_shells = self.ammo_shells;
          other.ammo_shells = other.ammo_shells + self.ammo_shells;
          self.ammo_shells = 0;
        }
        else //Ry: Can't carry all of it
        {
          other.ammo_shells = other.ammo_shells + take_shells;
          self.ammo_shells = self.ammo_shells - take_shells;
          leave = TRUE;
        }
      }
      else
        leave = TRUE;
    }
    else
      take_shells = 0;
    
    if (self.ammo_nails > 0)
    {
      if (take_nails > 0)
      {
        takenfrom = TRUE;
        if (take_nails >= self.ammo_nails) //Ry: Higher capacity than given ammo
        {
          take_nails = self.ammo_nails;
          other.ammo_nails = other.ammo_nails + self.ammo_nails;
          self.ammo_nails = 0;
        }
        else //Ry: Can't carry all of it
        {
          other.ammo_nails = other.ammo_nails + take_nails;
          self.ammo_nails = self.ammo_nails - take_nails;
          leave = TRUE;
        }
      }
      else
        leave = TRUE;
    }
    else
      take_nails = 0;
    
    if (self.ammo_rockets > 0)
    {
      if (take_rockets > 0)
      {
        takenfrom = TRUE;
        if (take_rockets >= self.ammo_rockets) //Ry: Higher capacity than given ammo
        {
          take_rockets = self.ammo_rockets;
          other.ammo_rockets = other.ammo_rockets + self.ammo_rockets;
          self.ammo_rockets = 0;
        }
        else //Ry: Can't carry all of it
        {
          other.ammo_rockets = other.ammo_rockets + take_rockets;
          self.ammo_rockets = self.ammo_rockets - take_rockets;
          leave = TRUE;
        }
      }
      else
        leave = TRUE;
    }
    else
      take_rockets = 0;
    
    if (self.ammo_cells > 0)
    {
      if (take_cells > 0)
      {
        takenfrom = TRUE;
        if (take_cells >= self.ammo_cells) //Ry: Higher capacity than given ammo
        {
          take_cells = self.ammo_cells;
          other.ammo_cells = other.ammo_cells + self.ammo_cells;
          self.ammo_cells = 0;
        }
        else //Ry: Can't carry all of it
        {
          other.ammo_cells = other.ammo_cells + take_cells;
          self.ammo_cells = self.ammo_cells - take_cells;
          leave = TRUE;
        }
      }
      else
        leave = TRUE;
    }
    else
      take_cells = 0;
    
  }
  
  if ( fullpick && (other == self.owner) ) //Ry: Unset owner once they run over the backpack (even if they don't collect anything)
  {
    self.owner = entity_null;
    //self.ownername = string_null;
    self.effects = 0;
    self.nextthink = time + 120;
    self.think = SUB_Remove;
  }
  
  if (!takenfrom) //Ry: Break if nothing was taken from the backpack
    return;
    
  if (other.classname == "player") //Ry: Don't run on Gremlins, moved weapon message down here, and merged
  {
    acount = 0;
    sprint (other, "You get ");

    if (!(self.netname == ""))
    {
      acount = 1;
      sprint (other, "the ");
      sprint (other, self.netname);
      self.netname = "";
    }
    
    if (take_shells) //Ry: Now using new values for these
    {
      if (acount)
        sprint(other, ", ");
      acount = 1;
      s = ftos(take_shells);
      sprint (other, s);
      sprint (other, " shells");
    }
    if (take_nails)
    {
      if (acount)
        sprint(other, ", ");
      acount = 1;
      s = ftos(take_nails);
      sprint (other, s);
      sprint (other, " nails");
    }
    if (take_rockets)
    {
      if (acount)
        sprint(other, ", ");
      acount = 1;
      s = ftos(take_rockets);
      sprint (other, s);
      sprint (other, " rockets");
    }
    if (take_cells)
    {
      if (acount)
        sprint(other, ", ");
      acount = 1;
      s = ftos(take_cells);
      sprint (other, s);
      sprint (other, " cells");
    }
    
    sprint (other, "\n");
    stuffcmd (other, "bf\n");
    
    //sprint (other, ftos(self.ammo_shells) );
    //sprint (other, " " );
    //sprint (other, ftos(self.ammo_nails) );
    //sprint (other, " " );
    //sprint (other, ftos(self.ammo_rockets) );
    //sprint (other, " " );
    //sprint (other, ftos(self.ammo_cells) );
    //sprint (other, "\n" );
  }
// backpack touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);

  bound_other_ammo ();

  if (leave == TRUE) //Ry: Leave the backpack if ammo remains
    self.lastfragtime = time + 2; //Ry: Next time backpack can be picked
  else
    remove(self);
	self = other;

// change to the weapon
  if (!deathmatch)
    self.weapon = new;
  else
    Deathmatch_Weapon (old, new);
  
  if (self.weapon == old || self.classname == "monster_gremlin") //Ry: Actually check if the weapon changed instead of always resetting weapon
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
  
  //if (dropall && coop && (self.flags & FL_CLIENT)) //Ry: Only when disconnecting (Obsolete with players being given all weapons)
  //  backweaps = self.items - (self.items & (IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD | IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS | IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3 | IT_AXE | IT_SHOTGUN) );
  
  if (!dropall && coop && (self.flags & FL_CLIENT)) //Ry: Players in Co-op will be given a minimum amount of ammo on respawn, which is also taken away from the backpack
  {
    
    if (self.ammo_shells > 25)
      backammo_shells = self.ammo_shells - 25;
    else
      backammo_shells = 0;
    //self.ammo_shells = 25;
    
    if ( self.items & (IT_NAILGUN|IT_SUPER_NAILGUN) )
    {
      if (self.ammo_nails > 30)
        backammo_nails = self.ammo_nails - 30;
      else
        backammo_nails = 0;
      //self.ammo_nails = 30;
    }
    else
    {
      backammo_nails = self.ammo_nails;
      //self.ammo_nails = 0;
    }
    
    if ( self.items & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER|IT_PROXIMITY_GUN) )
    {
      if (self.ammo_rockets > 5)
        backammo_rockets = self.ammo_rockets - 5;
      else
        backammo_rockets = 0;
      //self.ammo_rockets = 5;
    }
    else
    {
      backammo_rockets = self.ammo_rockets;
      //self.ammo_rockets = 0;
    }
    
    if ( self.items & (IT_LIGHTNING|IT_LASER_CANNON|IT_MJOLNIR) )
    {
      if (self.ammo_cells > 15)
        backammo_cells = self.ammo_cells - 15;
      else
        backammo_cells = 0;
      //self.ammo_cells = 15;
    }
    else
    {
      backammo_cells = self.ammo_cells;
      //self.ammo_cells = 0;
    }
    
  }
  else
  {
    backammo_shells = self.ammo_shells;
    backammo_nails = self.ammo_nails;
    backammo_rockets = self.ammo_rockets;
    backammo_cells = self.ammo_cells;
  }

	if (!(backammo_shells + backammo_nails + backammo_rockets + backammo_cells))
		return;	// nothing in it

	item = spawn();
  item.classname = "item_backpack"; //Ry: Actually give this a class name
	item.origin = self.origin - '0 0 24';

  if (deathmatch) //Ry: Normal behavior for DM
  {
    item.items = self.weapon;
     if (item.items == IT_AXE)
      item.netname = "Axe";
    else if (item.items == IT_SHOTGUN)
      item.netname = "Shotgun";
    else if (item.items == IT_SUPER_SHOTGUN)
      item.netname = "Double-barrelled Shotgun";
    else if (item.items == IT_NAILGUN)
      item.netname = "Nailgun";
    else if (item.items == IT_SUPER_NAILGUN)
      item.netname = "Super Nailgun";
    else if (item.items == IT_GRENADE_LAUNCHER)
      item.netname = "Grenade Launcher";
    else if (item.items == IT_ROCKET_LAUNCHER)
      item.netname = "Rocket Launcher";
    else if (item.items == IT_LIGHTNING)
      item.netname = "Thunderbolt";
     else if (item.items == IT_LASER_CANNON)
        item.netname = "Laser Cannon";
     else if (item.items == IT_PROXIMITY_GUN)
        item.netname = "Proximity Gun";
     else if (item.items == IT_MJOLNIR)
        item.netname = "Mjolnir";
     else
      item.netname = "";
  }
  //else if (coop && dropall) //Ry: Drop all weapons when disconnecting in Co-op
  //{
  //  item.items = backweaps;
  //}

	item.ammo_shells = backammo_shells;
	item.ammo_nails = backammo_nails;
	item.ammo_rockets = backammo_rockets;
	item.ammo_cells = backammo_cells;

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
    //item.ownername = self.netname;
    //bprint(item.ownername);
    //bprint(" backpack\n");
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
