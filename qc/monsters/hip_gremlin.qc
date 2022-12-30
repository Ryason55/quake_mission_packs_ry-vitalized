/*
==============================================================================

gremlin

==============================================================================
*/
$cd hipwork\models\grem
$origin 0 0 23
$scale 2
$base grembase.asc

$skin grem

$frame stand1.asc stand2.asc stand3.asc stand4.asc stand5.asc stand6.asc
$frame stand7.asc stand8.asc stand9.asc stand10.asc stand11.asc stand12.asc
$frame stand13.asc stand14.asc stand15.asc stand16.asc stand17.asc

$frame walk1.asc walk2.asc walk3.asc walk4.asc walk5.asc walk6.asc
$frame walk7.asc walk8.asc walk9.asc walk10.asc walk11.asc walk12.asc

$frame run1.asc run2.asc run3.asc run4.asc run5.asc run6.asc run7.asc run8.asc
$frame run9.asc run10.asc run11.asc run12.asc run13.asc run14.asc run15.asc

$frame jump1.asc jump2.asc jump3.asc jump4.asc jump5.asc jump6.asc jump7.asc
$frame jump8.asc jump9.asc jump10.asc jump11.asc jump12.asc jump13.asc jump14.asc
$frame jump15.asc jump16.asc

$frame attk1.asc attk2.asc attk3.asc attk4.asc attk5.asc attk6.asc
$frame attk7.asc attk8.asc attk9.asc attk10.asc attk11.asc

$frame maul1.asc maul2.asc maul3.asc maul4.asc maul5.asc maul6.asc
$frame maul7.asc maul8.asc maul9.asc maul10.asc maul11.asc maul12.asc maul13.asc

$frame spawn1.asc spawn2.asc spawn3.asc spawn4.asc spawn5.asc spawn6.asc

$frame look1.asc look2.asc look3.asc look4.asc look5.asc look6.asc look7.asc
$frame look8.asc look9.asc look10.asc

$frame pain1.asc pain2.asc pain3.asc pain4.asc

$frame death1.asc death2.asc death3.asc death4.asc death5.asc death6.asc death7.asc
$frame death8.asc death9.asc death10.asc death11.asc death12.asc

$frame flip1.asc flip2.asc flip3.asc flip4.asc flip5.asc flip6.asc flip7.asc
$frame flip8.asc

$frame lunge1.asc lunge2.asc lunge3.asc lunge4.asc lunge5.asc lunge6.asc lunge7.asc
$frame lunge8.asc lunge9.asc lunge10.asc lunge11.asc

$frame gfire1.asc gfire2.asc gfire3.asc gfire4.asc gfire5.asc gfire6.asc

$frame glook1.asc glook2.asc glook3.asc glook4.asc glook5.asc glook6.asc glook7.asc
$frame glook8.asc glook9.asc glook10.asc glook11.asc glook12.asc glook13.asc 
$frame glook14.asc glook15.asc glook16.asc glook17.asc glook18.asc glook19.asc glook20.asc

$frame gpain1.asc gpain2.asc gpain3.asc

$frame grun1.asc grun2.asc grun3.asc grun4.asc grun5.asc grun6.asc grun7.asc
$frame grun8.asc grun9.asc grun10.asc grun11.asc grun12.asc grun13.asc grun14.asc grun15.asc

//============================================================================



//======================
//  New Subs by Ryason
//======================

void() gremlin_look1;

float(entity target) Gremlin_TargetGorgable =
{
  if ( target && ((target.health <= 0) || ((target.classname == "monster_zombie") && !target.solid)) )
    return TRUE;
  return FALSE;
}

//Ry: gorging, stoleweapon, and stealitem are now all handled through this
void(float newstate) Gremlin_UpdateState =
{
  if (self.gremstate != newstate)
  {
    /*dprint("Gremlin with state ");
    dprint(ftos(self.gremstate));
    dprint(" updating to state ");
    dprint(ftos(newstate));
    dprint("\n");
    if (self.enemy)
    {
      dprint(" Enemy: ");
      dprint(self.enemy.classname);
      dprint(" (");
      dprint(self.enemy.netname);
      dprint(")\n");
    }
    if (self.goalentity)
    {
      dprint(" Goal: ");
      dprint(self.goalentity.classname);
      dprint(" (");
      dprint(self.goalentity.netname);
      dprint(")\n");
    }*/
    self.delay = 0;
    if (newstate == GREM_GORGING)
    {
      if ( !Gremlin_TargetGorgable(self.enemy) )
      {
        dprint("Gremlin tried to enter GORGING state for target with positive health\n");
        self.gremstate = GREM_DEFAULT;
        return;
      }
    }
    else if (newstate == GREM_STEALITEM)
    {
      if ( ( !self.goalentity ) || ((self.goalentity.solid != SOLID_TRIGGER) && !(self.goalentity.flags & (FL_CLIENT|FL_MONSTER))) || ((self.goalentity.classname != "player") && (self.goalentity.flags & (FL_CLIENT|FL_MONSTER))) )
      {
        dprint("Gremlin tried to enter STEALITEM state with invalid target\n");
        self.gremstate = GREM_DEFAULT;
        self.goalentity = self.enemy;
        return;
      }
    }
    else if (newstate >= GREM_ARMED)
    {
      if ( !self.weapon )
      {
        if (newstate == GREM_ARMED)
          dprint("Gremlin tried to enter ARMED state without a weapon\n");
        else
          dprint("Gremlin tried to enter ARMEDRETREAT state without a weapon\n");
        self.gremstate = GREM_DEFAULT;
        self.currentammo = 0;
        self.combat_style = CS_MELEE;
        return;
      }
    }

    if (self.gremstate == GREM_DEFAULT)
    {
      if (self.huntingcharmer)
        self.huntingcharmer = 0;
    }
    else if (self.gremstate == GREM_GORGING)
    {
      self.enemy = world;
      self.goalentity = world;
    }
    else if (self.gremstate == GREM_STEALITEM)
    {
      if (self.goalentity && (self.goalentity.flags & FL_ITEM))
      {
        self.goalentity.gremstate = GREM_DEFAULT;
        self.goalentity = entity_null;
      }
    }
    else if (self.gremstate >= GREM_ARMED)
    {
      if ( !(newstate >= GREM_ARMED) )
      {
        self.weapon = 0;
        self.currentammo = 0;
        self.combat_style = CS_MELEE;
      }
    }
    self.gremstate = newstate;
    if (newstate >= GREM_ARMED)
      self.combat_style = CS_RANGED;
  }
}

//Ry: Stop trying to gorge and return to normal operation
void(float running) Gremlin_AbandonGorge =
{
  self.wait = time + 5;
  Gremlin_UpdateState(GREM_DEFAULT);
  if ( self.oldenemy.health > 0 )
  {
    self.enemy = self.oldenemy;
    HuntTarget ();
    if (!running)
      self.th_run();
    return;
  }
  self.enemy = entity_null;
  if (self.movetarget)
     self.th_walk ();
  else
     self.th_stand ();
};

//Ry: Standalone function for storing weapon
void() GremlinStoreWeapon =
{
  self.weapon = 0;
  self.currentammo = 0;
  Gremlin_UpdateState(GREM_DEFAULT);
  self.combat_style = CS_MELEE;
};

void() GremlinAbandonItem =
{
  Gremlin_UpdateState(GREM_DEFAULT);
  if (self.enemy)
  {
    self.goalentity = self.enemy;
    self.th_run();
  }
  else if (!self.huntingcharmer)
  {
    self.goalentity = world;
    self.th_stand();
  }
  self.wait = time + 1;
}

void() ItemCollectedByGremlin =
{
  local entity stemp;
  if (other.goalentity == self)
  {
    stemp = self;
    self = other;
    GremlinAbandonItem();
    if (self.enemy)
      FoundTarget();
    self = stemp;
  }
}

float(entity item) GremlinCanStealItem = //Ry: Checks for specific items
{
  if (!self.super_item) //Ry: Can only steal one weapon item in campaign
  {
    if (item.classname == "weapon_supershotgun")
    {
      if (!(self.items & IT_SUPER_SHOTGUN))
        return TRUE;
    }
    else if (item.classname == "weapon_nailgun")
    {
      if (!(self.items & IT_NAILGUN))
        return TRUE;
    }
    else if (item.classname == "weapon_supernailgun")
    {
      if (!(self.items & IT_SUPER_NAILGUN))
        return TRUE;
    }
    else if (item.classname == "weapon_grenadelauncher")
    {
      if (!(self.items & IT_GRENADE_LAUNCHER))
        return TRUE;
    }
    else if (item.classname == "weapon_rocketlauncher")
    {
      if (!(self.items & IT_ROCKET_LAUNCHER))
        return TRUE;
    }
    else if (item.classname == "weapon_proximity_gun")
    {
      if (!(self.items & IT_PROXIMITY_GUN))
        return TRUE;
    }
    else if (item.classname == "weapon_lightning")
    {
      if (!(self.items & IT_LIGHTNING))
        return TRUE;
    }
    else if (item.classname == "weapon_laser_gun")
    {
      if (!(self.items & IT_LASER_CANNON))
        return TRUE;
    }
  }
  if (self.items > 0) //Ry: Only check ammo when has a gun
  {
    if (item.classname == "item_shells")
    {
      if ((self.items & (IT_SHOTGUN|IT_SUPER_SHOTGUN)) && (self.AMMO_SHELLS < 100))
        return TRUE;
    }
    else if (item.classname == "item_nails")
    {
      if ((self.items & (IT_NAILGUN|IT_SUPER_NAILGUN)) && (self.AMMO_NAILS < 200))
        return TRUE;
    }
    else if (item.classname == "item_rockets")
    {
      if ((self.items & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER|IT_PROXIMITY_GUN)) && (self.AMMO_ROCKETS < ammocap_rockets))
        return TRUE;
    }
    else if (item.classname == "item_cells")
    {
      if ((self.items & (IT_LIGHTNING|IT_LASER_CANNON)) && (self.AMMO_CELLS < 100))
        return TRUE;
    }
  }
  if (item.classname == "item_backpack" && !item.owner) //Ry: Only go for backpacks if it would enable weapon usage, and don't pursue protected backpacks
  {
    if ( ((self.AMMO_SHELLS + item.AMMO_SHELLS) > 0) )
    {
      if ( (item.items & (IT_SHOTGUN|IT_SUPER_SHOTGUN)) || (self.items & (IT_SHOTGUN|IT_SUPER_SHOTGUN)) )
        return TRUE;
    }
    if ( ((self.AMMO_NAILS + item.AMMO_NAILS) > 0) )
    {
      if ( (item.items & (IT_NAILGUN|IT_SUPER_NAILGUN)) || (self.items & (IT_NAILGUN|IT_SUPER_NAILGUN)) )
        return TRUE;
    }
    if ( ((self.AMMO_ROCKETS + item.AMMO_ROCKETS) > 0) )
    {
      if ( (item.items & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER|IT_PROXIMITY_GUN)) || (self.items & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER|IT_PROXIMITY_GUN)) )
        return TRUE;
    }
    if ( ((self.AMMO_CELLS + item.AMMO_CELLS) > 0) )
    {
      if ( (item.items & (IT_LIGHTNING|IT_LASER_CANNON)) || (self.items & (IT_LIGHTNING|IT_LASER_CANNON)) )
        return TRUE;
    }
  }
  return FALSE;
}

