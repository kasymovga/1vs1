string rm_game_type_vote_map;
string rm_game_type_vote_map_pic;
float rm_game_type_vote_map_pic_ready;
float rm_game_type_vote_types[10];
float rm_game_type_vote_votes[10];
float rm_game_type_vote_hoveralpha[10];
float rm_game_type_vote_starttime;
float rm_game_type_vote_timeout;
float rm_game_type_vote_available;
float rm_game_type_vote_longest;
float rm_game_type_vote_selection;
float rm_game_type_vote_own;
float rm_game_type_vote_max;

void(void) rm_game_type_vote_picture_read {
	string s = net_read_picture();
	if not(file_exists_image(rm_game_type_vote_map_pic)) {
		str_unzone_ifneeded(rm_game_type_vote_map_pic);
		rm_game_type_vote_map_pic = str_zone_ifneeded(s);
		rm_game_type_vote_map_pic_ready = TRUE;
	}
}

string(float id) rm_game_type_vote_description {
	float t = rm_game_type_vote_types[id] & 63;
	switch (t) {
	case GAME_TYPE_CTF:
	case GAME_TYPE_CTFT:
	case GAME_TYPE_CATF:
		return "Each team has a flag located in its base.\nYou must steal the enemy flag and bring it to yours to score.";
	case GAME_TYPE_KEYHUNT:
	case GAME_TYPE_KEYHUNT_FT:
	case GAME_TYPE_KEYHUNT_CA:
		return "Every team begins the round with one key.\nSteal all the keys and bring them together to score.";
	case GAME_TYPE_FREEZETAG:
		return "Frag your opponents to turn them into ice blocks.\nFreeze the entire opposite team to win the round.\nYou can unfreeze your frozen teammates by standing next to them.";
	case GAME_TYPE_DOMINATION:
		return "Several control points are placed around the map.\nWalk over a control point to capture it.\nWhile captured, control points keep adding to your score until the limit is reached.";
	//case GAME_TYPE_JAILBREAK;
	//	return "Frag the enemy team to send them into a jail!\nCapture their controlpoint to release your imprisoned teammates.\nLock all of your opponents to win the round.";
	case GAME_TYPE_DEATHMATCH:
		return "Free-for-all: the player who gets the most frags wins.";
	case GAME_TYPE_TEAM_DEATHMATCH:
		return "Team-based deathmatch: the team that gets the most frags wins.";
	case GAME_TYPE_CLANARENA:
		return "Team-based survival mode.\nYou Only Live Once (per round)!";
	}
	return "No description is available for this gametype";
}

float(float bInputType, float nPrimary, float nSecondary) rm_game_type_vote_input_event {
	float imp;
	if (bInputType != 0 || main_isdemo)
		return FALSE;

	if ('0' <= nPrimary && nPrimary <= '9') {
		// number-based voting is not prefered in NeX - but still possible manually using impulse
		imp = nPrimary - '0';
		rm_game_type_vote_own = imp;
		if (imp == 0) imp = 10;
		localcmd(strcat("\nimpulse ", ftos(imp), "\n"));
		return TRUE;
	}
	if (nPrimary == K_MOUSE1) {
		if (rm_game_type_vote_selection >= 0) {
			imp = min(rm_game_type_vote_selection + 1, rm_game_type_vote_max);
			localcmd(strcat("\nimpulse ", ftos(imp), "\n"));
			return TRUE;
		}
	}
	return FALSE;
}

vector(float id) rm_game_type_vote_rgb {
	if (id == rm_game_type_vote_own)
		return '0 1 0';
	else if (id == rm_game_type_vote_selection)
		return '1 1 0';
	else
		return '1 1 1';
}

float() rm_game_type_vote_select {
	float r;
	float offset = sbar_fontsize_y * 10;
	float i;
	r = -1;
	for (i = 0; i < rm_game_type_vote_max; ++i) {
		float sz;
		sz = sbar_fontsize_y * 1.4 + tokenizebyseparator(rm_game_type_vote_description(i), "\n") * sbar_fontsize_y;
		if(mouse_pos_y >= offset && mouse_pos_y <= offset + sz)
			r = i;

		offset += sz + sbar_fontsize_y;
	}
	if (r >= 0)
	if (rm_game_type_vote_types[r] & 64)
		return - 1;

	return r;
}

