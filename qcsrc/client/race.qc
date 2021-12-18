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
float race_records_speed[10];
string race_records_name[10];

void(void) race_read {
	float b;
	b = net_read_byte();
	float i;
	switch(b) {
		case RACE_NET_CHECKPOINT_HIT_QUALIFYING:
			race_checkpoint = net_read_byte();
			race_time = TIME_DECODE(net_read_int24());
			race_previousbesttime = TIME_DECODE(net_read_int24());
			if (race_previousbestname)
				strunzone(race_previousbestname);

			race_previousbestname = strzone(net_read_string());
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
			race_laptime = net_read_coord();
			race_checkpointtime = -99999;
			// fall through
		case RACE_NET_CHECKPOINT_NEXT_QUALIFYING:
			race_nextcheckpoint = net_read_byte();
			race_nextbesttime = TIME_DECODE(net_read_int24());
			if (race_nextbestname)
				strunzone(race_nextbestname);

			race_nextbestname = strzone(net_read_string());
			break;
		case RACE_NET_CHECKPOINT_HIT_RACE:
			race_mycheckpoint = net_read_byte();
			race_mycheckpointtime = time;
			race_mycheckpointdelta = TIME_DECODE(net_read_int24());
			race_mycheckpointlapsdelta = net_read_byte();
			if (race_mycheckpointlapsdelta >= 128)
				race_mycheckpointlapsdelta -= 256;

			if (race_mycheckpointenemy)
				strunzone(race_mycheckpointenemy);

			race_mycheckpointenemy = strzone(net_read_string());
			break;
		case RACE_NET_CHECKPOINT_HIT_RACE_BY_OPPONENT:
			race_othercheckpoint = net_read_byte();
			race_othercheckpointtime = time;
			race_othercheckpointdelta = TIME_DECODE(net_read_int24());
			race_othercheckpointlapsdelta = net_read_byte();
			if (race_othercheckpointlapsdelta >= 128)
				race_othercheckpointlapsdelta -= 256;

			if (race_othercheckpointenemy)
				strunzone(race_othercheckpointenemy);

			race_othercheckpointenemy = strzone(net_read_string());
			break;
		case RACE_NET_PENALTY_RACE:
			race_penaltyeventtime = time;
			race_penaltytime = TIME_DECODE(net_read_short());
			//race_penaltyaccumulator += race_penaltytime;
			if (race_penaltyreason)
				strunzone(race_penaltyreason);

			race_penaltyreason = strzone(net_read_string());
			break;
		case RACE_NET_PENALTY_QUALIFYING:
			race_penaltyeventtime = time;
			race_penaltytime = TIME_DECODE(net_read_short());
			race_penaltyaccumulator += race_penaltytime;
			if (race_penaltyreason)
				strunzone(race_penaltyreason);

			race_penaltyreason = strzone(net_read_string());
			break;
		case RACE_NET_RECORDS_TABLE:
			for (i = 0; i < 10; i++) {
				race_records_time[i] = net_read_coord();
				race_records_speed[i] = net_read_short();
				race_records_name[i] = str_zone_ifneeded(net_read_string());
			}
			break;
	}
}

