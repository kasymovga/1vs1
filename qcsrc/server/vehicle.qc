void(vector _mins, vector _maxs, float start_offs, float back, float up) vehicle_write_common {
	net_write_coord(MSG_ENTITY, up);
	net_write_coord(MSG_ENTITY, back);
	net_write_coord(MSG_ENTITY, start_offs);
	net_write_vector(MSG_ENTITY, _mins);
	net_write_vector(MSG_ENTITY, _maxs);
}

void(entity plr, entity veh, float start_offs, float back, float up) vehicle_adjust_player_position {
	physics_flags = plr.flags;
	if (plr != veh.owner || plr.vehicle != veh) {
		physics_velocity = plr.velocity;
		return;
	}
	makevectors(plr.v_angle);
	vector v = veh.origin;
	v_z += start_offs;
	trace_box(v, '-8 -8 -8', '8 8 8', v - v_forward * back, TRACE_MOVE_WORLDONLY, world);
	v = trace_endpos;
	trace_box(v, '-8 -8 -8', '8 8 8', v + v_up * up, TRACE_MOVE_WORLDONLY, world);
	setorigin(plr, trace_endpos - plr.view_ofs);
	physics_velocity = plr.velocity = veh.velocity;
	if (veh.player_physic)
		veh.player_physic.SendFlags |= 2;
}

float(entity plr, float eject) vehicle_extract_player {
	if not(plr.vehicle)
		return 0;

	entity oldself = self;
	self = plr.vehicle;
	self.bot_attack = (self.team && team_mode);
	vector exit_origin;
	makevectors(self.angles);
	float exit_up = self.maxs_z - plr.maxs_z;
	float eject_range = self.maxs_z - plr.mins_z;
	float range = (self.maxs_x + plr.maxs_x) * 1.5;
	if (eject)
		exit_origin = self.origin + '0 0 1' * eject_range;
	else
		exit_origin = self.origin - v_right * range + '0 0 1' * exit_up;

	trace_box(self.origin + '0 0 1' * exit_up, plr.mins, plr.maxs, exit_origin, TRACE_MOVE_NOMONSTERS, plr);
	if not(eject) {
		if (trace_fraction < 1) {
			exit_origin = self.origin + v_right * range + '0 0 1' * exit_up;
			trace_box(self.origin + '0 0 1' * exit_up, plr.mins, plr.maxs, exit_origin, TRACE_MOVE_NOMONSTERS, plr);
		}
		if (trace_fraction < 1) {
			exit_origin = self.origin + v_forward * range + '0 0 1' * exit_up;
			trace_box(self.origin + '0 0 1' * exit_up, plr.mins, plr.maxs, exit_origin, TRACE_MOVE_NOMONSTERS, plr);
		}
		if (trace_fraction < 1) {
			exit_origin = self.origin - v_forward * range + '0 0 1' * exit_up;
			trace_box(self.origin + '0 0 1' * exit_up, plr.mins, plr.maxs, exit_origin, TRACE_MOVE_NOMONSTERS, plr);
		}
		if (trace_fraction < 1)
			trace_endpos = self.origin + '0 0 1' * exit_up;
	}
	exit_origin = trace_endpos;
	plr.vehicle_exit_time = time;
	plr.PlayerPhysplug = NULL;
	self.owner = NULL;
	plr.vehicle = NULL;
	plr.lastpushtime = time;
	plr.angles_x = 0;
	plr.angles_y = self.angles_y;
	plr.angles_z = 0;
	client_view_angles_set(plr, plr.angles);
	plr.takedamage = DAMAGE_AIM;
	if not(team_mode)
		self.team = 0;
	else
		self.team = self.enemy.team;

	teleport_origin_set(plr, exit_origin, 0);
	player_physics_setup(plr);
	plr.velocity = self.velocity;
	if (eject) {
		plr.velocity = plr.velocity + (v_up + v_forward * 0.25) * 200;
	}
	physics_velocity = plr.velocity;
	if (self.player_physic)
		remove(self.player_physic);

	self.player_physic = NULL;
	self.vehicle_exit(eject);
	self = oldself;
	return 1;
}

void(void) vehicle_stdproc_setcolormod {
	self.colormod = '0 0 0';
	if (self.tur_head) self.tur_head.colormod = '0 0 0';
	turret_stdproc_setcolormod();
}

void(void) vehicle_stdproc_regen {
	float smax,hmax;
	smax = self.shield_max;
	hmax = self.health_max;
	if (self.vehicle_flags & VHF_HASSHIELD)
	if (self.vehicle_flags & VHF_SHIELDREGEN)
	if (self.vehicle_shield < smax)
	if (self.dmg_time + self.shield_regen_dmgpause < time) {
		self.vehicle_shield = min(self.vehicle_shield + self.shield_regen * sys_ticrate, smax);
		if (self.owner)
			self.owner.vehicle_shield = self.vehicle_shield / smax;
	}
	if (self.vehicle_flags & VHF_HEALTHREGEN)
	if (self.dmg_time + self.health_regen_dmgpause < time)
	if (self.health < hmax) {
		self.health = min(self.health + self.health_regen * sys_ticrate, hmax);
		if (self.owner)
			self.owner.vehicle_health = self.health / hmax;
	}
}

