// button and multiple button


//Yoder Sept24 Horde Merge
void(float key_item)horde_key_spend;

float BUTTON_KEY_ALWAYS_REQUIRED = 32;


void() button_wait;
void() button_return;

void() button_wait =
{
	self.state = STATE_TOP;
	self.nextthink = self.ltime + self.wait;
	self.think = button_return;
	activator = self.enemy;
	SUB_UseTargets();
	self.frame = 1;			// use alternate textures
};

void() button_done =
{
	self.state = STATE_BOTTOM;
};

void() button_return =
{
	self.state = STATE_DOWN;
	SUB_CalcMove (self.pos1, self.speed, button_done);
	self.frame = 0;			// use normal textures
	if (self.health)
		self.takedamage = DAMAGE_YES;	// can be shot again
};


void() button_blocked =
{	// do nothing, just don't ome all the way back out
};


void() button_fire =
{
	if (self.state == STATE_UP || self.state == STATE_TOP)
		return;

	if(self.items) //Ry: Remaster key button mechanic
	{
		sound (self, CHAN_ITEM, self.noise4, 1, ATTN_NORM);
		if(!(self.spawnflags & BUTTON_KEY_ALWAYS_REQUIRED))
		{
			self.items = 0;
		}
	}

	sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

	self.state = STATE_UP;
	SUB_CalcMove (self.pos2, self.speed, button_wait);
};


void() button_use =
{
	self.enemy = activator;
	button_fire ();
};

void() button_touch =
{
	if (other.classname != "player")
		return;
  
	if(time < self.attack_finished) //Ry: Remaster key button mechanic
		return;
	self.attack_finished = time + 2;
  
  if (self.items)
  {
    if ( !AttemptUnlock() ) //Ry: Global function for this now
      return;
    else
    {
      // Yoder Sept24, 2021 Horde merge
      if (horde_ent)
      {
        horde_key_spend(self.items);
        self.touch = SUB_Null;
      }
      else // standard behavior
        other.items = other.items - self.items;
    }
  }
  
	self.enemy = other;
	button_fire ();
};

void() button_killed =
{
	self.enemy = damage_attacker;
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;	// wil be reset upon return
	button_fire ();
};


/*QUAKED func_button (0 .5 .8) ?
When a button is touched, it moves some distance in the direction of it's angle, triggers all of it's targets, waits some time, then returns to it's original position where it can be triggered again.

"angle"		determines the opening direction
"target"	all entities with a matching targetname will be used
"speed"		override the default 40 speed
"wait"		override the default 1 second wait (-1 = never return)
"lip"		override the default 4 pixel lip remaining at end of move
"health"	if set, the button must be killed instead of touched
"sounds"
0) steam metal
1) wooden clunk
2) metallic click
3) in-out
*/
void() func_button =
{

  if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: For hybrid horde/campaign maps
    return;
  
  self.netname = "func_button"; // for bot nav support.
  
  PrepareKeyMechanismSounds(); //Ry: Set up key sounds via new global function

	if (self.sounds == 0)
	{
		precache_sound ("buttons/airbut1.wav");
		self.noise = "buttons/airbut1.wav";
	}
	if (self.sounds == 1)
	{
		precache_sound ("buttons/switch21.wav");
		self.noise = "buttons/switch21.wav";
	}
	if (self.sounds == 2)
	{
		precache_sound ("buttons/switch02.wav");
		self.noise = "buttons/switch02.wav";
	}
	if (self.sounds == 3)
	{
		precache_sound ("buttons/switch04.wav");
		self.noise = "buttons/switch04.wav";
	}
	
	SetMovedir ();

	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	setmodel (self, self.model);

	self.blocked = button_blocked;
	self.use = button_use;
  
	if (self.spawnflags & DOOR_SILVER_KEY) //Ry: Remaster key button mechanic
		self.items = IT_KEY1;
	if (self.spawnflags & DOOR_GOLD_KEY)
		self.items = IT_KEY2;

	if (self.health)
	{
		self.max_health = self.health;
		self.th_die = button_killed;
		self.takedamage = DAMAGE_YES;
	}
	else
		self.touch = button_touch;

	if (!self.speed)
		self.speed = 40;
	if (!self.wait)
		self.wait = 1;
	if (!self.lip)
		self.lip = 4;

	self.state = STATE_BOTTOM;

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip);
  
  if (deathmatch && self.wait == -1) //Ry: Immediately trigger all one-time buttons in Deathmatch
  {
    self.sounds = 0;
    self.takedamage = DAMAGE_NO;
    self.use = SUB_Null;
    self.think = button_fire;
    self.nextthink = time + 1 + random();
  }
};

