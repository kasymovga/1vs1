.entity akimbo_ghost;
float g_akimbo_weapons;
float g_akimbo_weapons_extra;
float g_akimbo_throwable;
float g_akimbo_weaponratefactor;
float g_akimbo_weaponratefactor_for;
float g_akimbo_weaponratefactor_for_extra;
float akimbo_supported_weapons;
void(entity e) akimbo_clear;
entity(entity e, float deep) akimbo_ghost_get;

void(entity e) akimbo_ghost_hide {
	entity oldself = self;
	self = e.akimbo_ghost;
	weapon_action(self.weapon, WEAPON_REQUEST_CLEAR);
	if (self.weaponentity)
		weapon_model_remove(self.weaponentity);

	if (self.exteriorweaponentity)
		remove(self.exteriorweaponentity);

	self.weaponentity = NULL;
	self.exteriorweaponentity = NULL;
	self = oldself;
	if (self.weaponentity)
		self.weaponentity.cnt = 0;
}

void(entity e) akimbo_ghost_remove {
	if (e.akimbo_ghost.akimbo_ghost)
		akimbo_ghost_remove(e.akimbo_ghost);

	if (e.akimbo_ghost.weaponentity)
		akimbo_ghost_hide(e);

	remove(e.akimbo_ghost);
	e.akimbo_ghost = world;
}

entity(entity p) akimbo_ghost_spawn {
	p.akimbo_ghost = spawn();
	p.akimbo_ghost.clipgroup = p.clipgroup;
	entity oldself = self;
	self = p.akimbo_ghost;
	float j;
	WEAPON_INFO_FOR_EACH_ID(j)
		weapon_action(j, WEAPON_REQUEST_RESETPLAYER);

	self = oldself;
	return p.akimbo_ghost;
}

void(void) akimbo_weapon_frame {
	float akimbo_weapon;
	float i, j, _weapons, _weapons_extra;
	entity _akimbo_ghost;
	entity pl = self;
	entity prevself;
	for (i = 2; i < 4; i++) {
		_akimbo_ghost = akimbo_ghost_get(pl, i);
		if (_akimbo_ghost) {
			if (_akimbo_ghost.switchweapon != pl.switchweapon) {
				if (akimbo_weapon_have(pl, _akimbo_ghost.switchweapon, i))
					_akimbo_ghost.switchweapon = pl.switchweapon;
				else
					_akimbo_ghost.switchweapon = 0;
			}
			if (_akimbo_ghost.weaponentity)
				akimbo_weapon = _akimbo_ghost.weapon;
			else
				akimbo_weapon = pl.weapon;
		} else
			akimbo_weapon = pl.weapon;

		prevself = self;
		if (akimbo_weapon && akimbo_weapon_have(pl, akimbo_weapon, i)) {
			self = _akimbo_ghost;
			if not(self) {
				self = akimbo_ghost_spawn(prevself);
			}
			self.ammo_shells = pl.ammo_shells;
			self.ammo_cells = pl.ammo_cells;
			self.ammo_nails = pl.ammo_nails;
			self.ammo_rockets = pl.ammo_rockets;
			self.BUTTON_ATCK = pl.BUTTON_ATCK;
			self.BUTTON_ATCK2 = pl.BUTTON_ATCK2;
			self.deadflag = pl.deadflag;
			self.colormap = pl.colormap;
			self.effects = pl.effects;
			self.alpha = pl.alpha;
			self.health = pl.health;
			self.v_angle = pl.v_angle;
			self.angles = pl.angles;
			self.origin = pl.origin;
			self.cnt = pl.cnt;
			self.items = pl.items;
			if not(self.weaponentity) {
				self.weapon = akimbo_weapon;
				self.switchweapon = akimbo_weapon;
				self.modelindex = pl.modelindex;
				self.owner = pl;
				self.cvar_cl_gunalpha = pl.cvar_cl_gunalpha;
				weapon_model_spawn();
				self.weaponentity.state = WEAPON_STATE_RAISE;
				weapon_setup(self.weapon);
				self = self.weaponentity;
				self.think();
				self = prevself.akimbo_ghost;
				weapon_thinkf(WEAPON_FRAME_IDLE, g_balance_weaponswitchdelay, weapon_ready);
				prevself.weaponentity.cnt = 0;
			}
			_weapons = self.weapons;
			_weapons_extra = self.weapons_extra;
			self.weapons = pl.weapons;
			self.weapons_extra = pl.weapons_extra;
			weapon_frame();
			self.weapons = _weapons;
			self.weapons_extra = _weapons_extra;
			pl.ammo_shells = self.ammo_shells;
			pl.ammo_cells = self.ammo_cells;
			pl.ammo_nails = self.ammo_nails;
			pl.ammo_rockets = self.ammo_rockets;
		} else {
			if (_akimbo_ghost.weaponentity)
				akimbo_ghost_hide(prevself);
		}
	}
	self = pl;
}

