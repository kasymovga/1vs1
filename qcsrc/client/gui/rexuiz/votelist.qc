void(entity me, float i) gui_rexuiz_votelist_select;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_votelist_resize;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_votelist_item_draw;

entity(void) gui_rexuiz_votelist_spawn {
	entity me; me = gui_rexuiz_listbox_spawn();
	me.drawListBoxItem = gui_rexuiz_votelist_item_draw;
	me.setSelected = gui_rexuiz_votelist_select;
	me.resizeNotify = gui_rexuiz_votelist_resize;
	me.textBox = NULL;
	me.realUpperMargin = 0;
	me.columnNameOrigin = 0;
	me.voteArgsList = NULL;
	me.classname = "NexuizVoteList";
	return me;
}

entity(void) gui_rexuiz_votelist_make {
	entity me;
	me = gui_rexuiz_votelist_spawn();
	me.nItems = vote_commands_count;
	me.selectedItem = -1;
	me.configureNexuizListBox(me);
	return me;
}
void(entity me, float i) gui_rexuiz_votelist_select {
	setSelectedListBox(me, i);
	me.voteArgsList.setVoteType(me.voteArgsList, vote_commands[i]);
	string s = strcat(vote_commands[i], " ");
	me.textBox.setText(me.textBox, s);
	me.textBox.cursorPos = strlen(s);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_votelist_resize {
	gui_rexuiz_listbox_resize(me, relOrigin, relSize, absOrigin, absSize); //parent method
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_votelist_item_draw {
	string s;
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	s = vote_commands[i];
	gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
}
