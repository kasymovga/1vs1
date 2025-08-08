#define ICE_FRAME_TIME sys_ticrate
string sv_model_ice;
string sv_sound_ice_frag;
string sv_sound_ice_revive;
float g_ice_unfroze_time;
float g_ice_unfroze_interruption;
float g_ice_unfroze_multi_factor;
float g_ice_slowdown;
float g_ice_autorevive_delay;
float g_ice_autorevive_time;
float sv_model_ice_scale;
float sv_model_ice_z;
float sv_model_ice_alpha;
float sv_model_ice_use_skins;
.entity ice;

entity ice_note;

float(void) ice_note_customize {
	if not(other.ice) return FALSE;
	if (SPECTATOR_IS_SPECTATOR(other)) return FALSE;
	return TRUE;
}

void(void) ice_note_message {
	self.message = "^1Yor are frozen\n^1Use ^3{+attack}^1 to mark danger\n^1Press ^3{+attack2}^1 to spectate";
}

void(void) ice_think;

void(void) ice_remove {
	if (self.ice.weaponentity)
		progressbar_remove(self.ice.weaponentity);

	if (self.ice) {
		rm_buffs_meodp_point_detach(self);
		remove(self.ice.ice);
		remove(self.ice);
	}
	entity e, e2;
	for (e = self.ice.enemy; e;) {
		e2 = e;
		e = e.enemy;
		progressbar_remove(e2.weaponentity);
		remove(e2);
	}
	self.ice = NULL;
	marker_DetachCarrier(self);
}

float(void) ice_customize {
	if (plugin_chain_PlayerVisibleThroughWallFor(self.owner, other))
		self.effects |= EFFECT_NODEPTHTEST;
	else
		self.effects &= ~EFFECT_NODEPTHTEST;

	return TRUE;
}

float(entity to, float sf) ice_pov_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_ICE);
	sf = sf & 3;
	net_write_byte(MSG_ENTITY, sf);
	entity _ice = self.enemy;
	if (sf & 1) {
		net_write_short(MSG_ENTITY, _ice.modelindex);
		net_write_byte(MSG_ENTITY, _ice.colormod_x * 255);
		net_write_byte(MSG_ENTITY, _ice.colormod_y * 255);
		net_write_byte(MSG_ENTITY, _ice.colormod_z * 255);
		net_write_coord(MSG_ENTITY, _ice.scale);
		net_write_coord(MSG_ENTITY, _ice.origin_x);
		net_write_coord(MSG_ENTITY, _ice.origin_y);
		net_write_coord(MSG_ENTITY, _ice.origin_z);
		net_write_byte(MSG_ENTITY, _ice.skin);
	}
	if (sf & 2) {
		net_write_byte(MSG_ENTITY, _ice.alpha * 255);
	}
	return TRUE;
}

void(entity attacker, entity inflictor) ice_meodp_hit {
	ice_unfroze(self, attacker);
}

float(entity attacker, entity inflictor, float deathtype) ice_player_death_handle {
	if (plugin_ice_skip_death_handle())
		return FALSE;

	if (deathtype)
		player_obituary(attacker, inflictor, self, deathtype);

	player_clear(TRUE);
	roundbased_check_teams();
	if (self.deadflag == DEAD_FREEZE)
		return TRUE;

	self.deadflag = DEAD_FREEZE;
	self.clipgroup = 0;
	self.health = player_start_health;
	plugin_ice_frozen_status();
	if (self.ice)
		return TRUE;

	if (sv_sound_ice_frag != "")
	if (clienttype(attacker) == CLIENTTYPE_REAL)
	if (attacker != self)
	if (team_is_different_teams(attacker, self))
		sound_play2(attacker, sv_sound_ice_frag);

	rm_buffs_meodp_point_detach(self);
	rm_buffs_meodp_point_attach(self, ice_meodp_hit);
	self.ice = spawn();
	self.ice.alpha = sv_model_ice_alpha;
	self.ice.scale = sv_model_ice_scale;
	self.ice.owner = self;
	self.ice.think = ice_think;
	self.ice.nextthink = time;
	self.ice.team = self.team;
	self.ice.customizeentityforclient = ice_customize;
	self.ice.ice = spawn();
	self.ice.ice.owner = self;
	self.ice.ice.enemy = self.ice;
	self.ice.ice.customizeentityforclient = weapon_model_customize;
	net_link_entity(self.ice.ice, FALSE, 0, ice_pov_send);
	if (sv_model_ice_use_skins)
		self.ice.skin = team_index(self.team);
	else
		self.ice.colormod = team_color(self.team);

	if (g_ice_autorevive_delay > 0)
		self.ice.fade_time = time + g_ice_autorevive_delay;
	else
		self.ice.fade_time = 0;

	RM_ELSE({
		marker_AttachCarrier("Frozen!", self);
		marker_text_update(self.waypointsprite_attachedforcarrier, '0.2 1 1', '0.2 1 1', '0.2 1 1');
	}, {
		marker_AttachCarrier("helpme", self);
	});
	setattachment(self.ice, self.body, "");
	setorigin(self.ice, '0 0 1' * sv_model_ice_z);
	setmodel(self.ice, sv_model_ice);
	return TRUE;
}

