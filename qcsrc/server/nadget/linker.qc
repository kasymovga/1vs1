float g_nadgets_linker_sharefactor;
float g_nadgets_linker_range;
float g_nadgets_linker_damagefactor;
float g_nadgets_linker_hps;
float g_nadgets_linker_duration;

void nadget_Linker_Adept_Push(entity p) {
    if(vlen(p.origin - self.origin) <= g_nadgets_linker_range) {
        float v = max(400, vlen(p.velocity));
        p.velocity = normalize(p.origin - self.origin) * v;
        projectile_update(p);
    }
}

void(void) nadget_linker_on_remove {
	entity  p;
	PLAYER_FOR_EACH(p) {
		if (p.hg_linker == self)
			p.hg_linker = NULL;
	}
	nadget_Waypoint_Remove(self.hg_waypoint);
}

var void(entity targ, entity attacker, float deathtype) nadget_linker_DamageForceModsSet_next;
void(entity targ, entity attacker, float deathtype) nadget_linker_DamageForceModsSet {
	if (targ.hg_linker)
	if (targ.hg_linker.owner == targ || (team_mode && targ.hg_linker.team == targ.team))
		plugin_chain_damage_mod = plugin_chain_damage_mod * g_nadgets_linker_damagefactor;

	nadget_linker_DamageForceModsSet_next(targ, attacker, deathtype);
}

#define HEAL_PAUSEROT_DEFAULT -1
void nadget_Linker_Think(void) {
    entity p, e;
    float denom = 0, thealth = 0, tarmor = 0;
    if(!self.owner.iscreature || self.owner.team != self.team) {
		stdproc_remove();
        return;
    }
    float sharingframe = (time > self.hg_linker_nexteffect);
    PLAYER_FOR_EACH(p) {
        if(p.team != self.team || (!team_mode && p != self.owner)) {
            if(p.hg_linker == self)
                p.hg_linker = world;
        } else if(p.hg_linker == self) {
            if(vlen(self.origin - p.origin) > g_nadgets_linker_range)
                p.hg_linker = world;
        } else if(!p.hg_linker) {
            if(vlen(self.origin - p.origin) <= g_nadgets_linker_range)
                p.hg_linker = self;
        }

        if(sharingframe)
        if(p.hg_linker == self) IF_NADGET_LINKER_APPLICABLE(p) {
            ++denom;
            thealth += p.health;
            tarmor += p.armorvalue;
            if(time > p.hg_linker_effecttime) {
                PLAYER_FOR_EACH(e) if(e != p) if(e.hg_linker == self) if(time > e.hg_linker_effecttime) IF_NADGET_LINKER_APPLICABLE(e) {
                    effect_lightningarc(p.origin, e.origin);
                }
            }

            p.hg_linker_effecttime = time;
			if(self.hg_adept)
				if(p != self.owner && p.deadflag != DEAD_FREEZE && (!team_mode || p.team != self.team))
					nadget_Linker_Adept_Push(p);
        }
    }
    if(sharingframe) {
        self.hg_linker_nexteffect = time + 1;

        if(denom >= 1) {
            if(denom > 1) sound(self, CHAN_AUTO, "kh/capture.wav", 0.4, 1.5);

            PLAYER_FOR_EACH(p) if(p.hg_linker == self) IF_NADGET_LINKER_APPLICABLE(p) {
                if(denom > 1 && g_nadgets_linker_sharefactor) {
                    float newhealth = (1 - g_nadgets_linker_sharefactor) * p.health     + g_nadgets_linker_sharefactor * (thealth / denom);
                    float newarmor  = (1 - g_nadgets_linker_sharefactor) * p.armorvalue + g_nadgets_linker_sharefactor * (tarmor  / denom);

                    if (g_nadgets_linker_hps) {
                        float lim = g_balance_health_limit;
                        newhealth = newhealth + min(g_nadgets_linker_hps, max(0, lim - newhealth));
                    }

                    heal(p, self, self.owner,
                            max(0, newhealth - p.health), max(0, newarmor - p.armorvalue), 0, 0, NADGET_LINKER | HITTYPE_SECONDARY,
                            HEAL_PAUSEROT_DEFAULT, HEAL_PAUSEROT_DEFAULT, '0 0 0', '0 0 0');

                    p.health = newhealth;
                    p.armorvalue = newarmor;
                } else {
                    heal(p, self, self.owner, g_nadgets_linker_hps, 0, 0, 0, NADGET_LINKER,
                         HEAL_PAUSEROT_DEFAULT, HEAL_PAUSEROT_DEFAULT, '0 0 0', '0 0 0');
                }
            }
        }
    }

    self.alpha = bound(0, (self.cnt - time) * 2, 1);

    if(self.alpha == 0) {
		stdproc_remove();
        return;
    }
    nadget_Waypoint();
    self.alpha = max(0.01, self.alpha * bound(0, (time - self.hg_spawntime) * 2, 1));
    self.glow_size = g_nadgets_linker_range * self.alpha * 3;
    self.nextthink = time;
}

void nadget_Linker_MEODP_Death(entity attacker, entity inflictor) {
	stdproc_remove();
}

NADGET_HOOKFUNCTION(linker, Attack) {
    entity e = spawn();
    e.classname = "hg_linker";
    e.owner = self;
    e.team = self.team;
    e.think = nadget_Linker_Think;
    e.nextthink = time;
    e.hg_spawntime = time;
    e.reset = stdproc_remove;
    e.effects = EFFECT_ADDITIVE | EFFECT_FULLBRIGHT | EFFECT_LOWPRECISION | EFFECT_DOUBLESIDED;
    e.gravity = 100;
    e.cnt = time + g_nadgets_linker_duration/* * Buffs_NadgetPower(self) */;
    e.hg_deathtime = e.cnt;
    e.alpha = 0.01;
    setmodel(e, "models/ctf/shield.md3");
    e.scale = g_nadgets_linker_range / e.maxs_x;
    e.glow_color = 0xF5;
    e.hg_adept = RM_BUFFS_PRESENT(self, RM_BUFFS_ADEPT);
    e.movetype = MOVETYPE_TOSS;
    e.hg_type = NADGET_LINKER;
    e.entremove = nadget_linker_on_remove;
    if(e.team)
        e.skin = team_index(e.team);

    setorigin(e, self.origin + self.view_ofs);
    setsize(e, '-32 -32 0', '32 32 32');
	rm_buffs_meodp_point_attach(e, nadget_Linker_MEODP_Death);
    sound(e, CHAN_PROJECTILE, "misc/powerup.wav", 1, 1.5);
    return NADGET_ATTACK_OK;
}

NADGET_HOOKFUNCTION(linker, Init) {
	CVAR_CACHE(g_nadgets_linker_sharefactor);
	CVAR_CACHE(g_nadgets_linker_range);
	CVAR_CACHE(g_nadgets_linker_damagefactor);
	CVAR_CACHE(g_nadgets_linker_hps);
	CVAR_CACHE(g_nadgets_linker_duration);
	nadget_linker_DamageForceModsSet_next = plugin_chain_damage_mods_set;
	plugin_chain_damage_mods_set = nadget_linker_DamageForceModsSet;
    return NADGET_INIT_OK;
}
