// Rogue Teamplay Variants
// Jan'97 by ZOID <zoid@threewave.com>
// Under contract to id software for Rogue Entertainment


// New entity fields

.float steam;		// selected team
//.float suicide_count; // how many times has this player done something silly?
.float ctf_flags; // various flags for CTF
.float ctf_killed;	// used for base spawning
.float ctf_flagsince;	// when we picked up the flag
.float ctf_lasthurtcarrier; // when we last hurt the carrier
.float ctf_lastreturnedflag; // when we returned the flag
.float ctf_lastfraggedcarrier; // when we last fragged the carrier

float TEAM1	= 5;  // color of team1 (red), note that this is self.team which
				//is one more than the color setting, so 'color 4' is red.
float TEAM2 = 3;  // color of team2 (blue), note that this is self.team which
				//is one more than the color setting, so 'color 13' is blue.  //Ry: Was 14
float TEAM3	= 13; // color of team3 (grey) in alt CTF  //Ry: Was 11 for Grey, but is now Yellow

float nextteamupdtime; // next time for a broadcast update

// TEAMPLAY VALUES

float TEAM_NORMAL_NODAMAGE	=	1;	// id's normal teamplay, can't hurt self
float TEAM_NORMAL_DAMAGE	=	2;	// id's alt teamplay, can hurt self/team
#ifndef ENGINE_KEX
  float TEAM_DMATCH_TAG		=	3;	// deathmatch tag, no 'team' stuff
#endif
float TEAM_CTF				=	4;	// regular CTF, locked colors
float TEAM_CTF_ONEFLAG		=	5;	// one flag CTF
float TEAM_CTF_ALT			=	6;	// alternate CTF (three teams)

// gamecfg cvar fields

float GAMECFG_ENABLE_RUNES		=	1; // enable runes (default is disabled)
float GAMECFG_TEAM_ARMOR_DMG	=	2; // 2 team damage affects armor (default is not)
float GAMECFG_TEAM_HEALTH_DMG	=	4; // 4 team damage affects health (default is not)
float GAMECFG_USE_COLOR			=	8; // use color player joins as (if you join and start with blue, you will go
//    to blue team, same with red/green.  If you are an illegal color, you'll
//    get assigned).
//float GAMECFG_ALLOW_CHG			=	16; // allow people to change teams

float CTF_CAPTURE_BONUS = 10; // what you get for capture
float CTF_ALT_CAPTURE_BONUS = 10; // what you get for capture
#ifdef CTF_ASSISTS
  float CTF_TEAM_BONUS = 0; // what your team gets for capture
  float CTF_ALT_TEAM_BONUS = 0; // what your team gets for capture
  float CTF_RECOVERY_BONUS = 1; // what you get for recovery
  float CTF_FLAG_BONUS = 0; // what you get for picking up enemy flag
  float CTF_FRAG_CARRIER_BONUS = 2; // what you get for fragging enemy flag carrier
  float CTF_CARRIER_DANGER_PROTECT_BONUS = 2; // bonus for fraggin someone
    // who has recently hurt your flag carrier
  float CTF_CARRIER_PROTECT_BONUS = 1; // bonus for fraggin someone while
    // either you or your target are near your flag carrier
  float CTF_FLAG_DEFENSE_BONUS = 1; // bonus for fraggin someone while
    // either you or your target are near your flag
  float CTF_RETURN_FLAG_ASSIST_BONUS = 1; // awarded for returning a flag that causes a
    // capture to happen almost immediately
  float CTF_FRAG_CARRIER_ASSIST_BONUS = 2; // award for fragging a flag carrier if a
    // capture happens almost immediately
  float CTF_TARGET_PROTECT_RADIUS = 400; // the radius around an object being
    // defended where a target will be worth extra frags
  float CTF_ATTACKER_PROTECT_RADIUS = 400; // the radius around an object being
    // defended where an attacker will get extra frags when making kills
  float CTF_CARRIER_DANGER_PROTECT_TIMEOUT = 4;
  float CTF_CARRIER_FLAG_SINCE_TIMEOUT = 2;
  float CTF_FRAG_CARRIER_ASSIST_TIMEOUT = 6;
  float CTF_RETURN_FLAG_ASSIST_TIMEOUT = 4;
#endif
float CTF_FLAG_RETURN_TIME = 40; // seconds until auto return
float CTF_UPDATE_TIME = 120;

// CTF flags
float CTF_FLAG_FLAG			=	1;	// player has flag in one flag mode
float CTF_FLAG_TEAM1		=	1;	// player has team1's flag
float CTF_FLAG_TEAM2		=	2;	// player has team2's flag
float CTF_FLAG_STUFF_COLOR	=	4;	// gotta stuff his color

// flag status used in cnt field of flag
float FLAG_AT_BASE = 0;
float FLAG_CARRIED = 1;
float FLAG_DROPPED = 2;

// Prototypes
float() W_BestWeapon;
void() W_SetCurrentAmmo;
void() bound_other_ammo;
void(float o, float n) Deathmatch_Weapon;
void() BackpackTouch;
void(entity comboOwner) EnableComboWeapons;


//======================
//  New Subs by Ryason
//======================

.float teamselecttime; //Ry: Time at which a player selecting a team will be pulled into the game regardless

float teamscr1;     // team 1's capture score
float teamscr2;     // team 2's capture score
float teamscr3;     // team 3's capture score

float GAMECFG_AUTO_TEAM  = 16; //Ry: Don't show team selection prompt on join
#ifdef ENGINE_KEX
  float GAMECFG_DMATCH_TAG = 32; //Ry: Deathmatch tag initiated through this now

  //Ry: Teamplay values used by Threewave, which Remaster sets when starting CTF
  float TW_TEAM_HEALTH_PROTECT = 1;
  float TW_TEAM_ARMOR_PROTECT =  2;
  float TW_TEAM_STATIC_TEAMS =   64;
  float TW_TEAM_SELECT_TEAM =    1024;

  void(entity e) SendCTFScoresUpdate;
  void() SendCTFScoresUpdateAll; // send score update to all players using new EX HUD
#endif
void() TeamCheckLock;
string(float Team) GetCTFTeam;

//Ry: From Remaster Threewave CTF
void(entity e, float top, float bottom) TeamSetColor =
{
  if (cvar("pr_checkextension"))
  {
    if (checkextension("DP_SV_SETCOLOR"))
    {
      local float color = bottom + (top * 16);
      setcolor(e, color);
      return;
    }
  }

  local string n;
  
  stuffcmd(self, "color ");
  n = ftos(top);
  stuffcmd(self, n);
  stuffcmd(self, " ");
  n = ftos(bottom);
  stuffcmd(self, n);
  stuffcmd(self, "\n");
}

void() MOTD_ChooseTeam =
{
  SendTeamplayValue(self);

  if (PromptSupported())
  {
    local float options = 3;
    local string message;
    if (teamplay == TEAM_CTF_ALT)
    {
      message = "Dissolution Ry-vitalized V3.0\nThree Team Capture the Flag\n\nSelect your team:";
      options = 4;
    }
    else if (teamplay == TEAM_CTF_ONEFLAG)
      message = "Dissolution Ry-vitalized V3.0\nOne Flag Capture the Flag\n\nSelect your team:";
    else
      message = "Dissolution Ry-vitalized V3.0\nCapture the Flag\n\nSelect your team:";
    prompt(self, message, options);
    #ifdef ENGINE_KEX
      promptchoice(self, "$qc_ctf_intro_auto", 103);
      promptchoice(self, "$qc_ctf_intro_red", 101);
      promptchoice(self, "$qc_ctf_intro_blue", 102);
    #else
      promptchoice(self, "Automatic Team", 103);
      promptchoice(self, "Red Team", 101);
      promptchoice(self, "Blue Team", 102);
    #endif
    if (options == 4)
      promptchoice(self, "Yellow Team", 104);
    #ifdef ENGINE_KEX
      stuffcmd(self,"RyModJoin\n"); //Ry: If the client has stuffcmd allowed, call this customizable alias function
      self.motd_cmd = TRUE;
    #endif
    self.motd_time = 0;
  }
  else
  {
    //Ry: Set normal MOTD, which will have team selection instructions
    self.motd_count = 30;
    MOTD();
  }
};

#ifdef ENGINE_KEX
  void(entity e) SendCTFScoresUpdate =
  {
    local float flagstatus = 0;
    local entity flag;

    flag = find(world, classname, "item_flag_team1");
    if (flag) //Ry: Double-check that flags exist [09-08-2022]
    {
      if (flag.cnt == FLAG_AT_BASE)
        flagstatus |= 1;
      else if (flag.cnt == FLAG_CARRIED)
        flagstatus |= 2;
      else if (flag.cnt == FLAG_DROPPED)
        flagstatus |= 4;

      flag = find(world, classname, "item_flag_team2");
      if (flag)
      {
        if (flag.cnt == FLAG_AT_BASE)
          flagstatus |= 8;
        else if (flag.cnt == FLAG_CARRIED)
          flagstatus |= 16;
        else if (flag.cnt == FLAG_DROPPED)
          flagstatus |= 32;

        stuffcmd(e, "ctfscores ");
        stuffcmd(e, ftos(teamscr1));
        stuffcmd(e, " ");
        stuffcmd(e, ftos(teamscr2));
        stuffcmd(e, " ");
        stuffcmd(e, ftos(flagstatus));
        stuffcmd(e, "\n");
      }
    }
  };

  void() SendCTFScoresUpdateAll =
  {
    local entity e = find(world, classname, "player");
    while(e)
    {
      SendCTFScoresUpdate(e);
      e = find(e, classname, "player");
    }
    dprint("Updated CTF scores and flag statuses\n");
  }
