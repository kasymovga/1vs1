entity modelselect;
entity modelselect_current;
string modelselect_list;
float modelselect_list_len;
float modelselect_list_pos;
float modelselect_list_pos_prev;

const vector MODELSELECT_PREV_POS = '-270 200 0';
const vector MODELSELECT_PREV_SIZE = '120 60 0';
const vector MODELSELECT_NEXT_POS = '150 200 0';
const vector MODELSELECT_NEXT_SIZE = '120 60 0';
const vector MODELSELECT_OK_POS = '-170 350 0';
const vector MODELSELECT_OK_SIZE = '100 30 0';
const vector MODELSELECT_CANCEL_POS = '50 350 0';
const vector MODELSELECT_CANCEL_SIZE = '120 30 0';

float(void) modelselect_choosen_button {
	vector v = mouse_position();
	v_x = v_x - (CVAR(vid_conwidth) / 2);
	if (v_x >= MODELSELECT_PREV_POS_x && v_x <= MODELSELECT_PREV_POS_x + MODELSELECT_PREV_SIZE_x && v_y >= MODELSELECT_PREV_POS_y && v_y <= MODELSELECT_PREV_POS_y + MODELSELECT_PREV_SIZE_y)
		return 1;
	else if (v_x >= MODELSELECT_NEXT_POS_x && v_x <= MODELSELECT_NEXT_POS_x + MODELSELECT_NEXT_SIZE_x && v_y >= MODELSELECT_NEXT_POS_y && v_y <= MODELSELECT_NEXT_POS_y + MODELSELECT_NEXT_SIZE_y)
		return 2;
	else if (v_x >= MODELSELECT_OK_POS_x && v_x <= MODELSELECT_OK_POS_x + MODELSELECT_OK_SIZE_x && v_y >= MODELSELECT_OK_POS_y && v_y <= MODELSELECT_OK_POS_y + MODELSELECT_OK_SIZE_y)
		return 3;
	else if (v_x >= MODELSELECT_CANCEL_POS_x && v_x <= MODELSELECT_CANCEL_POS_x + MODELSELECT_CANCEL_SIZE_x && v_y >= MODELSELECT_CANCEL_POS_y && v_y <= MODELSELECT_CANCEL_POS_y + MODELSELECT_CANCEL_SIZE_y)
		return 4;

	return 0;
}

void(void) modelselect_remove {
	remove(modelselect);
	modelselect = world;
	remove(modelselect_current);
	modelselect_current = world;
}

float(float bInputType, float nPrimary, float nSecondary) modelselect_input_event {
	//if (bInputType == 2) //Prevent mouse look
	//	return TRUE;

	if (bInputType == 0) {
		if (nPrimary == K_ESCAPE) {
			modelselect_remove();
			return TRUE;
		}
		if (nPrimary == K_MOUSE1) {
			float i = modelselect_choosen_button();
			if (i == 1)
				modelselect_list_pos--;
			else if (i == 2)
				modelselect_list_pos++;
			else if (i == 3) {
				localcmd("playermodel ", modelselect_current.model, ";playerskin ", ftos(modelselect_current.skin), "\n");
				modelselect_remove();
			} else if (i == 4)
				modelselect_remove();

			return TRUE;
		}
	}
	return FALSE;
}

