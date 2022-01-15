#define ShowModName 1
#define ModName "Ry Mod"


#define FirstDefineMap(_bspname,_maptitle) if(mapname == ##_bspname && title == ##_maptitle) { return ##_maptitle" ("ModName")"; }
#define DefineMap(_bspname,_maptitle) else FirstDefineMap(_bspname,_maptitle)
#define OverrideDefineMap(_bspname,_maptitle) else if(mapname == ##_bspname) { return ##_maptitle" ("ModName")"; }

string(string title) GetMapName =
{
  #if ShowModName == 1

  // Id1 maps
  FirstDefineMap("base32b","Base 32")
  DefineMap("death32c","Death 32")
  DefineMap("dm1","Place of Two Deaths")
  DefineMap("dm2","Claustrophobopolis")
  DefineMap("dm3","The Abandoned Base")
  DefineMap("dm4","The Bad Place")
  DefineMap("dm5","The Cistern")
  DefineMap("dm6","The Dark Zone")
  DefineMap("dm7","The Edge")
  DefineMap("dm8","Acrophobia")
  DefineMap("e1m1","The Slipgate Complex")
  DefineMap("e1m2","Castle of the Damned")
  DefineMap("e1m3","The Necropolis")
  DefineMap("e1m4","The Grisly Grotto")
  DefineMap("e1m5","Gloom Keep")
  DefineMap("e1m6","The Door To Chthon")
  DefineMap("e1m7","The House of Chthon")
  DefineMap("e1m8","Ziggurat Vertigo")
  DefineMap("e2m1","The Installation")
  DefineMap("e2m2","The Ogre Citadel")
  DefineMap("e2m3","The Crypt of Decay")
  DefineMap("e2m4","The Ebon Fortress")
  DefineMap("e2m5","The Wizard's Manse")
  DefineMap("e2m6","The Dismal Oubliette")
  DefineMap("e2m7","The Underearth")
  DefineMap("e3m1","Termination Central")
  DefineMap("e3m2","The Vaults of Zin")
  DefineMap("e3m3","The Tomb of Terror")
  DefineMap("e3m4","Satan's Dark Delight")
  DefineMap("e3m5","The Wind Tunnels")
  DefineMap("e3m6","Chambers of Torment")
  DefineMap("e3m7","The Haunted Halls")
  DefineMap("e4m1","The Sewage System")
  DefineMap("e4m2","The Tower of Despair")
  DefineMap("e4m3","The Elder God Shrine")
  DefineMap("e4m4","The Palace of Hate")
  DefineMap("e4m5","Hell's Atrium")
  DefineMap("e4m6","The Pain Maze")
  DefineMap("e4m7","Azure Agony")
  DefineMap("e4m8","The Nameless City")
  DefineMap("end","Shub-Niggurath's Pit")

	OverrideDefineMap("test/mals_combatbox","Mal's Combatbox")
	OverrideDefineMap("test/test_shadow","Shadow's Arena")
	OverrideDefineMap("test/test_aiming","Box Arena")
	OverrideDefineMap("test/test_obstacles","Obstacle Course")
  
  // Hipnotic maps
  DefineMap("start","Command HQ")
  DefineMap("hip1m1","The Pumping Station")
  DefineMap("hip1m2","Storage Facility")
  DefineMap("hip1m3","The Lost Mine")
  DefineMap("hip1m4","Research Facility")
  DefineMap("hip1m5","Military Complex")
  DefineMap("hip2m1","Ancient Realms")
  DefineMap("hip2m2","The Black Cathedral")
  DefineMap("hip2m3","The Catacombs")
  DefineMap("hip2m4","The Crypt")
  DefineMap("hip2m5","Mortum's Keep")
  DefineMap("hip2m6","The Gremlin's Domain")
  DefineMap("hip3m1","Tur Torment")
  DefineMap("hip3m2","Pandemonium")
  DefineMap("hip3m3","Limbo")
  DefineMap("hipdm1","The Edge of Oblivion")
  DefineMap("hip3m4","The Gauntlet")
  DefineMap("hipend","Armagon's Lair")

    #endif

	// Default
	return title;

}