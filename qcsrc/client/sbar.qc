float sbar_weapon_hits[WEP_COUNT];
float sbar_weapon_fired[WEP_COUNT];
float sbar_weapon_number;
vector sbar_topright;
vector sbar_bottom;
vector sbar_bottomright;
float sbar_alpha_bg;
float sbar_border_thickness;

float ps_primary, ps_secondary;
float ts_primary, ts_secondary;

vector sbar_color;
float SBAR_SCOREBOARD_OFFSET = 50;
#define SBAR_TIME_DECIMALS 2

#define SBAR_SCORE_IS_INCREASING(x) ( (x)&SCORE_FLAG_LOWER_IS_BETTER )
#define SBAR_SCORE_IS_DECREASING(x) ( !((x)&SCORE_FLAG_LOWER_IS_BETTER) )

float sbar_weaponspace[10];

void(void) sbar_set_defaults {
	cvar_set_vec("sbar_timer_position", SBAR_TIMER_POSITION_DEFAULT);
	cvar_set_vec("sbar_score_position", SBAR_SCORE_POSITION_DEFAULT);
	cvar_set_vec("sbar_ammo_position", SBAR_AMMO_POSITION_DEFAULT);
	cvar_set_vec("sbar_health_position", SBAR_HEALTH_POSITION_DEFAULT);
	cvar_set_vec("sbar_armor_position", SBAR_ARMOR_POSITION_DEFAULT);
	cvar_set_vec("sbar_nadget_position", SBAR_NADGET_POSITION_DEFAULT);
	cvar_set_vec("sbar_nadget2_position", SBAR_NADGET2_POSITION_DEFAULT);
	cvar_set_vec("sbar_weapons_position", SBAR_WEAPONS_POSITION_DEFAULT);
	cvar_set_vec("sbar_gameinfo_position", SBAR_GAMEINFO_POSITION_DEFAULT);
	cvar_set("sbar_timer_scale", "1");
	cvar_set("sbar_score_scale", "1");
	cvar_set("sbar_ammo_scale", "1");
	cvar_set("sbar_health_scale", "1");
	cvar_set("sbar_armor_scale", "1");
	cvar_set("sbar_nadget_scale", "1");
	cvar_set("sbar_nadget2_scale", "1");
	cvar_set("sbar_weapons_scale", "1");
	cvar_set("sbar_gameinfo_scale", "1");
}

void(string s) sbar_load {
	sbar_set_defaults();
	float f = fopen(s, FILE_READ);
	string l;
	string h, t;
	if (f >= 0) {
		while ((l = fgets(f))) {
			h = str_car(l);
			if (h != "") {
				if (substring(h, 0, 5) == "sbar_") {
					t = str_cdr(l);
					cvar_set(h, t);
				}
			}
		}
		fclose(f);
	}
}

void(float f, string s) sbar_save_write_line_scale {
	if (cvar_string(s) != "1") {
		fputs(f, strcat(s, " ", cvar_string(s), "\n"));
	}
}

void(float f, string s, vector def) sbar_save_write_line_position {
	vector v = stov(cvar_string(s));
	if (v != def) {
		fputs(f, strcat(s, " ", ftos(v_x), " ", ftos(v_y), " ", ftos(v_z), "\n"));
	}
}

void(string s) sbar_save {
	float f = fopen(s, FILE_WRITE);
	if (f >= 0) {
		sbar_save_write_line_scale(f, "sbar_timer_scale");
		sbar_save_write_line_scale(f, "sbar_score_scale");
		sbar_save_write_line_scale(f, "sbar_ammo_scale");
		sbar_save_write_line_scale(f, "sbar_health_scale");
		sbar_save_write_line_scale(f, "sbar_armor_scale");
		sbar_save_write_line_scale(f, "sbar_nadget_scale");
		sbar_save_write_line_scale(f, "sbar_nadget2_scale");
		sbar_save_write_line_scale(f, "sbar_weapons_scale");
		sbar_save_write_line_scale(f, "sbar_gameinfo_scale");
		sbar_save_write_line_position(f, "sbar_timer_position", SBAR_TIMER_POSITION_DEFAULT);
		sbar_save_write_line_position(f, "sbar_score_position", SBAR_SCORE_POSITION_DEFAULT);
		sbar_save_write_line_position(f, "sbar_ammo_position", SBAR_AMMO_POSITION_DEFAULT);
		sbar_save_write_line_position(f, "sbar_health_position", SBAR_HEALTH_POSITION_DEFAULT);
		sbar_save_write_line_position(f, "sbar_armor_position", SBAR_ARMOR_POSITION_DEFAULT);
		sbar_save_write_line_position(f, "sbar_nadget_position", SBAR_NADGET_POSITION_DEFAULT);
		sbar_save_write_line_position(f, "sbar_nadget2_position", SBAR_NADGET2_POSITION_DEFAULT);
		sbar_save_write_line_position(f, "sbar_weapons_position", SBAR_WEAPONS_POSITION_DEFAULT);
		sbar_save_write_line_position(f, "sbar_gameinfo_position", SBAR_GAMEINFO_POSITION_DEFAULT);
		fclose(f);
	}
}

vector sbar_position(vector pos, vector sz) {
	vector v = '0 0 0';
	if (pos_z & 1)
		v_x = pos_x + (CVAR(vid_conwidth) - sz_x) * 0.5;
	else if (pos_z & 2)
		v_x = CVAR(vid_conwidth) - pos_x - sz_x;
	else
		v_x = pos_x;

	if (pos_z & 4)
		v_y = pos_y + (CVAR(vid_conheight) - sz_y) * 0.5;
	else if (pos_z & 8)
		v_y = CVAR(vid_conheight) - pos_y - sz_y;
	else
		v_y = pos_y;

	return v;
}

void(float fade) sbar_draw_weapons {
	vector pos;
	float value, idx, imp, sp;
	float nr;
	for (idx = 0; idx < 10; ++idx)
		sbar_weaponspace[idx] = 0;

	float stat_weapons = getstati(STAT_WEAPONS);
	vector w_size = '48 24' * CVAR(sbar_weapons_scale), font_size = '12 12' * CVAR(sbar_weapons_scale), w_shift, w_shift2;
	float w_space = 2 * CVAR(sbar_weapons_scale);
	float active;
	vector weapon_position;
	if (CVAR(sbar_weapons_position_z) & 1) { //horizontal bar
		w_shift2_x = w_size_x;
		if (CVAR(sbar_weapons_position_z) & 8) { //down
			weapon_position = sbar_position(CVAR(sbar_weapons_position), '498 48' * CVAR(sbar_weapons_scale) - '0 24' * CVAR(sbar_weapons_scale));
			w_shift_y = -w_size_y;
		} else {
			weapon_position = sbar_position(CVAR(sbar_weapons_position), '498 48' * CVAR(sbar_weapons_scale));
			w_shift_y = w_size_y;
		}
	} else { //vertical bar
		w_shift2_y = -w_size_y;
		if (CVAR(sbar_weapons_position_z) & 2) { //right
			weapon_position = sbar_position(CVAR(sbar_weapons_position), '98 240' * CVAR(sbar_weapons_scale)) + '48 216' * CVAR(sbar_weapons_scale);
			w_shift_x = -w_size_x;
		} else { //left
			weapon_position = sbar_position(CVAR(sbar_weapons_position), '98 240' * CVAR(sbar_weapons_scale)) + '0 216' * CVAR(sbar_weapons_scale);
			w_shift_x = w_size_x;
		}
	}
	pos_z = 0;
	float wbit = 1;
	for (nr = WEP_FIRST; nr <= WEP_LAST; ++nr, wbit *= 2) {
		if not(stat_weapons & wbit) continue;
		imp = weapon_impulses[nr - 1];
		if not(imp >= 0) continue;
		if (imp == 0)
			idx = 9;
		else
			idx = imp - 1;

		active = (nr == weapon_current);
		value = (active) ? 2 : 0.75;
		sbar_color_x = sbar_color_y = sbar_color_z = value;
		sp = sbar_weaponspace[idx];
		sbar_weaponspace[idx] = sp + 1;
		pos = weapon_position + w_shift2 * idx;
		if (sp)
			pos += w_shift * sp;

		if (active)
			drawpic(pos, "gfx/hud/sb_ammobg", w_size, '1 1 1', fade * sbar_alpha_fg, DRAWFLAG_NORMAL);

		drawpic(pos, strcat("gfx/hud/inv_weapon", ftos(nr - 1)), w_size, sbar_color, fade * sbar_alpha_fg, DRAWFLAG_NORMAL);
		if (sp == 0) {
			pos_x += w_space;
			drawstring(pos, ftos(imp), font_size, '1 1 1', sbar_alpha_fg * fade, DRAWFLAG_NORMAL);
		}
	}
}

