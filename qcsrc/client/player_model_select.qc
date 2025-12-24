entity player_model_select;
entity player_model_select_current;
entity player_model_select_torso;
entity player_model_select_head;
string player_model_select_list;
float player_model_select_list_len;
float player_model_select_list_pos;
float player_model_select_list_pos_prev;

const vector PLAYER_MODEL_SELECT_PREV_POS = '-270 200 0';
const vector PLAYER_MODEL_SELECT_PREV_SIZE = '120 60 0';
const vector PLAYER_MODEL_SELECT_NEXT_POS = '150 200 0';
const vector PLAYER_MODEL_SELECT_NEXT_SIZE = '120 60 0';
const vector PLAYER_MODEL_SELECT_OK_POS = '-170 350 0';
const vector PLAYER_MODEL_SELECT_OK_SIZE = '100 30 0';
const vector PLAYER_MODEL_SELECT_CANCEL_POS = '50 350 0';
const vector PLAYER_MODEL_SELECT_CANCEL_SIZE = '120 30 0';

float(void) player_model_select_choosen_button {
	vector v = mouse_position();
	v_x = v_x - (CVAR(vid_conwidth) / 2);
	if (v_x >= PLAYER_MODEL_SELECT_PREV_POS_x && v_x <= PLAYER_MODEL_SELECT_PREV_POS_x + PLAYER_MODEL_SELECT_PREV_SIZE_x && v_y >= PLAYER_MODEL_SELECT_PREV_POS_y && v_y <= PLAYER_MODEL_SELECT_PREV_POS_y + PLAYER_MODEL_SELECT_PREV_SIZE_y)
		return 1;
	else if (v_x >= PLAYER_MODEL_SELECT_NEXT_POS_x && v_x <= PLAYER_MODEL_SELECT_NEXT_POS_x + PLAYER_MODEL_SELECT_NEXT_SIZE_x && v_y >= PLAYER_MODEL_SELECT_NEXT_POS_y && v_y <= PLAYER_MODEL_SELECT_NEXT_POS_y + PLAYER_MODEL_SELECT_NEXT_SIZE_y)
		return 2;
	else if (v_x >= PLAYER_MODEL_SELECT_OK_POS_x && v_x <= PLAYER_MODEL_SELECT_OK_POS_x + PLAYER_MODEL_SELECT_OK_SIZE_x && v_y >= PLAYER_MODEL_SELECT_OK_POS_y && v_y <= PLAYER_MODEL_SELECT_OK_POS_y + PLAYER_MODEL_SELECT_OK_SIZE_y)
		return 3;
	else if (v_x >= PLAYER_MODEL_SELECT_CANCEL_POS_x && v_x <= PLAYER_MODEL_SELECT_CANCEL_POS_x + PLAYER_MODEL_SELECT_CANCEL_SIZE_x && v_y >= PLAYER_MODEL_SELECT_CANCEL_POS_y && v_y <= PLAYER_MODEL_SELECT_CANCEL_POS_y + PLAYER_MODEL_SELECT_CANCEL_SIZE_y)
		return 4;

	return 0;
}

void(void) player_model_select_remove {
	remove(player_model_select);
	player_model_select = world;
	remove(player_model_select_current);
	player_model_select_current = world;
	remove(player_model_select_head);
	player_model_select_head = NULL;
	remove(player_model_select_torso);
	player_model_select_torso = NULL;
}

float(float bInputType, float nPrimary, float nSecondary) player_model_select_input_event {
	if (bInputType == 0) {
		if (nPrimary == K_ESCAPE) {
			player_model_select_remove();
			return TRUE;
		}
		if (nPrimary == K_MOUSE1) {
			float i = player_model_select_choosen_button();
			if (i == 1)
				player_model_select_list_pos--;
			else if (i == 2)
				player_model_select_list_pos++;
			else if (i == 3) {
				localcmd("playermodel ", player_model_select_current.model, ";playerskin ", ftos(player_model_select_current.skin), ";menu_cmd sync\n");
				player_model_select_remove();
			} else if (i == 4)
				player_model_select_remove();

			return TRUE;
		}
	}
	return FALSE;
}

void(string _model) player_model_select_get_idle_animinfo {
	float f = fopen(strcat(_model, ".animinfo"), FILE_READ);
	if (f < 0) return;
	float i;
	for (i = 0; i < 8; i++) fgets(f);
	string s = fgets(f);
	fclose(f);
	float c = tokenize_console(s);
	if (c > 2) {
		player_model_select_current.frame = stof(argv(0));
		player_model_select_torso.frame = stof(argv(0));
	}
}

