// non-solid model entities:
void(void) spawnfunc_misc_gamemodel         { model_init      (SOLID_NOT);} // model entity
void(void) spawnfunc_misc_clientmodel       { model_client_init(SOLID_NOT);} // model entity
void(void) spawnfunc_misc_models            { model_init      (SOLID_NOT);} // DEPRECATED old compat entity with confusing name, do not use

void(void) misc_follow_init {
	entity src, dst;
	src = find(world, targetname, self.killtarget);
	dst = find(world, targetname, self.target);
	if(!src || !dst) {
		objerror("follow: could not find target/killtarget");
		return;
	}
	if(self.spawnflags & 1) {
		// attach
		if(self.spawnflags & 2) {
			setattachment(dst, src, self.message);
		} else {
			attach_sameorigin(dst, src, self.message);
		}
	} else {
		if(self.spawnflags & 2) {
			dst.movetype = MOVETYPE_FOLLOW;
			dst.aiment = src;
			// dst.punchangle = '0 0 0'; // keep unchanged
			dst.view_ofs = dst.origin;
			dst.v_angle = dst.angles;
		} else {
			follow_sameorigin(dst, src);
		}
	}
	remove(self);
}

void(void) spawnfunc_misc_follow {
	InitializeEntity(self, misc_follow_init, INITPRIO_FINDTARGET);
}

void(void) spawnfunc_trap_spikeshooter {
	makevectors(self.angles);
	self.movedir = normalize(v_forward);
	self.use = spikeshooter_use;
	precache_sound("weapons/uzi_fire.wav");
	projectile_init(PROJECTILE_BULLET_BIG);
}

void(void) misc_lightning_spark {
	if (time > self.attack_finished_single) {
		stopsound(self, CHAN_TRIGGER);
		stopsound(self.enemy, CHAN_TRIGGER);
		return;
	}
	self.nextthink = time + 0.1;
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_BIGLIGHTNINGARC);
	WriteCoord(MSG_BROADCAST, self.origin_x);
	WriteCoord(MSG_BROADCAST, self.origin_y);
	WriteCoord(MSG_BROADCAST, self.origin_z);
	WriteCoord(MSG_BROADCAST, self.enemy.origin_x);
	WriteCoord(MSG_BROADCAST, self.enemy.origin_y);
	WriteCoord(MSG_BROADCAST, self.enemy.origin_z);
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
	InitializeEntity(self, misc_lightning_findtarget, INITPRIO_FINDTARGET);
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