string(float id, string map, float count, float maxwidth) rm_game_type_vote_format {
	string pre = "", post = "";
	if (count >= 0) {
		if (count == 1)
			post = strcat(" (1 vote)");
		else
			post = strcat(" (", ftos(count), " votes)");
	}
	maxwidth -= stringwidth(pre, FALSE) * sbar_fontsize_x + stringwidth(post, FALSE) * sbar_fontsize_x;
	map = str_shorten_to_width(map, maxwidth, str_width_nocolors);
	return strcat(pre, map, post);
}

vector(vector o, float gtype, float count, float id) rm_game_type_vote_draw_item {
	#define drawGameTypeLine(s,c,sc,a) \
	drawstring(o, (s), sbar_fontsize * (sc), (c), a * alpha, DRAWFLAG_NORMAL); \
	o_y += sbar_fontsize_y * sc *  (1 - pow(alpha - 1, 2))
	string s;
	s = rm_game_type_vote_description(id);
	float a, i, n = tokenizebyseparator(s, "\n");
	float alpha = bound(0, 0.5 * (time - rm_game_type_vote_starttime), 1);
	if (gtype & 64)
		a = 0.3;
	else
		a = 1;

	float oldx = o_x;
	o_x -= 10 * rm_game_type_vote_hoveralpha[id];
	drawGameTypeLine(rm_game_type_vote_format(id, game_type_name_long(gtype & 63), count, 500), rm_game_type_vote_rgb(id), 1.4, a);
	if (s != "") for(i = 0; i < n; ++i) {
		drawGameTypeLine(argv(i), '1 1 1', 1, a);
	}
	drawGameTypeLine("", '1 1 1', 1, 1);
	o_x = oldx;
	#undef drawGameTypeLine
	return o;
}

void(void) rm_game_type_vote_draw {
	if (sbar_showscores) return;
	view_crosshair = FALSE;
	sbar_hidescores = TRUE;
	vector pos;
	string map;
	float xmin, xmax, ymin, ymax = 0, i;
	float center = (CVAR(vid_conwidth) - 1)/2;
	xmin = CVAR(vid_conwidth) * 0.05; // 5% border must suffice
	xmax = CVAR(vid_conwidth) - xmin;
	ymin = 20;
	i = CVAR(con_chatpos);
	if (i < 0)
		ymax = CVAR(vid_conheight) + (i - CVAR(con_chat)) * CVAR(con_chatsize);

	if (i >= 0 || ymax < CVAR(vid_conheight) * 0.5)
		ymax = CVAR(vid_conheight) - ymin;

	//Title
	drawfont = sbar_bigfont;
	pos_y = ymin;
	pos_z = 0;
	pos_x = center - stringwidth("Decide the gametype", FALSE) * 24 * 0.5;
	drawstring(pos, "Decide the gametype", '24 24 0', '1 1 1', 1, DRAWFLAG_NORMAL);
	pos_y += 26;
	i = ceil(max(0, rm_game_type_vote_timeout - time));
	map = strcat(ftos(i), " seconds left");
	pos_x = center - stringwidth(map, FALSE) * 16 * 0.5;
	drawstring(pos, map, '16 16 0', '0 1 0', 1, DRAWFLAG_NORMAL);
	pos_y += 22;
	pos_x = xmin;
	//Map preview
	drawfont = sbar_font;
	float a = bound(0, (time - rm_game_type_vote_starttime), 1);
	vector o = '0 0 0';
	vector img_size = '0 0 0';
	vector img_fullsize;
	float isize = CVAR(vid_conwidth) * 0.25;
	img_size_y = isize;
	img_size_x = isize / 0.75;
	img_fullsize = img_size;
	img_size *= a;
	o_x = CVAR(vid_conwidth) * 0.75 - img_fullsize_x * 0.5;
	o_y = sbar_fontsize_y * 10;
	vector o2 = o + 0.5 * (img_fullsize - img_size);
	draw_borderlines(sbar_border_thickness, o2, img_size, '0 0 0', 1, DRAWFLAG_NORMAL);
	if (rm_game_type_vote_map_pic_ready)
		drawpic(o2, rm_game_type_vote_map_pic, img_size, '1 1 1', a, DRAWFLAG_NORMAL);

	vector sz = sbar_fontsize * a;
	img_size = img_fullsize;
	if (sz_x > 0) {
		o_y += img_size_y + 10;
		o_x += img_size_x / 2 - (str_width_nocolors(rm_game_type_vote_map) * sz_x / 2);
		drawstring(o, rm_game_type_vote_map, sz, '1 1 1' * a * a, a * a, DRAWFLAG_NORMAL);
	}
	//Game types
	o_x = max(CVAR(vid_conwidth) * 0.25 - (sbar_fontsize_x * rm_game_type_vote_longest) * 0.25, sbar_fontsize_x);
	o_y = sbar_fontsize_y * 10;
	float tmp;
	for (i = 0; i < rm_game_type_vote_max; ++i) {
		float ha = rm_game_type_vote_hoveralpha[i];
		float ha_speed = 5;
		float gt = rm_game_type_vote_types[i];
		if not(gt) break;
		if (i == rm_game_type_vote_selection)
			ha = bound(0, ha + frametime * ha_speed, 1);
		else
			ha = bound(0, ha - frametime * ha_speed, 1);
		
		rm_game_type_vote_hoveralpha[i] = ha;
		tmp = rm_game_type_vote_votes[i];
		o = rm_game_type_vote_draw_item(o, rm_game_type_vote_types[i], tmp, i);
	}
	mouse_enable("");
	input_event_callback = rm_game_type_vote_input_event;
	rm_game_type_vote_selection = rm_game_type_vote_select();
}

