
void nadget_GenericProjectile_Stick(entity targ, vector normal);
void nadget_GenericProjectile_Think(void);

float nadget_GenericProjectile_CSQCProjType(float t) {
    switch(t) {
        case NADGET_NAPALM  :   return PROJECTILE_HG_NAPALM;
        case NADGET_PLASMA  :   return PROJECTILE_HG_PLASMA;
        case NADGET_TRANSLOC:   return PROJECTILE_HG_TRANSLOC;
        case NADGET_REMOTE  :   return PROJECTILE_HG_REMOTE;
        case NADGET_LASER   :   return PROJECTILE_HG_LASER;
        case NADGET_RAZE    :   return PROJECTILE_HG_RAZE;
        default         :   return PROJECTILE_HG_GENERIC;
    }
}

void nadget_GenericProjectile_ThrowNapalm(void) {
	float c;
	entity e;
    for(c = 0; c < GRENVAR(self.hg_type, "numparticles"); c++) {
        e = Napalm_Spawn(
            self.owner,
            self.origin,
            GRENVAR(self.hg_type, "fire_lifetime"),
            GRENVAR(self.hg_type, "fire_lifetime_randomfactor"),
            self.projectiledeathtype | HITTYPE_SECONDARY,
            GRENVAR(self.hg_type, "burnradius"),
            GRENVAR(self.hg_type, "burndamage"),
            GRENVAR(self.hg_type, "edgeburndamage"),
            GRENVAR(self.hg_type, "burntime")
        );
            e.owner = self; // don't collide with the GenericProjectile that spawned it
            e.velocity = random_spread_vector(
                GRENVAR(self.hg_type, "spread_xy"),
                GRENVAR(self.hg_type, "spread_z"),
                GRENVAR(self.hg_type, "spread_z_min"),
                GRENVAR(self.hg_type, "spread_z_min_randomfactor")
            );
    }
}

#define GV(v) (GRENVAR(self.hg_type, v))

void nadget_GenericProjectile_RadiusDamage(void) {
    //float p = Buffs_NadgetPower(self.owner);
    float dmgmod = 1;
    float frcmod = 1;
    dmgmod *= pow(GV("damage_bouncemultiplier"), GV("bouncelimit") - self.cnt);
    damage_radius(self, self.owner,
                       GV("damage") * /*p * */ dmgmod,
                       GV("edgedamage") * /*p * */ dmgmod,
                       GV("radius"),
                       world,
                       GV("force") * frcmod,
                       self.projectiledeathtype,
                       other
                );
}

void nadget_GenericProjectile_Explode(void) {
    self.event_damage = NULL;
    self.takedamage = DAMAGE_NO;

    switch(self.hg_type) {
        case NADGET_NAPALM:
        case NADGET_REMOTE:
            nadget_GenericProjectile_ThrowNapalm();
            break;

        case NADGET_PLASMA:
            nadget_Plasma_Explode();
            break;

        case NADGET_TRANSLOC:
            nadget_Transloc_Explode();
            break;
    }

    nadget_GenericProjectile_RadiusDamage();
    nadget_GenericProjectile_Remove();
}

#undef GV

float nadget_GenericProjectile_TryStick(entity targ, vector normal) {
    float doStick;
	doStick = GRENVAR(self.hg_type, "stick");
    if(!doStick || (targ.takedamage == DAMAGE_AIM && doStick < 2) || targ.solid == SOLID_CORPSE)
        return FALSE;

    self.velocity = '0 0 0';

    if(self.hg_type == NADGET_TRANSLOC) {
        // Check if it's ok to teleport in this location
        // by assuming a player-sized bbox and trying to move out of solid.
        // If that fails, remove and refund the translocator

        if(!self.hg_transloc_solidcheck) {
            self.hg_transloc_solidcheck = TRUE;

            vector omins = self.mins;
            vector omaxs = self.maxs;
            vector oorig = self.origin;
            setsize(self, PL_MIN, PL_MAX);

            if(!entity_move_out_of_solid(self)) {
                if(!self.hg_isbonus) NADGET_DO_IN_ALL_CONTEXTS(if(self.owner.hg_ctx_type == NADGET_TRANSLOC)
                    self.owner.hg_ctx_ammo += 1;)

                bprint("^1Couldn't move ", self.owner.netname, "^1's translocator out of solid! Teleport aborted.\n");
                nadget_GenericProjectile_Remove();
                return TRUE;
            }

            setsize(self, omins, omaxs);
            setorigin(self, oorig);
        }
    }

    nadget_GenericProjectile_Stick(targ, normal);
    return TRUE;
}

