// Get real origin
vector(entity ent) turret_real_origin {
	entity e;
	vector v = '0 0 0';
	e = ent.tag_entity;
	while (e) {
		// v = v + e.origin;
		v = v + ((e.absmin + e.absmax) * 0.5);
		e = e.tag_entity;
	}
	//v = v + ent.origin;
	v = v + ((ent.absmin + ent.absmax) * 0.5);
	return v;
}

/*
* Return the angle between two enteties
*/
vector(entity from, entity to) turret_angleofs {
	vector v_res;
	// makevectors(from.angles);
	v_res = normalize(to.origin - from.origin);
	v_res = vectoangles(v_res);
	v_res = v_res - from.angles;
	if (v_res_x < 0) v_res_x += 360;
	if (v_res_x > 180) v_res_x -= 360;
	if (v_res_y < 0) v_res_y += 360;
	if (v_res_y > 180) v_res_y -= 360;
	return v_res;
}

vector(vector from,vector from_a, entity to) turret_angleofs3 {
	vector v_res;
	// makevectors(from.angles);
	v_res = normalize(to.origin - from);
	v_res = vectoangles(v_res);
	v_res = v_res - from_a;
	if (v_res_x < 0) v_res_x += 360;
	if (v_res_x > 180) v_res_x -= 360;
	if (v_res_y < 0) v_res_y += 360;
	if (v_res_y > 180) v_res_y -= 360;
	return v_res;
}

float() turret_tag_fire_update {
	if not(self.tur_head) {
		self.tur_shotorg = self.origin;
		return 0;
	}
	self.tur_shotorg = gettaginfo(self.tur_head,gettagindex(self.tur_head,"tag_fire"));
	v_forward = normalize(v_forward);
	return 1;
}

float() turret_tag_setup {
	setattachment(self.tur_head, self, "tag_head");
	return turret_tag_fire_update();
}

vector() turret_stdproc_aim_generic {
	vector pre_pos,prep;
	float distance, impact_time = 0, i, mintime;
	turret_tag_fire_update();
	if (self.aim_flags & TFL_AIM_SIMPLE)
		return turret_real_origin(self.enemy);

	// Keep track of when we can shoot the next time and
	// try to predict where the target will be then, so we can put our aimpoint there.
	// + sys_ticrate, becouse spawned REMOVE THIS IF sv_gameplayfix_delayprojectiles are 0!
	// projectiles dont move during the first tic of their life.
	//if (self.turrcaps_flags & TFL_TURRCAPS_HITSCAN)
	//    mintime = max(self.attack_finished_single - time,0) + sys_ticrate;
	//else
	mintime = max(self.attack_finished_single - time,0) + sys_ticrate;
	// Baseline
	pre_pos = turret_real_origin(self.enemy);
	if (self.aim_flags & TFL_AIM_INFRONT)   // Aim a bit in front of the target
		pre_pos = pre_pos + (normalize(self.enemy.velocity) * 64);

	if (self.aim_flags & TFL_AIM_BEHIND)    // Aim a bit behind the target
		pre_pos = pre_pos - (normalize(self.enemy.velocity) * 32);

	// Lead?
	if (self.aim_flags & TFL_AIM_LEAD)
	if (self.aim_flags & TFL_AIM_SHOTTIMECOMPENSATE) {     // Need to conpensate for shot traveltime
		// FIXME: this cant be the best way to do this..
		prep = pre_pos;
		for (i = 0; i < 4; ++i) {
			distance = vlen(prep - self.tur_shotorg);
			impact_time = distance / self.shot_speed;
			prep = pre_pos + self.enemy.velocity * impact_time;
		}
		prep = pre_pos + (self.enemy.velocity * (impact_time + mintime));
		if (self.aim_flags & TFL_AIM_ZPREDICT)
		if not(self.enemy.flags & FL_ONGROUND)
		if (self.enemy.movetype == MOVETYPE_WALK || self.enemy.movetype == MOVETYPE_TOSS || self.enemy.movetype == MOVETYPE_BOUNCE) {
			float vz;
			prep_z = pre_pos_z;
			vz = self.enemy.velocity_z;
			for (i = 0; i < impact_time; i += sys_ticrate) {
				vz = vz - (sv_gravity * sys_ticrate);
				prep_z = prep_z + vz * sys_ticrate;
			}
		}
		pre_pos = prep;
	} else
		pre_pos = pre_pos + self.enemy.velocity * mintime;

	// Smooth out predict-Z?
	/*
	if (self.aim_flags & TFL_AIM_ZEASE)
	if (self.enemy.flags & FL_CLIENT) {
		vector v;
		v = turret_real_origin(self.enemy);
		pre_pos_z = (pre_pos_z + v_z) * 0.5;
	}
	*/
	if (self.aim_flags & TFL_AIM_GROUND2) {
		//trace_box(pre_pos + '0 0 32',self.enemy.mins,self.enemy.maxs,pre_pos -'0 0 64',TRACE_MOVE_WORLDONLY,self.enemy);
		trace_line(pre_pos + '0 0 32',pre_pos -'0 0 64',TRACE_MOVE_WORLDONLY,self.enemy);
		if (trace_fraction != 1.0)
			pre_pos = trace_endpos;
	}
	/*
	// This turret should hit the ground neer a target rather the do a direct hit
	if (self.aim_flags & TFL_AIM_GROUND) {
		trace_line(pre_pos + '0 0 8',pre_pos - '0 0 10000',TRACE_MOVE_WORLDONLY,self.enemy);
		pre_pos = trace_endpos;
	}
	*/
	return pre_pos;
}

/*
* Trow a turret gib
*/
void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector vforce) turret_gib_damage {
	self.velocity += vforce;
}

void(vector v_from, vector v_to, vector v_colormod,
		string smodel,
		float f_lifetime, float f_fadetime, float b_burn) turret_trowgib {
	entity gib;
	entity burn;
	gib = spawn();
	gib.classname = "turret_gib";
	setmodel(gib,smodel);
	setorigin(gib,v_from);
	entity_fade_setup(gib,time + f_lifetime,2);
	gib.solid = SOLID_NOT;
	gib.movetype = MOVETYPE_BOUNCE;
	gib.event_damage = turret_gib_damage;
	gib.health = -1;
	gib.effects = EFFECT_LOWPRECISION;
	gib.flags = FL_NOTARGET;
	gib.colormod = v_colormod;
	gib.velocity = v_to;
	if (b_burn) {
		burn = spawn();
		burn.effects = EFFECT_LOWPRECISION;//|EFFECT_FLAME;
		setattachment(burn,gib,"");
		setorigin(burn,(gib.mins + gib.maxs) * 0.5);
		entity_fade_setup(burn,time + (f_lifetime * 0.5) ,2);
	}
}