void(string _model) player_model_select_get_idle_animinfo2 {
	float f = fopen(strcat(_model, ".animinfo2"), FILE_READ);
	if (f < 0) return;
	float i;
	string s;
	float c;
	player_model_select_current.frame = 7; //default
	while ((s = fgets(f))) {
		c = tokenize_console(s);
		s = argv(0);
		if (s == "scale" && c > 1) {
			player_model_select_current.scale *= stof(argv(1));
		} else if (s == "idle" && c > 3) {
			player_model_select_current.frame = stof(argv(1));
		} else if (s == "stand" && c > 3) {
			player_model_select_torso.frame = stof(argv(1));
		}
	}
	fclose(f);
}

void(string _model) player_model_select_get_idle_q3animations {
	float f = fopen(strcat(_model, ".q3animations"), FILE_READ);
	if (f < 0) return;
	float i;
	string s;
	float c;
	float animline = 0;
	float gestureframe = 0;
	float walkcrframe = 0;
	while ((s = fgets(f))) {
		c = tokenize_console(s);
		s = argv(0);
		if (strstrofs("0123456789", substring(s, 0, 1), 0) >= 0 && c > 3) {
			animline++;
			if (animline == 7) { //GESTURE
				gestureframe = stof(s);
			} else if (animline == 12) { //STAND
				player_model_select_torso.frame = stof(s);
			} else if (animline == 14) { //WALKCR
				walkcrframe = stof(s);
			} else if (animline == 23) { //IDLE
				player_model_select_current.frame = stof(s) - walkcrframe + gestureframe;
				break;
			}
		} else if (s == "headoffset" && c > 3) {
			//actually this offset mean something else
			//setorigin(player_model_select_head, stof(argv(1)) * '1 0 0' + stof(argv(2)) * '0 1 0' + stof(argv(3)) * '0 0 1');
		}
	}
	fclose(f);
}