var void(float killed) akimbo_player_clear_next;
void(float killed) akimbo_player_clear {
	akimbo_clear(self);
	akimbo_player_clear_next(killed);
}

float(float w) akimbo_weapon_throw {
	entity wi = weapon_info(w);
	entity ag = akimbo_ghost_get(self, 0);
	if (g_akimbo_weapons)
		if (ag.weapons & wi.weapons) {
			ag.weapons &= ~wi.weapons;
			return TRUE;
		}
	if (g_akimbo_weapons_extra)
		if (ag.weapons_extra & wi.weapons_extra) {
			ag.weapons_extra &= ~wi.weapons_extra;
			return TRUE;
		}
	return FALSE;
}

var float() akimbo_weapon_rate_factor_next;
float() akimbo_weapon_rate_factor {
	float f = 1;
	if (self.akimbo_ghost)
	if (self.akimbo_ghost.weaponentity)
	if (self.weaponentity.state != WEAPON_STATE_DROP)
	if (self.weaponentity.state != WEAPON_STATE_RAISE) {
		entity wi = weapon_info(self.weapon);
		if ((wi.weapons & g_akimbo_weaponratefactor_for) || (wi.weapons & g_akimbo_weaponratefactor_for_extra))
			f = g_akimbo_weaponratefactor;
	}
	return f * akimbo_weapon_rate_factor_next();
}

float akimbo_init_done;
void(void) akimbo_init_common {
	float i, j;
	string s = cvar_string("g_akimbo_weaponratefactor_for");
	if (s == "all") {
		g_akimbo_weaponratefactor_for = akimbo_supported_weapons;
		g_akimbo_weaponratefactor_for_extra = -1;
	} else {
		entity e;
		float n = tokenize_console(s);
		for (i = 0; i < n; i++)
			WEAPON_INFO_FOR_EACH(e)
				if (argv(i) == e.netname) {
					g_akimbo_weaponratefactor_for |= e.weapons;
					g_akimbo_weaponratefactor_for_extra |= e.weapons_extra;
					break;
				}
	}
	if (akimbo_init_done)
		return;

	akimbo_init_done = TRUE;
	CVAR_CACHE(g_akimbo_throwable);
	CVAR_CACHE(g_akimbo_weaponratefactor);
	akimbo_player_clear_next = plugin_chain_player_clear;
	plugin_chain_player_clear = akimbo_player_clear;
	akimbo_weapon_rate_factor_next = plugin_chain_weapon_rate_factor;
	plugin_chain_weapon_rate_factor = akimbo_weapon_rate_factor;
}

void(entity e, string args, float set) akimbo_ability_init {
	if (e) {
		entity ag = akimbo_ghost_get(e, 0);
		if not(ag) ag = akimbo_ghost_spawn(e);
		if (ag)
			ag.weapons = 0;

		if (set) {
			string wn;
			entity we;
			while ((wn = str_car(args)) != "") {
				args = str_cdr(args);
				we = weapon_info_by_name(wn);
				if (we.weapons & akimbo_supported_weapons)
					ag.weapons |= we.weapons;

				ag.weapons_extra |= we.weapons_extra;
			}
		}
	} else
		akimbo_init_common();
}

