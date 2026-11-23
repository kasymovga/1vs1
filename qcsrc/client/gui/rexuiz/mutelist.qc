void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_mutelist_resize;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_mutelist_draw_item;

entity(void) gui_rexuiz_mutelist_spawn {
	entity me; me = gui_rexuiz_listbox_spawn();
	me.drawListBoxItem = gui_rexuiz_mutelist_draw_item;
	me.resizeNotify = gui_rexuiz_mutelist_resize;
	me.textBox = NULL;
	me.realUpperMargin = 0;
	me.columnNameOrigin = 0;
	me.voteArgsList = NULL;
	me.classname = "NexuizMuteList";
	return me;
}

entity(void) gui_rexuiz_mutelist_make {
	entity me;
	me = gui_rexuiz_mutelist_spawn();
	me.nItems = maxclients;
	me.selectedItem = -1;
	me.configureNexuizListBox(me);
	return me;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_mutelist_resize {
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_mutelist_draw_item {
	string s;
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	float n = i + 1;
	s = strdecolorize(player_name(i));
	if (mute_listed(n)) {
		gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, "[MUTED]", me.realFontSize, SKINCOLOR_TEXT_WARNING, SKINALPHA_TEXT, 0);
		gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.1 0 0', strcat("#", ftos(n)), me.realFontSize, SKINCOLOR_TEXT_WARNING, SKINALPHA_TEXT, 0);
		gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.2 0 0', s, me.realFontSize, SKINCOLOR_TEXT_WARNING, SKINALPHA_TEXT, 0);
	} else {
		gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.1 0 0', strcat("#", ftos(n)), me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
		gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.2 0 0', s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
	}
}
