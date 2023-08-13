// non-solid model entities:
void(void) spawnfunc_misc_gamemodel         { model_init      (SOLID_NOT);} // model entity
void(void) spawnfunc_misc_clientmodel       { model_client_init(SOLID_NOT);} // model entity
void(void) spawnfunc_misc_models            { model_init      (SOLID_NOT);} // DEPRECATED old compat entity with confusing name, do not use

void(entity e, entity to, string tag) misc_attach_sameorigin {
    vector org, t_forward, t_left, t_up, e_forward, e_up;
    vector org0, ang0;
    float tagscale;
    ang0 = e.angles;
    org0 = e.origin;
    org = e.origin - gettaginfo(to, gettagindex(to, tag));
    tagscale = pow(vlen(v_forward), -2); // undo a scale on the tag
    t_forward = v_forward * tagscale;
    t_left = v_right * -tagscale;
    t_up = v_up * tagscale;
    e.origin_x = org * t_forward;
    e.origin_y = org * t_left;
    e.origin_z = org * t_up;
    // current forward and up directions
    if not(substring(e.model, 0, 1) == "*") // bmodels have their own rules
        e.angles_x = -e.angles_x;

    makevectors(e.angles);
    // untransform forward, up!
    e_forward_x = v_forward * t_forward;
    e_forward_y = v_forward * t_left;
    e_forward_z = v_forward * t_up;
    e_up_x = v_up * t_forward;
    e_up_y = v_up * t_left;
    e_up_z = v_up * t_up;
    e.angles = vectoangles(e_forward, e_up);
    if (substring(e.model, 0, 1) == "*") // bmodels have their own rules
        e.angles_x = -e.angles_x;

    setattachment(e, to, tag);
    setorigin(e, e.origin);
}

void(entity e, entity to) misc_follow_sameorigin {
    e.movetype = MOVETYPE_FOLLOW; // make the hole follow
    e.aiment = to; // make the hole follow bmodel
    e.punchangle = to.angles; // the original angles of bmodel
    e.view_ofs = e.origin - to.origin; // relative origin
    e.v_angle = e.angles - to.angles; // relative angles
}

void(void) misc_follow_init {
	entity src, dst;
	src = find(world, targetname, self.killtarget);
	dst = find(world, targetname, self.target);
	if(!src || !dst) {
		entity_abort("follow: could not find target/killtarget");
		return;
	}
	if(self.spawnflags & 1) {
		// attach
		if(self.spawnflags & 2) {
			setattachment(dst, src, self.message);
		} else {
			misc_attach_sameorigin(dst, src, self.message);
		}
	} else {
		if(self.spawnflags & 2) {
			dst.movetype = MOVETYPE_FOLLOW;
			dst.aiment = src;
			// dst.punchangle = '0 0 0'; // keep unchanged
			dst.view_ofs = dst.origin;
			dst.v_angle = dst.angles;
		} else {
			misc_follow_sameorigin(dst, src);
		}
	}
	remove(self);
}

void(void) spawnfunc_misc_follow {
	entity_initialize(self, misc_follow_init, INITPRIO_FINDTARGET);
}

void misc_spikeshooter_spike_touch(void) {
	PROJECTILE_TOUCH;
	if(other.solid == SOLID_BSP)
		effect_impact(self.origin, self.dmg, 0, 0, normalize(self.velocity), EFFECT_IMPACT_BULLET, self);
	if (other && other.takedamage) {
		damage(other, self, world, 20, WEAPON_UZI, self.origin, 20 * normalize(self.velocity));
	}
	remove(self);
}

void misc_spikeshooter_use(void) {
	entity spike = projectile(TRUE, PROJECTILE_BULLET_BIG, TRUE, world);
	projectile_setup(spike, self.origin, EFFECT_IMPACT_BULLET, WEAPON_UZI, 20,
			20, 0, 20, 0, MOVETYPE_FLY);
	spike.velocity = self.movedir * 800;
	spike.think = stdproc_remove;
	spike.nextthink = time + 10;
	spike.touch = misc_spikeshooter_spike_touch;
	sound (self, CHAN_WEAPON, "weapons/uzi_fire.wav", VOL_BASE, ATTN_NORM);
}

void(void) spawnfunc_misc_spikeshooter {
	makevectors(self.angles);
	self.movedir = normalize(v_forward);
	self.use = misc_spikeshooter_use;
	precache_sound("weapons/uzi_fire.wav");
}

