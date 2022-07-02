// Ry: MOTD functions lifted from Dissolution to fit my purposes

.float motd_time;
.float motd_count;
.float motd_cmd;

//Ry: New sub, located in ry_subs.qc
void(entity player, float type, string message1, string message2 = "", string message3 = "", string message4 = "", string message5 = "", string message6 = "") FilteredCenterPrint;

void() MOTD =
{
  local string thismod, mode, features1, features2, features3;
  if (!self.motd_cmd)
  {
    stuffcmd(self,"RyModJoin\n"); //Ry: If the client has stuffcmd allowed, call this customizable alias function
    self.motd_cmd = TRUE;
  }
	if (self.motd_count < 3) { //was 5
		self.motd_time = time + 1;
		self.motd_count = self.motd_count + 1;
    thismod = "Armagon Ry-vitalized V2.0";
    if (deathmatch)
    {
      mode = " Deathmatch";
      features1 = "\nFeatures Ring Outs, powerup drops, ";

      if (footsteps)
      {
        if (exitwarp)
          features2 = "exit warp, footsteps, ";
        else
          features2 = "footsteps, ";
      }
      else if (exitwarp)
      {
        features2 = "exit warp, ";
      }

      /*if (wide_lightning)
      {
        if (wide_spikes)
        {
          features3 = "wide shaft/spikes, ";
        }
        else
        {
          features3 = "wide shaft, ";
        }
      }
      else if (wide_spikes)
      {
        features3 = "wide spikes, ";
      }
      if (features3 && !features2)
      {
        features2 = features3;
        features3 = string_null;
      }*/

      if (!features2)
        features2 = "and various other changes";
      else
        features3 = "and various other changes";
    }
    else if (horde)
    {
      mode = " Horde Mode";
    }
    else if (coop)
    {
      mode = " Co-op";
    }
    
    if (coop) //Ry: Show Difficulty and Friendly Fire status to players on join in Co-op modes
    {
      if ( horde || (world.model != "maps/start.bsp") )
      {
        if (skill == 0)
          features1 = "\nEasy difficulty";
        else if (skill == 1)
          features1 = "\nNormal difficulty";
        else if (skill == 2)
          features1 = "\nHard difficulty";
        else if (skill == 3)
          features1 = "\nNightmare difficulty";
        if (!teamplay)
          features2 = ", FF Enabled";
      }
      else if (!teamplay)
        features1 = "\nFF Enabled";
    }
    
    FilteredCenterPrint(self, CPRINT_MOTD,thismod,mode,features1,features2,features3);
		return;
	}
	self.motd_time = 0;
  if ((self.mapsfinished < 1) && (self.playerprobe == FALSE))
  {
    sprint(self,"Toggle player name display by double-tapping [Axe]\n");
    sprint(self,"(Do not use with Accessibility options)\n");
  }
};

void() CheckMOTD =
{
//	if (self.motd_time && self.motd_time < time)
	if (self.motd_time)
	{ 
    if (!coop || self.mapsfinished < 1) //Ry: In Co-op, only show the message on the first map
    {
      if(self.motd_time < time)
        MOTD();
    }
    else
      self.motd_time = 0;
      
	}
};

void() SetMOTD = 
{
  if (deathmatch || coop)
  {
    self.motd_time = time + 3;
    if ( teamplay == 3 || coop )
      self.motd_count = 2;
    else
      self.motd_count = 0;
  }
};