void(void) vehicle_shieldhit_think {
	self.alpha = self.alpha - 0.125;
	if not(self.alpha <= 0) {
		self.nextthink = time;
	} else {
		setmodel(self,"");
		self.alpha = -1;
	}
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) vehicle_stdproc_damage {
	float ddmg_take;
	if (team_mode && self.team == attacker.team && self != attacker) {
		if (g_friendlyfire)
			_damage = _damage * g_friendlyfire;
		else
			return;
	}
	self.dmg_inflictor = attacker;
	self.dmg_time = time;
	if ((self.vehicle_flags & VHF_HASSHIELD) && (self.vehicle_shield > 0)) {
		if not (self.killindicator)
			self.killindicator = spawn();

		entity sh;
		sh = self.killindicator;
		sh.colormod = '1 1 1';
		sh.alpha = 0.5;
		sh.scale  = (128 / vlen(self.maxs - self.mins))*2;
		sh.effects = EFFECT_LOWPRECISION;
		sh.angles = vectoangles(normalize(hitloc - self.origin)) - self.angles;
		setmodel(sh,"models/vhshield.md3");
		setattachment(sh,self,"");
		sh.think = vehicle_shieldhit_think;
		sh.nextthink = time;
		self.vehicle_shield -= _damage;
		if (self.vehicle_shield < 0) {
			sh.colormod = '10 0 -1';
			ddmg_take = fabs(self.vehicle_shield);
			self.vehicle_shield = 0;
			self.health -= ddmg_take;
		}
	} else
		self.health -= _damage;

	if (random() < 0.5)
		sound(self, CHAN_TRIGGER, "onslaught/ons_hit1.wav", VOL_BASE, ATTN_NORM);
	else
		sound(self, CHAN_TRIGGER, "onslaught/ons_hit2.wav", VOL_BASE, ATTN_NORM);

	if (self.owner) {
		self.owner.vehicle_health = self.health / self.health_max;

		if (self.vehicle_flags & VHF_HASSHIELD)
			self.owner.vehicle_shield = self.vehicle_shield / cvar(strcat(self.cvar_basename,"_shield"));

	}
	if (self.health < 1) {
		if (self.owner)
			vehicle_extract_player(self.owner, TRUE);

		self.vehicle_die();
	}
}

void(void) vehicle_reset {
	if (self.owner)
		vehicle_extract_player(self.owner, TRUE);

	self.vehicle_spawn();
}

var void(float killed) vehicle_PlayerClear_NextLink;
void vehicle_PlayerClear(float killed) {
	vehicle_extract_player(self, TRUE);
	vehicle_PlayerClear_NextLink(killed);
}

var void() vehicle_player_effects_next;
void vehicle_player_effects() {
	if (self.vehicle)
	if (self.vehicle.vehicle_flags & VHF_HIDEPLAYER)
		self.effects |= EFFECT_NODRAW;

	vehicle_player_effects_next();
}

var float(void) vehicle_weapon_throw_handle_NextLink;
float(void) vehicle_weapon_throw_handle {
	if (vehicle_extract_player(self, FALSE))
		return TRUE;

	return vehicle_weapon_throw_handle_NextLink();
}

var entity(entity) vehicle_player_entity_next_link;
entity(entity pl) vehicle_player_entity {
	if (pl.vehicle)
		return pl.vehicle;

	return vehicle_player_entity_next_link(pl);
}

var float(float f) vehicle_weapon_frame_switch_mod_next;
float(float f) vehicle_weapon_frame_switch_mod {
	if (akimbo_owner(self).vehicle) {
		return 0;
	}
	return f;
}

void(float d, float ed, float r, float f) vehicle_blowup {
	damage_radius(self, self.dmg_inflictor, d, ed, r, world, f, EFFECT_IMPACT_ROCKET, WEAPON_ROCKET_LAUNCHER, world);
	self.alpha = -1;
	self.nextthink = time + 10;
	self.think = self.vehicle_spawn;
	self.velocity = '0 0 0';
}

