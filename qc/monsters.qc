/* ALL MONSTERS SHOULD BE 1 0 0 IN COLOR */

// name =[framenum,	nexttime, nextthink] {code}
// expands to:
// name ()
// {
//		self.frame=framenum;
//		self.nextthink = time + nexttime;
//		self.think = nextthink
//		<code>
// };

/*
================
monster_use

Using a monster makes it angry at the current activator
================
*/
void() monster_use =
{
	if (self.enemy)
		return;
	if (self.health <= 0)
		return;
	if (activator.items & IT_INVISIBILITY)
		return;
	if (activator.flags & FL_NOTARGET)
		return;
	if (activator.classname != "player")
		return;

// delay reaction so if the monster is teleported, its sound is still
// heard
	self.enemy = activator;
	self.nextthink = time + 0.1;
	self.think = FoundTarget;
};

/*
================
monster_death_use

When a mosnter dies, it fires all of its targets with the current
enemy as activator.
================
*/
void() monster_death_use =
{
// fall to ground
	if (self.flags & FL_FLY)
		self.flags = self.flags - FL_FLY;
	if (self.flags & FL_SWIM)
		self.flags = self.flags - FL_SWIM;

	if (cvar("horde") && self.classname != "monster_zombie") //Ry: Horde mode's wave check on monster kill
	{
		remote_wavecheck();
	}

	if (!self.target)
		return;

	activator = self.enemy;
	SUB_UseTargets ();
};


//============================================================================

void() walkmonster_start_go =
{
  self.origin_z = self.origin_z + 1;  // raise off floor a bit
	droptofloor(0,0); // Cataboligne 9.17.3 - fixed this compiler warning

	if (!walkmove(0,0))
	{
		dprint ("walkmonster "); //Ry: Print monster class too [09-15-2022]
    dprint (self.classname);
    dprint (" in wall at: ");
		dprint (vtos(self.origin));
		dprint ("\n");
	}

	self.takedamage = DAMAGE_AIM;

	self.ideal_yaw = self.angles * '0 1 0';
	if (!self.yaw_speed)
		self.yaw_speed = 20;
	self.view_ofs = '0 0 25';
	self.use = monster_use;

	self.flags = self.flags | FL_MONSTER;
  if (!self.category)
    self.category = "monster"; //Ry: For easier searching [09-05-2022]

	if (self.target)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
// this used to be an objerror
		if (self.movetarget.classname == "path_corner")
			self.th_walk ();
		else
			self.pausetime = 99999999;
			self.th_stand ();
	}
	else
	{
		self.pausetime = 99999999;
		self.th_stand ();
	}

  if (self.enemy) //Ry: For when spawned hostile
  {
    activator = self.enemy;
    self.enemy = world;
    monster_use();
  }
  else
  {
    // spread think times so they don't all happen at same time
    self.nextthink = self.nextthink + 0.05 + random()*0.45; //Ry: Minimum amount of time before monster is started, to fix the frozen monster bug
  }
};


void() walkmonster_start =
{
// delay drop to floor to make sure all doors have been spawned
// spread think times so they don't all happen at same time
	self.nextthink = self.nextthink + 0.05 + random()*0.45; //Ry: Minimum amount of time before monster is started, to fix the frozen monster bug
  self.flags = self.flags | FL_MONSTER;
  self.think = walkmonster_start_go;
  total_monsters = total_monsters + 1;
  #ifdef ENGINE_KEX
    self.navcooldowntime = 0;
  #endif
};



void() flymonster_start_go =
{
	self.takedamage = DAMAGE_AIM;

	self.ideal_yaw = self.angles * '0 1 0';
	if (!self.yaw_speed)
		self.yaw_speed = 10;
	self.view_ofs = '0 0 25';
	self.use = monster_use;

	self.flags = self.flags | FL_FLY;
	self.flags = self.flags | FL_MONSTER;
  if (!self.category)
    self.category = "monster"; //Ry: For easier searching [09-05-2022]

	if (!walkmove(0,0))
	{
		dprint ("flymonster "); //Ry: Print monster class too [09-15-2022]
    dprint (self.classname);
    dprint (" in wall at: ");
		dprint (vtos(self.origin));
		dprint ("\n");
	}

	if (self.target)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
// this used to be an objerror
		if (self.movetarget.classname == "path_corner")
			self.th_walk ();
		else
			self.pausetime = 99999999;
			self.th_stand ();
	}
	else
	{
		self.pausetime = 99999999;
		self.th_stand ();
	}

  if (self.enemy) //Ry: For when spawned hostile
  {
    activator = self.enemy;
    self.enemy = world;
    monster_use();
  }
};

void() flymonster_start =
{
// spread think times so they don't all happen at same time
	self.nextthink = self.nextthink + 0.05 + random()*0.45; //Ry: Minimum amount of time before monster is started, to fix the frozen monster bug
  self.flags = self.flags | FL_MONSTER;
  self.think = flymonster_start_go;
  total_monsters = total_monsters + 1;
  #ifdef ENGINE_KEX
    self.navcooldowntime = 0;
  #endif
};


void() swimmonster_start_go =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}

	self.takedamage = DAMAGE_AIM;
//MED
//   total_monsters = total_monsters + 1;

	self.ideal_yaw = self.angles * '0 1 0';
	if (!self.yaw_speed)
		self.yaw_speed = 10;
	self.view_ofs = '0 0 10';
	self.use = monster_use;

	self.flags = self.flags | FL_SWIM;
	self.flags = self.flags | FL_MONSTER;
  if (!self.category)
    self.category = "monster"; //Ry: For easier searching [09-05-2022]

	if (self.target)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
// this used to be an objerror
		self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
		self.th_walk ();
	}
	else
	{
		self.pausetime = 99999999;
		self.th_stand ();
	}

  if (self.enemy) //Ry: For when spawned hostile
  {
    activator = self.enemy;
    self.enemy = world;
    monster_use();
  }
  else
  {
    // spread think times so they don't all happen at same time
    self.nextthink = self.nextthink + 0.05 + random()*0.45; //Ry: Minimum amount of time before monster is started, to fix the frozen monster bug
  }
};

void() swimmonster_start =
{
// spread think times so they don't all happen at same time
  self.flags = self.flags | FL_MONSTER;
  self.nextthink = self.nextthink + 0.05 + random()*0.45; //Ry: Minimum amount of time before monster is started, to fix the frozen monster bug
	self.think = swimmonster_start_go;
  total_monsters = total_monsters + 1;
  #ifdef ENGINE_KEX
    self.navcooldowntime = 0;
  #endif
};
