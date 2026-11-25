void(entity me, string vote) gui_rexuiz_voteargslist_type_set;
void(entity me, float i) gui_rexuiz_voteargslist_select;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_voteargslist_resize;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_voteargslist_item_draw;

entity(void) gui_rexuiz_voteargslist_spawn {
	entity me = gui_rexuiz_listbox_spawn();
	me.drawListBoxItem = gui_rexuiz_voteargslist_item_draw;
	me.setSelected = gui_rexuiz_voteargslist_select;
	me.resizeNotify = gui_rexuiz_voteargslist_resize;
	me.setVoteType = gui_rexuiz_voteargslist_type_set;
	me.voteType = 0;
	me.textBox = NULL;
	me.realUpperMargin = 0;
	me.columnNameOrigin = 0;
	me.voteList = NULL;
	me.classname = "NexuizVoteArgsList";
	return me;
}

entity(void) gui_rexuiz_voteargslist_make {
	entity me;
	localcmd("cmd lsmaps2\n");
	me = gui_rexuiz_voteargslist_spawn();
	me.configureNexuizListBox(me);
	me.nItems = 0;
	return me;
}

void(entity me, string vote) gui_rexuiz_voteargslist_type_set {
	me.nItems = 0;
	float new_voteType;
	new_voteType = 0;
	if (vote == "kick" ||
		vote == "kickban") {
		new_voteType = 1;
		me.nItems = 255;
	} else if (vote == "movetoteam_auto" ||
			vote == "movetoteam_blue" ||
			vote == "movetoteam_red" ||
			vote == "movetoteam_yellow" ||
			vote == "movetoteam_ping" ||
			vote == "mute") {
		new_voteType = 2;
		me.nItems = 255;
	} else if (vote == "gotomap" || vote == "chmap" || vote == "nextmap") {
		new_voteType = 3;
		me.nItems = max(1, str_array_size(map_list));
	}
	me.selectedItem = -1;
	if (new_voteType != me.voteType) {
		me.voteType = new_voteType;
		me.scrollPos = 0;
	}
}

void(entity me, float i) gui_rexuiz_voteargslist_select {
	gui_listbox_select(me, i);
	if (i >= me.nItems)
		return;

	string vote = vote_commands[me.voteList.selectedItem];
	string s = "";
	if (me.voteType == 1 || me.voteType == 2) {
		entity e = player_slots[i];
		if (e) {
			if (me.voteType == 1)
				s = strcat(vote, " # ", ftos(e.sv_entnum + 1));
			else
				s = strcat(vote, " ", ftos(e.sv_entnum + 1));

			if (vote == "kick" || vote == "kickban")
				s = strcat(s, " reason");
		}
	} else if (me.voteType == 3) {
		s = strcat(vote, " ", str_array_get(map_list, i));
		me.voteList.textBox.setText(me.voteList.textBox, s);
		me.voteList.textBox.cursorPos = strlen(s);
	}
	me.voteList.textBox.setText(me.voteList.textBox, s);
	me.voteList.textBox.cursorPos = strlen(s);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_voteargslist_resize {
	gui_rexuiz_listbox_resize(me, relOrigin, relSize, absOrigin, absSize); //parent method
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_voteargslist_item_draw {
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	string s = "";
	if (me.voteType == 1 || me.voteType == 2) {
		entity e = player_slots[i];
		if (e)
			s = strcat("#", ftos(e.sv_entnum + 1), ": ", strdecolorize(player_name(e.sv_entnum)));
	} else if (me.voteType == 3) {
		s = str_array_get(map_list, i);
	}
	gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
}
