float g_balance_minstanex_animtime;
float g_balance_minstanex_refire;
float g_balance_minstanex_explode;
float g_balance_minstanex_explode_damage;
float g_balance_minstanex_explode_edgedamage;
float g_balance_minstanex_explode_force;
float g_balance_minstanex_explode_radius;
float g_balance_minstanex_laser;
float g_balance_minstanex_laser_count;
float g_balance_minstanex_laser_damage;
float g_balance_minstanex_laser_edgedamage;
float g_balance_minstanex_laser_force;
float g_balance_minstanex_laser_lifetime;
float g_balance_minstanex_laser_spread;
float g_balance_minstanex_laser_speed;
float g_balance_minstanex_laser_radius;
float g_balance_minstanex_laser_refire;
float g_balance_minstanex_laser_rapid;
float g_balance_minstanex_laser_rapid_delay;
float g_balance_minstanex_laser_rapid_refire;

.float minstanex_lasthit;
.float laser_hold;

float weapon_minstanex_draw_beam_particless_effect;
void weapon_minstanex_draw_beam_particless(vector start, vector end, vector to) {
	weapon_nex_whoosh(start, end);
	trailparticles(world, weapon_minstanex_draw_beam_particless_effect, start, end);
}

void weapon_minstanex_attack (void)
{
	float flying;
	flying = physics_is_flying(self); // do this BEFORE to make the trace values from bullet_railgun last

	antilag_begin(Akimbo_Owner(self));
	weapon_setup_shot (self, 0, "weapons/minstanexfire.wav", 1);

	yoda = 0;
	damage_goodhits = 0;
	headshot = 0;
	bullet_railgun (w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, 10000, 800, 0, 0, 0, 0, WEP_MINSTANEX);
	antilag_end();

	if(yoda > 1)
		announce(self, "announcer/male/yoda.wav", "^5Awesome");

	if(headshot)
		announce(self, "announcer/male/headshot.wav", "^1Head^3Shot");

	self.minstanex_lasthit = damage_goodhits;
	pointparticles(particleeffectnum("nex_muzzleflash"), w_shotorg_visual, w_shotdir * 1000, 1);

	// teamcolor / hit beam effect
	if(teamplay)
	{
	    switch(self.team)
	    {
            case COLOR_TEAM1:   // Red
                if(damage_goodhits)
                    weapon_minstanex_draw_beam_particless_effect = particleeffectnum("TE_TEI_G3RED_HIT");
                else
                    weapon_minstanex_draw_beam_particless_effect = particleeffectnum("TE_TEI_G3RED");
                break;
            case COLOR_TEAM2:   // Blue
                if(damage_goodhits)
                    weapon_minstanex_draw_beam_particless_effect = particleeffectnum("TE_TEI_G3BLUE_HIT");
                else
                    weapon_minstanex_draw_beam_particless_effect = particleeffectnum("TE_TEI_G3BLUE");
                break;
            case COLOR_TEAM3:   // Yellow
                if(damage_goodhits)
                    weapon_minstanex_draw_beam_particless_effect = particleeffectnum("TE_TEI_G3YELLOW_HIT");
                else
                    weapon_minstanex_draw_beam_particless_effect = particleeffectnum("TE_TEI_G3YELLOW");
                break;
            case COLOR_TEAM4:   // Pink
                if(damage_goodhits)
                    weapon_minstanex_draw_beam_particless_effect = particleeffectnum("TE_TEI_G3PINK_HIT");
                else
                    weapon_minstanex_draw_beam_particless_effect = particleeffectnum("TE_TEI_G3PINK");
                break;
	    }
	}
	else
        weapon_minstanex_draw_beam_particless_effect = particleeffectnum("TE_TEI_G3");

	WarpZone_DrawEffectTriangle(w_shotorg, w_shotorg_visual,  WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos), weapon_minstanex_draw_beam_particless);

	// flash and burn the wall
	if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)) {
		if (g_balance_minstanex_explode) {
			entity e = spawn();
			setorigin(e, trace_endpos);
			entity o = Akimbo_Owner(self);
			damage_radius (e, o, g_balance_minstanex_explode_damage, g_balance_minstanex_explode_edgedamage, g_balance_minstanex_explode_radius, world, g_balance_minstanex_explode_force, 0, world);
			pointparticles(particleeffectnum("rocket_explode"), trace_endpos, '0 0 0', 1);
			remove(e);
		}
		damage_info(trace_endpos, 10000, 0, 0, 800 * WarpZone_TransformVelocity(WarpZone_trace_transform, w_shotdir), WEP_MINSTANEX, self);
	}

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - 1;
}

void weapon_minstanex_laser_touch() {
	PROJECTILE_TOUCH;
	self.event_damage = stdproc_nothing;
	damage_radius (self, self.owner, g_balance_minstanex_laser_damage * self.dmg, g_balance_minstanex_laser_edgedamage * self.dmg, g_balance_minstanex_laser_radius, world, g_balance_minstanex_laser_force * self.dmg, self.projectiledeathtype, other);
	remove (self);
}

void weapon_minstanex_laser_projectile(vector _shotdir, float ff) {
	entity missile = projectile(TRUE, (g_balance_minstanex_explode ? PROJECTILE_RM_LASER : PROJECTILE_LASER), TRUE, self);
	missile.team = self.team;
	missile.dmg = ff;
	missile.classname = "laserbolt";
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = g_balance_minstanex_laser_damage;
	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_LASER | HITTYPE_SECONDARY;
	setorigin (missile, w_shotorg);
	missile.velocity = _shotdir * g_balance_minstanex_laser_speed;
	weapon_setup_projectile_velocity(missile);
	missile.angles = vectoangles (missile.velocity);
	missile.touch = weapon_minstanex_laser_touch;
	missile.think = stdproc_remove;
	missile.nextthink = time + g_balance_minstanex_laser_lifetime;
}

