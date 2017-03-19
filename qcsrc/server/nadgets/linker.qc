float g_nadgets_linker_sharefactor;
float g_nadgets_linker_range;
float g_nadgets_linker_damagefactor;
float g_nadgets_linker_hps;
float g_nadgets_linker_duration;

void HG_Linker_Adept_Push(entity p) {
    if(vlen(p.origin - self.origin) <= self.hg_linker_range) {
        float v = max(400, vlen(p.velocity));
        p.velocity = normalize(p.origin - self.origin) * v;
        UpdateCSQCProjectile(p);
    }
}

void HG_Linker_Remove(void) {
    HG_Waypoint_Remove(self.hg_waypoint);
    remove(self);
}

#define HEAL_PAUSEROT_DEFAULT -1
void HG_Linker_Think(void) {
    entity p, e;
    float denom, thealth, tarmor, sharefactor;

    if(!self.owner.iscreature || self.owner.team != self.team) {
        HG_Linker_Remove();
        return;
    }

    float sharingframe = (time > self.hg_linker_nexteffect);

#if 0
    if(sharingframe)
        self.buffs = 0;
#endif

    FOR_EACH_PLAYER(p) {
        if(p.team != self.team || (!teams_matter && p != self.owner)) {
            if(p.hg_linker == self)
                p.hg_linker = world;
        } else if(p.hg_linker == self) {
            if(vlen(self.origin - p.origin) > self.hg_linker_range)
                p.hg_linker = world;
        } else if(!p.hg_linker) {
            if(vlen(self.origin - p.origin) <= self.hg_linker_range)
                p.hg_linker = self;
        }

        if(sharingframe)
        if(p.hg_linker == self) IF_HG_LINKER_APPLICABLE(p) {
            ++denom;
            thealth += p.health;
            tarmor += p.armorvalue;

#if 0
            if(CVAR(g_nadgets_linker_sharedbuffs))
                self.buffs |= p.buffs;
#endif

            if(time > p.hg_linker_effecttime) {
                FOR_EACH_PLAYER(e) if(e != p) if(e.hg_linker == self) if(time > e.hg_linker_effecttime) IF_HG_LINKER_APPLICABLE(e) {
                    //te_csqc_lightningarc(p.origin, e.origin, FALSE, e.team);
                    te_csqc_lightningarc(p.origin, e.origin);
                }
            }

            p.hg_linker_effecttime = time;
        }

#if 0
        if(self.hg_adept)
            if(p != self.owner && !p.frozen && (!teams_matter || p.team != self.team))
                HG_Linker_Adept_Push(p);
#endif
    }

#if 0
    self.buffs &~= CVAR(g_nadgets_linker_sharedbuffs_banmask);

    if(self.hg_adept)
        for(p = findchainflags(flags, FL_PROJECTILE); p; p = p.chain)
            if(p.classname != "bullet" && p.owner != self.owner && (!teams_matter || p.owner.team != self.team))
                HG_Linker_Adept_Push(p);
#endif

    if(sharingframe) {
        self.hg_linker_nexteffect = time + 1;

        if(denom >= 1) {
            if(denom > 1) sound(self, CHAN_AUTO, "kh/capture.wav", 0.4, 1.5);

            FOR_EACH_PLAYER(p) if(p.hg_linker == self) IF_HG_LINKER_APPLICABLE(p) {
                if(denom > 1 && g_nadgets_linker_sharefactor) {
                    float newhealth = (1 - g_nadgets_linker_sharefactor) * p.health     + g_nadgets_linker_sharefactor * (thealth / denom);
                    float newarmor  = (1 - g_nadgets_linker_sharefactor) * p.armorvalue + g_nadgets_linker_sharefactor * (tarmor  / denom);

                    if(self.hg_linker_hps) {
                        float lim = g_balance_health_limit;
                        newhealth = newhealth + min(self.hg_linker_hps, max(0, lim - newhealth));
                    }

                    Heal(p, self, self.owner,
                            max(0, newhealth - p.health), max(0, newarmor - p.armorvalue), 0, 0, HG_LINKER | HITTYPE_SECONDARY,
                            HEAL_PAUSEROT_DEFAULT, HEAL_PAUSEROT_DEFAULT, '0 0 0', '0 0 0');

                    p.health = newhealth;
                    p.armorvalue = newarmor;
                } else {
                    Heal(p, self, self.owner, self.hg_linker_hps, 0, 0, 0, HG_LINKER,
                         HEAL_PAUSEROT_DEFAULT, HEAL_PAUSEROT_DEFAULT, '0 0 0', '0 0 0');
                }
            }
        }
    }

    self.alpha = bound(0, (self.cnt - time) * 2, 1);

    if(self.alpha == 0) {
        HG_Linker_Remove();
        return;
    }

    HG_Waypoint();

    self.alpha = max(0.01, self.alpha * bound(0, (time - self.hg_spawntime) * 2, 1));
    self.glow_size = self.hg_linker_range * self.alpha * 3;
    self.nextthink = time;
}

#if 0
void HG_Linker_MEODP_Death(entity attacker, entity inflictor) {
    HG_Linker_Remove();
}
#endif

HG_HOOKFUNCTION(linker, Attack) {
    entity e = spawn();
    e.classname = "hg_linker";
    e.owner = self;
    e.team = self.team;
    e.think = HG_Linker_Think;
    e.nextthink = time;
    e.hg_spawntime = time;
    e.reset = HG_Linker_Remove;
    e.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION | EF_DOUBLESIDED;
    e.gravity = 100;
    e.hg_linker_range = g_nadgets_linker_range;
    e.hg_linker_factor = g_nadgets_linker_damagefactor;
    e.hg_linker_hps = g_nadgets_linker_hps;
    e.cnt = time + g_nadgets_linker_duration/* * Buffs_NadgetPower(self) */;
    e.hg_deathtime = e.cnt;
    e.alpha = 0.01;
    setmodel(e, "models/ctf/shield.md3");
    e.scale = e.hg_linker_range / e.maxs_x;
    e.glow_color = 0xF5;
#if 0
    e.hg_adept = Buffs_Present(self, BUFF_ADEPT);
#endif
    e.movetype = MOVETYPE_TOSS;
    e.hg_type = HG_LINKER;

    if(e.team)
        e.skin = TeamColorSkin(e.team);

    if(e.hg_adept)
        e.skin += 5;

    setorigin(e, self.origin + self.view_ofs);
    setsize(e, '-32 -32 0', '32 32 32');

#if 0
    Buffs_MEODP_Point_Attach(e, HG_Linker_MEODP_Death);
#endif

    sound(e, CHAN_PROJECTILE, "misc/powerup.wav", 1, 1.5);

    return HG_ATTACK_OK;
}

HG_HOOKFUNCTION(linker, Init) {
	CACHE_CVAR(g_nadgets_linker_sharefactor);
	CACHE_CVAR(g_nadgets_linker_range);
	CACHE_CVAR(g_nadgets_linker_damagefactor);
	CACHE_CVAR(g_nadgets_linker_hps);
	CACHE_CVAR(g_nadgets_linker_duration);
    return HG_INIT_OK;
}
