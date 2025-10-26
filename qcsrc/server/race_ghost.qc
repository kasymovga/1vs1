.entity race_ghost;
entity race_ghost_best;
#define RACE_GHOST_TIC 0.04

string(string s, float n) race_ghost_pad_right {
	float l = strlen(s);
	float pad = n - l;
	if (pad <= 0) return s;
	return strcat(s, substring("          ", 0, pad));
}

string(vector o) race_ghost_vector_to_string {
	return strcat(
			race_ghost_pad_right(ftos(floor(o_x + 0.5)), 7),
			race_ghost_pad_right(ftos(floor(o_y + 0.5)), 7),
			race_ghost_pad_right(ftos(floor(o_z + 0.5)), 7));
}

void(entity ghost) race_ghost_refcounter_decrease {
	ghost.cnt--;
	if (ghost.cnt <= 0) {
		buf_del(ghost.lip);
		remove(ghost);
		if (ghost == race_ghost_best) {
			race_ghost_best = NULL;
		}
	}
}

void(entity ghost) race_ghost_refcounter_increase {
	ghost.cnt++;
}

float(void) race_ghost_customize {
	entity o;
	if (SPECTATOR_IS_SPECTATOR(other))
		o = SPECTATOR_SPECTATEE(other);
	else
		o = other;

	if (self != o.race_ghost) return FALSE;
	self.alpha = min(0.33, max(vlen(self.origin - o.origin) / 500, 0.05));
	return TRUE;
}

void(entity pl) race_ghost_start {
	if (pl.race_ghost) { //just in case
		race_ghost_refcounter_decrease(pl.race_ghost);
	}
	pl.race_ghost = spawn();
	pl.race_ghost.lip = buf_create();
	if (race_ghost_best) {
		pl.race_ghost.enemy = race_ghost_best;
		race_ghost_refcounter_increase(race_ghost_best);
		setmodel(pl.race_ghost, "models/player/grunt.dpm");
		pl.race_ghost.frame = 8;
		pl.race_ghost.customizeentityforclient = race_ghost_customize;
	}
	pl.race_ghost.cnt = 1;
}

void(entity pl) race_ghost_record_add {
	float ln = floor(pl.race_ghost.state / 640);
	pl.race_ghost.state++;
	string record_str = race_ghost_vector_to_string(pl.origin);
	record_str = strcat(record_str, race_ghost_pad_right(ftos(floor(pl.angles_y + 0.5)), 4));
	bufstr_set(pl.race_ghost.lip, ln, strcat(bufstr_get(pl.race_ghost.lip, ln), record_str));
}

void(entity ghost, entity ghost_body, float pos) race_ghost_record_read {
	float pos_floor = min(floor(pos), max(0, ghost.state - 1));
	float pos_ceil = min(ceil(pos), max(0, ghost.state - 1));
	float f = pos - pos_floor;
	float ln = floor(pos_floor / 640);
	float lp = math_mod(pos_floor, 640);
	string record_str = substring(bufstr_get(ghost.lip, ln), lp * 25, 25);
	vector o1;
	o1_x = stof(substring(record_str, 0, 7));
	o1_y = stof(substring(record_str, 7, 7));
	o1_z = stof(substring(record_str, 14, 7));
	float a1 = stof(substring(record_str, 21, 4));
	ln = floor(pos_ceil / 640);
	lp = math_mod(pos_ceil, 640);
	record_str = substring(bufstr_get(ghost.lip, ln), lp * 25, 25);
	vector o2;
	o2_x = stof(substring(record_str, 0, 7));
	o2_y = stof(substring(record_str, 7, 7));
	o2_z = stof(substring(record_str, 14, 7));
	float a2 = stof(substring(record_str, 21, 4));
	float a = (a1 * (1 - f) + a2 * f);
	vector o = (o1 * (1 - f) + o2 * f);
	ghost_body.angles_y = a;
	setorigin(ghost_body, o);
}

void(entity pl) race_ghost_finish {
	if not(pl.race_ghost) return; //just in case
	setmodel(pl.race_ghost, "");
	pl.race_ghost.customizeentityforclient = NULL;
	if (pl.race_ghost.enemy) {
		race_ghost_refcounter_decrease(pl.race_ghost.enemy);
		pl.race_ghost.enemy = NULL;
	}
	if not(race_ghost_best) { //easy
		race_ghost_best = pl.race_ghost;
		pl.race_ghost = NULL;
		return;
	}
	if (pl.race_ghost.state < race_ghost_best.state) {
		race_ghost_refcounter_decrease(race_ghost_best);
		race_ghost_best = pl.race_ghost;
		pl.race_ghost = NULL;
	} else {
		race_ghost_refcounter_decrease(pl.race_ghost);
		pl.race_ghost = NULL;
	}
}

void(entity pl, float time) race_ghost_process {
	if not(pl.race_ghost) return;
	float pos = floor(time / RACE_GHOST_TIC);
	while (pl.race_ghost.state < pos) {
		race_ghost_record_add(pl);
	}
	if (pl.race_ghost.enemy) {
		float pos_read = (time + sys_ticrate + pl.ping * 0.001) / RACE_GHOST_TIC;
		race_ghost_record_read(pl.race_ghost.enemy, pl.race_ghost, pos_read);
	}
}
