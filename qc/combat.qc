
#ifdef GAME_ROGUE
  float IsExplosionDamage;
#endif

void() T_MissileTouch;
void() info_player_start;
void(entity targ, entity attacker) ClientObituary;

void() monster_death_use;

// Yoder Sept24 2021 Horde Merge
void() horde_spawn_powerup;



//======================
//  New Subs by Ryason
//======================

#ifdef GAME_HIPNOTIC
  #ifdef ENGINE_KEX
    //Ry: If the Charmed monsters of a player see that the player is in combat, have them join in
    void(entity user, entity offender) AlertCharmedMonsters =
    {
      local	entity stemp, ent;
      local float valid, compare;
      
      stemp = self;
      if ( (user.flags & FL_CLIENT) && (user.charmedmonsters > 0) && (offender.flags & (FL_CLIENT|FL_MONSTER)) && (offender.team != user.team) )
      {
        traceline (user.origin + user.view_ofs, offender.origin + offender.view_ofs, TRUE, user);
        if (trace_fraction <= 1) //Ry: Make sure charmer can see enemy
        {
          user.charmedmonsters = 0; //Ry: Re-count these to make sure
          ent = find(world, category, "charmed_monster");
          while(ent)
          {
            if ( (ent.health > 0) && (ent.charmer == user) )
            {
              user.charmedmonsters += 1;
              if (!ent.enemy || (ent.enemy == user))
              {
                self = ent;
                if (visible(user))
                {
                  valid = walkpathtogoal(0,offender.origin); //Ry: See if monster can path to target via navs
                  /*dprint("Charmed ");
                  dprint(self.classname);
                  dprint(" has path status ");
                  dprint(ftos(valid));
                  dprint(" to target\n");*/
                  if (!valid) //Ry: Otherwise, check height difference and distance
                  {
                    //Ry: Distance check
                    compare = vlen(offender.origin-self.origin);
                    /*dprint(" Distance: ");
                    dprint(ftos(compare));
                    dprint("\n");*/
                    if (compare < 700)
                    {
                      //Ry: Height difference
                      compare = (offender.origin_z - self.origin_z);
                      /*dprint(" Height Diff: ");
                      dprint(ftos(compare));
                      dprint("\n");*/
                      if ( self.combat_style != CS_MIXED_ABOVE ) //Ry: Ogres will attack downwards
                        compare = fabs(compare);
                      compare = (compare * -1);
                      if ( compare >= -50 )
                      {
                        valid = TRUE;
                      }
                    }
                  }
                  if (valid)
                  {
                    //dprint("  Charmed monster react\n");
                    self.enemy = offender;
                    FoundTarget();
                  }
                }
              }
            }
            ent = find(ent, category, "charmed_monster");
          }
        }
      }
      self = stemp;
    }
  #endif
#endif

//Ry: Calculate how much damage is required to kill the player
float(entity targ) GetEffectiveHealth =
{
  if (targ.armorvalue <= 0) //No armor
    return targ.health;
  if ( targ.armortype >= 1) //Full absorption (would divide by zero if 1 is passed)
    return (targ.health + targ.armorvalue);
  local float eff = ceil( targ.health*(1/(1-targ.armortype)) );
  if (eff > (targ.health + targ.armorvalue))
    eff = targ.health + targ.armorvalue;
  return eff;
}

//===================
//  End of new subs
//===================



//============================================================================

