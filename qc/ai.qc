void() movetarget_f;
void() t_movetarget;
void() knight_walk1;
void() knight_bow6;
void() knight_bow1;
void(entity etemp, entity stemp, entity stemp, float dmg) T_Damage;
/*

.enemy
Will be world if not currently angry at anyone.

.movetarget
The next path spot to walk toward.  If .enemy, ignore .movetarget.
When an enemy is killed, the monster will try to return to it's path.

.huntt_ime
Set to time + something when the player is in sight, but movement straight for
him is blocked.  This causes the monster to use wall following code for
movement direction instead of sighting on the player.

.ideal_yaw
A yaw angle of the intended direction, which will be turned towards at up
to 45 deg / state.  If the enemy is in view and hunt_time is not active,
this will be the exact line towards the enemy.

.pausetime
A monster will leave it's stand state and head towards it's .movetarget when
time > .pausetime.

walkmove(angle, speed) primitive is all or nothing
*/

//
// when a monster becomes angry at a player, that monster will be used
// as the sight target the next frame so that monsters near that one
// will wake up even if they wouldn't have noticed the player
//
entity	sight_entity;
float	sight_entity_time;
void() FoundTarget;



//======================
//  New Subs by Ryason
//======================

#ifdef GAME_HIPNOTIC
  entity() SelectTargetForCharmed = //Ry: Separated out from FindTarget
  {
    local entity head;
    local entity selected;
    local float dist;

    selected = world;
    dist = CHARMED_RADIUS;
    head = findradius(self.origin, CHARMED_RADIUS);
    while(head)
    {
      //Ry: Can now target players, checks against team, and won't target downed Zombies
      if (!(head.flags & FL_NOTARGET) && (head.flags & (FL_CLIENT|FL_MONSTER)) && (head.solid) && ((head.team == 0) || (head.team != self.team)) )
      {
        if (visible(head) && (visible_distance < dist) && (head.health>0))
        {
          if ((head !=self) && (head != self.charmer) && (head.charmer != self.charmer))
          {
            selected = head;
            dist = visible_distance;
          }
        }
      }
      head = head.chain;
    }
    return selected;
  }

  #ifndef ENGINE_KEX
    float(entity source, entity dest, vector floorvec) Charmed_CanPathToPlayer =
    {
      local float val,len,lower,middle;
      local vector dir,vec1,vec2;
      
      //Ry: For everything past the second last breadcrumb, do a height check
      if (source.customtarget.customtarget)
      {
        if (floorvec_z >= (source.origin_z + 24))
          return FALSE;
      }
      
      //Ry: Both of these traces must succeed
      traceline(source.origin,dest.origin,TRUE,source);
      if (trace_fraction == 1.0)
      {
        traceline(source.origin,floorvec,TRUE,source);
        if (trace_fraction == 1.0)
        {
          //Ry: Make sure there aren't any pits in the way
          vec1 = dest.origin-source.origin;
          len = vlen(vec1);
          if (len > 64)
          {
            val = 5; //Ry: Number of down traces
            len = len/(val+1);
            dir = normalize(vec1);
            middle = ((source.origin_z+floorvec_z)/2)-24;
            if (floorvec_z <= source.origin_z)
              lower = floorvec_z - 40; //Ry: 24 unit height, and then 16 more units down
            else
              lower = source.origin_z - 40;
            while (val > 0)
            {
              vec1 = source.origin + ( dir * (len*val) );
              vec2 = vec1;
              vec2_z = lower;

              traceline(vec1,vec2,TRUE,source);
              if (trace_fraction == 1.0)
                return FALSE;

              val -= 1;
            }
          }
          return TRUE;
        }
      }
      return FALSE;
    }

    void(entity source, vector vec) CreateBreadcrumb =
    {
      if (!source.customtarget)
        source.customtarget = spawn();
      if (source.classname == "charm_breadcrumb")
        source.customtarget.cnt = source.cnt + 1;
      else
        source.customtarget.cnt = 1;
      source.customtarget.classname = "charm_breadcrumb";
      source.customtarget.owner = source;
      setorigin(source.customtarget,vec);
      //dprint("Created breadcrumb ");
      //dprint(ftos(source.customtarget.cnt));
      //dprint("\n");
    }
    
    void(entity source) RemoveBreadcrumbs =
    {
      local entity curr, next;
      curr = source.customtarget;
      source.customtarget = world;
      while (curr)
      {
        next = curr.customtarget;
        if (curr.classname == "charm_breadcrumb")
          remove(curr);
        curr = next;
      }
      /*if (source.classname == "charm_breadcrumb")
      {
        dprint("Removed breadcrumbs from breadcrumb ");
        dprint(ftos(source.cnt));
        dprint("\n");
      }
      else
      {
        dprint("Removed breadcrumbs from entity ");
        dprint(source.classname);
        dprint("\n");
      }*/
    }
    
    void() TryAutoMonsterJump =
    {
      local vector dir, vec;
      local float val;
      if ((self.huntingcharmer < 3) && (self.goalentity) && (self.flags & FL_ONGROUND) && (time >= self.rad_time))
      {
        if (self.origin_z > self.goalentity.origin_z)
        {
          dir = self.maxs;
          dir_z = 0;
          val = vlen(dir) + 8;
          makevectors (self.angles);
          dir = self.origin + (v_forward*val);
          traceline(self.origin,dir,TRUE,self);
          if (trace_fraction == 1) //Ry: Ensure not facing into a wall
          {
            vec = dir;
            vec_z = ((self.origin_z + self.mins_z) - 65);
            traceline(dir,vec,TRUE,self);
            if (trace_fraction == 1) //Ry: Check if there's a significant enough ledge
            {
              self.velocity = v_forward * 200; //Ry: Do Jump
              self.velocity_z = 200;
              self.flags = self.flags - FL_ONGROUND;
              self.rad_time = time + 3;
            }
          }
        }
      }
    }
  #endif
