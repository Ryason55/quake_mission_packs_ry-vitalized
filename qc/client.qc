
// prototypes
void () W_WeaponFrame;
void() W_SetCurrentAmmo;
void(entity attacker, float damage) player_pain;
void() player_stand1;
void (vector org) spawn_tfog;
void (vector org, entity death_owner) spawn_tdeath;

void() PlayerDie; //Ry: Moved this up here

void(entity temp_player) horde_set_keys; // yoder sept24
void() GibMonster;
float() HordeGetPlayersAlive;



//======================
//  New Subs by Ryason
//======================

void() changelevel_warpsetup_think = //Ry: Set up Target so exit trigger(s) can lead to the start of the map
{
  local vector middle = self.origin + ((self.mins + self.maxs)/2);
  local float content = pointcontents(middle);
  if ((content == CONTENT_EMPTY) || (content == CONTENT_WATER))
  {
    local entity start = find(world, classname, "info_player_start");
    if (start != world)
    {
      if (start.targetname)
        self.target = start.targetname;
      else
      {
        self.target = "ry_warptostart";
        start.targetname = "ry_warptostart";
      }
      start.mangle = start.angles;
      exitwarp = TRUE;
    }
  }
}

//Ry: Checks if enemy players or monsters are visible from a given spawn point, based on Remaster's "PlayerVisibleToSpawnPoint"
float(entity point) ThreatVisibleToSpawnPoint =
{
	local vector spot1, spot2;
	local entity ent;

  ent = nextent(world);
  while (ent != world) //Ry: Check against monsters as well, and ignore team members (which include charmed monsters)
  {
    if ( (ent.flags & (FL_CLIENT|FL_MONSTER)) )
    {
      if ( (ent.health > 0) && (ent.deadflag == 0) && ((ent.team == 0) || (ent.team != self.team)) )
      {
        spot1 = point.origin + default_view_ofs;
        spot2 = ent.origin;
        if (ent.flags & FL_CLIENT)
          spot2 = spot2 + ent.view_ofs;
        traceline(spot1, spot2, 1, point);
        if ((trace_fraction >= 1))
        {
          return (TRUE);
        }
      }
    }
    ent = nextent(ent);
  }
  
	return (FALSE);
};

//Ry: Separated out from Remaster's SelectSpawnPoint so it can be used elsewhere
float(entity spot, float clearance, float checkplayersvisible) IsSpawnPointClear =
{
  local float clear = TRUE;
  local entity thing = findradius(spot.origin, MIN_DIST_FROM_DM_SPAWN_POINT);
  
  while (thing)
  {
    //Ry: Also check for Monsters and Proxy Bombs, and ignore Players flagged as Dead
    if ( (thing.classname == "proximity_grenade") || ( (thing.flags & (FL_CLIENT|FL_MONSTER)) && (thing.health > 0) && (thing.deadflag == 0) && (thing.solid > 1) && (thing != self) ) )
    {
      if ( BBoxIntersection(spot,thing,clearance) ) //Ry: Check against bounding box
      {
        clear = FALSE;
        break;
      }
    }
    thing = thing.chain;
  }
  if (deathmatch && clear && checkplayersvisible)
  {
    if (ThreatVisibleToSpawnPoint(spot))
    {
      return FALSE;
    }
  }
  return clear;
}

//===================
//  End of new subs
//===================




/*
=============================================================================

				LEVEL CHANGING / INTERMISSION

=============================================================================
*/

float	intermission_running;
float	intermission_exittime;

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission =
{
};

void() SetChangeParms =
{
  if (deathmatch) //Ry: Shouldn't carry over inventory in Deathmatch, in the case that map rotation is used
  {
    SetNewParms ();
    parm10 = self.mapsfinished+1;
    parm11 = self.playerprobe;
    return;
  }
  
	if (self.health <= 0)
	{
    SetNewParms ();
    parm1 = self.items - (self.items & (IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD ) );
    if (self.items & IT_SUPER_SHOTGUN)
      parm8 = IT_SUPER_SHOTGUN;
    parm4 = self.ammo_shells;
    parm5 = self.ammo_nails;
    parm6 = self.ammo_rockets;
    parm7 = self.ammo_cells;
    parm10 = self.mapsfinished+1;
    parm11 = self.playerprobe;
    return;
	}

//JIM
// remove items
	self.items = self.items - (self.items &
   (IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD ) );
//MED
   self.items2 = self.items2 - (self.items2 &
   (HIP_IT_WETSUIT | HIP_IT_EMPATHY_SHIELDS ) );
//MED
   self.gravity = 1.0;

// cap super health
	if (self.health > 100)
		self.health = 100;
	if (self.health < 50)
		self.health = 50;
	parm1 = self.items;
	parm2 = self.health;
	parm3 = self.armorvalue;
	if (self.ammo_shells < 25)
		parm4 = 25;
	else
		parm4 = self.ammo_shells;
	parm5 = self.ammo_nails;
	parm6 = self.ammo_rockets;
	parm7 = self.ammo_cells;
	parm8 = self.weapon;
	parm9 = self.armortype * 100;
  parm10 = self.mapsfinished+1;
  parm11 = self.playerprobe;
};

void() SetNewParms =
{
	parm1 = IT_SHOTGUN | IT_AXE;
	parm2 = 100;
	parm3 = 0;
	parm4 = 25;
	parm5 = 0;
	parm6 = 0;
	parm7 = 0;
	parm8 = 1;
	parm9 = 0;
};