void nadget_GenericProjectile_Touch(void) {
    PROJECTILE_SKIPNONSOLID
    if(PROJECTILE_OWNER_CHECK())
        return;

    if(trace_ent && trace_ent.solid > SOLID_TRIGGER)
	if (self.movetype != MOVETYPE_FOLLOW && self.movetype != MOVETYPE_NONE)
        projectile_update_next_frame(self);

    if(projectile_no_impact_check()) {
        if(self.hg_type == NADGET_TRANSLOC || self.hg_type == NADGET_RAZE) {
            if(trace_dphitcontents & DPCONTENTS_PLAYERCLIP) {
                projectile_update_next_frame(self);
                goto troll;
            }
        }
        nadget_GenericProjectile_Remove();
        return;
    }

    if(other.classname == "hg_generic_projectile" && other.owner == self.owner)
        return;

    if(other.takedamage == DAMAGE_AIM) {
		vector v = normalize(self.origin - other.origin);
		v_z = trace_plane_normal_z;
        if(nadget_GenericProjectile_TryStick(other, v))
            return;

        if(self.hg_type == NADGET_TRANSLOC && team_mode && other.team == self.owner.team) {
			goto troll;
        } else if(self.hg_type == NADGET_REMOTE) {
            goto troll;
        } else if(self.hg_type == NADGET_PLASMA) {
            self.velocity = '0 0 0';
        }

        self.use();
    } else {
        if(self.hg_type == NADGET_TRANSLOC && cvar("g_nadgets_transloc_bounceresetorigin"))
            self.spawnorigin = self.origin;

        // Check if we should stop bouncing around, then stick or explode if so.
        if(self.cnt <= 0) {
            if(!nadget_GenericProjectile_TryStick(other, trace_plane_normal)) {
                if(self.hg_type == NADGET_PLASMA)
                    self.velocity = '0 0 0';
                self.use();
            }

            return;
        } else if(self.hg_type == NADGET_LASER) {
            nadget_GenericProjectile_RadiusDamage();
        }
:troll
        if(self.hg_type == NADGET_RAZE) {
            if(trace_ent && trace_ent.solid == SOLID_BSP)
                self.movedir = trace_plane_normal;

			float bounce;
            if((bounce = cvar("g_nadgets_raze_bouncefactor")) > 0) {
                vector o = self.origin;
				o_z += cvar("sv_stepheight");
                vector norm = trace_plane_normal;

                trace_box(o, self.mins, self.maxs, o + self.velocity * frametime, TRACE_MOVE_WORLDONLY, self);

                if(trace_fraction < 1 && trace_dphitcontents & DPCONTENTS_SOLID) {
                    trace_plane_normal = norm;
                    float spd = vlen(self.velocity) * bounce;
                    vector dir = normalize(self.velocity);
                    dir = dir - 2 * (dir * trace_plane_normal) * trace_plane_normal;
                    self.velocity = dir * spd;
                    setorigin(self, self.origin + self.velocity * frametime);
                    entity_move_out_of_solid(self);
                }
            }
        }

        if(self.hg_type == NADGET_LASER) {
			sound_spam(self, CHAN_PROJECTILE, RM_SOUND_LASER_SECONDARY, VOL_BASE, ATTN_NORM);
        } else {
            float r;
            r = random() * 6;
            if(r < 1)
                sound_spam(self, CHAN_PROJECTILE, "weapons/grenade_bounce1.wav", VOL_BASE, ATTN_NORM);
            else if(r < 2)
                sound_spam(self, CHAN_PROJECTILE, "weapons/grenade_bounce2.wav", VOL_BASE, ATTN_NORM);
            else if(r < 3)
                sound_spam(self, CHAN_PROJECTILE, "weapons/grenade_bounce3.wav", VOL_BASE, ATTN_NORM);
            else if(r < 4)
                sound_spam(self, CHAN_PROJECTILE, "weapons/grenade_bounce4.wav", VOL_BASE, ATTN_NORM);
            else if(r < 5)
                sound_spam(self, CHAN_PROJECTILE, "weapons/grenade_bounce5.wav", VOL_BASE, ATTN_NORM);
            else
                sound_spam(self, CHAN_PROJECTILE, "weapons/grenade_bounce6.wav", VOL_BASE, ATTN_NORM);
        }

        self.cnt -= 1;
        self.hg_state = TRUE;
    }
}

