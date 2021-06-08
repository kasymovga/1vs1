float mapvote_count;
string mapvote_gametype;
string mapvote_maps[MAPVOTE_COUNT];
string mapvote_pics[MAPVOTE_COUNT];
string mapvote_paks[MAPVOTE_COUNT];
float mapvote_previews[MAPVOTE_COUNT];
float mapvote_votes[MAPVOTE_COUNT];
entity mapvote_paklist;
float mapvote_abstain;
float mapvote_ownvote;
float mapvote_detail;
float mapvote_timeout;
float mapvote_maps_mask;
vector mapvote_pos, mapvote_dist;
float mapvote_rows, mapvote_columns;
float mapvote_selection;

float(string name) mapvote_preview_exists {
	if (CVAR(cl_readpicture_force))
		return FALSE;

	return file_exists_image(name);
}

float(void) mapvote_select {
	float cell;
	float c, r;
	cell = -1;
	vector v = mouse_position();
	for (r = 0; r < mapvote_rows; ++r)
		for (c = 0; c < mapvote_columns; ++c) {
			if (v_x >= mapvote_pos_x + mapvote_dist_x *  c &&
					v_x <= mapvote_pos_x + mapvote_dist_x * (c + 1) &&
					v_y >= mapvote_pos_y + mapvote_dist_y *  r &&
					v_y <= mapvote_pos_y + mapvote_dist_y * (r + 1)) {
				cell = r * mapvote_columns + c;
				break;
			}
		}
	if (cell >= mapvote_count)
		cell = -1;

	if (mapvote_abstain && cell < 0)
		return mapvote_count;

	return cell;
}

float(float bInputType, float nPrimary, float nSecondary) mapvote_input_event {
	float imp;
	if (bInputType != 0)
		return FALSE;

	if ('0' <= nPrimary && nPrimary <= '9') {
		// number-based voting is not prefered in NeX - but still possible manually using impulse
		imp = nPrimary - '0';
		if (imp == 0) imp = 10;
		localcmd(strcat("\nimpulse ", ftos(imp), "\n"));
		return TRUE;
	}
	if (nPrimary == K_MOUSE1) {
		mapvote_selection = mapvote_select();
		if (mapvote_selection >= 0) {
			imp = min(mapvote_selection + 1, mapvote_count);
			localcmd(strcat("\nimpulse ", ftos(imp), "\n"));
			return TRUE;
		}
	}
	return FALSE;
}

string(float id, string map, float count, float maxwidth) mapvote_item_format {
	string pre, post;
	pre = strcat(ftos(id+1), ". ");
	if (mapvote_detail) {
		if(count == 1)
			post = strcat(" (1 vote)");
		else
			post = strcat(" (", ftos(count), " votes)");
	} else
		post = "";

	maxwidth -= stringwidth(pre, FALSE) + stringwidth(post, FALSE);
	map = str_shorten_to_width(map, maxwidth, str_width_nocolors);
	return strcat(pre, map, post);
}

vector(float id) mapvote_rgb {
	if (id == mapvote_ownvote)
		return '1 1 0';
	else
		return '1 1 1';
}

void(vector pos, float isize, float tsize, string map, string pic, float count, float id) mapvote_item_draw {
	vector img_size;
	vector rgb;
	string label;
	float text_size;
	isize -= sbar_fontsize_y; // respect the text when calculating the image size
	rgb = mapvote_rgb(id);
	img_size_y = isize;
	img_size_x = isize / 0.75; // 4:3 x can be stretched easily, height is defined in isize
	drawfont = sbar_font;
	pos_y = pos_y + img_size_y;
	label = mapvote_item_format(id, map, count, tsize / sbar_fontsize_x);
	text_size = stringwidth(label, FALSE) * sbar_fontsize_x;
	pos_x -= text_size*0.5;
	drawstring(pos, label, sbar_fontsize, rgb, 1, DRAWFLAG_NORMAL);
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
	if (id == mapvote_ownvote || pic == "") {
		draw_borderlines(sbar_border_thickness, pos, img_size, rgb, 1, DRAWFLAG_NORMAL);
		drawpic(pos + '1 0 0', strcat("gfx/hud/num_", ftos(id+1)), (img_size_y / 5) * '1 1 0', rgb, 0.6, DRAWFLAG_NORMAL);
	} else {
		draw_borderlines(sbar_border_thickness, pos, img_size, '0 0 0', 1, DRAWFLAG_NORMAL);
		drawpic(pos + '1 0 0', strcat("gfx/hud/num_", ftos(id+1)), (img_size_y / 5) * '1 1 0', '1 1 1', 0.6, DRAWFLAG_NORMAL);
	}
}