void() turret_gib_boom {
	entity gib;
	float i;
	string s;
	for (i = 1; i < 5; i = i +1) {
		gib = spawn();
		gib.classname = "turret_gib";
		s = strcat("models/turrets/head-gib",ftos(i));
		s = strcat(s,".md3");
		// bprint("s:",s,"\n");
		setmodel(gib,s);
		setorigin(gib,self.origin);
		entity_fade_setup(gib,time + 5,2);
		gib.solid = SOLID_NOT;
		gib.movetype = MOVETYPE_BOUNCE;
		gib.gravity = 0.5;
		gib.damageforcescale = 2;
		gib.event_damage = turret_gib_damage;
		gib.health = -1;
		gib.effects = EFFECT_LOWPRECISION;
		gib.flags = FL_NOTARGET;
		gib.velocity = self.velocity + (randomvec() * 700);
		gib.avelocity = randomvec() * 64;
	}
	net_write_byte(MSG_BROADCAST, SVC_TEMPENTITY);
	net_write_byte(MSG_BROADCAST, 78);
	net_write_coord(MSG_BROADCAST, self.origin_x);
	net_write_coord(MSG_BROADCAST, self.origin_y);
	net_write_coord(MSG_BROADCAST, self.origin_z);
	remove(self);
}

void(vector v_from, vector v_to, vector v_colormod,
		entity e_mimic, float boomtime) turret_trowgib2 {
	entity gib;
	gib = spawn();
	gib.classname = "turret_gib";
	setmodel(gib,e_mimic.model);
	setorigin(gib,v_from);
	gib.solid = SOLID_BBOX;
	gib.movetype = MOVETYPE_BOUNCE;
	gib.gravity = 0.75;
	gib.damageforcescale = 2;
	gib.takedamage = DAMAGE_YES;
	gib.event_damage = turret_gib_damage;
	gib.health = -1;
	gib.effects = EFFECT_LOWPRECISION;
	gib.flags = FL_NOTARGET;
	gib.colormod = v_colormod;
	gib.velocity = v_to;
	gib.avelocity = randomvec() * 32;
	gib.think = turret_gib_boom;
	gib.nextthink = boomtime;
	//gib.effects = EFFECT_FLAME;
}

/*
* Spawn a boom, trow fake bits arround
* and hide the real ones.
*/
void() turret_stdproc_die {
	vector org2;
	vector t_dir;
	self.deadflag = DEAD_DEAD;
	sound (self, CHAN_PLAYER, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
	org2 = self.origin + '0 0 40';
	// Explotion grafix
	net_write_byte (MSG_BROADCAST, SVC_TEMPENTITY);
	net_write_byte (MSG_BROADCAST, 78);
	net_write_coord (MSG_BROADCAST, org2_x);
	net_write_coord (MSG_BROADCAST, org2_y);
	net_write_coord (MSG_BROADCAST, org2_z);
	// Unsolidify and hide real parts
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.alpha = -1;
	self.tur_head.alpha = self.alpha;
	self.customizeentityforclient = stdproc_false;
	self.tur_head.customizeentityforclient = stdproc_false;
	self.event_damage = NULL;
	self.takedamage = DAMAGE_NO;
	self.effects = 0;
	self.tur_head.effects = self.effects;
	self.health = 0;
	// Trow fake parts arround
	// base
	if not(self.damage_flags & TFL_DMG_DEATH_NOGIBS) {
		makevectors(self.angles);
		if (random() > 0.5) {
			turret_trowgib(self.origin, '0 0 0','1 1 1',"models/turrets/base-gib2.md3",min(self.respawntime,20),1,1);
			t_dir = (v_up * 700) + (randomvec() * 300);
			turret_trowgib(self.origin, t_dir,'1 1 1',"models/turrets/base-gib3.md3",min(self.respawntime,10),1,1);
			t_dir = (v_up * 700) + (randomvec() * 300);
			turret_trowgib(self.origin, t_dir,'1 1 1',"models/turrets/base-gib4.md3",min(self.respawntime,10),1,1);
		} else {
			turret_trowgib(self.origin, '0 0 0','1 1 1',"models/turrets/base-gib1.md3",min(self.respawntime,20),1,1);
		}
		// Blow the top part up into the air
		turret_trowgib2(self.origin + (v_up * 50),
				v_up * 150 + randomvec() * 50,
				'0.2 0.2 0.2',
				self.tur_head,time + 0.5 + (random() * 0.5));
	}
	if (self.damage_flags & TFL_DMG_DEATH_NORESPAWN) {
		if (self.turret_diehook)
			self.turret_diehook();

		remove(self.tur_head);
		remove(self);
	} else {
		// Setup respawn
		self.nextthink = time + self.respawntime;
		//self.think = self.turret_spawnfunc;
		self.think = turret_stdproc_respawn;
		if (self.turret_diehook)
			self.turret_diehook();
	}
}

void() turret_stdproc_setcolormod {
	vector cmod = team_colormod(self.team);
	self.colormod = cmod;
	if (self.tur_head)
		self.tur_head.colormod = cmod;
}

void() turret_stdproc_respawn {
	// Make sure all parts belong to the same team since
	// this function doubles as "teamchange" function.
	self.tur_head.team = self.team;
	turret_stdproc_setcolormod();
	self.flags = (self.flags & ~FL_ONGROUND);
	self.movetype = MOVETYPE_TOSS;
	self.deadflag = DEAD_NO;
	self.effects = 0;
	self.tur_head.effects = self.effects;
	self.solid = SOLID_BBOX;
	self.alpha = 1;
	self.tur_head.alpha = self.alpha;
	self.customizeentityforclient = stdproc_true;
	self.tur_head.customizeentityforclient = stdproc_true;
	setorigin(self, self.pos1);
	self.takedamage = DAMAGE_AIM;
	self.event_damage = turret_stdproc_damage;
	self.avelocity = '0 0 0';
	self.tur_head.avelocity = self.avelocity;
	self.tur_head.angles = self.idle_aim;
	self.health = self.tur_health;
	self.tur_head.health = self.tur_health;
	self.enemy = world;
	self.volly_counter = self.shot_volly;
	self.ammo = self.ammo_max;
	self.nextthink = time + self.ticrate;
	self.think = turret_think;
	if (self.turret_respawnhook)
		self.turret_respawnhook();
}

/*
* Standard damage proc.
*/
void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector vforce) turret_stdproc_damage {
	entity baseent;
	if (self.owner)
		baseent = self.owner;
	else
		baseent = self;

	// Enougth allready!
	if (self.health <= 0)
		return;

	// Inactive turrets take no damage. (hm..)
	if not(baseent.tur_active)
		return;

	if (team_mode)
	if (self.team == attacker.team) {
		// This does not happen anymore. Re-enable if you fix that.
		//if (attacker.flags & FL_CLIENT)
		if (clienttype(attacker) == CLIENTTYPE_REAL)
			sprint(attacker, "\{1}Turret tells you: I'm on your team!\n");

		if (g_friendlyfire)
			_damage = _damage * g_friendlyfire;
		else
			return;
	}
	self.health = self.health - _damage;
	// thorw head slightly off aim when hit?
	if (self.classname == "turret_head")
		if (baseent.damage_flags & TFL_DMG_HEADSHAKE) {
			self.angles_x = self.angles_x + (-0.5 + random()) * _damage;
			self.angles_y = self.angles_y + (-0.5 + random()) * _damage;
		}
	if (baseent.turrcaps_flags & TFL_TURRCAPS_MOVE)
		baseent.velocity = baseent.velocity + vforce;

	// FIXME: Better damage feedback
	// Start burning when we have 10% or less health left
	//if (self.health < (self.tur_health * 0.1))
	//    self.effects = EFFECT_FLAME;
	if (self.health <= 0) {
		baseent.event_damage = NULL;
		baseent.takedamage = DAMAGE_NO;
		baseent.nextthink = time;
		baseent.think = turret_stdproc_die;
	}
}

