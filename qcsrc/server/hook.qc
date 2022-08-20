/*============================================

      Wazat's Nexuiz Grappling Hook

        Contact: Wazat1@gmail.com

============================================*/
float g_grappling_hook;
float g_balance_grapplehook_break_damage;
float g_balance_grapplehook_damage;
float g_balance_grapplehook_damage_interval;
float g_balance_grapplehook_gravity;
float g_balance_grapplehook_health;
float g_balance_grapplehook_speed_fly;
float g_balance_grapplehook_onground_pullfactor;
float g_balance_grapplehook_team_friendly;
string sv_announcer_extra_hooked;
float HOOK_ABILITY;

.string aiment_classname;
.float aiment_deadflag;
.float hook_attack_time;

void(entity ent, entity e) hook_follow {
	ent.movetype = MOVETYPE_FOLLOW; // make the hole follow
	ent.solid = SOLID_NOT; // MOVETYPE_FOLLOW is always non-solid
	ent.aiment = e; // make the hole follow bmodel
	if (ent.aiment.takedamage)
		ent.hook_attack_time = time + g_balance_grapplehook_damage_interval;

	ent.punchangle = e.angles; // the original angles of bmodel
	ent.view_ofs = ent.origin - e.origin; // relative origin
	ent.v_angle = ent.angles - e.angles; // relative angles
	ent.aiment_classname = strzone(e.classname);
	ent.aiment_deadflag = e.deadflag;
	if (sv_announcer_extra_hooked != "")
	if (e.classname == "player")
	if (e.deadflag == DEAD_NO) {
		announce(e, sv_announcer_extra_hooked, "");
		announce(ent.owner, sv_announcer_extra_hooked, "");
	}
}

float(entity ent) hook_lost_follow {
	if (ent.aiment) {
		if (ent.aiment.classname != ent.aiment_classname)
			return 1;

		if (ent.aiment.deadflag != ent.aiment_deadflag)
			return 1;
	}
	return 0;
}

.float hook_length;
.float hook_switchweapon;

void(entity pl) hook_remove {
	if (pl.hook == world)
		return;

	remove(pl.hook.hook);
	remove(pl.hook);
	pl.hook = world;
	if (pl.movetype == MOVETYPE_FLY)
		pl.movetype = MOVETYPE_WALK;

	//pl.disableclientprediction = FALSE;
}

void() hook_think;
void hook_stop() {
	pointparticles(particleeffectnum("grapple_impact"), self.origin, '0 0 0', 1);
	sound (self, CHAN_PROJECTILE, "weapons/hook_impact.wav", VOL_BASE, ATTN_NORM);

	self.state = 1;
	self.hook.think = hook_think;
	self.hook.nextthink = time;
	self.touch = stdproc_nothing;
	self.velocity = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.hook_length = -1;
	self.hook.SendFlags |= 16;
}

float(entity to, float sf) hook_send {
	entity _hook = self.owner;
	net_write_byte(MSG_ENTITY, NET_CSQC_HOOK);
	sf = sf & 15;
	if (to == _hook.owner)
	if (_hook.state == 1)
		sf |= 16;

	net_write_byte(MSG_ENTITY, sf);
	if (sf & 1)
		net_write_byte(MSG_ENTITY, num_for_edict(_hook.owner));

	vector v;
	if (sf & 2) {
		if (_hook.owner.weapon == WEP_HOOK) {
			entity oldself = self;
			self = _hook;
			v = weapon_shotorg_adjust('26 9 -16', TRUE, TRUE, FALSE);
			self = oldself;
		} else
			v = '8 -8 -12';

		net_write_char(MSG_ENTITY, v_x);
		net_write_char(MSG_ENTITY, v_y);
		net_write_char(MSG_ENTITY, v_z);
	}
	if (sf & 4) {
		v = _hook.pos1;
		net_write_coord(MSG_ENTITY, v_x);
		net_write_coord(MSG_ENTITY, v_y);
		net_write_coord(MSG_ENTITY, v_z);
	}
	if (sf & 8) {
		v = _hook.pos2;
		net_write_coord(MSG_ENTITY, v_x);
		net_write_coord(MSG_ENTITY, v_y);
		net_write_coord(MSG_ENTITY, v_z);
	}
	if (sf & 16) {
		net_write_coord(MSG_ENTITY, _hook.hook_length);
	}
	return TRUE;
}

void(entity _hook, vector v, vector v0, vector dir) hook_pull_aiment {
	if (_hook.aiment.pushfactor) {
		vector dv = ((v - v0) * dir) * dir;
		float pullfactor = 0.5;
		if (_hook.aiment.flags & FL_ONGROUND)
			pullfactor = 0.5 * g_balance_grapplehook_onground_pullfactor;

		_hook.aiment.velocity = _hook.aiment.velocity - dv * (_hook.aiment.pushfactor / _hook.owner.pushfactor) * pullfactor;
		_hook.aiment.pusher = _hook.owner;
		_hook.aiment.pushltime = time + g_maxpushtime;
	}
}

