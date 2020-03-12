
void nadget_Transloc_Explode(void) {
    setsize(self, PL_MIN, PL_MAX);

    if(!entity_move_out_of_solid(self, MOVE_NOMONSTERS)) {
        if(!self.hg_isbonus) NADGET_DO_IN_ALL_CONTEXTS(if(self.owner.hg_ctx_type == NADGET_TRANSLOC)
            self.owner.hg_ctx_ammo += 1;)

        bprint("^1Couldn't move ", self.owner.netname, "^1's translocator out of solid! Teleport aborted. Origin: ", vtos(self.origin), ", velocity: ", vtos(self.velocity), "\n");
        return;
    }

	if(GameHook_PlayerIsCarrier(self.owner))
		GameHook_DropCarried(self.owner);

    vector a;
    a = vectoangles(normalize(self.hg_lastvel));
    a_x = self.owner.v_angle_x;
    makevectors(a);

    teleport(self, self.owner, self.origin, a, v_forward * (0.5 + 0.5 /* * Buffs_NadgetPower(self.owner) */ ) * (
                    cvar("g_nadgets_transloc_push_base")
                  + cvar("g_nadgets_transloc_push_playerfactor") * vlen(self.owner.velocity)
                  + cvar("g_nadgets_transloc_push_projfactor")   * vlen(self.velocity)), '0 0 0', '0 0 0', cvar("g_nadgets_transloc_damage"));
}
