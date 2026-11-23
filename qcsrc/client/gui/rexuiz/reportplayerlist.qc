void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_reportplayerlist_resize;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_reportplayerlist_item_draw;

entity(void) gui_rexuiz_reportplayerlist_spawn {
	entity me = gui_rexuiz_listbox_spawn();
	me.drawListBoxItem = gui_rexuiz_reportplayerlist_item_draw;
	me.realUpperMargin = 0;
	me.columnNameOrigin = 0;
	me.resizeNotify = gui_rexuiz_reportplayerlist_resize;
	me.classname = "NexuizReportPlayerList";
	return me;
}

entity(void) gui_rexuiz_reportplayerlist_make {
	entity me = gui_rexuiz_reportplayerlist_spawn();
	me.configureNexuizListBox(me);
	me.nItems = 255;
	return me;
}
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_reportplayerlist_resize {
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_reportplayerlist_item_draw {
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	string s = "";
	entity e = player_slots[i];
	if (e)
		s = strcat("#", ftos(e.sv_entnum + 1), ": ", strdecolorize(player_name(e.sv_entnum)));

	gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
}