#endif

void() TeamEndScore = 
{
  if (teamplay == TEAM_CTF || teamplay == TEAM_CTF_ONEFLAG)
  {
    if (teamscr1 > teamscr2)
    {
      #ifdef ENGINE_KEX
        bprint("$qc_ks_red_won", ftos(teamscr1));
        bprint("$qc_ks_blue_lost", ftos(teamscr2));
      #else
        bprint("RED team won the match with ");
        bprint(ftos(teamscr1));
        bprint(" points!\n");
        bprint("BLUE team lost the match with ");
        bprint(ftos(teamscr2));
        bprint(" points.\n");
      #endif
    }
    else if (teamscr1 < teamscr2)
    {
      #ifdef ENGINE_KEX
        bprint("$qc_ks_blue_won", ftos(teamscr2));
        bprint("$qc_ks_red_lost", ftos(teamscr1));
      #else
        bprint("BLUE team won the match with ");
        bprint(ftos(teamscr2));
        bprint(" points!\n");
        bprint("RED team lost the match with ");
        bprint(ftos(teamscr1));
        bprint(" points.\n");
      #endif
    }
    else
    {
      #ifdef ENGINE_KEX
        bprint("$qc_ks_match_tied", ftos(teamscr1));
      #else
        bprint("The match was tied with ");
        bprint(ftos(teamscr1));
        bprint(" points.\n");
      #endif
    }
  }
  //Ry: [TODO] Three Team CTF stuff
};

void() TeamScoreReport =
{
  local string status1, status2, status3, status4;
  local float scoreA, scoreB, teamB;
  if (teamplay >= TEAM_CTF)
  {
    if (teamplay != TEAM_CTF_ALT)
    {
      if (teamscr1 == teamscr2)
      {
        if (teamscr1 == 1)
          status2 = " point\n";
        else
          status2 = " points\n";
        #ifdef ENGINE_KEX
          FilteredCenterPrint(self, CPRINT_GAMEMODE, "Teams are tied with {}{}", ftos(teamscr1), status2);
        #else
          FilteredCenterPrint(self, CPRINT_GAMEMODE, "Teams are tied with ", ftos(teamscr1), status2);
        #endif
        return;
      }
      if (self.steam == TEAM1)
      {
        scoreA = teamscr1;
        scoreB = teamscr2;
        teamB = TEAM2;
      }
      else if (self.steam == TEAM2)
      {
        scoreA = teamscr2;
        scoreB = teamscr1;
        teamB = TEAM1;
      }
      else
        return;

      if (scoreA > scoreB)
      {
        #ifdef ENGINE_KEX
          status1 = "Your team leads with {}{}{}{}{}";
        #else
          status1 = "Your team leads with ";
        #endif
        if (teamB == TEAM1)
          status3 = "RED team is behind with ";
        else
          status3 = "BLUE team is behind with ";
      }
      else
      {
        #ifdef ENGINE_KEX
          status1 = "Your team is behind with {}{}{}{}{}";
        #else
          status1 = "Your team is behind with ";
        #endif
        if (teamB == TEAM1)
          status3 = "RED team leads with ";
        else
          status3 = "BLUE team leads with ";
      }
      if (scoreA == 1)
        status2 = " point\n";
      else
        status2 = " points\n";
      if (scoreB == 1)
        status4 = " point";
      else
        status4 = " points";
      FilteredCenterPrint(self, CPRINT_GAMEMODE, status1, ftos(scoreA), status2, status3, ftos(scoreB), status4);
    }
    else
    {
      if ((teamscr1 == teamscr2) && (teamscr1 == teamscr3))
      {
        if (teamscr1 == 1)
          status2 = " point";
        else
          status2 = " points";
        #ifdef ENGINE_KEX
          FilteredCenterPrint(self, CPRINT_GAMEMODE, "Teams are tied with {}{}", ftos(teamscr1), status2);
        #else
          FilteredCenterPrint(self, CPRINT_GAMEMODE, "Teams are tied with ", ftos(teamscr1), status2);
        #endif
        return;
      }
      if (self.steam == TEAM1)
      {
        scoreA = teamscr1;
        if (teamscr2 >= teamscr3)
        {
          scoreB = teamscr2;
          teamB = TEAM2;
        }
        else
        {
          scoreB = teamscr3;
          teamB = TEAM3;
        }
      }
      else if (self.steam == TEAM2)
      {
        scoreA = teamscr2;
        if (teamscr1 >= teamscr3)
        {
          scoreB = teamscr1;
          teamB = TEAM1;
        }
        else
        {
          scoreB = teamscr3;
          teamB = TEAM3;
        }
      }
      else if (self.steam == TEAM3)
      {
        scoreA = teamscr3;
        if (teamscr1 >= teamscr2)
        {
          scoreB = teamscr1;
          teamB = TEAM1;
        }
        else
        {
          scoreB = teamscr2;
          teamB = TEAM2;
        }
      }
      else
        return;

      if (scoreA == 1)
        status2 = " point\n";
      else
        status2 = " points\n";
      if (scoreA > scoreB)
      {
        #ifdef ENGINE_KEX
          status1 = "Your team leads with {}{}{}{}{}";
        #else
          status1 = "Your team leads with ";
        #endif
        if (teamB == TEAM1)
          status3 = "RED team is behind with ";
        else if (teamB == TEAM2)
          status3 = "BLUE team is behind with ";
        else
          status3 = "YELLOW team is behind with ";
      }
      else if (scoreA < scoreB)
      {
        #ifdef ENGINE_KEX
          status1 = "Your team is behind with {}{}{}{}{}";
        #else
          status1 = "Your team is behind with ";
        #endif
        if (teamB == TEAM1)
          status3 = "RED team leads with ";
        else if (teamB == TEAM2)
          status3 = "BLUE team leads with ";
        else
          status3 = "YELLOW team leads with ";
      }
      else
      {
        #ifdef ENGINE_KEX
          FilteredCenterPrint(self, CPRINT_GAMEMODE, "Your team is tied with {} team with {}{}", GetCTFTeam(teamB),ftos(scoreA), status2);
        #else
          FilteredCenterPrint(self, CPRINT_GAMEMODE, "Your team is tied with ", GetCTFTeam(teamB), " team with ", ftos(scoreA), status2);
        #endif
        return;
      }
      if (scoreB == 1)
        status4 = " point";
      else
        status4 = " points";
      FilteredCenterPrint(self, CPRINT_GAMEMODE, status1, ftos(scoreA), status2, status3, ftos(scoreB), status4);
    }
  }
}

void() respawn;

void(entity player, float newteam) ChangeTeam =
{
  local entity stemp;
  stemp = self;
  self = player;
  self.steam = self.team = newteam;
  self.ctf_killed = FALSE;
  
  if (self.deadflag)
    respawn();
  else
    ClientKill(FALSE);
  self.frags = 0;
  self.ctf_flags |= CTF_FLAG_STUFF_COLOR;
  TeamCheckLock();

  bprint (self.netname);
  bprint (" changed to the ");
  bprint (GetCTFTeam(newteam));
  bprint (" team\n");

  self.desireteamchangetime = 0;
  self.teamchangecooldown = time + 60;
  self = stemp;
}

float(entity player) TryChangeTeam =
{
  local entity otherplr,swapplayer;
  local float team1count, team2count, team3count;
  
  //Ry: First, see if teams are already unbalanced
	team1count = 0;
	team2count = 0;
	team3count = 0;

	otherplr = find (world, classname, "player");
	while(otherplr) {
		if (otherplr != self) {
			if (otherplr.steam == TEAM1)
				team1count = team1count + 1;
			else if (otherplr.steam == TEAM2)
				team2count = team2count + 1;
			else if (otherplr.steam == TEAM3)
				team3count = team3count + 1;
		}
		otherplr = find(otherplr, classname, "player");
	}
  
  //Ry: Less players on Yellow team
  team3count = team3count * 2;

  if (player.steam == TEAM1)
  {
    if (team2count < team1count)
    {
      ChangeTeam(player,TEAM2);
      return TRUE;
    }
    else if ((teamplay == TEAM_CTF_ALT) && (team3count < team1count))
    {
      ChangeTeam(player,TEAM3);
      return TRUE;
    }
  }
  else if (player.steam == TEAM2)
  {
    if (team1count < team2count)
    {
      ChangeTeam(player,TEAM1);
      return TRUE;
    }
    else if ((teamplay == TEAM_CTF_ALT) && (team3count < team2count))
    {
      ChangeTeam(player,TEAM3);
      return TRUE;
    }
  }
  else if ((teamplay == TEAM_CTF_ALT) && (player.steam == TEAM3))
  {
    if (team1count < team3count)
    {
      ChangeTeam(player,TEAM1);
      return TRUE;
    }
    else if (team2count < team3count)
    {
      ChangeTeam(player,TEAM2);
      return TRUE;
    }
  }

  //Ry: Otherwise, see if we can find someone to swap with
  otherplr = find(world,classname,"player");
  while (otherplr)
  {
    if (otherplr.steam != player.steam)
    {
      //Ry: Bots are always willing to swap
      if (otherplr.flags & FL_ISBOT)
      {
        if (!otherplr.ctf_flags) //Ry: Don't swap while carrying a flag
        {
          if (!swapplayer)
            swapplayer = otherplr;
          else if ((otherplr.frags < swapplayer.frags) && (swapplayer.flags & FL_ISBOT))
            swapplayer = otherplr;
        }
      }
      else if (otherplr.desireteamchangetime) //Ry: Another player is willing to swap
      {
        if (!swapplayer)
          swapplayer = otherplr;
        else if (otherplr.desireteamchangetime < swapplayer.desireteamchangetime || (swapplayer.flags & FL_ISBOT))
          swapplayer = otherplr;
      }
    }
    otherplr = find(otherplr,classname,"player");
  }
  if (swapplayer)
  {
    team1count = player.steam;
    ChangeTeam(player,swapplayer.steam);
    ChangeTeam(swapplayer,team1count);
    return TRUE;
  }
  return FALSE;
}

