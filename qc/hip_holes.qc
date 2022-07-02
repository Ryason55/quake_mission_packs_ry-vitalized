/* Bullet holes QuickC program
   By Jim Dose'  11/20/96
   Copyright (c)1996 Hipnotic Interactive, Inc.
   All rights reserved.
   Distributed (unsupported) on 3.12.97
*/

/*QUAKED wallsprite (0 1 0) (-8 -8 -8) (8 8 8)
Places a sprite on a wall.  Angles should be opposite of face.

"model" sprite to place on wall.  Default is "progs/s_blood1.spr".
*/
void() wallsprite =
{
  if ( !self.model )
  {
    self.model = "progs/s_blood1.spr";
  }

  precache_model( self.model );
  setmodel (self, self.model );

  // QuakeEd doesn't save up and down angles properly.
  if (self.angles == '0 -1 0')
    self.angles = '-90 0 0';
	else if (self.angles == '0 -2 0')
    self.angles = '90 0 0';

  // Pull the sprite away from the wall slightly to
  // get rid of z sort errors.
  makevectors(self.angles);
  setorigin( self, self.origin - ( v_forward * 0.2 ) );
	makestatic (self);
};

void() InitBulletHoles =
{
  local float count = 10;
  local entity new, prev;

  precache_model ("progs/s_bullet.spr");

  while (count > 0) //Ry: Set these up similar to Bodyque; The original method was crash-prone with Gremlins around, this seems more effecient in general
  {
    new = spawn();
    new.classname = "bullethole";
    new.owner = prev;
    if (!bulletholes)
      bulletholes = new;
    prev = new;
    count = count - 1;
  }
  bulletholes.owner = prev;
};

void() remove_bullethole =
{
  setmodel(self, ""); //Ry: Move way out of bounds so clients don't have to process it
  self.origin_z = self.origin_z + 1000;
  setorigin(self,self.origin);
};

void( vector pos ) placebullethole =
{
  local vector norm;

  norm = trace_plane_normal;
  norm_x = 0 - norm_x;
  norm_y = 0 - norm_y;
  bulletholes.angles = vectoangles( norm );
  makevectors(self.angles);
  setorigin( bulletholes, pos - ( v_forward * 0.2 ) );
  setmodel(bulletholes, "progs/s_bullet.spr" );
  setsize (bulletholes, '0 0 0', '0 0 0');

  bulletholes.think = remove_bullethole;
  bulletholes.nextthink = time + 300;

  bulletholes = bulletholes.owner;
};
