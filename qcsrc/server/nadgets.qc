.float nadget_hold;
.entity nadget_pb;
float g_balance_nadget_grenade_ammo;
float g_balance_nadget_grenade_damage;
float g_balance_nadget_grenade_damageforcescale;
float g_balance_nadget_grenade_edgedamage;
float g_balance_nadget_grenade_force;
float g_balance_nadget_grenade_health;
float g_balance_nadget_grenade_lifetime;
float g_balance_nadget_grenade_radius;
float g_balance_nadget_grenade_speed;
float g_balance_nadget_grenade_speed_up;

float g_balance_nadget_molotov_damage;
float g_balance_nadget_molotov_radius;
float g_balance_nadget_molotov_edgedamage;
float g_balance_nadget_molotov_force;
float g_balance_nadget_molotov_count;
float g_balance_nadget_molotov_lifetime;
float g_balance_nadget_molotov_shard_burntime;
float g_balance_nadget_molotov_shard_damage;
float g_balance_nadget_molotov_shard_radius;
float g_balance_nadget_molotov_shard_edgedamage;
float g_balance_nadget_molotov_shard_lifetime;

float g_balance_nadget_tesla_damage;
float g_balance_nadget_tesla_radius;
float g_balance_nadget_tesla_edgedamage;
float g_balance_nadget_tesla_force;
float g_balance_nadget_tesla_count;
float g_balance_nadget_tesla_lifetime;
float g_balance_nadget_tesla_beam_damage;
float g_balance_nadget_tesla_beam_force;
float g_balance_nadget_tesla_beam_radius;
float g_balance_nadget_tesla_beam_refire;
float g_balance_nadget_tesla_beam_lifetime;

float g_balance_nadget_throw_speedfactor_min;
float g_balance_nadget_throw_holdtime;
.float nadget_type;
.entity nadget_menu;
.float nadget_button;
#define NADGET_GRENADE 1
#define NADGET_MOLOTOV 2
#define NADGET_TESLA 4
#define NADGET_LAST 4
float available_nadgets_count;
float available_nadgets[3];
void Nadget_Select(float nadget);

float Nadget_CodeByName(string name) {
	if (name == "grenade")
		return NADGET_GRENADE;

	if (name == "molotov")
		return NADGET_MOLOTOV;

	if (name == "tesla")
		return NADGET_TESLA;

	return 0;
}

string Nadget_HumanNameByCode(float f) {
	switch (f) {
		case NADGET_GRENADE:
			return "Grenade";
		case NADGET_MOLOTOV:
			return "Molotov";
		case NADGET_TESLA:
			return "Tesla";
	}
	return "WTF";
}

void Nadget_ObserverHook() {
	self.nadget_type = 0;
	if (self.nadget_menu) {
		remove(self.nadget_menu);
		self.nadget_menu = world;
	}
}

void Nadget_SpawnHook() {
	if not(g_nadgets)
		return;

	if not(clienttype(self) == CLIENTTYPE_REAL) {
		self.nadget_type = available_nadgets[0];
		return;
	}

	self.nadget_hold = 0;
	self.nadget_button = FALSE;
	if not(self.nadget_type) {
		if (available_nadgets_count == 1) {
			self.nadget_type = available_nadgets[0];
		} else if not(self.nadget_menu) {
			self.nadget_menu = Menu_Prepare(self, "nadget", "Select your nadget", 0, Nadget_Select);
			float i;
			for (i = 0; i < available_nadgets_count; i++) {
				Menu_Add_Item(self.nadget_menu, Nadget_HumanNameByCode(available_nadgets[i]));
			}
		}
	}
}

void Nadget_Menu_Remove() {
	if (self.nadget_menu) {
		Menu_Remove(self.nadget_menu);
		self.nadget_menu = world;
	}
}

void Nadget_Select(float nadget) {
	if (nadget < 0 || nadget >= available_nadgets_count)
		return;

	if not(self.nadget_type)
		self.nadget_type = available_nadgets[nadget];

	Nadget_Menu_Remove();
}

