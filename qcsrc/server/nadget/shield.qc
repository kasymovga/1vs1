float g_nadgets_shield_damage_store_arc;
float g_nadgets_shield_damage_store_arc_pushback;
float g_nadgets_shield_damage_store_arc_range;
float g_nadgets_shield_damage_store_allow_armor_drain;
float g_nadgets_shield_damage_store_burstamount;
float g_nadgets_shield_damage_store_edgefactor;
float g_nadgets_shield_damage_store_radius;
float g_nadgets_shield_damage_store_forcefactor;
float g_nadgets_shield_damage_store_burstdelay;
float g_nadgets_shield_damage_reflect;
float g_nadgets_shield_damage_reflect_hg;
float g_nadgets_shield_damage_take;
float g_nadgets_shield_damage_store;
float g_nadgets_transloc_counters_shield;
float g_nadgets_shield_duration;
float g_nadgets_shield_immobile;
float g_nadgets_shield_health;
float g_nadgets_shield_diminish;
float g_nadgets_shield_adept_discharge_extend;
float g_nadgets_shield_adept_discharge_renew;
float g_nadgets_shield_adept_duration;

void nadget_Shield_Discharge_Arc(entity targ, entity attacker, float _damage) {
    arc_damage(targ, attacker, _damage, NADGET_SHIELD | HITTYPE_SECONDARY | HITTYPE_BOUNCE,
        g_nadgets_shield_damage_store_arc_range, g_nadgets_shield_damage_store_arc,
        g_nadgets_shield_damage_store_arc_pushback, COLOR_TEAM3, shield_arc_hit
    );
}

void nadget_Shield_Discharge_Think(void) {
    entity targ;
    vector start, end, end_visual;
    float _damage;

    float armorval = (g_nadgets_shield_damage_store_allow_armor_drain ? (self.owner.armorvalue / g_nadgets_shield_damage_store_allow_armor_drain) : 0);

    if(self.owner.hg_shield_stored < -1)
        _damage = 0;
    else
        _damage = min(max(0, self.owner.hg_shield_stored) + armorval, g_nadgets_shield_damage_store_burstamount);

    if(_damage <= 0 || !self.owner || !self.owner.iscreature || !player_can_fire(self.owner, FALSE)) {
        remove(self);
        return;
    }

    float armordamage = 0;

    if(self.owner.hg_shield_stored < 0) {
        armordamage = _damage;
    } else {
        self.owner.hg_shield_stored -= _damage;
        armordamage = -max(0, self.owner.hg_shield_stored);
        if(self.owner.hg_shield_stored <= 0)
            self.owner.hg_shield_stored = -1;
    }

    if(armordamage > 0 && armorval) {
        armordamage *= g_nadgets_shield_damage_store_allow_armor_drain;
		self.owner.armorvalue = max(0, self.owner.armorvalue - armordamage);
    }

    makevectors(self.owner.v_angle);
	antilag_begin(self.owner);
    weapon_setup_shot(self.owner, 0, "weapons/nexfire.wav", -1);
	warpzone_trace_line(weapon_shotorg, weapon_shotorg + weapon_shotdir * WORLD_MAX_SHOT_DISTANCE, TRACE_MOVE_NORMAL, self.owner);
	antilag_end();
    targ = trace_ent;
    start = weapon_shotorg;
    end = trace_endpos;
	end_visual = warpzone_untransform_origin(warpzone_trace_transform, trace_endpos);
    setorigin(self, end);
    damage_radius(self, self.owner, _damage, _damage * g_nadgets_shield_damage_store_edgefactor,
                 g_nadgets_shield_damage_store_radius, world,
                 _damage * g_nadgets_shield_damage_store_forcefactor, 0, NADGET_SHIELD | HITTYPE_SECONDARY, targ);

    //W_SetHitscanVisuals(self.owner, end);
    weapon_zapper_attack2_effect((team_mode ? self.owner.team : COLOR_TEAM3), weapon_shotorg_visual, end_visual);

    if(g_nadgets_shield_damage_store_arc && targ && targ.iscreature && (team_is_different_teams(self.owner, targ) || RM_BUFFS_PRESENT(self.owner, RM_BUFFS_MEDIC))) {
        nadget_Shield_Discharge_Arc(targ, self.owner, _damage);
    }

    self.nextthink = time + g_nadgets_shield_damage_store_burstdelay;
}

void nadget_Shield_Trigger(void) {
    sound(self, CHAN_WEAPON2, "porto/expire.wav", VOL_BASE, ATTN_NORM);

	entity e;
    for(e = world; (e = find(e, classname, "hg_shield_discharge"));) {
        if(e.owner == self) {
            self.hg_shield_stored = 0;
            remove(e);
            return;
        }
    }

    // Discharge
    if(self.hg_shield_stored) {
		entity oldself = self;
        self = spawn();
        self.classname = "hg_shield_discharge";
        self.owner = oldself;
        self.think = nadget_Shield_Discharge_Think;
        self.reset = stdproc_remove;
        self.think();
		self = oldself;
    }
	if(!RM_BUFFS_PRESENT(self, RM_BUFFS_ADEPT) || self.hg_shield_stored <= 0) {
		self.hg_shield = 0;
		sound_stop(self, CHAN_AUTO);
	}
}

