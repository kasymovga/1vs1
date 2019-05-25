// non-solid brush entities:
void(void) spawnfunc_func_illusionary       { model_init      (SOLID_NOT);} // Q1 name (WARNING: MISPREDICTED)
void(void) spawnfunc_func_clientillusionary { model_client_init(SOLID_NOT);} // brush entity
void(void) spawnfunc_func_static            { model_init      (SOLID_NOT);} // DEPRECATED old alias name from some other game

// solid brush entities
void(void) spawnfunc_func_wall              { model_init      (SOLID_BSP);} // Q1 name
void(void) spawnfunc_func_clientwall        { model_client_init(SOLID_BSP);} // brush entity (WARNING: MISPREDICTED)

void(void) spawnfunc_func_stardust {
	self.effects = EF_STARDUST;
}

float(entity to, float fl) func_pointparticles_send {
	WriteByte(MSG_ENTITY, ENT_CLIENT_POINTPARTICLES);
	// optional features to save space
	fl = fl & 0x0F;
	if(self.spawnflags & 2)
		fl |= 0x10; // absolute count on toggle-on

	if(self.movedir != '0 0 0' || self.velocity != '0 0 0')
		fl |= 0x20; // 4 bytes - saves CPU

	if(self.waterlevel || self.count != 1)
		fl |= 0x40; // 4 bytes - obscure features almost never used

	if(self.mins != '0 0 0' || self.maxs != '0 0 0')
		fl |= 0x80; // 14 bytes - saves lots of space

	WriteByte(MSG_ENTITY, fl);
	if(fl & 2) {
		if(self.state)
			WriteCoord(MSG_ENTITY, self.impulse);
		else
			WriteCoord(MSG_ENTITY, 0); // off
	}
	if(fl & 4) {
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);
	}
	if(fl & 1) {
		if(self.model != "null") {
			WriteShort(MSG_ENTITY, self.modelindex);
			if(fl & 0x80) {
				WriteCoord(MSG_ENTITY, self.mins_x);
				WriteCoord(MSG_ENTITY, self.mins_y);
				WriteCoord(MSG_ENTITY, self.mins_z);
				WriteCoord(MSG_ENTITY, self.maxs_x);
				WriteCoord(MSG_ENTITY, self.maxs_y);
				WriteCoord(MSG_ENTITY, self.maxs_z);
			}
		} else {
			WriteShort(MSG_ENTITY, 0);
			if(fl & 0x80) {
				WriteCoord(MSG_ENTITY, self.maxs_x);
				WriteCoord(MSG_ENTITY, self.maxs_y);
				WriteCoord(MSG_ENTITY, self.maxs_z);
			}
		}
		WriteShort(MSG_ENTITY, self.cnt);
		if(fl & 0x20) {
			WriteShort(MSG_ENTITY, net_compress_vec(self.velocity));
			WriteShort(MSG_ENTITY, net_compress_vec(self.movedir));
		}
		if(fl & 0x40) {
			WriteShort(MSG_ENTITY, self.waterlevel * 16.0);
			WriteByte(MSG_ENTITY, self.count * 16.0);
		}
		WriteString(MSG_ENTITY, self.noise);
		if(self.noise != "") {
			WriteByte(MSG_ENTITY, floor(self.atten * 64));
			WriteByte(MSG_ENTITY, floor(self.volume * 255));
		}
		WriteString(MSG_ENTITY, self.bgmscript);
		if(self.bgmscript != "") {
			WriteByte(MSG_ENTITY, floor(self.bgmscriptattack * 64));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptdecay * 64));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptsustain * 255));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptrelease * 64));
		}
	}
	return 1;
}

void(void) fucn_pointparticles_use {
	self.state = !self.state;
	self.SendFlags |= 2;
}

void(void) func_pointparticles_think {
	if(self.origin != self.oldorigin) {
		self.SendFlags |= 4;
		self.oldorigin = self.origin;
	}
	self.nextthink = time;
}

void(void) func_pointparticles_reset {
	if(self.spawnflags & 1)
		self.state = 1;
	else
		self.state = 0;
}

