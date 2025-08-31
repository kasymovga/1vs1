float g_nadgets_gg_damage;
float g_nadgets_gg_range;

NADGET_HOOKFUNCTION(gg, Attack) {
    entity p;
    float pwned = 0;
    float allow;

    PLAYER_FOR_EACH(p)
    if (p != self)
    if (!PLAYER_DEAD(p))
    if (!team_teams || p.team != self.team || RM_BUFFS_PRESENT(self, RM_BUFFS_MEDIC) || RM_BUFFS_PRESENT(self, RM_BUFFS_ADEPT))
    if (vlen(self.origin - p.origin) < g_nadgets_gg_range) {
        vector o = self.origin + self.view_ofs;
        vector e = p.origin + p.view_ofs;
        trace_line(o, e, TRUE, self);

        allow = (trace_endpos == e);
        if(!allow)
            allow = (vlen(trace_endpos - e) < 5);

        if(allow) {
            damage(p, world, self, g_nadgets_gg_damage, NADGET_GG, e, normalize(e - o) * 1000);
            trailparticles(world, particleeffectnum("TE_TEI_G3RED_HIT"), o, e + randomvec() * 10);
            trailparticles(world, particleeffectnum("TE_TEI_G3BLUE_HIT"), o, e + randomvec() * 10);
            trailparticles(world, particleeffectnum("TE_TEI_G3YELLOW_HIT"), o, e + randomvec() * 10);
            trailparticles(world, particleeffectnum("TE_TEI_G3PINK_HIT"), o, e + randomvec() * 10);
			if (RM_BUFFS_PRESENT(self, RM_BUFFS_ADEPT)) {
				//float i; for(i = 0; i < 4; ++i)
				//	te_csqc_lightningarc(o, e + randomvec() * 10, TRUE, Team_FromIndex(i));
				effect_lightningarc(o, e + randomvec() * 10/*, TRUE, Team_FromIndex(i)*/); //FIXME
			}
            ++pwned;
        }
    }

    if(pwned) {
        sound(self, CHAN_AUTO, "misc/gg.wav", 1, ATTN_NORM);
        return NADGET_ATTACK_OK;
    } else {
        RM({rm_bigprint_spec(self, "Nobody to win against!", "", 1);})
        return NADGET_ATTACK_FAIL_COOLDOWN;
    }
}

NADGET_HOOKFUNCTION(gg, Init) {
	CVAR_CACHE(g_nadgets_gg_damage);
	CVAR_CACHE(g_nadgets_gg_range);
    return NADGET_INIT_OK;
}