entity(void) hook_get {
	if (self.hook)
	if (self.hook.state == 1)
		return self.hook;

	return world;
}

void() hook_think {
	vector org, myorg;
	entity oldself = self;
	self = self.owner;
	if (PLAYER_DEAD(self.owner) || self.owner.hook != self) {// how did that happen?
		// well, better fix it anyway
		remove(self.hook);
		remove(self);
		goto end;
	}
	if (hook_lost_follow(self)) {
		hook_remove(self.owner);
		goto end;
	}
	self.hook.nextthink = time;
	if (self.owner.weapon == WEP_HOOK)
		org = gettaginfo(self.owner.exteriorweaponentity, gettagindex(self.owner.exteriorweaponentity, "_")) + v_forward * 20 + v_up * 3;
	else
		org = self.owner.origin + '0 0 12';

	makevectors(self.owner.v_angle);
	if (self.state == 1) {
		if (self.aiment) {
			if not(player_can_fire(self.owner, FALSE)) {
				hook_remove(self.owner);
				goto end;
			}
			if (g_balance_grapplehook_damage_interval)
			if (self.hook_attack_time)
			if (self.aiment.takedamage)
			while (self.hook_attack_time <= time) {
				damage(self.aiment, self.owner, self.owner, g_balance_grapplehook_damage, WEP_HOOK, self.origin, '0 0 0');
				self.hook_attack_time += g_balance_grapplehook_damage_interval;
			}
			if not(self.aiment) {
				hook_remove(self.owner);
				goto end;
			}
		}
	}
	myorg = warpzone_refsys_transform_origin(self, self.owner, self.origin);
	vector a = warpzone_refsys_transform_angles(self, self.owner, self.angles);
	makevectors(a_x * '-1 0 0' + a_y * '0 1 0');
	myorg = myorg + v_forward * (-9);
	if (myorg != self.pos1) {
		self.pos1 = myorg;
		self.hook.SendFlags |= 4;
	}
	if (org != self.pos2) {
		self.pos2 = org;
		self.hook.SendFlags |= 8;
	}
	if (self.owner.teleport_time == time)
		self.hook.SendFlags |= 28;

:end
	self = oldself;
}

void(void) hook_touch {
	PROJECTILE_SKIPNONSOLID
	if (PROJECTILE_OWNER_CHECK())
		return;

	if (projectile_no_impact_check()) {
		hook_remove(self.owner);
		return;
	}
	if (team_mode)
	if (g_balance_grapplehook_team_friendly)
	if (other.team == self.owner.team)
	if (other.classname == "player")
	if (PLAYER_REALLY_ALIVE(other)) {
		hook_remove(self.owner);
		return;
	}
	if (other == world) {
		vector tic;
		tic = self.velocity * sys_ticrate;
		tic = tic + normalize(tic) * vlen(self.maxs - self.mins);
		trace_line(self.origin - tic, self.origin + tic, TRACE_MOVE_NORMAL, self);
		if (trace_fraction < 1 && (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)) {
			hook_remove(self.owner);
			return;
		}
	}
	hook_stop();
	if (other)
		if (other.movetype != MOVETYPE_NONE) {
			hook_follow(self, other);
		}

	//self.owner.disableclientprediction = TRUE;
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) hook_damage {
	if (self.health > 0) {
		float f;
		if (attacker == self.owner)
			f = g_balance_selfdamagepercent;
		else
			f = 1;

		self.health = self.health - _damage * f;
		if (self.health <= 0) {
			if (attacker != self.owner) {
				self.owner.pusher = attacker;
				self.owner.pushltime = time + g_maxpushtime;
			}
			if (g_balance_grapplehook_break_damage)
			if (f)
				damage(self.owner, inflictor, attacker, g_balance_grapplehook_break_damage * f, WEP_HOOK, self.owner.origin, '0 0 0');

			hook_remove(self.owner);
		}
	}
}

