
void() InitBodyQue;
#ifdef GAME_HIPNOTIC
  //JIM
  void() InitBulletHoles;
#endif


void() main =
{
	dprint ("main function\n");

// these are just commands the the prog compiler to copy these files

	precache_file ("progs.dat");
	precache_file ("gfx.wad");
	precache_file ("quake.rc");
	precache_file ("default.cfg");

	precache_file ("end1.bin");
	precache_file2 ("end2.bin");

	precache_file ("demo1.dem");
	precache_file ("demo2.dem");
	precache_file ("demo3.dem");

//
// these are all of the lumps from the cached.ls files
//
	precache_file ("gfx/palette.lmp");
	precache_file ("gfx/colormap.lmp");

	precache_file2 ("gfx/pop.lmp");

	precache_file ("gfx/complete.lmp");
	precache_file ("gfx/inter.lmp");

	precache_file ("gfx/ranking.lmp");
	precache_file ("gfx/vidmodes.lmp");
	precache_file ("gfx/finale.lmp");
	precache_file ("gfx/conback.lmp");
	precache_file ("gfx/qplaque.lmp");

	precache_file ("gfx/menudot1.lmp");
	precache_file ("gfx/menudot2.lmp");
	precache_file ("gfx/menudot3.lmp");
	precache_file ("gfx/menudot4.lmp");
	precache_file ("gfx/menudot5.lmp");
	precache_file ("gfx/menudot6.lmp");

	precache_file ("gfx/menuplyr.lmp");
	precache_file ("gfx/bigbox.lmp");
	precache_file ("gfx/dim_modm.lmp");
	precache_file ("gfx/dim_drct.lmp");
	precache_file ("gfx/dim_ipx.lmp");
	precache_file ("gfx/dim_tcp.lmp");
	precache_file ("gfx/dim_mult.lmp");
	precache_file ("gfx/mainmenu.lmp");

	precache_file ("gfx/box_tl.lmp");
	precache_file ("gfx/box_tm.lmp");
	precache_file ("gfx/box_tr.lmp");

	precache_file ("gfx/box_ml.lmp");
	precache_file ("gfx/box_mm.lmp");
	precache_file ("gfx/box_mm2.lmp");
	precache_file ("gfx/box_mr.lmp");

	precache_file ("gfx/box_bl.lmp");
	precache_file ("gfx/box_bm.lmp");
	precache_file ("gfx/box_br.lmp");

	precache_file ("gfx/sp_menu.lmp");
	precache_file ("gfx/ttl_sgl.lmp");
	precache_file ("gfx/ttl_main.lmp");
	precache_file ("gfx/ttl_cstm.lmp");

	precache_file ("gfx/mp_menu.lmp");

	precache_file ("gfx/netmen1.lmp");
	precache_file ("gfx/netmen2.lmp");
	precache_file ("gfx/netmen3.lmp");
	precache_file ("gfx/netmen4.lmp");
	precache_file ("gfx/netmen5.lmp");

	precache_file ("gfx/sell.lmp");

	precache_file ("gfx/help0.lmp");
	precache_file ("gfx/help1.lmp");
	precache_file ("gfx/help2.lmp");
	precache_file ("gfx/help3.lmp");
	precache_file ("gfx/help4.lmp");
	precache_file ("gfx/help5.lmp");

	precache_file ("gfx/pause.lmp");
	precache_file ("gfx/loading.lmp");

	precache_file ("gfx/p_option.lmp");
	precache_file ("gfx/p_load.lmp");
	precache_file ("gfx/p_save.lmp");
	precache_file ("gfx/p_multi.lmp");

// sounds loaded by C code
	precache_sound ("misc/menu1.wav");
	precache_sound ("misc/menu2.wav");
	precache_sound ("misc/menu3.wav");

	precache_sound ("ambience/water1.wav");
	precache_sound ("ambience/wind2.wav");

// shareware
	precache_file ("maps/start.bsp");

	precache_file ("maps/e1m1.bsp");
	precache_file ("maps/e1m2.bsp");
	precache_file ("maps/e1m3.bsp");
	precache_file ("maps/e1m4.bsp");
	precache_file ("maps/e1m5.bsp");
	precache_file ("maps/e1m6.bsp");
	precache_file ("maps/e1m7.bsp");
	precache_file ("maps/e1m8.bsp");

// registered
	precache_file2 ("gfx/pop.lmp");

	precache_file2 ("maps/e2m1.bsp");
	precache_file2 ("maps/e2m2.bsp");
	precache_file2 ("maps/e2m3.bsp");
	precache_file2 ("maps/e2m4.bsp");
	precache_file2 ("maps/e2m5.bsp");
	precache_file2 ("maps/e2m6.bsp");
	precache_file2 ("maps/e2m7.bsp");

	precache_file2 ("maps/e3m1.bsp");
	precache_file2 ("maps/e3m2.bsp");
	precache_file2 ("maps/e3m3.bsp");
	precache_file2 ("maps/e3m4.bsp");
	precache_file2 ("maps/e3m5.bsp");
	precache_file2 ("maps/e3m6.bsp");
	precache_file2 ("maps/e3m7.bsp");

	precache_file2 ("maps/e4m1.bsp");
	precache_file2 ("maps/e4m2.bsp");
	precache_file2 ("maps/e4m3.bsp");
	precache_file2 ("maps/e4m4.bsp");
	precache_file2 ("maps/e4m5.bsp");
	precache_file2 ("maps/e4m6.bsp");
	precache_file2 ("maps/e4m7.bsp");
	precache_file2 ("maps/e4m8.bsp");

	precache_file2 ("maps/end.bsp");

	precache_file2 ("maps/dm1.bsp");
	precache_file2 ("maps/dm2.bsp");
	precache_file2 ("maps/dm3.bsp");
	precache_file2 ("maps/dm4.bsp");
	precache_file2 ("maps/dm5.bsp");
	precache_file2 ("maps/dm6.bsp");

  #ifdef GAME_HIPNOTIC
    //MED
    //Added Hipnotic Pack
    precache_file ("maps/hip1m1.bsp");
    precache_file ("maps/hip1m2.bsp");
    precache_file ("maps/hip1m3.bsp");
    precache_file ("maps/hip1m4.bsp");
    precache_file ("maps/hip1m5.bsp");
    precache_file ("maps/hip2m1.bsp");
    precache_file ("maps/hip2m2.bsp");
    precache_file ("maps/hip2m3.bsp");
    precache_file ("maps/hip2m4.bsp");
    precache_file ("maps/hip2m5.bsp");
    precache_file ("maps/hip2m6.bsp");
    precache_file ("maps/hip3m1.bsp");
    precache_file ("maps/hip3m2.bsp");
    precache_file ("maps/hip3m3.bsp");
    precache_file ("maps/hip3m4.bsp");
    precache_file ("maps/hipdm1.bsp");
    precache_file ("maps/hipend.bsp");
    //precache_file ("maps/zoo.bsp");
    //precache_file ("maps/mark.bsp");
  #endif

  #ifdef GAME_ROGUE
    precache_file ("maps/r1m1.bsp");
    precache_file ("maps/r1m2.bsp");
    precache_file ("maps/r1m3.bsp");
    precache_file ("maps/r1m4.bsp");
    precache_file ("maps/r1m5.bsp");
    precache_file ("maps/r1m6.bsp");
    precache_file ("maps/r1m7.bsp");
    precache_file ("maps/r2m1.bsp");
    precache_file ("maps/r2m2.bsp");
    precache_file ("maps/r2m3.bsp");
    precache_file ("maps/r2m4.bsp");
    precache_file ("maps/r2m5.bsp");
    precache_file ("maps/r2m6.bsp");
    precache_file ("maps/r2m7.bsp");
    precache_file ("maps/r2m8.bsp");
    precache_file ("maps/ctf1.bsp");
  #endif
};