float player_model_select_draw_last_noviewmodel;
void(void) player_model_select_draw {
	input_event_callback = player_model_select_input_event;
	mouse_enable("");
	string s = player_model_select_list;
	float noviewmodel = (CVAR(chase_active) || !cvar("r_drawviewmodel"));
	if (player_model_select_list_pos_prev != player_model_select_list_pos || noviewmodel != player_model_select_draw_last_noviewmodel) {
		player_model_select_draw_last_noviewmodel = noviewmodel;
		if (player_model_select_list_pos >= player_model_select_list_len)
			player_model_select_list_pos = 0;
		else if (player_model_select_list_pos < 0)
			player_model_select_list_pos = player_model_select_list_len - 1;

		float i;
		for (i = 0; i < player_model_select_list_pos; i++)
			s = str_cdr(s);

		s = str_car(s);
		float colon = strstrofs(s, ":", 0);
		string _model = substring(s, 0, colon);
		float _skin = stof(substring(s, colon + 1, -1));
		precache_model(_model);
		setmodel(player_model_select_current, _model);
		float fov_factor = (view_fov / 90);
		if (noviewmodel) {
			player_model_select_current.scale = 0.4 * fov_factor;
			view_fixed_angles_x = 0;
		} else
			player_model_select_current.scale = 0.8 * fov_factor;

		string s = strcat(substring(_model, 0, strlen(_model) - 4), "_torso", substring(_model, -4, 4));
		if (file_exists(s)) {
			precache_model(s);
			setmodel(player_model_select_torso, s);
			setattachment(player_model_select_torso, player_model_select_current, "tag_torso");
			string s = strcat(substring(_model, 0, strlen(_model) - 4), "_head", substring(_model, -4, 4));
			if (file_exists(s)) {
				precache_model(s);
				setmodel(player_model_select_head, s);
				setorigin(player_model_select_head, '0 0 0');
				setattachment(player_model_select_head, player_model_select_torso, "tag_head");
			} else
				setmodel(player_model_select_head, "null");
		} else {
			setmodel(player_model_select_torso, "null");
			setmodel(player_model_select_head, "null");
		}
		player_model_select_current.skin = _skin;
		player_model_select_torso.frame = 0;
		player_model_select_torso.skin = _skin;
		player_model_select_head.skin = _skin;
		player_model_select_current.frame = 7;
		if (file_exists(strcat(_model, ".animinfo"))) {
			player_model_select_get_idle_animinfo(_model);
		}
		if (file_exists(strcat(_model, ".animinfo2"))) {
			player_model_select_get_idle_animinfo2(_model);
		}
		if (file_exists(strcat(_model, ".q3animations"))) {
			player_model_select_get_idle_q3animations(_model);
		}
		player_model_select_list_pos_prev = player_model_select_list_pos;
	}
	if (noviewmodel) {
		makevectors(view_camera_angles);
		setorigin(player_model_select_current, view_camera_origin + v_forward * 50);
	} else
		setorigin(player_model_select_current, '100 0 0');

	player_model_select_current.angles_y = view_angles_y + (time * 90);
	vector c = '1 0 0' * (CVAR(vid_conwidth) / 2);
	drawfont = sbar_bigfont;
	draw_string_center('0 100 0', _("Model select"), '24 24 0', '1 1 1', 1, DRAWFLAG_NORMAL);
	draw_string_center('0 125 0', strcat(player_model_select_current.model, ":", ftos(player_model_select_current.skin)), '18 18 0', '1 1 1', 1, DRAWFLAG_NORMAL);
	vector ca;
	float button = player_model_select_choosen_button();
	//Previous
	if (button == 1) ca = '0.5 0.5 0.5'; else ca = '0 0 0';
	drawfill(PLAYER_MODEL_SELECT_PREV_POS + c, PLAYER_MODEL_SELECT_PREV_SIZE, '0 0 0' + ca, 0.3, DRAWFLAG_NORMAL);
    draw_borderlines(2, PLAYER_MODEL_SELECT_PREV_POS + c, PLAYER_MODEL_SELECT_PREV_SIZE, '0 0 0' + ca, 1, DRAWFLAG_NORMAL);
	draw_string_center(PLAYER_MODEL_SELECT_PREV_POS + ('1 0 0' * PLAYER_MODEL_SELECT_PREV_SIZE_x * 0.5), "<", '60 60 0', '1 1 0' + ca, 1, DRAWFLAG_NORMAL);
	//Next
	if (button == 2) ca = '0.5 0.5 0.5'; else ca = '0 0 0';
	drawfill(PLAYER_MODEL_SELECT_NEXT_POS + c, PLAYER_MODEL_SELECT_NEXT_SIZE, '0 0 0' + ca, 0.3, DRAWFLAG_NORMAL);
    draw_borderlines(2, PLAYER_MODEL_SELECT_NEXT_POS + c, PLAYER_MODEL_SELECT_NEXT_SIZE, '0 0 0' + ca, 1, DRAWFLAG_NORMAL);
	draw_string_center(PLAYER_MODEL_SELECT_NEXT_POS + ('1 0 0' * PLAYER_MODEL_SELECT_NEXT_SIZE_x * 0.5), ">", '60 60 0', '1 1 0' + ca, 1, DRAWFLAG_NORMAL);
	//Ok
	if (button == 3) ca = '0.5 0.5 0.5'; else ca = '0 0 0';
	drawfill(PLAYER_MODEL_SELECT_OK_POS + c, PLAYER_MODEL_SELECT_OK_SIZE, '0 0 0' + ca, 0.3, DRAWFLAG_NORMAL);
    draw_borderlines(2, PLAYER_MODEL_SELECT_OK_POS + c, PLAYER_MODEL_SELECT_OK_SIZE, '0 0 0' + ca, 1, DRAWFLAG_NORMAL);
	draw_string_center(PLAYER_MODEL_SELECT_OK_POS + ('1 0 0' * PLAYER_MODEL_SELECT_OK_SIZE_x * 0.5), _("Ok"), '30 30 0', '0 1 0' + ca, 1, DRAWFLAG_NORMAL);
	//Cancel
	if (button == 4) ca = '0.5 0.5 0.5'; else ca = '0 0 0';
	drawfill(PLAYER_MODEL_SELECT_CANCEL_POS + c, PLAYER_MODEL_SELECT_CANCEL_SIZE, '0 0 0' + ca, 0.3, DRAWFLAG_NORMAL);
    draw_borderlines(2, PLAYER_MODEL_SELECT_CANCEL_POS + c, PLAYER_MODEL_SELECT_CANCEL_SIZE, '0 0 0' + ca, 1, DRAWFLAG_NORMAL);
	draw_string_center(PLAYER_MODEL_SELECT_CANCEL_POS + ('1 0 0' * PLAYER_MODEL_SELECT_CANCEL_SIZE_x * 0.5), _("Cancel"), '30 30 0', '1 0 0' + ca, 1, DRAWFLAG_NORMAL);
    drawfont = sbar_font;
}