void(vector pos, float num, float digits, float showminusplus, float lettersize, vector rgb, float stroke, float alpha, float dflags) sbar_draw_num  {
	float l, i;
	string str, tmp;
	float minus, plus;
	vector vsize, num_color;
	vsize_x = vsize_y = lettersize;
	vsize_z = 0;
	// showminusplus 1: always prefix with minus sign (useful in race distribution display)
	// showminusplus 2: always prefix with plus sign (useful in race distribution display)
	// showminusplus 3: prefix with minus sign if negative, plus sign if positive (useful in score distribution display)
	if ((showminusplus == 2 && num >= 0) || (num > 0 && showminusplus == 3)) {
		plus = TRUE;
		pos_x -= lettersize;
	} else
		plus = FALSE;

	if (num < 0 || (num < 0 && showminusplus == 3) || (showminusplus == 1 && num <= 0)) {
		minus = TRUE;
		num = -num;
		pos_x -= lettersize;
	} else
		minus = FALSE;

	if (digits < 0) {
		tmp = ftos(num);
		digits = -digits;
		str = strcat(substring("0000000000", 0, digits - strlen(tmp)), tmp);
	} else
		str = ftos(num);

	l = strlen(str);
	if (l > digits) {
		str = substring(str, l-digits, 999);
		l = strlen(str);
	} else if (l < digits)
		pos_x += (digits-l) * lettersize;

	if (stroke == 1)
		num_color = '1 1 1';
	else
		num_color = rgb;

	if (minus) {
		if (stroke == 1)
			drawpic(pos, "gfx/hud/num_minus_stroke", vsize, rgb, alpha, dflags);

		drawpic(pos, "gfx/hud/num_minus", vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	} else if (plus) {
		if (stroke == 1)
			drawpic(pos, "gfx/hud/num_plus_stroke", vsize, rgb, alpha, dflags);

		drawpic(pos, "gfx/hud/num_plus", vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	}

	for (i = 0; i < l; ++i) {
		tmp = substring(str, i, 1);
		if (stroke == 1)
			drawpic(pos, strcat("gfx/hud/num_", tmp, "_stroke"), vsize, rgb, alpha, dflags);

		drawpic(pos, strcat("gfx/hud/num_", tmp), vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	}
}

void(vector pos, float x, float lettersize, float alpha) sbar_draw_num_colored  {
	if (x > 200) {
		sbar_color_x = 0;
		sbar_color_y = 1;
		sbar_color_z = 0;
	} else if (x > 150) {
		sbar_color_x = 0.4 - (x-150)*0.02 * 0.4; //red value between 0.4 -> 0
		sbar_color_y = 0.9 + (x-150)*0.02 * 0.1; // green value between 0.9 -> 1
		sbar_color_z = 0;
	} else if (x > 100) {
		sbar_color_x = 1 - (x-100)*0.02 * 0.6; //red value between 1 -> 0.4
		sbar_color_y = 1 - (x-100)*0.02 * 0.1; // green value between 1 -> 0.9
		sbar_color_z = 1 - (x-100)*0.02; // blue value between 1 -> 0
	} else if (x > 50) {
		sbar_color_x = 1;
		sbar_color_y = 1;
		sbar_color_z = 0.2 + (x-50)*0.02 * 0.8; // blue value between 0.2 -> 1
	} else if (x > 20) {
		sbar_color_x = 1;
		sbar_color_y = (x-20)*90/27/100; // green value between 0 -> 1
		sbar_color_z = (x-20)*90/27/100 * 0.2; // blue value between 0 -> 0.2
	} else {
		sbar_color_x = 1;
		sbar_color_y = 0;
		sbar_color_z = 0;
	}
	sbar_draw_num(pos, x, 3, 0, lettersize, sbar_color, 0, alpha, DRAWFLAG_NORMAL);
}

void(void) sbar_scores_init {
	float i, f;
	ps_primary = ps_secondary = ts_primary = ts_secondary = -1;
	for (i = 0; i < SCORE_FILEDS_MAX; ++i) {
		f = (scores_flags[i] & SCORE_FLAG_SORT_PRIO_MASK);
		if (f == SCORE_FLAG_SORT_PRIO_PRIMARY)
			ps_primary = i;
		if (f == SCORE_FLAG_SORT_PRIO_SECONDARY)
			ps_secondary = i;
	}
	if (ps_secondary == -1)
		ps_secondary = ps_primary;

	for (i = 0; i < SCORE_TEAM_FIELDS_MAX; ++i) {
		f = (teamscores_flags[i] & SCORE_FLAG_SORT_PRIO_MASK);
		if (f == SCORE_FLAG_SORT_PRIO_PRIMARY)
			ts_primary = i;
		if (f == SCORE_FLAG_SORT_PRIO_SECONDARY)
			ts_secondary = i;
	}
	if (ts_secondary == -1)
		ts_secondary = ts_primary;

	sbar_field_set(0);
}

float(entity left, entity right) sbar_scores_players_compare {
	float vl, vr;
	vl = player_color(left.sv_entnum);
	vr = player_color(right.sv_entnum);
	if (vl > vr)
		return TRUE;

	if (vl < vr)
		return FALSE;

	if (vl == TEAM_COLOR_SPECTATOR) {
		// FIRST the one with scores (spectators), THEN the ones without (downloaders)
		// no other sorting
		if (!left.gotscores && right.gotscores)
			return TRUE;

		return FALSE;
	}
	vl = left.scores[ps_primary];
	vr = right.scores[ps_primary];
	if (scores_flags[ps_primary] & SCORE_FLAG_ZERO_IS_WORST) {
		if (vl == 0 && vr != 0)
			return 1;

		if (vl != 0 && vr == 0)
			return 0;
	}
	if (vl > vr)
		return SBAR_SCORE_IS_INCREASING(scores_flags[ps_primary]);

	if (vl < vr)
		return SBAR_SCORE_IS_DECREASING(scores_flags[ps_primary]);

	vl = left.scores[ps_secondary];
	vr = right.scores[ps_secondary];
	if (scores_flags[ps_secondary] & SCORE_FLAG_ZERO_IS_WORST) {
		if (vl == 0 && vr != 0)
			return 1;
		if (vl != 0 && vr == 0)
			return 0;
	}
	if (vl > vr)
		return SBAR_SCORE_IS_INCREASING(scores_flags[ps_secondary]);

	if (vl < vr)
		return SBAR_SCORE_IS_DECREASING(scores_flags[ps_secondary]);

	return FALSE;
}

void(entity player) sbar_scores_player_position_update {
	for (other = player.sort_next; other && sbar_scores_players_compare(player, other); other = player.sort_next) {
		SORT_SWAP(player, other);
	}
	for (other = player.sort_prev; other != player_list && sbar_scores_players_compare(other, player); other = player.sort_prev) {
		SORT_SWAP(other, player);
	}
}

float(entity left, entity right) sbar_scores_teams_compare {
	float vl, vr;
	if (left.team == TEAM_COLOR_SPECTATOR)
		return 1;

	if (right.team == TEAM_COLOR_SPECTATOR)
		return 0;

	vl = left.teamscores[ts_primary];
	vr = right.teamscores[ts_primary];
	if (vl > vr)
		return SBAR_SCORE_IS_INCREASING(teamscores_flags[ts_primary]);

	if (vl < vr)
		return SBAR_SCORE_IS_DECREASING(teamscores_flags[ts_primary]);

	vl = left.teamscores[ts_secondary];
	vr = right.teamscores[ts_secondary];
	if (vl > vr)
		return SBAR_SCORE_IS_INCREASING(teamscores_flags[ts_secondary]);

	if (vl < vr)
		return SBAR_SCORE_IS_DECREASING(teamscores_flags[ts_secondary]);

	return FALSE;
}

void(entity Team) sbar_scores_team_position_update {
	for (other = Team.sort_next; other && sbar_scores_teams_compare(Team, other); other = Team.sort_next) {
		SORT_SWAP(Team, other);
	}
	for (other = Team.sort_prev; other != team_list && sbar_scores_teams_compare(other, Team); other = Team.sort_prev) {
		SORT_SWAP(other, Team);
	}
}

void(float argc) sbar_help {
	print("You can modify the scoreboard using the ^2sbar_columns_set command.\n");
	print("^3|---------------------------------------------------------------|\n");
	print("Usage:\n");
	print("^2sbar_columns_set default\n");
	print("^2sbar_columns_set ^7filed1 field2 ...\n");
	print("The following field names are recognized (case insensitive):\n");
	print("You can use a ^3|^7 to start the right-aligned fields.\n\n");
	print("^3name^7 or ^3nick^7         Name of a player\n");
	print("^3ping^7                     Ping time\n");
	print("^3pl^7                       Packet loss\n");
	print("^3kills^7                    Number of kills\n");
	print("^3deaths^7                   Number of deaths\n");
	print("^3suicides^7                 Number of suicides\n");
	print("^3frags^7                    kills - suicides\n");
	print("^3kd^7                       The kill-death ratio\n");
	print("^3caps^7                     How often a flag (CTF) or a key (KeyHunt) was captured\n");
	print("^3pickups^7                  How often a flag (CTF) or a key (KeyHunt) was picked up\n");
	print("^3fckills^7                  Number of flag carrier kills\n");
	print("^3returns^7                  Number of flag returns\n");
	print("^3drops^7                    Number of flag drops\n");
	print("^3rank^7                     Player rank\n");
	print("^3pushes^7                   Number of players pushed into void\n");
	print("^3destroyed^7                Number of keys destroyed by pushing them into void\n");
	print("^3kckills^7                  Number of keys carrier kills\n");
	print("^3losses^7                   Number of times a key was lost\n");
	print("^3laps^7                     Number of laps finished (race/cts)\n");
	print("^3time^7                     Total time raced (race/cts)\n");
	print("^3fastest^7                  Time of fastest lap (race/cts)\n");
	print("^3ticks^7                    Number of ticks (DOM)\n");
	print("^3takes^7                    Number of domination points taken (DOM)\n");
	print("^3score^7                    Total score\n\n");
	print("Before a field you can put a + or - sign, then a comma separated list\n");
	print("of game types, then a slash, to make the field show up only in these\n");
	print("or in all but these game types. You can also specify 'all' as a\n");
	print("field to show all fields available for the current game mode.\n\n");
	print("The special game type names 'teams' and 'noteams' can be used to\n");
	print("include/exclude ALL teams/noteams game modes.\n\n");
	print("Example: sbar_columns_set name ping pl | +ctf/field3 -dm/field4\n");
	print("will display name, ping and pl aligned to the left, and the fields\n");
	print("right of the vertical bar aligned to the right.\n");
	print("'field3' will only be shown in CTF, and 'field4' will be shown in all\n");
	print("other gamemodes except DM.\n");
}

string sbar_scoreboard_default_layout =
		"ping pl ?cv ?cn name | "
		"+teams/rank -teams,race,single/kills -teams,single/deaths -teams,race,single/suicides -race,dm,tdm,coop,single/frags " // tdm already has this in "score"
		"?damage ?bestwep +ca,ft,surv,catf,ctft,khca,khft,lms/status "
		"+ctf,catf,ctft/caps +ctf,catf,ctft/pickups +ctf,catf,ctft/fckills +ctf,catf,ctft/returns "
		"+kh,khca,khft/caps +kh,khca,khft/pushes +kh,khca,khft/destroyed "
		"?+race/laps ?+race/time ?+race/fastest "
		"+as/objectives +nexball/faults +nexball/goals "
		"+ft,ctft,khft/revs -race,nexball/score +lms/lives";

void(float argc) sbar_field_set {
	float i, j, slash;
	string str, pattern;
	float digit;
	float have_name, have_primary, have_secondary, have_separator;
	float missing;
	// TODO: re enable with gametype dependant cvars?
	if (argc < 2) // no arguments provided
		argc = tokenizebyseparator(strcat("x ", cvar_string("sbar_columns")), " ");

	if (argc < 2)
		argc = tokenizebyseparator(strcat("x ", sbar_scoreboard_default_layout), " ");

	if (argc == 2) {
		if (argv(1) == "default")
			argc = tokenizebyseparator(strcat("x ", sbar_scoreboard_default_layout), " ");
		else if (argv(1) == "all") {
			string s;
			s = "ping pl ?cn color name |";
			for (i = 0; i < SCORE_FILEDS_MAX; ++i) {
				if (i != ps_primary)
				if (i != ps_secondary)
				if (scores_label[i] != "")
					s = strcat(s, " ", scores_label[i]);
			}
			if (ps_secondary != ps_primary)
				s = strcat(s, " ", scores_label[ps_secondary]);

			s = strcat(s, " ", scores_label[ps_primary]);
			argc = tokenizebyseparator(strcat("x ", s), " ");
		}
	}
	sbar_num_fields = 0;
	drawfont = sbar_font;
	digit = stringwidth("0123456789", FALSE) / 10;
	for (i = 0; i < argc - 1; ++i) {
		float nocomplain;
		str = argv(i+1);
		nocomplain = FALSE;
		if (substring(str, 0, 1) == "?") {
			nocomplain = TRUE;
			str = substring(str, 1, strlen(str) - 1);
		}
		slash = strstrofs(str, "/", 0);
		if (slash >= 0) {
			pattern = substring(str, 0, slash);
			str = substring(str, slash + 1, strlen(str) - (slash + 1));
			if not(gametype_filter(gametype, team_mode, pattern))
				continue;
		}
		strunzone(sbar_title[sbar_num_fields]);
		sbar_title[sbar_num_fields] = strzone(str);
		sbar_size[sbar_num_fields] = stringwidth(str, FALSE);
		str = strtolower(str);
		if (str == "ping") {
			sbar_field[sbar_num_fields] = SP_PING;
		} else if (str == "pl") {
			sbar_field[sbar_num_fields] = SP_PL;
		} else if (str == "kd" || str == "kdr" || str == "kdratio" || str == "k/d") {
			sbar_field[sbar_num_fields] = SP_KDRATIO;
		} else if (str == "cn" && SP_COUNTRY_FIELD >= 0) {
			sbar_field[sbar_num_fields] = SP_COUNTRY;
		} else if (str == "cv" && SP_CLIENTVERSION_FIELD >= 0) {
			sbar_field[sbar_num_fields] = SP_CLIENTVERSION;
		} else if (str == "name" || str == "nick") {
			sbar_field[sbar_num_fields] = SP_NAME;
			have_name = 1;
		} else if (str == "status") {
			sbar_field[sbar_num_fields] = SP_STATUS;
		} else if (str == "|") {
			sbar_field[sbar_num_fields] = SP_SEPARATOR;
			have_separator = 1;
		} else {
			for (j = 0; j < SCORE_FILEDS_MAX; ++j)
				if (str == strtolower(scores_label[j]))
					goto found; // sorry, but otherwise fteqcc -O3 miscompiles this and warns about "unreachable code"
:notfound
			if (str == "frags") {
				j = SP_FRAGS;
			} else {
				if not(nocomplain)
					print(strcat("^1Error:^7 Unknown score field: '", str, "'\n"));

				continue;
			}
:found
			if (str == "bestwep")
				sbar_field[sbar_num_fields] = SP_BESTWEP;
			else
				sbar_field[sbar_num_fields] = j;

			if (j == ps_primary)
				have_primary = 1;

			if (j == ps_secondary)
				have_secondary = 1;
		}
		++sbar_num_fields;
		if (sbar_num_fields >= SBAR_FIELDS_MAX)
			break;
	}
	if (scores_flags[ps_primary] & SCORE_FLAG_ALLOW_HIDE)
		have_primary = 1;

	if (scores_flags[ps_secondary] & SCORE_FLAG_ALLOW_HIDE)
		have_secondary = 1;

	if (ps_primary == ps_secondary)
		have_secondary = 1;

	missing = (!have_primary) + (!have_secondary) + (!have_separator) + (!have_name);
	if (sbar_num_fields+missing < SBAR_FIELDS_MAX) {
		if (!have_name) {
			strunzone(sbar_title[sbar_num_fields]);
			for (i = sbar_num_fields; i > 0; --i) {
				sbar_title[i] = sbar_title[i-1];
				sbar_size[i] = sbar_size[i-1];
				sbar_field[i] = sbar_field[i-1];
			}
			sbar_title[0] = strzone("name");
			sbar_field[0] = SP_NAME;
			++sbar_num_fields;
			print("fixed missing field 'name'\n");
			if (!have_separator) {
				strunzone(sbar_title[sbar_num_fields]);
				for (i = sbar_num_fields; i > 1; --i) {
					sbar_title[i] = sbar_title[i-1];
					sbar_size[i] = sbar_size[i-1];
					sbar_field[i] = sbar_field[i-1];
				}
				sbar_title[1] = strzone("|");
				sbar_field[1] = SP_SEPARATOR;
				sbar_size[1] = stringwidth("|", FALSE);
				++sbar_num_fields;
				print("fixed missing field '|'\n");
			}
		} else if (!have_separator) {
			strunzone(sbar_title[sbar_num_fields]);
			sbar_title[sbar_num_fields] = strzone("|");
			sbar_size[sbar_num_fields] = stringwidth("|", FALSE);
			sbar_field[sbar_num_fields] = SP_SEPARATOR;
			++sbar_num_fields;
			print("fixed missing field '|'\n");
		}
		if (!have_secondary) {
			strunzone(sbar_title[sbar_num_fields]);
			sbar_title[sbar_num_fields] = strzone(scores_label[ps_secondary]);
			sbar_size[sbar_num_fields] = stringwidth(sbar_title[sbar_num_fields], FALSE);
			sbar_field[sbar_num_fields] = ps_secondary;
			++sbar_num_fields;
			print("fixed missing field '", scores_label[ps_secondary], "'\n");
		}
		if (!have_primary) {
			strunzone(sbar_title[sbar_num_fields]);
			sbar_title[sbar_num_fields] = strzone(scores_label[ps_primary]);
			sbar_size[sbar_num_fields] = stringwidth(sbar_title[sbar_num_fields], FALSE);
			sbar_field[sbar_num_fields] = ps_primary;
			++sbar_num_fields;
			print("fixed missing field '", scores_label[ps_primary], "'\n");
		}
	}
	sbar_field[sbar_num_fields] = SP_END;
}

vector sbar_field_rgb;
string sbar_field_icon0;
string sbar_field_icon1;
string sbar_field_icon2;
vector sbar_field_icon0_rgb;
vector sbar_field_icon1_rgb;
vector sbar_field_icon2_rgb;
float sbar_field_icon0_alpha;
float sbar_field_icon1_alpha;
float sbar_field_icon2_alpha;
string(entity pl, float field) sbar_field_get {
	float tmp, num, denom, f;
	string str;
	sbar_field_rgb = '1 1 1';
	sbar_field_icon0 = "";
	sbar_field_icon1 = "";
	sbar_field_icon2 = "";
	sbar_field_icon0_rgb = '1 1 1';
	sbar_field_icon1_rgb = '1 1 1';
	sbar_field_icon2_rgb = '1 1 1';
	sbar_field_icon0_alpha = 1;
	sbar_field_icon1_alpha = 1;
	sbar_field_icon2_alpha = 1;
	switch (field) {
	case SP_PING:
		if not(pl.gotscores)
			return "\x8D\x8D\x8D"; // >>> sign

		str = getplayerkey(pl.sv_entnum, "ping");
		if (str == "0")
			return "N/A";

		tmp = max(0, min(220, stof(str)-80)) / 220;
		sbar_field_rgb = '1 1 1' - '0 1 1'*tmp;
		return str;
	case SP_PL:
		if not(pl.gotscores)
			return "N/A";
		str = getplayerkey(pl.sv_entnum, "pl");
		if (str == "0")
			return "";
		tmp = bound(0, stof(str), 20) / 20; // 20% is REALLY BAD pl
		sbar_field_rgb = '1 0.5 0.5' - '0 0.5 0.5'*tmp;
		return str;
	case SP_COUNTRY:
		float char0 = pl.(scores[SP_COUNTRY_FIELD]) & 0xff;
		float char1 = floor(pl.(scores[SP_COUNTRY_FIELD]) / 256) & 0xff;
		if (!char0 || !char1)
			return "";

		return strcat(chr2str(char0), chr2str(char1));
	case SP_CLIENTVERSION:
		tmp = pl.(scores[SP_CLIENTVERSION_FIELD]);
		switch (tmp) {
		case CLIENT_NEWREXUIZ:
			sbar_field_rgb = '0.25 1 0.25';
			return "R+";
		case CLIENT_REXUIZ:
			sbar_field_rgb = '0.75 0.75 0.25';
			return "R";
		case CLIENT_NEXUIZ:
			sbar_field_rgb = '0.75 0.5 0.25';
			return "N+";
		case CLIENT_OLDNEXUIZ:
			sbar_field_rgb = '1 0.25 0.25';
			return "N";
		default:
			sbar_field_rgb = '0.5 0.5 0.5';
			return "U";
		}
	case SP_NAME:
		if (pl.ready) {
			sbar_field_icon0 = "gfx/sb_player_ready";
		} else if not(team_mode) {
			f = stof(getplayerkey(pl.sv_entnum, "colors"));
			sbar_field_icon0 = "gfx/sb_playercolor_base";
			sbar_field_icon1 = "gfx/sb_playercolor_shirt";
			sbar_field_icon1_rgb = colormap_palette_color(floor(f / 16), 0);
			sbar_field_icon2 = "gfx/sb_playercolor_pants";
			sbar_field_icon2_rgb = colormap_palette_color(math_mod(f, 16), 1);
		}
		return strcat(player_name(pl.sv_entnum), "^0#", ftos(pl.sv_entnum + 1));
	case SP_STATUS:
		if ((pl.(scores[SP_STATUS_FIELD]) == 0)) {
			sbar_field_rgb = '0.25 1 0.25';
			return "\x13";
		} else {
			sbar_field_rgb = '0.25 0.25 0.25';
			return "\x15";
		}
	case SP_FRAGS:
		f = pl.(scores[SP_KILLS_FIELD]);
		f -= pl.(scores[SP_SUICIDES_FIELD]);
		return ftos(f);
	case SP_KDRATIO:
		num = pl.(scores[SP_KILLS_FIELD]);
		denom = pl.(scores[SP_DEATHS_FIELD]);
		if (denom == 0) {
			sbar_field_rgb = '0 1 0';
			str = ftos(num);
		} else if (num <= 0) {
			sbar_field_rgb = '1 0 0';
			str = ftos(num/denom);
		} else
			str = ftos(num/denom);

		tmp = strstrofs(str, ".", 0);
		if (tmp > 0)
			str = substring(str, 0, tmp+2);

		return str;
	case SP_BESTWEP:
		tmp = pl.(scores[SP_BESTWEP_FIELD]);
		return score_string(0, tmp);
	default:
		tmp = pl.(scores[field]);
		f = scores_flags[field];
		if (field == ps_primary)
			sbar_field_rgb = '1 1 0';
		else if (field == ps_secondary)
			sbar_field_rgb = '0 1 1';
		else
			sbar_field_rgb = '1 1 1';
		return score_string(f, tmp);
	}
	//return "error";
}

float sbar_xmin, sbar_xmax, sbar_ymin, sbar_ymax, sbar_width;
float sbar_fixscoreboardcolumnwidth_len;
float sbar_fixscoreboardcolumnwidth_iconlen;
float sbar_fixscoreboardcolumnwidth_marginlen;

string(float i, string str) sbar_scoreboard_columns_width_fix {
	float field, f;
	vector sz;
	field = sbar_field[i];
	sbar_fixscoreboardcolumnwidth_iconlen = 0;
	if (sbar_field_icon0 != "") {
		sz = drawgetimagesize(sbar_field_icon0);
		f = sz_x / sz_y;
		if (sbar_fixscoreboardcolumnwidth_iconlen < f)
			sbar_fixscoreboardcolumnwidth_iconlen = f;
	}
	if (sbar_field_icon1 != "") {
		sz = drawgetimagesize(sbar_field_icon1);
		f = sz_x / sz_y;
		if (sbar_fixscoreboardcolumnwidth_iconlen < f)
			sbar_fixscoreboardcolumnwidth_iconlen = f;
	}
	if (sbar_field_icon2 != "") {
		sz = drawgetimagesize(sbar_field_icon2);
		f = sz_x / sz_y;
		if (sbar_fixscoreboardcolumnwidth_iconlen < f)
			sbar_fixscoreboardcolumnwidth_iconlen = f;
	}
	sbar_fixscoreboardcolumnwidth_iconlen *= sbar_fontsize_y / sbar_fontsize_x; // fix icon aspect
	if (sbar_fixscoreboardcolumnwidth_iconlen != 0)
		sbar_fixscoreboardcolumnwidth_marginlen = stringwidth(" ", FALSE);
	else
		sbar_fixscoreboardcolumnwidth_marginlen = 0;

	if (field == SP_NAME) { // name gets all remaining space
		float namesize, j;
		namesize = sbar_width / sbar_fontsize_x;
		for (j = 0; j < sbar_num_fields; ++j)
			if (j != i)
				if (sbar_field[i] != SP_SEPARATOR)
					namesize -= sbar_size[j] + 1;
		namesize += 1;
		sbar_size[i] = namesize;

		if (sbar_fixscoreboardcolumnwidth_iconlen != 0)
			namesize -= sbar_fixscoreboardcolumnwidth_marginlen + sbar_fixscoreboardcolumnwidth_iconlen;
		str = str_shorten_to_width(str, namesize, str_width_colors);
		sbar_fixscoreboardcolumnwidth_len = stringwidth(str, TRUE);
	}
	else if (field == SP_COUNTRY)
		sbar_fixscoreboardcolumnwidth_len = stringwidth("XX", FALSE);
	else if (field == SP_BESTWEP)
		sbar_fixscoreboardcolumnwidth_len = stringwidth("XXXXXX", FALSE);
	else
		sbar_fixscoreboardcolumnwidth_len = stringwidth(str, FALSE);

	f = sbar_fixscoreboardcolumnwidth_len + sbar_fixscoreboardcolumnwidth_marginlen + sbar_fixscoreboardcolumnwidth_iconlen;
	if (sbar_size[i] < f)
		sbar_size[i] = f;

	return str;
}

float sbar_width_wanted;
void(vector pos, entity pl, float is_self, float pl_number) sbar_scoreboard_item_draw {
	vector tmp;
	string str_full, str;
	float i, field, f, w;
	float is_spec;
	float sbar_size_i;
	float title_width;
	is_spec = (player_color(pl.sv_entnum) == TEAM_COLOR_SPECTATOR);
	float wanted_width = 0;
	// Layout:
	tmp_x = sbar_width;
	tmp_y = sbar_fontsize_y * 1.25;
	tmp_z = 0;
	// alternated rows highlighting
	if (is_self)
		drawfill(pos - '1 1 0', tmp + '2 0 0', '1 1 1', 0.25, DRAWFLAG_NORMAL);
	else {
		if (CVAR(sbar_scoreboard_highlight))
			if (!math_mod(pl_number,2))
				drawfill(pos - '1 1 0', tmp + '2 0 0', '1 1 1', 0.09, DRAWFLAG_NORMAL);
	}
	tmp_y = 0;
	for (i = 0; i < sbar_num_fields; ++i) {
		title_width = stringwidth(sbar_title[i], FALSE) + 1;
		sbar_size_i = sbar_size[i];
		field = sbar_field[i];
		if (field == SP_SEPARATOR)
			break;

		str_full = sbar_field_get(pl, field);
		str = sbar_scoreboard_columns_width_fix(i, str_full);
		if (field == SP_NAME)
			wanted_width = wanted_width + max(stringwidth(str_full, FALSE) + sbar_fixscoreboardcolumnwidth_marginlen + sbar_fixscoreboardcolumnwidth_iconlen + 1, title_width);
		else
			wanted_width = wanted_width + title_width;

		if (is_spec && field != SP_NAME && field != SP_PING && field != SP_COUNTRY && field != SP_CLIENTVERSION) {
			pos_x += sbar_fontsize_x * sbar_size_i + sbar_fontsize_x;
			continue;
		}
		pos_x += sbar_fontsize_x * sbar_size_i + sbar_fontsize_x;
		if (field == SP_NAME) {
			tmp_x = sbar_fontsize_x*(sbar_size_i - sbar_fixscoreboardcolumnwidth_iconlen - sbar_fixscoreboardcolumnwidth_marginlen) + sbar_fontsize_x;
			drawcolorcodedstring(pos - tmp, str, sbar_fontsize, 1, DRAWFLAG_NORMAL);
		} else if (field == SP_COUNTRY) {
			tmp_x = sbar_fixscoreboardcolumnwidth_len*sbar_fontsize_x + sbar_fontsize_x;
			drawpic(pos - tmp, flag_icon(str), '1.5 1 0' * sbar_fontsize_x, '1 1 1', 1.0, DRAWFLAG_NORMAL);
		} else if (field == SP_BESTWEP) {
			tmp_x = sbar_fixscoreboardcolumnwidth_len*sbar_fontsize_x + sbar_fontsize_x;
			f = stof(str);
			w = f & 63;
			if (w) {
				f = (f - w) / 64;
				drawpic(pos - tmp, strcat("gfx/hud/inv_weapon", ftos(w - 1)), '2 1 0' * sbar_fontsize_x, '1 1 1', 1.0, DRAWFLAG_NORMAL);
				tmp_x = tmp_x - 2 * sbar_fontsize_x;
				drawstring(pos - tmp, strcat(ftos(f), "%"), sbar_fontsize, sbar_field_rgb, 1, DRAWFLAG_NORMAL);
			}
		} else {
			tmp_x = sbar_fixscoreboardcolumnwidth_len*sbar_fontsize_x + sbar_fontsize_x;
			drawstring(pos - tmp, str, sbar_fontsize, sbar_field_rgb, 1, DRAWFLAG_NORMAL);
		}

		tmp_x = sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;
		if (field == SP_NAME)
		if not(is_spec) {
			if (sbar_field_icon0 != "")
				drawpic(pos - tmp, sbar_field_icon0, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon1_rgb, sbar_field_icon0_alpha, DRAWFLAG_NORMAL);

			if (sbar_field_icon1 != "")
				drawpic(pos - tmp, sbar_field_icon1, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon1_rgb, sbar_field_icon1_alpha, DRAWFLAG_NORMAL);

			if (sbar_field_icon2 != "")
				drawpic(pos - tmp, sbar_field_icon2, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon2_rgb, sbar_field_icon2_alpha, DRAWFLAG_NORMAL);
		}
	}
	if (sbar_field[i] == SP_SEPARATOR) {
		pos_x = sbar_xmax;
		for (i = sbar_num_fields-1; i > 0; --i) {
			title_width = stringwidth(sbar_title[i], FALSE) + 1;
			sbar_size_i = sbar_size[i];
			field = sbar_field[i];
			if (field == SP_SEPARATOR)
				break;

			str_full = sbar_field_get(pl, field);
			str = sbar_scoreboard_columns_width_fix(i, str_full);
			if (field == SP_NAME)
				wanted_width = wanted_width + max(stringwidth(str_full, FALSE) + sbar_fixscoreboardcolumnwidth_marginlen + sbar_fixscoreboardcolumnwidth_iconlen + 1, title_width);
			else
				wanted_width = wanted_width + title_width;

			if (is_spec && field != SP_NAME && field != SP_PING) {
				pos_x -= sbar_fontsize_x * sbar_size_i + sbar_fontsize_x;
				continue;
			}
			if (field == SP_NAME) {
				tmp_x = sbar_fontsize_x*sbar_fixscoreboardcolumnwidth_len; // left or right aligned? let's put it right...
				drawcolorcodedstring(pos - tmp, str, sbar_fontsize, 1, DRAWFLAG_NORMAL);
			} else if (field == SP_COUNTRY) {
				tmp_x = sbar_fixscoreboardcolumnwidth_len*sbar_fontsize_x;
				drawpic(pos - tmp, flag_icon(str), '1.5 1 0' * sbar_fontsize_x, '1 1 1', 1.0, DRAWFLAG_NORMAL);
			} else if (field == SP_BESTWEP) {
				tmp_x = sbar_fixscoreboardcolumnwidth_len*sbar_fontsize_x;
				f = stof(str);
				w = f & 63;
				if (w) {
					f = (f - w) / 64;
					drawpic(pos - tmp, strcat("gfx/hud/inv_weapon", ftos(w - 1)), '2 1 0' * sbar_fontsize_x, '1 1 1', 1.0, DRAWFLAG_NORMAL);
					tmp_x = tmp_x - 2 * sbar_fontsize_x;
					drawstring(pos - tmp, strcat(ftos(f), "%"), sbar_fontsize, sbar_field_rgb, 1, DRAWFLAG_NORMAL);
				}
			} else {
				tmp_x = sbar_fontsize_x*sbar_fixscoreboardcolumnwidth_len;
				drawstring(pos - tmp, str, sbar_fontsize, sbar_field_rgb, 1, DRAWFLAG_NORMAL);
			}

			tmp_x = sbar_fontsize_x * sbar_size_i;
			if (field == SP_NAME)
			if not(is_spec) {
				if (sbar_field_icon0 != "")
					drawpic(pos - tmp, sbar_field_icon0, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon1_rgb, sbar_field_icon0_alpha, DRAWFLAG_NORMAL);
				if (sbar_field_icon1 != "")
					drawpic(pos - tmp, sbar_field_icon1, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon1_rgb, sbar_field_icon1_alpha, DRAWFLAG_NORMAL);
				if (sbar_field_icon2 != "")
					drawpic(pos - tmp, sbar_field_icon2, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon2_rgb, sbar_field_icon2_alpha, DRAWFLAG_NORMAL);
			}
			pos_x -= sbar_fontsize_x * sbar_size_i + sbar_fontsize_x;
		}
	}
	sbar_width_wanted = max(sbar_width_wanted, wanted_width);
}

vector(vector pos, entity tm, vector rgb, vector bg_size) sbar_scoreboard_table_draw {
	float body_table_height, i;
	vector tmp, column_dim;
	entity pl;
	body_table_height = 1.25 * sbar_fontsize_y * max(1, tm.team_size); // no player? show 1 empty line
	pos -= '1 1 0';
	tmp_x = sbar_width + 2;
	tmp_y = 1.25 * sbar_fontsize_y;
	// rounded header
	drawpic(pos, "gfx/hud/sb_scoreboard_tableheader", tmp, '0.5 0.5 0.5', CVAR(sbar_scoreboard_alpha_bg), DRAWFLAG_NORMAL);
	// table border
	tmp_y += sbar_border_thickness;
	tmp_y += body_table_height;
	draw_borderlines(sbar_border_thickness, pos, tmp, '0 0 0', CVAR(sbar_scoreboard_alpha_bg), DRAWFLAG_NORMAL); // more transparency for the scoreboard
	// separator header/table
	pos_y += 1.25 * sbar_fontsize_y;
	tmp_y = sbar_border_thickness;
	drawfill(pos, tmp, '0 0 0', CVAR(sbar_scoreboard_alpha_bg), DRAWFLAG_NORMAL);
	pos_y += sbar_border_thickness;
	// table background
	tmp_y = body_table_height;
	draw_pic_tiled(pos, "gfx/hud/sb_scoreboard_bg", bg_size, tmp, rgb * CVAR(sbar_color_bg_team), CVAR(sbar_scoreboard_alpha_bg), DRAWFLAG_NORMAL);
	// go back to the top to make alternated columns highlighting and to print the strings
	pos_y -= 1.25 * sbar_fontsize_y;
	pos_y -= sbar_border_thickness;
	pos += '1 1 0';
	if (CVAR(sbar_scoreboard_highlight)) {
		column_dim_y = 1.25 * sbar_fontsize_y; // header
		column_dim_y += sbar_border_thickness;
		column_dim_y += body_table_height;
	}
	// print the strings of the columns headers and draw the columns
	for (i = 0; i < sbar_num_fields; ++i) {
		if (sbar_field[i] == SP_SEPARATOR)
			break;

		column_dim_x = sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;
		if (CVAR(sbar_scoreboard_highlight)) {
			if (math_mod(i,2))
				drawfill(pos - '0 1 0' - sbar_fontsize_x / 2 * '1 0 0', column_dim, '0 0 0', CVAR(sbar_scoreboard_alpha_bg) * 0.2, DRAWFLAG_NORMAL);
		}
		drawstring(pos, sbar_title[i], sbar_fontsize, rgb, 1, DRAWFLAG_NORMAL);
		pos_x += column_dim_x;
	}
	if (sbar_field[i] == SP_SEPARATOR) {
		pos_x = sbar_xmax;
		tmp_y = 0;
		for (i = sbar_num_fields-1; i > 0; --i) {
			if (sbar_field[i] == SP_SEPARATOR)
				break;

			pos_x -= sbar_size[i]*sbar_fontsize_x;
			if (CVAR(sbar_scoreboard_highlight)) {
				if (!math_mod(i,2)) {
					if (i == sbar_num_fields-1)
						column_dim_x = sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x / 2 + 1;
					else
						column_dim_x = sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;

					drawfill(pos - '0 1 0' - sbar_fontsize_x / 2 * '1 0 0', column_dim, '0 0 0', CVAR(sbar_scoreboard_alpha_bg) * 0.2, DRAWFLAG_NORMAL);
				}
			}
			tmp_x = stringwidth(sbar_title[i], FALSE);
			tmp_x = (sbar_size[i] - tmp_x) * sbar_fontsize_x;
			drawstring(pos + tmp, sbar_title[i], sbar_fontsize, rgb, 1, DRAWFLAG_NORMAL);
			pos_x -= sbar_fontsize_x;
		}
	}
	pos_x = sbar_xmin;
	pos_y += 1.25 * sbar_fontsize_y; // skip the header
	pos_y += sbar_border_thickness;
	// fill the table and draw the rows
	i = 0;
	if (team_mode)
		for (pl = player_list.sort_next; pl; pl = pl.sort_next) {
			if (pl.team != tm.team)
				continue;

			sbar_scoreboard_item_draw(pos, pl, (pl.sv_entnum == player_localentnum - 1), i);
			pos_y += 1.25 * sbar_fontsize_y;
			++i;
		}
	else
		for (pl = player_list.sort_next; pl; pl = pl.sort_next) {
			if (pl.team == TEAM_COLOR_SPECTATOR)
				continue;

			sbar_scoreboard_item_draw(pos, pl, (pl.sv_entnum == player_localentnum - 1), i);
			pos_y += 1.25 * sbar_fontsize_y;
			++i;
		}
	if (i == 0)
		pos_y += 1.25 * sbar_fontsize_y; // move to the end of the table

	pos_y += 1.25 * sbar_fontsize_y; // move empty row (out of the table)
	return pos;
}

float sbar_nextplayerscheck;
float sbar_lastpingstime;
void sbar_scoreboard_draw() {
	vector rgb, pos, tmp;
	entity pl, tm;
	view_crosshair = FALSE;
	if (sbar_nextplayerscheck < time) { //Check for downloaders
		float i;
		entity e;
		for (i = 0; i < maxclients; ++i) {
			e = player_slots[i];
			if (player_name(i) == "") {
				if (e.sort_prev) {
					team_set(e, -1);
					player_remove(e);
					e.sort_prev = world;
				}
			} else {
				if not(e.sort_prev) {
				if not(e)
					player_slots[i] = e = spawn();
					e.sv_entnum = i;
					team_set(e, TEAM_COLOR_SPECTATOR);
					player_register(e);
					sbar_scores_player_position_update(e);
				}
			}
		}
		sbar_nextplayerscheck = time + 1;
	}
	if (time > sbar_lastpingstime + 10) {
		localcmd("pings\n");
		sbar_lastpingstime = time;
	}
	sbar_width = sbar_width_wanted * sbar_fontsize_x;
	sbar_width_wanted = 0;
	sbar_width = min(CVAR(vid_conwidth) - 13 * sbar_fontsize_x, sbar_width);
	sbar_width = max(sbar_width, 400);
	sbar_xmin = 0.5 * (CVAR(vid_conwidth) - sbar_width);
	sbar_ymin = SBAR_SCOREBOARD_OFFSET;
	sbar_xmax = CVAR(vid_conwidth) - sbar_xmin;
	sbar_ymax = CVAR(vid_conheight) - 0.2 * CVAR(vid_conheight);
	// Initializes position
	pos_x = sbar_xmin;
	pos_y = sbar_ymin;
	pos_z = 0;
	drawfont = sbar_font;
	// Print info string
	string str;
	float tl, fl, ll;
	str = strcat("^7Playing ^3", strtoupper(gametype_name(gametype)), "^7 on ^2", map_shortname);
	drawcolorcodedstring(pos + '0.5 0 0' * (sbar_width - sbar_fontsize_x * stringwidth(str, TRUE)), str, sbar_fontsize, 0.8, DRAWFLAG_NORMAL);
	pos_y += sbar_fontsize_y;
	if (map_description != "") {
		str = strcat("^7(", map_description, "^7)");
		drawcolorcodedstring(pos + '0.5 0 0' * (sbar_width - sbar_fontsize_x * stringwidth(str, TRUE)), str, sbar_fontsize, 0.8, DRAWFLAG_NORMAL);
		pos_y += sbar_fontsize_y;
	}
	tl = getstatf(STAT_TIMELIMIT);
	fl = getstatf(STAT_FRAGLIMIT);
	ll = getstatf(STAT_LEADLIMIT);
	if (tl > 0)
		str = strcat("^7for ^1", ftos(tl), " minutes^7");
	else
		str = "";

	if (fl > 0) {
		if (tl > 0)
			str = strcat(str, " or");

		if (team_mode) {
			str = strcat(str, " until ^3", score_string(teamscores_flags[ts_primary], fl));
			if (teamscores_label[ts_primary] == "score")
				str = strcat(str, " points^7");
			else if (teamscores_label[ts_primary] == "fastest")
				str = strcat(str, " is beaten^7");
			else
				str = strcat(str, " ", teamscores_label[ts_primary]);
		} else {
			str = strcat(str, " until ^3", score_string(scores_flags[ps_primary], fl));
			if (scores_label[ps_primary] == "score")
				str = strcat(str, " points^7");
			else if (scores_label[ps_primary] == "fastest")
				str = strcat(str, " is beaten^7");
			else
				str = strcat(str, " ", scores_label[ps_primary]);
		}
	}
	if (ll > 0) {
		if (tl > 0 || fl > 0)
			str = strcat(str, " or");

		if (team_mode) {
			str = strcat(str, " until a lead of ^3", score_string(teamscores_flags[ts_primary], ll));
			if (teamscores_label[ts_primary] == "score")
				str = strcat(str, " points^7");
			else if (teamscores_label[ts_primary] == "fastest")
				str = strcat(str, " is beaten^7");
			else
				str = strcat(str, " ", teamscores_label[ts_primary]);
		} else {
			str = strcat(str, " until a lead of ^3", score_string(scores_flags[ps_primary], ll));
			if (scores_label[ps_primary] == "score")
				str = strcat(str, " points^7");
			else if (scores_label[ps_primary] == "fastest")
				str = strcat(str, " is beaten^7");
			else
				str = strcat(str, " ", scores_label[ps_primary]);
		}
	}
	if (str != "") {
		drawcolorcodedstring(pos + '0.5 0 0' * (sbar_width - sbar_fontsize_x * stringwidth(str, TRUE)), str, sbar_fontsize, 0.8, DRAWFLAG_NORMAL);
		pos_y += sbar_fontsize_y;
	}
	pos_y += sbar_fontsize_y;
	// Draw the scoreboard
	vector bg_size;
	bg_size = drawgetimagesize("gfx/hud/sb_scoreboard_bg");
	if (team_mode) {
		for (tm = team_list.sort_next; tm; tm = tm.sort_next) {
			if (tm.team == TEAM_COLOR_SPECTATOR)
				continue;

			rgb = team_rgb(tm.team);
			sbar_draw_num(pos - '6.5 0 0' * sbar_fontsize_y + '0 1 0' * sbar_fontsize_y, tm.(teamscores[ts_primary]), 4, 0, sbar_fontsize_y * 1.5, rgb, 1, 1, DRAWFLAG_NORMAL);
			if (ts_primary != ts_secondary)
				sbar_draw_num(pos - '4.5 0 0' * sbar_fontsize_y + '0 2.5 0' * sbar_fontsize_y, tm.(teamscores[ts_secondary]), 4, 0, sbar_fontsize_y * 1, rgb, 1, 1, DRAWFLAG_NORMAL);

			pos = sbar_scoreboard_table_draw(pos, tm, rgb, bg_size);
		}
	} else {
		rgb_x = CVAR(sbar_color_bg_r);
		rgb_y = CVAR(sbar_color_bg_g);
		rgb_z = CVAR(sbar_color_bg_b);
		for (tm = team_list.sort_next; tm; tm = tm.sort_next) {
			if (tm.team == TEAM_COLOR_SPECTATOR)
				continue;

			pos = sbar_scoreboard_table_draw(pos, tm, rgb, bg_size);
		}
	}
	tmp = pos + '0 0.75 0' * sbar_fontsize_y;
	pos_y += 2 * sbar_fontsize_y;
	// List spectators
	float specs;
	specs = 0;
	for (pl = player_list.sort_next; pl; pl = pl.sort_next) {
		if (pl.team != TEAM_COLOR_SPECTATOR)
			continue;

		sbar_scoreboard_item_draw(pos, pl, (pl.sv_entnum == player_localentnum - 1), specs);
		pos_y += 1.25 * sbar_fontsize_y;
		++specs;
	}
	if (specs) {
		drawstring(tmp, "Spectators", sbar_fontsize, '1 1 1', 1, DRAWFLAG_NORMAL);
		pos_y += 2 * sbar_fontsize_y;
	}
	scoreboard_bottom = pos_y;
	if (centerprint_num < 1) {
		string tail = server_motd;
		pos_y = max(CVAR(vid_conheight) * 0.5 + sbar_fontsize_y, pos_y);
		if (gametype == GAMETYPE_CTS || gametype == GAMETYPE_RACE)
			tail = strcat(race_records_table_string(pos_y), tail);

		float n;
		while (tail != "") {
			n = strstrofs(tail, "\n", 0);
			if (n < 0) {
				str = tail;
				tail = "";
			} else {
				str = substring(tail, 0, n);
				tail = substring(tail, n + 1, -1);
			}
			drawcolorcodedstring(pos + '0.5 0 0' * (sbar_width - sbar_fontsize_x * stringwidth(str, TRUE)), str, sbar_fontsize, 0.8, DRAWFLAG_NORMAL);
			pos_y += sbar_fontsize_y;
		}
	}
}

var void(void)sbar_score_draw = {};
void(void) sbar_score_draw_default {
	float score, distribution, leader;
	vector score_pos, secondary_score_pos, distribution_color;
	entity tm, pl, me;
	me = (view_spectatee_status > 0) ? player_slots[view_spectatee_status - 1] : player_slots[player_localentnum - 1];
	score_pos = sbar_position(CVAR(sbar_score_position), '196 34' * CVAR(sbar_score_scale));
	secondary_score_pos = score_pos + '132 0 0' * CVAR(sbar_score_scale);
	if not(team_mode) { // non-teamgames, except race/cts
		// me vector := [team/connected frags id]
		pl = player_list.sort_next;
		if (pl == me)
			pl = pl.sort_next;

		if (pl)
			distribution = me.(scores[ps_primary]) - pl.(scores[ps_primary]);
		else
			distribution = 0;

		score = me.(scores[ps_primary]);
		if (distribution >= 5) {
			distribution_color = '0 1 0';
			leader = 1;
		} else if (distribution >= 0) {
			distribution_color = '1 1 1';
			leader = 1;
		} else if (distribution >= -5)
			distribution_color = '1 1 0';
		else
			distribution_color = '1 0 0';

		sbar_draw_num(secondary_score_pos, distribution, 4, 3, 16 * CVAR(sbar_score_scale), distribution_color, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		sbar_draw_num(score_pos, score, 4, 0, 34 * CVAR(sbar_score_scale), distribution_color, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
	} else { // teamgames
		float max_fragcount;
		max_fragcount = -999;
		for (tm = team_list.sort_next; tm; tm = tm.sort_next) {
			if (tm.team == TEAM_COLOR_SPECTATOR || !tm.team_size) // no players? don't display
				continue;

			score = tm.(teamscores[ts_primary]);
			leader = 0;
			if (score > max_fragcount)
				max_fragcount = score;

			if (tm.team == team_my) {
				if (max_fragcount == score)
					leader = 1;

				sbar_draw_num(score_pos, score, 4, 0, 34 * CVAR(sbar_score_scale), team_rgb(tm.team) * 0.8, 1, sbar_alpha_fg, DRAWFLAG_NORMAL);
			} else {
				if (max_fragcount == score)
					leader = 1;

				sbar_draw_num(secondary_score_pos, score, 4, 0, 16 * CVAR(sbar_score_scale), team_rgb(tm.team) * 0.8, 1, sbar_alpha_fg, DRAWFLAG_NORMAL);
				secondary_score_pos = secondary_score_pos + '0 16 0' * CVAR(sbar_score_scale);
			}
		}
	}
}

void(void) sbar_score_draw_race {
	if ((scores_flags[ps_primary] & SCORE_FLAG_TIME) && !team_mode) { // race/cts record display on HUD
		float score, distribution;
		vector distribution_color;
		entity pl, me;
		me = (view_spectatee_status > 0) ? player_slots[view_spectatee_status - 1] : player_slots[player_localentnum - 1];
		pl = player_list.sort_next;
		if (pl == me)
			pl = pl.sort_next;

		if (scores_flags[ps_primary] & SCORE_FLAG_ZERO_IS_WORST)
			if (pl.scores[ps_primary] == 0)
				pl = world;

		score = me.(scores[ps_primary]);
		float racemin, racesec, racemsec;
		float distsec, distmsec, minusplus;
		racemin = floor(score/(60 * TIME_FACTOR));
		racesec = floor((score - racemin*(60 * TIME_FACTOR))/TIME_FACTOR);
		racemsec = score - racemin*60*TIME_FACTOR - racesec*TIME_FACTOR;
		vector pos = sbar_position(CVAR(sbar_score_position), '160 34' * CVAR(sbar_score_scale));
		vector font_size;
		if (pl && ((!(scores_flags[ps_primary] & SCORE_FLAG_ZERO_IS_WORST)) || score)) {
			// distribution display
			distribution = me.(scores[ps_primary]) - pl.(scores[ps_primary]);
			if (distribution < TIME_FACTOR && distribution > -TIME_FACTOR)
				distmsec = fabs(distribution);
			else {
				distsec = floor(fabs(distribution)/TIME_FACTOR);
				distmsec = fabs(distribution) - distsec*TIME_FACTOR;
				if (distribution < 0)
					distsec = -distsec;
			}
			if (distribution <= 0) {
				distribution_color = '0 1 0';
				minusplus = 1; // minusplus 1: always prefix with minus sign
			} else {
				distribution_color = '1 0 0';
				minusplus = 2; // minusplus 1: always prefix with plus sign
			}
			font_size = '14 14' * CVAR(sbar_score_scale);
			sbar_draw_num(pos + '132 0' * CVAR(sbar_score_scale), distmsec, -SBAR_TIME_DECIMALS, 0, font_size_x, distribution_color, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			drawpic(pos + '121.5 0' * CVAR(sbar_score_scale), "gfx/hud/num_dot", font_size, distribution_color, sbar_alpha_fg, DRAWFLAG_ADDITIVE);
			sbar_draw_num(pos + '71 0' * CVAR(sbar_score_scale), distsec, 4, minusplus, font_size_x, distribution_color, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		}
		font_size = '20 20' * CVAR(sbar_score_scale);
		sbar_draw_num(pos + '120 14' * CVAR(sbar_score_scale), racemsec, -SBAR_TIME_DECIMALS, 0, font_size_x, '1 1 1', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		drawpic(pos + '105 14' * CVAR(sbar_score_scale), "gfx/hud/num_dot", font_size, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE);
		sbar_draw_num(pos + '70 14' * CVAR(sbar_score_scale), racesec, -2, 0, font_size_x, '1 1 1', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		drawpic(pos + '55 14' * CVAR(sbar_score_scale), "gfx/hud/num_colon", font_size, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE);
		sbar_draw_num(pos + '20 14' * CVAR(sbar_score_scale), racemin, -2, 0, font_size_x, '1 1 1', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
	} else
		sbar_score_draw_default();

	race_sbar_draw();
}

void(void) sbar_timer {
	float timelimit, elapsedTime, minutes, seconds, timeleft, starttime, hideminutes;
	hideminutes = FALSE;
	vector timer_color;
	timelimit = getstatf(STAT_TIMELIMIT);
	starttime = getstatf(STAT_GAMESTARTTIME);
	timeleft = timelimit * 60 + starttime - time;
	if (timeleft >= 300 || timelimit == 0) //don't use red or yellow in warmup or when there is no timelimit
		timer_color = '1 1 1'; //white
	else if (timeleft >= 60)
		timer_color = '1 1 0'; //yellow
	else
		timer_color = '1 0 0'; //red

	if (CVAR(sbar_increment_maptime) || timelimit == 0) {
		if (time < starttime) {
			//while restart is still active, show 00:00
			minutes = seconds = 0;
		} else {
			elapsedTime = floor(time - starttime);
			minutes = floor(elapsedTime / 60);
			seconds = elapsedTime - minutes*60;
		}
	} else {
		if (timeleft < 0) {
			timeleft = max(0, -1 - timeleft);
		} else {
			if (timeleft < 60)
				hideminutes = TRUE;
		}
		timeleft = ceil(timeleft);
		minutes = floor(timeleft / 60);
		seconds = timeleft - minutes*60;
	}
	vector pos = sbar_position(CVAR(sbar_timer_position), '103 20' * CVAR(sbar_timer_scale));
	if not(hideminutes) {
		sbar_draw_num(pos, minutes, 3, 0, 18 * CVAR(sbar_timer_scale), timer_color, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		drawpic(pos + '50 0 0' * CVAR(sbar_timer_scale), "gfx/hud/num_colon", '18 18 0' * CVAR(sbar_timer_scale), timer_color, sbar_alpha_fg, DRAWFLAG_NORMAL);
	}
	sbar_draw_num(pos + '64 0 0' * CVAR(sbar_timer_scale), seconds, -2, 0, 18 * CVAR(sbar_timer_scale), timer_color, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
}

vector sbar_powerup_pos;
void sbar_powerup_timer_draw(float dt, string image) {
	vector picsize;
	picsize = '22 22 0' * CVAR(sbar_powerups_scale);
	float countdown_fontsize = 18;
	if (dt > 0) {
		if (dt < 5) {
			draw_pic_expanding_two(sbar_powerup_pos, image, picsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE,
				bound(0, (ceil(dt) - dt) / 0.5, 1));
		} else {
			if (dt > 99)
				dt = 99;

			drawpic(sbar_powerup_pos, image, picsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE);
		}
		sbar_draw_num(sbar_powerup_pos - '40 -2 0' * CVAR(sbar_powerups_scale), ceil(dt), 2, 0, countdown_fontsize, '1 1 1', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
	} else if (dt > -1) {
		draw_pic_expanding(sbar_powerup_pos, image, picsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE,
			bound(0, -dt / 0.5, 1));
	}
	sbar_powerup_pos_y -= 40 * CVAR(sbar_powerups_scale);
}

void(void) sbar_powerups_draw {
	if (getstati(STAT_HEALTH) <= 0)
		return;

	float strength_time, invincibility_time, speed_time, invisibility_time, jetpack_time;
	sbar_powerup_pos = sbar_position(CVAR(sbar_powerups_position), '64 200') + '40 160 0' * CVAR(sbar_powerups_scale);
	//draw_borderlines(1, sbar_powerup_pos, fill_size, '0 0 0', sbar_alpha_bg, DRAWFLAG_NORMAL);
	strength_time = getstatf(STAT_STRENGTH_FINISHED);
	invincibility_time = getstatf(STAT_INVINCIBLE_FINISHED);
	speed_time = getstatf(STAT_SPEED_FINISHED);
	invisibility_time = getstatf(STAT_INVISIBILITY_FINISHED);
	jetpack_time = getstati(STAT_FUEL);
	if (strength_time)
		sbar_powerup_timer_draw(strength_time - time, "gfx/hud/sb_str");

	if (invincibility_time)
		sbar_powerup_timer_draw(invincibility_time - time, "gfx/hud/sb_invinc");

	if (invisibility_time)
		sbar_powerup_timer_draw(invisibility_time - time, "gfx/hud/sb_str");

	if (speed_time)
		sbar_powerup_timer_draw(speed_time - time, "gfx/hud/sb_invinc");

	if (jetpack_time)
		sbar_powerup_timer_draw(jetpack_time, "gfx/hud/sb_fuel");
}

void(void) sbar_pressedkeys_draw {
	vector pos, bgsize;
	float pressedkeys;
	pos = stov(cvar_string("cl_showpressedkeys_position"));
	bgsize = '126 75 0';
	pos = '1 0 0' * (CVAR(vid_conwidth) - bgsize_x) * pos_x
			+ '0 1 0' * (CVAR(vid_conheight) - bgsize_y) * pos_y;
	pos -= '-15 -6 0'; // adjust to the origin of these numbers
	pressedkeys = getstatf(STAT_PRESSED_KEYS);
	drawpic(pos + '-15   -6   0', "gfx/hud/keys/key_bg",           bgsize, '1 1 1', 0.1 * sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 83.5  9   0', ((pressedkeys & KEY_CROUCH) ? "gfx/hud/keys/key_crouch_inv" : "gfx/hud/keys/key_crouch"), ' 24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 32   -1.5 0', ((pressedkeys & KEY_FORWARD) ? "gfx/hud/keys/key_forward_inv" : "gfx/hud/keys/key_forward"),  ' 32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + '-11.5  9   0', ((pressedkeys & KEY_JUMP) ? "gfx/hud/keys/key_jump_inv" : "gfx/hud/keys/key_jump"),     ' 24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' -1   32   0', ((pressedkeys & KEY_LEFT) ? "gfx/hud/keys/key_left_inv" : "gfx/hud/keys/key_left"),     ' 32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 32   32   0', ((pressedkeys & KEY_BACKWARD) ? "gfx/hud/keys/key_backward_inv" : "gfx/hud/keys/key_backward"), ' 32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 65   32   0', ((pressedkeys & KEY_RIGHT) ? "gfx/hud/keys/key_right_inv" : "gfx/hud/keys/key_right"),    ' 32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
}

void(void) sbar_speed_draw {
	vector numsize;
	float pos, conversion_factor;
	string speed, unit;
	switch (CVAR(cl_showspeed_unit)) {
	default:
	case 0:
		unit = "";
		conversion_factor = 1.0;
		break;
	case 1:
		unit = " qu/s";
		conversion_factor = 1.0;
		break;
	case 2:
		unit = " m/s";
		conversion_factor = 0.0254;
		break;
	case 3:
		unit = " km/h";
		conversion_factor = 0.0254 * 3.6;
		break;
	case 4:
		unit = " mph";
		conversion_factor = 0.0254 * 3.6 * 0.6213711922;
		break;
	case 5:
		unit = " knots";
		conversion_factor = 0.0254 * 1.943844492; // 1 m/s = 1.943844492 knots, because 1 knot = 1.852 km/h
		break;
	}
	if (CVAR(cl_showspeed_z) == 1)
		speed = strcat(ftos(floor( vlen(physics_velocity_frame_end) * conversion_factor + 0.5 )), unit);
	else
		speed = strcat(ftos(floor( vlen(physics_velocity_frame_end - physics_velocity_frame_end_z * '0 0 1') * conversion_factor + 0.5 )), unit);

	numsize_x = numsize_y = CVAR(cl_showspeed_size);
	pos = (CVAR(vid_conheight) - numsize_y) * CVAR(cl_showspeed_position);
	drawfont = sbar_bigfont;
	draw_string_center('1 0 0' + pos * '0 1 0', speed, numsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawfont = sbar_font;
}

void(void) sbar_acceleration_draw {
	vector pos, top, rgb;
	if (view_spectatee_status)
		return;

	top_x = CVAR(vid_conwidth)/2;
	top_y = 0;
	float acceleration;
	if (CVAR(cl_showacceleration_z))
		acceleration = (vlen(physics_velocity_frame_end) - vlen(physics_velocity_frame_begin)) * (1 / physics_frametime);
	else
		acceleration = (vlen(physics_velocity_frame_end - '0 0 1' * physics_velocity_frame_end_z) - vlen(physics_velocity_frame_begin - '0 0 1' * physics_velocity_frame_begin_z)) * (1 / physics_frametime);

	acceleration = acceleration / getstatf(STAT_MOVEVARS_MAXSPEED);
	pos = top - CVAR(cl_showacceleration_size)/2 * '0 1 0' + (CVAR(cl_showacceleration_position) * CVAR(vid_conheight)) * '0 1 0';
	if (CVAR(cl_showacceleration_color_custom))
		rgb = stov(cvar_string("cl_showacceleration_color"));
	else {
		rgb = '1 1 1';
		if (acceleration < 0) {
			rgb = '1 .5 .5' - '0 .5 .5' * bound(0, -acceleration * 0.2, 1);
		} else if (acceleration > 0) {
			rgb = '.5 1 .5' - '.5 0 .5' * bound(0, +acceleration * 0.2, 1);
		}
	}
	if (acceleration > 0)
		drawpic(pos, "gfx/hud/accelerometer_gradient", acceleration * CVAR(cl_showacceleration_scale) * '40 0 0' + CVAR(cl_showacceleration_size) * '0 1 0', rgb, CVAR(cl_showacceleration_alpha) * sbar_alpha_fg, DRAWFLAG_NORMAL);
	else if (acceleration < 0)
		drawpic(pos + acceleration * CVAR(cl_showacceleration_scale) * '40 0 0', "gfx/hud/accelerometer_gradient", -acceleration * CVAR(cl_showacceleration_scale) * '40 0 0' + CVAR(cl_showacceleration_size) * '0 1 0', rgb, CVAR(cl_showacceleration_alpha) * sbar_alpha_fg, DRAWFLAG_NORMAL);
}

void(vector position) sbar_accuracy_description_draw {
	drawstring(position + '0 3 0' * sbar_fontsize_y, "Shots fired:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawstring(position + '0 5 0' * sbar_fontsize_y, "Shots hit:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawstring(position + '0 7 0' * sbar_fontsize_y, "Accuracy:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawstring(position + '0 9 0' * sbar_fontsize_y, "Shots missed:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
}

void(void) sbar_accuracy_draw {
	float i, count, row;  // count is the number of 'colums'
	float weapon_hit, weapon_damage, weapon_stats;
	float left_border;  // position where the weapons start, the description is in the border
	vector fill_colour, fill_size;
	vector pos;
	float col_margin = 20;  // pixels between the columns
	float row_margin = 20;  // pixels between the rows
	fill_size_x = 5 * sbar_fontsize_x;  // width of the background
	fill_size_y = 10 * sbar_fontsize_y;  // height of the background
	drawfont = sbar_bigfont;
	pos_x = 0;
	pos_y = SBAR_SCOREBOARD_OFFSET;
	pos_z = 0;
	draw_string_center(pos, "Weapon Accuracy", 2 * sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	left_border = col_margin + 11 * sbar_fontsize_x;
	drawfont = sbar_font;
	float top_border = SBAR_SCOREBOARD_OFFSET + 55;  // position where the hitscan row starts: pixels down the screen
	sbar_accuracy_description_draw('1 0 0' * col_margin + '0 1 0' * top_border);
	for (i = WEP_FIRST; i <= WEP_LAST; ++i) {
		weapon_hit = sbar_weapon_hits[i];
		weapon_damage = sbar_weapon_fired[i];
		self = weapon_info(i);
		if (weapon_damage) {
			weapon_stats = bound(0, rint(100 * weapon_hit / weapon_damage), 100);
			fill_colour_x = 1 - 0.015 * weapon_stats;
			fill_colour_y = 1 - 0.015 * (100 - weapon_stats);
			// how the background colour is calculated
			// %	red		green	red_2			green_2
			// 0	1		0		1 - % * 0.015	1 - (100 - %) * 0.015
			// 10	0.85	0		1 - % * 0.015	1 - (100 - %) * 0.015
			// 20	0.70	0		1 - % * 0.015	1 - (100 - %) * 0.015
			// 30	0.55	0		1 - % * 0.015	1 - (100 - %) * 0.015
			// 40	0.40	0.10	1 - % * 0.015	1 - (100 - %) * 0.015
			// 50	0.25	0.25	1 - % * 0.015	1 - (100 - %) * 0.015
			// 60	0.10	0.40	1 - % * 0.015	1 - (100 - %) * 0.015
			// 70	0		0.55	1 - % * 0.015	1 - (100 - %) * 0.015
			// 80	0		0.70	1 - % * 0.015	1 - (100 - %) * 0.015
			// 90	0		0.85	1 - % * 0.015	1 - (100 - %) * 0.015
			// 100	0		1		1 - % * 0.015	1 - (100 - %) * 0.015
			if ((left_border + count * (fill_size_x + col_margin) + fill_size_x) >= CVAR(vid_conwidth)) {
				count = 0;
				++row;
				sbar_accuracy_description_draw('1 0 0' * col_margin + '0 1 0' * (top_border + row * (fill_size_y + row_margin)));
			}
			pos_x = left_border + count * (fill_size_x + col_margin);
			pos_y = top_border + row * (fill_size_y + row_margin);
			// background
			drawpic(pos, "gfx/hud/sb_accuracy", fill_size , fill_colour, sbar_alpha_bg, DRAWFLAG_NORMAL);
			draw_borderlines(sbar_border_thickness, pos, fill_size, '0 0 0', sbar_alpha_bg, DRAWFLAG_NORMAL);
			// the weapon
			drawpic(pos, strcat("gfx/hud/inv_weapon", ftos(i-1)), '1 0.5 0' * fill_size_x , '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
			// the amount of shots fired or max damage
			draw_string_right(pos + '4.5 0 0' * sbar_fontsize_x + '0 3 0' * sbar_fontsize_y, ftos(weapon_damage), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
			// the amount of hits or actual damage
			draw_string_right(pos + '4.5 0 0' * sbar_fontsize_x + '0 5 0' * sbar_fontsize_y, ftos(weapon_hit), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
			// the accuracy
			draw_string_right(pos + '4.5 0 0' * sbar_fontsize_x + '0 7 0' * sbar_fontsize_y, strcat(ftos(weapon_stats),"%"), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
			// the amount of shots missed or damage wasted
			draw_string_right(pos + '4.5 0 0' * sbar_fontsize_x + '0 9 0' * sbar_fontsize_y, ftos(max(0, weapon_damage - weapon_hit)), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
			++count;
		}
	}
}

void(void) sbar_reset {
	// reset gametype specific icons
	if (gametype == GAMETYPE_KEYHUNT || gametype == GAMETYPE_KEYHUNT_CA || gametype == GAMETYPE_KEYHUNT_FT)
		kh_hud_reset();
	else if (gametype == GAMETYPE_CTF || gametype == GAMETYPE_CATF || gametype == GAMETYPE_CTFT)
		ctf_hud_reset();
}

float(float stat_type, float stat_regen, float stat_maxregen) sbar_nadget_regen {
	return getstatf(stat_regen) / getstatf(stat_maxregen);
}

var void(void) sbar_gametype_hud;
void(void) sbar_gametype_init {
	if (gametype == GAMETYPE_KEYHUNT || gametype == GAMETYPE_KEYHUNT_CA || gametype == GAMETYPE_KEYHUNT_FT)
		sbar_gametype_hud = kh_hud;
	else if (gametype == GAMETYPE_CTF || gametype == GAMETYPE_CATF || gametype == GAMETYPE_CTFT)
		sbar_gametype_hud = ctf_hud;
	else if (gametype == GAMETYPE_NEXBALL)
		sbar_gametype_hud = nb_hud;
	else if (gametype == GAMETYPE_SINGLE || gametype == GAMETYPE_COOP) {
		sbar_gametype_hud = single_hud;
		sbar_score_draw = stdproc_nothing;
	} else if (gametype == GAMETYPE_RACE || gametype == GAMETYPE_CTS) {
		sbar_gametype_hud = stdproc_nothing;
		sbar_score_draw = sbar_score_draw_race;
	} else {
		sbar_gametype_hud = stdproc_nothing;
		sbar_score_draw = sbar_score_draw_default;
	}
}

void(vector pos, float a, float active, string image) sbar_ammo_draw {
	float alpha;
	if (active) {
		alpha = 1;
		drawpic(pos + '0 1.5 0' * CVAR(sbar_ammo_scale), "gfx/hud/sb_ammobg", '80 22 0' * CVAR(sbar_ammo_scale), '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	} else
		alpha = 0.7;

	drawpic(pos + '56 3 0' * CVAR(sbar_ammo_scale), image, '18 18 0' * CVAR(sbar_ammo_scale), '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	if (a < 10)
		sbar_color = '1 0 0';
	else
		sbar_color = '1 1 1';

	sbar_draw_num(pos + '6 4.5 0' * CVAR(sbar_ammo_scale), a, 3, 0, 16 * CVAR(sbar_ammo_scale), sbar_color, 0, sbar_alpha_fg * alpha, DRAWFLAG_NORMAL);
}

float sbar_hg_visual, sbar_hg_alpha;

void(void) sbar_draw {
	sbar_topright_x = CVAR(vid_conwidth);
	sbar_topright_y = 0;
	sbar_topright_z = 0;
	sbar_bottom_x = CVAR(vid_conwidth)/2;
	sbar_bottom_y = CVAR(vid_conheight);
	sbar_bottom_z = 0;
	sbar_bottomright_x = CVAR(vid_conwidth);
	sbar_bottomright_y = CVAR(vid_conheight);
	sbar_bottomright_z = 0;
	sbar_bottomleft_x = 0;
	sbar_bottomleft_y = CVAR(vid_conheight);
	sbar_bottomleft_z = 0;
	sbar_alpha_bg = CVAR(sbar_alpha_bg) * (1 - CVAR(_menu_alpha));
	sbar_border_thickness = bound(0, CVAR(sbar_border_thickness), 5);
	float i;
	float weapon_stats;
	float x;
	weapon_stats = getstati(STAT_DAMAGE_HITS);
	sbar_weapon_number = weapon_stats & 63;
	sbar_weapon_hits[sbar_weapon_number] = rint(weapon_stats / 64);
	weapon_stats = getstati(STAT_DAMAGE_FIRED);
	sbar_weapon_number = weapon_stats & 63;
	sbar_weapon_fired[sbar_weapon_number] = rint(weapon_stats / 64);
	string s;
	vector pos;
	pos = '0 0 0';
	sbar_fontsize = sbar_font_size(CVAR(sbar_fontsize));
	sbar_fontsize_spec = sbar_font_size(CVAR(sbar_fontsize_spec));
	float _health = getstati(STAT_HEALTH);
	if (mapvote_active) { // map voting screen
		if (sbar_showscores) {
			sbar_scoreboard_draw();
			sbar_score_draw();
			sbar_timer();
		} else if (sbar_showaccuracy) {
			sbar_accuracy_draw();
			sbar_score_draw();
			sbar_timer();
		} else {
			if (mapvote_active)
				mapvote_draw();
		}
		sbar_reset();
	} else if (_health <= 0 || view_observer_status) {
		if (sbar_showaccuracy)
			sbar_accuracy_draw();
		else if (!sbar_hidescores) {
			if (sbar_showscores || (_health <= 0 && CVAR(cl_deathscoreboard)))
				sbar_scoreboard_draw();
		} else
			return;

		sbar_score_draw();
		sbar_timer();
	} else {
		if (sbar_showscores)
			sbar_scoreboard_draw();
		else if (sbar_showaccuracy)
			sbar_accuracy_draw();

		float armor;
		armor = getstati(STAT_ARMOR);
		sbar_stat_items = getstati(STAT_ITEMS);
		// armor
		if (armor > 0) {
			pos = sbar_position(CVAR(sbar_armor_position), '110 32' * CVAR(sbar_armor_scale));
			if (armor > 45) {
				drawpic(pos + '78 0 0' * CVAR(sbar_armor_scale), "gfx/hud/sb_armor", '32 32 0' * CVAR(sbar_armor_scale), '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
				sbar_draw_num_colored(pos + '0 4' * CVAR(sbar_armor_scale), armor, 24 * CVAR(sbar_armor_scale), sbar_alpha_fg);
			} else {
				drawpic(pos + '78 0 0' * CVAR(sbar_armor_scale), "gfx/hud/sb_armor", '32 32 0' * CVAR(sbar_armor_scale), '1 1 1', (x+10)/55 * sbar_alpha_fg, DRAWFLAG_NORMAL);
				sbar_draw_num_colored(pos + '0 4' * CVAR(sbar_armor_scale), armor, 24 * CVAR(sbar_armor_scale), (x+10)/55 * sbar_alpha_fg);
			}
		}
		// health
		pos = sbar_position(CVAR(sbar_health_position), '110 32' * CVAR(sbar_health_scale));
		drawpic(pos + '78 0 0' * CVAR(sbar_health_scale), "gfx/hud/sb_health", '32 32 0' * CVAR(sbar_health_scale), '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
		sbar_draw_num_colored(pos + '0 4' * CVAR(sbar_health_scale), _health, 24 * CVAR(sbar_health_scale), sbar_alpha_fg);
		// weapon icons
		x = 1.0;
		float fade = bound(0, CVAR(sbar_weapons_fadetime) - (time - sbar_weapons_time) *  CVAR(sbar_weapons_fadespeed), 1);
		if (fade)
			sbar_draw_weapons(fade);

		// ammo
		float a; // i will be the ammo type (already declared), a will contain how much ammo there is of type i
		float clip = getstati(STAT_BULLETS_LOADED);
		pos = sbar_position(CVAR(sbar_ammo_position), '172 48' * CVAR(sbar_ammo_scale));
		if (clip) {
			if (clip < 0) clip = 0;
			string ai;
			float at;
			if (sbar_stat_items & IT_SHELLS) { at = STAT_SHELLS; ai = "gfx/hud/sb_shells"; }
			else if (sbar_stat_items & IT_NAILS) { at = STAT_NAILS; ai = "gfx/hud/sb_bullets"; }
			else if (sbar_stat_items & IT_ROCKETS) { at = STAT_ROCKETS; ai = "gfx/hud/sb_rocket"; }
			else if (sbar_stat_items & IT_CELLS) { at = STAT_CELLS; ai = "gfx/hud/sb_cells"; }
			else at = 0;
			if (at) {
				a = getstati(at);
				drawpic(pos + '106 13 0' * CVAR(sbar_ammo_scale), ai, '24 24 0' * CVAR(sbar_ammo_scale), '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
				if (sbar_stat_items & IT_UNLIMITED_WEAPON_AMMO) {
					sbar_draw_num(pos + '35 15 0' * CVAR(sbar_ammo_scale), clip, 3, 0, 24 * CVAR(sbar_ammo_scale), '1 1 0.5', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				} else {
					if (a < 10)
						sbar_draw_num(pos + '35 8 0' * CVAR(sbar_ammo_scale), a, 3, 0, 16 * CVAR(sbar_ammo_scale), '0.7 0 0', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					else
						sbar_draw_num(pos + '35 8 0' * CVAR(sbar_ammo_scale), a, 3, 0, 16 * CVAR(sbar_ammo_scale), '1 1 1', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);

					sbar_draw_num(pos + '35 28 0' * CVAR(sbar_ammo_scale), clip, 3, 0, 16 * CVAR(sbar_ammo_scale), '1 1 0.5', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				}
			}
		} else if not(sbar_stat_items & IT_UNLIMITED_WEAPON_AMMO) {
			if (CVAR(sbar_showcurrentammo)) { // force showing current ammo only with conwidths < 800
				string ai;
				float at;
				if (sbar_stat_items & IT_SHELLS) { at = STAT_SHELLS; ai = "gfx/hud/sb_shells"; }
				else if (sbar_stat_items & IT_NAILS) { at = STAT_NAILS; ai = "gfx/hud/sb_bullets"; }
				else if (sbar_stat_items & IT_ROCKETS) { at = STAT_ROCKETS; ai = "gfx/hud/sb_rocket"; }
				else if (sbar_stat_items & IT_CELLS) { at = STAT_CELLS; ai = "gfx/hud/sb_cells"; }
				else at = 0;
				if (at) {
					a = getstati(at);
					drawpic(pos + '106 13 0' * CVAR(sbar_ammo_scale), ai, '24 24 0' * CVAR(sbar_ammo_scale), '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
					if (a < 10)
						sbar_draw_num(pos + '35 15 0' * CVAR(sbar_ammo_scale), a, 3, 0, 24 * CVAR(sbar_ammo_scale), '0.7 0 0', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					else
						sbar_draw_num(pos + '35 15 0' * CVAR(sbar_ammo_scale), a, 3, 0, 24 * CVAR(sbar_ammo_scale), '1 1 1', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				}
			} else {
				a = getstati(STAT_SHELLS);
				if (a > 0) {
					sbar_ammo_draw(pos, a, sbar_stat_items & IT_SHELLS, "gfx/hud/sb_shells");
				}
				a = getstati(STAT_NAILS);
				if (a > 0) {
					sbar_ammo_draw(pos + '0 26' * CVAR(sbar_ammo_scale), a, sbar_stat_items & IT_NAILS, "gfx/hud/sb_bullets");
				}
				a = getstati(STAT_ROCKETS);
				if (a > 0) {
					sbar_ammo_draw(pos + '86 0' * CVAR(sbar_ammo_scale), a, sbar_stat_items & IT_ROCKETS, "gfx/hud/sb_rocket");
				}
				a = getstati(STAT_CELLS);
				if (a > 0) {
					sbar_ammo_draw(pos + '86 26' * CVAR(sbar_ammo_scale), a, sbar_stat_items & IT_CELLS, "gfx/hud/sb_cells");
				}
			}
		}
		// nades
		float hgtype = getstati(STAT_HGTYPE);
		if (hgtype) {
			vector hgapos;
			hgapos_x = 0;
			hgapos_y = CVAR(vid_conheight) - CVAR(vid_conheight) / 7;
			hgapos_z = 0;
			float hgtype2 = getstati(STAT_HGTYPE2);
			float hgammo = getstati(STAT_HGAMMO);
			float hgdetons = getstati(STAT_HGDETONABLES);
			float hgcd, hgcd2;
			hgcd = getstatf(STAT_HGREFIRE) - server_time;
			// handgrenade force meter
			float hgstat = getstatf(STAT_HGFORCE);
			if (hgstat) {
				float hgls = getstatf(STAT_HGLAUNCH);
				if (hgstat) {
					sbar_hg_alpha = approach(sbar_hg_alpha, 1, 5 * view_drawframetime);
				} else {
					sbar_hg_alpha = approach(sbar_hg_alpha, 0, 5 * view_drawframetime);
				}
				sbar_hg_visual = approach(sbar_hg_visual, hgstat, view_drawframetime * hgls);
				hgstat = sbar_hg_visual;
				if (sbar_hg_alpha) {
					vector hgpos;
					hgpos_x = CVAR(vid_conwidth) / 2;
					hgpos_y = CVAR(vid_conheight) - CVAR(vid_conheight) / 4;
					draw_progress_fragmented(hgpos, '120 5 0', hgstat, 0.7 * sbar_hg_alpha, '1 0 0' + '0 1 0' * (1 - hgstat), 1);
				}
			} else {
				sbar_hg_alpha = 0;
				sbar_hg_visual = 0;
			}
			if (hgtype2) {
				hgcd2 = getstatf(STAT_HGREFIRE2) - server_time;
			}
			if (getstati(STAT_HGSHIELDSTORE)) {
				draw_progress_fragmented('0.5 0 0' * CVAR(vid_conwidth) + hgapos - sbar_fontsize_y * '0 2.5 0', '25 0 0' * sbar_fontsize_x + '0 7 0',
						getstati(STAT_HGSHIELDSTORE) / getstati(STAT_HGSHIELDSTOREMAX), 0.7, '1 0.3 0',
						getstati(STAT_HGSHIELDSTOREMAX) / getstati(STAT_HGSHIELDDAMAGEPERSHOT));
			}
			if (getstati(STAT_STEALTH)) {
				draw_string_colorcoded_center(hgapos - sbar_fontsize_y * ('0 2 0'/* + '0 1 0' * !!adept */), strcat(
						"^3Shoot or press ^1", strtoupper(input_command_key("drop weapon", "dropweapon")),
						" ^3to ", /* if (adept) "suspend" else */ "cancel", " stealth (^1", ftos(getstati(STAT_STEALTH)), " ^3seconds remaining)"),
						sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
			} else if (getstati(STAT_STEALTH_SAVED)) {
				draw_string_colorcoded_center(hgapos - sbar_fontsize_y * '0 2 0', strcat(
						"^3Press ^1", strtoupper(input_command_key("drop weapon", "dropweapon")),
						" ^3to re-enter stealth (^1", ftos(getstati(STAT_STEALTH_SAVED)), " ^3seconds remaining)"),
						sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
			} else if (getstatf(STAT_HGSHIELD)) {
				string smsg;
				if (getstati(STAT_HGSHIELDSTORE) > 0) {
					smsg = strcat("^3Press ^1", strtoupper(input_command_key("drop weapon", "dropweapon")),
							" ^3to discharge your ", nadget_TypeToExpandedName(hgtype),
							" for ^1", ftos(getstati(STAT_HGSHIELDSTORE)), " ^3damage");
				} else {
					smsg = strcat("^3Press ^1", strtoupper(input_command_key("drop weapon", "dropweapon")),
							" ^3to cancel your ", ((getstati(STAT_HGSHIELDSTORE) < 0) ? "discharge" : nadget_TypeToExpandedName(hgtype)));
				}
				draw_string_colorcoded_center(hgapos - sbar_fontsize_y * '0 2 0', smsg, sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
			} else if (hgdetons) {
				draw_string_colorcoded_center(hgapos - sbar_fontsize_y * '0 2 0', strcat(
						"^3Press ^1", strtoupper(input_command_key("drop weapon", "dropweapon")),
						" ^3to trigger your nadget",
						((hgdetons > 1) ? strcat("s (^2", ftos(hgdetons), "^3)") : "")),
						sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
			} else if (hgtype == NADGET_GG && hgammo) {
				draw_string_colorcoded_center(hgapos - sbar_fontsize_y * '0 2 0', strcat("^3Press ^1", strtoupper(input_command_key("hook / nadget key", "+hook")), " ^3to win!"), sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
			}
			string hgicon = nadget_TypeToIcon(hgtype, TRUE, 0);
			hgapos = sbar_position(CVAR(sbar_nadget_position), '74 24' * CVAR(sbar_nadget_scale));
			float hgregen = sbar_nadget_regen(STAT_HGTYPE, STAT_HGREGEN, STAT_HGREGENMAX) - hgregen;
			vector hgrsize;
			if (hgregen && hgregen != 1) {
				hgrsize = '64 16 0' * CVAR(sbar_nadget_scale);
				hgrsize_x *= hgregen;
				drawfill(hgapos + '4 4' * CVAR(sbar_nadget_scale), hgrsize, '1 1 1' - '0 0.5 0.5' * getstati(STAT_HGREGENPAUSED), 0.5 * sbar_alpha_fg, DRAWFLAG_NORMAL);
			}
			sbar_draw_num(hgapos, hgammo, 2, 0, 24 * CVAR(sbar_nadget_scale), '1 1 1', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			drawpic(hgapos + '48 0' * CVAR(sbar_nadget_scale), hgicon, '22 22' * CVAR(sbar_nadget_scale), '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
			if (hgtype2) {
				hgapos = sbar_position(CVAR(sbar_nadget2_position), '74 24' * CVAR(sbar_nadget2_scale));
				hgicon = nadget_TypeToIcon(hgtype2, TRUE, 0);
				float hgregen2 = sbar_nadget_regen(STAT_HGTYPE2, STAT_HGREGEN2, STAT_HGREGENMAX2) - hgregen2;
				if (hgregen2 && hgregen2 != 1) {
					hgrsize = '64 16 0' * CVAR(sbar_nadget2_scale);
					hgrsize_x *= hgregen2;
					drawfill(hgapos + '4 4' * CVAR(sbar_nadget2_scale), hgrsize, '1 1 1' - '0 0.5 0.5' * getstati(STAT_HGREGENPAUSED2), 0.5 * sbar_alpha_fg, DRAWFLAG_NORMAL);
				}
				hgammo = getstati(STAT_HGAMMO2);
				sbar_draw_num(hgapos, hgammo, 2, 0, 24 * CVAR(sbar_nadget2_scale), '1 1 1', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				drawpic(hgapos + '48 0' * CVAR(sbar_nadget2_scale), hgicon, '22 22' * CVAR(sbar_nadget2_scale), '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
			}
		}
		// draw scores and timer
		sbar_score_draw();
		sbar_timer();
		// draw strength/invincibility icon and timer
		sbar_powerups_draw();
		a = getstati(STAT_RUNES);
		if (a) {
			pos_x = 0;
			pos_y = CVAR(vid_conheight) - 50 - sbar_fontsize_y;
			s = "";
			for (i = RUNE_FIRST; i <= RUNE_LAST; i *= 2) {
				if (i & a)
					s = strcat(s, " ", rune_name(i));
			}
			draw_string_colorcoded_center(pos, s, sbar_fontsize, 0.4, DRAWFLAG_NORMAL);
		}
		// draw gametype specific icons
		sbar_gametype_hud();
	}
}

vector(vector v) sbar_font_size {
	if (v_x == 0)
		v = '8 8 0';

	if (v_y == 0)
		v_y = v_x;

	v_z = 0;
	return v;
}
