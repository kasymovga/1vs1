// non-solid brush entities:
void(void) spawnfunc_func_illusionary { model_init(SOLID_NOT); } // Q1 name (WARNING: MISPREDICTED)
void(void) spawnfunc_func_clientillusionary { model_client_init(SOLID_NOT); } // brush entity

// solid brush entities
void(void) spawnfunc_func_wall { model_init(SOLID_BSP); } // Q1 name
void(void) spawnfunc_func_clientwall { model_client_init(SOLID_BSP); } // brush entity

void(void) spawnfunc_func_stardust {
	self.effects = EFFECT_STARDUST;
}

float(void) func_moving_brush_init {
	// trigger angles are used for one-way touches.  An angle of 0 is assumed
	// to mean no restrictions, so use a yaw of 360 instead.
	self.solid = SOLID_BSP;
	model_setup();
	self.movetype = MOVETYPE_PUSH;
	if (self.modelindex == 0) {
		entity_abort("func_moving_brush_init: no brushes found!");
		return 0;
	}
	return 1;
}

float(entity to, float fl) func_pointparticles_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_POINTPARTICLES);
	// optional features to save space
	fl = fl & 0x0F;
	if (self.spawnflags & 2)
		fl |= 0x10; // absolute count on toggle-on

	if (self.movedir != '0 0 0' || self.velocity != '0 0 0')
		fl |= 0x20; // 4 bytes - saves CPU

	if (self.waterlevel || self.count != 1)
		fl |= 0x40; // 4 bytes - obscure features almost never used

	if (self.mins != '0 0 0' || self.maxs != '0 0 0')
		fl |= 0x80; // 14 bytes - saves lots of space

	net_write_byte(MSG_ENTITY, fl);
	if (fl & 2) {
		if (self.state)
			net_write_coord(MSG_ENTITY, self.impulse);
		else
			net_write_coord(MSG_ENTITY, 0); // off
	}
	if (fl & 4) {
		net_write_coord(MSG_ENTITY, self.origin_x);
		net_write_coord(MSG_ENTITY, self.origin_y);
		net_write_coord(MSG_ENTITY, self.origin_z);
	}
	if (fl & 1) {
		if (self.model != "null") {
			net_write_short(MSG_ENTITY, self.modelindex);
			if (fl & 0x80) {
				net_write_coord(MSG_ENTITY, self.mins_x);
				net_write_coord(MSG_ENTITY, self.mins_y);
				net_write_coord(MSG_ENTITY, self.mins_z);
				net_write_coord(MSG_ENTITY, self.maxs_x);
				net_write_coord(MSG_ENTITY, self.maxs_y);
				net_write_coord(MSG_ENTITY, self.maxs_z);
			}
		} else {
			net_write_short(MSG_ENTITY, 0);
			if (fl & 0x80) {
				net_write_coord(MSG_ENTITY, self.maxs_x);
				net_write_coord(MSG_ENTITY, self.maxs_y);
				net_write_coord(MSG_ENTITY, self.maxs_z);
			}
		}
		net_write_short(MSG_ENTITY, self.cnt);
		if (fl & 0x20) {
			net_write_short(MSG_ENTITY, net_compress_vec(self.velocity));
			net_write_short(MSG_ENTITY, net_compress_vec(self.movedir));
		}
		if (fl & 0x40) {
			net_write_short(MSG_ENTITY, self.waterlevel * 16.0);
			net_write_byte(MSG_ENTITY, self.count * 16.0);
		}
		net_write_string(MSG_ENTITY, self.noise);
		if (self.noise != "") {
			net_write_byte(MSG_ENTITY, floor(self.atten * 64));
			net_write_byte(MSG_ENTITY, floor(self.volume * 255));
		}
		net_write_string(MSG_ENTITY, self.bgmscript);
		if (self.bgmscript != "") {
			net_write_byte(MSG_ENTITY, floor(self.bgmscriptattack * 64));
			net_write_byte(MSG_ENTITY, floor(self.bgmscriptdecay * 64));
			net_write_byte(MSG_ENTITY, floor(self.bgmscriptsustain * 255));
			net_write_byte(MSG_ENTITY, floor(self.bgmscriptrelease * 64));
		}
	}
	return 1;
}

void(void) fucn_pointparticles_use {
	self.state = !self.state;
	self.SendFlags |= 2;
}

void(void) func_pointparticles_think {
	if (self.origin != self.oldorigin) {
		self.SendFlags |= 4;
		self.oldorigin = self.origin;
	}
	self.nextthink = time;
}

void(void) func_pointparticles_reset {
	if (self.spawnflags & 1)
		self.state = 1;
	else
		self.state = 0;
}

void(void) spawnfunc_func_pointparticles {
	if (self.model != "")
		setmodel(self, self.model);

	if (self.noise != "")
		precache_sound(self.noise);

	if (!self.bgmscriptsustain)
		self.bgmscriptsustain = 1;
	else if (self.bgmscriptsustain < 0)
		self.bgmscriptsustain = 0;

	if (!self.atten)
		self.atten = ATTN_NORM;
	else if (self.atten < 0)
		self.atten = 0;

	if (!self.volume)
		self.volume = 1;

	if (!self.count)
		self.count = 1;

	if (!self.impulse)
		self.impulse = 1;

	if (!self.modelindex) {
		setorigin(self, self.origin + self.mins);
		setsize(self, '0 0 0', self.maxs - self.mins);
	}
	if (!self.cnt)
		self.cnt = particleeffectnum(self.mdl);

	net_link_entity(self, FALSE, 0, func_pointparticles_send);
	IFTARGETED {
		self.use = fucn_pointparticles_use;
		self.reset = func_pointparticles_reset;
		self.reset();
	} else
		self.state = 1;

	self.think = func_pointparticles_think;
	self.nextthink = time;
}

void(void) spawnfunc_func_sparks {
	// self.cnt is the amount of sparks that one burst will spawn
	if (self.cnt < 1) {
		self.cnt = 25.0; // nice default value
	}
	// self.wait is the probability that a sparkthink will spawn a spark shower
	// range: 0 - 1, but 0 makes little sense, so...
	if (self.wait < 0.05) {
		self.wait = 0.25; // nice default value
	}
	self.count = self.cnt;
	self.mins = '0 0 0';
	self.maxs = '0 0 0';
	self.velocity = '0 0 -1';
	self.mdl = "TE_SPARK";
	self.impulse = 10 * self.wait; // by default 2.5/sec
	self.wait = 0;
	self.cnt = 0; // use mdl
	spawnfunc_func_pointparticles();
}

float(entity to, float sf) func_rainsnow_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_RAINSNOW);
	net_write_byte(MSG_ENTITY, self.state);
	net_write_coord(MSG_ENTITY, self.origin_x + self.mins_x);
	net_write_coord(MSG_ENTITY, self.origin_y + self.mins_y);
	net_write_coord(MSG_ENTITY, self.origin_z + self.mins_z);
	net_write_coord(MSG_ENTITY, self.maxs_x - self.mins_x);
	net_write_coord(MSG_ENTITY, self.maxs_y - self.mins_y);
	net_write_coord(MSG_ENTITY, self.maxs_z - self.mins_z);
	net_write_short(MSG_ENTITY, net_compress_vec(self.dest));
	net_write_short(MSG_ENTITY, self.count);
	net_write_byte(MSG_ENTITY, self.cnt);
	return 1;
}

/*QUAKED spawnfunc_func_rain (0 .5 .8) ?
This is an invisible area like a trigger, which rain falls inside of.

Keys:
"velocity"
 falling direction (should be something like '0 0 -700', use the X and Y velocity for wind)
"cnt"
 sets color of rain (default 12 - white)
"count"
 adjusts density, this many particles fall every second for a 1024x1024 area, default is 2000
*/
void(void) spawnfunc_func_rain {
	self.dest = self.velocity;
	self.velocity = '0 0 0';
	if (!self.dest)
		self.dest = '0 0 -700';
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	model_setup();
	if (!self.cnt)
		self.cnt = 12;

	if (!self.count)
		self.count = 2000;

	self.count = 0.01 * self.count * (self.size_x / 1024) * (self.size_y / 1024);
	if (self.count < 1)
		self.count = 1;

	if (self.count > 65535)
		self.count = 65535;

	self.state = 1; // 1 is rain, 0 is snow
	net_link_entity(self, FALSE, 0, func_rainsnow_send);
}