void(entity frozen, entity unfrozer) ice_unfroze {
	entity snd = spawn();
	setorigin(snd, ENTITY_CENTER(frozen));
	sound(snd, CHAN_PROJECTILE, sv_sound_ice_revive, VOL_BASEVOICE, ATTN_NORM);
	snd.nextthink = time + 2;
	snd.think = stdproc_remove;
	if (clienttype(unfrozer) == CLIENTTYPE_REAL)
		print_to_spec(unfrozer, PRINT_CENTER, "^4You revive ^7{1}", frozen.netname, "", "");

	if (unfrozer.classname == "player") {
		print_all(PRINT_INFO, "^1{1}^1 was revived by {2}", frozen.netname, unfrozer.netname, "");
		if (clienttype(frozen) == CLIENTTYPE_REAL)
			print_to_spec(frozen, PRINT_CENTER, "^4You revived by ^7{1}", unfrozer.netname, "", "");
	} else {
		print_all(PRINT_INFO, "^1{1}^1 was autorevived", frozen.netname, "", "");
		print_to_spec(frozen, PRINT_CENTER, "^4You autorevived", "", "", "");
	}
	entity oldself = self;
	self = frozen.ice;
	plugin_chain_ice_unfroze(unfrozer);
	frozen.deadflag = DEAD_NO;
	player_physics_setup(frozen);
	self = frozen;
	spectator_player_stop();
	ice_remove();
	self = oldself;
	rm_buffs_meodp_point_attach(frozen, rm_buffs_meodp_death_player);
}

void(entity _ice, entity unfrozer) ice_unfrozer_add {
	entity e;
	for (e = _ice.enemy; e; e = e.enemy) {
		if (e.owner == unfrozer)
			return;

		if not(e.enemy) {
			e.enemy = spawn();
			e.enemy.owner = unfrozer;
			e.enemy.weaponentity = progressbar_create("Reviving", unfrozer);
			return;
		}
	}
	e = spawn();
	e.enemy = _ice.enemy;
	e.owner = unfrozer;
	e.weaponentity = progressbar_create("Reviving", unfrozer);
	_ice.enemy = e;
}

void(entity _ice, entity unfrozer) ice_unfrozer_remove {
	entity e, e2;
	if (_ice.enemy.owner == unfrozer) {
		progressbar_remove(_ice.enemy.weaponentity);
		e = _ice.enemy.enemy;
		remove(_ice.enemy);
		_ice.enemy = e;
	} else {
		for (e = _ice.enemy; e.enemy; e = e.enemy) {
			if (e.enemy.owner == unfrozer) {
				e2 = e.enemy;
				e.enemy = e.enemy.enemy;
				progressbar_remove(e2.weaponentity);
				remove(e2);
				break;
			}
		}
	}
}

