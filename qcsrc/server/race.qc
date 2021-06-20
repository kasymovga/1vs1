#define MAX_CHECKPOINTS 255
#define RACE_RECORD "/race100record/"
#define CTS_RECORD "/cts100record/"
// sorry, but using \ in macros breaks line numbers
#define RACE_WRITESPECTATABLE_MSG_ONE_VARNAME(varname,statement) entity varname; varname = msg_entity; FOR_EACH_REALCLIENT(msg_entity) if(msg_entity == varname || (msg_entity.classname == "spectator" && msg_entity.enemy == varname)) statement msg_entity = varname
#define RACE_WRITESPECTATABLE_MSG_ONE(statement) RACE_WRITESPECTATABLE_MSG_ONE_VARNAME(oldmsg_entity, statement)

float g_race;
float g_cts;

float race_teams;
.float race_completed;
float race_completing;
.float race_penalty_accumulator;
.string race_penalty_reason;
.float race_checkpoint; // player: next checkpoint that has to be reached
.float race_laptime;
.entity race_lastpenalty;
.float race_penalty;
.float race_movetime; // for reading
.float race_movetime_frac; // fractional accumulator for higher accuracy (helper for writing)
.float race_movetime_count; // integer accumulator
var .float race_maxspeed;

float g_race_qualifying;

float race_fraglimit;
float race_leadlimit;
float race_timelimit;
float race_defrag;
string race_records_path;

.entity sprite;

float race_checkpoint_records[MAX_CHECKPOINTS];
string race_checkpoint_recordholders[MAX_CHECKPOINTS];
float race_checkpoint_lasttimes[MAX_CHECKPOINTS];
float race_checkpoint_lastlaps[MAX_CHECKPOINTS];
entity race_checkpoint_lastplayers[MAX_CHECKPOINTS];
float race_spawns;
float race_highest_place_spawn; // number of places; a place higher gets spawned at 0
float race_lowest_place_spawn; // where to spawn in qualifying
.float race_place;
void(entity pl, float penalty, string reason) race_impose_penalty_time;
void(void) race_start_completing;
void(entity pl) race_position_remove;
float(entity pl) race_position_used;
void(entity pl) race_position_used_unset;

float race_highest_checkpoint;
float race_timed_checkpoint;

void race_time_clear(entity e);

float ST_RACE_LAPS;
float SP_RACE_LAPS;
float SP_RACE_FASTEST;
float SP_RACE_MAXSPEED;
float SP_RACE_TIME;

float race_records_time[10];
float race_records_speed[10];
string race_records_name[10];

float(string name, float checktime, float _speed) race_records_put;

void(void) race_records_load {
	string s = strcat(mapname, race_records_path);
	string n;
	float t, sp;
	n = db_get(db_server, strcat(s, "netname"));
	t = stof(db_get(db_server, strcat(s, "time")));
	sp = stof(db_get(db_server, strcat(s, "speed")));
	if (t && n != "")
		race_records_put(n, t, sp);

	float i;
	for (i = 1; i < 10; i++) {
		n = db_get(db_server, strcat(s, ftos(i), "/netname"));
		t = stof(db_get(db_server, strcat(s, ftos(i), "/time")));
		sp = stof(db_get(db_server, strcat(s, ftos(i), "/speed")));
		if (t && n != "")
			race_records_put(n, t, sp);
	}
}

void(void) race_records_save {
	float t, sp;
	string n;
	t = race_records_time[0];
	n = race_records_name[0];
	sp = race_records_speed[0];
	db_put(db_server, strcat(mapname, race_records_path, "time"), ftos(t));
	db_put(db_server, strcat(mapname, race_records_path, "netname"), n);
	db_put(db_server, strcat(mapname, race_records_path, "speed"), ftos(sp));
	float i;
	for (i = 1; i < 10; i++) {
		t = race_records_time[i];
		n = race_records_name[i];
		sp = race_records_speed[i];
		db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/time"), ftos(t));
		db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/netname"), n);
		db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/speed"), ftos(sp));
	}
}

float(string name) race_record_delete {
	float i, j, t, sp;
	string n;
	float r = 0;
	for (i = 0; i < 10; i++) {
		n = race_records_name[i];
		if (n == name) {
			str_unzone_ifneeded(n);
			for (j = i; j < 9; j++) {
				n = race_records_name[j + 1];
				t = race_records_time[j + 1];
				sp = race_records_speed[j + 1];
				race_records_name[j] = n;
				race_records_time[j] = t;
				race_records_speed[j] = sp;
			}
			race_records_name[9] = "";
			race_records_time[9] = 0;
			race_records_speed[9] = 0;
			r = 1;
		}
	}
	return r;
}

void(entity to) race_records_send {
	msg_entity = to;
	WriteByte(MSG_ONE, SVC_TEMPENTITY);
	WriteByte(MSG_ONE, NET_TE_CSQC_RACE);
	WriteByte(MSG_ONE, RACE_NET_RECORDS_TABLE);
	float i, t, sp;
	string n;
	for (i = 0; i < 10; i++) {
		n = race_records_name[i];
		t = race_records_time[i];
		sp = race_records_speed[i];
		WriteCoord(MSG_ONE, t);
		WriteShort(MSG_ONE, sp);
		WriteString(MSG_ONE, n);
	}
}

void(string m) race_records_clear {
	entity e;
	float i;
	bprint(strcat("Clearing records for ", m, "\n"));
	if (m == mapname) {
		for (i = 0; i < 10; i++) {
			race_records_name[i] = "";
			race_records_time[i] = 0;
			race_records_speed[i] = 0;
		}
		FOR_EACH_REALCLIENT(e) {
			race_records_send(e);
		}
	} else {
		db_put(db_server, strcat(m, race_records_path, "time"), "");
		db_put(db_server, strcat(m, race_records_path, "netname"), "");
		db_put(db_server, strcat(m, race_records_path, "speed"), "");
		for (i = 1; i < 10; i++) {
			db_put(db_server, strcat(m, race_records_path, ftos(i), "/time"), "");
			db_put(db_server, strcat(m, race_records_path, ftos(i), "/netname"), "");
			db_put(db_server, strcat(m, race_records_path, ftos(i), "/speed"), "");
		}
	}
}