void(void) misc_lightning_spark {
	if (time > self.attack_finished_single) {
		sound_stop(self, CHAN_TRIGGER);
		sound_stop(self.enemy, CHAN_TRIGGER);
		return;
	}
	self.nextthink = time + 0.1;
	net_write_byte(MSG_BROADCAST, SVC_TEMPENTITY);
	net_write_byte(MSG_BROADCAST, NET_TE_CSQC_BIGLIGHTNINGARC);
	net_write_coord(MSG_BROADCAST, self.origin_x);
	net_write_coord(MSG_BROADCAST, self.origin_y);
	net_write_coord(MSG_BROADCAST, self.origin_z);
	net_write_coord(MSG_BROADCAST, self.enemy.origin_x);
	net_write_coord(MSG_BROADCAST, self.enemy.origin_y);
	net_write_coord(MSG_BROADCAST, self.enemy.origin_z);
}

void(void) misc_lightning_use {
	if (self.nextthink)
		return;

	sound(self, CHAN_TRIGGER, "ambient/sparks1.ogg", VOL_BASE, ATTN_NORM);
	sound(self.enemy, CHAN_TRIGGER, "ambient/sparks1.ogg", VOL_BASE, ATTN_NORM);
	self.attack_finished_single = time + 0.5;
	misc_lightning_spark();
}

void(void) misc_lightning_findtarget {
	self.enemy = find(world, targetname, self.target);
}

void(void) spawnfunc_misc_lightning {
	entity_initialize(self, misc_lightning_findtarget, INITPRIO_FINDTARGET);
	self.use = misc_lightning_use;
	self.think = misc_lightning_spark;
	precache_sound("ambient/sparks1.ogg");
	dlc_require("rm_effects_v2");
}

//Q2 compat
void(void) spawnfunc_misc_teleporter {
	entity e = spawn();
	e.scale = 2;
	setorigin(e, self.origin);
	setmodel(e, "models/ebomb.mdl");
	setsize(self, '-32 -32 -48', '32 32 48');
	spawnfunc_trigger_teleport();
}

.float modelscale;
void(void) misc_laser_aim {
	vector a;
	if (self.enemy) {
		if (self.spawnflags & 2) {
			if(self.enemy.origin != self.mangle) {
				self.mangle = self.enemy.origin;
				self.SendFlags |= 2;
			}
		} else {
			a = vectoangles(self.enemy.origin - self.origin);
			a_x = -a_x;
			if(a != self.mangle) {
				self.mangle = a;
				self.SendFlags |= 2;
			}
		}
	} else {
		if (self.angles != self.mangle) {
			self.mangle = self.angles;
			self.SendFlags |= 2;
		}
	}
	if (self.origin != self.oldorigin) {
		self.SendFlags |= 1;
		self.oldorigin = self.origin;
	}
}

void(void) misc_laser_init {
	if (self.target != "")
		self.enemy = find(world, targetname, self.target);
}

.entity pusher;
void(void) misc_laser_think {
	vector o;
	entity oldself;
	self.nextthink = time;
	if (!self.state)
		return;

	misc_laser_aim();
	if (self.enemy) {
		o = self.enemy.origin;
		if not(self.spawnflags & 2)
			o = self.origin + normalize(o - self.origin) * 32768;
	} else {
		makevectors(self.mangle);
		o = self.origin + v_forward * 32768;
	}
	if (self.dmg) {
		if (self.dmg < 0)
			bullet_railgun(self.origin, o, 100000, 0, 0, 0, 0, 0, DEATH_HURTTRIGGER);
		else
			bullet_railgun(self.origin, o, self.dmg * frametime, 0, 0, 0, 0, 0, DEATH_HURTTRIGGER);
	}
	if (self.enemy.target != "") { // DETECTOR laser
		trace_line(self.origin, o, TRACE_MOVE_NORMAL, self);
		if (trace_ent.iscreature) {
			self.pusher = trace_ent;
			if (!self.count) {
				self.count = 1;
				oldself = self;
				self = self.enemy;
				activator = self.pusher;
				trigger_use_targets();
				self = oldself;
			}
		} else {
			if (self.count) {
				self.count = 0;
				oldself = self;
				self = self.enemy;
				activator = self.pusher;
				trigger_use_targets();
				self = oldself;
			}
		}
	}
}

