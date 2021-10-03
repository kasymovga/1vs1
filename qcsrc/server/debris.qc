float sv_breakable_debris;
.float debrismovetype;
.float debrissolid;
.vector debrisvelocity;
.vector debrisvelocityjitter;
.vector debrisavelocityjitter;
.float debristime;
.float debristimejitter;
.float debrisfadetime;
.float debrisdamageforcescale;
.float debrisskin;

void(void) debris_setup {
	if not(self.debrismovetype) self.debrismovetype = MOVETYPE_BOUNCE;
	if not(self.debrissolid) self.debrissolid = SOLID_NOT;
	if (self.debrisvelocity == '0 0 0') self.debrisvelocity = '0 0 140';
	if (self.debrisvelocityjitter == '0 0 0') self.debrisvelocityjitter = '70 70 70';
	if (self.debrisavelocityjitter == '0 0 0') self.debrisavelocityjitter = '600 600 600';
	if not(self.debristime) self.debristime = 3.5;
	if not(self.debristimejitter) self.debristimejitter = 2.5;
	if not(self.debrisfadetime) self.debrisfadetime = 1;
}

void(void) debris_init {
	float n, i;
	entity e = NULL;
	CVAR_CACHE(sv_breakable_debris);
	debris_setup();
	n = tokenize_console(self.debris);
	string s;
	var void(void) item_spawnfunc;
	entity oldself = self;
	for(i = 0; i < n; ++i) {
		s = argv(i);
		if ((item_spawnfunc = item_spawnfunc_for(s))) {
			self = spawn();
			item_spawnfunc(); //for precache
			remove(self);
		} else if ((e = weapon_info_by_name(s))) {
			e.weapon_func(WR_PRECACHE);
		} else
			precache_model(s);
	}
	self = oldself;
}

void(string debrisname, vector force) debris_launch {
	entity dbr;
	var void(void) item_spawnfunc = NULL;
	dbr = spawn();
	entity e = NULL;
	float haveslash = (strstrofs(debrisname, "/", 0) >= 0);
	if (!haveslash && (item_spawnfunc = item_spawnfunc_for(debrisname))) {
		setorigin(dbr, (self.absmin + self.absmax) * 0.5);
		entity oldself = self;
		self = dbr;
		self.classname = "droppeditem";
		item_spawnfunc();
		self = oldself;
	} else if (!haveslash && (e = weapon_info_by_name(debrisname))) {
		setorigin(dbr, (self.absmin + self.absmax) * 0.5);
		entity oldself = self;
		self = dbr;
		self.classname = "droppedweapon";
		weapon_defaultspawnfunc(e.weapon);
		self = oldself;
	} else if (sv_breakable_debris) {
		setorigin(dbr, self.absmin
				+ '1 0 0' * random() * (self.absmax_x - self.absmin_x)
				+ '0 1 0' * random() * (self.absmax_y - self.absmin_y)
				+ '0 0 1' * random() * (self.absmax_z - self.absmin_z));
		setmodel(dbr, debrisname );
		dbr.skin = self.debrisskin;
		dbr.colormap = self.colormap; // inherit team colors
		dbr.owner = self; // do not be affected by our own explosion
		dbr.movetype = self.debrismovetype;
		dbr.solid = self.debrissolid;
		if (dbr.solid != SOLID_BSP) // SOLID_BSP has exact collision, MAYBE this works? TODO check this out
			setsize(dbr, '0 0 0', '0 0 0'); // needed for performance, until engine can deal better with it

		dbr.avelocity_x = random() * self.debrisavelocityjitter_x;
		dbr.avelocity_y = random() * self.debrisavelocityjitter_y;
		dbr.avelocity_z = random() * self.debrisavelocityjitter_z;
		dbr.damageforcescale = self.debrisdamageforcescale;
		if (dbr.damageforcescale)
			dbr.takedamage = DAMAGE_YES;

		dbr.reset = stdproc_remove;
		entity_fade_setup(dbr, time + self.debristime + random_2() * self.debristimejitter, self.debrisfadetime);
	}
	dbr.velocity_x = self.debrisvelocity_x + self.debrisvelocityjitter_x * random_2();
	dbr.velocity_y = self.debrisvelocity_y + self.debrisvelocityjitter_y * random_2();
	dbr.velocity_z = self.debrisvelocity_z + self.debrisvelocityjitter_z * random_2();
	dbr.velocity = dbr.velocity + force * self.debrisdamageforcescale;
}

void(vector force) debris_throw {
	float i, n;
	n = tokenize_console(self.debris);
	for (i = 0; i < n; ++i)
		debris_launch(argv(i), force);
}