void(string s, string curmodel, float curskin) player_model_select_list_add {
	if (strstrofs(s, "/", 0) < 0)
		s = strcat("models/player/", s);

	if (player_model_select_list == "")
		player_model_select_list = s;
	else
		player_model_select_list = strcat(player_model_select_list, " ", s);

	if (s == strcat(curmodel, ":", ftos(curskin)))
		player_model_select_list_pos = player_model_select_list_len;

	player_model_select_list_len++;
}

void(string s, string curmodel, float curskin) player_model_select_list_add_all_skins {
	float i;
	player_model_select_list_add(strcat(s, ":0"), curmodel, curskin);
	for (i = 1; i < 16; i++) {
		if (strstrofs(s, "/", 0) < 0) {
			if not(file_exists(strcat("models/player/", s, "_", ftos(i), ".skin")))
				continue;
		} else {
			if not(file_exists(strcat(s, "_", ftos(i), ".skin")))
				continue;
		}
		player_model_select_list_add(strcat(s, ":", ftos(i)), curmodel, curskin);
	}
}

void(string s, string curmodel, float curskin) player_model_select_search_by_path {
	float glob, i;
	glob = search_begin(s, TRUE, TRUE);
	if (glob < 0)
		return;

	string _model, check;
	for (i = 0; i < search_getsize(glob); ++i) {
		_model = search_getfilename(glob, i);
		check = substring(_model, max(0, strlen(_model) - 9), 5);
		if (check == "_lod1" || check == "_lod2" || check == "_head")
			continue;

		check = substring(_model, max(0, strlen(_model) - 10), 6);
		if (check == "_torso")
			continue;

		check = substring(_model, max(0, strlen(_model) - 15), 11);
		if (check == "_decompiled")
			continue;

		check = substring(_model, max(0, strlen(_model) - 13), 9);
		if (check == "_compiled")
			continue;

		player_model_select_list_add_all_skins(_model, curmodel, curskin);
	}
	search_end(glob);
}

void(void) player_model_select_model_draw {
	if (CVAR(chase_active) || !cvar("r_drawviewmodel"))
		self.renderflags = 0;
	else
		self.renderflags = RF_VIEWMODEL | RF_DEPTHHACK;

	R_AddEntity(self);
}

void(void) player_model_select_read {
	string currentmodel = net_read_string();
	float currentskin = net_read_byte();
	string head, tail;
	tail = net_read_string();
	str_unzone_ifneeded(player_model_select_list);
	player_model_select_list = "";
	player_model_select_list_len = 0;
	player_model_select_list_pos = 0;
	player_model_select_list_pos_prev = -1;
	float colon;
	while (tail != "") {
		head = str_car(tail);
		tail = str_cdr(tail);
		if (head == "")
			continue;

		colon = strstrofs(head, ":", 0);
		if (colon > 0) {
			player_model_select_list_add(head, currentmodel, currentskin);
		} else {
			player_model_select_list_add_all_skins(head, currentmodel, currentskin);
		}
	}
	if not(player_model_select_list_len) {
		player_model_select_search_by_path("models/player/*.zym", currentmodel, currentskin);
		player_model_select_search_by_path("models/player/*.dpm", currentmodel, currentskin);
		player_model_select_search_by_path("models/player/*.md3", currentmodel, currentskin);
		player_model_select_search_by_path("models/player/*.psk", currentmodel, currentskin);
		player_model_select_search_by_path("models/player/*.iqm", currentmodel, currentskin);
	}
	player_model_select_list = str_zone_ifneeded(player_model_select_list);
	if not(player_model_select)
		player_model_select = spawn();

	player_model_select.draw2d = player_model_select_draw;
	player_model_select.draw2dflag = 3;
	if not(player_model_select_current) {
		player_model_select_current = spawn();
		player_model_select_head = spawn();
		player_model_select_torso = spawn();
	}
	player_model_select_current.effects = EFFECT_FULLBRIGHT | EFFECT_NODEPTHTEST;
	player_model_select_torso.effects = EFFECT_FULLBRIGHT | EFFECT_NODEPTHTEST;
	player_model_select_head.effects = EFFECT_FULLBRIGHT | EFFECT_NODEPTHTEST;
	player_model_select_current.draw = player_model_select_model_draw;
	player_model_select_current.renderflags = RF_VIEWMODEL | RF_DEPTHHACK;
	player_model_select_head.draw = player_model_select_model_draw;
	player_model_select_torso.draw = player_model_select_model_draw;
	player_model_select_current.colormap = 1023;
	player_model_select_torso.colormap = 1023;
	if not(player_model_select_list_len)
		player_model_select_remove();
}
