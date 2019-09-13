float g_nadgets_gg_damage;
float g_nadgets_gg_range;

NADGET_HOOKFUNCTION(gg, Attack) {
    entity p;
    float pwned;
    float allow;

    FOR_EACH_PLAYER(p)
    if(p != self)
    if(!PLAYER_DEAD(p))
    if(!teamplay || p.team != self.team /* || Buffs_Present(self, BUFF_MEDIC) || Buffs_Present(self, BUFF_ADEPT) */ )
    if(vlen(self.origin - p.origin) < g_nadgets_gg_range) {
        vector o = self.origin + self.view_ofs;
        vector e = p.origin + p.view_ofs;
        traceline(o, e, TRUE, self);

        allow = (trace_endpos == e);
        if(!allow)
            allow = (vlen(trace_endpos - e) < 5);

        if(allow) {
            damage(p, world, self, g_nadgets_gg_damage, NADGET_GG, e, normalize(e - o) * 1000);
            trailparticles(world, particleeffectnum("TE_TEI_G3RED_HIT"), o, e + randomvec() * 10);
            trailparticles(world, particleeffectnum("TE_TEI_G3BLUE_HIT"), o, e + randomvec() * 10);
            trailparticles(world, particleeffectnum("TE_TEI_G3YELLOW_HIT"), o, e + randomvec() * 10);
            trailparticles(world, particleeffectnum("TE_TEI_G3PINK_HIT"), o, e + randomvec() * 10);
            ++pwned;
        }
    }

    if(pwned) {
        dlc_sound(self, CHAN_AUTO, "misc/gg.wav", 1, ATTN_NORM);
        return NADGET_ATTACK_OK;
    } else {
        //bigprint_spec(self, "Nobody to win against!", "", 1);
        return NADGET_ATTACK_FAIL_COOLDOWN;
    }
}

NADGET_HOOKFUNCTION(gg, Init) {
	CACHE_CVAR(g_nadgets_gg_damage);
	CACHE_CVAR(g_nadgets_gg_range);
    return NADGET_INIT_OK;
}