float(string name, float checktime, float _speed) race_records_put {
	float t, i, j, sp;
	string n;
	for (i = 0; i < 10; i++) {
		t = race_records_time[i];
		n = race_records_name[i];
		sp = race_records_speed[i];
		if (!t || t > checktime) {
			race_record_delete(name);
			str_unzone_ifneeded(race_records_name[9]);
			for (j = 8; j >= i; j--) {
				n = race_records_name[j];
				t = race_records_time[j];
				sp = race_records_speed[j];
				race_records_name[j + 1] = n;
				race_records_time[j + 1] = t;
				race_records_speed[j + 1] = sp;
			}
			race_records_name[i] = str_zone_ifneeded(name);
			race_records_time[i] = checktime;
			race_records_speed[i] = _speed;
			return i + 1;
		}
		if (n == name) return FALSE;
	}
	return FALSE;
}

void(void) race_score_setup {
	score_basics(0, 0, FALSE);
	if (race_teams) {
		ST_RACE_LAPS = score_register_team_score("laps", SCORE_FLAG_SORT_PRIO_PRIMARY);
		SP_RACE_LAPS = score_register("laps", SCORE_FLAG_SORT_PRIO_PRIMARY);
		SP_RACE_TIME = score_register("time", SCORE_FLAG_SORT_PRIO_SECONDARY | SCORE_FLAG_LOWER_IS_BETTER | SCORE_FLAG_TIME);
	} else if (g_race_qualifying) {
		SP_RACE_FASTEST = score_register("fastest",   SCORE_FLAG_SORT_PRIO_PRIMARY | SCORE_FLAG_LOWER_IS_BETTER | SCORE_FLAG_TIME);
		SP_RACE_MAXSPEED = score_register("maxspeed",   SCORE_FLAG_SORT_PRIO_SECONDARY);
		race_maxspeed = scores[SP_RACE_MAXSPEED];
	} else {
		//ST_RACE_LAPS = score_register_team_score("laps", 0);
		SP_RACE_LAPS = score_register("laps", SCORE_FLAG_SORT_PRIO_PRIMARY);
		SP_RACE_TIME = score_register("time", SCORE_FLAG_SORT_PRIO_SECONDARY | SCORE_FLAG_LOWER_IS_BETTER | SCORE_FLAG_TIME);
	}
}

float(float f) race_checkpoint_next {
	if (f >= race_highest_checkpoint)
		return 0;
	else
		return f + 1;
}

float(float f) race_checkpoint_previous {
	if(f == -1)
		return 0;
	else if(f == 0)
		return race_highest_checkpoint;
	else
		return f - 1;
}

// encode as:
//   0 = common start/finish
// 254 = start
// 255 = finish
float(float f) race_checkpoint_id {
	if (race_timed_checkpoint) {
		if (f == 0)
			return 254; // start
		else if (f == race_timed_checkpoint)
			return 255; // finish
	}
	return f;
}

void(entity e, float spec) race_checkpoint_next_send { // qualifying only
	float recordtime;
	string recordholder;
	float cp;
	if not(e.race_laptime)
		return;

	cp = e.race_checkpoint;
	recordtime = race_checkpoint_records[cp];
	recordholder = race_checkpoint_recordholders[cp];
	if(recordholder == e.netname)
		recordholder = "";

	if not(spec)
		msg_entity = e;
	else
		msg_entity = self;

	RACE_WRITESPECTATABLE_MSG_ONE({
		WriteByte(MSG_ONE, SVC_TEMPENTITY);
		WriteByte(MSG_ONE, NET_TE_CSQC_RACE);
		if (spec) {
			WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_NEXT_SPEC_QUALIFYING);
			WriteCoord(MSG_ONE, time - e.race_movetime - e.race_penalty_accumulator);
		} else
			WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_NEXT_QUALIFYING);

		WriteByte(MSG_ONE, race_checkpoint_id(cp)); // checkpoint the player will be at next
		net_write_int24(MSG_ONE, TIME_ENCODE(recordtime));
		WriteString(MSG_ONE, recordholder);
	});
}

void(void) race_InitSpectator {
	if (g_race_qualifying) {
		if (self.enemy.race_laptime)
			race_checkpoint_next_send(self.enemy, 1);
		else
			race_time_clear(self);
	}
}

void(void) race_respawn_delayed {
	if (self.enemy.classname == "player")
	if (self.enemy.health >= 1)
	if (self.enemy.playerid == self.playerid) {
		entity oldself = self;
		self = self.enemy;
		client_put();
		self = oldself;
	}
	remove(self);
}

