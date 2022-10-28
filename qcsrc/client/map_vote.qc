float map_vote_count;
string map_vote_gametype;
string map_vote_maps[MAP_VOTE_COUNT];
string map_vote_pics[MAP_VOTE_COUNT];
string map_vote_paks[MAP_VOTE_COUNT];
float map_vote_previews[MAP_VOTE_COUNT];
float map_vote_votes[MAP_VOTE_COUNT];
entity map_vote_paklist;
float map_vote_abstain;
float map_vote_ownvote;
float map_vote_detail;
float map_vote_timeout;
float map_vote_maps_mask;
vector map_vote_pos, map_vote_dist;
float map_vote_rows, map_vote_columns;
float map_vote_selection;

float(string name) map_vote_preview_exists {
	if (CVAR(cl_readpicture_force))
		return FALSE;

	return file_exists_image(name);
}

float(void) map_vote_select {
	float cell;
	float c, r;
	cell = -1;
	vector v = mouse_position();
	for (r = 0; r < map_vote_rows; ++r)
		for (c = 0; c < map_vote_columns; ++c) {
			if (v_x >= map_vote_pos_x + map_vote_dist_x *  c &&
					v_x <= map_vote_pos_x + map_vote_dist_x * (c + 1) &&
					v_y >= map_vote_pos_y + map_vote_dist_y *  r &&
					v_y <= map_vote_pos_y + map_vote_dist_y * (r + 1)) {
				cell = r * map_vote_columns + c;
				break;
			}
		}
	if (cell >= map_vote_count)
		cell = -1;

	if (map_vote_abstain && cell < 0)
		return map_vote_count;

	return cell;
}

float(float bInputType, float nPrimary, float nSecondary) map_vote_input_event {
	float imp;
	if (bInputType != 0 || main_isdemo)
		return FALSE;

	if ('0' <= nPrimary && nPrimary <= '9') {
		// number-based voting is not prefered in NeX - but still possible manually using impulse
		imp = nPrimary - '0';
		if (imp == 0) imp = 10;
		localcmd(strcat("\nimpulse ", ftos(imp), "\n"));
		return TRUE;
	}
	if (nPrimary == K_MOUSE1) {
		map_vote_selection = map_vote_select();
		if (map_vote_selection >= 0) {
			imp = min(map_vote_selection + 1, map_vote_count);
			localcmd(strcat("\nimpulse ", ftos(imp), "\n"));
			return TRUE;
		}
	}
	return FALSE;
}

string(float id, string map, float count, float maxwidth) map_vote_item_format {
	string pre, post;
	pre = strcat(ftos(id+1), ". ");
	if (map_vote_detail) {
		post = strcat("^0 (^8", ftos(count), "^0)");
	} else
		post = "";

	maxwidth -= stringwidth(strdecolorize(pre), FALSE) + stringwidth(strdecolorize(post), FALSE);
	map = str_shorten_to_width(map, maxwidth, str_width_colors);
	return strcat(pre, map, post);
}

vector(float id) map_vote_rgb {
	if (id == map_vote_ownvote)
		return '1 1 0';
	else
		return '1 1 1';
}

void(vector pos, float isize, float tsize, string map, string pic, float count, float id) map_vote_item_draw {
	vector img_size = '0 0 0';
	vector rgb;
	string label;
	float text_size;
	isize -= sbar_fontsize_y; // respect the text when calculating the image size
	rgb = map_vote_rgb(id);
	img_size_y = isize;
	img_size_x = isize / 0.75; // 4:3 x can be stretched easily, height is defined in isize
	drawfont = sbar_font;
	pos_y = pos_y + img_size_y;
	label = map_vote_item_format(id, map, count, tsize / sbar_fontsize_x);
	text_size = stringwidth(strdecolorize(label), FALSE) * sbar_fontsize_x;
	pos_x -= text_size*0.5;
	drawcolorcodedstring(pos, label, sbar_fontsize, 1, DRAWFLAG_NORMAL);
	pos_x = pos_x + text_size*0.5 - img_size_x*0.5;
	pos_y = pos_y - img_size_y;
	pos += sbar_border_thickness * '1 1 0';
	img_size -= (sbar_border_thickness * 2) * '1 1 0';
	if (pic == "") {
		drawfill(pos, img_size, '.5 .5 .5', .7, DRAWFLAG_NORMAL);
	} else {
		drawpic(pos, pic, img_size, '1 1 1', 1, DRAWFLAG_NORMAL);
	}
	drawpic(pos + '1 0 0', strcat("gfx/hud/num_", ftos(id+1)), (img_size_y / 5) * '1 1 0', '1 1 1', 0.6, DRAWFLAG_NORMAL);
	if (id == map_vote_ownvote || pic == "") {
		draw_borderlines(sbar_border_thickness, pos, img_size, rgb, 1, DRAWFLAG_NORMAL);
		drawpic(pos + '1 0 0', strcat("gfx/hud/num_", ftos(id+1)), (img_size_y / 5) * '1 1 0', rgb, 0.6, DRAWFLAG_NORMAL);
	} else {
		draw_borderlines(sbar_border_thickness, pos, img_size, '0 0 0', 1, DRAWFLAG_NORMAL);
		drawpic(pos + '1 0 0', strcat("gfx/hud/num_", ftos(id+1)), (img_size_y / 5) * '1 1 0', '1 1 1', 0.6, DRAWFLAG_NORMAL);
	}
}