entity	lastspawn;

//=======================
/*QUAKED worldspawn (0 0 0) ?
Only used for the world entity.
Set message to the level name.
Set sounds to the cd track to play.

World Types:
0: medieval
1: metal
2: base
*/
//=======================

void() worldspawn =
{
  startingserverflags = serverflags;
  lastspawn = world;
	InitBodyQue ();

  #ifdef GAME_HIPNOTIC
    //JIM
    InitBulletHoles();
  #endif

// custom map attributes
	if (self.model == "maps/e1m8.bsp")
		cvar_set ("sv_gravity", "100");
	else
		cvar_set ("sv_gravity", "800");
  
  #ifdef ENGINE_KEX
    //Ry: Custom map title, from QuakeEnhancedQC
    self.message = GetMapName(self.message);
  #endif

// the area based ambient sounds MUST be the first precache_sounds

// player precaches
	W_Precache ();			// get weapon precaches
  #ifdef GAME_ROGUE
    RunePrecache();
  #endif

// sounds used from C physics code
	precache_sound ("demon/dland2.wav");		// landing thud
	precache_sound ("misc/h2ohit1.wav");		// landing splash

// setup precaches allways needed
	precache_sound ("items/itembk2.wav");		// item respawn sound
	precache_sound ("player/plyrjmp8.wav");		// player jump
	precache_sound ("player/land.wav");			// player landing
	precache_sound ("player/land2.wav");		// player hurt landing
	precache_sound ("player/drown1.wav");		// drowning pain
	precache_sound ("player/drown2.wav");		// drowning pain
	precache_sound ("player/gasp1.wav");		// gasping for air
	precache_sound ("player/gasp2.wav");		// taking breath
	precache_sound ("player/h2odeath.wav");		// drowning death

	precache_sound ("misc/talk.wav");			// talk
	precache_sound ("player/teledth1.wav");		// telefrag
	precache_sound ("misc/r_tele1.wav");		// teleport sounds
	precache_sound ("misc/r_tele2.wav");
	precache_sound ("misc/r_tele3.wav");
	precache_sound ("misc/r_tele4.wav");
	precache_sound ("misc/r_tele5.wav");
	precache_sound ("weapons/lock4.wav");		// ammo pick up
	precache_sound ("weapons/pkup.wav");		// weapon up
	precache_sound ("items/armor1.wav");		// armor up
	precache_sound ("weapons/lhit.wav");		//lightning
	precache_sound ("weapons/lstart.wav");		//lightning start
	precache_sound ("items/damage3.wav");

	precache_sound ("misc/power.wav");			//lightning for boss

// player gib sounds
	precache_sound ("player/gib.wav");			// player gib sound
	precache_sound ("player/udeath.wav");		// player gib sound
	precache_sound ("player/tornoff2.wav");		// gib sound

// player pain sounds

	precache_sound ("player/pain1.wav");
	precache_sound ("player/pain2.wav");
	precache_sound ("player/pain3.wav");
	precache_sound ("player/pain4.wav");
	precache_sound ("player/pain5.wav");
	precache_sound ("player/pain6.wav");

// player death sounds
	precache_sound ("player/death1.wav");
	precache_sound ("player/death2.wav");
	precache_sound ("player/death3.wav");
	precache_sound ("player/death4.wav");
	precache_sound ("player/death5.wav");

// ax sounds
	precache_sound ("weapons/ax1.wav");			// ax swoosh
	precache_sound ("player/axhit1.wav");		// ax hit meat
	precache_sound ("player/axhit2.wav");		// ax hit world

	precache_sound ("player/h2ojump.wav");		// player jumping into water
	precache_sound ("player/slimbrn2.wav");		// player enter slime
	precache_sound ("player/inh2o.wav");		// player enter water
	precache_sound ("player/inlava.wav");		// player enter lava
	precache_sound ("misc/outwater.wav");		// leaving water sound

	precache_sound ("player/lburn1.wav");		// lava burn
	precache_sound ("player/lburn2.wav");		// lava burn

	precache_sound ("misc/water1.wav");			// swimming
	precache_sound ("misc/water2.wav");			// swimming

  #ifdef GAME_HIPNOTIC
    //MED 10/21/96 added flies sound
    precache_sound ("misc/flys.wav");
    //MED 01/13/97 added explosion sounds
    precache_sound ("misc/shortexp.wav");
    precache_sound ("misc/longexpl.wav");
    precache_sound ("misc/foot1.wav");
    precache_sound ("misc/foot2.wav");
    precache_sound ("misc/foot3.wav");
    precache_sound ("misc/foot4.wav");
    precache_sound ("misc/foot5.wav");
    precache_sound ("misc/foot6.wav");
    precache_sound ("misc/foot7.wav");
  #endif
  #ifdef GAME_ROGUE
    // PGM Addition Sounds
    precache_sound ("enforcer/enfstop.wav");    // shield impact
    precache_sound ("plasma/explode.wav");
    precache_sound ("plasma/flight.wav");			
    precache_sound ("plasma/fire.wav");
    precache_sound ("shield/hit.wav");
    precache_sound ("belt/use.wav");
    precache_sound ("items/damage2.wav");
  #endif

  precache_model ("progs/player.mdl");
	precache_model ("progs/eyes.mdl");
	precache_model ("progs/h_player.mdl");
  #ifdef GAME_HIPNOTIC
    //MED 12/03/96 added player with hammer
    precache_model ("progs/playham.mdl");
  #endif
  precache_model ("progs/gib1.mdl");
	precache_model ("progs/gib2.mdl");
	precache_model ("progs/gib3.mdl");

	precache_model ("progs/s_bubble.spr");	// drowning bubbles
	precache_model ("progs/s_explod.spr");	// sprite explosion

	precache_model ("progs/v_axe.mdl");
	precache_model ("progs/v_shot.mdl");
	precache_model ("progs/v_nail.mdl");
	precache_model ("progs/v_rock.mdl");
	precache_model ("progs/v_shot2.mdl");
	precache_model ("progs/v_nail2.mdl");
	precache_model ("progs/v_rock2.mdl");

  #ifdef GAME_HIPNOTIC
    //MED 10/31/96 added precache for hip view models
    precache_model ("progs/v_laserg.mdl");
    precache_model ("progs/v_hammer.mdl");
    precache_model ("progs/v_prox.mdl");
    precache_model ("progs/proxbomb.mdl");
  #endif
  #ifdef GAME_ROGUE
    // Lava Gun models - pgm change
    precache_model ("progs/v_lava.mdl");
    precache_model ("progs/v_lava2.mdl");
    precache_model ("progs/v_multi.mdl");
    precache_model ("progs/v_multi2.mdl");
  #endif

	precache_model ("progs/bolt.mdl");		// for lightning gun
	precache_model ("progs/bolt2.mdl");		// for lightning gun
	precache_model ("progs/bolt3.mdl");		// for boss shock
	precache_model ("progs/lavaball.mdl");	// for testing
  #ifdef GAME_HIPNOTIC
    //MED 10/18/96 added precache for laser cannon
    precache_model ("progs/lasrspik.mdl");
  #endif

	precache_model ("progs/missile.mdl");
	precache_model ("progs/grenade.mdl");
	precache_model ("progs/spike.mdl");
	precache_model ("progs/s_spike.mdl");
  
  #ifdef GAME_ROGUE
    // PGM addition
    precache_model ("progs/mervup.mdl");
    precache_model ("progs/rockup.mdl");
    precache_model ("progs/rockup_d.mdl");
    precache_model ("progs/lspike.mdl");
    precache_model ("progs/shield.mdl");
    precache_model ("progs/p_shield.mdl");
  #endif

	precache_model ("progs/backpack.mdl");

	precache_model ("progs/zom_gib.mdl");

	precache_model ("progs/v_light.mdl");
  
  #ifdef GAME_ROGUE
    precache_model ("progs/plasma.mdl");
    precache_model ("progs/v_plasma.mdl");
    
    //ZOID--
    // hook for CTF
    precache_model ("progs/hook.mdl");
    precache_model ("progs/v_grpple.mdl");
    precache_model ("progs/beam.mdl"); //Ry: Remaster doesn't like that this wasn't precached
    //--ZOID
  #endif
  
  precache_sound ("doors/runeuse.wav"); //Ry: New frag confirmation sound


//
// Setup light animation tables. 'a' is total darkness, 'z' is maxbright.
//

	// 0 normal
	lightstyle(0, "m");

	// 1 FLICKER (first variety)
	lightstyle(1, "mmnmmommommnonmmonqnmmo");

	// 2 SLOW STRONG PULSE
	lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");

	// 3 CANDLE (first variety)
	lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");

	// 4 FAST STROBE
	lightstyle(4, "mamamamamama");

	// 5 GENTLE PULSE 1
	lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");

	// 6 FLICKER (second variety)
	lightstyle(6, "nmonqnmomnmomomno");

	// 7 CANDLE (second variety)
	lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");

	// 8 CANDLE (third variety)
	lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");

	// 9 SLOW STROBE (fourth variety)
	lightstyle(9, "aaaaaaaazzzzzzzz");

	// 10 FLUORESCENT FLICKER
	lightstyle(10, "mmamammmmammamamaaamammma");

	// 11 SLOW PULSE NOT FADE TO BLACK
	lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");

	// styles 32-62 are assigned by the light program for switchable lights

	// 63 testing
	lightstyle(63, "a");

  #ifdef GAME_HIPNOTIC
    //JIM
    StopEarthQuake();
    //MED 
    if ( !(cvar(SETTINGS_CVAR) & RY_FL_DISABLE_FOOTSTEPS) ) //Ry: Footsteps enabled by default, but can be turned off with a flag
      footsteps = TRUE;

    if ( !(cvar(SETTINGS_CVAR) & RY_FL_DISABLE_GREMITEMSTEAL) ) //Ry: Flag toggle for Gremlin's ability to pick up items
      grem_itemstealallowed = TRUE;
  #endif
  
  #ifndef GAME_ID1
    if ( !(cvar(SETTINGS_CVAR) & RY_FL_DISABLE_HIPREBALANCE) ) //Ry: Flag toggle for disabling balance adjustments for Mission Pack weapons and powerups
      hip_rebalance = TRUE;
  #endif

  if ( !(cvar(SETTINGS_CVAR) & RY_FL_DISABLE_WIDELIGHTNING) ) //Ry: Flag toggle for disabling the wide Thunderbolt beam fix
    wide_lightning = TRUE;

  if ( !(cvar(SETTINGS_CVAR) & RY_FL_DISABLE_WIDESPIKES) ) //Ry: Flag toggle for disabling Nails/Lasers having a bigger hitbox against players
    wide_spikes = TRUE;

  if (!deathmatch)
  {
    if ( cvar(SETTINGS_CVAR) & RY_FL_FASTMONSTERS ) //Ry: Flag toggle for Doom-style Fast Monsters
      fastmonsters = TRUE;

    if ( cvar(SETTINGS_CVAR) & RY_FL_COPPERNIGHTMARE ) //Ry: Some people enjoy this, I guess
      copper_nightmare = TRUE;
  }

  ach_weaponfired = FALSE; //Ry: Remaster ID1 achievements, now handled globally for proper Co-op handling
  ach_damagetaken = FALSE;

  mapstartweapons = 0;
  #ifndef GAME_ID1
    missionpackmap = FALSE;
    replacetime_ents = time + 0.3;
    #ifdef GAME_HIPNOTIC
      if (deathmatch)
        replacetime_weapons = time + 0.3;
      else
        replacetime_weapons = time + 5;
    #endif
  #endif

  #ifdef GAME_ROGUE
    teamplay = cvar("teamplay");
    #ifdef ENGINE_KEX //Ry: CTF mode innately uses Teamplay for Threewave settings
      if (cvar("ctf") && deathmatch)
      {
        if (teamplay == 0) //Ry: Switching off of CTF sets the Teamplay back to 0, but doesn't touch the actual CTF variable
        {
          cvar_set("ctf",ftos(0));
        }
        else if ( (teamplay < TEAM_CTF) || (teamplay > TEAM_CTF_ALT) )
        {
          //Ry: Convert Threewave teamplay flags to Dissolution gamecfg flags
          gameconfig = cvar("gamecfg");

          if (teamplay & TW_TEAM_HEALTH_PROTECT)
            gameconfig -= (gameconfig & GAMECFG_TEAM_HEALTH_DMG);
          else
            gameconfig |= GAMECFG_TEAM_HEALTH_DMG;

          if (teamplay & TW_TEAM_ARMOR_PROTECT)
            gameconfig -= (gameconfig & GAMECFG_TEAM_ARMOR_DMG);
          else
            gameconfig |= GAMECFG_TEAM_ARMOR_DMG;

          if (teamplay & TW_TEAM_SELECT_TEAM)
            gameconfig -= (gameconfig & GAMECFG_AUTO_TEAM);
          else
            gameconfig |= GAMECFG_AUTO_TEAM;

          cvar_set("gamecfg",ftos(gameconfig));
          teamplay = TEAM_CTF;
        }
      }
      else if (teamplay > TEAM_NORMAL_DAMAGE)
      {
        cvar_set("ctf",ftos(0));
        if (coop)
          teamplay = TEAM_NORMAL_NODAMAGE;
        else
          teamplay = FALSE;
      }
      cvar_set("teamplay",ftos(teamplay));
    #endif
    if (teamplay >= TEAM_CTF || (cvar(SETTINGS_CVAR) & RY_FL_ALWAYSGRAPPLE))
      grappleenabled = TRUE;
    
    //Ry: Experimental; When firing the Plasma Gun, the bolt is launched with a delay to match up to the firing sound.
    //    Not great for netplay.
    if ( (cvar(SETTINGS_CVAR) & RY_FL_ALTPLASMA) )
      altplasma = TRUE;
    
    #ifdef ENGINE_KEX
    //Ry: Initiate Deathmatch Tag through this now [09-21-2022]
    if ( deathmatch && (teamplay < TEAM_CTF) && (cvar("gamecfg") & GAMECFG_DMATCH_TAG) )
    #else
    if ( deathmatch && (teamplay == TEAM_DMATCH_TAG) )
    #endif
      dmatchtag = TRUE;
  #elifdef ENGINE_KEX
    //Ry: Reset these in case they were set by Dissolution
    if (cvar("ctf"))
      cvar_set("ctf",ftos(0));
    if (cvar("teamplay") > 2)
    {
      if (coop)
        cvar_set("teamplay",ftos(1));
      else
        cvar_set("teamplay",ftos(0));
    }
  #endif
  
  #ifdef GAME_ROGUE
  if (cvar("teamplay") >= TEAM_CTF)
    motd_priority = CPRINT_CHOICE;
  else
  #endif
    motd_priority = CPRINT_MOTD;

  //Ry: Set ammo caps for certain ammo types [09-06-2022]
  if (deathmatch)
  {
    ammocap_rockets = 50;
    #ifdef GAME_ROGUE
      ammocap_lava = 100;
      ammocap_multi = 20;
      ammocap_plasma = 30;
    #endif
  }
  else
  {
    ammocap_rockets = 100;
    #ifdef GAME_ROGUE
      ammocap_lava = 200;
      ammocap_multi = 100;
      ammocap_plasma = 100;
    #endif
  }

  debugspawns = FALSE;
  /*if ( (cvar(SETTINGS_CVAR) & RY_FL_DEBUGSPAWNS) )
  {
    debugspawns = TRUE;
    dprint("Spawn point debugging enabled\n");
  }*/

};