void(entity e, float cp, float t, float tvalid) race_time_send {
	float snew, l;
	entity p;
	if (g_race_qualifying)
		t += e.race_penalty_accumulator;

	t = TIME_ENCODE(t); // make integer
	// adding just 0.4 so it rounds down in the .5 case (matching the timer display)
	if (tvalid)
	if (cp == race_timed_checkpoint) { // finish line
		if not(e.race_completed) {
			float s;
			if (g_race_qualifying) {
				s = score_player_add(e, SP_RACE_FASTEST, 0);
				if (!s || t < s)
					score_player_add(e, SP_RACE_FASTEST, t - s);
			} else {
				s = score_player_add(e, SP_RACE_TIME, 0);
				snew = TIME_ENCODE(time - map_starttime);
				score_player_add(e, SP_RACE_TIME, snew - s);
				l = score_player_team_add(e, SP_RACE_LAPS, ST_RACE_LAPS, 1);
				if (cvar("fraglimit"))
					if (l >= cvar("fraglimit"))
						race_start_completing();

				if (race_completing) {
					e.race_completed = 1;
					PLAYER_MAKE_INDEPENDENT(e);
					bprint(e.netname, "^7 has finished the race.\n");
				}
			}
		}
		if (race_defrag) {
			entity e2 = spawn();
			e2.think = race_respawn_delayed;
			e2.nextthink = time + 1;
			e2.enemy = e;
			e2.playerid = e.playerid;
		}
	}
	float recordtime;
	string recordholder;
	if (g_race_qualifying) {
		if (tvalid) {
			recordtime = race_checkpoint_records[cp];
			recordholder = strcat1(race_checkpoint_recordholders[cp]); // make a tempstring copy, as we'll possibly strunzone it!
			if (recordholder == e.netname)
				recordholder = "";

			if (t != 0)
			if (t < recordtime || recordtime == 0) {
				race_checkpoint_records[cp] = t;
				if (race_checkpoint_recordholders[cp])
					strunzone(race_checkpoint_recordholders[cp]);

				race_checkpoint_recordholders[cp] = strzone(e.netname);
				FOR_EACH_REALPLAYER(p)
					if (p.race_checkpoint == cp)
						race_checkpoint_next_send(p, 0);
			}
			if (cp == race_timed_checkpoint) {
				if (race_position_used(e)) {
					sprint(e, "\{1}^3Save/retore position was used, time not counted\n");
				} else {
					float position = race_records_put(e.netname, t, e.scorekeeper.race_maxspeed);
					if (position) {
						chat_say(world, 0, world, strcat(e.netname, "^7 take place #", ftos(position), " with ", TIME_ENCODED_TOSTRING(t), " on ", mapname , "\n"), 0);
						if (position == 1)
							announce(e, "announcer/male/amazing.wav", "^31st place!");
						else if (position == 2)
							announce(e, "announcer/male/awesome.wav", "^52st place!");
						else if (position == 2)
							announce(e, "announcer/male/impressive.wav", "^23st place!");
						else
							announce(e, "announcer/male/impressive.wav", "^2New record!");

						entity e3;
						FOR_EACH_REALCLIENT(e3) {
							race_records_send(e3);
						}
					}
				}
			}
		} else {
			// dummies
			t = 0;
			recordtime = 0;
			recordholder = "";
		}
		msg_entity = e;
		RACE_WRITESPECTATABLE_MSG_ONE_VARNAME(dummy1, {
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, NET_TE_CSQC_RACE);
			WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_HIT_QUALIFYING);
			WriteByte(MSG_ONE, race_checkpoint_id(cp)); // checkpoint the player now is at
			net_write_int24(MSG_ONE, TIME_ENCODE(t)); // time to that intermediate
			net_write_int24(MSG_ONE, TIME_ENCODE(recordtime)); // previously best time
			WriteString(MSG_ONE, recordholder); // record holder
		});
	} else { // RACE! Not Qualifying
		float lself, lother, othtime;
		entity oth;
		oth = race_checkpoint_lastplayers[cp];
		if (oth) {
			lself = score_player_add(e, SP_RACE_LAPS, 0);
			lother = race_checkpoint_lastlaps[cp];
			othtime = race_checkpoint_lasttimes[cp];
		} else
			lself = lother = othtime = 0;

		msg_entity = e;
		RACE_WRITESPECTATABLE_MSG_ONE_VARNAME(dummy2, {
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, NET_TE_CSQC_RACE);
			WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_HIT_RACE);
			WriteByte(MSG_ONE, race_checkpoint_id(cp)); // checkpoint the player now is at
			if(e == oth) {
				net_write_int24(MSG_ONE, 0);
				WriteByte(MSG_ONE, 0);
				WriteString(MSG_ONE, "");
			} else {
				net_write_int24(MSG_ONE, TIME_ENCODE(time - race_checkpoint_lasttimes[cp]));
				WriteByte(MSG_ONE, lself - lother);
				WriteString(MSG_ONE, oth.netname); // record holder
			}
		});
		race_checkpoint_lastplayers[cp] = e;
		race_checkpoint_lasttimes[cp] = time;
		race_checkpoint_lastlaps[cp] = lself;
		msg_entity = oth;
		RACE_WRITESPECTATABLE_MSG_ONE_VARNAME(dummy3, {
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, NET_TE_CSQC_RACE);
			WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_HIT_RACE_BY_OPPONENT);
			WriteByte(MSG_ONE, race_checkpoint_id(cp)); // checkpoint the player now is at
			if(e == oth) {
				net_write_int24(MSG_ONE, 0);
				WriteByte(MSG_ONE, 0);
				WriteString(MSG_ONE, "");
			} else {
				net_write_int24(MSG_ONE, TIME_ENCODE(time - othtime));
				WriteByte(MSG_ONE, lother - lself);
				WriteString(MSG_ONE, e.netname); // record holder
			}
		});
	}
}

void(entity e) race_time_clear {
	e.race_checkpoint = -1;
	e.race_laptime = 0;
	e.race_movetime = e.race_movetime_frac = e.race_movetime_count = 0;
	e.race_penalty_accumulator = 0;
	e.race_lastpenalty = world;
	msg_entity = e;
	RACE_WRITESPECTATABLE_MSG_ONE({
		WriteByte(MSG_ONE, SVC_TEMPENTITY);
		WriteByte(MSG_ONE, NET_TE_CSQC_RACE);
		WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_CLEAR); // next
	});
}