void() DecodeLevelParms =
{
  if (!self.justrespawned) //Ry: Don't take away weapons on respawn
  {
    if (world.model == "maps/start.bsp")
      SetNewParms ();      // take away all stuff on starting new episode
    if (world.model == "maps/hip1m1.bsp")
      SetNewParms ();      // take away all stuff on starting new episode
    if (world.model == "maps/hip2m1.bsp")
      SetNewParms ();      // take away all stuff on starting new episode
    if (world.model == "maps/hip3m1.bsp")
      SetNewParms ();      // take away all stuff on starting new episode

    if (world.model == "maps/e1m1.bsp") //Ry: Remove weapons when starting ID1 episodes too
      SetNewParms ();
    if (world.model == "maps/e2m1.bsp")
      SetNewParms ();
    if (world.model == "maps/e3m1.bsp")
      SetNewParms ();
    if (world.model == "maps/e4m1.bsp")
      SetNewParms ();
    if (world.model == "maps/end.bsp")
      SetNewParms ();
  }

	self.items = parm1;
	self.health = parm2;
	self.armorvalue = parm3;
	self.ammo_shells = parm4;
	self.ammo_nails = parm5;
	self.ammo_rockets = parm6;
	self.ammo_cells = parm7;
	self.weapon = parm8;
	self.armortype = parm9 * 0.01;
  self.mapsfinished = parm10;
  if (!self.playerprobe)
    self.playerprobe = parm11;
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity() FindIntermission =
{
	local	entity spot;
	local	float cyc;

// look for info_intermission first
	spot = find (world, classname, "info_intermission");
	if (spot)
	{	// pick a random one
		cyc = random() * 4;
		while (cyc > 1)
		{
			spot = find (spot, classname, "info_intermission");
			if (!spot)
				spot = find (spot, classname, "info_intermission");
			cyc = cyc - 1;
		}
		return spot;
	}

// then look for the start position
	spot = find (world, classname, "info_player_start");
	if (spot)
		return spot;

// testinfo_player_start is only found in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (!spot)
		objerror ("FindIntermission: no spot");

	return spot;
};


string nextmap;
void() GotoNextMap =
{
	if (cvar("samelevel"))	// if samelevel is set, stay on same level
		changelevel (mapname);
	else
		changelevel (nextmap);
};


void() finale_transition = //Ry: Remaster functions for exiting to menu or Start map
{
  if ( !coop && (world.model == "maps/hipend.bsp") )
  {
    localcmd("menu_credits\n");
    localcmd("disconnect\n");
  }
  else
  {
    changelevel("start");
  }
};

void() finale_check =
{
  if (finaleFinished())
  {
    intermission_exittime = time + 5; //Ry: After the text finishes, there's a 5 second delay before player can input to exit
  }
  else
  {
    self.nextthink = (time + 0.1);
  }
};


void() ExitIntermission =
{
// skip any text in deathmatch
	if (deathmatch)
	{
		GotoNextMap ();
		return;
	}

	intermission_exittime = time + 1;
	intermission_running = intermission_running + 1;

//
// run some text if at the end of an episode
//
	if (intermission_running == 2)
	{
		if (world.model == "maps/e1m7.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);
			if (!cvar("registered"))
			{
				WriteByte (MSG_ALL, SVC_FINALE);
				WriteString (MSG_ALL, "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task in the other three\nhaunted lands of Quake. Or are you? If\nyou don't register Quake, you'll never\nknow what awaits you in the Realm of\nBlack Magic, the Netherworld, and the\nElder World!");
			}
			else
			{
				WriteByte (MSG_ALL, SVC_FINALE);
				WriteString (MSG_ALL, "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task. A Rune of magic\npower lies at the end of each haunted\nland of Quake. Go forth, seek the\ntotality of the four Runes!");
			}
			return;
		}
		else if (world.model == "maps/e2m6.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "The Rune of Black Magic throbs evilly in\nyour hand and whispers dark thoughts\ninto your brain. You learn the inmost\nlore of the Hell-Mother; Shub-Niggurath!\nYou now know that she is behind all the\nterrible plotting which has led to so\nmuch death and horror. But she is not\ninviolate! Armed with this Rune, you\nrealize that once all four Runes are\ncombined, the gate to Shub-Niggurath's\nPit will open, and you can face the\nWitch-Goddess herself in her frightful\notherworld cathedral.");
			return;
		}
		else if (world.model == "maps/e3m6.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "The charred viscera of diabolic horrors\nbubble viscously as you seize the Rune\nof Hell Magic. Its heat scorches your\nhand, and its terrible secrets blight\nyour mind. Gathering the shreds of your\ncourage, you shake the devil's shackles\nfrom your soul, and become ever more\nhard and determined to destroy the\nhideous creatures whose mere existence\nthreatens the souls and psyches of all\nthe population of Earth.");
			return;
		}
		else if (world.model == "maps/e4m7.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "Despite the awful might of the Elder\nWorld, you have achieved the Rune of\nElder Magic, capstone of all types of\narcane wisdom. Beyond good and evil,\nbeyond life and death, the Rune\npulsates, heavy with import. Patient and\npotent, the Elder Being Shub-Niggurath\nweaves her dire plans to clear off all\nlife from the Earth, and bring her own\nfoul offspring to our world! For all the\ndwellers in these nightmare dimensions\nare her descendants! Once all Runes of\nmagic power are united, the energy\nbehind them will blast open the Gateway\nto Shub-Niggurath, and you can travel\nthere to foil the Hell-Mother's plots\nin person.");
			return;
		}

//HIPNOTIC
      if (world.model == "maps/hip1m4.bsp")
      {
			WriteByte (MSG_ALL, SVC_CDTRACK);
         WriteByte (MSG_ALL, 6);
			WriteByte (MSG_ALL, 3);
			WriteByte (MSG_ALL, SVC_FINALE);
/*
         **************************************
         Deep within the bowels of the
         Research Facility, you discover the
         passage that the followers of Quake
         have used to enter our world.
         The bastards used some type of
         gigantic teleporter to overload
         one of our own slipgates!  As long as
         this portal exists, Earth will never
         be safe from Quake's cruel minions.

         If you can find the source of the
         portal's power, you can shut it
         down--possibly forever!  With only a
         moment's consideration for your own
         safety, you re-enter the dark domain,
         knowing Hell would be a better fate
         than experiencing the reign of Quake.
*/
         WriteString (MSG_ALL, "Deep within the bowels of the\nResearch Facility, you discover the\npassage that the followers of Quake\nhave used to enter our world.\nThe bastards used some type of\ngigantic teleporter to overload\none of our own slipgates!  As long as\nthis portal exists, Earth will never\nbe safe from Quake's cruel minions." );
         //WriteString (MSG_ALL, "If you can find the source of the\nportal's power, you can shut it\ndown--possibly forever!  With only a\nmoment's consideration for your own\nsafety, you re-enter the dark domain,\nknowing Hell would be a better fate\nthan experiencing the reign of Quake." );
         return;
		}
		else if (world.model == "maps/hip2m5.bsp")
		{
/*
         **************************************
         After destroying the power generator,
         you pass beyond the gate of Mortum's
         Keep.  A wave of nausea suddenly flows
         over you and you find yourself cast
         out into a liquid void.  You float
         lifelessly, yet aware, in a lavender
         sea of energy.

         After what seems like an eternity,
         you feel the presence of a diabolical
         intelligence.  You are held helpless
         for a moment as your mind is open to
         that of Armagon--Quake's General and
         master of this realm.  Recognizing
         you as the one who foiled his
         attempt to conquer Earth, a hellish
         howl fills your mind and blots out
         all consciousness.  When you awake,
         you find yourself on the shores of
         reality, but in a time and place
         unknown to you.
*/
         WriteByte (MSG_ALL, SVC_CDTRACK);
         WriteByte (MSG_ALL, 6);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
         WriteString (MSG_ALL, "After destroying the power generator,\nyou pass beyond the gate of Mortum's\nKeep.  A wave of nausea suddenly flows\nover you and you find yourself cast\nout into a liquid void.  You float\nlifelessly, yet aware, in a lavender\nsea of energy." );
         //WriteString (MSG_ALL, "After what seems like an eternity,\nyou feel the presence of a diabolical\nintelligence.  You are held helpless\nfor a moment as your mind is open to\nthat of Armagon--Quake's General and\nmaster of this realm.  Recognizing\nyou as the one who foiled his\nattempts to conquer Earth, a hellish\nhowl fills your mind and blots out\nall consciousness.  When you awake,\nyou find yourself on the shores of\nreality, but in a time and place\nunknown to you." );
         return;
		}
      else if (world.model == "maps/hipend.bsp")
      {
/*
         **************************************
         After the last echoes of Armagon's
         death yell fade away, you breathe a
         heavy sigh of relief.  With the loss
         of his magic, Armagon's fortress
         begins to collapse.  The rift he
         created to send his grisly troops
         through time slowly closes and seals
         itself forever.  In the chaos that
         ensues, a wall collapses, revealing
         one remaining time portal.  With your
         chances to escape rapidly growing
         slim, you race for the portal,
         mindless of your destination.  In a
         flash of light, you find yourself
         back at Command HQ, safe and sound.

         Congratulations!  You are victorious!
         The minions of Quake have once again
         fallen before your mighty hand.
         Is this the last you will see of
         Quake's hellions?

         Only time will tell...
*/
         WriteByte (MSG_ALL, SVC_CDTRACK);
         WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
         WriteString (MSG_ALL, "After the last echoes of Armagon's\ndeath yell fade away, you breathe a\nheavy sigh of relief.  With the loss\nof his magic, Armagon's fortress\nbegins to collapse.  The rift he\ncreated to send his grisly troops\nthrough time slowly closes and seals\nitself forever.  In the chaos that\nensues, a wall collapses, revealing\none remaining time portal.  With your\nchances to escape rapidly growing\nslim, you race for the portal,\nmindless of your destination.  In a\nflash of light, you find yourself\nback at Command HQ, safe and sound." );
         //WriteString (MSG_ALL, "Congratulations!  You are victorious!\nThe minions of Quake have once again\nfallen before your mighty hand.\nIs this the last you will see of\nQuake's hellions?\n\nOnly time will tell..." );
         //intermission_exittime = time + 10000000;  // never allow exit
      if (campaign) //Ry: Armagon clear achievements
      {
        WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
        WriteString(MSG_ALL, "ACH_COMPLETE_HIPEND");
        if ((skill == 3))
        {
          WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
          WriteString(MSG_ALL, "ACH_COMPLETE_HIPEND_NIGHTMARE");
        }
      }
			return;
		}
      GotoNextMap();
	}

	if (intermission_running == 3)
	{
		if (!cvar("registered"))
		{	// shareware episode has been completed, go to sell screen
			WriteByte (MSG_ALL, SVC_SELLSCREEN);
			return;
		}

    //Ry: Just assume the player has all 4 Runes (and don't display the message during *every* Armagon episode ending after clearing ID1)
		if (world.model == "maps/e4m7.bsp") //( (serverflags&15) == 15)
		{
			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "Now, you have all four Runes. You sense\ntremendous invisible forces moving to\nunseal ancient barriers. Shub-Niggurath\nhad hoped to use the Runes Herself to\nclear off the Earth, but now instead,\nyou will use them to enter her home and\nconfront her as an avatar of avenging\nEarth-life. If you defeat her, you will\nbe remembered forever as the savior of\nthe planet. If she conquers, it will be\nas if you had never been born.");
			return;
		}

//HIPNOTIC
    if (world.model == "maps/hip1m4.bsp")
    {
      WriteByte (MSG_ALL, SVC_FINALE);
      WriteString (MSG_ALL, "If you can find the source of the\nportal's power, you can shut it\ndown--possibly forever!  With only a\nmoment's consideration for your own\nsafety, you re-enter the dark domain,\nknowing Hell would be a better fate\nthan experiencing the reign of Quake." );
      return;
		}
		else if (world.model == "maps/hip2m5.bsp")
		{
      WriteByte (MSG_ALL, SVC_FINALE);
      WriteString (MSG_ALL, "After what seems like an eternity,\nyou feel the presence of a diabolical\nintelligence.  You are held helpless\nfor a moment as your mind is open to\nthat of Armagon--Quake's General and\nmaster of this realm.  Recognizing\nyou as the one who foiled his\nattempt to conquer Earth, a hellish\nhowl fills your mind and blots out\nall consciousness.  When you awake,\nyou find yourself on the shores of\nreality, but in a time and place\nunknown to you." );
      return;
		}
    else if (world.model == "maps/hipend.bsp")
    {
      WriteByte (MSG_ALL, SVC_FINALE);
      WriteString (MSG_ALL, "Congratulations!  You are victorious!\nThe minions of Quake have once again\nfallen before your mighty hand.\nIs this the last you will see of\nQuake's hellions?\n\nOnly time will tell..." );
      intermission_exittime = time + 10000000; //Ry: Block exiting until the outro text finishes
      local entity timer = spawn();
      timer.nextthink = (time + 1);
      timer.think = finale_check;
			return;
		}
  }
  
  //Ry: Now player can click to advance past the ending text scroll [06-28-2022]
  if ( (intermission_running > 3) && ((world.model == "maps/end.bsp") || (world.model == "maps/hipend.bsp")) )
  {
    finale_transition();
    return;
  }

	GotoNextMap();
};

/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void() IntermissionThink =
{
	if (time < intermission_exittime)
		return;

	if (!self.button0 && !self.button1 && !self.button2)
		return;

	ExitIntermission ();
};

