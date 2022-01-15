// Ry: MOTD functions lifted from Dissolution to fit my purposes

.float motd_time;
.float motd_count;

void() MOTD =
{
	local string tp;
	
	if (self.motd_count < 3) { //was 5
		self.motd_time = time + 1;
		self.motd_count = self.motd_count + 1;
    if (deathmatch)
      centerprint(self, "Modded Armagon Deathmatch by Ryason55\nFeatures Ring Outs, powerup drops, weapon respawns, and footstep sounds");
    else if (coop)
      centerprint(self, "Modded Armagon Co-op by Ryason55");
		return;
	}
	self.motd_time = 0;
};

void() CheckMOTD =
{
//	if (self.motd_time && self.motd_time < time)
	if (self.motd_time)
	{ 
		if(self.motd_time < time)
			MOTD();
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

