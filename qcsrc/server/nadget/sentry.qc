float g_nadgets_sentry_beam_range;
float g_nadgets_sentry_beam_dps;
float g_nadgets_sentry_beam_force;
float g_nadgets_sentry_beam_energyrequired;
float g_nadgets_sentry_beam_initialdelay;
float g_nadgets_sentry_beam_amount;
float g_nadgets_sentry_capture_range;
float g_nadgets_sentry_capture_damage_delay;
float g_nadgets_sentry_capture_speed;
//float g_nadgets_sentry_disown_on_death; //in nadgets.qc for some reason
float g_nadgets_sentry_health;
float g_nadgets_sentry_health_degenerate_when_damaged;
float g_nadgets_sentry_energy_regen;
float g_nadgets_sentry_levitation;
float g_nadgets_sentry_damagefactor;
float g_nadgets_sentry_damagefactor_nadgets;
float g_nadgets_sentry_repairfactor;
float g_nadgets_sentry_repairfactor_nadgets;
float g_nadgets_sentry_shock_damage;
float g_nadgets_sentry_shock_force;
float g_nadgets_sentry_shock_energy_cost;
float g_nadgets_sentry_shock_energy_cost;
float g_nadgets_sentry_friction;
float g_nadgets_sentry_pushfactor;
float g_nadgets_sentry_rot;
float g_nadgets_sentry_rot_pause;
float g_nadgets_sentry_adept_shock_energy_cost;
float g_nadgets_sentry_adept_shock_arc;
float g_nadgets_sentry_adept_shock_arc_range;
float g_nadgets_sentry_adept_shock_arc_force;

.float spawntime;

float nadget_Sentry_TargetIsTaken(entity emitter, entity targ) {
	entity e;
    for(e = emitter.owner.hg_sentry_emitter_next; e; e = e.hg_sentry_emitter_next)
        if(e != emitter && e.enemy == targ)
            return TRUE;
    return FALSE;
}

float nadget_Sentry_TargetIsValid(entity emitter, entity e) {
    entity sentry = emitter.owner;

    if(!sentry.realowner)
        return FALSE;

    if(PLAYER_DEAD(e))
        return FALSE;

    if(!team_is_different_teams(e, sentry.realowner) && !RM_BUFFS_PRESENT(sentry.realowner, RM_BUFFS_MEDIC))
        return FALSE;

    if(nadget_Sentry_TargetIsTaken(emitter, e))
        return FALSE;

    vector o = sentry.origin + sentry.view_ofs;
    vector t = e.origin + e.view_ofs;

    if(vlen(o - t) > g_nadgets_sentry_beam_range)
        return FALSE;

    trace_line(o, t, TRACE_MOVE_NORMAL, sentry);

    if(trace_ent != e)
        return FALSE;

    return TRUE;
}

entity nadget_Sentry_FindTarget(entity emitter) {
    entity sentry = emitter.owner;

    entity targ = NULL, p;
    float mindist, dist;
	float diffteam, medicflag;
    vector t, o = sentry.origin + sentry.view_ofs;

    mindist = g_nadgets_sentry_beam_range;

    if(!sentry.realowner)
        return world;

	medicflag = RM_BUFFS_PRESENT(sentry.realowner, RM_BUFFS_MEDIC);
    PLAYER_FOR_EACH(p) if not(PLAYER_DEAD(p)) {
        diffteam = (p != sentry.realowner && team_is_different_teams(sentry, p));
		if (!diffteam && !medicflag)
			continue;

        if(nadget_Sentry_TargetIsTaken(emitter, p))
            continue;

		t = warpzone_find_nearest_origin(o, p.origin + p.view_ofs, FALSE);
		dist = warpzone_find_nearest_origin_length;
        if(diffteam || (!diffteam && medicflag)) {
            if(dist > mindist)
                continue;
        } else if(dist > g_nadgets_sentry_beam_range)
            continue;

		warpzone_trace_line(o, t, TRACE_MOVE_NORMAL, sentry);
        if(trace_ent != p)
            continue;

        mindist = dist;
        targ = p;
    }

    return targ;
}

