//=====================================================================
//
// Spawning Functions (Hipnotic)
//
//=====================================================================



//========================
//  Subs added by Ryason
//========================

void() spawn_use;
void() spawn_think

void() spawn_warning = //Ry: Message warning about the incoming spawn
{
  if (self.prespawnmessage)
  {
    sound (self, CHAN_AUTO, "misc/talk.wav", 1, ATTN_NONE);
    bprint(self.prespawnmessage);
    bprint("\n");
  }
  self.think = spawn_use;
  self.nextthink = time + 10;
}

void() AutoSpawnSetup =
{
  if ( deathmatch && !self.targetname && (self.autospawndelay > 0) )
  {
    if ((self.autospawndelay >= 30) && self.prespawnmessage)
    {
      self.think = spawn_warning;
      self.nextthink = time + (self.autospawndelay - 10);
    }
    else
    {
      self.think = spawn_use;
      self.nextthink = time + self.autospawndelay;
    }
  }
}

void() waitforspawneedeath_think = //Ry: Wait for the last spawnee to die before counting down for the next one
{
  if (self.lastspawnee.health <= 0)
  {
    AutoSpawnSetup();
  }
  else
    self.nextthink = time + 1;
}

void() spawn_touch = //Ry: Delay spawn if a player is touching the spawner (only Horn-related ones)
{
  if (other.flags & FL_CLIENT)
  {
    self.delay = time + 0.1;
  }
}

void() spawn_firstthink = //Ry: To be called after everything is initialized
{
  dprint("Spawner for ");
  dprint(self.spawnmaster.classname);
  
  
  local entity ent = find(world, target, self.targetname); //Ry: If a horn targets this spawner, set it up as a touchfield to prevent the spawn if a player is in the area, and decrement monster count
  if (ent.classname == "item_hornofconjuring")
  {
    dprint(", which will be charmed");
    self.charmed = TRUE;
    self.solid = SOLID_TRIGGER;
    setsize (self, self.spawnmaster.mins - '4 4 4', self.spawnmaster.maxs + '4 4 4');
    self.touch = spawn_touch;
    if (!self.spawnmulti)
      total_monsters = total_monsters - 1;
  }
  dprint("\n");
   
  AutoSpawnSetup(); //Ry: Set up auto-spawner
}

void(entity tempself, void() spawnfunc, string spawnclass) spawn_storemonster = //Ry: Separated out from the main entity function
{
  // spawn the new entity
  self = spawn();
  // copy over everything
  SUB_CopyEntity(tempself,self);
  //self.spawnfunction = monster_demon1;
  //self.spawnclassname = "monster_demon1";
  self.classname = spawnclass;

  // call the named spawn function
  spawnfunc();

  self.spawnmodel = self.model;
  self.spawnmins = self.mins;
  self.spawnmaxs = self.maxs;
  setmodel (self, "");
  self.model = "";
  setsize (self, self.spawnmins, self.spawnmaxs);
  //save off solid flag
  self.spawnsolidtype = self.solid;
  self.solid = SOLID_NOT;
  self.spawnmovetype = self.movetype; //Ry: Track movetype now
  if (tempself.static) //Ry: No Gravity
    self.movetype = MOVETYPE_NONE;
  //save off think func and
  //get rid of his thinking
  self.spawnthink = self.think;
  self.think = spawn_think;
  self.nextthink = time + 1;

  if (self.conjoinedentity) //Ry: This is used for Armagon
  {
    self.conjoinedentity.spawnmodel = self.conjoinedentity.model;
    setmodel (self.conjoinedentity, "");
    self.conjoinedentity.model = "";
    self.conjoinedentity.spawnthink = self.conjoinedentity.think;
    self.conjoinedentity.think = spawn_think;
    self.conjoinedentity.nextthink = time + 1;
    self.conjoinedentity.spawnmovetype = self.conjoinedentity.movetype;
    if (tempself.static) //Ry: No Gravity
      self.conjoinedentity.movetype = MOVETYPE_NONE;
  }
}

//===================
//  End of new subs
//===================



//================
//
// spawn_think
//
//================

void() spawn_think =
   {
   self.think = spawn_think;
   self.nextthink = time + 1;
   };

//================
//
// spawn_use
//
//================

