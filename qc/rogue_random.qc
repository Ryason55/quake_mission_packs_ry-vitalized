// Random.qc

// =======================================================
// Random Items!
// =======================================================

//Ry: New spawnflags to control what powerups can appear
float RANDOM_NOQUAD = 1;
float RANDOM_NOPENTA = 2;
float RANDOM_NORING = 4;
float RANDOM_NOSHIELD = 8;
float RANDOM_NOBELT = 16;

// equal divisions of 1:
// 5: 0.2, 0.4, 0.6, 0.8, 1
// 6: 0.16, 0.33, 0.48, 0.66, 0.83, 1
// 7: 0.14, 0.28, 0.43, 0.56, 0.71, 0.86, 1
// 8: 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1
void() random_pick_type = 
{
	local float randItem;

  self.flags = FL_ITEM;

  //Ry: Now accounts for new spawnflags
  randItem = random() * self.count;
  
  if (!(self.spawnflags & RANDOM_NOQUAD))
  {
    if (randItem <= 1)
    {
      self.touch = powerup_touch;
      self.noise = "items/damage.wav";
      setmodel (self, "progs/quaddama.mdl");
      self.netname = "Quad Damage";
      self.items = IT_QUAD;
      self.items2 = 0;
      self.mdl = self.model; //Ry: Also track model for dropping
      self.itemeffect = SET_EF_QUAD; //Ry: New light for powerup
      self.classname = "item_artifact_super_damage"; //Ry: Set class name, instead of expecting touch functions to use netname [08-30-2022]
      setsize (self, '-16 -16 -24', '16 16 32'); //Ry: Make sure hitbox size is consistent
      return;
    }
  }
  else
    randItem += 1; //Ry: If an item is excluded, add to this value so odds match up
  
  if (!(self.spawnflags & RANDOM_NOPENTA))
  {
    if (randItem <= 2)
    {
      self.touch = powerup_touch;
      self.noise = "items/protect.wav";
      setmodel (self, "progs/invulner.mdl");
      self.netname = "Pentagram of Protection";
      self.items = IT_INVULNERABILITY;
      self.items2 = 0;
      self.mdl = self.model;
      self.itemeffect = SET_EF_PENTA; //Ry: New light for powerup
      self.classname = "item_artifact_invulnerability";
      setsize (self, '-16 -16 -24', '16 16 32');
      return;
    }
  }
  else
    randItem += 1;
  
  if (!(self.spawnflags & RANDOM_NORING))
  {
    if (randItem <= 3)
    {
      self.touch = powerup_touch;
      self.noise = "items/inv1.wav";
      setmodel (self, "progs/invisibl.mdl");
      self.netname = "Ring of Shadows";
      self.items = IT_INVISIBILITY;
      self.items2 = 0;
      self.mdl = self.model;
      self.itemeffect = 0;
      self.classname = "item_artifact_invisibility";
      setsize (self, '-16 -16 -24', '16 16 32');
      return;
    }
  }
  else
    randItem += 1;

  if (!(self.spawnflags & RANDOM_NOSHIELD))
  {
    if (randItem <= 4)
    {
      self.touch = newitems_touch;
      self.noise = "shield/pickup.wav";
      setmodel (self, "progs/shield.mdl");
      self.netname = "Power Shield";
      self.items = 0;
      self.items2 = IT2_SHIELD;
      self.mdl = self.model;
      self.itemeffect = 0;
      self.classname = "item_powerup_shield";
      setsize (self, '-16 -16 -24', '16 16 32');
      return;
    }
  }

  if (!(self.spawnflags & RANDOM_NOBELT))
  {
    self.touch = newitems_touch;
    self.noise = "belt/pickup.wav";
    setmodel (self, "progs/beltup.mdl");
    self.netname = "Anti-Grav Belt";
    self.items = 0;
    self.items2 = IT2_ANTIGRAV;
    self.mdl = self.model;
    self.itemeffect = 0;
    self.classname = "item_powerup_belt";
    setsize (self, '-16 -16 -24', '16 16 32');
    return;
  }

  dprint("item_random_powerup: No new powerup was selected!\n");
};

/*QUAKED item_random_powerup (0 .5 .8) (-16 -16 -24) (16 16 32)
The Random Box!

Contains a random powerup.
*/
void() item_random_powerup =
{
	if (!deathmatch)
	{
		remove(self);
		return;
	}

  self.count = 0;

	// Precache the lot of it....
  //Ry: Added spawnflags that exclude powerups [10-04-2022]
  if (!(self.spawnflags & RANDOM_NOQUAD))
  {
    precache_model ("progs/quaddama.mdl");
    precache_sound ("items/damage.wav");
    precache_sound ("items/damage2.wav");
    precache_sound ("items/damage3.wav");
    self.count += 1;
  }
  if (!(self.spawnflags & RANDOM_NOPENTA))
  {
    precache_model ("progs/invulner.mdl");
    precache_sound ("items/protect.wav");
    precache_sound ("items/protect2.wav");
    precache_sound ("items/protect3.wav");
    self.count += 1;
  }
  if (!(self.spawnflags & RANDOM_NORING))
  {
    precache_model ("progs/invisibl.mdl");
    precache_sound ("items/inv1.wav");
    precache_sound ("items/inv2.wav");
    precache_sound ("items/inv3.wav");
    self.count += 1;
  }
  if (!(self.spawnflags & RANDOM_NOSHIELD))
  {
    precache_model ("progs/shield.mdl");
    precache_model ("progs/p_shield.mdl");
    precache_sound ("shield/pickup.wav");
    precache_sound ("shield/hit.wav");
    precache_sound ("shield/fadeout.wav");
    self.count += 1;
  }
  if (!(self.spawnflags & RANDOM_NOBELT))
  {
    precache_model ("progs/beltup.mdl");
    precache_sound ("belt/pickup.wav");
    precache_sound ("belt/use.wav");
    precache_sound ("belt/fadeout.wav");
    self.count += 1;
  }

  if (self.count < 1) //Ry: If all powerups were excluded, just remove self
  {
    remove(self);
    return;
  }

  self.lefty = TRUE; //Ry: Set this to indicate it's the random item [08-30-2022]

	random_pick_type();
	StartItem ();
};

void() random_regen = 
{
	random_pick_type();
	SUB_regen();
};

