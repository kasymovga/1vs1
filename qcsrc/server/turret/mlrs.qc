void(void) turret_mlrs_postthink {
    // 0 = full, 6 = empty
    self.tur_head.frame = rint(6 - (self.ammo / self.shot_dmg));
}

void(void) turret_mlrs_attack {
	entity missile;
	turret_tag_fire_update();
	sound (self, CHAN_WEAPON, "weapons/rocket_fire.wav", VOL_BASE, ATTN_NORM);
	missile = projectile(TRUE, PROJECTILE_ROCKET, FALSE, self); // no cull, fly sound
	projectile_setup(missile, self.tur_shotorg, EFFECT_IMPACT_ROCKET, WEP_ROCKET_LAUNCHER, self.shot_dmg, self.shot_dmg * 0.5, self.shot_radius, self.owner.shot_force, 0, MOVETYPE_FLY);
	missile.solid = SOLID_BBOX;
	missile.classname          = "mlrs_missile";
	missile.takedamage         = DAMAGE_NO;
	missile.damageforcescale   = 4;
	missile.think              = turret_projectile_think_explode;
	missile.nextthink          = time + max(self.tur_impacttime,(self.shot_radius * 2) / self.shot_speed);
	missile.velocity           = normalize(self.tur_shotdir_updated + randomvec() * self.shot_spread) * self.shot_speed;
	missile.touch              = turret_projectile_touch_explode;
	missile.enemy              = self.enemy;
	te_explosion (missile.origin);
}

/*QUAKED turret_mlrs (0 .5 .8) ?
*/
void(void) spawnfunc_turret_mlrs {
	precache_model("models/turrets/mlrs.md3");
	precache_model("models/turrets/base.md3");
	precache_sound("weapons/rocket_fire.wav");
	if (self.netname == "")
		self.netname  = "MLRS turret";

	self.turrcaps_flags = TFL_TURRCAPS_RADIUSDMG | TFL_TURRCAPS_MEDPROJ | TFL_TURRCAPS_PLAYERKILL;
	self.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
	self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;// | TFL_AIM_GROUND2;
	if (turret_stdproc_init("mlrs_std", "models/turrets/base.md3", "models/turrets/mlrs.md3") == 0) {
		remove(self);
		return;
	}
	self.damage_flags |= TFL_DMG_HEADSHAKE;
	self.shoot_flags |= TFL_SHOOT_VOLLYALWAYS;
	self.volly_counter = self.shot_volly;
	if (!turret_tag_setup())
		print("Warning: Turret ",self.classname, " faild to initialize md3 tags\n");

	// Our fire routine
	self.turret_firefunc = turret_mlrs_attack;
	self.turret_postthink = turret_mlrs_postthink;
}
