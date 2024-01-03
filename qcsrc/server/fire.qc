float g_balance_firetransfer_damage;
float g_balance_firetransfer_time;
.float fire_damagepersec;
.float fire_endtime;
.float fire_deathtype;
.entity fire_owner;
.float fire_hitsound;
.entity fire_burner;
void(void) fire_burner_think;
#define FIRE_RM_TICRATE 0.2

float(entity e) fire_is_burning {
	return (time < e.fire_endtime);
}

float(entity e, entity o, float d, float t, float dt) fire_add_damage {
	float dps;
	float maxtime, mintime, maxdamage, mindamage, maxdps, mindps, totaldamage, totaltime;
	if (e.classname == "player" && e.deadflag) {
		return -1;
	} else {
		if (!e.fire_burner) {
			// print("adding a fire burner to ", e.classname, "\n");
			e.fire_burner = spawn();
			e.fire_burner.classname = "fireburner";
			e.fire_burner.think = fire_burner_think;
			e.fire_burner.nextthink = time;
			e.fire_burner.owner = e;
		}
	}
	t = max(t, 0.1);
	dps = d / t;
	if (fire_is_burning(e)) {
		mintime = e.fire_endtime - time;
		maxtime = max(mintime, t);
		mindps = e.fire_damagepersec;
		maxdps = max(mindps, dps);
		if (maxtime > mintime || maxdps > mindps) {
			mindamage = mindps * mintime;
			maxdamage = mindamage + d;
			// interval [mintime, maxtime] * [mindps, maxdps]
			// intersected with
			// [mindamage, maxdamage]
			// maximum of this!
			if (maxdamage >= maxtime * maxdps) {
				totaltime = maxtime;
				totaldamage = maxtime * maxdps;
				// this branch increases totaldamage if either t > mintime, or dps > mindps
			} else {
				// maxdamage is inside the interval!
				// first, try to use mindps; only if this fails, increase dps as needed
				totaltime = min(maxdamage / mindps, maxtime); // maxdamage / mindps >= mindamage / mindps = mintime
				totaldamage = maxdamage;
				// can totaldamage / totaltime be >= maxdps?
				// max(mindps, maxdamage / maxtime) >= maxdps?
				// we know maxdamage < maxtime * maxdps
				// so it cannot be
				// this branch ALWAYS increases totaldamage, but requires maxdamage < maxtime * maxdps
			}
			// total conditions for increasing:
			//     maxtime > mintime OR maxdps > mindps OR maxtime * maxdps > maxdamage
			// however:
			//     if maxtime = mintime, maxdps = mindps
			// then:
			//     maxdamage = mindamage + d
			//     mindamage = mindps * mintime = maxdps * maxtime < maxdamage!
			// so the last condition is not needed
			e.fire_damagepersec = totaldamage / totaltime;
			e.fire_endtime = time + totaltime;
			if (totaldamage > 1.2 * mindamage) {
				e.fire_deathtype = dt;
				if (e.fire_owner != o) {
					e.fire_owner = o;
					e.fire_hitsound = FALSE;
				}
			}
			return max(0, totaldamage - mindamage); // can never be negative, but to make sure
		} else
			return 0;
	} else {
		e.fire_damagepersec = dps;
		e.fire_endtime = time + t;
		e.fire_deathtype = dt;
		e.fire_owner = o;
		e.fire_hitsound = FALSE;
		return d;
	}
}

void(entity e) fire_apply_damage {
	float t, d, hi, ty;
	if not(fire_is_burning(e))
		return;

	// water and slime stop fire
	if (e.waterlevel)
	if (e.watertype != CONTENT_LAVA) {
		e.fire_endtime = 0;
		return;
	}
	RM_ELSE(t = min(FIRE_RM_TICRATE, e.fire_endtime - time), t = min(frametime, e.fire_endtime - time));
	print("t=", ftos(t), "\n");
	d = e.fire_damagepersec * t;
	hi = e.fire_owner.hitsound;
	ty = e.fire_owner.typehitsound;
	damage(e, e, e.fire_owner, d, e.fire_deathtype, e.origin, '0 0 0');
	if (e.fire_hitsound && e.fire_owner) {
		e.fire_owner.hitsound = hi;
		e.fire_owner.typehitsound = ty;
	}
	e.fire_hitsound = TRUE;
	if not(PLAYER_IS_INDEPENDENT(e))
	FOR_EACH_PLAYER(other) if (e != other) {
		if (other.classname == "player")
		if (other.deadflag == DEAD_NO)
		if not(PLAYER_IS_INDEPENDENT(other))
		if (math_boxes_overlap(e.absmin, e.absmax, other.absmin, other.absmax)) {
			t = g_balance_firetransfer_time * (e.fire_endtime - time);
			d = g_balance_firetransfer_damage * e.fire_damagepersec * t;
			fire_add_damage(other, e, d, t, DEATH_FIRE);
		}
	}
}

void(entity e) fire_apply_effect {
	if (fire_is_burning(e))
		e.effects |= EFFECT_FLAME;
	else
		e.effects &= ~EFFECT_FLAME;
}

void(void) fire_burner_think {
	// for players, this is done in the regular loop
	if (wasfreed(self.owner) || self.owner.fire_burner != self) {
		remove(self);
		return;
	}
	if not(fire_is_burning(self.owner)) {
		self.owner.fire_burner = world;
		remove(self);
		return;
	}
	if (self.owner.classname != "player")
		fire_apply_effect(self.owner);

	fire_apply_damage(self.owner);
	RM_ELSE(self.nextthink = time + FIRE_RM_TICRATE, self.nextthink = time);
}

void(entity from, entity to) fire_move {
	float t = from.fire_endtime - time;
	if (t > 0) {
		fire_add_damage(to, from.fire_owner, from.fire_damagepersec * t, t, DEATH_FIRE);
		from.fire_endtime = -1;
	}
}

void(void) fire_init {
	CVAR_CACHE(g_balance_firetransfer_damage);
	CVAR_CACHE(g_balance_firetransfer_time);
}
