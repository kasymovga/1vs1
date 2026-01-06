.entity race_ghost;
entity race_ghost_best;
entity race_ghost_best_session;
float race_ghost_best_updated;
float sv_cts_ghost;
#define RACE_GHOST_TIC 0.04

entity(void) race_ghost_spawn {
	entity e = spawn();
	e.lip = buf_create();
	e.cnt = 1;
	return e;
}

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

entity(entity ghost) race_ghost_refcounter_decrease { //always return NULL
	if not(ghost) return NULL;
	ghost.cnt--;
	if (ghost.cnt <= 0) {
		buf_del(ghost.lip);
		str_unzone_ifneeded(ghost.message);
		remove(ghost);
	}
	return NULL;
}

entity(entity ghost) race_ghost_refcounter_increase {
	ghost.cnt++;
	return ghost;
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
	entity pb = NULL;
	float ghost_type = 0;
	if (pl.race_ghost) {
		pb = pl.race_ghost.aiment;
		ghost_type = pl.race_ghost.weapon;
	}
	pl.race_ghost = race_ghost_refcounter_decrease(pl.race_ghost);
	pl.race_ghost = race_ghost_spawn();
	pl.race_ghost.aiment = pb;
	pl.race_ghost.weapon = ghost_type;
	entity e = NULL;
	if (ghost_type == 0) {
		e = race_ghost_best_session;
	} else if (ghost_type == 1) {
		e = race_ghost_best;
	} else if (ghost_type == 2) {
		e = pb;
	}
	if (e) {
		pl.race_ghost.enemy = race_ghost_refcounter_increase(e);
		setmodel(pl.race_ghost, "models/player/grunt.dpm");
		pl.race_ghost.frame = 8;
		pl.race_ghost.customizeentityforclient = race_ghost_customize;
	}
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
	string d, n, id, tail;
	float t;
	if (race_ghost_best) {
		tail = race_ghost_best.message;
		d = str_car(tail);
		tail = str_cdr(tail);
		id = str_car(tail);
		tail = str_cdr(tail);
		n = uri_unescape(str_car(tail));
		tail = str_cdr(tail);
		t = stof(str_car(tail));
		tail = str_cdr(tail);
		print_to(pl, PRINT_CHAT, "^8* Global CTS Ghost repeating ^7{1}^8's run with a result of ^7{2}^8 (recorded at {3})", n, TIME_ENCODED_TOSTRING(t), d);
	}
	if (race_ghost_best_session) {
		tail = race_ghost_best_session.message;
		d = str_car(tail);
		tail = str_cdr(tail);
		id = str_car(tail);
		tail = str_cdr(tail);
		n = uri_unescape(str_car(tail));
		tail = str_cdr(tail);
		t = stof(str_car(tail));
		tail = str_cdr(tail);
		print_to(pl, PRINT_CHAT, "^8* Session CTS Ghost repeating ^7{1}^8's run with a result of ^7{2}^8 (recorded at {3})", n, TIME_ENCODED_TOSTRING(t), d);
	}
}

void(entity pl, float t) race_ghost_best_session_update {
	race_ghost_best_session = race_ghost_refcounter_decrease(race_ghost_best_session);
	race_ghost_best_session = race_ghost_refcounter_increase(pl.race_ghost);
	race_ghost_best_session.speed = t;
	race_ghost_best_session.message = strcat(
			strftime(TRUE, "%Y-%m-%d_%H:%M"),
			" ", uri_escape((pl.clid == "") ? "<ERROR>" : pl.clid),
			" ", uri_escape((pl.netname == "") ? "<ERROR>" : pl.netname),
			" ", ftos(t));
	entity e;
	CLIENT_FOR_EACH_REAL(e) // print_all will send message to udp chat too, so print_to is better here
		print_to(e, PRINT_CHAT, "^8* ^7Session^8 CTS Ghost updated with ^7{1}^8's result of ^7{2}", pl.netname, TIME_ENCODED_TOSTRING(t), "");

	race_ghost_best_session.message = str_zone_ifneeded(race_ghost_best_session.message);
}

