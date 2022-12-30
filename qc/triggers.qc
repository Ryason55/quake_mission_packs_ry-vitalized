void() trigger_reactivate =
{
	self.solid = SOLID_TRIGGER;
};

//=============================================================================

float	SPAWNFLAG_NOMESSAGE = 1;
float	SPAWNFLAG_NOTOUCH = 1;
float	SPAWNFLAG_ALLOWMONSTERS = 2; //Ry: New flag

// the wait time has passed, so set back up for another activation
void() multi_wait =
{
	if (self.max_health)
	{
		self.health = self.max_health;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
	}
};


// the trigger was just touched/killed/used
// self.enemy should be set to the activator so it can be held through a delay
// so wait for the delay time before firing
void() multi_trigger =
{
	if (self.nextthink > time)
	{
		return;		// allready been triggered
	}

	if (self.classname == "trigger_secret")
	{
		if (self.enemy.classname != "player")
			return;
		found_secrets = found_secrets + 1;
		WriteByte (MSG_ALL, SVC_FOUNDSECRET);

    #ifdef ENGINE_KEX
      msg_entity = self.enemy; //Ry: Remaster secret achievement
      WriteByte(MSG_ONE, SVC_ACHIEVEMENT);
      WriteString(MSG_ONE, "ACH_FIND_SECRET");
    #endif
	}

  #ifdef ENGINE_KEX
    if ((self.enemy.classname == "player") && (world.model == "maps/hip3m1.bsp") && (self.message == "$map_not_supposed_be_here")) //Ry: Remaster HIP3M1 ledge secret achievement
    {
      msg_entity = self.enemy;
      WriteByte(MSG_ONE, SVC_ACHIEVEMENT);
      WriteString(MSG_ONE, "ACH_FIND_SUPPOSED_BE_HERE");
    }
  #endif

	if (self.noise)
		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

// don't trigger again until reset
	self.takedamage = DAMAGE_NO;

	activator = self.enemy;

	SUB_UseTargets();

	if (self.wait > 0)
	{
		self.think = multi_wait;
		self.nextthink = time + self.wait;
	}
	else
	{	// we can't just remove (self) here, because this is a touch function
		// called wheil C code is looping through area links...
		self.touch = SUB_Null;
		self.nextthink = time + 0.1;
		self.think = SUB_Remove;
	}
//MED 12/01/96 added cnt stuff
   if (self.cnt > 0)
      {
      self.cnt = self.cnt - 1;
      if (self.cnt == 0)
         {
         self.touch = SUB_Null;
         self.nextthink = time + 0.1;
         self.think = SUB_Remove;
         }
      }

  #ifdef ENGINE_KEX
    if (((activator.classname == "player") && (world.model == "maps/e2m3.bsp")) && (self.message == "$map_dopefish")) //Ry: ID1 Dopefish achievement
    {
      msg_entity = activator;
      WriteByte(MSG_ONE, SVC_ACHIEVEMENT);
      WriteString(MSG_ONE, "ACH_FIND_DOPEFISH");
    }
  #endif

};

void() multi_killed =
{
	self.enemy = damage_attacker;
	multi_trigger();
};

void() multi_use =
{
	self.enemy = activator;
	multi_trigger();
};

void() multi_touch =
{
  //Ry: React to cutscene Ranger as well, as well as monsters if the new spawn flag is set
	if ( !( (other.classname == "player") || (other.classname == "monster_decoy") || ((self.spawnflags & SPAWNFLAG_ALLOWMONSTERS) && (other.flags & FL_MONSTER)) ) )
		return;

// if the trigger has an angles field, check player's facing direction
	if (self.movedir != '0 0 0')
	{
		makevectors (other.angles);
		if (v_forward * self.movedir < 0)
			return;		// not facing the right way
	}

	self.enemy = other;
	multi_trigger ();
};