void Nadget_Init() {
	//CACHE_CVAR(g_nadgets);
	float n, i;
	n = tokenizebyseparator(cvar_string("g_nadgets"), " ");
	for (i = 0; i < n; i++) {
		g_nadgets |= Nadget_CodeByName(argv(i));
	}
	if not(g_nadgets)
		return;

	CACHE_CVAR(g_balance_nadget_grenade_ammo);
	CACHE_CVAR(g_balance_nadget_grenade_damage);
	CACHE_CVAR(g_balance_nadget_grenade_damageforcescale);
	CACHE_CVAR(g_balance_nadget_grenade_edgedamage);
	CACHE_CVAR(g_balance_nadget_grenade_force);
	CACHE_CVAR(g_balance_nadget_grenade_health);
	CACHE_CVAR(g_balance_nadget_grenade_lifetime);
	CACHE_CVAR(g_balance_nadget_grenade_speed);
	CACHE_CVAR(g_balance_nadget_grenade_speed_up);
	CACHE_CVAR(g_balance_nadget_grenade_radius);
	CACHE_CVAR(g_balance_nadget_throw_speedfactor_min);
	CACHE_CVAR(g_balance_nadget_throw_holdtime);
	CACHE_CVAR(g_balance_nadget_molotov_damage);
	CACHE_CVAR(g_balance_nadget_molotov_radius);
	CACHE_CVAR(g_balance_nadget_molotov_edgedamage);
	CACHE_CVAR(g_balance_nadget_molotov_force);
	CACHE_CVAR(g_balance_nadget_molotov_count);
	CACHE_CVAR(g_balance_nadget_molotov_lifetime);
	CACHE_CVAR(g_balance_nadget_molotov_shard_burntime);
	CACHE_CVAR(g_balance_nadget_molotov_shard_damage);
	CACHE_CVAR(g_balance_nadget_molotov_shard_edgedamage);
	CACHE_CVAR(g_balance_nadget_molotov_shard_lifetime);
	CACHE_CVAR(g_balance_nadget_molotov_shard_radius);
	CACHE_CVAR(g_balance_nadget_tesla_damage);
	CACHE_CVAR(g_balance_nadget_tesla_radius);
	CACHE_CVAR(g_balance_nadget_tesla_edgedamage);
	CACHE_CVAR(g_balance_nadget_tesla_force);
	CACHE_CVAR(g_balance_nadget_tesla_count);
	CACHE_CVAR(g_balance_nadget_tesla_lifetime);
	CACHE_CVAR(g_balance_nadget_tesla_beam_damage);
	CACHE_CVAR(g_balance_nadget_tesla_beam_force);
	CACHE_CVAR(g_balance_nadget_tesla_beam_radius);
	CACHE_CVAR(g_balance_nadget_tesla_beam_refire);
	CACHE_CVAR(g_balance_nadget_tesla_beam_lifetime);
	precache_sound("weapons/grenade_bounce1.wav");
	precache_sound("weapons/grenade_bounce2.wav");
	precache_sound("weapons/grenade_bounce3.wav");
	precache_sound("weapons/grenade_bounce4.wav");
	precache_sound("weapons/grenade_bounce5.wav");
	precache_sound("weapons/grenade_bounce6.wav");
	precache_sound("weapons/grenade_fire.wav");
	available_nadgets_count = 0;
	for (i = 1; i <= NADGET_LAST; i *= 2) {
		if (g_nadgets & i) {
			available_nadgets[available_nadgets_count] = i;
			available_nadgets_count++;
		}
	}
}