void(entity pl, float t) race_ghost_best_update {
	race_ghost_best_updated = TRUE;
	race_ghost_best = race_ghost_refcounter_decrease(race_ghost_best);
	race_ghost_best = race_ghost_refcounter_increase(pl.race_ghost); //not needed here
	race_ghost_best.speed = t;
	race_ghost_best.message = strcat(
			strftime(TRUE, "%Y-%m-%d_%H:%M"),
			" ", uri_escape((pl.clid == "") ? "<ERROR>" : pl.clid),
			" ", uri_escape((pl.netname == "") ? "<ERROR>" : pl.netname),
			" ", ftos(t));
	entity e;
	CLIENT_FOR_EACH_REAL(e) // print_all will send message to udp chat too, so print_to is better here
		print_to(e, PRINT_CHAT, "^8* ^7Global^8 CTS Ghost updated with ^7{1}^8's result of ^7{2}", pl.netname, TIME_ENCODED_TOSTRING(t), "");

	race_ghost_best.message = str_zone_ifneeded(race_ghost_best.message);
}

void(entity pl, float t) race_ghost_finish {
	if not(pl.race_ghost) return;
	setmodel(pl.race_ghost, "");
	float ghost_type = pl.race_ghost.weapon;
	pl.race_ghost.customizeentityforclient = NULL;
	pl.race_ghost.enemy = race_ghost_refcounter_decrease(pl.race_ghost.enemy);
	if (t < 0) { //easy
		return;
	}
	pl.race_ghost.weapon = 0;
	entity pb = pl.race_ghost.aiment; //increase
	pl.race_ghost.aiment = NULL; //decrease
	if (!race_ghost_best || t < race_ghost_best.speed) {
		race_ghost_best_update(pl, t);
	}
	if (!race_ghost_best_session || t < race_ghost_best_session.speed) {
		race_ghost_best_session_update(pl, t);
	}
	if (!pb || t < pb.speed) {
		pb = race_ghost_refcounter_decrease(pb);
		pb = race_ghost_refcounter_increase(pl.race_ghost);
		pb.speed = t;
	}
	pl.race_ghost = race_ghost_refcounter_decrease(pl.race_ghost);
	pl.race_ghost = race_ghost_spawn();
	pl.race_ghost.aiment = pb; //increase/decrease
	pl.race_ghost.weapon = ghost_type;
}

void(entity pl) race_ghost_clear {
	if (pl.race_ghost) pl.race_ghost.aiment = race_ghost_refcounter_decrease(pl.race_ghost.aiment);
	if (pl.race_ghost) pl.race_ghost.enemy = race_ghost_refcounter_decrease(pl.race_ghost.enemy);
	pl.race_ghost = race_ghost_refcounter_decrease(pl.race_ghost);
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
	if (sv_cts_ghost) {
		float f = fopen(strcat("maps/", mapname, ".ghost"), FILE_READ);
		if (f >= 0) {
			race_ghost_best = race_ghost_spawn();
			string s;
			race_ghost_best.message = str_zone_ifneeded(fgets(f));
			race_ghost_best.speed = stof(str_car(str_cdr(str_cdr(str_cdr(race_ghost_best.message))))); // 4th argument
			while ((s = fgets(f))) {
				bufstr_set(race_ghost_best.lip, race_ghost_best.state, s);
				race_ghost_best.state++;
			}
			fclose(f);
		}
		if (race_ghost_best.state <= 0) { //no data readed
			race_ghost_best = race_ghost_refcounter_decrease(race_ghost_best);
		}
	}
}

void(void) race_ghost_save {
	if (sv_cts_ghost && race_ghost_best && race_ghost_best_updated) {
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

float(string cmd, float argc) race_ghost_cmd {
	if (cmd == "sentcvar" && argc == 3 && argv(1) == "cl_cts_ghost") {
		if not(self.race_ghost) { // dummy for keeping settings
			self.race_ghost = race_ghost_spawn();
		}
		self.race_ghost.weapon = stof(argv(2));
		string s = "";
		if (self.race_ghost.weapon == 0) {
			s = "Session";
		} else if (self.race_ghost.weapon == 1) {
			s = "Global";
		} else if (self.race_ghost.weapon == 2) {
			s = "Personal";
		}
		if (s != "")
			print_to(self, PRINT_CHAT, "^8* You are watching ^7{1}^8 CTS Ghost", s, "", "");

		return TRUE;
	}
	return FALSE;
}
