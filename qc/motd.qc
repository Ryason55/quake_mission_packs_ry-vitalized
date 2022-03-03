// Ry: MOTD functions lifted from Dissolution to fit my purposes

.float motd_time;
.float motd_count;

//Ry: New func, located in client.qc
void(entity player, float type, string message1, string message2 = "", string message3 = "", string message4 = "", string message5 = "", string message6 = "") FilteredCenterPrint;

void() MOTD =
{
	if (self.motd_count < 3) { //was 5
		self.motd_time = time + 1;
		self.motd_count = self.motd_count + 1;
    if (deathmatch)
      FilteredCenterPrint(self, CPRINT_MOTD, "Modded Armagon Deathmatch by Ryason55\nFeatures Ring Outs, powerup drops, weapon respawns, and footstep sounds");
    else if (coop)
      FilteredCenterPrint(self, CPRINT_MOTD, "Modded Armagon Co-op by Ryason55");
		return;
	}
	self.motd_time = 0;
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

