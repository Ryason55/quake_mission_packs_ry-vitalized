// Ry: MOTD functions lifted from Dissolution to fit my purposes

void() MOTD =
{
  local string mode, info1, info2;
	if (self.motd_count > 0)
  {
		self.motd_time = time + 1;
		self.motd_count -= 1;
    if (deathmatch)
    {
      mode = "\nDeathmatch";
      #ifdef GAME_ROGUE
        if (dmatchtag == 2)
          mode = "\nDeathmatch Tag";
        if (teamplay >= TEAM_CTF && teamplay <= TEAM_CTF_ALT)
        {
          if (teamplay == TEAM_CTF_ALT)
            mode = "\nThree Team Capture the Flag";
          else if (teamplay == TEAM_CTF_ONEFLAG)
            mode = "\nOne Flag Capture the Flag";
          else
            mode = "\nCapture the Flag";
          if (self.teamselecttime)
          {
             //Ry: Used if the engine doesn't support prompts
            if (teamplay == TEAM_CTF_ALT)
              info1 = "\n\nPress 1 for RED team\nPress 2 for BLUE team\nPress 3 for YELLOW team\nPress JUMP for automatic team";
            else
              info1 = "\n\nPress 1 for RED team\nPress 2 for BLUE team\nPress JUMP for automatic team";
          }
          else
          {
            if (self.steam == TEAM1)
              info1 = "\n\nYou are on the RED team";
            else if (self.steam == TEAM2)
              info1 = "\n\nYou are on the BLUE team";
            else if (self.steam == TEAM3)
              info1 = "\n\nYou are on the YELLOW team";
          }
        }
        else
        {
          if (grappleenabled)
            if (runespawn)
              info1 = "\n\nGrappling Hook enabled\nRunes enabled";
            else
              info1 = "\n\nGrappling Hook enabled";
          else if (runespawn)
            info1 = "\n\nRunes enabled";
        }
      #endif
    }
    else if (coop || horde) //Ry: Show Difficulty and Friendly Fire status to players on join in Co-op modes
    {
      if (horde)
        mode = " Horde Mode";
      else
        mode = " Co-op";
      //Ry: Don't show difficulty on START map, since it's yet to be selected
      if ( horde || (world.model != "maps/start.bsp") )
      {
        if (skill == 0)
          info1 = "\nEasy difficulty";
        else if (skill == 1)
          info1 = "\nNormal difficulty";
        else if (skill == 2)
          info1 = "\nHard difficulty";
        else if (skill == 3)
        {
          if (copper_nightmare)
            info1 = "\nCopper Nightmare difficulty";
          else
            info1 = "\nNightmare difficulty";
        }
      }
      if (horde && !horde_ent) //Ry: Warning message just in case [2022-12-27]
      {
        info2 = "\n\nMap doesn't support Horde Mode!";
      }
      else
      {
        if (fastmonsters)
          if (!teamplay)
            info2 = "\n\nFast Monsters enabled\nFriendly Fire enabled";
          else
            info2 = "\n\nFast Monsters enabled";
        else if (!teamplay)
          info2 = "\n\nFriendly Fire enabled";
      }
    }

    #ifdef ENGINE_KEX
      if (info1)
        FilteredCenterPrint(self, motd_priority, "{}{}{}{}", THISMOD, mode, info1, info2);
      else if (info2)
        FilteredCenterPrint(self, motd_priority, "{}{}{}", THISMOD, mode, info2);
      else
        FilteredCenterPrint(self, motd_priority, "{}{}", THISMOD, mode);
    #else
      if (info1)
        FilteredCenterPrint(self, motd_priority, THISMOD, mode, info1, info2);
      else
        FilteredCenterPrint(self, motd_priority, THISMOD, mode, info2);
    #endif

    if (self.motd_count <= 0)
      self.motd_time = 0;
		return;
	}
};

void() CheckMOTD =
{
	if (self.motd_time && self.motd_count)
	{ 
    if (!coop || horde || self.mapsfinished < 1) //Ry: In Co-op, only show the message on the first map
    {
      #if defined(ENGINE_KEX) || defined(GAME_ROGUE)
        if (!self.motd_cmd && (self.motd_time <= (time + 2.9)))
        {
          #ifdef ENGINE_KEX
            stuffcmd(self,"RyModJoin\n"); //Ry: If the client has stuffcmd allowed, call this customizable alias function
          #endif
          #ifdef GAME_ROGUE
            SendTeamplayValue(self);
          #endif
          self.motd_cmd = TRUE;
        }
      #endif
      if (self.motd_time < time)
        MOTD();
    }
    else
      self.motd_time = 0;
	}
};

void() SetMOTD = 
{
  if (deathmatch || coop || horde)
  {
    self.motd_time = time + 3;
    #ifdef ENGINE_KEX
      self.motd_count = 2;
    #else
      self.motd_count = 3;
    #endif
  }
};