void nadget_Sentry_Beam_Think(void) {
    entity targ = self.enemy.enemy;
    vector end = targ.origin + targ.view_ofs * (0.5 + 0.5 * sin(time * 5 + num_for_edict(self)));
    vector start = self.owner.origin + self.owner.view_ofs;
    vector end_transformed;
	end = warpzone_find_nearest_origin(start, end, TRUE);
	warpzone_trace_line(start, end, TRACE_MOVE_NORMAL, self);
    targ = trace_ent;
    end_transformed = trace_endpos;
	end = warpzone_untransform_origin(warpzone_trace_transform, trace_endpos);
    if(!self.origin)
        self.origin = end;
    else
        self.origin += (end - self.origin) * frametime * 10;

    end = self.origin;

    if(targ.takedamage == DAMAGE_AIM && time > self.cnt) {
		damage(targ, self, self.owner.realowner, g_nadgets_sentry_beam_dps * 0.1, NADGET_SENTRY, end, g_nadgets_sentry_beam_force * normalize(end_transformed - warpzone_transform_origin(warpzone_trace_transform, start)));
        self.cnt = time + 0.1; // FIXME: this is inaccurate
    }

    end -= normalize(end - start) * 5;

    if(start != self.pos1) {
        self.pos1 = start;
        self.SendFlags |= 2;
    }

    if(end != self.pos2) {
        self.pos2 = end;
        self.SendFlags |= 4;
    }

    self.nextthink = time;
}

entity nadget_Sentry_Beam_Spawn(entity emitter) {
    entity e = spawn(), sentry = emitter.owner;
    e.classname = "hg_sentry_beam";
    e.owner = sentry;
    e.enemy = emitter;
    e.team = sentry.team;
    e.pos1 = sentry.origin + sentry.view_ofs;
    e.pos2 = e.pos1;
    e.think = nadget_Sentry_Beam_Think;
    e.nextthink = time;

    net_link_entity(e, FALSE, 0, weapon_zapper_beam_send);

    return e;
}

void nadget_Sentry_Emitter_Think() {
	entity sentry = self.owner;

	if(time < sentry.cnt || sentry.hg_sentry_energy < g_nadgets_sentry_beam_energyrequired) {
		if(self.zapper_beam)
			remove(self.zapper_beam);
		self.zapper_beam = world;
		self.enemy = world;
	} else if(!self.zapper_beam) {
		if(!nadget_Sentry_TargetIsValid(self, self.enemy))
			self.enemy = world;

		if(!self.enemy)
			self.enemy = nadget_Sentry_FindTarget(self);

		if(self.enemy)
			self.zapper_beam = nadget_Sentry_Beam_Spawn(self);
	} else {
		if(self.enemy && !nadget_Sentry_TargetIsValid(self, self.enemy))
			self.enemy = nadget_Sentry_FindTarget(self);

		if(!self.enemy) {
			remove(self.zapper_beam);
			self.zapper_beam = world;
			self.enemy = world;
		}
	}

	self.nextthink = time;
}

void(void) nadget_sentry_emitter_on_remove {
	if (self.zapper_beam)
		remove(self.zapper_beam);
}

entity nadget_Sentry_Emitter_Spawn(entity sentry) {
    entity e = spawn();
    e.classname = "hg_sentry_emitter";
    e.owner = sentry;
    e.origin = sentry.origin + sentry.view_ofs;
    e.think = nadget_Sentry_Emitter_Think;
    e.nextthink = time;
    e.entremove = nadget_sentry_emitter_on_remove;
	return e;
}

void nadget_Sentry_Interrupt_Capture(void) {
	if(self.hg_sentry_capture_pb) {
		progressbar_remove(self.hg_sentry_capture_pb);
		self.hg_sentry_capture_pb = world;
	}
    self.hg_sentry_capture_player = world;
    self.hg_sentry_capture_progress = 0;
}

void nadget_Sentry_SetOwner(entity sentry, entity newowner) {
    nadget_Waypoint_Remove(sentry.hg_waypoint);

    sentry.team = (team_mode ? newowner.team : 0);
    sentry.colormap = num_for_edict(newowner);
    sentry.aiment.colormap = sentry.colormap;

    if(newowner) {
        sentry.skin = 0;
        sentry.aiment.effects &= ~EFFECT_NODRAW;
        sentry.aiment.color = '0.3 0.3 0.3' + 0.7 * team_color((team_mode ? sentry.team : COLOR_TEAM3));
        sentry.bot_attack = TRUE;
    } else {
        sentry.skin = 1;
        sentry.aiment.effects |= EFFECT_NODRAW;
        sentry.bot_attack = FALSE;
    }

    if(sentry.realowner.classname == "player")
        sentry.realowner.hg_detonables -= 1;

    sentry.realowner = newowner;
    sentry.aiment.realowner = newowner;

    if(newowner) {
        newowner.hg_detonables += 1;
		print_to_spec(newowner, PRINT_CENTER, "^3You have claimed a ^1{1}^3!", nadget_TypeToExpandedName(NADGET_SENTRY), "", "");
    }
}