void(void) ice_think {
	self.nextthink = time + ICE_FRAME_TIME;
	if (self.owner.deadflag != DEAD_FREEZE || self.owner.ice != self) {
		if (self.weaponentity) //for self.owner.ice != self case
			remove(self.weaponentity);

		self.weaponentity = NULL;
		entity oldself = self;
		self = self.owner;
		ice_remove();
		self = oldself;
		return;
	}
	if (plugin_ice_skip_think())
		return;

	float oldprogress = self.cnt;
	if (self.team != self.owner.team) {
		self.team = self.owner.team;
		self.colormod = team_color(self.team);
	}
	entity e, unfrozer;
	unfrozer = NULL;
	for (e = self.enemy; e; e = e.enemy) {
		if (e.owner.classname != "player" ||
				e.owner.deadflag != DEAD_NO ||
				e.owner.team != self.team ||
				vlen(e.owner.origin - self.owner.origin) > 100 ||
				player_entity(e.owner) != e.owner) {
			ice_unfrozer_remove(self, e.owner);
		}
	}
	float unfrozers_count = 0;
	PLAYER_FOR_EACH(e) {
		if (e == self.owner || e.team != self.owner.team || e.deadflag != DEAD_NO || vlen(e.origin - self.owner.origin) > 100 || player_entity(e) != e)
			continue;

		ice_unfrozer_add(self, e);
		unfrozers_count++;
	}
	if (self.enemy) {
		unfrozer = self.enemy.owner;
	} else { //no unfrozers
		if (g_ice_autorevive_delay > 0)
		if (time > self.fade_time)
			unfrozer = self;
	}
	float unfroze_scale;
	if (unfrozer.classname == "player") {
		unfroze_scale = 1 + (unfrozers_count - 1) * g_ice_unfroze_multi_factor;
	} else {
		if (g_ice_autorevive_time)
			unfroze_scale = g_ice_unfroze_time / g_ice_autorevive_time;
		else
			unfroze_scale = 0;
	}
	if (unfrozer) {
		if not(self.weaponentity) {
			self.weaponentity = progressbar_create("Reviving", self.owner);
		}
		self.cnt += ICE_FRAME_TIME * unfroze_scale;
		float p = self.cnt / g_ice_unfroze_time;
		progressbar_set(self.weaponentity, p);
		if (clienttype(self.owner) == CLIENTTYPE_BOT) {
			self.owner.movement = '0 0 0';
			bot_stay(self.owner, ICE_FRAME_TIME);
		}
		for (e = self.enemy; e; e = e.enemy) {
			progressbar_set(e.weaponentity, p);
			if (clienttype(e.owner) == CLIENTTYPE_BOT) {
				e.owner.movement = '0 0 0';
				bot_stay(e.owner, ICE_FRAME_TIME);
			}
		}
	}
	if (self.cnt >= g_ice_unfroze_time) {
		ice_unfroze(self.owner, unfrozer);
		return;
	}
	if (self.cnt == oldprogress) {
		self.cnt = max(0, self.cnt - ICE_FRAME_TIME);
		if (self.weaponentity) {
			progressbar_set(self.weaponentity, self.cnt / g_ice_unfroze_time);
			if not(self.cnt) {
				progressbar_remove(self.weaponentity);
				self.weaponentity = NULL;
			}
		}
	}
	if (self.cnt != oldprogress) {
		self.alpha = sv_model_ice_alpha * max(0.01, 1 - (self.cnt / g_ice_unfroze_time));
		self.ice.SendFlags |= 2;
	}
}

var void(float killed) ice_player_clear_next;
void ice_player_clear(float killed) {
	ice_remove();
	ice_player_clear_next(killed);
}

var void(entity spot) ice_player_spawn_next;
void(entity spot) ice_player_spawn {
	ice_player_spawn_next(spot);
	ice_player_death_handle(NULL, NULL, 0);
}

var float() ice_physics_max_speed_mod_next;
float() ice_physics_max_speed_mod {
	float f = ice_physics_max_speed_mod_next();
	if (self.deadflag == DEAD_FREEZE)
		return g_ice_slowdown * f;

	return f;
}

