void spawnfunc_turret_mlrs();
void turret_mlrs_attack();
void turret_mlrs_rocket_explode();
void turret_mlrs_rocket_touch();

void turret_mlrs_postthink()
{

    // 0 = full, 6 = empty
    self.tur_head.frame = rint(6 - (self.ammo / self.shot_dmg));
}

void turret_mlrs_attack()
{
    entity missile;

    turret_tag_fire_update();

    sound (self, CHAN_WEAPON, "weapons/rocket_fire.wav", VOL_BASE, ATTN_NORM);

    missile                    = projectile(TRUE, PROJECTILE_ROCKET, FALSE, self); // no cull, fly sound
    setorigin(missile, self.tur_shotorg);
    missile.classname          = "mlrs_missile";
    missile.bot_dodge          = TRUE;
    missile.bot_dodgerating    = self.shot_dmg;
    missile.takedamage         = DAMAGE_NO;
    missile.damageforcescale   = 4;
    missile.think              = turret_mlrs_rocket_explode;
    missile.nextthink          = time + max(self.tur_impacttime,(self.shot_radius * 2) / self.shot_speed);
    missile.solid              = SOLID_BBOX;
    missile.movetype           = MOVETYPE_FLYMISSILE;
    missile.velocity           = normalize(self.tur_shotdir_updated + randomvec() * self.shot_spread) * self.shot_speed;
    missile.angles             = vectoangles(missile.velocity);
    missile.touch              = turret_mlrs_rocket_touch;
    missile.solid              = SOLID_BBOX;
    missile.enemy              = self.enemy;
    te_explosion (missile.origin);
}

void turret_mlrs_rocket_touch()
{
    if( (other == self.owner) || (other == self.owner.tur_head) )
        return;

    PROJECTILE_TOUCH;

    turret_mlrs_rocket_explode();
}

void turret_mlrs_rocket_explode()
{
    if(self.event_damage != stdproc_nothing)
    {
        self.event_damage = stdproc_nothing;
        self.think = turret_mlrs_rocket_explode;
        self.nextthink = time;
        return;
    }
    damage_radius (self, self.owner, self.owner.shot_dmg, self.owner.shot_dmg * 0.5, self.owner.shot_radius, world, self.owner.shot_force, WEP_ROCKET_LAUNCHER, world);
    // Target dead, Tell turret.
    if ((self.enemy.deadflag != DEAD_NO) && (self.enemy == self.owner.enemy))
        self.owner.enemy = world;

    remove (self);
}

/*QUAKED turret_mlrs (0 .5 .8) ?
*/

void(void) spawnfunc_turret_mlrs {
	precache_model("models/turrets/mlrs.md3");
	precache_model("models/turrets/base.md3");
	projectile_init(PROJECTILE_ROCKET);
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