void(void) hook_fire {
	entity missile;
	makevectors(self.v_angle);
	// UGLY WORKAROUND: play this on CHAN_WEAPON2 so it can't cut off fire sounds
	sound(self, CHAN_WEAPON2, "weapons/hook_fire.wav", VOL_BASE, ATTN_NORM);
	if (self.weapon == WEP_HOOK) {
		weapon_setup_shot(self, 0, "", 0);
	} else {
		weapon_shotorg = self.origin + self.view_ofs - '0 0 8';
		weapon_shotdir = v_forward;
	}
	pointparticles(particleeffectnum("grapple_muzzleflash"), weapon_shotorg_visual, '0 0 0', 1);
	missile = warpzone_refsys_spawn_same_refsys(self);
	missile.owner = self;
	missile.hook = spawn();
	missile.hook.owner = missile;
	net_link_entity(missile.hook, FALSE, 0, hook_send);
	self.hook = missile;
	missile.classname = "grapplinghook";
	missile.movetype = (g_balance_grapplehook_gravity ? MOVETYPE_TOSS : MOVETYPE_FLY);
	PROJECTILE_MAKETRIGGER(missile);
	setmodel (missile, "models/hook.md3"); // precision set below
	setsize (missile, '-3 -3 -3', '3 3 3');
	setorigin (missile, weapon_shotorg);
	missile.state = 0; // not latched onto anything
	missile.velocity = weapon_shotdir * g_balance_grapplehook_speed_fly;
	weapon_setup_projectile_velocity(missile);
	missile.angles = vectoangles (missile.velocity);
	//missile.glow_color = 250; // 244, 250
	//missile.glow_size = 120;
	missile.touch = hook_touch;
	missile.hook.think = hook_think;
	missile.hook.nextthink = time + 0.1;
	missile.effects = /*EFFECT_FULLBRIGHT | EFFECT_ADDITIVE |*/ EFFECT_LOWPRECISION;
	missile.health = g_balance_grapplehook_health;//120
	missile.event_damage = hook_damage;
	missile.takedamage = DAMAGE_AIM;
	missile.damageforcescale = 0;
	entity oldself = self;
	self = missile.hook;
	hook_think();
	self = oldself;
}

var void() hook_player_think_next;
void() hook_player_think {
	hook_player_think_next();
	float button_hook = self.BUTTON_HOOK;
	if (PLAYER_DEAD(self))
		return;

	float grappling_hook = (g_grappling_hook || (self.abilities & HOOK_ABILITY));
	if (grappling_hook && timeout_status != 2 && self.weapon != WEP_HOOK) {
		// offhand hook controls
		if (button_hook) {
			if not(self.hook || (self.hook_state & HOOK_WAITING_FOR_RELEASE))
			if (time > map_starttime) {
				self.hook_state |= HOOK_FIRING;
				self.hook_state |= HOOK_WAITING_FOR_RELEASE;
			}
		} else {
			self.hook_state |= HOOK_REMOVING;
			self.hook_state &= ~HOOK_WAITING_FOR_RELEASE;
		}
		self.hook_state &= ~HOOK_RELEASING;
		if (self.BUTTON_CROUCH) {
			self.hook_state &= ~HOOK_PULLING;
			//self.hook_state |= HOOK_RELEASING;
		} else {
			self.hook_state |= HOOK_PULLING;
			//self.hook_state &= ~HOOK_RELEASING;
		}
	} else if (!grappling_hook && self.switchweapon != WEP_HOOK) {
		if (button_hook && !self.hook_switchweapon)
			weapon_switch(WEP_HOOK);
	}
	self.hook_switchweapon = button_hook;
	if (!grappling_hook && self.weapon != WEP_HOOK) {
		self.hook_state &= ~HOOK_FIRING;
		self.hook_state |= HOOK_REMOVING;
	}
	if (self.hook_state & HOOK_FIRING) {
		if (self.hook)
			hook_remove(self);

		hook_fire();
		self.hook_state &= ~HOOK_FIRING;
	} else if (self.hook_state & HOOK_REMOVING) {
		if (self.hook)
			hook_remove(self);

		self.hook_state &= ~HOOK_REMOVING;
	}
}

var void() hook_client_connect_real_next;
void hook_client_connect_real(void) {
	// this function has been modified for Nexuiz
	// don't remove these lines! old server or demos coud overwrite the new aliases
	stuffcmd(self, "alias +hook +button6\n");
	stuffcmd(self, "alias -hook -button6\n");
	hook_client_connect_real_next();
}

var void(entity targ, entity attacker, float deathtype) hook_damage_mods_set_next;
void hook_damage_mods_set(entity targ, entity attacker, float deathtype) {
	if (targ.classname == "player")
		if (targ.hook) {
			if (targ.hook.aiment)
				if (targ.hook.aiment == attacker)
					hook_remove(targ); // STOP THAT, you parasite!

			if (targ.hook.state)
			if not(attacker)
			if (deathtype == DEATH_FALL) {
				plugin_chain_damage_mod = 0;
				plugin_chain_damage_mod_force = 0;
			}
		}
	hook_damage_mods_set_next(targ, attacker, deathtype);
}

