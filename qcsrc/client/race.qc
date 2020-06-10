// QUALIFYING
float race_checkpoint;
float race_time;
float race_laptime;
float race_checkpointtime;
float race_previousbesttime;
string race_previousbestname;
float race_nextcheckpoint;
float race_nextbesttime;
string race_nextbestname;
float race_penaltyaccumulator; // qualifying: total penalty time in tenths
float race_penaltyeventtime; // time when the player got the penalty
float race_penaltytime; // duration of penalty time, in tenths
string race_penaltyreason; // reason for penalty
// RACE
float race_mycheckpoint;
float race_mycheckpointtime;
float race_mycheckpointdelta;
float race_mycheckpointlapsdelta;
string race_mycheckpointenemy;
float race_othercheckpoint;
float race_othercheckpointtime;
float race_othercheckpointdelta;
float race_othercheckpointlapsdelta;
string race_othercheckpointenemy;
float race_records_time[10];
string race_records_name[10];

void(void) race_read {
	float b;
	b = ReadByte();
	float i;
	switch(b) {
		case RACE_NET_CHECKPOINT_HIT_QUALIFYING:
			race_checkpoint = ReadByte();
			race_time = net_read_int24();
			race_previousbesttime = net_read_int24();
			if (race_previousbestname)
				strunzone(race_previousbestname);

			race_previousbestname = strzone(ReadString());
			race_checkpointtime = max(time, 0.001);
			if (race_checkpoint == 0 || race_checkpoint == 254) {
				race_penaltyaccumulator = 0;
				race_laptime = max(time, 0.001); // valid
			}
			break;
		case RACE_NET_CHECKPOINT_CLEAR:
			race_laptime = 0;
			race_checkpointtime = 0;
			break;
		case RACE_NET_CHECKPOINT_NEXT_SPEC_QUALIFYING:
			race_laptime = ReadCoord();
			race_checkpointtime = -99999;
			// fall through
		case RACE_NET_CHECKPOINT_NEXT_QUALIFYING:
			race_nextcheckpoint = ReadByte();
			race_nextbesttime = net_read_int24();
			if (race_nextbestname)
				strunzone(race_nextbestname);

			race_nextbestname = strzone(ReadString());
			break;
		case RACE_NET_CHECKPOINT_HIT_RACE:
			race_mycheckpoint = ReadByte();
			race_mycheckpointtime = time;
			race_mycheckpointdelta = net_read_int24();
			race_mycheckpointlapsdelta = ReadByte();
			if (race_mycheckpointlapsdelta >= 128)
				race_mycheckpointlapsdelta -= 256;

			if (race_mycheckpointenemy)
				strunzone(race_mycheckpointenemy);

			race_mycheckpointenemy = strzone(ReadString());
			break;
		case RACE_NET_CHECKPOINT_HIT_RACE_BY_OPPONENT:
			race_othercheckpoint = ReadByte();
			race_othercheckpointtime = time;
			race_othercheckpointdelta = net_read_int24();
			race_othercheckpointlapsdelta = ReadByte();
			if (race_othercheckpointlapsdelta >= 128)
				race_othercheckpointlapsdelta -= 256;

			if (race_othercheckpointenemy)
				strunzone(race_othercheckpointenemy);

			race_othercheckpointenemy = strzone(ReadString());
			break;
		case RACE_NET_PENALTY_RACE:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			//race_penaltyaccumulator += race_penaltytime;
			if (race_penaltyreason)
				strunzone(race_penaltyreason);

			race_penaltyreason = strzone(ReadString());
			break;
		case RACE_NET_PENALTY_QUALIFYING:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			race_penaltyaccumulator += race_penaltytime;
			if (race_penaltyreason)
				strunzone(race_penaltyreason);

			race_penaltyreason = strzone(ReadString());
			break;
		case RACE_NET_RECORDS_TABLE:
			for (i = 0; i < 10; i++) {
				race_records_time[i] = ReadCoord();
				race_records_name[i] = str_zone_ifneeded(ReadString());
			}
			break;
	}
}

string(float cp, float mytime, float histime, float lapdelta, string hisname) race_checkpoint_string {
	string col;
	string timestr;
	string cpname;
	string lapstr;
	lapstr = "";
	if (histime == 0) { // goal hit
		if (mytime > 0) {
			timestr = strcat("+", str_float_decimals(+mytime, TIME_DECIMALS));
			col = "^1";
		} else if (mytime == 0) {
			timestr = "+0.0";
			col = "^3";
		} else {
			timestr = strcat("-", str_float_decimals(-mytime, TIME_DECIMALS));
			col = "^2";
		}
		if (lapdelta > 0) {
			lapstr = strcat(" (-", ftos(lapdelta), "L)");
			col = "^2";
		} else if (lapdelta < 0) {
			lapstr = strcat(" (+", ftos(-lapdelta), "L)");
			col = "^1";
		}
	}
	else if (histime > 0) { // anticipation
		if (mytime >= histime)
			timestr = strcat("+", str_float_decimals(mytime - histime, TIME_DECIMALS));
		else
			timestr = TIME_ENCODED_TOSTRING(TIME_ENCODE(histime));

		col = "^3";
	} else
		col = "^7";

	if (cp == 254)
		cpname = "Start line";
	else if (cp == 255)
		cpname = "Finish line";
	else if (cp)
		cpname = strcat("Intermediate ", ftos(cp));
	else
		cpname = "Finish line";

	if (histime < 0)
		return strcat(col, cpname);
	else if (hisname == "")
		return strcat(col, cpname, " (", timestr, ")");
	else
		return strcat(col, cpname, " (", timestr, " ", strcat(hisname, col, lapstr), ")");
}

