void drawstringright(vector, string, vector, vector, float, float);
void drawstringcenter(vector, string, vector, vector, float, float);
void drawcolorcodedstringcenter(vector, string, vector, float, float);

float weapon_hits[WEP_COUNT];
float weapon_fired[WEP_COUNT];
float weapon_number;
float stat_items;
// vectors for top right, bottom right, bottom and bottom left corners
vector topright;
vector bottom;
vector bottomright;
vector bottomleft;


float weapontime;

float sbar_alpha_fg;
float sbar_alpha_bg;
float sbar_border_thickness;

float ps_primary, ps_secondary;
float ts_primary, ts_secondary;

vector _color;
float SCOREBOARD_OFFSET = 50;
#define TIME_DECIMALS 2

#define FLAG_ANIM_LINEAR(frames,rate,offs) math_mod(floor((time) * (rate) + (offs)), frames)
#define FLAG_ANIM_SINE(frames,rate,offs) (frames - 1) * (sin(time * rate + offs) * 0.5 + 0.5)

float FlagIcon_Animate(string cn) {
	var animparams = stov(cvar_string(strcat("_flagicon_", cn, "_animparams")));

	if(!animparams_x) {
		return -1;
	}

	return switch(cvar(strcat("_flagicon_", cn, "_animparams"))) {
		default: case 0: FLAG_ANIM_LINEAR(animparams_x, animparams_y, animparams_z),
				 case 1: FLAG_ANIM_SINE(animparams_x, animparams_y, animparams_z)
	};
}

string FlagIcon(string cn) {
    string i;

    if(cn == "")
        return "gfx/flagicons/xx";

    i = strcat("gfx/flagicons/", cn);
    float aframe = FlagIcon_Animate(cn);
    if(aframe >= 0)
        i = strcat(i, "-", ftos(fabs(rint(aframe))));

    if(drawgetimagesize(i) == '0 0 0')
        return "gfx/flagicons/xx";

    return i;
}

void CSQC_kh_hudreset();
void CSQC_kh_hud();
void CSQC_ctf_hudreset();
void CSQC_ctf_hud();
void CSQC_single_hud();
void CSQC_nb_hud();
void Sbar_FinaleOverlay()
{
	/*vector pos;
	pos_x = (CVAR(vid_conwidth) - 1)/2;
	pos_y = 16;
	pos_z = 0;*/

	//drawpic(pos, "gfx/finale", '0 0 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

	//drawstring(pos, "END", sbar_fontsize, '1 1 1', 1, DRAWFLAG_NORMAL);
	if (mv_active)
		MapVote_Draw();
}

float weaponspace[10];
float weapon_first, weapon_last;
void Sbar_DrawWeapon_Clear()
{
	float idx;
	weapon_first = -2;
	weapon_last = -1;
	for(idx = 0; idx < 10; ++idx)
		weaponspace[idx] = 0;
	for(idx = 0; idx <= 23; ++idx)
	{
		if(weaponimpulse[idx] >= 0)
		{
			if(weapon_first < 0)
				weapon_first = idx;
			weapon_last = idx;
		}
	}
}
void Sbar_DrawWeapon(float nr, float fade, float active, float wc)
{
	vector pos, vsize;
	float value, idx, imp, sp;

	imp = weaponimpulse[nr];
	if(imp == 0)
		idx = 9;
	else
		idx = imp - 1;

	value = (active) ? 2 : 0.75;
	_color_x = _color_y = _color_z = value;

	// width = 300, height = 100
	const float w_width = 48, w_height = 24, w_space = 2, font_size = 12;

	sp = weaponspace[idx] + 1;
	weaponspace[idx] = sp;

	//pos_x = (CVAR(vid_conwidth) + 6 - w_width * 9) * 0.5 + w_width * idx;
	//pos_y = (CVAR(vid_conheight) - w_height * sp) - 38; // move 38 pixels up
	pos_x = CVAR(vid_conwidth) - w_width * sp - w_space;
	pos_y = CVAR(vid_conheight) - 90 - w_height * (idx);
	pos_z = 0;
	vsize_x = w_width;
	vsize_y = w_height;
	vsize_z = 0;
	if (active)
		drawpic(pos, "gfx/hud/sb_ammobg", vsize, '1 1 1', fade * sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos, strcat("gfx/hud/inv_weapon", ftos(nr)), vsize, _color, fade * sbar_alpha_fg, DRAWFLAG_NORMAL);
	pos_x += w_space;
	//pos_y += w_space;
	vsize_x = font_size;
	vsize_y = font_size;
	vsize_z = 0;
	if (sp == 1)
		drawstring(pos, ftos(imp), vsize, '1 1 1', sbar_alpha_fg * fade, DRAWFLAG_NORMAL);
}

