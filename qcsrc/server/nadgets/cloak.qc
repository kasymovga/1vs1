float g_nadgets_cloak_cooldown_decloak;
float g_nadgets_cloak_duration;
float g_nadgets_cloak_damagereduction_time;
float g_nadgets_cloak_stealthrate;
float g_nadgets_cloak_usewhileactive;
float g_nadgets_cloak_unstealthrate;

void HG_Cloak(void) {
    self.hg_stealth = self.hg_stealth + g_nadgets_cloak_duration/* * Buffs_NadgetPower(self)*/;
    self.fire_endtime = 0;
    self.hg_stealth_protectionexpiretime = time + g_nadgets_cloak_damagereduction_time;
    pointparticles(particleeffectnum("smoke_ring"), self.origin + self.maxs_z * '0 0 0.5', '0 0 0', 10);
    sound(self, CHAN_AUTO, "misc/stealth.wav", VOL_BASE, ATTN_NORM);
}

void HG_Cloak_Trigger(void) {
#if 0
    if(!Buffs_Present(self, BUFF_ADEPT)) {
#endif
        self.hg_stealth = 0;
        return;
#if 0
    }


    if(self.hg_stealth) {
        self.hg_stealth_saved = self.hg_stealth;
        self.hg_stealth = 0;
    } else if(self.hg_stealth_saved) {
        sound(self, CHAN_AUTO, "misc/stealth.wav", VOL_BASE, ATTN_NORM);
        self.hg_stealth = self.hg_stealth_saved;
        self.hg_stealth_saved = 0;
        self.fire_endtime = 0;
    }
#endif
}

void HG_Cloak_PlayerFrame(void) {
    if(self.hg_stealth) {
        if(self.flagcarried)
            DropFlag(self.flagcarried, world, world);
        self.hg_wasstealth = TRUE;
        self.hg_stealthtime = time;
        if(self.hg_stealthalpha < 1)
            self.hg_stealthalpha = approach(self.hg_stealthalpha, 1, frametime * g_nadgets_cloak_stealthrate);
        self.hg_stealth = approach(self.hg_stealth, 0, frametime);
    } else {
        if(self.hg_wasstealth) {
            self.hg_wasstealth = FALSE;

            HG_DO_IN_ALL_CONTEXTS({
                if(self.hg_ctx_type == HG_CLOAK)
                    HG_SetCooldown(hg_ctx_next, 0, g_nadgets_cloak_cooldown_decloak);
            })

            sound(self, CHAN_AUTO, "misc/unstealth.wav", VOL_BASE, ATTN_NORM);
        }
        if(self.hg_stealthalpha)
            self.hg_stealthalpha = approach(self.hg_stealthalpha, 0, frametime * g_nadgets_cloak_unstealthrate);
    }
}

HG_HOOKFUNCTION(cloak, Attack) {
    if(self.hg_stealth && !g_nadgets_cloak_usewhileactive)
        return HG_ATTACK_FAIL;

    HG_Cloak();
    return HG_ATTACK_OK;
}

HG_HOOKFUNCTION(cloak, Init) {
	CACHE_CVAR(g_nadgets_cloak_cooldown_decloak);
	CACHE_CVAR(g_nadgets_cloak_duration);
	CACHE_CVAR(g_nadgets_cloak_damagereduction_time);
	CACHE_CVAR(g_nadgets_cloak_stealthrate);
	CACHE_CVAR(g_nadgets_cloak_usewhileactive);
	CACHE_CVAR(g_nadgets_cloak_unstealthrate);
    addstat(STAT_STEALTH, AS_INT, hg_stealth);
    addstat(STAT_STEALTH_SAVED, AS_INT, hg_stealth_saved);
    return HG_INIT_OK;
}
