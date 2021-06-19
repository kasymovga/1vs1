
void nadget_Plasma_Shard_Explode(void) {
#if 0
    if(self.meodp_point.enemy) {
        self.realowner = self.meodp_point.enemy;
        self.team = self.meodp_point.enemy.team;
    }
#endif

    self.event_damage = stdproc_nothing;
    self.takedamage = DAMAGE_NO;
    //self.damage_noinfo = FALSE;
#if 0
    float p = Buffs_NadgetPower(self.realowner);
#endif

    damage_radius(self, self.realowner,
        cvar("g_nadgets_plasma_projectile_damage") /* * p */,
        cvar("g_nadgets_plasma_projectile_edgedamage") /* * p */,
        cvar("g_nadgets_plasma_projectile_radius"),
        world,
        cvar("g_nadgets_plasma_projectile_force") /* * p */,
        NADGET_PLASMA | HITTYPE_BOUNCE,
        other
    );

    remove(self);
}

void nadget_Plasma_Shard_Think(void) {
    entity e;
    //float found;

    if(time >= self.hg_detonatetime) {
        nadget_Plasma_Shard_Explode();
        return;
    }

#if 0
    if(self.hg_plasma_projdist) {
        for(e = world; (e = findfloat(e, csqcprojectile_extradata, self.csqcprojectile_extradata));) if(e != self)
            if(e.realowner == self.realowner) if(e.projectiledeathtype == self.projectiledeathtype) {
                WarpZone_FindNearestOrigin(self.origin, e.origin, 0);
                if(WarpZone_FindNearestOrigin_length < self.hg_plasma_projdist) {
                    found = TRUE;
                    break;
                }
            }

        if(!found) {
            nadget_Plasma_Shard_Explode();
            return;
        }
    }
#endif
	float pdmg = self.hg_plasma_projdps * (time - self.hg_plasma_projdps_last);
	self.hg_plasma_projdps_next = time + self.hg_plasma_projdps_delay;
	self.hg_plasma_projdps_last = time;
	vector o = self.origin;
	float f = cvar("g_nadgets_plasma_projectile_force");
	for (e = findradius (o, self.hg_plasma_projrange); e; e = e.chain) {
		if (e == self)
			continue;

		if not(e.takedamage)
			continue;

		trace_line(o, e.origin, MOVE_NOMONSTERS, self);
		if (trace_fraction < 1)
		if (trace_ent != e)
			continue;

		damage(e, self, self.realowner,
				pdmg,
				NADGET_PLASMA | HITTYPE_BOUNCE, trace_endpos,
				'0 0 0');

		effect_lightningarc(o, e.origin);
	}
#if 0
    HealParticleEmitter(self.realowner);
#endif
    self.nextthink = min(self.hg_plasma_projdps_next, self.hg_detonatetime);
}

void nadget_Plasma_Shard_Touch(void) {
    PROJECTILE_TOUCH;
    sound_spam(self, CHAN_PROJECTILE, "weapons/electro_bounce.wav", VOL_BASE, ATTN_NORM);
}

void nadget_Plasma_Shard(float kickangle) {
    entity proj;
    vector kick;

    proj = projectile(TRUE, PROJECTILE_HG_PLASMA_SHARD, FALSE, self);
	proj.gravity = 1;
    proj.classname = "hg_plasma";
    proj.realowner = self.owner;
    proj.team = proj.owner.team;
    proj.use = nadget_Plasma_Shard_Explode;
    proj.think = nadget_Plasma_Shard_Think;
    proj.bot_dodge = TRUE;
    proj.bot_dodgerating = cvar("g_nadgets_plasma_projectile_damage") + 300; // just avoid plasma
    proj.hg_detonatetime = time + cvar("g_nadgets_plasma_projectile_lifetime") + random() * cvar("g_nadgets_plasma_projectile_lifetime_randomfactor");

    PROJECTILE_MAKETRIGGER(proj);
    proj.projectiledeathtype = NADGET_PLASMA | HITTYPE_SECONDARY;
    setorigin(proj, self.origin);

    proj.movetype = MOVETYPE_BOUNCE;

    if(cvar("g_nadgets_plasma_spread_circle")) {
		float side = cvar("g_nadgets_plasma_spread_xy");
		kick = side * v_forward * cos(kickangle) + side * v_right * sin(kickangle) + cvar("g_nadgets_plasma_spread_z_min") * v_up;
    } else {
        kick = random_spread_vector(
            cvar("g_nadgets_plasma_spread_xy"),
            cvar("g_nadgets_plasma_spread_z"),   // FIXME: globals ending with _[xyz] wreak havoc...
            cvar("g_nadgets_plasma_spread_z_min"),
            cvar("g_nadgets_plasma_spread_z_min_randomfactor")
        );
    }

    proj.velocity = kick + self.velocity;
    proj.touch = nadget_Plasma_Shard_Touch;
    proj.takedamage = DAMAGE_NO;
    proj.hg_plasma_projrange = cvar("g_nadgets_plasma_projectile_dps_range");
    proj.hg_plasma_projdps = cvar("g_nadgets_plasma_projectile_dps") /* * Buffs_NadgetPower(self.realowner) */;
    proj.hg_plasma_projdps_delay = cvar("g_nadgets_plasma_projectile_dps_delay");
#if 0
    proj.hg_plasma_projdist = cvar("g_nadgets_plasma_projectile_maxdistance");
    proj.csqcprojectile_extradata = hg_plasma_group & 0xFF;
#endif
    proj.hg_plasma_projdps_next = time + cvar("g_nadgets_plasma_projectile_dps_pause") + random() * cvar("g_nadgets_plasma_projectile_dps_pause_randomfactor");
    proj.hg_plasma_projdps_last = max(time, proj.hg_plasma_projdps_next - proj.hg_plasma_projdps_delay);
    proj.nextthink = min(proj.hg_plasma_projdps_next, proj.hg_detonatetime);
#if 0
    proj.heal_emitter_radius = proj.hg_plasma_projrange;
    proj.damage_noinfo = TRUE;
#endif

    sound(proj, CHAN_WEAPON, "weapons/electro_fire2.wav", VOL_BASE, ATTN_NORM);
}

void nadget_Plasma_Explode(void) {
    float c;

	vector v;
	v = self.hg_lastvel;
	v_z = 0;
    vectorvectors(normalize(v));

    for (c = 0; c < cvar("g_nadgets_plasma_projectile_count"); c ++)
        nadget_Plasma_Shard(2 * MATH_PI * (c / cvar("g_nadgets_plasma_projectile_count")));
}