void(void) spawnfunc_func_pointparticles {
	if(self.model != "")
		setmodel(self, self.model);

	if(self.noise != "")
		precache_sound (self.noise);

	if(!self.bgmscriptsustain)
		self.bgmscriptsustain = 1;
	else if(self.bgmscriptsustain < 0)
		self.bgmscriptsustain = 0;

	if(!self.atten)
		self.atten = ATTN_NORM;
	else if(self.atten < 0)
		self.atten = 0;

	if(!self.volume)
		self.volume = 1;

	if(!self.count)
		self.count = 1;

	if(!self.impulse)
		self.impulse = 1;

	if(!self.modelindex) {
		setorigin(self, self.origin + self.mins);
		setsize(self, '0 0 0', self.maxs - self.mins);
	}
	if(!self.cnt)
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
	if(self.cnt < 1) {
		self.cnt = 25.0; // nice default value
	}
	// self.wait is the probability that a sparkthink will spawn a spark shower
	// range: 0 - 1, but 0 makes little sense, so...
	if(self.wait < 0.05) {
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
	WriteByte(MSG_ENTITY, ENT_CLIENT_RAINSNOW);
	WriteByte(MSG_ENTITY, self.state);
	WriteCoord(MSG_ENTITY, self.origin_x + self.mins_x);
	WriteCoord(MSG_ENTITY, self.origin_y + self.mins_y);
	WriteCoord(MSG_ENTITY, self.origin_z + self.mins_z);
	WriteCoord(MSG_ENTITY, self.maxs_x - self.mins_x);
	WriteCoord(MSG_ENTITY, self.maxs_y - self.mins_y);
	WriteCoord(MSG_ENTITY, self.maxs_z - self.mins_z);
	WriteShort(MSG_ENTITY, net_compress_vec(self.dest));
	WriteShort(MSG_ENTITY, self.count);
	WriteByte(MSG_ENTITY, self.cnt);
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
	SetBrushEntityModel();
	if (!self.cnt)
		self.cnt = 12;

	if (!self.count)
		self.count = 2000;

	self.count = 0.01 * self.count * (self.size_x / 1024) * (self.size_y / 1024);
	if (self.count < 1)
		self.count = 1;

	if(self.count > 65535)
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
	SetBrushEntityModel();
	if (!self.cnt)
		self.cnt = 12;

	if (!self.count)
		self.count = 2000;

	self.count = 0.01 * self.count * (self.size_x / 1024) * (self.size_y / 1024);
	if (self.count < 1)
		self.count = 1;

	if(self.count > 65535)
		self.count = 65535;

	self.state = 0; // 1 is rain, 0 is snow
	net_link_entity(self, FALSE, 0, func_rainsnow_send);
}

void(void) func_ladder_touch {
	if not(other.iscreature)
		return;

	EXACTTRIGGER_TOUCH;
	other.ladder_time = time + 0.1;
	other.ladder_entity = self;
}

void(void) spawnfunc_func_ladder {
	EXACTTRIGGER_INIT;
	self.touch = func_ladder_touch;
}

void(void) spawnfunc_func_water {
	EXACTTRIGGER_INIT;
	self.touch = func_ladder_touch;
}

void(void) func_nowalljump_touch {
	if(other.classname == "player")
		other.lastwj = time + frametime;
}

void(void) spawnfunc_func_nowalljump {
    EXACTTRIGGER_INIT;
    self.touch = func_nowalljump_touch;
}

/*
 * magicwall
 */

.float alpha_solid;
.float alpha_nonsolid;
.float oldsolid;

#define MAGICWALL_ALPHAFIELD(e) (if((e).solid == SOLID_BSP) alpha_solid else alpha_nonsolid)

#define SPAWNFLAG_MW_START_HIDDEN 4
#define SPAWNFLAG_MW_TOGGLE 8

void func_magicwall_think_transition(void) {
    self.alpha = approach(self.alpha, self.MAGICWALL_ALPHAFIELD(self), self.speed * frametime);
    if(self.alpha && self.alpha < self.alpha_solid)
        self.nextthink = time;
    else if(self.think1)
        self.think1();
}

void func_magicwall_start_transition(float sol, void(void) done) {
    self.solid = sol;

    if(!sol)
        dropentities(self);

    if(self.speed < 0) {
        self.alpha = self.MAGICWALL_ALPHAFIELD(self);
        if(done)
            done();
        return;
    }

    self.think = func_magicwall_think_transition;
    self.think1 = done;
    self.nextthink = time;
}

void spawnfunc_func_magicwall(void) {
    model_init(SOLID_BSP);

    if(self.alpha_solid <= 0)
        self.alpha_solid = 1;

    if(self.alpha_nonsolid < 0)
        self.alpha_nonsolid = 0;

    if(!self.wait && self.target == "")
        self.wait = self.delay;

    if(!self.wait)
        self.wait = 3;

    if(!self.speed)
        self.speed = 1;

    self.oldsolid = if(self.spawnflags & SPAWNFLAG_MW_START_HIDDEN) SOLID_NOT else SOLID_BSP;

    self.customizeentityforclient = inline float(void) {
        return (self.alpha > 0);
    };

    self.think = inline void(void) {
        self.nextthink = time;
        self.alpha = approach(self.alpha, self.MAGICWALL_ALPHAFIELD(self), self.speed * frametime);
    };

    self.reset = inline void(void) {
        self.solid = self.oldsolid;
        self.alpha = self.MAGICWALL_ALPHAFIELD(self);
        self.think = SUB_Null;
    };

    self.use = if(self.spawnflags & SPAWNFLAG_MW_TOGGLE)
        inline void(void) {
            func_magicwall_start_transition(if(self.solid == SOLID_BSP) SOLID_NOT else SOLID_BSP, func_null);
        } else inline void(void) {
            if(self.oldsolid != self.solid) {
                if(self.think && self.think != func_magicwall_think_transition)
                    self.nextthink = time + self.wait;
                return;
            }

            func_magicwall_start_transition(if(self.oldsolid == SOLID_BSP) SOLID_NOT else SOLID_BSP,
                if(self.wait >= 0) inline void(void) {
                    self.nextthink = time + self.wait;
                    self.think = inline void(void) {
                        func_magicwall_start_transition(self.oldsolid, func_null);
                    };
                } else func_null);
        };

    self.touch = inline void(void) {
        if(other.classname == "player" && !PLAYER_DEAD(other))
            using(activator = other)
                trigger_use_targets();
    };

    // self.clipgroup = CLIPGROUP_OBSERVER;
    self.reset();
    self.nextthink = time;
}