float() GremlinFindItem = //Ry: So Gremlins search out weapons after they've sighted the player
{
  local entity  head;
  local float   result;
  local entity  steal;
  local float   dist;
  local vector  goalvect;

  if ( grem_itemstealallowed && (!self.gremstate) && ((self.enemy.health > 0) || self.charmed) && (time > self.wait) )
  {
    dist = 400;
    steal = world;

    head = nextent(world);
    while (head!=world)
    {
      if ( (head.solid == SOLID_TRIGGER) && (!head.gremstate) && (head.weapon || head.items) )
      {
        result = 0;
        if ( !(deathmatch || self.charmed) && self.enemy ) //Ry: Check if item isn't too far above enemy in SP/Co-op
          result = head.origin_z - self.enemy.origin_z;
        if ( result < 100 )
        {
          if ( GremlinCanStealItem(head) )
          {
            goalvect = head.origin;
            goalvect_z = goalvect_z + head.maxs_z;
            traceline(self.origin, goalvect, TRUE, self);
            result = fabs(head.origin_z - self.origin_z);
            if ( (trace_fraction >= 1.0) && result<80 )
            {
              if ( (visible(head)) && (visible_distance<dist) )
              {
                dist = visible_distance;
                steal = head;
              }
            }
          }
        }
      }
      head = nextent(head);
    }
    if ((steal != world) && (dist < 400))
    {
      self.wait = time + 1;
      if ( self.charmed && (self.enemy == entity_null) ) //Ry: Charmed Gremlins can go for items when they have no foe
      {
        self.goalentity = steal;
        if (!deathmatch) //Ry: In SP/Co-op, make sure another Gremlin won't go for the item
          steal.gremstate = GREM_STEALITEM;
        Gremlin_UpdateState(GREM_STEALITEM);
        return TRUE;
      }
      if ( (!visible(self.enemy)) || (dist <= visible_distance) ) //Ry: Only go for the item if its closer than current foe, or foe is out of sight
      {
        self.goalentity = steal;
        if (!deathmatch)
          steal.gremstate = GREM_STEALITEM;
        Gremlin_UpdateState(GREM_STEALITEM);
        return TRUE;
      }
    }
  }
  return FALSE;
}

void() Gremlin_FireGrenade = //Similar to Ogres, but player damage, and random firing cone
{
	local	entity missile;
  local vector dir;
  local float conemul;

  self.currentammo = self.AMMO_ROCKETS = self.AMMO_ROCKETS - 1;
	self.effects = self.effects | EF_MUZZLEFLASH;

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	missile = spawn ();

//JIM
	missile.classname = "grenade";

	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;

// set missile speed

  if (self.charmed)
    conemul = 0.05;
  else
    conemul = 0.1;

  dir = normalize(self.enemy.origin - self.origin);
  self.v_angle = vectoangles(dir);
  makevectors(self.v_angle);
  dir = dir + crandom()* conemul *v_right + crandom()* conemul *v_up;
  dir = normalize(dir);
  missile.velocity = dir * 600;
	missile.velocity_z = 200;

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);

  if (skill > 0 || copper_nightmare || deathmatch)
  {
    missile.touch = GrenadeTouch;
    missile.nextthink = time + 2.5;
    missile.think = GrenadeExplode;
    if (!deathmatch)
      SetLightEffect(missile,SET_EF_CANDLE,TRUE); //Ry: Projectile glows to indicate player damage
  }
  else
  {
    missile.touch = OgreGrenadeTouch;
    missile.nextthink = time + 2.5;
    missile.think = OgreGrenadeExplode;
  }

	setmodel (missile, "progs/grenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};

//Ry: Checks if current gorge target is still valid to gorge while in the process of gorging
float(float loopcheck) Gremlin_GorgeValid =
{
  //Ry: Gorge target has either come back to life, or is a bodyque that got whisked away for another player's death
  if ( !Gremlin_TargetGorgable(self.enemy) || ((self.enemy.classname == "bodyque") && (!(visible(self.enemy)) || visible_distance > 128)) )
  {
    Gremlin_AbandonGorge(FALSE);
    return FALSE;
  }
  //Ry: Another Gremlin has finished the gorge
  if ( (self.enemy.health < -200.0) || (self.enemy.gremstate == GREM_GORGING) )
  {
    self.enemy = world;
    Gremlin_UpdateState(GREM_DEFAULT);
    gremlin_look1();
    return FALSE;
  }
  //Ry: Gremlin has no need to continue gorging
  if (loopcheck && (NumSpawnGremlins >= (NumGremlins*2)) && (self.health >= self.max_health) && (self.enemy.health < 0) )
  {
    self.enemy = world;
    Gremlin_UpdateState(GREM_DEFAULT);
    gremlin_look1();
    return FALSE;
  }
  return TRUE;
}

//===================
//  End of new subs
//===================



/*
===========
GremlinAttemptWeaponSteal

see if we can steal enemy's weapon

============
*/
entity()GremlinFindVictim;
float() GremlinFindTarget;

float() GremlinAttemptWeaponSteal =
{
  local vector delta;
  local entity tempself;
  local float best;
  local entity victim;
  local float amount;
  local string message;
  local float weaponstolen;
  local entity head;

  if (self.gremstate >= GREM_ARMED)
  {
    dprint("Gremlin tried to steal a weapon again\n");
    return FALSE;
  }

  //Ry: Gremlins can now steal from other Gremlins
  if ( !( (self.enemy.flags & FL_CLIENT) || ((self.enemy.classname == "monster_gremlin") && self.enemy.weapon) ) )
  {
    return FALSE;
  }

  delta = (self.enemy.origin - self.origin);

  if (vlen(delta) > 100)
    return FALSE;
  if (!deathmatch && (skill < 3 || copper_nightmare) && random() < 0.5) //Ry: Always steal on Nightmare/DM
    return FALSE;
  //
  // we are within range so lets go for it
  //
  victim = self.enemy;
  best = victim.weapon;
  if (best == IT_AXE || best == IT_SHOTGUN || best == IT_MJOLNIR)
    return FALSE;
  if ( !(self.items & best) ) //Ry: Only steal the weapon if the Gremlin doesn't already have it
  {
    // take that weapon from the entity
    victim.items = victim.items - (victim.items & best);

    if ( (victim.flags & FL_CLIENT) && !(victim.stolenitems & best) ) //Ry: Mark off that the player is now missing this weapon
    {
      victim.stolenitems = victim.stolenitems + best;
      if ( !(self.stolenitems & best) ) //Ry: And indicate on the Gremlin that this weapon was stolen
        self.stolenitems = self.stolenitems + best;
    }
    else if ( (victim.classname == "monster_gremlin") )
    {
      if ( victim.super_item && (victim.super_item.weapon == best) ) //Ry: If weapon was a picked item, transfer it over to the new Gremlin
      {
        self.super_item = victim.super_item;
        victim.super_item = entity_null;
      }
      else if ( (victim.stolenitems & best) ) //Ry: Otherwise, transfer the stolen state of the weapon
      {
        victim.stolenitems = victim.stolenitems - best;
        if ( !(self.stolenitems & best) )
          self.stolenitems = self.stolenitems + best;
      }
    }

    // give it to our gremlin
    self.items = self.items | best;
    weaponstolen = TRUE;
  }
  self.weapon = best;

  //Ry: Play pickup sound as an indicator [12-10-2022]
  if (weaponstolen)
    sound (self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
  else
    sound (self, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);

  // take some ammo while we are at it
  self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS ) );
  if ( best & IT_SUPER_SHOTGUN )
  {
    amount = victim.AMMO_SHELLS;
    if (amount > 20)
      amount = 20;
    victim.AMMO_SHELLS = victim.AMMO_SHELLS - amount;
    self.AMMO_SHELLS = self.AMMO_SHELLS + amount;
	  self.items = self.items | IT_SHELLS;
    self.currentammo = self.AMMO_SHELLS;
    if (weaponstolen)
      message = "Gremlin stole your Double-barreled Shotgun\n"; //Ry: Updated name from "Super Shotgun", for consistency
    else
    {
      if (victim.AMMO_SHELLS <= 0) //Ry: Now can steal ammo if they already have the weapon
      {
        message = "Gremlin stole your remaining Shells\n";
        weaponstolen = TRUE;
      }
      else
        message = "Gremlin stole some Shells\n";
    }
  }
  else if ( best & (IT_NAILGUN|IT_SUPER_NAILGUN) )
  {
    amount = victim.AMMO_NAILS;
    if (amount > 40)
      amount = 40;
    victim.AMMO_NAILS = victim.AMMO_NAILS - amount;
    self.AMMO_NAILS = self.AMMO_NAILS + amount;
    self.items = self.items | IT_NAILS;
    self.currentammo = self.AMMO_NAILS;
    if (weaponstolen)
    {
      if (best == IT_NAILGUN)
        message = "Gremlin stole your Nailgun\n";
      else
        message = "Gremlin stole your Super Nailgun\n";
    }
    else
    {
      if (victim.AMMO_NAILS <= 0)
      {
        message = "Gremlin stole your remaining Nails\n";
        weaponstolen = TRUE;
      }
      else
        message = "Gremlin stole some Nails\n";
    }
  }
  else if ( best & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER|IT_PROXIMITY_GUN) )
  {
    amount = victim.AMMO_ROCKETS;
    if (amount > 5)
      amount = 5;
    victim.AMMO_ROCKETS = victim.AMMO_ROCKETS - amount;
    self.AMMO_ROCKETS = self.AMMO_ROCKETS + amount;
    self.items = self.items | IT_ROCKETS;
    self.currentammo = self.AMMO_ROCKETS;
    if (weaponstolen)
    {
      if (best == IT_ROCKET_LAUNCHER)
        message = "Gremlin stole your Rocket Launcher\n";
      else if (best == IT_GRENADE_LAUNCHER)
        message = "Gremlin stole your Grenade Launcher\n";
      else
        message = "Gremlin stole your Proximity Gun\n";
    }
    else
    {
      if (victim.AMMO_ROCKETS <= 0)
      {
        message = "Gremlin stole your remaining Rockets\n";
        weaponstolen = TRUE;
      }
      else
        message = "Gremlin stole some Rockets\n";
    }
  }
  else if ( best & (IT_LIGHTNING|IT_LASER_CANNON) )
  {
    amount = victim.AMMO_CELLS;
    if (amount > 40)
      amount = 40;
    victim.AMMO_CELLS = victim.AMMO_CELLS - amount;
    self.AMMO_CELLS = self.AMMO_CELLS + amount;
    self.items = self.items | IT_CELLS;
    self.currentammo = self.AMMO_CELLS;
    if (weaponstolen)
    {
      if (best == IT_LIGHTNING)
        message = "Gremlin stole your Thunderbolt\n"; //Ry: This was "Lightning Gun"
      else
        message = "Gremlin stole your Laser Cannon\n";
    }
    else
    {
      if (victim.AMMO_CELLS <= 0)
      {
        message = "Gremlin stole your remaining Cells\n";
        weaponstolen = TRUE;
      }
      else
        message = "Gremlin stole some Cells\n";
    }
  }
  
  // tag the gremlin as having stolen a weapon
  Gremlin_UpdateState(GREM_ARMEDRETREAT);
  self.attack_finished = time;
  tempself = self;
  amount = 0;

  //Ry: Incite other Gremlins nearby to also try and steal from the player on Normal+
  if ( ((skill > 0) || copper_nightmare || deathmatch) && (victim.classname == "player") )
  {
    head = findradius(victim.origin, 100);
    while (head)
    { //Ry: Must be on same team, and have same target
      if ( (head.classname == "monster_gremlin") && (head.health > 0) && (head.team == self.team) && (head.goalentity == victim) )
      {
        if ( head.gremstate == GREM_STEALITEM )
          amount = amount + 1;
        else if ( !head.gremstate )
        {
          amount = amount + 1;
          self = head;
          Gremlin_UpdateState(GREM_STEALITEM);
          self = tempself;
        }
      }
      head = head.chain;
    }
  }

  self = victim;
  if (self.flags & FL_CLIENT)
  {
    if (message) //Ry: Steal message happens here now
      sprint (victim,message);
    if (weaponstolen) //Ry: If a weapon was stolen, or if all ammo for the weapon was stolen
    {
      if ( (amount > 0) || ((skill < 3) || copper_nightmare) ) //Ry: Gremlins change you to the Shotgun/Axe on Nightmare, unless there's other Gremlins that can steal
        self.weapon = W_BestWeapon ();
      else if ( self.AMMO_SHELLS > 0 )
        self.weapon = IT_SHOTGUN;
      else
        self.weapon = IT_AXE;
      W_SetCurrentAmmo ();
    }
    else //Ry: Only update ammo otherwise
    {
      W_UpdateAmmo();
    }
  }
  else //Ry: Gremlin stolen from
  {
    self.weapon = W_BestWeapon();
    if (self.weapon == IT_AXE)
      GremlinStoreWeapon();
    W_UpdateAmmo();
  }
  self = tempself;

  // don't fire the first shot at the person we stole the weapon from
  // all the time
  if (random()>0.65)
    self.lastvictim = victim;
  else
    self.lastvictim = self;