float g_turrets_aimidle_delay;
float g_turrets_nofire;
float g_turrets_targetscan_maxdelay;
float g_turrets_targetscan_mindelay;
float g_turrets_targetscan_playersonly;

void(entity ent, string unitname, float is_reload) load_unit_settings {
	string sbase;
	if (ent == world)
		return;

	if not(ent.turret_scale_damage) ent.turret_scale_damage = 1;
	if not(ent.turret_scale_range) ent.turret_scale_range = 1;
	if not(ent.turret_scale_refire) ent.turret_scale_refire = 1;
	if not(ent.turret_scale_ammo) ent.turret_scale_ammo = 1;
	if not(ent.turret_scale_aim) ent.turret_scale_aim = 1;
	if not(ent.turret_scale_health) ent.turret_scale_health = 1;
	if not(ent.turret_scale_respawn) ent.turret_scale_respawn = 1;
	sbase = strcat("g_turrets_unit_", unitname);
	if (is_reload) {
		ent.enemy = world;
		ent.tur_head.avelocity = '0 0 0';
		ent.tur_head.angles = '0 0 0';
	}
	ent.health = cvar(strcat(sbase,"_health")) * ent.turret_scale_health;
	ent.respawntime = cvar(strcat(sbase,"_respawntime")) * ent.turret_scale_respawn;
	ent.shot_dmg = cvar(strcat(sbase,"_shot_dmg")) * ent.turret_scale_damage;
	ent.shot_refire = cvar(strcat(sbase,"_shot_refire")) * ent.turret_scale_refire;
	ent.shot_radius = cvar(strcat(sbase,"_shot_radius")) * ent.turret_scale_damage;
	ent.shot_speed = cvar(strcat(sbase,"_shot_speed"));
	ent.shot_spread = cvar(strcat(sbase,"_shot_spread"));
	ent.shot_force = cvar(strcat(sbase,"_shot_force")) * ent.turret_scale_damage;
	ent.shot_volly = cvar(strcat(sbase,"_shot_volly"));
	ent.shot_volly_refire = cvar(strcat(sbase,"_shot_volly_refire")) * ent.turret_scale_refire;
	ent.target_range = cvar(strcat(sbase,"_target_range")) * ent.turret_scale_range;
	ent.target_range_min = cvar(strcat(sbase,"_target_range_min")) * ent.turret_scale_range;
	//ent.target_range_fire = cvar(strcat(sbase,"_target_range_fire")) * ent.turret_scale_range;
	ent.target_range_optimal = cvar(strcat(sbase,"_target_range_optimal")) * ent.turret_scale_range;
	ent.target_select_rangebias = cvar(strcat(sbase,"_target_select_rangebias"));
	ent.target_select_samebias = cvar(strcat(sbase,"_target_select_samebias"));
	ent.target_select_anglebias = cvar(strcat(sbase,"_target_select_anglebias"));
	ent.target_select_playerbias = cvar(strcat(sbase,"_target_select_playerbias"));
	//ent.target_select_fov = cvar(cvar_gets(sbase,"_target_select_fov"));
	ent.ammo_max = cvar(strcat(sbase,"_ammo_max")) * ent.turret_scale_ammo;
	ent.ammo_recharge = cvar(strcat(sbase,"_ammo_recharge")) * ent.turret_scale_ammo;
	ent.aim_firetolerance_dist = cvar(strcat(sbase,"_aim_firetolerance_dist"));
	ent.aim_speed = cvar(strcat(sbase,"_aim_speed")) * ent.turret_scale_aim;
	ent.aim_maxrot = cvar(strcat(sbase,"_aim_maxrot"));
	ent.aim_maxpitch = cvar(strcat(sbase,"_aim_maxpitch"));
	ent.track_type = cvar(strcat(sbase,"_track_type"));
	ent.track_accel_pitch = cvar(strcat(sbase,"_track_accel_pitch"));
	ent.track_accel_rot = cvar(strcat(sbase,"_track_accel_rot"));
	ent.track_blendrate = cvar(strcat(sbase,"_track_blendrate"));
	if (is_reload)
		if (ent.turret_respawnhook)
			ent.turret_respawnhook();
}

/**
** updates enemy distances, predicted impact point/time
** and updated aim<->predict impact distance.
**/
void(entity t_turret) turret_do_updates {
	vector enemy_pos,oldpos;
	entity oldself;
	oldself = self;
	self = t_turret;
	enemy_pos = turret_real_origin(self.enemy);
	turret_tag_fire_update();
	self.tur_shotdir_updated = normalize(v_forward);
	self.tur_dist_enemy = vlen(self.tur_shotorg - enemy_pos);
	self.tur_dist_aimpos = vlen(self.tur_shotorg - self.tur_aimpos);
	if ((self.firecheck_flags & TFL_FIRECHECK_VERIFIED) && (self.enemy)) {
		oldpos = self.enemy.origin;
		setorigin(self.enemy,self.tur_aimpos);
		trace_box(self.tur_shotorg, '-1 -1 -1','1 1 1',self.tur_shotorg + (self.tur_shotdir_updated * self.tur_dist_aimpos),TRACE_MOVE_NORMAL,self);
		setorigin(self.enemy,oldpos);

		if (trace_ent == self.enemy)
			self.tur_dist_impact_to_aimpos = 0;
		else
			self.tur_dist_impact_to_aimpos = vlen(trace_endpos - self.tur_aimpos);// - (vlen(self.enemy.maxs - self.enemy.mins)*0.5);
	} else {
		trace_box(self.tur_shotorg, '-1 -1 -1','1 1 1',self.tur_shotorg + (self.tur_shotdir_updated * self.tur_dist_aimpos),TRACE_MOVE_NORMAL,self);
		//trace_line(self.tur_shotorg, self.tur_shotorg + (self.tur_shotdir_updated * self.tur_dist_aimpos),TRACE_MOVE_NORMAL,self);
		self.tur_dist_impact_to_aimpos = vlen(trace_endpos - self.tur_aimpos) - (vlen(self.enemy.maxs - self.enemy.mins)*0.5);
	}
	self.tur_impactent = trace_ent;
	self.tur_impacttime = vlen(self.tur_shotorg - trace_endpos) / self.shot_speed;
	self = oldself;
}