void(vector pos, float isize, float tsize, float count, float id) map_vote_abstain_draw {
	vector rgb;
	float text_size;
	string label;
	rgb = map_vote_rgb(id);
	drawfont = sbar_font;
	pos_y = pos_y + sbar_fontsize_y;
	label = map_vote_item_format(id, "Don't care", count, tsize / sbar_fontsize_x);
	text_size = stringwidth(label, FALSE) * sbar_fontsize_x;
	pos_x -= text_size*0.5;
	drawstring(pos, label, sbar_fontsize, rgb, 1, DRAWFLAG_NORMAL);
}

vector(vector gridspec, float i, float m) map_vote_grid {
	float r = math_mod(i, m);
	return '1 0 0' * (gridspec_x * r) + '0 1 0' * (gridspec_y * (i - r) / m);
}

void(void) map_vote_draw {
	string map;
	float i, tmp;
	vector pos;
	float isize;
	float center;
	float tsize;
	float xmin, xmax, ymin, ymax = 0;
	vector dist;
	view_crosshair = FALSE;
	center = (CVAR(vid_conwidth) - 1)/2;
	xmin = CVAR(vid_conwidth)*0.05; // 5% border must suffice
	xmax = CVAR(vid_conwidth) - xmin;
	ymin = 20;
	i = CVAR(con_chatpos); //*con_chatsize;
	if (i < 0)
		ymax = CVAR(vid_conheight) + (i - CVAR(con_chat)) * CVAR(con_chatsize);

	if (i >= 0 || ymax < (CVAR(vid_conheight)*0.5))
		ymax = CVAR(vid_conheight) - ymin;

	drawfont = sbar_bigfont;
	sbar_fontsize = sbar_font_size(CVAR(sbar_fontsize));
	pos_y = ymin;
	pos_z = 0;
	string s = strcat("Vote for a map (^2", map_vote_gametype, "^7)");
	pos_x = center - stringwidth(strdecolorize(s), TRUE) * 0.5 * 24;
	drawcolorcodedstring(pos, s, '24 24 0', 1, DRAWFLAG_NORMAL);
	pos_y += 26;
	i = ceil(max(0, map_vote_timeout - time));
	map = strcat(ftos(i), " seconds left");
	pos_x = center - stringwidth(map, FALSE) * 0.5 * 16;
	drawstring(pos, map, '16 16 0', '0 1 0', 1, DRAWFLAG_NORMAL);
	pos_y += 22;
	pos_x = xmin;
	drawfont = sbar_font;
	// base for multi-column stuff...
	ymin = pos_y;
	if (map_vote_abstain)
		map_vote_count -= 1;
	
	if (map_vote_count > 3) {
		map_vote_columns = 3;
	} else {
		map_vote_columns = map_vote_count;
	}
	map_vote_rows = ceil(map_vote_count / map_vote_columns);
	dist_x = (xmax - xmin) / map_vote_columns;
	dist_y = (ymax - pos_y) / map_vote_rows;
	dist_z = 0;
	tsize = dist_x - 10;
	isize = min(dist_y - 10, 0.75 * tsize);
	map_vote_pos = pos;
	map_vote_dist = dist;
	map_vote_selection = map_vote_select();
	pos_x += (xmax - xmin) / (2 * map_vote_columns);
	pos_y += (dist_y - isize) / 2;
	ymax -= isize;
	for (i = 0; i < map_vote_count; ++i) {
		tmp = map_vote_votes[i]; // FTEQCC bug: too many array accesses in the function call screw it up
		if (tmp < 0)
			continue;
		map = map_vote_maps[i];
		if (map_vote_previews[i])
			map_vote_item_draw(pos + map_vote_grid(dist, i, map_vote_columns), isize, tsize, map, map_vote_pics[i], tmp, i);
		else
			map_vote_item_draw(pos + map_vote_grid(dist, i, map_vote_columns), isize, tsize, map, "", tmp, i);
	}
	if (map_vote_abstain)
		++map_vote_count;

	if (map_vote_abstain && i < map_vote_count) {
		tmp = map_vote_votes[i];
		pos_y = ymax + isize - sbar_fontsize_y;
		pos_x = (xmax+xmin)*0.5;
		map_vote_abstain_draw(pos, isize, xmax - xmin, tmp, i);
	}
	mouse_enable("");
	input_event_callback = map_vote_input_event;
}

