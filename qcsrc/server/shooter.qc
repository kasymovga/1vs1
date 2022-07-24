void(void) shooter_setup {
	if (self.target != "")
		self.enemy = find(world, targetname, self.target);

	if (!self.enemy) {
		makevectors(self.angles);
		self.movedir = v_forward;
		self.movedir_z = -self.movedir_z;
	}
}

void(void) shooter_plasma_use {
	vector v;
	if (self.enemy)
		v = normalize(self.enemy.origin - self.origin);
	else {
		v = self.movedir;
	}
	pointparticles(particleeffectnum("laser_muzzleflash"), self.origin, v * 1000, 1);
	entity missile = projectile(TRUE, PROJECTILE_HLAC, TRUE, world);
	missile.realowner = activator;
	projectile_setup(missile, self.origin, WEP_HLAC, g_balance_hlac_primary_damage,
			g_balance_hlac_primary_edgedamage, g_balance_hlac_primary_radius, g_balance_hlac_primary_force, 0, MOVETYPE_FLY);
	missile.existsonlyfor = activator.existsonlyfor;
    missile.velocity = v * g_balance_hlac_primary_speed;
	missile.touch = projectile_touch_explode;
	missile.think = stdproc_remove;
    missile.nextthink = time + g_balance_hlac_primary_lifetime;
}

void(void) shooter_rocket_use {
	vector v = normalize(self.enemy.origin - self.origin);
	pointparticles(particleeffectnum("laser_muzzleflash"), self.origin, v * 1000, 1);
	entity missile = projectile(TRUE, PROJECTILE_ROCKET, TRUE, world);
	missile.realowner = activator;
	projectile_setup(missile, self.origin, WEP_ROCKET_LAUNCHER, g_balance_rocketlauncher_damage,
			g_balance_rocketlauncher_edgedamage, g_balance_rocketlauncher_radius, g_balance_rocketlauncher_force, 0, MOVETYPE_FLY);
	missile.existsonlyfor = activator.existsonlyfor;
    missile.velocity = v * g_balance_rocketlauncher_speed;
	missile.touch = projectile_touch_explode;
	missile.think = stdproc_remove;
    missile.nextthink = time + g_balance_rocketlauncher_lifetime;
}

void(void) spawnfunc_shooter_plasma {
	self.use = shooter_plasma_use;
	entity_initialize(self, shooter_setup, INITPRIO_FINDTARGET);
}

void(void) spawnfunc_shooter_rocket {
	self.use = shooter_rocket_use;
	entity_initialize(self, shooter_setup, INITPRIO_FINDTARGET);
}