//===================
//  End of new subs
//===================


// Return a name for the color of a team
string(float Team) GetTeamColor =
{
	if(Team == 1) return("White");
	else if(Team == 2) return("Brown");
	else if(Team == 3) return("Light blue");
	else if(Team == 4) return("Green");
	else if(Team == 5) return("Red");
	else if(Team == 6) return("Olive");
	else if(Team == 7) return("Orange");
	else if(Team == 8) return("Peech");
	else if(Team == 9) return("Purple");
	else if(Team == 10) return("Majenta");
	else if(Team == 11) return("Grey");
	else if(Team == 12) return("Aqua");
	else if(Team == 13) return("Yellow");
	else if(Team == 14) return("Blue");
	return "Unknown";
};

string(float Team) GetCTFTeam =
{
	if (Team == TEAM1) return "RED"; 
	else if (Team == TEAM2) return "BLUE";
	else if (Team == TEAM3) return "YELLOW";
	return "UNKNOWN";
};

/*
================
TeamArmorDam

Return TRUE if the target's armor can take damage from this attacker.
================
*/

float(entity targ, entity inflictor, entity attacker, float damage) TeamArmorDam =
{
	if (teamplay <= 0)
		return TRUE;	// PGM bug? fix

	// teamplay modes 4,5,6 protect armor
	if ((teamplay == TEAM_CTF ||
		teamplay == TEAM_CTF_ONEFLAG ||
		teamplay == TEAM_CTF_ALT) &&
		attacker.steam == targ.steam && 
		attacker != targ &&
		!(gameconfig & GAMECFG_TEAM_ARMOR_DMG)) {
		// Armor is protected
		return FALSE;
	}
	return TRUE;
};

/*
================
TeamHealthDam

Return TRUE if the target can take health damage from this attacker.
================
*/

float(entity targ, entity inflictor, entity attacker, float damage) TeamHealthDam =
{
  //Ry: Can now always damage self, and monsters [09-10-2022]
	if ((teamplay <= 0) || (targ == attacker) || (targ.flags & FL_MONSTER))
		return TRUE;

	if (teamplay == TEAM_NORMAL_NODAMAGE && attacker.steam == targ.steam)
		return FALSE;

	// teamplay modes 4,5,6 protect health
	if ((teamplay == TEAM_CTF ||
		teamplay == TEAM_CTF_ONEFLAG ||
		teamplay == TEAM_CTF_ALT) &&
		attacker.steam == targ.steam && 
		attacker != targ &&
		!(gameconfig & GAMECFG_TEAM_HEALTH_DMG)) {
		// Health is protected
		return FALSE;
	}
	return TRUE;
};

void(entity who) TeamResetCarrier = 
{
	local entity head;

	// When the flag carrier dies, reset the last_hurt_carrier field in
	// all players on the opposite team from the flag carrier.  The carrier
	// has been killed, so there is no longer a reason to award points for
	// killing off his assailants
	if (teamplay >= TEAM_CTF &&
		(who.ctf_flags & (CTF_FLAG_TEAM1 | CTF_FLAG_TEAM2))) {

		head = find(world, classname, "player");

		while (head != world) {	
			if (teamplay == TEAM_CTF_ONEFLAG ||
				((who.ctf_flags & CTF_FLAG_TEAM1) && head.steam == TEAM1) ||
				((who.ctf_flags & CTF_FLAG_TEAM2) && head.steam == TEAM2))
				head.ctf_lasthurtcarrier = -10;
			head = find(head, classname, "player");
		}
	}
};

#ifdef CTF_ASSISTS
  void(entity targ, entity attacker) TeamAssists =
  {
    local float flag_radius;
    local float flag_carrier_radius;
    local string s;
    local entity head;

    if ((targ.ctf_flags & (CTF_FLAG_TEAM1 | CTF_FLAG_TEAM2)) &&
      targ.steam != attacker.steam) {
      //ZOID: one team fragged the other team's flag carrier

      // Mark the attacker with the time at which he killed the flag
      // carrier, for awarding assist points
      attacker.ctf_lastfraggedcarrier = time;

      // give player only the normal amount of frags
      // if the carrier has only had the flag for a few seconds, to
      // prevent ppl intentionally allowing enemies to grab the flag,
      // then immediately fragging them
      if (targ.ctf_flagsince + CTF_CARRIER_FLAG_SINCE_TIMEOUT > time) {
        sprint(attacker, "Enemy flag carrier killed, no bonus\n");
      } else {
        attacker.frags = attacker.frags + CTF_FRAG_CARRIER_BONUS;
        sprint(attacker, "Enemy flag carrier killed: ");
        s = ftos(CTF_FRAG_CARRIER_BONUS);
        sprint(attacker, s);
        sprint(attacker, " bonus frags\n");
      }
    }
    
    // This code checks for all game-critical kills OTHER THAN fragging the enemy
    // flag carrier, like killing players who are trying to kill your flag carrier
    // or trying to grab your flag, and hands out bonus frags.

    // The two variables below track whether special bonus frags have already
    // been awarded for the attacker or target being near the flag or flag carrier.  

    flag_radius = 0;
    flag_carrier_radius = 0;

    // get a string for the attacker's team now, for later announcements
    s = GetCTFTeam(attacker.steam);

    if ((targ.ctf_lasthurtcarrier + CTF_CARRIER_DANGER_PROTECT_TIMEOUT > time) &&
      !(attacker.ctf_flags & (CTF_FLAG_TEAM1 | CTF_FLAG_TEAM2))) {
      // a player on the same team as the flag carrier killed 
      // someone who recently shot the flag carrier
      attacker.frags = attacker.frags + CTF_CARRIER_DANGER_PROTECT_BONUS;
      flag_carrier_radius = 1;
      // NOTE: getting CARRIER_DANGER_PROTECT_BONUS precludes getting
      // other kinds of bonuses for defending the flag carrier, since
      // it's worth more points
      bprint(attacker.netname);
      bprint(" defends ");
      bprint(s);
      bprint("'s flag carrier against an agressive enemy\n");
    }

    // Bonusus for defending the flag carrier or the flag itself.
    // Extra frags are awarded if either the attacker or the target are
    // 1. within 40 feet of a flag carrier on the same team as the attacker
    // 2. within 40 feet of the attacker's flag
    // These bonuses are cumulative with respect to defending both the
    // flag and the flag carrier at the same time, but not cumulative with
    // respect to both the target and attacker being near the object being defended

    // find flags or flag carriers within a radius of the attacker
    head = findradius(attacker.origin, CTF_ATTACKER_PROTECT_RADIUS);

    while (head) {
      if (head.classname == "player") {
        if ( (head.steam == attacker.steam) &&
           (head.ctf_flags & (CTF_FLAG_TEAM1 | CTF_FLAG_TEAM2)) &&
           (head != attacker) && // self defense
           (!flag_carrier_radius) ) { 
          // attacker was near his own flag carrier
          attacker.frags = attacker.frags + CTF_CARRIER_PROTECT_BONUS;
          flag_carrier_radius = 1;
          bprint(attacker.netname);
          bprint(" defends ");
          bprint(s);
          bprint("'s flag carrier\n");
        }
      }
      if ((attacker.steam == TEAM1 && head.classname == "item_flag_team1") ||
        (attacker.steam == TEAM2 && head.classname == "item_flag_team2") ||
        head.classname == "item_flag") {  // one flag mode
        // attacker was near his own flag
        attacker.frags = attacker.frags + CTF_FLAG_DEFENSE_BONUS;
        flag_radius = 1; 
        bprint(attacker.netname);
        bprint(" defends the");
        if (teamplay != TEAM_CTF_ONEFLAG) {
          bprint(" ");
          bprint(s);
        }
        bprint(" flag\n");
      }
      head = head.chain;
    }

    // find flags or flag carriers within a radius from the target
    head = findradius(targ.origin, CTF_TARGET_PROTECT_RADIUS);
    while (head) {
      if (head.classname == "player") {
        if ( (head.steam == attacker.steam) &&
           (head.ctf_flags & (CTF_FLAG_TEAM1 | CTF_FLAG_TEAM2)) &&
           (head != attacker) &&
           (!flag_carrier_radius)) { // prevents redundant points awarded
          // target was near attacker's flag carrier
          attacker.frags = attacker.frags + CTF_CARRIER_PROTECT_BONUS;
          flag_carrier_radius = 1;
          bprint(attacker.netname);
          bprint(" defends ");
          bprint(s);
          bprint("'s flag carrier\n");
        }
      }
      if ((attacker.steam == TEAM1 && head.classname == "item_flag_team1") ||
        (attacker.steam == TEAM2 && head.classname == "item_flag_team2") ||
        head.classname == "item_flag" &&  // one flag mode
        (!flag_radius)) { // prevents redundant points awarded
        // target was near attacker's flag
        attacker.frags = attacker.frags + CTF_FLAG_DEFENSE_BONUS;
        flag_radius = 1;
        bprint(attacker.netname);
        bprint(" defends the");
        if (teamplay != TEAM_CTF_ONEFLAG) {
          bprint(" ");
          bprint(s);
        }
        bprint(" flag\n");
      }
      head = head.chain;
    }
  };
