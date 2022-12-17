//Custom subroutines for existing entities by Ryason55

void() W_SetCurrentAmmo;
void() BackpackTouch;
#ifdef GAME_HIPNOTIC
  void() ProximityGrenadeExplode;
#endif
void(entity item, float newalpha) UpdateItemVisibility;

//Custom function that only displays the centerprint if the current one has either expired, or is of equal or higher value
void(entity player, float type, string message1, string message2 = "", string message3 = "", string message4 = "", string message5 = "", string message6 = "") FilteredCenterPrint =
{
  if ( (!(player.flags & FL_ISBOT)) && (message1 != "") ) //Bots don't need centerprints
  {
    if ( (time >= (player.lastcenterprinttime + 5)) || (type >= player.lastcenterprinttype) )
    {
      if ((player.lastcenterprinttype == CPRINT_MOTD) && (player.lastcenterprinttype != type))
      {
        player.motd_time = 0;
        player.motd_count = 0;
      }
      player.lastcenterprinttime = time;
      player.lastcenterprinttype = type;
      #ifndef ENGINE_KEX
      if (message6 != "")
      #endif
        centerprint(player,message1,message2,message3,message4,message5,message6);
      #ifndef ENGINE_KEX
      else if (message5 != "")
        centerprint(player,message1,message2,message3,message4,message5);
      else if (message4 != "")
        centerprint(player,message1,message2,message3,message4);
      else if (message3 != "")
        centerprint(player,message1,message2,message3);
      else if (message2 != "")
        centerprint(player,message1,message2);
      else
        centerprint(player,message1);
      #endif
    }
  }
};

//Runs the above on all players
void(float type, string message1, string message2 = "", string message3 = "", string message4 = "", string message5 = "", string message6 = "") FilteredCenterPrint_All =
{
	entity ent = find(world, classname, "player");
	while(ent)
	{
		FilteredCenterPrint(ent, type, message1, message2, message3, message4, message5, message6);
		ent = find(ent, classname, "player");
	}
}


//Called when a player frags another player, incrementing frag count and showing a message on-screen
void(entity targ, entity attacker, entity inflictor, float add, string extramessage = "") ClientAwardFrag =
{
  if (deathmatch) //Ry: Only award PvP frags in Deathmatch
  {
    if (add > 0)
      attacker.frags = attacker.frags + add;
    else
      attacker.frags = attacker.frags + 1;
    
    if (!(attacker.flags & FL_ISBOT)) //Bots shouldn't get kill messages (unless I start doing sounds or announcements)
    {
      local string combomessage, addedfrags;
      #ifdef ENGINE_KEX
        combomessage = "";
        addedfrags = "";
      #endif
      if (add == 2)
        addedfrags = " (+2)";
      else if (add == 3)
        addedfrags = " (+3)";
      else if (add == 4)
        addedfrags = " (+4)";
      else if (add == 5)
        addedfrags = " (+5)";
      if (time > attacker.lastfragtime+3)
        attacker.fragcombo = 1;
      else
      {
        attacker.fragcombo = attacker.fragcombo + 1;
        if (attacker.fragcombo == 2)
          combomessage = "\nDouble Kill!";
        else if (attacker.fragcombo == 3)
          combomessage = "\nTriple Kill!";
        else if (attacker.fragcombo == 4)
          if (attacker.super_damage_finished) //Ry: Very important
            combomessage = "\nQUADra Kill!";
          else
            combomessage = "\nQuadra Kill!";
        else if (attacker.fragcombo == 5)
          if (attacker.invincible_finished) //Ry: Also important
            combomessage = "\nPENTA Kill!";
          else
            combomessage = "\nPenta Kill!";
        else if ((attacker.fragcombo > 5) && (attacker.fragcombo < 10))
          combomessage = "\nOverkill!";
        else if (attacker.fragcombo >= 10)
          combomessage = "\nAvatar of Death!";
      }
      
      #ifdef ENGINE_KEX
        if ((attacker != inflictor) && inflictor.netname)
          if (inflictor.flags & FL_CLIENT) //Ry: A different player got the kill
            FilteredCenterPrint(attacker,CPRINT_FRAG,"You assisted with fragging {}{}{}",targ.netname,addedfrags,combomessage);
          else //Ry: A summoned monster got the kill
            FilteredCenterPrint(attacker,CPRINT_FRAG,"Your {} fragged {}{}{}",inflictor.netname,targ.netname,addedfrags,combomessage);
        else
          FilteredCenterPrint(attacker,CPRINT_FRAG,"You fragged {}{}{}{}",targ.netname,addedfrags,combomessage,extramessage);
      #else
        if ((attacker != inflictor) && inflictor.netname)
          if (inflictor.flags & FL_CLIENT) //Ry: A different player got the kill
            FilteredCenterPrint(attacker,CPRINT_FRAG,"You assisted with fragging ",targ.netname,addedfrags,combomessage);
          else //Ry: A summoned monster got the kill
            FilteredCenterPrint(attacker,CPRINT_FRAG,"Your ",inflictor.netname," fragged ",targ.netname,addedfrags,combomessage);
        else
          FilteredCenterPrint(attacker,CPRINT_FRAG,"You fragged ",targ.netname,addedfrags,combomessage,extramessage);
      #endif
      attacker.lastfragtime = time;
      //localsound(attacker,"doors/runeuse.wav"); //Ry: Local frag sound, via new Remaster function... Though there isn't a way to adjust volume
    }
  }
}

#ifdef GAME_HIPNOTIC
  entity sort1,sort2;

  //Returns which value is higher for sorting purposes
  void(entity insert, entity current) HighestBossDamage =
  {
    if (!current)
    {
      sort1 = insert;
      sort2 = current;
    }
    else
    {
      if (insert.bossdamage > current.bossdamage)
      {
        sort1 = insert;
        sort2 = current;
      }
      else
      {
        sort1 = current;
        sort2 = insert;
      }
    }
  }
#endif

void() SetSpawnAmmo = //Ry: Players will retain a small amount of the ammo they had when they respawn (Except shells which will be 25)
{
  parm4 = 25; //Shells

  if ( self.items & (IT_NAILGUN|IT_SUPER_NAILGUN) ) //Nails
    if (self.AMMO_NAILS > 30)
      parm5 = 30;
    else
      parm5 = self.AMMO_NAILS;
  else
    parm5 = 0;

  #ifdef GAME_HIPNOTIC
    if ( self.items & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER|IT_PROXIMITY_GUN) ) //Rockets
  #else
    if ( self.items & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER) )
  #endif
    if (self.AMMO_ROCKETS > 5)
      parm6 = 5;
    else
      parm6 = self.AMMO_ROCKETS;
  else
    parm6 = 0;

  #ifdef GAME_HIPNOTIC
    if ( self.items & (IT_LIGHTNING|IT_LASER_CANNON|IT_MJOLNIR) ) //Cells
  #else
    if ( self.items & IT_LIGHTNING )
  #endif
    if (self.AMMO_CELLS > 15)
      parm7 = 15;
    else
      parm7 = self.AMMO_CELLS;
  else
    parm7 = 0;

  #ifdef GAME_ROGUE
    if ( self.items & (IT_LAVA_NAILGUN|IT_LAVA_SUPER_NAILGUN) ) //Lava Nails
      if (self.ammo_lava_nails > 20)
        parm11 = 20;
      else
        parm11 = self.ammo_lava_nails;
    else
      parm11 = 0;

    if ( self.items & (IT_MULTI_GRENADE|IT_MULTI_ROCKET) ) //Multi Rockets
      if (self.ammo_multi_rockets > 3)
        parm12 = 3;
      else
        parm12 = self.ammo_multi_rockets;
    else
      parm12 = 0;

    if ( self.items & IT_PLASMA_GUN ) //Plasma
      if (self.ammo_plasma > 5)
        parm13 = 5;
      else
        parm13 = self.ammo_plasma;
    else
      parm13 = 0;
  #endif
};

void() coopelevatorcheck = //Ry: Checks if the trigger is linked to an elevator, and if it is, sets the delay to 1 second to give other players in Co-op time to get on
{
  local entity e;
  local float valid,triggertop;
  triggertop = (self.maxs_z+self.origin.z);
  for (e = find(world,targetname,self.target) ; e ; e = find(e,targetname,self.target) )
  {
    if ( (e.classname == "door") || (e.classname == "plat") || (e.classname == "train") || (e.classname == "train2") )
    {
      dprint("Potential elevator trigger with target ");
      dprint(self.target);
      dprint(" targets ");
      dprint(e.classname);
      dprint("\n");
      if (e.classname == "door") //Ry: Extra checks for this, since doors are used as doors sometimes, weirdly enough
      {
        if (triggertop <= (e.maxs_z + e.pos1_z)) //Ry: Elevators have the trigger above in the default position
          dprint(" But trigger is below door\n");
        else
        {
          if (e.movedir_z == 0)
          {
            dprint(" But door moves horizontally\n");
          }
          else
          {
            local float cont = TRUE;
            local vector origvect,targvect;
            origvect = '0 0 0';
            origvect_x = (((e.maxs_x+e.mins_x)/2) + e.pos1_x);
            origvect_y = (((e.maxs_y+e.mins_y)/2) + e.pos1_y);
            origvect_z = ((e.maxs_z + e.pos1_z) - 4);
            if (e.pos1_z < e.pos2_z) //Ry: If starts in bottom position, add player height (+4) to the trace length
            {
              targvect = (origvect + (e.pos2-e.pos1));
              targvect.z = targvect.z + 60;
            }
            else //Ry: If it starts at the top position, make sure it isn't too close to the ceiling
            {
              targvect = (origvect + '0 0 60');
              traceline(origvect,targvect,TRUE,e);
              if (trace_fraction < 1 && !(trace_ent.targetname == self.target))
              {
                dprint(" But door starts too close to the ceiling\n");
                cont = FALSE;
              }
              else
                targvect = (origvect + (e.pos2-e.pos1));
            }
            if (cont)
            {
              traceline(origvect,targvect,TRUE,e);
              if (trace_fraction < 1 && !(trace_ent.targetname == self.target)) //Ry: Collides with an entity that isn't part of the same mechanism
                dprint(" But door moves into the ceiling/floor\n");
              else
              {
                dprint(" Door is a valid elevator!\n");
                valid = TRUE;
                break;
              }
            }
          }
        }
      }
      else
      {
        valid = TRUE;
        break;
      }
    }
  }
  if (valid)
  {
    self.delay = self.delay + 1;
    if (self.delay > 2)
      self.delay = 2;
    dprint(" Added extra delay to trigger\n");
  }
}

//Ry: If an elevator has items linked via super_item, move them all as well
void() MoveItemsWithElevator =
{
  local entity ent;
  ent = self.super_item;
  if (ent)
  {
    while (ent)
    {
      setorigin( ent, ent.owner.origin + ent.effectiveorigin );
      ent.velocity = ent.owner.velocity;
      ent = ent.super_item;
    }
  }
}

