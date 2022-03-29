void(void) spawnfunc_turret_hk;
void(void) turret_hk_attack;
void(void) turret_hk_missile_think;
void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) turret_hk_missile_damage;
float(entity e_target,entity e_sender) turret_hk_addtarget;
//void turret_hk_missile_touch();

float hk_maxspeed;
float hk_minspeed;
float hk_accel;
float hk_accel2;
float hk_decel;

float(entity e_target,entity e_sender) turret_hk_addtarget {
	if (e_target) {
		if (turret_validate_target(self,e_target,self.target_validate_flags) > 0) {
			self.enemy = e_target;
			return 1;
		}
	}
	return 0;
}

float(entity e_target) turret_hk_is_valid_target {
	if (e_target == world)
		return 0;

	// If only this was used more..
	if (e_target.flags & FL_NOTARGET)
		return 0;

	// Cant touch this
	if ((e_target.takedamage == DAMAGE_NO) || (e_target.health < 0))
		return 0;

	// player
	if (e_target.flags & FL_CLIENT) {
		if (self.owner.target_select_playerbias < 0)
			return 0;

		if (e_target.deadflag != DEAD_NO)
			return 0;
	}
	// Missile
	if ((e_target.flags & FL_PROJECTILE) && (self.owner.target_select_missilebias < 0))
		return 0;

	// Team check
	if ((e_target.team == self.owner.team) || (self.owner.team == e_target.owner.team))
		return 0;

	return 1;
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) turret_hk_missile_damage {
	if (attacker.team == self.team)
		_damage *= 0.5;

	self.velocity += force;
	self.health -= _damage;
	if (self.health <= 0) {
		self.nextthink = time;
		self.think = turret_projectile_think_explode;
	}
}

void(void) turret_hk_attack {
	entity missile;
	//entity flash2;
	sound (self, CHAN_WEAPON, "weapons/rocket_fire.wav", VOL_BASE, ATTN_NORM);
	missile                  = projectile(FALSE, PROJECTILE_ROCKET, FALSE, self); // no culling, fly sound
	projectile_setup(missile, self.tur_shotorg, WEP_ROCKET_LAUNCHER, self.shot_dmg, 0, self.shot_radius, self.owner.shot_force, 0, MOVETYPE_FLY);
	missile.solid            = SOLID_BBOX;
	setorigin(missile, self.tur_shotorg);
	missile.scale            = 1;
	missile.classname        = "hk_missile";
	missile.takedamage       = DAMAGE_YES;
	missile.damageforcescale = 4;
	missile.health           = 10;
	missile.think            = turret_hk_missile_think;
	missile.event_damage     = turret_hk_missile_damage;
	missile.nextthink        = time + 0.25;
	missile.velocity         = self.tur_shotdir_updated * (self.shot_speed * 0.75);
	missile.angles           = vectoangles(missile.velocity);
	missile.touch            = turret_projectile_touch_explode; //turret_hk_missile_touch;
	missile.enemy            = self.enemy;
	missile.team             = self.team;
	missile.cnt              = time + 30;
	missile.ticrate          = max(cvar("sys_ticrate"),0.05);
	te_explosion (missile.origin);
	if (self.tur_head.frame == 0)
		self.tur_head.frame = self.tur_head.frame + 1;
}