//  self.attack_state = AS_STRAIGHT;
  // find a recipient
  victim = GremlinFindVictim();
  if (victim != world)
  {
    self.enemy = victim;
    FoundTarget();
    self.attack_finished = time;
    self.search_time = AttackRecoil(self,1.0);
  }

  return TRUE;
};
//============================================================================

/*
===========
GremlinFindTarget

gremlin is currently not attacking anything, so try to find a target

============
*/
float() GremlinFindTarget =
{
  local entity   head;
  local entity   gorge;
  local entity   stemp;
  local float    dist;
  local float    result;
  local float    avoidsight;

  //Ry: Now only gorge if within the spawn limit, or the Gremlin wants a health boost
  if ( (!self.gremstate) && time > self.wait && ((NumSpawnGremlins < (NumGremlins*2)) || self.health < 100) )
  {
    self.wait = AttackRecoil(self,1.0);
    dist = 2000;
    if (self.charmed) //Ry: More contained when charmed
      dist = 300;
    if (self.enemy) //Ry: Prefer gorging if the corpse is closer than the enemy, or the enemy is out of sight
    {
      if (visible(self.enemy) && visible_distance < dist)
      {
        dist = visible_distance; //Ry: Cap search distance at enemy distance
        if (visible_distance < 100) //Ry: And don't gorge if the enemy is too close
          result = 1;
      }
    }
    if (!result)
    {
      gorge = world;
      head = nextent(world);
      stemp = self;
      avoidsight = ( ((skill > 0) || copper_nightmare || deathmatch) && (self.health > 30) );
      while (head!=world)
      {
        //Ry: Also look for (non-head) Bodyques
        if ((head.health < 1) && (head.health >= -200) && (!head.gremstate) && ((head.flags & (FL_MONSTER|FL_CLIENT)) || ((head.classname == "bodyque") && head.model )) )
        {
          result = fabs(head.origin_z - self.origin_z);
          if ((visible(head)) && (result<80) && (visible_distance<dist))
          {
            dist = visible_distance;
            gorge = head;
          }
        }
        else if ( avoidsight && (head.flags & FL_CLIENT) && (head.health > 0) && (head.team != self.team) ) //Ry: When at decent health, check if any enemy players are looking at the Gremlin
        {
          self = head;
          if (visible(stemp))
          {
            if (infront(stemp))
            {
              self = stemp; //Ry: If so, bail
              gorge = world;
              break;
            }
          }
          self = stemp;
        }
        head = nextent(head);
      }
      if ((gorge != world) && (dist < (700*random())))
      {
  //      dprint("starting to gorge on ");
  //      dprint(gorge.classname);
  //      dprint("\n");
        self.oldenemy = self.enemy;
        self.enemy = gorge;
        self.search_time = AttackRecoil(self,4.0);
        SightSound(); //Ry: Do these instead of FoundTarget
        HuntTarget();
        Gremlin_UpdateState(GREM_GORGING);
        return TRUE;
      }
      
    }
  }
  else if (self.gremstate >= GREM_ARMED)
  {
    head = GremlinFindVictim();
    if (head != world)
    {
      self.enemy = head;
      FoundTarget();
      self.attack_finished = time;
      self.search_time = AttackRecoil(self,2.0);
      return TRUE;
    }
  }
  result = FindTarget();
  self.search_time = AttackRecoil(self,2.0);
  return result;
};
//============================================================================
/*
=============
gremlin_walk

The monster is walking it's beat
=============
*/
void(float dist) gremlin_walk =
{
  if ( self.watertype == CONTENT_LAVA ) //Ry: Die when walking in lava too
  {
    T_Damage (self, world, world, 2000);
    return;
  }

  if ( !deathmatch )
    RecordSafeVect(); //Ry: Record safe position for backpacks to warp to

  if (self.gremstate >= GREM_ARMED) //Ry: Put away weapon when walking (Such as when charmed)
    GremlinStoreWeapon();
  movedist = dist;
  
  if (self.charmed) //Ry: Charmed Gremlins also look for items
  {
    if ( GremlinFindItem() )
    {
      SightSound();
      self.th_run();
      return;
    }
  }

  // check for noticing a player
  if ( GremlinFindTarget())
    return;

  if ( self.huntingcharmer ) //Ry: Double walking speed when following charmer
    self.nextthink = time + ((self.nextthink - time)/2);

	ai_pathtogoal(dist); //Ry: Use nav pathing instead
};

//============================================================================

/*
=============
gremlin_stand

The monster is staying in one place for a while, with slight angle turns
=============
*/
void() gremlin_stand =
{
  if (GremlinFindTarget ()) //Ry: This was only "FindTarget" before
    return;

	if (time > self.pausetime)
  {
		self.th_walk ();
		return;
  }
};

//============================================================================
float() GremlinHasAmmo;
void() gremlin_glook1;
/*
=============
gremlin_run

The monster has an enemy it is trying to kill
=============
*/
void(float dist) gremlin_run =
{
  local float r, pathstatus, clearpath;
  local vector d, vec1, vec2;

  if (self.watertype == CONTENT_LAVA)
  {  // do damage
    T_Damage (self, world, world, 2000);
    return; //Ry: Break out of this instead of allowing further behaviour
  }
  
  if (!deathmatch)
    RecordSafeVect(); //Ry: Record safe position for backpacks to warp to
  
  movedist = dist;
  if (self.gremstate >= GREM_ARMED)
  {
    self.frame = self.frame + $grun1.asc - $run1.asc;
  }
  else
    GremlinFindItem(); //Ry: Gremlin will attempt to find stealable weapon items when engaging the player

  if (self.gremstate == GREM_GORGING) //Ry: [TODO] This and the next condition are pretty similar with some different values/checks; Could probably be condensed in some way
  {
    if (!Gremlin_TargetGorgable(self.enemy) || self.enemy.gremstate) //Ry: Abort if target is alive or has already been gorged
    {
      Gremlin_UpdateState(GREM_DEFAULT);
      if (!GremlinFindTarget())
        self.th_stand();
      return;
    }
      
    //Ry: Check if close enough to the corpse to go straight at it
    clearpath = TRUE;
    r = vlen(self.enemy.origin - self.origin);
    if (r < 130)
    {
      ai_face();
      if (r < 45)
      {
        self.th_melee ();
        self.attack_state = AS_STRAIGHT;
        return;
      }
      else
      {
        clearpath = walkmove (self.angles_y, dist);
        if (clearpath) //Ry: Try moving straight; If fails, continue
          return;
      }
    }

    if (clearpath)
    { //Ry: See if the Gremlin has a straight shot at what they want
      traceline(self.origin, self.enemy.origin, TRUE, self);
      if ( (trace_fraction != 1.0) )
        clearpath = FALSE;
      else if ( !visible(self.enemy) )
        clearpath = FALSE;
      else if ( fabs(self.enemy.origin_z - self.origin_z) >= 80 )
        clearpath = FALSE;
      else //Ry: Check for any pits in the way
      {
        d = (self.enemy.origin-self.origin);
        r = vlen(d);
        d = normalize(d);
        vec1 = self.origin;
        while (r > 0)
        {
          vec1 = vec1 + (d * 32);
          vec2 = vec1;
          vec2_z = (self.origin_z + self.mins_z) - 16;
          traceline(vec1,vec2,TRUE,self);
          if (trace_fraction >= 1.0)
          {
            clearpath = FALSE;
            break;
          }
          r = r - 32;
        }
      }
    }

    #ifdef ENGINE_KEX
      //Ry: If there isn't a clear path, use bot navs to path to the item
      if (!clearpath && time >= self.navcooldowntime)
      {
        pathstatus = walkpathtogoal( dist, self.goalentity.origin );
        if ( pathstatus == PATH_IN_PROGRESS ) //Ry: Return if pathing succeeds
        {
          if (time >= self.super_time) //Ry: A monster butting up against a wall/obstacle seems to have PATH_IN_PROGRESS come up on some frames, so this timer is to account for that
            self.delay = AttackRecoil(self,2);
          return;
        }
        else if (pathstatus == PATH_REACHED_PATH_END) //Ry: Gremlin can now path directly to the target
        {
          self.navcooldowntime = AttackRecoil(self,3);
        }
        else if (pathstatus == PATH_ERROR) //Ry: No navs, not near node, or no path to target
        {
          self.delay = 0;
          self.navcooldowntime = AttackRecoil(self,1);
        }
        else //Ry: Gremlin is blocked by something
        {
          self.super_time = AttackRecoil(self,0.5);
          if (!self.delay) //Ry: Amount of time before giving up on navigation
            self.delay = AttackRecoil(self,2);
        }
      }
    #endif

    //Ry: If delay time is exceeded and there's no clear path, abort
    if (!clearpath && (time >= self.delay))
    {
      Gremlin_AbandonGorge(TRUE);
      return;
    }

    //Ry: Path normally
    if (pathstatus < PATH_IN_PROGRESS)
    {
      movetogoal(dist);
    }
  }
  else if ( (self.gremstate == GREM_STEALITEM) && !(self.goalentity.flags & (FL_MONSTER|FL_CLIENT)) ) //Ry: Head towards desired item
  {
    if ( (self.goalentity == world) || (self.goalentity.solid != SOLID_TRIGGER) || (self.goalentity.gremstate >= GREM_ARMED) ) //Ry: Desired item collected
    {
      GremlinAbandonItem();
      return;
    }

    clearpath = TRUE;

    //Ry: Check if close enough to the item to go straight at it
    if (time >= self.lastfragtime)
    {
      d = ((self.goalentity.origin + self.goalentity.view_ofs) - self.origin);
      r = vlen(d);
      if (r < 130)
      {
        self.ideal_yaw = vectoyaw(normalize(d));
        ChangeYaw ();
        clearpath = walkmove (self.angles_y, dist);
        if (clearpath) //Ry: Try moving straight; If fails, continue
          return;
        self.lastfragtime = AttackRecoil(self,1); //Ry: If this fails, set a delay before trying again
      }
    }

    if (clearpath)
    { //Ry: See if the Gremlin has a straight shot at what they want
      d = self.goalentity.origin + self.goalentity.view_ofs;
      d_z = d_z + self.goalentity.maxs_z;
      traceline(self.origin, d, TRUE, self);
      if (trace_fraction < 1.0)
        clearpath = FALSE;
      else if ( fabs( self.goalentity.origin_z - (self.origin_z+self.mins_z) ) > 40 )
        clearpath = FALSE;
      else //Ry: Check for any pits in the way
      {
        d = (d-self.origin);
        r = vlen(d);
        d = normalize(d);
        vec1 = self.origin;
        while (r > 0)
        {
          vec1 = vec1 + (d * 32);
          vec2 = vec1;
          vec2_z = (self.origin_z + self.mins_z) - 16;
          traceline(vec1,vec2,TRUE,self);
          if (trace_fraction >= 1.0)
          {
            clearpath = FALSE;
            break;
          }
          r = r - 32;
        }
      }
    }

    #ifdef ENGINE_KEX
      //Ry: If there isn't a clear path, use bot navs to path to the item
      if (!clearpath && time >= self.navcooldowntime)
      {
        r = walkpathtogoal( dist, self.goalentity.origin );
        if ( r == PATH_IN_PROGRESS ) //Ry: Return if pathing succeeds
        {
          if (time >= self.super_time) //Ry: A monster butting up against a wall/obstacle seems to have PATH_IN_PROGRESS come up on some frames, so this timer is to account for that
            self.delay = AttackRecoil(self,2);
          return;
        }
        else if (r == PATH_REACHED_PATH_END) //Ry: Gremlin can now path directly to the item
        {
          self.navcooldowntime = AttackRecoil(self,3);
        }
        else if (r == PATH_ERROR) //Ry: No navs, not near node, or no path to item
        {
          self.delay = 0;
          self.navcooldowntime = AttackRecoil(self,1);
        }
        else //Ry: Gremlin is blocked by something
        {
          self.super_time = AttackRecoil(self,0.5);
          if (!self.delay) //Ry: Amount of time before giving up on navigation
            self.delay = AttackRecoil(self,2);
        }
      }
    #endif

    //Ry: If delay time is exceeded and there's no clear path, abort
    if (!clearpath && (time >= self.delay))
    {
      GremlinAbandonItem();
      return;
    }

    //Ry: Path normally
    if (pathstatus < PATH_IN_PROGRESS)
    {
      movetogoal(dist);
    }
  }
  else
  {
    if (random()>0.97)
    {
      if (GremlinFindTarget())
        return;
    }
    // get away from player if we stole a weapon
    if (self.gremstate >= GREM_ARMED)
    {
      if (self.enemy.health <= 0 && self.enemy.classname == "player")
      {
        gremlin_glook1();
        return;
      }
      if (!GremlinHasAmmo())
      {
        if (self.t_length==1)
        {
          if (self.trigger_field) //Ry: Clean up the goal target entity
          {
            remove(self.trigger_field);
            self.trigger_field = world; //Ry: And be sure to unreference it so there aren't stale reference issues
          }
          self.goalentity = self.enemy;
          self.t_length = 0;
        }
        return;
      }
      r = vlen(self.enemy.origin - self.origin);
      d = normalize(self.origin-self.enemy.origin);
      if (self.t_length == 0)
      { //Ry: Keep distance either when initially stealing, or when using an explosive weapon
        if (r<150 && ((self.gremstate == GREM_ARMEDRETREAT) || (self.weapon == IT_ROCKET_LAUNCHER) || (self.weapon == IT_GRENADE_LAUNCHER) || (self.weapon == IT_PROXIMITY_GUN)) )
        {
          if (!self.trigger_field)
          {
            self.trigger_field = spawn();
            self.trigger_field.classname = "gremtarget";
          }
          setsize(self.trigger_field,'-1 -1 -1','1 1 1');
          self.t_length = 1;
        }
      }
      if (self.t_length==1)
      {
        if (r > 250)
        {
          if (self.trigger_field) //Ry: Clean up the goal target entity
          {
            remove(self.trigger_field);
            self.trigger_field = world; //Ry: And be sure to unreference it so there aren't stale reference issues
          }
          self.goalentity = self.enemy;
          self.t_length = 0;
          Gremlin_UpdateState(GREM_ARMED);
        }
        else
        {
          if (r < 160)
          {
            local vector ang;
            local float done;
            local vector end;
            local float c;

            ang = vectoangles(d);
            done = 0;
            c = 0;
            while (done == 0)
            {
              makevectors(ang);
              end = self.enemy.origin + v_forward * 350;
              traceline(self.enemy.origin,end,FALSE,self);
              if (trace_fraction == 1.0)
              {
                traceline(self.origin,end,FALSE,self);
                if (trace_fraction == 1.0)
                  done = 1;
              }
              ang_y = anglemod(ang_y + 36);
              c = c + 1;
              if (c == 10)
              {
                done = 1;
              }
            }
            setorigin(self.trigger_field,end);
          }
          self.goalentity = self.trigger_field;
          self.ideal_yaw = vectoyaw(normalize(self.goalentity.origin-self.origin));
          ChangeYaw ();
          movetogoal(dist);
          self.nextthink = AttackRecoil(self,0.1);
          return;
        }
      }
    }
    else //Ry: Draw weapon if there's ammo
    {
      if (self.enemy.health > 0)
        GremlinHasAmmo();
    }
    ai_run(dist);
    self.nextthink = AttackRecoil(self,0.1);
  }
};