void(void) race_sbar_draw {
	drawfont = sbar_bigfont;
	float a, t;
	vector m;
	string s, forcetime;
	m = '0.5 0 0' * CVAR(vid_conwidth) + '0 0.25 0' * CVAR(vid_conheight);
	if (race_checkpointtime) {
		a = bound(0, 2 - (time - race_checkpointtime), 1);
		s = "";
		forcetime = "";
		if (a > 0) { // just hit a checkpoint?
			if (race_checkpoint != 254) {
				if (race_time && race_previousbesttime)
					s = race_checkpoint_string(race_checkpoint, TIME_DECODE(race_time) - TIME_DECODE(race_previousbesttime), 0, 0, race_previousbestname);
				else
					s = race_checkpoint_string(race_checkpoint, 0, -1, 0, race_previousbestname);

				if (race_time)
					forcetime = TIME_ENCODED_TOSTRING(race_time);
			}
		} else {
			if (race_laptime && race_nextbesttime && race_nextcheckpoint != 254) {
				a = bound(0, 2 - ((race_laptime + TIME_DECODE(race_nextbesttime)) - (time + TIME_DECODE(race_penaltyaccumulator))), 1);
				if (a > 0) // next one?
					s = race_checkpoint_string(race_nextcheckpoint, (time + TIME_DECODE(race_penaltyaccumulator)) - race_laptime, TIME_DECODE(race_nextbesttime), 0, race_nextbestname);
			}
		}
		if (s != "" && a > 0) {
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			drawcolorcodedstring(m - '0 16 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
		}
		if (race_penaltytime) {
			a = bound(0, 2 - (time - race_penaltyeventtime), 1);
			if (a > 0) {
				s = strcat("^1PENALTY: ", str_float_decimals(race_penaltytime * 0.1, 1), " (", race_penaltyreason, ")");
				dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
				drawcolorcodedstring(m - '0 32 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
			}
		}
		if (forcetime != "") {
			a = bound(0, (time - race_checkpointtime) / 0.5, 1);
			drawstring_expanding(m - '16 0 0' * stringwidth(forcetime, FALSE), forcetime, '32 32 0', '1 1 1', sbar_alpha_fg, 0, a);
		} else
			a = 1;

		if (race_laptime && race_checkpoint != 255) {
			s = TIME_ENCODED_TOSTRING(TIME_ENCODE(time + TIME_DECODE(race_penaltyaccumulator) - race_laptime));
			drawstring(m - '16 0 0' * stringwidth(s, FALSE), s, '32 32 0', '1 1 1', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
		}
	} else {
		if (race_mycheckpointtime) {
			a = bound(0, 2 - (time - race_mycheckpointtime), 1);
			s = race_checkpoint_string(race_mycheckpoint, TIME_DECODE(race_mycheckpointdelta), -!race_mycheckpointenemy, race_mycheckpointlapsdelta, race_mycheckpointenemy);
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			drawcolorcodedstring(m - '0 16 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
		}
		if (race_othercheckpointtime && race_othercheckpointenemy != "") {
			a = bound(0, 2 - (time - race_othercheckpointtime), 1);
			s = race_checkpoint_string(race_othercheckpoint, -TIME_DECODE(race_othercheckpointdelta), -!race_othercheckpointenemy, race_othercheckpointlapsdelta, race_othercheckpointenemy);
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			drawcolorcodedstring(m - '0 0 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
		}
		if (race_penaltytime && !race_penaltyaccumulator) {
			t = race_penaltytime * 0.1 + race_penaltyeventtime;
			a = bound(0, (1 + t - time), 1);
			if (a > 0) {
				if (time < t)
					s = strcat("^1PENALTY: ", str_float_decimals(t - time, 1), " (", race_penaltyreason, ")");
				else
					s = strcat("^2PENALTY: 0.0 (", race_penaltyreason, ")");

				dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
				drawcolorcodedstring(m - '0 32 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
			}
		}
	}
	drawfont = sbar_font;
}

string(void) race_records_table_string {
	string table = "";
	if (race_records_time[0]) {
		string n;
		table = "-----RECORDS-----\n";
		float i, tt;
		for (i = 0; i < 10; i++) {
			n = race_records_name[i];
			tt = race_records_time[i];
			if (!tt)
				break;

			table = strcat(table, "^7", ftos(i + 1), ". ", n, "^7    ", TIME_ENCODED_TOSTRING(tt), "\n");
		}
		table = strcat(table, "-----------------\n\n");
	}
	return table;
}
