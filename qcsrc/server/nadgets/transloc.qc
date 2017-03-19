
void HG_Transloc_Explode(void) {
#if 0
    if(g_jailbreak && self.owner.jb_isprisoned)
        return;

    if(time < self.jb_jail_resettime)
        return;
#endif

    setsize(self, PL_MIN, PL_MAX);

    if(!move_out_of_solid(self, MOVE_NOMONSTERS)) {
        if(!self.hg_isbonus) HG_DO_IN_ALL_CONTEXTS(if(self.owner.hg_ctx_type == HG_TRANSLOC)
            self.owner.hg_ctx_ammo += 1;)

        bprint("^1Couldn't move ", self.owner.netname, "^1's translocator out of solid! Teleport aborted. Origin: ", vtos(self.origin), ", velocity: ", vtos(self.velocity), "\n");
        return;
    }

    if(self.owner.flagcarried)
        DropFlag(self.owner.flagcarried, world, world);

    vector a;
    a = vectoangles(normalize(self.hg_lastvel));
    a_x = self.owner.v_angle_x;
    makevectors(a);

    //tdeath_hit = 0;
    //tdeath_deathtype = self.hg_type;
    TeleportPlayer(self, self.owner, self.origin, a, v_forward * (0.5 + 0.5 /* * Buffs_NadgetPower(self.owner) */ ) * (
                    cvar("g_nadgets_transloc_push_base")
                  + cvar("g_nadgets_transloc_push_playerfactor") * vlen(self.owner.velocity)
                  + cvar("g_nadgets_transloc_push_projfactor")   * vlen(self.velocity)), '0 0 0', '0 0 0');
    //tdeath_deathtype = 0;

#if 0
    if(tdeath_fragged && !self.hg_isbonus) {
        float b = CVAR(g_nadgets_transloc_telefragbonus);

        if(b) HG_DO_IN_ALL_CONTEXTS({
            self.owner.hg_ctx_ammo += b * tdeath_fragged;
            HG_SetRegenTime(self.owner, HG_RegenTime(self.owner));
        })
    }

    if(cvar("g_nadgets_transloc_reloadonuse") && self.owner.weapon && (self.owner.weaponentity.wframe != WFRAME_RELOAD || tdeath_hit)) {
		entity oldself = self;
        self = self.owner;
		weapon_action(self.weapon, WR_ACTIVERELOAD);
		if(tdeath_hit)
			ATTACK_FINISHED(self) = TRUE;

		self = oldself;
    }
#endif
}