void(void) nadget_sentry_on_remove {
	entity_drop_entities(self);
	nadget_Sentry_Interrupt_Capture();
	if (self.realowner.classname == "player")
		self.realowner.hg_detonables -= 1;

	if (self.hg_waypoint)
		marker_Disown(self.hg_waypoint, 0.5);

	if (self.aiment) {
		sound_stop(self.aiment, CHAN_PROJECTILE);
		stdproc_remove_entity(self.aiment);
	}
	entity e = NULL;
    for(e; (e = find(e, classname, "hg_sentry_emitter"));)
		if(e.owner == self)
			stdproc_remove_entity(e);

	if (self.hg_sentry_capture_pb)
		remove(self.hg_sentry_capture_pb);
}

void nadget_Sentry_Explode(void) {
	effect_blast(self.origin + self.view_ofs);
	self.solid = SOLID_NOT;
	self.think = stdproc_remove;
	self.nextthink = time;
}

void nadget_Sentry_Levitate(void) {
    // oscillation effect
    // FIXME: doesn't work properly without g_nadgets_sentry_levitation
    // TODO: maybe move this to CSQC

    float shift = 0;
	if (g_nadgets_sentry_levitation)
	for(shift = 0; shift < MATH_PI * 2; shift += 0.1) {
        vector new_origin = self.origin + frametime * '0 0 8' * sin(self.spawntime + time + self.phase + shift);
        trace_box(new_origin, self.mins, self.maxs, new_origin, TRACE_MOVE_NORMAL, self);

        if(!trace_startsolid) {
            setorigin(self, new_origin);
            break;
        }
    }

    self.phase += shift;

    // dampen velocity to prevent the sentry from moving forever, i.e. after being hook-dragged.
    self.velocity = self.velocity * (1 - frametime * g_nadgets_sentry_friction);

    if(g_nadgets_sentry_levitation && g_nadgets_sentry_pushfactor) {
        // this hack is used to benefit from the "step" elevation of MOVETYPE_WALK while dragging a levitating sentry.
        // very low .gravaity is assigned to the sentry at spawn, which makes it seem like the sentry is still floating while being dragged.

        if(self.pushltime - (time + g_maxpushtime) > frametime) {
            // hook not attached
            self.movetype = MOVETYPE_FLY;
        } else {
            // hook attached
            self.movetype = MOVETYPE_WALK;
        }
    }
}

void nadget_Sentry_Orphaned_Think(void) {
    entity e;

    nadget_Sentry_Levitate();

    if(self.hg_sentry_capture_player) {
        e = self.hg_sentry_capture_player;

        if (e.classname != "player" || PLAYER_DEAD(e) || time - e.lastdamage < g_nadgets_sentry_capture_damage_delay || vlen(e.origin - self.origin) > g_nadgets_sentry_capture_range)
            nadget_Sentry_Interrupt_Capture();
        else {
            trace_line(self.origin, e.origin, TRACE_MOVE_NOMONSTERS, self);
            if(trace_fraction < 1)
                nadget_Sentry_Interrupt_Capture();
        }
    }

    if(!self.hg_sentry_capture_player) PLAYER_FOR_EACH(e) {
        if(PLAYER_DEAD(e))
            continue;

        if(time - e.lastdamage < g_nadgets_sentry_capture_damage_delay || vlen(e.origin - self.origin) > g_nadgets_sentry_capture_range)
            continue;

        trace_line(self.origin, e.origin, TRACE_MOVE_NOMONSTERS, self);
        if(trace_fraction < 1)
            continue;

        self.hg_sentry_capture_player = e;
		if not(self.hg_sentry_capture_pb)
			self.hg_sentry_capture_pb = progressbar_create("Capturing", e);

        break;
    }

    if(self.hg_sentry_capture_player) {
        e = self.hg_sentry_capture_player;

        self.hg_sentry_capture_progress = approach(self.hg_sentry_capture_progress, 1.0, g_nadgets_sentry_capture_speed * frametime);
        progressbar_set(self.hg_sentry_capture_pb, self.hg_sentry_capture_progress);
		bot_stay(e, 0);
        if(self.hg_sentry_capture_progress == 1) {
            nadget_Sentry_SetOwner(self, e);
            nadget_Sentry_Interrupt_Capture();
        }
        //self.hg_sentry_capture_player.buff_stealth_time = time;
    }
}