void() StartFrame =
{
	teamplay = cvar("teamplay");
	skill = cvar("skill");
  #ifdef GAME_ROGUE
    gameconfig = cvar("gamecfg");
  #endif
  #ifndef ENGINE_WINQUAKE
    cheats_allowed = cvar("sv_cheats");
    horde = cvar("horde");
    #ifdef ENGINE_KEX
      if (!campaign_valid)
      {
        campaign_valid = TRUE;
        campaign = cvar("campaign");
      }
      else
      {
        cvar_set("campaign", ftos(campaign));
      }
    #endif
  #endif
	framecount = framecount + 1;
  
  //Ry: Keep track of when the team wipes in Horde mode [09-22-2022]
  if (horde_ent)
  {
    if (!teamwipetime)
    {
      if (HordeGetPlayersAlive() <= 0)
        teamwipetime = time + 1;
    }
    else
    {
      if (HordeGetPlayersAlive() > 0) //Ry: If players somehow come back
      {
        teamwipetime = 0;
        local entity plr;
        plr = find(world,classname,"player");
        while (plr)
        {
          if (plr.deadflag && !(plr.flags & FL_ISBOT))
          {
            plr.lastcenterprinttype = CPRINT_NONE;
            plr.lastcenterprinttime = 0;
            centerprint(plr,"");
          }
          plr = find(plr,classname,"player");
        }
      }
      else if (time >= teamwipetime)
      {
        plr = find(world,classname,"player");
        while (plr)
        {
          if (plr.deadflag && !(plr.flags & FL_ISBOT))
          {
            #ifdef ENGINE_KEX
            if (plr.goalentity || !coop) //Ry: Spectator
            #endif
              FilteredCenterPrint(plr,CPRINT_CHOICE,"GAME OVER\n\nAll players have fallen...");
            #ifdef ENGINE_KEX
            else //Ry: Dead on the floor (pushed down so the scoreboard doesn't cover it)
              FilteredCenterPrint(plr,CPRINT_CHOICE,"\n\n\n\n\n\n\n\n\n\nGAME OVER\n\nAll players have fallen...");
            #endif
          }
          plr = find(plr,classname,"player");
        }
        teamwipetime = time + 1;
      }
    }
  }
  
  #ifndef GAME_ID1
    //Ry: Automatic replacements on ID1 maps
    if (!missionpackmap && (time >= replacetime_ents)) //Ry: Non-weapon replacements
    {
      missionpackmap = 2;
      #ifdef GAME_HIPNOTIC
        ReplaceBiosuits();
        if (!deathmatch)
          InjectHipnoticMonsters();
      #endif
      #ifdef GAME_ROGUE
        InjectAlternateAmmos();
        if (!deathmatch)
        {
          GenericMonsterReplace("monster_fish","eel",0.3);
          GenericMonsterReplace("monster_knight","sword",0.2);
          if (world.model != "maps/end.bsp")
          GenericMonsterReplace("monster_shalrath","wrath",0.25);
        }
      #endif
    }
    #ifdef GAME_HIPNOTIC
      if ( !deathmatch && (missionpackmap == 2) && (time >= replacetime_weapons) ) //Ry: Weapon item replacements
      {
        missionpackmap = 3;
        InjectHipnoticWeapons();
      }
    #endif
  #endif
  
  #ifdef GAME_ROGUE
    //Ry: Check for any players who want to switch teams
    if (deathmatch && (teamplay >= TEAM_CTF) && (teamplay <= TEAM_CTF_ALT))
    {
      local entity player,changeplayer;
      player = find(world,classname,"player");
      while (player)
      {
        if (player.desireteamchangetime)
        {
          if (!changeplayer)
            changeplayer = player;
          else if (player.desireteamchangetime < changeplayer.desireteamchangetime)
            changeplayer = player;
        }
        player = find(player,classname,"player");
      }
      if (changeplayer)
      {
        TryChangeTeam(changeplayer);
      }
    }
  #endif
  
  //Ry: If enabled, do fast monsters here [09-06-2022]
  DoFastMonsters();
};

