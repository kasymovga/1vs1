
void HG_GenericProjectile_Stick(entity targ, vector normal);
void HG_GenericProjectile_Think(void);

float HG_GenericProjectile_CSQCProjType(float t) {
    switch(t) {
        case HG_NAPALM  :   return PROJECTILE_HG_NAPALM;
        case HG_PLASMA  :   return PROJECTILE_HG_PLASMA;
        case HG_TRANSLOC:   return PROJECTILE_HG_TRANSLOC;
        case HG_REMOTE  :   return PROJECTILE_HG_REMOTE;
        case HG_LASER   :   return PROJECTILE_HG_LASER;
        case HG_RAZE    :   return PROJECTILE_HG_RAZE;
        default         :   return PROJECTILE_HG_GENERIC;
    }
}

void HG_GenericProjectile_ThrowNapalm(void) {
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
            //e.jb_proj_ownerstate = self.jb_proj_ownerstate;
            e.velocity = RandomSpreadVector(
                GRENVAR(self.hg_type, "spread_xy"),
                GRENVAR(self.hg_type, "spread_z"),
                GRENVAR(self.hg_type, "spread_z_min"),
                GRENVAR(self.hg_type, "spread_z_min_randomfactor")
            );
    }
}

#define GV(v) (GRENVAR(self.hg_type, v))

void HG_GenericProjectile_RadiusDamage(void) {
    //float p = Buffs_NadgetPower(self.owner);
    float dmgmod = 1;
    float frcmod = 1;

    if(self.hg_adept) {
        if(GV("adept_damagemod")) {
            dmgmod = dmgmod * (1 + (GV("adept_damagemod") - 1) * self.hg_adept);
        }

        if(GV("adept_forcemod")) {
            frcmod = frcmod * (1 + (GV("adept_forcemod")  - 1) * self.hg_adept);
        }
    }

    dmgmod *= pow(GV("damage_bouncemultiplier"), GV("bouncelimit") - self.cnt);

    RadiusDamage(self, self.owner,
                       GV("damage") * /*p * */ dmgmod,
                       GV("edgedamage") * /*p * */ dmgmod,
                       GV("radius"),
                       world,
                       GV("force") * frcmod,
                       self.projectiledeathtype,
                       other
                );
}

void HG_GenericProjectile_Explode(void) {
#if 0
    if(other.takedamage == DAMAGE_AIM)
        if(other.classname == "player")
            if(IsDifferentTeam(self.owner, other))
                if(IsFlying(other))
                    CSQCMessage_Praise(self.owner, CSQCMSG_PRAISEFLAG_AIRSHOT);
#endif

    self.event_damage = SUB_Null;
    self.takedamage = DAMAGE_NO;

    switch(self.hg_type) {
        case HG_NAPALM:
        case HG_REMOTE:
            HG_GenericProjectile_ThrowNapalm();
            break;

        case HG_PLASMA:
            HG_Plasma_Explode();
            break;

        case HG_TRANSLOC:
            HG_Transloc_Explode();
            break;
    }

    HG_GenericProjectile_RadiusDamage();
    HG_GenericProjectile_Remove();
}

#undef GV

float HG_GenericProjectile_TryStick(entity targ, vector normal) {
    float doStick;

    if(self.hg_adept)
        doStick = GRENVAR(self.hg_type, "adept_stick");
    else
        doStick = GRENVAR(self.hg_type, "stick");

    if(!doStick || (targ.takedamage == DAMAGE_AIM && doStick < 2) || targ.solid == SOLID_CORPSE)
        return FALSE;

    self.velocity = '0 0 0';

    if(self.hg_type == HG_TRANSLOC) {
        // Check if it's ok to teleport in this location
        // by assuming a player-sized bbox and trying to move out of solid.
        // If that fails, remove and refund the translocator

        if(!self.hg_transloc_solidcheck) {
            self.hg_transloc_solidcheck = TRUE;

            vector omins = self.mins;
            vector omaxs = self.maxs;
            vector oorig = self.origin;
            setsize(self, PL_MIN, PL_MAX);

            if(!move_out_of_solid(self, MOVE_NOMONSTERS)) {
                if(!self.hg_isbonus) HG_DO_IN_ALL_CONTEXTS(if(self.owner.hg_ctx_type == HG_TRANSLOC)
                    self.owner.hg_ctx_ammo += 1;)

                bprint("^1Couldn't move ", self.owner.netname, "^1's translocator out of solid! Teleport aborted.\n");
                HG_GenericProjectile_Remove();
                return TRUE;
            }

            setsize(self, omins, omaxs);
            setorigin(self, oorig);
        }
    }

    HG_GenericProjectile_Stick(targ, normal);
    return TRUE;
}