//MED 12/01/96 added count field
/*QUAKED trigger_multiple (.5 .5 .5) ? notouch
Variable sized repeatable trigger.  Must be targeted at one or more entities.  If "health" is set, the trigger must be killed to activate each time.
If "delay" is set, the trigger waits some time after activating before firing.
"wait" : Seconds between triggerings. (.2 default)
"cnt" how many times it can be triggered (infinite default)
If notouch is set, the trigger is only fired by other entities, not by touching.
NOTOUCH has been obsoleted by trigger_relay!
sounds
1)	secret
2)	beep beep
3)	large switch
4)
set "message" to text string
*/
void() trigger_multiple =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;

	if (self.sounds == 1)
	{
		precache_sound ("misc/secret.wav");
		self.noise = "misc/secret.wav";
	}
	else if (self.sounds == 2)
	{
		precache_sound ("misc/talk.wav");
		self.noise = "misc/talk.wav";
	}
	else if (self.sounds == 3)
	{
		precache_sound ("misc/trigger1.wav");
		self.noise = "misc/trigger1.wav";
	}

	if (!self.wait)
		self.wait = 0.2;
	self.use = multi_use;

	InitTrigger ();

	if (self.health)
	{
		if (self.spawnflags & SPAWNFLAG_NOTOUCH)
			objerror ("health and notouch don't make sense\n");
		self.max_health = self.health;
		self.th_die = multi_killed;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
		setorigin (self, self.origin);	// make sure it links into the world
	}
	else
	{
		if ( !(self.spawnflags & SPAWNFLAG_NOTOUCH) )
		{
			self.touch = multi_touch;
      if (coop && (self.classname == "trigger_multiple") && (self.delay < 2) && (self.target)) //Ry: If it's an elevator trigger, add an extra delay in Co-op (Done after everything else has spawned)
      {
        self.think = coopelevatorcheck;
        self.nextthink = time + 0.3;
      }
		}
	}
//MED 12/01/96 added cnt stuff
  if (self.cnt == 0)
    self.cnt = -1;
};


/*QUAKED trigger_once (.5 .5 .5) ? notouch
Variable sized trigger. Triggers once, then removes itself.  You must set the key "target" to the name of another object in the level that has a matching
"targetname".  If "health" is set, the trigger must be killed to activate.
If notouch is set, the trigger is only fired by other entities, not by touching.
if "killtarget" is set, any objects that have a matching "target" will be removed when the trigger is fired.
if "angle" is set, the trigger will only fire when someone is facing the direction of the angle.  Use "360" for an angle of 0.
sounds
1)	secret
2)	beep beep
3)	large switch
4)
set "message" to text string
*/
void() trigger_once =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;

  self.wait = -1;
  if (deathmatch) //Ry: Immediately trigger all one-time triggers in Deathmatch
  {
    self.sounds = 0;
		self.nextthink = time + 1 + random();
		self.think = multi_trigger;
  }
  else
    trigger_multiple();
};

//=============================================================================

/*QUAKED trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.  It can contain killtargets, targets, delays, and messages.
*/
void() trigger_relay =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps [08-01-2022]
    return;
	self.use = SUB_UseTargets;
};


//=============================================================================

/*QUAKED trigger_secret (.5 .5 .5) ?
secret counter trigger
sounds
1)	secret
2)	beep beep
3)
4)
set "message" to text string
*/
void() trigger_secret =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;

	total_secrets = total_secrets + 1;
	self.wait = -1;
	if (!self.message)
		self.message = "You found a secret area!";
	if (!self.sounds)
		self.sounds = 1;

	if (self.sounds == 1)
	{
		precache_sound ("misc/secret.wav");
		self.noise = "misc/secret.wav";
	}
	else if (self.sounds == 2)
	{
		precache_sound ("misc/talk.wav");
		self.noise = "misc/talk.wav";
	}

	trigger_multiple ();
};

//=============================================================================


