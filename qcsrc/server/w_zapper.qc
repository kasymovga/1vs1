float g_balance_zapper_animtime;
float g_balance_zapper_primary_ammo;
float g_balance_zapper_primary_cooloff;
float g_balance_zapper_primary_cooloff_accel;
float g_balance_zapper_primary_damage;
float g_balance_zapper_primary_damagefalloff_forcehalflife;
float g_balance_zapper_primary_damagefalloff_halflife;
float g_balance_zapper_primary_damagefalloff_maxdist;
float g_balance_zapper_primary_damagefalloff_mindist;
float g_balance_zapper_primary_force;
float g_balance_zapper_primary_heatup;
float g_balance_zapper_primary_lifetime;
float g_balance_zapper_primary_range;
float g_balance_zapper_primary_refire;
float g_balance_zapper_primary_ticrate;
float g_balance_zapper_secondary;
float g_balance_zapper_secondary_accumulate;
float g_balance_zapper_secondary_ammo;
float g_balance_zapper_secondary_arc;
float g_balance_zapper_secondary_arc_force;
float g_balance_zapper_secondary_arc_range;
float g_balance_zapper_secondary_charge_time;
float g_balance_zapper_secondary_damage;
float g_balance_zapper_secondary_damagefalloff_forcehalflife;
float g_balance_zapper_secondary_damagefalloff_halflife;
float g_balance_zapper_secondary_damagefalloff_maxdist;
float g_balance_zapper_secondary_damagefalloff_mindist;
float g_balance_zapper_secondary_force;
float g_balance_zapper_secondary_shield;
float g_balance_zapper_secondary_shield_ammo;
float g_balance_zapper_secondary_shield_heatup;
float g_balance_zapper_secondary_shield_lifetime;
float g_balance_zapper_secondary_shield_refire;
float g_balance_zapper_secondary_range;
float g_balance_zapper_secondary_refire;
var .float zapper_buttonatck1 = BUTTON_ATCK;
var .float zapper_buttonatck2 = BUTTON_ATCK2;

.entity zapper_shield;
.entity zapper_accumulator;
.entity zapper_spinner;
.entity zapper_beam;

.float zapper_range;
.float zapper_expire;
.float zapper_lastdmg;
.float zapper_dmgdelay;
.float zapper_arc_hit;
.float zapper_heat;
.float zapper_coolofftime;
.float zapper_accumulate;
.float zapper_shieldready; // for g_balance_zapper_shield 2

.vector zapper_beam_start, zapper_beam_end;

vector W_Zapper_BeamRGB(float t) {
    switch(t) {
        case COLOR_TEAM1:            return '5.0   1.0   0.5';
        case COLOR_TEAM2: default:   return '0.5   1.0   5.0';
        case COLOR_TEAM3:            return '4.0   2.5   0.5';
        case COLOR_TEAM4:            return '5.0   0.7   3.0';
    }
}

.vector glowmod;
void W_Zapper_SpawnSpinner_Think() {
	if(self.owner.weapon != WEP_ZAPPER) {
		self.owner.zapper_spinner = world;
		remove(self);
		return;
	}

	if(self.owner.zapper_beam || self.owner.zapper_shield)
		self.cnt = approach(self.cnt, 3, 4 * frametime);
	else
		self.cnt = approach(self.cnt, -0.1, 2 * frametime);

	float intens = self.cnt / 3;

	if(intens <= 0) {
		self.glowmod = '-1 -1 -1';
		self.skin = 0;
	} else {
		self.skin = 1;
		self.glowmod = self.color * pow(intens, 2);
	}

	self.angles_z = self.angles_z + frametime * self.cnt * 360;
	self.nextthink = time;
}

float W_Zapper_Spinner_CustomizeEntityForClient() {
	if (other.gameclient == CLIENT_OLDNEXUIZ)
		self.effects |= EF_NODRAW;
	else
		self.effects &~= EF_NODRAW;

	return CL_Weaponentity_CustomizeEntityForClient();
}

