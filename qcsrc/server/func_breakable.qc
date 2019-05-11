float sv_breakable_debris;
.entity sprite;

.float dmg;
.float dmg_edge;
.float dmg_radius;
.float dmg_force;
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
.float napalm_count;
.float napalm_color;

.string mdl_dead; // or "" to hide when broken
.string debris; // space separated list of debris models
// other fields:
//   mdl = particle effect name
//   count = particle effect multiplier
//   targetname = target to trigger to unbreak the model
//   target = targets to trigger when broken
//   health = amount of damage it can take
//   spawnflags:
//     1 = start disabled (needs to be triggered to activate)
//     2 = indicate damage
// notes:
//   for mdl_dead to work, origin must be set (using a common/origin brush).
//   Otherwise mdl_dead will be displayed at the map origin, and nobody would
//   want that!

.vector mins_save, maxs_save;

void func_breakable_damage(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force);

//
// func_breakable
// - basically func_assault_destructible for general gameplay use
//
void LaunchDebris (string debrisname, vector force) =
{
	local	entity dbr;

	dbr = spawn();
	setorigin(dbr, self.absmin
	           + '1 0 0' * random() * (self.absmax_x - self.absmin_x)
	           + '0 1 0' * random() * (self.absmax_y - self.absmin_y)
	           + '0 0 1' * random() * (self.absmax_z - self.absmin_z));
	setmodel (dbr, debrisname );
	dbr.skin = self.debrisskin;
	dbr.colormap = self.colormap; // inherit team colors
	dbr.owner = self; // do not be affected by our own explosion
	dbr.movetype = self.debrismovetype;
	dbr.solid = self.debrissolid;
	if(dbr.solid != SOLID_BSP) // SOLID_BSP has exact collision, MAYBE this works? TODO check this out
		setsize(dbr, '0 0 0', '0 0 0'); // needed for performance, until engine can deal better with it
	dbr.velocity_x = self.debrisvelocity_x + self.debrisvelocityjitter_x * random_2();
	dbr.velocity_y = self.debrisvelocity_y + self.debrisvelocityjitter_y * random_2();
	dbr.velocity_z = self.debrisvelocity_z + self.debrisvelocityjitter_z * random_2();
	self.velocity = self.velocity + force * self.debrisdamageforcescale;
	dbr.avelocity_x = random()*self.debrisavelocityjitter_x;
	dbr.avelocity_y = random()*self.debrisavelocityjitter_y;
	dbr.avelocity_z = random()*self.debrisavelocityjitter_z;
	dbr.damageforcescale = self.debrisdamageforcescale;
	if(dbr.damageforcescale)
		dbr.takedamage = DAMAGE_YES;
	SUB_SetFade(dbr, time + self.debristime + random_2() * self.debristimejitter, self.debrisfadetime);
};

void func_breakable_colormod()
{
	float h;
	if not(self.spawnflags & 2)
		return;
	h = self.health / self.max_health;
	if(h < 0.25)
		self.colormod = '1 0 0';
	else if(h <= 0.75)
		self.colormod = '1 0 0' + '0 1 0' * (2 * h - 0.5);
	else
		self.colormod = '1 1 1';
}

void func_breakable_look_destroyed()
{
	local float floor_z;

	if(self.mdl_dead == "")
		self.model = "";
	else {
		setmodel(self, self.mdl_dead);
		if (self.origin == '0 0 0')	{	// probably no origin brush, so don't spawn in the middle of the map..
			floor_z = self.absmin_z;
			setorigin(self,((self.absmax+self.absmin)*.5));
			self.origin_z = floor_z;
		}
	}

	self.solid = SOLID_NOT;
}

void func_breakable_look_restore()
{
	setmodel(self, self.mdl);
	self.solid = SOLID_BSP;
}

void func_breakable_behave_destroyed()
{
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;
	self.event_damage = SUB_Null;
	self.state = 1;
	setsize(self, '0 0 0', '0 0 0');
	func_breakable_colormod();
}

void func_breakable_behave_restore()
{
	self.owner = world;
	self.health = self.max_health;
	self.takedamage = DAMAGE_YES;
	self.event_damage = func_breakable_damage;
	self.state = 0;
	setsize(self, self.mins_save, self.maxs_save);
	func_breakable_colormod();
	setorigin(self, self.spawnorigin);
}

void func_breakable_destroyed()
{
	func_breakable_look_destroyed();
	func_breakable_behave_destroyed();
}

void func_breakable_restore()
{
	self.nextthink = 0;
	func_breakable_look_restore();
	func_breakable_behave_restore();
}

