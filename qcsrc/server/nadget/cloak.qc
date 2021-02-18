float g_nadgets_cloak_cooldown_decloak;
float g_nadgets_cloak_duration;
float g_nadgets_cloak_damagereduction_time;
float g_nadgets_cloak_stealthrate;
float g_nadgets_cloak_usewhileactive;
float g_nadgets_cloak_unstealthrate;
float g_nadgets_cloak_actiondelay;
float g_nadgets_cloak_spy;

void nadget_Cloak(void) {
    self.hg_stealth = self.hg_stealth + g_nadgets_cloak_duration/* * Buffs_NadgetPower(self)*/;
    self.fire_endtime = 0;
    self.hg_stealth_protectionexpiretime = time + g_nadgets_cloak_damagereduction_time;
    pointparticles(particleeffectnum("smoke_ring"), self.origin + self.maxs_z * '0 0 0.5', '0 0 0', 10);
    dlc_sound(self, CHAN_AUTO, "misc/stealth.wav", VOL_BASE, ATTN_NORM);
	entity e;
	if (g_nadgets_cloak_spy)
		FOR_EACH_PLAYER(e)
			e.entcs.SendFlags |= 16;
}

void nadget_Cloak_Trigger(void) {
	self.hg_stealth = 0;
	return;
}

void nadget_Cloak_PlayerFrame(void) {
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

            NADGET_DO_IN_ALL_CONTEXTS({
                if(self.hg_ctx_type == NADGET_CLOAK)
                    nadget_SetCooldown(hg_ctx_next, 0, g_nadgets_cloak_cooldown_decloak);
            })

            dlc_sound(self, CHAN_AUTO, "misc/unstealth.wav", VOL_BASE, ATTN_NORM);
        }
        if(self.hg_stealthalpha)
            self.hg_stealthalpha = approach(self.hg_stealthalpha, 0, frametime * g_nadgets_cloak_unstealthrate);
    }
}

var float(entity plr, entity viewer, float palpha) nadget_Cloak_PlayerAlphaMod_Next;

float nadget_Cloak_PlayerAlphaMod(entity plr, entity viewer, float palpha) {
    float sa = 1 - plr.hg_stealthalpha;

	if (viewer && viewer != plr)
	if ((team_mode && viewer.team == plr.team) || viewer.hg_stealth || viewer.classname != "player")
		sa = 0.3 + 0.7 * sa;

    return nadget_Cloak_PlayerAlphaMod_Next(plr, viewer, sa * palpha);
}

var float(float secondary, float attacktime) nadget_Cloak_WeaponPrepareAttack_Next;

float nadget_Cloak_WeaponPrepareAttack(float secondary, float attacktime) {
    if(self.hg_stealth) {
        nadget_Cloak_Trigger();
    }

    if(time - self.hg_stealthtime < g_nadgets_cloak_actiondelay) {
        return FALSE;
    }

    return nadget_Cloak_WeaponPrepareAttack_Next(secondary, attacktime);
}

NADGET_HOOKFUNCTION(cloak, Attack) {
    if(self.hg_stealth && !g_nadgets_cloak_usewhileactive)
        return NADGET_ATTACK_FAIL;

    nadget_Cloak();
    return NADGET_ATTACK_OK;
}

var float(entity plr, entity targ) nadget_Cloak_PlayerCanSeeHealthFor_NextLink;
float nadget_Cloak_PlayerCanSeeHealthFor(entity plr, entity targ) {
	if (plr.hg_stealth)
		return TRUE;

	return nadget_Cloak_PlayerCanSeeHealthFor_NextLink(plr, targ);
}

NADGET_HOOKFUNCTION(cloak, Init) {
	CVAR_CACHE(g_nadgets_cloak_cooldown_decloak);
	CVAR_CACHE(g_nadgets_cloak_duration);
	CVAR_CACHE(g_nadgets_cloak_damagereduction_time);
	CVAR_CACHE(g_nadgets_cloak_stealthrate);
	CVAR_CACHE(g_nadgets_cloak_usewhileactive);
	CVAR_CACHE(g_nadgets_cloak_unstealthrate);
    CVAR_CACHE(g_nadgets_cloak_actiondelay);
    CVAR_CACHE(g_nadgets_cloak_spy);

    addstat(STAT_STEALTH, AS_INT, hg_stealth);
    addstat(STAT_STEALTH_SAVED, AS_INT, hg_stealth_saved);

    nadget_Cloak_PlayerAlphaMod_Next = gamehook_chain_player_alpha_mod;
    gamehook_chain_player_alpha_mod = nadget_Cloak_PlayerAlphaMod;

    nadget_Cloak_WeaponPrepareAttack_Next = GameHookChain_WeaponPrepareAttack;
    GameHookChain_WeaponPrepareAttack = nadget_Cloak_WeaponPrepareAttack;

	if (g_nadgets_cloak_spy) {
		nadget_Cloak_PlayerCanSeeHealthFor_NextLink = GameHookChain_PlayerCanSeeHealthFor;
		GameHookChain_PlayerCanSeeHealthFor = nadget_Cloak_PlayerCanSeeHealthFor;
	}

    return NADGET_INIT_OK;
}