//Ry: At least 3 entities are set this up the exact same way, so:
void() PrepareKeyMechanismSounds =
{
  if (self.worldtype) //Ry: Remaster allows overriding worldtype per entity
    self.worldtype = self.worldtype - 1;
  else
    self.worldtype = world.worldtype;
  
  if (self.worldtype == 0)
	{
		precache_sound ("doors/medtry.wav");
		precache_sound ("doors/meduse.wav");
		self.noise3 = "doors/medtry.wav";
		self.noise4 = "doors/meduse.wav";
	}
	else if (self.worldtype == 1)
	{
		precache_sound ("doors/runetry.wav");
		precache_sound ("doors/runeuse.wav");
		self.noise3 = "doors/runetry.wav";
		self.noise4 = "doors/runeuse.wav";
	}
	else if (self.worldtype == 2)
	{
		precache_sound ("doors/basetry.wav");
		precache_sound ("doors/baseuse.wav");
		self.noise3 = "doors/basetry.wav";
		self.noise4 = "doors/baseuse.wav";
	}
	else
	{
		dprint ("no worldtype set!\n");
	}
}

//Ry: Same with this
float() AttemptUnlock =
{
	if ( (self.items & other.items) != self.items )
	{
    if ( (self.classname == "trigger_usekey") && (self.message != "") ) //Ry: Hipnotic entity
    {
      FilteredCenterPrint (activator, CPRINT_WORLD, self.message);
    }
    else
    {
      if (self.items == IT_KEY1)
      {
        if (self.worldtype == WORLDTYPE_BASE)
        {
          #ifdef ENGINE_KEX
            FilteredCenterPrint (other, CPRINT_WORLD, "$qc_need_silver_keycard");
          #else
            FilteredCenterPrint (other, CPRINT_WORLD, "You need the silver keycard");
          #endif
        }
        else if (self.worldtype == WORLDTYPE_METAL)
        {
          #ifdef ENGINE_KEX
            FilteredCenterPrint (other, CPRINT_WORLD, "$qc_need_silver_runekey");
          #else
            FilteredCenterPrint (other, CPRINT_WORLD, "You need the silver runekey");
          #endif
        }
        else if (self.worldtype == WORLDTYPE_MEDIEVAL || self.worldtype == WORLDTYPE_HUB)
        {
          #ifdef ENGINE_KEX
            FilteredCenterPrint (other, CPRINT_WORLD, "$qc_need_silver_key");
          #else
            FilteredCenterPrint (other, CPRINT_WORLD, "You need the silver key");
          #endif
        }
      }
      else if (self.items == IT_KEY2)
      {
        if (self.worldtype == WORLDTYPE_BASE)
        {
          #ifdef ENGINE_KEX
            FilteredCenterPrint (other, CPRINT_WORLD, "$qc_need_gold_keycard");
          #else
            FilteredCenterPrint (other, CPRINT_WORLD, "You need the gold keycard");
          #endif
        }
        else if (self.worldtype == WORLDTYPE_METAL)
        {
          #ifdef ENGINE_KEX
            FilteredCenterPrint (other, CPRINT_WORLD, "$qc_need_gold_runekey");
          #else
            FilteredCenterPrint (other, CPRINT_WORLD, "You need the gold runekey");
          #endif
        }
        else if (self.worldtype == WORLDTYPE_MEDIEVAL || self.worldtype == WORLDTYPE_HUB)
        {
          #ifdef ENGINE_KEX
            FilteredCenterPrint (other, CPRINT_WORLD, "$qc_need_gold_key");
          #else
            FilteredCenterPrint (other, CPRINT_WORLD, "You need the gold key");
          #endif
        }
      }
    }
    sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
		return FALSE;
	}
  return TRUE;
}

//Ry: Find an unused index for the player
void() AssignPlayerIndex =
{
  local float currindex = 1;
  local entity e;
  while (TRUE) //Ry: No idea if this will work above 24 players
  {
    if (currindex > highestplayerindex) //Ry: Need a new index
    {
      highestplayerindex = currindex;
      playerindexinuse = playerindexinuse + currindex;
      self.playerindex = currindex;
      dprint("Assigned NEW ID ");
      dprint(ftos(currindex));
      dprint(" to player\n");
      //Ry: Update transparency on items
      for (e = find(world, category, "item") ; e ; e = find(e, category, "item") )
        if (e.oneperplayer)
          #ifndef ENGINE_WINQUAKE
            UpdateItemVisibility(e,e.alpha);
          #else
            UpdateItemVisibility(e,1);
          #endif
      return;
    }
    else if (!(playerindexinuse & currindex)) //Ry: Reuse an old index
    {
      playerindexinuse = playerindexinuse + currindex;
      self.playerindex = currindex;
      dprint("Assigned existing ID ");
      dprint(ftos(currindex));
      dprint(" to player\n");
      //Ry: Update transparency on items
      for (e = find(world, category, "item") ; e ; e = find(e, category, "item") )
        if (e.oneperplayer)
          #ifndef ENGINE_WINQUAKE
            UpdateItemVisibility(e,e.alpha);
          #else
            UpdateItemVisibility(e,1);
          #endif
      return;
    }
    currindex = currindex * 2;
  }
}

//Ry: Checks if two entities' bounding boxes intersect at all
float(entity ent1, entity ent2, float clearance) BBoxIntersection =
{
  local float coordmin1,coordmax1,coordmin2,coordmax2;
  coordmin1 = ent1.origin_x+(ent1.mins_x-clearance);
  coordmax1 = ent1.origin_x+(ent1.maxs_x+clearance);
  coordmin2 = ent2.origin_x+ent2.mins_x;
  coordmax2 = ent2.origin_x+ent2.maxs_x;
  if ( ((coordmin1 >= coordmin2) && (coordmin1 <= coordmax2)) || ((coordmax1 >= coordmin2) && (coordmax1 <= coordmax2)) || ((coordmin2 >= coordmin1) && (coordmin2 <= coordmax1)) || ((coordmax2 >= coordmin1) && (coordmax2 <= coordmax1)) )
  {
    coordmin1 = ent1.origin_y+(ent1.mins_y-clearance);
    coordmax1 = ent1.origin_y+(ent1.maxs_y+clearance);
    coordmin2 = ent2.origin_y+ent2.mins_y;
    coordmax2 = ent2.origin_y+ent2.maxs_y;
    if ( ((coordmin1 >= coordmin2) && (coordmin1 <= coordmax2)) || ((coordmax1 >= coordmin2) && (coordmax1 <= coordmax2)) || ((coordmin2 >= coordmin1) && (coordmin2 <= coordmax1)) || ((coordmax2 >= coordmin1) && (coordmax2 <= coordmax1)) )
    {
      coordmin1 = ent1.origin_z+(ent1.mins_z-clearance);
      coordmax1 = ent1.origin_z+(ent1.maxs_z+clearance);
      coordmin2 = ent2.origin_z+ent2.mins_z;
      coordmax2 = ent2.origin_z+ent2.maxs_z;
      if ( ((coordmin1 >= coordmin2) && (coordmin1 <= coordmax2)) || ((coordmax1 >= coordmin2) && (coordmax1 <= coordmax2)) || ((coordmin2 >= coordmin1) && (coordmin2 <= coordmax1)) || ((coordmax2 >= coordmin1) && (coordmax2 <= coordmax1)) )
      {
        return TRUE;
      }
    }
  }
  return FALSE;
}

float(float enttype) EntityValidForMode =
{
  #ifdef GAME_HIPNOTIC
    if (initspawner) //Ry: A func_spawn is creating this entity
      return TRUE;
  #endif
  if ((enttype == ENTTYPE_MONSTER) && deathmatch)
  {
    remove(self);
    return FALSE;
  }
  if (!coop && (self.spawnflags & COOP_ONLY))
  {
    remove(self);
    return FALSE;
  }
  //Ry: Additional spawn flags for Horde mode
  if ((cvar("horde") == 1) && !deathmatch)
  {
    if (self.ryspawnflags & RYSPAWNFLAG_HORDEONLY)
      return TRUE;
    if ( ((enttype == ENTTYPE_MONSTER) || (enttype == ENTTYPE_GAMEPLAY)) )
    {
      if ( !(self.ryspawnflags & RYSPAWNFLAG_HORDEENABLE) )
      {
        remove(self);
        return FALSE;
      }
    }
    else if ( self.ryspawnflags & RYSPAWNFLAG_HORDEDISABLE )
    {
      remove(self);
      return FALSE;
    }
  }
  else if ((self.ryspawnflags & RYSPAWNFLAG_HORDEONLY) || (enttype == ENTTYPE_HORDE))
  {
    remove(self);
    return FALSE;
  }
  #ifdef GAME_ROGUE
    if (deathmatch && (teamplay >= TEAM_CTF) && (teamplay <= TEAM_CTF_ALT))
    {
      if ( self.ryspawnflags & RYSPAWNFLAG_CTFEXCLUDE )
      {
        remove(self);
        return FALSE;
      }
    }
    else if (( self.ryspawnflags & RYSPAWNFLAG_CTFONLY ) || (enttype == ENTTYPE_CTF))
    {
      remove(self);
      return FALSE;
    }
  #endif
  return TRUE;
}

float() CheatsAllowed =
{
  #ifndef ENGINE_WINQUAKE
    if ((deathmatch || coop) && (cheats_allowed == FALSE))
    {
      sprint(self,"sv_cheats must be enabled!\n");
      return FALSE;
    }
  #else
    if (deathmatch || coop)
    {
      sprint(self,"Cheats can't be used in multiplayer!\n");
      return FALSE;
    }
  #endif
  return TRUE;
}

//Ry: Checks if a monster can move straight to the designated entity [08-08-2022]
//  Only recommended for use against markers; Will probably fail against smaller entities that are against a wall
float(entity targ) ClearPathToTarget =
{
  local vector vecoffs;
  local float x, y, width;
  if (visible(targ))
  {
    if (self.maxs_x <= 16) //Ry: Only these two sizes matter against world
      width = 16;
    else
      width = 32;
    x = -1;
    while (x < 2)
    {
      y = -1;
      while (y < 2)
      {
        vecoffs = '0 0 0';
        vecoffs_x = width * x;
        vecoffs_y = width * y;
        traceline(self.origin+self.view_ofs+vecoffs, targ.origin+self.view_ofs+vecoffs, TRUE, self);
        if (trace_fraction < 1)
        {
          return FALSE;
        }
        y += 2;
      }
      x += 2;
    }
    return TRUE;
  }
  return FALSE;
}

entity() FindIntermission;

