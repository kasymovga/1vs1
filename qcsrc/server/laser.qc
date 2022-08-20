float g_laser_refire;
float g_laser_animtime;
float g_laser_speed;
float g_laser_damage;
float g_laser_damage_edge;
float g_laser_radius;
float g_laser_force;
float g_laser_offhand;

entity(vector _shotdir, float _speed, float _dmg, float _dmg_edge, float _dmg_radius, float _force, float expl, float issec, float lifetime) laser_projectile {
	entity missile = projectile(TRUE, (expl ? PROJECTILE_RM_LASER : PROJECTILE_LASER), TRUE, self);
	projectile_setup(missile, weapon_shotorg, WEP_LASER | (issec ? HITTYPE_SECONDARY: 0), _dmg, _dmg_edge, _dmg_radius, _force, 0, MOVETYPE_FLY);
	missile.team = self.team;
	missile.velocity = _shotdir * _speed;
	weapon_setup_projectile_velocity(missile);
	missile.touch = projectile_touch_explode;
	missile.think = stdproc_remove;
	missile.nextthink = time + lifetime;
	return missile;
}

var float(void) laser_weapon_frame_handle_next;
float(void) laser_weapon_frame_handle {
	if (self.BUTTON_ATCK2) {
		float w = self.weapon;
		float w2 = self.switchweapon;
		float ws = self.weaponentity.state;
		if (g_laser_offhand) {
			self.weapon = WEP_LASER;
			self.switchweapon = WEP_LASER;
		}
		if (weapon_prepareattack(0, g_laser_refire)) {
			weapon_setup_shotdir(self, v_forward, 3, "weapons/lasergun_fire.wav", 1);
			pointparticles(particleeffectnum("laser_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
			laser_projectile(weapon_shotdir, g_laser_speed, g_laser_damage, g_laser_damage_edge, g_laser_radius, g_laser_force, 0, TRUE, 10);
			if not(g_laser_offhand) {
				weapon_thinkf(WFRAME_FIRE1, g_laser_animtime, weapon_ready);
			}
		}
		if (g_laser_offhand) {
			self.weapon = w;
			self.switchweapon = w2;
			self.weaponentity.state = ws;
		}
		self.BUTTON_ATCK2 = 0;
	}
	return laser_weapon_frame_handle_next();
}

void(void) laser_init {
	if not(cvar("g_laser"))
		return;

	client_button_atck2_busy = TRUE;
	CVAR_CACHE(g_laser_refire);
	CVAR_CACHE(g_laser_animtime);
	CVAR_CACHE(g_laser_speed);
	CVAR_CACHE(g_laser_damage);
	CVAR_CACHE(g_laser_damage_edge);
	CVAR_CACHE(g_laser_radius);
	CVAR_CACHE(g_laser_force);
	CVAR_CACHE(g_laser_offhand);
	laser_weapon_frame_handle_next = plugin_chain_weapon_frame_handle;
	plugin_chain_weapon_frame_handle = laser_weapon_frame_handle;
	precache_sound ("weapons/lasergun_fire.wav");
}