var void(float killed) hook_player_clear_next;
void(float killed) hook_player_clear {
	hook_remove(self);
	hook_player_clear_next(killed);
}

vector hook_physics_pre_origin_save;
void(entity _hook, entity pl) hook_physics_pre {
	hook_physics_pre_origin_save = pl.origin;
	pl.origin = warpzone_refsys_transform_origin(pl, _hook, pl.origin);
	physics_velocity = warpzone_refsys_transform_velocity(pl, _hook, physics_velocity);
	physics_hook_old_length = _hook.hook_length;
}

void(entity _hook, entity pl) hook_physics_post {
	physics_velocity = warpzone_refsys_transform_velocity(_hook, pl, physics_velocity);
	pl.origin = hook_physics_pre_origin_save;
	_hook.hook_length = physics_hook_old_length;
	_hook.hook.SendFlags |= 16;
}

float(entity to, float sf) hook_physics_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_PHYSICS_HOOK);
	net_write_coord(MSG_ENTITY, g_balance_grapplehook_airfriction);
	net_write_coord(MSG_ENTITY, g_balance_grapplehook_dontpull);
	net_write_coord(MSG_ENTITY, g_balance_grapplehook_force_rubber);
	net_write_coord(MSG_ENTITY, g_balance_grapplehook_force_rubber_overstretch);
	net_write_coord(MSG_ENTITY, g_balance_grapplehook_length_min);
	net_write_coord(MSG_ENTITY, g_balance_grapplehook_speed_pull);
	net_write_coord(MSG_ENTITY, g_balance_grapplehook_stretch);
	net_write_coord(MSG_ENTITY, g_grappling_hook_tarzan);
	return TRUE;
}

var void(void) hook_entity_pre_spawn_next;
void(void) hook_entity_pre_spawn {
	if (g_grappling_hook)
	if (self.classname == "weapon_hook") {
		remove(self);
		return;
	}
	hook_entity_pre_spawn_next();
}

entity hook_physics_sender;
float hook_init_done;
void(void) hook_init_common {
	if (hook_init_done)
		return;

	physics_hook_enable();
	net_link_entity((hook_physics_sender = spawn()), FALSE, 0, hook_physics_send);
	hook_init_done = TRUE;
    precache_model("models/hook.md3");
	precache_sound("weapons/hook_fire.wav");
	precache_sound("weapons/hook_impact.wav");
	hook_client_connect_real_next = plugin_chain_client_connect_real;
	plugin_chain_client_connect_real = hook_client_connect_real;
	hook_damage_mods_set_next = plugin_chain_damage_mods_set;
	plugin_chain_damage_mods_set = hook_damage_mods_set;
	hook_player_think_next = plugin_chain_player_think;
	plugin_chain_player_think = hook_player_think;
	hook_player_clear_next = plugin_chain_player_clear;
	plugin_chain_player_clear = hook_player_clear;
	hook_entity_pre_spawn_next = plugin_chain_entity_spawn_pre;
	plugin_chain_entity_spawn_pre = hook_entity_pre_spawn;
}

void(entity e, string args, float set) hook_ability_init {
	if not(e)
		hook_init_common();
}

void(float force) hook_init {
	CVAR_CACHE(g_balance_grapplehook_airfriction);
	CVAR_CACHE(g_balance_grapplehook_break_damage);
	CVAR_CACHE(g_balance_grapplehook_damage);
	CVAR_CACHE(g_balance_grapplehook_damage_interval);
	CVAR_CACHE(g_balance_grapplehook_dontpull);
	CVAR_CACHE(g_balance_grapplehook_force_rubber);
	CVAR_CACHE(g_balance_grapplehook_force_rubber_overstretch);
	CVAR_CACHE(g_balance_grapplehook_gravity);
	CVAR_CACHE(g_balance_grapplehook_health);
	CVAR_CACHE(g_balance_grapplehook_length_min);
	CVAR_CACHE(g_balance_grapplehook_speed_fly);
	CVAR_CACHE(g_balance_grapplehook_speed_pull);
	CVAR_CACHE(g_balance_grapplehook_stretch);
	CVAR_CACHE(g_balance_grapplehook_onground_pullfactor);
	CVAR_CACHE(g_balance_grapplehook_team_friendly);
	CVAR_CACHE(g_grappling_hook_tarzan);
	CVAR_CACHE(g_grappling_hook);
	CVAR_CACHE_STR(sv_announcer_extra_hooked);
	if (sv_announcer_extra_hooked != "")
		precache_sound(sv_announcer_extra_hooked);

	if not(g_grappling_hook) {
		HOOK_ABILITY = ability_register("hook", hook_ability_init);
		if not(force)
			return;
	}
	hook_init_common();
}