void() spawn_use =
{
  local entity spawnentity;
  local entity spawnentity2;

  if (horn_active) //Ry: Have the spawner remember these in case the spawn has to be delayed
  {
    self.charmed = TRUE;
    self.charmer = horn_charmer;
    self.empathy_item = horn_item;
    self.empathy_item.count = self.empathy_item.count + 1; //Ry: Increment summoned monster count on Horn
  }
  if (time < self.delay) //Ry: Delay the spawn if the spawner is blocked by a player (For Horn of Conjuring monsters)
  {
    self.think = spawn_use;
    self.nextthink = time + 0.1;
    return;
  }

  if (self.spawnmessage)
  {
    sound (self, CHAN_AUTO, "misc/trigger1.wav", 1, ATTN_NONE);
    bprint(self.spawnmessage);
    bprint("\n");
  }
  if (self.autospawndelay && self.target) //Ry: Autospawners will trigger other entities, so only one in a set needs to be set up
  {
    SUB_UseTargets();
  }

  if ((self.spawnmulti == 1) || (self.charmed))
  {
    // spawn the new entity
    spawnentity = spawn();
    // copy the master mold
    SUB_CopyEntity(self.spawnmaster,spawnentity);
  }
  else
  {
    spawnentity = self.spawnmaster;
  }

  // restore the model
  spawnentity.model = spawnentity.spawnmodel;
  //restore solid flag
  spawnentity.solid = spawnentity.spawnsolidtype;
  //restore thinking function
  spawnentity.think = spawnentity.spawnthink;
  if (spawnentity.think) //Ry: Think immediately
    spawnentity.nextthink = time;
  setmodel (spawnentity, spawnentity.model);
  //setorigin (spawnentity, spawnentity.origin);

  spawnentity.mins = spawnentity.spawnmins;
  spawnentity.maxs = spawnentity.spawnmaxs;
  if (self.spawnmaster.spawnmovetype) //Ry: Restore movetype
    spawnentity.movetype = self.spawnmaster.spawnmovetype;
  setsize (spawnentity, spawnentity.mins, spawnentity.maxs);

  if (self.spawnmaster.conjoinedentity) //Ry: For Armagon
  {
    if ((self.spawnmulti == 1) || (self.charmed))
    {
      // spawn the new entity
      spawnentity2 = spawn();
      // copy the master mold
      SUB_CopyEntity(self.spawnmaster.conjoinedentity,spawnentity2);
    }
    else
    {
      spawnentity2 = self.spawnmaster.conjoinedentity;
    }
    //spawnentity2.origin = self.spawnmaster.origin;
    //spawnentity2.origin = spawnentity2.origin - '0 0 64';
    spawnentity2.think = self.spawnmaster.conjoinedentity.spawnthink;
    if (spawnentity2.think) //Ry: Think immediately
      spawnentity2.nextthink = time;
    spawnentity2.model = spawnentity2.spawnmodel;
    setmodel (spawnentity2, spawnentity2.model);
    //setorigin (spawnentity2, spawnentity2.origin);
    
    if (self.spawnmaster.conjoinedentity.spawnmovetype) //Ry: Restore movetype
      spawnentity2.movetype = self.spawnmaster.conjoinedentity.spawnmovetype;

    spawnentity.conjoinedentity = spawnentity2;
    spawnentity2.conjoinedentity = spawnentity;
  }

  if (spawnentity.classname == "monster_armagon") //Ry: Reset boss damage tracking
  {
    local entity e;
    for (e = find(world, classname, "player") ; e ; e = find(e, classname, "player") )
      e.bossdamage = 0;
  }

  // spawn the teleport effect
  if (self.spawnsilent == 0)
    spawn_tfog (spawnentity.origin);
//  horn_active = 0;
//  horn_charmer = find( world, classname, "player" );
  // call spawnentity think function
  if (self.charmed)
  {
    self.charmer.charmedmonsters += 1; //Ry: Increment number of charmed monsters
    spawnentity.charmer = self.charmer;
    spawnentity.charmed = 1;
    spawnentity.empathy_item = self.empathy_item; //Ry: Horn that summoned the monster is stored here
    spawnentity.team = self.charmer.team; //Ry: Assign the charmed monster the same team as the charmer for bots
    //dprint("Assigned spawned monster to team ");
    //dprint(ftos(self.charmer.team));
    //dprint("\n");
  }

  // check to see if it is a monster
  if (spawnentity.flags & FL_MONSTER)
  {
    if (self.spawnmulti && !self.charmed)
    {
      total_monsters = total_monsters + 1;
      WriteByte (MSG_BROADCAST, SVC_UPDATESTAT);
      WriteByte (MSG_BROADCAST, STAT_TOTALMONSTERS);
      WriteLong (MSG_BROADCAST, total_monsters);
    }
    // spawn the telefrag effect
    spawn_tdeath_fast(spawnentity.origin, spawnentity); //Ry: Actually spawn the telefrag effect (It was originally commented out)
    if (self.charmed && !deathmatch) //Ry: Disable the visual charmed effect in DM
    {
      spawnentity.effects = spawnentity.effects | EF_DIMLIGHT;
    }
    if (self.spawnhostile && !self.charmed && activator && activator.health > 0 && activator.team > 0) //Ry: Setting for spawning hostile
    {
      spawnentity.enemy = activator;
    }
  }
  if ((self.spawnmulti == 0) && (self.charmed == 0))
  {
    remove(self);
  }
  else if (self.autospawndelay && self.spawnmulti && (spawnentity.flags & FL_MONSTER)) //Ry: If auto-spawner, wait for spawnee to die before auto-spawning another (currently only set up properly for a single enemy)
  {
    self.lastspawnee = spawnentity;
    self.think = waitforspawneedeath_think;
    self.nextthink = time + 1;
  }

  if (self.charmed)
  {
    self.charmed = FALSE; //Ry: Clear these for next activation
    self.charmer = entity_null;
    self.empathy_item = entity_null;
  }

};