void Nadget_Grenade_Touch (void)
{
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM || self.nadget_type == NADGET_MOLOTOV || self.nadget_type == NADGET_TESLA) {
		if (self.nadget_type == NADGET_MOLOTOV)
			self.cnt = 1;

		self.use();
	} else if not(self.nadget_type == NADGET_TESLA) {
		if (self.owner)
			self.owner = world;

		float r;
		r = random() * 6;
		if(r < 1)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce1.wav", VOL_BASE, ATTN_NORM);
		else if(r < 2)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce2.wav", VOL_BASE, ATTN_NORM);
		else if(r < 3)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce3.wav", VOL_BASE, ATTN_NORM);
		else if(r < 4)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce4.wav", VOL_BASE, ATTN_NORM);
		else if(r < 5)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce5.wav", VOL_BASE, ATTN_NORM);
		else
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce6.wav", VOL_BASE, ATTN_NORM);
		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void Nadget_Molotov_Touch() {
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM)
	if(Fire_AddDamage(other, self.realowner, g_balance_nadget_molotov_shard_damage, g_balance_nadget_molotov_shard_lifetime, self.projectiledeathtype | HITTYPE_HEADSHOT) >= 0)
	{
		remove(self);
		return;
	}
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

void Nadget_Molotov_Think() {
	if(time > self.pushltime) {
		remove(self);
		return;
	}

	W_Fireball_LaserPlay(0.1, g_balance_nadget_molotov_shard_radius, g_balance_nadget_molotov_shard_edgedamage, g_balance_nadget_molotov_shard_damage, g_balance_nadget_molotov_shard_burntime);

	self.nextthink = time + 0.1;
}

void Nadget_Tesla_Think() {
	if(time > self.pushltime) {
		RadiusDamage (self, self.realowner, g_balance_nadget_tesla_damage, g_balance_nadget_tesla_edgedamage, g_balance_nadget_tesla_radius, world, g_balance_nadget_tesla_force, self.projectiledeathtype, other);
		remove(self);
		return;
	}
	entity e;
	for(e = findradius(self.origin, g_balance_nadget_tesla_beam_radius); e; e = e.chain) {
		if not(e.takedamage == DAMAGE_AIM)
			continue;

		traceline(self.origin, e.origin, MOVE_WORLDONLY, world);
		if (trace_fraction < 1)
			continue;

		te_lightning1(world, self.origin, e.origin);
		sound(self, CHAN_WEAPON, "weapons/electro_impact.wav", VOL_BASE, ATTN_NORM);
		Damage(e, self, self.realowner, g_balance_nadget_tesla_beam_damage, WEP_NADGET_TESLA, e.origin, normalize(e.origin - self.origin) * g_balance_nadget_tesla_beam_force);
	}

	self.nextthink = time + g_balance_nadget_tesla_beam_refire;
}

void Nadget_Grenade_Explode (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.realowner, other))
				if(IsFlying(other))
					announce(self.realowner, "announcer/male/airshot.wav");

	float i;
	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	if (self.nadget_type == NADGET_GRENADE) {
		RadiusDamage (self, self.realowner, g_balance_nadget_grenade_damage, g_balance_nadget_grenade_edgedamage, g_balance_nadget_grenade_radius, world, g_balance_nadget_grenade_force, self.projectiledeathtype, other);
	} else if (self.nadget_type == NADGET_MOLOTOV) {
		for (i = 0; i < g_balance_nadget_molotov_count; i++) {
			entity proj;
			proj = spawn();
			proj.realowner = proj.owner = self.owner;
			proj.classname = "grenade";
			proj.bot_dodge = TRUE;
			proj.bot_dodgerating = g_balance_nadget_molotov_damage;
			proj.movetype = MOVETYPE_BOUNCE;
			proj.projectiledeathtype = WEP_NADGET_MOLOTOV;
			proj.touch = Nadget_Molotov_Touch;
			PROJECTILE_MAKETRIGGER(proj);
			setsize(proj, '-4 -4 -4', '4 4 4');
			setorigin(proj, self.origin);
			proj.think = Nadget_Molotov_Think;
			proj.nextthink = time;
			if (self.cnt)
				proj.velocity = (normalize(randomvec()) * 0.5 + normalize(self.velocity) * 0.5 + trace_plane_normal) * g_balance_nadget_molotov_force;
			else
				proj.velocity = (normalize(randomvec()) * 0.5 + normalize(self.velocity) * 0.5) * g_balance_nadget_molotov_force;
			proj.pushltime = time + g_balance_nadget_molotov_shard_lifetime;
			W_SetupProjectileVelocity(proj);
			proj.owner = world;

			proj.angles = vectoangles(proj.velocity);
			proj.flags = FL_PROJECTILE;

			CSQCProjectile(proj, TRUE, PROJECTILE_FIREMINE, TRUE);
		}
		RadiusDamage (self, self.realowner, g_balance_nadget_molotov_damage, g_balance_nadget_molotov_edgedamage, g_balance_nadget_molotov_radius, world, 0, self.projectiledeathtype, other);
	} else if (self.nadget_type == NADGET_TESLA) {
		entity lb;
		lb = spawn();
		lb.realowner = lb.owner = self.owner;
		lb.bot_dodge = TRUE;
		lb.bot_dodgerating = g_balance_nadget_tesla_damage;
		setorigin(lb, self.origin);
		lb.think = Nadget_Tesla_Think;
		lb.nextthink = time;
		lb.scale = 4;
		lb.pushltime = time + g_balance_nadget_tesla_beam_lifetime;
		lb.projectiledeathtype = self.projectiledeathtype;
		setmodel(lb, "models/ebomb.mdl");
		RadiusDamage (self, self.realowner, g_balance_nadget_tesla_damage, g_balance_nadget_tesla_edgedamage, g_balance_nadget_tesla_radius, world, g_balance_nadget_tesla_force, self.projectiledeathtype, other);
	}

	remove (self);
}