#endif
 
/*
==================
TeamColorIsLegal

Return TRUE if the indicated color is legal
==================
*/
float(float color) TeamColorIsLegal =
{
	// All colors are legal if teamplay is not CTF
	if( teamplay < TEAM_CTF) {
		if (color > 0)
			return TRUE;
		return FALSE;
	}

	// In regular CTF and CTF_ONEFLAG, only two colors are legal
	if (teamplay == TEAM_CTF || teamplay == TEAM_CTF_ONEFLAG)
		if (color == TEAM1 || color == TEAM2)
			return TRUE;
		else
			return FALSE;

	// In ALT CTF, three colors are legal
	if (teamplay == TEAM_CTF_ALT)
		if (color == TEAM1 || color == TEAM2 || color == TEAM3)
			return TRUE;
		else
			return FALSE;

	// dunno what teamplay we're in, let'em all be ok
	return TRUE;
};

/* TeamSetSkin - set the skin of the player model to the
   apropriate skin based on team and teamplay settings.
*/
void() TeamSetSkin =
{
	self.skin = 0;
	if (deathmatch)
	{
		if (teamplay >= TEAM_CTF)
			self.skin = 1;
	}
};

/*
==================
TeamCheckTeam

Check if the team self is on is legal, and put self in a legal team if not.
==================
*/
void() TeamCheckTeam =
{
	local float team1count;
	local float team2count;
	local float team3count;
	local float newcolor;
	local float t;
	local entity p;
	local string n; 

	if (self.steam >= 0 || teamplay < TEAM_CTF) {
		if(TeamColorIsLegal(self.team)) {
			self.steam = self.team;
			TeamSetSkin();
			return;
		}
	}

	// Assign the player to a team.

	// Sum the players on all the teams.
	team1count = 0;
	team2count = 0;
	team3count = 0;

	p = find (world, classname, "player");

	while(p) {
		if (p != self) {
			if (p.steam == TEAM1)
				team1count = team1count + 1;
			else if (p.steam == TEAM2)
				team2count = team2count + 1;
			else if (p.steam == TEAM3)
				team3count = team3count + 1;
		}
		p = find(p, classname, "player");
	}

	// Find the team with the least players.
	newcolor = TEAM1;
	t = team1count;

	if (team2count < t || (team2count == t && random() < 0.5)) {
		newcolor = TEAM2;
		t = team2count;
	}

	// in CTF_ALT, there's three teams
	team3count = team3count * 2; // grey team only gets half as many players
	if (teamplay == TEAM_CTF_ALT && team3count < t) {
		newcolor = TEAM3;
		t = team3count;
	}

	// Put the player on a the new team.
	self.ctf_flags = self.ctf_flags | CTF_FLAG_STUFF_COLOR;

	n = GetCTFTeam(newcolor);
  bprint(self.netname);
  bprint(" joined the ");
  bprint(n);
  bprint(" team!\n");

	self.steam = newcolor;      // Remember what team we're on
	self.team = newcolor;
	TeamSetSkin();
};

/* Check for team changing and perform whatever actions are neccessary.  */
void() TeamCheckLock =
{
	if (!deathmatch || teamplay < TEAM_CTF)
  {
		// all colors are legal, no force
		self.steam = self.team;
		return;
	}

	if (self.ctf_flags & CTF_FLAG_STUFF_COLOR)
  {
		self.ctf_flags = self.ctf_flags - CTF_FLAG_STUFF_COLOR;
    if (self.steam == TEAM1)
      TeamSetColor(self,6,self.steam-1);
    else if (self.steam == TEAM2)
      TeamSetColor(self,0,self.steam-1);
    else
      TeamSetColor(self,10,self.steam-1);
		TeamSetSkin();
		return;
	}

	if (!TeamColorIsLegal(self.team) && self.team == self.steam)
		self.steam = -1; // full reset

	// Check to see if the player has changed colors
	if (self.team != self.steam)
  {
		if (self.steam >= 0)
    {
			if (TeamColorIsLegal(self.steam))
      {
        if (self.steam == TEAM1)
          TeamSetColor(self,6,self.steam-1);
        else if (self.steam == TEAM2)
          TeamSetColor(self,0,self.steam-1);
        else
          TeamSetColor(self,10,self.steam-1);
        self.team = self.steam;
        return;
			}
      else
      {
				// If we're on an illegal team, force a change.
				self.steam = -50;
			}
		}

		if (self.steam > 0)
    {
			// case base respawn
			if (self.ctf_killed != 1)
				self.ctf_killed = 2;
			T_Damage(self,self,self,1000);  // Kill the player
		}
		self.frags = 0;                 // Zero out frags
		TeamCheckTeam(); // re-assignment
	}
};

void() Team_weapon_touch =
{
	local	float	best, new, old;
	local entity stemp;

	if (!(other.flags & FL_CLIENT))
		return;
	// Don't let the owner pick up his own weapon for a second.
	if ((other == self.owner) && ((self.nextthink - time) > 119))
		return;

// if the player was using his best weapon, change up to the new one if better		
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;

	if (self.classname == "weapon_nailgun")
		new = IT_NAILGUN;
	else if (self.classname == "weapon_supernailgun")
		new = IT_SUPER_NAILGUN;
	else if (self.classname == "weapon_supershotgun")
		new = IT_SUPER_SHOTGUN;
	else if (self.classname == "weapon_rocketlauncher")
		new = IT_ROCKET_LAUNCHER;
	else if (self.classname == "weapon_grenadelauncher")
		new = IT_GRENADE_LAUNCHER;
	else if (self.classname == "weapon_lightning")
		new = IT_LIGHTNING;
	else
		objerror ("Team_weapon_touch: unknown classname");

	sprint (other, "You got the ");
	sprint (other, self.netname);
	sprint (other, "\n");
// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	bound_other_ammo ();

// change to the weapon
	old = other.items;
	other.items = other.items | new;
	
	remove(self);
	self = other;

	if (!deathmatch)
		self.weapon = new;
	else
		Deathmatch_Weapon (old, new);

	EnableComboWeapons(self);
	UpdateAmmoCounts(self);

	W_SetCurrentAmmo();

	// dropped weapon doesn't target, so no need to call UseTargets
};
        
void() TossWeapon =
{
	local entity item;
	
	if (deathmatch != 1)
		return;  // only in deathmatch 1

	// only valid in teamplay modes
	if (teamplay < 1)
		return;

	if((self.weapon == IT_AXE) || (self.weapon == IT_SHOTGUN) ||
		(self.weapon == IT_GRAPPLE))
		return;
		
	item = spawn();
	item.owner = self;
	makevectors(self.v_angle);
	item.weapon = 0;

	setorigin(item, self.origin + '0 0 16');
	item.velocity = aim(self, 1000);
	item.velocity = item.velocity * 500;
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_BOUNCE;
	
	if(self.weapon == IT_SUPER_SHOTGUN)
	{
		setmodel (item, "progs/g_shot.mdl");
		item.weapon = IT_SUPER_SHOTGUN;
		item.netname = "Double-barrelled Shotgun";
		item.classname = "weapon_supershotgun";
		self.items = self.items - IT_SUPER_SHOTGUN;
	}

	if( self.weapon == IT_NAILGUN || self.weapon == IT_LAVA_NAILGUN )
	{
		setmodel (item, "progs/g_nail.mdl");
		item.weapon = IT_NAILGUN;
		item.netname = "nailgun";
		item.classname = "weapon_nailgun";
		self.items = self.items - (self.items & (IT_NAILGUN | IT_LAVA_NAILGUN));
	}
		
	if( self.weapon == IT_SUPER_NAILGUN || self.weapon == IT_LAVA_SUPER_NAILGUN)
	{
		setmodel (item, "progs/g_nail2.mdl");
		item.weapon = IT_SUPER_NAILGUN;
		item.netname = "Super Nailgun";
		item.classname = "weapon_supernailgun";
		self.items = self.items - (self.items & (IT_SUPER_NAILGUN | IT_LAVA_SUPER_NAILGUN));
	}
	
	if( self.weapon == IT_GRENADE_LAUNCHER || self.weapon == IT_MULTI_GRENADE)
	{
		setmodel (item, "progs/g_rock.mdl");
		item.weapon = IT_GRENADE_LAUNCHER;
		item.netname = "Grenade Launcher";
		item.classname = "weapon_grenadelauncher";
		self.items = self.items - (self.items & (IT_GRENADE_LAUNCHER | IT_MULTI_GRENADE));
	}
	
	if( self.weapon == IT_ROCKET_LAUNCHER || self.weapon == IT_MULTI_ROCKET)
	{
		setmodel (item, "progs/g_rock2.mdl");
		item.weapon = IT_ROCKET_LAUNCHER;
		item.netname = "Rocket Launcher";
		item.classname = "weapon_rocketlauncher";
		self.items = self.items - (self.items & (IT_ROCKET_LAUNCHER | IT_MULTI_ROCKET));
	}
	
	if( self.weapon == IT_LIGHTNING || self.weapon == IT_PLASMA_GUN)
	{
		setmodel (item, "progs/g_light.mdl");
		item.weapon = IT_LIGHTNING;
		item.netname = "Thunderbolt";
		item.classname = "weapon_lightning";
		self.items = self.items - (self.items & (IT_LIGHTNING | IT_PLASMA_GUN));
	}
	setsize(item, '-16 -16 0', '16 16 56');
	item.touch = Team_weapon_touch;
	item.think = SUB_Remove;
	item.nextthink = time + 120;
	
	self.weapon = W_BestWeapon();
	W_SetCurrentAmmo();
};