#endif

//===================
//  End of new subs
//===================



float(float v) anglemod =
{
	while (v >= 360)
		v = v - 360;
	while (v < 0)
		v = v + 360;
	return v;
};

/*
==============================================================================

MOVETARGET CODE

The angle of the movetarget effects standing and bowing direction, but has no effect on movement, which allways heads to the next target.

targetname
must be present.  The name of this movetarget.

target
the next spot to move to.  If not present, stop here for good.

pausetime
The number of seconds to spend standing or bowing for path_stand or path_bow

==============================================================================
*/


void() movetarget_f =
{
	if (!self.targetname)
		objerror ("monster_movetarget: no targetname");

	self.solid = SOLID_TRIGGER;
	self.touch = t_movetarget;
	setsize (self, '-8 -8 -8', '8 8 8');

};

/*QUAKED path_corner (0.5 0.3 0) (-8 -8 -8) (8 8 8)
Monsters will continue walking towards the next target corner.
"delay" delay to wait before proceeding to next segment;
*/
void() path_corner =
{
	movetarget_f ();
};


/*
=============
t_movetarget

Something has bumped into a movetarget.  If it is a monster
moving towards it, change the next destination and continue.
==============
*/
void() t_movetarget =
{
local entity	temp;

	if (other.movetarget != self)
		return;

	if (other.enemy)
		return;		// fighting, not following a path

	temp = self;
	self = other;
	other = temp;

	if (self.classname == "monster_ogre")
		sound (self, CHAN_VOICE, "ogre/ogdrag.wav", 1, ATTN_IDLE);// play chainsaw drag sound

//dprint ("t_movetarget\n");
//MED
   if (other.target)
      {
      self.goalentity = self.movetarget = find (world, targetname, other.target);
      self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
      if (!self.movetarget)
         {
         self.pausetime = time + 999999;
         self.th_stand ();
         return;
         }
   //MED 01/20/97
      else if (other.delay)
         {
         self.pausetime = time + other.delay;
         self.th_stand ();
         }
      }
   else
      {
      self.pausetime = time + 999999;
      self.th_stand ();
      return;
      }
};


#ifdef GAME_HIPNOTIC
  //MED 01/20/97

  /*
  =============
  t_followtarget

  Something has bumped into a followtarget.  If it is a monster
  moving towards it, change the next destination and continue.
  ==============
  */
  void() t_followtarget =
  {
    local entity   temp;
    local vector   spot1, spot2;
    local entity   targ;
    local entity   client;

    if (!(other.flags & FL_MONSTER))
      return;
    if (other.classname == "monster_decoy")
      return;
    if (other.health <= 0) //Ry: Don't run on dying monsters [08-01-2022]
      return;
    #ifdef ENGINE_KEX
      if (other.allowPathFind == USEPATH_ALWAYS) //Ry: Don't affect monsters using pathing [08-01-2022]
        return;
    #endif
    //if (other.enemy == world)
    //  return;
    if (other.wetsuit_time > time)
      return;
    targ = other.enemy;

  // see if any entities are in the way of the shot
    spot1 = other.origin + other.view_ofs;
    spot2 = targ.origin + targ.view_ofs;

    traceline (spot1, spot2, FALSE, other);
    if (trace_fraction == 1)
      return;

    if (other.enemy)
    {
      // make the monster tame
      other.oldenemy = other.enemy;
      other.enemy = world;
      other.think = other.th_walk;
    }

    temp = self;
    self = other;
    other = temp;

    self.goalentity = self.movetarget = find (world, targetname, other.target);
  /*
     bprint("target ");
     bprint(other.target);
     bprint(" targetname ");
     bprint(self.goalentity.targetname);
     bprint(" origin ");
     bprint(vtos(self.goalentity.origin));
     bprint("\n");
  */
    self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
    self.wetsuit_time = time + 2;
    if (!self.movetarget)
    {
      if (self.oldenemy != world)
      {
        self.enemy = self.oldenemy;
        FoundTarget();
        return;
      }
      else
      {
        client = checkclient ();
        if (!client)
        {
          self.enemy = client;
          FoundTarget();
          return;
        }
        self.pausetime = time + 999999;
        self.th_stand ();
      }
    }
  };

  void() followtarget_f =
  {
    self.solid = SOLID_TRIGGER;
    self.touch = t_followtarget;
    setmodel (self, self.model);  // set size and link into world
    self.movetype = MOVETYPE_NONE;
    self.modelindex = 0;
    self.model = "";
  };

  /*QUAKED path_follow (0.5 0.3 0) ?
  Monsters will stop what they are doing and follow to the path
  */

  void() path_follow =
  {
    if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: Do entity type check here too [08-01-2022]
      return;
    followtarget_f ();
  };

  /*QUAKED path_follow2 (0.5 0.3 0) (-8 -8 -8) (8 8 8)
  Monsters will stop what they are doing and follow to the path
  */

  void() path_follow2 =
  {
    if (!EntityValidForMode(ENTTYPE_LEVEL)) //Ry: Do entity type check here too [08-01-2022]
      return;
    self.solid = SOLID_TRIGGER;
    self.touch = t_followtarget;
    setsize (self, '-8 -8 -8', '8 8 8');
  };