/*
==============================================================================

BODY QUE

==============================================================================
*/

entity	bodyque_head;

void() bodyque =
{	// just here so spawn functions don't complain after the world
	// creates bodyques
};

void() InitBodyQue =
{
	bodyque_head = spawn();
	bodyque_head.classname = "bodyque";
	bodyque_head.owner = spawn();
	bodyque_head.owner.classname = "bodyque";
	bodyque_head.owner.owner = spawn();
	bodyque_head.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner = spawn();
	bodyque_head.owner.owner.owner.classname = "bodyque";
  if (deathmatch) //Ry: Doubled number of bodyques available in Deathmatch
  {
    bodyque_head.owner.owner.owner.owner = spawn();
    bodyque_head.owner.owner.owner.owner.classname = "bodyque";
    bodyque_head.owner.owner.owner.owner.owner = spawn();
    bodyque_head.owner.owner.owner.owner.owner.classname = "bodyque";
    bodyque_head.owner.owner.owner.owner.owner.owner = spawn();
    bodyque_head.owner.owner.owner.owner.owner.owner.classname = "bodyque";
    bodyque_head.owner.owner.owner.owner.owner.owner.owner = spawn();
    bodyque_head.owner.owner.owner.owner.owner.owner.owner.classname = "bodyque";
    bodyque_head.owner.owner.owner.owner.owner.owner.owner.owner = bodyque_head;
  }
  else
    bodyque_head.owner.owner.owner.owner = bodyque_head;
};