/*QUAKED spawnfunc_func_snow (0 .5 .8) ?
This is an invisible area like a trigger, which snow falls inside of.

Keys:
"velocity"
 falling direction (should be something like '0 0 -300', use the X and Y velocity for wind)
"cnt"
 sets color of rain (default 12 - white)
"count"
 adjusts density, this many particles fall every second for a 1024x1024 area, default is 2000
*/
void(void) spawnfunc_func_snow {
	self.dest = self.velocity;
	self.velocity = '0 0 0';
	if (!self.dest)
		self.dest = '0 0 -300';

	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	model_setup();
	if (!self.cnt)
		self.cnt = 12;

	if (!self.count)
		self.count = 2000;

	self.count = 0.01 * self.count * (self.size_x / 1024) * (self.size_y / 1024);
	if (self.count < 1)
		self.count = 1;

	if (self.count > 65535)
		self.count = 65535;

	self.state = 0; // 1 is rain, 0 is snow
	net_link_entity(self, FALSE, 0, func_rainsnow_send);
}

void(void) func_ladder_touch {
	if not(other.iscreature)
		return;

	TRIGGER_EXACT_TOUCH;
	other.ladder_time = time + 0.1;
	other.ladder_entity = self;
}

void(void) spawnfunc_func_ladder {
	trigger_solid_brush_init();
	self.touch = func_ladder_touch;
}

void(void) spawnfunc_func_water {
	trigger_solid_brush_init();
	self.touch = func_ladder_touch;
}

void(void) func_nowalljump_touch {
	if (other.classname == "player")
		other.lastwj = time + frametime;
}

void(void) spawnfunc_func_nowalljump {
	trigger_solid_brush_init();
	self.touch = func_nowalljump_touch;
}

/*
 * magicwall
 */

.float alpha_solid;
.float alpha_nonsolid;
.float oldsolid;

#define MAGICWALL_ALPHAFIELD(e) (((e).solid == SOLID_BSP)? alpha_solid : alpha_nonsolid)
#define SPAWNFLAG_MW_START_HIDDEN 4
#define SPAWNFLAG_MW_TOGGLE 8

void(void) func_magicwall_think_transition {
	self.alpha = approach(self.alpha, self.MAGICWALL_ALPHAFIELD(self), self.speed * frametime);
	if (self.alpha && self.alpha < self.alpha_solid)
		self.nextthink = time;
	else if (self.think1)
		self.think1();
}

void(float sol, void(void) done) func_magicwall_start_transition {
	self.solid = sol;
	if (!sol)
		entity_drop_entities(self);

	if (self.speed < 0) {
		self.alpha = self.MAGICWALL_ALPHAFIELD(self);
		if (done)
			done();

		return;
	}
	self.think = func_magicwall_think_transition;
	self.think1 = done;
	self.nextthink = time;
}

float(void) func_magicwall_customize {
	return (self.alpha > 0);
}

void(void) func_magicwall_think {
	self.nextthink = time;
	self.alpha = approach(self.alpha, self.MAGICWALL_ALPHAFIELD(self), self.speed * frametime);
}

void(void) func_magicwall_reset {
	self.solid = self.oldsolid;
	self.alpha = self.MAGICWALL_ALPHAFIELD(self);
	self.think = stdproc_nothing;
}

void(void) func_magicwall_use_toggle {
	func_magicwall_start_transition(((self.solid == SOLID_BSP) ? SOLID_NOT : SOLID_BSP), NULL);
}

void(void) func_magicwall_think_transition_start {
	func_magicwall_start_transition(self.oldsolid, NULL);
}

void(void) func_magicwall_think_transition_schedule_back {
	self.nextthink = time + self.wait;
	self.think = func_magicwall_think_transition_start;
}

void(void) func_magicwall_use {
	if (self.oldsolid != self.solid) {
		if (self.think && self.think != func_magicwall_think_transition)
			self.nextthink = time + self.wait;

		return;
	}
	func_magicwall_start_transition(((self.oldsolid == SOLID_BSP) ? SOLID_NOT : SOLID_BSP),
		((self.wait >= 0) ? func_magicwall_think_transition_schedule_back : NULL));
}

void(void) func_magicwall_touch {
	if (other.classname == "player" && !PLAYER_DEAD(other)) {
		entity oldactivator = activator;
		activator = other;
		trigger_use_targets();
		activator = oldactivator;
	}
}

void(void) spawnfunc_func_magicwall {
    model_init(SOLID_BSP);
    if (self.alpha_solid <= 0)
        self.alpha_solid = 1;

    if (self.alpha_nonsolid < 0)
        self.alpha_nonsolid = 0;

    if (!self.wait && self.target == "")
        self.wait = self.delay;

    if (!self.wait)
        self.wait = 3;

    if (!self.speed)
        self.speed = 1;

    self.oldsolid = ((self.spawnflags & SPAWNFLAG_MW_START_HIDDEN) ? SOLID_NOT : SOLID_BSP);
    self.customizeentityforclient = func_magicwall_customize;
    self.think = func_magicwall_think;
    self.reset = func_magicwall_reset;
    self.use = ((self.spawnflags & SPAWNFLAG_MW_TOGGLE) ? func_magicwall_use_toggle : func_magicwall_use);
    self.touch = func_magicwall_touch;
    // self.clipgroup = CLIPGROUP_OBSERVER;
    self.reset();
    self.nextthink = time;
}

.float dmgtime2;
void(void) func_generic_plat_blocked {
    if (self.dmg && other.takedamage != DAMAGE_NO) {
        if (self.dmgtime2 < time) {
            damage(other, self, self, self.dmg, DEATH_HURTTRIGGER, other.origin, '0 0 0');
            self.dmgtime2 = time + self.dmgtime;
        }

        // Gib dead/dying stuff
        if (other.deadflag != DEAD_NO)
            damage(other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
    }
}

/*
=============
func_calc_move

calculate self.velocity and self.nextthink to reach dest from
self.origin traveling at speed
===============
*/
void(void) func_calc_move_done {
	// After moving, set origin to exact final destination
	setorigin (self, self.finaldest);
	self.velocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1)
		self.think1 ();
}

void(vector tdest, float tspeed, void() func) func_calc_move {
	vector delta;
	float traveltime;
	if (!tspeed) {
		entity_abort("No speed is defined!");
		return;
	}
	self.think1 = func;
	self.finaldest = tdest;
	self.think = func_calc_move_done;
	if (tdest == self.origin) {
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + sys_ticrate;
		return;
	}
	delta = tdest - self.origin;
	traveltime = vlen (delta) / tspeed;
	if (traveltime < sys_ticrate) {
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + sys_ticrate;
		return;
	}
	self.velocity = delta * (1/traveltime); // QuakeC doesn't allow vector/float division
	self.nextthink = self.ltime + traveltime;
}

void(void) func_calc_angle_move_done {
	// After rotating, set angle to exact final angle
	self.angles = self.finalangle;
	self.avelocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1)
		self.think1 ();
}

// FIXME: I fixed this function only for rotation around the main axes
void(vector destangle, float tspeed, void() func) func_calc_angle_move {
	vector delta;
	float traveltime;

	if (!tspeed) {
		entity_abort("No speed is defined!");
		return;
	}
	// take the shortest distance for the angles
	self.angles_x -= 360 * floor((self.angles_x - destangle_x) / 360 + 0.5);
	self.angles_y -= 360 * floor((self.angles_y - destangle_y) / 360 + 0.5);
	self.angles_z -= 360 * floor((self.angles_z - destangle_z) / 360 + 0.5);
	delta = destangle - self.angles;
	traveltime = vlen (delta) / tspeed;
	self.think1 = func;
	self.finalangle = destangle;
	self.think = func_calc_angle_move_done;
	if (traveltime < sys_ticrate) {
		self.avelocity = '0 0 0';
		self.nextthink = self.ltime + sys_ticrate;
		return;
	}
	self.avelocity = delta * (1 / traveltime);
	self.nextthink = self.ltime + traveltime;
}

.entity trigger_field;

void(void) func_plat_center_touch;
void(void) func_plat_trigger_use;
void(void) func_plat_go_up;
void(void) func_plat_go_down;
void(void) func_plat_crush;

float PLAT_LOW_TRIGGER = 1;
float PLAT_NO_TRIGGER = 8;
float PLAT_REVERSIBLE = 16;

void(void) func_plat_spawn_inside_trigger {
	entity trigger;
	vector tmin, tmax;
	trigger = spawn();
	trigger.touch = func_plat_center_touch;
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.enemy = self;
	tmin = self.absmin + '25 25 0';
	tmax = self.absmax - '25 25 -8';
	tmin_z = tmax_z - (self.pos1_z - self.pos2_z + 8);
	if (self.spawnflags & PLAT_LOW_TRIGGER)
		tmax_z = tmin_z + 8;

	if (self.size_x <= 50) {
		tmin_x = (self.mins_x + self.maxs_x) / 2;
		tmax_x = tmin_x + 1;
	}
	if (self.size_y <= 50) {
		tmin_y = (self.mins_y + self.maxs_y) / 2;
		tmax_y = tmin_y + 1;
	}
	self.enemy = trigger;
	setsize (trigger, tmin, tmax);
}