#endif


//============================================================================

/*
=============
range

returns the range catagorization of an entity reletive to self
0	melee range, will become hostile even if back is turned
1	visibility and infront, or visibility and show hostile
2	infront and show hostile
3	only triggered by damage
=============
*/
float(entity targ) range =
{
local vector	spot1, spot2;
local float		r;
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;

	r = vlen (spot1 - spot2);
	if (r < 120)
		return RANGE_MELEE;
	if (r < 500)
		return RANGE_NEAR;
	if (r < 1000)
		return RANGE_MID;
	return RANGE_FAR;
};

/*
=============
visible

returns 1 if the entity is visible to self, even if not infront ()
=============
*/
float (entity targ) visible =
{
	local vector	spot1, spot2;

	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;
   traceline (spot1, spot2, TRUE, self);  // see through other monsters

	if (trace_inopen && trace_inwater)
		return FALSE;			// sight line crossed contents

//MED 11/21/96
	if (trace_fraction == 1)
      {
      visible_distance = vlen(spot2-spot1);
      return TRUE;
      }
	return FALSE;
};


/*
=============
infront

returns 1 if the entity is in front (in sight) of self
=============
*/
float(entity targ) infront =
{
	local vector	vec;
	local float		dot;

	makevectors (self.angles);
	vec = normalize (targ.origin - self.origin);
	dot = vec * v_forward;

	if ( dot > 0.3)
	{
		return TRUE;
	}
	return FALSE;
};

#ifdef GAME_HIPNOTIC
  //MED 10/18/96 added charmed stuff
  //============================================================================
  void() UpdateCharmerGoal =
  {
    local entity targ;
    local vector dir;

    #ifdef ENGINE_KEX
      if (self.huntingcharmer == 1)
      {
        self.huntingcharmer = 2;
        self.goalentity = self.charmer; //Ry: Directly follow Charmer, since there's proper pathing now
      }
      else if (self.huntingcharmer > 2)
      {
        if (!self.customtarget)
        {
          targ = spawn();
          targ.classname = "charm_followtarget";
          self.customtarget = targ;
        }
        else
          targ = self.customtarget;
        if (!(self.goalentity == targ))
          self.goalentity = targ;
        dir = normalize(self.origin-self.charmer.origin);
        setorigin(targ,self.charmer.origin + (dir*300));
      }
    #else
      //Ry: Improved logic for pathing via breadcrumbs when not using Remaster [07-25-2022]
    
      local vector floorvec;

      floorvec = self.charmer.origin; //Ry: Trace down to floor, and then up to player entity height
      floorvec_z -= 10000;
      traceline(self.charmer.origin,floorvec,TRUE,self.charmer);
      floorvec = trace_endpos;
      floorvec_z -= self.charmer.mins_z;

      if (self.huntingcharmer == 1) //Ry: If charmer is in sight, create the first breadcrumb
      {
        if (Charmed_CanPathToPlayer(self,self.charmer,floorvec))
        {
          CreateBreadcrumb(self,floorvec);
          self.goalentity = self.customtarget;
          self.huntingcharmer = 2;
        }
        else if (self.goalentity != self.charmer)
          self.goalentity = self.charmer;
      }
      else if (self.huntingcharmer == 2)
      {
        targ = self.customtarget;
        if ( vlen(targ.origin-self.origin) < 64 ) //Ry: If near the current breadcrumb, "eat" it and move onto the next one
        {
          //dprint("Monster reached breadcrumb ");
          //dprint(ftos(targ.cnt));
          //dprint("\n");
          if (targ.customtarget) //Ry: Still more breadcrumbs to go
          {
            targ = targ.customtarget;
            remove(self.customtarget);
            targ.owner = self;
            self.customtarget = targ;
            self.goalentity = targ;
          }
          else //Ry: Ate the last breadcrumb; Go back to hunting charmer directly
          {
            RemoveBreadcrumbs(self);
            self.goalentity = self.charmer;
            self.huntingcharmer = 1;
            return;
          }
        }
        targ = self;
        while (targ) //Ry: Check if the monster or any breadcrumbs can see the charmer
        {
          if (Charmed_CanPathToPlayer(targ,self.charmer,floorvec)) //Ry: Player is visible from an earlier point in the chain; Cull everything past that point
          {
            if (!targ.customtarget)
              CreateBreadcrumb(targ,floorvec);
            targ = targ.customtarget;
            if (targ.customtarget)
              RemoveBreadcrumbs(targ);
            break;
          }

          targ = targ.customtarget;
          if (!targ.customtarget) //Ry: We've hit the end of the chain; Create a new breadcrumb to place on the player
          {
            if (pointcontents(self.charmer.origin) != CONTENT_SOLID) //Ry: UNLESS the player is in a wall
            {
              CreateBreadcrumb(targ,self.charmer.origin);
              targ = targ.customtarget;
            }
            break;
          }
        }
        setorigin(targ,floorvec);
      }
      else
      {
        if (!self.customtarget)
          CreateBreadcrumb(self,self.charmer.origin);
        else if (self.customtarget.customtarget)
          RemoveBreadcrumbs(self.customtarget);
        targ = self.customtarget;
        dir = normalize(self.origin-self.charmer.origin);
        setorigin(targ,self.charmer.origin + (dir*300));
      }

      //Ry: Try to jump off ledges [07-26-2022]
      TryAutoMonsterJump();
    #endif
  };

  //============================================================================
  void() HuntCharmer =
  {
    self.huntingcharmer = 1;
    UpdateCharmerGoal();
    visible(self.charmer);
    self.think = self.th_walk;
    self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
    self.nextthink = time + 0.1;
  };

  //============================================================================
  void() FleeCharmer =
  {
    self.huntingcharmer = 1;
    UpdateCharmerGoal();
    self.huntingcharmer = 3;
    self.think = self.th_walk;
    self.nextthink = time + 0.1;
  };

  //============================================================================
  void() StopHuntingCharmer =
  {
    self.goalentity = world;
    if (self.huntingcharmer > 1 && self.customtarget) //Ry: Check
    {
      #ifdef ENGINE_KEX
        remove(self.customtarget);
        self.customtarget = world;
      #else
        RemoveBreadcrumbs(self.customtarget);
      #endif
    }
    self.huntingcharmer = 0;
    self.think = self.th_stand;
    self.nextthink = time + 0.1;
  };

  //============================================================================