//================
//
// func_spawn
//
//================
/*QUAKED func_spawn (0 .5 .8) (-32 -32 -24) (32 32 64) big/ambush megahealth
This will spawn a thing upon being used. The thing that
is spawned depends upon the value of "spawnfunction".
"spawnclassname" should contain the same value as "spawnfunction".
If "spawnfunction" is unspecified a random monster is chosen.
The angles, target and all flags are passed on
Think of it like setting up a normal entity.
"spawnsilent" set this to 1 if you want a silent spawn.
"spawnmulti" set this to 1 if you want this spawn to be reoccuring.
*/

void() func_spawn =
{
	if (!EntityValidForMode(FALSE,TRUE)) //Ry: New function to handle func_spawn and horde mode
	{
		remove(self);
		return;
	}
  local entity tempself;
  local entity monster;
  local float tempskill;
  local float temptotal_monsters;

  hipnoticmap = TRUE; //Ry: Map has Hipnotic entity

  if (self.autospawndelay) //Ry: Precache sounds for new auto spawner
  {
    precache_sound ("misc/talk.wav");
    precache_sound ("misc/trigger1.wav");
  }

  tempskill = skill; //Ry: Set skill to Hard for DM spawns
  if (deathmatch)
    skill = 2;

  tempself = self;
  initspawner = TRUE; //Ry: Use this instead of changing the DM var

  // save off monster count so it doesn't get f'ed up
  temptotal_monsters = total_monsters;

  if (!self.spawnfunction)
  {
    local float spawnchance;
    spawnchance = random();
    monster = tempself;

    if (hip_rebalance) //Ry: New potential spawns
    {
      // spawn ogre (50%)
      spawn_storemonster(tempself,monster_ogre,"monster_ogre");
      if (spawnchance<0.5 && monster==tempself)
        monster = self;

      // spawn fiend (45%)
      spawn_storemonster(tempself,monster_demon1,"monster_demon1");
      if (spawnchance<0.95 && monster==tempself)
        monster = self;

      // spawn shambler (5%)
      spawn_storemonster(tempself,monster_shambler,"monster_shambler");
      if (monster==tempself)
        monster = self;
    }
    else //Ry: Original potential spawns
    {
      // spawn dog (50%)
      spawn_storemonster(tempself,monster_dog,"monster_dog");
      if (spawnchance<0.5 && monster==tempself)
        monster = self;

      // spawn ogre (30%)
      spawn_storemonster(tempself,monster_ogre,"monster_ogre");
      if (spawnchance<0.8 && monster==tempself)
        monster = self;

      // spawn fiend (12%)
      spawn_storemonster(tempself,monster_demon1,"monster_demon1");
      if (spawnchance<0.92 && monster==tempself)
        monster = self;

      // spawn zombie (5%)
      spawn_storemonster(tempself,monster_zombie,"monster_zombie");
      if (spawnchance<0.97 && monster==tempself)
        monster = self;

      // spawn shambler (3%)
      spawn_storemonster(tempself,monster_shambler,"monster_shambler");
      if (monster==tempself)
        monster = self;
    }
  }
  else
  {
    if (self.spawnclassname == string_null)
      objerror("No spawnclassname defined");
    spawn_storemonster(tempself,self.spawnfunction,self.spawnclassname);
    monster = self;
  }

  self = tempself;

  // make sure monster count is correct
  if ( self.spawnmulti || !(monster.flags & FL_MONSTER) )
    total_monsters = temptotal_monsters;
  else
    total_monsters = temptotal_monsters + 1;

  initspawner = FALSE;
  skill = tempskill; //Ry: Put skill back
  
  self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
  setmodel (self, self.model);  // set size and link into world
  self.use = spawn_use;
  self.spawnmaster = monster;
  self.solid = SOLID_NOT;
  
  self.nextthink = time + 0.2;
  self.think = spawn_firstthink;
};

//================
//
// func_spawn_small
//
//================
/*QUAKED func_spawn_small (0 .5 .8) (-16 -16 -24) (16 16 40) big/ambush megahealth
This will spawn a thing upon being used. The thing that
is spawned depends upon the value of "spawnfunction".
"spawnclassname" should contain the same value as "spawnfunction".
If "spawnfunction" is unspecified a random monster is chosen.
The angles, target and all flags are passed on
Think of it like setting up a normal entity.
"spawnsilent" set this to 1 if you want a silent spawn.
"spawnmulti" set this to 1 if you want this spawn to be reoccuring.
*/

void() func_spawn_small =
   {
   func_spawn();
   };