void(void) turret_hk_missile_think {
	vector vu, vd, vf, vl, vr, ve = '0 0 0';  // Vector (direction)
	float  fu, fd, ff, fl, fr, fe;  // Fraction to solid
	vector olddir,wishdir,newdir;   // Final direction
	float lt_for;   // Length of Trace FORwrad
	float lt_seek;  // Length of Trace SEEK (left, right, up down)
	float pt_seek;  // Pitch of Trace SEEK (How mutch to angele left, right up, down trace towards v_forward)
	vector pre_pos;
	float myspeed;
	entity e;
	float ad, edist = 0;
	self.nextthink = time + self.ticrate;
	if (self.enemy.deadflag != DEAD_NO)
		self.enemy = world;

	// Pick the closest valid target.
	if (!self.enemy) {
		e = findradius(self.origin, 5000);
		while (e) {
			if (turret_hk_is_valid_target(e)) {
				if (!self.enemy)
					self.enemy = e;
				else
					if (vlen(self.origin - e.origin) < vlen(self.origin - self.enemy.origin))
						self.enemy = e;
			}
			e = e.chain;
		}
	}
	self.angles = vectoangles(self.velocity);
	self.angles_x = self.angles_x * -1;
	makevectors(self.angles);
	self.angles_x = self.angles_x * -1;
	if (self.enemy) {
		edist = vlen(self.origin - self.enemy.origin);
		// Close enougth to do decent damage?
		if ( edist <= (self.owner.shot_radius * 0.25) ) {
			turret_projectile_explode();
			return;
		}
		// Get data on enemy position
		pre_pos = self.enemy.origin +
				self.enemy.velocity *
				min((vlen(self.enemy.origin - self.origin) / vlen(self.velocity)),0.5);
		trace_line(self.origin, pre_pos,TRUE,self.enemy);
		ve = normalize(pre_pos - self.origin);
		fe = trace_fraction;
	} else {
		fe = 0;
	}
	if ((fe != 1) || (self.enemy == world) || (edist > 1000)) {
		myspeed = vlen(self.velocity);
		lt_for  = myspeed * 3;
		lt_seek = myspeed * 2.95;
		// Trace forward
		trace_line(self.origin, self.origin + v_forward * lt_for,FALSE,self);
		vf = trace_endpos;
		ff = trace_fraction;
		// Find angular offset
		ad = vlen(vectoangles(normalize(self.enemy.origin - self.origin)) - self.angles);
		// To close to something, Slow down!
		if ( ((ff < 0.7) || (ad > 4)) && (myspeed > hk_minspeed) )
			myspeed = max(myspeed * hk_decel,hk_minspeed);

		// Failry clear, accelerate.
		if ( (ff > 0.7) && (myspeed < hk_maxspeed) )
			myspeed = min(myspeed * hk_accel,hk_maxspeed);

		// Setup trace pitch
		pt_seek = 1 - ff;
		pt_seek = bound(0.15,pt_seek,0.8);
		if (ff < 0.5) pt_seek = 1;
		// Trace left
		trace_line(self.origin, self.origin + (-1 * (v_right * pt_seek) + (v_forward * ff)) * lt_seek,FALSE,self);
		vl = trace_endpos;
		fl = trace_fraction;
		// Trace right
		trace_line(self.origin,  self.origin + ((v_right * pt_seek) + (v_forward * ff)) * lt_seek ,FALSE,self);
		vr = trace_endpos;
		fr = trace_fraction;
		// Trace up
		trace_line(self.origin,  self.origin + ((v_up * pt_seek) + (v_forward * ff)) * lt_seek ,FALSE,self);
		vu = trace_endpos;
		fu = trace_fraction;
		// Trace down
		trace_line(self.origin,  self.origin + (-1 * (v_up * pt_seek) + (v_forward * ff)) * lt_seek ,FALSE,self);
		vd = trace_endpos;
		fd = trace_fraction;
		vl = normalize(vl - self.origin);
		vr = normalize(vr - self.origin);
		vu = normalize(vu - self.origin);
		vd = normalize(vd - self.origin);
		// Panic tresh passed, find a single direction and turn as hard as we can
		if (pt_seek == 1) {
			wishdir = v_right;
			if (fl > fr) wishdir = -1 * v_right;
			if (fu > fl) wishdir = v_up;
			if (fd > fu) wishdir = -1 * v_up;
		} else {
			// Normalize our trace vectors to make a smooth path
			wishdir = normalize( (vl * fl) + (vr * fr) +  (vu * fu) +  (vd * fd) );
		}
		if (self.enemy) {
			if (fe < 0.1) fe = 0.1; // Make sure we always try to move sligtly towards our target
			wishdir = (wishdir * (1 - fe)) + (ve * fe);
		}
	} else {
		// Got a clear path to target, speed up fast (if not at full speed) and go straight for it.
		myspeed = vlen(self.velocity);
		if (myspeed < hk_maxspeed)
			myspeed = min(myspeed * hk_accel2,hk_maxspeed);

		wishdir = ve;
	}
	if ((myspeed > hk_minspeed) && (self.cnt > time))
		myspeed = min(myspeed * hk_accel2,hk_maxspeed);

	// Ranoutagazfish?
	if (self.cnt < time) {
		self.cnt = time + 0.25;
		self.nextthink = 0;
		self.movetype         = MOVETYPE_BOUNCE;
		sound(self, CHAN_PROJECTILE, "", 0.4 * VOL_BASE, ATTN_NORM);
		return;
	}
	// Calculate new heading
	olddir = normalize(self.velocity);
	newdir = normalize(olddir + wishdir * cvar("g_turrets_unit_hk_std_shot_speed_turnrate"));
	// Set heading & speed
	self.velocity = newdir * myspeed;
	// Align model with new heading
	self.angles = vectoangles(self.velocity);
	projectile_update(self);
}

