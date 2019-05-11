.float heal_next_particle;
float(entity targ, entity inflictor, entity healer, float _heal, float aheal, float hlimit, float alimit,
		float healtype, float pauserot, float pausearot, vector hitloc, vector force) heal {
    if(targ.classname == "player") {
        if(hlimit)  hlimit = min(g_balance_health_limit, hlimit);
        else        hlimit = g_balance_health_limit;
        if(alimit)  alimit = min(g_balance_armor_limit,  alimit);
        else        alimit = g_balance_armor_limit;

    }
    if(pauserot  < 0) pauserot  = g_balance_pause_health_rot;
    if(pausearot < 0) pausearot = g_balance_pause_armor_rot;

	_heal  = max(0, min(_heal,  hlimit - targ.health));
	aheal = max(0, min(aheal, alimit - targ.armorvalue));

    targ.health += _heal;
    targ.pauserothealth_finished = max(targ.pauserothealth_finished, time + pauserot);

    targ.armorvalue += aheal;
    targ.pauserotarmor_finished = max(targ.pauserotarmor_finished, time + pausearot);
    if(_heal || aheal) {
		if(time > targ.heal_next_particle) {
			//te_heal(targ);
			targ.heal_next_particle = time + 0.2;
		}

		if(_heal)  sound(targ, CHAN_AUTO, "misc/mediumhealth.wav", VOL_BASE, ATTN_NORM);
		if(aheal) sound(targ, CHAN_AUTO, "misc/armor10.wav", VOL_BASE, ATTN_NORM);
    }

    // apply push
    if(targ.damageforcescale)
    if(vlen(force)) {
        targ.velocity = targ.velocity + targ.damageforcescale * force;
        targ.flags &~= FL_ONGROUND;
    }

    return _heal + aheal;
}