void() counter_use =
{
	self.count = self.count - 1;
	if (self.count < 0)
		return;

	if (self.count != 0)
	{
		if (activator.classname == "player"
		&& (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
		{
			if (self.count >= 4)
				FilteredCenterPrint (activator, CPRINT_WORLD, "There are more to go...");
			else if (self.count == 3)
				FilteredCenterPrint (activator, CPRINT_WORLD, "Only 3 more to go...");
			else if (self.count == 2)
				FilteredCenterPrint (activator, CPRINT_WORLD, "Only 2 more to go...");
			else
				FilteredCenterPrint (activator, CPRINT_WORLD, "Only 1 more to go...");
		}
		return;
	}

	if (activator.classname == "player"
	&& (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
		FilteredCenterPrint(activator, CPRINT_WORLD, "Sequence completed!");
	self.enemy = activator;
	multi_trigger ();
};

/*QUAKED trigger_counter (.5 .5 .5) ? nomessage
Acts as an intermediary for an action that takes multiple inputs.

If nomessage is not set, t will print "1 more.. " etc when triggered and "sequence complete" when finished.

After the counter has been triggered "count" times (default 2), it will fire all of it's targets and remove itself.
*/
void() trigger_counter =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;

  if (deathmatch) //Ry: Immediately trigger all one-time counters in Deathmatch
  {
    self.think = multi_trigger;
    self.nextthink = time + 1 + random();
  }
  else
  {
    self.wait = -1;
    if (!self.count)
      self.count = 2;

    self.use = counter_use;
  }
};


/*
==============================================================================

TELEPORT TRIGGERS

==============================================================================
*/

float	PLAYER_ONLY	= 1;
float	SILENT = 2;
#ifdef GAME_ROGUE
  float	CTF_ONLY = 4;
#endif

void() play_teleport =
{
	local	float v;
	local	string tmpstr;

	v = random() * 5;
	if (v < 1)
		tmpstr = "misc/r_tele1.wav";
	else if (v < 2)
		tmpstr = "misc/r_tele2.wav";
	else if (v < 3)
		tmpstr = "misc/r_tele3.wav";
	else if (v < 4)
		tmpstr = "misc/r_tele4.wav";
	else
		tmpstr = "misc/r_tele5.wav";

	sound (self, CHAN_VOICE, tmpstr, 1, ATTN_NORM);
	remove (self);
};

void(vector org) spawn_tfog =
{
	local entity s = spawn ();
	s.origin = org;
	s.nextthink = time + 0.2;
	s.think = play_teleport;

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_TELEPORT);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
};


void() tdeath_touch =
{
	if (other == self.owner)
		return;

// frag anyone who teleports in on top of an invincible player
	if (other.important) //Ry: This uses it's own setting now [08-08-2022]
	{
		if (other.invincible_finished > time)
			self.classname = "teledeath2";
		if (!self.owner.important)
		{	// other monsters explode themselves
      #ifdef GAME_HIPNOTIC
      if (!(self.owner.charmed) || self.classname == "teledeath") //Ry: Don't blow up a charmed monster that's spawning in
      #endif
        T_Damage (self.owner, self, self, 50000);
			return;
		}

	}

	if (other.health)
	{
		T_Damage (other, self, self, 50000);
	}
};


void(vector org, entity death_owner) spawn_tdeath =
{
local entity	death;

	death = spawn();
	death.classname = "teledeath";
	death.movetype = MOVETYPE_NONE;
	death.solid = SOLID_TRIGGER;
	death.angles = '0 0 0';
	setsize (death, death_owner.mins - '1 1 1', death_owner.maxs + '1 1 1');
	setorigin (death, org);
	death.touch = tdeath_touch;
	death.nextthink = time + 0.2;
	death.think = SUB_Remove;
	death.owner = death_owner;

	force_retouch = 2;		// make sure even still objects get hit
};

void() teleport_touch =
{
  local entity	t;
  local vector	org;

	if (self.targetname)
	{
		if (self.nextthink < time)
		{
			return;		// not fired yet
		}
	}

	if (self.spawnflags & PLAYER_ONLY)
	{
		if (other.classname != "player")
			return;
	}

// only teleport living creatures
	if (other.health <= 0 || other.solid != SOLID_SLIDEBOX)
		return;

	t = find (world, targetname, self.target);
	if (!t) //Ry: Don't abort game if a target can't be found; Fixes the "crash" teleporter at the start of E4M8 [08-22-2022]
  {
    dprint("trigger_teleport couldn't find target\n");
    self.touch = SUB_Null;
    self.think = SUB_Remove;
    self.nextthink = time;
    return;
  }

  #ifndef ENGINE_WINQUAKE
    //Ry: In Horde, do extra checks to make sure the destination is clear
    local entity ent;
    local float srcflg, dstflg;
    if (horde_ent)
    {
      t.mins = other.mins;
      t.maxs = other.maxs;
      srcflg = other.flags & (FL_MONSTER|FL_CLIENT);
      ent = findradius(t.origin,135);
      while (ent)
      {
        //Ry: Don't teleport if there's a telefrag trigger going
        if (ent.classname == "teledeath")
        {
          if (ent.owner != other)
            if (BBoxIntersection(t,ent,4))
              return;
        }
        else if (ent.classname != "monster_zombie") //Ry: Ignore Zombies
        {
          dstflg = ent.flags & (FL_MONSTER|FL_CLIENT);
          //Ry: Clients don't teleport on clients, and Monsters don't teleport on anything
          if (dstflg && ent.health > 0 && dstflg <= srcflg)
            if (BBoxIntersection(t,ent,4))
              return;
        }
        ent = ent.chain;
      }
    }
  #endif

	SUB_UseTargets ();

// put a tfog where the player was
	spawn_tfog (other.origin);

// spawn a tfog flash in front of the destination
	makevectors (t.mangle);
	org = t.origin + 32 * v_forward;

	spawn_tfog (org);
	spawn_tdeath(t.origin, other);

// move the player and lock him down for a little while
	if (!other.health)
	{
		other.origin = t.origin;
		other.velocity = (v_forward * other.velocity_x) + (v_forward * other.velocity_y);
		return;
	}

	setorigin (other, t.origin);
	other.angles = t.mangle;
	if (other.classname == "player")
	{
		other.fixangle = 1;		// turn this way immediately
		other.teleport_time = time + 0.7;
    #ifdef GAME_HIPNOTIC
      other.proxyimmunetime = time + 0.7; //Ry: Have Proxy Bombs ignore the player for a bit after teleporting
    #endif
		if (other.flags & FL_ONGROUND)
			other.flags = other.flags - FL_ONGROUND;
		other.velocity = v_forward * 300;
	}
	other.flags = other.flags - other.flags & FL_ONGROUND;
};

/*QUAKED info_teleport_destination (.5 .5 .5) (-8 -8 -8) (8 8 32)
This is the destination marker for a teleporter.  It should have a "targetname" field with the same value as a teleporter's "target" field.
*/
void() info_teleport_destination =
{
// this does nothing, just serves as a target spot
	self.mangle = self.angles;
	self.angles = '0 0 0';
	self.model = "";
	if (!self.targetname)
  {
    dprint("info_teleport_destination at ");
    dprint(vtos(self.origin));
    dprint(" has no targetname set!\n");
		remove(self);
    return;
  }
	self.origin = self.origin + '0 0 27';
};

void() teleport_use =
{
	self.nextthink = time + 0.2;
	force_retouch = 2;		// make sure even still objects get hit
	self.think = SUB_Null;
};

/*QUAKED trigger_teleport (.5 .5 .5) ? PLAYER_ONLY SILENT
Any object touching this will be transported to the corresponding info_teleport_destination entity. You must set the "target" field, and create an object with a "targetname" field that matches.

If the trigger_teleport has a targetname, it will only teleport entities when it has been fired.
*/
void() trigger_teleport =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;

	local vector o;

  #ifdef GAME_ROGUE
    if (self.spawnflags & CTF_ONLY)
    {
      if (teamplay < TEAM_CTF || teamplay > TEAM_CTF_ALT)
      {
        remove (self);
        return;
      }
    }
  #endif

	InitTrigger ();
	self.touch = teleport_touch;
	// find the destination
	if (!self.target)
  {
    dprint("trigger_teleport at ");
    dprint(vtos( ((self.mins+self.maxs)/2) + self.origin ));
    dprint(" has no target set!\n");
		remove(self);
    return;
  }
	self.use = teleport_use;

	if (!(self.spawnflags & SILENT))
	{
		precache_sound ("ambience/hum1.wav");
		o = (self.mins + self.maxs)*0.5;
		ambientsound (o, "ambience/hum1.wav",0.5 , ATTN_STATIC);
	}
};

/*
==============================================================================

trigger_setskill

==============================================================================
*/

void() trigger_skill_touch =
{
	if (other.classname != "player")
		return;

	cvar_set ("skill", self.message);
  //The following doesn't seem needed currently
  /*if (copper_nightmare) //Ry: Copper Nightmare stuff [07-14-2022]
  {
    local float newhealth;
    local entity player;
    if ((skill < 3) && (cvar("skill") >= 3)) //Ry: To Nightmare
      newhealth = 50;
    else if ((skill >= 3) && (cvar("skill") < 3)) //Ry: From Nightmare
      newhealth = 100;
    if (newhealth)
    {
      player = find(world,classname,"player");
      while (player)
      {
        if (player.health > 0)
          player.health = newhealth;
        player.max_health = newhealth;
        player = find(player,classname,"player");
      }
    }
    skill = cvar("skill");
  }*/
};

/*QUAKED trigger_setskill (.5 .5 .5) ?
sets skill level to the value of "message".
Only used on start map.
*/
void() trigger_setskill =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;

	InitTrigger ();
	self.touch = trigger_skill_touch;
};