void(vector pos, float isize, float tsize, float count, float id) mapvote_abstain_draw {
	vector rgb;
	float text_size;
	string label;
	rgb = mapvote_rgb(id);
	drawfont = sbar_font;
	pos_y = pos_y + sbar_fontsize_y;
	label = mapvote_item_format(id, "Don't care", count, tsize / sbar_fontsize_x);
	text_size = stringwidth(label, FALSE) * sbar_fontsize_x;
	pos_x -= text_size*0.5;
	drawstring(pos, label, sbar_fontsize, rgb, 1, DRAWFLAG_NORMAL);
}

vector(vector gridspec, float i, float m) mapvote_grid {
	float r = math_mod(i, m);
	return '1 0 0' * (gridspec_x * r) + '0 1 0' * (gridspec_y * (i - r) / m);
}

void(void) mapvote_draw {
	string map;
	float i, tmp;
	vector pos;
	float isize;
	float center;
	float tsize;
	float xmin, xmax, ymin, ymax;
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
	string s = strcat("Vote for a map (^2", mapvote_gametype, "^7)");
	pos_x = center - stringwidth(s, TRUE) * 0.5 * 24;
	drawcolorcodedstring(pos, s, '24 24 0', 1, DRAWFLAG_NORMAL);
	pos_y += 26;
	i = ceil(max(0, mapvote_timeout - time));
	map = strcat(ftos(i), " seconds left");
	pos_x = center - stringwidth(map, FALSE) * 0.5 * 16;
	drawstring(pos, map, '16 16 0', '0 1 0', 1, DRAWFLAG_NORMAL);
	pos_y += 22;
	pos_x = xmin;
	drawfont = sbar_font;
	// base for multi-column stuff...
	ymin = pos_y;
	if (mapvote_abstain)
		mapvote_count -= 1;
	
	if (mapvote_count > 3) {
		mapvote_columns = 3;
	} else {
		mapvote_columns = mapvote_count;
	}
	mapvote_rows = ceil(mapvote_count / mapvote_columns);
	dist_x = (xmax - xmin) / mapvote_columns;
	dist_y = (ymax - pos_y) / mapvote_rows;
	tsize = dist_x - 10;
	isize = min(dist_y - 10, 0.75 * tsize);
	mapvote_pos = pos;
	mapvote_dist = dist;
	mapvote_selection = mapvote_select();
	pos_x += (xmax - xmin) / (2 * mapvote_columns);
	pos_y += (dist_y - isize) / 2;
	ymax -= isize;
	for (i = 0; i < mapvote_count; ++i) {
		tmp = mapvote_votes[i]; // FTEQCC bug: too many array accesses in the function call screw it up
		if (tmp < 0)
			continue;
		map = mapvote_maps[i];
		if (mapvote_previews[i])
			mapvote_item_draw(pos + mapvote_grid(dist, i, mapvote_columns), isize, tsize, map, mapvote_pics[i], tmp, i);
		else
			mapvote_item_draw(pos + mapvote_grid(dist, i, mapvote_columns), isize, tsize, map, "", tmp, i);
	}
	if (mapvote_abstain)
		++mapvote_count;

	if (mapvote_abstain && i < mapvote_count) {
		tmp = mapvote_votes[i];
		pos_y = ymax + isize - sbar_fontsize_y;
		pos_x = (xmax+xmin)*0.5;
		mapvote_abstain_draw(pos, isize, xmax - xmin, tmp, i);
	}
	mouse_enable("");
	input_event_callback = mapvote_input_event;
}

void(float argc) mapvote_preview_download {
	float id;
	entity pak;
	if (argc != 2 || !mapvote_paklist) {
		print("mv_mapdownload: ^3You're not supposed to use this command on your own!\n");
		return;
	}
	id = stof(argv(1));
	for (pak = mapvote_paklist; pak; pak = pak.chain)
		if(pak.sv_entnum == id)
			break;
	
	if (!pak || pak.sv_entnum != id) {
		print("^1Error:^7 Couldn't find pak index.\n");
		return;
	}
	if (mapvote_preview_exists(pak.message)) {
		mapvote_previews[id] = TRUE;
		//print("^2Found...\n");
		return;
	} else {
		print("Requesting preview...\n");
		localcmd(strcat("\ncmd mv_getpic ", ftos(id), "\n"));
	}
}