void Sbar_DrawXNum (vector pos, float num, float digits, float showminusplus, float lettersize, vector rgb, float highlighted, float stroke, float alpha, float dflags)
{
	float l, i;
	string str, tmp, l_length;
	float minus, plus;
	vector vsize, num_color;

	vsize_x = vsize_y = lettersize;
	vsize_z = 0;

	// showminusplus 1: always prefix with minus sign (useful in race distribution display)
	// showminusplus 2: always prefix with plus sign (useful in race distribution display)
	// showminusplus 3: prefix with minus sign if negative, plus sign if positive (useful in score distribution display)

	if((showminusplus == 2 && num >= 0) || (num > 0 && showminusplus == 3))
	{
		plus = true;
		pos_x -= lettersize;
	} else
		plus = false;

	if(num < 0 || (num < 0 && showminusplus == 3) || (showminusplus == 1 && num <= 0))
	{
		minus = true;
		num = -num;
		pos_x -= lettersize;
	} else
		minus = false;

	if(digits < 0)
	{
		tmp = ftos(num);
		digits = -digits;
		str = strcat(substring("0000000000", 0, digits - strlen(tmp)), tmp);
	} else
		str = ftos(num);

	l = strlen(str);
	l_length = ftos(l);

	if(l > digits)
	{
		str = substring(str, l-digits, 999);
		l = strlen(str);
	} else if(l < digits)
		pos_x += (digits-l) * lettersize;

	if (highlighted == 1) {
		vector hl_size;
		hl_size_x = vsize_x * l + vsize_x * 0.2;
		hl_size_y = vsize_y * 1.1;
		hl_size_z = 0;
		if(minus)
			hl_size_x = hl_size_x + vsize_x;

		vector hl_pos;
		hl_pos_x = pos_x - lettersize/10;
		hl_pos_y = pos_y - lettersize/20;
		hl_pos_z = 0;

		drawpic(hl_pos, strcat("gfx/hud/sb_highlight_", l_length), hl_size, '1 1 1', alpha, dflags);
	}

	if (stroke == 1)
		num_color = '1 1 1';
	else
		num_color = rgb;

	if(minus)
	{
		if (stroke == 1)
			drawpic(pos, "gfx/hud/num_minus_stroke", vsize, rgb, alpha, dflags);
		drawpic(pos, "gfx/hud/num_minus", vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	} else if(plus)
	{
		if (stroke == 1)
			drawpic(pos, "gfx/hud/num_plus_stroke", vsize, rgb, alpha, dflags);
		drawpic(pos, "gfx/hud/num_plus", vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	}

	for(i = 0; i < l; ++i)
	{
		tmp = substring(str, i, 1);
		if (stroke == 1)
			drawpic(pos, strcat("gfx/hud/num_", tmp, "_stroke"), vsize, rgb, alpha, dflags);
		drawpic(pos, strcat("gfx/hud/num_", tmp), vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	}
}

void Sbar_DrawXNum_Colored (vector pos, float x, float lettersize, float alpha)
{
	if(x > 200) {
		_color_x = 0;
		_color_y = 1;
		_color_z = 0;
	}
	else if(x > 150) {
		_color_x = 0.4 - (x-150)*0.02 * 0.4; //red value between 0.4 -> 0
		_color_y = 0.9 + (x-150)*0.02 * 0.1; // green value between 0.9 -> 1
		_color_z = 0;
	}
	else if(x > 100) {
		_color_x = 1 - (x-100)*0.02 * 0.6; //red value between 1 -> 0.4
		_color_y = 1 - (x-100)*0.02 * 0.1; // green value between 1 -> 0.9
		_color_z = 1 - (x-100)*0.02; // blue value between 1 -> 0
	}
	else if(x > 50) {
		_color_x = 1;
		_color_y = 1;
		_color_z = 0.2 + (x-50)*0.02 * 0.8; // blue value between 0.2 -> 1
	}
	else if(x > 20) {
		_color_x = 1;
		_color_y = (x-20)*90/27/100; // green value between 0 -> 1
		_color_z = (x-20)*90/27/100 * 0.2; // blue value between 0 -> 0.2
	}
	else {
		_color_x = 1;
		_color_y = 0;
		_color_z = 0;
	}
	Sbar_DrawXNum(pos, x, 3, 0, lettersize, _color, 0, 0, alpha, DRAWFLAG_NORMAL);
}

void Cmd_Sbar_SetFields(float argc);
void Sbar_InitScores()
{
	float i, f;

	ps_primary = ps_secondary = ts_primary = ts_secondary = -1;
	for(i = 0; i < MAX_SCORE; ++i)
	{
		f = (scores_flags[i] & SFL_SORT_PRIO_MASK);
		if(f == SFL_SORT_PRIO_PRIMARY)
			ps_primary = i;
		if(f == SFL_SORT_PRIO_SECONDARY)
			ps_secondary = i;
	}
	if(ps_secondary == -1)
		ps_secondary = ps_primary;

	for(i = 0; i < MAX_TEAMSCORE; ++i)
	{
		f = (teamscores_flags[i] & SFL_SORT_PRIO_MASK);
		if(f == SFL_SORT_PRIO_PRIMARY)
			ts_primary = i;
		if(f == SFL_SORT_PRIO_SECONDARY)
			ts_secondary = i;
	}
	if(ts_secondary == -1)
		ts_secondary = ts_primary;

	Cmd_Sbar_SetFields(0);
}

float Sbar_ComparePlayerScores(entity left, entity right)
{
	float vl, vr;
	vl = GetPlayerColor(left.sv_entnum);
	vr = GetPlayerColor(right.sv_entnum);

	if(vl > vr)
		return true;
	if(vl < vr)
		return false;

	if(vl == COLOR_SPECTATOR)
	{
		// FIRST the one with scores (spectators), THEN the ones without (downloaders)
		// no other sorting
		if(!left.gotscores && right.gotscores)
			return true;
		return false;
	}

	vl = left.scores[ps_primary];
	vr = right.scores[ps_primary];
	if(scores_flags[ps_primary] & SFL_ZERO_IS_WORST)
	{
		if(vl == 0 && vr != 0)
			return 1;
		if(vl != 0 && vr == 0)
			return 0;
	}
	if(vl > vr)
		return IS_INCREASING(scores_flags[ps_primary]);
	if(vl < vr)
		return IS_DECREASING(scores_flags[ps_primary]);

	vl = left.scores[ps_secondary];
	vr = right.scores[ps_secondary];
	if(scores_flags[ps_secondary] & SFL_ZERO_IS_WORST)
	{
		if(vl == 0 && vr != 0)
			return 1;
		if(vl != 0 && vr == 0)
			return 0;
	}
	if(vl > vr)
		return IS_INCREASING(scores_flags[ps_secondary]);
	if(vl < vr)
		return IS_DECREASING(scores_flags[ps_secondary]);

	return false;
}

void Sbar_UpdatePlayerPos(entity player)
{
	for(other = player.sort_next; other && Sbar_ComparePlayerScores(player, other); other = player.sort_next)
	{
		SORT_SWAP(player, other);
	}
	for(other = player.sort_prev; other != players && Sbar_ComparePlayerScores(other, player); other = player.sort_prev)
	{
		SORT_SWAP(other, player);
	}
}

float Sbar_CompareTeamScores(entity left, entity right)
{
	float vl, vr;

	if(left.team == COLOR_SPECTATOR)
		return 1;
	if(right.team == COLOR_SPECTATOR)
		return 0;

	vl = left.teamscores[ts_primary];
	vr = right.teamscores[ts_primary];
	if(vl > vr)
		return IS_INCREASING(teamscores_flags[ts_primary]);
	if(vl < vr)
		return IS_DECREASING(teamscores_flags[ts_primary]);

	vl = left.teamscores[ts_secondary];
	vr = right.teamscores[ts_secondary];
	if(vl > vr)
		return IS_INCREASING(teamscores_flags[ts_secondary]);
	if(vl < vr)
		return IS_DECREASING(teamscores_flags[ts_secondary]);

	return false;
}

void Sbar_UpdateTeamPos(entity Team)
{
	for(other = Team.sort_next; other && Sbar_CompareTeamScores(Team, other); other = Team.sort_next)
	{
		SORT_SWAP(Team, other);
	}
	for(other = Team.sort_prev; other != teams && Sbar_CompareTeamScores(other, Team); other = Team.sort_prev)
	{
		SORT_SWAP(other, Team);
	}
}

void Cmd_Sbar_Help(float argc)
{
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

string Sbar_DefaultColumnLayout()
{
	return strcat( // fteqcc sucks
		"ping pl ?cn name | ",
		"-teams,race,single/kills -teams,single/deaths -teams,race,single/suicides -race,dm,tdm,coop,single/frags ", // tdm already has this in "score"
		"?damage ?bestwep +ca,ft,surv,catf,ctft,khca,khft,lms/status "
		"+ctf,catf,ctft/caps +ctf,catf,ctft/pickups +ctf,catf,ctft/fckills +ctf,catf,ctft/returns ",
		"+kh,khca,khft/caps +kh,khca,khft/pushes +kh,khca,khft/destroyed ",
		"?+race/laps ?+race/time ?+race/fastest ",
		"+as/objectives +nexball/faults +nexball/goals ",
		"+ft,ctft,khft/revs -race,nexball/score +lms/lives");
}

void Cmd_Sbar_SetFields(float argc)
{
	float i, j, slash;
	string str, pattern;
	float digit;
	float have_name, have_primary, have_secondary, have_separator;
	float missing;

	// TODO: re enable with gametype dependant cvars?
	if(argc < 2) // no arguments provided
		argc = tokenizebyseparator(strcat("x ", cvar_string("sbar_columns")), " ");

	if(argc < 2)
		argc = tokenizebyseparator(strcat("x ", Sbar_DefaultColumnLayout()), " ");

	if(argc == 2)
	{
		if(argv(1) == "default")
			argc = tokenizebyseparator(strcat("x ", Sbar_DefaultColumnLayout()), " ");
		else if(argv(1) == "all")
		{
			string s;
			s = "ping pl ?cn color name |";
			for(i = 0; i < MAX_SCORE; ++i)
			{
				if(i != ps_primary)
				if(i != ps_secondary)
				if(scores_label[i] != "")
					s = strcat(s, " ", scores_label[i]);
			}
			if(ps_secondary != ps_primary)
				s = strcat(s, " ", scores_label[ps_secondary]);
			s = strcat(s, " ", scores_label[ps_primary]);
			argc = tokenizebyseparator(strcat("x ", s), " ");
		}
	}


	sbar_num_fields = 0;

	drawfont = sbar_font;
	digit = stringwidth("0123456789", FALSE) / 10;

	for(i = 0; i < argc - 1; ++i)
	{
		float nocomplain;
		str = argv(i+1);

		nocomplain = FALSE;
		if(substring(str, 0, 1) == "?")
		{
			nocomplain = TRUE;
			str = substring(str, 1, strlen(str) - 1);
		}

		slash = strstrofs(str, "/", 0);
		if(slash >= 0)
		{
			pattern = substring(str, 0, slash);
			str = substring(str, slash + 1, strlen(str) - (slash + 1));

			if not(gametype_filter(gametype, teamplay, pattern))
				continue;
		}

		strunzone(sbar_title[sbar_num_fields]);
		sbar_title[sbar_num_fields] = strzone(str);
		sbar_size[sbar_num_fields] = stringwidth(str, FALSE);
		str = strtolower(str);

		if(str == "ping") {
			sbar_field[sbar_num_fields] = SP_PING;
		} else if(str == "pl") {
			sbar_field[sbar_num_fields] = SP_PL;
		} else if(str == "kd" || str == "kdr" || str == "kdratio" || str == "k/d") {
			sbar_field[sbar_num_fields] = SP_KDRATIO;
		} else if(str == "cn" && sv_ip2country) {
			sbar_field[sbar_num_fields] = SP_COUNTRY;
		} else if(str == "name" || str == "nick") {
			sbar_field[sbar_num_fields] = SP_NAME;
			have_name = 1;
		} else if(str == "status") {
			sbar_field[sbar_num_fields] = SP_STATUS;
		} else if(str == "|") {
			sbar_field[sbar_num_fields] = SP_SEPARATOR;
			have_separator = 1;
		} else {
			for(j = 0; j < MAX_SCORE; ++j)
				if(str == strtolower(scores_label[j]))
					goto found; // sorry, but otherwise fteqcc -O3 miscompiles this and warns about "unreachable code"
:notfound
			if(str == "frags")
			{
				j = SP_FRAGS;
			}
			else
			{
				if not(nocomplain)
					print(strcat("^1Error:^7 Unknown score field: '", str, "'\n"));
				continue;
			}
:found
			if(str == "bestwep")
				sbar_field[sbar_num_fields] = SP_BESTWEP;
			else
				sbar_field[sbar_num_fields] = j;

			if(j == ps_primary)
				have_primary = 1;
			if(j == ps_secondary)
				have_secondary = 1;
		}
		++sbar_num_fields;
		if(sbar_num_fields >= MAX_SBAR_FIELDS)
			break;
	}

	if(scores_flags[ps_primary] & SFL_ALLOW_HIDE)
		have_primary = 1;
	if(scores_flags[ps_secondary] & SFL_ALLOW_HIDE)
		have_secondary = 1;
	if(ps_primary == ps_secondary)
		have_secondary = 1;
	missing = (!have_primary) + (!have_secondary) + (!have_separator) + (!have_name);

	if(sbar_num_fields+missing < MAX_SBAR_FIELDS)
	{
		if(!have_name)
		{
			strunzone(sbar_title[sbar_num_fields]);
			for(i = sbar_num_fields; i > 0; --i)
			{
				sbar_title[i] = sbar_title[i-1];
				sbar_size[i] = sbar_size[i-1];
				sbar_field[i] = sbar_field[i-1];
			}
			sbar_title[0] = strzone("name");
			sbar_field[0] = SP_NAME;
			++sbar_num_fields;
			print("fixed missing field 'name'\n");

			if(!have_separator)
			{
				strunzone(sbar_title[sbar_num_fields]);
				for(i = sbar_num_fields; i > 1; --i)
				{
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
		}
		else if(!have_separator)
		{
			strunzone(sbar_title[sbar_num_fields]);
			sbar_title[sbar_num_fields] = strzone("|");
			sbar_size[sbar_num_fields] = stringwidth("|", FALSE);
			sbar_field[sbar_num_fields] = SP_SEPARATOR;
			++sbar_num_fields;
			print("fixed missing field '|'\n");
		}
		if(!have_secondary)
		{
			strunzone(sbar_title[sbar_num_fields]);
			sbar_title[sbar_num_fields] = strzone(scores_label[ps_secondary]);
			sbar_size[sbar_num_fields] = stringwidth(sbar_title[sbar_num_fields], FALSE);
			sbar_field[sbar_num_fields] = ps_secondary;
			++sbar_num_fields;
			print("fixed missing field '", scores_label[ps_secondary], "'\n");
		}
		if(!have_primary)
		{
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

// MOVEUP::
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
string Sbar_GetField(entity pl, float field)
{
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
	switch(field)
	{
		case SP_PING:
			if not(pl.gotscores)
				return "\x8D\x8D\x8D"; // >>> sign
			str = getplayerkey(pl.sv_entnum, "ping");
			if(str == "0")
				return "N/A";
			tmp = max(0, min(220, stof(str)-80)) / 220;
			sbar_field_rgb = '1 1 1' - '0 1 1'*tmp;
			return str;

		case SP_PL:
			if not(pl.gotscores)
				return "N/A";
			str = getplayerkey(pl.sv_entnum, "pl");
			if(str == "0")
				return "";
			tmp = bound(0, stof(str), 20) / 20; // 20% is REALLY BAD pl
			sbar_field_rgb = '1 0.5 0.5' - '0 0.5 0.5'*tmp;
			return str;

		case SP_COUNTRY:
            float char0 = pl.(scores[SP_COUNTRY_FIELD]) & 0xff;
            float char1 = floor(pl.(scores[SP_COUNTRY_FIELD]) / 256) & 0xff;

            if(!char0 || !char1)
                return "";

            return strcat(chr2str(char0), chr2str(char1));

		case SP_NAME:
			if(pl.ready)
			{
				sbar_field_icon0 = "gfx/sb_player_ready";
			}
			else if(!teamplay)
			{
				f = stof(getplayerkey(pl.sv_entnum, "colors"));
				{
					sbar_field_icon0 = "gfx/sb_playercolor_base";
					sbar_field_icon1 = "gfx/sb_playercolor_shirt";
					sbar_field_icon1_rgb = colormap_palette_color(floor(f / 16), 0);
					sbar_field_icon2 = "gfx/sb_playercolor_pants";
					sbar_field_icon2_rgb = colormap_palette_color(math_mod(f, 16), 1);
				}
			}
			return strcat(GetPlayerName(pl.sv_entnum), "^0#", ftos(pl.sv_entnum + 1));
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

			if(denom == 0) {
				sbar_field_rgb = '0 1 0';
				str = ftos(num);
			} else if(num <= 0) {
				sbar_field_rgb = '1 0 0';
				str = ftos(num/denom);
			} else
				str = ftos(num/denom);

			tmp = strstrofs(str, ".", 0);
			if(tmp > 0)
				str = substring(str, 0, tmp+2);
			return str;

		case SP_BESTWEP:
			tmp = pl.(scores[SP_BESTWEP_FIELD]);
			return score_string(0, tmp);

		default:
			tmp = pl.(scores[field]);
			f = scores_flags[field];
			if(field == ps_primary)
				sbar_field_rgb = '1 1 0';
			else if(field == ps_secondary)
				sbar_field_rgb = '0 1 1';
			else
				sbar_field_rgb = '1 1 1';
			return score_string(f, tmp);
	}
	//return "error";
}

float xmin, xmax, ymin, ymax, sbwidth;
float sbar_fixscoreboardcolumnwidth_len;
float sbar_fixscoreboardcolumnwidth_iconlen;
float sbar_fixscoreboardcolumnwidth_marginlen;

string Sbar_FixScoreboardColumnWidth(float i, string str)
{
	float field, f;
	vector sz;
	field = sbar_field[i];

	sbar_fixscoreboardcolumnwidth_iconlen = 0;

	if(sbar_field_icon0 != "")
	{
		sz = drawgetimagesize(sbar_field_icon0);
		f = sz_x / sz_y;
		if(sbar_fixscoreboardcolumnwidth_iconlen < f)
			sbar_fixscoreboardcolumnwidth_iconlen = f;
	}

	if(sbar_field_icon1 != "")
	{
		sz = drawgetimagesize(sbar_field_icon1);
		f = sz_x / sz_y;
		if(sbar_fixscoreboardcolumnwidth_iconlen < f)
			sbar_fixscoreboardcolumnwidth_iconlen = f;
	}

	if(sbar_field_icon2 != "")
	{
		sz = drawgetimagesize(sbar_field_icon2);
		f = sz_x / sz_y;
		if(sbar_fixscoreboardcolumnwidth_iconlen < f)
			sbar_fixscoreboardcolumnwidth_iconlen = f;
	}

	sbar_fixscoreboardcolumnwidth_iconlen *= sbar_fontsize_y / sbar_fontsize_x; // fix icon aspect

	if(sbar_fixscoreboardcolumnwidth_iconlen != 0)
		sbar_fixscoreboardcolumnwidth_marginlen = stringwidth(" ", FALSE);
	else
		sbar_fixscoreboardcolumnwidth_marginlen = 0;

	if(field == SP_NAME) // name gets all remaining space
	{
		float namesize, j;
		namesize = sbwidth / sbar_fontsize_x;
		for(j = 0; j < sbar_num_fields; ++j)
			if(j != i)
				if (sbar_field[i] != SP_SEPARATOR)
					namesize -= sbar_size[j] + 1;
		namesize += 1;
		sbar_size[i] = namesize;

		if (sbar_fixscoreboardcolumnwidth_iconlen != 0)
			namesize -= sbar_fixscoreboardcolumnwidth_marginlen + sbar_fixscoreboardcolumnwidth_iconlen;
		str = textShortenToWidth(str, namesize, str_width_colors);
		sbar_fixscoreboardcolumnwidth_len = stringwidth(str, TRUE);
	}
	else if(field == SP_COUNTRY)
		sbar_fixscoreboardcolumnwidth_len = stringwidth("XX", FALSE);
	else if(field == SP_BESTWEP)
		sbar_fixscoreboardcolumnwidth_len = stringwidth("XXXXXX", FALSE);
	else
		sbar_fixscoreboardcolumnwidth_len = stringwidth(str, FALSE);

	f = sbar_fixscoreboardcolumnwidth_len + sbar_fixscoreboardcolumnwidth_marginlen + sbar_fixscoreboardcolumnwidth_iconlen;
	if(sbar_size[i] < f)
		sbar_size[i] = f;

	return str;
}

void Sbar_PrintScoreboardItem(vector pos, entity pl, float is_self, float pl_number)
{
	vector tmp;
	string str;
	float i, field, f, w;
	float is_spec;
	is_spec = (GetPlayerColor(pl.sv_entnum) == COLOR_SPECTATOR);

	// Layout:
	tmp_x = sbwidth;
	tmp_y = sbar_fontsize_y * 1.25;
	tmp_z = 0;

	// alternated rows highlighting
	if (is_self)
		drawfill(pos - '1 1 0', tmp + '2 0 0', '1 1 1', 0.25, DRAWFLAG_NORMAL);
	else
	{
		if (CVAR(sbar_scoreboard_highlight))
			if(!math_mod(pl_number,2))
				drawfill(pos - '1 1 0', tmp + '2 0 0', '1 1 1', 0.09, DRAWFLAG_NORMAL);
	}

	tmp_y = 0;
	for(i = 0; i < sbar_num_fields; ++i)
	{
		field = sbar_field[i];
		if(field == SP_SEPARATOR)
			break;

		if(is_spec && field != SP_NAME && field != SP_PING && field != SP_COUNTRY) {
			pos_x += sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;
			continue;
		}
		str = Sbar_GetField(pl, field);
		str = Sbar_FixScoreboardColumnWidth(i, str);

		pos_x += sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;

		if(field == SP_NAME) {
			tmp_x = sbar_fontsize_x*(sbar_size[i] - sbar_fixscoreboardcolumnwidth_iconlen - sbar_fixscoreboardcolumnwidth_marginlen) + sbar_fontsize_x;
			drawcolorcodedstring(pos - tmp, str, sbar_fontsize, 1, DRAWFLAG_NORMAL);
		} else if(field == SP_COUNTRY) {
			tmp_x = sbar_fixscoreboardcolumnwidth_len*sbar_fontsize_x + sbar_fontsize_x;
			drawpic(pos - tmp, FlagIcon(str), '1.5 1 0' * sbar_fontsize_x, '1 1 1', 1.0, DRAWFLAG_NORMAL);
		} else if(field == SP_BESTWEP) {
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
		if(field == SP_NAME)
		if not(is_spec) {
			if(sbar_field_icon0 != "")
				drawpic(pos - tmp, sbar_field_icon0, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon1_rgb, sbar_field_icon0_alpha, DRAWFLAG_NORMAL);

			if(sbar_field_icon1 != "")
				drawpic(pos - tmp, sbar_field_icon1, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon1_rgb, sbar_field_icon1_alpha, DRAWFLAG_NORMAL);

			if(sbar_field_icon2 != "")
				drawpic(pos - tmp, sbar_field_icon2, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon2_rgb, sbar_field_icon2_alpha, DRAWFLAG_NORMAL);
		}
	}
	if(sbar_field[i] == SP_SEPARATOR)
	{
		pos_x = xmax;
		for(i = sbar_num_fields-1; i > 0; --i)
		{
			field = sbar_field[i];
			if(field == SP_SEPARATOR)
				break;

			if(is_spec && field != SP_NAME && field != SP_PING) {
				pos_x -= sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;
				continue;
			}

			str = Sbar_GetField(pl, field);
			str = Sbar_FixScoreboardColumnWidth(i, str);

			if(field == SP_NAME) {
				tmp_x = sbar_fontsize_x*sbar_fixscoreboardcolumnwidth_len; // left or right aligned? let's put it right...
				drawcolorcodedstring(pos - tmp, str, sbar_fontsize, 1, DRAWFLAG_NORMAL);
			} else if(field == SP_COUNTRY) {
				tmp_x = sbar_fixscoreboardcolumnwidth_len*sbar_fontsize_x;
				drawpic(pos - tmp, FlagIcon(str), '1.5 1 0' * sbar_fontsize_x, '1 1 1', 1.0, DRAWFLAG_NORMAL);
			} else if(field == SP_BESTWEP) {
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

			tmp_x = sbar_fontsize_x*sbar_size[i];
			if(field == SP_NAME)
			if not(is_spec) {
				if(sbar_field_icon0 != "")
					drawpic(pos - tmp, sbar_field_icon0, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon1_rgb, sbar_field_icon0_alpha, DRAWFLAG_NORMAL);
				if(sbar_field_icon1 != "")
					drawpic(pos - tmp, sbar_field_icon1, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon1_rgb, sbar_field_icon1_alpha, DRAWFLAG_NORMAL);
				if(sbar_field_icon2 != "")
					drawpic(pos - tmp, sbar_field_icon2, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon2_rgb, sbar_field_icon2_alpha, DRAWFLAG_NORMAL);
			}
			pos_x -= sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;
		}
	}
}

/*
 * Sbar_Scoreboard_MakeTable
 *
 * Makes a table for a team (for all playing players in DM) and fills it
 */

vector Sbar_Scoreboard_MakeTable(vector pos, entity tm, vector rgb, vector bg_size)
{
	float body_table_height, i;
	vector tmp, column_dim;
	entity pl;

	body_table_height = 1.25 * sbar_fontsize_y * max(1, tm.team_size); // no player? show 1 empty line

	pos -= '1 1 0';

	tmp_x = sbwidth + 2;
	tmp_y = 1.25 * sbar_fontsize_y;

	// rounded header
	drawpic(pos, "gfx/hud/sb_scoreboard_tableheader", tmp, '0.5 0.5 0.5', CVAR(sbar_scoreboard_alpha_bg), DRAWFLAG_NORMAL);

	// table border
	tmp_y += sbar_border_thickness;
	tmp_y += body_table_height;
	drawborderlines(sbar_border_thickness, pos, tmp, '0 0 0', CVAR(sbar_scoreboard_alpha_bg), DRAWFLAG_NORMAL); // more transparency for the scoreboard

	// separator header/table
	pos_y += 1.25 * sbar_fontsize_y;
	tmp_y = sbar_border_thickness;
	drawfill(pos, tmp, '0 0 0', CVAR(sbar_scoreboard_alpha_bg), DRAWFLAG_NORMAL);

	pos_y += sbar_border_thickness;

	// table background
	tmp_y = body_table_height;
	drawpic_tiled(pos, "gfx/hud/sb_scoreboard_bg", bg_size, tmp, rgb * CVAR(sbar_color_bg_team), CVAR(sbar_scoreboard_alpha_bg), DRAWFLAG_NORMAL);

	// anyway, apply some color
	//drawfill(pos, tmp + '2 0 0', rgb, 0.1, DRAWFLAG_NORMAL);

	// go back to the top to make alternated columns highlighting and to print the strings
	pos_y -= 1.25 * sbar_fontsize_y;
	pos_y -= sbar_border_thickness;

	pos += '1 1 0';

	if (CVAR(sbar_scoreboard_highlight))
	{
		column_dim_y = 1.25 * sbar_fontsize_y; // header
		column_dim_y += sbar_border_thickness;
		column_dim_y += body_table_height;
	}

	// print the strings of the columns headers and draw the columns
	for(i = 0; i < sbar_num_fields; ++i)
	{
		if(sbar_field[i] == SP_SEPARATOR)
			break;
		column_dim_x = sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;
		if (CVAR(sbar_scoreboard_highlight))
		{
			if (math_mod(i,2))
				drawfill(pos - '0 1 0' - sbar_fontsize_x / 2 * '1 0 0', column_dim, '0 0 0', CVAR(sbar_scoreboard_alpha_bg) * 0.2, DRAWFLAG_NORMAL);
		}
		drawstring(pos, sbar_title[i], sbar_fontsize, rgb, 1, DRAWFLAG_NORMAL);
		pos_x += column_dim_x;
	}
	if(sbar_field[i] == SP_SEPARATOR)
	{
		pos_x = xmax;
		tmp_y = 0;
		for(i = sbar_num_fields-1; i > 0; --i)
		{
			if(sbar_field[i] == SP_SEPARATOR)
				break;

			pos_x -= sbar_size[i]*sbar_fontsize_x;

			if (CVAR(sbar_scoreboard_highlight))
			{
				if (!math_mod(i,2))
				{
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

	pos_x = xmin;
	pos_y += 1.25 * sbar_fontsize_y; // skip the header
	pos_y += sbar_border_thickness;

	// fill the table and draw the rows
	i = 0;
	if (teamplay)
		for(pl = players.sort_next; pl; pl = pl.sort_next)
		{
			if(pl.team != tm.team)
				continue;
			Sbar_PrintScoreboardItem(pos, pl, (pl.sv_entnum == player_localentnum - 1), i);
			pos_y += 1.25 * sbar_fontsize_y;
			++i;
		}
	else
		for(pl = players.sort_next; pl; pl = pl.sort_next)
		{
			if(pl.team == COLOR_SPECTATOR)
				continue;
			Sbar_PrintScoreboardItem(pos, pl, (pl.sv_entnum == player_localentnum - 1), i);
			pos_y += 1.25 * sbar_fontsize_y;
			++i;
		}

	if (i == 0)
		pos_y += 1.25 * sbar_fontsize_y; // move to the end of the table
	pos_y += 1.25 * sbar_fontsize_y; // move empty row (out of the table)

	return pos;
}

float nextplayerscheck;
float lastpingstime;
void Sbar_DrawScoreboard()
{
	vector rgb, pos, tmp;
	entity pl, tm;
	draw_crosshair = FALSE;

	if (nextplayerscheck < time) { //Check for downloaders
	       float i;
	       entity e;
	       for(i = 0; i < maxclients; ++i) {
	               e = playerslots[i];
	               if(GetPlayerName(i) == "") {
	                       if(e.sort_prev) {
	                               SetTeam(e, -1);
	                               RemovePlayer(e);
	                               e.sort_prev = world;
	                       }
	               } else {
	                       if not(e.sort_prev) {
	                               if not(e)
	                                       playerslots[i] = e = spawn();

	                               e.sv_entnum = i;
	                               SetTeam(e, COLOR_SPECTATOR);
	                               RegisterPlayer(e);
	                               Sbar_UpdatePlayerPos(e);
	                       }
	               }
	       }
	       nextplayerscheck = time + 1;
	}

	if(time > lastpingstime + 10)
	{
		localcmd("pings\n");
		lastpingstime = time;
	}

	sbwidth = Sbar_GetWidth(6.5 * sbar_fontsize_y);

	xmin = 0.5 * (CVAR(vid_conwidth) - sbwidth);
	ymin = SCOREBOARD_OFFSET;

	xmax = CVAR(vid_conwidth) - xmin;
	ymax = CVAR(vid_conheight) - 0.2 * CVAR(vid_conheight);

	// Initializes position
	pos_x = xmin;
	pos_y = ymin;
	pos_z = 0;

	//drawfont = sbar_bigfont;
	//drawstringcenter('0 1 0' * ymin, "Scoreboard", '24 24 0', '1 1 1', 1, DRAWFLAG_NORMAL);

	//pos_y += 24 + 4;
	//pos_y += sbar_fontsize_y;
	drawfont = sbar_font;
	// Print info string
	string str;
	float tl, fl, ll;
	str = strcat("^7Playing ^3", strtoupper(gametype_name(gametype)), "^7 on ^2", shortmapname);
	drawcolorcodedstring(pos + '0.5 0 0' * (sbwidth - sbar_fontsize_x * stringwidth(str, TRUE)), str, sbar_fontsize, 0.8, DRAWFLAG_NORMAL);
	pos_y += sbar_fontsize_y;
	if (map_description != "") {
		str = strcat("^7(", map_description, "^7)");
		drawcolorcodedstring(pos + '0.5 0 0' * (sbwidth - sbar_fontsize_x * stringwidth(str, TRUE)), str, sbar_fontsize, 0.8, DRAWFLAG_NORMAL);
		pos_y += sbar_fontsize_y;
	}
	tl = getstatf(STAT_TIMELIMIT);
	fl = getstatf(STAT_FRAGLIMIT);
	ll = getstatf(STAT_LEADLIMIT);
	if(tl > 0)
		str = strcat("^7for ^1", ftos(tl), " minutes^7");
	else
		str = "";

	if(fl > 0)
	{
		if(tl > 0)
			str = strcat(str, " or");

		if(teamplay)
		{
			str = strcat(str, " until ^3", score_string(teamscores_flags[ts_primary], fl));
			if(teamscores_label[ts_primary] == "score")
				str = strcat(str, " points^7");
			else if(teamscores_label[ts_primary] == "fastest")
				str = strcat(str, " is beaten^7");
			else
				str = strcat(str, " ", teamscores_label[ts_primary]);
		}
		else
		{
			str = strcat(str, " until ^3", score_string(scores_flags[ps_primary], fl));
			if(scores_label[ps_primary] == "score")
				str = strcat(str, " points^7");
			else if(scores_label[ps_primary] == "fastest")
				str = strcat(str, " is beaten^7");
			else
				str = strcat(str, " ", scores_label[ps_primary]);
		}
	}
	if(ll > 0)
	{
		if(tl > 0 || fl > 0)
			str = strcat(str, " or");
		if(teamplay)
		{
			str = strcat(str, " until a lead of ^3", score_string(teamscores_flags[ts_primary], ll));
			if(teamscores_label[ts_primary] == "score")
				str = strcat(str, " points^7");
			else if(teamscores_label[ts_primary] == "fastest")
				str = strcat(str, " is beaten^7");
			else
				str = strcat(str, " ", teamscores_label[ts_primary]);
		}
		else
		{
			str = strcat(str, " until a lead of ^3", score_string(scores_flags[ps_primary], ll));
			if(scores_label[ps_primary] == "score")
				str = strcat(str, " points^7");
			else if(scores_label[ps_primary] == "fastest")
				str = strcat(str, " is beaten^7");
			else
				str = strcat(str, " ", scores_label[ps_primary]);
		}
	}
	if (str != "") {
		drawcolorcodedstring(pos + '0.5 0 0' * (sbwidth - sbar_fontsize_x * stringwidth(str, TRUE)), str, sbar_fontsize, 0.8, DRAWFLAG_NORMAL);
		pos_y += sbar_fontsize_y;
	}
	pos_y += sbar_fontsize_y;

	// Draw the scoreboard
	vector bg_size;
	bg_size = drawgetimagesize("gfx/hud/sb_scoreboard_bg");

	if(teamplay)
	{
		for(tm = teams.sort_next; tm; tm = tm.sort_next)
		{
			if(tm.team == COLOR_SPECTATOR)
				continue;

			rgb = GetTeamRGB(tm.team);

			Sbar_DrawXNum(pos - '6.5 0 0' * sbar_fontsize_y + '0 1 0' * sbar_fontsize_y, tm.(teamscores[ts_primary]), 4, 0, sbar_fontsize_y * 1.5, rgb, 0, 1, 1, DRAWFLAG_NORMAL);

			if(ts_primary != ts_secondary)
				Sbar_DrawXNum(pos - '4.5 0 0' * sbar_fontsize_y + '0 2.5 0' * sbar_fontsize_y, tm.(teamscores[ts_secondary]), 4, 0, sbar_fontsize_y * 1, rgb, 0, 1, 1, DRAWFLAG_NORMAL);

			pos = Sbar_Scoreboard_MakeTable(pos, tm, rgb, bg_size);
		}
	}
	else
	{
		rgb_x = CVAR(sbar_color_bg_r);
		rgb_y = CVAR(sbar_color_bg_g);
		rgb_z = CVAR(sbar_color_bg_b);

		for(tm = teams.sort_next; tm; tm = tm.sort_next)
		{
			if(tm.team == COLOR_SPECTATOR)
				continue;

			pos = Sbar_Scoreboard_MakeTable(pos, tm, rgb, bg_size);
		}
	}

	tmp = pos + '0 0.75 0' * sbar_fontsize_y;
	pos_y += 2 * sbar_fontsize_y;

	// List spectators
	float specs;
	specs = 0;
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		if(pl.team != COLOR_SPECTATOR)
			continue;
		Sbar_PrintScoreboardItem(pos, pl, (pl.sv_entnum == player_localentnum - 1), specs);
		pos_y += 1.25 * sbar_fontsize_y;
		++specs;
	}
	if(specs) {
		drawstring(tmp, "Spectators", sbar_fontsize, '1 1 1', 1, DRAWFLAG_NORMAL);
		pos_y += 2 * sbar_fontsize_y;
	}
	scoreboard_bottom = pos_y;
	if (centerprint_num < 1) {
		string tail = motd;
		float n;
		pos_y = max(CVAR(vid_conheight) * 0.5 + sbar_fontsize_y, pos_y);
		while (tail != "") {
			n = strstrofs(tail, "\n", 0);
			if (n < 0) {
				str = tail;
				tail = "";
			} else {
				str = substring(tail, 0, n);
				tail = substring(tail, n + 1, -1);
			}
			drawcolorcodedstring(pos + '0.5 0 0' * (sbwidth - sbar_fontsize_x * stringwidth(str, TRUE)), str, sbar_fontsize, 0.8, DRAWFLAG_NORMAL);
			pos_y += sbar_fontsize_y;
		}
	}
}

string MakeRaceString(float cp, float mytime, float histime, float lapdelta, string hisname)
{
	string col;
	string timestr;
	string cpname;
	string lapstr;
	lapstr = "";

	if(histime == 0) // goal hit
	{
		if(mytime > 0)
		{
			timestr = strcat("+", str_float_decimals(+mytime, TIME_DECIMALS));
			col = "^1";
		}
		else if(mytime == 0)
		{
			timestr = "+0.0";
			col = "^3";
		}
		else
		{
			timestr = strcat("-", str_float_decimals(-mytime, TIME_DECIMALS));
			col = "^2";
		}

		if(lapdelta > 0)
		{
			lapstr = strcat(" (-", ftos(lapdelta), "L)");
			col = "^2";
		}
		else if(lapdelta < 0)
		{
			lapstr = strcat(" (+", ftos(-lapdelta), "L)");
			col = "^1";
		}
	}
	else if(histime > 0) // anticipation
	{
		if(mytime >= histime)
			timestr = strcat("+", str_float_decimals(mytime - histime, TIME_DECIMALS));
		else
			timestr = TIME_ENCODED_TOSTRING(TIME_ENCODE(histime));
		col = "^3";
	}
	else
		col = "^7";

	if(cp == 254)
		cpname = "Start line";
	else if(cp == 255)
		cpname = "Finish line";
	else if(cp)
		cpname = strcat("Intermediate ", ftos(cp));
	else
		cpname = "Finish line";

	if(histime < 0)
		return strcat(col, cpname);
	else if(hisname == "")
		return strcat(col, cpname, " (", timestr, ")");
	else
		return strcat(col, cpname, " (", timestr, " ", strcat(hisname, col, lapstr), ")");
}

void()Sbar_Score_Disabled {};
var void()Sbar_Score = {};
void()Sbar_Score_Default {
	float score, distribution, leader;
	vector score_pos, secondary_score_pos, distribution_color;
	entity tm, pl, me;
	me = (spectatee_status > 0) ? playerslots[spectatee_status - 1] : playerslots[player_localentnum - 1];

	score_pos = bottomright - '196 42 0';
	secondary_score_pos = score_pos + '132 -6 0';

	if((scores_flags[ps_primary] & SFL_TIME) && !teamplay) { // race/cts record display on HUD
		pl = players.sort_next;
		if(pl == me)
			pl = pl.sort_next;
		if(scores_flags[ps_primary] & SFL_ZERO_IS_WORST)
			if(pl.scores[ps_primary] == 0)
				pl = world;

		score = me.(scores[ps_primary]);

		float racemin, racesec, racemsec;
		float distsec, distmsec, minusplus;

		racemin = floor(score/(60 * TIME_FACTOR));
		racesec = floor((score - racemin*(60 * TIME_FACTOR))/TIME_FACTOR);
		racemsec = score - racemin*60*TIME_FACTOR - racesec*TIME_FACTOR;

		if (pl && ((!(scores_flags[ps_primary] & SFL_ZERO_IS_WORST)) || score)) {
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
			}
			else {
				distribution_color = '1 0 0';
				minusplus = 2; // minusplus 1: always prefix with plus sign
			}
			Sbar_DrawXNum(bottomright - '0 48 0' - '16 0 0' * TIME_DECIMALS, distmsec, -TIME_DECIMALS, 0, 16, distribution_color, 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			Sbar_DrawXNum(bottomright - '68 48 0' - '16 0 0' * TIME_DECIMALS, distsec, 4, minusplus, 16, distribution_color, 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			drawpic(bottomright - '10 48 0' - '16 0 0' * TIME_DECIMALS, "gfx/hud/num_dot", '16 16 0', distribution_color, sbar_alpha_fg, DRAWFLAG_ADDITIVE);
		}
		// race record display
		if (distribution <= 0 || distribution == score) // draw the highlight background behind the timer if we have the lead
			drawpic(bottomright - '0 32 0' - '32 0 0' * (4 + TIME_DECIMALS), "gfx/hud/sb_highlight_4", '0 28 0' + '32 0 0' * (4 + TIME_DECIMALS), '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

		Sbar_DrawXNum(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0', racemsec, -TIME_DECIMALS, 0, 30, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		Sbar_DrawXNum(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0'  - '66 0 0', racesec, -2, 0, 30, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		drawpic(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0' - '18 0 0', "gfx/hud/num_dot", '30 30 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE);

		Sbar_DrawXNum(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0' - '132 0 0', racemin, -2, 0, 30, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		drawpic(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0' - '84 0 0', "gfx/hud/num_colon", '30 30 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE);

	} else if (!teamplay) { // non-teamgames, except race/cts
		// me vector := [team/connected frags id]
		pl = players.sort_next;
		if(pl == me)
			pl = pl.sort_next;

		if(pl)
			distribution = me.(scores[ps_primary]) - pl.(scores[ps_primary]);
		else
			distribution = 0;

		score = me.(scores[ps_primary]);

		if(distribution >= 5) {
			distribution_color = '0 1 0';
			leader = 1;
		} else if(distribution >= 0) {
			distribution_color = '1 1 1';
			leader = 1;
		} else if(distribution >= -5)
			distribution_color = '1 1 0';
		else
			distribution_color = '1 0 0';

		Sbar_DrawXNum(secondary_score_pos, distribution, 4, 3, 16, distribution_color, 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		Sbar_DrawXNum(score_pos, score, 4, 0, 34, distribution_color, leader, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
	} else { // teamgames
		float max_fragcount;
		max_fragcount = -999;

		for(tm = teams.sort_next; tm; tm = tm.sort_next) {
			if(tm.team == COLOR_SPECTATOR || !tm.team_size) // no players? don't display
				continue;
			score = tm.(teamscores[ts_primary]);
			leader = 0;

			if (score > max_fragcount)
				max_fragcount = score;

			if(tm.team == myteam) {
				if (max_fragcount == score)
					leader = 1;
				Sbar_DrawXNum(score_pos, score, 4, 0, 34, GetTeamRGB(tm.team) * 0.8, leader, 1, sbar_alpha_fg, DRAWFLAG_NORMAL);
			} else {
				if (max_fragcount == score)
					leader = 1;
				Sbar_DrawXNum(secondary_score_pos, score, 4, 0, 16, GetTeamRGB(tm.team) * 0.8, leader, 1, sbar_alpha_fg, DRAWFLAG_NORMAL);
				secondary_score_pos = secondary_score_pos + '0 16 0';
			}
		}
	}

	if(gametype == GAME_RACE || gametype == GAME_CTS)
	{
		drawfont = sbar_bigfont;
		float a, t;
		vector m;
		string s, forcetime;

		m = '0.5 0 0' * CVAR(vid_conwidth) + '0 0.25 0' * CVAR(vid_conheight);

		if(race_checkpointtime)
		{
			a = bound(0, 2 - (time - race_checkpointtime), 1);
			s = "";
			forcetime = "";
			if(a > 0) // just hit a checkpoint?
			{
				if(race_checkpoint != 254)
				{
					if(race_time && race_previousbesttime)
						s = MakeRaceString(race_checkpoint, TIME_DECODE(race_time) - TIME_DECODE(race_previousbesttime), 0, 0, race_previousbestname);
					else
						s = MakeRaceString(race_checkpoint, 0, -1, 0, race_previousbestname);
					if(race_time)
						forcetime = TIME_ENCODED_TOSTRING(race_time);
				}
			}
			else
			{
				if(race_laptime && race_nextbesttime && race_nextcheckpoint != 254)
				{
					a = bound(0, 2 - ((race_laptime + TIME_DECODE(race_nextbesttime)) - (time + TIME_DECODE(race_penaltyaccumulator))), 1);
					if(a > 0) // next one?
					{
						s = MakeRaceString(race_nextcheckpoint, (time + TIME_DECODE(race_penaltyaccumulator)) - race_laptime, TIME_DECODE(race_nextbesttime), 0, race_nextbestname);
					}
				}
			}

			if(s != "" && a > 0)
			{
				dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
				drawcolorcodedstring(m - '0 16 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
			}

			if(race_penaltytime)
			{
				a = bound(0, 2 - (time - race_penaltyeventtime), 1);
				if(a > 0)
				{
					s = strcat("^1PENALTY: ", str_float_decimals(race_penaltytime * 0.1, 1), " (", race_penaltyreason, ")");
					dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
					drawcolorcodedstring(m - '0 32 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
				}
			}

			if(forcetime != "")
			{
				a = bound(0, (time - race_checkpointtime) / 0.5, 1);
				drawstring_expanding(m - '16 0 0' * stringwidth(forcetime, FALSE), forcetime, '32 32 0', '1 1 1', sbar_alpha_fg, 0, a);
			}
			else
				a = 1;

			if(race_laptime && race_checkpoint != 255)
			{
				s = TIME_ENCODED_TOSTRING(TIME_ENCODE(time + TIME_DECODE(race_penaltyaccumulator) - race_laptime));
				drawstring(m - '16 0 0' * stringwidth(s, FALSE), s, '32 32 0', '1 1 1', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
			}
		}
		else
		{
			if(race_mycheckpointtime)
			{
				a = bound(0, 2 - (time - race_mycheckpointtime), 1);
				s = MakeRaceString(race_mycheckpoint, TIME_DECODE(race_mycheckpointdelta), -!race_mycheckpointenemy, race_mycheckpointlapsdelta, race_mycheckpointenemy);
				dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
				drawcolorcodedstring(m - '0 16 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
			}
			if(race_othercheckpointtime && race_othercheckpointenemy != "")
			{
				a = bound(0, 2 - (time - race_othercheckpointtime), 1);
				s = MakeRaceString(race_othercheckpoint, -TIME_DECODE(race_othercheckpointdelta), -!race_othercheckpointenemy, race_othercheckpointlapsdelta, race_othercheckpointenemy);
				dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
				drawcolorcodedstring(m - '0 0 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
			}

			if(race_penaltytime && !race_penaltyaccumulator)
			{
				t = race_penaltytime * 0.1 + race_penaltyeventtime;
				a = bound(0, (1 + t - time), 1);
				if(a > 0)
				{
					if(time < t)
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
}

void Sbar_Timer()
{
	float timelimit, elapsedTime, minutes, seconds, timeleft, starttime, hideminutes;
	hideminutes = FALSE;
	vector bgpos, timer_color;
	bgpos = '0 0 0';

	timelimit = getstatf(STAT_TIMELIMIT);
	starttime = getstatf(STAT_GAMESTARTTIME);

	timeleft = timelimit * 60 + starttime - time;
	if(timeleft >= 300 || warmup_stage || timelimit == 0) //don't use red or yellow in warmup or when there is no timelimit
		timer_color = '1 1 1'; //white
	else if(timeleft >= 60)
		timer_color = '1 1 0'; //yellow
	else
		timer_color = '1 0 0'; //red

	if (CVAR(sbar_increment_maptime) || timelimit == 0 || warmup_stage) {
		if (time < starttime) {
			//while restart is still active, show 00:00
			minutes = seconds = 0;
		} else {
			elapsedTime = floor(time - starttime);
			minutes = floor(elapsedTime / 60);
			seconds = elapsedTime - minutes*60;
		}
		if (minutes < 10)
			bgpos_x = topright_x - 54 - 17 - 12;
		else if (minutes < 100)	// nudge the timer background left if more digits are drawn
			bgpos_x = topright_x - 72 - 17 - 12;
		else
			bgpos_x = topright_x - 90 - 17 - 12;
		bgpos_y = 0;
		bgpos_z = 0;
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
		if (hideminutes)
			bgpos_x = topright_x - 36 - 7 - 12;
		else if (minutes < 10) // nudge the timer background left if more digits are drawn
			bgpos_x = topright_x - 54 - 17 - 12;
		else if (minutes < 100)
			bgpos_x = topright_x - 72 - 17 - 12;
		else
			bgpos_x = topright_x - 90 - 17 - 12;
		bgpos_y = 0;
		bgpos_z = 0;
	}

	if (CVAR(viewsize) <= 100) { // draw timer background when viewsize <= 100
		if (teamplay)
			drawpic(bgpos, "gfx/hud/sb_timerbg", '120 30 0', GetTeamRGB(myteam) * CVAR(sbar_color_bg_team), sbar_alpha_bg, DRAWFLAG_NORMAL); // timer bg color = myteam color
		else {
			_color_x = CVAR(sbar_color_bg_r);
			_color_y = CVAR(sbar_color_bg_g);
			_color_z = CVAR(sbar_color_bg_b);

			drawpic(bgpos, "gfx/hud/sb_timerbg", '120 30 0', _color, sbar_alpha_bg, DRAWFLAG_NORMAL);
		}
	}
	if not(hideminutes) {
		Sbar_DrawXNum(topright - '103 0 0' + '0 2 0', minutes, 3, 0, 18, timer_color, 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		drawpic(topright - '53 0 0' + '0 1 0', "gfx/hud/num_colon", '18 18 0', timer_color, sbar_alpha_fg, DRAWFLAG_NORMAL);
	}
	Sbar_DrawXNum(topright - '36 0 0' - '3 0 0' + '0 2 0', seconds, -2, 0, 18, timer_color, 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
}

vector powerup_pos;
void Sbar_DrawPowerupTimer(float dt, string image) {
	vector picsize;
	picsize = '22 22 0';
	float countdown_fontsize = 18;
	if(dt > 0)
	{
		if(dt < 5)
		{
			drawpic_expanding_two(powerup_pos, image, picsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE,
				bound(0, (ceil(dt) - dt) / 0.5, 1));
		}
		else
		{
			if (dt > 99)
				dt = 99;

			drawpic(powerup_pos, image, picsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE);
		}
		Sbar_DrawXNum(powerup_pos - '40 -2 0', ceil(dt), 2, 0, countdown_fontsize, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
	}
	else if(dt > -1)
	{
		drawpic_expanding(powerup_pos, image, picsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE,
			bound(0, -dt / 0.5, 1));
	}
	powerup_pos_y -= 40;
}

void CSQC_Strength_Timer() {
	if (getstati(STAT_HEALTH) <= 0)
		return;

	float strength_time, invincibility_time, speed_time, invisibility_time, jetpack_time;

	powerup_pos_x = CVAR(vid_conwidth) - 24;
	powerup_pos_y = CVAR(vid_conheight) - 360;

	//strength
	strength_time = getstatf(STAT_STRENGTH_FINISHED);
	invincibility_time = getstatf(STAT_INVINCIBLE_FINISHED);
	speed_time = getstatf(STAT_SPEED_FINISHED);
	invisibility_time = getstatf(STAT_INVISIBILITY_FINISHED);
	jetpack_time = getstati(STAT_FUEL);

	if (strength_time)
		Sbar_DrawPowerupTimer(strength_time - time, "gfx/hud/sb_str");

	if (invincibility_time)
		Sbar_DrawPowerupTimer(invincibility_time - time, "gfx/hud/sb_invinc");

	if (invisibility_time)
		Sbar_DrawPowerupTimer(invisibility_time - time, "gfx/hud/sb_str");

	if (speed_time)
		Sbar_DrawPowerupTimer(speed_time - time, "gfx/hud/sb_invinc");

	if (jetpack_time)
		Sbar_DrawPowerupTimer(jetpack_time, "gfx/hud/sb_fuel");
}

void Sbar_DrawPressedKeys(void)
{
	vector pos, bgsize;
	float pressedkeys;

	pos = stov(cvar_string("cl_showpressedkeys_position"));

	bgsize = '126 75 0';

	pos = '1 0 0' * (CVAR(vid_conwidth) - bgsize_x) * pos_x
	    + '0 1 0' * (CVAR(vid_conheight) - bgsize_y) * pos_y;
	pos -= '-15 -6 0'; // adjust to the origin of these numbers

	pressedkeys = getstatf(STAT_PRESSED_KEYS);
	drawpic(pos + '-15   -6   0', "gfx/hud/keys/key_bg.tga",           bgsize, '1 1 1', 0.1 * sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 83.5  9   0', ((pressedkeys & KEY_CROUCH) ? "gfx/hud/keys/key_crouch_inv.tga" : "gfx/hud/keys/key_crouch.tga"), ' 24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 32   -1.5 0', ((pressedkeys & KEY_FORWARD) ? "gfx/hud/keys/key_forward_inv.tga" : "gfx/hud/keys/key_forward.tga"),  ' 32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + '-11.5  9   0', ((pressedkeys & KEY_JUMP) ? "gfx/hud/keys/key_jump_inv.tga" : "gfx/hud/keys/key_jump.tga"),     ' 24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' -1   32   0', ((pressedkeys & KEY_LEFT) ? "gfx/hud/keys/key_left_inv.tga" : "gfx/hud/keys/key_left.tga"),     ' 32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 32   32   0', ((pressedkeys & KEY_BACKWARD) ? "gfx/hud/keys/key_backward_inv.tga" : "gfx/hud/keys/key_backward.tga"), ' 32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 65   32   0', ((pressedkeys & KEY_RIGHT) ? "gfx/hud/keys/key_right_inv.tga" : "gfx/hud/keys/key_right.tga"),    ' 32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
}

void Sbar_ShowSpeed(void)
{
	vector numsize;
	float pos, conversion_factor;
	string speed, unit;

	switch(CVAR(cl_showspeed_unit))
	{
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
		speed = strcat(ftos(floor( vlen(pmove_vel) * conversion_factor + 0.5 )), unit);
	else
		speed = strcat(ftos(floor( vlen(pmove_vel - pmove_vel_z * '0 0 1') * conversion_factor + 0.5 )), unit);

	numsize_x = numsize_y = CVAR(cl_showspeed_size);
	pos = (CVAR(vid_conheight) - numsize_y) * CVAR(cl_showspeed_position);

	drawfont = sbar_bigfont;
	drawstringcenter('1 0 0' + pos * '0 1 0', speed, numsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawfont = sbar_font;
}

vector acc_prevspeed;
float acc_prevtime;
float acc_avg;

void Sbar_ShowAcceleration(void)
{
	float acceleration, f;
	vector pos, top, rgb;
	top_x = CVAR(vid_conwidth)/2;
	top_y = 0;

	f = time - acc_prevtime;
	if(CVAR(cl_showacceleration_z))
		acceleration = (vlen(pmove_vel) - vlen(acc_prevspeed)) * (1 / f);
	else
		acceleration = (vlen(pmove_vel - '0 0 1' * pmove_vel_z) - vlen(acc_prevspeed - '0 0 1' * acc_prevspeed_z)) * (1 / f);
	acc_prevspeed = pmove_vel;
	acc_prevtime = time;

	f = bound(0, f * 10, 1);
	acc_avg = acc_avg * (1 - f) + acceleration * f;
	acceleration = acc_avg / getstatf(STAT_MOVEVARS_MAXSPEED);

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

void Sbar_DrawAccuracyStats_Description(vector position)
{
	drawstring(position + '0 3 0' * sbar_fontsize_y, "Shots fired:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawstring(position + '0 5 0' * sbar_fontsize_y, "Shots hit:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawstring(position + '0 7 0' * sbar_fontsize_y, "Accuracy:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawstring(position + '0 9 0' * sbar_fontsize_y, "Shots missed:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
}

void Sbar_DrawAccuracyStats()
{
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
	pos_y = SCOREBOARD_OFFSET;
	pos_z = 0;
	drawstringcenter(pos, "Weapon Accuracy", 2 * sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

	left_border = col_margin + 11 * sbar_fontsize_x;

	drawfont = sbar_font;

	if(warmup_stage)
	{
		pos_y += 40;
		if(math_mod(time, 1) >= 0.4)
			drawstringcenter(pos, "Stats are not tracked during warmup stage", sbar_fontsize, '1 1 0', sbar_alpha_fg, DRAWFLAG_NORMAL);

		return;
	}

	float top_border = SCOREBOARD_OFFSET + 55;  // position where the hitscan row starts: pixels down the screen
	Sbar_DrawAccuracyStats_Description('1 0 0' * col_margin + '0 1 0' * top_border);

	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
	{
		weapon_hit = weapon_hits[i];
		weapon_damage = weapon_fired[i];
		self = weapon_info(i);

		//if ((weapon_number != 42))  // print them all :)
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

			if ((left_border + count * (fill_size_x + col_margin) + fill_size_x) >= CVAR(vid_conwidth))
			{
				count = 0;
				++row;
				Sbar_DrawAccuracyStats_Description('1 0 0' * col_margin + '0 1 0' * (top_border + row * (fill_size_y + row_margin)));
			}

			pos_x = left_border + count * (fill_size_x + col_margin);
			pos_y = top_border + row * (fill_size_y + row_margin);

			// background
			drawpic(pos, "gfx/hud/sb_accuracy", fill_size , fill_colour, sbar_alpha_bg, DRAWFLAG_NORMAL);
			drawborderlines(sbar_border_thickness, pos, fill_size, '0 0 0', sbar_alpha_bg, DRAWFLAG_NORMAL);

			// the weapon
			drawpic(pos, strcat("gfx/hud/inv_weapon", ftos(i-1)), '1 0.5 0' * fill_size_x , '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

			// the amount of shots fired or max damage
			drawstringright(pos + '4.5 0 0' * sbar_fontsize_x + '0 3 0' * sbar_fontsize_y, ftos(weapon_damage), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

			// the amount of hits or actual damage
			drawstringright(pos + '4.5 0 0' * sbar_fontsize_x + '0 5 0' * sbar_fontsize_y, ftos(weapon_hit), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

			// the accuracy
			drawstringright(pos + '4.5 0 0' * sbar_fontsize_x + '0 7 0' * sbar_fontsize_y, strcat(ftos(weapon_stats),"%"), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

			// the amount of shots missed or damage wasted
			drawstringright(pos + '4.5 0 0' * sbar_fontsize_x + '0 9 0' * sbar_fontsize_y, ftos(max(0, weapon_damage - weapon_hit)), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

			++count;
		}
	}
}

void drawstringright(vector position, string text, vector scale, vector rgb, float alpha, float flag)
{
	position_x -= 2 / 3 * strlen(text) * scale_x;
	drawstring(position, text, scale, rgb, alpha, flag);
}

void drawstringcenter(vector position, string text, vector scale, vector rgb, float alpha, float flag)
{
	position_x = 0.5 * (CVAR(vid_conwidth) - 0.6025 * strlen(text) * scale_x);
	drawstring(position, text, scale, rgb, alpha, flag);
}

void drawcolorcodedstringcenter(vector position, string text, vector scale, float alpha, float flag)
{
	position_x = 0.5 * (CVAR(vid_conwidth) - stringwidth(text, TRUE) * scale_x);
	drawcolorcodedstring(position, text, scale, alpha, flag);
}

void Sbar_Reset (void)
{
	// reset gametype specific icons
	if(gametype == GAME_KEYHUNT || gametype == GAME_KEYHUNT_CA || gametype == GAME_KEYHUNT_FT)
		CSQC_kh_hudreset();
	else if(gametype == GAME_CTF || gametype == GAME_CATF || gametype == GAME_CTFT)
		CSQC_ctf_hudreset();
}

void DrawProgressFragmented(vector cpos, vector l_size, float progress, float alpha, vector l_color, float fragments) {
    vector pos;
    pos_x = cpos_x - l_size_x / 2;
    pos_y = cpos_y - l_size_y / 2;

    vector fill = l_size;
    fill_x *= progress;

    drawfill(pos, fill, l_color, alpha * 0.7, DRAWFLAG_NORMAL);

    if(fragments < 2) {
        drawborderlines(1, pos, l_size, l_color, alpha, DRAWFLAG_NORMAL);
    } else {
        vector fragsize;
		fragsize_x = l_size_x / fragments;
		fragsize_y = l_size_y;
		fragsize_z = 0;

		float frag;
        for(frag = 0; frag < fragments; ++frag) {
            drawborderlines(1, pos + fragsize_x * frag * '1 0', fragsize, l_color, alpha, DRAWFLAG_NORMAL);
        }
    }
}

void DrawProgress(vector cpos, vector l_size, float progress, float alpha, vector l_color) {
    DrawProgressFragmented(cpos, l_size, progress, alpha, l_color, 1);
}

float Sbar_GetNadgetRegen(float stat_type, float stat_regen, float stat_maxregen) {
	return getstatf(stat_regen) / getstatf(stat_maxregen);
}

float hg_visual, hg_alpha;

var void() Sbar_GameType_hud;
void Sbar_GameType_Init() {
	if(gametype == GAME_KEYHUNT || gametype == GAME_KEYHUNT_CA || gametype == GAME_KEYHUNT_FT)
		Sbar_GameType_hud = CSQC_kh_hud;
	else if(gametype == GAME_CTF || gametype == GAME_CATF || gametype == GAME_CTFT)
		Sbar_GameType_hud = CSQC_ctf_hud;
	else if(gametype == GAME_NEXBALL)
		Sbar_GameType_hud = CSQC_nb_hud;
	else if(gametype == GAME_SINGLE || gametype == GAME_COOP) {
		Sbar_GameType_hud = CSQC_single_hud;
		Sbar_Score = Sbar_Score_Disabled;
	} else {
		Sbar_GameType_hud = SUB_Null;
		Sbar_Score = Sbar_Score_Default;
	}
}

void Sbar_DrawAmmo(vector pos, float a, float active, string image) {
	float alpha;
	if (active) {
		alpha = 1;
		drawpic(pos + '0 1.5 0', "gfx/hud/sb_ammobg", '80 22 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	} else
		alpha = 0.7;

	drawpic(pos + '56 3 0', image, '18 18 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	if (a < 10)
		_color = '1 0 0';
	else
		_color = '1 1 1';

	Sbar_DrawXNum(pos + '6 4.5 0', a, 3, 0, 16, _color, 0, 0, sbar_alpha_fg * alpha, DRAWFLAG_NORMAL);
}

void Sbar_Draw (void)
{
	topright_x = CVAR(vid_conwidth);
	topright_y = 0;
	topright_z = 0;

	bottom_x = CVAR(vid_conwidth)/2;
	bottom_y = CVAR(vid_conheight);
	bottom_z = 0;

	bottomright_x = CVAR(vid_conwidth);
	bottomright_y = CVAR(vid_conheight);
	bottomright_z = 0;

	bottomleft_x = 0;
	bottomleft_y = CVAR(vid_conheight);
	bottomleft_z = 0;

	sbar_alpha_bg = CVAR(sbar_alpha_bg) * (1 - CVAR(_menu_alpha));
	sbar_border_thickness = bound(0, CVAR(sbar_border_thickness), 5);

	float i;
	float weapon_stats;
	float x;
	float stat_weapons;

	weapon_stats = getstati(STAT_DAMAGE_HITS);
 	weapon_number = weapon_stats & 63;
 	weapon_hits[weapon_number] = rint(weapon_stats / 64);

 	weapon_stats = getstati(STAT_DAMAGE_FIRED);
 	weapon_number = weapon_stats & 63;
 	weapon_fired[weapon_number] = rint(weapon_stats / 64);

	string s;
	vector pos;
	pos = '0 0 0';

	sbar_fontsize = Sbar_GetFontsize(CVAR(sbar_fontsize));
	sbar_fontsize_spec = Sbar_GetFontsize(CVAR(sbar_fontsize_spec));

	if(player_deadflag == DEAD_FREEZE)
		drawfill('0 0 0', bottomright, '1 1 1', 0.4, DRAWFLAG_ADDITIVE);

	float _health = getstati(STAT_HEALTH);
	if (mv_active) // map voting screen
	{
		if(sb_showscores) {
			Sbar_DrawScoreboard();
			Sbar_Score();
			Sbar_Timer();
		}
		else if(sb_showaccuracy) {
			Sbar_DrawAccuracyStats();
			Sbar_Score();
			Sbar_Timer();
		}
  		else
			Sbar_FinaleOverlay();

		Sbar_Reset();
	}
	else if (_health <= 0 || observer_status)
	{
  		if(sb_showaccuracy)
  			Sbar_DrawAccuracyStats();
		else if (!sb_hidescores) {
			if (sb_showscores || (_health <= 0 && !sb_hidescores && CVAR(cl_deathscoreboard)))
				Sbar_DrawScoreboard();
		}
		Sbar_Score();
		Sbar_Timer();
		Sbar_Reset();
  	}
	else
	{
		if (sb_showscores)
			Sbar_DrawScoreboard();
		else if(sb_showaccuracy)
			Sbar_DrawAccuracyStats();

		float armor;
		armor = getstati(STAT_ARMOR);
		stat_items = getstati(STAT_ITEMS);
		stat_weapons = getstati(STAT_WEAPONS);

		vector bg_size; // hud background size
		bg_size = '1600 58 0';

		if (CVAR(viewsize) <= 100 && CVAR(vid_conwidth) <= 1600) {
			if (teamplay)
				drawpic(bottom - '800 58 0', "gfx/hud/sbar", bg_size, GetTeamRGB(myteam) * CVAR(sbar_color_bg_team), sbar_alpha_bg, DRAWFLAG_NORMAL); // hud color = myteam color
			else {
				// allow for custom HUD colors in non-teamgames
				_color_x = CVAR(sbar_color_bg_r);
				_color_y = CVAR(sbar_color_bg_g);
				_color_z = CVAR(sbar_color_bg_b);

				drawpic(bottom - '800 58 0', "gfx/hud/sbar", bg_size, _color, sbar_alpha_bg, DRAWFLAG_NORMAL);
			}
		}

		vector health_pos, armor_pos;

		if (CVAR(sbar_hudselector) == 0) { // old style layout with armor left of health
			armor_pos = bottom - '96 28 0';
			health_pos = bottom - '-14 28 0';
		}
		else {
			health_pos = bottom - '96 28 0';
			armor_pos = bottom - '-14 28 0';
		}

		// armor
		x = armor;
		if (x > 0)
		{
			if (x > 45) {
				drawpic(armor_pos + '78 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
				Sbar_DrawXNum_Colored(armor_pos, x, 24, sbar_alpha_fg);
			}
			else {
				drawpic(armor_pos + '78 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', (x+10)/55 * sbar_alpha_fg, DRAWFLAG_NORMAL);
				Sbar_DrawXNum_Colored(armor_pos, x, 24, (x+10)/55 * sbar_alpha_fg);
			}
		}

		// health
		x = _health;
		drawpic(health_pos + '78 -4.5 0', "gfx/hud/sb_health", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
		Sbar_DrawXNum_Colored(health_pos, x, 24, sbar_alpha_fg);

		// weapon icons
		x = 1.0;
		float fade = bound(0, CVAR(sbar_weapons_fadetime) - (time - weapontime) *  CVAR(sbar_weapons_fadespeed), 1);
		if (fade) {
			Sbar_DrawWeapon_Clear();
			for(i = 1; i <= 24; ++i)
			{
				if(weaponimpulse[i-1] >= 0)
				if(stat_weapons & x)
				{
					Sbar_DrawWeapon(i-1, fade, (i == activeweapon), i);
				}
				x *= 2;
			}
		}

		// ammo
		float a; // i will be the ammo type (already declared), a will contain how much ammo there is of type i
		float clip = getstati(STAT_BULLETS_LOADED);
		if (clip) {
			if (clip < 0) clip = 0;
			string ai;
			float at;
			if (stat_items & IT_SHELLS) { at = STAT_SHELLS; ai = "gfx/hud/sb_shells"; }
			else if (stat_items & IT_NAILS) { at = STAT_NAILS; ai = "gfx/hud/sb_bullets"; }
			else if (stat_items & IT_ROCKETS) { at = STAT_ROCKETS; ai = "gfx/hud/sb_rocket"; }
			else if (stat_items & IT_CELLS) { at = STAT_CELLS; ai = "gfx/hud/sb_cells"; }
			else at = 0;
			if (at) {
				a = getstati(at);

				if (CVAR(vid_conwidth) >= 800) {
					pos_x = 230;
					pos_y = 40;
				} else {
					pos_x = 206;
					pos_y = 33;
				}
				pos = bottom - pos;
				drawpic(pos + '76 3 0', ai, '24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
				if (stat_items & IT_UNLIMITED_WEAPON_AMMO) {
					Sbar_DrawXNum(pos + '5 5 0', clip, 3, 0, 24, '1 1 0.5', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				} else {
					if(a < 10)
						Sbar_DrawXNum(pos + '25 -2 0', a, 3, 0, 16, '0.7 0 0', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					else
						Sbar_DrawXNum(pos + '25 -2 0', a, 3, 0, 16, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);

					Sbar_DrawXNum(pos + '25 18 0', clip, 3, 0, 16, '1 1 0.5', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				}
			}
		} else if not(stat_items & IT_UNLIMITED_WEAPON_AMMO) {
			if(CVAR(sbar_showcurrentammo) || CVAR(vid_conwidth) < 800) { // force showing current ammo only with conwidths < 800
				string ai;
				float at;
				if (stat_items & IT_SHELLS) { at = STAT_SHELLS; ai = "gfx/hud/sb_shells"; }
				else if (stat_items & IT_NAILS) { at = STAT_NAILS; ai = "gfx/hud/sb_bullets"; }
				else if (stat_items & IT_ROCKETS) { at = STAT_ROCKETS; ai = "gfx/hud/sb_rocket"; }
				else if (stat_items & IT_CELLS) { at = STAT_CELLS; ai = "gfx/hud/sb_cells"; }
				else at = 0;
				if (at) {
					a = getstati(at);

					if (CVAR(vid_conwidth) >= 800) {
						pos_x = 230;
						pos_y = 40;
					} else {
						pos_x = 206;
						pos_y = 33;
					}
					pos = bottom - pos;
					if(CVAR(vid_conwidth) >= 800)
						drawpic(pos + '0 1.5 0', "gfx/hud/sb_ammobg", '107 29 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
					drawpic(pos + '76 3 0', ai, '24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
					if(a < 10)
						Sbar_DrawXNum(pos + '5 5 0', a, 3, 0, 24, '0.7 0 0', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					else
						Sbar_DrawXNum(pos + '5 5 0', a, 3, 0, 24, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				}
			} else {
				a = getstati(STAT_SHELLS);
				if (a > 0) {
					pos_x = 286; pos_y = 48;
					Sbar_DrawAmmo(bottom - pos, a, stat_items & IT_SHELLS, "gfx/hud/sb_shells");
				}
				a = getstati(STAT_NAILS);
				if (a > 0) {
					pos_x = 286; pos_y = 26;
					Sbar_DrawAmmo(bottom - pos, a, stat_items & IT_NAILS, "gfx/hud/sb_bullets");
				}
				a = getstati(STAT_ROCKETS);
				if (a > 0) {
					pos_x = 200; pos_y = 48;
					Sbar_DrawAmmo(bottom - pos, a, stat_items & IT_ROCKETS, "gfx/hud/sb_rocket");
				}
				a = getstati(STAT_CELLS);
				if (a > 0) {
					pos_x = 200; pos_y = 26;
					Sbar_DrawAmmo(bottom - pos, a, stat_items & IT_CELLS, "gfx/hud/sb_cells");
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
            hgcd = getstatf(STAT_HGREFIRE) - servertime;
			// handgrenade force meter
			float hgstat = getstatf(STAT_HGFORCE);
			if (hgstat) {
				float hgls = getstatf(STAT_HGLAUNCH);
				if(hgstat) {
					hg_alpha = approach(hg_alpha, 1, 5 * drawframetime);
				} else {
					hg_alpha = approach(hg_alpha, 0, 5 * drawframetime);
				}
				hg_visual = approach(hg_visual, hgstat, drawframetime * hgls);
				hgstat = hg_visual;
				if(hg_alpha)
				{
					vector hgpos;
					hgpos_x = CVAR(vid_conwidth) / 2;
					hgpos_y = CVAR(vid_conheight) - CVAR(vid_conheight) / 4;
					DrawProgress(hgpos, '120 5 0', hgstat, 0.7 * hg_alpha, '1 0 0' + '0 1 0' * (1 - hgstat));
				}
			} else {
				hg_alpha = 0;
				hg_visual = 0;
			}

#if 0
            if(hgcd > 0) {
                if(hgcd > hg_maxcd) hg_maxcd = hgcd;
            } else hg_maxcd = 0;
#endif

            if(hgtype2) {
                hgcd2 = getstatf(STAT_HGREFIRE2) - servertime;

#if 0
                if(hgcd2 > 0) {
                    if(hgcd2 > hg_maxcd2) hg_maxcd2 = hgcd2;
                } else hg_maxcd2 = 0;
#endif
            }

            if(getstati(STAT_HGSHIELDSTORE)) {
                DrawProgressFragmented('0.5 0 0' * CVAR(vid_conwidth) + hgapos - sbar_fontsize_y * '0 2.5 0', '25 0 0' * sbar_fontsize_x + '0 7 0',
                             getstati(STAT_HGSHIELDSTORE) / getstati(STAT_HGSHIELDSTOREMAX), 0.7, '1 0.3 0',
                             getstati(STAT_HGSHIELDSTOREMAX) / getstati(STAT_HGSHIELDDAMAGEPERSHOT));
            }

            if(getstati(STAT_STEALTH)) {
                drawcolorcodedstringcenter(hgapos - sbar_fontsize_y * ('0 2 0'/* + '0 1 0' * !!adept */), strcat(
                                            "^3Shoot or press ^1", strtoupper(getcommandkey("drop weapon", "dropweapon")),
                                            " ^3to ", /* if(adept) "suspend" else */ "cancel", " stealth (^1", ftos(getstati(STAT_STEALTH)), " ^3seconds remaining)"),
                                            sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
#if 0
                if(adept) drawcolorcodedstringcenter(hgapos - sbar_fontsize_y * '0 2 0', strcat(
                                            "^3Press ^1", strtoupper(getcommandkey("drop flag", "+use")),
                                            " ^3to cancel stealth completely"),
                                            sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
#endif
            } else if(getstati(STAT_STEALTH_SAVED)) {
                drawcolorcodedstringcenter(hgapos - sbar_fontsize_y * '0 2 0', strcat(
                                            "^3Press ^1", strtoupper(getcommandkey("drop weapon", "dropweapon")),
                                            " ^3to re-enter stealth (^1", ftos(getstati(STAT_STEALTH_SAVED)), " ^3seconds remaining)"),
                                            sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
            } else if(getstatf(STAT_HGSHIELD)) {
                string smsg;
                if(getstati(STAT_HGSHIELDSTORE) > 0) {
                    smsg = strcat("^3Press ^1", strtoupper(getcommandkey("drop weapon", "dropweapon")),
                                  " ^3to discharge your ", nadget_TypeToExpandedName(hgtype),
                                  " for ^1", ftos(getstati(STAT_HGSHIELDSTORE)), " ^3damage");
                } else {
                    smsg = strcat("^3Press ^1", strtoupper(getcommandkey("drop weapon", "dropweapon")),
                                  " ^3to cancel your ", ((getstati(STAT_HGSHIELDSTORE) < 0) ? "discharge" : nadget_TypeToExpandedName(hgtype)));
                }
                drawcolorcodedstringcenter(hgapos - sbar_fontsize_y * '0 2 0', smsg, sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
            } else if(hgdetons) {
                drawcolorcodedstringcenter(hgapos - sbar_fontsize_y * '0 2 0', strcat(
                                            "^3Press ^1", strtoupper(getcommandkey("drop weapon", "dropweapon")),
                                            " ^3to trigger your nadget",
                                            ((hgdetons > 1) ? strcat("s (^2", ftos(hgdetons), "^3)") : "")),
                                            sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
            } else if(hgtype == NADGET_GG && hgammo) {
                drawcolorcodedstringcenter(hgapos - sbar_fontsize_y * '0 2 0', strcat("^3Press ^1", strtoupper(getcommandkey("hook / nadget key", "+hook")), " ^3to win!"), sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
            }

			string hgicon = nadget_TypeToIcon(hgtype, TRUE, 0);
			hgapos_x = CVAR(vid_conwidth / 2) + 154;
			hgapos_y = CVAR(vid_conheight) - 44;
			float hgregen = Sbar_GetNadgetRegen(STAT_HGTYPE, STAT_HGREGEN, STAT_HGREGENMAX) - hgregen;
			vector hgrsize;
			if(hgregen && hgregen != 1) {
				hgrsize = '64 16 0';
				hgrsize_x *= hgregen;
				drawfill(hgapos, hgrsize, '1 1 1' - '0 0.5 0.5' * getstati(STAT_HGREGENPAUSED), 0.5 * sbar_alpha_fg, DRAWFLAG_NORMAL);
			}
			hgapos -= '4 4';
			Sbar_DrawXNum(hgapos, hgammo, 2, 0, 24, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			hgapos_x += 48;
			drawpic(hgapos, hgicon, '22 22', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

			if(hgtype2) {
				hgicon = nadget_TypeToIcon(hgtype2, TRUE, 0);
				hgapos_y += 26;
				hgapos_x -= 44;
				float hgregen2 = Sbar_GetNadgetRegen(STAT_HGTYPE2, STAT_HGREGEN2, STAT_HGREGENMAX2) - hgregen2;
				if(hgregen2 && hgregen2 != 1) {
					hgrsize = '64 16 0';
					hgrsize_x *= hgregen2;
					drawfill(hgapos, hgrsize, '1 1 1' - '0 0.5 0.5' * getstati(STAT_HGREGENPAUSED2), 0.5 * sbar_alpha_fg, DRAWFLAG_NORMAL);
				}
				hgapos -= '4 4';
				hgammo = getstati(STAT_HGAMMO2);
				Sbar_DrawXNum(hgapos, hgammo, 2, 0, 24, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				hgapos_x += 48;
				drawpic(hgapos, hgicon, '22 22', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
			}
		}

		// draw scores and timer
		Sbar_Score();
		Sbar_Timer();

		// draw strength/invincibility icon and timer
		CSQC_Strength_Timer();

		a = getstati(STAT_RUNES);
		if (a) {
			pos_x = CVAR(vid_conwidth) / 2;
			pos_y = CVAR(vid_conheight) - 50 - sbar_fontsize_y;
			s = "";
			for (i = RUNE_FIRST; i <= RUNE_LAST; i *= 2) {
				if (i & a)
					s = strcat(s, " ", rune_name(i));
			}
			drawcolorcodedstringcenter(pos, s, sbar_fontsize, 0.4, DRAWFLAG_NORMAL);
		}

		// draw gametype specific icons
		Sbar_GameType_hud();
	}
	return;
}

void CSQC_single_hud(void)
{
	if (stat_items & IT_KEY1)
		drawpic (bottomleft - '-30 44 0', "gfx/hud/sb_kh_blue", '20 40', '1.125 1.125 0.75', sbar_alpha_fg, DRAWFLAG_NORMAL);

	if (stat_items & IT_KEY2)
		drawpic (bottomleft - '-58 44 0', "gfx/hud/sb_kh_yellow", '20 40', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

	if (stat_items & IT_KEY3)
		drawpic (bottomleft - '-86 44 0', "gfx/hud/sb_kh_red", '20 40', '2 0.5 0.5', sbar_alpha_fg, DRAWFLAG_NORMAL);
}

// CTF HUD
float redflag_prevframe, blueflag_prevframe; // status during previous frame
float redflag_prevstatus, blueflag_prevstatus; // last remembered status
float redflag_statuschange_time, blueflag_statuschange_time; // time when the status changed

void CSQC_ctf_hudreset(void)
{
	redflag_prevstatus = blueflag_prevstatus = redflag_prevframe = blueflag_prevframe = redflag_statuschange_time = blueflag_statuschange_time = 0;
}

void CSQC_ctf_hud(void)
{
	vector redflag_pos, blueflag_pos, sz;
	float f; // every function should have that

	float redflag, blueflag; // current status
	float redflag_statuschange_elapsedtime, blueflag_statuschange_elapsedtime; // time since the status changed

	redflag = (stat_items/IT_RED_FLAG_TAKEN) & 3;
	blueflag = (stat_items/IT_BLUE_FLAG_TAKEN) & 3;

	// when status CHANGES, set old status into prevstatus and current status into status
	if (redflag != redflag_prevframe)
	{
		redflag_statuschange_time = time;
		redflag_prevstatus = redflag_prevframe;
		redflag_prevframe = redflag;
	}

	if (blueflag != blueflag_prevframe)
	{
		blueflag_statuschange_time = time;
		blueflag_prevstatus = blueflag_prevframe;
		blueflag_prevframe = blueflag;
	}

	redflag_statuschange_elapsedtime = time - redflag_statuschange_time;
	blueflag_statuschange_elapsedtime = time - blueflag_statuschange_time;

	float BLINK_FACTOR = 0.15;
	float BLINK_BASE = 0.85;
	// note:
	//   RMS = sqrt(BLINK_BASE^2 + 0.5 * BLINK_FACTOR^2)
	// thus
	//   BLINK_BASE = sqrt(RMS^2 - 0.5 * BLINK_FACTOR^2)
	// ensure RMS == 1
	float BLINK_FREQ = 5; // circle frequency, = 2*pi*frequency in hertz

	string red_icon, red_icon_prevstatus;
	float red_alpha, red_alpha_prevstatus;
	red_alpha = red_alpha_prevstatus = 1;
	switch(redflag) {
		case 1: red_icon = "gfx/hud/sb_flag_red_taken"; break;
		case 2: red_icon = "gfx/hud/sb_flag_red_lost"; break;
		case 3: red_icon = "gfx/hud/sb_flag_red_carrying"; red_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM2))
				red_icon = "gfx/hud/sb_flag_red_shielded";
			else
				red_icon = string_null;
			break;
	}
	switch(redflag_prevstatus) {
		case 1: red_icon_prevstatus = "gfx/hud/sb_flag_red_taken"; break;
		case 2: red_icon_prevstatus = "gfx/hud/sb_flag_red_lost"; break;
		case 3: red_icon_prevstatus = "gfx/hud/sb_flag_red_carrying"; red_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if(redflag == 3)
				red_icon_prevstatus = "gfx/hud/sb_flag_red_carrying"; // make it more visible
			else if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM2))
				red_icon_prevstatus = "gfx/hud/sb_flag_red_shielded";
			else
				red_icon_prevstatus = string_null;
			break;
	}

	string blue_icon, blue_icon_prevstatus;
	float blue_alpha, blue_alpha_prevstatus;
	blue_alpha = blue_alpha_prevstatus = 1;
	switch(blueflag) {
		case 1: blue_icon = "gfx/hud/sb_flag_blue_taken"; break;
		case 2: blue_icon = "gfx/hud/sb_flag_blue_lost"; break;
		case 3: blue_icon = "gfx/hud/sb_flag_blue_carrying"; blue_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM1))
				blue_icon = "gfx/hud/sb_flag_blue_shielded";
			else
				blue_icon = string_null;
			break;
	}
	switch(blueflag_prevstatus) {
		case 1: blue_icon_prevstatus = "gfx/hud/sb_flag_blue_taken"; break;
		case 2: blue_icon_prevstatus = "gfx/hud/sb_flag_blue_lost"; break;
		case 3: blue_icon_prevstatus = "gfx/hud/sb_flag_blue_carrying"; blue_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if(blueflag == 3)
				blue_icon_prevstatus = "gfx/hud/sb_flag_blue_carrying"; // make it more visible
			else if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM1))
				blue_icon_prevstatus = "gfx/hud/sb_flag_blue_shielded";
			else
				blue_icon_prevstatus = string_null;
			break;
	}

	if (myteam == COLOR_TEAM1) { // always draw own flag on left
		redflag_pos = bottomleft - '-4 50 0';
		blueflag_pos = bottomleft - '-62 50 0';
	} else {
		blueflag_pos = bottomleft - '-4 50 0';
		redflag_pos = bottomleft - '-62 50 0';
	}

	sz = '52 52 0';

	f = bound(0, redflag_statuschange_elapsedtime*2, 1);
	if(red_icon_prevstatus && f < 1)
		drawpic_expanding(redflag_pos, red_icon_prevstatus, sz, '1 1 1', sbar_alpha_fg * red_alpha_prevstatus, DRAWFLAG_NORMAL, f);
	if(red_icon)
		drawpic(redflag_pos, red_icon, sz, '1 1 1', sbar_alpha_fg * red_alpha * f, DRAWFLAG_NORMAL);

	f = bound(0, blueflag_statuschange_elapsedtime*2, 1);
	if(blue_icon_prevstatus && f < 1)
		drawpic_expanding(blueflag_pos, blue_icon_prevstatus, sz, '1 1 1', sbar_alpha_fg * blue_alpha_prevstatus, DRAWFLAG_NORMAL, f);
	if(blue_icon)
		drawpic(blueflag_pos, blue_icon, sz, '1 1 1', sbar_alpha_fg * blue_alpha * f, DRAWFLAG_NORMAL);
}

// Keyhunt HUD
float kh_runheretime;

void CSQC_kh_hudreset(void)
{
	kh_runheretime = 0;
}

void CSQC_kh_hud(void)
{
	float kh_keys;
	float keyteam;
	float a, aa;
	vector p, pa, kh_size, kh_asize;

	p_x = 6;
	p_y = CVAR(vid_conheight) - 34 - 3;
	p_z = 0;

	kh_keys = getstati(STAT_KH_KEYS);

	kh_size = '19 34 0';
	kh_asize = '19 10 0';
	pa = p + '0 -10 0';

	float i, key;

	float keycount;
	keycount = 0;
	for(i = 0; i < 4; ++i)
	{
		key = floor(kh_keys / pow(32, i)) & 31;
		keyteam = key - 1;
		if(keyteam == 30 && keycount <= 4)
			keycount += 4;
		if(keyteam == myteam || keyteam == -1 || keyteam == 30)
			keycount += 1;
	}
	// this yields 8 exactly if "RUN HERE" shows

	if(keycount == 8)
	{
		if(!kh_runheretime)
			kh_runheretime = time;
		pa_y -= fabs(sin((time - kh_runheretime) * 3.5)) * 6; // make the arrows jump in case of RUN HERE
	}
	else
		kh_runheretime = 0;

	for(i = 0; i < 4; ++i)
	{
		key = floor(kh_keys / pow(32, i)) & 31;
		keyteam = key - 1;
		switch(keyteam)
		{
			case 30: // my key
				keyteam = myteam;
				a = 1;
				aa = 1;
				break;
			case -1: // no key
				a = 0;
				aa = 0;
				break;
			default: // owned or dropped
				a = 0.2;
				aa = 0.5;
				break;
		}
		if(a > 0)
		{
			switch(keyteam)
			{
				case COLOR_TEAM1:
					drawpic (pa, "gfx/hud/sb_kh_redarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM2:
					drawpic (pa, "gfx/hud/sb_kh_bluearrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM3:
					drawpic (pa, "gfx/hud/sb_kh_yellowarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM4:
					drawpic (pa, "gfx/hud/sb_kh_pinkarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				default:
					break;
			}
			switch(i) // YAY! switch(i) inside a for loop for i. DailyWTF, here we come!
			{
				case 0:
					drawpic (p, "gfx/hud/sb_kh_red", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 1:
					drawpic (p, "gfx/hud/sb_kh_blue", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 2:
					drawpic (p, "gfx/hud/sb_kh_yellow", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 3:
					drawpic (p, "gfx/hud/sb_kh_pink", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
			}
		}
		p_x += 24;
		pa_x += 24;
	}
}

//Nexball HUD
#define NBPB_SIZE '96 38 0'
#define NBPB_BT 2                   //thickness
#define NBPB_BRGB '1 1 1'
#define NBPB_BALPH 1                //alpha
#define NBPB_BFLAG DRAWFLAG_NORMAL
#define NBPB_IALPH 0.4
#define NBPB_IFLAG DRAWFLAG_NORMAL
#define NBPB_IRGB '0.7 0.1 0'

void CSQC_nb_hud(void)
{
	float nb_pb;
	vector pos;

	nb_pb = getstatf(STAT_NB_METERSTART);

	pos_x = 4;
	pos_y = CVAR(vid_conheight) - 42;
	pos_z = 0;

	//Manage the progress bar if any
	if (nb_pb > 0)
	{
		vector s;
		if (nb_pb > 1)
			nb_pb = 2 - nb_pb;

		s = NBPB_SIZE;
		//Draw the filling
		drawfill(pos, nb_pb * s_x * '1 0 0' + s_y * '0 1 0', NBPB_IRGB, NBPB_IALPH, NBPB_IFLAG);

		//Draw the box
		s = NBPB_SIZE;
		drawline(NBPB_BT, pos    , pos + '1 0 0' * s_x, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
		drawline(NBPB_BT, pos    , pos + '0 1 0' * s_y, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
		drawline(NBPB_BT, pos + s, pos + '1 0 0' * s_x, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
		drawline(NBPB_BT, pos + s, pos + '0 1 0' * s_y, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
	}

	pos_x += 12; //horizontal margin to the picture
	pos_y += 2; //vertical margin to the picture

	if (stat_items & IT_KEY1)
		drawpic(pos, "gfx/hud/sb_nexball_carrying", '80 34 0', '1 1 1', 1, DRAWFLAG_NORMAL);
}