void nadget_Shield_Adept_ExtendRenew(entity plr) {
    float extend = g_nadgets_shield_adept_discharge_extend;
    float renew = g_nadgets_shield_adept_discharge_renew;
    if (!extend && !renew)
        return;

    plr.hg_shield = max(plr.hg_shield, renew) + extend;
    sound_stop(plr, CHAN_AUTO);
    sound(plr, CHAN_AUTO, "misc/powerup_shield.wav", VOL_BASE, ATTN_NORM);
}

void nadget_Shield_Model_Think(void) {
    if(self.owner.hg_shield)
        self.alpha = approach(self.alpha, 1, frametime * 3);
    else
        self.alpha = approach(self.alpha, 0, frametime * 3);

    if(!self.alpha) {
        self.owner.hg_shieldmodel = world;
        remove(self);
        return;
    }

    self.colormod = '1 1 0';
    self.colormod_z = 1 - self.owner.hg_shieldpower;
    if(self.hg_adept && self.owner.hg_shieldpower == 1)
        self.colormod_z = 1;

    setorigin(self, self.owner.origin);
    self.nextthink = time;
}

float nadget_Shield_Find() {
	entity e;
	for (e = world; (e = find(e, classname, "hg_shield_discharge"));) {
		if (e.owner == self)
			return TRUE;
	}
	return FALSE;
}

void nadget_Shield_PlayerFrame(void) {
    if(self.hg_shieldmax && self.hg_shield)
        self.hg_shieldstat = self.hg_shield / self.hg_shieldmax;
    else
        self.hg_shieldstat = 0;

    if (self.hg_shield_stored < 0 || (self.hg_shield_stored && !self.hg_shield))
	if not(nadget_Shield_Find())
		self.hg_shield_stored = 0;

    if(!self.hg_shield) {
        //self.nobuffs = 0;

        if(self.hg_shield_oldmovetype) {
            self.movetype = self.hg_shield_oldmovetype;
            self.hg_shield_oldmovetype = 0;
        }

        return;
    }

    if(!self.movetype) {
        // with MOVETYPE_NONE the player model rotation will not correspond to the view direction, so fix it here
        self.angles_y = self.v_angle_y;
    }

    if(self.hg_shieldhealth <= 0)
        self.hg_shield = 0;
    else {
        self.hg_shield = max(0, self.hg_shield - frametime);
        if(g_nadgets_shield_diminish)
            self.hg_shieldpower = self.hg_shield / self.hg_shieldmax;
    }
}

.float hg_shield_nexteffect;

float nadget_Shield_Damage(entity attacker, float _damage, float deathtype, vector hitloc) {
    if not(_damage && attacker.iscreature && self.hg_shield)
        return 1;

    if(DEATH_NADGETTYPE(deathtype) == NADGET_TRANSLOC && g_nadgets_transloc_counters_shield) {
        self.hg_shield = 0;
        return 1;
    }

    if not(DEATH_NADGETTYPE(deathtype) != NADGET_SHIELD /* && deathtype != DEATH_NOISE && deathtype != DEATH_ARC */ && DEATH_NADGETTYPE(deathtype) != NADGET_GG)
        return 1;

    vector offs = '0 0 1' * self.maxs_z * 0.5;
    float reflect    = _damage * g_nadgets_shield_damage_reflect * self.hg_shieldpower;
    float takefactor = 1 - (1 - g_nadgets_shield_damage_take)   * self.hg_shieldpower;
    float absorb     = _damage * (1 - takefactor);

    float o = self.hg_shield_stored;
    self.hg_shield_stored = min(g_nadgets_shield_damage_store_limit, self.hg_shield_stored + _damage * g_nadgets_shield_damage_store);

    if(self.hg_shield_stored > o && time > self.hg_shield_nexteffect) {
        //te_eleblast(hitloc, if(team_mode) self.team else 0);
        self.hg_shield_nexteffect = time + 0.15;
    }

    if(DEATH_NADGETTYPE(deathtype) == NADGET_TRANSLOC)
        reflect = 0;
    else if(DEATH_ISNADGET(deathtype))
        reflect *= g_nadgets_shield_damage_reflect_hg;

    if(reflect) {
        vector start = self.origin + offs;
        vector end   = attacker.origin + offs;

        trace_line(start, end, FALSE, self);
        end = trace_endpos;

        if(trace_ent.takedamage)
            damage(trace_ent, self, self, reflect, NADGET_SHIELD, end, '0 0 0');

        trailparticles(world, particleeffectnum("TE_TEI_G3YELLOW"), start, end);
    }

    self.hg_shieldhealth -= absorb;
    if(self.hg_shieldhealth <= 0)
        self.hg_shield = 0;

    return takefactor;
}