void HG_GenericProjectile_Touch(void) {
    PROJECTILE_SKIPNONSOLID
    if(SUB_OwnerCheck())
        return;

    if(trace_ent && trace_ent.solid > SOLID_TRIGGER)
        UpdateCSQCProjectileNextFrame(self);

    if(SUB_NoImpactCheck()) {
        if(self.hg_type == HG_TRANSLOC || self.hg_type == HG_RAZE) {
            if(trace_dphitcontents & DPCONTENTS_PLAYERCLIP)
                goto troll;
            self.use();
            return;
        }
        HG_GenericProjectile_Remove();
        return;
    }

    if(other.classname == "hg_generic_projectile" && other.owner == self.owner)
        return;

    if(other.takedamage == DAMAGE_AIM) {
		vector v = normalize(self.origin - other.origin);
		v_z = trace_plane_normal_z;
        if(HG_GenericProjectile_TryStick(other, v))
            return;

        if(self.hg_type == HG_TRANSLOC && teams_matter && other.team == self.owner.team) {
#if 0
            float adeptRev = (Buffs_Present(self.owner, BUFF_ADEPT) && CVAR(g_nadgets_transloc_adept_revive));

            if(adeptRev || Buffs_Present(self.owner, BUFF_MEDIC)) {
                if(g_freeze && other.frozen) {
                    self.owner.chain = world;
                    Freeze_RevivePlayer(other, self.owner, TRUE);
                    self.hg_tl_revived = TRUE;

                    float m = CVAR(g_nadgets_transloc_medic_revive_health_multiplier);
                    float h = other.health * m;
                    float a = other.armorvalue * m;

                    if(adeptRev)
                        m = max(1.0, m);

                    if(m > 1.0)
                        Heal(other, self, self.owner, other.health - h, other.armorvalue - a, 0, 0, HG_TRANSLOC, 0, 0, self.origin, '0 0 0');
                    else if(m < 1.0) {
                        other.health = h;
                        other.armorvalue = a;
                        other.pauseregen_finished = time + CVAR(g_balance_pause_health_regen);
                    }
                }
            } else
#endif
				goto troll;
        } else if(self.hg_type == HG_REMOTE) {
            goto troll;
        } else if(self.hg_type == HG_PLASMA) {
            self.velocity = '0 0 0';
        }

        self.use();
    } else {
        if(self.hg_type == HG_TRANSLOC && cvar("g_nadgets_transloc_bounceresetorigin"))
            self.spawnorigin = self.origin;

        // Check if we should stop bouncing around, then stick or explode if so.
        if(self.cnt <= 0) {
            if(!HG_GenericProjectile_TryStick(other, trace_plane_normal)) {
                if(self.hg_type == HG_PLASMA)
                    self.velocity = '0 0 0';
                self.use();
            }

            return;
        } else if(self.hg_type == HG_LASER) {
            HG_GenericProjectile_RadiusDamage();
        } else if(self.hg_type == HG_PLASMA && self.hg_adept) {
            float pcount = cvar("g_nadgets_plasma_adept_projectiles_on_bounce");

            if(pcount > 0) {
                vector oldvel = self.velocity;
                self.velocity = '0 0 0';

                ++hg_plasma_group;

				float c;
                for(c = 0; c < pcount; ++c)
                    HG_Plasma_Shard(2 * M_PI * (c / pcount));

                self.velocity = oldvel;
            }
        }

:troll
        if(self.hg_type == HG_RAZE) {
            if(trace_ent && trace_ent.solid == SOLID_BSP)
                self.movedir = trace_plane_normal;

			float bounce;
            if((bounce = cvar("g_nadgets_raze_bouncefactor")) > 0) {
                vector o = self.origin;
				o_z += cvar("sv_stepheight");
                vector norm = trace_plane_normal;

                tracebox(o, self.mins, self.maxs, o + self.velocity * frametime, MOVE_WORLDONLY, self);

                if(trace_fraction < 1 && trace_dphitcontents & DPCONTENTS_SOLID) {
                    trace_plane_normal = norm;
                    float spd = vlen(self.velocity) * bounce;
                    vector dir = normalize(self.velocity);
                    dir = dir - 2 * (dir * trace_plane_normal) * trace_plane_normal;
                    self.velocity = dir * spd;
                    setorigin(self, self.origin + self.velocity * frametime);
                    move_out_of_solid(self, MOVE_NOMONSTERS);
                }
            }
        }

        if(self.hg_type == HG_LASER)
            spamsound(self, CHAN_PROJECTILE, RM_SOUND_LASER_SECONDARY, VOL_BASE, ATTN_NORM);
        else {
            float r;
            r = random() * 6;
            if(r < 1)
                spamsound(self, CHAN_PROJECTILE, "weapons/grenade_bounce1.wav", VOL_BASE, ATTN_NORM);
            else if(r < 2)
                spamsound(self, CHAN_PROJECTILE, "weapons/grenade_bounce2.wav", VOL_BASE, ATTN_NORM);
            else if(r < 3)
                spamsound(self, CHAN_PROJECTILE, "weapons/grenade_bounce3.wav", VOL_BASE, ATTN_NORM);
            else if(r < 4)
                spamsound(self, CHAN_PROJECTILE, "weapons/grenade_bounce4.wav", VOL_BASE, ATTN_NORM);
            else if(r < 5)
                spamsound(self, CHAN_PROJECTILE, "weapons/grenade_bounce5.wav", VOL_BASE, ATTN_NORM);
            else
                spamsound(self, CHAN_PROJECTILE, "weapons/grenade_bounce6.wav", VOL_BASE, ATTN_NORM);
        }

        self.cnt -= 1;
        self.hg_state = TRUE;
    }
}