void(float argc) map_vote_preview_download {
	float id;
	entity pak;
	if (argc != 2 || !map_vote_paklist) {
		print("mv_mapdownload: ^3You're not supposed to use this command on your own!\n");
		return;
	}
	id = stof(argv(1));
	for (pak = map_vote_paklist; pak; pak = pak.chain)
		if(pak.sv_entnum == id)
			break;
	
	if (!pak || pak.sv_entnum != id) {
		print("^1Error:^7 Couldn't find pak index.\n");
		return;
	}
	if (map_vote_preview_exists(pak.message)) {
		map_vote_previews[id] = TRUE;
		//print("^2Found...\n");
		return;
	} else {
		print("Requesting preview...\n");
		localcmd(strcat("\ncmd mv_getpic ", ftos(id), "\n"));
	}
}

void(string pic, string pk3, float id) map_vote_checkpk3 {
	entity pak;
	pak = spawn();
	pak.netname = pk3;
	pak.message = pic;
	pak.sv_entnum = id;
	pak.chain = map_vote_paklist;
	map_vote_paklist = pak;
	if (pk3 != "") {
		localcmd(strcat("\ncurl --pak ", pk3, "; wait; cl_cmd mv_download ", ftos(id), "\n"));
	} else {
		map_vote_preview_download(tokenize_console(strcat("mv_download ", ftos(id))));
	}
}

void(string pic, string pk3, float id) map_vote_checkpic {
	// never try to retrieve a pic for the "don't care" 'map'
	if (map_vote_abstain && id == map_vote_count - 1)
		return;

	if (map_vote_preview_exists(pic)) {
		map_vote_previews[id] = TRUE;
		return;
	}
	map_vote_checkpk3(pic, pk3, id);
}

void(void) map_vote_init {
	float i, power;
	string map, pk3, map_pic;
	map_vote_active = 1;
	map_vote_selection = -1;
	str_unzone_ifneeded(map_vote_gametype);
	map_vote_gametype = str_zone_ifneeded(net_read_string());
	map_vote_count = min(MAP_VOTE_COUNT, net_read_byte());
	map_vote_abstain = net_read_byte();
	if (map_vote_abstain)
		map_vote_abstain = 1; // must be 1 for bool-true, makes stuff easier

	map_vote_detail = net_read_byte();
	map_vote_ownvote = -1;
	map_vote_timeout = net_read_coord();
	if (map_vote_count <= 8)
		map_vote_maps_mask = net_read_byte();
	else
		map_vote_maps_mask = net_read_short();
	
	// Assume map_vote_paklist is NULL, there should only be 1 map_vote per round
	map_vote_paklist = NULL; // I'm still paranoid!
	for (i = 0, power = 1; i < map_vote_count; ++i, power *= 2) {
		map_vote_votes[i] = 0;
		if (map_vote_maps_mask & power) {
			map = strzone(net_read_string());
			map_pic = strzone(net_read_string());
			pk3 = strzone(net_read_string());
			map_vote_maps[i] = map;
			map_vote_paks[i] = pk3;
			map_vote_pics[i] = map_pic;
			map_vote_previews[i] = FALSE;
			//print(strcat("RECV: ", map, " in ", pk3, "\n"));
			map_vote_checkpic(map_pic, pk3, i);
		} else {
			map_vote_maps[i] = strzone("if-you-see-this-the-code-is-broken");
			map_vote_paks[i] = strzone("if-you-see-this-the-code-is-broken");
			map_vote_pics[i] = strzone("if-you-see-this-the-code-is-broken");
			map_vote_previews[i] = FALSE;
		}
	}
}

void(void) map_vote_update_mask {
	float i, power;
	float oldmask;
	oldmask = map_vote_maps_mask;
	if (map_vote_count <= 8)
		map_vote_maps_mask = net_read_byte();
	else
		map_vote_maps_mask = net_read_short();

	// remove votes that no longer apply
	for (i = 0, power = 1; i < map_vote_count; ++i, power *= 2)
		if not(map_vote_maps_mask & power)
			map_vote_votes[i] = -1;
}

void(void) map_vote_update_votes {
	float i, power;
	for (i = 0, power = 1; i < map_vote_count; ++i, power *= 2) {
		if (map_vote_maps_mask & power) {
			if (map_vote_detail)
				map_vote_votes[i] = net_read_byte();
			else
				map_vote_votes[i] = 0;
		} else
			map_vote_votes[i] = -1;
	}
	map_vote_ownvote = net_read_byte() - 1;
}

void(float ignore) map_vote_read {
	float sf;
	sf = net_read_byte();
	if(sf & 1)
		map_vote_init();

	if(sf & 2)
		map_vote_update_mask();

	if(sf & 4)
		map_vote_update_votes();
}

void(void) map_vote_picture_read {
	float type;
	type = net_read_byte();
	map_vote_previews[type] = TRUE;
	map_vote_pics[type] = strzone(net_read_picture());
}
