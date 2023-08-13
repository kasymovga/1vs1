.float fireflag;

float(void) turret_phaser_firecheck {
    if (self.fireflag != 0) return 0;
    return turret_stdproc_firecheck();
}

void(void) turret_phaser_postthink {
	if (self.tur_head.frame == 0)
		return;

	if (self.fireflag == 1) {
		if (self.tur_head.frame == 10)
			self.tur_head.frame = 1;
		else
			self.tur_head.frame = self.tur_head.frame +1;
	} else if (self.fireflag == 2 ) {
		self.tur_head.frame = self.tur_head.frame +1;
		if (self.tur_head.frame == 15) {
			self.tur_head.frame = 0;
			self.fireflag = 0;
		}
	}
}

void(vector start,vector end,vector smin,vector smax,
		float bforce,float f_dmg,float f_velfactor, float deathtype) turret_phaser_beam_fire {
	vector hitloc, force, endpoint, dir;
	entity ent;
	dir = normalize(end - start);
	force = dir * bforce;
	// go a little bit into the wall because we need to hit this wall later
	end = end + dir;
	// trace multiple times until we hit a wall, each obstacle will be made unsolid.
	// note down which entities were hit so we can damage them later
	while (1) {
		trace_box(start, smin, smax, end, FALSE, self);
		// if it is world we can't hurt it so stop now
		if (trace_ent == world || trace_fraction == 1)
			break;

		if (trace_ent.solid == SOLID_BSP)
			break;

		// make the entity non-solid so we can hit the next one
		trace_ent.railgunhit = TRUE;
		trace_ent.railgunhitloc = end;
		trace_ent.railgunhitsolidbackup = trace_ent.solid;
		// stop if this is a wall
		// make the entity non-solid
		trace_ent.solid = SOLID_NOT;
	}
	endpoint = trace_endpos;
	// find all the entities the railgun hit and restore their solid state
	ent = findfloat(world, railgunhit, TRUE);
	while (ent) {
		// restore their solid type
		ent.solid = ent.railgunhitsolidbackup;
		ent = findfloat(ent, railgunhit, TRUE);
	}
	// find all the entities the railgun hit and hurt them
	ent = findfloat(world, railgunhit, TRUE);
	while (ent) {
		// get the details we need to call the damage function
		hitloc = ent.railgunhitloc;
		ent.railgunhitloc = '0 0 0';
		ent.railgunhitsolidbackup = SOLID_NOT;
		ent.railgunhit = FALSE;
		// apply the damage
		if (ent.takedamage) {
			damage(ent, self, self, f_dmg, deathtype, hitloc, force);
			ent.velocity = ent.velocity * f_velfactor;
			//ent.alpha = 0.25 + random() * 0.75;
		}
		// advance to the next entity
		ent = findfloat(ent, railgunhit, TRUE);
	}
	trace_endpos = endpoint;
}


void(void) turret_phaser_beam_think {
	if ((time > self.cnt) || (self.owner.deadflag != DEAD_NO)) {
		self.owner.attack_finished_single = time + self.owner.shot_refire;
		self.owner.fireflag = 2;
		self.owner.tur_head.frame = 10;
		sound_stop(self, CHAN_PROJECTILE);
		remove(self);
		return;
	}
	turret_do_updates(self.owner);
	if (time - self.shot_spread > 0) {
		self.shot_spread = time + 2;
		sound(self, CHAN_PROJECTILE, "turrets/phaser.wav", VOL_BASE, ATTN_NORM);
	}
	self.nextthink = time + self.ticrate;
	self.owner.attack_finished_single = time + frametime;
	entity oldself;
	oldself = self;
	self = self.owner;
	//w_deathtypestring = "was phased out of existence";
	turret_phaser_beam_fire(
			self.tur_shotorg,
			self.tur_shotorg + self.tur_shotdir_updated * self.target_range,
			'-1 -1 -1' * self.shot_radius,
			'1 1 1' * self.shot_radius,
			self.shot_force,
			oldself.shot_dmg,
			0.75,
			WEAPON_NEX);
	self = oldself;
	self.scale = vlen(self.owner.tur_shotorg - trace_endpos) / 256;
}

void(void) turret_phaser_attack {
	entity beam;
	beam = spawn();
	beam.ticrate = 0.1; //cvar("sys_ticrate");
	setmodel(beam,"models/turrets/phaser_beam.md3");
	beam.effects = EFFECT_LOWPRECISION;
	beam.solid = SOLID_NOT;
	beam.think = turret_phaser_beam_think;
	beam.cnt = time + self.shot_speed;
	beam.shot_spread = time + 2;
	beam.nextthink = time;
	beam.owner = self;
	beam.shot_dmg = self.shot_dmg / (self.shot_speed / beam.ticrate);
	beam.scale = self.target_range / 256;
	beam.movetype = MOVETYPE_NONE;
	beam.enemy = self.enemy;
	beam.bot_dodge = TRUE;
	beam.bot_dodgerating = beam.shot_dmg;
	sound (beam, CHAN_PROJECTILE, "turrets/phaser.wav", VOL_BASE, ATTN_NORM);
	self.fireflag = 1;
	beam.attack_finished_single = self.attack_finished_single;
	self.attack_finished_single = time; // + cvar("sys_ticrate");
	setattachment(beam,self.tur_head,"tag_fire");
	sound_at (self, trace_endpos, CHAN_PROJECTILE, "weapons/neximpact.wav", VOL_BASE, ATTN_NORM);
	if (self.tur_head.frame == 0)
		self.tur_head.frame = 1;
}

/*QUAKED turret_phaser(0 .5 .8) ?
*/
void(void) spawnfunc_turret_phaser {
	precache_sound("turrets/phaser.wav");
	precache_model("models/turrets/phaser.md3");
	precache_model("models/turrets/phaser_beam.md3");
	precache_model("models/turrets/base.md3");
	if (self.netname == "")
		self.netname = "Phaser Cannon";

	self.turrcaps_flags = TFL_TURRCAPS_SNIPER|TFL_TURRCAPS_HITSCAN|TFL_TURRCAPS_PLAYERKILL;
	self.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIVE;
	self.aim_flags = TFL_AIM_ZEASE | TFL_AIM_LEAD;
	if (turret_stdproc_init("phaser_std", "models/turrets/base.md3", "models/turrets/phaser.md3") == 0) {
		remove(self);
		return;
	}
	if (!turret_tag_setup())
		print("Warning: Turret ",self.classname, " faild to initialize md3 tags\n");

	self.turret_firecheckfunc = turret_phaser_firecheck;
	self.turret_firefunc  = turret_phaser_attack;
	self.turret_postthink = turret_phaser_postthink;
}