void(void) turret_hk_postthink {
	if (cvar("g_turrets_reloadcvars")) {
		hk_maxspeed = cvar("g_turrets_unit_hk_std_shot_speed_max");
		hk_minspeed = cvar("g_turrets_unit_hk_std_shot_speed");
		hk_accel    = cvar("g_turrets_unit_hk_std_shot_speed_accel");
		hk_accel2   = cvar("g_turrets_unit_hk_std_shot_speed_accel2");
		hk_decel    = cvar("g_turrets_unit_hk_std_shot_speed_decel");
	}
	if (self.tur_head.frame != 0)
		self.tur_head.frame = self.tur_head.frame + 1;

	if (self.tur_head.frame > 5)
		self.tur_head.frame = 0;
}

/*QUAKED turret_hk (0 .5 .8) ?
* Turret that fires Hunter-killer missiles.
* Missiles seek their target and try to avoid obstacles. If target dies early, they
* pick a new one on their own.
*/

void(void) spawnfunc_turret_hk {
	precache_model("models/turrets/base.md3");
	precache_model("models/turrets/hk.md3");
	if (self.netname == "")
		self.netname = "Hunter-killer turret";

	hk_maxspeed = cvar("g_turrets_unit_hk_std_shot_speed_max");
	hk_minspeed = cvar("g_turrets_unit_hk_std_shot_speed");
	hk_accel = cvar("g_turrets_unit_hk_std_shot_speed_accel");
	hk_accel2 = cvar("g_turrets_unit_hk_std_shot_speed_accel2");
	hk_decel = cvar("g_turrets_unit_hk_std_shot_speed_decel");
	self.turrcaps_flags = TFL_TURRCAPS_RADIUSDMG | TFL_TURRCAPS_MEDPROJ | TFL_TURRCAPS_PLAYERKILL | TFL_TURRCAPS_RECIVETARGETS;
	self.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
	self.aim_flags = TFL_AIM_SIMPLE;
	self.target_select_flags = TFL_TARGETSELECT_LOS | TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_TRIGGERTARGET | TFL_TARGETSELECT_RANGELIMTS | TFL_TARGETSELECT_TEAMCHECK;
	self.firecheck_flags = TFL_FIRECHECK_WORLD | TFL_FIRECHECK_DEAD | TFL_FIRECHECK_TEAMCECK  | TFL_FIRECHECK_REFIRE | TFL_FIRECHECK_AFF;
	self.target_select_flags = TFL_TARGETSELECT_LOS | TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_TRIGGERTARGET | TFL_TARGETSELECT_RANGELIMTS | TFL_TARGETSELECT_TEAMCHECK;
	self.shoot_flags = TFL_SHOOT_CLEARTARGET;
	if (turret_stdproc_init("hk_std", "models/turrets/base.md3", "models/turrets/hk.md3") == 0) {
		remove(self);
		return;
	}
	self.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_TEAMCHECK;
	if (!turret_tag_setup())
		print("Warning: Turret ",self.classname, " faild to initialize md3 tags\n");

	// Our fire routine
	self.turret_firefunc  = turret_hk_attack;
	// re-color badge & handle recoil effect
	self.turret_postthink = turret_hk_postthink;
	// What to do when reciveing foreign target data
	self.turret_addtarget = turret_hk_addtarget;
}