void(string pic, string pk3, float id) mapvote_checkpk3 {
	entity pak;
	pak = spawn();
	pak.netname = pk3;
	pak.message = pic;
	pak.sv_entnum = id;
	pak.chain = mapvote_paklist;
	mapvote_paklist = pak;
	if (pk3 != "") {
		localcmd(strcat("\ncurl --pak ", pk3, "; wait; cl_cmd mv_download ", ftos(id), "\n"));
	} else {
		mapvote_preview_download(tokenize_console(strcat("mv_download ", ftos(id))));
	}
}

void(string pic, string pk3, float id) mapvote_checkpic {
	// never try to retrieve a pic for the "don't care" 'map'
	if (mapvote_abstain && id == mapvote_count - 1)
		return;

	if (mapvote_preview_exists(pic)) {
		mapvote_previews[id] = TRUE;
		return;
	}
	mapvote_checkpk3(pic, pk3, id);
}

void(void) mapvote_init {
	float i, power;
	string map, pk3, map_pic;
	mapvote_active = 1;
	mapvote_selection = -1;
	str_unzone_ifneeded(mapvote_gametype);
	mapvote_gametype = str_zone_ifneeded(ReadString());
	mapvote_count = min(MAPVOTE_COUNT, ReadByte());
	mapvote_abstain = ReadByte();
	if (mapvote_abstain)
		mapvote_abstain = 1; // must be 1 for bool-true, makes stuff easier

	mapvote_detail = ReadByte();
	mapvote_ownvote = -1;
	mapvote_timeout = ReadCoord();
	if (mapvote_count <= 8)
		mapvote_maps_mask = ReadByte();
	else
		mapvote_maps_mask = ReadShort();
	
	// Assume mapvote_paklist is NULL, there should only be 1 mapvote per round
	mapvote_paklist = NULL; // I'm still paranoid!
	for (i = 0, power = 1; i < mapvote_count; ++i, power *= 2) {
		mapvote_votes[i] = 0;
		if (mapvote_maps_mask & power) {
			map = strzone(ReadString());
			map_pic = strzone(ReadString());
			pk3 = strzone(ReadString());
			mapvote_maps[i] = map;
			mapvote_paks[i] = pk3;
			mapvote_pics[i] = map_pic;
			mapvote_previews[i] = FALSE;
			//print(strcat("RECV: ", map, " in ", pk3, "\n"));
			mapvote_checkpic(map_pic, pk3, i);
		} else {
			mapvote_maps[i] = strzone("if-you-see-this-the-code-is-broken");
			mapvote_paks[i] = strzone("if-you-see-this-the-code-is-broken");
			mapvote_pics[i] = strzone("if-you-see-this-the-code-is-broken");
			mapvote_previews[i] = FALSE;
		}
	}
}

void(void) mapvote_update_mask {
	float i, power;
	float oldmask;
	oldmask = mapvote_maps_mask;
	if (mapvote_count <= 8)
		mapvote_maps_mask = ReadByte();
	else
		mapvote_maps_mask = ReadShort();

	// remove votes that no longer apply
	for (i = 0, power = 1; i < mapvote_count; ++i, power *= 2)
		if not(mapvote_maps_mask & power)
			mapvote_votes[i] = -1;
}

void(void) mapvote_update_votes {
	float i, power;
	for (i = 0, power = 1; i < mapvote_count; ++i, power *= 2) {
		if (mapvote_maps_mask & power) {
			if (mapvote_detail)
				mapvote_votes[i] = ReadByte();
			else
				mapvote_votes[i] = 0;
		} else
			mapvote_votes[i] = -1;
	}
	mapvote_ownvote = ReadByte() - 1;
}

void(void) mapvote_read {
	float sf;
	sf = ReadByte();
	if(sf & 1)
		mapvote_init();

	if(sf & 2)
		mapvote_update_mask();

	if(sf & 4)
		mapvote_update_votes();
}

void(void) mapvote_picture_read {
	float type;
	type = ReadByte();
	mapvote_previews[type] = TRUE;
	mapvote_pics[type] = strzone(ReadPicture());
}