/**
** Handles head rotation according to
** the units .track_type and .track_flags
**/
//.entity aim_mark;
void() turret_stdproc_track {
	vector target_angle; // This is where we want to aim
	vector move_angle; // This is where we can aim
	vector a_off;
	float f_tmp;
	if (self.track_flags == TFL_TRACK_NO)
		return;

	if not(self.tur_active)
		target_angle = self.idle_aim - ('1 0 0' * self.aim_maxpitch);
	else if (self.enemy == world) {
		if (time > self.lip)
			target_angle = self.idle_aim + self.angles;
		else
			target_angle = vectoangles(normalize(self.tur_aimpos - self.tur_shotorg));
	} else {
		// Find the direction
		target_angle = normalize(self.tur_aimpos - self.tur_shotorg);
		target_angle = vectoangles(target_angle); // And make a angle
	}
	self.tur_head.angles_x = math_safeangle(self.tur_head.angles_x);
	self.tur_head.angles_y = math_safeangle(self.tur_head.angles_y);
	// Find the diffrence between where we currently aim and where we want to aim
	vector head_angles = self.angles + self.tur_head.angles;
	head_angles_x = math_safeangle(head_angles_x);
	head_angles_y = math_safeangle(head_angles_y);
	move_angle = target_angle - head_angles;
	move_angle_x = math_safeangle(move_angle_x);
	move_angle_y = math_safeangle(move_angle_y);
	move_angle = math_shortangle_vxy(move_angle, head_angles);
	a_off = '0 0 0';
	switch(self.track_type) {
	case TFL_TRACKTYPE_STEPMOTOR:
		f_tmp = self.aim_speed * self.ticrate; // dgr/sec -> dgr/tic
		if (self.track_flags & TFL_TRACK_PITCH) {
			self.tur_head.angles_x += bound(-f_tmp,move_angle_x, f_tmp);
			if (self.tur_head.angles_x + a_off_x > self.aim_maxpitch)
				self.tur_head.angles_x = a_off_x + self.aim_maxpitch;

			if (self.tur_head.angles_x + a_off_x < -self.aim_maxpitch)
				self.tur_head.angles_x = a_off_x - self.aim_maxpitch;
		}
		if (self.track_flags & TFL_TRACK_ROT) {
			self.tur_head.angles_y += bound(-f_tmp, move_angle_y, f_tmp);
			if ((self.tur_head.angles_y - a_off_y) > self.aim_maxrot)
				self.tur_head.angles_y = a_off_y + self.aim_maxrot;

			if ((self.tur_head.angles_y - a_off_y) < -self.aim_maxrot)
				self.tur_head.angles_y = a_off_y - self.aim_maxrot;
		}
		return;
	case TFL_TRACKTYPE_FLUIDINERTIA:
		f_tmp = self.aim_speed * self.ticrate; // dgr/sec -> dgr/tic
		move_angle_x = bound(-self.aim_speed, move_angle_x * self.track_accel_pitch * f_tmp,self.aim_speed);
		move_angle_y = bound(-self.aim_speed, move_angle_y * self.track_accel_rot * f_tmp,self.aim_speed);
		move_angle = (self.tur_head.avelocity * self.track_blendrate) + (move_angle * (1 - self.track_blendrate));
		break;
	case TFL_TRACKTYPE_FLUIDPRECISE:
		move_angle_y = bound(-self.aim_speed, move_angle_y, self.aim_speed);
		move_angle_x = bound(-self.aim_speed, move_angle_x, self.aim_speed);
		break;
	}
	//pitch
	if (self.track_flags & TFL_TRACK_PITCH) {
		self.tur_head.avelocity_x = move_angle_x;
		self.tur_head.angles_x += move_angle_x * self.ticrate;
		if ((self.tur_head.angles_x + self.tur_head.avelocity_x * self.ticrate) + a_off_x > self.aim_maxpitch) {
			self.tur_head.avelocity_x = 0;
			self.tur_head.angles_x = a_off_x + self.aim_maxpitch;
		}
		if ((self.tur_head.angles_x + self.tur_head.avelocity_x * self.ticrate) + a_off_x < -self.aim_maxpitch) {
			self.tur_head.avelocity_x = 0;
			self.tur_head.angles_x = a_off_x - self.aim_maxpitch;
		}
	}
	//rot
	if (self.track_flags & TFL_TRACK_ROT) {
		self.tur_head.avelocity_y = move_angle_y;
		self.tur_head.angles_y += move_angle_y * self.ticrate;
		if (((self.tur_head.angles_y + self.tur_head.avelocity_y * self.ticrate)- a_off_y) > self.aim_maxrot) {
			self.tur_head.avelocity_y = 0;
			self.tur_head.angles_y = a_off_y + self.aim_maxrot;
		}
		if (((self.tur_head.angles_y + self.tur_head.avelocity_y * self.ticrate) - a_off_y) < -self.aim_maxrot) {
			self.tur_head.avelocity_y = 0;
			self.tur_head.angles_y = a_off_y - self.aim_maxrot;
		}
	}
}

/*
 + = implemented
 - = not implemented

 + TFL_FIRECHECK_NO
 + TFL_FIRECHECK_WORLD
 + TFL_FIRECHECK_DEAD
 + TFL_FIRECHECK_DISTANCES
 - TFL_FIRECHECK_LOS
 + TFL_FIRECHECK_AIMDIST
 + TFL_FIRECHECK_REALDIST
 - TFL_FIRECHECK_ANGLEDIST
 - TFL_FIRECHECK_TEAMCECK
 + TFL_FIRECHECK_AFF
 + TFL_FIRECHECK_OWM_AMMO
 + TFL_FIRECHECK_OTHER_AMMO
 + TFL_FIRECHECK_REFIRE
*/

/**
** Preforms pre-fire checks based on the uints firecheck_flags
**/
float() turret_stdproc_firecheck {
	// This one just dont care =)
	if (self.firecheck_flags & TFL_FIRECHECK_NO)
		return 1;

	// Ready?
	if (self.firecheck_flags & TFL_FIRECHECK_REFIRE)
		if (self.attack_finished_single >= time) return 0;

	// Special case: volly fire turret that has to fire a full volly if a shot was fired.
	if (self.shoot_flags & TFL_SHOOT_VOLLYALWAYS)
		if not(self.volly_counter == self.shot_volly)
			return 1;

	// Lack of zombies makes shooting dead things unnecessary :P
	if (self.firecheck_flags & TFL_FIRECHECK_DEAD)
		if (self.enemy.deadflag != DEAD_NO)
			return 0;

	// Plz stop killing the world!
	if (self.firecheck_flags & TFL_FIRECHECK_WORLD)
		if (self.enemy == world)
			return 0;

	// Own ammo?
	if (self.firecheck_flags & TFL_FIRECHECK_OWM_AMMO)
		if (self.ammo < self.shot_dmg)
			return 0;

	// Other's ammo? (support-supply units)
	if (self.firecheck_flags & TFL_FIRECHECK_OTHER_AMMO)
		if (self.enemy.ammo >= self.enemy.ammo_max)
			return 0;

	if (self.firecheck_flags & TFL_FIRECHECK_DISTANCES) {
		// Not close enougth?
		//if (self.tur_dist_aimpos > self.target_range_fire) return 0;
		// To close?
		if (self.tur_dist_aimpos < self.target_range_min)
			return 0;
	}

	// Try to avoid FF?
	if (self.firecheck_flags & TFL_FIRECHECK_AFF)
		if (self.tur_impactent.team == self.team)
			return 0;

	// aim<->predicted impact
	if (self.firecheck_flags & TFL_FIRECHECK_AIMDIST)
		if (self.tur_dist_impact_to_aimpos > self.aim_firetolerance_dist)
			return 0;

		//if (self.tur_impactent != self.enemy)

	// Volly status
	if (self.shot_volly > 1)
		if (self.volly_counter == self.shot_volly)
			if (self.ammo < (self.shot_dmg * self.shot_volly))
				return 0;

	if (self.firecheck_flags & TFL_FIRECHECK_VERIFIED)
		if (self.tur_impactent != self.enemy)
			return 0;

	return 1;
}