//============================================================================

void()   Gremlin_JumpTouch;
void()   Gremlin_FlipTouch;
void(float side)  Gremlin_Melee;
void(float side)  Gremlin_Gorge;

void()   gremlin_stand1  =[ $stand1.asc, gremlin_stand2  ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand2  =[ $stand2.asc, gremlin_stand3  ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand3  =[ $stand3.asc, gremlin_stand4  ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand4  =[ $stand4.asc, gremlin_stand5  ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand5  =[ $stand5.asc, gremlin_stand6  ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand6  =[ $stand6.asc, gremlin_stand7  ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand7  =[ $stand7.asc, gremlin_stand8  ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand8  =[ $stand8.asc, gremlin_stand9  ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand9  =[ $stand9.asc, gremlin_stand10 ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand10 =[ $stand10.asc,   gremlin_stand11 ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand11 =[ $stand11.asc,   gremlin_stand12 ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand12 =[ $stand12.asc,   gremlin_stand13 ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand13 =[ $stand13.asc,   gremlin_stand14 ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand14 =[ $stand14.asc,   gremlin_stand15 ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand15 =[ $stand15.asc,   gremlin_stand16 ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand16 =[ $stand16.asc,   gremlin_stand17 ] {gremlin_stand();self.nextthink = time + 0.2;};
void()   gremlin_stand17 =[ $stand17.asc,   gremlin_stand1  ] {gremlin_stand();self.nextthink = time + 0.2;};

void()   gremlin_walk1 =[ $walk1.asc,      gremlin_walk2 ] {
if (random() < 0.1)
    sound (self, CHAN_VOICE, "grem/idle.wav", 1, ATTN_IDLE);
gremlin_walk(8);};
void()   gremlin_walk2 =[ $walk2.asc,      gremlin_walk3 ] {gremlin_walk(8);};
void()   gremlin_walk3 =[ $walk3.asc,      gremlin_walk4 ] {gremlin_walk(8);};
void()   gremlin_walk4 =[ $walk4.asc,      gremlin_walk5 ] {gremlin_walk(8);};
void()   gremlin_walk5 =[ $walk5.asc,      gremlin_walk6 ] {gremlin_walk(8);};
void()   gremlin_walk6 =[ $walk6.asc,      gremlin_walk7 ] {gremlin_walk(8);};
void()   gremlin_walk7 =[ $walk7.asc,      gremlin_walk8 ] {gremlin_walk(8);};
void()   gremlin_walk8 =[ $walk8.asc,      gremlin_walk9 ] {gremlin_walk(8);};
void()   gremlin_walk9 =[ $walk9.asc,      gremlin_walk10 ] {gremlin_walk(8);};
void()   gremlin_walk10 =[ $walk10.asc,      gremlin_walk11 ] {gremlin_walk(8);};
void()   gremlin_walk11 =[ $walk11.asc,      gremlin_walk12 ] {gremlin_walk(8);};
void()   gremlin_walk12 =[ $walk12.asc,      gremlin_walk1 ] {gremlin_walk(8);};

void()   gremlin_run1 =[ $run1.asc,      gremlin_run2 ] {
if (random() < 0.1)
    sound (self, CHAN_VOICE, "grem/idle.wav", 1, ATTN_IDLE);
gremlin_run(0);};
void()   gremlin_run2 =[ $run2.asc,      gremlin_run3 ] {gremlin_run(8);};
void()   gremlin_run3 =[ $run3.asc,      gremlin_run4 ] {gremlin_run(12);};
void()   gremlin_run4 =[ $run4.asc,      gremlin_run5 ] {gremlin_run(16);};
void()   gremlin_run5 =[ $run5.asc,      gremlin_run6 ] {gremlin_run(16);};
void()   gremlin_run6 =[ $run6.asc,      gremlin_run7 ] {gremlin_run(12);};
void()   gremlin_run7 =[ $run7.asc,      gremlin_run8 ] {gremlin_run(8);};
void()   gremlin_run8 =[ $run8.asc,      gremlin_run9 ] {gremlin_run(0);};
void()   gremlin_run9 =[ $run9.asc,      gremlin_run10 ] {gremlin_run(8);};
void()   gremlin_run10 =[ $run10.asc,      gremlin_run11 ] {gremlin_run(12);};
void()   gremlin_run11 =[ $run11.asc,      gremlin_run12 ] {gremlin_run(16);};
void()   gremlin_run12 =[ $run12.asc,      gremlin_run1 ] {gremlin_run(16);};
void()   gremlin_run13 =[ $run13.asc,      gremlin_run14 ] {gremlin_run(12);};
void()   gremlin_run14 =[ $run14.asc,      gremlin_run15 ] {gremlin_run(8);};
void()   gremlin_run15 =[ $run15.asc,      gremlin_run1 ] {gremlin_run(0);};

void()   gremlin_jump1   =[ $jump1.asc,     gremlin_jump2   ] {ai_face();};
void()   gremlin_jump2   =[ $jump2.asc,     gremlin_jump3   ] {ai_face();};
void()   gremlin_jump3   =[ $jump3.asc,     gremlin_jump4   ] {ai_face();};
void()   gremlin_jump4   =[ $jump4.asc,     gremlin_jump5   ] {ai_face();};
void()   gremlin_jump5   =[ $jump5.asc,     gremlin_jump6   ]
{
	ai_face();

   if (self.flags & FL_ONGROUND)
      {
      self.touch = Gremlin_JumpTouch;
      makevectors (self.angles);
      self.origin_z = self.origin_z + 1;
      self.velocity = v_forward * 300 + '0 0 300';
      self.flags = self.flags - FL_ONGROUND;
      }
   else
      {
      gremlin_run1();
      }
};
void()   gremlin_jump6   =[ $jump6.asc,     gremlin_jump7   ] {};
void()   gremlin_jump7   =[ $jump7.asc,     gremlin_jump8   ] {};
void()   gremlin_jump8   =[ $jump8.asc,     gremlin_jump9   ] {};
void()   gremlin_jump9   =[ $jump9.asc,     gremlin_jump10   ] {};
void()   gremlin_jump10   =[ $jump10.asc,     gremlin_jump11   ] {};
void()   gremlin_jump11   =[ $jump11.asc,     gremlin_jump1   ]
{
  self.nextthink = time + 3;
  // if three seconds pass, assume gremlin is stuck and jump again
};

void()   gremlin_jump12   =[ $jump12.asc,    gremlin_jump13  ] {};
void()   gremlin_jump13   =[ $jump13.asc,    gremlin_jump14  ] {};
void()   gremlin_jump14   =[ $jump14.asc,    gremlin_jump15  ] {};
void()   gremlin_jump15   =[ $jump15.asc,    gremlin_jump16  ] {};
void()   gremlin_jump16   =[ $jump16.asc,    gremlin_run1 ] {};

void()   gremlin_shot1 = [$gfire1.asc, gremlin_shot2   ] {self.effects = self.effects | EF_MUZZLEFLASH;};
void()   gremlin_shot2 = [$gfire2.asc, gremlin_shot3   ] {};
void()   gremlin_shot3 = [$gfire3.asc, gremlin_shot4   ] {};
void()   gremlin_shot4 = [$gfire4.asc, gremlin_shot5   ] {};
void()   gremlin_shot5 = [$gfire5.asc, gremlin_shot6   ] {};
void()   gremlin_shot6 = [$gfire6.asc, gremlin_run1   ] {};


//============================================================================
void(float ox) Gremlin_FireNailGun;

void() gremlin_nail1   =[$gfire1.asc, gremlin_nail2  ]
   {
	self.effects = self.effects | EF_MUZZLEFLASH;
   Gremlin_FireNailGun(4);
   };
void() gremlin_nail2   =[$gfire1.asc, gremlin_nail3  ]
   {
	self.effects = self.effects | EF_MUZZLEFLASH;
   Gremlin_FireNailGun(4);
   };
void() gremlin_nail3   =[$gfire1.asc, gremlin_nail4  ]
   {
	self.effects = self.effects | EF_MUZZLEFLASH;
   Gremlin_FireNailGun(4);
   };
void() gremlin_nail4   =[$gfire1.asc, gremlin_nail5  ]
   {
	self.effects = self.effects | EF_MUZZLEFLASH;
   Gremlin_FireNailGun(4);
   };
void() gremlin_nail5   =[$gfire1.asc, gremlin_nail6  ]
   {
	self.effects = self.effects | EF_MUZZLEFLASH;
   Gremlin_FireNailGun(4);
   };
void() gremlin_nail6   =[$gfire1.asc, gremlin_nail7  ]
   {
	self.effects = self.effects | EF_MUZZLEFLASH;
   Gremlin_FireNailGun(4);
   };
void() gremlin_nail7 = [$gfire1.asc, gremlin_run1   ] {};


void(float ox) Gremlin_FireLaserGun;

void() gremlin_laser1   =[$gfire1.asc, gremlin_laser2  ]
   {
	self.effects = self.effects | EF_MUZZLEFLASH;
   Gremlin_FireLaserGun(4);
   };
void() gremlin_laser2   =[$gfire1.asc, gremlin_laser3  ]
   {
	self.effects = self.effects | EF_MUZZLEFLASH;
   Gremlin_FireLaserGun(4);
   };
void() gremlin_laser3   =[$gfire1.asc, gremlin_laser4  ]
   {
	self.effects = self.effects | EF_MUZZLEFLASH;
   Gremlin_FireLaserGun(4);
   };
void() gremlin_laser4   =[$gfire1.asc, gremlin_laser5  ]
   {
	self.effects = self.effects | EF_MUZZLEFLASH;
   Gremlin_FireLaserGun(4);
   };
void() gremlin_laser5   =[$gfire1.asc, gremlin_laser6  ]
   {
	self.effects = self.effects | EF_MUZZLEFLASH;
   Gremlin_FireLaserGun(4);
   };
void() gremlin_laser6   =[$gfire1.asc, gremlin_laser7  ]
   {
	self.effects = self.effects | EF_MUZZLEFLASH;
   Gremlin_FireLaserGun(4);
   };
void() gremlin_laser7 = [$gfire1.asc, gremlin_run1   ] {};

//============================================================================

void() Gremlin_FireLightningGun;
void() gremlin_light1   =[$gfire1.asc, gremlin_light2  ]
   {
   Gremlin_FireLightningGun();
   };
void() gremlin_light2 = [$gfire1.asc, gremlin_light3   ]
   {
   Gremlin_FireLightningGun();
   };
void() gremlin_light3   =[$gfire1.asc, gremlin_light4  ]
   {
   Gremlin_FireLightningGun();
   };
void() gremlin_light4 = [$gfire1.asc, gremlin_light5   ]
{
   Gremlin_FireLightningGun();
};
void() gremlin_light5 = [$gfire1.asc, gremlin_run1   ] {};

//============================================================================

void()   gremlin_rocket1 = [$gfire1.asc, gremlin_rocket2   ] {self.effects = self.effects | EF_MUZZLEFLASH;};
void()   gremlin_rocket2 = [$gfire2.asc, gremlin_rocket3   ] {};
void()   gremlin_rocket3 = [$gfire3.asc, gremlin_rocket4   ] {};
void()   gremlin_rocket4 = [$gfire4.asc, gremlin_rocket5   ] {};
void()   gremlin_rocket5 = [$gfire5.asc, gremlin_rocket6   ] {};
void()   gremlin_rocket6 = [$gfire6.asc, gremlin_run1   ] {};

void()   gremlin_lunge1   =[ $lunge1.asc,     gremlin_lunge2   ] {ai_charge(0);};
void()   gremlin_lunge2   =[ $lunge2.asc,     gremlin_lunge3   ] {ai_charge(0);};
void()   gremlin_lunge3   =[ $lunge3.asc,     gremlin_lunge4   ] {ai_charge(0);};
void()   gremlin_lunge4   =[ $lunge4.asc,     gremlin_lunge5   ] {ai_charge(0);};
void()   gremlin_lunge5   =[ $lunge5.asc,     gremlin_lunge6   ] {ai_charge(0);};
void()   gremlin_lunge6   =[ $lunge6.asc,     gremlin_lunge7   ] {ai_charge(0);};
void()   gremlin_lunge7   =[ $lunge7.asc,     gremlin_lunge8   ] {ai_charge(15);};
void()   gremlin_lunge8   =[ $lunge8.asc,     gremlin_lunge9   ] {ai_charge(0);Gremlin_Melee(0);};
void()   gremlin_lunge9   =[ $lunge9.asc,     gremlin_lunge10] {ai_charge(0);};
void()   gremlin_lunge10  =[ $lunge10.asc,    gremlin_lunge11] {ai_charge(0);};
void()   gremlin_lunge11  =[ $lunge11.asc,    gremlin_run1] {ai_charge(0);};

void()   gremlin_claw1   =[ $attk1.asc,     gremlin_claw2   ] {ai_charge(0);};
void()   gremlin_claw2   =[ $attk2.asc,     gremlin_claw3   ] {ai_charge(0);};
void()   gremlin_claw3   =[ $attk3.asc,     gremlin_claw4   ] {ai_charge(0);};
void()   gremlin_claw4   =[ $attk4.asc,     gremlin_claw5   ] {ai_charge(0);};
void()   gremlin_claw5   =[ $attk5.asc,     gremlin_claw6   ] {ai_charge(0);};
void()   gremlin_claw6   =[ $attk6.asc,     gremlin_claw7   ] {ai_charge(0);Gremlin_Melee(200);};
void()   gremlin_claw7   =[ $attk7.asc,     gremlin_claw8   ] {ai_charge(15);};
void()   gremlin_claw8   =[ $attk8.asc,     gremlin_claw9   ] {ai_charge(0);};
void()   gremlin_claw9   =[ $attk9.asc,     gremlin_claw10] {ai_charge(0);};
void()   gremlin_claw10  =[ $attk10.asc,    gremlin_claw11] {ai_charge(0);};
void()   gremlin_claw11  =[ $attk11.asc,    gremlin_run1] {ai_charge(0);};

void()   gremlin_gorge1   =[ $maul1.asc,     gremlin_gorge2] {ai_charge(1);Gremlin_GorgeValid(TRUE);}; //Ry: Additional check here
void()   gremlin_gorge2   =[ $maul2.asc,     gremlin_gorge3] {ai_charge(1);};
void()   gremlin_gorge3   =[ $maul3.asc,     gremlin_gorge4] {ai_charge(2);};
void()   gremlin_gorge4   =[ $maul4.asc,     gremlin_gorge5] {ai_charge(0);};
void()   gremlin_gorge5   =[ $maul5.asc,     gremlin_gorge6] {ai_charge(0);};
void()   gremlin_gorge6   =[ $maul6.asc,     gremlin_gorge7] {ai_charge(0);Gremlin_Gorge(200);};
void()   gremlin_gorge7   =[ $maul7.asc,     gremlin_gorge8] {ai_charge(0);};
void()   gremlin_gorge8   =[ $maul8.asc,     gremlin_gorge9] {ai_charge(0);Gremlin_Gorge(-200);};
void()   gremlin_gorge9   =[ $maul9.asc,     gremlin_gorge10] {ai_charge(0);};
void()   gremlin_gorge10   =[ $maul10.asc,     gremlin_gorge11] {ai_charge(0);};
void()   gremlin_gorge11   =[ $maul11.asc,     gremlin_gorge12] {ai_charge(0);};
void()   gremlin_gorge12   =[ $maul12.asc,     gremlin_gorge13] {ai_charge(0);};
void()   gremlin_gorge13   =[ $maul13.asc,     gremlin_gorge1] {ai_charge(0);};

void()  gremlin_look = //Ry: Check if there's any more targets around
{
  if (GremlinFindTarget())
    gremlin_run1();
}

void()   gremlin_look1   =[ $look1.asc,     gremlin_look2] {self.nextthink = time + 0.2;};
void()   gremlin_look2   =[ $look2.asc,     gremlin_look3] {self.nextthink = time + 0.2;};
void()   gremlin_look3   =[ $look3.asc,     gremlin_look4] {self.nextthink = time + 0.2;};
void()   gremlin_look4   =[ $look4.asc,     gremlin_look5] {self.nextthink = time + 0.2;};
void()   gremlin_look5   =[ $look5.asc,     gremlin_look6] {self.nextthink = time + 0.2;};
void()   gremlin_look6   =[ $look6.asc,     gremlin_look7] {self.nextthink = time + 0.2;};
void()   gremlin_look7   =[ $look7.asc,     gremlin_look8] {self.nextthink = time + 0.2;};
void()   gremlin_look8   =[ $look8.asc,     gremlin_look9] {self.nextthink = time + 0.2;};
void()   gremlin_look9   =[ $look9.asc,     gremlin_run1]
{
  Gremlin_AbandonGorge(FALSE);
};

void()   gremlin_glook1   =[ $glook1.asc,     gremlin_glook2] {gremlin_look();};
void()   gremlin_glook2   =[ $glook2.asc,     gremlin_glook3] {gremlin_look();};
void()   gremlin_glook3   =[ $glook3.asc,     gremlin_glook4] {gremlin_look();};
void()   gremlin_glook4   =[ $glook4.asc,     gremlin_glook5] {gremlin_look();};
void()   gremlin_glook5   =[ $glook5.asc,     gremlin_glook6] {gremlin_look();};
void()   gremlin_glook6   =[ $glook6.asc,     gremlin_glook7] {gremlin_look();};
void()   gremlin_glook7   =[ $glook7.asc,     gremlin_glook8] {gremlin_look();};
void()   gremlin_glook8   =[ $glook8.asc,     gremlin_glook9] {gremlin_look();};
void()   gremlin_glook9   =[ $glook9.asc,     gremlin_glook10] {gremlin_look();};
void()   gremlin_glook10   =[ $glook10.asc,     gremlin_glook11] {gremlin_look();};
void()   gremlin_glook11   =[ $glook11.asc,     gremlin_glook12] {gremlin_look();};
void()   gremlin_glook12   =[ $glook12.asc,     gremlin_glook13] {gremlin_look();};
void()   gremlin_glook13   =[ $glook13.asc,     gremlin_glook14] {gremlin_look();};
void()   gremlin_glook14   =[ $glook14.asc,     gremlin_glook15] {gremlin_look();};
void()   gremlin_glook15   =[ $glook15.asc,     gremlin_glook16] {gremlin_look();};
void()   gremlin_glook16   =[ $glook16.asc,     gremlin_glook17] {gremlin_look();};
void()   gremlin_glook17   =[ $glook17.asc,     gremlin_glook18] {gremlin_look();};
void()   gremlin_glook18   =[ $glook18.asc,     gremlin_glook19] {gremlin_look();};
void()   gremlin_glook19   =[ $glook19.asc,     gremlin_glook20] {gremlin_look();};
void()   gremlin_glook20   =[ $glook20.asc,     gremlin_glook20]
   {
   if (self.oldenemy.health > 0)
      {
      self.enemy = self.oldenemy;
      HuntTarget ();
      }
   else
      {
      //GremlinDropBackpack(); //Ry: Just put away weapon when idling too long
      GremlinStoreWeapon();
      self.enemy = world; //Ry: Clear foe so can properly target again
      if (self.movetarget)
         self.th_walk ();
      else
         self.th_stand ();
      }
   };

void()   gremlin_pain1   =[ $pain1.asc,     gremlin_pain2   ] {ai_back(4);};
void()   gremlin_pain2   =[ $pain2.asc,     gremlin_pain3   ] {ai_back(4);};
void()   gremlin_pain3   =[ $pain3.asc,     gremlin_pain4   ] {ai_back(2);};
void()   gremlin_pain4   =[ $pain4.asc,     gremlin_run1 ] {};

void()   gremlin_gunpain1   =[ $gpain1.asc,     gremlin_gunpain2   ] {ai_back(4);};
void()   gremlin_gunpain2   =[ $gpain2.asc,     gremlin_gunpain3   ] {ai_back(2);};
void()   gremlin_gunpain3   =[ $gpain3.asc,     gremlin_run1 ] {};

void(entity attacker, float damage) gremlin_pain =
{
  local float r;

  if ( (attacker != self) && (random()<0.8) ) //Ry: Don't target self
  {
    if (self.gremstate < GREM_ARMED)
      Gremlin_UpdateState(GREM_DEFAULT);
    self.enemy = attacker;
    FoundTarget();
  }
  if (self.touch == Gremlin_JumpTouch)
		return;

	if (self.pain_finished > time)
		return;

	self.pain_finished = time + 1;

  r = random();
  if (r<0.33)
    sound (self, CHAN_VOICE, "grem/pain1.wav", 1, ATTN_NORM);
  else if (r<0.66)
    sound (self, CHAN_VOICE, "grem/pain2.wav", 1, ATTN_NORM);
  else
    sound (self, CHAN_VOICE, "grem/pain3.wav", 1, ATTN_NORM);

  if (self.gremstate >= GREM_ARMED)
  {
    gremlin_gunpain1 ();
  }
  else
  {
    Gremlin_UpdateState(GREM_DEFAULT); //Ry: Reset state
    gremlin_pain1 ();
  }
};

void()   gremlin_spawn1 =[ $spawn1.asc,      gremlin_spawn2 ] {self.nextthink = time + 0.3;
   self.th_pain = SUB_Null_Pain;
//    sound (self, CHAN_VOICE, "grem/idle.wav", 1, ATTN_IDLE);
};
void()   gremlin_spawn2 =[ $spawn2.asc,      gremlin_spawn3 ] {self.nextthink = time + 0.3;};
void()   gremlin_spawn3 =[ $spawn3.asc,      gremlin_spawn4 ] {self.nextthink = time + 0.3;};
void()   gremlin_spawn4 =[ $spawn4.asc,      gremlin_spawn5 ] {self.nextthink = time + 0.3;};
void()   gremlin_spawn5 =[ $spawn5.asc,      gremlin_spawn6 ] {self.nextthink = time + 0.3;};
void()   gremlin_spawn6 =[ $spawn6.asc,      gremlin_run1 ] {
   self.th_pain = gremlin_pain;
};


void()   gremlin_die1    =[ $death1.asc,    gremlin_die2 ]
{sound (self, CHAN_VOICE, "grem/death.wav", 1, ATTN_NORM);};
void()   gremlin_die2    =[ $death2.asc,    gremlin_die3 ] {ai_forward(2);};
void()   gremlin_die3    =[ $death3.asc,    gremlin_die4 ] {ai_forward(1);};
void()   gremlin_die4    =[ $death4.asc,    gremlin_die5 ] {ai_forward(2);};
void()   gremlin_die5    =[ $death5.asc,    gremlin_die6 ] {ai_forward(1);};
void()   gremlin_die6    =[ $death6.asc,    gremlin_die7 ]
{self.solid = SOLID_NOT;};
void()   gremlin_die7    =[ $death7.asc,    gremlin_die8 ] {ai_forward(2);};
void()   gremlin_die8    =[ $death8.asc,    gremlin_die9 ] {ai_forward(1);};
void()   gremlin_die9    =[ $death9.asc,    gremlin_die10 ] {ai_forward(2);};
void()   gremlin_die10    =[ $death10.asc,    gremlin_die11 ] {ai_forward(1);};
void()   gremlin_die11    =[ $death11.asc,    gremlin_die12 ] {ai_forward(2);};
void()   gremlin_die12    =[ $death12.asc,    gremlin_die12 ]
{
	if (horde_ent) //Ry: Horde mode fade out
	{
		self.think = MonsterFade;
		self.nextthink = time + FADETIME;
	}
};

void() gremlin_gib=
{
  sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
  ThrowHead ("progs/h_grem.mdl", -35);
  ThrowGib ("progs/gib1.mdl", -35);
  ThrowGib ("progs/gib1.mdl", -35);
  ThrowGib ("progs/gib1.mdl", -35);
};

void()   gremlin_flip1    =[ $flip1.asc,    gremlin_flip2 ]
{
  ai_face();
	makevectors (self.angles);
  self.origin_z = self.origin_z + 1;
  self.velocity = '0 0 350' - (v_forward * 200);
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
  sound (self, CHAN_VOICE, "grem/death.wav", 1, ATTN_NORM);
};
void()   gremlin_flip2    =[ $flip2.asc,    gremlin_flip3 ] {ai_face();};
void()   gremlin_flip3    =[ $flip3.asc,    gremlin_flip4 ] {};
void()   gremlin_flip4    =[ $flip4.asc,    gremlin_flip5 ] {};
void()   gremlin_flip5    =[ $flip5.asc,    gremlin_flip6 ] {};
void()   gremlin_flip6    =[ $flip6.asc,    gremlin_flip7 ] {self.touch = Gremlin_FlipTouch;};
void()   gremlin_flip7    =[ $flip7.asc,    gremlin_gib ]
{
  self.nextthink = time + 3;
  // if three seconds pass, assume gremlin is stuck and jump again
};
void()   gremlin_flip8    =[ $flip8.asc,    gremlin_flip8 ]
{
  self.solid = SOLID_NOT;
	if (horde_ent) //Ry: Horde mode fade out
	{
		self.think = MonsterFade;
		self.nextthink = time + FADETIME;
	}
};

/*
===============
GremlinDropBackpack
===============
*/
void() GremlinDropBackpack =
{
	local entity	item;
  
  if (self.super_item) //Ry: If Gremlin picked up a weapon item, drop it separately
  {
    self.super_item.model = self.super_item.mdl;
    self.super_item.effects = self.super_item.itemeffect;
    self.super_item.origin = self.origin;
    self.super_item.flags = FL_ITEM;
    self.super_item.waterlevel = 0;
    self.super_item.solid = SOLID_TRIGGER;
    self.super_item.movetype = MOVETYPE_TOSS;
    self.super_item.velocity_z = 300;
    self.super_item.velocity_x = -100 + (random() * 200);
    self.super_item.velocity_y = -100 + (random() * 200);
    self.super_item.gremstate = GREM_DEFAULT;
    self.super_item.think = GremlinItemSafety;
    self.super_item.nextthink = time+1;
    self.super_item.displaced = TRUE;

    //Ry: Remove the weapon and as much ammo as the weapon gives from the Gremlin to make sure it doesn't drop with the backpack
    if (self.items & self.super_item.weapon)
      self.items = self.items - self.super_item.weapon;
    if (self.stolenitems & self.super_item.weapon) //Ry: This shouldn't happen, but just in case
      self.stolenitems = self.stolenitems - self.super_item.weapon;

    if ( self.super_item.weapon & (IT_NAILGUN|IT_SUPER_NAILGUN) )
    {
      if (self.AMMO_NAILS > 30)
        self.AMMO_NAILS = self.AMMO_NAILS - 30;
      else
        self.AMMO_NAILS = 0;
    }
    else if ( self.super_item.weapon & IT_SUPER_SHOTGUN )
    {
      if (self.AMMO_SHELLS > 20)
        self.AMMO_SHELLS = self.AMMO_SHELLS - 20;
      else
        self.AMMO_SHELLS = 0;
    }
    else if ( self.super_item.weapon & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER|IT_PROXIMITY_GUN) )
    {
      if (self.AMMO_ROCKETS > 5)
        self.AMMO_ROCKETS = self.AMMO_ROCKETS - 5;
      else
        self.AMMO_ROCKETS = 0;
    }
    else if ( self.super_item.weapon & IT_LIGHTNING )
    {
      if (self.AMMO_CELLS > 15)
        self.AMMO_CELLS = self.AMMO_CELLS - 15;
      else
        self.AMMO_CELLS = 0;
    }
    else if ( self.super_item.weapon & IT_LASER_CANNON )
    {
      if (self.AMMO_CELLS > 30)
        self.AMMO_CELLS = self.AMMO_CELLS - 30;
      else
        self.AMMO_CELLS = 0;
    }

    self.super_item = world;

  }

  //Ry: Clean up items before deciding whether or not to drop
  self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS ) );
  if (self.AMMO_SHELLS < 0) self.AMMO_SHELLS = 0;
  if (self.AMMO_NAILS < 0) self.AMMO_NAILS = 0;
  if (self.AMMO_ROCKETS < 0) self.AMMO_ROCKETS = 0;
  if (self.AMMO_CELLS < 0) self.AMMO_CELLS = 0;

  /*dprint("Dead Gremlin at ");
  dprint(vtos(self.origin));
  dprint(" has Items ");
  dprint(ftos(self.items));
  dprint(", with ");
  dprint(ftos(self.stolenitems));
  dprint(" having been stolen\n");*/

  if (!deathmatch) //Ry: Only drop weapons that were stolen in SP/Co-op
    self.items = self.stolenitems;

  if ( (self.items + self.AMMO_SHELLS + self.AMMO_NAILS + self.AMMO_ROCKETS + self.AMMO_CELLS) <= 0 )
    return;

	item = spawn();
  item.classname = "item_backpack"; //Ry: Give this a classname
	item.origin = self.origin - '0 0 24';

  item.items = self.items;
  item.stolenitems = self.stolenitems; //Ry: Indicate which weapons were ones stolen from players

  if (item.items & IT_AXE)
		item.netname = "Axe";
  else if (item.items & IT_SHOTGUN)
		item.netname = "Shotgun";
  else if (item.items & IT_SUPER_SHOTGUN)
		item.netname = "Double-barrelled Shotgun";
  else if (item.items & IT_NAILGUN)
		item.netname = "Nailgun";
  else if (item.items & IT_SUPER_NAILGUN)
		item.netname = "Super Nailgun";
  else if (item.items & IT_GRENADE_LAUNCHER)
		item.netname = "Grenade Launcher";
  else if (item.items & IT_ROCKET_LAUNCHER)
		item.netname = "Rocket Launcher";
  else if (item.items & IT_LIGHTNING)
		item.netname = "Thunderbolt";
  else if (item.items & IT_LASER_CANNON)
    item.netname = "Laser Cannon";
  else if (item.items & IT_PROXIMITY_GUN)
    item.netname = "Proximity Gun";
  else if (item.items & IT_MJOLNIR)
    item.netname = "Mjolnir";
  else
		item.netname = "";

  item.AMMO_SHELLS = self.AMMO_SHELLS;
	item.AMMO_NAILS = self.AMMO_NAILS;
	item.AMMO_ROCKETS = self.AMMO_ROCKETS;
	item.AMMO_CELLS = self.AMMO_CELLS;

  if (self.health > 0) //Ry: When still alive, also empty out inventory
  {
    self.items = 0;
    self.AMMO_SHELLS = 0;
    self.AMMO_NAILS = 0;
    self.AMMO_ROCKETS = 0;
    self.AMMO_CELLS = 0;
    item.lastfragtime = time + 0.2; //Ry: And make sure it's not picked immediately
  }

	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);

	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	setmodel (item, "progs/backpack.mdl");
	setsize (item, '-16 -16 0', '16 16 56');
	item.touch = BackpackTouch;

  if (!deathmatch && item.items) //Ry: If there's stolen weapons in SP/Co-op, make sure the backpack stays safe
  {
    item.nextthink = time + 1;
    item.think = GremlinBackpackSafety;
    item.lastsafevect = self.lastsafevect;
  }
  else
  {
    item.nextthink = time + 120;	// remove after 2 minutes
    item.think = SUB_Remove;
  }
};

void() gremlin_die =
{
  local vector   vec;
	local float		dot;

  // check for gib  //Ry: Also drop backpack if ammo was collected
  if (self.items & (IT_SHOTGUN|IT_SUPER_SHOTGUN|IT_NAILGUN|IT_SUPER_NAILGUN|IT_GRENADE_LAUNCHER|IT_ROCKET_LAUNCHER|IT_LIGHTNING|IT_LASER_CANNON|IT_PROXIMITY_GUN) || self.AMMO_SHELLS > 0 || self.AMMO_NAILS > 0 || self.AMMO_ROCKETS > 0 || self.AMMO_CELLS > 0)
  {
    GremlinDropBackpack();
  }

  if (self.trigger_field && (self.trigger_field.classname == "gremtarget")) //Ry: Clean up Gremlin's custom target entity (make double sure it's the right thing)
    remove(self.trigger_field);

  makevectors (self.angles);
  vec = normalize (damage_attacker.origin - self.origin);
	dot = vec * v_forward;

  Gremlin_UpdateState(GREM_DEFAULT); //Ry: Reset state to default

  if ( self.health < self.gib_health ) //Ry: Compare to the saved var now [07-31-2022]
  {
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
    ThrowHead ("progs/h_grem.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
		return;
  }
  else if (dot>0.7 && (random()<0.5) && (self.flags & FL_ONGROUND))
  {
    gremlin_flip1();
    return;
  }
  // regular death
  gremlin_die1 ();
};


float() GremlinWeaponAttack;
void() Gremlin_MeleeAttack =
{
  local float num;
  if (self.gremstate == GREM_GORGING && Gremlin_TargetGorgable(self.enemy) ) //Ry: Ensure Gremlin doesn't gorge a living target, which doesn't kill properly
  {
    gremlin_gorge1();
  }
  else
  { //Ry: Now guaranteed to *try* to steal if incited by other Gremlins
    if ( ((self.enemy.flags & FL_CLIENT) || (self.enemy.classname == "monster_gremlin")) && ((random() < 0.4) || (self.gremstate == GREM_STEALITEM)) )
      if (GremlinAttemptWeaponSteal())
        return;
    Gremlin_UpdateState(GREM_DEFAULT); //Ry: Put back into default state
    num = random();
    if (num<0.3)
    {
      gremlin_claw1 ();
    }
    else if (num < 0.6)
    {
      gremlin_lunge1 ();
    }
    else
    {
      gremlin_claw1 ();
    }
  }
};

/*
============
GremlinHasAmmo //Ry: Renamed this to better fit what's returned

attack with a weapon
============
*/
float() GremlinHasAmmo =
  {
	  if (self.weapon && self.currentammo > 0)
    {
		  return TRUE;
    }
    else if (self.items > 0)
    {
      self.weapon = W_BestWeapon(); //Ry: Check if another weapon is available
      if ( (!self.weapon) || (self.weapon == IT_AXE) || (self.weapon == IT_MJOLNIR) )
      {
        GremlinStoreWeapon();
        return FALSE;
      }
      else
      {
        W_UpdateAmmo();
        Gremlin_UpdateState(GREM_ARMED);
        return TRUE;
      }
    }
    return FALSE;
  };

/*
============
GremlinFindVictim

find a victim to shoot at
============
*/
entity() GremlinFindVictim =
   {
   local entity head;
   local entity selected;
   local float dist;
   local float head_dist;
   //local float decision;

   self.search_time = AttackRecoil(self,1.0);
// look in our immediate vicinity

   selected = world;
   dist = 1000;
   head = findradius(self.origin, 1000);
   while(head)
      {
      //Ry: Check for team, and don't target other monsters in Nightmare (unless charmed)
      if (!(head.flags & FL_NOTARGET) && ( (self.team == 0) || !(self.team == head.team) ) && ( (head.flags & FL_CLIENT) || ((head.flags & FL_MONSTER) && (skill < 3 || copper_nightmare || self.charmed)) ) )
         {
         if (visible(head) && (head.health > 0) && (head !=self))
            {
            head_dist = vlen(head.origin-self.origin);
            if (head == self.lastvictim)
               head_dist = head_dist * 2;
            if (head.flags & FL_CLIENT)
               head_dist = head_dist / 1.5;
            if (head.classname == self.classname)
               head_dist = head_dist * 1.5;
            if (head_dist < dist)
               {
               selected = head;
               dist = head_dist;
               }
            }
         }
      head = head.chain;
      }
   self.lastvictim = selected;

   return selected;
   };

/*
============
Gremlin_FireRocket

fire a rocket
============
*/
void() Gremlin_FireRocket =
{
	local	entity missile;
  local vector dir;
  local float conemul;

	self.currentammo = self.AMMO_ROCKETS = self.AMMO_ROCKETS - 1;
   self.effects = self.effects | EF_MUZZLEFLASH;

	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "missile";

// set missile speed

  if (self.charmed)
    conemul = 0.05;
  else
    conemul = 0.1;

  dir = normalize(self.enemy.origin - self.origin);
  self.v_angle = vectoangles(dir);
  makevectors(self.v_angle);
  dir = dir + crandom()* conemul * v_right + crandom()* conemul *v_up;
  missile.velocity = normalize(dir);
  missile.velocity = missile.velocity * ProjectileSpeed(self,1000);
	missile.angles = vectoangles(missile.velocity);

	missile.touch = T_MissileTouch;

// set missile duration
	missile.nextthink = time + 5;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/missile.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin + v_forward*8 + '0 0 16');
//   GremlinRecoil(dir,-1000);
};

/*
============
Gremlin_FireNailGun

fire a nailgun
============
*/
void(float ox) Gremlin_FireNailGun =
{
  local vector dir;
  local float conemul;

  self.effects = self.effects | EF_MUZZLEFLASH;
  
  if (self.charmed)
    conemul = 0.05;
  else
    conemul = 0.1;

  dir = normalize(self.enemy.origin - self.origin);
  self.v_angle = vectoangles(dir);
  makevectors(self.v_angle);
  dir = dir + crandom()* conemul * v_right + crandom()* conemul *v_up;
  dir = normalize(dir);
  launch_spike (self.origin + '0 0 16', dir);

  if (self.weapon == IT_SUPER_NAILGUN && (self.AMMO_NAILS > 1)) //Ry: Actually be able to fire super nails
  {
    self.currentammo = self.AMMO_NAILS = self.AMMO_NAILS - 2;
    sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
    newmis.touch = superspike_touch;
    newmis.classname = "super_spike";
    setmodel (newmis, "progs/s_spike.mdl");
    setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
    CreateMissileField(newmis,4);
  }
  else
  {
    self.currentammo = self.AMMO_NAILS = self.AMMO_NAILS - 1;
    sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
    CreateMissileField(newmis,6);
  }

};

/*
============
Gremlin_FireLaserGun

fire a laser cannon
============
*/
void(float ox) Gremlin_FireLaserGun =
{
  local vector dir;
  local float conemul;

  self.currentammo = self.AMMO_CELLS = self.AMMO_CELLS - 1;
  self.effects = self.effects | EF_MUZZLEFLASH;
   
  if (self.charmed)
    conemul = 0.05;
  else
    conemul = 0.1;

  sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
  dir = normalize(self.enemy.origin - self.origin);
  self.v_angle = vectoangles(dir);
  makevectors(self.v_angle);
  dir = dir + crandom()* conemul * v_right + crandom()* conemul *v_up;
  dir = normalize(dir);
  HIP_LaunchLaser(self.origin + '0 0 16', dir, 0);
};

/*
============
Gremlin_FireShotGun

fire a shotgun
============
*/
void() Gremlin_FireShotGun =
{
  local vector dir;
  local float conemul;

  self.currentammo = self.AMMO_SHELLS = self.AMMO_SHELLS - 1;
  self.effects = self.effects | EF_MUZZLEFLASH;
 
  if (self.charmed)
    conemul = 0.05;
  else
    conemul = 0.1;

  sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);
  dir = normalize(self.enemy.origin - self.origin);
  self.v_angle = vectoangles(dir);
  makevectors(self.v_angle);
  dir = dir + crandom()* conemul *v_right + crandom()* conemul *v_up;
  dir = normalize(dir);
  self.v_angle = vectoangles(dir);
  FireBullets (6, dir, '0.04 0.04 0');
};

/*
============
Gremlin_FireSuperShotGun

fire a shotgun
============
*/
void() Gremlin_FireSuperShotGun =
{
  local vector dir;
  local float conemul;
 
  if (self.AMMO_SHELLS < 2) //Ry: Fire a single shotgun blast if too low on ammo, just like the player
  {
    Gremlin_FireShotGun();
    return;
  }

  self.currentammo = self.AMMO_SHELLS = self.AMMO_SHELLS - 2;
  self.effects = self.effects | EF_MUZZLEFLASH;

  if (self.charmed)
    conemul = 0.15;
  else
    conemul = 0.3;

   sound (self ,CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
   dir = normalize(self.enemy.origin - self.origin);
   self.v_angle = vectoangles(dir);
   makevectors(self.v_angle);
   dir = dir + crandom()* conemul *v_right + crandom()* conemul *v_up;
   dir = normalize(dir);
   self.v_angle = vectoangles(dir);
   FireBullets (14, dir, '0.14 0.08 0');
};

/*
============
Gremlin_FireLightningGun

fire lightning gun
============
*/
void() Gremlin_FireLightningGun =
   {
	local	vector	org, dir;
  local float cells, conemul;

// explode if under water
  if ((self.watertype <= CONTENT_WATER) && (self.waterlevel > 1)) //Ry: Actually check water level, so they don't blow up in ankle-deep water
	{
    self.deathtype = "discharge";
		cells = self.AMMO_CELLS;
		self.AMMO_CELLS = 0;
		T_RadiusDamage (self, self, 35*cells, world);
//      W_SetCurrentAmmo ();
		return;
	}

  self.effects = self.effects | EF_MUZZLEFLASH;

	ai_face ();

  self.currentammo = self.AMMO_CELLS = self.AMMO_CELLS - 2;
  org = self.origin + '0 0 16';
   
  if (self.charmed)
    conemul = 0.05;
  else
    conemul = 0.1;

	dir = self.enemy.origin + '0 0 16' - org;
	dir = normalize (dir);
  dir = normalize(self.enemy.origin - self.origin);
  self.v_angle = vectoangles(dir);
  makevectors(self.v_angle);
  dir = dir + crandom()* conemul *v_right + crandom()* conemul *v_up;
  dir = normalize(dir);

	traceline (org, self.origin + dir*600, TRUE, self);

  WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
  WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);

  LightningDamage (org, trace_endpos+(dir*4), self, self, 30, TRUE, self.team); //Ry: Added inflictor, use the extra traces like the player, and forward team [07-31-2022]
};

/*
================
GremlinFireProximityGrenade
================
*/
void() GremlinFireProximityGrenade =
{
  local entity missile;
  local vector dir;
  local float conemul;

  NumProximityGrenades = NumProximityGrenades + 1;
  self.currentammo = self.AMMO_ROCKETS = self.AMMO_ROCKETS - 1;

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	missile = spawn ();
  missile.owner = self;
  missile.lastvictim = self;
  missile.movetype = MOVETYPE_TOSS;
	missile.solid = SOLID_BBOX;
  missile.classname = "proximity_grenade";
  missile.takedamage = DAMAGE_NO;
  missile.health = 5;
  missile.state = 0;

  //Ry: Proxy Bombs fired by Enemy Gremlins in campaign will glow [12-10-2022]
  if (hip_rebalance && !deathmatch && self.team == 0)
    SetLightEffect(missile,SET_EF_CANDLE,TRUE);

// set missile speed

  if (self.charmed)
    conemul = 0.05;
  else
    conemul = 0.1;

  dir = normalize(self.enemy.origin - self.origin);
  self.v_angle = vectoangles(dir);
  makevectors(self.v_angle);
  dir = dir + crandom()* conemul *v_right + crandom()* conemul *v_up;
  dir = normalize(dir);
  missile.velocity = dir * 600;
	missile.velocity_z = 200;

  missile.avelocity = '100 600 100';

	missile.angles = vectoangles(missile.velocity);

  missile.touch = ProximityGrenadeTouch;

// set missile duration
  missile.nextthink = time + 2;
  missile.delay = time + 15 + (10*random());
  missile.think = ProximityBomb;
  missile.th_die = ProximityGrenadeExplode;

  setmodel (missile, "progs/proxbomb.mdl");
  setorigin (missile, self.origin);
  setsize (missile, '-1 -1 -1', '1 1 1');
};

/*
============
GremlinWeaponAttack

attack with a weapon
============
*/
void()   gremlin_shot1;
void()   gremlin_nail1;
void()   gremlin_light1;
void()   gremlin_rocket1;

float() GremlinWeaponAttack =
{
  if (!GremlinHasAmmo ())
    return FALSE;

  self.show_hostile = time + 1; // wake monsters up

  if (self.weapon == IT_SHOTGUN)
  {
    gremlin_shot1 ();
    Gremlin_FireShotGun();
    SUB_AttackFinished(1);
  }
	else if (self.weapon == IT_SUPER_SHOTGUN)
  {
    gremlin_shot1 ();
    Gremlin_FireSuperShotGun();
    SUB_AttackFinished(1);
  }
	else if (self.weapon == IT_NAILGUN)
  {
    gremlin_nail3 ();
    SUB_AttackFinished(1);
  }
	else if (self.weapon == IT_SUPER_NAILGUN)
  {
    gremlin_nail3 ();
    SUB_AttackFinished(1);
  }
	else if (self.weapon == IT_GRENADE_LAUNCHER)
  {
    gremlin_rocket1();
    Gremlin_FireGrenade(); //Ry: Fired like Ogres, but Player damage on Normal+ and DM
    SUB_AttackFinished(1);
  }
	else if (self.weapon == IT_ROCKET_LAUNCHER)
  {
    gremlin_rocket1();
    Gremlin_FireRocket();
    SUB_AttackFinished(1);
  }
	else if (self.weapon == IT_LIGHTNING)
  {
    gremlin_light1();
    SUB_AttackFinished(1);
    sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
  }
  else if (self.weapon == IT_LASER_CANNON)
  {
    gremlin_laser3();
    SUB_AttackFinished(1);
  }
  else if (self.weapon == IT_PROXIMITY_GUN)
  {
    gremlin_rocket1();
    GremlinFireProximityGrenade();
    SUB_AttackFinished(1);
  }
  return TRUE;
};

void() Gremlin_MissileAttack =
{
  if (self.gremstate >= GREM_ARMED)
  {
    if (GremlinWeaponAttack())
      return;
    else if ((random()<0.1) && (self.flags & FL_ONGROUND))
    {
      gremlin_jump1();
      return;
    }
  }
  if (self.flags & FL_ONGROUND)
    gremlin_jump1();
};

/*QUAKED monster_gremlin (1 0 0) (-32 -32 -24) (32 32 64) Ambush

*/
void() monster_gremlin =
{
  missionpackmap = TRUE; //Ry: Map has Hipnotic entity
  
  if (!EntityValidForMode(ENTTYPE_MONSTER)) //Ry: New function to handle func_spawn and horde mode
		return;
    
  precache_model ("progs/grem.mdl");
  precache_model ("progs/h_grem.mdl");

  precache_sound ("grem/death.wav");
  precache_sound ("grem/attack.wav");
  precache_sound ("demon/djump.wav");
  precache_sound ("demon/dhit2.wav");
  precache_sound ("grem/pain1.wav");
  precache_sound ("grem/pain2.wav");
  precache_sound ("grem/pain3.wav");
  precache_sound ("grem/idle.wav");
  precache_sound ("grem/sight1.wav");

  setmodel (self, "progs/grem.mdl");
  setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
  self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

  self.netname = "Gremlin"; //Ry: Name for Deathmatch
  self.health = 100;
  self.max_health = 100; //Ry: Just use 100 instead of 101
  self.gib_health = -35; //Ry: Var for gib health [07-31-2022]
  self.yaw_speed = 40;
  self.lastsafecheck = time; //Ry: Initial safe vector for returning a dropped weapon backpack
  self.lastsafevect = self.origin;
  
  #ifdef ENGINE_KEX
    self.allowPathFind = USEPATH_ALWAYS; //Ry: Always use Remaster pathing [08-01-2022]
  #endif
	self.combat_style = CS_MELEE; //Ry: Will change to CS_RANGED when it steals a weapon
  
  self.th_stand = gremlin_stand1;
  self.th_walk = gremlin_walk1;
  self.th_run = gremlin_run1;
  self.th_die = gremlin_die;
  self.th_melee = Gremlin_MeleeAttack;     // one of two attacks
  self.th_missile = Gremlin_MissileAttack; // check for random jump or firing of weapon
  self.th_pain = gremlin_pain;
  
  NumGremlins = NumGremlins + 1;

  walkmonster_start();
};

float()  GremlinCheckAttack =
{
	local vector	spot1, spot2;
	local entity	targ;
	local float		chance;

	targ = self.enemy;

  if (time < self.attack_finished)
    return FALSE;

// see if any entities are in the way of the shot
  spot1 = self.origin;// + self.view_ofs;
  spot2 = targ.origin;// + targ.view_ofs;

  if ((vlen(spot2 - spot1) <= 90) && (self.gremstate < GREM_ARMED))
  {
    self.attack_state = AS_MELEE;
    return TRUE;
  }
// missile attack
  if (self.gremstate >= GREM_ARMED)
  {
    self.attack_state = AS_MISSILE;
    return TRUE;
  }
  else
  {
    chance = 0.03;
    if (random() < chance)
    {
      self.attack_state = AS_MISSILE;
      return TRUE;
    }
  }
	return FALSE;
};


//===========================================================================

void(float side)  Gremlin_Melee =
{
	local	float	ldmg;
	local vector	delta;

	ai_face ();

//   walkmove (self.ideal_yaw, 12);   // allow a little closing


	delta = self.enemy.origin - self.origin;

	if (vlen(delta) > 100)
		return;
	if (!CanDamage (self.enemy, self))
		return;

    sound (self, CHAN_WEAPON, "grem/attack.wav", 1, ATTN_NORM);
	ldmg = 10 + 5*random();
	T_Damage (self.enemy, self, self, ldmg);

	makevectors (self.angles);
	SpawnMeatSpray (self.origin + v_forward*16, side * v_right);
};

//===========================================================================
void(float dm) Gremlin_ThrowHead =
   {
   local string gibname;
   if (self.classname == "monster_ogre")
      gibname = "progs/h_ogre.mdl";
	else if (self.classname == "monster_knight")
      gibname = "progs/h_knight.mdl";
   else if (self.classname == "monster_shambler")
      gibname = "progs/h_shams.mdl";
   else if (self.classname == "monster_demon1")
      gibname = "progs/h_demon.mdl";
   else if (self.classname == "monster_wizard")
      gibname = "progs/h_wizard.mdl";
   else if (self.classname == "monster_zombie")
      gibname = "progs/h_zombie.mdl";
   else if (self.classname == "monster_dog")
      gibname = "progs/h_dog.mdl";
   else if (self.classname == "monster_hell_knight")
      gibname = "progs/h_hellkn.mdl";
   else if (self.classname == "monster_enforcer")
      gibname = "progs/h_mega.mdl";
   else if (self.classname == "monster_army")
      gibname = "progs/h_guard.mdl";
   else if (self.classname == "monster_shalrath")
      gibname = "progs/h_shal.mdl";
   else if (self.classname == "monster_gremlin")
      gibname = "progs/h_grem.mdl";
   else if (self.classname == "monster_scourge")
      gibname = "progs/h_scourg.mdl";
   else if (self.classname == "monster_fish")
      gibname = "progs/gib1.mdl";
   else
      gibname = "progs/h_player.mdl";
   ThrowHead(gibname,dm);
   };
//===========================================================================

/*
============
Gremlin_Damage

The damage is coming from inflictor, but get mad at attacker
============
*/
void(entity targ, entity inflictor, entity attacker, float damage) Gremlin_Damage=
{
// check for godmode or invincibility
	if (targ.flags & FL_GODMODE)
		return;
	if (targ.invincible_finished >= time)
	{
		if (self.invincible_sound < time)
		{
			sound (targ, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM);
			self.invincible_sound = time + 2;
		}
		return;
	}

// do the damage
  targ.health = targ.health - damage;
};

void() Gremlin_Split =
{
  local entity grem;
  local entity temp;
  local entity head;
  local float done;
  local vector ang;
  local float c;
  local vector pos;
  local float proceed;

  if (NumSpawnGremlins >= (NumGremlins*2))
    return;
  done = 0;
  c = 0;
  ang = self.angles;
  while (done == 0)
  {
    makevectors(ang);
    pos = self.origin + (80 * v_forward);
    head = findradius(pos, 35);
    proceed = 1;
    while (head)
    {
      if ((head.health > 0) && (head.flags & (FL_MONSTER | FL_CLIENT)))
        proceed = 0;
      head = head.chain;
    }
    traceline(self.origin,pos,FALSE,self);
    if (trace_fraction == 1 && (proceed == 1))
    {
      traceline(self.origin,(pos-'40 40 0'),FALSE,self);
      if (trace_fraction == 1)
      {
        traceline(self.origin,(pos+'40 40 0'),FALSE,self);
        if (trace_fraction == 1)
        {
          traceline(self.origin,(pos + '0 0 64'),FALSE,self);
          if (trace_fraction == 1)
          {
            traceline(self.origin,(pos - '0 0 64'),FALSE,self);
            if (trace_fraction != 1)
            {
              done = 1;
            }
          }
        }
      }
    }
    if (done == 0)
    {
      ang_y = ang_y + 36;
      c = c + 1;
      if (c==10)
      {
        return;
      }
    }
  }
  NumSpawnGremlins = NumSpawnGremlins + 1;
  grem = spawn();
  SUB_CopyEntity(self,grem);
  grem.solid = SOLID_SLIDEBOX;
  grem.movetype = MOVETYPE_STEP;
  setmodel (grem, "progs/grem.mdl");
  setsize (grem, VEC_HULL_MIN, VEC_HULL_MAX);
  grem.health = 50; //Ry: Set the new Gremlin to a flat 50 health, and leave the source Gremlin alone

  grem.isspawnee = TRUE; //Ry: Take note that this was a spawned Gremlin
  if (self.charmed) //Ry: Also copy Horn of Conjuring status
  {
    self.charmer.charmedmonsters += 1;
    grem.charmer = self.charmer; 
    grem.charmed = self.charmed;
    grem.empathy_item = self.empathy_item;
    if (grem.empathy_item) //Ry: Increment count on the item so the newly spawned gremlin will also have to be killed for the horn to come back
      grem.empathy_item.count = grem.empathy_item.count + 1;
  }
  else //Ry: Don't add to count when charmed
  {
    total_monsters = total_monsters + 1;
    WriteByte (MSG_BROADCAST, SVC_UPDATESTAT);
    WriteByte (MSG_BROADCAST, STAT_TOTALMONSTERS);
    WriteLong (MSG_BROADCAST, total_monsters);
  }
  if (self.enemy && (self.enemy.health > 0) && ( (self.enemy.flags & FL_CLIENT) || self.charmed )) //Ry: Also copy Gremlin's current enemy
    grem.enemy = self.enemy;
   
  grem.items = 0; //Ry: Remove any weapons and ammo copied by SUB_CopyEntity
  grem.weapon = 0; //(Could potentially make it so a Gremlin will share an extra weapon they have with the spawn)
  grem.currentammo = 0;
  grem.AMMO_SHELLS = 0;
  grem.AMMO_NAILS = 0;
  grem.AMMO_ROCKETS = 0;
  grem.AMMO_CELLS = 0;
  grem.combat_style = CS_MELEE;

  setorigin(grem, pos);
  temp = self;
  self = grem;
  gremlin_spawn1();
  self.enemy = world;
  Gremlin_UpdateState(GREM_DEFAULT);
  self = temp;
};

void(float side)  Gremlin_Gorge =
{
	local	float	ldmg;
	local vector	delta;
  local entity temp;
  local float gorgingzombie;
  
  if ((self.enemy.classname == "monster_zombie") && (self.enemy.health > 0))
    gorgingzombie = TRUE;
   
  if (!Gremlin_GorgeValid(FALSE))
    return;

	delta = self.enemy.origin - self.origin;

  sound (self, CHAN_WEAPON, "demon/dhit2.wav", 1, ATTN_NORM);
  if ( ((skill > 2) && !gorgingzombie && !copper_nightmare) || deathmatch ) //Ry: Gorge twice as fast in Nightmare and Deathmatch
    ldmg = 14+10*random();
  else
    ldmg = 7+5*random();
  
  if (self.enemy.health > 0) //Ry: Deal proper damage at positive HP values
    T_Damage(self.enemy, self, self, ldmg);
  else
    Gremlin_Damage (self.enemy, self, self, ldmg);

  if (self.health < self.max_health) //Ry: Heal during the process, instead of when the split occurs, to benefit multiple Gremlins
  {
    self.health = self.health + ceil(ldmg/2);
    if (self.health > self.max_health)
      self.health = self.max_health;
  }

	makevectors (self.angles);
	SpawnMeatSpray (self.origin + v_forward*16, side * v_right);
  if ( (self.enemy.health < -200.0) || (gorgingzombie && (self.enemy.health <= 0)) )
  {
    if (gorgingzombie) //Ry: Zombie should have already gibbed and such
    {
      Gremlin_Split();
    }
    else if (!self.enemy.gremstate)
    {
      self.enemy.gremstate = GREM_GORGING;
      sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
      temp = self;
      self = self.enemy;
      Gremlin_ThrowHead(-15);
      self = temp;
      Gremlin_Split();
    }
    self.enemy = world;
    Gremlin_UpdateState(GREM_DEFAULT);
    gremlin_look1();
  }
};


void()   Gremlin_JumpTouch =
{
  if (self.health <= 0)
		return;

  //Ry: Try to steal a weapon if the Gremlin collides with their target mid-jump
  if ( !self.gremstate && (other == self.enemy) && (other.health > 0) && other.weapon )
  {
    GremlinAttemptWeaponSteal();
  }
  
	if (!checkbottom(self))
      {
		if (self.flags & FL_ONGROUND)
         {
         self.touch = SUB_Null;
         self.think = gremlin_jump1;
         self.nextthink = time + 0.1;
         }
		return;	// not on ground yet
      }

	self.touch = SUB_Null;
   self.think = gremlin_jump12;
	self.nextthink = time + 0.1;
};

void()   Gremlin_FlipTouch =
{
	if (!checkbottom(self))
      {
		if (self.flags & FL_ONGROUND)
         {
         self.touch = SUB_Null;
         self.think = gremlin_gib; //Ry: This used to call the backflip death again, which yeah, don't :V
         self.nextthink = time + 0.1;
         }
		return;	// not on ground yet
      }

	self.touch = SUB_Null;
   self.think = gremlin_flip8;
	self.nextthink = time + 0.1;
};