void() execute_changelevel =
{
	local entity	pos;

	intermission_running = 1;

// enforce a wait time before allowing changelevel
	if (deathmatch)
		intermission_exittime = time + 5;
	else
		intermission_exittime = time + 2;

	WriteByte (MSG_ALL, SVC_CDTRACK);
   WriteByte (MSG_ALL, 9);
	WriteByte (MSG_ALL, 3);

	pos = FindIntermission ();
  
  if ( (!deathmatch) && (skill == 3) ) //Ry: Achievements for specific level challenges in Remaster ID1, now requiring all players to participate
  {
    if ( (ach_weaponfired == FALSE) && (world.model == "maps/e1m1.bsp") )
    {
      WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
      WriteString(MSG_ALL, "ACH_PACIFIST");
    }
    if ( (ach_damagetaken == FALSE) && (world.model == "maps/e4m6.bsp") )
    {
      WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
      WriteString(MSG_ALL, "ACH_PAINLESS_MAZE");
    }
  }

	other = find (world, classname, "player");
	while (other != world)
	{
		other.view_ofs = '0 0 0';
		other.angles = other.v_angle = pos.mangle;
		other.fixangle = TRUE;		// turn this way immediately
		other.nextthink = time + 0.5;
		other.takedamage = DAMAGE_NO;
		other.solid = SOLID_NOT;
		other.movetype = MOVETYPE_NONE;
		other.modelindex = 0;
		setorigin (other, pos.origin);
		other = find (other, classname, "player");
	}

	WriteByte (MSG_ALL, SVC_INTERMISSION);

  if (!deathmatch) //Ry: Don't trigger these in Deathmatch
  {

    if (campaign && (world.model == "maps/hip1m4.bsp")) //Ry: Remaster episode clear achievements
    {
      WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
      WriteString(MSG_ALL, "ACH_COMPLETE_HIP1M4");
    }
    else if (campaign && (world.model == "maps/hip2m5.bsp"))
    {
      WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
      WriteString(MSG_ALL, "ACH_COMPLETE_HIP2M5");
    }
    else if (world.model == "maps/e1m7.bsp") //Ry: Play ID1 maps in order since there's Hipnotic Start map
    {
      nextmap = "e2m1";
      if (campaign)
      {
        WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
        WriteString(MSG_ALL, "ACH_COMPLETE_E1M7");
      }
    }
    else if (world.model == "maps/e2m6.bsp")
    {
      nextmap = "e3m1";
      if (campaign)
      {
        WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
        WriteString(MSG_ALL, "ACH_COMPLETE_E2M6");
      }
    }
    else if (world.model == "maps/e3m6.bsp")
    {
      nextmap = "e4m1";
      {
				WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
				WriteString(MSG_ALL, "ACH_COMPLETE_E3M6");
      }
    }
    else if (world.model == "maps/e4m7.bsp")
    {
      nextmap = "end";
      {
        WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
        WriteString(MSG_ALL, "ACH_COMPLETE_E4M7");
      }
    }

    if ((world.model == "maps/hip1m2.bsp") && (nextmap == "hip1m5")) //Ry: Remaster secret level achievements
    {
      WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
      WriteString(MSG_ALL, "ACH_FIND_HIP1M5");
    }
    else if ((world.model == "maps/hip2m1.bsp") && (nextmap == "hip2m6"))
    {
      WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
      WriteString(MSG_ALL, "ACH_FIND_HIP2M6");
    }
    else if ((world.model == "maps/hip3m3.bsp") && (nextmap == "hipdm1"))
    {
      WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
      WriteString(MSG_ALL, "ACH_FIND_HIPDM1");
    }
    else if ((world.model == "maps/e1m4.bsp") && (nextmap == "e1m8")) //Ry: ID1
    {
      WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
      WriteString(MSG_ALL, "ACH_FIND_E1M8");
    }
    else if ((world.model == "maps/e2m3.bsp") && (nextmap == "e2m7"))
    {
      WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
      WriteString(MSG_ALL, "ACH_FIND_E2M7");
    }
    else if ((world.model == "maps/e3m4.bsp") && (nextmap == "e3m7"))
    {
      WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
      WriteString(MSG_ALL, "ACH_FIND_E3M7");
    }
    else if ((world.model == "maps/e4m5.bsp") && (nextmap == "e4m8"))
    {
      WriteByte(MSG_ALL, SVC_ACHIEVEMENT);
      WriteString(MSG_ALL, "ACH_FIND_E4M8");
    }
    
    // Yoder merge Horde sept24 2021
    if (horde_ent)
    {
      horde_ent.think = SUB_Null;
      horde_ent.nextthink = -1;
      
      other = find (world, category, CATEGORY_MONSTER);
      while (other != world)
      {
        //void(entity targ, entity inflictor, entity attacker, float damage)
        //T_Damage(other, world, world, 4000);
        other.think = GibMonster;
        other.nextthink = time + 0.2 + random() * 1.8;
        other = find(other, category, CATEGORY_MONSTER);
      }
    }

  }
  
};


void() teleport_touch; //Ry: Reference here

void() changelevel_touch =
{
  if (deathmatch && self.target) //Ry: If exit has been previously set up, act as a teleporter
  {
    teleport_touch();
    return;
  }

	if (other.classname != "player")
		return;

   if ((cvar("noexit") == 1) || ((cvar("noexit") == 2) && (mapname != "start")))
	{
		T_Damage (other, self, self, 50000);
		return;
	}

   if (coop || deathmatch)
	{
		bprint (other.netname);
		bprint (" exited the level\n");
	}

	nextmap = self.map;

	SUB_UseTargets ();

	if ( (self.spawnflags & 1) && (deathmatch == 0) )
	{	// NO_INTERMISSION
		GotoNextMap();
		return;
	}

	self.touch = SUB_Null;

// we can't move people right now, because touch functions are called
// in the middle of C movement code, so set a think time to do it
	self.think = execute_changelevel;
	self.nextthink = time + 0.1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
	if (!self.map)
		objerror ("changelevel trigger doesn't have map"); //Ry: Spelling correction

	InitTrigger ();
	self.touch = changelevel_touch;
  
  if (deathmatch && (cvar("temp5") & RY_FL_EXITWARP) ) //Ry: Set up exit warp in DM if desired (Exit warps to map start)
  {
    self.think = changelevel_warpsetup_think;
    self.nextthink = time + 0.3;
  }
};


