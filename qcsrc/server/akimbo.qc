.float akimbo_weapons;
.entity akimbo_ghost;
float g_akimbo_weapons;
float weapons_with_akimbo_support;

void Akimbo_GhostRemove(entity e)
{
	entity oldself = self;
	self = self.akimbo_ghost;
	weapon_action(self.weapon, WR_CLEAR);
	self = oldself;
	if (self.akimbo_ghost.weaponentity.weaponentity)
		remove(self.akimbo_ghost.weaponentity.weaponentity);
	remove(self.akimbo_ghost.weaponentity);
	remove(self.akimbo_ghost.exteriorweaponentity);
	remove(self.akimbo_ghost);
	self.akimbo_ghost = world;
	if (self.weaponentity)
		self.weaponentity.cnt = 0;
}

void Akimbo_WeaponFrame()
{
	if (self.akimbo_ghost && self.akimbo_ghost.weapon != self.weapon)
		Akimbo_GhostRemove(self);
	if (g_nexball)
	if (self.ballcarried)
	{
		return;
		Akimbo_GhostRemove(self);
	}
	if not(self.weapon)
		return;
	if (Akimbo_HaveWeapon(self, self.weapon))
	{
		entity oldself = self;
		if not(self.akimbo_ghost)
		{
			self.akimbo_ghost = spawn();
			self.akimbo_ghost.weapon = self.weapon;
			self.akimbo_ghost.switchweapon = self.weapon;
			self.akimbo_ghost.modelindex = self.modelindex;
			self.akimbo_ghost.weapons = self.weapons;
			self.akimbo_ghost.owner = self;
			self = self.akimbo_ghost;
			CL_SpawnWeaponentity();
			self.weaponentity.state = WS_RAISE;
			weapon_action(self.weapon, WR_SETUP);
			weapon_thinkf(WFRAME_IDLE, g_balance_weaponswitchdelay, w_ready);
			weapon_boblayer1(PLAYER_WEAPONSELECTION_SPEED, '0 0 0');
			self = oldself;
			self.weaponentity.cnt = 0;
		}
		self.akimbo_ghost.ammo_shells = self.ammo_shells;
		self.akimbo_ghost.ammo_cells = self.ammo_cells;
		self.akimbo_ghost.ammo_nails = self.ammo_nails;
		self.akimbo_ghost.ammo_rockets = self.ammo_rockets;
		self.akimbo_ghost.weapons = self.weapons;
		self.akimbo_ghost.BUTTON_ATCK = self.BUTTON_ATCK;
		self.akimbo_ghost.BUTTON_ATCK2 = self.BUTTON_ATCK2;
		self.akimbo_ghost.deadflag = self.deadflag;
		self.akimbo_ghost.colormap = self.colormap;
		self.akimbo_ghost.effects = self.effects;
		self.akimbo_ghost.alpha = self.alpha;
		self.akimbo_ghost.health = self.health;
		self.akimbo_ghost.switchweapon = self.switchweapon;
		self.akimbo_ghost.v_angle = self.v_angle;
		self.akimbo_ghost.origin = self.origin;
		self = self.akimbo_ghost;
		W_WeaponFrame();
		self = oldself;
		self.ammo_shells = self.akimbo_ghost.ammo_shells;
		self.ammo_cells = self.akimbo_ghost.ammo_cells;
		self.ammo_nails = self.akimbo_ghost.ammo_nails;
		self.ammo_rockets = self.akimbo_ghost.ammo_rockets;
	}
	else
	{
		if (self.akimbo_ghost)
			Akimbo_GhostRemove(self);
	}
}

void Akimbo_Init()
{
	float i, j, n;
	n = tokenize_console(cvar_string("g_akimbo_weapons"));
	for (i = 0; i < n; i++)
		for (j = WEP_FIRST; j <= WEP_LAST; j++)
			if (argv(i) == get_weaponinfo(j).netname)
			{
				g_akimbo_weapons |= W_WeaponBit(j);
				break;
			}

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
			WEPBIT_ROCKET_LAUNCHER;

	g_akimbo_weapons = g_akimbo_weapons & weapons_with_akimbo_support;
	g_powerup_strength_akimbo = cvar("g_powerup_strength_akimbo");
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
	float wpnbit = W_WeaponBit(wpn);
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

float Akimbo_Active(entity e)
{
	if (e.akimbo_ghost)
		return 1;
	if (Akimbo_Owner(e) != e)
		return 2;

	return 0;
}

void Akimbo_Clear(entity e)
{
	Akimbo_GhostRemove(e);
	e.akimbo_weapons = 0;
}

float Akimbo_HaveWeapon(entity e, float wpn)
{
	float wpnbit = W_WeaponBit(wpn);
	if ((e.akimbo_weapons & wpnbit) ||
			(g_powerup_strength_akimbo && e.strength_finished > time &&
			(wpnbit & weapons_with_akimbo_support)))
		return TRUE;
	return FALSE;
}