/*
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============
*/
float(entity targ, entity inflictor) CanDamage =
{
// bmodels need special checking because their origin is 0,0,0
	if (targ.movetype == MOVETYPE_PUSH)
	{
		traceline(inflictor.origin, 0.5 * (targ.absmin + targ.absmax), TRUE, self);
		if (trace_fraction == 1)
			return TRUE;
		if (trace_ent == targ)
			return TRUE;
		return FALSE;
	}

	traceline(inflictor.origin, targ.origin, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '15 15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '-15 -15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '-15 15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '15 -15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;

	return FALSE;
};

/*
============
Killed
============
*/
void(entity targ, entity attacker) Killed =
{
	local entity oself;

	oself = self;
	self = targ;

	if (self.health < -99)
		self.health = -99;		// don't let sbar look bad if a player
  #ifdef GAME_HIPNOTIC
    //MED
    if (self.charmed)
    {
      self.charmer.charmedmonsters -= 1; //Ry: Decrement number of charmed monsters
      self.effects = self.effects - (self.effects & EF_DIMLIGHT);
      if (self.trigger_field) //Ry: Remove charmed monster's goal entity
      {
        remove(self.trigger_field);
      }
    }
  #endif

	if (self.movetype == MOVETYPE_PUSH || self.movetype == MOVETYPE_NONE)
	{	// doors, triggers, etc
    activator = attacker; //Ry: Forward this
		self.th_die ();
		self = oself;
		return;
	}

	self.enemy = attacker;
  
	// Yoder March04 2022, punish team killspree
	if (horde && (attacker.classname == "player") && (targ.classname == "player"))
	{
		dprint("punish teamkill\n");
		attacker.killtime = 0;
		attacker.frags -= 2;
	}

// bump the monster counter
  if (self.flags & FL_MONSTER)
	{
		// Yoder Sept24, 2021 Horde Merge
		if (horde_ent)
		{
      #ifdef GAME_HIPNOTIC
      if (!self.charmed && (self.classname != "monster_zombie")) //Ry: Exclude charmed monsters as well [08-22-2022]
      #else
			if (self.classname != "monster_zombie") // zombies don't count
      #endif
			{
				killed_monsters = killed_monsters + 1;
				WriteByte (MSG_ALL, SVC_KILLEDMONSTER); 
			}
			
			// check kill spree
			if (attacker.classname == "player")
			{
				attacker.killspree++;
				attacker.killtime = time + KILLSPREE_GAP;
					
        if (time < attacker.killtime)
        {
          #ifdef ENGINE_KEX
            if (attacker.killspree >= 14)
              sprint(attacker, "$qc_horde_streak_generic", ftos(attacker.killspree));
            else if (attacker.killspree == 13)
              sprint(attacker, "$qc_horde_streak_13");
            else if (attacker.killspree == 12)
              sprint(attacker, "$qc_horde_streak_12");
            else if (attacker.killspree == 11)
              sprint(attacker, "$qc_horde_streak_11");
            else if (attacker.killspree == 10)
              sprint(attacker, "$qc_horde_streak_10");
            else if (attacker.killspree == 9)
              sprint(attacker, "$qc_horde_streak_9");
            else if (attacker.killspree == 8)
              sprint(attacker, "$qc_horde_streak_8");
            else if (attacker.killspree == 7)
              sprint(attacker, "$qc_horde_streak_7");
            else if (attacker.killspree == 6)
              sprint(attacker, "$qc_horde_streak_6");
            else if (attacker.killspree == 5)
              sprint(attacker, "$qc_horde_streak_5");
            else if (attacker.killspree == 4)
              sprint(attacker, "$qc_horde_streak_4");
            else if (attacker.killspree == 3)
              sprint(attacker, "$qc_horde_streak_3");
            else if (attacker.killspree == 2)
              sprint(attacker, "$qc_horde_streak_2");
          #else
            if (attacker.killspree >= 14)
            {
              sprint(attacker,ftos(attacker.killspree));
              sprint(attacker," KILLS!\n");
            }
            else if (attacker.killspree == 13)
              sprint(attacker, "KILLOGRAM!\n");
            else if (attacker.killspree == 12)
              sprint(attacker, "KILLAMITY!\n");
            else if (attacker.killspree == 11)
              sprint(attacker, "KILLUSTRIOUS!\n");
            else if (attacker.killspree == 10)
              sprint(attacker, "DEATH INCARNATE!\n");
            else if (attacker.killspree == 9)
              sprint(attacker, "MASSACRE!\n");
            else if (attacker.killspree == 8)
              sprint(attacker, "RAMPAGE!\n");
            else if (attacker.killspree == 7)
              sprint(attacker, "ONSLAUGHT!\n");
            else if (attacker.killspree == 6)
              sprint(attacker, "UBER KILL!\n");
            else if (attacker.killspree == 5)
              sprint(attacker, "PENTA KILL!\n");
            else if (attacker.killspree == 4)
              sprint(attacker, "QUAD KILL!\n");
            else if (attacker.killspree == 3)
              sprint(attacker, "TRIPLE KILL!\n");
            else if (attacker.killspree == 2)
              sprint(attacker, "DOUBLE KILL!\n");
          #endif
        }
			}
			
			// check to see about spawning a powerup
			horde_spawn_powerup();
		}
    else
    {
      #ifdef GAME_HIPNOTIC
      if (!self.charmed) //Ry: Exclude charmed monsters from the monster count
      {
      #endif
        killed_monsters = killed_monsters + 1;
        WriteByte (MSG_ALL, SVC_KILLEDMONSTER);
      #ifdef GAME_HIPNOTIC
      }
      if (deathmatch)
      {
        if (self.charmed && self.empathy_item) //Ry: If monster was summoned from a Horn, run the function on the horn to count the monsters killed
        {
          local entity stemp = self;
          self = self.empathy_item;
          self.use();
          self = stemp;
        }
        else if (self.classname == "monster_armagon") //Ry: Armagon gives frags in Deathmatch
        {
          if (attacker.classname != "player") //Ry: In case Armagon suicides with rockets
            attacker = self.lastdamager;
          if (attacker) //Ry: Ensure there's actually an attacker, in case of genocide cheat before anyone attacks Armagon [08-02-2022]
          {
            local float killerfrags = 2;
            local entity killer = attacker; //Ry: Store killing player separately, since it could be a charmed monster that got the final hit
            if (killer.charmer)
              killer = killer.charmer;
            bprint("Armagon was bested by ");
            bprint(killer.netname);
            bprint("\n");
            
            local float playercount = 0;
            local entity e,player1,player2,player3;
            
            for (e = find(world, classname, "player") ; e ; e = find(e, classname, "player") ) //Ry: Sort Top 3 damagers
            {
              if (e.flags & FL_CLIENT)
              {
                playercount = playercount + 1;
                if (e.bossdamage > 0)
                {
                  HighestBossDamage(e,player1);
                  player1 = sort1;
                  if (sort2)
                  {
                    HighestBossDamage(sort2,player2);
                    player2 = sort1;
                    if (sort2)
                    {
                      HighestBossDamage(sort2,player3);
                      player3 = sort1;
                    }
                  }
                }
              }
            }
            
            if (player1 && playercount > 1)
            {
              bprint(" Most damage from ");
              bprint(player1.netname);
              
              if ( !player2 || (player1.bossdamage >= player2.bossdamage * 3) ) //Ry: Player 1 gets all the points
                if (player1 == killer) //Ry: If the killer also did enough damage to be top 3, store the frags and add them after
                  killerfrags = killerfrags + 3;
                else
                  ClientAwardFrag(self,player1,killer,3);
              else if (!player3 || (player1.bossdamage >= player2.bossdamage * 2)) //Ry: Player 1 gets 2 points, Player 2 gets 1
              {
                if (player1 == killer)
                  killerfrags = killerfrags + 2;
                else
                  ClientAwardFrag(self,player1,killer,2);
                if (player2)
                {
                  bprint(" and ");
                  bprint(player2.netname);
                  if (player2 == killer)
                    killerfrags = killerfrags + 1;
                  else
                    ClientAwardFrag(self,player2,killer,1);
                }
              }
              else //Ry: Even distribution between 3 players
              {
                if (player1 == killer)
                  killerfrags = killerfrags + 1;
                else
                  ClientAwardFrag(self,player1,killer,1);

                bprint(", ");
                bprint(player2.netname);
                if (player2 == killer)
                  killerfrags = killerfrags + 1;
                else
                  ClientAwardFrag(self,player2,killer,1);

                bprint(", and ");
                bprint(player3.netname);
                if (player3 == killer)
                  killerfrags = killerfrags + 1;
                else
                  ClientAwardFrag(self,player3,killer,1);

              }
              bprint("\n");
            }  
            ClientAwardFrag(self,killer,attacker,killerfrags); //Ry: Award accumulated frags to the killer
          }
        }
      }
      #endif
    }
    
    if ( !deathmatch && (attacker.classname == "player") ) //Ry: Remaster mechanic of giving a frag for each killed monster
      attacker.frags = (attacker.frags + 1);

    #ifdef ENGINE_KEX
      #ifdef GAME_HIPNOTIC
      if ( (attacker != self) && (attacker.flags & FL_MONSTER) && !self.charmed && !attacker.charmed ) //Ry: Exclude charmed monsters from the achievement
      #elifdef GAME_ROGUE
      if ( (attacker != self) && (attacker.flags & FL_MONSTER) && (attacker.classname != "actor") ) //Ry: Exclude ending player actor
      #else
      if ( (attacker != self) && (attacker.flags & FL_MONSTER) )
      #endif
      {
        WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
        WriteString(MSG_ALL, "ACH_FRIENDLY_FIRE");
      }
    #endif
	}
  
  #ifdef GAME_ROGUE
    // PGM - guarantee gib if killed by buzzsaw.
    if (attacker.classname == "buzzsaw" || 
      attacker.classname == "Vengeance" ||
      attacker.classname == "pendulum")
      self.health = -99;

    // PGM - gravity fix!
    self.gravity = 1.0;
  #endif

	ClientObituary(self, attacker);

	self.takedamage = DAMAGE_NO;
	self.touch = SUB_Null;

	monster_death_use();
	self.th_die ();

	self = oself;
};

#ifdef GAME_ROGUE
  // ====
  // Function prototype for shield impact handler.
  // ====
  float(entity targ, entity inflictor, entity attacker, float damage) shield_hit;
#endif

/*
============
T_Damage

The damage is coming from inflictor, but get mad at attacker
This should be the only function that ever reduces health.
============
*/
#ifdef GAME_HIPNOTIC
  //MED 01/10/97 added empathyused variable
  float empathyused;
#endif
void(entity targ, entity inflictor, entity attacker, float damage) T_Damage=
{
	local	vector	dir;
	local	entity	oldself;
	local	float	save;
	local	float	take;
  local float knockbackmult = 1;

	if (!targ.takedamage)
		return;

	// mal: in Coop, don't let bots hurt human teammates - that would be REALLY annoying...
	if ( coop && targ != attacker && targ.classname == "player" && attacker.classname == "player" ) {
		if ( attacker.flags & FL_ISBOT && !( targ.flags & FL_ISBOT ) ) {
			return;
		}
	}	

  #ifdef GAME_HIPNOTIC
    if ( (attacker.deathtype == "discharge") && targ.wetsuit_finished )
      return;
  #endif
  //MED moved damage_attacker down a bit
  
  #ifdef GAME_ROGUE
    if (targ.classname == "trigger_explosion")
    {
      if ( IsExplosionDamage != 1)
        return;
    }

    if (targ.items2 & IT2_SHIELD)
    {
      // Allow some damage to pass through.
      damage = shield_hit(targ, inflictor, attacker, damage);
      if (damage == 0)
        return;
    }
  #endif

// check for quad damage powerup on the attacker
	if (attacker.super_damage_finished > time)
		damage = damage * 4;
  #ifdef GAME_ROGUE
    // rune power up (Black Magic)
    if (deathmatch)
      damage = RuneApplyBlack(damage, attacker);
  #endif

  #ifdef GAME_HIPNOTIC
    //MED
    //check for empathy shields
    if (targ.items2 & HIP_IT_EMPATHY_SHIELDS)
    {
      if (!(inflictor.items2 & HIP_IT_EMPATHY_SHIELDS) && (targ != attacker)) //Ry: Will now cut damage even if the inflictor is the user
      {
        empathyused = 1;
        if (attacker.flags & FL_CLIENT || !hip_rebalance) //Ry: Now only players recieve half damage back; Everything else takes full damage
          T_Damage (attacker,targ,targ,damage/2);
        else
          T_Damage (attacker,targ,targ,damage);
        empathyused = 0;
      }
      else if (targ == attacker && !hip_rebalance)
        knockbackmult = 2; //Ry: Ensure same rocket jump strength
      damage = damage/2;
    }
  #endif

//MED
// used by buttons and triggers to set activator for target firing
	damage_attacker = attacker;

//MED
// used to keep track of what hit us
   damage_inflictor = inflictor;

// save damage based on the target's armor level

  #ifdef GAME_ROGUE
    //ZOID--
    if (TeamArmorDam(targ, inflictor, attacker, damage))
      save = ceil(targ.armortype*damage);
    else
      save = 0;
    //--ZOID
  #else
    save = ceil(targ.armortype*damage);
  #endif
	if (save >= targ.armorvalue)
	{
		save = targ.armorvalue;
		targ.armortype = 0;	// lost all armor
    #ifdef GAME_ROGUE
      targ.items2 = targ.items2 - (targ.items2 & (IT2_ARMOR1 | IT2_ARMOR2 | IT2_ARMOR3));
    #else
      targ.items = targ.items - (targ.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
    #endif
  }

	targ.armorvalue = targ.armorvalue - save;
	take = ceil(damage-save);

// add to the damage total for clients, which will be sent as a single
// message at the end of the frame
// FIXME: remove after combining shotgun blasts?
	if (targ.flags & FL_CLIENT)
	{
		targ.dmg_take = targ.dmg_take + take;
		targ.dmg_save = targ.dmg_save + save;
		targ.dmg_inflictor = inflictor;
	}

// figure momentum add
	if ( (inflictor != world) && (targ.movetype == MOVETYPE_WALK) ) //Ry: No knockback when protecting
	{
		dir = targ.origin - (inflictor.absmin + inflictor.absmax) * 0.5;
		dir = normalize(dir);
		targ.velocity = targ.velocity + dir*(damage*knockbackmult)*8;
	}
  
  local float teamdamage;
  teamdamage = 0;
  
// team play damage avoidance
  #ifdef GAME_ROGUE
  if (!TeamHealthDam(targ, inflictor, attacker, damage))
  #else
  if ( (targ != attacker) && (teamplay == 1) && (targ.team > 0) && (targ.team == attacker.team) ) //Ry: Allow self damage in Teamplay
  #endif
		teamdamage = 1;
    
  //Ry: Record who last damaged the player in DM, and at what time
  if (deathmatch  && (targ != attacker) && (teamdamage == 0) && (targ.classname == "player") )
  {
    if ((attacker.solid == SOLID_BSP) && (attacker != world) && attacker.lastdamager && (attacker.lastdamager.classname == "player") && (attacker.lastdamager != targ)) //Ry: Another player influenced a mechanism to crush this player
    {
      targ.lastdamagetime = time;
      targ.lastdamager = attacker.lastdamager;
    }
    else if (attacker.classname == "teledeath" || attacker.classname == "teledeath2" || attacker.classname == "teledeath_fast") //Ry: Telefrag [11-12-2022]
    {
      targ.lastdamagetime = time;
      targ.lastdamager = attacker.owner;
    }
    #ifdef GAME_HIPNOTIC
    else if (attacker.classname == "player" || (attacker.flags & FL_MONSTER && attacker.charmer) ) //Ry: Set damager if damager is a player, or a charmed monster in SoA
    #else
    else if (attacker.classname == "player" )
    #endif
    {
      targ.lastdamagetime = time;
      targ.lastdamager = attacker;
    }
    else if (time <= (targ.lastdamagetime + 3)) //Reset time if damaged within the threshold
      targ.lastdamagetime = time;
  }

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
  #ifdef GAME_HIPNOTIC
    //MED
    if (targ.items2 & HIP_IT_EMPATHY_SHIELDS)
    {
        if (self.empathy_sound < time)
      {
           sound (targ, CHAN_ITEM, "hipitems/empathy2.wav", 1, ATTN_NORM);
           self.empathy_sound = time + 0.5;
      }
    }
  #endif

  if (teamdamage == 1) //Ry: Moved the team check earlier so Ring Out check can account for Invuln
    return;
    
  #ifdef GAME_ROGUE
    // rune power up (Earth Magic)
    if (deathmatch)
      take = RuneApplyEarth(take, targ);
  #endif

// do the damage
	targ.health = targ.health - take;
  
  #ifdef GAME_HIPNOTIC
    if (targ.classname == "monster_armagon") //Ry: Track damage on Armagon
    {
      if (attacker.flags & FL_CLIENT) //Ry: Player
      {
        attacker.bossdamage = attacker.bossdamage + take;
        targ.lastdamager = attacker;
      }
      else if (attacker.charmer && (attacker.charmer.flags & FL_CLIENT)) //Ry: Charmed monster
      {
        attacker.charmer.bossdamage = attacker.charmer.bossdamage + take;
        targ.lastdamager = attacker;
      }
    }
  #endif
  
	if ((targ.classname == "player") && (take > 0)) //Ry: Track if has taken damage for Painless Maze
	{
		ach_damagetaken = TRUE;
	}
  
  #if defined(GAME_HIPNOTIC) && defined(ENGINE_KEX)
    if ((attacker != targ) && (attacker.health > 0)) //Ry: Charmed monsters react to charmer being damaged
      AlertCharmedMonsters(targ,attacker);
  #endif

	if (targ.health <= 0)
	{
		Killed (targ, attacker);
		return;
	}

// react to the damage
	oldself = self;
	self = targ;

//MED 10/17/96 added charmed stuff
	if ( (self.flags & FL_MONSTER) && (attacker != world) && (attacker.health > 0) //Ry: Attacker must be alive (Don't aggro on Spike Mines)
    && (!self.nodamagereact) && (!attacker.nodamagereact) ) //Ry: If either entity has this, there is no reaction [10-07-2022]
	{
	// get mad unless of the same class (except for soldiers)
    if (self != attacker && attacker != self.enemy && (!self.team || self.team != attacker.team) ) //Ry: Charmed monsters now check the attacker's team, so will no longer react poorly to other Co-op players
		{
      #ifdef GAME_HIPNOTIC
			if ( (self.classname != attacker.classname) || (attacker.charmed) //Ry: Monsters will now retaliate against charmed monsters of the same species
         || (self.classname == "monster_army" ) || (self.classname == "monster_armagon" ) )
      #else
      if ( (self.classname != attacker.classname) || (self.classname == "monster_army" ) )
      #endif
			{
        if (self.busy) //Ry: Store attacker if monster is performing an attack (This would need to be set up per monster)
          self.nextenemy = attacker;
        //Ry: There's a delay before a monster can switch targets between two player team entities (player or charmed monster); Exception is if the current enemy is not visible
        else if ( self.enemy.health <= 0 || !( (attacker.team > 0) && (self.enemy.team > 0) ) || (time >= self.lastfoetime + 3) || !visible(self.enemy) )
        {
          if (self.enemy.classname == "player")
            self.oldenemy = self.enemy;
          self.enemy = attacker;
          FoundTarget ();
        }
			}
		}
	}

	if (self.th_pain)
	{
		self.th_pain (attacker, take);
	// nightmare mode monsters don't go into pain frames often
		if ((skill >= 3) && !copper_nightmare) //Ry: Copper Nightmare says monster differences bad [07-14-2022]
			self.pain_finished = time + 5;
	}

  #if defined(GAME_HIPNOTIC) && defined(ENGINE_KEX)
    if (attacker != targ) //Ry: Charmed monsters want a piece of whatever their charmer attacked
      AlertCharmedMonsters(attacker,targ);
  #endif

  self = oldself;
};

/*
============
T_RadiusDamage
============
*/
void(entity inflictor, entity attacker, float damage, entity ignore) T_RadiusDamage =
{
	local	float 	points;
	local	entity	head;
	local	vector	org;
  
  #ifdef GAME_ROGUE
    IsExplosionDamage = TRUE;
  #endif
  
	//Look for downed zombies and gib them if possible
	if(damage >= 60)
	{
		head = find(world, classname, "monster_zombie");
		while(head)
		{
			if(head.solid == SOLID_NOT)
			{
				org = head.origin + (head.mins + head.maxs)*0.5;
				points = 0.5*vlen (inflictor.origin - org);
				if (points < 0)
				{
					points = 0;
				}
				points = damage - points;
				if (points > 60)
				{
					if (CanDamage (head, inflictor))
					{	
						T_Damage (head, inflictor, attacker, points);
					}
				}
			}
			head = find(head, classname, "monster_zombie");
		}
	}

	head = findradius(inflictor.origin, damage+40);

	while (head)
	{
		if (head != ignore)
		{
			if (head.takedamage)
			{
				org = head.origin + (head.mins + head.maxs)*0.5;
				points = 0.5*vlen (inflictor.origin - org);
				if (points < 0)
					points = 0;
				points = damage - points;
				if (head == attacker)
					points = points * 0.5;
				if (points > 0)
				{
					if (CanDamage (head, inflictor))
					{	// shambler takes half damage from all explosions
						if (head.classname == "monster_shambler")
							T_Damage (head, inflictor, attacker, points*0.5);
						else
							T_Damage (head, inflictor, attacker, points);
					}
				}
			}
		}
		head = head.chain;
	}
  
  #ifdef GAME_ROGUE
    //Ry: Unset this here, instead of when damaging the very first entity [09-15-2022]
    IsExplosionDamage = FALSE;
  #endif
};

/*
============
T_BeamDamage
============
*/
void(entity attacker, float damage) T_BeamDamage =
{
	local	float 	points;
	local	entity	head;

	head = findradius(attacker.origin, damage+40);

	while (head)
	{
		if (head.takedamage)
		{
			points = 0.5*vlen (attacker.origin - head.origin);
			if (points < 0)
				points = 0;
			points = damage - points;
			if (head == attacker)
				points = points * 0.5;
			if (points > 0)
			{
				if (CanDamage (head, attacker))
				{
					if (head.classname == "monster_shambler")
						T_Damage (head, attacker, attacker, points*0.5);
					else
						T_Damage (head, attacker, attacker, points);
				}
			}
		}
		head = head.chain;
	}
};