void func_breakable_launch_napalm(void) {
    // yes, this is a lazy hack

    var nc = self.napalm_count;

    if(nc <= 0)
        return;

    var saveteam = self.owner.team;
    self.hg_type = HG_REMOTE;
    self.owner.team = Team_FromIndex(self.napalm_color);

    for(var c = 0; c < nc; ++c) {
        Napalm_Spawn(self.owner, self.origin, 3, 0.15, DEATH_HURTTRIGGER, 180, 80, 20, 1.5) {
            velocity: random_spread_vector(70, 300, 300, 10)
        };
    }

    self.hg_type = 0;
    self.owner.team = saveteam;
}

vector debrisforce; // global, set before calling this
void func_breakable_destroy() {
	float n, i;
	string oldmsg;

	activator = self.owner;

	// now throw around the debris
	if (sv_breakable_debris)
	{
		n = tokenize_console(self.debris);
		for(i = 0; i < n; ++i)
			LaunchDebris(argv(i), debrisforce);
	}

    func_breakable_launch_napalm();
	func_breakable_destroyed();

	if(self.noise)
		sound (self, CHAN_AUTO, self.noise, VOL_BASE, ATTN_NORM);

	if(self.dmg)
		damage_radius(self, activator, self.dmg, self.dmg_edge, self.dmg_radius, self, self.dmg_force, DEATH_HURTTRIGGER, world);

	if(self.cnt)
		pointparticles(self.cnt, self.absmin * 0.5 + self.absmax * 0.5, '0 0 0', self.count);

	if(self.respawntime)
	{
		self.think = func_breakable_restore;
		self.nextthink = time + self.respawntime + random_2() * self.respawntimejitter;
	}

	oldmsg = self.message;
	self.message = "";
	other = self;
	SUB_UseTargets();
	self.message = oldmsg;
}

void func_breakable_damage(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force)
{
	if(self.state == 1)
		return;
	if(self.spawnflags & DOOR_NOSPLASH)
		if(!(DEATH_ISSPECIAL(deathtype)) && (deathtype & HITTYPE_SPLASH))
			return;
	if(self.team)
		if(attacker.team == self.team)
			return;
	if(self.sprite)
		WaypointSprite_Ping(self.sprite);
	self.health = self.health - _damage;
	func_breakable_colormod();

	if(self.health <= 0)
	{
		debrisforce = force;
		W_PrepareExplosionByDamage(attacker, func_breakable_destroy);
	}
}

void func_breakable_reset()
{
	self.team = self.team_saved;
	func_breakable_look_restore();
	if(self.spawnflags & 1)
		func_breakable_behave_destroyed();
	else
		func_breakable_behave_restore();
}

float func_breakable_init_done;
void func_breakable_init() {
	if (func_breakable_init_done)
		return;

	CACHE_CVAR(sv_breakable_debris);
}

// destructible walls that can be used to trigger target_objective_decrease
void spawnfunc_func_breakable() {
	float n, i;
	func_breakable_init();
	model_movable_init();
	if(!self.health)
		self.health = 100;
	self.max_health = self.health;

	// yes, I know, MOVETYPE_NONE is not available here, not that one would want it here anyway
	if(!self.debrismovetype) self.debrismovetype = MOVETYPE_BOUNCE;
	if(!self.debrissolid) self.debrissolid = SOLID_NOT;
	if(self.debrisvelocity == '0 0 0') self.debrisvelocity = '0 0 140';
	if(self.debrisvelocityjitter == '0 0 0') self.debrisvelocityjitter = '70 70 70';
	if(self.debrisavelocityjitter == '0 0 0') self.debrisavelocityjitter = '600 600 600';
	if(!self.debristime) self.debristime = 3.5;
	if(!self.debristimejitter) self.debristime = 2.5;

	if(self.mdl != "")
		self.cnt = particleeffectnum(self.mdl);
	if(self.count == 0)
		self.count = 1;

	if(!self.message)
		self.message = "got too close to an explosion";
	if(!self.message2)
		self.message2 = "was pushed into an explosion by";
	if(!self.dmg_radius)
		self.dmg_radius = 150;
	if(!self.dmg_force)
		self.dmg_force = 200;

	self.mdl = self.model;
	SetBrushEntityModel();
	self.mins_save = self.mins;
	self.maxs_save = self.maxs;

	self.use = func_breakable_restore;

	// precache all the models
	if (self.mdl_dead)
		precache_model(self.mdl_dead);
	n = tokenize_console(self.debris);
	for(i = 0; i < n; ++i)
		precache_model(argv(i));
	if(self.noise)
		precache_sound(self.noise);

	self.team_saved = self.team;

	self.reset = func_breakable_reset;
	self.spawnorigin = self.origin;
	func_breakable_reset();

	if(self.napalm_count > 0) {
		Napalm_Init();
	}
}