/*
=============================================================================

				PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

void() set_suicide_frame;

// called by ClientKill and DeadThink
void() respawn =
{
  self.justrespawned = TRUE; //Ry: Set this for DecodeLevelParms and W_WeaponFrame
	if (coop)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// get the spawn parms as they were at level start
		//setspawnparms (self);
    
    //Ry: Keep weapons on respawn, but reset health/armor and retain only a small amount of the ammo you had
    SetNewParms ();
    parm1 = self.items - (self.items & (IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD ) );
    if (self.items & IT_SUPER_SHOTGUN)
      parm8 = IT_SUPER_SHOTGUN;
    SetSpawnAmmo();
    
		// respawn
		PutClientInServer ();
	}
	else if (deathmatch)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// set default spawn parms
		SetNewParms ();
		// respawn
		PutClientInServer ();
	}
	else
	{	// restart the entire server
		localcmd ("restart\n");
	}
};


/*
============
ClientKill

Player entered the suicide command
============
*/
void() ClientKill =
{
  if (self.view_ofs != '0 0 0') //Ry: Don't allow suiciding while in intermission camera
  {
    if (horde) // horde mode behavior
    {
      PlayerDie();
      self.health = 0;
    }
    else if ( coop || debugspawns || (time >= (self.lastspawntime + 10)) ) //Ry: Since suiciding now always drops a backpack in DM, make sure it can't be spammed (unless debugging)
    {
      ach_damagetaken = TRUE; //Ry: Count this as damage
      bprint (self.netname);
      bprint (" suicides\n");
      set_suicide_frame ();
      self.frags = self.frags - 2;	// extra penalty
      
      //Ry: Drop powerups and backpack
      DropPowerups();
      if (!debugspawns)
        DropBackpack(FALSE);
      
      respawn ();
    }
    else
      sprint(self,"Please wait a bit before suiciding\n");
  }
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/

entity(float forceSpawn) SelectSpawnPoint = //Ry: Retrofitted from Remaster's spawn point selection
{
	local entity spot;
	local float numspots;
	local float totalspots;
	local entity spots;
  local float earliesttime = time; //Ry: For Co-op spawns

	numspots = 0;
	totalspots = 0;
	spot = find(world, classname, "testplayerstart");
	if (spot)
	{
		return (spot);
	}
  
  if ( cvar( "horde" ) )
  { // run simpler logic for horde - just need a spot with noone on top of it...
  	spot = find( world, classname, "info_player_coop" );

   	while( spot )
    {
      numspots = numspots + 1;
   		spots = findradius( spot.origin, MIN_DIST_FROM_HORDE_SPAWN_POINT );
   		totalspots = FALSE;

   		while( spots )
      {
				if ( spots.classname == "player" && spots.health > 0 )
        {
					totalspots = TRUE;
          break;
        }

				spots = spots.chain;      
      }

      if ( !totalspots ) {
        return spot;
      }

      // Get the next spot in the chain
      spot = find( spot, classname, "info_player_coop" );
    }
  }
	else if (coop) //Ry: Co-op now spawns the player on the earliest available spawn point, checking each one to make sure it's clear
	{
    
    totalspots = 1;
    spot = find(world, classname, "info_player_start");
    spot.cnt = 1; //Ry: Record Spawn point number for debugging
    if (time >= spot.lastspawntime + 0.3)
    {
      if (IsSpawnPointClear(spot,4,FALSE))
      {
        earliesttime = spot.lastspawntime;
        spots = spot;
      }
    }
    
    spot = find(world, classname, "info_player_coop");
    while (spot)
    {
      totalspots = totalspots + 1;
      spot.cnt = totalspots; //Ry: Record Spawn point number for debugging
      if ( (time >= spot.lastspawntime + 0.3) && (spot.lastspawntime < earliesttime) )
      {
        if (IsSpawnPointClear(spot,4,FALSE))
        {
          earliesttime = spot.lastspawntime;
          spots = spot;
        }
      }
      spot = find(spot, classname, "info_player_coop");
    }
    
    if (spots)
      return spots;
    
    if (forceSpawn) //Ry: Return random spawn point if one is absolutely necessary
    {
      numspots = ceil(totalspots * random());
      if (numspots <= 1)
        return find(world, classname, "info_player_start");
      else
      {
        numspots = numspots - 1;
        spot = find(world, classname, "info_player_coop");
        while (spot)
        {
          if (numspots == 1)
            return spot;
          numspots = numspots - 1;
          spot = find(spot, classname, "info_player_coop");
        }
      }
    }
    return world;
	}
	else if (deathmatch)
	{
    spots = world;
    spot = find(world, classname, "info_player_deathmatch");
    while (spot)
    {
      totalspots = totalspots + 1;
      spot.cnt = totalspots; //Ry: Record Spawn point number for debugging
      if (time >= spot.lastspawntime + 1 ) //Ry: Check against the last time a player spawned on this point; Also allows a spawn point to be disabled for a time at the start of the map
      {
        if ( IsSpawnPointClear(spot,4,TRUE) ) //Ry: This part is separated out into its own function
        {
          spot.goalentity = spots;
          spots = spot;
          numspots = numspots + 1;
        }
      }
      spot = find(spot, classname, "info_player_deathmatch");
    }
    totalspots = totalspots - 1;
    if ((numspots == 0))
    {
      spot = find(world, classname, "info_player_deathmatch");
      while (spot)
      {
        if (time >= spot.lastspawntime + 1 )
        {
          if ( IsSpawnPointClear(spot,4,FALSE) )
          {
            spot.goalentity = spots;
            spots = spot;
            numspots = numspots + 1;
          }
        }
        spot = find(spot, classname, "info_player_deathmatch");
      }
    }
    if (!numspots)
    {
      if ((forceSpawn == FALSE))
      {
        return (world);
      }
      totalspots = rint((random() * totalspots));
      spot = find(world, classname, "info_player_deathmatch");
      while ((totalspots > 0))
      {
        totalspots = totalspots - 1;
        spot = find(spot, classname, "info_player_deathmatch");
      }
      return (spot);
    }
    numspots = numspots - 1;
    numspots = rint((random() * numspots));
    spot = spots;
    while ((numspots > 0))
    {
      spot = spot.goalentity;
      numspots = numspots - 1;
    }
    return (spot);
	}
	if (serverflags)
	{
		spot = find(world, classname, "info_player_start2");
		if (spot)
		{
			return (spot);
		}
	}
	spot = find(world, classname, "info_player_start");
	if (!spot)
	{
		error("PutClientInServer: no info_player_start on level");
	}
	return (spot);
};

/*
===========
PutClientInServer

called each time a player is spawned
============
*/

void() DecodeLevelParms;

void() PutClientInServer =
{
	local	entity spot;
  self.classname = "player";

	self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.show_hostile = 0;
	self.max_health = 100;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;   		// initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;
	//JIM
	self.wetsuit_finished = 0;
  //MED
  self.empathy_finished = 0;
  //MED
  self.items2 = 0;
  self.gravity = 1.0;
  self.gremstate = GREM_DEFAULT; //Ry: Reset gorging eligibility
  self.proxyimmunetime = time + 1; //Ry: Have Proxy Bombs ignore spawning players for a bit

  self.lastspawntime = time; //Ry: Record when the player spawns

  //Ry: Track the last player that damaged the player to track Ring Outs
  self.lastdamagetime = -100;
  self.lastdamager = world;

  //Ry: Track combo kills and kill streaks
  self.lastfragtime = -100;
  self.fragcombo = 0;
  //self.fragstreak = 0;
  
  //Ry: Track Megahealth rotting on the player themselves
  self.megarot_count = 0;
  self.megarot_time = 0;
  
  if (!(self.flags & FL_ISBOT))
  {
    if (self.lastcenterprinttype > CPRINT_NONE)
    {
      self.lastcenterprinttype = CPRINT_NONE;
      self.lastcenterprinttime = 0;
      centerprint(self,"");
    }
    self.lastprobedplayer = entity_null;
    self.lastprobetime = 0;
  }

  if (!self.playerindex) //Ry: Assign player index if not assigned, and increment for next one
    AssignPlayerIndex();
  if (!deathmatch)
    self.team = 1; //Ry: Put all players in Co-op on the same team
  else if (!teamplay)
    self.team = self.playerindex; //Ry: Assign unique team in DM for Horn of Conjuring use

	DecodeLevelParms ();
  
  if (self.firstspawn) //Ry: Give the player the weapons every other player started the map with in Co-op
  {
    if (coop)
    {
      local entity e;
      if ((self.weapon == IT_SHOTGUN) && (mapstartweapons & IT_SUPER_SHOTGUN) && (!(self.items & IT_SUPER_SHOTGUN)))
        self.weapon = IT_SUPER_SHOTGUN;
      self.items = self.items | mapstartweapons;
      mapstartweapons = self.items - (self.items & (IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD | IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS | IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3 ) );
      for (e = find(world, classname, "player") ; e ; e = find(e, classname, "player") ) //Ry: Ensure that player's items are shared with other players
        e.items = e.items | mapstartweapons;
      if ( !hipnoticmap || (hipnoticmap == 2) )
        hip_weaponconverttime = time + 1;
    }
    else if (!deathmatch) //Ry: Just record the weapons the player has in singleplayer, for if ID1 maps are played
    {
      mapstartweapons = self.items - (self.items & (IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD | IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS | IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3 ) );
      if ( !hipnoticmap )
        hip_weaponconverttime = time + 0.3;
    }
  }
  self.firstspawn = FALSE;

	W_SetCurrentAmmo ();

	self.attack_finished = time;
	self.th_pain = player_pain;
	self.th_die = PlayerDie;

	self.deadflag = DEAD_NO;
// paustime is set by teleporters to keep the player from moving a while
	self.pausetime = 0;

  if (self.desiredspawnpoint) //Ry: Spawn point was forced; For sure spawn on it
  {
    spot = self.desiredspawnpoint;
    self.desiredspawnpoint = entity_null;
  }
  else
    spot = SelectSpawnPoint(FALSE); //Ry: Moved this down here just so joining players are fully defined before the following
	if ((spot == world)) //Ry: Remaster deferred spawning, slightly modified
	{
    if (!(self.flags & FL_NOTARGET)) //Ry: Add NoTarget so monsters aren't alarmed
      self.flags = self.flags + FL_NOTARGET;
		self.takedamage = DAMAGE_NO;
		self.solid = SOLID_NOT;
		self.movetype = MOVETYPE_NONE;
		self.deadflag = DEAD_DEAD;
		setmodel(self, "");
    setsize (self, VEC_HULL_MIN, VEC_HULL_MAX ); //Ry: Set size so the telefrag trigger is also appropriately sized
		self.velocity = VEC_ORIGIN;
		if ((self.spawn_deferred == 0))
		{
      FilteredCenterPrint(self,CPRINT_WORLD,"Please wait..."); //Ry: Actually tell the player something instead of looking like a bug
      self.spawn_deferred = (time + 5);
		}
    else if (time >= self.spawn_deferred)
    {
      spot = SelectSpawnPoint(TRUE);    //Ry: The telefrag at the end doesn't resolve in time (player gets warped back to where they died due to the enemy player's collision)
      spawn_tdeath (spot.origin, self); // So store the spawn point and put the player on it as soon as it's clear
      self.spawn_deferred = time + 0.2;
      self.desiredspawnpoint = spot;
      if (debugspawns)
      {
        dprint("Player ");
        dprint(self.netname);
        dprint(" desires spawn point ");
        dprint(ftos(spot.cnt));
        dprint("\n");
      }
    }
    
    self.view_ofs = '0 0 1';
    spot = FindIntermission();
    self.v_angle = spot.mangle;
    self.angles = spot.mangle;
    self.fixangle = TRUE;
    self.origin = spot.origin;
    self.weaponmodel = "";
    self.weaponframe = 0;
    self.weapon = IT_AXE; //Ry: This originally used 0, but that crashed for me. Apparently Axe works fine visually.

		return;
	}
  
  if (debugspawns && spot.cnt) //Ry: Spawn point debugging
  {
    dprint("Placing player ");
    dprint(self.netname);
    dprint(" on spawn point ");
    dprint(ftos(spot.cnt));
    dprint("\n");
  }
  
  spot.lastspawntime = time;
	self.spawn_deferred = 0;

	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;		// turn this way immediately
  
  self.lastsafecheck = time; //Ry: Set spawn position as first safe vect, as it hopefully should be
  self.lastsafevect = self.origin;

  //JIM
  // Clear out velocity so you're not launched into the air
  // when you respawn.
  self.velocity = '0 0 0';

// oh, this is a hack!
  setmodel (self, "progs/playham.mdl");
  modelindex_hammer = self.modelindex;

  setmodel (self, "progs/eyes.mdl");
	modelindex_eyes = self.modelindex;

	setmodel (self, "progs/player.mdl");
	modelindex_player = self.modelindex;

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

	self.view_ofs = default_view_ofs;

	player_stand1 ();

	if (deathmatch || coop)
	{
		makevectors(self.angles);
		spawn_tfog (self.origin + v_forward*20);
	}

	spawn_tdeath (self.origin, self);
};


/*
=============================================================================

				QUAKED FUNCTIONS

=============================================================================
*/


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start =
{
  if (coop) //Ry: Set up for being detected by Proxy Bombs in Co-op
  {
    self.mins = VEC_HULL_MIN;
    self.maxs = VEC_HULL_MAX;
    self.solid = SOLID_TRIGGER;
  }
};


/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 =
{
};


/*
saved out by quaked in region mode
*/
void() testplayerstart =
{
};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void() info_player_deathmatch =
{
  if (deathmatch) //Ry: Set up for being detected by Proxy Bombs in Deathmatch
  {
    self.mins = VEC_HULL_MIN;
    self.maxs = VEC_HULL_MAX;
    self.solid = SOLID_TRIGGER;
  }
};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void() info_player_coop =
{
  if (coop) //Ry: Set up for being detected by Proxy Bombs in Co-op
  {
    self.mins = VEC_HULL_MIN;
    self.maxs = VEC_HULL_MAX;
    self.solid = SOLID_TRIGGER;
  }
};

/*
===============================================================================

RULES

===============================================================================
*/

/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void() NextLevel =
{
	local entity o;

//HIPNOTIC
//Commented out so that timelimit and fraglimit work on start map
   /*
	if (mapname == "start")
	{
		if (!cvar("registered"))
		{
			mapname = "e1m1";
		}
		else if (!(serverflags & 1))
		{
			mapname = "e1m1";
         serverflags = serverflags | 1;
		}
		else if (!(serverflags & 2))
		{
			mapname = "e2m1";
         serverflags = serverflags | 2;
		}
		else if (!(serverflags & 4))
		{
			mapname = "e3m1";
         serverflags = serverflags | 4;
		}
		else if (!(serverflags & 8))
		{
			mapname = "e4m1";
         serverflags = serverflags - 7;
		}

		o = spawn();
		o.map = mapname;
	}
	else
	{
*/
		// find a trigger changelevel
		o = find(world, classname, "trigger_changelevel");

		// go back to start if no trigger_changelevel
		if (!o)
		{
			mapname = "start";
			o = spawn();
			o.map = mapname;
		}
//   }

	nextmap = o.map;
	gameover = TRUE;

	if (o.nextthink < time)
	{
		o.think = execute_changelevel;
		o.nextthink = time + 0.1;
	}
};

/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
void() CheckRules =
{
	local	float		timelimit;
	local	float		fraglimit;

	if (gameover)	// someone else quit the game already
		return;

	timelimit = cvar("timelimit") * 60;
	fraglimit = cvar("fraglimit");

	if (timelimit && time >= timelimit)
	{
		NextLevel ();
		return;
	}

	if (fraglimit && self.frags >= fraglimit)
	{
		NextLevel ();
		return;
	}
};

//============================================================================

void() PlayerDeathThink =
{
	local float		forward;
  local entity		spot;

	if ((self.flags & FL_ONGROUND))
	{
		forward = vlen (self.velocity);
		forward = forward - 20;
		if (forward <= 0)
			self.velocity = '0 0 0';
		else
			self.velocity = forward * normalize(self.velocity);
	}

  if (self.desiredspawnpoint) //Ry: Waste no time if a spawn point is already desired (A telefrag trigger should already be on that spot)
  {
    if ( IsSpawnPointClear(self.desiredspawnpoint,1,FALSE) )
      respawn();
    else if (time >= self.spawn_deferred) //Ry: Keep trying the telefrag trigger if something went wrong
    {
      spawn_tdeath (self.desiredspawnpoint.origin, self);
      self.spawn_deferred = time + 0.2;
    }
    return;
  }
	if (self.spawn_deferred) //Ry: Remaster spawn stuff
	{
		spot = SelectSpawnPoint(FALSE);
		if (((spot != world) || (time >= self.spawn_deferred)))
		{
			respawn();
		}
		return;
	}

// wait for all buttons released
	if (self.deadflag == DEAD_DEAD)
	{
		if (self.button2 || self.button1 || self.button0)
			return;
		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}

// wait for any button down
	if (!self.button2 && !self.button1 && !self.button0)
		return;

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
  
	// Yoder Sept24, 2021
	if (horde_ent)
	{
		if ( !(self.flags & FL_ISBOT) && ((coop && HordeGetPlayersAlive() <= 0) || (!coop)) ) //Ry: Bots aren't allowed to advance
		{
			horde_respawn_all();
		}
		return;
	}
  
	respawn();
};


void() PlayerJump =
{
  local float upspeed, maxup;

	if (self.flags & FL_WATERJUMP)
		return;

	if (self.waterlevel >= 2)
	{
    //Ry: Swim up speed fix from Copper, by Lunaran
		// fix for +jump not swimming upward as fast as +moveup
		upspeed = cvar("cl_upspeed");
		if (self.waterlevel < 3)
    {
			upspeed *= 0.5; // match vanilla swim values at the surface so we don't launch out of the water any higher
      if (self.wetsuit_finished > time) //Ry: Account for wetsuit
        upspeed *= 1.25;
    }
		else
    {
			upspeed *= 0.7;	// match moveup from SV_WaterMove
      if (self.wetsuit_finished > time) //Ry: Account for wetsuit
        upspeed *= 1.5;
    }

		if (self.watertype == CONTENT_LAVA)
			upspeed *= 0.5;	// originally 50
		else if (self.watertype == CONTENT_SLIME)
			upspeed *= 0.8;	// originally 80

		// scale upspeed to match WaterMove since playerjump gets called after it
		self.velocity_z = upspeed - 0.8 * self.waterlevel * frametime * upspeed;

    maxup = cvar("sv_maxspeed"); //Ry: Cap speed
    if (self.velocity_z > maxup)
      self.velocity_z = maxup;


// play swiming sound
    if (self.swim_flag < time)
    {
      self.swim_flag = time + 1;
      if (random() < 0.5)
        sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
      else
        sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
    }

		return;
	}

	if (!(self.flags & FL_ONGROUND))
		return;

	if ( !(self.flags & FL_JUMPRELEASED) )
		return;		// don't pogo stick

	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);

	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk

	self.button2 = 0;
// player jumping sound
	sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
	self.velocity_z = self.velocity_z + 270;
};