var float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) ice_player_damage_handle_next;
float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) ice_player_damage_handle {
	if not(self.deadflag == DEAD_FREEZE)
		return ice_player_damage_handle_next(inflictor, attacker, _damage, deathtype, hitloc, force);

	RM({
		if (DEATH_NADGETTYPE(deathtype) == NADGET_PLASMA) {
			if (self.deadflag == DEAD_FREEZE || (inflictor.hg_adept && g_nadgets_plasma_adept_stun)) {
				if (self != attacker && (!team_mode || team_is_different_teams(self, attacker))) {
					self.hg_plasmalock = time + g_nadgets_plasma_projectile_frozenlock * rm_buffs_nadget_power(attacker);
					self.hg_plasmalock_owner = attacker;
					//te_csqc_lightningarc(inflictor.origin, hitloc, TRUE, attacker.team);
					effect_lightningarc(inflictor.origin, hitloc/*, TRUE, attacker.team*/); //FIXME
				}
			}
		}
	})
	if (attacker)
	if (attacker.team != self.team)
	if (g_ice_unfroze_interruption || (self.ice.fade_time && time > self.ice.fade_time)) {
		if (g_ice_autorevive_delay > 0)
			self.ice.fade_time = time + g_ice_autorevive_delay;

		self.ice.alpha = sv_model_ice_alpha;
		self.ice.cnt = 0;
	}
	if (deathtype == DEATH_SLIME ||
			deathtype == DEATH_LAVA ||
			deathtype == DEATH_HURTTRIGGER) {
		entity spot = player_spawn_spot();
		pointparticles(particleeffectnum("teleport"), ENTITY_CENTER(self), '0 0 0', 1);
		client_put_to_spot(spot);
		self.velocity = '0 0 0';
		if (physics_current_player == self) physics_velocity = '0 0 0';
		sound(self, CHAN_TRIGGER, "misc/spawn.wav", VOL_BASE, ATTN_NORM);
		pointparticles(particleeffectnum("teleport"), ENTITY_CENTER(self), '0 0 0', 1);
	} else if (deathtype == DEATH_TEAMCHANGE) {
		client_put();
	}
	return TRUE;
}

var void(void) ice_player_think_next;
void(void) ice_player_think {
	if (self.deadflag == DEAD_FREEZE && !SPECTATOR_IS_SPECTATOR(self)) {
		if (self.BUTTON_ATCK)
			self.impulse = 38;

		if (self.BUTTON_ATCK2)
			spectator_player_start(); //force spectating
	}
	ice_player_think_next();
}

void(void) ice_init {
	CVAR_CACHE_STR(sv_model_ice); //strzone once and never strunzone
	if (sv_model_ice == "models/ice/ice.md3")
		dlc_require("ice");

	precache_model(sv_model_ice);
	CVAR_CACHE_STR(sv_sound_ice_frag);
	CVAR_CACHE_STR(sv_sound_ice_revive);
	if (sv_sound_ice_frag != "")
		precache_sound(sv_sound_ice_frag);

	if (sv_sound_ice_revive != "")
		precache_sound(sv_sound_ice_revive);

	CVAR_CACHE(g_ice_unfroze_time);
	CVAR_CACHE(g_ice_unfroze_interruption);
	CVAR_CACHE(g_ice_slowdown);
	CVAR_CACHE(g_ice_autorevive_delay);
	CVAR_CACHE(g_ice_autorevive_time);
	if (g_ice_unfroze_time <= 0)
		g_ice_unfroze_time = 1;

	if (g_ice_autorevive_time <= 0)
		g_ice_autorevive_time = 1;

	CVAR_CACHE(sv_model_ice_alpha);
	CVAR_CACHE(sv_model_ice_scale);
	CVAR_CACHE(sv_model_ice_z);
	CVAR_CACHE(sv_model_ice_use_skins);
	plugin_player_death_handle = ice_player_death_handle;
	ice_player_clear_next = plugin_chain_player_clear;
	plugin_chain_player_clear = ice_player_clear;
	ice_physics_max_speed_mod_next = plugin_chain_physics_max_speed_mod;
	plugin_chain_physics_max_speed_mod = ice_physics_max_speed_mod;
	ice_player_spawn_next = plugin_chain_player_spawn;
	plugin_chain_player_spawn = ice_player_spawn;
	ice_player_damage_handle_next = plugin_chain_player_damage_handle;
	plugin_chain_player_damage_handle = ice_player_damage_handle;
	ice_player_think_next = plugin_chain_player_think;
	plugin_chain_player_think = ice_player_think;
	ice_note = noteline_new(ice_note_message);
	ice_note.customizeentityforclient = ice_note_customize;
}