void nadget_Sentry_Think(void) {
    entity o = self.realowner;

    nadget_Sentry_Levitate();

    if(o && ((team_mode && self.team != o.team) || !o.iscreature))
        o = world;

    if(!o || PLAYER_DEAD(o)) {
        if(g_nadgets_sentry_disown_on_death /* && roundstate == ROUNDSTATE_GAME */) {
            nadget_Sentry_SetOwner(self, world);
        } else if(!o) {
            nadget_Sentry_Explode();
            return;
        }
    }

	if(self.health < g_nadgets_sentry_health)
		self.health -= frametime * g_nadgets_sentry_health_degenerate_when_damaged;

	if (g_nadgets_sentry_rot && time > self.pauserothealth_finished)
		self.health -= g_nadgets_sentry_rot * frametime;

    if(self.health <= 0) {
        nadget_Sentry_Explode();
        return;
    }

    if(self.health < g_nadgets_sentry_health) {
        self.effects |= EFFECT_FLAME;
    } else {
        self.effects &= ~EFFECT_FLAME;
    }

    self.hg_sentry_energy = approach(self.hg_sentry_energy, 1, frametime * g_nadgets_sentry_energy_regen);

    if(self.realowner)
        nadget_Waypoint();
    else
        nadget_Sentry_Orphaned_Think();

    setorigin(self.aiment, self.origin + self.view_ofs);
    self.aiment.scale = bound(0.01, self.hg_sentry_energy, 1);
    self.aiment.light_lev = 100 + self.aiment.scale * 200;
    self.nextthink = time;
}

void nadget_Sentry_Damage(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) {
    if(!self.realowner || team_is_different_teams(attacker, self.realowner)) {
        if(DEATH_ISNADGET(deathtype))
            _damage *= g_nadgets_sentry_damagefactor_nadgets;
        else
            _damage *= g_nadgets_sentry_damagefactor;

        self.health = bound(0, self.health - _damage, self.health);
    } else {
        if(DEATH_ISNADGET(deathtype))
            _damage *= g_nadgets_sentry_repairfactor_nadgets;
        else
            _damage *= g_nadgets_sentry_repairfactor;

        heal(self, inflictor, attacker, _damage, 0, g_nadgets_sentry_health, 0, deathtype, 0, 0, hitloc, '0 0 0');
		self.pauserothealth_finished = time + g_nadgets_sentry_rot_pause;
    }

    if(self.health <= 0)
        nadget_Sentry_Explode();
}

void nadget_Sentry_MEODP_Death(entity attacker, entity inflictor) {
	nadget_Sentry_Explode();
}

