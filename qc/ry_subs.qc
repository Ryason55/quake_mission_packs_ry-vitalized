//Custom subroutines for existing entities by Ryason55

void() W_SetCurrentAmmo;
void() BackpackTouch;
void() ProximityGrenadeExplode;
void(entity item, float newalpha) UpdateItemVisibility;

//Custom function that only displays the centerprint if the current one has either expired, or is of equal or higher value
void(entity player, float type, string message1, string message2 = "", string message3 = "", string message4 = "", string message5 = "", string message6 = "") FilteredCenterPrint =
{
  if ( (!(player.flags & FL_ISBOT)) && (message1 != "") ) //Bots don't need centerprints
  {
    if ( (time >= (player.lastcenterprinttime + 5)) || (type >= player.lastcenterprinttype) )
    {
      if ((player.lastcenterprinttype == CPRINT_MOTD) && (player.lastcenterprinttype != type))
        player.motd_count = 99;
      player.lastcenterprinttime = time;
      player.lastcenterprinttype = type;
      if (message6 != "")
      {
        if (use_new_cprint)
          centerprint_new(player,message1,message2,message3,message4,message5,message6);
        else
          centerprint(player,message1,message2,message3,message4,message5,message6);
      }
      else if (message5 != "")
      {
        if (use_new_cprint)
          centerprint_new(player,message1,message2,message3,message4,message5);
        else
          centerprint(player,message1,message2,message3,message4,message5);
      }
      else if (message4 != "")
      {
        if (use_new_cprint)
          centerprint_new(player,message1,message2,message3,message4);
        else
          centerprint(player,message1,message2,message3,message4);
      }
      else if (message3 != "")
      {
        if (use_new_cprint)
          centerprint_new(player,message1,message2,message3);
        else
          centerprint(player,message1,message2,message3);
      }
      else if (message2 != "")
      {
        if (use_new_cprint)
          centerprint_new(player,message1,message2);
        else
          centerprint(player,message1,message2);
      }
      else
      {
        if (use_new_cprint)
          centerprint_new(player,message1);
        else
          centerprint(player,message1);
      }
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

//These call the new version of the centerprint function, which does translation but doesn't do string appending
void(entity player, float type, string message1, string message2 = "", string message3 = "", string message4 = "", string message5 = "", string message6 = "") FilteredCenterPrint_New =
{
  use_new_cprint = TRUE;
  FilteredCenterPrint(player, type, message1, message2, message3, message4, message5, message6);
  use_new_cprint = FALSE;
}

void(float type, string message1, string message2 = "", string message3 = "", string message4 = "", string message5 = "", string message6 = "") FilteredCenterPrint_New_All
{
  use_new_cprint = TRUE;
  FilteredCenterPrint_All(type, message1, message2, message3, message4, message5, message6);
  use_new_cprint = FALSE;
}


//Called when a player frags another player, incrementing frag count and showing a message on-screen
void(entity targ, entity attacker, entity inflictor, float add) ClientAwardFrag =
{
  if (deathmatch) //Ry: Only award PvP frags in Deathmatch
  {
    if (add > 0)
      attacker.frags = attacker.frags + add;
    else
      attacker.frags = attacker.frags + 1;
    
    if (!(attacker.flags & FL_ISBOT)) //Bots shouldn't get kill messages (unless I start doing sounds or announcements)
    {
      local string combomessage;
      combomessage = "";
      local string addedfrags;
      addedfrags = "";
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
          if (attacker.super_damage_finished) //Very important
            combomessage = "\nQUADra Kill!";
          else
            combomessage = "\nQuadra Kill!";
        else if (attacker.fragcombo == 5)
          if (attacker.invincible_finished) //Also important
            combomessage = "\nPENTA Kill!";
          else
            combomessage = "\nPenta Kill!";
        else if ((attacker.fragcombo > 5) && (attacker.fragcombo < 10))
          combomessage = "\nOverkill!";
        else if (attacker.fragcombo >= 10)
          combomessage = "\nAvatar of Death!";
      }
      
      if ((attacker != inflictor) && inflictor.netname)
        if (inflictor.flags & FL_CLIENT) //Ry: A different player got the kill
          FilteredCenterPrint(attacker,CPRINT_FRAG,"You assisted with fragging ",targ.netname,addedfrags,combomessage);
        else //Ry: A summoned monster got the kill
          FilteredCenterPrint(attacker,CPRINT_FRAG,"Your ",inflictor.netname," fragged ",targ.netname,addedfrags,combomessage);
      else
        FilteredCenterPrint(attacker,CPRINT_FRAG,"You fragged ",targ.netname,addedfrags,combomessage);
      attacker.lastfragtime = time;
      //localsound(attacker,"doors/runeuse.wav"); //Ry: Local frag sound, via new Remaster function... Though there isn't a way to adjust volume
    }
  }
}

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

void() SetSpawnAmmo = //Ry: Players will retain a small amount of the ammo they had when they respawn (Except shells which will be 25)
{
  parm4 = 25; //Shells
  
  if ( self.items & (IT_NAILGUN|IT_SUPER_NAILGUN) ) //Nails
    if (self.ammo_nails > 30)
      parm5 = 30;
    else
      parm5 = self.ammo_nails;
  else
    parm5 = 0;
  
  if ( self.items & (IT_ROCKET_LAUNCHER|IT_GRENADE_LAUNCHER|IT_PROXIMITY_GUN) )
    if (self.ammo_rockets > 5)
      parm6 = 5;
    else
      parm6 = self.ammo_rockets;
  else
    parm6 = 0;
  
  if ( self.items & (IT_LIGHTNING|IT_LASER_CANNON|IT_MJOLNIR) )
    if (self.ammo_cells > 15)
      parm7 = 15;
    else
      parm7 = self.ammo_cells;
  else
    parm7 = 0;
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
      FilteredCenterPrint_New (activator, CPRINT_WORLD, self.message);
    }
    else
    {
      if (self.items == IT_KEY1)
      {
        if (self.worldtype == WORLDTYPE_BASE)
        {
          FilteredCenterPrint_New (other, CPRINT_WORLD, "$qc_need_silver_keycard");
        }
        else if (self.worldtype == WORLDTYPE_METAL)
        {
          FilteredCenterPrint_New (other, CPRINT_WORLD, "$qc_need_silver_runekey");
        }
        else if (self.worldtype == WORLDTYPE_MEDIEVAL || self.worldtype == WORLDTYPE_HUB)
        {
          FilteredCenterPrint_New (other, CPRINT_WORLD, "$qc_need_silver_key");
        }
      }
      else if (self.items == IT_KEY2)
      {
        if (self.worldtype == WORLDTYPE_BASE)
        {
          FilteredCenterPrint_New (other, CPRINT_WORLD, "$qc_need_gold_keycard");
        }
        else if (self.worldtype == WORLDTYPE_METAL)
        {
          FilteredCenterPrint_New (other, CPRINT_WORLD, "$qc_need_gold_runekey");
        }
        else if (self.worldtype == WORLDTYPE_MEDIEVAL || self.worldtype == WORLDTYPE_HUB)
        {
          FilteredCenterPrint_New (other, CPRINT_WORLD, "$qc_need_gold_key");
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
      for (e = find(world, enttype, "item") ; e ; e = find(e, enttype, "item") )
        UpdateItemVisibility(e,e.alpha);
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
      for (e = find(world, enttype, "item") ; e ; e = find(e, enttype, "item") )
        UpdateItemVisibility(e,e.alpha);
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

float(float IsMonster, float IsGameplayElement) EntityValidForMode =
{
  if (initspawner)
    return TRUE;
  if (IsMonster && deathmatch)
  {
    remove(self);
    return FALSE;
  }
  if (!coop && (self.spawnflags & COOP_ONLY))
  {
    remove(self);
    return FALSE;
  }
  if (world.hybridhordemap)
  {
    if (cvar("horde") == 1)
    {
      if (self.hordeflags & HORDEFLAG_HORDEONLY)
        return TRUE;
      if ( (IsMonster || IsGameplayElement) )
      {
        if ( !(self.hordeflags & HORDEFLAG_HORDEENABLE) )
        {
          remove(self);
          return FALSE;
        }
      }
      else if ( self.hordeflags & HORDEFLAG_HORDEDISABLE )
      {
        remove(self);
        return FALSE;
      }
    }
    else if (self.hordeflags & HORDEFLAG_HORDEONLY)
    {
      remove(self);
      return FALSE;
    }
  }
  return TRUE;
}

//Ry: In horde.qc
vector(entity monster, vector org, string class) LoadMonster;

void(entity attacker, float damage) SUB_Null_Pain = {};


// ================
//   Gremlin Subs
// ================

void(float newstate) Gremlin_UpdateState;
void() GremlinAbandonItem;


// ========================
//   ID1 Replacement Subs
// ========================

void() hip_powerup_touch; //Ry: Reference this

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
    if (self.spawnclassname == "centroid" && hipnoticmap > 1) //Ry: Make Centroids drop ammo
      self.ammo_nails = 30;
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

  total = 0;
  count = 0;
  for (monster = find(world, classname, "monster_knight") ; monster ; monster = find(monster, classname, "monster_knight") )
  {
    total = total + 1;
    if (HiddenFromSpawnPoint(monster))
    {
      count = count + 1;
      monster.spawnclassname = "gremlin";
    }
  }
  dprint(ftos(count));
  dprint(" out of ");
  dprint(ftos(total));
  dprint(" Knights are valid for Gremlin replacement\n");
  if (count > 0)
  {
    total = ceil(total/6);
    if (total > count)
      total = count;
    count = total / count;
    valid = 0;
    total = 0;
    for (monster = find(world, spawnclassname, "gremlin") ; monster ; monster = find(monster, spawnclassname, "gremlin") )
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
    if (cvar("temp5") & RY_FL_PREFERID1WEPS) // Grenade Launcher > Proximity Gun
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
    if (cvar("temp5") & RY_FL_PREFERID1WEPS) // Thunderbolt > Laser Cannon > Mjolnir
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
		if( self.ammo_shells >= 20 ) {
			item.ammo_shells = 20;
			self.ammo_shells = self.ammo_shells - 20;
		}
		else
		{
			item.ammo_shells = self.ammo_shells;
			self.ammo_shells = 0;
		}
	}		
	
	// See if you have neither the Shotgun or Super Shotgun
	if ( !(self.items & (IT_SHOTGUN|IT_SUPER_SHOTGUN)) ) {
		if( self.ammo_shells >= 20 ) {
			item.ammo_shells = 20;
			self.ammo_shells = self.ammo_shells - 20;
		} else {
			item.ammo_shells = self.ammo_shells;
			self.ammo_shells = 0;
		}
	}		
	
	// See if we are using a nailgun
	if ((self.weapon == IT_NAILGUN) || (self.weapon == IT_SUPER_NAILGUN) ) {
		if( self.ammo_nails >= 20 ) {
			item.ammo_nails = 20;
			self.ammo_nails = self.ammo_nails - 20;
		} else {
			item.ammo_nails = self.ammo_nails;
			self.ammo_nails = 0;
		}
	}	

	// Check to see if we have neither nailgun
	if ( !( self.items & (IT_NAILGUN|IT_SUPER_NAILGUN)) ) {
		if (self.ammo_nails >= 20) {
			item.ammo_nails = 20;
			self.ammo_nails = self.ammo_nails - 20;
		} else {
			item.ammo_nails = self.ammo_nails;
			self.ammo_nails = 0;
		}
	}	
	
	// See if we are using a grenade or rocket launcher
	if ((self.weapon == IT_GRENADE_LAUNCHER) || (self.weapon == IT_ROCKET_LAUNCHER) || (self.weapon == IT_PROXIMITY_GUN)) {
		if( self.ammo_rockets >= 10 ) {
			item.ammo_rockets = 10;
			self.ammo_rockets = self.ammo_rockets - 10;
		} else {
			item.ammo_rockets = self.ammo_rockets;
			self.ammo_rockets = 0;
		}
	}

	// See if we have neither the Grenade or rocket launcher
	if ( !(self.items & (IT_GRENADE_LAUNCHER|IT_ROCKET_LAUNCHER|IT_PROXIMITY_GUN)) ) {
		if( self.ammo_rockets >= 10 ) {
			item.ammo_rockets = 10;
			self.ammo_rockets = self.ammo_rockets - 10;
		} else {
			item.ammo_rockets = self.ammo_rockets;
			self.ammo_rockets = 0;
		}
	}

	// See if we're using the lightning gun
	if ( (self.weapon == IT_LIGHTNING) || (self.weapon == IT_LASER_CANNON) || (self.weapon == IT_MJOLNIR) ) {	
		if( self.ammo_cells >= 20 ) {
			item.ammo_cells = 20;
			self.ammo_cells = self.ammo_cells - 20;
		} else {
			item.ammo_cells = self.ammo_cells;
			self.ammo_cells = 0;
		}
	}

	// see if we don't have the lightning gun
	if ( !(self.items & (IT_LIGHTNING|IT_LASER_CANNON|IT_MJOLNIR)) ) {	
		if( self.ammo_cells >= 20 ) {
			item.ammo_cells = 20;
			self.ammo_cells = self.ammo_cells - 20;
		} else {
			item.ammo_cells = self.ammo_cells;
			self.ammo_cells = 0;
		}
	}
	 
	if (item.ammo_shells + item.ammo_nails + item.ammo_rockets + item.ammo_cells == 0) {
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
  if (hip_rebalance && !deathmatch)
  {
    if (comma)
      sprint(self,", ");
    sprint(self,"Hipnotic Rebalance");
    comma = TRUE;
  }
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
    sprint(self,"Wide Nails/Lasers");
    comma = TRUE;
  }
  if (exitwarp && deathmatch)
  {
    if (comma)
      sprint(self,", ");
    sprint(self,"Exit Warp");
    comma = TRUE;
  }
  if (!comma)
  {
    sprint(self,"None");
  }
  sprint(self,"\n");
}

void() TogglePlayerProbe = //Toggles player name display (impulse 56)
{
  if (self.playerprobe == TRUE)
  {
    self.playerprobe = FALSE;
    sprint(self,"Player name display disabled\n");
  }
  else
  {
    self.playerprobe = TRUE;
    sprint(self,"Player name display enabled\n");
  }
}

void() EnablePlayerProbe = //Enable player name display (impulse 57)
{
  if (self.playerprobe == FALSE)
  {
    self.playerprobe = TRUE;
    sprint(self,"Player name display enabled\n");
  }
}

void() DisablePlayerProbe = //Disable player name display (impulse 58)
{
  if (self.playerprobe == TRUE)
  {
    self.playerprobe = FALSE;
    sprint(self,"Player name display disabled\n");
  }
}

void () DeleteWall = //Ry: Just a fun thing (impulse 207)
{
  if (cheats_allowed == FALSE) //Ry: Enabled with sv_cheats 1 only
  {
    sprint(self,"sv_cheats must be enabled!\n");
		return;
  }
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
	death.nextthink = time + 0.01;
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
	if (self.alpha > 0)
	{
		self.alpha = self.alpha - 1 * frametime;
		self.nextthink = time; // think next frame
	}
	else
		remove(self);
}
void() MonsterFade =
{
  if (!self.alpha)
    self.alpha = 1;
  self.think = MonsterFade2;
  self.nextthink = time + 10 + random() * 5; // wait a bit before fading
};

//Remaster Advanced movement code that use the bots pathfinder if allowed and conditions are right.
void ai_pathtogoal( float dist ) {
	if (( self.allowPathFind == FALSE ) || (time < self.navcooldowntime)) { //Ry: When the monster is blocked, the nav has a cooldown to see if the monster gets unstuck
		movetogoal( dist ); // can't use pathfinding, so use normal Quake movement behavior.	
		return;
	}

  if ( visible(self.goalentity) ) { //Ry: Use .goalentity instead of .enemy
    //Ry: Always use nav for charmed monsters following their charmer, or when targetting non-solid entities (like items or bodies)
    if ( (self.charmed && self.huntingcharmer && (self.huntingcharmer < 3) ) || (self.goalentity.solid < 2) ) {
      if ( walkpathtogoal( dist, self.goalentity.origin ) == PATH_IN_PROGRESS ) {
        return;
      }
    } else if ( self.combat_style == CS_RANGED ) {
			// do the normal "shoot, walk, shoot" behavior...
			movetogoal( dist );
			return;
		} else if ( self.combat_style == CS_MELEE ) {
			// path pretty close to the enemy, then let normal Quake movement take over.
			if ( enemy_range > RANGE_NEAR ) {
				if ( walkpathtogoal( dist, self.goalentity.origin ) == PATH_IN_PROGRESS ) {
					return;
				}
			}
		} else if ( self.combat_style >= CS_MIXED ) {
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

	movetogoal( dist ); // fall back to normal Quake movement behavior.
  self.navcooldowntime = time + 1;
  return;
}

float(entity playerEnt, float old, float new) W_WantsToChangeWeapon =
{
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

	return 1;
};

float() W_CheckNoAmmo =
{
	if (self.currentammo > 0)
		return TRUE;

	if (self.weapon == IT_AXE)
		return TRUE;

//MED
   if (self.weapon == IT_MJOLNIR)
      {
      return TRUE;
      }

   self.weapon = W_BestWeapon ();

	W_SetCurrentAmmo ();

// drop the weapon down
	return FALSE;
};