void nadget_GenericProjectile_Stick(entity targ, vector normal) {
    // TODO: A better, more general fix
    if(targ.classname == "misc_terminal")
        return;

    if(targ.flags & FL_PROJECTILE)
        return;

    entity e = self;
    e.hg_state = TRUE;

    if(e.hg_type == NADGET_TRANSLOC) {
        e.angles = randomvec() * 360;
    } else {
        e.angles = vectoangles(-normal);
    }

    if(e.hg_type == NADGET_PLASMA) {
        vector va = vectoangles(e.hg_lastvel);
        e.angles_x -= 90;
        e.angles_y = va_y - 90;
    }

	if (self.movetype != MOVETYPE_NONE)
	if (self.movetype != MOVETYPE_FOLLOW) { //not already sticked
		sound(self, CHAN_PROJECTILE, "weapons/grenade_stick.wav", 1, ATTN_NORM);
		float lt_override = GRENVAR(e.hg_type, "stick_lifetime_override");
		if(lt_override > 0)
			e.hg_deathtime = time + lt_override;
	}
	projectile_stick(e, targ, e.angles);
    float sz;
	switch(e.hg_type) {
	case NADGET_TRANSLOC: sz = NADGET_SIZE_TRANSLOC; break;
	case NADGET_PLASMA  : sz = NADGET_SIZE_PLASMA_STICK; break;
	default         : sz = NADGET_SIZE_DEFAULT;
    }

    vector hitmins = '-1 -1 -1' * sz;
    vector hitmaxs = ' 1  1  1' * sz;

    setsize(e, hitmins, hitmaxs);

    if(!targ || targ.solid == SOLID_BSP) {
        trace_box(e.origin, e.mins, e.maxs, e.origin - normal * 64, TRACE_MOVE_NOMONSTERS, e);
        if(!trace_startsolid)
            setorigin(e, trace_endpos);
    }

    // For the translocator (face against the wall when teleporting)
    if(normal != '0 0 1')
        e.hg_lastvel = normal;

#if 0
    e.meodp_point_offs = e.meodp_point_offs + normal * sz * 2;
    e.meodp_point_angleoffs = '90 180 0';
#endif

    e.effects |= EFFECT_NODEPTHTEST; // no culling please
    entity_move_out_of_solid(e);
}

void nadget_GenericProjectile_Think(void) {
    #define GV(v) (GRENVAR(self.hg_type, v))
    if(self.velocity != '0 0 0')
        self.hg_lastvel = self.velocity;

    if(self.hg_type == NADGET_RAZE) {
        if(time < (self.hg_spawntime + GV("movement_delay"))){
        }
        else{
            if not(self.hg_raze_randelayed){
                self.movetype = GV("delayed_movetype");
                if(GV("speedscale")){
                    self.velocity = self.hg_minVelocity;
                } else {
                    setorigin(self, self.origin + self.movedir * 5);
                    entity_move_out_of_solid(self);
                    self.velocity = self.hg_deferredVel;
                    sound(self, CHAN_WEAPON2, "porto/bounce.wav", VOL_BASE, ATTN_NORM);
                    pointparticles(particleeffectnum("smoke_ring"), self.origin, -self.velocity, 10);
                }
                self.hg_raze_randelayed = 1;
            }
            else{
                if(GV("speedscale")){
                    float speedscale = (time - self.hg_spawntime) / GV("speedscale_time");
                    speedscale = bound(0, speedscale, 1);
                    vector veldiff = self.hg_maxVelocity - self.hg_minVelocity;
                    veldiff = veldiff * speedscale;
                    if(GV("noverticalvelocity")){
                        self.velocity_x = self.hg_minVelocity_x + veldiff_x;
                        self.velocity_y = self.hg_minVelocity_y + veldiff_y;
                    }
                    else{
                        self.velocity = self.hg_minVelocity + veldiff;
                    }
                }
            }
        }
    }

    nadget_Waypoint();

    if(time >= self.hg_deathtime) {
        if(self.hg_type == NADGET_TRANSLOC && self.health > 0) {
            nadget_GenericProjectile_Remove();
        } else
            self.use();
        return;
    }

    if(self.hg_detonable)
	if(time >= self.hg_detonateready)
	if(!self.hg_detonatetime) {
		if(!self.hg_detonable_updated) {
			self.hg_detonable_updated = TRUE;
			self.owner.hg_detonables += 1;
		}
		if (self.hg_type == NADGET_REMOTE)
		if (clienttype(self.owner) == CLIENTTYPE_BOT) {
			nadget_GenericProjectile_Detonate(self);
		}
	}
    if(self.hg_detonable && self.hg_detonatetime) {
        if(time >= self.hg_detonatetime) {
			self.use();
			return;
        } else if(time >= self.hg_nextsnd) {
			sound(self, CHAN_PROJECTILE, "weapons/rm_nadebeep.wav", VOL_BASE * 0.5, ATTN_NORM * 2);
            self.hg_sndcount += 1;
            self.hg_nextsnd = time + max((self.hg_detonatedelay * 0.3) / (pow(self.hg_sndcount, 1.2)), 0.1);
        }
    }

#if 0
    HealParticleEmitter(self.owner);
#endif

    self.nextthink = time;
    self.hg_ranthink += 1;
    #undef GV
}