void nadget_Sentry_Trigger(void) {
    entity e, aimtarg, aimtransform;
    vector o, aimloc, aimloc_untransformed;

    makevectors(self.v_angle);
	antilag_begin(self);
    weapon_setup_shot(self, 0, "", -1);
    o = weapon_shotorg;
	warpzone_trace_line(o, o + weapon_shotdir * WORLD_MAX_SHOT_DISTANCE, TRACE_MOVE_NORMAL, self);
    while(trace_ent && trace_ent.classname == "hg_sentry" && !team_is_different_teams(trace_ent, self))
        warpzone_trace_line(trace_endpos + weapon_shotdir, trace_endpos + weapon_shotdir * WORLD_MAX_SHOT_DISTANCE, TRACE_MOVE_NORMAL, self);

    aimloc = trace_endpos;
    aimtarg = trace_ent;
    aimtransform = warpzone_trace_transform;
	aimloc_untransformed = warpzone_untransform_origin(aimtransform, aimloc);
    float c_dmg = g_nadgets_sentry_shock_damage;
    float c_frc = g_nadgets_sentry_shock_force;
    float c_cost;
	if(RM_BUFFS_PRESENT(self, RM_BUFFS_ADEPT))
		c_cost = g_nadgets_sentry_adept_shock_energy_cost;
	else
		c_cost = g_nadgets_sentry_shock_energy_cost;

    float found = 0, triggered = 0;
    for(e = world; (e = find(e, classname, "hg_sentry"));) if(e.realowner == self) {
        ++found;

        if(e.hg_sentry_energy < c_cost)
            continue;

        o = e.origin + e.view_ofs;

        #define IS_GOOD_HIT (vlen(trace_endpos - aimloc) < 1 || (aimtarg && aimtarg.takedamage && trace_ent == aimtarg))

		warpzone_trace_line(o, aimloc + normalize(aimloc - o), TRACE_MOVE_NORMAL, self);
		entity targ = ((trace_fraction < 1) ? trace_ent : world);
        if(!IS_GOOD_HIT) {
            // Aiming through a warpzone, sentry can hit directly
			warpzone_trace_line(o, aimloc, TRACE_MOVE_NORMAL, self);
        }
        entity wz = warpzone_chain_begin;
        while(!IS_GOOD_HIT && wz) {
            // Sentry can hit neither directly nor through the warpzone we aimed through (if any).
            // Let's see if we can hit through another warpzone.
			warpzone_trace_line(o, warpzone_untransform_origin(wz, aimloc), TRACE_MOVE_NORMAL, self);
            wz = wz.warpzone_chain;
        }
        if(IS_GOOD_HIT) {
			vector end_visual = warpzone_untransform_origin(warpzone_trace_transform, trace_endpos);
            vector dir = normalize(end_visual - o);
            vector endpos = trace_endpos;
            float noimpact = (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT);
            vector force = c_frc * dir;
			if (targ)
				damage(targ, self, self, c_dmg, NADGET_SENTRY | HITTYPE_SECONDARY, endpos, force);

            sound(e, CHAN_WEAPON, ((random() > 0.5) ? "misc/arc1.wav": "misc/arc2.wav"), VOL_BASE, ATTN_NORM);
            weapon_zapper_attack2_effect((team_mode ? self.team : COLOR_TEAM3), o, end_visual);
			if(targ.takedamage && RM_BUFFS_PRESENT(self, RM_BUFFS_ADEPT)) {
				if(g_nadgets_sentry_adept_shock_arc) {
					arc_damage(targ, self, c_dmg, NADGET_SENTRY | HITTYPE_SECONDARY | HITTYPE_BOUNCE,
						g_nadgets_sentry_adept_shock_arc_range, g_nadgets_sentry_adept_shock_arc,
						g_nadgets_sentry_adept_shock_arc_force, COLOR_TEAM3, sentry_arc_hit
					);
				}
			}
			if (targ.solid == SOLID_BSP && !noimpact) {
				effect_impact(endpos, c_dmg, 0, 0, force, WEAPON_ZAPPER | HITTYPE_SECONDARY, self);
			}
            e.hg_sentry_energy = bound(0, e.hg_sentry_energy - c_cost, 1);
            ++triggered;
        }

        #undef IS_GOOD_HIT
    }
	antilag_end();

    if(triggered)
        sound(self, CHAN_WEAPON2, "weapons/rocket_mode.wav", VOL_BASE, ATTN_NORM);
    else if(found)
        sound(self, CHAN_WEAPON2, "weapons/unavailable.wav", VOL_BASE, ATTN_NORM);
}

