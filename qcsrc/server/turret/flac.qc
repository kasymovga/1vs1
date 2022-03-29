void spawnfunc_turret_flac();
void turret_flac_attack();
void turret_flac_projectile_explode();

void(void) turret_flac_attack {
	entity proj;
	turret_tag_fire_update();
	sound (self, CHAN_WEAPON, "weapons/hagar_fire.wav", VOL_BASE, ATTN_NORM);
	proj = projectile(TRUE, PROJECTILE_HAGAR, TRUE, self);
	projectile_setup(proj, self.tur_shotorg, WEP_ROCKET_LAUNCHER, self.shot_dmg, self.shot_dmg * 0.5, self.shot_radius, self.owner.shot_force, 0, MOVETYPE_FLY);
	proj.solid = SOLID_BBOX;
	proj.classname          = "flac_projectile";
	proj.takedamage         = DAMAGE_NO;
	proj.velocity           = normalize(self.tur_shotdir_updated + randomvec() * self.shot_spread) * self.shot_speed;
	proj.touch = turret_projectile_touch_explode;
	proj.think = turret_projectile_think_explode;
	proj.nextthink          = time + max(self.tur_impacttime,(self.shot_radius * 3) / self.shot_speed);
	proj.enemy              = self.enemy;
	proj.cnt                = time + 5;
	self.tur_head.frame = self.tur_head.frame + 1;
	if (self.tur_head.frame >= 4) self.tur_head.frame = 0;
}

void(void) spawnfunc_turret_flac {
	precache_model("models/turrets/base.md3");
	precache_model("models/turrets/flac.md3");
	precache_sound("weapons/hagar_fire.wav");
	if (self.netname == "")
		self.netname = "FLAC Cannon";

	self.turrcaps_flags = TFL_TURRCAPS_RADIUSDMG | TFL_TURRCAPS_FASTPROJ | TFL_TURRCAPS_MISSILEKILL;
	self.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
	self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
	if (turret_stdproc_init("flac_std", "models/turrets/base.md3", "models/turrets/flac.md3") == 0) {
		remove(self);
		return;
	}
	setsize(self.tur_head,'-32 -32 0','32 32 64');
	self.damage_flags |= TFL_DMG_HEADSHAKE;
	self.target_select_flags |= (TFL_TARGETSELECT_NOTURRETS | TFL_TARGETSELECT_MISSILESONLY);
	if (!turret_tag_setup())
		print("Warning: Turret ",self.classname, " faild to initialize md3 tags\n");

	// Our fire routine
	self.turret_firefunc  = turret_flac_attack;
}
