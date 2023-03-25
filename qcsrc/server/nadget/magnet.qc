void(void) nadget_magnet_explosion_think {
	if (time > self.cnt) {
		stdproc_remove();
		return;
	}
	float eff;
	if (time > self.attack_finished_single) {
		self.attack_finished_single = time + 0.5;
		eff = EFFECT_IMPACT_HOOKBOOMB;
	} else
		eff = 0;

	damage_radius(self, self.owner, self.dmg, self.dmg_edge, self.dmg_radius, self.owner, self.dmg_force, eff, NADGET_MAGNET | HITTYPE_NOTEAMDAMAGE, world);
	self.nextthink += time + self.delay;
}

void(void) nadget_magnet_explode {
	entity e = spawn();
	setorigin(e, (self.absmin + self.absmax) * 0.5);
	e.nextthink = time;
	e.think = nadget_magnet_explosion_think;
	e.cnt = time + cvar("g_nadgets_magnet_explosion_time");
	e.delay = cvar("g_nadgets_magnet_ticrate");
	e.dmg = cvar("g_nadgets_magnet_damage");
	e.dmg_edge = cvar("g_nadgets_magnet_edgedamage");
	e.dmg_force = cvar("g_nadgets_magnet_force");
	e.dmg_radius = cvar("g_nadgets_magnet_radius");
	e.owner = self.realowner;
	stdproc_remove();
}