NADGET_HOOKFUNCTION(sentry, Attack) {
    vector o = self.origin;

    entity e = spawn();
    setmodel(e, "models/rtzsentry.iqm");
    setsize(e, NADGET_SENTRY_MINS, NADGET_SENTRY_MAXS);
    setorigin(e, o);

    if(!entity_move_out_of_solid(e)) {
        remove(e);
		RM_ELSE({rm_bigprint_spec(self, "Can't put a sentry here!", "", 1);},
				{print_to_spec(self, PRINT_CENTER, "Can't put a sentry here!", "", "", "");})
        return NADGET_ATTACK_FAIL_COOLDOWN;
    }

	e.spawnorigin = e.origin;
    e.classname = "hg_sentry";
    e.team = self.team;
    e.realowner = self; // can't use owner here because we want to be blocked by it
    e.solid = SOLID_BBOX;
    e.movetype = (g_nadgets_sentry_levitation ? MOVETYPE_FLY : (g_nadgets_sentry_pushfactor ? MOVETYPE_WALK : MOVETYPE_TOSS));
    e.angles = '0 360 0' * random();
    e.reset = stdproc_remove;
    e.think = nadget_Sentry_Think;
    e.pauserothealth_finished = time + g_nadgets_sentry_rot_pause;
    e.nextthink = time;
    e.hg_type = NADGET_SENTRY;
    e.view_ofs = '0 0 100';
    e.takedamage = DAMAGE_AIM;
    e.colormap = num_for_edict(e.realowner);
    e.health = g_nadgets_sentry_health;
    e.event_damage = nadget_Sentry_Damage;
    e.cnt = time + g_nadgets_sentry_beam_initialdelay;
    e.spawntime = time;
    e.damageforcescale = e.pushfactor = g_nadgets_sentry_pushfactor;
    e.entremove = nadget_sentry_on_remove;
	if (e.pushfactor > 0)
		e.touch = push_touch;

    if(g_nadgets_sentry_levitation) {
        // also see nadget_Sentry_Levitate
        e.gravity = 0.001;
    }
    self.hg_detonables += 1;
	rm_buffs_meodp_point_attach(e, nadget_Sentry_MEODP_Death);
    entity c = spawn();
    setmodel(c, "models/ebomb.mdl");
    c.skin = 3;
    c.colormap = e.colormap;
    c.pflags = PFLAGS_FULLDYNAMIC;
    c.color = '0.3 0.3 0.3' + 0.7 * team_color(((self.team > 0) ? self.team : COLOR_TEAM3));
    c.owner = self;
    c.effects |= EFFECT_DOUBLESIDED;
    sound(c, CHAN_PROJECTILE, "weapons/electro_fly.wav", 0.5, 2);

    e.aiment = c;

    entity tail = e;
	float i;
    for(i = 0; i < g_nadgets_sentry_beam_amount; ++i) {
        tail.hg_sentry_emitter_next = nadget_Sentry_Emitter_Spawn(e);
        tail = tail.hg_sentry_emitter_next;
    }

    // TODO: a better sound?
    sound(self, CHAN_PROJECTILE, "weapons/grenade_stick.wav", 1, ATTN_NORM);
    return NADGET_ATTACK_OK;
}

NADGET_HOOKFUNCTION(sentry, Init) {
	CVAR_CACHE(g_nadgets_sentry_beam_range);
	CVAR_CACHE(g_nadgets_sentry_beam_dps);
	CVAR_CACHE(g_nadgets_sentry_beam_force);
	CVAR_CACHE(g_nadgets_sentry_beam_energyrequired);
	CVAR_CACHE(g_nadgets_sentry_beam_initialdelay);
	CVAR_CACHE(g_nadgets_sentry_beam_amount);
	CVAR_CACHE(g_nadgets_sentry_capture_range);
	CVAR_CACHE(g_nadgets_sentry_capture_damage_delay);
	CVAR_CACHE(g_nadgets_sentry_capture_speed);
	//float g_nadgets_sentry_disown_on_death; //in nadgets.qc for some reason
	CVAR_CACHE(g_nadgets_sentry_health);
	CVAR_CACHE(g_nadgets_sentry_health_degenerate_when_damaged);
	CVAR_CACHE(g_nadgets_sentry_energy_regen);
	CVAR_CACHE(g_nadgets_sentry_levitation);
	CVAR_CACHE(g_nadgets_sentry_damagefactor);
	CVAR_CACHE(g_nadgets_sentry_damagefactor_nadgets);
	CVAR_CACHE(g_nadgets_sentry_repairfactor);
	CVAR_CACHE(g_nadgets_sentry_repairfactor_nadgets);
	CVAR_CACHE(g_nadgets_sentry_shock_damage);
	CVAR_CACHE(g_nadgets_sentry_shock_force);
	CVAR_CACHE(g_nadgets_sentry_shock_energy_cost);
	CVAR_CACHE(g_nadgets_sentry_friction);
	CVAR_CACHE(g_nadgets_sentry_pushfactor);
	CVAR_CACHE(g_nadgets_sentry_rot);
	CVAR_CACHE(g_nadgets_sentry_rot_pause);
	CVAR_CACHE(g_nadgets_sentry_adept_shock_energy_cost);
	CVAR_CACHE(g_nadgets_sentry_adept_shock_arc);
	CVAR_CACHE(g_nadgets_sentry_adept_shock_arc_range);
	CVAR_CACHE(g_nadgets_sentry_adept_shock_arc_force);
    return NADGET_INIT_OK;
}