/**
** Evaluate a entity for target valitity based on validate_flags
** NOTE: the caller must check takedamage before calling this, to inline this check.
**/
float(entity e_turret,entity e_target,float validate_flags) turret_validate_target {
	vector v_tmp;
	//if (!validate_flags & TFL_TARGETSELECT_NOBUILTIN)
	//    return -0.5;

	if (e_target.owner == e_turret)
		return -0.5;

	if not(checkpvs(e_target.origin, e_turret))
		return -1;

	if not(e_target)
		return -2;

	if (validate_flags & TFL_TARGETSELECT_NO)
		return -4;

	// If only this was used more..
	if (e_target.flags & FL_NOTARGET)
		return -5;

	// Cant touch this
	if (e_target.health <= 0)
		return -6;

	// player
	if (e_target.flags & FL_CLIENT) {
		if not(validate_flags & TFL_TARGETSELECT_PLAYERS)
			return -7;

		if (e_target.deadflag != DEAD_NO)
			return -8;
	}
	// enemy turrets
	if (validate_flags & TFL_TARGETSELECT_NOTURRETS)
		if (e_target.turret_firefunc || e_target.owner.tur_head == e_target)
			if (e_target.team != e_turret.team) // Dont break support units.
				return -9;

	// Missile
	if (e_target.flags & FL_PROJECTILE)
		if not(validate_flags & TFL_TARGETSELECT_MISSILES)
			return -10;

	if (validate_flags & TFL_TARGETSELECT_MISSILESONLY)
		if not(e_target.flags & FL_PROJECTILE)
			return -10.5;

	// Team check
	if ((validate_flags & TFL_TARGETSELECT_TEAMCHECK)) {
		if (validate_flags & TFL_TARGETSELECT_OWNTEAM) {
			if (e_target.team != e_turret.team)
				return -11;

			if (e_target.owner)
			if (e_turret.team != e_target.owner.team)
				return -12;
		} else {
			if (e_target.team == e_turret.team || (team_mode && !e_target.team))
				return -13;

			if (e_target.owner)
			if (e_turret.team == e_target.owner.team || (team_mode && !e_target.owner.team))
				return -14;
		}
	}
	// Range limits?
	tvt_dist = vlen(e_turret.origin - turret_real_origin(e_target));
	if (validate_flags & TFL_TARGETSELECT_RANGELIMTS) {
		if (tvt_dist < e_turret.target_range_min)
			return -15;

		if (tvt_dist > e_turret.target_range)
			return -16;
	}
	tvt_thadv = turret_angleofs3(turret_real_origin(e_turret.tur_head) ,e_turret.angles + e_turret.tur_head.angles ,e_target);
	tvt_tadv = math_shortangle_vxy(turret_angleofs(e_turret,e_target),e_turret.angles);
	tvt_thadf = vlen(tvt_thadv);
	tvt_tadf = vlen(tvt_tadv);
	/*
	if (validate_flags & TFL_TARGETSELECT_FOV) {
		if (e_turret.target_select_fov < tvt_thadf)
			return -21;
	}
	*/
	if (validate_flags & TFL_TARGETSELECT_ANGLELIMITS) {
		if (fabs(tvt_tadv_x) > e_turret.aim_maxpitch)
			return -17;

		if (fabs(tvt_tadv_y) > e_turret.aim_maxrot)
			return -18;
	}
	// Line of sight?
	if (validate_flags & TFL_TARGETSELECT_LOS) {
		v_tmp = turret_real_origin(e_target) + ((e_target.mins + e_target.maxs) * 0.5);
		trace_line(turret_real_origin(e_turret.tur_head) ,v_tmp, 0, e_turret);
		if (e_turret.aim_firetolerance_dist < vlen(v_tmp - trace_endpos))
			return -19;
	}
	if (e_target.classname == "grapplinghook")
		return -20;

	/*
	if (e_target.classname == "func_button")
		return -21;
	*/
	return 1;
}

entity() turret_select_target {
	entity e; // target looper entity
	float score; // target looper entity score
	entity e_enemy; // currently best scoreing target
	float m_score; // currently best scoreing target's score
	entity e_real;
	e_enemy = world;
	m_score = 0;
	if (self.enemy)
	if (self.enemy.takedamage)
	if (turret_validate_target(self,self.enemy,self.target_validate_flags) > 0) {
		e_enemy = self.enemy;
		m_score = self.turret_score_target(self,e_enemy) * self.target_select_samebias;
	} else
		self.enemy = world;

	if (g_turrets_targetscan_playersonly) {
		FOR_EACH_PLAYER(e) {
			e_real = player_entity(e);
			if (turret_validate_target(self,e_real,self.target_select_flags) <= 0)
				continue;

			score = self.turret_score_target(self,e_real);
			if ((score > m_score) && (score > 0)) {
				e_enemy = e_real;
				m_score = score;
			}
		}
		return e_enemy;
	}
	for (e = findradius(self.origin,self.target_range); e; e = e.chain) {
		if not(e.takedamage)
			continue;

		if (turret_validate_target(self,e,self.target_select_flags) <= 0)
			continue;

		score = self.turret_score_target(self,e);
		if ((score > m_score) && (score > 0)) {
			e_enemy = e;
			m_score = score;
		}
		e = e.chain;
	}
	return e_enemy;
}