float nadget_GenericProjectile_Attack(float hgtype) {
	nadget_GenericProjectile(hgtype, '0 0 0', FALSE);
    return NADGET_ATTACK_OK;
}

void nadget_GenericProjectile_ChangeOwner(entity o) {
    if(!o || o == self.owner)
        return;

    if(self.hg_detonable_updated) {
        self.owner.hg_detonables -= 1;
        o.hg_detonables += 1;
    }

    self.owner = o;
    self.team = o.team;
}

void nadget_GenericProjectile_Damage(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) {
    if(DEATH_ISNADGET(deathtype))
        return;
    if(self.health <= 0)
        return;
    if(!self.hg_state)
        return;
    self.health = self.health - _damage;
    if(self.health <= 0) {
        if(self.hg_type != NADGET_TRANSLOC)
        if(attacker.classname == "player")
            nadget_GenericProjectile_ChangeOwner(attacker);
        self.hg_deathtime = time;
    }
}

void nadget_GenericProjectile_Remove(void) {
    nadget_Waypoint_Remove(self.hg_waypoint);

    sound_stop(self, CHAN_PAIN);

    if(self.hg_detonable_updated && self.owner)
        self.owner.hg_detonables -= 1;

    remove(self);
}

#define GV(v) (GRENVAR(hgtype, v))