/*
==============================================================================

ONLY REGISTERED TRIGGERS

==============================================================================
*/

void() trigger_onlyregistered_touch =
{
	if (other.classname != "player")
		return;
	if (self.attack_finished > time)
		return;

	self.attack_finished = time + 2;
	if (cvar("registered"))
	{
		self.message = "";
		SUB_UseTargets ();
		remove (self);
	}
	else
	{
		if (self.message != "")
		{
			FilteredCenterPrint (other, CPRINT_WORLD, self.message);
			sound (other, CHAN_BODY, "misc/talk.wav", 1, ATTN_NORM);
		}
	}
};

/*QUAKED trigger_onlyregistered (.5 .5 .5) ?
Only fires if playing the registered version, otherwise prints the message
*/
void() trigger_onlyregistered =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;

	precache_sound ("misc/talk.wav");
	InitTrigger ();
	self.touch = trigger_onlyregistered_touch;
};

//============================================================================

//JIM
void( entity ent, float amount ) hurt_setdamage =
   {
   ent.dmg = amount;
   if ( !amount )
      {
      ent.solid = SOLID_NOT;
      }
   else
      {
      ent.solid = SOLID_TRIGGER;
      }
   ent.nextthink = -1;
   };

void() hurt_on =
{
	//self.solid = SOLID_TRIGGER;
	self.nextthink = -1;
};