void(void) race_checkpoint_passed {
	string oldmsg;
	/*
	 * Trigger targets
	 */
	if not(self.spawnflags & 2) {
		activator = other;
		oldmsg = self.message;
		self.message = "";
		trigger_use_targets();
		self.message = oldmsg;
	}
	if(other.classname != "player")
		return;

	if (other.race_checkpoint == -1 || other.race_checkpoint == self.race_checkpoint || (race_defrag && other.race_checkpoint < self.race_checkpoint && other.race_checkpoint)) {
		if(self.race_penalty) {
			if(other.race_lastpenalty != self) {
				other.race_lastpenalty = self;
				race_impose_penalty_time(other, self.race_penalty, self.race_penalty_reason);
			}
		}
		if(other.race_penalty)
			return;

		/*
		 * Trigger targets
		 */
		if(self.spawnflags & 2) {
			activator = other;
			oldmsg = self.message;
			self.message = "";
			trigger_use_targets();
			self.message = oldmsg;
		}
		if (race_defrag) {
			entity e;
			float shift_required = FALSE;
			for (e = find(world, classname, "race_trigger_checkpoint"); e; e = find(e, classname, "race_trigger_checkpoint")) {
				if (e != self)
				if (e.race_checkpoint) //ignore start triggers
				if (e.race_checkpoint == self.race_checkpoint) {
					if (self.spawnflags == 9) {
						if (e.spawnflags != 9) {
							if (e.sprite)
								remove(e.sprite);

							remove(e);
						}
					} else {
						shift_required = TRUE;
						break;
					}
				}
			}
			if (shift_required) {
				for (e = find(world, classname, "race_trigger_checkpoint"); e; e = find(e, classname, "race_trigger_checkpoint")) {
					if (e != self)
					if (e.race_checkpoint >= self.race_checkpoint)
						e.race_checkpoint = e.race_checkpoint + 1;
				}
				race_timed_checkpoint += 1;
				race_highest_checkpoint += 1;
			}
		}
		other.race_checkpoint = race_checkpoint_next(self.race_checkpoint);
		race_time_send(other, self.race_checkpoint, other.race_movetime, !!other.race_laptime);
		if(!self.race_checkpoint) { // start line
			other.race_laptime = time;
			other.race_movetime = other.race_movetime_frac = other.race_movetime_count = 0;
			race_position_used_unset(other);
			if (g_race_qualifying)
				score_player_set(other, SP_RACE_MAXSPEED, 0);

			other.race_penalty_accumulator = 0;
			other.race_lastpenalty = world;
		}
		if(g_race_qualifying)
			race_checkpoint_next_send(other, 0);
	} else if(other.race_checkpoint == race_checkpoint_next(self.race_checkpoint)) {
		// ignored
	} else {
		if(self.spawnflags & 4)
			damage (other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
	}
}

void(void) race_trigger_checkpoint_touch {
	TRIGGER_EXACT_TOUCH;
	race_checkpoint_passed();
}

void(void) race_trigger_checkpoint_use {
	if (other.classname == "info_player_deathmatch") // a spawn, a spawn
		return;

	other = activator;
	race_checkpoint_passed();
}

float(entity e) race_waypointsprite_visible_for_player {
	if(e.race_checkpoint == -1)
		return TRUE;
	else if(e.race_checkpoint == self.owner.race_checkpoint)
		return TRUE;
	else
		return FALSE;
}

float race_trigger_checkpoint_verified;
void(void) race_trigger_checkpoint_verify {
	entity oldself, cp;
	float i, p;
	float qual;
	if (race_trigger_checkpoint_verified)
		return;

	race_trigger_checkpoint_verified = 1;
	qual = g_race_qualifying;
	oldself = self;
	self = spawn();
	self.classname = "player";
	if (g_race) {
		for (i = 0; i <= race_highest_checkpoint; ++i) {
			self.race_checkpoint = race_checkpoint_next(i);
			// race only (middle of the race)
			g_race_qualifying = 0;
			self.race_place = 0;
			if (!spawn_filter_out_of_bad_spots(findchain(classname, "info_player_deathmatch"), world, 0, FALSE))
				error(strcat("Checkpoint ", ftos(i), " misses a spawnpoint with race_place==", ftos(self.race_place), " (used for respawning in race) - bailing out"));

			if (i == 0) {
				// qualifying only
				g_race_qualifying = 1;
				self.race_place = race_lowest_place_spawn;
				if (!spawn_filter_out_of_bad_spots(findchain(classname, "info_player_deathmatch"), world, 0, FALSE))
					error(strcat("Checkpoint ", ftos(i), " misses a spawnpoint with race_place==", ftos(self.race_place), " (used for qualifying) - bailing out"));

				// race only (initial spawn)
				g_race_qualifying = 0;
				for (p = 1; p <= race_highest_place_spawn; ++p) {
					self.race_place = p;
					if (!spawn_filter_out_of_bad_spots(findchain(classname, "info_player_deathmatch"), world, 0, FALSE))
						error(strcat("Checkpoint ", ftos(i), " misses a spawnpoint with race_place==", ftos(self.race_place), " (used for initially spawning in race) - bailing out"));
				}
			}
		}
	} else {
		// qualifying only
		self.race_checkpoint = race_checkpoint_next(0);
		g_race_qualifying = 1;
		self.race_place = race_lowest_place_spawn;
		if (!spawn_filter_out_of_bad_spots(findchain(classname, "info_player_deathmatch"), world, 0, FALSE))
			error(strcat("Checkpoint ", ftos(self.race_checkpoint), " misses a spawnpoint with race_place==", ftos(self.race_place), " (used for qualifying) - bailing out"));
	}
	g_race_qualifying = qual;
	if (race_timed_checkpoint)
		for (cp = world; (cp = find(cp, classname, "race_trigger_checkpoint")); )
			if (cp.sprite) {
				if (cp.race_checkpoint == 0)
					WaypointSprite_UpdateSprites(cp.sprite, "race-start", "", "");
				else if (cp.race_checkpoint == race_timed_checkpoint && !race_defrag)
					WaypointSprite_UpdateSprites(cp.sprite, "race-finish", "", "");
				else if (race_defrag && cp.spawnflags == 9)
					WaypointSprite_UpdateSprites(cp.sprite, "race-finish", "", "");
			}
	remove(self);
	self = oldself;
}

void(void) spawnfunc_race_trigger_checkpoint {
	vector o;
	if (!g_race && !g_cts) {
		remove(self);
		return;
	}
	trigger_solid_brush_init();
	self.use = race_trigger_checkpoint_use;
	if not(self.spawnflags & 1)
		self.touch = race_trigger_checkpoint_touch;

	o = (self.absmin + self.absmax) * 0.5;
	trace_box(o, PL_MIN, PL_MAX, o - '0 0 1' * (o_z - self.absmin_z), TRACE_MOVE_NORMAL, self);
	waypoint_spawnforitem_force(self, trace_endpos);
	self.nearestwaypointtimeout = time + 1000000000;
	if (!self.message)
		self.message = "went backwards";

	if (!self.message2)
		self.message2 = "was pushed backwards by";

	if (!self.race_penalty_reason)
		self.race_penalty_reason = "missing a checkpoint";

	self.race_checkpoint = self.cnt;
	if(self.race_checkpoint > race_highest_checkpoint) {
		race_highest_checkpoint = self.race_checkpoint;
		if (self.spawnflags & 8)
			race_timed_checkpoint = self.race_checkpoint;
		else
			race_timed_checkpoint = 0;
	}
	if (!self.race_penalty) {
		if (self.race_checkpoint)
			WaypointSprite_SpawnFixed("race-checkpoint", o, self, sprite);
		else
			WaypointSprite_SpawnFixed("race-finish", o, self, sprite);
	}
	self.sprite.waypointsprite_visible_for_player = race_waypointsprite_visible_for_player;
	entity_initialize(self, race_trigger_checkpoint_verify, INITPRIO_FINDTARGET);
}

void(entity p) race_abandon_check {
	if (race_completing && !p.race_completed) {
		p.race_completed = 1;
		PLAYER_MAKE_INDEPENDENT(p);
		bprint(p.netname, "^7 has abandoned the race.\n");
	}
}

void(void) race_start_completing {
	entity p;
	race_completing = 1;
	FOR_EACH_PLAYER(p)
		if (p.deadflag != DEAD_NO)
			race_abandon_check(p);
}

void(void) race_player_prepare {
	race_time_clear(self);
	self.race_place = 0;
}

void(void) race_player_retract {
	self.race_checkpoint = race_checkpoint_previous(self.race_checkpoint);
	if(self.race_checkpoint == 0)
	{
		race_time_clear(self);
		self.race_checkpoint = 0;
	}
}

var void(float killed) race_player_clear_next;
void(float killed) race_player_clear {
	if (killed)
		race_abandon_check(self);

	if (self.classname == "disconnecting")
		race_position_remove(self);

	race_player_clear_next(killed);
}

entity() race_client_put_spawn_point {
	if(self.killcount == -666 || g_race_qualifying)
		race_player_prepare();

	race_abandon_check(self);
	return spawn_select(FALSE);
}

var void(entity spot) race_spawn_next;
void(entity spot) race_spawn {
	if (self.killcount != -666 && !g_race_qualifying) {
		if (spot.target == "")
			// let the player run without timing, if he did not spawn at a targetting spawnpoint
			race_player_prepare();
		else
			race_player_retract();
	}
	if (spot.target != "" && self.race_checkpoint == -1)
		self.race_checkpoint = 0;

	self.race_place = 0;
	race_spawn_next(spot);
}

var void() race_observer_spawn_next;
void() race_observer_spawn {
	race_player_prepare();
	race_observer_spawn_next();
}

void(void) spawnfunc_race_info_player {
	if (!g_race && !g_cts) {
		remove(self);
		return;
	}
	++race_spawns;
	spawnfunc_info_player_deathmatch();
	if (self.race_place > race_highest_place_spawn)
		race_highest_place_spawn = self.race_place;

	if (self.race_place < race_lowest_place_spawn)
		race_lowest_place_spawn = self.race_place;
}

void(void) race_checkpoints_records_clear {
	float i;
	entity e;
	for (i = 0; i < MAX_CHECKPOINTS; ++i) {
		race_checkpoint_records[i] = 0;
		if (race_checkpoint_recordholders[i])
			strunzone(race_checkpoint_recordholders[i]);

		race_checkpoint_recordholders[i] = NULL;
	}
	FOR_EACH_CLIENT(e)
		race_time_clear(e);
}

void() race_world_reset {
	float s;
	score_nice_print(world);
	race_checkpoints_records_clear();
	score_sort(race_place);
	entity e;
	FOR_EACH_CLIENT(e) {
		if (e.race_place) {
			s = score_player_add(e, SP_RACE_FASTEST, 0);
			if (!s)
				e.race_place = 0;
		}
		print(e.netname, " = ", ftos(e.race_place), "\n");
	}
	if (g_race_qualifying == 2) {
		g_race_qualifying = 0;
		player_independent = 0;
		cvar_set("fraglimit", ftos(race_fraglimit));
		cvar_set("leadlimit", ftos(race_leadlimit));
		cvar_set("timelimit", ftos(race_timelimit));
		race_score_setup();
	}
}

void(entity pl, float penalty, string reason) race_impose_penalty_time {
	if (g_race_qualifying) {
		pl.race_penalty_accumulator += penalty;
		msg_entity = pl;
		RACE_WRITESPECTATABLE_MSG_ONE({
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, NET_TE_CSQC_RACE);
			WriteByte(MSG_ONE, RACE_NET_PENALTY_QUALIFYING);
			WriteShort(MSG_ONE, TIME_ENCODE(penalty));
			WriteString(MSG_ONE, reason);
		});
	} else {
		pl.race_penalty = time + penalty;
		msg_entity = pl;
		RACE_WRITESPECTATABLE_MSG_ONE_VARNAME(dummy, {
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, NET_TE_CSQC_RACE);
			WriteByte(MSG_ONE, RACE_NET_PENALTY_RACE);
			WriteShort(MSG_ONE, TIME_ENCODE(penalty));
			WriteString(MSG_ONE, reason);
		});
	}
}