NADGET_HOOKFUNCTION(shield, Attack) {
    entity e;
    float d;
	float adept = RM_BUFFS_PRESENT(self, RM_BUFFS_ADEPT);
	if (adept)
		d = g_nadgets_shield_adept_duration;
	else
		d = g_nadgets_shield_duration;

	if(g_nadgets_shield_immobile) {
		self.hg_shield_oldmovetype = self.movetype;
		self.movetype = MOVETYPE_NONE;
	}
    self.hg_shieldmax = d * rm_buffs_nadget_power(self);
    self.hg_shield = self.hg_shieldmax;
    self.hg_shieldhealth = g_nadgets_shield_health;
    self.hg_shieldpower = 1;
    self.hg_shield_stored = g_nadgets_shield_damage_store_base;
    self.hg_shield_stored_limit = g_nadgets_shield_damage_store_limit;
	self.nobuffs = cvar("g_nadgets_shield_nobuffs");
    self.hg_shield_damage_per_shot = g_nadgets_shield_damage_store_burstamount;

    sound(self, CHAN_AUTO, "misc/powerup_shield.wav", VOL_BASE, ATTN_NORM);

    if(!self.hg_shieldmodel) {
        e = spawn();
        e.classname = "hg_shieldmodel";
        e.owner = self;
        e.think = nadget_Shield_Model_Think;
        e.nextthink = time;
        e.alpha = 0.1;
        e.effects = EFFECT_ADDITIVE | EFFECT_FULLBRIGHT;
        e.glow_size = 256;
        e.glow_color = 230;
        e.glow_trail = 1;
        e.avelocity = '14 0 22';
        e.movetype = MOVETYPE_FOLLOW;
        e.aiment = e.owner;
        setorigin(e, self.origin);
        setmodel(e, "models/ctf/shield.md3");
        e.scale = 0.5;
		e.hg_adept = adept;
		e.skin = 10 + !!adept;
        e.exteriormodeltoclient = self;
        setsize(e, e.scale * e.mins, e.scale * e.maxs);

        self.hg_shieldmodel = e;
    }

    return NADGET_ATTACK_OK;
}

NADGET_HOOKFUNCTION(shield, Init) {
    addstat(STAT_HGSHIELD, STAT_FLOAT, hg_shieldstat);
    addstat(STAT_HGSHIELDPOWER, STAT_FLOAT, hg_shieldpower);
    addstat(STAT_HGSHIELDSTORE, STAT_INT, hg_shield_stored);
    addstat(STAT_HGSHIELDSTOREMAX, STAT_INT, hg_shield_stored_limit);
    addstat(STAT_HGSHIELDDAMAGEPERSHOT, STAT_INT, hg_shield_damage_per_shot);
	CVAR_CACHE(g_nadgets_shield_damage_store_arc);
	CVAR_CACHE(g_nadgets_shield_damage_store_arc_pushback);
	CVAR_CACHE(g_nadgets_shield_damage_store_arc_range);
	CVAR_CACHE(g_nadgets_shield_damage_store_allow_armor_drain);
	CVAR_CACHE(g_nadgets_shield_damage_store_burstamount);
	CVAR_CACHE(g_nadgets_shield_damage_store_edgefactor);
	CVAR_CACHE(g_nadgets_shield_damage_store_radius);
	CVAR_CACHE(g_nadgets_shield_damage_store_forcefactor);
	CVAR_CACHE(g_nadgets_shield_damage_store_burstdelay);
	CVAR_CACHE(g_nadgets_shield_damage_reflect);
	CVAR_CACHE(g_nadgets_shield_damage_reflect_hg);
	CVAR_CACHE(g_nadgets_shield_damage_take);
	CVAR_CACHE(g_nadgets_shield_damage_store_base);
	CVAR_CACHE(g_nadgets_shield_damage_store_limit);
	CVAR_CACHE(g_nadgets_shield_damage_store);
	CVAR_CACHE(g_nadgets_transloc_counters_shield);
	CVAR_CACHE(g_nadgets_shield_duration);
	CVAR_CACHE(g_nadgets_shield_immobile);
	CVAR_CACHE(g_nadgets_shield_health);
	CVAR_CACHE(g_nadgets_shield_diminish);
	CVAR_CACHE(g_nadgets_shield_adept_discharge_extend);
	CVAR_CACHE(g_nadgets_shield_adept_discharge_renew);
	CVAR_CACHE(g_nadgets_shield_adept_duration);
    return NADGET_INIT_OK;
}
