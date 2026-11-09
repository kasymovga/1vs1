#ifdef INTERFACE
CLASS(NexuizVoteArgsList) EXTENDS(NexuizListBox)
	METHOD(NexuizVoteArgsList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(NexuizVoteArgsList, setSelected, void(entity, float))
	METHOD(NexuizVoteArgsList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(NexuizVoteArgsList, setVoteType, void(entity, string))
	ATTRIB(NexuizVoteArgsList, voteType, float, 0)
	ATTRIB(NexuizVoteArgsList, textBox, entity, NULL)
	ATTRIB(NexuizVoteArgsList, realUpperMargin, float, 0)
	ATTRIB(NexuizVoteArgsList, columnNameOrigin, float, 0)
	ATTRIB(NexuizVoteArgsList, voteList, entity, NULL)
ENDCLASS(NexuizVoteArgsList)
entity makeNexuizVoteArgsList();
#endif

#ifdef IMPLEMENTATION

entity makeNexuizVoteArgsList(void)
{
	entity me;
	localcmd("cmd lsmaps2\n");
	me = spawnNexuizVoteArgsList();
	me.configureNexuizListBox(me);
	me.nItems = 0;
	return me;
}

void setVoteTypeNexuizVoteArgsList(entity me, string vote) {
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
		me.nItems = max(1, buf_getsize(map_list));
	}
	me.selectedItem = -1;
	if (new_voteType != me.voteType) {
		me.voteType = new_voteType;
		me.scrollPos = 0;
	}

}

void setSelectedNexuizVoteArgsList(entity me, float i)
{
	setSelectedListBox(me, i);
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
		s = strcat(vote, " ", bufstr_get(map_list, i));
		me.voteList.textBox.setText(me.voteList.textBox, s);
		me.voteList.textBox.cursorPos = strlen(s);
	}
	me.voteList.textBox.setText(me.voteList.textBox, s);
	me.voteList.textBox.cursorPos = strlen(s);
}

void resizeNotifyNexuizVoteArgsList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

string drawListBoxItemNexuizVoteArgsList_cdr_last;
float drawListBoxItemNexuizVoteArgsList_cdr_last_pos;
float drawListBoxItemNexuizVoteArgsList_list_last;
void drawListBoxItemNexuizVoteArgsList(entity me, float i, vector absSize, float isSelected)
{
	if(isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	string s = "";

	if (me.voteType == 1 || me.voteType == 2) {

		entity  e = player_slots[i];
		if (e)
			s = strcat("#", ftos(e.sv_entnum + 1), ": ", strdecolorize(player_name(e.sv_entnum)));

	} else if (me.voteType == 3) {
		s = bufstr_get(map_list, i);
	}
	gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
}

#endif