void() turret_think {
	entity e;
	self.nextthink = time + self.ticrate;
	if (time < map_starttime)
		return;

	if (map_finished)
		return;

	// ONS uses somewhat backwards linking.
	if (team_mode) {
		if (self.team != self.tur_head.team)
			turret_stdproc_setcolormod();
	}
	// Handle ammo
	if not(self.spawnflags & TSF_NO_AMMO_REGEN)
	if (self.ammo < self.ammo_max)
		self.ammo = min(self.ammo + self.ammo_recharge,self.ammo_max);

	entity tag_entity_restore = self.tag_entity;
	vector tag_origin_restore = '0 0 0';
	float tag_index_restore = 0;
	vector tag_angles_restore = '0 0 0';
	if (tag_entity_restore) {
		tag_index_restore = self.tag_index;
		tag_origin_restore = self.origin;
		tag_angles_restore = self.angles;
		setorigin(self, gettaginfo(self.tag_entity, self.tag_index) + self.origin);
		setattachment(self, world, "");
		self.angles = vectoangles(v_forward);
	}
	// Inactive turrets needs to run the think loop,
	// So they can handle animation and wake up if need be.
	if not(self.tur_active) {
		turret_stdproc_track();
		goto finish;
	}
	//This is just wrong :| and unlikely to ever happen.
	/*
	if (self.deadflag != DEAD_NO) {
		goto finish;
	}
	*/
	// This is typicaly used for zaping every target in range
	// turret_fusionreactor uses this to recharge friendlys.
	if (self.shoot_flags & TFL_SHOOT_HITALLVALID) {
		// Do a self.turret_fire for every valid target.
		e = findradius(self.origin,self.target_range);
		while (e) {
			if (e.takedamage) {
				if (turret_validate_target(self,e,self.target_validate_flags)) {
					self.enemy = e;
					turret_do_updates(self);
					if (self.turret_firecheckfunc())
						turret_fire();
				}
			}
			e = e.chain;
		}
		self.enemy = world;
	} else if (self.shoot_flags & TFL_SHOOT_CUSTOM) {
		// This one is doing something.. oddball. assume its handles what needs to be handled.
		// Predict?
		if not(self.aim_flags & TFL_AIM_NO)
			self.tur_aimpos = turret_stdproc_aim_generic();

		// Turn & pitch?
		if not(self.track_flags & TFL_TRACK_NO)
			turret_stdproc_track();

		turret_do_updates(self);
		// Fire?
		if (self.turret_firecheckfunc())
			turret_fire();
	} else {
		// Special case for volly always. if it fired once it must compleate the volly.
		if (self.shoot_flags & TFL_SHOOT_VOLLYALWAYS)
			if (self.volly_counter != self.shot_volly) {
				// Predict or whatnot
				if not(self.aim_flags & TFL_AIM_NO)
					self.tur_aimpos = turret_stdproc_aim_generic();

				// Turn & pitch
				if not(self.track_flags & TFL_TRACK_NO)
					turret_stdproc_track();

				turret_do_updates(self);
				// Fire!
				if (self.turret_firecheckfunc() != 0)
					turret_fire();

				if (self.turret_postthink)
					self.turret_postthink();

				goto finish;
			}
		// Check if we have a vailid enemy, and try to find one if we dont.
		// g_turrets_targetscan_maxdelay forces a target re-scan this often
		float do_target_scan = FALSE;
		if ((self.target_select_time + g_turrets_targetscan_maxdelay) < time)
			do_target_scan = 1;

		// Old target (if any) invalid?
		if (turret_validate_target(self,self.enemy,self.target_validate_flags) <= 0)
			do_target_scan = 1;

		// But never more often then g_turrets_targetscan_mindelay!
		if (self.target_select_time + g_turrets_targetscan_mindelay > time)
			do_target_scan = 0;

		if (do_target_scan) {
			self.enemy = turret_select_target();
			self.target_select_time = time;
		}
		// No target, just go to idle, do any custom stuff and bail.
		if (self.enemy == world) {
			// Turn & pitch
			if not(self.track_flags & TFL_TRACK_NO)
				turret_stdproc_track();

			// do any per-turret stuff
			if (self.turret_postthink)
				self.turret_postthink();

			// And bail.
			goto finish;
		} else
			self.lip = time + g_turrets_aimidle_delay; // Keep track of the last time we had a target.

		// Predict?
		if not(self.aim_flags & TFL_AIM_NO)
			self.tur_aimpos = turret_stdproc_aim_generic();

		// Turn & pitch?
		if not(self.track_flags & TFL_TRACK_NO)
			turret_stdproc_track();

		turret_do_updates(self);
		// Fire?
		if (self.turret_firecheckfunc())
			turret_fire();
	}
	// do any per-turret stuff
	if (self.turret_postthink)
		self.turret_postthink();
:finish
	if (tag_entity_restore) {
		self.tag_entity = tag_entity_restore;
		self.tag_index = tag_index_restore;
		setorigin(self, tag_origin_restore);
		self.angles = tag_angles_restore;
	}
}

void() turret_fire {
	if (g_turrets_nofire != 0)
		return;

	self.turret_firefunc();
	self.attack_finished_single = time + self.shot_refire;
	self.ammo -= self.shot_dmg;
	self.volly_counter = self.volly_counter - 1;
	if (self.volly_counter <= 0) {
		self.volly_counter = self.shot_volly;
		if (self.shoot_flags & TFL_SHOOT_CLEARTARGET)
			self.enemy = world;

		if (self.shot_volly > 1)
			self.attack_finished_single = time + self.shot_volly_refire;
	}
}

void() turret_stdproc_fire {
	print("^1Bang, ^3your dead^7 ", self.enemy.netname, "! ^1(turret with no real firefunc)\n");
}

void() turret_activate {
	if (team_mode)
		self.tur_active = self.team;
	else
		self.tur_active = 1;
}

/*
    When .used a turret switch team to activator.team.
    If activator is world, the turrets goes inactive.
*/
void() turret_stdproc_use {
	self.tur_head.team = self.team = activator.team;
	turret_stdproc_setcolormod();
	turret_activate();
}

float turret_precash_done;
void(void) turret_precache {
	if (turret_precash_done)
		return;

	turret_precash_done = TRUE;
	precache_sound("weapons/rocket_impact.wav");
	precache_model("models/turrets/base-gib1.md3");
	precache_model("models/turrets/base-gib2.md3");
	precache_model("models/turrets/base-gib3.md3");
	precache_model("models/turrets/base-gib4.md3");
	precache_model("models/turrets/head-gib1.md3");
	precache_model("models/turrets/head-gib2.md3");
	precache_model("models/turrets/head-gib3.md3");
	precache_model("models/turrets/head-gib4.md3");
	precache_model("models/turrets/terrainbase.md3");
	precache_model("models/turrets/c512.md3");
	precache_model("models/marker.md3");
}

float turret_count;
void(void) turret_stdproc_init_delayed {
	entity e;
	if not(team_mode)
		self.team = -1; // Group all turrets into the same team iso they dont kill eachother.
	else {
		if (self.targetname != "") {
			e = find(world, target, self.targetname);
			if (e != world) {
				self.team = e.team;
			}
		}
	}
	self.tur_head.team = self.team;
	if (!self.tur_defend)
	if (self.target != "") {
		self.tur_defend = find(world, targetname, self.target);
		if (self.tur_defend == world)
			self.target = "";
	}
	turret_activate();
	turret_stdproc_setcolormod();
	// Initiate the main AI loop
	self.think = turret_think;
	++turret_count;
	self.nextthink = time + self.ticrate + (turret_count * sys_ticrate);
}