//Ry: Takes the player out of gameplay and sticks them on an info_intermission [08-11-2022]
float() PlayerEnterSpectatorMode =
{
  local entity spot;
  if (!self.goalentity)
  {
    if (self.spawn_deferred)
      self.health = 5; //Ry: This will count down
    else
      self.health = 1;
    self.flags |= FL_NOTARGET; //Ry: Add NoTarget so monsters aren't alarmed
    self.takedamage = DAMAGE_NO;
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    self.deadflag = DEAD_DEAD;
    setmodel(self, "");
    setsize (self, VEC_ORIGIN, VEC_ORIGIN);
    self.velocity = VEC_ORIGIN;

    self.view_ofs = '0 0 1';
    spot = FindIntermission();
    self.v_angle = spot.mangle;
    self.angles = spot.mangle;
    self.fixangle = TRUE;
    self.origin = spot.origin;
    self.weaponmodel = "";
    self.frame = self.weaponframe = 0;
    self.weapon = IT_AXE; //Ry: This needs to be a weapon, or else WinQuake/QuakeSpasm abort with illegible server message
		self.think = SUB_Null;

    self.goalentity = spot; //Ry: Track the current intermission/spectator spot with this [08-11-2022]
    return TRUE;
  }
  return FALSE;
}

//Ry: Move player to next intermission spot if Jump is pressed [08-11-2022]
void() PlayerEvaluateSpectator =
{
  local entity spot;
  if (self.button2)
  {
    if ((self.lip == 0) && (self.goalentity.classname == "info_intermission"))
    {
      self.lip = 1; //Ry: Only once per button press
      spot = find(self.goalentity,classname,"info_intermission");
      if (!spot) //Ry: Looped over to world; Start again
        spot = find(world,classname,"info_intermission");
      if (spot != self.goalentity)
      {
        self.modelindex = modelindex_player; //Ry: Have to pop in the model for a frame so the camera can be moved
        #ifndef ENGINE_WINQUAKE
          self.alpha = 0.01;
        #endif
        setorigin(self,spot.origin);
        self.angles = self.v_angle = spot.mangle;
        self.fixangle = TRUE;
        self.goalentity = spot;
      }
    }
    else if (self.modelindex) //Ry: Clear model again
    {
      self.modelindex = 0;
      #ifndef ENGINE_WINQUAKE
        self.alpha = 0;
      #endif
    }
  }
  else
  {
    self.lip = 0;
    if (self.modelindex) //Ry: Clear model again
    {
      self.modelindex = 0;
      #ifndef ENGINE_WINQUAKE
        self.alpha = 0;
      #endif
    }
  }
}

//Ry: These 2 set light effect on the entity based on the engine using the SET_EF_ constants [08-22-2022]
void(entity ent, float effect, float state) ApplyEffectChange =
{
  if (state)
    ent.effects |= effect;
  else
    ent.effects -= (ent.effects & effect);
}

void(entity ent, float effecttype, float state) SetLightEffect =
{
  if (effecttype > 0)
  {
    if (effecttype == SET_EF_DIM)
    {
      ApplyEffectChange(ent,EF_DIMLIGHT,state);
      return;
    }
    #ifdef GAME_ROGUE
      //Ry: Only flags should have colored lights in CTF
      if ((effecttype < SET_EF_CANDLE) && deathmatch && (teamplay >= TEAM_CTF) && (teamplay <= TEAM_CTF_ALT) && !(ent.flags & FL_OBJECTIVE))
      {
        ApplyEffectChange(ent,EF_DIMLIGHT,state);
        return;
      }
    #endif
    if (cvar("pr_checkextension"))
    {
      if (checkextension("EX_EXTENDED_EF"))
      {
        if (effecttype == SET_EF_QUAD)
          ApplyEffectChange(ent,EF_QUADLIGHT,state);
        else if (effecttype == SET_EF_PENTA)
          ApplyEffectChange(ent,EF_PENTALIGHT,state);
        else if (effecttype == SET_EF_CANDLE)
          ApplyEffectChange(ent,EF_CANDLELIGHT,state);
        return;
      }
      else
      {
        if ((effecttype == SET_EF_QUAD) && checkextension("DP_EF_BLUE"))
        {
          ApplyEffectChange(ent,EF_BLUE,state);
          return;
        }
        else if ((effecttype == SET_EF_PENTA) && checkextension("DP_EF_RED"))
        {
          ApplyEffectChange(ent,EF_RED,state);
          return;
        }
      }
    }
    if (effecttype != SET_EF_CANDLE)
      ApplyEffectChange(ent,EF_DIMLIGHT,state);
  }
}

//Ry: If using Fast Monsters, iterate over every monster and halve think times [09-05-2022]
void() DoFastMonsters =
{
  if (fastmonsters)
  {
    local string categoryname = "monster";
    local entity monster;
    monster = find(world,category,categoryname);
    while (monster)
    {
      if (monster.lastframe != monster.frame) //Ry: Only once per animation frame
      {
        monster.lastframe = monster.frame;
        if (monster.nextthink > time)
        {
          if ( (monster.nextthink < time + 1) || (monster.flags & (FL_ONGROUND|FL_FLY)) )
            monster.nextthink = time + ((monster.nextthink - time)*0.5);
        }
      }
      monster = find(monster,category,categoryname);
      #ifdef GAME_HIPNOTIC
        if (!monster && (categoryname == "monster")) //Ry: Iterate over charmed monsters too
        {
          categoryname = "charmed_monster";
          monster = find(monster,category,categoryname);
        }
      #endif
    }
  }
}

//Ry: To more easily set recoil for Fast Monsters
float(entity ent, float val) AttackRecoil =
{
  if (fastmonsters && (ent.flags & FL_MONSTER))
    val = val * 0.5;
  return time + val;
}

//Ry: To more easily set projectile speed for Fast Monsters
float(entity ent, float val) ProjectileSpeed =
{
  if (fastmonsters && (ent.flags & FL_MONSTER))
    val = val * 1.5;
  return val;
}

//Ry: If the monster was busy doing an attack, unset busy, and target whoever last attacked during the busy state
//    Returns TRUE if the monster changed targets
float() MonsterUnbusy =
{
  if (self.busy)
  {
    self.busy = FALSE;
    if (self.nextenemy)
    {
      if (self.nextenemy != self.enemy)
      {
        if (self.enemy.classname == "player")
          self.oldenemy = self.enemy;
        self.enemy = self.nextenemy;
        FoundTarget ();
        self.nextenemy = world;
        return TRUE;
      }
      self.nextenemy = world;
    }
  }
  return FALSE;
}

//Ry: Scales the given value based on the amount of additional players
float(float input, float addvalue, float hordescale) ScaleByPlayerCount =
{
  local entity curr;
  local float playercount;
  
  curr = find(world, classname, "player");
  while (curr)
  {
    if ((curr.flags & FL_CLIENT) && curr.important)
      playercount = playercount + 1;
    curr = find(curr, classname, "player");
  }

  if (playercount > 1)
  {
    if (hordescale && horde_ent) //Ry: Scale down for Horde mode
      addvalue = addvalue/2;
    return ceil( input + (addvalue * (playercount-1)) );
  }
  return input;
}

//Ry: Sets a monster's health one time if 'justrespawned' is set
void(float input, float addvalue) ScaleHealthByPlayerCount =
{
  if (self.justrespawned && (self.health > 0))
  {
    if (self.max_health) //Ry: This accounts for any damage taken, if set
    {
      local float damage;
      damage = self.max_health - self.health;
      self.health = ScaleByPlayerCount(input,addvalue,TRUE);
      self.health -= damage;
      if (self.health < 1) //Ry: Just in case
        self.health = 1;
    }
    else
    {
      self.health = ScaleByPlayerCount(input,addvalue,TRUE);
    }
    self.justrespawned = FALSE;
  }
}

void(string cvarname, float setting, string name, float defaultstate) ToggleSetting =
{
  local entity p1;
  local float currvalue;
  local string enabletext;

  //Ry: Only the host can change these
  p1 = find(world,classname,"player");
  if (self == p1)
  {
    currvalue = cvar(cvarname);
    if (currvalue & setting) //Ry: Disable
    {
      currvalue -= (currvalue & setting);
      if (defaultstate == TRUE)
        enabletext = "ENABLED";
      else
        enabletext = "DISABLED";
    }
    else //Ry: Enable
    {
      currvalue |= setting;
      if (defaultstate == TRUE)
        enabletext = "DISABLED";
      else
        enabletext = "ENABLED";
    }
    cvar_set(cvarname,ftos(currvalue));
    sprint(self,"\"");
    sprint(self,name);
    sprint(self,"\" will be ");
    sprint(self,enabletext);
    sprint(self," next map\n");
  }
}


#ifdef GAME_HIPNOTIC
  // =================
  //   Hipnotic Subs
  // =================

  void(float newstate) Gremlin_UpdateState;
  void() GremlinAbandonItem;
#endif

#ifdef GAME_ROGUE
  // ==============
  //   Rogue Subs
  // ==============
  
  void() HandleAntiGravBelt =
  {
    if (self.antigrav_finished && !(self.flags & FL_ISBOT))
      if (!hip_rebalance) //Ry: Original behavior
        self.gravity = 0.25;
      else
      {
        local float levelgravmod;
        levelgravmod = cvar("sv_gravity");
        if (levelgravmod == 0) //Ry: Really can't do anything with zero gravity
        {
          self.gravity = 1;
          return;
        }
        levelgravmod = 800/levelgravmod;
        if (self.button2) //Ry: New behavior; Much decreased gravity while holding jump
        {
          self.gravity = 0.1 * levelgravmod;
          if (self.gravity > 1)
            self.gravity = 1;
        }
        else
        {
          self.gravity = levelgravmod;
        }
      }
    else
      self.gravity = 1;
  }
  
  //Ry: Dissolution CTF HUD needs the Teamplay set right locally
  void(entity player) SendTeamplayValue =
  {
    local entity P1;
    P1 = find(world,classname,"player");
    if (player != P1) //Ry: Don't send to host player
    {
      stuffcmd(self,"teamplay ");
      stuffcmd(self,ftos(teamplay));
      stuffcmd(self,"\n");
    }
  }
#endif


// ========================
//   ID1 Replacement Subs
// ========================