void() hurt_touch =
{
  if ((time <= self.nextthink - 1) || (time >= self.nextthink)) //Ry: Allow hitting more than one thing at a time
  {
    if ( other.health > 0 && other.takedamage ) //Ry: Check health
    {
      if (!(self.spawnflags & PLAYER_ONLY) || (other.classname == "player")) //Ry: Spawn Flag 1 makes this only affect players
      {
        if (other.classname == "monster_oldone") //Ry: Automatically assign Shub as owner [09-16-2022]
        {
          self.owner = other;
          self.spawnflags |= PLAYER_ONLY;
        }
        T_Damage (other, self, self.owner, self.dmg); //Ry: Damage comes from owner, if one is set [09-16-2022]
        if (time > self.nextthink) //Ry: Only set these once per frame
        {
          self.think = SUB_Null;
          self.nextthink = time + 1;
          //MED 12/01/96 added count stuff
          if (self.cnt > 0)
          {
            self.cnt = self.cnt - 1;
            if (self.cnt == 0)
            {
              //self.touch = SUB_Null;
              self.nextthink = time + 0.1;
              self.think = SUB_Remove;
            }
          }
        }
      }
    }
    force_retouch = 1;
  }

	return;
};

//MED 12/01/96 added count field
/*QUAKED trigger_hurt (.5 .5 .5) ?
Any object touching this will be hurt
set dmg to damage amount
defalt dmg = 5
"cnt" default infinite, how many times to trigger
*/
void() trigger_hurt =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;

  self.netname = "trigger_hurt"; // for bot nav support.
	InitTrigger ();
	self.touch = hurt_touch;
	if (!self.dmg)
		self.dmg = 5;
  //MED 12/01/96 added count stuff
  if (self.cnt == 0)
    self.cnt = -1;
  self.owner = self; //Ry: Set owner as self by default [09-16-2022]
};

//============================================================================

float PUSH_ONCE = 1;
#ifdef GAME_ROGUE
  float PUSH_TOGL = 2;
  float PUSH_ACTIVE = 4;
#else
  float ADDITIVE_PUSH = 2;
  float PUSH_START_OFF = 4;
#endif
float PUSH_ITEMS = 8; //Ry: Ability to push items [07-29-2022]

void() DoPush = //Ry: Separate function for this [07-29-2022]
{
  #ifndef GAME_ROGUE
  if (self.spawnflags & ADDITIVE_PUSH) // yoder add, Jan 28 2021
  {
    other.velocity = other.velocity + (self.speed * self.movedir * 10 * frametime);
    if (self.height) //Ry: Can now define a height [07-29-2022]
      other.velocity_z = other.velocity_z + (self.height * frametime);
  }
  else
  {
  #endif
    other.velocity = self.speed * self.movedir * 10;
    if (self.height) //Ry: Can now define a height [07-29-2022]
      other.velocity_z = self.height;
  #ifndef GAME_ROGUE
  }
  #endif
}