/*
* Standard turret initialization. use this!
* (unless you have a very good reason not to)
* if the return value is 0, the turret should be removed.
*/
float(string cvar_base_name, string base, string head) turret_stdproc_init {
	// Are turrets allowed atm?
	if (cvar("g_turrets") == 0)
		return 0;

	turret_precache();
	// Better more then once then never.
	// turret_gibs_precash();
	// Terrainbase spawnflag. This puts a enlongated model
	// under the turret, so it looks ok on uneaven surfaces.
	if (self.spawnflags & TSF_TERRAINBASE) {
		entity tb;
		//precache_model("models/turrets/terrainbase.md3");
		tb = spawn();
		setmodel(tb,"models/turrets/terrainbase.md3");
		tb.maxs_z = -1;
		setsize(tb, tb.mins, tb.maxs);
		setorigin(tb, self.origin);
		tb.solid = SOLID_BBOX;
		//makestatic(tb);
	}
	self.cvar_basename = cvar_base_name;
	load_unit_settings(self,self.cvar_basename,0);
	/*
	* Try to guess some reasonaly defaults
	* for missing params and do sanety checks
	* thise checks could produce some "interesting" results
	* if it hits a glitch in my logic :P so try to set as mutch
	* as possible beforehand.
	*/
	if not(self.ticrate) {
		if (self.turrcaps_flags & TFL_TURRCAPS_SUPPORT)
			self.ticrate = 0.2; // Support units generaly dont need to have a high speed ai-loop
		else
			self.ticrate = 0.05; // 10 fps for normal turrets
	}
	self.ticrate = bound(0.05,self.ticrate,60); // keep it sane
	// General stuff
	if (self.netname == "")
		self.netname = self.classname;

	if (!self.respawntime)
		self.respawntime = 60;

	self.respawntime = max(-1,self.respawntime);
	if (!self.health)
		self.health = 1000;

	self.tur_health = max(1,self.health);
	if (!self.turrcaps_flags)
		self.turrcaps_flags = TFL_TURRCAPS_RADIUSDMG | TFL_TURRCAPS_MEDPROJ | TFL_TURRCAPS_PLAYERKILL;

	if (!self.damage_flags)
		self.damage_flags = TFL_DMG_YES | TFL_DMG_RETALIATE | TFL_DMG_AIMSHAKE;

	// Shot stuff.
	if (!self.shot_refire)
		self.shot_refire = 1;

	self.shot_refire = bound(0.01,self.shot_refire,9999);
	if (!self.shot_dmg)
		self.shot_dmg = self.shot_refire * 50;

	self.shot_dmg = max(1,self.shot_dmg);
	if (!self.shot_radius)
		self.shot_radius = self.shot_dmg * 0.5;

	self.shot_radius = max(1,self.shot_radius);
	if (!self.shot_speed)
		self.shot_speed = 2500;

	self.shot_speed = max(1,self.shot_speed);
	if (!self.shot_spread)
		self.shot_spread = 0.0125;

	self.shot_spread = bound(0.0001,self.shot_spread,500);
	if (!self.shot_force)
		self.shot_force = self.shot_dmg * 0.5 + self.shot_radius * 0.5;

	self.shot_force = bound(0.001,self.shot_force,WORLD_MAX_SHOT_DISTANCE * 0.5);
	if (!self.shot_volly)
		self.shot_volly = 1;

	self.shot_volly = bound(1,self.shot_volly,floor(self.ammo_max / self.shot_dmg));
	if (!self.shot_volly_refire)
		self.shot_volly_refire = self.shot_refire * self.shot_volly;

	self.shot_volly_refire = bound(self.shot_refire,self.shot_volly_refire,60);
	if (!self.firecheck_flags)
		self.firecheck_flags = TFL_FIRECHECK_WORLD | TFL_FIRECHECK_DEAD | TFL_FIRECHECK_DISTANCES |
				TFL_FIRECHECK_LOS | TFL_FIRECHECK_AIMDIST | TFL_FIRECHECK_TEAMCECK |
				TFL_FIRECHECK_OWM_AMMO | TFL_FIRECHECK_REFIRE | TFL_FIRECHECK_WORLD;

	// Range stuff.
	if (!self.target_range)
		self.target_range = self.shot_speed * 0.5;

	self.target_range = bound(0,self.target_range,WORLD_MAX_SHOT_DISTANCE);
	if (!self.target_range_min)
		self.target_range_min = self.shot_radius * 2;

	self.target_range_min = bound(0,self.target_range_min,WORLD_MAX_SHOT_DISTANCE);
	//if (!self.target_range_fire)
	//    self.target_range_fire = self.target_range * 0.8;

	//self.target_range_fire = bound(0,self.target_range_fire,WORLD_MAX_SHOT_DISTANCE);
	if (!self.target_range_optimal)
		self.target_range_optimal = self.target_range * 0.5;

	self.target_range_optimal = bound(0,self.target_range_optimal,WORLD_MAX_SHOT_DISTANCE);
	// Aim stuff.
	if (!self.aim_maxrot)
		self.aim_maxrot = 90;

	self.aim_maxrot = bound(0,self.aim_maxrot,360);
	if (!self.aim_maxpitch)
		self.aim_maxpitch = 20;

	self.aim_maxpitch = bound(0,self.aim_maxpitch,90);
	if (!self.aim_speed)
		self.aim_speed = 36;

	self.aim_speed = bound(0.1,self.aim_speed, 1000);
	if (!self.aim_firetolerance_dist)
		self.aim_firetolerance_dist = 5 + (self.shot_radius * 2);

	self.aim_firetolerance_dist = bound(0.1,self.aim_firetolerance_dist,WORLD_MAX_SHOT_DISTANCE);
	if (!self.aim_flags) {
		self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
		if (self.turrcaps_flags & TFL_TURRCAPS_RADIUSDMG)
			self.aim_flags |= TFL_AIM_GROUND2;
	}
	// Sill the most tested (and aim-effective)
	if (!self.track_type) self.track_type = TFL_TRACKTYPE_STEPMOTOR;
	if (self.track_type != TFL_TRACKTYPE_STEPMOTOR) {
		// Fluid / Ineria mode. Looks mutch nicer, bit experimental &
		// Can inmapt aim preformance alot.
		// needs a bit diffrent aimspeed
		if (!self.aim_speed)
			self.aim_speed = 180;

		self.aim_speed = bound(0.1,self.aim_speed, 1000);
		if (!self.track_accel_pitch)
			self.track_accel_pitch = 0.5;

		if (!self.track_accel_rot)
			self.track_accel_rot  = 0.5;

		if (!self.track_blendrate)
			self.track_blendrate  = 0.35;
	}
	if (!self.track_flags)
		self.track_flags = TFL_TRACK_PITCH | TFL_TRACK_ROT;

	// Target selection stuff.
	if (!self.target_select_rangebias)
		self.target_select_rangebias = 1;

	self.target_select_rangebias = bound(-10,self.target_select_rangebias,10);
	if (!self.target_select_samebias)
		self.target_select_samebias = 1;

	self.target_select_samebias = bound(-10,self.target_select_samebias,10);
	if (!self.target_select_anglebias)
		self.target_select_anglebias = 1;

	self.target_select_anglebias = bound(-10,self.target_select_anglebias,10);
	if (!self.target_select_missilebias)
		self.target_select_missilebias = -10;

	self.target_select_missilebias = bound(-10,self.target_select_missilebias,10);
	self.target_select_playerbias = bound(-10,self.target_select_playerbias,10);
	if (!self.target_select_flags) {
			self.target_select_flags = TFL_TARGETSELECT_LOS | TFL_TARGETSELECT_TEAMCHECK
					| TFL_TARGETSELECT_RANGELIMTS | TFL_TARGETSELECT_ANGLELIMITS;

		if (self.turrcaps_flags & TFL_TURRCAPS_MISSILEKILL)
			self.target_select_flags |= TFL_TARGETSELECT_MISSILES;

		if (self.turrcaps_flags & TFL_TURRCAPS_PLAYERKILL)
			self.target_select_flags |= TFL_TARGETSELECT_PLAYERS;
		//else
		//    self.target_select_flags = TFL_TARGETSELECT_NO;
	}
	self.target_validate_flags = self.target_select_flags;
	// Ammo stuff
	if (!self.ammo_max)
		self.ammo_max = self.shot_dmg * 10;

	self.ammo_max = max(self.shot_dmg,self.ammo_max);
	if (!self.ammo)
		self.ammo = self.shot_dmg * 5;

	self.ammo = bound(0,self.ammo,self.ammo_max);
	if (!self.ammo_recharge)
		self.ammo_recharge = self.shot_dmg * 0.5;

	self.ammo_recharge = max(0,self.ammo_recharge);
	// Convert the recharge from X per sec to X per ticrate
	self.ammo_recharge = self.ammo_recharge * self.ticrate;
	if (!self.ammo_flags)
		self.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE;

	// Damage stuff
	if (self.spawnflags & TSL_NO_RESPAWN)
		if not(self.damage_flags & TFL_DMG_DEATH_NORESPAWN)
			self.damage_flags |= TFL_DMG_DEATH_NORESPAWN;

	// End of default & sanety checks, start building the turret.
	// Spawn extra bits
	self.tur_head = spawn();
	self.tur_head.netname = self.tur_head.classname = "turret_head";
	self.tur_head.owner = self;
	setmodel(self,base);
	setmodel(self.tur_head,head);
	vector extra_maxs = gettaginfo(self, gettagindex(self,"tag_head")) - self.origin;
	extra_maxs_x = 0;
	extra_maxs_y = 0;
	setsize(self, '-32 -32 0', '32 32 32' + extra_maxs);
	self.pos1 = self.origin;
	// Put pices in place
	if (self.tur_defend)
		self.idle_aim = self.tur_head.angles + turret_angleofs(self.tur_head,self.tur_defend);
	else
		self.idle_aim = '0 0 0';

	if (!self.health)
		self.health = 150;

	self.tur_health = self.health;
	self.tur_head.health = self.health;
	self.solid = SOLID_BBOX;
	self.takedamage = DAMAGE_AIM;
	self.movetype = MOVETYPE_TOSS;
	// Attach stdprocs. override when and what needed
	if (self.turrcaps_flags & TFL_TURRCAPS_SUPPORT) {
		self.turret_score_target = turret_stdproc_targetscore_support;
		self.turret_firecheckfunc = turret_stdproc_firecheck;
		self.turret_firefunc = turret_stdproc_fire;
		//self.turret_postthink = turret_stdproc_nothing;
		self.event_damage = turret_stdproc_damage;
	} else {
		self.turret_score_target = turret_stdproc_targetscore_generic;
		self.turret_firecheckfunc = turret_stdproc_firecheck;
		self.turret_firefunc = turret_stdproc_fire;
		//self.turret_postthink = turret_stdproc_nothing;
		self.event_damage = turret_stdproc_damage;
		//self.turret_addtarget = turret_stdproc_false;
	}
	self.use = turret_stdproc_use;
	self.bot_attack = TRUE;
	self.view_ofs = '0 0 0';
	// Its all good.
	self.classname = "turret_main";
	entity_initialize(self, turret_stdproc_init_delayed, INITPRIO_FIRST);
	return 1;
}