#ifndef GAME_ID1
  float(entity ent) HiddenFromSpawnPoint =
  {
    local entity stemp;
    stemp = self;
    if (!deathmatch)
    {
      self = find(world, classname, "info_player_start");
      if (visible(ent))
      {
        self = stemp;
        return FALSE;
      }
      for (self = find(world, classname, "info_player_coop") ; self ; self = find(self, classname, "info_player_coop") )
      {
        if (visible(ent))
        {
          self = stemp;
          return FALSE;
        }
      }
    }
    else
    {
      for (self = find(world, classname, "info_player_deathmatch") ; self ; self = find(self, classname, "info_player_deathmatch") )
      {
        if (visible(ent))
        {
          self = stemp;
          return FALSE;
        }
      }
    }
    self = stemp;
    return TRUE;
  }

  //Ry: If the monster uses a spawn closet with teleporter, grabs the teleporter exit as the origin
  vector(entity ent) GetEffectiveOrigin =
  {
    local entity tele, exit;
    if (!ent.effectiveorigin)
    {
      ent.effectiveorigin = ent.origin;
      for (tele = find(world, classname, "trigger_teleport") ; tele ; tele = find(tele, classname, "trigger_teleport") )
      {
        if ( BBoxIntersection(ent,tele,0) )
        {
          exit = find (world, targetname, tele.target);
          if (exit)
          {
            ent.effectiveorigin = exit.origin;
            break;
          }
        }
      }
    }
    return ent.origin;
  }

  //Ry: visible, but modified to account for where a monster in a spawn box will warp to
  float (entity targ) visible_fromeffectivespawn =
  {
    local vector	spot1, spot2;

    spot1 = GetEffectiveOrigin(self) + self.view_ofs;
    spot2 = GetEffectiveOrigin(targ) + targ.view_ofs;
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

  void() ReplaceMonster =
  {
    if (self.spawnclassname)
    {
      local vector org;
      org = self.origin;
      org_z = org_z + self.mins_z;
      LoadMonster(self,org,self.spawnclassname); //Ry: Change to desired monster and run appropriate state function
      if (self.enemy)
        self.th_run();
      else if (self.goalentity)
        self.th_walk();
      else
        self.th_stand();
      if (self.spawnclassname == "centroid" && missionpackmap > 1) //Ry: Make Centroids drop ammo
      {
        self.AMMO_NAILS = 30;
        self.gib_health = -80; //Ry: Harder to gib [07-31-2022]
      }
    }
    else
    {
      dprint("Entity passed to ReplaceMonster does not have spawnclassname set!\n");
    }
  }

  float() ReplaceValidMonstersInRange =
  {
    local float valid, replacecount, heightdiff;
    local entity stemp, monster_chain, monster_next;
    stemp = self;
    monster_chain = self;
    valid = TRUE;
    //dprint("Running ReplaceValidMonstersInRange\n");
    self.spawnsilent = TRUE;
    while (self)
    {
      //dprint("Iterating on monster ");
      //dprint(ftos(self.spawnmulti));
      //dprint("\n");
      for (monster_next = find(world, classname, self.classname) ; monster_next ; monster_next = find(monster_next, classname, self.classname) )
      {
        //dprint(" Checking against monster ");
        //dprint(ftos(monster_next.spawnmulti));
        //dprint("\n");
        if ( (monster_next != self) && !monster_next.spawnmaster && !monster_next.spawnsilent )
        {
          if ( visible_fromeffectivespawn(monster_next) && (visible_distance <= 400) )
          {
            heightdiff = fabs( self.origin_z - monster_next.origin_z );
            if (heightdiff <= 100)
            {
              //dprint("  Entity valid\n");
              if ( monster_next.spawnclassname == self.spawnclassname )
              {
                //dprint("   Added to chain\n");
                monster_chain.spawnmaster = monster_next;
                monster_chain = monster_next;
                monster_next.spawnsilent = TRUE;
              }
              else //Ry: If any of these fail, do not convert the monsters
              {
                //dprint("   But is not replacable\n");
                valid = FALSE;
              }
            }
          }
        }
      }
      self = self.spawnmaster;
    }
    self = stemp;
    replacecount = 0;
    while (self)
    {
      if (valid)
      {
        ReplaceMonster();
        replacecount = replacecount + 1;
      }
      self.spawnclassname = string_null;
      self = self.spawnmaster;
    }
    if (replacecount)
    {
      dprint("Group of ");
      dprint(ftos(replacecount));
      dprint(" monsters replaced\n");
    }
    return replacecount;
  }
  
  void(string monsterclass, string newmonster, float percent) GenericMonsterReplace =
  {
    local entity monster, stemp;
    local float total, count, valid;
    monster = find(world, classname, monsterclass);
    while (monster)
    {
      total = total + 1;
      #ifdef GAME_ROGUE
      if (newmonster != "sword" || !monster.movetarget)
      #endif
        if (HiddenFromSpawnPoint(monster))
        {
          count = count + 1;
          monster.spawnclassname = newmonster;
        }
      monster = find(monster, classname, monsterclass);
    }
    dprint(ftos(count));
    dprint(" out of ");
    dprint(ftos(total));
    dprint(" ");
    dprint(monsterclass);
    dprint(" are able to be replaced with ");
    dprint(newmonster);
    dprint("\n");
    if (count > 0)
    {
      total = ceil(total*percent);
      if (total > count)
        total = count;
      count = total / count;
      valid = 0;
      total = 0;
      monster = find(world, spawnclassname, newmonster);
      while (monster)
      {
        valid = valid + count;
        if (valid >= 1)
        {
          stemp = self;
          self = monster;
          total = ReplaceValidMonstersInRange();
          valid = valid - total;
          self = stemp;
        }
        monster = find(monster, spawnclassname, newmonster);
      }
    }
  }

  #ifdef GAME_HIPNOTIC
    void() hip_powerup_touch; //Ry: Reference this

    float(entity monster, vector vec1, vector dir, float lowerfloorheight, float valid) CentroidClearanceCheck =
    {
      if (valid >= 0) //Ry: If one of these have failed, skip the rest
      {
        //local entity test;
        local vector vec2;
        local float diff;
        vec2 = vec1 + (dir * 150);
        if (pointcontents(vec2) == CONTENT_EMPTY)
        {
          traceline(vec1,vec2,TRUE,monster); //Ry: Trace around to see if it's an area where the Centroid would have a clear shot
          if (trace_ent.classname == "door")
          { //Ry: If it hits a door, do an additional trace past the door, since it'll probably open up later
            traceline(trace_endpos,vec2,TRUE,trace_ent);
          }
          //test = spawn(); //FOR DEBUGGING
          //test.origin = trace_endpos;
          //setmodel(test,"progs/grenade.mdl");
          if (trace_fraction >= 1)
          { //Ry: Now trace downwards to ensure it's not too high up
            vec1 = vec2 + '0 0 -100';
            traceline(vec2,vec1,TRUE,monster);
            //setorigin(test,trace_endpos);
            if (trace_fraction < 1)
            {
              valid = valid + 1;
              //test.effects = EF_CANDLELIGHT;
            }
            else //Ry: Trace alllll the way down to see if we hit the same floor level as directly underneath the monster
            {
              vec1 = vec2 + '0 0 -1000';
              traceline(vec2,vec1,TRUE,monster);
              if ( trace_fraction < 1 )
              {
                diff = fabs( trace_endpos_z - lowerfloorheight );
                if (diff <= 100)
                {
                  valid = -1;
                }
              }
            }
          }
        }
      }
      return valid;
    }

    void() InjectHipnoticMonsters = //Ry: Convert some monsters to Hipnotic monsters
    {
      local entity stemp, monster;
      local vector org, vec1, vec2;
      local float total, count, valid, lowerfloorheight;
      
      total = 0;
      count = 0;
      for (monster = find(world, classname, "monster_ogre") ; monster ; monster = find(monster, classname, "monster_ogre") )
      {
        total = total + 1;
        //monster.spawnmulti = total; //For debugging
        if (HiddenFromSpawnPoint(monster))
        {
          //dprint("Ogre ");
          //dprint(ftos(total));
          //dprint(": ");
          valid = 0;
          org = GetEffectiveOrigin(monster);
          org_z = org_z + monster.mins_z + 4; //Ry: Move trace origin close to bottom of entity
          
          //Ry: Check if there's a floor underneath the floor this Ogre is on
          lowerfloorheight = org_z + 200;
          vec1 = org;
          vec1_z = vec1_z - 1000;
          traceline(org,vec1,TRUE,monster);
          if (trace_fraction < 1) //Ry: Trace to floor
          {
            vec2 = vec1;
            vec1 = trace_endpos;
            vec1_z = vec1_z - 4;
            traceline(vec1,vec2,TRUE,monster);
            if (trace_fraction < 1) //Ry: Trace to floor below
            {
              lowerfloorheight = trace_endpos_z;
            }
          }
          
          //Ry: Do Traces in 8 directions that check for walls and drops
          valid = CentroidClearanceCheck(monster,org,'1 0 0',lowerfloorheight,valid);
          valid = CentroidClearanceCheck(monster,org,'0 1 0',lowerfloorheight,valid);
          valid = CentroidClearanceCheck(monster,org,'-1 0 0',lowerfloorheight,valid);
          valid = CentroidClearanceCheck(monster,org,'0 -1 0',lowerfloorheight,valid);
          valid = CentroidClearanceCheck(monster,org,'0.7 0.7 0',lowerfloorheight,valid);
          valid = CentroidClearanceCheck(monster,org,'-0.7 0.7 0',lowerfloorheight,valid);
          valid = CentroidClearanceCheck(monster,org,'-0.7 -0.7 0',lowerfloorheight,valid);
          valid = CentroidClearanceCheck(monster,org,'0.7 -0.7 0',lowerfloorheight,valid);
          if (valid >= 3)
          {
            monster.spawnclassname = "centroid";
            count = count + 1;
            //dprint("valid with at least ");
          }
          //dprint(ftos(valid));
          //dprint(" clear directions\n");
        }
      }
      dprint(ftos(count));
      dprint(" out of ");
      dprint(ftos(total));
      dprint(" Ogres are valid for Centroid replacement\n");
      if (count > 0)
      {
        total = ceil(total/4);
        if (total > count)
          total = count;
        count = total / count;
        valid = 0;
        total = 0;
        for (monster = find(world, spawnclassname, "centroid") ; monster ; monster = find(monster, spawnclassname, "centroid") )
        {
          valid = valid + count;
          if (valid >= 1)
          {
            //valid = valid - 1;
            //total = total + 1;
            stemp = self;
            self = monster;
            total = ReplaceValidMonstersInRange();
            valid = valid - total;
            self = stemp;
          }
        }
      }

      GenericMonsterReplace("monster_knight","gremlin",1/6);
    }

    void() ReplaceBiosuits = //Ry: Convert any Biosuits that are near water, but aren't near slime, to Wetsuits
    {
      local vector checkoffset;
      local float nearwater, nearslime, contentval;
      local float count = 0;
      local entity ent;
      
      for (ent = find(world, classname, "item_artifact_envirosuit") ; ent ; ent = find(ent, classname, "item_artifact_envirosuit") )
      {
        nearwater = FALSE;
        nearslime = FALSE;
        checkoffset = '-256 -256 -256';
        if (world.model == "maps/e3m5.bsp") //Ry: Override for this map
          nearwater = TRUE;
        else
        {
          while (TRUE)
          {
            contentval = pointcontents(ent.origin+checkoffset);
            if (contentval == CONTENT_SLIME)
            {
              nearslime = TRUE;
              break;
            }
            else if (contentval == CONTENT_WATER)
              nearwater = TRUE;
            
            checkoffset_x = checkoffset_x + 128;
            if (checkoffset_x > 256)
            {
              checkoffset_x = -256;
              checkoffset_y = checkoffset_y + 128;
              if (checkoffset_y > 256)
              {
                checkoffset_y = -256;
                checkoffset_z = checkoffset_z + 128;
                if (checkoffset_z > 256)
                {
                  break;
                }
              }
            }
          }
        }
        if (nearwater && !nearslime)
        {
          ent.classname = "item_artifact_wetsuit";
          ent.touch = hip_powerup_touch;
          ent.noise = "misc/weton.wav";
          ent.mdl = "progs/wetsuit.mdl";
          if (ent.model)
          {
            setmodel (ent, "progs/wetsuit.mdl");
            setsize (ent, '-16 -16 -24', '16 16 32');
          }
          ent.netname = "Wetsuit";
          ent.items = 0;
          ent.items2 = HIP_IT_WETSUIT;
          count = count + 1;
        }
      }
      if (count > 0)
      {
        dprint("Converted ");
        dprint(ftos(count));
        dprint(" Biosuits to Wetsuits\n");
      }
    };

    void() InjectHipnoticWeapons = //Ry: Changes relevant weapons on map start if the player already has the base weapon
    {
      local entity ent;
      local float replace;
      
      if (!horde_ent)
      {
        replace = 0;
        if (cvar(SETTINGS_CVAR) & RY_FL_PREFERID1WEPS) // Grenade Launcher > Proximity Gun
        {
          if ( (mapstartweapons & IT_GRENADE_LAUNCHER) && (!(mapstartweapons & IT_PROXIMITY_GUN)) )
            replace = 1;
        }
        else // Proximity Gun > Grenade Launcher
        {
          if ( !(mapstartweapons & IT_PROXIMITY_GUN) )
            replace = 1;
        }
        
        if ( replace )
        {
          ent = find(world, classname, "weapon_grenadelauncher");
          if ((ent != world) && !ent.pickers) //Ry: Don't change if a player very quickly picks the weapon item
          {
            ent.classname = "weapon_proximity_gun";
            ent.mdl = "progs/g_prox.mdl";
            if (ent.model)
            {
              setmodel (ent, "progs/g_prox.mdl");
              setsize (ent, '-16 -16 0', '16 16 56');
            }
            ent.weapon = IT_PROXIMITY_GUN;
            ent.netname = "Proximity Gun";
            ent.items = IT_PROXIMITY_GUN;
            dprint("Converted a Grenade Launcher to the Proximity Gun\n");
          }
        }

        replace = 0;
        if (cvar(SETTINGS_CVAR) & RY_FL_PREFERID1WEPS) // Thunderbolt > Laser Cannon > Mjolnir
        {
          if ( (world.model == "maps/e4m8.bsp") && !(mapstartweapons & IT_MJOLNIR) )
            replace = 2; //Mjolnir guaranteed on Nameless City
          else if ( mapstartweapons & IT_LIGHTNING )
          {
            if ( !(mapstartweapons & IT_LASER_CANNON) )
              replace = 1;
            else if ( !(mapstartweapons & IT_MJOLNIR) )
              replace = 2;
          }
        }
        else // Laser Cannon > Mjolnir > Thunderbolt
        {
          if (world.model != "maps/e4m8.bsp") //Thunderbolt guaranteed on Nameless City
          {
            if ( !(mapstartweapons & IT_LASER_CANNON) )
              replace = 1;
            else if ( !(mapstartweapons & IT_MJOLNIR) )
              replace = 2;
          }
        }

        if ( replace == 1 )
        {
          ent = find(world, classname, "weapon_lightning");
          if ((ent != world) && !ent.pickers)
          {
            ent.classname = "weapon_laser_gun";
            ent.mdl = "progs/g_laserg.mdl";
            if (ent.model)
            {
              setmodel (ent, "progs/g_laserg.mdl");
              setsize (ent, '-16 -16 0', '16 16 56');
            }
            ent.weapon = IT_LASER_CANNON;
            ent.netname = "Laser Cannon";
            ent.items = IT_LASER_CANNON;
            dprint("Converted a Thunderbolt to the Laser Cannon\n");
          }
        }
        else if ( replace == 2 )
        {
          ent = find(world, classname, "weapon_lightning");
          if ((ent != world) && !ent.pickers)
          {
            ent.classname = "weapon_mjolnir";
            ent.mdl = "progs/g_hammer.mdl";
            if (ent.model)
            {
              setmodel (ent, "progs/g_hammer.mdl");
              setsize (ent, '-16 -16 0', '16 16 56');
            }
            ent.weapon = IT_MJOLNIR;
            ent.netname = "Mjolnir";
            ent.items = IT_MJOLNIR;
            dprint("Converted a Thunderbolt to the Mjolnir\n");
          }
        }
      }
    };
  #endif
#endif

#ifdef GAME_ROGUE
  void(entity box, float newammoindex) ReplaceAmmoBox =
  {
    if (newammoindex == 5)
    {
      box.classname = "item_lava_spikes";
      if (box.spawnflags & WEAPON_BIG2)
      {
        setmodel (box, "maps/b_lnail1.bsp");
        box.aflag = 50;
        box.view_ofs = '16 16 0';
      }
      else
      {
        setmodel (box, "maps/b_lnail0.bsp");
        box.aflag = 25;
        box.view_ofs = '12 12 0';
      }
      box.weapon = newammoindex;
      box.netname = "lava nails";
    }
    else if (newammoindex == 6)
    {
      box.classname = "item_multi_rockets";
      if (box.spawnflags & WEAPON_BIG2)
      {
        setmodel (box, "maps/b_mrock1.bsp");
        box.aflag = 10;
        box.view_ofs = '16 8 0';
      }
      else
      {
        setmodel (box, "maps/b_mrock0.bsp");
        box.aflag = 5;
        box.view_ofs = '8 8 0';
      }
      box.weapon = newammoindex;
      box.netname = "multi rockets";
    }
    else if (newammoindex == 7)
    {
      box.classname = "item_plasma";
      if (box.spawnflags & WEAPON_BIG2)
      {
        setmodel (box, "maps/b_plas1.bsp");
        box.aflag = 12;
      }
      else
      {
        setmodel (box, "maps/b_plas0.bsp");
        box.aflag = 6;
      }
      box.view_ofs = '16 12 0';
      box.weapon = newammoindex;
      box.netname = "plasma";
    }
    setsize (box, '0 0 0', '32 32 56');
  }
  
  //Ry: Replace this item and the ones around it if they're all valid
  float(entity box, float newammoindex, float remain) ReplaceAmmoCluster =
  {
    local float valid, replaced;
    local entity curritem, nextitem;
    local vector basevec, nextvec;
    
    valid = TRUE;
    replaced = 0;
    basevec = box.origin + box.view_ofs;
    basevec_z += box.maxs_z;
    curritem = box;
    nextitem = find(world,classname,box.classname);
    while (nextitem)
    {
      if (nextitem != box)
      {
        nextvec = nextitem.origin + nextitem.view_ofs;
        nextvec_z += nextitem.maxs_z;
        if (vlen(nextvec-basevec) <= 100)
        {
          traceline(basevec,nextvec,TRUE,box);
          if (trace_fraction >= 1)
          {
            if (nextitem.AGping)
              valid = FALSE;
            replaced += 1;
            curritem.oldenemy = nextitem;
            curritem = nextitem;
          }
        }
      }
      nextitem = find(nextitem,classname,box.classname);
    }
    if (replaced > remain)
      valid = FALSE;
    replaced = 0;
    curritem = box;
    while (curritem)
    {
      if (valid)
      {
        replaced += 1;
        ReplaceAmmoBox(curritem,newammoindex);
      }
      else
        curritem.AGping = TRUE;
      curritem = curritem.oldenemy;
    }
    if (valid)
    {
      dprint(" cluster of ");
      dprint(ftos(replaced));
      dprint(" replaced\n");
    }
    return replaced;
  }

  void(string targetclass, float newammoindex, float density) InjectAmmoType =
  {
    local entity box, secret;
    local float total, count, replaced;
    local vector vec;

    //Ry: Count how many ammo boxes of this type there are
    box = find(world,classname,targetclass);
    total = 0;
    while (box)
    {
      total += 1;
      box = find(box,classname,targetclass);
    }
    dprint(ftos(total));
    dprint(" ");
    dprint(targetclass);
    dprint("\n");
    count = ceil(total * density);
    
    if (total < 1/density)
    {
      dprint("Not enough items\n");
      return;
    }
    
    replaced = 0;

    //Ry: Find ammo close to secrets and change them for sure
    secret = find(world,classname,"trigger_secret");
    while (secret)
    {
      vec = (secret.mins + secret.maxs) / 2;
      box = findradius(vec,300);
      while (box)
      {
        if (box.classname == targetclass && !box.AGping)
        {
          replaced += ReplaceAmmoCluster(box,newammoindex,count-replaced);
          if (replaced >= count)
          {
            dprint("Replaced ");
            dprint(ftos(replaced));
            dprint(" near secrets only\n");
            return;
          }
        }
        box = box.chain;
      }
      secret = find(secret,classname,"trigger_secret");
    }
    dprint("Replaced ");
    dprint(ftos(replaced));
    dprint(" near secrets\n");
    
    //Ry: Go through everything else
    density = density * ((total-replaced)/total);
    total = 0;
    replaced = 0;
    
    box = find(world,classname,targetclass);
    while (box)
    {
      total += density;
      if (total >= 1 && !box.AGping)
      {
        count = ReplaceAmmoCluster(box,newammoindex,count-replaced);
        replaced += count;
        total -= count;
      }
      box = find(box,classname,targetclass);
    }
    dprint("Replaced ");
    dprint(ftos(replaced));
    dprint(" around the level\n");
  }
  
  //Ry: Ammo near weapons should not change
  void(string weaponclass, string ammoclass) MarkAmmoNearWeapon =
  {
    local entity srcitem, dstitem;
    local vector srcvec, dstvec;
    srcitem = find(world,classname,weaponclass);
    while (srcitem)
    {
      srcvec = srcitem.origin;
      srcvec_z += srcitem.maxs_z;
      dstitem = find(world,classname,ammoclass);
      while (dstitem)
      {
        dstvec = dstitem.origin + dstitem.view_ofs;
        dstvec_z += dstitem.maxs_z;
        traceline(srcvec,dstvec,TRUE,srcitem);
        if (trace_fraction >= 1)
          dstitem.AGping = TRUE;
        dstitem = find(dstitem,classname,ammoclass);
      }
      srcitem = find(srcitem,classname,weaponclass);
    }
  }  

  void() InjectAlternateAmmos =
  {
    MarkAmmoNearWeapon("weapon_nailgun","item_spikes");
    MarkAmmoNearWeapon("weapon_supernailgun","item_spikes");
    MarkAmmoNearWeapon("weapon_grenadelauncher","item_rockets");
    MarkAmmoNearWeapon("weapon_rocketlauncher","item_rockets");
    MarkAmmoNearWeapon("weapon_lightning","item_cells");
    InjectAmmoType("item_spikes",  5, 0.4);
    InjectAmmoType("item_rockets", 6, 0.3);
    InjectAmmoType("item_cells",   7, 0.2);
  }
#endif

// ================
//   Impulse Subs
// ================

//Ry: Backpack toss impulse from Dissolution, but with Armagon stuff (impulse 20)
void() TossBackpack =
{
	local entity 	item;

	// If we don't have any ammo, return
	if(self.currentammo <= 0)
		return;

	// only valid in teamplay modes
	if (!coop && teamplay < 1) //Ry: Also allow in Friendly Fire-enabled Co-op
		return;

	item = spawn();

	// See if you have the Shotgun or Super Shotgun on
	if ((self.weapon == IT_SHOTGUN) || (self.weapon == IT_SUPER_SHOTGUN)) {
		if( self.AMMO_SHELLS >= 20 ) {
			item.AMMO_SHELLS = 20;
			self.AMMO_SHELLS = self.AMMO_SHELLS - 20;
		}
		else
		{
			item.AMMO_SHELLS = self.AMMO_SHELLS;
			self.AMMO_SHELLS = 0;
		}
	}

	// See if you have neither the Shotgun or Super Shotgun
	if ( !(self.items & (IT_SHOTGUN|IT_SUPER_SHOTGUN)) ) {
		if( self.AMMO_SHELLS >= 20 ) {
			item.AMMO_SHELLS = 20;
			self.AMMO_SHELLS = self.AMMO_SHELLS - 20;
		} else {
			item.AMMO_SHELLS = self.AMMO_SHELLS;
			self.AMMO_SHELLS = 0;
		}
	}

	// See if we are using a nailgun
	if ((self.weapon == IT_NAILGUN) || (self.weapon == IT_SUPER_NAILGUN) ) {
		if( self.AMMO_NAILS >= 20 ) {
			item.AMMO_NAILS = 20;
			self.AMMO_NAILS = self.AMMO_NAILS - 20;
		} else {
			item.AMMO_NAILS = self.AMMO_NAILS;
			self.AMMO_NAILS = 0;
		}
	}

  #ifdef GAME_ROGUE
    // See if we are using the lava nailguns
    if ((self.weapon == IT_LAVA_NAILGUN) || (self.weapon == IT_LAVA_SUPER_NAILGUN) ) {
      if( self.ammo_lava_nails >= 20 ) {
        item.ammo_lava_nails = 20;
        self.ammo_lava_nails = self.ammo_lava_nails - 20;
      } else {
        item.ammo_lava_nails = self.ammo_lava_nails;
        self.ammo_lava_nails = 0;
      }
    }
  #endif

	// Check to see if we have neither nailgun
	if ( !( self.items & (IT_NAILGUN|IT_SUPER_NAILGUN)) ) {
		if (self.AMMO_NAILS >= 20) {
			item.AMMO_NAILS = 20;
			self.AMMO_NAILS = self.AMMO_NAILS - 20;
		} else {
			item.AMMO_NAILS = self.AMMO_NAILS;
			self.AMMO_NAILS = 0;
		}
    #ifdef GAME_ROGUE
      if( self.ammo_lava_nails >= 20 ) {
        item.ammo_lava_nails = 20;
        self.ammo_lava_nails = self.ammo_lava_nails - 20;
      } else {
        item.ammo_lava_nails = self.ammo_lava_nails;
        self.ammo_lava_nails = 0;
      }
    #endif
	}	
	
	// See if we are using a grenade or rocket launcher
  #ifdef GAME_HIPNOTIC
  if ((self.weapon == IT_GRENADE_LAUNCHER) || (self.weapon == IT_ROCKET_LAUNCHER) || (self.weapon == IT_PROXIMITY_GUN)) {
  #else
  if ((self.weapon == IT_GRENADE_LAUNCHER) || (self.weapon == IT_ROCKET_LAUNCHER)) {
  #endif
		if( self.AMMO_ROCKETS >= 10 ) {
			item.AMMO_ROCKETS = 10;
			self.AMMO_ROCKETS = self.AMMO_ROCKETS - 10;
		} else {
			item.AMMO_ROCKETS = self.AMMO_ROCKETS;
			self.AMMO_ROCKETS = 0;
		}
	}

  #ifdef GAME_ROGUE
    // See if we are using the multi grenade or rocket launcher
    if ((self.weapon == IT_MULTI_GRENADE) || (self.weapon == IT_MULTI_ROCKET)) {
      if (self.ammo_multi_rockets >= 10 ) {
        item.ammo_multi_rockets = 10;
        self.ammo_multi_rockets = self.ammo_multi_rockets - 10;
      } else {
        item.ammo_multi_rockets = self.ammo_multi_rockets;
        self.ammo_multi_rockets = 0;
      }
    }
  #endif

	// See if we have neither the Grenade or rocket launcher
  #ifdef GAME_HIPNOTIC
  if ( !(self.items & (IT_GRENADE_LAUNCHER|IT_ROCKET_LAUNCHER|IT_PROXIMITY_GUN)) ) {
  #else
  if ( !(self.items & (IT_GRENADE_LAUNCHER|IT_ROCKET_LAUNCHER)) ) {
  #endif
		if( self.AMMO_ROCKETS >= 10 ) {
			item.AMMO_ROCKETS = 10;
			self.AMMO_ROCKETS = self.AMMO_ROCKETS - 10;
		} else {
			item.AMMO_ROCKETS = self.AMMO_ROCKETS;
			self.AMMO_ROCKETS = 0;
		}
    #ifdef GAME_ROGUE
      if (self.ammo_multi_rockets >= 10 ) {
        item.ammo_multi_rockets = 10;
        self.ammo_multi_rockets = self.ammo_multi_rockets - 10;
      } else {
        item.ammo_multi_rockets = self.ammo_multi_rockets;
        self.ammo_multi_rockets = 0;
      }
    #endif
	}

	// See if we're using the lightning gun
  #ifdef GAME_HIPNOTIC
  if ( (self.weapon == IT_LIGHTNING) || (self.weapon == IT_LASER_CANNON) || (self.weapon == IT_MJOLNIR) ) {
  #else
  if ( (self.weapon == IT_LIGHTNING) ) {	
  #endif
		if( self.AMMO_CELLS >= 20 ) {
			item.AMMO_CELLS = 20;
			self.AMMO_CELLS = self.AMMO_CELLS - 20;
		} else {
			item.AMMO_CELLS = self.AMMO_CELLS;
			self.AMMO_CELLS = 0;
		}
	}

  #ifdef GAME_ROGUE
    // see if we are using the plasma gun
    if (self.weapon == IT_PLASMA_GUN) {	
      if( self.ammo_plasma >= 10 ) {
        item.ammo_plasma = 10;
        self.ammo_plasma = self.ammo_plasma - 10;
      } else {
        item.ammo_plasma = self.ammo_plasma;
        self.ammo_plasma = 0;
      }
    }
  #endif

	// see if we don't have the lightning gun
  #ifdef GAME_HIPNOTIC
  if ( !(self.items & (IT_LIGHTNING|IT_LASER_CANNON|IT_MJOLNIR)) ) {
  #else
  if ( !(self.items & IT_LIGHTNING) ) {
  #endif
		if( self.AMMO_CELLS >= 20 ) {
			item.AMMO_CELLS = 20;
			self.AMMO_CELLS = self.AMMO_CELLS - 20;
		} else {
			item.AMMO_CELLS = self.AMMO_CELLS;
			self.AMMO_CELLS = 0;
		}
    #ifdef GAME_ROGUE
      if( self.ammo_plasma >= 10 ) {
        item.ammo_plasma = 10;
        self.ammo_plasma = self.ammo_plasma - 10;
      } else {
        item.ammo_plasma = self.ammo_plasma;
        self.ammo_plasma = 0;
      }
    #endif
	}
  
  #ifdef GAME_ROGUE
  if (item.AMMO_SHELLS + item.AMMO_NAILS + item.AMMO_ROCKETS + item.AMMO_CELLS +
    item.ammo_lava_nails + item.ammo_multi_rockets + item.ammo_plasma == 0)
  #else
	if (item.AMMO_SHELLS + item.AMMO_NAILS + item.AMMO_ROCKETS + item.AMMO_CELLS == 0)
  #endif
  {
		sprint(self, "No ammo available!\n");
		remove(item);
		return;
	}
	 
	//item.owner = self;
  item.lastfragtime = time + 0.2; //Ry: Use delay instead of setting owner
	makevectors(self.v_angle);

	setorigin(item, self.origin + '0 0 16');
	item.velocity = aim(self, 1000);
	item.velocity = item.velocity * 500;
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_BOUNCE;

	setmodel (item, "progs/backpack.mdl");
	setsize(item, '-16 -16 0', '16 16 56');
	item.touch = BackpackTouch;
	item.nextthink = time + 120;	// remove after 2 minutes
	item.think = SUB_Remove;

	W_SetCurrentAmmo();
};

void() QueryEnabledOptions = //Prints which options are enabled (impulse 55)
{
  local float comma = FALSE;
  sprint(self,"Options Enabled: ");
  #ifdef GAME_HIPNOTIC
    if (footsteps)
    {
      sprint(self,"Footstep Sounds");
      comma = TRUE;
    }
    if (grem_itemstealallowed && (!deathmatch || (NumGremlins > 0)))
    {
      if (comma)
        sprint(self,", ");
      sprint(self,"Gremlin Item Steal");
      comma = TRUE;
    }
  #endif
  #ifndef GAME_ID1
    if (hip_rebalance && !deathmatch)
    {
      if (comma)
        sprint(self,", ");
      #ifdef GAME_HIPNOTIC
        sprint(self,"Hipnotic Rebalance");
      #elifdef GAME_ROGUE
        sprint(self,"Rogue Rebalance");
      #else
        sprint(self,"Mission Pack Rebalance");
      #endif
      comma = TRUE;
    }
  #endif
  if (wide_lightning)
  {
    if (comma)
      sprint(self,", ");
    sprint(self,"Wide Lightning");
    comma = TRUE;
  }
  if (wide_spikes && deathmatch)
  {
    if (comma)
      sprint(self,", ");
    #ifdef GAME_HIPNOTIC
      sprint(self,"Wide Nails/Lasers");
    #else
      sprint(self,"Wide Nails");
    #endif
    comma = TRUE;
  }
  #ifdef GAME_ROGUE
    if (altplasma)
    {
      if (comma)
        sprint(self,", ");
      sprint(self,"Alternate Plasma");
      comma = TRUE;
    }
  #endif
  if (exitwarp && deathmatch)
  {
    if (comma)
      sprint(self,", ");
    sprint(self,"Exit Warp");
    comma = TRUE;
  }
  if (!deathmatch)
  {
    if (copper_nightmare)
    {
      if (comma)
        sprint(self,", ");
      sprint(self,"Copper Difficulty Balance");
      comma = TRUE;
    }
    if (fastmonsters)
    {
      if (comma)
        sprint(self,", ");
      sprint(self,"Fast Monsters");
      comma = TRUE;
    }
  }
  if (!comma)
  {
    sprint(self,"None");
  }
  sprint(self,"\n");
}

void () DeleteWall = //Ry: Just a fun thing (impulse 207)
{
  if ( !CheatsAllowed() ) //Ry: New check for if cheats are allowed [07-23-2022]
    return;
  local vector org = self.origin+self.view_ofs;
  traceline (org, org + v_forward*600, TRUE, self);
  if (trace_fraction < 1)
  {
    if ( trace_ent.classname == "func_wall" )
    {
      sprint(self,"Removed wall\n");
      remove(trace_ent);
    }
    else if ( trace_ent.classname == "door" )
    {
      if (!(trace_ent.target)) //Only remove if it's not important for level scripting
      {
        sprint(self,"Removed door\n");
        remove(trace_ent);
      }
    }
  }
}

void () ProbeEntityData = //Ry: Debugging (impulse 208)
{
  local vector org = self.origin+self.view_ofs;
  traceline (org, org + v_forward*2048, FALSE, self);
  if ((trace_fraction < 1) && (trace_ent != world))
  {
    eprint(trace_ent);
    dprint("Current Time: ");
    dprint(ftos(time));
    dprint("\n");
  }
}

void() TestSpawnPoints = //Ry: Check if any spawn points are problematic (impulse 209)
{
  local entity spawnpoint;
  local vector testvect;
  local float current = 0;
  local float valid;
  local float contentval;
  
  for (spawnpoint = find(world, classname, "info_player_deathmatch") ; spawnpoint ; spawnpoint = find(spawnpoint, classname, "info_player_deathmatch") )
  {
    current = current + 1;
    valid = FALSE;
    testvect = spawnpoint.origin;
    testvect_x = testvect_x + VEC_HULL_MAX_x;
    testvect_y = testvect_y + VEC_HULL_MAX_y;
    testvect_z = testvect_z + VEC_HULL_MAX_z;
    contentval = pointcontents(testvect);
    if ((contentval == CONTENT_EMPTY) || (contentval == CONTENT_WATER))
    {
      testvect = spawnpoint.origin;
      testvect_x = testvect_x + VEC_HULL_MIN_x;
      testvect_y = testvect_y + VEC_HULL_MAX_y;
      testvect_z = testvect_z + VEC_HULL_MAX_z;
      contentval = pointcontents(testvect);
      if ((contentval == CONTENT_EMPTY) || (contentval == CONTENT_WATER))
      {
        testvect = spawnpoint.origin;
        testvect_x = testvect_x + VEC_HULL_MAX_x;
        testvect_y = testvect_y + VEC_HULL_MIN_y;
        testvect_z = testvect_z + VEC_HULL_MAX_z;
        contentval = pointcontents(testvect);
        if ((contentval == CONTENT_EMPTY) || (contentval == CONTENT_WATER))
        {
          testvect = spawnpoint.origin;
          testvect_x = testvect_x + VEC_HULL_MAX_x;
          testvect_y = testvect_y + VEC_HULL_MAX_y;
          testvect_z = testvect_z + VEC_HULL_MIN_z;
          contentval = pointcontents(testvect);
          if ((contentval == CONTENT_EMPTY) || (contentval == CONTENT_WATER))
          {
            testvect = spawnpoint.origin;
            testvect_x = testvect_x + VEC_HULL_MIN_x;
            testvect_y = testvect_y + VEC_HULL_MIN_y;
            testvect_z = testvect_z + VEC_HULL_MAX_z;
            contentval = pointcontents(testvect);
            if ((contentval == CONTENT_EMPTY) || (contentval == CONTENT_WATER))
            {
              testvect = spawnpoint.origin;
              testvect_x = testvect_x + VEC_HULL_MAX_x;
              testvect_y = testvect_y + VEC_HULL_MIN_y;
              testvect_z = testvect_z + VEC_HULL_MIN_z;
              contentval = pointcontents(testvect);
              if ((contentval == CONTENT_EMPTY) || (contentval == CONTENT_WATER))
              {
                testvect = spawnpoint.origin;
                testvect_x = testvect_x + VEC_HULL_MIN_x;
                testvect_y = testvect_y + VEC_HULL_MAX_y;
                testvect_z = testvect_z + VEC_HULL_MIN_z;
                contentval = pointcontents(testvect);
                if ((contentval == CONTENT_EMPTY) || (contentval == CONTENT_WATER))
                {
                  testvect = spawnpoint.origin;
                  testvect_x = testvect_x + VEC_HULL_MIN_x;
                  testvect_y = testvect_y + VEC_HULL_MIN_y;
                  testvect_z = testvect_z + VEC_HULL_MIN_z;
                  contentval = pointcontents(testvect);
                  if ((contentval == CONTENT_EMPTY) || (contentval == CONTENT_WATER))
                  {
                    valid = TRUE;
                  }
                }
              }
            }
          }
        }
      }
    }
    dprint("Spawn point ");
    dprint(ftos(current));
    if (valid)
      dprint(": OK\n");
    else
      dprint(": Obstructed\n");
  }
  
}


//Ry: This set of commands allows placing and manipulating models
void() DummyModel_CopyFacing = //impulse 236
{
  if (self.currentdummymodel)
  {
    self.currentdummymodel.angles = self.angles;
    self.currentdummymodel.angles_x = 0;
    FilteredCenterPrint(self,CPRINT_WORLD,"Model heading matched to player");
  }
}

void() DummyModel_CopyFacingAngled = //impulse 237
{
  if (self.currentdummymodel)
  {
    self.currentdummymodel.angles = self.angles;
    FilteredCenterPrint(self,CPRINT_WORLD,"Model angle matched to player");
  }
}

void() DummyModel_ResetFacing = //impulse 238
{
  if (self.currentdummymodel)
  {
    self.currentdummymodel.angles = '0 0 0';
    FilteredCenterPrint(self,CPRINT_WORLD,"Model angle reset");
  }
}

void(entity ent, vector orig, vector offset) SnapEntToGrid = //helper function
{
  if (self.placegridsnap > 0)
  {
    orig_x = rint(orig_x / self.placegridsnap) * self.placegridsnap;
    orig_y = rint(orig_y / self.placegridsnap) * self.placegridsnap;
    orig_z = rint(orig_z / 4) * 4;
  }
  ent.pickorigin = orig;
  setorigin(ent,orig+offset);
}

void() DummyModel_Place = //impulse 230
{
  local vector org = self.origin+self.view_ofs;
  traceline (org, org + v_forward*2000, TRUE, self);
  if (trace_fraction < 1)
  {
    if (self.currentdummymodel)
    {
      SnapEntToGrid( self.currentdummymodel , trace_endpos , self.currentdummymodel.view_ofs );
      FilteredCenterPrint(self,CPRINT_WORLD,"Model moved to crosshair");
    }
    else if ( CheatsAllowed() ) //Ry: Can only create new ones with cheats enabled
    {
      self.currentdummymodel = spawn();
      self.currentdummymodel.classname = "dummymodel";
      self.currentdummymodel.view_ofs_z -= VEC_HULL_MIN_z; //Ry: Model offset
      self.currentdummymodel.effectiveorigin_z -= VEC_HULL_MIN_z; //Ry: Up/Down offset
      SnapEntToGrid( self.currentdummymodel , trace_endpos , self.currentdummymodel.view_ofs );
      setmodel(self.currentdummymodel,self.model);
      setsize(self.currentdummymodel,VEC_HULL_MIN,VEC_HULL_MAX);
      DummyModel_CopyFacing();
      FilteredCenterPrint(self,CPRINT_WORLD,"Created new dummy model");
    }
  }
}

void(entity targ) DummyModel_Realign = //helper function
{
  local vector middle;
  self.currentdummymodel.view_ofs = '0 0 0';
  if (targ)
  {
    if ( self.currentdummymodel.modelindex < (modelindex_player - 1) )
    {
      middle = (targ.mins + targ.maxs)/2;
      self.currentdummymodel.view_ofs_x = 0 - middle_x;
      self.currentdummymodel.view_ofs_y = 0 - middle_y;
      self.currentdummymodel.view_ofs_z = 0 - targ.mins_z;
      self.currentdummymodel.angles = '0 0 0';
      self.currentdummymodel.effectiveorigin = '0 0 0';
    }
    else
    {
      self.currentdummymodel.view_ofs_z = 0 - targ.mins_z;
      self.currentdummymodel.effectiveorigin_z = self.currentdummymodel.view_ofs_z;
    }
  }
  else
  {
    self.currentdummymodel.view_ofs_z = 0 - self.currentdummymodel.mins_z;
    self.currentdummymodel.effectiveorigin_z = self.currentdummymodel.view_ofs_z;
  }
  SnapEntToGrid( self.currentdummymodel , self.currentdummymodel.pickorigin , self.currentdummymodel.view_ofs );
}

void() DummyModel_GrabModel = //impulse 231
{
  if (self.currentdummymodel)
  {
    local vector org = self.origin+self.view_ofs;
    traceline (org, org + v_forward*2000, FALSE, self);
    if (trace_fraction < 1 && trace_ent && trace_ent.model)
    {
      setmodel(self.currentdummymodel,trace_ent.model);
      setsize(self.currentdummymodel,trace_ent.mins,trace_ent.maxs);
      self.currentdummymodel.frame = 0;
      DummyModel_Realign(trace_ent);
      FilteredCenterPrint(self,CPRINT_WORLD,"Grabbed model: ",trace_ent.model);
    }
  }
}

void() DummyModel_GrabSizeForModelIndex = //helper function
{
  local entity head;
  head = nextent(world);
  while (head)
  {
    if (head.classname != "dummymodel" && head.modelindex == self.currentdummymodel.modelindex)
    {
      setsize(self.currentdummymodel,head.mins,head.maxs);
      DummyModel_Realign(head);
      return;
    }
    head = nextent(head);
  }
  setsize(self.currentdummymodel,VEC_HULL_MIN,VEC_HULL_MAX);
  DummyModel_Realign(world);
  return;
}

void() DummyModel_IncreaseModelIndex = //impulse 232
{
  if (self.currentdummymodel)
  {
    self.currentdummymodel.modelindex = self.currentdummymodel.modelindex + 1;
    self.currentdummymodel.frame = 0;
    if (self.currentdummymodel.view_ofs_x || self.currentdummymodel.view_ofs_y)
    {
      self.currentdummymodel.view_ofs = '0 0 0';
    }
    DummyModel_GrabSizeForModelIndex();
    #ifdef ENGINE_KEX
      FilteredCenterPrint(self,CPRINT_WORLD,"Model index increased to {}",ftos(self.currentdummymodel.modelindex));
    #else
      FilteredCenterPrint(self,CPRINT_WORLD,"Model index increased to ",ftos(self.currentdummymodel.modelindex));
    #endif
  }
}

void() DummyModel_DecreaseModelIndex = //impulse 233
{
  if (self.currentdummymodel)
  {
    self.currentdummymodel.modelindex = self.currentdummymodel.modelindex - 1;
    self.currentdummymodel.frame = 0;
    if (self.currentdummymodel.view_ofs_x || self.currentdummymodel.view_ofs_y)
    {
      self.currentdummymodel.view_ofs = '0 0 0';
    }
    DummyModel_GrabSizeForModelIndex();
    #ifdef ENGINE_KEX
      FilteredCenterPrint(self,CPRINT_WORLD,"Model index decreased to {}",ftos(self.currentdummymodel.modelindex));
    #else
      FilteredCenterPrint(self,CPRINT_WORLD,"Model index decreased to ",ftos(self.currentdummymodel.modelindex));
    #endif
  }
}

void() DummyModel_MoveUp = //impulse 234
{
  local float val;
  if (self.currentdummymodel)
  {
    val = 4;
    if (self.placegridsnap > 4)
      val = self.placegridsnap;
    self.currentdummymodel.effectiveorigin_z += val;
    self.currentdummymodel.view_ofs_z += val;
    self.currentdummymodel.origin_z += val;
    setorigin(self.currentdummymodel,self.currentdummymodel.origin);
    FilteredCenterPrint(self,CPRINT_WORLD,"Model moved up");
  }
}

void() DummyModel_MoveDown = //impulse 235
{
  local float val;
  if (self.currentdummymodel)
  {
    val = 4;
    if (self.placegridsnap > 4)
      val = self.placegridsnap;
    self.currentdummymodel.effectiveorigin_z -= val;
    self.currentdummymodel.view_ofs_z -= val;
    self.currentdummymodel.origin_z -= val;
    setorigin(self.currentdummymodel,self.currentdummymodel.origin);
    FilteredCenterPrint(self,CPRINT_WORLD,"Model moved down");
  }
}

void() DummyModel_IncreaseFrame = //impulse 239
{
  if (self.currentdummymodel)
  {
    self.currentdummymodel.frame = self.currentdummymodel.frame + 1;
    #ifdef ENGINE_KEX
      FilteredCenterPrint(self,CPRINT_WORLD,"Model frame increased to {}",ftos(self.currentdummymodel.frame));
    #else
      FilteredCenterPrint(self,CPRINT_WORLD,"Model frame increased to ",ftos(self.currentdummymodel.frame));
    #endif
  }
}

void() DummyModel_DecreaseFrame = //impulse 240
{
  if (self.currentdummymodel)
  {
    self.currentdummymodel.frame = self.currentdummymodel.frame - 1;
    if (self.currentdummymodel.frame < 0)
      self.currentdummymodel.frame = 0;
    #ifdef ENGINE_KEX
      FilteredCenterPrint(self,CPRINT_WORLD,"Model frame decreased to {}",ftos(self.currentdummymodel.frame));
    #else
      FilteredCenterPrint(self,CPRINT_WORLD,"Model frame decreased to ",ftos(self.currentdummymodel.frame));
    #endif
  }
}

void() DummyModel_Next = //impulse 241
{
  self.currentdummymodel = find(self.currentdummymodel,classname,"dummymodel");
  if (self.currentdummymodel)
    FilteredCenterPrint(self,CPRINT_WORLD,"Selected next model");
  else
    FilteredCenterPrint(self,CPRINT_WORLD,"No model selected");
}

void() DummyModel_Copy = //impulse 242
{
  local entity new;
  if (self.currentdummymodel)
  {
    local vector org = self.origin+self.view_ofs;
    traceline (org, org + v_forward*2000, TRUE, self);
    if (trace_fraction < 1)
    {
        new = spawn();
        new.classname = "dummymodel";

        setmodel(new,self.currentdummymodel.model);
        new.modelindex = self.currentdummymodel.modelindex;
        new.frame = self.currentdummymodel.frame;
        new.effectiveorigin = self.currentdummymodel.effectiveorigin;
        new.view_ofs = self.currentdummymodel.view_ofs;
        new.angles = self.currentdummymodel.angles;
        SnapEntToGrid( new , trace_endpos , new.view_ofs );
        setsize(new,self.currentdummymodel.mins,self.currentdummymodel.maxs);

        self.currentdummymodel = new;
        FilteredCenterPrint(self,CPRINT_WORLD,"Cloned model");
    }
  }
}

void() DummyModel_AdjustGridSnap = //impulse 243
{
  if (self.currentdummymodel)
  {
    if (self.placegridsnap < 4)
      self.placegridsnap = 4;
    else if (self.placegridsnap < 8)
      self.placegridsnap = 8;
    else if (self.placegridsnap < 16)
      self.placegridsnap = 16;
    else if (self.placegridsnap < 32)
      self.placegridsnap = 32;
    else if (self.placegridsnap < 64)
      self.placegridsnap = 64;
    else
    {
      self.placegridsnap = 0;
      FilteredCenterPrint(self,CPRINT_WORLD,"Grid snapping disabled");
      return;
    }
    #ifdef ENGINE_KEX
      FilteredCenterPrint(self,CPRINT_WORLD,"Grid snapping changed to {}",ftos(self.placegridsnap));
    #else
      FilteredCenterPrint(self,CPRINT_WORLD,"Grid snapping changed to ",ftos(self.placegridsnap));
    #endif
  }
}

void() DummyModel_Print = //impulse 244
{
  if (self.currentdummymodel)
  {
    eprint(self.currentdummymodel);
  }
}


// =================
//   Remaster Subs
// =================

void() tdeath_touch;
//void(entity ent) CopyToBodyQue;
void() respawn;
float() W_BestWeapon;

void(vector org) spawn_tfog_silent =
{
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_TELEPORT);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
};

// Yoder sept24 2021 horde merge
// a faster version of tdeath to minimize telefragging 
void(vector org, entity death_owner) spawn_tdeath_fast =
{
local entity	death;

	death = spawn();
	death.classname = "teledeath_fast"; //Ry: Unique classname
	death.movetype = MOVETYPE_NONE;
	death.solid = SOLID_TRIGGER;
	death.angles = '0 0 0';
	setsize (death, death_owner.mins - '1 1 1', death_owner.maxs + '1 1 1');
	setorigin (death, org);
	death.touch = tdeath_touch;
	death.nextthink = time + 0.02; //Ry: Increased slightly to hopefully not stop before having a chance to process all entities that could touch it [11-12-2022]
	death.think = SUB_Remove;
	death.owner = death_owner;
	
	force_retouch = 2;		// make sure even still objects get hit
};

// Yoder, Sept24, 2021
// when in horde (coop or solo), respawn all by restarting the server:
void() horde_respawn_all =
{
	// restart the entire server
	// put serverflags back to map's initial setting
	serverflags = startingserverflags;
	// request a reset to the parms
	reset_flag = TRUE;
	// "change" to the same level
	localcmd ("changelevel ");
	localcmd(mapname);
	localcmd("\n");
};

// Yoder Sept24 2021, Horde Merge
// Monster fade, used to fade out the model a few seconds after deathmatch
void() MonsterFade2 =
{
  #ifdef GAME_HIPNOTIC
    if (!self.gremstate) //Ry: Prevent fade if a Gremlin wants to gorge on this corpse
    {
      local entity ent;
      for (ent = find(world,classname,"monster_gremlin") ; ent ; ent = find(ent,classname,"monster_gremlin") )
      {
        if (ent.goalentity == self)
        {
          self.nextthink = time + 1;
          return;
        }
      }
      self.gremstate = GREM_GORGING; //Ry: Once the corpse starts to fade, Gremlins can no longer gorge on it
    }
  #endif
  #ifndef ENGINE_WINQUAKE
    if (self.alpha > 0)
    {
      self.alpha = self.alpha - 1 * frametime;
      self.nextthink = time; // think next frame
    }
    else
  #endif
		remove(self);
}
void() MonsterFade =
{
  #ifndef ENGINE_WINQUAKE
    if (!self.alpha)
      self.alpha = 1;
  #endif
  self.think = MonsterFade2;
  self.nextthink = time + 10 + random() * 5; // wait a bit before fading
};

//Remaster Advanced movement code that use the bots pathfinder if allowed and conditions are right.
void ai_pathtogoal( float dist ) {
  #ifdef ENGINE_KEX
    if (( self.allowPathFind == USEPATH_NO ) || (time < self.navcooldowntime)) //Ry: When the monster is blocked, the nav has a cooldown to see if the monster gets unstuck
    {
      movetogoal( dist ); // can't use pathfinding, so use normal Quake movement behavior.	
      return;
    }

    if ( visible(self.goalentity) ) //Ry: Use .goalentity instead of .enemy
    {
      #ifdef GAME_HIPNOTIC
        //Ry: Always use nav for charmed monsters following their charmer, or when targetting non-solid entities (like items or bodies)
        if ( (self.charmed && self.huntingcharmer && (self.huntingcharmer < 3) ) || (self.goalentity.solid < 2) ) {
          if ( walkpathtogoal( dist, self.goalentity.origin ) == PATH_IN_PROGRESS ) {
            return;
          }
        }
      #endif
      if ( self.combat_style == CS_RANGED )
      {
        // do the normal "shoot, walk, shoot" behavior...
        movetogoal( dist );
        return;
      }
      else if ( self.combat_style == CS_MELEE )
      {
        // path pretty close to the enemy, then let normal Quake movement take over.
        if ( enemy_range > RANGE_NEAR ) {
          if ( walkpathtogoal( dist, self.goalentity.origin ) == PATH_IN_PROGRESS ) {
            return;
          }
        }
      }
      else if ( self.combat_style >= CS_MIXED )
      {
        // most mixed combat AI have fairly short range attacks, so try to path within mid range.
        local float heightdiff = (self.goalentity.origin_z - self.origin_z);
        if ( self.combat_style == CS_MIXED ) //Ry: CS_MIXED will try to get to about the same height as the target
          heightdiff = fabs(heightdiff);     //Ry: CS_MIXED_ABOVE is fine with staying above the target
        heightdiff = (heightdiff * -1);
        if ( ( enemy_range > RANGE_MID ) || ( ( enemy_range > RANGE_NEAR ) && ( heightdiff < -50 ) ) ) {
          if ( walkpathtogoal( dist, self.goalentity.origin ) == PATH_IN_PROGRESS ) {
            return;
          }
        }
      }
    } else {
      // we can't see our enemy, let's see if we can path to them
      if ( walkpathtogoal( dist, self.goalentity.origin ) == PATH_IN_PROGRESS ) {
        return;
      }
    }
    self.navcooldowntime = time + 1;
  #endif
	movetogoal( dist ); // fall back to normal Quake movement behavior.
  return;
}

float(entity playerEnt, float old, float new) W_WantsToChangeWeapon =
{
  #ifdef ENGINE_KEX
    if (playerEnt.flags & FL_CLIENT) //Ry: Ensure is actually Client
    {
      float playerFlags = CheckPlayerEXFlags(playerEnt);
      if((playerFlags & PEF_CHANGENEVER) != 0)
      {
        return 0;
      }
      
      if(((playerFlags & PEF_CHANGEONLYNEW) != 0) && old == new)
      {
        return 0;
      }
    }
  #endif

	return 1;
};

float() W_CheckNoAmmo =
{
	if (self.currentammo > 0)
		return TRUE;

	if (self.weapon == IT_AXE)
		return TRUE;
  
  #ifdef GAME_ROGUE
    //ZOID--
    if (self.weapon == IT_GRAPPLE)
      return TRUE;
    //--ZOID
  #endif

  #ifdef GAME_HIPNOTIC
    //MED
    if (self.weapon == IT_MJOLNIR)
      return TRUE;
  #endif

  self.weapon = W_BestWeapon ();

	W_SetCurrentAmmo ();

// drop the weapon down
	return FALSE;
};

float PromptSupported() =
{
  if (!cvar("pr_checkextension"))
    return FALSE;

  return checkextension("EX_PROMPT");
}