void(void) modelselect_draw {
	CSQC_InputEvent_Callback = modelselect_input_event;
	Mouse_Enable();
	sbar_hidescores = TRUE;
	string s = modelselect_list;
	if (modelselect_list_pos_prev != modelselect_list_pos) {
		if (modelselect_list_pos >= modelselect_list_len)
			modelselect_list_pos = 0;
		else if (modelselect_list_pos < 0)
			modelselect_list_pos = modelselect_list_len - 1;

		float i;
		for (i = 0; i < modelselect_list_pos; i++)
			s = str_cdr(s);

		s = str_car(s);
		float colon = strstrofs(s, ":", 0);
		string _model = substring(s, 0, colon);
		float _skin = stof(substring(s, colon + 1, -1));
		precache_model(_model);
		setmodel(modelselect_current, _model);
		modelselect_current.skin = _skin;
		modelselect_current.frame = 8;
		modelselect_list_pos_prev = modelselect_list_pos;
	}
	setorigin(modelselect_current, view_camera_origin + view_forward * 150);
	modelselect_current.angles_y = view_angles_y + (time * 90);
	vector c = '1 0 0' * (CVAR(vid_conwidth) / 2);
	drawfont = sbar_bigfont;
	draw_string_center('0 100 0', "Model select", '24 24 0', '1 1 1', 1, DRAWFLAG_NORMAL);
	draw_string_center('0 125 0', strcat(modelselect_current.model, ":", ftos(modelselect_current.skin)), '18 18 0', '1 1 1', 1, DRAWFLAG_NORMAL);
	vector ca;
	float button = modelselect_choosen_button();
	//Previous
	if (button == 1) ca = '0.5 0.5 0.5'; else ca = '0 0 0';
	drawfill(MODELSELECT_PREV_POS + c, MODELSELECT_PREV_SIZE, '0 0 0' + ca, 0.3, DRAWFLAG_NORMAL);
    draw_borderlines(2, MODELSELECT_PREV_POS + c, MODELSELECT_PREV_SIZE, '0 0 0' + ca, 1, DRAWFLAG_NORMAL);
	draw_string_center(MODELSELECT_PREV_POS + ('1 0 0' * MODELSELECT_PREV_SIZE_x * 0.5), "<", '60 60 0', '1 1 0' + ca, 1, DRAWFLAG_NORMAL);
	//Next
	if (button == 2) ca = '0.5 0.5 0.5'; else ca = '0 0 0';
	drawfill(MODELSELECT_NEXT_POS + c, MODELSELECT_NEXT_SIZE, '0 0 0' + ca, 0.3, DRAWFLAG_NORMAL);
    draw_borderlines(2, MODELSELECT_NEXT_POS + c, MODELSELECT_NEXT_SIZE, '0 0 0' + ca, 1, DRAWFLAG_NORMAL);
	draw_string_center(MODELSELECT_NEXT_POS + ('1 0 0' * MODELSELECT_NEXT_SIZE_x * 0.5), ">", '60 60 0', '1 1 0' + ca, 1, DRAWFLAG_NORMAL);
	//Ok
	if (button == 3) ca = '0.5 0.5 0.5'; else ca = '0 0 0';
	drawfill(MODELSELECT_OK_POS + c, MODELSELECT_OK_SIZE, '0 0 0' + ca, 0.3, DRAWFLAG_NORMAL);
    draw_borderlines(2, MODELSELECT_OK_POS + c, MODELSELECT_OK_SIZE, '0 0 0' + ca, 1, DRAWFLAG_NORMAL);
	draw_string_center(MODELSELECT_OK_POS + ('1 0 0' * MODELSELECT_OK_SIZE_x * 0.5), "Ok", '30 30 0', '0 1 0' + ca, 1, DRAWFLAG_NORMAL);
	//Cancel
	if (button == 4) ca = '0.5 0.5 0.5'; else ca = '0 0 0';
	drawfill(MODELSELECT_CANCEL_POS + c, MODELSELECT_CANCEL_SIZE, '0 0 0' + ca, 0.3, DRAWFLAG_NORMAL);
    draw_borderlines(2, MODELSELECT_CANCEL_POS + c, MODELSELECT_CANCEL_SIZE, '0 0 0' + ca, 1, DRAWFLAG_NORMAL);
	draw_string_center(MODELSELECT_CANCEL_POS + ('1 0 0' * MODELSELECT_CANCEL_SIZE_x * 0.5), "Cancel", '30 30 0', '1 0 0' + ca, 1, DRAWFLAG_NORMAL);
    drawfont = sbar_font;
}

void(string s, string curmodel, float curskin) modelselect_list_add {
	if (modelselect_list == "")
		modelselect_list = s;
	else
		modelselect_list = strcat(modelselect_list, " ", s);

	if (s == strcat(curmodel, ":", ftos(curskin)))
		modelselect_list_pos = modelselect_list_len;

	modelselect_list_len++;
}

void(string s, string curmodel, float curskin) modelselect_list_add_all_skins {
	float i;
	modelselect_list_add(strcat(s, ":0"), curmodel, curskin);
	for (i = 1; i < 16; i++) {
		if not(file_exists(strcat(s, "_", ftos(i), ".skin")))
			continue;

		modelselect_list_add(strcat(s, ":", ftos(i)), curmodel, curskin);
	}
}

void(string s, string curmodel, float curskin) modelselect_search_by_path {
	float glob, i;
	glob = search_begin(s, TRUE, TRUE);
	if (glob < 0)
		return;

	string _model, lodcheck;
	for (i = 0; i < search_getsize(glob); ++i) {
		_model = search_getfilename(glob, i);
		lodcheck = substring(_model, max(0, strlen(_model) - 9), 5);
		if (lodcheck == "_lod1" || lodcheck == "_lod2")
			continue;

		modelselect_list_add_all_skins(_model, curmodel, curskin);
	}
	search_end(glob);
}

void(void) modelselect_read {
	string currentmodel = ReadString();
	float currentskin = ReadByte();
	string head, tail;
	tail = ReadString();
	str_unzone_ifneeded(modelselect_list);
	modelselect_list = "";
	modelselect_list_len = 0;
	modelselect_list_pos = 0;
	modelselect_list_pos_prev = -1;
	float colon;
	while (tail != "") {
		head = str_car(tail);
		tail = str_cdr(tail);
		if (head == "")
			continue;

		colon = strstrofs(head, ":", 0);
		if (colon > 0) {
			modelselect_list_add(head, currentmodel, currentskin);
		} else {
			modelselect_list_add_all_skins(head, currentmodel, currentskin);
		}
	}
	if not(modelselect_list_len) {
		modelselect_search_by_path("models/player/*.zym", currentmodel, currentskin);
		modelselect_search_by_path("models/player/*.dpm", currentmodel, currentskin);
		modelselect_search_by_path("models/player/*.md3", currentmodel, currentskin);
	}
	modelselect_list = str_zone_ifneeded(modelselect_list);
	if not(modelselect)
		modelselect = spawn();

	modelselect.draw2d = modelselect_draw;
	modelselect.draw2dflag = 1;
	if not(modelselect_current)
		modelselect_current = spawn();

	modelselect_current.effects = EF_NODEPTHTEST | EF_FULLBRIGHT;
	modelselect_current.draw = inline void(void) { R_AddEntity(self); };
	modelselect_current.colormap = 1023;
	if not(modelselect_list_len)
		modelselect_remove();
}