#endif

void() HuntTarget =
{
	self.goalentity = self.enemy;
	self.think = self.th_run;
	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	self.nextthink = time + 0.1;
	SUB_AttackFinished (1);	// wait a while before first attack
};

void() SightSound =
{
local float	rsnd;

	if (self.classname == "monster_ogre")
		sound (self, CHAN_VOICE, "ogre/ogwake.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_knight")
  {
    #ifdef GAME_ROGUE
    if (self.skin == 0)
    #endif
      sound (self, CHAN_VOICE, "knight/ksight.wav", 1, ATTN_NORM);
  }
	else if (self.classname == "monster_shambler")
		sound (self, CHAN_VOICE, "shambler/ssight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_demon1")
		sound (self, CHAN_VOICE, "demon/sight2.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_wizard")
		sound (self, CHAN_VOICE, "wizard/wsight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_zombie")
		sound (self, CHAN_VOICE, "zombie/z_idle.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_dog")
		sound (self, CHAN_VOICE, "dog/dsight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_hell_knight")
  {
    #ifdef GAME_ROGUE
    if (self.skin == 0)
    #endif
      sound (self, CHAN_VOICE, "hknight/sight1.wav", 1, ATTN_NORM);
  }
	else if (self.classname == "monster_tarbaby")
		sound (self, CHAN_VOICE, "blob/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_enforcer")
	{
		rsnd = rint(random() * 3);
		if (rsnd == 1)
			sound (self, CHAN_VOICE, "enforcer/sight1.wav", 1, ATTN_NORM);
		else if (rsnd == 2)
			sound (self, CHAN_VOICE, "enforcer/sight2.wav", 1, ATTN_NORM);
		else if (rsnd == 0)
			sound (self, CHAN_VOICE, "enforcer/sight3.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "enforcer/sight4.wav", 1, ATTN_NORM);
	}
	else if (self.classname == "monster_army")
		sound (self, CHAN_VOICE, "soldier/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_shalrath")
		sound (self, CHAN_VOICE, "shalrath/sight.wav", 1, ATTN_NORM);
  #ifdef GAME_HIPNOTIC
    //MED
    else if (self.classname == "monster_gremlin")
    {
      if (self.gremstate < GREM_ARMED)
        sound (self, CHAN_VOICE, "grem/sight1.wav", 1, ATTN_NORM);
    }
    //MED
    else if (self.classname == "monster_scourge")
      sound (self, CHAN_VOICE, "scourge/sight.wav", 1, ATTN_NORM);
    //MED
    else if (self.classname == "monster_armagon")
      sound (self, CHAN_VOICE, "armagon/sight.wav", 1, 0.1);
  #endif
  #ifdef GAME_ROGUE
    else if (self.classname == "monster_eel")
      sound (self, CHAN_VOICE, "eel/eelc5.wav", 1, ATTN_NORM);
    else if (self.classname == "monster_wrath")
      sound (self, CHAN_VOICE, "wrath/wsee.wav", 1, ATTN_NORM);
    else if (self.classname == "monster_dragon")
      sound (self, CHAN_VOICE, "dragon/see.wav", 1, ATTN_NORM);
  #endif
};

void() FoundTarget =
{
//MED
	if (self.enemy.classname == "player")
  {
    #ifdef GAME_HIPNOTIC
      if (self.charmed)
      {
        if ((self.charmer == self.enemy) || (self.charmer == self.enemy.charmer))
        {
          self.enemy = world;
          return;
        }
      }
    #endif
    // let other monsters see this monster for a while
		sight_entity = self;
		sight_entity_time = time;
  }
  #ifdef GAME_HIPNOTIC
    else if (self.charmed)
    {
      if ((self.charmer == self.enemy.charmer))
      {
        self.enemy = world;
        return;
      }
    }

    if (self.huntingcharmer) //Ry: Make sure this is reset
      self.huntingcharmer = 0;
  #endif
      
  self.lastfoetime = time; //Ry: Note the time foe was last changed

	self.show_hostile = time + 1;		// wake up other monsters

	SightSound ();
	HuntTarget ();
};

/*
===========
FindTarget

Self is currently not attacking anything, so try to find a target

Returns TRUE if an enemy was sighted

When a player fires a missile, the point of impact becomes a fakeplayer so
that monsters that see the impact will respond as if they had seen the
player.

To avoid spending too much time, only a single client (or fakeclient) is
checked each frame.  This means multi player games will have slightly
slower noticing monsters.
============
*/
float() FindTarget =
{
	local entity	client;
	local float		r;

// if the first spawnflag bit is set, the monster will only wake up on
// really seeing the player, not another monster getting angry

// spawnflags & 3 is a big hack, because zombie crucified used the first
// spawn flag prior to the ambush flag, and I forgot about it, so the second
// spawn flag works as well

  #ifdef GAME_HIPNOTIC
  //MED 10/17/96 added charmed stuff
  if (self.charmed && !self.enemy)
  {
    if (!deathmatch)
      self.effects = self.effects | EF_DIMLIGHT;
    if (self.classname == "monster_gremlin" && self.gremstate) //Ry: Break if Gremlin is up to something
    {
      self.huntingcharmer = 0;
    }
    else if (self.huntingcharmer > 0)
    {
      UpdateCharmerGoal();
      if (self.huntingcharmer == 3) //Ry: When not fleeing, compare against charmer, not goalentity [07-25-2022]
        r = vlen(self.origin - self.goalentity.origin);
      else
        r = vlen(self.origin - self.charmer.origin);
      if (r < MIN_CHARMER_DISTANCE)
      {
        if ((self.huntingcharmer == 3) && (r > TOOCLOSE_CHARMER_DISTANCE))
          return FALSE;

        #ifndef ENGINE_KEX
          //Ry: Check if charmer can be seen [10-11-2022]
          if (self.huntingcharmer < 3)
            if (!visible(self.charmer))
              return FALSE;
        #endif

        StopHuntingCharmer();
        return TRUE;
      }
    }
    else if (vlen (self.origin - self.charmer.origin) > MAX_CHARMER_DISTANCE)
    {
      HuntCharmer();
      return FALSE;
    }
    else if (vlen (self.origin - self.charmer.origin) < TOOCLOSE_CHARMER_DISTANCE)
    {
      FleeCharmer();
      return FALSE;
    }
    #ifndef ENGINE_KEX
    //Ry: Charmer rounded a corner real close by [10-11-2022]
    else if (!visible(self.charmer))
    {
      self.huntingcharmer = 2;
      CreateBreadcrumb(self,self.charmer.origin);
      self.goalentity = self.customtarget;
      UpdateCharmerGoal();
      self.think = self.th_walk;
      self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
      self.nextthink = time + 0.1;
      return FALSE;
    }
    #endif
  }

  if (sight_entity_time >= time - 0.1 && !(self.spawnflags & 3) && !(self.charmed) )
  #else
  if (sight_entity_time >= time - 0.1 && !(self.spawnflags & 3) )
  #endif
  {
		client = sight_entity;
		if (client.enemy == self.enemy)
			return FALSE; // Cataboligne 9.17.3 - fixed this compiler warning
	}
  #ifdef GAME_HIPNOTIC
    else if (self.charmed)
    {
      local entity selected;
      selected = SelectTargetForCharmed(); //Ry: Now a standalone function
      if (selected == world)
        return FALSE;
      client = selected;
    }
  #endif
  else
	{
    client = checkclient ();
    if (!client)
      return FALSE;	// current check entity isn't in PVS
	}

	if (client == self.enemy)
		return FALSE;

  #ifdef GAME_HIPNOTIC
  //MED 10/17/96 added charmed stuff
  if (!self.charmed)
  {
  #endif
    if (client.flags & FL_NOTARGET)
      return FALSE;
  #ifdef GAME_HIPNOTIC
  }
  #endif
  if (client.items & IT_INVISIBILITY)
    return FALSE;

	r = range (client);
	if (r == RANGE_FAR)
		return FALSE;

	if (!visible (client))
		return FALSE;

  #ifdef GAME_HIPNOTIC
  //MED 10/17/96 added charmed stuff
  if (!self.charmed)
  {
  #endif
    if (r == RANGE_NEAR)
    {
      if (client.show_hostile < time && !infront (client))
        return FALSE;
    }
    else if (r == RANGE_MID)
    {
      if ( /* client.show_hostile < time || */ !infront (client))
        return FALSE;
    }
  #ifdef GAME_HIPNOTIC
  }
  #endif

  // got one
	self.enemy = client;

  #ifdef GAME_HIPNOTIC
  //MED 10/17/96 added charmed stuff
  if ((!self.charmed) && (!self.enemy.charmed))
  {
  #endif
    if (self.enemy.classname != "player")
    {
      self.enemy = self.enemy.enemy;
      if (self.enemy.classname != "player")
      {
        self.enemy = world;
        return FALSE;
      }
    }
  #ifdef GAME_HIPNOTIC
  }
  #endif

  #ifdef GAME_ROGUE
  // PGM hack	
	if (self.classname != "monster_dragon") //Ry: Not sure if this even comes up, but corrected the classname [09-02-2022]
  #endif
    FoundTarget ();

	return TRUE;
};


//=============================================================================

void(float dist) ai_forward =
{
	walkmove (self.angles_y, dist);
};

void(float dist) ai_back =
{
	walkmove ( (self.angles_y+180), dist);
};


/*
=============
ai_pain

stagger back a bit
=============
*/
void(float dist) ai_pain =
{
	ai_back (dist);
/*
	local float	away;

	away = anglemod (vectoyaw (self.origin - self.enemy.origin)
	+ 180*(random()- 0.5) );

	walkmove (away, dist);
*/
};

/*
=============
ai_painforward

stagger back a bit
=============
*/
void(float dist) ai_painforward =
{
	walkmove (self.ideal_yaw, dist);
};

/*
=============
ai_walk

The monster is walking it's beat
=============
*/
void(float dist) ai_walk =
{
	movedist = dist;

  //Ry: Monster is no longer doing an attack, so unbusy [09-24-2022]
  if ( MonsterUnbusy() )
    return;

  //MED 01/20/97
	// check for noticing a player
  if ( FindTarget() )
    return;

  #ifdef GAME_HIPNOTIC
    //MED 11/02/96
    if (self.huntingcharmer )
    {
      #ifdef ENGINE_KEX
        ai_pathtogoal(dist); //Ry: Charmed monsters use bot pathing if availible
      #else
        movetogoal (dist);
      #endif
      if ( (self.classname == "monster_ogre") || (self.classname == "monster_hell_knight") || (self.classname == "monster_knight") )
        self.nextthink = time + ((self.nextthink - time)/3);
      else
        self.nextthink = time + ((self.nextthink - time)/2);
    }
    else
  #endif
    movetogoal (dist);
};


/*
=============
ai_stand

The monster is staying in one place for a while, with slight angle turns
=============
*/
void() ai_stand =
{
  //Ry: Monster is no longer doing an attack, so unbusy [09-24-2022]
  if ( MonsterUnbusy() )
    return;

  if (FindTarget ())
    return;

	if (time > self.pausetime)
	{
		self.th_walk ();
		return;
	}

// change angle slightly

};

/*
=============
ai_turn

don't move, but turn towards ideal_yaw
=============
*/
void() ai_turn =
{
	if (FindTarget ())
		return;

	ChangeYaw ();
};

#ifdef GAME_HIPNOTIC
  //MED 11/10/96 added ai_turn_in_place
  /*
  =============
  ai_turn_in_place

  don't move, but turn towards ideal_yaw
  =============
  */
  void() ai_turn_in_place =
  {
    local float delta;

    self.nextthink = time + 0.1;
    enemy_yaw = vectoyaw(self.enemy.origin - self.origin);
    delta = fabs(self.angles_y - enemy_yaw);
    if (delta > MIN_ANGLE_DELTA)
    {
      self.ideal_yaw = enemy_yaw;
      ChangeYaw();
    }
    else
    {
      self.think = self.th_run;
    }
  };
#endif

//=============================================================================

/*
=============
ChooseTurn
=============
*/
void(vector dest3) ChooseTurn =
{
	local vector	dir, newdir;

	dir = self.origin - dest3;

	newdir_x = trace_plane_normal_y;
	newdir_y = 0 - trace_plane_normal_x;
	newdir_z = 0;

	if (dir * newdir > 0)
	{
		dir_x = 0 - trace_plane_normal_y;
		dir_y = trace_plane_normal_x;
	}
	else
	{
		dir_x = trace_plane_normal_y;
		dir_y = 0 - trace_plane_normal_x;
	}

	dir_z = 0;
	self.ideal_yaw = vectoyaw(dir);
};

/*
============
FacingIdeal

============
*/
float() FacingIdeal =
{
	local	float	delta;

	delta = anglemod(self.angles_y - self.ideal_yaw);
	if (delta > 45 && delta < 315)
		return FALSE;
	return TRUE;
};


//=============================================================================

float()	WizardCheckAttack;
float()	DogCheckAttack;
#ifdef GAME_HIPNOTIC
  //MED
  float()  GremlinCheckAttack;
  float()  ScourgeCheckAttack;
  float()  ArmagonCheckAttack;
#endif

float() CheckAnyAttack =
{
	if (!enemy_vis)
		return FALSE; // Cataboligne 9.17.3 - fixed this compiler warning
  if (self.classname == "monster_army")
		return SoldierCheckAttack ();
  if (self.classname == "monster_ogre")
		return OgreCheckAttack ();
  if (self.classname == "monster_shambler")
		return ShamCheckAttack ();
	if (self.classname == "monster_demon1")
		return DemonCheckAttack ();
	if (self.classname == "monster_dog")
		return DogCheckAttack ();
	if (self.classname == "monster_wizard")
		return WizardCheckAttack ();
  #ifdef GAME_HIPNOTIC
    if (self.classname == "monster_gremlin")
      return GremlinCheckAttack ();
    if (self.classname == "monster_scourge")
      return ScourgeCheckAttack ();
    if (self.classname == "monster_armagon")
      return ArmagonCheckAttack ();
  #endif
   return CheckAttack ();
};


/*
=============
ai_run_melee

Turn and close until within an angle to launch a melee attack
=============
*/
void() ai_run_melee =
{
	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();

	if (FacingIdeal())
	{
		self.th_melee ();
		self.attack_state = AS_STRAIGHT;
	}
};


/*
=============
ai_run_missile

Turn in place until within an angle to launch a missile attack
=============
*/
void() ai_run_missile =
{
	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();
	if (FacingIdeal())
	{
		self.th_missile ();
		self.attack_state = AS_STRAIGHT;
	}
};


/*
=============
ai_run_slide

Strafe sideways, but stay at aproximately the same range
=============
*/
void() ai_run_slide =
{
	local float	ofs;

	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();
	if (self.lefty)
		ofs = 90;
	else
		ofs = -90;

	if (walkmove (self.ideal_yaw + ofs, movedist))
		return;

	self.lefty = 1 - self.lefty;

	walkmove (self.ideal_yaw - ofs, movedist);
};

#ifdef GAME_HIPNOTIC
  //MED
  /*
  =============
  ai_run_dodge

  Strafe sideways, but continue moving towards the enemy
  Used by the Scourge.
  =============
  */
  void() ai_run_dodge =
  {
    local float	ofs;
     local float newyaw;

  /*
  // attempt to jump over missiles
     if (self.enemy.weaponframe == 1)
        {
        if (self.flags & FL_ONGROUND)
           {
           self.origin_z = self.origin_z + 1;
           self.velocity = self.velocity + '0 0 500';
           self.flags = self.flags - FL_ONGROUND;
           }
        self.ltime = self.ltime + 1.0;
        }
  */
     self.nextthink = time + 0.1;
     if (self.lefty)
        ofs = 40;
    else
        ofs = -40;

     if (time > self.ltime)
        {
        self.lefty = 1 - self.lefty;
        self.ltime = time + 0.8;
        }

     newyaw = enemy_yaw + ofs;
     self.ideal_yaw = enemy_yaw;
     if (walkmove (newyaw, movedist))
        {
        ChangeYaw ();
        return;
        }

     self.lefty = 1 - self.lefty;
     self.ltime = time + 0.8;
     newyaw = enemy_yaw - ofs;
     self.ideal_yaw = enemy_yaw;
     walkmove (newyaw, movedist);
     ChangeYaw ();
  };
#endif

/*
=============
ai_run

The monster has an enemy it is trying to kill
=============
*/

#ifdef GAME_HIPNOTIC
  float RUN_STRAIGHT;
  float() Armagon_ClearShotFromBarrels;
#endif

void(float dist) ai_run =
{
  local entity newtarget, stemp, closetarg;
  local float closedist, currdist;

  //Ry: Monster is no longer doing an attack, so unbusy [09-24-2022]
  MonsterUnbusy();

  #ifdef GAME_HIPNOTIC
    if ( self.charmed && (self.goalentity == self.charmer) ) //Ry: Ensure charmed monsters walk after pain when following charmer
    {
      self.th_walk();
      return;
    }
    if ( self.charmed && (time >= self.lastfoetime + 3) ) //Ry: Charmed monsters will look for other enemies when their current target isn't visible
    {
      if ( !visible(self.enemy) )
      {
        newtarget = SelectTargetForCharmed();
        if ( newtarget != world )
        {
          self.enemy = newtarget;
          FoundTarget();
        }
      }
    }
  #endif

	movedist = dist;
  // see if the enemy is dead
  #ifdef GAME_HIPNOTIC
    if (self.enemy.health <= 0 || (self.charmed && (self.charmer == self.enemy)))
  #else
    if (self.enemy.health <= 0)
  #endif
	{
		self.enemy = world;
    #ifdef GAME_HIPNOTIC
      //MED 10/30/96 added charmed stuff
      if (self.charmed)
      {
        HuntCharmer();
        return;
      }
    #endif
	  // FIXME: look all around for other targets
		if (self.oldenemy.health > 0)
		{
			self.enemy = self.oldenemy;
			HuntTarget ();
		}
		else
		{
			if (self.movetarget)
				self.th_walk ();
			else
				self.th_stand ();
			return;
		}
	}

	self.show_hostile = time + 1;		// wake up other monsters

// check knowledge of enemy
	enemy_vis = visible(self.enemy);
	if (enemy_vis)
		self.search_time = time + 5;

  // look for other coop players
  #ifdef GAME_HIPNOTIC
  //MED 10/17/96 added charmed stuff
  if (coop && self.search_time < time && !self.charmed)
  #else
  if (coop && self.search_time < time)
  #endif
	{
		if (FindTarget ())
			return;
	}
  
  #ifdef GAME_HIPNOTIC
    if ((self.classname == "monster_armagon") && enemy_vis) //Ry: Additional visibility check for Armagon [08-0X-2022]
      if (time < self.wetsuit_time)
        enemy_vis = FALSE;
      else if (!Armagon_ClearShotFromBarrels())
        enemy_vis = FALSE;
  #endif

  //Ry: If foe can't be seen, see if any "traffic mirrors" are in sight and can see the player [08-0X-2022]
  #ifdef ENGINE_KEX
  if (self.allowPathFind != USEPATH_ALWAYS)
  {
  #endif
    local vector monstervec;
    if (!enemy_vis && (self.goalentity == self.enemy))
    {
      newtarget = find(world,classname,"path_trafficmirror");
      if (newtarget)
      {
        monstervec = self.origin;
        closedist = 10000;
        closetarg = world;
        while (newtarget)
        {
          monstervec_z = newtarget.origin_z; //Ry: Ignore vertical height difference
          currdist = vlen(newtarget.origin-monstervec);
          if (currdist > newtarget.distance) //Ry: Check if monster isn't already on the marker
          {
            if (ClearPathToTarget(newtarget)) //Ry: See if monster can path straight to marker
            {
              if (!infront(newtarget)) //Ry: Prefer markers in front
                currdist += 64;
              stemp = self;
              self = newtarget;
              if (visible(stemp.enemy)) //Ry: This marker can see the target
              {
                currdist += visible_distance; //Ry: Track the closest one
                if ((currdist < closedist) || ((currdist == closedist) && (random() < 0.5)))
                {
                  closedist = currdist;
                  closetarg = newtarget;
                }
              }
              self = stemp;
            }
          }
          newtarget = find(newtarget,classname,"path_trafficmirror");
        }
        if (closetarg)
        {
          self.goalentity = closetarg;
        }
      }
    }
    else if (self.goalentity.classname == "path_trafficmirror")
    {
      monstervec = self.origin;
      monstervec_z = self.goalentity.origin_z;
      currdist = vlen(self.goalentity.origin-monstervec) - 8;
      if ( enemy_vis || !ClearPathToTarget(self.goalentity) || (currdist <= self.goalentity.distance) )
      {
        self.goalentity = self.enemy;
        #ifdef GAME_HIPNOTIC
          self.endtime = time + 2;
        #endif
      }
      /*#ifdef ENGINE_KEX
        else
        {
          draw_arrow(self.goalentity.origin, self.enemy.origin, COLOR_CYAN, 8, 0.1, FALSE);
          draw_circle(self.goalentity.origin,self.goalentity.distance, COLOR_RED, 0.1, FALSE );
        }
      #endif*/
    }
  #ifdef ENGINE_KEX
  }
  #endif

	enemy_infront = infront(self.enemy);
	enemy_range = range(self.enemy);
	enemy_yaw = vectoyaw(self.enemy.origin - self.origin);

  #ifdef GAME_HIPNOTIC
    //MED
    if (self.th_turn)
    {
      local float angledelta;

      angledelta = fabs(self.angles_y - enemy_yaw);
      if (angledelta > MIN_ANGLE_DELTA)
      {
        self.th_turn();
        return;
      }
    }
  #endif

	if (self.attack_state == AS_MISSILE)
	{
		ai_run_missile ();
		return;
	}
	if (self.attack_state == AS_MELEE)
	{
		ai_run_melee ();
		return;
	}

	if (CheckAnyAttack ())
  {
    return;              // beginning an attack
  }

	if (self.attack_state == AS_SLIDING)
	{
		ai_run_slide ();
		return;
	}

  #ifdef GAME_HIPNOTIC
  if (self.attack_state == AS_DODGING)
  {
    if (visible(self.goalentity)) //Ry: Only do this when the target is visible [10-21-2022]
    {
      ai_run_dodge ();
      return;
    }
  }
  
  #ifndef ENGINE_KEX
    if (self.charmed) //Ry: Charmed monsters now able to jump off ledges when chasing enemies in non-Remaster [07-27-2022]
    {
      if (self.origin_z > self.enemy.origin_z)
      {
        if (self.combat_style == CS_RANGED)
        {
          if (!visible(self.enemy)) //Ry: Ranged monsters will stay on a higher ledge if target is visible
            if (infront(self.enemy))
              TryAutoMonsterJump();
        }
        else
        {
          if (infront(self.enemy))
            TryAutoMonsterJump();
        }
      }
    }
  #endif

  //MED 11/11/96
  if (RUN_STRAIGHT && time > self.endtime)
  {
    RUN_STRAIGHT = 0;
    if (!walkmove (self.angles_y, movedist))
    {
      //Ry: God knows what we ran into, so check if there's a monster or player colliding with us [08-09-2022]
      closetarg = findradius(self.origin,220);
      while (closetarg)
      {
        if ((closetarg != self) && (closetarg.solid == SOLID_SLIDEBOX))
          if (BBoxIntersection(self,closetarg,1))
            break; //Ry: Found something; Break out
        closetarg = closetarg.chain;
      }
      if (!closetarg) //Ry: If nothing is found, assume we hit a wall, and start searching for traffic mirrors [08-09-2022]
        self.wetsuit_time = time + 2;
      self.endtime = time + 2;
      movetogoal (dist);      // done in C code...
    }
  }
  else
  {
  #endif
    #ifdef ENGINE_KEX
    //Ry: Horde monsters, charmed monsters, Gremlins, and Armagon are set to always use pathing [08-01-2022]
    if (self.allowPathFind == USEPATH_ALWAYS)
      ai_pathtogoal(dist);
    else // head straight in
    #endif
      movetogoal (dist);      // done in C code...
  #ifdef GAME_HIPNOTIC
  }
  #endif
};
