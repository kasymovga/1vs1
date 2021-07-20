.float akimbo_weapons;
.entity akimbo_ghost;
float g_akimbo_weapons;
float g_akimbo_throwable;
float g_akimbo_weaponratefactor;
float weapons_with_akimbo_support;
void(entity e) akimbo_clear;
entity(entity e, float deep) akimbo_ghost_get;

void(entity e) akimbo_ghost_hide {
	entity oldself = self;
	self = e.akimbo_ghost;
	weapon_action(self.weapon, WR_CLEAR);
	if (self.weaponentity.weaponentity)
		remove(self.weaponentity.weaponentity);

	remove(self.weaponentity);
	remove(self.exteriorweaponentity);
	self.weaponentity = world;
	self.exteriorweaponentity = world;
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

void(void) akimbo_weapon_frame {
	float akimbo_weapon;
	float i, j;
	entity _akimbo_ghost;
	entity pl = self;
	entity prevself;
	for (i = 2; i < 4; i++) {
		_akimbo_ghost = akimbo_ghost_get(pl, i);
		if (_akimbo_ghost) {
			if (_akimbo_ghost.switchweapon != pl.switchweapon)
				_akimbo_ghost.switchweapon = pl.switchweapon;

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
				prevself.akimbo_ghost = self = spawn();
				self.clipgroup = pl.clipgroup;
				for (j = WEP_FIRST; j <= WEP_LAST; ++j)
					weapon_action(j, WR_RESETPLAYER);
			}
			self.ammo_shells = pl.ammo_shells;
			self.ammo_cells = pl.ammo_cells;
			self.ammo_nails = pl.ammo_nails;
			self.ammo_rockets = pl.ammo_rockets;
			self.weapons = pl.weapons;
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
				self.weapons = pl.weapons;
				self.owner = pl;
				self.cvar_cl_gunalpha = pl.cvar_cl_gunalpha;
				weapon_model_spawn();
				self.weaponentity.state = WS_RAISE;
				weapon_action(self.weapon, WR_SETUP);
				weapon_thinkf(WFRAME_IDLE, g_balance_weaponswitchdelay, weapon_ready);
				self = self.weaponentity;
				self.think();
				self = prevself.akimbo_ghost;
				prevself.weaponentity.cnt = 0;
			}
			weapon_frame();
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

float(float wbit) akimbo_weapon_throw {
	if (g_akimbo_weapons)
	if (self.akimbo_weapons & wbit) {
		self.akimbo_weapons &= ~wbit;
		return TRUE;
	}
	return FALSE;
}

var float() akimbo_weapon_rate_factor_next;
float() akimbo_weapon_rate_factor {
	float f = 1;
	if (self.akimbo_ghost)
	if (self.akimbo_ghost.weaponentity)
		f = g_akimbo_weaponratefactor;

	return f * akimbo_weapon_rate_factor_next();
}

void(void) akimbo_init {
	float i, j, n;
	string s = cvar_string("g_akimbo_weapons");
	weapons_with_akimbo_support =
			WEPBIT_LASER |
			WEPBIT_SHOTGUN |
			WEPBIT_UZI |
			WEPBIT_CAMPINGRIFLE |
			WEPBIT_GRENADE_LAUNCHER |
			WEPBIT_ELECTRO |
			WEPBIT_CRYLINK |
			WEPBIT_HLAC |
			WEPBIT_NEX |
			WEPBIT_HAGAR |
			WEPBIT_SUPERSHOTGUN |
			WEPBIT_ZAPPER |
			WEPBIT_ROCKET_LAUNCHER;

	if (s == "all")
		g_akimbo_weapons = weapons_with_akimbo_support;
	else {
		n = tokenize_console(s);
		for (i = 0; i < n; i++)
			for (j = WEP_FIRST; j <= WEP_LAST; j++)
				if (argv(i) == weapon_info(j).netname)
				{
					g_akimbo_weapons |= weapon_bit(j);
					break;
				}
	}
	g_akimbo_weapons = g_akimbo_weapons & weapons_with_akimbo_support;
	if not(g_akimbo_weapons)
	if not(g_powerup_strength_akimbo)
		return;

	CVAR_CACHE(g_akimbo_animation_shift);
	CVAR_CACHE(g_akimbo_throwable);
	CVAR_CACHE(g_akimbo_weaponratefactor);
	akimbo_player_clear_next = gamehook_chain_player_clear;
	gamehook_chain_player_clear = akimbo_player_clear;
	akimbo_weapon_rate_factor_next = gamehook_chain_weapon_rate_factor;
	gamehook_chain_weapon_rate_factor = akimbo_weapon_rate_factor;
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
	float wpnbit = weapon_bit(wpn);
	if (wpnbit & p.akimbo_weapons)
		return FALSE;

	if (g_akimbo_weapons & wpnbit) {
		p.akimbo_weapons |= wpnbit;
		sprint(p, "You got ^4Akimbo ^2");
		sprint(p, name);
		sprint(p, "\n");
		return TRUE;
	}
	return FALSE;
}

float(entity p, float wpn, string name) akimbo_weapon_drop {
	float wpnbit = weapon_bit(wpn);
	if not(g_akimbo_weapons & wpnbit)
		return FALSE;

	if not(wpnbit & p.akimbo_weapons)
		return FALSE;

	p.akimbo_weapons &= ~wpnbit;
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
	for ( ; e2; e2 = e2.akimbo_ghost) {
		if (e2 == e)
			return n;

		n++;
	}
	return 1;
}

void(entity e) akimbo_clear {
	if (e.akimbo_ghost)
		akimbo_ghost_remove(e);

	e.akimbo_weapons = 0;
}

float(entity e, float wpn, float deep) akimbo_weapon_have {
	float wpnbit = weapon_bit(wpn);
	if not(wpnbit & weapons_with_akimbo_support)
		return FALSE;

	if (e.akimbo_weapons & wpnbit) {
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
