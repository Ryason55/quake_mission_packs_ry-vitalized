/* Trigger QuickC program
   By Jim Dose'  12/2/96
   Copyright (c)1996 Hipnotic Interactive, Inc.
   All rights reserved.
   Distributed (unsupported) on 3.12.97
*/

float USE_GOLD_KEY = 1;

void() keytrigger_use =
{
  if (activator.classname != "player")
		return;
  if (self.attack_finished > time)
		return;

  self.attack_finished = time + 2;

	if ( !AttemptUnlock() ) //Ry: Global function for this now
		return;

	if (horde_ent) //Ry: Horde mode behavior
		horde_key_spend(self.items);
	else // standard behavior
		activator.items = activator.items - self.items;

  // we can't just remove (self) here, because this is a touch function
  // called while C code is looping through area links...
  self.touch = SUB_Null;
  self.use = SUB_Null;
  self.nextthink = time + 0.1;
  self.think = SUB_Remove;
  self.message = "";

  sound (self, CHAN_ITEM, self.noise4, 1, ATTN_NORM);

  SUB_UseTargets();
};

void() keytrigger_touch =
{
  activator = other;
  keytrigger_use();
};

/*QUAKED trigger_usekey (0 .5 0) ? USE_GOLD_KEY
Variable sized single use trigger that requires a key to trigger targets.  Must be targeted at one or more entities.

"message" is printed when the trigger is touched without having the right key.
*/

void() trigger_usekey =
{
  if (!EntityValidForMode(FALSE,FALSE)) //Ry: For hybrid horde/campaign maps
    return;

  PrepareKeyMechanismSounds(); //Ry: Global function for this now

  if (self.spawnflags & USE_GOLD_KEY)
    self.items = IT_KEY2;
  else
    self.items = IT_KEY1;

  self.use = keytrigger_use;
  self.touch = keytrigger_touch;

	InitTrigger ();
};

void() remove_touch =
   {
   if (other.flags & self.cnt)
      return;
   other.touch = SUB_Null;
   other.model = "";
   remove(self);
//   other.nextthink = time + 0.1;
//   other.think = SUB_Remove;
   };

/*QUAKED trigger_remove (.5 .5 .5) ? ignoremonsters ignoreplayers
Variable sized trigger that removes the thing
that touches it.  Does not affect monsters or
players.
*/
void() trigger_remove =
{
  if (!EntityValidForMode(FALSE,FALSE)) //Ry: For hybrid horde/campaign maps
    return;

  self.cnt = FL_CLIENT|FL_MONSTER;
  if (self.spawnflags & 1)
    self.cnt = self.cnt - FL_MONSTER;
  if (self.spawnflags & 2)
    self.cnt = self.cnt - FL_CLIENT;
  InitTrigger ();
  self.touch = remove_touch;
};
/*
==============================================================================

trigger_setgravity

==============================================================================
*/

void() trigger_gravity_touch =
{
	if (other.classname != "player")
		return;
   if (self.gravity == -1)
      other.gravity = 1.0;
   else
      other.gravity = self.gravity;
};

/*QUAKED trigger_setgravity (.5 .5 .5) ?
set the gravity of a player
"gravity" what to set the players gravity to
 - 0 (default) normal gravity
 - 1 no gravity
 - 2 almost no gravity
 - ...
 - 101 normal gravity
 - 102 slightly higher gravity
 - ...
 - 1000 very high gravity
*/
void() trigger_setgravity =
{
  if (!EntityValidForMode(FALSE,FALSE)) //Ry: For hybrid horde/campaign maps
    return;

	InitTrigger ();
  self.touch = trigger_gravity_touch;
  if (!self.gravity)
  {
    self.gravity = -1;
  }
  else
  {
    self.gravity = ((self.gravity - 1) / 100);
  }
};

void() trigger_command_use =
{
  if ( self.message )
    localcmd( self.message );
};

/*QUAKED trigger_command (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
 When triggered, stuffs a command into the console to allow map
 designers to set server variables.

 "message" is the command to send to the console.
*/

void() trigger_command =
{
  if (!EntityValidForMode(FALSE,FALSE)) //Ry: For hybrid horde/campaign maps
    return;

  self.use = oncount_use;
  self.think = SUB_Null;
};

void() trigger_decoy_touch =
   {
   if (other.classname != "monster_decoy")
      return;
   self.touch = SUB_Null;
   self.nextthink = time + 0.1;
   self.think = SUB_Remove;
   SUB_UseTargets();
   };

/*QUAKED trigger_decoy_use (.5 .5 .5) ?
 only the decoy player can trigger this
 once triggers, all targets are used
*/

void() trigger_decoy_use =
   {
   if (deathmatch)
	{
		remove(self);
		return;
	}
   InitTrigger ();
   self.touch = trigger_decoy_touch;
   };

void() trigger_waterfall_touch =
   {
   // only affect players
   if (!(other.flags & FL_CLIENT))
      {
      return;
      }

   other.velocity = other.velocity + self.movedir;
   other.velocity_x = other.velocity_x + self.count * ( random() - 0.5 );
   other.velocity_y = other.velocity_y + self.count * ( random() - 0.5 );
   };

/*QUAKED trigger_waterfall (.2 .5 .2) ?
 Pushes the player in the direction specified by angles.

 "speed" is the strength of the push (default 50).
 "count" amount of random xy movement to add to velocity (default 100).
*/

void() trigger_waterfall =
{
  if (!EntityValidForMode(FALSE,FALSE)) //Ry: For hybrid horde/campaign maps
    return;

  InitTrigger ();
  self.touch = trigger_waterfall_touch;

  if ( self.count == 0 )
  {
    self.count = 100;
  }

  if ( self.speed == 0 )
  {
    self.movedir = self.movedir * 50;
  }
  else
  {
    self.movedir = self.movedir * self.speed;
  }
};
