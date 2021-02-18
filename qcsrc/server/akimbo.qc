.float akimbo_weapons;
.entity akimbo_ghost;
float g_akimbo_weapons;
float g_akimbo_throwable;
float weapons_with_akimbo_support;
void Akimbo_Clear(entity e);

void Akimbo_GhostHide(entity e) {
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

void Akimbo_GhostRemove(entity e)
{
	if (e.akimbo_ghost.weaponentity)
		Akimbo_GhostHide(e);

	remove(e.akimbo_ghost);
	e.akimbo_ghost = world;
}

void Akimbo_WeaponFrame()
{
	float akimbo_weapon;
	if (self.akimbo_ghost) {
		if (self.akimbo_ghost.switchweapon != self.switchweapon)
			self.akimbo_ghost.switchweapon = self.switchweapon;

		if (self.akimbo_ghost.weaponentity)
			akimbo_weapon = self.akimbo_ghost.weapon;
		else
			akimbo_weapon = self.weapon;
	} else
		akimbo_weapon = self.weapon;

	if (akimbo_weapon && Akimbo_HaveWeapon(self, akimbo_weapon))
	{
		entity oldself = self;
		self = self.akimbo_ghost;
		if not(self.weaponentity) {
			if not(self)
				oldself.akimbo_ghost = self = spawn();

			self.weapon = akimbo_weapon;
			self.switchweapon = akimbo_weapon;
			self.modelindex = oldself.modelindex;
			self.weapons = oldself.weapons;
			self.owner = oldself;
			self.cvar_cl_gunalpha = oldself.cvar_cl_gunalpha;
			weapon_model_spawn();
			self.weaponentity.state = WS_RAISE;
			weapon_action(self.weapon, WR_SETUP);
			weapon_thinkf(WFRAME_IDLE, g_balance_weaponswitchdelay, weapon_ready);
			self = self.weaponentity;
			self.think();
			self = oldself.akimbo_ghost;
			oldself.weaponentity.cnt = 0;
		}
		self.ammo_shells = oldself.ammo_shells;
		self.ammo_cells = oldself.ammo_cells;
		self.ammo_nails = oldself.ammo_nails;
		self.ammo_rockets = oldself.ammo_rockets;
		self.weapons = oldself.weapons;
		self.BUTTON_ATCK = oldself.BUTTON_ATCK;
		self.BUTTON_ATCK2 = oldself.BUTTON_ATCK2;
		self.deadflag = oldself.deadflag;
		self.colormap = oldself.colormap;
		self.effects = oldself.effects;
		self.alpha = oldself.alpha;
		self.health = oldself.health;
		self.v_angle = oldself.v_angle;
		self.angles = oldself.angles;
		self.origin = oldself.origin;
		self.cnt = oldself.cnt;
		self.items = oldself.items;
		weapon_frame();
		oldself.ammo_shells = self.ammo_shells;
		oldself.ammo_cells = self.ammo_cells;
		oldself.ammo_nails = self.ammo_nails;
		oldself.ammo_rockets = self.ammo_rockets;
		self = oldself;
	}
	else
	{
		if (self.akimbo_ghost.weaponentity)
			Akimbo_GhostHide(self);
	}
}

var void(float killed) Akimbo_PlayerClear_NextLink;
void Akimbo_PlayerClear(float killed) {
	//if not(killed)
	Akimbo_Clear(self);

	Akimbo_PlayerClear_NextLink(killed);
}

float Akimbo_Throw(float wbit) {
	if (g_akimbo_weapons)
	if (self.akimbo_weapons & wbit) {
		self.akimbo_weapons &~= wbit;
		return TRUE;
	}
	return FALSE;
}

void Akimbo_Init()
{
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
	Akimbo_PlayerClear_NextLink = gamehook_chain_player_clear;
	gamehook_chain_player_clear = Akimbo_PlayerClear;
}

entity Akimbo_Owner(entity e)
{
	if (e.owner)
	if (e.owner.akimbo_ghost == e)
		return e.owner;

	return e;
}

entity Akimbo_Ghost(entity e)
{
	if (e.owner)
	if (e.owner.akimbo_ghost == e)
		return e;

	return e.akimbo_ghost;
}

float Akimbo_GiveWeapon(entity p, float wpn, string name)
{
	float wpnbit = weapon_bit(wpn);
	if (wpnbit & p.akimbo_weapons)
		return FALSE;

	if (g_akimbo_weapons & wpnbit)
	{
		p.akimbo_weapons |= wpnbit;
		sprint(p, "You got ^4Akimbo ^2");
		sprint(p, name);
		sprint(p, "\n");
		return TRUE;
	}
	return FALSE;
}

float Akimbo_DropWeapon(entity p, float wpn, string name)
{
	float wpnbit = weapon_bit(wpn);
	if not(g_akimbo_weapons & wpnbit)
		return FALSE;

	if not(wpnbit & p.akimbo_weapons)
		return FALSE;

	p.akimbo_weapons &~= wpnbit;
	sprint(p, "You drop ^4Akimbo ^2");
	sprint(p, name);
	sprint(p, "\n");
	return TRUE;
}

float Akimbo_Active(entity e)
{
	if (e.akimbo_ghost.weaponentity)
		return 1;
	if (Akimbo_Owner(e) != e)
		return 2;

	return 0;
}

void Akimbo_Clear(entity e)
{
	if (e.akimbo_ghost)
		Akimbo_GhostRemove(e);

	e.akimbo_weapons = 0;
}

float Akimbo_HaveWeapon(entity e, float wpn)
{
	float wpnbit = weapon_bit(wpn);
#if 0
	if (cvar("g_akimbo_force") && (wpn & weapons_with_akimbo_support))
		return TRUE;
#endif

	if ((e.akimbo_weapons & wpnbit) ||
			(g_powerup_strength_akimbo && e.strength_finished > time &&
			(wpnbit & weapons_with_akimbo_support)))
		return TRUE;
	return FALSE;
}