entity nadget_GenericProjectile(float hgtype, vector ang, float silent) {
    float hitmask;
	switch(hgtype) {
	case NADGET_RAZE:
		hitmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP;
		break;
	case NADGET_TRANSLOC:
		hitmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
		break;
	default:
		hitmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	}

    makevectors(self.((GV("noverticalvelocity")) ? angles : v_angle));
	if (hgtype == NADGET_LASER)
		sound(self, CHAN_WEAPON, RM_SOUND_LASER_PRIMARY, VOL_BASE, ATTN_NORM);
	else
		sound(self, CHAN_WEAPON, "weapons/grenade_fire.wav", VOL_BASE, ATTN_NORM);

    weapon_setup_shot(self, 4, "", -1);
    pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), weapon_shotorg, weapon_shotdir * 1000, 1);

    vector a = vectoangles(weapon_shotdir);
    a_x = -a_x;
    makevectors(a + ang);
    weapon_shotdir = v_forward;
    entity gren = projectile(hgtype != NADGET_RAZE, nadget_GenericProjectile_CSQCProjType(hgtype), TRUE, self);
	gren.movetype = GV("movetype");
    gren.classname = "hg_generic_projectile";
    gren.bot_dodge = TRUE;
    gren.bot_dodgerating = GV("damage") + 300;
    PROJECTILE_MAKETRIGGER(gren);
    gren.dphitcontentsmask = hitmask;
    gren.projectiledeathtype = hgtype;
    gren.hg_type = hgtype;
    gren.spawnorigin = self.origin;
    gren.hg_spawntime = time;
	gren.hg_detonable = GV("detonable");
	gren.hg_detonatedelay = GV("detonate_delay");
	gren.hg_detonateready = time + GV("detonate_threshold");
	if (gren.movetype == MOVETYPE_TOSS || gren.movetype == MOVETYPE_BOUNCE)
		gren.gravity = GV("gravity");

    setorigin(gren, weapon_shotorg);

    float lt;
    if(hgtype == NADGET_TRANSLOC && self.BUTTON_CROUCH) {
		lt = GV("crouch_lifetime");
    } else
        lt = GV("lifetime");

	gren.cnt = GV("bouncelimit");
    if(self.hg_power == 1 && GV("launch_fullforce_explodes_in_yo_face"))
		gren.hg_deathtime = time + 0.01;
	else
		gren.hg_deathtime = time + lt /* * (if(hgtype == NADGET_TRANSLOC) Buffs_NadgetPower(self) else 1) */;

    gren.think = nadget_GenericProjectile_Think;
    gren.nextthink = time;
    gren.use = nadget_GenericProjectile_Explode;
    gren.touch = nadget_GenericProjectile_Touch;
    gren.reset = nadget_GenericProjectile_Remove;
    gren.team = self.team;
    gren.hg_isbonus = self.hg_bonus;
    if(GV("takedamage") || gren.health) {
        gren.takedamage = DAMAGE_AIM;
        gren.event_damage = nadget_GenericProjectile_Damage;
    } else {
        gren.takedamage = DAMAGE_NO;
        gren.event_damage = NULL;
    }

    if(!gren.health)
        gren.health = GV("health");
    gren.damageforcescale = GV("damageforcescale");

    float spd, mspd, upspd;

    if(hgtype == NADGET_TRANSLOC && self.BUTTON_CROUCH) {
        spd   = GV("crouch_speed");
        mspd  = GV("crouch_speed_min");
        upspd = GV("crouch_speed_up");
    } else {
        spd   = GV("speed");
        mspd  = GV("speed_min");
        upspd = GV("speed_up");
    }

    if(GV("launchspeed")) {
        gren.velocity = weapon_shotdir * (mspd + (spd-mspd) * self.hg_power) + v_up * upspd * self.hg_power;
    } else {
        gren.velocity = weapon_shotdir * spd + v_up * upspd;
    }

    if(GV("delayvelocity")) {
        gren.hg_deferredVel = weapon_shotdir * GV("movement_speed") + v_up * upspd;
    }

    if(GV("speedscale")) {
        gren.hg_minVelocity = weapon_shotdir * GV("speedscale_minspeed") + v_up * upspd;
        gren.hg_maxVelocity = weapon_shotdir * GV("speedscale_maxspeed") + v_up * upspd;
    }

    weapon_setup_projectile_velocity(gren);
    gren.max_health = gren.health;
    gren.angles = vectoangles(gren.velocity);
    gren.hg_nadesused = self.hg_nadesused;
    if(hgtype == NADGET_NAPALM && self.hg_power == 1 && GV("launch_fullforce_explodes_in_yo_face")) {
        damage(self, self, self, GV("kamikaze_damage") /* * Buffs_NadgetPower(self) */, NADGET_NAPALM, self.origin, '0 0 0');
    }

    if(hgtype == NADGET_TRANSLOC) {
        self.hg_transloc_last = gren;
    }

    self.hg_power = 0;
    return gren;
}

#undef GV

void nadget_GenericProjectile_Detonate(entity nade) {
    if(!nade || !nade.hg_detonable || nade.hg_detonatetime || nade.hg_detonateready > time)
        return;

    nade.hg_detonatetime = time + nade.hg_detonatedelay;
    if(nade.hg_detonable_updated && nade.owner) {
        nade.hg_detonable_updated = FALSE;
        nade.owner.hg_detonables -= 1;
    }
}

float nadget_GenericProjectile_DetonateAll(entity plr, float force) {
    float c = 0;
    entity nade, tl = NULL;
    if(!plr.hg_detonables || (!force && PLAYER_REALLY_DEAD(plr)))
        return 0;

    if(!force) for(nade = world; (nade = find(nade, classname, "hg_generic_projectile"));) {
        if(nade.owner == plr && nade.hg_type == NADGET_TRANSLOC) {
            if(!tl || nade.hg_nadesused < tl.hg_nadesused)
                tl = nade;
        }
    }

    if(tl) {
        c = 1;
        nadget_GenericProjectile_Detonate(tl);
    } else for(nade = world; (nade = find(nade, classname, "hg_generic_projectile"));) if(nade.owner == plr) {
        nadget_GenericProjectile_Detonate(nade);
        ++c;
    }

    if(c)
        sound(plr, CHAN_WEAPON2, "weapons/rocket_mode.wav", VOL_BASE, ATTN_NORM);

    return c;
}