void(void) race_trigger_penalty_touch {
	TRIGGER_EXACT_TOUCH;
	if (other.race_lastpenalty != self) {
		other.race_lastpenalty = self;
		race_impose_penalty_time(other, self.race_penalty, self.race_penalty_reason);
	}
}

void(void) race_trigger_penalty_use {
	race_impose_penalty_time(activator, self.race_penalty, self.race_penalty_reason);
}

void(void) spawnfunc_race_trigger_penalty {
	trigger_solid_brush_init();
	self.use = race_trigger_penalty_use;
	if not(self.spawnflags & 1)
		self.touch = race_trigger_penalty_touch;

	if (!self.race_penalty_reason)
		self.race_penalty_reason = "missing a checkpoint";

	if (!self.race_penalty)
		self.race_penalty = 5;
}

float() race_PlayerAllowedToMove {
	if (self.race_penalty)
		if (time > self.race_penalty)
			self.race_penalty = 0;

	if (self.race_penalty)
		return FALSE;

	return TRUE;
}

var float(entity plr, float wep) race_PlayerCanFire_NextLink;
float race_PlayerCanFire(entity plr, float wep) {
	if (time < plr.race_penalty)
		return FALSE;

	return race_PlayerCanFire_NextLink(plr, wep);
}

void() race_PhysicFrameBegin {
	vector wishvel;
	float wishspeed, f;
	// if record times matter
	// ensure nothing EVIL is being done (i.e. strafebot)
	// this hinders joystick users though
	// but it still gives SOME analog control
	// TODO implement this for engine cl_movement code too (basically, clipping to the four axes)
	wishvel_x = fabs(self.movement_x);
	wishvel_y = fabs(self.movement_y);
	if(wishvel_x != 0 && wishvel_y != 0 && wishvel_x != wishvel_y)
	{
		wishvel_z = 0;
		wishspeed = vlen(wishvel);
		if(wishvel_x >= 2 * wishvel_y)
		{
			// pure X motion
			if(self.movement_x > 0)
				self.movement_x = wishspeed;
			else
				self.movement_x = -wishspeed;
			self.movement_y = 0;
		}
		else if(wishvel_y >= 2 * wishvel_x)
		{
			// pure Y motion
			self.movement_x = 0;
			if(self.movement_y > 0)
				self.movement_y = wishspeed;
			else
				self.movement_y = -wishspeed;
		}
		else
		{
			// diagonal
			if(self.movement_x > 0)
				self.movement_x = 0.70710678118654752440 * wishspeed;
			else
				self.movement_x = -0.70710678118654752440 * wishspeed;
			if(self.movement_y > 0)
				self.movement_y = 0.70710678118654752440 * wishspeed;
			else
				self.movement_y = -0.70710678118654752440 * wishspeed;
		}
	}
	self.race_movetime_frac += frametime;
	f = floor(self.race_movetime_frac);
	self.race_movetime_frac -= f;
	self.race_movetime_count += f;
	self.race_movetime = self.race_movetime_frac + self.race_movetime_count;
	if (g_race_qualifying) {
		vector v = self.velocity;
		v_z = 0;
		float maxspeed = vlen(v);
		if (self.scorekeeper)
		if (maxspeed > self.scorekeeper.race_maxspeed)
			score_player_set(self, SP_RACE_MAXSPEED, maxspeed);
	}
}