void weapon_minstanex_laser_attack_setup() {
	float w_safe = self.weapon;
	self.weapon = WEP_LASER;
	weapon_setup_shotdir(self, v_forward, 3, "weapons/lasergun_fire.wav", 1);
	self.weapon = w_safe;
}

float weapon_minstanex_player_can_fire() {
	float w_safe = self.weapon;
	self.weapon = WEP_LASER;
	float r = player_can_fire(self, TRUE);
	self.weapon = w_safe;
	return r;
}

void weapon_minstanex_laser_attack() {
	weapon_minstanex_laser_attack_setup();
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg_visual, w_shotdir * 1000, 1);
	float f1, f2;
	if (g_balance_minstanex_laser_count > 1) {
		f1 = g_balance_minstanex_laser_spread / (g_balance_minstanex_laser_count - 1);
		f2 = -0.5 * g_balance_minstanex_laser_spread;
	} else
		f1 = f2 = 0;

	float i;
	vector v;
	float ff = 1 / g_balance_minstanex_laser_count;
	for (i = 0; i < g_balance_minstanex_laser_count; i++) {
		v = w_shotdir + v_right * f2;
		f2 += f1;
		weapon_minstanex_laser_projectile(v, ff);
	}
}

void weapon_minstanex_laser_attack_rapid() {
	weapon_minstanex_laser_attack_setup();
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg_visual, w_shotdir * 1000, 1);
	weapon_minstanex_laser_projectile(w_shotdir, 1);
}

float weapon_minstanex(float req)
{
	if (req == WR_AIM)
	{
		if (self.ammo_cells > 0 || self.items & IT_UNLIMITED_AMMO)
			self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
		else
			self.BUTTON_ATCK2 = bot_aim(g_balance_laser_primary_speed, 0, g_balance_laser_primary_lifetime, FALSE);
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		{
			if (weapon_prepareattack(0, g_balance_minstanex_refire))
			{
				weapon_minstanex_attack();
				weapon_thinkf(WFRAME_FIRE1, g_balance_minstanex_animtime, weapon_ready);
			}
		}
		if (g_balance_minstanex_laser) {
			if (self.BUTTON_ATCK2)
			{
				if not(self.laser_hold) {
					if (self.jump_interval <= time)
					if (weapon_minstanex_player_can_fire())
					{
						self.jump_interval = time + g_balance_minstanex_laser_refire * weapon_rate_factor();
						//W_Laser_Attack(FALSE);
						weapon_minstanex_laser_attack();
						if (g_balance_minstanex_laser_rapid)
							self.laser_hold = time + g_balance_minstanex_laser_rapid_delay;
					}
				} else {
					if (self.laser_hold <= time)
					if (self.jump_interval <= time)
					if (weapon_minstanex_player_can_fire()) {
						self.jump_interval = time + g_balance_minstanex_laser_rapid_refire * weapon_rate_factor();
						weapon_minstanex_laser_attack_rapid();
					}
				}
			} else {
				self.laser_hold = 0;
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/nexflash.md3");
		precache_sound ("weapons/minstanexfire.wav");
		precache_sound ("weapons/nexwhoosh1.wav");
		precache_sound ("weapons/nexwhoosh2.wav");
		precache_sound ("weapons/nexwhoosh3.wav");
		weapon_laser(WR_PRECACHE);
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_MINSTANEX);
		self.minstanex_lasthit = 0;
		self.laser_hold = 0;
	}
	else if (req == WR_CHECKAMMO1)
	{
		return self.ammo_cells >= 1;
	}
	else if (req == WR_CHECKAMMO2)
		return TRUE;
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE) {
		w_fragprefix = "^5INSTA";
		w_deathtypestring = "has been vaporized by";
	} else if (req == WR_RESETPLAYER)
	{
		self.minstanex_lasthit = 0;
	}
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_minstanex_animtime);
		CACHE_CVAR(g_balance_minstanex_refire);
		CACHE_CVAR(g_balance_minstanex_explode);
		CACHE_CVAR(g_balance_minstanex_explode_damage);
		CACHE_CVAR(g_balance_minstanex_explode_edgedamage);
		CACHE_CVAR(g_balance_minstanex_explode_force);
		CACHE_CVAR(g_balance_minstanex_explode_radius);
		CACHE_CVAR(g_balance_minstanex_laser);
		g_balance_minstanex_laser_count = max(1, cvar("g_balance_minstanex_laser_count"));
		CACHE_CVAR(g_balance_minstanex_laser_damage);
		CACHE_CVAR(g_balance_minstanex_laser_edgedamage);
		CACHE_CVAR(g_balance_minstanex_laser_force);
		CACHE_CVAR(g_balance_minstanex_laser_lifetime);
		CACHE_CVAR(g_balance_minstanex_laser_speed);
		CACHE_CVAR(g_balance_minstanex_laser_spread);
		CACHE_CVAR(g_balance_minstanex_laser_radius);
		CACHE_CVAR(g_balance_minstanex_laser_refire);
		CACHE_CVAR(g_balance_minstanex_laser_rapid);
		CACHE_CVAR(g_balance_minstanex_laser_rapid_delay);
		CACHE_CVAR(g_balance_minstanex_laser_rapid_refire);
		if (g_balance_minstanex_explode) {
			dlc_require("rm_effects_v2");
			projectile_init(PROJECTILE_RM_LASER);
		} else
			projectile_init(PROJECTILE_LASER);
	}
	return TRUE;
}
