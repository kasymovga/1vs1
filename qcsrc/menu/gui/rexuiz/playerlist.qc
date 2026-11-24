void(entity me, string plist) gui_rexuiz_playerlist_set;
string(entity me, float i, float key) gui_rexuiz_playerlist_get;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_playerlist_resize;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_playerlist_draw;

entity(void) gui_rexuiz_playerlist_spawn {
	entity me = gui_rexuiz_listbox_spawn();
	me.rowsPerItem = 1;
	me.resizeNotify = gui_rexuiz_playerlist_resize;
	me.drawListBoxItem = gui_rexuiz_playerlist_draw;
	me.realFontSize = '0 0 0';
	me.columnNameOrigin = 0;
	me.columnNameSize = 0;
	me.columnScoreOrigin = 0;
	me.columnScoreSize = 0;
	me.realUpperMargin = 0;
	me.origin = '0 0 0';
	me.itemAbsSize = '0 0 0';
	me.setPlayerList = gui_rexuiz_playerlist_set;
	me.getPlayerList = gui_rexuiz_playerlist_get;
	me.playerList = -1;
	me.classname = "NexuizPlayerList";
	return me;
}

entity(void) gui_rexuiz_playerlist_make {
	entity me = gui_rexuiz_playerlist_spawn();
	me.configureNexuizListBox(me);
	return me;
}

void(entity me, string plist) gui_rexuiz_playerlist_set {
	float buf,i,n;
	string s;
	buf = str_array_create();
	me.nItems = tokenizebyseparator(plist, "\n");
	for (i = 0; i < me.nItems; ++i) {
		str_array_set(buf, i * 4 + 3, argv(i)); // -666 100 "^4Nex ^2Player"
	}
	for (i = 0; i < me.nItems; ++i) {
		s = str_array_get(buf, i * 4 + 3);
		n = tokenize_console(s);
		if (n == 4) {
			str_array_set(buf, i * 4 + 0, argv(0)); // -666
			str_array_set(buf, i * 4 + 1, argv(1)); // 100
			str_array_set(buf, i * 4 + 2, argv(2)); // 0 for spec, else 1, 2, 3, 4
			str_array_set(buf, i * 4 + 3, argv(3)); // ^4Nex ^2Player
		} else {
			str_array_set(buf, i * 4 + 0, argv(0)); // -666
			str_array_set(buf, i * 4 + 1, argv(1)); // 100
			str_array_set(buf, i * 4 + 2, "-1");
			str_array_set(buf, i * 4 + 3, argv(2)); // ^4Nex ^2Player
		}
	}
	me.playerList = buf;
}

string(entity me, float i, float key) gui_rexuiz_playerlist_get {
	return str_array_get(me.playerList, i * 4 + key);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_playerlist_resize {
	me.itemAbsSize = '0 0 0';
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize_y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize_x * (1 - me.controlWidth)));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
	// this list does 1 char left and right margin
	me.columnScoreSize = 3 * me.realFontSize_x;
	me.columnNameSize = 1 - 3 * me.realFontSize_x - me.columnScoreSize;
	me.columnNameOrigin = me.realFontSize_x;
	me.columnScoreOrigin = me.columnNameOrigin + me.columnNameSize + me.realFontSize_x;
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_playerlist_draw {
	string s;
	string score;
	float t;
	vector rgb;
	t = stof(me.getPlayerList(me, i, 2));
	if (t == 1)
		rgb = colormap_palette_color(4, 0);
	else if (t == 2)
		rgb = colormap_palette_color(13, 0);
	else if (t == 3)
		rgb = colormap_palette_color(12, 0);
	else if (t == 4)
		rgb = colormap_palette_color(9, 0);
	else
		rgb = '1 1 1';

	s = me.getPlayerList(me, i, 3);
	score = me.getPlayerList(me, i, 0);
	if (str_sub(score, strlen(score) - 10, 10) == ":spectator") {
		score = "-666";
	} else {
		if ((t = strstrofs(score, ":", 0)) >= 0)
			score = str_sub(score, 0, t);
		if ((t = strstrofs(score, ",", 0)) >= 0)
			score = str_sub(score, 0, t);
	}
	s = gui_draw_text_shorten_to_width(s, (me.columnNameSize / me.realFontSize_x), 1);
	score = gui_draw_text_shorten_to_width(score, me.columnScoreSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin2 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - gui_text_width(s, 1) * me.realFontSize_x)) * eX, s, me.realFontSize, '1 1 1', 1, 1);
	gui_draw_text(me.realUpperMargin2 * eY + (me.columnScoreOrigin + 1.00 * (me.columnScoreSize - gui_text_width(score, 1) * me.realFontSize_x)) * eX, score, me.realFontSize, rgb, 1, 0);
}