float(float fraglimit) race_winning_condition_non_qualifying {
	entity p;
	float n, c;
	n = 0;
	c = 0;
	FOR_EACH_PLAYER(p) {
		++n;
		if (p.race_completed)
			++c;
	}
	if (n && (n == c))
		return TRUE;

	return score_winning_condition(fraglimit, 0);
}

float(float fraglimit, float ignore) race_winning_condition {
	if not(g_race_qualifying)
		return race_winning_condition_non_qualifying(fraglimit);
	else if (g_race_qualifying == 1)
		return score_winning_condition(fraglimit, 0);

	return FALSE;
}

float() race_OvertimeHandle {
	if (g_race_qualifying == 2) {
		float totalplayers;
		float playerswithlaps;
		float readyplayers;
		entity head;
		totalplayers = playerswithlaps = readyplayers = 0;
		FOR_EACH_PLAYER(head) {
			++totalplayers;
			if(score_player_add(head, SP_RACE_FASTEST, 0))
				++playerswithlaps;

			if(head.ready)
				++readyplayers;
		}
		// at least 2 of the players have completed a lap: start the RACE
		// otherwise, the players should end the qualifying on their own
		if (readyplayers || playerswithlaps >= 2) {
			checkrules_suddendeathend = 0;
			ready_restart(); // go to race
			return TRUE;
		}
	}
	if (!checkrules_suddendeathend) {
		checkrules_suddendeathend = time + 60 * cvar("timelimit_suddendeath");
		if (g_race && !g_race_qualifying)
			race_start_completing();
	}
	return TRUE;
}

float race_SpawnPointGood(entity spot) {
	if (race_spawns)
		if (spot.target == "")
			return FALSE;

	if (spot.target == "")
		return TRUE;

	entity ent;
	float good = FALSE, found = FALSE;
	ent = find(world, targetname, spot.target);
	while (ent) {
		if (ent.classname == "race_trigger_checkpoint") {
			found = 1;
			if (self.classname == "player") { // spectators may spawn everywhere
				if (g_race_qualifying) {
					// spawn at first
					if (ent.race_checkpoint != 0)
						return FALSE;

					if (spot.race_place != race_lowest_place_spawn)
						return FALSE;
				} else {
					if (ent.race_checkpoint != race_checkpoint_previous(self.race_checkpoint))
						return FALSE;

					float pl;
					pl = self.race_place;
					if (pl > race_highest_place_spawn)
						pl = 0;

					if (spot.race_place != pl)
						return FALSE;
				}
			}
			good = 1;
		}
		ent = find(ent, targetname, spot.target);
	}
	if (found && !good)
		return FALSE;

	return TRUE;
}