string(float cp, float mytime, float histime, float lapdelta, string hisname) race_checkpoint_string {
	string col;
	string timestr = "";
	string cpname;
	string lapstr;
	lapstr = "";
	if (histime == 0) { // goal hit
		if (mytime > 0) {
			timestr = strcat("+", str_float_decimals(TIME_DECODE(+mytime), SBAR_TIME_DECIMALS));
			col = "^1";
		} else if (mytime == 0) {
			timestr = "+0.0";
			col = "^3";
		} else {
			timestr = strcat("-", str_float_decimals(TIME_DECODE(-mytime), SBAR_TIME_DECIMALS));
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
			timestr = strcat("+", str_float_decimals(TIME_DECODE(mytime - histime), SBAR_TIME_DECIMALS));
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

vector race_movement;
vector race_velocity;
float(float diffangle) race_strafe_angle {
	vector vel = race_velocity;
	vel_z = 0;
	float speed = vlen(vel);
	float maxspeed = sv_maxspeed * physics_maxspeedmod;
	if not(physics_flags & FL_ONGROUND)
	if (race_movement_y)
	if not(race_movement_x)
	if (sv_maxairstrafespeed) {
		maxspeed = sv_maxairstrafespeed;
	}
	float cos_angle = min(1, maxspeed / speed); //cos of optimal angle
	if (diffangle > 90 || diffangle < -90)
		return -acos(cos_angle) * MATH_RAD2DEG;

	return acos(cos_angle) * MATH_RAD2DEG;
}

float(float f) race_angle_norm {
	while (f > 180) f -= 360;
	while (f < -180) f += 360;
	return f;
}

float(float f) race_angle_to_con_x {
	f = race_angle_norm(f);
	if (f <= -90)
		return 0;

	if (f >= 90)
		return CVAR(vid_conwidth);

	vector v = view_angles;
	v_y -= f;
	makevectors(v);
	v = v_forward * 100 + view_origin;
	v = view_project_3d_to_2d(v);
	return v_x;
}

void(void) race_sbar_draw {
	drawfont = sbar_bigfont;
	float a, t;
	vector m;
	string s, forcetime;
	if (view_spectatee_status || main_isdemo) {
		float keys = getstatf(STAT_PRESSED_KEYS);
		race_movement = '0 0 0';
		if (keys & KEY_FORWARD)
			race_movement_x += sv_maxspeed;

		if (keys & KEY_BACKWARD)
			race_movement_x -= sv_maxspeed;

		if (keys & KEY_LEFT)
			race_movement_y -= sv_maxspeed;

		if (keys & KEY_RIGHT)
			race_movement_y += sv_maxspeed;

		t = bound(0, (time - server_prevtime) / server_ticrate, 1);
		race_velocity = (physics_velocity_frame_begin * (1 - t) + physics_velocity_frame_end * t);
	} else {
		race_velocity = physics_velocity_frame_end;
		race_movement = input_movevalues;
	}
	if (gametype == GAMETYPE_CTS)
	if (CVAR(cl_cts_strafe_helper))
	if (race_velocity_x != 0 || race_velocity_y != 0)
	if (race_movement_x != 0 || race_movement_y != 0) {
		float wishangle = view_angles_y;
		vector v = vectoangles(race_velocity);
		float moveangle = v_y;
		if (race_movement_x > 0) {
			if (race_movement_y > 0)
				wishangle -= 45;
			else if (race_movement_y < 0)
				wishangle += 45;
		} else if (race_movement_x < 0) {
			if (race_movement_y > 0)
				wishangle -= 135;
			else if (race_movement_y < 0)
				wishangle += 135;
		} else {
			if (race_movement_y > 0)
				wishangle -= 90;
			else if (race_movement_y < 0)
				wishangle += 90;
		}
		float diffangle = race_angle_norm(wishangle - moveangle);
		float strafeangle = race_angle_norm(race_strafe_angle(diffangle));
		vector v1, v2;
		v1_x = race_angle_to_con_x(diffangle + strafeangle);
		v1_y = CVAR(vid_conheight) * 0.5 - CVAR(cl_cts_strafe_helper_position);
		v1_z = 0;
		v2_x = max(0, race_angle_to_con_x(diffangle + 90) - v1_x);
		v2_y = CVAR(cl_cts_strafe_helper_height);
		v2_z = 0;
		drawfill(v1, v2, CVAR(cl_cts_strafe_helper_color), 0.25, DRAWFLAG_NORMAL);
		v1_x = race_angle_to_con_x(diffangle - 90);
		v2_x = max(0, race_angle_to_con_x(diffangle - strafeangle) - v1_x);
		drawfill(v1, v2, CVAR(cl_cts_strafe_helper_color), 0.25, DRAWFLAG_NORMAL);
	}
	m = '0.5 0 0' * CVAR(vid_conwidth) + '0 0.25 0' * CVAR(vid_conheight);
	if (race_checkpointtime) {
		a = bound(0, 2 - (time - race_checkpointtime), 1);
		s = "";
		forcetime = "";
		if (a > 0) { // just hit a checkpoint?
			if (race_time && race_previousbesttime)
				s = race_checkpoint_string(race_checkpoint, race_time - race_previousbesttime, 0, 0, race_previousbestname);
			else
				s = race_checkpoint_string(race_checkpoint, 0, -1, 0, race_previousbestname);

			if (race_time)
				forcetime = time_mmssss(race_time);
		} else {
			if (race_laptime && race_nextbesttime && race_nextcheckpoint != 254) {
				a = bound(0, 2 - ((race_laptime + race_nextbesttime) - (time + race_penaltyaccumulator)), 1);
				if (a > 0) // next one?
					s = race_checkpoint_string(race_nextcheckpoint, (time + race_penaltyaccumulator) - race_laptime, race_nextbesttime, 0, race_nextbestname);
			}
		}
		if (s != "" && a > 0) {
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			drawcolorcodedstring(m - '0 16 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
		}
		if (race_penaltytime) {
			a = bound(0, 2 - (time - race_penaltyeventtime), 1);
			if (a > 0) {
				s = strcat("^1PENALTY: ", str_float_decimals(race_penaltytime, 1), " (", race_penaltyreason, ")");
				dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
				drawcolorcodedstring(m - '0 32 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
			}
		}
		if (forcetime != "") {
			a = bound(0, (time - race_checkpointtime) / 0.5, 1);
			draw_string_expanding(m - '16 0 0' * stringwidth(forcetime, FALSE), forcetime, '32 32 0', '1 1 1', sbar_alpha_fg, 0, a);
		} else
			a = 1;

		if (race_laptime && race_checkpoint != 255) {
			s = TIME_ENCODED_TOSTRING(TIME_ENCODE(time + race_penaltyaccumulator - race_laptime));
			drawstring(m - '16 0 0' * stringwidth(s, FALSE), s, '32 32 0', '1 1 1', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
		}
	} else {
		if (race_mycheckpointtime) {
			a = bound(0, 2 - (time - race_mycheckpointtime), 1);
			s = race_checkpoint_string(race_mycheckpoint, race_mycheckpointdelta, -!race_mycheckpointenemy, race_mycheckpointlapsdelta, race_mycheckpointenemy);
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			drawcolorcodedstring(m - '0 16 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
		}
		if (race_othercheckpointtime && race_othercheckpointenemy != "") {
			a = bound(0, 2 - (time - race_othercheckpointtime), 1);
			s = race_checkpoint_string(race_othercheckpoint, -race_othercheckpointdelta, -!race_othercheckpointenemy, race_othercheckpointlapsdelta, race_othercheckpointenemy);
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			drawcolorcodedstring(m - '0 0 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
		}
		if (race_penaltytime && !race_penaltyaccumulator) {
			t = race_penaltytime + race_penaltyeventtime;
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

string(float posy) race_records_table_string {
	string table = "";
	if (race_records_time[0]) {
		string n;
		table = "RECORDS\n";
		float i, tt, sp;
		float rows;
		float name_column_width = 4 * sbar_fontsize_x, table_width;
		float left;
		float tt_prev = 0;
		vector pos = '0 0 0';
		for (i = 0; i < 10; i++) {
			n = race_records_name[i];
			tt = race_records_time[i];
			if (!tt)
				break;

			//table = strcat(table, "^7", ftos(i + 1), ". ", n, "^7    ", TIME_ENCODED_TOSTRING(tt), "\n");
			name_column_width = max(name_column_width, stringwidth(n, TRUE) * sbar_fontsize_x);
			table = strcat(table, "\n");
		}
		rows = i;
		table_width = name_column_width + sbar_fontsize_x * 18;
		pos_x = left = (CVAR(vid_conwidth) - table_width) / 2;
		pos_y = posy + sbar_fontsize_y;
		drawfill(pos, '1 0 0' * table_width + sbar_fontsize_y * (rows + 1) * '0 1 0', '0 0 0', 0.5, DRAWFLAG_NORMAL);
		draw_borderlines(sbar_border_thickness, pos, '1 0 0' * table_width + sbar_fontsize_y * '0 1 0', '0 0 0', 1, DRAWFLAG_NORMAL);
		pos_x += sbar_fontsize_x * 2;
		draw_string_right(pos, "# ", sbar_fontsize, '1 1 0.5', 1, DRAWFLAG_NORMAL);
		pos_x += sbar_fontsize_x;
		drawstring(pos, "Name", sbar_fontsize, '1 1 0.5', 1, DRAWFLAG_NORMAL);
		pos_x += name_column_width + sbar_fontsize_x;
		drawstring(pos, "MSpd", sbar_fontsize, '1 1 0.5', 1, DRAWFLAG_NORMAL);
		pos_x += sbar_fontsize_x * 5;
		drawstring(pos, "Time", sbar_fontsize, '1 1 0.5', 1, DRAWFLAG_NORMAL);
		pos_x += sbar_fontsize_x * 5;
		drawstring(pos, "Gap", sbar_fontsize, '1 1 0.5', 1, DRAWFLAG_NORMAL);
		pos_y += sbar_fontsize_y;
		pos_x = left;
		draw_borderlines(sbar_border_thickness, pos, '1 0 0' * table_width + rows * sbar_fontsize_y * '0 1 0', '0 0 0', 1, DRAWFLAG_NORMAL);
		for (i = 0; i < rows; i++) {
			n = race_records_name[i];
			tt = race_records_time[i];
			sp = race_records_speed[i];
			pos_x += sbar_fontsize_x * 2;
			draw_string_right(pos, strcat(ftos(i + 1), " "), sbar_fontsize, '1 1 0.5', 1, DRAWFLAG_NORMAL);
			drawcolorcodedstring(pos, n, sbar_fontsize, 1, DRAWFLAG_NORMAL);
			pos_x += name_column_width + sbar_fontsize_x * 5;
			draw_string_right(pos, ftos(sp), sbar_fontsize, '0.5 1 0.5', 1, DRAWFLAG_NORMAL);
			pos_x = left + table_width - sbar_fontsize_x * 5;
			draw_string_right(pos, TIME_ENCODED_TOSTRING(tt), sbar_fontsize, '1 1 0.5', 1, DRAWFLAG_NORMAL);
			if (i) {
				pos_x = left + table_width;
				draw_string_right(pos, TIME_ENCODED_TOSTRING(tt - tt_prev), sbar_fontsize, '1 0.5 0.5', 1, DRAWFLAG_NORMAL);
			}
			tt_prev = tt;
			pos_y += sbar_fontsize_y;
			pos_x = left;
		}
		table = strcat(table, "\n\n");
	}
	return table;
}

entity race_pad;

void(void) race_pad_draw {
	if (view_observer_status)
		return;

	if (view_angles_x < 45)
		return;

	if not(CVAR(cl_cts_position_helper))
		return;

	vector v = physics_end_origin;
	trace_box(physics_end_origin, physics.mins, physics.maxs, physics_end_origin + physics.mins_z * '0 0 1' - ('0 0 1' * (physics.maxs_z - physics.mins_z)), TRACE_MOVE_NOMONSTERS, NULL);
	if (trace_fraction == 1)
		return;

	float af = ((view_angles_x - 45) / 45);
	float alpha = min(CVAR(cl_cts_position_helper_alpha), (1 - trace_fraction) * af);
	if (alpha <= 0)
		return;

	v_z = trace_endpos_z + physics.mins_z + 0.01;
	vector rgb = CVAR(cl_cts_position_helper_color);
	vector a, b, c, d, a09, b09, c09, d09;
	a = physics.mins_x * '1 0 0' + physics.mins_y * '0 1 0';
	b = physics.mins_x * '1 0 0' + physics.maxs_y * '0 1 0';
	c = physics.maxs_x * '1 0 0' + physics.maxs_y * '0 1 0';
	d = physics.maxs_x * '1 0 0' + physics.mins_y * '0 1 0';
	a09 = a * 0.9;
	b09 = b * 0.9;
	c09 = c * 0.9;
	d09 = d * 0.9;
	R_BeginPolygon("", DRAWFLAG_NORMAL);
	R_PolygonVertex(v + a, '0 0 0', rgb, alpha);
	R_PolygonVertex(v + a09, '0 1 0', rgb, alpha);
	R_PolygonVertex(v + b09, '1 1 0', rgb, alpha);
	R_PolygonVertex(v + b, '1 0 0', rgb, alpha);
	R_EndPolygon();
	R_BeginPolygon("", DRAWFLAG_NORMAL);
	R_PolygonVertex(v + b, '0 0 0', rgb, alpha);
	R_PolygonVertex(v + b09, '0 1 0', rgb, alpha);
	R_PolygonVertex(v + c09, '1 1 0', rgb, alpha);
	R_PolygonVertex(v + c, '1 0 0', rgb, alpha);
	R_EndPolygon();
	R_BeginPolygon("", DRAWFLAG_NORMAL);
	R_PolygonVertex(v + c, '0 0 0', rgb, alpha);
	R_PolygonVertex(v + c09, '0 1 0', rgb, alpha);
	R_PolygonVertex(v + d09, '1 1 0', rgb, alpha);
	R_PolygonVertex(v + d, '1 0 0', rgb, alpha);
	R_EndPolygon();
	R_BeginPolygon("", DRAWFLAG_NORMAL);
	R_PolygonVertex(v + d, '0 0 0', rgb, alpha);
	R_PolygonVertex(v + d09, '0 1 0', rgb, alpha);
	R_PolygonVertex(v + a09, '1 1 0', rgb, alpha);
	R_PolygonVertex(v + a, '1 0 0', rgb, alpha);
	R_EndPolygon();
	//R_BeginPolygon("textures/trak5/graypanel1", DRAWFLAG_NORMAL);
	//R_PolygonVertex(v + a, '0 0 0', rgb, alpha);
	//R_PolygonVertex(v + b, '0 1 0', rgb, alpha);
	//R_PolygonVertex(v + c, '1 1 0', rgb, alpha);
	//R_PolygonVertex(v + d, '1 0 0', rgb, 0.5);
	//R_EndPolygon();
}

void(void) race_init {
	race_pad = spawn();
	race_pad.draw = race_pad_draw;
}
