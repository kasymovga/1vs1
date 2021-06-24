void spawnfunc_turret_plasma();
void spawnfunc_turret_plasma_dual();

void turret_plasma_attack();
void turret_plasma_projectile_explode();

void turret_plasma_postthink()
{
    if (self.tur_head.frame != 0)
        self.tur_head.frame = self.tur_head.frame + 1;

    if (self.tur_head.frame > 5)
        self.tur_head.frame = 0;
}

void turret_plasma_dual_postthink()
{
    if ((self.tur_head.frame != 0) && (self.tur_head.frame != 3))
        self.tur_head.frame = self.tur_head.frame + 1;

    if (self.tur_head.frame > 6)
        self.tur_head.frame = 0;
}

void turret_plasma_attack()
{
    entity proj;

    sound (self, CHAN_WEAPON, "weapons/hagar_fire.wav", VOL_BASE, ATTN_NORM);
    pointparticles(particleeffectnum("laser_muzzleflash"), self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);

    proj                    = projectile(TRUE, PROJECTILE_ELECTRO_BEAM, TRUE, self);
    setorigin(proj, self.tur_shotorg);
    proj.classname       = "plasmabomb";
    proj.bot_dodge       = TRUE;
    proj.bot_dodgerating = self.shot_dmg;
    proj.think           = turret_plasma_projectile_explode;
    proj.nextthink       = time + 9;
    proj.solid           = SOLID_BBOX;
    proj.velocity        = normalize(self.tur_shotdir_updated + randomvec() * self.shot_spread) * self.shot_speed;
    proj.touch           = turret_plasma_projectile_explode;
    proj.flags           = FL_PROJECTILE;
    proj.enemy           = self.enemy;
    proj.flags           |= FL_NOTARGET;
    if (self.tur_head.frame == 0)
        self.tur_head.frame = 1;
}

void turret_plasma_dual_attack()
{
    entity proj;

    sound (self, CHAN_WEAPON, "weapons/hagar_fire.wav", VOL_BASE, ATTN_NORM);
    proj                    = projectile(TRUE, PROJECTILE_ELECTRO_BEAM, TRUE, self);
    setorigin(proj, self.tur_shotorg);
    proj.classname       = "plasmabomb";
    proj.bot_dodge       = TRUE;
    proj.bot_dodgerating = self.shot_dmg;
    proj.think           = turret_plasma_projectile_explode;
    proj.nextthink       = time + 9;
    proj.solid           = SOLID_BBOX;
    proj.velocity        = normalize(self.tur_shotdir_updated + randomvec() * self.shot_spread) * self.shot_speed;
    proj.touch           = turret_plasma_projectile_explode;
    proj.flags           = FL_PROJECTILE;
    proj.enemy           = self.enemy;
    proj.flags           |= FL_NOTARGET;
    self.tur_head.frame += 1;
}

void turret_plasma_projectile_explode()
{
    self.event_damage = NULL;
    //w_deathtypestring = "ate to much plasma";
    damage_radius (self, self.owner, self.owner.shot_dmg, 0, self.owner.shot_radius, world, self.owner.shot_force, WEP_ELECTRO, world);
    remove (self);
}

/*
* Basic moderate (std) or fast (dual) fireing, short-mid range energy cannon.
* Not too mutch of a therat on its own, but can be rather dangerous in groups.
* Regenerates ammo slowly, support with a fusionreactor(s) to do some real damage.
*/

/*QUAKED turret_plasma (0 .5 .8) ?
*/
void(void) spawnfunc_turret_plasma {
	precache_model("models/turrets/plasma.md3");
	precache_model("models/turrets/base.md3");
	if (self.netname == "")
		self.netname = "Plasma Cannon";

	// What ammo to use
	self.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIVE;
	// How to aim
	self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE | TFL_AIM_GROUND2;
	self.turrcaps_flags = TFL_TURRCAPS_RADIUSDMG | TFL_TURRCAPS_MEDPROJ | TFL_TURRCAPS_PLAYERKILL | TFL_TURRCAPS_MISSILEKILL;
	if (turret_stdproc_init("plasma_std", "models/turrets/base.md3", "models/turrets/plasma.md3") == 0) {
		remove(self);
		return;
	}
	self.damage_flags	|= TFL_DMG_HEADSHAKE;
	self.firecheck_flags |= TFL_FIRECHECK_AFF;
	if (!turret_tag_setup())
		print("Warning: Turret ",self.classname, " faild to initialize md3 tags\n");

	// Our fireing routine
	self.turret_firefunc  = turret_plasma_attack;
	// Custom per turret frame stuff. usualy animation.
	self.turret_postthink = turret_plasma_postthink;
	turret_do_updates(self);
}

/*QUAKED turret_plasma_dual (0 .5 .8) ?
*/
void(void) spawnfunc_turret_plasma_dual {
	precache_model("models/turrets/plasmad.md3");
	precache_model("models/turrets/base.md3");
	if (self.netname == "")
		self.netname = "Dual Plasma Cannon";

	// What ammo to use
	self.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIVE;
	// How to aim at targets
	self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE  | TFL_AIM_GROUND2 ;
	self.turrcaps_flags = TFL_TURRCAPS_RADIUSDMG | TFL_TURRCAPS_MEDPROJ | TFL_TURRCAPS_PLAYERKILL;
	if (turret_stdproc_init("plasma_dual", "models/turrets/base.md3", "models/turrets/plasmad.md3") == 0) {
		remove(self);
		return;
	}
	self.damage_flags |= TFL_DMG_HEADSHAKE;
	self.firecheck_flags |= TFL_FIRECHECK_AFF;
	if (!turret_tag_setup())
		print("Warning: Turret ", self.classname, " faild to initialize md3 tags\n");

	// Our fireing routine
	self.turret_firefunc  = turret_plasma_dual_attack;
	// Custom per turret frame stuff. usualy animation.
	self.turret_postthink = turret_plasma_dual_postthink;
}