void(entity flg) RegenFlag =
{
	flg.movetype = MOVETYPE_TOSS;
	flg.solid = SOLID_TRIGGER;
	sound (flg, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);	// play respawn sound
	setorigin(flg, flg.oldorigin);
	flg.angles = flg.mangle;
	flg.cnt = FLAG_AT_BASE; // it's at home base
	flg.owner = world;
};

void(entity flg) TeamReturnFlag =
{
	local entity p;

	RegenFlag(flg);

	p = find(world, classname, "player");
	while (p != world) {
		if (teamplay == TEAM_CTF_ONEFLAG) // one flag mode?
			FilteredCenterPrint(p, CPRINT_GAMEMODE, "The flag has been returned!");
		else {
			if (teamplay == TEAM_CTF_ALT) {
				if (flg.team == TEAM1)
					FilteredCenterPrint(p, CPRINT_GAMEMODE, "RED flag has been returned to base!"); //Ry: Remaster didn't display the copper text
				else if (flg.team == TEAM2)
					FilteredCenterPrint(p, CPRINT_GAMEMODE, "BLUE flag has been returned to base!");
				else
					FilteredCenterPrint(p, CPRINT_GAMEMODE, "Some flag has been returned to base!");
			} else {
				if (p.steam != flg.team)
					FilteredCenterPrint(p, CPRINT_GAMEMODE, "Enemy flag has been returned to base!");
				else if (p.steam == flg.team)
					FilteredCenterPrint(p, CPRINT_GAMEMODE, "Your flag has been returned to base!");
			}
		}
		p = find(p, classname, "player");
	}
};

void () TeamRegenFlags =
{
	local entity f;

	if (teamplay == TEAM_CTF_ONEFLAG) {
		f = find(world, classname, "item_flag");
		if (f != world)
			RegenFlag(f);
		return;
	}

	f = find(world, classname, "item_flag_team1");
	if (f != world)
		RegenFlag(f);
	f = find(world, classname, "item_flag_team2");
	if (f != world)
		RegenFlag(f);
};

void(entity flg) TeamDropFlag =
{
	local entity p;

	p = flg.owner;

	bprint(p.netname);
	if (teamplay == TEAM_CTF_ONEFLAG)
		bprint(" lost the flag!\n");
	else {
		if (flg.team == TEAM1)
			bprint(" lost the RED flag!\n"); // red
		else
			bprint(" lost the BLUE flag!\n"); // blue
	}

	setorigin(flg, p.origin - '0 0 24');
	flg.cnt = FLAG_DROPPED;
	flg.velocity_z = 300;
	flg.velocity_x = 0;
	flg.velocity_y = 0;
	flg.flags = FL_ITEM;
	flg.solid = SOLID_TRIGGER;
	flg.movetype = MOVETYPE_TOSS;
	setsize(flg, '-16 -16 0', '16 16 74');
	// return it after so long
	flg.super_time = time + CTF_FLAG_RETURN_TIME;
  #ifdef ENGINE_KEX
    SendCTFScoresUpdateAll(); //Ry: Remaster flag status update
  #endif
};

void(entity player) TeamDropFlagOfPlayer =
{
	local string kn;
	local entity e;

	if (teamplay == TEAM_CTF_ONEFLAG && (player.ctf_flags & CTF_FLAG_FLAG))
		kn = "item_flag";
	else if (player.ctf_flags & CTF_FLAG_TEAM1) 
		kn = "item_flag_team1";
	else if (player.ctf_flags & CTF_FLAG_TEAM2) 
		kn = "item_flag_team2";
	else
		return; // doesn't have a flg
	player.ctf_flags = player.ctf_flags -
		(player.ctf_flags & (CTF_FLAG_FLAG | CTF_FLAG_TEAM1 | CTF_FLAG_TEAM2));
	e = find(world, classname, kn);
	if (e != world)
		TeamDropFlag(e);
};

// A flag was touched.  In one flag mode, the player always just picks it up
// (the flagbase models at each base will cause the score).  In two flag mode,
// it could be the guy returning his flag, or the guy getting the enemy flag
// Three team mode gets more complicated as the third team touches the 
// flagbase to score
void() TeamFlagTouch =
{
	local entity p;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	if (other.team != other.steam)
		return; // something is fishy, somebody is playing with colors

	if (self.cnt == FLAG_CARRIED)
		return; // huh?

	// Ok, first up, let's do it for one flag mode
	if (teamplay == TEAM_CTF_ONEFLAG) {
		// in one flag mode, we always pick up the flag.  The touch of the
		// flagbase entities does the scoring
		bprint(other.netname);
		bprint(" got the flag!\n"); //Ry: More copper text
    #ifdef CTF_ASSISTS
      if (CTF_FLAG_BONUS)
        other.frags = other.frags + CTF_FLAG_BONUS;
    #endif
		FilteredCenterPrint(other, CPRINT_GAMEMODE, "YOU GOT THE FLAG\n\nTAKE IT TO ENEMY BASE");

    //Ry: Don't use the same channel as common items [09-04-2022]
		sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);

		other.ctf_flags = other.ctf_flags | CTF_FLAG_FLAG;
		other.items = other.items | self.items;
		other.ctf_flagsince = time;

		// pick up the flag
		self.cnt = FLAG_CARRIED;
		self.movetype = MOVETYPE_NOCLIP;
		self.solid = SOLID_NOT;
		self.owner = other;

		p = find(world, classname, "player");
		while (p != world) {
			if (p != other)
				FilteredCenterPrint(p, CPRINT_GAMEMODE, "The flag has been taken!");
			p = find(p, classname, "player");
		}
		return;
	}

	// Regular and Alt CTF mode
	if (teamplay != TEAM_CTF && teamplay != TEAM_CTF_ALT)
		return; // odd, but ignore it

	if (self.team == other.steam) {
		// same team, if the flag is *not* at the base, return
		// it to base.  we overload the 'cnt' field for this
		if (self.cnt == FLAG_AT_BASE) {
			// the flag is at home base.  if the player has the enemy
			// flag, he's just won!
			if ((self.team == TEAM1 && (other.ctf_flags & CTF_FLAG_TEAM2)) ||
				(self.team == TEAM2 && (other.ctf_flags & CTF_FLAG_TEAM1))) {
				bprint(other.netname);
				if (other.team == TEAM1)
        {
					bprint(" captured the BLUE flag!\n"); // blue
          teamscr1 += 1; //Ry: Remaster score
        }
				else
        {
					bprint(" captured the RED flag!\n"); // red
          teamscr2 += 1;
        }
				other.items = other.items - (other.items & (IT_KEY1 | IT_KEY2));

        nextteamupdtime = time + 2; //Ry: Show a score update after scoring [09-05-2022]

				sound (other, CHAN_VOICE, "misc/flagcap.wav", 1, ATTN_NONE);

        // other gets another 10 frag bonus
        other.frags = other.frags + CTF_CAPTURE_BONUS;

				// Ok, let's do the player loop, hand out the bonuses
				p = find(world, classname, "player");
				while (p != world) {
					self = p;
          #ifdef CTF_ASSISTS
            if (self.team == other.team && self != other)
            	self.frags = self.frags + CTF_TEAM_BONUS;
          #endif
					if (self.team != other.team) {
						if (self.team == TEAM3)
							if (other.team == TEAM1)
								FilteredCenterPrint(self, CPRINT_GAMEMODE, "BLUE flag was captured!");
							else
								FilteredCenterPrint(self, CPRINT_GAMEMODE, "RED flag was captured!");
						else 
							FilteredCenterPrint(self, CPRINT_GAMEMODE, "Your flag was captured!");
						// reset the last_hurt_carrier variable in all enemy players, so that you don't get
						// bonuses for defending the flag carrier if the flag carrier has already
						// completed a capture
						self.ctf_lasthurtcarrier = -5;
					} else if (self.team == other.team) {
						// done to all players on the capturing team
						FilteredCenterPrint(self, CPRINT_GAMEMODE, "Your team captured the flag!");
            #ifdef CTF_ASSISTS
              // award extra points for capture assists
              if (self.ctf_lastreturnedflag + CTF_RETURN_FLAG_ASSIST_TIMEOUT > time) {
                bprint(self.netname);
                if (self.team == TEAM1)
                  bprint(" gets an assist for returning the RED flag!\n");
                else
                  bprint(" gets an assist for returning the BLUE flag!\n");
                self.frags = self.frags + CTF_RETURN_FLAG_ASSIST_BONUS;
              }
              if (self.ctf_lastfraggedcarrier + CTF_FRAG_CARRIER_ASSIST_TIMEOUT > time) {
                bprint(self.netname);
                bprint(" gets an assist for fragging the flag carrier!\n");
                self.frags = self.frags + CTF_FRAG_CARRIER_ASSIST_BONUS;
              }
            #endif
					}
					self.ctf_flags = self.ctf_flags - (self.ctf_flags &
						(CTF_FLAG_TEAM1 | CTF_FLAG_TEAM2));
					p = find(p, classname, "player");
				}
				// respawn flags
				TeamRegenFlags();
        #ifdef ENGINE_KEX
          SendCTFScoresUpdateAll(); //Ry: Remaster flag status update
        #endif
				return;
			}
			return; // its at home base already
		}	
		// hey, its not home.  return it by teleporting it back
		bprint(other.netname);
		if (other.team == TEAM1)
			bprint(" returned the RED flag!\n"); // red
		else
			bprint(" returned the BLUE flag!\n"); // blue
    #ifdef CTF_ASSISTS
      other.frags = other.frags + CTF_RECOVERY_BONUS;
      other.ctf_lastreturnedflag = time;
    #endif
    //Ry: Use a different channel for this [09-04-2022]
		sound (other, CHAN_POWERUP, self.noise1, 1, ATTN_NORM);
		TeamReturnFlag(self);
    #ifdef ENGINE_KEX
      SendCTFScoresUpdateAll(); //Ry: Remaster flag status update
    #endif
		return;
	}

	// if we have any flags, leave now
	if (other.ctf_flags & (CTF_FLAG_TEAM1 | CTF_FLAG_TEAM2))
		return;

	// hey, its not our flag, pick it up
	bprint(other.netname);
	if (self.team == TEAM1)
		bprint(" got the RED flag!\n"); // red
	else
		bprint(" got the BLUE flag!\n"); // blue
  #ifdef CTF_ASSISTS
    other.frags = other.frags + CTF_FLAG_BONUS;
  #endif

	// if in three team, messages are a little different
	if (other.team == TEAM3) {
		FilteredCenterPrint(other, CPRINT_GAMEMODE, "YOU GOT THE ENEMY FLAG\n\nRETURN IT TO THE OTHER BASE!");
	} else {
		FilteredCenterPrint(other, CPRINT_GAMEMODE, "YOU GOT THE ENEMY FLAG!\n\nRETURN TO BASE!");
	}
  //Ry: Use a different channel for this [09-04-2022]
	sound (other, CHAN_POWERUP, self.noise, 1, ATTN_NORM);

	if (self.team == TEAM1)
		other.ctf_flags = other.ctf_flags | CTF_FLAG_TEAM1;
	else
		other.ctf_flags = other.ctf_flags | CTF_FLAG_TEAM2;
	other.items = other.items | self.items;

	other.ctf_flagsince = time;

	// pick up the flag
	self.cnt = FLAG_CARRIED;
	self.movetype = MOVETYPE_NOCLIP;
	self.solid = SOLID_NOT;
	self.owner = other;

	// PGM Fix - 03/06/97 Made it work right in three team. 
	p = find(world, classname, "player");
	while (p != world) 
	{
		if (p != other) 
		{
			if (p.steam == self.team)
			{
				FilteredCenterPrint(p, CPRINT_GAMEMODE, "Your flag has been taken!");
			}
			else if (p.steam == other.team)
			{
				if (self.team == TEAM1)
					FilteredCenterPrint(p, CPRINT_GAMEMODE, "Your team has the RED flag!");	// Red Flag
				else
					FilteredCenterPrint(p, CPRINT_GAMEMODE, "Your team has the BLUE flag!");	// Blue Flag
			}
			else
			{
				if (self.team == TEAM1)
					if (other.steam == TEAM2)
						FilteredCenterPrint(p, CPRINT_GAMEMODE, "BLUE team has the RED flag!"); // Blue has red
					else // must be team3
						FilteredCenterPrint(p, CPRINT_GAMEMODE, "YELLOW team has the RED flag!"); // grey has red
				else
					if (other.steam == TEAM1)
						FilteredCenterPrint(p, CPRINT_GAMEMODE, "RED team has the BLUE flag!"); // red has blue
					else // must be team3
						FilteredCenterPrint(p, CPRINT_GAMEMODE, "YELLOW team has the BLUE flag!");// grey has blue
			}
		}
		p = find(p, classname, "player");
	}
  #ifdef ENGINE_KEX
    SendCTFScoresUpdateAll(); //Ry: Remaster flag status update
  #endif
};

