#define ICE_FRAME_TIME 0.2
string sv_model_ice;
string sv_sound_ice_frag;
float g_ice_unfroze_time;
float g_ice_unfroze_interruption;
float g_ice_slowdown;
float g_ice_autorevive_delay;
float g_ice_autorevive_time;
float sv_model_ice_scale;
float sv_model_ice_z;
float sv_model_ice_alpha;
float sv_model_ice_use_skins;
.entity ice;
.entity last_unfrozer;
.float unfroze_progress;
.entity unfroze_pb;

void(void) ice_think;

void(void) ice_remove {
	if (self.ice) {
		remove(self.ice.ice);
		remove(self.ice);
	}
	if (self.unfroze_pb)
		progressbar_remove(self.unfroze_pb);

	if (self.ice.unfroze_pb)
		progressbar_remove(self.ice.unfroze_pb);

	self.unfroze_pb = world;
	self.ice = world;
	WaypointSprite_DetachCarrier(self);
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

float(entity attacker, entity inflictor, float deathtype) ice_player_death_handle {
	if (ice_hook_skip_death_handle)
	if (ice_hook_skip_death_handle())
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
	if (ice_hook_frozen_status)
		ice_hook_frozen_status();

	if (self.ice)
		return TRUE;

	if (sv_sound_ice_frag != "")
	if (clienttype(attacker) == CLIENTTYPE_REAL)
	if (attacker != self)
	if (team_is_different_teams(attacker, self))
		sound_play2(attacker, sv_sound_ice_frag);

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

	WaypointSprite_AttachCarrier("helpme", self);
	setattachment(self.ice, self.body, "");
	setorigin(self.ice, '0 0 1' * sv_model_ice_z);
	setmodel(self.ice, sv_model_ice);
	return TRUE;
}

void(void) ice_think {
	self.nextthink = time + ICE_FRAME_TIME;
	if (self.owner.deadflag != DEAD_FREEZE || self.owner.ice != self) {
		if (self.unfroze_pb) //for self.owner.ice != self case
			remove(self.unfroze_pb);

		self.unfroze_pb = world;
		entity oldself = self;
		self = self.owner;
		ice_remove();
		self = oldself;
		return;
	}
	if (ice_hook_skip_think)
	if (ice_hook_skip_think())
		return;

	float oldprogress = self.unfroze_progress;
	if (self.team != self.owner.team) {
		self.team = self.owner.team;
		self.colormod = team_color(self.team);
	}
	entity e, unfrozer;
	unfrozer = world;
	if (self.last_unfrozer && self.last_unfrozer.deadflag == DEAD_NO && vlen(self.last_unfrozer.origin - self.owner.origin) <= 100 && player_entity(self.last_unfrozer) == self.last_unfrozer) {
		unfrozer = self.last_unfrozer;
	} else FOR_EACH_PLAYER(e) {
		if (e == self.owner || e.team != self.owner.team || e.deadflag != DEAD_NO || vlen(e.origin - self.owner.origin) > 100 || player_entity(e) != e)
			continue;

		unfrozer = e;
		break;
	}
	if not(unfrozer)
	if (g_ice_autorevive_delay > 0)
	if (time > self.fade_time)
		unfrozer = self;

	if (unfrozer != self.last_unfrozer) {
		if (self.unfroze_pb)
			remove(self.unfroze_pb);

		if (unfrozer) {
			self.unfroze_pb = progressbar_create("Reviving", unfrozer);
			if not(self.owner.unfroze_pb)
				self.owner.unfroze_pb = progressbar_create("Reviving", self.owner);
		} else {
			if (self.owner.unfroze_pb)
				progressbar_remove(self.owner.unfroze_pb);

			self.owner.unfroze_pb = world;
			self.unfroze_pb = world;
		}
	}
	float unfroze_scale;
	if (unfrozer.classname == "player") {
		self.last_unfrozer = unfrozer;
		unfroze_scale = 1;
	} else {
		self.last_unfrozer = world;
		unfroze_scale = g_ice_unfroze_time / g_ice_autorevive_time;
	}
	if (unfrozer) {
		self.unfroze_progress += ICE_FRAME_TIME * unfroze_scale;
		if (clienttype(unfrozer) == CLIENTTYPE_REAL) {
			if (self.unfroze_pb)
				progressbar_set(self.unfroze_pb, self.unfroze_progress / g_ice_unfroze_time);
		} else
			bot_stay(unfrozer, ICE_FRAME_TIME);

		if (clienttype(self.owner) == CLIENTTYPE_REAL) {
			if (self.owner.unfroze_pb)
				progressbar_set(self.owner.unfroze_pb, self.unfroze_progress / g_ice_unfroze_time);
		} else {
			self.owner.movement = '0 0 0';
			bot_stay(self.owner, ICE_FRAME_TIME);
		}
	}
	if (self.unfroze_progress >= g_ice_unfroze_time) {
		if (clienttype(unfrozer) == CLIENTTYPE_REAL)
			centerprint(unfrozer, strcat("^4You revive ^7", self.owner.netname, "\n"));

		if (unfrozer.classname == "player") {
			bprint ("^1", self.owner.netname, "^1 was revived by ", unfrozer.netname, "\n");
			if (clienttype(self.owner) == CLIENTTYPE_REAL)
				centerprint(self.owner, strcat("^4You revived by ^7", unfrozer.netname, "\n"));
		} else {
			bprint ("^1", self.owner.netname, "^1 was autorevived\n");
			centerprint(self.owner, "^4You autorevived\n");
		}
		ice_hook_unfroze(unfrozer);
		self.owner.deadflag = DEAD_NO;
		player_physics_setup(self.owner);
		return;
	}
	if (self.unfroze_progress == oldprogress)
	if (oldprogress != 0)
		self.unfroze_progress = max(0, oldprogress - ICE_FRAME_TIME);

	if (self.unfroze_progress != oldprogress) {
		self.alpha = sv_model_ice_alpha * max(0.01, 1 - (self.unfroze_progress / g_ice_unfroze_time));
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
	ice_player_death_handle(world, world, 0);
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

	if (attacker)
	if (attacker.team != self.team)
	if (g_ice_unfroze_interruption || (self.ice.fade_time && time > self.ice.fade_time)) {
		if (g_ice_autorevive_delay > 0)
			self.ice.fade_time = time + g_ice_autorevive_delay;

		self.ice.alpha = sv_model_ice_alpha;
		self.ice.unfroze_progress = 0;
	}
	if (deathtype == DEATH_SLIME ||
			deathtype == DEATH_LAVA ||
			deathtype == DEATH_HURTTRIGGER ||
			deathtype == DEATH_TEAMCHANGE
			)
		client_put();

	self.unfroze_progress = 0;
	return TRUE;
}

var void(entity spectatee) ice_spectator_copy_next;
void ice_spectator_copy(entity spectatee) {
	self.deadflag = spectatee.deadflag;
	ice_spectator_copy_next(spectatee);
}

var void(void) ice_player_think_next;
void(void) ice_player_think {
	if (self.deadflag == DEAD_FREEZE)
	if (self.BUTTON_ATCK)
		self.impulse = 38;

	ice_player_think_next();
}

void(void) ice_init {
	CVAR_CACHE_STR(sv_model_ice); //strzone once and never strunzone
	if (sv_model_ice == "models/ice/ice.md3")
		dlc_require("ice");

	precache_model(sv_model_ice);
	CVAR_CACHE_STR(sv_sound_ice_frag);
	if (sv_sound_ice_frag != "")
		precache_sound(sv_sound_ice_frag);

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
	ice_spectator_copy_next = plugin_chain_spectator_copy;
	plugin_chain_spectator_copy = ice_spectator_copy;
	ice_player_think_next = plugin_chain_player_think;
	plugin_chain_player_think = ice_player_think;
}