var void(float remain_frags) race_score_winning_condition_countdown_orig;
void(float remain_frags) race_score_winning_condition_countdown {
	if (g_race)
	if not(g_race_qualifying)
		race_score_winning_condition_countdown_orig(remain_frags);
}

float(float f) race_KillDelayMod {
	if (g_race_qualifying)
		return 0;

	return f;
}

string(string s) race_SuddenDeathMod {
	if (g_race_qualifying)
		return s;

	return "^3Everyone, finish your lap! The race is over!";
}

float() race_WarmupAllowed {
	if (g_race_qualifying == 2)
		return FALSE;

	return TRUE;
}

string() race_client_fix_cvars {
	return "cl_cmd settemp cl_movecliptokeyboard 2";
}

string(string bspname) race_world_record_for_map {
	string recid = (g_race ? RACE_RECORD : CTS_RECORD);
	float r = stof(db_get(db_server, strcat(bspname, recid, "time")));
	if (r == 0)
		return strcat(strpad(16, bspname), " ", "--:--.-- -\n");

	string n = strreplace("\n", " ", db_get(db_server, strcat(bspname, recid, "netname")));
	return strcat(strpad(16, bspname), " ", strpad(-8, TIME_ENCODED_TOSTRING(r)), " ", n, "\n");
}

float() race_ReadyAllowed {
	return (g_race_qualifying == 2);
}

float() race_ClearScoresAllowed {
	return g_race_qualifying;
}

float() race_TelefragsAllowed {
	return FALSE;
}

float() race_ready_restart_hard {
	return race_completing;
}

void(void) race_qualifying_limits {
	cvar_set("fraglimit", "0");
	cvar_set("leadlimit", "0");
	cvar_set("timelimit", cvar_string("g_race_qualifying_timelimit"));
}

void(void) spawnfunc_race_target_init {
	self.weapons = player_start_weapons;
	self.health = player_start_health;
	self.armorvalue = player_start_armorvalue;
	self.ammo_shells = player_start_ammo_shells;
	self.ammo_nails = player_start_ammo_nails;
	self.ammo_rockets = player_start_ammo_rockets;
	self.ammo_cells = player_start_ammo_cells;
	self.ammo_fuel = player_start_ammo_fuel;
	self.items = player_start_items;
	spawnfunc_target_items();
}

void(void) spawnfunc_race_target_start_timer {
	if (gametype != GAMETYPE_CTS) {
		remove(self);
		return;
	}
	race_defrag = TRUE;
	self.cnt = 0;
	self.spawnflags = 1;
	self.classname = "race_trigger_checkpoint";
	self.target = ""; //workaround for some broken defrag maps
	spawnfunc_race_trigger_checkpoint();
}

void(void) spawnfunc_race_target_stop_timer {
	if (gametype != GAMETYPE_CTS) {
		remove(self);
		return;
	}
	race_defrag = TRUE;
	self.cnt = 1;
	self.spawnflags = 9;
	self.classname = "race_trigger_checkpoint";
	self.target = ""; //workaround for some broken defrag maps
	race_timed_checkpoint = 1;
	race_highest_checkpoint = 1;
	spawnfunc_race_trigger_checkpoint();
}

void(void) spawnfunc_race_target_checkpoint {
	if (gametype != GAMETYPE_CTS) {
		remove(self);
		return;
	}
	race_defrag = TRUE;
	self.cnt = 1;
	self.spawnflags = 1;
	self.classname = "race_trigger_checkpoint";
	self.target = ""; //workaround for some broken defrag maps
	spawnfunc_race_trigger_checkpoint();
}

var void(void) race_shutdown_next;
void(void) race_shutdown {
	race_records_save();
	race_shutdown_next();
}

var void(void) race_client_real_connect_next;
void(void) race_client_real_connect {
	race_records_send(self);
	race_client_real_connect_next();
}

var float(string cmd, float argc) race_cmd_game_handle_next;
float(string cmd, float argc) race_cmd_game_handle {
	if (cmd == "clear_records") {
		string m;
		if (argc > 1)
			m = argv(1);
		else
			m = mapname;

		race_records_clear(m);
		return TRUE;
	}
	return race_cmd_game_handle_next(cmd, argc);
}

entity(entity pl) race_position_find {
	entity e;
	for (e = find(world, classname, "race_position"); e; e = find(e, classname, "race_position")) {
		if (e.owner == pl)
			return e;
	}
	return world;
}

void(entity pl) race_position_used_unset {
	entity e = race_position_find(pl);
	if (e) e.cnt = 0;
}

float(entity pl) race_position_used {
	entity e = race_position_find(pl);
	if (e)
		return e.cnt;

	return 0;
}

void(entity pl) race_position_remove {
	entity e = race_position_find(pl);
	if (e) remove(e);
}

void(entity pl) race_position_create {
	if (pl.classname != "player") {
		sprint(pl, "\{1}^1You need join game first!\n");
		return;
	}
	race_position_remove(pl);
	entity e = spawn();
	entity oldself = self;
	self = e;
	spectator_copy(pl);
	self = oldself;
	e.classname = "race_position";
	e.owner = pl;
	e.race_completed = pl.race_completed;
	e.race_penalty_accumulator = pl.race_penalty_accumulator;
	e.race_penalty_reason = pl.race_penalty_reason;
	e.race_checkpoint = pl.race_checkpoint;
	e.race_laptime = pl.race_laptime;
	e.race_lastpenalty = pl.race_lastpenalty;
	e.race_penalty = pl.race_penalty;
	e.race_movetime = pl.race_movetime;
	e.race_movetime_frac = pl.race_movetime_frac;
	e.race_movetime_count = pl.race_movetime_count;
	e.race_maxspeed = pl.race_maxspeed;
	e.cnt = 1;
	sprint(pl, "\{1}^2Position was saved\n");
}