void W_Zapper_SpawnSpinner(void) {
    if (self.zapper_spinner)
        return;

	if (self.weaponentity.cnt != self.weapon)
		return;

    entity o = Akimbo_Owner(self);

    entity s = spawn();
	s.classname = "zapper_spinner";
	s.model = "models/weapons/rtzapper_hyperhonker.iqm";
	s.owner = self;
	s.viewmodelforclient = o;
	s.colormap = self.colormap;
	s.color = W_Zapper_BeamRGB((teamplay ? self.team : COLOR_TEAM2));
	s.think = W_Zapper_SpawnSpinner_Think;
	s.nextthink = time;
	s.customizeentityforclient = W_Zapper_Spinner_CustomizeEntityForClient;

    setattachment(s, self.weaponentity, "shot");

    setorigin(s, '-4 0 -0.5');
    setmodel(s, s.model);

    self.zapper_spinner = s;
}

float W_Zapper_Attack1_CheckAmmo(entity p) {
    return p.ammo_cells >= g_balance_zapper_primary_ammo;
}

float W_Zapper_Attack2_CheckAmmo(entity p) {
    if(g_balance_zapper_secondary_shield)
        return p.ammo_cells >= 1;

    return p.ammo_cells >= g_balance_zapper_secondary_ammo;
}

float W_Zapper_Beam_Send(entity to, float sf) {
    sf &~= 24;

    float o = num_for_edict(self.owner);

    if(o > maxclients) {
        o = 0;
	}

    if(!o) {
        sf |= 16;
    }

    if(self.classname == "zapper_shield_beam")
        WriteByte(MSG_ENTITY, ENT_CLIENT_ZAPPER_SHIELD);
    else {
        WriteByte(MSG_ENTITY, ENT_CLIENT_ZAPPER);
		if (Akimbo_Active(self.owner)) {
			sf |= 8;
		}
	}


    WriteByte(MSG_ENTITY, sf);

    if(sf & 1) {
        if(o)
            WriteByte(MSG_ENTITY, o);
        else
            WriteByte(MSG_ENTITY, self.team);
    }

    if(sf & 2) {
        WriteCoord(MSG_ENTITY, self.zapper_beam_start_x);
        WriteCoord(MSG_ENTITY, self.zapper_beam_start_y);
        WriteCoord(MSG_ENTITY, self.zapper_beam_start_z);
    }

    if(sf & 4) {
        WriteCoord(MSG_ENTITY, self.zapper_beam_end_x);
        WriteCoord(MSG_ENTITY, self.zapper_beam_end_y);
        WriteCoord(MSG_ENTITY, self.zapper_beam_end_z);
    }

    if(sf & 32) {
		entity e = self.enemy.weaponentity;
        WriteCoord(MSG_ENTITY, e.shotorg_visual_x);
        WriteCoord(MSG_ENTITY, -e.shotorg_visual_y);
        WriteCoord(MSG_ENTITY, e.shotorg_visual_z);
    }

    return TRUE;
}

float W_Zapper_Beam_Expired(float secondary) {
    entity o = self.owner;

	if(self.zapper_expire)
    if(time > self.zapper_expire)
        return TRUE;

    if(self.owner.zapper_heat >= 1)
        return TRUE;

    if(self.owner.weapon != WEP_ZAPPER)
        return TRUE;

    if(!PlayerCanFire(o, TRUE))
        return TRUE;

	if not(o.items & IT_UNLIMITED_WEAPON_AMMO) {
		if(secondary) {
			if(o.ammo_cells < 1)
				return TRUE;
		} else {
			if(!W_Zapper_Attack1_CheckAmmo(o))
				return TRUE;
			if(o.zapper_shield)
				return TRUE;
		}
	}

    return FALSE;
}

vector W_Zapper_GetVisualShootOrg(entity o) {
	float n = gettagindex(o.exteriorweaponentity, "_");
    vector org = gettaginfo(o.exteriorweaponentity, n);
	return org + v_forward * 30 + v_up * 3;
}