// A flagbase was touched.  In one flag mode, this is how a capture is made.
// in three team mode, only team3 touches this.  In regular CTF, this is
// ignored
void() TeamFlagBaseTouch =
{
	local entity p, f;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
	if (other.team != other.steam)
		return; // something is fishy, somebody is playing with colors

	// Ok, first up, let's do it for one flag mode
	if (teamplay == TEAM_CTF_ONEFLAG) {
		// ok, if they guy touching it has the flag and this is his
		// base, capture!
		if (((self.team == TEAM1 && other.steam == TEAM2) || 
			(self.team == TEAM2 && other.steam == TEAM1)) && 
			(other.ctf_flags & CTF_FLAG_FLAG)) {
			// he just touched enemy base, capture it
			bprint(other.netname);
			bprint(" captured the flag!\n"); // blue
			other.items = other.items - (other.items & (IT_KEY1 | IT_KEY2));
			sound (other, CHAN_VOICE, "misc/flagcap.wav", 1, ATTN_NONE);
      
      if (other.team == TEAM1) //Ry: Remaster score
        teamscr1 += 1;
      else if (other.team == TEAM2)
        teamscr2 += 1;
      else
        teamscr3 += 1;

      nextteamupdtime = time + 2; //Ry: Show a score update after scoring [09-05-2022]

      // other gets another 10 frag bonus
      other.frags = other.frags + CTF_CAPTURE_BONUS;

			// Ok, let's do the player loop, hand out the bonuses
			p = find(world, classname, "player");
			while (p != world) {
				self = p;
        #ifdef CTF_ASSISTS
          if (self.team == other.team && self != other)
            self.frags = self.frags + CTF_TEAM_BONUS;
          if (self.team != other.team) {
            self.ctf_lasthurtcarrier = -5;
          } else if (self.team == other.team) {
            // award extra points for capture assists
            if (self.ctf_lastfraggedcarrier + CTF_FRAG_CARRIER_ASSIST_TIMEOUT > time) {
              bprint(self.netname);
              bprint(" gets an assist for fragging the flag carrier!\n");
              self.frags = self.frags + CTF_FRAG_CARRIER_ASSIST_BONUS;
            }
          }
        #endif
				self.ctf_flags = self.ctf_flags - (self.ctf_flags & CTF_FLAG_FLAG);
				p = find(p, classname, "player");
			}
			// respawn flags
			TeamRegenFlags();
      #ifdef ENGINE_KEX
        SendCTFScoresUpdateAll(); //Ry: Remaster flag status update
      #endif
			return;
		}
	}

	// in three team mode (TEAM_CTF_ALT) and we're on team3, see if we capture
	if (teamplay != TEAM_CTF_ALT || other.steam != TEAM3)
		return;

	if (((other.ctf_flags & CTF_FLAG_TEAM1) && (self.team == TEAM2)) ||
		((other.ctf_flags & CTF_FLAG_TEAM2) && (self.team == TEAM1))) {
		// third team captured

		bprint(other.netname);
		if (self.team == TEAM1)
    {
			bprint(" captured the BLUE flag!\n"); // blue
      if (other.team == TEAM3)
        teamscr3 += 1; //Ry: Remaster score
      else
        teamscr1 += 1;
    }
		else
    {
			bprint(" captured the RED flag!\n"); // red
      if (other.team == TEAM3)
        teamscr3 += 1;
      else
        teamscr2 += 1;
    }
		other.items = other.items - (other.items & (IT_KEY1 | IT_KEY2));

		sound (other, CHAN_VOICE, "misc/flagcap.wav", 1, ATTN_NONE);

    //other gets another 10 frag bonus
    other.frags = other.frags + CTF_ALT_CAPTURE_BONUS;

		// Ok, let's do the player loop, hand out the bonuses
		p = find(world, classname, "player");
		while (p != world) {
			self = p;
      #ifdef CTF_ASSISTS
			  if (self.team == other.team && self != other)
			  	self.frags = self.frags + CTF_ALT_TEAM_BONUS;
      #endif
			if (self.team != other.team) {
				if ((other.ctf_flags & CTF_FLAG_TEAM1) && self.team == TEAM1)
					FilteredCenterPrint(self, CPRINT_GAMEMODE, "Your flag was captured!");
				else if ((other.ctf_flags & CTF_FLAG_TEAM2) && self.team == TEAM2)
					FilteredCenterPrint(self, CPRINT_GAMEMODE, "The enemy flag was captured!");
				// reset the last_hurt_carrier variable in all enemy players, so that you don't get
				// bonuses for defending the flag carrier if the flag carrier has already
				// completed a capture
        #ifdef CTF_ASSISTS
          self.ctf_lasthurtcarrier = -5;
        #endif
			} else if (self.team == other.team) {
				// done to all players on the capturing team
				FilteredCenterPrint(self, CPRINT_GAMEMODE, "Your team captured the flag!");
			}
			p = find(p, classname, "player");
		}
		// respawn flags
		if (other.ctf_flags & CTF_FLAG_TEAM1) {
			f = find(world, classname, "item_flag_team1");
			if (f != world)
				RegenFlag(f);
		} else { // must be flag2
			f = find(world, classname, "item_flag_team2");
			if (f != world)
				RegenFlag(f);
		}
		other.ctf_flags = other.ctf_flags - (other.ctf_flags &
			(CTF_FLAG_TEAM1 | CTF_FLAG_TEAM2));
    #ifdef ENGINE_KEX
      SendCTFScoresUpdateAll(); //Ry: Remaster flag status update
    #endif
		return;
	}
};