float(entity to, float fl) misc_laser_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_LASER);
	fl = fl - (fl & 0xE0); // use that bit to indicate finite length laser
	if (self.spawnflags & 2)
		fl |= 0x80;

	if (self.alpha)
		fl |= 0x40;

	if (self.scale != 1 || self.modelscale != 1)
		fl |= 0x20;

	net_write_byte(MSG_ENTITY, fl);
	if(fl & 1) {
		net_write_coord(MSG_ENTITY, self.origin_x);
		net_write_coord(MSG_ENTITY, self.origin_y);
		net_write_coord(MSG_ENTITY, self.origin_z);
	}
	if (fl & 8) {
		net_write_byte(MSG_ENTITY, self.colormod_x * 255.0);
		net_write_byte(MSG_ENTITY, self.colormod_y * 255.0);
		net_write_byte(MSG_ENTITY, self.colormod_z * 255.0);
		if (fl & 0x40)
			net_write_byte(MSG_ENTITY, self.alpha * 255.0);

		if (fl & 0x20) {
			net_write_byte(MSG_ENTITY, bound(0, self.scale * 16.0, 255));
			net_write_byte(MSG_ENTITY, bound(0, self.modelscale * 16.0, 255));
		}
		net_write_short(MSG_ENTITY, self.cnt + 1);
	}
	if (fl & 2) {
		if (fl & 0x80) {
			net_write_coord(MSG_ENTITY, self.enemy.origin_x);
			net_write_coord(MSG_ENTITY, self.enemy.origin_y);
			net_write_coord(MSG_ENTITY, self.enemy.origin_z);
		} else {
			net_write_angle(MSG_ENTITY, self.mangle_x);
			net_write_angle(MSG_ENTITY, self.mangle_y);
		}
	}
	if (fl & 4)
		net_write_byte(MSG_ENTITY, self.state);

	return 1;
}

void(void) misc_laser_use {
	self.state = !self.state;
	self.SendFlags |= 4;
	misc_laser_aim();
}

void(void) misc_laser_reset {
	if (self.spawnflags & 1)
		self.state = 1;
	else
		self.state = 0;
}

/*QUAKED spawnfunc_misc_laser (.5 .5 .5) ? START_ON DEST_IS_FIXED
Any object touching the beam will be hurt
Keys:
"target"
 spawnfunc_target_position where the laser ends
"mdl"
 name of beam end effect to use
"colormod"
 color of the beam (default: red)
"dmg"
 damage per second (-1 for a laser that kills immediately)
*/
void(void) spawnfunc_misc_laser {
	if (self.mdl) {
		if (self.mdl == "none")
			self.cnt = -1;
		else {
			self.cnt = particleeffectnum(self.mdl);
			if (self.cnt < 0)
				if (self.dmg)
					self.cnt = particleeffectnum("laser_deadly");
		}
	} else if (!self.cnt) {
		if (self.dmg)
			self.cnt = particleeffectnum("laser_deadly");
		else
			self.cnt = -1;
	}
	if (self.cnt < 0)
		self.cnt = -1;

	if (self.colormod == '0 0 0')
		if (!self.alpha)
			self.colormod = '1 0 0';

	if (!self.message)
		self.message = "saw the light";

	if (!self.message2)
		self.message2 = "was pushed into a laser by";

	if (!self.scale)
		self.scale = 1;

	if (!self.modelscale)
		self.modelscale = 1;

	self.think = misc_laser_think;
	self.nextthink = time;
	entity_initialize(self, misc_laser_init, INITPRIO_FINDTARGET);
	self.mangle = self.angles;
	net_link_entity(self, FALSE, 0, misc_laser_send);
	IFTARGETED {
		self.reset = misc_laser_reset;
		misc_laser_reset();
		self.use = misc_laser_use;
	} else
		self.state = 1;
}

void(void) spawnfunc_misc_tree {
	precache_model("models/mtree01.md3");
	setmodel(self, "models/mtree01.md3");
	self.solid = SOLID_BBOX;
	setsize(self, '-16 -16 0', '16 16 128');
	entity_droptofloor();
}

void(void) spawnfunc_misc_barrel_explosive {
	precache_model("models/grenademodel.md3");
	setmodel(self, "models/grenademodel.md3");
	self.solid = SOLID_BBOX;
	self.pushfactor = 0.5;
	self.friction = 0.5;
	self.movetype = MOVETYPE_WALK;
	self.dmg = 100;
	self.health = 50;
	self.cnt = particleeffectnum("rocket_explode");
	spawnfunc_func_breakable();
	self.angles = '-90 0 0';
	self.scale = 4;
	setsize(self, '-16 -16 -24', '16 16 24');
	entity_droptofloor();
}