void(void) rm_game_type_vote_picture_check {
	if not(file_exists_image(rm_game_type_vote_map_pic)) {
		localcmd("cmd mv_getpic\n"); //reuse cmd from map vote
	} else
		rm_game_type_vote_map_pic_ready = TRUE;
}

void(float ignore) rm_game_type_vote_read {
	float sf = net_read_byte();
	float i, j, n, tmp;
	string pakfile;
	if (sf & 1) {
		rm_game_type_vote_max = 0;
		rm_game_type_vote_selection = -1;
		rm_game_type_vote_own = -1;
		rm_game_type_vote_timeout = time + net_read_coord();
		rm_game_type_vote_starttime = time;
		str_unzone_ifneeded(rm_game_type_vote_map);
		str_unzone_ifneeded(rm_game_type_vote_map_pic);
		rm_game_type_vote_map = str_zone_ifneeded(net_read_string());
		rm_game_type_vote_map_pic = str_zone_ifneeded(net_read_string());
		pakfile = net_read_string();
		if not(file_exists_image(rm_game_type_vote_map_pic)) {
			rm_game_type_vote_map_pic_ready = FALSE;
			if (pakfile != "") {
				localcmd("curl --pak ", pakfile, "\n");
				localcmd("cl_cmd rm_game_type_vote_picture_check\n");
			} else
				rm_game_type_vote_picture_check();
		} else
			rm_game_type_vote_map_pic_ready = TRUE;

		for (i = 0; i < 10; i++) {
			rm_game_type_vote_types[i] = net_read_byte();
			n = tokenizebyseparator(rm_game_type_vote_description(i), "\n");
			for (j = 0; j < n; ++j) {
				tmp = strlen(argv(j));
				if (tmp > rm_game_type_vote_longest) {
					rm_game_type_vote_longest = tmp;
				}
			}
		}
		self.draw2d = rm_game_type_vote_draw;
		self.draw2dflag = 1;
		for (i = 0; i < 10; i++) {
			if (rm_game_type_vote_types[i]) {
				rm_game_type_vote_max++;
			} else
				break;
		}
	}
	if (sf & 2) {
		for (i = 0; i < 10; i++)
			rm_game_type_vote_votes[i] = net_read_byte();
	}
}