void() TeamFlagThink =
{
	local entity e;
	local vector v;
	local float f;

	self.nextthink = time + 0.1;

	if (self.cnt == FLAG_AT_BASE)
		return; // just sitting around waiting to be picked up

	if (self.cnt == FLAG_DROPPED) {
		if (time - self.super_time > CTF_FLAG_RETURN_TIME)
    {
			TeamReturnFlag(self);
      #ifdef ENGINE_KEX
        SendCTFScoresUpdateAll(); //Ry: Remaster flag status update
      #endif
    }
		return;
	}

	if (self.cnt != FLAG_CARRIED)
		objerror("Flag in invalid state\n");

	e = self.owner;
	if (e.classname != "player" || e.deadflag) {
		TeamDropFlag(self);
		return;
	}

	if (teamplay == TEAM_CTF_ONEFLAG && !(e.ctf_flags & CTF_FLAG_FLAG)) {
		TeamDropFlag(self);
		return;
	}
	// must be TEAM_CTF or TEAM_CTF_ALT
	if ((!(e.ctf_flags & CTF_FLAG_TEAM1) && self.team == TEAM1) ||
		(!(e.ctf_flags & CTF_FLAG_TEAM2) && self.team == TEAM2)) {
		TeamDropFlag(self);
		return;
	}

	makevectors (e.angles);
	v = v_forward;
	v_z = (-1) * v_z; // reverse z component

	f = 14;
	if (self.owner.frame >= 29 && self.owner.frame <= 40) {
		if (self.owner.frame >= 29 && self.owner.frame <= 34) { //axpain
			if      (self.owner.frame == 29) f = f + 2; 
			else if (self.owner.frame == 30) f = f + 8;
			else if (self.owner.frame == 31) f = f + 12;
			else if (self.owner.frame == 32) f = f + 11;
			else if (self.owner.frame == 33) f = f + 10;
			else if (self.owner.frame == 34) f = f + 4;
		} else if (self.owner.frame >= 35 && self.owner.frame <= 40) { // pain
			if      (self.owner.frame == 35) f = f + 2; 
			else if (self.owner.frame == 36) f = f + 10;
			else if (self.owner.frame == 37) f = f + 10;
			else if (self.owner.frame == 38) f = f + 8;
			else if (self.owner.frame == 39) f = f + 4;
			else if (self.owner.frame == 40) f = f + 2;
		}
	} else if (self.owner.frame >= 103 && self.owner.frame <= 118) {
		if      (self.owner.frame >= 103 && self.owner.frame <= 104) f = f + 6;  //nailattack
		else if (self.owner.frame >= 105 && self.owner.frame <= 106) f = f + 6;  //light 
		else if (self.owner.frame >= 107 && self.owner.frame <= 112) f = f + 7;  //rocketattack
		else if (self.owner.frame >= 112 && self.owner.frame <= 118) f = f + 7;  //shotattack
	}
	self.origin = e.origin + '0 0 -16' - f*v + v_right * 22;
	self.angles = e.angles + '0 0 -45';
	setorigin (self, self.origin);
	self.nextthink = time + 0.01;
};

void() TeamFlagStatusReport =
{
	local entity flag1, flag2, p;
	local string n;

	if (!deathmatch)
		return;

	if (teamplay < TEAM_CTF || teamplay > TEAM_CTF_ALT)
  {
		//sprint(self, "Capture the Flag is not enabled.\n");
		return;
	}

  //Ry: These now use centerprint [09-06-2022]
	if (teamplay == TEAM_CTF_ONEFLAG) {
		flag1 = find (world, classname, "item_flag");
		if (flag1 == world)
      FilteredCenterPrint(self, CPRINT_GAMEMODE, "The flag is missing!");
		else if (flag1.cnt == FLAG_AT_BASE)
      FilteredCenterPrint(self, CPRINT_GAMEMODE, "The flag is at base!");
		else if (flag1.cnt == FLAG_DROPPED)
      FilteredCenterPrint(self, CPRINT_GAMEMODE, "The flag is lying about!");
		else if (flag1.cnt == FLAG_CARRIED) {
			if (flag1.owner == self)
        FilteredCenterPrint(self, CPRINT_GAMEMODE, "You have the flag!");
			else
        #ifdef ENGINE_KEX
          FilteredCenterPrint(self, CPRINT_GAMEMODE, "{} of the {} team has the flag!", flag1.owner.netname, GetCTFTeam(flag1.owner.steam));
        #else
          FilteredCenterPrint(self, CPRINT_GAMEMODE, flag1.owner.netname, " of the ", GetCTFTeam(flag1.owner.steam), " team has the flag!");
        #endif
		} else 
      FilteredCenterPrint(self,CPRINT_GAMEMODE, "The flag is screwed up!");
		return;
	}

  local string status1, status2, status3, status4;

	// normal CTF
	if (teamplay == TEAM_CTF) {
		// Find the flags at home base
		flag1 = find (world,classname, "item_flag_team1");
		flag2 = find (world,classname, "item_flag_team2");

		// If on team 2 switch meanings of flags
		if (self.team != TEAM1)
    {
			p = flag1;
			flag1 = flag2;
			flag2 = p;
		}

		if (flag1 != world && flag1.cnt == FLAG_CARRIED)
    {
      status1 = flag1.owner.netname;
      status2 = " has your flag.\n";
		}
    else
    {
      status1 = "Your flag is ";
			if (flag1 == world)
        status2 = "missing!\n";
			if (flag1.cnt == FLAG_AT_BASE)
        status2 = "in your base.\n";
			else if (flag1.cnt == FLAG_DROPPED)
        status2 = "lying about.\n";
			else
        status2 = "corrupt.\n";
		}

		if (flag2 != world && flag2.cnt == FLAG_CARRIED)
    {
			if (self == flag2.owner)
        status3 = "You have the enemy flag.";
			else
      {
        status3 = flag2.owner.netname;
        status4 = " has the enemy flag.";
      }
		}
    else
    {
      status3 = "The enemy flag is ";
			if (flag2 == world)
        status4 = "missing!";
			if (flag2.cnt == FLAG_AT_BASE)
        status4 = "in their base.";
			else if (flag2.cnt == FLAG_DROPPED)
        status4 = "lying about.";
			else
        status4 = "corrupt.";
		}
    #ifdef ENGINE_KEX
      FilteredCenterPrint(self, CPRINT_GAMEMODE, "{}{}{}{}", status1, status2, status3, status4);
    #else
      FilteredCenterPrint(self, CPRINT_GAMEMODE, status1, status2, status3, status4);
    #endif
	}

	// three team CTF  //Ry: [TODO] Change these over to centerprint
	if (teamplay == TEAM_CTF_ALT) {
		// Find the flags at home base
		flag1 = find (world,classname, "item_flag_team1");
		flag2 = find (world,classname, "item_flag_team2");

		if (flag1 != world && flag1.cnt == FLAG_CARRIED) {
			if (flag1.owner == self)
				sprint(self, "You have the RED flag!\n");
			else {
				sprint(self, flag1.owner.netname);
				n = GetCTFTeam(flag1.owner.steam);
				sprint(self, " of the ");
				sprint(self, n);
				sprint(self, " team has the RED flag.\n");
			}
		} else {
			if (self.steam == flag1.team)
				sprint(self, "Your flag is ");
			else
				sprint(self, "RED flag is ");
			if (flag1 == world)
				sprint(self, "missing!\n");
			if (flag1.cnt == FLAG_AT_BASE)
				sprint(self, "at base.\n");
			else if (flag1.cnt == FLAG_DROPPED)
				sprint(self, "lying about.\n");
			else
				sprint(self, " corrupt.\n");
		}

		if (flag2 != world && flag2.cnt == FLAG_CARRIED) {
			if (flag2.owner == self) 
				sprint(self, "You have the BLUE flag.\n");
			else {
				sprint(self, flag2.owner.netname);
				n = GetCTFTeam(flag2.owner.steam);
				sprint(self, " of the ");
				sprint(self, n);
				sprint(self, " team has the BLUE flag.\n");
			}
		} else {
			if (self.steam == flag1.team)
				sprint(self, "Your flag is ");
			else
				sprint(self, "BLUE flag is ");
			if (flag2 == world)
				sprint(self, "missing!\n");
			if (flag2.cnt == FLAG_AT_BASE)
				sprint(self, "at base.\n");
			else if (flag2.cnt == FLAG_DROPPED)
				sprint(self, "lying about.\n");
			else
				sprint(self, " corrupt.\n");
		}
	}
};

/////////////////////////////////////////////////////////////////////////

$cd id1/models/flag
$base base
$skin skin