void(void) akimbo_init {
	float i, j, n;
	ability_register("akimbo", akimbo_ability_init);
	string s = cvar_string("g_akimbo_weapons");
	entity e;
	akimbo_supported_weapons = 0;
	WEAPON_INFO_FOR_EACH(e) {
		if (e.weapon == WEP_TUBA || e.weapon == WEP_FIREBALL || e.weapon == WEP_MELEE || e.weapon == WEP_HOOK || e.weapon == WEP_PORTO || e.weapon == WEP_MINSTANEX)
			continue;

		akimbo_supported_weapons |= e.weapons;
	}
	if (s == "all") {
		WEAPON_INFO_FOR_EACH(e) {
			g_akimbo_weapons |= (akimbo_supported_weapons & e.weapons);
			g_akimbo_weapons_extra |= e.weapons_extra;
		}
	} else {
		n = tokenize_console(s);
		for (i = 0; i < n; i++)
			WEAPON_INFO_FOR_EACH(e)
				if (argv(i) == e.netname) {
					g_akimbo_weapons |= e.weapons;
					g_akimbo_weapons_extra |= e.weapons_extra;
					break;
				}
	}
	g_akimbo_weapons = g_akimbo_weapons & akimbo_supported_weapons;
	if not(g_akimbo_weapons)
	if not(g_powerup_strength_akimbo)
		return;

	akimbo_init_common();
}

entity(entity e) akimbo_owner {
	if (e.owner) {
		entity e2 = e.owner.akimbo_ghost;
		for ( ; e2; e2 = e2.akimbo_ghost)
			if (e2 == e)
				return e.owner;
	}
	return e;
}

entity(entity e, float deep) akimbo_ghost_get {
	float i;
	entity e2;
	if (e.owner)
		e2 = e.owner.akimbo_ghost;
	else
		e2 = e.akimbo_ghost;

	if (e2)
	for (i = 2; i < deep; i++) {
		e2 = e2.akimbo_ghost;
	}
	return e2;
}

float(entity p, float wpn, string name) akimbo_weapon_give {
	entity wi = weapon_info(wpn);
	entity ag = akimbo_ghost_get(p, 0);
	if not(ag) ag = akimbo_ghost_spawn(p);
	if ((wi.weapons & ag.weapons) || (wi.weapons_extra & ag.weapons_extra))
		return FALSE;

	if ((g_akimbo_weapons & wi.weapons) || (g_akimbo_weapons_extra & wi.weapons_extra)) {
		ag.weapons |= wi.weapons;
		ag.weapons_extra |= wi.weapons_extra;
		sprint(p, "You got ^4Akimbo ^2");
		sprint(p, name);
		sprint(p, "\n");
		return TRUE;
	}
	return FALSE;
}

float(entity p, float wpn, string name) akimbo_weapon_drop {
	entity wi = weapon_info(wpn);
	entity ag = akimbo_ghost_get(p, 0);
	if (!(g_akimbo_weapons & wi.weapons & ag.weapons) && !(g_akimbo_weapons_extra & wi.weapons_extra & ag.weapons_extra))
		return FALSE;

	ag.weapons &= ~wi.weapons;
	ag.weapons_extra &= ~wi.weapons_extra;
	sprint(p, "You drop ^4Akimbo ^2");
	sprint(p, name);
	sprint(p, "\n");
	return TRUE;
}

float(entity e) akimbo_active {
	entity e2 = (e.owner ? e.owner.akimbo_ghost : e.akimbo_ghost);
	if not(e2)
		return 0;

	float n = 2;
	entity e3 = e2;
	for ( ; e3; e3 = e3.akimbo_ghost) {
		if (e3 == e)
			return n;

		n++;
	}
	if not(e2.weaponentity)
		return 0;

	return 1;
}

void(entity e) akimbo_clear {
	if (e.akimbo_ghost)
		akimbo_ghost_remove(e);
}

float(entity e, float wpn, float deep) akimbo_weapon_have {
	entity wi = weapon_info(wpn);
	if (!(wi.weapons & akimbo_supported_weapons) && !wi.weapons_extra)
		return FALSE;

	entity ag = akimbo_ghost_get(e, 0);
	if ((ag.weapons & wi.weapons) || (ag.weapons_extra & wi.weapons_extra)) {
			if (g_powerup_strength_akimbo && e.strength_finished > time)
				return deep <= 3;

		return deep == 2;
	} else if (g_powerup_strength_akimbo && e.strength_finished > time) {
		return deep == 2;
	}
	return FALSE;
}

void(entity e) akimbo_reload {
	entity oldself = self;
	self = e.akimbo_ghost;
	if (self) {
		weapon_reload();
	}
	self = oldself;
}
