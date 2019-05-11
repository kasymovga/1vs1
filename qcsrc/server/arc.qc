void arc_effect(vector from, vector to, float t) {
    // te_csqc_lightningarc(from, to, TRUE, t);
    // W_Zapper_Attack2_Effect(t, from, to);
    te_csqc_lightningarc(from, to);
}

void arc_damage_recurse(entity targ, entity attacker, float damage, float deathtype,
                       vector arcoffset, float range, float mul, float force, float default_color,
                       float targetTeamMates, float targetFrozen, float targetAlive, .float hitfield) {
    entity oldself = self;
    entity plr, newtarget;
    float dist, shortest;

    if(targetFrozen)
        damage = 1;
    else
        damage = damage * mul;

    if(damage < 1)
        return;

    newtarget = world;
    shortest = range;
    targ.hitfield = TRUE;

    FOR_EACH_PLAYER(plr)
    if(plr != attacker)
    if(plr != targ)
    if(plr.deadflag == DEAD_NO || (plr.deadflag == DEAD_FREEZE && targetFrozen))
    if(!plr.hg_stealth || (targetTeamMates && plr.team == attacker.team))
    if(!plr.hitfield) {
        float sameteam = (teamplay && plr.team == attacker.team);
        if((!sameteam && (((plr.deadflag != DEAD_FREEZE) && targetAlive) || ((plr.deadflag == DEAD_FREEZE) && targetFrozen))) || (sameteam && targetTeamMates)) {
            dist = vlen(plr.origin - targ.origin);
            if(dist < shortest) {
                traceline(targ.origin + arcoffset, plr.origin + arcoffset, MOVE_NORMAL, world);

                if(trace_fraction < 1 && trace_ent == plr) {
                    shortest = dist;
                    newtarget = plr;
                }
            }
        }
    }

    if(newtarget) {
        arc_effect(targ.origin + arcoffset, newtarget.origin + arcoffset,
                  (targetTeamMates ? 0 : (teamplay ? attacker.team : default_color)));

        Damage(newtarget, attacker, attacker, damage, deathtype, '0 0 0',
               normalize(newtarget.origin - targ.origin) * force);

        arc_damage_recurse(newtarget, attacker, damage, deathtype, arcoffset, range, mul, force,
                          default_color, targetTeamMates, targetFrozen, targetAlive, hitfield);

        if(targetTeamMates)
            sound(newtarget, CHAN_PROJECTILE, "kh/capture.wav", 0.4, ATTN_NORM);
        else
            sound(newtarget, CHAN_PROJECTILE, strcat("misc/arc", ftos(1 + (random() > 0.5)), ".wav"),
                  VOL_BASE, ATTN_NORM * 0.3);
    }

    self = oldself;
}

void arc_damage(entity targ, entity attacker, float damage, float deathtype,
               float range, float mul, float force, float default_color, .float hitfield) {

    float targetTeamMates = 0;
    if(teamplay && targ.team == attacker.team && !targetTeamMates)
        return;

    float targetFrozen = (targ.deadflag == DEAD_FREEZE) && !targetTeamMates;
    float targetAlive = !targetFrozen && !targetTeamMates;

    arc_damage_recurse(targ, attacker, damage, deathtype,
                      attacker.maxs_z * '0 0 0.5', range, mul, force, default_color,
                      targetTeamMates, targetFrozen, targetAlive, hitfield);

    entity e; for(e = world; (e = findfloat(e, hitfield, TRUE));)
        e.hitfield = FALSE;
}