/*
===========
WaterMove

============
*/
.float	dmgtime;

void() WaterMove =
{
	if (self.movetype == MOVETYPE_NOCLIP)
		return;
	if (self.health < 0)
		return;

	if (self.waterlevel != 3)
	{
		if (self.air_finished < time)
			sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
		else if (self.air_finished < time + 9)
			sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
		self.air_finished = time + 12;
		self.dmg = 2;
	}
	else if (self.air_finished < time)
	{	// drown!
		if (self.pain_finished < time)
		{
			self.dmg = self.dmg + 2;
			if (self.dmg > 15)
				self.dmg = 10;
      self.deathtype = "drowning"; //Ry: Track this better
      T_Damage (self, world, world, self.dmg);
			self.pain_finished = time + 1;
		}
	}

	if (!self.waterlevel)
	{
		if (self.flags & FL_INWATER)
		{
			// play leave water sound
			sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
			self.flags = self.flags - FL_INWATER;
		}
		return;
	}

	if (self.watertype == CONTENT_LAVA)
	{	// do damage
		if (self.dmgtime < time)
		{
			if (self.radsuit_finished > time)
				self.dmgtime = time + 1;
			else
				self.dmgtime = time + 0.2;

      self.deathtype = "lava"; //Ry: Track this better
      T_Damage (self, world, world, 10*self.waterlevel);
		}
	}
	else if (self.watertype == CONTENT_SLIME)
	{	// do damage
		if (self.dmgtime < time && self.radsuit_finished < time)
		{
			self.dmgtime = time + 1;
      self.deathtype = "slime"; //Ry: Track this better
      T_Damage (self, world, world, 4*self.waterlevel);
		}
	}

	if ( !(self.flags & FL_INWATER) )
	{

// player enter water sound

		if (self.watertype == CONTENT_LAVA)
			sound (self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_SLIME)
			sound (self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);

		self.flags = self.flags + FL_INWATER;
		self.dmgtime = 0;
	}

	if (! (self.flags & FL_WATERJUMP) )
		self.velocity = self.velocity - 0.8*self.waterlevel*frametime*self.velocity;
};

void() CheckWaterJump =
{
	local vector start, end;

// check for a jump-out-of-water
	makevectors (self.angles);
	start = self.origin;
	start_z = start_z + 8;
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	traceline (start, end, TRUE, self);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, self);
		if (trace_fraction == 1)
		{	// open at eye level
			self.flags = self.flags | FL_WATERJUMP;
			self.velocity_z = 225;
			self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
			self.teleport_time = time + 2;	// safety net
			return;
		}
	}
};

/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
//MED 01/17/97
void(float num_bubbles) DeathBubbles;
void() PlayerPreThink =
{
	if (intermission_running)
	{
    if ( (self.health <= 0) && (self.deadflag > 0) ) //Ry: If player is dead at intermission, set their ammo to spawn ammo so backpacks apply correctly
    {
      self.deadflag = DEAD_NO;
      SetSpawnAmmo();
      self.ammo_shells = parm4;
      self.ammo_nails = parm5;
      self.ammo_rockets = parm6;
      self.ammo_cells = parm7;
    }
    earthquake_prethink();
    IntermissionThink ();   // otherwise a button could be missed between
		return;					// the think tics
	}

	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale
  
  self.deathtype = ""; //Ry: Ensure these are reset between frames
  self.axhitme = 0;

//JIM
   // Kill player on Edge of Oblivion
   if ( ( self.origin_z < -1300 ) && (world.model == "maps/hipdm1.bsp") &&
      ( self.health > 0 ) )
      {
      self.deathtype = "falling";

      if (self.invincible_finished >= time)
         {
         self.invincible_finished = 0;
         self.items = self.items - (self.items & IT_INVULNERABILITY);
         self.invincible_time = 0;
			self.invincible_finished = 0;
         self.effects = self.effects - (self.effects & EF_PENTALIGHT);
         }
      T_Damage( self, self, world, self.health + 1000 );
      }

	//JIM
//   if (!deathmatch)
//      {
      earthquake_prethink();
//      }

	makevectors (self.v_angle);
  
  if (self.health <= 0 && !self.deadflag) //Ry: If player is put to 0 or lower health via unexpected means, allow them to respawn
  {
    self.nextthink = -1;
    self.deadflag = DEAD_DEAD;
  }
  
  if (!self.deadflag && self.justrespawned && !self.button0) //Ry: Allow player to shoot again after releasing fire after respawning
    self.justrespawned = FALSE;
  
  if (!(self.flags & FL_ISBOT) && (coop || deathmatch))
  { //Ry: Remove Frag and Probe messages after an amount of time
    if ( ((self.lastcenterprinttype == CPRINT_FRAG) && (time >= self.lastcenterprinttime + 3)) || ((self.lastcenterprinttype == CPRINT_NAME) && (time >= self.lastcenterprinttime + 1)) )
    {
      self.lastcenterprinttype = CPRINT_NONE;
      self.lastcenterprinttime = 0;
      centerprint(self,"");
    }
    if ( self.playerprobe && ((self.lastcenterprinttype <= CPRINT_NAME) || (time >= self.lastcenterprinttime + 5)) ) //Ry: Player Probe
    {
      local vector org = self.origin+self.view_ofs;
      traceline (org, org + v_forward*2048, FALSE, self);
      if (trace_fraction < 1)
      {
        if ( (trace_ent != self) && ( (trace_ent.classname == "player") || ((deathmatch || (coop && trace_ent.charmed)) && (trace_ent.flags & FL_MONSTER)) ) && (!trace_ent.invisible_finished || coop) ) //Ry: Valid target, and target is not invisible (DM)
        {
          if ( (self.lastprobedplayer != trace_ent) || (time >= self.lastprobetime + 0.5) )
          {
            local string targname = trace_ent.netname;
            if (!targname || (targname == ""))
            {
              if (trace_ent.flags & FL_MONSTER)
                targname = "Monster";
              else
                targname = "Player";
            }
            if ( coop || (self.team > 0 && self.team == trace_ent.team) )
              FilteredCenterPrint(self,CPRINT_NAME,"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n[Ally]\n",targname);
            else
              FilteredCenterPrint(self,CPRINT_NAME,"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n[Enemy]\n",targname);
            self.lastprobetime = time;
          }
          self.lastprobedplayer = trace_ent;
        }
        else if (self.lastprobedplayer) //Ry: Just looked away from this player
        {
          self.lastcenterprinttime = time;
          self.lastprobedplayer = entity_null;
          self.lastprobetime = 0;
        }
      }
    }
  }

  CheckMOTD(); //Ry: Copied from Rogue, since a MOTD would be nice
	CheckRules ();
	WaterMove ();

	//JIM
	//WETSUIT
	if (self.wetsuit_finished > time)
  {
    if (self.waterlevel==2)
    {
      self.velocity = self.velocity * 1.25;
    }
    if (self.waterlevel==3)
    {
      self.velocity = self.velocity * 1.5;
    }
    if (self.waterlevel >= 2)
    {
      // play scuba sound
      if (self.swim_flag < time)
      {
        self.swim_flag = time + 7;
        sound (self, CHAN_BODY, "misc/wetsuit.wav", 1, ATTN_NORM);
      }
      //MED 01/17/97
      else
      {
        if (fabs(self.swim_flag - time - 6)<0.04)
        {
          DeathBubbles(1);
        }
        else if (fabs(self.swim_flag - time - 5.5)<0.04)
        {
          DeathBubbles(1);
        }
        else if (fabs(self.swim_flag - time - 5)<0.04)
        {
          DeathBubbles(1);
        }
      }
    }
  }

	if (self.waterlevel == 2)
		CheckWaterJump ();

	if (self.deadflag >= DEAD_DEAD)
	{
		PlayerDeathThink ();
		return;
	}

	if (self.deadflag == DEAD_DYING)
		return;	// dying, so do nothing

	if (self.button2)
	{
		PlayerJump ();
	}
	else
		self.flags = self.flags | FL_JUMPRELEASED;

// teleporters can force a non-moving pause time
	if (time < self.pausetime)
		self.velocity = '0 0 0';

   if(time > self.attack_finished && self.currentammo == 0 && self.weapon != IT_AXE && self.weapon != IT_MJOLNIR)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
	}
};