void Nadget_Grenade_Throw() {
	local entity gren;

	if (self.ammo_rockets < g_balance_nadget_grenade_ammo)
		return;

	if (self.deadflag)
		makevectors(randomvec());
	else
		makevectors(self.v_angle);
	sound(self, CHAN_WEAPON, "weapons/grenade_fire.wav", VOL_BASE, ATTN_NORM);
	w_shotorg = self.origin;
	tracebox(w_shotorg, '-4 -4 -4', '4 4 4', w_shotorg + v_forward * 21, MOVE_NOMONSTERS, self);
	w_shotorg = w_shotorg + (trace_fraction * 20 * v_forward);
	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = spawn ();
	gren.nadget_type = self.nadget_type;
	gren.owner = gren.realowner = Akimbo_Owner(self);
	gren.classname = "grenade";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = g_balance_nadget_grenade_damage;
	PROJECTILE_MAKETRIGGER(gren);
	setsize(gren, '-4 -4 -4', '4 4 4');
	setorigin(gren, w_shotorg);

	gren.think = adaptor_think2use;
	gren.takedamage = DAMAGE_YES;
	gren.health = g_balance_nadget_grenade_health;
	gren.damageforcescale = g_balance_nadget_grenade_damageforcescale;
	gren.event_damage = W_Grenade_Damage;
	gren.velocity = (w_shotdir * g_balance_nadget_grenade_speed + v_up * g_balance_nadget_grenade_speed_up) *
			bound(0, g_balance_nadget_throw_speedfactor_min + (1 - g_balance_nadget_throw_speedfactor_min) * self.nadget_hold, 1);
	W_SetupProjectileVelocity(gren);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	gren.use = Nadget_Grenade_Explode;
	gren.touch = Nadget_Grenade_Touch;
	if (self.nadget_type == NADGET_GRENADE) {
		gren.nextthink = time + g_balance_nadget_grenade_lifetime - g_balance_nadget_throw_holdtime * self.nadget_hold;
		gren.movetype = MOVETYPE_BOUNCE;
		gren.projectiledeathtype = WEP_NADGET_GRENADE;
		CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE_BOUNCING, TRUE);
	} else if (self.nadget_type == NADGET_MOLOTOV) {
		gren.nextthink = time + g_balance_nadget_molotov_lifetime;
		gren.movetype = MOVETYPE_TOSS;
		gren.projectiledeathtype = WEP_NADGET_MOLOTOV;
		CSQCProjectile(gren, TRUE, PROJECTILE_MOLOTOV, TRUE);
	} else if (self.nadget_type == NADGET_TESLA) {
		gren.nextthink = time + g_balance_nadget_tesla_lifetime;
		gren.movetype = MOVETYPE_BOUNCE;
		gren.projectiledeathtype = WEP_NADGET_TESLA;
		CSQCProjectile(gren, TRUE, PROJECTILE_TESLA, TRUE);
	}

	self.ammo_rockets -= g_balance_nadget_grenade_ammo;
}

void Nadget_Reset() {
	if (self.nadget_pb) {
		remove(self.nadget_pb);
		self.nadget_pb = world;
	}
	if (self.nadget_hold > 0) {
		Nadget_Grenade_Throw();

		self.nadget_hold = 0;
	}
	self.nadget_button = FALSE;
}

void Nadget_Clear(float killed) {
	Nadget_Reset();
	if not(killed)
		Nadget_Menu_Remove();
}

void Nadget_Button() {
	if (self.ammo_rockets < g_balance_nadget_grenade_ammo)
		self.nadget_button = FALSE;
	else
		self.nadget_button = !self.nadget_button;
}

void Nadget_Frame() {
	if not(self.deadflag == DEAD_NO) {
		Nadget_Reset();
		return;
	}

	float nadget_btn = (self.nadget_button || (g_grappling_hook ? 0 : self.BUTTON_HOOK));

	if not(nadget_btn) {
		if (self.nadget_hold < 0) {
			self.nadget_hold = 0;
			return;
		}
	}
	if (nadget_btn && self.nadget_hold >= 0) {
		if (self.ammo_rockets < g_balance_nadget_grenade_ammo) {
			Nadget_Reset();
		} else if (g_balance_nadget_throw_holdtime > 0) {
			self.nadget_hold += frametime / g_balance_nadget_throw_holdtime;
			if not(self.nadget_pb)
				self.nadget_pb = ProgressBar_Create("Throw power", self);

			ProgressBar_SetValue(self.nadget_pb, self.nadget_hold);
		} else
			self.nadget_hold = 1;
	}
	if (self.nadget_hold && (!nadget_btn || self.nadget_hold >= 1)) {
		Nadget_Grenade_Throw();
		if (nadget_btn)
			self.nadget_hold = -1;
		else
			self.nadget_hold = 0;

		Nadget_Reset();
	}
}

void Nadget_Joint() {
}