void(entity pl) race_position_restore {
	if (pl.classname != "player") {
		sprint(pl, "\{1}^1You need join game first!\n");
		return;
	}
	entity e = race_position_find(pl);
	if (e) {
		setorigin(pl, e.origin);
		entity oldself = self;
		self = pl;
		spectator_copy(e);
		self = oldself;
		pl.race_completed = e.race_completed;
		pl.race_penalty_accumulator = e.race_penalty_accumulator;
		pl.race_penalty_reason = e.race_penalty_reason;
		pl.race_checkpoint = e.race_checkpoint;
		pl.race_laptime = e.race_laptime;
		pl.race_lastpenalty = e.race_lastpenalty;
		pl.race_penalty = e.race_penalty;
		pl.race_movetime = e.race_movetime;
		pl.race_movetime_frac = e.race_movetime_frac;
		pl.race_movetime_count = e.race_movetime_count;
		pl.race_maxspeed = e.race_maxspeed;
		if (pl.race_laptime)
			race_checkpoint_next_send(pl, 1);
		else
			race_time_clear(pl);

		e.cnt = 1;
		sprint(pl, "\{1}^2Position was restored\n");
		return;
	}
	sprint(pl, "\{1}^1No saved position found!\n");
}

var float(string cmd, float argc) race_cmd_client_handle_next;
float(string cmd, float argc) race_cmd_client_handle {
	if (cmd == "saveposition") {
		race_position_create(self);
		return TRUE;
	}
	if (cmd == "restoreposition") {
		race_position_restore(self);
		return TRUE;
	}
	return race_cmd_client_handle_next(cmd, argc);
}

var void(void(string item, string cmd) send_item) race_gamemenu_send_next;
void race_gamemenu_send(void(string item, string cmd) send_item) {
	send_item("Respawn", "kill;");
	send_item("Map records...", "cl_cmd recordlist;");
	send_item("Save position", "cmd saveposition;");
	send_item("Restore position", "cmd restoreposition;");
	race_gamemenu_send_next(send_item);
}

void(void) race_init {
	if (gametype == GAMETYPE_RACE) {
		float qualifying_override = cvar("g_race_qualifying_timelimit_override");
		g_race = 1;
		if (cvar("g_race_teams")) {
			team_play_activate();
			race_teams = bound(2, cvar("g_race_teams"), 4);
			team_teams_set_count(race_teams);
		} else
			race_teams = 0;

		if (qualifying_override >= 0)
			cvar_set("g_race_qualifying_timelimit", ftos(qualifying_override));

		if (g_campaign) {
			g_race_qualifying = 1;
		} else {
			if (cvar("g_race_qualifying_timelimit") > 0) {
				race_fraglimit = cvar("fraglimit");
				race_leadlimit = cvar("leadlimit");
				race_timelimit = cvar("timelimit");
				defer(0, race_qualifying_limits);
				g_race_qualifying = 2;
			} else
				g_race_qualifying = 0;
		}
		race_records_path = RACE_RECORD;
	}
	if (gametype == GAMETYPE_CTS) {
		g_cts = 1;
		g_race_qualifying = 1;
		race_records_path = CTS_RECORD;
		race_gamemenu_send_next = gamehook_chain_gamemenu_send;
		gamehook_chain_gamemenu_send = race_gamemenu_send;
		race_cmd_client_handle_next = gamehook_chain_cmd_client_handle;
		gamehook_chain_cmd_client_handle = race_cmd_client_handle;
	}
	if (g_race_qualifying) {
		player_independent = 1;
		race_records_load();
		race_shutdown_next = gamehook_chain_shutdown;
		gamehook_chain_shutdown = race_shutdown;
		race_client_real_connect_next = gamehook_chain_client_connect_real;
		gamehook_chain_client_connect_real = race_client_real_connect;
	}
	if (g_race) {
		gamehook_winning_condition = race_winning_condition;
		gamehook_OvertimeHandle = race_OvertimeHandle;
		gamehook_WarmupAllowed = race_WarmupAllowed;
		gamehook_ClearScoreAllowed = race_ClearScoresAllowed;
	}
	race_score_setup();
	gamehook_InitSpectator = race_InitSpectator;
	gamehook_world_reset = race_world_reset;
	gamehook_PlayerAllowedToMove = race_PlayerAllowedToMove;
	race_PlayerCanFire_NextLink = gamehook_chain_PlayerCanFire;
	gamehook_chain_PlayerCanFire = race_PlayerCanFire;
	gamehook_PhysicFrameBegin = race_PhysicFrameBegin;
	gamehook_client_put_spawn_point = race_client_put_spawn_point;
	race_spawn_next = gamehook_chain_spawn;
	gamehook_chain_spawn = race_spawn;
	race_player_clear_next = gamehook_chain_player_clear;
	gamehook_chain_player_clear = race_player_clear;
	race_observer_spawn_next = gamehook_chain_observer_spawn;
	gamehook_chain_observer_spawn = race_observer_spawn;
	gamehook_SpawnPointGood = race_SpawnPointGood;
	race_score_winning_condition_countdown_orig = gamehook_score_winning_condition_countdown;
	gamehook_score_winning_condition_countdown = race_score_winning_condition_countdown;
	gamehook_client_fix_cvars = race_client_fix_cvars;
	gamehook_world_record_for_map = race_world_record_for_map;
	gamehook_ReadyAllowed = race_ReadyAllowed;
	gamehook_TelefragsAllowed = race_TelefragsAllowed;
	gamehook_ready_restart_hard = race_ready_restart_hard;
	gamehook_havocbot_role_choose = race_role_choose;
	gamehook_SuddenDeathMessageMod = race_SuddenDeathMod;
	race_cmd_game_handle_next = gamehook_chain_cmd_game_handle;
	gamehook_chain_cmd_game_handle = race_cmd_game_handle;
}
