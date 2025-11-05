.entity race_ghost;
entity race_ghost_best;
float race_ghost_best_updated;
float sv_cts_ghost;
float sv_cts_ghost_save;
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
		str_unzone_ifneeded(ghost.message);
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
	if not(sv_cts_ghost) return;
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

void(entity pl) race_ghost_best_announce {
	if not(race_ghost_best) return;
	string d, n, id, tail;
	float t;
	tail = race_ghost_best.message;
	d = str_car(tail);
	tail = str_cdr(tail);
	id = str_car(tail);
	tail = str_cdr(tail);
	n = uri_unescape(str_car(tail));
	tail = str_cdr(tail);
	t = stof(str_car(tail));
	tail = str_cdr(tail);
	print_to(pl, PRINT_CHAT, "^8* CTS Ghost repeating ^7{1}^8's run with a result of ^7{2}^8 (recorded at {3})", n, TIME_ENCODED_TOSTRING(t), d);
}

void(entity pl, float t) race_ghost_best_update {
	race_ghost_best_updated = TRUE;
	race_ghost_best = pl.race_ghost;
	race_ghost_best.speed = t;
	race_ghost_best.message = strcat(
			strftime(TRUE, "%Y-%m-%d_%H:%M"),
			" ", uri_escape((pl.clid == "") ? "<ERROR>" : pl.clid),
			" ", uri_escape((pl.netname == "") ? "<ERROR>" : pl.netname),
			" ", ftos(t));
	entity e;
	CLIENT_FOR_EACH_REAL(e) // print_all will send message to udp chat too, so print_to is better here
		print_to(e, PRINT_CHAT, "^8* CTS Ghost updated and will repeat ^7{1}^8's run with a result of ^7{2}^8", pl.netname, TIME_ENCODED_TOSTRING(t), "");

	race_ghost_best.message = str_zone_ifneeded(race_ghost_best.message);
	pl.race_ghost = NULL;
}

void(entity pl, float t) race_ghost_finish {
	if not(pl.race_ghost) return;
	setmodel(pl.race_ghost, "");
	pl.race_ghost.customizeentityforclient = NULL;
	if (pl.race_ghost.enemy) {
		race_ghost_refcounter_decrease(pl.race_ghost.enemy);
		pl.race_ghost.enemy = NULL;
	}
	if (t < 0) { //easy
		race_ghost_refcounter_decrease(pl.race_ghost);
		pl.race_ghost = NULL;
		return;
	}
	if not(race_ghost_best) { //easy
		race_ghost_best_update(pl, t);
		return;
	}
	if (t < race_ghost_best.speed) {
		race_ghost_refcounter_decrease(race_ghost_best);
		race_ghost_best_update(pl, t);
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

void(void) race_ghost_init {
	CVAR_CACHE(sv_cts_ghost);
	CVAR_CACHE(sv_cts_ghost_save);
	if (sv_cts_ghost && sv_cts_ghost_save) {
		float f = fopen(strcat("maps/", mapname, ".ghost"), FILE_READ);
		if (f >= 0) {
			race_ghost_best = spawn();
			race_ghost_best.cnt = 1;
			string s;
			race_ghost_best.lip = buf_create();
			race_ghost_best.message = str_zone_ifneeded(fgets(f));
			race_ghost_best.speed = stof(str_car(str_cdr(str_cdr(str_cdr(race_ghost_best.message))))); // 4th argument
			while ((s = fgets(f))) {
				bufstr_set(race_ghost_best.lip, race_ghost_best.state, s);
				race_ghost_best.state++;
			}
			fclose(f);
		}
		if (race_ghost_best.state <= 0) { //no data readed
			race_ghost_refcounter_decrease(race_ghost_best);
		}
	}
}

void(void) race_ghost_save {
	if (sv_cts_ghost && sv_cts_ghost_save && race_ghost_best && race_ghost_best_updated) {
		float f = fopen(strcat("maps/", mapname, ".ghost"), FILE_WRITE);
		if (f >= 0) {
			float i;
			fputs(f, strcat(race_ghost_best.message, "\n"));
			for (i = 0; i < race_ghost_best.state; i++)
				fputs(f, strcat(bufstr_get(race_ghost_best.lip, i), "\n"));

			fclose(f);
		}
	}
}