void() place_flag =
{
	self.mdl = self.model;		// so it can be restored on respawn
	self.flags = FL_ITEM | FL_OBJECTIVE;		// make extra wide
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;	
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	self.think = TeamFlagThink;
	self.touch = TeamFlagTouch;
	self.nextthink = time + 0.1;
	self.cnt = FLAG_AT_BASE;
	self.mangle = self.angles;
	//self.effects = self.effects | EF_DIMLIGHT;
  if (self.itemeffect)
    SetLightEffect(self,self.itemeffect,TRUE);
	if (!droptofloor(0,0)) {
		dprint ("Flag fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
		return;
	}
	self.oldorigin = self.origin; // save for flag return
};

void(entity flg, string cname) place_flagbase = 
{
	local entity oself;

	teamplay = cvar("teamplay");

	oself = self;
	self = spawn();
	self.classname = cname;
	setorigin(self, flg.origin);
	self.angles = flg.angles;
	precache_model ("progs/ctfbase.mdl");
	setmodel (self, "progs/ctfbase.mdl");
	self.skin = flg.skin;
	self.team = flg.team;
//	setsize(self, '-8 -8 -4', '8 8 4');
	setsize(self, '-8 -8 0', '8 8 8');
	self.flags = FL_ITEM;		// make extra wide
	self.movetype = MOVETYPE_TOSS;	
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	if (teamplay == TEAM_CTF_ONEFLAG || teamplay == TEAM_CTF_ALT) {
		self.solid = SOLID_TRIGGER;
		self.touch = TeamFlagBaseTouch;
	} else
		self.solid = SOLID_NOT;
	if (!droptofloor(0,0)) {
		dprint ("Flagbase fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
		self = oself;
		return;
	}
	self = oself;
};

// ZOID Capture the flag
/*QUAKED item_flag_team1 (0 .5 .8) (-8 -8 -32) (8 8 24)
red team flag
Only appears in CTF teamplay

The flag waves 90 degrees off from the entity angle. If
you want the flag to point at 180, set then entity angle
to 90.
*/
void() item_flag_team1 =
{
	if (!deathmatch) {
		remove(self);
		return;
	}

	teamplay = cvar("teamplay");

	if (teamplay == TEAM_CTF_ONEFLAG) {
		precache_sound ("misc/flagtk.wav");		// flag taken
		precache_sound ("misc/flagcap.wav");	// flag capture
		self.skin = 0;
		self.team = TEAM1;
		place_flagbase(self, "item_flagbase_team1");
		remove(self);
		return;
	}

	if (teamplay == TEAM_CTF || teamplay == TEAM_CTF_ALT) {
		self.team = TEAM1;
		self.items = IT_KEY2;
		precache_model ("progs/ctfmodel.mdl");
		setmodel (self, "progs/ctfmodel.mdl");
		self.skin = 0;
		precache_sound ("misc/flagtk.wav");		// flag taken
		precache_sound ("misc/flagcap.wav");	// flag capture
		precache_sound ("misc/flagret.wav");	// flag return
		self.noise = "misc/flagtk.wav";
		self.noise1 = "misc/flagret.wav";
		setsize(self, '-16 -16 0', '16 16 74');
		self.nextthink = time + 0.2;	// items start after other solids
		self.think = place_flag;
    self.itemeffect = SET_EF_PENTA; //Ry: Red team light
		place_flagbase(self, "item_flagbase_team1");
	} else {
		remove(self); // not teamplay or deathmatch
	}
};

/*QUAKED item_flag_team2 (0 .5 .8) (-8 -8 -32) (8 8 24)
blue team flag
Only appears in CTF teamplay

The flag waves 90 degrees off from the entity angle. If
you want the flag to point at 180, set then entity angle
to 90.
*/
void() item_flag_team2 =
{
	if (!deathmatch) {
		remove(self);
		return;
	}

	teamplay = cvar("teamplay");

	if (teamplay == TEAM_CTF_ONEFLAG) {
		precache_sound ("misc/flagtk.wav");		// flag taken
		precache_sound ("misc/flagcap.wav");	// flag capture
		self.team = TEAM2;
		self.skin = 1;
		place_flagbase(self, "item_flagbase_team2");
		remove(self);
		return;
	}

	if (teamplay == TEAM_CTF || teamplay == TEAM_CTF_ALT) {
		self.team = TEAM2;
		self.items = IT_KEY1;
		precache_model ("progs/ctfmodel.mdl");
		setmodel (self, "progs/ctfmodel.mdl");
		self.skin = 1;
		precache_sound ("misc/flagtk.wav");		// flag taken
		precache_sound ("misc/flagcap.wav");	// flag capture
		precache_sound ("misc/flagret.wav");	// flag return
		self.noise = "misc/flagtk.wav";
		self.noise1 = "misc/flagret.wav";
		setsize(self, '-16 -16 0', '16 16 74');
		self.nextthink = time + 0.2;	// items start after other solids
		self.think = place_flag;
    self.itemeffect = SET_EF_QUAD; //Ry: Blue team light
		place_flagbase(self, "item_flagbase_team2");
	} else {
		remove(self); // not teamplay or deathmatch
	}
};

/*QUAKED item_flag (0 .5 .8) (-8 -8 -32) (8 8 24)
flag for OneTeam play.
Only appears in CTF teamplay

The flag waves 90 degrees off from the entity angle. If
you want the flag to point at 180, set then entity angle
to 90.
*/
void() item_flag = 
{
	if (cvar("teamplay") != TEAM_CTF_ONEFLAG) {
		remove(self);
		return;
	}
	self.team = 0; // no team
	self.items = IT_KEY1 | IT_KEY2;
//	precache_model ("progs/flag.mdl");
//	setmodel (self, "progs/flag.mdl");
	precache_model ("progs/ctfmodel.mdl");		// PGM 01/18/97
	setmodel (self, "progs/ctfmodel.mdl");	// PGM 01/18/97
	self.skin = 2;
	precache_sound ("misc/flagtk.wav");		// flag taken
	precache_sound ("misc/flagcap.wav");	// flag capture
	precache_sound ("misc/flagret.wav");	// flag return
	self.noise = "misc/flagtk.wav";
	self.noise1 = "misc/flagret.wav";
	setsize(self, '-16 -16 0', '16 16 74');
	self.nextthink = time + 0.2;	// items start after other solids
	self.think = place_flag;
  self.itemeffect = SET_EF_DIM; //Ry: Third team light
	place_flagbase(self, "item_flagbase");
};

/*QUAKED info_player_team1 (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for CTF games team 1.
*/
void() info_player_team1 = 
{
};

/*QUAKED info_player_team2 (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for CTF games team 2.
*/
void() info_player_team2 = 
{
};

void() TeamSetUpdate = 
{
	nextteamupdtime = time + CTF_UPDATE_TIME;
};

//Ry: Modified this whole function to use the saved team score values [09-05-2022]
void() TeamCheckUpdate =
{
	local string ts1, ts2, ts3;

	if (nextteamupdtime > time || teamplay < 1 || !deathmatch)
		return;

	TeamSetUpdate();

	ts1 = GetCTFTeam(TEAM1);
	ts2 = GetCTFTeam(TEAM2);
	ts3 = GetCTFTeam(TEAM3);

	if (teamplay >= TEAM_CTF && teamplay <= TEAM_CTF_ONEFLAG)
  {
    if (teamplay == TEAM_CTF || teamplay == TEAM_CTF_ONEFLAG)
    {
      if (teamscr1 > teamscr2) 
      {
				bprint(ts1);
				bprint(" team is leading with ");
				bprint(ftos(teamscr1));
      }
      else if (teamscr1 < teamscr2)
      {
				bprint(ts2);
				bprint(" team is leading with ");
				bprint(ftos(teamscr2));
      }
      else
      {
				bprint("Teams are tied with ");
				bprint(ftos(teamscr1));
      }
      bprint(" points!\n");
		}
    else if (teamplay == TEAM_CTF_ALT)
    {
			if (teamscr1 > teamscr2 && teamscr1 > teamscr3) {
				bprint(ts1);
				bprint(" team is leading with ");
				bprint(ftos(teamscr1));
			}
      else if (teamscr2 > teamscr1 && teamscr2 > teamscr3)
      {
				bprint(ts2);
				bprint(" team is leading with ");
				bprint(ftos(teamscr2));
			}
      else if (teamscr3 > teamscr1 && teamscr3 > teamscr2)
      {
				bprint(ts3);
				bprint(" team is leading with ");
				bprint(ftos(teamscr3));
			}
      else if (teamscr1 == teamscr2)
      {
				bprint(ts1);
				bprint(" and ");
				bprint(ts2);
				bprint(" teams are tied with ");
				bprint(ftos(teamscr1));
			}
      else if (teamscr2 == teamscr3)
      {
				bprint(ts2);
				bprint(" and ");
				bprint(ts3);
				bprint(" teams are tied with ");
				bprint(ftos(teamscr2));
			}
      else if (teamscr3 == teamscr1)
      {
				bprint(ts1);
				bprint(" and ");
				bprint(ts3);
				bprint(" teams are tied with ");
				bprint(ftos(teamscr1));
			}
      else
      {
				bprint("All teams are tied with ");
				bprint(ftos(teamscr1));
			}
      bprint(" points!\n");
		}
	}
};

/*QUAKED func_ctf_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
Only appears in CTF teamplay
*/
void() func_ctf_wall =
{
	teamplay = cvar("teamplay");
	if (teamplay == TEAM_CTF || teamplay == TEAM_CTF_ONEFLAG ||
		teamplay == TEAM_CTF_ALT) {
		self.angles = '0 0 0';
		self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
		self.solid = SOLID_BSP;
		setmodel (self, self.model);
	} else
		remove(self);
};