void HG_GenericProjectile_Stick(entity targ, vector normal) {
    spamsound(self, CHAN_PROJECTILE, "weapons/grenade_stick.wav", 1, ATTN_NORM);

    // TODO: A better, more general fix
    if(targ.classname == "misc_terminal")
        return;

    if(targ.flags & FL_PROJECTILE)
        return;

    entity e = self;
    e.hg_state = TRUE;

    if(e.hg_type == HG_TRANSLOC) {
        e.angles = randomvec() * 360;
    } else {
        e.angles = vectoangles(-normal);
    }

    if(e.hg_type == HG_PLASMA) {
        vector va = vectoangles(e.hg_lastvel);
        e.angles_x -= 90;
        e.angles_y = va_y - 90;
    }

    float lt_override = GRENVAR(e.hg_type, strcat((e.hg_adept ? "adept_" : ""), "stick_lifetime_override"));
    if(lt_override > 0) {
        e.hg_deathtime = time + lt_override;
    }

    if(targ) {
        e.movetype = MOVETYPE_FOLLOW;
        e.view_ofs = e.origin - targ.origin;
        e.aiment = targ;
        e.v_angle = e.angles;
        e.v_angle_y -= targ.angles_y;
        e.punchangle = -targ.angles;
        e.punchangle_y *= -1;
    } else {
        e.movetype = MOVETYPE_NONE;
    }

    float sz;
	switch(e.hg_type) {
	case HG_TRANSLOC: sz = 6; break;
	case HG_PLASMA  : sz = 7; break;
	default         : sz = 5;
    }

    vector hitmins = '-1 -1 -1' * sz;
    vector hitmaxs = ' 1  1  1' * sz;

    setsize(e, hitmins, hitmaxs);

    if(!targ || targ.solid == SOLID_BSP) {
        tracebox(e.origin, e.mins, e.maxs, e.origin - normal * 64, MOVE_NOMONSTERS, e);
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

    e.csqcprojectile_clientanimate = FALSE;
    UpdateCSQCProjectile(e);
    e.SendFlags = 0xFFFFFF;
#if 0
    UpdateCSQCProjectileAngles(e);
#endif
    e.effects |= EF_NODEPTHTEST; // no culling please
    move_out_of_solid(e, MOVE_WORLDONLY);
}

.vector hg_oldangles;

void HG_GenericProjectile_Think(void) {
    #define GV(v) (GRENVAR(self.hg_type, v))

    if(!self.csqcprojectile_clientanimate) {
        vector o = self.oldorigin;

        if(self.origin != self.oldorigin) {
            UpdateCSQCProjectile(self);
            self.oldorigin = self.origin;
        }

        if(self.movetype == MOVETYPE_FOLLOW) {
            if(self.angles != self.hg_oldangles) {
#if 0
                UpdateCSQCProjectileAngles(self);
#endif
                self.hg_oldangles = self.angles;
            }

            if(!self.aiment || wasfreed(self.aiment)) {
                self.aiment = world;
                self.movetype = MOVETYPE_TOSS;
                setorigin(self, o);
                UpdateCSQCProjectile(self);
            }
        }
    }

    if(self.velocity != '0 0 0')
        self.hg_lastvel = self.velocity;

    if(self.hg_type == HG_RAZE) {
        if(time < (self.hg_spawntime + GV("movement_delay"))){
        }
        else{
            if not(self.hg_raze_randelayed){
                self.movetype = GV("delayed_movetype");
                if(GV("speedscale")){
                    self.velocity = self.hg_minVelocity;
                } else {
                    setorigin(self, self.origin + self.movedir * 5);
                    move_out_of_solid(self, MOVE_NOMONSTERS);
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

                if(self.hg_adept && GV("adept_trailblaze") && time > self.hg_fireSpawnTime){
                    HG_GenericProjectile_ThrowNapalm();
                    self.hg_fireSpawnTime = time + GV("fire_spawninterval");
                }
            }
        }
    }

    HG_Waypoint();

    if(time >= self.hg_deathtime) {
        if(self.hg_type == HG_TRANSLOC && self.health > 0) {
            HG_GenericProjectile_Remove();
        } else
            self.use();
        return;
    }

    if(self.hg_detonable)
    if(time >= self.hg_detonateready)
    if(!self.hg_detonatetime)
    if(!self.hg_detonable_updated) {
        self.hg_detonable_updated = TRUE;
        self.owner.hg_detonables += 1;
    }

    if(self.hg_detonable && self.hg_detonatetime) {
        if(time >= self.hg_detonatetime) {
            if(self.hg_type == HG_REMOTE && self.hg_adept) {
                self.hg_adept = 0;
                self.health = self.max_health;
                HG_GenericProjectile_ThrowNapalm();
                HG_GenericProjectile_RadiusDamage();
                self.hg_detonateready = time + GRENVAR(self.hg_type, "adept_detonate_threshold");
                self.hg_detonatetime = 0;
                self.hg_sndcount = 0;
                WaypointSprite_Disown(self.hg_waypoint, 0.5);
            } else {
                self.use();
                return;
            }
        } else if(time >= self.hg_nextsnd) {
            spamsound(self, CHAN_PROJECTILE, "weapons/rm_nadebeep.wav", VOL_BASE * 0.5, ATTN_NORM * 2);
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

float HG_GenericProjectile_Attack(float hgtype) {
#if 0
    if(Buffs_Present(self, BUFF_ADEPT) && (GRENVAR(hgtype, "adept_split") > 0 ||
       (hgtype == HG_LASER && self.hg_detonatepressed))) {
        float split = GRENVAR(hgtype, "adept_split");
        float spread = GRENVAR(hgtype, "adept_split_spread");
        vector dir;
        float i;

        if(!split && hgtype == HG_LASER) {
            split = hg_ammo_used = hg_ammo_available;
        }

        if(split == 1)
            HG_GenericProjectile(hgtype, '0 0 0', FALSE);
        else for(i = 0; i < split; ++i) {
            dir_y = spread * (-0.5 + (i / (split-1)));
            HG_GenericProjectile(hgtype, dir, i);
        }
    } else {
#endif
        HG_GenericProjectile(hgtype, '0 0 0', FALSE);
#if 0
    }
#endif

    return HG_ATTACK_OK;
}

void HG_GenericProjectile_ChangeOwner(entity o) {
    if(!o || o == self.owner)
        return;

    if(self.hg_detonable_updated) {
        self.owner.hg_detonables -= 1;
        o.hg_detonables += 1;
    }

    self.owner = o;
    self.team = o.team;
}

void HG_GenericProjectile_Damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
    if(DEATH_ISHG(deathtype))
        return;
    if(self.health <= 0)
        return;
    if(!self.hg_state)
        return;
    self.health = self.health - damage;
    if(self.health <= 0) {
        if(self.hg_type != HG_TRANSLOC)
        if(attacker.classname == "player")
            HG_GenericProjectile_ChangeOwner(attacker);
        self.hg_deathtime = time;
    }
}

void HG_GenericProjectile_Remove(void) {
    HG_Waypoint_Remove(self.hg_waypoint);

    stopsound(self, CHAN_PAIN);

    if(self.hg_detonable_updated && self.owner)
        self.owner.hg_detonables -= 1;

    remove(self);
}

#if 0
void HG_GenericProjectile_MEODP_Death(entity attacker, entity inflictor) {
    self.takedamage = DAMAGE_AIM;
    self.health = max(10, self.health);
    self.event_damage = HG_GenericProjectile_Damage;
    self.hg_state = 1;
    Damage(self, inflictor, attacker, self.health, DEATH_MEODP, self.meodp_point.origin, '0 0 0');
}
#endif

string HG_GenericProjectile_TypeToAttackSound(float hgtype) {
    switch(hgtype) {
        case HG_LASER:
            return RM_SOUND_LASER_PRIMARY;
        default:
            return "weapons/grenade_fire.wav";
    }
}

#define GV(v) (GRENVAR(hgtype, v))

entity HG_GenericProjectile(float hgtype, vector ang, float silent) {
    vector hitmins, hitmaxs;

    if(hgtype == HG_RAZE) {
        hitmins = '-16 -16 -3';
        hitmaxs = ' 16  16  3';
    } else if(g_nadgets_oldhitboxes) {
        hitmins = '0 0 -3';
        hitmaxs = '0 0 -3';
    } else {
        float sz = ((hgtype == HG_TRANSLOC) ? 8 : 5);
        hitmins = '-1 -1 -1' * sz;
        hitmaxs = ' 1  1  1' * sz;
    }

    float hitmask;
	switch(hgtype) {
	case HG_RAZE:
		hitmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP;
		break;
	case HG_TRANSLOC:
		hitmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
		break;
	default:
		hitmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	}

    makevectors(self.((GV("noverticalvelocity")) ? angles : v_angle));
    //W_SetupShot_ProjectileSize_HitMask(self, hitmins, hitmaxs, FALSE, 4, (silent ? "" : HG_GenericProjectile_TypeToAttackSound(hgtype)), -1, hitmask);
    W_SetupShot_ProjectileSize(self, hitmins, hitmaxs, FALSE, 4, (silent ? "" : HG_GenericProjectile_TypeToAttackSound(hgtype)), -1);
    pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

    vector a = vectoangles(w_shotdir);
    a_x = -a_x;
    makevectors(a + ang);
    w_shotdir = v_forward;

    entity gren = spawn();
    gren.owner = self;
    gren.classname = "hg_generic_projectile";
    gren.bot_dodge = TRUE;
    gren.bot_dodgerating = GV("damage") + 300;
    PROJECTILE_MAKETRIGGER(gren);
    gren.dphitcontentsmask = hitmask;
    gren.projectiledeathtype = hgtype;
    gren.hg_type = hgtype;
    gren.spawnorigin = self.origin;
    gren.hg_spawntime = time;

#if 0
    if(hgtype != HG_NAPALM) {
        gren.hg_adept = Buffs_Present(self, BUFF_ADEPT);
    }
#endif

    if(gren.hg_adept && GV("adept_detonable")) {
        gren.hg_detonable = GV("adept_detonable");
        gren.hg_detonatedelay = GV("adept_detonate_delay");
        gren.hg_detonateready = time + GV("adept_detonate_threshold");
    } else {
        gren.hg_detonable = GV("detonable");
        gren.hg_detonatedelay = GV("detonate_delay");
        gren.hg_detonateready = time + GV("detonate_threshold");
    }

    if(gren.hg_adept && GV("adept_movetype"))
        gren.movetype = GV("adept_movetype");
    else
        gren.movetype = GV("movetype");

    gren.gravity = GV("gravity");
    setsize(gren, hitmins, hitmaxs);
    setorigin(gren, w_shotorg);

    float lt;
    if(hgtype == HG_TRANSLOC && self.BUTTON_CROUCH) {
        if(gren.hg_adept) {
            lt = GV("adept_crouch_lifetime");
            if(!lt)
                lt = GV("crouch_lifetime");
        } else
            lt = GV("crouch_lifetime");
    } else if(gren.hg_adept) {
        lt = GV("adept_lifetime");
        if(!lt)
            lt = GV("lifetime");
#if 0
        else if(hgtype == HG_REMOTE)
            lt = lt * Buffs_NadgetPower(self);
#endif
    } else
        lt = GV("lifetime");

    if(gren.hg_adept)
        gren.cnt = GV("adept_bouncelimit");
    else
        gren.cnt = GV("bouncelimit");

    if(self.hg_power == 1 && GV("launch_fullforce_explodes_in_yo_face"))
		gren.hg_deathtime = time + 0.01;
	else
		gren.hg_deathtime = time + lt /* * (if(hgtype == HG_TRANSLOC) Buffs_NadgetPower(self) else 1) */;

    gren.think = HG_GenericProjectile_Think;
    gren.nextthink = time;
    gren.use = HG_GenericProjectile_Explode;
    gren.touch = HG_GenericProjectile_Touch;
    gren.reset = HG_GenericProjectile_Remove;
    gren.team = self.team;
    gren.hg_isbonus = self.hg_bonus;

    if(gren.hg_adept) {
        gren.health = GV("adept_health");

        if(gren.hg_type == HG_RAZE)
            gren.hg_fireSpawnTime = gren.hg_spawntime + GV("adept_trailblaze_delay");
    }

    if(GV("takedamage") || gren.health) {
        gren.takedamage = DAMAGE_AIM;
        gren.event_damage = HG_GenericProjectile_Damage;
    } else {
        gren.takedamage = DAMAGE_NO;
        gren.event_damage = SUB_Null;
    }

    if(!gren.health)
        gren.health = GV("health");
    gren.damageforcescale = GV("damageforcescale");

    float spd, mspd, upspd;

    if(hgtype == HG_TRANSLOC && self.BUTTON_CROUCH) {
        spd   = GV("crouch_speed");
        mspd  = GV("crouch_speed_min");
        upspd = GV("crouch_speed_up");
    } else {
        spd   = GV("speed");
        mspd  = GV("speed_min");
        upspd = GV("speed_up");
    }

    if(GV("launchspeed")) {
        gren.velocity = w_shotdir * (mspd + (spd-mspd) * self.hg_power) + v_up * upspd * self.hg_power;
    } else {
        gren.velocity = w_shotdir * spd + v_up * upspd;
    }

    if(GV("delayvelocity")) {
        gren.hg_deferredVel = w_shotdir * GV("movement_speed") + v_up * upspd;
    }

    if(GV("speedscale")) {
        gren.hg_minVelocity = w_shotdir * GV("speedscale_minspeed") + v_up * upspd;
        gren.hg_maxVelocity = w_shotdir * GV("speedscale_maxspeed") + v_up * upspd;
    }

    W_SetupProjectileVelocity(gren);

#if 0
    if(!gren.clipgroup)
        gren.clipgroup = CLIPGROUP_PLAYERMASK(self) | hgtype;
#endif

    gren.max_health = gren.health;
    gren.angles = vectoangles(gren.velocity);
    gren.flags = FL_PROJECTILE;
    gren.hg_nadesused = self.hg_nadesused;

#if 0
    Buffs_MEODP_Point_Attach(gren, HG_GenericProjectile_MEODP_Death);
#endif

    CSQCProjectile(gren, hgtype != HG_RAZE, HG_GenericProjectile_CSQCProjType(hgtype), TRUE);

    if(hgtype == HG_NAPALM && self.hg_power == 1 && GV("launch_fullforce_explodes_in_yo_face")) {
        Damage(self, self, self, GV("kamikaze_damage") /* * Buffs_NadgetPower(self) */, HG_NAPALM, self.origin, '0 0 0');
    }

    if(hgtype == HG_TRANSLOC) {
        self.hg_transloc_last = gren;
    }

    self.hg_power = 0;
    return gren;
}

#undef GV

void HG_GenericProjectile_Detonate(entity nade) {
    if(!nade || !nade.hg_detonable || nade.hg_detonatetime || nade.hg_detonateready > time)
        return;

    nade.hg_detonatetime = time + nade.hg_detonatedelay;
    if(nade.hg_detonable_updated && nade.owner) {
        nade.hg_detonable_updated = FALSE;
        nade.owner.hg_detonables -= 1;
    }
}

float HG_GenericProjectile_DetonateAll(entity plr, float force) {
    float c;
    entity nade, tl;

    if(!plr.hg_detonables || (!force && PLAYER_REALLY_DEAD(plr)))
        return 0;

    if(!force) for(nade = world; (nade = find(nade, classname, "hg_generic_projectile"));) {
        if(nade.owner == plr && nade.hg_type == HG_TRANSLOC) {
            if(!tl || nade.hg_nadesused < tl.hg_nadesused)
                tl = nade;
        }
    }

    if(tl) {
        c = 1;
        HG_GenericProjectile_Detonate(tl);
    } else for(nade = world; (nade = find(nade, classname, "hg_generic_projectile"));) if(nade.owner == plr) {
        HG_GenericProjectile_Detonate(nade);
        ++c;
    }

    if(c)
        sound(plr, CHAN_WEAPON2, "weapons/rocket_mode.wav", VOL_BASE, ATTN_NORM);

    return c;
}