void turret_readcvars() {
	entity e;
	CVAR_CACHE(g_turrets_aimidle_delay);
	CVAR_CACHE(g_turrets_nofire);
	CVAR_CACHE(g_turrets_targetscan_maxdelay);
	CVAR_CACHE(g_turrets_targetscan_mindelay);
	CVAR_CACHE(g_turrets_targetscan_playersonly);
	e = nextent(world);
	while (e) {
		if (e.tur_head != world) {
			load_unit_settings(e,e.cvar_basename,1);
			if (e.turret_postthink) {
				entity oldself = self;
				self = e;
				e.turret_postthink();
				self = oldself;
			}
		}
		e = nextent(e);
	}
}

float(entity e_turret,entity e_target) turret_stdproc_targetscore_support {
	float score; // Total score
	float s_score = 0,d_score;
	if (e_turret.enemy == e_target) s_score = 1;
	d_score = min(e_turret.target_range_optimal,tvt_dist) / max(e_turret.target_range_optimal,tvt_dist);
	score = (d_score * e_turret.target_select_rangebias) +
			(s_score * e_turret.target_select_samebias);
	return score;
}

/*
* Generic bias aware score system.
*/
float(entity e_turret,entity e_target) turret_stdproc_targetscore_generic {
	//vector v_tmp;
	float d_dist; // Defendmode Distance
	float score; // Total score
	float d_score; // Distance score
	float a_score; // Angular score
	float m_score = 0; // missile score
	float p_score = 0; // player score
	//float da_score; // Distance from aimpoint score
	float ikr; // ideal kill range
	if (!e_target) return 0;
	//if (e_target == e_turret.enemy) s_score = 1;
	if (e_turret.tur_defend) {
		d_dist = vlen(turret_real_origin(e_target) - e_turret.tur_defend.origin);
		ikr = vlen(e_turret.origin - e_turret.tur_defend.origin);
		d_score = 1 - d_dist / e_turret.target_range;
	} else {
		// Make a normlized value base on the targets distance from our optimal killzone
		ikr = e_turret.target_range_optimal;
		d_score = min(ikr,tvt_dist) / max(ikr,tvt_dist);
	}
	/*
	// Determine the maximum time it could take this turrent to aim at someting.
	max_aim_delay = (max(e_turret.aim_maxrot,e_turret.aim_maxpitch) / e_turret.aim_speed * 2);
	// Find out how long it would take to aim at this taget.
	aim_delay = (thadf+0.01) / e_turret.aim_speed;
	// Turn this info into a normalized value.
	aim_delay = (min(max_aim_delay,aim_delay) / max_aim_delay);
	a_score = 1 - aim_delay;
	*/
	//a_score = 1 - (tvt_thadf / max(e_turret.aim_maxrot,e_turret.aim_maxpitch));
	a_score = 1 - tvt_thadf / e_turret.aim_maxrot;
	if ((e_turret.target_select_missilebias > 0) && (e_target.flags & FL_PROJECTILE))
		m_score = 1;

	if ((e_turret.target_select_playerbias > 0) && (e_target.flags & FL_CLIENT))
		p_score = 1;

	d_score = max(d_score,0);
	a_score = max(a_score,0);
	m_score = max(m_score,0);
	p_score = max(p_score,0);
	score = (d_score * e_turret.target_select_rangebias) +
			(a_score * e_turret.target_select_anglebias) +
			(m_score * e_turret.target_select_missilebias) +
			(p_score * e_turret.target_select_playerbias);
	if (e_turret.target_range < vlen(e_turret.tur_shotorg - turret_real_origin(e_target)))
		score *= 0.001;

	return score;
}

void(void) turret_projectile_explode {
	entity e = self.enemy;
	entity o = self.owner;
	//w_deathtypestring = "got hunted to extinction";
	projectile_explode();
	// Target dead, get another is still targeting the same.
	if ((e.deadflag != DEAD_NO) && (e == o.enemy))
		o.enemy = world;
}

void(void) turret_projectile_think_explode {
	other = world;
	turret_projectile_explode();
}

void(void) turret_projectile_touch_explode {
	if (other)
	if ((other == self.owner) || (other == self.owner.tur_head) || (other == self.owner.tag_entity))
		return;

	turret_projectile_explode();
}