void(void) func_plat_hit_top {
	sound(self, CHAN_TRIGGER, self.noise1, VOL_BASE, ATTN_NORM);
	self.state = 1;
	self.think = func_plat_go_down;
	self.nextthink = self.ltime + 3;
}

void(void) func_plat_hit_bottom {
	sound(self, CHAN_TRIGGER, self.noise1, VOL_BASE, ATTN_NORM);
	self.state = 2;
}

void(void) func_plat_go_down {
	sound(self, CHAN_TRIGGER, self.noise, VOL_BASE, ATTN_NORM);
	self.state = 3;
	func_calc_move (self.pos2, self.speed, func_plat_hit_bottom);
}

void(void) func_plat_go_up {
	sound(self, CHAN_TRIGGER, self.noise, VOL_BASE, ATTN_NORM);
	self.state = 4;
	func_calc_move (self.pos1, self.speed, func_plat_hit_top);
}

void(void) func_plat_center_touch {
	if not(other.iscreature)
		return;

	if (other.health <= 0)
		return;

	entity trig = self;
	self = self.enemy;
	if (self.state == 2) {
		if (trig.wait < 0) {
			trig.wait = time + self.delay;
		} else if (time > trig.wait) {
			func_plat_go_up();
		}
	} else if (self.state == 1) {
		self.nextthink = self.ltime + 1; // delay going down
	}
}

void(void) func_plat_trigger_use {
	if ((self.think && !(self.spawnflags & PLAT_REVERSIBLE)) || (self.state != 4 && self.state != 1))
		return; // already activated

	if (self.spawnflags & PLAT_REVERSIBLE && self.enemy)
		self.enemy.wait = -1;

	func_plat_go_down();
}


