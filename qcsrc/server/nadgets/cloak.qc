float g_nadgets_cloak_cooldown_decloak;
float g_nadgets_cloak_duration;
float g_nadgets_cloak_damagereduction_time;
float g_nadgets_cloak_stealthrate;
float g_nadgets_cloak_usewhileactive;
float g_nadgets_cloak_unstealthrate;
float g_nadgets_cloak_actiondelay;

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
        if(GameHook_PlayerIsCarrier(self))
			GameHook_DropCarried(self);

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

var float(entity plr, entity viewer, float palpha) HG_Cloak_PlayerAlphaMod_Next;

float HG_Cloak_PlayerAlphaMod(entity plr, entity viewer, float palpha) {
    float sa = 1 - plr.hg_stealthalpha;

    if(viewer && viewer != plr) {
        if(
            (teamplay && viewer.team == plr.team) ||
            // (viewer.hg_stealth && (!Buffs_Present(plr, BUFF_ADEPT) || Buffs_Present(viewer, BUFF_ADEPT))) ||
            viewer.hg_stealth ||
            viewer.classname != "player"
        ) {
            sa = 0.3 + 0.7 * sa;
        }
    }

    return HG_Cloak_PlayerAlphaMod_Next(plr, viewer, sa * palpha);
}

var float(float secondary, float attacktime) HG_Cloak_WeaponPrepareAttack_Next;

float HG_Cloak_WeaponPrepareAttack(float secondary, float attacktime) {
    if(self.hg_stealth) {
        HG_Cloak_Trigger();
    }

    if(time - self.hg_stealthtime < g_nadgets_cloak_actiondelay) {
        return FALSE;
    }

    return HG_Cloak_WeaponPrepareAttack_Next(secondary, attacktime);
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
    CACHE_CVAR(g_nadgets_cloak_actiondelay);

    addstat(STAT_STEALTH, AS_INT, hg_stealth);
    addstat(STAT_STEALTH_SAVED, AS_INT, hg_stealth_saved);

    HG_Cloak_PlayerAlphaMod_Next = GameHookChain_PlayerAlphaMod;
    GameHookChain_PlayerAlphaMod = HG_Cloak_PlayerAlphaMod;

    HG_Cloak_WeaponPrepareAttack_Next = GameHookChain_WeaponPrepareAttack;
    GameHookChain_WeaponPrepareAttack = HG_Cloak_WeaponPrepareAttack;

    return HG_INIT_OK;
}