void() trigger_push_touch =
{
  #ifdef GAME_ROGUE
    if (!(self.spawnflags & PUSH_ACTIVE))
      return;
  #endif

  if ((self.spawnflags & PUSH_ITEMS) && (other.flags & FL_ITEM)) //Ry: Allow push triggers to push items with a flag [07-29-2022]
  {
    DoPush();
    return;
  }
  
	// yoder Sept 24 2021 horde merge
	if (horde_ent)
	{
    #ifndef GAME_ROGUE
      if (self.spawnflags & PUSH_START_OFF) // ignore this spawnflag in horde mode
        self.spawnflags-= PUSH_START_OFF;
    #endif
		
		if ((other.classname != "player"))
		{
			if ((other.classname == "item_artifact_invulnerability") || (other.classname == "item_artifact_super_damage"))
				DoPush();
			return;
		}
	}
	
  #ifdef GAME_ROGUE
  if (other.health > 0 || (other.classname == "grenade") || (other.classname == "MiniGrenade") || (other.classname == "MultiGrenade"))
  #else
	if (other.health > 0 || other.classname == "grenade")
  #endif
	{
		if (other.flags & FL_INSHELTER)
      return;

		DoPush();
		if (other.classname == "player")
		{
			if (other.fly_sound < time)
			{
				other.fly_sound = time + 1.5;
				sound (other, CHAN_AUTO, "ambience/windfly.wav", 1, ATTN_NORM);
			}
		}
		if(other.flags & FL_MONSTER) other.flags (-) FL_ONGROUND; //If a monster walks inside a trigger_push, make it fly
	}
	if (self.spawnflags & PUSH_ONCE)
		remove(self);
};

#ifdef GAME_ROGUE
  void() trigger_push_use = 
  {
    if (self.spawnflags & PUSH_ACTIVE)
      self.spawnflags = self.spawnflags - PUSH_ACTIVE;
    else
      self.spawnflags = self.spawnflags + PUSH_ACTIVE;
  };

  /*QUAKED trigger_push (.5 .5 .5) ? PUSH_ONCE PUSH_TOGL PUSH_ACTIVE
  Pushes the player.

  speed: velocity of push. (default 1000)
  */
#else
  /*QUAKED trigger_push (.5 .5 .5) ? PUSH_ONCE
  Pushes the player
  */
#endif
void() trigger_push =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;

  #ifdef GAME_ROGUE
    if (self.spawnflags & PUSH_TOGL)
      self.use = trigger_push_use;
    else
      self.spawnflags = self.spawnflags + PUSH_ACTIVE;
  #endif

	InitTrigger ();
	precache_sound ("ambience/windfly.wav");
	self.touch = trigger_push_touch;
	if (!self.speed)
		self.speed = 1000;
};

//============================================================================

void() trigger_monsterjump_touch =
{
  local float dot;

	if ( other.flags & (FL_MONSTER | FL_FLY | FL_SWIM) != FL_MONSTER )
		return;

  #ifdef GAME_HIPNOTIC
    if ( other.charmed && (!self.charmed) ) //Ry: Charmed monsters ignore these unless specifically set
      return;
  #endif

  if (self.checkdirection) //Ry: Check if monster is moving in roughly the same direction as the trigger
  {
    makevectors(other.angles);
    dot = self.movedir * v_forward;
    if (dot < 0)
      return;
  }

  if ((time < self.wait) && (other.flags & FL_ONGROUND)) //Ry: Don't react if in wait time, unless monster is already in the air [06-30-2022]
    return;

// set XY even if not on ground, so the jump will clear lips
	other.velocity_x = self.movedir_x * self.speed;
	other.velocity_y = self.movedir_y * self.speed;

	if ( !(other.flags & FL_ONGROUND) )
		return;

	other.flags = other.flags - FL_ONGROUND;

  if (self.delay) //Ry: If a delay is set, wait after each activation [06-30-2022]
    self.wait = time + self.delay;

	other.velocity_z = self.height;
//MED 12/01/96 added count stuff
  if (self.cnt>0)
  {
    self.cnt = self.cnt - 1;
    if (self.cnt == 0)
    {
      self.touch = SUB_Null;
      self.nextthink = time + 0.1;
      self.think = SUB_Remove;
    }
  }
};

//MED 12/01/96 added count field
/*QUAKED trigger_monsterjump (.5 .5 .5) ?
Walking monsters that touch this will jump in the direction of the trigger's angle
"speed" default to 200, the speed thrown forward
"height" default to 200, the speed thrown upwards
"cnt" default infinite, how many times to trigger
*/
void() trigger_monsterjump =
{
  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;

	if (!self.speed)
		self.speed = 200;
	if (!self.height)
		self.height = 200;
	if (self.angles == '0 0 0')
		self.angles = '0 360 0';
//MED 12/01/96 added count stuff
  if (self.cnt == 0)
    self.cnt = -1;
  if (self.delay < 0) //Ry: Added handler for setting a delay [06-30-2022]
    self.delay = 0;
	InitTrigger ();
	self.touch = trigger_monsterjump_touch;
};