void(void) func_plat_crush {
	if ((self.spawnflags & 4) && (other.takedamage != DAMAGE_NO)) { // KIll Kill Kill!!
		damage(other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
	} else {
		if ((self.dmg) && (other.takedamage != DAMAGE_NO)) {   // Shall we bite?
			damage(other, self, self, self.dmg, DEATH_HURTTRIGGER, other.origin, '0 0 0');
			// Gib dead/dying stuff
			if (other.deadflag != DEAD_NO)
				damage(other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
		}

		if (self.state == 4)
			func_plat_go_down ();
		else if (self.state == 3)
			func_plat_go_up ();
		else {
			backtrace("func_plat_crush: bad self.state\n");
			return;
		}
	}
}

void(void) func_plat_use {
	self.use = stdproc_nothing;
	if (self.state != 4) {
		backtrace("func_plat_use: not in up state");
		return;
	}
	func_plat_go_down();
}

.string sound1, sound2;

void(void) func_plat_reset {
	if (!self.nottargeted && self.targetname != "" && !(self.spawnflags & PLAT_REVERSIBLE)) {
		setorigin (self, self.pos1);
		self.state = 4;
		self.use = func_plat_use;
	} else {
		setorigin (self, self.pos2);
		self.state = 2;
		self.use = func_plat_trigger_use;
	}
	if (self.enemy)
		self.enemy.wait = 0;

	self.velocity = '0 0 0';
	self.think = stdproc_nothing;
	self.nextthink = 0;
	sound_stop(self, CHAN_TRIGGER);
}

void(void) spawnfunc_path_corner { }
void(void) spawnfunc_func_plat {
	if (!self.t_length)
		self.t_length = 80;

	if (!self.t_width)
		self.t_width = 10;

	if (self.sounds == 0)
		self.sounds = 2;

	if (self.spawnflags & 4)
		self.dmg = 10000;

	if (self.dmg && (!self.message))
		self.message = "was squished";

	if (self.dmg && (!self.message2))
		self.message2 = "was squished by";

	if (self.sounds == 1) {
		precache_sound("plats/plat1.wav");
		precache_sound("plats/plat2.wav");
		self.noise = "plats/plat1.wav";
		self.noise1 = "plats/plat2.wav";
	}
	if (self.sounds >= 2) {
		precache_sound("plats/medplat1.wav");
		precache_sound("plats/medplat2.wav");
		self.noise = "plats/medplat1.wav";
		self.noise1 = "plats/medplat2.wav";
	}
	if (self.sound1) {
		precache_sound(self.sound1);
		self.noise = self.sound1;
	}
	if (self.sound2) {
		precache_sound(self.sound2);
		self.noise1 = self.sound2;
	}
	self.mangle = self.angles;
	self.angles = '0 0 0';
	self.classname = "plat";
	if not(func_moving_brush_init())
		return;

	self.effects |= EFFECT_LOWPRECISION;
	setsize (self, self.mins , self.maxs);
	self.blocked = func_plat_crush;
	if (!self.speed)
		self.speed = 150;

	self.pos1 = self.origin;
	self.pos2 = self.origin;
	self.pos2_z = self.origin_z -
			((cvar("sv_gameplayfix_useheightforplat") && self.height) ? self.height : self.size_z) + 8;
	if (!self.delay) {
		self.delay = 2;
	}
	if (!(self.spawnflags & PLAT_NO_TRIGGER))
		func_plat_spawn_inside_trigger (); // the "start moving" trigger

	self.reset = func_plat_reset;
	func_plat_reset();
}

void(void) func_train_next;
void(void) func_train_wait {
	self.think = func_train_next;
	self.nextthink = self.ltime + self.wait;
	if (self.noise != "")
		sound_stop_to(MSG_BROADCAST, self, CHAN_TRIGGER); // send this as unreliable only, as the train will resume operation shortly anyway
}

float sv_gameplayfix_trainnomins;
float sv_gameplayfix_trainnowait;

void(void) func_train_next {
	entity targ;
	targ = find(world, targetname, self.target);
	self.target = targ.target;
	if (self.target == "") {
		print("func_train_next: no next target");
		return;
	}
	self.wait = targ.wait;
	if (!self.wait)
		self.wait = 0.1;

	float _speed = (targ.speed ? targ.speed : self.speed);
	if (self.wait < 0) {
		if (self.targetname != "" && !sv_gameplayfix_trainnowait)
			func_calc_move(targ.origin - (sv_gameplayfix_trainnomins ? '0 0 0' : self.mins), _speed, stdproc_nothing);
		else
			func_calc_move(targ.origin - (sv_gameplayfix_trainnomins ? '0 0 0' : self.mins), _speed, func_train_next);
	} else
		func_calc_move(targ.origin - (sv_gameplayfix_trainnomins ? '0 0 0' : self.mins), _speed, func_train_wait);

	if (self.noise != "")
		sound(self, CHAN_TRIGGER, self.noise, VOL_BASE, ATTN_IDLE);
}

void(void) func_train_find {
	entity targ;
	targ = find(world, targetname, self.target);
	if (!targ || self.target == "") {
		print("func_train_find: no init target\n");
		return;
	}
	self.target = targ.target;
	setorigin(self, targ.origin - (sv_gameplayfix_trainnomins ? '0 0 0' : self.mins));
	if (self.target == "") {
		print("func_train_find: no next target\n");
		return;
	}
	if (self.targetname != "" && find(world, target, self.targetname) && !sv_gameplayfix_trainnowait) {
		self.use = func_train_next;
	} else {
		self.targetname = "";
		self.nextthink = self.ltime + 1;
		self.think = func_train_next;
	}
}

/*QUAKED spawnfunc_func_train (0 .5 .8) ?
Ridable platform, targets spawnfunc_path_corner path to follow.
speed : speed the train moves (can be overridden by each spawnfunc_path_corner)
target : targetname of first spawnfunc_path_corner (starts here)
*/
float func_train_init_done;
void(void) spawnfunc_func_train {
	if not(func_train_init_done) {
		CVAR_CACHE(sv_gameplayfix_trainnomins);
		CVAR_CACHE(sv_gameplayfix_trainnowait);
		func_train_init_done = TRUE;
	}
	if (self.noise != "")
		precache_sound(self.noise);

	if (!self.target) {
		entity_abort("func_train without a target");
		return;
	}
	if (!self.speed)
		self.speed = 100;

	if not(func_moving_brush_init())
		return;

	self.effects |= EFFECT_LOWPRECISION;
	// wait for targets to spawn
	entity_initialize(self, func_train_find, INITPRIO_SETLOCATION);
	self.blocked = func_generic_plat_blocked;
	if (self.dmg & (!self.message))
		self.message = " was squished";

    if (self.dmg && (!self.message2))
		self.message2 = "was squished by";

	if (self.dmg && (!self.dmgtime))
		self.dmgtime = 0.25;

	self.dmgtime2 = time;
	// TODO make a reset function for this one
}

/*QUAKED spawnfunc_func_rotating (0 .5 .8) ? - - X_AXIS Y_AXIS
Brush model that spins in place on one axis (default Z).
speed   : speed to rotate (in degrees per second)
noise   : path/name of looping .wav file to play.
dmg     : Do this mutch dmg every .dmgtime intervall when blocked
dmgtime : See above.
*/

void(void) spawnfunc_func_rotating {
	if (self.noise != "") {
		precache_sound(self.noise);
		ambientsound(self.origin, self.noise, VOL_BASE, ATTN_IDLE);
	}
	if (!self.speed)
		self.speed = 100;
	// FIXME: test if this turns the right way, then remove this comment (negate as needed)
	if (self.spawnflags & 4) // X (untested)
		self.avelocity = '0 0 1' * self.speed;
	// FIXME: test if this turns the right way, then remove this comment (negate as needed)
	else if (self.spawnflags & 8) // Y (untested)
		self.avelocity = '1 0 0' * self.speed;
	// FIXME: test if this turns the right way, then remove this comment (negate as needed)
	else // Z
		self.avelocity = '0 1 0' * self.speed;

	if (self.dmg & (!self.message))
		self.message = " was squished";

	if (self.dmg && (!self.message2))
		self.message2 = "was squished by";

	if (self.dmg && (!self.dmgtime))
		self.dmgtime = 0.25;

    self.dmgtime2 = time;
	if not(func_moving_brush_init())
		return;

	// no EFFECT_LOWPRECISION here, as rounding angles is bad
	self.blocked = func_generic_plat_blocked;
	// wait for targets to spawn
	self.nextthink = self.ltime + 999999999;
	self.think = stdproc_nothing;
	// TODO make a reset function for this one
}

.float height;
void func_bobbing_controller_think() {
	vector v;
	self.nextthink = time + 0.1;
	// calculate sinewave using makevectors
	makevectors((self.nextthink * self.owner.cnt + self.owner.phase * 360) * '0 1 0');
	v = self.owner.destvec + self.owner.movedir * v_forward_y;
	// * 10 so it will arrive in 0.1 sec
	self.owner.velocity = (v - self.owner.origin) * 10;
}

/*QUAKED spawnfunc_func_bobbing (0 .5 .8) ? X_AXIS Y_AXIS
Brush model that moves back and forth on one axis (default Z).
speed : how long one cycle takes in seconds (default 4)
height : how far the cycle moves (default 32)
phase : cycle timing adjustment (0-1 as a fraction of the cycle, default 0)
noise : path/name of looping .wav file to play.
dmg : Do this mutch dmg every .dmgtime intervall when blocked
dmgtime : See above.
*/
void spawnfunc_func_bobbing() {
	entity controller;
	if (self.noise != "") {
		precache_sound(self.noise);
		sound_to(MSG_INIT, self, CHAN_TRIGGER, self.noise, VOL_BASE, ATTN_IDLE);
	}
	if (!self.speed)
		self.speed = 4;

	if (!self.height)
		self.height = 32;

	// center of bobbing motion
	self.destvec = self.origin;
	// time scale to get degrees
	self.cnt = 360 / self.speed;
	// damage when blocked
	self.blocked = func_generic_plat_blocked;
	if (self.dmg & (!self.message))
		self.message = " was squished";

    if (self.dmg && (!self.message2))
		self.message2 = "was squished by";

	if (self.dmg && (!self.dmgtime))
		self.dmgtime = 0.25;

	self.dmgtime2 = time;
	// how far to bob
	if (self.spawnflags & 1) // X
		self.movedir = '1 0 0' * self.height;
	else if (self.spawnflags & 2) // Y
		self.movedir = '0 1 0' * self.height;
	else // Z
		self.movedir = '0 0 1' * self.height;

	if not(func_moving_brush_init())
		return;

	// wait for targets to spawn
	controller = spawn();
	controller.classname = "func_bobbing_controller";
	controller.owner = self;
	controller.nextthink = time + 1;
	controller.think = func_bobbing_controller_think;
	self.nextthink = self.ltime + 999999999;
	self.think = stdproc_nothing;
	// Savage: Reduce bandwith, critical on e.g. nexdm02
	self.effects |= EFFECT_LOWPRECISION;
	// TODO make a reset function for this one
}

void(void) func_button_return;

void(void) func_button_wait {
	self.state = FUNC_STATE_TOP;
	self.nextthink = self.ltime + self.wait;
	self.think = func_button_return;
	activator = self.enemy;
	trigger_use_targets();
	self.frame = 1; // use alternate textures
}

void(void) func_button_done {
	self.state = FUNC_STATE_BOTTOM;
}

void(void) func_button_return {
	self.state = FUNC_STATE_DOWN;
	func_calc_move (self.pos1, self.speed, func_button_done);
	self.frame = 0; // use normal textures
	if (self.health)
		self.takedamage = DAMAGE_YES; // can be shot again
}

void(void) func_button_blocked {
	// do nothing, just don't come all the way back out
}

void(void) func_button_fire {
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;    // will be reset upon return

	if (self.state == FUNC_STATE_UP || self.state == FUNC_STATE_TOP)
		return;

	if (self.noise != "")
		sound(self, CHAN_TRIGGER, self.noise, VOL_BASE, ATTN_NORM);

	self.state = FUNC_STATE_UP;
	func_calc_move (self.pos2, self.speed, func_button_wait);
}

void(void) func_button_reset {
	self.health = self.max_health;
	setorigin(self, self.pos1);
	self.frame = 0; // use normal textures
	self.state = FUNC_STATE_BOTTOM;
	if (self.health)
		self.takedamage = DAMAGE_YES; // can be shot again
}

void(void) func_button_use {
	self.enemy = activator;
	func_button_fire ();
}

void(void) func_button_touch {
	if (!other)
		return;

	if not(other.iscreature)
		return;

	if (other.velocity * self.movedir < 0)
		return;

	self.enemy = other;
	if (other.owner)
		self.enemy = other.owner;

	func_button_fire();
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) func_button_damage {
	self.health = self.health - _damage;
	if (self.health <= 0) {
		self.enemy = attacker;
		func_button_fire ();
	}
}

void(void) func_button_pos_setup {
	self.pos1 = self.origin;
	self.pos2 = self.pos1 +
			self.movedir * (self.size_x * '1 0 0') * '1 0 0' +
			self.movedir * (self.size_y * '0 1 0') * '0 1 0' +
			self.movedir * (self.size_z * '0 0 1') * '0 0 1' -
			self.lip * self.movedir;
}

/*QUAKED spawnfunc_func_button (0 .5 .8) ?
When a button is touched, it moves some distance in the direction of it's angle, triggers all of it's targets, waits some time, then returns to it's original position where it can be triggered again.

"angle"		determines the opening direction
"target"	all entities with a matching targetname will be used
"speed"		override the default 40 speed
"wait"		override the default 1 second wait (-1 = never return)
"lip"		override the default 4 pixel lip remaining at end of move
"health"	if set, the button must be killed instead of touched. If set to -1, the button will fire on ANY attack, even damageless ones like the MinstaGib laser
"sounds"
0) steam metal
1) wooden clunk
2) metallic click
3) in-out
*/
void(void) spawnfunc_func_button {
	entity_movedir_setup();
	if not(func_moving_brush_init())
		return;

	self.effects |= EFFECT_LOWPRECISION;
	self.blocked = func_button_blocked;
	self.use = func_button_use;
	self.reset = func_button_reset;
	if (self.health) {
		self.max_health = self.health;
		self.event_damage = func_button_damage;
		self.takedamage = DAMAGE_YES;
	} else
		self.touch = func_button_touch;

	if (!self.speed)
		self.speed = 40;

	if (!self.wait)
		self.wait = 1;

	if (self.wait < 0 && cvar("g_button_nowaitforever")) {
		self.wait = 0.001;
	}
	if (!self.lip)
		self.lip = 4;

	if (self.sounds > 0)
	if (self.noise == "")
		self.noise = "misc/menu1.wav";

	if (self.noise != "")
		precache_sound(self.noise);

	func_button_pos_setup();
	self.flags |= FL_NOTARGET;
	func_button_reset();
}

float DOOR_START_OPEN = 1;
float DOOR_DONT_LINK = 4;
float DOOR_TOGGLE = 32;
float DOOR_KEY_GOLD_OR_CRUSH = 8;
float DOOR_KEY_SILVER = 16;
float DOOR_KEY_BLOOD = 64;
float DOOR_PLAYER_ONLY = 128;

void(void) func_door_go_down;
void(void) func_door_go_up;
void(void) func_door_rotating_go_down;
void(void) func_door_rotating_go_up;

void(void) func_door_blocked {
	if ((self.spawnflags & 8) && (other.takedamage != DAMAGE_NO)) { // KIll Kill Kill!!
		damage(other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
	} else {
		if ((self.dmg) && (other.takedamage != DAMAGE_NO))    // Shall we bite?
			damage(other, self, self, self.dmg, DEATH_HURTTRIGGER, other.origin, '0 0 0');

		//Dont chamge direction for dead or dying stuff
		if (other.deadflag != DEAD_NO && (other.takedamage == DAMAGE_NO)) {
			if (self.wait >= 0) {
				if (self.state == FUNC_STATE_DOWN) {
					if (self.classname == "door")
						func_door_go_up();
					else
						func_door_rotating_go_up ();
				} else {
					if (self.classname == "door")
						func_door_go_down();
					else
						func_door_rotating_go_down ();
				}
			}
		} else {
			//gib dying stuff just to make sure
			if ((self.dmg) && (other.takedamage != DAMAGE_NO)) // Shall we bite?
				damage(other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
		}
	}
}

void(void) func_door_hit_top {
	if (self.noise1 != "")
		sound(self, CHAN_TRIGGER, self.noise1, VOL_BASE, ATTN_NORM);

	self.state = FUNC_STATE_TOP;
	if (self.spawnflags & DOOR_TOGGLE)
		return; // don't come down automatically

	if (self.classname == "door")
		self.think = func_door_go_down;
	else
		self.think = func_door_rotating_go_down;

	self.nextthink = self.ltime + self.wait;
}

void(void) func_door_hit_bottom {
	if (self.noise1 != "")
		sound(self, CHAN_TRIGGER, self.noise1, VOL_BASE, ATTN_NORM);

	self.state = FUNC_STATE_BOTTOM;
}

void(void) func_door_go_down {
	if (self.noise2 != "")
		sound(self, CHAN_TRIGGER, self.noise2, VOL_BASE, ATTN_NORM);

	if (self.max_health) {
		self.takedamage = DAMAGE_YES;
		self.health = self.max_health;
	}
	self.state = FUNC_STATE_DOWN;
	func_calc_move (self.pos1, self.speed, func_door_hit_bottom);
}

void(void) func_door_go_up {
	if (self.state == FUNC_STATE_UP)
		return; // already going up

	if (self.state == FUNC_STATE_TOP) { // reset top wait time
		self.nextthink = self.ltime + self.wait;
		return;
	}
	if (self.noise2 != "")
		sound(self, CHAN_TRIGGER, self.noise2, VOL_BASE, ATTN_NORM);

	self.state = FUNC_STATE_UP;
	func_calc_move (self.pos2, self.speed, func_door_hit_top);
	string oldmessage;
	oldmessage = self.message;
	self.message = "";
	trigger_use_targets();
	self.message = oldmessage;
}

void(void) func_door_fire {
	entity oself;
	entity starte;
	if (self.owner != self) {
		backtrace("func_door_fire: self.owner != self");
		return;
	}
	oself = self;
	if (self.spawnflags & DOOR_TOGGLE) {
		if (self.state == FUNC_STATE_UP || self.state == FUNC_STATE_TOP) {
			starte = self;
			do {
				if (self.classname == "door")
					func_door_go_down();
				else
					func_door_rotating_go_down();

				self = self.enemy;
			} while ( (self != starte) && (self != world) );
			self = oself;
			return;
		}
	}
	// trigger all paired doors
	starte = self;
	do {
		if (self.classname == "door") {
			func_door_go_up();
		} else {
			// if the BIDIR spawnflag (==2) is set and the trigger has set trigger_reverse, reverse the opening direction
			if ((self.spawnflags & 2) && other.trigger_reverse!=0 && self.lip!=666 && self.state == FUNC_STATE_BOTTOM) {
				self.lip = 666; // self.lip is used to remember reverse opening direction for door_rotating
				self.pos2 = '0 0 0' - self.pos2;
			}
			// if BIDIR_IN_DOWN (==8) is set, prevent the door from reoping during closing if it is triggered from the wrong side
			if (!((self.spawnflags & 2) &&  (self.spawnflags & 8) && self.state == FUNC_STATE_DOWN
					&& (((self.lip==666) && (other.trigger_reverse==0)) || ((self.lip!=666) && (other.trigger_reverse!=0))))) {
				func_door_rotating_go_up();
			}
		}
		self = self.enemy;
	} while ( (self != starte) && (self != world) );
	self = oself;
}

void(void) func_door_use {
	entity oself;
	//dprint("func_door_use (model: ");dprint(self.model);dprint(")\n");
	if (self.owner) {
		oself = self;
		self = self.owner;
		func_door_fire();
		self = oself;
	} else
		print("door without owner\n");
}


void(void) func_door_trigger_touch {
	if not(other.iscreature)
		return;

	if (self.owner.spawnflags & DOOR_PLAYER_ONLY)
	if (other.classname != "player")
		return;

	if (self.owner.items)
	if not(other.keys & self.owner.items) {
		if (self.owner.state == FUNC_STATE_BOTTOM)
		if (clienttype(other) == CLIENTTYPE_REAL) {
			string s;
			if  (self.owner.items & IT_KEY1)
				s = "Silver Key";
			else if (self.owner.items & IT_KEY2)
				s = "Gold Key";
			else if (self.owner.items & IT_KEY3)
				s = "Blood Key";
			else
				s = "Unknown Key";

			if (time >= self.attack_finished_single) {
				self.attack_finished_single = time + 1;
				sound_play2(other, "misc/talk.wav");
			}
			centerprint(other, strcat("This door required ", s));
		}
		return;
	}
	activator = other;
	self = self.owner;
	func_door_use();
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) func_door_damage {
	entity oself;
	self.health = self.health - _damage;
	if (self.health <= 0) {
		oself = self;
		self = self.owner;
		self.health = self.max_health;
		//self.takedamage = DAMAGE_NO; // wil be reset upon return //ORLY?
		func_door_use();
		self = oself;
	}
}

void(void) func_door_touch {
	if not(other.iscreature)
		return;

	if (self.owner.attack_finished_single > time)
		return;

	self.owner.attack_finished_single = time + 2;
	if (!(self.owner.dmg) && (self.owner.message != "") && self.owner.state == FUNC_STATE_BOTTOM) {
		if (clienttype(other) == CLIENTTYPE_REAL) {
			centerprint(other, self.owner.message);
			sound_play2(other, "misc/talk.wav");
		}
	}
}

void(void) func_door_rotating_hit_top {
	if (self.noise1 != "")
		sound(self, CHAN_TRIGGER, self.noise1, VOL_BASE, ATTN_NORM);

	self.state = FUNC_STATE_TOP;
	if (self.spawnflags & DOOR_TOGGLE)
		return; // don't come down automatically

	self.think = func_door_rotating_go_down;
	self.nextthink = self.ltime + self.wait;
}

void(void) func_door_rotating_hit_bottom {
	if (self.noise1 != "")
		sound(self, CHAN_TRIGGER, self.noise1, VOL_BASE, ATTN_NORM);
	if (self.lip == 666) { // self.lip is used to remember reverse opening direction for door_rotating
		self.pos2 = '0 0 0' - self.pos2;
		self.lip = 0;
	}
	self.state = FUNC_STATE_BOTTOM;
}

void(void) func_door_rotating_go_down {
	if (self.noise2 != "")
		sound(self, CHAN_TRIGGER, self.noise2, VOL_BASE, ATTN_NORM);

	if (self.max_health) {
		self.takedamage = DAMAGE_YES;
		self.health = self.max_health;
	}
	self.state = FUNC_STATE_DOWN;
	func_calc_angle_move(self.pos1, self.speed, func_door_rotating_hit_bottom);
}

void(void) func_door_rotating_go_up {
	if (self.state == FUNC_STATE_UP)
		return; // already going up

	if (self.state == FUNC_STATE_TOP) { // reset top wait time
		self.nextthink = self.ltime + self.wait;
		return;
	}
	if (self.noise2 != "")
		sound(self, CHAN_TRIGGER, self.noise2, VOL_BASE, ATTN_NORM);

	self.state = FUNC_STATE_UP;
	func_calc_angle_move(self.pos2, self.speed, func_door_rotating_hit_top);
	string oldmessage;
	oldmessage = self.message;
	self.message = "";
	trigger_use_targets();
	self.message = oldmessage;
}

entity(vector fmins, vector fmaxs) func_spawn_field {
	entity trigger;
	vector t1, t2, v;
	trigger = spawn();
	trigger.classname = "doortriggerfield";
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.owner = self;
	trigger.touch = func_door_trigger_touch;
	t1 = fmins;
	t2 = fmaxs;
	v = stov(cvar_string("sv_door_trigger_field"));
	setsize(trigger, t1 - v, t2 + v);
	return trigger;
}

float(entity e1, entity e2) func_doors_touching {
	if (e1.absmin_x > e2.absmax_x)
		return FALSE;

	if (e1.absmin_y > e2.absmax_y)
		return FALSE;

	if (e1.absmin_z > e2.absmax_z)
		return FALSE;

	if (e1.absmax_x < e2.absmin_x)
		return FALSE;

	if (e1.absmax_y < e2.absmin_y)
		return FALSE;

	if (e1.absmax_z < e2.absmin_z)
		return FALSE;

	if (e1.existsonlyfor != e2.existsonlyfor)
		return FALSE;

	return TRUE;
}

void(void) func_doors_link {
	entity t, starte;
	vector cmins, cmaxs;
	if (self.enemy)
		return; // already linked by another door

	if ((self.spawnflags & DOOR_DONT_LINK) || cvar("sv_gameplayfix_dontlinkdoors")) {
		self.owner = self.enemy = self;
		IFTARGETED
			return;

		if (self.health || (!self.items && cvar("g_door_shootable"))) {
			self.takedamage = DAMAGE_YES;
			self.event_damage = func_door_damage;
		}
		if (self.health)
			return;

		self.trigger_field = func_spawn_field(self.absmin, self.absmax);
		return; // don't want to link this door
	}
	cmins = self.absmin;
	cmaxs = self.absmax;
	starte = self;
	t = self;
	do {
		if (self.owner != starte) {
			self.owner = starte; // master door
			if (self.health)
				starte.health = self.health;

			if (self.items)
				starte.items = self.items;

			IFTARGETED
				starte.targetname = self.targetname;

			if (self.message != "")
				starte.message = self.message;
		}
		t = find(t, classname, self.classname);
		if (!t) {
			self.enemy = starte; // make the chain a loop
			// shootable, or triggered doors just needed the owner/enemy links,
			// they don't spawn a field
			self = self.owner;
			if (self.health)
				break;

			IFTARGETED
				break;

			self.owner.trigger_field = func_spawn_field(cmins, cmaxs);
			break;
		}
		if (func_doors_touching(self,t)) {
			if (t.enemy) {
				continue;
			}
			self.enemy = t;
			self = t;
			if (t.absmin_x < cmins_x)
				cmins_x = t.absmin_x;

			if (t.absmin_y < cmins_y)
				cmins_y = t.absmin_y;

			if (t.absmin_z < cmins_z)
				cmins_z = t.absmin_z;

			if (t.absmax_x > cmaxs_x)
				cmaxs_x = t.absmax_x;

			if (t.absmax_y > cmaxs_y)
				cmaxs_y = t.absmax_y;

			if (t.absmax_z > cmaxs_z)
				cmaxs_z = t.absmax_z;
		}
	} while (1);
	if (starte.targetname == "" || starte.nottargeted)
	if (starte.health > 0 || (!starte.items && cvar("g_door_shootable"))) {
		for (t = starte; ;) {
			t.takedamage = DAMAGE_YES;
			t.event_damage = func_door_damage;
			if ((t = t.enemy) == starte)
				break;
		}
	}
}

/*QUAKED spawnfunc_func_door (0 .5 .8) ? START_OPEN x DOOR_DONT_LINK x x TOGGLE
if two doors touch, they are assumed to be connected and operate as a unit.

TOGGLE causes the door to wait in both the start and end states for a trigger event.

START_OPEN causes the door to move to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not useful for touch or takedamage doors).

"message"	is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"		determines the opening direction
"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"	if set, door must be shot open
"speed"		movement speed (100 default)
"wait"		wait before returning (3 default, -1 = never return)
"lip"		lip remaining at end of move (8 default)
"dmg"		damage to inflict when blocked (2 default)
"sounds"
0)	no sound
1)	stone
2)	base
3)	stone chain
4)	screechy metal
FIXME: only one sound set available at the time being

*/

void(void) func_door_init_startopen {
	setorigin (self, self.pos2);
	self.pos2 = self.pos1;
	self.pos1 = self.origin;
}

void(void) func_door_reset {
	setorigin(self, self.pos1);
	self.velocity = '0 0 0';
	self.state = FUNC_STATE_BOTTOM;
	self.think = stdproc_nothing;
}

.float jaildoormode;
void(void) func_door_rm_hack {
	if (self.targetname == "jail_red" || self.targetname == "jail_blue")
	if (self.jaildoormode != 2)
		self.spawnflags |= DOOR_START_OPEN;
}

void(void) spawnfunc_func_door {
	func_door_rm_hack();
	entity_movedir_setup();
	self.max_health = self.health;
	if not(func_moving_brush_init())
		return;

	self.effects |= EFFECT_LOWPRECISION;
	self.classname = "door";
	self.blocked = func_door_blocked;
	self.use = func_door_use;
    if (self.spawnflags & DOOR_KEY_GOLD_OR_CRUSH) {
		if (self.wait < 0)
			self.items |= IT_KEY2;
		else
			self.dmg = 10000;
	}
	if (self.spawnflags & DOOR_KEY_SILVER)
		self.items |= IT_KEY1;

	if (self.spawnflags & DOOR_KEY_BLOOD)
		self.items |= IT_KEY3;

	if (self.dmg && (!self.message))
		self.message = "was squished";
	if (self.dmg && (!self.message2))
		self.message2 = "was squished by";

	if (self.sounds > 0) {
		precache_sound("plats/medplat1.wav");
		precache_sound("plats/medplat2.wav");
		self.noise2 = "plats/medplat1.wav";
		self.noise1 = "plats/medplat2.wav";
	}
	if (!self.speed)
		self.speed = cvar("sv_door_default_speed");

	if (!self.wait)
		self.wait = 3;

	if (!self.lip)
		self.lip = 8;

	func_button_pos_setup();
	// DOOR_START_OPEN is to allow an entity to be lighted in the closed position
	// but spawn in the open position
	if (self.spawnflags & DOOR_START_OPEN)
		entity_initialize(self, func_door_init_startopen, INITPRIO_SETLOCATION);

	self.state = FUNC_STATE_BOTTOM;
	self.touch = func_door_touch;
	entity_initialize(self, func_doors_link, INITPRIO_LINKDOORS);
	self.reset = func_door_reset;
}

/*QUAKED spawnfunc_func_door_rotating (0 .5 .8) ? START_OPEN BIDIR DOOR_DONT_LINK BIDIR_IN_DOWN x TOGGLE X_AXIS Y_AXIS
if two doors touch, they are assumed to be connected and operate as a unit.

TOGGLE causes the door to wait in both the start and end states for a trigger event.

BIDIR makes the door work bidirectional, so that the opening direction is always away from the requestor.
The usage of bidirectional doors requires two manually instantiated triggers (trigger_multiple), the one to open it in the other direction
must have set trigger_reverse to 1.
BIDIR_IN_DOWN will the door prevent from reopening while closing if it is triggered from the other side.

START_OPEN causes the door to move to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not usefull for touch or takedamage doors).

"message"	is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"		determines the destination angle for opening. negative values reverse the direction.
"targetname"    if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"	if set, door must be shot open
"speed"		movement speed (100 default)
"wait"		wait before returning (3 default, -1 = never return)
"dmg"		damage to inflict when blocked (2 default)
"sounds"
0)	no sound
1)	stone
2)	base
3)	stone chain
4)	screechy metal
FIXME: only one sound set available at the time being
*/

void(void) func_door_rotating_reset {
	self.angles = self.pos1;
	self.avelocity = '0 0 0';
	self.state = FUNC_STATE_BOTTOM;
	self.think = stdproc_nothing;
}

void(void) func_door_rotating_init_startopen {
	self.angles = self.movedir;
	self.pos2 = '0 0 0';
	self.pos1 = self.movedir;
}

void(void) spawnfunc_func_door_rotating {
	func_door_rm_hack();
	// I abuse "movedir" for denoting the axis for now
	if (self.spawnflags & 64) // X (untested)
		self.movedir = '0 0 1';
	else if (self.spawnflags & 128) // Y (untested)
		self.movedir = '1 0 0';
	else // Z
		self.movedir = '0 1 0';

	if (self.angles_y==0) self.angles_y = 90;
	self.movedir = self.movedir * self.angles_y;
	self.angles = '0 0 0';
	self.max_health = self.health;
	if not(func_moving_brush_init())
		return;

	//self.effects |= EFFECT_LOWPRECISION;
	self.classname = "door_rotating";
	self.blocked = func_door_blocked;
	self.use = func_door_use;
	if (self.spawnflags & 8)
		self.dmg = 10000;

	if (self.dmg && (!self.message))
		self.message = "was squished";
	if (self.dmg && (!self.message2))
		self.message2 = "was squished by";

	if (self.sounds > 0) {
		self.noise2 = "plats/medplat1.wav";
		self.noise1 = "plats/medplat2.wav";
	}
	if (self.noise1)
		precache_sound(self.noise1);

	if (self.noise2)
		precache_sound(self.noise2);

	if (!self.speed)
		self.speed = 50;

	if (!self.wait)
		self.wait = 1;

	self.lip = 0; // self.lip is used to remember reverse opening direction for door_rotating
	self.pos1 = '0 0 0';
	self.pos2 = self.movedir;
	// DOOR_START_OPEN is to allow an entity to be lighted in the closed position
	// but spawn in the open position
	if (self.spawnflags & DOOR_START_OPEN)
		entity_initialize(self, func_door_rotating_init_startopen, INITPRIO_SETLOCATION);

	self.state = FUNC_STATE_BOTTOM;
	if (self.health) {
		self.takedamage = DAMAGE_YES;
		self.event_damage = func_door_damage;
	}
	self.touch = func_door_touch;
	// func_doors_link can't be done until all of the doors have been spawned, so
	// the sizes can be detected properly.
	entity_initialize(self, func_doors_link, INITPRIO_LINKDOORS);
	self.reset = func_door_rotating_reset;
}

void(void) func_door_secret_move1;
void(void) func_door_secret_move2;
void(void) func_door_secret_move3;
void(void) func_door_secret_move4;
void(void) func_door_secret_move5;
void(void) func_door_secret_move6;
void(void) func_door_secret_done;

float SECRET_OPEN_ONCE = 1;  // stays open
float SECRET_1ST_LEFT = 2;   // 1st move is left of arrow
float SECRET_1ST_DOWN = 4;   // 1st move is down from arrow
float SECRET_NO_SHOOT = 8;   // only opened by trigger
float SECRET_YES_SHOOT = 16; // shootable even if targeted

void(void) func_door_secret_use {
	float temp;
	string message_save;
	self.health = 10000;
	self.bot_attack = TRUE;
	// exit if still moving around...
	if (self.origin != self.oldorigin)
		return;

	message_save = self.message;
	self.message = ""; // no more message
	trigger_use_targets(); // fire all targets / killtargets
	self.message = message_save;
	self.velocity = '0 0 0';
	// Make a sound, wait a little...
	if (self.noise1 != "")
		sound(self, CHAN_TRIGGER, self.noise1, VOL_BASE, ATTN_NORM);

	self.nextthink = self.ltime + sys_ticrate;
	temp = 1 - (self.spawnflags & SECRET_1ST_LEFT); // 1 or -1
	makevectors(self.mangle);
	if (!self.t_width) {
		if (self.spawnflags & SECRET_1ST_DOWN)
			self.t_width = fabs(v_up * self.size);
		else
			self.t_width = fabs(v_right * self.size);
	}
	if (!self.t_length)
		self.t_length = fabs(v_forward * self.size);

	if (self.spawnflags & SECRET_1ST_DOWN)
		self.dest1 = self.origin - v_up * self.t_width;
	else
		self.dest1 = self.origin + v_right * (self.t_width * temp);

	self.dest2 = self.dest1 + v_forward * self.t_length;
	func_calc_move(self.dest1, self.speed, func_door_secret_move1);
	if (self.noise2 != "")
		sound(self, CHAN_TRIGGER, self.noise2, VOL_BASE, ATTN_NORM);
}

// Wait after first movement...
void(void) func_door_secret_move1 {
	self.nextthink = self.ltime + 1.0;
	self.think = func_door_secret_move2;
	if (self.noise3 != "")
		sound(self, CHAN_TRIGGER, self.noise3, VOL_BASE, ATTN_NORM);
}

// Start moving sideways w/sound...
void(void) func_door_secret_move2 {
	if (self.noise2 != "")
		sound(self, CHAN_TRIGGER, self.noise2, VOL_BASE, ATTN_NORM);

	func_calc_move(self.dest2, self.speed, func_door_secret_move3);
}

// Wait here until time to go back...
void(void) func_door_secret_move3 {
	if (self.noise3 != "")
		sound(self, CHAN_TRIGGER, self.noise3, VOL_BASE, ATTN_NORM);

	if (!(self.spawnflags & SECRET_OPEN_ONCE)) {
		self.nextthink = self.ltime + self.wait;
		self.think = func_door_secret_move4;
	}
}

// Move backward...
void(void) func_door_secret_move4 {
	if (self.noise2 != "")
		sound(self, CHAN_TRIGGER, self.noise2, VOL_BASE, ATTN_NORM);

	func_calc_move(self.dest1, self.speed, func_door_secret_move5);
}

// Wait 1 second...
void(void) func_door_secret_move5 {
	self.nextthink = self.ltime + 1.0;
	self.think = func_door_secret_move6;
	if (self.noise3 != "")
		sound(self, CHAN_TRIGGER, self.noise3, VOL_BASE, ATTN_NORM);
}

void(void) func_door_secret_move6 {
	if (self.noise2 != "")
		sound(self, CHAN_TRIGGER, self.noise2, VOL_BASE, ATTN_NORM);

	func_calc_move(self.oldorigin, self.speed, func_door_secret_done);
}

void(void) func_door_secret_done {
	if (self.spawnflags&SECRET_YES_SHOOT) {
		self.health = 10000;
		self.takedamage = DAMAGE_YES;
		//self.th_pain = func_door_secret_use;
	}
	if (self.noise3 != "")
		sound(self, CHAN_TRIGGER, self.noise3, VOL_BASE, ATTN_NORM);
}

void(void) func_secret_blocked {
	if (time < self.attack_finished_single)
		return;

	self.attack_finished_single = time + 0.5;
}

void(void) func_secret_touch {
	if not(other.iscreature)
		return;

	if (self.attack_finished_single > time)
		return;

	self.attack_finished_single = time + 2;
	if (self.message) {
		if (clienttype(other) == CLIENTTYPE_REAL) {
			centerprint(other, self.message);
			sound_play2(other, "misc/talk.wav");
		}
	}
}

void(void) func_secret_reset {
	if (self.spawnflags & SECRET_YES_SHOOT) {
		self.health = 10000;
		self.takedamage = DAMAGE_YES;
	}
	setorigin(self, self.oldorigin);
	self.think = stdproc_nothing;
}

/*QUAKED spawnfunc_func_door_secret (0 .5 .8) ? open_once 1st_left 1st_down no_shoot always_shoot
Basic secret door. Slides back, then to the side. Angle determines direction.
wait  = # of seconds before coming back
1st_left = 1st move is left of arrow
1st_down = 1st move is down from arrow
always_shoot = even if targeted, keep shootable
t_width = override WIDTH to move back (or height if going down)
t_length = override LENGTH to move sideways
"dmg"		damage to inflict when blocked (2 default)

If a secret door has a targetname, it will only be opened by it's botton or trigger, not by damage.
"sounds"
1) medieval
2) metal
3) base
*/

void(entity, entity, float, float, vector, vector) func_door_secret_event_damage {
	func_door_secret_use();
}

void(void) spawnfunc_func_door_secret {
	if (!self.dmg)
		self.dmg = 2;

	self.mangle = self.angles;
	self.angles = '0 0 0';
	self.classname = "door";
	if not(func_moving_brush_init())
		return;

	self.effects |= EFFECT_LOWPRECISION;
	self.touch = func_secret_touch;
	self.blocked = func_secret_blocked;
	self.speed = 50;
	self.use = func_door_secret_use;
	IFTARGETED {
	} else
		self.spawnflags |= SECRET_YES_SHOOT;

	if (self.spawnflags & SECRET_YES_SHOOT) {
		self.health = 10000;
		self.takedamage = DAMAGE_YES;
		self.event_damage = func_door_secret_event_damage;
	}
	self.oldorigin = self.origin;
	if (!self.wait)
		self.wait = 5; // 5 seconds before closing

	self.reset = func_secret_reset;
	func_secret_reset();
}

/*QUAKED spawnfunc_func_fourier (0 .5 .8) ?
Brush model that moves in a pattern of added up sine waves, can be used e.g. for circular motions.
netname: list of <frequencymultiplier> <phase> <x> <y> <z> quadruples, separated by spaces; note that phase 0 represents a sine wave, and phase 0.25 a cosine wave (by default, it uses 1 0 0 0 1, to match func_bobbing's defaults
speed: how long one cycle of frequency multiplier 1 in seconds (default 4)
height: amplitude modifier (default 32)
phase: cycle timing adjustment (0-1 as a fraction of the cycle, default 0)
noise: path/name of looping .wav file to play.
dmg: Do this mutch dmg every .dmgtime intervall when blocked
dmgtime: See above.
*/

void(void) func_fourier_controller_think {
	vector v;
	float n, i, t;
	self.nextthink = time + 0.1;
	n = floor((tokenize_console(self.owner.netname)) / 5);
	t = self.nextthink * self.owner.cnt + self.owner.phase * 360;
	v = self.owner.destvec;
	for (i = 0; i < n; ++i) {
		makevectors((t * stof(argv(i*5)) + stof(argv(i*5+1)) * 360) * '0 1 0');
		v = v + ('1 0 0' * stof(argv(i*5+2)) + '0 1 0' * stof(argv(i*5+3)) + '0 0 1' * stof(argv(i*5+4))) * self.owner.height * v_forward_y;
	}
	// * 10 so it will arrive in 0.1 sec
	self.owner.velocity = (v - self.owner.origin) * 10;
}

void(void) spawnfunc_func_fourier {
	entity controller;
	if (self.noise != "") {
		precache_sound(self.noise);
		sound_to(MSG_INIT, self, CHAN_TRIGGER, self.noise, VOL_BASE, ATTN_IDLE);
	}
	if (!self.speed)
		self.speed = 4;

	if (!self.height)
		self.height = 32;

	self.destvec = self.origin;
	self.cnt = 360 / self.speed;
	self.blocked = func_generic_plat_blocked;
	if (self.dmg & (!self.message))
		self.message = " was squished";

	if (self.dmg && (!self.message2))
		self.message2 = "was squished by";

	if (self.dmg && (!self.dmgtime))
		self.dmgtime = 0.25;

	self.dmgtime2 = time;
	if (self.netname == "")
		self.netname = "1 0 0 0 1";

	if not(func_moving_brush_init())
		return;

	// wait for targets to spawn
	controller = spawn();
	controller.classname = "func_fourier_controller";
	controller.owner = self;
	controller.nextthink = time + 1;
	controller.think = func_fourier_controller_think;
	self.nextthink = self.ltime + 999999999;
	self.think = stdproc_nothing;
	// Savage: Reduce bandwith, critical on e.g. nexdm02
	self.effects |= EFFECT_LOWPRECISION;
	// TODO make a reset function for this one
}

// reusing some fields havocbots declared
.entity wp00, wp01, wp02, wp03;

.float targetfactor, target2factor, target3factor, target4factor;
.vector targetnormal, target2normal, target3normal, target4normal;

vector(entity o, float t) func_vectormamamam_origin {
	vector v, p;
	float f;
	entity e;
	f = o.spawnflags;
	v = '0 0 0';
	e = o.wp00;
	if (e) {
		p = e.origin + t * e.velocity;
		if (f & 1)
			v = v + (p * o.targetnormal) * o.targetnormal * o.targetfactor;
		else
			v = v + (p - (p * o.targetnormal) * o.targetnormal) * o.targetfactor;
	}
	e = o.wp01;
	if (e) {
		p = e.origin + t * e.velocity;
		if (f & 2)
			v = v + (p * o.target2normal) * o.target2normal * o.target2factor;
		else
			v = v + (p - (p * o.target2normal) * o.target2normal) * o.target2factor;
	}
	e = o.wp02;
	if (e) {
		p = e.origin + t * e.velocity;
		if (f & 4)
			v = v + (p * o.target3normal) * o.target3normal * o.target3factor;
		else
			v = v + (p - (p * o.target3normal) * o.target3normal) * o.target3factor;
	}
	e = o.wp03;
	if (e) {
		p = e.origin + t * e.velocity;
		if (f & 8)
			v = v + (p * o.target4normal) * o.target4normal * o.target4factor;
		else
			v = v + (p - (p * o.target4normal) * o.target4normal) * o.target4factor;
	}
	return v;
}

void(void) func_vectormamamam_controller_think {
	self.nextthink = time + 0.1;
	self.owner.velocity = (self.owner.destvec + func_vectormamamam_origin(self.owner, 0.1) - self.owner.origin) * 10;
}

void(void) func_vectormamamam_findtarget {
	if (self.target != "")
		self.wp00 = find(world, targetname, self.target);

	if (self.target2 != "")
		self.wp01 = find(world, targetname, self.target2);

	if (self.target3 != "")
		self.wp02 = find(world, targetname, self.target3);

	if (self.target4 != "")
		self.wp03 = find(world, targetname, self.target4);

	if (!self.wp00 && !self.wp01 && !self.wp02 && !self.wp03) {
		entity_abort("No reference entity found, so there is nothing to move. Aborting.");
		return;
	}
	self.destvec = self.origin - func_vectormamamam_origin(self.owner, 0);
	entity controller;
	controller = spawn();
	controller.classname = "func_vectormamamam_controller";
	controller.owner = self;
	controller.nextthink = time + 1;
	controller.think = func_vectormamamam_controller_think;
}

void(void) spawnfunc_func_vectormamamam {
	if (self.noise != "") {
		precache_sound(self.noise);
		sound_to(MSG_INIT, self, CHAN_TRIGGER, self.noise, VOL_BASE, ATTN_IDLE);
	}
	if (!self.targetfactor)
		self.targetfactor = 1;

	if (!self.target2factor)
		self.target2factor = 1;

	if (!self.target3factor)
		self.target3factor = 1;

	if (!self.target4factor)
		self.target4factor = 1;

	if (vlen(self.targetnormal))
		self.targetnormal = normalize(self.targetnormal);

	if (vlen(self.target2normal))
		self.target2normal = normalize(self.target2normal);

	if (vlen(self.target3normal))
		self.target3normal = normalize(self.target3normal);

	if (vlen(self.target4normal))
		self.target4normal = normalize(self.target4normal);

	self.blocked = func_generic_plat_blocked;
	if (self.dmg & (!self.message))
		self.message = " was squished";

    if (self.dmg && (!self.message2))
		self.message2 = "was squished by";

	if (self.dmg && (!self.dmgtime))
		self.dmgtime = 0.25;

	self.dmgtime2 = time;

	if (self.netname == "")
		self.netname = "1 0 0 0 1";

	if not(func_moving_brush_init())
		return;

	// wait for targets to spawn
	self.nextthink = self.ltime + 999999999;
	self.think = stdproc_nothing;
	// Savage: Reduce bandwith, critical on e.g. nexdm02
	self.effects |= EFFECT_LOWPRECISION;
	entity_initialize(self, func_vectormamamam_findtarget, INITPRIO_FINDTARGET);
}

void(void) func_moveentity_think {
	vector v = self.enemy.origin;
	float f = self.speed * frametime;
	v_x = approach(v_x, self.origin_x, f);
	v_y = approach(v_y, self.origin_y, f);
	v_z = approach(v_z, self.origin_z, f);
	setorigin(self.enemy, v);
	if (v == self.origin)
		return;

	self.nextthink = time;
}

void(void) func_moveentity_use {
	self.enemy = find(world, targetname, self.target);
	if not(self.enemy)
		return;

	self.think();
}

void(void) spawnfunc_func_moveentity {
	self.use = func_moveentity_use;
	self.think = func_moveentity_think;
}

void(void) func_timer_think {
	activator = self.enemy;
	trigger_use_targets();
	self.nextthink = time + self.wait;
}

void(void) func_timer_use {
	self.enemy = activator;
	if (self.nextthink) {
		self.nextthink = 0;
		return;
	}
	func_timer_think();
}

void(void) func_timer_reset {
	self.enemy = NULL;
	if (self.spawnflags & 1) {
		self.nextthink = time + sys_ticrate;
	} else
		self.nextthink = 0;
}

void(void) spawnfunc_func_timer {
	self.think = func_timer_think;
	self.use = func_timer_use;
	self.reset = func_timer_reset;
	if (self.spawnflags & 1) {
		self.nextthink = time + sys_ticrate;
	}
	if (self.targetname != "")
		ENTITY_PER_PLAYER_FORCE();
}