/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups =
{
	if (self.health <= 0)
		return;

// invisibility
	if (self.invisible_finished)
	{
// sound and screen flash when items starts to run out
		if (self.invisible_sound < time)
		{
			sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
			self.invisible_sound = time + ((random() * 3) + 1);
		}


		if (self.invisible_finished < time + 3)
		{
			if (self.invisible_time == 1)
			{
				sprint (self, "Ring of Shadows magic is fading\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				self.invisible_time = time + 1;
			}

			if (self.invisible_time < time)
			{
				self.invisible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invisible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVISIBILITY;
			self.invisible_finished = 0;
			self.invisible_time = 0;
		}

	// use the eyes
		self.frame = 0;
		self.modelindex = modelindex_eyes;
	}
//MED 12/04/96 added mjolnir stuff
   else if (self.weapon == IT_MJOLNIR)
      self.modelindex = modelindex_hammer;   // don't use eyes
   else
		self.modelindex = modelindex_player;	// don't use eyes

// invincibility
	if (self.invincible_finished)
	{
// sound and screen flash when items starts to run out
		if (self.invincible_finished < time + 3)
		{
			if (self.invincible_time == 1)
			{
				sprint (self, "Protection is almost burned out\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				self.invincible_time = time + 1;
			}

			if (self.invincible_time < time)
			{
				self.invincible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invincible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVULNERABILITY;
			self.invincible_time = 0;
			self.invincible_finished = 0;
		}
		if (self.invincible_finished > time)
			self.effects = self.effects | EF_PENTALIGHT;
		else
			self.effects = self.effects - (self.effects & EF_PENTALIGHT);
	}

// super damage
	if (self.super_damage_finished)
	{

// sound and screen flash when items starts to run out

		if (self.super_damage_finished < time + 3)
		{
			if (self.super_time == 1)
			{
				sprint (self, "Quad Damage is wearing off\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				self.super_time = time + 1;
			}

			if (self.super_time < time)
			{
				self.super_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.super_damage_finished < time)
		{	// just stopped
			self.items = self.items - IT_QUAD;
			self.super_damage_finished = 0;
			self.super_time = 0;
		}
		if (self.super_damage_finished > time)
			self.effects = self.effects | EF_QUADLIGHT;
		else
			self.effects = self.effects - (self.effects & EF_QUADLIGHT);
	}

// suit
	if (self.radsuit_finished)
	{
		self.air_finished = time + 12;		// don't drown

// sound and screen flash when items starts to run out
		if (self.radsuit_finished < time + 3)
		{
			if (self.rad_time == 1)
			{
				sprint (self, "Air supply in Biosuit expiring\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				self.rad_time = time + 1;
			}

			if (self.rad_time < time)
			{
				self.rad_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.radsuit_finished < time)
		{	// just stopped
			self.items = self.items - IT_SUIT;
			self.rad_time = 0;
			self.radsuit_finished = 0;
		}
	}

//JIM
// wetsuit
	if (self.wetsuit_finished)
	{
	self.air_finished = time + 12;		// don't drown

	// sound and screen flash when items starts to run out
	if (self.wetsuit_finished < time + 3)
		{
			if (self.wetsuit_time == 1)
			{
				sprint (self, "Air supply in Wetsuit is running out\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				self.wetsuit_time = time + 1;
			}

			if (self.wetsuit_time < time)
			{
				self.wetsuit_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.wetsuit_finished < time)
		{	// just stopped
//MED
         self.items2 = self.items2 - HIP_IT_WETSUIT;
			self.wetsuit_time = 0;
			self.wetsuit_finished = 0;
		}
	}

//MED
// empathy shields
   if (self.empathy_finished)
	{
      // sound and screen flash when items starts to run out
      if (self.empathy_finished < time + 3)
		{
         if (self.empathy_time == 1)
			{
            sprint (self, "Empathy Shields are running out\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
            self.empathy_time = time + 1;
			}

         if (self.empathy_time < time)
			{
            self.empathy_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

      if (self.empathy_finished < time)
		{	// just stopped
//MED
         self.items2 = self.items2 - HIP_IT_EMPATHY_SHIELDS;
         self.empathy_time = 0;
         self.empathy_finished = 0;
		}
//MED
      if (self.empathy_finished > time)
			self.effects = self.effects | EF_DIMLIGHT;
		else
			self.effects = self.effects - (self.effects & EF_DIMLIGHT);
   }
};


/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() PlayerPostThink =
{
	if (self.view_ofs == '0 0 0')
      {
      earthquake_postthink();
      return;     // intermission or finale
      }

	//JIM
	//WETSUIT
	if (self.wetsuit_finished > time)
		{
		if (self.waterlevel==2)
			{
			self.velocity = self.velocity * 0.8;
			}
		if (self.waterlevel==3)
			{
			self.velocity = self.velocity * 0.66;
			}
      }

	//JIM
//   if (!deathmatch)
//      {
      earthquake_postthink();
//      }

	if (self.deadflag)
		return;

// do weapon stuff

	W_WeaponFrame ();

// check to see if player landed and play landing sound
	if ((self.jump_flag < -300) && (self.flags & FL_ONGROUND) && (self.health > 0))
	{
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
		else if (self.jump_flag < -650)
		{
      self.deathtype = "falling"; //Ry: Moved this up here, before damage is called
			T_Damage (self, world, world, 5);
      if (self.health > 0) //Ry: Actually check if player lived
        sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
		}
		else
			sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);

		self.jump_flag = 0;
	}

	if (!(self.flags & FL_ONGROUND))
		self.jump_flag = self.velocity_z;
  
  //Ry: In Co-op, record a safe place to put a backpack if need be
  if (coop)
    RecordSafeVect();

  //Ry: Handle Megahealth rotting here [06-30-2022]
  if (self.megarot_count && time >= self.megarot_time)
  {
    if (self.health > self.max_health)
    {
      self.health -= self.megarot_count;
      self.megarot_time = time + 1;
      if (self.health <= self.max_health)
      {
        self.health = self.max_health;
        self.megarot_count = 0;
        self.megarot_time = 0;
      }
    }
    else
    {
      self.megarot_count = 0;
      self.megarot_time = 0;
    }
  }
  
	// AY 11 Nov 2021, check killspree end
	if ((self.killspree > 0) && (time > self.killtime))
	{
		dprint("killspree ended.\n");
		
		//score = (self.killspree + (self.killspree - 1) -1) * 5; // previously was "attacker.killspree - 1"
		if (self.killspree > 1)
		{
			local float score = ceil((self.killspree * self.killspree)/2);
			sprint(self, "$qc_horde_streak_ended", ftos(score));
			self.frags += score;
		}
		
		self.killspree = 0; // reset killspree
	}

	CheckPowerups ();
};


/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() ClientConnect =
{
  if (self.flags & FL_ISBOT) //Ry: Bots now have a different connect message
  {
    bprint ("Bot ");
    bprint (self.netname);
    bprint (" added to the game\n");
  }
  else
  {
    bprint (self.netname);
    bprint (" entered the game\n");
  }
  
  SetMOTD(); //Ry: Show the MOTD when the player joins

  self.firstspawn = TRUE; //Ry: For giving weapons in Co-op

// a client connecting during an intermission can cause problems
	if (intermission_running)
		ExitIntermission ();
};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
	if (gameover)
		return;
	// if the level end trigger has been activated, just return
	// since they aren't *really* leaving

  if (coop && self.health <= 0) //Ry: A backpack should already be dropped if they're dead, so reduce ammo to spawn ammo before dropping another
  {
    if (self.ammo_shells > 25)
      self.ammo_shells = 25;
    if (self.ammo_nails > 30)
      self.ammo_nails = 30;
    if (self.ammo_rockets > 5)
      self.ammo_rockets = 5;
    if (self.ammo_cells > 15)
      self.ammo_cells = 15;
  }
  DropPowerups(); //Ry: Drop powerups and backpack when disconnecting
  DropBackpack(TRUE);
  
  self.mapsfinished = 0; //Ry: Reset map count on this player slot
  self.playerprobe = FALSE; //Ry: Reset player name display
  
  self.spawn_deferred = 0; //Ry: Reset these just in case
  self.desiredspawnpoint = entity_null;
  
  if (self.playerindex) //Ry: Free up the index the player was using
  {
    playerindexinuse = playerindexinuse - (playerindexinuse & self.playerindex);
    dprint("Freed up index ");
    dprint(ftos(self.playerindex));
    dprint("\n");
    
    if (coop)
    {
      local entity e;
      
      //Ry: Remove this ID from all items
      for (e = find(world, enttype, "item") ; e ; e = find(e, enttype, "item") )
      {
        if (e.pickers & self.playerindex)
          e.pickers = e.pickers - (e.pickers & self.playerindex);
        UpdateItemVisibility(e,e.alpha);
      }
    }
    else if (deathmatch) //Ry: Unset team, just in case
      self.team = 0;
    
    self.playerindex = 0; //Ry: Unset to ensure the player entity doesn't retain the ID when its reused for the next client
    
  }
	
	// yoder oct13, horde fix for dc-ing players
	if(cvar("horde"))
	{
		dprint("horde mode, player disconnect\n");
		self.health = 0;
	}

	// let everyone else know
  if (self.flags & FL_ISBOT) //Ry: Bots now have a different disconnect message
  {
    bprint ("Bot ");
    bprint (self.netname);
    bprint (" removed with ");
  }
  else
  {
    bprint (self.netname);
    bprint (" left the game with ");
  }
	bprint (ftos(self.frags));
	bprint (" frags\n");
	sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);
	set_suicide_frame ();
};

/*
===========
ClientObituary

called when a player dies
============
*/
void(entity targ, entity attacker) ClientObituary =
{
	local	float rnum;
	local	string deathstring, deathstring2;
	rnum = random();

   if (targ.classname == "player")
	{
		if (attacker.classname == "teledeath")
		{
			bprint (targ.netname);
			bprint (" was telefragged by ");
			bprint (attacker.owner.netname);
			bprint ("\n");

      ClientAwardFrag(targ,attacker.owner,attacker.owner,1); //Ry: PvP frags are now added in this function
			return;
		}

		if (attacker.classname == "teledeath2")
		{
			bprint ("Satan's power deflects ");
			bprint (targ.netname);
			bprint ("'s telefrag\n");

			targ.frags = targ.frags - 1;
			return;
		}

		if (attacker.classname == "player")
		{
			if (targ == attacker)
			{
				// killed self
				attacker.frags = attacker.frags - 1;
				bprint (targ.netname);
        
        if (targ.dmg_inflictor.classname == "trap_gods_wrath") //Ry: Death message for trap_gods_wrath wasn't showing up before, since the player who initiated it does the damage
        {
          bprint (" ");
          bprint (targ.dmg_inflictor.deathtype);
          bprint ("\n");
          return;
        }

        if (targ.dmg_inflictor.classname == "grenade" || targ.dmg_inflictor.classname == "proximity_grenade") //Ry: Actually check for what projectile killed the player
        {  
          bprint (" tries to put the pin back in\n");
          return;
        }
        if (targ.dmg_inflictor.classname == "missile")
        {  
          if (rnum > 0.4 )
            bprint (" becomes bored with life\n");
          else
            bprint (" checks if their weapon is loaded\n");
          return;
        }
        if (targ.dmg_inflictor.classname == "hiplaser") //Ry: Armagon exclusive
        {  
          if (rnum > 0.4 )
            bprint (" radiates themself\n");
          else
            bprint (" tried to dance with lasers\n");
          return;
        }

				if ( targ.deathtype == "discharge" ) //Ry: Now uses deathtype instead
				{
          if (self.watertype == CONTENT_SLIME) //Ry: Proper message per liquid type
            bprint (" discharges into the slime\n");
          else if (self.watertype == CONTENT_LAVA)
            bprint (" discharges into the lava\n");
          else
            bprint (" discharges into the water\n");
					return;
				}
//JIM
        else if (rnum > 0.4 )
					bprint (" becomes bored with life\n");
				else
					bprint (" checks if their weapon is loaded\n");
        
        //if (targ.dmg_inflictor.classname) //Ry: For debugging
        //{  
        //  bprint (targ.dmg_inflictor.classname);
        //  bprint ("\n");
        //}
        
				return;
			}
         else if ( (teamplay == 2) && (targ.team > 0)&&(targ.team == attacker.team) )
			{
				if (rnum < 0.25)
					deathstring = " mows down a teammate\n";
				else if (rnum < 0.50)
					deathstring = " checks their glasses\n";
				else if (rnum < 0.75)
					deathstring = " gets a frag for the other team\n";
				else
					deathstring = " loses another friend\n";
				bprint (attacker.netname);
				bprint (deathstring);
				attacker.frags = attacker.frags - 1;
				return;
			}
         else
			{
        ClientAwardFrag(targ,attacker,attacker,1); //Ry: PvP frags are now added in this function
//MED 01/19/97
            if (empathyused == 1)
               {
               bprint (targ.netname);
               if (random()<0.5)
                  bprint (" shares ");
               else
                  bprint (" feels ");
               bprint (attacker.netname);
               bprint ("'s pain\n");
               return;
               }

//MED 11/18/96
            if (targ.dmg_inflictor.classname == "proximity_grenade")
               {
               bprint (targ.netname);
               if (random()<0.5)
                  bprint (" got too friendly with ");
               else
                  bprint (" did the rhumba with ");
               bprint (attacker.netname);
               bprint ("'s bomb\n");
               return;
               }
               
        deathstring = " was killed by "; //Ry: Fallback text just in case
        deathstring2 = "\n";
        
        if (targ.dmg_inflictor.classname == "grenade") //Ry: Actually check for what projectile killed the player (Proxy bomb handled just above)
        {  
          deathstring = " eats ";
          deathstring2 = "'s pineapple\n";
          if (targ.health < -40)
          {
            deathstring = " was gibbed by ";
            deathstring2 = "'s grenade\n";
          }
        }
        else if (targ.dmg_inflictor.classname == "missile")
        {  
          if (attacker.super_damage_finished && (targ.health < -40)) //Ry: Remaster Quad Rocket messages (minus 1)
          {
            if (rnum< 0.5)
              deathstring = " was brutalized by ";
            else
              deathstring = " was smeared by ";
            deathstring2 = "'s quad rocket\n";
          }
          else
          {
            if (targ.health < -40)
              deathstring = " was gibbed by ";
            else
              deathstring = " rides ";
            deathstring2 = "'s rocket\n";
          }
        }
        else if (targ.dmg_inflictor.classname == "spike")
        {
          deathstring = " was nailed by ";
          deathstring2 = "\n";
        }
        else if (targ.dmg_inflictor.classname == "super_spike") //Ry: Super Nails are normally also "spike", but I changed the class name used for them for this
        {
          deathstring = " was punctured by ";
          deathstring2 = "\n";
        }
        else if (targ.dmg_inflictor.classname == "hiplaser") //Ry: Armagon exclusive
        {  
          if (rnum<0.5)
            deathstring = " was toasted by ";
          else
            deathstring = " was radiated by ";
          deathstring2 = "'s laser\n";
        }
        else if (targ.dmg_inflictor.classname == "trap_gods_wrath") //HIP2M2
        {  
          deathstring = " suffers for ";
          deathstring2 = "'s sins\n";
        }
        else //Ry: Weapons you absolutely must have out to deal damage with
        {
          //if (targ.dmg_inflictor.classname) //Ry: For Debugging
          //{
          //  bprint(targ.dmg_inflictor.classname);
          //  bprint("\n");
          //}
          rnum = attacker.lastfiredweapon; //Ry: Use what weapon was last fired, since bots can change weapons faster than the recoil
          if (rnum == IT_AXE)
          {
            deathstring = " was ax-murdered by ";
            deathstring2 = "\n";
          }
          if (rnum == IT_SHOTGUN)
          {
            deathstring = " chewed on ";
            deathstring2 = "'s boomstick\n";
          }
          if (rnum == IT_SUPER_SHOTGUN)
          {
            deathstring = " ate 2 loads of ";
            deathstring2 = "'s buckshot\n";
          }
          if (rnum == IT_LIGHTNING)
          {
            deathstring = " accepts ";
            if (attacker.deathtype == "discharge") //Ry: Use deathtype for this
            {
              deathstring2 = "'s discharge\n";
              if (attacker.invincible_finished || attacker.wetsuit_finished) //Ry: Discharge achievement stuff
              {
                msg_entity = attacker;
                WriteByte(MSG_ONE, SVC_ACHIEVEMENT);
                WriteString(MSG_ONE, "ACH_SURVIVE_DISCHARGE");
              }
            }
            else
              deathstring2 = "'s shaft\n";
          }
  //MED
          if (rnum == IT_MJOLNIR)
          {
            if (attacker.deathtype == "discharge") //Ry: Message for discharging with Mjolnir (also use deathtype)
            {
              deathstring = " accepts ";
              deathstring2 = "'s discharge\n";
              if (attacker.invincible_finished || attacker.wetsuit_finished) //Ry: Discharge achievement stuff
              {
                msg_entity = attacker;
                WriteByte(MSG_ONE, SVC_ACHIEVEMENT);
                WriteString(MSG_ONE, "ACH_SURVIVE_DISCHARGE");
              }
            }
            else
            {
              deathstring = " was slammed by ";
              deathstring2 = "'s hammer\n";
            }
          }
          
        }
      
            bprint (targ.netname);
				bprint (deathstring);
				bprint (attacker.netname);
				bprint (deathstring2);
			}
			return;
		}
    
    else if (time <= (targ.lastdamagetime + 3) && (targ.lastdamager.classname == "player" || targ.lastdamager.charmer) ) // Ry: Killed by non-player in Deathmatch while having been recently damaged by a player
    {
      if (targ.lastdamager.charmer) //Ry: Killed by a charmed monster
      {
        if (targ == targ.lastdamager.charmer) //Ry: Killed by own monster
        {
          targ.frags = targ.frags - 1;
          bprint (targ.netname);
          bprint (" was killed by their own monster\n");
          return;
        }
        else
          ClientAwardFrag(targ,targ.lastdamager.charmer,targ.lastdamager,1); //Ry: PvP frags are now added in this function
        
        deathstring = " was killed by ";
        deathstring2 = "'s monster\n";
				if (attacker.classname == "monster_army")
        {
          deathstring = " was shot by ";
          deathstring2 = "'s Grunt\n";
        }
				else if (attacker.classname == "monster_demon1")
        {
          deathstring = " was eviscerated by ";
          deathstring2 = "'s Fiend\n";
        }
				else if (attacker.classname == "monster_dog")
        {
          deathstring = " was mauled by ";
          deathstring2 = "'s Rottweiler\n";
        }
				else if (attacker.classname == "monster_dragon")
        {
          deathstring = " was fried by ";
          deathstring2 = "'s Dragon\n";
        }
				else if (attacker.classname == "monster_enforcer")
        {
          deathstring = " was blasted by ";
          deathstring2 = "'s Enforcer\n";
        }
				else if (attacker.classname == "monster_fish")
        {
          deathstring = " was fed to ";
          deathstring2 = "'s Rotfish\n";
        }
				else if (attacker.classname == "monster_hell_knight")
        {
          deathstring = " was slain by ";
          deathstring2 = "'s Death Knight\n";
        }
				else if (attacker.classname == "monster_knight")
        {
          deathstring = " was slashed by ";
          deathstring2 = "'s Knight\n";
        }
				else if (attacker.classname == "monster_ogre")
        {
          deathstring = " was destroyed by ";
          deathstring2 = "'s Ogre\n";
        }
				else if (attacker.classname == "monster_oldone")
        {
          deathstring = " became one with ";
          deathstring2 = "'s Shub-Niggurath\n"; //Ry: Take home your very own Shub today
        }
				else if (attacker.classname == "monster_shalrath")
        {
          deathstring = " was exploded by ";
          deathstring2 = "'s Vore\n";
        }
				else if (attacker.classname == "monster_shambler")
        {
          deathstring = " was smashed by ";
          deathstring2 = "'s Shambler\n";
        }
				else if (attacker.classname == "monster_tarbaby")
        {
          deathstring = " was slimed by ";
          deathstring2 = "'s Spawn\n";
        }
				else if (attacker.classname == "monster_vomit")
        {
          deathstring = " was vomited on by ";
          deathstring2 = "'s Vomitus\n";
        }
				else if (attacker.classname == "monster_wizard")
        {
          deathstring = " was scragged by ";
          deathstring2 = "'s Scrag\n";
        }
				else if (attacker.classname == "monster_zombie")
        {
          deathstring = " joins ";
          deathstring2 = "'s Zombie\n";
        }
        else if (attacker.classname == "monster_gremlin")
        {
          deathstring = " was outsmarted by ";
          deathstring2 = "'s Gremlin\n";
        }
        else if (attacker.classname == "monster_scourge")
        {
          deathstring = " was stung by ";
          deathstring2 = "'s Centroid\n";
        }
        else if (attacker.classname == "monster_armagon")
        {
          deathstring = " was outgunned by ";
          deathstring2 = "'s Armagon\n";
        }
        else if ((attacker.classname == "monster_spikemine") || (attacker.classname == "trap_spike_mine"))
        {
          deathstring = " was blasted by ";
          deathstring2 = "'s Spike Mine\n";
        }
        bprint (targ.netname);
        bprint (deathstring);
        bprint (targ.lastdamager.charmer.netname);
        bprint (deathstring2);
        return;
      }
      else
      {
        ClientAwardFrag(targ,targ.lastdamager,targ.lastdamager,1); //Ry: PvP frags are now added in this function
      
        bprint (targ.netname);
        //Ry: Player died to another player in liquid; Now uses deathtype as well
        if (self.deathtype == "drowning") //Drowning in Water
        {
          if (random() < 0.5)
            bprint (" was held under by ");
          else
            bprint (" was suffocated by ");
          bprint (targ.lastdamager.netname);
          bprint ("\n");
          return;
        }
        else if (self.deathtype == "slime") //Slime
        {
          if (random() < 0.5)
            bprint (" was cast into the slime by ");
          else
            bprint (" got an acid wash from ");
          bprint (targ.lastdamager.netname);
          bprint ("\n");
          return;
        }
        else if (self.deathtype == "lava") //Lava
        {
          if (random() < 0.5)
            bprint (" was sent plummeting into lava by ");
          else
            bprint (" got a lava bath from ");
          bprint (targ.lastdamager.netname);
          bprint ("\n");
          return;
        }
        
        if (attacker.solid == SOLID_BSP && attacker != world)
        {
          bprint (" was crushed by ");
          bprint (targ.lastdamager.netname);
          bprint ("\n");
          return;
        }
        if (targ.deathtype == "falling")
        {
          bprint (" was shoved off by ");
          bprint (targ.lastdamager.netname);
          bprint ("\n");
          return;
        }
        if (attacker.classname == "trigger_changelevel")
        {
          bprint (" has departed on behalf of ");
          bprint (targ.lastdamager.netname);
          bprint ("\n");
          return;
        }
        
        bprint (" died while fighting ");
        bprint (targ.lastdamager.netname);
        bprint ("\n");
        return;
      }
    }
      
		else
		{
			targ.frags = targ.frags - 1;		// killed self

			bprint (targ.netname);

//JIM
          if ( attacker.deathtype ) //Ry: The Remaster translations have problems (like missing newlines), and I wasn't using the translation strings anyways
          {
            if (attacker.deathtype == "$qc_spin_blade") //HIP3M4
              bprint (" was mangled by a Spin Blade");
            else if (attacker.deathtype == "$qc_boulder") //HIP1M3
              bprint (", you've been Jones'ed!");
            else if (attacker.deathtype == "$qc_falling_rocks") //HIP1M3
              bprint ("'s rumblin' tumblin' death");
            else if (attacker.deathtype == "$qc_fan_blade") //HIP1M2
              bprint (" was chopped to bits");
            else if (attacker.deathtype == "$qc_turbine") //HIP1M5
              bprint (" was munched by the turbines");
            else //Original logic
            {
              bprint ( " " );
              bprint ( attacker.deathtype );
            }
            bprint( "\n" );
            return;
          }

			if (self.deathtype == "drowning") //Ry: Now uses deathtype for liquid deaths
			{
				if (random() < 0.5)
					bprint (" sleeps with the fishes\n");
				else
					bprint (" sucks it down\n");
				return;
			}
			else if (self.deathtype == "slime")
			{
				if (random() < 0.5)
					bprint (" gulped a load of slime\n");
				else
					bprint (" can't exist on slime alone\n");
				return;
			}
			else if (self.deathtype == "lava")
			{
				if (targ.health < -15)
				{
					bprint (" burst into flames\n");
					return;
				}
				if (random() < 0.5)
					bprint (" turned into hot slag\n");
				else
					bprint (" visits the Volcano God\n");
				return;
			}

			if (attacker.flags & FL_MONSTER)
			{
				if (attacker.classname == "monster_army")
					bprint (" was shot by a Grunt\n");
				if (attacker.classname == "monster_demon1")
					bprint (" was eviscerated by a Fiend\n");
				if (attacker.classname == "monster_dog")
					bprint (" was mauled by a Rottweiler\n");
				if (attacker.classname == "monster_dragon")
					bprint (" was fried by a Dragon\n");
				if (attacker.classname == "monster_enforcer")
					bprint (" was blasted by an Enforcer\n");
				if (attacker.classname == "monster_fish")
					bprint (" was fed to the Rotfish\n");
				if (attacker.classname == "monster_hell_knight")
					bprint (" was slain by a Death Knight\n");
				if (attacker.classname == "monster_knight")
					bprint (" was slashed by a Knight\n");
				if (attacker.classname == "monster_ogre")
					bprint (" was destroyed by an Ogre\n");
				if (attacker.classname == "monster_oldone")
					bprint (" became one with Shub-Niggurath\n");
				if (attacker.classname == "monster_shalrath")
					bprint (" was exploded by a Vore\n");
				if (attacker.classname == "monster_shambler")
					bprint (" was smashed by a Shambler\n");
				if (attacker.classname == "monster_tarbaby")
					bprint (" was slimed by a Spawn\n");
				if (attacker.classname == "monster_vomit")
					bprint (" was vomited on by a Vomitus\n");
				if (attacker.classname == "monster_wizard")
					bprint (" was scragged by a Scrag\n");
				if (attacker.classname == "monster_zombie")
					bprint (" joins the Zombies\n");
//MED
            if (attacker.classname == "monster_gremlin")
               bprint (" was outsmarted by a Gremlin\n");
//MED
            if (attacker.classname == "monster_scourge")
               bprint (" was stung by a Centroid\n");
//MED
            if (attacker.classname == "monster_armagon")
               bprint (" was outgunned by Armagon\n");

				return;
			}
			if (attacker.classname == "explo_box")
			{
				bprint (" blew up\n");
				return;
			}
			if (attacker.solid == SOLID_BSP && attacker != world)
			{
				bprint (" was squished\n");
				return;
			}
			if (targ.deathtype == "falling")
			{
				bprint (" fell to their death\n");
				return;
			}
			if (attacker.classname == "trap_shooter" || attacker.classname == "trap_spikeshooter")
			{
				bprint (" was spiked\n");
				return;
			}
			if (attacker.classname == "fireball")
			{
				bprint (" ate a lavaball\n");
				return;
			}
			if (attacker.classname == "trigger_changelevel")
			{
				bprint (" tried to leave\n");
				return;
			}

         bprint (" died\n");
		}
	}
};
