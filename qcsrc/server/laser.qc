float g_laser_refire;
float g_laser_speed;
float g_laser_damage;
float g_laser_damage_edge;
float g_laser_radius;
float g_laser_force;

void(void) laser_touch {
	PROJECTILE_TOUCH;
	self.event_damage = stdproc_nothing;
	damage_radius(self, self.owner, self.dmg, self.dmg_edge, self.dmg_radius, world, self.dmg_force, self.projectiledeathtype, other);
	remove(self);
}

void(vector _shotdir, float _speed, float _dmg, float _dmg_edge, float _dmg_radius, float _force, float expl, float issec, float lifetime) laser_projectile {
	entity missile = projectile(TRUE, (expl ? PROJECTILE_RM_LASER : PROJECTILE_LASER), TRUE, self);
	missile.team = self.team;
	missile.dmg = _dmg;
	missile.dmg_force = _force;
	missile.dmg_radius = _dmg_radius;
	missile.dmg_edge = _dmg_edge;
	missile.classname = "laserbolt";
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = _dmg;
	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_LASER | (issec ? HITTYPE_SECONDARY: 0);
	setorigin (missile, w_shotorg);
	missile.velocity = _shotdir * _speed;
	weapon_setup_projectile_velocity(missile);
	missile.angles = vectoangles (missile.velocity);
	missile.touch = laser_touch;
	missile.think = stdproc_remove;
	missile.nextthink = time + lifetime;
}

var float(void) laser_weapon_frame_handle_next;
float(void) laser_weapon_frame_handle {
	if (self.BUTTON_ATCK2) {
		float w = self.weapon;
		float w2 = self.switchweapon;
		float ws = self.weaponentity.state;
		self.weapon = WEP_LASER;
		self.switchweapon = WEP_LASER;
		if (weapon_prepareattack(0, g_laser_refire)) {
			weapon_setup_shotdir(self, v_forward, 3, "weapons/lasergun_fire.wav", 1);
			pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg_visual, w_shotdir * 1000, 1);
			laser_projectile(w_shotdir, g_laser_speed, g_laser_damage, g_laser_damage_edge, g_laser_radius, g_laser_force, 0, TRUE, 10);
		}
		self.weapon = w;
		self.switchweapon = w2;
		self.BUTTON_ATCK2 = 0;
		self.weaponentity.state = ws;
	}
	return laser_weapon_frame_handle_next();
}

void(void) laser_init {
	if not(cvar("g_laser"))
		return;

	CACHE_CVAR(g_laser_refire);
	CACHE_CVAR(g_laser_speed);
	CACHE_CVAR(g_laser_damage);
	CACHE_CVAR(g_laser_damage_edge);
	CACHE_CVAR(g_laser_radius);
	CACHE_CVAR(g_laser_force);
	laser_weapon_frame_handle_next = gamehook_chain_weapon_frame_handle;
	gamehook_chain_weapon_frame_handle = laser_weapon_frame_handle;
}
