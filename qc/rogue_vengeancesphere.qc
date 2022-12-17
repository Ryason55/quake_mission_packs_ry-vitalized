// vengeance sphere

// ==============================
// sphere_impact
// ==============================
void() sphere_impact =
{
	if (other.health)
	{
    T_Damage (other, self, self.owner, 1000 ); //Ry: Indicate the player as the attacker now [09-04-2022]
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact
    T_RadiusDamage (self, self.owner, 300, other);

//	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

void(entity ownerEntity) sphere_remove =
{
	local entity theSphere;
	
	theSphere = find(world, classname, "Vengeance");
	while(theSphere != world)
	{
		if(theSphere.owner == self)
		{
			bprint ( theSphere.owner.netname );
			bprint ( " is denied Vengeance\n" );
			remove (theSphere);
			theSphere = find(world, classname, "Vengeance");
		}
		else
			theSphere = find(theSphere, classname, "Vengeance");
	}
};

// ==============================
// sphere_attack
// ==============================
void() sphere_attack =
{
	self.solid = SOLID_TRIGGER;
	self.touch = sphere_impact;

	if (self.enemy.health < 1)
	{
		sprint ( self.owner, "You are denied Vengeance\n");
		remove(self);
		return;
	}

	ai_track(self.enemy, 650);
	self.nextthink = time + 0.1;
  self.think = sphere_attack; 
};

// ==============================
// sphere_think
// ==============================
void() sphere_think =
{
	if (self.shieldSoundTime < time)
	{
		sound ( self, CHAN_VOICE, "sphere/sphere.wav", 1, ATTN_NORM);
		self.shieldSoundTime = time + 4;
	}
	
	if (time > self.delay)
	{
		if (self.owner.items2 & IT2_V_SPHERE)
			self.owner.items2 = self.owner.items2 - IT2_V_SPHERE;
		sprint ( self.owner, "Vengeance Sphere Lost\n");
		remove (self);
		return;
	}

	if (self.owner.health < 1)
	{
		if (self.owner.items2 & IT2_V_SPHERE)
			self.owner.items2 = self.owner.items2 - IT2_V_SPHERE;
		if ( self.owner.enemy.classname == "player" )
		{
			self.enemy = self.owner.enemy;
			sphere_attack();
			return;
		}
		if ( self.owner.enemy.owner.classname == "player")
		{
			self.enemy = self.owner.enemy.owner;
			sphere_attack();
			return;
		}
		remove (self);
		return;
	}
	
	ai_orbit(self.owner, 16, '0 0 48');
	
  self.think = sphere_think;
  self.nextthink = time + 0.1;
};

// ==============================
// sphere_spawn
// ==============================
void() sphere_spawn =
{
  local   entity missile;

  missile = spawn();
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_NOT;
  missile.classname = "Vengeance";
  missile.owner = other;
  missile.weapon = 0;
  missile.delay = time + 30;
  setmodel (missile, "progs/sphere.mdl");
  setsize (missile, '0 0 0', '0 0 0');     
  setorigin (missile, self.origin );
	missile.avelocity = '40 40 40';
  missile.think = sphere_think;
  missile.nextthink = time + 0.1;
  SetLightEffect(missile,SET_EF_CANDLE,TRUE); //Ry: Glow
};

/*QUAKED item_sphere (0 0 1) (-8 -8 -8) (8 8 8) ?
The Vengeance Sphere. DEATHMATCH ONLY.
*/
void() item_sphere =
{
  if (!deathmatch)
  {
    remove(self);
    return;
  }

  precache_model ("progs/sphere.mdl");
	precache_sound ("sphere/sphere.wav");

	self.noise = "sphere/sphere.wav";
	self.netname = "Vengeance Sphere";
  self.touch = newitems_touch;

  self.respawntime = 180; //Ry: Respawn time defined here now
  self.itemeffect = SET_EF_CANDLE; //Ry: New light for powerup

  setmodel (self, "progs/sphere.mdl");
  setsize (self, '-16 -16 -8', '16 16 48'); //Ry: Now the same size as other items
	self.avelocity = '40 40 40';
	StartItem ();
};