// make a body que entry for the given ent so the ent can be
// respawned elsewhere
void(entity ent) CopyToBodyQue =
{
  if (ent.model != "") //Ry: Make sure player has a model, in case this is called during deferred spawning
  {
    #ifdef GAME_HIPNOTIC
      local entity head;
      if (ent.model == "progs/h_player.mdl") //Ry: Set this appropriately based on whether it's a head or not (For Gremlins)
        bodyque_head.gremstate = GREM_GORGING;
      else
        bodyque_head.gremstate = GREM_DEFAULT;
      bodyque_head.health = ent.health; //Ry: Copy health for Gremlins
      if (bodyque_head.health > 0)
        bodyque_head.health = 0;
      
      //Ry: Gremlins wanting to gorge on this player's corpse will update target to the bodyque
      for (head = find(world, classname, "monster_gremlin") ; head ; head = find(head, classname, "monster_gremlin") )
        if ( (head.health > 0) && (head.enemy == ent) )
          head.enemy = bodyque_head;
    #endif
    #ifdef GAME_ROGUE
      // PGM - support for new deathmatch skins on corpses too!
      bodyque_head.skin = ent.skin;
    #endif

    bodyque_head.angles = ent.angles;
    bodyque_head.model = ent.model;
    bodyque_head.modelindex = ent.modelindex;
    bodyque_head.frame = ent.frame;
    bodyque_head.colormap = ent.colormap;
    bodyque_head.movetype = ent.movetype;
    bodyque_head.velocity = ent.velocity;
    bodyque_head.flags = 0;

    //Ry: Allow the death animation to finish if it didn't (Can happen in Horde Mode when everyone respawns) [07-31-2022]
    if (ent.deadflag == DEAD_DYING)
    {
      bodyque_head.think = ent.think;
      bodyque_head.nextthink = ent.nextthink;
    }

    setorigin (bodyque_head, ent.origin);
    setsize (bodyque_head, ent.mins, ent.maxs);
    bodyque_head = bodyque_head.owner;
  }
};
