// LAVA Weapon Routines

/*
===============
launch_lava_spike

Used for both the player and the ogre
===============
*/
void(vector org, vector dir) launch_lava_spike =
{
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);
	
	newmis.touch = lavaspike_touch;
	newmis.classname = "lava_spike";
	newmis.think = RemoveMissile;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/lspike.mdl");	
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (newmis, org);

  //Ry: Make lava nails glow [09-17-2022]
  SetLightEffect(newmis,SET_EF_CANDLE,TRUE);

	newmis.velocity = dir * ProjectileSpeed(self,1000);
};

void() W_FireSuperLavaSpikes =
{
	local vector	dir;
	
	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_lava_nails = self.ammo_lava_nails - 2;
	UpdateAmmoCounts (self);
	
	dir = aim (self, 1000);
	launch_lava_spike (self.origin + '0 0 16', dir);
  CreateMissileField(newmis,4); //Ry: Give bigger hitbox against players in Deathmatch
	newmis.touch = superlavaspike_touch;

//	setmodel (newmis, "progs/lspike.mdl");			

	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	self.punchangle_x = -2;
};

void(float ox) W_FireLavaSpikes =
{
	local vector	dir;
	
	makevectors (self.v_angle);
	
	if (self.ammo_lava_nails >= 2 && self.weapon == IT_LAVA_SUPER_NAILGUN)
	{
		W_FireSuperLavaSpikes ();
		return;
	}

	if (self.ammo_lava_nails < 1)
	{
		sprint (self, "Out of Lava Nails\n");
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_lava_nails = self.ammo_lava_nails - 1;
	UpdateAmmoCounts (self);
	
	dir = aim (self, 1000);
	launch_lava_spike (self.origin + '0 0 16' + v_right*ox, dir);
  CreateMissileField(newmis,6); //Ry: Give bigger hitbox against players in Deathmatch

	self.punchangle_x = -2;
};

// =============== Lava Spike Touch Routines

void() lavaspike_touch =
{
  local float old_armortype;
  local float old_armorvalue;
  local float old_armormask;

	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		RemoveMissile();
		return;
	}

  //Ry: Don't show bleeding effects against these guys [09-26-2022]
  if ( other.classname == "monster_lava_man")
  {
		RemoveMissile();
		return;
  }
	
// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (9);
		if(other.classname == "player")
		{
			old_armortype = other.armortype;
			old_armorvalue = other.armorvalue;
			old_armormask = other.items2 & (IT2_ARMOR1|IT2_ARMOR2|IT2_ARMOR3);
			other.armortype = 0;
			other.armorvalue = 0;
			T_Damage (other, self, self.owner, 9);
			other.armortype = old_armortype;
			other.armorvalue = old_armorvalue;
			other.items2 = other.items2 | old_armormask;
		}
		else		// is a monster
		{
			T_Damage (other, self, self.owner, 15);
		}
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);

		WriteByte (MSG_BROADCAST, TE_SPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	RemoveMissile();

};

void() superlavaspike_touch =
{
  local float old_armortype;

	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		RemoveMissile();
		return;
	}

  //Ry: Don't show bleeding effects against these guys [09-26-2022]
  if ( other.classname == "monster_lava_man")
  {
		RemoveMissile();
		return;
  }

// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (18);
		
		// halve the effectiveness of the armor for players..
		if(other.classname == "player")
		{
			// save the old armor values...
			old_armortype = other.armortype;
			other.armortype = other.armortype * 0.5;
			T_Damage (other, self, self.owner, 18);
			
			// if the damage didn't wipe out the armor, armortype 
			if(other.armortype != 0)
			{
				other.armortype = old_armortype;
			}
		}
		else		// is a monster, do 50% more damage
		{
			T_Damage (other, self, self.owner, 30);
		}
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	RemoveMissile();

};