void W_Zapper_Beam_Think(void) {
    if(W_Zapper_Beam_Expired(FALSE)) {
        if(self.enemy.zapper_beam == self)
            self.enemy.zapper_beam = world;
        remove(self);
        return;
    }
	vector org = W_Zapper_GetVisualShootOrg(self.enemy);

    makevectors(self.owner.v_angle);
    W_SetupShot(self.enemy, FALSE, 0, "", 0);

    float fract;
    entity targ;
    vector end = w_shotorg + w_shotdir * self.zapper_range;
    entity o = self.owner;

    //ExactHitscan_Begin();
    traceline_antilag(o, w_shotorg, end, FALSE, o, ANTILAG_LATENCY(o));
    //ExactHitscan_End();

    targ = trace_ent;
    end = trace_endpos;
    fract = trace_fraction;

    float dt = time - self.zapper_lastdmg;
    float rate = W_WeaponRateFactorFor(o);
    float damageIsDps = FALSE;

    if(dt < frametime)
    if(almost_equals(dt, frametime))
        dt = frametime;

    float wantedTicrate = self.zapper_dmgdelay * rate;

    if(wantedTicrate <= 0) {
        wantedTicrate = dt;
        damageIsDps = TRUE;
    }
	vector forcedir = WarpZone_TransformVelocity(WarpZone_trace_transform, w_shotdir);
    for ( ;dt >= wantedTicrate; dt -= wantedTicrate) {
        float damage = g_balance_zapper_primary_damage;
        float force  = g_balance_zapper_primary_force;
		o.bullets_fired[WEP_ZAPPER] += 1;
		o.maxdamage_fired = WEP_ZAPPER + 64 * rint(o.bullets_fired[WEP_ZAPPER]);
        if(damageIsDps) {
            damage = damage * wantedTicrate;
            force = force * wantedTicrate;
        }
        if(targ.takedamage) {
            float d = vlen(end - w_shotorg) * fract;

            float mindist = g_balance_zapper_primary_damagefalloff_mindist;
            float maxdist = g_balance_zapper_primary_damagefalloff_maxdist;
            float halflifedist = g_balance_zapper_primary_damagefalloff_halflife;
            float forcehalflifedist = g_balance_zapper_primary_damagefalloff_forcehalflife;

            damage *= ExponentialFalloff(mindist, maxdist, halflifedist, d);
            force  *= ExponentialFalloff(mindist, maxdist, forcehalflifedist, d);

            Damage(targ, self, o, damage, WEP_ZAPPER, end, force * forcedir);
			if not(inWarmupStage)
			if not(targ.deadflag)
			if (!teamplay || targ.team != o.team) {
				o.bullets_hit[WEP_ZAPPER] += 1;
				o.damage_hits = WEP_ZAPPER + 64 * rint(o.bullets_hit[WEP_ZAPPER]);
			}
        }
        if(fract < 1)
        if(targ.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
            Damage_DamageInfo(end, damage, 0, 0, force * forcedir, WEP_ZAPPER, self);

        if not(self.enemy.items & IT_UNLIMITED_AMMO)
            self.enemy.ammo_cells = self.enemy.ammo_cells - g_balance_zapper_primary_ammo;

        self.zapper_lastdmg = self.zapper_lastdmg + wantedTicrate;
    }

	//vector org = w_shotorg_visual;

    if(org != self.zapper_beam_start) {
        self.SendFlags |= 2;
        self.zapper_beam_start = org;
    }

    vector nowarp_end = WarpZone_UnTransformOrigin(WarpZone_trace_transform, end);
    if(nowarp_end != self.zapper_beam_end) {
        self.SendFlags |= 4;
        self.zapper_beam_end = nowarp_end;
    }

    if(self.enemy.zapper_heat >= 0) {
        self.enemy.zapper_heat = bound(0, self.enemy.zapper_heat + (g_balance_zapper_primary_heatup * frametime) / rate, 1);
        self.enemy.zapper_coolofftime = time + frametime;
    }

	ATTACK_FINISHED(self.enemy) = time + g_balance_zapper_primary_refire * rate;

    self.nextthink = time;
}

void W_Zapper_Attack1(void) {
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
    if(!W_Zapper_Attack1_CheckAmmo(self))
        return;

    sound(self, CHAN_WEAPON, "weapons/zapper_fire.wav", VOL_BASE, ATTN_NORM);

    entity e = spawn();
    e.classname = "zapper_beam";
    e.think = W_Zapper_Beam_Think;
    e.owner = Akimbo_Owner(self);
    e.enemy = self;

    e.zapper_range = g_balance_zapper_primary_range;
    e.zapper_expire = time + g_balance_zapper_primary_lifetime;
    e.zapper_dmgdelay = g_balance_zapper_primary_ticrate;
    e.zapper_lastdmg = time - e.zapper_dmgdelay * W_WeaponRateFactor();

    Net_LinkEntity(e, FALSE, 0, W_Zapper_Beam_Send);

    self.zapper_beam = e;
	entity oldself = self;
    self = e;
	self.think();
	self = oldself;
	e.nextthink = time;
}

float W_Zapper_Attack2_Effect_team;
void W_Zapper_Attack2_Effect_cb(vector from, vector to, vector end) {
    WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte(MSG_BROADCAST, TE_CSQC_ZAPPERLIGHTNING);

    WriteByte(MSG_BROADCAST, W_Zapper_Attack2_Effect_team);
    WriteCoord(MSG_BROADCAST, from_x);
    WriteCoord(MSG_BROADCAST, from_y);
    WriteCoord(MSG_BROADCAST, from_z);
    WriteCoord(MSG_BROADCAST, to_x);
    WriteCoord(MSG_BROADCAST, to_y);
    WriteCoord(MSG_BROADCAST, to_z);
}

void W_Zapper_Attack2_Effect(float ateam, vector from, vector to) {
	W_Zapper_Attack2_Effect_team = ateam;
	WarpZone_DrawEffectTriangle(from, from, to, W_Zapper_Attack2_Effect_cb);
}

void W_Zapper_Attack2_Arc(entity targ, entity attacker, float damage) {
    float arc = g_balance_zapper_secondary_arc;

    if(arc <= 0)
        return;

    ArcDamage(targ, attacker, damage, WEP_ZAPPER | HITTYPE_SECONDARY | HITTYPE_BOUNCE,
        g_balance_zapper_secondary_arc_range, arc,
        g_balance_zapper_secondary_arc_force, COLOR_TEAM2, zapper_arc_hit
    );
}

void W_Zapper_Attack2(void) {
    float accum_time = g_balance_zapper_secondary_accumulate;
    float charge_time;
    if (accum_time) {
        charge_time = g_balance_zapper_secondary_charge_time;
        if (!charge_time)
            charge_time = accum_time;
    }

    float accum  = (accum_time ? (min(1, (time - self.zapper_accumulate) * W_WeaponRateFactorFor(self.owner) / charge_time)) : 1);
    float damage = g_balance_zapper_secondary_damage * accum;
    float force  = g_balance_zapper_secondary_force * accum;
    float range  = g_balance_zapper_secondary_range * accum;

    makevectors(self.v_angle);
    W_SetupShot(self, TRUE, 5, strcat("misc/arc", ftos(1 + (random() > 0.5)), ".wav"), 0);

    entity targ;
    vector end = w_shotorg + w_shotdir * range;
    //entity pts = Buffs_MEODP_Hitscan_Begin(self);

    //ExactHitscan_Begin();
    traceline_antilag(self, w_shotorg, end, FALSE, self, ANTILAG_LATENCY(self));
    //ExactHitscan_End();

    targ = trace_ent;
    end = trace_endpos;

    //W_SetHitscanVisuals(self, end);

    //vector end_visual = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	vector forcedir = WarpZone_TransformVelocity(WarpZone_trace_transform, w_shotdir);

    if(targ.takedamage) {
        float d = vlen(end - w_shotorg) * trace_fraction;

        float mindist = g_balance_zapper_secondary_damagefalloff_mindist;
        float maxdist = g_balance_zapper_secondary_damagefalloff_maxdist;
        float halflifedist = g_balance_zapper_secondary_damagefalloff_halflife;
        float forcehalflifedist = g_balance_zapper_secondary_damagefalloff_forcehalflife;

        damage *= ExponentialFalloff(mindist, maxdist, halflifedist, d);
        force  *= ExponentialFalloff(mindist, maxdist, forcehalflifedist, d);

        if(targ.iscreature)
            W_Zapper_Attack2_Arc(targ, self, damage);

		entity o = Akimbo_Owner(self);
        Damage(targ, o, o, damage, WEP_ZAPPER | HITTYPE_SECONDARY, end, force * forcedir);
		if not(inWarmupStage)
		if (!teamplay || targ.team != o.team) {
			o.bullets_hit[WEP_ZAPPER] += 1;
			o.damage_hits = WEP_ZAPPER + 64 * rint(o.bullets_hit[WEP_ZAPPER]);
		}
    }

    //Buffs_MEODP_Hitscan_End(pts);

    //W_Accuracy_RegisterShot(self, self.weapon);
    //W_Accuracy_RegisterHit(self, targ, self.weapon);

	W_Zapper_Attack2_Effect_team = self.team;
	WarpZone_DrawEffectTriangle(w_shotorg, w_shotorg_visual, WarpZone_UnTransformOrigin(WarpZone_trace_transform, end), W_Zapper_Attack2_Effect_cb);

    if(targ.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
        Damage_DamageInfo(end, damage, 0, 0, force * forcedir, WEP_ZAPPER | HITTYPE_SECONDARY, self);

    if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
        self.ammo_cells = self.ammo_cells - g_balance_zapper_secondary_ammo;
}

void W_Zapper_Shield_Beam_Think(void) {
    if(self.enemy.zapper_shield != self.zapper_shield) {
        remove(self);
        return;
    }
    entity o = self.owner;

	vector end;
#if 0
    W_SetupShot(self, TRUE, 5, "", 0);
	vector org = w_shotorg_visual;
#endif
    vector org = W_Zapper_GetVisualShootOrg(self.enemy);
	makevectors(self.owner.angles);

    end = org + v_forward * 7;
    traceline(org, end, FALSE, o);
    end = trace_endpos;

    if(org != self.zapper_beam_start) {
        self.SendFlags |= 2;
        self.zapper_beam_start = org;
    }

    if(end != self.zapper_beam_end) {
        self.SendFlags |= 4;
        self.zapper_beam_end = end;
    }

    self.nextthink = time;
}

void W_Zapper_Shield_Think(void) {
    if(W_Zapper_Beam_Expired(TRUE) || !self.owner.zapper_shield) {
        if(self.owner.zapper_shield == self)
            self.owner.zapper_shield = world;

        remove(self);
        return;
    } else {
        self.alpha = approach(self.alpha, 1, frametime * 10);
		if not(self.owner.items & IT_UNLIMITED_AMMO)
			self.owner.ammo_cells = max(0, self.owner.ammo_cells - frametime * g_balance_zapper_secondary_shield_ammo);

		if(self.owner.zapper_heat >= 0) {
			self.owner.zapper_heat = bound(0, self.owner.zapper_heat + (g_balance_zapper_secondary_shield_heatup * frametime), 1);
			self.owner.zapper_coolofftime = time + frametime;
		}

		ATTACK_FINISHED(self.owner) = self.owner.zapper_shieldready = time + g_balance_zapper_secondary_shield_refire * W_WeaponRateFactorFor(self.owner);
    }

    self.nextthink = time;
}

void W_Zapper_Shield_Blocker_Push(entity p) {
    if(normalize(p.origin - self.oldorigin) * v_forward < 0.5)
        return;

    if(vlen(p.origin - self.oldorigin) <= 90) {
        float v = max(600, vlen(p.velocity));
        p.velocity = normalize(p.origin - self.oldorigin) * v;
        UpdateCSQCProjectile(p);
    }
}

void W_Zapper_Shield_Blocker_Think(void) {
    if(self.owner.zapper_shield != self.zapper_shield) {
        remove(self);
        return;
    }

    entity e;
    vector o = self.owner.origin + self.owner.view_ofs;
    vector a = self.owner.angles;
    self.oldorigin = o;

    makevectors(a);
    self.angles = a;
    setorigin(self, o - v_forward * 85);
    FOR_EACH_PLAYER(e) if(e != self.owner)
        W_Zapper_Shield_Blocker_Push(e);

    for(e = findchainflags(flags, FL_PROJECTILE); e; e = e.chain)
        if(e.classname != "bullet")
            W_Zapper_Shield_Blocker_Push(e);

    self.nextthink = time;
}

void W_Zapper_FixShieldBlockerOrigin(entity plr) {
    if(!plr.zapper_shield.zapper_shield)
        return;

    vector fwd = v_forward, up = v_up, right = v_right;

    makevectors(plr.angles);
    plr.zapper_shield.zapper_shield.angles = plr.angles;
    setorigin(plr.zapper_shield.zapper_shield, plr.origin + plr.view_ofs - v_forward * 85);

    v_forward = fwd;
    v_up = up;
    v_right = right;
}

void W_Zapper_Attack3(void) {
    entity e = spawn();
    e.classname = "zapper_shield";
    setmodel(e, "models/vhshield.md3");
    e.think = W_Zapper_Shield_Think;
	e.owner = self;
    e.nextthink = time;
    e.alpha = 0.01;

	e.skin = 0;
    if(teamplay)
        e.skin = TeamColorSkin(self.team);
    if(!e.skin)
        e.skin = TeamColorSkin(COLOR_TEAM2);

    // This copies the entity! e becomes a viewmodel, the copy is attached to shotorg.
    W_AttachToShotorg(e, '-120 0 0');

    // needs to be done AFTER W_AttachToShotorg
    //e.customizeentityforclient = W_Zapper_Shield_CustomizeEntityForClient;

    self.zapper_shield = e;

    sound(self, CHAN_WEAPON, "weapons/zapper_fire.wav", VOL_BASE, ATTN_NORM);

    entity b = spawn();
    b.classname = "zapper_shield_beam";
    b.think = W_Zapper_Shield_Beam_Think;
    b.nextthink = time;
	b.enemy = self;
    b.owner = Akimbo_Owner(self);
    b.zapper_shield = e;

    Net_LinkEntity(b, FALSE, 0, W_Zapper_Beam_Send);

    e.zapper_beam = b;

    b = spawn();
    b.classname = "zapper_shield_blocker";
    b.owner = Akimbo_Owner(self);
    b.think = W_Zapper_Shield_Blocker_Think;
    b.zapper_shield = e;
    b.nextthink = time;
    b.solid = SOLID_BSP;
    b.alpha = -1;
    setmodel(b, "models/vhshield.md3");

    e.zapper_shield = b;
}

void W_Zapper_Cooloff(void) {
    if(self.zapper_heat < 0)
        return;

    float a = bound(0, (time - self.zapper_coolofftime) * g_balance_zapper_primary_cooloff_accel, 1);

    if(!a)
        return;

    self.zapper_heat = bound(0, self.zapper_heat - g_balance_zapper_primary_cooloff * frametime * a, 1);
}

#if 0
float W_Zapper_PrepareFirstAttack(float sec) {
    if(self.weaponentity.state == WS_INUSE)
        self.weaponentity.state = WS_READY;

    return weapon_prepareattack(sec, 0);
}
#endif

void W_Zapper_Accumulate(void) {

    setorigin(self, self.owner.origin);
    self.nextthink = time;
    self = self.owner;
    float accumulate_end = 1;
    if (PlayerCanFire(self, TRUE) && self.weapon == WEP_ZAPPER) {
        if (self.zapper_accumulator.zapper_expire < time &&
               (!self.zapper_buttonatck2
               || self.zapper_buttonatck1
               || time > self.zapper_accumulator.zapper_accumulate)) {
            W_Zapper_Attack2();
            weapon_thinkf(WFRAME_FIRE2, g_balance_zapper_animtime, w_ready);
        } else
            accumulate_end = 0;
    }
    if (accumulate_end) {
        stopsound(self, CHAN_WEAPON2);
        remove(self.zapper_accumulator);
        self.zapper_accumulator = world;
    }
}


float w_zapper(float req) {
    float dofire;

    if (req == WR_AIM) {
        if(vlen(self.origin-self.enemy.origin) < g_balance_zapper_primary_range)
            self.zapper_buttonatck1 = bot_aim(1000000, 0, 0.001, FALSE);
        else
            self.zapper_buttonatck2 = bot_aim(1000000, 0, 0.001, FALSE);
    } else if(req == WR_THINK) {
        W_Zapper_SpawnSpinner();
		W_Zapper_Cooloff();

        if(self.zapper_buttonatck1) {
            if (self.zapper_buttonatck2 && g_balance_zapper_secondary_shield == 2) {
                if(weapon_prepareattack(1, -1)) {
                    if(self.zapper_heat >= 1 && g_balance_zapper_secondary_shield_heatup) {
                        //W_SwitchWeapon_OutOfAmmo(self);
                    } else {
                        if(self.zapper_shield) {
                            dofire = TRUE;
                            self.zapper_shield.zapper_expire = time + g_balance_zapper_secondary_shield_lifetime;
                        } else if(time > self.zapper_shieldready) {
                            dofire = TRUE;
                            W_Zapper_Attack3();
                        }

                        if(dofire)
                            weapon_thinkf(WFRAME_FIRE1, g_balance_zapper_animtime, w_ready);
                    }
                }
           } else if(weapon_prepareattack(0, -1)) {
                if(self.zapper_heat >= 1 && g_balance_zapper_primary_heatup) {
                    //W_SwitchWeapon_OutOfAmmo(self);
                } else {
                    if(self.zapper_beam) {
                        dofire = TRUE;
                        self.zapper_beam.zapper_expire = time + g_balance_zapper_primary_lifetime;
                    } else {
                        dofire = TRUE;
                        W_Zapper_Attack1();
                    }

                    if(dofire)
                        weapon_thinkf(WFRAME_FIRE1, g_balance_zapper_animtime, w_ready);
                }
            }
        } else if(self.zapper_buttonatck2 && g_balance_zapper_secondary) {
            if(g_balance_zapper_secondary_shield == 1) {
                if(weapon_prepareattack(1, -1)) {
                    if(self.zapper_heat >= 1 && g_balance_zapper_secondary_shield_heatup) {
                        //W_SwitchWeapon_OutOfAmmo(self);
                    } else {
                        if(self.zapper_shield) {
                            dofire = TRUE;
                            self.zapper_shield.zapper_expire = time + g_balance_zapper_secondary_shield_lifetime;
                        } else {
                            dofire = TRUE;
                            W_Zapper_Attack3();
                        }

                        if(dofire)
                            weapon_thinkf(WFRAME_FIRE1, g_balance_zapper_animtime, w_ready);
                    }
                }
            } else if(g_balance_zapper_secondary_accumulate) {
                if (!self.zapper_accumulator && weapon_prepareattack(1, g_balance_zapper_secondary_refire)) {
                    self.zapper_accumulate = time; //Accumulate start time
                    self.zapper_accumulator = spawn();
                    self.zapper_accumulator.zapper_accumulate = time + g_balance_zapper_secondary_accumulate; //Accumulate end time
                    self.zapper_accumulator.owner = self;
                    self.zapper_accumulator.think = W_Zapper_Accumulate;
                    self.zapper_accumulator.nextthink = time;
                    self.zapper_accumulator.zapper_expire = time + g_balance_zapper_animtime;
                    sound(self, CHAN_WEAPON2, "weapons/fireball_fly2.wav", VOL_BASE, ATTN_NORM);
                    weapon_thinkf(WFRAME_FIRE1, g_balance_zapper_animtime, w_ready);
                }
            } else if(weapon_prepareattack(1, g_balance_zapper_secondary_refire)) {
                W_Zapper_Attack2();
                weapon_thinkf(WFRAME_FIRE1, g_balance_zapper_animtime, w_ready);
            }
        }
    } else if(req == WR_PRECACHE) {
        precache_model("models/vhshield.md3");
        precache_model("models/weapons/rtzapper_hyperhonker.iqm");
        precache_sound("weapons/zapper_fire.wav");
        precache_sound("weapons/zapper_fly.wav");
        precache_sound("weapons/fireball_fly2.wav");
        precache_sound("misc/arc1.wav");
        precache_sound("misc/arc2.wav");
		dlc_require("rm_effects_v2");
		dlc_require("pryaxe_balls");
		dlc_require("rm_arc");
		dlc_require("zapper_v1");
    } else if(req == WR_RESETPLAYER){
        if(g_balance_zapper_primary_heatup || (g_balance_zapper_secondary_shield && g_balance_zapper_secondary_shield_heatup))
            self.zapper_heat = 0;
        else
            self.zapper_heat = -1;
    } else if(req == WR_SETUP) {
        weapon_setup(WEP_ZAPPER);
    } else if(req == WR_CLEAR) {
        if(self.zapper_spinner) {
            remove(self.zapper_spinner);
            self.zapper_spinner = world;
        }
    } else if(req == WR_CHECKAMMO1)
        return W_Zapper_Attack1_CheckAmmo(self);
    else if(req == WR_CHECKAMMO2)
        return W_Zapper_Attack2_CheckAmmo(self);
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = "was zapped by";
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_zapper_animtime);
		CACHE_CVAR(g_balance_zapper_primary_ammo);
		CACHE_CVAR(g_balance_zapper_primary_cooloff);
		CACHE_CVAR(g_balance_zapper_primary_cooloff_accel);
		CACHE_CVAR(g_balance_zapper_primary_damage);
		CACHE_CVAR(g_balance_zapper_primary_damagefalloff_forcehalflife);
		CACHE_CVAR(g_balance_zapper_primary_damagefalloff_mindist);
		CACHE_CVAR(g_balance_zapper_primary_damagefalloff_maxdist);
		CACHE_CVAR(g_balance_zapper_primary_damagefalloff_halflife);
		CACHE_CVAR(g_balance_zapper_primary_force);
		CACHE_CVAR(g_balance_zapper_primary_heatup);
		CACHE_CVAR(g_balance_zapper_primary_lifetime);
		CACHE_CVAR(g_balance_zapper_primary_range);
		CACHE_CVAR(g_balance_zapper_primary_refire);
		CACHE_CVAR(g_balance_zapper_primary_ticrate);
		CACHE_CVAR(g_balance_zapper_secondary);
		CACHE_CVAR(g_balance_zapper_secondary_accumulate);
		CACHE_CVAR(g_balance_zapper_secondary_ammo);
		CACHE_CVAR(g_balance_zapper_secondary_arc);
		CACHE_CVAR(g_balance_zapper_secondary_arc_force);
		CACHE_CVAR(g_balance_zapper_secondary_arc_range);
		CACHE_CVAR(g_balance_zapper_secondary_charge_time);
		CACHE_CVAR(g_balance_zapper_secondary_damage);
		CACHE_CVAR(g_balance_zapper_secondary_damagefalloff_forcehalflife);
		CACHE_CVAR(g_balance_zapper_secondary_damagefalloff_halflife);
		CACHE_CVAR(g_balance_zapper_secondary_damagefalloff_maxdist);
		CACHE_CVAR(g_balance_zapper_secondary_damagefalloff_mindist);
		CACHE_CVAR(g_balance_zapper_secondary_force);
		CACHE_CVAR(g_balance_zapper_secondary_shield);
		CACHE_CVAR(g_balance_zapper_secondary_shield_ammo);
		CACHE_CVAR(g_balance_zapper_secondary_shield_heatup);
		CACHE_CVAR(g_balance_zapper_secondary_shield_lifetime);
		CACHE_CVAR(g_balance_zapper_secondary_shield_refire);
		CACHE_CVAR(g_balance_zapper_secondary_range);
		CACHE_CVAR(g_balance_zapper_secondary_refire);
		if (cvar("g_balance_zapper_swap_buttons")) {
			zapper_buttonatck1 = BUTTON_ATCK2;
			zapper_buttonatck2 = BUTTON_ATCK;
		}
	}
    return TRUE;
}

void spawnfunc_weapon_zapper(void) {
    weapon_defaultspawnfunc(WEP_ZAPPER);
}
