void(entity me) gui_rexuiz_skinlist_configure;
void(entity me) gui_rexuiz_skinlist_load;
void(entity me) gui_rexuiz_skinlist_save;
string(entity me, float i, float key) gui_rexuiz_skinlist_parameter;
void(entity me) gui_rexuiz_skinlist_get;
void(entity me) gui_rexuiz_skinlist_destroy;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_skinlist_resize;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_skinlist_item_draw;
void(entity me) gui_rexuiz_skinlist_set;
void(entity me, float i, vector where, float doubleclick) gui_rexuiz_skinlist_item_click;
float(entity me, float scan, float ascii, float shift) gui_rexuiz_skinlist_keydown;

entity(void) gui_rexuiz_skinlist_spawn {
	entity me; me = gui_rexuiz_listbox_spawn();
	me.configureNexuizSkinList = gui_rexuiz_skinlist_configure;
	me.rowsPerItem = 4;
	me.resizeNotify = gui_rexuiz_skinlist_resize;
	me.drawListBoxItem = gui_rexuiz_skinlist_item_draw;
	me.getSkins = gui_rexuiz_skinlist_get;
	me.setSkin = gui_rexuiz_skinlist_set;
	me.loadCvars = gui_rexuiz_skinlist_load;
	me.saveCvars = gui_rexuiz_skinlist_save;
	me.skinParameter = gui_rexuiz_skinlist_parameter;
	me.clickListBoxItem = gui_rexuiz_skinlist_item_click;
	me.keyDown = gui_rexuiz_skinlist_keydown;
	me.destroy = gui_rexuiz_skinlist_destroy;
	me.skinlist = -1;
	me.realFontSize = '0 0 0';
	me.columnPreviewOrigin = 0;
	me.columnPreviewSize = 0;
	me.columnNameOrigin = 0;
	me.columnNameSize = 0;
	me.realUpperMargin1 = 0;
	me.realUpperMargin2 = 0;
	me.origin = '0 0 0';
	me.itemAbsSize = '0 0 0';
	me.name = "skinselector";
	me.classname = "NexuizSkinList";
	return me;
}

entity(void) gui_rexuiz_skinlist_make {
	entity me;
	me = gui_rexuiz_skinlist_spawn();
	me.configureNexuizSkinList(me);
	return me;
}

void(entity me) gui_rexuiz_skinlist_configure {
	me.configureNexuizListBox(me);
	me.getSkins(me);
	me.loadCvars(me);
}

void(entity me) gui_rexuiz_skinlist_load {
	string s;
	float i, n;
	s = cvar_string("menu_skin");
	n = me.nItems;
	for (i = 0; i < n; ++i) {
		if (me.skinParameter(me, i, 0) == s) {
				me.selectedItem = i;
				break;
		}
	}
}

void(entity me) gui_rexuiz_skinlist_save {
	cvar_set("menu_skin", me.skinParameter(me, me.selectedItem, 0));
}

string(entity me, float i, float key) gui_rexuiz_skinlist_parameter {
	return str_array_get(me.skinlist, i * 4 + key);
}

void(entity me) gui_rexuiz_skinlist_get {
	float glob, buf, i, n, fh;
	string s;
	buf = str_array_create();
	glob = search_begin("gfx/menu/*/skinvalues.txt", TRUE, TRUE);
	if (glob < 0) {
		me.skinlist = buf;
		me.nItems = 0;
		return;
	}
	n = search_getsize(glob);
	for (i = 0; i < n; ++i) {
		s = search_getfilename(glob, i);
		str_array_set(buf, i * 4 + 0, str_sub(s, 9, strlen(s) - 24)); // the * part
		str_array_set(buf, i * 4 + 1, "<TITLE>");
		str_array_set(buf, i * 4 + 2, "<AUTHOR>");
		str_array_set(buf, i * 4 + 3, strcat("/gfx/menu/", str_sub(s, 9, strlen(s) - 24), "/skinpreview"));
		fh = fopen(s, FILE_READ);
		if (fh < 0) {
			print("Warning: can't open skinvalues.txt file\n");
			continue;
		}
		while ((s = fgets(fh))) {
			// these two are handled by skinlist.qc
			if (str_sub(s, 0, 6) == "title ")
				str_array_set(buf, i * 4 + 1, str_sub(s, 6, strlen(s) - 6));
			else if(str_sub(s, 0, 7) == "author ")
				str_array_set(buf, i * 4 + 2, str_sub(s, 7, strlen(s) - 7));
		}
		fclose(fh);
	}
	search_end(glob);
	me.skinlist = buf;
	me.nItems = n;
}

void(entity me) gui_rexuiz_skinlist_destroy {
	str_array_delete(me.skinlist);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_skinlist_resize {
	me.itemAbsSize = '0 0 0';
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize_y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize_x * (1 - me.controlWidth)));
	me.realUpperMargin1 = 0.5 * (1 - 2.5 * me.realFontSize_y);
	me.realUpperMargin2 = me.realUpperMargin1 + 1.5 * me.realFontSize_y;
	me.columnPreviewOrigin = 0;
	me.columnPreviewSize = me.itemAbsSize_y / me.itemAbsSize_x * 4 / 3;
	me.columnNameOrigin = me.columnPreviewOrigin + me.columnPreviewSize + me.realFontSize_x;
	me.columnNameSize = 1 - me.columnPreviewSize - 2 * me.realFontSize_x;
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_skinlist_item_draw {
	string s;
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	s = me.skinParameter(me, i, 3);
	gui_draw_picture(me.columnPreviewOrigin * eX, s, me.columnPreviewSize * eX + eY, '1 1 1', 1);
	s = me.skinParameter(me, i, 0);
	s = strcat(s, ": ", me.skinParameter(me, i, 1));
	s = gui_draw_text_shorten_to_width(s, me.columnNameSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin1 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - gui_text_width(s, 0) * me.realFontSize_x)) * eX, s, me.realFontSize, SKINCOLOR_SKINLIST_TITLE, SKINALPHA_TEXT, 0);
	s = me.skinParameter(me, i, 2);
	s = gui_draw_text_shorten_to_width(s, me.columnNameSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin2 * eY + (me.columnNameOrigin + 1.00 * (me.columnNameSize - gui_text_width(s, 0) * me.realFontSize_x)) * eX, s, me.realFontSize, SKINCOLOR_SKINLIST_AUTHOR, SKINALPHA_TEXT, 0);
}

void(entity me) gui_rexuiz_skinlist_set {
	if (cvar_string("menu_skin") == me.skinParameter(me, me.selectedItem, 0))
		return;

	me.saveCvars(me);
	localcmd("\nmenu_restart\nr_restart\ntogglemenu\ndefer 0.1 \"menu_cmd skinselect\"\n");
}

void(entity me, float i, vector where, float doubleclick) gui_rexuiz_skinlist_item_click {
	if (doubleclick)
		me.setSkin(me);
}

float(entity me, float scan, float ascii, float shift) gui_rexuiz_skinlist_keydown {
	if (scan == VM_K_ENTER) {
		me.setSkin(me);
		return 1;
	} else
		return keyDownListBox(me, scan, ascii, shift);
}
