//.float bulletcounter;
void(void) turret_machinegun_attack {
	sound (self, CHAN_WEAPON, "weapons/uzi_fire.wav", VOL_BASE, ATTN_NORM);
	bullet_begin(self.shot_speed, PROJECTILE_BULLET, particleeffectnum("tr_bullet"));
	bullet(self.tur_shotorg, self.tur_shotorg, self.tur_shotdir_updated,self.shot_spread, self.shot_speed, 5, self.shot_dmg, 0, self.shot_force, EFFECT_IMPACT_BULLET, WEAPON_UZI, 1, cvar("g_balance_uzi_bulletconstant"));
	bullet_end();
	//w_deathtypestring = "had an alergic reaction due to 10 kilos of led";
	te_smallflash(self.tur_shotorg);
	// muzzle flash for 3rd person view
	setattachment(weapon_flash_spawn(WEAPON_FLASH_UZI), self.tur_head, "tag_fire");
}

/*QUAKED turret_machinegun (0 .5 .8) ?
* machinegun turret. does what you'd expect
*/
void(void) spawnfunc_turret_machinegun {
	precache_model("models/turrets/machinegun.md3");
	precache_model("models/turrets/base.md3");
	weapon_flash_precache(WEAPON_FLASH_UZI);
	precache_sound("weapons/uzi_fire.wav");
	if (self.netname == "")
		self.netname  = "Machinegun Turret";

	self.ammo_flags = TFL_AMMO_BULLETS | TFL_AMMO_RECHARGE | TFL_AMMO_RECIVE;
	self.turrcaps_flags = TFL_TURRCAPS_PLAYERKILL;
	self.aim_flags = TFL_AIM_LEAD;
	self.turrcaps_flags |= TFL_TURRCAPS_HITSCAN;
	if (turret_stdproc_init("machinegun_std", "models/turrets/base.md3", "models/turrets/machinegun.md3") == 0) {
		remove(self);
		return;
	}
	self.damage_flags |= TFL_DMG_HEADSHAKE;
	if (!turret_tag_setup())
		print("Warning: Turret ",self.classname, " faild to initialize md3 tags\n");

	// Our fire routine
	self.turret_firefunc  = turret_machinegun_attack;
}