float vehicle_init_done;
void(void) vehicle_init {
	if (vehicle_init_done)
		return;

	precache_sound("onslaught/ons_hit1.wav");
	precache_sound("onslaught/ons_hit2.wav");
	vehicle_init_done = TRUE;
	vehicle_PlayerClear_NextLink = plugin_chain_player_clear;
	plugin_chain_player_clear = vehicle_PlayerClear;
	vehicle_player_effects_next = plugin_chain_player_effects;
	plugin_chain_player_effects = vehicle_player_effects;
	vehicle_weapon_throw_handle_NextLink = plugin_chain_weapon_throw_handle;
	plugin_chain_weapon_throw_handle = vehicle_weapon_throw_handle;
	vehicle_player_entity_next_link = plugin_chain_player_entity;
	plugin_chain_player_entity = vehicle_player_entity;
	vehicle_weapon_frame_switch_mod_next = plugin_chain_weapon_frame_switch_mod;
	plugin_chain_weapon_frame_switch_mod = vehicle_weapon_frame_switch_mod;
	addstat(STAT_SPIDERBOT_ROCKETS, STAT_INT,   rockets);
	addstat(STAT_SPIDERBOT_RELOAD,  STAT_FLOAT, rockets_reload);
	addstat(STAT_SPIDERBOT_HEAT,    STAT_FLOAT, vehicle_heat);
	addstat(STAT_SPIDERBOT_HEALTH,  STAT_FLOAT, vehicle_health);
	addstat(STAT_SPIDERBOT_SHIELD,  STAT_FLOAT, vehicle_shield);
}

float(vector ang, float() phys_plug, float(entity, float) phys_send) vehicle_enter {
	if (other.vehicle_exit_time >= time)
		return FALSE;

	if (other.classname != "player")
		return FALSE;

	if not(player_can_fire(other, FALSE))
		return FALSE;

	if (other.vehicle != world)
		return FALSE;

	if (team_mode)
	if (self.team)
	if (self.team != other.team)
		return FALSE;

	other.vehicle_health = (self.health / self.health_max);
	if (self.vehicle_flags & VHF_HASSHIELD)
		other.vehicle_shield = (self.vehicle_shield / self.shield_max);
	else
		other.vehicle_shield = -1;

	if (self.vehicle_flags & VHF_HEAT)
		other.vehicle_heat = self.vehicle_heat;
	else
		other.vehicle_heat = -1;

	if (self.vehicle_flags & VHF_HASROCKETS) {
		other.rockets = self.rockets;
		other.rockets_reload = self.rockets_reload;
	} else {
		other.rockets = -1;
	}
	self.owner = other;
	self.owner.angles         = self.angles;
	self.owner.takedamage     = DAMAGE_NO;
	self.owner.solid          = SOLID_NOT;
	self.owner.PlayerPhysplug = phys_plug;
	self.owner.vehicle        = self;
	self.team                 = self.owner.team;
	if (clienttype(other) == CLIENTTYPE_REAL) {
		ang_z = 0;
		ang_x = -ang_x;
		client_view_angles_set(other, ang);
		self.bot_nextthink = 0;
	} else {
		self.bot_nextthink = time + 5;
	}
	self.player_physic = spawn();
	self.player_physic.viewmodelforclient = self.owner;
	self.player_physic.vehicle = self;
	self.bot_attack = TRUE;
	net_link_entity(self.player_physic, FALSE, 0, phys_send);
	return TRUE;
}

float(void) vehicle_stdproc_customize {
	if (self.deadflag == DEAD_DEAD)
		return FALSE;

	return TRUE;
}

void(float n) vehicle_explode {
	float i, f;
	vector o = ENTITY_CENTER(self);
	for (i = 0; i < n; i++) {
		f = random();
		if(f < 0.3)
			onslaught_throwgib(o, (100 * randomvec() - '1 1 1') * 11 + '0 0 20', "models/onslaught/gen_gib1.md3", 6, TRUE);
		else if(f > 0.7)
			onslaught_throwgib(o, (100 * randomvec() - '1 1 1') * 12 + '0 0 20', "models/onslaught/gen_gib2.md3", 6, TRUE);
		else
			onslaught_throwgib(o, (100 * randomvec() - '1 1 1') * 13 + '0 0 20', "models/onslaught/gen_gib3.md3", 6, TRUE);
	}
}

void(string name, void() delayed_init) vehicle_stdproc_init {
	self.health_max = cvar(strcat("g_vehicle_", name, "_health"));
	self.health_regen = cvar(strcat("g_vehicle_", name, "_health_regen"));
	self.health_regen_dmgpause = cvar(strcat("g_vehicle_", name, "_health_regen_dmgpause"));
	self.shield_max = cvar(strcat("g_vehicle_", name, "_shield"));
	self.shield_regen = cvar(strcat("g_vehicle_", name, "_shield_regen"));
	self.shield_regen_dmgpause = cvar(strcat("g_vehicle_", name, "_shield_regen_dmgpause"));
	self.bot_attack = (self.team && team_mode);
	entity_initialize(self, delayed_init, INITPRIO_DROPTOFLOOR);
}
